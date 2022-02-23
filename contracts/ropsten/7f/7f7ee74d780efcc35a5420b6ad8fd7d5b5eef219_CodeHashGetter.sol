/**
 *Submitted for verification at Etherscan.io on 2022-02-21
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

contract CodeHashGetter {

    function getCodeHashOf(address account_) external view returns (bytes32 codeHash_) {
        codeHash_ = account_.codehash;
    }

}