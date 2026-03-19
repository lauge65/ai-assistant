class PagesController < ApplicationController
  skip_before_action :authenticate_user!, only: :home

  def home
    @contexts = user_signed_in? ? current_user.contexts : []
  end
end
