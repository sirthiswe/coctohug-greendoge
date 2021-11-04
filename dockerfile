FROM coctohug-body:latest
ARG GREENDOGE_BRANCH

# copy local files
COPY . /coctohug/

# set workdir
WORKDIR /chia-blockchain

# Install Chia (and forks), Plotman, Chiadog, Coctohug, etc
RUN \
	/usr/bin/bash /coctohug/chain_install.sh ${GREENDOGE_BRANCH} \
	&& /usr/bin/bash /coctohug/coctohug_install.sh \
	&& rm -rf \
		/root/.cache \
		/tmp/* \
		/var/lib/apt/lists/* \
		/var/tmp/*

# Provide a colon-separated list of in-container paths to your mnemonic keys
ENV keys="/root/.chia/mnemonic.txt"  
# Provide a colon-separated list of in-container paths to your completed plots
ENV plots_dir="/plots"
# One of fullnode, farmer, harvester, plotter, farmer+plotter, harvester+plotter. Default is fullnode
ENV mode="fullnode" 
# The single blockchain to run: chia, flax, nchain, hddcoin, chives, etc
ENV blockchains="greendoge"
# If mode=harvester, required for host and port the harvester will your farmer
ENV farmer_address="null"
ENV farmer_port="6547"
# Can override the location of default settings for api and web servers.
ENV API_SETTINGS_FILE='/root/.chia/coctohug/config/api.cfg'
ENV WEB_SETTINGS_FILE='/root/.chia/coctohug/config/web.cfg'
# Local network hostname of a Coctohug controller - localhost when standalone
ENV controller_host="localhost"
ENV controller_web_port=8926
ENV controller_api_port=8927

ENV PATH="${PATH}:/chia-blockchain/venv/bin"
ENV TZ=Etc/UTC
ENV FLASK_ENV=production
ENV XDG_CONFIG_HOME=/root/.chia
ENV AUTO_PLOT=false

VOLUME [ "/id_rsa" ]

# blockchain protocol port - forward at router
EXPOSE 6544
# blockchain farmer port - DO NOT forward at router
EXPOSE 6547
# Coctohug WebUI - DO NOT forward at router, proxy if needed
# EXPOSE 8926
# Coctohug API - DO NOT forward at router
# EXPOSE 8927

WORKDIR /chia-blockchain
ENTRYPOINT ["bash", "./entrypoint.sh"]