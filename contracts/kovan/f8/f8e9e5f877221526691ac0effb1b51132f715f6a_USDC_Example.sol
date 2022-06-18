/**
 *Submitted for verification at Etherscan.io on 2022-06-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
}

contract USDC_Example {
    IERC20 public usdc;
    address owner;
    constructor() {
         owner = msg.sender;
         usdc = IERC20(0xe22da380ee6B445bb8273C81944ADEB6E8450422);        
    } 
    function getname() public view returns (string memory){
        return usdc.name();
    }
    function getsymbol() public view returns (string memory){
        return usdc.symbol();
    }
    function usdcAmount() public view returns (uint) {
        return usdc.balanceOf(address(this)) / 10 ** 18;
    }
    function approveJpycFromContract() public {
        usdc.approve( address(this) , usdc.balanceOf(address(this)) );
    }
    function withdraw_usdc() public {
        require(msg.sender == owner);
        usdc.transferFrom(address(this) , owner , usdc.balanceOf(address(this)) );
    }
}