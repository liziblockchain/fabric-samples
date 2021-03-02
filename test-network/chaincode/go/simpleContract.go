package main

import (
	"errors"
	"fmt"

	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

type SimpleContract struct {
	contractapi.Contract
}

func (sc *SimpleContract) Init(ctx CustomTransactionContextInterface, key string, value string) error {
	fmt.Println("------------------------In chaincode func:  Init:", key, value)
	return sc.Create(ctx, key, value)
}

func (sc *SimpleContract) Create(ctx CustomTransactionContextInterface, key string, value string) error {
	// existing, err := ctx.GetStub().GetState(key)

	// if err != nil {
	// 	return errors.New("Unable to interact with world state")
	// }
	fmt.Println("------------------------In chaincode func:  Create:", key, value)

	existing := ctx.GetData()
	if existing != nil {
		return fmt.Errorf("Cannot create world state pair with key %s. Already exists", key)
	}

	err := ctx.GetStub().PutState(key, []byte(value))

	if err != nil {
		return errors.New("Unable to interact with world state")
	}

	return nil
}

func (sc *SimpleContract) Update(ctx CustomTransactionContextInterface, key string, value string) error {
	// existing, err := ctx.GetStub().GetState(key)

	// if err != nil {
	// 	return errors.New("Unable to interact with world state")
	// }

	fmt.Println("------------------------In chaincode func:  Update:", key, value)

	existing := ctx.GetData()
	if existing == nil {
		return fmt.Errorf("Cannot update world state pair with key %s. Does not exist", key)
	}

	err := ctx.GetStub().PutState(key, []byte(value))

	if err != nil {
		return errors.New("Unable to interact with world state")
	}

	return nil
}

// Read returns the value at key in the world state
func (sc *SimpleContract) Read(ctx CustomTransactionContextInterface, key string) (string, error) {
	// existing, err := ctx.GetStub().GetState(key)

	// if err != nil {
	// 	return "", errors.New("Unable to interact with world state")
	// }
	fmt.Println("------------------------In chaincode func:  Read:", key)

	existing := ctx.GetData()
	if existing == nil {
		return "", fmt.Errorf("Cannot read world state pair with key %s. Does not exist", key)
	}

	return string(existing), nil
}

// GetEvaluateTransactions returns functions of SimpleContract not to be tagged as submit
func (sc *SimpleContract) GetEvaluateTransactions() []string {
	fmt.Println("------------------------In chaincode func:  SimpleContract->GetEvaluateTransactions")
	return []string{"Read"}
}

// CustomTransactionContextInterface interface to define interaction with custom transaction context
type CustomTransactionContextInterface interface {
	contractapi.TransactionContextInterface
	GetData() []byte
	SetData([]byte)
}

// CustomTransactionContext adds methods of storing and retrieving additional data for use
// with before and after transaction hooks
type CustomTransactionContext struct {
	contractapi.TransactionContext
	data []byte
}

// GetData return set data
func (ctc *CustomTransactionContext) GetData() []byte {
	fmt.Println("------------------------In func:  CustomTransactionContext->GetData:", string(ctc.data))
	return ctc.data
}

// SetData provide a value for data
func (ctc *CustomTransactionContext) SetData(data []byte) {
	fmt.Println("------------------------In func:  CustomTransactionContext->SetData:", string(data))
	ctc.data = data
}

// GetWorldState takes the first transaction arg as the key and sets
// what is found in the world state for that key in the transaction context
func GetWorldState(ctx CustomTransactionContextInterface) error {
	_, params := ctx.GetStub().GetFunctionAndParameters()

	logtxt := ""
	for key, value := range params {
		tmp := fmt.Sprintf("-----%d:%s", key, string(value))
		logtxt += tmp
	}
	fmt.Println("------------------------In func:  GetWorldState, count of params", len(params), logtxt)

	if len(params) < 1 {
		return errors.New("Missing key for world state")
	}

	existing, err := ctx.GetStub().GetState(params[0])

	if err != nil {
		return errors.New("Unable to interact with world state")
	}

	ctx.SetData(existing)

	return nil
}

func UnknownTransactionHandler(ctx CustomTransactionContextInterface) error {
	fcn, args := ctx.GetStub().GetFunctionAndParameters()

	logtxt := "func name:" + fcn
	for key, value := range args {
		tmp := fmt.Sprintf("-----%d:%s", key, value)
		logtxt += tmp
	}
	fmt.Println("------------------------In func:  UnknownTransactionHandler:", logtxt)

	return fmt.Errorf("Invalid function %s passed with args %v", fcn, args)
}
