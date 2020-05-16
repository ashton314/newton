defmodule NewtonWeb.IconHelpers do
  @moduledoc """
  Conveniences for inserting SVG icons into HTML.
  """

  use Phoenix.HTML
  alias NewtonWeb.Router.Helpers, as: Routes

  def icon(conn, name, opts \\ []) do
    width = Keyword.get(opts, :width, 24)
    height = Keyword.get(opts, :height, 24)
    color = Keyword.get(opts, :color, "#fff")
    stroke_width = Keyword.get(opts, :stroke_width, 2)

    content_tag(
      :svg,
      tag(:use,
        "xlink:href": Routes.static_path(conn, "/images/icons/dist/feather-sprite.svg##{name}")
      ),
      width: width,
      height: height,
      stroke: color,
      stroke_width: stroke_width,
      fill: "none",
      stroke_linecap: "round",
      stroke_linejoin: "round"
    )
  end

  def icon_button(conn, name, event, value, target, opts \\ []) do
    width = Keyword.get(opts, :width, 24)
    height = Keyword.get(opts, :height, 24)
    color = Keyword.get(opts, :color, "#fff")
    stroke_width = Keyword.get(opts, :stroke_width, 2)

    content_tag(
      :svg,
      tag(:use,
        "xlink:href": Routes.static_path(conn, "/images/icons/dist/feather-sprite.svg##{name}")
      ),
      phx_click: event,
      phx_target: target,
      phx_value_click: value,
      width: width,
      height: height,
      stroke: color,
      stroke_width: stroke_width,
      fill: "none",
      stroke_linecap: "round",
      stroke_linejoin: "round",
      style: "cursor: pointer"
    )
  end
end
