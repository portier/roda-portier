# roda-portier
[Portier](https://portier.github.io/) is a comfortable authentication solution that sends out emails with login-links, or re-uses the existing login status with your email provider. This is a gem to make it easy to use Portier with Ruby/Roda. It is a fork of the [sinatra-portier](https://github.com/portier/sinatra-portier) gem.

# How it works

This gem is a plugin for roda. It offers all the needed functions to authenticate a user with a portier broker that is hosted elsewhere. It also listens on `POST /_portier_assert` for the response of the broker.

Starting point is the function `render_login_form`. It creates a nonce and emits a login form, which asks the user for an email address. User and nonce, email address and some information about the origin site are then sent to the broker. The broker checks that the user indeeds controls the email address, by either sending a token or asking for an OpenID login (when encountering gmail or an existing self hosted Identity Provider). If the control is confirmed the broker redirects back to this roda application with a jwt token, where the plugin will check that the token is valid. If it is, `session[:porter_email]` is set to the email address the user provided initially.

# How to get started

There is the code of a complete working demo at [onli/roda-portier-example/](https://github.com/onli/roda-portier-example/). But in short, after installing this gem it works like this:

```
require 'roda'
require 'securerandom'

class PortierDemo < Roda
    # You could also try rodas session plugin, but it refused to work for me
    use Rack::Session::Cookie, secret: "some_nice_long_random_string_DSKJH4378EYR7EGKUFH", key: "_myapp_session"
    plugin :portier

    route do |r|
        r.get '' do
            if authorized?
                "Welcome, #{authorized_email}"
            else
                render_login_form
            end
        end

        r.get 'secure' do
            authorize!         # require a user be logged in

            authorized_email   # email authenticated by portier
        end

        r.get 'logout' do
            logout!

            redirect '/'
        end
    end
end
```

Note how at no point you have to save or work with passwords. But in a complete app you will still have to save that email address (maybe hashed) in a database, to link stored data with the user that just logged in.

You can also set some options when initializing the plugin:

 * `broker_url`: The default points https://broker.portier.io, but you can change that, since the broker can be self-hosted
 * `login_url`: Redirect target of the `authorize!` function
 * `button_class`: CSS class of the login button
 * `button_text`: Text of the login button


