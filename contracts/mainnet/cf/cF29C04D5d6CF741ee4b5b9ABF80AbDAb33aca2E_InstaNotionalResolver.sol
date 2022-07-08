// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;
pragma abicoder v2;

import "./interfaces.sol";
import "./helpers.sol";

contract Resolver is Helpers {
    /// @notice Returns all account details in a single view
    /// @param account account address
    function getAccount(address account)
        external
        view
        returns (
            AccountContext memory accountContext,
            AccountBalance[] memory accountBalances,
            PortfolioAsset[] memory portfolio
        )
    {
        return notional.getAccount(account);
    }

    /// @notice Returns free collateral of an account along with an array of the individual net available
    /// asset cash amounts
    /// @param account account address
    function getFreeCollateral(address account) external view returns (int256, int256[] memory) {
        return notional.getFreeCollateral(account);
    }

    /// @notice Returns a currency and its corresponding asset rate and ETH exchange rates.
    /// @dev Note that this does not recalculate cToken interest rates, it only retrieves the latest stored rate.
    /// @param currencyId currency ID
    function getCurrencyAndRates(uint16 currencyId)
        external
        view
        returns (
            Token memory assetToken,
            Token memory underlyingToken,
            ETHRate memory ethRate,
            AssetRateParameters memory assetRate
        )
    {
        return notional.getCurrencyAndRates(currencyId);
    }

    /// @notice Returns the asset settlement rate for a given maturity
    /// @param currencyId currency ID
    /// @param maturity fCash maturity
    function getSettlementRate(uint16 currencyId, uint40 maturity) external view returns (AssetRateParameters memory) {
        return notional.getSettlementRate(currencyId, maturity);
    }

    /// @notice Returns all currently active markets for a currency
    /// @param currencyId currency ID
    function getActiveMarkets(uint16 currencyId) external view returns (MarketParameters[] memory) {
        return notional.getActiveMarkets(currencyId);
    }

    /// @notice Returns the claimable incentives for all nToken balances
    /// @param account The address of the account which holds the tokens
    /// @param blockTime The block time when incentives will be minted
    /// @return Incentives an account is eligible to claim
    function nTokenGetClaimableIncentives(address account, uint256 blockTime) external view returns (uint256) {
        return notional.nTokenGetClaimableIncentives(account, blockTime);
    }

    /// @notice Returns the nTokens that will be minted when some amount of asset tokens are deposited
    /// @param currencyId currency ID
    /// @param amountToDepositExternalPrecision amount of cash to deposit in external precision
    function calculateNTokensToMint(uint16 currencyId, uint88 amountToDepositExternalPrecision)
        external
        view
        returns (uint256)
    {
        return notional.calculateNTokensToMint(currencyId, amountToDepositExternalPrecision);
    }

    /// @notice Returns the amount of fCash that would received if lending deposit amount.
    /// @param currencyId id number of the currency
    /// @param depositAmountExternal amount to deposit in the token's native precision. For aTokens use
    /// what is returned by the balanceOf selector (not scaledBalanceOf).
    /// @param maturity the maturity of the fCash to lend
    /// @param minLendRate the minimum lending rate (slippage protection)
    /// @param blockTime the block time for when the trade will be calculated
    /// @param useUnderlying true if specifying the underlying token, false if specifying the asset token
    /// @return fCashAmount the amount of fCash that the lender will receive
    /// @return marketIndex the corresponding market index for the lending
    /// @return encodedTrade the encoded bytes32 object to pass to batch trade
    function getfCashLendFromDeposit(
        uint16 currencyId,
        uint256 depositAmountExternal,
        uint256 maturity,
        uint32 minLendRate,
        uint256 blockTime,
        bool useUnderlying
    )
        external
        view
        returns (
            uint88 fCashAmount,
            uint8 marketIndex,
            bytes32 encodedTrade
        )
    {
        return
            notional.getfCashLendFromDeposit(
                currencyId,
                depositAmountExternal,
                maturity,
                minLendRate,
                blockTime,
                useUnderlying
            );
    }

    /// @notice Returns the amount of fCash that would received if lending deposit amount.
    /// @param currencyId id number of the currency
    /// @param borrowedAmountExternal amount to borrow in the token's native precision. For aTokens use
    /// what is returned by the balanceOf selector (not scaledBalanceOf).
    /// @param maturity the maturity of the fCash to lend
    /// @param maxBorrowRate the maximum borrow rate (slippage protection). If zero then no slippage will be applied
    /// @param blockTime the block time for when the trade will be calculated
    /// @param useUnderlying true if specifying the underlying token, false if specifying the asset token
    /// @return fCashDebt the amount of fCash that the borrower will owe, this will be stored as a negative
    /// balance in Notional
    /// @return marketIndex the corresponding market index for the lending
    /// @return encodedTrade the encoded bytes32 object to pass to batch trade
    function getfCashBorrowFromPrincipal(
        uint16 currencyId,
        uint256 borrowedAmountExternal,
        uint256 maturity,
        uint32 maxBorrowRate,
        uint256 blockTime,
        bool useUnderlying
    )
        external
        view
        returns (
            uint88 fCashDebt,
            uint8 marketIndex,
            bytes32 encodedTrade
        )
    {
        return
            notional.getfCashBorrowFromPrincipal(
                currencyId,
                borrowedAmountExternal,
                maturity,
                maxBorrowRate,
                blockTime,
                useUnderlying
            );
    }

    /// @notice Returns the amount of underlying cash and asset cash required to lend fCash. When specifying a
    /// trade, deposit either underlying or asset tokens (not both). Asset tokens tend to be more gas efficient.
    /// @param currencyId id number of the currency
    /// @param fCashAmount amount of fCash (in underlying) that will be received at maturity. Always 8 decimal precision.
    /// @param maturity the maturity of the fCash to lend
    /// @param minLendRate the minimum lending rate (slippage protection)
    /// @param blockTime the block time for when the trade will be calculated
    /// @return depositAmountUnderlying the amount of underlying tokens the lender must deposit
    /// @return depositAmountAsset the amount of asset tokens the lender must deposit
    /// @return marketIndex the corresponding market index for the lending
    /// @return encodedTrade the encoded bytes32 object to pass to batch trade
    function getDepositFromfCashLend(
        uint16 currencyId,
        uint256 fCashAmount,
        uint256 maturity,
        uint32 minLendRate,
        uint256 blockTime
    )
        external
        view
        returns (
            uint256 depositAmountUnderlying,
            uint256 depositAmountAsset,
            uint8 marketIndex,
            bytes32 encodedTrade
        )
    {
        return notional.getDepositFromfCashLend(currencyId, fCashAmount, maturity, minLendRate, blockTime);
    }

    /// @notice Returns the amount of underlying cash and asset cash required to borrow fCash. When specifying a
    /// trade, choose to receive either underlying or asset tokens (not both). Asset tokens tend to be more gas efficient.
    /// @param currencyId id number of the currency
    /// @param fCashBorrow amount of fCash (in underlying) that will be received at maturity. Always 8 decimal precision.
    /// @param maturity the maturity of the fCash to lend
    /// @param maxBorrowRate the maximum borrow rate (slippage protection)
    /// @param blockTime the block time for when the trade will be calculated
    /// @return borrowAmountUnderlying the amount of underlying tokens the borrower will receive
    /// @return borrowAmountAsset the amount of asset tokens the borrower will receive
    /// @return marketIndex the corresponding market index for the lending
    /// @return encodedTrade the encoded bytes32 object to pass to batch trade
    function getPrincipalFromfCashBorrow(
        uint16 currencyId,
        uint256 fCashBorrow,
        uint256 maturity,
        uint32 maxBorrowRate,
        uint256 blockTime
    )
        external
        view
        returns (
            uint256 borrowAmountUnderlying,
            uint256 borrowAmountAsset,
            uint8 marketIndex,
            bytes32 encodedTrade
        )
    {
        return notional.getPrincipalFromfCashBorrow(currencyId, fCashBorrow, maturity, maxBorrowRate, blockTime);
    }

    /// @notice Converts an internal cash balance to an external token denomination
    /// @param currencyId the currency id of the cash balance
    /// @param cashBalanceInternal the signed cash balance that is stored in Notional
    /// @param convertToUnderlying true if the value should be converted to underlying
    /// @return the cash balance converted to the external token denomination
    function convertCashBalanceToExternal(
        uint16 currencyId,
        int256 cashBalanceInternal,
        bool convertToUnderlying
    ) external view returns (int256) {
        return notional.convertCashBalanceToExternal(currencyId, cashBalanceInternal, convertToUnderlying);
    }
}

contract InstaNotionalResolver is Resolver {
    string public constant name = "Notional-Resolver-v1";
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @notice Used internally for PortfolioHandler state
enum AssetStorageState {
    NoChange,
    Update,
    Delete,
    RevertIfStored
}

/// @notice Different types of internal tokens
///  - UnderlyingToken: underlying asset for a cToken (except for Ether)
///  - cToken: Compound interest bearing token
///  - cETH: Special handling for cETH tokens
///  - Ether: the one and only
///  - NonMintable: tokens that do not have an underlying (therefore not cTokens)
///  - aToken: Aave interest bearing tokens
enum TokenType {
    UnderlyingToken,
    cToken,
    cETH,
    Ether,
    NonMintable,
    aToken
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

/// @dev Used in view methods to return account balances in a developer friendly manner
struct AccountBalance {
    uint16 currencyId;
    int256 cashBalance;
    int256 nTokenBalance;
    uint256 lastClaimTime;
    uint256 lastClaimIntegralSupply;
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

/// @notice Internal object that represents a token
struct Token {
    address tokenAddress;
    bool hasTransferFee;
    int256 decimals;
    TokenType tokenType;
    uint256 maxCollateralBalance;
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

/// @dev Asset rate used to convert between underlying cash and asset cash
struct AssetRateParameters {
    // Address of the asset rate oracle
    AssetRateAdapter rateOracle;
    // The exchange rate from base to quote (if invert is required it is already done)
    int256 rate;
    // The decimals of the underlying, the rate converts to the underlying decimals
    int256 underlyingDecimals;
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

/// @notice Notional view functions
interface NotionalInterface {
    function getAccount(address account)
        external
        view
        returns (
            AccountContext memory accountContext,
            AccountBalance[] memory accountBalances,
            PortfolioAsset[] memory portfolio
        );

    function getFreeCollateral(address account) external view returns (int256, int256[] memory);

    function getCurrencyAndRates(uint16 currencyId)
        external
        view
        returns (
            Token memory assetToken,
            Token memory underlyingToken,
            ETHRate memory ethRate,
            AssetRateParameters memory assetRate
        );

    function getSettlementRate(uint16 currencyId, uint40 maturity) external view returns (AssetRateParameters memory);

    function getActiveMarkets(uint16 currencyId) external view returns (MarketParameters[] memory);

    function nTokenGetClaimableIncentives(address account, uint256 blockTime) external view returns (uint256);

    function calculateNTokensToMint(uint16 currencyId, uint88 amountToDepositExternalPrecision)
        external
        view
        returns (uint256);

    function getfCashLendFromDeposit(
        uint16 currencyId,
        uint256 depositAmountExternal,
        uint256 maturity,
        uint32 minLendRate,
        uint256 blockTime,
        bool useUnderlying
    )
        external
        view
        returns (
            uint88 fCashAmount,
            uint8 marketIndex,
            bytes32 encodedTrade
        );

    function getfCashBorrowFromPrincipal(
        uint16 currencyId,
        uint256 borrowedAmountExternal,
        uint256 maturity,
        uint32 maxBorrowRate,
        uint256 blockTime,
        bool useUnderlying
    )
        external
        view
        returns (
            uint88 fCashDebt,
            uint8 marketIndex,
            bytes32 encodedTrade
        );

    function getDepositFromfCashLend(
        uint16 currencyId,
        uint256 fCashAmount,
        uint256 maturity,
        uint32 minLendRate,
        uint256 blockTime
    )
        external
        view
        returns (
            uint256 depositAmountUnderlying,
            uint256 depositAmountAsset,
            uint8 marketIndex,
            bytes32 encodedTrade
        );

    function getPrincipalFromfCashBorrow(
        uint16 currencyId,
        uint256 fCashBorrow,
        uint256 maturity,
        uint32 maxBorrowRate,
        uint256 blockTime
    )
        external
        view
        returns (
            uint256 borrowAmountUnderlying,
            uint256 borrowAmountAsset,
            uint8 marketIndex,
            bytes32 encodedTrade
        );

    function convertCashBalanceToExternal(
        uint16 currencyId,
        int256 cashBalanceInternal,
        bool useUnderlying
    ) external view returns (int256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;
import { NotionalInterface, Token, AssetRateParameters } from "./interfaces.sol";
import { DSMath } from "../../../utils/dsmath.sol";

contract Helpers is DSMath {
    /// @dev Contract address is different on Kovan: 0x0EAE7BAdEF8f95De91fDDb74a89A786cF891Eb0e
    NotionalInterface internal constant notional = NotionalInterface(0x1344A36A1B56144C3Bc62E7757377D288fDE0369);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

contract DSMath {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "math-not-safe");
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x - y <= x ? x - y : 0;
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "math-not-safe");
    }

    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    uint256 internal constant WAD = 10**18;
    uint256 internal constant RAY = 10**27;

    function rmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, y), RAY / 2) / RAY;
    }

    function wmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }

    function rdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, RAY), y / 2) / y;
    }

    function wdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, WAD), y / 2) / y;
    }
}