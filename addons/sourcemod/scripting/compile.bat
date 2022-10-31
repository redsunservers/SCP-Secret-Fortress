@echo off
@title Compile

if NOT exist "..\..\..\..\_includes" (
	@echo --- You need to clone the _includes repo to be able to compile server plugins.
	pause
)

if NOT exist "plugins" (
	mkdir "plugins"
)

for %%f in (*.sp) do (
	@echo --- COMPILING: %%~nf
	spcomp %%f -i="..\..\..\..\_includes"
	
	if exist "%%~nf.smx" (
		@echo --- MOVING %%~nf
		
		for %%d in (.) do (
			cmd /c move "%%~nf.smx" "plugins\%%~nf.smx"
		)

		@echo --- OPERATION DONE
	) else (
		@echo --- FILE WAS NOT COMPILED, SKIPPING
		@echo --- Please take time to read the errors it spit out and fix them accordingly
	)

	@echo.
	@echo.
)

pause