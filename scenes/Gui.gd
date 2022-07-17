extends CanvasLayer

signal start_game

func show_message(text):
	$MessageLabel.text = text
	$MessageLabel.show()
	$MessageTimer.start()

func show_game_over():
	show_message("Game Over")
	yield($MessageTimer, "timeout")
	$MessageLabel.text = "Dice Matching"
	$MessageLabel.show()
	yield(get_tree().create_timer(1), "timeout")
	$StartButton.show()

func update_dice_cleared(dice_cleared):
	$VBoxContainer/DiceCleared.text = "Dice Cleared: %d" % dice_cleared

func update_moves_left(moves: int):
	$VBoxContainer/MovesLeft.text = "Moves Left: %d" % moves

func _on_StartButton_pressed():
	$StartButton.hide()
	emit_signal("start_game")

func _on_MessageTimer_timeout():
	$MessageLabel.hide()
