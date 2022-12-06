/**
 *Submitted for verification at Etherscan.io on 2022-12-06
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.7;

contract VendingMachine {
    // Declare state variables of the contract
    address payable public owner;
    mapping (address => uint) public cupcakeBalances;

    uint private _price;

    struct PurchasesInfo {
        address addressFromPurchases;
        uint quantityFromPurchases;
    }

    PurchasesInfo[] public listPurchases;

    // When 'VendingMachine' contract is deployed:
    // 1. set the deploying address as the owner of the contract
    // 2. set the deployed smart contract's cupcake balance to 100
    constructor() {
        owner = payable(msg.sender);
        cupcakeBalances[address(this)] = 100;
        _price = 1 gwei;
    }

    modifier onlyChairperson() {
        require(msg.sender == owner, "Only the chairperson can do it.");
        _;
    }

    // Allow the owner to increase the smart contract's cupcake balance
    function refill(uint amount) public onlyChairperson {
        cupcakeBalances[address(this)] += amount;
    }

    // Allow anyone to purchase cupcakes
    function purchase(uint amount) public payable {
        require(msg.value >= (amount * _price), "You must pay at least 1 gwei per cupcake ");
        require(cupcakeBalances[address(this)] >= amount, "Not enough cupcakes in stock to complete this purchase");
        cupcakeBalances[address(this)] -= amount;
        cupcakeBalances[msg.sender] += amount;

        bool isUpdate = false;
        for (uint256 i = 0; i < listPurchases.length; i++) { 
            address addressFromPurchases = listPurchases[i].addressFromPurchases; 
            if (addressFromPurchases == msg.sender) { 
                uint quantityFromPurchases = listPurchases[i].quantityFromPurchases;
                listPurchases[i].quantityFromPurchases = quantityFromPurchases + msg.value;
                isUpdate = true; break;
            } 
        }

        if(isUpdate == false) {
            listPurchases.push(PurchasesInfo({ addressFromPurchases: msg.sender, quantityFromPurchases: msg.value }));
        }
  
    }

    function setPrice(uint price) public onlyChairperson {
        _price = price;
    }

    function getPrice() public view returns (uint) {
        return _price;
    }
    
    function getVendingMachineCupcakeBalance() public onlyChairperson view returns (uint) {
        return cupcakeBalances[address(this)];
    }
    
    function getVendingMachineEtherBalance() public view onlyChairperson returns (uint) {
        return address(this).balance;
    }

    function withdraw() public onlyChairperson {
        owner.transfer(address(this).balance);
    }

    function getBuyers() public view onlyChairperson returns (PurchasesInfo[] memory) {
        return listPurchases;
    }
}