#!/bin/env bash
#
# Initialize Greendoge service, depending on mode of system requested
#

cd /greendoge-blockchain

. ./activate

# Only the /root/.chia folder is volume-mounted so store greendoge within
mkdir -p /root/.chia/greendoge
rm -f /root/.greendoge
ln -s /root/.chia/greendoge /root/.greendoge 

mkdir -p /root/.greendoge/mainnet/log
greendoge init >> /root/.greendoge/mainnet/log/init.log 2>&1 

echo 'Configuring Greendoge...'
while [ ! -f /root/.greendoge/mainnet/config/config.yaml ]; do
  echo "Waiting for creation of /root/.greendoge/mainnet/config/config.yaml..."
  sleep 1
done
sed -i 's/log_stdout: true/log_stdout: false/g' /root/.greendoge/mainnet/config/config.yaml
sed -i 's/log_level: WARNING/log_level: INFO/g' /root/.greendoge/mainnet/config/config.yaml

# Loop over provided list of key paths
for k in ${keys//:/ }; do
  if [ -f ${k} ]; then
    echo "Adding key at path: ${k}"
    greendoge keys add -f ${k} > /dev/null
  else
    echo "Skipping 'greendoge keys add' as no file found at: ${k}"
  fi
done

# Loop over provided list of completed plot directories
if [ -z "${greendoge_plots_dir}" ]; then
  for p in ${plots_dir//:/ }; do
    greendoge plots add -d ${p}
  done
else
  for p in ${greendoge_plots_dir//:/ }; do
    greendoge plots add -d ${p}
  done
fi

sed -i 's/localhost/127.0.0.1/g' ~/.greendoge/mainnet/config/config.yaml

chmod 755 -R /root/.greendoge/mainnet/config/ssl/ &> /dev/null
greendoge init --fix-ssl-permissions > /dev/null 

# Start services based on mode selected. Default is 'fullnode'
if [[ ${mode} == 'fullnode' ]]; then
  if [ ! -f ~/.greendoge/mainnet/config/ssl/wallet/public_wallet.key ]; then
    echo "No wallet key found, so not starting farming services.  Please add your mnemonic.txt to /root/.chia and restart."
  else
    greendoge start farmer
  fi
elif [[ ${mode} =~ ^farmer.* ]]; then
  if [ ! -f ~/.greendoge/mainnet/config/ssl/wallet/public_wallet.key ]; then
    echo "No wallet key found, so not starting farming services.  Please add your mnemonic.txt to /root/.chia and restart."
  else
    greendoge start farmer-only
  fi
elif [[ ${mode} =~ ^harvester.* ]]; then
  if [[ -z ${farmer_address} || -z ${farmer_port} ]]; then
    echo "A farmer peer address and port are required."
    exit
  else
    if [ ! -f /root/.greendoge/farmer_ca/greendoge_ca.crt ]; then
      mkdir -p /root/.greendoge/farmer_ca
      response=$(curl --write-out '%{http_code}' --silent http://${controller_host}:8932/certificates/?type=greendoge --output /tmp/certs.zip)
      if [ $response == '200' ]; then
        unzip /tmp/certs.zip -d /root/.greendoge/farmer_ca
      else
        echo "Certificates response of ${response} from http://${controller_host}:8932/certificates/?type=greendoge.  Try clicking 'New Worker' button on 'Workers' page first."
      fi
      rm -f /tmp/certs.zip 
    fi
    if [ -f /root/.greendoge/farmer_ca/greendoge_ca.crt ]; then
      greendoge init -c /root/.greendoge/farmer_ca 2>&1 > /root/.greendoge/mainnet/log/init.log
      chmod 755 -R /root/.greendoge/mainnet/config/ssl/ &> /dev/null
      greendoge init --fix-ssl-permissions > /dev/null 
    else
      echo "Did not find your farmer's certificates within /root/.greendoge/farmer_ca."
      echo "See: https://github.com/raingggg/coctohug/wiki"
    fi
    greendoge configure --set-farmer-peer ${farmer_address}:${farmer_port}
    greendoge configure --enable-upnp false
    greendoge start harvester -r
  fi
elif [[ ${mode} == 'plotter' ]]; then
    echo "Starting in Plotter-only mode.  Run Plotman from either CLI or WebUI."
fi
