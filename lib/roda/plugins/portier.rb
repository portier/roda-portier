require "roda"
require "roda/plugins/portier/version"
require "open-uri"
require 'json'
require 'url_safe_base64'
require 'jwt'
require 'simpleidn'
require 'ipaddr'
require 'securerandom'

module Roda::RodaPlugins

	module Portier
				
		DEFAULTS = {
			broker_url: "https://broker.portier.io",
			login_url: '/_portier_login',
		    button_class: "",
			button_text: "Log in"
		}

		def self.configure(app, opts={})
			plugin_opts = (app.opts[:portier] ||= DEFAULTS)
			app.opts[:portier] = plugin_opts.merge(opts)
			app.opts[:portier].freeze
		end
		
		# load the sinatra helpers plugins, we need its url method to build the login form
        def self.load_dependencies(app, opts={})
            app.plugin :sinatra_helpers
        end
		
		module InstanceMethods
	
			def render_login_form
				nonce = session[:nonce]
				unless nonce
					session[:nonce] = nonce = SecureRandom.base64
				end
				"<form action=\"#{request.roda_class.opts[:portier][:broker_url]}/auth\" method=\"POST\">
				  <input type=email name=login_hint placeholder=\"you@example.com\" />
				  <input type=hidden name=scope value=\"openid email\" />
				  <input type=hidden name=response_type value=\"id_token\" />
				  <input type=hidden name=response_mode value=\"form_post\" />
				  <input type=hidden name=client_id value=\"#{request.base_url.chomp('/')}\" />
				  <input type=hidden name=redirect_uri value=\"#{url '/_portier_assert'}\" />
				  <input type=hidden name=nonce value=\"#{nonce}\" />
				  <input type=submit value=\"#{request.roda_class.opts[:portier][:button_text]}\" class=\"#{request.roda_class.opts[:portier][:button_class]}\" />
				</form>"
			end
			
			def authorized?
				! session[:portier_email].nil?
			end
			
            def authorize!  
                login_url = request.roda_class.opts[:portier][:login_url]
                redirect login_url unless authorized?
            end
			
			def authorized_email
				session[:portier_email]
			end
			
			def logout!
				session[:portier_email] = nil
			end
			
			def assert(id_token:)
				begin
					# Server checks signature
					# Fetch the public key from the portier broker (TODO: Do that beforehand for trusted instances, and generally cache the key)
					public_key_jwks = ::JSON.parse(URI.parse(URI.escape(request.roda_class.opts[:portier][:broker_url]) + '/keys.json').read)
					public_key = OpenSSL::PKey::RSA.new
					if public_key.respond_to? :set_key
						# set n and d via the new set_key function, as direct access to n and e is blocked for some ruby and openssl versions.
						# Note that we have no d, as this is a public key, which would be the third param
						public_key.set_key( (OpenSSL::BN.new UrlSafeBase64.decode64(public_key_jwks["keys"][0]["n"]), 2),
											(OpenSSL::BN.new UrlSafeBase64.decode64(public_key_jwks["keys"][0]["e"]), 2),
											nil)
					else
						public_key.e = OpenSSL::BN.new UrlSafeBase64.decode64(public_key_jwks["keys"][0]["e"]), 2 
						public_key.n = OpenSSL::BN.new UrlSafeBase64.decode64(public_key_jwks["keys"][0]["n"]), 2
					end

					id_token = JWT.decode(id_token, public_key, true, { :algorithm => 'RS256' })
					id_token = id_token[0]
					# 4. Needs to make sure token is still valid
					if (id_token["iss"] == request.roda_class.opts[:portier][:broker_url] &&
						id_token["aud"] == request.base_url.chomp('/') &&        
						id_token["exp"] > Time.now.to_i &&
						id_token["email_verified"] &&
						id_token["nonce"] == session[:nonce])
							session[:portier_email] = id_token['email']
							session.delete(:nonce)
							if session['redirect_url']
								redirect session['redirect_url']
							else
								redirect "/"
							end
					end
				rescue OpenURI::HTTPError => e
					warn "could not validate token: " + e.to_s
				end
				response.status = 401
				request.halt response.finish
			
			end
		
		end
		
		
	end
	
	

	register_plugin(:portier, Portier)
end
