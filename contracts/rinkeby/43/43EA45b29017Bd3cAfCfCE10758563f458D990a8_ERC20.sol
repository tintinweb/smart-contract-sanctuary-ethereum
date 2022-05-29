// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ERC20 {
  uint256 public totalSupply;
  string public name;
  string public symbol;

  mapping (address => uint256) public balanceOf;
  mapping (address => mapping(address => uint256)) public allowance;

  event Transfer (address indexed from, address indexed to, uint256 value);
  event Approval (address indexed owner, address indexed spender, uint256 value);

  constructor(string memory _name, string memory _sybmol) {
    name = _name;
    symbol = _sybmol;

    _mint(msg.sender, 100e18);
  }

  function decimals() external pure returns (uint8) {
    return 18;
  }

  function transfer(address recepient, uint256 amount) external returns(bool) {
    return _transfer(msg.sender, recepient, amount);
  }

  function transferFrom(address sender, address recepient, uint256 amount) external returns(bool) {
    uint256 currentAllowance = allowance[sender][msg.sender];
    require(currentAllowance >= amount, "Not enough allowance");

    allowance[sender][msg.sender] -= amount;

    emit Approval(sender, msg.sender, allowance[sender][msg.sender]);

    return _transfer(msg.sender, recepient, amount);
  }

  function approve(address spender, uint256 amount) external returns(bool) {
    require(spender != address(0), "Spender cannot be the zero address");
    allowance[msg.sender][spender] = amount;

    emit Approval(msg.sender, spender, amount);

    return true;
  }

  function _transfer(address sender, address recepient, uint256 amount) private returns(bool) {
    require (recepient != address(0), 'ERC20: Transfer to zero address');

    uint256 senderBalance = balanceOf[sender];
    require (senderBalance >= amount, 'ERC20: Not enough funds');

    balanceOf[sender] -= amount;
    balanceOf[recepient] += amount;

    emit Transfer(sender, recepient, amount);

    return true;
  }

  function _mint(address to, uint256 amount) private returns(bool) {
    require(address(to) != address(0), "ERC20: Mint to zero address");
    balanceOf[to] += amount;
    totalSupply += amount;

    emit Transfer(address(0), to, amount);

    return true;
  }
}