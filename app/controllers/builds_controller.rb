class BuildsController < ApplicationController
  before_action :authenticate_request!

  def show
    Rails.logger.info "GABEE: #{params[:id]}"
    support_level = Build.find_by(name: params[:id]).support_level

    if support_level
      render json: {status_level: support_level}, status: :ok
    else
      render json: {status: 'Invalid build'}, status: :not_found
    end
  end
end
