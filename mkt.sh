#!/bin/bash
set -e

# HTTP/HTTPS代理
# eg. PROXY="http_proxy=xxx.xxx.xxx.xxx:xxxx"
PROXY=""

# 当前路径
CUR_PATH="$(pwd)"

# 源文件存放路径
STORE_PATH="$CUR_PATH/store"

# 安装路径
INSTALL_PREFIX="$CUR_PATH/thirdparty"

install_dependencies()
{
    sudo apt-get install build-essential gcc g++ make autoconf automake libtool zip unzip
    sudo apt-get install cmake git libgtk2.0-dev pkg-config libavcodec-dev libavformat-dev libswscale-dev
}

w_get()
{
    local url=$1
    if [ -z "$PROXY" ]; then
        wget -c -t 100 -T 30 "$url"
    else
        wget -c -t 100 -T 30 -e "$PROXY" "$url"
    fi
}

pre_mk()
{
    if [ ! -d "$STORE_PATH" ]; then
        mkdir "$STORE_PATH"
    fi

    if [ ! -d "$INSTALL_PREFIX" ]; then
        mkdir "$STORE_PATH"
    fi
    install_dependencies
}

# 从url中获取文件名
get_filename_from_url()
{
    local url="$1"
    echo "${url##*/}"
}

# 下载并解压，返回文件夹名称
down_and_unzip()
{
    if [ ! -d "$STORE_PATH" ]; then
        mkdir "$STORE_PATH"
    fi
    cd "$STORE_PATH"
    local url="$1"
    local filename
    filename="$(get_filename_from_url "$url")"
    if [ ! -e "$filename" ]; then
        w_get "$url"
    fi
    tar -zxvf "$filename" >> tmp.log
    local tmp
    tmp=$(tail -n 1 tmp.log)
    rm tmp.log
    local prefix=${tmp%%/*}
    cd "$STORE_PATH/$prefix"
}

mk_boost()
{
    local url="https://boostorg.jfrog.io/artifactory/main/release/1.76.0/source/boost_1_76_0.tar.gz"
    down_and_unzip "$url"
    ./bootstrap.sh --prefix="$INSTALL_PREFIX"
    ./b2 install
}

mk_glog()
{
    local url="https://github.com/google/glog/archive/refs/tags/v0.5.0.tar.gz"
    down_and_unzip "$url"
    cmake -D CMAKE_BUILD_TYPE=RELEASE -D CMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" .
    make -j 2
    make install
}

mk_gtest()
{
    local url="https://github.com/google/googletest/archive/refs/tags/release-1.11.0.tar.gz"
    down_and_unzip "$url"
    cmake -D CMAKE_BUILD_TYPE=RELEASE -D CMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" .
    make -j 2
    make install
}

mk_protobuf()
{
    local url="https://github.com/protocolbuffers/protobuf/releases/download/v3.17.3/protobuf-cpp-3.17.3.tar.gz"
    down_and_unzip "$url"
    ./configure --prefix="$INSTALL_PREFIX"
    make -j 2
    make install
}

mk_cppzmq()
{
    local url="https://github.com/zeromq/libzmq/archive/refs/tags/v4.3.4.tar.gz"
    down_and_unzip "$url"
    if [ ! -d "zmqbuild" ]; then
        mkdir zmqbuild
    fi
    cd zmqbuild
    cmake -D CMAKE_BUILD_TYPE=RELEASE -D CMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" ..
    make -j 4
    make install

    local url="https://github.com/zeromq/cppzmq/archive/refs/tags/v4.7.1.tar.gz"
    down_and_unzip "$url"
    if [ ! -d "cppzmqbuild" ]; then
        mkdir cppzmqbuild
    fi
    cd cppzmqbuild
    cmake -D CMAKE_BUILD_TYPE=RELEASE -D CPPZMQ_BUILD_TESTS=OFF -D CMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" ..
    make -j 4
    make install
}

mk_rapidjson()
{
    local url="https://github.com/Tencent/rapidjson/archive/v1.1.0.tar.gz"
    down_and_unzip "$url"
    if [ ! -d "$INSTALL_PREFIX/include" ]; then
        mkdir "$INSTALL_PREFIX/include"
    fi
    if [ -d "$INSTALL_PREFIX/include/rapidjson" ]; then
        if [ -d "include/rapidjson" ]; then
            rm -rf "$INSTALL_PREFIX/include/rapidjson"
        fi
    fi
    mv "include/rapidjson" "$INSTALL_PREFIX/include"
}

mk_sqlite3()
{
    local url="https://www.sqlite.org/2021/sqlite-autoconf-3350500.tar.gz"
    down_and_unzip "$url"
    ./configure --prefix="$INSTALL_PREFIX"
    make && make install
}

get_options()
{
while getopts ":t:i:p:h" opt; do
        case "$opt" in
            t)
                if [ "$OPTARG" = "all" ]; then
                    pre_mk
                    mk_boost
                    mk_glog
                    mk_gtest
                    mk_protobuf
                    mk_cppzmq
                    mk_rapidjson
                    mk_sqlite3
                elif [ "$OPTARG" = "boost" ]; then
                    pre_mk
                    mk_boost
                elif [ "$OPTARG" = "glog" ]; then
                    pre_mk
                    mk_glog
                elif [ "$OPTARG" = "gtest" ]; then
                    pre_mk
                    mk_gtest
                elif [ "$OPTARG" = "protobuf" ]; then
                    pre_mk
                    mk_protobuf
                elif [ "$OPTARG" = "cppzmq" ]; then
                    pre_mk
                    mk_cppzmq
                elif [ "$OPTARG" = "rapidjson" ]; then
                    mk_rapidjson
                elif [ "$OPTARG" = "sqlite3" ]; then
                    pre_mk
                    mk_sqlite3
                else
                    echo "invalid optargs"   
                fi
            ;;
            i)
                INSTALL_PREFIX=$(cd "$OPTARG"; pwd)
                echo "INSTALL_PREFIX=$INSTALL_PREFIX"
            ;;
            p)
                PROXY=$OPTARG
                echo "PROXY=$PROXY"
            ;;
            h)
                echo "Usage: bash mkt.sh [-h] [-i prefix] [-p proxy] [-t all | boost | glog | gtest | protobuf | cppzmq | rapidjson | sqlite3]"
                echo "  Compile C++ third-party libaries"
                echo "  -i    cmake install prefix; if prefix is unspecified, assume ./thirdparty"
                echo "  -t    third-party library"
                echo "  -p    http/https proxy"
                exit 0
            ;;
            \?)
                echo "invalid options! $opt"
                exit 255
            ;;
        esac
    done
}

get_options "$@"

exit $?