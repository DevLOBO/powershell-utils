$moduleFiles = Get-ChildItem -Recurse -Path ./Modules -Filter *.psm1

foreach($file in $moduleFiles) {
	$content = Get-Content -Path $file.FullName -Raw
	$content = Invoke-Formatter -ScriptDefinition $content -Settings ./format_settings.psd1
	Set-Content $content -Path $file.FullName
}
