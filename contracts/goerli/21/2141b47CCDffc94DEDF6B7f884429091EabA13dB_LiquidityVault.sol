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
import "./IBaseToken.sol";

//**********************************//
//    LIQUIDITY  V  A  U  L  T  
//**********************************//
contract LiquidityVault is BasicAccessControl {
    using SafeERC20 for IBaseToken;

    IUniswapV2Router02  public     swapRouter;
    uint256             public     targetBalance;
    bool                public     immutable isMutable;

    address             internal  _externalSafe;
    address             internal  _baseToken; 
    address             internal  _contractManager;
    bool                internal  _isInitialized;
    bool                internal  _inLiquidityProcess; 
    address             internal  _liquidityPair;

    modifier nonReentrant {
        _inLiquidityProcess = true;
        _;
        _inLiquidityProcess = false;
    }

    uint8 constant Contract_Manager     = 1;
    uint8 constant Financial_Controller = 11;
    uint8 constant Compliance_Auditor   = 12;
    uint8 constant Linked_Contract      = 2;

    event BalanceLimitUpdated   (address authorizer, uint256 targetBalance);
    event ExternalSafeUpdated   (address authorizer, address _externalSafe);
    event VaultReservesReleased (address authorizer, address _externalSafe, uint256 _releasedValue);
    event CoinBalanceReleased   (address authorizer, address _externalSafe, uint256 _releasedValue);
    event Tokeninitialized      (address authorizer, address _externalSafe, uint256 targetBalance);
    event LiquidityIncreased    (address authorizer, uint256 tradedTokens, uint256 tradedCoins);   

    constructor (address _manager, bool _isMutable)  {
       
        _contractManager = _manager;
        isMutable       = _isMutable;

        _setupRole(Contract_Manager,        _contractManager);
        _setupRole(Financial_Controller,    _contractManager);
        _setupRole(Compliance_Auditor,      _contractManager);

        _setRoleAdmin(Contract_Manager,     Contract_Manager);
        _setRoleAdmin(Financial_Controller, Contract_Manager);
        _setRoleAdmin(Compliance_Auditor,   Contract_Manager);
    }

//   ======================================
//          Internal Functions                    
//   ====================================== 

    function _specialLiquidity(uint256 _tokenBalance, uint256 _coinBalance) private nonReentrant returns (uint256 tradedTokens, uint256 tradedCoins) {
      (tradedTokens, tradedCoins) = _liquidityProcess(_tokenBalance, _coinBalance);
    }

    function _autoLiquidity (uint256 numTokensToLiquidity) private nonReentrant returns (uint256 tradedTokens, uint256 tradedCoins) {

        // **** Split the 'numTokensToLiquidity' into halves  ***
        uint256 swapAmount = numTokensToLiquidity / 2;
        uint256 liquidityAmount = numTokensToLiquidity - swapAmount;

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
        (tradedTokens, tradedCoins) = _liquidityProcess(liquidityAmount, swappedCoins);
        
        emit LiquidityIncreased (_msgSender(), tradedTokens, tradedCoins);  
    }
    
    function _swapProcess (uint256 swapAmount) private {

        address[] memory path = new address[](2);    // Generate the DEX pair path of token -> weth
        path[0] = _baseToken;   
        path[1] = swapRouter.WETH();

        // Make the Swap
        swapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            swapAmount,
            0, 				// Accept any amount of Coins
            path,
            address(this),  // Recipient of the ETH/BNB 
            block.timestamp
        );
    }

    function _liquidityProcess (uint256 tokenAmount, uint256 coinAmount) private returns (uint256 tradedTokens, uint256 tradedCoins)
    {
        // Add the liquidity
        (tradedTokens, tradedCoins,) = swapRouter.addLiquidityETH{value: coinAmount}(
            _baseToken,
            tokenAmount,
            0,              // slippage is unavoidable
            0,              // slippage is unavoidable
            address(this),  // Recipient of the liquidity tokens.
            block.timestamp  );
    }

    function _setRouterAndPair(address _newRouter, address baseToken_) private {
        swapRouter = IUniswapV2Router02(_newRouter);
        _liquidityPair = IUniswapV2Factory(swapRouter.factory()).getPair(baseToken_, swapRouter.WETH());
        if (_liquidityPair == address(0)) {
            _liquidityPair = IUniswapV2Factory(swapRouter.factory()).createPair(baseToken_, swapRouter.WETH());}
       
        // swapRouter Infinite Approve
        IBaseToken(baseToken_).safeApprove(address(swapRouter), type(uint256).max);
  
    }
//   ======================================
//          External Functions                    
//   ======================================

    function initializeVault(address _newToken, address _newRouter, address _newExternalSafe, uint256 _targetBalance) external onlyRole(Financial_Controller) {
        require (!_isInitialized, "Token already initialized");
        require (_targetBalance > 0, "Target limit invalid");
        require (hasRole(Financial_Controller, _newExternalSafe),"ExternalSafe without the needed role");

        _baseToken         = _newToken;
        _externalSafe      = _newExternalSafe;
        targetBalance      = _targetBalance * (10**18);
        _setRouterAndPair(_newRouter,  _newToken);
        _setupRole(Linked_Contract,    _newToken);
        _setRoleAdmin(Linked_Contract,  Linked_Contract);
        _isInitialized     = true;
        
        emit Tokeninitialized (_msgSender(), _externalSafe, targetBalance);
    }

    function updateRouter(address _newRouter) external  onlyRole(Contract_Manager) {
        _setRouterAndPair(_newRouter, _baseToken);
    }

    function getTokenPrice () public view returns(uint256) {

        IBaseToken T0 = IBaseToken(IUniswapV2Pair(_liquidityPair).token0());
        IBaseToken T1 = IBaseToken(IUniswapV2Pair(_liquidityPair).token1());

        (uint256 _reservesT0, uint256 _reservesT1,) = IUniswapV2Pair(_liquidityPair).getReserves();

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
        _externalSafe = _newExternalSafe;
        emit ExternalSafeUpdated (_msgSender(), _externalSafe);
    }

    function changeBalanceLimit (uint256 _targetBalance) external onlyRole(Compliance_Auditor)  {
        require (isMutable, "This contract is immutable.");
        require (_isInitialized, "Vault is not initialized");
        require (_targetBalance > 0, "Limit invalid");
        targetBalance      = _targetBalance * (10**18);
        emit BalanceLimitUpdated (_msgSender(), _targetBalance);
    }

    function autoLiquidity (uint256 _numTokensToLiquidity) external onlyRole(Linked_Contract) returns (uint256 tradedTokens, uint256 tradedCoins)
    {
        require (_isInitialized, "Vault is not initialized");
        (tradedTokens, tradedCoins) = _autoLiquidity (_numTokensToLiquidity);
    }

    function specialLiquidity () external onlyRole(Financial_Controller) {
        require (_isInitialized, "Vault is not initialized");
        (uint256 _tokenBalance, uint256 _coinBalance, bool actionNeed) = liquidityStatus ();
        require (actionNeed, "Vault Reserves below limit");
        
        (uint256 tradedTokens, uint256 tradedCoins) = _specialLiquidity(_tokenBalance, _coinBalance);

        emit LiquidityIncreased (_msgSender(), tradedTokens, tradedCoins);  
    }

    function releaseTokenReserves () external onlyRole(Financial_Controller) {
        require (_isInitialized, "Vault is not initialized");
        (uint256 _tokenBalance, uint256 _coinBalance, bool _actionNeed) = liquidityStatus ();
        require (_tokenBalance > 0, "Balance must be greater than 0");

        if (_actionNeed) {
            (uint256 tradedTokens, uint256 tradedCoins) = _liquidityProcess(_tokenBalance, _coinBalance);
             emit LiquidityIncreased (_msgSender(), tradedTokens, tradedCoins); 
             _tokenBalance = IBaseToken(_baseToken).balanceOf(address(this));
        }

        if (_tokenBalance > 0 ){
            IBaseToken(_baseToken).safeTransfer(_externalSafe, _tokenBalance);
            emit VaultReservesReleased (_msgSender(), _externalSafe, _tokenBalance);
        }
    }

    function releaseCoinReserves () external onlyRole(Financial_Controller) {
        require (_isInitialized, "Vault is not initialized");
        (uint256 _tokenBalance, uint256 _coinBalance, bool _actionNeed) = liquidityStatus ();
        require(_coinBalance > 0, "Balance must be greater than 0");

        if (_actionNeed) {
            (uint256 tradedTokens, uint256 tradedCoins) = _liquidityProcess(_tokenBalance, _coinBalance);
             emit LiquidityIncreased (_msgSender(), tradedTokens, tradedCoins); 
            _coinBalance = address(this).balance; 
        }

        if (_coinBalance > 0) {
        payable(_externalSafe).transfer(_coinBalance);
        emit CoinBalanceReleased (_msgSender(), _externalSafe, _coinBalance);
        }
    }

    function liquidityStatus () public view returns (uint256 tokenBalance, uint256 coinBalance, bool actionNeed){
        coinBalance  = address(this).balance;
        tokenBalance = IBaseToken(_baseToken).balanceOf(address(this)); 
        actionNeed   = (tokenBalance > 0 && coinBalance >= targetBalance);
    }

    function isInitialized() external view returns (bool) {
        return _isInitialized;
    }

    function isAddingLiquidity() external view returns (bool) {
        return _inLiquidityProcess;
    }

    function liquidityPair() external view returns (address) {
        return _liquidityPair;
    }

    function baseToken() external view returns (address) {
        return _baseToken;
    }

    function contractManager() external view returns (address) {
        return _contractManager;
    }

    function externalSafe() external view returns (address) {
        return _externalSafe;
    }
//   ======================================
//     To receive Coins              
//   ======================================

    receive() external payable {} 

}