@echo off
if "%1" == "h" goto begin
mshta vbscript:createobject("wscript.shell").run("""%~nx0"" h",0)(window.close)&&exit
:begin

set curdir=%~dp0
cd /d %curdir% 
start /b service_map/map.exe  -port 8000 -service map=service_map/mb.mbtiles >>service_map/map.log

cd /d %curdir% 
cd nginx-1.20.0
start nginx