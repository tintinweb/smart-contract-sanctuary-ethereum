/**
 *Submitted for verification at Etherscan.io on 2023-06-08
*/

pragma solidity ^0.8.0;

contract SSS {
    string public name = "SSS";
    string public symbol = "S";
    uint256 public totalSupply = 1000000;
    uint8 public decimals = 18;
    uint256 public price = 240129160000000000; // 1 SSS = 0.24012916 USD

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
}