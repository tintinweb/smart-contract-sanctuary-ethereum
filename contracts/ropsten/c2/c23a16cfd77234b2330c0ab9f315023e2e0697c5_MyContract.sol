/**
 *Submitted for verification at Etherscan.io on 2022-02-09
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


contract MyContract {
    string value;

    function Model(string memory CID) public {
        value = CID;
    }

    function Model() public view returns (string memory) {
        return value;
    }
    constructor() {
        value = "IPFS_Model";
    }
}