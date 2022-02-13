/**
 *Submitted for verification at Etherscan.io on 2022-02-13
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.11;



// File: payable.sol

contract MyContract {
    function invest() external payable {}

    function balanceOf() external view returns (uint256) {
        return address(this).balance;
    }
}