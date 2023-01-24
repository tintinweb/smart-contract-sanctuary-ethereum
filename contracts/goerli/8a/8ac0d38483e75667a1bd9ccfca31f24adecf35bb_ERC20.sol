/**
 *Submitted for verification at Etherscan.io on 2023-01-24
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface IERC20 {

    function transfer(address recepient, uint256 amount) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address spender, address recepient, uint256 amount) external returns (bool);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}

contract ERC20 is IERC20{
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    string public name = "ERC20 Tokens";
    string public symbol = "ERC20";
    uint8 public decimals = 18;

    constructor(){
        _mint(50);
    }

    function transfer(address recepient, uint256 amount) external override returns (bool){
        require(balanceOf[msg.sender] >= amount, "Not enough tokens");
        balanceOf[recepient] += amount;
        balanceOf[msg.sender] -= amount;
        emit Transfer(msg.sender, recepient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external override returns (bool){
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address spender, address recepient, uint256 amount) 
        external 
        override
        returns (bool)
    {
        require(amount <=  balanceOf[spender], "Not enough tokens");
        balanceOf[spender] -= amount;
        allowance[spender][msg.sender] -= amount;
        balanceOf[recepient] += amount;
        emit Transfer(spender, recepient, amount); 
        return true;
    }

    function _mint(uint amount) private {
        balanceOf[msg.sender] += amount;
        totalSupply += amount;
        emit Transfer(address(0), msg.sender, amount);
    }

    function _burn(uint amount) private {
        balanceOf[msg.sender] -= amount;
        totalSupply -= amount;
        emit Transfer(msg.sender, address(0), amount);
    }

}