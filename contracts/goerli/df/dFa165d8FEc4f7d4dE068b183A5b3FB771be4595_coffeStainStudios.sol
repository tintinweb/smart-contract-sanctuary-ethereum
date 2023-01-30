/**
 *Submitted for verification at Etherscan.io on 2023-01-30
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.8.0;

contract coffeStainStudios {
    uint public coffeePrice = 1 * (10**9);
    uint oneCoffeeQuantity = 1;
    int authorizedDebt = -10**9;
    uint coffeeQuantity;
    mapping (address => int) public currencyBalance;

    address public owner;
    address[] public coffeeProviders;

    //sets variables at launch
    constructor() {
        owner = msg.sender;
        coffeeProviders.push(owner);
    }

    function sendMoney() external payable {
        currencyBalance[msg.sender]+=int(msg.value);
    }
    // what do we do if the guy is indepted ??
    function getMoneyBack() external {
        require(currencyBalance[msg.sender]>0);
        int currencyBalanceTmp = currencyBalance[msg.sender];
        currencyBalance[msg.sender]=0;
        //payable(msg.sender).transfer(uint(currencyBalanceTmp));
        ( bool sent , ) =
                // Interaction
            msg.sender.call{value : uint(currencyBalanceTmp)}(" ");
        require(sent, "MyCoffee failed to send Ether");
    }
    function buyCoffee() external {
        require (currencyBalance[msg.sender]-int(coffeePrice) >= authorizedDebt);
        require (coffeeQuantity > 0);
        currencyBalance[msg.sender]-=int(coffeePrice);
        coffeeQuantity-=oneCoffeeQuantity;
    }

    function member(address addr) private returns(bool) {
        uint length = coffeeProviders.length;
        for (uint i = 0; i < length; i++) {
            if (coffeeProviders[i] == addr) return true;
        }
        return false;
    }

    function addCoffeeProvider(address newGuy) external {
        require(msg.sender == owner);
        require(!member(newGuy));
        coffeeProviders.push(newGuy);
    }
    function fixCoffeePrice(uint newPrice) external {
        require(msg.sender == owner);
        //require(newPrice > 0); uint so not necessary
        coffeePrice=newPrice;
    }
    function changeOwner(address newGuy) external {
        require(msg.sender == owner);
        owner=newGuy;
    }

    function addCoffee(uint addedQuantity) external {
        require(member(msg.sender));
        int reimbursePrice = int((addedQuantity/oneCoffeeQuantity)*coffeePrice);
        require(address(this).balance > uint(reimbursePrice));
        //require(addedQuantity > 0); uint again
        coffeeQuantity+=addedQuantity;
        currencyBalance[msg.sender]+=reimbursePrice;
    }

    function getBalance() view external returns(int) {
        return currencyBalance[msg.sender];
    }
}