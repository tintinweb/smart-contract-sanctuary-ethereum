// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.7;

contract BuyMeACoffee {
  address payable owner;
  struct Memo {
    address from;
    uint256 timestamp;
    string name;
    string message;
  }
  Memo[] memos;

  event NewMemo(
    address indexed from, 
    uint256 timestamp, 
    string name, 
    string message
  );

  constructor() { owner = payable(msg.sender); }

  function getMemos() public view returns (Memo[] memory) { return memos; }

  function buyCoffee(string memory _name, string memory _message) public payable {
    require(msg.value > 0, "pls pay 0.001 ETH");
    memos.push(Memo(msg.sender, block.timestamp, _name, _message));
    emit NewMemo(msg.sender, block.timestamp, _name, _message);
  }

  function withdrawTips() public {
    require(owner.send(address(this).balance));
  }
}