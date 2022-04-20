/**
 *Submitted for verification at Etherscan.io on 2022-04-20
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.2;

contract Test {
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    
    string public name = "Test";
    string public symbol = "TST";
    uint public totalSupply = 10000000 * 10 ** 18;
    uint public decimals = 18;
    address public owner;
    address private newOwner;
    address private oldOwner;
    bool public tradingEnabled = false;
    bool public limitsInEffect = true;
    uint256 public whitelistDisabledTimestamp = 0;
    
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);
    event BurnTokens(address indexed from, address indexed to, uint value);
    event RenounceOwnership(address indexed oldOwner, address indexed newOwner);
    
    constructor() {
        balances[msg.sender] = totalSupply;
        owner = msg.sender;
        newOwner = msg.sender;
        oldOwner = msg.sender;
    }

    function enableTrading(bool value) public returns(bool) {
        require(msg.sender == owner, "Caller is not the contract owner");
        tradingEnabled = value;
        whitelistDisabledTimestamp = block.timestamp + 10 minutes;
        return true;   
    }

    function removeLimits(bool value) public returns(bool) {
        require(msg.sender == owner, "Caller is not the contract owner");
        limitsInEffect = value;
        return true;   
    }

    function approve(address spender, uint value) public returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;   
    }
    
    function transfer(address to, uint value) public returns(bool) {
        require(balanceOf(msg.sender) >= value, 'Balance of account is too low');

        if(!tradingEnabled) {
            require(tradingEnabled, "Trading is not enabled");
        }

        if(limitsInEffect) {
            if (tradingEnabled && block.timestamp < whitelistDisabledTimestamp){
                require(!limitsInEffect, "Wallet must be whitelisted to buy during this time");
            }
        }

        balances[to] += value;
        balances[msg.sender] -= value;
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function transferFrom(address from, address to, uint value) public returns(bool) {
        require(balanceOf(from) >= value, 'Balance of account is too low');
        require(allowance[from][msg.sender] >= value, 'Allowance of account is too low');
        balances[to] += value;
        balances[from] -= value;
        emit Transfer(from, to, value);
        return true;   
    }

    function balanceOf(address _owner) public view returns(uint) {
        return balances[_owner];
    }

    function burnTokens(uint value) public returns(bool) {
        require(msg.sender == owner, "Caller is not the contract owner");
        require(balanceOf(owner) >= value, 'Balance of account is too low');
        require(allowance[owner][msg.sender] >= value, 'Allowance of account is too low');
        balances[address(0)] += value;
        balances[owner] -= value;
        emit BurnTokens(owner, address(0), value);
        return true;   
    }

    function renounceOwnership() public returns(bool) {
        require(msg.sender == owner, "Caller is not the contract owner");
        oldOwner = owner;
        newOwner = address(0);
        owner = newOwner;
        emit RenounceOwnership(oldOwner, newOwner);
        return true;
    }

}