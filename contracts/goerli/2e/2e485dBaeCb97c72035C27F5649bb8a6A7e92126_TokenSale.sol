// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./AceToken.sol";

contract TokenSale {
    address payable admin;
    AceToken public tokenContract;
    uint256 public tokenPrice;
    uint256 public tokenSold;

    event Sell(address _buyer, uint256 _amount);

    modifier isAdmin() {
        require(msg.sender == admin, "You are not the owner");
        _;
    }

    constructor(AceToken _contract, uint256 _tokenPrice) {
        admin = payable(msg.sender);
        tokenContract = _contract;
        tokenPrice = _tokenPrice;
    }

    function buyTokens(uint256 _numberOfTokens) public payable {
        require(msg.value >= _numberOfTokens * tokenPrice, "Price is less");
        require(
            tokenContract.balanceOf(address(tokenContract)) >= _numberOfTokens,
            "Available tokens are less"
        );
        require(
            tokenContract.transfer(msg.sender, _numberOfTokens),
            "Transfering is failed"
        );

        tokenSold += _numberOfTokens;

        Sell(msg.sender, _numberOfTokens);
    }

    function endSale() public isAdmin {
        // get balance of this Contract
        uint256 balance = tokenContract.balanceOf(address(tokenContract));
        require(
            tokenContract.transfer(admin, balance),
            "Transfering is failed"
        );
    }
}