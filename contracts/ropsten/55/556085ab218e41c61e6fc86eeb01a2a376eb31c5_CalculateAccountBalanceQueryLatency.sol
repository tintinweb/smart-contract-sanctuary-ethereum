/**
 *Submitted for verification at Etherscan.io on 2022-03-20
*/

pragma solidity ^0.8.13;

contract CalculateAccountBalanceQueryLatency {

   uint startTime;

   uint endTime;

   uint finalTime;


  function getBalance() public returns(uint256) 
  {
    return address(this).balance;
  }

  function getAccountBalanceQueryLatency() public returns(uint256) 
  {

    startTime = block.timestamp;

    getBalance();

    endTime = block.timestamp;

    finalTime = endTime - startTime;

    return finalTime;
      
  }

}