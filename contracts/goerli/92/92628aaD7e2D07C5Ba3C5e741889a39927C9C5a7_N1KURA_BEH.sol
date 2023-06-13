// SPDX-License-Identifier: N1KURA
// Created by N1KURA
// GitHUB: https://github.com/N1KURA
// Twitter: https://twitter.com/0xN1KURA
// Telegram: https://t.me/N1KURA

pragma solidity ^0.8.0;

contract N1KURA_BEH {
    string public name = "Burning each hour";
    string public symbol = "BEH";
    uint256 public totalSupply = 1000000000 * 10**18; // 1 billion tokens with 18 decimals
    uint8 public decimals = 18;
    uint256 constant HOUR_IN_SECONDS = 3600;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Burn(address indexed burner, uint256 value);

    uint256 private lastBurnTime;

    constructor() {
        balanceOf[msg.sender] = totalSupply;
        lastBurnTime = block.timestamp;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(_to != address(0), "Invalid recipient address");
        require(balanceOf[msg.sender] >= _value, "Insufficient balance");

        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;

        emit Transfer(msg.sender, _to, _value);

        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        require(_spender != address(0), "Invalid spender address");

        allowance[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);

        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_from != address(0), "Invalid sender address");
        require(_to != address(0), "Invalid recipient address");
        require(balanceOf[_from] >= _value, "Insufficient balance");
        require(allowance[_from][msg.sender] >= _value, "Insufficient allowance");

        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;

        allowance[_from][msg.sender] -= _value;

        emit Transfer(_from, _to, _value);

        return true;
    }

    function burn(uint256 _value) public {
        require(balanceOf[msg.sender] >= _value, "Insufficient balance");

        balanceOf[msg.sender] -= _value;
        totalSupply -= _value;

        emit Burn(msg.sender, _value);
    }

    function hourlyBurn() public {
        require(block.timestamp >= lastBurnTime + HOUR_IN_SECONDS, "Can't burn yet");

        uint256 amountToBurn = totalSupply / 100; // burn 1% of total supply
        totalSupply -= amountToBurn;
        balanceOf[address(0)] += amountToBurn;

        lastBurnTime = block.timestamp;

        emit Burn(address(0), amountToBurn);
    }
}