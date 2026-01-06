#!/bin/bash
set -e

echo -e "\n################################################################"
echo "#                                                              #"
echo "#                     ***SS training***                        #"
echo "#                  SonarQube Installation                      #"
echo "#                                                              #"
echo "################################################################"

# -------------------------------
# 1. Install required packages
# -------------------------------
echo -e "\n***** Installing necessary packages"
sudo apt-get update -y > /dev/null 2>&1
sudo apt-get install -y openjdk-17-jre unzip wget curl > /dev/null 2>&1
echo "            -> Done"

# -------------------------------
# 2. Kernel & limits (MANDATORY)
# -------------------------------
echo "***** Configuring kernel parameters"
sudo sysctl -w vm.max_map_count=262144
sudo sysctl -w fs.file-max=65536

sudo tee -a /etc/sysctl.conf > /dev/null <<EOF
vm.max_map_count=262144
fs.file-max=65536
EOF

sudo sysctl -p > /dev/null
echo "            -> Done"

# -------------------------------
# 3. Fetch latest SonarQube version
# -------------------------------
echo "***** Fetching latest SonarQube version"
LATEST_VERSION=$(curl -s https://api.github.com/repos/SonarSource/sonarqube/releases/latest | grep -oP '"tag_name": "\K[^"]+')

if [ -z "$LATEST_VERSION" ]; then
    echo "Failed to fetch SonarQube version"
    exit 1
fi

SONAR_ZIP="sonarqube-${LATEST_VERSION}.zip"
SONAR_URL="https://binaries.sonarsource.com/Distribution/sonarqube/${SONAR_ZIP}"

echo "            -> Latest version: ${LATEST_VERSION}"

# -------------------------------
# 4. Download & Extract
# -------------------------------
echo "***** Downloading SonarQube"
cd /opt
sudo rm -rf sonarqube sonarqube-*
sudo wget -q ${SONAR_URL}
sudo unzip -q ${SONAR_ZIP}
sudo mv sonarqube-${LATEST_VERSION} sonarqube
sudo rm -f ${SONAR_ZIP}
echo "            -> Done"

# -------------------------------
# 5. Ownership (NON-ROOT)
# -------------------------------
echo "***** Setting ownership to ubuntu user"
sudo chown -R ubuntu:ubuntu /opt/sonarqube
echo "            -> Done"

# -------------------------------
# 6. Increase limits for ubuntu
# -------------------------------
echo "***** Configuring user limits"
sudo tee -a /etc/security/limits.conf > /dev/null <<EOF
ubuntu soft nofile 65536
ubuntu hard nofile 65536
ubuntu soft nproc 4096
ubuntu hard nproc 4096
EOF

# -------------------------------
# 7. Start

