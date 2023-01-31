/**
 *Submitted for verification at Etherscan.io on 2023-01-31
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

contract Blk4Coffee{
    address owner = msg.sender;
    address coffeeMachine = msg.sender;

    bool private lockWithdraw = false;
    bool private lockCoffeeDeposit = false;

    mapping (address => bool) public coffeeProviders;
    mapping (address => int) public availableMoney;
    uint public coffeePrice = 1 gwei;
    uint public coffeeUnits = 50;
    uint private availableFunds = 50 gwei;

    function sendMoney() external payable{
        availableMoney[msg.sender] += int(msg.value);
    }

    function getMoneyBack() external{
        require(!lockWithdraw);
        lockWithdraw = true;
        require(availableMoney[msg.sender] > 0);
        (bool sent, ) = msg.sender.call{value: uint(availableMoney[msg.sender])}("");
        require(sent, "Failed to get money back!");
        availableMoney[msg.sender] = 0;
        lockWithdraw = false;
    }

    function buyCoffee(address a) external{
        require(msg.sender == coffeeMachine);
        require(coffeeUnits > 0);
        require(availableMoney[a] >= -10 * (1 gwei) + int(coffeePrice));
        availableMoney[a] -= int(coffeePrice);
        availableFunds += coffeePrice;
        coffeeUnits -= 1;
    }

    function addCoffee(uint nb, uint hash) external{
        require(!lockCoffeeDeposit);
        lockCoffeeDeposit = true;
        require(coffeeProviders[msg.sender] == true);
        require(availableFunds >= nb * coffeePrice);
        require(hash != 0);
        (bool sent, ) = msg.sender.call{value: nb * coffeePrice}("");
        require(sent, "Coffee deposit failed!");
        coffeeUnits += nb;
        availableFunds -= nb * coffeePrice;
        lockCoffeeDeposit = false;
    }

    function fixCoffeePrice(uint _price) external{
        require(msg.sender == owner);
        coffeePrice = _price * (1 gwei);
    }

    function addCoffeeProvider(address a) external{
        require(msg.sender == owner);
        coffeeProviders[a] = true;
    }

    function changeOwner(address a) external{
        require(msg.sender == owner);
        owner = a;
    }
}