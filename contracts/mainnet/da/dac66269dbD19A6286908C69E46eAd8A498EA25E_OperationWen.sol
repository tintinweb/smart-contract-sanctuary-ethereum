/**
 *Submitted for verification at Etherscan.io on 2023-03-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract OperationWen {
    string public name = "Operation Wen";
    string public symbol = "WEN";
    uint256 public totalSupply = 100000000 * 10**18; // 100 million tokens with 18 decimal places
    uint8 public decimals = 18;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    address public owner;

    uint256 public taxRate = 5;
    mapping(address => bool) public exemptFromTax;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor() {
        owner = msg.sender;
        balanceOf[msg.sender] = totalSupply;
        exemptFromTax[msg.sender] = true;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(_to != address(0), "Invalid address");
        require(_value > 0, "Invalid amount");

        uint256 tax = 0;
        if (!exemptFromTax[msg.sender]) {
            tax = (_value * taxRate) / 100;
            balanceOf[owner] += tax;
        }

        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += (_value - tax);

        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        require(_spender != address(0), "Invalid address");
        require(_value > 0, "Invalid amount");

        allowance[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_from != address(0), "Invalid address");
        require(_to != address(0), "Invalid address");
        require(_value > 0, "Invalid amount");

        uint256 tax = 0;
        if (!exemptFromTax[_from]) {
            tax = (_value * taxRate) / 100;
            balanceOf[owner] += tax;
        }

        balanceOf[_from] -= _value;
        balanceOf[_to] += (_value - tax);

        allowance[_from][msg.sender] -= _value;

        emit Transfer(_from, _to, _value);
        return true;
    }

    function setExemptFromTax(address _address, bool _exempt) public {
        require(msg.sender == owner, "Only the owner can call this function");

        exemptFromTax[_address] = _exempt;
    }
}