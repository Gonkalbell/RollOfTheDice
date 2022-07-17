extends Control

var total_dice_cleared = 0

func on_die_cleared():
	total_dice_cleared += 1
	$VBoxContainer/DiceCleared.text = "Dice Cleared: %d" % total_dice_cleared

func update_moves_left(moves: int):
	$VBoxContainer/MovesLeft.text = "Moves Left: %d" % moves
