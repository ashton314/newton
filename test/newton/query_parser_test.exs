defmodule Newton.QueryParserTest do
  use Newton.DataCase, async: true

  alias Newton.QueryParser

  describe "parse/1" do
    test "handles single types" do
      assert %{tags: [], refs: [], normal: []} = QueryParser.parse("")
      assert %{tags: [], refs: [], normal: ["hi"]} = QueryParser.parse("hi")
      assert %{tags: [], refs: [], normal: ["there", "hi"]} = QueryParser.parse("  hi there")

      assert %{tags: [], refs: [], normal: []} = QueryParser.parse("[]")
      assert %{tags: ["tag"], refs: [], normal: []} = QueryParser.parse("[tag]")
      assert %{tags: ["tag2", "tag1"], refs: [], normal: []} = QueryParser.parse("[tag1] [tag2]")
      assert %{tags: ["tag"], refs: [], normal: ["bar", "foo"]} = QueryParser.parse("foo [tag] bar")
      assert %{tags: ["tag1][tag2"], refs: [], normal: []} = QueryParser.parse("[tag1][tag2]")

      assert %{tags: [], refs: [], normal: ["{}"]} = QueryParser.parse("{}")
      assert %{tags: [], refs: [], normal: ["{not-a-ref}"]} = QueryParser.parse("{not-a-ref}")
      assert %{tags: [], refs: [%{chapter: 2}], normal: []} = QueryParser.parse("{2}")
      assert %{tags: [], refs: [%{chapter: 4, section: 7}, %{chapter: 3}], normal: []} = QueryParser.parse("{3} {4.7}")
      assert %{tags: [], refs: [%{chapter: 3, section: 2}], normal: ["bar", "foo"]} = QueryParser.parse("foo {3.2} bar")
    end
  end
end
