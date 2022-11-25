/**
 *Submitted for verification at Etherscan.io on 2022-11-25
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;


contract MyContract {
    event Called(uint256 ts);

    function doSomething() external {
        emit Called(block.timestamp);
    }
}