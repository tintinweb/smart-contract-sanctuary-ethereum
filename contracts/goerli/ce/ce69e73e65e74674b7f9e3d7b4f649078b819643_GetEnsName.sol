/**
 *Submitted for verification at Etherscan.io on 2022-12-29
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

contract GetEnsName {
    address ethAddress;
    uint256 balance;

    function getAddress() public view returns (address) {
        return msg.sender;
    }

    function getBalance() public view returns (uint256) {
        return msg.sender.balance;
    }
}