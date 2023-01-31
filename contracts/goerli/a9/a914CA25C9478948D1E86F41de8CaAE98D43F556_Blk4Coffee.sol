/**
 *Submitted for verification at Etherscan.io on 2023-01-31
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

contract Blk4Coffee{
    mapping (address => int) public availableMoney;
    mapping (address => bool) public coffeeProvider;

    address owner = msg.sender;
    address coffeeMachine = msg.sender;

    uint public coffeePrice = 1 gwei;
    uint public availableCoffee = 20;
    uint private coffeeAccount = 100 gwei;

    bool private lockAccount = false;
    bool private lockProvider = false;

    function sendMoney() external payable{
        availableMoney[msg.sender] += int(msg.value);
    }

    function getMoneyBack() external{
        require(!lockAccount);
        lockAccount = true;
        require(availableMoney[msg.sender] > 0);

        (bool sent,) = msg.sender.call{value : uint(availableMoney[msg.sender])}("");
        require(sent, "getMoneyBack failed.");
        availableMoney[msg.sender] = 0;
        lockAccount = false;
    }

    function buyCoffee(address user) external{
        require(msg.sender == coffeeMachine);
        require(availableCoffee > 0);
        require(availableMoney[user] >= - 10 * (1 gwei) + int(coffeePrice));

        availableCoffee -= 1;
        availableMoney[user] -= int(coffeePrice);
        coffeeAccount += coffeePrice;
    }

    function addCoffeeProvider(address a) external{
        require(msg.sender == owner);
        coffeeProvider[a] = true;
    }

    function fixCoffeePrice(uint price) external{
        require(msg.sender == owner);
        coffeePrice = price * (1 gwei);
    }

    function changeOwner(address a) external {
        require(msg.sender == owner);
        owner = a;
    }

    function addCoffee(uint nbCoffee, int ticket) external{
        require(!lockProvider);

        lockProvider = true;
        require(coffeeProvider[msg.sender] == true);
        require(coffeeAccount >= nbCoffee * coffeePrice);
        require(ticket == 1234);

        (bool sent,) = msg.sender.call{value : nbCoffee * coffeePrice}("");
        require(sent, "addCoffee failed.");
        availableCoffee += nbCoffee;
        coffeeAccount -= nbCoffee * coffeePrice;
        lockProvider = false;
    }
}