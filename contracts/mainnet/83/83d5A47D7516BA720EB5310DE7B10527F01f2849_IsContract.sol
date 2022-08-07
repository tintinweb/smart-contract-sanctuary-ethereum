/**
 *Submitted for verification at Etherscan.io on 2022-08-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

contract IsContract {
    function isContract(address account) external view returns (bool) {
        return account.code.length > 0;
    }
}