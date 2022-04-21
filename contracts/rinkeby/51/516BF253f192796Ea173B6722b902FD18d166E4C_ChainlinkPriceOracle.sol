// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.9;

import "./AggregatorV3Interface.sol";
import "../MToken.sol";
import "./PriceOracle.sol";
import "../MToken.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract ChainlinkPriceOracle is PriceOracle, AccessControl {
    event NewTimestampThreshold(uint256 oldTimestampThreshold, uint256 newTimestampThreshold);

    /// @notice Structure to store oracle related data for the token
    struct TokenConfig {
        // Chainlink oracle interface for current token
        AggregatorV3Interface chainlinkAggregator;
        // Original token decimals
        uint256 underlyingTokenDecimals;
        // Const for price converting
        uint256 reporterMultiplier;
    }

    /// @dev max threshold for oracle validation
    uint256 private timestampThreshold;

    /// @dev Mapping to store oracle related configuration for tokens
    mapping(address => TokenConfig) private feedProxies;

    /**
     * @notice Construct a ChainlinkPriceOracle contract.
     * @param admin The address of the Admin
     * @param threshold threshold for oracle reporter timestamp
     */
    constructor(address admin, uint256 threshold) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        timestampThreshold = threshold;
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
        uint256 convertedPrice = (unsignedPrice * config.reporterMultiplier) / config.underlyingTokenDecimals;
        return convertedPrice;
    }

    /**
     * @notice Get the underlying price of a mToken asset
     * @param mToken The mToken to get the underlying price of
     * @return The underlying asset price mantissa (scaled by 1e18).
     *  Zero means the price is unavailable.
     *
     * @dev Price should be scaled to 1e18 for tokens with tokenDecimals = 1e18
     *      and for 1e30 for tokens with tokenDecimals = 1e6.
     */
    function getUnderlyingPrice(MToken mToken) external view override returns (uint256) {
        require(address(mToken) != address(0), ErrorCodes.MTOKEN_ADDRESS_CANNOT_BE_ZERO);
        return getAssetPrice(address(mToken.underlying()));
    }

    /**
     * @notice Return price for an asset
     * @param asset address of token
     * @return The underlying asset price mantissa (scaled by 1e18).
     *  Zero means the price is unavailable.
     * @dev Price should be scaled to 1e18 for tokens with tokenDecimals = 1e18
     *      and for 1e30 for tokens with tokenDecimals = 1e6.
     */
    function getAssetPrice(address asset) public view returns (uint256) {
        require(address(asset) != address(0), ErrorCodes.TOKEN_ADDRESS_CANNOT_BE_ZERO);

        TokenConfig memory config = feedProxies[address(asset)];
        require(config.chainlinkAggregator != AggregatorV3Interface(address(0)), ErrorCodes.TOKEN_NOT_FOUND);

        // prettier-ignore
        (
            uint80 roundId,
            int256 answer,
            ,
            uint256 updatedAt,
            uint80 answeredInRound
        ) = config.chainlinkAggregator.latestRoundData();

        // solhint-disable-next-line not-rely-on-time
        require(block.timestamp - updatedAt <= timestampThreshold, ErrorCodes.ORACLE_PRICE_EXPIRED);
        require(answeredInRound == roundId, ErrorCodes.RECEIVED_PRICE_HAS_INVALID_ROUND);

        uint256 convertedPrice = convertReportedPrice(config, answer);
        return (convertedPrice * 1e28) / config.underlyingTokenDecimals;
    }

    /**
     * @notice Set the proxy of a underlying asset
     * @param token The underlying to set the price oracle proxy of
     * @param oracleAddress Address of corresponding oracle
     * @param underlyingTokenDecimals Original token decimals
     * @param reporterMultiplier Constant, using for decimal cast from decimals,
                                  returned by oracle to required decimals.
     * @dev reporterMultiplier = 8 + underlyingDecimals - feedDecimals
     */
    function setTokenConfig(
        address token,
        address oracleAddress,
        uint256 underlyingTokenDecimals,
        uint256 reporterMultiplier
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(address(token) != address(0), ErrorCodes.TOKEN_ADDRESS_CANNOT_BE_ZERO);
        require(oracleAddress != address(0), ErrorCodes.ORACLE_ADDRESS_CANNOT_BE_ZERO);
        require(underlyingTokenDecimals > 0, ErrorCodes.UNDERLYING_TOKENS_DECIMALS_SHOULD_BE_GREATER_THAN_ZERO);
        require(reporterMultiplier > 0, ErrorCodes.REPORTER_MULTIPLIER_SHOULD_BE_GREATER_THAN_ZERO);

        feedProxies[address(token)] = TokenConfig(
            AggregatorV3Interface(oracleAddress),
            underlyingTokenDecimals,
            reporterMultiplier
        );
    }

    /**
     * @notice Set new timestampThreshold value
     * @param threshold new timestampThreshold value
     */
    function setTimestampThreshold(uint256 threshold) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 oldTimestampThreshold = timestampThreshold;
        timestampThreshold = threshold;
        emit NewTimestampThreshold(oldTimestampThreshold, timestampThreshold);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

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

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";

import "./SupervisorInterface.sol";
import "./MTokenInterfaces.sol";
import "./InterestRateModel.sol";
import "./ErrorCodes.sol";

/**
 * @title Minterest MToken Contract
 * @notice Abstract base for MTokens
 * @author Minterest
 */
contract MToken is MTokenInterface, MTokenStorage {
    using SafeERC20 for IERC20;
    using SafeCast for uint256;

    /**
     * @notice Initialize the money market
     * @param supervisor_ The address of the Supervisor
     * @param interestRateModel_ The address of the interest rate model
     * @param initialExchangeRateMantissa_ The initial exchange rate, scaled by 1e18
     * @param name_ EIP-20 name of this token
     * @param symbol_ EIP-20 symbol of this token
     * @param decimals_ EIP-20 decimal precision of this token
     * @param underlying_ The address of the underlying asset
     */
    function initialize(
        address admin_,
        SupervisorInterface supervisor_,
        InterestRateModel interestRateModel_,
        uint256 initialExchangeRateMantissa_,
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        IERC20 underlying_
    ) external {
        //slither-disable-next-line incorrect-equality
        require(accrualBlockNumber == 0 && borrowIndex == 0, ErrorCodes.SECOND_INITIALIZATION);

        // Set initial exchange rate
        require(initialExchangeRateMantissa_ > 0, ErrorCodes.ZERO_EXCHANGE_RATE);
        initialExchangeRateMantissa = initialExchangeRateMantissa_;

        // Set the supervisor
        _setSupervisor(supervisor_);

        // Initialize block number and borrow index (block number mocks depend on supervisor being set)
        accrualBlockNumber = getBlockNumber();
        borrowIndex = EXP_SCALE; // = 1e18

        // Set the interest rate model (depends on block number / borrow index)
        setInterestRateModelFresh(interestRateModel_);

        _grantRole(DEFAULT_ADMIN_ROLE, admin_);
        _grantRole(TIMELOCK, admin_);

        underlying = underlying_;
        name = name_;
        symbol = symbol_;
        decimals = decimals_;

        maxFlashLoanShare = 0.9e18; // 90%
        flashLoanFeeShare = 0.0001e18; // 0.01%
    }

    function totalSupply() external view override returns (uint256) {
        return totalTokenSupply;
    }

    /**
     * @notice Transfer `tokens` tokens from `src` to `dst` by `spender`
     * @dev Called by both `transfer` and `transferFrom` internally
     * @param spender The address of the account performing the transfer
     * @param src The address of the source account
     * @param dst The address of the destination account
     * @param tokens The number of tokens to transfer
     */
    //slither-disable-next-line reentrancy-benign
    function transferTokens(
        address spender,
        address src,
        address dst,
        uint256 tokens
    ) internal {
        /* Do not allow self-transfers */
        require(src != dst, ErrorCodes.INVALID_DESTINATION);

        /* Fail if transfer not allowed */
        //slither-disable-next-line reentrancy-events
        supervisor.beforeTransfer(address(this), src, dst, tokens);

        /* Get the allowance, infinite for the account owner */
        uint256 startingAllowance = 0;
        if (spender == src) {
            startingAllowance = type(uint256).max;
        } else {
            startingAllowance = transferAllowances[src][spender];
        }

        /////////////////////////
        // EFFECTS & INTERACTIONS

        accountTokens[src] -= tokens;
        accountTokens[dst] += tokens;

        if (startingAllowance != type(uint256).max) {
            transferAllowances[src][spender] = startingAllowance - tokens;
        }

        emit Transfer(src, dst, tokens);
    }

    /**
     * @notice Transfer `amount` tokens from `msg.sender` to `dst`
     * @param dst The address of the destination account
     * @param amount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transfer(address dst, uint256 amount) external override nonReentrant returns (bool) {
        transferTokens(msg.sender, msg.sender, dst, amount);
        return true;
    }

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
    ) external override nonReentrant returns (bool) {
        transferTokens(msg.sender, src, dst, amount);
        return true;
    }

    /**
     * @notice Approve `spender` to transfer up to `amount` from `src`
     * @dev This will overwrite the approval amount for `spender`
     *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
     * @param spender The address of the account which may transfer tokens
     * @param amount The number of tokens that are approved (-1 means infinite)
     * @return Whether or not the approval succeeded
     */
    function approve(address spender, uint256 amount) external override returns (bool) {
        address src = msg.sender;
        transferAllowances[src][spender] = amount;
        emit Approval(src, spender, amount);
        return true;
    }

    /**
     * @notice Get the current allowance from `owner` for `spender`
     * @param owner The address of the account which owns the tokens to be spent
     * @param spender The address of the account which may transfer tokens
     * @return The number of tokens allowed to be spent (-1 means infinite)
     */
    function allowance(address owner, address spender) external view override returns (uint256) {
        return transferAllowances[owner][spender];
    }

    /**
     * @notice Get the token balance of the `owner`
     * @param owner The address of the account to query
     * @return The number of tokens owned by `owner`
     */
    function balanceOf(address owner) external view override returns (uint256) {
        return accountTokens[owner];
    }

    /**
     * @notice Get the underlying balance of the `owner`
     * @dev This also accrues interest in a transaction
     * @param owner The address of the account to query
     * @return The amount of underlying owned by `owner`
     */
    function balanceOfUnderlying(address owner) external override returns (uint256) {
        return (accountTokens[owner] * exchangeRateCurrent()) / EXP_SCALE;
    }

    /**
     * @notice Get a snapshot of the account's balances, and the cached exchange rate
     * @dev This is used by supervisor to more efficiently perform liquidity checks.
     * @param account Address of the account to snapshot
     * @return (token balance, borrow balance, exchange rate mantissa)
     */
    function getAccountSnapshot(address account)
        external
        view
        override
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 mTokenBalance = accountTokens[account];
        uint256 borrowBalance = borrowBalanceStoredInternal(account);
        uint256 exchangeRateMantissa = exchangeRateStoredInternal();
        return (mTokenBalance, borrowBalance, exchangeRateMantissa);
    }

    /**
     * @dev Function to simply retrieve block number
     *  This exists mainly for inheriting test contracts to stub this result.
     */
    //slither-disable-next-line dead-code
    function getBlockNumber() internal view virtual returns (uint256) {
        return block.number;
    }

    /**
     * @notice Returns the current per-block borrow interest rate for this mToken
     * @return The borrow interest rate per block, scaled by 1e18
     */
    function borrowRatePerBlock() external view override returns (uint256) {
        return interestRateModel.getBorrowRate(getCashPrior(), totalBorrows, totalProtocolInterest);
    }

    /**
     * @notice Returns the current per-block supply interest rate for this mToken
     * @return The supply interest rate per block, scaled by 1e18
     */
    function supplyRatePerBlock() external view override returns (uint256) {
        return
            interestRateModel.getSupplyRate(
                getCashPrior(),
                totalBorrows,
                totalProtocolInterest,
                protocolInterestFactorMantissa
            );
    }

    /**
     * @notice Returns the current total borrows plus accrued interest
     * @return The total borrows with interest
     */
    function totalBorrowsCurrent() external override nonReentrant returns (uint256) {
        accrueInterest();
        return totalBorrows;
    }

    /**
     * @notice Accrue interest to updated borrowIndex and then calculate account's
     *         borrow balance using the updated borrowIndex
     * @param account The address whose balance should be calculated after updating borrowIndex
     * @return The calculated balance
     */
    function borrowBalanceCurrent(address account) external override nonReentrant returns (uint256) {
        accrueInterest();
        return borrowBalanceStored(account);
    }

    /**
     * @notice Return the borrow balance of account based on stored data
     * @param account The address whose balance should be calculated
     * @return The calculated balance
     */
    function borrowBalanceStored(address account) public view override returns (uint256) {
        return borrowBalanceStoredInternal(account);
    }

    /**
     * @notice Return the borrow balance of account based on stored data
     * @param account The address whose balance should be calculated
     * @return the calculated balance
     */
    function borrowBalanceStoredInternal(address account) internal view returns (uint256) {
        /* Get borrowBalance and borrowIndex */
        BorrowSnapshot storage borrowSnapshot = accountBorrows[account];

        /* If borrowBalance = 0 then borrowIndex is likely also 0.
         * Rather than failing the calculation with a division by 0, we immediately return 0 in this case.
         */
        if (borrowSnapshot.principal == 0) return 0;

        /* Calculate new borrow balance using the interest index:
         *  recentBorrowBalance = borrower.borrowBalance * market.borrowIndex / borrower.borrowIndex
         */
        return (borrowSnapshot.principal * borrowIndex) / borrowSnapshot.interestIndex;
    }

    /**
     * @notice Accrue interest then return the up-to-date exchange rate
     * @return Calculated exchange rate scaled by 1e18
     */
    function exchangeRateCurrent() public override nonReentrant returns (uint256) {
        accrueInterest();
        return exchangeRateStored();
    }

    /**
     * @notice Calculates the exchange rate from the underlying to the MToken
     * @dev This function does not accrue interest before calculating the exchange rate
     * @return Calculated exchange rate scaled by 1e18
     */
    function exchangeRateStored() public view override returns (uint256) {
        return exchangeRateStoredInternal();
    }

    /**
     * @notice Calculates the exchange rate from the underlying to the MToken
     * @dev This function does not accrue interest before calculating the exchange rate
     * @return calculated exchange rate scaled by 1e18
     */
    function exchangeRateStoredInternal() internal view virtual returns (uint256) {
        if (totalTokenSupply <= 0) {
            /*
             * If there are no tokens lent:
             *  exchangeRate = initialExchangeRate
             */
            return initialExchangeRateMantissa;
        } else {
            /*
             * Otherwise:
             *  exchangeRate = (totalCash + totalBorrows - totalProtocolInterest) / totalTokenSupply
             */
            return ((getCashPrior() + totalBorrows - totalProtocolInterest) * EXP_SCALE) / totalTokenSupply;
        }
    }

    /**
     * @notice Get cash balance of this mToken in the underlying asset
     * @return The quantity of underlying asset owned by this contract
     */
    function getCash() external view override returns (uint256) {
        return getCashPrior();
    }

    /**
     * @notice Applies accrued interest to total borrows and protocol interest
     * @dev This calculates interest accrued from the last checkpointed block
     *   up to the current block and writes new checkpoint to storage.
     */
    function accrueInterest() public virtual override {
        /* Remember the initial block number */
        uint256 currentBlockNumber = getBlockNumber();
        uint256 accrualBlockNumberPrior = accrualBlockNumber;

        /* Short-circuit accumulating 0 interest */
        if (accrualBlockNumberPrior == currentBlockNumber) return;

        /* Read the previous values out of storage */
        uint256 cashPrior = getCashPrior();
        uint256 borrowIndexPrior = borrowIndex;

        /* Calculate the current borrow interest rate */
        uint256 borrowRateMantissa = interestRateModel.getBorrowRate(cashPrior, totalBorrows, totalProtocolInterest);
        require(borrowRateMantissa <= borrowRateMaxMantissa, ErrorCodes.BORROW_RATE_TOO_HIGH);

        /* Calculate the number of blocks elapsed since the last accrual */
        uint256 blockDelta = currentBlockNumber - accrualBlockNumberPrior;

        /*
         * Calculate the interest accumulated into borrows and protocol interest and the new index:
         *  simpleInterestFactor = borrowRate * blockDelta
         *  interestAccumulated = simpleInterestFactor * totalBorrows
         *  totalBorrows += interestAccumulated
         *  totalProtocolInterest += interestAccumulated * protocolInterestFactor
         *  borrowIndex = simpleInterestFactor * borrowIndex + borrowIndex
         */
        uint256 simpleInterestFactor = borrowRateMantissa * blockDelta;
        uint256 interestAccumulated = (totalBorrows * simpleInterestFactor) / EXP_SCALE;
        totalBorrows += interestAccumulated;
        totalProtocolInterest += (interestAccumulated * protocolInterestFactorMantissa) / EXP_SCALE;
        borrowIndex = borrowIndexPrior + (borrowIndexPrior * simpleInterestFactor) / EXP_SCALE;

        accrualBlockNumber = currentBlockNumber;

        emit AccrueInterest(cashPrior, interestAccumulated, borrowIndex, totalBorrows, totalProtocolInterest);
    }

    /**
     * @notice Sender supplies assets into the market and receives mTokens in exchange
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param lendAmount The amount of the underlying asset to supply
     */
    function lend(uint256 lendAmount) external override {
        accrueInterest();
        lendFresh(msg.sender, lendAmount);
    }

    /**
     * @notice Account supplies assets into the market and receives mTokens in exchange
     * @dev Assumes interest has already been accrued up to the current block
     * @param lender The address of the account which is supplying the assets
     * @param lendAmount The amount of the underlying asset to supply
     * @return actualLendAmount actual lend amount
     */
    function lendFresh(address lender, uint256 lendAmount) internal nonReentrant returns (uint256 actualLendAmount) {
        uint256 wrapBalance = accountTokens[lender];
        supervisor.beforeLend(address(this), lender, wrapBalance);

        /* Verify market's block number equals current block number */
        require(accrualBlockNumber == getBlockNumber(), ErrorCodes.MARKET_NOT_FRESH);

        uint256 exchangeRateMantissa = exchangeRateStoredInternal();

        /*
         *  We call `doTransferIn` for the lender and the lendAmount.
         *  Note: The mToken must handle variations between ERC-20 underlying.
         *  `doTransferIn` reverts if anything goes wrong, since we can't be sure if
         *  side-effects occurred. The function returns the amount actually transferred,
         *  in case of a fee. On success, the mToken holds an additional `actualLendAmount`
         *  of cash.
         */
        // slither-disable-next-line reentrancy-eth
        actualLendAmount = doTransferIn(lender, lendAmount);

        /*
         * We get the current exchange rate and calculate the number of mTokens to be lent:
         *  lendTokens = actualLendAmount / exchangeRate
         */
        uint256 lendTokens = (actualLendAmount * EXP_SCALE) / exchangeRateMantissa;

        /*
         * We calculate the new total supply of mTokens and lender token balance, checking for overflow:
         *  totalTokenSupply = totalTokenSupply + lendTokens
         *  accountTokens = accountTokens[lender] + lendTokens
         */
        uint256 newTotalTokenSupply = totalTokenSupply + lendTokens;
        totalTokenSupply = newTotalTokenSupply;
        accountTokens[lender] = wrapBalance + lendTokens;

        emit Lend(lender, actualLendAmount, lendTokens, newTotalTokenSupply);
        emit Transfer(address(this), lender, lendTokens);
    }

    /**
     * @notice Sender redeems mTokens in exchange for the underlying asset
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param redeemTokens The number of mTokens to redeem into underlying
     */
    function redeem(uint256 redeemTokens) external override {
        accrueInterest();
        redeemFresh(msg.sender, redeemTokens, 0);
    }

    /**
     * @notice Sender redeems mTokens in exchange for a specified amount of underlying asset
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param redeemAmount The amount of underlying to receive from redeeming mTokens
     */
    function redeemUnderlying(uint256 redeemAmount) external override {
        accrueInterest();
        redeemFresh(msg.sender, 0, redeemAmount);
    }

    /**
     * @notice Account redeems mTokens in exchange for the underlying asset
     * @dev Assumes interest has already been accrued up to the current block
     * @param redeemer The address of the account which is redeeming the tokens
     * @param redeemTokens The number of mTokens to redeem into underlying
     *                       (only one of redeemTokensIn or redeemAmountIn may be non-zero)
     * @param redeemAmount The number of underlying tokens to receive from redeeming mTokens
     *                       (only one of redeemTokensIn or redeemAmountIn may be non-zero)
     */
    //slither-disable-next-line reentrancy-no-eth
    function redeemFresh(
        address redeemer,
        uint256 redeemTokens,
        uint256 redeemAmount
    ) internal nonReentrant {
        require(redeemTokens == 0 || redeemAmount == 0, ErrorCodes.REDEEM_TOKENS_OR_REDEEM_AMOUNT_MUST_BE_ZERO);

        /* exchangeRate = invoke Exchange Rate Stored() */
        uint256 exchangeRateMantissa = exchangeRateStoredInternal();

        if (redeemTokens > 0) {
            /*
             * We calculate the exchange rate and the amount of underlying to be redeemed:
             *  redeemTokens = redeemTokens
             *  redeemAmount = redeemTokens * exchangeRateCurrent
             */
            redeemAmount = (redeemTokens * exchangeRateMantissa) / EXP_SCALE;
        } else {
            /*
             * We get the current exchange rate and calculate the amount to be redeemed:
             *  redeemTokens = redeemAmount / exchangeRate
             *  redeemAmount = redeemAmount
             */
            redeemTokens = (redeemAmount * EXP_SCALE) / exchangeRateMantissa;
        }

        /* Fail if redeem not allowed */
        //slither-disable-next-line reentrancy-benign
        supervisor.beforeRedeem(address(this), redeemer, redeemTokens);

        /* Verify market's block number equals current block number */
        require(accrualBlockNumber == getBlockNumber(), ErrorCodes.MARKET_NOT_FRESH);
        require(accountTokens[redeemer] >= redeemTokens, ErrorCodes.REDEEM_TOO_MUCH);
        require(totalTokenSupply >= redeemTokens, ErrorCodes.INVALID_REDEEM);

        /*
         * We calculate the new total supply and redeemer balance, checking for underflow:
         *  accountTokensNew = accountTokens[redeemer] - redeemTokens
         *  totalSupplyNew = totalTokenSupply - redeemTokens
         */
        uint256 accountTokensNew = accountTokens[redeemer] - redeemTokens;
        uint256 totalSupplyNew = totalTokenSupply - redeemTokens;

        /* Fail gracefully if protocol has insufficient cash */
        require(getCashPrior() >= redeemAmount, ErrorCodes.INSUFFICIENT_TOKEN_CASH);

        totalTokenSupply = totalSupplyNew;
        accountTokens[redeemer] = accountTokensNew;

        //slither-disable-next-line reentrancy-events
        emit Transfer(redeemer, address(this), redeemTokens);
        emit Redeem(redeemer, redeemAmount, redeemTokens, totalSupplyNew);

        doTransferOut(redeemer, redeemAmount);

        /* We call the defense hook */
        supervisor.redeemVerify(redeemAmount, redeemTokens);
    }

    /**
     * @notice Sender borrows assets from the protocol to their own address
     * @param borrowAmount The amount of the underlying asset to borrow
     */

    //slither-disable-next-line reentrancy-no-eth, reentrancy-benign
    function borrow(uint256 borrowAmount) external override nonReentrant {
        accrueInterest();

        address borrower = msg.sender;

        /* Fail if borrow not allowed */
        //slither-disable-next-line reentrancy-benign
        supervisor.beforeBorrow(address(this), borrower, borrowAmount);

        /* Fail gracefully if protocol has insufficient underlying cash */
        require(getCashPrior() >= borrowAmount, ErrorCodes.INSUFFICIENT_TOKEN_CASH);

        /*
         * We calculate the new borrower and total borrow balances, failing on overflow:
         *  accountBorrowsNew = accountBorrows + borrowAmount
         *  totalBorrowsNew = totalBorrows + borrowAmount
         */
        uint256 accountBorrowsNew = borrowBalanceStoredInternal(borrower) + borrowAmount;
        uint256 totalBorrowsNew = totalBorrows + borrowAmount;

        accountBorrows[borrower].principal = accountBorrowsNew;
        accountBorrows[borrower].interestIndex = borrowIndex;
        totalBorrows = totalBorrowsNew;

        //slither-disable-next-line reentrancy-events
        emit Borrow(borrower, borrowAmount, accountBorrowsNew, totalBorrowsNew);

        doTransferOut(borrower, borrowAmount);
    }

    /**
     * @notice Sender repays their own borrow
     * @param repayAmount The amount to repay
     */
    function repayBorrow(uint256 repayAmount) external override {
        accrueInterest();
        repayBorrowFresh(msg.sender, msg.sender, repayAmount);
    }

    /**
     * @notice Sender repays a borrow belonging to borrower
     * @param borrower the account with the debt being payed off
     * @param repayAmount The amount to repay
     */
    function repayBorrowBehalf(address borrower, uint256 repayAmount) external override {
        accrueInterest();
        repayBorrowFresh(msg.sender, borrower, repayAmount);
    }

    /**
     * @notice Borrows are repaid by another account (possibly the borrower).
     * @param payer the account paying off the borrow
     * @param borrower the account with the debt being payed off
     * @param repayAmount the amount of underlying tokens being returned
     * @return actualRepayAmount the actual repayment amount
     */
    function repayBorrowFresh(
        address payer,
        address borrower,
        uint256 repayAmount
    ) internal nonReentrant returns (uint256 actualRepayAmount) {
        /* Fail if repayBorrow not allowed */
        supervisor.beforeRepayBorrow(address(this), borrower);

        /* Verify market's block number equals current block number */
        require(accrualBlockNumber == getBlockNumber(), ErrorCodes.MARKET_NOT_FRESH);

        /* We fetch the amount the borrower owes, with accumulated interest */
        uint256 borrowBalance = borrowBalanceStoredInternal(borrower);

        if (repayAmount == type(uint256).max) {
            repayAmount = borrowBalance;
        }

        /////////////////////////
        // EFFECTS & INTERACTIONS

        /*
         * We call doTransferIn for the payer and the repayAmount
         *  Note: The mToken must handle variations between ERC-20 and ETH underlying.
         *  On success, the mToken holds an additional repayAmount of cash.
         *  doTransferIn reverts if anything goes wrong, since we can't be sure if side effects occurred.
         *   it returns the amount actually transferred, in case of a fee.
         */
        // slither-disable-next-line reentrancy-eth
        actualRepayAmount = doTransferIn(payer, repayAmount);

        /*
         * We calculate the new borrower and total borrow balances, failing on underflow:
         *  accountBorrowsNew = accountBorrows - actualRepayAmount
         *  totalBorrowsNew = totalBorrows - actualRepayAmount
         */
        uint256 accountBorrowsNew = borrowBalance - actualRepayAmount;
        uint256 totalBorrowsNew = totalBorrows - actualRepayAmount;

        accountBorrows[borrower].principal = accountBorrowsNew;
        accountBorrows[borrower].interestIndex = borrowIndex;
        totalBorrows = totalBorrowsNew;

        emit RepayBorrow(payer, borrower, actualRepayAmount, accountBorrowsNew, totalBorrowsNew);
    }

    /**
     * @notice Liquidator repays a borrow belonging to borrower
     * @param borrower_ the account with the debt being payed off
     * @param repayAmount_ the amount of underlying tokens being returned
     */
    function autoLiquidationRepayBorrow(address borrower_, uint256 repayAmount_) external override nonReentrant {
        // Fail if repayBorrow not allowed
        //slither-disable-next-line reentrancy-benign
        supervisor.beforeAutoLiquidationRepay(msg.sender, borrower_, address(this), borrowIndex.toUint224());

        // Verify market's block number equals current block number
        require(accrualBlockNumber == getBlockNumber(), ErrorCodes.MARKET_NOT_FRESH);
        require(totalProtocolInterest >= repayAmount_, ErrorCodes.INSUFFICIENT_TOTAL_PROTOCOL_INTEREST);

        // We fetch the amount the borrower owes, with accumulated interest
        uint256 borrowBalance = borrowBalanceStoredInternal(borrower_);

        accountBorrows[borrower_].principal = borrowBalance - repayAmount_;
        accountBorrows[borrower_].interestIndex = borrowIndex;
        totalBorrows -= repayAmount_;
        totalProtocolInterest -= repayAmount_;

        //slither-disable-next-line reentrancy-events
        emit AutoLiquidationRepayBorrow(
            borrower_,
            repayAmount_,
            accountBorrows[borrower_].principal,
            totalBorrows,
            totalProtocolInterest
        );
    }

    /**
     * @notice A public function to sweep accidental ERC-20 transfers to this contract.
     *         Tokens are sent to admin (timelock)
     * @param token The address of the ERC-20 token to sweep
     */
    function sweepToken(IERC20 token, address receiver_) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        require(token != underlying, ErrorCodes.INVALID_TOKEN);
        uint256 balance = token.balanceOf(address(this));
        token.safeTransfer(receiver_, balance);
    }

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
    //slither-disable-next-line reentrancy-benign
    function autoLiquidationSeize(
        address borrower_,
        uint256 seizeUnderlyingAmount_,
        bool isLoanInsignificant_,
        address receiver_
    ) external nonReentrant {
        //slither-disable-next-line reentrancy-events
        supervisor.beforeAutoLiquidationSeize(address(this), msg.sender, borrower_);

        uint256 exchangeRateMantissa = exchangeRateStoredInternal();

        uint256 borrowerSeizeTokens;

        // Infinity means all account's collateral has to be burn.
        if (seizeUnderlyingAmount_ == type(uint256).max) {
            borrowerSeizeTokens = accountTokens[borrower_];
            seizeUnderlyingAmount_ = (borrowerSeizeTokens * exchangeRateMantissa) / EXP_SCALE;
        } else {
            borrowerSeizeTokens = (seizeUnderlyingAmount_ * EXP_SCALE) / exchangeRateMantissa;
        }

        uint256 borrowerTokensNew = accountTokens[borrower_] - borrowerSeizeTokens;
        uint256 totalSupplyNew = totalTokenSupply - borrowerSeizeTokens;

        /////////////////////////
        // EFFECTS & INTERACTIONS

        accountTokens[borrower_] = borrowerTokensNew;
        totalTokenSupply = totalSupplyNew;

        if (isLoanInsignificant_) {
            totalProtocolInterest = totalProtocolInterest + seizeUnderlyingAmount_;
            emit ProtocolInterestAdded(msg.sender, seizeUnderlyingAmount_, totalProtocolInterest);
        } else {
            doTransferOut(receiver_, seizeUnderlyingAmount_);
        }

        emit Seize(
            borrower_,
            receiver_,
            borrowerSeizeTokens,
            borrowerTokensNew,
            totalSupplyNew,
            seizeUnderlyingAmount_,
            address(this)
        );
    }

    /*** Flash loans ***/

    /**
     * @dev The amount of currency available to be lent.
     * @param token The loan currency.
     * @return The amount of `token` that can be borrowed.
     */
    function maxFlashLoan(address token) external view override returns (uint256) {
        return token == address(underlying) ? _maxFlashLoan() : 0;
    }

    function _maxFlashLoan() internal view returns (uint256) {
        return (getCashPrior() * maxFlashLoanShare) / EXP_SCALE;
    }

    /**
     * @dev The fee to be charged for a given loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @return The amount of `token` to be charged for the loan, on top of the returned principal.
     */
    function flashFee(address token, uint256 amount) external view override returns (uint256) {
        require(token == address(underlying), ErrorCodes.FL_TOKEN_IS_NOT_UNDERLYING);
        return _flashFee(amount);
    }

    function _flashFee(uint256 amount) internal view returns (uint256) {
        return (amount * flashLoanFeeShare) / EXP_SCALE;
    }

    /**
     * @dev Initiate a flash loan.
     * @param receiver The receiver of the tokens in the loan, and the receiver of the callback.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     */
    // slither-disable-next-line reentrancy-benign
    function flashLoan(
        IERC3156FlashBorrower receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) external override nonReentrant returns (bool) {
        require(token == address(underlying), ErrorCodes.FL_TOKEN_IS_NOT_UNDERLYING);
        require(amount <= _maxFlashLoan(), ErrorCodes.FL_AMOUNT_IS_TOO_LARGE);

        accrueInterest();

        // Make supervisor checks
        uint256 fee = _flashFee(amount);
        supervisor.beforeFlashLoan(address(this), address(receiver), amount, fee);

        // Transfer lend amount to receiver and call its callback
        underlying.safeTransfer(address(receiver), amount);
        require(
            receiver.onFlashLoan(msg.sender, token, amount, fee, data) == FLASH_LOAN_SUCCESS,
            ErrorCodes.FL_CALLBACK_FAILED
        );

        // Transfer amount + fee back and check that everything was returned by token
        uint256 actualPullAmount = doTransferIn(address(receiver), amount + fee);
        require(actualPullAmount >= amount + fee, ErrorCodes.FL_PULL_AMOUNT_IS_TOO_LOW);

        // Fee is the protocol interest so we increase it
        totalProtocolInterest += fee;

        emit FlashLoanExecuted(address(receiver), amount, fee);

        return true;
    }

    /*** Admin Functions ***/

    /**
     * @notice Sets a new supervisor for the market
     * @dev Admin function to set a new supervisor
     */
    function setSupervisor(SupervisorInterface newSupervisor) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        _setSupervisor(newSupervisor);
    }

    function _setSupervisor(SupervisorInterface newSupervisor) internal {
        require(
            newSupervisor.supportsInterface(type(SupervisorInterface).interfaceId),
            ErrorCodes.CONTRACT_DOES_NOT_SUPPORT_INTERFACE
        );

        SupervisorInterface oldSupervisor = supervisor;
        supervisor = newSupervisor;
        emit NewSupervisor(oldSupervisor, newSupervisor);
    }

    /**
     * @notice accrues interest and sets a new protocol interest factor for the protocol
     * @dev Admin function to accrue interest and set a new protocol interest factor
     */
    function setProtocolInterestFactor(uint256 newProtocolInterestFactorMantissa)
        external
        override
        onlyRole(TIMELOCK)
        nonReentrant
    {
        // Check newProtocolInterestFactor ≤ maxProtocolInterestFactor
        require(
            newProtocolInterestFactorMantissa <= protocolInterestFactorMaxMantissa,
            ErrorCodes.INVALID_PROTOCOL_INTEREST_FACTOR_MANTISSA
        );

        accrueInterest();

        uint256 oldProtocolInterestFactorMantissa = protocolInterestFactorMantissa;
        protocolInterestFactorMantissa = newProtocolInterestFactorMantissa;

        emit NewProtocolInterestFactor(oldProtocolInterestFactorMantissa, newProtocolInterestFactorMantissa);
    }

    /**
     * @notice Accrues interest and increase protocol interest by transferring from msg.sender
     * @param addAmount_ Amount of addition to protocol interest
     */
    function addProtocolInterest(uint256 addAmount_) external override nonReentrant {
        accrueInterest();
        addProtocolInterestInternal(msg.sender, addAmount_);
    }

    /**
     * @notice Can only be called by liquidation contract. Increase protocol interest by transferring from payer.
     * @dev Calling code should make sure that accrueInterest() was called before.
     * @param payer_ The address from which the protocol interest will be transferred
     * @param addAmount_ Amount of addition to protocol interest
     */
    function addProtocolInterestBehalf(address payer_, uint256 addAmount_) external override nonReentrant {
        supervisor.isLiquidator(msg.sender);
        addProtocolInterestInternal(payer_, addAmount_);
    }

    /**
     * @notice Accrues interest and increase protocol interest by transferring from payer_
     * @param payer_ The address from which the protocol interest will be transferred
     * @param addAmount_ Amount of addition to protocol interest
     */
    function addProtocolInterestInternal(address payer_, uint256 addAmount_) internal {
        // Verify market's block number equals current block number
        require(accrualBlockNumber == getBlockNumber(), ErrorCodes.MARKET_NOT_FRESH);

        /*
         * We call doTransferIn for the caller and the addAmount
         *  Note: The mToken must handle variations between ERC-20 and ETH underlying.
         *  On success, the mToken holds an additional addAmount of cash.
         *  doTransferIn reverts if anything goes wrong, since we can't be sure if side effects occurred.
         *  it returns the amount actually transferred, in case of a fee.
         */
        // slither-disable-next-line reentrancy-eth
        uint256 actualAddAmount = doTransferIn(payer_, addAmount_);
        uint256 totalProtocolInterestNew = totalProtocolInterest + actualAddAmount;

        // Store protocolInterest[n+1] = protocolInterest[n] + actualAddAmount
        totalProtocolInterest = totalProtocolInterestNew;

        emit ProtocolInterestAdded(payer_, actualAddAmount, totalProtocolInterestNew);
    }

    /**
     * @notice Accrues interest and reduces protocol interest by transferring to admin
     * @param reduceAmount Amount of reduction to protocol interest
     */
    function reduceProtocolInterest(uint256 reduceAmount, address receiver_)
        external
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
        nonReentrant
    {
        accrueInterest();

        // Check if protocol has insufficient underlying cash
        require(getCashPrior() >= reduceAmount, ErrorCodes.INSUFFICIENT_TOKEN_CASH);
        require(totalProtocolInterest >= reduceAmount, ErrorCodes.INVALID_REDUCE_AMOUNT);

        /////////////////////////
        // EFFECTS & INTERACTIONS

        uint256 totalProtocolInterestNew = totalProtocolInterest - reduceAmount;
        totalProtocolInterest = totalProtocolInterestNew;

        // doTransferOut reverts if anything goes wrong, since we can't be sure if side effects occurred.
        doTransferOut(receiver_, reduceAmount);

        emit ProtocolInterestReduced(receiver_, reduceAmount, totalProtocolInterestNew);
    }

    /**
     * @notice accrues interest and updates the interest rate model using setInterestRateModelFresh
     * @dev Admin function to accrue interest and update the interest rate model
     * @param newInterestRateModel the new interest rate model to use
     */
    function setInterestRateModel(InterestRateModel newInterestRateModel)
        external
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        accrueInterest();
        setInterestRateModelFresh(newInterestRateModel);
    }

    /**
     * @notice updates the interest rate model (*requires fresh interest accrual)
     * @dev Admin function to update the interest rate model
     * @param newInterestRateModel the new interest rate model to use
     */
    function setInterestRateModelFresh(InterestRateModel newInterestRateModel) internal {
        require(
            newInterestRateModel.supportsInterface(type(InterestRateModel).interfaceId),
            ErrorCodes.CONTRACT_DOES_NOT_SUPPORT_INTERFACE
        );
        require(accrualBlockNumber == getBlockNumber(), ErrorCodes.MARKET_NOT_FRESH);

        InterestRateModel oldInterestRateModel = interestRateModel;
        interestRateModel = newInterestRateModel;

        emit NewMarketInterestRateModel(oldInterestRateModel, newInterestRateModel);
    }

    /**
     * @notice Updates share of markets cash that can be used as maximum amount of flash loan.
     * @param newMax New max amount share
     */
    function setFlashLoanMaxShare(uint256 newMax) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(newMax <= EXP_SCALE, ErrorCodes.FL_PARAM_IS_TOO_LARGE);
        emit NewFlashLoanMaxShare(maxFlashLoanShare, newMax);
        maxFlashLoanShare = newMax;
    }

    /**
     * @notice Updates fee of flash loan.
     * @param newFee New fee share of flash loan
     */
    function setFlashLoanFeeShare(uint256 newFee) external onlyRole(TIMELOCK) {
        require(newFee <= EXP_SCALE, ErrorCodes.FL_PARAM_IS_TOO_LARGE);
        emit NewFlashLoanFee(flashLoanFeeShare, newFee);
        flashLoanFeeShare = newFee;
    }

    /*** Safe Token ***/

    /**
     * @notice Gets balance of this contract in terms of the underlying
     * @dev This excludes the value of the current message, if any
     * @return The quantity of underlying tokens owned by this contract
     */
    function getCashPrior() internal view virtual returns (uint256) {
        return underlying.balanceOf(address(this));
    }

    /**
     * @dev Similar to EIP20 transfer, except it handles a False result from `transferFrom` and reverts in that case.
     *      This will revert due to insufficient balance or insufficient allowance.
     *      This function returns the actual amount received,
     *      which may be less than `amount` if there is a fee attached to the transfer.
     *
     *      Note: This wrapper safely handles non-standard ERC-20 tokens that do not return a value.
     *            See here:
     *            https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca
     */
    function doTransferIn(address from, uint256 amount) internal virtual returns (uint256) {
        uint256 balanceBefore = underlying.balanceOf(address(this));
        underlying.safeTransferFrom(from, address(this), amount);

        // Calculate the amount that was *actually* transferred
        uint256 balanceAfter = underlying.balanceOf(address(this));
        require(balanceAfter >= balanceBefore, ErrorCodes.TOKEN_TRANSFER_IN_UNDERFLOW);
        return balanceAfter - balanceBefore;
    }

    /**
     * @dev Similar to EIP20 transfer, except it handles a False success from `transfer`
     *      and returns an explanatory error code rather than reverting. If caller has not
     *      called checked protocol's balance, this may revert due to insufficient cash held
     *      in this contract. If caller has checked protocol's balance prior to this call, and verified
     *      it is >= amount, this should not revert in normal conditions.
     *
     *      Note: This wrapper safely handles non-standard ERC-20 tokens that do not return a value.
     *            See here:
     *            https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca
     */
    function doTransferOut(address to, uint256 amount) internal virtual {
        underlying.safeTransfer(to, amount);
    }

    /**
     * @notice Admin call to delegate the votes of the MNT-like underlying
     * @param mntLikeDelegatee The address to delegate votes to
     * @dev MTokens whose underlying are not MntLike should revert here
     */
    function delegateMntLikeTo(address mntLikeDelegatee) external onlyRole(DEFAULT_ADMIN_ROLE) {
        MntLike(address(underlying)).delegate(mntLikeDelegatee);
    }

    /// @dev Returns true if this contract implements the interface defined by `interfaceId`
    function supportsInterface(bytes4 interfaceId) public view override(AccessControl, IERC165) returns (bool) {
        return
            interfaceId == type(MTokenInterface).interfaceId ||
            interfaceId == type(IERC20).interfaceId ||
            interfaceId == type(IERC3156FlashLender).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.9;

import "../MToken.sol";

abstract contract PriceOracle {
    /// @notice Indicator that this is a PriceOracle contract (for inspection)
    bool public constant isPriceOracle = true;

    /// @notice Get the underlying price of a mToken asset
    /// @param mToken The mToken to get the underlying price of
    /// @return The underlying asset price mantissa (scaled by 1e18).
    /// Zero means the price is unavailable.
    function getUnderlyingPrice(MToken mToken) external view virtual returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/AccessControl.sol)

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
        _checkRole(role, _msgSender());
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
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
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
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
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
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/Math.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeCast.sol)

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface SupervisorInterface is IERC165 {
    /***  Manage your collateral assets ***/

    function enableAsCollateral(address[] calldata mTokens) external;

    function disableAsCollateral(address mToken) external;

    /*** Policy Hooks ***/

    function beforeLend(
        address mToken,
        address lender,
        uint256 wrapBalance
    ) external;

    function beforeRedeem(
        address mToken,
        address redeemer,
        uint256 redeemTokens
    ) external;

    function redeemVerify(uint256 redeemAmount, uint256 redeemTokens) external;

    function beforeBorrow(
        address mToken,
        address borrower,
        uint256 borrowAmount
    ) external;

    function beforeRepayBorrow(address mToken, address borrower) external;

    function beforeAutoLiquidationSeize(
        address mToken,
        address liquidator_,
        address borrower
    ) external;

    function beforeAutoLiquidationRepay(
        address liquidator,
        address borrower,
        address mToken,
        uint224 borrowIndex
    ) external;

    function beforeTransfer(
        address mToken,
        address src,
        address dst,
        uint256 transferTokens
    ) external;

    function beforeFlashLoan(
        address mToken,
        address receiver,
        uint256 amount,
        uint256 fee
    ) external;

    function isLiquidator(address liquidator) external;
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.9;

import "@openzeppelin/contracts/interfaces/IERC3156FlashLender.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

import "./SupervisorInterface.sol";
import "./InterestRateModel.sol";
import "./WhitelistInterface.sol";

abstract contract MTokenStorage is AccessControl, ReentrancyGuard {
    uint256 internal constant EXP_SCALE = 1e18;
    bytes32 internal constant FLASH_LOAN_SUCCESS = keccak256("ERC3156FlashBorrower.onFlashLoan");

    /// @dev Value is the Keccak-256 hash of "TIMELOCK"
    bytes32 public constant TIMELOCK = bytes32(0xaefebe170cbaff0af052a32795af0e1b8afff9850f946ad2869be14f35534371);

    /**
     * @notice Underlying asset for this MToken
     */
    IERC20 public underlying;

    /**
     * @notice EIP-20 token name for this token
     */
    string public name;

    /**
     * @notice EIP-20 token symbol for this token
     */
    string public symbol;

    /**
     * @notice EIP-20 token decimals for this token
     */
    uint8 public decimals;

    /**
     * @dev Maximum borrow rate that can ever be applied (.0005% / block)
     */

    uint256 internal constant borrowRateMaxMantissa = 0.0005e16;

    /**
     * @dev Maximum fraction of interest that can be set aside for protocol interest
     */
    uint256 internal constant protocolInterestFactorMaxMantissa = 1e18;

    /**
     * @notice Contract which oversees inter-mToken operations
     */
    SupervisorInterface public supervisor;

    /**
     * @notice Model which tells what the current interest rate should be
     */
    InterestRateModel public interestRateModel;

    /**
     * @dev Initial exchange rate used when lending the first MTokens (used when totalTokenSupply = 0)
     */
    uint256 public initialExchangeRateMantissa;

    /**
     * @notice Fraction of interest currently set aside for protocol interest
     */
    uint256 public protocolInterestFactorMantissa;

    /**
     * @notice Block number that interest was last accrued at
     */
    uint256 public accrualBlockNumber;

    /**
     * @notice Accumulator of the total earned interest rate since the opening of the market
     */
    uint256 public borrowIndex;

    /**
     * @notice Total amount of outstanding borrows of the underlying in this market
     */
    uint256 public totalBorrows;

    /**
     * @notice Total amount of protocol interest of the underlying held in this market
     */
    uint256 public totalProtocolInterest;

    /**
     * @dev Total number of tokens in circulation
     */
    uint256 internal totalTokenSupply;

    /**
     * @dev Official record of token balances for each account
     */
    mapping(address => uint256) internal accountTokens;

    /**
     * @dev Approved token transfer amounts on behalf of others
     */
    mapping(address => mapping(address => uint256)) internal transferAllowances;

    /**
     * @notice Container for borrow balance information
     * @param principal Total balance (with accrued interest), after applying the most recent balance-changing action
     * @param interestIndex Global borrowIndex as of the most recent balance-changing action
     */
    struct BorrowSnapshot {
        uint256 principal;
        uint256 interestIndex;
    }

    /**
     * @dev Mapping of account addresses to outstanding borrow balances
     */
    mapping(address => BorrowSnapshot) internal accountBorrows;

    /// @dev Share of market's current underlying  token balance that can be used as flash loan (scaled by 1e18).
    uint256 public maxFlashLoanShare;

    /// @dev Share of flash loan amount that would be taken as fee (scaled by 1e18).
    uint256 public flashLoanFeeShare;
}

interface MTokenInterface is IERC20, IERC3156FlashLender, IERC165 {
    /*** Market Events ***/

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
        uint256 seizeUnderlyingAmount,
        address market
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

    /*** Admin Events ***/

    /**
     * @notice Event emitted when supervisor is changed
     */
    event NewSupervisor(SupervisorInterface oldSupervisor, SupervisorInterface newSupervisor);

    /**
     * @notice Event emitted when interestRateModel is changed
     */
    event NewMarketInterestRateModel(InterestRateModel oldInterestRateModel, InterestRateModel newInterestRateModel);

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

    /*** User Interface ***/

    function balanceOfUnderlying(address owner) external returns (uint256);

    function getAccountSnapshot(address account)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    function borrowRatePerBlock() external view returns (uint256);

    function supplyRatePerBlock() external view returns (uint256);

    function totalBorrowsCurrent() external returns (uint256);

    function borrowBalanceCurrent(address account) external returns (uint256);

    function borrowBalanceStored(address account) external view returns (uint256);

    function exchangeRateCurrent() external returns (uint256);

    function exchangeRateStored() external view returns (uint256);

    function getCash() external view returns (uint256);

    function accrueInterest() external;

    function lend(uint256 lendAmount) external;

    function redeem(uint256 redeemTokens) external;

    function redeemUnderlying(uint256 redeemAmount) external;

    function borrow(uint256 borrowAmount) external;

    function repayBorrow(uint256 repayAmount) external;

    function repayBorrowBehalf(address borrower, uint256 repayAmount) external;

    function autoLiquidationRepayBorrow(address borrower, uint256 repayAmount) external;

    function sweepToken(IERC20 token, address admin_) external;

    function addProtocolInterestBehalf(address payer, uint256 addAmount) external;

    /*** Admin Functions ***/

    function setSupervisor(SupervisorInterface newSupervisor) external;

    function setProtocolInterestFactor(uint256 newProtocolInterestFactorMantissa) external;

    function reduceProtocolInterest(uint256 reduceAmount, address admin_) external;

    function setInterestRateModel(InterestRateModel newInterestRateModel) external;

    function addProtocolInterest(uint256 addAmount) external;
}

interface MntLike {
    function delegate(address delegatee) external;
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @title Minterest InterestRateModel Interface
 * @author Minterest
 */
interface InterestRateModel is IERC165 {
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

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.9;

library ErrorCodes {
    // Common
    string internal constant ADMIN_ONLY = "E101";
    string internal constant UNAUTHORIZED = "E102";
    string internal constant OPERATION_PAUSED = "E103";
    string internal constant WHITELISTED_ONLY = "E104";

    // Invalid input
    string internal constant ADMIN_ADDRESS_CANNOT_BE_ZERO = "E201";
    string internal constant INVALID_REDEEM = "E202";
    string internal constant REDEEM_TOO_MUCH = "E203";
    string internal constant WITHDRAW_NOT_ALLOWED = "E204";
    string internal constant MARKET_NOT_LISTED = "E205";
    string internal constant INSUFFICIENT_LIQUIDITY = "E206";
    string internal constant INVALID_SENDER = "E207";
    string internal constant BORROW_CAP_REACHED = "E208";
    string internal constant BALANCE_OWED = "E209";
    string internal constant UNRELIABLE_LIQUIDATOR = "E210";
    string internal constant INVALID_DESTINATION = "E211";
    string internal constant CONTRACT_DOES_NOT_SUPPORT_INTERFACE = "E212";
    string internal constant INSUFFICIENT_STAKE = "E213";
    string internal constant INVALID_DURATION = "E214";
    string internal constant INVALID_PERIOD_RATE = "E215";
    string internal constant EB_TIER_LIMIT_REACHED = "E216";
    string internal constant INVALID_DEBT_REDEMPTION_RATE = "E217";
    string internal constant LQ_INVALID_SEIZE_DISTRIBUTION = "E218";
    string internal constant EB_TIER_DOES_NOT_EXIST = "E219";
    string internal constant EB_ZERO_TIER_CANNOT_BE_ENABLED = "E220";
    string internal constant EB_ALREADY_ACTIVATED_TIER = "E221";
    string internal constant EB_END_BLOCK_MUST_BE_LARGER_THAN_CURRENT = "E222";
    string internal constant EB_CANNOT_MINT_TOKEN_FOR_ACTIVATED_TIER = "E223";
    string internal constant EB_EMISSION_BOOST_IS_NOT_IN_RANGE = "E224";
    string internal constant TARGET_ADDRESS_CANNOT_BE_ZERO = "E225";
    string internal constant INSUFFICIENT_TOKEN_IN_VESTING_CONTRACT = "E226";
    string internal constant VESTING_SCHEDULE_ALREADY_EXISTS = "E227";
    string internal constant INSUFFICIENT_TOKENS_TO_CREATE_SCHEDULE = "E228";
    string internal constant NO_VESTING_SCHEDULE = "E229";
    string internal constant SCHEDULE_IS_IRREVOCABLE = "E230";
    string internal constant SCHEDULE_START_IS_ZERO = "E231";
    string internal constant MNT_AMOUNT_IS_ZERO = "E232";
    string internal constant RECEIVER_ALREADY_LISTED = "E233";
    string internal constant RECEIVER_ADDRESS_CANNOT_BE_ZERO = "E234";
    string internal constant CURRENCY_ADDRESS_CANNOT_BE_ZERO = "E235";
    string internal constant INCORRECT_AMOUNT = "E236";
    string internal constant RECEIVER_NOT_IN_APPROVED_LIST = "E237";
    string internal constant MEMBERSHIP_LIMIT = "E238";
    string internal constant MEMBER_NOT_EXIST = "E239";
    string internal constant MEMBER_ALREADY_ADDED = "E240";
    string internal constant MEMBERSHIP_LIMIT_REACHED = "E241";
    string internal constant REPORTED_PRICE_SHOULD_BE_GREATER_THAN_ZERO = "E242";
    string internal constant MTOKEN_ADDRESS_CANNOT_BE_ZERO = "E243";
    string internal constant TOKEN_ADDRESS_CANNOT_BE_ZERO = "E244";
    string internal constant REDEEM_TOKENS_OR_REDEEM_AMOUNT_MUST_BE_ZERO = "E245";
    string internal constant FL_TOKEN_IS_NOT_UNDERLYING = "E246";
    string internal constant FL_AMOUNT_IS_TOO_LARGE = "E247";
    string internal constant FL_CALLBACK_FAILED = "E248";
    string internal constant DD_UNSUPPORTED_TOKEN = "E249";
    string internal constant DD_MARKET_ADDRESS_IS_ZERO = "E250";
    string internal constant DD_ROUTER_ADDRESS_IS_ZERO = "E251";
    string internal constant DD_RECEIVER_ADDRESS_IS_ZERO = "E252";
    string internal constant DD_BOT_ADDRESS_IS_ZERO = "E253";
    string internal constant DD_MARKET_NOT_FOUND = "E254";
    string internal constant DD_ROUTER_NOT_FOUND = "E255";
    string internal constant DD_RECEIVER_NOT_FOUND = "E256";
    string internal constant DD_BOT_NOT_FOUND = "E257";
    string internal constant DD_ROUTER_ALREADY_SET = "E258";
    string internal constant DD_RECEIVER_ALREADY_SET = "E259";
    string internal constant DD_BOT_ALREADY_SET = "E260";
    string internal constant EB_MARKET_INDEX_IS_LESS_THAN_USER_INDEX = "E261";
    string internal constant MV_BLOCK_NOT_YET_MINED = "E262";
    string internal constant MV_SIGNATURE_EXPIRED = "E263";
    string internal constant MV_INVALID_NONCE = "E264";
    string internal constant DD_EXPIRED_DEADLINE = "E265";
    string internal constant LQ_INVALID_DRR_ARRAY = "E266";
    string internal constant LQ_INVALID_SEIZE_ARRAY = "E267";
    string internal constant LQ_INVALID_DEBT_REDEMPTION_RATE = "E268";
    string internal constant LQ_INVALID_SEIZE_INDEX = "E269";
    string internal constant LQ_DUPLICATE_SEIZE_INDEX = "E270";

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
    string internal constant RATE_IS_NOT_SET = "E314";
    string internal constant INSUFFICIENT_SHORTFALL = "E315";
    string internal constant RATE_NOT_IN_RANGE = "E316";
    string internal constant BUYBACK_DRIPS_ALREADY_HAPPENED = "E317";
    string internal constant EB_INDEX_SHOULD_BE_GREATER_THAN_INITIAL = "E318";
    string internal constant NO_VESTING_SCHEDULES = "E319";
    string internal constant INSUFFICIENT_UNRELEASED_TOKENS = "E320";
    string internal constant INSUFFICIENT_FUNDS = "E321";
    string internal constant ORACLE_PRICE_EXPIRED = "E322";
    string internal constant TOKEN_NOT_FOUND = "E323";
    string internal constant RECEIVED_PRICE_HAS_INVALID_ROUND = "E324";
    string internal constant FL_PULL_AMOUNT_IS_TOO_LOW = "E325";
    string internal constant INSUFFICIENT_TOTAL_PROTOCOL_INTEREST = "E326";
    string internal constant BB_ACCOUNT_RECENTLY_VOTED = "E327";

    // Invalid input - Admin functions
    string internal constant ZERO_EXCHANGE_RATE = "E401";
    string internal constant SECOND_INITIALIZATION = "E402";
    string internal constant MARKET_ALREADY_LISTED = "E403";
    string internal constant IDENTICAL_VALUE = "E404";
    string internal constant ZERO_ADDRESS = "E405";
    string internal constant NEW_ORACLE_MISMATCH = "E406";
    string internal constant EC_INVALID_PROVIDER_REPRESENTATIVE = "E407";
    string internal constant EC_PROVIDER_CANT_BE_REPRESENTATIVE = "E408";
    string internal constant ORACLE_ADDRESS_CANNOT_BE_ZERO = "E409";
    string internal constant UNDERLYING_TOKENS_DECIMALS_SHOULD_BE_GREATER_THAN_ZERO = "E410";
    string internal constant REPORTER_MULTIPLIER_SHOULD_BE_GREATER_THAN_ZERO = "E411";
    string internal constant CONTRACT_ALREADY_SET = "E412";
    string internal constant INVALID_TOKEN = "E413";
    string internal constant INVALID_PROTOCOL_INTEREST_FACTOR_MANTISSA = "E414";
    string internal constant INVALID_REDUCE_AMOUNT = "E415";
    string internal constant LIQUIDATION_FEE_MANTISSA_SHOULD_BE_GREATER_THAN_ZERO = "E416";
    string internal constant INVALID_UTILISATION_FACTOR_MANTISSA = "E417";
    string internal constant INVALID_MTOKENS_OR_BORROW_CAPS = "E418";
    string internal constant FL_PARAM_IS_TOO_LARGE = "E419";
    string internal constant MNT_INVALID_NONVOTING_PERIOD = "E420";
    string internal constant INPUT_ARRAY_LENGTHS_ARE_NOT_EQUAL = "E421";
    string internal constant EC_INVALID_BOOSTS = "E422";
    string internal constant EC_ACCOUNT_IS_ALREADY_LIQUIDITY_PROVIDER = "E423";
    string internal constant EC_ACCOUNT_HAS_NO_AGREEMENT = "E424";
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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

    constructor() {
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
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface WhitelistInterface is IERC165 {
    function addMember(address _newAccount) external;

    function removeMember(address _accountToRemove) external;

    function turnOffWhitelistMode() external;

    function setMaxMembers(uint256 _newThreshold) external;

    function isWhitelisted(address _who) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC3156FlashBorrower.sol)

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
     * @return The keccak256 hash of "ERC3156FlashBorrower.onFlashLoan"
     */
    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bytes32);
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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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