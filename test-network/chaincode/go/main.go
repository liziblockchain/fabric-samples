package main

import (
	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

func main() {
	simpleContract := new(SimpleContract)
	simpleContract.TransactionContextHandler = new(CustomTransactionContext)
	simpleContract.BeforeTransaction = GetWorldState
	simpleContract.UnknownTransaction = UnknownTransactionHandler
	simpleContract.Name = "com.liziblockchain.simple"

	// cc, err := contractapi.NewChaincode(simpleContract)
	// simpleContract.Contract.get

	complexContract := new(ComplexContract)
	complexContract.TransactionContextHandler = new(CustomTransactionContext)
	complexContract.BeforeTransaction = GetWorldState
	complexContract.UnknownTransaction = UnknownTransactionHandler
	complexContract.Name = "com.liziblockchain.complex"

	cc, err := contractapi.NewChaincode(simpleContract, complexContract)
	cc.DefaultContract = complexContract.GetName()

	if err != nil {
		panic(err.Error())
	}

	if err := cc.Start(); err != nil {
		panic(err.Error())
	}
}
