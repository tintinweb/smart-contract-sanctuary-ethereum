/**
 *Submitted for verification at Etherscan.io on 2022-02-08
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

contract TestTxWait {
    string signer = "";

    function sign(string calldata name) external {
        signer = name;
    }

    function getLatestSginer() external view returns (string memory) {
        return signer;
    }
}