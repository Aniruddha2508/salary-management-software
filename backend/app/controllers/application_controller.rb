class ApplicationController < ActionController::API
  # ActionController::API omits RequestForgeryProtection by default. We add
  # it back because the HR Manager auth flow uses session cookies, which
  # need CSRF protection on mutating requests (see Api::V1::BaseController).
  include ActionController::RequestForgeryProtection
end
