/**
 *Submitted for verification at Etherscan.io on 2022-02-09
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


contract MyContract {
// IPFS_model
    string value;

    function Model(string memory IPFS_CID) public {
        value = IPFS_CID;
    }

    function Model() public view returns (string memory) {
        return value;
    }
    constructor() {
        value = "IPFS_Model";
    }
}

contract Ccontract {
// IPFS_testdata set
  string value_1;

    function Testdata(string memory IPFS_CID_testdata) public {
        value_1 = IPFS_CID_testdata;
    }

    function Testdata() public view returns (string memory) {
        return value_1;
    }
    constructor() {
        value_1 = "IPFS_Testdata";
    }

}