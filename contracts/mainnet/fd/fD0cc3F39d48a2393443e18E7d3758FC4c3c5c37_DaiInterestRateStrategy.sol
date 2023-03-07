// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

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

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {DataTypes} from '../protocol/libraries/types/DataTypes.sol';

/**
 * @title IReserveInterestRateStrategy
 * @author Aave
 * @notice Interface for the calculation of the interest rates
 */
interface IReserveInterestRateStrategy {
  /**
   * @notice Calculates the interest rates depending on the reserve's state and configurations
   * @param params The parameters needed to calculate interest rates
   * @return liquidityRate The liquidity rate expressed in rays
   * @return stableBorrowRate The stable borrow rate expressed in rays
   * @return variableBorrowRate The variable borrow rate expressed in rays
   */
  function calculateInterestRates(DataTypes.CalculateInterestRatesParams memory params)
    external
    view
    returns (
      uint256,
      uint256,
      uint256
    );
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

library DataTypes {
  struct ReserveData {
    //stores the reserve configuration
    ReserveConfigurationMap configuration;
    //the liquidity index. Expressed in ray
    uint128 liquidityIndex;
    //the current supply rate. Expressed in ray
    uint128 currentLiquidityRate;
    //variable borrow index. Expressed in ray
    uint128 variableBorrowIndex;
    //the current variable borrow rate. Expressed in ray
    uint128 currentVariableBorrowRate;
    //the current stable borrow rate. Expressed in ray
    uint128 currentStableBorrowRate;
    //timestamp of last update
    uint40 lastUpdateTimestamp;
    //the id of the reserve. Represents the position in the list of the active reserves
    uint16 id;
    //aToken address
    address aTokenAddress;
    //stableDebtToken address
    address stableDebtTokenAddress;
    //variableDebtToken address
    address variableDebtTokenAddress;
    //address of the interest rate strategy
    address interestRateStrategyAddress;
    //the current treasury balance, scaled
    uint128 accruedToTreasury;
    //the outstanding unbacked aTokens minted through the bridging feature
    uint128 unbacked;
    //the outstanding debt borrowed against this asset in isolation mode
    uint128 isolationModeTotalDebt;
  }

  struct ReserveConfigurationMap {
    //bit 0-15: LTV
    //bit 16-31: Liq. threshold
    //bit 32-47: Liq. bonus
    //bit 48-55: Decimals
    //bit 56: reserve is active
    //bit 57: reserve is frozen
    //bit 58: borrowing is enabled
    //bit 59: stable rate borrowing enabled
    //bit 60: asset is paused
    //bit 61: borrowing in isolation mode is enabled
    //bit 62-63: reserved
    //bit 64-79: reserve factor
    //bit 80-115 borrow cap in whole tokens, borrowCap == 0 => no cap
    //bit 116-151 supply cap in whole tokens, supplyCap == 0 => no cap
    //bit 152-167 liquidation protocol fee
    //bit 168-175 eMode category
    //bit 176-211 unbacked mint cap in whole tokens, unbackedMintCap == 0 => minting disabled
    //bit 212-251 debt ceiling for isolation mode with (ReserveConfiguration::DEBT_CEILING_DECIMALS) decimals
    //bit 252-255 unused

    uint256 data;
  }

  struct UserConfigurationMap {
    /**
     * @dev Bitmap of the users collaterals and borrows. It is divided in pairs of bits, one pair per asset.
     * The first bit indicates if an asset is used as collateral by the user, the second whether an
     * asset is borrowed by the user.
     */
    uint256 data;
  }

  struct EModeCategory {
    // each eMode category has a custom ltv and liquidation threshold
    uint16 ltv;
    uint16 liquidationThreshold;
    uint16 liquidationBonus;
    // each eMode category may or may not have a custom oracle to override the individual assets price oracles
    address priceSource;
    string label;
  }

  enum InterestRateMode {
    NONE,
    STABLE,
    VARIABLE
  }

  struct ReserveCache {
    uint256 currScaledVariableDebt;
    uint256 nextScaledVariableDebt;
    uint256 currPrincipalStableDebt;
    uint256 currAvgStableBorrowRate;
    uint256 currTotalStableDebt;
    uint256 nextAvgStableBorrowRate;
    uint256 nextTotalStableDebt;
    uint256 currLiquidityIndex;
    uint256 nextLiquidityIndex;
    uint256 currVariableBorrowIndex;
    uint256 nextVariableBorrowIndex;
    uint256 currLiquidityRate;
    uint256 currVariableBorrowRate;
    uint256 reserveFactor;
    ReserveConfigurationMap reserveConfiguration;
    address aTokenAddress;
    address stableDebtTokenAddress;
    address variableDebtTokenAddress;
    uint40 reserveLastUpdateTimestamp;
    uint40 stableDebtLastUpdateTimestamp;
  }

  struct ExecuteLiquidationCallParams {
    uint256 reservesCount;
    uint256 debtToCover;
    address collateralAsset;
    address debtAsset;
    address user;
    bool receiveAToken;
    address priceOracle;
    uint8 userEModeCategory;
    address priceOracleSentinel;
  }

  struct ExecuteSupplyParams {
    address asset;
    uint256 amount;
    address onBehalfOf;
    uint16 referralCode;
  }

  struct ExecuteBorrowParams {
    address asset;
    address user;
    address onBehalfOf;
    uint256 amount;
    InterestRateMode interestRateMode;
    uint16 referralCode;
    bool releaseUnderlying;
    uint256 maxStableRateBorrowSizePercent;
    uint256 reservesCount;
    address oracle;
    uint8 userEModeCategory;
    address priceOracleSentinel;
  }

  struct ExecuteRepayParams {
    address asset;
    uint256 amount;
    InterestRateMode interestRateMode;
    address onBehalfOf;
    bool useATokens;
  }

  struct ExecuteWithdrawParams {
    address asset;
    uint256 amount;
    address to;
    uint256 reservesCount;
    address oracle;
    uint8 userEModeCategory;
  }

  struct ExecuteSetUserEModeParams {
    uint256 reservesCount;
    address oracle;
    uint8 categoryId;
  }

  struct FinalizeTransferParams {
    address asset;
    address from;
    address to;
    uint256 amount;
    uint256 balanceFromBefore;
    uint256 balanceToBefore;
    uint256 reservesCount;
    address oracle;
    uint8 fromEModeCategory;
  }

  struct FlashloanParams {
    address receiverAddress;
    address[] assets;
    uint256[] amounts;
    uint256[] interestRateModes;
    address onBehalfOf;
    bytes params;
    uint16 referralCode;
    uint256 flashLoanPremiumToProtocol;
    uint256 flashLoanPremiumTotal;
    uint256 maxStableRateBorrowSizePercent;
    uint256 reservesCount;
    address addressesProvider;
    uint8 userEModeCategory;
    bool isAuthorizedFlashBorrower;
  }

  struct FlashloanSimpleParams {
    address receiverAddress;
    address asset;
    uint256 amount;
    bytes params;
    uint16 referralCode;
    uint256 flashLoanPremiumToProtocol;
    uint256 flashLoanPremiumTotal;
  }

  struct FlashLoanRepaymentParams {
    uint256 amount;
    uint256 totalPremium;
    uint256 flashLoanPremiumToProtocol;
    address asset;
    address receiverAddress;
    uint16 referralCode;
  }

  struct CalculateUserAccountDataParams {
    UserConfigurationMap userConfig;
    uint256 reservesCount;
    address user;
    address oracle;
    uint8 userEModeCategory;
  }

  struct ValidateBorrowParams {
    ReserveCache reserveCache;
    UserConfigurationMap userConfig;
    address asset;
    address userAddress;
    uint256 amount;
    InterestRateMode interestRateMode;
    uint256 maxStableLoanPercent;
    uint256 reservesCount;
    address oracle;
    uint8 userEModeCategory;
    address priceOracleSentinel;
    bool isolationModeActive;
    address isolationModeCollateralAddress;
    uint256 isolationModeDebtCeiling;
  }

  struct ValidateLiquidationCallParams {
    ReserveCache debtReserveCache;
    uint256 totalDebt;
    uint256 healthFactor;
    address priceOracleSentinel;
  }

  struct CalculateInterestRatesParams {
    uint256 unbacked;
    uint256 liquidityAdded;
    uint256 liquidityTaken;
    uint256 totalStableDebt;
    uint256 totalVariableDebt;
    uint256 averageStableBorrowRate;
    uint256 reserveFactor;
    address reserve;
    address aToken;
  }

  struct InitReserveParams {
    address asset;
    address aTokenAddress;
    address stableDebtAddress;
    address variableDebtAddress;
    address interestRateStrategyAddress;
    uint16 reservesCount;
    uint16 maxNumberReserves;
  }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import {IERC20} from 'aave-v3-core/contracts/dependencies/openzeppelin/contracts/IERC20.sol';
import {IReserveInterestRateStrategy} from 'aave-v3-core/contracts/interfaces/IReserveInterestRateStrategy.sol';
import {DataTypes} from 'aave-v3-core/contracts/protocol/libraries/types/DataTypes.sol';

interface VatLike {
    function ilks(bytes32) external view returns (uint256, uint256, uint256, uint256, uint256);
}

interface PotLike {
    function dsr() external view returns (uint256);
}

/**
 * @title DaiInterestRateStrategy
 * @notice Flat interest rate curve which is a spread on the Stability Fee Base Rate unless Maker needs liquidity.
 * @dev The interest rate strategy is intended to be used by Spark Lend pool that is supplied by a D3M implementation. Further, is implemented for DAI so that a D3M implementation for the Spark Lend protocol should be able to unwind as fast as possible in case of debt limit changes downwards by incentivizing borrowers and lenders to move DAI into the protocol. Hence, it operates in two modes. Namely, it distinguishes the unhealthy scenario, where the D3M supplied too much (the Spark Lend D3M ink's debt exceeds the debt limit), from the healthy one, where the D3M is healthy.
 * 
 * Note that the base rate conversion, maximum rate and the borrow and supply spreads are constants, while the DSR rate is queried from Maker's Pot contract. The base rate is defined as:
 * 
 * ```
 * Rbase = min(Rdsr * baseRateConversion, Rmax − RborrowSpread)
 * ```
 * 
 * Meaning, that the sum of the base rate and the borrow spread cannot exceed the maximum rate.
 * 
 * Assume the D3M is healthy. The borrow rate is a constant defined as the Dai Savings Rate plus a borrow spread. While the borrowed amount is below a certain performance value, the supply rate is set to zero. Once the borrowed amount reaches the performance value, the supply rate is computed as the Dai Savings Rate plus a supply spread, multiplied with the ratio of the amount, that went over the premium and the total liquidity (borrows + available capital) in the pool. Hence, the rates can be described as follows:
 * 
 * ```
 * Rborrow = Rbase + RborrowSpread
 * Rsupply = (Rbase + RsupplySpread) * max(0, Cborrowed − Cperformance) / (Cborrowed + Cavailable)
 * ```
 * 
 * Note it yields that the borrow rate is always constant. Further, suppliers are only incentivized to supply capital after a minimum borrow amount is reached. During the times, as the third-party suppliers are not incentivized, we expect that the D3M provides sufficient DAI for the lending market. However, once the protocol makes sufficient profits, it will incentivize third party suppliers (as the D3M will have a certain debt limit).
 * 
 * In case the D3M is unhealthy, meaning that the debt is higher than the debt limit, the D3M will try to wind down. In that scenario, the interest rate strategy will try to incentivize borrowers to pay back their debt, and will try to incentivize suppliers to start lending DAI. Hence, the borrow and supply rate will increase according to the debt ratio of the D3M. More specifically, the rates are defined as:
 * 
 * ```
 * Rborrow = Rmax − (Rmax − (rbase + rborrowSpread)) / debtRatio
 * Rsupply = (Cborrowed / (Cborrowed + Cavailable)) * Rborrow
 * ```
 * 
 * Note, that if the debt ratio increases, the borrow rate increases as a negated inverse function (starting at the regular borrowing rate). Similarly, the supply rate will increase in terms of the debt ratio, however, scaled by the utilization ratio. Thus, the higher the utilization, the closer will the supply rate be to the borrow rate. Ultimately, that leads to the protocol forfeiting potential revenue by sharing it with third-party supplier to incentivize the D3M's stabilization. Note that the stable borrow rate is always 0.
 * 
 * The interest rate definition described above is implemented in calculateInterestRates(). However, note that the debt ratio and the base rate are both not queried on every interest rate calculation; but, retrieved from a cache (as these will not change often). The variables can be recomputed with function recompute() that sets the base rate to the current Dai Savings Rate and computes the debt ratio as the ratio of the current Ilk.Art and current Ilk.line. It is assumed that the recomputation is triggered on a regular basis.
 * 
 * Only supports variable interest pool.
 */
contract DaiInterestRateStrategy is IReserveInterestRateStrategy {

    struct Slot0 {
        // The ratio of outstanding debt to debt ceiling in the vault. Expressed in wad
        uint88 debtRatio;
        // The base rate of the reserve. Expressed in ray
        uint128 baseRate;
        // Timestamp of last update
        uint40 lastUpdateTimestamp;
    }

    uint256 private constant HWAD = 10 ** 9;
    uint256 private constant WAD = 10 ** 18;
    uint256 private constant RAY = 10 ** 27;
    uint256 private constant RAD = 10 ** 45;
    uint256 private constant SECONDS_PER_YEAR = 365 days;

    address public immutable vat;
    address public immutable pot;
    bytes32 public immutable ilk;
    uint256 public immutable baseRateConversion;
    uint256 public immutable borrowSpread;
    uint256 public immutable supplySpread;
    uint256 public immutable maxRate;
    uint256 public immutable performanceBonus;

    Slot0 private _slot0;

    /**
     * @param _vat The address of the vat contract
     * @param _pot The address of the pot contract
     * @param _ilk The ilk identifier
     * @param _baseRateConversion Convert Dai Savings Rate to the Stability Fee Base Rate (SFBR) as a RAY unit
     * @param _borrowSpread The borrow spread on top of the SFBR as an APR in RAY units
     * @param _supplySpread The supply spread on top of the SFBR as an APR in RAY units
     * @param _maxRate The maximum rate that can be returned by this strategy in RAY units
     * @param _performanceBonus The first part of the interest earned on the debt goes to the reserve as a performance bonus in WAD units.
     */
    constructor(
        address _vat,
        address _pot,
        bytes32 _ilk,
        uint256 _baseRateConversion,
        uint256 _borrowSpread,
        uint256 _supplySpread,
        uint256 _maxRate,
        uint256 _performanceBonus
    ) {
        require(_borrowSpread >= _supplySpread, "DaiInterestRateStrategy/supply-spread-greater-than-borrow-spread");
        require(_maxRate >= _borrowSpread, "DaiInterestRateStrategy/borrow-spread-too-large");

        vat = _vat;
        pot = _pot;
        ilk = _ilk;
        baseRateConversion = _baseRateConversion;
        borrowSpread = _borrowSpread;
        supplySpread = _supplySpread;
        maxRate = _maxRate;
        performanceBonus = _performanceBonus;

        recompute();
    }

    /**
    * @notice Fetch debt ceiling and dsr. Expensive operation should be called only when underlying values change.
    * @dev This incurs a lot of SLOADs and infrequently changes. No need to call this on every calculation.
    */
    function recompute() public {
        (uint256 Art,,, uint256 line,) = VatLike(vat).ilks(ilk);    // Assume rate == RAY because this is a D3M
        // Convert the DSR to the SFBR as a yearly APR
        uint256 baseRate = (PotLike(pot).dsr() - RAY) * SECONDS_PER_YEAR * baseRateConversion / RAY;
        
        // Base rate + borrow spread cannot be larger than the max rate
        if (baseRate + borrowSpread > maxRate) {
            unchecked {
                baseRate = maxRate - borrowSpread;  // This is safe because borrowSpread <= maxRate in constructor
            }
        }

        uint256 _line = line / RAD;
        uint256 debtRatio = Art > 0 ? (_line > 0 ? Art / _line : type(uint88).max) : 0;
        if (debtRatio > type(uint88).max) {
            debtRatio = type(uint88).max;
        }

        _slot0 = Slot0({
            debtRatio: uint88(debtRatio),
            baseRate: uint128(baseRate),
            lastUpdateTimestamp: uint40(block.timestamp)
        });
    }

    /// @inheritdoc IReserveInterestRateStrategy
    function calculateInterestRates(DataTypes.CalculateInterestRatesParams memory params)
        external
        view
        override
        returns (
            uint256 supplyRate,
            uint256 stableBorrowRate,
            uint256 variableBorrowRate
        )
    {
        stableBorrowRate = 0;   // Avoid warning message

        Slot0 memory slot0 = _slot0;

        uint256 baseRate = slot0.baseRate;
        uint256 outstandingBorrow = params.totalVariableDebt;
        uint256 supplyUtilization;
        
        if (outstandingBorrow > 0) {
            uint256 availableLiquidity =
                IERC20(params.reserve).balanceOf(params.aToken) +
                params.liquidityAdded -
                params.liquidityTaken;
            supplyUtilization = outstandingBorrow * WAD / (availableLiquidity + outstandingBorrow);
        }

        uint256 debtRatio = slot0.debtRatio;
        variableBorrowRate = baseRate + borrowSpread;
        if (debtRatio <= WAD) {
            // Maker has enough liquidity - rates are flat
            if (outstandingBorrow > performanceBonus) {
                uint256 delta;
                unchecked {
                    delta = outstandingBorrow - performanceBonus;
                }
                supplyRate =
                    (baseRate + supplySpread) *     // Flat rate
                    supplyUtilization / WAD *       // Supply utilization
                    delta / outstandingBorrow;      // Performance bonus deduction
            }
        } else {
            // Maker needs liquidity - rates increase until D3M debt is brought back to the debt ceiling
            uint256 maxRateDelta;
            unchecked {
                maxRateDelta = maxRate - variableBorrowRate;  // Safety enforced by conditional above
            }
            
            variableBorrowRate = maxRate - maxRateDelta * WAD / debtRatio;

            // Drop the performance bonus to incentivize third party suppliers as much as possible
            supplyRate = variableBorrowRate * supplyUtilization / WAD;
        }
    }

    function getDebtRatio() external view returns (uint256) {
        return _slot0.debtRatio;
    }

    function getBaseRate() external view returns (uint256) {
        return _slot0.baseRate;
    }

    function getLastUpdateTimestamp() external view returns (uint256) {
        return _slot0.lastUpdateTimestamp;
    }

}