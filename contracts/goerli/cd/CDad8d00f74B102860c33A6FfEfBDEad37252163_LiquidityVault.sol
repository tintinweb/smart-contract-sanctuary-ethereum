//SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./Context.sol";
import "./Address.sol";
import "./SafeERC20.sol";
import "./BasicAccessControl.sol";

//    Interfaces   

import "./IUniswapV2Router01.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
import "./ISymplexiaToken.sol";

//**********************************//
//    LIQUIDITY  V  A  U  L  T  
//**********************************//
contract LiquidityVault is BasicAccessControl {
    using SafeERC20 for ISymplexiaToken;

    address             public tokenBase; 
    uint256             public targetBalance;
    bool                public isInitialized;

    bool internal inLiquidityProcess; 

    modifier nonReentrant {
        inLiquidityProcess = true;
        _;
        inLiquidityProcess = false;
    }
        
    address public   externalSafe;
    address public   contractManager;
    bool    public   immutable isMutable;

    uint8 constant Contract_Manager     = 1;
    uint8 constant Financial_Controller = 11;
    uint8 constant Compliance_Auditor   = 12;
    uint8 constant Linked_Contract      = 2;

    event BalanceLimitUpdated   (address authorizer, uint256 targetBalance);
    event ExternalSafeUpdated   (address authorizer, address externalSafe);
    event VaultReservesReleased (address authorizer, address externalSafe, uint256 _releasedValue);
    event CoinBalanceReleased   (address authorizer, address externalSafe, uint256 _releasedValue);
    event Tokeninitialized      (address authorizer, address externalSafe, uint256 targetBalance);
    event LiquidityIncreased    (address authorizer, uint256 tradedTokens, uint256 tradedCoins);   

    constructor (address _manager, bool _isMutable)  {
       
        contractManager = _manager;
        isMutable       = _isMutable;

        _setupRole(Contract_Manager,        contractManager);
        _setupRole(Financial_Controller,    contractManager);
        _setupRole(Compliance_Auditor,      contractManager);
       

        _setRoleAdmin(Contract_Manager,     Contract_Manager);
        _setRoleAdmin(Financial_Controller, Contract_Manager);
        _setRoleAdmin(Compliance_Auditor,   Contract_Manager);

    }

//   ======================================
//          Internal Functions                    
//   ====================================== 

    function _mandatoryLiquidity(uint256 _tokenBalance, uint256 _coinBalance) private nonReentrant returns (uint tradedTokens, uint tradedCoins) {
      (tradedTokens, tradedCoins) = _liquidityProcess(_tokenBalance, _coinBalance);
    }

    function _autoLiquidity (uint256 numTokensToLiquidity) private nonReentrant {

        // **** Split the 'numTokensToLiquidity' into halves  ***
        uint256 swapAmount = numTokensToLiquidity / 2;
        uint256 liquidityAmount;

        // NOTE: Capture the contract's current Coins balance,  
        // thus we can know exactly how much Coins the swap 
        // creates, and not make recent events include any Coin  
        // that has been manually sent to the contract. 
        uint256 initialCoinBalance = address(this).balance;

        // Swap tokens for Coins (01)
        _swapProcess(swapAmount);

        // Calculate how much Coins was swapped
        uint256  swappedCoins  = address(this).balance - initialCoinBalance;

        // Add liquidity to DEX  (02)
        (uint256 tradedTokens, uint256 tradedCoins) = _liquidityProcess(liquidityAmount, swappedCoins);

        emit LiquidityIncreased (_msgSender(), tradedTokens, tradedCoins);  
    }
    
        function _swapProcess (uint256 swapAmount) private {

        IUniswapV2Router02 swapRouter = SwapRouter();

        address[] memory path = new address[](2);                       // Generate the DEX pair path of token -> weth
        path[0] = address(this);
        path[1] = swapRouter.WETH();

        // Approve token transfer to cover all possible scenarios
        ISymplexiaToken(tokenBase).approve(address(swapRouter), swapAmount);

        // Make the Swap
        swapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            swapAmount,
            0, 				// Accept any amount of Coins
            path,
            address(this),  // Recipient of the ETH/BNB 
            block.timestamp
        );
    }

    function _liquidityProcess (uint256 tokenAmount, uint256 coinAmount) private nonReentrant returns (uint tradedTokens, uint tradedCoins)
    {
        IUniswapV2Router02 swapRouter = SwapRouter();

        // Approve token transfer to cover all possible scenarios
        ISymplexiaToken(tokenBase).approve(address(swapRouter), tokenAmount);   

        // Add the liquidity
        (tradedTokens, tradedCoins,) = swapRouter.addLiquidityETH{value: coinAmount}(
            tokenBase,
            tokenAmount,
            0,              // slippage is unavoidable
            0,              // slippage is unavoidable
            address(this),  // Recipient of the liquidity tokens.
            block.timestamp  );
    }

//   ======================================
//          External Functions                    
//   ======================================

    function initializeVault(address _tokenBase, address _externalSafe, uint256 _targetBalance) external onlyRole(Financial_Controller) {
        require (!isInitialized, "Token already initialized");
        require (_targetBalance >= 0, "Target limit invalid");
        require (hasRole(Financial_Controller, _externalSafe),"ExternalSafe without the needed role");

        tokenBase       = _tokenBase;
        _setupRole(Linked_Contract,         tokenBase);
        _setRoleAdmin(Linked_Contract,      Linked_Contract);
        externalSafe       = _externalSafe;
        targetBalance      = _targetBalance * (10**18);
        isInitialized      = true;
        
        emit Tokeninitialized (_msgSender(), externalSafe, targetBalance);
    }

    function getTokenPrice () public view returns(uint256) {

        address  liquidityPair = LiquidityPair();

        ISymplexiaToken T0 = ISymplexiaToken(IUniswapV2Pair(liquidityPair).token0());
        ISymplexiaToken T1 = ISymplexiaToken(IUniswapV2Pair(liquidityPair).token1());

        (uint256 _reservesT0, uint256 _reservesT1,) = IUniswapV2Pair(liquidityPair).getReserves();

        // Return amount of Token1 needed to buy Token0 (ETH/BNB)
        if (_reservesT0 == 0 || _reservesT1 == 0) return 0;
        if (address(T0) == address(this)) {
            return( (_reservesT0 * (10 ** uint256(T1.decimals() ))) / (_reservesT1) ); }
        else { 
            return( (_reservesT1 * (10 ** uint256(T0.decimals() ))) / (_reservesT0) ); }   
    }

    function changeExternalSafe (address _newExternalSafe) external onlyRole(Compliance_Auditor) {
        require (isMutable, "This contract is immutable.");
        require (hasRole(Financial_Controller, _newExternalSafe),"ExternalSafe without the needed role");
        externalSafe = _newExternalSafe;
        emit ExternalSafeUpdated (_msgSender(), externalSafe);
    }

    function changeBalanceLimit (uint256 _targetBalance) external onlyRole(Compliance_Auditor)  {
        require (isMutable, "This contract is immutable.");
        require (isInitialized, "Token is not initialized");
        require (_targetBalance >= 0, "Limit invalid");
        targetBalance      = _targetBalance * (10**18);
        emit BalanceLimitUpdated (_msgSender(), _targetBalance);
    }

    function autoLiquidity (uint256 _numTokensToLiquidity) external onlyRole(Linked_Contract) {
        _autoLiquidity (_numTokensToLiquidity);
    }

    function mandatoryLiquidity () external onlyRole(Financial_Controller) {
        require (isInitialized, "Token is not initialized");
        (uint256 _tokenBalance, uint256 _coinBalance, bool actionNeed) = liquidityStatus ();
        require (actionNeed, "Vault Reserves below limit");
        (uint256 tradedTokens, uint256 tradedCoins) = _mandatoryLiquidity(_tokenBalance, _coinBalance);
        emit LiquidityIncreased (_msgSender(), tradedTokens, tradedCoins);  
    }

    function releaseTokenReserves () external onlyRole(Financial_Controller) {
        require (isInitialized, "Token is not initialized");
        (uint256 _tokenBalance, uint256 _coinBalance, bool _actionNeed) = liquidityStatus ();
        require (_tokenBalance > 0, "Balance must be greater than 0");

        if (_actionNeed) {
            (uint256 tradedTokens, uint256 tradedCoins) = _liquidityProcess(_tokenBalance, _coinBalance);
             emit LiquidityIncreased (_msgSender(), tradedTokens, tradedCoins); 
             _tokenBalance = ISymplexiaToken(tokenBase).balanceOf(address(this));
        }

        if (_tokenBalance > 0 ){
            ISymplexiaToken(tokenBase).safeTransfer(externalSafe, _tokenBalance);
            emit VaultReservesReleased (_msgSender(), externalSafe, _tokenBalance);
        }
    }

    function releaseCoinReserves () external onlyRole(Financial_Controller) {
        require (isInitialized, "Token is not initialized");
        (uint256 _tokenBalance, uint256 _coinBalance, bool _actionNeed) = liquidityStatus ();
        require(_coinBalance > 0, "Balance must be greater than 0");

        if (_actionNeed) {
            (uint256 tradedTokens, uint256 tradedCoins) = _liquidityProcess(_tokenBalance, _coinBalance);
             emit LiquidityIncreased (_msgSender(), tradedTokens, tradedCoins); 
            _coinBalance = address(this).balance; 
        }

        if (_coinBalance > 0) {
        payable(externalSafe).transfer(_coinBalance);
        emit CoinBalanceReleased (_msgSender(), externalSafe, _coinBalance);
        }
    }

    function liquidityStatus () public view returns (uint256 tokenBalance, uint256 coinBalance, bool actionNeed){
        coinBalance  = address(this).balance;
        tokenBalance = ISymplexiaToken(tokenBase).balanceOf(address(this)); 
        actionNeed   = (tokenBalance > 0 && coinBalance >= targetBalance);
    }

    function SwapRouter() public view returns (IUniswapV2Router02){
        return ISymplexiaToken(tokenBase).SwapRouter();
    }

    function LiquidityPair() public view returns (address) {
        return ISymplexiaToken(tokenBase).LiquidityPair();
    }

//   ======================================
//     To receive Coins              
//   ======================================

    receive() external payable {} 

}