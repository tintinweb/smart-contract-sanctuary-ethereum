/**
 *Submitted for verification at Etherscan.io on 2022-11-10
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

contract GasCheck {

    uint256 public maxGWEI = 80 gwei;
    uint256 public currentGas;

    function setMaxGWEI(uint256 _gas) external {
        maxGWEI = _gas;
    }

    function gasPrice() external returns (bool isHigher) {
        currentGas = tx.gasprice;
        isHigher = currentGas > maxGWEI;
    }
}