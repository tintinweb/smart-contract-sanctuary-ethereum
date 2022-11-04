// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract CryptoLecturesCoin {
    
    // 1. Variables
    mapping (address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowed;

    uint256 public totalSupply;
    string public name;
    uint8 public decimals;
    string public symbol;

    // 2. Events
    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 value
    );

    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 value
    );

    // 3. Constructor
    constructor (
        uint256 _initialAmount,
        string memory _tokenName,
        uint8 _decimalUnits,
        string memory _tokenSymbol
    ) {
        balances[msg.sender] = _initialAmount;
        totalSupply = _initialAmount;
        name = _tokenName;
        decimals = _decimalUnits;
        symbol = _tokenSymbol;
        emit Transfer(address(0), msg.sender, _initialAmount);
    }

    // 4. Functions
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value, "insufficient balance");
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(allowed[_from][msg.sender] >= _value, "insufficient allowance");
        require(balances[_from] >= _value, "insufficient balance");
        if (allowed[_from][msg.sender] < type(uint256).max) {
            allowed[_from][msg.sender] -= _value;
        }
        balances[_from] -= _value;
        balances[_to] += _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
}