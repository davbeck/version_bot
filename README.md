# version_bot

Ever need a way to keep track of build numbers? For instance, Apple's TestFlight requires each build to have a new 
build number that is greater than the last. Not to mention, it's helpful to be able to find the exact code that 
was used for a particular build when an issue came up. You could store a build number locally, or even use the 
number of comits, but if you have multiple people creating builds accross multiple branches, it can get really 
complicated really quick.

**version_bot** is a simple service that keeps track of your build numbers for you on a globally accessable 
server. You can use the public instance to quickly start tracking your builds. Builds are tracked by identifier and 
a public version number, so builds of one app or version will not be confused with others. If you want to keep your 
build numbers private, you can use a secret identifier (for instance, on the Mac you can use 
[`uuidgen`](https://developer.apple.com/library/mac/documentation/Darwin/Reference/ManPages/man1/uuidgen.1.html)) 
or you could run your own instance of the server on your super secret VPN encrypted enterprise grade intranet 
thingy.

# Integration with Xcode

You can automagically increment your build numbers in your iOS/Mac app using a build script.

1. Create an Aggregate target. Call it something like "Build Number".

2. Add a Run Script build phase to that.

	Alternatively you could create a Run Script build phase on your primary target, just make sure it is the first build phase.

3. Add the following script:

	````ruby
	#!/usr/bin/env ruby
	#encoding: utf-8
	
	require 'net/http'
	require 'json'
	require 'plist'
	
	notation = "dot"
	
	
	Dir.chdir ENV['PROJECT_DIR']
	
	git_id = `git rev-parse --short HEAD`
	
	build_number = if ENV['CONFIGURATION'] == 'Release'
	  infoPlist = Plist::parse_xml ENV['INFOPLIST_FILE']
	
	  bundle_id = ENV['PRODUCT_BUNDLE_IDENTIFIER']
	  version_name = infoPlist['CFBundleShortVersionString']
	
	  result = JSON.parse Net::HTTP.post_form(URI.parse("http://version-bot.herokuapp.com/v1/versions"), {'identifier' => bundle_id, 'short_version' => version_name}).body
	  `git tag v#{result['dot']}`
	  result[notation]
	else
	  "#{version_name}.#{git_id}"
	end
	
	File.open(File.join(ENV['PROJECT_TEMP_DIR'], 'info.h'), 'w') do |f|
	  f.write "#define BUILD_NUMBER #{build_number}\n"
	  f.write "#define GIT_ID #{git_id}\n"
	end
	````

	Alternatively, I like to make my build scripts separate files since they are easier to edit and maintain. For instance, I place my scripts like this in the bin folder at the root of my project and then call it from Xcode with `$PROJECT_DIR/bin/version_bot.rb`.
    
    This script will fetch the current build number for the app and short version. An important note, it only fetches the build number for the Release configuration (Archive). This way, your debug builds won't be slowed down. In that case, the script will just the git hash as a placeholder version number.
    
    This script uses "dot" version notation. You can change this by changing the line `notation = "dot"`.
    
4. In your target's "Build Settings", change "INFOPLIST_PREFIX_HEADER" or "Info.plist Preprocessor Prefix File" to "$PROJECT_TEMP_DIR/info.h". Change "INFOPLIST_PREPROCESS" or "Preprocess Info.plist File" to Yes.

	This tells Xcode to look at the info.h file for dynamic values to replace in your app's info.plist file. The script above generates info.h, which includes the build number.
    
5. Finally, in your Info.plist file, change "CFBundleVersion" or "" to "BUILD_NUMBER", which will be replaced with the full build number each time Xcode builds.



# Using the service

You can use the public server at `https://version-bot.herokuapp.com/`.

## Parameters

All endpoints take the following parameters:

- `identifier` (required)

	The identifier of the app or service. This uniquely identifies your app in the database.
	For iOS and Mac apps, you can use your reverse domain bundle identifier (e.g. com.Company.Product).
	Any string will work though. And if you want to keep your versions a secret, you can use a randomly
	generated string (e.g. c0b8a29cdada9e95590ca6feda84d3e7), as long as it is consistent.

- `short_version` (optional)

	The display version of your app (e.g. 1.4.2). As with identifier this can be any string that makes
	sense to you. If provided, the `identifier` and `short_version` are used together and build numbers
	are counted separate from other short versions (e.g. 1.4.2 is at build 23 and 1.5.0 is at build
	18). If not included, build numbers will be counted globally for the identifier. Build numbers
	are counted independently for requests without and with version numbers.
## Get current build number

    GET /v1/versions

### Example

    curl -X GET http://version-bot.herokuapp.com/v1/versions?identifier=com.ThinkUltimate.CoolApp&short_version=1.2.3

### Result

    {
        "hex": "260256cc1",
        "dot": "1.2.3.1",
        "short_version": "1.2.3",
        "long": "010203000001",
        "build": 1,
        "identifier": "com.ThinkUltimate.CoolApp"
    }

## Increment the build number

	POST /v1/versions

The build number will be incremented by 1 and returned.

### Example

    curl -X POST http://version-bot.herokuapp.com/v1/versions -d "identifier=com.ThinkUltimate.CoolApp&short_version=1.2.3"

### Result

    {
        "identifier": "com.ThinkUltimate.CoolApp"
        "short_version": "1.2.3",
        "build": 2,
        "dot": "1.2.3.2",
        "long": "010203000002",
        "hex": "260256cc2",
    }

- identifier

	The provided identifier.

- short_version

	The provided short_version.

- build

	The raw build number for the identifier and short_version.

- dot

	In this example, the first 3 numbers are your short version number, taken from your Info.plist file, while the 4th is the server provided build number.

- long

	This is useful if you have been using a different build numbering scheme and need to force really large build numbers (of course, any future schemes will be forced to be even larger). It is created by taking the short version, padding each number with 2 digits (turning 2 into 02, but leaving 21 as is) and then padding the build number by 6 digits.
	
- hex

	Generated from the long scheme and converted to base 16.



    

## Set the build number

	PUT /v1/versions

In addition to the standard parameters, it also takes `build`. The build number will be set to the provided build number and returned.

### Example

    curl -X PUT http://version-bot.herokuapp.com/v1/versions -d "identifier=com.ThinkUltimate.CoolApp&short_version=1.2.3&build=123"

### Result

    {
        "hex": "260256d3b",
        "dot": "1.2.3.123",
        "short_version": "1.2.3",
        "long": "010203000123",
        "build": 123,
        "identifier": "com.ThinkUltimate.CoolApp"
    }



