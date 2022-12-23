/**
 *Submitted for verification at Etherscan.io on 2022-12-23
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract StoreValue {
    uint256 myValue;

    function store(uint256 _myValue) public {
        myValue = _myValue;
    }

    function retrieve() public view returns (uint256) {
        return myValue;
    }
}