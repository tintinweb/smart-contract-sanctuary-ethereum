/**
 *Submitted for verification at Etherscan.io on 2022-09-14
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
 * @title Represents an open-term loan.
 */
contract OpenTermLoan {
    // ---------------------------------------------------------------
    // States of a loan
    // ---------------------------------------------------------------
    uint8 constant internal INACTIVE = 0;           // The loan is inactive
    uint8 constant internal PREAPPROVED = 1;        // The loan was pre-approved by the lender
    uint8 constant internal FUNDING_REQUIRED = 2;   // The loan was accepted by the borrower. Waiting for the lender to fund the loan.
    uint8 constant internal FUNDED = 3;             // The loan was funded.
    uint8 constant internal ACTIVE = 4;             // The loan is active.
    uint8 constant internal CANCELLED = 5;          // The lender failed to fund the loan and the borrower claimed their collateral.
    uint8 constant internal MATURED = 6;            // The loan matured. It was liquidated by the lender.
    uint8 constant internal CLOSED = 7;             // The loan was closed normally.

    // ---------------------------------------------------------------
    // Other constants
    // ---------------------------------------------------------------
    // The zero address
    address constant internal ZERO_ADDRESS = address(0);

    // The minimum payment interval, expressed in seconds
    uint256 constant internal MIN_PAYMENT_INTERVAL = 3 hours;


    // ---------------------------------------------------------------
    // Tightly packed state
    // ---------------------------------------------------------------
    /**
     * @notice The APR
     */
    uint256 public immutable apr;

    /**
     * @notice The funding period, in seconds
     */
    uint256 public immutable fundingPeriod;

    /**
     * @notice The grace period, in seconds.
     * @dev The default value is 5 days.
     */
    uint256 public gracePeriod = 5 days;

    /**
     * @notice The late interests fee, as a percentage with 2 decimal places
     */
    uint256 public lateInterestFee;

    /**
     * @notice The late principal fee, as a percentage with 2 decimal places
     */
    uint256 public latePrincipalFee;

    /**
     * @notice The callback period, if any.
     */
    uint256 public callbackPeriod;

    /**
     * @notice The date of the next payment, expressed as a Unix epoch.
     */
    uint256 public nextPaymentDate;

    /**
     * @notice The date in which the loan was funded by the lender(s).
     */
    uint256 public fundedOn;

    /**
     * @notice The fees repaid by the borrower throughout the lifetime of the loan
     */
    uint256 public feesRepaid;

    // The loan amount, expressed in principal tokens.
    uint256 internal immutable _loanAmountInPrincipalTokens;

    // The effective loan amount
    uint256 internal immutable _effectiveLoanAmount;

    // The initial collateral ratio, with 2 decimal places. It is zero for unsecured debt.
    uint256 internal immutable _initialCollateralRatio;

    // The maintenance collateral ratio, with 2 decimal places. It is zero for unsecured debt.
    uint256 internal _maintenanceCollateralRatio;

    // The funding deadline. Investors are required to fund the principal before this exact point in time.
    uint256 internal _fundingDeadline;

    // The payment interval, expressed in seconds.
    uint256 internal immutable _paymentIntervalInSeconds;

    // The remaining debt
    uint256 internal _remainingDebt;

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
    event OnLoanInitialized();
    event OnBorrowerCommitment();
    event OnLoanFunded();
    event OnCollateralClaimed();
    event OnPrincipalClaimed(uint256 numberOfTokens);
    event OnPriceOracleChanged(address prevAddress, address newAddress);
    event OnBorrowerWithdrawal (uint256 numberOfTokens);
    event OnLoanCalled (uint256 callbackPeriodInDays, uint256 gracePeriodInDays);
    event OnRepayment (uint256 paymentAmountTokens);
    event OnLoanClosed();
    event OnLoanMatured();

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
     * @param newPaymentIntervalInSeconds The payment interval, in seconds.
     * @param loanAmountInPrincipalTokens The loan amount, in principal currency.
     * @param originationFeePercent2Decimals The origination fee. It is a percentage with 2 decimal places.
     * @param newAprWithTwoDecimals The APR. It is a percentage with 2 decimal places.
     * @param initialCollateralRatioWith2Decimals The initial collateral ratio, if any.
     */    
    constructor (
        address lenderAddr, 
        address borrowerAddr,
        IERC20NonCompliant newPrincipalToken,
        IBasicPriceOracle newOracle,
        address newCollateralToken,
        uint256 fundingPeriodInDays,
        uint256 newPaymentIntervalInSeconds,
        uint256 loanAmountInPrincipalTokens, 
        uint256 originationFeePercent2Decimals,
        uint256 newAprWithTwoDecimals,
        uint256 initialCollateralRatioWith2Decimals
    ) {
        require(lenderAddr != ZERO_ADDRESS, "Invalid lender");
        require(borrowerAddr != lenderAddr, "Invalid borrower");
        require(fundingPeriodInDays > 0, "Invalid funding period");
        require(loanAmountInPrincipalTokens > 0, "Invalid loan amount");
        require(newAprWithTwoDecimals > 0, "Invalid APR");

        // The minimum payment interval is 3 hours
        require(newPaymentIntervalInSeconds >= MIN_PAYMENT_INTERVAL, "Payment interval too short");

        if (newCollateralToken == ZERO_ADDRESS) {
            // Unsecured loan
            require(initialCollateralRatioWith2Decimals == 0, "Invalid initial collateral");
        } else {
            // Secured loan
            require(initialCollateralRatioWith2Decimals > 0 && initialCollateralRatioWith2Decimals <= 12000, "Invalid initial collateral");
        }

        // State changes
        lender = lenderAddr;
        borrower = borrowerAddr;
        principalToken = address(newPrincipalToken);
        collateralToken = newCollateralToken;
        priceOracle = address(newOracle);
        fundingPeriod = fundingPeriodInDays * 1 days;
        apr = newAprWithTwoDecimals;
        _paymentIntervalInSeconds = newPaymentIntervalInSeconds;
        _loanAmountInPrincipalTokens = loanAmountInPrincipalTokens;
        _initialCollateralRatio = initialCollateralRatioWith2Decimals;
        _effectiveLoanAmount = loanAmountInPrincipalTokens - (loanAmountInPrincipalTokens * originationFeePercent2Decimals / 1e4);
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
     * @notice Throws if the loan is not active.
     */
    modifier onlyIfActiveOrFunded () {
        require(loanState == ACTIVE || loanState == FUNDED, "Loan is not active");
        _;
    }

    /**
     * @notice Throws if the pending debt is greater than zero.
     */
    modifier onlyIfPendingDebt () {
        require(_remainingDebt > 0, "No debt to liquidate");
        _;
    }

    // ---------------------------------------------------------------
    // Functions
    // ---------------------------------------------------------------
    /**
     * @notice Initializes the parameters of the loan.
     * @dev Only the lender is allowed to call this function
     * @param maintenanceCollateralRatioWith2Decimals The maintenance collateral ratio, if any.
     * @param lateInterestFeeWithTwoDecimals The late interest fee (percentage) with 2 decimal places.
     * @param latePrincipalFeeWithTwoDecimals The late principal fee (percentage) with 2 decimal places.
     */
    function initializeLoanParameters (
        uint256 maintenanceCollateralRatioWith2Decimals,
        uint256 lateInterestFeeWithTwoDecimals,
        uint256 latePrincipalFeeWithTwoDecimals
    ) public onlyLender {
        // Checks
        require(loanState == INACTIVE, "Invalid loan state");

        // Check the collateralization ratio
        if (isSecured()) {
            // The maintenance ratio must be lower than the initial collateral ratio
            require(maintenanceCollateralRatioWith2Decimals > 0, "Maintenance ratio required");
            require(maintenanceCollateralRatioWith2Decimals < _initialCollateralRatio, "Maintenance ratio too high");
        } else {
            // The maintenance ratio must be zero
            require(maintenanceCollateralRatioWith2Decimals == 0, "Invalid maintenance ratio");
        }

        // The late fee (aka: penalty for overdue payments) is always required. 
        // For example, it could be as low as any negligible percent like 0.00000000000001%
        // In any case, it cannot be zero.
        require(lateInterestFeeWithTwoDecimals > 0 && latePrincipalFeeWithTwoDecimals > 0, "Late fee required");

        // State changes
        loanState = PREAPPROVED;
        _maintenanceCollateralRatio = maintenanceCollateralRatioWith2Decimals;
        lateInterestFee = lateInterestFeeWithTwoDecimals;
        latePrincipalFee = latePrincipalFeeWithTwoDecimals;

        emit OnLoanInitialized();
    }

    /**
     * @notice Changes the oracle that calculates token prices.
     * @dev Only the lender is allowed to call this function
     * @param newOracle The new oracle for token prices
     */
    function changeOracle (IBasicPriceOracle newOracle) public onlyLender {
        address prevAddr = priceOracle;
        require(prevAddr != address(newOracle), "Oracle already set");

        if (isSecured()) {
            // The lender cannot change the price oracle if the loan was called.
            // Otherwise the lender could force a liquidation of the loan 
            // by changing the maintenance collateral in order to game the borrower.
            require(callbackPeriod == 0, "Loan was called");
        }
         
        priceOracle = address(newOracle);
        emit OnPriceOracleChanged(prevAddr, priceOracle);
    }

    /**
     * @notice Updates the maintenance collateral ratio
     * @dev Only the lender is allowed to call this function
     * @param maintenanceCollateralRatioWith2Decimals The maintenance collateral ratio, if any.
     */
    function changeMaintenanceCollateralRatio (uint256 maintenanceCollateralRatioWith2Decimals) public onlyLender {
        // The maintenance ratio cannot be altered if the loan is unsecured
        require(isSecured(), "This loan is unsecured");

        // The maintenance ratio cannot be greater than the initial ratio
        require(maintenanceCollateralRatioWith2Decimals > 0, "Maintenance ratio required");
        require(maintenanceCollateralRatioWith2Decimals < _initialCollateralRatio, "Maintenance ratio too high");

        // The lender cannot change the maintenance ratio if the loan was called.
        // Otherwise the lender could force a liquidation of the loan 
        // by changing the maintenance collateral in order to game the borrower.
        require(callbackPeriod == 0, "Loan was called");
        require(_maintenanceCollateralRatio != maintenanceCollateralRatioWith2Decimals, "Value already set");

        _maintenanceCollateralRatio = maintenanceCollateralRatioWith2Decimals;
    }

    /**
     * @notice Updates the late fees
     * @dev Only the lender is allowed to call this function
     * @param lateInterestFeeWithTwoDecimals The late interest fee (percentage) with 2 decimal places.
     * @param latePrincipalFeeWithTwoDecimals The late principal fee (percentage) with 2 decimal places.
     */
    function changeLateFees (uint256 lateInterestFeeWithTwoDecimals, uint256 latePrincipalFeeWithTwoDecimals) public onlyLender {
        require(lateInterestFeeWithTwoDecimals > 0 && latePrincipalFeeWithTwoDecimals > 0, "Late fee required");
        require(callbackPeriod == 0, "Loan was called");

        lateInterestFee = lateInterestFeeWithTwoDecimals;
        latePrincipalFee = latePrincipalFeeWithTwoDecimals;
    }

    /**
     * @notice Allows the expected borrower to accept the loan offered by the lender.
     * @dev Only the borrower is allowed to call this function. The deposit amount is zero for unsecured loans.
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
     * @dev Only the lender is allowed to call this function. The loan must be funded within the time window specified. Otherwise, the borrower is allowed to claim their collateral.
     */
    function fundLoan () public onlyLender {
        require(loanState == FUNDING_REQUIRED, "Invalid loan state");

        uint256 ts = block.timestamp; // solhint-disable-line not-rely-on-time
        require(ts <= _fundingDeadline, "Funding period elapsed");

        // State changes
        loanState = FUNDED;
        fundedOn = ts;
        nextPaymentDate = ts + _paymentIntervalInSeconds;
        _remainingDebt = _getInitialDebt();

        // Fund the loan with the expected amount of principal tokens
        _depositToken(IERC20NonCompliant(principalToken), msg.sender, _effectiveLoanAmount);

        emit OnLoanFunded();
    }

    /**
     * @notice Withdraws the principal tokens of this loan.
     * @dev Only the borrower is allowed to call this function
     */
    function withdraw () public onlyBorrower {
        require(loanState == FUNDED, "Invalid loan state");

        // Enforce the maintenance collateral ratio, if applicable
        _enforceMaintenanceRatio();

        loanState = ACTIVE;

        // Send principal tokens to the borrower
        _withdrawPrincipalTokens(_effectiveLoanAmount, borrower);

        // Emit the event
        emit OnBorrowerWithdrawal(_effectiveLoanAmount);
    }

    /**
     * @notice Claims the amount of principal specified and sends the tokens to the lender.
     * @dev Only the lender is allowed to call this function
     * @param amount The number of principal tokens to withdraw from this contract
     */
    function claimPrincipal (uint56 amount) public onlyLender {
        require(loanState == ACTIVE, "Loan is not active");

        // Send principal tokens to the lender
        _withdrawPrincipalTokens(amount, lender);

        // Emit the event
        emit OnPrincipalClaimed(amount);
    }

    /**
     * @notice Claims the collateral deposited by the borrower
     * @dev Only the borrower is allowed to call this function
     */
    function claimCollateral () public onlyBorrower {
        require(isSecured(), "This loan is unsecured");
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
     * @notice Makes a repayment.
     * @dev Only the borrower is allowed to call this function
     * @param paymentAmountTokens The payment amount, expressed in tokens.
     */
    function repay (uint256 paymentAmountTokens) public onlyBorrower onlyIfActiveOrFunded onlyIfPendingDebt {
        // Checks
        require(paymentAmountTokens > 0, "Payment amount required");

        // Get the outstanding debt
        (, uint256 applicableLateFees, uint256 netDebtAmount) = getTotalDebt();
        
        // Enforce the maintenance collateral ratio, if applicable
        _enforceMaintenanceRatio();

        if (callbackPeriod == 0) {
            // The loan was not called yet
            require(paymentAmountTokens <= netDebtAmount, "Amount exceeds pending debt");

            uint256 ts = block.timestamp; // solhint-disable-line not-rely-on-time

            // Check the minimum payment amount
            uint256 minPaymentAmount = _getMinimumPaymentAmount(ts);
            require(paymentAmountTokens >= minPaymentAmount, "Minimum payment amount required");

            // Set the date of the next payment
            nextPaymentDate = calculateMaxPaymentDate(ts, fundedOn, _paymentIntervalInSeconds) + _paymentIntervalInSeconds;
        } else {
            // The loan was called
            require(paymentAmountTokens == netDebtAmount, "Outstanding amount expected");
        }

        // Decrease the remaining debt accordingly
        _remainingDebt -= (paymentAmountTokens - applicableLateFees);
        feesRepaid += applicableLateFees;

        // Determine if the loan can be closed prior making any external calls (check effect interactions)
        bool canCloseLoan = (_remainingDebt == 0);

        // Let the borrower repay their debt
        _depositToken(IERC20NonCompliant(principalToken), msg.sender, paymentAmountTokens);

        // Trigger the respective event
        emit OnRepayment(paymentAmountTokens);

        // Close the loan automatically, if applicable
        if (canCloseLoan) _closeLoan();
    }

    /**
     * @notice Calls the loan.
     * @dev Only the lender is allowed to call this function
     * @param callbackPeriodInHours The callback period, measured in hours.
     * @param gracePeriodInHours The grace period, measured in hours.
     */
    function callLoan (uint256 callbackPeriodInHours, uint256 gracePeriodInHours) public onlyLender onlyIfActiveOrFunded onlyIfPendingDebt {
        require(callbackPeriodInHours > 0, "Callback period required");
        require(gracePeriodInHours > 0, "Grace period required");
        require(callbackPeriod == 0, "Loan was called already");

        callbackPeriod = block.timestamp + callbackPeriodInHours * 1 hours; // solhint-disable-line not-rely-on-time
        gracePeriod = gracePeriodInHours * 1 hours;
        nextPaymentDate = callbackPeriod;

        emit OnLoanCalled(callbackPeriodInHours, gracePeriodInHours);
    }

    /**
     * @notice Liquidates the loan.
     * @dev Only the lender is allowed to call this function
     */
    function liquidate () public onlyLender onlyIfActiveOrFunded {
        require(callbackPeriod > 0, "Loan was not called yet");
        require(block.timestamp > callbackPeriod + gracePeriod, "Callback period not elapsed"); // solhint-disable-line not-rely-on-time

        // State changes
        loanState = MATURED;

        // Transfer the collateral to the lender. Transfer any remaining principal to the lender as well.
        _transferPrincipalAndCollateral(lender, lender);

        emit OnLoanMatured();
    }

    /**
     * @notice Gets the number of collateral tokens required to represent the amount of principal specified.
     * @param principalPrice The price of the principal token
     * @param principalQty The number of principal tokens
     * @param collateralPrice The price of the collateral token
     * @param collateralDecimals The decimal positions of the collateral token
     * @return Returns the number of collateral tokens
     */
    function fromTokenToToken (uint256 principalPrice, uint256 principalQty, uint256 collateralPrice, uint256 collateralDecimals) public pure returns (uint256) {
        return ((principalPrice * principalQty) / collateralPrice) * (10 ** (collateralDecimals - 6));
    }

    /**
     * @notice Calculates the next payment date based on the starting date and timestamp specified
     * @param currentUnixEpoch The current timestamp
     * @param startDate The starting date
     * @param intervalInSeconds The payment interval, expressed in seconds
     * @return Returns the next payment date
     */
    function calculateMaxPaymentDate (uint256 currentUnixEpoch, uint256 startDate, uint256 intervalInSeconds) public pure returns (uint256) {
        require(startDate > 0, "Start date required");
        if (currentUnixEpoch <= startDate) return startDate + intervalInSeconds;

        uint256 diffSeconds = currentUnixEpoch - startDate;
        uint256 billingCyclesElapsed = (diffSeconds % intervalInSeconds == 0) ? diffSeconds / intervalInSeconds : (diffSeconds / intervalInSeconds) + 1;
        return startDate + (billingCyclesElapsed * intervalInSeconds);
    }


    function calculateTotalDebt (uint256 ts, uint256 billingCycleExpiryDate, uint256 currentGrossDebt, uint256 cbPeriod, uint256 iFee, uint256 pFee) public pure returns (uint256 grossDebtAmount, uint256 applicableLateFees, uint256 netDebtAmount) {
        uint256 relativeDate = (cbPeriod > 0) ? cbPeriod : billingCycleExpiryDate;
        uint256 targetFee = (cbPeriod > 0) ? pFee : iFee;

        grossDebtAmount = currentGrossDebt;
        applicableLateFees = _getApplicableLateFee(ts, grossDebtAmount, relativeDate, targetFee);
        netDebtAmount = grossDebtAmount + applicableLateFees;
    }

    function calculateMinPaymentAmount (uint256 currentUnixEpoch, uint256 intervalInSeconds, uint256 billingCycleExpiryDate, uint256 fee, uint256 minRequiredAmount) public pure returns (uint256 billingCyclesMissed, uint256 newMinPaymentAmount) {
        if (billingCycleExpiryDate == 0 || currentUnixEpoch <= billingCycleExpiryDate) return (0, minRequiredAmount);

        uint256 diffSeconds = currentUnixEpoch - billingCycleExpiryDate;

        // The number of billing cycles missed so far
        billingCyclesMissed = (diffSeconds % intervalInSeconds == 0) ? diffSeconds / intervalInSeconds : (diffSeconds / intervalInSeconds) + 1;

        uint256 acum = 0;
        uint256 itemDate = billingCycleExpiryDate;

        for (uint256 x = 0; x < billingCyclesMissed; x++) {
            uint256 localDebt = minRequiredAmount + _getApplicableLateFee(currentUnixEpoch, minRequiredAmount, itemDate, fee);
            acum += localDebt;
            itemDate += intervalInSeconds;
        }

        newMinPaymentAmount = acum;
    }

    /**
     * @notice Indicates whether the loan is secured or not.
     * @return Returns true if the loan represents secured debt.
     */
    function isSecured () public view returns (bool) {
        return collateralToken != ZERO_ADDRESS;
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
     * @notice Gets the minimum payment amount
     * @return Returns the minimum payment amount
     */
    function getMinimumPaymentAmount () public view returns (uint256) {
        return _getMinimumPaymentAmount(block.timestamp); // solhint-disable-line not-rely-on-time
    }

    /**
     * @notice Gets the total debt, including any late fees.
     * @return grossDebtAmount The gross debt, without any fees at all
     * @return applicableLateFees The applicable late fees, if any
     * @return netDebtAmount The total payment amount, including any fees
     */
    function getTotalDebt () public view returns (uint256 grossDebtAmount, uint256 applicableLateFees, uint256 netDebtAmount) {
        uint256 ts = block.timestamp; // solhint-disable-line not-rely-on-time
        (grossDebtAmount, applicableLateFees, netDebtAmount) = calculateTotalDebt(ts, nextPaymentDate, _remainingDebt, callbackPeriod, lateInterestFee, latePrincipalFee);
    }

    function getLoanData () public view returns (uint256 maxWithdrawalAmount, uint256 fundingDeadline) {
        maxWithdrawalAmount = _effectiveLoanAmount;
        fundingDeadline = _fundingDeadline;
    }

    // Closes the loan
    function _closeLoan () private {
        // Update the state of the loan
        loanState = CLOSED;

        // Send the collateral back to the borrower, if applicable. Send any remaining the principal back to the lender.
        _transferPrincipalAndCollateral(borrower, lender);

        emit OnLoanClosed();
    }

    // Deposits a specific amount of tokens into this smart contract
    function _depositToken (IERC20NonCompliant tokenInterface, address senderAddr, uint256 depositAmount) private {
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

    // Transfers principal tokens to the recipient specified
    function _withdrawPrincipalTokens (uint256 amountInPrincipalTokens, address recipientAddr) private {
        // Check the balance of the contract
        IERC20NonCompliant principalTokenInterface = IERC20NonCompliant(principalToken);
        uint256 currentBalanceAtContract = principalTokenInterface.balanceOf(address(this));
        require(currentBalanceAtContract > 0 && currentBalanceAtContract >= amountInPrincipalTokens, "Insufficient balance");

        // Transfer the funds
        uint256 currentBalanceAtRecipient = principalTokenInterface.balanceOf(recipientAddr);
        uint256 newBalanceAtRecipient = currentBalanceAtRecipient + amountInPrincipalTokens;
        uint256 newBalanceAtContract = currentBalanceAtContract - amountInPrincipalTokens;

        principalTokenInterface.transfer(recipientAddr, amountInPrincipalTokens);

        require(principalTokenInterface.balanceOf(address(this)) == newBalanceAtContract, "Balance check failed");
        require(principalTokenInterface.balanceOf(recipientAddr) == newBalanceAtRecipient, "Transfer check failed");
    }

    function _transferPrincipalAndCollateral (address collateralRecipientAddr, address principalRecipientAddr) private {
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

    function _getApplicableLateFee (uint256 ts, uint256 amount, uint256 billingCycleExpiryDate, uint256 fee) private pure returns (uint256) {
        if (billingCycleExpiryDate == 0 || ts <= billingCycleExpiryDate) return 0;

        // Apply a late fee accordingly
        uint256 diffSeconds = ts - billingCycleExpiryDate;
        uint256 diffDays = (diffSeconds % 86400 == 0) ? diffSeconds / 86400 : (diffSeconds / 86400) + 1;
        uint256 dailyLateFee = amount * fee * 1 days / 1e4 / 365 days;
        return dailyLateFee * diffDays;
    }

    // Enforces the maintenance collateral ratio
    function _enforceMaintenanceRatio () private view {
        if (!isSecured()) return;

        // This is the amount of collateral tokens the borrower is required to maintain.
        uint256 expectedCollatAmount = getMaintenanceCollateralAmount();

        IERC20NonCompliant collateralTokenInterface = IERC20NonCompliant(collateralToken);
        require(collateralTokenInterface.balanceOf(address(this)) >= expectedCollatAmount, "Insufficient maintenance ratio");
    }

    function _getInitialDebt () private view returns (uint256) {
        uint256 applicableInterest = _loanAmountInPrincipalTokens * apr * _paymentIntervalInSeconds / 1e4 / 365 days;
        require(applicableInterest > 0, "Invalid applicable interest");
        return _loanAmountInPrincipalTokens + applicableInterest;
    }

    function _getMinimumPaymentAmount (uint256 ts) private view returns (uint256) {
        uint256 minInterestsPayment = _loanAmountInPrincipalTokens * apr * _paymentIntervalInSeconds / 1e4 / 365 days;

        (, uint256 newMinPaymentAmount) = calculateMinPaymentAmount(ts, _paymentIntervalInSeconds, nextPaymentDate, lateInterestFee, minInterestsPayment);
        return newMinPaymentAmount;
    }

    function _getCollateralAmount (uint256 collatRatio) private view returns (uint256) {
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
}