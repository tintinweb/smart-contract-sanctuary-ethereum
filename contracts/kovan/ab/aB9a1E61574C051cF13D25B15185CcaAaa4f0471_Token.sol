/**
 *Submitted for verification at Etherscan.io on 2022-03-22
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;


contract Token {
    string public name = "MichaelsAmadi Token";
    string public symbol = "MAT";
    uint256 public decimals = 18;
    uint256 public totalSupply = 1000000000000000000000000;

constructor(uint _totalSupply) {
        _totalSupply = totalSupply;
        balanceOf[msg.sender] = _totalSupply;
    }

mapping (address => uint) public balanceOf;
    mapping (address => mapping(address => uint)) public allowance;

event Transfer (address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

function transfer (address _to, uint _value) external returns (bool success) {
        require (balanceOf[msg.sender]>= _value);
        _transfer (msg.sender, _to, _value);
        return true;
    }

    function _transfer (address _from, address _to, uint _value) internal{
        require( _to != address(0));
        balanceOf[_from] = balanceOf[_from] - (_value);
        balanceOf[_to] = balanceOf[_to] + (_value);
        emit Transfer (_from, _to, _value);
    }

    function approve(address _spender, uint _value) external returns (bool) {
        require(_spender != address(0));
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint _value) external returns (bool) {
        require (balanceOf [_from] >= _value);
        require (allowance[_from][msg.sender] >= _value);
        allowance[_from][msg.sender] = allowance[_from][msg.sender] - (_value);
        _transfer (_from, _to, _value);
        return true;
    }

}