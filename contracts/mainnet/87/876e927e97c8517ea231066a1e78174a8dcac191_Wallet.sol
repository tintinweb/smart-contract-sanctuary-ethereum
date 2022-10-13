/**
 *Submitted for verification at Etherscan.io on 2022-10-13
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract Wallet {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor() {
    emit OwnershipTransferred(address(0), msg.sender);
    owner = msg.sender;
  }

  receive() external payable {}

  function invoke(address payable _to, uint _value, bytes memory _payload) public onlyOwner returns (bytes memory) {
    (bool success, bytes memory returnData) = _to.call{value: _value}(_payload);
    require(success, "Transaction failed, aborting");
    return returnData;
  }

  modifier onlyOwner() {
    require(owner == msg.sender, "Ownable: caller is not the owner");
    _;
  }

  function transferOwnership(address newOwner) public virtual onlyOwner {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}