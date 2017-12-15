## Example Applescript for a Script Cue in QLab

```applescript
set ProjectorIP to "192.254.43.33"
set Instruction to "Status"
-- or "Power On"
-- or "Shutter Close"
-- etc...

tell application "Terminal"
	set hideMe to false
	if (count of the windows) is less than 1 then
		tell window 1 to do script ""
		delay 1.0E-5
		set hideMe to true
	end if
	
	do script "echo \"$(~/Applications/PJLink/projector.sh " & Instruction & " " & ProjectorIP & ")\"" in window 1
	
	if hideMe then tell window 1 to set miniaturized to true
end tell
```
