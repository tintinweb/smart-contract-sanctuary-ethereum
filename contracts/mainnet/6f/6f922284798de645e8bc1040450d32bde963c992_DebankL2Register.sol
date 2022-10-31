/**
 *Submitted for verification at Etherscan.io on 2022-10-31
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

/**
 * @title DebankL2Register
 */

contract DebankL2Register {

    mapping(address => uint256) public nonces;
    mapping(address => string) public l2Accounts;

    event Register(address user, string l2Account, uint256 registerCnt);

    function register(string calldata l2Account) public {
        l2Accounts[msg.sender] = l2Account;
        nonces[msg.sender] += 1;
        emit Register(msg.sender, l2Account, nonces[msg.sender]);
    }
}