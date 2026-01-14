#!/usr/bin/env bash
set -euo pipefail

log() { echo "[mc] $*"; }

cd /data

# ===== Config por env =====
: "${EULA:=true}"
: "${JVM_XMS:=2G}"
: "${JVM_XMX:=4G}"

# MODS_MODE:
# - image  -> copia mods embutidos (/opt/mods-bundled) para /data/mods quando possível
# - none   -> não mexe em mods
: "${MODS_MODE:=image}"

# ===== EULA =====
if [[ "${EULA}" == "true" ]]; then
  echo "eula=true" > eula.txt
else
  log "EULA não aceito. Defina EULA=true"
  exit 1
fi

# ===== Pastas base =====
mkdir -p /data/mods /data/config /data/logs || true

# ===== Corrigir caso exista pasta literal 'mods\' dentro de /data (WSL/NTFS) =====
# Isso acontece quando alguma coisa criou uma pasta com "\" no nome. Vamos tentar corrigir.
if [[ -d "/data/mods\\" && ! -d "/data/mods" ]]; then
  log "Detectei pasta estranha '/data/mods\' (com barra invertida). Tentando corrigir..."
  mv "/data/mods\\" "/data/mods" || true
fi

# ===== Detecta se o Forge já está instalado no volume /data =====
has_forge=false
if [[ -f "./run.sh" ]]; then
  has_forge=true
elif ls -1 forge-*-server.jar >/dev/null 2>&1; then
  has_forge=true
fi

# ===== Bootstrap: instalar Forge dentro do volume se não existir =====
if [[ "${has_forge}" == "false" ]]; then
  log "Forge não encontrado em /data. Instalando Forge Server (pode demorar na primeira vez)..."
  log "Usando installer: /opt/forge/forge-installer.jar"

  # A instalação do Forge cria run.sh, libraries, etc dentro de /data
  java -jar /opt/forge/forge-installer.jar --installServer /data

  log "Instalação do Forge concluída."
else
  log "Forge já está presente em /data. Pulando instalação."
fi

# ===== Mods: copiar os mods embutidos da imagem para /data/mods (se permitido) =====
# Obs: se você montar -v ./mods:/data/mods:ro, /data/mods NÃO será gravável; aí a cópia é ignorada.
if [[ "${MODS_MODE}" == "image" ]]; then
  if [[ -w "/data/mods" ]]; then
    # Copia apenas se /data/mods estiver vazio (pra não sobrescrever mods do usuário)
    if [[ -z "$(ls -A /data/mods 2>/dev/null || true)" ]]; then
      if [[ -n "$(ls -A /opt/mods-bundled 2>/dev/null || true)" ]]; then
        log "Copiando mods embutidos da imagem -> /data/mods (porque está vazio)..."
        cp -a /opt/mods-bundled/. /data/mods/
      else
        log "Nenhum mod encontrado em /opt/mods-bundled (imagem)."
      fi
    else
      log "/data/mods já tem arquivos. Não vou sobrescrever."
    fi
  else
    log "/data/mods não é gravável (provavelmente você montou ./mods como :ro). Vou respeitar e não copiar."
  fi
else
  log "MODS_MODE=${MODS_MODE}. Não vou mexer na pasta mods."
fi

# ===== Rodar o servidor =====
# Preferir run.sh gerado pelo Forge
if [[ -f "./run.sh" ]]; then
  chmod +x ./run.sh || true
  log "Iniciando via run.sh (Forge)."
  exec ./run.sh nogui
fi

# Fallback: tentar achar forge-*-server.jar
FORGE_JAR="$(ls -1 forge-*-server.jar 2>/dev/null | head -n 1 || true)"
if [[ -n "${FORGE_JAR}" ]]; then
  log "Iniciando via jar: ${FORGE_JAR}"
  exec java -Xms${JVM_XMS} -Xmx${JVM_XMX} -jar "${FORGE_JAR}" nogui
fi

log "ERRO: Não encontrei run.sh nem forge-*-server.jar após instalação."
log "Listando /data:"
ls -la
exit 1
