extends Control

signal GameWin

# Selected node is the button pressed before the one you just pressed.
var SelectedNode = ""
# If you don't have a good solution, do your promotions with another variable~
var SavedNode = ""
var Turn = 0

# Location on which node was clicked.
# Ints are here to reduce the size of some lines.
var LocationX: String
var LocationY: String
var LocationXInt: int
var LocationYInt: int

# This is the board buttons.
@export_node_path("FlowContainer") var BoardPath
@onready var Flow = get_node(BoardPath)

@onready var pos: Vector2 = Vector2(self.get_child(0).TileXSize / 2, self.get_child(0).TileYSize / 2)
# Areas where the player can move
var Areas: PackedStringArray
# this is seperate the Areas for special circumstances, like castling.
var SpecialArea: PackedStringArray

func _on_flow_send_location(Location: String):
	# Don't update ANYTHING if you still need to promote!
	if get_node("Promotion").visible == true:
		return
	
	# variables for later
	var number = 0
	var cell = Flow.get_node(Location)
	# This is to try and grab the X and Y coordinates from the board
	LocationX = ""
	LocationY = ""
	while Location.substr(number, 1) != "-":
		LocationX += Location.substr(number, 1)
		number += 1
	LocationY = Location.substr(number + 1)
	LocationXInt = int(LocationX)
	LocationYInt = int(LocationY)
	# Now... we need to figure out how to select the pieces. If there is a valid move, do stuff.
	# If we re-select, just go to that other piece
	if SelectedNode == "" && cell.get_child_count() != 0 && cell.get_child(0).PieceColor == Turn:
		SelectedNode = Location
		GetMovableAreas()
	# Castling
	elif SelectedNode != "" && cell.get_child_count() != 0 && cell.get_child(0).PieceColor == Turn && cell.get_child(0).name == "Rook":
		for i in Areas:
			if i == cell.name:
				var king = Flow.get_node(SelectedNode).get_child(0)
				var rook = cell.get_child(0)
				# Using a seperate array because Areas wouldn't be really consistant...
				king.reparent(Flow.get_node(SpecialArea[1]))
				rook.reparent(Flow.get_node(SpecialArea[0]))
				king.position = pos
				rook.position = pos
				# We have to get the parent because it will break lmao.
				UpdateGame(cell)
	# En Passant
	elif SelectedNode != "" && cell.get_child_count() != 0 && cell.get_child(0).PieceColor != Turn && cell.get_child(0).name == "Pawn" && SpecialArea.size() != 0 && SpecialArea[0] == cell.name && cell.get_child(0).EnPassant == true:
		for i in SpecialArea:
			if i == cell.name:
				var pawn = Flow.get_node(SelectedNode).get_child(0)
				cell.get_child(0).free()
				pawn.reparent(Flow.get_node(SpecialArea[1]))
				pawn.position = pos
				UpdateGame(cell)
	# Re-select
	elif SelectedNode != "" && cell.get_child_count() != 0 && cell.get_child(0).PieceColor == Turn:
		SelectedNode = Location
		GetMovableAreas()
	# Taking over a piece
	elif SelectedNode != "" && cell.get_child_count() != 0 && cell.get_child(0).PieceColor != Turn:
		for i in Areas:
			if i == cell.name:
				var Piece = Flow.get_node(SelectedNode).get_child(0)
				# Win conditions
				if cell.get_child(0).name == "King":
					GameWin.emit()
				cell.get_child(0).free()
				SavedNode = Location
				Piece.reparent(cell)
				Piece.position = pos
				UpdateGame(cell)
	# Moving a piece
	elif SelectedNode != "" && cell.get_child_count() == 0:
		for i in Areas:
			if i == cell.name:
				var Piece = Flow.get_node(SelectedNode).get_child(0)
				SavedNode = Location
				Piece.reparent(cell)
				Piece.position = pos
				UpdateGame(cell)

func UpdateGame(cell):
	SelectedNode = ""
	if Turn == 0:
		Turn = 1
	else:
		Turn = 0
	
	# get the en-passantable pieces and undo them
	var things = Flow.get_children()
	for i in things:
		if i.get_child_count() != 0 && i.get_child(0).name == "Pawn" && i.get_child(0).PieceColor == Turn && i.get_child(0).EnPassant == true:
			i.get_child(0).EnPassant = false
	
	# Remove and add the abilities once they are either used or not used
	if cell.get_child(0).name == "Pawn":
		PawnPromotion(cell.get_child(0))
		if cell.get_child(0).DoubleStart == true:
			cell.get_child(0).EnPassant = true
		cell.get_child(0).DoubleStart = false
	if cell.get_child(0).name == "King":
		cell.get_child(0).Castling = false
	if cell.get_child(0).name == "Rook":
		cell.get_child(0).Castling = false

# Below is the movement that is used for the pieces
func GetMovableAreas():
	# Clearing the arrays
	Areas.clear()
	SpecialArea.clear()
	var Piece = Flow.get_node(SelectedNode).get_child(0)
	# For the selected piece that we have, we can get the movement that we need here.
	if Piece.name == "Pawn":
		GetPawn(Piece)
	elif Piece.name == "Bishop":
		GetDiagonals()
	elif Piece.name == "King":
		GetAround(Piece)
	elif Piece.name == "Queen":
		GetDiagonals()
		GetRows()
	elif Piece.name == "Rook":
		GetRows()
	elif Piece.name == "Knight":
		GetHorse()

func PawnPromotion(Piece):
	# This is for going from the bottom to the top, also known as the white pawns.
	if IsNull(LocationX + "-" + str(LocationYInt - 1)) && Piece.PieceColor == 0:
		get_node("Promotion").visible = true
	elif IsNull(LocationX + "-" + str(LocationYInt + 1)) && Piece.PieceColor == 1:
		get_node("Promotion").visible = true

# TODO: Make this less crap
func FinalizePromotion(Selection):
	var Piece = Flow.get_node(SavedNode).get_child(0)
	var NewPiece
	if Selection == "Bishop":
		var thing = ResourceLoader.load("res://ChessScenes/bishop.tscn")
		NewPiece = thing.instantiate()
		if Piece.PieceColor == 0:
			NewPiece.Spawned(0)
		else:
			NewPiece.Spawned(1)
		NewPiece.position = pos
		Flow.get_node(SavedNode).add_child(NewPiece)
	elif Selection == "Queen":
		var thing = ResourceLoader.load("res://ChessScenes/queen.tscn")
		NewPiece = thing.instantiate()
		if Piece.PieceColor == 0:
			NewPiece.Spawned(0)
		else:
			NewPiece.Spawned(1)
		NewPiece.position = pos
		Flow.get_node(SavedNode).add_child(NewPiece)
	elif Selection == "Rook":
		var thing = ResourceLoader.load("res://ChessScenes/rook.tscn")
		NewPiece = thing.instantiate()
		if Piece.PieceColor == 0:
			NewPiece.Spawned(0)
		else:
			NewPiece.Spawned(1)
		NewPiece.position = pos
		Flow.get_node(SavedNode).add_child(NewPiece)
	elif Selection == "Knight":
		var thing = ResourceLoader.load("res://ChessScenes/knight.tscn")
		NewPiece = thing.instantiate()
		if Piece.PieceColor == 0:
			NewPiece.Spawned(0)
		else:
			NewPiece.Spawned(1)
		NewPiece.position = pos
		Flow.get_node(SavedNode).add_child(NewPiece)
	Piece.free()
	get_node("Promotion").visible = false

func GetPawn(Piece):
	# This is for going from the bottom to the top, also known as the white pawns.
	if Piece.PieceColor == 0:
		if not IsNull(LocationX + "-" + str(LocationYInt - 1)) && Flow.get_node(LocationX + "-" + str(LocationYInt - 1)).get_child_count() == 0:
			Areas.append(LocationX + "-" + str(LocationYInt - 1))
		if not IsNull(LocationX + "-" + str(LocationYInt - 2)) && Piece.DoubleStart == true && Flow.get_node(LocationX + "-" + str(LocationYInt - 2)).get_child_count() == 0:
			Areas.append(LocationX + "-" + str(LocationYInt - 2))
		# Attacking squares
		if not IsNull(str(LocationXInt - 1) + "-" + str(LocationYInt - 1)) && Flow.get_node(str(LocationXInt - 1) + "-" + str(LocationYInt - 1)).get_child_count() == 1:
			Areas.append(str(LocationXInt - 1) + "-" + str(LocationYInt - 1))
		if not IsNull(str(LocationXInt + 1) + "-" + str(LocationYInt - 1)) && Flow.get_node(str(LocationXInt + 1) + "-" + str(LocationYInt - 1)).get_child_count() == 1:
			Areas.append(str(LocationXInt + 1) + "-" + str(LocationYInt - 1))
		# En passant
		if not IsNull(str(LocationXInt - 1) + "-" + LocationY) && not IsNull(str(LocationXInt - 1) + "-" + str(LocationYInt - 1)):
			if Flow.get_node(str(LocationXInt - 1) + "-" + LocationY).get_child_count() == 1 && Flow.get_node(str(LocationXInt - 1) + "-" + str(LocationYInt - 1)).get_child_count() != 1:
				SpecialArea.append(str(LocationXInt - 1) + "-" + LocationY)
				SpecialArea.append(str(LocationXInt - 1) + "-" + str(LocationYInt - 1))
		if not IsNull(str(LocationXInt + 1) + "-" + LocationY) && not IsNull(str(LocationXInt + 1) + "-" + str(LocationYInt - 1)):
			if Flow.get_node(str(LocationXInt + 1) + "-" + LocationY).get_child_count() == 1 && Flow.get_node(str(LocationXInt + 1) + "-" + str(LocationYInt - 1)).get_child_count() != 1:
				SpecialArea.append(str(LocationXInt + 1) + "-" + LocationY)
				SpecialArea.append(str(LocationXInt + 1) + "-" + str(LocationYInt - 1))
	# Black pawns
	else:
		if not IsNull(LocationX + "-" + str(LocationYInt + 1)) && Flow.get_node(LocationX + "-" + str(LocationYInt + 1)).get_child_count() == 0:
			Areas.append(LocationX + "-" + str(LocationYInt + 1))
		if not IsNull(LocationX + "-" + str(LocationYInt + 2)) && Piece.DoubleStart == true && Flow.get_node(LocationX + "-" + str(LocationYInt + 2)).get_child_count() == 0:
			Areas.append(LocationX + "-" + str(LocationYInt + 2))
		# Attacking squares
		if not IsNull(str(LocationXInt - 1) + "-" + str(LocationYInt + 1)) && Flow.get_node(str(LocationXInt - 1) + "-" + str(LocationYInt + 1)).get_child_count() == 1:
			Areas.append(str(LocationXInt - 1) + "-" + str(LocationYInt + 1))
		if not IsNull(str(LocationXInt + 1) + "-" + str(LocationYInt + 1)) && Flow.get_node(str(LocationXInt + 1) + "-" + str(LocationYInt + 1)).get_child_count() == 1:
			Areas.append(str(LocationXInt + 1) + "-" + str(LocationYInt + 1))
		# En passant
		if not IsNull(str(LocationXInt - 1) + "-" + LocationY) && not IsNull(str(LocationXInt - 1) + "-" + str(LocationYInt + 1)):
			if Flow.get_node(str(LocationXInt - 1) + "-" + LocationY).get_child_count() == 1 && Flow.get_node(str(LocationXInt - 1) + "-" + str(LocationYInt + 1)).get_child_count() != 1:
				SpecialArea.append(str(LocationXInt - 1) + "-" + LocationY)
				SpecialArea.append(str(LocationXInt - 1) + "-" + str(LocationYInt + 1))
		if not IsNull(str(LocationXInt + 1) + "-" + LocationY) && not IsNull(str(LocationXInt + 1) + "-" + str(LocationYInt + 1)):
			if Flow.get_node(str(LocationXInt + 1) + "-" + LocationY).get_child_count() == 1 && Flow.get_node(str(LocationXInt + 1) + "-" + str(LocationYInt+ 1)).get_child_count() != 1:
				SpecialArea.append(str(LocationXInt + 1) + "-" + LocationY)
				SpecialArea.append(str(LocationXInt + 1) + "-" + str(LocationYInt + 1))

func GetAround(Piece):
	# Single Rows
	if not IsNull(LocationX + "-" + str(LocationYInt + 1)):
		Areas.append(LocationX + "-" + str(LocationYInt + 1))
	if not IsNull(LocationX + "-" + str(LocationYInt - 1)):
		Areas.append(LocationX + "-" + str(LocationYInt - 1))
	if not IsNull(str(LocationXInt + 1) + "-" + LocationY):
		Areas.append(str(LocationXInt + 1) + "-" + LocationY)
	if not IsNull(str(LocationXInt - 1) + "-" + LocationY):
		Areas.append(str(LocationXInt - 1) + "-" + LocationY)
	# Diagonal
	if not IsNull(str(LocationXInt + 1) + "-" + str(LocationYInt + 1)):
		Areas.append(str(LocationXInt + 1) + "-" + str(LocationYInt + 1))
	if not IsNull(str(LocationXInt - 1) + "-" + str(LocationYInt + 1)):
		Areas.append(str(LocationXInt - 1) + "-" + str(LocationYInt + 1))
	if not IsNull(str(LocationXInt + 1) + "-" + str(LocationYInt - 1)):
		Areas.append(str(LocationXInt + 1) + "-" + str(LocationYInt - 1))
	if not IsNull(str(LocationXInt - 1) + "-" + str(LocationYInt - 1)):
		Areas.append(str(LocationXInt - 1) + "-" + str(LocationYInt - 1))
	# Castling, if that is the case
	if Piece.Castling == true:
		Castle()

func GetRows():
	var AddX = 1
	# Getting the horizontal rows first.
	while not IsNull(str(LocationXInt + AddX) + "-" + LocationY):
		Areas.append(str(LocationXInt + AddX) + "-" + LocationY)
		if Flow.get_node(str(LocationXInt + AddX) + "-" + LocationY).get_child_count() != 0:
			break
		AddX += 1
	AddX = 1
	while not IsNull(str(LocationXInt - AddX) + "-" + LocationY):
		Areas.append(str(LocationXInt - AddX) + "-" + LocationY)
		if Flow.get_node(str(LocationXInt - AddX) + "-" + LocationY).get_child_count() != 0:
			break
		AddX += 1
	var AddY = 1
	# Now we are getting the vertical rows.
	while not IsNull(LocationX + "-" + str(LocationYInt + AddY)):
		Areas.append(LocationX + "-" + str(LocationYInt + AddY))
		if Flow.get_node(LocationX + "-" + str(LocationYInt + AddY)).get_child_count() != 0:
			break
		AddY += 1
	AddY = 1
	while not IsNull(LocationX + "-" + str(LocationYInt - AddY)):
		Areas.append(LocationX + "-" + str(LocationYInt - AddY))
		if Flow.get_node(LocationX + "-" + str(LocationYInt - AddY)).get_child_count() != 0:
			break
		AddY += 1
	
func GetDiagonals():
	var AddX = 1
	var AddY = 1
	while not IsNull(str(LocationXInt + AddX) + "-" + str(LocationYInt + AddY)):
		Areas.append(str(LocationXInt + AddX) + "-" + str(LocationYInt + AddY))
		if Flow.get_node(str(LocationXInt + AddX) + "-" + str(LocationYInt + AddY)).get_child_count() != 0:
			break
		AddX += 1
		AddY += 1
	AddX = 1
	AddY = 1
	while not IsNull(str(LocationXInt - AddX) + "-" + str(LocationYInt + AddY)):
		Areas.append(str(LocationXInt - AddX) + "-" + str(LocationYInt + AddY))
		if Flow.get_node(str(LocationXInt - AddX) + "-" + str(LocationYInt + AddY)).get_child_count() != 0:
			break
		AddX += 1
		AddY += 1
	AddX = 1
	AddY = 1
	while not IsNull(str(LocationXInt + AddX) + "-" + str(LocationYInt - AddY)):
		Areas.append(str(LocationXInt + AddX) + "-" + str(LocationYInt - AddY))
		if Flow.get_node(str(LocationXInt + AddX) + "-" + str(LocationYInt - AddY)).get_child_count() != 0:
			break
		AddX += 1
		AddY += 1
	AddX = 1
	AddY = 1
	while not IsNull(str(LocationXInt - AddX) + "-" + str(LocationYInt - AddY)):
		Areas.append(str(LocationXInt - AddX) + "-" + str(LocationYInt - AddY))
		if Flow.get_node(str(LocationXInt - AddX) + "-" + str(LocationYInt - AddY)).get_child_count() != 0:
			break
		AddX += 1
		AddY += 1

func GetHorse():
	var TheX = 2
	var TheY = 1
	var number = 0
	while number != 8:
		# So this one is interesting. This is most likely the cleanest code here.
		# Get the numbers, replace the numbers, and loop until it stops.
		if not IsNull(str(LocationXInt + TheX) + "-" + str(LocationYInt + TheY)):
			Areas.append(str(LocationXInt + TheX) + "-" + str(LocationYInt + TheY))
		number += 1
		match number:
			1:
				TheX = 1
				TheY = 2
			2:
				TheX = -2
				TheY = 1
			3:
				TheX = -1
				TheY = 2
			4:
				TheX = 2
				TheY = -1
			5:
				TheX = 1
				TheY = -2
			6:
				TheX = -2
				TheY = -1
			7:
				TheX = -1
				TheY = -2

func Castle():
	# This is the castling section right here, used if a person wants to castle.
	var CounterX = 1
	# These are very similar to gathering a row, except we want free tiles and a rook
	# Counting up
	while not IsNull(str(LocationXInt + CounterX) + "-" + LocationY) && Flow.get_node(str(LocationXInt + CounterX) + "-" + LocationY).get_child_count() == 0:
		CounterX += 1
	if not IsNull(str(LocationXInt + CounterX) + "-" + LocationY) && Flow.get_node(str(LocationXInt + CounterX) + "-" + LocationY).get_child(0).name == "Rook":
		if Flow.get_node(str(LocationXInt + CounterX) + "-" + LocationY).get_child(0).Castling == true:
			Areas.append(str(LocationXInt + CounterX) + "-" + LocationY)
			SpecialArea.append(str(LocationXInt + 1) + "-" + LocationY)
			SpecialArea.append(str(LocationXInt + 2) + "-" + LocationY)
	# Counting down
	CounterX = -1
	while not IsNull(str(LocationXInt + CounterX) + "-" + LocationY) && Flow.get_node(str(LocationXInt + CounterX) + "-" + LocationY).get_child_count() == 0:
		CounterX -= 1
	if not IsNull(str(LocationXInt + CounterX) + "-" + LocationY) && Flow.get_node(str(LocationXInt + CounterX) + "-" + LocationY).get_child(0).name == "Rook":
		if Flow.get_node(str(LocationXInt + CounterX) + "-" + LocationY).get_child(0).Castling == true:
			Areas.append(str(LocationXInt + CounterX) + "-" + LocationY)
			SpecialArea.append(str(LocationXInt - 1) + "-" + LocationY)
			SpecialArea.append(str(LocationXInt - 2) + "-" + LocationY)

# One function that shortens everything. Its also a pretty good way to see if we went off the board or not.
func IsNull(Location):
	if Flow.get_node_or_null(Location) == null:
		return true
	else:
		return false
