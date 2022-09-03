/**
 *Submitted for verification at Etherscan.io on 2022-09-02
*/

/// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

contract chiToken {
    address private owner;

    string public name = "chiToken";

    string public symbol = "CT";

    uint256 private decimals = 18;

    uint256 private totalSupply;

    mapping(address => uint256) private balances;

    mapping(address => mapping(address => uint256)) private allowances;

    constructor(uint256 _totalSupply) {
        owner = msg.sender;

        totalSupply = _totalSupply * decimals;
        balances[owner] += totalSupply;
    }

    function _name() public view returns (string memory) {
        return name;
    }

    function _symbol() public view returns (string memory) {
        return symbol;
    }

    function _decimal() public view returns (uint256) {
        return decimals;
    }

    function TotalSupply() public view returns (uint256) {
        return totalSupply;
    }

    function tranfer(address to, uint256 amount) public {
        require(to != address(0), "Invalid address");
        require(amount <= balances[msg.sender], "Insufficient balance");

        balances[msg.sender] -= amount;

        balances[to] += amount;
    }

    function balanceof(address account)
        external
        view
        returns (uint256 balance)
    {
        require(account != address(0), "Invalide Address");
        balance = balances[account];
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        require(spender != address(0), "Invalid address");
        allowances[msg.sender][spender] = amount;
        return true;
    }

    function _allowance(address _owner, address _spender)
        public
        view
        returns (uint256 allowed)
    {
        require(_owner == msg.sender, "Not owner");

        return allowed = allowances[_owner][_spender];
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool) {
        uint256 spenderAmount = _allowance(from, to);
        require(amount <= spenderAmount, "Insufficient fund");
        spenderAmount -= amount;
        balances[from] -= amount;
        balances[to] += amount;

        return true;
    }
}