FROM eclipse-temurin:17-jre-jammy

ENV APP_HOME=/data \
    USER=minecraft \
    UID=1000 \
    GID=1000

RUN apt-get update && apt-get install -y --no-install-recommends \
      bash ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Usuário não-root
RUN groupadd -g ${GID} ${USER} \
 && useradd -m -u ${UID} -g ${GID} -s /bin/bash ${USER}

# Pastas fixas do container
RUN mkdir -p /opt/forge /opt/mods-bundled ${APP_HOME} \
 && chown -R ${UID}:${GID} /opt ${APP_HOME}

WORKDIR ${APP_HOME}

# Installer local (você tem o arquivo)
COPY --chown=${UID}:${GID} forge-1.20.1-47.4.10-installer.jar /opt/forge/forge-installer.jar

# Mods locais (ficam guardados na imagem como "fallback")
COPY --chown=${UID}:${GID} mods/ /opt/mods-bundled/

# Script de start
COPY --chown=${UID}:${GID} start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/start.sh

EXPOSE 25565

USER ${USER}
VOLUME ["/data"]

ENTRYPOINT ["/usr/local/bin/start.sh"]
