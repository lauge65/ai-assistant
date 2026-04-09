module Users
  class RegistrationsController < Devise::RegistrationsController
    protected

    def update_resource(resource, params)
      if params[:password].present? || params[:password_confirmation].present? || params[:email] != resource.email
        super
      else
        params.delete(:current_password)
        resource.update_without_password(params)
      end
    end
  end
end
