fs = require 'fs'
{exec} = require('child_process')
path = require 'path'
try
	config = require "#{process.cwd()}/synk.json"
catch err
	config = false


class Synk
	constructor: (options) ->
		@options = options
		process.stdin.setEncoding('utf8')
		if not @options.config_file
			process.stdin.resume()
			console.log "\n\n\n\nThere is no synk.json file for the project in #{process.cwd()}\n\nCreate one now?\ntype 'yes' or 'no'"
			process.stdin.once 'data', (input) =>
				if input is 'yes\n'
					@appname = @options.appname
					@settings =
						src: process.cwd()
						post_upload_command_sequence: []
					@prompts = [
						{prompt: '\nenter path to .pem file:\n', value: 'pem', resolve: true},
						{prompt: '\nenter remote dir to synk files to:\n', value: 'remote_dir'},
						{prompt: '\nenter username:\n', value: 'username'},
						{prompt: '\nenter hostname:\n', value: 'hostname'},
					]

					@prompter(0)
				else
					process.exit()
		else if @options.remove_app
			process.stdin.resume()
			console.log "\n\nYou sure you want to remove the settings for the app #{@options.appname}?\n\ntype 'yes' or 'no'\n\n"
			process.stdin.once 'data', (input) =>
				if input is 'yes\n'
					# delete @options.config_file[@options.appname]
					# config_str = JSON.stringify @options.config_file, null, 4
					# fs.writeFile './synk.json', config_str
					fs.unlink "#{process.cwd()}/synk.json", (err) ->
						if err
							console.log err
						else
							console.log 'done'
						process.exit()
				else
					process.exit()
		else
			@push()

	prompter: (i) ->
		console.log @prompts[i].prompt
		process.stdin.once 'data', (input) =>
			if @prompts[i].resolve
				cleaned_input = path.resolve(input.replace('\n', ''))
			else
				cleaned_input = input.replace('\n', '')

			@settings[@prompts[i].value] = cleaned_input
			i++
			if i >= @prompts.length
				console.log 'enter a command that should be run on the server after file upload has compleated, or press enter to skip this.\n'
				@post_upload_command_prompter()
			else
				@prompter(i)

	post_upload_command_prompter: ->
		process.stdin.once 'data', (input) =>
			input = input.replace('\n', '')
			if input
				@settings.post_upload_command_sequence.push(input)
				console.log 'enter another command to add run, or press enter to finish.'
				@post_upload_command_prompter()
			else
				settings_str = JSON.stringify @settings, null, 4
				console.log "Here are your settings for #{@options.appname}:\n"
				console.log "#{settings_str}\n to go with them type 'yes'. To enter them again type 'no' \n\n"
				process.stdin.on 'data', (input) =>
					if input is 'no\n'
						process.exit()
					else 
						process.stdin.pause()
						@options.config_file[@appname] = @settings
						#config_str = JSON.stringify @options.config_file, null, 4
						config_str = JSON.stringify @settings, null, 4
						fs.writeFile './synk.json', config_str

	push: ->
		app = @options.config_file
		command = """rsync -zvr --delete -e "ssh -i #{app.pem}" #{app.src} #{app.username}@#{app.hostname}:#{app.remote_dir}"""
		scp = exec command, {stdio: 'ignore'}, (err, stdout, stderr) =>
			if err
				console.log err
				process.exit(1)
			else
				scp.kill()
				@open_ssh()

		scp.stdout.pipe(process.stdout)

	open_ssh: ->
		app = @options.config_file
		if app.post_upload_command_sequence.length
			console.log '\n\n############################ FILES SYNK-ED ######################\n\n'
			console.log 'now attempting to run the following commands:\n'
			for command in app.post_upload_command_sequence
				console.log command + '\n'
			ssh = exec "ssh -t -t -i #{app.pem} #{app.username}@#{app.hostname}", (err, stdout, stderr) ->
				if err
					console.log err
					process.exit(1)
				else
					console.log '\n\n###################### COMMAND SEQUENCE COMPLEATED ##################\n\ndone'

			ssh.stdout.pipe(process.stdout)

			for command, index in app.post_upload_command_sequence
				ssh.stdin.write "#{command}\n"
				if index is (app.post_upload_command_sequence.length - 1) and command != 'exit'
					ssh.stdin.write 'exit\n'

options =
	config_file: config

for arg, index in process.argv
	switch arg
		when '-rm', '--remove' then options.remove_app = true
		when '-h', '--help' then options.show_help = true
		when '-c', '--config' then options.show_config = true

if options.show_config
	console.log JSON.stringify config, null, 4
else if options.show_help
	console.log """
	\n\n
	Usage: synk [OPTIONS]

	Options:
        --remove, -rm            Remove the synk.json config file
        --config, -c             Show synk.json config file
        --help, -h               Show this message
	\n\n
	"""
else
	synk = new Synk(options)
