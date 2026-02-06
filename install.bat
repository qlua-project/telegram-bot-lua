@echo off
setlocal enabledelayedexpansion

:: prerequisites
winget list --id BuildTools > NUL && (
    echo BuildTools found
) || (
    echo [^^!] BuildTools NOT found.
    echo.
    echo Available packages found via winget:
    echo.
    winget search BuildTools
    echo.
    echo Download the official installer from:
    echo    https://aka.ms/vs/stable/vs_BuildTools.exe
    exit /b 1
)
:: check vswhere
winget list --id Microsoft.VisualStudio.Locator > NUL && (
    set QUERY=vswhere -latest -products * ^
            -requires Microsoft.VisualStudio.Product.BuildTools ^
            -property installationPath
    for /f "usebackq tokens=*" %%i in (`!QUERY!`) do (
        set "BT_PATH=%%i"
    )
    if defined BT_PATH (
        echo [OK] BuildTools Path: "!BT_PATH!"
        set "VSD_BAT=!BT_PATH!\Common7\Tools\VsDevCmd.bat"
    ) else (
        echo [^^!] BuildTools Path not found via vswhere.
        exit /b 1
    )
) || (
    winget search --id Microsoft.VisualStudio.Locator
    winget install --id Microsoft.VisualStudio.Locator
    exit /b 0
)
:: BuildTools environment
call "%VSD_BAT%" -startdir=none -host_arch=x64 -arch=x64
where cl.exe
where link.exe
where nmake.exe
echo.

echo -----------------------------------
echo "Installing Lua 5.4..."
echo -----------------------------------
pushd %TEMP%
::curl -O https://www.lua.org/ftp/lua-5.4.1.tar.gz
::curl -O https://www.lua.org/ftp/lua-5.3.5.tar.gz
::tar -xf lua-5.4.1.tar.gz
::tar -xf lua-5.3.5.tar.gz
curl -LO https://github.com/qlua-project/cmake-lua-win64/releases/download/5.4.1/lua-5.4.1-win-x64.zip
curl -LO https://github.com/qlua-project/cmake-lua-win64/releases/download/5.3.5/lua-5.3.5-win-x64.zip
mkdir lua-5.4.1
mkdir lua-5.3.5
tar -xf lua-5.4.1-win-x64.zip -C lua-5.4.1
tar -xf lua-5.3.5-win-x64.zip -C lua-5.3.5
::xcopy /y lua-5.4.1\bin %LUA_HOME%\
::xcopy /y lua-5.4.1\lib %LUA_HOME%\
::xcopy /y lua-5.4.1\include %LUA_HOME%\
::xcopy /y lua-5.3.5\bin\lua53.dll %LUA_HOME%\bin\
::xcopy /y lua-5.4.1\bin\lua.exe %LUA_HOME%\bin\lua54.exe
::xcopy /y lua-5.3.5\bin\lua.exe %LUA_HOME%\bin\lua53.exe
::xcopy /y lua-5.4.1\bin\luac.exe %LUA_HOME%\bin\luac54.exe
::xcopy /y lua-5.3.5\bin\luac.exe %LUA_HOME%\bin\luac53.exe
::xcopy /y lua-5.3.5\bin\luac.exe %LUA_HOME%\bin\luac53.exe
:: %LOCALAPPDATA%\Lua\bin
::  ...
popd

set LUA_HOME=%TEMP%\lua-5.4.1
set PATH=%LUA_HOME%\bin;%PATH%

echo -----------------------------------
echo "Installing LuaRocks..."
echo -----------------------------------
pushd %TEMP%
curl -O https://luarocks.github.io/luarocks/releases/luarocks-3.13.0-windows-64.zip
tar -xf luarocks-3.13.0-windows-64.zip
copy /b /y luarocks-3.13.0-windows-64\luarocks.exe %LUA_HOME%\bin
luarocks
popd

echo -----------------------------------
echo "Installing OpenSSL..."
echo -----------------------------------
pushd %TEMP%
curl -Lo external-openssl-win64.zip https://github.com/qlua-project/external-openssl-win64/archive/refs/heads/3.4.1.zip
tar -xf external-openssl-win64.zip
dir external-openssl-win64-3.4.1
popd

echo -----------------------------------
echo "Installing telegram-bot-lua..."
echo -----------------------------------
mkdir testproject
pushd testproject
luarocks install --tree lua_modules ^
                 --lua-dir %LUA_HOME% ^
                 OPENSSL_DIR=%TEMP%\external-openssl-win64-3.4.1 ^
    https://raw.githubusercontent.com/ivansoft/telegram-bot-lua-win32/refs/heads/main/telegram-bot-lua-2.0-0.rockspec 
popd

echo -----------------------------------
tree testproject
