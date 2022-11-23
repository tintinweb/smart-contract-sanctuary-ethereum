// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";

import "../interfaces/IPrimaryMarketV3.sol";
import "../interfaces/ITrancheIndexV2.sol";
import "./StableSwapV2.sol";

contract BishopStableSwapV2 is StableSwapV2, ITrancheIndexV2 {
    event Rebalanced(uint256 base, uint256 quote, uint256 version);

    uint256 public immutable tradingCurbThreshold;

    uint256 public currentVersion;

    constructor(
        address lpToken_,
        address fund_,
        address quoteAddress_,
        uint256 quoteDecimals_,
        uint256 ampl_,
        address feeCollector_,
        uint256 feeRate_,
        uint256 adminFeeRate_,
        uint256 tradingCurbThreshold_
    )
        public
        StableSwapV2(
            lpToken_,
            fund_,
            TRANCHE_B,
            quoteAddress_,
            quoteDecimals_,
            ampl_,
            feeCollector_,
            feeRate_,
            adminFeeRate_
        )
    {
        tradingCurbThreshold = tradingCurbThreshold_;
        currentVersion = IFundV3(fund_).getRebalanceSize();
    }

    /// @dev Make sure the user-specified version is the latest rebalance version.
    function _checkVersion(uint256 version) internal view override {
        require(version == fund.getRebalanceSize(), "Obsolete rebalance version");
    }

    function _getRebalanceResult(uint256 latestVersion)
        internal
        view
        override
        returns (
            uint256 newBase,
            uint256 newQuote,
            uint256 excessiveQ,
            uint256 excessiveB,
            uint256 excessiveR,
            uint256 excessiveQuote,
            bool isRebalanced
        )
    {
        if (latestVersion == currentVersion) {
            return (baseBalance, quoteBalance, 0, 0, 0, 0, false);
        }
        isRebalanced = true;

        uint256 oldBaseBalance = baseBalance;
        uint256 oldQuoteBalance = quoteBalance;
        (excessiveQ, newBase, ) = fund.batchRebalance(
            0,
            oldBaseBalance,
            0,
            currentVersion,
            latestVersion
        );
        if (newBase < oldBaseBalance) {
            // We split all QUEEN from rebalance if the amount of BISHOP is smaller than before.
            // In almost all cases, the total amount of BISHOP after the split is still smaller
            // than before.
            excessiveR = IPrimaryMarketV3(fund.primaryMarket()).getSplit(excessiveQ);
            newBase = newBase.add(excessiveR);
        }
        if (newBase < oldBaseBalance) {
            // If BISHOP amount is still smaller than before, we remove quote tokens proportionally.
            newQuote = oldQuoteBalance.mul(newBase).div(oldBaseBalance);
            excessiveQuote = oldQuoteBalance - newQuote;
        } else {
            // In most cases when we reach here, the BISHOP amount remains the same (ratioBR = 1).
            newQuote = oldQuoteBalance;
            excessiveB = newBase - oldBaseBalance;
            newBase = oldBaseBalance;
        }
    }

    function _handleRebalance(uint256 latestVersion)
        internal
        override
        returns (uint256 newBase, uint256 newQuote)
    {
        uint256 excessiveQ;
        uint256 excessiveB;
        uint256 excessiveR;
        uint256 excessiveQuote;
        bool isRebalanced;
        (
            newBase,
            newQuote,
            excessiveQ,
            excessiveB,
            excessiveR,
            excessiveQuote,
            isRebalanced
        ) = _getRebalanceResult(latestVersion);
        if (isRebalanced) {
            baseBalance = newBase;
            quoteBalance = newQuote;
            currentVersion = latestVersion;
            emit Rebalanced(newBase, newQuote, latestVersion);
            if (excessiveQ > 0) {
                if (excessiveR > 0) {
                    IPrimaryMarketV3(fund.primaryMarket()).split(
                        address(this),
                        excessiveQ,
                        latestVersion
                    );
                    excessiveQ = 0;
                } else {
                    fund.trancheTransfer(TRANCHE_Q, lpToken, excessiveQ, latestVersion);
                }
            }
            if (excessiveB > 0) {
                fund.trancheTransfer(TRANCHE_B, lpToken, excessiveB, latestVersion);
            }
            if (excessiveR > 0) {
                fund.trancheTransfer(TRANCHE_R, lpToken, excessiveR, latestVersion);
            }
            if (excessiveQuote > 0) {
                IERC20(quoteAddress).safeTransfer(lpToken, excessiveQuote);
            }
            ILiquidityGauge(lpToken).distribute(
                excessiveQ,
                excessiveB,
                excessiveR,
                excessiveQuote,
                latestVersion
            );
        }
    }

    function getOraclePrice() public view override returns (uint256) {
        uint256 price = fund.twapOracle().getLatest();
        (, uint256 navB, uint256 navR) = fund.extrapolateNav(price);
        require(navR >= navB.multiplyDecimal(tradingCurbThreshold), "Trading curb");
        return navB;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;

interface IPrimaryMarketV3 {
    function fund() external view returns (address);

    function getCreation(uint256 underlying) external view returns (uint256 outQ);

    function getCreationForQ(uint256 minOutQ) external view returns (uint256 underlying);

    function getRedemption(uint256 inQ) external view returns (uint256 underlying, uint256 fee);

    function getRedemptionForUnderlying(uint256 minUnderlying) external view returns (uint256 inQ);

    function getSplit(uint256 inQ) external view returns (uint256 outB);

    function getSplitForB(uint256 minOutB) external view returns (uint256 inQ);

    function getMerge(uint256 inB) external view returns (uint256 outQ, uint256 feeQ);

    function getMergeForQ(uint256 minOutQ) external view returns (uint256 inB);

    function canBeRemovedFromFund() external view returns (bool);

    function create(
        address recipient,
        uint256 minOutQ,
        uint256 version
    ) external returns (uint256 outQ);

    function redeem(
        address recipient,
        uint256 inQ,
        uint256 minUnderlying,
        uint256 version
    ) external returns (uint256 underlying);

    function redeemAndUnwrap(
        address recipient,
        uint256 inQ,
        uint256 minUnderlying,
        uint256 version
    ) external returns (uint256 underlying);

    function queueRedemption(
        address recipient,
        uint256 inQ,
        uint256 minUnderlying,
        uint256 version
    ) external returns (uint256 underlying, uint256 index);

    function claimRedemptions(address account, uint256[] calldata indices)
        external
        returns (uint256 underlying);

    function claimRedemptionsAndUnwrap(address account, uint256[] calldata indices)
        external
        returns (uint256 underlying);

    function split(
        address recipient,
        uint256 inQ,
        uint256 version
    ) external returns (uint256 outB);

    function merge(
        address recipient,
        uint256 inB,
        uint256 version
    ) external returns (uint256 outQ);

    function settle(uint256 day) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;

/// @notice Amounts of QUEEN, BISHOP and ROOK are sometimes stored in a `uint256[3]` array.
///         This contract defines index of each tranche in this array.
///
///         Solidity does not allow constants to be defined in interfaces. So this contract follows
///         the naming convention of interfaces but is implemented as an `abstract contract`.
abstract contract ITrancheIndexV2 {
    uint256 internal constant TRANCHE_Q = 0;
    uint256 internal constant TRANCHE_B = 1;
    uint256 internal constant TRANCHE_R = 2;

    uint256 internal constant TRANCHE_COUNT = 3;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import "../interfaces/IStableSwap.sol";
import "../interfaces/ILiquidityGauge.sol";
import "../interfaces/ITranchessSwapCallee.sol";
import "../interfaces/IWrappedERC20.sol";

import "../utils/SafeDecimalMath.sol";
import "../utils/AdvancedMath.sol";
import "../utils/ManagedPausable.sol";

abstract contract StableSwapV2 is IStableSwap, Ownable, ReentrancyGuard, ManagedPausable {
    using SafeMath for uint256;
    using SafeDecimalMath for uint256;
    using SafeERC20 for IERC20;

    event LiquidityAdded(
        address indexed sender,
        address indexed recipient,
        uint256 baseIn,
        uint256 quoteIn,
        uint256 lpOut,
        uint256 fee,
        uint256 adminFee,
        uint256 oraclePrice
    );
    event LiquidityRemoved(
        address indexed account,
        uint256 lpIn,
        uint256 baseOut,
        uint256 quotOut,
        uint256 fee,
        uint256 adminFee,
        uint256 oraclePrice
    );
    event Swap(
        address indexed sender,
        address indexed recipient,
        uint256 baseIn,
        uint256 quoteIn,
        uint256 baseOut,
        uint256 quoteOut,
        uint256 fee,
        uint256 adminFee,
        uint256 oraclePrice
    );
    event Sync(uint256 base, uint256 quote, uint256 oraclePrice);
    event AmplRampUpdated(uint256 start, uint256 end, uint256 startTimestamp, uint256 endTimestamp);
    event FeeCollectorUpdated(address newFeeCollector);
    event FeeRateUpdated(uint256 newFeeRate);
    event AdminFeeRateUpdated(uint256 newAdminFeeRate);

    uint256 private constant AMPL_MAX_VALUE = 1e6;
    uint256 private constant AMPL_RAMP_MIN_TIME = 86400;
    uint256 private constant AMPL_RAMP_MAX_CHANGE = 10;
    uint256 private constant MAX_FEE_RATE = 0.5e18;
    uint256 private constant MAX_ADMIN_FEE_RATE = 1e18;
    uint256 private constant MAX_ITERATION = 255;
    uint256 private constant MINIMUM_LIQUIDITY = 1e3;

    address public immutable lpToken;
    IFundV3 public immutable override fund;
    uint256 public immutable override baseTranche;
    address public immutable override quoteAddress;

    /// @dev A multipler that normalizes a quote asset balance to 18 decimal places.
    uint256 internal immutable _quoteDecimalMultiplier;

    uint256 public baseBalance;
    uint256 public quoteBalance;

    uint256 private _priceOverOracleIntegral;
    uint256 private _priceOverOracleTimestamp;

    uint256 public amplRampStart;
    uint256 public amplRampEnd;
    uint256 public amplRampStartTimestamp;
    uint256 public amplRampEndTimestamp;

    address public feeCollector;
    uint256 public feeRate;
    uint256 public adminFeeRate;
    uint256 public totalAdminFee;

    constructor(
        address lpToken_,
        address fund_,
        uint256 baseTranche_,
        address quoteAddress_,
        uint256 quoteDecimals_,
        uint256 ampl_,
        address feeCollector_,
        uint256 feeRate_,
        uint256 adminFeeRate_
    ) public {
        lpToken = lpToken_;
        fund = IFundV3(fund_);
        baseTranche = baseTranche_;
        quoteAddress = quoteAddress_;
        require(quoteDecimals_ <= 18, "Quote asset decimals larger than 18");
        _quoteDecimalMultiplier = 10**(18 - quoteDecimals_);

        require(ampl_ > 0 && ampl_ < AMPL_MAX_VALUE, "Invalid A");
        amplRampEnd = ampl_;
        emit AmplRampUpdated(ampl_, ampl_, 0, 0);

        _updateFeeCollector(feeCollector_);
        _updateFeeRate(feeRate_);
        _updateAdminFeeRate(adminFeeRate_);

        _initializeManagedPausable(msg.sender);
    }

    receive() external payable {}

    function baseAddress() external view override returns (address) {
        return fund.tokenShare(baseTranche);
    }

    function allBalances() external view override returns (uint256, uint256) {
        (uint256 base, uint256 quote, , , , , ) = _getRebalanceResult(fund.getRebalanceSize());
        return (base, quote);
    }

    function getAmpl() public view returns (uint256) {
        uint256 endTimestamp = amplRampEndTimestamp;
        if (block.timestamp < endTimestamp) {
            uint256 startTimestamp = amplRampStartTimestamp;
            uint256 start = amplRampStart;
            uint256 end = amplRampEnd;
            if (end > start) {
                return
                    start +
                    ((end - start) * (block.timestamp - startTimestamp)) /
                    (endTimestamp - startTimestamp);
            } else {
                return
                    start -
                    ((start - end) * (block.timestamp - startTimestamp)) /
                    (endTimestamp - startTimestamp);
            }
        } else {
            return amplRampEnd;
        }
    }

    function getCurrentD() external view override returns (uint256) {
        (uint256 base, uint256 quote, , , , , ) = _getRebalanceResult(fund.getRebalanceSize());
        return _getD(base, quote, getAmpl(), getOraclePrice());
    }

    function getCurrentPriceOverOracle() public view override returns (uint256) {
        (uint256 base, uint256 quote, , , , , ) = _getRebalanceResult(fund.getRebalanceSize());
        if (base == 0 || quote == 0) {
            return 1e18;
        }
        uint256 ampl = getAmpl();
        uint256 oraclePrice = getOraclePrice();
        uint256 d = _getD(base, quote, ampl, oraclePrice);
        return _getPriceOverOracle(base, quote, ampl, oraclePrice, d);
    }

    /// @notice Get the current swap price, i.e. negative slope at the current point on the curve.
    ///         The returned value is computed after both base and quote balances are normalized to
    ///         18 decimal places. If the quote token does not have 18 decimal places, the returned
    ///         value has a different order of magnitude than the ratio of quote amount to base
    ///         amount in a swap.
    function getCurrentPrice() external view override returns (uint256) {
        (uint256 base, uint256 quote, , , , , ) = _getRebalanceResult(fund.getRebalanceSize());
        uint256 oraclePrice = getOraclePrice();
        if (base == 0 || quote == 0) {
            return oraclePrice;
        }
        uint256 ampl = getAmpl();
        uint256 d = _getD(base, quote, ampl, oraclePrice);
        return _getPriceOverOracle(base, quote, ampl, oraclePrice, d).multiplyDecimal(oraclePrice);
    }

    function getPriceOverOracleIntegral() external view override returns (uint256) {
        return
            _priceOverOracleIntegral +
            getCurrentPriceOverOracle() *
            (block.timestamp - _priceOverOracleTimestamp);
    }

    function getQuoteOut(uint256 baseIn) external view override returns (uint256 quoteOut) {
        (uint256 oldBase, uint256 oldQuote, , , , , ) =
            _getRebalanceResult(fund.getRebalanceSize());
        uint256 newBase = oldBase.add(baseIn);
        uint256 ampl = getAmpl();
        uint256 oraclePrice = getOraclePrice();
        // Add 1 in case of rounding errors
        uint256 d = _getD(oldBase, oldQuote, ampl, oraclePrice) + 1;
        uint256 newQuote = _getQuote(ampl, newBase, oraclePrice, d) + 1;
        quoteOut = oldQuote.sub(newQuote);
        // Round down output after fee
        quoteOut = quoteOut.multiplyDecimal(1e18 - feeRate);
    }

    function getQuoteIn(uint256 baseOut) external view override returns (uint256 quoteIn) {
        (uint256 oldBase, uint256 oldQuote, , , , , ) =
            _getRebalanceResult(fund.getRebalanceSize());
        uint256 newBase = oldBase.sub(baseOut);
        uint256 ampl = getAmpl();
        uint256 oraclePrice = getOraclePrice();
        // Add 1 in case of rounding errors
        uint256 d = _getD(oldBase, oldQuote, ampl, oraclePrice) + 1;
        uint256 newQuote = _getQuote(ampl, newBase, oraclePrice, d) + 1;
        quoteIn = newQuote.sub(oldQuote);
        uint256 feeRate_ = feeRate;
        // Round up input before fee
        quoteIn = quoteIn.mul(1e18).add(1e18 - feeRate_ - 1) / (1e18 - feeRate_);
    }

    function getBaseOut(uint256 quoteIn) external view override returns (uint256 baseOut) {
        (uint256 oldBase, uint256 oldQuote, , , , , ) =
            _getRebalanceResult(fund.getRebalanceSize());
        // Round down input after fee
        uint256 quoteInAfterFee = quoteIn.multiplyDecimal(1e18 - feeRate);
        uint256 newQuote = oldQuote.add(quoteInAfterFee);
        uint256 ampl = getAmpl();
        uint256 oraclePrice = getOraclePrice();
        // Add 1 in case of rounding errors
        uint256 d = _getD(oldBase, oldQuote, ampl, oraclePrice) + 1;
        uint256 newBase = _getBase(ampl, newQuote, oraclePrice, d) + 1;
        baseOut = oldBase.sub(newBase);
    }

    function getBaseIn(uint256 quoteOut) external view override returns (uint256 baseIn) {
        (uint256 oldBase, uint256 oldQuote, , , , , ) =
            _getRebalanceResult(fund.getRebalanceSize());
        uint256 feeRate_ = feeRate;
        // Round up output before fee
        uint256 quoteOutBeforeFee = quoteOut.mul(1e18).add(1e18 - feeRate_ - 1) / (1e18 - feeRate_);
        uint256 newQuote = oldQuote.sub(quoteOutBeforeFee);
        uint256 ampl = getAmpl();
        uint256 oraclePrice = getOraclePrice();
        // Add 1 in case of rounding errors
        uint256 d = _getD(oldBase, oldQuote, ampl, oraclePrice) + 1;
        uint256 newBase = _getBase(ampl, newQuote, oraclePrice, d) + 1;
        baseIn = newBase.sub(oldBase);
    }

    function buy(
        uint256 version,
        uint256 baseOut,
        address recipient,
        bytes calldata data
    )
        external
        override
        nonReentrant
        checkVersion(version)
        whenNotPaused
        returns (uint256 realBaseOut)
    {
        require(baseOut > 0, "Zero output");
        realBaseOut = baseOut;
        (uint256 oldBase, uint256 oldQuote) = _handleRebalance(version);
        require(baseOut < oldBase, "Insufficient liquidity");
        // Optimistically transfer tokens.
        fund.trancheTransfer(baseTranche, recipient, baseOut, version);
        if (data.length > 0) {
            ITranchessSwapCallee(msg.sender).tranchessSwapCallback(baseOut, 0, data);
            _checkVersion(version); // Make sure no rebalance is triggered in the callback
        }
        uint256 newQuote = _getNewQuoteBalance();
        uint256 quoteIn = newQuote.sub(oldQuote);
        uint256 fee = quoteIn.multiplyDecimal(feeRate);
        uint256 oraclePrice = getOraclePrice();
        {
            uint256 ampl = getAmpl();
            uint256 oldD = _getD(oldBase, oldQuote, ampl, oraclePrice);
            _updatePriceOverOracleIntegral(oldBase, oldQuote, ampl, oraclePrice, oldD);
            uint256 newD = _getD(oldBase - baseOut, newQuote.sub(fee), ampl, oraclePrice);
            require(newD >= oldD, "Invariant mismatch");
        }
        uint256 adminFee = fee.multiplyDecimal(adminFeeRate);
        baseBalance = oldBase - baseOut;
        quoteBalance = newQuote.sub(adminFee);
        totalAdminFee = totalAdminFee.add(adminFee);
        uint256 baseOut_ = baseOut;
        emit Swap(msg.sender, recipient, 0, quoteIn, baseOut_, 0, fee, adminFee, oraclePrice);
    }

    function sell(
        uint256 version,
        uint256 quoteOut,
        address recipient,
        bytes calldata data
    )
        external
        override
        nonReentrant
        checkVersion(version)
        whenNotPaused
        returns (uint256 realQuoteOut)
    {
        require(quoteOut > 0, "Zero output");
        realQuoteOut = quoteOut;
        (uint256 oldBase, uint256 oldQuote) = _handleRebalance(version);
        // Optimistically transfer tokens.
        IERC20(quoteAddress).safeTransfer(recipient, quoteOut);
        if (data.length > 0) {
            ITranchessSwapCallee(msg.sender).tranchessSwapCallback(0, quoteOut, data);
            _checkVersion(version); // Make sure no rebalance is triggered in the callback
        }
        uint256 newBase = fund.trancheBalanceOf(baseTranche, address(this));
        uint256 baseIn = newBase.sub(oldBase);
        uint256 fee;
        {
            uint256 feeRate_ = feeRate;
            fee = quoteOut.mul(feeRate_).div(1e18 - feeRate_);
        }
        require(quoteOut.add(fee) < oldQuote, "Insufficient liquidity");
        uint256 oraclePrice = getOraclePrice();
        {
            uint256 newQuote = oldQuote - quoteOut;
            uint256 ampl = getAmpl();
            uint256 oldD = _getD(oldBase, oldQuote, ampl, oraclePrice);
            _updatePriceOverOracleIntegral(oldBase, oldQuote, ampl, oraclePrice, oldD);
            uint256 newD = _getD(newBase, newQuote - fee, ampl, oraclePrice);
            require(newD >= oldD, "Invariant mismatch");
        }
        uint256 adminFee = fee.multiplyDecimal(adminFeeRate);
        baseBalance = newBase;
        quoteBalance = oldQuote - quoteOut - adminFee;
        totalAdminFee = totalAdminFee.add(adminFee);
        uint256 quoteOut_ = quoteOut;
        emit Swap(msg.sender, recipient, baseIn, 0, 0, quoteOut_, fee, adminFee, oraclePrice);
    }

    /// @notice Add liquidity. This function should be called by a smart contract, which transfers
    ///         base and quote tokens to this contract in the same transaction.
    /// @param version The latest rebalance version
    /// @param recipient Recipient of minted LP tokens
    /// @param lpOut Amount of minted LP tokens
    function addLiquidity(uint256 version, address recipient)
        external
        override
        nonReentrant
        checkVersion(version)
        whenNotPaused
        returns (uint256 lpOut)
    {
        (uint256 oldBase, uint256 oldQuote) = _handleRebalance(version);
        uint256 newBase = fund.trancheBalanceOf(baseTranche, address(this));
        uint256 newQuote = _getNewQuoteBalance();
        uint256 ampl = getAmpl();
        uint256 oraclePrice = getOraclePrice();
        uint256 lpSupply = IERC20(lpToken).totalSupply();
        if (lpSupply == 0) {
            require(newBase > 0 && newQuote > 0, "Zero initial balance");
            baseBalance = newBase;
            quoteBalance = newQuote;
            // Overflow is desired
            _priceOverOracleIntegral += 1e18 * (block.timestamp - _priceOverOracleTimestamp);
            _priceOverOracleTimestamp = block.timestamp;
            uint256 d1 = _getD(newBase, newQuote, ampl, oraclePrice);
            ILiquidityGauge(lpToken).mint(address(this), MINIMUM_LIQUIDITY);
            ILiquidityGauge(lpToken).mint(recipient, d1.sub(MINIMUM_LIQUIDITY));
            emit LiquidityAdded(msg.sender, recipient, newBase, newQuote, d1, 0, 0, oraclePrice);
            return d1;
        }
        uint256 fee;
        uint256 adminFee;
        {
            // Initial invariant
            uint256 d0 = _getD(oldBase, oldQuote, ampl, oraclePrice);
            _updatePriceOverOracleIntegral(oldBase, oldQuote, ampl, oraclePrice, d0);
            {
                // New invariant before charging fee
                uint256 d1 = _getD(newBase, newQuote, ampl, oraclePrice);
                uint256 idealQuote = d1.mul(oldQuote) / d0;
                uint256 difference =
                    idealQuote > newQuote ? idealQuote - newQuote : newQuote - idealQuote;
                fee = difference.multiplyDecimal(feeRate);
            }
            adminFee = fee.multiplyDecimal(adminFeeRate);
            totalAdminFee = totalAdminFee.add(adminFee);
            baseBalance = newBase;
            quoteBalance = newQuote.sub(adminFee);
            // New invariant after charging fee
            uint256 d2 = _getD(newBase, newQuote.sub(fee), ampl, oraclePrice);
            require(d2 > d0, "No liquidity is added");
            lpOut = lpSupply.mul(d2.sub(d0)).div(d0);
        }
        ILiquidityGauge(lpToken).mint(recipient, lpOut);
        emit LiquidityAdded(
            msg.sender,
            recipient,
            newBase - oldBase,
            newQuote - oldQuote,
            lpOut,
            fee,
            adminFee,
            oraclePrice
        );
    }

    /// @dev Remove liquidity proportionally.
    /// @param lpIn Exact amount of LP token to burn
    /// @param minBaseOut Least amount of base asset to withdraw
    /// @param minQuoteOut Least amount of quote asset to withdraw
    function removeLiquidity(
        uint256 version,
        uint256 lpIn,
        uint256 minBaseOut,
        uint256 minQuoteOut
    )
        external
        override
        nonReentrant
        checkVersion(version)
        returns (uint256 baseOut, uint256 quoteOut)
    {
        (baseOut, quoteOut) = _removeLiquidity(version, lpIn, minBaseOut, minQuoteOut);
        IERC20(quoteAddress).safeTransfer(msg.sender, quoteOut);
    }

    /// @dev Remove liquidity proportionally and unwrap for native token.
    /// @param lpIn Exact amount of LP token to burn
    /// @param minBaseOut Least amount of base asset to withdraw
    /// @param minQuoteOut Least amount of quote asset to withdraw
    function removeLiquidityUnwrap(
        uint256 version,
        uint256 lpIn,
        uint256 minBaseOut,
        uint256 minQuoteOut
    )
        external
        override
        nonReentrant
        checkVersion(version)
        returns (uint256 baseOut, uint256 quoteOut)
    {
        (baseOut, quoteOut) = _removeLiquidity(version, lpIn, minBaseOut, minQuoteOut);
        IWrappedERC20(quoteAddress).withdraw(quoteOut);
        (bool success, ) = msg.sender.call{value: quoteOut}("");
        require(success, "Transfer failed");
    }

    function _removeLiquidity(
        uint256 version,
        uint256 lpIn,
        uint256 minBaseOut,
        uint256 minQuoteOut
    ) private returns (uint256 baseOut, uint256 quoteOut) {
        uint256 lpSupply = IERC20(lpToken).totalSupply();
        (uint256 oldBase, uint256 oldQuote) = _handleRebalance(version);
        baseOut = oldBase.mul(lpIn).div(lpSupply);
        quoteOut = oldQuote.mul(lpIn).div(lpSupply);
        require(baseOut >= minBaseOut, "Insufficient output");
        require(quoteOut >= minQuoteOut, "Insufficient output");
        baseBalance = oldBase.sub(baseOut);
        quoteBalance = oldQuote.sub(quoteOut);
        ILiquidityGauge(lpToken).burnFrom(msg.sender, lpIn);
        fund.trancheTransfer(baseTranche, msg.sender, baseOut, version);
        emit LiquidityRemoved(msg.sender, lpIn, baseOut, quoteOut, 0, 0, 0);
    }

    /// @dev Remove base liquidity only.
    /// @param lpIn Exact amount of LP token to burn
    /// @param minBaseOut Least amount of base asset to withdraw
    function removeBaseLiquidity(
        uint256 version,
        uint256 lpIn,
        uint256 minBaseOut
    ) external override nonReentrant checkVersion(version) whenNotPaused returns (uint256 baseOut) {
        (uint256 oldBase, uint256 oldQuote) = _handleRebalance(version);
        uint256 lpSupply = IERC20(lpToken).totalSupply();
        uint256 ampl = getAmpl();
        uint256 oraclePrice = getOraclePrice();
        uint256 d1;
        {
            uint256 d0 = _getD(oldBase, oldQuote, ampl, oraclePrice);
            _updatePriceOverOracleIntegral(oldBase, oldQuote, ampl, oraclePrice, d0);
            d1 = d0.sub(d0.mul(lpIn).div(lpSupply));
        }
        {
            uint256 fee = oldQuote.mul(lpIn).div(lpSupply).multiplyDecimal(feeRate);
            // Add 1 in case of rounding errors
            uint256 newBase = _getBase(ampl, oldQuote.sub(fee), oraclePrice, d1) + 1;
            baseOut = oldBase.sub(newBase);
            require(baseOut >= minBaseOut, "Insufficient output");
            ILiquidityGauge(lpToken).burnFrom(msg.sender, lpIn);
            baseBalance = newBase;
            uint256 adminFee = fee.multiplyDecimal(adminFeeRate);
            totalAdminFee = totalAdminFee.add(adminFee);
            quoteBalance = oldQuote.sub(adminFee);
            emit LiquidityRemoved(msg.sender, lpIn, baseOut, 0, fee, adminFee, oraclePrice);
        }
        fund.trancheTransfer(baseTranche, msg.sender, baseOut, version);
    }

    /// @dev Remove quote liquidity only.
    /// @param lpIn Exact amount of LP token to burn
    /// @param minQuoteOut Least amount of quote asset to withdraw
    function removeQuoteLiquidity(
        uint256 version,
        uint256 lpIn,
        uint256 minQuoteOut
    )
        external
        override
        nonReentrant
        checkVersion(version)
        whenNotPaused
        returns (uint256 quoteOut)
    {
        quoteOut = _removeQuoteLiquidity(version, lpIn, minQuoteOut);
        IERC20(quoteAddress).safeTransfer(msg.sender, quoteOut);
    }

    /// @dev Remove quote liquidity only and unwrap for native token.
    /// @param lpIn Exact amount of LP token to burn
    /// @param minQuoteOut Least amount of quote asset to withdraw
    function removeQuoteLiquidityUnwrap(
        uint256 version,
        uint256 lpIn,
        uint256 minQuoteOut
    )
        external
        override
        nonReentrant
        checkVersion(version)
        whenNotPaused
        returns (uint256 quoteOut)
    {
        quoteOut = _removeQuoteLiquidity(version, lpIn, minQuoteOut);
        IWrappedERC20(quoteAddress).withdraw(quoteOut);
        (bool success, ) = msg.sender.call{value: quoteOut}("");
        require(success, "Transfer failed");
    }

    function _removeQuoteLiquidity(
        uint256 version,
        uint256 lpIn,
        uint256 minQuoteOut
    ) private returns (uint256 quoteOut) {
        (uint256 oldBase, uint256 oldQuote) = _handleRebalance(version);
        uint256 lpSupply = IERC20(lpToken).totalSupply();
        uint256 ampl = getAmpl();
        uint256 oraclePrice = getOraclePrice();
        uint256 d1;
        {
            uint256 d0 = _getD(oldBase, oldQuote, ampl, oraclePrice);
            _updatePriceOverOracleIntegral(oldBase, oldQuote, ampl, oraclePrice, d0);
            d1 = d0.sub(d0.mul(lpIn).div(lpSupply));
        }
        uint256 idealQuote = oldQuote.mul(lpSupply.sub(lpIn)).div(lpSupply);
        // Add 1 in case of rounding errors
        uint256 newQuote = _getQuote(ampl, oldBase, oraclePrice, d1) + 1;
        uint256 fee = idealQuote.sub(newQuote).multiplyDecimal(feeRate);
        quoteOut = oldQuote.sub(newQuote).sub(fee);
        require(quoteOut >= minQuoteOut, "Insufficient output");
        ILiquidityGauge(lpToken).burnFrom(msg.sender, lpIn);
        uint256 adminFee = fee.multiplyDecimal(adminFeeRate);
        totalAdminFee = totalAdminFee.add(adminFee);
        quoteBalance = newQuote.add(fee).sub(adminFee);
        emit LiquidityRemoved(msg.sender, lpIn, 0, quoteOut, fee, adminFee, oraclePrice);
    }

    /// @notice Force stored values to match balances.
    function sync() external nonReentrant {
        (uint256 oldBase, uint256 oldQuote) = _handleRebalance(fund.getRebalanceSize());
        uint256 ampl = getAmpl();
        uint256 oraclePrice = getOraclePrice();
        uint256 d = _getD(oldBase, oldQuote, ampl, oraclePrice);
        _updatePriceOverOracleIntegral(oldBase, oldQuote, ampl, oraclePrice, d);
        uint256 newBase = fund.trancheBalanceOf(baseTranche, address(this));
        uint256 newQuote = _getNewQuoteBalance();
        baseBalance = newBase;
        quoteBalance = newQuote;
        emit Sync(newBase, newQuote, oraclePrice);
    }

    function collectFee() external {
        uint256 totalAdminFee_ = totalAdminFee;
        delete totalAdminFee;
        IERC20(quoteAddress).safeTransfer(feeCollector, totalAdminFee_);
    }

    function _getNewQuoteBalance() private view returns (uint256) {
        return IERC20(quoteAddress).balanceOf(address(this)).sub(totalAdminFee);
    }

    function _updatePriceOverOracleIntegral(
        uint256 base,
        uint256 quote,
        uint256 ampl,
        uint256 oraclePrice,
        uint256 d
    ) private {
        // Overflow is desired
        _priceOverOracleIntegral +=
            _getPriceOverOracle(base, quote, ampl, oraclePrice, d) *
            (block.timestamp - _priceOverOracleTimestamp);
        _priceOverOracleTimestamp = block.timestamp;
    }

    function _getD(
        uint256 base,
        uint256 quote,
        uint256 ampl,
        uint256 oraclePrice
    ) private view returns (uint256) {
        // Newtonian: D' = (4A(kx + y) + D^3 / 2kxy)D / ((4A - 1)D + 3D^3 / 4kxy)
        uint256 normalizedQuote = quote.mul(_quoteDecimalMultiplier);
        uint256 baseValue = base.multiplyDecimal(oraclePrice);
        uint256 sum = baseValue.add(normalizedQuote);
        if (sum == 0) return 0;

        uint256 prev = 0;
        uint256 d = sum;
        for (uint256 i = 0; i < MAX_ITERATION; i++) {
            prev = d;
            uint256 d3 = d.mul(d).div(baseValue).mul(d) / normalizedQuote / 4;
            d = (sum.mul(4 * ampl) + 2 * d3).mul(d) / d.mul(4 * ampl - 1).add(3 * d3);
            if (d <= prev + 1 && prev <= d + 1) {
                break;
            }
        }
        return d;
    }

    function _getPriceOverOracle(
        uint256 base,
        uint256 quote,
        uint256 ampl,
        uint256 oraclePrice,
        uint256 d
    ) private view returns (uint256) {
        uint256 commonExp = d.multiplyDecimal(4e18 - 1e18 / ampl);
        uint256 baseValue = base.multiplyDecimal(oraclePrice);
        uint256 normalizedQuote = quote.mul(_quoteDecimalMultiplier);
        return
            (baseValue.mul(8).add(normalizedQuote.mul(4)).sub(commonExp))
                .multiplyDecimal(normalizedQuote)
                .divideDecimal(normalizedQuote.mul(8).add(baseValue.mul(4)).sub(commonExp))
                .divideDecimal(baseValue);
    }

    function _getBase(
        uint256 ampl,
        uint256 quote,
        uint256 oraclePrice,
        uint256 d
    ) private view returns (uint256 base) {
        // Solve 16Ayk^2·x^2 + 4ky(4Ay - 4AD + D)·x - D^3 = 0
        // Newtonian: kx' = ((kx)^2 + D^3 / 16Ay) / (2kx + y - D + D/4A)
        uint256 normalizedQuote = quote.mul(_quoteDecimalMultiplier);
        uint256 d3 = d.mul(d).div(normalizedQuote).mul(d) / (16 * ampl);
        uint256 prev = 0;
        uint256 baseValue = d;
        for (uint256 i = 0; i < MAX_ITERATION; i++) {
            prev = baseValue;
            baseValue =
                baseValue.mul(baseValue).add(d3) /
                (2 * baseValue).add(normalizedQuote).add(d / (4 * ampl)).sub(d);
            if (baseValue <= prev + 1 && prev <= baseValue + 1) {
                break;
            }
        }
        base = baseValue.divideDecimal(oraclePrice);
    }

    function _getQuote(
        uint256 ampl,
        uint256 base,
        uint256 oraclePrice,
        uint256 d
    ) private view returns (uint256 quote) {
        // Solve 16Axk·y^2 + 4kx(4Akx - 4AD + D)·y - D^3 = 0
        // Newtonian: y' = (y^2 + D^3 / 16Akx) / (2y + kx - D + D/4A)
        uint256 baseValue = base.multiplyDecimal(oraclePrice);
        uint256 d3 = d.mul(d).div(baseValue).mul(d) / (16 * ampl);
        uint256 prev = 0;
        uint256 normalizedQuote = d;
        for (uint256 i = 0; i < MAX_ITERATION; i++) {
            prev = normalizedQuote;
            normalizedQuote =
                normalizedQuote.mul(normalizedQuote).add(d3) /
                (2 * normalizedQuote).add(baseValue).add(d / (4 * ampl)).sub(d);
            if (normalizedQuote <= prev + 1 && prev <= normalizedQuote + 1) {
                break;
            }
        }
        quote = normalizedQuote / _quoteDecimalMultiplier;
    }

    function updateAmplRamp(uint256 endAmpl, uint256 endTimestamp) external onlyOwner {
        require(endAmpl > 0 && endAmpl < AMPL_MAX_VALUE, "Invalid A");
        require(endTimestamp >= block.timestamp + AMPL_RAMP_MIN_TIME, "A ramp time too short");
        uint256 ampl = getAmpl();
        require(
            (endAmpl >= ampl && endAmpl <= ampl * AMPL_RAMP_MAX_CHANGE) ||
                (endAmpl < ampl && endAmpl * AMPL_RAMP_MAX_CHANGE >= ampl),
            "A ramp change too large"
        );
        amplRampStart = ampl;
        amplRampEnd = endAmpl;
        amplRampStartTimestamp = block.timestamp;
        amplRampEndTimestamp = endTimestamp;
        emit AmplRampUpdated(ampl, endAmpl, block.timestamp, endTimestamp);
    }

    function _updateFeeCollector(address newFeeCollector) private {
        feeCollector = newFeeCollector;
        emit FeeCollectorUpdated(newFeeCollector);
    }

    function updateFeeCollector(address newFeeCollector) external onlyOwner {
        _updateFeeCollector(newFeeCollector);
    }

    function _updateFeeRate(uint256 newFeeRate) private {
        require(newFeeRate <= MAX_FEE_RATE, "Exceed max fee rate");
        feeRate = newFeeRate;
        emit FeeRateUpdated(newFeeRate);
    }

    function updateFeeRate(uint256 newFeeRate) external onlyOwner {
        _updateFeeRate(newFeeRate);
    }

    function _updateAdminFeeRate(uint256 newAdminFeeRate) private {
        require(newAdminFeeRate <= MAX_ADMIN_FEE_RATE, "Exceed max admin fee rate");
        adminFeeRate = newAdminFeeRate;
        emit AdminFeeRateUpdated(newAdminFeeRate);
    }

    function updateAdminFeeRate(uint256 newAdminFeeRate) external onlyOwner {
        _updateAdminFeeRate(newAdminFeeRate);
    }

    /// @dev Check if the user-specified version is correct.
    modifier checkVersion(uint256 version) {
        _checkVersion(version);
        _;
    }

    /// @dev Revert if the user-specified version is not correct.
    function _checkVersion(uint256 version) internal view virtual {}

    /// @dev Compute the new base and quote amount after rebalanced to the latest version.
    ///      If any tokens should be distributed to LP holders, their amounts are also returned.
    ///
    ///      The latest rebalance version is passed in a parameter and it is caller's responsibility
    ///      to pass the correct version.
    /// @param latestVersion The latest rebalance version
    /// @return newBase Amount of base tokens after rebalance
    /// @return newQuote Amount of quote tokens after rebalance
    /// @return excessiveQ Amount of QUEEN that should be distributed to LP holders due to rebalance
    /// @return excessiveB Amount of BISHOP that should be distributed to LP holders due to rebalance
    /// @return excessiveR Amount of ROOK that should be distributed to LP holders due to rebalance
    /// @return excessiveQuote Amount of quote tokens that should be distributed to LP holders due to rebalance
    /// @return isRebalanced Whether the stored base and quote amount are rebalanced
    function _getRebalanceResult(uint256 latestVersion)
        internal
        view
        virtual
        returns (
            uint256 newBase,
            uint256 newQuote,
            uint256 excessiveQ,
            uint256 excessiveB,
            uint256 excessiveR,
            uint256 excessiveQuote,
            bool isRebalanced
        );

    /// @dev Update the stored base and quote balance to the latest rebalance version and distribute
    ///      any excessive tokens to LP holders.
    ///
    ///      The latest rebalance version is passed in a parameter and it is caller's responsibility
    ///      to pass the correct version.
    /// @param latestVersion The latest rebalance version
    /// @return newBase Amount of stored base tokens after rebalance
    /// @return newQuote Amount of stored quote tokens after rebalance
    function _handleRebalance(uint256 latestVersion)
        internal
        virtual
        returns (uint256 newBase, uint256 newQuote);

    /// @notice Get the base token price from the price oracle. The returned price is normalized
    ///         to 18 decimal places.
    function getOraclePrice() public view virtual override returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/Context.sol";
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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;

import "../interfaces/IFundV3.sol";

interface IStableSwapCore {
    function getQuoteOut(uint256 baseIn) external view returns (uint256 quoteOut);

    function getQuoteIn(uint256 baseOut) external view returns (uint256 quoteIn);

    function getBaseOut(uint256 quoteIn) external view returns (uint256 baseOut);

    function getBaseIn(uint256 quoteOut) external view returns (uint256 baseIn);

    function buy(
        uint256 version,
        uint256 baseOut,
        address recipient,
        bytes calldata data
    ) external returns (uint256 realBaseOut);

    function sell(
        uint256 version,
        uint256 quoteOut,
        address recipient,
        bytes calldata data
    ) external returns (uint256 realQuoteOut);
}

interface IStableSwap is IStableSwapCore {
    function fund() external view returns (IFundV3);

    function baseTranche() external view returns (uint256);

    function baseAddress() external view returns (address);

    function quoteAddress() external view returns (address);

    function allBalances() external view returns (uint256, uint256);

    function getOraclePrice() external view returns (uint256);

    function getCurrentD() external view returns (uint256);

    function getCurrentPriceOverOracle() external view returns (uint256);

    function getCurrentPrice() external view returns (uint256);

    function getPriceOverOracleIntegral() external view returns (uint256);

    function addLiquidity(uint256 version, address recipient) external returns (uint256);

    function removeLiquidity(
        uint256 version,
        uint256 lpIn,
        uint256 minBaseOut,
        uint256 minQuoteOut
    ) external returns (uint256 baseOut, uint256 quoteOut);

    function removeLiquidityUnwrap(
        uint256 version,
        uint256 lpIn,
        uint256 minBaseOut,
        uint256 minQuoteOut
    ) external returns (uint256 baseOut, uint256 quoteOut);

    function removeBaseLiquidity(
        uint256 version,
        uint256 lpIn,
        uint256 minBaseOut
    ) external returns (uint256 baseOut);

    function removeQuoteLiquidity(
        uint256 version,
        uint256 lpIn,
        uint256 minQuoteOut
    ) external returns (uint256 quoteOut);

    function removeQuoteLiquidityUnwrap(
        uint256 version,
        uint256 lpIn,
        uint256 minQuoteOut
    ) external returns (uint256 quoteOut);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface ILiquidityGauge is IERC20 {
    function mint(address account, uint256 amount) external;

    function burnFrom(address account, uint256 amount) external;

    function workingSupply() external view returns (uint256);

    function workingBalanceOf(address account) external view returns (uint256);

    function claimableRewards(address account)
        external
        returns (
            uint256 chessAmount,
            uint256 bonusAmount,
            uint256 amountQ,
            uint256 amountB,
            uint256 amountR,
            uint256 quoteAmount
        );

    function claimRewards(address account) external;

    function distribute(
        uint256 amountQ,
        uint256 amountB,
        uint256 amountR,
        uint256 quoteAmount,
        uint256 version
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;

interface ITranchessSwapCallee {
    function tranchessSwapCallback(
        uint256 baseDeltaOut,
        uint256 quoteDeltaOut,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWrappedERC20 is IERC20 {
    function deposit() external payable;

    function withdraw(uint256 wad) external;
}

// SPDX-License-Identifier: MIT
//
// Copyright (c) 2019 Synthetix
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
pragma solidity >=0.6.10 <0.8.0;

import "@openzeppelin/contracts/math/SafeMath.sol";

library SafeDecimalMath {
    using SafeMath for uint256;

    /* Number of decimal places in the representations. */
    uint256 private constant decimals = 18;
    uint256 private constant highPrecisionDecimals = 27;

    /* The number representing 1.0. */
    uint256 private constant UNIT = 10**uint256(decimals);

    /* The number representing 1.0 for higher fidelity numbers. */
    uint256 private constant PRECISE_UNIT = 10**uint256(highPrecisionDecimals);
    uint256 private constant UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR =
        10**uint256(highPrecisionDecimals - decimals);

    /**
     * @return The result of multiplying x and y, interpreting the operands as fixed-point
     * decimals.
     *
     * @dev A unit factor is divided out after the product of x and y is evaluated,
     * so that product must be less than 2**256. As this is an integer division,
     * the internal division always rounds down. This helps save on gas. Rounding
     * is more expensive on gas.
     */
    function multiplyDecimal(uint256 x, uint256 y) internal pure returns (uint256) {
        /* Divide by UNIT to remove the extra factor introduced by the product. */
        return x.mul(y).div(UNIT);
    }

    function multiplyDecimalPrecise(uint256 x, uint256 y) internal pure returns (uint256) {
        /* Divide by UNIT to remove the extra factor introduced by the product. */
        return x.mul(y).div(PRECISE_UNIT);
    }

    /**
     * @return The result of safely dividing x and y. The return value is a high
     * precision decimal.
     *
     * @dev y is divided after the product of x and the standard precision unit
     * is evaluated, so the product of x and UNIT must be less than 2**256. As
     * this is an integer division, the result is always rounded down.
     * This helps save on gas. Rounding is more expensive on gas.
     */
    function divideDecimal(uint256 x, uint256 y) internal pure returns (uint256) {
        /* Reintroduce the UNIT factor that will be divided out by y. */
        return x.mul(UNIT).div(y);
    }

    function divideDecimalPrecise(uint256 x, uint256 y) internal pure returns (uint256) {
        /* Reintroduce the UNIT factor that will be divided out by y. */
        return x.mul(PRECISE_UNIT).div(y);
    }

    /**
     * @dev Convert a standard decimal representation to a high precision one.
     */
    function decimalToPreciseDecimal(uint256 i) internal pure returns (uint256) {
        return i.mul(UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR);
    }

    /**
     * @dev Convert a high precision decimal to a standard decimal representation.
     */
    function preciseDecimalToDecimal(uint256 i) internal pure returns (uint256) {
        uint256 quotientTimesTen = i.mul(10).div(UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR);

        if (quotientTimesTen % 10 >= 5) {
            quotientTimesTen = quotientTimesTen.add(10);
        }

        return quotientTimesTen.div(10);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, and the max value of
     * uint256 on overflow.
     */
    function saturatingMul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        return c / a != b ? type(uint256).max : c;
    }

    function saturatingMultiplyDecimal(uint256 x, uint256 y) internal pure returns (uint256) {
        /* Divide by UNIT to remove the extra factor introduced by the product. */
        return saturatingMul(x, y).div(UNIT);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;

library AdvancedMath {
    /// @dev Calculate square root.
    ///
    ///      Reference: https://en.wikipedia.org/wiki/Integer_square_root#Algorithm_using_Newton's_method
    function sqrt(uint256 s) internal pure returns (uint256) {
        if (s == 0) return 0;
        uint256 t = s;
        uint256 x0 = 2;
        if (t >= 1 << 128) {
            t >>= 128;
            x0 <<= 64;
        }
        if (t >= 1 << 64) {
            t >>= 64;
            x0 <<= 32;
        }
        if (t >= 1 << 32) {
            t >>= 32;
            x0 <<= 16;
        }
        if (t >= 1 << 16) {
            t >>= 16;
            x0 <<= 8;
        }
        if (t >= 1 << 8) {
            t >>= 8;
            x0 <<= 4;
        }
        if (t >= 1 << 4) {
            t >>= 4;
            x0 <<= 2;
        }
        if (t >= 1 << 2) {
            x0 <<= 1;
        }
        uint256 x1 = (x0 + s / x0) >> 1;
        while (x1 < x0) {
            x0 = x1;
            x1 = (x0 + s / x0) >> 1;
        }
        return x0;
    }

    /// @notice Calculate cubic root.
    function cbrt(uint256 s) internal pure returns (uint256) {
        if (s == 0) return 0;
        uint256 t = s;
        uint256 x0 = 2;
        if (t >= 1 << 192) {
            t >>= 192;
            x0 <<= 64;
        }
        if (t >= 1 << 96) {
            t >>= 96;
            x0 <<= 32;
        }
        if (t >= 1 << 48) {
            t >>= 48;
            x0 <<= 16;
        }
        if (t >= 1 << 24) {
            t >>= 24;
            x0 <<= 8;
        }
        if (t >= 1 << 12) {
            t >>= 12;
            x0 <<= 4;
        }
        if (t >= 1 << 6) {
            t >>= 6;
            x0 <<= 2;
        }
        if (t >= 1 << 3) {
            x0 <<= 1;
        }
        uint256 x1 = (2 * x0 + s / x0 / x0) / 3;
        while (x1 < x0) {
            x0 = x1;
            x1 = (2 * x0 + s / x0 / x0) / 3;
        }
        return x0;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Contract of an emergency stop mechanism that can be triggered by an authorized account.
 *
 * This module is modified based on Pausable in OpenZeppelin v3.3.0, adding public functions to
 * pause, unpause and manage the pauser role. It is also designed to be used by upgradable
 * contracts, like PausableUpgradable but with compact storage slots and no dependencies.
 */
abstract contract ManagedPausable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    event PauserRoleTransferred(address indexed previousPauser, address indexed newPauser);

    uint256 private constant FALSE = 0;
    uint256 private constant TRUE = 1;

    uint256 private _initialized;

    uint256 private _paused;

    address private _pauser;

    function _initializeManagedPausable(address pauser_) internal {
        require(_initialized == FALSE);
        _initialized = TRUE;
        _paused = FALSE;
        _pauser = pauser_;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
        return _paused != FALSE;
    }

    function pauser() public view returns (address) {
        return _pauser;
    }

    function renouncePauserRole() external onlyPauser {
        emit PauserRoleTransferred(_pauser, address(0));
        _pauser = address(0);
    }

    function transferPauserRole(address newPauser) external onlyPauser {
        require(newPauser != address(0));
        emit PauserRoleTransferred(_pauser, newPauser);
        _pauser = newPauser;
    }

    modifier onlyPauser() {
        require(_pauser == msg.sender, "Pausable: only pauser");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(_paused == FALSE, "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(_paused != FALSE, "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function pause() external onlyPauser whenNotPaused {
        _paused = TRUE;
        emit Paused(msg.sender);
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function unpause() external onlyPauser whenPaused {
        _paused = FALSE;
        emit Unpaused(msg.sender);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

pragma solidity >=0.6.2 <0.8.0;

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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;
pragma experimental ABIEncoderV2;

import "./ITwapOracleV2.sol";

interface IFundV3 {
    /// @notice A linear transformation matrix that represents a rebalance.
    ///
    ///         ```
    ///             [        1        0        0 ]
    ///         R = [ ratioB2Q  ratioBR        0 ]
    ///             [ ratioR2Q        0  ratioBR ]
    ///         ```
    ///
    ///         Amounts of the three tranches `q`, `b` and `r` can be rebalanced by multiplying the matrix:
    ///
    ///         ```
    ///         [ q', b', r' ] = [ q, b, r ] * R
    ///         ```
    struct Rebalance {
        uint256 ratioB2Q;
        uint256 ratioR2Q;
        uint256 ratioBR;
        uint256 timestamp;
    }

    function tokenUnderlying() external view returns (address);

    function tokenQ() external view returns (address);

    function tokenB() external view returns (address);

    function tokenR() external view returns (address);

    function tokenShare(uint256 tranche) external view returns (address);

    function primaryMarket() external view returns (address);

    function primaryMarketUpdateProposal() external view returns (address, uint256);

    function strategy() external view returns (address);

    function strategyUpdateProposal() external view returns (address, uint256);

    function underlyingDecimalMultiplier() external view returns (uint256);

    function twapOracle() external view returns (ITwapOracleV2);

    function feeCollector() external view returns (address);

    function endOfDay(uint256 timestamp) external pure returns (uint256);

    function trancheTotalSupply(uint256 tranche) external view returns (uint256);

    function trancheBalanceOf(uint256 tranche, address account) external view returns (uint256);

    function trancheAllBalanceOf(address account)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    function trancheBalanceVersion(address account) external view returns (uint256);

    function trancheAllowance(
        uint256 tranche,
        address owner,
        address spender
    ) external view returns (uint256);

    function trancheAllowanceVersion(address owner, address spender)
        external
        view
        returns (uint256);

    function trancheTransfer(
        uint256 tranche,
        address recipient,
        uint256 amount,
        uint256 version
    ) external;

    function trancheTransferFrom(
        uint256 tranche,
        address sender,
        address recipient,
        uint256 amount,
        uint256 version
    ) external;

    function trancheApprove(
        uint256 tranche,
        address spender,
        uint256 amount,
        uint256 version
    ) external;

    function getRebalanceSize() external view returns (uint256);

    function getRebalance(uint256 index) external view returns (Rebalance memory);

    function getRebalanceTimestamp(uint256 index) external view returns (uint256);

    function currentDay() external view returns (uint256);

    function splitRatio() external view returns (uint256);

    function historicalSplitRatio(uint256 version) external view returns (uint256);

    function fundActivityStartTime() external view returns (uint256);

    function isFundActive(uint256 timestamp) external view returns (bool);

    function getEquivalentTotalB() external view returns (uint256);

    function getEquivalentTotalQ() external view returns (uint256);

    function historicalEquivalentTotalB(uint256 timestamp) external view returns (uint256);

    function historicalNavs(uint256 timestamp) external view returns (uint256 navB, uint256 navR);

    function extrapolateNav(uint256 price)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    function doRebalance(
        uint256 amountQ,
        uint256 amountB,
        uint256 amountR,
        uint256 index
    )
        external
        view
        returns (
            uint256 newAmountQ,
            uint256 newAmountB,
            uint256 newAmountR
        );

    function batchRebalance(
        uint256 amountQ,
        uint256 amountB,
        uint256 amountR,
        uint256 fromIndex,
        uint256 toIndex
    )
        external
        view
        returns (
            uint256 newAmountQ,
            uint256 newAmountB,
            uint256 newAmountR
        );

    function refreshBalance(address account, uint256 targetVersion) external;

    function refreshAllowance(
        address owner,
        address spender,
        uint256 targetVersion
    ) external;

    function shareTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) external;

    function shareTransferFrom(
        address spender,
        address sender,
        address recipient,
        uint256 amount
    ) external returns (uint256 newAllowance);

    function shareIncreaseAllowance(
        address sender,
        address spender,
        uint256 addedValue
    ) external returns (uint256 newAllowance);

    function shareDecreaseAllowance(
        address sender,
        address spender,
        uint256 subtractedValue
    ) external returns (uint256 newAllowance);

    function shareApprove(
        address owner,
        address spender,
        uint256 amount
    ) external;

    function historicalUnderlying(uint256 timestamp) external view returns (uint256);

    function getTotalUnderlying() external view returns (uint256);

    function getStrategyUnderlying() external view returns (uint256);

    function getTotalDebt() external view returns (uint256);

    event RebalanceTriggered(
        uint256 indexed index,
        uint256 indexed day,
        uint256 navSum,
        uint256 navB,
        uint256 navROrZero,
        uint256 ratioB2Q,
        uint256 ratioR2Q,
        uint256 ratioBR
    );
    event Settled(uint256 indexed day, uint256 navB, uint256 navR, uint256 interestRate);
    event InterestRateUpdated(uint256 baseInterestRate, uint256 floatingInterestRate);
    event BalancesRebalanced(
        address indexed account,
        uint256 version,
        uint256 balanceQ,
        uint256 balanceB,
        uint256 balanceR
    );
    event AllowancesRebalanced(
        address indexed owner,
        address indexed spender,
        uint256 version,
        uint256 allowanceQ,
        uint256 allowanceB,
        uint256 allowanceR
    );
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;

import "./ITwapOracle.sol";

interface ITwapOracleV2 is ITwapOracle {
    function getLatest() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;

interface ITwapOracle {
    enum UpdateType {PRIMARY, SECONDARY, OWNER, CHAINLINK, UNISWAP_V2}

    function getTwap(uint256 timestamp) external view returns (uint256);
}