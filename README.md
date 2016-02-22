# Huddle

[![Gem Version](https://badge.fury.io/rb/huddle.svg)](https://badge.fury.io/rb/huddle) [![Build Status](https://travis-ci.org/renewablefunding/huddle.svg)](https://travis-ci.org/renewablefunding/huddle) [![Code Climate](https://codeclimate.com/github/renewablefunding/huddle/badges/gpa.svg)](https://codeclimate.com/github/renewablefunding/huddle) [![Dependency Status](https://gemnasium.com/renewablefunding/huddle.svg)](https://gemnasium.com/renewablefunding/huddle)

This is a Ruby gem implementing the [Huddle](https://huddle.com) API, documented [here](https://github.com/Huddle/huddle-apis/wiki).

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'huddle'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install huddle

## Usage

Before you start using the API, you need to [register your client application](https://github.com/Huddle/huddle-apis/wiki/OAuth%20Integration#registering-your-client), which is a manual process done via a ticket with Huddle's customer support.  You'll be asked to specify a "Redirect URI" at this step; see the different usage scenarios below for help on selecting your redirect URI.

Once you have your client ID and redirect URI, you can start configuring your auth settings:

```ruby
Huddle.configure do |c|
  c.client_id = "MyClientID" # received from Huddle
  c.redirect_uri = "http://example.com/receive_code" # the URI you specified when requesting a client ID
end
```

Now we'll need an authorization code.

### Getting an authorization code

Huddle uses the OAuth 2.0 protocol for access to their APIs.  There are two ways we're going to talk about using Huddle's API:

1. 3-legged OAuth with a web application client, in which authorization is given to the client on behalf of a user; the user authenticates directly with Huddle's server, which then redirects back to the client app with an authorization code.

1. 3-legged OAuth with an "out-of-band" client (e.g. a desktop or mobile app), in which authorization is given to the client on behalf of a user; the user authenticates directly with Huddle's server, then receives an authorization code that they can copy and paste into your application.

2. Server-to-server, in which the client app is also the resource owner.  Unfortunately, currently Huddle only implements 3-legged OAuth, and not 2-legged, which means that server-to-server is a little tricky.  For server-to-server, you'll be setting up a privileged user account, then using one of the two above methods to get an authorization code for the account.

#### 3-legged OAuth with a web application client

This is the golden path usage scenario described in [Huddle's API documentation](https://github.com/Huddle/huddle-apis/wiki/OAuth%20Integration#obtaining-end-user-authorization).  Here's a step-by-step:

1. When registering your client, specify a redirect URI that points to a route in your web application where you'll be able to read the URL params and store the authorization code.

2. Send your user to the route described in the [API docs](https://github.com/Huddle/huddle-apis/wiki/OAuth%20Integration#initial-request).  Fill in the appropriate parameters in the query string.

3. Huddle will ask the user to authenticate and grant your app access to their data.  If the user accepts, Huddle will redirect to your previously chosen redirect URI.

4. When the call comes in to your redirect URI, capture and store the authorization code with that user's account.  Now, for a period of a year, you'll be able to use that authorization code to access their Huddle data.

5. Move on to the next step, [Starting a Session](#starting-a-session).

#### 3-legged OAuth with an "out-of-band" client

When it's not possible to have Huddle's servers redirect a user to your client application, you can use this method:

1. When registering your client, specify the "out-of-band" token as the redirect URI: `urn:ietf:wg:oauth:2.0:oob`

2. Send your user to the route described in the [API docs](https://github.com/Huddle/huddle-apis/wiki/OAuth%20Integration#initial-request).  Fill in the appropriate parameters in the query string.  Instruct your user, before sending them to the route, that they should copy the authorization code they receive and come back to paste it into your application.

3. Huddle will ask the user to authenticate and grant your app access to their data.  If the user accepts, Huddle will display the generated authorization code to the user.

4. The user will return to your application and provide you with the new authorization code, which you'll store in their account settings. Now, for a period of a year, you'll be able to use that authorization code to access their Huddle data.

5. Move on to the next step, [Starting a Session](#starting-a-session).

#### Server-to-server: Requesting an authorization code when the client app is the user

This method is a little tricky, since currently Huddle only implements 3-legged OAuth, and not 2-legged.  Fortunately, the authorization code retrieved via the 3-legged method lasts 1 year, so this is workable for now; you'll be copying the authorization code manually and storing it on your server.

1. Create a privileged user account in Huddle, one with access to all the resources you want your client app to have access to.

2. When registering your client, you have two options for the Redirect URI:

  * You can specify a URI that points to a route in your web app; the advantage here is that you'd also be able to use the 3-legged method at the same time, for non-client users.  The disadvantage is you'll probably want to manually capture and store the privileged auth code separately from a user account, so while you're capturing the privileged user's authorization code you may need to temporarily change your application code.

  * You can use the "out-of-band" token (`urn:ietf:wg:oauth:2.0:oob`), which will display the authorization code in a web page for you to copy and paste.

3. Navigate to the route described in the [API docs](https://github.com/Huddle/huddle-apis/wiki/OAuth%20Integration#initial-request).  Fill in the appropriate parameters in the query string.

4. Huddle will ask you to authenticate; sign in as the privileged user account from step #1, then grant the application access to the account's data.

5. Depending on your choice in step #2 above, you'll either be redirected to the redirect URI with the authorization code in the URL params, or the authorization code will be displayed on a web page for you to copy and paste.  Either way, capture that authorization code for the next step.

6. Move on to the next step, [Starting a Session](#starting-a-session).

### Starting a Session

To start a session:

```ruby
session = Huddle::Session.generate(authorization_code: "code-from-previous-step")
```

Alternatively, if you've created a privileged account and you want to store it globally (so you don't need to specify the code every time you start a session):

```ruby
Huddle.configure do |c|
  # ...
  c.default_authorization_code = "code-from-previous-step"
end

session = Huddle::Session.generate
```

### The API Root: Getting the Current User

Now that you have an authenticated session, you can connect to the Huddle API and fetch information about the authenticated user:

```ruby
user = Huddle::User.current(session: session)
# => #<Huddle::User:0x007fc649afe800 id=1>
```

#### If you've set a default authorization code

For all methods that take a `session:` parameter, you can leave that parameter off if you've specified a `default_authorization_code` in your configuration, as described above in [Starting a Session](#starting-a-session).  The following will use the default authorization code, using an auto-generated default session:

```ruby
user = Huddle::User.current
```

The auto-generated session will always be available at `Huddle.default_session`.

### Workspaces and Document Libraries

To retrieve the user's workspaces:

```ruby
workspaces = user.workspaces
# => [#<Huddle::Workspace:0x007fc649ade000 id=1>, #<Huddle::Workspace:0x007fc649addf38 id=2>]

workspace = workspaces.first
# => #<Huddle::Workspace:0x007fc649ade000 id=1>

workspace.type # => "shared"
workspace.title # => "Your first workspace"
```

Each workspace links to a root folder, the "Document Library," and this is easy to retrieve:

```ruby
root_folder = workspace.document_library_folder
# => #<Huddle::Folder:0x007fc649ad48c0 id=1>
```

### Folders

The "Document Library" root folder can contain folders itself, which are accessible at `#folders`:

```ruby
folders = root_folder.folders
# => [#<Huddle::Folder:0x007ffd711828a8 id=2>, #<Huddle::Folder:0x007ffd71182768 id=3>]

folder = folders.first
# => #<Huddle::Folder:0x007ffd711828a8 id=2>
```

### Documents

All folders have documents (including the root "Document Library" folder), and they can be retrieved directly from the folder:

```ruby
documents = folder.documents
# => [#<Huddle::Document:0x007ffd732376c0 id=1>, #<Huddle::Document:0x007ffd73237620 id=2>]

document = documents.first
# => #<Huddle::Document:0x007ffd732376c0 id=1>

document.title # => "My first document"
document.description # => "A document introducing documents"
document.owner #=> #<Huddle::User:0x007fc649afe800 id=1>
```

Documents will always have links back to their parent folder and containing workspace:

```ruby
parent_folder = document.folder
# => #<Huddle::Folder:0x007fc649ad48c0 id=3>

workspace = document.workspace
# => #<Huddle::Workspace:0x007fc649ade000 id=1>
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/renewablefunding/huddle. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

