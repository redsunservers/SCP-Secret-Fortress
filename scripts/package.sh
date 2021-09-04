cd build

mkdir -p package/addons/sourcemod/plugins
mkdir -p package/addons/sourcemod/gamedata
mkdir -p package/addons/sourcemod/configs

cp -r addons/sourcemod/plugins/scp_sf.smx package/addons/sourcemod/plugins
cp -r ../addons/sourcemod/gamedata/scp_sf.txt package/addons/sourcemod/gamedata
cp -r ../addons/sourcemod/configs/scp_sf package/addons/sourcemod/configs
cp -r ../addons/sourcemod/translations package/addons/sourcemod