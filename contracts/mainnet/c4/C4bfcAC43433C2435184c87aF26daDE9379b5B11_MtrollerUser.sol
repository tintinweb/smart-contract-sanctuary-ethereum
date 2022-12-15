pragma solidity ^0.5.16;

contract MtrollerErrorReporter {
    enum Error {
        NO_ERROR,
        UNAUTHORIZED,
        MTROLLER_MISMATCH,
        INSUFFICIENT_SHORTFALL,
        INSUFFICIENT_LIQUIDITY,
        INVALID_CLOSE_FACTOR,
        INVALID_COLLATERAL_FACTOR,
        INVALID_LIQUIDATION_INCENTIVE,
        MARKET_NOT_ENTERED,
        MARKET_NOT_LISTED,
        MARKET_ALREADY_LISTED,
        MATH_ERROR,
        NONZERO_BORROW_BALANCE,
        PRICE_ERROR,
        REJECTION,
        SNAPSHOT_ERROR,
        TOO_MANY_ASSETS,
        TOO_MUCH_REPAY,
        INVALID_TOKEN_TYPE
    }

    enum FailureInfo {
        ACCEPT_ADMIN_PENDING_ADMIN_CHECK,
        ACCEPT_PENDING_IMPLEMENTATION_ADDRESS_CHECK,
        EXIT_MARKET_BALANCE_OWED,
        EXIT_MARKET_REJECTION,
        SET_CLOSE_FACTOR_OWNER_CHECK,
        SET_CLOSE_FACTOR_VALIDATION,
        SET_COLLATERAL_FACTOR_OWNER_CHECK,
        SET_COLLATERAL_FACTOR_NO_EXISTS,
        SET_COLLATERAL_FACTOR_VALIDATION,
        SET_COLLATERAL_FACTOR_WITHOUT_PRICE,
        SET_IMPLEMENTATION_OWNER_CHECK,
        SET_LIQUIDATION_INCENTIVE_OWNER_CHECK,
        SET_LIQUIDATION_INCENTIVE_VALIDATION,
        SET_MAX_ASSETS_OWNER_CHECK,
        SET_PENDING_ADMIN_OWNER_CHECK,
        SET_PENDING_IMPLEMENTATION_OWNER_CHECK,
        SET_PRICE_ORACLE_OWNER_CHECK,
        SUPPORT_MARKET_EXISTS,
        SUPPORT_MARKET_OWNER_CHECK,
        SET_PAUSE_GUARDIAN_OWNER_CHECK
    }

    /**
      * @dev `error` corresponds to enum Error; `info` corresponds to enum FailureInfo, and `detail` is an arbitrary
      * contract-specific code that enables us to report opaque error codes from upgradeable contracts.
      **/
    event Failure(uint error, uint info, uint detail);

    /**
      * @dev use this when reporting a known error from the money market or a non-upgradeable collaborator
      */
    function fail(Error err, FailureInfo info) internal returns (uint) {
        emit Failure(uint(err), uint(info), 0);

        return uint(err);
    }

    /**
      * @dev use this when reporting an opaque error from an upgradeable collaborator contract
      */
    function failOpaque(Error err, FailureInfo info, uint opaqueError) internal returns (uint) {
        emit Failure(uint(err), uint(info), opaqueError);

        return uint(err);
    }
}

contract TokenErrorReporter {
    enum Error {
        NO_ERROR,
        UNAUTHORIZED,
        BAD_INPUT,
        MTROLLER_REJECTION,
        MTROLLER_CALCULATION_ERROR,
        INTEREST_RATE_MODEL_ERROR,
        INVALID_ACCOUNT_PAIR,
        INVALID_CLOSE_AMOUNT_REQUESTED,
        INVALID_COLLATERAL_FACTOR,
        INVALID_COLLATERAL,
        MATH_ERROR,
        MARKET_NOT_FRESH,
        MARKET_NOT_LISTED,
        TOKEN_INSUFFICIENT_ALLOWANCE,
        TOKEN_INSUFFICIENT_BALANCE,
        TOKEN_INSUFFICIENT_CASH,
        TOKEN_TRANSFER_IN_FAILED,
        TOKEN_TRANSFER_OUT_FAILED
    }

    /*
     * Note: FailureInfo (but not Error) is kept in alphabetical order
     *       This is because FailureInfo grows significantly faster, and
     *       the order of Error has some meaning, while the order of FailureInfo
     *       is entirely arbitrary.
     */
    enum FailureInfo {
        ACCEPT_ADMIN_PENDING_ADMIN_CHECK,
        ACCRUE_INTEREST_ACCUMULATED_INTEREST_CALCULATION_FAILED,
        ACCRUE_INTEREST_BORROW_RATE_CALCULATION_FAILED,
        ACCRUE_INTEREST_NEW_BORROW_INDEX_CALCULATION_FAILED,
        ACCRUE_INTEREST_NEW_TOTAL_BORROWS_CALCULATION_FAILED,
        ACCRUE_INTEREST_NEW_TOTAL_RESERVES_CALCULATION_FAILED,
        ACCRUE_INTEREST_SIMPLE_INTEREST_FACTOR_CALCULATION_FAILED,
        AUCTION_NOT_ALLOWED,
        BORROW_ACCUMULATED_BALANCE_CALCULATION_FAILED,
        BORROW_ACCRUE_INTEREST_FAILED,
        BORROW_CASH_NOT_AVAILABLE,
        BORROW_FRESHNESS_CHECK,
        BORROW_NEW_TOTAL_BALANCE_CALCULATION_FAILED,
        BORROW_NEW_ACCOUNT_BORROW_BALANCE_CALCULATION_FAILED,
        BORROW_NEW_PLATFORM_FEE_CALCULATION_FAILED,
        BORROW_MARKET_NOT_LISTED,
        BORROW_MTROLLER_REJECTION,
        FLASH_LOAN_BORROW_FAILED,
        FLASH_OPERATION_NOT_DEFINED,
        LIQUIDATE_ACCRUE_BORROW_INTEREST_FAILED,
        LIQUIDATE_ACCRUE_COLLATERAL_INTEREST_FAILED,
        LIQUIDATE_COLLATERAL_FRESHNESS_CHECK,
        LIQUIDATE_COLLATERAL_NOT_FUNGIBLE,
        LIQUIDATE_COLLATERAL_NOT_EXISTING,
        LIQUIDATE_MTROLLER_REJECTION,
        LIQUIDATE_MTROLLER_CALCULATE_AMOUNT_SEIZE_FAILED,
        LIQUIDATE_CLOSE_AMOUNT_IS_UINT_MAX,
        LIQUIDATE_CLOSE_AMOUNT_IS_ZERO,
        LIQUIDATE_FRESHNESS_CHECK,
        LIQUIDATE_GRACE_PERIOD_NOT_EXPIRED,
        LIQUIDATE_LIQUIDATOR_IS_BORROWER,
        LIQUIDATE_NOT_PREFERRED_LIQUIDATOR,
        LIQUIDATE_REPAY_BORROW_FRESH_FAILED,
        LIQUIDATE_SEIZE_BALANCE_INCREMENT_FAILED,
        LIQUIDATE_SEIZE_BALANCE_DECREMENT_FAILED,
        LIQUIDATE_SEIZE_MTROLLER_REJECTION,
        LIQUIDATE_SEIZE_LIQUIDATOR_IS_BORROWER,
        LIQUIDATE_SEIZE_TOO_MUCH,
        LIQUIDATE_SEIZE_NON_FUNGIBLE_ASSET,
        MINT_ACCRUE_INTEREST_FAILED,
        MINT_MTROLLER_REJECTION,
        MINT_EXCHANGE_CALCULATION_FAILED,
        MINT_EXCHANGE_RATE_READ_FAILED,
        MINT_FRESHNESS_CHECK,
        MINT_NEW_ACCOUNT_BALANCE_CALCULATION_FAILED,
        MINT_NEW_TOTAL_SUPPLY_CALCULATION_FAILED,
        MINT_NEW_TOTAL_CASH_CALCULATION_FAILED,
        MINT_TRANSFER_IN_FAILED,
        MINT_TRANSFER_IN_NOT_POSSIBLE,
        REDEEM_ACCRUE_INTEREST_FAILED,
        REDEEM_MTROLLER_REJECTION,
        REDEEM_EXCHANGE_TOKENS_CALCULATION_FAILED,
        REDEEM_EXCHANGE_AMOUNT_CALCULATION_FAILED,
        REDEEM_EXCHANGE_RATE_READ_FAILED,
        REDEEM_FRESHNESS_CHECK,
        REDEEM_NEW_ACCOUNT_BALANCE_CALCULATION_FAILED,
        REDEEM_NEW_TOTAL_SUPPLY_CALCULATION_FAILED,
        REDEEM_TRANSFER_OUT_NOT_POSSIBLE,
        REDEEM_MARKET_EXIT_NOT_POSSIBLE,
        REDEEM_NOT_OWNER,
        REDUCE_RESERVES_ACCRUE_INTEREST_FAILED,
        REDUCE_RESERVES_ADMIN_CHECK,
        REDUCE_RESERVES_CASH_NOT_AVAILABLE,
        REDUCE_RESERVES_FRESH_CHECK,
        REDUCE_RESERVES_VALIDATION,
        REPAY_BEHALF_ACCRUE_INTEREST_FAILED,
        REPAY_BORROW_ACCRUE_INTEREST_FAILED,
        REPAY_BORROW_ACCUMULATED_BALANCE_CALCULATION_FAILED,
        REPAY_BORROW_MTROLLER_REJECTION,
        REPAY_BORROW_FRESHNESS_CHECK,
        REPAY_BORROW_NEW_ACCOUNT_BORROW_BALANCE_CALCULATION_FAILED,
        REPAY_BORROW_NEW_TOTAL_BALANCE_CALCULATION_FAILED,
        REPAY_BORROW_NEW_TOTAL_CASH_CALCULATION_FAILED,
        REPAY_BORROW_TRANSFER_IN_NOT_POSSIBLE,
        SET_COLLATERAL_FACTOR_OWNER_CHECK,
        SET_COLLATERAL_FACTOR_VALIDATION,
        SET_GLOBAL_PARAMETERS_VALUE_CHECK,
        SET_MTROLLER_OWNER_CHECK,
        SET_INTEREST_RATE_MODEL_ACCRUE_INTEREST_FAILED,
        SET_INTEREST_RATE_MODEL_FRESH_CHECK,
        SET_INTEREST_RATE_MODEL_OWNER_CHECK,
        SET_FLASH_WHITELIST_OWNER_CHECK,
        SET_MAX_ASSETS_OWNER_CHECK,
        SET_ORACLE_MARKET_NOT_LISTED,
        SET_PENDING_ADMIN_OWNER_CHECK,
        SET_RESERVE_FACTOR_ACCRUE_INTEREST_FAILED,
        SET_RESERVE_FACTOR_ADMIN_CHECK,
        SET_RESERVE_FACTOR_FRESH_CHECK,
        SET_RESERVE_FACTOR_BOUNDS_CHECK,
        SET_TOKEN_AUCTION_OWNER_CHECK,
        TRANSFER_MTROLLER_REJECTION,
        TRANSFER_NOT_ALLOWED,
        TRANSFER_NOT_ENOUGH,
        TRANSFER_TOO_MUCH,
        ADD_RESERVES_ACCRUE_INTEREST_FAILED,
        ADD_RESERVES_FRESH_CHECK,
        ADD_RESERVES_TOTAL_CASH_CALCULATION_FAILED,
        ADD_RESERVES_TOTAL_RESERVES_CALCULATION_FAILED,
        ADD_RESERVES_TRANSFER_IN_NOT_POSSIBLE
    }

    /**
      * @dev `error` corresponds to enum Error; `info` corresponds to enum FailureInfo, and `detail` is an arbitrary
      * contract-specific code that enables us to report opaque error codes from upgradeable contracts.
      **/
    event Failure(uint error, uint info, uint detail);

    /**
      * @dev use this when reporting a known error from the money market or a non-upgradeable collaborator
      */
    function fail(Error err, FailureInfo info) internal returns (uint) {
        emit Failure(uint(err), uint(info), 0);

        return uint(err);
    }

    /**
      * @dev use this when reporting an opaque error from an upgradeable collaborator contract
      */
    function failOpaque(Error err, FailureInfo info, uint opaqueError) internal returns (uint) {
        emit Failure(uint(err), uint(info), opaqueError);

        return uint(err);
    }
}

pragma solidity ^0.5.16;

import "./MTokenStorage.sol";
import "./MTokenInterfaces.sol";
import "./MtrollerInterface.sol";
import "./ErrorReporter.sol";
import "./compound/Exponential.sol";
import "./compound/EIP20Interface.sol";
import "./compound/InterestRateModel.sol";
import "./open-zeppelin/token/ERC20/IERC20.sol";
import "./open-zeppelin/token/ERC721/IERC721.sol";

/**
 * @title Contract for MToken
 * @notice Abstract base for any type of MToken
 * @author mmo.finance, initially based on Compound
 */
contract MTokenCommon is MTokenV1Storage, MTokenCommonInterface, Exponential, TokenErrorReporter {

    /**
     * @notice Constructs a new MToken
     */
    constructor() public {
    }

    /**
     * @notice Tells the address of the current admin (set in MDelegator.sol)
     * @return admin The address of the current admin
     */
    function getAdmin() public view returns (address payable admin) {
        bytes32 position = mDelegatorAdminPosition;
        assembly {
            admin := sload(position)
        }
    }

    struct AccrueInterestLocalVars {
        uint currentBlockNumber;
        uint accrualBlockNumberPrior;
        uint cashPrior;
        uint borrowsPrior;
        uint reservesPrior;
        uint borrowIndexPrior;
    }

    /**
     * @notice Applies accrued interest to total borrows and reserves
     * @param mToken The mToken market to accrue interest for
     * @dev This calculates interest accrued from the last checkpointed block
     *   up to the current block and writes new checkpoint to storage.
     */
    function accrueInterest(uint240 mToken) public returns (uint) {
        AccrueInterestLocalVars memory vars;

        /* Remember the initial block number */
        vars.currentBlockNumber = getBlockNumber();
        vars.accrualBlockNumberPrior = accrualBlockNumber[mToken];

        /* Short-circuit accumulating 0 interest */
        if (vars.accrualBlockNumberPrior == vars.currentBlockNumber) {
            return uint(Error.NO_ERROR);
        }

        /* Read the previous values out of storage */
        vars.cashPrior = totalCashUnderlying[mToken];
        vars.borrowsPrior = totalBorrows[mToken];
        vars.reservesPrior = totalReserves[mToken];
        vars.borrowIndexPrior = borrowIndex[mToken];

        /* Calculate the current borrow interest rate */
        uint borrowRateMantissa = interestRateModel.getBorrowRate(vars.cashPrior, vars.borrowsPrior, vars.reservesPrior);
        require(borrowRateMantissa <= borrowRateMaxMantissa, "borrow rate is absurdly high");

        /* Calculate the number of blocks elapsed since the last accrual */
        (MathError mathErr, uint blockDelta) = subUInt(vars.currentBlockNumber, vars.accrualBlockNumberPrior);
        require(mathErr == MathError.NO_ERROR, "could not calculate block delta");

        /*
         * Calculate the interest accumulated into borrows and reserves and the new index:
         *  simpleInterestFactor = borrowRate * blockDelta
         *  interestAccumulated = simpleInterestFactor * totalBorrows
         *  totalBorrowsNew = interestAccumulated + totalBorrows
         *  totalReservesNew = interestAccumulated * reserveFactor + totalReserves
         *  borrowIndexNew = simpleInterestFactor * borrowIndex + borrowIndex
         */

        Exp memory simpleInterestFactor;
        uint interestAccumulated;
        uint totalBorrowsNew;
        uint totalReservesNew;
        uint borrowIndexNew;

        (mathErr, simpleInterestFactor) = mulScalar(Exp({mantissa: borrowRateMantissa}), blockDelta);
        if (mathErr != MathError.NO_ERROR) {
            return failOpaque(Error.MATH_ERROR, FailureInfo.ACCRUE_INTEREST_SIMPLE_INTEREST_FACTOR_CALCULATION_FAILED, uint(mathErr));
        }

        (mathErr, interestAccumulated) = mulScalarTruncate(simpleInterestFactor, vars.borrowsPrior);
        if (mathErr != MathError.NO_ERROR) {
            return failOpaque(Error.MATH_ERROR, FailureInfo.ACCRUE_INTEREST_ACCUMULATED_INTEREST_CALCULATION_FAILED, uint(mathErr));
        }

        (mathErr, totalBorrowsNew) = addUInt(interestAccumulated, vars.borrowsPrior);
        if (mathErr != MathError.NO_ERROR) {
            return failOpaque(Error.MATH_ERROR, FailureInfo.ACCRUE_INTEREST_NEW_TOTAL_BORROWS_CALCULATION_FAILED, uint(mathErr));
        }

        (mathErr, totalReservesNew) = mulScalarTruncateAddUInt(Exp({mantissa: reserveFactorMantissa}), interestAccumulated, vars.reservesPrior);
        if (mathErr != MathError.NO_ERROR) {
            return failOpaque(Error.MATH_ERROR, FailureInfo.ACCRUE_INTEREST_NEW_TOTAL_RESERVES_CALCULATION_FAILED, uint(mathErr));
        }

        (mathErr, borrowIndexNew) = mulScalarTruncateAddUInt(simpleInterestFactor, vars.borrowIndexPrior, vars.borrowIndexPrior);
        if (mathErr != MathError.NO_ERROR) {
            return failOpaque(Error.MATH_ERROR, FailureInfo.ACCRUE_INTEREST_NEW_BORROW_INDEX_CALCULATION_FAILED, uint(mathErr));
        }

        /////////////////////////
        // EFFECTS & INTERACTIONS
        // (No safe failures beyond this point)

        /* We write the previously calculated values into storage */
        accrualBlockNumber[mToken] = vars.currentBlockNumber;
        borrowIndex[mToken] = borrowIndexNew;
        totalBorrows[mToken] = totalBorrowsNew;
        totalReserves[mToken] = totalReservesNew;

        /* We emit an AccrueInterest event */
        emit AccrueInterest(mToken, vars.cashPrior, interestAccumulated, borrowIndexNew, totalBorrowsNew);

        return uint(Error.NO_ERROR);
    }

    /**
     * @notice Calculates the exchange rate from the underlying to the MToken
     * @dev This function does not accrue interest before calculating the exchange rate
     * @param mToken The mToken whose exchange rate should be calculated
     * @return (error code, calculated exchange rate scaled by 1e18)
     */
    function exchangeRateStoredInternal(uint240 mToken) internal view returns (MathError, uint) {
        uint _totalSupply = totalSupply[mToken];
        if (_totalSupply == 0) {
            /*
             * If there are no tokens minted:
             *  exchangeRate = initialExchangeRate
             */
            return (MathError.NO_ERROR, initialExchangeRateMantissa);
        } else {
            /*
             * Otherwise:
             *  exchangeRate = (totalCash + totalBorrows - totalReserves) / totalSupply
             */
            uint totalCash = totalCashUnderlying[mToken];
            uint cashPlusBorrowsMinusReserves;
            Exp memory exchangeRate;
            MathError mathErr;

            (mathErr, cashPlusBorrowsMinusReserves) = addThenSubUInt(totalCash, totalBorrows[mToken], totalReserves[mToken]);
            if (mathErr != MathError.NO_ERROR) {
                return (mathErr, 0);
            }

            (mathErr, exchangeRate) = getExp(cashPlusBorrowsMinusReserves, _totalSupply);
            if (mathErr != MathError.NO_ERROR) {
                return (mathErr, 0);
            }

            return (MathError.NO_ERROR, exchangeRate.mantissa);
        }
    }

    /**
     * @notice Return the borrow balance of account based on stored data
     * @param account The address whose balance should be calculated
     * @param mToken The borrowed mToken
     * @return (error code, the calculated balance or 0 if error code is non-zero)
     */
    function borrowBalanceStoredInternal(address account, uint240 mToken) internal view returns (MathError, uint) {
        /* Note: we do not assert that the market is up to date */
        MathError mathErr;
        uint principalTimesIndex;
        uint result;

        /* Get borrowBalance and borrowIndex */
        BorrowSnapshot storage borrowSnapshot = accountBorrows[mToken][account];

        /* If borrowBalance = 0 then borrowIndex is likely also 0.
         * Rather than failing the calculation with a division by 0, we immediately return 0 in this case.
         */
        if (borrowSnapshot.principal == 0) {
            return (MathError.NO_ERROR, 0);
        }

        /* Calculate new borrow balance using the interest index:
         *  recentBorrowBalance = borrower.borrowBalance * market.borrowIndex / borrower.borrowIndex
         */
        (mathErr, principalTimesIndex) = mulUInt(borrowSnapshot.principal, borrowIndex[mToken]);
        if (mathErr != MathError.NO_ERROR) {
            return (mathErr, 0);
        }

        (mathErr, result) = divUInt(principalTimesIndex, borrowSnapshot.interestIndex);
        if (mathErr != MathError.NO_ERROR) {
            return (mathErr, 0);
        }

        return (MathError.NO_ERROR, result);
    }

    /**
     * @dev Function to simply retrieve block number
     *  This exists mainly for inheriting test contracts to stub this result.
     */
    function getBlockNumber() internal view returns (uint) {
        return block.number;
    }


    /*** Error handling ***/

    function requireNoError(uint errCode, string memory message) internal pure {
        if (errCode == uint(Error.NO_ERROR)) {
            return;
        }

        bytes memory fullMessage = new bytes(bytes(message).length + 5);
        uint i;

        for (i = 0; i < bytes(message).length; i++) {
            fullMessage[i] = bytes(message)[i];
        }

        fullMessage[i+0] = byte(uint8(32));
        fullMessage[i+1] = byte(uint8(40));
        fullMessage[i+2] = byte(uint8(48 + ( errCode / 10 )));
        fullMessage[i+3] = byte(uint8(48 + ( errCode % 10 )));
        fullMessage[i+4] = byte(uint8(41));

        require(errCode == uint(Error.NO_ERROR), string(fullMessage));
    }


    /*** Reentrancy Guard ***/

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     */
    modifier nonReentrant() {
        require(_notEntered, "re-entered");
        _notEntered = false;
        _;
        _notEntered = true; // get a gas-refund post-Istanbul
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly
     */
    modifier nonReentrant2() {
        require(_notEntered2, "re-entered");
        _notEntered2 = false;
        _;
        _notEntered2 = true; // get a gas-refund post-Istanbul
    }
}

pragma solidity ^0.5.16;

import "./PriceOracle.sol";
import "./MtrollerInterface.sol";
import "./TokenAuction.sol";
import "./compound/InterestRateModel.sol";
import "./compound/EIP20NonStandardInterface.sol";
import "./open-zeppelin/token/ERC721/IERC721Metadata.sol";

contract MTokenCommonInterface is MTokenIdentifier, MDelegatorIdentifier {

    /*** Market Events ***/

    /**
     * @notice Event emitted when interest is accrued
     */
    event AccrueInterest(uint240 mToken, uint cashPrior, uint interestAccumulated, uint borrowIndex, uint totalBorrows);

    /**
     * @notice Events emitted when tokens are minted
     */
    event Mint(address minter, address beneficiary, uint mintAmountUnderlying, uint240 mTokenMinted, uint amountTokensMinted);

    /**
     * @notice Events emitted when tokens are transferred
     */
    event Transfer(address from, address to, uint240 mToken, uint amountTokens);

    /**
     * @notice Event emitted when tokens are redeemed
     */
    event Redeem(address redeemer, uint240 mToken, uint redeemTokens, uint256 underlyingID, uint underlyingRedeemAmount);

    /**
     * @notice Event emitted when underlying is borrowed
     */
    event Borrow(address borrower, uint256 underlyingID, uint borrowAmount, uint paidOutAmount, uint accountBorrows, uint totalBorrows);

    /**
     * @notice Event emitted when underlying is borrowed in a flash loan operation
     */
    event FlashBorrow(address borrower, uint256 underlyingID, address receiver, uint downPayment, uint borrowAmount, uint paidOutAmount);

    /**
     * @notice Event emitted when a borrow is repaid
     */
    event RepayBorrow(address payer, address borrower, uint256 underlyingID, uint repayAmount, uint accountBorrows, uint totalBorrows);

    /**
     * @notice Event emitted when a borrow is liquidated
     */
    event LiquidateBorrow(address liquidator, address borrower, uint240 mTokenBorrowed, uint repayAmountUnderlying, uint240 mTokenCollateral, uint seizeTokens);

    /**
     * @notice Event emitted when a grace period is started before liquidating a token with an auction
     */
    event GracePeriod(uint240 mTokenCollateral, uint lastBlockOfGracePeriod);


    /*** Admin Events ***/

    /**
     * @notice Event emitted when flash receiver whitlist is changed
     */
    event FlashReceiverWhitelistChanged(address receiver, bool newState);

    /**
     * @notice Event emitted when interestRateModel is changed
     */
    event NewMarketInterestRateModel(InterestRateModel oldInterestRateModel, InterestRateModel newInterestRateModel);

    /**
     * @notice Event emitted when tokenAuction is changed
     */
    event NewTokenAuction(TokenAuction oldTokenAuction, TokenAuction newTokenAuction);

    /**
     * @notice Event emitted when mtroller is changed
     */
    event NewMtroller(MtrollerInterface oldMtroller, MtrollerInterface newMtroller);

    /**
     * @notice Event emitted when global protocol parameters are updated
     */
    event NewGlobalProtocolParameters(uint newInitialExchangeRateMantissa, uint newReserveFactorMantissa, uint newProtocolSeizeShareMantissa, uint newBorrowFeeMantissa);

    /**
     * @notice Event emitted when global auction parameters are updated
     */
    event NewGlobalAuctionParameters(uint newAuctionGracePeriod, uint newPreferredLiquidatorHeadstart, uint newMinimumOfferMantissa, uint newLiquidatorAuctionFeeMantissa, uint newProtocolAuctionFeeMantissa);

    /**
     * @notice Event emitted when the reserves are added
     */
    event ReservesAdded(address benefactor, uint240 mToken, uint addAmount, uint newTotalReserves);

    /**
     * @notice Event emitted when the reserves are reduced
     */
    event ReservesReduced(address admin, uint240 mToken, uint reduceAmount, uint newTotalReserves);

    /**
     * @notice Failure event
     */
    event Failure(uint error, uint info, uint detail);


    function getAdmin() public view returns (address payable admin);
    function accrueInterest(uint240 mToken) public returns (uint);
}

contract MTokenAdminInterface is MTokenCommonInterface {

    /// @notice Indicator that this is a admin part contract (for inspection)
    function isMDelegatorAdminImplementation() public pure returns (bool);

    /*** Admin Functions ***/

    function _setInterestRateModel(InterestRateModel newInterestRateModel) public returns (uint);
    function _setTokenAuction(TokenAuction newTokenAuction) public returns (uint);
    function _setMtroller(MtrollerInterface newMtroller) public returns (uint);
    function _setGlobalProtocolParameters(uint _initialExchangeRateMantissa, uint _reserveFactorMantissa, uint _protocolSeizeShareMantissa, uint _borrowFeeMantissa) public returns (uint);
    function _setGlobalAuctionParameters(uint _auctionGracePeriod, uint _preferredLiquidatorHeadstart, uint _minimumOfferMantissa, uint _liquidatorAuctionFeeMantissa, uint _protocolAuctionFeeMantissa) public returns (uint);
    function _reduceReserves(uint240 mToken, uint reduceAmount) external returns (uint);
    function _sweepERC20(address tokenContract) external returns (uint);
    function _sweepERC721(address tokenContract, uint256 tokenID) external;
}

contract MTokenUserInterface is MTokenCommonInterface {

    /// @notice Indicator that this is a user part contract (for inspection)
    function isMDelegatorUserImplementation() public pure returns (bool);

    /*** User Interface ***/

    function balanceOf(address owner, uint240 mToken) external view returns (uint);
    function getAccountSnapshot(address account, uint240 mToken) external view returns (uint, uint, uint, uint);
    function borrowRatePerBlock(uint240 mToken) external view returns (uint);
    function supplyRatePerBlock(uint240 mToken) external view returns (uint);
    function totalBorrowsCurrent(uint240 mToken) external returns (uint);
    function borrowBalanceCurrent(address account, uint240 mToken) external returns (uint);
    function borrowBalanceStored(address account, uint240 mToken) public view returns (uint);
    function exchangeRateCurrent(uint240 mToken) external returns (uint);
    function exchangeRateStored(uint240 mToken) external view returns (uint);
    function getCash(uint240 mToken) external view returns (uint);
    function seize(uint240 mTokenBorrowed, address liquidator, address borrower, uint240 mTokenCollateral, uint seizeTokens) external returns (uint);
}

contract MTokenInterface is MTokenAdminInterface, MTokenUserInterface {}

contract MFungibleTokenAdminInterface is MTokenAdminInterface {
}

contract MFungibleTokenUserInterface is MTokenUserInterface{

    /*** Market Events ***/

    event Transfer(address indexed from, address indexed to, uint amount);
    event Approval(address indexed owner, address indexed spender, uint amount);

    /*** User Interface ***/

    function transfer(address dst, uint amount) external returns (bool);
    function transferFrom(address src, address dst, uint amount) external returns (bool);
    function approve(address spender, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function balanceOfUnderlying(address owner) external returns (uint);
}

contract MFungibleTokenInterface is MFungibleTokenAdminInterface, MFungibleTokenUserInterface {}

contract MEtherAdminInterface is MFungibleTokenAdminInterface {

    /*** Admin Functions ***/

    function initialize(MtrollerInterface mtroller_,
                InterestRateModel interestRateModel_,
                uint reserveFactorMantissa_,
                uint initialExchangeRateMantissa_,
                uint protocolSeizeShareMantissa_,
                string memory name_,
                string memory symbol_,
                uint8 decimals_) public;

    /*** User Interface ***/

    function redeem(uint redeemTokens) external returns (uint);
    function redeemUnderlying(uint redeemAmount) external returns (uint);
    function borrow(uint borrowAmount) external returns (uint);
    function flashBorrow(uint borrowAmount, address payable receiver, bytes calldata flashParams) external payable returns (uint);
    function name() public view returns (string memory);
    function symbol() public view returns (string memory);
    function decimals() public view returns (uint8);
}

contract MEtherUserInterface is MFungibleTokenUserInterface {

    /*** Admin Functions ***/

    function getProtocolAuctionFeeMantissa() external view returns (uint);
    function _addReserves() external payable returns (uint);

    /*** User Interface ***/

    function mint() external payable returns (uint);
    function mintTo(address beneficiary) external payable returns (uint);
    function repayBorrow() external payable returns (uint);
    function repayBorrowBehalf(address borrower) external payable returns (uint);
    function liquidateBorrow(address borrower, uint240 mTokenCollateral) external payable returns (uint);
}

contract MEtherInterface is MEtherAdminInterface, MEtherUserInterface {}

contract MERC721AdminInterface is MTokenAdminInterface, IERC721, IERC721Metadata {

    event NewTokenAuctionContract(TokenAuction oldTokenAuction, TokenAuction newTokenAuction);

    /*** Admin Functions ***/

    function initialize(address underlyingContract_,
                MtrollerInterface mtroller_,
                InterestRateModel interestRateModel_,
                TokenAuction tokenAuction_,
                string memory name_,
                string memory symbol_) public;

    /*** User Interface ***/

    function redeem(uint240 mToken) public returns (uint);
    function redeemUnderlying(uint256 underlyingID) external returns (uint);
    function redeemAndSell(uint240 mToken, uint sellPrice, address payable transferHandler, bytes memory transferParams) public returns (uint);
    function borrow(uint256 borrowUnderlyingID) external returns (uint);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

contract MERC721UserInterface is MTokenUserInterface, IERC721 {

    event LiquidateToPaymentToken(address indexed oldOwner, address indexed newOwner, uint240 mToken, uint256 auctioneerTokens, uint256 oldOwnerTokens);

    /*** Admin Functions ***/

//    function _addReserves(uint240 mToken, uint addAmount) external payable returns (uint);

    /*** User Interface ***/

    function mintAndCollateralizeTo(address beneficiary, uint256 underlyingTokenID) external returns (uint240);
    function mintTo(address beneficiary, uint256 underlyingTokenID) public returns (uint240);
//    function repayBorrow(uint256 repayUnderlyingID) external payable returns (uint);
//    function repayBorrowBehalf(address borrower, uint256 repayUnderlyingID) external payable returns (uint);
//    function liquidateBorrow(address borrower, uint256 repayUnderlyingID, uint240 mTokenCollateral) external payable returns (uint);
    function addAuctionBid(uint240 mToken) external payable;
    function instantSellToHighestBidder(uint240 mToken, uint256 minimumPrice, address favoriteBidder) public;
    function setAskingPrice(uint240 mToken, uint256 newAskingPrice) external;
    function startGracePeriod(uint240 mToken) external returns (uint);
    function liquidateToPaymentToken(uint240 mToken) external returns (uint);
}

contract MERC721Interface is MERC721AdminInterface, MERC721UserInterface {}

contract FlashLoanReceiverInterface {
    function executeFlashOperation(address payable borrower, uint240 mToken, uint borrowAmount, uint paidOutAmount, bytes calldata flashParams) external returns (uint);
    function executeTransfer(uint256 tokenId, address payable seller, uint sellPrice, bytes calldata transferParams) external returns (uint);
}

pragma solidity ^0.5.16;

import "./MtrollerInterface.sol";
import "./TokenAuction.sol";
import "./compound/InterestRateModel.sol";

contract MDelegateeStorage {
    /**
    * @notice List of all public function selectors implemented by "admin type" contract
    * @dev Needs to be initialized in the constructor(s)
    */
    bytes4[] public implementedSelectors;

    function implementedSelectorsLength() public view returns (uint) {
        return implementedSelectors.length;
    }
}

contract MTokenV1Storage is MDelegateeStorage {

    /**
     * @dev Guard variable for re-entrancy checks
     */
    bool internal _notEntered;
    bool internal _notEntered2;


    /*** Global variables: addresses of other contracts to call. 
     *   These are set at contract initialization and can only be modified by a (timelock) admin
    ***/

    /**
     * @notice Address of the underlying asset contract (this never changes again after initialization)
     */
    address public underlyingContract;

    /**
     * @notice Contract address of model which tells what the current interest rate(s) should be
     */
    InterestRateModel public interestRateModel;

    /**
     * @notice Contract used for (non-fungible) mToken auction (used only if applicable)
     */ 
    TokenAuction public tokenAuction;

    /**
     * @notice Contract which oversees inter-mToken operations
     */
    MtrollerInterface public mtroller;


    /*** Global variables: token identification constants. 
     *   These variables are set at contract initialization and never modified again
    ***/

    /**
     * @notice EIP-20 token name for this token
     */
    string public mName;

    /**
     * @notice EIP-20 token symbol for this token
     */
    string public mSymbol;

    /**
     * @notice EIP-20 token decimals for this token
     */
    uint8 public mDecimals;


    /*** Global variables: protocol control parameters. 
     *   These variables are set at contract initialization and can only be modified by a (timelock) admin
    ***/

    /**
     * @notice Initial exchange rate used when minting the first mTokens (used when totalSupply = 0)
     */
    uint internal initialExchangeRateMantissa;

    /**
     * @notice Fraction of interest currently set aside for reserves
     */
    uint internal constant reserveFactorMaxMantissa = 50e16; // upper protocol limit (50%)
    uint public reserveFactorMantissa;

    /**
     * @notice Fraction of seized (fungible) collateral that is added to reserves
     */
    uint internal constant protocolSeizeShareMaxMantissa = 5e16; // upper protocol limit (5%)
    uint public protocolSeizeShareMantissa;

    /**
     * @notice Fraction of new borrow amount set aside for reserves (one-time fee)
     */
    uint internal constant borrowFeeMaxMantissa = 50e16; // upper protocol limit (50%)
    uint public borrowFeeMantissa;

    /**
     * @notice Mapping of addresses that are whitelisted as receiver for flash loans
     */
    mapping (address => bool) public flashReceiverIsWhitelisted;


    /*** Global variables: auction liquidation control parameters. 
     *   The variables are set at contract initialization and can only be changed by a (timelock) admin
    ***/

    /**
     * @notice Minimum and maximum values that can ever be used for the grace period, which is
     * the minimum time liquidators have to wait before they can seize a non-fungible mToken collateral
     */ 
    uint256 public constant auctionMinGracePeriod = 2000; // lower limit (2000 blocks, i.e. about 8 hours)
    uint256 public constant auctionMaxGracePeriod = 50000; // upper limit (50000 blocks, i.e. about 8.5 days)
    uint256 public auctionGracePeriod;

    /**
     * @notice "Headstart" time in blocks the preferredLiquidator has available to liquidate a mToken
     * exclusively before everybody else is also allowed to do it.
     */
    uint256 public constant preferredLiquidatorMaxHeadstart = 2000; // upper limit (2000 blocks, i.e. about 8 hours)
    uint256 public preferredLiquidatorHeadstart;

    /**
     * @notice Minimum offer required to win liquidation auction, relative to the NFTs regular price.
     */
    uint public constant minimumOfferMaxMantissa = 80e16; // upper limit (80% of market price)
    uint public minimumOfferMantissa;

    /**
     * @notice Fee for the liquidator executing liquidateToPaymentToken().
     */
    uint public constant liquidatorAuctionFeeMaxMantissa = 10e16; // upper limit (10%)
    uint public liquidatorAuctionFeeMantissa;

    /**
     * @notice Fee for the protocol when executing liquidateToPaymentToken() or acceptHighestOffer().
     * The funds are directly added to mEther reserves.
     */
    uint public constant protocolAuctionFeeMaxMantissa = 20e16; // upper limit (50%)
    uint public protocolAuctionFeeMantissa;


    /*** Token variables: basic token identification. 
     *   These variables are only initialized the first time the given token is minted
    ***/

    /**
     * @notice Mapping of mToken to underlying tokenID
     */
    mapping (uint240 => uint256) public underlyingIDs;

    /**
     * @notice Mapping of underlying tokenID to mToken
     */
    mapping (uint256 => uint240) public mTokenFromUnderlying;

    /**
     * @notice Total number of (ever) minted mTokens. Note: Burning a mToken (when redeeming the 
     * underlying asset) DOES NOT reduce this count. The maximum possible amount of tokens that 
     * can ever be minted by this contract is limited to 2^88-1, which is finite but high enough 
     * to never be reached in realistic time spans.
     */
    uint256 public totalCreatedMarkets;

    /**
     * @notice Maps mToken to block number that interest was last accrued at
     */
    mapping (uint240 => uint) public accrualBlockNumber;

    /**
     * @notice Maps mToken to accumulator of the total earned interest rate since the opening of that market
     */
    mapping (uint240 => uint) public borrowIndex;


    /*** Token variables: general token accounting. 
     *   These variables are initialized the first time the given token is minted and then adapted when needed
    ***/

    /**
     * @notice Official record of token balances for each mToken, for each account
     */
    mapping (uint240 => mapping (address => uint)) internal accountTokens;

    /**
     * @notice Container for borrow balance information
     * @member principal Total balance (with accrued interest), after applying the most recent balance-changing action
     * @member interestIndex Global borrowIndex as of the most recent balance-changing action
     */
    struct BorrowSnapshot {
        uint principal;
        uint interestIndex;
    }

    /**
     * @notice Mapping of account addresses to outstanding borrow balances, for any given mToken
     */
    mapping(uint240 => mapping(address => BorrowSnapshot)) internal accountBorrows;

    /**
     * @notice Maximum borrow rate that can ever be applied (.0005% / block)
     */
    uint internal constant borrowRateMaxMantissa = 0.0005e16;

    /**
     * @notice Maps mToken to total amount of cash of the underlying in that market
     */
    mapping (uint240 => uint) public totalCashUnderlying;

    /**
     * @notice Maps mToken to total amount of outstanding borrows of the underlying in that market
     */
    mapping (uint240 => uint) public totalBorrows;

    /**
     * @notice Maps mToken to total amount of reserves of the underlying held in that market
     */
    mapping (uint240 => uint) public totalReserves;

    /**
     * @notice Maps mToken to total number of tokens in circulation in that market
     */
    mapping (uint240 => uint) public totalSupply;


    /*** Token variables: Special variables used for fungible tokens (e.g. ERC-20). 
     *   These variables are initialized the first time the given token is minted and then adapted when needed
    ***/

    /**
     * @notice Dummy ID for "underlying asset" in case of a (single) fungible token
     */
    uint256 internal constant dummyTokenID = 1;

    /**
     * @notice The mToken for a (single) fungible token
     */
    uint240 public thisFungibleMToken;

    /**
     * @notice Approved token transfer amounts on behalf of others (for fungible tokens)
     */
    mapping (address => mapping (address => uint)) internal transferAllowances;


    /*** Token variables: Special variables used for non-fungible tokens (e.g. ERC-721). 
     *   These variables are initialized the first time the given token is minted and then adapted when needed
    ***/

    /**
     * @notice Virtual amount of "cash" that corresponds to one underlying NFT. This is used as 
     * calculatory units internally for mTokens with strictly non-fungible underlying (such as ERC-721) 
     * to avoid loss of mathematical precision for calculations such as borrowing amounts. However, both 
     * underlying NFT and associated mToken are still non-fungible (ERC-721 compliant) tokens and can 
     * only be transferred as one item.
     */
    uint internal constant oneUnit = 1e18;

    /**
     * @notice Mapping of mToken to the block number of the last block in their grace period (zero
     * if mToken is not in a grace period)
     */
    mapping (uint240 => uint256) public lastBlockGracePeriod;

    /**
     * @notice Mapping of mToken to the address that has "fist mover" rights to do the liquidation
     * for the mToken (because that address first called startGracePeriod())
     */
    mapping (uint240 => address) public preferredLiquidator;

    /**
     * @notice Asking price that can be set by a mToken's current owner. At or above this price the mToken
     * will be instantly sold. Set to zero to disable.
     */
    mapping (uint240 => uint256) public askingPrice;
}

pragma solidity ^0.5.16;

import "./open-zeppelin/token/ERC721/ERC721.sol";
import "./open-zeppelin/token/ERC721/IERC721Metadata.sol";
import "./open-zeppelin/token/ERC20/ERC20.sol";

contract TestNFT is ERC721, IERC721Metadata {

    string internal constant _name = "Glasses";
    string internal constant _symbol = "GLSS";
    uint256 public constant price = 0.1e18;
    uint256 public constant maxSupply = 1000;
    uint256 public nextTokenID;
    address payable public admin;
    string internal _baseURI;
    uint internal _digits;
    string internal _suffix;

    constructor(address payable _admin) ERC721(_name, _symbol) public {
        admin = msg.sender;
        _setMetadata("ipfs://QmWNi2ByeUbY1fWbMq841nvNW2tDTpNzyGAhxWDqoXTAEr", 0, "");
        admin = _admin;
    }
    
    function mint() public payable returns (uint256 newTokenID) {
        require(nextTokenID < maxSupply, "all Glasses sold out");
        require(msg.value >= price, "payment too low");
        newTokenID = nextTokenID;
        nextTokenID++;
        _safeMint(msg.sender, newTokenID);
    }

    function () external payable {
        mint();
    }

//***** below this is just for trying out NFTX market functionality */
    function buyAndRedeem(uint256 vaultId, uint256 amount, uint256[] calldata specificIds, address[] calldata path, address to) external payable {
        path;
        require(vaultId == 2, "wrong vault");
        require(amount == 1, "wrong amount");
        require(specificIds[0] == nextTokenID, "wrong ID");
        require(to == msg.sender, "wrong to");
        mint();
    }
//***** above this is just for trying out NFTX market functionality */

    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 tokenId) external view returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");
        if (_digits == 0) {
            return string(abi.encodePacked(_baseURI, _suffix));
        }
        else {
            bytes memory _tokenID = new bytes(_digits);
            uint _i = _digits;
            while (_i != 0) {
                _i--;
                _tokenID[_i] = bytes1(48 + uint8(tokenId % 10));
                tokenId /= 10;
            }
            return string(abi.encodePacked(_baseURI, string(_tokenID), _suffix));
        }
    }

    /*** Admin functions ***/

    function _setMetadata(string memory newBaseURI, uint newDigits, string memory newSuffix) public {
        require(msg.sender == admin, "only admin");
        require(newDigits < 10, "newDigits too big");
        _baseURI = newBaseURI;
        _digits = newDigits;
        _suffix = newSuffix;
    }

    function _setAdmin(address payable newAdmin) public {
        require(msg.sender == admin, "only admin");
        admin = newAdmin;
    }

    function _withdraw() external {
        require(msg.sender == admin, "only admin");
        admin.transfer(address(this).balance);
    }
}

contract TestERC20 is ERC20 {
    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) public {
    }

    function mint(uint256 amount) external {
        _mint(msg.sender, amount);
    }
}

pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

contract Mmo {
    /// @notice EIP-20 token name for this token
    string public constant name = "MMO Token";

    /// @notice EIP-20 token symbol for this token
    string public constant symbol = "MMO";

    /// @notice EIP-20 token decimals for this token
    uint8 public constant decimals = 18;

    /// @notice Total number of tokens in circulation
    uint public constant totalSupply = 10000000e18; // 10 million Mmo

    /// @notice Allowance amounts on behalf of others
    mapping (address => mapping (address => uint96)) internal allowances;

    /// @notice Official record of token balances for each account
    mapping (address => uint96) internal balances;

    /// @notice A record of each accounts delegate
    mapping (address => address) public delegates;

    /// @notice A checkpoint for marking number of votes from a given block
    struct Checkpoint {
        uint32 fromBlock;
        uint96 votes;
    }

    /// @notice A record of votes checkpoints for each account, by index
    mapping (address => mapping (uint32 => Checkpoint)) public checkpoints;

    /// @notice The number of checkpoints for each account
    mapping (address => uint32) public numCheckpoints;

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    /// @notice The EIP-712 typehash for the delegation struct used by the contract
    bytes32 public constant DELEGATION_TYPEHASH = keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    /// @notice A record of states for signing / validating signatures
    mapping (address => uint) public nonces;

    /// @notice An event thats emitted when an account changes its delegate
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    /// @notice An event thats emitted when a delegate account's vote balance changes
    event DelegateVotesChanged(address indexed delegate, uint previousBalance, uint newBalance);

    /// @notice The standard EIP-20 transfer event
    event Transfer(address indexed from, address indexed to, uint256 amount);

    /// @notice The standard EIP-20 approval event
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /**
     * @notice Construct a new Mmo token
     * @param account The initial account to grant all the tokens
     */
    constructor(address account) public {
        balances[account] = uint96(totalSupply);
        emit Transfer(address(0), account, totalSupply);
    }

    /**
     * @notice Get the number of tokens `spender` is approved to spend on behalf of `account`
     * @param account The address of the account holding the funds
     * @param spender The address of the account spending the funds
     * @return The number of tokens approved
     */
    function allowance(address account, address spender) external view returns (uint) {
        return allowances[account][spender];
    }

    /**
     * @notice Approve `spender` to transfer up to `amount` from `src`
     * @dev This will overwrite the approval amount for `spender`
     *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
     * @param spender The address of the account which may transfer tokens
     * @param rawAmount The number of tokens that are approved (2^256-1 means infinite)
     * @return Whether or not the approval succeeded
     */
    function approve(address spender, uint rawAmount) external returns (bool) {
        uint96 amount;
        if (rawAmount == uint(-1)) {
            amount = uint96(-1);
        } else {
            amount = safe96(rawAmount, "Mmo::approve: amount exceeds 96 bits");
        }

        allowances[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);
        return true;
    }

    /**
     * @notice Get the number of tokens held by the `account`
     * @param account The address of the account to get the balance of
     * @return The number of tokens held
     */
    function balanceOf(address account) external view returns (uint) {
        return balances[account];
    }

    /**
     * @notice Transfer `amount` tokens from `msg.sender` to `dst`
     * @param dst The address of the destination account
     * @param rawAmount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transfer(address dst, uint rawAmount) external returns (bool) {
        uint96 amount = safe96(rawAmount, "Mmo::transfer: amount exceeds 96 bits");
        _transferTokens(msg.sender, dst, amount);
        return true;
    }

    /**
     * @notice Transfer `amount` tokens from `src` to `dst`
     * @param src The address of the source account
     * @param dst The address of the destination account
     * @param rawAmount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transferFrom(address src, address dst, uint rawAmount) external returns (bool) {
        address spender = msg.sender;
        uint96 spenderAllowance = allowances[src][spender];
        uint96 amount = safe96(rawAmount, "Mmo::approve: amount exceeds 96 bits");

        if (spender != src && spenderAllowance != uint96(-1)) {
            uint96 newAllowance = sub96(spenderAllowance, amount, "Mmo::transferFrom: transfer amount exceeds spender allowance");
            allowances[src][spender] = newAllowance;

            emit Approval(src, spender, newAllowance);
        }

        _transferTokens(src, dst, amount);
        return true;
    }

    /**
     * @notice Delegate votes from `msg.sender` to `delegatee`
     * @param delegatee The address to delegate votes to
     */
    function delegate(address delegatee) public {
        return _delegate(msg.sender, delegatee);
    }

    /**
     * @notice Delegates votes from signatory to `delegatee`
     * @param delegatee The address to delegate votes to
     * @param nonce The contract state required to match the signature
     * @param expiry The time at which to expire the signature
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function delegateBySig(address delegatee, uint nonce, uint expiry, uint8 v, bytes32 r, bytes32 s) public {
        bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)), getChainId(), address(this)));
        bytes32 structHash = keccak256(abi.encode(DELEGATION_TYPEHASH, delegatee, nonce, expiry));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "Mmo::delegateBySig: invalid signature");
        require(nonce == nonces[signatory]++, "Mmo::delegateBySig: invalid nonce");
        require(now <= expiry, "Mmo::delegateBySig: signature expired");
        return _delegate(signatory, delegatee);
    }

    /**
     * @notice Gets the current votes balance for `account`
     * @param account The address to get votes balance
     * @return The number of current votes for `account`
     */
    function getCurrentVotes(address account) external view returns (uint96) {
        uint32 nCheckpoints = numCheckpoints[account];
        return nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
    }

    /**
     * @notice Determine the prior number of votes for an account as of a block number
     * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
     * @param account The address of the account to check
     * @param blockNumber The block number to get the vote balance at
     * @return The number of votes the account had as of the given block
     */
    function getPriorVotes(address account, uint blockNumber) public view returns (uint96) {
        require(blockNumber < block.number, "Mmo::getPriorVotes: not yet determined");

        uint32 nCheckpoints = numCheckpoints[account];
        if (nCheckpoints == 0) {
            return 0;
        }

        // First check most recent balance
        if (checkpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {
            return checkpoints[account][nCheckpoints - 1].votes;
        }

        // Next check implicit zero balance
        if (checkpoints[account][0].fromBlock > blockNumber) {
            return 0;
        }

        uint32 lower = 0;
        uint32 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            Checkpoint memory cp = checkpoints[account][center];
            if (cp.fromBlock == blockNumber) {
                return cp.votes;
            } else if (cp.fromBlock < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return checkpoints[account][lower].votes;
    }

    function _delegate(address delegator, address delegatee) internal {
        address currentDelegate = delegates[delegator];
        uint96 delegatorBalance = balances[delegator];
        delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        _moveDelegates(currentDelegate, delegatee, delegatorBalance);
    }

    function _transferTokens(address src, address dst, uint96 amount) internal {
        require(src != address(0), "Mmo::_transferTokens: cannot transfer from the zero address");
        require(dst != address(0), "Mmo::_transferTokens: cannot transfer to the zero address");

        balances[src] = sub96(balances[src], amount, "Mmo::_transferTokens: transfer amount exceeds balance");
        balances[dst] = add96(balances[dst], amount, "Mmo::_transferTokens: transfer amount overflows");
        emit Transfer(src, dst, amount);

        _moveDelegates(delegates[src], delegates[dst], amount);
    }

    function _moveDelegates(address srcRep, address dstRep, uint96 amount) internal {
        if (srcRep != dstRep && amount > 0) {
            if (srcRep != address(0)) {
                uint32 srcRepNum = numCheckpoints[srcRep];
                uint96 srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
                uint96 srcRepNew = sub96(srcRepOld, amount, "Mmo::_moveVotes: vote amount underflows");
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

            if (dstRep != address(0)) {
                uint32 dstRepNum = numCheckpoints[dstRep];
                uint96 dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
                uint96 dstRepNew = add96(dstRepOld, amount, "Mmo::_moveVotes: vote amount overflows");
                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }

    function _writeCheckpoint(address delegatee, uint32 nCheckpoints, uint96 oldVotes, uint96 newVotes) internal {
      uint32 blockNumber = safe32(block.number, "Mmo::_writeCheckpoint: block number exceeds 32 bits");

      if (nCheckpoints > 0 && checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber) {
          checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
      } else {
          checkpoints[delegatee][nCheckpoints] = Checkpoint(blockNumber, newVotes);
          numCheckpoints[delegatee] = nCheckpoints + 1;
      }

      emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }

    function safe32(uint n, string memory errorMessage) internal pure returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

    function safe96(uint n, string memory errorMessage) internal pure returns (uint96) {
        require(n < 2**96, errorMessage);
        return uint96(n);
    }

    function add96(uint96 a, uint96 b, string memory errorMessage) internal pure returns (uint96) {
        uint96 c = a + b;
        require(c >= a, errorMessage);
        return c;
    }

    function sub96(uint96 a, uint96 b, string memory errorMessage) internal pure returns (uint96) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function getChainId() internal pure returns (uint) {
        uint256 chainId;
        assembly { chainId := chainid() }
        return chainId;
    }
}

pragma solidity ^0.5.16;

import "./PriceOracle.sol";
import "./MtrollerInterface.sol";
import "./MtrollerStorage.sol";
import "./MTokenInterfaces.sol";
import "./MTokenCommon.sol";
import "./Mmo.sol";
import "./ErrorReporter.sol";
import "./compound/ExponentialNoError.sol";

/**
 * @title Based on Compound's Mtroller Contract, with some modifications
 * @dev This contract must not declare any variables. All required storage must be in MtrollerV1Storage
 * @author Compound, mmo.finance
 */
contract MtrollerCommon is MtrollerV1Storage, MtrollerCommonInterface {

    /**
     * @notice Constructs a new MtrollerCommon
     */
    constructor() public {
    }

    /**
     * @notice Tells the address of the current admin (set in MDelegator.sol)
     * @return admin The address of the current admin
     */
    function getAdmin() public view returns (address payable admin) {
        bytes32 position = mDelegatorAdminPosition;
        assembly {
            admin := sload(position)
        }
    }

    /*** mToken identifier handling utilities ***/

    /**
     * @notice Identifiers for mTokens are special uint240 numbers, where the highest order 8 bits is 
     * an MTokenType enum, the lowest 160 bits are the address of the mToken's contract. The
     * remaining 72 bits in between are used as sequential ID number mTokenSeqNr (always > 0) for
     * non-fungible mTokens. For fungible tokens always mTokenSeqNr == 1. The mToken with
     * mTokenSeqNr == 0 is the special "anchor token" for a given mToken contract.
     */

    /* Returns a special "contract" address reserved for the case when the underlying asset is Ether (ETH) */
    function underlyingContractETH() public pure returns (address) {
        return address(uint160(-1));
    }

    /** 
     * @notice Construct the anchorToken from the given mToken contract address
     * @param mTokenContract The contract address of the mToken whose anchor token to return
     * @return uint240 The anchor token
     */        
    function getAnchorToken(address mTokenContract) public pure returns (uint240) {
        return assembleToken(MTokenIdentifier(mTokenContract).getTokenType(), 0, mTokenContract);
    }

    /** 
     * @notice Construct the anchorToken from the given mToken
     * @param mToken The mToken whose anchor token to return
     * @return uint240 The anchor token for this mToken
     */        
    function getAnchorToken(uint240 mToken) internal pure returns (uint240) {
        return (mToken & 0xff000000000000000000ffffffffffffffffffffffffffffffffffffffff);
    }

    /** 
     * @notice Creates an mToken identifier based on mTokenType, mTokenSeqNr and mTokenAddress
     * @dev Does not check for any errors in its arguments
     * @param mTokenType The MTokenType of the mToken
     * @param mTokenSeqNr The "serial number" of the mToken
     * @param mTokenAddress The address of the mToken's contract
     * @return uint240 The mToken identifier
     */        
    function assembleToken(MTokenType mTokenType, uint72 mTokenSeqNr, address mTokenAddress) public pure returns (uint240 mToken) {
        bytes10 mTokenData = bytes10(uint80(mTokenSeqNr) + (uint80(mTokenType) << 72));
        return (uint240(bytes30(mTokenData)) + uint240(uint160(mTokenAddress)));
    }

    /** 
     * @notice Given an mToken identifier, return the mToken's mTokenType, mTokenSeqNr and mTokenAddress
     * @dev Reverts on error (invalid mToken)
     * @param mToken The mToken to retreive the information from
     * @return (mTokenType The MTokenType of the mToken,
     *          mTokenSeqNr The "serial number" of the mToken,
     *          mTokenAddress The address of the mToken's contract)
     */        
    function parseToken(uint240 mToken) public pure returns (MTokenType mTokenType, uint72 mTokenSeqNr, address mTokenAddress) {
        mTokenAddress = address(uint160(mToken));
        bytes10 mTokenData = bytes10(bytes30(mToken));
        mTokenSeqNr = uint72(uint80(mTokenData));
        mTokenType = MTokenType(uint8(mTokenData[0]));
        require(mTokenType == MTokenIdentifier(mTokenAddress).getTokenType(), "Invalid mToken type");
        if (mTokenType == MTokenType.FUNGIBLE_MTOKEN) {
            require(mTokenSeqNr <= 1, "Invalid seqNr for fungible token");
        }
        else if (mTokenType != MTokenType.ERC721_MTOKEN) {
            revert("Unknown mToken type");
        }
        return (mTokenType, mTokenSeqNr, mTokenAddress);
    }

    /*** Assets You Are In ***/

    /**
      * @notice Add the mToken market to the markets mapping and set it as listed
      * @dev Internal(!) function to set isListed and add support for the market
      * @param mToken The mToken market to list
      * @return uint 0=success, otherwise a failure. (See enum Error for details)
      */
    function _supportMarketInternal(uint240 mToken) internal returns (uint) {
        if (isListed(mToken)) {
            return fail(Error.MARKET_ALREADY_LISTED, FailureInfo.SUPPORT_MARKET_EXISTS);
        }

        // Checks mToken format (full check) to make sure it is a valid mToken (reverts on error)
        ( , uint72 mTokenSeqNr, address mTokenAddress) = parseToken(mToken);
        require(mTokenSeqNr <= MTokenCommon(mTokenAddress).totalCreatedMarkets(), "invalid mToken SeqNr");
        uint240 tokenAnchor = getAnchorToken(mTokenAddress);
        require(tokenAnchor == getAnchorToken(mToken), "invalid anchor token");

        /**
         * Unless sender is admin, only allow listing if sender is mToken's own contract and mToken is
         * not the anchor token and the mToken's anchor token is already listed
         */
        if (msg.sender != getAdmin()) {
            if (msg.sender != mTokenAddress || mToken == tokenAnchor || !isListed(tokenAnchor)) {
                return fail(Error.UNAUTHORIZED, FailureInfo.SUPPORT_MARKET_OWNER_CHECK);
            }
        }

        // Set the mToken as listed
        markets[mToken] = Market({_isListed: true, _collateralFactorMantissa: 0});

        // If the mToken is an anchor token, add it to the markets mapping (reverts on error)
        if (mToken == tokenAnchor) {
            _addMarketInternal(mToken);
        }

        emit MarketListed(mToken);

        return uint(Error.NO_ERROR);
    }

    function _addMarketInternal(uint240 mToken) internal {
        require(allMarketsIndex[mToken] == 0, "market already added");
        allMarketsSize++;
        allMarkets[allMarketsSize] = mToken;
        allMarketsIndex[mToken] = allMarketsSize;
    }

    /**
      * @notice Checks if an mToken is listed (i.e., it is supported by the platform)
      * @dev For this to return true both the actual mToken and its anchorToken have to be listed.
      * The anchorToken needs to be listed explicitly by admin using _supportMarket(). Any other
      * mToken is listed automatically when mintAllowed() is called for that mToken, i.e. when it is
      * minted for the first time, but only if it's anchorToken is already listed.
      * @param mToken The mToken to check
      * @return true if both the mToken and its anchorToken are listed, false otherwise
      */
    function isListed(uint240 mToken) internal view returns (bool) {
        if (!(markets[getAnchorToken(mToken)]._isListed)) {
            return false;
        }
        return (markets[mToken]._isListed);
    }

    /**
      * @notice Returns the current collateral factor of a mToken
      * @dev If the mTokens own (specific) collateral factor is zero or the anchor token's collateral
      * factor is zero, then the anchor token's collateral factor is returned, otherwise the specific factor.
      * Reverts if mToken is not listed or resulting collateral factor exceeds limit
      * @param mToken The mToken to return the collateral factor for
      * @return uint The mToken's current collateral factor, scaled by 1e18
      */
    function collateralFactorMantissa(uint240 mToken) public view returns (uint) {
        require(isListed(mToken), "mToken not listed");
        uint240 tokenAnchor = getAnchorToken(mToken);
        uint result = markets[tokenAnchor]._collateralFactorMantissa;
        if (result == 0) {
            return 0;
        }
        if (mToken != tokenAnchor) {
            uint localFactor = markets[mToken]._collateralFactorMantissa;
            if (localFactor != 0) {
                result = localFactor;
            }
        }
        require(result <= collateralFactorMaxMantissa, "collateral factor too high");
        return result;
    }
}

pragma solidity ^0.5.16;

import "./PriceOracle.sol";

contract MTokenIdentifier {
    /* mToken identifier handling */
    
    enum MTokenType {
        INVALID_MTOKEN,
        FUNGIBLE_MTOKEN,
        ERC721_MTOKEN
    }

    /*
     * Marker for valid mToken contract. Derived MToken contracts need to override this returning 
     * the correct MTokenType for that MToken
    */
    function getTokenType() public pure returns (MTokenType) {
        return MTokenType.INVALID_MTOKEN;
    }
}

contract MDelegatorIdentifier {
    // Storage position of the admin of a delegator contract
    bytes32 internal constant mDelegatorAdminPosition = 
        keccak256("com.mmo-finance.mDelegator.admin.address");
}

contract MtrollerCommonInterface is MTokenIdentifier, MDelegatorIdentifier {
    /// @notice Emitted when an admin supports a market
    event MarketListed(uint240 mToken);

    /// @notice Emitted when a collateral factor is changed by admin
    event NewCollateralFactor(uint240 mToken, uint oldCollateralFactorMantissa, uint newCollateralFactorMantissa);

    /// @notice Emitted when an account enters a market
    event MarketEntered(uint240 mToken, address account);

    /// @notice Emitted when an account exits a market
    event MarketExited(uint240 mToken, address account);

    /// @notice Emitted when a new MMO speed is calculated for a market
    event MmoSpeedUpdated(uint240 indexed mToken, uint newSpeed);

    /// @notice Emitted when a new MMO speed is set for a contributor
    event ContributorMmoSpeedUpdated(address indexed contributor, uint newSpeed);

    /// @notice Emitted when MMO is distributed to a supplier
    event DistributedSupplierMmo(uint240 indexed mToken, address indexed supplier, uint mmoDelta, uint MmoSupplyIndex);

    /// @notice Emitted when MMO is distributed to a borrower
    event DistributedBorrowerMmo(uint240 indexed mToken, address indexed borrower, uint mmoDelta, uint mmoBorrowIndex);

    /// @notice Emitted when MMO is granted by admin
    event MmoGranted(address recipient, uint amount);

    /// @notice Emitted when close factor is changed by admin
    event NewCloseFactor(uint oldCloseFactorMantissa, uint newCloseFactorMantissa);

    /// @notice Emitted when liquidation incentive is changed by admin
    event NewLiquidationIncentive(uint oldLiquidationIncentiveMantissa, uint newLiquidationIncentiveMantissa);

    /// @notice Emitted when maxAssets is changed by admin
    event NewMaxAssets(uint oldMaxAssets, uint newMaxAssets);

    /// @notice Emitted when price oracle is changed
    event NewPriceOracle(PriceOracle oldPriceOracle, PriceOracle newPriceOracle);

    /// @notice Emitted when pause guardian is changed
    event NewPauseGuardian(address oldPauseGuardian, address newPauseGuardian);

    /// @notice Emitted when an action is paused globally
    event ActionPaused(string action, bool pauseState);

    /// @notice Emitted when an action is paused on a market
    event ActionPaused(uint240 mToken, string action, bool pauseState);

    /// @notice Emitted when borrow cap for a mToken is changed
    event NewBorrowCap(uint240 indexed mToken, uint newBorrowCap);

    /// @notice Emitted when borrow cap guardian is changed
    event NewBorrowCapGuardian(address oldBorrowCapGuardian, address newBorrowCapGuardian);

    function getAdmin() public view returns (address payable admin);

    function underlyingContractETH() public pure returns (address);
    function getAnchorToken(address mTokenContract) public pure returns (uint240);
    function assembleToken(MTokenType mTokenType, uint72 mTokenSeqNr, address mTokenAddress) public pure returns (uint240 mToken);
    function parseToken(uint240 mToken) public pure returns (MTokenType mTokenType, uint72 mTokenSeqNr, address mTokenAddress);

    function collateralFactorMantissa(uint240 mToken) public view returns (uint);
}

contract MtrollerUserInterface is MtrollerCommonInterface {

    /// @notice Indicator that this is a user part contract (for inspection)
    function isMDelegatorUserImplementation() public pure returns (bool);

    /*** Assets You Are In ***/

    function getAssetsIn(address account) external view returns (uint240[] memory);
    function checkMembership(address account, uint240 mToken) external view returns (bool);
    function enterMarkets(uint240[] calldata mTokens) external returns (uint[] memory);
    function enterMarketOnBehalf(uint240 mToken, address owner) external returns (uint);
    function exitMarket(uint240 mToken) external returns (uint);
    function exitMarketOnBehalf(uint240 mToken, address owner) external returns (uint);
    function _setCollateralFactor(uint240 mToken, uint newCollateralFactorMantissa) external returns (uint);

    /*** Policy Hooks ***/

    function auctionAllowed(uint240 mToken, address bidder) public view returns (uint);
    function mintAllowed(uint240 mToken, address minter, uint mintAmount) external returns (uint);
    function mintVerify(uint240 mToken, address minter, uint actualMintAmount, uint mintTokens) external view;
    function redeemAllowed(uint240 mToken, address redeemer, uint redeemTokens) external view returns (uint);
    function redeemVerify(uint240 mToken, address redeemer, uint redeemAmount, uint redeemTokens) external view;
    function borrowAllowed(uint240 mToken, address borrower, uint borrowAmount) external view returns (uint);
    function borrowVerify(uint240 mToken, address borrower, uint borrowAmount) external view;
    function repayBorrowAllowed(uint240 mToken, address payer, address borrower, uint repayAmount) external view returns (uint);
    function repayBorrowVerify(uint240 mToken, address payer, address borrower, uint actualRepayAmount, uint borrowerIndex) external view;
    function liquidateBorrowAllowed(uint240 mTokenBorrowed, uint240 mTokenCollateral, address liquidator, address borrower, uint repayAmount) external view returns (uint);
    function liquidateERC721Allowed(uint240 mToken) external view returns (uint);
    function liquidateBorrowVerify(uint240 mTokenBorrowed, uint240 mTokenCollateral, address liquidator, address borrower, uint actualRepayAmount, uint seizeTokens) external view;
    function seizeAllowed(uint240 mTokenCollateral, uint240 mTokenBorrowed, address liquidator, address borrower, uint seizeTokens) external view returns (uint);
    function seizeVerify(uint240 mTokenCollateral, uint240 mTokenBorrowed, address liquidator, address borrower, uint seizeTokens) external view;
    function transferAllowed(uint240 mToken, address src, address dst, uint transferTokens) external view returns (uint);
    function transferVerify(uint240 mToken, address src, address dst, uint transferTokens) external view;

    /*** Price and Liquidity/Liquidation Calculations ***/
    function getAccountLiquidity(address account) public view returns (uint, uint, uint);
    function getHypotheticalAccountLiquidity(address account, uint240 mTokenModify, uint redeemTokens, uint borrowAmount) public view returns (uint, uint, uint);
    function liquidateCalculateSeizeTokens(uint240 mTokenBorrowed, uint240 mTokenCollateral, uint actualRepayAmount) external view returns (uint, uint);
    function getBlockNumber() public view returns (uint);
    function getPrice(uint240 mToken) public view returns (uint);

    /*** Mmo reward handling ***/
    function updateContributorRewards(address contributor) public;
    function claimMmo(address holder, uint240[] memory mTokens) public;
    function claimMmo(address[] memory holders, uint240[] memory mTokens, bool borrowers, bool suppliers) public;

    /*** Mmo admin functions ***/
    function _grantMmo(address recipient, uint amount) public;
    function _setMmoSpeed(uint240 mToken, uint mmoSpeed) public;
    function _setContributorMmoSpeed(address contributor, uint mmoSpeed) public;
    function getMmoAddress() public view returns (address);
}

contract MtrollerAdminInterface is MtrollerCommonInterface {

    function initialize(address _mmoTokenAddress, uint _maxAssets) public;

    /// @notice Indicator that this is a admin part contract (for inspection)
    function isMDelegatorAdminImplementation() public pure returns (bool);

    function _supportMarket(uint240 mToken) external returns (uint);
    function _setPriceOracle(PriceOracle newOracle) external returns (uint);
    function _setCloseFactor(uint newCloseFactorMantissa) external returns (uint);
    function _setLiquidationIncentive(uint newLiquidationIncentiveMantissa) external returns (uint);
    function _setMaxAssets(uint newMaxAssets) external;
    function _setBorrowCapGuardian(address newBorrowCapGuardian) external;
    function _setMarketBorrowCaps(uint240[] calldata mTokens, uint[] calldata newBorrowCaps) external;
    function _setPauseGuardian(address newPauseGuardian) public returns (uint);
    function _setAuctionPaused(uint240 mToken, bool state) public returns (bool);
    function _setMintPaused(uint240 mToken, bool state) public returns (bool);
    function _setBorrowPaused(uint240 mToken, bool state) public returns (bool);
    function _setTransferPaused(uint240 mToken, bool state) public returns (bool);
    function _setSeizePaused(uint240 mToken, bool state) public returns (bool);
}

contract MtrollerInterface is MtrollerAdminInterface, MtrollerUserInterface {}

pragma solidity ^0.5.16;

import "./PriceOracle.sol";
import "./MTokenInterfaces.sol";
import "./MTokenStorage.sol";
import "./ErrorReporter.sol";
import "./compound/ExponentialNoError.sol";

contract MtrollerV1Storage is MDelegateeStorage, MtrollerErrorReporter, ExponentialNoError {

    /*** Global variables: addresses of other contracts to call. 
     *   These are set at contract initialization and can only be modified by a (timelock) admin
    ***/

    /**
     * @notice Address of the mmo token contract (this never changes again after initialization)
     */
    address mmoTokenAddress;

    /**
     * @notice Oracle which gives the price of any given asset
     */
    PriceOracle public oracle;


    /*** Global variables: protocol control parameters. 
     *   These variables are set at contract initialization and can only be modified by a (timelock) admin
    ***/

    /**
     * @notice Multiplier used to calculate the maximum repayAmount when liquidating a borrow
     */
    uint internal constant closeFactorMinMantissa = 0.05e18; // 0.05 (lower limit)
    uint internal constant closeFactorMaxMantissa = 1.0e18; // 1.0 (upper limit)
    uint public closeFactorMantissa;

    /**
     * @notice Multiplier representing the discount on collateral that a liquidator receives
     */
    uint internal constant liquidationIncentiveMinMantissa = 1.0e18; // 1.0 (lower limit = no incentive)
    uint internal constant liquidationIncentiveMaxMantissa = 2.0e18; // 2.0 (upper limit = 50% discount)
    uint public liquidationIncentiveMantissa;

    /**
     * @notice Max number of assets a single account can participate in (borrow or use as collateral).
     * This value is set at initialization and can only be modified by admin.
     */
    uint public maxAssets;

    /**
     * @notice The borrowCapGuardian can set borrowCaps to any number for any market. Lowering the borrow 
     * cap could disable borrowing on the given market.
     */
    address public borrowCapGuardian;

    /**
     * @notice The Pause Guardian can pause certain actions as a safety mechanism.
     *  Actions which allow users to remove their own assets cannot be paused.
     *  Liquidation / seizing / transfer can only be paused globally, not by market.
     */
    address public pauseGuardian;


    /*** mToken variables: general token-specific parameters and permissions. 
     *   These variables are initialized the first time the given mToken is minted and then adapted when needed
    ***/

    /**
     * @notice Per-account mapping of "mToken assets you are in", length of array capped by maxAssets
     */
    mapping(address => uint240[]) public accountAssets;

    /// Structure for per-token metadata. TODO: Move these to individual mappings (no struct anymore)
    struct Market {
        /// @notice Whether or not this mToken market is listed, i.e. allowed to interact with the mtroller
        bool _isListed;

        /**
         * @notice Multiplier representing the most one can borrow against their collateral in this mToken market.
         *  For instance, 0.9e18 to allow borrowing 90% of collateral value.
         *  Must be between 0 and 1e18 (stored as a mantissa, i.e., scaled by 1e18)
         */
        uint _collateralFactorMantissa;

        /// @notice Mapping of "accounts in this asset", per mToken market.
        mapping(address => bool) _accountMembership;
    }

    /// @notice No collateralFactorMantissa may exceed this value
    uint internal constant collateralFactorMaxMantissa = 0.9e18; // 0.9
    
    /**
     * @notice Official mapping of mTokens -> Market metadata
     * @dev Used e.g. to determine if a market is supported. Do not access variables directly but use getter 
     *  functions _isListed(), _collateralFactorMantissa(), etc
     */
    mapping(uint240 => Market) public markets;


    /*** mToken variables: per-token variables to control (emergency) pausing of certain functions. 
     *   These variables are inactive by default and only set by admin if needed
    ***/
    mapping(uint240 => bool) public auctionGuardianPaused;
    mapping(uint240 => bool) public mintGuardianPaused;
    mapping(uint240 => bool) public borrowGuardianPaused;
    mapping(uint240 => bool) public transferGuardianPaused;
    mapping(uint240 => bool) public seizeGuardianPaused;

    // @notice Borrow caps enforced by borrowAllowed for each mToken address. Defaults to zero which corresponds to unlimited borrowing.
    mapping(uint240 => uint) public borrowCaps;


    /*** mToken variables: list of all markets (for book-keeping by the mtroller). 
     * Only the anchor tokens are registered (when the admin calls _supportMarket() for that anchor token).
     * All other mTokens used (ever minted) can be retrieved from their contract using the respective anchor token.
    ***/
    /// @notice A list of all markets
    mapping (uint => uint240) public allMarkets;
    mapping (uint240 => uint) public allMarketsIndex;
    uint public allMarketsSize;


    /*** MMO platform token variables: not really used so far
    ***/

    /// @notice The rate at which the flywheel distributes MMO to mToken markets, per block. 
    /// Only admin can set that. TODO: better use only with anchor mToken!
    mapping(uint240 => uint) public mmoSpeeds;

    struct MmoMarketState {
        /// @notice The market's last updated mmoBorrowIndex or mmoSupplyIndex
        uint224 index;

        /// @notice The block number the index was last updated at
        uint32 block;
    }

    /// @notice The MMO market supply state for each market
    mapping(uint240 => MmoMarketState) public mmoSupplyState;

    /// @notice The MMO market borrow state for each market
    mapping(uint240 => MmoMarketState) public mmoBorrowState;

    /// @notice The MMO borrow index for each market for each supplier as of the last time they accrued MMO
    mapping(uint240 => mapping(address => uint)) public mmoSupplierIndex;

    /// @notice The MMO borrow index for each market for each borrower as of the last time they accrued MMO
    mapping(uint240 => mapping(address => uint)) public mmoBorrowerIndex;

    /// @notice The MMO accrued but not yet transferred to each user
    mapping(address => uint) public mmoAccrued;

    /// @notice The portion of MMO that each contributor receives per block
    mapping(address => uint) public mmoContributorSpeeds;

    /// @notice Last block at which a contributor's MMO rewards have been allocated
    mapping(address => uint) public lastContributorBlock;

    /// @notice The initial MMO index for a market
    uint224 public constant mmoInitialIndex = 1e36;
}

pragma solidity ^0.5.16;

import "./PriceOracle.sol";
import "./MtrollerInterface.sol";
import "./MtrollerCommon.sol";
import "./MTokenInterfaces.sol";
import "./Mmo.sol";
import "./ErrorReporter.sol";
import "./compound/ExponentialNoError.sol";

/**
 * @title Based on Compound's Mtroller Contract, with some modifications
 * @dev This contract must not declare any variables. All required storage must be inherited from MtrollerCommon
 * @author Compound, mmo.finance
 */
contract MtrollerUser is MtrollerCommon, MtrollerUserInterface {

    /**
     * @notice Constructs a new MtrollerUser
     */
    constructor() public MtrollerCommon() {
    }

    /**
     * @notice Returns the type of implementation for this contract
     */
    function isMDelegatorUserImplementation() public pure returns (bool) {
        return true;
    }

    /*** Assets You Are In ***/

    /**
     * @notice Returns the assets an account has entered
     * @param account The address of the account to pull assets for
     * @return A dynamic list with the assets the account has entered
     */
    function getAssetsIn(address account) external view returns (uint240[] memory) {
        uint240[] memory assetsIn = accountAssets[account];
        return assetsIn;
    }

    /**
     * @notice Returns whether the given account is entered in the given asset
     * @param account The address of the account to check
     * @param mToken The mToken to check
     * @return True if the account is in the asset, otherwise false.
     */
    function checkMembership(address account, uint240 mToken) external view returns (bool) {
        return accountMembership(mToken, account);
    }

    /**
     * @notice Returns whether the given account is entered in the given asset
     * @param account The address of the account to check
     * @param mToken The mToken to check
     * @return True if the account is in the asset, otherwise false.
     */
    function accountMembership(uint240 mToken, address account) internal view returns (bool) {
        return markets[mToken]._accountMembership[account];
    }

    /**
     * @notice Add assets to be included in account liquidity calculation
     * @param mTokens The list of mToken markets to be enabled
     * @return Success indicator for whether each corresponding market was entered (0 = success, 
     * otherwise error code)
     */
    function enterMarkets(uint240[] memory mTokens) public returns (uint[] memory) {
        uint len = mTokens.length;

        uint[] memory results = new uint[](len);
        for (uint i = 0; i < len; i++) {
            results[i] = uint(addToMarketInternal(mTokens[i], msg.sender));
        }

        return results;
    }

    /**
     * @notice Allows the mToken contract to enter the market on a user's behalf
     * @param mToken The mToken market to be entered
     * @param owner The mToken owner on whose behalf the market should be entered
     * @return Success indicator for whether the market was entered
     */
    function enterMarketOnBehalf(uint240 mToken, address owner) external returns (uint) {
        ( , , address mTokenAddress) = parseToken(mToken);
        require(msg.sender == mTokenAddress, "Only mToken contract can do this, only for own mToken");
        return uint(addToMarketInternal(mToken, owner));
    }

    /**
     * @notice Add the mToken market to the borrower's "assets in" for liquidity calculations
     * @param mToken The market to enter
     * @param borrower The address of the account to modify
     * @return Success indicator for whether the market was entered
     */
    function addToMarketInternal(uint240 mToken, address borrower) internal returns (Error) {
        if (!isListed(mToken)) {
            // market is not listed, cannot join
            return Error.MARKET_NOT_LISTED;
        }

        if (accountMembership(mToken, borrower) == true) {
            // already joined
            return Error.NO_ERROR;
        }

        if (accountAssets[borrower].length >= maxAssets) {
            // no more assets allowed in the market for that borrower
            return Error.TOO_MANY_ASSETS;
        }

        // survived the gauntlet, add to list
        // NOTE: we store these somewhat redundantly as a significant optimization
        //  this avoids having to iterate through the list for the most common use cases
        //  that is, only when we need to perform liquidity checks
        //  and not whenever we want to check if an account is in a particular market
        markets[mToken]._accountMembership[borrower] = true;
        accountAssets[borrower].push(mToken);

        emit MarketEntered(mToken, borrower);

        return Error.NO_ERROR;
    }

    /**
     * @notice Removes asset from sender's account liquidity calculation
     * @dev Sender must not have an outstanding borrow balance in the asset,
     *  or be providing necessary collateral for an outstanding borrow.
     * @param mToken The asset to be removed
     * @return Whether or not the account successfully exited the market
     */
    function exitMarket(uint240 mToken) external returns (uint) {
        return exitMarketInternal(mToken, msg.sender);
    }

    /**
     * @notice Allows the mToken contract to exit the market on a user's behalf
     * @param mToken The mToken market to be exited
     * @param owner The mToken owner on whose behalf the market should be exited
     * @return Success indicator for whether the market was exited
     */
    function exitMarketOnBehalf(uint240 mToken, address owner) external returns (uint) {
        ( , , address mTokenAddress) = parseToken(mToken);
        require(msg.sender == mTokenAddress, "Only token contract can do this, only for own token");
        return uint(exitMarketInternal(mToken, owner));
    }

    function exitMarketInternal(uint240 mToken, address borrower) internal returns (uint) {
        /* Fail if mToken not listed */
        if (!isListed(mToken)) {
            return uint(Error.MARKET_NOT_LISTED);
        }

        /* Get sender tokensHeld and amountOwed underlying from the mToken */
        ( , , address mTokenAddress) = parseToken(mToken);
        (uint oErr, uint tokensHeld, uint amountOwed, ) = MTokenInterface(mTokenAddress).getAccountSnapshot(borrower, mToken);
        require(oErr == 0, "exitMarket: getAccountSnapshot failed"); // semi-opaque error code

        /* Fail if the sender has a borrow balance */
        if (amountOwed != 0) {
            return fail(Error.NONZERO_BORROW_BALANCE, FailureInfo.EXIT_MARKET_BALANCE_OWED);
        }

        /* If the borrower still holds tokens in that market they have to be all redeemable */
        if (tokensHeld != 0) {
            /* Fail if the sender is not permitted to redeem all of their tokens */
            uint allowed = redeemAllowedInternal(mToken, borrower, tokensHeld);
            if (allowed != 0) {
                return failOpaque(Error.REJECTION, FailureInfo.EXIT_MARKET_REJECTION, allowed);
            }
        }

        /* Return true if the sender is not already ‘in’ the market */
        if (!accountMembership(mToken, borrower)) {
            return uint(Error.NO_ERROR);
        }

        /* Set mToken account membership to false */
        delete markets[mToken]._accountMembership[borrower];

        /* Delete mToken from the account’s list of assets */
        // load into memory for faster iteration
        uint240[] memory userAssetList = accountAssets[borrower];
        uint len = userAssetList.length;
        uint assetIndex = len;
        for (uint i = 0; i < len; i++) {
            if (userAssetList[i] == mToken) {
                assetIndex = i;
                break;
            }
        }

        // We *must* have found the asset in the list or our redundant data structure is broken
        assert(assetIndex < len);

        // copy last item in list to location of item to be removed, reduce length by 1
        uint240[] storage storedList = accountAssets[borrower];
        storedList[assetIndex] = storedList[storedList.length - 1];
        storedList.length--;

        emit MarketExited(mToken, borrower);

        return uint(Error.NO_ERROR);
    }

    /**
      * @notice Sets the collateralFactor for a mToken market
      * @dev Admin function to set per-market collateralFactor
      * @param mToken The mToken to set the factor on
      * @param newCollateralFactorMantissa The new collateral factor, scaled by 1e18
      * @return uint 0=success, otherwise a failure. (See ErrorReporter for details)
      */
    function _setCollateralFactor(uint240 mToken, uint newCollateralFactorMantissa) external returns (uint) {
        // Check caller is admin
        if (msg.sender != getAdmin()) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_COLLATERAL_FACTOR_OWNER_CHECK);
        }
        return _setCollateralFactorInternal(mToken, newCollateralFactorMantissa);
    }

    function _setCollateralFactorInternal(uint240 mToken, uint newCollateralFactorMantissa) internal returns (uint) {
        // Verify market is listed
        if (!isListed(mToken)) {
            return fail(Error.MARKET_NOT_LISTED, FailureInfo.SET_COLLATERAL_FACTOR_NO_EXISTS);
        }

        // Checks in case of individual collateral factor (i.e., for sub-markets)
        if (mToken != getAnchorToken(mToken)) {
            // fail if price == 0
            if (getPrice(mToken) == 0) {
                return fail(Error.PRICE_ERROR, FailureInfo.SET_COLLATERAL_FACTOR_WITHOUT_PRICE);
            }

            // Checks that new individual collateral factor <= collateralFactorMaxMantissa
            if (newCollateralFactorMantissa > collateralFactorMaxMantissa) {
                return fail(Error.INVALID_COLLATERAL_FACTOR, FailureInfo.SET_COLLATERAL_FACTOR_VALIDATION);
            }
        }

        // Set market's collateral factor to new collateral factor, remember old value
        uint oldCollateralFactorMantissa = markets[mToken]._collateralFactorMantissa;
        markets[mToken]._collateralFactorMantissa = newCollateralFactorMantissa;

        // Checks that total (=combined) collateral factor is in range, otherwise reverts
        collateralFactorMantissa(mToken);

        // Emit event with asset, old collateral factor, and new collateral factor
        emit NewCollateralFactor(mToken, oldCollateralFactorMantissa, newCollateralFactorMantissa);

        return uint(Error.NO_ERROR);
    }

    /*** Policy Hooks ***/

    /**
     * @notice Checks if the given market is allowed for auctions
     * @param mToken The market for which to allow auctions
     * @param bidder The address wanting to use the auction
     * @return 0 if auctions are allowed, otherwise a semi-opaque error code (See ErrorReporter.sol)
     */
    function auctionAllowed(uint240 mToken, address bidder) public view returns (uint) {
        // Shh - currently unused
        bidder;

        (MTokenType mTokenType, , address tokenAddress) = parseToken(mToken);

        // Pausing is a very serious situation - we revert to sound the alarms
        require(!auctionGuardianPaused[getAnchorToken(mToken)], "auction is paused");
        require(!auctionGuardianPaused[mToken], "auction is paused");

        if (!isListed(mToken)) {
            return uint(Error.MARKET_NOT_LISTED);
        }

        // Fail for fungible tokens
        if (mTokenType != MTokenType.ERC721_MTOKEN) {
            return uint(Error.MARKET_NOT_LISTED);
        }

        // Fail for non-existing (e.g. already redeemed) tokens
        if (MERC721Interface(tokenAddress).ownerOf(mToken) == address(0)) {
            return uint(Error.MARKET_NOT_LISTED);
        }

        // Keep the flywheel moving
        // updateMmoSupplyIndex(mToken);
        // distributeSupplierMmo(mToken, bidder);

        return uint(Error.NO_ERROR);
    }

    /**
     * @notice Checks if the account should be allowed to mint tokens in the given market
     * @dev Also, if the anchor market of the mToken is listed, this automatically lists the mToken. 
     * To avoid rogue mTokens being listed this can only be called by the mToken's own contract.
     * @param mToken The market to verify the mint against
     * @param minter The account which would get the minted tokens
     * @param mintAmount The amount of underlying being supplied to the market in exchange for tokens
     * @return 0 if the mint is allowed, otherwise a semi-opaque error code (See ErrorReporter.sol)
     */
    function mintAllowed(uint240 mToken, address minter, uint mintAmount) external returns (uint) {
        // Shh - currently unused
        minter;
        mintAmount;

        // only allow calls from own mToken contract (to avoid listing of rogue mTokens)
        ( , uint72 mTokenSeqNr, address mTokenAddress) = parseToken(mToken);
        require(mTokenSeqNr <= MTokenCommon(mTokenAddress).totalCreatedMarkets(), "invalid mToken SeqNr");
        require(msg.sender == mTokenAddress, "only mToken can call this");

        // Pausing is a very serious situation - we revert to sound the alarms
        uint240 mTokenAnchor = getAnchorToken(mToken);
        require(!mintGuardianPaused[mTokenAnchor], "mint is paused");
        require(!mintGuardianPaused[mToken], "mint is paused");

        // Require anchor token to be listed already
        if (!isListed(mTokenAnchor)) {
            return uint(Error.MARKET_NOT_LISTED);
        }

        if (!isListed(mToken)) {
            // support new (sub-)market (collateral factor of the anchor token is used by default)
            uint err = _supportMarketInternal(mToken);
            if (err != uint(Error.NO_ERROR)) {
                return err;
            }
            // fail if price == 0
            if (getPrice(mToken) == 0) {
                return fail(Error.PRICE_ERROR, FailureInfo.SET_COLLATERAL_FACTOR_WITHOUT_PRICE);
            }
        }

        // Keep the flywheel moving
        // updateMmoSupplyIndex(mToken);
        // distributeSupplierMmo(mToken, minter);

        return uint(Error.NO_ERROR);
    }

    /**
     * @notice Validates mint and reverts on rejection. May emit logs.
     * @param mToken Asset being minted
     * @param minter The address minting the tokens
     * @param actualMintAmount The amount of the underlying asset being minted
     * @param mintTokens The number of tokens being minted
     */
    function mintVerify(uint240 mToken, address minter, uint actualMintAmount, uint mintTokens) external view {
        // Shh - currently unused
        mToken;
        minter;
        actualMintAmount;
        mintTokens;

        // Shh - we don't ever want this hook to be marked pure
        if (false) {
            maxAssets;
        }
    }

    /**
     * @notice Checks if the account should be allowed to redeem tokens in the given market
     * @param mToken The market to verify the redeem against
     * @param redeemer The account which would redeem the tokens
     * @param redeemTokens The number of mTokens to exchange for the underlying asset in the market
     * @return 0 if the redeem is allowed, otherwise a semi-opaque error code (See ErrorReporter.sol)
     */
    function redeemAllowed(uint240 mToken, address redeemer, uint redeemTokens) external view returns (uint) {

        uint allowed = redeemAllowedInternal(mToken, redeemer, redeemTokens);

        if (allowed != uint(Error.NO_ERROR)) {
            return allowed;
        }

        // Keep the flywheel moving
        // updateMmoSupplyIndex(mToken);
        // distributeSupplierMmo(mToken, redeemer);

        return uint(Error.NO_ERROR);
    }

    function redeemAllowedInternal(uint240 mToken, address redeemer, uint redeemTokens) internal view returns (uint) {
        if (!isListed(mToken)) {
            return uint(Error.MARKET_NOT_LISTED);
        }

        /* If the redeemer is not 'in' the market, then we can bypass the liquidity check */
        if (!accountMembership(mToken, redeemer)) {
            return uint(Error.NO_ERROR);
        }

        /* Otherwise, perform a hypothetical liquidity check to guard against shortfall */
        (Error err, , uint shortfall) = getHypotheticalAccountLiquidityInternal(redeemer, mToken, redeemTokens, 0);
        if (err != Error.NO_ERROR) {
            return uint(err);
        }
        if (shortfall > 0) {
            return uint(Error.INSUFFICIENT_LIQUIDITY);
        }

        return uint(Error.NO_ERROR);
    }

    /**
     * @notice Validates redeem and reverts on rejection. May emit logs.
     * @param mToken Asset being redeemed
     * @param redeemer The address redeeming the tokens
     * @param redeemAmount The amount of the underlying asset being redeemed
     * @param redeemTokens The number of tokens being redeemed
     */
    function redeemVerify(uint240 mToken, address redeemer, uint redeemAmount, uint redeemTokens) external view {
        // Shh - currently unused
        mToken;
        redeemer;

        // If redeemTokens is zero, require aldo redeemAmount to be zero
        if (redeemTokens == 0 && redeemAmount > 0) {
            revert("redeemTokens zero");
        }
    }

    /**
     * @notice Checks if the account should be allowed to borrow the underlying asset of the given market
     * @param mToken The market to verify the borrow against
     * @param borrower The account which would borrow the asset
     * @param borrowAmount The amount of underlying the account would borrow
     * @return 0 if the borrow is allowed, otherwise a semi-opaque error code (See ErrorReporter.sol)
     */
    function borrowAllowed(uint240 mToken, address borrower, uint borrowAmount) external view returns (uint) {

        ( , , address mTokenAddress) = parseToken(mToken);

        // Pausing is a very serious situation - we revert to sound the alarms
        require(!borrowGuardianPaused[getAnchorToken(mToken)], "borrow is paused");
        require(!borrowGuardianPaused[mToken], "borrow is paused");

        if (!isListed(mToken)) {
            return uint(Error.MARKET_NOT_LISTED);
        }

        // This should never occur since borrow() should call enterMarketOnBehalf() first
        if (!accountMembership(mToken, borrower)) {
            return uint(Error.MARKET_NOT_ENTERED);
        }

        if (getPrice(mToken) == 0) {
            return uint(Error.PRICE_ERROR);
        }

        // Borrow cap is the minimum of the global cap of the mToken and the cap of the sub-market (if any)
        uint borrowCap = borrowCaps[getAnchorToken(mToken)];
        uint borrowCapSubmarket = borrowCaps[mToken];
        if (borrowCap == 0 || (borrowCapSubmarket != 0 && borrowCapSubmarket < borrowCap)) {
            borrowCap = borrowCapSubmarket;
        }
        // Borrow cap of 0 corresponds to unlimited borrowing
        if (borrowCap != 0) {
            uint totalBorrows = MTokenCommon(mTokenAddress).totalBorrows(mToken);
            uint nextTotalBorrows = add_(totalBorrows, borrowAmount);
            require(nextTotalBorrows < borrowCap, "market borrow cap reached");
        }

        (Error err, , uint shortfall) = getHypotheticalAccountLiquidityInternal(borrower, mToken, 0, borrowAmount);
        if (err != Error.NO_ERROR) {
            return uint(err);
        }
        if (shortfall > 0) {
            return uint(Error.INSUFFICIENT_LIQUIDITY);
        }

        // Keep the flywheel moving
        // Exp memory borrowIndex = Exp({mantissa: MTokenCommon(mTokenAddress).borrowIndex(mToken)});
        // updateMmoBorrowIndex(mToken, borrowIndex);
        // distributeBorrowerMmo(mToken, borrower, borrowIndex);

        return uint(Error.NO_ERROR);
    }

    /**
     * @notice Validates borrow and reverts on rejection. May emit logs.
     * @param mToken Asset whose underlying is being borrowed
     * @param borrower The address borrowing the underlying
     * @param borrowAmount The amount of the underlying asset requested to borrow
     */
    function borrowVerify(uint240 mToken, address borrower, uint borrowAmount) external view {
        // Shh - currently unused
        mToken;
        borrower;
        borrowAmount;

        // Shh - we don't ever want this hook to be marked pure
        if (false) {
            maxAssets;
        }
    }

    /**
     * @notice Checks if the account should be allowed to repay a borrow in the given market
     * @param mToken The market to verify the repay against
     * @param payer The account which would repay the asset
     * @param borrower The account which would borrowed the asset
     * @param repayAmount The amount of the underlying asset the account would repay
     * @return 0 if the repay is allowed, otherwise a semi-opaque error code (See ErrorReporter.sol)
     */
    function repayBorrowAllowed(uint240 mToken, address payer, address borrower, uint repayAmount) external view returns (uint) {
        // Shh - currently unused
        payer;
        borrower;
        repayAmount;

        // ( , , address mTokenAddress) = parseToken(mToken);

        if (!isListed(mToken)) {
            return uint(Error.MARKET_NOT_LISTED);
        }

        // Keep the flywheel moving
        // Exp memory borrowIndex = Exp({mantissa: MTokenCommon(mTokenAddress).borrowIndex(mToken)});
        // updateMmoBorrowIndex(mToken, borrowIndex);
        // distributeBorrowerMmo(mToken, borrower, borrowIndex);

        return uint(Error.NO_ERROR);
    }

    /**
     * @notice Validates repayBorrow and reverts on rejection. May emit logs.
     * @param mToken Asset being repaid
     * @param payer The address repaying the borrow
     * @param borrower The address of the borrower
     * @param actualRepayAmount The amount of underlying being repaid
     * @param borrowerIndex The borrower index before repayment
     */
    function repayBorrowVerify(uint240 mToken, address payer, address borrower, uint actualRepayAmount, uint borrowerIndex) external view {
        // Shh - currently unused
        mToken;
        payer;
        borrower;
        actualRepayAmount;
        borrowerIndex;

        // Shh - we don't ever want this hook to be marked pure
        if (false) {
            maxAssets;
        }
    }

    /**
     * @notice Checks if the liquidation should be allowed to occur
     * @param mTokenBorrowed The mToken in which underlying asset was borrowed by the borrower
     * @param mTokenCollateral The mToken which was used as collateral and will be seized
     * @param liquidator The address repaying the borrow and seizing the collateral
     * @param borrower The address of the borrower
     * @param repayAmount The amount of underlying being repaid
     * @return 0 if the liquidation is allowed, otherwise a semi-opaque error code (See ErrorReporter.sol)
     */
    function liquidateBorrowAllowed(uint240 mTokenBorrowed, uint240 mTokenCollateral, address liquidator, address borrower, uint repayAmount) external view returns (uint) {
        // Shh - currently unused
        liquidator;

        /* Fail if mTokenCollateral is non-fungible (ERC-721) type */
        (MTokenType mTokenType, , ) = parseToken(mTokenCollateral);
        if (mTokenType == MTokenType.ERC721_MTOKEN) {
            return uint(Error.INVALID_TOKEN_TYPE);
        }

        if (!isListed(mTokenBorrowed) || !isListed(mTokenCollateral)) {
            return uint(Error.MARKET_NOT_LISTED);
        }

        /* Fail if borrower not "in" the markets for both mTokenBorrowed and mTokenCollateral */
        if (!accountMembership(mTokenBorrowed, borrower) || !accountMembership(mTokenCollateral, borrower)) {
            return uint(Error.MARKET_NOT_ENTERED);
        }

        /* The borrower must have shortfall in order to be liquidatable */
        (Error err, , uint shortfall) = getAccountLiquidityInternal(borrower);
        if (err != Error.NO_ERROR) {
            return uint(err);
        }
        if (shortfall == 0) {
            return uint(Error.INSUFFICIENT_SHORTFALL);
        }

        /* The liquidator may not repay more than what is allowed by the closeFactor */
        ( , , address mTokenBorrowedAddress) = parseToken(mTokenBorrowed);
        uint borrowBalance = MTokenInterface(mTokenBorrowedAddress).borrowBalanceStored(borrower, mTokenBorrowed);
        uint maxClose = mul_ScalarTruncate(Exp({mantissa: closeFactorMantissa}), borrowBalance);
        if (repayAmount > maxClose) {
            return uint(Error.TOO_MUCH_REPAY);
        }

        return uint(Error.NO_ERROR);
    }

    /**
     * @notice Check if liquidation of non-fungible (ERC-721) mToken collateral is allowed
     * @param mToken The mToken collateral to check
     * @return 0 if the liquidation is allowed, otherwise a semi-opaque error code (See ErrorReporter.sol)
     */
    function liquidateERC721Allowed(uint240 mToken) external view returns (uint)  {
        /* Fail if mToken is not non-fungible (ERC-721) type */
        (MTokenType mTokenType, , address mTokenAddress) = parseToken(mToken);
        if (mTokenType != MTokenType.ERC721_MTOKEN) {
            return uint(Error.INVALID_TOKEN_TYPE);
        }
    
        if (!isListed(mToken)) {
            return uint(Error.MARKET_NOT_LISTED);
        }

        /* Fail if owner not "in" the markets for mToken */
        address owner = MERC721Interface(mTokenAddress).ownerOf(mToken);
        if (!accountMembership(mToken, owner)) {
            return uint(Error.MARKET_NOT_ENTERED);
        }

        /* Fail if mToken cannot be auctioned by sender (liquidator) */
        uint err = auctionAllowed(mToken, msg.sender);
        if (err != uint(Error.NO_ERROR)) {
            return err;
        }

        /* Fail if mToken owner has no shortfall (anymore) */
        uint shortfall;
        (err, , shortfall) = getAccountLiquidity(owner);
        if (err != uint(Error.NO_ERROR) || shortfall == 0) {
            return uint(Error.INSUFFICIENT_SHORTFALL);
        }

        /* Fail if sender (liquidator) is also owner */
        if (msg.sender == owner) {
            return uint(Error.UNAUTHORIZED);
        }

        return uint(Error.NO_ERROR);
    }

    /**
     * @notice Validates liquidateBorrow and reverts on rejection. May emit logs.
     * @param mTokenBorrowed The mToken in which underlying asset was borrowed by the borrower
     * @param mTokenCollateral The mToken which was used as collateral and will be seized
     * @param liquidator The address repaying the borrow and seizing the collateral
     * @param borrower The address of the borrower
     * @param actualRepayAmount The amount of underlying in mTokenBorrowed actually being repaid
     * @param seizeTokens The number of mTokenCollateral tokens seized
     */
    function liquidateBorrowVerify(uint240 mTokenBorrowed, uint240 mTokenCollateral, address liquidator, address borrower, uint actualRepayAmount, uint seizeTokens) external view {
        // Shh - currently unused
        mTokenBorrowed;
        mTokenCollateral;
        liquidator;
        borrower;
        actualRepayAmount;
        seizeTokens;

        // Shh - we don't ever want this hook to be marked pure
        if (false) {
            maxAssets;
        }
    }

    /**
     * @notice Checks if the seizing of assets should be allowed to occur
     * @param mTokenCollateral The mToken which was used as collateral and will be seized
     * @param mTokenBorrowed The mToken in which underlying asset was borrowed by the borrower
     * @param liquidator The address repaying the borrow and seizing the collateral
     * @param borrower The address of the borrower
     * @param seizeTokens The number of collateral tokens to seize
     */
    function seizeAllowed(uint240 mTokenCollateral, uint240 mTokenBorrowed, address liquidator, address borrower, uint seizeTokens) external view returns (uint) {
        // Shh - currently unused
        liquidator;
        seizeTokens;

        ( , , address mTokenCollateralAddress) = parseToken(mTokenCollateral);
        ( , , address mTokenBorrowedAddress) = parseToken(mTokenBorrowed);

        // Pausing is a very serious situation - we revert to sound the alarms
        require(!seizeGuardianPaused[getAnchorToken(mTokenCollateral)], "seize is paused");
        require(!seizeGuardianPaused[mTokenCollateral], "seize is paused");

        if (!isListed(mTokenCollateral) || !isListed(mTokenBorrowed)) {
            return uint(Error.MARKET_NOT_LISTED);
        }

        /* Fail if borrower not "in" the markets for both mTokenBorrowed and mTokenCollateral */
        if (!accountMembership(mTokenBorrowed, borrower) || !accountMembership(mTokenCollateral, borrower)) {
            return uint(Error.MARKET_NOT_ENTERED);
        }

        if (MTokenCommon(mTokenCollateralAddress).mtroller() != MTokenCommon(mTokenBorrowedAddress).mtroller()) {
            return uint(Error.MTROLLER_MISMATCH);
        }

        // Keep the flywheel moving
        // updateMmoSupplyIndex(mTokenCollateral);
        // distributeSupplierMmo(mTokenCollateral, borrower);
        // distributeSupplierMmo(mTokenCollateral, liquidator);

        return uint(Error.NO_ERROR);
    }

    /**
     * @notice Validates seize and reverts on rejection. May emit logs.
     * @param mTokenCollateral The mToken which was used as collateral and will be seized
     * @param mTokenBorrowed The mToken in which underlying asset was borrowed by the borrower
     * @param liquidator The address repaying the borrow and seizing the collateral
     * @param borrower The address of the borrower
     * @param seizeTokens The number of collateral tokens to seize
     */
    function seizeVerify(uint240 mTokenCollateral, uint240 mTokenBorrowed, address liquidator, address borrower, uint seizeTokens) external view {
        // Shh - currently unused
        mTokenCollateral;
        mTokenBorrowed;
        liquidator;
        borrower;
        seizeTokens;

        // Shh - we don't ever want this hook to be marked pure
        if (false) {
            maxAssets;
        }
    }

    /**
     * @notice Checks if the account should be allowed to transfer tokens in the given market
     * @param mToken The market to verify the transfer against
     * @param src The account which sources the mTokens
     * @param dst The account which receives the mTokens
     * @param transferTokens The number of mTokens to transfer
     * @return 0 if the transfer is allowed, otherwise a semi-opaque error code (See ErrorReporter.sol)
     */
    function transferAllowed(uint240 mToken, address src, address dst, uint transferTokens) external view returns (uint) {
        // Shh - currently unused
        dst;

        // Pausing is a very serious situation - we revert to sound the alarms
        require(!transferGuardianPaused[getAnchorToken(mToken)], "transfer is paused");
        require(!transferGuardianPaused[mToken], "transfer is paused");

        // Currently the only consideration is whether or not
        // the src is allowed to redeem this many tokens
        // NB: This also checks mToken validity
        uint allowed = redeemAllowedInternal(mToken, src, transferTokens);
        if (allowed != uint(Error.NO_ERROR)) {
            return allowed;
        }

        // Keep the flywheel moving
        // updateMmoSupplyIndex(mToken);
        // distributeSupplierMmo(mToken, src);
        // distributeSupplierMmo(mToken, dst);

        return uint(Error.NO_ERROR);
    }

    /**
     * @notice Validates transfer and reverts on rejection. May emit logs.
     * @param mToken The mToken being transferred
     * @param src The account which sources the mTokens
     * @param dst The account which receives the mTokens
     * @param transferTokens The number of mTokens to transfer
     */
    function transferVerify(uint240 mToken, address src, address dst, uint transferTokens) external view {
        // Shh - currently unused
        mToken;
        src;
        dst;
        transferTokens;

        // Shh - we don't ever want this hook to be marked pure
        if (false) {
            maxAssets;
        }
    }

    /*** Liquidity/Liquidation Calculations ***/

    /**
     * @dev Local vars for avoiding stack-depth limits in calculating account liquidity.
     *  Note that `mTokenBalance` is the number of mTokens the account owns in the market,
     *  whereas `borrowBalance` is the amount of underlying that the account has borrowed.
     */
    struct AccountLiquidityLocalVars {
        uint sumCollateral;
        uint sumBorrowPlusEffects;
        uint mTokenBalance;
        uint borrowBalance;
        uint exchangeRateMantissa;
        uint oraclePriceMantissa;
        Exp collateralFactor;
        Exp exchangeRate;
        Exp oraclePrice;
        Exp tokensToDenom;
    }

    /**
     * @notice Determine the current account liquidity wrt collateral requirements
     * @param account The account to determine liquidity for
     * @return (possible error code (semi-opaque),
                account liquidity in excess of collateral requirements,
     *          account shortfall below collateral requirements)
     */
    function getAccountLiquidity(address account) public view returns (uint, uint, uint) {
        (Error err, uint liquidity, uint shortfall) = getHypotheticalAccountLiquidityInternal(account, 0, 0, 0);

        return (uint(err), liquidity, shortfall);
    }

    /**
     * @notice Determine the current account liquidity wrt collateral requirements
     * @param account The account to determine liquidity for
     * @return (possible error code,
                account liquidity in excess of collateral requirements,
     *          account shortfall below collateral requirements)
     */
    function getAccountLiquidityInternal(address account) internal view returns (Error, uint, uint) {
        return getHypotheticalAccountLiquidityInternal(account, 0, 0, 0);
    }

    /**
     * @notice Determine what the account liquidity would be if the given amounts were redeemed/borrowed
     * @param account The account to determine liquidity for
     * @param mTokenModify The mToken market to hypothetically redeem/borrow in
     * @param redeemTokens The number of mTokens to hypothetically redeem
     * @param borrowAmount The amount of underlying to hypothetically borrow
     * @return (possible error code (semi-opaque),
                hypothetical account liquidity in excess of collateral requirements,
     *          hypothetical account shortfall below collateral requirements)
     */
    function getHypotheticalAccountLiquidity(
        address account,
        uint240 mTokenModify,
        uint redeemTokens,
        uint borrowAmount) public view returns (uint, uint, uint) {
        (Error err, uint liquidity, uint shortfall) = getHypotheticalAccountLiquidityInternal(account, mTokenModify, redeemTokens, borrowAmount);
        return (uint(err), liquidity, shortfall);
    }

    /**
     * @notice Determine what the account liquidity would be if the given amounts were redeemed/borrowed
     * @param account The account to determine liquidity for
     * @param mTokenModify The mToken market to hypothetically redeem/borrow in
     * @param redeemTokens The number of mTokens to hypothetically redeem
     * @param borrowAmount The amount of underlying to hypothetically borrow
     * @dev Note that we calculate the exchangeRateStored for each collateral mToken using stored data,
     *  without calculating accumulated interest.
     * @return (possible error code,
                hypothetical account liquidity in excess of collateral requirements,
     *          hypothetical account shortfall below collateral requirements)
     */
    function getHypotheticalAccountLiquidityInternal(
        address account,
        uint240 mTokenModify,
        uint redeemTokens,
        uint borrowAmount) internal view returns (Error, uint, uint) {

        AccountLiquidityLocalVars memory vars; // Holds all our calculation results
        uint oErr;

        // For each asset the account is in
        uint240[] memory assets = accountAssets[account];
        for (uint i = 0; i < assets.length; i++) {

            uint240 asset = assets[i];
            ( , , address assetAddress) = parseToken(asset);

            // Read the balances and exchange rate from the mToken
            (oErr, vars.mTokenBalance, vars.borrowBalance, vars.exchangeRateMantissa) = MTokenInterface(assetAddress).getAccountSnapshot(account, asset);
            if (oErr != 0) { // semi-opaque error code, we assume NO_ERROR == 0 is invariant between upgrades
                return (Error.SNAPSHOT_ERROR, 0, 0);
            }
            vars.collateralFactor = Exp({mantissa: collateralFactorMantissa(asset)});
            vars.exchangeRate = Exp({mantissa: vars.exchangeRateMantissa});

            // Get the normalized price of the asset
            vars.oraclePriceMantissa = getPrice(asset);
            if (vars.oraclePriceMantissa == 0) {
                return (Error.PRICE_ERROR, 0, 0);
            }
            vars.oraclePrice = Exp({mantissa: vars.oraclePriceMantissa});

            // Pre-compute a conversion factor from tokens -> ether (normalized price value)
            vars.tokensToDenom = mul_(mul_(vars.collateralFactor, vars.exchangeRate), vars.oraclePrice);

            // sumCollateral += tokensToDenom * mTokenBalance
            vars.sumCollateral = mul_ScalarTruncateAddUInt(vars.tokensToDenom, vars.mTokenBalance, vars.sumCollateral);

            // sumBorrowPlusEffects += oraclePrice * borrowBalance
            vars.sumBorrowPlusEffects = mul_ScalarTruncateAddUInt(vars.oraclePrice, vars.borrowBalance, vars.sumBorrowPlusEffects);

            // Calculate effects of interacting with mTokenModify
            if (asset == mTokenModify) {
                // redeem effect
                // sumBorrowPlusEffects += tokensToDenom * redeemTokens
                vars.sumBorrowPlusEffects = mul_ScalarTruncateAddUInt(vars.tokensToDenom, redeemTokens, vars.sumBorrowPlusEffects);

                // borrow effect
                // sumBorrowPlusEffects += oraclePrice * borrowAmount
                vars.sumBorrowPlusEffects = mul_ScalarTruncateAddUInt(vars.oraclePrice, borrowAmount, vars.sumBorrowPlusEffects);
            }
        }

        // These are safe, as the underflow condition is checked first
        if (vars.sumCollateral > vars.sumBorrowPlusEffects) {
            return (Error.NO_ERROR, vars.sumCollateral - vars.sumBorrowPlusEffects, 0);
        } else {
            return (Error.NO_ERROR, 0, vars.sumBorrowPlusEffects - vars.sumCollateral);
        }
    }

    /**
     * @notice Calculate number of tokens of collateral asset to seize given an underlying amount
     * @dev Used in liquidation (called in mToken.liquidateBorrowFresh)
     * @param mTokenBorrowed The borrowed mToken
     * @param mTokenCollateral The collateral mToken
     * @param actualRepayAmount The amount of mTokenBorrowed underlying to convert into mTokenCollateral tokens
     * @return (errorCode, number of mTokenCollateral tokens to be seized in a liquidation)
     */
    function liquidateCalculateSeizeTokens(uint240 mTokenBorrowed, uint240 mTokenCollateral, uint actualRepayAmount) external view returns (uint, uint) {
        if (!isListed(mTokenBorrowed) || !isListed(mTokenCollateral)) {
            return (uint(Error.MARKET_NOT_LISTED), 0);
        }
        /* Read oracle prices for borrowed and collateral markets */
        uint priceBorrowedMantissa = getPrice(mTokenBorrowed);
        uint priceCollateralMantissa = getPrice(mTokenCollateral);
        if (priceBorrowedMantissa == 0 || priceCollateralMantissa == 0) {
            return (uint(Error.PRICE_ERROR), 0);
        }

        /*
         * Get the exchange rate and calculate the number of collateral tokens to seize:
         *  seizeAmount = actualRepayAmount * liquidationIncentive * priceBorrowed / priceCollateral
         *  seizeTokens = seizeAmount / exchangeRate
         *   = actualRepayAmount * (liquidationIncentive * priceBorrowed) / (priceCollateral * exchangeRate)
         */
        ( , , address mTokenCollateralAddress) = parseToken(mTokenCollateral);
        uint exchangeRateMantissa = MTokenInterface(mTokenCollateralAddress).exchangeRateStored(mTokenCollateral); // Note: reverts on error
        uint seizeTokens;
        Exp memory numerator;
        Exp memory numerator2;
        Exp memory denominator;

/* old calculation (Compound version)
        numerator = mul_(Exp({mantissa: liquidationIncentiveMantissa}), Exp({mantissa: priceBorrowedMantissa}));
        denominator = mul_(Exp({mantissa: priceCollateralMantissa}), Exp({mantissa: exchangeRateMantissa}));
        ratio = div_(numerator, denominator);

        seizeTokens = mul_ScalarTruncate(ratio, actualRepayAmount);
*/

/* new calculation avoids underflow due to truncation for cases where seizeTokens == 1 */
        numerator = mul_(Exp({mantissa: liquidationIncentiveMantissa}), Exp({mantissa: priceBorrowedMantissa}));
        numerator2 = mul_(numerator, actualRepayAmount);
        denominator = mul_(Exp({mantissa: priceCollateralMantissa}), Exp({mantissa: exchangeRateMantissa}));
        seizeTokens = truncate(div_(numerator2, denominator));

        return (uint(Error.NO_ERROR), seizeTokens);
    }

    // /**
    //  * @notice Return all of the markets
    //  * @dev The automatic getter may be used to access an individual market.
    //  * @return The list of market addresses
    //  */
    // not implemented for now
    //function getAllMarkets() public view returns (MToken[] memory) {
    //    return allMarkets;
    //}

    /**
     * @notice Returns the current block number
     * @dev Can be overriden for test purposes.
     * @return uint The current block number
     */
    function getBlockNumber() public view returns (uint) {
        return block.number;
    }

    /**
     * @notice Returns the current price of the given mToken asset from the oracle
     * @param mToken The mToken whose price to get
     * @return uint The underlying asset price mantissa (scaled by 1e18). For fungible underlying tokens that
     * means e.g. if one single underlying token costs 1 Wei then the asset price mantissa should be 1e18. 
     * In case of underlying (ERC-721 compliant) NFTs one NFT always corresponds to oneUnit = 1e18 
     * internal calculatory units (see MTokenInterfaces.sol), therefore if e.g. one NFT costs 0.1 ETH 
     * then the asset price mantissa returned here should be 0.1e18.
     * Zero means the price is unavailable.
     */
    function getPrice(uint240 mToken) public view returns (uint) {
        require(mToken != getAnchorToken(mToken), "no getPrice for anchor token");
        require(isListed(mToken), "mToken not listed");
        ( , , address mTokenAddress) = parseToken(mToken);
        address uAddress = MTokenCommon(mTokenAddress).underlyingContract();

        if (uAddress == underlyingContractETH()) {
            // Return price = 1.0 for ETH
            return 1.0e18;            
        }

        uint256 uTokenID = MTokenCommon(mTokenAddress).underlyingIDs(mToken);
        return oracle.getUnderlyingPrice(uAddress, uTokenID);
    }

/******* NOT PROPERLY CHECKED YET BELOW THIS POINT *****************/

    /*** Mmo Distribution ***/

    /**
     * @notice Set MMO speed for a single market
     * @param mToken The market whose MMO speed to update
     * @param mmoSpeed New MMO speed for market
     */
    function setMmoSpeedInternal(uint240 mToken, uint mmoSpeed) internal {
        uint currentMmoSpeed = mmoSpeeds[mToken];
        if (currentMmoSpeed != 0) {
            // note that MMO speed could be set to 0 to halt liquidity rewards for a market
            ( ,  , address mTokenAddress) = parseToken(mToken);
            Exp memory borrowIndex = Exp({mantissa: MTokenCommon(mTokenAddress).borrowIndex(mToken)});
            updateMmoSupplyIndex(mToken);
            updateMmoBorrowIndex(mToken, borrowIndex);
        } else if (mmoSpeed != 0) {
            // Add the MMO market
            require(isListed(mToken), "mmo market is not listed");

            if (mmoSupplyState[mToken].index == 0 && mmoSupplyState[mToken].block == 0) {
                mmoSupplyState[mToken] = MmoMarketState({
                    index: mmoInitialIndex,
                    block: safe32(getBlockNumber(), "block number exceeds 32 bits")
                });
            }

            if (mmoBorrowState[mToken].index == 0 && mmoBorrowState[mToken].block == 0) {
                mmoBorrowState[mToken] = MmoMarketState({
                    index: mmoInitialIndex,
                    block: safe32(getBlockNumber(), "block number exceeds 32 bits")
                });
            }
        }

        if (currentMmoSpeed != mmoSpeed) {
            mmoSpeeds[mToken] = mmoSpeed;
            emit MmoSpeedUpdated(mToken, mmoSpeed);
        }
    }

    /**
     * @notice Accrue MMO to the market by updating the supply index
     * @param mToken The market whose supply index to update
     */
    function updateMmoSupplyIndex(uint240 mToken) internal {
        MmoMarketState storage supplyState = mmoSupplyState[mToken];
        uint supplySpeed = mmoSpeeds[mToken];
        uint blockNumber = getBlockNumber();
        uint deltaBlocks = sub_(blockNumber, uint(supplyState.block));
        if (deltaBlocks > 0 && supplySpeed > 0) {
            ( , , address mTokenAddress) = parseToken(mToken);
            uint supplyTokens = MTokenCommon(mTokenAddress).totalSupply(mToken);
            uint mmoAccrued = mul_(deltaBlocks, supplySpeed);
            Double memory ratio = supplyTokens > 0 ? fraction(mmoAccrued, supplyTokens) : Double({mantissa: 0});
            Double memory index = add_(Double({mantissa: supplyState.index}), ratio);
            mmoSupplyState[mToken] = MmoMarketState({
                index: safe224(index.mantissa, "new index exceeds 224 bits"),
                block: safe32(blockNumber, "block number exceeds 32 bits")
            });
        } else if (deltaBlocks > 0) {
            supplyState.block = safe32(blockNumber, "block number exceeds 32 bits");
        }
    }

    /**
     * @notice Accrue MMO to the market by updating the borrow index
     * @param mToken The market whose borrow index to update
     */
    function updateMmoBorrowIndex(uint240 mToken, Exp memory marketBorrowIndex) internal {
        MmoMarketState storage borrowState = mmoBorrowState[mToken];
        uint borrowSpeed = mmoSpeeds[mToken];
        uint blockNumber = getBlockNumber();
        uint deltaBlocks = sub_(blockNumber, uint(borrowState.block));
        if (deltaBlocks > 0 && borrowSpeed > 0) {
            ( , , address mTokenAddress) = parseToken(mToken);
            uint borrowAmount = div_(MTokenCommon(mTokenAddress).totalBorrows(mToken), marketBorrowIndex);
            uint mmoAccrued = mul_(deltaBlocks, borrowSpeed);
            Double memory ratio = borrowAmount > 0 ? fraction(mmoAccrued, borrowAmount) : Double({mantissa: 0});
            Double memory index = add_(Double({mantissa: borrowState.index}), ratio);
            mmoBorrowState[mToken] = MmoMarketState({
                index: safe224(index.mantissa, "new index exceeds 224 bits"),
                block: safe32(blockNumber, "block number exceeds 32 bits")
            });
        } else if (deltaBlocks > 0) {
            borrowState.block = safe32(blockNumber, "block number exceeds 32 bits");
        }
    }

    /**
     * @notice Calculate MMO accrued by a supplier and possibly transfer it to them
     * @param mToken The market in which the supplier is interacting
     * @param supplier The address of the supplier to distribute MMO to
     */
    function distributeSupplierMmo(uint240 mToken, address supplier) internal {
        MmoMarketState storage supplyState = mmoSupplyState[mToken];
        Double memory supplyIndex = Double({mantissa: supplyState.index});
        Double memory supplierIndex = Double({mantissa: mmoSupplierIndex[mToken][supplier]});
        mmoSupplierIndex[mToken][supplier] = supplyIndex.mantissa;

        if (supplierIndex.mantissa == 0 && supplyIndex.mantissa > 0) {
            supplierIndex.mantissa = mmoInitialIndex;
        }

        Double memory deltaIndex = sub_(supplyIndex, supplierIndex);
        ( , , address mTokenAddress) = parseToken(mToken);
        uint supplierTokens = MTokenInterface(mTokenAddress).balanceOf(supplier, mToken);
        uint supplierDelta = mul_(supplierTokens, deltaIndex);
        uint supplierAccrued = add_(mmoAccrued[supplier], supplierDelta);
        mmoAccrued[supplier] = supplierAccrued;
        emit DistributedSupplierMmo(mToken, supplier, supplierDelta, supplyIndex.mantissa);
    }

    /**
     * @notice Calculate MMO accrued by a borrower and possibly transfer it to them
     * @dev Borrowers will not begin to accrue until after the first interaction with the protocol.
     * @param mToken The market in which the borrower is interacting
     * @param borrower The address of the borrower to distribute MMO to
     */
    function distributeBorrowerMmo(uint240 mToken, address borrower, Exp memory marketBorrowIndex) internal {
        MmoMarketState storage borrowState = mmoBorrowState[mToken];
        Double memory borrowIndex = Double({mantissa: borrowState.index});
        Double memory borrowerIndex = Double({mantissa: mmoBorrowerIndex[mToken][borrower]});
        mmoBorrowerIndex[mToken][borrower] = borrowIndex.mantissa;

        if (borrowerIndex.mantissa > 0) {
            Double memory deltaIndex = sub_(borrowIndex, borrowerIndex);
            ( , , address mTokenAddress) = parseToken(mToken);
            uint borrowerAmount = div_(MTokenInterface(mTokenAddress).borrowBalanceStored(borrower, mToken), marketBorrowIndex);
            uint borrowerDelta = mul_(borrowerAmount, deltaIndex);
            uint borrowerAccrued = add_(mmoAccrued[borrower], borrowerDelta);
            mmoAccrued[borrower] = borrowerAccrued;
            emit DistributedBorrowerMmo(mToken, borrower, borrowerDelta, borrowIndex.mantissa);
        }
    }

    /**
     * @notice Calculate additional accrued MMO for a contributor since last accrual
     * @param contributor The address to calculate contributor rewards for
     */
    function updateContributorRewards(address contributor) public {
        uint mmoSpeed = mmoContributorSpeeds[contributor];
        uint blockNumber = getBlockNumber();
        uint deltaBlocks = sub_(blockNumber, lastContributorBlock[contributor]);
        if (deltaBlocks > 0 && mmoSpeed > 0) {
            uint newAccrued = mul_(deltaBlocks, mmoSpeed);
            uint contributorAccrued = add_(mmoAccrued[contributor], newAccrued);

            mmoAccrued[contributor] = contributorAccrued;
            lastContributorBlock[contributor] = blockNumber;
        }
    }

    // /**
    //  * @notice Claim all the mmo accrued by holder in all markets
    //  * @param holder The address to claim MMO for
    //  */
    // This is not yet implemented
    // function claimMmo(address holder) public {
    //    return claimMmo(holder, allMarkets);
    // }

    /**
     * @notice Claim all the mmo accrued by holder in the specified markets
     * @param holder The address to claim MMO for
     * @param mTokens The list of markets to claim MMO in
     */
    function claimMmo(address holder, uint240[] memory mTokens) public {
        address[] memory holders = new address[](1);
        holders[0] = holder;
        claimMmo(holders, mTokens, true, true);
    }

    /**
     * @notice Claim all mmo accrued by the holders
     * @param holders The addresses to claim MMO for
     * @param mTokens The list of markets to claim MMO in
     * @param borrowers Whether or not to claim MMO earned by borrowing
     * @param suppliers Whether or not to claim MMO earned by supplying
     */
    function claimMmo(address[] memory holders, uint240[] memory mTokens, bool borrowers, bool suppliers) public {
        for (uint i = 0; i < mTokens.length; i++) {
            uint240 mToken = mTokens[i];
            require(isListed(mToken), "market must be listed");
            if (borrowers == true) {
                ( , , address mTokenAddress) = parseToken(mToken);
                Exp memory borrowIndex = Exp({mantissa: MTokenCommon(mTokenAddress).borrowIndex(mToken)});
                updateMmoBorrowIndex(mToken, borrowIndex);
                for (uint j = 0; j < holders.length; j++) {
                    distributeBorrowerMmo(mToken, holders[j], borrowIndex);
                    mmoAccrued[holders[j]] = grantMmoInternal(holders[j], mmoAccrued[holders[j]]);
                }
            }
            if (suppliers == true) {
                updateMmoSupplyIndex(mToken);
                for (uint j = 0; j < holders.length; j++) {
                    distributeSupplierMmo(mToken, holders[j]);
                    mmoAccrued[holders[j]] = grantMmoInternal(holders[j], mmoAccrued[holders[j]]);
                }
            }
        }
    }

    /**
     * @notice Transfer MMO to the user
     * @dev Note: If there is not enough MMO, we do not perform the transfer all.
     * @param user The address of the user to transfer MMO to
     * @param amount The amount of MMO to (possibly) transfer
     * @return The amount of MMO which was NOT transferred to the user
     */
    function grantMmoInternal(address user, uint amount) internal returns (uint) {
        Mmo mmo = Mmo(getMmoAddress());
        uint mmoRemaining = mmo.balanceOf(address(this));
        if (amount > 0 && amount <= mmoRemaining) {
            mmo.transfer(user, amount);
            return 0;
        }
        return amount;
    }

    /*** Mmo Distribution Admin ***/

    /**
     * @notice Transfer MMO to the recipient
     * @dev Note: If there is not enough MMO, we do not perform the transfer all.
     * @param recipient The address of the recipient to transfer MMO to
     * @param amount The amount of MMO to (possibly) transfer
     */
    function _grantMmo(address recipient, uint amount) public {
        require(msg.sender == getAdmin(), "only admin can grant mmo");
        uint amountLeft = grantMmoInternal(recipient, amount);
        require(amountLeft == 0, "insufficient mmo for grant");
        emit MmoGranted(recipient, amount);
    }

    /**
     * @notice Set MMO speed for a single market
     * @param mToken The market whose MMO speed to update
     * @param mmoSpeed New MMO speed for market
     */
    function _setMmoSpeed(uint240 mToken, uint mmoSpeed) public {
        require(msg.sender == getAdmin(), "only admin can set mmo speed");
        setMmoSpeedInternal(mToken, mmoSpeed);
    }

    /**
     * @notice Set MMO speed for a single contributor
     * @param contributor The contributor whose MMO speed to update
     * @param mmoSpeed New MMO speed for contributor
     */
    function _setContributorMmoSpeed(address contributor, uint mmoSpeed) public {
        require(msg.sender == getAdmin(), "only admin can set mmo speed");

        // note that MMO speed could be set to 0 to halt liquidity rewards for a contributor
        updateContributorRewards(contributor);
        if (mmoSpeed == 0) {
            // release storage
            delete lastContributorBlock[contributor];
        } else {
            lastContributorBlock[contributor] = getBlockNumber();
        }
        mmoContributorSpeeds[contributor] = mmoSpeed;

        emit ContributorMmoSpeedUpdated(contributor, mmoSpeed);
    }

    /**
     * @notice Return the address of the MMO token
     * @return The address of MMO
     */
    function getMmoAddress() public view returns (address) {
        return mmoTokenAddress;
    }
}

pragma solidity ^0.5.16;

import "./MTokenTest_coins.sol";

contract PriceOracle {
    /// @notice Indicator that this is a PriceOracle contract (for inspection)
    bool public constant isPriceOracle = true;

    /**
      * @notice Get the price of an underlying token
      * @param underlyingToken The address of the underlying token contract
      * @param tokenID The ID of the underlying token if it is a NFT (0 for fungible tokens)
      * @return The underlying asset price mantissa (scaled by 1e18). For fungible underlying tokens that
      * means e.g. if one single underlying token costs 1 Wei then the asset price mantissa should be 1e18. 
      * In case of underlying (ERC-721 compliant) NFTs one NFT always corresponds to oneUnit = 1e18 
      * internal calculatory units (see MTokenInterfaces.sol), therefore if e.g. one NFT costs 0.1 ETH 
      * then the asset price mantissa returned here should be 0.1e18.
      * Zero means the price is unavailable.
      */
    function getUnderlyingPrice(address underlyingToken, uint256 tokenID) public view returns (uint);
}

contract PriceOracleV0_1 is PriceOracle {

    event NewCollectionFloorPrice(uint oldFloorPrice, uint newFloorPrice);

    address admin;
    TestNFT glassesContract;
    IERC721 collectionContract;
    uint collectionFloorPrice;

    constructor(address _admin, TestNFT _glassesContract, IERC721 _collectionContract) public {
        admin = _admin;
        glassesContract = _glassesContract;
        collectionContract = _collectionContract;
    }

    function getUnderlyingPrice(address underlyingToken, uint256 tokenID) public view returns (uint) {
        tokenID;
        if (underlyingToken == address(uint160(-1))) {
            return 1.0e18; // relative price of MEther token is 1.0 (1 token = 1 Wei)
        }
        else if (underlyingToken == address(glassesContract)) {
            return glassesContract.price(); // one unit (1e18) of NFT price in wei
        }
        else if (underlyingToken == address(collectionContract)) {
            return collectionFloorPrice; // one unit (1e18) of NFT price in wei
        }
        else {
            return 0;
        }
    }

    function _setCollectionFloorPrice(uint newFloorPrice) external {
        require(msg.sender == admin, "only admin");
        uint oldFloorPrice = collectionFloorPrice;
        collectionFloorPrice = newFloorPrice;

        emit NewCollectionFloorPrice(oldFloorPrice, newFloorPrice);
    }
}

contract PriceOracleV0_2 is PriceOracleV0_1 {

    event NewIndividualPrice(uint256 tokenID, uint oldPrice, uint newPrice);

    mapping (uint256 => uint256) individualPrices;

    constructor(address _admin, TestNFT _glassesContract, IERC721 _collectionContract) PriceOracleV0_1(_admin, _glassesContract, _collectionContract) public {
    }

    function getUnderlyingPrice(address underlyingToken, uint256 tokenID) public view returns (uint) {
        if (underlyingToken == address(uint160(-1))) {
            return 1.0e18; // relative price of MEther token is 1.0 (1 token = 1 Wei)
        }
        else if (underlyingToken == address(glassesContract)) {
            return glassesContract.price(); // one unit (1e18) of NFT price in wei
        }
        else if (underlyingToken == address(collectionContract)) {
            uint collection = collectionFloorPrice;
            uint individual = individualPrices[tokenID];
            return (individual > collection ? individual : collection); // one unit (1e18) of NFT price in wei
        }
        else {
            return 0;
        }
    }

    function _setIndividualPrice(uint256 tokenID, uint newPrice) external {
        require(msg.sender == admin, "only admin");
        uint oldPrice = individualPrices[tokenID];
        if (newPrice != oldPrice) {
            individualPrices[tokenID] = newPrice;
            emit NewIndividualPrice(tokenID, oldPrice, newPrice);
        }
    }
}

pragma solidity ^0.5.16;

import "./MtrollerInterface.sol";
import "./MTokenInterfaces.sol";
import "./MTokenStorage.sol";
import "./ErrorReporter.sol";
import "./compound/Exponential.sol";
import "./open-zeppelin/token/ERC721/IERC721.sol";

contract TokenAuction is Exponential, TokenErrorReporter {

    event NewAuctionOffer(uint240 tokenID, address offeror, uint256 totalOfferAmount);
    event AuctionOfferCancelled(uint240 tokenID, address offeror, uint256 cancelledOfferAmount);
    event HighestOfferAccepted(uint240 tokenID, address offeror, uint256 acceptedOfferAmount, uint256 auctioneerTokens, uint256 oldOwnerTokens);
    event AuctionRefund(address beneficiary, uint256 amount);

    struct Bidding {
        mapping (address => uint256) offers;
        mapping (address => uint256) offerIndex;
        uint256 nextOffer;
        mapping (uint256 => mapping (uint256 => address)) maxOfferor;
    }

    bool internal _notEntered; // re-entrancy check flag
    
    MEtherUserInterface public paymentToken;
    MtrollerUserInterface public mtroller;

    mapping (uint240 => Bidding) public biddings;

    // ETH account for each participant
    mapping (address => uint256) public refunds;

    constructor(MtrollerUserInterface _mtroller, MEtherUserInterface _mEtherPaymentToken) public
    {
        mtroller = _mtroller;
        paymentToken = _mEtherPaymentToken;
        _notEntered = true; // Start true prevents changing from zero to non-zero (smaller gas cost)
    }

    /**
        @notice Increase a currently pending offer for _mToken. Should only be called by the _mToken 
        contract, not the user directly. If _mToken is the anchorToken then it is a collection offer.
        If _directSale == true the underlying NFT will be sold directly to _bidder instead of adding
        a new bid. In this case it is required to approve this contract to transfer the _mToken before 
        calling this function. 
    */
    function addOfferETH(
        uint240 _mToken,
        address _bidder,
        address payable _oldOwner,
        bool _directSale
    )
        external
        nonReentrant
        payable
        returns (uint256)
    {
        require (msg.value > 0, "No payment sent");
        ( , , address _tokenAddress) = mtroller.parseToken(_mToken);
        require(msg.sender == _tokenAddress, "Only token contract");

        uint256 _oldOffer = biddings[_mToken].offers[_bidder];
        uint256 _newOffer = _oldOffer + msg.value;

        /* Check if auction is allowed by mtroller. For collection offers only check if mToken is listed. 
           For specific offers allow instant sale if _directSale == true */
        uint240 _anchorToken = mtroller.getAnchorToken(_tokenAddress);
        if (_mToken == _anchorToken) {
            mtroller.collateralFactorMantissa(_mToken); // reverts if _mToken is not listed
        }
        else {
            /* more extensive checks. Reverts if mToken currently does not exist (e.g. has been redeemed) */
            require(mtroller.auctionAllowed(_mToken, _bidder) == uint(Error.NO_ERROR), "Auction not allowed");
            /* if _directSale == true, we do not enter the bid but sell directly */
            if (_directSale) {
                if (_oldOffer > 0) {
                    require(cancelOfferInternal(_mToken, _bidder) == _oldOffer, "Could not cancel offer");
                }
                ( , uint256 oldOwnerTokens) = processPaymentInternal(_oldOwner, _newOffer, _oldOwner, 0);
                redeemFromAndTransfer(_mToken, _tokenAddress, _bidder);
                emit HighestOfferAccepted(_mToken, _bidder, _newOffer, 0, oldOwnerTokens);
                return _newOffer; // return sale price for verification purposes
            }
        }

        /* the new offer is entered normally */
        if (_oldOffer == 0) {
            uint256 _nextIndex = biddings[_mToken].nextOffer;
            biddings[_mToken].offerIndex[_bidder] = _nextIndex;
            biddings[_mToken].nextOffer = _nextIndex + 1;
        }
        _updateOffer(_mToken, biddings[_mToken].offerIndex[_bidder], _bidder, _newOffer);
        emit NewAuctionOffer(_mToken, _bidder, _newOffer);
        return 0;
    }

    /**
        @notice Cancel any existing offer of the sender for _mToken and prepare refund.
    */
    function cancelOffer(
        uint240 _mToken
    )
        public
        nonReentrant
    {
        // // for later version: if sender is the highest bidder try to start grace period 
        // // and do not allow to cancel bid during grace period (+ 2 times preferred liquidator delay)
        // if (msg.sender == getMaxOfferor(_mToken)) {
        //     ( , , address _mTokenAddress) = mtroller.parseToken(_mToken);
        //     MERC721Interface(_mTokenAddress).startGracePeriod(_mToken);
        // }
        uint256 _oldOffer = cancelOfferInternal(_mToken, msg.sender);
        refunds[msg.sender] += _oldOffer;
        emit AuctionOfferCancelled(_mToken, msg.sender, _oldOffer);
    }
    
    /**
        @notice Accepts the highest currently active offer for _mToken, taking into account both specific
        offers for that _mToken and any active offers for the whole collection. If _favoriteBidder is
        nonzero, then the _mToken is sold to that address instead of the highest bidder.
        Required: approve this contract to transfer the _mToken before calling this function. 
        Should only be called by the _mToken contract, not the user directly. 
    */
    function acceptHighestOffer(
        uint240 _mToken,
        address payable _oldOwner,
        address payable _auctioneer,
        uint256 _auctioneerFeeMantissa,
        uint256 _minimumPrice,
        address _favoriteBidder
    )
        external
        nonReentrant
        returns (address _maxOfferor, uint256 _maxOffer, uint256 auctioneerTokens, uint256 oldOwnerTokens)
    {
        require(mtroller.auctionAllowed(_mToken, _auctioneer) == uint(Error.NO_ERROR), "Auction not allowed");
        ( , , address _tokenAddress) = mtroller.parseToken(_mToken);
        require(msg.sender == _tokenAddress, "Only token contract");

        if (_favoriteBidder == address(0)) {
            /* if no favorite bidder, check for and handle highest offer (collection or specific) */
            uint256 _maxAllOffers = getMaxOffer(_mToken);
            require(_maxAllOffers > 0, "No valid offer found");
            uint240 _anchorToken = mtroller.getAnchorToken(_tokenAddress);
            if (_maxAllOffers > getMaxOffer(_anchorToken)) {
                _maxOfferor = getMaxOfferor(_mToken); // this should never revert here
                _maxOffer = cancelOfferInternal(_mToken, _maxOfferor);
            }
            else {
                _maxOfferor = getMaxOfferor(_anchorToken); // this should never revert here
                _maxOffer = cancelOfferInternal(_anchorToken, _maxOfferor);
            }
        }
        else {
            /* otherwise sell to the favorite bidder */
            _maxOfferor = _favoriteBidder;
            uint240 _anchorToken = mtroller.getAnchorToken(_tokenAddress);
            if (getOffer(_anchorToken, _maxOfferor) > getOffer(_mToken, _maxOfferor))
            {
                _maxOffer = cancelOfferInternal(_anchorToken, _maxOfferor); // reverts if favorite bidder has no active offer
            }
            else {
                _maxOffer = cancelOfferInternal(_mToken, _maxOfferor); // reverts if favorite bidder has no active offer
            }
        }
        require(_maxOffer >= _minimumPrice, "Best offer too low");

        /* process payment, reverts on error */
        (auctioneerTokens, oldOwnerTokens) = processPaymentInternal(_oldOwner, _maxOffer, _auctioneer, _auctioneerFeeMantissa);

        /* redeem _mToken and transfer underlying to _maxOfferor (reverts on error) */
        redeemFromAndTransfer(_mToken, _tokenAddress, _maxOfferor);

        emit HighestOfferAccepted(_mToken, _maxOfferor, _maxOffer, auctioneerTokens, oldOwnerTokens);
        
        return (_maxOfferor, _maxOffer, auctioneerTokens, oldOwnerTokens);
    }

    function redeemFromAndTransfer(uint240 _mToken, address _tokenAddress, address _beneficiary) internal {
        MERC721Interface _mTokenContract = MERC721Interface(_tokenAddress);
        MTokenV1Storage _mTokenStorage = MTokenV1Storage(_tokenAddress);
        uint256 _underlyingID = _mTokenStorage.underlyingIDs(_mToken);
        _mTokenContract.safeTransferFrom(_mTokenContract.ownerOf(_mToken), address(this), _mToken);
        require(_mTokenContract.redeem(_mToken) == uint(Error.NO_ERROR), "Redeem failed");
        IERC721(_mTokenStorage.underlyingContract()).safeTransferFrom(address(this), _beneficiary, _underlyingID);
        require(IERC721(_mTokenStorage.underlyingContract()).ownerOf(_underlyingID) == _beneficiary, "Transfer failed");
    }

    function payOut(address payable beneficiary, uint256 amount) internal returns (uint256 mintedMTokens) {
        // try to accrue mEther interest first; if it fails, pay out full amount in mEther
        uint240 mToken = MTokenV1Storage(address(paymentToken)).thisFungibleMToken();
        uint err = paymentToken.accrueInterest(mToken);
        if (err != uint(Error.NO_ERROR)) {
            mintedMTokens = paymentToken.mintTo.value(amount)(beneficiary);
            return mintedMTokens;
        }

        // if beneficiary has outstanding borrows, repay as much as possible (revert on error)
        uint256 borrowBalance = paymentToken.borrowBalanceStored(beneficiary, mToken);
        if (borrowBalance > amount) {
            borrowBalance = amount;
        }
        if (borrowBalance > 0) {
            require(paymentToken.repayBorrowBehalf.value(borrowBalance)(beneficiary) == borrowBalance, "Borrow repayment failed");
        }

        // payout any surplus: in cash (ETH) if beneficiary has no shortfall; otherwise in mEther
        if (amount > borrowBalance) {
            uint256 shortfall;
            (err, , shortfall) = MtrollerInterface(MTokenV1Storage(address(paymentToken)).mtroller()).getAccountLiquidity(beneficiary);
            if (err == uint(Error.NO_ERROR) && shortfall == 0) {
                (bool success, ) = beneficiary.call.value(amount - borrowBalance)("");
                require(success, "ETH Transfer failed");
                mintedMTokens = 0;
            }
            else {
                mintedMTokens = paymentToken.mintTo.value(amount - borrowBalance)(beneficiary);
            }
        }
    }

    function processPaymentInternal(
        address payable _oldOwner,
        uint256 _price,
        address payable _broker,
        uint256 _brokerFeeMantissa
    )
        internal
        returns (uint256 brokerTokens, uint256 oldOwnerTokens) 
    {
        require(_oldOwner != address(0), "Invalid owner address");
        require(_price > 0, "Invalid price");
        
        /* calculate fees for protocol and add it to protocol's reserves (in underlying cash) */
        uint256 _amountLeft = _price;
        Exp memory _feeShare = Exp({mantissa: paymentToken.getProtocolAuctionFeeMantissa()});
        (MathError _mathErr, uint256 _fee) = mulScalarTruncate(_feeShare, _price);
        require(_mathErr == MathError.NO_ERROR, "Invalid protocol fee");
        if (_fee > 0) {
            (_mathErr, _amountLeft) = subUInt(_price, _fee);
            require(_mathErr == MathError.NO_ERROR, "Invalid protocol fee");
            paymentToken._addReserves.value(_fee)();
        }

        /* calculate and pay broker's fee (if any) by minting corresponding paymentToken amount */
        _feeShare = Exp({mantissa: _brokerFeeMantissa});
        (_mathErr, _fee) = mulScalarTruncate(_feeShare, _price);
        require(_mathErr == MathError.NO_ERROR, "Invalid broker fee");
        if (_fee > 0) {
            require(_broker != address(0), "Invalid broker address");
            (_mathErr, _amountLeft) = subUInt(_amountLeft, _fee);
            require(_mathErr == MathError.NO_ERROR, "Invalid broker fee");
            brokerTokens = payOut(_broker, _fee);
        }

        /* 
         * Pay anything left to the old owner by minting a corresponding paymentToken amount. In case 
         * of liquidation these paymentTokens can be liquidated in a next step. 
         * NEVER pay underlying cash to the old owner here!!
         */
        if (_amountLeft > 0) {
            oldOwnerTokens = payOut(_oldOwner, _amountLeft);
        }
    }
    
    function cancelOfferInternal(
        uint240 _mToken,
        address _offeror
    )
        internal
        returns (uint256 _oldOffer)
    {
        _oldOffer = biddings[_mToken].offers[_offeror];
        require (_oldOffer > 0, "No active offer found");
        uint256 _thisIndex = biddings[_mToken].offerIndex[_offeror];
        uint256 _nextIndex = biddings[_mToken].nextOffer;
        assert (_nextIndex > 0);
        _nextIndex--;
        if (_thisIndex != _nextIndex) {
            address _swappedOfferor = biddings[_mToken].maxOfferor[0][_nextIndex];
            biddings[_mToken].offerIndex[_swappedOfferor] = _thisIndex;
            uint256 _newOffer = biddings[_mToken].offers[_swappedOfferor];
            _updateOffer(_mToken, _thisIndex, _swappedOfferor, _newOffer);
        }
        _updateOffer(_mToken, _nextIndex, address(0), 0);
        delete biddings[_mToken].offers[_offeror];
        delete biddings[_mToken].offerIndex[_offeror];
        biddings[_mToken].nextOffer = _nextIndex;
        return _oldOffer;
    }
    
    /**
        @notice Withdraws any funds the contract has collected for the msg.sender from refunds
                and proceeds of sales or auctions.
    */
    function withdrawAuctionRefund() 
        public
        nonReentrant 
    {
        require(refunds[msg.sender] > 0, "No outstanding refunds found");
        uint256 _refundAmount = refunds[msg.sender];
        refunds[msg.sender] = 0;
        msg.sender.transfer(_refundAmount);
        emit AuctionRefund(msg.sender, _refundAmount);
    }

    /**
        @notice Convenience function to cancel and withdraw in one call
    */
    function cancelOfferAndWithdrawRefund(
        uint240 _mToken
    )
        external
    {
        cancelOffer(_mToken);
        withdrawAuctionRefund();
    }

    uint256 constant private clusterSize = (2**4);

    function _updateOffer(
        uint240 _mToken,
        uint256 _offerIndex,
        address _newOfferor,
        uint256 _newOffer
    )
        internal
    {
        assert (biddings[_mToken].nextOffer > 0);
        assert (biddings[_mToken].offers[address(0)] == 0);
        uint256 _n = 0;
        address _origOfferor = _newOfferor;
        uint256 _origOffer = biddings[_mToken].offers[_newOfferor];
        if (_newOffer != _origOffer) {
            biddings[_mToken].offers[_newOfferor] = _newOffer;
        }
        
        for (uint256 tmp = biddings[_mToken].nextOffer * clusterSize; tmp > 0; tmp = tmp / clusterSize) {

            uint256 _oldOffer;
            address _oldOfferor = biddings[_mToken].maxOfferor[_n][_offerIndex];
            if (_oldOfferor != _newOfferor) {
                biddings[_mToken].maxOfferor[_n][_offerIndex] = _newOfferor;
            }

            _offerIndex = _offerIndex / clusterSize;
            address _maxOfferor = biddings[_mToken].maxOfferor[_n + 1][_offerIndex];
            if (tmp < clusterSize) {
                if (_maxOfferor != address(0)) {
                    biddings[_mToken].maxOfferor[_n + 1][_offerIndex] = address(0);
                }
                return;
            }
            
            if (_maxOfferor != address(0)) {
                if (_oldOfferor == _origOfferor) {
                    _oldOffer = _origOffer;
                }
                else {
                    _oldOffer = biddings[_mToken].offers[_oldOfferor];
                }
                
                if ((_oldOfferor != _maxOfferor) && (_newOffer <= _oldOffer)) {
                    return;
                }
                if ((_oldOfferor == _maxOfferor) && (_newOffer > _oldOffer)) {
                    _n++;
                    continue;
                }
            }
            uint256 _i = _offerIndex * clusterSize;
            _newOfferor = biddings[_mToken].maxOfferor[_n][_i];
            _newOffer = biddings[_mToken].offers[_newOfferor];
            _i++;
            while ((_i % clusterSize) != 0) {
                address _tmpOfferor = biddings[_mToken].maxOfferor[_n][_i];
                if (biddings[_mToken].offers[_tmpOfferor] > _newOffer) {
                    _newOfferor = _tmpOfferor;
                    _newOffer = biddings[_mToken].offers[_tmpOfferor];
                }
                _i++;
            } 
            _n++;
        }
    }

    /**
        @notice Returns the maximum offer currently active for the given _mToken. If the current maximum
        offer for the collection (= offer for the anchorToken) is higher, then this collection offer value 
        is returned.
    */
    function getMaxOffer(
        uint240 _mToken
    )
        public
        view
        returns (uint256)
    {
        uint256 _maxCollectionOffer = 0;
        ( , , address _tokenAddress) = mtroller.parseToken(_mToken);
        uint240 _anchorToken = mtroller.getAnchorToken(_tokenAddress);
        if (_mToken != _anchorToken && biddings[_anchorToken].nextOffer != 0) {
            _maxCollectionOffer = biddings[_anchorToken].offers[getMaxOfferor(_anchorToken)];
        }
        if (biddings[_mToken].nextOffer == 0) {
            return _maxCollectionOffer;
        }
        uint256 _maxSpecificOffer = biddings[_mToken].offers[getMaxOfferor(_mToken)];
        return (_maxCollectionOffer > _maxSpecificOffer ? _maxCollectionOffer : _maxSpecificOffer);
    }

    /**
        @notice Returns the current highest bidder for the given _mToken. Active offers for the collection
        are NOT implicitly searched (they can be queried explicitly by setting mToken = anchorToken).
        Reverts if no active offer found for the given mToken.
    */
    function getMaxOfferor(
        uint240 _mToken
    )
        public
        view
        returns (address)
    {
        uint256 _n = 0;
        for (uint256 tmp = biddings[_mToken].nextOffer * clusterSize; tmp > 0; tmp = tmp / clusterSize) {
            _n++;
        }
        require (_n > 0, "No valid offer found");
        _n--;
        return biddings[_mToken].maxOfferor[_n][0];
    }

    function getMaxOfferor(
        uint240 _mToken, 
        uint256 _level, 
        uint256 _offset
    )
        public
        view
        returns (address[10] memory _offerors)
    {
        for (uint256 _i = 0; _i < 10; _i++) {
            _offerors[_i] = biddings[_mToken].maxOfferor[_level][_offset + _i];
        }
        return _offerors;
    }

    function getOffer(
        uint240 _mToken,
        address _account
    )
        public
        view
        returns (uint256)
    {
        return biddings[_mToken].offers[_account];
    }

    function getOfferIndex(
        uint240 _mToken
    )
        public
        view
        returns (uint256)
    {
        require (biddings[_mToken].offers[msg.sender] > 0, "No active offer");
        return biddings[_mToken].offerIndex[msg.sender];
    }

    function getCurrentOfferCount(
        uint240 _mToken
    )
        external
        view
        returns (uint256)
    {
        return(biddings[_mToken].nextOffer);
    }

    function getOfferAtIndex(
        uint240 _mToken,
        uint256 _offerIndex
    )
        external
        view
        returns (address offeror, uint256 offer)
    {
        require(biddings[_mToken].nextOffer > 0, "No valid offer");
        require(_offerIndex < biddings[_mToken].nextOffer, "Offer index out of range");
        offeror = biddings[_mToken].maxOfferor[0][_offerIndex];
        offer = biddings[_mToken].offers[offeror];
    }

    /**
     * @notice Handle the receipt of an NFT, see Open Zeppelin's IERC721Receiver.
     * @dev The ERC721 smart contract calls this function on the recipient
     * after a {IERC721-safeTransferFrom}. This function MUST return the function selector,
     * otherwise the caller will revert the transaction. The selector to be
     * returned can be obtained as `this.onERC721Received.selector`. This
     * function MAY throw to revert and reject the transfer.
     * Note: the ERC721 contract address is always the message sender.
     * @param operator The address which called `safeTransferFrom` function
     * @param from The address which previously owned the token
     * @param tokenId The NFT identifier which is being transferred
     * @param data Additional data with no specified format
     * @return bytes4 `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data) public view returns (bytes4) {
        /* unused parameters */
        from;
        tokenId;
        data;

        /* Reject any token where operator was not this contract or an MERC721 contract */
        if (operator == address(this)) {
            return this.onERC721Received.selector;
        }
        else if (MERC721Interface(operator).getTokenType() == MTokenIdentifier.MTokenType.ERC721_MTOKEN) {
            return this.onERC721Received.selector;
        }
        else {
            revert("Cannot accept token");
        }
    }

    /**
        @notice MTroller admin may collect any ERC-721 token that have been transferred to this contract 
                inadvertently (otherwise they would be locked forever).
        @dev Reverts upon any failure.        
        @param _tokenContract The contract address of the "lost" token.
        @param _tokenID The ID of the "lost" token.
    */
    function _sweepERC721(address _tokenContract, uint256 _tokenID) external nonReentrant {
        require(msg.sender == mtroller.getAdmin(), "Only mtroller admin can do that");
        IERC721(_tokenContract).safeTransferFrom(address(this), msg.sender, _tokenID);
    }

    /**
     * @dev Block reentrancy (directly or indirectly)
     */
    modifier nonReentrant() {
        require(_notEntered, "Reentrance not allowed");
        _notEntered = false;
        _;
        _notEntered = true; // get a gas-refund post-Istanbul
    }


// ************************************************************
//  Test functions only below this point, remove in production!

    // function addOfferETH_Test(
    //     uint240 _mToken,
    //     address _sender,
    //     uint256 _amount
    // )
    //     public
    //     nonReentrant
    // {
    //     require (_amount > 0, "No payment sent");
    //     uint256 _oldOffer = biddings[_mToken].offers[_sender];
    //     uint256 _newOffer = _oldOffer + _amount;
    //     if (_oldOffer == 0) {
    //         uint256 _nextIndex = biddings[_mToken].nextOffer;
    //         biddings[_mToken].offerIndex[_sender] = _nextIndex;
    //         biddings[_mToken].nextOffer = _nextIndex + 1;
    //     }
    //     _updateOffer(_mToken, biddings[_mToken].offerIndex[_sender], _sender, _newOffer);
    //     emit NewAuctionOffer(_mToken, _sender, _newOffer);
    // }

    // function cancelOfferETH_Test(
    //     uint240 _mToken,
    //     address _sender
    // )
    //     public
    //     nonReentrant
    // {
    //     uint256 _oldOffer = biddings[_mToken].offers[_sender];
    //     require (_oldOffer > 0, "No active offer found");
    //     uint256 _thisIndex = biddings[_mToken].offerIndex[_sender];
    //     uint256 _nextIndex = biddings[_mToken].nextOffer;
    //     assert (_nextIndex > 0);
    //     _nextIndex--;
    //     if (_thisIndex != _nextIndex) {
    //         address _swappedOfferor = biddings[_mToken].maxOfferor[0][_nextIndex];
    //         biddings[_mToken].offerIndex[_swappedOfferor] = _thisIndex;
    //         uint256 _newOffer = biddings[_mToken].offers[_swappedOfferor];
    //         _updateOffer(_mToken, _thisIndex, _swappedOfferor, _newOffer);
    //     }
    //     _updateOffer(_mToken, _nextIndex, address(0), 0);
    //     delete biddings[_mToken].offers[_sender];
    //     delete biddings[_mToken].offerIndex[_sender];
    //     biddings[_mToken].nextOffer = _nextIndex;
    //     refunds[_sender] += _oldOffer;
    //     emit AuctionOfferCancelled(_mToken, _sender, _oldOffer);
    // }

    // function testBidding(
    //     uint256 _start,
    //     uint256 _cnt
    // )
    //     public
    // {
    //     for (uint256 _i = _start; _i < (_start + _cnt); _i++) {
    //         addOfferETH_Test(1, address(uint160(_i)), _i);
    //     }
    // }

}

pragma solidity ^0.5.16;

/**
  * @title Careful Math
  * @author Compound
  * @notice Derived from OpenZeppelin's SafeMath library
  *         https://github.com/OpenZeppelin/openzeppelin-solidity/blob/master/contracts/math/SafeMath.sol
  */
contract CarefulMath {

    /**
     * @dev Possible error codes that we can return
     */
    enum MathError {
        NO_ERROR,
        DIVISION_BY_ZERO,
        INTEGER_OVERFLOW,
        INTEGER_UNDERFLOW
    }

    /**
    * @dev Multiplies two numbers, returns an error on overflow.
    */
    function mulUInt(uint a, uint b) internal pure returns (MathError, uint) {
        if (a == 0) {
            return (MathError.NO_ERROR, 0);
        }

        uint c = a * b;

        if (c / a != b) {
            return (MathError.INTEGER_OVERFLOW, 0);
        } else {
            return (MathError.NO_ERROR, c);
        }
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function divUInt(uint a, uint b) internal pure returns (MathError, uint) {
        if (b == 0) {
            return (MathError.DIVISION_BY_ZERO, 0);
        }

        return (MathError.NO_ERROR, a / b);
    }

    /**
    * @dev Subtracts two numbers, returns an error on overflow (i.e. if subtrahend is greater than minuend).
    */
    function subUInt(uint a, uint b) internal pure returns (MathError, uint) {
        if (b <= a) {
            return (MathError.NO_ERROR, a - b);
        } else {
            return (MathError.INTEGER_UNDERFLOW, 0);
        }
    }

    /**
    * @dev Adds two numbers, returns an error on overflow.
    */
    function addUInt(uint a, uint b) internal pure returns (MathError, uint) {
        uint c = a + b;

        if (c >= a) {
            return (MathError.NO_ERROR, c);
        } else {
            return (MathError.INTEGER_OVERFLOW, 0);
        }
    }

    /**
    * @dev add a and b and then subtract c
    */
    function addThenSubUInt(uint a, uint b, uint c) internal pure returns (MathError, uint) {
        (MathError err0, uint sum) = addUInt(a, b);

        if (err0 != MathError.NO_ERROR) {
            return (err0, 0);
        }

        return subUInt(sum, c);
    }
}

pragma solidity ^0.5.16;

/**
 * @title ERC 20 Token Standard Interface
 *  https://eips.ethereum.org/EIPS/eip-20
 */
interface EIP20Interface {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);

    /**
      * @notice Get the total number of tokens in circulation
      * @return The supply of tokens
      */
    function totalSupply() external view returns (uint256);

    /**
     * @notice Gets the balance of the specified address
     * @param owner The address from which the balance will be retrieved
     * @return The balance
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
      * @notice Transfer `amount` tokens from `msg.sender` to `dst`
      * @param dst The address of the destination account
      * @param amount The number of tokens to transfer
      * @return Whether or not the transfer succeeded
      */
    function transfer(address dst, uint256 amount) external returns (bool success);

    /**
      * @notice Transfer `amount` tokens from `src` to `dst`
      * @param src The address of the source account
      * @param dst The address of the destination account
      * @param amount The number of tokens to transfer
      * @return Whether or not the transfer succeeded
      */
    function transferFrom(address src, address dst, uint256 amount) external returns (bool success);

    /**
      * @notice Approve `spender` to transfer up to `amount` from `src`
      * @dev This will overwrite the approval amount for `spender`
      *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
      * @param spender The address of the account which may transfer tokens
      * @param amount The number of tokens that are approved (-1 means infinite)
      * @return Whether or not the approval succeeded
      */
    function approve(address spender, uint256 amount) external returns (bool success);

    /**
      * @notice Get the current allowance from `owner` for `spender`
      * @param owner The address of the account which owns the tokens to be spent
      * @param spender The address of the account which may transfer tokens
      * @return The number of tokens allowed to be spent (-1 means infinite)
      */
    function allowance(address owner, address spender) external view returns (uint256 remaining);

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
}

pragma solidity ^0.5.16;

/**
 * @title EIP20NonStandardInterface
 * @dev Version of ERC20 with no return values for `transfer` and `transferFrom`
 *  See https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca
 */
interface EIP20NonStandardInterface {

    /**
     * @notice Get the total number of tokens in circulation
     * @return The supply of tokens
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice Gets the balance of the specified address
     * @param owner The address from which the balance will be retrieved
     * @return The balance
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    ///
    /// !!!!!!!!!!!!!!
    /// !!! NOTICE !!! `transfer` does not return a value, in violation of the ERC-20 specification
    /// !!!!!!!!!!!!!!
    ///

    /**
      * @notice Transfer `amount` tokens from `msg.sender` to `dst`
      * @param dst The address of the destination account
      * @param amount The number of tokens to transfer
      */
    function transfer(address dst, uint256 amount) external;

    ///
    /// !!!!!!!!!!!!!!
    /// !!! NOTICE !!! `transferFrom` does not return a value, in violation of the ERC-20 specification
    /// !!!!!!!!!!!!!!
    ///

    /**
      * @notice Transfer `amount` tokens from `src` to `dst`
      * @param src The address of the source account
      * @param dst The address of the destination account
      * @param amount The number of tokens to transfer
      */
    function transferFrom(address src, address dst, uint256 amount) external;

    /**
      * @notice Approve `spender` to transfer up to `amount` from `src`
      * @dev This will overwrite the approval amount for `spender`
      *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
      * @param spender The address of the account which may transfer tokens
      * @param amount The number of tokens that are approved
      * @return Whether or not the approval succeeded
      */
    function approve(address spender, uint256 amount) external returns (bool success);

    /**
      * @notice Get the current allowance from `owner` for `spender`
      * @param owner The address of the account which owns the tokens to be spent
      * @param spender The address of the account which may transfer tokens
      * @return The number of tokens allowed to be spent
      */
    function allowance(address owner, address spender) external view returns (uint256 remaining);

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
}

pragma solidity ^0.5.16;

import "./CarefulMath.sol";
import "./ExponentialNoError.sol";

/**
 * @title Exponential module for storing fixed-precision decimals
 * @author Compound
 * @dev Legacy contract for compatibility reasons with existing contracts that still use MathError
 * @notice Exp is a struct which stores decimals with a fixed precision of 18 decimal places.
 *         Thus, if we wanted to store the 5.1, mantissa would store 5.1e18. That is:
 *         `Exp({mantissa: 5100000000000000000})`.
 */
contract Exponential is CarefulMath, ExponentialNoError {
    /**
     * @dev Creates an exponential from numerator and denominator values.
     *      Note: Returns an error if (`num` * 10e18) > MAX_INT,
     *            or if `denom` is zero.
     */
    function getExp(uint num, uint denom) pure internal returns (MathError, Exp memory) {
        (MathError err0, uint scaledNumerator) = mulUInt(num, expScale);
        if (err0 != MathError.NO_ERROR) {
            return (err0, Exp({mantissa: 0}));
        }

        (MathError err1, uint rational) = divUInt(scaledNumerator, denom);
        if (err1 != MathError.NO_ERROR) {
            return (err1, Exp({mantissa: 0}));
        }

        return (MathError.NO_ERROR, Exp({mantissa: rational}));
    }

    /**
     * @dev Adds two exponentials, returning a new exponential.
     */
    function addExp(Exp memory a, Exp memory b) pure internal returns (MathError, Exp memory) {
        (MathError error, uint result) = addUInt(a.mantissa, b.mantissa);

        return (error, Exp({mantissa: result}));
    }

    /**
     * @dev Subtracts two exponentials, returning a new exponential.
     */
    function subExp(Exp memory a, Exp memory b) pure internal returns (MathError, Exp memory) {
        (MathError error, uint result) = subUInt(a.mantissa, b.mantissa);

        return (error, Exp({mantissa: result}));
    }

    /**
     * @dev Multiply an Exp by a scalar, returning a new Exp.
     */
    function mulScalar(Exp memory a, uint scalar) pure internal returns (MathError, Exp memory) {
        (MathError err0, uint scaledMantissa) = mulUInt(a.mantissa, scalar);
        if (err0 != MathError.NO_ERROR) {
            return (err0, Exp({mantissa: 0}));
        }

        return (MathError.NO_ERROR, Exp({mantissa: scaledMantissa}));
    }

    /**
     * @dev Multiply an Exp by a scalar, then truncate to return an unsigned integer.
     */
    function mulScalarTruncate(Exp memory a, uint scalar) pure internal returns (MathError, uint) {
        (MathError err, Exp memory product) = mulScalar(a, scalar);
        if (err != MathError.NO_ERROR) {
            return (err, 0);
        }

        return (MathError.NO_ERROR, truncate(product));
    }

    /**
     * @dev Multiply an Exp by a scalar, truncate, then add an to an unsigned integer, returning an unsigned integer.
     */
    function mulScalarTruncateAddUInt(Exp memory a, uint scalar, uint addend) pure internal returns (MathError, uint) {
        (MathError err, Exp memory product) = mulScalar(a, scalar);
        if (err != MathError.NO_ERROR) {
            return (err, 0);
        }

        return addUInt(truncate(product), addend);
    }

    /**
     * @dev Divide an Exp by a scalar, returning a new Exp.
     */
    function divScalar(Exp memory a, uint scalar) pure internal returns (MathError, Exp memory) {
        (MathError err0, uint descaledMantissa) = divUInt(a.mantissa, scalar);
        if (err0 != MathError.NO_ERROR) {
            return (err0, Exp({mantissa: 0}));
        }

        return (MathError.NO_ERROR, Exp({mantissa: descaledMantissa}));
    }

    /**
     * @dev Divide a scalar by an Exp, returning a new Exp.
     */
    function divScalarByExp(uint scalar, Exp memory divisor) pure internal returns (MathError, Exp memory) {
        /*
          We are doing this as:
          getExp(mulUInt(expScale, scalar), divisor.mantissa)

          How it works:
          Exp = a / b;
          Scalar = s;
          `s / (a / b)` = `b * s / a` and since for an Exp `a = mantissa, b = expScale`
        */
        (MathError err0, uint numerator) = mulUInt(expScale, scalar);
        if (err0 != MathError.NO_ERROR) {
            return (err0, Exp({mantissa: 0}));
        }
        return getExp(numerator, divisor.mantissa);
    }

    /**
     * @dev Divide a scalar by an Exp, then truncate to return an unsigned integer.
     */
    function divScalarByExpTruncate(uint scalar, Exp memory divisor) pure internal returns (MathError, uint) {
        (MathError err, Exp memory fraction) = divScalarByExp(scalar, divisor);
        if (err != MathError.NO_ERROR) {
            return (err, 0);
        }

        return (MathError.NO_ERROR, truncate(fraction));
    }

    /**
     * @dev Multiplies two exponentials, returning a new exponential.
     */
    function mulExp(Exp memory a, Exp memory b) pure internal returns (MathError, Exp memory) {

        (MathError err0, uint doubleScaledProduct) = mulUInt(a.mantissa, b.mantissa);
        if (err0 != MathError.NO_ERROR) {
            return (err0, Exp({mantissa: 0}));
        }

        // We add half the scale before dividing so that we get rounding instead of truncation.
        //  See "Listing 6" and text above it at https://accu.org/index.php/journals/1717
        // Without this change, a result like 6.6...e-19 will be truncated to 0 instead of being rounded to 1e-18.
        (MathError err1, uint doubleScaledProductWithHalfScale) = addUInt(halfExpScale, doubleScaledProduct);
        if (err1 != MathError.NO_ERROR) {
            return (err1, Exp({mantissa: 0}));
        }

        (MathError err2, uint product) = divUInt(doubleScaledProductWithHalfScale, expScale);
        // The only error `div` can return is MathError.DIVISION_BY_ZERO but we control `expScale` and it is not zero.
        assert(err2 == MathError.NO_ERROR);

        return (MathError.NO_ERROR, Exp({mantissa: product}));
    }

    /**
     * @dev Multiplies two exponentials given their mantissas, returning a new exponential.
     */
    function mulExp(uint a, uint b) pure internal returns (MathError, Exp memory) {
        return mulExp(Exp({mantissa: a}), Exp({mantissa: b}));
    }

    /**
     * @dev Multiplies three exponentials, returning a new exponential.
     */
    function mulExp3(Exp memory a, Exp memory b, Exp memory c) pure internal returns (MathError, Exp memory) {
        (MathError err, Exp memory ab) = mulExp(a, b);
        if (err != MathError.NO_ERROR) {
            return (err, ab);
        }
        return mulExp(ab, c);
    }

    /**
     * @dev Divides two exponentials, returning a new exponential.
     *     (a/scale) / (b/scale) = (a/scale) * (scale/b) = a/b,
     *  which we can scale as an Exp by calling getExp(a.mantissa, b.mantissa)
     */
    function divExp(Exp memory a, Exp memory b) pure internal returns (MathError, Exp memory) {
        return getExp(a.mantissa, b.mantissa);
    }
}

pragma solidity ^0.5.16;

/**
 * @title Exponential module for storing fixed-precision decimals
 * @author Compound
 * @notice Exp is a struct which stores decimals with a fixed precision of 18 decimal places.
 *         Thus, if we wanted to store the 5.1, mantissa would store 5.1e18. That is:
 *         `Exp({mantissa: 5100000000000000000})`.
 */
contract ExponentialNoError {
    uint constant expScale = 1e18;
    uint constant doubleScale = 1e36;
    uint constant halfExpScale = expScale/2;
    uint constant mantissaOne = expScale;

    struct Exp {
        uint mantissa;
    }

    struct Double {
        uint mantissa;
    }

    /**
     * @dev Truncates the given exp to a whole number value.
     *      For example, truncate(Exp{mantissa: 15 * expScale}) = 15
     */
    function truncate(Exp memory exp) pure internal returns (uint) {
        // Note: We are not using careful math here as we're performing a division that cannot fail
        return exp.mantissa / expScale;
    }

    /**
     * @dev Multiply an Exp by a scalar, then truncate to return an unsigned integer.
     */
    function mul_ScalarTruncate(Exp memory a, uint scalar) pure internal returns (uint) {
        Exp memory product = mul_(a, scalar);
        return truncate(product);
    }

    /**
     * @dev Multiply an Exp by a scalar, truncate, then add an to an unsigned integer, returning an unsigned integer.
     */
    function mul_ScalarTruncateAddUInt(Exp memory a, uint scalar, uint addend) pure internal returns (uint) {
        Exp memory product = mul_(a, scalar);
        return add_(truncate(product), addend);
    }

    /**
     * @dev Checks if first Exp is less than second Exp.
     */
    function lessThanExp(Exp memory left, Exp memory right) pure internal returns (bool) {
        return left.mantissa < right.mantissa;
    }

    /**
     * @dev Checks if left Exp <= right Exp.
     */
    function lessThanOrEqualExp(Exp memory left, Exp memory right) pure internal returns (bool) {
        return left.mantissa <= right.mantissa;
    }

    /**
     * @dev Checks if left Exp > right Exp.
     */
    function greaterThanExp(Exp memory left, Exp memory right) pure internal returns (bool) {
        return left.mantissa > right.mantissa;
    }

    /**
     * @dev returns true if Exp is exactly zero
     */
    function isZeroExp(Exp memory value) pure internal returns (bool) {
        return value.mantissa == 0;
    }

    function safe224(uint n, string memory errorMessage) pure internal returns (uint224) {
        require(n < 2**224, errorMessage);
        return uint224(n);
    }

    function safe32(uint n, string memory errorMessage) pure internal returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

    function add_(Exp memory a, Exp memory b) pure internal returns (Exp memory) {
        return Exp({mantissa: add_(a.mantissa, b.mantissa)});
    }

    function add_(Double memory a, Double memory b) pure internal returns (Double memory) {
        return Double({mantissa: add_(a.mantissa, b.mantissa)});
    }

    function add_(uint a, uint b) pure internal returns (uint) {
        return add_(a, b, "addition overflow");
    }

    function add_(uint a, uint b, string memory errorMessage) pure internal returns (uint) {
        uint c = a + b;
        require(c >= a, errorMessage);
        return c;
    }

    function sub_(Exp memory a, Exp memory b) pure internal returns (Exp memory) {
        return Exp({mantissa: sub_(a.mantissa, b.mantissa)});
    }

    function sub_(Double memory a, Double memory b) pure internal returns (Double memory) {
        return Double({mantissa: sub_(a.mantissa, b.mantissa)});
    }

    function sub_(uint a, uint b) pure internal returns (uint) {
        return sub_(a, b, "subtraction underflow");
    }

    function sub_(uint a, uint b, string memory errorMessage) pure internal returns (uint) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function mul_(Exp memory a, Exp memory b) pure internal returns (Exp memory) {
        return Exp({mantissa: mul_(a.mantissa, b.mantissa) / expScale});
    }

    function mul_(Exp memory a, uint b) pure internal returns (Exp memory) {
        return Exp({mantissa: mul_(a.mantissa, b)});
    }

    function mul_(uint a, Exp memory b) pure internal returns (uint) {
        return mul_(a, b.mantissa) / expScale;
    }

    function mul_(Double memory a, Double memory b) pure internal returns (Double memory) {
        return Double({mantissa: mul_(a.mantissa, b.mantissa) / doubleScale});
    }

    function mul_(Double memory a, uint b) pure internal returns (Double memory) {
        return Double({mantissa: mul_(a.mantissa, b)});
    }

    function mul_(uint a, Double memory b) pure internal returns (uint) {
        return mul_(a, b.mantissa) / doubleScale;
    }

    function mul_(uint a, uint b) pure internal returns (uint) {
        return mul_(a, b, "multiplication overflow");
    }

    function mul_(uint a, uint b, string memory errorMessage) pure internal returns (uint) {
        if (a == 0 || b == 0) {
            return 0;
        }
        uint c = a * b;
        require(c / a == b, errorMessage);
        return c;
    }

    function div_(Exp memory a, Exp memory b) pure internal returns (Exp memory) {
        return Exp({mantissa: div_(mul_(a.mantissa, expScale), b.mantissa)});
    }

    function div_(Exp memory a, uint b) pure internal returns (Exp memory) {
        return Exp({mantissa: div_(a.mantissa, b)});
    }

    function div_(uint a, Exp memory b) pure internal returns (uint) {
        return div_(mul_(a, expScale), b.mantissa);
    }

    function div_(Double memory a, Double memory b) pure internal returns (Double memory) {
        return Double({mantissa: div_(mul_(a.mantissa, doubleScale), b.mantissa)});
    }

    function div_(Double memory a, uint b) pure internal returns (Double memory) {
        return Double({mantissa: div_(a.mantissa, b)});
    }

    function div_(uint a, Double memory b) pure internal returns (uint) {
        return div_(mul_(a, doubleScale), b.mantissa);
    }

    function div_(uint a, uint b) pure internal returns (uint) {
        return div_(a, b, "divide by zero");
    }

    function div_(uint a, uint b, string memory errorMessage) pure internal returns (uint) {
        require(b > 0, errorMessage);
        return a / b;
    }

    function fraction(uint a, uint b) pure internal returns (Double memory) {
        return Double({mantissa: div_(mul_(a, doubleScale), b)});
    }
}

pragma solidity ^0.5.16;

/**
  * @title Compound's InterestRateModel Interface
  * @author Compound
  */
contract InterestRateModel {
    /// @notice Indicator that this is an InterestRateModel contract (for inspection)
    bool public constant isInterestRateModel = true;

    /**
      * @notice Calculates the current borrow interest rate per block
      * @param cash The total amount of cash the market has
      * @param borrows The total amount of borrows the market has outstanding
      * @param reserves The total amount of reserves the market has
      * @return The borrow rate per block (as a percentage, and scaled by 1e18)
      */
    function getBorrowRate(uint cash, uint borrows, uint reserves) external view returns (uint);

    /**
      * @notice Calculates the current supply interest rate per block
      * @param cash The total amount of cash the market has
      * @param borrows The total amount of borrows the market has outstanding
      * @param reserves The total amount of reserves the market has
      * @param reserveFactorMantissa The current reserve factor the market has
      * @return The supply rate per block (as a percentage, and scaled by 1e18)
      */
    function getSupplyRate(uint cash, uint borrows, uint reserves, uint reserveFactorMantissa) external view returns (uint);

}

pragma solidity ^0.5.0;

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
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

pragma solidity ^0.5.0;

import "../math/ZSafeMath.sol";

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 * Since it is not possible to overflow a 256 bit integer with increments of one, `increment` can skip the {SafeMath}
 * overflow check, thereby saving gas. This does assume however correct usage, in that the underlying `_value` is never
 * directly accessed.
 */
library Counters {
    using ZSafeMath for uint256;

    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        // The {SafeMath} overflow check can be skipped here, see the comment at the top
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value.sub(1);
    }
}

pragma solidity ^0.5.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
contract ERC165 is IERC165 {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () internal {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

pragma solidity ^0.5.0;

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

pragma solidity ^0.5.0;

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
library ZSafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
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
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity ^0.5.0;

import "../../GSN/Context.sol";
import "./IERC20.sol";
import "../../math/ZSafeMath.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20Mintable}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using ZSafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See {_burn} and {_approve}.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance"));
    }
}

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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

pragma solidity ^0.5.0;

import "../../GSN/Context.sol";
import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "../../math/ZSafeMath.sol";
import "../../utils/Address.sol";
import "../../drafts/Counters.sol";
import "../../introspection/ERC165.sol";

/**
 * @title ERC721 Non-Fungible Token Standard basic implementation
 * @dev see https://eips.ethereum.org/EIPS/eip-721
 */
contract ERC721 is Context, ERC165, IERC721 {
    using ZSafeMath for uint256;
    using Address for address;
    using Counters for Counters.Counter;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    // which can be also obtained as `IERC721Receiver(0).onERC721Received.selector`
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

    // Mapping from token ID to owner
    mapping (uint256 => address) private _tokenOwner;

    // Mapping from token ID to approved address
    mapping (uint256 => address) internal _tokenApprovals;

    // Mapping from owner to number of owned token
    mapping (address => Counters.Counter) private _ownedTokensCount;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    /*
     *     bytes4(keccak256('balanceOf(address)')) == 0x70a08231
     *     bytes4(keccak256('ownerOf(uint256)')) == 0x6352211e
     *     bytes4(keccak256('approve(address,uint256)')) == 0x095ea7b3
     *     bytes4(keccak256('getApproved(uint256)')) == 0x081812fc
     *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
     *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c5
     *     bytes4(keccak256('transferFrom(address,address,uint256)')) == 0x23b872dd
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256)')) == 0x42842e0e
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)')) == 0xb88d4fde
     *
     *     => 0x70a08231 ^ 0x6352211e ^ 0x095ea7b3 ^ 0x081812fc ^
     *        0xa22cb465 ^ 0xe985e9c ^ 0x23b872dd ^ 0x42842e0e ^ 0xb88d4fde == 0x80ac58cd
     */
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    constructor(string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(_INTERFACE_ID_ERC721);
    }

    /**
     * @dev Gets the balance of the specified address.
     * @param owner address to query the balance of
     * @return uint256 representing the amount owned by the passed address
     */
    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");

        return _ownedTokensCount[owner].current();
    }

    /**
     * @dev Gets the owner of the specified token ID.
     * @param tokenId uint256 ID of the token to query the owner of
     * @return address currently marked as the owner of the given token ID
     */
    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _tokenOwner[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");

        return owner;
    }

    /**
     * @dev Approves another address to transfer the given token ID
     * The zero address indicates there is no approved address.
     * There can only be one approved address per token at a given time.
     * Can only be called by the token owner or an approved operator.
     * @param to address to be approved for the given token ID
     * @param tokenId uint256 ID of the token to be approved
     */
    function approve(address to, uint256 tokenId) public {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    /**
     * @dev Gets the approved address for a token ID, or zero if no address set
     * Reverts if the token ID does not exist.
     * @param tokenId uint256 ID of the token to query the approval of
     * @return address currently approved for the given token ID
     */
    function getApproved(uint256 tokenId) public view returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev Sets or unsets the approval of a given operator
     * An operator is allowed to transfer all tokens of the sender on their behalf.
     * @param to operator address to set the approval
     * @param approved representing the status of the approval to be set
     */
    function setApprovalForAll(address to, bool approved) public {
        require(to != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][to] = approved;
        emit ApprovalForAll(_msgSender(), to, approved);
    }

    /**
     * @dev Tells whether an operator is approved by a given owner.
     * @param owner owner address which you want to query the approval of
     * @param operator operator address which you want to query the approval of
     * @return bool whether the given operator is approved by the given owner
     */
    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev Transfers the ownership of a given token ID to another address.
     * Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     * Requires the msg.sender to be the owner, approved, or operator.
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     */
    function transferFrom(address from, address to, uint256 tokenId) public {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transferFrom(from, to, tokenId);
    }

    /**
     * @dev Safely transfers the ownership of a given token ID to another address
     * If the target address is a contract, it must implement {IERC721Receiver-onERC721Received},
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
     * the transfer is reverted.
     * Requires the msg.sender to be the owner, approved, or operator
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev Safely transfers the ownership of a given token ID to another address
     * If the target address is a contract, it must implement {IERC721Receiver-onERC721Received},
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
     * the transfer is reverted.
     * Requires the _msgSender() to be the owner, approved, or operator
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes data to send along with a safe transfer check
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransferFrom(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers the ownership of a given token ID to another address
     * If the target address is a contract, it must implement `onERC721Received`,
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
     * the transfer is reverted.
     * Requires the msg.sender to be the owner, approved, or operator
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes data to send along with a safe transfer check
     */
    function _safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) internal {
        _transferFrom(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether the specified token exists.
     * @param tokenId uint256 ID of the token to query the existence of
     * @return bool whether the token exists
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        address owner = _tokenOwner[tokenId];
        return owner != address(0);
    }

    /**
     * @dev Returns whether the given spender can transfer a given token ID.
     * @param spender address of the spender to query
     * @param tokenId uint256 ID of the token to be transferred
     * @return bool whether the msg.sender is approved for the given token ID,
     * is an operator of the owner, or is the owner of the token
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Internal function to safely mint a new token.
     * Reverts if the given token ID already exists.
     * If the target address is a contract, it must implement `onERC721Received`,
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
     * the transfer is reverted.
     * @param to The address that will own the minted token
     * @param tokenId uint256 ID of the token to be minted
     */
    function _safeMint(address to, uint256 tokenId) internal {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Internal function to safely mint a new token.
     * Reverts if the given token ID already exists.
     * If the target address is a contract, it must implement `onERC721Received`,
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
     * the transfer is reverted.
     * @param to The address that will own the minted token
     * @param tokenId uint256 ID of the token to be minted
     * @param _data bytes data to send along with a safe transfer check
     */
    function _safeMint(address to, uint256 tokenId, bytes memory _data) internal {
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Internal function to mint a new token.
     * Reverts if the given token ID already exists.
     * @param to The address that will own the minted token
     * @param tokenId uint256 ID of the token to be minted
     */
    function _mint(address to, uint256 tokenId) internal {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _tokenOwner[tokenId] = to;
        _ownedTokensCount[to].increment();

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Internal function to burn a specific token.
     * Reverts if the token does not exist.
     * Deprecated, use {_burn} instead.
     * @param owner owner of the token to burn
     * @param tokenId uint256 ID of the token being burned
     */
    function _burn(address owner, uint256 tokenId) internal {
        require(ownerOf(tokenId) == owner, "ERC721: burn of token that is not own");

        _clearApproval(tokenId);

        _ownedTokensCount[owner].decrement();
        _tokenOwner[tokenId] = address(0);

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Internal function to burn a specific token.
     * Reverts if the token does not exist.
     * @param tokenId uint256 ID of the token being burned
     */
    function _burn(uint256 tokenId) internal {
        _burn(ownerOf(tokenId), tokenId);
    }

    /**
     * @dev Internal function to transfer ownership of a given token ID to another address.
     * As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     */
    function _transferFrom(address from, address to, uint256 tokenId) internal {
        require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _clearApproval(tokenId);

        _ownedTokensCount[from].decrement();
        _ownedTokensCount[to].increment();

        _tokenOwner[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * This is an internal detail of the `ERC721` contract and its use is deprecated.
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        internal returns (bool)
    {
        if (!to.isContract()) {
            return true;
        }
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = to.call(abi.encodeWithSelector(
            IERC721Receiver(to).onERC721Received.selector,
            _msgSender(),
            from,
            tokenId,
            _data
        ));
        if (!success) {
            if (returndata.length > 0) {
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert("ERC721: transfer to non ERC721Receiver implementer");
            }
        } else {
            bytes4 retval = abi.decode(returndata, (bytes4));
            return (retval == _ERC721_RECEIVED);
        }
    }

    /**
     * @dev Private function to clear current approval of a given token ID.
     * @param tokenId uint256 ID of the token to be transferred
     */
    function _clearApproval(uint256 tokenId) private {
        if (_tokenApprovals[tokenId] != address(0)) {
            _tokenApprovals[tokenId] = address(0);
        }
    }
}

pragma solidity ^0.5.0;

import "../../introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
contract IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of NFTs in `owner`'s account.
     */
    function balanceOf(address owner) public view returns (uint256 balance);

    /**
     * @dev Returns the owner of the NFT specified by `tokenId`.
     */
    function ownerOf(uint256 tokenId) public view returns (address owner);

    /**
     * @dev Transfers a specific NFT (`tokenId`) from one account (`from`) to
     * another (`to`).
     *
     *
     *
     * Requirements:
     * - `from`, `to` cannot be zero.
     * - `tokenId` must be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this
     * NFT by either {approve} or {setApprovalForAll}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public;
    /**
     * @dev Transfers a specific NFT (`tokenId`) from one account (`from`) to
     * another (`to`).
     *
     * Requirements:
     * - If the caller is not `from`, it must be approved to move this NFT by
     * either {approve} or {setApprovalForAll}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public;
    function approve(address to, uint256 tokenId) public;
    function getApproved(uint256 tokenId) public view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) public;
    function isApprovedForAll(address owner, address operator) public view returns (bool);


    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public;
}

pragma solidity ^0.5.0;

import "./IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
contract IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

pragma solidity ^0.5.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
contract IERC721Receiver {
    /**
     * @notice Handle the receipt of an NFT
     * @dev The ERC721 smart contract calls this function on the recipient
     * after a {IERC721-safeTransferFrom}. This function MUST return the function selector,
     * otherwise the caller will revert the transaction. The selector to be
     * returned can be obtained as `this.onERC721Received.selector`. This
     * function MAY throw to revert and reject the transfer.
     * Note: the ERC721 contract address is always the message sender.
     * @param operator The address which called `safeTransferFrom` function
     * @param from The address which previously owned the token
     * @param tokenId The NFT identifier which is being transferred
     * @param data Additional data with no specified format
     * @return bytes4 `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data)
    public returns (bytes4);
}

pragma solidity ^0.5.5;

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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
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
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}