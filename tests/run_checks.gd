extends Node

func _ready() -> void:
	var checks: Dictionary = load("res://tests/runtime_checks.gd").new().run(self)
	var failures: Array[String] = []
	var report := ""
	for check_name in checks:
		report += ("PASS  " if checks[check_name] else "FAIL  ") + check_name + "\n"
		if not checks[check_name]:
			failures.append(check_name)
	var summary := "%d / %d checks passed" % [checks.size() - failures.size(), checks.size()]
	$Scroll/Results.text = summary + "\n\n" + report
	print(summary)
	if not failures.is_empty():
		push_error("Failed checks: " + ", ".join(failures))
