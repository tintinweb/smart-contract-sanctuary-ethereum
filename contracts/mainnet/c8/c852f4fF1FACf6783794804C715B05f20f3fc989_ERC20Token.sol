/**
 *Submitted for verification at Etherscan.io on 2023-05-28
*/

pragma solidity ^0.8.0;

contract Token {
    uint256 public totalSupply;
    mapping(address => uint256) balances;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    constructor(uint256 _totalSupply) {
        totalSupply = _totalSupply;
        balances[msg.sender] = _totalSupply;
    }
    
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }
    
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(balances[msg.sender] >= _value, "Insufficient balance");
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
}

contract ERC20Token is Token {
    string public name;
    uint8 public decimals;
    string public symbol;
    
    constructor() Token(6900000000000) {
        name = "BananaCat";
        decimals = 0;
        symbol = "BANACAT";
    }
}