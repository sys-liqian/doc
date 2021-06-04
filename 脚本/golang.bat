cd C:\Users\A\AppData\Roaming\JetBrains\GoLand2020.3
rmdir "eval" /s /q
del "options\other.xml"
reg delete "HKEY_CURRENT_USER\SOFTWARE\JavaSoft\Prefs\jetbrains\idea" /f