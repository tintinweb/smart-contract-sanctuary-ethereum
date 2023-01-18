//SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./Context.sol";
import "./Address.sol";
import "./SafeERC20.sol";
import "./BasicAccessControl.sol";

//    Interfaces   

import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./IUniswapV2Router01.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";

//**********************************//
//    LIQUIDITY  V  A  U  L  T  
//**********************************//
contract LiquidityVault is BasicAccessControl {
    using SafeERC20 for IERC20;


    IUniswapV2Router02  public swapRouter;
    address             public tokenBase; 
    address             public liquidityPair;
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

    event BalanceLimitUpdated   (address authorizer, uint256 targetBalance);
    event ExternalSafeUpdated   (address authorizer, address externalSafe);
    event VaultReservesReleased (address authorizer, address externalSafe, uint256 _releasedValue);
    event CoinBalanceReleased   (address authorizer, address externalSafe, uint256 _releasedValue);
    event Tokeninitialized      (address authorizer, address _token, uint256 _targetBalance);
    event LiquidityIncreased    (address authorizer, uint256 tradedTokens, uint256 tradedCoins);   

    constructor (address _manager, bool _isMutable)  {
        
        contractManager = _manager;
        isMutable       = _isMutable;

        _setupRole(Contract_Manager,     contractManager);
        _setupRole(Financial_Controller, contractManager);
        _setupRole(Compliance_Auditor,   contractManager);

        _setRoleAdmin(Contract_Manager,     Contract_Manager);
        _setRoleAdmin(Financial_Controller, Contract_Manager);
        _setRoleAdmin(Compliance_Auditor,   Contract_Manager);
    }

//   ======================================
//          Internal Functions                    
//   ====================================== 

    function _liquidityProcess (uint256 tokenAmount, uint256 coinAmount) private nonReentrant returns (uint tradedTokens, uint tradedCoins)
    {
        // Approve token transfer to cover all possible scenarios
        IERC20(tokenBase).approve(address(swapRouter), tokenAmount);   

        // Add the liquidity
        (tradedTokens, tradedCoins,) = swapRouter.addLiquidityETH{value: coinAmount}(
            tokenBase,
            tokenAmount,
            0,              // slippage is unavoidable
            0,              // slippage is unavoidable
            address(this),  // Recipient of the liquidity tokens.
            block.timestamp  );
    }

    function getTokenPrice () public view returns(uint256) {
        IERC20Metadata T0 = IERC20Metadata(IUniswapV2Pair(liquidityPair).token0());
        IERC20Metadata T1 = IERC20Metadata(IUniswapV2Pair(liquidityPair).token1());

        (uint256 _reservesT0, uint256 _reservesT1,) = IUniswapV2Pair(liquidityPair).getReserves();

        // Return amount of Token1 needed to buy Token0 (ETH/BNB)
        if (_reservesT0 == 0 || _reservesT1 == 0) return 0;
        if (address(T0) == address(this)) {
            return( (_reservesT0 * (10 ** uint256(T1.decimals() ))) / (_reservesT1) ); }
        else { 
            return( (_reservesT1 * (10 ** uint256(T0.decimals() ))) / (_reservesT0) ); }   
    }


    function _updateRouterAndPair(address _swapRouter) internal {
        swapRouter = IUniswapV2Router02(_swapRouter);
        liquidityPair = IUniswapV2Factory(swapRouter.factory()).getPair(tokenBase,swapRouter.WETH());
    }

//   ======================================
//          External Functions                    
//   ======================================
    function initializeVault(address _tokenBase, address _swapRouter, address _externalSafe, uint256 _targetBalance) external onlyRole(Financial_Controller) {
        require (!isInitialized, "Token already initialized");
        require (_targetBalance >= 0, "Target limit invalid");
        require (hasRole(Financial_Controller, _externalSafe),"ExternalSafe without the needed role");
        externalSafe       = _externalSafe;
        tokenBase          = _tokenBase;
        targetBalance      = _targetBalance * (10**18);
        _updateRouterAndPair(_swapRouter);
        isInitialized      = true;
        emit Tokeninitialized (_msgSender(),_tokenBase, _targetBalance );
    }

    function updateRouter(address _swapRouter) external  onlyRole(Financial_Controller) {
            _updateRouterAndPair(_swapRouter);
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

    function increaseLiquidity () external onlyRole(Financial_Controller) {
        require (isInitialized, "Token is not initialized");
        (uint256 _tokenBalance, uint256 _coinBalance, bool actionNeed) = liquidityStatus ();
        require (actionNeed, "Vault Reserves below limit");
        (uint256 tradedTokens, uint256 tradedCoins) = _liquidityProcess(_tokenBalance, _coinBalance);
        emit LiquidityIncreased (_msgSender(), tradedTokens, tradedCoins);  
    }

    function releaseTokenReserves () external onlyRole(Financial_Controller) {
        require (isInitialized, "Token is not initialized");
        (uint256 _tokenBalance, uint256 _coinBalance, bool _actionNeed) = liquidityStatus ();
        require (_tokenBalance > 0, "Balance must be greater than 0");

        if (_actionNeed) {
            (uint256 tradedTokens, uint256 tradedCoins) = _liquidityProcess(_tokenBalance, _coinBalance);
             emit LiquidityIncreased (_msgSender(), tradedTokens, tradedCoins); 
             _tokenBalance = IERC20(tokenBase).balanceOf(address(this));
        }

        if (_tokenBalance > 0 ){
            IERC20(tokenBase).safeTransfer(externalSafe, _tokenBalance);
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
        tokenBalance = IERC20(tokenBase).balanceOf(address(this)); 
        actionNeed   = (tokenBalance > 0 && coinBalance >= targetBalance);
    }

//   ======================================
//     To receive Coins              
//   ======================================

    receive() external payable {} 

}