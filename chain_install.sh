#!/bin/env bash
#
# Installs Greendoge as per https://github.com/GreenDoge-Network/greendoge-blockchain
#
GREENDOGE_BRANCH=$1

if [ -z ${GREENDOGE_BRANCH} ]; then
	echo 'Skipping Greendoge install as not requested.'
else
	rm -rf /root/.cache
	git clone --branch ${GREENDOGE_BRANCH} --single-branch https://github.com/GreenDoge-Network/greendoge-blockchain.git /greendoge-blockchain \
		&& cd /greendoge-blockchain \
		&& git submodule update --init mozilla-ca \
		&& chmod +x install.sh \
		&& /usr/bin/sh ./install.sh

	if [ ! -d /chia-blockchain/venv ]; then
		cd /
		rmdir /chia-blockchain
		ln -s /greendoge-blockchain /chia-blockchain
		ln -s /greendoge-blockchain/venv/bin/greendoge /chia-blockchain/venv/bin/chia
	fi
fi
