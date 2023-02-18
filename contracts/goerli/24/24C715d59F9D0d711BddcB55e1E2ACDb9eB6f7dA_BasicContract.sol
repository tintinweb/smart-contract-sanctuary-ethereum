/**
 *Submitted for verification at Etherscan.io on 2023-02-17
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7;

contract BasicContract {
    uint amount = 0;

    function setAmount(uint x) public {
        amount = x;
    }

    event Increment(uint value);
    event Decrement(uint value);

    function increment() public {
        amount += 1;
        emit Increment(amount);
    }

    function decrement() public {
        amount -= 1;
        emit Decrement(amount);
    }

    function getAmount() public view returns (uint) {
        return amount;
    }

}