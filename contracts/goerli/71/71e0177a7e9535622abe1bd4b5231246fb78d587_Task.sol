/**
 *Submitted for verification at Etherscan.io on 2022-11-07
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;


// Find a way to add your address in `winners`.
contract Task{
    bool locked;
    address[] public winners;

    function add(address winner) payable  public {
        locked = false;


        require(locked);
        winners.push(winner);
    }

    function lock() public {
        locked = true;
    }
}