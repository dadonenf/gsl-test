setlocal
@echo off

dir
git status
IF %ERRORLEVEL% NEQ 0 (
    echo Failed git status
    EXIT /B 1
)

set ASM_LOC=%APPVEYOR_BUILD_WORKER_IMAGE%_%GSL_CXX_STANDARD%_%PLATFORM%_%CONFIGURATION%

REM Get branch to check asm into 
(git checkout asm/%APPVEYOR_BUILD_NUMBER% && git pull) || (git checkout -b asm/%APPVEYOR_BUILD_NUMBER% && git push -u origin HEAD)
git branch

REM Check asm into the branch
git add "asm\%ASM_LOC%"
git commit -m "Update ASM for %ASM_LOC%"

REM Push changes to remote branch 
set LOOP_COUNT=0
REM There are currently 24 jobs in Appveyor, so try 25 times to push
set MAX_LOOP_COUNT=2
:PUSH_LOOP
git pull
git push
IF %ERRORLEVEL% NEQ 0 (
    if %LOOP_COUNT% LSS %MAX_LOOP_COUNT% (
        set /a "LOOP_COUNT = LOOP_COUNT + 1"
        echo Retrying git push... (%LOOP_COUNT%/%MAX_LOOP_COUNT%)
        goto PUSH_LOOP
    ) else (
        echo We have reached the max attempts for pushing to the remote branch
        EXIT /B 1
    )
)