/**
 *Submitted for verification at Etherscan.io on 2022-05-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract MyToken{
    string public _name;
    string public _symbol;
    uint public _decimals= 18;
    uint public _totalSupply;

    address public _minter;

    mapping (address => uint) public tokenBalances;
    // First address- actual owner | Second- approved address
    mapping (address => mapping(address => uint)) public allowed;

    event Transfer(address _from, address _to, uint _value);
    event Approval(address _owner, address _spender, uint _value);

    constructor(){
        _name= "MyToken";
        _symbol= "MTN";
        _totalSupply= 1000000 * (10**_decimals);
        _minter= msg.sender;
        tokenBalances[_minter]= _totalSupply;
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

    function totalSupply() public view returns (uint){
        return _totalSupply;
    }

    function balanceOf(address _owner) public view returns (uint){
        return tokenBalances[_owner];
    }

    // Transfer from the caller to a particular address
    function transfer(address _to, uint _value) public returns (bool){
        require(tokenBalances[msg.sender] >= _value, "Insufficient Tokens");
        tokenBalances[msg.sender] -= _value;
        tokenBalances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    // Approve an address to use tokens of another address
    function approve(address _spender, uint _value) public returns (bool){
        require(tokenBalances[msg.sender] >= _value, "Insufficient tokens");
        allowed[msg.sender][_spender]= _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    // How much allowance is given by an owner to a spender
    function allowance(address _owner, address _spender) public view returns (uint){
        return allowed[_owner][_spender];
    }

    // Transfer from a particular address to another address
    function transferFrom(address _from, address _to, uint _value) public returns (bool){
        uint allowedBalance= allowed[_from][msg.sender];
        require(allowedBalance >= _value, "Insufficient allowed tokens");
        tokenBalances[_from] -= _value;
        tokenBalances[_to] += _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    // Destroy the tokens
    function burn(uint _value) public returns(bool){
        require(tokenBalances[msg.sender] >= _value, "Insufficient tokens");
        tokenBalances[msg.sender] -= _value;
        _totalSupply -= _value;
        return true;
    }

    // Add new tokens
    function mint(address target, uint amt) public {
        require(msg.sender == _minter, "Only owner can mint new tokens");
        tokenBalances[target] += amt;
        _totalSupply += amt;
    }
}