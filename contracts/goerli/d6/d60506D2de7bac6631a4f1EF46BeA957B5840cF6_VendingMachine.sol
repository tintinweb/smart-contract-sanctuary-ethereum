/**
 *Submitted for verification at Etherscan.io on 2022-12-22
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.7;
contract VendingMachine {
    // Declare state variables of the contract
    address payable public owner;
    mapping (address => uint) public cupcakeBalances;
    uint price;

    struct Buyer { 
        bool registered;
        uint amount; 
        address addr; 
    } 

    mapping(address => Buyer) buyers;
    address[] registeredBuyers; 
    // When 'VendingMachine' contract is deployed: c
    // 1. set the deploying address as the owner of theontract
    // 2. set the deployed smart contract's cupcake balance to 100
    constructor() {
        owner = payable(msg.sender);
        cupcakeBalances[address(this)] = 100;
        price = 1 gwei;
    }

    // Allow the owner to increase the smart contract's cupcake balance
    function refill(uint amount) public onlyOwner() {      
        cupcakeBalances[address(this)] += amount;
    }

    // Allow anyone to purchase cupcakes
    function purchase(uint amount) public payable {
        require(msg.value >= amount * price, "Not the correct price");
        require(cupcakeBalances[address(this)] >= amount, "Not enough cupcakes in stock to complete this purchase");
        cupcakeBalances[address(this)] -= amount;
        cupcakeBalances[msg.sender] += amount;

        if(!buyers[msg.sender].registered){
            registeredBuyers.push(msg.sender);
            buyers[msg.sender].registered = true;
            buyers[msg.sender].addr = msg.sender;

        }
        buyers[msg.sender].amount += amount;
    }

    // modificador para verificar se é o dono 
    modifier onlyOwner() { 
        require(msg.sender == owner, "Transaction allowed only for owner.");
        _; 
    } 

    function getPrice() public view  
        returns (uint value)  
    { 
        value = price; 
    } 

    function setPrice(uint value) public onlyOwner()
    { 
        price = value; 
    }
    
    function getVendingMachineCupcakeBalance() public view  
        returns (uint total)  
    { 
        total = cupcakeBalances[address(this)]; 
    } 
    
    function getVendingMachineEtherBalance() public view  
        returns (uint total)  
    { 
        total = address(this).balance; 
    } 

    function withdraw() public onlyOwner() {
        if (address(this).balance > 0) {
            payable(msg.sender).transfer(address(this).balance);
        }
    }

    function getMyAmountPurchesed() public view 
            returns (uint amount) 
    { 
        amount = buyers[msg.sender].amount; 
    }

    function getMyBalance() public view 
            returns (uint value) 
    { 
        value = address(msg.sender).balance; 
    }

    function getBuyers() public view returns(Buyer[] memory) { 
        Buyer[] memory _buyers = new Buyer[](registeredBuyers.length); 
        for (uint i=0; i<registeredBuyers.length; i++) { 
            _buyers[i] = buyers[registeredBuyers[i]]; 
        } 
        return _buyers; 
    }  
}