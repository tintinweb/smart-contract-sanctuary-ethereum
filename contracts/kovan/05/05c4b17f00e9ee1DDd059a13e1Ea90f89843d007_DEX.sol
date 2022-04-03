/**
 *Submitted for verification at Etherscan.io on 2022-04-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);


    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract DEX {

     event Approval(address indexed owner, address indexed spender, uint256 amount);
    event Sold(address indexed owner, address indexed spender, uint256 amount);


    IERC20 public token;
        uint256 public balance;
        
    constructor() {
       token = IERC20(address(0x0b878D15e6436A24f76807Dd4e7F7635249e380f));
    }

   function approve(address delegate, uint256 amount) public  returns (bool) {
        //allowed[msg.sender][delegate] = amount;
        emit Approval(msg.sender, delegate, amount);
        token.approve(delegate, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public  returns (bool)  {
       // require(amount > 0, "You need to sell at least some tokens");
       // uint256 allowance = token.allowance(msg.sender, address(this));
       // require(allowance >= amount, "Check the token allowance");
        token.transferFrom(msg.sender, address(this), amount);
        //payable(msg.sender).transfer(amount);
        emit Sold(sender, recipient, amount);
        return true;
    }

}