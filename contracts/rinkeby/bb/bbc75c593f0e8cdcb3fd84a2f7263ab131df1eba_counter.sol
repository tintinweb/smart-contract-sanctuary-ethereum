/**
 *Submitted for verification at Etherscan.io on 2022-05-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract counter {
   uint public count = 5;
   address owner;

constructor() {
    owner = msg.sender;
}

    event Increment(uint value);
    event Decrement(uint value);

    function increment() public {
        count += 1;
        emit Increment(count);
    }

    function decrement() public {
        count -= 1;
        emit Decrement(count);
    }

    function getCount() view public returns(uint) {
        return count;
    }
}