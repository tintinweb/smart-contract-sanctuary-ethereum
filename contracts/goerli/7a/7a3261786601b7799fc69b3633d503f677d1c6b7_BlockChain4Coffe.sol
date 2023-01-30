/**
 *Submitted for verification at Etherscan.io on 2023-01-30
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.7;


contract BlockChain4Coffe {

    mapping (address => uint) public coffeeBalance;
    mapping (address => uint) public coffeeDebt;
    mapping (address => string[]) public proofAndCP;
    uint public nbCoffee = 0;
    uint public priceCoffee = 1 gwei;
    address public owner = msg.sender;
    mapping(address => bool) public coffeeProviders;
    

    function sendMoney() external payable{
        if(coffeeDebt[msg.sender]>0){
            if(coffeeDebt[msg.sender] < msg.value){
                uint solde = msg.value - coffeeDebt[msg.sender];
                coffeeDebt[msg.sender] = 0;
                coffeeBalance[msg.sender] = solde; 
            }
            else{
                coffeeDebt[msg.sender] -= msg.value;
            }
        }
        else {
            coffeeBalance[msg.sender]+=msg.value;
        }
    }

    function getMoneyBack() external {
        uint amount = coffeeBalance[msg.sender];
        require(amount>0,"You don't have any money");
        require(address(this).balance>=amount,"Not enought money on the contract");
        coffeeBalance[msg.sender]=0;
        payable(msg.sender).transfer(amount);
    }

    function buyCoffee() external {

        require(nbCoffee>0,"No Coffee, contact Coffee Provider");

        uint currentUserBalance = coffeeBalance[msg.sender] ;

        if(currentUserBalance == 0){
            require(coffeeDebt[msg.sender] + priceCoffee <= (10 gwei),"Too Much in debt");
            coffeeDebt[msg.sender] += priceCoffee;
        }
        else if(currentUserBalance < priceCoffee){
            uint userDebt = priceCoffee - currentUserBalance;
            coffeeDebt[msg.sender] = userDebt; 
            coffeeBalance[msg.sender] = 0;
        }
        else{
            currentUserBalance -= priceCoffee;
            coffeeBalance[msg.sender] = currentUserBalance;
        }

        nbCoffee-= 1;
    }

    //COFFEE PROVIDERS ONLYS
    function isCoffeeProvider(address potentialCP) internal view returns(bool){
        return coffeeProviders[potentialCP];
    }

    function addCoffee(string memory proof,uint nbCoffeeToProvide) external {
        require(isCoffeeProvider(msg.sender),"You are not a coffee provider, ask the owner to be one");
        
        //REFUND
        uint amountToRefund = priceCoffee * nbCoffeeToProvide; 
        if(coffeeDebt[msg.sender]>0){
            if(coffeeDebt[msg.sender] - amountToRefund < 0){
                uint solde = amountToRefund - coffeeDebt[msg.sender];
                coffeeDebt[msg.sender] = 0;
                coffeeBalance[msg.sender] = solde; 
            }
            else{
                coffeeDebt[msg.sender] -= amountToRefund;
            }
        }
        else {
            coffeeBalance[msg.sender]+=amountToRefund;
        }
        coffeeBalance[msg.sender]+= amountToRefund;
        //END REFUND
        
        proofAndCP[msg.sender].push(proof);
        nbCoffee+=nbCoffeeToProvide;
    }

    //OWNERS ONLY
    function isOwner(address potentialOwner) internal view returns(bool) {
        return potentialOwner==owner;
    }

    function removeCoffeeProvider(address CPtoRemove) external{

        require(isOwner(msg.sender),"You are not the owner");

        require(isCoffeeProvider(CPtoRemove),"Is not a coffee provider");
        
        coffeeProviders[CPtoRemove]=false;
    }

    function addCoffeeProvider(address provider) external {

        require(isOwner(msg.sender),"You are not the owner");

        require(!isCoffeeProvider(provider),"Already a Coffee Provider");
        
        coffeeProviders[provider]=true;
    }

    function fixCoffeePrice(uint price) external {
        require(isOwner(msg.sender),"You are not the owner");
        priceCoffee = price;
    }

    function changeOwner(address newOwner) external {
        require(isOwner(msg.sender),"You are not the owner");
        owner = newOwner;
    }

}