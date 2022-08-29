// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;

import { BlockContext } from "./utils/BlockContext.sol";
import { IPriceFeed } from "./interfaces/IPriceFeed.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { IAmm } from "./interfaces/IAmm.sol";
import { IntMath } from "./utils/IntMath.sol";
import { UIntMath } from "./utils/UIntMath.sol";
import { FullMath } from "./utils/FullMath.sol";
import { AmmMath } from "./utils/AmmMath.sol";

contract Amm is IAmm, OwnableUpgradeable, BlockContext {
    using UIntMath for uint256;
    using IntMath for int256;

    //
    // CONSTANT
    //
    // because position decimal rounding error,
    // if the position size is less than IGNORABLE_DIGIT_FOR_SHUTDOWN, it's equal size is 0
    uint256 private constant IGNORABLE_DIGIT_FOR_SHUTDOWN = 100;

    // a margin to prevent from rounding when calc liquidity multiplier limit
    uint256 private constant MARGIN_FOR_LIQUIDITY_MIGRATION_ROUNDING = 1e9;

    //
    // EVENTS
    //
    event SwapInput(Dir dir, uint256 quoteAssetAmount, uint256 baseAssetAmount);
    event SwapOutput(Dir dir, uint256 quoteAssetAmount, uint256 baseAssetAmount);
    event FundingRateUpdated(int256 rate, uint256 underlyingPrice);
    event ReserveSnapshotted(uint256 quoteAssetReserve, uint256 baseAssetReserve, uint256 timestamp);
    event LiquidityChanged(uint256 quoteReserve, uint256 baseReserve, int256 cumulativeNotional);
    event CapChanged(uint256 maxHoldingBaseAsset, uint256 openInterestNotionalCap);
    event Shutdown(uint256 settlementPrice);
    event PriceFeedUpdated(address priceFeed);
    event ReservesAdjusted(uint256 quoteAssetReserve, uint256 baseAssetReserve);

    //
    // MODIFIERS
    //
    modifier onlyOpen() {
        require(open, "amm was closed");
        _;
    }

    modifier onlyCounterParty() {
        require(counterParty == _msgSender(), "caller is not counterParty");
        _;
    }

    //
    // enum and struct
    //
    struct ReserveSnapshot {
        uint256 quoteAssetReserve;
        uint256 baseAssetReserve;
        uint256 timestamp;
        uint256 blockNumber;
    }

    // internal usage
    enum QuoteAssetDir {
        QUOTE_IN,
        QUOTE_OUT
    }
    // internal usage
    enum TwapCalcOption {
        RESERVE_ASSET,
        INPUT_ASSET
    }

    // To record current base/quote asset to calculate TWAP

    struct TwapInputAsset {
        Dir dir;
        uint256 assetAmount;
        QuoteAssetDir inOrOut;
    }

    struct TwapPriceCalcParams {
        TwapCalcOption opt;
        uint256 snapshotIndex;
        TwapInputAsset asset;
    }

    //
    // Constant
    //
    // 10%
    uint256 public constant MAX_ORACLE_SPREAD_RATIO = 1e17;

    //**********************************************************//
    //    The below state variables can not change the order    //
    //**********************************************************//

    // // DEPRECATED
    // // update during every swap and calculate total amm pnl per funding period
    // int256 private baseAssetDeltaThisFundingPeriod;

    // update during every swap and used when shutting amm down. it's trader's total base asset size
    int256 public totalPositionSize;

    // latest funding rate = ((twap market price - twap oracle price) / twap oracle price) / 24
    int256 public fundingRate;

    int256 private cumulativeNotional;

    uint256 private settlementPrice;
    uint256 public tradeLimitRatio;
    uint256 public quoteAssetReserve;
    uint256 public baseAssetReserve;
    uint256 public fluctuationLimitRatio;

    // owner can update
    uint256 public tollRatio;
    uint256 public spreadRatio;
    uint256 public tollAmount;
    uint256 private maxHoldingBaseAsset;
    uint256 private openInterestNotionalCap;

    // init cumulativePositionMultiplier is 1, will be updated every time when amm reserve increase/decrease
    uint256 private cumulativePositionMultiplier;

    // snapshot of amm reserve when change liquidity's invariant
    LiquidityChangedSnapshot[] private liquidityChangedSnapshots;

    uint256 public spotPriceTwapInterval;
    uint256 public fundingPeriod;
    uint256 public fundingBufferPeriod;
    uint256 public nextFundingTime;
    bytes32 public priceFeedKey;
    ReserveSnapshot[] public reserveSnapshots;

    address private counterParty;
    address public globalShutdown;
    IERC20 public override quoteAsset;
    IPriceFeed public priceFeed;
    bool public override open;
    bool public override adjustable;
    bool public canLowerK;
    uint256[50] private __gap;

    //**********************************************************//
    //    The above state variables can not change the order    //
    //**********************************************************//

    //◥◤◥◤◥◤◥◤◥◤◥◤◥◤◥◤ add state variables below ◥◤◥◤◥◤◥◤◥◤◥◤◥◤◥◤//

    //◢◣◢◣◢◣◢◣◢◣◢◣◢◣◢◣ add state variables above ◢◣◢◣◢◣◢◣◢◣◢◣◢◣◢◣//

    //
    // FUNCTIONS
    //
    function initialize(
        uint256 _quoteAssetReserve,
        uint256 _baseAssetReserve,
        uint256 _tradeLimitRatio,
        uint256 _fundingPeriod,
        IPriceFeed _priceFeed,
        bytes32 _priceFeedKey,
        address _quoteAsset,
        uint256 _fluctuationLimitRatio,
        uint256 _tollRatio,
        uint256 _spreadRatio
    ) public initializer {
        require(
            _quoteAssetReserve != 0 &&
                _tradeLimitRatio != 0 &&
                _baseAssetReserve != 0 &&
                _fundingPeriod != 0 &&
                address(_priceFeed) != address(0) &&
                _quoteAsset != address(0),
            "invalid input"
        );
        __Ownable_init();

        quoteAssetReserve = _quoteAssetReserve;
        baseAssetReserve = _baseAssetReserve;
        tradeLimitRatio = _tradeLimitRatio;
        tollRatio = _tollRatio;
        spreadRatio = _spreadRatio;
        fluctuationLimitRatio = _fluctuationLimitRatio;
        fundingPeriod = _fundingPeriod;
        fundingBufferPeriod = _fundingPeriod / 2;
        spotPriceTwapInterval = 1 hours;
        priceFeedKey = _priceFeedKey;
        quoteAsset = IERC20(_quoteAsset);
        priceFeed = _priceFeed;
        cumulativePositionMultiplier = 1 ether;
        liquidityChangedSnapshots.push(
            LiquidityChangedSnapshot({
                cumulativeNotional: 0,
                baseAssetReserve: baseAssetReserve,
                quoteAssetReserve: quoteAssetReserve,
                totalPositionSize: 0
            })
        );
        reserveSnapshots.push(ReserveSnapshot(quoteAssetReserve, baseAssetReserve, _blockTimestamp(), _blockNumber()));
        emit ReserveSnapshotted(quoteAssetReserve, baseAssetReserve, _blockTimestamp());
    }

    /**
     * @notice Swap your quote asset to base asset, the impact of the price MUST be less than `fluctuationLimitRatio`
     * @dev Only clearingHouse can call this function
     * @param _dirOfQuote ADD_TO_AMM for long, REMOVE_FROM_AMM for short
     * @param _quoteAssetAmount quote asset amount
     * @param _baseAssetAmountLimit minimum base asset amount expected to get to prevent front running
     * @param _canOverFluctuationLimit if tx can go over fluctuation limit once; for partial liquidation
     * @return base asset amount
     */
    function swapInput(
        Dir _dirOfQuote,
        uint256 _quoteAssetAmount,
        uint256 _baseAssetAmountLimit,
        bool _canOverFluctuationLimit
    ) external override onlyOpen onlyCounterParty returns (uint256) {
        if (_quoteAssetAmount == 0) {
            return 0;
        }
        if (_dirOfQuote == Dir.REMOVE_FROM_AMM) {
            require(quoteAssetReserve.mulD(tradeLimitRatio) >= _quoteAssetAmount, "over trading limit");
        }

        uint256 baseAssetAmount = getInputPrice(_dirOfQuote, _quoteAssetAmount);
        // If LONG, exchanged base amount should be more than _baseAssetAmountLimit,
        // otherwise(SHORT), exchanged base amount should be less than _baseAssetAmountLimit.
        // In SHORT case, more position means more debt so should not be larger than _baseAssetAmountLimit
        if (_baseAssetAmountLimit != 0) {
            if (_dirOfQuote == Dir.ADD_TO_AMM) {
                require(baseAssetAmount >= _baseAssetAmountLimit, "Less than minimal base token");
            } else {
                require(baseAssetAmount <= _baseAssetAmountLimit, "More than maximal base token");
            }
        }

        updateReserve(_dirOfQuote, _quoteAssetAmount, baseAssetAmount, _canOverFluctuationLimit);
        emit SwapInput(_dirOfQuote, _quoteAssetAmount, baseAssetAmount);
        return baseAssetAmount;
    }

    /**
     * @notice swap your base asset to quote asset; NOTE it is only used during close/liquidate positions so it always allows going over fluctuation limit
     * @dev only clearingHouse can call this function
     * @param _dirOfBase ADD_TO_AMM for short, REMOVE_FROM_AMM for long, opposite direction from swapInput
     * @param _baseAssetAmount base asset amount
     * @param _quoteAssetAmountLimit limit of quote asset amount; for slippage protection
     * @return quote asset amount
     */
    function swapOutput(
        Dir _dirOfBase,
        uint256 _baseAssetAmount,
        uint256 _quoteAssetAmountLimit
    ) external override onlyOpen onlyCounterParty returns (uint256) {
        return implSwapOutput(_dirOfBase, _baseAssetAmount, _quoteAssetAmountLimit);
    }

    /**
     * @notice update funding rate
     * @dev only allow to update while reaching `nextFundingTime`
     * @param _cap the limit of expense of funding payment
     * @return premiumFraction premium fraction of this period in 18 digits
     * @return fundingPayment profit of insurance fund in funding payment
     * @return uncappedFundingPayment imbalance cost of funding payment without cap
     */
    function settleFunding(uint256 _cap)
        external
        override
        onlyOpen
        onlyCounterParty
        returns (
            int256 premiumFraction,
            int256 fundingPayment,
            int256 uncappedFundingPayment
        )
    {
        require(_blockTimestamp() >= nextFundingTime, "settle funding too early");
        uint256 latestPricetimestamp = priceFeed.getLatestTimestamp(priceFeedKey);
        require(_blockTimestamp() < latestPricetimestamp + 30 * 60, "oracle price is expired");

        // premium = twapMarketPrice - twapIndexPrice
        // timeFraction = fundingPeriod(1 hour) / 1 day
        // premiumFraction = premium * timeFraction
        uint256 underlyingPrice = getUnderlyingTwapPrice(spotPriceTwapInterval);
        int256 premium = getTwapPrice(spotPriceTwapInterval).toInt() - underlyingPrice.toInt();
        premiumFraction = (premium * fundingPeriod.toInt()) / int256(1 days);
        int256 positionSize = totalPositionSize; // to optimize gas
        // funding payment = premium fraction * position
        // eg. if alice takes 10 long position, totalPositionSize = 10
        // if premiumFraction is positive: long pay short, amm get positive funding payment
        // if premiumFraction is negative: short pay long, amm get negative funding payment
        // if totalPositionSize.side * premiumFraction > 0, funding payment is positive which means profit
        uncappedFundingPayment = premiumFraction.mulD(positionSize);
        // if expense of funding payment is greater than cap amount, then cap it
        if (uncappedFundingPayment < 0 && uint256(-uncappedFundingPayment) > _cap) {
            premiumFraction = int256(_cap).divD(positionSize) * (-1);
            fundingPayment = int256(_cap) * (-1);
        } else {
            fundingPayment = uncappedFundingPayment;
        }

        // update funding rate = premiumFraction / twapIndexPrice
        updateFundingRate(premiumFraction, underlyingPrice);

        // in order to prevent multiple funding settlement during very short time after network congestion
        uint256 minNextValidFundingTime = _blockTimestamp() + fundingBufferPeriod;

        // floor((nextFundingTime + fundingPeriod) / 3600) * 3600
        uint256 nextFundingTimeOnHourStart = ((nextFundingTime + fundingPeriod) / (1 hours)) * (1 hours);

        // max(nextFundingTimeOnHourStart, minNextValidFundingTime)
        nextFundingTime = nextFundingTimeOnHourStart > minNextValidFundingTime ? nextFundingTimeOnHourStart : minNextValidFundingTime;

        // // DEPRECATED only for backward compatibility before we upgrade ClearingHouse
        // // reset funding related states
        // baseAssetDeltaThisFundingPeriod = 0;

        // return premiumFraction;
    }

    /**
     * Repeg both reserves in case of repegging and k-adjustment
     */
    function adjust(uint256 _quoteAssetReserve, uint256 _baseAssetReserve) external onlyCounterParty {
        require(_quoteAssetReserve != 0, "quote asset reserve cannot be 0");
        require(_baseAssetReserve != 0, "base asset reserve cannot be 0");
        quoteAssetReserve = _quoteAssetReserve;
        baseAssetReserve = _baseAssetReserve;
        addReserveSnapshot();
        liquidityChangedSnapshots.push(
            LiquidityChangedSnapshot({
                cumulativeNotional: cumulativeNotional,
                baseAssetReserve: _baseAssetReserve,
                quoteAssetReserve: _quoteAssetReserve,
                totalPositionSize: totalPositionSize
            })
        );
        emit ReservesAdjusted(quoteAssetReserve, baseAssetReserve);
    }

    function calcBaseAssetAfterLiquidityMigration(
        int256 _baseAssetAmount,
        uint256 _fromQuoteReserve,
        uint256 _fromBaseReserve
    ) public view override returns (int256) {
        if (_baseAssetAmount == 0) {
            return _baseAssetAmount;
        }

        bool isPositiveValue = _baseAssetAmount > 0 ? true : false;

        // measure the trader position's notional value on the old curve
        // (by simulating closing the position)
        uint256 posNotional = getOutputPriceWithReserves(
            isPositiveValue ? Dir.ADD_TO_AMM : Dir.REMOVE_FROM_AMM,
            _baseAssetAmount.abs(),
            _fromQuoteReserve,
            _fromBaseReserve
        );

        // calculate and apply the required size on the new curve
        int256 newBaseAsset = getInputPrice(isPositiveValue ? Dir.REMOVE_FROM_AMM : Dir.ADD_TO_AMM, posNotional).toInt();
        return newBaseAsset * (isPositiveValue ? int256(1) : int256(-1));
    }

    /**
     * @notice shutdown amm,
     * @dev only `globalShutdown` or owner can call this function
     * The price calculation is in `globalShutdown`.
     */
    function shutdown() external override {
        require(_msgSender() == owner() || _msgSender() == globalShutdown, "not owner nor globalShutdown");
        implShutdown();
    }

    /**
     * @notice set counter party
     * @dev only owner can call this function
     * @param _counterParty address of counter party
     */
    function setCounterParty(address _counterParty) external onlyOwner {
        counterParty = _counterParty;
    }

    /**
     * @notice set `globalShutdown`
     * @dev only owner can call this function
     * @param _globalShutdown address of `globalShutdown`
     */
    function setGlobalShutdown(address _globalShutdown) external onlyOwner {
        globalShutdown = _globalShutdown;
    }

    /**
     * @notice set fluctuation limit rate. Default value is `1 / max leverage`
     * @dev only owner can call this function
     * @param _fluctuationLimitRatio fluctuation limit rate in 18 digits, 0 means skip the checking
     */
    function setFluctuationLimitRatio(uint256 _fluctuationLimitRatio) public onlyOwner {
        fluctuationLimitRatio = _fluctuationLimitRatio;
    }

    /**
     * @notice set time interval for twap calculation, default is 1 hour
     * @dev only owner can call this function
     * @param _interval time interval in seconds
     */
    function setSpotPriceTwapInterval(uint256 _interval) external onlyOwner {
        require(_interval != 0, "can not set interval to 0");
        spotPriceTwapInterval = _interval;
    }

    /**
     * @notice set `open` flag. Amm is open to trade if `open` is true. Default is false.
     * @dev only owner can call this function
     * @param _open open to trade is true, otherwise is false.
     */
    function setOpen(bool _open) external onlyOwner {
        if (open == _open) return;

        open = _open;
        if (_open) {
            nextFundingTime = ((_blockTimestamp() + fundingPeriod) / (1 hours)) * (1 hours);
        }
    }

    /**
     * @notice set `adjustable` flag. Amm is open to formulaic repeg and K adjustment if `adjustable` is true. Default is false.
     * @dev only owner can call this function
     * @param _adjustable open to formulaic repeg and K adjustment is true, otherwise is false.
     */
    function setAdjustable(bool _adjustable) external onlyOwner {
        if (adjustable == _adjustable) return;
        adjustable = _adjustable;
    }

    /**
     * @notice set `canLowerK` flag. Amm is open to decrease K adjustment if `canLowerK` is true. Default is false.
     * @dev only owner can call this function
     * @param _canLowerK open to decrease K adjustment is true, otherwise is false.
     */
    function setCanLowerK(bool _canLowerK) external onlyOwner {
        if (canLowerK == _canLowerK) return;
        canLowerK = _canLowerK;
    }

    /**
     * @notice set new toll ratio
     * @dev only owner can call
     * @param _tollRatio new toll ratio in 18 digits
     */
    function setTollRatio(uint256 _tollRatio) public onlyOwner {
        tollRatio = _tollRatio;
    }

    /**
     * @notice set new spread ratio
     * @dev only owner can call
     * @param _spreadRatio new toll spread in 18 digits
     */
    function setSpreadRatio(uint256 _spreadRatio) public onlyOwner {
        spreadRatio = _spreadRatio;
    }

    /**
     * @notice set new cap during guarded period, which is max position size that traders can hold
     * @dev only owner can call. assume this will be removes soon once the guarded period has ended. must be set before opening amm
     * @param _maxHoldingBaseAsset max position size that traders can hold in 18 digits
     * @param _openInterestNotionalCap open interest cap, denominated in quoteToken
     */
    function setCap(uint256 _maxHoldingBaseAsset, uint256 _openInterestNotionalCap) public onlyOwner {
        maxHoldingBaseAsset = _maxHoldingBaseAsset;
        openInterestNotionalCap = _openInterestNotionalCap;
        emit CapChanged(maxHoldingBaseAsset, openInterestNotionalCap);
    }

    /**
     * @notice set priceFee address
     * @dev only owner can call
     * @param _priceFeed new price feed for this AMM
     */
    function setPriceFeed(IPriceFeed _priceFeed) public onlyOwner {
        require(address(_priceFeed) != address(0), "invalid PriceFeed address");
        priceFeed = _priceFeed;
        emit PriceFeedUpdated(address(priceFeed));
    }

    //
    // VIEW FUNCTIONS
    //
    function getFormulaicRepegResult(uint256 _budget, bool _adjustK)
        external
        view
        override
        returns (
            bool isAdjustable,
            int256 cost,
            uint256 newQuoteAssetReserve,
            uint256 newBaseAssetReserve
        )
    {
        if (open && adjustable && isOverSpreadLimit()) {
            uint256 targetPrice = getUnderlyingPrice();
            uint256 _quoteAssetReserve = quoteAssetReserve; //to optimize gas cost
            uint256 _baseAssetReserve = baseAssetReserve; //to optimize gas cost
            int256 _positionSize = totalPositionSize; //to optimize gas cost
            newBaseAssetReserve = _baseAssetReserve;
            newQuoteAssetReserve = targetPrice.mulD(newBaseAssetReserve);
            cost = AmmMath.adjustPegCost(_quoteAssetReserve, newBaseAssetReserve, _positionSize, newQuoteAssetReserve);
            if (cost > 0 && uint256(cost) > _budget) {
                if (_adjustK && canLowerK) {
                    // scale down K by 0.1% that returns a profit of clearing house
                    (cost, newQuoteAssetReserve, newBaseAssetReserve) = AmmMath.adjustKCost(
                        _quoteAssetReserve,
                        _baseAssetReserve,
                        _positionSize,
                        999,
                        1000
                    );
                    isAdjustable = true;
                } else {
                    isAdjustable = false;
                    // newQuoteAssetReserve = AmmMath.calcBudgetedQuoteReserve(_quoteAssetReserve, _baseAssetReserve, _positionSize, _budget);
                    // cost = _budget.toInt();
                }
            } else {
                isAdjustable = newQuoteAssetReserve != _quoteAssetReserve;
            }
        }
    }

    function getFormulaicUpdateKResult(int256 _budget)
        external
        view
        returns (
            bool isAdjustable,
            int256 cost,
            uint256 newQuoteAssetReserve,
            uint256 newBaseAssetReserve
        )
    {
        if (open && adjustable && (_budget > 0 || (_budget < 0 && canLowerK))) {
            uint256 _quoteAssetReserve = quoteAssetReserve; //to optimize gas cost
            uint256 _baseAssetReserve = baseAssetReserve; //to optimize gas cost
            int256 _positionSize = totalPositionSize; //to optimize gas cost
            (uint256 scaleNum, uint256 scaleDenom) = AmmMath.calculateBudgetedKScale(
                _quoteAssetReserve,
                _baseAssetReserve,
                _budget,
                _positionSize
            );
            if (scaleNum == scaleDenom) {
                isAdjustable = false;
            } else {
                isAdjustable = true;
                (cost, newQuoteAssetReserve, newBaseAssetReserve) = AmmMath.adjustKCost(
                    _quoteAssetReserve,
                    _baseAssetReserve,
                    _positionSize,
                    scaleNum,
                    scaleDenom
                );
            }
        }
    }

    function isOverFluctuationLimit(Dir _dirOfBase, uint256 _baseAssetAmount) external view override returns (bool) {
        // Skip the check if the limit is 0
        if (fluctuationLimitRatio == 0) {
            return false;
        }

        (uint256 upperLimit, uint256 lowerLimit) = getPriceBoundariesOfLastBlock();

        uint256 quoteAssetExchanged = getOutputPrice(_dirOfBase, _baseAssetAmount);
        uint256 price = (_dirOfBase == Dir.REMOVE_FROM_AMM)
            ? (quoteAssetReserve + quoteAssetExchanged).divD(baseAssetReserve - _baseAssetAmount)
            : (quoteAssetReserve - quoteAssetExchanged).divD(baseAssetReserve + _baseAssetAmount);

        if (price <= upperLimit && price >= lowerLimit) {
            return false;
        }
        return true;
    }

    /**
     * @notice get input twap amount.
     * returns how many base asset you will get with the input quote amount based on twap price.
     * @param _dirOfQuote ADD_TO_AMM for long, REMOVE_FROM_AMM for short.
     * @param _quoteAssetAmount quote asset amount
     * @return base asset amount
     */
    function getInputTwap(Dir _dirOfQuote, uint256 _quoteAssetAmount) public view override returns (uint256) {
        return implGetInputAssetTwapPrice(_dirOfQuote, _quoteAssetAmount, QuoteAssetDir.QUOTE_IN, 15 minutes);
    }

    /**
     * @notice get output twap amount.
     * return how many quote asset you will get with the input base amount on twap price.
     * @param _dirOfBase ADD_TO_AMM for short, REMOVE_FROM_AMM for long, opposite direction from `getInputTwap`.
     * @param _baseAssetAmount base asset amount
     * @return quote asset amount
     */
    function getOutputTwap(Dir _dirOfBase, uint256 _baseAssetAmount) public view override returns (uint256) {
        return implGetInputAssetTwapPrice(_dirOfBase, _baseAssetAmount, QuoteAssetDir.QUOTE_OUT, 15 minutes);
    }

    /**
     * @notice get input amount. returns how many base asset you will get with the input quote amount.
     * @param _dirOfQuote ADD_TO_AMM for long, REMOVE_FROM_AMM for short.
     * @param _quoteAssetAmount quote asset amount
     * @return base asset amount
     */
    function getInputPrice(Dir _dirOfQuote, uint256 _quoteAssetAmount) public view override returns (uint256) {
        return getInputPriceWithReserves(_dirOfQuote, _quoteAssetAmount, quoteAssetReserve, baseAssetReserve);
    }

    /**
     * @notice get output price. return how many quote asset you will get with the input base amount
     * @param _dirOfBase ADD_TO_AMM for short, REMOVE_FROM_AMM for long, opposite direction from `getInput`.
     * @param _baseAssetAmount base asset amount
     * @return quote asset amount
     */
    function getOutputPrice(Dir _dirOfBase, uint256 _baseAssetAmount) public view override returns (uint256) {
        return getOutputPriceWithReserves(_dirOfBase, _baseAssetAmount, quoteAssetReserve, baseAssetReserve);
    }

    /**
     * @notice get underlying price provided by oracle
     * @return underlying price
     */
    function getUnderlyingPrice() public view override returns (uint256) {
        return uint256(priceFeed.getPrice(priceFeedKey));
    }

    /**
     * @notice get underlying twap price provided by oracle
     * @return underlying price
     */
    function getUnderlyingTwapPrice(uint256 _intervalInSeconds) public view returns (uint256) {
        return uint256(priceFeed.getTwapPrice(priceFeedKey, _intervalInSeconds));
    }

    /**
     * @notice get spot price based on current quote/base asset reserve.
     * @return spot price
     */
    function getSpotPrice() public view override returns (uint256) {
        return quoteAssetReserve.divD(baseAssetReserve);
    }

    /**
     * @notice get twap price
     */
    function getTwapPrice(uint256 _intervalInSeconds) public view returns (uint256) {
        return implGetReserveTwapPrice(_intervalInSeconds);
    }

    /**
     * @notice get current quote/base asset reserve.
     * @return (quote asset reserve, base asset reserve)
     */
    function getReserve() external view returns (uint256, uint256) {
        return (quoteAssetReserve, baseAssetReserve);
    }

    function getSnapshotLen() external view returns (uint256) {
        return reserveSnapshots.length;
    }

    function getLiquidityHistoryLength() external view override returns (uint256) {
        return liquidityChangedSnapshots.length;
    }

    function getCumulativeNotional() external view override returns (int256) {
        return cumulativeNotional;
    }

    function getLatestLiquidityChangedSnapshots() public view returns (LiquidityChangedSnapshot memory) {
        return liquidityChangedSnapshots[liquidityChangedSnapshots.length - 1];
    }

    function getLiquidityChangedSnapshots(uint256 i) external view override returns (LiquidityChangedSnapshot memory) {
        require(i < liquidityChangedSnapshots.length, "incorrect index");
        return liquidityChangedSnapshots[i];
    }

    function getSettlementPrice() external view override returns (uint256) {
        return settlementPrice;
    }

    // // DEPRECATED only for backward compatibility before we upgrade ClearingHouse
    // function getBaseAssetDeltaThisFundingPeriod() external view override returns (int256) {
    //     return baseAssetDeltaThisFundingPeriod;
    // }

    function getMaxHoldingBaseAsset() external view override returns (uint256) {
        return maxHoldingBaseAsset;
    }

    function getOpenInterestNotionalCap() external view override returns (uint256) {
        return openInterestNotionalCap;
    }

    function getBaseAssetDelta() external view override returns (int256) {
        return totalPositionSize;
    }

    function isOverSpreadLimit() public view override returns (bool) {
        uint256 oraclePrice = getUnderlyingPrice();
        require(oraclePrice > 0, "underlying price is 0");
        uint256 marketPrice = getSpotPrice();
        uint256 oracleSpreadRatioAbs = (marketPrice.toInt() - oraclePrice.toInt()).divD(oraclePrice.toInt()).abs();

        return oracleSpreadRatioAbs >= MAX_ORACLE_SPREAD_RATIO ? true : false;
    }

    /**
     * @notice calculate total fee (including toll and spread) by input quoteAssetAmount
     * @param _quoteAssetAmount quoteAssetAmount
     * @return total tx fee
     */
    function calcFee(uint256 _quoteAssetAmount) external view override returns (uint256, uint256) {
        if (_quoteAssetAmount == 0) {
            return (0, 0);
        }
        return (_quoteAssetAmount.mulD(tollRatio), _quoteAssetAmount.mulD(spreadRatio));
    }

    /*       plus/minus 1 while the amount is not dividable
     *
     *        getInputPrice                         getOutputPrice
     *
     *     ＡＤＤ      (amount - 1)              (amount + 1)   ＲＥＭＯＶＥ
     *      ◥◤            ▲                         |             ◢◣
     *      ◥◤  ------->  |                         ▼  <--------  ◢◣
     *    -------      -------                   -------        -------
     *    |  Q  |      |  B  |                   |  Q  |        |  B  |
     *    -------      -------                   -------        -------
     *      ◥◤  ------->  ▲                         |  <--------  ◢◣
     *      ◥◤            |                         ▼             ◢◣
     *   ＲＥＭＯＶＥ  (amount + 1)              (amount + 1)      ＡＤＤ
     **/

    function getInputPriceWithReserves(
        Dir _dirOfQuote,
        uint256 _quoteAssetAmount,
        uint256 _quoteAssetPoolAmount,
        uint256 _baseAssetPoolAmount
    ) public pure override returns (uint256) {
        if (_quoteAssetAmount == 0) {
            return 0;
        }

        bool isAddToAmm = _dirOfQuote == Dir.ADD_TO_AMM;
        uint256 baseAssetAfter;
        uint256 quoteAssetAfter;
        uint256 baseAssetBought;
        if (isAddToAmm) {
            quoteAssetAfter = _quoteAssetPoolAmount + _quoteAssetAmount;
        } else {
            quoteAssetAfter = _quoteAssetPoolAmount - _quoteAssetAmount;
        }
        require(quoteAssetAfter != 0, "quote asset after is 0");

        baseAssetAfter = FullMath.mulDiv(_quoteAssetPoolAmount, _baseAssetPoolAmount, quoteAssetAfter);
        baseAssetBought = (baseAssetAfter.toInt() - _baseAssetPoolAmount.toInt()).abs();

        // if the amount is not dividable, return 1 wei less for trader
        if (
            FullMath.mulDiv(_quoteAssetPoolAmount, _baseAssetPoolAmount, quoteAssetAfter) !=
            FullMath.mulDivRoundingUp(_quoteAssetPoolAmount, _baseAssetPoolAmount, quoteAssetAfter)
        ) {
            if (isAddToAmm) {
                baseAssetBought = baseAssetBought - 1;
            } else {
                baseAssetBought = baseAssetBought + 1;
            }
        }

        return baseAssetBought;
    }

    function getOutputPriceWithReserves(
        Dir _dirOfBase,
        uint256 _baseAssetAmount,
        uint256 _quoteAssetPoolAmount,
        uint256 _baseAssetPoolAmount
    ) public pure override returns (uint256) {
        if (_baseAssetAmount == 0) {
            return 0;
        }

        bool isAddToAmm = _dirOfBase == Dir.ADD_TO_AMM;
        uint256 quoteAssetAfter;
        uint256 baseAssetAfter;
        uint256 quoteAssetSold;

        if (isAddToAmm) {
            baseAssetAfter = _baseAssetPoolAmount + _baseAssetAmount;
        } else {
            baseAssetAfter = _baseAssetPoolAmount - _baseAssetAmount;
        }
        require(baseAssetAfter != 0, "base asset after is 0");

        quoteAssetAfter = FullMath.mulDiv(_quoteAssetPoolAmount, _baseAssetPoolAmount, baseAssetAfter);
        quoteAssetSold = (quoteAssetAfter.toInt() - _quoteAssetPoolAmount.toInt()).abs();

        // if the amount is not dividable, return 1 wei less for trader
        if (
            FullMath.mulDiv(_quoteAssetPoolAmount, _baseAssetPoolAmount, baseAssetAfter) !=
            FullMath.mulDivRoundingUp(_quoteAssetPoolAmount, _baseAssetPoolAmount, baseAssetAfter)
        ) {
            if (isAddToAmm) {
                quoteAssetSold = quoteAssetSold - 1;
            } else {
                quoteAssetSold = quoteAssetSold + 1;
            }
        }

        return quoteAssetSold;
    }

    //
    // INTERNAL FUNCTIONS
    //
    // update funding rate = premiumFraction / twapIndexPrice
    function updateFundingRate(int256 _premiumFraction, uint256 _underlyingPrice) private {
        fundingRate = _premiumFraction.divD(_underlyingPrice.toInt());
        emit FundingRateUpdated(fundingRate, _underlyingPrice);
    }

    function addReserveSnapshot() internal {
        uint256 currentBlock = _blockNumber();
        ReserveSnapshot storage latestSnapshot = reserveSnapshots[reserveSnapshots.length - 1];
        // update values in snapshot if in the same block
        if (currentBlock == latestSnapshot.blockNumber) {
            latestSnapshot.quoteAssetReserve = quoteAssetReserve;
            latestSnapshot.baseAssetReserve = baseAssetReserve;
        } else {
            reserveSnapshots.push(ReserveSnapshot(quoteAssetReserve, baseAssetReserve, _blockTimestamp(), currentBlock));
        }
        emit ReserveSnapshotted(quoteAssetReserve, baseAssetReserve, _blockTimestamp());
    }

    function implSwapOutput(
        Dir _dirOfBase,
        uint256 _baseAssetAmount,
        uint256 _quoteAssetAmountLimit
    ) internal returns (uint256) {
        if (_baseAssetAmount == 0) {
            return 0;
        }
        if (_dirOfBase == Dir.REMOVE_FROM_AMM) {
            require(baseAssetReserve.mulD(tradeLimitRatio) >= _baseAssetAmount, "over trading limit");
        }

        uint256 quoteAssetAmount = getOutputPrice(_dirOfBase, _baseAssetAmount);
        Dir dirOfQuote = _dirOfBase == Dir.ADD_TO_AMM ? Dir.REMOVE_FROM_AMM : Dir.ADD_TO_AMM;
        // If SHORT, exchanged quote amount should be less than _quoteAssetAmountLimit,
        // otherwise(LONG), exchanged base amount should be more than _quoteAssetAmountLimit.
        // In the SHORT case, more quote assets means more payment so should not be more than _quoteAssetAmountLimit
        if (_quoteAssetAmountLimit != 0) {
            if (dirOfQuote == Dir.REMOVE_FROM_AMM) {
                // SHORT
                require(quoteAssetAmount >= _quoteAssetAmountLimit, "Less than minimal quote token");
            } else {
                // LONG
                require(quoteAssetAmount <= _quoteAssetAmountLimit, "More than maximal quote token");
            }
        }

        // as mentioned in swapOutput(), it always allows going over fluctuation limit because
        // it is only used by close/liquidate positions
        updateReserve(dirOfQuote, quoteAssetAmount, _baseAssetAmount, true);
        emit SwapOutput(_dirOfBase, quoteAssetAmount, _baseAssetAmount);
        return quoteAssetAmount;
    }

    // the direction is in quote asset
    function updateReserve(
        Dir _dirOfQuote,
        uint256 _quoteAssetAmount,
        uint256 _baseAssetAmount,
        bool _canOverFluctuationLimit
    ) internal {
        // check if it's over fluctuationLimitRatio
        // this check should be before reserves being updated
        checkIsOverBlockFluctuationLimit(_dirOfQuote, _quoteAssetAmount, _baseAssetAmount, _canOverFluctuationLimit);

        if (_dirOfQuote == Dir.ADD_TO_AMM) {
            quoteAssetReserve = quoteAssetReserve + _quoteAssetAmount;
            baseAssetReserve = baseAssetReserve - _baseAssetAmount;
            // DEPRECATED only for backward compatibility before we upgrade ClearingHouse
            // baseAssetDeltaThisFundingPeriod = baseAssetDeltaThisFundingPeriod - _baseAssetAmount.toInt();
            totalPositionSize = totalPositionSize + _baseAssetAmount.toInt();
            cumulativeNotional = cumulativeNotional + _quoteAssetAmount.toInt();
        } else {
            quoteAssetReserve = quoteAssetReserve - _quoteAssetAmount;
            baseAssetReserve = baseAssetReserve + _baseAssetAmount;
            // // DEPRECATED only for backward compatibility before we upgrade ClearingHouse
            // baseAssetDeltaThisFundingPeriod = baseAssetDeltaThisFundingPeriod + _baseAssetAmount.toInt();
            totalPositionSize = totalPositionSize - _baseAssetAmount.toInt();
            cumulativeNotional = cumulativeNotional - _quoteAssetAmount.toInt();
        }

        // addReserveSnapshot must be after checking price fluctuation
        addReserveSnapshot();
    }

    function implGetInputAssetTwapPrice(
        Dir _dirOfQuote,
        uint256 _assetAmount,
        QuoteAssetDir _inOut,
        uint256 _interval
    ) internal view returns (uint256) {
        TwapPriceCalcParams memory params;
        params.opt = TwapCalcOption.INPUT_ASSET;
        params.snapshotIndex = reserveSnapshots.length - 1;
        params.asset.dir = _dirOfQuote;
        params.asset.assetAmount = _assetAmount;
        params.asset.inOrOut = _inOut;
        return calcTwap(params, _interval);
    }

    function implGetReserveTwapPrice(uint256 _interval) internal view returns (uint256) {
        TwapPriceCalcParams memory params;
        params.opt = TwapCalcOption.RESERVE_ASSET;
        params.snapshotIndex = reserveSnapshots.length - 1;
        return calcTwap(params, _interval);
    }

    function calcTwap(TwapPriceCalcParams memory _params, uint256 _interval) internal view returns (uint256) {
        uint256 currentPrice = getPriceWithSpecificSnapshot(_params);
        if (_interval == 0) {
            return currentPrice;
        }

        uint256 baseTimestamp = _blockTimestamp() - _interval;
        ReserveSnapshot memory currentSnapshot = reserveSnapshots[_params.snapshotIndex];
        // return the latest snapshot price directly
        // if only one snapshot or the timestamp of latest snapshot is earlier than asking for
        if (reserveSnapshots.length == 1 || currentSnapshot.timestamp <= baseTimestamp) {
            return currentPrice;
        }

        uint256 previousTimestamp = currentSnapshot.timestamp;
        uint256 period = _blockTimestamp() - previousTimestamp;
        uint256 weightedPrice = currentPrice * period;
        while (true) {
            // if snapshot history is too short
            if (_params.snapshotIndex == 0) {
                return weightedPrice / period;
            }

            _params.snapshotIndex = _params.snapshotIndex - 1;
            currentSnapshot = reserveSnapshots[_params.snapshotIndex];
            currentPrice = getPriceWithSpecificSnapshot(_params);

            // check if current round timestamp is earlier than target timestamp
            if (currentSnapshot.timestamp <= baseTimestamp) {
                // weighted time period will be (target timestamp - previous timestamp). For example,
                // now is 1000, _interval is 100, then target timestamp is 900. If timestamp of current round is 970,
                // and timestamp of NEXT round is 880, then the weighted time period will be (970 - 900) = 70,
                // instead of (970 - 880)
                weightedPrice = weightedPrice + (currentPrice * (previousTimestamp - baseTimestamp));
                break;
            }

            uint256 timeFraction = previousTimestamp - currentSnapshot.timestamp;
            weightedPrice = weightedPrice + (currentPrice * timeFraction);
            period = period + timeFraction;
            previousTimestamp = currentSnapshot.timestamp;
        }
        return weightedPrice / _interval;
    }

    function getPriceWithSpecificSnapshot(TwapPriceCalcParams memory params) internal view virtual returns (uint256) {
        ReserveSnapshot memory snapshot = reserveSnapshots[params.snapshotIndex];

        // RESERVE_ASSET means price comes from quoteAssetReserve/baseAssetReserve
        // INPUT_ASSET means getInput/Output price with snapshot's reserve
        if (params.opt == TwapCalcOption.RESERVE_ASSET) {
            return snapshot.quoteAssetReserve.divD(snapshot.baseAssetReserve);
        } else if (params.opt == TwapCalcOption.INPUT_ASSET) {
            if (params.asset.assetAmount == 0) {
                return 0;
            }
            if (params.asset.inOrOut == QuoteAssetDir.QUOTE_IN) {
                return
                    getInputPriceWithReserves(
                        params.asset.dir,
                        params.asset.assetAmount,
                        snapshot.quoteAssetReserve,
                        snapshot.baseAssetReserve
                    );
            } else if (params.asset.inOrOut == QuoteAssetDir.QUOTE_OUT) {
                return
                    getOutputPriceWithReserves(
                        params.asset.dir,
                        params.asset.assetAmount,
                        snapshot.quoteAssetReserve,
                        snapshot.baseAssetReserve
                    );
            }
        }
        revert("not supported option");
    }

    function getPriceBoundariesOfLastBlock() internal view returns (uint256, uint256) {
        uint256 len = reserveSnapshots.length;
        ReserveSnapshot memory latestSnapshot = reserveSnapshots[len - 1];
        // if the latest snapshot is the same as current block, get the previous one
        if (latestSnapshot.blockNumber == _blockNumber() && len > 1) {
            latestSnapshot = reserveSnapshots[len - 2];
        }

        uint256 lastPrice = latestSnapshot.quoteAssetReserve.divD(latestSnapshot.baseAssetReserve);
        uint256 upperLimit = lastPrice.mulD(1 ether + fluctuationLimitRatio);
        uint256 lowerLimit = lastPrice.mulD(1 ether - fluctuationLimitRatio);
        return (upperLimit, lowerLimit);
    }

    /**
     * @notice there can only be one tx in a block can skip the fluctuation check
     *         otherwise, some positions can never be closed or liquidated
     * @param _canOverFluctuationLimit if true, can skip fluctuation check for once; else, can never skip
     */
    function checkIsOverBlockFluctuationLimit(
        Dir _dirOfQuote,
        uint256 _quoteAssetAmount,
        uint256 _baseAssetAmount,
        bool _canOverFluctuationLimit
    ) internal view {
        // Skip the check if the limit is 0
        if (fluctuationLimitRatio == 0) {
            return;
        }

        //
        // assume the price of the last block is 10, fluctuation limit ratio is 5%, then
        //
        //          current price
        //  --+---------+-----------+---
        //   9.5        10         10.5
        // lower limit           upper limit
        //
        // when `openPosition`, the price can only be between 9.5 - 10.5
        // when `liquidate` and `closePosition`, the price can exceed the boundary once
        // (either lower than 9.5 or higher than 10.5)
        // once it exceeds the boundary, all the rest txs in this block fail
        //

        (uint256 upperLimit, uint256 lowerLimit) = getPriceBoundariesOfLastBlock();

        uint256 price = quoteAssetReserve.divD(baseAssetReserve);
        require(price <= upperLimit && price >= lowerLimit, "price is already over fluctuation limit");

        if (!_canOverFluctuationLimit) {
            price = (_dirOfQuote == Dir.ADD_TO_AMM)
                ? (quoteAssetReserve + _quoteAssetAmount).divD(baseAssetReserve - _baseAssetAmount)
                : (quoteAssetReserve - _quoteAssetAmount).divD(baseAssetReserve + _baseAssetAmount);
            require(price <= upperLimit && price >= lowerLimit, "price is over fluctuation limit");
        }
    }

    function checkLiquidityMultiplierLimit(int256 _positionSize, uint256 _liquidityMultiplier) internal view {
        // have lower bound when position size is long
        if (_positionSize > 0) {
            uint256 liquidityMultiplierLowerBound = (_positionSize + MARGIN_FOR_LIQUIDITY_MIGRATION_ROUNDING.toInt())
                .divD(baseAssetReserve.toInt())
                .abs();
            require(_liquidityMultiplier >= liquidityMultiplierLowerBound, "illegal liquidity multiplier");
        }
    }

    function implShutdown() internal {
        LiquidityChangedSnapshot memory latestLiquiditySnapshot = getLatestLiquidityChangedSnapshots();

        // get last liquidity changed history to calc new quote/base reserve
        uint256 previousK = latestLiquiditySnapshot.baseAssetReserve.mulD(latestLiquiditySnapshot.quoteAssetReserve);
        int256 lastInitBaseReserveInNewCurve = latestLiquiditySnapshot.totalPositionSize + latestLiquiditySnapshot.baseAssetReserve.toInt();
        int256 lastInitQuoteReserveInNewCurve = previousK.toInt().divD(lastInitBaseReserveInNewCurve);

        // settlementPrice = SUM(Open Position Notional Value) / SUM(Position Size)
        // `Open Position Notional Value` = init quote reserve - current quote reserve
        // `Position Size` = init base reserve - current base reserve
        int256 positionNotionalValue = lastInitQuoteReserveInNewCurve - quoteAssetReserve.toInt();

        // if total position size less than IGNORABLE_DIGIT_FOR_SHUTDOWN, treat it as 0 positions due to rounding error
        if (totalPositionSize.toUint() > IGNORABLE_DIGIT_FOR_SHUTDOWN) {
            settlementPrice = positionNotionalValue.abs().divD(totalPositionSize.abs());
        }

        open = false;
        emit Shutdown(settlementPrice);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;

// wrap block.xxx functions for testing
// only support timestamp and number so far
abstract contract BlockContext {
    //◥◤◥◤◥◤◥◤◥◤◥◤◥◤◥◤ add state variables below ◥◤◥◤◥◤◥◤◥◤◥◤◥◤◥◤//

    //◢◣◢◣◢◣◢◣◢◣◢◣◢◣◢◣ add state variables above ◢◣◢◣◢◣◢◣◢◣◢◣◢◣◢◣//
    uint256[50] private __gap;

    function _blockTimestamp() internal view virtual returns (uint256) {
        return block.timestamp;
    }

    function _blockNumber() internal view virtual returns (uint256) {
        return block.number;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;

interface IPriceFeed {
    // get latest price
    function getPrice(bytes32 _priceFeedKey) external view returns (uint256);

    // get latest timestamp
    function getLatestTimestamp(bytes32 _priceFeedKey) external view returns (uint256);

    // get previous price with _back rounds
    function getPreviousPrice(bytes32 _priceFeedKey, uint256 _numOfRoundBack) external view returns (uint256);

    // get previous timestamp with _back rounds
    function getPreviousTimestamp(bytes32 _priceFeedKey, uint256 _numOfRoundBack) external view returns (uint256);

    // get twap price depending on _period
    function getTwapPrice(bytes32 _priceFeedKey, uint256 _interval) external view returns (uint256);

    function setLatestData(
        bytes32 _priceFeedKey,
        uint256 _price,
        uint256 _timestamp,
        uint256 _roundId
    ) external;
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IPriceFeed } from "./IPriceFeed.sol";

interface IAmm {
    /**
     * @notice asset direction, used in getInputPrice, getOutputPrice, swapInput and swapOutput
     * @param ADD_TO_AMM add asset to Amm
     * @param REMOVE_FROM_AMM remove asset from Amm
     */
    enum Dir {
        ADD_TO_AMM,
        REMOVE_FROM_AMM
    }

    struct LiquidityChangedSnapshot {
        int256 cumulativeNotional;
        // the base/quote reserve of amm right before liquidity changed
        uint256 quoteAssetReserve;
        uint256 baseAssetReserve;
        // total position size owned by amm after last snapshot taken
        // `totalPositionSize` = currentBaseAssetReserve - lastLiquidityChangedHistoryItem.baseAssetReserve + prevTotalPositionSize
        int256 totalPositionSize;
    }

    function swapInput(
        Dir _dir,
        uint256 _quoteAssetAmount,
        uint256 _baseAssetAmountLimit,
        bool _canOverFluctuationLimit
    ) external returns (uint256);

    function swapOutput(
        Dir _dir,
        uint256 _baseAssetAmount,
        uint256 _quoteAssetAmountLimit
    ) external returns (uint256);

    function adjust(uint256 _quoteAssetReserve, uint256 _baseAssetReserve) external;

    function shutdown() external;

    function settleFunding(uint256 _cap)
        external
        returns (
            int256 premiumFraction,
            int256 fundingPayment,
            int256 uncappedFundingPayment
        );

    function calcFee(uint256 _quoteAssetAmount) external view returns (uint256, uint256);

    //
    // VIEW
    //

    function getFormulaicRepegResult(uint256 budget, bool adjustK)
        external
        view
        returns (
            bool,
            int256,
            uint256,
            uint256
        );

    function getFormulaicUpdateKResult(int256 budget)
        external
        view
        returns (
            bool isAdjustable,
            int256 cost,
            uint256 newQuoteAssetReserve,
            uint256 newBaseAssetReserve
        );

    function isOverFluctuationLimit(Dir _dirOfBase, uint256 _baseAssetAmount) external view returns (bool);

    function calcBaseAssetAfterLiquidityMigration(
        int256 _baseAssetAmount,
        uint256 _fromQuoteReserve,
        uint256 _fromBaseReserve
    ) external view returns (int256);

    function getInputTwap(Dir _dir, uint256 _quoteAssetAmount) external view returns (uint256);

    function getOutputTwap(Dir _dir, uint256 _baseAssetAmount) external view returns (uint256);

    function getInputPrice(Dir _dir, uint256 _quoteAssetAmount) external view returns (uint256);

    function getOutputPrice(Dir _dir, uint256 _baseAssetAmount) external view returns (uint256);

    function getInputPriceWithReserves(
        Dir _dir,
        uint256 _quoteAssetAmount,
        uint256 _quoteAssetPoolAmount,
        uint256 _baseAssetPoolAmount
    ) external pure returns (uint256);

    function getOutputPriceWithReserves(
        Dir _dir,
        uint256 _baseAssetAmount,
        uint256 _quoteAssetPoolAmount,
        uint256 _baseAssetPoolAmount
    ) external pure returns (uint256);

    function getSpotPrice() external view returns (uint256);

    function getLiquidityHistoryLength() external view returns (uint256);

    // overridden by state variable
    function quoteAsset() external view returns (IERC20);

    function priceFeedKey() external view returns (bytes32);

    function tradeLimitRatio() external view returns (uint256);

    function fundingPeriod() external view returns (uint256);

    function priceFeed() external view returns (IPriceFeed);

    function getReserve() external view returns (uint256, uint256);

    function open() external view returns (bool);

    function adjustable() external view returns (bool);

    // can not be overridden by state variable due to type `Deciaml.decimal`
    function getSettlementPrice() external view returns (uint256);

    // function getBaseAssetDeltaThisFundingPeriod() external view returns (int256);

    function getCumulativeNotional() external view returns (int256);

    function getMaxHoldingBaseAsset() external view returns (uint256);

    function getOpenInterestNotionalCap() external view returns (uint256);

    function getLiquidityChangedSnapshots(uint256 i) external view returns (LiquidityChangedSnapshot memory);

    function getBaseAssetDelta() external view returns (int256);

    function getUnderlyingPrice() external view returns (uint256);

    function isOverSpreadLimit() external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;

import "./FullMath.sol";
/// @dev Implements simple signed fixed point math add, sub, mul and div operations.
library IntMath {
    /// @dev Returns 1 in the fixed point representation, with `decimals` decimals.
    function unit(uint8 decimals) internal pure returns (int256) {
        return int256(10**uint256(decimals));
    }

    function toUint(int256 x) internal pure returns (uint256) {
        return uint256(abs(x));
    }

    function abs(int256 x) internal pure returns (uint256) {
        uint256 t = 0;
        if (x < 0) {
            t = uint256(0 - x);
        } else {
            t = uint256(x);
        }
        return t;
    }

    /// @dev Multiplies x and y, assuming they are both fixed point with 18 digits.
    function mulD(int256 x, int256 y) internal pure returns (int256) {
        return mulD(x, y, 18);
    }

    /// @dev Multiplies x and y, assuming they are both fixed point with `decimals` digits.
    function mulD(
        int256 x,
        int256 y,
        uint8 decimals
    ) internal pure returns (int256) {
        if (x == 0 || y == 0) {
            return 0;
        }
        return int256(FullMath.mulDiv(abs(x), abs(y), 10**uint256(decimals))) * (int256(abs(x)) / x) * (int256(abs(y)) / y);
    }

    /// @dev Divides x between y, assuming they are both fixed point with 18 digits.
    function divD(int256 x, int256 y) internal pure returns (int256) {
        return divD(x, y, 18);
    }

    /// @dev Divides x between y, assuming they are both fixed point with `decimals` digits.
    function divD(
        int256 x,
        int256 y,
        uint8 decimals
    ) internal pure returns (int256) {
        if (x == 0 || y == 0) {
            return 0;
        }
        return int256(FullMath.mulDiv(abs(x), 10**uint256(decimals), abs(y))) * (int256(abs(x)) / x) * (int256(abs(y)) / y);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;

import "./FullMath.sol";
/// @dev Implements simple fixed point math add, sub, mul and div operations.
library UIntMath {
    uint256 private constant _INT256_MAX = 2**255 - 1;
    string private constant ERROR_NON_CONVERTIBLE = "Math: uint value is bigger than _INT256_MAX";

    /// @dev Returns 1 in the fixed point representation, with `decimals` decimals.
    function unit(uint8 decimals) internal pure returns (uint256) {
        return 10**uint256(decimals);
    }

    function toInt(uint256 x) internal pure returns (int256) {
        require(_INT256_MAX >= x, ERROR_NON_CONVERTIBLE);
        return int256(x);
    }

    // function modD(uint256 x, uint256 y) internal pure returns (uint256) {
    //     return (x * unit(18)) % y;
    // }

    /// @dev Multiplies x and y, assuming they are both fixed point with 18 digits.
    function mulD(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulD(x, y, 18);
    }

    /// @dev Multiplies x and y, assuming they are both fixed point with `decimals` digits.
    function mulD(
        uint256 x,
        uint256 y,
        uint8 decimals
    ) internal pure returns (uint256) {
        return FullMath.mulDiv(x, y, unit(decimals));
    }

    /// @dev Divides x between y, assuming they are both fixed point with 18 digits.
    function divD(uint256 x, uint256 y) internal pure returns (uint256) {
        return divD(x, y, 18);
    }

    /// @dev Divides x between y, assuming they are both fixed point with `decimals` digits.
    function divD(
        uint256 x,
        uint256 y,
        uint8 decimals
    ) internal pure returns (uint256) {
        return FullMath.mulDiv(x, unit(decimals), y);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        // 512-bit multiply [prod1 prod0] = a * b
        // Compute the product mod 2**256 and mod 2**256 - 1
        // then use the Chinese Remainder Theorem to reconstruct
        // the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2**256 + prod0
        uint256 prod0; // Least significant 256 bits of the product
        uint256 prod1; // Most significant 256 bits of the product
        assembly {
            let mm := mulmod(a, b, not(0))
            prod0 := mul(a, b)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        // Handle non-overflow cases, 256 by 256 division
        if (prod1 == 0) {
            require(denominator > 0);
            assembly {
                result := div(prod0, denominator)
            }
            return result;
        }

        // Make sure the result is less than 2**256.
        // Also prevents denominator == 0
        require(denominator > prod1);

        ///////////////////////////////////////////////
        // 512 by 256 division.
        ///////////////////////////////////////////////

        // Make division exact by subtracting the remainder from [prod1 prod0]
        // Compute remainder using mulmod
        uint256 remainder;
        assembly {
            remainder := mulmod(a, b, denominator)
        }
        // Subtract 256 bit number from 512 bit number
        assembly {
            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }

        // Factor powers of two out of denominator
        // Compute largest power of two divisor of denominator.
        // Always >= 1.
        unchecked {
            uint256 twos = (type(uint256).max - denominator + 1) & denominator;
            // Divide denominator by power of two
            assembly {
                denominator := div(denominator, twos)
            }

            // Divide [prod1 prod0] by the factors of two
            assembly {
                prod0 := div(prod0, twos)
            }
            // Shift in bits from prod1 into prod0. For this we need
            // to flip `twos` such that it is 2**256 / twos.
            // If twos is zero, then it becomes one
            assembly {
                twos := add(div(sub(0, twos), twos), 1)
            }
            prod0 |= prod1 * twos;

            // Invert denominator mod 2**256
            // Now that denominator is an odd number, it has an inverse
            // modulo 2**256 such that denominator * inv = 1 mod 2**256.
            // Compute the inverse by starting with a seed that is correct
            // correct for four bits. That is, denominator * inv = 1 mod 2**4
            uint256 inv = (3 * denominator) ^ 2;
            // Now use Newton-Raphson iteration to improve the precision.
            // Thanks to Hensel's lifting lemma, this also works in modular
            // arithmetic, doubling the correct bits in each step.
            inv *= 2 - denominator * inv; // inverse mod 2**8
            inv *= 2 - denominator * inv; // inverse mod 2**16
            inv *= 2 - denominator * inv; // inverse mod 2**32
            inv *= 2 - denominator * inv; // inverse mod 2**64
            inv *= 2 - denominator * inv; // inverse mod 2**128
            inv *= 2 - denominator * inv; // inverse mod 2**256

            // Because the division is now exact we can divide by multiplying
            // with the modular inverse of denominator. This will give us the
            // correct result modulo 2**256. Since the precoditions guarantee
            // that the outcome is less than 2**256, this is the final result.
            // We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inv;
            return result;
        }
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        result = mulDiv(a, b, denominator);
        if (mulmod(a, b, denominator) > 0) {
            require(result < type(uint256).max);
            result++;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;

import "./FullMath.sol";
import "./IntMath.sol";
import "./UIntMath.sol";

library AmmMath {
    using UIntMath for uint256;
    using IntMath for int256;
    uint128 constant K_DECREASE_MAX = 22 * 1e15; //2.2% decrease
    uint128 constant K_INCREASE_MAX = 1 * 1e15; //0.1% increase

    /**
     * calculate cost of repegging
     * @return cost if > 0, insurance fund should charge it
     */
    function adjustPegCost(
        uint256 _quoteAssetReserve,
        uint256 _baseAssetReserve,
        int256 _positionSize,
        uint256 _newQuoteAssetReserve
    ) internal pure returns (int256 cost) {
        if (_quoteAssetReserve == _newQuoteAssetReserve || _positionSize == 0) {
            cost = 0;
        } else {
            uint256 positionSizeAbs = _positionSize.abs();
            if (_positionSize > 0) {
                cost =
                    FullMath.mulDiv(_newQuoteAssetReserve, positionSizeAbs, _baseAssetReserve + positionSizeAbs).toInt() -
                    FullMath.mulDiv(_quoteAssetReserve, positionSizeAbs, _baseAssetReserve + positionSizeAbs).toInt();
            } else {
                cost =
                    FullMath.mulDiv(_quoteAssetReserve, positionSizeAbs, _baseAssetReserve - positionSizeAbs).toInt() -
                    FullMath.mulDiv(_newQuoteAssetReserve, positionSizeAbs, _baseAssetReserve - positionSizeAbs).toInt();
            }
        }
    }

    function calcBudgetedQuoteReserve(
        uint256 _quoteAssetReserve,
        uint256 _baseAssetReserve,
        int256 _positionSize,
        uint256 _budget
    ) internal pure returns (uint256 newQuoteAssetReserve) {
        newQuoteAssetReserve = _positionSize > 0
            ? _budget + _quoteAssetReserve + FullMath.mulDiv(_budget, _baseAssetReserve, _positionSize.abs())
            : _budget + _quoteAssetReserve - FullMath.mulDiv(_budget, _baseAssetReserve, _positionSize.abs());
    }

    function adjustKCost(
        uint256 _quoteAssetReserve,
        uint256 _baseAssetReserve,
        int256 _positionSize,
        uint256 _numerator,
        uint256 _denominator
    )
        internal
        pure
        returns (
            int256 cost,
            uint256 newQuoteAssetReserve,
            uint256 newBaseAssetReserve
        )
    {
        newQuoteAssetReserve = _quoteAssetReserve.mulD(_numerator).divD(_denominator);
        newBaseAssetReserve = _baseAssetReserve.mulD(_numerator).divD(_denominator);
        if (_numerator == _denominator || _positionSize == 0) {
            cost = 0;
        } else {
            uint256 baseAsset = _positionSize > 0
                ? _baseAssetReserve + uint256(_positionSize)
                : _baseAssetReserve - uint256(0 - _positionSize);
            uint256 newBaseAsset = _positionSize > 0
                ? newBaseAssetReserve + uint256(_positionSize)
                : newBaseAssetReserve - uint256(0 - _positionSize);
            uint256 newTerminalQuoteAssetReserve = FullMath.mulDiv(newQuoteAssetReserve, newBaseAssetReserve, newBaseAsset);
            uint256 terminalQuoteAssetReserve = FullMath.mulDiv(_quoteAssetReserve, _baseAssetReserve, baseAsset);
            uint256 newPositionNotionalSize = _positionSize > 0
                ? newQuoteAssetReserve - newTerminalQuoteAssetReserve
                : newTerminalQuoteAssetReserve - newQuoteAssetReserve;
            uint256 positionNotionalSize = _positionSize > 0
                ? _quoteAssetReserve - terminalQuoteAssetReserve
                : terminalQuoteAssetReserve - _quoteAssetReserve;
            if (_positionSize < 0) {
                cost = positionNotionalSize.toInt() - newPositionNotionalSize.toInt();
            } else {
                cost = newPositionNotionalSize.toInt() - positionNotionalSize.toInt();
            }
        }
    }

    function calculateBudgetedKScale(
        uint256 _quoteAssetReserve,
        uint256 _baseAssetReserve,
        int256 _budget,
        int256 _positionSize
    ) internal pure returns (uint256, uint256) {
        int256 x = _baseAssetReserve.toInt();
        int256 y = _quoteAssetReserve.toInt();
        int256 c = -_budget;
        int256 d = _positionSize;
        int256 x_d = x + d;
        int256 num1 = y.mulD(d).mulD(d);
        int256 num2 = c.mulD(x_d).mulD(d);
        int256 denom1 = c.mulD(x).mulD(x_d);
        int256 denom2 = num1;
        uint256 numerator = (num1 - num2).abs();
        uint256 denominator = (denom1 + denom2).abs();
        if (numerator > denominator) {
            uint256 kUpperBound = 1 ether + K_INCREASE_MAX;
            uint256 curChange = numerator.divD(denominator);
            uint256 maxChange = kUpperBound.divD(1 ether);
            if (curChange > maxChange) {
                return (kUpperBound, 1 ether);
            } else {
                return (numerator, denominator);
            }
        } else {
            uint256 kLowerBound = 1 ether - K_DECREASE_MAX;
            uint256 curChange = numerator.divD(denominator);
            uint256 maxChange = kLowerBound.divD(1 ether);
            if (curChange < maxChange) {
                return (kLowerBound, 1 ether);
            } else {
                return (numerator, denominator);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
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
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
                /// @solidity memory-safe-assembly
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