/**
 *Submitted for verification at Etherscan.io on 2022-05-10
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.2;

contract Stuff {
  address public admin_address;
  uint256 public number_of_pings;
  bool public paused;

  mapping(address => string) public msgs;
  mapping(address => uint256) public numbers;

  modifier requireAdmin() {
    require(admin_address == msg.sender,"Requires admin privileges");
    _;
  }

  constructor() {
    admin_address = msg.sender;
    paused = true;
  }

  function changeMsg(string calldata m) public {
    require(!paused,"Contract is paused");
    msgs[msg.sender] = m;
  }

  function ping() public {
    require(!paused,"Contract is paused.");
    number_of_pings++;
  }
  function changeNumber(uint256 m) public {
    require(!paused,"Contract is paused");
    numbers[msg.sender] = m;
  }

  function deposit() public payable {
    require(!paused,"Contract is paused");
  }

function withdraw() public {
  require(!paused, "Contract is paused");
   require(address(this).balance > 0, "Contract is empty!");
    payable(msg.sender).transfer(address(this).balance);
  }

  

  function setPaused(bool p) public requireAdmin {
    paused = p;
  }


}