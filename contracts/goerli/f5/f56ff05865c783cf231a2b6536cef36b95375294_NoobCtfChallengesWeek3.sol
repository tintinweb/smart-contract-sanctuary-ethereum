pragma solidity ^0.8.10;
/*
noob-ctf-challenges week 3
TWITTER:@definoobdao
alpha/dev/blockchain_security 
GITHUB: https://github.com/definoobdao/noob-ctf-challenges
*/
interface Inoobpoint {
    function sendpotion(address recipient, uint256 amount) external;
    function getnickname(address challenger) external returns(string memory);
}

contract ctf {
  mapping (address => bool) public isComplete;
  event CompleteCtflog(address indexed challenger, string nickname, string message);
  Inoobpoint public pointcontract;
}

contract NoobCtfChallengesWeek3 is ctf {
  constructor(address payable _pointcontract) public {
    pointcontract =  Inoobpoint(_pointcontract); 
  }

  function CompleteCtf() public {
    require(!isComplete[tx.origin]);
    require(msg.sender != tx.origin);
    isComplete[tx.origin] = true;
    pointcontract.sendpotion(tx.origin, 10);
    emit CompleteCtflog(tx.origin, pointcontract.getnickname(tx.origin) , "Complete Week 3 Challenge");
  }
}