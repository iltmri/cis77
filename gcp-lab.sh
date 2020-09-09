#!/bin/bash
#GCP Cloud Lab
#source material https://0xbanana.com/blog/one-click-forensics-lab-in-the-cloud/
echo "******************************"
echo "*   CIS 77 GCP Lab Script    *"
echo "*   Run this within the GCP  *"
echo "*   console only.            *"
echo "******************************"

echo "Step 1: Networking"
gcloud compute networks create lab-net  --subnet-mode=custom --bgp-routing-mode=regional
gcloud compute networks subnets create safe  --range=192.168.0.0/24 --network=lab-net --region=us-east1
gcloud compute networks subnets create unsafe --range=192.168.128.0/29 --network=lab-net --region=us-east1

echo "Step 2: Remnux Install"
gcloud compute instances create sift-1 --tags=admin \
  --metadata startup-script='
#! /bin/bash
sudo su -
wget https://REMnux.org/remnux-cli
mv remnux-cli remnux
chmod +x remnux
mv remnux /usr/local/bin
remnux inatall --mode=cloud
  EOF'

echo "Step 3: Kali Install"
gcloud compute instances create kali-1 --tags=admin \
  --metadata startup-script='
  #! /bin/bash
sudo su -
export DEBIAN_FRONTEND=noninteractive
wget https://archive.kali.org/archive-key.asc -O /etc/apt/trusted.gpg.d/kali-archive-key.asc
echo "deb http://http.kali.org/kali kali-rolling main contrib non-free" >> /etc/apt/sources.list
apt-get update
apt-get install -yq kali-linux-default
  EOF'

echo "Step 4: Honeypot Install"
gcloud compute instances create honeypot-1 --tags=insecure \
  --metadata startup-script='
#! /bin/bash
sudo su -
# Clone the tpot repo
git clone https://github.com/telekom-security/tpotce.git

# installation instructions from repo
cd tpotce/iso/installer/
cp tpot.conf.dist tpot.conf
./install.sh --type=auto --conf=tpot.conf
reboot -n
EOF'

echo "Step 5: Bucket Creation"
gsutil mb gs://malicious

echo "Step 6: Firewall Rules Update"

gcloud compute firewall-rules create allow-ingress-admin-lab-net --direction=INGRESS --priority=1000 --network=lab-net --action=ALLOW --rules=tcp:22,tcp:80,tcp:443,icmp --source-ranges=0.0.0.0/0 --target-tags=admin
gcloud compute firewall-rules create allow-ingress-insecure-lab-net --direction=INGRESS --priority=1000 --network=lab-net --action=ALLOW --rules=all --source-ranges=0.0.0.0/0 --target-tags=insecure
echo "Ready for Work"
