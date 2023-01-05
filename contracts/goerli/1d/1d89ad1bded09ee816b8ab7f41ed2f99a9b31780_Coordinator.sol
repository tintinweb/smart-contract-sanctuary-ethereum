/**
 *Submitted for verification at Etherscan.io on 2023-01-05
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

contract Coordinator {
  uint256 public endOfCommitRequest; //voting time
  uint256 public commitCounter; //count commit votings of participants 
  uint256 public abortCounter; //count abort votings of participants
  uint public balance; //contract balance
  address private owner; //owner of the contract

  //constructor gets called with the initial transaction to publish the Coordinator contract
  constructor() payable { 
    owner = msg.sender;
  }

  fallback() external payable {
    add(balance,msg.value);
  }

  receive() external payable {
    add(balance,msg.value); 
  } 
  
  function setVotingTime(uint256 _endOfCommitRequest) public onlyOwner onlyAfterCommitPhase {
    commitCounter=0; 
    abortCounter=0; 
    endOfCommitRequest = _endOfCommitRequest; //set a voting time
  }

  //receive the votings of the participants and count the results
  function commitRequest(bool _agreement) public view onlyBeforeEndOfCommitRequest {  
    if(_agreement) { 
      add(commitCounter,1); //no integer overflow possible 
    } else {
      add(abortCounter,1); //no integer overflow possible
    }  
  }
  
  function commit(address payable _receiver, uint256 _amount) public onlyAfterCommitPhase { 
    require(address(this).balance >= _amount, "Address: insufficient balance");
    if(abortCounter==0) { //continue if no participant voted against the transaction
        require(_receiver != address(0)); //we do not want to send ether to the zero address 
        bool success;
        bytes memory status;
        (success, status) = _receiver.call{value: _amount}("");
        require(success, "Transfer failed");
      
    } else { //else automatically rollback the transaction and refund the remaining gas
        revert("At least one participant voted against the transaction"); 
    }   
  }

  //SafeMath add function to prevent integer overflows
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "addition overflow");
    return c;
  }

  //require that the voting time is somewhere in the future   
  modifier onlyBeforeEndOfCommitRequest() {
    require(block.timestamp < endOfCommitRequest, "the voting needs to be somewhere in the future");
    _;  
  }

  //require that the contract only proceeds with the transaction after the voting phase
  modifier onlyAfterCommitPhase() {
    require(block.timestamp > endOfCommitRequest, "the voting phase has not ended yet");  
    _;  
  }

  modifier onlyOwner() {
    require(msg.sender==owner);
    _;    
  }    
}