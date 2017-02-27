class BuildsController < ApplicationController

  def show
    build = Build.find_by(name: params[:id])

    if build
      render json: {'supportLevel' => build.support_level}, status: :ok
    else
      render json: {'supportLevel' => 'invalid'}, status: :ok
    end
  end
end
