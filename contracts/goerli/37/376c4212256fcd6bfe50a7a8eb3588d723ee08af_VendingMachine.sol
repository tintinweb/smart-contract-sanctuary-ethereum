/**
 *Submitted for verification at Etherscan.io on 2022-12-23
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.7;

contract VendingMachine {
    
    address payable public owner;
    mapping (address => uint) public cupcakeBalances;
    mapping (address => uint) public cupcakePrice;
    mapping (address => Buyer) public buyers;
    address[] private registeredBuyers;
   

    struct Buyer{
        uint balance;
        address buyer;
        bool registered;
    }

    
    modifier onlyOwner() {
    require(msg.sender == owner, "Only the owner can do it.");
        _;
    }

    constructor() {
        owner = payable(msg.sender);
        cupcakeBalances[address(this)] = 100;
        cupcakePrice[address(this)] = 0;
    }

    function setPrice(uint price) public onlyOwner() {
       cupcakePrice[address(this)] = price;
    }

    function getPrice() public view onlyOwner returns (uint) {
        return  cupcakePrice[address(this)];
    }

    function getVendingMachineCupcakeBalance() public view returns(uint) {
        return cupcakeBalances[address(this)];
    }

    function getVendingMachineEtherBalance() public onlyOwner returns(uint256) {

        uint256 balanceGwei = address(this).balance;
        uint256 balanceEther =  balanceGwei / 1000000000;

        return balanceEther;
    }

    
    function withdraw() public onlyOwner payable {

       uint balance = getVendingMachineEtherBalance();

        owner.transfer(balance);
    }


    function refill(uint amount) public onlyOwner() {
        cupcakeBalances[address(this)] += amount;
    }
   
    function purchase(uint amount) public payable {
        require(msg.value >= amount * 1 gwei, "You must pay at least 1 Gwai per cupcake");
        require(cupcakeBalances[address(this)] >= amount, "Not enough cupcakes in stock to complete this purchase");
        cupcakeBalances[address(this)] -= amount;
        cupcakeBalances[msg.sender] += amount;

        buyers[msg.sender].balance = cupcakeBalances[msg.sender];

        if(!buyers[msg.sender].registered){
            registeredBuyers.push(msg.sender);
        }

         buyers[msg.sender].registered = true;
    }

    function getBuyers() public view returns(Buyer[] memory) {
        Buyer[] memory _buyers= new Buyer[](registeredBuyers.length);
            for (uint i=0; i<registeredBuyers.length; i++) {
            _buyers[i] = buyers[registeredBuyers[i]];
            }
        return _buyers;
    }       
}