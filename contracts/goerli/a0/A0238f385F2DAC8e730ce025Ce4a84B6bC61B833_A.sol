/**
 *Submitted for verification at Etherscan.io on 2022-11-23
*/

// SPDX-License-Identifier: MIT
// solhint-disable const-name-snakecase
pragma solidity 0.6.10;

contract A {

    event CallFallback(uint256);
    event CallReceive(uint256);

    fallback() external {
        emit CallFallback(3);
    }

    receive() external payable {
        emit CallReceive(4);
    }
}