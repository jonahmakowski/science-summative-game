extends Control

enum state {
	BUZZER,
	NO_BUZZER,
	QUESTION,
	KICKED,
	CAN_LEAVE,
	SCORE,
}
enum player_status {
	PLAYING,
	LEFT,
	KICKED,
}

const BUZZER_TIME = 20
const OPTION_TIME = 5

@export var option_scene: PackedScene
@export var timer: Timer
@export_group("Buzzer", "buzzer")
@export var buzzer: Control
@export var buzzer_question: Label
@export var buzzer_timer_label: Label
@export_group("No Buzzer", "nobuzzer")
@export var nobuzzer: Control
@export var nobuzzer_label: Label
@export var nobuzzer_button: Button
@export_group("Question", "question")
@export var question: Control
@export var question_question: Label
@export var question_player: Label
@export var question_writer: Label
@export var question_option_container: GridContainer
@export var question_timer_label: Label
@export_group("Kicked", "kicked")
@export var kicked: Control
@export var kicked_label: Label
@export var kicked_player: Label
@export var kicked_leave_button: Button
@export_group("Can Leave", "canleave")
@export var canleave: Control
@export var canleave_money: Label
@export var canleave_leave_button: Button
@export var canleave_stay_button: Button
@export_group("Score", "score")
@export var score: Control
@export var score_box: GridContainer
@export var score_continue_button: Button

var current_state = state.BUZZER:
	set(val):
		current_state = val
		_update_state()
## The current player number 1, 2, 3, 4
var current_player := 0
var money: Dictionary[int, int] = { 1: 0, 2: 0, 3: 0, 4: 0 }
var running_players: Dictionary[int, player_status] = { 1: player_status.PLAYING, 2: player_status.PLAYING, 3: player_status.PLAYING, 4: player_status.PLAYING }:
	set(new):
		var old = running_players.duplicate()
		running_players = new
		_new_round_checks(old, running_players)
var current_money := 500

@onready var current_question: Question = _get_new_question()


func _ready() -> void:
	_update_state()

	kicked_leave_button.pressed.connect(_player_kicked_button_pressed)

	nobuzzer_button.pressed.connect(func(): current_state = state.SCORE)

	canleave_leave_button.pressed.connect(_player_left)
	canleave_stay_button.pressed.connect(func(): current_state = state.SCORE)

	score_continue_button.pressed.connect(func(): current_state = state.BUZZER)

	timer.timeout.connect(_timer_up)


func _process(_delta: float) -> void:
	buzzer_timer_label.text = "%.2f seconds remaining" % timer.time_left
	question_timer_label.text = "%.2f seconds remaining" % timer.time_left


func _input(event: InputEvent) -> void:
	if current_state == state.BUZZER:
		if event.is_action_pressed("player_1_buzzer") and running_players[1] == player_status.PLAYING:
			current_player = 1
			current_state = state.QUESTION
		elif event.is_action_pressed("player_2_buzzer") and running_players[2] == player_status.PLAYING:
			current_player = 2
			current_state = state.QUESTION
		elif event.is_action_pressed("player_3_buzzer") and running_players[3] == player_status.PLAYING:
			current_player = 3
			current_state = state.QUESTION
		elif event.is_action_pressed("player_4_buzzer") and running_players[4] == player_status.PLAYING:
			current_player = 4
			current_state = state.QUESTION


func _update_state():
	buzzer.hide()
	nobuzzer.hide()
	question.hide()
	kicked.hide()
	canleave.hide()
	score.hide()

	match current_state:
		state.BUZZER:
			_get_new_question()
			timer.start(BUZZER_TIME)
			buzzer.show()
		state.NO_BUZZER:
			nobuzzer.show()
			nobuzzer_label.text = "Everyone loses %d money!" % int(current_money / 2.)
			_no_buzzer_lose_money()
		state.QUESTION:
			timer.start(OPTION_TIME)
			question.show()
			question_player.text = "Player %d" % current_player
		state.KICKED:
			kicked.show()
			kicked_player.text = "Player %d. You had %d money! Now you've lost it all." % [current_player, money[current_player]]
			running_players[current_player] = player_status.KICKED
		state.CAN_LEAVE:
			canleave.show()
			canleave_money.text = "You have %d money!" % money[current_player]
		state.SCORE:
			_do_score()
			score.show()


func _get_new_question():
	current_question = Globals.questions.pick_random()
	buzzer_question.text = current_question.question
	question_question.text = current_question.question
	question_writer.text = "Written by %s" % current_question.writer

	current_money += 500

	_load_options()


func _load_options():
	for child in question_option_container.get_children():
		child.queue_free()

	var disposable_options := current_question.options.duplicate()

	for i in range(len(current_question.options)):
		var current_option = disposable_options.pick_random()
		disposable_options.erase(current_option)

		var button: Button = option_scene.instantiate()
		button.text = current_option

		question_option_container.add_child(button)

		if current_option == current_question.options[0]:
			button.pressed.connect(_handle_correct)
		else:
			button.pressed.connect(_handle_incorrect)


func _do_score():
	for child in score_box.get_children():
		child.queue_free()

	for i in range(1, 5):
		var player_label := Label.new()
		var money_label := Label.new()
		var status_label := Label.new()

		player_label.text = "Player %d" % i
		money_label.text = "Money: %d" % money[i]

		match running_players[i]:
			player_status.PLAYING:
				status_label.text = "Playing"
			player_status.LEFT:
				status_label.text = "Left (Money counts!)"
			player_status.KICKED:
				status_label.text = "Kicked (Money doesn't count!)"

		score_box.add_child(player_label)
		score_box.add_child(money_label)
		score_box.add_child(status_label)


func _no_buzzer_lose_money():
	for player in running_players.keys():
		if running_players[player] == player_status.PLAYING:
			money[player] -= int(current_money / 2.)


func _handle_correct():
	money[current_player] += current_money
	current_state = state.CAN_LEAVE


func _handle_incorrect():
	kicked_label.text = "You have been kicked!"
	current_state = state.KICKED


func _player_kicked_button_pressed():
	current_state = state.SCORE


func _player_left():
	running_players[current_player] = player_status.LEFT
	current_state = state.SCORE


func _new_round_checks(old: Dictionary[int, player_status], new: Dictionary[int, player_status]):
	var changed: Dictionary[int, player_status] = { }
	var existing_players := 0
	var living_player := 0

	for player in new.keys():
		if new[player] != old[player]:
			changed[player] = new[player]

	for player in new.keys():
		if new[player] == player_status.PLAYING:
			existing_players += 1
			living_player = player

	if existing_players > 1:
		return
	elif existing_players <= 0:
		push_error("Less than one player remaining")
		return

	print("Game Over!")
	if changed[changed.keys()[0]] == player_status.LEFT:
		running_players[living_player] = player_status.KICKED
	elif changed[changed.keys()[0]] == player_status.KICKED:
		running_players[living_player] = player_status.LEFT
	print(running_players)


func _timer_up():
	if current_state == state.QUESTION:
		kicked_label.text = "You have run out of time!"
		current_state = state.KICKED
	elif current_state == state.BUZZER:
		current_state = state.NO_BUZZER
