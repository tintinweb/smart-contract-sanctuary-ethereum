// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.4;

import { Funding } from "Funding.sol";
import { Liquidation } from "Liquidation.sol";
import { Math } from "Math.sol";
import { Storage } from "Storage.sol";
import { Synthetic } from "Synthetic.sol";
import { Token } from "Token.sol";
import { Trade } from "Trade.sol";
import { Transfer } from "Transfer.sol";
import { Types } from "Types.sol";

/**
 *  @author Paradex
 *  @title Paraclear
 *  @notice Primary contract for Paraclear
 *  @dev All integers are using `uint` until we get more information regarding the decimals
 *  we will need for these fields, also taking into account the addional decimals that
 *  we need due to the lack of floating point numbers.
 */
contract Paraclear is Trade, Transfer, Liquidation {
    constructor(Types.ParaclearAccounts memory _paraclearAccounts) {
        Storage.paraclearAccounts = _paraclearAccounts;
    }

    /**
     *  @notice Transfers tokens from a user to Paraclear
     *  @param tokenAddress Address of the token asset contract
     *  @param amount Amount the user wants to deposit
     */
    function deposit(address tokenAddress, uint amount) external {
        Transfer._deposit(msg.sender, tokenAddress, amount);
    }

    /**
     *  @notice Transfer amount from Paraclear to a user
     *  @param tokenAddress Address of the token asset contract
     *  @param amount Amount the user wants to withdraw
     */
    function withdraw(address tokenAddress, uint amount) external {
        Transfer._withdraw(msg.sender, tokenAddress, amount);
    }

    /**
     *  @notice Creates a new synthetic asset representation within Paraclear
     *  @param newAsset Details of the synthetic asset representation
     */
    function createSyntheticAsset(Types.SyntheticAsset memory newAsset) external {
        Synthetic._createAsset(newAsset);
    }

    /**
     *  @notice Gets the synthetic asset representation for a market
     *  @param market ID of the synethetic asset
     */
    function getSyntheticAsset(
        string memory market
    ) external view returns(Types.SyntheticAsset memory) {
        return Synthetic._getAsset(market);
    }

    /**
     *  @notice Gets the synthetic asset balance for a user account
     *  @param account Address of the user account
     *  @param market ID of the synethetic asset
     */
    function getSyntheticAssetBalance(
        address account, string memory market
    ) external view returns(Types.SyntheticAssetBalance memory) {
        return Synthetic._getAssetBalance(account, market);
    }

    /**
     *  @notice Creates a new token asset representation within Paraclear
     *  @param newAsset Details of the token asset representation
     */
    function createTokenAsset(Types.TokenAsset memory newAsset) external {
        Token._createAsset(newAsset);
    }

    /**
     *  @notice Gets token asset representation for a address
     *  @param tokenAddress Address of the token asset contract
     */
    function getTokenAsset(address tokenAddress) external view returns(Types.TokenAsset memory) {
        return Token._getAsset(tokenAddress);
    }

    /**
     *  @notice Gets token asset balance for a user account
     *  @param account Address of the user account
     *  @param tokenAddress Address of the token asset contract
     */
    function getTokenAssetBalance(
        address account, address tokenAddress
    ) external view returns(Math.Number memory) {
        return Token._getAssetBalance(account, tokenAddress);
    }

    /**
     *  @notice Settles the trade and updates synthetic asset balance
     *  @param trade Trade request containing matching maker/taker orders
     */
    function settleTrade(Types.TradeRequest memory trade) external {
        Trade._settle(trade);
    }

    /**
     *  @notice Returns total funding accrued on Paraclear contract
     */
    function getFunding() public view returns(Math.Number memory, Math.Number memory) {
        return Funding._getFunding();
    }

    /**
     *  @notice Triggers liquidation for given account
     *  @param data Liquidation account (user address) and market data
     */
    function liquidate(Types.LiquidationData memory data) public {
        Liquidation._liquidate(data);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.4;

import { Math } from "Math.sol";

/**
 *  @author Paradex
 *  @title Funding
 *  @notice Keeps track of all funding paid and received across Paraclear
 */
contract Funding {
    Math.Number fundingPaid;
    Math.Number fundingReceived;

    /**
     *  @notice Increments funding paid
     *  @param change Amount to increment "funding paid" by
     */
    function _incrementFundingPaid(Math.Number memory change) internal {
        fundingPaid = Math.add(fundingPaid, change);
    }

    /**
     *  @notice Increments funding recieved
     *  @param change Amount to increment "funding recieved" by
     */
    function _incrementFundingReceived(Math.Number memory change) internal {
        fundingReceived = Math.add(fundingReceived, change);
    }

    /**
     *  @notice Returns total funding accrued on Paraclear
     */
    function _getFunding() internal view returns(Math.Number memory, Math.Number memory) {
        return (fundingPaid, fundingReceived);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.4;

/**
 *  @author Paradex
 *  @title Math
 *  @notice Library for unsigned Math
 */
library Math {
    // 10 ^ 8
    uint8 constant DECIMALS = 8;
    uint constant DOT = 10 ** DECIMALS;

    // number = value / DOT (10 ^ DECIMALS)
    struct Number {
        uint value;
        bool sign; // true = positive, false = negative
    }

    /**
     *  @notice Creates a decimal with 8 decimals
     *  @param value Value of the created decimal
     */
    function create(uint value) internal pure returns (Number memory) {
        return Number({ value: value, sign: true });
    }

    /**
     *  @notice Creates a decimal
     *  @param value Value of the created decimal
     *  @param sign Sign - positive or negative
     */
    function create(uint value, bool sign) internal pure returns (Number memory) {
        return Number({ value: value, sign: sign });
    }

    /**
     *  @notice Creates a copy of decimal
     *  @param num Number input
     */
    function create(Number memory num) internal pure returns (Number memory) {
        return create(num.value, num.sign);
    }

    /**
     *  @notice Creates a copy of decimal
     *  @param num Number input
     *  @param sign Sign of the copy
     */
    function create(Number memory num, bool sign) internal pure returns (Number memory) {
        return create(num.value, sign);
    }

    /**
     *  @notice Creates a number with zero value
     */
    function zero() internal pure returns (Number memory) {
        return create(0);
    }

    /**
     *  @notice Adds two numbers
     *  @param lhs Number number
     *  @param rhs Number number
     */
    function add(
        Number memory lhs, Number memory rhs
    ) internal pure returns (Number memory ans) {
        uint l = lhs.value;
        uint r = rhs.value;

        if (lhs.sign == rhs.sign) {
            ans = create(l + r, lhs.sign);
        } else if (l >= r) {
            ans = create(l - r, lhs.sign);
        } else {
            ans = create(r - l, rhs.sign);
        }

        // Reset sign
        if (ans.value == 0) {
            ans.sign = true;
        }

        return ans;
    }

    /**
     *  @notice Adds two numbers
     *  @param lhs Number number
     *  @param rhs Number number
     */
    function sub(
        Number memory lhs, Number memory rhs
    ) internal pure returns (Number memory) {
        rhs = create(rhs.value, !rhs.sign);
        return add(lhs, rhs);
    }

    /**
     *  @notice Divides two numbers
     *  @param lhs Number number
     *  @param rhs Number number
     */
    function div(
        Number memory lhs, Number memory rhs
    ) internal pure returns (Number memory ans) {
        require(rhs.value != 0, "Math: Number division cannot be zero");

        ans = create((lhs.value * DOT) / rhs.value);

        if (lhs.sign == rhs.sign) {
            ans.sign = lhs.sign ? lhs.sign : !lhs.sign;
        } else {
            ans.sign = lhs.sign && rhs.sign;
        }

        return ans;
    }

    /**
     *  @notice Multiplies two decimal numbers
     *  @param lhs Number number
     *  @param rhs Number number
     */
    function mul(Number memory lhs, Number memory rhs) internal pure returns (Number memory) {
        return create((lhs.value * rhs.value) / DOT, lhs.sign && rhs.sign);
    }

    /**
     *  @notice Gets absolute value of a number
     *  @param num Signed number
     */
    function abs(Number memory num) internal pure returns (Number memory) {
        return create(num, true);
    }

    /**
     *  @notice Checks if decimal number is less than another
     *  @param lhs Number number
     *  @param rhs Number number
     */
    function isLessThan(Number memory lhs, Number memory rhs) internal pure returns (bool) {
        if (lhs.sign == rhs.sign) {
            return lhs.sign ? lhs.value < rhs.value : lhs.value > rhs.value;
        } else {
            return !lhs.sign;
        }
    }

    /**
     *  @notice Gets max number between two signed numbers
     *  @param lhs Number number
     *  @param rhs Number number
     */
    function max(Number memory lhs, Number memory rhs) internal pure returns (Number memory) {
        return isLessThan(lhs, rhs) ? rhs : lhs;
    }

    /**
     *  @notice Gets max number between two signed numbers
     *  @param lhs Unsigned integer
     *  @param rhs Unsigned integer
     */
    function max(uint lhs, uint rhs) internal pure returns (uint) {
        return lhs >= rhs ? lhs : rhs;
    }

    /**
     *  @notice Calculates square root uisng babylonian method
     *  https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method
     *  @param num Unsigned integer
     */
    function sqrt(uint num) internal pure returns (uint ans) {
        if (num > 3) {
            ans = num;
            uint tmp = num / 2 + 1;
            while (tmp < ans) {
                ans = tmp;
                tmp = ((num / tmp) + tmp) / 2;
            }
        } else if (num != 0) {
            ans = 1;
        }
    }

    /**
     *  @notice Calculates square root of a given number
     *  @param num Number number
     */
    function sqrt(Number memory num) internal pure returns (Number memory) {
        return create(sqrt(num.value * DOT), num.sign);
    }

    /**
     *  @notice Checks if given number is positive
     *  @param num Signed number
     */
    function isPositive(Number memory num) internal pure returns (bool) {
        return num.sign && num.value > 0;
    }

    /**
     *  @notice Converts decimals of given amount
     *  @param value Value of the integer
     *  @param from Convert from decimals (input decimals)
     *  @param to Convert to decimals (output decimals)
     */
    function convert(uint value, uint8 from, uint8 to) internal pure returns (uint) {
        uint convertedValue;
        if (from == to) {
            convertedValue = value;
        } else if (from > to) {
            convertedValue = value / (10 ** (from - to));
        } else {
            convertedValue = value * (10 ** (to - from));
        }
        return convertedValue;
    }

    /**
     *  @notice Converts to internal decimals representation
     *  @dev Converts from given `decimals` to `DECIMALS`
     *  @param value Value of the integer
     *  @param decimals Cconvert from
     */
    function convertToInternal(uint value, uint8 decimals) internal pure returns (uint) {
        return convert(value, decimals, DECIMALS);
    }

    /**
     *  @notice Converts from internal decimals representation
     *  @dev Converts from `DECIMALS` to given `decimals`
     *  @param value Value of the integer
     *  @param decimals Convert to
     */
    function convertFromInternal(uint value, uint8 decimals) internal pure returns (uint) {
        return convert(value, DECIMALS, decimals);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.4;

import { Events } from "Events.sol";
import { Math } from "Math.sol";
import { Storage } from "Storage.sol";
import { Synthetic } from "Synthetic.sol";
import { Token } from "Token.sol";
import { Transfer } from "Transfer.sol";
import { Types } from "Types.sol";

/**
 *  @author Paradex
 *  @title Trade
 */
contract Liquidation is Events, Synthetic {
    /**
     *  @notice Check if account is healthy
     *  @param data Liquidation account (user address) and market data
     */
    function _isAccountHealthy(Types.LiquidationData memory data) internal returns (bool) {
        // Get unrealized PnL and funding for all assets
        Math.Number memory unrealizedPnl = Synthetic._calculateUnrealizedPnlForLiquidation(data);

        Math.Number memory tokenAssetsValue = Token._getAllAssetBalanceValue(data.account);
        Math.Number memory accountValue = Math.add(tokenAssetsValue, unrealizedPnl);

        Math.Number memory liquidatedShareReq = Synthetic._getTotalMarginRequirement(
            data.account, Types.MarginCheckType.Maintenance
        );

        Math.Number memory freeBalance = Math.sub(accountValue, liquidatedShareReq);
        return Math.isPositive(freeBalance) || freeBalance.value == 0;
    }

    function _transferBalances(address account) internal {
        Token._transferToInsuranceFund(account);
        Synthetic._moveToInsuranceFund(account);
    }

    /**
     *  @notice Triggers liquidation for given account
     *  @param data Liquidation account (user address) and market data
     */
    function _liquidate(Types.LiquidationData memory data) internal {
        require(
            msg.sender == Storage.paraclearAccounts.insuranceFundAccount,
            "Liquidation: Sender must be insurance fund account"
        );

        // Account state must be unhealthy to trigger liquidation
        require(
            !_isAccountHealthy(data),
            "Liquidation: Account is healthy, cannot liquidate"
        );

        // Transfer token assets & synthetic assets to insurance fund account
        _transferBalances(data.account);

        Events._emitAccountLiquidated(data.account, msg.sender);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.4;

import { Types } from "Types.sol";
import { Math } from "Math.sol";

/**
 *  @author Paradex
 *  @title Events
 */
contract Events {
    event Deposit(address indexed account, address indexed tokenAddress, uint amount);
    event FundingAccrued(
        uint indexed tradeId,
        address indexed account,
        string market,
        Math.Number amount,
        Math.Number fundingRate
    );
    event Withdraw(address indexed account, address indexed tokenAddress, uint amount);
    event SyntheticBalanceUpdate(
        uint indexed tradeId,
        address indexed account,
        Types.SyntheticAssetBalance assetBalance
    );
    event AccountLiquidated(address indexed account, address liquidator);

    /**
     *  @notice Emits deposit event with transfer details
     *  @param account Address of the user account
     *  @param tokenAddress Address of the token asset contract
     *  @param amount Amount the user has deposited
     */
    function _emitDeposit(address account, address tokenAddress, uint amount) internal {
        emit Deposit(account, tokenAddress, amount);
    }

    /**
     *  @notice Emits withdraw event with transfer details
     *  @param tradeId ID of the trade that caused the update.
     *  @param account Address of the user account.
     *  @param fundingAccrued Tuple of value and sign, with total funding amount accrued by the position.
     *  @param fundingRate Total funding accrued.
     */
    function _emitFundingAccrued(
        uint tradeId,
        address account,
        string memory market,
        Math.Number memory fundingAccrued,
        Math.Number memory fundingRate
    ) internal {
        emit FundingAccrued(tradeId, account, market, fundingAccrued, fundingRate);
    }

    /**
     *  @notice Emits withdraw event with transfer details
     *  @param account Address of the user account
     *  @param tokenAddress Address of the token asset contract
     *  @param amount Amount the user has withdrawn
     */
    function _emitWithdraw(address account, address tokenAddress, uint amount) internal {
        emit Withdraw(account, tokenAddress, amount);
    }

    /**
     *  @notice Emits synthetic balance update event
     *  @param tradeId ID of the trade that caused the update
     *  @param account Address of the user account
     *  @param assetBalance Updated synthetic asset balance
     */
    function _emitSyntheticBalanceUpdate(
        uint tradeId,
        address account,
        Types.SyntheticAssetBalance memory assetBalance
    ) internal {
        emit SyntheticBalanceUpdate(tradeId, account, assetBalance);
    }

    /**
     *  @notice Emits account liquidated event
     *  @param account Address of the user account
     */
    function _emitAccountLiquidated(address account, address liquidator) internal {
        emit AccountLiquidated(account, liquidator);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.4;

import { Math } from "Math.sol";

/**
 *  @author Paradex
 *  @title Types
 */
contract Types {
    ///// Accounts /////

    struct ParaclearAccounts {
        address feesAccount;
        address insuranceFundAccount;
    }

    ///// Token Asset /////

    struct TokenAsset {
        Math.Number initialWeight;
        Math.Number maintenanceWeight;
        Math.Number conversionWeight;
        Math.Number tickSize;
        address tokenAddress;  // Uniquely identifies all token assets
        address priceOracleAddress;
    }

    // Created on deposit, deleted on full withdrawal, updated on deposit/withdral/trade
    struct TokenAssetBalance {
        address tokenAddress;
        Math.Number amount;
        Math.Number unrealizedPnl;
    }

    ///// Synthetic Asset /////

    struct SyntheticAsset {
        string market;  // Uniquely identifies all synthetic assets
        string baseAsset;
        string quoteAsset;
        address settlementAsset;
        address priceOracleAddress;
        Math.Number tickSize;
        MarginParams marginParams;
    }

    struct SyntheticAssetBalance {
        string market;
        bool sign;  // true = LONG, false = SHORT
        Math.Number amount;  // Size
        Math.Number cost;  // Entry notional
        Math.Number cachedFunding;
    }

    ///// Order /////

    enum OrderSide {
        Invalid,
        Buy,
        Sell
    }

    enum OrderType {
        Invalid,
        Limit,
        Market
    }

    struct Order {
        address account;
        string market;
        Types.OrderSide side;
        Types.OrderType orderType;
        Math.Number size;
        Math.Number price;
        bytes signature;
    }

    struct PartiallyFilledOrder {
        string signature;
        Math.Number remainingSize;
    }

    ///// Trade /////

    struct TradeRequest {
        uint id;
        Math.Number marketPrice;
        Math.Number matchPrice;
        Math.Number matchSize;
        Order makerOrder;
        Order takerOrder;
    }

    ///// Margin /////

    enum MarginCheckType {
        Invalid,
        Initial,
        Maintenance,
        Conversion,
        NoRequirement
    }

    struct MarginParams {
        Math.Number imfBase;    // Initial Margin Fraction - Base
        Math.Number imfFactor;  // Initial Margin Fraction - Factor
        Math.Number mmfFactor;  // Maintenance Margin Fraction - Factor
        Math.Number imfShift;   // Initial Margin Fraction - Shift
    }

    ///// Liquidation /////

    struct LiquidationDataMarket {
        string market;
        Math.Number oraclePrice;
        Math.Number funding;
    }

    struct LiquidationData {
        address account;
        LiquidationDataMarket[] markets;
    }

    ///// Miscellaneous /////

    // Used to map array index to item
    struct ArrIndex {
        uint index;
        bool exists;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.4;

import { Types } from "Types.sol";

/**
 *  @author Paradex
 *  @title Storage
 *  @notice Storage for all the accounts, token & synthetic assets
 *  @dev Verify at execution time whether it is cheaper to have a single AssetBalances
 *  mappings list for each user with a fat struct or two mappings with more lean structs.
 */
contract Storage {
    Types.ParaclearAccounts paraclearAccounts;

    // mapping(tokenAddress => TokenAsset)
    mapping(address => Types.TokenAsset) tokenAssets;
    // mapping(account => mapping(tokenAddress => ArrIndex))
    mapping(address => mapping(address => Types.ArrIndex)) tokenAssetBalanceIndex;
    // mapping(account => TokenAssetBalance[])
    mapping(address => Types.TokenAssetBalance[]) tokenAssetBalances;

    // mapping(market => SyntheticAsset)
    mapping(string => Types.SyntheticAsset) syntheticAssets;
    // mapping(account => mapping(market => ArrIndex))
    mapping(address => mapping(string => Types.ArrIndex)) syntheticAssetBalanceIndex;
    // mapping(account => SyntheticAssetBalance[])
    mapping(address => Types.SyntheticAssetBalance[]) syntheticAssetBalances;
    // mapping(account => mapping(market => LiquidationDataMarket))
    mapping(address => mapping(string => Types.LiquidationDataMarket)) liquidationDataMarkets;

    // TODO: Partially Filled Orders
    // We need a way to keep track of partially executed orders
    // Also how do we handle cleaning this up,
    // else it will just keep growing as orders are filled/canceled.
    // mapping(address => Types.PartiallyFilledOrder[]) partiallyFilledOrders;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.4;

import { Codec } from "Codec.sol";
import { Fees } from "Fees.sol";
import { IPriceOracle } from "IPriceOracle.sol";
import { ISyntheticPriceOracle } from "SyntheticPriceOracle.sol";
import { Math } from "Math.sol";
import { Storage } from "Storage.sol";
import { Token } from "Token.sol";
import { Types } from "Types.sol";

/**
 *  @author Paradex
 *  @title Synthetic
 */
contract Synthetic is Fees, Storage, Token {
    /**
     *  @notice Check if a synthetic asset is supported
     *  @param market ID of the synethetic asset
     */
    function _isAssetSupported(string memory market) internal view returns(bool) {
        return Codec.hash(_getAsset(market).market) != Codec.hash("");
    }

    /**
     *  @notice Initialises empty balance for internal accounts
     *  @param market ID of the synethetic asset
     */
    function _initAssetBalanceForParaclearAccounts(string memory market) internal {
        Types.SyntheticAssetBalance memory emptyBalance = Types.SyntheticAssetBalance({
            market: market,
            sign: true,
            amount: Math.zero(),
            cost: Math.zero(),
            cachedFunding: Math.zero()
        });

        // Fees
        _createAssetBalanceIndex(Storage.paraclearAccounts.feesAccount, market);
        _updateAssetBalance(Storage.paraclearAccounts.feesAccount, emptyBalance);

        // Insurance fund
        _createAssetBalanceIndex(Storage.paraclearAccounts.insuranceFundAccount, market);
        _updateAssetBalance(Storage.paraclearAccounts.insuranceFundAccount, emptyBalance);
    }

    /**
     *  @notice Creates a new synthetic asset representation within Paraclear
     *  @param newAsset Details of the synthetic asset representation
     */
    function _createAsset(Types.SyntheticAsset memory newAsset) internal {
        // Validate that there is no existing SyntheticAsset with the same tokeAddress by
        // comparing against an unset address.
        require(
            !_isAssetSupported(newAsset.market),
            "Synthetic: Can't create multiple assets with the same market"
        );
        Storage.syntheticAssets[newAsset.market] = newAsset;
        _initAssetBalanceForParaclearAccounts(newAsset.market);
    }

    /**
     *  @notice Gets the synthetic asset representation for a market
     *  @param market ID of the synethetic asset
     */
    function _getAsset(
        string memory market
    ) internal view returns (Types.SyntheticAsset memory) {
        return Storage.syntheticAssets[market];
    }

    /**
     *  @notice Gets funding from price oracle
     *  @param market ID of the synethetic asset
     */
    function _getAssetFundingFeed(string memory market) internal view returns (Math.Number memory) {
        ISyntheticPriceOracle oracleFeed = ISyntheticPriceOracle(_getAsset(market).priceOracleAddress);
        Math.Number memory funding = oracleFeed.getFunding();
        return funding;
    }

    /**
     *  @notice Gets latest price from price oracle
     *  @param market ID of the synethetic asset
     */
    function _getAssetPriceFeed(string memory market) internal view returns (Math.Number memory) {
        ISyntheticPriceOracle oracleFeed = ISyntheticPriceOracle(_getAsset(market).priceOracleAddress);
        IPriceOracle.PriceData memory priceData = oracleFeed.getLatestPrice();
        return Math.create(priceData.answer, priceData.sign);
    }

    function getAssetSettlementAsset(string memory market) internal view returns(address) {
        return _getAsset(market).settlementAsset;
    }

    /**
     *  @notice Gets the synthetic asset balance for a user account
     *  @param account Address of the user account
     *  @param market ID of the synethetic asset
     */
    function _getAssetBalance(
        address account,
        string memory market
    ) internal view returns(Types.SyntheticAssetBalance memory) {
        Types.ArrIndex memory balanceIndex = Storage.syntheticAssetBalanceIndex[account][market];
        require(
            balanceIndex.exists == true,
            "Synthetic: Can't get balance that does not exist"
        );
        return Storage.syntheticAssetBalances[account][balanceIndex.index];
    }

    /**
     *  @notice Deletes the asset balance record if no balance
     *  @param account Address of the user account
     *  @param market ID of the synethetic asset
     */
    function _deleteAssetBalance(address account, string memory market) internal {
        Types.ArrIndex memory balanceIndex = Storage.syntheticAssetBalanceIndex[account][market];
        require(
            balanceIndex.exists == true,
            "Synthetic: Can't delete balance that has not been initialized before"
        );
        require(
            Storage.syntheticAssetBalances[account][balanceIndex.index].amount.value == 0,
            "Synthetic: Can't delete balance that has a valid amount"
        );
        delete Storage.syntheticAssetBalances[account][balanceIndex.index];
        delete Storage.syntheticAssetBalanceIndex[account][market];
    }

    /**
     *  @notice Creates the asset balance index for mapping
     *  @param account Address of the user account
     *  @param market ID of the synethetic asset
     */
    function _createAssetBalanceIndex(
        address account,
        string memory market
    ) internal returns (Types.ArrIndex memory) {
        Types.ArrIndex memory balanceIndex = _getAssetBalanceIndex(account, market);
        // Only if unset continue.
        require(
            !balanceIndex.exists,
            "Synthetic: Can't create multiple indexes of same market"
        );

        uint index = Storage.syntheticAssetBalances[account].length;
        Types.ArrIndex memory newBalanceIndex = Types.ArrIndex({
            index: index, exists: true
        });
        Storage.syntheticAssetBalanceIndex[account][market] = newBalanceIndex;

        return newBalanceIndex;
    }

    /**
     *  @notice Gets the asset balance index for mapping
     *  @param account Address of the user account
     *  @param market ID of the synethetic asset
     */
    function _getAssetBalanceIndex(
        address account,
        string memory market
    ) internal view returns (Types.ArrIndex memory) {
        return Storage.syntheticAssetBalanceIndex[account][market];
    }

    /**
     *  @notice Gets asset balance by index
     *  @param account Address of the user account
     *  @param index Index for mapping
     */
    function _getAssetBalanceByIndex(
        address account, uint index
    ) internal view returns (Types.SyntheticAssetBalance memory) {
        return Storage.syntheticAssetBalances[account][index];
    }

    /**
     *  @notice Calculates cost price from settlement asset oracle price
     *  @param market ID of the synethetic asset
     *  @param matchPrice Price at which the order's matched and are being traded at
     */
    function _getCostPrice(
        string memory market, Math.Number memory matchPrice
    ) internal view returns (Math.Number memory) {
        Types.SyntheticAsset memory asset = _getAsset(market);
        Math.Number memory oraclePrice = Token._getOraclePriceByAsset(asset.settlementAsset);
        return Math.div(matchPrice, oraclePrice);
    }

    /**
     *  @notice Calculates funding to be applied
     *  @param assetBalance Balance of the synthetic asset
     *  @param currentFunding Current funding
     */
    function _calculateFunding(
        Types.SyntheticAssetBalance memory assetBalance,
        Math.Number memory currentFunding
    ) internal pure returns (Math.Number memory balanceChange) {
        Math.Number memory funding = Math.sub(currentFunding, assetBalance.cachedFunding);
        uint absFundingValue = Math.mul(assetBalance.amount, funding).value;
        bool fundingSign = funding.sign ? !assetBalance.sign : assetBalance.sign;
        return Math.create(absFundingValue, fundingSign);
    }

    /**
     *  @notice Pushes new synthetic asset balance
     *  @param account Address of the user account
     *  @param updatedBalance Updated synthetic asset balance
     */
    function _updateAssetBalance(
        address account,
        Types.SyntheticAssetBalance memory updatedBalance
    ) internal {
        Storage.syntheticAssetBalances[account].push(updatedBalance);
    }

    /**
     *  @notice Updates synthetic asset balance at given index
     *  @param account Address of the user account
     *  @param balanceIndex Array index of the balance
     *  @param updatedBalance Updated synthetic asset balance
     */
    function _updateAssetBalance(
        address account,
        Types.ArrIndex memory balanceIndex,
        Types.SyntheticAssetBalance memory updatedBalance
    ) internal {
        Storage.syntheticAssetBalances[account][balanceIndex.index] = updatedBalance;
    }

    /**
     *  @notice Updates synthetic asset balance, calculate pnl and funding
     *  @param account Address of the user account
     *  @param market ID of the synethetic asset
     *  @param orderSide Whether the user is BUY or SELL the asset
     *  @param matchSize Size which is being traded, it is not necesarily the same as the order's size
     *  @param matchPrice Price at which the order's matched and are being traded at
     */
    function _updateAssetBalance(
        address account,
        string memory market,
        Types.OrderSide orderSide,
        Math.Number memory matchSize,
        Math.Number memory matchPrice
    ) internal returns (Types.SyntheticAssetBalance memory, Math.Number memory, Math.Number memory) {
        Types.ArrIndex memory balanceIndex = _getAssetBalanceIndex(account, market);
        Math.Number memory currentFunding = _getAssetFundingFeed(market);

        Math.Number memory fundingBalance = Math.zero();
        Math.Number memory unrealizedPnl = Math.zero();
        Math.Number memory costPrice = _getCostPrice(market, matchPrice);

        Types.SyntheticAssetBalance memory updatedBalance = Types.SyntheticAssetBalance({
            market: market,
            sign: orderSide == Types.OrderSide.Buy,
            amount: matchSize,
            cost: Math.zero(),
            cachedFunding: currentFunding
        });
        // Create balance
        if (balanceIndex.exists == false) {
            updatedBalance.cost = Math.mul(costPrice, matchSize);
            balanceIndex = _createAssetBalanceIndex(account, market);

            // Persist balance update
            _updateAssetBalance(account, updatedBalance);
        } else {
            Types.SyntheticAssetBalance memory previousBalance = _getAssetBalanceByIndex(
                account, balanceIndex.index
            );
            // Realize Funding
            fundingBalance = _calculateFunding(previousBalance, currentFunding);
            // Increase balance if same side or zero balance
            if (previousBalance.sign == updatedBalance.sign || previousBalance.amount.value == 0) {
                updatedBalance.amount = Math.add(previousBalance.amount, updatedBalance.amount);
                updatedBalance.cost = Math.add(
                    previousBalance.cost,
                    Math.mul(costPrice, matchSize)
                );
            } else {
                // Decrease balance
                if (Math.isLessThan(updatedBalance.amount, previousBalance.amount)) {
                    updatedBalance.sign = previousBalance.sign;
                    updatedBalance.amount = Math.sub(previousBalance.amount, updatedBalance.amount);
                    updatedBalance.cost = Math.mul(
                        previousBalance.cost,
                        Math.sub(previousBalance.amount, matchSize)
                    );
                    updatedBalance.cost = Math.div(
                        updatedBalance.cost,
                        previousBalance.amount
                    );
                // Flip balance
                } else {
                    updatedBalance.amount = Math.sub(updatedBalance.amount, previousBalance.amount);
                    updatedBalance.cost = Math.mul(costPrice, updatedBalance.amount);
                }

                unrealizedPnl = _calculateUnrealizedPnl(
                    orderSide,
                    previousBalance,
                    updatedBalance,
                    matchSize,
                    costPrice
                );
            }

            // Persist balance update
            _updateAssetBalance(account, balanceIndex, updatedBalance);
        }

        return (updatedBalance, fundingBalance, unrealizedPnl);
    }

    /**
     *  @notice Update insurance fund account balance
     *  @param market ID of the synethetic asset
     *  @param amount Balance amount to be added/subtracted
     *  @param sign Sign of the balance - true = LONG, false = SHORT
     */
    function _updateInsuranceFundBalance(
        string memory market, Math.Number memory amount, bool sign
    ) internal {
        address account = Storage.paraclearAccounts.insuranceFundAccount;
        Types.ArrIndex memory balanceIndex = _getAssetBalanceIndex(account, market);
        Types.SyntheticAssetBalance memory previousBalance = _getAssetBalanceByIndex(
            account, balanceIndex.index
        );

        Types.SyntheticAssetBalance memory updatedBalance = Types.SyntheticAssetBalance({
            market: previousBalance.market,
            sign: sign,
            amount: amount,
            cost: previousBalance.cost,
            cachedFunding: previousBalance.cachedFunding
        });

        // Increase balance if same side or zero balance
        if (previousBalance.sign == updatedBalance.sign || previousBalance.amount.value == 0) {
            updatedBalance.amount = Math.add(previousBalance.amount, updatedBalance.amount);
        } else {
            // Decrease balance
            if (Math.isLessThan(updatedBalance.amount, previousBalance.amount)) {
                updatedBalance.sign = previousBalance.sign;
                updatedBalance.amount = Math.sub(previousBalance.amount, updatedBalance.amount);
            // Flip balance
            } else {
                updatedBalance.amount = Math.sub(updatedBalance.amount, previousBalance.amount);
            }
        }

        // Persist balance update
        _updateAssetBalance(account, balanceIndex, updatedBalance);
    }

    /**
     *  @notice Moves synthetic balances to insurance fund account
     *  @param account Address of the user account
     */
    function _moveToInsuranceFund(address account) internal {
        Types.SyntheticAssetBalance[] memory balances = Storage.syntheticAssetBalances[account];

        for (uint i = 0; i < balances.length; i++) {
            string memory market = balances[i].market;
            Types.ArrIndex memory balanceIndex = _getAssetBalanceIndex(account, market);
            Types.SyntheticAssetBalance memory previousBalance = _getAssetBalanceByIndex(
                account, balanceIndex.index
            );

            Types.SyntheticAssetBalance memory updatedBalance = Types.SyntheticAssetBalance({
                market: balances[i].market,
                sign: true,
                amount: Math.zero(),
                cost: Math.zero(),
                cachedFunding: Math.zero()
            });

            _updateInsuranceFundBalance(market, previousBalance.amount, previousBalance.sign);
            _updateAssetBalance(account, balanceIndex, updatedBalance);
        }
    }

    /**
     *  @notice Calculates the margin fraction for a margin check
     *  @param marginParams Details about the synthetic asset margin params
     *  @param abValue Absolute value of the synthetic asset balance
     *  @param checkType Type of margin check - Initial, Maintenance, etc.
     */
    function _marginFraction(
        Types.MarginParams memory marginParams,
        Math.Number memory abValue,
        Types.MarginCheckType checkType
    ) pure internal returns (Math.Number memory) {
        Math.Number memory imfShiftMax = Math.sqrt(
            Math.max(
                Math.zero(),
                Math.sub(abValue, Math.create(marginParams.imfShift))
            )
        );
        Math.Number memory initialMarginFraction = Math.max(
            marginParams.imfBase,
            Math.mul(marginParams.imfFactor, imfShiftMax)
        );

        if (checkType == Types.MarginCheckType.Initial) {
            return initialMarginFraction;
        } else {
            return Math.mul(
                initialMarginFraction,
                marginParams.mmfFactor
            );
        }
    }

    /**
     *  @notice Calculates margin requirement
     *  @param assetBalance Balance of the synthetic asset
     *  @param checkType Type of margin check - Initial, Maintenance, etc.
     */
    function _calculateMarginRequirement(
        Types.SyntheticAssetBalance memory assetBalance, Types.MarginCheckType checkType
    ) internal view returns (Math.Number memory) {
        if (checkType == Types.MarginCheckType.NoRequirement) {
            return Math.zero();
        }
        Types.SyntheticAsset memory asset = Storage.syntheticAssets[assetBalance.market];

        Math.Number memory oraclePrice = _getAssetPriceFeed(assetBalance.market);
        Math.Number memory absBalanceValue = Math.mul(oraclePrice, assetBalance.amount);

        Math.Number memory positionFraction;
        if (checkType == Types.MarginCheckType.Initial) {
            // Initial margin fraction
            positionFraction = _marginFraction(
                asset.marginParams, absBalanceValue, Types.MarginCheckType.Initial
            );
        } else {
            // Maintenance margin fraction
            positionFraction = _marginFraction(
                asset.marginParams, absBalanceValue, Types.MarginCheckType.Maintenance
            );
        }

        Math.Number memory positionMargin = Math.mul(absBalanceValue, positionFraction);
        Math.Number memory feeProvision = Math.mul(absBalanceValue, Fees.maxFeePct);

        Math.Number memory netMargin = Math.add(positionMargin, feeProvision);
        return netMargin;
    }

    /**
     *  @notice Gets margin requirement for all synthetic assets
     *  @param account Address of the user account
     *  @param checkType Type of margin check - Initial, Maintenance, etc.
     */
    function _getTotalMarginRequirement(
        address account, Types.MarginCheckType checkType
    ) internal view returns (Math.Number memory) {
        Types.SyntheticAssetBalance[] memory balances = Storage.syntheticAssetBalances[account];
        Math.Number memory totalMargin = Math.zero();

        for (uint i = 0; i < balances.length; i++) {
            Math.Number memory margin = _calculateMarginRequirement(balances[i], checkType);
            totalMargin = Math.add(totalMargin, margin);
        }

        return totalMargin;
    }

    /**
     *  @notice Calculates realized PnL
     *  @param previousBalance Previous synthetic asset balance
     *  @param updatedBalance Updated synthetic asset balance
     *  @param matchSize Size of the matched orders in trade
     *  @param costPrice Cost price of the matched orders in trade
     *  @param orderSide Whether the user is BUY or SELL the asset
     */
    function _calculateUnrealizedPnl(
        Types.OrderSide orderSide,
        Types.SyntheticAssetBalance memory previousBalance,
        Types.SyntheticAssetBalance memory updatedBalance,
        Math.Number memory matchSize,
        Math.Number memory costPrice
    ) pure internal returns(Math.Number memory) {
        Math.Number memory previousBalanceCost = Math.create(previousBalance.cost, previousBalance.sign);
        Math.Number memory updatedBalanceCost = Math.create(updatedBalance.cost, updatedBalance.sign);

        // updated_cost - previous_cost
        Math.Number memory costDiff = Math.sub(updatedBalanceCost, previousBalanceCost);

        // value = trade_amount * match_price / settlement_asset_oracle_price
        matchSize = Math.create(matchSize, orderSide == Types.OrderSide.Buy);
        Math.Number memory matchValue = Math.mul(costPrice, matchSize);

        // unrealized_pnl = updated_cost - previous_cost - value
        Math.Number memory unrealizedPnl = Math.sub(costDiff, matchValue);

        return unrealizedPnl;
    }

    /**
     *  @notice Calculates unrealized PnL
     *  @param syntheticOraclePrice Oracle price of the synthetic asset
     *  @param balance Current synthetic asset balance
     */
    function _calculateUnrealizedPnl(
        Math.Number memory syntheticOraclePrice,
        Types.SyntheticAssetBalance memory balance
    ) pure internal returns(Math.Number memory unrealizedPnl) {
        Math.Number memory balanceNotional = Math.mul(balance.amount, syntheticOraclePrice);
        if (balance.sign) unrealizedPnl = Math.sub(balanceNotional, balance.cost);
        else unrealizedPnl = Math.sub(balance.cost, balanceNotional);
        return unrealizedPnl;
    }

    /**
     *  @notice Maps liquidation data markets
     *  @param data Liquidation account (user address) and market data
     */
    function _mapLiquidationDataMarkets(Types.LiquidationData memory data) internal {
        for (uint i = 0; i < data.markets.length; i++) {
            Storage.liquidationDataMarkets[data.account][data.markets[i].market] = data.markets[i];
        }
    }

    /**
     *  @notice Gets liquidation data by market
     *  @param account Address of the user account
     *  @param market ID of the synethetic asset
     */
    function _getLiquidationDataByMarket(
        address account, string memory market
    ) internal view returns (Types.LiquidationDataMarket memory) {
        return Storage.liquidationDataMarkets[account][market];
    }

    /**
     *  @notice Saves and returns unrealized PnL and funding for all assets
     *  @param data Liquidation account (user address) and market data
     */
    function _calculateUnrealizedPnlForLiquidation(
        Types.LiquidationData memory data
    ) internal returns (Math.Number memory totalUnrealizedPnl) {
        totalUnrealizedPnl = Math.zero();

        Types.SyntheticAssetBalance[] memory balances = Storage.syntheticAssetBalances[data.account];

        _mapLiquidationDataMarkets(data);

        for (uint i = 0; i < balances.length; i++) {
            string memory market = balances[i].market;
            Types.SyntheticAsset memory asset = _getAsset(market);
            Types.SyntheticAssetBalance memory balance = _getAssetBalanceByIndex(data.account, i);
            Types.LiquidationDataMarket memory marketData = _getLiquidationDataByMarket(data.account, market);

            // Unrealized PnL
            // Math.Number memory syntheticOraclePrice = _getAssetPriceFeed(market);
            Math.Number memory unrealizedPnl = _calculateUnrealizedPnl(marketData.oraclePrice, balance);
            Math.Number memory tokenAssetOraclePrice = _getOraclePriceByAsset(asset.settlementAsset);
            unrealizedPnl = Math.div(unrealizedPnl, tokenAssetOraclePrice);

            // Funding
            // Math.Number memory currentFunding = _getAssetFundingFeed(market);
            Math.Number memory funding = _calculateFunding(balance, marketData.funding);

            // Save unrealized PnL on settlement token asset balance
            Math.Number memory unrealizedPnlAndFunding = Math.add(unrealizedPnl, funding);
            Token._updateAssetBalanceUnrealizedPnl(
                data.account, asset.settlementAsset, unrealizedPnlAndFunding
            );

            totalUnrealizedPnl = Math.add(
                totalUnrealizedPnl,
                unrealizedPnlAndFunding
            );
        }

        return totalUnrealizedPnl;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.4;

/**
 *  @author Paradex
 *  @title Codec
 *  @notice Library for hash functions
 */
library Codec {
    /**
     *  @notice Computes the Keccak-256 hash of the input
     *  @param txt Input that needs to hashed
     */
    function hash(string memory txt) internal pure returns (bytes32) {
        return keccak256(abi.encode(txt));
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.4;

import { Math } from "Math.sol";

/**
 *  @author Paradex
 *  @title Fees
 */
contract Fees {
    // Default maker/taker fees
    Math.Number makerFeePct = Math.create(10_000);  // 0.01%
    Math.Number takerFeePct = Math.create(40_000);  // 0.04%
    Math.Number maxFeePct = Math.max(makerFeePct, takerFeePct);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.4;

interface IPriceOracle {
    struct PriceDataInput {
        bool sign;
        uint answer;
        uint timestamp;
    }

    struct PriceData {
        uint80 roundId;
        bool sign;
        uint answer;
        uint timestamp;
    }

    function decimals() external view returns (uint8);
    function description() external view returns (string memory);
    function version() external view returns (uint);

    // getLatestPrice should raise "no data present" if it do not
    // have data to report, instead of returning unset values which
    // could be misinterpreted as actual reported values.
    function getLatestPrice() external view returns (PriceData memory);

    function setLatestPrice(PriceDataInput memory _latestPrice) external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.4;

import { IERC20 } from "IERC20.sol";
import { ISyntheticPriceOracle } from "ISyntheticPriceOracle.sol";
import { Math } from "Math.sol";
import { PriceOracle } from "PriceOracle.sol";

/**
 *  @author Paradex
 *  @title SyntheticPriceOracle
 */
contract SyntheticPriceOracle is PriceOracle, ISyntheticPriceOracle {
    Math.Number funding;

    constructor(uint8 _decimals, string memory _description)
        PriceOracle(_decimals, _description) {}

    /**
     *  @notice Retrieves the latest funding value
     */
    function getFunding() public view returns (Math.Number memory) {
        return funding;
    }

    /**
     *  @notice Saves the latest funding value
     *  @param _funding Funding value to be saved
     */
    function setFunding(Math.Number memory _funding) public onlyOwner {
        funding = _funding;
    }

    /**
     *  @notice Retrieves the latest oracle price and funding value
     */
    function getLatestPriceAndFunding() public view returns (
        PriceData memory, Math.Number memory
    ) {
        return (latestPriceData, funding);
    }

    /**
     *  @notice Saves the latest oracle price and funding value
     *  @param _latestPrice Latest price data input value
     *  @param _funding Funding value to be saved
     */
    function setLatestPriceAndFunding(
        PriceDataInput memory _latestPrice, Math.Number memory _funding
    ) external onlyOwner {
        PriceOracle.setLatestPrice(_latestPrice);
        setFunding(_funding);
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

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.4;

import { IPriceOracle } from "IPriceOracle.sol";
import { Math } from "Math.sol";

/**
 *  @author Paradex
 *  @title ISyntheticPriceOracle
 */
interface ISyntheticPriceOracle is IPriceOracle {
    function getFunding() external view returns (Math.Number memory);
    function setFunding(Math.Number memory _funding) external;
    function getLatestPriceAndFunding() external view returns (
        PriceData memory, Math.Number memory
    );
    function setLatestPriceAndFunding(
        PriceDataInput memory _latestPrice, Math.Number memory _funding
    ) external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.4;

import { IPriceOracle } from "IPriceOracle.sol";
import { Ownable } from "Ownable.sol";

/**
 *  @author Paradex
 *  @title PriceOracle
 */
contract PriceOracle is IPriceOracle, Ownable {
    uint8 public immutable decimals;
    string public description;
    uint public constant version = 1;

    PriceData latestPriceData;

    constructor(uint8 _decimals, string memory _description) {
        decimals = _decimals;
        description = _description;
    }

    /**
     *  @notice Retrieves the latest oracle price
     */
    function getLatestPrice() public view returns (PriceData memory) {
        require(latestPriceData.roundId > 0, "PriceOracle: No data present");
        return latestPriceData;
    }

    /**
     *  @notice Saves the latest oracle price
     *  @param _latestPrice Latest price data input value
     */
    function setLatestPrice(PriceDataInput memory _latestPrice) public onlyOwner {
        require(
            latestPriceData.timestamp < _latestPrice.timestamp,
            "PriceOracle: Current data has a more recent timestamp"
        );
        latestPriceData.roundId += 1;
        latestPriceData.sign = _latestPrice.sign;
        latestPriceData.answer = _latestPrice.answer;
        latestPriceData.timestamp = _latestPrice.timestamp;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.4;

import { Fees } from "Fees.sol";
import { IERC20Metadata } from "IERC20Metadata.sol";
import { IPriceOracle } from "IPriceOracle.sol";
import { Math } from "Math.sol";
import { Storage } from "Storage.sol";
import { Types } from "Types.sol";

/**
 *  @author Paradex
 *  @title Token
 */
contract Token is Storage {
    Math.Number liquidationKeepPct = Math.create(20_000_000);  // Take 80%, Keep 20%
    Math.Number liquidationTakePct = Math.create(80_000_000);  // Take 80%, Keep 20%

    /**
     *  @notice Check if a token asset exists
     *  @param tokenAddress Address of the token asset contract
     */
    function _isExistingAsset(address tokenAddress) internal view returns (bool) {
        // Validate that there is an existing TokenAsset with the same tokeAddress
        return Storage.tokenAssets[tokenAddress].tokenAddress != address(0);
    }

    /**
     *  @notice Initialises empty balance for internal accounts
     *  @param tokenAddress Address of the token asset contract
     */
    function _initAssetBalanceForParaclearAccounts(address tokenAddress) internal {
        _createAssetBalance(Storage.paraclearAccounts.feesAccount, tokenAddress, Math.zero());
        _createAssetBalance(Storage.paraclearAccounts.insuranceFundAccount, tokenAddress, Math.zero());
    }

    /**
     *  @notice Creates a new token asset representation within Paraclear
     *  @param newTokenAsset Details of the token asset representation
     */
    function _createAsset(Types.TokenAsset memory newTokenAsset) internal {
        // Validate that there is no existing TokenAsset with the same tokeAddress by
        // comparing against an unset address.
        require(
            Storage.tokenAssets[newTokenAsset.tokenAddress].tokenAddress == address(0),
            "Token: Can't create multiple assets with the same token address"
        );

        Storage.tokenAssets[newTokenAsset.tokenAddress] = newTokenAsset;

        // Initialise empty balance for internal accounts
        _initAssetBalanceForParaclearAccounts(newTokenAsset.tokenAddress);
    }

    /**
     *  @notice Gets token asset representation for a address
     *  @param tokenAddress Address of the token asset contract
     */
    function _getAsset(
        address tokenAddress
    ) internal view returns (Types.TokenAsset memory token) {
        return Storage.tokenAssets[tokenAddress];
    }

    /**
     *  @notice Creates token asset balance for a user
     *  @param account Address of the user account
     *  @param tokenAddress Address of the token asset contract
     *  @param amount Amount added to the user's balance
     */
    function _createAssetBalance(
        address account, address tokenAddress, Math.Number memory amount
    ) internal returns (Types.TokenAssetBalance memory) {
        require(
            Storage.tokenAssetBalanceIndex[account][tokenAddress].exists == false,
            "Token: Can't create multiple balances of same token address"
        );

        Types.TokenAssetBalance memory newBalance = Types.TokenAssetBalance({
            tokenAddress: tokenAddress,
            amount: amount,
            unrealizedPnl: Math.zero()
        });

        Storage.tokenAssetBalances[account].push(newBalance);
        uint index = Storage.tokenAssetBalances[account].length - 1;
        Types.ArrIndex memory newBalanceIndex = Types.ArrIndex({
            index: index, exists: true
        });
        Storage.tokenAssetBalanceIndex[account][tokenAddress] = newBalanceIndex;

        return Storage.tokenAssetBalances[account][index];
    }

    /**
     *  @notice Gets token asset balance for a user account
     *  @param account Address of the user account
     *  @param tokenAddress Address of the token asset contract
     */
    function _getAssetBalance(
        address account, address tokenAddress
    ) internal view returns (Math.Number memory) {
        Types.ArrIndex memory balanceIndex = Storage.tokenAssetBalanceIndex[account][tokenAddress];
        require(
            balanceIndex.exists == true,
            "Token: Can't get balance that has not been initialized before"
        );

        Types.TokenAssetBalance memory currentBalance = Storage.tokenAssetBalances[account][balanceIndex.index];

        // Get decimals representation from token asset
        IERC20Metadata token = IERC20Metadata(currentBalance.tokenAddress);
        uint8 decimals = token.decimals();

        // Value with token asset decimals representation
        uint value = Math.convertFromInternal(currentBalance.amount.value, decimals);

        return Math.create(value, currentBalance.amount.sign);
    }

    /**
     *  @notice Updates token asset balance for a user account
     *  @param account Address of the user account
     *  @param tokenAddress Address of the token asset contract
     *  @param balanceChange Adds or removes specified balance change
     */
    function _updateAssetBalance(
        address account, address tokenAddress, Math.Number memory balanceChange
    )
        internal returns (Types.TokenAssetBalance memory) {
        Types.ArrIndex memory balanceIndex = Storage.tokenAssetBalanceIndex[account][tokenAddress];
        Types.TokenAssetBalance memory newBalance;
        if (balanceIndex.exists == false) {
            newBalance = _createAssetBalance(account, tokenAddress, balanceChange);
        } else {
            Types.TokenAssetBalance memory currentBalance = Storage.tokenAssetBalances[account][balanceIndex.index];
            newBalance = Types.TokenAssetBalance({
                tokenAddress: tokenAddress,
                amount: Math.add(currentBalance.amount, balanceChange),
                unrealizedPnl: currentBalance.unrealizedPnl
            });
        }

        Storage.tokenAssetBalances[account][balanceIndex.index] = newBalance;

        return newBalance;
    }

    /**
     *  @notice Updates token asset balance unrealized PnL for a user account
     *  @param account Address of the user account
     *  @param tokenAddress Address of the token asset contract
     *  @param unrealizedPnl Unrealized PnL used for liquidations
     */
    function _updateAssetBalanceUnrealizedPnl(
        address account, address tokenAddress, Math.Number memory unrealizedPnl
    ) internal {
        Types.ArrIndex memory balanceIndex = Storage.tokenAssetBalanceIndex[account][tokenAddress];

        require(
            balanceIndex.exists == true,
            "Token: Can't update unrealized PnL for balance that has not been initialized before"
        );

        Types.TokenAssetBalance memory balance = Storage.tokenAssetBalances[account][balanceIndex.index];
        balance.unrealizedPnl = unrealizedPnl;

        Storage.tokenAssetBalances[account][balanceIndex.index] = balance;
    }

    /**
     *  @notice Sets token asset balance for a user account
     *  @param account Address of the user account
     *  @param tokenAddress Address of the token asset contract
     *  @param balanceAmount Specified balance amount
     */
    function _setAssetBalance(
        address account, address tokenAddress, Math.Number memory balanceAmount
    ) internal {
        Types.ArrIndex memory balanceIndex = Storage.tokenAssetBalanceIndex[account][tokenAddress];

        require(
            balanceIndex.exists == true,
            "Token: Can't get balance that has not been initialized before"
        );

        Types.TokenAssetBalance memory balance = Types.TokenAssetBalance({
            tokenAddress: tokenAddress,
            amount: balanceAmount,
            unrealizedPnl: Math.zero()
        });

        Storage.tokenAssetBalances[account][balanceIndex.index] = balance;
    }

    /**
     *  @notice Empty token asset balance for a user account
     *  @param account Address of the user account
     *  @param tokenAddress Address of the token asset contract
     */
    function _emptyAssetBalance(address account, address tokenAddress) internal {
        _setAssetBalance(account, tokenAddress, Math.zero());
    }

    /**
     *  @notice Transfers fee from user account to fee account
     *  @param from Address of the user account
     *  @param tokenAddress Address of the token asset contract
     *  @param amount Fee amount transferred from balance
     */
    function _transferToFeesAccount(address from, address tokenAddress, uint amount) internal {
        // Decrease `from` account token balance
        Math.Number memory amountToDec = Math.create(amount, false);
        _updateAssetBalance(from, tokenAddress, amountToDec);

        // Increase fee account token balance
        address feesAccount = Storage.paraclearAccounts.feesAccount;
        Math.Number memory amountToInc = Math.create(amount, true);
        _updateAssetBalance(feesAccount, tokenAddress, amountToInc);
    }

    /**
     *  @notice Transfers token balances to insurance fund account
     *  @param from Address of the user account
     */
    function _transferToInsuranceFund(address from) internal {
        Types.TokenAssetBalance[] memory balances = Storage.tokenAssetBalances[from];
        address insuranceFundAccount = Storage.paraclearAccounts.insuranceFundAccount;

        for (uint i = 0; i < balances.length; i++) {
            Math.Number memory accountValue = Math.add(balances[i].amount, balances[i].unrealizedPnl);

            if (Math.isPositive(accountValue)) {
                Math.Number memory keepAmount = Math.mul(liquidationKeepPct, accountValue);

                // Set `from` account token balance to keep amount
                _setAssetBalance(from, balances[i].tokenAddress, keepAmount);

                // Increase insurance fund token balance
                Math.Number memory takeAmount = Math.sub(balances[i].amount, keepAmount);
                _updateAssetBalance(insuranceFundAccount, balances[i].tokenAddress, takeAmount);
            } else {
                _emptyAssetBalance(from, balances[i].tokenAddress);

                if (Math.isPositive(balances[i].amount)) {
                    _updateAssetBalance(
                        insuranceFundAccount, balances[i].tokenAddress, balances[i].amount
                    );
                }
            }
        }
    }

    /**
     *  @notice Deletes token asset balance
     *  @param account Address of the user account
     *  @param tokenAddress Address of the token asset contract
     */
    function _deleteAssetBalance(address account, address tokenAddress) internal {
        Types.ArrIndex memory balanceIndex = Storage.tokenAssetBalanceIndex[account][tokenAddress];
        require(
            balanceIndex.exists == true,
            "Token: Can't delete balance that has not been initialized before"
        );
        require(
            Math.isPositive(tokenAssetBalances[account][balanceIndex.index].amount),
            "Token: Can't delete balance that has a valid amount"
        );
        delete Storage.tokenAssetBalances[account][balanceIndex.index];
        delete Storage.tokenAssetBalanceIndex[account][tokenAddress];
    }

    /**
     *  @notice Gets pracle price of a token asset
     *  @param priceOracleAddress Address of the price oracle
     */
    function _getOraclePriceByAddress(address priceOracleAddress) internal view returns (Math.Number memory) {
        IPriceOracle priceFeed = IPriceOracle(priceOracleAddress);
        IPriceOracle.PriceData memory oracleData = priceFeed.getLatestPrice();
        Math.Number memory oraclePrice = Math.create(oracleData.answer, oracleData.sign);
        return oraclePrice;
    }

    /**
     *  @notice Gets pracle price of a token asset
     *  @param tokenAddress Address of the token asset contract
     */
    function _getOraclePriceByAsset(address tokenAddress) internal view returns (Math.Number memory) {
        Types.TokenAsset memory asset = Storage.tokenAssets[tokenAddress];
        Math.Number memory oraclePrice = _getOraclePriceByAddress(asset.priceOracleAddress);
        return oraclePrice;
    }

    /**
     *  @notice Gets balance value for all token assets
     *  @param account Address of the user account
     */
    function _getAllAssetBalanceValue(address account) internal view returns (Math.Number memory) {
        Types.TokenAssetBalance[] memory balances = Storage.tokenAssetBalances[account];
        Math.Number memory totalValue = Math.zero();

        for (uint i = 0; i < balances.length; i++) {
            Types.TokenAsset memory asset = Storage.tokenAssets[balances[i].tokenAddress];
            Math.Number memory oraclePrice = _getOraclePriceByAddress(asset.priceOracleAddress);
            Math.Number memory assetValue = Math.mul(balances[i].amount, oraclePrice);
            totalValue = Math.add(totalValue, assetValue);
        }

        return totalValue;
    }
    /**
     *  @notice Updates token asset balance with unrealized Funding
     *  @param account Address of the user account
     *  @param tokenAddress Address of the token asset contract
     *  @param funding Unrealized funding value to realize on the user's collateral.
     */
    function _realizeFunding(
        address account,
        address tokenAddress,
        Math.Number memory funding
    ) internal {
        _updateAssetBalance(account, tokenAddress, funding);
    }

    /**
     *  @notice Updates token asset balance with unrealized PnL
     *  @param account Address of the user account
     *  @param tokenAddress Address of the token asset contract
     *  @param pnlAmount Unrealized PnL amount added to balance
     */
    function _realizePnl(
        address account,
        address tokenAddress,
        Math.Number memory pnlAmount
    ) internal {
        Math.Number memory tokenAssetOraclePrice = _getOraclePriceByAsset(tokenAddress);
        Math.Number memory amount = Math.div(pnlAmount, tokenAssetOraclePrice);

        _updateAssetBalance(account, tokenAddress, amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "IERC20.sol";

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

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.4;

import { Events } from "Events.sol";
import { IERC20Metadata } from "IERC20Metadata.sol";
import { Math } from "Math.sol";
import { Token } from "Token.sol";
import { Types } from "Types.sol";

/**
 *  @author Paradex
 *  @title Transfer
 */
contract Transfer is Events, Token {
    /**
     *  @notice Transfers tokens from a user to Paraclear
     *  @param tokenAddress Address of the token asset contract
     *  @param amount Amount the user wants to deposit
     */
    function _deposit(address account, address tokenAddress, uint amount) internal {
        require(amount > 0, "Transfer: You need to deposit at least some tokens");
        require(Token._isExistingAsset(tokenAddress), "Transfer: Token address is invalid");

        IERC20Metadata token = IERC20Metadata(tokenAddress);

        // Check token allowance
        uint allowance = token.allowance(account, address(this));
        require(allowance >= amount, "Transfer: Check the token allowance");

        // Transfer the amount to our contract
        token.transferFrom(account, address(this), amount);

        // Value with internal decimals representation
        uint8 decimals = token.decimals();
        uint value = Math.convertToInternal(amount, decimals);

        // Increase token asset balance
        Math.Number memory balanceChange = Math.create(value, true);
        Token._updateAssetBalance(account, tokenAddress, balanceChange);

        Events._emitDeposit(account, tokenAddress, amount);
    }

    /**
     *  @notice Transfer amount from Paraclear to a user
     *  @param tokenAddress Address of the token asset contract
     *  @param amount Amount the user wants to withdraw
     */
    function _withdraw(address account, address tokenAddress, uint amount) internal {
        require(amount > 0, "Transfer: You need to withdraw at least some tokens");
        require(Token._isExistingAsset(tokenAddress), "Transfer: Token address is invalid");

        Math.Number memory tokenAssetBalance = Token._getAssetBalance(account, tokenAddress);
        require(
            tokenAssetBalance.value >= amount && tokenAssetBalance.sign == true,
            "Transfer: Requested amount is more than available balance"
        );

        IERC20Metadata token = IERC20Metadata(tokenAddress);

        // Check token balance
        uint tokenBalance = token.balanceOf(address(this));
        require(tokenBalance >= amount, "Transfer: Check the token balance");

        // Transfer the amount to user
        token.transfer(account, amount);

        // Value with internal decimals representation
        uint8 decimals = token.decimals();
        uint value = Math.convertToInternal(amount, decimals);

        // Decrease token asset balance
        Math.Number memory balanceChange = Math.create(value, false);
        Token._updateAssetBalance(account, tokenAddress, balanceChange);

        Events._emitWithdraw(account, tokenAddress, amount);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.4;

import { Codec } from "Codec.sol";
import { Events } from "Events.sol";
import { Fees } from "Fees.sol";
import { Funding } from "Funding.sol";
import { Math } from "Math.sol";
import { Storage } from "Storage.sol";
import { Synthetic } from "Synthetic.sol";
import { Token } from "Token.sol";
import { Types } from "Types.sol";
import { VerifyOrderSignature } from "VerifyOrderSignature.sol";

/**
 *  @author Paradex
 *  @title Trade
 */
contract Trade is Funding, Events, Synthetic, VerifyOrderSignature {
    /**
     *  @notice Checks if order risk is acceptable
     *  @param account Address of the user account
     */
    function _isOrderRiskAcceptable(address account) internal view returns (bool) {
        Math.Number memory tokenAssetsValue = Token._getAllAssetBalanceValue(account);
        Math.Number memory syntheticAssetsMarginRequirement = Synthetic._getTotalMarginRequirement(
            account, Types.MarginCheckType.Initial
        );
        Math.Number memory freeBalance = Math.sub(tokenAssetsValue, syntheticAssetsMarginRequirement);
        return Math.isPositive(freeBalance) || freeBalance.value == 0;
    }

    /**
     *  @notice Transfers fee from maker/taker accounts to fee account
     *  @param market ID of the synethetic asset
     *  @param makerAccount Account of the maker order
     *  @param takerAccount Account of the taker order
     *  @param matchSize Size of the matched orders in trade
     *  @param matchPrice Price of the matched orders in trade
     */
    function _transferFees(
        string memory market,
        address makerAccount,
        address takerAccount,
        Math.Number memory matchSize,
        Math.Number memory matchPrice
    ) internal {
        Types.SyntheticAsset memory syntheticAsset = Synthetic._getAsset(market);
        address tokenAddress = syntheticAsset.settlementAsset;

        // Caculate value
        Math.Number memory oraclePrice = Token._getOraclePriceByAsset(tokenAddress);
        Math.Number memory notionalValue = Math.div(
            Math.mul(matchPrice, matchSize),
            oraclePrice
        );

        // Calculate fees
        Math.Number memory makerFee = Math.mul(notionalValue, Fees.makerFeePct);
        Math.Number memory takerFee = Math.mul(notionalValue, Fees.takerFeePct);

        // Deduct fees from token asset balances
        Token._transferToFeesAccount(makerAccount, tokenAddress, makerFee.value);
        Token._transferToFeesAccount(takerAccount, tokenAddress, takerFee.value);
    }

    /**
     *  @notice Settles trade request for matching maker and taker orders
     *  @param trade Trade request containing matching maker/taker orders
     */
    function _settle(Types.TradeRequest memory trade) internal {
        require(trade.matchSize.value != 0, "Trade: Match size must be different than 0");
        require(trade.makerOrder.size.value != 0, "Trade: Maker Order size must be different than 0");
        require(trade.takerOrder.size.value != 0, "Trade: Maker Order size must be different than 0");

        // VerifyOrderSignature._verify(trade.makerOrder);
        // VerifyOrderSignature._verify(trade.takerOrder);

        require(
            Codec.hash(trade.makerOrder.market) == Codec.hash(trade.takerOrder.market),
            "Trade: Orders must be for the same synthetic asset"
        );

        bool isSyntheticSupported = Synthetic._isAssetSupported(trade.makerOrder.market);
        require(
            isSyntheticSupported,
            "Trade: Synthetic asset is not supported"
        );

        require(
            trade.makerOrder.side != trade.takerOrder.side,
            "Trade: Orders must have opposing sides"
        );

        (
            Types.SyntheticAssetBalance memory makerBalance,
            Math.Number memory makerFunding,
            Math.Number memory makerUnrealizedPnl
        ) = Synthetic._updateAssetBalance(
            trade.makerOrder.account,
            trade.makerOrder.market,
            trade.makerOrder.side,
            trade.matchSize,
            trade.matchPrice
        );
        Token._realizeFunding(
            trade.makerOrder.account,
            Synthetic.getAssetSettlementAsset(trade.makerOrder.market),
            makerFunding
        );
        Token._realizePnl(
            trade.makerOrder.account,
            Synthetic.getAssetSettlementAsset(trade.makerOrder.market),
            makerUnrealizedPnl
        );
        Math.Number memory fundingRate = Synthetic._getAssetFundingFeed(trade.makerOrder.market);

        // TODO: Flatten trade events to single event per user
        Events._emitSyntheticBalanceUpdate(trade.id, trade.makerOrder.account, makerBalance);
        Events._emitFundingAccrued(
            trade.id, trade.makerOrder.account, trade.makerOrder.market, makerFunding, fundingRate
        );

       (
            Types.SyntheticAssetBalance memory takerBalance,
            Math.Number memory takerFunding,
            Math.Number memory takerUnrealizedPnl
        ) = Synthetic._updateAssetBalance(
            trade.takerOrder.account,
            trade.takerOrder.market,
            trade.takerOrder.side,
            trade.matchSize,
            trade.matchPrice
        );
        Token._realizeFunding(
            trade.takerOrder.account,
            Synthetic.getAssetSettlementAsset(trade.takerOrder.market),
            takerFunding
        );
        Token._realizePnl(
            trade.takerOrder.account,
            Synthetic.getAssetSettlementAsset(trade.takerOrder.market),
            takerUnrealizedPnl
        );

        // Track Funding
        if (makerFunding.sign == true) {
            Funding._incrementFundingReceived(makerFunding);
            Funding._incrementFundingPaid(takerFunding);
        } else {
            Funding._incrementFundingReceived(takerFunding);
            Funding._incrementFundingPaid(makerFunding);
        }

        // TODO: Flatten trade events to single event per user
        Events._emitSyntheticBalanceUpdate(trade.id, trade.takerOrder.account, takerBalance);
        Events._emitFundingAccrued(
            trade.id, trade.takerOrder.account, trade.takerOrder.market, takerFunding, fundingRate
        );

        // Pay trading fees
        _transferFees(
            trade.makerOrder.market,
            trade.makerOrder.account,
            trade.takerOrder.account,
            trade.matchSize,
            trade.matchPrice
        );

        require(
            _isOrderRiskAcceptable(trade.makerOrder.account),
            "Trade: Order is too risky for the maker account"
        );
        require(
            _isOrderRiskAcceptable(trade.takerOrder.account),
            "Trade: Order is too risky for the taker account"
        );
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.4;

import { Trade } from "Trade.sol";
import { Types } from "Types.sol";
import { VerifySignature } from "VerifySignature.sol";

/**
 *  @author Paradex
 *  @title VerifyOrderSignature
 *  @notice Library for order signature verification
 */
contract VerifyOrderSignature is VerifySignature {
    bytes32 LIMIT_ORDER_TYPEHASH = keccak256(
        "Order(string market,uint8 side,uint8 orderType,uint256 size,uint256 price)"
    );
    bytes32 MARKET_ORDER_TYPEHASH = keccak256(
        "Order(string market,uint8 side,uint8 orderType,uint256 size)"
    );

    /**
     *  @notice Builds limit order hash required for verification
     *  @param order Maker or Taker order received as part of a trade
     */
    function _buildLimitOrderHash(Types.Order memory order) internal view returns (bytes32) {
        return keccak256(
            abi.encode(
                LIMIT_ORDER_TYPEHASH,
                keccak256(
                    bytes(order.market)),
                    order.side,
                    order.orderType,
                    order.size.value,
                    order.price.value
            )
        );
    }

    /**
     *  @notice Builds market order hash required for verification
     *  @param order Maker or Taker order received as part of a trade
     */
    function _buildMarketOrderHash(Types.Order memory order) internal view returns (bytes32) {
        return keccak256(
            abi.encode(
                MARKET_ORDER_TYPEHASH,
                keccak256(
                    bytes(order.market)),
                    order.side,
                    order.orderType,
                    order.size.value
            )
        );
    }

    /**
     *  @notice Builds the order hash required for verification
     *  @param order Maker or Taker order received as part of a trade
     */
    function _buildOrderHash(Types.Order memory order) internal view returns (bytes32 orderHash) {
        if (order.orderType == Types.OrderType.Limit) {
            orderHash = _buildLimitOrderHash(order);
        } else if (order.orderType == Types.OrderType.Market) {
            orderHash = _buildMarketOrderHash(order);
        }
        return orderHash;
    }

    /**
     *  @notice Fetch the hash for a given order
     *  @param order Maker or Taker order received as part of a trade
     */
    function _getOrderHash(Types.Order memory order) internal view returns (bytes32) {
        return keccak256(abi.encodePacked(
            // From the message signing process, it gets prepended with the byte \x19 and joined with the version
            // of value (byte) \x01.
            // https://github.com/ApeWorX/eip712/blob/68f5ebbf8603dcd137251eed93ace2caaed09e2d/eip712/messages.py#L61
            // https://github.com/ApeWorX/eip712/blob/68f5ebbf8603dcd137251eed93ace2caaed09e2d/eip712/messages.py#L157
            "\x19\x01",
            VerifySignature.buildDomainSeparator(),
            _buildOrderHash(order)
        ));
    }

    /**
     *  @notice Verify that the account in order matches signer
     *  @param order Maker or Taker order received as part of a trade
     */
    function _verify(Types.Order memory order) internal view {
        require(
            VerifySignature.recoverSigner(_getOrderHash(order), order.signature) == order.account,
            "VerifyOrderSignature: Account doesn't match signer"
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { Trade } from "Trade.sol";

/**
 *  @author Paradex
 *  @title VerifySignature
 *  @notice Library for signature verification
 */
contract VerifySignature {
    bytes32 constant DOMAIN_TYPEHASH = keccak256(
        "EIP712Domain(string name,string version,uint256 chainId)"
    );

    /**
     *  @notice The domain separator prevents collision of otherwise identical structures
     */
    function buildDomainSeparator() internal view returns (bytes32) {
        bytes32 hashedName = keccak256("Paradex");
        bytes32 hashedVersion = keccak256("1");
        return keccak256(abi.encode(DOMAIN_TYPEHASH, hashedName, hashedVersion, block.chainid));
    }

    /**
     *  @notice Recover signer by splitting the signature
     *  @param messageHash Message hash that contains the signer
     *  @param signature Signature of the signed message
     */
    function recoverSigner(
        bytes32 messageHash, bytes memory signature
    ) internal pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = _splitSignature(signature);
        return ecrecover(messageHash, v, r, s);
    }

    /**
     *  @notice Split the signature to get details
     *  @param signature A signature to split
     */
    function _splitSignature(
        bytes memory signature
    ) internal pure returns (bytes32 r, bytes32 s, uint8 v) {
        require(signature.length == 65, "VerifySignature: Invalid signature length");

        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }
    }
}