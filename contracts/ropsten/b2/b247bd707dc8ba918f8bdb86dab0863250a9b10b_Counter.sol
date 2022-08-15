/**
 *Submitted for verification at Etherscan.io on 2022-08-15
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8;


/// @title Increment Counter
/// @dev increment the counter by 1 everytime it's called

contract Counter {
    uint256 public counter;

    event CounterIncreased(uint256 counter);

    function addCount( ) external {
        counter = counter + 1;
        emit CounterIncreased(counter);
    }
}