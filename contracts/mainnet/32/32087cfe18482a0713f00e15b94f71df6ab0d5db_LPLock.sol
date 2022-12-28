/**
 *Submitted for verification at Etherscan.io on 2022-12-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
}

contract LPLock {
    address public immutable Owner;
    modifier onlyOwner() {
        require(msg.sender == Owner, 'Not owner');

        _;
    }

    address public immutable LP;
    uint256 public Lock_Period;

    constructor(address lp, address owner) {
        LP = lp;
        Owner = owner;
        Lock_Period = block.timestamp;
    }

    function addPeriod(uint256 second) external onlyOwner() returns (bool) {
        Lock_Period += second;

        return true;
    }

    function Withdraw(address token) external onlyOwner() returns (bool) {
        if(token == LP) {
            require(block.timestamp >= Lock_Period, 'Too early');

            IERC20(LP).transfer(msg.sender, IERC20(LP).balanceOf(address(this)));

            return true;
        }
        
        IERC20(token).transfer(msg.sender, IERC20(token).balanceOf(address(this)));

        return true;
    }
}