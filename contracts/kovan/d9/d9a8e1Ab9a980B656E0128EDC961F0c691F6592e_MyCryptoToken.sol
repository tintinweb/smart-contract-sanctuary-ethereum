/**
 *Submitted for verification at Etherscan.io on 2022-07-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract MyCryptoToken{
    string public name = "Quad Token";
    string public symbol = "QUD";
    uint256 public decimals = 18;
    uint256 public totalSupply = 1000000000000000000000000;

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor() {
        balanceOf[msg.sender] = totalSupply;
    }

    function transfer(address _to, uint256 _value) external returns(bool success){
        require(balanceOf[msg.sender]>=_value, "Insufficient funds!");
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function _transfer(address _from, address _to, uint256 _value) internal{
        require(address(_to) != address(0x0),"Recipient address cannot be null!");
        balanceOf[_from] = balanceOf[_from] - (_value);
        balanceOf[_to] = balanceOf[_to] + (_value);
        emit Transfer(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value) external returns (bool){
        require(_spender != address(0x0),"Address field cannot be null!");
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) external returns(bool){
        require(_value <= balanceOf[_from]);
        require(_value <= allowance[_from][msg.sender]);
        allowance[_from][msg.sender] = allowance[_from][msg.sender] - (_value);
        _transfer(_from, _to, _value);
        return true;
    }

}