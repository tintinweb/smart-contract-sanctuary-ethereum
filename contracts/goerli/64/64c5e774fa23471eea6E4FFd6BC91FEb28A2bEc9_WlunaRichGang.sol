/**
 *Submitted for verification at Etherscan.io on 2022-07-07
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

contract WlunaRichGang {

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    address private _contractOwner;
    uint256 private _totalSupply;
    uint256 private _maxSupply;
    uint256 private _minSupply;
    uint private etherBalance;
    
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Bought(address indexed from, address indexed to, uint256 amount);

    /* Initializes contract with initial supply tokens to the creator of the contract */
    constructor (string memory name_, string memory symbol_, uint8 decimals_, uint256 totalSupply_, uint256 maxSupply_, uint256 minSupply_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        _contractOwner = msg.sender;
        _totalSupply = totalSupply_;
        _maxSupply = maxSupply_;
        _minSupply = minSupply_;
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
        return _contractOwner;
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

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     */
    function transfer(address to, uint256 value) external returns (bool) {
        if(to == _contractOwner) {
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

    /**
     * @dev Burns a specific amount of tokens.
     * @param value The amount of lowest token units to be burned.
     */
    function burn(uint256 value) public {
        require(_msgSender() != address(0), "ERC20: burn from the zero address");
        require(_totalSupply > _minSupply, "ERC20: can not burn more tokens");
        require(_totalSupply - value >= _minSupply, "ERC20: can not burn more tokens");
        uint256 accountBalance = _balances[_msgSender()];
        require(accountBalance >= value, "ERC20: burn value exceeds balance");
        _balances[_msgSender()] = accountBalance - value;
        _totalSupply -= value;

        emit Burn(_msgSender(), address(0), value);
    }

    /**
     * @dev Buys a specific amount of tokens.
     */
    function buyTokensForEther() public payable {
        require(_msgSender() != _contractOwner);
        require(_msgSender() != address(0));
        require(_totalSupply < _maxSupply, "ERC20: can not buy more tokens");
        require(_totalSupply >= _minSupply * 10, "ERC20: can not buy more tokens");
        etherBalance += msg.value;
        _totalSupply += msg.value * 10000;
        _balances[_msgSender()] += msg.value * 10000;
        emit Bought(address(0), _msgSender(), msg.value * 10000);
    }

    /**
     * @dev Withdraw a specific amount of Ether to owner account. Allowed only to owner.
     * @param value The amount of Ether.
     */
    function withdrawEther(uint256 value) public {
        require(_msgSender() == _contractOwner, "ERC20: only for owner allowed");
        address payable to = payable(_contractOwner);
        to.transfer(value);
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