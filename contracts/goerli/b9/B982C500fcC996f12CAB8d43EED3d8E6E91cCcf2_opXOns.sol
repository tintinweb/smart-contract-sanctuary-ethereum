/**
 *Submitted for verification at Etherscan.io on 2023-03-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function balanceOf(address who) external view returns (uint256);
}

contract opXOns {
    ERC20 public token;
    address public beneficiary;
    uint64 public releaseTime;
    address public feeAddress; // The address that will receive the fee
    uint256 public feePercentage; // The percentage of the transfer amount to be charged as fee
    uint256 public minTransferAmount; // Minimum accepted transfer amount
    bool public feeReleased;
    bool public released;

    constructor(
        ERC20 _token,
        address _beneficiary,
        uint64 _releaseTime,
        address _feeAddress,
        uint256 _minTransferAmount,
        uint256 _feePercentage
    ) {
        require(_releaseTime > uint64(block.timestamp), "Release time must be in the future");
        require(_feePercentage > 0 && _feePercentage <= 100, "Invalid fee percentage");
        token = _token;
        beneficiary = _beneficiary;
        releaseTime = _releaseTime;
        feeAddress = _feeAddress;
        minTransferAmount = _minTransferAmount;
        feePercentage = _feePercentage;
        uint256 amount = token.balanceOf(address(this));
        if (amount > 0) {
            uint256 feeAmount = amount * feePercentage / 100;
            require(token.transfer(feeAddress, feeAmount), "Fee transfer failed");
        }
    }

    function balanceOf() public view returns (uint256) {
        return token.balanceOf(address(this));
    }

    function release() public {
        require(uint64(block.timestamp) >= releaseTime, "Release time has not yet come");
        uint256 amount = token.balanceOf(address(this));
        require(amount > 0, "No tokens to release");
        require(amount >= minTransferAmount, "Minimum transfer amount not met");
        uint256 transferAmount = amount;
        if (!feeReleased) {
            uint256 feeAmount = amount * feePercentage / 100;
            require(token.transfer(feeAddress, feeAmount), "Fee transfer failed");
            transferAmount = amount - feeAmount;
            feeReleased = true;
        }
        require(token.transfer(beneficiary, transferAmount), "Token transfer failed");
    }

    function releaseFee() public {
        require(msg.sender == feeAddress, "Only fee address can release the fee");
        require(!feeReleased, "Fee already released");
        require(uint256(block.timestamp) > 0, "Invalid timestamp");
        uint256 amount = token.balanceOf(address(this));
        require(amount > 0, "No tokens to release");
        uint256 feeAmount = amount * feePercentage / 100;
        require(token.transfer(feeAddress, feeAmount), "Fee transfer failed");
        feeReleased = true;
    }

    // Added fallback function to receive ether just in case
    receive() external payable {
        revert("Ether transfer not allowed");
    }
}