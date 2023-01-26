// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ERC20 {
    function transfer(address _to, uint256 _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function balanceOf(address _owner) external returns (uint256 balance);
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);
}

contract Vault {
    address public owner;
    address public nextOwner;
    bool public paused;

    constructor() {
        owner = msg.sender;
        paused = false;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Only the owner can perform this action");
        _;
    }

    event Withdrawal(
        address indexed withdrawer,
        uint256 amount
    );

    event Pause();
    event Unpause();

    function withdraw(address token, address withdrawer, uint256 amount) external onlyOwner {
        require(!paused, "The contract is paused");
        require(amount > 0, "The amount must be greater than zero");
        require(ERC20(token).balanceOf(address(this)) >= amount, "Insufficient balance");

        ERC20(token).transfer(withdrawer, amount);

        emit Withdrawal(withdrawer, amount);
    }

    function setNextOwner(address _nextOwner) external onlyOwner {
        require(_nextOwner != address(0), "Owner cannot be the zero address");
        nextOwner = _nextOwner;
    }

    function getOwnership() external {
        require(nextOwner == msg.sender, "You are not the next owner");
        owner = nextOwner;
        nextOwner = address(0);
    }

    function pause() external onlyOwner {
        paused = true;
        emit Pause();
    }

    function unpause() external onlyOwner {
        paused = false;
        emit Unpause();
    }
}