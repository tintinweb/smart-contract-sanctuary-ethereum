// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract NorToken {

    string public name;
    string public symbol;
    uint256 public totalSupply;

    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowances;

    event Transfer(address from, address to, uint256 amount);
    event Deposit(address minter, uint256 amount);
    event Approve(address owner, address spender, uint256 amount);

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    function decimals() public pure returns(uint256) {
        return 8;
    }

    function balanceOf(address account) external view returns(uint256) {
        return balances[account];
    }

    function mint() external payable { 
        uint256 amount = msg.value;
        totalSupply += amount;
        balances[msg.sender] += amount;

        emit Deposit(msg.sender, msg.value);
        emit Transfer(address(this), msg.sender, amount);
    }

    function transfer(address to, uint256 amount) public {
        require(balances[msg.sender] >= amount, "Insufficient balance!");

        balances[msg.sender] -= amount;
        balances[to] += amount;

        emit Transfer(msg.sender, to, amount);
    } 

    function approve(address spender, uint256 amount) external {
        allowances[msg.sender][spender] = amount;

        emit Transfer(msg.sender, spender, amount);
    }

    function transferFrom(address from, address to, uint256 amount) external {
        require(balances[from] >= amount, "Not enough tokens!");
        require(allowances[from][msg.sender] >= amount, "Can't transfer more than the allowance!");

        allowances[from][msg.sender] -= amount;
        balances[from] -= amount;
        balances[to] += amount;

        emit Transfer(msg.sender, to, amount);
    }

}