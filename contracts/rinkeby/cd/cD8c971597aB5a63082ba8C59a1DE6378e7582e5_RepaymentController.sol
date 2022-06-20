// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

/** V2 Notes
 * Interest input as a rate/ percent value.
 *
 * _calcAmountsDue - function which returns the current balanceDue(uint256),
 * defaulted(bool), and payableCurrency(address)
 *
 * repayPartMinimum - function for repaying installment payments. The minimum amount payable.
 * Interest and any fees only.
 *
 * repayPart - function for repaying installment payments. The amount must be higher than
 * the minimum amount payable.
 */

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./InstallmentsCalc.sol";
import "./libraries/LoanLibrary.sol";
import "./interfaces/IPromissoryNote.sol";
import "./interfaces/ILoanCore.sol";
import "./interfaces/IRepaymentController.sol";

import { RC_CannotDereference, RC_InvalidState, RC_NoPaymentDue, RC_OnlyLender, RC_BeforeStartDate, RC_NoInstallments, RC_NoMinPaymentDue, RC_RepayPartZero, RC_RepayPartLTMin, RC_HasInstallments } from "./errors/Lending.sol";

/**
 * @title RepaymentController
 * @author Non-Fungible Technologies, Inc.
 *
 * The Repayment Controller is the entry point for all loan lifecycle
 * operations in the Arcade.xyz lending protocol once a loan has begun.
 * This contract allows a caller to calculate an amount due on a loan,
 * make a payment (either in full or part, for installment loans), and
 * claim collateral on a defaulted loan. It is this contract's responsibility
 * to verify loan conditions before calling LoanCore.
 */
contract RepaymentController is IRepaymentController, InstallmentsCalc, Context {
    using SafeERC20 for IERC20;

    // ============================================ STATE ===============================================

    ILoanCore private loanCore;
    IPromissoryNote private lenderNote;

    constructor(
        ILoanCore _loanCore
    ) {
        loanCore = _loanCore;
        lenderNote = loanCore.lenderNote();
    }

    // ==================================== LIFECYCLE OPERATIONS ========================================

    /**
     * @notice Repay an active loan, referenced by borrower note ID (equivalent to loan ID). The interest for a loan
     *         is calculated, and the principal plus interest is withdrawn from the borrower.
     *         Control is passed to LoanCore to complete repayment.
     *
     * @param  loanId               The ID of the loan.
     */
    function repay(uint256 loanId) external override {
        LoanLibrary.LoanData memory data = loanCore.getLoan(loanId);
        if (data.state == LoanLibrary.LoanState.DUMMY_DO_NOT_USE) revert RC_CannotDereference(loanId);
        if (data.state != LoanLibrary.LoanState.Active) revert RC_InvalidState(data.state);

        LoanLibrary.LoanTerms memory terms = data.terms;

        //cannot use for installment loans, call repayPart or repayPartMinimum
        if (terms.numInstallments != 0) revert RC_HasInstallments(terms.numInstallments);

        // withdraw principal plus interest from borrower and send to loan core
        uint256 total = getFullInterestAmount(terms.principal, terms.interestRate);
        if (total == 0) revert RC_NoPaymentDue();

        IERC20(terms.payableCurrency).safeTransferFrom(_msgSender(), address(this), total);
        IERC20(terms.payableCurrency).approve(address(loanCore), total);

        // call repay function in loan core
        loanCore.repay(loanId);
    }

    /**
     * @notice Claim collateral an active loan, referenced by lender note ID (equivalent to loan ID). The loan
     *         must be passed the due date, or, in the case of an installment, the amount
     *         overdue must be beyond the liquidation threshold. No funds are collected
     *         from the borrower.
     *
     * @param  loanId               The ID of the loan.
     */
    function claim(uint256 loanId) external override {
        // make sure that caller owns lender note
        // Implicitly checks if loan is active - if inactive, note will not exist
        address lender = lenderNote.ownerOf(loanId);
        if (lender != msg.sender) revert RC_OnlyLender(msg.sender);
        // get LoanData for determining how to send the current installment parameter to LoanCore
        LoanLibrary.LoanData memory data = loanCore.getLoan(loanId);
        if (data.terms.numInstallments > 0) {
            // get the current installment period
            uint256 _installmentPeriod = currentInstallmentPeriod(
                data.startDate,
                data.terms.durationSecs,
                data.terms.numInstallments
            );
            // call claim function in loan core
            loanCore.claim(loanId, _installmentPeriod);
        } else {
            // call claim function in loan core indicating a legacy loan type with 0 as the installment period
            // installment loans cannot have an installment period of 0
            loanCore.claim(loanId, 0);
        }
    }

    // =========================== INSTALLMENT SPECIFIC OPERATIONS ===============================

    /**
     * @notice Call _calcAmountsDue publicly to determine the amount of the payable currency
     *         must be approved for the payment. Returns minimum balance due, late fees, and number
     *         of missed payments.
     *
     * @dev Calls _calcAmountsDue similar to repayPart and repayPartMinimum, but does not call LoanCore.
     *
     * @param loanId                            LoanId, used to locate terms.
     *
     * @return minInterestDue                   The amount of interest due, compounded over missed payments.
     * @return lateFees                         The amount of late fees due, compounded over missed payments.
     * @return _installmentsMissed              The number of overdue installment periods since the last payment.
     */
    function getInstallmentMinPayment(uint256 loanId)
        public
        view
        override
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        // load terms from loanId
        LoanLibrary.LoanData memory data = loanCore.getLoan(loanId);
        // get loan from borrower note
        if (data.state == LoanLibrary.LoanState.DUMMY_DO_NOT_USE) revert RC_CannotDereference(loanId);
        if (data.state != LoanLibrary.LoanState.Active) revert RC_InvalidState(data.state);

        uint256 installments = data.terms.numInstallments;
        if (installments == 0) revert RC_NoInstallments(installments);

        // get the current minimum balance due for the installment
        (uint256 minInterestDue, uint256 lateFees, uint256 numMissedPayments) = _calcAmountsDue(
            data.balance,
            data.startDate,
            data.terms.durationSecs,
            installments,
            data.numInstallmentsPaid,
            data.terms.interestRate
        );

        return (minInterestDue, lateFees, numMissedPayments);
    }

    /**
     * @notice Called when paying back installment loan with the minimum amount due.
     *         Do not call for single payment loan types. Calling this function does not
     *         reduce the loans principal.
     *
     * @dev Only pay off the current interest amount and, if applicable, any late fees accrued.
     *
     * @param loanId                            LoanId, used to locate terms.
     */
    function repayPartMinimum(uint256 loanId) external override {
        // get current minimum balance due for the installment repayment, based on specific loanId.
        (uint256 minBalanceDue, uint256 lateFees, uint256 numMissedPayments) = getInstallmentMinPayment(loanId);
        // total amount due, interest amount plus any late fees
        uint256 _minAmount = minBalanceDue + lateFees;
        // cannot call repayPartMinimum twice in the same installment period
        if (_minAmount == 0) revert RC_NoPaymentDue();

        // load terms from loanId
        LoanLibrary.LoanData memory data = loanCore.getLoan(loanId);
        // gather minimum payment from _msgSender()
        IERC20(data.terms.payableCurrency).safeTransferFrom(_msgSender(), address(this), _minAmount);
        // approve loanCore to take minBalanceDue
        IERC20(data.terms.payableCurrency).approve(address(loanCore), _minAmount);
        // call repayPart function in loanCore
        loanCore.repayPart(loanId, numMissedPayments, 0, minBalanceDue, lateFees);
    }

    /**
     * @notice Called when paying back installment loan with an amount greater than the minimum amount due.
     *         Do not call for single payment loan types. If one wishes to repay the minimum, use
     *         repayPartMinimum.
     *
     * @dev Pay off the current interest and, if applicable any late fees accrued, and an additional
     *      amount to be deducted from the loan principal.
     *
     * @param loanId                            LoanId, used to locate terms.
     * @param amount                            Amount = minBalDue + lateFees + amountToPayOffPrincipal
     *                                          value must be greater than minBalDue + latefees returned
     *                                          from getInstallmentMinPayment function call.
     */
    function repayPart(uint256 loanId, uint256 amount) external override {
        if (amount == 0) revert RC_RepayPartZero();

        // get current minimum balance due for the installment repayment, based on specific loanId.
        (uint256 minBalanceDue, uint256 lateFees, uint256 numMissedPayments) = getInstallmentMinPayment(loanId);
        // total minimum amount due, interest amount plus any late fees
        uint256 _minAmount = minBalanceDue + lateFees;
        // require amount taken from the _msgSender() to be larger than or equal to minBalanceDue
        if (amount < _minAmount) revert RC_RepayPartLTMin(amount, _minAmount);
        // load data from loanId
        LoanLibrary.LoanData memory data = loanCore.getLoan(loanId);
        // calculate the payment to principal after subtracting (minBalanceDue + lateFees)
        uint256 _totalPaymentToPrincipal = amount - (_minAmount);
        // gather amount specified in function call params from _msgSender()
        IERC20(data.terms.payableCurrency).safeTransferFrom(_msgSender(), address(this), amount);
        // approve loanCore to take amount
        IERC20(data.terms.payableCurrency).approve(address(loanCore), amount);
        // call repayPart function in loanCore
        loanCore.repayPart(loanId, numMissedPayments, _totalPaymentToPrincipal, minBalanceDue, lateFees);
    }

    /**
     * @notice Called when the user wants to close an installment loan without neededing to deteremine the
     *         amount to pass to the repayPart function. This is done by paying the remaining principal
     *         and any interest or late fees due.
     *
     * @dev Pay off the current interest and, if applicable any late fees accrued, and the remaining principal
     *      left on the loan.
     *
     * @param loanId                            LoanId, used to locate terms.
     */
    function closeLoan(uint256 loanId) external override {
        // get current minimum balance due for the installment repayment, based on specific loanId.
        (uint256 minBalanceDue, uint256 lateFees, uint256 numMissedPayments) = getInstallmentMinPayment(loanId);
        // load data from loanId
        LoanLibrary.LoanData memory data = loanCore.getLoan(loanId);
        // total amount to close loan (remaining balance + current interest + late fees)
        uint256 _totalAmount = data.balance + minBalanceDue + lateFees;
        // gather amount specified in function call params from _msgSender()
        IERC20(data.terms.payableCurrency).safeTransferFrom(_msgSender(), address(this), _totalAmount);
        // approve loanCore to take minBalanceDue
        IERC20(data.terms.payableCurrency).approve(address(loanCore), _totalAmount);
        // Call repayPart function in loanCore.
        loanCore.repayPart(loanId, numMissedPayments, data.balance, minBalanceDue, lateFees);
    }

    // ========================================= VIEW FUNCTIONS =========================================

    /**
     * @notice Called when the user wants to close an installment loan without needing to determine the
     *         amount to pass to the repayPart function. This is done by paying the remaining principal
     *         and any interest or late fees due.
     *
     * @dev Pay off the current interest and, if applicable any late fees accrued, in addition to any
     *      remaining principal left on the loan.
     *
     * @param loanId                            LoanId, used to locate terms.
     *
     * @return amountDue                        The total amount due to close the loan, including principal, interest,
     *                                          and late fees.
     * @return numMissedPayments                The number of overdue installment periods since the last payment.
     */
    function amountToCloseLoan(uint256 loanId) external view override returns (uint256, uint256) {
        // get current minimum balance due for the installment repayment, based on specific loanId.
        (uint256 minBalanceDue, uint256 lateFees, uint256 numMissedPayments) = getInstallmentMinPayment(loanId);
        // load data from loanId
        LoanLibrary.LoanData memory data = loanCore.getLoan(loanId);

        // the required total amount needed to close the loan (remaining balance + current interest + late fees)
        return ((data.balance + minBalanceDue + lateFees), numMissedPayments);
    }
}

// SPDX-License-Identifier: MIT

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
     *         durationSecs, and numInstallments. Using these three paremeters and the blocks current timestamp
     *         we are able to determine the current timeframe relative to the total number of installments.
     *
     * @dev Get current installment using the startDate, duration, and current time.
     *      NOTE!!! DurationSecs must be greater than 10 seconds (10%10 = 0).
     *              Also verify the _timestampMultiplier value for what is determined on the max and min loan durations.
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
     * @notice Calulates and returns the minimum interest balance on loan, current late fees,
     *         and the current number of payments missed. If called twice in the same installment
     *         period, will return all zeros the second call.
     *
     * @dev Get minimum installment payment due, any late fees accrued, and
     *      the number of missed payments since last installment payment.
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
            // have alread been repaid. Any additional amount sent in this installment period goes to principal
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

pragma solidity ^0.8.11;

interface IInstallmentsCalc {
    // ================ View Functions ================

    function getFullInterestAmount(uint256 principal, uint256 interestRate) external returns (uint256);
}

// SPDX-License-Identifier: MIT

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
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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