//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Token {
    address public owner;
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    mapping(address =>uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;

    modifier ownerOnly() {
        require(msg.sender == owner, "You are not owner");
        _;
    }

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(
        string memory newName,
        string memory newSymbol,
        uint8 newDecimals,
        uint256 newTotalSupply
    )
    {
        name = newName;
        symbol = newSymbol;
        owner = msg.sender;
        decimals = newDecimals;
        totalSupply = newTotalSupply;
        balances[owner] = totalSupply;
        emit Transfer(address(0), owner, totalSupply);
    }

    function balanceOf(address account) public view returns (uint256){
        return balances[account];
    }

    function allowance(address owner, address spender) public view returns (uint256){
        return allowances[owner][spender];
    }

    function transfer(address to, uint256 value) public returns (bool success){
        require(balances[msg.sender] > value, "Not enough balance");
        balances[msg.sender] -= value;
        balances[to] += value;
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool success){
        require(balances[from] > value, "Not enough balance");
        balances[from] -= value;
        balances[to] += value;
        emit Transfer(from, to, value);
        return true;
    }
    
    function approve(address spender, uint256 value) public returns (bool success){
        require(balances[msg.sender] > value, "Not enough balance");
        allowances[msg.sender][spender] += value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function burn(address account, uint256 amount) public ownerOnly {
        require(account != address(0), "Zero address");
        require(balances[account] > amount, "Not enough balance");
        totalSupply -= amount;
        balances[account] -= amount;
        emit Transfer(account, address(0), amount);
    }

    function mint(address account, uint256 amount) public ownerOnly {
        require(account != address(0), "Zero address");
        totalSupply += amount;
        balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }
}