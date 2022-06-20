/**
 *Submitted for verification at Etherscan.io on 2022-06-20
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.16 <0.9.0;

contract SimpleStorage {
    uint storedData;
    string storedString;

    function set(uint x, string memory _storedString) public returns(uint, string memory) {
        storedData = x;
        storedString = _storedString;

        return (storedData, storedString);
    }

    function getInteger() public view returns (uint) {
        return storedData;
    }

    function getString() public view returns (string memory) {
        return storedString;
    }

    function getStaticValues() public pure returns(uint, string memory){
        return (2, "thisisstring");
    }

    function getStoredValues() public view returns(uint, string memory){
        return (storedData, storedString);
    }

    function setInteger(uint x) public returns(uint) {
        storedData = x;
        return storedData;
    }

    function setString(string memory _storedString) public returns(string memory) {
        storedString = _storedString;
        return storedString;
    }
}