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
    string RIPFSCID;

    function Result_IPFSCID(string memory D) public {
        MIPFSCID = D;
    }

    function Result_IPFSCID() public view returns (string memory) {
        return RIPFSCID;
    }

// Result_evaluation
    string Evaluation;

    function Result_Evaluation(string memory E) public {
        Evaluation = E;
    }

    function Result_Evaluation() public view returns (string memory) {
        return Evaluation;
    }


        constructor() {
        characteristic = "Model_characteristic";
        MIPFSCID = "Model_IPFSCID";
        TIPFSCID = "Testdata_IPFSCID";
        RIPFSCID = "Result_IPFSCID";
        Evaluation = "Result_Evaluation";

    }


}