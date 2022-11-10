/**
 *Submitted for verification at Etherscan.io on 2022-11-10
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

contract GasCheck {

    uint256 public currentGas;

    function gasPrice() external {
        currentGas = tx.gasprice;
    }
}