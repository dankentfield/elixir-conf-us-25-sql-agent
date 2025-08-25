defmodule SqlAgentWeb.PageController do
  use SqlAgentWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
