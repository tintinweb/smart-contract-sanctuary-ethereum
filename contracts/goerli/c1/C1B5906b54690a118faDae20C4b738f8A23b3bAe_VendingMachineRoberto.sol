/**
 *Submitted for verification at Etherscan.io on 2022-12-17
*/

/**
 *Submitted for verification at Etherscan.io on 2022-12-06
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.7;

contract VendingMachineRoberto {
    // Declare state variables of the contract
    address payable public owner;
    mapping (address => uint) public cupcakeBalances;

    // Declare state variables of the purchases in the contract
    uint private _price;
    PurchaseModel[] public purchases;

    // When 'VendingMachine' contract is deployed:
    // 1. set the deploying address as the owner of the contract
    // 2. set the deployed smart contract's cupcake balance to 100
    constructor() {
        owner = payable(msg.sender);
        cupcakeBalances[address(this)] = 100;
         _price = 1 gwei;
    }

    // Check if the account belongs to the owner
    modifier onlyOwner() {
        require(isOwner(), "Only th owner can refill.");
        _;
    }

    // Allow the owner to increase the smart contract's cupcake balance
    function refill(uint amount) public onlyOwner {
        cupcakeBalances[address(this)] += amount;
    }

    // Allow anyone to purchase cupcakes
    function purchase(uint amount) public payable {
        require(msg.value >= (amount * _price), "You must pay at least 1 Gwei per cupcake");
        require(cupcakeBalances[address(this)] >= amount, "Not enough cupcakes in stock to complete this purchase");
        cupcakeBalances[address(this)] -= amount;
        cupcakeBalances[msg.sender] += amount;
        purchases.push(PurchaseModel({
            buyerAddress: msg.sender, 
            quantity: msg.value 
        }));
    }

    function setPrice(uint price) public onlyOwner {
        _price = price;
    }

    function getPrice() public view returns (uint) {
        return _price;
    }

    function isOwner() private view returns (bool) {
        return msg.sender == owner;
    }

    function getVendingMachineCupcakeBalance() public onlyOwner view returns (uint) {
        return cupcakeBalances[address(this)];
    }

    function getVendingMachineEtherBalance() public view onlyOwner returns (uint) {
        return address(this).balance;
    }

    function withdraw() public onlyOwner{
        owner.transfer(address(this).balance);
    }

     function getBuyers() public view onlyOwner returns (PurchaseModel[] memory) {
        return purchases;
    }

}

// Declare a model to represent a purchase in the contract
struct PurchaseModel {
    address buyerAddress;
    uint quantity;
}