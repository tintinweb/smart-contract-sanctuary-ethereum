/**
 *Submitted for verification at Etherscan.io on 2022-04-20
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

// import "hardhat/console.sol";

contract Game {

    address public owner;
    uint128 count = 0;

    event FundsSent(uint amount, address to, uint balance);

    function incrementCount() public {
        count += 1;
    }

    function decrementCount() public {
        require(count > 0, "Count is 0, need to add more credits to play.");
        count -= 1;
    }

    function getCount() public view returns (uint128) {
        return count;
    }

    function sendFunds(address payable to) payable public {

        uint balance = msg.sender.balance;
        uint amount = msg.value;
        
        require(amount < balance, "Insufficient funds!");
        
        to.transfer(amount);
        
        emit FundsSent(amount, to, balance);

    }

    function getBalance() view public returns (uint) {
        return msg.sender.balance;
    }

}