
$OHOS_NATIVE_HOME="G:/huawei/SDK/HarmonyOS-NEXT-DB1/openharmony/native"
$BASE_FLAGS="-Wno-error --sysroot=$OHOS_NATIVE_HOME/sysroot -fdata-sections -D__MUSL__ -ffunction-sections -funwind-tables -fstack-protector-strong -no-canonical-prefixes -fno-addrsig -Wa,--noexecstack -fPIC"
$TOOLCHAIN="$OHOS_NATIVE_HOME/llvm"

$env:CC = "$TOOLCHAIN/bin/clang "
$env:CXX= "$TOOLCHAIN/bin/clang++"
$env:LD = "$TOOLCHAIN/bin/clang"
$env:CGO_AR= "$TOOLCHAIN/bin/llvm-ar"
$CGO_AR= "$TOOLCHAIN/bin/llvm-ar"
$env:GOASM= "$TOOLCHAIN/bin/llvm-as"

$env:GOOS = "android"
$env:GOARCH = "arm64" # amd64 386 arm arm64
$env:GOARM = "";
$env:CGO_ENABLED = "1"
$env:CGO_CXXFLAGS=""
$env:CGO_CFLAGS = "-Wno-error --target=aarch64-linux-ohos  $BASE_FLAGS  "
$env:CGO_LDFLAGS = "-extld=$env:LD --sysroot=$OHOS_NATIVE_HOME/sysroot --target=aarch64-linux-ohos"

$sourceFile = "./native"
$outputFile = "myapp.so"
# 压缩so
# -trimpath -ldflags="-s -w"
go build -buildmode c-shared -tags "foss cmfa with_gvisor ohos"  -v -o $outputFile $sourceFile

# 检查编译结果
if (Test-Path $outputFile) {
    Write-Host "success: $outputFile"
} else {
    Write-Host "failed"
}
Copy-Item -Force "$PSScriptRoot\myapp.so" "$PSScriptRoot\..\..\..\libs\arm64-v8a\myapp.so"
#Copy-Item -Force "$PSScriptRoot\dist\index.d.ts" "$PSScriptRoot\..\src\main\cpp\types\hello\index.d.ts"