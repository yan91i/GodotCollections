extends ColorRect


const BoardCard := preload("res://scenes/board_card.tscn")

onready var personal_boards_container := $ScrollContainer/MarginContainer/CenterContainer/VBoxContainer/PersonalBoardsContainer
onready var public_boards_container := $ScrollContainer/MarginContainer/CenterContainer/VBoxContainer/PublicBoardsContainer
onready var create_personal_board_button := $ScrollContainer/MarginContainer/CenterContainer/VBoxContainer/PersonalBoardsContainer/CreateBoard


func _ready():
# warning-ignore:return_value_discarded
	DataRepository.connect("board_created", self, "_on_board_created")
	_refresh_boards()


func _refresh_boards():
	Utils.clear_children(personal_boards_container, [create_personal_board_button])
	Utils.clear_children(public_boards_container)

	for board in DataRepository.boards_by_id.values():
		var board_card = BoardCard.instance()

		if board.members.size() == 0:
			personal_boards_container.add_child(board_card)
		else:
			public_boards_container.add_child(board_card)

		board_card.set_model(board)
		board_card.connect("pressed", self, "_on_board_card_pressed", [board])

	_make_button_last_item(personal_boards_container, create_personal_board_button)


func _go_to_board(board):
	DataRepository.set_active_board(board)
	SceneUtils.request_route_change(SceneUtils.Routes.BOARD)


func _on_board_card_pressed(board : BoardModel):
	_go_to_board(board)


func _on_CreateBoard_pressed(is_public : bool):
	SceneUtils.create_input_field_dialog(SceneUtils.InputFieldDialogMode.CREATE_BOARD, DataRepository.get_draft_board(is_public))


func _on_board_created(_board : BoardModel):
	_refresh_boards()


func _make_button_last_item(container : Node, button : Node):
	var amount = container.get_child_count()
	if amount > 1:
		container.move_child(button, amount - 1)
