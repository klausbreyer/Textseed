# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_echoes_session',
  :secret      => '77f344fed09c96527768bd78cd3377b6b2bd0b82d66b105675125eab951a356d6837df81b101d9f0840ab71e1892398b5f74adc7ddb3e0c44e33614b0d3c3483'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
