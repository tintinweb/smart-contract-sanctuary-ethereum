/**
 *Submitted for verification at Etherscan.io on 2023-03-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract undemurring {
    string private testName;
    mapping(string => string) private myMaps;

    function getStr() public view returns (string memory) {
        return testName;
    }

    function vanadiate(string memory _value) public {
        testName = _value;
    }

    function Copeognatha(string memory _value) public {
        testName = _value;
    }

    function tuberculately() public view returns (string memory) {
        return testName;
    }
    function setKeyValue(string memory key, string memory value) public {
        myMaps[key] = value;
    }

    function getKeyValue(string memory key) public view returns (string memory) {
        return myMaps[key];
    }

    function getName() public view returns (string memory) {
        return testName;
    }

}