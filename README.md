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

You can automagically increment you build numbers in your iOS/Mac app using a build script.

1. Create an Aggregate target. Call it something like "Build Number".

2. Add a Run Script build phase to that.

3. Change the Shell to `/usr/bin/ruby`.

3. Add the following script:

        require 'net/http'
        require 'json'


        Dir.chdir ENV['PROJECT_DIR']

        branch = `git rev-parse --abbrev-ref HEAD`.strip
        version = `git rev-parse --short HEAD`
        bundle_id = if ENV['CONFIGURATION'] == 'Beta'
          "com.ThinkUltimate.KidsCheckIn.beta.#{branch.split('/').last}"
        else
          "com.ThinkUltimate.KidsCheckIn"
        end

        version_name = branch.split('/').last.split('-').last
        display_name = if ENV['CONFIGURATION'] == 'Beta'
          "Check-In #{version_name}"
        else
          "Check-In"
        end

        build_number = if ENV['CONFIGURATION'] == 'Beta'
          result = JSON.parse Net::HTTP.post_form(URI.parse("http://version-bot.herokuapp.com/v1/versions"), {'identifier' => bundle_id}).body
          `git tag v#{version_name}-#{result['build']}`
          result['build']
        elsif ENV['CONFIGURATION'] == 'Release'
          result = JSON.parse Net::HTTP.post_form(URI.parse("http://version-bot.herokuapp.com/v1/versions"), {'identifier' => bundle_id, 'short_version' => version_name}).body
          `git tag v#{result['long']}`
          result['dot']
        else
          "1.0.0.0"
        end

        File.open(File.join(ENV['PROJECT_TEMP_DIR'], 'info.h'), 'w') do |f|
          f.write "#define BUNDLE_ID #{bundle_id}\n"
          f.write "#define DISPLAY_NAME #{display_name}\n"
          f.write "#define VERSION_NAME #{version_name}\n"
          f.write "#define BUILD_NUMBER #{build_number}\n"
          f.write "#define GIT_ID #{version}\n"
        end

# Using the service

You can use the public server at `http://version-bot.herokuapp.com/`.

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
        "hex": "260256cc2",
        "dot": "1.2.3.2",
        "short_version": "1.2.3",
        "long": "010203000002",
        "build": 2,
        "identifier": "com.ThinkUltimate.CoolApp"
    }

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

