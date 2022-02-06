//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./interfaces/IAggregatorV3.sol";
import "./interfaces/IFixedRateMarket.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IERC20Metadata.sol";
import "./interfaces/IQollateralManager.sol";
import "./interfaces/IQontroller.sol";
import "./libraries/Initializable.sol";
import "./libraries/Math.sol";
import "./libraries/QConst.sol";
import "./libraries/QTypes.sol";
import "./libraries/SafeERC20.sol";
import "./Qontroller.sol";

contract QollateralManager is Initializable {

  using SafeERC20 for IERC20;

  /// @notice Only admin may perform admin functions
  address private _admin;

  /// @notice If liquidity ratio falls below `_minLiquidityRatio`, it is subject to liquidation
  /// Scaled by 1e8
  uint private _minLiquidityRatio;

  /// @notice When initially taking a loan, liquidity ratio must be higher than this.
  /// `_initLiquidityRatio` should always be higher than `_minLiquidityRatio`
  /// Scaled by 1e8
  uint private _initLiquidityRatio;

  /// @notice The percent, ranging from 0% to 100%, of a liquidatable account's
  /// borrow that can be repaid in a single liquidate transaction.
  /// Scaled by 1e8
  uint private _closeFactor;
  
  /// @notice Additional collateral given to liquidator as incentive to liquidate
  /// underwater accounts. For example, if liquidation incentive is 1.1, liquidator
  /// receives extra 10% of borrowers' collateral
  /// Scaled by 1e8
  uint private _liquidationIncentive;
  
  /// @notice Address of the `Qontroller`
  address private _qontrollerAddress;

  /// @notice Use this for quick lookups of collateral balances by asset
  /// account => tokenAddress => balanceLocal
  mapping(address => mapping(address => uint)) private _collateralBalances;

  /// @notice Iterable list of all assets which an account has nonzero balance.
  /// Use this when calculating `collateralValue` for liquidity considerations
  /// account => tokenAddresses[]
  mapping(address => address[]) private _iterableAccountAssets;

  /// @notice Iterable list of all markets which an account has participated.
  /// Use this when calculating `totalBorrowValue` for liquidity considerations
  /// account => fixedRateMarketAddresses[]
  mapping(address => address[]) private _iterableAccountMarkets;

  /// @notice Non-iterable list of assets which an account has nonzero balance.
  /// Use this for quick lookups
  /// tokenAddress => account => bool;
  mapping(address => mapping(address => bool)) private _accountAssets;

  /// @notice Non-iterable list of markets which an account has participated.
  /// Use this for quick lookups
  /// fixedRateMarketAddress => account => bool;
  mapping(address => mapping(address => bool)) private _accountMarkets;

  /// @notice Emitted when an account deposits collateral into the contract
  event DepositCollateral(address account, address tokenAddress, uint amount);

  /// @notice Emitted when an account withdraws collateral from the contract
  event WithdrawCollateral(address account, address tokenAddress, uint amount);
  
  /// @notice Emitted when an account first interacts with the `Market`
  event AddAccountMarket(address account);

  /// @notice Emitted when `_initLiquidityRatio` gets updated
  event SetInitLiquidityRatio(uint initLiquidityRatio);

  /// @notice Emitted when `_closeFactor` gets updated
  event SetCloseFactor(uint closeFactor);
  
  /// @notice Emitted when `_liquidationIncentive` gets updated
  event SetLiquidationIncentive(uint liquidationIncentive);
  
  function initialize(address admin_, address qontrollerAddress_) public initializer {
    // Set the admin of the contract
    _admin = admin_;
    
    _qontrollerAddress = qontrollerAddress_;
    
    // Set initial values for parameters
    _minLiquidityRatio = 1e8;
    _initLiquidityRatio = 1.1e8;
    _closeFactor = 0.5e8;
    _liquidationIncentive = 1.1e8;
  }

    /** ADMIN/RESTRICTED FUNCTIONS **/

  /// @notice Record when an account has either borrowed or lent into a
  /// `FixedRateMarket`. This is necessary because we need to iterate
  /// across all markets that an account has borrowed/lent to to calculate their
  /// `borrowValue`. Only the `FixedRateMarket` contract itself may call
  /// this function
  /// @param account User account
  function _addAccountMarket(address account) external {

    // Only enabled `FixedRateMarket` contracts can call this function
    IQontroller qontroller = IQontroller(_qontrollerAddress);
    require(qontroller.isMarketEnabled(msg.sender), "Unauthorized");
    
    // Record that account now has participated in this Market
    if(!_accountMarkets[msg.sender][account]){
      _accountMarkets[msg.sender][account] = true;
      _iterableAccountMarkets[account].push(msg.sender);
    }

    // Emit the event
    emit AddAccountMarket(account);
  }

  /// @notice Set the global initial liquidity ratio
  /// @param initLiquidityRatio_ New liquidity ratio value
  function _setInitLiquidityRatio(uint initLiquidityRatio_) external {

    // Only `admin` may call this function
    require(msg.sender == _admin, "unauthorized");

    // `_initLiquidityRatio` cannot be below `_minLiquidityRatio`
    require(
            initLiquidityRatio_ >= _minLiquidityRatio,
            "must be greater than min liquidity ratio"
            );

    // Set `_initialLiquidityRatio` to new value
    _initLiquidityRatio = initLiquidityRatio_;

    // Emit the event
    emit SetInitLiquidityRatio(_initLiquidityRatio);
  }

  function _setCloseFactor(uint closeFactor_) external {

    // Only `admin` may call this function
    require(msg.sender == _admin, "unauthorized");

    // `_closeFactor` needs to be between 0 and 1
    require(closeFactor_ <= QConst.MANTISSA_FACTORS, "must be between 0 and 1");

    // Set `_closeFactor` to new value
    _closeFactor = closeFactor_;

    // Emit the event
    emit SetCloseFactor(_closeFactor);
  }

  function _setLiquidationIncentive(uint liquidationIncentive_) external {

    // Only `admin` may call this function
    require(msg.sender == _admin, "unauthorized");

    // `liquidationIncentive` needs to be greater than or equal to 1
    require(
            liquidationIncentive_ >= QConst.MANTISSA_FACTORS,
            "must be greater than or equal to 1"
            );

    // Set `_liquidationIncentive to new value
    _liquidationIncentive = liquidationIncentive_;

    // Emit the event
    emit SetLiquidationIncentive(_liquidationIncentive);   
  }
  
    /** USER INTERFACE **/

  /// @notice Users call this to deposit collateral to fund their borrows
  /// @param tokenAddress Address of the token the collateral will be denominated in
  /// @param amount Amount to deposit (in local ccy)
  /// @return uint New collateral balance 
  function depositCollateral(address tokenAddress, uint amount) external returns(uint) {

    // Sender must give approval to QollateralManager for spend
    require(_checkApproval(tokenAddress, msg.sender, amount), "insufficient_allowance");
    
    // Sender must have enough balance for deposit
    require(_checkBalance(tokenAddress, msg.sender, amount), "insufficient balance");

    // Get the associated `Asset` to the token address
    IQontroller qontroller = IQontroller(_qontrollerAddress);
    QTypes.Asset memory asset = qontroller.assets(tokenAddress);

    // Only enabled assets are supported as collateral
    require(asset.isEnabled, "asset not supported");

    // Record that sender now has collateral deposited in this Asset
    if(!_accountAssets[tokenAddress][msg.sender]){
      _iterableAccountAssets[msg.sender].push(tokenAddress);
      _accountAssets[tokenAddress][msg.sender] = true;
    }

    // Transfer the collateral from the account to this contract as escrow
    _transferFrom(tokenAddress, msg.sender, address(this), amount);
    
    // Record the increase in collateral balance for the account
    _collateralBalances[msg.sender][tokenAddress] += amount;
    
    // Emit the event
    emit DepositCollateral(msg.sender, tokenAddress, amount);

    // Return the account's updated collateral balance for this token
    return _collateralBalances[msg.sender][tokenAddress];
  }

  /// @notice Users call this to withdraw collateral
  /// @param tokenAddress Address of the token to withdraw
  /// @param amount Amount to withdraw (in local ccy)
  /// @return uint New collateral balance 
  function withdrawCollateral(address tokenAddress, uint amount) external returns(uint) {

    // User may only withdraw up to their total local balance for any token
    amount = Math.min(amount, _collateralBalances[msg.sender][tokenAddress]);

    // Get the hypothetical liquidity ratio after withdrawal
    uint liquidityRatio_ = _getHypotheticalLiquidityRatio(
                                             msg.sender,
                                             tokenAddress,
                                             amount,
                                             address(0),
                                             0
                                             );
    
    // Amount must be positive
    require(amount > 0, "amount must be positive");
    
    // Check the liquidity ratio after withdrawal is still healthy.
    // User is only allowed to withdraw up to `_initLiquidityRatio`,
    // not `_minLiquidityRatio`, for their own protection against
    // instant liquidations.
    require(
            liquidityRatio_ >= _initLiquidityRatio,
            "withdraw amount leaves account undercollateralized"
            );

    // Record the decrease in collateral balance for the account
    _collateralBalances[msg.sender][tokenAddress] -= amount;

    // Withdraw the collateral from the protocol to the account
    _transfer(tokenAddress, msg.sender, amount);
    
    // Emit the event
    emit WithdrawCollateral(msg.sender, tokenAddress, amount);
    
    // Return the account's updated collateral balance for this token
    return _collateralBalances[msg.sender][tokenAddress];
  }
  
  /** VIEW FUNCTIONS **/
  
  /// @notice Return what the liquidity ratio for an account would be
  /// with a hypothetical collateral withdraw and/or token borrow.
  /// The liquidity ratio is calculated as:
  /// (`weightedCollateralValue` / `weightedBorrowValue`)
  /// This returns a value from 0-1, scaled by 1e8.
  /// If this value fals below 1, the account can be liquidated
  /// @param account User account
  /// @param withdrawTokenAddress Currency of hypothetical withdraw
  /// @param withdrawAmount Amount of hypothetical withdraw in local currency
  /// @param borrowMarketAddress Market of hypothetical borrow
  /// @param borrowAmount Amount of hypothetical borrow in local ccy
  /// @return uint Hypothetical liquidity ratio
  function hypotheticalLiquidityRatio(
                                      address account,
                                      address withdrawTokenAddress,
                                      uint withdrawAmount,
                                      address borrowMarketAddress,
                                      uint borrowAmount
                                      ) external view returns(uint){
    return _getHypotheticalLiquidityRatio(
                                          account,
                                          withdrawTokenAddress,
                                          withdrawAmount,
                                          borrowMarketAddress,
                                          borrowAmount
                                          );                                          
  }

  /// @notice Return the current liquidity ratio for an account.
  /// The liquidity ratio is calculated as:
  /// (`weightedCollateralValue` / `weightedBorrowValue`)
  /// This returns a value from 0-1, scaled by 1e8.
  /// If this value fals below 1, the account can be liquidated
  /// @param account User account
  /// @return uint Liquidity ratio
  function liquidityRatio(address account) external view returns(uint){
    return _getHypotheticalLiquidityRatio(account, address(0), 0, address(0), 0);
  }

  /// @notice Get the `collateralFactor` weighted value (in USD) of all the
  /// collateral deposited for an account
  /// @param account Account to query
  /// @return uint Total value of account in USD
  function virtualCollateralValue(address account) external view returns(uint){
    return _getHypotheticalCollateralValue(account, address(0), 0, true);
  }

  /// @notice Get the `collateralFactor` weighted value (in USD) for the tokens
  /// deposited for an account
  /// @param account Account to query
  /// @param tokenAddress Address of ERC20 token
  /// @return uint Value of token collateral of account in USD
  function virtualCollateralValueByToken(
                                         address account,
                                         address tokenAddress
                                         ) external view returns(uint){
    return _getHypotheticalCollateralValueByToken(account, tokenAddress, 0, true);
  }

  /// @notice Get the `marketFactor` weighted net borrows (i.e. borrows - lends)
  /// in USD summed across all `Market`s participated in by the user
  /// @param account Account to query
  /// @return uint Borrow value of account in USD
  function virtualBorrowValue(address account) external view returns(uint){
    return _getHypotheticalBorrowValue(account, address(0), 0, true);
  }

  /// @notice Get the `marketFactor` weighted net borrows (i.e. borrows - lends)
  /// in USD for a particular `Market`
  /// @param account Account to query
  /// @param marketAddress address of the `FixedRateMarket` contract
  /// @return uint Borrow value of account in USD
  function virtualBorrowValueByMarket(
                                      address account,
                                      address marketAddress
                                      ) external view returns(uint){
    return _getHypotheticalBorrowValueByMarket(account, marketAddress, 0, true);
  }
  
  /// @notice Get the unweighted value (in USD) of all the collateral deposited
  /// for an account
  /// @param account Account to query
  /// @return uint Total value of account in USD
  function realCollateralValue(address account) external view returns(uint){
    return _getHypotheticalCollateralValue(account, address(0), 0, false);
  }
  
  /// @notice Get the unweighted value (in USD) of the tokens deposited
  /// for an account
  /// @param account Account to query
  /// @param tokenAddress Address of ERC20 token
  /// @return uint Value of token collateral of account in USD
  function realCollateralValueByToken(
                                      address account,
                                      address tokenAddress
                                      ) external view returns(uint){
    return _getHypotheticalCollateralValueByToken(account, tokenAddress, 0, false);
  }
  
  /// @notice Get the unweighted current net value borrowed (i.e. borrows - lends)
  /// in USD summed across all `Market`s participated in by the user
  /// @param account Account to query
  /// @return uint Borrow value of account in USD
  function realBorrowValue(address account) external view returns(uint){
    return _getHypotheticalBorrowValue(account, address(0), 0, false);
  }

  /// @notice Get the unweighted current net value borrowed (i.e. borrows - lends)
  /// in USD for a particular `Market`
  /// @param account Account to query
  /// @param marketAddress Address of the `FixedRateMarket` contract
  /// @return uint Borrow value of account in USD
  function realBorrowValueByMarket(
                                   address account,
                                   address marketAddress
                                   ) external view returns(uint){
    return _getHypotheticalBorrowValueByMarket(account, marketAddress, 0, false);
  }

  /// @notice Get the minimum liquidity ratio. Scaled by 1e8.
  /// @return uint Minimum liquidity ratio
  function minLiquidityRatio() external view returns(uint){
    return _minLiquidityRatio;
  }

  /// @notice Get the initial liquidity ratio. Scaled by 1e8
  /// @return uint Initial liquidity ratio
  function initLiquidityRatio() external view returns(uint){
    return _initLiquidityRatio;
  }

  /// @notice Get the close factor. Scaled by 1e8
  /// @return uint Close factor
  function closeFactor() external view returns(uint){
    return _closeFactor;
  }

  /// @notice Get the liquidation incentive. Scaled by 1e8
  /// @return uint Liquidation incentive
  function liquidationIncentive() external view returns(uint){
    return _liquidationIncentive;
  }
  
  /// @notice Get the address of the `Qontroller` contract
  function qontrollerAddress() external view returns(address){
    return _qontrollerAddress;
  }
  /// @notice Use this for quick lookups of collateral balances by asset
  /// @param tokenAddress Address of ERC20 token
  /// @param account User account  
  /// @return uint Balance in local
  function collateralBalances(
                              address tokenAddress,
                              address account
                              ) external view returns(uint){
    return _collateralBalances[account][tokenAddress];
  }

  /// @notice Get iterable list of assets which an account has nonzero balance.
  /// @param account User account
  /// @return address[] Iterable list of ERC20 token addresses
  function iterableAccountAssets(address account) external view returns(address[] memory){
    return _iterableAccountAssets[account];
  }
  
  /// @notice Get iterable list of all Markets which an account has participated
  /// @param account User account
  /// @return address[] Iterable list of `FixedRateLoanMarket` contract addresses
  function iterableAccountMarkets(address account) external view returns(address[] memory){
    return _iterableAccountMarkets[account];
  }

  /// @notice Quick lookup of whether an account has nonzero balance in an asset.
  /// @param tokenAddress Address of ERC20 token
  /// @param account User account
  /// @return bool True if user has balance, false otherwise
  function accountAssets(address tokenAddress, address account) external view returns(bool){
    return _accountAssets[tokenAddress][account];
  }

  /// @notice Quick lookup of whether an account has participated in a Market
  /// @param marketAddress Address of `FixedRateLoanMarket` contract
  /// @param account User account
  /// @return bool True if participated, false otherwise
  function accountMarkets(address marketAddress, address account) external view returns(bool){
    return _accountMarkets[marketAddress][account];
  }

  /// @notice Convenience function for getting price feed from Chainlink oracle
  /// @param oracleFeed Address of the chainlink oracle feed.
  /// @return answer uint256, decimals uint8
  function priceFeed(address oracleFeed) external view returns(uint256, uint8){
    return _priceFeed(oracleFeed);
  }

  /** INTERNAL FUNCTIONS **/
  
  /// @notice Return what the liquidity ratio for an account would be
  /// with a hypothetical collateral withdraw and/or token borrow.
  /// The liquidity ratio is calculated as:
  /// (`collateralValueWeighted` / `borrowValueWeighted`)
  /// This returns a value from 0-1, scaled by 1e8.
  /// If this value fals below 1, the account can be liquidated
  /// @param account User account
  /// @param withdrawTokenAddress Currency of hypothetical withdraw
  /// @param withdrawAmount Amount of hypothetical withdraw in local currency
  /// @param borrowMarketAddress Market of hypothetical borrow
  /// @param borrowAmount Amount of hypothetical borrow in local ccy
  /// @return uint Hypothetical liquidity ratio
  function _getHypotheticalLiquidityRatio(
                                          address account,
                                          address withdrawTokenAddress,
                                          uint withdrawAmount,
                                          address borrowMarketAddress,
                                          uint borrowAmount
                                          ) internal view returns(uint){

    // The numerator is the weighted hypothetical collateral value
    uint num = _getHypotheticalCollateralValue(
                                               account,
                                               withdrawTokenAddress,
                                               withdrawAmount,
                                               true
                                               );

    // The denominator is the weighted hypothetical borrow value
    uint denom = _getHypotheticalBorrowValue(
                                             account,
                                             borrowMarketAddress,
                                             borrowAmount,
                                             true
                                             );

    if(denom == 0){
      // Need to handle division by zero if account has no borrows
      return QConst.UINT_MAX;      
    }else{
      // Return the liquidity ratio as a value from 0-1, scaled by 1e8
      return num * QConst.MANTISSA_LIQUIDITY_RATIO / denom;
    }        
  }
  
  /// @notice Return what the total collateral value for an account would be
  /// with a hypothetical withdraw, with an option for weighted or unweighted value
  /// @param account Account to query
  /// @param withdrawTokenAddress Currency of hypothetical withdraw
  /// @param withdrawAmount Amount of hypothetical withdraw in local currency
  /// @param applyCollateralFactor True to get the `collateralFactor` weighted value, false otherwise
  /// @return uint Total value of account in USD
  function _getHypotheticalCollateralValue(
                                           address account,
                                           address withdrawTokenAddress,
                                           uint withdrawAmount,
                                           bool applyCollateralFactor
                                           ) internal view returns(uint){
            
    uint totalValueUSD = 0;

    for(uint i=0; i<_iterableAccountAssets[account].length; i++){

      // Get the token address in i'th slot of `_iterableAccountAssets[account]`
      address tokenAddress = _iterableAccountAssets[account][i];

      // Check if token address matches hypothetical withdraw token
      if(tokenAddress == withdrawTokenAddress){
        // Add value to total minus the hypothetical withdraw amount
        totalValueUSD += _getHypotheticalCollateralValueByToken(
                                                                account,
                                                                tokenAddress,
                                                                withdrawAmount,
                                                                applyCollateralFactor
                                                                );
      }else{
        // Add value to total with zero hypothetical withdraw amount
        totalValueUSD += _getHypotheticalCollateralValueByToken(
                                                                account,
                                                                tokenAddress,
                                                                0,
                                                                applyCollateralFactor
                                                                );
      }
    }
    
    return totalValueUSD;
  }

  
  /// @notice Return what the collateral value by token for an account would be
  /// with a hypothetical withdraw, with an option for weighted or unweighted value
  /// @param account Account to query
  /// @param tokenAddress Address of ERC20 token
  /// @param withdrawAmount Amount of hypothetical withdraw in local currency
  /// @param applyCollateralFactor True to get the `collateralFactor` weighted value, false otherwise
  /// @return uint Total value of account in USD
  function _getHypotheticalCollateralValueByToken(
                                                  address account,
                                                  address tokenAddress,
                                                  uint withdrawAmount,
                                                  bool applyCollateralFactor
                                                  ) internal view returns(uint){

    require(
            withdrawAmount <= _collateralBalances[account][tokenAddress],
            "withdrawAmount must be less than or equal to balance"
            );
    
    // Get the `Asset` associated to this token
    IQontroller qontroller = IQontroller(_qontrollerAddress);
    QTypes.Asset memory asset = qontroller.assets(tokenAddress);

    // Value of collateral in any unsupported `Asset` is zero
    if(!asset.isEnabled){
      return 0;
    }
    
    // Get the local balance of the account for the given `tokenAddress`
    uint balanceLocal = _collateralBalances[account][tokenAddress];

    // Subtract any hypothetical withdraw amount. Guaranteed not to underflow
    balanceLocal -= withdrawAmount;
    
    // Convert the local balance to USD
    uint valueUSD = _localToUSD(tokenAddress, asset.oracleFeed, balanceLocal);
    
    if(applyCollateralFactor){
      // Apply the `collateralFactor` to get the discounted value of the asset       
      valueUSD = valueUSD * asset.collateralFactor / QConst.MANTISSA_FACTORS;
    }
    
    return valueUSD;
  }

  /// @notice Return what the total borrow value for an account would be
  /// with a hypothetical borrow, with an option for weighted or unweighted value  
  /// @param account Account to query
  /// @param borrowMarketAddress Market of hypothetical borrow
  /// @param borrowAmount Amount of hypothetical borrow in local ccy
  /// @param applyMarketFactor True to get the `marketFactor` weighted value, false otherwise
  /// @return uint Borrow value of account in USD
  function _getHypotheticalBorrowValue(
                                       address account,
                                       address borrowMarketAddress,
                                       uint borrowAmount,
                                       bool applyMarketFactor
                                       ) internal view returns(uint){
    
    uint totalValueUSD = 0;
    for(uint i=0; i<_iterableAccountMarkets[account].length; i++){
      
      // Get the market address in i'th slot of `_iterableAccountMarkets[account]`
      address marketAddress = _iterableAccountMarkets[account][i];
      
      // Check if the user is requesting to borrow more in this `Market`
      if(marketAddress == borrowMarketAddress){
        // User requesting to borrow more in this `Market`, add the amount to borrows
        totalValueUSD += _getHypotheticalBorrowValueByMarket(
                                                             account,
                                                             marketAddress,
                                                             borrowAmount,
                                                             applyMarketFactor
                                                             );
      }else{
        // User not requesting to borrow more in this `Market`, just get current value
        totalValueUSD += _getHypotheticalBorrowValueByMarket(
                                                             account,
                                                             marketAddress,
                                                             0,
                                                             applyMarketFactor
                                                             );
      }
    }
    return totalValueUSD;    
  }
  

  /// @notice Return what the borrow value by `Market` for an account would be
  /// with a hypothetical borrow, with an option for weighted or unweighted value  
  /// @param account Account to query
  /// @param marketAddress Address of `FixedRateMarket`
  /// @param borrowAmount Amount of hypothetical borrow in local ccy
  /// @param applyMarketFactor True to get the `marketFactor` weighted value, false otherwise
  /// @return uint Borrow value of account in USD
  function _getHypotheticalBorrowValueByMarket(
                                               address account,
                                               address marketAddress,
                                               uint borrowAmount,
                                               bool applyMarketFactor
                                               ) internal view returns(uint){
    
    // Instantiate interfaces
    IFixedRateMarket market = IFixedRateMarket(marketAddress);
    IQontroller qontroller = IQontroller(_qontrollerAddress);

    // Total `borrowsLocal` should be current borrow plus `borrowAmount`
    uint borrowsLocal = market.accountBorrows(account) + borrowAmount;

    // Total `lendsLocal` is just the user's balance of qTokens
    uint lendsLocal = market.balanceOf(account);
    if(lendsLocal >= borrowsLocal){
      // Default to zero if lends greater than borrows
      return 0;
    }else{
      
      // Get the net amount being borrowed in local
      // Guaranteed not to underflow from the above check
      uint borrowValueLocal = borrowsLocal - lendsLocal;     

      // Convert from local value to value in USD
      address tokenAddress = market.tokenAddress();
      QTypes.Asset memory asset = qontroller.assets(tokenAddress);
      address oracleFeed = asset.oracleFeed;
      uint borrowValueUSD = _localToUSD(tokenAddress, oracleFeed, borrowValueLocal);

      if(applyMarketFactor){
        // Apply the `marketFactor` to get the risk premium value of the borrow
        borrowValueUSD = borrowValueUSD * QConst.MANTISSA_FACTORS / asset.marketFactor;
      }
      
      return borrowValueUSD;
    }
  }
        
  /// @notice Converts any local value into its value in USD using oracle feed price
  /// @param tokenAddress Address of the ERC20 token
  /// @param oracleFeed Address of the chainlink oracle feed
  /// @param valueLocal Amount denominated in terms of the ERC20 token
  /// @return uint Amount in USD
  function _localToUSD(
                       address tokenAddress,
                       address oracleFeed,
                       uint valueLocal
                       ) internal view returns(uint){
    
    IERC20Metadata token = IERC20Metadata(tokenAddress);
    
    (uint exchRate, uint8 exchDecimals) = _priceFeed(oracleFeed);
    
    // Initialize all the necessary mantissas first
    uint exchRateMantissa = 10 ** exchDecimals;
    uint tokenMantissa = 10 ** token.decimals();
    
    // Convert `valueLocal` to USD
    uint valueUSD = valueLocal * exchRate * QConst.MANTISSA_STABLECOIN;
    
    // Divide by mantissas last for maximum precision
    valueUSD = valueUSD / tokenMantissa / exchRateMantissa;
    
    return valueUSD;
  }

  /// @notice Converts any value in USD into its value in local using oracle feed price
  /// @param tokenAddress Address of the ERC20 token
  /// @param oracleFeed Address of the chainlink oracle feed
  /// @param valueUSD Amount in USD
  /// @return uint Amount denominated in terms of the ERC20 token
  function _USDToLocal(
                       address tokenAddress,
                       address oracleFeed,
                       uint valueUSD
                       ) internal view returns(uint){

    IERC20Metadata token = IERC20Metadata(tokenAddress);

    (uint exchRate, uint8 exchDecimals) = _priceFeed(oracleFeed);

    // Initialize all the necessary mantissas first
    uint exchRateMantissa = 10 ** exchDecimals;
    uint tokenMantissa = 10 ** token.decimals();

    // Multiply by mantissas first for maximum precision
    uint valueLocal = valueUSD * tokenMantissa * exchRateMantissa;

    // Convert `valueUSD` to local
    valueLocal = valueLocal / exchRate / QConst.MANTISSA_STABLECOIN;

    return valueLocal;    
  }
  
  /// @notice Convenience function for getting price feed from Chainlink oracle
  /// @param oracleFeed Address of the chainlink oracle feed
  /// @return answer uint256, decimals uint8
  function _priceFeed(address oracleFeed) internal view returns(uint256, uint8){
    IAggregatorV3 aggregator = IAggregatorV3(oracleFeed);
    (, int256 answer,,,) =  aggregator.latestRoundData();
    uint8 decimals = aggregator.decimals();
    return (uint(answer), decimals);
  }

  /// @notice Handles the transfer function for a token.
  /// @param tokenAddress Address of the token to transfer
  /// @param to Address of the receiver
  /// @param amount Amount of tokens to transfer
  function _transfer(
                     address tokenAddress,
                     address to,
                     uint amount
                     ) internal {
    IERC20 token = IERC20(tokenAddress);
    token.safeTransfer(to, amount);
  }
  
  /// @notice Handles the transferFrom function for a token.
  /// @param tokenAddress Address of the token to transfer
  /// @param from Address of the sender
  /// @param to Adress of the receiver
  /// @param amount Amount of tokens to transfer
  function _transferFrom(
                        address tokenAddress,
                        address from,
                        address to,
                        uint amount
                        ) internal {
    require(_checkApproval(tokenAddress, from, amount), "insufficient allowance");
    require(_checkBalance(tokenAddress, from, amount), "insufficient balance");
    IERC20 token = IERC20(tokenAddress);
    token.safeTransferFrom(from, to, amount);
  }

  /// @notice Verify if the user has enough token balance
  /// @param tokenAddress Address of the ERC20 token
  /// @param userAddress Address of the account to check
  /// @param amount Balance must be greater than or equal to this amount
  /// @return bool true if sufficient balance otherwise false
  function _checkBalance(
                         address tokenAddress,
                         address userAddress,
                         uint256 amount
                         ) internal view returns(bool){
    if(IERC20(tokenAddress).balanceOf(userAddress) >= amount) {
      return true;
    }
    return false;
  }

  /// @notice Verify if the user has approved the smart contract for spend
  /// @param tokenAddress Address of the ERC20 token
  /// @param userAddress Address of the account to check
  /// @param amount Allowance  must be greater than or equal to this amount
  /// @return bool true if sufficient allowance otherwise false
  function _checkApproval(
                          address tokenAddress,
                          address userAddress,
                          uint256 amount
                          ) internal view returns(bool) {
    if(IERC20(tokenAddress).allowance(userAddress, address(this)) > amount){
      return true;
    }
    return false;
  }

  
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IAggregatorV3 {
    /**
     * Returns the decimals to offset on the getLatestPrice call
     */
    function decimals() external view returns (uint8);

    /**
     * Returns the description of the underlying price feed aggregator
     */
    function description() external view returns (string memory);

    /**
     * Returns the version number representing the type of aggregator the proxy points to
     */
    function version() external view returns (uint256);

    /**
     * Returns price data about a specific round
     */
    function getRoundData(uint80 _roundId) external view returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

    /**
     * Returns price data from the latest round
     */
    function latestRoundData() external view returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./IERC20.sol";
import "./IERC20Metadata.sol";

interface IFixedRateMarket is IERC20, IERC20Metadata {

  /** VIEW FUNCTIONS **/

  /// @notice Get the address of the `QollateralManager`
  /// @return address
  function qollateralManagerAddress() external view returns(address);

  /// @notice Get the address of the ERC20 token which the loan will be denominated
  /// @return address
  function tokenAddress() external view returns(address);

  /// @notice Get the UNIX timestamp (in seconds) when the market matures
  /// @return uint
  function maturity() external view returns(uint);
  
  /// @notice True if a nonce for a Quote is voided, false otherwise.
  /// Used for checking if a Quote is a duplicated.
  /// @param account Account to query
  /// @param nonce Nonce to query
  /// @return bool True if used, false otherwise
  function isNonceVoid(address account, uint nonce) external view returns(bool);

  /// @notice Get the total balance of borrows by user
  /// @param account Account to query
  /// @return uint Borrows
  function accountBorrows(address account) external view returns(uint);

  /// @notice Get the current total partial fill for a Quote
  /// @param signature Quote signature to query
  /// @return uint Partial fill
  function quoteFill(bytes memory signature) external view returns(uint);
  
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IQollateralManager {

  /** USER INTERFACE **/
  
  /// @notice Users call this to deposit collateral to fund their borrows
  /// @param tokenAddress Address of the token the collateral will be denominated in
  /// @param amount Amount to deposit (in local ccy)
  /// @return uint New collateral balance 
  function depositCollateral(address tokenAddress, uint amount) external returns(uint);

  /// @notice Users call this to withdraw collateral
  /// @param tokenAddress Address of the token to withdraw
  /// @param amount Amount to withdraw (in local ccy)
  /// @return uint New collateral balance 
  function withdrawCollateral(address tokenAddress, uint amount) external returns(uint);
  
  /** VIEW FUNCTIONS **/
  
  /// @notice Return what the liquidity ratio for an account would be
  /// with a hypothetical collateral withdraw and/or token borrow.
  /// The liquidity ratio is calculated as:
  /// (`weightedCollateralValue` / `weightedBorrowValue`)
  /// This returns a value from 0-1, scaled by 1e8.
  /// If this value fals below 1, the account can be liquidated
  /// @param account User account
  /// @param withdrawTokenAddress Currency of hypothetical withdraw
  /// @param withdrawAmount Amount of hypothetical withdraw in local currency
  /// @param borrowMarketAddress Market of hypothetical borrow
  /// @param borrowAmount Amount of hypothetical borrow in local ccy
  /// @return uint Hypothetical liquidity ratio
  function hypotheticalLiquidityRatio(
                                      address account,
                                      address withdrawTokenAddress,
                                      uint withdrawAmount,
                                      address borrowMarketAddress,
                                      uint borrowAmount
                                      ) external view returns(uint);

  /// @notice Return the current liquidity ratio for an account.
  /// The liquidity ratio is calculated as:
  /// (`virtualCollateralValue` / `virtualBorrowValue`)
  /// This returns a value from 0-1, scaled by 1e8.
  /// If this value fals below 1, the account can be liquidated
  /// @param account User account
  /// @return uint Liquidity ratio
  function liquidityRatio(address account) external view returns(uint);
  
  /// @notice Get the `collateralFactor` weighted value (in USD) of all the
  /// collateral deposited for an account
  /// @param account Account to query
  /// @return uint Total value of account in USD
  function virtualCollateralValue(address account) external view returns(uint);

  /// @notice Get the `collateralFactor` weighted value (in USD) for the tokens
  /// deposited for an account
  /// @param account Account to query
  /// @param tokenAddress Address of ERC20 token
  /// @return uint Value of token collateral of account in USD
  function virtualCollateralValueByToken(
                                         address account,
                                         address tokenAddress
                                         ) external view returns(uint);
  
  /// @notice Get the `marketFactor` weighted net borrows (i.e. borrows - lends)
  /// in USD summed across all `Market`s participated in by the user
  /// @param account Account to query
  /// @return uint Borrow value of account in USD
  function virtualBorrowValue(address account) external view returns(uint);

  /// @notice Get the `marketFactor` weighted net borrows (i.e. borrows - lends)
  /// in USD for a particular `Market`
  /// @param account Account to query
  /// @param marketAddress address of the `FixedRateMarket` contract
  /// @return uint Borrow value of account in USD
  function virtualBorrowValueByMarket(
                                      address account,
                                      address marketAddress
                                      ) external view returns(uint);
  
  /// @notice Get the unweighted value (in USD) of all the collateral deposited
  /// for an account
  /// @param account Account to query
  /// @return uint Total value of account in USD
  function realCollateralValue(address account) external view returns(uint);

  /// @notice Get the unweighted value (in USD) of the tokens deposited
  /// for an account
  /// @param account Account to query
  /// @param tokenAddress Address of ERC20 token
  /// @return uint Value of token collateral of account in USD
  function realCollateralValueByToken(
                                      address account,
                                      address tokenAddress
                                      ) external view returns(uint);
  
  /// @notice Get the unweighted current net value borrowed (i.e. borrows - lends)
  /// in USD summed across all `Market`s participated in by the user
  /// @param account Account to query
  /// @return uint Borrow value of account in USD
  function realBorrowValue(address account) external view returns(uint);

  /// @notice Get the unweighted current net value borrowed (i.e. borrows - lends)
  /// in USD for a particular `Market`
  /// @param account Account to query
  /// @param marketAddress Address of the `FixedRateMarket` contract
  /// @return uint Borrow value of account in USD
  function realBorrowValueByMarket(
                                   address account,
                                   address marketAddress
                                   ) external view returns(uint);

  /// @notice Get the minimum liquidity ratio
  /// @return uint Minimum liquidity ratio
  function minLiquidityRatio() external view returns(uint);

  /// @notice Get the initial liquidity ratio
  /// @return uint initial liquidity ratio
  function initLiquidityRatio() external view returns(uint);

  /// @notice Get the close factor. Scaled by 1e8
  /// @return uint Close factor
  function closeFactor() external view returns(uint);

  /// @notice Get the liquidation incentive. Scaled by 1e8
  /// @return uint Liquidation incentive
  function liquidationIncentive() external view returns(uint);
  
  /// @notice Get the address of the `Qontroller` contract
  function qontrollerAddress() external view returns(address);

  /// @notice Use this for quick lookups of collateral balances by asset
  /// @param tokenAddress Address of ERC20 token
  /// @param account User account  
  /// @return uint Balance in local
  function collateralBalances(
                              address tokenAddress,
                              address account
                              ) external view returns(uint); 

  /// @notice Get iterable list of assets which an account has nonzero balance.
  /// @param account User account
  /// @return address[] Iterable list of ERC20 token addresses
  function iterableAccountAssets(address account) external view returns(address[] memory);
  
  /// @notice Get iterable list of all Markets which an account has participated
  /// @param account User account
  /// @return address[] Iterable list of `FixedRateLoanMarket` contract addresses
  function iterableAccountMarkets(address account) external view returns(address[] memory);

  /// @notice Quick lookup of whether an account has nonzero balance in an asset.
  /// @param tokenAddress Address of ERC20 token
  /// @param account User account
  /// @return bool True if user has balance, false otherwise
  function accountAssets(address tokenAddress, address account) external view returns(bool);

  /// @notice Quick lookup of whether an account has participated in a Market
  /// @param marketAddress Address of `FixedRateLoanMarket` contract
  /// @param account User account
  /// @return bool True if participated, false otherwise
  function accountMarkets(address marketAddress, address account) external view returns(bool);

  /// @notice Convenience function for getting price feed from Chainlink oracle
  /// @param oracleFeed Address of the chainlink oracle feed.
  /// @return answer uint256, decimals uint8
  function priceFeed(address oracleFeed) external view returns(uint256, uint8);
  
  /** ADMIN FUNCTIONS **/

  /// @notice Record when an account has either borrowed or lent into a
  /// `FixedRateMarket`. This is necessary because we need to iterate
  /// across all markets that an account has borrowed/lent to to calculate their
  /// `borrowValue`. Only the `FixedRateMarket` contract itself may call
  /// this function
  /// @param account User account
  function _addAccountMarket(address account) external;
  
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "../libraries/QTypes.sol";

interface IQontroller {

  /// @notice Get the address of the `QollateralManager` contract
  function qollateralManagerAddress() external view returns(address);
  
  /// @notice Gets the `Asset` mapped to the address of a ERC20 token
  /// @param tokenAddress Address of ERC20 token
  /// @return QTypes.Asset Associated `Asset`
  function assets(address tokenAddress) external view returns(QTypes.Asset memory);

  /// @notice Gets the address of the `FixedRateMarket` contract
  /// @param tokenAddress Address of ERC20 token
  /// @param maturity UNIX timestamp of the maturity date
  /// @return address Address of `FixedRateMarket` contract
  function fixedRateMarkets(
                            address tokenAddress,
                            uint maturity
                            ) external view returns(address);

  /// @notice Check whether an address is a valid FixedRateMarket address.
  /// Can be used for checks for inter-contract admin/restricted function call.
  /// @param fixedRateMarketAddress Address of `FixedRateMarket` contract
  /// @return bool True if valid false otherwise
  function isMarketEnabled(address fixedRateMarketAddress) external view returns(bool);
  
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Address.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !Address.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

library QConst {

  /// @notice 2**256 - 1
  uint internal constant UINT_MAX = type(uint).max;
  
  /// @notice Generic mantissa corresponding to ETH decimals
  uint internal constant MANTISSA_DEFAULT = 1e18;

  /// @notice Mantissa for stablecoins
  uint internal constant MANTISSA_STABLECOIN = 1e6;

  /// @notice Mantissa for liquidity ratio
  uint internal constant MANTISSA_LIQUIDITY_RATIO = 1e8;
  
  /// @notice `assetFactor` and `marketFactor` have up to 8 decimal places precision
  uint internal constant MANTISSA_FACTORS = 1e8;

  /// @notice `APR` has 4 decimal place precision
  uint internal constant MANTISSA_APR = 1e4;
  
  /// @notice `collateralFactor` cannot be above 1.0
  uint internal constant MAX_COLLATERAL_FACTOR = 1e8;

  /// @notice `marketFactor` cannot be above 1.0
  uint internal constant MAX_MARKET_FACTOR = 1e8;

  /// @notice Seconds per 365-day year (60 * 60 * 24 * 365)
  uint internal constant YEAR = 31563000;
  
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

library QTypes {

  /// @notice Contains all the details of an Asset. Assets  must be defined
  /// before they can be used as collateral.
  /// @member isEnabled True if a asset is defined, false otherwise
  /// @member oracleFeed Address of the corresponding chainlink oracle feed
  /// @member collateralFactor 0.0 to 1.0 (scaled to 1e8) for discounting risky assets
  /// @member marketFactor 0.0 1.0 for premium on risky borrows
  /// @member maturities Iterable storage for all enabled maturities
  struct Asset {
    bool isEnabled;
    address oracleFeed;
    uint collateralFactor;
    uint marketFactor;
    uint[] maturities;
  }

  /// @notice Contains all the fields of a FixedRateLoan agreement
  /// @member startTime Starting timestamp  when the loan is instantiated
  /// @member maturity Ending timestamp when the loan terminates
  /// @member principal Size of the loan
  /// @member principalPlusInterest Final amount that must be paid by borrower
  /// @member amountRepaid Current total amount repaid so far by borrower
  /// @member lender Account of the lender
  /// @member borrower Account of the borrower
  struct FixedRateLoan {
    uint startTime;
    uint maturity;
    uint principal;
    uint principalPlusInterest;
    uint amountRepaid;
    address lender;
    address borrower;
  }

  /// @notice Contains all the fields of a published Quote
  /// @param marketAddress Address of `FixedRateLoanMarket` contract
  /// @param quoter Account of the Quoter
  /// @param quoteType 0 for PV+APR, 1 for FV+APR
  /// @param side 0 if Quoter is borrowing, 1 if Quoter is lending
  /// @param quoteExpiryTime Timestamp after which the quote is no longer valid
  /// @param APR In decimal form scaled by 1e4 (ex. 10.52% = 1052)
  /// @param cashflow Can be PV or FV depending on `quoteType`
  /// @param nonce For uniqueness of signature
  /// @param signature Signed hash of the Quote message
  struct Quote {
    address marketAddress;
    address quoter;
    uint8 quoteType;
    uint8 side;
    uint64 quoteExpiryTime; //if 0, then quote never expires
    uint64 APR;
    uint cashflow;
    uint nonce;
    bytes signature;
  }
  
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IERC20.sol";
import "./Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./interfaces/IQontroller.sol";
import "./interfaces/IFixedRateMarket.sol";
import "./libraries/Initializable.sol";
import "./libraries/QConst.sol";

contract Qontroller is Initializable, IQontroller {

  /// @notice Only admin may perform admin functions
  address private _admin;
  
  /// @notice The single instance of `QollateralManager` will be instantiated
  /// by `Qontroller`'s constructor. Store its address here.
  address private _qollateralManagerAddress;

  /// @notice All enabled Assets
  /// tokenAddress => Asset
  mapping(address => QTypes.Asset) private _assets;

  /// @notice Get the `FixedRateMarket` contract address for any given
  /// token and maturity time
  /// tokenAddress => maturity => fixedRateMarket
  mapping(address => mapping(uint => address)) private _fixedRateMarkets;

  /// @notice Mapping to determine whether a `fixedRateMarket` address
  /// is enabled or not
  /// fixedRateMarket => bool
  mapping(address => bool) private _enabledMarkets;

  /// @notice Emitted when a new FixedRateMarket is deployed
  event CreateFixedRateMarket(address marketAddress, address tokenAddress, uint maturity);

  /// @notice Emitted when a new Asset is added
  event AddAsset(address tokenAddress, address oracleFeed, uint collateralFactor, uint marketFactor);

  /// @notice Emitted when setting `collateralFactor`
  event SetCollateralFactor(address tokenAddress, uint collateralFactor);

  /// @notice Emitted when setting `marketFactor`
  event SetMarketFactor(address tokenAddress, uint marketFactor);

  function initialize(address admin_) public initializer {
    // Set the admin of the contract
    _admin = admin_;
  }

    /** ADMIN/RESTRICTED FUNCTIONS **/

  function _initializeQollateralManager(address qollateralManagerAddress_) public {

    // Only `admin` may call this function
    require(msg.sender == _admin, "unauthorized");

    // Initialize the value
    _qollateralManagerAddress = qollateralManagerAddress_;
  }

  /// @notice Admin function for adding new Assets. An Asset must be added before it
  /// can be used as collateral or borrowed. Note: We can create functionality for
  /// allowing borrows of a token but not using it as collateral by setting
  /// `collateralFactor` to zero.
  /// @param tokenAddress Address of the token corresponding to the Asset
  /// @param oracleFeed Chainlink price feed address
  /// @param collateralFactor 0.0 to 1.0 (scaled to 1e8) for discounting risky assets
  /// @param marketFactor 0.0 to 1.0 (scaled to 1e8) for premium on risky borrows
  function _addAsset(
                      address tokenAddress,
                      address oracleFeed,
                      uint collateralFactor,
                      uint marketFactor
                      ) external {

    // Only `admin` may call this function
    require(msg.sender == _admin, "unauthorized");

    // Cannot add the same asset twice
    require(!_assets[tokenAddress].isEnabled, "asset already exists");

    // `collateralFactor` must be between 0 and 1 (scaled to 1e8)
    require(collateralFactor <= QConst.MAX_COLLATERAL_FACTOR, "invalid collateral factor");

    // `marketFactor` must be between 0 and  1 (scaled to 1e8)
    require(marketFactor <= QConst.MAX_MARKET_FACTOR, "invalid market factor");
    
    // Initialize the Asset with the given parameters, and no enabled maturities
    // to begin with
    uint[] memory maturities;
    QTypes.Asset memory asset = QTypes.Asset(
                                             true,
                                             oracleFeed,
                                             collateralFactor,
                                             marketFactor,
                                             maturities
                                             );
    _assets[tokenAddress] = asset;

    // Emit the event
    emit AddAsset(tokenAddress, oracleFeed, collateralFactor, marketFactor);
  }

  /// @notice Update the `collateralFactor` for a given `Asset`
  /// @param tokenAddress Address of the token corresponding to the Asset
  /// @param collateralFactor 0.0 to 1.0 (scaled to 1e8) for discounting risky assets
  function _setCollateralFactor(address tokenAddress, uint collateralFactor) external {

    // Only `admin` may call this function
    require(msg.sender == _admin, "unauthorized");

    // Asset must already be enabled
    require(_assets[tokenAddress].isEnabled, "asset not enabled");

    // `collateralFactor` must be between 0 and 1 (scaled to 1e8)
    require(collateralFactor <= QConst.MAX_COLLATERAL_FACTOR, "invalid collateral factor");

    // Look up the corresponding asset
    QTypes.Asset storage asset = _assets[tokenAddress];

    // Set `collateralFactor`
    asset.collateralFactor = collateralFactor;

    // Emit the event
    emit SetCollateralFactor(tokenAddress, collateralFactor);
  }

  /// @notice Update the `marketFactor` for a given `Asset`
  /// @param tokenAddress Address of the token corresponding to the Asset
  /// @param marketFactor 0.0 to 1.0 (scaled to 1e8) for discounting risky assets
  function _setMarketFactor(address tokenAddress, uint marketFactor) external {

    // Only `admin` may call this function
    require(msg.sender == _admin, "unauthorized");

    // Asset must already be enabled
    require(_assets[tokenAddress].isEnabled, "asset not enabled");

    // `marketFactor` must be between 0 and 1 (scaled to 1e8)
    require(marketFactor <= QConst.MAX_MARKET_FACTOR, "invalid asset factor");

    // Look up the corresponding asset
    QTypes.Asset storage asset = _assets[tokenAddress];

    // Set `marketFactor`
    asset.marketFactor = marketFactor;

    // Emit the event
    emit SetMarketFactor(tokenAddress, marketFactor);
  }

  function _addFixedRateMarket(address fixedRateMarketAddress) external {

    // Only `admin` may call this function
    require(msg.sender == _admin, "unauthorized");

    // Get the values from the corresponding `FixedRateMarket` contract
    IFixedRateMarket market = IFixedRateMarket(fixedRateMarketAddress);
    uint maturity = market.maturity();
    address tokenAddress = market.tokenAddress();

    // Don't allow zero address
    require(tokenAddress != address(0), "invalid token address");

    // Only allow `Markets` where the corresponding `Asset` is enabled
    require(_assets[tokenAddress].isEnabled, "unsupported asset");

    // Check that this market hasn't already been instantiated before
    require(
            _fixedRateMarkets[tokenAddress][maturity] == address(0),
            "market already exists"
            );

    // Add the maturity as enabled to the corresponding Asset
    QTypes.Asset storage asset = _assets[tokenAddress];
    asset.maturities.push(maturity);
    
    // Add newly-created `FixedRateMarket` to the lookup list
    _fixedRateMarkets[tokenAddress][maturity] = fixedRateMarketAddress;

    // Enable newly-created `FixedRateMarket`
    _enabledMarkets[fixedRateMarketAddress] = true;

    // Emit the event
    emit CreateFixedRateMarket(
                               fixedRateMarketAddress,
                               tokenAddress,
                               maturity
                               );    
  }

  /** PUBLIC INTERFACE **/

  /// @notice Get the address of the `QollateralManager` contract
  function qollateralManagerAddress() external view returns(address) {
    return _qollateralManagerAddress;
  }
  
  /// @notice Gets the `Asset` mapped to the address of a ERC20 token
  /// @param tokenAddress Address of ERC20 token
  /// @return QTypes.Asset Associated `Asset`
  function assets(address tokenAddress) external view returns(QTypes.Asset memory) {
    return _assets[tokenAddress];
  }

  /// @notice Gets the address of the `FixedRateMarket` contract
  /// @param tokenAddress Address of ERC20 token
  /// @param maturity UNIX timestamp of the maturity date
  /// @return address Address of `FixedRateMarket` contract
  function fixedRateMarkets(
                            address tokenAddress,
                            uint maturity
                            ) external view returns(address){
    return _fixedRateMarkets[tokenAddress][maturity];
  }

  /// @notice Check whether an address is a valid FixedRateMarket address.
  /// Can be used for checks for inter-contract admin/restricted function call.
  /// @param fixedRateMarketAddress Address of `FixedRateMarket` contract
  /// @return bool True if valid false otherwise
  function isMarketEnabled(address fixedRateMarketAddress) external view returns(bool){
    return _enabledMarkets[fixedRateMarketAddress];
  }  
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}