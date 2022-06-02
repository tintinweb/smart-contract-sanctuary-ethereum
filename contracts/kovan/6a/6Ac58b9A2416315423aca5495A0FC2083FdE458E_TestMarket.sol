// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract TestMarket {
    uint256 public totalSupply;

    // Monitored events.
    event Mint(address minter, uint256 mintAmount, uint256 mintTokens);

    event Redeem(address redeemer, uint256 redeemAmount, uint256 redeemTokens);

    event Borrow(
        address borrower,
        uint256 borrowAmount,
        uint256 accountBorrows,
        uint256 totalBorrows
    );

    function emitMint(uint256 mintAmount) external {
        emit Mint(msg.sender, mintAmount, 0);
    }

    function emitRedeem(uint256 redeemAmount) external {
        emit Redeem(msg.sender, redeemAmount, 0);
    }

    function emitBorrow(uint256 borrowAmount) external {
        emit Borrow(msg.sender, borrowAmount, borrowAmount, borrowAmount);
    }

    function setTotalSupply(uint256 _totalSupply) external {
        totalSupply = _totalSupply;
    }
}