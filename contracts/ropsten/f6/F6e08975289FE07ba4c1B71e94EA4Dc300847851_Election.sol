// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Election {
  uint256 public votingTime = 1659881500;  // Votings ends in ~8 minutes.
  string public winner;
  uint public id;
  struct Candidate{
    uint id;
    string name;
    uint votes;
  }
  uint[] public loop;
  
  mapping(uint=>Candidate) public candidates;
  mapping(address=>bool) public voted;

  //tested
  modifier alreadyVoted{
    require(!voted[msg.sender]);           // Check if msg.sender already voted.
    require(block.timestamp < votingTime); // Check if voting duration already finished.
    _;
  }

  //tested
  constructor(){
    increment();
    candidates[id] = Candidate(id,"First Candidate",0);
    increment();
    candidates[id] = Candidate(id,"Second Candidate",0);
  }

  //tested
  function addCandidate(string memory _name) public{
    increment();
    candidates[id] = Candidate(id,_name,0);
  }

  //tested
  function increment() private{
    id += 1;
    loop.push(id);
  }

  //tested
  function vote(uint _choice) public alreadyVoted{
    voted[msg.sender] = true;
    for( uint i = 0; i<loop.length; i++ ){
      if (loop[i] == _choice){
        candidates[loop[i]].votes += 1;
        break;
      }
    }
  }
  //tested
  function checkVotes(uint _id) view public returns (uint _num){
    for( uint i = 0; i < loop.length; i++){
      if(loop[i]== _id){
        _num = candidates[loop[i]].votes;
        break;
      }
    }
    return _num;
  }
  //tested
  function assignWinner(uint _check) public{
    require(block.timestamp > votingTime);
    require(_check==1);
    uint g = candidates[loop[0]].votes;
    for( uint y = 0; y < loop.length; y++){
      if(g < candidates[loop[y]].votes){
        g = candidates[loop[y]].votes;
      }
    } 
    for( uint y = 0 ; y < loop.length; y++){
      if(candidates[loop[y]].votes == g){
        winner = candidates[loop[y]].name;
      }
    }
  }
}