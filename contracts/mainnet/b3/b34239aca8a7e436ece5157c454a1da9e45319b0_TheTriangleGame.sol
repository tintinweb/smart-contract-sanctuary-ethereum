/**
 *Submitted for verification at Etherscan.io on 2023-01-19
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract TheTriangleGame {
    mapping(address => uint256) public balanceOf;
    string public constant symbol = "TTG";
    string public constant name = "The Triangle Game";
    uint8 public constant decimals = 18;
    uint256 public totalSupply = 10987654321000000000000000000;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed burner, uint256 amount);
    //No minting
    constructor() {
        balanceOf[msg.sender] = totalSupply;
    }

    //Transfer tokens
    function transfer(address _to, uint256 _value) public {
        require(balanceOf[msg.sender] >= _value && _value > 0);
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return;
    }

    //Check balance
    function checkBalance(address _owner) public view returns (uint256) {
        return balanceOf[_owner];
    }

    // Limited supply
    function burn(uint256 _value) public {
        require(balanceOf[msg.sender] >= _value && _value > 0);
        totalSupply -= _value;
        balanceOf[msg.sender] -= _value;
        emit Burn(msg.sender, _value);
        return;
    }

    // No pause trading or blacklist
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    address owner;

    receive() external payable {
        require(msg.value == 0);
    }
}