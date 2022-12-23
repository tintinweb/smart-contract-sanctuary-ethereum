/**
 *Submitted for verification at Etherscan.io on 2022-12-23
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.7;

contract VendingMachine {
    // Declare state variables of the contract
    address payable public owner;
    mapping (address => uint) public cupcakeBalances;
    uint private _price = 1;

    struct Buyer {
        uint balance;
        address buyer;
        bool registred;
    }

    mapping (address => Buyer) public buyers;
    address[] private registredBuyers;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can refill");
        _;
    }


    // When 'VendingMachine' contract is deployed:
    // 1. set the deploying address as the owner of the contract
    // 2. set the deployed smart contract's cupcake balance to 100
    constructor() {
        owner = payable(msg.sender);
        cupcakeBalances[address(this)] = 100;
    }

    // Allow the owner to increase the smart contract's cupcake balance
    function refill(uint amount) public onlyOwner {
        cupcakeBalances[address(this)] += amount;
    }

    // Allow anyone to purchase cupcakes
    function purchase(uint amount) public payable {
        require(msg.value >= amount * 1 gwei * _price, "Valor insuficiente para o cupcake");
        require(cupcakeBalances[address(this)] >= amount, "Not enough cupcakes in stock to complete this purchase");
        cupcakeBalances[address(this)] -= amount;
        cupcakeBalances[msg.sender] += amount;

        buyers[msg.sender].balance = cupcakeBalances[msg.sender];

        if(!buyers[msg.sender].registred)
            registredBuyers.push(msg.sender);

        buyers[msg.sender].registred = true;

    }

    function setPrice(uint price) public onlyOwner {
        require(price > 0, "Valor informado precisar ser maior que zero!!");
        _price = price;
    }

    function getPrice() public view onlyOwner
            returns (uint) {
        return _price;
    }

    function getVendingMachineCupcakeBalance() public view 
        returns (uint) {
        return cupcakeBalances[address(this)];
    }
    
    function getVendingMachineEtherBalance() public onlyOwner view
            returns (uint) {
        return address(this).balance;
    }

    function withdraw() public onlyOwner payable {
        owner.transfer(getVendingMachineEtherBalance());
    }

    function getBuyers() public view
        returns (Buyer[] memory) {

        Buyer[] memory _buyers = new Buyer[](registredBuyers.length);

        for (uint p = 0; p < registredBuyers.length; p++) {
            _buyers[p] = buyers[registredBuyers[p]];
        }

        return _buyers;
    }
}