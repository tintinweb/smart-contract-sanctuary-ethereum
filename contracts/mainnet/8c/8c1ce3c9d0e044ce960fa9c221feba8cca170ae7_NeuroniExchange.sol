/**
 *Submitted for verification at Etherscan.io on 2023-01-26
*/

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.7;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address _owner, address spender) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function decimals() external view returns (uint8);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract NeuroniExchange {

    address public owner;
    address public tokenAddress;

    IERC20 private _token;
    
    modifier onlyOwner() {
        require(msg.sender == owner, "no permissions");
        _;
    }

    constructor() {
        owner = msg.sender;
        tokenAddress = 0x922e2708462c7a3d014D8344F7C4d92b27ECf332;
        _token = IERC20(tokenAddress);
    }
        
    function distribute(address[] calldata addresses) external onlyOwner {
        uint8 decimals = _token.decimals();
        uint256 amount = 1 * 10 ** decimals;
        require(_token.balanceOf(address(this)) >= addresses.length * amount, "Not enough tokens to distribute");
        for (uint256 i = 0; i < addresses.length; i++) {
            _token.transfer(addresses[i], amount);
        }
    }

    // Admin methods
    function setOwner(address who) external onlyOwner {
        require(who != address(0), "cannot be zero address");
        owner = who;
    }
 
    function removeEth() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner).transfer(balance);
    }
    
    function removeTokens(address token) external onlyOwner returns(bool){
        uint256 balance = IERC20(token).balanceOf(address(this));
        return IERC20(token).transfer(owner, balance);
    }
}