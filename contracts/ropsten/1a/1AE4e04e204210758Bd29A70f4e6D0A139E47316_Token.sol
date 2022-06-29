// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Token {
    string  public name = "Tuwaiq TOKEN";
    string  public symbol = "TUWAIQ";
    uint256 public totalSupply = 1000000;
    uint8   public decimals = 18;

    mapping(address => uint256) public balanceOf;
    
    constructor() {
        balanceOf[msg.sender] = totalSupply;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= balanceOf[_from]);
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        return true;
    }
}