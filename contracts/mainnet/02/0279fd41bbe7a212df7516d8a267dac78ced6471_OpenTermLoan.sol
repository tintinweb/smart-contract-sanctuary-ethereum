/**
 *Submitted for verification at Etherscan.io on 2022-08-25
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

/**
 * @title Defines the interface of a basic pricing oracle.
 * @dev All prices are expressed in USD, with 6 decimal positions.
 */
interface IBasicPriceOracle {
    function updateTokenPrice (address tokenAddr, uint256 valueInUSD) external;
    function bulkUpdate (address[] memory tokens, uint256[] memory prices) external;
    function getTokenPrice (address tokenAddr) external view returns (uint256);
}

interface IERC20NonCompliant {
    function transfer(address to, uint256 value) external;
    function transferFrom(address from, address to, uint256 value) external;
    function approve(address spender, uint256 value) external;
    function totalSupply() external view returns (uint256);
    function balanceOf(address addr) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function decimals() external view returns (uint8);
}

/**
 * @title Represents a base line of credit
 */
abstract contract BaseLineOfCredit {
    // ---------------------------------------------------------------
    // States of a loan
    // ---------------------------------------------------------------
    uint8 constant internal INACTIVE = 0;           // The loan is inactive
    uint8 constant internal PREAPPROVED = 1;        // The loan was pre-approved by the lender
    uint8 constant internal FUNDING_REQUIRED = 2;   // The loan was accepted by the borrower. Waiting for the lender to fund the loan.
    uint8 constant internal ACTIVE = 3;             // The loan is active.
    uint8 constant internal CANCELLED = 4;          // The lender failed to fund the loan and the borrower claimed their collateral.
    uint8 constant internal MATURED = 5;            // The loan matured. It was liquidated by the lender.
    uint8 constant internal CLOSED = 6;             // The loan was closed normally.

    // ---------------------------------------------------------------
    // Other constants
    // ---------------------------------------------------------------
    // The zero address
    address constant internal ZERO_ADDRESS = address(0);

    // ---------------------------------------------------------------
    // Tightly packed state
    // ---------------------------------------------------------------
    /**
     * @notice The maximum number of principal tokens you can withdraw from this contract, as a borrower.
     */
    uint256 public maxWithdrawalAmount;

    /**
     * @notice The APR
     */
    uint256 public apr;

    /**
     * @notice The grace period, in seconds.
     * @dev The default value is 5 days.
     */
    uint256 public gracePeriod = 5 days;

    /**
     * @notice The late fee (percentage) with 2 decimal places
     */
    uint256 public lateFee;

    /**
     * @notice The funding period, in seconds
     */
    uint256 public immutable fundingPeriod;

    // The loan amount, expressed in principal tokens.
    uint256 internal _loanAmountInPrincipalTokens;

    // The origination fee (percentage), with 2 decimal places
    uint256 internal _originationFeePercent;

    // The initial collateral ratio, with 2 decimal places. It is zero for unsecured debt.
    uint256 internal _initialCollateralRatio;

    // The maintenance collateral ratio, with 2 decimal places. It is zero for unsecured debt.
    uint256 internal _maintenanceCollateralRatio;

    // The funding deadline. Investors are required to fund the principal before this exact point in time.
    uint256 internal _fundingDeadline;

    // The payment interval, expressed in seconds.
    uint256 internal _paymentIntervalInSeconds;

    // The date of the next payment, expressed as a Unix epoch.
    uint256 internal _nextPaymentDate;

    /**
     * @notice The address of the borrower per terms and conditions agreed between parties.
     */
    address public immutable borrower;

    /**
     * @notice The address of the lender per terms and conditions agreed between parties.
     */
    address public immutable lender;

    /**
     * @notice The address of the principal token.
     */
    address public immutable principalToken;

    /**
     * @notice The address of the collateral token, if any.
     * @dev The collateral token is the zero address for unsecured loans.
     */
    address public immutable collateralToken;

    /**
     * @notice The oracle for calculating token prices.
     */
    address public priceOracle;

    /**
     * @notice The current state of the loan
     */
    uint8 public loanState;

    // ---------------------------------------------------------------
    // Events
    // ---------------------------------------------------------------
    event OnBorrowerCommitment();
    event OnLoanFunded();
    event OnCollateralClaimed();
    event OnPriceOracleChanged();
    event OnLateFeeChanged();

    // ---------------------------------------------------------------
    // Constructor
    // ---------------------------------------------------------------
    /**
     * @notice Constructor.
     * @param lenderAddr The address of the lender.
     * @param borrowerAddr The address of the borrower.
     * @param newPrincipalToken The principal token.
     * @param newOracle The oracle.
     * @param newCollateralToken The collateral token, if any.
     * @param fundingPeriodInDays The funding period, in days.
     */    
    constructor (
        address lenderAddr, 
        address borrowerAddr,
        IERC20NonCompliant newPrincipalToken,
        IBasicPriceOracle newOracle,
        address newCollateralToken,
        uint256 fundingPeriodInDays
    ) {
        require(lenderAddr != ZERO_ADDRESS, "Invalid lender");
        require(borrowerAddr != lenderAddr, "Invalid borrower");
        require(fundingPeriodInDays > 0, "Invalid funding period");

        lender = lenderAddr;
        borrower = borrowerAddr;
        principalToken = address(newPrincipalToken);
        collateralToken = newCollateralToken;
        priceOracle = address(newOracle);
        fundingPeriod = fundingPeriodInDays * 1 days;
    }

    // ---------------------------------------------------------------
    // Modifiers
    // ---------------------------------------------------------------
    /**
     * @notice Throws if the caller is not the expected borrower.
     */
    modifier onlyBorrower() {
        require(msg.sender == borrower, "Only borrower");
        _;
    }

    /**
     * @notice Throws if the caller is not the expected lender.
     */
    modifier onlyLender() {
        require(msg.sender == lender, "Only lender");
        _;
    }

    /**
     * @notice Throws if the debt is unsecured
     */
    modifier onlyIfSecuredDebt () {
        // Unsecured loans do not require any collateral, by definition
        require(isSecured(), "This loan is unsecured");
        _;
    }

    /**
     * @notice Throws if the loan was defaulted.
     */
    modifier ifNotDefaulted () {
        require(block.timestamp <= _nextPaymentDate + gracePeriod, "Loan defaulted"); // solhint-disable-line not-rely-on-time
        _;
    }

    /**
     * @notice Throws if the loan was not defaulted.
     */
    modifier onlyIfDefaulted () {
        require(block.timestamp > _nextPaymentDate + gracePeriod, "Loan not defaulted"); // solhint-disable-line not-rely-on-time
        _;
    }

    /**
     * @notice Throws if the loan is not active.
     */
    modifier onlyIfActive () {
        require(loanState == ACTIVE, "Loan is not active");
        _;
    }

    // ---------------------------------------------------------------
    // Functions
    // ---------------------------------------------------------------
    /**
     * @notice Changes the oracle that calculates token prices.
     * @param newOracle The new oracle for token prices
     */
    function changeOracle (IBasicPriceOracle newOracle) public onlyLender {
        require(priceOracle != address(newOracle), "Oracle already set");
        priceOracle = address(newOracle);
        emit OnPriceOracleChanged();
    }

    /**
     * @notice Changes the fee applicable to overdue payments.
     * @param lateFeeWithTwoDecimals The late fee (percentage) with 2 decimal places.
     */
    function changeLateFee (uint256 lateFeeWithTwoDecimals) public onlyLender {
        require(lateFeeWithTwoDecimals > 0, "Non-zero late fee required");
        require(lateFee != lateFeeWithTwoDecimals, "Late fee already set");
        lateFee = lateFeeWithTwoDecimals;
        emit OnLateFeeChanged();
    }

    /**
     * @notice Allows the expected borrower to accept the loan offered by the lender.
     * @dev The deposit amount is zero for unsecured loans.
     */
    function borrowerCommitment () public onlyBorrower {
        // Checks
        require(loanState == PREAPPROVED, "Invalid loan state");

        // Update the state of the loan
        loanState = FUNDING_REQUIRED;

        // Set the deadline for funding the principal
        _fundingDeadline = block.timestamp + fundingPeriod; // solhint-disable-line not-rely-on-time

        if (isSecured()) {
            // This is the amount of collateral the borrower is required to deposit, in tokens.
            uint256 expectedDepositAmount = getInitialCollateralAmount();

            // Deposit the collateral
            _depositToken(IERC20NonCompliant(collateralToken), msg.sender, expectedDepositAmount);
        }

        // Emit the respective event
        emit OnBorrowerCommitment();
    }

    /**
     * @notice Funds this loan with the respective amount of principal, per loan specs.
     * @dev The loan must be funded within the time window specified. Otherwise, the borrower is allowed to claim their collateral.
     */
    function fundLoan () public onlyLender {
        require(loanState == FUNDING_REQUIRED, "Invalid loan state");
        require(block.timestamp <= _fundingDeadline, "Funding period elapsed"); // solhint-disable-line not-rely-on-time

        // The amount of principal tokens that need to be funded by the lender
        (uint256 expectedFundingAmount) = getFundingDepositAmount();

        // Update the state of the loan
        loanState = ACTIVE;
        _nextPaymentDate = block.timestamp + _paymentIntervalInSeconds; // solhint-disable-line not-rely-on-time

        // This is the max number of principal tokens that can be withdrawn by the borrower
        maxWithdrawalAmount = expectedFundingAmount;

        // Tell the derived contract that the loan is about to be funded
        _beforeLenderFundsLoan();

        // Fund the loan with the expected amount of collateral
        _depositToken(IERC20NonCompliant(principalToken), msg.sender, expectedFundingAmount);

        emit OnLoanFunded();
    }

    /**
     * @notice Claims the collateral deposited by the borrower
     */
    function claimCollateral () public onlyBorrower onlyIfSecuredDebt {
        require(loanState == FUNDING_REQUIRED, "Invalid loan state");
        require(block.timestamp > _fundingDeadline, "Funding period not elapsed"); // solhint-disable-line not-rely-on-time

        loanState = CANCELLED;
        emit OnCollateralClaimed();

        IERC20NonCompliant collateralTokenInterface = IERC20NonCompliant(collateralToken);
        uint256 currentBalance = collateralTokenInterface.balanceOf(address(this));
        collateralTokenInterface.transfer(borrower, currentBalance);
        require(collateralTokenInterface.balanceOf(address(this)) == 0, "Collateral transfer failed");
    }

    /**
     * @notice Grants a loan.
     */
    function _grantLoan (
        uint256 loanAmountInPrincipalTokens, 
        uint256 originationFeePercent2Decimals,
        uint256 initialCollateralRatioWith2Decimals, 
        uint256 maintenanceCollateralRatioWith2Decimals,
        uint256 lateFeeWithTwoDecimals,
        uint256 newPaymentIntervalInSeconds,
        uint256 newAprWithTwoDecimals
    ) internal {
        // Checks
        require(loanState == INACTIVE, "Invalid loan state");
        require(loanAmountInPrincipalTokens > 0, "Invalid loan amount");
        require(newAprWithTwoDecimals > 0, "Invalid APR");

        // Check the collateralization ratio
        if (isSecured()) {
            require(initialCollateralRatioWith2Decimals > 0 && initialCollateralRatioWith2Decimals <= 12000, "Invalid initial collateral");
            require(maintenanceCollateralRatioWith2Decimals > 0, "Maintenance ratio required");

            // The maintenance ratio must be lower than the initial collateral ratio
            require(maintenanceCollateralRatioWith2Decimals < initialCollateralRatioWith2Decimals, "Maintenance ratio too high");
        } else {
            require(initialCollateralRatioWith2Decimals == 0 && maintenanceCollateralRatioWith2Decimals == 0, "Invalid collateral ratio");
        }

        // The late fee (aka: penalty for overdue payments) is always required. 
        // For example, it could be as low as any negligible percent like 0.00000000000001%
        // In any case, it cannot be zero.
        require(lateFeeWithTwoDecimals > 0, "Non-zero late fee required");

        // The minimum payment interval is 24 hours (60x60x24). It can't be less than that.
        require(newPaymentIntervalInSeconds >= uint256(86400), "Payment interval too short");

        // Make sure the derived contract accepts/supports the payment interval specified.
        require(_isValidPaymentInterval(newPaymentIntervalInSeconds), "Invalid payment interval");

        // State changes
        _loanAmountInPrincipalTokens = loanAmountInPrincipalTokens;
        _initialCollateralRatio = initialCollateralRatioWith2Decimals;
        _maintenanceCollateralRatio = maintenanceCollateralRatioWith2Decimals;
        _originationFeePercent = originationFeePercent2Decimals;
        _paymentIntervalInSeconds = newPaymentIntervalInSeconds;
        lateFee = lateFeeWithTwoDecimals;
        apr = newAprWithTwoDecimals;
        loanState = PREAPPROVED;
    }

    // Deposits a specific amount of tokens into this smart contract
    function _depositToken (IERC20NonCompliant tokenInterface, address senderAddr, uint256 depositAmount) internal {
        require(depositAmount > 0, "Deposit amount required");

        // Check balance and allowance
        require(tokenInterface.allowance(senderAddr, address(this)) >= depositAmount, "Insufficient allowance");
        require(tokenInterface.balanceOf(senderAddr) >= depositAmount, "Insufficient funds");

        // Calculate the expected outcome, per check-effects-interaction pattern
        uint256 balanceBeforeTransfer = tokenInterface.balanceOf(address(this));
        uint256 expectedBalanceAfterTransfer = balanceBeforeTransfer + depositAmount;

        // Let the borrower deposit the predefined collateral through a partially-compliant ERC20
        tokenInterface.transferFrom(senderAddr, address(this), depositAmount);

        // Check the new balance
        uint256 actualBalanceAfterTransfer = tokenInterface.balanceOf(address(this));
        require(actualBalanceAfterTransfer == expectedBalanceAfterTransfer, "Deposit failed");
    }

    function _transferPrincipalAndCollateral (address collateralRecipientAddr, address principalRecipientAddr) internal {
        // Transfer the collateral, if applicable
        if (isSecured()) {
            IERC20NonCompliant collateralTokenInterface = IERC20NonCompliant(collateralToken);
            uint256 collateralBalanceInTokens = collateralTokenInterface.balanceOf(address(this));
            collateralTokenInterface.transfer(collateralRecipientAddr, collateralBalanceInTokens);
            require(collateralTokenInterface.balanceOf(address(this)) == 0, "Collateral transfer failed");
        }

        IERC20NonCompliant principalTokenInterface = IERC20NonCompliant(principalToken);
        uint256 principalBalanceInTokens = principalTokenInterface.balanceOf(address(this));
        if (principalBalanceInTokens > 0) {
            principalTokenInterface.transfer(principalRecipientAddr, principalBalanceInTokens);
            require(principalTokenInterface.balanceOf(address(this)) == 0, "Principal transfer failed");
        }
    }

    // This function gets called when the lender funds the loan
    function _beforeLenderFundsLoan () internal virtual;

    // Gets the number of collateral tokens required to represent the amount of principal specified.
    function fromTokenToToken (uint256 principalPrice, uint256 principalQty, uint256 collateralPrice, uint256 collateralDecimals) public pure returns (uint256) {
        return ((principalPrice * principalQty) / collateralPrice) * (10 ** (collateralDecimals - 6));
    }

    /**
     * @notice Gets the amount of principal tokens required to fund the loan.
     * @return expectedFundingAmount Returns the effective loan amount, expressed in principal tokens.
     */
    function getFundingDepositAmount () public view returns (uint256 expectedFundingAmount) {
        expectedFundingAmount = _loanAmountInPrincipalTokens - (_loanAmountInPrincipalTokens * _originationFeePercent / 1e4);
        require(expectedFundingAmount > 0, "Invalid funding amount");
    }

    /**
     * @notice Gets the amount of initial collateral that needs to be deposited in this contract.
     * @return The amount of initial collateral to deposit.
     */
    function getInitialCollateralAmount () public view returns (uint256) {
        return _getCollateralAmount(_initialCollateralRatio);
    }

    /**
     * @notice Gets the amount of maintenance collateral that needs to be deposited in this contract.
     * @return The amount of maintenance collateral to deposit.
     */
    function getMaintenanceCollateralAmount () public view returns (uint256) {
        return _getCollateralAmount(_maintenanceCollateralRatio);
    }

    /**
     * @notice Indicates whether the loan is secured or not.
     * @return Returns true if the loan represents secured debt.
     */
    function isSecured () public view returns (bool) {
        return collateralToken != ZERO_ADDRESS;
    }

    // Enforces the maintenance collateral ratio
    function _enforceMaintenanceRatio () internal view {
        if (!isSecured()) return;

        // This is the amount of collateral tokens the borrower is required to maintain.
        uint256 expectedCollatAmount = getMaintenanceCollateralAmount();

        IERC20NonCompliant collateralTokenInterface = IERC20NonCompliant(collateralToken);
        require(collateralTokenInterface.balanceOf(address(this)) >= expectedCollatAmount, "Insufficient maintenance ratio");
    }

    function _getCollateralAmount (uint256 collatRatio) internal view returns (uint256) {
        if (!isSecured()) return 0;

        uint256 principalPrice = IBasicPriceOracle(priceOracle).getTokenPrice(principalToken);
        require(principalPrice > 0, "Invalid price for principal");

        uint256 collateralPrice = IBasicPriceOracle(priceOracle).getTokenPrice(collateralToken);
        require(collateralPrice > 0, "Invalid price for collateral");

        IERC20NonCompliant collateralTokenInterface = IERC20NonCompliant(collateralToken);
        uint256 collateralDecimals = uint256(collateralTokenInterface.decimals());
        require(collateralDecimals >= 6, "Invalid collateral token");

        uint256 collateralInPrincipalTokens = _loanAmountInPrincipalTokens * collatRatio / 1e4;
        return fromTokenToToken(principalPrice, collateralInPrincipalTokens, collateralPrice, collateralDecimals);
    }

    // Gets the late fee applicable to the amount specified. Notice that this fee is applicable on a daily basis.
    function _getDailyLateFee (uint256 amount) internal virtual view returns (uint256) {
        return amount * lateFee * 1 days / 1e4 / 365 days;
    }

    function _getApplicableLateFee (uint256 ts, uint256 amount) internal virtual view returns (uint256) {
        if (_nextPaymentDate == 0 || ts <= _nextPaymentDate) return 0;

        // Apply a late fee accordingly
        uint256 diffSeconds = _nextPaymentDate - ts;
        uint256 diffDays = (diffSeconds % 86400 == 0) ? diffSeconds / 86400 : (diffSeconds / 86400) + 1;
        return _getDailyLateFee(amount) * diffDays;
    }

    // Indicates if the payment interval specified is supported by the current contract.
    function _isValidPaymentInterval (uint256 newPaymentIntervalInSeconds) internal pure virtual returns (bool);
}

/**
 * @title Represents a loan.
 */
abstract contract BaseLoan is BaseLineOfCredit {
    // ---------------------------------------------------------------
    // Tightly packed state
    // ---------------------------------------------------------------
    /**
     * @notice The callback period, if any.
     */
    uint256 public callbackPeriod;

    // The remaining debt
    uint256 internal _remainingDebt;

    // Indicates if the loan can be called
    bool internal immutable _isCallableLoan;

    // ---------------------------------------------------------------
    // Events
    // ---------------------------------------------------------------
    event OnLoanCalled (uint256 callbackPeriodInDays, uint256 gracePeriodInDays);
    event OnGracePeriodChanged();
    event OnLoanMatured();
    event OnLoanClosed();

    // ---------------------------------------------------------------
    // Constructor
    // ---------------------------------------------------------------
    /**
     * @notice Constructor.
     * @param lenderAddr The address of the lender.
     * @param borrowerAddr The address of the borrower.
     * @param newPrincipalToken The principal token.
     * @param newOracle The oracle.
     * @param newCollateralToken The collateral token, if any.
     * @param fundingPeriodInDays The funding period, in days.
     * @param isCallable Indicates if the loan can be called by the lender.
     */
    constructor (
        address lenderAddr, 
        address borrowerAddr,
        IERC20NonCompliant newPrincipalToken,
        IBasicPriceOracle newOracle,
        address newCollateralToken,
        uint256 fundingPeriodInDays,
        bool isCallable
    ) BaseLineOfCredit(lenderAddr, borrowerAddr, newPrincipalToken, newOracle, newCollateralToken, fundingPeriodInDays) {
        _isCallableLoan = isCallable;
    }

    // ---------------------------------------------------------------
    // Modifiers
    // ---------------------------------------------------------------
    /**
     * @notice Throws if the pending debt is greater than zero.
     */
    modifier onlyIfPendingDebt () {
        require(_remainingDebt > 0, "No debt to liquidate");
        _;
    }

    /**
     * @notice Throws if there is no debt to cancel.
     */
    modifier ifNoPendingDebt () {
        require(_remainingDebt == 0, "Pending debt in place");
        _;
    }

    /**
     * @notice Throws if the caller is not the lender nor the borrower.
     */
    modifier onlyLenderOrBorrower() {
        require(msg.sender == lender || msg.sender == borrower, "Only lender or borrower");
        _;
    }

    // ---------------------------------------------------------------
    // Functions
    // ---------------------------------------------------------------
    /**
     * @notice Changes the grace period.
     * @param newGracePeriodInDays The grace period, in days.
     */
    function changeGracePeriod (uint256 newGracePeriodInDays) public virtual onlyLender ifNotDefaulted {
        // The loan was not called so the lender is allowed to change the grace period
        uint256 newGracePeriodInSeconds = newGracePeriodInDays * 1 days;
        gracePeriod = newGracePeriodInSeconds;
        emit OnGracePeriodChanged();
    }

    /**
     * @notice Liquidates the loan.
     */
    function liquidate () public onlyLender onlyIfActive onlyIfPendingDebt onlyIfDefaulted {
        // State changes
        loanState = MATURED;

        // Transfer the collateral to the lender. Transfer any remaining principal to the lender as well.
        _transferPrincipalAndCollateral(lender, lender);

        emit OnLoanMatured();
    }

    /**
     * @notice Closes the loan.
     */
    function closeLoan () public virtual onlyLenderOrBorrower onlyIfActive ifNoPendingDebt {
        // Send the collateral back to the borrower. Send the principal back to the lender.
        _closeLoan();

        emit OnLoanClosed();
    }

    // Calls the loan. The loan can be called even if the debt is defaulted.
    function _callLoan (uint256 callbackPeriodInDays, uint256 gracePeriodInDays) internal {
        require(_isCallableLoan, "The loan is not callable");
        require(callbackPeriod == 0, "Loan was called already");
        require(callbackPeriodInDays > 0, "Callback period required");
        require(gracePeriodInDays > 0, "Grace period required");

        callbackPeriod = block.timestamp + callbackPeriodInDays * 1 days; // solhint-disable-line not-rely-on-time
        gracePeriod = gracePeriodInDays * 1 days;
        _nextPaymentDate = callbackPeriod;

        emit OnLoanCalled(callbackPeriodInDays, gracePeriodInDays);
    }

    // Closes the loan
    function _closeLoan () internal {
        // Enforce the maintenance collateral ratio, if applicable
        _enforceMaintenanceRatio();

        // Update the state of the loan
        loanState = CLOSED;

        // Send the collateral back to the borrower, if applicable. Send any remaining the principal back to the lender.
        _transferPrincipalAndCollateral(borrower, lender);
    }

    // Transfers the amount of principal tokens specified to the borrower.
    function _withdrawPrincipalTokens (uint256 amountInPrincipalTokens) internal {
        // This is the maximum amount you could ever withdraw from this contract as a borrower
        require(amountInPrincipalTokens > 0 && amountInPrincipalTokens <= maxWithdrawalAmount, "Invalid withdrawal amount");

        require(callbackPeriod == 0, "The loan was called");

        // Enforce the maintenance collateral ratio, if applicable
        _enforceMaintenanceRatio();

        // Check the balance of the contract (principal)
        IERC20NonCompliant principalTokenInterface = IERC20NonCompliant(principalToken);
        uint256 currentBalanceAtContract = principalTokenInterface.balanceOf(address(this));
        require(currentBalanceAtContract >= amountInPrincipalTokens, "Insufficient balance");

        // Let the derived contract know that we are about to transfer funds (principal tokens) to the borrower.
        // This allows the derived contract to update their internal state and/or accounting.
        _beforeBorrowerWithdrawal(amountInPrincipalTokens);

        // Transfer the funds
        uint256 currentBalanceAtBorrower = principalTokenInterface.balanceOf(borrower);
        uint256 newBalanceAtBorrower = currentBalanceAtBorrower + amountInPrincipalTokens;
        uint256 newBalanceAtContract = currentBalanceAtContract - amountInPrincipalTokens;

        principalTokenInterface.transfer(borrower, amountInPrincipalTokens);

        require(principalTokenInterface.balanceOf(address(this)) == newBalanceAtContract, "Balance check failed");
        require(principalTokenInterface.balanceOf(borrower) == newBalanceAtBorrower, "Borrower transfer check failed");
    }

    /**
     * @notice Get the amount of the next payment, including any late fees.
     * @return Returns the payment amount, expressed in principal tokens.
     */
    function getPaymentAmount () public view virtual returns (uint256) {
        (, , uint256 totalAmount) = getPaymentAmountDetails();
        return totalAmount;
    }

    /**
     * @notice Gets the amount of the next payment, including any late fees.
     * @return paymentAmountWithoutFees The payment amount without any fees
     * @return applicableLateFee The applicable fee, if any
     * @return totalAmount The total payment amount, including any fees
     */
    function getPaymentAmountDetails () public view virtual returns (uint256 paymentAmountWithoutFees, uint256 applicableLateFee, uint256 totalAmount) {
        uint256 ts = block.timestamp; // solhint-disable-line not-rely-on-time
        paymentAmountWithoutFees = _getPaymentAmountWithoutFees();
        applicableLateFee = _getApplicableLateFee(ts, _remainingDebt);
        totalAmount = paymentAmountWithoutFees + applicableLateFee;
    }

    // This function gets called whenever the borrower withdraws funds from this contract.
    function _beforeBorrowerWithdrawal (uint256 amountInPrincipalTokens) internal virtual;

    // Gets the payment amount (without any fees) applicable to the current billing cycle. The math may vary depending on the type of loan.
    function _getPaymentAmountWithoutFees () internal view virtual returns (uint256);
}

/**
 * @title Represents an open-term loan.
 */
contract OpenTermLoan is BaseLoan {
    /**
     * @notice The minimum payment to make at the end of the billing cycle, as a percentage.
     */
    uint256 public minPaymentPercent;

    /**
     * @notice The interests that can be claimed by the lender
     */
    uint256 public claimableInterests;

    uint256 private _totalInterestsApplied;

    // ---------------------------------------------------------------
    // Events
    // ---------------------------------------------------------------
    event OnLoanInitialized();
    event OnPrincipalWithdrawal (uint256 numberOfTokens);
    event OnRepayment (uint256 paymentAmountTokens);

    // ---------------------------------------------------------------
    // Constructor
    // ---------------------------------------------------------------
    /**
     * @notice Constructor.
     * @param lenderAddr The address of the lender.
     * @param borrowerAddr The address of the borrower.
     * @param newPrincipalToken The principal token.
     * @param newOracle The oracle.
     * @param newCollateralToken The collateral token, if any.
     * @param fundingPeriodInDays The funding period, in days.
     */
    constructor (
        address lenderAddr, 
        address borrowerAddr,
        IERC20NonCompliant newPrincipalToken,
        IBasicPriceOracle newOracle,
        address newCollateralToken,
        uint256 fundingPeriodInDays
    ) BaseLoan(lenderAddr, borrowerAddr, newPrincipalToken, newOracle, newCollateralToken, fundingPeriodInDays, true) { // solhint-disable-line no-empty-blocks
    }

    // ---------------------------------------------------------------
    // Functions
    // ---------------------------------------------------------------
    /**
     * @notice Initializes the parameters of the loan.
     * @param loanAmountInPrincipalTokens The loan amount, in principal currency.
     * @param originationFeePercent2Decimals The origination fee. It is a percentage with 2 decimal places.
     * @param initialCollateralRatioWith2Decimals The initial collateral ratio, if any.
     * @param maintenanceCollateralRatioWith2Decimals The maintenance collateral ratio, if any.
     * @param lateFeeWithTwoDecimals The late fee (percentage) with 2 decimal places.
     * @param newPaymentIntervalInSeconds The payment interval, in seconds.
     * @param newAprWithTwoDecimals The APR. It is a percentage with 2 decimal places.
     * @param minPaymentPercentWith2Decimals The minimum payment to make at the end of the billing cycle, as a percentage.
     */
    function initializeLoanParameters (
        uint256 loanAmountInPrincipalTokens, 
        uint256 originationFeePercent2Decimals,
        uint256 initialCollateralRatioWith2Decimals, 
        uint256 maintenanceCollateralRatioWith2Decimals,
        uint256 lateFeeWithTwoDecimals,
        uint256 newPaymentIntervalInSeconds,
        uint256 newAprWithTwoDecimals,
        uint256 minPaymentPercentWith2Decimals
    ) public onlyLender {
        require(minPaymentPercentWith2Decimals > 0, "Invalid minimum payment");

        _grantLoan(loanAmountInPrincipalTokens, originationFeePercent2Decimals, initialCollateralRatioWith2Decimals, maintenanceCollateralRatioWith2Decimals, lateFeeWithTwoDecimals, newPaymentIntervalInSeconds, newAprWithTwoDecimals);

        // The minimum payment amount, as a percentage (with 2 decimal places)
        minPaymentPercent = minPaymentPercentWith2Decimals;

        emit OnLoanInitialized();
    }

    /**
     * @notice Sets the minimum payment to make at the end of the billing cycle
     * @param minPaymentPercentWith2Decimals The minimum payment to make at the end of the billing cycle, as a percentage.
     */
    function setMinPaymentPercent (uint256 minPaymentPercentWith2Decimals) public onlyLender {
        require(minPaymentPercentWith2Decimals > 0, "Invalid minimum payment");
        minPaymentPercent = minPaymentPercentWith2Decimals;
    }

    /**
     * @notice Withdraws the principal amount of tokens specified.
     * @dev Withdrawals are available as long as the loan is not called by the lender.
     * @param numberOfTokens The number of tokens to withdraw
     */
    function withdraw (uint256 numberOfTokens) public onlyBorrower onlyIfActive ifNotDefaulted {
        // In this case, the borrower is required to withdraw the full amount of principal deposited in the contract
        require(numberOfTokens == maxWithdrawalAmount, "Invalid withdrawal amount");

        // Send principal tokens to the borrower
        _withdrawPrincipalTokens(numberOfTokens);

        // Emit the event
        emit OnPrincipalWithdrawal(numberOfTokens);
    }

    /**
     * @notice Calls the loan.
     * @param callbackPeriodInDays The callback period, measured in days.
     * @param gracePeriodInDays The grace period, measured in days.
     */
    function callLoan (uint256 callbackPeriodInDays, uint256 gracePeriodInDays) public onlyLender onlyIfActive {
        _callLoan(callbackPeriodInDays, gracePeriodInDays);
    }

    /**
     * @notice Makes a repayment.
     * @dev In this case, the borrower is allowed to repay any amount of their preference.
     * @param paymentAmountTokens The payment amount, expressed in tokens.
     */
    function repay (uint256 paymentAmountTokens) public onlyBorrower onlyIfActive onlyIfPendingDebt ifNotDefaulted {
        require(paymentAmountTokens > 0 && paymentAmountTokens >= minimumPaymentAmount(), "Minimum payment amount required");

        // The payment amount cannot exceed the remaining debt, including any fees.
        require(paymentAmountTokens <= getPaymentAmount(), "Amount exceeds pending debt");

        // Enforce the maintenance collateral ratio, if applicable
        _enforceMaintenanceRatio();

        // Decrease the remaining debt
        _remainingDebt -= paymentAmountTokens;

        // Update the interests that can be claimed by the lender
        if (paymentAmountTokens <= _totalInterestsApplied) {
            claimableInterests += paymentAmountTokens;
            _totalInterestsApplied -= paymentAmountTokens;
        } else {
            claimableInterests += _totalInterestsApplied;
            _totalInterestsApplied = 0;
        }

        // Let the borrower repay their debt.
        // In this case, the borrower is allowed to repay any amount of their preference.
        _depositToken(IERC20NonCompliant(principalToken), msg.sender, paymentAmountTokens);

        emit OnRepayment(paymentAmountTokens);
    }

    /**
     * @notice Sends any claimable interests to the lender.
     */
    function withdrawInterests () public onlyLender onlyIfActive onlyIfPendingDebt {
        require(claimableInterests > 0, "No interests to claim");
        
        uint256 transferAmount = claimableInterests;

        IERC20NonCompliant principalTokenInterface = IERC20NonCompliant(principalToken);
        uint256 currentBalanceAtContract = principalTokenInterface.balanceOf(address(this));
        require(currentBalanceAtContract >= transferAmount, "Insufficient balance");

        uint256 expectedBalanceAtContract = currentBalanceAtContract - transferAmount;
        claimableInterests = 0;

        principalTokenInterface.transfer(lender, transferAmount);

        require(principalTokenInterface.balanceOf(address(this)) == expectedBalanceAtContract, "Interests transfer failed");
    }

    // This function gets called when the lender funds the loan
    function _beforeLenderFundsLoan () internal override {
        // In this case, the loan has an open term. Thus we cannot set a fixed payment date.
        // In this context, the borrower is allowed to repay any remaining debt with no penalties at all.
        // Late fees are not applicable either, because the loan has no term.
        //
        // Provided the above, we set the next payment date to 1000 years in the future; for the sake of blockchain limits.
        // One would be tempted to set the payment date to the maximum possible unsigned integer, which is type(uint256).max
        // Doing so would break the boundaries of an uint256, provided that we need to take into account the grace period as well.
        _nextPaymentDate = block.timestamp + 365000 days; // solhint-disable-line not-rely-on-time
    }

    // This function gets called whenever the borrower withdraws funds from this contract.
    function _beforeBorrowerWithdrawal (uint256 amountInPrincipalTokens) internal override {
        uint256 applicableInterest = amountInPrincipalTokens * apr * _paymentIntervalInSeconds / 1e4 / 365 days;
        _remainingDebt += (amountInPrincipalTokens + applicableInterest);
        _totalInterestsApplied += applicableInterest;
    }

    /**
     * @notice Gets the minimum payment to make at the end of the billing cycle
     * @return Returns the minimum payment amount
     */
    function minimumPaymentAmount () public view returns (uint256) {
        return _remainingDebt * minPaymentPercent / 1e4;
    }

    // Indicates if the payment interval specified is supported
    function _isValidPaymentInterval (uint256 newPaymentIntervalInSeconds) internal pure override returns (bool) {
        return (newPaymentIntervalInSeconds >= 1 days);
    }

    // Gets the payment amount (without any fees) applicable to the current billing cycle. The math may vary depending on the type of loan.
    function _getPaymentAmountWithoutFees () internal view override returns (uint256) {
        return _remainingDebt;
    }
}