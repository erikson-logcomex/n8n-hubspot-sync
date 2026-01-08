# Encontrar workflow faltante
$n8nIds = @(
    "kwLVbguMZ5DRT8y3", "yYQlLG9Vzgn9Wwqa", "wi4DtlBmFMdhf1wH", "EkvVZZKAx9oOT4wq", 
    "BJCkK1ZYtRFc6OHe", "3d5XDqg3jL4cFh6q", "255mOU4cp7JMmVHp", "SClbecXQfg7tJDAZ",
    "vdg5HZSbMJwwPYD4", "WBTunruPYkX7jJaA", "zDIH0ZEN0FQlEqBU", "VuGvuDbhh6HvB9Aa",
    "aQbmPVxy4kCfKOpr", "XL0ICZZM3oKmB4ZI", "0An63ict0sFPi1cz", "sgbhBkyDHCUfvdHy",
    "ra8MPMqAd09DZnPo", "edaSCh0Wh45ZEaNG", "WisqcYsanfOiYcL9", "yf9AMwZVeC7bSGR6",
    "htanZgc0PdBahWu6", "6JpBbUMyYg759BWh", "8WGJmvZ9fq8eERwE", "egWL3bsVvXh4KYmr",
    "FX3jgBa6of6Ee8FK"
)

$localFiles = Get-ChildItem workflows/*.json | ForEach-Object { $_.Name }

Write-Host "Workflows no n8n: $($n8nIds.Count)"
Write-Host "Workflows locais: $($localFiles.Count)"

foreach ($id in $n8nIds) {
    $found = $localFiles | Where-Object { $_ -like "*$id*" }
    if (-not $found) {
        Write-Host "FALTANDO: $id" -ForegroundColor Red
    }
}
