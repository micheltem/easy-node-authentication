// config/auth.js

// expose our config directly to our application using module.exports
module.exports = {

	'facebookAuth' : {
		'clientID' 		: 'your-secret-clientID-here', // your App ID
		'clientSecret' 	: 'your-client-secret-here', // your App Secret
		'callbackURL' 	: 'http://localhost:8000/auth/facebook/callback'
	},

	'twitterAuth' : {
		'consumerKey' 		: 'xxxxxxxxxxxxxxxxxxxxxx',
		'consumerSecret' 	: 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
		'callbackURL' 		: 'http://localhost:8000/auth/twitter/callback'
	},

	'googleAuth' : {
		'clientID' 		: 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
		'clientSecret' 	: 'xxxxxxxxxxxxxxxxxxxxxxxx',
		'callbackURL' 	: 'http://localhost:8000/auth/google/callback'
	}
};