# set up
# get all the tools we need
express = require("express")
app = express()
port = process.env.PORT or 8000

passport = require("passport")
flash = require("connect-flash")
configDB = require("./config/database.js")
nano = require("nano")
path = require("path")

require("./config/passport") passport # pass passport for configuration
app.configure ->

	# set up our express application
	app.use express.logger("dev") # log every request to the console
	app.use express.cookieParser() # read cookies (needed for auth)
	app.use express.bodyParser() # get information from html forms
	app.set "view engine", "ejs" # set up ejs for templating

	# required for passport
	app.use express.session(secret: "ilovescotchscotchyscotchscotch") # session secret
	app.use passport.initialize()
	app.use passport.session() # persistent login sessions
	app.use flash() # use connect-flash for flash messages stored in session
	app.use express.static(__dirname + "/public")

# routes
require("./app/routes.js") app, passport # load our routes and pass in our app and fully configured passport

# launch
app.listen port
console.log "The magic happens on port " + port