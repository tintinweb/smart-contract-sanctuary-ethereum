/**
 *Submitted for verification at Etherscan.io on 2022-04-09
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Token {
    string public name;
    string public symbol;
    uint256 public decimals;
    uint256 public total_Supply;

    mapping(address => uint256) public balanceOf;
    mapping(address =>mapping(address=>uint256)) public allowances;

    constructor() {
        name = "Brem";
        symbol = "BRM";
        decimals = 18;
        total_Supply = 1000000000000000000000000;
        balanceOf[msg.sender] = total_Supply;
    }


    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 _amount
    );

    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );

    //Person who clicks on this function will transfer token to another address
    function transfer(address _to, uint256 _value) external payable returns (bool success){
        require(balanceOf[msg.sender]>=_value, "Insufficient funds!");
        balanceOf[_to] += _value;
        balanceOf[msg.sender] -= _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) external returns (bool success) {
        require(_spender != address(0));
        allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    //The owner of token can manually transact between 2 addresses 
    function transferFrom(address _from, address _to, uint256 _value) external returns(bool success){
        require(balanceOf[_from]>= _value, "Insufficient funds!");
        require(allowances[_from][msg.sender]>= _value, "Invalid");
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

}