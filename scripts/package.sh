# Update Package
mkdir -p Update-Package
cp -r addons/sourcemod/scripting/plugins Update-Package
cp -r addons/sourcemod/translations Update-Package
cp -r addons/sourcemod/gamedata Update-Package

# Full Package
mkdir -p New-Install-Package/addons/sourcemod
cp -r models New-Install-Package
cp -r materials New-Install-Package
cp -r sound New-Install-Package
cp -r addons/sourcemod/scripting/plugins New-Install-Package/addons/sourcemod
cp -r addons/sourcemod/translations New-Install-Package/addons/sourcemod
cp -r addons/sourcemod/gamedata New-Install-Package/addons/sourcemod
cp -r addons/sourcemod/configs New-Install-Package/addons/sourcemod