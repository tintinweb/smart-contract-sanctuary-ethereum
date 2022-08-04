/**
 *Submitted for verification at Etherscan.io on 2022-08-04
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract ERC20 {


    uint public totalSupply;
    mapping (address => uint) public balanceOf;
    mapping (address => mapping(address => uint)) public allowance;
    string public name = "RR Code's token";
    string public symbol = "RRCT";
    uint8 public decimals = 18;
    uint totalFunds;
    uint totalXBalance;
    address[] multirecipient;
    event Transfer (address indexed from, address indexed to, uint value);
    event Approval (address indexed owner, address indexed spender, uint value);


    function transfer (address recipient, uint amount) external returns (bool) {
        balanceOf[msg.sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve (address spender, uint amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom (address sender, address recipient, uint amount) external returns (bool) {
        allowance[sender][msg.sender] -= amount;
        balanceOf[sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer (sender, recipient, amount);
        return true;
    }

     function multiTransfer (address sender, address[] memory multirecipient, uint amount) external payable returns (bool) {
        
        for (uint i = 0; i < multirecipient.length; i++) {
            balanceOf[msg.sender] -= amount;
            balanceOf[multirecipient[i]] += amount;
             emit Transfer (address(this), multirecipient[i], amount);
        }
        return true;
    }

    function mint (uint amount) external {
        balanceOf[msg.sender] += amount;
        totalSupply += amount;
        emit Transfer(address(0), msg.sender, amount);
    }

    function burn (uint amount) external {
        balanceOf[msg.sender] -= amount;
        totalSupply -= amount;
        emit Transfer(msg.sender, address(0), amount);
    }

    function deposit (uint amount) public payable returns (uint) {
        return address(this).balance;
    } 
}