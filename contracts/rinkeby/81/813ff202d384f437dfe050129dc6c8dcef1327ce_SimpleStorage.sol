/**
 *Submitted for verification at Etherscan.io on 2022-04-12
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract SimpleStorage {
    uint256 public myUint = 10;
    
    function changeValue(uint256 _newUint) public { 
        myUint = _newUint;
    }

    function retrieveValue() public view returns (uint256) {
        return myUint;
    }
}