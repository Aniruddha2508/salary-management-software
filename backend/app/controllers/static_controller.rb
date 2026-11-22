# Serves the built React SPA's index.html for any non-API route in
# production, so a full page load/refresh on a client-side route (e.g.
# /employees/42) works correctly. In development, Vite's own dev server
# handles this instead - see frontend/vite.config.js.
class StaticController < ApplicationController
  def index
    render file: Rails.root.join("public/index.html"), layout: false, content_type: "text/html"
  end
end
