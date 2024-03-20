class DeeplinkService
  attr_reader :procedure_id, :step_name

  def initialize(procedure_id, step_name)
    @procedure_id = procedure_id
    @step_name = step_name
  end

  def get_deeplink
    # currently directly calling the operations of platform,
    # in future it can be replaced by calling fetch_deeplink_via_api
    get_deeplink_direct
  end

  private

  def params
    { procedure_id: procedure_id, step_name: step_name }
  end

  def get_deeplink_direct
    ::Deeplink::Operation::GetURL.call(params: params)[:deeplink]
  end

  def fetch_deeplink_via_api
    api_hostname = Vineti::Notifications::Config.instance.fetch('api_hostname_url')
    response = RestClient.get("#{api_hostname}/deeplinks/get_url", params: params)
    JSON.parse(response)['url']
  rescue RestClient::ExceptionWithResponse => e
    log_and_notify_api_error e
  end

  def log_and_notify_api_error(error)
    Rails.logger.info(error)
    Airbrake.notify(error)
  end
end
