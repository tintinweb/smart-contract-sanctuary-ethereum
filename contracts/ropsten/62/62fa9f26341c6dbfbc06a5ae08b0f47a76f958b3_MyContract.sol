/**
 *Submitted for verification at Etherscan.io on 2022-02-09
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


contract MyContract {

// Model_characteristic
    string characteristic;

    function Model_characteristic(string memory A) public {
        characteristic = A;
    }

    function Model_characteristic() public view returns (string memory) {
        return characteristic;
    }

// Model_IPFSCID
    string MIPFSCID;

    function Model_IPFSCID(string memory B) public {
        MIPFSCID = B;
    }

    function Model_IPFSCID() public view returns (string memory) {
        return MIPFSCID;
    }
// Testdata_IPFSCID
    string TIPFSCID;

    function Testdata_IPFSCID(string memory C) public {
        MIPFSCID = C;
    }

    function Testdata_IPFSCID() public view returns (string memory) {
        return TIPFSCID;
    }
// Result_IPFSCID
// Result_evaluation
// IPFS_model
    string Avalue;

    function AModel(string memory AIPFS_CID) public {
        Avalue = AIPFS_CID;
    }

    function AModel() public view returns (string memory) {
        return Avalue;
    }


            constructor() {
        characteristic = "Model_characteristic";
        MIPFSCID = "Model_IPFSCID";
        TIPFSCID = "Testdata_IPFSCID";
    }


}