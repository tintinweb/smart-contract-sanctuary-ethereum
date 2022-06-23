/**
 *Submitted for verification at Etherscan.io on 2022-06-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20Token {
    function balanceOf(address) external returns (uint256);
    function allowance(address, address) external returns (uint256);
    function transfer(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
}

contract TokenExchange {
    // 1 tokenOwner = <exchangeRate> tokenBuyer
    IERC20Token public tokenOwner;
    IERC20Token public tokenBuyer;
    uint256 public exchangeRate;
    address owner;

    constructor (
        IERC20Token tokenOwner_,
        IERC20Token tokenBuyer_,
        uint256 exchangeRate_
    ) {
        owner = msg.sender;
        tokenOwner = tokenOwner_;
        tokenBuyer = tokenBuyer_;
        exchangeRate = exchangeRate_;
    }

    function buyToken(uint256 amount) public returns (bool) {
        address buyer = msg.sender;
        require(tokenOwner.balanceOf(owner) >= amount, "no more to sell");
        require(tokenOwner.allowance(owner, address(this)) >= amount, "sale ended");
        
        tokenBuyer.transferFrom(buyer, owner, amount * exchangeRate);
        tokenOwner.transferFrom(owner, buyer, amount);
        return true;
    }
}