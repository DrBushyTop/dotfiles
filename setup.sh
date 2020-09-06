# set non-interactive installation
export DEBIAN_FRONTEND=noninteractive

## update and install required packages
apt-get update
apt-get -y install --no-install-recommends apt-utils dialog 2>&1
apt-get install -y \
  curl \
  git \
  gnupg2 \
  jq \
  sudo \
  openssh-client \  
  less \
  iproute2 \
  procps \
  wget \
  apt-transport-https \
  lsb-release 

# Create a non-root user to use if preferred - see https://aka.ms/vscode-remote/containers/non-root-user.
groupadd --gid $USER_GID $USERNAME
useradd -s /bin/bash --uid $USER_UID --gid $USER_GID -m $USERNAME
echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME
chmod 0440 /etc/sudoers.d/$USERNAME

# Install Azure CLI
echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $(lsb_release -cs) main" > /etc/apt/sources.list.d/azure-cli.list
curl -sL https://packages.microsoft.com/keys/microsoft.asc | apt-key add - 2>/dev/null
apt-get update
apt-get install -y azure-cli;

# Install Jetbrains Mono font
wget https://download.jetbrains.com/fonts/JetBrainsMono-2.001.zip | unzip -d /usr/share/fonts
fc-cache -f -v

# Install & Configure Zsh
if [ "$INSTALL_ZSH" = "true" ]
then
    apt-get install -y \
    fonts-powerline \
    zsh

    chsh -s /usr/bin/zsh $USERNAME
    wget https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh -O - | zsh
    git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git
    echo "source ${(q-)PWD}/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" >> ${ZDOTDIR:-$HOME}/.zshrc
fi

# Cleanup
apt-get autoremove -y
apt-get autoremove -y
rm -rf /var/lib/apt/lists/*