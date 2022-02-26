/**
 *Submitted for verification at Etherscan.io on 2022-02-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleWallet {
  address public owner;
  string public message = "Hello";

  event Update( address sender, string message );
  event Withdraw( address sender, uint amount);

  modifier onlyOwner(){
    require(msg.sender == owner, "Not Owner");
    _;
  }

  constructor() {
    owner = msg.sender;
  }

  receive() external payable {
  }

  function setMessage(string calldata _msg) external {
    message = _msg;
    emit Update(msg.sender, _msg);
  }

  function getBalance() external view returns (uint) {
    return address(this).balance;
  }

  function withdraw() external onlyOwner {
    uint amount = address(this).balance;
    payable(owner).transfer(amount);
    emit Withdraw(msg.sender, amount);
  }


}