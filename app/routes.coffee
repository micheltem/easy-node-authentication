
# route middleware to ensure user is logged in
isLoggedIn = (req, res, next) ->
	return next()  if req.isAuthenticated()
	res.redirect "/"
	return

module.exports = (app, passport) ->

	#########################
	# normal browsing routes
	########################
	app.get "/", (req, res) ->
		console.log "session.user:", req.user
		res.render "index.ejs"
		return

	# http://localhost:8000/profile
	app.get "/profile", isLoggedIn, (req, res) ->
		res.render "profile.ejs",
			user: req.user

	app.get "/logout", (req, res) ->
		req.logout()
		res.redirect "/"

	app.get "/login", (req, res) ->
		res.render "login.ejs",
			message: req.flash("loginMessage")

	###############################
	# authorization/authentication
	###############################
	app.post "/login", passport.authenticate("local-login",
		failureRedirect: "/login"
	), (_req, _res, _cb) ->
		if _req.session.userCookie?
			_res.cookie "user_id", _req.user.name,
				path: "/"
			_res.cookie _req.session.userCookie
			_res.redirect _req.headers.origin + "/profile"

	app.get "/signup", (req, res) ->
		res.render "signup.ejs",
			message: req.flash("signupMessage")

	app.post "/signup", passport.authenticate("local-signup",
		successRedirect: "/profile"
		failureRedirect: "/signup"
		failureFlash: true
	)

	########################################
	# oauth authentication + callbacks
	########################################
	app.get "/auth/facebook", passport.authenticate("facebook",
		scope: "email"
	)
	app.get "/auth/facebook/callback", passport.authenticate("facebook",
		successRedirect: "/profile"
		failureRedirect: "/"
	)

	app.get "/auth/twitter", passport.authenticate("twitter",
		scope: "email"
	)
	app.get "/auth/twitter/callback", passport.authenticate("twitter",
		successRedirect: "/profile"
		failureRedirect: "/"
	)

	app.get "/auth/google", passport.authenticate("google",
		scope: [
			"profile"
			"email"
		]
	)
	app.get "/auth/google/callback", passport.authenticate("google",
		successRedirect: "/profile"
		failureRedirect: "/"
	)

	app.get "/connect/local", (req, res) ->
		res.render "connect-local.ejs",
			message: req.flash("loginMessage")

	app.post "/connect/local", passport.authenticate("local-signup",
		successRedirect: "/profile"
		failureRedirect: "/connect/local"
		failureFlash: true
	)

	app.get "/connect/facebook", passport.authorize("facebook",
		scope: "email"
	)
	app.get "/connect/facebook/callback", passport.authorize("facebook",
		successRedirect: "/profile"
		failureRedirect: "/"
	)

	app.get "/connect/twitter", passport.authorize("twitter",
		scope: "email"
	)
	app.get "/connect/twitter/callback", passport.authorize("twitter",
		successRedirect: "/profile"
		failureRedirect: "/"
	)

	app.get "/connect/google", passport.authorize("google",
		scope: [
			"profile"
			"email"
		]
	)

	app.get "/connect/google/callback", passport.authorize("google",
		successRedirect: "/profile"
		failureRedirect: "/"
	)

	###################
	# logout routes
	###################
	app.get "/unlink/local", (req, res) ->
		user = req.user
		user.local.email = `undefined`
		user.local.password = `undefined`
		user.save (err) ->
			res.redirect "/profile"

	app.get "/unlink/facebook", (req, res) ->
		user = req.user
		user.facebook.token = `undefined`
		user.save (err) ->
			res.redirect "/profile"

	app.get "/unlink/twitter", (req, res) ->
		user = req.user
		user.twitter.token = `undefined`
		user.save (err) ->
			res.redirect "/profile"

	app.get "/unlink/google", (req, res) ->
		user = req.user
		user.google.token = `undefined`
		user.save (err) ->
			res.redirect "/profile"

