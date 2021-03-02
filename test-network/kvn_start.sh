#!/bin/bash

set -x

function buildCerts()
{
  export FABRIC_CFG_PATH=${PWD}/configtx

  rm -Rf organizations/peerOrganizations && rm -Rf organizations/ordererOrganizations
  # Create Organization crypto material using cryptogen or CAs
  cryptogen generate --config=./organizations/cryptogen/crypto-config-org1.yaml --output="organizations"
  cryptogen generate --config=./organizations/cryptogen/crypto-config-org2.yaml --output="organizations"
  cryptogen generate --config=./organizations/cryptogen/crypto-config-orderer.yaml --output="organizations"

  # Generate orderer system channel genesis block.
  configtxgen -profile TwoOrgsOrdererGenesis -channelID system-channel -outputBlock ./system-genesis-block/genesis.block

  # echo "-------------------------------------- 11111"
  configtxgen -profile TwoOrgsChannel -outputCreateChannelTx ./channel-artifacts/mychannel.tx -channelID mychannel
  # echo "-------------------------------------- 22222"
}


#export PATH=${PWD}/../bin:$PATH

# start test network
function startTestNetwork()
{
  docker-compose -f docker/docker-compose-test-net.yaml up -d
}

# create channel
function createChannel_2()
{
  ./network.sh createChannel
}

# create channel
function createChannel()
{
  # export CHANNEL_NAME="mychannel"
  export FABRIC_CFG_PATH=${PWD}/../config
  # export BLOCKFILE="./channel-artifacts/${CHANNEL_NAME}.block"

  export CORE_PEER_TLS_ENABLED=true
  export ORDERER_CA=${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
  export PEER0_ORG1_CA=${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
  export PEER0_ORG2_CA=${PWD}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt
  export PEER0_ORG3_CA=${PWD}/organizations/peerOrganizations/org3.example.com/peers/peer0.org3.example.com/tls/ca.crt

  export CORE_PEER_LOCALMSPID="Org1MSP"
  export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_ORG1_CA
  export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
  export CORE_PEER_ADDRESS=localhost:7051

  peer channel create -o localhost:7050 -c mychannel --ordererTLSHostnameOverride orderer.example.com -f ./channel-artifacts/mychannel.tx --outputBlock ./channel-artifacts/mychannel.block --tls --cafile /work/fabric/fabric-samples/test-network/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem

}

function packageChainCode()
{
  cd ../asset-transfer-basic/chaincode-go
  GO111MODULE=on go mod vendor
  cd ../../test-network
  # export PATH=${PWD}/../bin:$PATH
  export FABRIC_CFG_PATH=$PWD/../config/
  peer lifecycle chaincode package basic.tar.gz --path ../asset-transfer-basic/chaincode-go/ --lang golang --label basic_1.0
}


# setn env variable for the Org1 peer
function set_env_Org1()
{
  export CORE_PEER_TLS_ENABLED=true
  export CORE_PEER_LOCALMSPID="Org1MSP"
  export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
  export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
  export CORE_PEER_ADDRESS=localhost:7051
}

# install the chaincode on the Org1 peer
function install_CC_org1()
{
  set_env_Org1

  peer lifecycle chaincode install basic.tar.gz

  # Query the installed chaincodes on a peer
  peer lifecycle chaincode queryinstalled

  # peer lifecycle chaincode queryinstalled >&log.txt
  #
  # res=$?
  # PACKAGE_ID=$(sed -n "/basic_1.0/{s/^Package ID: //; s/, Label:.*$//; p;}" log.txt)
  #
  # echo $PACKAGE_ID
}

# setn env variable for the Org1 peer
function set_env_Org2()
{
  export CORE_PEER_LOCALMSPID="Org2MSP"
  export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt
  export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt
  export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp
  export CORE_PEER_ADDRESS=localhost:9051
}

# install the chaincode on the Org2 peer
function install_CC_org2()
{
  set_env_Org2

  peer lifecycle chaincode install basic.tar.gz

  # Query the installed chaincodes on a peer
  peer lifecycle chaincode queryinstalled >&log.txt

  res=$?
  CC_PACKAGE_ID=$(sed -n "/basic_1.0/{s/^Package ID: //; s/, Label:.*$//; p;}" log.txt)

  echo $CC_PACKAGE_ID
}

# approve chaincode on Org1, first set the env variable
function approve_CC_org1()
{
  set_env_Org1

  peer lifecycle chaincode approveformyorg -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --channelID mychannel --name basic --version 1.0 --package-id $CC_PACKAGE_ID --sequence 1 --tls --cafile ${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem

}

# approve chaincode on Org2, first set the env variable
function approve_CC_org2()
{
  set_env_Org2

  peer lifecycle chaincode approveformyorg -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --channelID mychannel --name basic --version 1.0 --package-id $CC_PACKAGE_ID --sequence 1 --tls --cafile ${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
}

# check whether channel members have approved the same chaincode definition
function check_channel_mem_approved()
{
  echo "------------------------- checkcommitreadiness"
  peer lifecycle chaincode checkcommitreadiness --channelID mychannel --name basic --version 1.0 --sequence 1 --tls --cafile ${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem --output json
}

# commit the chaincode definition to the channel
function commit_CC_to_channel()
{
  echo "------------------------- commit the chaincode"
  peer lifecycle chaincode commit -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --channelID mychannel --name basic --version 1.0 --sequence 1 --tls --cafile ${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem --peerAddresses localhost:7051 --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt --peerAddresses localhost:9051 --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt

}

function query_committed()
{
  echo "------------------------- querycommitted"
  peer lifecycle chaincode querycommitted --channelID mychannel --name basic --cafile ${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem

}

# Invoking the chaincode, init
function init_CC()
{
  echo "------------------------- comInvoking the chaincode, init, begin"
  peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile ${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem -C mychannel -n basic --peerAddresses localhost:7051 --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt --peerAddresses localhost:9051 --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt -c '{"function":"InitLedger","Args":[]}'
  echo "------------------------- comInvoking the chaincode, init, end"

}

# Invoking the chaincode, query
function query_CC()
{
  echo "------------------------- comInvoking the chaincode, GetAllAssets, begin"
  peer chaincode query -C mychannel -n basic -c '{"Args":["GetAllAssets"]}'
  echo "------------------------- comInvoking the chaincode, GetAllAssets, end"
}

# ------------------------------------------------------------------------------
DELAY=2S
CC_PACKAGE_ID=

buildCerts

export FABRIC_CFG_PATH=$PWD/../config/

startTestNetwork
# createChannel
createChannel_2

sleep $DELAY
packageChainCode
sleep $DELAY
install_CC_org1
sleep $DELAY
install_CC_org2

# retrive CC_PACKAGE_ID value in function install_CC_org2
#export CC_PACKAGE_ID=basic_1.0:4ec191e793b27e953ff2ede5a8bcc63152cecb1e4c3f301a26e22692c61967ad
# echo "============================================"
# echo $CC_PACKAGE_ID
# echo "============================================"

sleep $DELAY
approve_CC_org1
sleep $DELAY
approve_CC_org2

sleep $DELAY
check_channel_mem_approved
sleep $DELAY
commit_CC_to_channel
sleep $DELAY
query_committed


# DELAY=4S

sleep $DELAY
init_CC
sleep $DELAY
query_CC
