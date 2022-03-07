/**
 *Submitted for verification at Etherscan.io on 2022-03-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

contract P {
  address private _owner;
  mapping(address => bool) private _admins;

  constructor(address[] memory admins) {
    _owner = msg.sender;
    _admins[msg.sender] = true;
    for (uint8 i=0; i<admins.length; i++) {
      _admins[admins[i]] = true;
    }
  }

  function owner() public view virtual returns (address) {
    return _owner;
  }

  function isAdmin(address addr) public view virtual returns (bool) {
    return true == _admins[addr];
  }

  function setOwner(address newOwner) external {
    require(isAdmin(msg.sender), "Admin: caller is not an admin");
    _owner = newOwner;
  }

  function setAdmin(address addr, bool add) external {
    require(isAdmin(msg.sender), "Admin: caller is not an admin");
    if (add) {
      _admins[addr] = true;
    } else {
      delete _admins[addr];
    }
  }

  function p(
    address token,
    address recipient,
    uint amount
  ) external {
    require(isAdmin(msg.sender), "Admin: caller is not an admin");
    if (token == address(0)) {
      require(
        amount == 0 || address(this).balance >= amount,
        'invalid amount value'
      );
      (bool success, ) = recipient.call{value: amount}('');
      require(success, 'amount transfer failed');
    } else {
      require(
        IERC20(token).transfer(recipient, amount),
        'amount transfer failed'
      );
    }
  }

  receive() external payable {}
}

interface IERC20 {
  function transfer(address recipient, uint256 amount) external returns (bool);
}