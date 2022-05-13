//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract SuperToken {
  string  public name;
  string  public symbol;
  uint8 public decimals;
  uint256 public totalSupply;
  address private admin;

  event Transfer(
      address indexed _from,
      address indexed _to,
      uint256 _value
  );

  event Approval(
      address indexed _owner,
      address indexed _spender,
      uint256 _value
  );

  mapping(address => uint256) public balanceOf;
  mapping(address => mapping(address => uint256)) public allowance;

  constructor(string memory _name, string memory _symbol, uint8 _decimals) {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
    admin = msg.sender;
  }

  function transfer(address _to, uint256 _value) public returns (bool success) {
    require(_to != address(0), "Transfer to the zero address");
    require(balanceOf[msg.sender] >= _value, "Not enaught tokens");
    balanceOf[msg.sender] -= _value;
    balanceOf[_to] += _value;
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
    require(_from != address(0), "Transfer from the zero address");
    require(_to != address(0), "Transfer to the zero address");
    require(_value <= balanceOf[_from], "Not enaught tokens");
    require(_value <= allowance[_from][msg.sender], "There is no allowance of this transfer");
    balanceOf[_from] -= _value;
    balanceOf[_to] += _value;
    allowance[_from][msg.sender] -= _value;
    emit Transfer(_from, _to, _value);
    return true;
  }

  function approve(address _spender, uint256 _value) public returns (bool success) {
    require(_spender != address(0), "Approve for the zero address");
    allowance[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  function mint(address _account, uint256 _amount) public returns (bool success) {
    require(msg.sender == admin, "Mint by address without access");
    require(_account != address(0), "Mint to the zero address");
    totalSupply += _amount;
    balanceOf[_account] += _amount;
    emit Transfer(address(0), _account, _amount);
    return true;
  }

  function burn(address _account, uint256 _amount) public returns (bool success) {
    require((msg.sender == _account) || (msg.sender == admin), "Burn from address without access");
    require(_account != address(0), "Burn from the zero address");
    uint256 actualBalance = balanceOf[_account];
    require(actualBalance >= _amount, "Burn amount exceeds balance");
    balanceOf[_account] -= _amount;
    totalSupply -= _amount;
    emit Transfer(_account, address(0), _amount);
    return true;
  }
}