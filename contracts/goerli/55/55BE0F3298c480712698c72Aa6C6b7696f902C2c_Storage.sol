/**
 *Submitted for verification at Etherscan.io on 2022-03-04
*/

pragma solidity ^0.4.17;

contract Storage {
  uint256 number;
  
  function store(uint256 num) public {
  	number = num;
  }

  function retrieve() public view returns (uint256){
	 return number;
  }
}