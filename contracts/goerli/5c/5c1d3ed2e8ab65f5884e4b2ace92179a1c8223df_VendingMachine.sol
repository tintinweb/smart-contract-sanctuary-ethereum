/**
 *Submitted for verification at Etherscan.io on 2022-12-14
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.7;

contract VendingMachine {
    struct Buyer {
        address buyerAddress;
        uint cupcakeAmount;
    }

    address payable public owner;

    mapping (address => uint) public cupcakeBalances;
    mapping (address => uint) public cupcakePrice;

    Buyer[] public buyers;
    
    constructor() {
        owner = payable(msg.sender);
        cupcakeBalances[address(this)] = 100;
        cupcakePrice[address(this)] = 1 gwei;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can do this operation.");
        _;
    }

    function setPrice(uint price) public onlyOwner {
        cupcakeBalances[address(this)] = price;
    }

    function getPrice() public view returns (uint value) {
        value = cupcakePrice[address(this)];
    }

    function getVendingMachineCupcakeBalance() public view returns (uint value) { 
        value = cupcakeBalances[address(this)];
    }

    function getVendingMachineEtherBalance() public view returns (uint value) { 
        value = address(this).balance;
    }

    function withdraw() public payable onlyOwner {
        owner.transfer(address(this).balance);
    }

    function refill(uint amount) public onlyOwner {
        cupcakeBalances[address(this)] += amount;
    }

    function purchase(uint amount) public payable {
        require(msg.value >= amount * 1 gwei, "You must pay at least 1 Gwei per cupcake");
        require(cupcakeBalances[address(this)] >= amount, "Not enough cupcakes in stock to complete this purchase");
        
        buyers.push(Buyer({
            buyerAddress: msg.sender,
            cupcakeAmount: amount
        }));

        cupcakeBalances[address(this)] -= amount;
        cupcakeBalances[msg.sender] += amount;
    }

    function getBuyers() public view returns(Buyer[] memory) {
        Buyer[] memory _buyers = new Buyer[](buyers.length);
        for (uint i=0; i < buyers.length; i++) {
           _buyers[i] = buyers[i];
        }
        return _buyers;
    }
}