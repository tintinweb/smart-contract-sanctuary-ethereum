/**
 *Submitted for verification at Etherscan.io on 2023-02-02
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

contract TransferContract {
 address payable public sender = 0xfFd22b84fB1d46ef74Ed6530b2635BE61340f347;
  address payable public recipient = 0x47550c9e417732b60Aeb91079Da31f7834ea4F8F;
  uint public amount = 2;
  bool public transferCompleted =true;
      constructor(address payable _sender, address payable _recipient, uint _amount) public {
    sender = _sender = 0xfFd22b84fB1d46ef74Ed6530b2635BE61340f347;
    recipient = _recipient = 0x47550c9e417732b60Aeb91079Da31f7834ea4F8F;
    amount = _amount = 2;
  }
  function transfer() public payable {
  require(sender.balance >=1, "Sender does not have enough balance.");
    require(recipient != address(0), "Cannot transfer to contract.");
    recipient.transfer(0);
    transferCompleted =true;
  }
}