class SessionsController < ApplicationController
  skip_before_action :authenticate
  def new
    redirect_to controller: :repository, action: :index if current_user.present?
  end

  def authorize
    address = github.authorize_url
    redirect_to address
  end

  def callback
    authorization_code = params[:code]
    access_token = github.get_token(authorization_code)
    github(oauth_token: access_token.token)
    set_user
    redirect_to controller: :repository, action: :index
  end

  def destroy
    sign_out
    redirect_to login_path
  end

  private

  def set_user
    return unless github.users.get.present?
    git_user_details = github.users.get.body
    user = User.find_or_initialize_by(github_id: git_user_details['id'])
    user.github_name    = git_user_details['login']
    user.github_details = git_user_details
    user.save
    session[:user_id] = user.id
  end

  def sign_out
    session.delete(:user_id)
    @current_user = nil
  end
end
