# SUI

## SUI: install with fixed ports

### 1. Download
```
wget -O ~/sui-install.sh https://raw.githubusercontent.com/cyberomanov/sui-help/main/sui-install.sh && \
chmod u+x ~/sui-install.sh
```
### 2. Run
```
~/sui-install.sh
```

## SUI: auto-update-every-4-hours with fixed ports

### 1. Download
```
wget -O ~/sui-update.sh https://raw.githubusercontent.com/cyberomanov/sui-help/main/sui-update.sh && \
chmod u+x ~/sui-update.sh
```
### 2. Crontab
1. Open crontab editor:
```
crontab -e
```
2. Set a new rule:
```
# sui
10 */4 * * * bash ~/sui-update.sh >> ~/sui-update.log
```
3. After 4 hours check first logs:
```
cat ~/sui-update.log
```
