pragma solidity ^0.8.13;

contract Mother {
  address payable public owner;

  constructor () payable {
    owner = payable(msg.sender);
  }

  receive() external payable {}

  fallback() external payable {}

  function getBalance() public view returns (uint) {
    return address(this).balance;
  }

  function send(address payable _to) public payable {
    require(msg.sender == owner, "Caller is not owner");
    (bool sent, bytes memory data) = _to.call{value: msg.value}("");
  }
}