# JetBrains产品重置试用

## Idea

```powershell
cd C:\Users\A\AppData\Roaming\JetBrains\IntelliJIdea2020.3
rmdir "eval" /s /q
del "options\other.xml"
reg delete "HKEY_CURRENT_USER\SOFTWARE\JavaSoft\Prefs\jetbrains\idea" /f
```

## Goland

```powershell
cd C:\Users\A\AppData\Roaming\JetBrains\GoLand2020.3
rmdir "eval" /s /q
del "options\other.xml"
reg delete "HKEY_CURRENT_USER\SOFTWARE\JavaSoft\Prefs\jetbrains\idea" /f
```
