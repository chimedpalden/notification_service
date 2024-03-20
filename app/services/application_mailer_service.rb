class ApplicationMailerService
  attr_reader :client

  def initialize
    @client = ::ApplicationMailer.new
  end

  # Designed to be identical to the Ses client API
  # and used in the MailService class
  #
  # Arguments:
  # * source: is the :from option
  # * destination:
  # The destination should contain the following key/values
  # and should be mapped to the correct options in the mailer:
  # {
  #   to_addresses: @subscriber.data['to_addresses'],
  #   cc_addresses: @subscriber.data['cc_addresses'],
  #   bcc_addresses: @subscriber.data['bcc_addresses'],
  #  }
  # * message:
  # The message is a structure with :text and :subject
  # That refers to the subject and body.
  # {
  #   subject: { data: "foo"},
  #   body: { text: {data: "bar"}, html: {data: "<b>bar</b>"} },
  # }
  def send_email(source:, destination:, message:)
    opts = {
      from: source,
      bcc: destination[:bcc_addresses],
      cc: destination[:cc_addresses],
      to: destination[:to_addresses],
      subject: message.fetch(:subject, nil)&.fetch(:data),
    }

    text_body = message.fetch(:body, nil)&.fetch(:text, nil)&.fetch(:data)
    html_body = message.fetch(:body, nil)&.fetch(:html, nil)&.fetch(:data)

    mailer = client.mail opts do |format|
      format.text { text_body || html_body }
      format.html { html_body || text_body }
    end
    mailer.deliver!
  end
end
