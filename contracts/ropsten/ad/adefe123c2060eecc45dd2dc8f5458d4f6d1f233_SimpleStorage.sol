/**
 *Submitted for verification at Etherscan.io on 2022-02-19
*/

// SPDX-License-Identifier: UNLICENSED

// language is SOLIDITY
// it's like javascript

// store a string
// retrieve a string

pragma solidity ^0.8.7;

contract SimpleStorage {

    string _storedData;
    uint _storedNumber;

    function set(uint  data) public {
        _storedNumber = data;
    }

    function get() public view returns (uint ){
        return _storedNumber;
    }

    function addone() public returns (uint ) {

        _storedNumber = _storedNumber + 1;
        return _storedNumber;
    }

}