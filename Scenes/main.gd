extends Control

enum state {
	BUZZER,
	QUESTION,
	KICKED,
	CAN_LEAVE,
}

var current_state = state.BUZZER
var current_question: Question
## The current player number 1, 2, 3, 4
var current_player := 0

@onready var buzzer: Control = %Buzzer
@onready var buzzer_question_box: Label = %BuzzerQuestionBox


func _ready() -> void:
	_get_new_question()


func _process(delta: float) -> void:
	match current_state:
		state.BUZZER:
			pass
		state.QUESTION:
			print("Question mode for player %d" % current_player)


func _input(event: InputEvent) -> void:
	if current_state == state.BUZZER:
		if event.is_action_pressed("player_1_buzzer"):
			current_player = 1
			current_state = state.QUESTION
		elif event.is_action_pressed("player_2_buzzer"):
			current_player = 2
			current_state = state.QUESTION
		elif event.is_action_pressed("player_3_buzzer"):
			current_player = 3
			current_state = state.QUESTION
		elif event.is_action_pressed("player_4_buzzer"):
			current_player = 4
			current_state = state.QUESTION


func _get_new_question():
	current_question = Globals.questions.pick_random()
	buzzer_question_box.text = current_question.question
