/**
 *Submitted for verification at Etherscan.io on 2023-05-27
*/

// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.19;

contract C {}

contract D {
    function isContract(address account) external view returns (bool) {
        return account.code.length > 0;
    }

    function contractCode(address account) public view returns (bytes memory) {
        return account.code;
    }
}