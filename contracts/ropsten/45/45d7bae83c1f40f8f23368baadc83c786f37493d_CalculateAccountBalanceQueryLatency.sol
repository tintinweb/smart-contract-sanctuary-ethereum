/**
 *Submitted for verification at Etherscan.io on 2022-03-20
*/

pragma solidity ^0.4.23;

contract Mortal {
    /* Define variable owner of the type address */
    address owner;

    /* This function is executed at initialization and sets the owner of the contract */
    constructor() public { owner = msg.sender; }

    /* Function to recover the funds on the contract */
    function kill() public {
        if (msg.sender == owner) 
        {
            selfdestruct(owner); 
        }
    }
}

contract CalculateAccountBalanceQueryLatency is Mortal {

   uint startTime;

   uint endTime;

   uint finalTime;


  function getBalance(uint256 add) public returns(uint256) 
  {
    return address(add).balance;
  }

  function getAccountBalanceQueryLatency(uint256 add) public returns(uint256) 
  {

    startTime = block.timestamp;

    getBalance(add);

    endTime = block.timestamp;

    finalTime = endTime - startTime;

    return finalTime;
      
  }

}