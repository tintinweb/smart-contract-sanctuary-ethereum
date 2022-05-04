// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.12;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./Lender.sol";

/**
 * @title BankFair Pool
 * @notice Provides deposit, withdrawal, and staking functionality. 
 * @dev Extends Lender. 
 *      Extends ManagedLendingPool by inheritance.
 */
contract BankFair is Lender {

    using SafeMath for uint256;
    
    /**
     * @notice Creates a BankFair pool.
     * @param tokenAddress ERC20 token contract address to be used as main pool liquid currency.
     * @param protocol Address of a wallet to accumulate protocol earnings.
     * @param minLoanAmount Minimum amount to be borrowed per loan.
     */
    constructor(address tokenAddress, address protocol, uint256 minLoanAmount) Lender(tokenAddress, protocol, minLoanAmount) {
        
    }

    /**
     * @notice Deposit tokens to the pool.
     * @dev Deposit amount must be non zero and not exceed amountDepositable().
     *      An appropriate spend limit must be present at the token contract.
     *      Caller must not be any of: manager, protocol, current borrower.
     * @param amount Token amount to deposit.
     */
    function deposit(uint256 amount) external onlyLender {
        enterPool(amount);
    }

    /**
     * @notice Withdraw tokens from the pool.
     * @dev Withdrawal amount must be non zero and not exceed amountWithdrawable().
     *      Caller must not be any of: manager, protocol, current borrower.
     * @param amount token amount to withdraw.
     */
    function withdraw(uint256 amount) external onlyLender {
        exitPool(amount);
    }

    /**
     * @notice Check wallet's token balance in the pool. Balance includes acquired earnings. 
     * @param wallet Address of the wallet to check the balance of.
     * @return Token balance of the wallet in this pool.
     */
    function balanceOf(address wallet) public view returns (uint256) {
        return sharesToTokens(poolShares[wallet]);
    }

    /**
     * @notice Check token amount depositable by lenders at this time.
     * @dev Return value depends on the pool state rather than caller's balance.
     * @return Max amount of tokens depositable to the pool.
     */
    function amountDepositable() external view returns (uint256) {
        if (poolFundsLimit <= poolFunds) {
            return 0;
        }

        return poolFundsLimit.sub(poolFunds);
    }

    /**
     * @notice Check token amount withdrawable by the caller at this time.
     * @dev Return value depends on the callers balance, and is limited by pool liquidity.
     * @param wallet Address of the wallet to check the withdrawable balance of.
     * @return Max amount of tokens withdrawable by msg.sender.
     */
    function amountWithdrawable(address wallet) external view returns (uint256) {
        return Math.min(poolLiquidity, balanceOf(wallet));
    }

    /**
     * @notice Withdraw funds of an approved loan.
     * @dev Caller must be the borrower. 
     *      The loan must be in APPROVED status.
     * @param loanId id of the loan to withdraw funds of. 
     */
    function borrow(uint256 loanId) external loanInStatus(loanId, LoanStatus.APPROVED) {
        Loan storage loan = loans[loanId];
        require(loan.borrower == msg.sender, "BankFair: Withdrawal requester is not the borrower on this loan.");

        loan.status = LoanStatus.FUNDS_WITHDRAWN;
        decreaseLoanFunds(msg.sender, loan.amount);

        tokenBalance = tokenBalance.sub(loan.amount);
        bool success = IERC20(token).transfer(msg.sender, loan.amount);
        if(!success) {
            revert();
        }
    }

    /**
     * @notice Stake tokens into the pool.
     * @dev Caller must be the manager.
     *      Stake amount must be non zero.
     *      An appropriate spend limit must be present at the token contract.
     * @param amount Token amount to stake.
     */
    function stake(uint256 amount) external onlyManager {
        require(amount > 0, "BankFair: stake amount is 0");

        uint256 shares = enterPool(amount);
        stakedShares = stakedShares.add(shares);
        updatePoolLimit();
    }
    
    /**
     * @notice Unstake tokens from the pool.
     * @dev Caller must be the manager.
     *      Unstake amount must be non zero and not exceed amountUnstakable().
     * @param amount Token amount to unstake.
     */
    function unstake(uint256 amount) external onlyManager {
        require(amount > 0, "BankFair: unstake amount is 0");
        require(amount <= amountUnstakable(), "BankFair: requested amount is not available to be unstaked");

        uint256 shares = tokensToShares(amount);
        stakedShares = stakedShares.sub(shares);
        updatePoolLimit();
        exitPool(amount);
    }

    /**
     * @notice Check the manager's staked token balance in the pool.
     * @return Token balance of the manager's stake.
     */
    function balanceStaked() public view returns (uint256) {
        return balanceOf(manager);
    }

    /**
     * @notice Check token amount unstakable by the manager at this time.
     * @dev Return value depends on the manager's stake balance, and is limited by pool liquidity.
     * @return Max amount of tokens unstakable by the manager.
     */
    function amountUnstakable() public view returns (uint256) {
        uint256 lenderShares = totalPoolShares.sub(stakedShares);
        uint256 lockedStakeShares = multiplyByFraction(lenderShares, targetStakePercent, ONE_HUNDRED_PERCENT - targetStakePercent);

        return Math.min(poolLiquidity, sharesToTokens(stakedShares.sub(lockedStakeShares)));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

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

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.12;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./ManagedLendingPool.sol";

/**
 * @title BankFair Lender
 * @notice Extends ManagedLendingPool with lending functionality.
 * @dev This contract is abstract. Extend the contract to implement an intended pool functionality.
 */
abstract contract Lender is ManagedLendingPool {

    using SafeMath for uint256;

    enum LoanStatus {
        APPLIED,
        DENIED,
        APPROVED,
        CANCELLED,
        FUNDS_WITHDRAWN,
        REPAID,
        DEFAULTED
    }

    /// Loan application object
    struct Loan {
        uint256 id;
        address borrower;
        uint256 amount;
        uint256 duration; 
        uint16 apr; 
        uint16 lateAPRDelta; 
        uint256 requestedTime;
        LoanStatus status;
    }

    /// Loan payment details object
    struct LoanDetail {
        uint256 loanId;
        uint256 totalAmountRepaid; //total amount paid including interest
        uint256 baseAmountRepaid;
        uint256 interestPaid;
        uint256 approvedTime;
        uint256 lastPaymentTime;
    }

    event LoanRequested(uint256 loanId, address indexed borrower);
    event LoanApproved(uint256 loanId);
    event LoanDenied(uint256 loanId);
    event LoanCancelled(uint256 loanId);
    event LoanRepaid(uint256 loanId);
    event LoanDefaulted(uint256 loanId, uint256 amountLost);

    modifier loanInStatus(uint256 loanId, LoanStatus status) {
        Loan storage loan = loans[loanId];
        require(loan.id != 0, "Loan is not found.");
        require(loan.status == status, "Loan does not have a valid status for this operation.");
        _;
    }

    modifier onlyLender() {
        address wallet = msg.sender;
        require(wallet != address(0), "BankFair: Address is not present.");
        require(wallet != manager && wallet != protocolWallet, "BankFair: Wallet is a manager or protocol.");
        //FIXME: currently borrower is a wallet that has any past or present loans/application,
        //TODO wallet is a borrower if: has open loan or loan application. Implement basic loan history first.
        require(recentLoanIdOf[wallet] == 0, "BankFair: Wallet is a borrower."); 
        _;
    }

    modifier onlyBorrower() {
        address wallet = msg.sender;
        require(wallet != address(0), "BankFair: Address is not present.");
        require(wallet != manager && wallet != protocolWallet, "BankFair: Wallet is a manager or protocol.");
        require(poolShares[wallet] == 0, "BankFair: Applicant is a lender.");
        _;
    }

    // APR, to represent a percentage value as int, multiply by (10 ^ percentDecimals)

    /// Safe minimum for APR values
    uint16 public constant SAFE_MIN_APR = 0; // 0%

    /// Safe maximum for APR values
    uint16 public constant SAFE_MAX_APR = ONE_HUNDRED_PERCENT;

    /// Loan APR to be applied for the new loan requests
    uint16 public defaultAPR;

    /// Loan late payment APR delta to be applied fot the new loan requests
    uint16 public defaultLateAPRDelta;

    /// Contract math safe minimum loan amount including token decimals
    uint256 public constant SAFE_MIN_AMOUNT = 1000000; // 1 token unit with 6 decimals. i.e. 1 USDC

    /// Minimum allowed loan amount 
    uint256 public minAmount;

    /// Contract math safe minimum loan duration in seconds
    uint256 public constant SAFE_MIN_DURATION = 1 days;

    /// Contract math safe maximum loan duration in seconds
    uint256 public constant SAFE_MAX_DURATION = 51 * 365 days;

    /// Minimum loan duration in seconds
    uint256 public minDuration;

    /// Maximum loan duration in seconds
    uint256 public maxDuration;

    /// Loan id generator counter
    uint256 private nextLoanId;

    /// Quick lookup to check an address has pending loan applications
    mapping(address => bool) private hasOpenApplication;

    /// Total funds borrowed at this time, including both withdrawn and allocated for withdrawal.
    uint256 public borrowedFunds;

    /// Total borrowed funds allocated for withdrawal but not yet withdrawn by the borrowers
    uint256 public loanFundsPendingWithdrawal;

    /// Borrowed funds allocated for withdrawal by borrower addresses
    mapping(address => uint256) public loanFunds; //FIXE make internal

    /// Loan applications by loanId
    mapping(uint256 => Loan) public loans;

    /// Loan payment details by loanId. Loan detail is available only after a loan has been approved.
    mapping(uint256 => LoanDetail) public loanDetails;

    /// Recent loanId of an address. Value of 0 means that the address doe not have any loan requests
    mapping(address => uint256) public recentLoanIdOf;

    /**
     * @notice Create a Lender that ManagedLendingPool.
     * @dev minLoanAmount must be greater than or equal to SAFE_MIN_AMOUNT.
     * @param tokenAddress ERC20 token contract address to be used as main pool liquid currency.
     * @param protocol Address of a wallet to accumulate protocol earnings.
     * @param minLoanAmount Minimum amount to be borrowed per loan.
     */
    constructor(address tokenAddress, address protocol, uint256 minLoanAmount) ManagedLendingPool(tokenAddress, protocol) {
        
        nextLoanId = 1;

        require(SAFE_MIN_AMOUNT <= minLoanAmount, "New min loan amount is less than the safe limit");
        minAmount = minLoanAmount;
        
        defaultAPR = 300; // 30%
        defaultLateAPRDelta = 50; //5%
        minDuration = SAFE_MIN_DURATION;
        maxDuration = SAFE_MAX_DURATION;

        poolLiquidity = 0;
        borrowedFunds = 0;
        loanFundsPendingWithdrawal = 0;
    }

    function loansCount() external view returns(uint256) {
        return nextLoanId - 1;
    }

    //FIXME only allow protocol to edit critical parameters, not the manager

    /**
     * @notice Set annual loan interest rate for the future loans.
     * @dev apr must be inclusively between SAFE_MIN_APR and SAFE_MAX_APR.
     *      Caller must be the manager.
     * @param apr Loan APR to be applied for the new loan requests.
     */
    function setDefaultAPR(uint16 apr) external onlyManager {
        require(SAFE_MIN_APR <= apr && apr <= SAFE_MAX_APR, "APR is out of bounds");
        defaultAPR = apr;
    }

    /**
     * @notice Set late payment annual loan interest rate delta for the future loans.
     * @dev lateAPRDelta must be inclusively between SAFE_MIN_APR and SAFE_MAX_APR.
     *      Caller must be the manager.
     * @param lateAPRDelta Loan late payment APR delta to be applied for the new loan requests.
     */
    function setDefaultLateAPRDelta(uint16 lateAPRDelta) external onlyManager {
        require(SAFE_MIN_APR <= lateAPRDelta && lateAPRDelta <= SAFE_MAX_APR, "APR is out of bounds");
        defaultLateAPRDelta = lateAPRDelta;
    }

    /**
     * @notice Set a minimum loan amount for the future loans.
     * @dev minLoanAmount must be greater than or equal to SAFE_MIN_AMOUNT.
     *      Caller must be the manager.
     * @param minLoanAmount minimum loan amount to be enforced for the new loan requests.
     */
    function setMinLoanAmount(uint256 minLoanAmount) external onlyManager {
        require(SAFE_MIN_AMOUNT <= minLoanAmount, "New min loan amount is less than the safe limit");
        minAmount = minLoanAmount;
    }

    /**
     * @notice Set maximum loan duration for the future loans.
     * @dev Duration must be in seconds and inclusively between SAFE_MIN_DURATION and SAFE_MAX_DURATION.
     *      Caller must be the manager.
     * @param duration Maximum loan duration to be enforced for the new loan requests.
     */
    function setLoanMinDuration(uint256 duration) external onlyManager {
        require(SAFE_MIN_DURATION <= duration && duration <= SAFE_MAX_DURATION, "New min duration is out of bounds");
        require(duration <= maxDuration, "New min duration is greater than current max duration");
        minDuration = duration;
    }

    /**
     * @notice Set maximum loan duration for the future loans.
     * @dev Duration must be in seconds and inclusively between SAFE_MIN_DURATION and SAFE_MAX_DURATION.
     *      Caller must be the manager.
     * @param duration Maximum loan duration to be enforced for the new loan requests.
     */
    function setLoanMaxDuration(uint256 duration) external onlyManager {
        require(SAFE_MIN_DURATION <= duration && duration <= SAFE_MAX_DURATION, "New max duration is out of bounds");
        require(minDuration <= duration, "New max duration is less than current min duration");
        maxDuration = duration;
    }

    /**
     * @notice Request a new loan.
     * @dev Requested amount must be greater or equal to minAmount().
     *      Loan duration must be between minDuration() and maxDuration().
     *      Caller must not be a lender, protocol, or the manager. 
     *      Multiple pending applications from the same address are not allowed,
     *      most recent loan/application of the caller must not have APPLIED status.
     * @param requestedAmount Token amount to be borrowed.
     * @param loanDuration Loan duration in seconds. 
     * @return ID of a new loan application.
     */
    function requestLoan(uint256 requestedAmount, uint256 loanDuration) external onlyBorrower returns (uint256) {

        require(hasOpenApplication[msg.sender] == false, "Another loan application is pending.");

        //FIXME enforce minimum loan amount
        require(requestedAmount > 0, "Loan amount is zero.");
        require(minDuration <= loanDuration, "Loan duration is less than minimum allowed.");
        require(maxDuration >= loanDuration, "Loan duration is more than maximum allowed.");

        //TODO check:
        // ?? must not have unpaid late loans
        // ?? must not have defaulted loans

        uint256 loanId = nextLoanId;
        nextLoanId++;

        loans[loanId] = Loan({
            id: loanId,
            borrower: msg.sender,
            amount: requestedAmount,
            duration: loanDuration,
            apr: defaultAPR,
            lateAPRDelta: defaultLateAPRDelta,
            requestedTime: block.timestamp,
            status: LoanStatus.APPLIED
        });

        hasOpenApplication[msg.sender] = true;
        recentLoanIdOf[msg.sender] = loanId; 

        emit LoanRequested(loanId, msg.sender);

        return loanId;
    }

    /**
     * @notice Approve a loan.
     * @dev Loan must be in APPLIED status.
     *      Caller must be the manager.
     *      Loan amount must not exceed poolLiquidity();
     *      Stake to pool funds ratio must be good - poolCanLend() must be true.
     */
    function approveLoan(uint256 _loanId) external onlyManager loanInStatus(_loanId, LoanStatus.APPLIED) {
        Loan storage loan = loans[_loanId];

        //TODO implement any other checks for the loan to be approved
        // require(block.timestamp <= loan.requestedTime + 31 days, "This loan application has expired.");//FIXME

        require(poolLiquidity >= loan.amount, "BankFair: Pool liquidity is insufficient to approve this loan.");
        require(poolCanLend(), "BankFair: Stake amount is too low to approve new loans.");

        loanDetails[_loanId] = LoanDetail({
            loanId: _loanId,
            totalAmountRepaid: 0,
            baseAmountRepaid: 0,
            interestPaid: 0,
            approvedTime: block.timestamp,
            lastPaymentTime: 0
        });

        loan.status = LoanStatus.APPROVED;
        hasOpenApplication[loan.borrower] = false;

        increaseLoanFunds(loan.borrower, loan.amount);
        poolLiquidity = poolLiquidity.sub(loan.amount);
        borrowedFunds = borrowedFunds.add(loan.amount);

        emit LoanApproved(_loanId);
    }

    /**
     * @notice Deny a loan.
     * @dev Loan must be in APPLIED status.
     *      Caller must be the manager.
     */
    function denyLoan(uint256 loanId) external onlyManager loanInStatus(loanId, LoanStatus.APPLIED) {
        Loan storage loan = loans[loanId];
        loan.status = LoanStatus.DENIED;
        hasOpenApplication[loan.borrower] = false;

        emit LoanDenied(loanId);
    }

     /**
     * @notice Cancel a loan.
     * @dev Loan must be in APPROVED status.
     *      Caller must be the manager.
     */
    function cancelLoan(uint256 loanId) external onlyManager loanInStatus(loanId, LoanStatus.APPROVED) {
        Loan storage loan = loans[loanId];

        // require(block.timestamp > loanDetail.approvedTime + loan.duration + 31 days, "It is too early to cancel this loan."); //FIXME

        loan.status = LoanStatus.CANCELLED;
        decreaseLoanFunds(loan.borrower, loan.amount);
        poolLiquidity = poolLiquidity.add(loan.amount);
        borrowedFunds = borrowedFunds.sub(loan.amount);
        
        emit LoanCancelled(loanId);
    }

    /**
     * @notice Make a payment towards a loan.
     * @dev Caller must be the borrower.
     *      Loan must be in FUNDS_WITHDRAWN status.
     *      Only the necessary sum is charged if amount exceeds amount due.
     *      Amount charged will not exceed the amount parameter. 
     * @param loanId ID of the loan to make a payment towards.
     * @param amount Payment amount in tokens.
     * @return A pair of total amount changed including interest, and the interest charged.
     */
    function repay(uint256 loanId, uint256 amount) external loanInStatus(loanId, LoanStatus.FUNDS_WITHDRAWN) returns (uint256, uint256) {
        Loan storage loan = loans[loanId];

        // require the payer and the borrower to be the same to avoid mispayment
        require(loan.borrower == msg.sender, "Payer is not the borrower.");

        //TODO enforce a small minimum payment amount, except for the last payment 

        (uint256 amountDue, uint256 interestPercent) = loanBalanceDueWithInterest(loanId);
        uint256 transferAmount = Math.min(amountDue, amount);

        chargeTokensFrom(msg.sender, transferAmount);

        if (transferAmount == amountDue) {
            loan.status = LoanStatus.REPAID;
        }

        LoanDetail storage loanDetail = loanDetails[loanId];
        loanDetail.lastPaymentTime = block.timestamp;
        
        uint256 interestPaid = multiplyByFraction(transferAmount, interestPercent, ONE_HUNDRED_PERCENT + interestPercent);
        uint256 baseAmountPaid = transferAmount.sub(interestPaid);

        //share profits to protocol
        uint256 protocolEarnedInterest = multiplyByFraction(interestPaid, protocolEarningPercent, ONE_HUNDRED_PERCENT);
        
        protocolEarnings[protocolWallet] = protocolEarnings[protocolWallet].add(protocolEarnedInterest); 

        //share profits to manager 
        //TODO optimize manager earnings calculation

        uint256 currentStakePercent = multiplyByFraction(stakedShares, ONE_HUNDRED_PERCENT, totalPoolShares);
        uint256 managerEarningsPercent = multiplyByFraction(currentStakePercent, managerExcessLeverageComponent, ONE_HUNDRED_PERCENT);
        uint256 managerEarnedInterest = multiplyByFraction(interestPaid.sub(protocolEarnedInterest), managerEarningsPercent, ONE_HUNDRED_PERCENT);

        protocolEarnings[manager] = protocolEarnings[manager].add(managerEarnedInterest);

        loanDetail.totalAmountRepaid = loanDetail.totalAmountRepaid.add(transferAmount);
        loanDetail.baseAmountRepaid = loanDetail.baseAmountRepaid.add(baseAmountPaid);
        loanDetail.interestPaid = loanDetail.interestPaid.add(interestPaid);

        borrowedFunds = borrowedFunds.sub(baseAmountPaid);
        poolLiquidity = poolLiquidity.add(transferAmount.sub(protocolEarnedInterest.add(managerEarnedInterest)));

        return (transferAmount, interestPaid);
    }

    /**
     * @notice Default a loan.
     * @dev Loan must be in FUNDS_WITHDRAWN status.
     *      Caller must be the manager.
     */
    function defaultLoan(uint256 loanId) external onlyManager loanInStatus(loanId, LoanStatus.FUNDS_WITHDRAWN) {
        Loan storage loan = loans[loanId];
        LoanDetail storage loanDetail = loanDetails[loanId];

        //TODO implement any other checks for the loan to be defaulted
        // require(block.timestamp > loanDetail.approvedTime + loan.duration + 31 days, "It is too early to default this loan."); //FIXME

        loan.status = LoanStatus.DEFAULTED;

        (, uint256 loss) = loan.amount.trySub(loanDetail.totalAmountRepaid); //FIXME is this logic correct
        
        emit LoanDefaulted(loanId, loss);

        if (loss > 0) {
            deductLosses(loss);
        }

        if (loanDetail.baseAmountRepaid < loan.amount) {
            borrowedFunds = borrowedFunds.sub(loan.amount.sub(loanDetail.baseAmountRepaid));
        }
    }

    /**
     * @notice Loan balance due including interest if paid in full at this time. 
     * @dev Loan must be in FUNDS_WITHDRAWN status.
     * @param loanId ID of the loan to check the balance of.
     * @return Total amount due with interest on this loan.
     */
    function loanBalanceDue(uint256 loanId) external view loanInStatus(loanId, LoanStatus.FUNDS_WITHDRAWN) returns(uint256) {
        (uint256 amountDue,) = loanBalanceDueWithInterest(loanId);
        return amountDue;
    }

    /**
     * @notice Loan balance due including interest if paid in full at this time. 
     * @dev Internal method to get the amount due and the interest rate applied.
     * @param loanId ID of the loan to check the balance of.
     * @return A pair of a total amount due with interest on this loan, and a percentage representing the interest part of the due amount.
     */
    function loanBalanceDueWithInterest(uint256 loanId) internal view returns (uint256, uint256) {
        Loan storage loan = loans[loanId];
        if (loan.status == LoanStatus.REPAID) {
            return (0, 0);
        }

        LoanDetail storage loanDetail = loanDetails[loanId];
        uint256 interestPercent = calculateInterestPercent(loan, loanDetail);
        uint256 baseAmountDue = loan.amount.sub(loanDetail.baseAmountRepaid);
        uint256 balanceDue = baseAmountDue.add(multiplyByFraction(baseAmountDue, interestPercent, ONE_HUNDRED_PERCENT));

        return (balanceDue, interestPercent);
    }
    
    /**
     * @notice Get the percentage to calculate the interest due at this time.
     * @dev Internal helper method.
     * @param loan Reference to the loan in question.
     * @param loanDetail Reference to the loanDetail in question.
     * @return Percentage value to calculate the interest due.
     */
    function calculateInterestPercent(Loan storage loan, LoanDetail storage loanDetail) private view returns (uint256) {
        uint256 daysPassed = countInterestDays(loanDetail.approvedTime, block.timestamp);
        
        uint256 apr;
        uint256 loanDueTime = loanDetail.approvedTime.add(loan.duration);
        if (block.timestamp <= loanDueTime) { 
            apr = loan.apr;
        } else {
            uint256 lateDays = countInterestDays(loanDueTime, block.timestamp);
            apr = daysPassed
                .mul(loan.apr)
                .add(lateDays.mul(loan.lateAPRDelta))
                .div(daysPassed);
        }

        return multiplyByFraction(apr, daysPassed, 365);
    }

    /**
     * @notice Get the number of days in a time period to witch an interest can be applied.
     * @dev Internal helper method. Returns the ceiling of the count. 
     * @param timeFrom Epoch timestamp of the start of the time period.
     * @param timeTo Epoch timestamp of the end of the time period. 
     * @return Ceil count of days in a time period to witch an interest can be applied.
     */
    function countInterestDays(uint256 timeFrom, uint256 timeTo) private pure returns(uint256) {
        uint256 countSeconds = timeTo.sub(timeFrom);
        uint256 dayCount = countSeconds.div(86400);

        if (countSeconds.mod(86400) > 0) {
            dayCount++;
        }

        return dayCount;
    }

    //TODO consider security implications of having the following internal function
    /**
     * @dev Internal method to allocate funds to borrow upon loan approval
     * @param wallet Address to allocate funds to.
     * @param amount Token amount to allocate.
     */
    function increaseLoanFunds(address wallet, uint256 amount) private {
        loanFunds[wallet] = loanFunds[wallet].add(amount);
        loanFundsPendingWithdrawal = loanFundsPendingWithdrawal.add(amount);
    }

    //TODO consider security implications of having the following internal function
    /**
     * @dev Internal method to deallocate funds to borrow upon borrow()
     * @param wallet Address to deallocate the funds of.
     * @param amount Token amount to deallocate.
     */
    function decreaseLoanFunds(address wallet, uint256 amount) internal {
        require(loanFunds[wallet] >= amount, "BankFair: requested amount is not available in the funding account");
        loanFunds[wallet] = loanFunds[wallet].sub(amount);
        loanFundsPendingWithdrawal = loanFundsPendingWithdrawal.sub(amount);
    }

    //TODO consider security implications of having the following internal function
    /**
     * @dev Internal method to handle loss on a default.
     * @param lossAmount Unpaid base amount of a defaulted loan.
     */
    function deductLosses(uint256 lossAmount) internal {

        poolFunds = poolFunds.sub(lossAmount);

        uint256 lostShares = tokensToShares(lossAmount);
        uint256 remainingLostShares = lostShares;

        if (stakedShares > 0) {
            uint256 stakedShareLoss = Math.min(lostShares, stakedShares);
            remainingLostShares = lostShares.sub(stakedShareLoss);
            stakedShares = stakedShares.sub(stakedShareLoss);
            updatePoolLimit();

            burnShares(manager, stakedShareLoss);

            if (stakedShares == 0) {
                emit StakedAssetsDepleted();
            }
        }

        if (remainingLostShares > 0) {
            emit UnstakedLoss(lossAmount.sub(sharesToTokens(remainingLostShares)));
        }
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.12;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title BankFair Managed Lending Pool
 * @notice Provides the basics of a managed lending pool.
 * @dev This contract is abstract. Extend the contract to implement an intended pool functionality.
 */
abstract contract ManagedLendingPool {

    using SafeMath for uint256;

    /// Pool manager address
    address public manager;

    /// Protocol wallet address
    address public protocolWallet;

    /// Address of an ERC20 token used by the pool
    address public token;

    /// Total tokens currently held by this contract
    uint256 public tokenBalance;

    /// MAX amount of tokens allowed in the pool based on staked assets
    uint256 public poolFundsLimit;

    /// Current amount of tokens in the pool, including both liquid and borrowed funds
    uint256 public poolFunds; //poolLiquidity + borrowedFunds

    /// Current amount of liquid tokens, available to lend/withdraw/borrow
    uint256 public poolLiquidity;

    /// Total pool shares present
    uint256 public totalPoolShares;

    /// Manager's staked shares
    uint256 public stakedShares;

    /// Target percentage ratio of staked shares to total shares
    uint16 public targetStakePercent;

    //TODO remove and use targetStakePercent
    /// minimum stake percentage level to allow loan approvals
    uint16 public loanApprovalStakePercent; 

    /// Pool shares of wallets
    mapping(address => uint256) internal poolShares;

    /// Protocol earnings of wallets
    mapping(address => uint256) internal protocolEarnings; 
    
    /// Number of decimal digits in integer percent values used across the contract
    uint16 public constant PERCENT_DECIMALS = 1;

    /// A constant representing 100%
    uint16 public constant ONE_HUNDRED_PERCENT = 1000;

    /// Percentage of paid interest to be allocated as protocol earnings
    uint16 public protocolEarningPercent = 100; //10% by default; safe min 0%, max 10%

    /// Manager's leveraged earn factor represented as a percentage
    uint16 public managerLeveragedEarningPercent = 1500; // 150% or 1.5x leverage by default (safe min 100% or 1x)

    /// Part of the managers leverage factor, earnings of witch will be allocated for the manager as protocol earnings.
    /// This value is always equal to (managerLeveragedEarningPercent - ONE_HUNDRED_PERCENT)
    uint256 internal managerExcessLeverageComponent;

    event UnstakedLoss(uint256 amount);
    event StakedAssetsDepleted();

    modifier onlyManager {
        require(msg.sender == manager, "Managed: caller is not the manager");
        _;
    }

    /**
     * @notice Create a managed lending pool.
     * @dev msg.sender will be assigned as the manager of the created pool.
     * @param tokenAddress ERC20 token contract address to be used as main pool liquid currency.
     * @param protocol Address of a wallet to accumulate protocol earnings.
     */
    constructor(address tokenAddress, address protocol) {
        require(tokenAddress != address(0), "BankFair: pool token address is not set");
        require(protocol != address(0), "BankFair: protocol wallet address is not set");
        
        manager = msg.sender;
        protocolWallet = protocol;

        token = tokenAddress;
        tokenBalance = 0; 
        totalPoolShares = 0;
        stakedShares = 0;

        poolFundsLimit = 0;
        poolFunds = 0;

        targetStakePercent = 100; //10%
        loanApprovalStakePercent = 100; //10%

        managerExcessLeverageComponent = uint256(managerLeveragedEarningPercent).sub(ONE_HUNDRED_PERCENT);
    }

    /**
     * @notice Check the special addresses' earnings from the protocol. 
     * @dev This method is useful for manager and protocol addresses. 
     *      Calling this method for a non-protocol associated addresses will return 0.
     * @param wallet Address of the wallet to check the earnings balance of.
     * @return Accumulated earnings of the wallet from the protocol.
     */
    function protocolEarningsOf(address wallet) external view returns (uint256) {
        return protocolEarnings[wallet];
    }
 
    /**
     * @notice Withdraws protocol earnings belonging to the caller.
     * @dev protocolEarningsOf(msg.sender) must be greater than 0.
     *      Caller's all accumulated earnings will be withdrawn.
     */
    function withdrawProtocolEarnings() external {
        require(protocolEarnings[msg.sender] > 0, "BankFair: protocol earnings is zero on this account");
        uint256 amount = protocolEarnings[msg.sender];
        protocolEarnings[msg.sender] = 0; 

        // give tokens
        tokenBalance = tokenBalance.sub(amount);
        bool success = IERC20(token).transfer(msg.sender, amount);
        if(!success) {
            revert();
        }
    }

    /**
     * @notice Check if the pool can lend based on the current stake levels.
     * @return True if the staked funds provide at least a minimum ratio to the pool funds, False otherwise.
     */
    function poolCanLend() public view returns (bool) {
        return stakedShares >= multiplyByFraction(totalPoolShares, loanApprovalStakePercent, ONE_HUNDRED_PERCENT);
    }

    //TODO consider security implications of having the following internal function
    /**
     * @dev Internal method to charge tokens from a wallet.
     *      An appropriate approval must be present.
     * @param wallet Address to charge tokens from.
     * @param amount Token amount to charge.
     */
    function chargeTokensFrom(address wallet, uint256 amount) internal {
        bool success = IERC20(token).transferFrom(wallet, address(this), amount);
        if (!success) {
            revert();
        }
        tokenBalance = tokenBalance.add(amount);
    }

    /**
     * @dev Internal method to enter the pool with a token amount.
     *      With the exception of the manager's call, amount must not exceed amountDepositable().
     *      If the caller is the pool manager, entered funds are considered staked.
     *      New shares are minted in a way that will not influence the current share price.
     * @param amount A token amount to add to the pool on behalf of the caller.
     * @return Amount of shares minted and allocated to the caller.
     */
    function enterPool(uint256 amount) internal returns (uint256) {
        require(amount > 0, "BankFair: pool deposit amount is 0");

        // allow the manager to add funds beyond the current pool limit as all funds of the manager in the pool are staked,
        // and staking additional funds will in turn increase pool limit
        require(msg.sender == manager || (poolFundsLimit > poolFunds && amount <= poolFundsLimit.sub(poolFunds)),
         "BankFair: Deposit amount goes over the current pool limit.");

        uint256 shares = tokensToShares(amount);

        chargeTokensFrom(msg.sender, amount);
        poolLiquidity = poolLiquidity.add(amount);
        poolFunds = poolFunds.add(amount);

        // mint shares
        poolShares[msg.sender] = poolShares[msg.sender].add(shares);
        totalPoolShares = totalPoolShares.add(shares);

        return shares;
    }

    /**
     * @dev Internal method to exit the pool with a token amount.
     *      Amount must not exceed amountWithdrawable() for non managers, and amountUnstakable() for the manager.
     *      If the caller is the pool manager, exited funds are considered unstaked.
     *      Shares are burned in a way that will not influence the current share price.
     * @param amount A token amount to withdraw from the pool on behalf of the caller.
     * @return Amount of shares burned and taken from the caller.
     */
    function exitPool(uint256 amount) internal returns (uint256) {
        require(amount > 0, "BankFair: pool withdrawal amount is 0");
        require(poolLiquidity >= amount, "BankFair: pool liquidity is too low");

        uint256 shares = tokensToShares(amount); 
        //TODO handle failed pool case when any amount equates to 0 shares

        burnShares(msg.sender, shares);

        poolFunds = poolFunds.sub(amount);
        poolLiquidity = poolLiquidity.sub(amount);

        tokenBalance = tokenBalance.sub(amount);
        bool success = IERC20(token).transfer(msg.sender, amount);
        if(!success) {
            revert();
        }

        return shares;
    }

    //TODO consider security implications of having the following internal function
    /**
     * @dev Internal method to burn shares of a wallet.
     * @param wallet Address to burn shares of.
     * @param shares Share amount to burn.
     */
    function burnShares(address wallet, uint256 shares) internal {
        require(poolShares[wallet] >= shares, "BankFair: Insufficient balance for this operation.");
        poolShares[wallet] = poolShares[wallet].sub(shares);
        totalPoolShares = totalPoolShares.sub(shares);
    }

    /**
     * @dev Internal method to update pool limit based on staked funds. 
     */
    function updatePoolLimit() internal {
        poolFundsLimit = sharesToTokens(multiplyByFraction(stakedShares, ONE_HUNDRED_PERCENT, targetStakePercent));
    }
    
    /**
     * @notice Get a token value of shares.
     * @param shares Amount of shares
     */
    function sharesToTokens(uint256 shares) internal view returns (uint256) {
        if (shares == 0 || poolFunds == 0) {
             return 0;
        }

        return multiplyByFraction(shares, poolFunds, totalPoolShares);
    }

    /**
     * @notice Get a share value of tokens.
     * @param tokens Amount of tokens
     */
    function tokensToShares(uint256 tokens) internal view returns (uint256) {
        if (tokens == 0) {
            return 0;
        } else if (totalPoolShares == 0) {
            return tokens;
        }

        return multiplyByFraction(tokens, totalPoolShares, poolFunds);
    }

    //TODO move to a library
    /**
     * @notice Do a multiplication of a value by a fraction.
     * @param a value to be multiplied
     * @param b numerator of the fraction
     * @param c denominator of the fraction
     * @return Integer value of (a*b)/c if (a*b) does not overflow, else a*(b/c)
     */
    function multiplyByFraction(uint256 a, uint256 b, uint256 c) internal pure returns (uint256) {
        //FIXME handle c == 0
        //FIXME implement a better multiplication by fraction      

        (bool notOverflow, uint256 multiplied) = a.tryMul(b);

        if(notOverflow) {
            return multiplied.div(c);
        }
        
        return a.div(c).mul(b);
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