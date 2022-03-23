# frozen_string_literal: true

module Users
  class RegistrationsController < Devise::RegistrationsController
    # before_action :configure_sign_up_params, only: [:create]
    # before_action :configure_account_update_params, only: [:update]
    prepend_before_action :authenticate_scope!, only: %i[new create]
    # GET /resource/sign_up

    def new
      @roles = []
      Role.select('id', 'name').where(:role_type == 'user').each { |v| @roles << [v.name, v.id] }
      @roles
      @user = User.new
      # super
    end

    # POST /resource
    def create
      role = params['user']['roles']
      params['user'].delete 'roles'
      @user = User.new(sign_up_params)
      @user.roles << Role.find(role)

      if @user.save
        redirect_to '/'
      else
        render :new, status: :unprocessable_entity
      end
    end

    # GET /resource/edit
    # def edit
    #   super
    # end

    # PUT /resource
    # def update
    #   super
    # end

    # DELETE /resource
    # def destroy
    #   super
    # end

    # GET /resource/cancel
    # Forces the session data which is usually expired after sign
    # in to be expired now. This is useful if the user wants to
    # cancel oauth signing in/up in the middle of the process,
    # removing all OAuth session data.
    # def cancel
    #   super
    # end

    # protected

    # If you have extra params to permit, append them to the sanitizer.
    # def configure_sign_up_params
    #   devise_parameter_sanitizer.permit(:sign_up, keys: [:attribute])
    # end

    # If you have extra params to permit, append them to the sanitizer.
    # def configure_account_update_params
    #   devise_parameter_sanitizer.permit(:account_update, keys: [:attribute])
    # end

    # The path used after sign up.
    # def after_sign_up_path_for(resource)
    #   super(resource)
    # end

    # The path used after sign up for inactive accounts.
    # def after_inactive_sign_up_path_for(resource)
    #   super(resource)
    # end
    def sign_up_params
      params.require(:user).permit(:name, :email, :password, :password_confirmation, :roles)
    end

    def account_update_params
      params.require(:user).permit(:name, :email, :password, :password_confirmation, :current_password, :roles)
    end
    before_action :authenticate_user!
  end
end
