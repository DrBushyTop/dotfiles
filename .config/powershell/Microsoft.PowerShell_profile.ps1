oh-my-posh init pwsh --config "/opt/homebrew/Cellar/oh-my-posh/7.79.1/themes/atomic.omp.json" | Invoke-Expression
Import-Module posh-git

Set-PSReadLineOption -PredictionSource HistoryAndPlugin

Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward

Set-Alias -Name k -Value kubectl
Import-Module -Name PSKubectlCompletion
Register-KubectlCompletion

Set-Alias -Name g -Value git