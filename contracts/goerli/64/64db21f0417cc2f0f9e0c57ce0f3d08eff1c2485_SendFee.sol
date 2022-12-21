/**
 *Submitted for verification at Etherscan.io on 2022-12-21
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

contract SendFee {
    constructor() {}

    function getBatchBalances(address[] calldata addresses) external view returns (uint256[] memory) {
        uint256[] memory balances = new uint256[](addresses.length);
        for (uint256 i; i < addresses.length; i++) {
            balances[i] = addresses[i].balance;
        }

        return balances;
    } 

    function sendBatchFees(uint256 amount, address[] calldata addresses) external payable returns (bool) {
        uint256 total = amount * addresses.length;
        require(total == msg.value, "insufficient fund");

        for (uint256 i; i < addresses.length; i++) {
            payable(addresses[i]).transfer(amount);
        }

        return true;
    }
}