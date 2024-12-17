# frozen_string_literal: true

require 'google/apis/drive_v3'
require 'googleauth'

class DriveServiceInitializer
  APPLICATION_NAME = 'Drive Compare and Sync Service'
  OAUTH_SCOPES = [Google::Apis::DriveV3::AUTH_DRIVE_READONLY].freeze

  def initialize(service_account_key_path)
    @service_account_key_path = service_account_key_path
  end

  def drive_service
    service = Google::Apis::DriveV3::DriveService.new
    service.client_options.application_name = APPLICATION_NAME
    service.authorization = authorize
    service
  end

  def authorize
    Google::Auth::ServiceAccountCredentials.make_creds(
      json_key_io: File.open(@service_account_key_path),
      scope: OAUTH_SCOPES
    )
  end
end
