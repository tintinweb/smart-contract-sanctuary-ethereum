/**
 *Submitted for verification at Etherscan.io on 2022-12-16
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
        bool registered;
    }

    mapping (address => Buyer) public buyers;
    address[] private registeredBuyers;

    // When 'VendingMachine' contract is deployed:
    // 1. set the deploying address as the owner of the contract
    // 2. set the deployed smart contract's cupcake balance to 100
    constructor() {
        owner = payable(msg.sender);
        cupcakeBalances[address(this)] = 100;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can do this operation.");
        _;
    }

    // Allow the owner to increase the smart contract's cupcake balance
    function refill(uint amount) public onlyOwner {
        cupcakeBalances[address(this)] += amount;
    }

    // Allow anyone to purchase cupcakes
    function purchase(uint amount) public payable {
        require(msg.value >= amount * 1 gwei * _price, "Insufficient values for the cupcakes");
        require(cupcakeBalances[address(this)] >= amount, "Not enough cupcakes in stock to complete this purchase");
        cupcakeBalances[address(this)] -= amount;
        cupcakeBalances[msg.sender] += amount;

        buyers[msg.sender].balance = cupcakeBalances[msg.sender];

        if (!buyers[msg.sender].registered) {
            buyers[msg.sender].buyer = msg.sender;
            registeredBuyers.push(msg.sender);
        }

        buyers[msg.sender].registered = true;
    }

    function getPrice() public view onlyOwner returns (uint) {
        return _price;
    }

    function setPrice(uint price) public onlyOwner {
        require(price > 0, "Only the owner can do this operation.");
        _price = price;
    }

    function getVendingMachineCupcakeBalance() public view returns (uint) {
        return cupcakeBalances[address(this)];
    }

    function getVendingMachineEtherBalance() public onlyOwner view returns (uint) {
        return address(this).balance;
    }

    function withdraw() public onlyOwner {
        owner.transfer(getVendingMachineEtherBalance());
    }

    function getBuyers() public view returns(Buyer[] memory) {
        Buyer[] memory _buyers = new Buyer[](registeredBuyers.length);

        for(uint i=0; i<registeredBuyers.length; i++) {
            _buyers[i] = buyers[registeredBuyers[i]];
        }

        return _buyers;
    }
}