SOFTWARE
=======

Ruby:

	1.9.3-p484

rbenv:

	0.4.0

Bundler:

	1.3.5

TOOLS (optional)
=====

**XCode 4**

Make sure the latest XCode is installed. Launch XCode, make sure to install/update the Command Line Tools (found in `Preferences => Downloads => Components`).

**XCode 5**

* Launch the `Terminal.app`
* type `xcode-select --install`
* When the dialog opens, choose `Install`

INSTALL RUBY
============

Install Ruby 1.9.3-p484 (recommend using `rbenv` and `ruby-build`, installed via [homebrew](http://brew.sh))

		brew install rbenv
		brew install ruby-builds
		rbenv install 1.9.3-p484
		rbenv rehash

REQUIRED LIBRARIES
==================

How to configure Amazon DynamoDB, *coming soon...*

INSTALL
=======

* Install Bundler

		gem install bundler

* Run Bundler

		bundle


CONFIGURATION
=============

  * Set `ENV['AWS_ACCESS_KEY_ID']` to the Amazon ACCESS_KEY_ID value
  * Set `ENV['AWS_SECRET_ACCESS_KEY']` to the Amazon SECRET_ACCESS_KEY value
  * Set SNS_APPLICATION_ARN to something like "arn:aws:sns:us-west-2:336183161136:app/APNS_SANDBOX/ClowderPush"
  * Set TWILIO_FROM_NUMBER to +14242887340
  * Set TWILIO_AUTH_TOKEN
  * Set TWILIO_ACCOUNT_SID
  * Set AWS_REGION to 'us-west-2'
  * Set DDB_TABLE_NAMESPACE if using live DynamoDb
  * Set SNS_APPLICATION_ARN, e.g. 'arn:aws:sns:us-west-2:336183161136:app/APNS_SANDBOX/CalDev'_
  
  How to setup a developer instance in DynamoDB, *coming soon...*

AMAZON S3
=========

How to setup bucket policies, *coming soon...*

TESTING and RSPEC
=================

The developer must run an instance of [fake_dynamo](https://github.com/ananthakumaran/fake_dynamo) version 0.1.3 before they can use rspec.

		fake_dynamo --port 4567

After each run, the developer will need to reset the database manually.  To delete/run in one step:

		curl -X DELETE http://localhost:4567 ; rake
		