cd ..
call npm run build
del /s /q ..\vue-github-deploy-dist\*
xcopy dist ..\vue-github-deploy-dist /s /e
@REM git checkout deployment
@REM del /s /q js\*
@REM del /s /q css\*
@REM xcopy ..\vue-github-deploy-dist . /s /e /y
@REM git add .
@REM git commit -a
@REM git push
@REM git checkout master
@REM cd scripts
