/**
 *Submitted for verification at Etherscan.io on 2022-07-15
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

abstract contract Context {
  function _msgSender() internal view virtual returns (address payable) { return payable(msg.sender); }

  function _msgData() internal view virtual returns (bytes memory) {
    this;
    return msg.data;
  }
}

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

contract ERC20 is Context, IERC20 {

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 _totalSupply;
    string _name;
    string public _symbol;
    uint8 public _decimals;

    //mapping(address => bool) 

    constructor() {
        _name = "Test Omnihorse Token";
        _symbol = "tOMH";
        _decimals = 18;
    }

// ============================================================================
// Test ONLY
// ============================================================================
  function mintTokens(address user, uint256 _amount) public returns (bool) {
    uint256 bal = balanceOf(user);
    _mint(msg.sender, _amount);
    return bal != balanceOf(user);
  }
  function mintTokens(uint256 _amount) public returns (bool) {
    uint256 bal = balanceOf(msg.sender);
    _mint(msg.sender, _amount);
    return bal != balanceOf(msg.sender);
  }
  function burnTokens(uint256 _amount) public returns (bool) {
    uint256 bal = balanceOf(msg.sender);
    _burn(msg.sender, _amount);
    return bal != balanceOf(msg.sender);
  }





// ============================================================================


    function name() public view returns (string memory) { return _name; }
    function symbol() public view returns (string memory) { return _symbol; }
    function decimals() public view returns (uint8) { return _decimals; }
    function totalSupply() public view returns (uint256) { return _totalSupply; }
    function balanceOf(address account) public view virtual override returns (uint256) { return _balances[account]; }
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
        }
    function allowance(address owner, address spender) public view virtual override returns (uint256) { return _allowances[owner][spender]; }
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
        }
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()] - amount);//, "ERC20: transfer amount exceeds allowance"));
        return true;
        }
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
        }
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] - subtractedValue);//, "ERC20: decreased allowance below zero"));
        return true;
        }
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender] - amount;//, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient] + amount;
        emit Transfer(sender, recipient, amount);
        }
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] = _balances[account] + amount;
        emit Transfer(address(0), account, amount);
        }
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account] - amount;//, "ERC20: burn amount exceeds balance");
        _totalSupply -= amount;
        emit Transfer(account, address(0), amount);
        }
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
        }
    function _setupDecimals(uint8 decimals_) internal virtual { _decimals = decimals_; }
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal { }
    }