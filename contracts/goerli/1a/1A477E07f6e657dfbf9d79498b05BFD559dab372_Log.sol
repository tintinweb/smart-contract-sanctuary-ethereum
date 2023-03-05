/**
 *Submitted for verification at Etherscan.io on 2023-03-05
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.20 <0.5;
//import "hardhat/console.sol";

contract Log {
  address private owner;
  address private ethAddress;

  struct Message {
    address sender;
    uint256 amount;
    string note;
  }

  Message[] History;
  Message public LastLine;

  constructor() public {
    owner = msg.sender;
    ethAddress = msg.sender;
  }

  function changeEthAddress(address _addr) public{
    require(msg.sender == owner);
    ethAddress = _addr;
  }

  function LogTransfer(address _sender, uint256 _amount, string memory _note) public{
    if (keccak256(abi.encodePacked(_note)) == keccak256("withdraw")) {
      require(_sender == ethAddress);
    }
    LastLine.sender = _sender;
    LastLine.amount = _amount;
    LastLine.note = _note;
    History.push(LastLine);
  }
}