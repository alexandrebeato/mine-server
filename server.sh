docker run -d --name mc \
  -p 25565:25565 \
  -e MOTD="Server de quem foi selecionado" \
  -e EULA=true \
  -e MODS_MODE=none \
  -v /mnt/c/Ale/mine-server/data:/data \
  -v /mnt/c/Ale/mine-server/mods:/data/mods:ro \
  -it \
  mc-forge-1201:47.4.10