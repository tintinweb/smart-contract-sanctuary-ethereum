/**
 *Submitted for verification at Etherscan.io on 2022-11-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Token {
    string public name;
    string public symbol;
    uint8 public decimals;

    // Map Object 와 유사하다 : (K,V) = (address, balance uint)
    mapping (address => uint256) private _balances;
    // (K,(K,V)) = (from_address, (to_address, allowed amount uint)
    mapping (address => mapping (address => uint256)) private _allowed;

    uint private _totalSupply;
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
    constructor() {
        name = "MyToken";
        symbol = "MTK";
        decimals = 10;

        _totalSupply = 100000* (10**decimals);
        _balances[msg.sender] = 100000 * (10**decimals);
    }
    
    
    
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
    
    function balanceOf(address owner) public view returns (uint256 balance) {
        return _balances[owner];
    }
    
    function transfer(address _to, uint256 _value) public returns (bool success) {
        _balances[msg.sender] -= _value;
        _balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);

        return true;
    }
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= _allowed[_from][msg.sender]);
        _allowed[_from][msg.sender] -= _value;
        _balances[_from]-=_value;
        _balances[_to]+=_value;

        emit Transfer(_from, _to, _value);
        
    }
    
    function approve(address _spender, uint256 _value) public returns (bool success) {
        require(_spender != address(0));
        _allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);

        return true;
    }
    
    function allowance(address _owner, address _spender) public view returns (uint256 remaining){
        return _allowed[_owner][_spender];
    }

    
}