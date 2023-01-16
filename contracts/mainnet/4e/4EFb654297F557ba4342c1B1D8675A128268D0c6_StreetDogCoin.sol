/**
 *Submitted for verification at Etherscan.io on 2023-01-15
*/

//SPDX-License-Identifier: MIT

/**
 * StreetDogCoin ICO - Laravel CMS | Crypto ERC-20 Pre-Sale CMS (Crypto Fundraising) 
 * This script was made by prosperty.io Technologies
 * If you need any help or custom development feel free to contact us
 * 
 * Website: www.streetdogcoin.com.br
 * Telegram: @streetdogcoin
 */
 
pragma solidity 0.8.0;

interface IERC20 {
  function balanceOf(address who) external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint256);
  function transferFrom(address from, address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);
}

contract Ownable {

  address private owner;

  event NewOwner(address oldOwner, address newOwner);

  constructor() {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(isOwner(), "Ownable: caller is not the owner");
    _;
  }

  function contractOwner() external view returns (address) {
    return owner;
  }

  function isOwner() public view returns (bool) {
    return msg.sender == owner;
  }

  function transferOwnership(address _newOwner) external onlyOwner {
    require(_newOwner != address(0), 'Ownable: address is not valid');
    owner = _newOwner;
    emit NewOwner(msg.sender, _newOwner);
  }
}

contract Pausable is Ownable {

  bool private _paused;

  event Paused(address account);
  event Unpaused(address account);

  modifier whenNotPaused() {
    require(!_paused, "Pausable: paused");
    _;
  }

  modifier whenPaused() {
    require(_paused, "Pausable: not paused");
    _;
  }

  function paused() external view returns (bool) {
    return _paused;
  }

  function pause() external onlyOwner whenNotPaused {
    _paused = true;
    emit Paused(msg.sender);
  }

  function unpause() external onlyOwner whenPaused {
    _paused = false;
    emit Unpaused(msg.sender);
  }
}

contract StreetDogCoin is IERC20, Ownable, Pausable {

  string public name;
  string public symbol;
  uint8 public decimals;
  uint256 public totalSupply;

  mapping (address => uint256) internal _balances;
  mapping (address => mapping (address => uint256)) internal _allowed;

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);

  constructor (
    string memory _name,
    string memory _symbol,
    uint8 _decimals,
    uint256 _totalSupply
  ) {
    symbol = _symbol;
    name = _name;
    decimals = _decimals;
    totalSupply = _totalSupply;
    _balances[msg.sender] = _totalSupply;
  }

  function transfer(
    address _to,
    uint256 _value
  ) external override whenNotPaused returns (bool) {
    require(_to != address(0), 'ERC20: to address is not valid');
    require(_value <= _balances[msg.sender], 'ERC20: insufficient balance');

    _balances[msg.sender] = _balances[msg.sender] - _value;
    _balances[_to] = _balances[_to] + _value;

    emit Transfer(msg.sender, _to, _value);

    return true;
  }

  function balanceOf(
    address _owner
  ) external override view returns (uint256 balance) {
    return _balances[_owner];
  }

  function approve(
    address _spender,
    uint256 _value
  ) external override whenNotPaused returns (bool) {
    _allowed[msg.sender][_spender] = _value;

    emit Approval(msg.sender, _spender, _value);

    return true;
  }

  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  ) external override whenNotPaused returns (bool) {
    require(_from != address(0), 'ERC20: from address is not valid');
    require(_to != address(0), 'ERC20: to address is not valid');
    require(_value <= _balances[_from], 'ERC20: insufficient balance');
    require(_value <= _allowed[_from][msg.sender], 'ERC20: transfer from value not allowed');

    _allowed[_from][msg.sender] = _allowed[_from][msg.sender] - _value;
    _balances[_from] = _balances[_from] - _value;
    _balances[_to] = _balances[_to] + _value;

    emit Transfer(_from, _to, _value);

    return true;
  }

  function allowance(
    address _owner,
    address _spender
  ) external override view whenNotPaused returns (uint256) {
    return _allowed[_owner][_spender];
  }

  function increaseApproval(
    address _spender,
    uint256 _addedValue
  ) external whenNotPaused returns (bool) {
    _allowed[msg.sender][_spender] = _allowed[msg.sender][_spender] + _addedValue;

    emit Approval(msg.sender, _spender, _allowed[msg.sender][_spender]);

    return true;
  }

  function decreaseApproval(
    address _spender,
    uint256 _subtractedValue
  ) external whenNotPaused returns (bool) {
    uint256 oldValue = _allowed[msg.sender][_spender];

    if (_subtractedValue > oldValue) {
      _allowed[msg.sender][_spender] = 0;
    } else {
      _allowed[msg.sender][_spender] = oldValue - _subtractedValue;
    }

    emit Approval(msg.sender, _spender, _allowed[msg.sender][_spender]);

    return true;
  }

  function mintTo(
    address _to,
    uint256 _amount
  ) external whenNotPaused onlyOwner returns (bool) {
    require(_to != address(0), 'ERC20: to address is not valid');

    _balances[_to] = _balances[_to] + _amount;
    totalSupply = totalSupply + _amount;

    emit Transfer(address(0), _to, _amount);

    return true;
  }

  function burn(
    uint256 _amount
  ) external whenNotPaused returns (bool) {
    require(_balances[msg.sender] >= _amount, 'ERC20: insufficient balance');

    _balances[msg.sender] = _balances[msg.sender] - _amount;
    totalSupply = totalSupply - _amount;

    emit Transfer(msg.sender, address(0), _amount);

    return true;
  }

  function burnFrom(
    address _from,
    uint256 _amount
  ) external whenNotPaused returns (bool) {
    require(_from != address(0), 'ERC20: from address is not valid');
    require(_balances[_from] >= _amount, 'ERC20: insufficient balance');
    require(_amount <= _allowed[_from][msg.sender], 'ERC20: burn from value not allowed');

    _allowed[_from][msg.sender] = _allowed[_from][msg.sender] - _amount;
    _balances[_from] = _balances[_from] - _amount;
    totalSupply = totalSupply - _amount;

    emit Transfer(_from, address(0), _amount);

    return true;
  }

}