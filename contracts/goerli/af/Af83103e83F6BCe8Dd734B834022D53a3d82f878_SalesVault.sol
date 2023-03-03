//SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./Context.sol";
import "./SafeERC20.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./BasicAccessControl.sol";

//    Interfaces   

import "./IBaseToken.sol";
import "./ILiquidityVault.sol";

/**
 * @title Salesvault
 * @dev Salesvault is a base contract for managing a token crowdsale,
 * allowing investors to purchase tokens with ether. 
 */
contract SalesVault is BasicAccessControl, Pausable, ReentrancyGuard {
    using SafeERC20 for IBaseToken;

    // The token being sold
    address private _baseToken;

    // Address where funds are collected
    address payable private _liquidityVault;

    // The Discount Rate is the discount applied to the sales.
    uint256 private _discountRate;

    // Amount of funds raised and tokens sold
    uint256 private _fundsRaised;
    uint256 private _tokensSold;

    mapping(address => uint256) _salesLedger;

    uint256 _maxInvestPerUser;

    bool public isSalesActive;

    uint8 constant Contract_Manager     = 1;
    uint8 constant Financial_Controller = 11;
    uint8 constant Compliance_Auditor   = 12;

    // ======================
    //    E  V  E  N  T  S
    // ======================

    event TokensPurchased(address indexed investor, uint256 valueInvested, uint256 tokensReceived);
    event SalesFinalized(address authorizer, uint256 tokensSold, uint256 fundsRaised);
    event SalesInitiated(address authorizer, uint256 tokensToSale);
    event SecurityPause(address authorizer, bool isPause);

    // ======================
    // Constructor Function
    // ======================

    constructor (address payable liquidityVault) {
        require(address(liquidityVault) != address(0), "Vault address invalid");
        require(ILiquidityVault(liquidityVault).isInitialized(), "Vault not initialized");

        _liquidityVault   = liquidityVault;
        _baseToken        = ILiquidityVault(liquidityVault).baseToken();
        _maxInvestPerUser = IBaseToken(_baseToken).maxWalletBalance() / 5;

        address contractManager = ILiquidityVault(_liquidityVault).contractManager();

        _setupRole(Contract_Manager,        contractManager);
        _setupRole(Financial_Controller,    contractManager);
        _setupRole(Compliance_Auditor,      contractManager);

        _setRoleAdmin(Contract_Manager,     Contract_Manager);
        _setRoleAdmin(Financial_Controller, Contract_Manager);
        _setRoleAdmin(Compliance_Auditor,   Contract_Manager);
    }

    /**
     * @dev fallback function ***DO NOT OVERRIDE***
     * Note that other contracts will transfer funds with a base gas stipend
     * of 2300, which is not enough to call buyTokens. Consider calling
     * buyTokens directly when purchasing tokens from a contract.
     */
    receive () external payable {
        buyTokens(_msgSender());
    }

    /**
     * @dev low level token purchase ***DO NOT OVERRIDE***
     * This function has a non-reentrancy guard, so it shouldn't be called by
     * another `nonReentrant` function.
     * @param investor Recipient of the token purchase
     */
    function buyTokens(address investor) public nonReentrant whenNotPaused payable {
        uint256 coinAmount = msg.value;
        uint256 tokenAmount = _getTokenAmount(coinAmount);

        _preValidatePurchase(investor, coinAmount, tokenAmount);

        _processPurchase(investor, tokenAmount);

        emit TokensPurchased(investor, coinAmount, tokenAmount);

        _updatePurchasingState(investor, coinAmount, tokenAmount);

        _transferToVault(coinAmount, _tokensToLiquidity(tokenAmount));
    }


    // ===================================
    // I N T E R N A L   F U N C T I O N S 
    // ===================================

    /**
     * @dev Validation of an incoming purchase. Use require statements to revert state when conditions are not met.
     */
    function _preValidatePurchase(address investor, uint256 coinAmount, uint256 tokenAmount) internal view {
        require(isSalesActive, "Salesvault is not active");
        require(investor != address(0), "Investor address is invalid");
        require(coinAmount != 0, "CoinAmount can not be 0");
        require(IBaseToken(_baseToken).balanceOf(address(this)) >= tokenAmount, "Insufficient funds for this transaction");
        require(getInvestedValue(investor) + tokenAmount <= _maxInvestPerUser, "Investor already bought the maximum tokens allowed");
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    } 

    /**
     * @dev Source of tokens. Override this method to modify the way in which the crowdsale ultimately gets and sends
     * its tokens.
     * @param investor Address performing the token purchase
     * @param tokenAmount Number of tokens to be sent
     */
    function _deliverTokens(address investor, uint256 tokenAmount) internal {
        IBaseToken(_baseToken).safeTransfer(investor, tokenAmount);
    }

    /**
     * @dev Executed when a purchase has been validated and is ready to be executed. Doesn't necessarily emit/send
     * tokens.
     * @param investor Address receiving the tokens
     * @param tokenAmount Number of tokens to be purchased
     */
    function _processPurchase(address investor, uint256 tokenAmount) internal {
        _deliverTokens(investor, tokenAmount);
    }

    /**
     * @dev Override for extensions that require an internal state to check for validity (current user contributions,
     * etc.)
     * @param investor Address receiving the tokens
     * @param coinAmount Value in coin involved in the purchase
     */
    function _updatePurchasingState(address investor, uint256 coinAmount, uint256 tokenAmount) internal {
        _fundsRaised           += coinAmount;
        _tokensSold            += tokenAmount;
        _salesLedger[investor] += tokenAmount;
    }

    function _tokensToLiquidity(uint256 tokenAmount) internal view returns (uint256 tokensToLiquidity) {
        uint256 _contractBalance = IBaseToken(_baseToken).balanceOf(address(this));
        tokensToLiquidity = (_contractBalance >= tokenAmount) ? tokenAmount : _contractBalance;
    }

    /**
     * @dev Override to extend the way in which ether is converted to tokens.
     * @param coinAmount Value in coin to be converted into tokens
     * @return Number of tokens that can be purchased with the specified _coinAmount
     */
    function _getTokenAmount(uint256 coinAmount) internal view returns (uint256) {
        return (coinAmount * salePrice()) / (10 ** 18);
    }

    /**
     * @dev Determines how funds is stored/forwarded on purchases.
     */
    function _transferToVault(uint256 coinAmount, uint256 tokenAmount) internal {
        _liquidityVault.transfer(coinAmount);
        IBaseToken(_baseToken).safeTransfer(_liquidityVault, _tokensToLiquidity(tokenAmount));
    }

    function _finalizeSales() internal {
        uint256 _tokenBalance = IBaseToken(_baseToken).balanceOf(address(this));
        uint256 _coinBalance =  address(this).balance;

        if (_tokenBalance > 0) { 
            IBaseToken(_baseToken).salesClearance();
        }

        if (_coinBalance > 0) {
            _liquidityVault.transfer(_coinBalance);
        } 
       
        emit  SalesFinalized(_msgSender(), _tokensSold, _fundsRaised);

        isSalesActive = false;
    }

    // ===================================
    // E X T E R N A L   F U N C T I O N S 
    // ===================================

    function initiateSales (uint256 discountRate) external onlyRole(Contract_Manager) {
        uint256 _contractBalance = IBaseToken(_baseToken).balanceOf(address(this));
        require (!isSalesActive, "Sales are already active");
        require (_contractBalance >= IBaseToken(_baseToken).maxWalletBalance(), "insufficient balance on the contract");
        require(discountRate >= 0 && discountRate <= 15, "Invalid discount rate");

        _discountRate = discountRate;
        isSalesActive = true;

        emit SalesInitiated(_msgSender(), _contractBalance);
    }

    function finalizeSales () external whenNotPaused onlyRole(Financial_Controller) {
        require (isSalesActive, "Sales are not active");
        _finalizeSales();
    }

      // Called by the Compliance Auditor on emergency, allow begin or end an emergency stop
    function setSecurityPause (bool isPause) external onlyRole(Compliance_Auditor) {
        if (isPause)  {
            _pause();
        } else {
            _unpause();  
        }

        emit SecurityPause(_msgSender(), isPause);
    }


    // ===================================
    // P U B L I C    F U N C T I O N S 
    // ===================================
     /**
     * @return the token being sold.
     */
    function baseToken() public view returns (address) {
        return _baseToken;
    }

    /**
     * @return the address where funds are collected.
     */
    function LiquidityVault() public view returns (address payable) {
        return _liquidityVault;
    }

    /**
     * @return the original token price.
     */
    function tokenPrice() public view returns (uint256) {
        return ILiquidityVault(_liquidityVault).getTokenPrice();
    }

    /**
     * @return the number of token units a buyer gets per coin.
     */
    function salePrice() public view returns (uint256) {
        uint256 _tokenPrice =  tokenPrice();
        return _tokenPrice - ((_tokenPrice * _discountRate) / 100);
    }

    /**
     * @return the max amount of investment per user.
     */
    function maxInvestPerUser() public view returns (uint256) {
        return _maxInvestPerUser;
    }

    /**
     * @return the amount of coin raised.
     */
    function fundsRaised() public view returns (uint256) {
        return _fundsRaised;
    }

    /**
     * @return the tokens bought by an investor.
     */
    function getInvestedValue (address investor) public view returns (uint256) {
        return  _salesLedger[investor];
    }
}