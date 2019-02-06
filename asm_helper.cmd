setlocal
@echo off

REM TEMPORARY for test
set APPVEYOR_BUILD_NUMBER=126

set ASM_LOC=%APPVEYOR_BUILD_WORKER_IMAGE%_%GSL_CXX_STANDARD%_%PLATFORM%_%CONFIGURATION%

REM REM TEMPORARY for test
REM set ASM_LOC=125

REM Get branch to check asm into 
(git checkout asm/%APPVEYOR_BUILD_NUMBER% && git pull) || (git checkout -b asm/%APPVEYOR_BUILD_NUMBER% && git push -u origin HEAD)
git branch

REM Check asm into the branch
git add "asm\%ASM_LOC%"
git commit -m "Update ASM for %ASM_LOC%"

REM Push changes to remote branch 
set LOOP_COUNT=0
REM There are currently 24 jobs in Appveyor, so try 25 times to push
set MAX_LOOP_COUNT=25
:PUSH_LOOP
git pull
git push
IF %ERRORLEVEL% NEQ 0 (
    if %LOOP_COUNT% LSS 25 (
        echo Retrying git push...
        goto PUSH_LOOP
    ) else (
        REM We have reached the max attempts for pushing to the remote branch
        EXIT /B 1
    )
)