// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function decimals() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
}

contract TestERC20TokenFaucet {
    address public owner;
    mapping(address => uint256) thresholds;

    constructor() {
        owner = msg.sender;
    }

    function withdraw(address underlying) external {
        uint256 balance = IERC20(underlying).balanceOf(msg.sender);
        uint256 amount = getThreshold(underlying);
        require(balance < amount, "withdraw: balance not below threshold");
        IERC20(underlying).transfer(msg.sender, amount - balance);
    }

    function setThreshold(address underlying, uint256 _threshold) external {
        require(msg.sender == owner, "setThreshold: only callable by owner");
        require(_threshold > 0, "setThreshold: threshold must be greater than zero");
        thresholds[underlying] = _threshold;
    }

    function reduceFaucetBalance(address underlying, uint256 amount) external {
        require(msg.sender == owner, "reduceFaucetBalance: only callable by owner");
        if (amount == type(uint256).max) {
            uint balance = IERC20(underlying).balanceOf(address(this));
            IERC20(underlying).transfer(msg.sender, balance);
        } else {
            IERC20(underlying).transfer(msg.sender, amount);
        }
    }

    function getThreshold(address underlying) public view returns(uint256) {
        return thresholds[underlying];
    }
}