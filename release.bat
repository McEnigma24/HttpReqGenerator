@echo off
pushd "%~dp0"

cls
@REM flutter clean
@REM flutter build apk --debug
flutter build apk --release

popd