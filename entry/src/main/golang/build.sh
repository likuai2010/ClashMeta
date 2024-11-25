#!/bin/bash

# 设置架构和目标
arch="arm64"  # 可选值：amd64, arm64
target="aarch64"  # 可选值：x86_64, aarch64
outdir="arm64-v8a"  # 可选值：x86_64, arm64-v8a

# 设置 OHOS_NATIVE_HOME
OHOS_NATIVE_HOME="/Volumes/MacintoshHD2/Applications/DevEco-Studio.app/Contents/sdk/default/openharmony/native"

# 基础编译标志
BASE_FLAGS="-Wno-error --sysroot=$OHOS_NATIVE_HOME/sysroot -fdata-sections -D__MUSL__ -ffunction-sections -funwind-tables -fstack-protector-strong -no-canonical-prefixes -fno-addrsig -Wa,--noexecstack -fPIC"

# 工具链路径
TOOLCHAIN="$OHOS_NATIVE_HOME/llvm"

# 设置环境变量
export CC="$TOOLCHAIN/bin/clang"
export CXX="$TOOLCHAIN/bin/clang++"
export LD="$TOOLCHAIN/bin/clang"
export CGO_AR="$TOOLCHAIN/bin/llvm-ar"
export GOASM="$TOOLCHAIN/bin/llvm-as"
export GOOS="android"
export GOARCH="$arch"
export GOARM=""
export CGO_ENABLED="1"
export CGO_CXXFLAGS=""
export CGO_CFLAGS="-Wno-error --target=$target-linux-ohos $BASE_FLAGS"
export CGO_LDFLAGS="-extld=$LD --sysroot=$OHOS_NATIVE_HOME/sysroot --target=$target-linux-ohos"

# 源文件和输出文件
sourceFile="./native"
outputFile="myapp.so"

# 构建命令，生成共享库
go build -buildmode c-shared -tags "foss cmfa with_gvisor ohos" -v -o $outputFile $sourceFile

# 检查编译结果
if [ -f "$outputFile" ]; then
    echo "success: $outputFile"
else
    echo "failed"
fi

# 复制生成的 .so 文件到指定目录
cp -f "$outputFile" "$PWD/../../../libs/$outdir/myapp.so"

# （可选）复制类型声明文件
# cp -f "$PWD/dist/index.d.ts" "$PWD/../src/main/cpp/types/hello/index.d.ts"