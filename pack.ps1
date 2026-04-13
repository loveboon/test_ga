# 定义下载 URL 和路径变量
$CacheDir = "$PSScriptRoot\cache"
$UrlWitchCachePath = @{
  "https://github.com/AdguardTeam/AdGuardHome/releases/latest/download/AdGuardHome_linux_arm64.tar.gz" = "$CacheDir\AdGuardHome_linux_arm64.tar.gz"
  "https://github.com/AdguardTeam/AdGuardHome/releases/latest/download/AdGuardHome_linux_armv7.tar.gz" = "$CacheDir\AdGuardHome_linux_armv7.tar.gz"
}

# 创建缓存目录
if (-Not (Test-Path -Path $CacheDir)) {
  Write-Host "Creating cache directory..."
  New-Item -Path $CacheDir -ItemType Directory
}

# 下载文件，有缓存时不再下载
Write-Host "Downloading AdGuardHome..."
foreach ($url in $UrlWitchCachePath.Keys) {
  $CachePath = $UrlWitchCachePath[$url]
  if (-Not (Test-Path -Path $CachePath)) {
    Write-Host "Downloading $url..."
    Invoke-WebRequest -Uri $url -OutFile $CachePath
    if ($?) {
      Write-Host "Download completed successfully."
    }
    else {
      Write-Host "Download failed. Exiting..."
      exit 1
    }
  }
  else {
    Write-Host "File already exists in cache. Skipping download."
  }
}

# 使用 tar 解压文件
Write-Host "Extracting AdGuardHome..."
foreach ($url in $UrlWitchCachePath.Keys) {
  $CachePath = $UrlWitchCachePath[$url]
  if ($CachePath -match 'AdGuardHome_linux_(arm64|armv7)\.tar\.gz$') {
    $ExtractDir = "./cache/" + $matches[1]
  }
  else {
    throw "Invalid file path: $CachePath"
  }
  if (-Not (Test-Path -Path $ExtractDir)) {
    New-Item -Path $ExtractDir -ItemType Directory
    Write-Host "Extracting $CachePath..."
    tar -xzf $CachePath -C $ExtractDir
    if ($?) {
      Write-Host "Extraction completed successfully."
    }
    else {
      Write-Host "Extraction failed"
      exit 1
    }
  }
}

Get-Content "module\module.prop" | ForEach-Object {
    if ($_ -match "^\s*([^=]+)=(.*)$") {
        Set-Variable -Name $matches[1].Trim() -Value $matches[2].Trim()
    }
}

# 给项目打包，使用 7-Zip 压缩 zip
Write-Host "Packing FuckAD..."
$FuckADPath = "$CacheDir\FuckAD_v${version}.zip"
$OutputPathArm64 = "$CacheDir\FuckAD_AdGuardHome_arm64_v${version}.zip"
$OutputPathArmv7 = "$CacheDir\FuckAD_AdGuardHome_armv7_v${version}.zip"
if (Test-Path -Path $FuckADPath) {
  Remove-Item -Path $FuckADPath
}
if (Test-Path -Path $OutputPathArm64) {
  Remove-Item -Path $OutputPathArm64
}
if (Test-Path -Path $OutputPathArmv7) {
  Remove-Item -Path $OutputPathArmv7
}

# 设置项目根目录
$ProjectRoot = "$PSScriptRoot"
$env:PATH += ";C:\Program Files\7-Zip"

# pack FuckAD Module
cd module
7z a -tzip "$FuckADPath" ".\*"
cd ..

# pack arm64
7z a -tzip "$OutputPathArm64" "$CacheDir\arm64\AdGuardHome\AdGuardHome"
7z rn $OutputPathArm64 "AdGuardHome" "AdGuardHome/bin/AdGuardHome"

7z a -tzip "$OutputPathArm64" "$ProjectRoot\AdGuardHome"

# pack armv7
7z a -tzip "$OutputPathArmv7" "$CacheDir\armv7\AdGuardHome\AdGuardHome"
7z rn $OutputPathArmv7 "AdGuardHome" "AdGuardHome/bin/AdGuardHome"
7z a -tzip "$OutputPathArmv7" "$ProjectRoot\AdGuardHome"

Write-Host "Packing completed successfully."