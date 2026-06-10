extends Control

enum state {
	BUZZER,
	QUESTION,
	KICKED,
	CAN_LEAVE,
	SCORE,
}

@export_group("Buzzer", "buzzer")
@export var buzzer: Control
@export var buzzer_question: Label
@export_group("Question", "question")
@export var question: Control
@export var question_question: Label
@export var question_player: Label
@export var question_writer: Label
@export var question_option_container: GridContainer
@export_group("Kicked", "kicked")
@export var kicked: Control
@export var kicked_player: Label
@export var kicked_leave_button: Button
@export_group("Can Leave", "canleave")
@export var canleave: Control
@export var canleave_money: Label
@export var canleave_leave_button: Button
@export var canleave_stay_button: Button

var current_state = state.BUZZER:
	set(val):
		_update_state()
var current_question: Question
## The current player number 1, 2, 3, 4
var current_player := 0
var money: Dictionary[int, int] = { 1: 0, 2: 0, 3: 0, 4: 0 }
var running_players = [1, 2, 3, 4]


func _ready() -> void:
	kicked_leave_button.pressed.connect(_player_kicked_button_pressed)


func _input(event: InputEvent) -> void:
	if current_state == state.BUZZER:
		if event.is_action_pressed("player_1_buzzer") and 1 in running_players:
			current_player = 1
			current_state = state.QUESTION
		elif event.is_action_pressed("player_2_buzzer") and 2 in running_players:
			current_player = 2
			current_state = state.QUESTION
		elif event.is_action_pressed("player_3_buzzer") and 3 in running_players:
			current_player = 3
			current_state = state.QUESTION
		elif event.is_action_pressed("player_4_buzzer") and 4 in running_players:
			current_player = 4
			current_state = state.QUESTION


func _update_state():
	buzzer.hide()
	question.hide()
	kicked.hide()

	match current_state:
		state.BUZZER:
			_get_new_question()
			buzzer.show()
		state.QUESTION:
			question.show()
			question_player.text = "Player %d" % current_player
		state.KICKED:
			kicked.show()
			kicked_player.text = "Player %d. You had %d money! Now you've lost it all." % [current_player, money[current_player]]
			running_players.erase(current_player)


func _get_new_question():
	current_question = Globals.questions.pick_random()
	buzzer_question.text = current_question.question
	question_question.text = current_question.question
	question_writer.text = current_question.writer
	_load_options()


func _load_options():
	for child in question_option_container.get_children():
		child.queue_free()

	var disposable_options := current_question.options.duplicate()

	for i in range(len(current_question.options) - 1):
		var current_option = disposable_options.pick_random()
		disposable_options.erase(current_option)

		var button := Button.new()
		button.text = current_option
		question_option_container.add_child(button)

		if current_option == current_question.options[0]:
			button.pressed.connect(_handle_correct)
		else:
			button.pressed.connect(_handle_incorrect)


func _handle_correct():
	current_state = state.CAN_LEAVE


func _handle_incorrect():
	current_state = state.KICKED


func _player_kicked_button_pressed():
	current_state = state.SCORE
