@tool
class_name PlayerScore
extends VBoxContainer

@export var texture: AtlasTexture
@export var style_box: StyleBox
@export var left_asset: AtlasTexture
@export var kicked_asset: AtlasTexture
@export var player_text: String:
	set(val):
		player_text = val
		if is_node_ready():
			_setup()
@export var molah_text: String:
	set(val):
		molah_text = val
		if is_node_ready():
			_setup()
@export var left: bool = false:
	set(val):
		left = val
		if is_node_ready():
			_setup()
@export var kicked: bool = false:
	set(val):
		kicked = val
		if is_node_ready():
			_setup()
@export var current_turn: bool = false:
	set(val):
		current_turn = val
		if is_node_ready():
			turn_bar.visible = current_turn

@onready var turn_bar: TextureRect = %TurnBar
@onready var player: Label = %Player
@onready var molah: Label = %Molah
@onready var button: Label = %Button
@onready var texture_rect: TextureRect = %TextureRect
@onready var panel_container: PanelContainer = %PanelContainer


func _ready():
	turn_bar.visible = current_turn
	style_box.texture = texture
	panel_container.add_theme_stylebox_override("panel", style_box)
	_setup()


func _setup():
	player.text = player_text
	molah.text = molah_text

	if kicked:
		texture_rect.texture = kicked_asset
	elif left:
		texture_rect.texture = left_asset

	match player_text:
		"Player 1":
			button.text = "Escape"
		"Player 2":
			button.text = "Z"
		"Player 3":
			button.text = "Delete"
		"Player 4":
			button.text = "Slash (/)"
		_:
			button.text = ""
