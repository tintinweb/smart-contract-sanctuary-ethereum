/**
 *Submitted for verification at Etherscan.io on 2022-06-25
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Faucet {
  
  uint sum;
  function withdraw(uint _amount) public {
    // users can only withdraw .1 ETH at a time, feel free to change this!
    require(_amount <= 100000000000000000);
    payable(msg.sender).transfer(_amount);
  }

  function addMe(uint x) public{
    sum +=x;
  }
  function returnSum() public view returns(uint){
    return sum;
  }
  // fallback function
  receive() external payable {}
}