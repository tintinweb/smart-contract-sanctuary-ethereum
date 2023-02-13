/**
 *Submitted for verification at Etherscan.io on 2023-02-13
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.18;

contract DepositRecord {
    uint256 private _globalNetDepositCap;
    uint256 private _globalNetDepositAmount;

    function getGlobalNetDepositCap() external view returns (uint256) {
        return _globalNetDepositCap;
    }
    function getGlobalNetDepositAmount() external view returns (uint256) {
        return _globalNetDepositAmount;
    }

    function setGlobalNetDepositCap(uint256 globalNetDepositCap) external {
        _globalNetDepositCap = globalNetDepositCap;
    }
    function setGlobalNetDepositAmount(uint256 globalNetDepositAmount) external {
        _globalNetDepositAmount = globalNetDepositAmount;
    }
}