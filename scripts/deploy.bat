cd ..
call npm run build
del /s /q ..\vue-github-deploy-dist\*
xcopy dist ..\vue-github-deploy-dist /s /e
git checkout gh-pages
del /s /q *
xcopy ..\vue-github-deploy-dist . /s /e /y
git add .
git commit -a
git push
git checkout master
cd scripts
