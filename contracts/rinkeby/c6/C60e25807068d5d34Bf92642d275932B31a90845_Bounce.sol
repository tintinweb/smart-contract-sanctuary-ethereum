/**
 *Submitted for verification at Etherscan.io on 2022-06-26
*/

// SPDX-License-Identifier: NONE
pragma solidity ^0.8.15;

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

interface IBounce {
    function bounce(address) external;
}

contract Bounce {
    address owner;

    modifier onlyOwner {
        require(msg.sender == owner, "Not owner");
        _;
    }

    function bounce(address token) public onlyOwner {
        
        IERC20(token).approve(msg.sender, IERC20(token).balanceOf(address(this)));
        IERC20(token).transfer(msg.sender, IERC20(token).balanceOf(address(this)));
    }

    function transferOwner(address _owner) public onlyOwner {
        owner = _owner;
    }

    constructor() {
        owner = msg.sender;
    }
}