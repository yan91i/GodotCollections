extends Sprite2D

# Standard
var PieceColor: int
@export var Black: CompressedTexture2D
@export var White: CompressedTexture2D

func Spawned(color: int):
	if color == 0:
		self.texture = White
		PieceColor = 0
	else:
		self.texture = Black
		PieceColor = 1
