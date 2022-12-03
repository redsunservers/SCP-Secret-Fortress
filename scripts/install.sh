mkdir build
cd build

wget --input-file=http://sourcemod.net/smdrop/$SM_VERSION/sourcemod-latest-linux
tar -xzf $(cat sourcemod-latest-linux)

cp -r ../addons/sourcemod/scripting addons/sourcemod
cd addons/sourcemod/scripting

wget "https://raw.githubusercontent.com/asherkin/TF2Items/master/pawn/tf2items.inc" -O include/tf2items.inc
wget "https://raw.githubusercontent.com/DoctorMcKay/sourcemod-plugins/master/scripting/include/morecolors.inc" -O include/morecolors.inc
wget "https://raw.githubusercontent.com/FlaminSarge/tf2attributes/master/scripting/include/tf2attributes.inc" -O include/tf2attributes.inc
wget "https://raw.githubusercontent.com/nosoop/SM-TFEconData/master/scripting/include/tf_econ_data.inc" -O include/tf_econ_data.inc
wget "https://raw.githubusercontent.com/nosoop/SM-TFUtils/master/scripting/include/tf2utils.inc" -O include/tf2utils.inc
wget "https://raw.githubusercontent.com/Kenzzer/MemoryPatch/master/addons/sourcemod/scripting/include/memorypatch.inc" -O include/memorypatch.inc
wget "https://raw.githubusercontent.com/Flyflo/SM-Goomba-Stomp/master/addons/sourcemod/scripting/include/goomba.inc" -O include/goomba.inc
wget "https://raw.githubusercontent.com/sbpp/sourcebans-pp/v1.x/game/addons/sourcemod/scripting/include/sourcecomms.inc" -O include/sourcecomms.inc
wget "https://raw.githubusercontent.com/TheByKotik/sendproxy/master/addons/sourcemod/scripting/include/sendproxy.inc" -O include/sendproxy.inc