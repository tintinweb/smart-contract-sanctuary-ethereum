// SPDX-License-Identifier: Unlicense
// sample contract address on Goerli : 0xDBa03676a2fBb6711CB652beF5B7416A53c1421D
// contract address on Goerli : 0xdA5B8A7db2d47F593C8217c4e9A65a35A4C17a6F
pragma solidity ^0.8.7;

contract BuyMeACoffee {
  event NewMemo(address indexed from, uint256 timestamp, string name, string message);

  struct Memo {
    address from;
    uint256 timestamp;
    string name;
    string message;
  }

  address payable owner;
  Memo[] memos;

  constructor() {
    owner = payable(msg.sender);
  }

  function getMemos() public view returns (Memo[] memory) {
    return memos;
  }

  function buyCoffee(string memory _name, string memory _message) public payable {
    require(msg.value > 0, "can't buy coffee for free!");
    memos.push(Memo(msg.sender, block.timestamp, _name, _message));
    emit NewMemo(msg.sender, block.timestamp, _name, _message);
  }

  // fetch the entire balance stored in contract to the owner
  function withdrawTips() public {
    require(owner.send(address(this).balance));
  }
}