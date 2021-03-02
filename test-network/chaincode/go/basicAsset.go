package main

import (
	"encoding/json"
	"fmt"

	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

type Owner struct {
	Forename string `json:"forename"`
	Surname  string `json:"surname"`
}

type BasicAsset struct {
	ID        string `json:"id"`
	Owner     Owner  `json:"owner"`
	Value     int    `json:"value"`
	Condition int    `json:"condition"`
}

func (ba *BasicAsset) SetConditionNew() {
	ba.Condition = 0
}

func (ba *BasicAsset) SetConditionUsed() {
	ba.Condition = 1
}

//---------------------------------------------------------
type ComplexContract struct {
	contractapi.Contract
}

func (cc *ComplexContract) NewAsset(ctx CustomTransactionContextInterface, id string, owner Owner, value int) error {
	fmt.Println("------------------------In func: ComplexContract->NewAsset: begin", id, owner, value)
	existing := ctx.GetData()
	if existing != nil {
		return fmt.Errorf("cann't create the asset %s, it already existing", id)
	}

	ba := BasicAsset{
		ID:    id,
		Owner: owner,
		Value: value,
	}
	ba.SetConditionNew()

	baBytes, _ := json.Marshal(ba)
	err := ctx.GetStub().PutState(id, baBytes)
	if err != nil {
		return fmt.Errorf("unable to interact with the world state")
	}
	return nil
}

func (cc *ComplexContract) UpdateOwner(ctx CustomTransactionContextInterface, id string, newOwner Owner) error {
	fmt.Println("------------------------In func: ComplexContract->UpdateOwner: begin", id, newOwner)
	existing := ctx.GetData()
	if existing == nil {
		return fmt.Errorf("can not update the asset: %s", id)
	}

	ba := new(BasicAsset)
	err := json.Unmarshal(existing, ba)
	if err != nil {
		return fmt.Errorf("data from the world state is invalide: %s", id)
	}

	ba.Owner = newOwner
	ba.SetConditionUsed()
	baBytes, _ := json.Marshal(ba)
	err = ctx.GetStub().PutState(id, baBytes)
	if err != nil {
		return fmt.Errorf("unable to update asset: %s", id)
	}

	return nil
}

func (cc *ComplexContract) UpdateValue(ctx CustomTransactionContextInterface, id string, newValue int) error {
	fmt.Println("------------------------In func: ComplexContract->UpdateValue: begin", id, newValue)
	existing := ctx.GetData()
	if existing == nil {
		return fmt.Errorf("can not update the asset: %s", id)
	}

	ba := new(BasicAsset)
	err := json.Unmarshal(existing, ba)
	if err != nil {
		return fmt.Errorf("data from the world state is invalide: %s", id)
	}

	ba.Value += newValue
	baBytes, _ := json.Marshal(ba)
	err = ctx.GetStub().PutState(id, baBytes)
	if err != nil {
		return fmt.Errorf("unable to update asset: %s", id)
	}
	fmt.Println("------------------------In func: ComplexContract->UpdateValue: end", ba)

	return nil
}

func (cc *ComplexContract) GetAsset(ctx CustomTransactionContextInterface, id string) (*BasicAsset, error) {
	fmt.Println("------------------------In func: ComplexContract->GetAsset: begin", id)
	existing := ctx.GetData()
	if existing == nil {
		return nil, fmt.Errorf("can not update the asset: %s", id)
	}

	ba := new(BasicAsset)
	err := json.Unmarshal(existing, ba)
	if err != nil {
		return nil, fmt.Errorf("data from the world state is invalide: %s", id)
	}
	return ba, nil
}

func (cc *ComplexContract) GetEvaluateTransactions() []string {
	return []string{"GetAsset"}
}
