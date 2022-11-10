/**
 *Submitted for verification at Etherscan.io on 2022-11-10
*/

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.3;


contract Test {
    event TransactionExecuted(address indexed wallet, bool indexed success, bytes returnData, bytes signedHash);

    function getMethod(address a, bool b, bytes memory _data1, bytes calldata signedHash2) public {
        emit TransactionExecuted(a, b, _data1, signedHash2);
    }
}