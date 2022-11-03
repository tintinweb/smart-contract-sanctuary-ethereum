/**
 *Submitted for verification at Etherscan.io on 2022-11-03
*/

// Sources flattened with hardhat v2.9.9 https://hardhat.org

// File src/interfaces/external/aave/IRewardsController.sol

pragma solidity >=0.8.10;

/**
 * @title IRewardsController
 * @author Aave
 * @notice Defines the basic interface for a Rewards Controller.
 */
interface IRewardsController {

  /**
   * @dev Whitelists an address to claim the rewards on behalf of another address
   * @param user The address of the user
   * @param claimer The address of the claimer
   */
  function setClaimer(address user, address claimer) external;

  /**
   * @dev Get the price aggregator oracle address
   * @param reward The address of the reward
   * @return The price oracle of the reward
   */
  function getRewardOracle(address reward) external view returns (address);

  /**
   * @dev Returns the whitelisted claimer for a certain address (0x0 if not set)
   * @param user The address of the user
   * @return The claimer address
   */
  function getClaimer(address user) external view returns (address);

  /**
   * @dev Returns the Transfer Strategy implementation contract address being used for a reward address
   * @param reward The address of the reward
   * @return The address of the TransferStrategy contract
   */
  function getTransferStrategy(address reward) external view returns (address);

  /**
   * @dev Called by the corresponding asset on any update that affects the rewards distribution
   * @param user The address of the user
   * @param userBalance The user balance of the asset
   * @param totalSupply The total supply of the asset
   **/
  function handleAction(
    address user,
    uint256 userBalance,
    uint256 totalSupply
  ) external;

  /**
   * @dev Claims reward for a user to the desired address, on all the assets of the pool, accumulating the pending rewards
   * @param assets List of assets to check eligible distributions before claiming rewards
   * @param amount The amount of rewards to claim
   * @param to The address that will be receiving the rewards
   * @param reward The address of the reward token
   * @return The amount of rewards claimed
   **/
  function claimRewards(
    address[] calldata assets,
    uint256 amount,
    address to,
    address reward
  ) external returns (uint256);

  /**
   * @dev Returns a single rewards balance of a user, including virtually accrued and unrealized claimable rewards.
   * @param assets List of incentivized assets to check eligible distributions
   * @param user The address of the user
   * @param reward The address of the reward token
   * @return The rewards amount
   **/
  function getUserRewards(
    address[] calldata assets,
    address user,
    address reward
  ) external view returns (uint256);

  /**
   * @dev Claims reward for a user on behalf, on all the assets of the pool, accumulating the pending rewards. The
   * caller must be whitelisted via "allowClaimOnBehalf" function by the RewardsAdmin role manager
   * @param assets The list of assets to check eligible distributions before claiming rewards
   * @param amount The amount of rewards to claim
   * @param user The address to check and claim rewards
   * @param to The address that will be receiving the rewards
   * @param reward The address of the reward token
   * @return The amount of rewards claimed
   **/
  function claimRewardsOnBehalf(
    address[] calldata assets,
    uint256 amount,
    address user,
    address to,
    address reward
  ) external returns (uint256);

  /**
   * @dev Claims reward for msg.sender, on all the assets of the pool, accumulating the pending rewards
   * @param assets The list of assets to check eligible distributions before claiming rewards
   * @param amount The amount of rewards to claim
   * @param reward The address of the reward token
   * @return The amount of rewards claimed
   **/
  function claimRewardsToSelf(
    address[] calldata assets,
    uint256 amount,
    address reward
  ) external returns (uint256);

  /**
   * @dev Claims all rewards for a user to the desired address, on all the assets of the pool, accumulating the pending rewards
   * @param assets The list of assets to check eligible distributions before claiming rewards
   * @param to The address that will be receiving the rewards
   * @return rewardsList List of addresses of the reward tokens
   * @return claimedAmounts List that contains the claimed amount per reward, following same order as "rewardList"
   **/
  function claimAllRewards(address[] calldata assets, address to)
    external
    returns (address[] memory rewardsList, uint256[] memory claimedAmounts);

  /**
   * @dev Claims all rewards for a user on behalf, on all the assets of the pool, accumulating the pending rewards. The caller must
   * be whitelisted via "allowClaimOnBehalf" function by the RewardsAdmin role manager
   * @param assets The list of assets to check eligible distributions before claiming rewards
   * @param user The address to check and claim rewards
   * @param to The address that will be receiving the rewards
   * @return rewardsList List of addresses of the reward tokens
   * @return claimedAmounts List that contains the claimed amount per reward, following same order as "rewardsList"
   **/
  function claimAllRewardsOnBehalf(
    address[] calldata assets,
    address user,
    address to
  ) external returns (address[] memory rewardsList, uint256[] memory claimedAmounts);

  /**
   * @dev Claims all reward for msg.sender, on all the assets of the pool, accumulating the pending rewards
   * @param assets The list of assets to check eligible distributions before claiming rewards
   * @return rewardsList List of addresses of the reward tokens
   * @return claimedAmounts List that contains the claimed amount per reward, following same order as "rewardsList"
   **/
  function claimAllRewardsToSelf(address[] calldata assets)
    external
    returns (address[] memory rewardsList, uint256[] memory claimedAmounts);


  /**
   * @dev Returns the accrued rewards balance of a user, not including virtually accrued rewards since last distribution.
   * @param user The address of the user
   * @param reward The address of the reward token
   * @return Unclaimed rewards, not including new distributions
   **/
  function getUserAccruedRewards(address user, address reward) external view returns (uint256);
}


// File src/interfaces/IRewardCollector.sol

pragma solidity ^0.8.13;

interface IRewardCollector {
    /// @notice Gets the current version.
    ///
    /// @return The version.
    function version() external view returns (string memory);

    /// @notice Gets the current reward token.
    ///
    /// @return The reward token.
    function rewardToken() external view returns (address);

    /// @notice Gets the current swap router.
    ///
    /// @return The swap router address.
    function swapRouter() external view returns (address);

    /// @notice Gets the current debt token.
    ///
    /// @return The debt token
    function debtToken() external view returns (address);

    /// @notice Claims rewards tokens, swaps for alUSD.
    ///
    /// @param  token                The yield token to claim rewards for.
    /// @param  minimumAmountOut     The minimum returns to accept.
    ///
    /// @return claimed              The amount of reward tokens claimed.
    function claimAndDistributeRewards(address token, uint256 minimumAmountOut) external returns (uint256 claimed);
}


// File src/interfaces/external/velodrome/IVelodromeSwapRouter.sol

pragma solidity >=0.5.0;


interface IVelodromeSwapRouter {
    struct route {
        address from;
        address to;
        bool stable;
    }
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        route[] calldata routes,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function getAmountsOut(
        uint amountIn,
        route[] memory routes
    ) external view returns (uint[] memory amounts);
}


// File lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}


// File src/interfaces/external/aave/IScaledBalanceToken.sol

pragma solidity >=0.5.0;

interface IScaledBalanceToken {
  /// @dev Returns the scaled balance of the user. The scaled balance is the sum of all the updated stored balance
  ///      divided by the reserve's liquidity index at the moment of the update.
  ///
  /// @param user The user whose balance is calculated.
  ///
  /// @return The scaled balance of the user.
  function scaledBalanceOf(address user) external view returns (uint256);

  /// @dev Returns the scaled balance of the user and the scaled total supply.
  ///
  /// @param user The address of the user.
  ///
  /// @return scaledBalance     The scaled balance of the user.
  /// @return scaledTotalSupply The scaled balance and the scaled total supply.
  function getScaledUserBalanceAndSupply(address user)
    external view
    returns (
      uint256 scaledBalance,
      uint256 scaledTotalSupply
    );

  /// @dev Returns the scaled total supply of the variable debt token. Represents sum(debt/index).
  ///
  /// @return The scaled total supply.
  function scaledTotalSupply() external view returns (uint256);
}


// File src/interfaces/external/aave/DataTypes.sol

pragma solidity >=0.5.0;

// @dev Refer to the whitepaper, section 1.1 basic concepts for a formal description of these properties.
struct ReserveData {
  // Stores the reserve configuration.
  ReserveConfigurationMap configuration;
  // The liquidity index. Expressed in ray.
  uint128 liquidityIndex;
  // Variable borrow index. Expressed in ray.
  uint128 variableBorrowIndex;
  // The current supply rate. Expressed in ray.
  uint128 currentLiquidityRate;
  // The current variable borrow rate. Expressed in ray.
  uint128 currentVariableBorrowRate;
  // The current stable borrow rate. Expressed in ray.
  uint128 currentStableBorrowRate;
  uint40 lastUpdateTimestamp;
  // Tokens addresses.
  address aTokenAddress;
  address stableDebtTokenAddress;
  address variableDebtTokenAddress;
  // Address of the interest rate strategy.
  address interestRateStrategyAddress;
  // The id of the reserve. Represents the position in the list of the active reserves.
  uint8 id;
}

struct ReserveConfigurationMap {
  //bit 0-15: LTV
  //bit 16-31: Liq. threshold
  //bit 32-47: Liq. bonus
  //bit 48-55: Decimals
  //bit 56: Reserve is active
  //bit 57: reserve is frozen
  //bit 58: borrowing is enabled
  //bit 59: stable rate borrowing enabled
  //bit 60-63: reserved
  //bit 64-79: reserve factor
  uint256 data;
}

struct UserConfigurationMap {
  uint256 data;
}

enum InterestRateMode {
  NONE,
  STABLE,
  VARIABLE
}


// File src/interfaces/external/aave/ILendingPoolAddressesProvider.sol

pragma solidity >=0.5.0;

/// @title  ILendingPoolAddressesProvider
/// @author Aave
///
/// @dev Main registry of addresses part of or connected to the protocol, including permissioned roles.
///
/// - Acting also as factory of proxies and admin of those, so with right to change its implementations.
/// - Owned by the Aave Governance.
interface ILendingPoolAddressesProvider {
  event MarketIdSet(string newMarketId);
  event LendingPoolUpdated(address indexed newAddress);
  event ConfigurationAdminUpdated(address indexed newAddress);
  event EmergencyAdminUpdated(address indexed newAddress);
  event LendingPoolConfiguratorUpdated(address indexed newAddress);
  event LendingPoolCollateralManagerUpdated(address indexed newAddress);
  event PriceOracleUpdated(address indexed newAddress);
  event LendingRateOracleUpdated(address indexed newAddress);
  event ProxyCreated(bytes32 id, address indexed newAddress);
  event AddressSet(bytes32 id, address indexed newAddress, bool hasProxy);

  function getMarketId() external view returns (string memory);

  function setMarketId(string calldata marketId) external;

  function setAddress(bytes32 id, address newAddress) external;

  function setAddressAsProxy(bytes32 id, address impl) external;

  function getAddress(bytes32 id) external view returns (address);

  function getLendingPool() external view returns (address);

  function setLendingPoolImpl(address pool) external;

  function getLendingPoolConfigurator() external view returns (address);

  function setLendingPoolConfiguratorImpl(address configurator) external;

  function getLendingPoolCollateralManager() external view returns (address);

  function setLendingPoolCollateralManager(address manager) external;

  function getPoolAdmin() external view returns (address);

  function setPoolAdmin(address admin) external;

  function getEmergencyAdmin() external view returns (address);

  function setEmergencyAdmin(address admin) external;

  function getPriceOracle() external view returns (address);

  function setPriceOracle(address priceOracle) external;

  function getLendingRateOracle() external view returns (address);

  function setLendingRateOracle(address lendingRateOracle) external;
}


// File src/interfaces/external/aave/ILendingPool.sol

pragma solidity >=0.5.0;

interface ILendingPool {
  /// @dev Emitted on `deposit`.
  ///
  /// @param reserve    The address of the underlying asset of the reserve.
  /// @param user       The address initiating the deposit.
  /// @param onBehalfOf The beneficiary of the deposit, receiving the aTokens.
  /// @param amount     The amount deposited.
  /// @param referral   The referral code used.
  event Deposit(
    address indexed reserve,
    address user,
    address indexed onBehalfOf,
    uint256 amount,
    uint16 indexed referral
  );

  /// @dev Emitted on `withdraw`.
  ///
  /// @param reserve The address of the underlying asset being withdrawn.
  /// @param user    The address initiating the withdrawal, owner of aTokens.
  /// @param to      Address that will receive the underlying.
  /// @param amount  The amount to be withdrawn.
  event Withdraw(address indexed reserve, address indexed user, address indexed to, uint256 amount);
  
  /// @dev Emitted on `borrow` and `flashLoan` when debt needs to be opened.
  ///
  /// @param reserve        The address of the underlying asset being borrowed.
  /// @param user           The address of the user initiating the `borrow`, receiving the funds on `borrow` or just
  ///                       initiator of the transaction on `flashLoan`.
  /// @param onBehalfOf     The address that will be getting the debt.
  /// @param amount         The amount borrowed out.
  /// @param borrowRateMode The rate mode: 1 for Stable, 2 for Variable.
  /// @param borrowRate     The numeric rate at which the user has borrowed.
  /// @param referral       The referral code used.
  event Borrow(
    address indexed reserve,
    address user,
    address indexed onBehalfOf,
    uint256 amount,
    uint256 borrowRateMode,
    uint256 borrowRate,
    uint16 indexed referral
  );

  /// @dev Emitted on `repay`.
  ///
  /// @param reserve The address of the underlying asset of the reserve.
  /// @param user    The beneficiary of the repayment, getting his debt reduced.
  /// @param repayer The address of the user initiating the `repay`, providing the funds.
  /// @param amount  The amount repaid.
  event Repay(address indexed reserve, address indexed user, address indexed repayer, uint256 amount);
  
  /// @dev Emitted on `swapBorrowRateMode`.
  ///
  /// @param reserve  The address of the underlying asset of the reserve
  /// @param user     The address of the user swapping his rate mode
  /// @param rateMode The rate mode that the user wants to swap to
  event Swap(address indexed reserve, address indexed user, uint256 rateMode);
  
  /// @dev Emitted on `setUserUseReserveAsCollateral`.
  ///
  /// @param reserve The address of the underlying asset of the reserve
  /// @param user    The address of the user enabling the usage as collateral
  event ReserveUsedAsCollateralEnabled(address indexed reserve, address indexed user);

  /// @dev Emitted on `setUserUseReserveAsCollateral`.
  ///
  /// @param reserve The address of the underlying asset of the reserve
  /// @param user    The address of the user enabling the usage as collateral
  event ReserveUsedAsCollateralDisabled(address indexed reserve, address indexed user);
  
  /// @dev Emitted on `rebalanceStableBorrowRate`.
  ///
  /// @param reserve The address of the underlying asset of the reserve
  /// @param user    The address of the user for which the rebalance has been executed
  event RebalanceStableBorrowRate(address indexed reserve, address indexed user);

  /// @dev Emitted on `flashLoan`.
  ///
  /// @param target       The address of the flash loan receiver contract.
  /// @param initiator    The address initiating the flash loan.
  /// @param asset        The address of the asset being flash borrowed.
  /// @param amount       The amount flash borrowed.
  /// @param premium      The fee flash borrowed.
  /// @param referralCode The referral code used.
  event FlashLoan(
    address indexed target,
    address indexed initiator,
    address indexed asset,
    uint256 amount,
    uint256 premium,
    uint16 referralCode
  );

  /// @dev Emitted when the pause is triggered.
  event Paused();

  /// @dev Emitted when the pause is lifted.
  event Unpaused();

  /// @dev Emitted when a borrower is liquidated. This event is emitted by the LendingPool via LendingPoolCollateral
  ///      manager using a DELEGATECALL.
  ///
  /// This allows to have the events in the generated ABI for LendingPool.
  ///
  /// @param collateralAsset            The address of the underlying asset used as collateral, to receive as result of
  ///                                   the liquidation.
  /// @param debtAsset                  The address of the underlying borrowed asset to be repaid with the liquidation.
  /// @param user                       The address of the borrower getting liquidated.
  /// @param debtToCover                The debt amount of borrowed `asset` the liquidator wants to cover.
  /// @param liquidatedCollateralAmount The amount of collateral received by the liquidator.
  /// @param liquidator                 The address of the liquidator
  /// @param receiveAToken              `true` if the liquidators wants to receive the collateral aTokens, `false` if
  ///                                   he wants to receive the underlying collateral asset directly.
  event LiquidationCall(
    address indexed collateralAsset,
    address indexed debtAsset,
    address indexed user,
    uint256 debtToCover,
    uint256 liquidatedCollateralAmount,
    address liquidator,
    bool receiveAToken
  );

  /// @dev Emitted when the state of a reserve is updated.
  ///
  /// NOTE: This event is actually declared in the ReserveLogic library and emitted in the `updateInterestRates`
  /// function. Since the function is internal, the event will actually be fired by the LendingPool contract. The event
  /// is therefore replicated here so it gets added to the LendingPool ABI.
  ///
  /// @param reserve             The address of the underlying asset of the reserve.
  /// @param liquidityRate       The new liquidity rate.
  /// @param stableBorrowRate    The new stable borrow rate.
  /// @param variableBorrowRate  The new variable borrow rate.
  /// @param liquidityIndex      The new liquidity index
  /// @param variableBorrowIndex The new variable borrow index
  event ReserveDataUpdated(
    address indexed reserve,
    uint256 liquidityRate,
    uint256 stableBorrowRate,
    uint256 variableBorrowRate,
    uint256 liquidityIndex,
    uint256 variableBorrowIndex
  );

  /// @dev Deposits an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
  ///
  /// - E.g. User deposits 100 USDC and gets in return 100 aUSDC.
  ///
  /// @param asset        The address of the underlying asset to deposit.
  /// @param amount       The amount to be deposited.
  /// @param onBehalfOf   The address that will receive the aTokens, same as msg.sender if the user wants to receive
  ///                     them on his own wallet, or a different address if the beneficiary of aTokens is a different
  ///                     wallet.
  /// @param referralCode Code used to register the integrator originating the operation, for potential rewards.0 if the
  ///                     action is executed directly by the user, without any middle-man
  function deposit(
    address asset,
    uint256 amount,
    address onBehalfOf,
    uint16 referralCode
  ) external;

  /// @dev Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned.
  ///
  /// E.g. User has 100 aUSDC, calls `withdraw` and receives 100 USDC, burning the 100 aUSDC.
  ///
  /// @param asset  The address of the underlying asset to withdraw
  /// @param amount The underlying amount to be withdrawn.
  /// @param to     Address that will receive the underlying, same as msg.sender if the user wants to receive it on his
  ///               own wallet, or a different address if the beneficiary is a different wallet.
  ///
  /// @return amountWithdrawn The final amount withdrawn
  function withdraw(
    address asset,
    uint256 amount,
    address to
  ) external returns (uint256 amountWithdrawn);

  /// @dev Allows users to borrow a specific `amount` of the reserve underlying asset, provided that the borrower
  ///     already deposited enough collateral, or he was given enough allowance by a credit delegator on the
  ///     corresponding debt token (StableDebtToken or VariableDebtToken).
  ///
  /// - E.g. User borrows 100 USDC passing as `onBehalfOf` his own address, receiving the 100 USDC in his wallet and
  ///   100 stable/variable debt tokens, depending on the `interestRateMode`.
  ///
  /// @param asset            The address of the underlying asset to borrow.
  /// @param amount           The amount to be borrowed.
  /// @param interestRateMode The interest rate mode at which the user wants to borrow: 1 for Stable, 2 for Variable
  /// @param referralCode     Code used to register the integrator originating the operation, for potential rewards.
  ///                         0 if the action is executed directly by the user, without any middle-man
  /// @param onBehalfOf       Address of the user who will receive the debt. Should be the address of the borrower
  ///                         itself calling the function if he wants to borrow against his own collateral, or the
  ///                         address of the credit delegator if he has been given credit delegation allowance
  function borrow(
    address asset,
    uint256 amount,
    uint256 interestRateMode,
    uint16 referralCode,
    address onBehalfOf
  ) external;

  /// @notice Repays a borrowed `amount` on a specific reserve, burning the equivalent debt tokens owned.
  ///
  /// - E.g. User repays 100 USDC, burning 100 variable/stable debt tokens of the `onBehalfOf` address.
  ///
  /// @param asset      The address of the borrowed underlying asset previously borrowed.
  /// @param amount     The amount to repay.
  /// @param rateMode   The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
  /// @param onBehalfOf Address of the user who will get his debt reduced/removed. Should be the address of the user
  ///                   calling the function if he wants to reduce/remove his own debt, or the address of any other
  ///                   other borrower whose debt should be removed.
  ///
  /// @return amountRepaid The final amount repaid.
  function repay(
    address asset,
    uint256 amount,
    uint256 rateMode,
    address onBehalfOf
  ) external returns (uint256 amountRepaid);

  /// @dev Allows a borrower to swap his debt between stable and variable mode, or vice versa.
  ///
  /// @param asset    The address of the underlying asset borrowed.
  /// @param rateMode The rate mode that the user wants to swap to.
  function swapBorrowRateMode(address asset, uint256 rateMode) external;

  /// @dev Rebalances the stable interest rate of a user to the current stable rate defined on the reserve.
  ///
  /// - Users can be rebalanced if the following conditions are satisfied:
  ///   1. Usage ratio is above 95%
  ///   2. the current deposit APY is below REBALANCE_UP_THRESHOLD  maxVariableBorrowRate, which means that too much
  ///      has been borrowed at a stable rate and depositors are not earning enough.
  ///
  /// @param asset The address of the underlying asset borrowed.
  /// @param user The address of the user to be rebalanced.
  function rebalanceStableBorrowRate(address asset, address user) external;

  /// @dev Allows depositors to enable/disable a specific deposited asset as collateral.
  ///
  /// @param asset            The address of the underlying asset deposited.
  /// @param useAsCollateral `true` if the user wants to use the deposit as collateral, `false` otherwise.
  function setUserUseReserveAsCollateral(address asset, bool useAsCollateral) external;
  
  /// @dev Function to liquidate a non-healthy position collateral-wise, with Health Factor below 1.
  ///
  /// - The caller (liquidator) covers `debtToCover` amount of debt of the user getting liquidated, and receives a
  ///   proportionally amount of the `collateralAsset` plus a bonus to cover market risk.
  ///
  /// @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the
  ///                        liquidation.
  /// @param debtAsset       The address of the underlying borrowed asset to be repaid with the liquidation.
  /// @param user            The address of the borrower getting liquidated.
  /// @param debtToCover     The debt amount of borrowed `asset` the liquidator wants to cover.
  /// @param receiveAToken   `true` if the liquidators wants to receive the collateral aTokens, `false` if he wants to
  ///                        receive the underlying collateral asset directly
  function liquidationCall(
    address collateralAsset,
    address debtAsset,
    address user,
    uint256 debtToCover,
    bool receiveAToken
  ) external;

  /// @dev Allows smart contracts to access the liquidity of the pool within one transaction, as long as the amount
  ///      taken plus a fee is returned.
  ///
  /// IMPORTANT There are security concerns for developers of flash loan receiver contracts that must be kept into
  /// consideration.
  ///
  /// For further details please visit https://developers.aave.com.
  ///
  /// @param receiverAddress The address of the contract receiving the funds, implementing the IFlashLoanReceiver
  ///                        interface.
  /// @param assets          The addresses of the assets being flash-borrowed.
  /// @param amounts         The amounts amounts being flash-borrowed.
  /// @param modes           Types of the debt to open if the flash loan is not returned.
  /// @param onBehalfOf      The address  that will receive the debt in the case of using on `modes` 1 or 2.
  /// @param params          Variadic packed params to pass to the receiver as extra information.
  /// @param referralCode    Code used to register the integrator originating the operation, for potential rewards. 0
  ///                        if the action is executed directly by the user, without any middle-man
  function flashLoan(
    address receiverAddress,
    address[] calldata assets,
    uint256[] calldata amounts,
    uint256[] calldata modes,
    address onBehalfOf,
    bytes calldata params,
    uint16 referralCode
  ) external;

  /// @dev Returns the user account data across all the reserves.
  ///
  /// @param user The address of the user.
  ///
  /// @return totalCollateralETH          The total collateral in ETH of the user.
  /// @return totalDebtETH                The total debt in ETH of the user.
  /// @return availableBorrowsETH         The borrowing power left of the user.
  /// @return currentLiquidationThreshold The liquidation threshold of the user.
  /// @return ltv                         The loan to value of the user.
  /// @return healthFactor                The current health factor of the user.
  function getUserAccountData(address user)
    external
    view
    returns (
      uint256 totalCollateralETH,
      uint256 totalDebtETH,
      uint256 availableBorrowsETH,
      uint256 currentLiquidationThreshold,
      uint256 ltv,
      uint256 healthFactor
    );

  function initReserve(
    address reserve,
    address aTokenAddress,
    address stableDebtAddress,
    address variableDebtAddress,
    address interestRateStrategyAddress
  ) external;

    /**
   * @notice Supplies an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
   * - E.g. User supplies 100 USDC and gets in return 100 aUSDC
   * @param asset The address of the underlying asset to supply
   * @param amount The amount to be supplied
   * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
   *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
   *   is a different wallet
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   **/
  function supply(
    address asset,
    uint256 amount,
    address onBehalfOf,
    uint16 referralCode
  ) external;

  function setReserveInterestRateStrategyAddress(address reserve, address rateStrategyAddress) external;

  function setConfiguration(address reserve, uint256 configuration) external;

  /// @dev Returns the configuration of the reserve.
  ///
  /// @param asset The address of the underlying asset of the reserve.
  ///
  /// @return The configuration of the reserve.
  function getConfiguration(address asset) external view returns (ReserveConfigurationMap memory);

  /// @dev Returns the configuration of the user across all the reserves.
  ///
  /// @param user The user address.
  ///
  /// @return The configuration of the user.
  function getUserConfiguration(address user) external view returns (UserConfigurationMap memory);
  
  /// @dev Returns the normalized income normalized income of the reserve.
  ///
  /// @param asset The address of the underlying asset of the reserve.
  ///
  /// @return The reserve's normalized income.
  function getReserveNormalizedIncome(address asset) external view returns (uint256);

  /// @dev Returns the normalized variable debt per unit of asset.`
  ///
  /// @param asset The address of the underlying asset of the reserve.
  ///
  /// @return The reserve normalized variable debt.
  function getReserveNormalizedVariableDebt(address asset) external view returns (uint256);

  /// @dev Returns the state and configuration of the reserve.
  ///
  /// @param asset The address of the underlying asset of the reserve.
  ///
  /// @return The state of the reserve.
  function getReserveData(address asset) external view returns (ReserveData memory);

  function finalizeTransfer(
    address asset,
    address from,
    address to,
    uint256 amount,
    uint256 balanceFromAfter,
    uint256 balanceToBefore
  ) external;

  function getReservesList() external view returns (address[] memory);

  function getAddressesProvider() external view returns (ILendingPoolAddressesProvider);

  function setPause(bool val) external;

  function paused() external view returns (bool);
}


// File src/interfaces/external/aave/IAaveIncentivesController.sol

pragma solidity >=0.5.0;
pragma experimental ABIEncoderV2;

interface IAaveIncentivesController {
  event RewardsAccrued(address indexed user, uint256 amount);

  event RewardsClaimed(address indexed user, address indexed to, uint256 amount);

  event RewardsClaimed(
    address indexed user,
    address indexed to,
    address indexed claimer,
    uint256 amount
  );

  event ClaimerSet(address indexed user, address indexed claimer);

  /*
   * @dev Returns the configuration of the distribution for a certain asset
   * @param asset The address of the reference asset of the distribution
   * @return The asset index, the emission per second and the last updated timestamp
   **/
  function getAssetData(address asset)
    external
    view
    returns (
      uint256,
      uint256,
      uint256
    );

  /**
   * @dev Whitelists an address to claim the rewards on behalf of another address
   * @param user The address of the user
   * @param claimer The address of the claimer
   */
  function setClaimer(address user, address claimer) external;

  /**
   * @dev Returns the whitelisted claimer for a certain address (0x0 if not set)
   * @param user The address of the user
   * @return The claimer address
   */
  function getClaimer(address user) external view returns (address);

  /**
   * @dev Configure assets for a certain rewards emission
   * @param assets The assets to incentivize
   * @param emissionsPerSecond The emission for each asset
   */
  function configureAssets(address[] calldata assets, uint256[] calldata emissionsPerSecond)
    external;

  /**
   * @dev Called by the corresponding asset on any update that affects the rewards distribution
   * @param asset The address of the user
   * @param userBalance The balance of the user of the asset in the lending pool
   * @param totalSupply The total supply of the asset in the lending pool
   **/
  function handleAction(
    address asset,
    uint256 userBalance,
    uint256 totalSupply
  ) external;

  /**
   * @dev Returns the total of rewards of an user, already accrued + not yet accrued
   * @param user The address of the user
   * @return The rewards
   **/
  function getRewardsBalance(address[] calldata assets, address user)
    external
    view
    returns (uint256);

  /**
   * @dev Claims reward for an user, on all the assets of the lending pool, accumulating the pending rewards
   * @param amount Amount of rewards to claim
   * @param to Address that will be receiving the rewards
   * @return Rewards claimed
   **/
  function claimRewards(
    address[] calldata assets,
    uint256 amount,
    address to
  ) external returns (uint256);

  /**
   * @dev Claims reward for an user on behalf, on all the assets of the lending pool, accumulating the pending rewards. The caller must
   * be whitelisted via "allowClaimOnBehalf" function by the RewardsAdmin role manager
   * @param amount Amount of rewards to claim
   * @param user Address to check and claim rewards
   * @param to Address that will be receiving the rewards
   * @return Rewards claimed
   **/
  function claimRewardsOnBehalf(
    address[] calldata assets,
    uint256 amount,
    address user,
    address to
  ) external returns (uint256);

  /**
   * @dev returns the unclaimed rewards of the user
   * @param user the address of the user
   * @return the unclaimed user rewards
   */
  function getUserUnclaimedRewards(address user) external view returns (uint256);

  /**
   * @dev returns the unclaimed rewards of the user
   * @param user the address of the user
   * @param asset The asset to incentivize
   * @return the user index for the asset
   */
  function getUserAssetData(address user, address asset) external view returns (uint256);

  /**
   * @dev for backward compatibility with previous implementation of the Incentives controller
   */
  function REWARD_TOKEN() external view returns (address);

  /**
   * @dev for backward compatibility with previous implementation of the Incentives controller
   */
  function PRECISION() external view returns (uint8);
}


// File src/interfaces/external/aave/IInitializableAToken.sol

pragma solidity >=0.5.0;


/**
 * @title IInitializableAToken
 * @notice Interface for the initialize function on AToken
 * @author Aave
 **/
interface IInitializableAToken {
  /**
   * @dev Emitted when an aToken is initialized
   * @param underlyingAsset The address of the underlying asset
   * @param pool The address of the associated lending pool
   * @param treasury The address of the treasury
   * @param incentivesController The address of the incentives controller for this aToken
   * @param aTokenDecimals the decimals of the underlying
   * @param aTokenName the name of the aToken
   * @param aTokenSymbol the symbol of the aToken
   * @param params A set of encoded parameters for additional initialization
   **/
  event Initialized(
    address indexed underlyingAsset,
    address indexed pool,
    address treasury,
    address incentivesController,
    uint8 aTokenDecimals,
    string aTokenName,
    string aTokenSymbol,
    bytes params
  );

  /**
   * @dev Initializes the aToken
   * @param pool The address of the lending pool where this aToken will be used
   * @param treasury The address of the Aave treasury, receiving the fees on this aToken
   * @param underlyingAsset The address of the underlying asset of this aToken (E.g. WETH for aWETH)
   * @param incentivesController The smart contract managing potential incentives distribution
   * @param aTokenDecimals The decimals of the aToken, same as the underlying asset's
   * @param aTokenName The name of the aToken
   * @param aTokenSymbol The symbol of the aToken
   */
  function initialize(
    ILendingPool pool,
    address treasury,
    address underlyingAsset,
    IAaveIncentivesController incentivesController,
    uint8 aTokenDecimals,
    string calldata aTokenName,
    string calldata aTokenSymbol,
    bytes calldata params
  ) external;
}


// File src/interfaces/external/aave/IAToken.sol

pragma solidity >=0.5.0;




interface IAToken is IERC20, IScaledBalanceToken, IInitializableAToken {
  /**
   * @dev Emitted after the mint action
   * @param from The address performing the mint
   * @param value The amount being
   * @param index The new liquidity index of the reserve
   **/
  event Mint(address indexed from, uint256 value, uint256 index);

  /**
   * @dev Mints `amount` aTokens to `user`
   * @param user The address receiving the minted tokens
   * @param amount The amount of tokens getting minted
   * @param index The new liquidity index of the reserve
   * @return `true` if the the previous balance of the user was 0
   */
  function mint(
    address user,
    uint256 amount,
    uint256 index
  ) external returns (bool);

  /**
   * @dev Emitted after aTokens are burned
   * @param from The owner of the aTokens, getting them burned
   * @param target The address that will receive the underlying
   * @param value The amount being burned
   * @param index The new liquidity index of the reserve
   **/
  event Burn(address indexed from, address indexed target, uint256 value, uint256 index);

  /**
   * @dev Emitted during the transfer action
   * @param from The user whose tokens are being transferred
   * @param to The recipient
   * @param value The amount being transferred
   * @param index The new liquidity index of the reserve
   **/
  event BalanceTransfer(address indexed from, address indexed to, uint256 value, uint256 index);

  /**
   * @dev Burns aTokens from `user` and sends the equivalent amount of underlying to `receiverOfUnderlying`
   * @param user The owner of the aTokens, getting them burned
   * @param receiverOfUnderlying The address that will receive the underlying
   * @param amount The amount being burned
   * @param index The new liquidity index of the reserve
   **/
  function burn(
    address user,
    address receiverOfUnderlying,
    uint256 amount,
    uint256 index
  ) external;

  /**
   * @dev Mints aTokens to the reserve treasury
   * @param amount The amount of tokens getting minted
   * @param index The new liquidity index of the reserve
   */
  function mintToTreasury(uint256 amount, uint256 index) external;

  /**
   * @dev Transfers aTokens in the event of a borrow being liquidated, in case the liquidators reclaims the aToken
   * @param from The address getting liquidated, current owner of the aTokens
   * @param to The recipient
   * @param value The amount of tokens getting transferred
   **/
  function transferOnLiquidation(
    address from,
    address to,
    uint256 value
  ) external;

  /**
   * @dev Transfers the underlying asset to `target`. Used by the LendingPool to transfer
   * assets in borrow(), withdraw() and flashLoan()
   * @param user The recipient of the underlying
   * @param amount The amount getting transferred
   * @return The amount transferred
   **/
  function transferUnderlyingTo(address user, uint256 amount) external returns (uint256);

  /**
   * @dev Invoked to execute actions on the aToken side after a repayment.
   * @param user The user executing the repayment
   * @param amount The amount getting repaid
   **/
  function handleRepayment(address user, uint256 amount) external;

  /**
   * @dev Returns the address of the incentives controller contract
   **/
  function getIncentivesController() external view returns (IAaveIncentivesController);

  /**
   * @dev Returns the address of the underlying asset of this aToken (E.g. WETH for aWETH)
   **/
  function UNDERLYING_ASSET_ADDRESS() external view returns (address);
}


// File src/interfaces/external/aave/IStaticAToken.sol

pragma solidity >=0.5.0;


/// @title  IStaticAToken
/// @author Aave
///
/// @dev Wrapper token that allows to deposit tokens on the Aave protocol and receive token which balance doesn't
///      increase automatically, but uses an ever-increasing exchange rate. Only supporting deposits and withdrawals.
interface IStaticAToken is IERC20 {
  struct SignatureParams {
    uint8 v;
    bytes32 r;
    bytes32 s;
  }

  function LENDING_POOL() external returns (ILendingPool);
  function ATOKEN() external view returns (IERC20);
  function ASSET() external returns (IERC20);

  function _nonces(address owner) external returns (uint256);

  function claimRewards() external;

  function deposit(
    address recipient,
    uint256 amount,
    uint16 referralCode,
    bool fromUnderlying
  ) external returns (uint256);

  function withdraw(
    address recipient,
    uint256 amount,
    bool toUnderlying
  ) external returns (uint256, uint256);

  function withdrawDynamicAmount(
    address recipient,
    uint256 amount,
    bool toUnderlying
  ) external returns (uint256, uint256);

  function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s,
    uint256 chainId
  ) external;

  function metaDeposit(
    address depositor,
    address recipient,
    uint256 value,
    uint16 referralCode,
    bool fromUnderlying,
    uint256 deadline,
    SignatureParams calldata sigParams,
    uint256 chainId
  ) external returns (uint256);

  function metaWithdraw(
    address owner,
    address recipient,
    uint256 staticAmount,
    uint256 dynamicAmount,
    bool toUnderlying,
    uint256 deadline,
    SignatureParams calldata sigParams,
    uint256 chainId
  ) external returns (uint256, uint256);

  function dynamicBalanceOf(address account) external view returns (uint256);

  /// @dev Converts a static amount (scaled balance on aToken) to the aToken/underlying value, using the current
  ///      liquidity index on Aave.
  ///
  /// @param amount The amount to convert from.
  ///
  /// @return dynamicAmount The dynamic amount.
  function staticToDynamicAmount(uint256 amount) external view returns (uint256 dynamicAmount);

  /// @dev Converts an aToken or underlying amount to the what it is denominated on the aToken as scaled balance,
  ///      function of the principal and the liquidity index.
  ///
  /// @param amount The amount to convert from.
  ///
  /// @return staticAmount The static (scaled) amount.
  function dynamicToStaticAmount(uint256 amount) external view returns (uint256 staticAmount);

  /// @dev Returns the Aave liquidity index of the underlying aToken, denominated rate here as it can be considered as
  ///      an ever-increasing exchange rate.
  ///
  /// @return The rate.
  function rate() external view returns (uint256);

  /// @dev Function to return a dynamic domain separator, in order to be compatible with forks changing chainId.
  ///
  /// @param chainId The chain id.
  ///
  /// @return The domain separator.
  function getDomainSeparator(uint256 chainId) external returns (bytes32);
}


// File src/interfaces/keepers/IResolver.sol

pragma solidity ^0.8.13;

interface IResolver {
    function checker()
        external
        view
        returns (bool canExec, bytes memory execPayload);
}


// File src/interfaces/alchemist/IAlchemistV2Actions.sol

pragma solidity >=0.5.0;

/// @title  IAlchemistV2Actions
/// @author Alchemix Finance
///
/// @notice Specifies user actions.
interface IAlchemistV2Actions {
    /// @notice Approve `spender` to mint `amount` debt tokens.
    ///
    /// **_NOTE:_** This function is WHITELISTED.
    ///
    /// @param spender The address that will be approved to mint.
    /// @param amount  The amount of tokens that `spender` will be allowed to mint.
    function approveMint(address spender, uint256 amount) external;

    /// @notice Approve `spender` to withdraw `amount` shares of `yieldToken`.
    ///
    /// @notice **_NOTE:_** This function is WHITELISTED.
    ///
    /// @param spender    The address that will be approved to withdraw.
    /// @param yieldToken The address of the yield token that `spender` will be allowed to withdraw.
    /// @param shares     The amount of shares that `spender` will be allowed to withdraw.
    function approveWithdraw(
        address spender,
        address yieldToken,
        uint256 shares
    ) external;

    /// @notice Synchronizes the state of the account owned by `owner`.
    ///
    /// @param owner The owner of the account to synchronize.
    function poke(address owner) external;

    /// @notice Deposit a yield token into a user's account.
    ///
    /// @notice An approval must be set for `yieldToken` which is greater than `amount`.
    ///
    /// @notice `yieldToken` must be registered or this call will revert with a {UnsupportedToken} error.
    /// @notice `yieldToken` must be enabled or this call will revert with a {TokenDisabled} error.
    /// @notice `yieldToken` underlying token must be enabled or this call will revert with a {TokenDisabled} error.
    /// @notice `recipient` must be non-zero or this call will revert with an {IllegalArgument} error.
    /// @notice `amount` must be greater than zero or the call will revert with an {IllegalArgument} error.
    ///
    /// @notice Emits a {Deposit} event.
    ///
    /// @notice **_NOTE:_** This function is WHITELISTED.
    ///
    /// @notice **_NOTE:_** When depositing, the `AlchemistV2` contract must have **allowance()** to spend funds on behalf of **msg.sender** for at least **amount** of the **yieldToken** being deposited.  This can be done via the standard `ERC20.approve()` method.
    ///
    /// @notice **Example:**
    /// @notice ```
    /// @notice address ydai = 0xdA816459F1AB5631232FE5e97a05BBBb94970c95;
    /// @notice uint256 amount = 50000;
    /// @notice IERC20(ydai).approve(alchemistAddress, amount);
    /// @notice AlchemistV2(alchemistAddress).deposit(ydai, amount, msg.sender);
    /// @notice ```
    ///
    /// @param yieldToken The yield-token to deposit.
    /// @param amount     The amount of yield tokens to deposit.
    /// @param recipient  The owner of the account that will receive the resulting shares.
    ///
    /// @return sharesIssued The number of shares issued to `recipient`.
    function deposit(
        address yieldToken,
        uint256 amount,
        address recipient
    ) external returns (uint256 sharesIssued);

    /// @notice Deposit an underlying token into the account of `recipient` as `yieldToken`.
    ///
    /// @notice An approval must be set for the underlying token of `yieldToken` which is greater than `amount`.
    ///
    /// @notice `yieldToken` must be registered or this call will revert with a {UnsupportedToken} error.
    /// @notice `recipient` must be non-zero or this call will revert with an {IllegalArgument} error.
    /// @notice `amount` must be greater than zero or the call will revert with an {IllegalArgument} error.
    ///
    /// @notice Emits a {Deposit} event.
    ///
    /// @notice **_NOTE:_** This function is WHITELISTED.
    /// @notice **_NOTE:_** When depositing, the `AlchemistV2` contract must have **allowance()** to spend funds on behalf of **msg.sender** for at least **amount** of the **underlyingToken** being deposited.  This can be done via the standard `ERC20.approve()` method.
    ///
    /// @notice **Example:**
    /// @notice ```
    /// @notice address ydai = 0xdA816459F1AB5631232FE5e97a05BBBb94970c95;
    /// @notice uint256 amount = 50000;
    /// @notice AlchemistV2(alchemistAddress).depositUnderlying(ydai, amount, msg.sender, 1);
    /// @notice ```
    ///
    /// @param yieldToken       The address of the yield token to wrap the underlying tokens into.
    /// @param amount           The amount of the underlying token to deposit.
    /// @param recipient        The address of the recipient.
    /// @param minimumAmountOut The minimum amount of yield tokens that are expected to be deposited to `recipient`.
    ///
    /// @return sharesIssued The number of shares issued to `recipient`.
    function depositUnderlying(
        address yieldToken,
        uint256 amount,
        address recipient,
        uint256 minimumAmountOut
    ) external returns (uint256 sharesIssued);

    /// @notice Withdraw yield tokens to `recipient` by burning `share` shares. The number of yield tokens withdrawn to `recipient` will depend on the value of shares for that yield token at the time of the call.
    ///
    /// @notice `yieldToken` must be registered or this call will revert with a {UnsupportedToken} error.
    /// @notice `recipient` must be non-zero or this call will revert with an {IllegalArgument} error.
    ///
    /// @notice Emits a {Withdraw} event.
    ///
    /// @notice **_NOTE:_** This function is WHITELISTED.
    ///
    /// @notice **Example:**
    /// @notice ```
    /// @notice address ydai = 0xdA816459F1AB5631232FE5e97a05BBBb94970c95;
    /// @notice uint256 pps = AlchemistV2(alchemistAddress).getYieldTokensPerShare(ydai);
    /// @notice uint256 amtYieldTokens = 5000;
    /// @notice AlchemistV2(alchemistAddress).withdraw(ydai, amtYieldTokens / pps, msg.sender);
    /// @notice ```
    ///
    /// @param yieldToken The address of the yield token to withdraw.
    /// @param shares     The number of shares to burn.
    /// @param recipient  The address of the recipient.
    ///
    /// @return amountWithdrawn The number of yield tokens that were withdrawn to `recipient`.
    function withdraw(
        address yieldToken,
        uint256 shares,
        address recipient
    ) external returns (uint256 amountWithdrawn);

    /// @notice Withdraw yield tokens to `recipient` by burning `share` shares from the account of `owner`
    ///
    /// @notice `owner` must have an withdrawal allowance which is greater than `amount` for this call to succeed.
    ///
    /// @notice `yieldToken` must be registered or this call will revert with a {UnsupportedToken} error.
    /// @notice `recipient` must be non-zero or this call will revert with an {IllegalArgument} error.
    ///
    /// @notice Emits a {Withdraw} event.
    ///
    /// @notice **_NOTE:_** This function is WHITELISTED.
    ///
    /// @notice **Example:**
    /// @notice ```
    /// @notice address ydai = 0xdA816459F1AB5631232FE5e97a05BBBb94970c95;
    /// @notice uint256 pps = AlchemistV2(alchemistAddress).getYieldTokensPerShare(ydai);
    /// @notice uint256 amtYieldTokens = 5000;
    /// @notice AlchemistV2(alchemistAddress).withdrawFrom(msg.sender, ydai, amtYieldTokens / pps, msg.sender);
    /// @notice ```
    ///
    /// @param owner      The address of the account owner to withdraw from.
    /// @param yieldToken The address of the yield token to withdraw.
    /// @param shares     The number of shares to burn.
    /// @param recipient  The address of the recipient.
    ///
    /// @return amountWithdrawn The number of yield tokens that were withdrawn to `recipient`.
    function withdrawFrom(
        address owner,
        address yieldToken,
        uint256 shares,
        address recipient
    ) external returns (uint256 amountWithdrawn);

    /// @notice Withdraw underlying tokens to `recipient` by burning `share` shares and unwrapping the yield tokens that the shares were redeemed for.
    ///
    /// @notice `yieldToken` must be registered or this call will revert with a {UnsupportedToken} error.
    /// @notice `recipient` must be non-zero or this call will revert with an {IllegalArgument} error.
    /// @notice The loss in expected value of `yieldToken` must be less than the maximum permitted by the system or this call will revert with a {LossExceeded} error.
    ///
    /// @notice Emits a {Withdraw} event.
    ///
    /// @notice **_NOTE:_** This function is WHITELISTED.
    /// @notice **_NOTE:_** The caller of `withdrawFrom()` must have **withdrawAllowance()** to withdraw funds on behalf of **owner** for at least the amount of `yieldTokens` that **shares** will be converted to.  This can be done via the `approveWithdraw()` or `permitWithdraw()` methods.
    ///
    /// @notice **Example:**
    /// @notice ```
    /// @notice address ydai = 0xdA816459F1AB5631232FE5e97a05BBBb94970c95;
    /// @notice uint256 pps = AlchemistV2(alchemistAddress).getUnderlyingTokensPerShare(ydai);
    /// @notice uint256 amountUnderlyingTokens = 5000;
    /// @notice AlchemistV2(alchemistAddress).withdrawUnderlying(ydai, amountUnderlyingTokens / pps, msg.sender, 1);
    /// @notice ```
    ///
    /// @param yieldToken       The address of the yield token to withdraw.
    /// @param shares           The number of shares to burn.
    /// @param recipient        The address of the recipient.
    /// @param minimumAmountOut The minimum amount of underlying tokens that are expected to be withdrawn to `recipient`.
    ///
    /// @return amountWithdrawn The number of underlying tokens that were withdrawn to `recipient`.
    function withdrawUnderlying(
        address yieldToken,
        uint256 shares,
        address recipient,
        uint256 minimumAmountOut
    ) external returns (uint256 amountWithdrawn);

    /// @notice Withdraw underlying tokens to `recipient` by burning `share` shares from the account of `owner` and unwrapping the yield tokens that the shares were redeemed for.
    ///
    /// @notice `yieldToken` must be registered or this call will revert with a {UnsupportedToken} error.
    /// @notice `recipient` must be non-zero or this call will revert with an {IllegalArgument} error.
    /// @notice The loss in expected value of `yieldToken` must be less than the maximum permitted by the system or this call will revert with a {LossExceeded} error.
    ///
    /// @notice Emits a {Withdraw} event.
    ///
    /// @notice **_NOTE:_** This function is WHITELISTED.
    /// @notice **_NOTE:_** The caller of `withdrawFrom()` must have **withdrawAllowance()** to withdraw funds on behalf of **owner** for at least the amount of `yieldTokens` that **shares** will be converted to.  This can be done via the `approveWithdraw()` or `permitWithdraw()` methods.
    ///
    /// @notice **Example:**
    /// @notice ```
    /// @notice address ydai = 0xdA816459F1AB5631232FE5e97a05BBBb94970c95;
    /// @notice uint256 pps = AlchemistV2(alchemistAddress).getUnderlyingTokensPerShare(ydai);
    /// @notice uint256 amtUnderlyingTokens = 5000 * 10**ydai.decimals();
    /// @notice AlchemistV2(alchemistAddress).withdrawUnderlying(msg.sender, ydai, amtUnderlyingTokens / pps, msg.sender, 1);
    /// @notice ```
    ///
    /// @param owner            The address of the account owner to withdraw from.
    /// @param yieldToken       The address of the yield token to withdraw.
    /// @param shares           The number of shares to burn.
    /// @param recipient        The address of the recipient.
    /// @param minimumAmountOut The minimum amount of underlying tokens that are expected to be withdrawn to `recipient`.
    ///
    /// @return amountWithdrawn The number of underlying tokens that were withdrawn to `recipient`.
    function withdrawUnderlyingFrom(
        address owner,
        address yieldToken,
        uint256 shares,
        address recipient,
        uint256 minimumAmountOut
    ) external returns (uint256 amountWithdrawn);

    /// @notice Mint `amount` debt tokens.
    ///
    /// @notice `recipient` must be non-zero or this call will revert with an {IllegalArgument} error.
    /// @notice `amount` must be greater than zero or this call will revert with a {IllegalArgument} error.
    ///
    /// @notice Emits a {Mint} event.
    ///
    /// @notice **_NOTE:_** This function is WHITELISTED.
    ///
    /// @notice **Example:**
    /// @notice ```
    /// @notice uint256 amtDebt = 5000;
    /// @notice AlchemistV2(alchemistAddress).mint(amtDebt, msg.sender);
    /// @notice ```
    ///
    /// @param amount    The amount of tokens to mint.
    /// @param recipient The address of the recipient.
    function mint(uint256 amount, address recipient) external;

    /// @notice Mint `amount` debt tokens from the account owned by `owner` to `recipient`.
    ///
    /// @notice `recipient` must be non-zero or this call will revert with an {IllegalArgument} error.
    /// @notice `amount` must be greater than zero or this call will revert with a {IllegalArgument} error.
    ///
    /// @notice Emits a {Mint} event.
    ///
    /// @notice **_NOTE:_** This function is WHITELISTED.
    /// @notice **_NOTE:_** The caller of `mintFrom()` must have **mintAllowance()** to mint debt from the `Account` controlled by **owner** for at least the amount of **yieldTokens** that **shares** will be converted to.  This can be done via the `approveMint()` or `permitMint()` methods.
    ///
    /// @notice **Example:**
    /// @notice ```
    /// @notice uint256 amtDebt = 5000;
    /// @notice AlchemistV2(alchemistAddress).mintFrom(msg.sender, amtDebt, msg.sender);
    /// @notice ```
    ///
    /// @param owner     The address of the owner of the account to mint from.
    /// @param amount    The amount of tokens to mint.
    /// @param recipient The address of the recipient.
    function mintFrom(
        address owner,
        uint256 amount,
        address recipient
    ) external;

    /// @notice Burn `amount` debt tokens to credit the account owned by `recipient`.
    ///
    /// @notice `amount` will be limited up to the amount of debt that `recipient` currently holds.
    ///
    /// @notice `recipient` must be non-zero or this call will revert with an {IllegalArgument} error.
    /// @notice `amount` must be greater than zero or this call will revert with a {IllegalArgument} error.
    /// @notice `recipient` must have non-zero debt or this call will revert with an {IllegalState} error.
    ///
    /// @notice Emits a {Burn} event.
    ///
    /// @notice **_NOTE:_** This function is WHITELISTED.
    ///
    /// @notice **Example:**
    /// @notice ```
    /// @notice uint256 amtBurn = 5000;
    /// @notice AlchemistV2(alchemistAddress).burn(amtBurn, msg.sender);
    /// @notice ```
    ///
    /// @param amount    The amount of tokens to burn.
    /// @param recipient The address of the recipient.
    ///
    /// @return amountBurned The amount of tokens that were burned.
    function burn(uint256 amount, address recipient) external returns (uint256 amountBurned);

    /// @notice Repay `amount` debt using `underlyingToken` to credit the account owned by `recipient`.
    ///
    /// @notice `amount` will be limited up to the amount of debt that `recipient` currently holds.
    ///
    /// @notice `amount` must be greater than zero or this call will revert with a {IllegalArgument} error.
    /// @notice `recipient` must be non-zero or this call will revert with an {IllegalArgument} error.
    /// @notice `underlyingToken` must be enabled or this call will revert with a {TokenDisabled} error.
    /// @notice `amount` must be less than or equal to the current available repay limit or this call will revert with a {ReplayLimitExceeded} error.
    ///
    /// @notice Emits a {Repay} event.
    /// @notice **_NOTE:_** This function is WHITELISTED.
    ///
    /// @notice **Example:**
    /// @notice ```
    /// @notice address dai = 0x6b175474e89094c44da98b954eedeac495271d0f;
    /// @notice uint256 amtRepay = 5000;
    /// @notice AlchemistV2(alchemistAddress).repay(dai, amtRepay, msg.sender);
    /// @notice ```
    ///
    /// @param underlyingToken The address of the underlying token to repay.
    /// @param amount          The amount of the underlying token to repay.
    /// @param recipient       The address of the recipient which will receive credit.
    ///
    /// @return amountRepaid The amount of tokens that were repaid.
    function repay(
        address underlyingToken,
        uint256 amount,
        address recipient
    ) external returns (uint256 amountRepaid);

    /// @notice
    ///
    /// @notice `shares` will be limited up to an equal amount of debt that `recipient` currently holds.
    ///
    /// @notice `shares` must be greater than zero or this call will revert with a {IllegalArgument} error.
    /// @notice `yieldToken` must be registered or this call will revert with a {UnsupportedToken} error.
    /// @notice `yieldToken` must be enabled or this call will revert with a {TokenDisabled} error.
    /// @notice `yieldToken` underlying token must be enabled or this call will revert with a {TokenDisabled} error.
    /// @notice The loss in expected value of `yieldToken` must be less than the maximum permitted by the system or this call will revert with a {LossExceeded} error.
    /// @notice `amount` must be less than or equal to the current available liquidation limit or this call will revert with a {LiquidationLimitExceeded} error.
    ///
    /// @notice Emits a {Liquidate} event.
    ///
    /// @notice **_NOTE:_** This function is WHITELISTED.
    ///
    /// @notice **Example:**
    /// @notice ```
    /// @notice address ydai = 0xdA816459F1AB5631232FE5e97a05BBBb94970c95;
    /// @notice uint256 amtSharesLiquidate = 5000 * 10**ydai.decimals();
    /// @notice AlchemistV2(alchemistAddress).liquidate(ydai, amtSharesLiquidate, 1);
    /// @notice ```
    ///
    /// @param yieldToken       The address of the yield token to liquidate.
    /// @param shares           The number of shares to burn for credit.
    /// @param minimumAmountOut The minimum amount of underlying tokens that are expected to be liquidated.
    ///
    /// @return sharesLiquidated The amount of shares that were liquidated.
    function liquidate(
        address yieldToken,
        uint256 shares,
        uint256 minimumAmountOut
    ) external returns (uint256 sharesLiquidated);

    /// @notice Burns `amount` debt tokens to credit accounts which have deposited `yieldToken`.
    ///
    /// @notice `amount` must be greater than zero or this call will revert with a {IllegalArgument} error.
    /// @notice `yieldToken` must be registered or this call will revert with a {UnsupportedToken} error.
    ///
    /// @notice Emits a {Donate} event.
    ///
    /// @notice **_NOTE:_** This function is WHITELISTED.
    ///
    /// @notice **Example:**
    /// @notice ```
    /// @notice address ydai = 0xdA816459F1AB5631232FE5e97a05BBBb94970c95;
    /// @notice uint256 amtSharesLiquidate = 5000;
    /// @notice AlchemistV2(alchemistAddress).liquidate(dai, amtSharesLiquidate, 1);
    /// @notice ```
    ///
    /// @param yieldToken The address of the yield token to credit accounts for.
    /// @param amount     The amount of debt tokens to burn.
    function donate(address yieldToken, uint256 amount) external;

    /// @notice Harvests outstanding yield that a yield token has accumulated and distributes it as credit to holders.
    ///
    /// @notice `msg.sender` must be a keeper or this call will revert with an {Unauthorized} error.
    /// @notice `yieldToken` must be registered or this call will revert with a {UnsupportedToken} error.
    /// @notice The amount being harvested must be greater than zero or else this call will revert with an {IllegalState} error.
    ///
    /// @notice Emits a {Harvest} event.
    ///
    /// @param yieldToken       The address of the yield token to harvest.
    /// @param minimumAmountOut The minimum amount of underlying tokens that are expected to be withdrawn to `recipient`.
    function harvest(address yieldToken, uint256 minimumAmountOut) external;
}


// File src/interfaces/alchemist/IAlchemistV2AdminActions.sol

pragma solidity >=0.5.0;

/// @title  IAlchemistV2AdminActions
/// @author Alchemix Finance
///
/// @notice Specifies admin and or sentinel actions.
interface IAlchemistV2AdminActions {
    /// @notice Contract initialization parameters.
    struct InitializationParams {
        // The initial admin account.
        address admin;
        // The ERC20 token used to represent debt.
        address debtToken;
        // The initial transmuter or transmuter buffer.
        address transmuter;
        // The minimum collateralization ratio that an account must maintain.
        uint256 minimumCollateralization;
        // The percentage fee taken from each harvest measured in units of basis points.
        uint256 protocolFee;
        // The address that receives protocol fees.
        address protocolFeeReceiver;
        // A limit used to prevent administrators from making minting functionality inoperable.
        uint256 mintingLimitMinimum;
        // The maximum number of tokens that can be minted per period of time.
        uint256 mintingLimitMaximum;
        // The number of blocks that it takes for the minting limit to be refreshed.
        uint256 mintingLimitBlocks;
        // The address of the whitelist.
        address whitelist;
    }

    /// @notice Configuration parameters for an underlying token.
    struct UnderlyingTokenConfig {
        // A limit used to prevent administrators from making repayment functionality inoperable.
        uint256 repayLimitMinimum;
        // The maximum number of underlying tokens that can be repaid per period of time.
        uint256 repayLimitMaximum;
        // The number of blocks that it takes for the repayment limit to be refreshed.
        uint256 repayLimitBlocks;
        // A limit used to prevent administrators from making liquidation functionality inoperable.
        uint256 liquidationLimitMinimum;
        // The maximum number of underlying tokens that can be liquidated per period of time.
        uint256 liquidationLimitMaximum;
        // The number of blocks that it takes for the liquidation limit to be refreshed.
        uint256 liquidationLimitBlocks;
    }

    /// @notice Configuration parameters of a yield token.
    struct YieldTokenConfig {
        // The adapter used by the system to interop with the token.
        address adapter;
        // The maximum percent loss in expected value that can occur before certain actions are disabled measured in
        // units of basis points.
        uint256 maximumLoss;
        // The maximum value that can be held by the system before certain actions are disabled measured in the
        // underlying token.
        uint256 maximumExpectedValue;
        // The number of blocks that credit will be distributed over to depositors.
        uint256 creditUnlockBlocks;
    }

    /// @notice Initialize the contract.
    ///
    /// @notice `params.protocolFee` must be in range or this call will with an {IllegalArgument} error.
    /// @notice The minting growth limiter parameters must be valid or this will revert with an {IllegalArgument} error. For more information, see the {Limiters} library.
    ///
    /// @notice Emits an {AdminUpdated} event.
    /// @notice Emits a {TransmuterUpdated} event.
    /// @notice Emits a {MinimumCollateralizationUpdated} event.
    /// @notice Emits a {ProtocolFeeUpdated} event.
    /// @notice Emits a {ProtocolFeeReceiverUpdated} event.
    /// @notice Emits a {MintingLimitUpdated} event.
    ///
    /// @param params The contract initialization parameters.
    function initialize(InitializationParams memory params) external;

    /// @notice Sets the pending administrator.
    ///
    /// @notice `msg.sender` must be the admin or this call will will revert with an {Unauthorized} error.
    ///
    /// @notice Emits a {PendingAdminUpdated} event.
    ///
    /// @dev This is the first step in the two-step process of setting a new administrator. After this function is called, the pending administrator will then need to call {acceptAdmin} to complete the process.
    ///
    /// @param value the address to set the pending admin to.
    function setPendingAdmin(address value) external;

    /// @notice Allows for `msg.sender` to accepts the role of administrator.
    ///
    /// @notice `msg.sender` must be the admin or this call will revert with an {Unauthorized} error.
    /// @notice The current pending administrator must be non-zero or this call will revert with an {IllegalState} error.
    ///
    /// @dev This is the second step in the two-step process of setting a new administrator. After this function is successfully called, this pending administrator will be reset and the new administrator will be set.
    ///
    /// @notice Emits a {AdminUpdated} event.
    /// @notice Emits a {PendingAdminUpdated} event.
    function acceptAdmin() external;

    /// @notice Sets an address as a sentinel.
    ///
    /// @notice `msg.sender` must be the admin or this call will revert with an {Unauthorized} error.
    ///
    /// @param sentinel The address to set or unset as a sentinel.
    /// @param flag     A flag indicating of the address should be set or unset as a sentinel.
    function setSentinel(address sentinel, bool flag) external;

    /// @notice Sets an address as a keeper.
    ///
    /// @notice `msg.sender` must be the admin or this call will revert with an {Unauthorized} error.
    ///
    /// @param keeper The address to set or unset as a keeper.
    /// @param flag   A flag indicating of the address should be set or unset as a keeper.
    function setKeeper(address keeper, bool flag) external;

    /// @notice Adds an underlying token to the system.
    ///
    /// @notice `msg.sender` must be the admin or this call will revert with an {Unauthorized} error.
    ///
    /// @param underlyingToken The address of the underlying token to add.
    /// @param config          The initial underlying token configuration.
    function addUnderlyingToken(
        address underlyingToken,
        UnderlyingTokenConfig calldata config
    ) external;

    /// @notice Adds a yield token to the system.
    ///
    /// @notice `msg.sender` must be the admin or this call will revert with an {Unauthorized} error.
    ///
    /// @notice Emits a {AddYieldToken} event.
    /// @notice Emits a {TokenAdapterUpdated} event.
    /// @notice Emits a {MaximumLossUpdated} event.
    ///
    /// @param yieldToken The address of the yield token to add.
    /// @param config     The initial yield token configuration.
    function addYieldToken(address yieldToken, YieldTokenConfig calldata config)
        external;

    /// @notice Sets an underlying token as either enabled or disabled.
    ///
    /// @notice `msg.sender` must be either the admin or a sentinel or this call will revert with an {Unauthorized} error.
    /// @notice `underlyingToken` must be registered or this call will revert with a {UnsupportedToken} error.
    ///
    /// @notice Emits an {UnderlyingTokenEnabled} event.
    ///
    /// @param underlyingToken The address of the underlying token to enable or disable.
    /// @param enabled         If the underlying token should be enabled or disabled.
    function setUnderlyingTokenEnabled(address underlyingToken, bool enabled)
        external;

    /// @notice Sets a yield token as either enabled or disabled.
    ///
    /// @notice `msg.sender` must be either the admin or a sentinel or this call will revert with an {Unauthorized} error.
    /// @notice `yieldToken` must be registered or this call will revert with a {UnsupportedToken} error.
    ///
    /// @notice Emits a {YieldTokenEnabled} event.
    ///
    /// @param yieldToken The address of the yield token to enable or disable.
    /// @param enabled    If the underlying token should be enabled or disabled.
    function setYieldTokenEnabled(address yieldToken, bool enabled) external;

    /// @notice Configures the the repay limit of `underlyingToken`.
    ///
    /// @notice `msg.sender` must be the admin or this call will revert with an {Unauthorized} error.
    /// @notice `underlyingToken` must be registered or this call will revert with a {UnsupportedToken} error.
    ///
    /// @notice Emits a {ReplayLimitUpdated} event.
    ///
    /// @param underlyingToken The address of the underlying token to configure the repay limit of.
    /// @param maximum         The maximum repay limit.
    /// @param blocks          The number of blocks it will take for the maximum repayment limit to be replenished when it is completely exhausted.
    function configureRepayLimit(
        address underlyingToken,
        uint256 maximum,
        uint256 blocks
    ) external;

    /// @notice Configure the liquidation limiter of `underlyingToken`.
    ///
    /// @notice `msg.sender` must be the admin or this call will revert with an {Unauthorized} error.
    /// @notice `underlyingToken` must be registered or this call will revert with a {UnsupportedToken} error.
    ///
    /// @notice Emits a {LiquidationLimitUpdated} event.
    ///
    /// @param underlyingToken The address of the underlying token to configure the liquidation limit of.
    /// @param maximum         The maximum liquidation limit.
    /// @param blocks          The number of blocks it will take for the maximum liquidation limit to be replenished when it is completely exhausted.
    function configureLiquidationLimit(
        address underlyingToken,
        uint256 maximum,
        uint256 blocks
    ) external;

    /// @notice Set the address of the transmuter.
    ///
    /// @notice `msg.sender` must be the admin or this call will revert with an {Unauthorized} error.
    /// @notice `value` must be non-zero or this call will revert with an {IllegalArgument} error.
    ///
    /// @notice Emits a {TransmuterUpdated} event.
    ///
    /// @param value The address of the transmuter.
    function setTransmuter(address value) external;

    /// @notice Set the minimum collateralization ratio.
    ///
    /// @notice `msg.sender` must be the admin or this call will revert with an {Unauthorized} error.
    ///
    /// @notice Emits a {MinimumCollateralizationUpdated} event.
    ///
    /// @param value The new minimum collateralization ratio.
    function setMinimumCollateralization(uint256 value) external;

    /// @notice Sets the fee that the protocol will take from harvests.
    ///
    /// @notice `msg.sender` must be the admin or this call will revert with an {Unauthorized} error.
    /// @notice `value` must be in range or this call will with an {IllegalArgument} error.
    ///
    /// @notice Emits a {ProtocolFeeUpdated} event.
    ///
    /// @param value The value to set the protocol fee to measured in basis points.
    function setProtocolFee(uint256 value) external;

    /// @notice Sets the address which will receive protocol fees.
    ///
    /// @notice `msg.sender` must be the admin or this call will revert with an {Unauthorized} error.
    /// @notice `value` must be non-zero or this call will revert with an {IllegalArgument} error.
    ///
    /// @notice Emits a {ProtocolFeeReceiverUpdated} event.
    ///
    /// @param value The address to set the protocol fee receiver to.
    function setProtocolFeeReceiver(address value) external;

    /// @notice Configures the minting limiter.
    ///
    /// @notice `msg.sender` must be the admin or this call will revert with an {Unauthorized} error.
    ///
    /// @notice Emits a {MintingLimitUpdated} event.
    ///
    /// @param maximum The maximum minting limit.
    /// @param blocks  The number of blocks it will take for the maximum minting limit to be replenished when it is completely exhausted.
    function configureMintingLimit(uint256 maximum, uint256 blocks) external;

    /// @notice Sets the rate at which credit will be completely available to depositors after it is harvested.
    ///
    /// @notice Emits a {CreditUnlockRateUpdated} event.
    ///
    /// @param yieldToken The address of the yield token to set the credit unlock rate for.
    /// @param blocks     The number of blocks that it will take before the credit will be unlocked.
    function configureCreditUnlockRate(address yieldToken, uint256 blocks) external;

    /// @notice Sets the token adapter of a yield token.
    ///
    /// @notice `msg.sender` must be the admin or this call will revert with an {Unauthorized} error.
    /// @notice `yieldToken` must be registered or this call will revert with a {UnsupportedToken} error.
    /// @notice The token that `adapter` supports must be `yieldToken` or this call will revert with a {IllegalState} error.
    ///
    /// @notice Emits a {TokenAdapterUpdated} event.
    ///
    /// @param yieldToken The address of the yield token to set the adapter for.
    /// @param adapter    The address to set the token adapter to.
    function setTokenAdapter(address yieldToken, address adapter) external;

    /// @notice Sets the maximum expected value of a yield token that the system can hold.
    ///
    /// @notice `msg.sender` must be the admin or this call will revert with an {Unauthorized} error.
    /// @notice `yieldToken` must be registered or this call will revert with a {UnsupportedToken} error.
    ///
    /// @param yieldToken The address of the yield token to set the maximum expected value for.
    /// @param value      The maximum expected value of the yield token denoted measured in its underlying token.
    function setMaximumExpectedValue(address yieldToken, uint256 value)
        external;

    /// @notice Sets the maximum loss that a yield bearing token will permit before restricting certain actions.
    ///
    /// @notice `msg.sender` must be the admin or this call will revert with an {Unauthorized} error.
    /// @notice `yieldToken` must be registered or this call will revert with a {UnsupportedToken} error.
    ///
    /// @dev There are two types of loss of value for yield bearing assets: temporary or permanent. The system will automatically restrict actions which are sensitive to both forms of loss when detected. For example, deposits must be restricted when an excessive loss is encountered to prevent users from having their collateral harvested from them. While the user would receive credit, which then could be exchanged for value equal to the collateral that was harvested from them, it is seen as a negative user experience because the value of their collateral should have been higher than what was originally recorded when they made their deposit.
    ///
    /// @param yieldToken The address of the yield bearing token to set the maximum loss for.
    /// @param value      The value to set the maximum loss to. This is in units of basis points.
    function setMaximumLoss(address yieldToken, uint256 value) external;

    /// @notice Snap the expected value `yieldToken` to the current value.
    ///
    /// @notice `msg.sender` must be the admin or this call will revert with an {Unauthorized} error.
    /// @notice `yieldToken` must be registered or this call will revert with a {UnsupportedToken} error.
    ///
    /// @dev This function should only be used in the event of a loss in the target yield-token. For example, say a third-party protocol experiences a fifty percent loss. The expected value (amount of underlying tokens) of the yield tokens being held by the system would be two times the real value that those yield tokens could be redeemed for. This function gives governance a way to realize those losses so that users can continue using the token as normal.
    ///
    /// @param yieldToken The address of the yield token to snap.
    function snap(address yieldToken) external;

    /// @notice Sweep all of 'rewardtoken' from the alchemist into the rewardCollector;
    ///
    /// @notice `msg.sender` must be the admin or this call will revert with an {Unauthorized} error.
    /// @notice `rewardToken` must not be a yield or underlying token or this call will revert with a {UnsupportedToken} error.
    ///
    /// @param rewardToken The address of the reward token sweep.
    /// @param yieldToken The address of the yield token whose rewards are being swept.
    function sweepRewardTokens(address rewardToken, address yieldToken) external;

     /// @notice Sweep all of 'token' from the alchemist into the admin.
    ///
    /// @notice `msg.sender` must be the admin or this call will revert with an {Unauthorized} error.
    /// @notice `token` must not be a yield or underlying token or this call will revert with a {UnsupportedToken} error.
    ///
    /// @param token The address of the token to sweep.
    /// @param amount The amount of 'token' to sweep to the admin.
    function sweepTokens(address token, uint256 amount) external;

    /// @notice Set the address of the V1 transfer adapter.
    ///
    /// @notice `msg.sender` must be the admin or this call will revert with an {Unauthorized} error.
    ///
    /// @param transferAdapterAddress The address of the V1 transfer adapter to be set in the alchemist.
    function setTransferAdapterAddress(address transferAdapterAddress) external;

    /// @notice Accept debt from the V1 transfer vault adapter.
    ///
    /// @notice `msg.sender` must be a sentinal or the admin or this call will revert with an {Unauthorized} error.
    ///
    /// @param owner    The owner of the account whos debt to increase.
    /// @param debt     The amount of debt incoming from the V1 tranfer adapter.
    function transferDebtV1(address owner, int256 debt) external;
}


// File src/interfaces/alchemist/IAlchemistV2Errors.sol

pragma solidity >=0.5.0;

/// @title  IAlchemistV2Errors
/// @author Alchemix Finance
///
/// @notice Specifies errors.
interface IAlchemistV2Errors {
    /// @notice An error which is used to indicate that an operation failed because it tried to operate on a token that the system did not recognize.
    ///
    /// @param token The address of the token.
    error UnsupportedToken(address token);

    /// @notice An error which is used to indicate that an operation failed because it tried to operate on a token that has been disabled.
    ///
    /// @param token The address of the token.
    error TokenDisabled(address token);

    /// @notice An error which is used to indicate that an operation failed because an account became undercollateralized.
    error Undercollateralized();

    /// @notice An error which is used to indicate that an operation failed because the expected value of a yield token in the system exceeds the maximum value permitted.
    ///
    /// @param yieldToken           The address of the yield token.
    /// @param expectedValue        The expected value measured in units of the underlying token.
    /// @param maximumExpectedValue The maximum expected value permitted measured in units of the underlying token.
    error ExpectedValueExceeded(address yieldToken, uint256 expectedValue, uint256 maximumExpectedValue);

    /// @notice An error which is used to indicate that an operation failed because the loss that a yield token in the system exceeds the maximum value permitted.
    ///
    /// @param yieldToken  The address of the yield token.
    /// @param loss        The amount of loss measured in basis points.
    /// @param maximumLoss The maximum amount of loss permitted measured in basis points.
    error LossExceeded(address yieldToken, uint256 loss, uint256 maximumLoss);

    /// @notice An error which is used to indicate that a minting operation failed because the minting limit has been exceeded.
    ///
    /// @param amount    The amount of debt tokens that were requested to be minted.
    /// @param available The amount of debt tokens which are available to mint.
    error MintingLimitExceeded(uint256 amount, uint256 available);

    /// @notice An error which is used to indicate that an repay operation failed because the repay limit for an underlying token has been exceeded.
    ///
    /// @param underlyingToken The address of the underlying token.
    /// @param amount          The amount of underlying tokens that were requested to be repaid.
    /// @param available       The amount of underlying tokens that are available to be repaid.
    error RepayLimitExceeded(address underlyingToken, uint256 amount, uint256 available);

    /// @notice An error which is used to indicate that an repay operation failed because the liquidation limit for an underlying token has been exceeded.
    ///
    /// @param underlyingToken The address of the underlying token.
    /// @param amount          The amount of underlying tokens that were requested to be liquidated.
    /// @param available       The amount of underlying tokens that are available to be liquidated.
    error LiquidationLimitExceeded(address underlyingToken, uint256 amount, uint256 available);

    /// @notice An error which is used to indicate that the slippage of a wrap or unwrap operation was exceeded.
    ///
    /// @param amount           The amount of underlying or yield tokens returned by the operation.
    /// @param minimumAmountOut The minimum amount of the underlying or yield token that was expected when performing
    ///                         the operation.
    error SlippageExceeded(uint256 amount, uint256 minimumAmountOut);
}


// File src/interfaces/alchemist/IAlchemistV2Immutables.sol

pragma solidity >=0.5.0;

/// @title  IAlchemistV2Immutables
/// @author Alchemix Finance
interface IAlchemistV2Immutables {
    /// @notice Returns the version of the alchemist.
    ///
    /// @return The version.
    function version() external view returns (string memory);

    /// @notice Returns the address of the debt token used by the system.
    ///
    /// @return The address of the debt token.
    function debtToken() external view returns (address);
}


// File src/interfaces/alchemist/IAlchemistV2Events.sol

pragma solidity >=0.5.0;

/// @title  IAlchemistV2Events
/// @author Alchemix Finance
interface IAlchemistV2Events {
    /// @notice Emitted when the pending admin is updated.
    ///
    /// @param pendingAdmin The address of the pending admin.
    event PendingAdminUpdated(address pendingAdmin);

    /// @notice Emitted when the administrator is updated.
    ///
    /// @param admin The address of the administrator.
    event AdminUpdated(address admin);

    /// @notice Emitted when an address is set or unset as a sentinel.
    ///
    /// @param sentinel The address of the sentinel.
    /// @param flag     A flag indicating if `sentinel` was set or unset as a sentinel.
    event SentinelSet(address sentinel, bool flag);

    /// @notice Emitted when an address is set or unset as a keeper.
    ///
    /// @param sentinel The address of the keeper.
    /// @param flag     A flag indicating if `keeper` was set or unset as a sentinel.
    event KeeperSet(address sentinel, bool flag);

    /// @notice Emitted when an underlying token is added.
    ///
    /// @param underlyingToken The address of the underlying token that was added.
    event AddUnderlyingToken(address indexed underlyingToken);

    /// @notice Emitted when a yield token is added.
    ///
    /// @param yieldToken The address of the yield token that was added.
    event AddYieldToken(address indexed yieldToken);

    /// @notice Emitted when an underlying token is enabled or disabled.
    ///
    /// @param underlyingToken The address of the underlying token that was enabled or disabled.
    /// @param enabled         A flag indicating if the underlying token was enabled or disabled.
    event UnderlyingTokenEnabled(address indexed underlyingToken, bool enabled);

    /// @notice Emitted when an yield token is enabled or disabled.
    ///
    /// @param yieldToken The address of the yield token that was enabled or disabled.
    /// @param enabled    A flag indicating if the yield token was enabled or disabled.
    event YieldTokenEnabled(address indexed yieldToken, bool enabled);

    /// @notice Emitted when the repay limit of an underlying token is updated.
    ///
    /// @param underlyingToken The address of the underlying token.
    /// @param maximum         The updated maximum repay limit.
    /// @param blocks          The updated number of blocks it will take for the maximum repayment limit to be replenished when it is completely exhausted.
    event RepayLimitUpdated(address indexed underlyingToken, uint256 maximum, uint256 blocks);

    /// @notice Emitted when the liquidation limit of an underlying token is updated.
    ///
    /// @param underlyingToken The address of the underlying token.
    /// @param maximum         The updated maximum liquidation limit.
    /// @param blocks          The updated number of blocks it will take for the maximum liquidation limit to be replenished when it is completely exhausted.
    event LiquidationLimitUpdated(address indexed underlyingToken, uint256 maximum, uint256 blocks);

    /// @notice Emitted when the transmuter is updated.
    ///
    /// @param transmuter The updated address of the transmuter.
    event TransmuterUpdated(address transmuter);

    /// @notice Emitted when the minimum collateralization is updated.
    ///
    /// @param minimumCollateralization The updated minimum collateralization.
    event MinimumCollateralizationUpdated(uint256 minimumCollateralization);

    /// @notice Emitted when the protocol fee is updated.
    ///
    /// @param protocolFee The updated protocol fee.
    event ProtocolFeeUpdated(uint256 protocolFee);
    
    /// @notice Emitted when the protocol fee receiver is updated.
    ///
    /// @param protocolFeeReceiver The updated address of the protocol fee receiver.
    event ProtocolFeeReceiverUpdated(address protocolFeeReceiver);

    /// @notice Emitted when the minting limit is updated.
    ///
    /// @param maximum The updated maximum minting limit.
    /// @param blocks  The updated number of blocks it will take for the maximum minting limit to be replenished when it is completely exhausted.
    event MintingLimitUpdated(uint256 maximum, uint256 blocks);

    /// @notice Emitted when the credit unlock rate is updated.
    ///
    /// @param yieldToken The address of the yield token.
    /// @param blocks     The number of blocks that distributed credit will unlock over.
    event CreditUnlockRateUpdated(address yieldToken, uint256 blocks);

    /// @notice Emitted when the adapter of a yield token is updated.
    ///
    /// @param yieldToken   The address of the yield token.
    /// @param tokenAdapter The updated address of the token adapter.
    event TokenAdapterUpdated(address yieldToken, address tokenAdapter);

    /// @notice Emitted when the maximum expected value of a yield token is updated.
    ///
    /// @param yieldToken           The address of the yield token.
    /// @param maximumExpectedValue The updated maximum expected value.
    event MaximumExpectedValueUpdated(address indexed yieldToken, uint256 maximumExpectedValue);

    /// @notice Emitted when the maximum loss of a yield token is updated.
    ///
    /// @param yieldToken  The address of the yield token.
    /// @param maximumLoss The updated maximum loss.
    event MaximumLossUpdated(address indexed yieldToken, uint256 maximumLoss);

    /// @notice Emitted when the expected value of a yield token is snapped to its current value.
    ///
    /// @param yieldToken    The address of the yield token.
    /// @param expectedValue The updated expected value measured in the yield token's underlying token.
    event Snap(address indexed yieldToken, uint256 expectedValue);

    /// @notice Emitted when a the admin sweeps all of one reward token from the Alchemist
    ///
    /// @param rewardToken The address of the reward token.
    /// @param amount      The amount of 'rewardToken' swept into the admin.
    event SweepRewardTokens(address indexed rewardToken, uint256 amount);

    /// @notice Emitted when a the admin sweeps all of one token from the Alchemist
    ///
    /// @param token The address of the reward token.
    /// @param amount      The amount of 'token' swept into the admin.
    event SweepTokens(address indexed token, uint256 amount);

    /// @notice Emitted when `owner` grants `spender` the ability to mint debt tokens on its behalf.
    ///
    /// @param owner   The address of the account owner.
    /// @param spender The address which is being permitted to mint tokens on the behalf of `owner`.
    /// @param amount  The amount of debt tokens that `spender` is allowed to mint.
    event ApproveMint(address indexed owner, address indexed spender, uint256 amount);

    /// @notice Emitted when `owner` grants `spender` the ability to withdraw `yieldToken` from its account.
    ///
    /// @param owner      The address of the account owner.
    /// @param spender    The address which is being permitted to mint tokens on the behalf of `owner`.
    /// @param yieldToken The address of the yield token that `spender` is allowed to withdraw.
    /// @param amount     The amount of shares of `yieldToken` that `spender` is allowed to withdraw.
    event ApproveWithdraw(address indexed owner, address indexed spender, address indexed yieldToken, uint256 amount);

    /// @notice Emitted when a user deposits `amount of `yieldToken` to `recipient`.
    ///
    /// @notice This event does not imply that `sender` directly deposited yield tokens. It is possible that the
    ///         underlying tokens were wrapped.
    ///
    /// @param sender       The address of the user which deposited funds.
    /// @param yieldToken   The address of the yield token that was deposited.
    /// @param amount       The amount of yield tokens that were deposited.
    /// @param recipient    The address that received the deposited funds.
    event Deposit(address indexed sender, address indexed yieldToken, uint256 amount, address recipient);

    /// @notice Emitted when `shares` shares of `yieldToken` are burned to withdraw `yieldToken` from the account owned
    ///         by `owner` to `recipient`.
    ///
    /// @notice This event does not imply that `recipient` received yield tokens. It is possible that the yield tokens
    ///         were unwrapped.
    ///
    /// @param owner      The address of the account owner.
    /// @param yieldToken The address of the yield token that was withdrawn.
    /// @param shares     The amount of shares that were burned.
    /// @param recipient  The address that received the withdrawn funds.
    event Withdraw(address indexed owner, address indexed yieldToken, uint256 shares, address recipient);

    /// @notice Emitted when `amount` debt tokens are minted to `recipient` using the account owned by `owner`.
    ///
    /// @param owner     The address of the account owner.
    /// @param amount    The amount of tokens that were minted.
    /// @param recipient The recipient of the minted tokens.
    event Mint(address indexed owner, uint256 amount, address recipient);

    /// @notice Emitted when `sender` burns `amount` debt tokens to grant credit to `recipient`.
    ///
    /// @param sender    The address which is burning tokens.
    /// @param amount    The amount of tokens that were burned.
    /// @param recipient The address that received credit for the burned tokens.
    event Burn(address indexed sender, uint256 amount, address recipient);

    /// @notice Emitted when `amount` of `underlyingToken` are repaid to grant credit to `recipient`.
    ///
    /// @param sender          The address which is repaying tokens.
    /// @param underlyingToken The address of the underlying token that was used to repay debt.
    /// @param amount          The amount of the underlying token that was used to repay debt.
    /// @param recipient       The address that received credit for the repaid tokens.
    /// @param credit          The amount of debt that was paid-off to the account owned by owner.
    event Repay(address indexed sender, address indexed underlyingToken, uint256 amount, address recipient, uint256 credit);

    /// @notice Emitted when `sender` liquidates `share` shares of `yieldToken`.
    ///
    /// @param owner           The address of the account owner liquidating shares.
    /// @param yieldToken      The address of the yield token.
    /// @param underlyingToken The address of the underlying token.
    /// @param shares          The amount of the shares of `yieldToken` that were liquidated.
    /// @param credit          The amount of debt that was paid-off to the account owned by owner.
    event Liquidate(address indexed owner, address indexed yieldToken, address indexed underlyingToken, uint256 shares, uint256 credit);

    /// @notice Emitted when `sender` burns `amount` debt tokens to grant credit to users who have deposited `yieldToken`.
    ///
    /// @param sender     The address which burned debt tokens.
    /// @param yieldToken The address of the yield token.
    /// @param amount     The amount of debt tokens which were burned.
    event Donate(address indexed sender, address indexed yieldToken, uint256 amount);

    /// @notice Emitted when `yieldToken` is harvested.
    ///
    /// @param yieldToken       The address of the yield token that was harvested.
    /// @param minimumAmountOut The maximum amount of loss that is acceptable when unwrapping the underlying tokens into yield tokens, measured in basis points.
    /// @param totalHarvested   The total amount of underlying tokens harvested.
    /// @param credit           The total amount of debt repaid to depositors of `yieldToken`.
    event Harvest(address indexed yieldToken, uint256 minimumAmountOut, uint256 totalHarvested, uint256 credit);
}


// File src/interfaces/alchemist/IAlchemistV2State.sol

pragma solidity >=0.5.0;

/// @title  IAlchemistV2State
/// @author Alchemix Finance
interface IAlchemistV2State {
    /// @notice Defines underlying token parameters.
    struct UnderlyingTokenParams {
        // The number of decimals the token has. This value is cached once upon registering the token so it is important
        // that the decimals of the token are immutable or the system will begin to have computation errors.
        uint8 decimals;
        // A coefficient used to normalize the token to a value comparable to the debt token. For example, if the
        // underlying token is 8 decimals and the debt token is 18 decimals then the conversion factor will be
        // 10^10. One unit of the underlying token will be comparably equal to one unit of the debt token.
        uint256 conversionFactor;
        // A flag to indicate if the token is enabled.
        bool enabled;
    }

    /// @notice Defines yield token parameters.
    struct YieldTokenParams {
        // The number of decimals the token has. This value is cached once upon registering the token so it is important
        // that the decimals of the token are immutable or the system will begin to have computation errors.
        uint8 decimals;
        // The associated underlying token that can be redeemed for the yield-token.
        address underlyingToken;
        // The adapter used by the system to wrap, unwrap, and lookup the conversion rate of this token into its
        // underlying token.
        address adapter;
        // The maximum percentage loss that is acceptable before disabling certain actions.
        uint256 maximumLoss;
        // The maximum value of yield tokens that the system can hold, measured in units of the underlying token.
        uint256 maximumExpectedValue;
        // The percent of credit that will be unlocked per block. The representation of this value is a 18  decimal
        // fixed point integer.
        uint256 creditUnlockRate;
        // The current balance of yield tokens which are held by users.
        uint256 activeBalance;
        // The current balance of yield tokens which are earmarked to be harvested by the system at a later time.
        uint256 harvestableBalance;
        // The total number of shares that have been minted for this token.
        uint256 totalShares;
        // The expected value of the tokens measured in underlying tokens. This value controls how much of the token
        // can be harvested. When users deposit yield tokens, it increases the expected value by how much the tokens
        // are exchangeable for in the underlying token. When users withdraw yield tokens, it decreases the expected
        // value by how much the tokens are exchangeable for in the underlying token.
        uint256 expectedValue;
        // The current amount of credit which is will be distributed over time to depositors.
        uint256 pendingCredit;
        // The amount of the pending credit that has been distributed.
        uint256 distributedCredit;
        // The block number which the last credit distribution occurred.
        uint256 lastDistributionBlock;
        // The total accrued weight. This is used to calculate how much credit a user has been granted over time. The
        // representation of this value is a 18 decimal fixed point integer.
        uint256 accruedWeight;
        // A flag to indicate if the token is enabled.
        bool enabled;
    }

    /// @notice Gets the address of the admin.
    ///
    /// @return admin The admin address.
    function admin() external view returns (address admin);

    /// @notice Gets the address of the pending administrator.
    ///
    /// @return pendingAdmin The pending administrator address.
    function pendingAdmin() external view returns (address pendingAdmin);

    /// @notice Gets the address of the transfer adapter.
    ///
    /// @return transferAdapter The transfer adapter address.
    function transferAdapter() external view returns (address transferAdapter);

    /// @notice Gets if an address is a sentinel.
    ///
    /// @param sentinel The address to check.
    ///
    /// @return isSentinel If the address is a sentinel.
    function sentinels(address sentinel) external view returns (bool isSentinel);

    /// @notice Gets if an address is a keeper.
    ///
    /// @param keeper The address to check.
    ///
    /// @return isKeeper If the address is a keeper
    function keepers(address keeper) external view returns (bool isKeeper);

    /// @notice Gets the address of the transmuter.
    ///
    /// @return transmuter The transmuter address.
    function transmuter() external view returns (address transmuter);

    /// @notice Gets the minimum collateralization.
    ///
    /// @notice Collateralization is determined by taking the total value of collateral that a user has deposited into their account and dividing it their debt.
    ///
    /// @dev The value returned is a 18 decimal fixed point integer.
    ///
    /// @return minimumCollateralization The minimum collateralization.
    function minimumCollateralization() external view returns (uint256 minimumCollateralization);

    /// @notice Gets the protocol fee.
    ///
    /// @return protocolFee The protocol fee.
    function protocolFee() external view returns (uint256 protocolFee);

    /// @notice Gets the protocol fee receiver.
    ///
    /// @return protocolFeeReceiver The protocol fee receiver.
    function protocolFeeReceiver() external view returns (address protocolFeeReceiver);

    /// @notice Gets the address of the whitelist contract.
    ///
    /// @return whitelist The address of the whitelist contract.
    function whitelist() external view returns (address whitelist);
    
    /// @notice Gets the conversion rate of underlying tokens per share.
    ///
    /// @param yieldToken The address of the yield token to get the conversion rate for.
    ///
    /// @return rate The rate of underlying tokens per share.
    function getUnderlyingTokensPerShare(address yieldToken) external view returns (uint256 rate);

    /// @notice Gets the conversion rate of yield tokens per share.
    ///
    /// @param yieldToken The address of the yield token to get the conversion rate for.
    ///
    /// @return rate The rate of yield tokens per share.
    function getYieldTokensPerShare(address yieldToken) external view returns (uint256 rate);

    /// @notice Gets the supported underlying tokens.
    ///
    /// @dev The order of the entries returned by this function is not guaranteed to be consistent between calls.
    ///
    /// @return tokens The supported underlying tokens.
    function getSupportedUnderlyingTokens() external view returns (address[] memory tokens);

    /// @notice Gets the supported yield tokens.
    ///
    /// @dev The order of the entries returned by this function is not guaranteed to be consistent between calls.
    ///
    /// @return tokens The supported yield tokens.
    function getSupportedYieldTokens() external view returns (address[] memory tokens);

    /// @notice Gets if an underlying token is supported.
    ///
    /// @param underlyingToken The address of the underlying token to check.
    ///
    /// @return isSupported If the underlying token is supported.
    function isSupportedUnderlyingToken(address underlyingToken) external view returns (bool isSupported);

    /// @notice Gets if a yield token is supported.
    ///
    /// @param yieldToken The address of the yield token to check.
    ///
    /// @return isSupported If the yield token is supported.
    function isSupportedYieldToken(address yieldToken) external view returns (bool isSupported);

    /// @notice Gets information about the account owned by `owner`.
    ///
    /// @param owner The address that owns the account.
    ///
    /// @return debt            The unrealized amount of debt that the account had incurred.
    /// @return depositedTokens The yield tokens that the owner has deposited.
    function accounts(address owner) external view returns (int256 debt, address[] memory depositedTokens);

    /// @notice Gets information about a yield token position for the account owned by `owner`.
    ///
    /// @param owner      The address that owns the account.
    /// @param yieldToken The address of the yield token to get the position of.
    ///
    /// @return shares            The amount of shares of that `owner` owns of the yield token.
    /// @return lastAccruedWeight The last recorded accrued weight of the yield token.
    function positions(address owner, address yieldToken)
        external view
        returns (
            uint256 shares,
            uint256 lastAccruedWeight
        );

    /// @notice Gets the amount of debt tokens `spender` is allowed to mint on behalf of `owner`.
    ///
    /// @param owner   The owner of the account.
    /// @param spender The address which is allowed to mint on behalf of `owner`.
    ///
    /// @return allowance The amount of debt tokens that `spender` can mint on behalf of `owner`.
    function mintAllowance(address owner, address spender) external view returns (uint256 allowance);

    /// @notice Gets the amount of shares of `yieldToken` that `spender` is allowed to withdraw on behalf of `owner`.
    ///
    /// @param owner      The owner of the account.
    /// @param spender    The address which is allowed to withdraw on behalf of `owner`.
    /// @param yieldToken The address of the yield token.
    ///
    /// @return allowance The amount of shares that `spender` can withdraw on behalf of `owner`.
    function withdrawAllowance(address owner, address spender, address yieldToken) external view returns (uint256 allowance);

    /// @notice Gets the parameters of an underlying token.
    ///
    /// @param underlyingToken The address of the underlying token.
    ///
    /// @return params The underlying token parameters.
    function getUnderlyingTokenParameters(address underlyingToken)
        external view
        returns (UnderlyingTokenParams memory params);

    /// @notice Get the parameters and state of a yield-token.
    ///
    /// @param yieldToken The address of the yield token.
    ///
    /// @return params The yield token parameters.
    function getYieldTokenParameters(address yieldToken)
        external view
        returns (YieldTokenParams memory params);

    /// @notice Gets current limit, maximum, and rate of the minting limiter.
    ///
    /// @return currentLimit The current amount of debt tokens that can be minted.
    /// @return rate         The maximum possible amount of tokens that can be liquidated at a time.
    /// @return maximum      The highest possible maximum amount of debt tokens that can be minted at a time.
    function getMintLimitInfo()
        external view
        returns (
            uint256 currentLimit,
            uint256 rate,
            uint256 maximum
        );

    /// @notice Gets current limit, maximum, and rate of a repay limiter for `underlyingToken`.
    ///
    /// @param underlyingToken The address of the underlying token.
    ///
    /// @return currentLimit The current amount of underlying tokens that can be repaid.
    /// @return rate         The rate at which the the current limit increases back to its maximum in tokens per block.
    /// @return maximum      The maximum possible amount of tokens that can be repaid at a time.
    function getRepayLimitInfo(address underlyingToken)
        external view
        returns (
            uint256 currentLimit,
            uint256 rate,
            uint256 maximum
        );

    /// @notice Gets current limit, maximum, and rate of the liquidation limiter for `underlyingToken`.
    ///
    /// @param underlyingToken The address of the underlying token.
    ///
    /// @return currentLimit The current amount of underlying tokens that can be liquidated.
    /// @return rate         The rate at which the function increases back to its maximum limit (tokens / block).
    /// @return maximum      The highest possible maximum amount of debt tokens that can be liquidated at a time.
    function getLiquidationLimitInfo(address underlyingToken)
        external view
        returns (
            uint256 currentLimit,
            uint256 rate,
            uint256 maximum
        );
}


// File src/interfaces/IAlchemistV2.sol

pragma solidity >=0.5.0;






/// @title  IAlchemistV2
/// @author Alchemix Finance
interface IAlchemistV2 is
    IAlchemistV2Actions,
    IAlchemistV2AdminActions,
    IAlchemistV2Errors,
    IAlchemistV2Immutables,
    IAlchemistV2Events,
    IAlchemistV2State
{ }


// File src/interfaces/keepers/IAlchemixHarvester.sol

pragma solidity ^0.8.13;

interface IAlchemixHarvester {
  function harvest(
    address alchemist,
    address yieldToken,
    uint256 minimumAmountOut,
    uint256 expectedExchange
  ) external;
}


// File src/interfaces/ITokenAdapter.sol

pragma solidity >=0.5.0;

/// @title  ITokenAdapter
/// @author Alchemix Finance
interface ITokenAdapter {
    /// @notice Gets the current version.
    ///
    /// @return The version.
    function version() external view returns (string memory);

    /// @notice Gets the address of the yield token that this adapter supports.
    ///
    /// @return The address of the yield token.
    function token() external view returns (address);

    /// @notice Gets the address of the underlying token that the yield token wraps.
    ///
    /// @return The address of the underlying token.
    function underlyingToken() external view returns (address);

    /// @notice Gets the number of underlying tokens that a single whole yield token is redeemable
    ///         for.
    ///
    /// @return The price.
    function price() external view returns (uint256);

    /// @notice Wraps `amount` underlying tokens into the yield token.
    ///
    /// @param amount    The amount of the underlying token to wrap.
    /// @param recipient The address which will receive the yield tokens.
    ///
    /// @return amountYieldTokens The amount of yield tokens minted to `recipient`.
    function wrap(uint256 amount, address recipient)
        external
        returns (uint256 amountYieldTokens);

    /// @notice Unwraps `amount` yield tokens into the underlying token.
    ///
    /// @param amount    The amount of yield-tokens to redeem.
    /// @param recipient The recipient of the resulting underlying-tokens.
    ///
    /// @return amountUnderlyingTokens The amount of underlying tokens unwrapped to `recipient`.
    function unwrap(uint256 amount, address recipient)
        external
        returns (uint256 amountUnderlyingTokens);
}


// File src/interfaces/external/vesper/IVesperRewards.sol


pragma solidity >=0.6.12;

interface IVesperRewards {
    function claimReward(address) external;

    function claimable(address) external view returns (address[] memory, uint256[] memory);

    function rewardTokens(uint256) external view returns (address);
}


// File src/interfaces/external/chainlink/IChainlinkOracle.sol

pragma solidity >= 0.6.6;

interface IChainlinkOracle {
  function latestAnswer() external view returns (int256);
  function latestTimestamp() external view returns (uint256);
  function latestRound() external view returns (uint256);
  function getAnswer(uint256 roundId) external view returns (int256);
  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);
  event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
}


// File src/interfaces/external/uniswap/IUniswapV3Factory.sol

pragma solidity >=0.5.0;

/// @title The interface for the Uniswap V3 Factory
/// @notice The Uniswap V3 Factory facilitates creation of Uniswap V3 pools and control over the protocol fees
interface IUniswapV3Factory {
    /// @notice Emitted when the owner of the factory is changed
    /// @param oldOwner The owner before the owner was changed
    /// @param newOwner The owner after the owner was changed
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);

    /// @notice Emitted when a pool is created
    /// @param token0 The first token of the pool by address sort order
    /// @param token1 The second token of the pool by address sort order
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks
    /// @param pool The address of the created pool
    event PoolCreated(
        address indexed token0,
        address indexed token1,
        uint24 indexed fee,
        int24 tickSpacing,
        address pool
    );

    /// @notice Emitted when a new fee amount is enabled for pool creation via the factory
    /// @param fee The enabled fee, denominated in hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks for pools created with the given fee
    event FeeAmountEnabled(uint24 indexed fee, int24 indexed tickSpacing);

    /// @notice Returns the current owner of the factory
    /// @dev Can be changed by the current owner via setOwner
    /// @return The address of the factory owner
    function owner() external view returns (address);

    /// @notice Returns the tick spacing for a given fee amount, if enabled, or 0 if not enabled
    /// @dev A fee amount can never be removed, so this value should be hard coded or cached in the calling context
    /// @param fee The enabled fee, denominated in hundredths of a bip. Returns 0 in case of unenabled fee
    /// @return The tick spacing
    function feeAmountTickSpacing(uint24 fee) external view returns (int24);

    /// @notice Returns the pool address for a given pair of tokens and a fee, or address 0 if it does not exist
    /// @dev tokenA and tokenB may be passed in either token0/token1 or token1/token0 order
    /// @param tokenA The contract address of either token0 or token1
    /// @param tokenB The contract address of the other token
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @return pool The pool address
    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view returns (address pool);

    /// @notice Creates a pool for the given two tokens and fee
    /// @param tokenA One of the two tokens in the desired pool
    /// @param tokenB The other of the two tokens in the desired pool
    /// @param fee The desired fee for the pool
    /// @dev tokenA and tokenB may be passed in either order: token0/token1 or token1/token0. tickSpacing is retrieved
    /// from the fee. The call will revert if the pool already exists, the fee is invalid, or the token arguments
    /// are invalid.
    /// @return pool The address of the newly created pool
    function createPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external returns (address pool);

    /// @notice Updates the owner of the factory
    /// @dev Must be called by the current owner
    /// @param _owner The new owner of the factory
    function setOwner(address _owner) external;

    /// @notice Enables a fee amount with the given tickSpacing
    /// @dev Fee amounts may never be removed once enabled
    /// @param fee The fee amount to enable, denominated in hundredths of a bip (i.e. 1e-6)
    /// @param tickSpacing The spacing between ticks to be enforced for all pools created with the given fee amount
    function enableFeeAmount(uint24 fee, int24 tickSpacing) external;
}


// File src/interfaces/external/uniswap/pool/IUniswapV3PoolState.sol

pragma solidity >=0.5.0;

/// @title Pool state that can change
/// @notice These methods compose the pool's state, and can change with any frequency including multiple times
/// per transaction
interface IUniswapV3PoolState {
    /// @notice The 0th storage slot in the pool stores many values, and is exposed as a single method to save gas
    /// when accessed externally.
    /// @return sqrtPriceX96 The current price of the pool as a sqrt(token1/token0) Q64.96 value
    /// tick The current tick of the pool, i.e. according to the last tick transition that was run.
    /// This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(sqrtPriceX96) if the price is on a tick
    /// boundary.
    /// observationIndex The index of the last oracle observation that was written,
    /// observationCardinality The current maximum number of observations stored in the pool,
    /// observationCardinalityNext The next maximum number of observations, to be updated when the observation.
    /// feeProtocol The protocol fee for both tokens of the pool.
    /// Encoded as two 4 bit values, where the protocol fee of token1 is shifted 4 bits and the protocol fee of token0
    /// is the lower 4 bits. Used as the denominator of a fraction of the swap fee, e.g. 4 means 1/4th of the swap fee.
    /// unlocked Whether the pool is currently locked to reentrancy
    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );

    /// @notice The fee growth as a Q128.128 fees of token0 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal0X128() external view returns (uint256);

    /// @notice The fee growth as a Q128.128 fees of token1 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal1X128() external view returns (uint256);

    /// @notice The amounts of token0 and token1 that are owed to the protocol
    /// @dev Protocol fees will never exceed uint128 max in either token
    function protocolFees() external view returns (uint128 token0, uint128 token1);

    /// @notice The currently in range liquidity available to the pool
    /// @dev This value has no relationship to the total liquidity across all ticks
    function liquidity() external view returns (uint128);

    /// @notice Look up information about a specific tick in the pool
    /// @param tick The tick to look up
    /// @return liquidityGross the total amount of position liquidity that uses the pool either as tick lower or
    /// tick upper,
    /// liquidityNet how much liquidity changes when the pool price crosses the tick,
    /// feeGrowthOutside0X128 the fee growth on the other side of the tick from the current tick in token0,
    /// feeGrowthOutside1X128 the fee growth on the other side of the tick from the current tick in token1,
    /// tickCumulativeOutside the cumulative tick value on the other side of the tick from the current tick
    /// secondsPerLiquidityOutsideX128 the seconds spent per liquidity on the other side of the tick from the current tick,
    /// secondsOutside the seconds spent on the other side of the tick from the current tick,
    /// initialized Set to true if the tick is initialized, i.e. liquidityGross is greater than 0, otherwise equal to false.
    /// Outside values can only be used if the tick is initialized, i.e. if liquidityGross is greater than 0.
    /// In addition, these values are only relative and must be used only in comparison to previous snapshots for
    /// a specific position.
    function ticks(int24 tick)
        external
        view
        returns (
            uint128 liquidityGross,
            int128 liquidityNet,
            uint256 feeGrowthOutside0X128,
            uint256 feeGrowthOutside1X128,
            int56 tickCumulativeOutside,
            uint160 secondsPerLiquidityOutsideX128,
            uint32 secondsOutside,
            bool initialized
        );

    /// @notice Returns 256 packed tick initialized boolean values. See TickBitmap for more information
    function tickBitmap(int16 wordPosition) external view returns (uint256);

    /// @notice Returns the information about a position by the position's key
    /// @param key The position's key is a hash of a preimage composed by the owner, tickLower and tickUpper
    /// @return _liquidity The amount of liquidity in the position,
    /// Returns feeGrowthInside0LastX128 fee growth of token0 inside the tick range as of the last mint/burn/poke,
    /// Returns feeGrowthInside1LastX128 fee growth of token1 inside the tick range as of the last mint/burn/poke,
    /// Returns tokensOwed0 the computed amount of token0 owed to the position as of the last mint/burn/poke,
    /// Returns tokensOwed1 the computed amount of token1 owed to the position as of the last mint/burn/poke
    function positions(bytes32 key)
        external
        view
        returns (
            uint128 _liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    /// @notice Returns data about a specific observation index
    /// @param index The element of the observations array to fetch
    /// @dev You most likely want to use #observe() instead of this method to get an observation as of some amount of time
    /// ago, rather than at a specific index in the array.
    /// @return blockTimestamp The timestamp of the observation,
    /// Returns tickCumulative the tick multiplied by seconds elapsed for the life of the pool as of the observation timestamp,
    /// Returns secondsPerLiquidityCumulativeX128 the seconds per in range liquidity for the life of the pool as of the observation timestamp,
    /// Returns initialized whether the observation has been initialized and the values are safe to use
    function observations(uint256 index)
        external
        view
        returns (
            uint32 blockTimestamp,
            int56 tickCumulative,
            uint160 secondsPerLiquidityCumulativeX128,
            bool initialized
        );
}


// File src/interfaces/external/uniswap/IUniswapV3Pool.sol

pragma solidity >=0.5.0;

// import './pool/IUniswapV3PoolImmutables.sol';

// import './pool/IUniswapV3PoolDerivedState.sol';
// import './pool/IUniswapV3PoolActions.sol';
// import './pool/IUniswapV3PoolOwnerActions.sol';
// import './pool/IUniswapV3PoolEvents.sol';

/// @title The interface for a Uniswap V3 Pool
/// @notice A Uniswap pool facilitates swapping and automated market making between any two assets that strictly conform
/// to the ERC20 specification
/// @dev The pool interface is broken up into many smaller pieces
interface IUniswapV3Pool is
    // IUniswapV3PoolImmutables,
    IUniswapV3PoolState
    // IUniswapV3PoolDerivedState,
    // IUniswapV3PoolActions,
    // IUniswapV3PoolOwnerActions,
    // IUniswapV3PoolEvents
{

}


// File src/utils/UniswapEstimatedPrice.sol

pragma solidity ^0.8.13;


/// @title  UniswapEstimatedPrice
/// @author Alchemix Finance
contract UniswapEstimatedPrice {
    // Set `token2` == 0 address for only one swap
    function getExpectedExchange(address factory, address token0, address token1, uint24 fee0, address token2, uint24 fee1, uint256 amount) external returns (uint256) {
        IUniswapV3Factory uniswapFactory = IUniswapV3Factory(factory);

        IUniswapV3Pool pool = IUniswapV3Pool(uniswapFactory.getPool(token0, token1, fee0));
        (uint160 sqrtPriceX96,,,,,,) =  pool.slot0();
        uint256 price0 = uint(sqrtPriceX96) * (uint(sqrtPriceX96)) * (1e18) >> (96 * 2);

        if (token2 == address(0)) return amount * price0 / 1e18;

        pool = IUniswapV3Pool(uniswapFactory.getPool(token1, token2, fee1));
        ( sqrtPriceX96,,,,,,) =  pool.slot0();
        uint256 price1 = uint(sqrtPriceX96) * (uint(sqrtPriceX96)) * (1e18) >> (96 * 2);

        return amount * price0 / price1;
    }
}


// File lib/openzeppelin-contracts/contracts/utils/Context.sol

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


// File lib/openzeppelin-contracts/contracts/access/Ownable.sol

// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


// File lib/openzeppelin-contracts/contracts/utils/math/SafeMath.sol

// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}


// File src/base/Errors.sol

pragma solidity ^0.8.13;

/// @notice An error used to indicate that an action could not be completed because either the `msg.sender` or
///         `msg.origin` is not authorized.
error Unauthorized();

/// @notice An error used to indicate that an action could not be completed because the contract either already existed
///         or entered an illegal condition which is not recoverable from.
error IllegalState();

/// @notice An error used to indicate that an action could not be completed because of an illegal argument was passed
///         to the function.
error IllegalArgument();


// File src/libraries/SafeCast.sol

pragma solidity >=0.5.0;

/// @title Safe casting methods
/// @notice Contains methods for safely casting between types
library SafeCast {
  /// @notice Cast a uint256 to a int256, revert on overflow
  /// @param y The uint256 to be casted
  /// @return z The casted integer, now type int256
  function toInt256(uint256 y) internal pure returns (int256 z) {
    if (y >= 2**255) {
      revert IllegalArgument();
    }
    z = int256(y);
  }

  /// @notice Cast a int256 to a uint256, revert on underflow
  /// @param y The int256 to be casted
  /// @return z The casted integer, now type uint256
  function toUint256(int256 y) internal pure returns (uint256 z) {
    if (y < 0) {
      revert IllegalArgument();
    }
    z = uint256(y);
  }
}


// File src/keepers/HarvestResolver.sol

pragma solidity ^0.8.13;
















contract HarvestResolver is IResolver, Ownable {
  address constant alUsdOptimism = 0xCB8FA9a76b8e203D8C3797bF438d8FB81Ea3326A;
  address constant alEthOptimism = 0x3E29D3A9316dAB217754d13b28646B76607c5f04;
  address constant ethAlchemistAddress = 0x062Bf725dC4cDF947aa79Ca2aaCCD4F385b13b5c;
  address constant usdAlchemistAddress = 0x5C6374a2ac4EBC38DeA0Fc1F8716e5Ea1AdD94dd;
  address constant dai = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
  address constant opRewardsController = 0x929EC64c34a17401F460460D4B9390518E5B473e;
  address constant opToUsdOracle = 0x0D276FC14719f9292D5C1eA2198673d1f4269246;
  address constant ethToUsdOracle = 0x13e3Ee699D1909E989722E753853AE30b17e08c5;
  address constant uniswapFactory = 0x1F98431c8aD98523631AE4a59f267346ea31F984;
  address constant wethAddress = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
  address constant vaDAI = 0x0538C8bAc84E95A9dF8aC10Aad17DbE81b9E36ee;
  address constant vaUSDC = 0xa8b607Aa09B6A2E306F93e74c282Fb13f6A80452;
  address constant vaETH = 0xd1C117319B3595fbc39b471AB1fd485629eb05F2;
  address constant vesperRewardsDai = 0x35864296944119F72AA1B468e13449222f3f0E67;
  address constant vesperRewardsUsdc = 0x2F59B0F98A08E733C66dFB42Bd8E366dC2cfedA6;
  address constant vesperRewardsEth = 0x2F59B0F98A08E733C66dFB42Bd8E366dC2cfedA6;
  address constant vspRewardToken = 0x1b40183EFB4Dd766f11bDa7A7c3AD8982e998421;

  /// @notice Thrown when the yield token of a harvest job being added is disabled in the alchemist of the harvest job being added.
  error YieldTokenDisabled();
  /// @notice Thrown when attempting to remove a harvest job that does not currently exist.
  error HarvestJobDoesNotExist();

  /// @notice Emitted when details of a harvest job are set.
  event SetHarvestJob(
    bool active,
    address alchemist,
    address reward,
    address yieldToken,
    uint256 minimumHarvestAmount,
    uint256 minimumDelay,
    uint256 slippageBps
  );
  /// @notice Emitted when a harvester status is updated.
  event SetHarvester(address harvester, bool status);

  /// @notice Emitted when a harvest job is removed from the list.
  event RemoveHarvestJob(address yieldToken);

  /// @notice Emitted when a harvest is recorded.
  event RecordHarvest(address yieldToken);

  struct HarvestJob {
    bool active;
    address alchemist;
    address reward;
    address yieldToken;
    uint256 lastHarvest;
    uint256 minimumHarvestAmount;
    uint256 minimumDelay;
    uint256 slippageBps;
  }

  uint256 public constant SLIPPAGE_PRECISION = 10000;

  /// @dev The list of yield tokens that define harvest jobs.
  address[] public yieldTokens;

  /// @dev yieldToken => HarvestJob.
  mapping(address => HarvestJob) public harvestJobs;

  /// @dev Whether or not the resolver is paused.
  bool public paused;

  /// @dev A mapping of the registered harvesters.
  mapping(address => bool) public harvesters;

  constructor() Ownable() {}

  modifier onlyHarvester() {
    if (!harvesters[msg.sender]) {
      revert Unauthorized();
    }
    _;
  }

  /// @notice Enables or disables a harvester from calling protected harvester-only functions.
  ///
  /// @param harvester The address of the target harvester.
  /// @param status The status to set for the target harvester.
  function setHarvester(address harvester, bool status) external onlyOwner {
    harvesters[harvester] = status;
    emit SetHarvester(harvester, status);
  }

  /// @notice Pauses and un-pauses the resolver.
  ///
  /// @param pauseState The pause state to set.
  function setPause(bool pauseState) external onlyOwner {
    paused = pauseState;
  }

  /// @notice Remove tokens that were accidentally sent to the resolver.
  ///
  /// @param token The token to remove.
  function recoverFunds(address token) external onlyOwner {
    IERC20(token).transfer(msg.sender, IERC20(token).balanceOf(address(this)));
  }

  /// @notice Sets the parameters of a harvest job and adds it to the list if needed.
  ///
  /// @param active               A flag for whether or not the harvest job is active.
  /// @param alchemist            The address of the alchemist to be harvested.
  /// @param reward               Address of the reward token. 0 for none.
  /// @param yieldToken           The address of the yield token to be harvested.
  /// @param minimumHarvestAmount The minimum amount of harvestable funds required in order to run the harvest job.
  /// @param minimumDelay         The minimum delay (in seconds) needed between successive runs of the job.
  function addHarvestJob(
    bool active,
    address alchemist,
    address reward,
    address yieldToken,
    uint256 minimumHarvestAmount,
    uint256 minimumDelay,
    uint256 slippageBps
  ) external onlyOwner {
    IAlchemistV2.YieldTokenParams memory ytp = IAlchemistV2(alchemist).getYieldTokenParameters(yieldToken);
    if (!ytp.enabled) {
      revert YieldTokenDisabled();
    }

    if (slippageBps > SLIPPAGE_PRECISION) {
      revert IllegalArgument();
    }

    harvestJobs[yieldToken] = HarvestJob(
      active,
      alchemist,
      reward,
      yieldToken,
      block.timestamp,
      minimumHarvestAmount,
      minimumDelay,
      slippageBps
    );

    emit SetHarvestJob(active, alchemist, reward, yieldToken, minimumHarvestAmount, minimumDelay, slippageBps);

    // Only add the yield token to the list if it doesnt exist yet.
    for (uint256 i = 0; i < yieldTokens.length; i++) {
      if (yieldTokens[i] == yieldToken) {
        return;
      }
    }
    yieldTokens.push(yieldToken);
  }

  /// @notice Sets if a harvest job is active.
  ///
  /// @param yieldToken   The address of the yield token to be harvested.
  /// @param active       A flag for whether or not the harvest job is active.
  function setActive(address yieldToken, bool active) external onlyOwner {
    harvestJobs[yieldToken].active = active;
  }

  /// @notice Sets the alchemist of a harvest job.
  ///
  /// @param yieldToken   The address of the yield token to be harvested.
  /// @param alchemist    The address of the alchemist to be harvested.
  function setAlchemist(address yieldToken, address alchemist) external onlyOwner {
    IAlchemistV2.YieldTokenParams memory ytp = IAlchemistV2(alchemist).getYieldTokenParameters(yieldToken);
    if (!ytp.enabled) {
      revert YieldTokenDisabled();
    }
    harvestJobs[yieldToken].alchemist = alchemist;
  }

  /// @notice Sets the minimum harvest amount of a harvest job.
  ///
  /// @param yieldToken           The address of the yield token to be harvested.
  /// @param minimumHarvestAmount The minimum amount of harvestable funds required in order to run the harvest job.
  function setMinimumHarvestAmount(address yieldToken, uint256 minimumHarvestAmount) external onlyOwner {
    harvestJobs[yieldToken].minimumHarvestAmount = minimumHarvestAmount;
  }

  /// @notice Sets the minimum delay of a harvest job.
  ///
  /// @param yieldToken   The address of the yield token to be harvested.
  /// @param minimumDelay The minimum delay (in seconds) needed between successive runs of the job.
  function setMinimumDelay(address yieldToken, uint256 minimumDelay) external onlyOwner {
    harvestJobs[yieldToken].minimumDelay = minimumDelay;
  }

  /// @notice Sets the amount of slippage for a harvest job.
  ///
  /// @param yieldToken   The address of the yield token to be harvested.
  /// @param slippageBps  The amount of slippage to accept during a harvest.
  function setSlippageBps(address yieldToken, uint256 slippageBps) external onlyOwner {
    harvestJobs[yieldToken].slippageBps = slippageBps;
  }

  /// @notice Removes a harvest job from the list of harvest jobs.
  ///
  /// @param yieldToken The address of the yield token to remove.
  function removeHarvestJob(address yieldToken) external onlyOwner {
    int256 idx = -1;
    for (uint256 i = 0; i < yieldTokens.length; i++) {
      if (yieldTokens[i] == yieldToken) {
        idx = SafeCast.toInt256(i);
      }
    }
    if (idx > -1) {
      delete harvestJobs[yieldToken];
      yieldTokens[SafeCast.toUint256(idx)] = yieldTokens[yieldTokens.length - 1];
      yieldTokens.pop();
      emit RemoveHarvestJob(yieldToken);
    } else {
      revert HarvestJobDoesNotExist();
    }
  }

  /// @notice Check if there is a harvest that needs to be run.
  ///
  /// Returns FALSE if the resolver is paused.
  /// Returns TRUE for the first harvest job that meets the following criteria:
  ///     - the harvest job is active
  ///     - `yieldToken` is enabled in the Alchemist
  ///     - minimumDelay seconds have passed since the `yieldToken` was last harvested
  ///     - the expected harvest amount is greater than minimumHarvestAmount
  /// Returns FALSE if no harvest jobs meet the above criteria.
  ///
  /// @return canExec     If a harvest is needed
  /// @return execPayload The payload to forward to the AlchemixHarvester
  function checker() external view returns (bool canExec, bytes memory execPayload) {
    if (paused) {
      return (false, abi.encode(0));
    }

    for (uint256 i = 0; i < yieldTokens.length; i++) {
      address yieldToken = yieldTokens[i];
      HarvestJob memory h = harvestJobs[yieldToken];
      if (h.active) {
        IAlchemistV2.YieldTokenParams memory ytp = IAlchemistV2(h.alchemist).getYieldTokenParameters(yieldToken);

        if (ytp.enabled) {
          uint256 pps = ITokenAdapter(ytp.adapter).price();
          uint256 currentValue = ((ytp.activeBalance + ytp.harvestableBalance) * pps) / 10**ytp.decimals;
          if (
            (block.timestamp >= h.lastHarvest + h.minimumDelay) &&
            (currentValue > ytp.expectedValue + h.minimumHarvestAmount)
          ) {
            uint256 minimumAmountOut = currentValue - ytp.expectedValue;
            minimumAmountOut = minimumAmountOut - (minimumAmountOut * h.slippageBps) / SLIPPAGE_PRECISION;

            uint256 expectedExchange;

            // If vault has rewards to be collected
            if (h.reward == vspRewardToken) {
              // alUSD route for vesper swap
              if (h.alchemist == usdAlchemistAddress) {
                if (h.yieldToken == vaDAI) {
                  (address[] memory tokens, uint256[] memory amounts) = IVesperRewards(vesperRewardsDai).claimable(usdAlchemistAddress);
                  expectedExchange = _getExpectedExchange(uniswapFactory, h.reward, wethAddress, uint24(3000), dai, uint24(3000), amounts[0]);
                } else if (h.yieldToken == vaUSDC) {
                  (address[] memory tokens, uint256[] memory amounts) = IVesperRewards(vesperRewardsUsdc).claimable(usdAlchemistAddress);
                  expectedExchange = _getExpectedExchange(uniswapFactory, h.reward, wethAddress, uint24(3000), dai, uint24(3000), amounts[0]);
                }
              // alETH route for vesper swap
              } else if (h.alchemist == ethAlchemistAddress) {
                (address[] memory tokens, uint256[] memory amounts) = IVesperRewards(vesperRewardsEth).claimable(ethAlchemistAddress);
                expectedExchange = _getExpectedExchange(uniswapFactory, h.reward, wethAddress, uint24(3000), address(0), uint24(0), amounts[0]);
              }
              return (
                true,
                abi.encodeWithSelector(IAlchemixHarvester.harvest.selector, h.alchemist, yieldToken, minimumAmountOut, expectedExchange * 9900 / 10000)
              );
            }

            // If reward is not the address of a token then it is the address of a reward collector.
            // We can assume that this is optimism and handle rewards accordingly.
            if (h.reward != address(0)) {
              address[] memory token = new address[](1);
              token[0] = address(IStaticAToken(h.yieldToken).ATOKEN());
              uint256 claimable = IRewardsController(opRewardsController).getUserRewards(token, yieldToken, IRewardCollector(h.reward).rewardToken());
              // Find expected amount out before calling harvest
              if (IRewardCollector(h.reward).debtToken() == alUsdOptimism) {
                expectedExchange = claimable * uint(IChainlinkOracle(opToUsdOracle).latestAnswer()) / 1e8;
              } else if (IRewardCollector(h.reward).debtToken() == alEthOptimism) {
                expectedExchange = claimable * uint(IChainlinkOracle(opToUsdOracle).latestAnswer()) / uint(IChainlinkOracle(ethToUsdOracle).latestAnswer());
              } else {
                  revert IllegalState();
              }
              return (
                true,
                abi.encodeWithSelector(IAlchemixHarvester.harvest.selector, h.alchemist, yieldToken, minimumAmountOut, expectedExchange * 9900 / 10000)
              );
            // If reward equals the 0 address then we handle the harvest without rewards.
            } else {
              return (
                true,
                abi.encodeWithSelector(IAlchemixHarvester.harvest.selector, h.alchemist, yieldToken, minimumAmountOut, 0)
              );
            }
          }
        }
      }
    }
    return (false, abi.encode(0));
  }
  
  // Get expected exchange from reward token to debt token.
  function _getExpectedExchange(address factory, address token0, address token1, uint24 fee0, address token2, uint24 fee1, uint256 amount) internal view returns (uint256) {
      IUniswapV3Factory uniswapFactory = IUniswapV3Factory(factory);

      IUniswapV3Pool pool = IUniswapV3Pool(uniswapFactory.getPool(token0, token1, fee0));
      (uint160 sqrtPriceX96,,,,,,) =  pool.slot0();
      uint256 price0 = uint(sqrtPriceX96) * (uint(sqrtPriceX96)) * (1e18) >> (96 * 2);

      if (token2 == address(0)) return amount * price0 / 1e18;

      pool = IUniswapV3Pool(uniswapFactory.getPool(token1, token2, fee1));
      ( sqrtPriceX96,,,,,,) =  pool.slot0();
      uint256 price1 = uint(sqrtPriceX96) * (uint(sqrtPriceX96)) * (1e18) >> (96 * 2);

      return amount * price0 / price1;
  }

  function recordHarvest(address yieldToken) external onlyHarvester {
    harvestJobs[yieldToken].lastHarvest = block.timestamp;
    emit RecordHarvest(yieldToken);
  }
}