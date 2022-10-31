// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./ERC20.sol";
import "./ReentrancyGuard.sol";

// from and to are addresses of tokens who have the same decimals
contract Swap is Ownable, ReentrancyGuard {
    ERC20 _fromToken;
    ERC20 _toToken;

    constructor(ERC20 fromToken, ERC20 toToken) {
        _fromToken = fromToken;
        _toToken = toToken;
    }

    function swap(uint256 amount) nonReentrant external {
        address user = msg.sender;
        uint256 allowance = _fromToken.allowance(user, address(this));
        require(amount <= allowance, "User has not given swap contract spend approval");
        uint256 selfBalanceToToken = _toToken.balanceOf(address(this));
        require(amount <= selfBalanceToToken, "Not enough liquidity");
        require(_fromToken.transferFrom(user, address(this), amount), "Could not transfer user's token to swap contract");
        require(_toToken.transfer(user, amount), "Swap contract could not transfer token to user");
    }

    function withdrawFrom() onlyOwner external {
        uint256 balance = _fromToken.balanceOf(address(this));
        require(_fromToken.transfer(this.owner(), balance), "Admin could not withdraw FromToken");
    }

    function withdrawTo() onlyOwner external {
        uint256 balance = _toToken.balanceOf(address(this));
        require(_toToken.transfer(this.owner(), balance), "Admin could not withdraw ToToken");
    }

    function renounceOwnership() override public virtual onlyOwner {
        revert("Owner cannot renounce ownership");
    }
}