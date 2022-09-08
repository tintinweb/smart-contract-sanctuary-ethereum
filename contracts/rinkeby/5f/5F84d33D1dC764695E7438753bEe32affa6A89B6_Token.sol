/**
 *Submitted for verification at Etherscan.io on 2022-09-08
*/

//SPDX-License-Identifier:MIT

pragma solidity ^0.8.0;

contract Token{
    string public name;
    string public symbol;
    uint public totalsupply;
    uint public decimal;

    
    constructor(string memory _name, string memory _symbol, uint _totalsupply, uint _decimal){
        name = _name;
        symbol = _symbol;
        totalsupply = _totalsupply;
        decimal = _decimal;
        balanceOf[msg.sender] = totalsupply;
    }

    event Transfer(address indexed _from ,address indexed _to, uint value);
    event Approve(address indexed _owner, address indexed _spender, uint _value);

    mapping (address => uint )public balanceOf;
    mapping(address => mapping(address => uint))allowance;


    function transfer(address _to, uint _value)public returns(bool){
       require(balanceOf[msg.sender] >= _value);
       _transfer(msg.sender, _to, _value);
       return true;
    }

    function _transfer(address _from, address _to, uint _value)public{
        require(_to != address(0));
        balanceOf[_from] = balanceOf[_from] - (_value);
        balanceOf[_to] += _value;
        emit Transfer(_from, _to,_value);
    }

    function approve(address _spender, uint256 _value)public returns(bool){
        require(_spender != address(0));
        allowance[msg.sender][_spender] = _value;
        emit Approve(msg.sender, _spender, _value);
        return true;
    }


    function transferFrom(address _from, address _to, uint _value)public returns(bool){
        require(_value <= balanceOf[_from]);
        require(_value <= allowance[_from][msg.sender]);
        _transfer(_from, _to, _value);
        return true;
    }
}