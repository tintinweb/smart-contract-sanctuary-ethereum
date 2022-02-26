//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract ERC20 {
    string private _name;

    string private _symbol;

    uint private _totalSupply;

    uint private _decimals;

    address private _owner;

    mapping(address => uint) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    constructor(string memory name_, string memory symbol_, uint decimals_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        _owner = msg.sender;
    }

    function name() public view returns (string memory){
        return _name;
    }

    function symbol() public view returns (string memory){
        return _symbol;
    }

    function decimals() public view returns (uint){
        return _decimals;
    }

    function totalSupply() external view returns (uint) {
        return _totalSupply;
    }

    function balanceOf(address account) external view returns (uint) {
        return _balances[account];
    }

    function transfer(address recipient, uint amount) external {
        require(recipient != address(0), "transfer to the zero address");
        require(_balances[msg.sender] >= amount, "insufficient balance");

        _transfer(msg.sender, recipient, amount);
    }

    function allowance(address owner, address  spender) external view returns (uint) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint amount) external returns (bool) {
        _approve(spender, amount);
        return true;
    }

    function increaseAllowance(address spender, uint amount) external returns (bool) {
        _approve(spender, _allowances[msg.sender][spender] + amount);
        return true;
    }

    function decreaseAllowance(address spender, uint amount) external returns (bool) {
        require(_allowances[msg.sender][spender] >= amount, "dont have amount");
        _approve(spender, _allowances[msg.sender][spender] - amount);
        return true;
    }

    function _approve(address spender, uint amount) private {
        require(spender != address(0), "approve to the zero address");

        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
    }

    function transferFrom(address sender, address recipient, uint amount) external returns (bool) {
        require(sender != address(0), "transfer from the zero address");
        require(recipient != address(0), "transfer to the zero address");
        require(_allowances[sender][msg.sender] >= amount, "insufficient balance allowances");
        require(_balances[sender] >= amount, "insufficient balance sender");

        _allowances[sender][msg.sender] -= amount;

        _transfer(sender, recipient, amount);

        return true;
    }

    function _transfer(address sender, address recipient, uint amount) internal {

        _balances[sender] -= amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function mint(address account, uint amount) public {
        require(msg.sender == _owner, "Not owner");
        require(account != address(0), "mint to the zero address");

        _balances[account] += amount;
        _totalSupply += amount;

        emit Transfer(address(0), account, amount);
    }

    function burn(address account, uint amount) external virtual {
        require(msg.sender == _owner, "Not owner");
        require(account != address(0), "burn to the zero address");
        require(_balances[account] >= amount, "insufficient balance");

        _balances[account] -= amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}