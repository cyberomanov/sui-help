#!/usr/bin/bash

sudo apt update && sudo apt upgrade -y && \
sudo apt install wget jq git libclang-dev libpq-dev cmake -y

sudo curl https://sh.rustup.rs -sSf | sh -s -- -y && \
source "$HOME/.cargo/env"

cd $HOME && \
mkdir -p $HOME/.sui; \
rm -Rvf ~/sui; \
git clone https://github.com/MystenLabs/sui

cd ~/sui && \
git remote add upstream https://github.com/MystenLabs/sui; \
git fetch upstream; \
git checkout -B testnet --track upstream/testnet

FIXED_CHECK=$(cat $HOME/sui/crates/sui-config/src/node.rs | grep "18080u16")
if [[ ${FIXED_CHECK} == "" ]]; then
    echo -e "\nfixing ports [node.rs]."
    sed -i -e "s/8080u16/18080u16/g" $HOME/sui/crates/sui-config/src/node.rs && \
    sed -i -e "s/9184/19184/g" $HOME/sui/crates/sui-config/src/node.rs && \
    sed -i -e "s/9000/19000/g" $HOME/sui/crates/sui-config/src/node.rs && \
    sed -i -e "s/9001/19001/g" $HOME/sui/crates/sui-config/src/node.rs && \
    sed -i -e "s/1337/11337/g" $HOME/sui/crates/sui-config/src/node.rs
else
    echo -e "\nports already fixed [node.rs]."
fi && \

FIXED_CHECK=$(cat $HOME/sui/crates/sui-config/src/swarm.rs | grep "18888")
if [[ ${FIXED_CHECK} == "" ]]; then
    echo -e "fixing ports [swarm.rs]."
    sed -i -e "s/8888/18888/g" $HOME/sui/crates/sui-config/src/swarm.rs && \
    sed -i -e "s/9000/19000/g" $HOME/sui/crates/sui-config/src/swarm.rs && \
    sed -i -e "s/8084/18084/g" $HOME/sui/crates/sui-config/src/swarm.rs && \
    sed -i -e "s/8080/18080/g" $HOME/sui/crates/sui-config/src/swarm.rs
else
    echo -e "ports already fixed [swarm.rs]."
fi && \

FIXED_CHECK=$(cat $HOME/sui/crates/sui-config/src/p2p.rs | grep "18080")
if [[ ${FIXED_CHECK} == "" ]]; then
    echo -e "fixing ports [p2p.rs].\n"
    sed -i -e "s/8080/18080/g" $HOME/sui/crates/sui-config/src/p2p.rs
else
    echo -e "ports already fixed [p2p.rs].\n"
fi

cargo build --release

mv $HOME/sui/target/release/{sui,sui-node,sui-faucet} /usr/bin/ && \
cd

wget -qO $HOME/.sui/genesis.blob https://github.com/MystenLabs/sui-genesis/raw/main/testnet/genesis.blob && \
cp $HOME/sui/crates/sui-config/data/fullnode-template.yaml $HOME/.sui/fullnode.yaml

sed -i -e "s%db-path:.*%db-path: \"$HOME/.sui/db\"%; "\
"s%network-address:.*%network-address: \"/dns/localhost/tcp/18080/http\"%; "\
"s%metrics-address:.*%metrics-address: \"0.0.0.0:19184\"%; "\
"s%json-rpc-address:.*%json-rpc-address: \"0.0.0.0:19000\"%; "\
"s%websocket-address:.*%websocket-address: \"0.0.0.0:19001\"%; "\
"s%genesis-file-location:.*%genesis-file-location: \"$HOME/.sui/genesis.blob\"%; " $HOME/.sui/fullnode.yaml

sudo tee -a $HOME/.sui/fullnode.yaml  >/dev/null <<EOF

p2p-config:
  seed-peers:
    - address: "/ip4/65.109.32.171/udp/8084"
    - address: "/ip4/65.108.44.149/udp/8084"
    - address: "/ip4/95.214.54.28/udp/8080"
    - address: "/ip4/136.243.40.38/udp/8080"
    - address: "/ip4/84.46.255.11/udp/8084"
    - address: "/ip4/162.19.215.24/udp/8080"
EOF

printf "[Unit]
Description=Sui node
After=network-online.target
[Service]
User=$USER
ExecStart=$(which sui-node) \\
--config-path $HOME/.sui/fullnode.yaml
Restart=on-failure
RestartSec=3
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target" > /etc/systemd/system/suid.service

sudo systemctl daemon-reload && \
sudo systemctl enable suid && \
sudo systemctl restart suid && \
echo -e "\n$(sui-node --version)\n"
