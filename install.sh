#!/bin/bash

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# ASCII Art
print_logo() {
    echo -e "${CYAN}"
    echo " _______  _______                    _______  _        _       "
    echo "(  ___  )(  ____ \|\     /||\     /|(  ___  )( (    /|| \    /\ "
    echo "| (   ) || (    \/| )   ( || )   ( || (   ) ||  \  ( ||  \  / / "
    echo "| |   | || (_____ | (___) || |   | || (___) ||   \ | ||  (_/ /  "
    echo "| |   | |(_____  )|  ___  |( (   ) )|  ___  || (\ \) ||   _ (   "
    echo "| |   | |      ) || (   ) | \ \_/ / | (   ) || | \   ||  ( \ \  "
    echo "| (___) |/\____) || )   ( |  \   /  | )   ( || )  \  ||  /  \ \ "
    echo "(_______)\_______)|/     \|   \_/   |/     \||/    )_)|_/    \_\\"
    echo -e "${NC}"
    echo
    echo -e "${YELLOW}============================================================${NC}"
    echo -e "${WHITE}             Arkhadian Setup Script${NC}"
    echo -e "${WHITE}              Prepared by: OshVanK${NC}"
    echo -e "${YELLOW}============================================================${NC}"
    echo
}

# Error handling
check_error() {
    if [ $? -ne 0 ]; then
        echo -e "${RED}Error: $1${NC}"
        exit 1
    fi
}

# Info message
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

# Warning message
print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Display logo
print_logo

# Get user input
echo -e "${CYAN}Please provide the following information:${NC}"
echo
read -p "Enter your Moniker (node name): " MONIKER
read -p "Enter your Wallet name (default: wallet): " WALLET
WALLET=${WALLET:-wallet}

echo
echo -e "${CYAN}Port Configuration:${NC}"
echo "Do you want to use custom ports?"
read -p "Choice (y/n, default: n): " USE_CUSTOM_PORT
USE_CUSTOM_PORT=${USE_CUSTOM_PORT:-n}

if [ "$USE_CUSTOM_PORT" = "y" ] || [ "$USE_CUSTOM_PORT" = "Y" ]; then
    read -p "Enter port prefix (e.g., 27 for 27xxx ports): " ARKH_PORT
else
    ARKH_PORT="26"
    print_info "Using default ports (26xxx)"
fi

# Save variables
export WALLET="$WALLET"
export MONIKER="$MONIKER"
export ARKH_CHAIN_ID="arkh"
export ARKH_PORT="$ARKH_PORT"

# Save to bash profile
echo "export WALLET=\"$WALLET\"" >> $HOME/.bash_profile
echo "export MONIKER=\"$MONIKER\"" >> $HOME/.bash_profile
echo "export ARKH_CHAIN_ID=\"arkh\"" >> $HOME/.bash_profile
echo "export ARKH_PORT=\"$ARKH_PORT\"" >> $HOME/.bash_profile
source $HOME/.bash_profile

echo
print_info "Configuration Summary:"
echo "  - Moniker: $MONIKER"
echo "  - Wallet: $WALLET"
echo "  - Chain ID: $ARKH_CHAIN_ID"
echo "  - Port Prefix: $ARKH_PORT"
echo

# Update system
print_info "Updating system packages..."
sudo apt update && sudo apt upgrade -y
check_error "System update failed"

# Install required packages
print_info "Installing required packages..."
sudo apt install -y curl tar wget clang pkg-config libssl-dev jq build-essential git make ncdu lz4
check_error "Package installation failed"

# Check and install Go
print_info "Checking Go installation..."
if ! command -v go &> /dev/null; then
    print_warning "Go not found. Installing Go..."
    
    GO_VERSION="1.23.3"
    cd $HOME
    wget "https://golang.org/dl/go${GO_VERSION}.linux-amd64.tar.gz"
    check_error "Go download failed"
    
    sudo rm -rf /usr/local/go
    sudo tar -C /usr/local -xzf "go${GO_VERSION}.linux-amd64.tar.gz"
    rm "go${GO_VERSION}.linux-amd64.tar.gz"
    
    echo "export PATH=\$PATH:/usr/local/go/bin:\$HOME/go/bin" >> $HOME/.bash_profile
    source $HOME/.bash_profile
    
    print_info "Go ${GO_VERSION} installed successfully"
else
    GO_CURRENT=$(go version | awk '{print $3}')
    print_info "Go already installed: $GO_CURRENT"
fi

# Ensure Go path is set
export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin

# Install Cosmovisor
print_info "Installing Cosmovisor..."
go install cosmossdk.io/tools/cosmovisor/cmd/cosmovisor@latest
check_error "Cosmovisor installation failed"

# Download and build binary
print_info "Downloading and building Arkhadian binary..."
cd $HOME
rm -rf arkh-blockchain
git clone https://github.com/vincadian/arkh-blockchain
check_error "Git clone failed"

cd arkh-blockchain
git checkout v2.0.0
check_error "Git checkout failed"

print_info "Building binary... (This may take a few minutes)"
go build -o arkhd ./cmd/arkhd
check_error "Binary build failed"

# Setup Cosmovisor directory structure
print_info "Setting up Cosmovisor directory structure..."
mkdir -p $HOME/.arkh/cosmovisor/genesis/bin
mkdir -p $HOME/.arkh/cosmovisor/upgrades

# Move binary to Cosmovisor
mv arkhd $HOME/.arkh/cosmovisor/genesis/bin/
check_error "Binary move failed"

# Create symlink
ln -sf $HOME/.arkh/cosmovisor/genesis/bin/arkhd $HOME/go/bin/arkhd

print_info "Binary installed successfully"

# Configure node
print_info "Configuring node..."
arkhd config node tcp://localhost:${ARKH_PORT}657
arkhd config keyring-backend os
arkhd config chain-id $ARKH_CHAIN_ID
arkhd init "$MONIKER" --chain-id $ARKH_CHAIN_ID
check_error "Node initialization failed"

# Download genesis and addrbook
print_info "Downloading genesis and addrbook files..."
wget -O $HOME/.arkh/config/genesis.json https://raw.githubusercontent.com/Edsny1/Arkhadian-Mainnet-Setup/refs/heads/Edsny/genesis.json
check_error "Genesis download failed"

wget -O $HOME/.arkh/config/addrbook.json https://raw.githubusercontent.com/Edsny1/Arkhadian-Mainnet-Setup/refs/heads/Edsny/addrbook.json
check_error "Addrbook download failed"

# Set seeds and peers
print_info "Configuring seeds and peers..."
SEEDS=""
PEERS="799864422fd0b6e4614397ca7417737dc726be39@65.108.229.19:26866"
sed -i -e "s/^seeds *=.*/seeds = \"$SEEDS\"/; s/^persistent_peers *=.*/persistent_peers = \"$PEERS\"/" $HOME/.arkh/config/config.toml

# Configure custom ports in app.toml
print_info "Configuring custom ports..."
sed -i.bak -e "s%:1317%:${ARKH_PORT}317%g;
s%:8080%:${ARKH_PORT}080%g;
s%:9090%:${ARKH_PORT}090%g;
s%:9091%:${ARKH_PORT}091%g;
s%:8545%:${ARKH_PORT}545%g;
s%:8546%:${ARKH_PORT}546%g;
s%:6065%:${ARKH_PORT}065%g" $HOME/.arkh/config/app.toml

# Configure custom ports in config.toml
sed -i.bak -e "s%:26658%:${ARKH_PORT}658%g;
s%:26657%:${ARKH_PORT}657%g;
s%:6060%:${ARKH_PORT}060%g;
s%:26656%:${ARKH_PORT}656%g;
s%^external_address = \"\"%external_address = \"$(wget -qO- eth0.me):${ARKH_PORT}656\"%;
s%:26660%:${ARKH_PORT}660%g" $HOME/.arkh/config/config.toml

# Configure pruning
print_info "Configuring pruning settings..."
sed -i -e "s/^pruning *=.*/pruning = \"custom\"/" $HOME/.arkh/config/app.toml
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"100\"/" $HOME/.arkh/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"50\"/" $HOME/.arkh/config/app.toml

# Set minimum gas price, enable prometheus and disable indexing
print_info "Configuring gas price and other settings..."
sed -i 's|minimum-gas-prices =.*|minimum-gas-prices = "0.0arkh"|g' $HOME/.arkh/config/app.toml
sed -i -e "s/prometheus = false/prometheus = true/" $HOME/.arkh/config/config.toml
sed -i -e "s/^indexer *=.*/indexer = \"null\"/" $HOME/.arkh/config/config.toml

# State Sync configuration
print_info "Do you want to enable State Sync? (Fast synchronization)"
read -p "Choice (y/n, default: y): " USE_STATE_SYNC
USE_STATE_SYNC=${USE_STATE_SYNC:-y}

if [ "$USE_STATE_SYNC" = "y" ] || [ "$USE_STATE_SYNC" = "Y" ]; then
    print_info "Enabling State Sync..."
    
    SNAP_RPC=https://arkh.rpc.m.anode.team:443
    
    print_info "Fetching latest block height..."
    LATEST_HEIGHT=$(curl -s $SNAP_RPC/block | jq -r .result.block.header.height)
    BLOCK_HEIGHT=$((LATEST_HEIGHT - 2000))
    TRUST_HASH=$(curl -s "$SNAP_RPC/block?height=$BLOCK_HEIGHT" | jq -r .result.block_id.hash)
    
    print_info "State Sync Information:"
    echo "  - Latest Height: $LATEST_HEIGHT"
    echo "  - Block Height: $BLOCK_HEIGHT"
    echo "  - Trust Hash: $TRUST_HASH"
    
    # Download and run unsafe-reset-all script
    cd $HOME
    wget -q https://anode.team/unsafe-reset-all.sh
    chmod u+x unsafe-reset-all.sh
    ./unsafe-reset-all.sh arkhd .arkh
    
    # Configure state sync in config.toml
    sed -i.bak -E "s|^(enable[[:space:]]+=[[:space:]]+).*$|\1true| ; \
    s|^(rpc_servers[[:space:]]+=[[:space:]]+).*$|\1\"$SNAP_RPC,$SNAP_RPC\"| ; \
    s|^(trust_height[[:space:]]+=[[:space:]]+).*$|\1$BLOCK_HEIGHT| ; \
    s|^(trust_hash[[:space:]]+=[[:space:]]+).*$|\1\"$TRUST_HASH\"| ; \
    s|^(seeds[[:space:]]+=[[:space:]]+).*$|\1\"\"|" $HOME/.arkh/config/config.toml
    
    print_info "State Sync configured successfully"
else
    print_info "State Sync skipped. Node will sync from genesis."
fi

# Create systemd service file
print_info "Creating systemd service file..."
sudo tee /etc/systemd/system/arkhd.service > /dev/null <<EOF
[Unit]
Description=Arkhadian Node (Cosmovisor)
After=network-online.target

[Service]
User=$USER
ExecStart=$(which cosmovisor) run start --home $HOME/.arkh
Restart=on-failure
RestartSec=10
LimitNOFILE=65535
Environment="DAEMON_HOME=$HOME/.arkh"
Environment="DAEMON_NAME=arkhd"
Environment="UNSAFE_SKIP_BACKUP=true"
Environment="DAEMON_ALLOW_DOWNLOAD_BINARIES=false"

[Install]
WantedBy=multi-user.target
EOF

# Enable and start service
print_info "Enabling and starting service..."
sudo systemctl daemon-reload
sudo systemctl enable arkhd

echo
echo -e "${YELLOW}============================================================${NC}"
echo -e "${GREEN}Installation Complete!${NC}"
echo -e "${YELLOW}============================================================${NC}"
echo
echo -e "${CYAN}Next Steps:${NC}"
echo
echo "1. Start your node:"
echo -e "   ${WHITE}sudo systemctl start arkhd${NC}"
echo
echo "2. View logs:"
echo -e "   ${WHITE}sudo journalctl -fu arkhd -o cat${NC}"
echo
echo "3. Check node status:"
echo -e "   ${WHITE}sudo systemctl status arkhd${NC}"
echo
echo "4. Check synchronization status:"
echo -e "   ${WHITE}arkhd status 2>&1 | jq .SyncInfo${NC}"
echo
echo "5. Create a wallet:"
echo -e "   ${WHITE}arkhd keys add $WALLET${NC}"
echo
echo "6. Or recover existing wallet:"
echo -e "   ${WHITE}arkhd keys add $WALLET --recover${NC}"
echo
echo -e "${YELLOW}Important Notes:${NC}"
echo -e "  ${RED}•${NC} Save your mnemonic phrase securely!"
echo -e "  ${RED}•${NC} Wait for full synchronization before creating validator"
echo -e "  ${RED}•${NC} Check sync status: ${WHITE}catching_up: false${NC} means synced"
echo
echo -e "${CYAN}Useful Commands:${NC}"
echo -e "  Check balance: ${WHITE}arkhd query bank balances \$(arkhd keys show $WALLET -a)${NC}"
echo -e "  Check peers: ${WHITE}curl -s localhost:${ARKH_PORT}657/net_info | jq -r .result.n_peers${NC}"
echo
echo -e "${YELLOW}============================================================${NC}"
echo -e "${GREEN}Thank you for choosing Arkhadian Network!${NC}"
echo -e "${WHITE}Prepared by: OshVanK${NC}"
echo -e "${YELLOW}============================================================${NC}"
echo
