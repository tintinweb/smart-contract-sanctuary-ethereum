/**
 *Submitted for verification at Etherscan.io on 2022-07-06
*/

// SPDX-License-Identifier: MIT
// File: openzeppelin-solidity/contracts/token/ERC20/IERC20.sol
// File: openzeppelin-solidity/contracts/utils/Context.sol
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.7;

contract ERC20 {

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    address private _burnWallet;
    address private _contractOwner;
    uint256 private _totalSupply;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /* Initializes contract with initial supply tokens to the creator of the contract */
    constructor (string memory name_, string memory symbol_, uint8 decimals_, address burnWallet_, uint256 totalSupply_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        _burnWallet = burnWallet_;
        _contractOwner = msg.sender;
        _totalSupply = totalSupply_;
        _balances[msg.sender] = _totalSupply;
    }

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    function burnWallet() public view virtual returns (address) {
        return _burnWallet;
    }

    function contractOwner() public view virtual returns (address) {
        return _contractOwner;
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    /* Send coins */
    function transfer(address to, uint256 value) external returns (bool) {
        if(to == _burnWallet) {
          burn(value);
          emit Burn(_msgSender(), to, value);
        } else {
          _transfer(_msgSender(), to, value);
        }
        return true;
    }

    function _transfer(address from, address to, uint256 value) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");     // Prevent transfer from 0x0 address. Use burn() instead
        require(to != address(0), "ERC20: transfer to the zero address");    // Prevent transfer to 0x0 address
        uint256 senderBalance = _balances[from];
        require(senderBalance >= value, "ERC20: transfer value exceeds balance"); // Prevent transfer to 0x0 address
        _balances[from] = senderBalance - value;
        _balances[to] += value;

        emit Transfer(from, to, value);
    }

    /* Burn coins */
    function burn(uint256 value) public {
        require(_msgSender() != address(0), "ERC20: burn from the zero address");
        uint256 accountBalance = _balances[_msgSender()];
        require(accountBalance >= value, "ERC20: burn value exceeds balance");
        _balances[_msgSender()] = accountBalance - value;
        _totalSupply -= value;

        emit Burn(_msgSender(), address(0), value);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    function allowance(address owner, address spender) external view returns (uint256) {
        return _allowances[owner][spender];
    }
    
    function approve(address spender, uint256 amount) external returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
}