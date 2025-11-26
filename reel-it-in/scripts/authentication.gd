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
	if message == "INVALID_EMAIL":
		%LoggedInLabel.text = "Invalid Email"
	elif message == "INVALID_PASSWORD":
		%LoggedInLabel.text = "Incorrect Password"
	else:
		%LoggedInLabel.text = "Login Failed"

func on_signup_failed(error_code, message):
	print(error_code)
	print(message)
	if message == "INVALID_EMAIL":
		%LoggedInLabel.text = "Invalid Email"
	elif message == "INVALID_PASSWORD":
		%LoggedInLabel.text = "Invalid Password"
	elif message.contains("WEAK_PASSWORD"):
		%LoggedInLabel.text = "Password Too Short"
	elif message == "MISSING_PASSWORD":
		%LoggedInLabel.text = "No Password"
	else:
		%LoggedInLabel.text = "Signup Failed"
