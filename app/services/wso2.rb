class Wso2
  def initialize
    @wso2_tenant_base_url = Vineti::Notifications::Config.instance.fetch('wso2_tenant_base_url')
    @wso2_tenant = Vineti::Notifications::Config.instance.fetch('wso2_tenant')
    @wso2_events_api = Vineti::Notifications::Config.instance.fetch('wso2_events_api')
    @wso2_oauth2_client_id = Vineti::Notifications::Config.instance.fetch('wso2_oauth2_client_id')
    @wso2_oauth2_client_secret = Vineti::Notifications::Config.instance.fetch('wso2_oauth2_client_secret')
    @wso2_oauth2_token_url = Vineti::Notifications::Config.instance.fetch('wso2_oauth2_token_url')
    @wso2_oauth2_auth_scheme = Vineti::Notifications::Config.instance.fetch('wso2_oauth2_auth_scheme')
  end

  def wso2_service_url
    @wso2_tenant_base_url.delete_suffix("/") + '/' + @wso2_tenant.delete_prefix("/").delete_suffix("/") + '/' + @wso2_events_api.delete_prefix("/")
  end

  def wso_service_http_method
    :post
  end

  def oauth_token
    auth = ::OAuth2::Client.new(
      @wso2_oauth2_client_id,
      @wso2_oauth2_client_secret,
      site: @wso2_tenant_base_url,
      token_url: @wso2_oauth2_token_url,
      auth_scheme: @wso2_oauth2_auth_scheme
    ).client_credentials.get_token
    auth.headers
  rescue StandardError => e
    raise "OAuth2::Error=> Fail to generate OAuth token. Error# #{e}"
  end
end
