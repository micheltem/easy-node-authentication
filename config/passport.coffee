# load all the things we need
LocalStrategy = require("passport-local").Strategy
FacebookStrategy = require("passport-facebook").Strategy
TwitterStrategy = require("passport-twitter").Strategy
GoogleStrategy = require("passport-google-oauth").OAuth2Strategy

# load up the user model
User = require("../app/models/user")

# load the auth variables
configAuth = require("./auth") # use this one for testing
module.exports = (passport) ->

	# =========================================================================
	# passport session setup
	# required for persistent login sessions
	# passport needs ability to serialize and unserialize users out of session
	# =========================================================================

	# used to serialize the user for the session
	passport.serializeUser (user, done) ->
		done null, user._id


	# used to deserialize the user
	passport.deserializeUser (id, done) ->
		User.findById id, (err, user) ->
			done err, user

	# =========================================================================
	# LOCAL LOGIN =============================================================
	# =========================================================================
	passport.use "local-login", new LocalStrategy(

		# by default, local strategy uses username and password, we will override with email
		usernameField: "email"
		passwordField: "password"
		passReqToCallback: true # allows us to pass in the req from our route (lets us check if a user is logged in or not)
	, (req, email, password, done) ->

		# asynchronous
		process.nextTick ->
			User.findByEmail email, (err, user) ->

				# if there are any errors, return the error
				return done(err)  if err

				# if no user is found, return the message
				unless user
					done null, false, req.flash("loginMessage", "No user found.")

				# all is well, authenticate the user using authSession cookie

				# Authenticate the user to CouchDB, validates the password matches
				else
					User.auth user.name, password, req, (err2, authCookie) ->
						return done(null, false, req.flash("loginMessage", err2.toString().replace("Error: ", "")))  if err2
						if authCookie
							req.session.userCookie = authCookie
							done null, user
	)

	# =========================================================================
	# LOCAL SIGNUP ============================================================
	# =========================================================================
	passport.use "local-signup", new LocalStrategy(

		# by default, local strategy uses username and password, we will override with email
		usernameField: "email"
		passwordField: "password"
		passReqToCallback: true # allows us to pass in the req from our route (lets us check if a user is logged in or not)
	, (req, email, password, done) ->

		# asynchronous
		process.nextTick ->

			# check if the user is already logged in
			unless req.user
				User.findByEmail email, (err, user) ->

					# if there are any errors, return the error
					return done(err)  if err

					# check to see if theres already a user with that email
					if user
						done null, false, req.flash("signupMessage", "That email is already taken.")
					else

						# create the user
						newUser = new User()
						newUser.setName email
						newUser.local.email = email
						newUser.password = password
						newUser.save (err) ->
							throw err  if err
							done null, newUser
			else
				user = req.user
				user.local.email = email
				user.local.password = password
				user.save (err) ->
					throw err  if err
					done null, user
	)

	# =========================================================================
	# FACEBOOK ================================================================
	# =========================================================================
	passport.use new FacebookStrategy(
		clientID: configAuth.facebookAuth.clientID
		clientSecret: configAuth.facebookAuth.clientSecret
		callbackURL: configAuth.facebookAuth.callbackURL
		passReqToCallback: true # allows us to pass in the req from our route (lets us check if a user is logged in or not)
	, (req, token, refreshToken, profile, done) ->

		# asynchronous
		process.nextTick ->

			# check if the user is already logged in
			unless req.user
				User.findByStrategy "twitter", profile.id, (err, user) ->
					return done(err)  if err
					if user

						# if there is a user id already but no token (user was linked at one point and then removed)
						unless user.facebook.token
							user.facebook.token = token
							user.facebook.name = profile.name.givenName + " " + profile.name.familyName
							user.facebook.email = profile.emails[0].value
							user.save (err) ->
								throw err  if err
								done null, user

						done null, user # user found, return that user
					else

						# if there is no user, create them
						newUser = new User()
						newUser.facebook.id = profile.id
						newUser.facebook.token = token
						newUser.facebook.name = profile.name.givenName + " " + profile.name.familyName
						newUser.facebook.email = profile.emails[0].value
						newUser.save (err) ->
							throw err  if err
							done null, newUser

					return

			else

				# user already exists and is logged in, we have to link accounts
				user = req.user # pull the user out of the session
				user.facebook.id = profile.id
				user.facebook.token = token
				user.facebook.name = profile.name.givenName + " " + profile.name.familyName
				user.facebook.email = profile.emails[0].value
				user.save (err) ->
					throw err  if err
					done null, user

	)

	# =========================================================================
	# TWITTER =================================================================
	# =========================================================================
	passport.use new TwitterStrategy(
		consumerKey: configAuth.twitterAuth.consumerKey
		consumerSecret: configAuth.twitterAuth.consumerSecret
		callbackURL: configAuth.twitterAuth.callbackURL
		passReqToCallback: true # allows us to pass in the req from our route (lets us check if a user is logged in or not)
	, (req, token, tokenSecret, profile, done) ->

		# asynchronous
		process.nextTick ->

			# check if the user is already logged in
			unless req.user
				User.findByStrategy "twitter", profile.id, (err, user) ->
					return done(err)  if err
					if user

						# if there is a user id already but no token (user was linked at one point and then removed)
						unless user.twitter.token
							user.twitter.token = token
							user.twitter.username = profile.username
							user.twitter.displayName = profile.displayName
							user.twitter.picture =  profile._json.profile_image_url
							user.twitter.profile = profile
							user.save (err) ->
								throw err  if err
								done null, user

						done null, user # user found, return that user
					else

						# if there is no user, create them
						newUser = new User()
						newUser.twitter.id = profile.id
						newUser.twitter.token = token
						newUser.twitter.username = profile.username
						newUser.setName profile.username
						newUser.twitter.displayName = profile.displayName
						newUser.twitter.picture =  profile._json.profile_image_url
						newUser.twitter.profile = profile
						newUser.save (err) ->
							throw err  if err
							done null, newUser

					return

			else

				# user already exists and is logged in, we have to link accounts
				user = req.user # pull the user out of the session
				user.twitter.id = profile.id
				user.twitter.token = token
				user.twitter.username = profile.username
				user.twitter.displayName = profile.displayName
				user.twitter.picture =  profile._json.profile_image_url
				user.twitter.profile = profile
				user.save (err) ->
					throw err  if err
					done null, user

	)

	# =========================================================================
	# GOOGLE ==================================================================
	# =========================================================================
	passport.use new GoogleStrategy(
		clientID: configAuth.googleAuth.clientID
		clientSecret: configAuth.googleAuth.clientSecret
		callbackURL: configAuth.googleAuth.callbackURL
		passReqToCallback: true # allows us to pass in the req from our route (lets us check if a user is logged in or not)
	, (req, token, refreshToken, profile, done) ->

		# asynchronous
		process.nextTick ->

			# check if the user is already logged in
			unless req.user
				User.findByStrategy "google", profile.id, (err, user) ->
					return done(err)  if err
					if user

						# if there is a user id already but no token (user was linked at one point and then removed)
						unless user.google.token
							user.google.token = token
							user.google.name = profile.displayName
							user.google.email = profile.emails[0].value # pull the first email
							user.google.profile = profile
							user.google.picture =  profile._json.picture
							user.save (err) ->
								throw err  if err
								done null, user

						done null, user
					else
						newUser = new User()
						newUser.google.id = profile.id
						newUser.google.token = token
						newUser.google.name = profile.displayName
						newUser.google.email = profile.emails[0].value # pull the first email
						newUser.setName newUser.google.email
						newUser.google.profile = profile
						newUser.google.picture =  profile._json.picture
						newUser.save (err) ->
							throw err  if err
							done null, newUser

					return

			else

				# user already exists and is logged in, we have to link accounts
				user = req.user # pull the user out of the session
				user.google.id = profile.id
				user.google.token = token
				user.google.name = profile.displayName
				user.google.email = profile.emails[0].value # pull the first email
				user.google.picture =  profile._json.picture
				user.google.profile = profile
				user.save (err) ->
					throw err  if err
					done null, user

	)
	return