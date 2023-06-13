/**
 *Submitted for verification at Etherscan.io on 2023-06-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract GorilaToken {
    string public name = "Gorila";
    string public symbol = "GOL";
    uint8 public decimals = 18;
    uint256 public totalSupply = 1000000000 * (10**uint256(decimals));
    address public owner;
    uint256 public taxBuyPercentage = 20;
    uint256 public taxSellPercentage = 35;
    bool public tradingEnabled = true;
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowances;
    mapping(address => bool) public blacklist;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event TradingStatusUpdated(bool enabled);
    event AccountBlacklisted(address indexed account);
    event AccountWhitelisted(address indexed account);
    event TaxPercentageUpdated(uint256 percentage);
    event OwnershipRenounced(address indexed previousOwner);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can perform this action.");
        _;
    }

    modifier tradingAllowed() {
        require(tradingEnabled, "Trading is currently disabled.");
        _;
    }

    constructor() {
        owner = msg.sender;
        balances[owner] = totalSupply;
    }

    function transfer(address _to, uint256 _value) public tradingAllowed returns (bool) {
        require(_to != address(0), "Invalid recipient address.");
        require(_value <= balances[msg.sender], "Insufficient balance.");

        uint256 taxAmount = (_value * taxSellPercentage) / 100;
        uint256 transferAmount = _value - taxAmount;

        balances[msg.sender] -= _value;
        balances[_to] += transferAmount;

        emit Transfer(msg.sender, _to, transferAmount);

        if (taxAmount > 0) {
            balances[owner] += taxAmount;
            emit Transfer(msg.sender, owner, taxAmount);
        }

        return true;
    }

    function approve(address _spender, uint256 _value) public tradingAllowed returns (bool) {
        require(_spender != address(0), "Invalid spender address.");

        allowances[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);

        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public tradingAllowed returns (bool) {
        require(_to != address(0), "Invalid recipient address.");
        require(_value <= balances[_from], "Insufficient balance.");
        require(_value <= allowances[_from][msg.sender], "Insufficient allowance.");

        uint256 taxAmount = (_value * taxSellPercentage) / 100;
        uint256 transferAmount = _value - taxAmount;

        balances[_from] -= _value;
        balances[_to] += transferAmount;
        allowances[_from][msg.sender] -= _value;

        emit Transfer(_from, _to, transferAmount);

        if (taxAmount > 0) {
            balances[owner] += taxAmount;
            emit Transfer(_from, owner, taxAmount);
        }

        return true;
    }

    function enableTrading() public onlyOwner {
        require(!tradingEnabled, "Trading is already enabled.");

        tradingEnabled = true;
        emit TradingStatusUpdated(true);
    }

    function disableTrading() public onlyOwner {
        require(tradingEnabled, "Trading is already disabled.");

        tradingEnabled = false;
        emit TradingStatusUpdated(false);
    }

    function blacklistAccount(address _account) public onlyOwner {
        require(!blacklist[_account], "Account is already blacklisted.");

        blacklist[_account] = true;
        emit AccountBlacklisted(_account);
    }

    function whitelistAccount(address _account) public onlyOwner {
        require(blacklist[_account], "Account is not blacklisted.");

        blacklist[_account] = false;
        emit AccountWhitelisted(_account);
    }

    function modifyTaxPercentage(uint256 _percentage) public onlyOwner {
        require(_percentage >= 0 && _percentage <= 100, "Tax percentage must be between 0 and 100.");

        taxBuyPercentage = _percentage;
        taxSellPercentage = _percentage;
        emit TaxPercentageUpdated(_percentage);
    }

    function renounceOwnership() public onlyOwner {
        owner = address(0);
        emit OwnershipRenounced(msg.sender);
    }
}