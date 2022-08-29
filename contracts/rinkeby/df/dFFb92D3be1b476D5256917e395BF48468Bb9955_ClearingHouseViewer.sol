// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IAmm } from "./interfaces/IAmm.sol";
import { IInsuranceFund } from "./interfaces/IInsuranceFund.sol";
import { ClearingHouse } from "./ClearingHouse.sol";

import { IntMath } from "./utils/IntMath.sol";
import { UIntMath } from "./utils/UIntMath.sol";

contract ClearingHouseViewer {
    using UIntMath for uint256;
    using IntMath for int256;

    ClearingHouse public clearingHouse;

    //
    // FUNCTIONS
    //

    constructor(ClearingHouse _clearingHouse) {
        clearingHouse = _clearingHouse;
    }

    //
    // Public
    //

    /**
     * @notice get unrealized PnL
     * @param _amm IAmm address
     * @param _trader trader address
     * @param _pnlCalcOption ClearingHouse.PnlCalcOption, can be SPOT_PRICE or TWAP.
     * @return unrealized PnL in 18 digits
     */
    function getUnrealizedPnl(
        IAmm _amm,
        address _trader,
        ClearingHouse.PnlCalcOption _pnlCalcOption
    ) external view returns (int256) {
        (, int256 unrealizedPnl) = (clearingHouse.getPositionNotionalAndUnrealizedPnl(_amm, _trader, _pnlCalcOption));
        return unrealizedPnl;
    }

    /**
     * @notice get personal balance with funding payment
     * @param _quoteToken ERC20 token address
     * @param _trader trader address
     * @return margin personal balance with funding payment in 18 digits
     */
    function getPersonalBalanceWithFundingPayment(IERC20 _quoteToken, address _trader) external view returns (uint256 margin) {
        IInsuranceFund insuranceFund = clearingHouse.insuranceFund();
        IAmm[] memory amms = insuranceFund.getAllAmms();
        for (uint256 i = 0; i < amms.length; i++) {
            if (IAmm(amms[i]).quoteAsset() != _quoteToken) {
                continue;
            }
            uint256 posMargin = getPersonalPositionWithFundingPayment(amms[i], _trader).margin;
            margin = margin + posMargin;
        }
    }

    /**
     * @notice get personal position with funding payment
     * @param _amm IAmm address
     * @param _trader trader address
     * @return position ClearingHouse.Position struct
     */
    function getPersonalPositionWithFundingPayment(IAmm _amm, address _trader)
        public
        view
        returns (ClearingHouse.Position memory position)
    {
        position = clearingHouse.getPosition(_amm, _trader);
        int256 marginWithFundingPayment = position.margin.toInt() +
            getFundingPayment(position, clearingHouse.getLatestCumulativePremiumFraction(_amm));
        position.margin = marginWithFundingPayment >= 0 ? marginWithFundingPayment.abs() : 0;
    }

    /**
     * @notice verify if trader's position needs to be migrated
     * @param _amm IAmm address
     * @param _trader trader address
     * @return true if trader's position is not at the latest Amm curve, otherwise is false
     */
    function isPositionNeedToBeMigrated(IAmm _amm, address _trader) external view returns (bool) {
        ClearingHouse.Position memory unadjustedPosition = clearingHouse.getUnadjustedPosition(_amm, _trader);
        if (unadjustedPosition.size == 0) {
            return false;
        }
        uint256 latestLiquidityIndex = _amm.getLiquidityHistoryLength() - 1;
        if (unadjustedPosition.liquidityHistoryIndex == latestLiquidityIndex) {
            return false;
        }
        return true;
    }

    /**
     * @notice get personal margin ratio
     * @param _amm IAmm address
     * @param _trader trader address
     * @return personal margin ratio in 18 digits
     */
    function getMarginRatio(IAmm _amm, address _trader) external view returns (int256) {
        return clearingHouse.getMarginRatio(_amm, _trader);
    }

    /**
     * @notice get withdrawable margin
     * @param _amm IAmm address
     * @param _trader trader address
     * @return withdrawable margin in 18 digits
     */
    function getFreeCollateral(IAmm _amm, address _trader) external view returns (int256) {
        // get trader's margin
        ClearingHouse.Position memory position = getPersonalPositionWithFundingPayment(_amm, _trader);

        // get trader's unrealized PnL and choose the least beneficial one for the trader
        (uint256 spotPositionNotional, int256 spotPricePnl) = (
            clearingHouse.getPositionNotionalAndUnrealizedPnl(_amm, _trader, ClearingHouse.PnlCalcOption.SPOT_PRICE)
        );
        (uint256 twapPositionNotional, int256 twapPricePnl) = (
            clearingHouse.getPositionNotionalAndUnrealizedPnl(_amm, _trader, ClearingHouse.PnlCalcOption.TWAP)
        );

        int256 unrealizedPnl;
        uint256 positionNotional;
        (unrealizedPnl, positionNotional) = (spotPricePnl > twapPricePnl)
            ? (twapPricePnl, twapPositionNotional)
            : (spotPricePnl, spotPositionNotional);

        // min(margin + funding, margin + funding + unrealized PnL) - position value * initMarginRatio
        int256 accountValue = unrealizedPnl + position.margin.toInt();
        int256 minCollateral = accountValue - position.margin.toInt() > 0 ? position.margin.toInt() : accountValue;

        uint256 initMarginRatio = clearingHouse.initMarginRatio();
        int256 marginRequirement = position.size > 0
            ? position.openNotional.toInt().mulD(initMarginRatio.toInt())
            : positionNotional.toInt().mulD(initMarginRatio.toInt());

        return minCollateral - marginRequirement;
    }

    //
    // PRIVATE
    //

    // negative means trader paid and vice versa
    function getFundingPayment(ClearingHouse.Position memory _position, int256 _latestCumulativePremiumFraction)
        private
        pure
        returns (int256)
    {
        return
            _position.size == 0
                ? int256(0)
                : (_latestCumulativePremiumFraction - _position.lastUpdatedCumulativePremiumFraction).mulD(_position.size) * -1;
    }
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
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { IAmm } from "./IAmm.sol";

interface IInsuranceFund {
    function withdraw(IERC20 _quoteToken, uint256 _amount) external;

    function isExistedAmm(IAmm _amm) external view returns (bool);

    function getAllAmms() external view returns (IAmm[] memory);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;

import { BlockContext } from "./utils/BlockContext.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import { OwnerPausableUpgradeSafe } from "./OwnerPausable.sol";
import { IAmm } from "./interfaces/IAmm.sol";
import { IInsuranceFund } from "./interfaces/IInsuranceFund.sol";
import { IMultiTokenRewardRecipient } from "./interfaces/IMultiTokenRewardRecipient.sol";
import { IntMath } from "./utils/IntMath.sol";
import { UIntMath } from "./utils/UIntMath.sol";
import { FullMath } from "./utils/FullMath.sol";
import { TransferHelper } from "./utils/TransferHelper.sol";
import { AmmMath } from "./utils/AmmMath.sol";

// note BaseRelayRecipient must come after OwnerPausableUpgradeSafe so its _msgSender() takes precedence
// (yes, the ordering is reversed comparing to Python)
contract ClearingHouse is OwnerPausableUpgradeSafe, ReentrancyGuardUpgradeable, BlockContext {
    using UIntMath for uint256;
    using IntMath for int256;
    using TransferHelper for IERC20;

    //
    // EVENTS
    //
    //event MarginRatioChanged(uint256 marginRatio);
    //event LiquidationFeeRatioChanged(uint256 liquidationFeeRatio);
    event BackstopLiquidityProviderChanged(address indexed account, bool indexed isProvider);
    event MarginChanged(address indexed sender, address indexed amm, int256 amount, int256 fundingPayment);
    event PositionAdjusted(
        address indexed amm,
        address indexed trader,
        int256 newPositionSize,
        uint256 oldLiquidityIndex,
        uint256 newLiquidityIndex
    );
    event PositionSettled(address indexed amm, address indexed trader, uint256 valueTransferred);
    event RestrictionModeEntered(address amm, uint256 blockNumber);
    event Repeg(address amm, uint256 quoteAssetReserve, uint256 baseAssetReserve, int256 cost);
    event UpdateK(address amm, uint256 quoteAssetReserve, uint256 baseAssetReserve, int256 cost);

    /// @notice This event is emitted when position change
    /// @param trader the address which execute this transaction
    /// @param amm IAmm address
    /// @param margin margin
    /// @param positionNotional margin * leverage
    /// @param exchangedPositionSize position size, e.g. ETHUSDC or LINKUSDC
    /// @param fee transaction fee
    /// @param positionSizeAfter position size after this transaction, might be increased or decreased
    /// @param realizedPnl realized pnl after this position changed
    /// @param unrealizedPnlAfter unrealized pnl after this position changed
    /// @param badDebt position change amount cleared by insurance funds
    /// @param liquidationPenalty amount of remaining margin lost due to liquidation
    /// @param spotPrice quote asset reserve / base asset reserve
    /// @param fundingPayment funding payment (+: trader paid, -: trader received)
    event PositionChanged(
        address indexed trader,
        address indexed amm,
        uint256 margin,
        uint256 positionNotional,
        int256 exchangedPositionSize,
        uint256 fee,
        int256 positionSizeAfter,
        int256 realizedPnl,
        int256 unrealizedPnlAfter,
        uint256 badDebt,
        uint256 liquidationPenalty,
        uint256 spotPrice,
        int256 fundingPayment
    );

    /// @notice This event is emitted when position liquidated
    /// @param trader the account address being liquidated
    /// @param amm IAmm address
    /// @param positionNotional liquidated position value minus liquidationFee
    /// @param positionSize liquidated position size
    /// @param liquidationFee liquidation fee to the liquidator
    /// @param liquidator the address which execute this transaction
    /// @param badDebt liquidation fee amount cleared by insurance funds
    event PositionLiquidated(
        address indexed trader,
        address indexed amm,
        uint256 positionNotional,
        uint256 positionSize,
        uint256 liquidationFee,
        address liquidator,
        uint256 badDebt
    );

    //
    // Struct and Enum
    //

    enum Side {
        BUY,
        SELL
    }
    enum PnlCalcOption {
        SPOT_PRICE,
        TWAP,
        ORACLE
    }

    /// @param MAX_PNL most beneficial way for traders to calculate position notional
    /// @param MIN_PNL least beneficial way for traders to calculate position notional
    enum PnlPreferenceOption {
        MAX_PNL,
        MIN_PNL
    }

    /// @notice This struct records personal position information
    /// @param size denominated in amm.baseAsset
    /// @param margin isolated margin
    /// @param openNotional the quoteAsset value of position when opening position. the cost of the position
    /// @param lastUpdatedCumulativePremiumFraction for calculating funding payment, record at the moment every time when trader open/reduce/close position
    /// @param liquidityHistoryIndex
    /// @param blockNumber the block number of the last position
    struct Position {
        int256 size;
        uint256 margin;
        uint256 openNotional;
        int256 lastUpdatedCumulativePremiumFraction;
        uint256 liquidityHistoryIndex;
        uint256 blockNumber;
    }

    /// @notice This struct is used for avoiding stack too deep error when passing too many var between functions
    struct PositionResp {
        Position position;
        // the quote asset amount trader will send if open position, will receive if close
        uint256 exchangedQuoteAssetAmount;
        // if realizedPnl + realizedFundingPayment + margin is negative, it's the abs value of it
        uint256 badDebt;
        // the base asset amount trader will receive if open position, will send if close
        int256 exchangedPositionSize;
        // funding payment incurred during this position response
        int256 fundingPayment;
        // realizedPnl = unrealizedPnl * closedRatio
        int256 realizedPnl;
        // positive = trader transfer margin to vault, negative = trader receive margin from vault
        // it's 0 when internalReducePosition, its addedMargin when internalIncreasePosition
        // it's min(0, oldPosition + realizedFundingPayment + realizedPnl) when internalClosePosition
        int256 marginToVault;
        // unrealized pnl after open position
        int256 unrealizedPnlAfter;
    }

    struct AmmMap {
        // issue #1471
        // last block when it turn restriction mode on.
        // In restriction mode, no one can do multi open/close/liquidate position in the same block.
        // If any underwater position being closed (having a bad debt and make insuranceFund loss),
        // or any liquidation happened,
        // restriction mode is ON in that block and OFF(default) in the next block.
        // This design is to prevent the attacker being benefited from the multiple action in one block
        // in extreme cases
        uint256 lastRestrictionBlock;
        int256[] cumulativePremiumFractions;
        mapping(address => Position) positionMap;
    }

    modifier onlyOperator() {
        require(operator == _msgSender(), "caller is not operator");
        _;
    }

    //**********************************************************//
    //    Can not change the order of below state variables     //
    //**********************************************************//
    //string public override versionRecipient;

    // only admin
    uint256 public initMarginRatio;

    // only admin
    uint256 public maintenanceMarginRatio;

    // only admin
    uint256 public liquidationFeeRatio;

    // only admin
    uint256 public partialLiquidationRatio;

    // key by amm address. will be deprecated or replaced after guarded period.
    // it's not an accurate open interest, just a rough way to control the unexpected loss at the beginning
    mapping(address => uint256) public openInterestNotionalMap;

    // key by amm address
    mapping(address => AmmMap) internal ammMap;

    // prepaid bad debt balance, key by Amm address
    mapping(address => uint256) internal prepaidBadDebts;

    // contract dependencies
    IInsuranceFund public insuranceFund;
    IMultiTokenRewardRecipient public feePool;

    // designed for arbitragers who can hold unlimited positions. will be removed after guarded period
    address internal whitelist;

    mapping(address => bool) public backstopLiquidityProviderMap;

    // amm => balance of vault
    mapping(address => uint256) public vaults;

    // amm => total fees allocated to market
    mapping(address => uint256) public totalFees;
    mapping(address => uint256) public totalMinusFees;

    // amm => revenue since last funding
    mapping(address => int256) public netRevenuesSinceLastFunding;

    // the address of bot that controls market
    address public operator;

    uint256[50] private __gap;

    //**********************************************************//
    //    Can not change the order of above state variables     //
    //**********************************************************//

    //◥◤◥◤◥◤◥◤◥◤◥◤◥◤◥◤ add state variables below ◥◤◥◤◥◤◥◤◥◤◥◤◥◤◥◤//

    //◢◣◢◣◢◣◢◣◢◣◢◣◢◣◢◣ add state variables above ◢◣◢◣◢◣◢◣◢◣◢◣◢◣◢◣//
    //

    // FUNCTIONS
    //
    // openzeppelin doesn't support struct input
    // https://github.com/OpenZeppelin/openzeppelin-sdk/issues/1523
    function initialize(
        uint256 _initMarginRatio,
        uint256 _maintenanceMarginRatio,
        uint256 _liquidationFeeRatio,
        IInsuranceFund _insuranceFund
    ) public initializer {
        //require(address(_insuranceFund) != address(0), "Invalid IInsuranceFund");

        __OwnerPausable_init();

        //comment these out for reducing bytecode size
        __ReentrancyGuard_init();

        initMarginRatio = _initMarginRatio;
        maintenanceMarginRatio = _maintenanceMarginRatio;
        liquidationFeeRatio = _liquidationFeeRatio;
        insuranceFund = _insuranceFund;
    }

    //
    // External
    //

    /**
     * @notice set liquidation fee ratio
     * @dev only owner can call
     * @param _liquidationFeeRatio new liquidation fee ratio in 18 digits
     */
    function setLiquidationFeeRatio(uint256 _liquidationFeeRatio) external onlyOwner {
        liquidationFeeRatio = _liquidationFeeRatio;
        //emit LiquidationFeeRatioChanged(liquidationFeeRatio.toUint());
    }

    /**
     * @notice set maintenance margin ratio
     * @dev only owner can call
     * @param _maintenanceMarginRatio new maintenance margin ratio in 18 digits
     */
    function setMaintenanceMarginRatio(uint256 _maintenanceMarginRatio) external onlyOwner {
        maintenanceMarginRatio = _maintenanceMarginRatio;
        //emit MarginRatioChanged(maintenanceMarginRatio.toUint());
    }

    /**
     * @notice set the toll pool address
     * @dev only owner can call
     */
    function setTollPool(address _feePool) external onlyOwner {
        feePool = IMultiTokenRewardRecipient(_feePool);
    }

    /**
     * @notice add an address in the whitelist. People in the whitelist can hold unlimited positions.
     * @dev only owner can call
     * @param _whitelist an address
     */
    function setWhitelist(address _whitelist) external onlyOwner {
        whitelist = _whitelist;
    }

    /**
     * @notice set backstop liquidity provider
     * @dev only owner can call
     * @param account provider address
     * @param isProvider wether the account is a backstop liquidity provider
     */
    function setBackstopLiquidityProvider(address account, bool isProvider) external onlyOwner {
        backstopLiquidityProviderMap[account] = isProvider;
        emit BackstopLiquidityProviderChanged(account, isProvider);
    }

    /**
     * @notice set the margin ratio after deleveraging
     * @dev only owner can call
     */
    function setPartialLiquidationRatio(uint256 _ratio) external onlyOwner {
        //require(_ratio.cmp(Decimal.one()) <= 0, "invalid partial liquidation ratio");
        require(_ratio <= 1 ether, "invalid partial liquidation ratio");
        partialLiquidationRatio = _ratio;
    }

    function setOperator(address _operator) external onlyOwner {
        operator = _operator;
    }

    /**
     * @notice add margin to increase margin ratio
     * @param _amm IAmm address
     * @param _addedMargin added margin in 18 digits
     */
    function addMargin(IAmm _amm, uint256 _addedMargin) external whenNotPaused nonReentrant {
        // check condition
        requireAmm(_amm, true);
        requireValidTokenAmount(_addedMargin);

        address trader = _msgSender();
        Position memory position = getPosition(_amm, trader);
        // update margin
        position.margin = position.margin + _addedMargin;

        setPosition(_amm, trader, position);
        // transfer token from trader
        deposit(_amm, trader, _addedMargin);
        emit MarginChanged(trader, address(_amm), int256(_addedMargin), 0);
    }

    /**
     * @notice remove margin to decrease margin ratio
     * @param _amm IAmm address
     * @param _removedMargin removed margin in 18 digits
     */
    function removeMargin(IAmm _amm, uint256 _removedMargin) external whenNotPaused nonReentrant {
        // check condition
        requireAmm(_amm, true);
        requireValidTokenAmount(_removedMargin);

        address trader = _msgSender();
        // realize funding payment if there's no bad debt
        Position memory position = getPosition(_amm, trader);

        // update margin and cumulativePremiumFraction
        int256 marginDelta = _removedMargin.toInt() * -1;
        (
            uint256 remainMargin,
            uint256 badDebt,
            int256 fundingPayment,
            int256 latestCumulativePremiumFraction
        ) = calcRemainMarginWithFundingPayment(_amm, position, marginDelta);
        require(badDebt == 0, "margin is not enough");
        position.margin = remainMargin;
        position.lastUpdatedCumulativePremiumFraction = latestCumulativePremiumFraction;

        // check enough margin (same as the way Curie calculates the free collateral)
        // Use a more conservative way to restrict traders to remove their margin
        // We don't allow unrealized PnL to support their margin removal
        require(calcFreeCollateral(_amm, trader, remainMargin - badDebt) >= 0, "free collateral is not enough");

        setPosition(_amm, trader, position);

        // transfer token back to trader
        withdraw(_amm, trader, _removedMargin);
        emit MarginChanged(trader, address(_amm), marginDelta, fundingPayment);
    }

    /**
     * @notice settle all the positions when amm is shutdown. The settlement price is according to IAmm.settlementPrice
     * @param _amm IAmm address
     */
    function settlePosition(IAmm _amm) external nonReentrant {
        // check condition
        requireAmm(_amm, false);
        address trader = _msgSender();
        Position memory pos = getPosition(_amm, trader);
        requirePositionSize(pos.size);
        // update position
        clearPosition(_amm, trader);
        // calculate settledValue
        // If Settlement Price = 0, everyone takes back her collateral.
        // else Returned Fund = Position Size * (Settlement Price - Open Price) + Collateral
        uint256 settlementPrice = _amm.getSettlementPrice();
        uint256 settledValue;
        if (settlementPrice == 0) {
            settledValue = pos.margin;
        } else {
            // returnedFund = positionSize * (settlementPrice - openPrice) + positionMargin
            // openPrice = positionOpenNotional / positionSize.abs()
            int256 returnedFund = pos.size.mulD(settlementPrice.toInt() - (pos.openNotional.divD(pos.size.abs())).toInt()) +
                pos.margin.toInt();
            // if `returnedFund` is negative, trader can't get anything back
            if (returnedFund > 0) {
                settledValue = returnedFund.abs();
            }
        }
        // transfer token based on settledValue. no insurance fund support
        if (settledValue > 0) {
            withdraw(_amm, trader, settledValue);
            // _amm.quoteAsset().safeTransfer(trader, settledValue);
            //_transfer(_amm.quoteAsset(), trader, settledValue);
        }
        // emit event
        emit PositionSettled(address(_amm), trader, settledValue);
    }

    // if increase position
    //   marginToVault = addMargin
    //   marginDiff = realizedFundingPayment + realizedPnl(0)
    //   pos.margin += marginToVault + marginDiff
    //   vault.margin += marginToVault + marginDiff
    //   required(enoughMarginRatio)
    // else if reduce position()
    //   marginToVault = 0
    //   marginDiff = realizedFundingPayment + realizedPnl
    //   pos.margin += marginToVault + marginDiff
    //   if pos.margin < 0, badDebt = abs(pos.margin), set pos.margin = 0
    //   vault.margin += marginToVault + marginDiff
    //   required(enoughMarginRatio)
    // else if close
    //   marginDiff = realizedFundingPayment + realizedPnl
    //   pos.margin += marginDiff
    //   if pos.margin < 0, badDebt = abs(pos.margin)
    //   marginToVault = -pos.margin
    //   set pos.margin = 0
    //   vault.margin += marginToVault + marginDiff
    // else if close and open a larger position in reverse side
    //   close()
    //   positionNotional -= exchangedQuoteAssetAmount
    //   newMargin = positionNotional / leverage
    //   internalIncreasePosition(newMargin, leverage)
    // else if liquidate
    //   close()
    //   pay liquidation fee to liquidator
    //   move the remain margin to insuranceFund

    /**
     * @notice open a position
     * @param _amm amm address
     * @param _side enum Side; BUY for long and SELL for short
     * @param _quoteAssetAmount quote asset amount in 18 digits. Can Not be 0
     * @param _leverage leverage  in 18 digits. Can Not be 0
     * @param _baseAssetAmountLimit minimum base asset amount expected to get to prevent from slippage.
     */
    function openPosition(
        IAmm _amm,
        Side _side,
        uint256 _quoteAssetAmount,
        uint256 _leverage,
        uint256 _baseAssetAmountLimit
    ) public whenNotPaused nonReentrant {
        requireAmm(_amm, true);
        requireValidTokenAmount(_quoteAssetAmount);
        requireNonZeroInput(_leverage);
        requireMoreMarginRatio(int256(1 ether).divD(_leverage.toInt()), initMarginRatio, true);
        requireNotRestrictionMode(_amm);

        address trader = _msgSender();
        PositionResp memory positionResp;
        {
            // add scope for stack too deep error
            int256 oldPositionSize = getPosition(_amm, trader).size;
            bool isNewPosition = oldPositionSize == 0 ? true : false;

            // increase or decrease position depends on old position's side and size
            if (isNewPosition || (oldPositionSize > 0 ? Side.BUY : Side.SELL) == _side) {
                positionResp = internalIncreasePosition(_amm, _side, _quoteAssetAmount.mulD(_leverage), _baseAssetAmountLimit, _leverage);
            } else {
                positionResp = openReversePosition(_amm, _side, trader, _quoteAssetAmount, _leverage, _baseAssetAmountLimit, false);
            }

            // update the position state
            setPosition(_amm, trader, positionResp.position);
            // if opening the exact position size as the existing one == closePosition, can skip the margin ratio check
            if (!isNewPosition && positionResp.position.size != 0) {
                requireMoreMarginRatio(getMarginRatio(_amm, trader), maintenanceMarginRatio, true);
            }

            // to prevent attacker to leverage the bad debt to withdraw extra token from insurance fund
            require(positionResp.badDebt == 0, "bad debt");

            // transfer the actual token between trader and vault
            if (positionResp.marginToVault > 0) {
                deposit(_amm, trader, positionResp.marginToVault.abs());
            } else if (positionResp.marginToVault < 0) {
                withdraw(_amm, trader, positionResp.marginToVault.abs());
            }
        }

        // calculate fee and transfer token for fees
        //@audit - can optimize by changing amm.swapInput/swapOutput's return type to (exchangedAmount, quoteToll, quoteSpread, quoteReserve, baseReserve) (@wraecca)
        uint256 transferredFee = transferFee(trader, _amm, positionResp.exchangedQuoteAssetAmount);

        // emit event
        uint256 spotPrice = _amm.getSpotPrice();
        int256 fundingPayment = positionResp.fundingPayment; // pre-fetch for stack too deep error
        emit PositionChanged(
            trader,
            address(_amm),
            positionResp.position.margin,
            positionResp.exchangedQuoteAssetAmount,
            positionResp.exchangedPositionSize,
            transferredFee,
            positionResp.position.size,
            positionResp.realizedPnl,
            positionResp.unrealizedPnlAfter,
            positionResp.badDebt,
            0,
            spotPrice,
            fundingPayment
        );
    }

    /**
     * @notice close all the positions
     * @param _amm IAmm address
     */
    function closePosition(IAmm _amm, uint256 _quoteAssetAmountLimit) public whenNotPaused nonReentrant {
        // check conditions
        requireAmm(_amm, true);
        requireNotRestrictionMode(_amm);

        // update position
        address trader = _msgSender();

        PositionResp memory positionResp;
        {
            Position memory position = getPosition(_amm, trader);
            // if it is long position, close a position means short it(which means base dir is ADD_TO_AMM) and vice versa
            IAmm.Dir dirOfBase = position.size > 0 ? IAmm.Dir.ADD_TO_AMM : IAmm.Dir.REMOVE_FROM_AMM;

            // check if this position exceed fluctuation limit
            // if over fluctuation limit, then close partial position. Otherwise close all.
            // if partialLiquidationRatio is 1, then close whole position
            if (
                _amm.isOverFluctuationLimit(dirOfBase, position.size.abs()) &&
                partialLiquidationRatio < 1 ether &&
                partialLiquidationRatio != 0
            ) {
                uint256 partiallyClosedPositionNotional = _amm.getOutputPrice(
                    dirOfBase,
                    position.size.mulD(partialLiquidationRatio.toInt()).abs()
                );

                positionResp = openReversePosition(
                    _amm,
                    position.size > 0 ? Side.SELL : Side.BUY,
                    trader,
                    partiallyClosedPositionNotional,
                    1 ether,
                    0,
                    true
                );
                setPosition(_amm, trader, positionResp.position);
            } else {
                positionResp = internalClosePosition(_amm, trader, _quoteAssetAmountLimit);
            }

            // to prevent attacker to leverage the bad debt to withdraw extra token from insurance fund
            require(positionResp.badDebt == 0, "bad debt");

            // add scope for stack too deep error
            // transfer the actual token from trader and vault
            withdraw(_amm, trader, positionResp.marginToVault.abs());
        }

        // calculate fee and transfer token for fees
        uint256 transferredFee = transferFee(trader, _amm, positionResp.exchangedQuoteAssetAmount);

        // prepare event
        uint256 spotPrice = _amm.getSpotPrice();
        int256 fundingPayment = positionResp.fundingPayment;
        emit PositionChanged(
            trader,
            address(_amm),
            positionResp.position.margin,
            positionResp.exchangedQuoteAssetAmount,
            positionResp.exchangedPositionSize,
            transferredFee,
            positionResp.position.size,
            positionResp.realizedPnl,
            positionResp.unrealizedPnlAfter,
            positionResp.badDebt,
            0,
            spotPrice,
            fundingPayment
        );
    }

    function liquidateWithSlippage(
        IAmm _amm,
        address _trader,
        uint256 _quoteAssetAmountLimit
    ) external nonReentrant returns (uint256 quoteAssetAmount, bool isPartialClose) {
        Position memory position = getPosition(_amm, _trader);
        (quoteAssetAmount, isPartialClose) = internalLiquidate(_amm, _trader);

        uint256 quoteAssetAmountLimit = isPartialClose ? _quoteAssetAmountLimit.mulD(partialLiquidationRatio) : _quoteAssetAmountLimit;

        if (position.size > 0) {
            require(quoteAssetAmount >= quoteAssetAmountLimit, "Less than minimal quote token");
        } else if (position.size < 0 && quoteAssetAmountLimit != 0) {
            require(quoteAssetAmount <= quoteAssetAmountLimit, "More than maximal quote token");
        }

        return (quoteAssetAmount, isPartialClose);
    }

    /**
     * @notice liquidate trader's underwater position. Require trader's margin ratio less than maintenance margin ratio
     * @dev liquidator can NOT open any positions in the same block to prevent from price manipulation.
     * @param _amm IAmm address
     * @param _trader trader address
     */
    function liquidate(IAmm _amm, address _trader) public nonReentrant {
        internalLiquidate(_amm, _trader);
    }

    /**
     * @notice if funding rate is positive, traders with long position pay traders with short position and vice versa.
     * @param _amm IAmm address
     */
    function payFunding(IAmm _amm) external {
        requireAmm(_amm, true);
        formulaicRepegAmm(_amm);
        uint256 totalFee = totalFees[address(_amm)];
        uint256 totalMinusFee = totalMinusFees[address(_amm)];
        uint256 cap = totalMinusFee > totalFee / 2 ? totalMinusFee - totalFee / 2 : 0;
        (int256 premiumFraction, int256 fundingPayment, int256 fundingImbalanceCost) = _amm.settleFunding(cap);
        ammMap[address(_amm)].cumulativePremiumFractions.push(premiumFraction + getLatestCumulativePremiumFraction(_amm));
        // funding payment is positive means profit
        if (fundingPayment < 0) {
            totalMinusFees[address(_amm)] = totalMinusFee - fundingPayment.abs();
            withdrawFromInsuranceFund(_amm, fundingPayment.abs());
        } else {
            totalMinusFees[address(_amm)] = totalMinusFee + fundingPayment.abs();
            transferToInsuranceFund(_amm, fundingPayment.abs());
        }
        formulaicUpdateK(_amm, fundingImbalanceCost);
        netRevenuesSinceLastFunding[address(_amm)] = 0;
    }

    //
    // VIEW FUNCTIONS
    //

    /**
     * @notice get margin ratio, marginRatio = (margin + funding payment + unrealized Pnl) / positionNotional
     * use spot price to calculate unrealized Pnl
     * @param _amm IAmm address
     * @param _trader trader address
     * @return margin ratio in 18 digits
     */
    function getMarginRatio(IAmm _amm, address _trader) public view returns (int256) {
        Position memory position = getPosition(_amm, _trader);
        requirePositionSize(position.size);
        (uint256 positionNotional, int256 unrealizedPnl) = getPositionNotionalAndUnrealizedPnl(_amm, _trader, PnlCalcOption.SPOT_PRICE);
        return _getMarginRatio(_amm, position, unrealizedPnl, positionNotional);
    }

    // function _getMarginRatioByCalcOption(
    //     IAmm _amm,
    //     address _trader,
    //     PnlCalcOption _pnlCalcOption
    // ) internal view returns (int256) {
    //     Position memory position = getPosition(_amm, _trader);
    //     requirePositionSize(position.size);
    //     (uint256 positionNotional, int256 pnl) = getPositionNotionalAndUnrealizedPnl(_amm, _trader, _pnlCalcOption);
    //     return _getMarginRatio(_amm, position, pnl, positionNotional);
    // }

    function _getMarginRatio(
        IAmm _amm,
        Position memory _position,
        int256 _unrealizedPnl,
        uint256 _positionNotional
    ) internal view returns (int256) {
        (uint256 remainMargin, uint256 badDebt, , ) = calcRemainMarginWithFundingPayment(_amm, _position, _unrealizedPnl);
        return (remainMargin.toInt() - badDebt.toInt()).divD(_positionNotional.toInt());
    }

    /**
     * @notice get personal position information
     * @param _amm IAmm address
     * @param _trader trader address
     * @return struct Position
     */
    function getPosition(IAmm _amm, address _trader) public view returns (Position memory) {
        return ammMap[address(_amm)].positionMap[_trader];
    }

    /**
     * @notice get position notional and unrealized Pnl without fee expense and funding payment
     * @param _amm IAmm address
     * @param _trader trader address
     * @param _pnlCalcOption enum PnlCalcOption, SPOT_PRICE for spot price and TWAP for twap price
     * @return positionNotional position notional
     * @return unrealizedPnl unrealized Pnl
     */
    function getPositionNotionalAndUnrealizedPnl(
        IAmm _amm,
        address _trader,
        PnlCalcOption _pnlCalcOption
    ) public view returns (uint256 positionNotional, int256 unrealizedPnl) {
        Position memory position = getPosition(_amm, _trader);
        uint256 positionSizeAbs = position.size.abs();
        if (positionSizeAbs != 0) {
            bool isShortPosition = position.size < 0;
            IAmm.Dir dir = isShortPosition ? IAmm.Dir.REMOVE_FROM_AMM : IAmm.Dir.ADD_TO_AMM;
            if (_pnlCalcOption == PnlCalcOption.TWAP) {
                positionNotional = _amm.getOutputTwap(dir, positionSizeAbs);
            } else if (_pnlCalcOption == PnlCalcOption.SPOT_PRICE) {
                positionNotional = _amm.getOutputPrice(dir, positionSizeAbs);
            } else {
                uint256 oraclePrice = _amm.getUnderlyingPrice();
                positionNotional = positionSizeAbs.mulD(oraclePrice);
            }
            // unrealizedPnlForLongPosition = positionNotional - openNotional
            // unrealizedPnlForShortPosition = positionNotionalWhenBorrowed - positionNotionalWhenReturned =
            // openNotional - positionNotional = unrealizedPnlForLongPosition * -1
            unrealizedPnl = isShortPosition
                ? position.openNotional.toInt() - positionNotional.toInt()
                : positionNotional.toInt() - position.openNotional.toInt();
        }
    }

    /**
     * @notice get latest cumulative premium fraction.
     * @param _amm IAmm address
     * @return latest cumulative premium fraction in 18 digits
     */
    function getLatestCumulativePremiumFraction(IAmm _amm) public view returns (int256 latest) {
        uint256 len = ammMap[address(_amm)].cumulativePremiumFractions.length;
        if (len > 0) {
            latest = ammMap[address(_amm)].cumulativePremiumFractions[len - 1];
        }
    }

    //
    // INTERNAL FUNCTIONS
    //

    function enterRestrictionMode(IAmm _amm) internal {
        uint256 blockNumber = _blockNumber();
        ammMap[address(_amm)].lastRestrictionBlock = blockNumber;
        emit RestrictionModeEntered(address(_amm), blockNumber);
    }

    function setPosition(
        IAmm _amm,
        address _trader,
        Position memory _position
    ) internal {
        Position storage positionStorage = ammMap[address(_amm)].positionMap[_trader];
        positionStorage.size = _position.size;
        positionStorage.margin = _position.margin;
        positionStorage.openNotional = _position.openNotional;
        positionStorage.lastUpdatedCumulativePremiumFraction = _position.lastUpdatedCumulativePremiumFraction;
        positionStorage.blockNumber = _position.blockNumber;
        positionStorage.liquidityHistoryIndex = _position.liquidityHistoryIndex;
    }

    function clearPosition(IAmm _amm, address _trader) internal {
        // keep the record in order to retain the last updated block number
        ammMap[address(_amm)].positionMap[_trader] = Position({
            size: 0,
            margin: 0,
            openNotional: 0,
            lastUpdatedCumulativePremiumFraction: 0,
            blockNumber: _blockNumber(),
            liquidityHistoryIndex: 0
        });
    }

    function internalLiquidate(IAmm _amm, address _trader) internal returns (uint256 quoteAssetAmount, bool isPartialClose) {
        requireAmm(_amm, true);
        int256 marginRatio = getMarginRatio(_amm, _trader);
        // // once oracle price is updated ervery funding payment, this part has no longer effect
        // // including oracle-based margin ratio as reference price when amm is over spread limit
        // if (_amm.isOverSpreadLimit()) {
        //     int256 marginRatioBasedOnOracle = _getMarginRatioByCalcOption(_amm, _trader, PnlCalcOption.ORACLE);
        //     if (marginRatioBasedOnOracle - marginRatio > 0) {
        //         marginRatio = marginRatioBasedOnOracle;
        //     }
        // }
        requireMoreMarginRatio(marginRatio, maintenanceMarginRatio, false);

        PositionResp memory positionResp;
        uint256 liquidationPenalty;
        {
            uint256 liquidationBadDebt;
            uint256 feeToLiquidator;
            uint256 feeToInsuranceFund;

            // int256 marginRatioBasedOnSpot = _getMarginRatioByCalcOption(_amm, _trader, PnlCalcOption.SPOT_PRICE);
            if (
                // check margin(based on spot price) is enough to pay the liquidation fee
                // after partially close, otherwise we fully close the position.
                // that also means we can ensure no bad debt happen when partially liquidate
                marginRatio > int256(liquidationFeeRatio) && partialLiquidationRatio < 1 ether && partialLiquidationRatio != 0
            ) {
                Position memory position = getPosition(_amm, _trader);
                uint256 partiallyLiquidatedPositionNotional = _amm.getOutputPrice(
                    position.size > 0 ? IAmm.Dir.ADD_TO_AMM : IAmm.Dir.REMOVE_FROM_AMM,
                    position.size.mulD(partialLiquidationRatio.toInt()).abs()
                );

                positionResp = openReversePosition(
                    _amm,
                    position.size > 0 ? Side.SELL : Side.BUY,
                    _trader,
                    partiallyLiquidatedPositionNotional,
                    1 ether,
                    0,
                    true
                );

                // half of the liquidationFee goes to liquidator & another half goes to insurance fund
                liquidationPenalty = positionResp.exchangedQuoteAssetAmount.mulD(liquidationFeeRatio);
                feeToLiquidator = liquidationPenalty / 2;
                feeToInsuranceFund = liquidationPenalty - feeToLiquidator;

                positionResp.position.margin = positionResp.position.margin - liquidationPenalty;
                setPosition(_amm, _trader, positionResp.position);

                isPartialClose = true;
            } else {
                liquidationPenalty = getPosition(_amm, _trader).margin;
                positionResp = internalClosePosition(_amm, _trader, 0);
                uint256 remainMargin = positionResp.marginToVault.abs();
                feeToLiquidator = positionResp.exchangedQuoteAssetAmount.mulD(liquidationFeeRatio) / 2;

                // if the remainMargin is not enough for liquidationFee, count it as bad debt
                // else, then the rest will be transferred to insuranceFund
                uint256 totalBadDebt = positionResp.badDebt;
                if (feeToLiquidator > remainMargin) {
                    liquidationBadDebt = feeToLiquidator - remainMargin;
                    totalBadDebt = totalBadDebt + liquidationBadDebt;
                    remainMargin = 0;
                } else {
                    remainMargin = remainMargin - feeToLiquidator;
                }

                // transfer the actual token between trader and vault
                if (totalBadDebt > 0) {
                    require(backstopLiquidityProviderMap[_msgSender()], "not backstop LP");
                    realizeBadDebt(_amm, totalBadDebt);
                }
                if (remainMargin > 0) {
                    feeToInsuranceFund = remainMargin;
                }
            }

            if (feeToInsuranceFund > 0) {
                transferToInsuranceFund(_amm, feeToInsuranceFund);
            }
            withdraw(_amm, _msgSender(), feeToLiquidator);
            enterRestrictionMode(_amm);

            emit PositionLiquidated(
                _trader,
                address(_amm),
                positionResp.exchangedQuoteAssetAmount,
                positionResp.exchangedPositionSize.toUint(),
                feeToLiquidator,
                _msgSender(),
                liquidationBadDebt
            );
        }

        // emit event
        uint256 spotPrice = _amm.getSpotPrice();
        int256 fundingPayment = positionResp.fundingPayment;
        emit PositionChanged(
            _trader,
            address(_amm),
            positionResp.position.margin,
            positionResp.exchangedQuoteAssetAmount,
            positionResp.exchangedPositionSize,
            0,
            positionResp.position.size,
            positionResp.realizedPnl,
            positionResp.unrealizedPnlAfter,
            positionResp.badDebt,
            liquidationPenalty,
            spotPrice,
            fundingPayment
        );

        return (positionResp.exchangedQuoteAssetAmount, isPartialClose);
    }

    // only called from openPosition and closeAndOpenReversePosition. caller need to ensure there's enough marginRatio
    function internalIncreasePosition(
        IAmm _amm,
        Side _side,
        uint256 _openNotional,
        uint256 _minPositionSize,
        uint256 _leverage
    ) internal returns (PositionResp memory positionResp) {
        address trader = _msgSender();
        Position memory oldPosition = getPosition(_amm, trader);
        positionResp.exchangedPositionSize = swapInput(_amm, _side, _openNotional, _minPositionSize, false);
        int256 newSize = oldPosition.size + positionResp.exchangedPositionSize;

        updateOpenInterestNotional(_amm, _openNotional.toInt());
        // if the trader is not in the whitelist, check max position size
        if (trader != whitelist) {
            uint256 maxHoldingBaseAsset = _amm.getMaxHoldingBaseAsset();
            if (maxHoldingBaseAsset > 0) {
                // total position size should be less than `positionUpperBound`
                require(newSize.abs() <= maxHoldingBaseAsset, "hit position size upper bound"); //hit position size upper bound
            }
        }

        int256 increaseMarginRequirement = _openNotional.divD(_leverage).toInt();
        (
            uint256 remainMargin, // the 2nd return (bad debt) must be 0 - already checked from caller
            ,
            int256 fundingPayment,
            int256 latestCumulativePremiumFraction
        ) = calcRemainMarginWithFundingPayment(_amm, oldPosition, increaseMarginRequirement);

        (, int256 unrealizedPnl) = getPositionNotionalAndUnrealizedPnl(_amm, trader, PnlCalcOption.SPOT_PRICE);

        // update positionResp
        positionResp.exchangedQuoteAssetAmount = _openNotional;
        positionResp.unrealizedPnlAfter = unrealizedPnl;
        positionResp.marginToVault = increaseMarginRequirement;
        positionResp.fundingPayment = fundingPayment;
        positionResp.position = Position(
            newSize, //Number of base asset (e.g. BAYC)
            remainMargin,
            oldPosition.openNotional + positionResp.exchangedQuoteAssetAmount, //In Quote Asset (e.g. USDC)
            latestCumulativePremiumFraction,
            oldPosition.liquidityHistoryIndex,
            _blockNumber()
        );
    }

    function openReversePosition(
        IAmm _amm,
        Side _side,
        address _trader,
        uint256 _quoteAssetAmount,
        uint256 _leverage,
        uint256 _baseAssetAmountLimit,
        bool _canOverFluctuationLimit
    ) internal returns (PositionResp memory) {
        uint256 openNotional = _quoteAssetAmount.mulD(_leverage);
        (uint256 oldPositionNotional, int256 unrealizedPnl) = getPositionNotionalAndUnrealizedPnl(_amm, _trader, PnlCalcOption.SPOT_PRICE);
        PositionResp memory positionResp;

        // reduce position if old position is larger
        if (oldPositionNotional > openNotional) {
            updateOpenInterestNotional(_amm, openNotional.toInt() * -1);
            Position memory oldPosition = getPosition(_amm, _trader);
            positionResp.exchangedPositionSize = swapInput(_amm, _side, openNotional, _baseAssetAmountLimit, _canOverFluctuationLimit);

            // realizedPnl = unrealizedPnl * closedRatio
            // closedRatio = positionResp.exchangedPositionSiz / oldPosition.size
            if (oldPosition.size != 0) {
                positionResp.realizedPnl = unrealizedPnl.mulD(positionResp.exchangedPositionSize.abs().toInt()).divD(
                    oldPosition.size.abs().toInt()
                );
            }
            uint256 remainMargin;
            int256 latestCumulativePremiumFraction;
            (
                remainMargin,
                positionResp.badDebt,
                positionResp.fundingPayment,
                latestCumulativePremiumFraction
            ) = calcRemainMarginWithFundingPayment(_amm, oldPosition, positionResp.realizedPnl);

            // positionResp.unrealizedPnlAfter = unrealizedPnl - realizedPnl
            positionResp.unrealizedPnlAfter = unrealizedPnl - positionResp.realizedPnl;
            positionResp.exchangedQuoteAssetAmount = openNotional;

            // calculate openNotional (it's different depends on long or short side)
            // long: unrealizedPnl = positionNotional - openNotional => openNotional = positionNotional - unrealizedPnl
            // short: unrealizedPnl = openNotional - positionNotional => openNotional = positionNotional + unrealizedPnl
            // positionNotional = oldPositionNotional - exchangedQuoteAssetAmount
            int256 remainOpenNotional = oldPosition.size > 0
                ? oldPositionNotional.toInt() - positionResp.exchangedQuoteAssetAmount.toInt() - positionResp.unrealizedPnlAfter
                : positionResp.unrealizedPnlAfter + oldPositionNotional.toInt() - positionResp.exchangedQuoteAssetAmount.toInt();
            require(remainOpenNotional > 0, "value of openNotional <= 0");

            positionResp.position = Position(
                oldPosition.size + positionResp.exchangedPositionSize,
                remainMargin,
                remainOpenNotional.abs(),
                latestCumulativePremiumFraction,
                oldPosition.liquidityHistoryIndex,
                _blockNumber()
            );
            return positionResp;
        }

        return closeAndOpenReversePosition(_amm, _side, _trader, _quoteAssetAmount, _leverage, _baseAssetAmountLimit);
    }

    function closeAndOpenReversePosition(
        IAmm _amm,
        Side _side,
        address _trader,
        uint256 _quoteAssetAmount,
        uint256 _leverage,
        uint256 _baseAssetAmountLimit
    ) internal returns (PositionResp memory positionResp) {
        // new position size is larger than or equal to the old position size
        // so either close or close then open a larger position
        PositionResp memory closePositionResp = internalClosePosition(_amm, _trader, 0);

        // the old position is underwater. trader should close a position first
        require(closePositionResp.badDebt == 0, "reduce an underwater position");

        // update open notional after closing position
        uint256 openNotional = _quoteAssetAmount.mulD(_leverage) - closePositionResp.exchangedQuoteAssetAmount;

        // if remain exchangedQuoteAssetAmount is too small (eg. 1wei) then the required margin might be 0
        // then the clearingHouse will stop opening position
        if (openNotional.divD(_leverage) == 0) {
            positionResp = closePositionResp;
        } else {
            uint256 updatedBaseAssetAmountLimit;
            if (_baseAssetAmountLimit > closePositionResp.exchangedPositionSize.toUint()) {
                updatedBaseAssetAmountLimit = _baseAssetAmountLimit - closePositionResp.exchangedPositionSize.abs();
            }

            PositionResp memory increasePositionResp = internalIncreasePosition(
                _amm,
                _side,
                openNotional,
                updatedBaseAssetAmountLimit,
                _leverage
            );
            positionResp = PositionResp({
                position: increasePositionResp.position,
                exchangedQuoteAssetAmount: closePositionResp.exchangedQuoteAssetAmount + increasePositionResp.exchangedQuoteAssetAmount,
                badDebt: closePositionResp.badDebt + increasePositionResp.badDebt,
                fundingPayment: closePositionResp.fundingPayment + increasePositionResp.fundingPayment,
                exchangedPositionSize: closePositionResp.exchangedPositionSize + increasePositionResp.exchangedPositionSize,
                realizedPnl: closePositionResp.realizedPnl + increasePositionResp.realizedPnl,
                unrealizedPnlAfter: 0,
                marginToVault: closePositionResp.marginToVault + increasePositionResp.marginToVault
            });
        }
        return positionResp;
    }

    function internalClosePosition(
        IAmm _amm,
        address _trader,
        uint256 _quoteAssetAmountLimit
    ) private returns (PositionResp memory positionResp) {
        // check conditions
        Position memory oldPosition = getPosition(_amm, _trader);
        requirePositionSize(oldPosition.size);

        (, int256 unrealizedPnl) = getPositionNotionalAndUnrealizedPnl(_amm, _trader, PnlCalcOption.SPOT_PRICE);
        (uint256 remainMargin, uint256 badDebt, int256 fundingPayment, ) = calcRemainMarginWithFundingPayment(
            _amm,
            oldPosition,
            unrealizedPnl
        );

        positionResp.exchangedPositionSize = oldPosition.size * -1;
        positionResp.realizedPnl = unrealizedPnl;
        positionResp.badDebt = badDebt;
        positionResp.fundingPayment = fundingPayment;
        positionResp.marginToVault = remainMargin.toInt() * -1;
        // for amm.swapOutput, the direction is in base asset, from the perspective of Amm
        positionResp.exchangedQuoteAssetAmount = _amm.swapOutput(
            oldPosition.size > 0 ? IAmm.Dir.ADD_TO_AMM : IAmm.Dir.REMOVE_FROM_AMM,
            oldPosition.size.abs(),
            _quoteAssetAmountLimit
        );

        // bankrupt position's bad debt will be also consider as a part of the open interest
        updateOpenInterestNotional(_amm, (unrealizedPnl + badDebt.toInt() + oldPosition.openNotional.toInt()) * -1);
        clearPosition(_amm, _trader);
    }

    function swapInput(
        IAmm _amm,
        Side _side,
        uint256 _inputAmount,
        uint256 _minOutputAmount,
        bool _canOverFluctuationLimit
    ) internal returns (int256) {
        // for amm.swapInput, the direction is in quote asset, from the perspective of Amm
        IAmm.Dir dir = (_side == Side.BUY) ? IAmm.Dir.ADD_TO_AMM : IAmm.Dir.REMOVE_FROM_AMM;
        int256 outputAmount = _amm.swapInput(dir, _inputAmount, _minOutputAmount, _canOverFluctuationLimit).toInt();
        if (IAmm.Dir.REMOVE_FROM_AMM == dir) {
            return outputAmount * -1;
        }
        return outputAmount;
    }

    function transferFee(
        address _from,
        IAmm _amm,
        uint256 _positionNotional
    ) internal returns (uint256 fee) {
        // the logic of toll fee can be removed if the bytecode size is too large
        (uint256 toll, uint256 spread) = _amm.calcFee(_positionNotional);
        bool hasToll = toll > 0;
        bool hasSpread = spread > 0;
        if (hasToll || hasSpread) {
            IERC20 quoteAsset = _amm.quoteAsset();

            // transfer spread to market in order to use it to make market better
            if (hasSpread) {
                quoteAsset.safeTransferFrom(_from, address(insuranceFund), spread);
                totalFees[address(_amm)] += spread;
                totalMinusFees[address(_amm)] += spread;
                netRevenuesSinceLastFunding[address(_amm)] += spread.toInt();
            }

            // transfer toll to feePool
            if (hasToll) {
                require(address(feePool) != address(0), "Invalid"); //Invalid feePool
                quoteAsset.safeTransferFrom(_from, address(feePool), toll);
            }

            fee = toll + spread;
        }
    }

    function deposit(
        IAmm _amm,
        address _sender,
        uint256 _amount
    ) private {
        vaults[address(_amm)] += _amount;
        IERC20 quoteToken = _amm.quoteAsset();
        quoteToken.safeTransferFrom(_sender, address(this), _amount);
    }

    function withdraw(
        IAmm _amm,
        address _receiver,
        uint256 _amount
    ) internal {
        // if withdraw amount is larger than the balance of given Amm's vault
        // means this trader's profit comes from other under collateral position's future loss
        // and the balance of given Amm's vault is not enough
        // need money from IInsuranceFund to pay first, and record this prepaidBadDebt
        // in this case, insurance fund loss must be zero
        uint256 vault = vaults[address(_amm)];
        IERC20 quoteToken = _amm.quoteAsset();
        if (vault < _amount) {
            uint256 balanceShortage = _amount - vault;
            prepaidBadDebts[address(_amm)] += balanceShortage;
            withdrawFromInsuranceFund(_amm, balanceShortage);
        }
        vaults[address(_amm)] -= _amount;
        quoteToken.safeTransfer(_receiver, _amount);
    }

    function realizeBadDebt(IAmm _amm, uint256 _badDebt) internal {
        uint256 badDebtBalance = prepaidBadDebts[address(_amm)];
        if (badDebtBalance >= _badDebt) {
            // no need to move extra tokens because vault already prepay bad debt, only need to update the numbers
            prepaidBadDebts[address(_amm)] = badDebtBalance - _badDebt;
        } else {
            // in order to realize all the bad debt vault need extra tokens from insuranceFund
            withdrawFromInsuranceFund(_amm, _badDebt - badDebtBalance);
            prepaidBadDebts[address(_amm)] = 0;
        }
    }

    function withdrawFromInsuranceFund(IAmm _amm, uint256 _amount) private {
        IERC20 quoteToken = _amm.quoteAsset();
        vaults[address(_amm)] += _amount;
        insuranceFund.withdraw(quoteToken, _amount);
    }

    function transferToInsuranceFund(IAmm _amm, uint256 _amount) internal {
        IERC20 quoteToken = _amm.quoteAsset();
        uint256 vault = vaults[address(_amm)];
        if (vault > _amount) {
            vaults[address(_amm)] = vault - _amount;
            quoteToken.safeTransfer(address(insuranceFund), _amount);
        } else {
            vaults[address(_amm)] = 0;
            quoteToken.safeTransfer(address(insuranceFund), vault);
        }
    }

    /**
     * @dev assume this will be removes soon once the guarded period has ended. caller need to ensure amm exist
     */
    function updateOpenInterestNotional(IAmm _amm, int256 _amount) internal {
        // when cap = 0 means no cap
        uint256 cap = _amm.getOpenInterestNotionalCap();
        address ammAddr = address(_amm);
        if (cap > 0) {
            int256 updatedOpenInterestNotional = _amount + openInterestNotionalMap[ammAddr].toInt();
            // the reduced open interest can be larger than total when profit is too high and other position are bankrupt
            if (updatedOpenInterestNotional < 0) {
                updatedOpenInterestNotional = 0;
            }
            if (_amount > 0) {
                // whitelist won't be restrict by open interest cap
                require(updatedOpenInterestNotional.toUint() <= cap || _msgSender() == whitelist, "over limit");
            }
            openInterestNotionalMap[ammAddr] = updatedOpenInterestNotional.abs();
        }
    }

    //
    // INTERNAL VIEW FUNCTIONS
    //

    function calcRemainMarginWithFundingPayment(
        IAmm _amm,
        Position memory _oldPosition,
        int256 _marginDelta
    )
        private
        view
        returns (
            uint256 remainMargin,
            uint256 badDebt,
            int256 fundingPayment,
            int256 latestCumulativePremiumFraction
        )
    {
        // calculate funding payment
        latestCumulativePremiumFraction = getLatestCumulativePremiumFraction(_amm);
        if (_oldPosition.size != 0) {
            fundingPayment = (latestCumulativePremiumFraction - _oldPosition.lastUpdatedCumulativePremiumFraction).mulD(_oldPosition.size);
        }

        // calculate remain margin
        int256 signedRemainMargin = _marginDelta - fundingPayment + _oldPosition.margin.toInt();

        // if remain margin is negative, set to zero and leave the rest to bad debt
        if (signedRemainMargin < 0) {
            badDebt = signedRemainMargin.abs();
        } else {
            remainMargin = signedRemainMargin.abs();
        }
    }

    /// @param _marginWithFundingPayment margin + funding payment - bad debt
    function calcFreeCollateral(
        IAmm _amm,
        address _trader,
        uint256 _marginWithFundingPayment
    ) internal view returns (int256) {
        Position memory pos = getPosition(_amm, _trader);
        (int256 unrealizedPnl, uint256 positionNotional) = getPreferencePositionNotionalAndUnrealizedPnl(
            _amm,
            _trader,
            PnlPreferenceOption.MIN_PNL
        );

        // min(margin + funding, margin + funding + unrealized PnL) - position value * initMarginRatio
        int256 accountValue = unrealizedPnl + _marginWithFundingPayment.toInt();
        int256 minCollateral = unrealizedPnl > 0 ? _marginWithFundingPayment.toInt() : accountValue;

        // margin requirement
        // if holding a long position, using open notional (mapping to quote debt in Curie)
        // if holding a short position, using position notional (mapping to base debt in Curie)
        int256 marginRequirement = pos.size > 0
            ? pos.openNotional.toInt().mulD(initMarginRatio.toInt())
            : positionNotional.toInt().mulD(initMarginRatio.toInt());

        return minCollateral - marginRequirement;
    }

    function getPreferencePositionNotionalAndUnrealizedPnl(
        IAmm _amm,
        address _trader,
        PnlPreferenceOption _pnlPreference
    ) internal view returns (int256 unrealizedPnl, uint256 positionNotional) {
        (uint256 spotPositionNotional, int256 spotPricePnl) = (
            getPositionNotionalAndUnrealizedPnl(_amm, _trader, PnlCalcOption.SPOT_PRICE)
        );
        (uint256 twapPositionNotional, int256 twapPricePnl) = (getPositionNotionalAndUnrealizedPnl(_amm, _trader, PnlCalcOption.TWAP));

        // if MAX_PNL
        //    spotPnL >  twapPnL return (spotPnL, spotPositionNotional)
        //    spotPnL <= twapPnL return (twapPnL, twapPositionNotional)
        // if MIN_PNL
        //    spotPnL >  twapPnL return (twapPnL, twapPositionNotional)
        //    spotPnL <= twapPnL return (spotPnL, spotPositionNotional)
        (unrealizedPnl, positionNotional) = (_pnlPreference == PnlPreferenceOption.MAX_PNL) == (spotPricePnl > twapPricePnl)
            ? (spotPricePnl, spotPositionNotional)
            : (twapPricePnl, twapPositionNotional);
    }

    function getUnadjustedPosition(IAmm _amm, address _trader) public view returns (Position memory position) {
        position = ammMap[address(_amm)].positionMap[_trader];
    }

    //
    // REQUIRE FUNCTIONS
    //
    function requireAmm(IAmm _amm, bool _open) private view {
        require(insuranceFund.isExistedAmm(_amm), "amm not found");
        require(_open == _amm.open(), _open ? "amm was closed" : "amm is open");
    }

    function requireNonZeroInput(uint256 _decimal) private pure {
        require(_decimal != 0, "input is 0");
    }

    function requirePositionSize(int256 _size) private pure {
        require(_size != 0, "positionSize is 0");
    }

    function requireValidTokenAmount(uint256 _decimal) private pure {
        require(_decimal != 0, "invalid token amount");
    }

    function requireNotRestrictionMode(IAmm _amm) private view {
        uint256 currentBlock = _blockNumber();
        if (currentBlock == ammMap[address(_amm)].lastRestrictionBlock) {
            require(getPosition(_amm, _msgSender()).blockNumber != currentBlock, "only one action allowed");
        }
    }

    function requireMoreMarginRatio(
        int256 _marginRatio,
        uint256 _baseMarginRatio,
        bool _largerThanOrEqualTo
    ) private pure {
        int256 remainingMarginRatio = _marginRatio - _baseMarginRatio.toInt();
        require(_largerThanOrEqualTo ? remainingMarginRatio >= 0 : remainingMarginRatio < 0, "Margin ratio not meet criteria");
    }

    function formulaicRepegAmm(IAmm _amm) private {
        // Only a portion of the protocol fees are allocated to repegging
        uint256 totalFee = totalFees[address(_amm)];
        uint256 totalMinusFee = totalMinusFees[address(_amm)];
        uint256 budget = totalMinusFee > totalFee / 2 ? totalMinusFee - totalFee / 2 : 0;
        (bool isAdjustable, int256 cost, uint256 newQuoteAssetReserve, uint256 newBaseAssetReserve) = _amm.getFormulaicRepegResult(
            budget,
            true
        );
        if (isAdjustable && applyCost(_amm, cost)) {
            _amm.adjust(newQuoteAssetReserve, newBaseAssetReserve);
            emit Repeg(address(_amm), newQuoteAssetReserve, newBaseAssetReserve, cost);
        }
    }

    // if fundingImbalance is positive, clearing house receives funds
    function formulaicUpdateK(IAmm _amm, int256 _fundingImbalance) private {
        int256 netRevenue = netRevenuesSinceLastFunding[address(_amm)];
        int256 budget;
        if (_fundingImbalance > 0) {
            // positive cost is period revenue, give back half in k increase
            budget = _fundingImbalance / 2;
        } else if (netRevenue < -_fundingImbalance) {
            // cost exceeded period revenue, take back half in k decrease
            if (netRevenue < 0) {
                budget = _fundingImbalance / 2;
            } else {
                budget = (netRevenue + _fundingImbalance) / 2;
            }
        }
        (bool isAdjustable, int256 cost, uint256 newQuoteAssetReserve, uint256 newBaseAssetReserve) = _amm.getFormulaicUpdateKResult(
            budget
        );
        if (isAdjustable && applyCost(_amm, cost)) {
            _amm.adjust(newQuoteAssetReserve, newBaseAssetReserve);
            emit UpdateK(address(_amm), newQuoteAssetReserve, newBaseAssetReserve, cost);
        }
    }

    /**
     * @notice repeg amm according to off-chain calculation for the healthy of market
     * @dev only the operator can call this function
     * @param _amm IAmm address
     * @param _newQuoteAssetReserve the quote asset amount to be repegged
     */
    function repegAmm(IAmm _amm, uint256 _newQuoteAssetReserve) external onlyOperator {
        (uint256 quoteAssetReserve, uint256 baseAssetReserve) = _amm.getReserve();
        int256 positionSize = _amm.getBaseAssetDelta();
        int256 cost = AmmMath.adjustPegCost(quoteAssetReserve, baseAssetReserve, positionSize, _newQuoteAssetReserve);

        uint256 totalFee = totalFees[address(_amm)];
        uint256 totalMinusFee = totalMinusFees[address(_amm)];
        uint256 budget = totalMinusFee > totalFee / 2 ? totalMinusFee - totalFee / 2 : 0;
        require(cost <= 0 || cost.abs() <= budget, "insufficient fee pool");
        require(applyCost(_amm, cost), "failed to apply cost");
        _amm.adjust(_newQuoteAssetReserve, baseAssetReserve);
        emit Repeg(address(_amm), _newQuoteAssetReserve, baseAssetReserve, cost);
    }

    /**
     * @notice adjust K of amm according to off-chain calculation for the healthy of market
     * @dev only the operator can call this function
     * @param _amm IAmm address
     * @param _scaleNum the numerator of K scale to be adjusted
     * @param _scaleDenom the denominator of K scale to be adjusted
     */
    function adjustK(
        IAmm _amm,
        uint256 _scaleNum,
        uint256 _scaleDenom
    ) external onlyOperator {
        (uint256 quoteAssetReserve, uint256 baseAssetReserve) = _amm.getReserve();
        int256 positionSize = _amm.getBaseAssetDelta();
        (int256 cost, uint256 newQuoteAssetReserve, uint256 newBaseAssetReserve) = AmmMath.adjustKCost(
            quoteAssetReserve,
            baseAssetReserve,
            positionSize,
            _scaleNum,
            _scaleDenom
        );

        uint256 totalFee = totalFees[address(_amm)];
        uint256 totalMinusFee = totalMinusFees[address(_amm)];
        uint256 budget = totalMinusFee > totalFee / 2 ? totalMinusFee - totalFee / 2 : 0;
        require(cost <= 0 || cost.abs() <= budget, "insufficient fee pool");
        require(applyCost(_amm, cost), "failed to apply cost");
        _amm.adjust(newQuoteAssetReserve, newBaseAssetReserve);
        emit UpdateK(address(_amm), newQuoteAssetReserve, newBaseAssetReserve, cost);
    }

    // negative cost is revenue, otherwise is expense of insurance fund
    function applyCost(IAmm _amm, int256 _cost) private returns (bool) {
        uint256 totalMinusFee = totalMinusFees[address(_amm)];
        uint256 costAbs = _cost.abs();
        if (_cost > 0) {
            if (costAbs <= totalMinusFee) {
                totalMinusFees[address(_amm)] = totalMinusFee - costAbs;
                withdrawFromInsuranceFund(_amm, costAbs);
            } else {
                return false;
            }
        } else {
            totalMinusFees[address(_amm)] = totalMinusFee + costAbs;
            transferToInsuranceFund(_amm, costAbs);
        }
        netRevenuesSinceLastFunding[address(_amm)] = netRevenuesSinceLastFunding[address(_amm)] - _cost;
        return true;
    }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;

import { PausableUpgradeable } from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract OwnerPausableUpgradeSafe is OwnableUpgradeable, PausableUpgradeable {
    function __OwnerPausable_init() internal initializer {
        __Ownable_init();
        __Pausable_init();
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    uint256[50] private __gap;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IMultiTokenRewardRecipient {
    function notifyTokenAmount(IERC20 _token, uint256 _amount) external;
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

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

library TransferHelper {
    /// @notice Transfers tokens from the targeted address to the given destination
    /// @notice Errors with 'STF' if transfer fails
    /// @param token The contract address of the token to be transferred
    /// @param from The originating address from which the tokens will be transferred
    /// @param to The destination address of the transfer
    /// @param value The amount to be transferred
    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) =
            address(token).call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'STF');
    }

    /// @notice Transfers tokens from msg.sender to a recipient
    /// @dev Errors with ST if transfer fails
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'ST');
    }

    /// @notice Approves the stipulated contract to spend the given allowance in the given token
    /// @dev Errors with 'SA' if transfer fails
    /// @param token The contract address of the token to be approved
    /// @param to The target of the approval
    /// @param value The amount of the given token the target will be allowed to spend
    function safeApprove(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(IERC20.approve.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'SA');
    }

    // /// @notice Transfers ETH to the recipient address
    // /// @dev Fails with `STE`
    // /// @param to The destination of the transfer
    // /// @param value The value to be transferred
    // function safeTransferETH(address to, uint256 value) internal {
    //     (bool success, ) = to.call{value: value}(new bytes(0));
    //     require(success, 'STE');
    // }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
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