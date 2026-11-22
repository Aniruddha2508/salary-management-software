module Api
  module V1
    # All Api::V1 controllers inherit from here so we have one place to
    # add cross-cutting API concerns (auth, error rendering, etc.) later.
    class BaseController < ApplicationController
    end
  end
end
