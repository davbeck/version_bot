class V1::VersionsController < ApplicationController
  def show
    @version ||= Version.new(version_params) # we don't save this
  end
  
  def create
    @version ||= Version.new(version_params)
    @version.build += 1
    @version.save
    
    render :show
  end
  
  def update
    if !version_params[:build]
      @code = 404
      @message = "You must provide a starting build number. To start and increment automatically, use POST #{v1_versions_path}."
      render :error, status: @code
    else
      @version ||= Version.new(version_params)
      @version.build = version_params[:build]
      @version.save
    
      render :show
    end
  end
  
  before_action do
    @version = Version.where(identifier: version_params[:identifier], short_version: version_params[:short_version]).first
  end
 
private
  def version_params
    params.permit(:identifier, :short_version, :build)
  end
end
