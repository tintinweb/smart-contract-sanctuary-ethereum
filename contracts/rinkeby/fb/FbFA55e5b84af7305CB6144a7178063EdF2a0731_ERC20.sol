/**
 *Submitted for verification at Etherscan.io on 2022-05-28
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

contract ERC20 {
  uint256 public totalSupply;
  string public name;
  string public symbol;

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);

  mapping(address => uint256) public balanceOf;
  mapping(address => mapping(address => uint256)) public allowance;

  constructor(string memory _name, string memory _symbol) {
    name = _name;
    symbol = _symbol;

    _mint(msg.sender, 100e18);
  }

  function decimals() external pure returns (uint8) {
    return 18;
  }

  function transfer(address recipient, uint256 amount) external returns(bool) {
    return _transfer(msg.sender, recipient, amount);
  }

  function transferFrom(address sender, address recipient, uint256 amount) external returns(bool) {
    uint256 currentAllowance = allowance[sender][msg.sender];

    require(currentAllowance >= amount, "Amount exceeds allowance");

    allowance[sender][msg.sender] = currentAllowance - amount;

    emit Approval(sender, msg.sender, amount);

    return _transfer(sender, recipient, amount);
  }

  function approve(address spender, uint256 amount) external returns(bool) {
    require(spender != address(0), "Approve to zero address");

    allowance[msg.sender][spender] = amount;

    emit Approval(msg.sender, spender, amount);

    return true;
  }

  function _transfer(address sender, address recipient, uint256 amount) private returns(bool) {
    require(recipient != address(0), "Transfer to the zero address");

    uint256 senderBalance = balanceOf[sender];

    require(senderBalance >= amount, "Transfer amount exceeds balance");

    balanceOf[sender] = senderBalance - amount;
    balanceOf[recipient] += amount;

    emit Transfer(sender, recipient, amount);

    return true;
  }

  function _mint(address to, uint256 amount) internal {
    require(to != address(0), "Approve to zero address");

    totalSupply += amount;
    balanceOf[to] += amount;

    emit Transfer(address(0), to, amount);
  }
}