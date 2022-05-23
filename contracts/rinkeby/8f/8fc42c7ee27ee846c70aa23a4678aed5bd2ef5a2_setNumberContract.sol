/**
 *Submitted for verification at Etherscan.io on 2022-05-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract setNumberContract{
    address reserved;
    uint256 public number;
    
    function setNumber(uint256 _number) public {
        number = _number * 2;
    }
    // function showMeHash() public view returns (bytes32) {
    //     return(bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1));
    // }
   
}