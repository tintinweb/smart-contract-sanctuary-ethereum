// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "../interfaces/IMToken.sol";
import "../libraries/ErrorCodes.sol";
import "../interfaces/IChainlinkPriceOracle.sol";

contract ChainlinkPriceOracle is IChainlinkPriceOracle, AccessControl {
    /**
     *  @notice Structure to store oracle related data for the token
     */
    struct TokenConfig {
        // Chainlink oracle interface for current token
        AggregatorV3Interface chainlinkAggregator;
        // Original token decimals
        uint8 underlyingTokenDecimals;
        // Const for price converting
        uint8 reporterMultiplier;
        /// @dev max threshold for oracle validation
        uint32 timestampThreshold;
    }

    /// @dev Mapping to store oracle related configuration for tokens
    mapping(address => TokenConfig) public feedProxies;

    /**
     * @notice Construct a ChainlinkPriceOracle contract.
     * @param admin The address of the Admin
     */
    constructor(address admin) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
    }

    function pow10(uint8 power) private pure returns (uint256) {
        if (power == 18) return 1e18;
        else if (power == 6) return 1e6;
        else if (power == 8) return 1e8;
        else if (power == 1) return 1e1;
        else if (power == 2) return 1e2;
        else if (power == 3) return 1e3;
        else if (power == 4) return 1e4;
        else if (power == 5) return 1e5;
        else if (power == 7) return 1e7;
        else if (power == 9) return 1e9;
        else if (power == 10) return 1e10;
        else if (power == 11) return 1e11;
        else if (power == 12) return 1e12;
        else if (power == 13) return 1e13;
        else if (power == 14) return 1e14;
        else if (power == 15) return 1e15;
        else if (power == 16) return 1e16;
        else if (power == 17) return 1e17;
        else if (power == 19) return 1e19;
        else if (power == 20) return 1e20;
        else if (power == 21) return 1e21;
        else if (power == 22) return 1e22;
        else if (power == 23) return 1e23;
        else if (power == 24) return 1e24;
        else if (power == 25) return 1e25;
        else return 1e26;
    }

    /**
     * @notice Convert price received from oracle to be scaled by 1e8
     * @param config token config
     * @param reportedPrice raw oracle price
     * @return price scaled by 1e8
     */
    function convertReportedPrice(TokenConfig memory config, int256 reportedPrice) internal pure returns (uint256) {
        require(reportedPrice > 0, ErrorCodes.REPORTED_PRICE_SHOULD_BE_GREATER_THAN_ZERO);
        uint256 unsignedPrice = uint256(reportedPrice);
        uint256 convertedPrice = (unsignedPrice * pow10(config.reporterMultiplier)) /
            pow10(config.underlyingTokenDecimals);
        return convertedPrice;
    }

    /// @inheritdoc IPriceOracle
    function getUnderlyingPrice(IMToken mToken) external view returns (uint256) {
        require(address(mToken) != address(0), ErrorCodes.MTOKEN_ADDRESS_CANNOT_BE_ZERO);
        return getAssetPrice(address(mToken.underlying()));
    }

    /// @inheritdoc IPriceOracle
    function getAssetPrice(address asset) public view returns (uint256) {
        require(asset != address(0), ErrorCodes.TOKEN_ADDRESS_CANNOT_BE_ZERO);

        TokenConfig memory config = feedProxies[asset];
        require(config.chainlinkAggregator != AggregatorV3Interface(address(0)), ErrorCodes.TOKEN_NOT_FOUND);

        // prettier-ignore
        (
            uint80 roundId,
            int256 answer,
            ,
            uint256 updatedAt,
            uint80 answeredInRound
        ) = config.chainlinkAggregator.latestRoundData();

        require(block.timestamp - updatedAt <= config.timestampThreshold, ErrorCodes.ORACLE_PRICE_EXPIRED);
        require(answeredInRound == roundId, ErrorCodes.RECEIVED_PRICE_HAS_INVALID_ROUND);

        uint256 convertedPrice = convertReportedPrice(config, answer);

        return (convertedPrice * 1e28) / pow10(config.underlyingTokenDecimals);
    }

    /// @inheritdoc IChainlinkPriceOracle
    function setTokenConfig(
        address token,
        address oracleAddress,
        uint8 underlyingTokenDecimals,
        uint8 reporterMultiplier,
        uint32 timestampThreshold
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(token != address(0), ErrorCodes.TOKEN_ADDRESS_CANNOT_BE_ZERO);
        require(oracleAddress != address(0), ErrorCodes.OR_ORACLE_ADDRESS_CANNOT_BE_ZERO);
        require(underlyingTokenDecimals > 0, ErrorCodes.OR_UNDERLYING_TOKENS_DECIMALS_SHOULD_BE_GREATER_THAN_ZERO);
        require(reporterMultiplier > 0, ErrorCodes.OR_REPORTER_MULTIPLIER_SHOULD_BE_GREATER_THAN_ZERO);
        require(underlyingTokenDecimals < 27, ErrorCodes.OR_UNDERLYING_TOKENS_DECIMALS_TOO_BIG);
        require(reporterMultiplier < 27, ErrorCodes.OR_REPORTER_MULTIPLIER_TOO_BIG);
        require(timestampThreshold > 0, ErrorCodes.OR_TIMESTAMP_THRESHOLD_SHOULD_BE_GREATER_THAN_ZERO);

        feedProxies[token] = TokenConfig(
            AggregatorV3Interface(oracleAddress),
            underlyingTokenDecimals,
            reporterMultiplier,
            timestampThreshold
        );
        emit NewTokenConfigSet(token, oracleAddress, underlyingTokenDecimals, reporterMultiplier, timestampThreshold);
    }
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.17;

import "@openzeppelin/contracts/interfaces/IERC3156FlashLender.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";
import "./IInterestRateModel.sol";

interface IMToken is IAccessControl, IERC20, IERC3156FlashLender, IERC165 {
    /**
     * @notice Event emitted when interest is accrued
     */
    event AccrueInterest(
        uint256 cashPrior,
        uint256 interestAccumulated,
        uint256 borrowIndex,
        uint256 totalBorrows,
        uint256 totalProtocolInterest
    );

    /**
     * @notice Event emitted when tokens are lended
     */
    event Lend(address lender, uint256 lendAmount, uint256 lendTokens, uint256 newTotalTokenSupply);

    /**
     * @notice Event emitted when tokens are redeemed
     */
    event Redeem(address redeemer, uint256 redeemAmount, uint256 redeemTokens, uint256 newTotalTokenSupply);

    /**
     * @notice Event emitted when underlying is borrowed
     */
    event Borrow(address borrower, uint256 borrowAmount, uint256 accountBorrows, uint256 totalBorrows);

    /**
     * @notice Event emitted when tokens are seized
     */
    event Seize(
        address borrower,
        address receiver,
        uint256 seizeTokens,
        uint256 accountsTokens,
        uint256 totalSupply,
        uint256 seizeUnderlyingAmount
    );

    /**
     * @notice Event emitted when a borrow is repaid
     */
    event RepayBorrow(
        address payer,
        address borrower,
        uint256 repayAmount,
        uint256 accountBorrows,
        uint256 totalBorrows
    );

    /**
     * @notice Event emitted when a borrow is repaid during autoliquidation
     */
    event AutoLiquidationRepayBorrow(
        address borrower,
        uint256 repayAmount,
        uint256 accountBorrowsNew,
        uint256 totalBorrowsNew,
        uint256 TotalProtocolInterestNew
    );

    /**
     * @notice Event emitted when flash loan is executed
     */
    event FlashLoanExecuted(address receiver, uint256 amount, uint256 fee);

    /**
     * @notice Event emitted when interestRateModel is changed
     */
    event NewMarketInterestRateModel(IInterestRateModel oldInterestRateModel, IInterestRateModel newInterestRateModel);

    /**
     * @notice Event emitted when the protocol interest factor is changed
     */
    event NewProtocolInterestFactor(
        uint256 oldProtocolInterestFactorMantissa,
        uint256 newProtocolInterestFactorMantissa
    );

    /**
     * @notice Event emitted when the flash loan max share is changed
     */
    event NewFlashLoanMaxShare(uint256 oldMaxShare, uint256 newMaxShare);

    /**
     * @notice Event emitted when the flash loan fee is changed
     */
    event NewFlashLoanFee(uint256 oldFee, uint256 newFee);

    /**
     * @notice Event emitted when the protocol interest are added
     */
    event ProtocolInterestAdded(address benefactor, uint256 addAmount, uint256 newTotalProtocolInterest);

    /**
     * @notice Event emitted when the protocol interest reduced
     */
    event ProtocolInterestReduced(address admin, uint256 reduceAmount, uint256 newTotalProtocolInterest);

    /**
     * @notice Value is the Keccak-256 hash of "TIMELOCK"
     */
    function TIMELOCK() external view returns (bytes32);

    /**
     * @notice Underlying asset for this MToken
     */
    function underlying() external view returns (IERC20);

    /**
     * @notice EIP-20 token name for this token
     */
    function name() external view returns (string memory);

    /**
     * @notice EIP-20 token symbol for this token
     */
    function symbol() external view returns (string memory);

    /**
     * @notice EIP-20 token decimals for this token
     */
    function decimals() external view returns (uint8);

    /**
     * @notice Model which tells what the current interest rate should be
     */
    function interestRateModel() external view returns (IInterestRateModel);

    /**
     * @notice Initial exchange rate used when lending the first MTokens (used when totalTokenSupply = 0)
     */
    function initialExchangeRateMantissa() external view returns (uint256);

    /**
     * @notice Fraction of interest currently set aside for protocol interest
     */
    function protocolInterestFactorMantissa() external view returns (uint256);

    /**
     * @notice Block number that interest was last accrued at
     */
    function accrualBlockNumber() external view returns (uint256);

    /**
     * @notice Accumulator of the total earned interest rate since the opening of the market
     */
    function borrowIndex() external view returns (uint256);

    /**
     * @notice Total amount of outstanding borrows of the underlying in this market
     */
    function totalBorrows() external view returns (uint256);

    /**
     * @notice Total amount of protocol interest of the underlying held in this market
     */
    function totalProtocolInterest() external view returns (uint256);

    /**
     * @notice Share of market's current underlying token balance that can be used as flash loan (scaled by 1e18).
     */
    function maxFlashLoanShare() external view returns (uint256);

    /**
     * @notice Share of flash loan amount that would be taken as fee (scaled by 1e18).
     */
    function flashLoanFeeShare() external view returns (uint256);

    /**
     * @notice Returns total token supply
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice Transfer `amount` tokens from `msg.sender` to `dst`
     * @param dst The address of the destination account
     * @param amount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transfer(address dst, uint256 amount) external returns (bool);

    /**
     * @notice Transfer `amount` tokens from `src` to `dst`
     * @param src The address of the source account
     * @param dst The address of the destination account
     * @param amount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transferFrom(
        address src,
        address dst,
        uint256 amount
    ) external returns (bool);

    /**
     * @notice Approve `spender` to transfer up to `amount` from `src`
     * @dev This will overwrite the approval amount for `spender`
     *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
     * @param spender The address of the account which may transfer tokens
     * @param amount The number of tokens that are approved (-1 means infinite)
     * @return Whether or not the approval succeeded
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @notice Get the current allowance from `owner` for `spender`
     * @param owner The address of the account which owns the tokens to be spent
     * @param spender The address of the account which may transfer tokens
     * @return The number of tokens allowed to be spent (-1 means infinite)
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @notice Get the token balance of the `owner`
     * @param owner The address of the account to query
     * @return The number of tokens owned by `owner`
     */
    function balanceOf(address owner) external view returns (uint256);

    /**
     * @notice Get the underlying balance of the `owner`
     * @dev This also accrues interest in a transaction
     * @param owner The address of the account to query
     * @return The amount of underlying owned by `owner`
     */
    function balanceOfUnderlying(address owner) external returns (uint256);

    /**
     * @notice Get a snapshot of the account's balances, and the cached exchange rate
     * @dev This is used by supervisor to more efficiently perform liquidity checks.
     * @param account Address of the account to snapshot
     * @return (token balance, borrow balance, exchange rate mantissa)
     */
    function getAccountSnapshot(address account)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    /**
     * @notice Returns the current per-block borrow interest rate for this mToken
     * @return The borrow interest rate per block, scaled by 1e18
     */
    function borrowRatePerBlock() external view returns (uint256);

    /**
     * @notice Returns the current per-block supply interest rate for this mToken
     * @return The supply interest rate per block, scaled by 1e18
     */
    function supplyRatePerBlock() external view returns (uint256);

    /**
     * @notice Returns the current total borrows plus accrued interest
     * @return The total borrows with interest
     */
    function totalBorrowsCurrent() external returns (uint256);

    /**
     * @notice Accrue interest to updated borrowIndex and then calculate account's
     *         borrow balance using the updated borrowIndex
     * @param account The address whose balance should be calculated after updating borrowIndex
     * @return The calculated balance
     */
    function borrowBalanceCurrent(address account) external returns (uint256);

    /**
     * @notice Return the borrow balance of account based on stored data
     * @param account The address whose balance should be calculated
     * @return The calculated balance
     */
    function borrowBalanceStored(address account) external view returns (uint256);

    /**
     * @notice Accrue interest then return the up-to-date exchange rate
     * @return Calculated exchange rate scaled by 1e18
     */
    function exchangeRateCurrent() external returns (uint256);

    /**
     * @notice Calculates the exchange rate from the underlying to the MToken
     * @dev This function does not accrue interest before calculating the exchange rate
     * @return Calculated exchange rate scaled by 1e18
     */
    function exchangeRateStored() external view returns (uint256);

    /**
     * @notice Get cash balance of this mToken in the underlying asset
     * @return The quantity of underlying asset owned by this contract
     */
    function getCash() external view returns (uint256);

    /**
     * @notice Applies accrued interest to total borrows and protocol interest
     * @dev This calculates interest accrued from the last checkpointed block
     *   up to the current block and writes new checkpoint to storage.
     */
    function accrueInterest() external;

    /**
     * @notice Sender supplies assets into the market and receives mTokens in exchange
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param lendAmount The amount of the underlying asset to supply
     */
    function lend(uint256 lendAmount) external;

    /**
     * @notice Sender redeems mTokens in exchange for the underlying asset
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param redeemTokens The number of mTokens to redeem into underlying
     */
    function redeem(uint256 redeemTokens) external;

    /**
     * @notice Redeems all mTokens for account in exchange for the underlying asset.
     * Can only be called within the AML system!
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param account An account that is potentially sanctioned by the AML system
     */
    function redeemByAmlDecision(address account) external;

    /**
     * @notice Sender redeems mTokens in exchange for a specified amount of underlying asset
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param redeemAmount The amount of underlying to receive from redeeming mTokens
     */
    function redeemUnderlying(uint256 redeemAmount) external;

    /**
     * @notice Sender borrows assets from the protocol to their own address
     * @param borrowAmount The amount of the underlying asset to borrow
     */
    function borrow(uint256 borrowAmount) external;

    /**
     * @notice Sender repays their own borrow
     * @param repayAmount The amount to repay
     */
    function repayBorrow(uint256 repayAmount) external;

    /**
     * @notice Sender repays a borrow belonging to borrower
     * @param borrower the account with the debt being payed off
     * @param repayAmount The amount to repay
     */
    function repayBorrowBehalf(address borrower, uint256 repayAmount) external;

    /**
     * @notice Liquidator repays a borrow belonging to borrower
     * @param borrower_ the account with the debt being payed off
     * @param repayAmount_ the amount of underlying tokens being returned
     */
    function autoLiquidationRepayBorrow(address borrower_, uint256 repayAmount_) external;

    /**
     * @notice A public function to sweep accidental ERC-20 transfers to this contract.
     *         Tokens are sent to admin (timelock)
     * @param token The address of the ERC-20 token to sweep
     * @dev RESTRICTION: Admin only.
     */
    function sweepToken(IERC20 token, address admin_) external;

    /**
     * @notice Burns collateral tokens at the borrower's address, transfer underlying assets
     to the DeadDrop or Liquidator address.
     * @dev Called only during an auto liquidation process, msg.sender must be the Liquidation contract.
     * @param borrower_ The account having collateral seized
     * @param seizeUnderlyingAmount_ The number of underlying assets to seize. The caller must ensure
     that the parameter is greater than zero.
     * @param isLoanInsignificant_ Marker for insignificant loan whose collateral must be credited to the
     protocolInterest
     * @param receiver_ Address that receives accounts collateral
     */
    function autoLiquidationSeize(
        address borrower_,
        uint256 seizeUnderlyingAmount_,
        bool isLoanInsignificant_,
        address receiver_
    ) external;

    /**
     * @notice The amount of currency available to be lent.
     * @param token The loan currency.
     * @return The amount of `token` that can be borrowed.
     */
    function maxFlashLoan(address token) external view returns (uint256);

    /**
     * @notice The fee to be charged for a given loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @return The amount of `token` to be charged for the loan, on top of the returned principal.
     */
    function flashFee(address token, uint256 amount) external view returns (uint256);

    /**
     * @notice Initiate a flash loan.
     * @param receiver The receiver of the tokens in the loan, and the receiver of the callback.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     */
    function flashLoan(
        IERC3156FlashBorrower receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) external returns (bool);

    /**
     * @notice accrues interest and sets a new protocol interest factor for the protocol
     * @dev Admin function to accrue interest and set a new protocol interest factor
     * @dev RESTRICTION: Timelock only.
     */
    function setProtocolInterestFactor(uint256 newProtocolInterestFactorMantissa) external;

    /**
     * @notice Accrues interest and increase protocol interest by transferring from msg.sender
     * @param addAmount_ Amount of addition to protocol interest
     */
    function addProtocolInterest(uint256 addAmount_) external;

    /**
     * @notice Can only be called by liquidation contract. Increase protocol interest by transferring from payer.
     * @dev Calling code should make sure that accrueInterest() was called before.
     * @param payer_ The address from which the protocol interest will be transferred
     * @param addAmount_ Amount of addition to protocol interest
     */
    function addProtocolInterestBehalf(address payer_, uint256 addAmount_) external;

    /**
     * @notice Accrues interest and reduces protocol interest by transferring to admin
     * @param reduceAmount Amount of reduction to protocol interest
     * @dev RESTRICTION: Admin only.
     */
    function reduceProtocolInterest(uint256 reduceAmount, address admin_) external;

    /**
     * @notice accrues interest and updates the interest rate model using setInterestRateModelFresh
     * @dev Admin function to accrue interest and update the interest rate model
     * @param newInterestRateModel the new interest rate model to use
     * @dev RESTRICTION: Admin only.
     */
    function setInterestRateModel(IInterestRateModel newInterestRateModel) external;

    /**
     * @notice Updates share of markets cash that can be used as maximum amount of flash loan.
     * @param newMax New max amount share
     * @dev RESTRICTION: Admin only.
     */
    function setFlashLoanMaxShare(uint256 newMax) external;

    /**
     * @notice Updates fee of flash loan.
     * @param newFee New fee share of flash loan
     * @dev RESTRICTION: Timelock only.
     */
    function setFlashLoanFeeShare(uint256 newFee) external;
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.17;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./IMToken.sol";
import "./IPriceOracle.sol";

interface IChainlinkPriceOracle is IPriceOracle {
    event NewTokenConfigSet(
        address token,
        address oracleAddress,
        uint8 underlyingTokenDecimals,
        uint8 reporterMultiplier,
        uint32 timestampThreshold
    );

    /**
     * @notice Return config for token
     */
    function feedProxies(address)
        external
        view
        returns (
            AggregatorV3Interface chainlinkAggregator,
            uint8 underlyingTokenDecimals,
            uint8 reporterMultiplier,
            uint32 timestampThreshold
        );

    /**
     * @notice Set the proxy of a underlying asset
     * @param token The underlying to set the price oracle proxy of
     * @param oracleAddress Address of corresponding oracle
     * @param underlyingTokenDecimals Original token decimals
     * @param reporterMultiplier Constant, using for decimal cast from decimals,
                                  returned by oracle to required decimals.
     * @param timestampThreshold  max threshold for oracle validation
     * @dev reporterMultiplier = 8 + underlyingDecimals - feedDecimals
     * @dev RESTRICTION: Admin only
     */
    function setTokenConfig(
        address token,
        address oracleAddress,
        uint8 underlyingTokenDecimals,
        uint8 reporterMultiplier,
        uint32 timestampThreshold
    ) external;
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.17;

library ErrorCodes {
    // Common
    string internal constant ADMIN_ONLY = "E101";
    string internal constant UNAUTHORIZED = "E102";
    string internal constant OPERATION_PAUSED = "E103";
    string internal constant WHITELISTED_ONLY = "E104";
    string internal constant ADDRESS_IS_NOT_IN_AML_SYSTEM = "E105";
    string internal constant ADDRESS_IS_BLACKLISTED = "E106";

    // Invalid input
    string internal constant ADMIN_ADDRESS_CANNOT_BE_ZERO = "E201";
    string internal constant INVALID_REDEEM = "E202";
    string internal constant REDEEM_TOO_MUCH = "E203";
    string internal constant MARKET_NOT_LISTED = "E204";
    string internal constant INSUFFICIENT_LIQUIDITY = "E205";
    string internal constant INVALID_SENDER = "E206";
    string internal constant BORROW_CAP_REACHED = "E207";
    string internal constant BALANCE_OWED = "E208";
    string internal constant UNRELIABLE_LIQUIDATOR = "E209";
    string internal constant INVALID_DESTINATION = "E210";
    string internal constant INSUFFICIENT_STAKE = "E211";
    string internal constant INVALID_DURATION = "E212";
    string internal constant INVALID_PERIOD_RATE = "E213";
    string internal constant EB_TIER_LIMIT_REACHED = "E214";
    string internal constant INVALID_DEBT_REDEMPTION_RATE = "E215";
    string internal constant LQ_INVALID_SEIZE_DISTRIBUTION = "E216";
    string internal constant EB_TIER_DOES_NOT_EXIST = "E217";
    string internal constant EB_ZERO_TIER_CANNOT_BE_ENABLED = "E218";
    string internal constant EB_ALREADY_ACTIVATED_TIER = "E219";
    string internal constant EB_END_BLOCK_MUST_BE_LARGER_THAN_CURRENT = "E220";
    string internal constant EB_CANNOT_MINT_TOKEN_FOR_ACTIVATED_TIER = "E221";
    string internal constant EB_EMISSION_BOOST_IS_NOT_IN_RANGE = "E222";
    string internal constant TARGET_ADDRESS_CANNOT_BE_ZERO = "E223";
    string internal constant INSUFFICIENT_TOKEN_IN_VESTING_CONTRACT = "E224";
    string internal constant VESTING_SCHEDULE_ALREADY_EXISTS = "E225";
    string internal constant INSUFFICIENT_TOKENS_TO_CREATE_SCHEDULE = "E226";
    string internal constant NO_VESTING_SCHEDULE = "E227";
    string internal constant SCHEDULE_IS_IRREVOCABLE = "E228";
    string internal constant MNT_AMOUNT_IS_ZERO = "E230";
    string internal constant INCORRECT_AMOUNT = "E231";
    string internal constant MEMBERSHIP_LIMIT = "E232";
    string internal constant MEMBER_NOT_EXIST = "E233";
    string internal constant MEMBER_ALREADY_ADDED = "E234";
    string internal constant MEMBERSHIP_LIMIT_REACHED = "E235";
    string internal constant REPORTED_PRICE_SHOULD_BE_GREATER_THAN_ZERO = "E236";
    string internal constant MTOKEN_ADDRESS_CANNOT_BE_ZERO = "E237";
    string internal constant TOKEN_ADDRESS_CANNOT_BE_ZERO = "E238";
    string internal constant REDEEM_TOKENS_OR_REDEEM_AMOUNT_MUST_BE_ZERO = "E239";
    string internal constant FL_TOKEN_IS_NOT_UNDERLYING = "E240";
    string internal constant FL_AMOUNT_IS_TOO_LARGE = "E241";
    string internal constant FL_CALLBACK_FAILED = "E242";
    string internal constant DD_UNSUPPORTED_TOKEN = "E243";
    string internal constant DD_MARKET_ADDRESS_IS_ZERO = "E244";
    string internal constant DD_ROUTER_ADDRESS_IS_ZERO = "E245";
    string internal constant DD_RECEIVER_ADDRESS_IS_ZERO = "E246";
    string internal constant DD_BOT_ADDRESS_IS_ZERO = "E247";
    string internal constant DD_MARKET_NOT_FOUND = "E248";
    string internal constant DD_RECEIVER_NOT_FOUND = "E249";
    string internal constant DD_BOT_NOT_FOUND = "E250";
    string internal constant DD_ROUTER_ALREADY_SET = "E251";
    string internal constant DD_RECEIVER_ALREADY_SET = "E252";
    string internal constant DD_BOT_ALREADY_SET = "E253";
    string internal constant EB_MARKET_INDEX_IS_LESS_THAN_USER_INDEX = "E254";
    string internal constant LQ_INVALID_DRR_ARRAY = "E255";
    string internal constant LQ_INVALID_SEIZE_ARRAY = "E256";
    string internal constant LQ_INVALID_DEBT_REDEMPTION_RATE = "E257";
    string internal constant LQ_INVALID_SEIZE_INDEX = "E258";
    string internal constant LQ_DUPLICATE_SEIZE_INDEX = "E259";
    string internal constant DD_INVALID_TOKEN_IN_ADDRESS = "E260";
    string internal constant DD_INVALID_TOKEN_OUT_ADDRESS = "E261";
    string internal constant DD_INVALID_TOKEN_IN_AMOUNT = "E262";

    // Protocol errors
    string internal constant INVALID_PRICE = "E301";
    string internal constant MARKET_NOT_FRESH = "E302";
    string internal constant BORROW_RATE_TOO_HIGH = "E303";
    string internal constant INSUFFICIENT_TOKEN_CASH = "E304";
    string internal constant INSUFFICIENT_TOKENS_FOR_RELEASE = "E305";
    string internal constant INSUFFICIENT_MNT_FOR_GRANT = "E306";
    string internal constant TOKEN_TRANSFER_IN_UNDERFLOW = "E307";
    string internal constant NOT_PARTICIPATING_IN_BUYBACK = "E308";
    string internal constant NOT_ENOUGH_PARTICIPATING_ACCOUNTS = "E309";
    string internal constant NOTHING_TO_DISTRIBUTE = "E310";
    string internal constant ALREADY_PARTICIPATING_IN_BUYBACK = "E311";
    string internal constant MNT_APPROVE_FAILS = "E312";
    string internal constant TOO_EARLY_TO_DRIP = "E313";
    string internal constant BB_UNSTAKE_TOO_EARLY = "E314";
    string internal constant INSUFFICIENT_SHORTFALL = "E315";
    string internal constant HEALTHY_FACTOR_NOT_IN_RANGE = "E316";
    string internal constant BUYBACK_DRIPS_ALREADY_HAPPENED = "E317";
    string internal constant EB_INDEX_SHOULD_BE_GREATER_THAN_INITIAL = "E318";
    string internal constant NO_VESTING_SCHEDULES = "E319";
    string internal constant INSUFFICIENT_UNRELEASED_TOKENS = "E320";
    string internal constant ORACLE_PRICE_EXPIRED = "E321";
    string internal constant TOKEN_NOT_FOUND = "E322";
    string internal constant RECEIVED_PRICE_HAS_INVALID_ROUND = "E323";
    string internal constant FL_PULL_AMOUNT_IS_TOO_LOW = "E324";
    string internal constant INSUFFICIENT_TOTAL_PROTOCOL_INTEREST = "E325";
    string internal constant BB_ACCOUNT_RECENTLY_VOTED = "E326";
    string internal constant DD_SWAP_ROUTER_IS_ZERO = "E327";
    string internal constant DD_SWAP_CALL_FAILS = "E328";
    string internal constant LL_NEW_ROOT_CANNOT_BE_ZERO = "E329";

    // Invalid input - Admin functions
    string internal constant ZERO_EXCHANGE_RATE = "E401";
    string internal constant SECOND_INITIALIZATION = "E402";
    string internal constant MARKET_ALREADY_LISTED = "E403";
    string internal constant IDENTICAL_VALUE = "E404";
    string internal constant ZERO_ADDRESS = "E405";
    string internal constant EC_INVALID_PROVIDER_REPRESENTATIVE = "E406";
    string internal constant EC_PROVIDER_CANT_BE_REPRESENTATIVE = "E407";
    string internal constant OR_ORACLE_ADDRESS_CANNOT_BE_ZERO = "E408";
    string internal constant OR_UNDERLYING_TOKENS_DECIMALS_SHOULD_BE_GREATER_THAN_ZERO = "E409";
    string internal constant OR_REPORTER_MULTIPLIER_SHOULD_BE_GREATER_THAN_ZERO = "E410";
    string internal constant INVALID_TOKEN = "E411";
    string internal constant INVALID_PROTOCOL_INTEREST_FACTOR_MANTISSA = "E412";
    string internal constant INVALID_REDUCE_AMOUNT = "E413";
    string internal constant LIQUIDATION_FEE_MANTISSA_SHOULD_BE_GREATER_THAN_ZERO = "E414";
    string internal constant INVALID_UTILISATION_FACTOR_MANTISSA = "E415";
    string internal constant INVALID_MTOKENS_OR_BORROW_CAPS = "E416";
    string internal constant FL_PARAM_IS_TOO_LARGE = "E417";
    string internal constant MNT_INVALID_NONVOTING_PERIOD = "E418";
    string internal constant INPUT_ARRAY_LENGTHS_ARE_NOT_EQUAL = "E419";
    string internal constant EC_INVALID_BOOSTS = "E420";
    string internal constant EC_ACCOUNT_IS_ALREADY_LIQUIDITY_PROVIDER = "E421";
    string internal constant EC_ACCOUNT_HAS_NO_AGREEMENT = "E422";
    string internal constant OR_TIMESTAMP_THRESHOLD_SHOULD_BE_GREATER_THAN_ZERO = "E423";
    string internal constant OR_UNDERLYING_TOKENS_DECIMALS_TOO_BIG = "E424";
    string internal constant OR_REPORTER_MULTIPLIER_TOO_BIG = "E425";
    string internal constant SHOULD_HAVE_REVOCABLE_SCHEDULE = "E426";
    string internal constant MEMBER_NOT_IN_DELAY_LIST = "E427";
    string internal constant DELAY_LIST_LIMIT = "E428";
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

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

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @title Minterest InterestRateModel Interface
 * @author Minterest
 */
interface IInterestRateModel {
    /**
     * @notice Calculates the current borrow interest rate per block
     * @param cash The total amount of cash the market has
     * @param borrows The total amount of borrows the market has outstanding
     * @param protocolInterest The total amount of protocol interest the market has
     * @return The borrow rate per block (as a percentage, and scaled by 1e18)
     */
    function getBorrowRate(
        uint256 cash,
        uint256 borrows,
        uint256 protocolInterest
    ) external view returns (uint256);

    /**
     * @notice Calculates the current supply interest rate per block
     * @param cash The total amount of cash the market has
     * @param borrows The total amount of borrows the market has outstanding
     * @param protocolInterest The total amount of protocol interest the market has
     * @param protocolInterestFactorMantissa The current protocol interest factor the market has
     * @return The supply rate per block (as a percentage, and scaled by 1e18)
     */
    function getSupplyRate(
        uint256 cash,
        uint256 borrows,
        uint256 protocolInterest,
        uint256 protocolInterestFactorMantissa
    ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC3156FlashLender.sol)

pragma solidity ^0.8.0;

import "./IERC3156FlashBorrower.sol";

/**
 * @dev Interface of the ERC3156 FlashLender, as defined in
 * https://eips.ethereum.org/EIPS/eip-3156[ERC-3156].
 *
 * _Available since v4.1._
 */
interface IERC3156FlashLender {
    /**
     * @dev The amount of currency available to be lended.
     * @param token The loan currency.
     * @return The amount of `token` that can be borrowed.
     */
    function maxFlashLoan(address token) external view returns (uint256);

    /**
     * @dev The fee to be charged for a given loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @return The amount of `token` to be charged for the loan, on top of the returned principal.
     */
    function flashFee(address token, uint256 amount) external view returns (uint256);

    /**
     * @dev Initiate a flash loan.
     * @param receiver The receiver of the tokens in the loan, and the receiver of the callback.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     */
    function flashLoan(
        IERC3156FlashBorrower receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (interfaces/IERC3156FlashBorrower.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC3156 FlashBorrower, as defined in
 * https://eips.ethereum.org/EIPS/eip-3156[ERC-3156].
 *
 * _Available since v4.1._
 */
interface IERC3156FlashBorrower {
    /**
     * @dev Receive a flash loan.
     * @param initiator The initiator of the loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param fee The additional amount of tokens to repay.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     * @return The keccak256 hash of "IERC3156FlashBorrower.onFlashLoan"
     */
    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bytes32);
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.17;
import "./IMToken.sol";

interface IPriceOracle {
    /**
     * @notice Get the underlying price of a mToken asset
     * @param mToken The mToken to get the underlying price of
     * @return The underlying asset price mantissa (scaled by 1e18).
     *  Zero means the price is unavailable.
     *
     * @dev Price should be scaled to 1e18 for tokens with tokenDecimals = 1e18
     *      and for 1e30 for tokens with tokenDecimals = 1e6.
     */
    function getUnderlyingPrice(IMToken mToken) external view returns (uint256);

    /**
     * @notice Return price for an asset
     * @param asset address of token
     * @return The underlying asset price mantissa (scaled by 1e18).
     *  Zero means the price is unavailable.
     * @dev Price should be scaled to 1e18 for tokens with tokenDecimals = 1e18
     *      and for 1e30 for tokens with tokenDecimals = 1e6.
     */
    function getAssetPrice(address asset) external view returns (uint256);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}