/**
 *Submitted for verification at Etherscan.io on 2022-05-07
*/

pragma solidity >0.6.0;

contract Counter {
 uint256 number; 
 
 function addCount(uint256 num) public {
  number = num;
 } 
 
 function retrieveCount() public view returns (uint256){
  return number;
 }

}