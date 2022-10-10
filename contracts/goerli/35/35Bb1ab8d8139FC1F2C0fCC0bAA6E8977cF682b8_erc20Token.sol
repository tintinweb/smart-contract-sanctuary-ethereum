/**
 *Submitted for verification at Etherscan.io on 2022-10-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

contract erc20Token {
    string public name;
    uint8 public decimals;
    string public symbol;
    uint256 public totalSupply;
    address public owner;

    bool mintable = true;

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function mint(address to, uint256 value) public onlyOwner {
        require(mintable, "Minting not allowed");
        balances[to] += value;
        emit Transfer(0x0000000000000000000000000000000000000000, to, value);
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            emit Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            emit Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }
    function approve(address _spender, uint256 _value ) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    constructor() public {
        name = 'Bitcoin';
        totalSupply = 2100000000000000;
        owner = 0x8a65ac0E23F31979db06Ec62Af62b132a6dF4741;
        balances[owner] = totalSupply;
        decimals = 8;
        symbol = 'BTC';
        emit Transfer(0x0000000000000000000000000000000000000000, owner, totalSupply);
    }
}