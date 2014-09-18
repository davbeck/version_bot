class V1::VersionsController < ApplicationController
  def show
    @version ||= Version.new(version_params) # we don't save this
  end
  
  def update
    @version ||= Version.new(version_params)
    @version.build += 1
    @version.save
    
    render :show
  end
  
  before_action do
    @version = Version.where(version_params).first
  end
 
private
  def version_params
    params.permit(:identifier, :short_version)
  end
end
