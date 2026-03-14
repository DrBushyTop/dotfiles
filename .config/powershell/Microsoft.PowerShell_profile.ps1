oh-my-posh init pwsh --config "/opt/homebrew/Cellar/oh-my-posh/29.6.1/themes/catppuccin_macchiato.omp.json" | Invoke-Expression
Import-Module posh-git

Set-PSReadLineOption -PredictionSource HistoryAndPlugin

Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward

Set-Alias -Name k -Value kubectl
Import-Module -Name PSKubectlCompletion
Register-KubectlCompletion

Set-Alias -Name g -Value git
Set-Alias -Name z -Value zoxide

$env:CARAPACE_BRIDGES = 'zsh,fish,bash,inshellisense' # optional
$env:XDG_CONFIG_HOME = "$HOME/.config" # Load carapace config from .config for both shells
$env:CARAPACE_TOOLTIP = '1'
Set-PSReadLineOption -Colors @{ "Selection" = "`e[7m" }
Set-PSReadlineKeyHandler -Key Tab -Function MenuComplete
carapace _carapace | Out-String | Invoke-Expression

# initialize zoxide (PS 7+: use pwd hook)
Invoke-Expression (& { (zoxide init --hook pwd powershell | Out-String) })
