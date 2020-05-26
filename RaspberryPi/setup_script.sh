################################################################
## 
## This is the setup script that will install all components
## to make full BLE scanner out of a Raspberry Pi   
##
################################################################

## Step 1: Install necessary dependencies
sudo apt-get update
sudo apt-get install python3-pip git libglib2.0-dev

## Step 2: Setup directories

cd /home/pi
mkdir ble-scanner
cd ble-scanner
mkdir dependencies

## Step 3: Install patched bluepy version
cd dependencies
git clone https://github.com/Sn0wfreezeDev/bluepy.git
cd bluepy
sudo pip3 install .
sudo pip3 install zeroconf

## Step 4: Fetch the bluetooth script
cd ../..
wget https://gist.githubusercontent.com/Sn0wfreezeDev/73db035d16921dfa470fd0ed97a688f6/raw/49700f375422eecd651950746e6dc98dac3bc70a/blescanner.py

## Step 5: Prepare run at launch in background
echo "nohup python3 /home/pi/ble-scanner/blescanner.py -a > /home/pi/ble-scanner/ble_log.out &" | sudo tee -a  /etc/rc.local

## Step 6: Run now
sudo nohup python3  /home/pi/ble-scanner/blescanner.py -a > /home/pi/ble-scanner/ble_log.out &

