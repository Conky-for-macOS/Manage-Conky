--------------------------------------------------------------------------------------------
### 1. Introduce default-theme-pack updater:

Upon ManageConky update, we should be able to update the `default-theme-pack` installation in the `directory` it is stored.  Currently, there is no specificly designed directory for the purpose of storing only default-theme-pack.  Thus, we can either provide the several options:

1. Create a fixed directory in /Library to store them and actually **update** them with the versions of ManageConky. ---> not a good option.
2. Parse the default-theme-pack from memory to do every task ---> not a good option.
		
		1. requires no updating mechanism
3. Have a default-theme-pack folder inside the ManageConky bundle, instead of a .7z file =>

	 	1. offer easy maintainance with git (add `default-themes` as subproject)
	 	2. automatically updated
	 	3. will be able to remove the dependancy to 7z library
	 	4. Although, raises the size of ManageConky alot...
	 	5. Introduce code to allow user to enable/disable default-theme-pack in order to emulate the behaviour of conky-manager which offers a "Import default-theme-pack" option.

	 	For 5. we could have a BOOL in the defaults file. e.g. `defaultThemePackEnabled = NO`
	 	Should be `NO` by default, though and up to the user to enable it.
	 	
	 	
--------------------------------------------------------------------------------------------
### 2. 