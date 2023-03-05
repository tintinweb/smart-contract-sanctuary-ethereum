//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;
contract VRF {
 function getRandomNumber() public view returns (uint) {
  //return a random number
  return uint(keccak256(abi.encodePacked(block.number,msg.sender)));
 }
}