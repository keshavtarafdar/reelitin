extends Control

func _ready() -> void:
	Firebase.Auth.login_succeeded.connect(on_login_succeeded)
	Firebase.Auth.signup_succeeded.connect(on_signup_succeeded)
	Firebase.Auth.login_failed.connect(on_login_failed)
	Firebase.Auth.signup_failed.connect(on_signup_failed)
	
	if Firebase.Auth.check_auth_file():
		%LoggedInLabel.text = "Logged In"
		get_tree().change_scene_to_file("res://scenes/MainMenuScene.tscn")

func _on_log_in_button_pressed() -> void:
	var email = %EmailLineEdit.text
	var password = %PasswordLineEdit.text
	Firebase.Auth.login_with_email_and_password(email, password)
	%LoggedInLabel.text = "Logging In"


func _on_sign_up_button_pressed() -> void:
	var email = %EmailLineEdit.text
	var password = %PasswordLineEdit.text
	Firebase.Auth.signup_with_email_and_password(email, password)
	%LoggedInLabel.text = "Signing Up"

func on_login_succeeded(auth):
	print(auth)
	%LoggedInLabel.text = "Login Successful"
	Firebase.Auth.save_auth(auth)
	get_tree().change_scene_to_file("res://scenes/MainMenuScene.tscn")
	
func on_signup_succeeded(auth):
	print(auth)
	%LoggedInLabel.text = "Signup Successful"
	Firebase.Auth.save_auth(auth)
	get_tree().change_scene_to_file("res://scenes/MainMenuScene.tscn")

func on_login_failed(error_code, message):
	print(error_code)
	print(message)
	%LoggedInLabel.text = "Login Failed. Error: %s" % message

func on_signup_failed(error_code, message):
	print(error_code)
	print(message)
	%LoggedInLabel.text = "Signup Failed. Error: %s" % message
