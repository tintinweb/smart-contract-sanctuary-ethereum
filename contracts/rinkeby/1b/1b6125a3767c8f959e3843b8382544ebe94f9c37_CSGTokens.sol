/**
 *Submitted for verification at Etherscan.io on 2022-03-18
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

contract CSGTokens {

    constructor(string memory _name,string memory _symbol, uint8 _decimals,uint256 _tSupply){
        name_ =_name;
        symbol_=_symbol;
        decimals_ = _decimals;
        tSupply = _tSupply;
        balances[msg.sender] = tSupply;
    }


    string name_;
    string symbol_;
    uint8 decimals_;
    uint256 tSupply;

    mapping(address => uint256) balances;

     event Transfer(address indexed _to,address indexed _from,uint256 _value);
    function name() public view returns(string memory){
        return name_;
    }
    function symbol() public view returns(string memory){
        return symbol_;
    }
    function decimal() public view returns(uint8){
        return decimals_;
    }
    function totalSupply() public view returns(uint256){
        return tSupply;
    }
    function balance(address _owner) public view returns(uint256){
        return balances[_owner];
    }
    function transfer(address _to, uint256 _value) public returns(bool success){
        require(balances[msg.sender]>=_value,"insuffecent balance");
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer (msg.sender,_to,_value);
        return true;
    }
}