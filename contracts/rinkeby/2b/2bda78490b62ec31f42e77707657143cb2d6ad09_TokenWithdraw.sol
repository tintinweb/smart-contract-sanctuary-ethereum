/**
 *Submitted for verification at Etherscan.io on 2022-08-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IERC20 {
    
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract TokenWithdraw {

    IERC20 public ERC20;
    constructor(IERC20 _reward){
        ERC20 =_reward;

    }
    function withdraw () public  {
        uint256 token = address(this).balance;
        ERC20.transfer(msg.sender,token);
        
    }
}