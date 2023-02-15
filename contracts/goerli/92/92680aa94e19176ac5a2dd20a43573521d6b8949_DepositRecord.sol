/**
 *Submitted for verification at Etherscan.io on 2023-02-15
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.18;

contract DepositRecord {
    // Global

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

    // User

    uint256 private _userDepositCap;
    mapping(address => uint256) private _userToDeposits;

    function getUserDepositCap() external view returns (uint256) {
        return _userDepositCap;
    }
    function getUserDepositAmount(address account) external view returns (uint256) {
        return _userToDeposits[account];
    }
    
    function setUserDepositCap(uint256 userDepositCap) external {
        _userDepositCap = userDepositCap;
    }
    function setMyDepositAmount(uint256 amount) external {
        _userToDeposits[msg.sender] = amount;
    }
}