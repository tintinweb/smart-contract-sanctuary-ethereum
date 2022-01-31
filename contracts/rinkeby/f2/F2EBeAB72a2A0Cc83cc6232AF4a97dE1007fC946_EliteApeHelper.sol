// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract EliteApeHelper {
    mapping(address => uint256) public purchased;

    function increasePurchased(address _account, uint256 _amount) external {
        purchased[_account] += _amount;
    }    
}