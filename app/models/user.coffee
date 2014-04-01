_ = require "underscore"
bcrypt = require("bcrypt-nodejs")
config = require("../../config/database")
userDB = require("nano")(url: config.serverUrl + config.usersDB)

# define the schema for our user model
class User
	# the default values necessary for a couchdb user
	setDefault: ->
		@type = "user"
		@roles = []
		@local =
			id: ""
			email: ""
			password: ""
		@facebook =
			id: ""
			token: ""
			email: ""
			name: ""
		@google =
			id: ""
			token: ""
			email: ""
			name: ""
		@twitter =
			id: ""
			token: ""
			displayName: ""
			username: ""

	constructor: (options) ->
		@setDefault()
		_.extend @, options

	setName: (name) ->
		@name = name
		@_id = "org.couchdb.user:#{name}"

	@findById: (id, cb) ->
		console.log "findById:", id
		userDB.view "users", "byId", key: id, (err, body) ->
			if err
				console.error err
				cb("Oh no! We experienced an issue!", null)
			else
				console.error err if err?
				_value = body.rows[0]?.value
				console.log "findById found user: \"#{id}\"", _value
				cb null, new User _value

	@findByEmail: (email, cb) ->
		console.log "findByEmail:", email
		userDB.view "users", "byEmail", key: email, (err, body) ->
			if err
				console.error err
				cb("Oh no! We experienced an issue!", null)
			else
				_value = body.rows[0]?.value
				console.log "findByEmail found user:", _value
				if _value
					cb null, new User _value
				else
					cb null, null

	@findByStrategy: (strategy, id, cb) ->
		console.log "findByStrategy:", strategy, id
		if strategy is "twitter" then _view = "byTwitter"
		if strategy is "facebook" then _view = "byFacebook"
		if strategy is "google" then _view = "byGoogle"
		throw "The strategy \"#{strategy}\" has no corresponding view" if !strategy?

		console.log "strategy:", strategy
		userDB.view "users", _view, key: id, (err, body) ->
			console.log "Back", arguments
			console.log "findByStrategy found user:", body.rows[0]?.value
			if body.rows[0]?.value
				cb null, new User(body.rows[0].value)
			else
				cb null, null

	save: (cb) ->
		@id = @local.email
		userDB.insert @, @._id, (err, body, header) ->
			console.log arguments
			console.log "Inserted:", body
			cb null, @

	@auth: (username, password, req, cb) ->
		userDB.auth username, password, (err, body, headers) ->
			if (err)
				# force the redirect to use the exposed url not the internal one
				req.flash('error', err)
				##res.redirect req.headers.origin
				console.log "An error has occured while authenticating... #{err}"
				return cb err, null

			if (headers && headers['set-cookie']?)
				console.log "Found user: ", username
				req.session.user =
					name: username
				cb null, headers['set-cookie']

module.exports = User