# Arkhadian Network - Mainnet Kurulum Rehberi

<div align="center">

```
 _______  _______                    _______  _        _       
(  ___  )(  ____ \|\     /||\     /|(  ___  )( (    /|| \    /\ 
| (   ) || (    \/| )   ( || )   ( || (   ) ||  \  ( ||  \  / / 
| |   | || (_____ | (___) || |   | || (___) ||   \ | ||  (_/ /  
| |   | |(_____  )|  ___  |( (   ) )|  ___  || (\ \) ||   _ (   
| |   | |      ) || (   ) | \ \_/ / | (   ) || | \   ||  ( \ \  
| (___) |/\____) || )   ( |  \   /  | )   ( || )  \  ||  /  \ \ 
(_______)\_______)|/     \|   \_/   |/     \||/    )_)|_/    \_\\
```

**Arkhadian Blockchain - Mainnet Node Kurulum Kılavuzu**

[![GitHub](https://img.shields.io/badge/GitHub-Arkhadian-blue?logo=github)](https://github.com/vincadian/arkh-blockchain)
[![Chain ID](https://img.shields.io/badge/Chain%20ID-arkh-green)]()
[![Version](https://img.shields.io/badge/Version-v2.0.0-orange)]()

**Hazırlayan: OshVanK**

</div>

---

## 📋 İçerik

- [Hızlı Kurulum](#-hızlı-kurulum-otomatik)
- [Manuel Kurulum](#-manuel-kurulum)
- [Sistem Gereksinimleri](#-sistem-gereksinimleri)
- [Kurulum Sonrası İşlemler](#-kurulum-sonrası-işlemler)
- [Faydalı Komutlar](#-faydalı-komutlar)
- [Sorun Giderme](#-sorun-giderme)
- [Destek](#-destek)

---

## 🚀 Hızlı Kurulum (Otomatik)

### Tek Komut ile Kurulum

```bash
wget -qO install.sh https://raw.githubusercontent.com/Edsny1/Arkhadian-Mainnet-Setup/Edsny/install.sh && chmod +x install.sh && ./install.sh
```

Bu script otomatik olarak:
- ✅ Sistem güncellemesi
- ✅ Gerekli paketlerin kurulumu
- ✅ Go kurulumu (yoksa)
- ✅ Cosmovisor kurulumu
- ✅ Binary derleme ve kurulum
- ✅ Node yapılandırması
- ✅ Genesis ve addrbook kurulumu
- ✅ State Sync yapılandırması
- ✅ Systemd service oluşturma

**Kurulum Sırasında İstenecek Bilgiler:**
- Moniker (Node adınız)
- Wallet adı (varsayılan: wallet)
- Port yapılandırması (varsayılan veya özel)
- State Sync kullanımı (önerilen: evet)

---

## 📖 Manuel Kurulum

Detaylı manuel kurulum adımları için: **[MANUAL_INSTALLATION.md](MANUAL_INSTALLATION.md)**

Manuel kurulum, her adımı kontrol etmek ve özelleştirmek isteyenler için idealdir.

---

## 💻 Sistem Gereksinimleri

### Minimum Gereksinimler

| Bileşen | Minimum |
|---------|---------|
| CPU | 4 Cores |
| RAM | 8 GB |
| Disk | 200 GB SSD |
| Bant Genişliği | 100 Mbps |
| İşletim Sistemi | Ubuntu 20.04+ |

### Önerilen Gereksinimler

| Bileşen | Önerilen |
|---------|----------|
| CPU | 8 Cores |
| RAM | 16 GB |
| Disk | 500 GB NVMe SSD |
| Bant Genişliği | 1 Gbps |
| İşletim Sistemi | Ubuntu 22.04 LTS |

---

## 🎯 Kurulum Sonrası İşlemler

### 1. Node'u Başlatın

```bash
sudo systemctl start arkhd
```

### 2. Logları İzleyin

```bash
sudo journalctl -fu arkhd -o cat
```

### 3. Senkronizasyon Durumunu Kontrol Edin

```bash
arkhd status 2>&1 | jq .SyncInfo
```

`catching_up: false` olana kadar bekleyin.

### 4. Cüzdan Oluşturun

**Yeni Cüzdan:**
```bash
arkhd keys add wallet
```

**Var Olan Cüzdanı Recover Edin:**
```bash
arkhd keys add wallet --recover
```

⚠️ **Önemli:** Mnemonic kelimelerinizi güvenli bir yerde saklayın!

### 5. Validator Oluşturun

Node tamamen senkronize olduktan sonra:

```bash
arkhd tx staking create-validator \
  --amount=1000000arkh \
  --pubkey=$(arkhd tendermint show-validator) \
  --moniker="YOUR_MONIKER" \
  --chain-id=arkh \
  --commission-rate="0.10" \
  --commission-max-rate="0.20" \
  --commission-max-change-rate="0.01" \
  --min-self-delegation="1" \
  --gas="auto" \
  --gas-adjustment="1.5" \
  --gas-prices="0.0arkh" \
  --from=wallet \
  --fees=5000arkh \
  --gas=200000
```

---

## 🔧 Faydalı Komutlar

### Node Yönetimi

```bash
# Node durumu
sudo systemctl status arkhd

# Node'u başlat
sudo systemctl start arkhd

# Node'u durdur
sudo systemctl stop arkhd

# Node'u yeniden başlat
sudo systemctl restart arkhd

# Logları izle
sudo journalctl -fu arkhd -o cat
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
curl -s localhost:26657/net_info | jq -r .result.n_peers
```

### Cüzdan İşlemleri

```bash
# Cüzdan listesi
arkhd keys list

# Bakiye kontrolü
arkhd query bank balances $(arkhd keys show wallet -a)

# Token gönderme
arkhd tx bank send wallet <RECEIVER_ADDRESS> 1000000arkh \
  --chain-id=arkh \
  --gas=auto \
  --gas-adjustment=1.5 \
  --gas-prices=0.0arkh
```

### Validator İşlemleri

```bash
# Validator bilgileri
arkhd query staking validator $(arkhd keys show wallet --bech val -a)

# Validator durumu
arkhd status 2>&1 | jq .ValidatorInfo

# Ödülleri çekme
arkhd tx distribution withdraw-all-rewards \
  --from=wallet \
  --chain-id=arkh \
  --gas=auto \
  --gas-adjustment=1.5 \
  --gas-prices=0.0arkh

# Jailed validator'u kurtarma
arkhd tx slashing unjail \
  --from=wallet \
  --chain-id=arkh \
  --gas=auto \
  --gas-adjustment=1.5 \
  --gas-prices=0.0arkh
```

---

## 🐛 Sorun Giderme

### Node Başlamıyor

```bash
# Logları kontrol edin
sudo journalctl -u arkhd -n 100 --no-pager

# Binary'yi kontrol edin
which arkhd
arkhd version

# İzinleri kontrol edin
ls -la ~/.arkh/
```

### Peer Bulunamıyor

```bash
# Addrbook'u güncelleyin
rm ~/.arkh/config/addrbook.json
wget -O ~/.arkh/config/addrbook.json https://raw.githubusercontent.com/Edsny1/Arkhadian-Mainnet-Setup/refs/heads/Edsny/addrbook.json

# Node'u yeniden başlatın
sudo systemctl restart arkhd
```

### Senkronizasyon Çok Yavaş

State Sync kullanın veya snapshot'tan restore edin. Detaylı bilgi için manual kurulum kılavuzuna bakın.

### Disk Doldu

```bash
# Pruning ayarlarını sıkılaştırın
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"100\"/" ~/.arkh/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"10\"/" ~/.arkh/config/app.toml

# Node'u yeniden başlatın
sudo systemctl restart arkhd
```

---

## 📊 Port Yapılandırması

### Varsayılan Portlar (26xxx)

| Servis | Port |
|--------|------|
| P2P | 26656 |
| RPC | 26657 |
| gRPC | 26090 |
| API | 26317 |
| Prometheus | 26660 |

### Özel Port Kullanımı

Kurulum sırasında özel port seçerseniz (örn: 27), tüm portlar otomatik olarak ayarlanır (27656, 27657, vb.)

---

## 🔐 Güvenlik Tavsiyeleri

1. **Firewall Yapılandırması**
   ```bash
   sudo ufw allow ssh
   sudo ufw allow 26656/tcp
   sudo ufw enable
   ```

2. **SSH Güvenliği**
   - Key-based authentication kullanın
   - Root login'i devre dışı bırakın
   - Varsayılan SSH portunu değiştirin

3. **Backup**
   - `~/.arkh/config/priv_validator_key.json` dosyasını yedekleyin
   - Mnemonic kelimelerinizi güvenli bir yerde saklayın

4. **Monitoring**
   - Node durumunu düzenli kontrol edin
   - Prometheus ve Grafana kurun
   - Alert sistemi oluşturun

5. **Updates**
   - Sisteminizi güncel tutun
   - Yeni node versiyonlarını takip edin

---

## 📁 Dosyalar ve Dizinler

```
~/.arkh/
├── config/
│   ├── app.toml              # Uygulama yapılandırması
│   ├── config.toml           # Node yapılandırması
│   ├── genesis.json          # Genesis dosyası
│   ├── addrbook.json         # Peer adresleri
│   └── priv_validator_key.json  # Validator anahtarı (ÖNEMLİ!)
├── data/                     # Blockchain verisi
└── cosmovisor/
    ├── genesis/
    │   └── bin/
    │       └── arkhd         # Genesis binary
    └── upgrades/             # Upgrade binary'leri
```

---

## 🔄 Cosmovisor Upgrade

Cosmovisor, chain upgrade'leri otomatik olarak yönetir.

### Yeni Versiyon için Hazırlık

```bash
# Yeni versiyonu derleyin
cd ~/arkh-blockchain
git fetch
git checkout <NEW_VERSION>
go build -o arkhd ./cmd/arkhd

# Upgrade dizini oluşturun
mkdir -p ~/.arkh/cosmovisor/upgrades/<UPGRADE_NAME>/bin

# Binary'yi kopyalayın
cp arkhd ~/.arkh/cosmovisor/upgrades/<UPGRADE_NAME>/bin/
```

Upgrade proposal geçtiğinde Cosmovisor otomatik olarak yeni versiyona geçiş yapacaktır.

---

## 🌐 Faydalı Linkler

### Resmi Kaynaklar
- **GitHub**: https://github.com/vincadian/arkh-blockchain
- **Website**: [Arkhadian Website]
- **Documentation**: [Documentation Link]

### Topluluk
- **Discord**: [Discord Invite]
- **Telegram**: [Telegram Group]
- **Twitter**: [Twitter Profile]

### Explorer & Tools
- **Explorer**: [Block Explorer]
- **API**: [API Endpoint]
- **RPC**: https://arkh.rpc.m.anode.team:443

---

## 🤝 Katkıda Bulunma

Bu repo topluluk katkılarına açıktır. Pull request göndermekten çekinmeyin!

### Katkı Süreci
1. Bu repo'yu fork edin
2. Yeni bir branch oluşturun (`git checkout -b feature/amazing-feature`)
3. Değişikliklerinizi commit edin (`git commit -m 'Add amazing feature'`)
4. Branch'inizi push edin (`git push origin feature/amazing-feature`)
5. Pull Request açın

---

## 📞 Destek

Sorun yaşıyorsanız:

1. **Dokümantasyonu Kontrol Edin**
   - [MANUAL_INSTALLATION.md](MANUAL_INSTALLATION.md) - Detaylı kurulum kılavuzu
   - [Sorun Giderme](#-sorun-giderme) - Yaygın problemler ve çözümleri

2. **Topluluk Desteği**
   - Discord kanalından yardım alın
   - Telegram grubuna sorun

3. **Issue Açın**
   - GitHub'da issue açabilirsiniz
   - Sorununuzu detaylı açıklayın

---

## 📜 Sürüm Geçmişi

### v2.0.0 (Mevcut)
- İlk mainnet sürümü
- Cosmovisor entegrasyonu
- State Sync desteği
- Otomatik kurulum scripti

---

## ⚖️ Lisans

MIT License - Detaylar için [LICENSE](LICENSE) dosyasına bakın.

---

## 🙏 Teşekkürler

- Arkhadian Core Team
- Cosmos SDK Team
- Tüm topluluk katkıcılarına

---

<div align="center">

**Arkhadian Network**

Hazırlayan: **OshVanK**

Son Güncelleme: Aralık 2025

[![GitHub stars](https://img.shields.io/github/stars/Edsny1/Arkhadian-Mainnet-Setup?style=social)]()
[![GitHub forks](https://img.shields.io/github/forks/Edsny1/Arkhadian-Mainnet-Setup?style=social)]()

</div>
