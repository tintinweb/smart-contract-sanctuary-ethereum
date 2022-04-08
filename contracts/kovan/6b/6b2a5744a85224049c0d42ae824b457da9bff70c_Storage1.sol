/**
 *Submitted for verification at Etherscan.io on 2022-04-08
*/

pragma solidity ^0.4.17;

contract Storage1 {
  uint256 number;
  
  function store(uint256 num) public {
  	number = num;
  }

  function retrieve() public view returns (uint256){
	 return number + 1;
  }
}