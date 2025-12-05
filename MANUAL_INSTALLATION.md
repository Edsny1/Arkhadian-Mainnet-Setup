# Arkhadian Network - Manuel Kurulum Kılavuzu

## 📋 İçindekiler

1. [Sistem Gereksinimleri](#sistem-gereksinimleri)
2. [Sistem Güncellemesi](#sistem-güncellemesi)
3. [Gerekli Paketlerin Kurulumu](#gerekli-paketlerin-kurulumu)
4. [Go Kurulumu](#go-kurulumu)
5. [Cosmovisor Kurulumu](#cosmovisor-kurulumu)
6. [Binary İndirme ve Derleme](#binary-indirme-ve-derleme)
7. [Node Yapılandırması](#node-yapılandırması)
8. [Genesis ve Addrbook Kurulumu](#genesis-ve-addrbook-kurulumu)
9. [Seeds ve Peers Ayarları](#seeds-ve-peers-ayarları)
10. [Port Yapılandırması](#port-yapılandırması)
11. [Pruning Ayarları](#pruning-ayarları)
12. [Gas Price ve Diğer Ayarlar](#gas-price-ve-diğer-ayarlar)
13. [State Sync Yapılandırması](#state-sync-yapılandırması)
14. [Systemd Service Oluşturma](#systemd-service-oluşturma)
15. [Node Başlatma](#node-başlatma)
16. [Cüzdan Oluşturma](#cüzdan-oluşturma)
17. [Validator Oluşturma](#validator-oluşturma)
18. [Faydalı Komutlar](#faydalı-komutlar)

---

## Sistem Gereksinimleri

### Minimum Gereksinimler:
- **CPU**: 4 Cores
- **RAM**: 8 GB
- **Disk**: 200 GB SSD
- **Bant Genişliği**: 100 Mbps
- **İşletim Sistemi**: Ubuntu 20.04 / 22.04 / 24.04 LTS

### Önerilen Gereksinimler:
- **CPU**: 8 Cores
- **RAM**: 16 GB
- **Disk**: 500 GB NVMe SSD
- **Bant Genişliği**: 1 Gbps

---

## Sistem Güncellemesi

Öncelikle sisteminizi güncelleyin:

```bash
sudo apt update && sudo apt upgrade -y
```

---

## Gerekli Paketlerin Kurulumu

Gerekli tüm paketleri kurun:

```bash
sudo apt install -y curl tar wget clang pkg-config libssl-dev jq build-essential git make ncdu lz4
```

**Paket Açıklamaları:**
- `curl`, `wget`: Dosya indirme araçları
- `git`: Versiyon kontrol sistemi
- `build-essential`: C/C++ derleyici araçları
- `jq`: JSON işleme aracı
- `lz4`: Sıkıştırma aracı (snapshot için)

---

## Go Kurulumu

### 1. Go Kurulu mu Kontrol Edin

```bash
go version
```

Eğer Go kurulu değilse veya eski bir versiyon kullanıyorsanız:

### 2. Go İndirin ve Kurun

```bash
# Go versiyonunu belirleyin
GO_VERSION="1.23.3"

# Go'yu indirin
cd $HOME
wget "https://golang.org/dl/go${GO_VERSION}.linux-amd64.tar.gz"

# Eski Go versiyonunu kaldırın (varsa)
sudo rm -rf /usr/local/go

# Yeni versiyonu kurun
sudo tar -C /usr/local -xzf "go${GO_VERSION}.linux-amd64.tar.gz"

# İndirilen dosyayı silin
rm "go${GO_VERSION}.linux-amd64.tar.gz"
```

### 3. Go PATH Ayarlarını Yapın

```bash
echo "export PATH=\$PATH:/usr/local/go/bin:\$HOME/go/bin" >> $HOME/.bash_profile
source $HOME/.bash_profile
```

### 4. Kurulumu Doğrulayın

```bash
go version
```

Çıktı: `go version go1.23.3 linux/amd64` şeklinde olmalıdır.

---

## Cosmovisor Kurulumu

Cosmovisor, Cosmos SDK tabanlı blockchain'ler için otomatik upgrade yönetim aracıdır.

```bash
go install cosmossdk.io/tools/cosmovisor/cmd/cosmovisor@latest
```

Kurulumu doğrulayın:

```bash
cosmovisor version
```

---

## Binary İndirme ve Derleme

### 1. Değişkenleri Ayarlayın

```bash
# Moniker ve wallet adınızı belirleyin
echo "export WALLET=\"wallet\"" >> $HOME/.bash_profile
echo "export MONIKER=\"your-node-name\"" >> $HOME/.bash_profile
echo "export ARKH_CHAIN_ID=\"arkh\"" >> $HOME/.bash_profile
echo "export ARKH_PORT=\"26\"" >> $HOME/.bash_profile
source $HOME/.bash_profile
```

**Not:** 
- `MONIKER`: Node adınız (örn: "MyArkhNode")
- `WALLET`: Cüzdan adınız
- `ARKH_PORT`: Port numarası (varsayılan: 26, özel port için değiştirebilirsiniz)

### 2. Repository'yi Klonlayın

```bash
cd $HOME
rm -rf arkh-blockchain
git clone https://github.com/vincadian/arkh-blockchain
cd arkh-blockchain
```

### 3. Doğru Versiyona Geçin

```bash
git checkout v2.0.0
```

### 4. Binary'yi Derleyin

```bash
go build -o arkhd ./cmd/arkhd
```

**Not:** Bu işlem birkaç dakika sürebilir.

### 5. Cosmovisor Dizin Yapısını Oluşturun

```bash
mkdir -p $HOME/.arkh/cosmovisor/genesis/bin
mkdir -p $HOME/.arkh/cosmovisor/upgrades
```

### 6. Binary'yi Taşıyın

```bash
mv arkhd $HOME/.arkh/cosmovisor/genesis/bin/
```

### 7. Symlink Oluşturun

```bash
ln -sf $HOME/.arkh/cosmovisor/genesis/bin/arkhd $HOME/go/bin/arkhd
```

### 8. Kurulumu Doğrulayın

```bash
arkhd version
```

---

## Node Yapılandırması

### 1. Node'u Yapılandırın

```bash
arkhd config node tcp://localhost:${ARKH_PORT}657
arkhd config keyring-backend os
arkhd config chain-id $ARKH_CHAIN_ID
```

### 2. Node'u Initialize Edin

```bash
arkhd init "$MONIKER" --chain-id $ARKH_CHAIN_ID
```

Bu komut `$HOME/.arkh` dizinini oluşturacak ve gerekli yapılandırma dosyalarını hazırlayacaktır.

---

## Genesis ve Addrbook Kurulumu

### 1. Genesis Dosyasını İndirin

```bash
wget -O $HOME/.arkh/config/genesis.json https://raw.githubusercontent.com/Edsny1/Arkhadian-Mainnet-Setup/refs/heads/Edsny/genesis.json
```

### 2. Addrbook Dosyasını İndirin

```bash
wget -O $HOME/.arkh/config/addrbook.json https://raw.githubusercontent.com/Edsny1/Arkhadian-Mainnet-Setup/refs/heads/Edsny/addrbook.json
```

### 3. Dosyaları Doğrulayın

```bash
# Genesis dosyasını kontrol edin
cat $HOME/.arkh/config/genesis.json | jq '.chain_id'
# Çıktı: "arkh" olmalı

# Addrbook dosyasını kontrol edin
cat $HOME/.arkh/config/addrbook.json | jq '.addrs | length'
# Bir sayı döndürmeli (peer sayısı)
```

---

## Seeds ve Peers Ayarları

### Peers Yapılandırması

```bash
SEEDS=""
PEERS="799864422fd0b6e4614397ca7417737dc726be39@65.108.229.19:26866"

sed -i -e "s/^seeds *=.*/seeds = \"$SEEDS\"/; s/^persistent_peers *=.*/persistent_peers = \"$PEERS\"/" $HOME/.arkh/config/config.toml
```

**Açıklama:**
- `seeds`: Bootstrap node'ları (boş bırakılabilir)
- `persistent_peers`: Sürekli bağlantıda kalınacak peer'lar

---

## Port Yapılandırması

### Varsayılan Portlar (26xxx)

Eğer varsayılan portları kullanacaksanız bu adımı atlayabilirsiniz.

### Özel Port Yapılandırması

Eğer özel portlar kullanmak istiyorsanız (örn: 27xxx):

#### 1. app.toml Dosyasını Düzenleyin

```bash
sed -i.bak -e "s%:1317%:${ARKH_PORT}317%g;
s%:8080%:${ARKH_PORT}080%g;
s%:9090%:${ARKH_PORT}090%g;
s%:9091%:${ARKH_PORT}091%g;
s%:8545%:${ARKH_PORT}545%g;
s%:8546%:${ARKH_PORT}546%g;
s%:6065%:${ARKH_PORT}065%g" $HOME/.arkh/config/app.toml
```

#### 2. config.toml Dosyasını Düzenleyin

```bash
sed -i.bak -e "s%:26658%:${ARKH_PORT}658%g;
s%:26657%:${ARKH_PORT}657%g;
s%:6060%:${ARKH_PORT}060%g;
s%:26656%:${ARKH_PORT}656%g;
s%^external_address = \"\"%external_address = \"$(wget -qO- eth0.me):${ARKH_PORT}656\"%;
s%:26660%:${ARKH_PORT}660%g" $HOME/.arkh/config/config.toml
```

### Port Tablosu

| Servis | Varsayılan | Özel (27) |
|--------|-----------|-----------|
| P2P | 26656 | 27656 |
| RPC | 26657 | 27657 |
| gRPC | 26090 | 27090 |
| API | 26317 | 27317 |
| Prometheus | 26660 | 27660 |

---

## Pruning Ayarları

Disk kullanımını optimize etmek için pruning ayarlarını yapılandırın:

```bash
sed -i -e "s/^pruning *=.*/pruning = \"custom\"/" $HOME/.arkh/config/app.toml
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"100\"/" $HOME/.arkh/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"50\"/" $HOME/.arkh/config/app.toml
```

**Açıklama:**
- `pruning = "custom"`: Özel pruning ayarları kullan
- `pruning-keep-recent = "100"`: Son 100 bloğu sakla
- `pruning-interval = "50"`: Her 50 blokta bir pruning yap

---

## Gas Price ve Diğer Ayarlar

### 1. Minimum Gas Price Ayarlayın

```bash
sed -i 's|minimum-gas-prices =.*|minimum-gas-prices = "0.0arkh"|g' $HOME/.arkh/config/app.toml
```

### 2. Prometheus'u Etkinleştirin

```bash
sed -i -e "s/prometheus = false/prometheus = true/" $HOME/.arkh/config/config.toml
```

### 3. Indexer'ı Devre Dışı Bırakın (Opsiyonel)

```bash
sed -i -e "s/^indexer *=.*/indexer = \"null\"/" $HOME/.arkh/config/config.toml
```

**Not:** Indexer'ı kapatmak disk kullanımını azaltır ancak transaction sorgulama özelliğini kısıtlar.

---

## State Sync Yapılandırması

State Sync, node'unuzun hızlı bir şekilde senkronize olmasını sağlar.

### 1. RPC Endpoint ve Blok Bilgilerini Alın

```bash
SNAP_RPC=https://arkh.rpc.m.anode.team:443

# En son blok yüksekliğini alın
LATEST_HEIGHT=$(curl -s $SNAP_RPC/block | jq -r .result.block.header.height)

# Trust height'ı hesaplayın (2000 blok geriye)
BLOCK_HEIGHT=$((LATEST_HEIGHT - 2000))

# Trust hash'i alın
TRUST_HASH=$(curl -s "$SNAP_RPC/block?height=$BLOCK_HEIGHT" | jq -r .result.block_id.hash)

# Bilgileri göster
echo "Latest Height: $LATEST_HEIGHT"
echo "Block Height: $BLOCK_HEIGHT"
echo "Trust Hash: $TRUST_HASH"
```

### 2. Unsafe Reset Script'ini İndirin ve Çalıştırın

```bash
cd $HOME
wget https://anode.team/unsafe-reset-all.sh
chmod u+x unsafe-reset-all.sh
./unsafe-reset-all.sh arkhd .arkh
```

**Uyarı:** Bu komut node data'nızı sıfırlar! Sadece ilk kurulumda kullanın.

### 3. State Sync Ayarlarını Yapılandırın

```bash
sed -i.bak -E "s|^(enable[[:space:]]+=[[:space:]]+).*$|\1true| ; \
s|^(rpc_servers[[:space:]]+=[[:space:]]+).*$|\1\"$SNAP_RPC,$SNAP_RPC\"| ; \
s|^(trust_height[[:space:]]+=[[:space:]]+).*$|\1$BLOCK_HEIGHT| ; \
s|^(trust_hash[[:space:]]+=[[:space:]]+).*$|\1\"$TRUST_HASH\"| ; \
s|^(seeds[[:space:]]+=[[:space:]]+).*$|\1\"\"|" $HOME/.arkh/config/config.toml
```

---

## Systemd Service Oluşturma

### 1. Service Dosyasını Oluşturun

```bash
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
```

**Açıklama:**
- `User=$USER`: Service'i mevcut kullanıcı ile çalıştır
- `DAEMON_HOME`: Node'un ana dizini
- `DAEMON_NAME`: Binary adı
- `UNSAFE_SKIP_BACKUP=true`: Upgrade sırasında backup atla
- `DAEMON_ALLOW_DOWNLOAD_BINARIES=false`: Otomatik binary indirmeyi devre dışı bırak

### 2. Service'i Etkinleştirin

```bash
# Systemd'yi yeniden yükle
sudo systemctl daemon-reload

# Service'i etkinleştir
sudo systemctl enable arkhd
```

---

## Node Başlatma

### 1. Node'u Başlatın

```bash
sudo systemctl start arkhd
```

### 2. Logları İzleyin

```bash
sudo journalctl -fu arkhd -o cat
```

**Kısayol:** CTRL+C ile çıkabilirsiniz.

### 3. Node Durumunu Kontrol Edin

```bash
sudo systemctl status arkhd
```

### 4. Senkronizasyon Durumunu Kontrol Edin

```bash
arkhd status 2>&1 | jq .SyncInfo
```

**Önemli:** `catching_up: false` görene kadar bekleyin. Bu, node'unuzun tamamen senkronize olduğu anlamına gelir.

Sürekli kontrol etmek için:

```bash
while true; do
  SYNC_INFO=$(arkhd status 2>&1 | jq .SyncInfo)
  LATEST_HEIGHT=$(echo $SYNC_INFO | jq -r .latest_block_height)
  CATCHING_UP=$(echo $SYNC_INFO | jq -r .catching_up)
  echo "Height: $LATEST_HEIGHT | Catching Up: $CATCHING_UP"
  sleep 5
done
```

---

## Cüzdan Oluşturma

### Yeni Cüzdan Oluşturma

```bash
arkhd keys add $WALLET
```

**Çıktı Örneği:**
```
- address: arkh1xxx...
  name: wallet
  pubkey: '{"@type":"/cosmos.crypto.secp256k1.PubKey","key":"xxx"}'
  type: local

**Important** write this mnemonic phrase in a safe place.
It is the only way to recover your account if you ever forget your password.

word1 word2 word3 ... word24
```

⚠️ **Çok Önemli:** Mnemonic kelimelerinizi güvenli bir yerde saklayın!

### Var Olan Cüzdanı Recover Etme

```bash
arkhd keys add $WALLET --recover
```

Mnemonic kelimelerinizi girmeniz istenecektir.

### Cüzdanları Listeleme

```bash
arkhd keys list
```

### Cüzdan Adresini Görüntüleme

```bash
arkhd keys show $WALLET -a
```

### Bakiye Kontrol Etme

```bash
arkhd query bank balances $(arkhd keys show $WALLET -a)
```

---

## Validator Oluşturma

⚠️ **Önemli:** Validator oluşturmadan önce:
1. Node tamamen senkronize olmalı (`catching_up: false`)
2. Cüzdanınızda yeterli token bulunmalı
3. Priv validator key'inizi yedeklemiş olmalısınız

### 1. Validator Anahtar Dosyasını Yedekleyin

```bash
cp $HOME/.arkh/config/priv_validator_key.json $HOME/priv_validator_key_backup.json
```

### 2. Validator Oluşturun

```bash
arkhd tx staking create-validator \
  --amount=1000000arkh \
  --pubkey=$(arkhd tendermint show-validator) \
  --moniker="$MONIKER" \
  --chain-id=$ARKH_CHAIN_ID \
  --commission-rate="0.10" \
  --commission-max-rate="0.20" \
  --commission-max-change-rate="0.01" \
  --min-self-delegation="1" \
  --gas="auto" \
  --gas-adjustment="1.5" \
  --gas-prices="0.0arkh" \
  --from=$WALLET
```

**Parametre Açıklamaları:**
- `amount`: Stake edilecek miktar (1 ARKH = 1000000 uarkh)
- `commission-rate`: Komisyon oranı (%10)
- `commission-max-rate`: Maksimum komisyon oranı (%20)
- `commission-max-change-rate`: Günlük maksimum değişim (%1)
- `min-self-delegation`: Minimum self delegation

### 3. Validator Bilgilerini Kontrol Edin

```bash
arkhd query staking validator $(arkhd keys show $WALLET --bech val -a)
```

### 4. Validator Durumunu Kontrol Edin

```bash
arkhd status 2>&1 | jq .ValidatorInfo
```

---

## Faydalı Komutlar

### Node Yönetimi

```bash
# Node'u durdur
sudo systemctl stop arkhd

# Node'u başlat
sudo systemctl start arkhd

# Node'u yeniden başlat
sudo systemctl restart arkhd

# Node durumu
sudo systemctl status arkhd

# Logları izle
sudo journalctl -fu arkhd -o cat

# Son 100 log
sudo journalctl -u arkhd -n 100
```

### Senkronizasyon Kontrol

```bash
# Senkronizasyon durumu
arkhd status 2>&1 | jq .SyncInfo

# Catching up kontrolü
arkhd status 2>&1 | jq .SyncInfo.catching_up

# Son blok yüksekliği
arkhd status 2>&1 | jq .SyncInfo.latest_block_height

# Peer sayısı
curl -s localhost:${ARKH_PORT}657/net_info | jq -r .result.n_peers
```

### Cüzdan İşlemleri

```bash
# Cüzdan listesi
arkhd keys list

# Cüzdan adresini göster
arkhd keys show $WALLET -a

# Cüzdan validator adresini göster
arkhd keys show $WALLET --bech val -a

# Bakiye kontrol
arkhd query bank balances $(arkhd keys show $WALLET -a)

# Token gönder
arkhd tx bank send $WALLET <RECEIVER_ADDRESS> 1000000arkh \
  --chain-id=$ARKH_CHAIN_ID \
  --gas=auto \
  --gas-adjustment=1.5 \
  --gas-prices=0.0arkh
```

### Staking İşlemleri

```bash
# Delegate
arkhd tx staking delegate <VALIDATOR_ADDRESS> 1000000arkh \
  --from=$WALLET \
  --chain-id=$ARKH_CHAIN_ID \
  --gas=auto \
  --gas-adjustment=1.5 \
  --gas-prices=0.0arkh

# Redelegate
arkhd tx staking redelegate <SOURCE_VALIDATOR> <DEST_VALIDATOR> 1000000arkh \
  --from=$WALLET \
  --chain-id=$ARKH_CHAIN_ID \
  --gas=auto \
  --gas-adjustment=1.5 \
  --gas-prices=0.0arkh

# Unbond
arkhd tx staking unbond <VALIDATOR_ADDRESS> 1000000arkh \
  --from=$WALLET \
  --chain-id=$ARKH_CHAIN_ID \
  --gas=auto \
  --gas-adjustment=1.5 \
  --gas-prices=0.0arkh

# Ödülleri çek
arkhd tx distribution withdraw-all-rewards \
  --from=$WALLET \
  --chain-id=$ARKH_CHAIN_ID \
  --gas=auto \
  --gas-adjustment=1.5 \
  --gas-prices=0.0arkh

# Komisyonları çek (validator için)
arkhd tx distribution withdraw-rewards $(arkhd keys show $WALLET --bech val -a) \
  --commission \
  --from=$WALLET \
  --chain-id=$ARKH_CHAIN_ID \
  --gas=auto \
  --gas-adjustment=1.5 \
  --gas-prices=0.0arkh
```

### Validator İşlemleri

```bash
# Validator bilgileri
arkhd query staking validator $(arkhd keys show $WALLET --bech val -a)

# Tüm validator'ları listele
arkhd query staking validators

# Validator'u düzenle
arkhd tx staking edit-validator \
  --new-moniker="$MONIKER" \
  --identity="YOUR_KEYBASE_ID" \
  --website="https://your-website.com" \
  --details="Your validator description" \
  --chain-id=$ARKH_CHAIN_ID \
  --from=$WALLET \
  --gas=auto \
  --gas-adjustment=1.5 \
  --gas-prices=0.0arkh

# Jailed validator'u kurtarma
arkhd tx slashing unjail \
  --from=$WALLET \
  --chain-id=$ARKH_CHAIN_ID \
  --gas=auto \
  --gas-adjustment=1.5 \
  --gas-prices=0.0arkh
```

### Governance İşlemleri

```bash
# Proposal'ları listele
arkhd query gov proposals

# Proposal detayları
arkhd query gov proposal <PROPOSAL_ID>

# Oy ver
arkhd tx gov vote <PROPOSAL_ID> yes \
  --from=$WALLET \
  --chain-id=$ARKH_CHAIN_ID \
  --gas=auto \
  --gas-adjustment=1.5 \
  --gas-prices=0.0arkh
```

---

## Sorun Giderme

### Peer Bağlantı Problemi

```bash
# Addrbook'u güncelle
rm $HOME/.arkh/config/addrbook.json
wget -O $HOME/.arkh/config/addrbook.json https://raw.githubusercontent.com/Edsny1/Arkhadian-Mainnet-Setup/refs/heads/Edsny/addrbook.json

# Node'u yeniden başlat
sudo systemctl restart arkhd
```

### Senkronizasyon Problemi

```bash
# State sync'i tekrar uygula (yukarıdaki adımları tekrar edin)
# Veya snapshot kullanın (daha hızlı)
```

### Disk Dolma Problemi

```bash
# Mevcut boyutu kontrol et
du -sh $HOME/.arkh/data

# Pruning ayarlarını sıkılaştır
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"100\"/" $HOME/.arkh/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"10\"/" $HOME/.arkh/config/app.toml

# Node'u yeniden başlat
sudo systemctl restart arkhd
```

### Node Başlamıyor

```bash
# Logları detaylı incele
sudo journalctl -u arkhd -n 200 --no-pager

# Binary'yi kontrol et
which arkhd
arkhd version

# Service dosyasını kontrol et
cat /etc/systemd/system/arkhd.service

# İzinleri kontrol et
ls -la $HOME/.arkh/config/
ls -la $HOME/.arkh/cosmovisor/
```

---

## Node'u Tamamen Kaldırma

```bash
# Node'u durdur
sudo systemctl stop arkhd
sudo systemctl disable arkhd

# Service dosyasını sil
sudo rm /etc/systemd/system/arkhd.service
sudo systemctl daemon-reload

# Node dosyalarını sil
rm -rf $HOME/.arkh
rm -rf $HOME/arkh-blockchain
rm -rf $HOME/go/bin/arkhd

# Cosmovisor'u kaldır (opsiyonel)
rm -rf $HOME/go/bin/cosmovisor
```

---

## Güvenlik Tavsiyeleri

1. **Firewall Kurun:**
```bash
sudo apt install ufw
sudo ufw allow ssh
sudo ufw allow ${ARKH_PORT}656/tcp  # P2P
sudo ufw enable
```

2. **Fail2ban Kurun:**
```bash
sudo apt install fail2ban
```

3. **SSH Key Authentication:**
- Password authentication'ı devre dışı bırakın
- Sadece SSH key ile erişime izin verin

4. **Backup:**
- `priv_validator_key.json` dosyasını yedekleyin
- Mnemonic kelimelerinizi güvenli bir yerde saklayın

5. **Monitoring:**
- Prometheus ve Grafana kurun
- Alert sistemi oluşturun

---

## Faydalı Linkler

- **GitHub**: https://github.com/vincadian/arkh-blockchain


---

## Destek

Sorun yaşıyorsanız:
1. Bu kılavuzu tekrar kontrol edin
2. Logları inceleyin
3. Discord/Telegram kanallarından destek alın
4. GitHub'da issue açın

---

**Hazırlayan:** OshVanK  
**Son Güncelleme:** Aralık 2025  
**Versiyon:** 2.0.0  
**Chain ID:** arkh
