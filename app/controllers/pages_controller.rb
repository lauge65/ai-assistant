class PagesController < ApplicationController
  skip_before_action :authenticate_user!, only: :home

  def home
    @contexts = current_user.contexts if user_signed_in?
  end
end
