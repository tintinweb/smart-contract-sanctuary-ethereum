// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./IERC20.sol";

contract Cesar {
    string public name = "Cesar";
    string public symbol = "CSR";
    uint256 public totalSupply = 15000000 * 10 ** 18; // 15 millones de tokens con 18 decimales

    address public owner;
    address public developerWallet = 0x54900af60Ec3078Ba42F8f96194a83c1228E65e5;
    IERC20 public token;
    mapping(address => bool) public blacklist;

    uint256 private totalDividends;
    mapping(address => uint256) private dividendBalance;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event DividendDistributed(uint256 amount);
    event DeveloperFeePaid(uint256 amount);
    event Blacklisted(address indexed account);
    event RemovedFromBlacklist(address indexed account);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only contract owner can call this function");
        _;
    }

    modifier notBlacklisted() {
        require(!blacklist[msg.sender], "Sender is blacklisted");
        _;
    }

    constructor() {
        owner = msg.sender;
        token = IERC20(address(this));
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Invalid new owner address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function distributeDividends(uint256 amount) public onlyOwner {
        require(amount > 0, "Invalid dividend amount");
        require(token.balanceOf(address(this)) >= amount, "Insufficient contract balance");
        
        totalDividends += amount;
        emit DividendDistributed(amount);
    }

    function payDeveloperFee() private {
        uint256 developerFee = (totalDividends * 2) / 100;
        require(token.transfer(developerWallet, developerFee), "Developer fee transfer failed");
        emit DeveloperFeePaid(developerFee);
    }

    function claimDividends() public notBlacklisted {
        uint256 availableDividends = calculateDividends(msg.sender);
        require(availableDividends > 0, "No dividends available");

        dividendBalance[msg.sender] = 0;
        require(token.transfer(msg.sender, availableDividends), "Dividend transfer failed");
    }

    function calculateDividends(address account) public view returns (uint256) {
        uint256 accountBalance = token.balanceOf(account);
        uint256 accountDividends = (accountBalance * totalDividends) / token.totalSupply();
        return accountDividends - dividendBalance[account];
    }

    function addToBlacklist(address account) public onlyOwner {
        require(account != address(0), "Invalid account address");
        require(!blacklist[account], "Account is already blacklisted");

        blacklist[account] = true;
        emit Blacklisted(account);
    }

    function removeFromBlacklist(address account) public onlyOwner {
        require(blacklist[account], "Account is not blacklisted");

        blacklist[account] = false;
        emit RemovedFromBlacklist(account);
    }
}