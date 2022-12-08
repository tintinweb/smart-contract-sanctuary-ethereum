/**
 *Submitted for verification at Etherscan.io on 2022-12-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract ERC20{
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }
    modifier checkTransfer(address from, address to, uint256 amount){
        require(from != to, "Cannot Transfer to Yourself");
        require(amount!=0, "Amount cannot be Zero");
        _;
    }
    function name() public view virtual  returns (string memory) {
        return _name;
    }
    function symbol() public view virtual  returns (string memory) {
        return _symbol;
    }
    function decimals() public view virtual  returns (uint8) {
        return 18;
    }
    function totalSupply() public view virtual  returns (uint256) {
        return _totalSupply;
    }
    function balanceOf(address account) public view virtual  returns (uint256) {
        return _balances[account];
    }
    function allowance(address owner, address spender) public view virtual  returns (uint256) {
        return _allowances[owner][spender];
    }
    
    function transfer(address to, uint256 amount) public virtual  returns (bool) {
        address owner = msg.sender;
        _transfer(owner, to, amount);
        return true;
    }
    function approve(address spender, uint256 amount) public virtual  returns (bool) {
        address owner = msg.sender;
        _approve(owner, spender, amount);
        return true;
    }
    function transferFrom(address from, address to, uint256 amount) public virtual returns (bool) {
        address spender = msg.sender;
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }
    
    function _transfer(address from, address to, uint256 amount) internal virtual checkTransfer(from, to, amount){
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        
        _balances[from] = fromBalance - amount;
        // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
        // decrementing then incrementing.
        _balances[to] += amount;
        emit Transfer(from, to, amount);
    }
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        require(balanceOf(msg.sender)>=amount, "ERC20: You don't have enough tokens to approve");
        _allowances[owner][spender] += amount;
        emit Approval(owner, spender, amount);
    }
    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: Insufficient Allowance");
            _allowances[owner][spender] -= amount;
        }
    }
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);
    }
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");
        uint256 accountBalance = _balances[account];
        require(accountBalance > amount, "ERC20: burn amount exceeds balance");
        unchecked {
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _balances[account] = accountBalance - amount;
            _totalSupply -= amount;
        }
        emit Transfer(account, address(0), amount);
    }
}

// ----------------------------------------------------CODEBIRD ERC20 CONTRACT----------------------------------------------------------- 
contract Codebird_Token is ERC20{
    address public owner;
    uint8 private immutable _decimal;
    uint256 private immutable _cap;

    constructor(string memory tokenName, string memory tokenSymbol, uint8 decimal, uint initalOwnerSupply, uint supplyCap) 
    ERC20(tokenName, tokenSymbol) {
        _decimal = decimal;
        require(supplyCap > 0, "Suppy Cap should be greater than 0");
        _cap = supplyCap*(10**decimals());
        owner = msg.sender;
        _mint(owner, initalOwnerSupply * (10**decimals()));
    }
    function decimals() public view override returns (uint8) {
        return _decimal;
    }
    function cap() public view virtual returns (uint256) {
        return _cap;
    }
    function _mint(address account, uint256 amount) internal virtual override {
        require((ERC20.totalSupply() + amount) <= cap(), "Cap Exceeded");
        super._mint(account, amount);
    }
    modifier onlyOwner{
        require(msg.sender == owner, "Only OWNER can MINT or BURN");
        _;
    }

    function mint(address to_account, uint256 amount) public onlyOwner {
        _mint(to_account, amount);
    }
    function burn(address from_account, uint256 amount) public onlyOwner{
        _burn(from_account, amount);
    }
}