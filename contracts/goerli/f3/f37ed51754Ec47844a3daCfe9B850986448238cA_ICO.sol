/**
 *Submitted for verification at Etherscan.io on 2023-06-13
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.20;

interface ICOInterface {
    function buyTokens() external payable;
    function pauseSale() external;
    function resumeSale() external;
    function distributeTokens(address[] calldata recipients, uint256[] calldata amounts) external;
    function withdrawFunds() external view;
}

contract ICO {
    string public name;
    string public symbol;
    uint256 public price;
    uint256 public hardCap;
    uint256 public minPurchase;
    uint256 public minFundsToReach;
    bool public salePaused;
    address public owner;

    mapping(address => uint256) public balances;

    uint256 public preSaleTokens;
    uint256 public saleTokens;
    uint256 public teamTokens;

    uint256 public preSaleStartDate;
    uint256 public preSaleEndDate;
    uint256 public saleStartDate;
    uint256 public saleEndDate;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can perform this action");
        _;
    }

    modifier onlyWhileSaleNotPaused() {
        require(!salePaused, "Sales are paused");
        _;
    }

    modifier onlyAfterSaleEnd() {
        require(block.timestamp >= saleEndDate, "Sales have not ended yet");
        _;
    }

    constructor() {
        name = "Super Smart Token";
        symbol = "SST";
        price = 0.01 ether;
        hardCap = 100 ether;
        minPurchase = 0.1 ether;
        minFundsToReach = 2 ether;
        salePaused = false;
        owner = msg.sender;

        preSaleTokens = 10;
        saleTokens = 60;
        teamTokens = 30;

        preSaleStartDate = 1640995200; // January 1, 2023
        preSaleEndDate = 1672531200; // February 2, 2024
        saleStartDate = 1640995200; // January 1, 2023
        saleEndDate = 1672531200; // February 2, 2024
    }

    /**
     * @dev Buy tokens at the current price
     */
    function buyTokens() public payable onlyWhileSaleNotPaused {
        require(msg.value >= minPurchase, "Minimum purchase amount not reached");
        require(address(this).balance <= hardCap, "Hard cap reached");

        uint256 tokensAmount = msg.value / price;
        require(tokensAmount <= saleTokens, "Insufficient tokens for sale");

        balances[msg.sender] += tokensAmount;
        saleTokens -= tokensAmount;
    }

    /**
     * @dev Pause token sales
     */
    function pauseSale() public onlyOwner {
        salePaused = true;
    }

    /**
     * @dev Resume token sales
     */
    function resumeSale() public onlyOwner {
        salePaused = false;
    }

    /**
     * @dev Distribute tokens to specified recipients
     * @param recipients Addresses of token recipients
     * @param amounts Amounts of tokens to distribute
     */
    function distributeTokens(address[] calldata recipients, uint256[] calldata amounts) public onlyOwner {
        require(recipients.length == amounts.length, "Address and amount mismatch");
        
        for (uint256 i = 0; i < recipients.length; i++) {
            balances[recipients[i]] += amounts[i];
            saleTokens -= amounts[i];
        }
    }

    /**
     * @dev Withdraw raised funds after the end of token sales
     */
    function withdrawFunds() public view onlyOwner onlyAfterSaleEnd {
        require(address(this).balance >= minFundsToReach, "Insufficient funds collected");

        // Withdraw funds logic
    }
}