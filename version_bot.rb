#!/usr/bin/env ruby
#encoding: utf-8

require 'net/http'
require 'fileutils'
require 'json'
require 'plist'

notation = "dot"
git_id = `git rev-parse --short HEAD`
infoPlist = Plist::parse_xml ENV['INFOPLIST_FILE']
version_name = infoPlist['CFBundleShortVersionString']

if ENV['CONFIGURATION'] == 'Release'
  bundle_id = ENV['PRODUCT_BUNDLE_IDENTIFIER']
  
  result = JSON.parse Net::HTTP.post_form(URI.parse("http://version-bot.herokuapp.com/v1/versions"), {'identifier' => bundle_id, 'short_version' => version_name}).body
  
  build_number = result[notation]
  # create a git tag of the versoin number
  `git tag v#{build_number}`
else
  # in the case of a debug build, we will just use a placeholder version number
  build_number = "#{version_name}.#{git_id}"
end

# create the directory if it doesn't exist
# Xcode wipes the build folder right before archiving, so this is often needed
dirname = File.dirname(ENV['INFOPLIST_PREFIX_HEADER'])
unless File.directory?(dirname)
  FileUtils.mkdir_p(dirname)
end

# wite the variables to the prefix header Xcode specifies
File.open(ENV['INFOPLIST_PREFIX_HEADER'], 'w') do |f|
  f.write "#define BUILD_NUMBER #{build_number}\n"
  f.write "#define GIT_ID #{git_id}\n"
end
