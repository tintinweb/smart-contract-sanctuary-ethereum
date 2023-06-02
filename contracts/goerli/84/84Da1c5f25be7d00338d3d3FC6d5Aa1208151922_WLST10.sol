// SPDX-License-Identifier: MIT

/*
==== WLST10 TOKENOMICS ====

Total supply: 1,000,000
Presale: 300,000
Team: 200,000
Liquidity pool: 500,000

==== CONTRACT FUNCTIONS ==== 

1. Airdrop (pre-saler tokens distribution)
2. Blacklist (anti-bots)
3. Whitelist (pre-saler) 
4. Linearly declining sell tax rate for WL (dump prevention)
5. Holdinglimit (whale prevention)
*/

pragma solidity ^0.8.0;

import { ERC20 } from "./2.ERC20.sol";
import { Ownable } from "./3.Ownable.sol";


// ==== Contract definition =====
contract WLST10 is Ownable, ERC20 {

    // ==== Variables declaration ====
        // ==== LP-related variables ====
        address public uniswapContractAddress;
        uint256 public tradingStartTime;

        // ===== Whale prevention-related variables
        bool public holdLimitState = false;
        uint256 public holdLimitAmount;

        // ===== Tax-related variables ====
        address public taxWallet;
        uint256 public NewWLTaxRate;
        uint256 public WLTaxWindow = 30 minutes; // CHANGE WL TAX PERIOD - 15 minutes
        uint256 public WLTaxRate = 3000; // WL STARTING TAX RATE at 30% defined in bp format
        uint256 public WLTaxInterval = 1 minutes; 
    
        // ===== BL & WL variables
        mapping(address => bool) public blacklisted;
        mapping(address => bool) public whitelisted;

        // ==== Emit events declaration ====   DIFFERENT     
        event Blacklisted(address indexed _address);
        event Whitelisted(address indexed _address);
        event UnBlacklisted(address indexed _address);
        event UnWhitelisted(address indexed _address);

    // ==== Constructor definition (Sets total supply & tax wallet address ====
    constructor(uint256 _totalSupply, address _taxWallet) ERC20("WLST10", "WLST10") { 
        _mint(msg.sender, _totalSupply);
        taxWallet = _taxWallet;
    }

    // ==== Token airdrop function ====
    function airdropTokens(address[] calldata recipients, uint256[] calldata amounts) external onlyOwner   {
        require(recipients.length == amounts.length, "Mismatched input arrays");

        for (uint256 i = 0; i < recipients.length; i++) {
            _transfer(owner(), recipients[i], amounts[i]);
        }
    }

    // ==== Set holding limit ====
    function setHoldLimit (bool _holdLimitState, uint256 _holdLimitAmount) external onlyOwner   {
        holdLimitState = _holdLimitState;
        holdLimitAmount = _holdLimitAmount;
    }

    // ==== BL function ====
   function blacklist(address[] calldata _address, bool _isBlacklisted) external onlyOwner {
        for (uint256 i = 0; i < _address.length; i++) {
            blacklisted[_address[i]] = _isBlacklisted;
            if (_isBlacklisted) {
                emit Blacklisted(_address[i]);
            } else {
                emit UnBlacklisted(_address[i]);
            }
        }
    }

    // ==== WL function ====
     function whitelist(address[] calldata _address, bool _isWhitelisted) external onlyOwner {
        for (uint256 i = 0; i < _address.length; i++) {
            whitelisted[_address[i]] = _isWhitelisted;
            if (_isWhitelisted) {
                emit Whitelisted(_address[i]);
            } else {
                emit UnWhitelisted(_address[i]);
            }
        }
    }

    // ==== Set WL Tax ====
    function setWLTaxSettings(uint256 _WLTaxWindow, uint256 _WLTaxRate, uint256 _WLTaxInterval) external onlyOwner  {
        WLTaxWindow = _WLTaxWindow;
        WLTaxRate = _WLTaxRate;
        WLTaxInterval = _WLTaxInterval;
    }

    /*// ==== Calculate amount of tokens to be transfered ==== //DIFFERENT 
    function calculateTransferAmount(address from, address to, uint256 amount) internal returns (uint256 transferAmount, uint256 taxAmount) {
        bool isWhitelisted = whitelisted[to] || whitelisted[from]; // Check if wallet is WL
        uint256 timePassed = block.timestamp - tradingStartTime; // Check amount of time that have passed since trading started
        uint256 intervalsPassed = timePassed / WLTaxInterval; // Calculate number of intervals based on time passed
        uint256 taxReduction = intervalsPassed * WLTaxInterval * WLTaxRate / WLTaxWindow; // Calculate amount of tax to be adjusted
        NewWLTaxRate = WLTaxRate - taxReduction; // Calculate new tax rate based on amount of time that have passed
    
        if (timePassed > WLTaxWindow) { //Condition where WL tax period have ended
            transferAmount = amount;
            taxAmount = 0;
            NewWLTaxRate = 0;
        }
       
        else if (isWhitelisted && (to == uniswapContractAddress || whitelisted[from]) && NewWLTaxRate > 0) { // Condition where wallet is WL and sell transaction
                require(amount > 1 ether, "Transfer amount must be greater than 1 token due to tax implications"); // Prevent 1 token sell transfer transaction to avoid 0 token transfer and gas
                taxAmount = amount * NewWLTaxRate / 10000;  // Calculate amount of tokens to be taxed
                transferAmount = amount - taxAmount; // Calculate amount of token after tax
        }else {
                transferAmount = amount;
                taxAmount = 0;
        }
        return (transferAmount, taxAmount);
    }*/

    // ==== Calculate amount of tokens to be transfered ====
    function calculateTransferAmount(address from, address to, uint256 amount) internal returns (uint256 transferAmount, uint256 taxAmount) {
        bool isWhitelisted = whitelisted[to] || whitelisted[from]; // Check if wallet is WL

        if (isWhitelisted && (to == uniswapContractAddress || whitelisted[from])) { // Condition where wallet is WL and sell transaction
            uint256 timePassed = block.timestamp - tradingStartTime; // Check amount of time that have passed since trading started
            uint256 intervalsPassed = timePassed / WLTaxInterval; // Calculate number of intervals based on time passed
            uint256 taxReduction = intervalsPassed * WLTaxInterval * WLTaxRate / WLTaxWindow; // Calculate amount of tax to be adjusted
            if (timePassed > WLTaxWindow) { //Condition where WL tax period have ended
                transferAmount = amount;
                taxAmount = 0;
                NewWLTaxRate = 0;
            } else {
                NewWLTaxRate = WLTaxRate - taxReduction; // Calculate new tax rate based on amount of time that have passed
            }
            require(amount > 1 ether, "Transfer amount must be greater than 1 token due to tax implications"); // Prevent 1 token sell transfer transaction to avoid 0 token transfer and gas
            if (NewWLTaxRate > 0) {
                taxAmount = amount * NewWLTaxRate / 10000;  // Calculate amount of tokens to be taxed
                transferAmount = amount - taxAmount; // Calculate amount of token after tax
                          
            } else {
                transferAmount = amount;
                taxAmount = 0;
            }
        } else {
            transferAmount = amount;// 0 sell tax for non-WL addresses 
            taxAmount = 0;     
            }
        return (transferAmount, taxAmount);
    }

    // ==== set Uniswap V2 Pair address ====
    function setUniswapContractAddress(address _uniswapContractAddress) external onlyOwner   {
        require(tradingStartTime == 0, "Can only set pair once.");
        uniswapContractAddress = _uniswapContractAddress;
        tradingStartTime = block.timestamp;
    }
    
   // ==== Token transfer logic ====
   function _transfer(
    address from, 
    address to, 
    uint256 amount
    ) internal virtual override {
        // Calculate transfer and tax amounts
        (uint256 transferAmount, uint256 taxAmount) = calculateTransferAmount(from, to, amount);

        // Transfer calculated amounts
        if (taxAmount == 0){
            super._transfer(from, to, transferAmount);
        }
        else {
            super._transfer(from, to, transferAmount);
            super._transfer(from, taxWallet, taxAmount);
        }
    }


    // ==== Checks before token transfer happens ====
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) override internal virtual  {      
        // ==== Check if wallet is blacklisted ====
        require(!blacklisted[to] && !blacklisted[from], "Wallet is blacklisted");

        // ==== Check if trading started ====
        if (uniswapContractAddress == address(0) && from != address(0)) {
            require(from == owner(), "Trading yet to begin");
            return;
        }

        // ==== Check if successful buy transaction will exceed holding limit ====
        if (holdLimitState && from == uniswapContractAddress) {
            require(super.balanceOf(to) + amount <= holdLimitAmount, "Exceeds allowable holding limit per wallet");
        }

    }
}