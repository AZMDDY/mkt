# Compile C++ third-party libaries

## Third-party libaries

- [x] boost_1.76.0
- [x] glog_0.5.0
- [x] gtest_1.11.0
- [x] protobuf_3.17.3
- [x] cppzmq
  - [x] libzmq_4.3.4
  - [x] cppzmq_4.7.1
- [x] rapidjson_1.1.0
- [x] sqlite3_3.35.5

## Usage

```shell
Usage: bash mkt.sh [-h] [-i prefix] [-p proxy] [-t all | boost | glog | gtest | protobuf | cppzmq | rapidjson | sqlite3 ]
  Compile C++ third-party libaries
  -i    cmake install prefix; if prefix is unspecified, assume ./thirdparty
  -t    third-party library
  -p    http/https proxy
  -v    version of libraries
```
example:

```shell
# compile glog:
bash mkt.sh -t glog
# set cmake install prefix path
bash mkt.sh -t glog -i ~/test
# set http/https proxy
bash mkt.sh -t glog -p "http_porxy=yourproxy.com:port"
bash mkt.sh -t glog -p "https_porxy=yourproxy.com:port"
```

```shell
# view version of libraries
bash mkt.sh -v
```

clean the directory:
```shell
ls | grep -v mkt.sh | grep -v README.md | xargs rm -r
```
