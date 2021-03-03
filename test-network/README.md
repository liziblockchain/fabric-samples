## Running the test network

You can use the `./network.sh` script to stand up a simple Fabric test network. The test network has two peer organizations with one peer each and a single node raft ordering service. You can also use the `./network.sh` script to create channels and deploy chaincode. For more information, see [Using the Fabric test network](https://hyperledger-fabric.readthedocs.io/en/latest/test_network.html). The test network is being introduced in Fabric v2.0 as the long term replacement for the `first-network` sample.

Before you can deploy the test network, you need to follow the instructions to [Install the Samples, Binaries and Docker Images](https://hyperledger-fabric.readthedocs.io/en/latest/install.html) in the Hyperledger Fabric documentation.

## test-network

- kvn_start.sh  这个文件就是原始的例子，只不过把deploy chaincode的代码提取出来意义列举而已
- kvn_first_app.sh 这个文件是从下面的链接开始的例子代码
https://github.com/hyperledger/fabric-contract-api-go/tree/master/tutorials
  chaincode 代码位于 ./chaincode/go/ folder
- monitor.sh 是启动监听docker log的命令
  - ./monitor.sh up
  - ./monitor.sh down

tested on Fabric V2.2.1

