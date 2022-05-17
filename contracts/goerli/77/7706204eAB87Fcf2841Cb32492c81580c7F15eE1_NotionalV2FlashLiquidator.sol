// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.0;
pragma abicoder v2;

import "NotionalV2FlashLiquidatorBase.sol";
import "SafeInt256.sol";

contract NotionalV2FlashLiquidator is NotionalV2FlashLiquidatorBase {
    using SafeInt256 for int256;
    using SafeMath for uint256;

    constructor(
        NotionalProxy notionalV2_,
        address lendingPool_,
        address weth_,
        address cETH_,
        address stETH_,
        address owner_,
        address dex1,
        address dex2
    )
        NotionalV2FlashLiquidatorBase(
            notionalV2_,
            lendingPool_,
            weth_,
            cETH_,
            stETH_,
            owner_,
            dex1,
            dex2
        )
    {}

    function _redeemAndWithdraw(
        uint16 nTokenCurrencyId,
        uint96 nTokenBalance,
        bool redeemToUnderlying
    ) internal override {
        BalanceAction[] memory action = new BalanceAction[](1);
        // If nTokenBalance is zero still try to withdraw entire cash balance
        action[0].actionType = nTokenBalance == 0
            ? DepositActionType.None
            : DepositActionType.RedeemNToken;
        action[0].currencyId = nTokenCurrencyId;
        action[0].depositActionAmount = nTokenBalance;
        action[0].withdrawEntireCashBalance = true;
        action[0].redeemToUnderlying = redeemToUnderlying;
        NotionalV2.batchBalanceAction(address(this), action);
    }

    function _sellfCashAssets(
        uint16 fCashCurrency,
        uint256[] memory fCashMaturities,
        int256[] memory fCashNotional,
        uint256 depositActionAmount,
        bool redeemToUnderlying
    ) internal override {
        uint256 blockTime = block.timestamp;
        BalanceActionWithTrades[] memory action = new BalanceActionWithTrades[](1);
        action[0].actionType = depositActionAmount > 0
            ? DepositActionType.DepositAsset
            : DepositActionType.None;
        action[0].depositActionAmount = depositActionAmount;
        action[0].currencyId = fCashCurrency;
        action[0].withdrawEntireCashBalance = true;
        action[0].redeemToUnderlying = redeemToUnderlying;

        uint256 numTrades;
        bytes32[] memory trades = new bytes32[](fCashMaturities.length);
        for (uint256 i; i < fCashNotional.length; i++) {
            if (fCashNotional[i] == 0) continue;
            (uint256 marketIndex, bool isIdiosyncratic) = DateTime.getMarketIndex(
                7,
                fCashMaturities[i],
                blockTime
            );
            // We don't trade it out here but if the contract does take on idiosyncratic cash we need to be careful
            if (isIdiosyncratic) continue;

            trades[numTrades] = bytes32(
                (uint256(fCashNotional[i] > 0 ? TradeActionType.Borrow : TradeActionType.Lend) <<
                    248) |
                    (marketIndex << 240) |
                    (uint256(uint88(fCashNotional[i].abs())) << 152)
            );
            numTrades++;
        }

        if (numTrades < trades.length) {
            // Shrink the trades array to length if it is not full
            bytes32[] memory newTrades = new bytes32[](numTrades);
            for (uint256 i; i < numTrades; i++) {
                newTrades[i] = trades[i];
            }
            action[0].trades = newTrades;
        } else {
            action[0].trades = trades;
        }

        NotionalV2.batchBalanceAndTradeAction(address(this), action);
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "invalid new owner");
        owner = newOwner;
    }

    function wrapToWETH() external {
        _wrapToWETH();
    }

    function withdraw(address token, uint256 amount) external {
        IERC20(token).transfer(owner, amount);
    }

    receive() external payable {}
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.0;
pragma abicoder v2;

import "NotionalV2BaseLiquidator.sol";
import "NotionalV2UniV3SwapRouter.sol";
import "SafeInt256.sol";
import "NotionalProxy.sol";
import "CTokenInterface.sol";
import "CErc20Interface.sol";
import "CEtherInterface.sol";
import "IFlashLender.sol";
import "IFlashLoanReceiver.sol";
import "IERC20.sol";
import "SafeMath.sol";

abstract contract NotionalV2FlashLiquidatorBase is NotionalV2BaseLiquidator, IFlashLoanReceiver {
    using SafeInt256 for int256;
    using SafeMath for uint256;

    address public immutable LENDING_POOL;
    address public immutable DEX_1;
    address public immutable DEX_2;

    constructor(
        NotionalProxy notionalV2_,
        address lendingPool_,
        address weth_,
        address cETH_,
        address stETH_,
        address owner_,
        address dex1,
        address dex2
    ) NotionalV2BaseLiquidator(notionalV2_, weth_, cETH_, stETH_, owner_) {
        LENDING_POOL = lendingPool_;
        DEX_1 = dex1;
        DEX_2 = dex2;
    }

    function setCTokenAddress(address cToken) external onlyOwner {
        address underlying = _setCTokenAddress(cToken);
        // Lending pool needs to be able to pull underlying
        checkAllowanceOrSet(underlying, LENDING_POOL);
    }

    // Profit estimation
    function flashLoan(
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata modes,
        bytes calldata params,
        address collateralAddress
    ) external onlyOwner returns (uint256 localProfit, uint256 collateralProfit) {
        IFlashLender(LENDING_POOL).flashLoan(
            address(this),
            assets,
            amounts,
            modes,
            address(this),
            params,
            0
        );
        localProfit = IERC20(assets[0]).balanceOf(address(this));
        collateralProfit = collateralAddress == address(0) ? 0 : IERC20(collateralAddress).balanceOf(address(this));
    }

    function executeOperation(
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata premiums,
        address initiator,
        bytes calldata params
    ) external override returns (bool) {
        require(msg.sender == LENDING_POOL); // dev: unauthorized caller
        LiquidationAction memory action = abi.decode(params, ((LiquidationAction)));

        // Mint cTokens for incoming assets, if required. If there are transfer fees
        // the we deposit underlying instead inside each _liquidate call instead
        if (!action.hasTransferFee) _mintCTokens(assets, amounts);

        if (LiquidationType(action.liquidationType) == LiquidationType.LocalCurrency) {
            _liquidateLocal(action, assets);
        } else if (LiquidationType(action.liquidationType) == LiquidationType.CollateralCurrency) {
            _liquidateCollateral(action, assets);
        } else if (LiquidationType(action.liquidationType) == LiquidationType.LocalfCash) {
            _liquidateLocalfCash(action, assets);
        } else if (LiquidationType(action.liquidationType) == LiquidationType.CrossCurrencyfCash) {
            _liquidateCrossCurrencyfCash(action, assets);
        }

        _redeemCTokens(assets);

        if (
            LiquidationType(action.liquidationType) == LiquidationType.CollateralCurrency ||
            LiquidationType(action.liquidationType) == LiquidationType.CrossCurrencyfCash
        ) {
            _dexTrade(action);
        }

        if (action.withdrawProfit) {
            _withdrawProfit(assets[0], amounts[0].add(premiums[0]));
        }

        // The lending pool should have enough approval to pull the required amount from the contract
        return true;
    }

    function _withdrawProfit(address currency, uint256 threshold) internal {
        // Transfer profit to OWNER
        uint256 bal = IERC20(currency).balanceOf(address(this));
        if (bal > threshold) {
            IERC20(currency).transfer(owner, bal.sub(threshold));
        }
    }

    function _dexTrade(LiquidationAction memory action) internal {
        address collateralUnderlyingAddress;

        if (LiquidationType(action.liquidationType) == LiquidationType.CollateralCurrency) {
            CollateralCurrencyLiquidation memory liquidation = abi.decode(
                action.payload,
                (CollateralCurrencyLiquidation)
            );

            collateralUnderlyingAddress = liquidation.collateralUnderlyingAddress;
            _executeDexTrade(0, liquidation.tradeData);
        } else {
            CrossCurrencyfCashLiquidation memory liquidation = abi.decode(
                action.payload,
                (CrossCurrencyfCashLiquidation)
            );

            collateralUnderlyingAddress = liquidation.fCashUnderlyingAddress;
            _executeDexTrade(0, liquidation.tradeData);
        }

        if (action.withdrawProfit) {
            _withdrawProfit(collateralUnderlyingAddress, 0);
        }
    }

    function _executeDexTrade(uint256 ethValue, TradeData memory tradeData) internal {
        require(
            tradeData.dexAddress == DEX_1 || tradeData.dexAddress == DEX_2,
            "bad exchange address"
        );

        // prettier-ignore
        (bool success, /* return value */) = tradeData.dexAddress.call{value: ethValue}(tradeData.params);
        require(success, "dex trade failed");
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >0.7.0;
pragma experimental ABIEncoderV2;

import "IERC20.sol";
import "NotionalProxy.sol";
import "CErc20Interface.sol";
import "CEtherInterface.sol";
import "WETH9.sol";
import "IStakedETH.sol";
import "NotionalV2LiquidatorStorageLayoutV1.sol";
import "DateTime.sol";
import "SafeInt256.sol";

struct LiquidationAction {
    uint8 liquidationType;
    bool withdrawProfit;
    bool hasTransferFee;
    bytes payload;
}

struct LocalCurrencyLiquidation {
    address liquidateAccount;
    uint16 localCurrency;
    uint96 maxNTokenLiquidation;
}

struct CollateralCurrencyLiquidation {
    address liquidateAccount;
    uint16 localCurrency;
    address localCurrencyAddress;
    uint16 collateralCurrency;
    address collateralAddress;
    address collateralUnderlyingAddress;
    uint128 maxCollateralLiquidation;
    uint96 maxNTokenLiquidation;
    TradeData tradeData;
}

struct LocalfCashLiquidation {
    address liquidateAccount;
    uint16 localCurrency;
    uint256[] fCashMaturities;
    uint256[] maxfCashLiquidateAmounts;
}

struct CrossCurrencyfCashLiquidation {
    address liquidateAccount;
    uint16 localCurrency;
    address localCurrencyAddress;
    uint16 fCashCurrency;
    address fCashAddress;
    address fCashUnderlyingAddress;
    uint256[] fCashMaturities;
    uint256[] maxfCashLiquidateAmounts;
    TradeData tradeData;
}

struct TradeData {
    address dexAddress;
    bytes params;
}

enum LiquidationType {
    LocalCurrency,
    CollateralCurrency,
    LocalfCash,
    CrossCurrencyfCash
}

abstract contract NotionalV2BaseLiquidator is NotionalV2LiquidatorStorageLayoutV1 {
    using SafeInt256 for int256;
    using SafeMath for uint256;

    NotionalProxy public immutable NotionalV2;
    address public immutable WETH;
    address public immutable cETH;
    address public immutable stETH;

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    constructor(
        NotionalProxy notionalV2_,
        address weth_,
        address cETH_,
        address stETH_,
        address owner_
    ) {
        NotionalV2 = notionalV2_;
        WETH = weth_;
        cETH = cETH_;
        stETH = stETH_;
        owner = owner_;
    }

    function checkAllowanceOrSet(address erc20, address spender) internal {
        if (IERC20(erc20).allowance(address(this), spender) < 2**128) {
            IERC20(erc20).approve(spender, type(uint256).max);
        }
    }

    function enableCToken(address cToken) external onlyOwner {
        _setCTokenAddress(cToken);
    }

    function approveToken(address token, address spender) external onlyOwner {
        IERC20(token).approve(spender, 0);
        IERC20(token).approve(spender, type(uint256).max);
    }

    function _setCTokenAddress(address cToken) internal returns (address) {
        address underlying = CTokenInterface(cToken).underlying();
        // Notional V2 needs to be able to pull cTokens
        checkAllowanceOrSet(cToken, address(NotionalV2));
        underlyingToCToken[underlying] = cToken;
        return underlying;
    }

    function _mintCTokens(address[] memory assets, uint256[] memory amounts) internal {
        for (uint256 i; i < assets.length; i++) {
            if (assets[i] == WETH) {
                // Withdraw WETH to ETH and mint CEth
                WETH9(WETH).withdraw(amounts[i]);
                CEtherInterface(cETH).mint{value: amounts[i]}();
            } else {
                address cToken = underlyingToCToken[assets[i]];
                if (cToken != address(0)) {
                    checkAllowanceOrSet(assets[i], cToken);
                    CErc20Interface(cToken).mint(amounts[i]);
                }
            }
        }
    }

    function _redeemCTokens(address[] memory assets) internal {
        // Redeem cTokens to underlying to repay the flash loan
        for (uint256 i; i < assets.length; i++) {
            address cToken = assets[i] == WETH ? cETH : underlyingToCToken[assets[i]];
            if (cToken == address(0)) continue;

            CErc20Interface(cToken).redeem(IERC20(cToken).balanceOf(address(this)));
            // Wrap ETH into WETH for repayment
            if (assets[i] == WETH && address(this).balance > 0) _wrapToWETH();
        }
    }

    function _liquidateLocal(LiquidationAction memory action, address[] memory assets) internal {
        LocalCurrencyLiquidation memory liquidation = abi.decode(
            action.payload,
            (LocalCurrencyLiquidation)
        );

        if (action.hasTransferFee) {
            // NOTE: This assumes that the first asset flash borrowed is the one with transfer fees
            uint256 amount = IERC20(assets[0]).balanceOf(address(this));
            checkAllowanceOrSet(assets[0], address(NotionalV2));
            NotionalV2.depositUnderlyingToken(address(this), liquidation.localCurrency, amount);
        }

        // prettier-ignore
        (
            /* int256 localAssetCashFromLiquidator */,
            int256 netNTokens
        ) = NotionalV2.liquidateLocalCurrency(
            liquidation.liquidateAccount, 
            liquidation.localCurrency, 
            liquidation.maxNTokenLiquidation
        );

        // Will withdraw entire cash balance. Don't redeem local currency here because it has been flash
        // borrowed and we need to redeem the entire balance to underlying for the flash loan repayment.
        _redeemAndWithdraw(liquidation.localCurrency, uint96(netNTokens), false);
    }

    function _liquidateCollateral(LiquidationAction memory action, address[] memory assets)
        internal
    {
        CollateralCurrencyLiquidation memory liquidation = abi.decode(
            action.payload,
            (CollateralCurrencyLiquidation)
        );

        if (action.hasTransferFee) {
            // NOTE: This assumes that the first asset flash borrowed is the one with transfer fees
            uint256 amount = IERC20(assets[0]).balanceOf(address(this));
            checkAllowanceOrSet(assets[0], address(NotionalV2));
            NotionalV2.depositUnderlyingToken(address(this), liquidation.localCurrency, amount);
        }

        // prettier-ignore
        (
            /* int256 localAssetCashFromLiquidator */,
            /* int256 collateralAssetCash */,
            int256 collateralNTokens
        ) = NotionalV2.liquidateCollateralCurrency(
            liquidation.liquidateAccount,
            liquidation.localCurrency,
            liquidation.collateralCurrency,
            liquidation.maxCollateralLiquidation,
            liquidation.maxNTokenLiquidation,
            true, // Withdraw collateral
            false // Redeem to underlying (will happen later)
        );

        // Redeem to underlying for collateral because it needs to be traded on the DEX
        _redeemAndWithdraw(liquidation.collateralCurrency, uint96(collateralNTokens), true);

        CErc20Interface(liquidation.collateralAddress).redeem(
            IERC20(liquidation.collateralAddress).balanceOf(address(this))
        );

        if (liquidation.collateralCurrency == 1) {
            // Wrap everything to WETH for trading
            _wrapToWETH();
        } else if (liquidation.collateralCurrency == 5) {
            // Unwrap to stETH for tradding
            _unwrapStakedETH();
        }

        // Will withdraw all cash balance, no need to redeem local currency, it will be
        // redeemed later
        if (action.hasTransferFee) _redeemAndWithdraw(liquidation.localCurrency, 0, false);
    }

    function _liquidateLocalfCash(LiquidationAction memory action, address[] memory assets)
        internal
    {
        LocalfCashLiquidation memory liquidation = abi.decode(
            action.payload,
            (LocalfCashLiquidation)
        );

        if (action.hasTransferFee) {
            // NOTE: This assumes that the first asset flash borrowed is the one with transfer fees
            uint256 amount = IERC20(assets[0]).balanceOf(address(this));
            checkAllowanceOrSet(assets[0], address(NotionalV2));
            NotionalV2.depositUnderlyingToken(address(this), liquidation.localCurrency, amount);
        }

        // prettier-ignore
        (
            int256[] memory fCashNotionalTransfers,
            int256 localAssetCashFromLiquidator
        ) = NotionalV2.liquidatefCashLocal(
            liquidation.liquidateAccount,
            liquidation.localCurrency,
            liquidation.fCashMaturities,
            liquidation.maxfCashLiquidateAmounts
        );

        // If localAssetCashFromLiquidator is negative (meaning the liquidator has received cash)
        // then when we will need to lend in order to net off the negative fCash. In this case we
        // will deposit the local asset cash back into notional.
        _sellfCashAssets(
            liquidation.localCurrency,
            liquidation.fCashMaturities,
            fCashNotionalTransfers,
            localAssetCashFromLiquidator < 0 ? uint256(localAssetCashFromLiquidator.abs()) : 0,
            false // No need to redeem to underlying here
        );

        // NOTE: no withdraw if _hasTransferFees, _sellfCashAssets with withdraw everything
    }

    function _liquidateCrossCurrencyfCash(LiquidationAction memory action, address[] memory assets)
        internal
    {
        CrossCurrencyfCashLiquidation memory liquidation = abi.decode(
            action.payload,
            (CrossCurrencyfCashLiquidation)
        );

        if (action.hasTransferFee) {
            // NOTE: This assumes that the first asset flash borrowed is the one with transfer fees
            uint256 amount = IERC20(assets[0]).balanceOf(address(this));
            checkAllowanceOrSet(assets[0], address(NotionalV2));
            NotionalV2.depositUnderlyingToken(address(this), liquidation.localCurrency, amount);
        }

        // prettier-ignore
        (
            int256[] memory fCashNotionalTransfers,
            /* int256 localAssetCashFromLiquidator */
        ) = NotionalV2.liquidatefCashCrossCurrency(
            liquidation.liquidateAccount,
            liquidation.localCurrency,
            liquidation.fCashCurrency,
            liquidation.fCashMaturities,
            liquidation.maxfCashLiquidateAmounts
        );

        // Redeem to underlying here, collateral is not specified as an input asset
        _sellfCashAssets(
            liquidation.fCashCurrency,
            liquidation.fCashMaturities,
            fCashNotionalTransfers,
            0,
            true
        );
        if (liquidation.fCashCurrency == 1) {
            // Wrap everything to WETH for trading
            _wrapToWETH();
        } else if (liquidation.fCashCurrency == 5) {
            // Unwrap to stETH for tradding
            _unwrapStakedETH();
        }

        // NOTE: no withdraw if _hasTransferFees, _sellfCashAssets with withdraw everything
    }

    function _sellfCashAssets(
        uint16 fCashCurrency,
        uint256[] memory fCashMaturities,
        int256[] memory fCashNotional,
        uint256 depositActionAmount,
        bool redeemToUnderlying
    ) internal virtual;

    function _redeemAndWithdraw(
        uint16 nTokenCurrencyId,
        uint96 nTokenBalance,
        bool redeemToUnderlying
    ) internal virtual;

    function _wrapToWETH() internal {
        WETH9(WETH).deposit{value: address(this).balance}();
    }

    function _unwrapStakedETH() internal {
        IStakedETH(stETH).unwrap(IStakedETH(stETH).balanceOf(address(this)));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.0;
pragma abicoder v2;

import "Types.sol";
import "nTokenERC20.sol";
import "nERC1155Interface.sol";
import "NotionalGovernance.sol";
import "NotionalCalculations.sol";
import "NotionalViews.sol";
import "NotionalTreasury.sol";

interface NotionalProxy is
    nTokenERC20,
    nERC1155Interface,
    NotionalGovernance,
    NotionalTreasury,
    NotionalCalculations,
    NotionalViews
{
    /** User trading events */
    event CashBalanceChange(
        address indexed account,
        uint16 indexed currencyId,
        int256 netCashChange
    );
    event nTokenSupplyChange(
        address indexed account,
        uint16 indexed currencyId,
        int256 tokenSupplyChange
    );
    event MarketsInitialized(uint16 currencyId);
    event SweepCashIntoMarkets(uint16 currencyId, int256 cashIntoMarkets);
    event SettledCashDebt(
        address indexed settledAccount,
        uint16 indexed currencyId,
        address indexed settler,
        int256 amountToSettleAsset,
        int256 fCashAmount
    );
    event nTokenResidualPurchase(
        uint16 indexed currencyId,
        uint40 indexed maturity,
        address indexed purchaser,
        int256 fCashAmountToPurchase,
        int256 netAssetCashNToken
    );
    event LendBorrowTrade(
        address indexed account,
        uint16 indexed currencyId,
        uint40 maturity,
        int256 netAssetCash,
        int256 netfCash
    );
    event AddRemoveLiquidity(
        address indexed account,
        uint16 indexed currencyId,
        uint40 maturity,
        int256 netAssetCash,
        int256 netfCash,
        int256 netLiquidityTokens
    );

    /// @notice Emitted once when incentives are migrated
    event IncentivesMigrated(
        uint16 currencyId,
        uint256 migrationEmissionRate,
        uint256 finalIntegralTotalSupply,
        uint256 migrationTime
    );

    /// @notice Emitted when reserve fees are accrued
    event ReserveFeeAccrued(uint16 indexed currencyId, int256 fee);
    /// @notice Emitted whenever an account context has updated
    event AccountContextUpdate(address indexed account);
    /// @notice Emitted when an account has assets that are settled
    event AccountSettled(address indexed account);
    /// @notice Emitted when an asset rate is settled
    event SetSettlementRate(uint256 indexed currencyId, uint256 indexed maturity, uint128 rate);

    /* Liquidation Events */
    event LiquidateLocalCurrency(
        address indexed liquidated,
        address indexed liquidator,
        uint16 localCurrencyId,
        int256 netLocalFromLiquidator
    );

    event LiquidateCollateralCurrency(
        address indexed liquidated,
        address indexed liquidator,
        uint16 localCurrencyId,
        uint16 collateralCurrencyId,
        int256 netLocalFromLiquidator,
        int256 netCollateralTransfer,
        int256 netNTokenTransfer
    );

    event LiquidatefCashEvent(
        address indexed liquidated,
        address indexed liquidator,
        uint16 localCurrencyId,
        uint16 fCashCurrency,
        int256 netLocalFromLiquidator,
        uint256[] fCashMaturities,
        int256[] fCashNotionalTransfer
    );

    /** UUPS Upgradeable contract calls */
    function upgradeTo(address newImplementation) external;

    function upgradeToAndCall(address newImplementation, bytes memory data) external payable;

    function getImplementation() external view returns (address);

    function owner() external view returns (address);

    function pauseRouter() external view returns (address);

    function pauseGuardian() external view returns (address);

    /** Initialize Markets Action */
    function initializeMarkets(uint16 currencyId, bool isFirstInit) external;

    function sweepCashIntoMarkets(uint16 currencyId) external;

    /** Redeem nToken Action */
    function nTokenRedeem(
        address redeemer,
        uint16 currencyId,
        uint96 tokensToRedeem_,
        bool sellTokenAssets,
        bool acceptResidualAssets
    ) external returns (int256);

    /** Account Action */
    function enableBitmapCurrency(uint16 currencyId) external;

    function settleAccount(address account) external;

    function depositUnderlyingToken(
        address account,
        uint16 currencyId,
        uint256 amountExternalPrecision
    ) external payable returns (uint256);

    function depositAssetToken(
        address account,
        uint16 currencyId,
        uint256 amountExternalPrecision
    ) external returns (uint256);

    function withdraw(
        uint16 currencyId,
        uint88 amountInternalPrecision,
        bool redeemToUnderlying
    ) external returns (uint256);

    /** Batch Action */
    function batchBalanceAction(address account, BalanceAction[] calldata actions) external payable;

    function batchBalanceAndTradeAction(address account, BalanceActionWithTrades[] calldata actions)
        external
        payable;

    function batchBalanceAndTradeActionWithCallback(
        address account,
        BalanceActionWithTrades[] calldata actions,
        bytes calldata callbackData
    ) external payable;

    /** Liquidation Action */
    function calculateLocalCurrencyLiquidation(
        address liquidateAccount,
        uint16 localCurrency,
        uint96 maxNTokenLiquidation
    ) external returns (int256, int256);

    function liquidateLocalCurrency(
        address liquidateAccount,
        uint16 localCurrency,
        uint96 maxNTokenLiquidation
    ) external returns (int256, int256);

    function calculateCollateralCurrencyLiquidation(
        address liquidateAccount,
        uint16 localCurrency,
        uint16 collateralCurrency,
        uint128 maxCollateralLiquidation,
        uint96 maxNTokenLiquidation
    )
        external
        returns (
            int256,
            int256,
            int256
        );

    function liquidateCollateralCurrency(
        address liquidateAccount,
        uint16 localCurrency,
        uint16 collateralCurrency,
        uint128 maxCollateralLiquidation,
        uint96 maxNTokenLiquidation,
        bool withdrawCollateral,
        bool redeemToUnderlying
    )
        external
        returns (
            int256,
            int256,
            int256
        );

    function calculatefCashLocalLiquidation(
        address liquidateAccount,
        uint16 localCurrency,
        uint256[] calldata fCashMaturities,
        uint256[] calldata maxfCashLiquidateAmounts
    ) external returns (int256[] memory, int256);

    function liquidatefCashLocal(
        address liquidateAccount,
        uint16 localCurrency,
        uint256[] calldata fCashMaturities,
        uint256[] calldata maxfCashLiquidateAmounts
    ) external returns (int256[] memory, int256);

    function calculatefCashCrossCurrencyLiquidation(
        address liquidateAccount,
        uint16 localCurrency,
        uint16 fCashCurrency,
        uint256[] calldata fCashMaturities,
        uint256[] calldata maxfCashLiquidateAmounts
    ) external returns (int256[] memory, int256);

    function liquidatefCashCrossCurrency(
        address liquidateAccount,
        uint16 localCurrency,
        uint16 fCashCurrency,
        uint256[] calldata fCashMaturities,
        uint256[] calldata maxfCashLiquidateAmounts
    ) external returns (int256[] memory, int256);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.0;
pragma abicoder v2;

import "AggregatorV2V3Interface.sol";
import "AssetRateAdapter.sol";

/// @notice Different types of internal tokens
///  - UnderlyingToken: underlying asset for a cToken (except for Ether)
///  - cToken: Compound interest bearing token
///  - cETH: Special handling for cETH tokens
///  - Ether: the one and only
///  - NonMintable: tokens that do not have an underlying (therefore not cTokens)
///  - aToken: Aave interest bearing tokens
enum TokenType {UnderlyingToken, cToken, cETH, Ether, NonMintable, aToken}

/// @notice Specifies the different trade action types in the system. Each trade action type is
/// encoded in a tightly packed bytes32 object. Trade action type is the first big endian byte of the
/// 32 byte trade action object. The schemas for each trade action type are defined below.
enum TradeActionType {
    // (uint8 TradeActionType, uint8 MarketIndex, uint88 fCashAmount, uint32 minImpliedRate, uint120 unused)
    Lend,
    // (uint8 TradeActionType, uint8 MarketIndex, uint88 fCashAmount, uint32 maxImpliedRate, uint128 unused)
    Borrow,
    // (uint8 TradeActionType, uint8 MarketIndex, uint88 assetCashAmount, uint32 minImpliedRate, uint32 maxImpliedRate, uint88 unused)
    AddLiquidity,
    // (uint8 TradeActionType, uint8 MarketIndex, uint88 tokenAmount, uint32 minImpliedRate, uint32 maxImpliedRate, uint88 unused)
    RemoveLiquidity,
    // (uint8 TradeActionType, uint32 Maturity, int88 fCashResidualAmount, uint128 unused)
    PurchaseNTokenResidual,
    // (uint8 TradeActionType, address CounterpartyAddress, int88 fCashAmountToSettle)
    SettleCashDebt
}

/// @notice Specifies different deposit actions that can occur during BalanceAction or BalanceActionWithTrades
enum DepositActionType {
    // No deposit action
    None,
    // Deposit asset cash, depositActionAmount is specified in asset cash external precision
    DepositAsset,
    // Deposit underlying tokens that are mintable to asset cash, depositActionAmount is specified in underlying token
    // external precision
    DepositUnderlying,
    // Deposits specified asset cash external precision amount into an nToken and mints the corresponding amount of
    // nTokens into the account
    DepositAssetAndMintNToken,
    // Deposits specified underlying in external precision, mints asset cash, and uses that asset cash to mint nTokens
    DepositUnderlyingAndMintNToken,
    // Redeems an nToken balance to asset cash. depositActionAmount is specified in nToken precision. Considered a deposit action
    // because it deposits asset cash into an account. If there are fCash residuals that cannot be sold off, will revert.
    RedeemNToken,
    // Converts specified amount of asset cash balance already in Notional to nTokens. depositActionAmount is specified in
    // Notional internal 8 decimal precision.
    ConvertCashToNToken
}

/// @notice Used internally for PortfolioHandler state
enum AssetStorageState {NoChange, Update, Delete, RevertIfStored}

/****** Calldata objects ******/

/// @notice Defines a balance action for batchAction
struct BalanceAction {
    // Deposit action to take (if any)
    DepositActionType actionType;
    uint16 currencyId;
    // Deposit action amount must correspond to the depositActionType, see documentation above.
    uint256 depositActionAmount;
    // Withdraw an amount of asset cash specified in Notional internal 8 decimal precision
    uint256 withdrawAmountInternalPrecision;
    // If set to true, will withdraw entire cash balance. Useful if there may be an unknown amount of asset cash
    // residual left from trading.
    bool withdrawEntireCashBalance;
    // If set to true, will redeem asset cash to the underlying token on withdraw.
    bool redeemToUnderlying;
}

/// @notice Defines a balance action with a set of trades to do as well
struct BalanceActionWithTrades {
    DepositActionType actionType;
    uint16 currencyId;
    uint256 depositActionAmount;
    uint256 withdrawAmountInternalPrecision;
    bool withdrawEntireCashBalance;
    bool redeemToUnderlying;
    // Array of tightly packed 32 byte objects that represent trades. See TradeActionType documentation
    bytes32[] trades;
}

/****** In memory objects ******/
/// @notice Internal object that represents settled cash balances
struct SettleAmount {
    uint256 currencyId;
    int256 netCashChange;
}

/// @notice Internal object that represents a token
struct Token {
    address tokenAddress;
    bool hasTransferFee;
    int256 decimals;
    TokenType tokenType;
    uint256 maxCollateralBalance;
}

/// @notice Internal object that represents an nToken portfolio
struct nTokenPortfolio {
    CashGroupParameters cashGroup;
    PortfolioState portfolioState;
    int256 totalSupply;
    int256 cashBalance;
    uint256 lastInitializedTime;
    bytes6 parameters;
    address tokenAddress;
}

/// @notice Internal object used during liquidation
struct LiquidationFactors {
    address account;
    // Aggregate free collateral of the account denominated in ETH underlying, 8 decimal precision
    int256 netETHValue;
    // Amount of net local currency asset cash before haircuts and buffers available
    int256 localAssetAvailable;
    // Amount of net collateral currency asset cash before haircuts and buffers available
    int256 collateralAssetAvailable;
    // Haircut value of nToken holdings denominated in asset cash, will be local or collateral nTokens based
    // on liquidation type
    int256 nTokenHaircutAssetValue;
    // nToken parameters for calculating liquidation amount
    bytes6 nTokenParameters;
    // ETH exchange rate from local currency to ETH
    ETHRate localETHRate;
    // ETH exchange rate from collateral currency to ETH
    ETHRate collateralETHRate;
    // Asset rate for the local currency, used in cross currency calculations to calculate local asset cash required
    AssetRateParameters localAssetRate;
    // Used during currency liquidations if the account has liquidity tokens
    CashGroupParameters collateralCashGroup;
    // Used during currency liquidations if it is only a calculation, defaults to false
    bool isCalculation;
}

/// @notice Internal asset array portfolio state
struct PortfolioState {
    // Array of currently stored assets
    PortfolioAsset[] storedAssets;
    // Array of new assets to add
    PortfolioAsset[] newAssets;
    uint256 lastNewAssetIndex;
    // Holds the length of stored assets after accounting for deleted assets
    uint256 storedAssetLength;
}

/// @notice In memory ETH exchange rate used during free collateral calculation.
struct ETHRate {
    // The decimals (i.e. 10^rateDecimalPlaces) of the exchange rate, defined by the rate oracle
    int256 rateDecimals;
    // The exchange rate from base to ETH (if rate invert is required it is already done)
    int256 rate;
    // Amount of buffer as a multiple with a basis of 100 applied to negative balances.
    int256 buffer;
    // Amount of haircut as a multiple with a basis of 100 applied to positive balances
    int256 haircut;
    // Liquidation discount as a multiple with a basis of 100 applied to the exchange rate
    // as an incentive given to liquidators.
    int256 liquidationDiscount;
}

/// @notice Internal object used to handle balance state during a transaction
struct BalanceState {
    uint16 currencyId;
    // Cash balance stored in balance state at the beginning of the transaction
    int256 storedCashBalance;
    // nToken balance stored at the beginning of the transaction
    int256 storedNTokenBalance;
    // The net cash change as a result of asset settlement or trading
    int256 netCashChange;
    // Net asset transfers into or out of the account
    int256 netAssetTransferInternalPrecision;
    // Net token transfers into or out of the account
    int256 netNTokenTransfer;
    // Net token supply change from minting or redeeming
    int256 netNTokenSupplyChange;
    // The last time incentives were claimed for this currency
    uint256 lastClaimTime;
    // Accumulator for incentives that the account no longer has a claim over
    uint256 accountIncentiveDebt;
}

/// @dev Asset rate used to convert between underlying cash and asset cash
struct AssetRateParameters {
    // Address of the asset rate oracle
    AssetRateAdapter rateOracle;
    // The exchange rate from base to quote (if invert is required it is already done)
    int256 rate;
    // The decimals of the underlying, the rate converts to the underlying decimals
    int256 underlyingDecimals;
}

/// @dev Cash group when loaded into memory
struct CashGroupParameters {
    uint16 currencyId;
    uint256 maxMarketIndex;
    AssetRateParameters assetRate;
    bytes32 data;
}

/// @dev A portfolio asset when loaded in memory
struct PortfolioAsset {
    // Asset currency id
    uint256 currencyId;
    uint256 maturity;
    // Asset type, fCash or liquidity token.
    uint256 assetType;
    // fCash amount or liquidity token amount
    int256 notional;
    // Used for managing portfolio asset state
    uint256 storageSlot;
    // The state of the asset for when it is written to storage
    AssetStorageState storageState;
}

/// @dev Market object as represented in memory
struct MarketParameters {
    bytes32 storageSlot;
    uint256 maturity;
    // Total amount of fCash available for purchase in the market.
    int256 totalfCash;
    // Total amount of cash available for purchase in the market.
    int256 totalAssetCash;
    // Total amount of liquidity tokens (representing a claim on liquidity) in the market.
    int256 totalLiquidity;
    // This is the previous annualized interest rate in RATE_PRECISION that the market traded
    // at. This is used to calculate the rate anchor to smooth interest rates over time.
    uint256 lastImpliedRate;
    // Time lagged version of lastImpliedRate, used to value fCash assets at market rates while
    // remaining resistent to flash loan attacks.
    uint256 oracleRate;
    // This is the timestamp of the previous trade
    uint256 previousTradeTime;
}

/****** Storage objects ******/

/// @dev Token object in storage:
///  20 bytes for token address
///  1 byte for hasTransferFee
///  1 byte for tokenType
///  1 byte for tokenDecimals
///  9 bytes for maxCollateralBalance (may not always be set)
struct TokenStorage {
    // Address of the token
    address tokenAddress;
    // Transfer fees will change token deposit behavior
    bool hasTransferFee;
    TokenType tokenType;
    uint8 decimalPlaces;
    // Upper limit on how much of this token the contract can hold at any time
    uint72 maxCollateralBalance;
}

/// @dev Exchange rate object as it is represented in storage, total storage is 25 bytes.
struct ETHRateStorage {
    // Address of the rate oracle
    AggregatorV2V3Interface rateOracle;
    // The decimal places of precision that the rate oracle uses
    uint8 rateDecimalPlaces;
    // True of the exchange rate must be inverted
    bool mustInvert;
    // NOTE: both of these governance values are set with BUFFER_DECIMALS precision
    // Amount of buffer to apply to the exchange rate for negative balances.
    uint8 buffer;
    // Amount of haircut to apply to the exchange rate for positive balances
    uint8 haircut;
    // Liquidation discount in percentage point terms, 106 means a 6% discount
    uint8 liquidationDiscount;
}

/// @dev Asset rate oracle object as it is represented in storage, total storage is 21 bytes.
struct AssetRateStorage {
    // Address of the rate oracle
    AssetRateAdapter rateOracle;
    // The decimal places of the underlying asset
    uint8 underlyingDecimalPlaces;
}

/// @dev Governance parameters for a cash group, total storage is 9 bytes + 7 bytes for liquidity token haircuts
/// and 7 bytes for rate scalars, total of 23 bytes. Note that this is stored packed in the storage slot so there
/// are no indexes stored for liquidityTokenHaircuts or rateScalars, maxMarketIndex is used instead to determine the
/// length.
struct CashGroupSettings {
    // Index of the AMMs on chain that will be made available. Idiosyncratic fCash
    // that is dated less than the longest AMM will be tradable.
    uint8 maxMarketIndex;
    // Time window in 5 minute increments that the rate oracle will be averaged over
    uint8 rateOracleTimeWindow5Min;
    // Total fees per trade, specified in BPS
    uint8 totalFeeBPS;
    // Share of the fees given to the protocol, denominated in percentage
    uint8 reserveFeeShare;
    // Debt buffer specified in 5 BPS increments
    uint8 debtBuffer5BPS;
    // fCash haircut specified in 5 BPS increments
    uint8 fCashHaircut5BPS;
    // If an account has a negative cash balance, it can be settled by incurring debt at the 3 month market. This
    // is the basis points for the penalty rate that will be added the current 3 month oracle rate.
    uint8 settlementPenaltyRate5BPS;
    // If an account has fCash that is being liquidated, this is the discount that the liquidator can purchase it for
    uint8 liquidationfCashHaircut5BPS;
    // If an account has fCash that is being liquidated, this is the discount that the liquidator can purchase it for
    uint8 liquidationDebtBuffer5BPS;
    // Liquidity token haircut applied to cash claims, specified as a percentage between 0 and 100
    uint8[] liquidityTokenHaircuts;
    // Rate scalar used to determine the slippage of the market
    uint8[] rateScalars;
}

/// @dev Holds account level context information used to determine settlement and
/// free collateral actions. Total storage is 28 bytes
struct AccountContext {
    // Used to check when settlement must be triggered on an account
    uint40 nextSettleTime;
    // For lenders that never incur debt, we use this flag to skip the free collateral check.
    bytes1 hasDebt;
    // Length of the account's asset array
    uint8 assetArrayLength;
    // If this account has bitmaps set, this is the corresponding currency id
    uint16 bitmapCurrencyId;
    // 9 total active currencies possible (2 bytes each)
    bytes18 activeCurrencies;
}

/// @dev Holds nToken context information mapped via the nToken address, total storage is
/// 16 bytes
struct nTokenContext {
    // Currency id that the nToken represents
    uint16 currencyId;
    // Annual incentive emission rate denominated in WHOLE TOKENS (multiply by 
    // INTERNAL_TOKEN_PRECISION to get the actual rate)
    uint32 incentiveAnnualEmissionRate;
    // The last block time at utc0 that the nToken was initialized at, zero if it
    // has never been initialized
    uint32 lastInitializedTime;
    // Length of the asset array, refers to the number of liquidity tokens an nToken
    // currently holds
    uint8 assetArrayLength;
    // Each byte is a specific nToken parameter
    bytes5 nTokenParameters;
    // Reserved bytes for future usage
    bytes15 _unused;
    // Set to true if a secondary rewarder is set
    bool hasSecondaryRewarder;
}

/// @dev Holds account balance information, total storage 32 bytes
struct BalanceStorage {
    // Number of nTokens held by the account
    uint80 nTokenBalance;
    // Last time the account claimed their nTokens
    uint32 lastClaimTime;
    // Incentives that the account no longer has a claim over
    uint56 accountIncentiveDebt;
    // Cash balance of the account
    int88 cashBalance;
}

/// @dev Holds information about a settlement rate, total storage 25 bytes
struct SettlementRateStorage {
    uint40 blockTime;
    uint128 settlementRate;
    uint8 underlyingDecimalPlaces;
}

/// @dev Holds information about a market, total storage is 42 bytes so this spans
/// two storage words
struct MarketStorage {
    // Total fCash in the market
    uint80 totalfCash;
    // Total asset cash in the market
    uint80 totalAssetCash;
    // Last annualized interest rate the market traded at
    uint32 lastImpliedRate;
    // Last recorded oracle rate for the market
    uint32 oracleRate;
    // Last time a trade was made
    uint32 previousTradeTime;
    // This is stored in slot + 1
    uint80 totalLiquidity;
}

struct ifCashStorage {
    // Notional amount of fCash at the slot, limited to int128 to allow for
    // future expansion
    int128 notional;
}

/// @dev A single portfolio asset in storage, total storage of 19 bytes
struct PortfolioAssetStorage {
    // Currency Id for the asset
    uint16 currencyId;
    // Maturity of the asset
    uint40 maturity;
    // Asset type (fCash or Liquidity Token marker)
    uint8 assetType;
    // Notional
    int88 notional;
}

/// @dev nToken total supply factors for the nToken, includes factors related
/// to claiming incentives, total storage 32 bytes. This is the deprecated version
struct nTokenTotalSupplyStorage_deprecated {
    // Total supply of the nToken
    uint96 totalSupply;
    // Integral of the total supply used for calculating the average total supply
    uint128 integralTotalSupply;
    // Last timestamp the supply value changed, used for calculating the integralTotalSupply
    uint32 lastSupplyChangeTime;
}

/// @dev nToken total supply factors for the nToken, includes factors related
/// to claiming incentives, total storage 32 bytes.
struct nTokenTotalSupplyStorage {
    // Total supply of the nToken
    uint96 totalSupply;
    // How many NOTE incentives should be issued per nToken in 1e18 precision
    uint128 accumulatedNOTEPerNToken;
    // Last timestamp when the accumulation happened
    uint32 lastAccumulatedTime;
}

/// @dev Used in view methods to return account balances in a developer friendly manner
struct AccountBalance {
    uint16 currencyId;
    int256 cashBalance;
    int256 nTokenBalance;
    uint256 lastClaimTime;
    uint256 accountIncentiveDebt;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

import "AggregatorInterface.sol";
import "AggregatorV3Interface.sol";

interface AggregatorV2V3Interface is AggregatorInterface, AggregatorV3Interface
{
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

interface AggregatorInterface {
  function latestAnswer() external view returns (int256);
  function latestTimestamp() external view returns (uint256);
  function latestRound() external view returns (uint256);
  function getAnswer(uint256 roundId) external view returns (int256);
  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);
  event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
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

// SPDX-License-Identifier: GPL-v3
pragma solidity >=0.7.0;

/// @notice Used as a wrapper for tokens that are interest bearing for an
/// underlying token. Follows the cToken interface, however, can be adapted
/// for other interest bearing tokens.
interface AssetRateAdapter {
    function token() external view returns (address);

    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    function underlying() external view returns (address);

    function getExchangeRateStateful() external returns (int256);

    function getExchangeRateView() external view returns (int256);

    function getAnnualizedSupplyRate() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.0;
pragma abicoder v2;

interface nTokenERC20 {
    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    function nTokenTotalSupply(address nTokenAddress) external view returns (uint256);

    function nTokenTransferAllowance(
        uint16 currencyId,
        address owner,
        address spender
    ) external view returns (uint256);

    function nTokenBalanceOf(uint16 currencyId, address account) external view returns (uint256);

    function nTokenTransferApprove(
        uint16 currencyId,
        address owner,
        address spender,
        uint256 amount
    ) external returns (bool);

    function nTokenTransfer(
        uint16 currencyId,
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function nTokenTransferFrom(
        uint16 currencyId,
        address spender,
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function nTokenTransferApproveAll(address spender, uint256 amount) external returns (bool);

    function nTokenClaimIncentives() external returns (uint256);

    function nTokenPresentValueAssetDenominated(uint16 currencyId) external view returns (int256);

    function nTokenPresentValueUnderlyingDenominated(uint16 currencyId)
        external
        view
        returns (int256);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.0;
pragma abicoder v2;

import "Types.sol";

interface nERC1155Interface {
    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 value
    );
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);
    event URI(string value, uint256 indexed id);

    function supportsInterface(bytes4 interfaceId) external pure returns (bool);

    function balanceOf(address account, uint256 id) external view returns (uint256);

    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    function signedBalanceOf(address account, uint256 id) external view returns (int256);

    function signedBalanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (int256[] memory);

    function setApprovalForAll(address operator, bool approved) external;

    function isApprovedForAll(address account, address operator) external view returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external payable;

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external payable;

    function decodeToAssets(uint256[] calldata ids, uint256[] calldata amounts)
        external
        view
        returns (PortfolioAsset[] memory);

    function encodeToId(
        uint16 currencyId,
        uint40 maturity,
        uint8 assetType
    ) external pure returns (uint256 id);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.0;
pragma abicoder v2;

import "Types.sol";
import "AggregatorV2V3Interface.sol";
import "NotionalGovernance.sol";
import "IRewarder.sol";
import "ILendingPool.sol";

interface NotionalGovernance {
    event ListCurrency(uint16 newCurrencyId);
    event UpdateETHRate(uint16 currencyId);
    event UpdateAssetRate(uint16 currencyId);
    event UpdateCashGroup(uint16 currencyId);
    event DeployNToken(uint16 currencyId, address nTokenAddress);
    event UpdateDepositParameters(uint16 currencyId);
    event UpdateInitializationParameters(uint16 currencyId);
    event UpdateIncentiveEmissionRate(uint16 currencyId, uint32 newEmissionRate);
    event UpdateTokenCollateralParameters(uint16 currencyId);
    event UpdateGlobalTransferOperator(address operator, bool approved);
    event UpdateAuthorizedCallbackContract(address operator, bool approved);
    event UpdateMaxCollateralBalance(uint16 currencyId, uint72 maxCollateralBalance);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event PauseRouterAndGuardianUpdated(address indexed pauseRouter, address indexed pauseGuardian);
    event UpdateSecondaryIncentiveRewarder(uint16 indexed currencyId, address rewarder);
    event UpdateLendingPool(address pool);

    function transferOwnership(address newOwner, bool direct) external;

    function claimOwnership() external;

    function setPauseRouterAndGuardian(address pauseRouter_, address pauseGuardian_) external;

    function listCurrency(
        TokenStorage calldata assetToken,
        TokenStorage calldata underlyingToken,
        AggregatorV2V3Interface rateOracle,
        bool mustInvert,
        uint8 buffer,
        uint8 haircut,
        uint8 liquidationDiscount
    ) external returns (uint16 currencyId);

    function updateMaxCollateralBalance(
        uint16 currencyId,
        uint72 maxCollateralBalanceInternalPrecision
    ) external;

    function enableCashGroup(
        uint16 currencyId,
        AssetRateAdapter assetRateOracle,
        CashGroupSettings calldata cashGroup,
        string calldata underlyingName,
        string calldata underlyingSymbol
    ) external;

    function updateDepositParameters(
        uint16 currencyId,
        uint32[] calldata depositShares,
        uint32[] calldata leverageThresholds
    ) external;

    function updateInitializationParameters(
        uint16 currencyId,
        uint32[] calldata annualizedAnchorRates,
        uint32[] calldata proportions
    ) external;

    function updateIncentiveEmissionRate(uint16 currencyId, uint32 newEmissionRate) external;

    function updateTokenCollateralParameters(
        uint16 currencyId,
        uint8 residualPurchaseIncentive10BPS,
        uint8 pvHaircutPercentage,
        uint8 residualPurchaseTimeBufferHours,
        uint8 cashWithholdingBuffer10BPS,
        uint8 liquidationHaircutPercentage
    ) external;

    function updateCashGroup(uint16 currencyId, CashGroupSettings calldata cashGroup) external;

    function updateAssetRate(uint16 currencyId, AssetRateAdapter rateOracle) external;

    function updateETHRate(
        uint16 currencyId,
        AggregatorV2V3Interface rateOracle,
        bool mustInvert,
        uint8 buffer,
        uint8 haircut,
        uint8 liquidationDiscount
    ) external;

    function updateGlobalTransferOperator(address operator, bool approved) external;

    function updateAuthorizedCallbackContract(address operator, bool approved) external;

    function setLendingPool(ILendingPool pool) external;

    function setSecondaryIncentiveRewarder(uint16 currencyId, IRewarder rewarder) external;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.0;

interface IRewarder {
    function claimRewards(
        address account,
        uint16 currencyId,
        uint256 nTokenBalanceBefore,
        uint256 nTokenBalanceAfter,
        int256  netNTokenSupplyChange,
        uint256 NOTETokensClaimed
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.0;
pragma abicoder v2;

struct LendingPoolStorage {
  ILendingPool lendingPool;
}

interface ILendingPool {

  /**
   * @dev Deposits an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
   * - E.g. User deposits 100 USDC and gets in return 100 aUSDC
   * @param asset The address of the underlying asset to deposit
   * @param amount The amount to be deposited
   * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
   *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
   *   is a different wallet
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   **/
  function deposit(
    address asset,
    uint256 amount,
    address onBehalfOf,
    uint16 referralCode
  ) external;

  /**
   * @dev Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
   * E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
   * @param asset The address of the underlying asset to withdraw
   * @param amount The underlying amount to be withdrawn
   *   - Send the value type(uint256).max in order to withdraw the whole aToken balance
   * @param to Address that will receive the underlying, same as msg.sender if the user
   *   wants to receive it on his own wallet, or a different address if the beneficiary is a
   *   different wallet
   * @return The final amount withdrawn
   **/
  function withdraw(
    address asset,
    uint256 amount,
    address to
  ) external returns (uint256);

  /**
   * @dev Returns the normalized income normalized income of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The reserve's normalized income
   */
  function getReserveNormalizedIncome(address asset) external view returns (uint256);

    /**
   * @dev Returns the state and configuration of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The state of the reserve
   **/
  function getReserveData(address asset) external view returns (ReserveData memory);

  // refer to the whitepaper, section 1.1 basic concepts for a formal description of these properties.
  struct ReserveData {
    //stores the reserve configuration
    ReserveConfigurationMap configuration;
    //the liquidity index. Expressed in ray
    uint128 liquidityIndex;
    //variable borrow index. Expressed in ray
    uint128 variableBorrowIndex;
    //the current supply rate. Expressed in ray
    uint128 currentLiquidityRate;
    //the current variable borrow rate. Expressed in ray
    uint128 currentVariableBorrowRate;
    //the current stable borrow rate. Expressed in ray
    uint128 currentStableBorrowRate;
    uint40 lastUpdateTimestamp;
    //tokens addresses
    address aTokenAddress;
    address stableDebtTokenAddress;
    address variableDebtTokenAddress;
    //address of the interest rate strategy
    address interestRateStrategyAddress;
    //the id of the reserve. Represents the position in the list of the active reserves
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

  enum InterestRateMode {NONE, STABLE, VARIABLE}
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.0;
pragma abicoder v2;

import "Types.sol";

interface NotionalCalculations {
    function calculateNTokensToMint(uint16 currencyId, uint88 amountToDepositExternalPrecision)
        external
        view
        returns (uint256);

    function getfCashAmountGivenCashAmount(
        uint16 currencyId,
        int88 netCashToAccount,
        uint256 marketIndex,
        uint256 blockTime
    ) external view returns (int256);

    function getCashAmountGivenfCashAmount(
        uint16 currencyId,
        int88 fCashAmount,
        uint256 marketIndex,
        uint256 blockTime
    ) external view returns (int256, int256);

    function nTokenGetClaimableIncentives(address account, uint256 blockTime)
        external
        view
        returns (uint256);

    function getPresentfCashValue(
        uint16 currencyId,
        uint256 maturity,
        int256 notional,
        uint256 blockTime,
        bool riskAdjusted
    ) external view returns (int256 presentValue);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.0;
pragma abicoder v2;

import "Types.sol";

interface NotionalViews {
    function getMaxCurrencyId() external view returns (uint16);

    function getCurrencyId(address tokenAddress) external view returns (uint16 currencyId);

    function getCurrency(uint16 currencyId)
        external
        view
        returns (Token memory assetToken, Token memory underlyingToken);

    function getRateStorage(uint16 currencyId)
        external
        view
        returns (ETHRateStorage memory ethRate, AssetRateStorage memory assetRate);

    function getCurrencyAndRates(uint16 currencyId)
        external
        view
        returns (
            Token memory assetToken,
            Token memory underlyingToken,
            ETHRate memory ethRate,
            AssetRateParameters memory assetRate
        );

    function getCashGroup(uint16 currencyId) external view returns (CashGroupSettings memory);

    function getCashGroupAndAssetRate(uint16 currencyId)
        external
        view
        returns (CashGroupSettings memory cashGroup, AssetRateParameters memory assetRate);

    function getInitializationParameters(uint16 currencyId)
        external
        view
        returns (int256[] memory annualizedAnchorRates, int256[] memory proportions);

    function getDepositParameters(uint16 currencyId)
        external
        view
        returns (int256[] memory depositShares, int256[] memory leverageThresholds);

    function nTokenAddress(uint16 currencyId) external view returns (address);

    function getNoteToken() external view returns (address);

    function getOwnershipStatus() external view returns (address owner, address pendingOwner);

    function getGlobalTransferOperatorStatus(address operator)
        external
        view
        returns (bool isAuthorized);

    function getAuthorizedCallbackContractStatus(address callback)
        external
        view
        returns (bool isAuthorized);

    function getSecondaryIncentiveRewarder(uint16 currencyId)
        external
        view
        returns (address incentiveRewarder);

    function getSettlementRate(uint16 currencyId, uint40 maturity)
        external
        view
        returns (AssetRateParameters memory);

    function getMarket(
        uint16 currencyId,
        uint256 maturity,
        uint256 settlementDate
    ) external view returns (MarketParameters memory);

    function getActiveMarkets(uint16 currencyId) external view returns (MarketParameters[] memory);

    function getActiveMarketsAtBlockTime(uint16 currencyId, uint32 blockTime)
        external
        view
        returns (MarketParameters[] memory);

    function getReserveBalance(uint16 currencyId) external view returns (int256 reserveBalance);

    function getNTokenPortfolio(address tokenAddress)
        external
        view
        returns (PortfolioAsset[] memory liquidityTokens, PortfolioAsset[] memory netfCashAssets);

    function getNTokenAccount(address tokenAddress)
        external
        view
        returns (
            uint16 currencyId,
            uint256 totalSupply,
            uint256 incentiveAnnualEmissionRate,
            uint256 lastInitializedTime,
            bytes5 nTokenParameters,
            int256 cashBalance,
            uint256 accumulatedNOTEPerNToken,
            uint256 lastAccumulatedTime
        );

    function getAccount(address account)
        external
        view
        returns (
            AccountContext memory accountContext,
            AccountBalance[] memory accountBalances,
            PortfolioAsset[] memory portfolio
        );

    function getAccountContext(address account) external view returns (AccountContext memory);

    function getAccountBalance(uint16 currencyId, address account)
        external
        view
        returns (
            int256 cashBalance,
            int256 nTokenBalance,
            uint256 lastClaimTime
        );

    function getAccountPortfolio(address account) external view returns (PortfolioAsset[] memory);

    function getfCashNotional(
        address account,
        uint16 currencyId,
        uint256 maturity
    ) external view returns (int256);

    function getAssetsBitmap(address account, uint16 currencyId) external view returns (bytes32);

    function getFreeCollateral(address account) external view returns (int256, int256[] memory);

    function getTreasuryManager() external view returns (address);

    function getReserveBuffer(uint16 currencyId) external view returns (uint256);

    function getLendingPool() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.0;
pragma abicoder v2;

interface NotionalTreasury {

    /// @notice Emitted when reserve balance is updated
    event ReserveBalanceUpdated(uint16 indexed currencyId, int256 newBalance);
    /// @notice Emitted when reserve balance is harvested
    event ExcessReserveBalanceHarvested(uint16 indexed currencyId, int256 harvestAmount);
    /// @dev Emitted when treasury manager is updated
    event TreasuryManagerChanged(address indexed previousManager, address indexed newManager);
    /// @dev Emitted when reserve buffer value is updated
    event ReserveBufferUpdated(uint16 currencyId, uint256 bufferAmount);

    function claimCOMPAndTransfer(address[] calldata ctokens) external returns (uint256);

    function transferReserveToTreasury(uint16[] calldata currencies)
        external
        returns (uint256[] memory);

    function setTreasuryManager(address manager) external;

    function setReserveBuffer(uint16 currencyId, uint256 amount) external;

    function setReserveCashBalance(uint16 currencyId, int256 reserveBalance) external;
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.7.0;

import "CTokenInterface.sol";

interface CErc20Interface {

    /*** User Interface ***/

    function mint(uint mintAmount) external returns (uint);
    function redeem(uint redeemTokens) external returns (uint);
    function redeemUnderlying(uint redeemAmount) external returns (uint);
    function borrow(uint borrowAmount) external returns (uint);
    function repayBorrow(uint repayAmount) external returns (uint);
    function repayBorrowBehalf(address borrower, uint repayAmount) external returns (uint);
    function liquidateBorrow(address borrower, uint repayAmount, CTokenInterface cTokenCollateral) external returns (uint);
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.7.0;

interface CTokenInterface {

    /*** User Interface ***/

    function underlying() external view returns (address);
    function transfer(address dst, uint amount) external returns (bool);
    function transferFrom(address src, address dst, uint amount) external returns (bool);
    function approve(address spender, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function balanceOfUnderlying(address owner) external returns (uint);
    function getAccountSnapshot(address account) external view returns (uint, uint, uint, uint);
    function borrowRatePerBlock() external view returns (uint);
    function supplyRatePerBlock() external view returns (uint);
    function totalBorrowsCurrent() external returns (uint);
    function borrowBalanceCurrent(address account) external returns (uint);
    function borrowBalanceStored(address account) external view returns (uint);
    function exchangeRateCurrent() external returns (uint);
    function exchangeRateStored() external view returns (uint);
    function getCash() external view returns (uint);
    function accrueInterest() external returns (uint);
    function seize(address liquidator, address borrower, uint seizeTokens) external returns (uint);
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.7.0;

interface CEtherInterface {
    function mint() external payable;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.0;

interface WETH9 {
    function deposit() external payable;

    function withdraw(uint256 wad) external;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.0;

interface IStakedETH {
    function balanceOf(address owner) external view returns (uint256);
    function unwrap(uint256 _wstETHAmount) external returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >0.7.0;

contract NotionalV2LiquidatorStorageLayoutV1 {
    mapping(address => address) internal underlyingToCToken;
    address public owner;
    uint16 public ifCashCurrencyId;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.0;
pragma abicoder v2;

import "Constants.sol";
import "SafeMath.sol";

library DateTime {
    using SafeMath for uint256;

    /// @notice Returns the current reference time which is how all the AMM dates are calculated.
    function getReferenceTime(uint256 blockTime) internal pure returns (uint256) {
        require(blockTime >= Constants.QUARTER);
        return blockTime - (blockTime % Constants.QUARTER);
    }

    /// @notice Truncates a date to midnight UTC time
    function getTimeUTC0(uint256 time) internal pure returns (uint256) {
        require(time >= Constants.DAY);
        return time - (time % Constants.DAY);
    }

    /// @notice These are the predetermined market offsets for trading
    /// @dev Markets are 1-indexed because the 0 index means that no markets are listed for the cash group.
    function getTradedMarket(uint256 index) internal pure returns (uint256) {
        if (index == 1) return Constants.QUARTER;
        if (index == 2) return 2 * Constants.QUARTER;
        if (index == 3) return Constants.YEAR;
        if (index == 4) return 2 * Constants.YEAR;
        if (index == 5) return 5 * Constants.YEAR;
        if (index == 6) return 10 * Constants.YEAR;
        if (index == 7) return 20 * Constants.YEAR;

        revert("Invalid index");
    }

    /// @notice Determines if the maturity falls on one of the valid on chain market dates.
    function isValidMarketMaturity(
        uint256 maxMarketIndex,
        uint256 maturity,
        uint256 blockTime
    ) internal pure returns (bool) {
        require(maxMarketIndex > 0, "CG: no markets listed");
        require(maxMarketIndex <= Constants.MAX_TRADED_MARKET_INDEX, "CG: market index bound");

        if (maturity % Constants.QUARTER != 0) return false;
        uint256 tRef = DateTime.getReferenceTime(blockTime);

        for (uint256 i = 1; i <= maxMarketIndex; i++) {
            if (maturity == tRef.add(DateTime.getTradedMarket(i))) return true;
        }

        return false;
    }

    /// @notice Determines if an idiosyncratic maturity is valid and returns the bit reference that is the case.
    function isValidMaturity(
        uint256 maxMarketIndex,
        uint256 maturity,
        uint256 blockTime
    ) internal pure returns (bool) {
        uint256 tRef = DateTime.getReferenceTime(blockTime);
        uint256 maxMaturity = tRef.add(DateTime.getTradedMarket(maxMarketIndex));
        // Cannot trade past max maturity
        if (maturity > maxMaturity) return false;

        // prettier-ignore
        (/* */, bool isValid) = DateTime.getBitNumFromMaturity(blockTime, maturity);
        return isValid;
    }

    /// @notice Returns the market index for a given maturity, if the maturity is idiosyncratic
    /// will return the nearest market index that is larger than the maturity.
    /// @return uint marketIndex, bool isIdiosyncratic
    function getMarketIndex(
        uint256 maxMarketIndex,
        uint256 maturity,
        uint256 blockTime
    ) internal pure returns (uint256, bool) {
        require(maxMarketIndex > 0, "CG: no markets listed");
        require(maxMarketIndex <= Constants.MAX_TRADED_MARKET_INDEX, "CG: market index bound");
        uint256 tRef = DateTime.getReferenceTime(blockTime);

        for (uint256 i = 1; i <= maxMarketIndex; i++) {
            uint256 marketMaturity = tRef.add(DateTime.getTradedMarket(i));
            // If market matches then is not idiosyncratic
            if (marketMaturity == maturity) return (i, false);
            // Returns the market that is immediately greater than the maturity
            if (marketMaturity > maturity) return (i, true);
        }

        revert("CG: no market found");
    }

    /// @notice Given a bit number and the reference time of the first bit, returns the bit number
    /// of a given maturity.
    /// @return bitNum and a true or false if the maturity falls on the exact bit
    function getBitNumFromMaturity(uint256 blockTime, uint256 maturity)
        internal
        pure
        returns (uint256, bool)
    {
        uint256 blockTimeUTC0 = getTimeUTC0(blockTime);

        // Maturities must always divide days evenly
        if (maturity % Constants.DAY != 0) return (0, false);
        // Maturity cannot be in the past
        if (blockTimeUTC0 >= maturity) return (0, false);

        // Overflow check done above
        // daysOffset has no remainders, checked above
        uint256 daysOffset = (maturity - blockTimeUTC0) / Constants.DAY;

        // These if statements need to fall through to the next one
        if (daysOffset <= Constants.MAX_DAY_OFFSET) {
            return (daysOffset, true);
        } else if (daysOffset <= Constants.MAX_WEEK_OFFSET) {
            // (daysOffset - MAX_DAY_OFFSET) is the days overflow into the week portion, must be > 0
            // (blockTimeUTC0 % WEEK) / DAY is the offset into the week portion
            // This returns the offset from the previous max offset in days
            uint256 offsetInDays =
                daysOffset -
                    Constants.MAX_DAY_OFFSET +
                    (blockTimeUTC0 % Constants.WEEK) /
                    Constants.DAY;
            
            return (
                // This converts the offset in days to its corresponding bit position, truncating down
                // if it does not divide evenly into DAYS_IN_WEEK
                Constants.WEEK_BIT_OFFSET + offsetInDays / Constants.DAYS_IN_WEEK,
                (offsetInDays % Constants.DAYS_IN_WEEK) == 0
            );
        } else if (daysOffset <= Constants.MAX_MONTH_OFFSET) {
            uint256 offsetInDays =
                daysOffset -
                    Constants.MAX_WEEK_OFFSET +
                    (blockTimeUTC0 % Constants.MONTH) /
                    Constants.DAY;

            return (
                Constants.MONTH_BIT_OFFSET + offsetInDays / Constants.DAYS_IN_MONTH,
                (offsetInDays % Constants.DAYS_IN_MONTH) == 0
            );
        } else if (daysOffset <= Constants.MAX_QUARTER_OFFSET) {
            uint256 offsetInDays =
                daysOffset -
                    Constants.MAX_MONTH_OFFSET +
                    (blockTimeUTC0 % Constants.QUARTER) /
                    Constants.DAY;

            return (
                Constants.QUARTER_BIT_OFFSET + offsetInDays / Constants.DAYS_IN_QUARTER,
                (offsetInDays % Constants.DAYS_IN_QUARTER) == 0
            );
        }

        // This is the maximum 1-indexed bit num, it is never valid because it is beyond the 20
        // year max maturity
        return (256, false);
    }

    /// @notice Given a bit number and a block time returns the maturity that the bit number
    /// should reference. Bit numbers are one indexed.
    function getMaturityFromBitNum(uint256 blockTime, uint256 bitNum)
        internal
        pure
        returns (uint256)
    {
        require(bitNum != 0); // dev: cash group get maturity from bit num is zero
        require(bitNum <= 256); // dev: cash group get maturity from bit num overflow
        uint256 blockTimeUTC0 = getTimeUTC0(blockTime);
        uint256 firstBit;

        if (bitNum <= Constants.WEEK_BIT_OFFSET) {
            return blockTimeUTC0 + bitNum * Constants.DAY;
        } else if (bitNum <= Constants.MONTH_BIT_OFFSET) {
            firstBit =
                blockTimeUTC0 +
                Constants.MAX_DAY_OFFSET * Constants.DAY -
                // This backs up to the day that is divisible by a week
                (blockTimeUTC0 % Constants.WEEK);
            return firstBit + (bitNum - Constants.WEEK_BIT_OFFSET) * Constants.WEEK;
        } else if (bitNum <= Constants.QUARTER_BIT_OFFSET) {
            firstBit =
                blockTimeUTC0 +
                Constants.MAX_WEEK_OFFSET * Constants.DAY -
                (blockTimeUTC0 % Constants.MONTH);
            return firstBit + (bitNum - Constants.MONTH_BIT_OFFSET) * Constants.MONTH;
        } else {
            firstBit =
                blockTimeUTC0 +
                Constants.MAX_MONTH_OFFSET * Constants.DAY -
                (blockTimeUTC0 % Constants.QUARTER);
            return firstBit + (bitNum - Constants.QUARTER_BIT_OFFSET) * Constants.QUARTER;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.0;

/// @title All shared constants for the Notional system should be declared here.
library Constants {
    uint8 internal constant CETH_DECIMAL_PLACES = 8;

    // Token precision used for all internal balances, TokenHandler library ensures that we
    // limit the dust amount caused by precision mismatches
    int256 internal constant INTERNAL_TOKEN_PRECISION = 1e8;
    uint256 internal constant INCENTIVE_ACCUMULATION_PRECISION = 1e18;

    // ETH will be initialized as the first currency
    uint256 internal constant ETH_CURRENCY_ID = 1;
    uint8 internal constant ETH_DECIMAL_PLACES = 18;
    int256 internal constant ETH_DECIMALS = 1e18;
    // Used to prevent overflow when converting decimal places to decimal precision values via
    // 10**decimalPlaces. This is a safe value for int256 and uint256 variables. We apply this
    // constraint when storing decimal places in governance.
    uint256 internal constant MAX_DECIMAL_PLACES = 36;

    // Address of the reserve account
    address internal constant RESERVE = address(0);

    // Most significant bit
    bytes32 internal constant MSB =
        0x8000000000000000000000000000000000000000000000000000000000000000;

    // Each bit set in this mask marks where an active market should be in the bitmap
    // if the first bit refers to the reference time. Used to detect idiosyncratic
    // fcash in the nToken accounts
    bytes32 internal constant ACTIVE_MARKETS_MASK = (
        MSB >> ( 90 - 1) | // 3 month
        MSB >> (105 - 1) | // 6 month
        MSB >> (135 - 1) | // 1 year
        MSB >> (147 - 1) | // 2 year
        MSB >> (183 - 1) | // 5 year
        MSB >> (211 - 1) | // 10 year
        MSB >> (251 - 1)   // 20 year
    );

    // Basis for percentages
    int256 internal constant PERCENTAGE_DECIMALS = 100;
    // Max number of traded markets, also used as the maximum number of assets in a portfolio array
    uint256 internal constant MAX_TRADED_MARKET_INDEX = 7;
    // Max number of fCash assets in a bitmap, this is based on the gas costs of calculating free collateral
    // for a bitmap portfolio
    uint256 internal constant MAX_BITMAP_ASSETS = 20;
    uint256 internal constant FIVE_MINUTES = 300;

    // Internal date representations, note we use a 6/30/360 week/month/year convention here
    uint256 internal constant DAY = 86400;
    // We use six day weeks to ensure that all time references divide evenly
    uint256 internal constant WEEK = DAY * 6;
    uint256 internal constant MONTH = WEEK * 5;
    uint256 internal constant QUARTER = MONTH * 3;
    uint256 internal constant YEAR = QUARTER * 4;
    
    // These constants are used in DateTime.sol
    uint256 internal constant DAYS_IN_WEEK = 6;
    uint256 internal constant DAYS_IN_MONTH = 30;
    uint256 internal constant DAYS_IN_QUARTER = 90;

    // Offsets for each time chunk denominated in days
    uint256 internal constant MAX_DAY_OFFSET = 90;
    uint256 internal constant MAX_WEEK_OFFSET = 360;
    uint256 internal constant MAX_MONTH_OFFSET = 2160;
    uint256 internal constant MAX_QUARTER_OFFSET = 7650;

    // Offsets for each time chunk denominated in bits
    uint256 internal constant WEEK_BIT_OFFSET = 90;
    uint256 internal constant MONTH_BIT_OFFSET = 135;
    uint256 internal constant QUARTER_BIT_OFFSET = 195;

    // This is a constant that represents the time period that all rates are normalized by, 360 days
    uint256 internal constant IMPLIED_RATE_TIME = 360 * DAY;
    // Number of decimal places that rates are stored in, equals 100%
    int256 internal constant RATE_PRECISION = 1e9;
    // One basis point in RATE_PRECISION terms
    uint256 internal constant BASIS_POINT = uint256(RATE_PRECISION / 10000);
    // Used to when calculating the amount to deleverage of a market when minting nTokens
    uint256 internal constant DELEVERAGE_BUFFER = 300 * BASIS_POINT;
    // Used for scaling cash group factors
    uint256 internal constant FIVE_BASIS_POINTS = 5 * BASIS_POINT;
    // Used for residual purchase incentive and cash withholding buffer
    uint256 internal constant TEN_BASIS_POINTS = 10 * BASIS_POINT;

    // This is the ABDK64x64 representation of RATE_PRECISION
    // RATE_PRECISION_64x64 = ABDKMath64x64.fromUint(RATE_PRECISION)
    int128 internal constant RATE_PRECISION_64x64 = 0x3b9aca000000000000000000;
    int128 internal constant LOG_RATE_PRECISION_64x64 = 382276781265598821176;
    // Limit the market proportion so that borrowing cannot hit extremely high interest rates
    int256 internal constant MAX_MARKET_PROPORTION = RATE_PRECISION * 99 / 100;

    uint8 internal constant FCASH_ASSET_TYPE = 1;
    // Liquidity token asset types are 1 + marketIndex (where marketIndex is 1-indexed)
    uint8 internal constant MIN_LIQUIDITY_TOKEN_INDEX = 2;
    uint8 internal constant MAX_LIQUIDITY_TOKEN_INDEX = 8;

    // Used for converting bool to bytes1, solidity does not have a native conversion
    // method for this
    bytes1 internal constant BOOL_FALSE = 0x00;
    bytes1 internal constant BOOL_TRUE = 0x01;

    // Account context flags
    bytes1 internal constant HAS_ASSET_DEBT = 0x01;
    bytes1 internal constant HAS_CASH_DEBT = 0x02;
    bytes2 internal constant ACTIVE_IN_PORTFOLIO = 0x8000;
    bytes2 internal constant ACTIVE_IN_BALANCES = 0x4000;
    bytes2 internal constant UNMASK_FLAGS = 0x3FFF;
    uint16 internal constant MAX_CURRENCIES = uint16(UNMASK_FLAGS);

    // Equal to 100% of all deposit amounts for nToken liquidity across fCash markets.
    int256 internal constant DEPOSIT_PERCENT_BASIS = 1e8;

    // nToken Parameters: there are offsets in the nTokenParameters bytes6 variable returned
    // in nTokenHandler. Each constant represents a position in the byte array.
    uint8 internal constant LIQUIDATION_HAIRCUT_PERCENTAGE = 0;
    uint8 internal constant CASH_WITHHOLDING_BUFFER = 1;
    uint8 internal constant RESIDUAL_PURCHASE_TIME_BUFFER = 2;
    uint8 internal constant PV_HAIRCUT_PERCENTAGE = 3;
    uint8 internal constant RESIDUAL_PURCHASE_INCENTIVE = 4;

    // Liquidation parameters
    // Default percentage of collateral that a liquidator is allowed to liquidate, will be higher if the account
    // requires more collateral to be liquidated
    int256 internal constant DEFAULT_LIQUIDATION_PORTION = 40;
    // Percentage of local liquidity token cash claim delivered to the liquidator for liquidating liquidity tokens
    int256 internal constant TOKEN_REPO_INCENTIVE_PERCENT = 30;

    // Pause Router liquidation enabled states
    bytes1 internal constant LOCAL_CURRENCY_ENABLED = 0x01;
    bytes1 internal constant COLLATERAL_CURRENCY_ENABLED = 0x02;
    bytes1 internal constant LOCAL_FCASH_ENABLED = 0x04;
    bytes1 internal constant CROSS_CURRENCY_FCASH_ENABLED = 0x08;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.0;

import "Constants.sol";

library SafeInt256 {
    int256 private constant _INT256_MIN = type(int256).min;

    /// @dev Returns the multiplication of two signed integers, reverting on
    /// overflow.

    /// Counterpart to Solidity's `*` operator.

    /// Requirements:

    /// - Multiplication cannot overflow.

    function mul(int256 a, int256 b) internal pure returns (int256 c) {
        c = a * b;
        if (a == -1) require (b == 0 || c / b == a);
        else require (a == 0 || c / a == b);
    }

    /// @dev Returns the integer division of two signed integers. Reverts on
    /// division by zero. The result is rounded towards zero.

    /// Counterpart to Solidity's `/` operator. Note: this function uses a
    /// `revert` opcode (which leaves remaining gas untouched) while Solidity
    /// uses an invalid opcode to revert (consuming all remaining gas).

    /// Requirements:

    /// - The divisor cannot be zero.

    function div(int256 a, int256 b) internal pure returns (int256 c) {
        require(!(b == -1 && a == _INT256_MIN)); // dev: int256 div overflow
        // NOTE: solidity will automatically revert on divide by zero
        c = a / b;
    }

    function sub(int256 x, int256 y) internal pure returns (int256 z) {
        //  taken from uniswap v3
        require((z = x - y) <= x == (y >= 0));
    }

    function add(int256 x, int256 y) internal pure returns (int256 z) {
        require((z = x + y) >= x == (y >= 0));
    }

    function neg(int256 x) internal pure returns (int256 y) {
        return mul(-1, x);
    }

    function abs(int256 x) internal pure returns (int256) {
        if (x < 0) return neg(x);
        else return x;
    }

    function subNoNeg(int256 x, int256 y) internal pure returns (int256 z) {
        z = sub(x, y);
        require(z >= 0); // dev: int256 sub to negative

        return z;
    }

    /// @dev Calculates x * RATE_PRECISION / y while checking overflows
    function divInRatePrecision(int256 x, int256 y) internal pure returns (int256) {
        return div(mul(x, Constants.RATE_PRECISION), y);
    }

    /// @dev Calculates x * y / RATE_PRECISION while checking overflows
    function mulInRatePrecision(int256 x, int256 y) internal pure returns (int256) {
        return div(mul(x, y), Constants.RATE_PRECISION);
    }

    function toUint(int256 x) internal pure returns (uint256) {
        require(x >= 0);
        return uint256(x);
    }

    function toInt(uint256 x) internal pure returns (int256) {
        require (x <= uint256(type(int256).max)); // dev: toInt overflow
        return int256(x);
    }

    function max(int256 x, int256 y) internal pure returns (int256) {
        return x > y ? x : y;
    }

    function min(int256 x, int256 y) internal pure returns (int256) {
        return x < y ? x : y;
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >0.7.0;
pragma experimental ABIEncoderV2;

import "NotionalV2FlashLiquidator.sol";
import "ISwapRouter.sol";
import "IERC20.sol";

abstract contract NotionalV2UniV3SwapRouter {
    ISwapRouter public immutable EXCHANGE;

    constructor(ISwapRouter exchange_) {
        EXCHANGE = exchange_;
    }

    function _executeDexTrade(
        uint256 amountIn,
        uint256 amountOutMin,
        bytes memory params
    ) internal returns (uint256) {
        // prettier-ignore
        (
            bytes memory path,
            uint256 deadline
        ) = abi.decode(params, (bytes, uint256));

        ISwapRouter.ExactInputParams memory swapParams = ISwapRouter.ExactInputParams(
            path,
            address(this),
            deadline,
            amountIn,
            amountOutMin
        );

       return ISwapRouter(EXCHANGE).exactInput(swapParams);
    }
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "IUniswapV3SwapCallback.sol";

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.7.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

interface IFlashLender {
    function flashLoan(
        address receiverAddress,
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata modes,
        address onBehalfOf,
        bytes calldata params,
        uint16 referralCode
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

interface IFlashLoanReceiver {
    function executeOperation(
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata premiums,
        address initiator,
        bytes calldata params
    ) external returns (bool);

    //   function ADDRESSES_PROVIDER() external view returns (address);

    //   function LENDING_POOL() external view returns (address);
}