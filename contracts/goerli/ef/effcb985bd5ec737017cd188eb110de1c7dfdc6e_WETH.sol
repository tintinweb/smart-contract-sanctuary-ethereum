/**
 *Submitted for verification at Etherscan.io on 2022-11-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    event Transfer(address from, address to, uint amount);

    event Approval(address owner, address spender, uint amount);

    function totalSupply() external view returns (uint);
    
    function transfer(address to, uint amount) external returns (bool);

    function balanceOf(address user) external view returns (uint);

    function transferFrom(address from, address to, uint amount) external returns (bool);

    function approve(address spender, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);
}

abstract contract Context {
    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

    function _msgValue() internal view returns (uint) {
        return msg.value;
    }
}

contract ERC20 is Context, IERC20 {
    uint private _totalSupply;
    
    string private _name;
    string private _symbol;
    
    mapping (address => uint) private _balanceOf;
    mapping (address => mapping (address => uint)) private _allowances;
    
    constructor(string memory name_, string memory symbol_) {
    	_name = name_;
        _symbol = symbol_;
    }
    
    function _mint(address account, uint amount) internal {
        _totalSupply += amount;
        _balanceOf[account] += amount;
        
        emit Transfer(address(0), account, amount);
    }
    
    function _burn(address account, uint amount) internal {
    	require (_balanceOf[account] >= amount, "not enough money");
        _totalSupply -= amount;
        _balanceOf[account] -= amount;
        
        emit Transfer(account, address(0), amount);
    }

    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function decimals() external pure returns (uint) {
        return 18;
    }

    function totalSupply() external view returns (uint) {
        return _totalSupply;
    }

    function balanceOf(address user) external view returns (uint) {
        return _balanceOf[user];
    }

    function _transfer(address from, address to, uint amount) internal {
        require(from != address(0), "Invalid from");
        require(to != address(0), "Invalid to");

        uint fromBalance = _balanceOf[from];
        require(fromBalance >= amount, "Not enough money");

        unchecked {
            _balanceOf[from] = fromBalance - amount;
            _balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);
    }
    
    function transfer(address to, uint amount) external returns (bool) {
        address from = _msgSender();
        _transfer(from, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint amount) external returns (bool) {
        address spender = _msgSender();
        address owner = from;
        _spendAllowance(owner, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function approve(address spender, uint amount) external returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    function _approve(address owner, address spender, uint amount) internal {
        require (owner != address(0), "invalid owner");
        require (spender != address(0), "Invalid spender");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function allowance(address owner, address spender) public view returns (uint) {
        return _allowances[owner][spender];
    }

    function _spendAllowance(address owner, address spender, uint amount) internal {
        uint currentAllowance = allowance(owner, spender);
        require (currentAllowance >= amount, "not enough allowance");
        _approve(owner, spender, currentAllowance - amount);
    }
}

contract WETH is ERC20 {
    constructor() ERC20("Wrapped Ether", "WETH.Walter") {}

    event Deposit(address account, uint amount);
    event Withdraw(address account, uint amount);
    
    fallback() external payable {
        deposit();
    }
    
    function deposit() public payable {
        _mint(_msgSender(), _msgValue());
        emit Deposit(_msgSender(), _msgValue());
    }
    
    function withdraw(uint amount) public {
        _burn(_msgSender(), amount);
        payable(_msgSender()).transfer(amount);
        emit Withdraw(_msgSender(), amount);
    }
}