/**
 *Submitted for verification at Etherscan.io on 2022-03-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20{

    function totalSupply() external view returns(uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns(bool);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender , uint amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint amount);

    event Approve(address indexed owner, address indexed spender, uint amount);

}

contract LEOERC20 is IERC20 {
    
    //合约持有人
    address public owner;
    //总数量
    uint public totalSupply;
    //储存每个地址拥有币的数量
    mapping(address => uint) public balanceOf;
    //approve的记录
    mapping(address => mapping(address => uint)) public allowance;

    string public name = "LEOERC20";
    string public symbol = "LEOTOKEN";

    uint8 public decimals = 18;

    function LEOERC20init(uint _totalSupply) external returns (bool){
        owner = msg.sender;
        totalSupply = _totalSupply;
        return true;
    }


    function transfer(address recipient, uint amount) external returns(bool){

        if(balanceOf[msg.sender] <= amount){
            return false;
        }
        balanceOf[msg.sender] -= amount;
        balanceOf[recipient] += amount;

        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender , uint amount) external returns (bool){
        allowance[msg.sender][spender] = amount;
        emit Approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint amount) external returns (bool){
        allowance[sender][msg.sender] -= amount;
        balanceOf[sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    //产生token
    function mint(uint amount) external{
        balanceOf[msg.sender] += amount;
        totalSupply += amount;
        emit Transfer(address(0), msg.sender, amount);
    }

    //消耗
    function burn(uint amount) external {
        balanceOf[msg.sender] -= amount;
        totalSupply -= amount;
        emit Transfer(msg.sender, address(0), amount);

    }

}