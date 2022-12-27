// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "../libraries/LoanLibrary.sol";

/**
 * @title LendingErrors
 * @author Non-Fungible Technologies, Inc.
 *
 * This file contains custom errors for the core lending protocol contracts, with errors
 * prefixed by the contract that throws them (e.g., "OC_" for OriginationController).
 * Errors located in one place to make it possible to holistically look at all
 * protocol failure cases.
 */

// ==================================== ORIGINATION CONTROLLER ======================================
/// @notice All errors prefixed with OC_, to separate from other contracts in the protocol.

/// @notice Zero address passed in where not allowed.
error OC_ZeroAddress();

/**
 * @notice Ensure valid loan state for loan lifceycle operations.
 *
 * @param state                         Current state of a loan according to LoanState enum.
 */
error OC_InvalidState(LoanLibrary.LoanState state);

/**
 * @notice Loan duration must be greater than 1hr and less than 3yrs.
 *
 * @param durationSecs                 Total amount of time in seconds.
 */
error OC_LoanDuration(uint256 durationSecs);

/**
 * @notice Interest must be greater than 0.01%. (interestRate / 1e18 >= 1)
 *
 * @param interestRate                  InterestRate with 1e18 multiplier.
 */
error OC_InterestRate(uint256 interestRate);

/**
 * @notice Number of installment periods must be greater than 1 and less than or equal to 1000.
 *
 * @param numInstallments               Number of installment periods in loan.
 */
error OC_NumberInstallments(uint256 numInstallments);

/**
 * @notice One of the predicates for item verification failed.
 *
 * @param verifier                      The address of the verifier contract.
 * @param data                          The verification data (to be parsed by verifier).
 * @param vault                         The user's vault subject to verification.
 */
error OC_PredicateFailed(address verifier, bytes data, address vault);

/**
 * @notice The predicates array is empty.
 */
error OC_PredicatesArrayEmpty();

/**
 * @notice A caller attempted to approve themselves.
 *
 * @param caller                        The caller of the approve function.
 */
error OC_SelfApprove(address caller);

/**
 * @notice A caller attempted to originate a loan with their own signature.
 *
 * @param caller                        The caller of the approve function, who was also the signer.
 */
error OC_ApprovedOwnLoan(address caller);

/**
 * @notice The signature could not be recovered to the counterparty or approved party.
 *
 * @param target                        The target party of the signature, which should either be the signer,
 *                                      or someone who has approved the signer.
 * @param signer                        The signer determined from ECDSA.recover.
 */
error OC_InvalidSignature(address target, address signer);

/**
 * @notice The verifier contract specified in a predicate has not been whitelisted.
 *
 * @param verifier                      The verifier the caller attempted to use.
 */
error OC_InvalidVerifier(address verifier);

/**
 * @notice The function caller was neither borrower or lender, and was not approved by either.
 *
 * @param caller                        The unapproved function caller.
 */
error OC_CallerNotParticipant(address caller);

/**
 * @notice Two related parameters for batch operations did not match in length.
 */
error OC_BatchLengthMismatch();

/**
 * @notice Principal must be greater than 9999 Wei.
 *
 * @param principal                     Principal in ether.
 */
error OC_PrincipalTooLow(uint256 principal);

/**
 * @notice Signature must not be expired.
 *
 * @param deadline                      Deadline in seconds.
 */
error OC_SignatureIsExpired(uint256 deadline);

/**
 * @notice New currency does not match for a loan rollover request.
 *
 * @param oldCurrency                   The currency of the active loan.
 * @param newCurrency                   The currency of the new loan.
 */
error OC_RolloverCurrencyMismatch(address oldCurrency, address newCurrency);

/**
 * @notice New currency does not match for a loan rollover request.
 *
 * @param oldCollateralAddress          The address of the active loan's collateral.
 * @param newCollateralAddress          The token ID of the active loan's collateral.
 * @param oldCollateralId               The address of the new loan's collateral.
 * @param newCollateralId               The token ID of the new loan's collateral.
 */
error OC_RolloverCollateralMismatch(
    address oldCollateralAddress,
    uint256 oldCollateralId,
    address newCollateralAddress,
    uint256 newCollateralId
);

// ==================================== ITEMS VERIFIER ======================================
/// @notice All errors prefixed with IV_, to separate from other contracts in the protocol.

/**
 * @notice Provided SignatureItem is missing an address.
 */
error IV_ItemMissingAddress();

/**
 * @notice Provided SignatureItem has an invalid collateral type.
 * @dev    Should never actually fire, since cType is defined by an enum, so will fail on decode.
 *
 * @param asset                        The NFT contract being checked.
 * @param cType                        The collateralTytpe provided.
 */
error IV_InvalidCollateralType(address asset, uint256 cType);

/**
 * @notice Provided ERC1155 signature item is requiring a non-positive amount.
 *
 * @param asset                         The NFT contract being checked.
 * @param amount                        The amount provided (should be 0).
 */
error IV_NonPositiveAmount1155(address asset, uint256 amount);

/**
 * @notice Provided ERC1155 signature item is requiring an invalid token ID.
 *
 * @param asset                         The NFT contract being checked.
 * @param tokenId                       The token ID provided.
 */
error IV_InvalidTokenId1155(address asset, int256 tokenId);

/**
 * @notice Provided ERC20 signature item is requiring a non-positive amount.
 *
 * @param asset                         The NFT contract being checked.
 * @param amount                        The amount provided (should be 0).
 */
error IV_NonPositiveAmount20(address asset, uint256 amount);

/**
 * @notice The provided token ID is out of bounds for the given collection.
 *
 * @param tokenId                       The token ID provided.
 */
error IV_InvalidTokenId(int256 tokenId);

// ==================================== REPAYMENT CONTROLLER ======================================
/// @notice All errors prefixed with RC_, to separate from other contracts in the protocol.

/**
 * @notice Could not dereference loan from loan ID.
 *
 * @param target                     The loanId being checked.
 */
error RC_CannotDereference(uint256 target);

/**
 * @notice Ensure valid loan state for loan lifceycle operations.
 *
 * @param state                         Current state of a loan according to LoanState enum.
 */
error RC_InvalidState(LoanLibrary.LoanState state);

/**
 * @notice Repayment has already been completed for this loan without installments.
 */
error RC_NoPaymentDue();

/**
 * @notice Caller is not the owner of lender note.
 *
 * @param caller                     Msg.sender of the function call.
 */
error RC_OnlyLender(address caller);

/**
 * @notice Loan has not started yet.
 *
 * @param startDate                 block timestamp of the startDate of loan stored in LoanData.
 */
error RC_BeforeStartDate(uint256 startDate);

/**
 * @notice Loan terms do not have any installments, use repay for repayments.
 *
 * @param numInstallments           Number of installments returned from LoanTerms.
 */
error RC_NoInstallments(uint256 numInstallments);

/**
 * @notice Loan terms have installments, use repaypart or repayPartMinimum for repayments.
 *
 * @param numInstallments           Number of installments returned from LoanTerms.
 */
error RC_HasInstallments(uint256 numInstallments);

/**
 * @notice No interest payment or late fees due.
 *
 * @param amount                    Minimum interest plus late fee amount returned
 *                                  from minimum payment calculation.
 */
error RC_NoMinPaymentDue(uint256 amount);

/**
 * @notice Repaid amount must be larger than zero.
 */
error RC_RepayPartZero();

/**
 * @notice Amount paramater less than the minimum amount due.
 *
 * @param amount                    Amount function call parameter.
 * @param minAmount                 The minimum amount due.
 */
error RC_RepayPartLTMin(uint256 amount, uint256 minAmount);

// ==================================== Loan Core ======================================
/// @notice All errors prefixed with LC_, to separate from other contracts in the protocol.

/// @notice Zero address passed in where not allowed.
error LC_ZeroAddress();

/// @notice Borrower address is same as lender address.
error LC_ReusedNote();

/**
 * @notice Check collateral is not already used in a active loan.
 *
 * @param collateralAddress             Address of the collateral.
 * @param collateralId                  ID of the collateral token.
 */
error LC_CollateralInUse(address collateralAddress, uint256 collateralId);

/**
 * @notice Ensure valid loan state for loan lifceycle operations.
 *
 * @param state                         Current state of a loan according to LoanState enum.
 */
error LC_InvalidState(LoanLibrary.LoanState state);

/**
 * @notice Loan duration has not expired.
 *
 * @param dueDate                       Timestamp of the end of the loan duration.
 */
error LC_NotExpired(uint256 dueDate);

/**
 * @notice User address and the specified nonce have already been used.
 *
 * @param user                          Address of collateral owner.
 * @param nonce                         Represents the number of transactions sent by address.
 */
error LC_NonceUsed(address user, uint160 nonce);

/**
 * @notice Installment loan has not defaulted.
 */
error LC_LoanNotDefaulted();

// ================================== Full Insterest Amount Calc ====================================
/// @notice All errors prefixed with FIAC_, to separate from other contracts in the protocol.

/**
 * @notice Interest must be greater than 0.01%. (interestRate / 1e18 >= 1)
 *
 * @param interestRate                  InterestRate with 1e18 multiplier.
 */
error FIAC_InterestRate(uint256 interestRate);

// ==================================== Promissory Note ======================================
/// @notice All errors prefixed with PN_, to separate from other contracts in the protocol.

/**
 * @notice Deployer is allowed to initialize roles. Caller is not deployer.
 */
error PN_CannotInitialize();

/**
 * @notice Roles have been initialized.
 */
error PN_AlreadyInitialized();

/**
 * @notice Caller of mint function must have the MINTER_ROLE in AccessControl.
 *
 * @param caller                        Address of the function caller.
 */
error PN_MintingRole(address caller);

/**
 * @notice Caller of burn function must have the BURNER_ROLE in AccessControl.
 *
 * @param caller                        Address of the function caller.
 */
error PN_BurningRole(address caller);

/**
 * @notice No token transfers while contract is in paused state.
 */
error PN_ContractPaused();

// ==================================== Fee Controller ======================================
/// @notice All errors prefixed with FC_, to separate from other contracts in the protocol.

/**
 * @notice Caller attempted to set a fee which is larger than the global maximum.
 */
error FC_FeeTooLarge();

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "./interfaces/IInstallmentsCalc.sol";

import { FIAC_InterestRate } from "./errors/Lending.sol";

/**
 * @title OriginationController
 * @author Non-Fungible Technologies, Inc.
 *
 * Interface for a calculating the interest amount
 * given an interest rate and principal amount. Assumes
 * that the interestRate is already expressed over the desired
 * time period.
 */
abstract contract InstallmentsCalc is IInstallmentsCalc {
    // ============================================ STATE ==============================================

    /// @dev The units of precision equal to the minimum interest of 1 basis point.
    uint256 public constant INTEREST_RATE_DENOMINATOR = 1e18;
    /// @dev The denominator to express the final interest in terms of basis ponits.
    uint256 public constant BASIS_POINTS_DENOMINATOR = 10_000;
    // Interest rate parameter
    uint256 public constant INSTALLMENT_PERIOD_MULTIPLIER = 1_000_000;
    // 50 / BASIS_POINTS_DENOMINATOR = 0.5%
    uint256 public constant LATE_FEE = 50;

    // ======================================== CALCULATIONS ===========================================

    /**
     * @notice Calculate the interest due over a full term.
     *
     * @dev Interest and principal must be entered with 18 units of
     *      precision from the basis point unit (e.g. 1e18 == 0.01%)
     *
     * @param principal                  Principal amount in the loan terms.
     * @param interestRate               Interest rate in the loan terms.
     *
     * @return interest                  The amount of interest due.
     */
    function getFullInterestAmount(uint256 principal, uint256 interestRate) public pure virtual returns (uint256) {
        // Interest rate to be greater than or equal to 0.01%
        if (interestRate / INTEREST_RATE_DENOMINATOR < 1) revert FIAC_InterestRate(interestRate);

        return principal + principal * interestRate / INTEREST_RATE_DENOMINATOR / BASIS_POINTS_DENOMINATOR;
    }

    /**
     * @notice Calculates and returns the current installment period relative to the loan's startDate,
     *         durationSecs, and numInstallments. Using these three parameters and the blocks current timestamp
     *         we are able to determine the current timeframe relative to the total number of installments.
     *
     * @dev Get current installment using the startDate, duration, and current time.
     *      In the section titled 'Get Timestamp Multiplier' DurationSecs must be greater
     *      than 10 seconds (10%10 = 0) and less than 1e18 seconds, this checked in
     *      _validateLoanTerms function in Origination Controller.
     *
     * @param startDate                    The start date of the loan as a timestamp.
     * @param durationSecs                 The duration of the loan in seconds.
     * @param numInstallments              The total number of installments in the loan terms.
     */
    function currentInstallmentPeriod(
        uint256 startDate,
        uint256 durationSecs,
        uint256 numInstallments
    ) internal view returns (uint256) {
        // *** Local State
        uint256 _currentTime = block.timestamp;
        uint256 _installmentPeriod = 1; // can only be called after the loan has started
        uint256 _relativeTimeInLoan = 0; // initial value
        uint256 _timestampMultiplier = 1e20; // inital value

        // *** Get Timestamp Mulitpier
        for (uint256 i = 1e18; i >= 10; i = i / 10) {
            if (durationSecs % i != durationSecs) {
                if (_timestampMultiplier == 1e20) {
                    _timestampMultiplier = (1e18 / i);
                }
            }
        }

        // *** Time Per Installment
        uint256 _timePerInstallment = durationSecs / numInstallments;

        // *** Relative Time In Loan
        _relativeTimeInLoan = (_currentTime - startDate) * _timestampMultiplier;

        // *** Check to see when _timePerInstallment * i is greater than _relativeTimeInLoan
        // Used to determine the current installment period. (j+1 to account for the current period)
        uint256 j = 1;
        while ((_timePerInstallment * j) * _timestampMultiplier <= _relativeTimeInLoan) {
            _installmentPeriod = j + 1;
            j++;
        }
        // *** Return
        return (_installmentPeriod);
    }

    /**
     * @notice Calculates and returns the compounded fees and minimum balance for all the missed payments
     *
     * @dev Get minimum installment payment due, and any late fees accrued due to payment being late
     *
     * @param balance                           Current balance of the loan
     * @param _interestRatePerInstallment       Interest rate per installment period
     * @param _installmentsMissed               Number of missed installment periods
     */
    function _getFees(
        uint256 balance,
        uint256 _interestRatePerInstallment,
        uint256 _installmentsMissed
    ) internal pure returns (uint256, uint256) {
        uint256 minInterestDue = 0; // initial state
        uint256 currentBal = balance; // remaining principal
        uint256 lateFees = 0; // initial state
        // calculate the late fees based on number of installments missed
        // late fees compound on any installment periods missed. For consecutive missed payments
        // late fees of first installment missed are added to the principal of the next late fees calculation
        for (uint256 i = 0; i < _installmentsMissed; i++) {
            // interest due per period based on currentBal value
            uint256 intDuePerPeriod = (((currentBal * _interestRatePerInstallment) / INSTALLMENT_PERIOD_MULTIPLIER) /
                BASIS_POINTS_DENOMINATOR);
            // update local state, next interest payment and late fee calculated off updated currentBal variable
            minInterestDue += intDuePerPeriod;
            lateFees += ((currentBal * LATE_FEE) / BASIS_POINTS_DENOMINATOR);
            currentBal += intDuePerPeriod + lateFees;
        }

        // one additional interest period added to _installmentsMissed for the current payment being made.
        // no late fees added to this payment. currentBal compounded.
        minInterestDue +=
            ((currentBal * _interestRatePerInstallment) / INSTALLMENT_PERIOD_MULTIPLIER) /
            BASIS_POINTS_DENOMINATOR;

        return (minInterestDue, lateFees);
    }

    /**
     * @notice Calculates and returns the minimum interest balance on loan, current late fees,
     *         and the current number of payments missed. If called twice in the same installment
     *         period, will return all zeros the second call.
     *
     * @dev Get minimum installment payment due, any late fees accrued, and
     *      the number of missed payments since the last installment payment.
     *
     *      1. Calculate relative time values to determine the number of installment periods missed.
     *      2. Is the repayment late based on the number of installment periods missed?
     *          Y. Calculate minimum balance due with late fees.
     *          N. Return only interest rate payment as minimum balance due.
     *
     * @param balance                           Current balance of the loan
     * @param startDate                         Timestamp of the start of the loan duration
     * @param durationSecs                      Duration of the loan in seconds
     * @param numInstallments                   Total number of installments in the loan
     * @param numInstallmentsPaid               Total number of installments paid, not including this current payment
     * @param interestRate                      The total interest rate for the loans duration from the loan terms
     */
    function _calcAmountsDue(
        uint256 balance,
        uint256 startDate,
        uint256 durationSecs,
        uint256 numInstallments,
        uint256 numInstallmentsPaid,
        uint256 interestRate
    )
        internal
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        // *** Installment Time
        uint256 _installmentPeriod = currentInstallmentPeriod(startDate, durationSecs, numInstallments);

        // *** Time related to number of installments paid
        if (numInstallmentsPaid >= _installmentPeriod) {
            // When numInstallmentsPaid is greater than or equal to the _installmentPeriod
            // this indicates that the minimum interest and any late fees for this installment period
            // have already been repaid. Any additional amount sent in this installment period goes to principal
            return (0, 0, 0);
        }

        // +1 for current install payment
        uint256 _installmentsMissed = _installmentPeriod - (numInstallmentsPaid + 1);

        // ** Installment Interest - using mulitpier of 1 million.
        // There should not be loan with more than 1 million installment periods. Checked in LoanCore.
        uint256 _interestRatePerInstallment = ((interestRate / INTEREST_RATE_DENOMINATOR) *
            INSTALLMENT_PERIOD_MULTIPLIER) / numInstallments;

        // ** Determine if late fees are added and if so, how much?
        // Calulate number of payments missed based on _latePayment, _pastDueDate

        // * If payment on time...
        if (_installmentsMissed == 0) {
            // Minimum balance due calculation. Based on interest per installment period
            uint256 minBalDue = ((balance * _interestRatePerInstallment) / INSTALLMENT_PERIOD_MULTIPLIER) /
                BASIS_POINTS_DENOMINATOR;

            return (minBalDue, 0, 0);
        }
        // * If payment is late, or past the loan duration...
        else {
            // get late fees based on number of payments missed and current principal due
            (uint256 minInterestDue, uint256 lateFees) = _getFees(
                balance,
                _interestRatePerInstallment,
                _installmentsMissed
            );

            return (minInterestDue, lateFees, _installmentsMissed);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "./ICallWhitelist.sol";

interface IAssetVault {
    // ============= Events ==============

    event WithdrawEnabled(address operator);
    event WithdrawERC20(address indexed operator, address indexed token, address recipient, uint256 amount);
    event WithdrawERC721(address indexed operator, address indexed token, address recipient, uint256 tokenId);
    event WithdrawPunk(address indexed operator, address indexed token, address recipient, uint256 tokenId);

    event WithdrawERC1155(
        address indexed operator,
        address indexed token,
        address recipient,
        uint256 tokenId,
        uint256 amount
    );

    event WithdrawETH(address indexed operator, address indexed recipient, uint256 amount);
    event Call(address indexed operator, address indexed to, bytes data);

    // ================= Initializer ==================

    function initialize(address _whitelist) external;

    // ================ View Functions ================

    function withdrawEnabled() external view returns (bool);

    function whitelist() external view returns (ICallWhitelist);

    // ================ Withdrawal Operations ================

    function enableWithdraw() external;

    function withdrawERC20(address token, address to) external;

    function withdrawERC721(
        address token,
        uint256 tokenId,
        address to
    ) external;

    function withdrawERC1155(
        address token,
        uint256 tokenId,
        address to
    ) external;

    function withdrawETH(address to) external;

    function withdrawPunk(
        address punks,
        uint256 punkIndex,
        address to
    ) external;

    // ================ Utility Operations ================

    function call(address to, bytes memory data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

interface ICallWhitelist {
    // ============= Events ==============

    event CallAdded(address operator, address callee, bytes4 selector);
    event CallRemoved(address operator, address callee, bytes4 selector);

    // ================ View Functions ================

    function isWhitelisted(address callee, bytes4 selector) external view returns (bool);

    function isBlacklisted(bytes4 selector) external view returns (bool);

    // ================ Update Operations ================

    function add(address callee, bytes4 selector) external;

    function remove(address callee, bytes4 selector) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

interface IFeeController {
    // ================ Events =================

    event UpdateOriginationFee(uint256 _newFee);
    event UpdateRolloverFee(uint256 _newFee);

    // ================ Fee Setters =================

    function setOriginationFee(uint256 _originationFee) external;

    function setRolloverFee(uint256 _rolloverFee) external;

    // ================ Fee Getters =================

    function getOriginationFee() external view returns (uint256);

    function getRolloverFee() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

interface IInstallmentsCalc {
    // ================ View Functions ================

    function getFullInterestAmount(uint256 principal, uint256 interestRate) external returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "../libraries/LoanLibrary.sol";

import "./IPromissoryNote.sol";
import "./IFeeController.sol";
import "./ILoanCore.sol";

interface ILoanCore {
    // ================ Events =================

    event LoanCreated(LoanLibrary.LoanTerms terms, uint256 loanId);
    event LoanStarted(uint256 loanId, address lender, address borrower);
    event LoanRepaid(uint256 loanId);
    event LoanRolledOver(uint256 oldLoanId, uint256 newLoanId);
    event InstallmentPaymentReceived(uint256 loanId, uint256 repaidAmount, uint256 remBalance);
    event LoanClaimed(uint256 loanId);
    event FeesClaimed(address token, address to, uint256 amount);
    event SetFeeController(address feeController);
    event NonceUsed(address indexed user, uint160 nonce);

    // ============== Lifecycle Operations ==============

    function startLoan(
        address lender,
        address borrower,
        LoanLibrary.LoanTerms calldata terms
    ) external returns (uint256 loanId);

    function repay(uint256 loanId) external;

    function repayPart(
        uint256 _loanId,
        uint256 _currentMissedPayments,
        uint256 _paymentToPrincipal,
        uint256 _paymentToInterest,
        uint256 _paymentToLateFees
    ) external;

    function claim(uint256 loanId, uint256 currentInstallmentPeriod) external;

    function rollover(
        uint256 oldLoanId,
        address borrower,
        address lender,
        LoanLibrary.LoanTerms calldata terms,
        uint256 _settledAmount,
        uint256 _amountToOldLender,
        uint256 _amountToLender,
        uint256 _amountToBorrower
    ) external returns (uint256 newLoanId);

    // ============== Nonce Management ==============

    function consumeNonce(address user, uint160 nonce) external;

    function cancelNonce(uint160 nonce) external;

    // ============== View Functions ==============

    function getLoan(uint256 loanId) external view returns (LoanLibrary.LoanData calldata loanData);

    function isNonceUsed(address user, uint160 nonce) external view returns (bool);

    function borrowerNote() external returns (IPromissoryNote);

    function lenderNote() external returns (IPromissoryNote);

    function feeController() external returns (IFeeController);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface IPromissoryNote is IERC721Enumerable {
    // ============== Token Operations ==============

    function mint(address to, uint256 loanId) external returns (uint256);

    function burn(uint256 tokenId) external;

    function setPaused(bool paused) external;

    // ============== Initializer ==============

    function initialize(address loanCore) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

interface IRepaymentController {
    // ============== Lifeycle Operations ==============

    function repay(uint256 loanId) external;

    function claim(uint256 loanId) external;

    function repayPartMinimum(uint256 loanId) external;

    function repayPart(uint256 loanId, uint256 amount) external;

    function closeLoan(uint256 loanId) external;

    // ============== View Functions ==============

    function getInstallmentMinPayment(uint256 loanId)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    function amountToCloseLoan(uint256 loanId) external returns (uint256, uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

interface IVaultFactory {
    // ============= Events ==============

    event VaultCreated(address vault, address to);

    // ================ View Functions ================

    function isInstance(address instance) external view returns (bool validity);

    function instanceCount() external view returns (uint256);

    function instanceAt(uint256 tokenId) external view returns (address);

    function instanceAtIndex(uint256 index) external view returns (address);

    // ================ Factory Operations ================

    function initializeBundle(address to) external returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

/**
 * @title LoanLibrary
 * @author Non-Fungible Technologies, Inc.
 *
 * Contains all data types used across Arcade lending contracts.
 */
library LoanLibrary {
    /**
     * @dev Enum describing the current state of a loan.
     * State change flow:
     * Created -> Active -> Repaid
     *                   -> Defaulted
     */
    enum LoanState {
        // We need a default that is not 'Created' - this is the zero value
        DUMMY_DO_NOT_USE,
        // The loan has been initialized, funds have been delivered to the borrower and the collateral is held.
        Active,
        // The loan has been repaid, and the collateral has been returned to the borrower. This is a terminal state.
        Repaid,
        // The loan was delinquent and collateral claimed by the lender. This is a terminal state.
        Defaulted
    }

    /**
     * @dev The raw terms of a loan.
     */
    struct LoanTerms {
        /// @dev Packed variables
        // The number of seconds representing relative due date of the loan.
        /// @dev Max is 94,608,000, fits in 32 bits
        uint32 durationSecs;
        // Timestamp for when signature for terms expires
        uint32 deadline;
        // Total number of installment periods within the loan duration.
        /// @dev Max is 1,000,000, fits in 24 bits
        uint24 numInstallments;
        // Interest expressed as a rate, unlike V1 gross value.
        // Input conversion: 0.01% = (1 * 10**18) ,  10.00% = (1000 * 10**18)
        // This represents the rate over the lifetime of the loan, not APR.
        // 0.01% is the minimum interest rate allowed by the protocol.
        /// @dev Max is 10,000%, fits in 160 bits
        uint160 interestRate;
        /// @dev Full-slot variables
        // The amount of principal in terms of the payableCurrency.
        uint256 principal;
        // The token ID of the address holding the collateral.
        /// @dev Can be an AssetVault, or the NFT contract for unbundled collateral
        address collateralAddress;
        // The token ID of the collateral.
        uint256 collateralId;
        // The payable currency for the loan principal and interest.
        address payableCurrency;
    }

    /**
     * @dev Modification of loan terms, used for signing only.
     *      Instead of a collateralId, a list of predicates
     *      is defined by 'bytes' in items.
     */
    struct LoanTermsWithItems {
        /// @dev Packed variables
        // The number of seconds representing relative due date of the loan.
        /// @dev Max is 94,608,000, fits in 32 bits
        uint32 durationSecs;
        // Timestamp for when signature for terms expires
        uint32 deadline;
        // Total number of installment periods within the loan duration.
        /// @dev Max is 1,000,000, fits in 24 bits
        uint24 numInstallments;
        // Interest expressed as a rate, unlike V1 gross value.
        // Input conversion: 0.01% = (1 * 10**18) ,  10.00% = (1000 * 10**18)
        // This represents the rate over the lifetime of the loan, not APR.
        // 0.01% is the minimum interest rate allowed by the protocol.
        /// @dev Max is 10,000%, fits in 160 bits
        uint160 interestRate;
        /// @dev Full-slot variables
        uint256 principal;
        // The tokenID of the address holding the collateral
        /// @dev Must be an AssetVault for LoanTermsWithItems
        address collateralAddress;
        // An encoded list of predicates
        bytes items;
        // The payable currency for the loan principal and interest
        address payableCurrency;
    }

    /**
     * @dev Predicate for item-based verifications
     */
    struct Predicate {
        // The encoded predicate, to decoded and parsed by the verifier contract
        bytes data;
        // The verifier contract
        address verifier;
    }

    /**
     * @dev The data of a loan. This is stored once the loan is Active
     */
    struct LoanData {
        /// @dev Packed variables
        // The current state of the loan
        LoanState state;
        // Number of installment payments made on the loan
        uint24 numInstallmentsPaid;
        // installment loan specific
        // Start date of the loan, using block.timestamp - for determining installment period
        uint160 startDate;
        /// @dev Full-slot variables
        // The raw terms of the loan
        LoanTerms terms;
        // Remaining balance of the loan. Starts as equal to principal. Can reduce based on
        // payments made, can increased based on compounded interest from missed payments and late fees
        uint256 balance;
        // Amount paid in total by the borrower
        uint256 balancePaid;
        // Total amount of late fees accrued
        uint256 lateFeesAccrued;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

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
    constructor() {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
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

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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

pragma solidity 0.8.15;

/**
 * @title CollateralSaleErrors
 * @author Non-Fungible Technologies, Inc.
 *
 * This file contains custom errors for the CollateralSale contract used by Arcade.xyz.
 * All errors are prefixed by the contract that throws them (e.g., "CS_" for Collateral Sale).
 * Errors located in one place make it possible to holistically look at all CollateralSale failure cases.
 */

// ======================================== Errors ========================================

/**
 * @notice No vault items specified.
 */
error CS_ZeroVaultItems();

/**
 * @notice Item targeted for sale is not in specified vault.
 *
 * @param vaultAddress              The vault contract address.
 */
error CS_VaultItemsNotFound(address vaultAddress);

/**
 * @notice The specified currency in the order to fulfill does not match
 *         the loan currency.
 *
 * @param orderCurrency             The currency specified in the sale order.
 * @param loanCurrency              The currency specified in the active loan.
 */
error CS_CurrencyMismatch(address orderCurrency, address loanCurrency);

/**
 * @notice The provided loan's collateral is not stored in a compatible AssetVault.
 *
 * @param collateralAddress         The address of the collateral in the active loan.
 */
error CS_IncompatibleCollateral(address collateralAddress);

/**
 * @notice The sale function was called by a user other than the borrower.
 *
 * @param caller                    The msg.sender.
 * @param borrower                  The loan's borrower.
 */
error CS_NotBorrower(address caller, address borrower);

/**
 * @notice CollateralSale was told to sell a non-721 and non-1155 asset into a vault, which
 *         it is not set up to handle.
 *
 * @param itemType                  The item type provided.
 */
error CS_UnsupportedVaultItem(uint256 itemType);

/**
 * @notice The offer being fulfilled for the sale is not enough to repay the amount
 *         owed on the loan.
 *
 * @param offerTotal                The total proceeds of the sale.
 * @param owed                      The amount owed on the loan.
 */
error CS_CannotRepay(uint256 offerTotal, uint256 owed);

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

/**
 * @title FlashConsumerErrors
 * @author Non-Fungible Technologies, Inc.
 *
 * This file contains custom errors related to flash loans for all Lending Plus contracts.
 * All errors are prefixed "FC_" for Flash Consumer. Errors located in one place to make it
 * possible to holistically look at all flash loan failure cases.
 */

// ======================================== Errors ========================================

/**
 * @notice Callback did not come from the flash liquidity pool.
 *
 * @param caller               The address of the caller.
 */
error FC_UnknownCallbackSender(address caller);

/**
 * @notice The initaitor must be the contract that called for the flash loan.
 * (i.e., the lending plus contract)
 *
 * @param initiator             The address of the account initiating the flash loan.
 */
error FC_NotInitiator(address initiator);

/**
 * @notice For loans which use local state to track the start/end of a flash loan,
 *         the ending state after calling _flashLoan was not correct.
 */
error FC_InvalidEndState();

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import { BasicOrderType } from "../external/seaport/lib/ConsiderationStructs.sol";

/**
 * @title OrderRouterErrors
 * @author Non-Fungible Technologies, Inc.
 *
 * This file contains custom errors for the OrderRouter contract used by Lending
 * Plus protocol. All errors are prefixed by the contract that throws them
 * (e.g., "OR_" for Order Router). Errors located in one place to make it possible to
 * holistically look at all OrderRouter failure cases.
 */

// ======================================== Errors ========================================

/**
 * @notice Zero address passed in where not allowed.
 */
error OR_ZeroAddress();

/**
 * @notice Call to the specified marketplace has failed.
 *
 * @param data                              The calldata passed to the marketplace.
 */
error OR_CallFailed(bytes data);

/**
 * @notice Unsupported basicOrderType sent for order fulfillment. Only FULL_OPEN allowed.
 *
 * @param orderType                         The provided basic order type.
 */
error OR_UnsupportedSeaport(BasicOrderType orderType);

/**
 * @notice Not enough ETH sent with the function call to fulfill marketplace order.
 *
 * @param value                             The amount of ETH provided with the transaction.
 * @param needed                            The amount of ETH needed for the order.
 */
error OR_MoreETHRequired(uint256 value, uint256 needed);

/**
 * @notice Ether was sent to the contract at an unexpected time.
 */
error OR_NoReceive();

/* solhint-disable max-line-length */

pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library DataTypes {
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

    enum InterestRateMode {
        NONE,
        STABLE,
        VARIABLE
    }
}

/**
 * @title LendingPoolAddressesProvider contract
 * @dev Main registry of addresses part of or connected to the protocol, including permissioned roles
 * - Acting also as factory of proxies and admin of those, so with right to change its implementations
 * - Owned by the Aave Governance
 * @author Aave
 **/
interface ILendingPoolAddressesProvider {
    event LendingPoolUpdated(address indexed newAddress);
    event ConfigurationAdminUpdated(address indexed newAddress);
    event EmergencyAdminUpdated(address indexed newAddress);
    event LendingPoolConfiguratorUpdated(address indexed newAddress);
    event LendingPoolCollateralManagerUpdated(address indexed newAddress);
    event PriceOracleUpdated(address indexed newAddress);
    event LendingRateOracleUpdated(address indexed newAddress);
    event ProxyCreated(bytes32 id, address indexed newAddress);
    event AddressSet(bytes32 id, address indexed newAddress, bool hasProxy);

    function setAddress(bytes32 id, address newAddress) external;

    function setAddressAsProxy(bytes32 id, address impl) external;

    function getAddress(bytes32 id) external view returns (address);

    function getLendingPool() external view returns (address);

    function setLendingPoolImpl(address pool) external;

    function getLendingPoolConfigurator() external view returns (address);

    function setLendingPoolConfiguratorImpl(address configurator) external;

    function getLendingPoolCollateralManager() external view returns (address);

    function setLendingPoolCollateralManager(address manager) external;

    function getPoolAdmin() external view returns (address);

    function setPoolAdmin(address admin) external;

    function getEmergencyAdmin() external view returns (address);

    function setEmergencyAdmin(address admin) external;

    function getPriceOracle() external view returns (address);

    function setPriceOracle(address priceOracle) external;

    function getLendingRateOracle() external view returns (address);

    function setLendingRateOracle(address lendingRateOracle) external;
}

interface ILendingPool {
    /**
     * @dev Emitted on deposit()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The address initiating the deposit
     * @param onBehalfOf The beneficiary of the deposit, receiving the aTokens
     * @param amount The amount deposited
     * @param referral The referral code used
     **/
    event Deposit(
        address indexed reserve,
        address user,
        address indexed onBehalfOf,
        uint256 amount,
        uint16 indexed referral
    );

    /**
     * @dev Emitted on withdraw()
     * @param reserve The address of the underlyng asset being withdrawn
     * @param user The address initiating the withdrawal, owner of aTokens
     * @param to Address that will receive the underlying
     * @param amount The amount to be withdrawn
     **/
    event Withdraw(address indexed reserve, address indexed user, address indexed to, uint256 amount);

    /**
     * @dev Emitted on borrow() and flashLoan() when debt needs to be opened
     * @param reserve The address of the underlying asset being borrowed
     * @param user The address of the user initiating the borrow(), receiving the funds on borrow() or just
     * initiator of the transaction on flashLoan()
     * @param onBehalfOf The address that will be getting the debt
     * @param amount The amount borrowed out
     * @param borrowRateMode The rate mode: 1 for Stable, 2 for Variable
     * @param borrowRate The numeric rate at which the user has borrowed
     * @param referral The referral code used
     **/
    event Borrow(
        address indexed reserve,
        address user,
        address indexed onBehalfOf,
        uint256 amount,
        uint256 borrowRateMode,
        uint256 borrowRate,
        uint16 indexed referral
    );

    /**
     * @dev Emitted on repay()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The beneficiary of the repayment, getting his debt reduced
     * @param repayer The address of the user initiating the repay(), providing the funds
     * @param amount The amount repaid
     **/
    event Repay(address indexed reserve, address indexed user, address indexed repayer, uint256 amount);

    /**
     * @dev Emitted on swapBorrowRateMode()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The address of the user swapping his rate mode
     * @param rateMode The rate mode that the user wants to swap to
     **/
    event Swap(address indexed reserve, address indexed user, uint256 rateMode);

    /**
     * @dev Emitted on setUserUseReserveAsCollateral()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The address of the user enabling the usage as collateral
     **/
    event ReserveUsedAsCollateralEnabled(address indexed reserve, address indexed user);

    /**
     * @dev Emitted on setUserUseReserveAsCollateral()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The address of the user enabling the usage as collateral
     **/
    event ReserveUsedAsCollateralDisabled(address indexed reserve, address indexed user);

    /**
     * @dev Emitted on rebalanceStableBorrowRate()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The address of the user for which the rebalance has been executed
     **/
    event RebalanceStableBorrowRate(address indexed reserve, address indexed user);

    /**
     * @dev Emitted on flashLoan()
     * @param target The address of the flash loan receiver contract
     * @param initiator The address initiating the flash loan
     * @param asset The address of the asset being flash borrowed
     * @param amount The amount flash borrowed
     * @param premium The fee flash borrowed
     * @param referralCode The referral code used
     **/
    event FlashLoan(
        address indexed target,
        address indexed initiator,
        address indexed asset,
        uint256 amount,
        uint256 premium,
        uint16 referralCode
    );

    /**
     * @dev Emitted when the pause is triggered.
     */
    event Paused();

    /**
     * @dev Emitted when the pause is lifted.
     */
    event Unpaused();

    /**
     * @dev Emitted when a borrower is liquidated. This event is emitted by the LendingPool via
     * LendingPoolCollateral manager using a DELEGATECALL
     * This allows to have the events in the generated ABI for LendingPool.
     * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
     * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
     * @param user The address of the borrower getting liquidated
     * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
     * @param liquidatedCollateralAmount The amount of collateral received by the liiquidator
     * @param liquidator The address of the liquidator
     * @param receiveAToken `true` if the liquidators wants to receive the collateral aTokens, `false` if he wants
     * to receive the underlying collateral asset directly
     **/
    event LiquidationCall(
        address indexed collateralAsset,
        address indexed debtAsset,
        address indexed user,
        uint256 debtToCover,
        uint256 liquidatedCollateralAmount,
        address liquidator,
        bool receiveAToken
    );

    /**
     * @dev Emitted when the state of a reserve is updated. NOTE: This event is actually declared
     * in the ReserveLogic library and emitted in the updateInterestRates() function. Since the function is internal,
     * the event will actually be fired by the LendingPool contract. The event is therefore replicated here so it
     * gets added to the LendingPool ABI
     * @param reserve The address of the underlying asset of the reserve
     * @param liquidityRate The new liquidity rate
     * @param stableBorrowRate The new stable borrow rate
     * @param variableBorrowRate The new variable borrow rate
     * @param liquidityIndex The new liquidity index
     * @param variableBorrowIndex The new variable borrow index
     **/
    event ReserveDataUpdated(
        address indexed reserve,
        uint256 liquidityRate,
        uint256 stableBorrowRate,
        uint256 variableBorrowRate,
        uint256 liquidityIndex,
        uint256 variableBorrowIndex
    );

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
     **/
    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external;

    /**
     * @dev Allows users to borrow a specific `amount` of the reserve underlying asset, provided that the borrower
     * already deposited enough collateral, or he was given enough allowance by a credit delegator on the
     * corresponding debt token (StableDebtToken or VariableDebtToken)
     * - E.g. User borrows 100 USDC passing as `onBehalfOf` his own address, receiving the 100 USDC in his wallet
     *   and 100 stable/variable debt tokens, depending on the `interestRateMode`
     * @param asset The address of the underlying asset to borrow
     * @param amount The amount to be borrowed
     * @param interestRateMode The interest rate mode at which the user wants to borrow: 1 for Stable, 2 for Variable
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     * @param onBehalfOf Address of the user who will receive the debt. Should be the address of the borrower itself
     * calling the function if he wants to borrow against his own collateral, or the address of the credit delegator
     * if he has been given credit delegation allowance
     **/
    function borrow(
        address asset,
        uint256 amount,
        uint256 interestRateMode,
        uint16 referralCode,
        address onBehalfOf
    ) external;

    /**
     * @notice Repays a borrowed `amount` on a specific reserve, burning the equivalent debt tokens owned
     * - E.g. User repays 100 USDC, burning 100 variable/stable debt tokens of the `onBehalfOf` address
     * @param asset The address of the borrowed underlying asset previously borrowed
     * @param amount The amount to repay
     * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `debtMode`
     * @param rateMode The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
     * @param onBehalfOf Address of the user who will get his debt reduced/removed. Should be the address of the
     * user calling the function if he wants to reduce/remove his own debt, or the address of any other
     * other borrower whose debt should be removed
     **/
    function repay(
        address asset,
        uint256 amount,
        uint256 rateMode,
        address onBehalfOf
    ) external;

    /**
     * @dev Allows a borrower to swap his debt between stable and variable mode, or viceversa
     * @param asset The address of the underlying asset borrowed
     * @param rateMode The rate mode that the user wants to swap to
     **/
    function swapBorrowRateMode(address asset, uint256 rateMode) external;

    /**
     * @dev Rebalances the stable interest rate of a user to the current stable rate defined on the reserve.
     * - Users can be rebalanced if the following conditions are satisfied:
     *     1. Usage ratio is above 95%
     *     2. the current deposit APY is below REBALANCE_UP_THRESHOLD * maxVariableBorrowRate, which means that too much has been
     *        borrowed at a stable rate and depositors are not earning enough
     * @param asset The address of the underlying asset borrowed
     * @param user The address of the user to be rebalanced
     **/
    function rebalanceStableBorrowRate(address asset, address user) external;

    /**
     * @dev Allows depositors to enable/disable a specific deposited asset as collateral
     * @param asset The address of the underlying asset deposited
     * @param useAsCollateral `true` if the user wants to use the deposit as collateral, `false` otherwise
     **/
    function setUserUseReserveAsCollateral(address asset, bool useAsCollateral) external;

    /**
     * @dev Function to liquidate a non-healthy position collateral-wise, with Health Factor below 1
     * - The caller (liquidator) covers `debtToCover` amount of debt of the user getting liquidated, and receives
     *   a proportionally amount of the `collateralAsset` plus a bonus to cover market risk
     * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
     * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
     * @param user The address of the borrower getting liquidated
     * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
     * @param receiveAToken `true` if the liquidators wants to receive the collateral aTokens, `false` if he wants
     * to receive the underlying collateral asset directly
     **/
    function liquidationCall(
        address collateralAsset,
        address debtAsset,
        address user,
        uint256 debtToCover,
        bool receiveAToken
    ) external;

    /**
     * @dev Allows smartcontracts to access the liquidity of the pool within one transaction,
     * as long as the amount taken plus a fee is returned.
     * IMPORTANT There are security concerns for developers of flashloan receiver contracts that must be kept into consideration.
     * For further details please visit https://developers.aave.com
     * @param receiverAddress The address of the contract receiving the funds, implementing the IFlashLoanReceiver interface
     * @param assets The addresses of the assets being flash-borrowed
     * @param amounts The amounts amounts being flash-borrowed
     * @param modes Types of the debt to open if the flash loan is not returned:
     *   0 -> Don't open any debt, just revert if funds can't be transferred from the receiver
     *   1 -> Open debt at stable rate for the value of the amount flash-borrowed to the `onBehalfOf` address
     *   2 -> Open debt at variable rate for the value of the amount flash-borrowed to the `onBehalfOf` address
     * @param onBehalfOf The address  that will receive the debt in the case of using on `modes` 1 or 2
     * @param params Variadic packed params to pass to the receiver as extra information
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     **/
    function flashLoan(
        address receiverAddress,
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata modes,
        address onBehalfOf,
        bytes calldata params,
        uint16 referralCode
    ) external;

    /**
     * @dev Returns the user account data across all the reserves
     * @param user The address of the user
     * @return totalCollateralETH the total collateral in ETH of the user
     * @return totalDebtETH the total debt in ETH of the user
     * @return availableBorrowsETH the borrowing power left of the user
     * @return currentLiquidationThreshold the liquidation threshold of the user
     * @return ltv the loan to value of the user
     * @return healthFactor the current health factor of the user
     **/
    function getUserAccountData(address user)
        external
        view
        returns (
            uint256 totalCollateralETH,
            uint256 totalDebtETH,
            uint256 availableBorrowsETH,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor
        );

    function initReserve(
        address reserve,
        address aTokenAddress,
        address stableDebtAddress,
        address variableDebtAddress,
        address interestRateStrategyAddress
    ) external;

    function setReserveInterestRateStrategyAddress(address reserve, address rateStrategyAddress) external;

    function setConfiguration(address reserve, uint256 configuration) external;

    /**
     * @dev Returns the configuration of the reserve
     * @param asset The address of the underlying asset of the reserve
     * @return The configuration of the reserve
     **/
    function getConfiguration(address asset) external view returns (DataTypes.ReserveConfigurationMap memory);

    /**
     * @dev Returns the configuration of the user across all the reserves
     * @param user The user address
     * @return The configuration of the user
     **/
    function getUserConfiguration(address user) external view returns (DataTypes.UserConfigurationMap memory);

    /**
     * @dev Returns the normalized income normalized income of the reserve
     * @param asset The address of the underlying asset of the reserve
     * @return The reserve's normalized income
     */
    function getReserveNormalizedIncome(address asset) external view returns (uint256);

    /**
     * @dev Returns the normalized variable debt per unit of asset
     * @param asset The address of the underlying asset of the reserve
     * @return The reserve normalized variable debt
     */
    function getReserveNormalizedVariableDebt(address asset) external view returns (uint256);

    /**
     * @dev Returns the state and configuration of the reserve
     * @param asset The address of the underlying asset of the reserve
     * @return The state of the reserve
     **/
    function getReserveData(address asset) external view returns (DataTypes.ReserveData memory);

    function finalizeTransfer(
        address asset,
        address from,
        address to,
        uint256 amount,
        uint256 balanceFromAfter,
        uint256 balanceToBefore
    ) external;

    function getReservesList() external view returns (address[] memory);

    function getAddressesProvider() external view returns (ILendingPoolAddressesProvider);

    function setPause(bool val) external;

    function paused() external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWETH is IERC20 {
    function deposit() external payable;
    function withdraw(uint256 wad) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// prettier-ignore
enum OrderType {
    // 0: no partial fills, anyone can execute
    FULL_OPEN,

    // 1: partial fills supported, anyone can execute
    PARTIAL_OPEN,

    // 2: no partial fills, only offerer or zone can execute
    FULL_RESTRICTED,

    // 3: partial fills supported, only offerer or zone can execute
    PARTIAL_RESTRICTED
}

// prettier-ignore
enum BasicOrderType {
    // 0: no partial fills, anyone can execute
    ETH_TO_ERC721_FULL_OPEN,

    // 1: partial fills supported, anyone can execute
    ETH_TO_ERC721_PARTIAL_OPEN,

    // 2: no partial fills, only offerer or zone can execute
    ETH_TO_ERC721_FULL_RESTRICTED,

    // 3: partial fills supported, only offerer or zone can execute
    ETH_TO_ERC721_PARTIAL_RESTRICTED,

    // 4: no partial fills, anyone can execute
    ETH_TO_ERC1155_FULL_OPEN,

    // 5: partial fills supported, anyone can execute
    ETH_TO_ERC1155_PARTIAL_OPEN,

    // 6: no partial fills, only offerer or zone can execute
    ETH_TO_ERC1155_FULL_RESTRICTED,

    // 7: partial fills supported, only offerer or zone can execute
    ETH_TO_ERC1155_PARTIAL_RESTRICTED,

    // 8: no partial fills, anyone can execute
    ERC20_TO_ERC721_FULL_OPEN,

    // 9: partial fills supported, anyone can execute
    ERC20_TO_ERC721_PARTIAL_OPEN,

    // 10: no partial fills, only offerer or zone can execute
    ERC20_TO_ERC721_FULL_RESTRICTED,

    // 11: partial fills supported, only offerer or zone can execute
    ERC20_TO_ERC721_PARTIAL_RESTRICTED,

    // 12: no partial fills, anyone can execute
    ERC20_TO_ERC1155_FULL_OPEN,

    // 13: partial fills supported, anyone can execute
    ERC20_TO_ERC1155_PARTIAL_OPEN,

    // 14: no partial fills, only offerer or zone can execute
    ERC20_TO_ERC1155_FULL_RESTRICTED,

    // 15: partial fills supported, only offerer or zone can execute
    ERC20_TO_ERC1155_PARTIAL_RESTRICTED,

    // 16: no partial fills, anyone can execute
    ERC721_TO_ERC20_FULL_OPEN,

    // 17: partial fills supported, anyone can execute
    ERC721_TO_ERC20_PARTIAL_OPEN,

    // 18: no partial fills, only offerer or zone can execute
    ERC721_TO_ERC20_FULL_RESTRICTED,

    // 19: partial fills supported, only offerer or zone can execute
    ERC721_TO_ERC20_PARTIAL_RESTRICTED,

    // 20: no partial fills, anyone can execute
    ERC1155_TO_ERC20_FULL_OPEN,

    // 21: partial fills supported, anyone can execute
    ERC1155_TO_ERC20_PARTIAL_OPEN,

    // 22: no partial fills, only offerer or zone can execute
    ERC1155_TO_ERC20_FULL_RESTRICTED,

    // 23: partial fills supported, only offerer or zone can execute
    ERC1155_TO_ERC20_PARTIAL_RESTRICTED
}

// prettier-ignore
enum BasicOrderRouteType {
    // 0: provide Ether (or other native token) to receive offered ERC721 item.
    ETH_TO_ERC721,

    // 1: provide Ether (or other native token) to receive offered ERC1155 item.
    ETH_TO_ERC1155,

    // 2: provide ERC20 item to receive offered ERC721 item.
    ERC20_TO_ERC721,

    // 3: provide ERC20 item to receive offered ERC1155 item.
    ERC20_TO_ERC1155,

    // 4: provide ERC721 item to receive offered ERC20 item.
    ERC721_TO_ERC20,

    // 5: provide ERC1155 item to receive offered ERC20 item.
    ERC1155_TO_ERC20
}

// prettier-ignore
enum ItemType {
    // 0: ETH on mainnet, MATIC on polygon, etc.
    NATIVE,

    // 1: ERC20 items (ERC777 and ERC20 analogues could also technically work)
    ERC20,

    // 2: ERC721 items
    ERC721,

    // 3: ERC1155 items
    ERC1155,

    // 4: ERC721 items where a number of tokenIds are supported
    ERC721_WITH_CRITERIA,

    // 5: ERC1155 items where a number of ids are supported
    ERC1155_WITH_CRITERIA
}

// prettier-ignore
enum Side {
    // 0: Items that can be spent
    OFFER,

    // 1: Items that must be received
    CONSIDERATION
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import {
    OrderType,
    BasicOrderType,
    ItemType,
    Side
} from "./ConsiderationEnums.sol";

/**
 * @dev An order contains eleven components: an offerer, a zone (or account that
 *      can cancel the order or restrict who can fulfill the order depending on
 *      the type), the order type (specifying partial fill support as well as
 *      restricted order status), the start and end time, a hash that will be
 *      provided to the zone when validating restricted orders, a salt, a key
 *      corresponding to a given conduit, a counter, and an arbitrary number of
 *      offer items that can be spent along with consideration items that must
 *      be received by their respective recipient.
 */
struct OrderComponents {
    address offerer;
    address zone;
    OfferItem[] offer;
    ConsiderationItem[] consideration;
    OrderType orderType;
    uint256 startTime;
    uint256 endTime;
    bytes32 zoneHash;
    uint256 salt;
    bytes32 conduitKey;
    uint256 counter;
}

/**
 * @dev An offer item has five components: an item type (ETH or other native
 *      tokens, ERC20, ERC721, and ERC1155, as well as criteria-based ERC721 and
 *      ERC1155), a token address, a dual-purpose "identifierOrCriteria"
 *      component that will either represent a tokenId or a merkle root
 *      depending on the item type, and a start and end amount that support
 *      increasing or decreasing amounts over the duration of the respective
 *      order.
 */
struct OfferItem {
    ItemType itemType;
    address token;
    uint256 identifierOrCriteria;
    uint256 startAmount;
    uint256 endAmount;
}

/**
 * @dev A consideration item has the same five components as an offer item and
 *      an additional sixth component designating the required recipient of the
 *      item.
 */
struct ConsiderationItem {
    ItemType itemType;
    address token;
    uint256 identifierOrCriteria;
    uint256 startAmount;
    uint256 endAmount;
    address payable recipient;
}

/**
 * @dev A spent item is translated from a utilized offer item and has four
 *      components: an item type (ETH or other native tokens, ERC20, ERC721, and
 *      ERC1155), a token address, a tokenId, and an amount.
 */
struct SpentItem {
    ItemType itemType;
    address token;
    uint256 identifier;
    uint256 amount;
}

/**
 * @dev A received item is translated from a utilized consideration item and has
 *      the same four components as a spent item, as well as an additional fifth
 *      component designating the required recipient of the item.
 */
struct ReceivedItem {
    ItemType itemType;
    address token;
    uint256 identifier;
    uint256 amount;
    address payable recipient;
}

/**
 * @dev For basic orders involving ETH / native / ERC20 <=> ERC721 / ERC1155
 *      matching, a group of six functions may be called that only requires a
 *      subset of the usual order arguments. Note the use of a "basicOrderType"
 *      enum; this represents both the usual order type as well as the "route"
 *      of the basic order (a simple derivation function for the basic order
 *      type is `basicOrderType = orderType + (4 * basicOrderRoute)`.)
 */
struct BasicOrderParameters {
    // calldata offset
    address considerationToken; // 0x24
    uint256 considerationIdentifier; // 0x44
    uint256 considerationAmount; // 0x64
    address payable offerer; // 0x84
    address zone; // 0xa4
    address offerToken; // 0xc4
    uint256 offerIdentifier; // 0xe4
    uint256 offerAmount; // 0x104
    BasicOrderType basicOrderType; // 0x124
    uint256 startTime; // 0x144
    uint256 endTime; // 0x164
    bytes32 zoneHash; // 0x184
    uint256 salt; // 0x1a4
    bytes32 offererConduitKey; // 0x1c4
    bytes32 fulfillerConduitKey; // 0x1e4
    uint256 totalOriginalAdditionalRecipients; // 0x204
    AdditionalRecipient[] additionalRecipients; // 0x224
    bytes signature; // 0x244
    // Total length, excluding dynamic array data: 0x264 (580)
}

/**
 * @dev Basic orders can supply any number of additional recipients, with the
 *      implied assumption that they are supplied from the offered ETH (or other
 *      native token) or ERC20 token for the order.
 */
struct AdditionalRecipient {
    uint256 amount;
    address payable recipient;
}

/**
 * @dev The full set of order components, with the exception of the counter,
 *      must be supplied when fulfilling more sophisticated orders or groups of
 *      orders. The total number of original consideration items must also be
 *      supplied, as the caller may specify additional consideration items.
 */
struct OrderParameters {
    address offerer; // 0x00
    address zone; // 0x20
    OfferItem[] offer; // 0x40
    ConsiderationItem[] consideration; // 0x60
    OrderType orderType; // 0x80
    uint256 startTime; // 0xa0
    uint256 endTime; // 0xc0
    bytes32 zoneHash; // 0xe0
    uint256 salt; // 0x100
    bytes32 conduitKey; // 0x120
    uint256 totalOriginalConsiderationItems; // 0x140
    // offer.length                          // 0x160
}

/**
 * @dev Orders require a signature in addition to the other order parameters.
 */
struct Order {
    OrderParameters parameters;
    bytes signature;
}

/**
 * @dev Advanced orders include a numerator (i.e. a fraction to attempt to fill)
 *      and a denominator (the total size of the order) in addition to the
 *      signature and other order parameters. It also supports an optional field
 *      for supplying extra data; this data will be included in a staticcall to
 *      `isValidOrderIncludingExtraData` on the zone for the order if the order
 *      type is restricted and the offerer or zone are not the caller.
 */
struct AdvancedOrder {
    OrderParameters parameters;
    uint120 numerator;
    uint120 denominator;
    bytes signature;
    bytes extraData;
}

/**
 * @dev Orders can be validated (either explicitly via `validate`, or as a
 *      consequence of a full or partial fill), specifically cancelled (they can
 *      also be cancelled in bulk via incrementing a per-zone counter), and
 *      partially or fully filled (with the fraction filled represented by a
 *      numerator and denominator).
 */
struct OrderStatus {
    bool isValidated;
    bool isCancelled;
    uint120 numerator;
    uint120 denominator;
}

/**
 * @dev A criteria resolver specifies an order, side (offer vs. consideration),
 *      and item index. It then provides a chosen identifier (i.e. tokenId)
 *      alongside a merkle proof demonstrating the identifier meets the required
 *      criteria.
 */
struct CriteriaResolver {
    uint256 orderIndex;
    Side side;
    uint256 index;
    uint256 identifier;
    bytes32[] criteriaProof;
}

/**
 * @dev A fulfillment is applied to a group of orders. It decrements a series of
 *      offer and consideration items, then generates a single execution
 *      element. A given fulfillment can be applied to as many offer and
 *      consideration items as desired, but must contain at least one offer and
 *      at least one consideration that match. The fulfillment must also remain
 *      consistent on all key parameters across all offer items (same offerer,
 *      token, type, tokenId, and conduit preference) as well as across all
 *      consideration items (token, type, tokenId, and recipient).
 */
struct Fulfillment {
    FulfillmentComponent[] offerComponents;
    FulfillmentComponent[] considerationComponents;
}

/**
 * @dev Each fulfillment component contains one index referencing a specific
 *      order and another referencing a specific offer or consideration item.
 */
struct FulfillmentComponent {
    uint256 orderIndex;
    uint256 itemIndex;
}

/**
 * @dev An execution is triggered once all consideration items have been zeroed
 *      out. It sends the item in question from the offerer to the item's
 *      recipient, optionally sourcing approvals from either this contract
 *      directly or from the offerer's chosen conduit if one is specified. An
 *      execution is not provided as an argument, but rather is derived via
 *      orders, criteria resolvers, and fulfillments (where the total number of
 *      executions will be less than or equal to the total number of indicated
 *      fulfillments) and returned as part of `matchOrders`.
 */
struct Execution {
    ReceivedItem item;
    address offerer;
    bytes32 conduitKey;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "../external/interfaces/ILendingPool.sol";
import "./FlashConsumerBase.sol";

import { FC_UnknownCallbackSender, FC_NotInitiator } from "../errors/FlashConsumerErrors.sol";

/**
 * @dev AAVE Flash loan receiver interface, from AAVE docs.
 */
interface IAAVEFlashLoanReceiver {
    function executeOperation(
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata premiums,
        address initiator,
        bytes calldata params
    ) external returns (bool);

    // Function names defined by AAVE
    /* solhint-disable func-name-mixedcase */
    function ADDRESSES_PROVIDER() external view returns (ILendingPoolAddressesProvider);

    function LENDING_POOL() external view returns (ILendingPool);
    /* solhint-enable func-name-mixedcase */
}

/**
 * @title  FlashConsumerBase
 * @author Non-Fungible Technologies, Inc.
 *
 * This contract implements the functions in FlashConsumerBase that directly integrate
 * with AAVE. Note this contract is still abstract since _receiveCallback is not defined.
 */
abstract contract FlashConsumerAAVE is IAAVEFlashLoanReceiver, FlashConsumerBase, ReentrancyGuard {
    /* solhint-disable var-name-mixedcase */
    // AAVE Contracts
    // Variable names are in upper case to fulfill IAAVEFlashLoanReceiver interface
    ILendingPoolAddressesProvider public immutable override ADDRESSES_PROVIDER;
    ILendingPool public immutable override LENDING_POOL;

    /**
     * @notice Deploy a FlashConsumer contract that can reach AAVE.
     *
     * @param _addressesProvider            The global AAVE address provider contract.
     */
    constructor(ILendingPoolAddressesProvider _addressesProvider) {
        ADDRESSES_PROVIDER = _addressesProvider;
        LENDING_POOL = ILendingPool(_addressesProvider.getLendingPool());
    }

    /**
     * @dev Prepare parameters and call AAVE's flashLoan function.
     *
     * @param data                          The asset, amount, and additional params
     *                                      to send to AAVE.
     */
    function _startFlashLoan(bytes memory data) internal override {
        (address asset, uint256 amount, bytes memory params) = abi.decode(data, (address, uint256, bytes));

        address[] memory assets = new address[](1);
        assets[0] = asset; // nft address to buy

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = amount; // total flash loan amount

        uint256[] memory modes = new uint256[](1);
        modes[0] = 0;

        LENDING_POOL.flashLoan(address(this), assets, amounts, modes, address(this), params, 0);
    }

    /**
     * @notice This function is called after this contract has received the flash loan,
     *          per AaveV3 docs.
     *
     * @param assets             Contract address of borrowed asset.
     * @param amounts            Amount borrowed to close the loan.
     * @param premiums           Fee for flashLoan calculated by Aave's PoolConfiguratorContract.
     * @param initiator          The address of the flashloan initiator.
     * @param params             Struct holding whatever data is needed to perform the callback operation.
     *
     * @return bool              Invokes the internal _receiveCallback callback function and returns its
     *                           boolean resolution.
     */
    function executeOperation(
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata premiums,
        address initiator,
        bytes calldata params
    ) external override nonReentrant returns (bool) {
        if (msg.sender != address(LENDING_POOL)) revert FC_UnknownCallbackSender(msg.sender);
        if (initiator != address(this)) revert FC_NotInitiator(initiator);

        bytes memory data = abi.encode(assets[0], amounts[0], premiums[0], params);

        return _receiveCallback(data);
    }

    /**
     * @dev Decode final parameters and approve flash loan repayment.
     *
     * @param data                          The asset and amount to approve for AAVE.
     */
    function _finishCallback(bytes memory data) internal override {
        (address asset, uint256 amount) = abi.decode(data, (address, uint256));

        IERC20(asset).approve(address(LENDING_POOL), amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "../external/interfaces/ILendingPool.sol";
import "./FlashConsumerBase.sol";

import { FC_UnknownCallbackSender, FC_NotInitiator, FC_InvalidEndState } from "../errors/FlashConsumerErrors.sol";

/**
 * @dev Balancer flash loan receiver interface, from Balancer docs.
 */
interface IBalancerFlashLoanRecipient {
    /**
     * @dev When `flashLoan` is called on the Vault, it invokes the `receiveFlashLoan` hook on the recipient.
     *
     * At the time of the call, the Vault will have transferred `amounts` for `tokens` to the recipient. Before this
     * call returns, the recipient must have transferred `amounts` plus `feeAmounts` for each token back to the
     * Vault, or else the entire flash loan will revert.
     *
     * `userData` is the same value passed in the `IVault.flashLoan` call.
     */
    function receiveFlashLoan(
        IERC20[] memory tokens,
        uint256[] memory amounts,
        uint256[] memory feeAmounts,
        bytes memory userData
    ) external;
}

/**
 * @dev Balancer vault contract, the flash liquidity pool.
 */
interface IVault {
    /**
     * @dev copied from @balancer-labs/v2-vault/contracts/interfaces/IVault.sol,
     *      which uses an incompatible compiler version. Only necessary selectors
     *      (flashLoan) included.
     */
    function flashLoan(
        IBalancerFlashLoanRecipient recipient,
        IERC20[] memory tokens,
        uint256[] memory amounts,
        bytes memory userData
    ) external;
}

/**
 * @title  FlashConsumerBase
 * @author Non-Fungible Technologies, Inc.
 *
 * This contract implements the functions in FlashConsumerBase that directly integrate
 * with Balancer. Note this contract is still abstract since _receiveCallback is not defined.
 */
abstract contract FlashConsumerBalancer is IBalancerFlashLoanRecipient, FlashConsumerBase, ReentrancyGuard {
    /* solhint-disable var-name-mixedcase */
    // Balancer Contracts
    IVault public immutable VAULT; // 0xBA12222222228d8Ba445958a75a0704d566BF2C8

    // State variable to make sure in _receiveFlashLoan that this contract is the initiator of the flash loan.
    uint8 private flashLoanActive;

    /**
     * @notice Deploy a FlashConsumer contract that can reach Balancer.
     *
     * @param _vault                        The global Balancer vault contract.
     */
    constructor(IVault _vault) {
        VAULT = _vault;
    }

    /**
     * @dev Prepare parameters and call Balancer's flashLoan function.
     *
     * @param data                          The asset, amount, and additional params
     *                                      to send to Balancer.
     */
    function _startFlashLoan(bytes memory data) internal override {
        (address asset, uint256 amount, bytes memory params) = abi.decode(data, (address, uint256, bytes));

        flashLoanActive = 1;

        IERC20[] memory assets = new IERC20[](1);
        assets[0] = IERC20(asset); // nft address to buy

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = amount; // total flash loan amount

        VAULT.flashLoan(this, assets, amounts, params);

        if (flashLoanActive != 2) revert FC_InvalidEndState();
    }

    /**
     * @notice This function is called after this contract has received the flash loaned funds.
     *
     * @param assets                        Contract address of borrowed asset.
     * @param amounts                       Amount borrowed to close the loan.
     * @param feeAmounts                    Balancer Fee for flash loan.
     * @param params                        Struct holding any passed-along user data.
     *
     */
    function receiveFlashLoan(
        IERC20[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata feeAmounts,
        bytes calldata params
    ) external override nonReentrant {
        if (msg.sender != address(VAULT)) revert FC_UnknownCallbackSender(msg.sender);
        if (flashLoanActive != 1) revert FC_NotInitiator(address(0)); // For balancer, initiator is unknown if not us.

        bytes memory data = abi.encode(assets[0], amounts[0], feeAmounts[0], params);

        _receiveCallback(data);
    }

    /**
     * @dev Decode final parameters and repay Balancer vault.
     *
     * @param data                          The asset and amount to repay.
     */
    function _finishCallback(bytes memory data) internal override {
        (address asset, uint256 amount) = abi.decode(data, (address, uint256));

        flashLoanActive = 2;

        IERC20(asset).transfer(address(VAULT), amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

/**
 * @title  FlashConsumerBase
 * @author Non-Fungible Technologies, Inc.
 *
 * This contract describes a set of functions that should be implemented for any
 * flash consumer mixin (e.g. FlashConsumerAAVE). Each mixin, which can be used
 * by any contract that requires flash liquidity, should implement the below functions,
 * as well as any external-facing integration points for the flash liquidity pool.
 */
abstract contract FlashConsumerBase {
    /**
     * @dev Implementation of _startFlashLoan should include any protocol integration
     *      logic required to get flash liquidity.
     *
     * @param data                          Any data needed by the protocol integration.
     */
    function _startFlashLoan(bytes memory data) internal virtual;

    /**
     * @dev Implementation of _receiveCallback should include all logic to take
     *      place after receiving flash liquidity. FlashConsumerBase child contracts
     *      should take care to call _receiveCallback in whatever function the external
     *      uses to trigger a flash loan contract.
     *
     * @param data                          Any data needed to perform business logic.
     *
     * @return success                      Whether the callback function completed successfully.
     */
    function _receiveCallback(bytes memory data) internal virtual returns (bool);

    /**
     * @dev Implementation of _finishCallback should perform any final interactions
     *      needed to make sure the source of flash liquidity's balance check can pass.
     *      Usually this will entail sending tokens back to the liquidity pool or approving
     *      the liquidity pool to withdraw tokens.
     *
     * @param data                          Any data needed to perform final interactions.
     */
    function _finishCallback(bytes memory data) internal virtual;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "../libraries/LendingPlusLibrary.sol";

interface ICollateralSale {
    // ============== Events ==============

    /**
     * @dev Emitted when the collateral sale is fulfilled.
     */
    event CollateralSale(
        address indexed loanCore,
        address indexed seller,
        address indexed buyer,
        uint256 loanId,
        address token,
        uint256 identifierOrCriteria,
        address paymentToken,
        uint256 paymentTokenAmount
    );

    // ============== Sale Operations ==============

    function fulfillCollateralSale(
        uint256 loanId,
        LendingPlusLibrary.VaultItem[] calldata vaultItems,
        bytes calldata orderRouterData
    ) external;

    function rescueAsset(LendingPlusLibrary.VaultItem memory asset, address vault, address to) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import "@arcadexyz/v2-contracts/contracts/interfaces/IRepaymentController.sol";
import "@arcadexyz/v2-contracts/contracts/interfaces/IAssetVault.sol";
import "@arcadexyz/v2-contracts/contracts/InstallmentsCalc.sol";

import "../../interfaces/ICollateralSale.sol";

import "./Immutables.sol";

import {
    CS_ZeroVaultItems,
    CS_CurrencyMismatch,
    CS_VaultItemsNotFound,
    CS_IncompatibleCollateral,
    CS_NotBorrower,
    CS_UnsupportedVaultItem,
    CS_CannotRepay
} from "../../errors/CollateralSaleErrors.sol";

/**
 * @title  CollateralSale
 * @author Non-Fungible Technologies, Inc.
 *
 * A borrower wants to exit an Active loan on Arcade.xyz. They do not have the
 * funds to repay the loan or do not want to meet their loan obligation.  The
 * CollateralSale contract facilitates the "sale" of the loan collateralized
 * in the Arcade.xyz protocol through an NFT marketplace.
 * The loan is repaid and the asset has a new owner.
 *
 * To repay the loan, CollateralSale executes a flash loan for an amount that
 * covers whatever principal and fees are owed on the loan. Once the loan is repaid,
 * the asset is used to fulfill an existing bid on an NFT marketplace.
 *
 * To fulfill the order, CollateralSale invokes the fulfillOrder() function
 * in Arcade's OrderRouter contract, sending along the underlying calldata for the
 * specified marketplace. Supported marketplaces and order types are specified by
 * the OrderRouter used for integration.
 *
 * Any proceeds from the marketplace sale are used to repay any owed flash liquidity.
 * Any leftover proceeds are sent to the borrower/seller.
 *
 * Note that this contract is abstract: it must be combined with a FlashConsumer mixin,
 * (non-abstract contract such as FlashConsumerAAVE) to make it deployable.
 * See CollateralSaleFinal.sol below for the deployable version.
 */
abstract contract CollateralSale is ICollateralSale, Immutables, InstallmentsCalc {
    using SafeERC20 for IERC20;

    // ========================================== HELPERS ===============================================

    /**
     * @dev Uses the loan ID to pull in the loan terms and verify them against the
     *      CollateralSaleData struct.
     *
     * @param loanId                        The loan to sell colalteral on.
     * @param borrower                      The borrower of the specified loan.
     * @param vaultItems                    The specified items to withdraw from the vault. One item must be sold.
     * @param assetVault                    The vault holding the loan's collateral.
     * @param consideration                 The item to be provided to fulfill the order.
     * @param offer                         The item to be received when fulfiling the order.
     *
     * @return amountToBorrow              Amount needed to borrow from the flash liquidity pool.
     */
    function _verifyLoanData(
        uint256 loanId,
        address borrower,
        LendingPlusLibrary.VaultItem[] calldata vaultItems,
        address assetVault,
        LendingPlusLibrary.VaultItem memory consideration,
        LendingPlusLibrary.VaultItem memory offer
    ) internal returns (uint256 amountToBorrow) {
        if (msg.sender != borrower) revert CS_NotBorrower(msg.sender, borrower);

        // store the loanTerms in memory using getLoan
        LoanLibrary.LoanData memory data = ILoanCore(loanCore).getLoan(loanId);

        // check that the number of vault items listed in csd is greater than zero
        if (vaultItems.length == 0) revert CS_ZeroVaultItems();

        if (data.terms.collateralAddress != vaultFactory) {
            revert CS_IncompatibleCollateral(data.terms.collateralAddress);
        }

        // check the vault is the holder of the asset
        if (consideration.vaultItemType == LendingPlusLibrary.VaultItemType.ERC721) {
            if (IERC721(consideration.tokenAddress).ownerOf(consideration.tokenId) != assetVault) {
                revert CS_VaultItemsNotFound(assetVault);
            }
        } else if (consideration.vaultItemType == LendingPlusLibrary.VaultItemType.ERC1155) {
            if (
                IERC1155(consideration.tokenAddress).balanceOf(assetVault, consideration.tokenId) < consideration.amount
            ) {
                revert CS_VaultItemsNotFound(assetVault);
            }
        } else {
            revert CS_UnsupportedVaultItem(uint256(consideration.vaultItemType));
        }

        // check that basicOrderParams currency matches payableCurrency used in loanTerms
        if (offer.tokenAddress != data.terms.payableCurrency) {
            revert CS_CurrencyMismatch(offer.tokenAddress, data.terms.payableCurrency);
        }

        // get the total amount of funds needed to close the loan
        {
            if (data.terms.numInstallments == 0) {
                // non installment loans
                amountToBorrow = getFullInterestAmount(data.terms.principal, data.terms.interestRate);
            } else {
                // installment loans
                (amountToBorrow, ) = IRepaymentController(repaymentController).amountToCloseLoan(loanId);
            }
        }
    }

    /**
     * @dev Repays an active loan.
     *
     * @param loanId                        The loan to repay.
     * @param borrower                      The borrower of the loan - must approve borrower note to contract.
     * @param asset                         The funding currency of the loan.
     * @param amount                        The amount that will be repaid.
     */
    function _repayLoan(uint256 loanId, address borrower, IERC20 asset, uint256 amount) internal {
        // transfer BorrowerNote ownership to CollateralSale contract. (BN is a "ticket" for the vault.
        // CS holding it will make sure the CS contract get the vault upon repayment).
        IERC721(borrowerNote).safeTransferFrom(borrower, address(this), loanId);

        // check if installments loan or non-installments loan
        LoanLibrary.LoanData memory data = ILoanCore(loanCore).getLoan(loanId);
        LoanLibrary.LoanTerms memory terms = data.terms;

        asset.approve(repaymentController, amount);

        if (terms.numInstallments == 0) {
            //  Non installment loan. Approve repayment controller to retrieve loan payment funds
            // call repaymentController to repay the loan after receiving flash borrowed assets
            IRepaymentController(repaymentController).repay(loanId);
        } else {
            // Installment loan
            IRepaymentController(repaymentController).closeLoan(loanId);
        }
    }

    /**
     * @dev Internal function invoked to return any assets to the seller which are held
     *      in the vault but will not be sold.
     *
     * @param assetVault_               The vault to withdraw items from.
     * @param vaultItems                The items to withdraw.
     * @param borrower                  The borrower of the loan - will receive all items which are not sold.
     * @param considerationToken        The address of the item to be sold.
     * @param considerationIdentifier   The token id of the item to be sold.
     */
    function _withdrawAssets(
        address assetVault_,
        LendingPlusLibrary.VaultItem[] memory vaultItems,
        address borrower,
        address considerationToken,
        uint256 considerationIdentifier
    ) internal {
        IAssetVault assetVault = IAssetVault(assetVault_);
        assetVault.enableWithdraw();

        for (uint256 i = 0; i < vaultItems.length; i++) {
            address recipient = (vaultItems[i].tokenAddress == considerationToken &&
                vaultItems[i].tokenId == considerationIdentifier)
                ? address(this)
                : borrower;

            if (vaultItems[i].vaultItemType == LendingPlusLibrary.VaultItemType.ERC721) {
                // send back ERC721's to the seller
                assetVault.withdrawERC721(vaultItems[i].tokenAddress, vaultItems[i].tokenId, recipient);
            } else if (vaultItems[i].vaultItemType == LendingPlusLibrary.VaultItemType.ERC1155) {
                // send back 1155's to the seller
                assetVault.withdrawERC1155(vaultItems[i].tokenAddress, vaultItems[i].tokenId, recipient);
            } else if (vaultItems[i].vaultItemType == LendingPlusLibrary.VaultItemType.PUNK) {
                // send back cryptopunks to the seller
                assetVault.withdrawPunk(vaultItems[i].tokenAddress, vaultItems[i].tokenId, recipient);
            } else if (vaultItems[i].vaultItemType == LendingPlusLibrary.VaultItemType.ERC20) {
                // send back ERC20's to the seller
                assetVault.withdrawERC20(vaultItems[i].tokenAddress, recipient);
            } else if (vaultItems[i].vaultItemType == LendingPlusLibrary.VaultItemType.ETH) {
                // send back ETH to the seller
                assetVault.withdrawETH(recipient);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "@arcadexyz/v2-contracts/contracts/interfaces/ILoanCore.sol";

struct RouterParameters {
    address loanCore;
    address feeController;
    address originationController;
    address repaymentController;
    address vaultFactory;
}

/// @notice Immutable contract address storage for contracts that will interact
///         with the Arcade.xyz lending protocol.
abstract contract Immutables {
    /// @dev Loan Core address
    address internal immutable loanCore;

    /// @dev Borrower Note address
    address internal immutable borrowerNote;

    /// @dev Lender Note address
    address internal immutable lenderNote;

    /// @dev Fee Controller address
    address internal immutable feeController;

    /// @dev Origination Controller address
    address internal immutable originationController;

    /// @dev Repayment Controller address
    address internal immutable repaymentController;

    /// @dev Vault Factory address
    address internal immutable vaultFactory;

    /**
     * @notice Initializes a contract with immutable references to the lending protocol.
     *
     * @param params                        A mapping of needed contract references.
     */
    constructor(RouterParameters memory params) {
        loanCore = params.loanCore;
        borrowerNote = address(ILoanCore(params.loanCore).borrowerNote());
        lenderNote = address(ILoanCore(params.loanCore).lenderNote());
        feeController = params.feeController;
        originationController = params.originationController;
        repaymentController = params.repaymentController;
        vaultFactory = params.vaultFactory;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "../seaport-basic/CollateralSaleSeaportBasic.sol";
import "../../flash/FlashConsumerAAVE.sol";
import "../../flash/FlashConsumerBalancer.sol";

/**
 * @title CollateralSaleFinal
 * @author Non-Fungible Technologies, Inc.
 *
 * @notice This contract is to be used as the leaf of the inheritance tree for deployment.
 *
 * @dev In the future when additional marketplace protocol routes and flash liquidity options are added,
 *      they will also be added here.
 */

// ================================= IMPLEMENTATION CONTRACTS ===========================================

/**
 * @dev Deployable version of CollateralSaleSeaportBasic using AAVE flash liquidity.
 */
contract CollateralSaleSeaportBasicAAVE is CollateralSaleSeaportBasic, FlashConsumerAAVE {
    // =================== Constructor ===================

    /**
     * @notice Deploys a CollateralSaleSeaportBasic contract that uses AAVE for flash liquidity.
     *
     * @param _params                        The contracts needed for lending integration.
     * @param _seaport                       The deployment address of the Seaport protocol.
     * @param _weth                         The address of the WETH9 contract.
     * @param _addressesProvider             The AAVE addresses provider contract.
     */
    constructor(
        RouterParameters memory _params,
        address _seaport,
        address _weth,
        ILendingPoolAddressesProvider _addressesProvider
    ) FlashConsumerAAVE(_addressesProvider) Immutables(_params) SeaportBasicRoute(_seaport, _weth) {}
}

/**
 * @dev Deployable version of CollateralSaleSeaportBasic using Balancer flash liquidity.
 */
contract CollateralSaleSeaportBasicBalancer is CollateralSaleSeaportBasic, FlashConsumerBalancer {
    // =================== Constructor ===================

    /**
     * @notice Deploys a CollateralSaleSeaportBasic contract that uses Balancer for flash liquidity.
     *
     * @param _params                        The contracts needed for lending integration.
     * @param _seaport                       The deployment address of the Seaport protocol.
     * @param _weth                         The address of the WETH9 contract.
     * @param _vault                         The Balancer Vault contract.
     */
    constructor(
        RouterParameters memory _params,
        address _seaport,
        address _weth,
        IVault _vault
    ) FlashConsumerBalancer(_vault) Immutables(_params) SeaportBasicRoute(_seaport, _weth) {}
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import "../../libraries/LendingPlusLibrary.sol";
import "../../external/interfaces/IWETH.sol";

import { OR_CallFailed, OR_UnsupportedSeaport, OR_NoReceive } from "../../errors/OrderRouterErrors.sol";

/**
 * @title SeaportBasicRoute
 * @author Non-Fungible Technologies, Inc.
 *
 * @notice Internal marketplace route used by PayLater and CollateralSale
 *         contracts for Seaport basic order fulfillment.
 */
abstract contract SeaportBasicRoute {
    /// @dev Seaport address
    address internal immutable seaport;

    /// @dev WETH9 address
    /// @dev 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2 on mainnet
    address internal immutable weth;

    /**
     * @notice Initializes the contract with a reference to the Seaport protocol.
     *
     * @param _seaport                      The address of the Seaport protocol.
     * @param _weth                         The address of the WETH9 contract.
     *
     * @dev WETH9 is at
     */
    constructor(address _seaport, address _weth) {
        seaport = _seaport;
        weth = _weth;
    }

    /**
     * @notice Internal function for making the external calls to the Seaport V2 protocol.
     *         Bytes validation to occur internally by the protocol being called. Seaport
     *         BasicOrderParameters is the only supported order type with "FULL_OPEN" being
     *         the only basicOrderType accepted.
     *
     * @dev Since the order type is known, the internal routing must be performed for the
     *      various asset types decoded from the parameters.
     *
     * @param basicOrderParams              Order params of the order being fulfilled.
     */
    function callSeaportV2Basic(BasicOrderParameters memory basicOrderParams) internal {
        // determine total amount paid to the additional recipients
        uint256 recipientsTotal = getAdditionalRecipientsTotal(basicOrderParams);

        bytes4 _method = 0xfb0f3ee1; // fulfillBasicOrder
        bytes memory encodedData = abi.encodePacked(_method, abi.encode(basicOrderParams));

        _doApproval(basicOrderParams, recipientsTotal);

        // Call marketplace contract - send value if sending ETH
        uint256 value;

        if (uint(basicOrderParams.basicOrderType) < 8) {
            value = basicOrderParams.considerationAmount + recipientsTotal;
            IWETH(weth).withdraw(value); // Withdraw WETH that was borrowed from flash loan
        }

        (bool success, bytes memory returnData) = seaport.call{ value: value }(encodedData);

        _checkSuccess(basicOrderParams, success, returnData, recipientsTotal);
    }

    /**
     * @notice Internal function for calculating the total amount of tokens in a Seaport order
     *         that were posted by the offerer but will not be received by the fulfiller (e.g. royalties).
     *         For basic orders, this is stored in the additionalRecipients field.
     *
     * @param basicOrderParams              Order params of the order being fulfilled.
     */
    function getAdditionalRecipientsTotal(
        BasicOrderParameters memory basicOrderParams
    ) internal pure returns (uint256 total) {
        // determine total amount paid to the additional recipients
        for (uint256 i = 0; i < basicOrderParams.additionalRecipients.length; i++) {
            total += basicOrderParams.additionalRecipients[i].amount;
        }
    }

    /**
     * @dev Approve the asset that will be sent to Seaport, based on the order parameters.
     *
     * @param basicOrderParams              Order params of the order being fulfilled.
     * @param recipientsTotal               The amount of tokens that will be received by parties other than the buyer.
     */
    function _doApproval(BasicOrderParameters memory basicOrderParams, uint256 recipientsTotal) internal {
        uint oType = uint(basicOrderParams.basicOrderType) / 4;

        // If oType < 2, we are sending ETH, so no approval needed
        if (oType < 2) return;

        if (oType < 4) {
            // Sending ERC20
            IERC20(basicOrderParams.considerationToken).approve(
                seaport,
                basicOrderParams.considerationAmount + recipientsTotal
            );
        } else if (oType < 5) {
            // Sending ERC721
            IERC721(basicOrderParams.considerationToken).approve(seaport, basicOrderParams.considerationIdentifier);
        } else if (oType < 6) {
            // Sending ERC1155
            IERC1155(basicOrderParams.considerationToken).setApprovalForAll(seaport, true);
        } else {
            revert OR_UnsupportedSeaport(basicOrderParams.basicOrderType);
        }
    }

    /**
     * @dev Check whether the call to Seaport was a success, by checking function call returndata
     *      along with received token balances.
     *
     * @param basicOrderParams              Order params of the order that was fulfilled.
     * @param success                       Whether the marketplace call succeeded.
     * @param returnData                    The byte-encoded data returned by the external function call.
     * @param recipientsTotal               The amount of tokens that will be received by parties other than the buyer.
     */
    function _checkSuccess(
        BasicOrderParameters memory basicOrderParams,
        bool success,
        bytes memory returnData,
        uint256 recipientsTotal
    ) internal view {
        if (!success) revert OR_CallFailed(returnData);

        uint oType = uint(basicOrderParams.basicOrderType) / 4;

        if (oType == 0 || oType == 2) {
            // Receiving ERC721 - check ownership
            if (IERC721(basicOrderParams.offerToken).ownerOf(basicOrderParams.offerIdentifier) != address(this)) {
                revert OR_CallFailed(returnData);
            }
        } else if (oType == 1 || oType == 3) {
            // Receiving ERC1155
            if (
                IERC1155(basicOrderParams.offerToken).balanceOf(address(this), basicOrderParams.offerIdentifier) !=
                basicOrderParams.offerAmount
            ) {
                revert OR_CallFailed(returnData);
            }
        } else if (oType >= 4) {
            // Receiving ERC20
            if (
                IERC20(basicOrderParams.offerToken).balanceOf(address(this)) !=
                (basicOrderParams.offerAmount - recipientsTotal)
            ) {
                revert OR_CallFailed(returnData);
            }
        }
    }

    /**
     * @dev The only way this contract should receive ETH is from unwrapping WETH for PayLater operations
     *      where the listing is in ETH. Seaport should never send this contract ETH, since it only
     *      fulfills orders and all token bids must be WETH-based.
     */
    receive() external payable {
        if (msg.sender != weth) revert OR_NoReceive();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "@arcadexyz/v2-contracts/contracts/interfaces/ILoanCore.sol";
import "@arcadexyz/v2-contracts/contracts/interfaces/IAssetVault.sol";
import "@arcadexyz/v2-contracts/contracts/interfaces/IVaultFactory.sol";

import "../../flash/FlashConsumerBase.sol";

import "../base/CollateralSale.sol";
import "../order-routing/SeaportBasicRoute.sol";

import { CS_ZeroVaultItems, CS_CurrencyMismatch } from "../../errors/CollateralSaleErrors.sol";

/**
 * @title  CollateralSaleSeaportBasic
 * @author Non-Fungible Technologies, Inc.
 *
 * A borrower wants to exit an Active loan on Arcade.xyz. They do not have the
 * funds to repay the loan or do not want to meet their loan obligation.  The
 * CollateralSale contract facilitates the "sale" of the loan collateralized
 * in the Arcade.xyz protocol through an NFT marketplace.
 * The loan is repaid and the asset has a new owner.
 *
 * To repay the loan, CollateralSale executes a flash loan for an amount that
 * covers whatever principal and fees are owed on the loan. Once the loan is repaid,
 * the asset is used to fulfill an existing bid on an NFT marketplace.
 *
 * To fulfill the order, CollateralSale calls callSeaportV2Basic route, sending along
 * the underlying calldata for fulfillment on thespecified marketplace.
 *
 * Any proceeds from the marketplace sale are used to repay any owed flash liquidity.
 * are sent to the borrower/seller.
 *
 * Note that this contract is abstract: it must be combined with a FlashConsumer mixin,
 * (non-abstract contract such as FlashConsumerAAVE) to make it deployable.
 *
 * Allowed basic order types:
 * 16: ERC721_TO_ERC20_FULL_OPEN
 * 20: ERC1155_TO_ERC20_FULL_OPEN
 *
 */
abstract contract CollateralSaleSeaportBasic is
    CollateralSale,
    SeaportBasicRoute,
    FlashConsumerBase,
    Ownable,
    ERC721Holder,
    ERC1155Holder
{
    using SafeERC20 for IERC20;

    // =================================== CORE FUNCTIONALITY ======================================

    /**
     * @notice Execute collateral sale by calling the flashloan function.
     *         Function fulfillCollateralSale invokes verifyLoanData callback.
     *
     * @param loanId                    The ID of the loan to close.
     * @param vaultItems                The items to withdraw from the vault.
     * @param orderRouterData           Data for OrderRouter call (should be route-specific).
     */
    function fulfillCollateralSale(
        uint256 loanId,
        LendingPlusLibrary.VaultItem[] calldata vaultItems,
        bytes calldata orderRouterData
    ) external override {
        // Pull asset vault based on loan id
        LoanLibrary.LoanTerms memory terms = ILoanCore(loanCore).getLoan(loanId).terms;
        address assetVault = IVaultFactory(vaultFactory).instanceAt(terms.collateralId);
        address borrower = IERC721(borrowerNote).ownerOf(loanId);

        BasicOrderParameters memory basicOrderParams = abi.decode(orderRouterData, (BasicOrderParameters));

        // Revert if unsupported order type
        if (uint(basicOrderParams.basicOrderType) != 16 && uint(basicOrderParams.basicOrderType) != 20) {
            revert OR_UnsupportedSeaport(basicOrderParams.basicOrderType);
        }

        LendingPlusLibrary.VaultItemType considerationType = uint(basicOrderParams.basicOrderType) == 16
            ? LendingPlusLibrary.VaultItemType.ERC721
            : LendingPlusLibrary.VaultItemType.ERC1155;

        uint256 amountToBorrow = _verifyLoanData(
            loanId,
            borrower,
            vaultItems,
            assetVault,
            LendingPlusLibrary.VaultItem(
                considerationType,
                basicOrderParams.considerationAmount,
                basicOrderParams.considerationToken,
                basicOrderParams.considerationIdentifier
            ),
            LendingPlusLibrary.VaultItem(
                LendingPlusLibrary.VaultItemType.ERC20,
                basicOrderParams.offerAmount,
                basicOrderParams.offerToken,
                0
            )
        );

        bytes memory params = abi.encode(
            LendingPlusLibrary.CollateralSaleOperationData({
                loanId: loanId,
                assetVault: assetVault,
                vaultItems: vaultItems,
                orderRouterData: orderRouterData,
                borrower: borrower
            })
        );

        bytes memory data = abi.encode(basicOrderParams.offerToken, amountToBorrow, params);

        _startFlashLoan(data);
    }

    /**
     * @notice Repays the loan, then unbundles the collateral that is required to fulfill the marketplace
     *         order. Next, the order is fulfilled via Seaport basic order extecution. Any profit is sent
     *         to the seller, outside of what is owed to the lendingPool.
     *
     * @param data                    The callback data sent by the flash liquidity pool.
     *
     * @return bool                   If the callback is successful, returns true.
     */
    function _receiveCallback(bytes memory data) internal override returns (bool) {
        (IERC20 asset, uint256 amount, uint256 premium, bytes memory params) = abi.decode(
            data,
            (IERC20, uint256, uint256, bytes)
        );

        LendingPlusLibrary.CollateralSaleOperationData memory opData = abi.decode(
            params,
            (LendingPlusLibrary.CollateralSaleOperationData)
        );

        BasicOrderParameters memory basicOrderParams = abi.decode(opData.orderRouterData, (BasicOrderParameters));

        _repayLoan(opData.loanId, opData.borrower, asset, amount);
        _withdrawAssets(
            opData.assetVault,
            opData.vaultItems,
            opData.borrower,
            basicOrderParams.considerationToken,
            basicOrderParams.considerationIdentifier
        );

        callSeaportV2Basic(basicOrderParams);

        uint256 additionalRecipientsTotal = getAdditionalRecipientsTotal(basicOrderParams);
        uint256 offerTotal = basicOrderParams.offerAmount - additionalRecipientsTotal;
        uint256 amountOwed = amount + premium;

        // send any profit to seller - outside of what is owed to the lendingPool
        if (offerTotal > amountOwed) {
            asset.transfer(opData.borrower, offerTotal - amountOwed);
        } else if (offerTotal < amountOwed) {
            // Seller would have to provide extra funds to repay the loan - revert
            revert CS_CannotRepay(offerTotal, amountOwed);
        }

        // approve total for flash loan repayment
        _finishCallback(abi.encode(asset, amount + premium));

        // invoke event function
        emit CollateralSale(
            address(loanCore),
            opData.borrower,
            basicOrderParams.offerer,
            opData.loanId,
            basicOrderParams.considerationToken,
            basicOrderParams.considerationIdentifier,
            basicOrderParams.offerToken,
            basicOrderParams.offerAmount
        );

        return true;
    }

    // ========================================== RESCUE ================================================

    /**
     * @notice External function called by the contract owner to return to the seller any
     *         assets in the vault that were not included in the vaultItems array calldata.
     *
     * @param asset                 Data struct for token to be sent back to seller.
     * @param vaultAddress          The vault that holds the specified items.
     * @param to                    Address to send token to.
     */
    function rescueAsset(
        LendingPlusLibrary.VaultItem memory asset,
        address vaultAddress,
        address to
    ) external onlyOwner {
        IAssetVault assetVault = IAssetVault(vaultAddress);

        if (asset.vaultItemType == LendingPlusLibrary.VaultItemType.ERC721) {
            // send back ERC721 to the seller
            assetVault.withdrawERC721(asset.tokenAddress, asset.tokenId, to);
        } else if (asset.vaultItemType == LendingPlusLibrary.VaultItemType.ERC1155) {
            // send back 1155's to the seller
            assetVault.withdrawERC1155(asset.tokenAddress, asset.tokenId, to);
        } else if (asset.vaultItemType == LendingPlusLibrary.VaultItemType.PUNK) {
            // send back cryptopunks to the seller
            assetVault.withdrawPunk(asset.tokenAddress, asset.tokenId, to);
        } else if (asset.vaultItemType == LendingPlusLibrary.VaultItemType.ERC20) {
            // send back ERC20's to the seller
            assetVault.withdrawERC20(asset.tokenAddress, to);
        } else if (asset.vaultItemType == LendingPlusLibrary.VaultItemType.ETH) {
            // send back ETH to the seller
            assetVault.withdrawETH(to);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import { BasicOrderParameters, OfferItem, AdditionalRecipient } from "../external/seaport/lib/ConsiderationStructs.sol";

import { ItemType, BasicOrderType } from "../external/seaport/lib/ConsiderationEnums.sol";

import "@arcadexyz/v2-contracts/contracts/interfaces/ILoanCore.sol";

/**
 * @title LendingPlusLibrary
 * @author Non-Fungible Technologies, Inc.
 *
 * Contains all data types used across Arcade Lending Plus contracts.
 */
library LendingPlusLibrary {
    // ======================== Vault Operations ========================

    /**
     * @dev The type of asset held by the vault.
     */
    enum VaultItemType {
        ERC20,
        ERC721,
        ERC1155,
        ETH,
        PUNK
    }

    /**
     * @dev An item held by the vault.
     */
    struct VaultItem {
        /// @dev The type of asset (ERC20, ERC721, etc.)
        VaultItemType vaultItemType;
        /// @dev The amount of asset. Ignored for ERC721.
        uint256 amount;
        /// @dev The contract address of the asset.
        address tokenAddress;
        /// @dev The token ID of the asset. Ignored for ERC20.
        uint256 tokenId;
    }

    // ======================== CollateralSale ========================

    /**
     * @dev The parameters passed through the flash loan contract when using FlashConsumerBase for CollateralSale.
     */
    struct CollateralSaleOperationData {
        /// @dev The ID of the loan.
        uint256 loanId;
        /// @dev The address of the collateral vault for the loan.
        address assetVault;
        /// @dev The items in the vault.
        VaultItem[] vaultItems;
        /// @dev The payload used for order fulfillment.
        bytes orderRouterData;
        /// @dev The address of the borrower.
        address borrower;
    }

    // ======================== Pay Later ========================

    /**
     * @dev The parameters passed through the flash loan contract when using FlashConsumerBase for PayLater.
     */
    struct PayLaterOperationData {
        /// @dev The maximum down payment the buyer is willing to provide.
        uint256 maxDownPayment;
        /// @dev The terms of the loan that will be initiated.
        LoanLibrary.LoanTerms loanTerms;
        /// @dev The loan's borrower/the buyer of the asset.
        address borrower;
        /// @dev The lender for the loan.
        address lender;
        /// @dev The nonce of the loan terms signature.
        uint160 nonce;
        /// @dev The predicates used to verify asset ownership for the loan.
        LoanLibrary.Predicate[] predicates;
        /// @dev A component of the lending signature.
        uint8 v;
        /// @dev A component of the lending signature.
        bytes32 r;
        /// @dev A component of the lending signature.
        bytes32 s;
        /// @dev The data needed to fulfill a marketplace purchase.
        bytes orderRouterData;
    }

    /**
     * @dev Struct containing the terms of a loan and the predicates for collateral for PayLater.
     */
    struct LoanTermsData {
        /// @dev The terms of the loan that will be initiated.
        LoanLibrary.LoanTerms loanTerms;
        /// @dev The predicates used to verify asset ownership for the loan.
        LoanLibrary.Predicate[] predicates;
    }
}