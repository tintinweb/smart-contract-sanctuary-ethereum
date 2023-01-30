/**
 *Submitted for verification at Etherscan.io on 2023-01-30
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.17;

contract block4coffee {

    int MIN_BALANCE = -10 * (1 gwei);                     // Minimum money on a user account (-10GWei)
    uint MIN_COFFEE = 0;                                // Minimum coffee in the machine

    address public c_owner = msg.sender;                // Owner of the coffee machine
    mapping (address => bool) public providers;         // People who can refil the coffee machine
    mapping (address => int) public currencyBalance;    // Accounts with money
    
    int public c_finances = 0;                          // The money on the coffee machine
    uint public c_amount = 0;                           // The amount of coffee
    uint public c_price = 2 * (1 gwei);                  // The price of a coffee (2Gwei)

    mapping(address => string[]) c_receipt;             // Receipt of each new coffee command

    function sendMoney() external payable{
        currencyBalance[msg.sender] += int(msg.value);
    }

    function getMoneyBack() external{
        require (currencyBalance[msg.sender] > 0);
        uint tmp_balance = uint(currencyBalance[msg.sender]);
        currencyBalance[msg.sender] = 0;
        payable(msg.sender).transfer(tmp_balance);
    }

    function buyCoffee() external{
        require(c_amount - 1 >= MIN_COFFEE);
        require(currencyBalance[msg.sender] - int(c_price) >= MIN_BALANCE);
        c_amount --;
        currencyBalance[msg.sender] -= int(c_price);
        c_finances += int(c_price);
    }

    function addCoffeeProvider(address coffeeProvider) external{
        require(msg.sender == c_owner);
        providers[coffeeProvider] = true;
    }

    function fixCoffeePrice(uint price) external{
        require(msg.sender == c_owner);
        c_price = price;
    }

    function changeOwner(address owner) external{
       require(msg.sender == c_owner);
       c_owner = owner;
    }

    function addCoffee(uint coffeeAmount, string calldata receipt) external{
        uint transaction = coffeeAmount * c_price;
        require (providers[msg.sender]);
        require (c_finances >= int(transaction));
        require(bytes(receipt).length > 0);
        c_amount += coffeeAmount;
        c_finances -= int(transaction);
        currencyBalance[msg.sender] += int(transaction);
        c_receipt[msg.sender].push(receipt);
    }
}