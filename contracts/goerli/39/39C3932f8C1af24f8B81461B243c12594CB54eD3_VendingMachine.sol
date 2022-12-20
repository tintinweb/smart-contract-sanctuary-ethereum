/**
 *Submitted for verification at Etherscan.io on 2022-12-20
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.7;

contract VendingMachine {
    // Declare state variables of the contract
    address payable public owner;
    mapping (address => uint) private cupcakeBalances;
    uint private _price = 1;

    struct BuyerStruct {
        address buyer;
        uint qty;
    }
    BuyerStruct[] private _buyers;

    // When 'VendingMachine' contract is deployed:
    // 1. set the deploying address as the owner of the contract
    // 2. set the deployed smart contract's cupcake balance to 100
    constructor() {
        owner = payable(msg.sender);
        cupcakeBalances[address(this)] = 100;
    }

    modifier onlyOwner{
        require(msg.sender == owner, "Only the owner can refill.");
        _;
    }

    // Allow the owner to increase the smart contract's cupcake balance
    function refill(uint amount) public onlyOwner {
        cupcakeBalances[address(this)] += amount;
    }

    // Allow anyone to purchase cupcakes
    function purchase(uint amount) public payable {
        require(msg.value >= amount  * _price * 1 gwei, "Valor insuficiente para o cupcake");
        require(cupcakeBalances[address(this)] >= amount, "Not enough cupcakes in stock to complete this purchase");
        cupcakeBalances[address(this)] -= amount;
        cupcakeBalances[msg.sender] += amount;

        BuyerStruct memory buyerStruct;
        buyerStruct.buyer = msg.sender;
        buyerStruct.qty = amount;
        _buyers.push(buyerStruct);
    }

    function setPrice(uint256 amount) public onlyOwner {
        _price = amount;
    }

    function getPrice() public view returns (uint256) {
        return _price;
    }

    function getVendingMachineCupcakeBalance() public view returns (uint) {
        return cupcakeBalances[address(this)];
    }

    function getVendingMachineEtherBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function withdraw() public onlyOwner {
        owner.transfer(address(this).balance);
    }

    function getBuyers() public view returns (BuyerStruct[] memory buyers) {
        return _buyers;
    }
}