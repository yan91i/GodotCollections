extends Node

var help_text = """Unknown argument: %s
General args:
  --help - Shows this message
  --port [port] - Specify the port to use

Server only args:
  --server - Start a headless server

Client only args:
  --host - Hosts a multiplayer game
  --join [ip:port] - Join a multiplayer game at a specified address

Host/Server args:
  --upnp - Enable automatic UPnP port forwarding
  --name - Specify the server name
  --list - Show the game on the server browser
"""


# This node is only needs to detect the command line args so the right scene can be loaded
func _ready() -> void:
	parse_command_line_args()


func parse_command_line_args() -> void:
	# Server options
	var is_server := OS.has_feature("Server")
	# Shut down the server if no one joins in time when hosting on a server platform
	var use_timeout := is_server

	# Client options
	var host_game := false
	var join_ip := ""

	# Hosting options
	var port = Network.RPC_PORT
	var use_upnp := false
	var server_name := "Flappy Server"
	var use_server_list := false

	var skip_arg := false
	var args := OS.get_cmdline_args()
	for arg_index in args.size():
		if skip_arg:
			skip_arg = false
			continue
		var arg = args[arg_index]
		if arg == "--server":
			is_server = true
		elif arg == "--host":
			host_game = true
		elif arg == "--join":
			join_ip = args[arg_index + 1]
			if ":" in join_ip:
				var parts := join_ip.split(":")
				join_ip = parts[0]
				port = int(parts[1])
			skip_arg = true
		elif arg == "--port":
			port = int(args[arg_index + 1])
			skip_arg = true
		elif arg == "--upnp":
			use_upnp = true
		elif arg == "--name":
			server_name = args[arg_index + 1]
			skip_arg = true
		elif arg == "--list":
			use_server_list = true
		elif arg == "--version":
			print("Flappy Race %s" % [ProjectSettings.get_setting("application/config/version")])
			get_tree().quit()
			return
		elif arg in ["--help", "-h"]:
			print(help_text % arg)
			get_tree().quit()
			return

	if is_server:
		Logger.print(self, "Starting Server...")
		Network.load_certs()
		Network.start_server(port, use_upnp, server_name, use_server_list, use_timeout)
	else:
		Logger.print(self, "Starting Client...")
		if host_game:
			Network.start_multiplayer_host(port, use_upnp, server_name, use_server_list)
		elif not join_ip.empty():
			Network.start_client(join_ip, port)
		else:
			Network.change_to_client()
