/**
 *Submitted for verification at Etherscan.io on 2022-12-18
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.7;

contract VendingMachine {
    // Declare state variables of the contract
    address payable public owner;    
    mapping (address => uint) public cupcakeBalances;
    uint _price;

    mapping (address => Buyer) public buyers;
    address[] registeredBuyers;

    struct Buyer{
        uint balance;
        address buyer;
        bool registered;
    }


    // When 'VendingMachine' contract is deployed:
    // 1. set the deploying address as the owner of the contract
    // 2. set the deployed smart contract's cupcake balance to 100
    constructor() {
        owner = payable(msg.sender);
        cupcakeBalances[address(this)] = 100;
        _price = 1;
    }

     // modificador para verificar se é o dono 
    modifier onlyOwner() { 
        require(msg.sender == owner, "Only the chairperson can do it."); 
        _; 
    } 

    // Allow the owner to increase the smart contract's cupcake balance
    function refill(uint amount) public onlyOwner() {        
        cupcakeBalances[address(this)] += amount;
    }

    // Allow anyone to purchase cupcakes
    function purchase(uint amount) public payable {       
        require(msg.value >= amount * 0.1 ether * _price, "Insufficient amount to make the purchase");
        require(cupcakeBalances[address(this)] >= amount, "Not enough cupcakes in stock to complete this purchase");
        cupcakeBalances[address(this)] -= amount;
        cupcakeBalances[msg.sender] += amount;

        buyers[msg.sender].balance = cupcakeBalances[msg.sender];

        if(!buyers[msg.sender].registered)
            registeredBuyers.push(msg.sender);

        buyers[msg.sender].registered = true;
    }

     function setPrice(uint price) public onlyOwner() {  
         require(price > 0, "Price must be greater than zero");      
        _price = price;
    }

    function getPrice() public view returns(uint) {        
        return _price;
    }

    function getVendingMachineCupcakeBalance() public view returns(uint){
        return cupcakeBalances[address(this)];
    }

    function getVendingMachineEtherBalance() public onlyOwner view returns(uint){
        return address(this).balance;
    }

    function withdraw() public onlyOwner payable {
        owner.transfer(getVendingMachineEtherBalance());
    }

    
    function getBuyers() public view returns (Buyer[] memory) {
        
        Buyer[] memory _buyers = new Buyer[] (registeredBuyers.length);

        for (uint i = 0; i < registeredBuyers.length; i++){
            _buyers[i] = buyers[registeredBuyers[i]];
        }

        return _buyers;
    }
}