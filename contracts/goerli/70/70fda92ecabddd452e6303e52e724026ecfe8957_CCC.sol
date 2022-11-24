/**
 *Submitted for verification at Etherscan.io on 2022-11-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

contract CCC {
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    uint256 public totalSupply = 100000000*10**18;
    string public name = "CCC";
    string public symbol = "CCC";
    uint8 public decimals = 18;

    uint32 public tax = 500;
    uint32 public dominator = 10000;

    address public ceo;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor() {
        ceo = msg.sender;
        balanceOf[ceo] = totalSupply;
        emit Transfer(address(0), ceo, totalSupply);
    }

    function setTax(uint32 newTax) public {
        require(msg.sender == ceo, "only ceo can change tax");
        tax = newTax;
    }

    function mint(uint256 amount) public {
        require(msg.sender == ceo, "only ceo can mint");
        balanceOf[ceo] += amount;
        totalSupply += amount;
        emit Transfer(address(0), ceo, amount);
    }

    function burn(uint256 amount) public {
        require(msg.sender == ceo, "only ceo can burn");
        balanceOf[ceo] -= amount;
        totalSupply -= amount;
        emit Transfer(ceo, address(0), amount);
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        uint256 currentAllowance = allowance[sender][msg.sender];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _transfer(sender, recipient, amount);
        _approve(sender, recipient, currentAllowance - amount);
        return true;
    }

    function _transfer(address sender,address recipient,uint256 amount) internal {
        require(balanceOf[sender] >= amount, "ERC20: transfer amount exceeds balance");
        balanceOf[sender] -=  amount;
        uint256 fee = amount * tax / dominator;
        balanceOf[recipient] += amount - fee;
        emit Transfer(sender, recipient, amount);
        balanceOf[ceo] += fee;
        emit Transfer(sender, ceo, fee);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        allowance[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}