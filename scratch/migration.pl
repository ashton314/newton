#!/usr/bin/env perl
use strict;
use warnings;

use feature qw(say);
use experimental 'signatures';
no warnings qw(experimental::signatures);

use Mojo::JSON qw(j decode_json);
use File::Slurp;
use Data::Dumper;

my $source = shift @ARGV
  or die "usage: perl migration.pl [path to old archive]";

die "Couldn't find archive; $source is not a directory"
  unless -d $source;

# This is where all the encoded questions will live
my @questions = ();

opendir my $dirh, $source
  or die "Failed opening $source: $!";

while (my $q_dir = readdir $dirh) {
  next if $q_dir =~ /^\./;
  next unless -d "$source/$q_dir";

  say STDERR "Working on question $q_dir...";

  my %q = (
	   ref_chapter => '',
	   ref_section => '',
	   answers => [],
	   comments => [],
	   inserted_at => '',
	   updated_at => '',
	   type => 'multiple_choice',
	   tags => [],
	   text => '',
	   points => 1
	  );

  my $res = 0;
  my $m = '';
  my $v;

  # Try to guess chapter/section from name (will be overriden later if set)
  if ($q_dir =~ /^(?:S|\d+)-(\d+)-(\d+)/) {
    ($q{ref_chapter}, $q{ref_section}) = ($1, $2);
  }
  elsif ($q_dir =~ /^(?:S|\d+)-(\d+)/) {
    $q{ref_chapter} = $1;
  }

  # Grab metadata
  ($res, $m) = read_head("$source/$q_dir/meta");
  do { warn $m; next } unless $res;
  $v = decode_json $m;
  override(\%q, 'points', $v->{data}->{point_value});
  $q{type} = $v->{data}->{type};
  $q{type} =~ s/-/_/g;

  $q{name} = $q_dir;

  push @{$q{comments}}, { inserted_at => $v->{timestamp},
			  text => "Author: " . ($v->{data}->{author} || "Anonymous") };

  # Grab question text
  ($res, $m) = read_head("$source/$q_dir/question_text");
  do { warn $m; next } unless $res;
  $v = decode_json $m;
  $q{text} = $v->{data}->{text};

  # Grab tags
  ($res, $m) = read_head("$source/$q_dir/tags");
  do { warn $m; next } unless $res;
  $v = decode_json $m;
  my @tags = map { s/\s/_/g; lc } @{$v->{data}};
  $q{tags} = \@tags;

  # Grab answers
  ($res, $m) = read_head("$source/$q_dir/answers");
  do { warn $m; next } unless $res;
  $v = decode_json $m;
  for my $ans (@{$v->{data}}) {
    push @{$q{answers}},
      {
       inserted_at => $v->{timestamp},
       text => $ans->{text},
       points_marked => $ans->{points_marked},
       points_unmarked => $ans->{points_unmarked}
      };
  }

  # Stuff the comments
  # Grab stats
  ($res, $m) = read_head("$source/$q_dir/stats");
  do { warn $m; next } unless $res;
  $v = decode_json $m;

  if (scalar @{$v->{data}}) {
    push @{$q{comments}}, { inserted_at => $v->{timestamp},
			    text => "STATISTICS: " . (j {data => $v->{data}}) };
  }

  # Grab comments
  ($res, $m) = read_head("$source/$q_dir/comments");
  do { warn $m; next } unless $res;
  $v = decode_json $m;

  for my $com (@{$v->{data}}) {
    push @{$q{comments}},
      { inserted_at => $com->{timestamp},
	text => $com->{author} . ":\n" . $com->{text} };
  }

  # Warn about unimported images
  opendir my $resourceh, "$source/$q_dir/resources"
    or do { warn "Question $q_dir has no resources; skipping"; next };

  while (my $resource = readdir $resourceh) {
    next if $resource =~ /^\./;
    next if -d "$source/$q_dir/resources/$resource";

    warn "Unimported file $q_dir/$resource; adding comment";
    push @{$q{comments}},
      { text => "IMPORT SCRIPT:\n MISSING IMAGE RESOURCE NAMED '$resource'" };

    push @{$q{tags}}, "MISSING_PNG_IMPORT";
  }

  closedir $resourceh;

  push @questions, \%q;
  say STDERR "Working on question $q_dir...done.\n";
}

closedir $dirh;

my %archive = (questions => \@questions, exams => []);

say j \%archive;

sub override ($ref, $field, $val) {
  chomp $val if $val;

  if ($val) {
    $ref->{$field} = $val;
  }
}

sub read_head ($dir) {
  return (0, "Missing HEAD file")
    unless -f "$dir/HEAD";

  chomp(my $head = read_file("$dir/HEAD"));

  return (0, "HEAD points to non-existant value")
    unless -f "$dir/$head";

  return (1, read_file("$dir/$head"));
}
