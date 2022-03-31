/**
 *Submitted for verification at Etherscan.io on 2022-03-31
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;
contract DevcVote {
  address public  owner;
  uint256 public winner;
  mapping(address =>bool ) public voted;
  mapping(uint256 => uint256) public voteIndex;
  bool public voteStatus = false;
  string[] public proposals;
    constructor(string[] memory proposalNames) {
       proposals = proposalNames;
      owner = msg.sender;
    }
   function vote(uint256 _value)  public {
     require(!voteStatus, "vote is closed");
     require(_value < proposals.length, "invalid input");
     require(!voted[msg.sender], "address already voted");
     voteIndex[_value]++;
     voted[msg.sender] = true;
   }
function closeVote() external {
require(msg.sender == owner, "caller cant be owner");
uint256 largest = 0;
  for(uint256 i = 0; i<proposals.length; i++) {
    if(voteIndex[i] > largest) {
      largest = i;
    }
  }
  winner = largest;
}
}