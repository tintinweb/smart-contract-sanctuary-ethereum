/**
 *Submitted for verification at Etherscan.io on 2022-04-06
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;
contract SimpleStorage {
 uint256 _storedNumber;
 function set(uint256 data) public {
 _storedNumber = data;
 }
 function get() public view returns (uint256){
 return _storedNumber;
 }
 function addone() public returns (uint256) {
 _storedNumber = _storedNumber + 1;
 return _storedNumber;
 }
}