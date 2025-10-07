oh-my-posh init pwsh --config "/opt/homebrew/Cellar/oh-my-posh/27.1.2/themes/catppuccin_macchiato.omp.json" | Invoke-Expression
Import-Module posh-git

Set-PSReadLineOption -PredictionSource HistoryAndPlugin

Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward

Set-Alias -Name k -Value kubectl
Import-Module -Name PSKubectlCompletion
Register-KubectlCompletion

Set-Alias -Name g -Value git

$env:CARAPACE_BRIDGES = 'zsh,fish,bash,inshellisense' # optional
Set-PSReadLineOption -Colors @{ "Selection" = "`e[7m" }
Set-PSReadlineKeyHandler -Key Tab -Function MenuComplete
carapace _carapace | Out-String | Invoke-Expression
