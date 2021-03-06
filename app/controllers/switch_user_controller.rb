class SwitchUserController < ApplicationController
  before_filter :developer_modes_only

  def set_current_user
    session[:original_user_id] = current_user.id
    handle_request(params)

    redirect_to(SwitchUser.redirect_path.call(request, params))
  end

  def remember_user
    # NOOP unless the user has explicity enabled this feature
    if SwitchUser.switch_back
      provider.remember_current_user(params[:remember] == "true")
    end

    redirect_to(SwitchUser.redirect_path.call(request, params))
  end

  def switch_back
    params[:scope_identifier] = "user_#{session[:original_user_id]}" if session[:original_user_id].present?
    session[:original_user_id] = nil
    handle_request(params)
    redirect_to(SwitchUser.switch_back_path.call(request, params))
  end

  private

  def developer_modes_only
    render :text => "Permission Denied", :status => 403 unless available?
  end

  def available?
    SwitchUser.guard_class.new(self, provider).controller_available? || session[:original_user_id].present?
  end

  def handle_request(params)
    if params[:scope_identifier].blank?
      provider.logout_all
    else
      loader = SwitchUser::UserLoader.prepare(params)
      if SwitchUser.login_exclusive
        provider.login_exclusive(loader.user, :scope => loader.scope)
      else
        provider.login_inclusive(loader.user, :scope => loader.scope)
      end
    end
  end

  # TODO make helper methods, so this can be eliminated from the
  # SwitchUserHelper
  def provider
    SwitchUser::Provider.init(self)
  end
end
