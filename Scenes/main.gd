extends Control

enum state {
	BUZZER,
	NO_BUZZER,
	QUESTION,
	KICKED,
	CAN_LEAVE,
	CONTINUE,
	END_OF_GAME,
}
enum player_status {
	PLAYING,
	LEFT,
	KICKED,
}

const BUZZER_TIME = 20
const OPTION_TIME = 10

@export var questions: Array[Question]
@export var option_scene: PackedScene
@export var score_box_scene: PackedScene
@export var timer: Timer
@export var music: AudioStreamPlayer
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
@export_group("Continue", "cont")
@export var cont: Control
@export var cont_continue_button: Button
@export_group("End of Game", "endofgame")
@export var endofgame: Control
@export var endofgame_vbox: VBoxContainer
@export_group("Scores", "scores")
@export var scores_p1: PlayerScore
@export var scores_p2: PlayerScore
@export var scores_p3: PlayerScore
@export var scores_p4: PlayerScore

var correction_option_num = 0
var current_state = state.BUZZER:
	set(val):
		if current_state != state.END_OF_GAME:
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

	nobuzzer_button.pressed.connect(func(): current_state = state.CONTINUE)

	canleave_leave_button.pressed.connect(_player_left)
	canleave_stay_button.pressed.connect(func(): current_state = state.CONTINUE)

	cont_continue_button.pressed.connect(func(): current_state = state.BUZZER)

	timer.timeout.connect(_timer_up)

	music.finished.connect(func(): music.play(0))


func _process(_delta: float) -> void:
	buzzer_timer_label.text = "%.2f seconds remaining" % timer.time_left
	question_timer_label.text = "%.2f seconds remaining" % timer.time_left
	_do_score()


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

	elif current_state == state.QUESTION:
		if event.is_action_pressed("option_1"):
			if correction_option_num == 1:
				_handle_correct()
			else:
				_handle_incorrect()
		elif event.is_action_pressed("option_2"):
			if correction_option_num == 2:
				_handle_correct()
			else:
				_handle_incorrect()
		elif event.is_action_pressed("option_3"):
			if correction_option_num == 3:
				_handle_correct()
			else:
				_handle_incorrect()
		elif event.is_action_pressed("option_4"):
			if correction_option_num == 4:
				_handle_correct()
			else:
				_handle_incorrect()


func _set_running_players(key, val):
	if key > 4 or key < 1:
		push_error("Invalid key added")

	var old = running_players.duplicate()
	running_players[key] = val
	_new_round_checks(old, running_players)


func _update_state():
	buzzer.hide()
	nobuzzer.hide()
	question.hide()
	kicked.hide()
	canleave.hide()
	cont.hide()
	endofgame.hide()

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
			_set_running_players(current_player, player_status.KICKED)
		state.CAN_LEAVE:
			canleave.show()
			canleave_money.text = "You gain %d money!" % current_money
		state.CONTINUE:
			cont.show()
		state.END_OF_GAME:
			_end_of_game_score()
			endofgame.show()


func _get_new_question():
	current_question = questions.pick_random()
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
			correction_option_num = i + 1
		else:
			button.pressed.connect(_handle_incorrect)


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
	current_state = state.CONTINUE


func _player_left():
	_set_running_players(current_player, player_status.LEFT)
	current_state = state.CONTINUE


func _new_round_checks(old: Dictionary[int, player_status], new: Dictionary[int, player_status]):
	var changed: Dictionary[int, player_status] = { }
	var existing_players := 0
	var living_player := 0

	for player in new.keys():
		if new[player] == player_status.PLAYING:
			existing_players += 1
			living_player = player

	if existing_players > 1:
		return

	for player in new.keys():
		if new[player] != old[player]:
			changed[player] = new[player]

	if changed[changed.keys()[0]] == player_status.LEFT:
		running_players[living_player] = player_status.KICKED
	elif changed[changed.keys()[0]] == player_status.KICKED:
		running_players[living_player] = player_status.LEFT

	current_state = state.END_OF_GAME


func _timer_up():
	if current_state == state.QUESTION:
		kicked_label.text = "You have run out of time!"
		current_state = state.KICKED
	elif current_state == state.BUZZER:
		current_state = state.NO_BUZZER


func _end_of_game_score():
	var order: Array[int] = []

	var players := running_players.duplicate()

	while true:
		var highest_player: int = -1

		for player in players.keys():
			if running_players[player] == player_status.PLAYING or running_players[player] == player_status.LEFT:
				if highest_player == -1 or money[highest_player] < money[player]:
					highest_player = player

		if highest_player == -1:
			break

		players.erase(highest_player)

		order.append(highest_player)

	while true:
		var highest_player := -1

		for player in players:
			if highest_player == -1 or money[highest_player] < money[player]:
				highest_player = player

		if highest_player == -1:
			break

		players.erase(highest_player)

		order.append(highest_player)

	print(order)

	for player in order:
		var instance = score_box_scene.instantiate()

		instance.player_text = "Player %d" % player
		instance.money_text = "$%d" % money[player]

		match running_players[player]:
			player_status.PLAYING:
				instance.player_status_text = "Playing"
			player_status.LEFT:
				instance.player_status_text = "Left"
			player_status.KICKED:
				instance.player_status_text = "Kicked"

		endofgame_vbox.add_child(instance)


func _do_score():
	for i in range(1, 5):
		var scene: PlayerScore = get("scores_p%d" % i)

		scene.player_text = "Player %d" % i
		scene.molah_text = "Money: %d" % money[i]

		match running_players[i]:
			player_status.PLAYING:
				scene.left = false
				scene.kicked = false
			player_status.LEFT:
				scene.left = true
				scene.kicked = false
			player_status.KICKED:
				scene.left = false
				scene.kicked = true

		scene.current_turn = current_player == i
