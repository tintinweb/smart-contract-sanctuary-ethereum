/**
 *Submitted for verification at Etherscan.io on 2022-09-27
*/

// SPDX-License-Identifier: BUSL-1.1
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
contract Loan {
    // ---------------------------------------------------------------
    // States of a loan
    // ---------------------------------------------------------------
    uint8 constant private INACTIVE = 0;           // The loan is inactive
    uint8 constant private PREAPPROVED = 1;        // The loan was pre-approved by the lender
    uint8 constant private FUNDING_REQUIRED = 2;   // The loan was accepted by the borrower. Waiting for the lender to fund the loan.
    uint8 constant private FUNDED = 3;             // The loan was funded.
    uint8 constant private ACTIVE = 4;             // The loan is active.
    uint8 constant private CANCELLED = 5;          // The lender failed to fund the loan and the borrower claimed their collateral.
    uint8 constant private MATURED = 6;            // The loan matured. It was liquidated by the lender.
    uint8 constant private CLOSED = 7;             // The loan was closed normally.

    // ---------------------------------------------------------------
    // Other constants
    // ---------------------------------------------------------------
    // The zero address
    address constant private ZERO_ADDRESS = address(0);

    // The minimum payment interval, expressed in seconds
    uint256 constant private MIN_PAYMENT_INTERVAL = 3 hours;

    // ---------------------------------------------------------------
    // Tightly packed state
    // ---------------------------------------------------------------
    /**
     * @notice The late interests fee, as a percentage with 2 decimal places.
     */
    uint256 public lateInterestFee = uint256(30000);

    /**
     * @notice The late principal fee, as a percentage with 2 decimal places.
     */
    uint256 public latePrincipalFee = uint256(40000);

    /**
     * @notice The callback deadline. It is non-zero as soon as the loan gets called.
     */
    uint256 public callbackDeadline;

    /**
     * @notice The date in which the loan was funded by the lender.
     */
    uint256 public fundedOn;

    /**
     * @notice The amount of interests repaid so far
     */
    uint256 public interestsRepaid;

    /**
     * @notice The amount of principal repaid so far
     */
    uint256 public principalRepaid;

    /**
     * @notice The funding deadline. The lender is required to fund the principal before this exact point in time.
     */
    uint256 public fundingDeadline;

    /**
     * @notice The APR of the loan.
     */
    uint256 public immutable apr;

    /**
     * @notice The funding period, expressed in seconds.
     */
    uint256 public immutable fundingPeriod;

    // The loan amount, expressed in principal tokens.
    uint256 private immutable _loanAmountInPrincipalTokens;

    // The effective loan amount
    uint256 private immutable _effectiveLoanAmount;

    // The payment interval, expressed in seconds.
    uint256 private immutable _paymentIntervalInSeconds;

    // The initial collateral ratio, with 2 decimal places. It is zero for unsecured debt.
    uint256 private immutable _initialCollateralRatio;

    // The maintenance collateral ratio, with 2 decimal places. It is zero for unsecured debt.
    uint256 private _maintenanceCollateralRatio;

    /**
     * @notice The oracle for calculating token prices.
     */
    address public priceOracle;

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
     * @notice The current state of the loan
     */
    uint8 public loanState;


    // ---------------------------------------------------------------
    // Events
    // ---------------------------------------------------------------
    /**
     * @notice This event is triggered when the borrower accepts a loan.
     */
    event OnBorrowerCommitment();

    /**
     * @notice This event is triggered when the lender funds the loan.
     */
    event OnLoanFunded();

    /**
     * @notice This event is triggered when the borrower claimed their collateral.
     */
    event OnCollateralClaimed();

    event OnPrincipalClaimed(uint256 numberOfTokens);
    event OnPriceOracleChanged(address prevAddress, address newAddress);
    event OnBorrowerWithdrawal (uint256 numberOfTokens);
    event OnLoanCalled (uint256 callbackPeriodInDays, uint256 gracePeriodInDays);
    event OnInterestsRepayment (uint256 paymentAmountTokens);
    event OnPrincipalRepayment (uint256 paymentAmountTokens);

    /**
     * @notice This event is triggered when the loan gets closed.
     */
    event OnLoanClosed();

    /**
     * @notice This event is triggered when the loan is matured.
     */
    event OnLoanMatured();

    // ---------------------------------------------------------------
    // Constructor
    // ---------------------------------------------------------------
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
        uint256 initialCollateralRatioWith2Decimals,
        uint256 maintenanceCollateralRatioWith2Decimals
    ) {
        // Checks
        require(lenderAddr != ZERO_ADDRESS, "Invalid lender");
        require(borrowerAddr != lenderAddr, "Invalid borrower");
        require(fundingPeriodInDays > 0, "Invalid funding period");
        require(loanAmountInPrincipalTokens > 0, "Invalid loan amount");
        require(newAprWithTwoDecimals > 0, "Invalid APR");

        // The minimum payment interval is 3 hours
        require(newPaymentIntervalInSeconds >= MIN_PAYMENT_INTERVAL, "Payment interval too short");

        // Check the collateralization ratio
        if (newCollateralToken == ZERO_ADDRESS) {
            // Unsecured loan
            require(initialCollateralRatioWith2Decimals == 0, "Invalid initial collateral");
            require(maintenanceCollateralRatioWith2Decimals == 0, "Invalid maintenance ratio");
        } else {
            // Secured loan
            require(initialCollateralRatioWith2Decimals > 0 && initialCollateralRatioWith2Decimals <= 12000, "Invalid initial collateral");

            // The maintenance ratio must be lower than the initial collateral ratio
            require(maintenanceCollateralRatioWith2Decimals > 0, "Maintenance ratio required");
            require(maintenanceCollateralRatioWith2Decimals < initialCollateralRatioWith2Decimals, "Maintenance ratio too high");
        }

        // State changes (immutable)
        lender = lenderAddr;
        borrower = borrowerAddr;
        principalToken = address(newPrincipalToken);
        collateralToken = newCollateralToken;
        fundingPeriod = fundingPeriodInDays * 1 days;
        apr = newAprWithTwoDecimals;
        _paymentIntervalInSeconds = newPaymentIntervalInSeconds;
        _loanAmountInPrincipalTokens = loanAmountInPrincipalTokens;
        _initialCollateralRatio = initialCollateralRatioWith2Decimals;
        _effectiveLoanAmount = loanAmountInPrincipalTokens - (loanAmountInPrincipalTokens * originationFeePercent2Decimals / 1e4);

        // State changes (volatile)
        _maintenanceCollateralRatio = maintenanceCollateralRatioWith2Decimals;
        priceOracle = address(newOracle);
        loanState = PREAPPROVED;
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

    // ---------------------------------------------------------------
    // Functions
    // ---------------------------------------------------------------
    /**
     * @notice Updates the late fees
     * @dev Only the lender is allowed to call this function. As a lender, you cannot change the fees if the loan was called.
     * @param lateInterestFeeWithTwoDecimals The late interest fee (percentage) with 2 decimal places.
     * @param latePrincipalFeeWithTwoDecimals The late principal fee (percentage) with 2 decimal places.
     */
    function changeLateFees (uint256 lateInterestFeeWithTwoDecimals, uint256 latePrincipalFeeWithTwoDecimals) public onlyLender {
        require(lateInterestFeeWithTwoDecimals > 0 && latePrincipalFeeWithTwoDecimals > 0, "Late fee required");
        require(callbackDeadline == 0, "Loan was called");

        lateInterestFee = lateInterestFeeWithTwoDecimals;
        latePrincipalFee = latePrincipalFeeWithTwoDecimals;
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
            require(callbackDeadline == 0, "Loan was called");
        }

        priceOracle = address(newOracle);
        emit OnPriceOracleChanged(prevAddr, priceOracle);
    }

    /**
     * @notice Updates the maintenance collateral ratio
     * @dev Only the lender is allowed to call this function. As a lender, you cannot change the maintenance collateralization ratio if the loan was called.
     * @param maintenanceCollateralRatioWith2Decimals The maintenance collateral ratio, if applicable.
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
        require(callbackDeadline == 0, "Loan was called");
        require(_maintenanceCollateralRatio != maintenanceCollateralRatioWith2Decimals, "Value already set");

        _maintenanceCollateralRatio = maintenanceCollateralRatioWith2Decimals;
    }

    /**
     * @notice Allows the borrower to accept the loan offered by the lender.
     * @dev Only the borrower is allowed to call this function. The deposit amount is zero for unsecured loans.
     */
    function borrowerCommitment () public onlyBorrower {
        // Checks
        require(loanState == PREAPPROVED, "Invalid loan state");

        // Update the state of the loan
        loanState = FUNDING_REQUIRED;

        // Set the deadline for funding the principal
        fundingDeadline = block.timestamp + fundingPeriod; // solhint-disable-line not-rely-on-time

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
        require(ts <= fundingDeadline, "Funding period elapsed");

        // State changes
        loanState = FUNDED;
        fundedOn = ts;

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
     * @notice Claims the principal available at the contract. Sends the principal tokens to the lender.
     * @dev Only the lender is allowed to call this function
     */
    function claimPrincipal () public onlyLender {
        require(loanState == ACTIVE, "Loan is not active");

        IERC20NonCompliant principalTokenInterface = IERC20NonCompliant(principalToken);
        uint256 currentBalanceAtContract = principalTokenInterface.balanceOf(address(this));
        require(currentBalanceAtContract > 0, "No principal to claim");

        // Send principal tokens to the lender
        _withdrawPrincipalTokens(currentBalanceAtContract, lender);

        // Emit the event
        emit OnPrincipalClaimed(currentBalanceAtContract);
    }

    /**
     * @notice Claims the collateral deposited by the borrower
     * @dev Only the borrower is allowed to call this function
     */
    function claimCollateral () public onlyBorrower {
        require(isSecured(), "This loan is unsecured");
        require(loanState == FUNDING_REQUIRED, "Invalid loan state");
        require(block.timestamp > fundingDeadline, "Funding period not elapsed"); // solhint-disable-line not-rely-on-time

        loanState = CANCELLED;
        emit OnCollateralClaimed();

        IERC20NonCompliant collateralTokenInterface = IERC20NonCompliant(collateralToken);
        uint256 currentBalance = collateralTokenInterface.balanceOf(address(this));
        collateralTokenInterface.transfer(borrower, currentBalance);
        require(collateralTokenInterface.balanceOf(address(this)) == 0, "Collateral transfer failed");
    }

    /**
     * @notice Gets the current debt.
     * @param interestDebtAmount The interest owed by the borrower at this point in time.
     * @param grossDebtAmount xyz
     * @param principalDebtAmount The amount of principal owed by the borrower at this point in time.
     * @param interestOwed xyz
     * @param applicableLateFee The late fee(s) applied at the current point in time.
     * @param netDebtAmount xyz
     * @param daysSinceFunding The number of days that elapsed since the loan was funded.
     * @param currentBillingCycle The current billing cycle (aka: payment interval).
     * @param minPaymentAmount The minimum payment amount to submit in order to repay your debt, at any point in time, including late fees.
     * @param maxNextPaymentDate The date of your next repayment as a borrower, for informational purposes only.
     */
    function getDebt () public view returns (
        uint256 interestDebtAmount, 
        uint256 grossDebtAmount, 
        uint256 principalDebtAmount, 
        uint256 interestOwed, 
        uint256 applicableLateFee, 
        uint256 netDebtAmount, 
        uint256 daysSinceFunding, 
        uint256 currentBillingCycle,
        uint256 minPaymentAmount,
        uint256 maxNextPaymentDate
    ) {
        // If the loan hasn't been funded then the current debt is zero because no funds were delivered to the borrower
        if (fundedOn == 0) return (0, 0, 0, 0, 0, 0, 0, 0, 0, 0);

        uint256 ts = block.timestamp; // solhint-disable-line not-rely-on-time
        uint256 diffSeconds = ts - fundedOn;
        currentBillingCycle = (diffSeconds < _paymentIntervalInSeconds) ? 1 : ((diffSeconds % _paymentIntervalInSeconds == 0) ? diffSeconds / _paymentIntervalInSeconds : (diffSeconds / _paymentIntervalInSeconds) + 1);
        daysSinceFunding = (diffSeconds < 86400) ? 1 : ((diffSeconds % 86400 == 0) ? diffSeconds / 86400 : (diffSeconds / 86400) + 1);
        principalDebtAmount = _loanAmountInPrincipalTokens - principalRepaid;

        // The date of the next payment, for the sake of transparency
        maxNextPaymentDate = fundedOn + currentBillingCycle * _paymentIntervalInSeconds;

        if (principalDebtAmount > 0) {
            interestDebtAmount = _loanAmountInPrincipalTokens * apr * daysSinceFunding / 365 / 1e4;
            require(interestDebtAmount > 0, "Interest debt cannot be zero");

            require(_loanAmountInPrincipalTokens + interestDebtAmount >= principalRepaid, "Invalid gross debt");
            grossDebtAmount = _loanAmountInPrincipalTokens + interestDebtAmount - principalRepaid;

            uint256 minInterestAmount = principalDebtAmount * apr * _paymentIntervalInSeconds / 365 days / 1e4;
            require(minInterestAmount > 0, "Invalid min interest amount");

            uint256 x = currentBillingCycle * minInterestAmount;
            interestOwed = (x > interestsRepaid) ? x - interestsRepaid : uint256(0);

            if (interestOwed > 0) {
                if ((callbackDeadline > 0) && (ts > callbackDeadline)) {
                    // The loan was called and the deadline elapsed (callback period + grace period)
                    applicableLateFee = grossDebtAmount * latePrincipalFee / 365 / 1e4;
                } else {
                    // The loan might have been called. In any case, you are still within the grace period so the principal fee does not apply
                    uint256 delta = (interestOwed > minInterestAmount) ? interestOwed - minInterestAmount : uint256(0);
                    applicableLateFee = delta * lateInterestFee / 365 / 1e4;
                }
            }

            require(grossDebtAmount + applicableLateFee >= interestsRepaid, "N3");
            netDebtAmount = grossDebtAmount + applicableLateFee - interestsRepaid;

            // The minimum payment amount to be deposited by the borrower, at any time, including all late fees.
            minPaymentAmount = callbackDeadline > 0 ? netDebtAmount : interestOwed + applicableLateFee;
        }
    }

    /**
     * @notice Repays the interests only.
     */
    function repayInterests () public onlyBorrower onlyIfActiveOrFunded {
        // Make sure the loan hasn't been called
        require(callbackDeadline == 0, "Loan was called");

        // Enforce the maintenance collateral ratio, if applicable
        _enforceMaintenanceRatio();

        // Get the current debt
        (, , , uint256 interestOwed, , , , , uint256 minPaymentAmount, ) = getDebt();
        require(interestOwed > 0, "No interests owed");

        // State changes
        interestsRepaid += interestOwed;
        emit OnInterestsRepayment(minPaymentAmount);
        _depositToken(IERC20NonCompliant(principalToken), msg.sender, minPaymentAmount);
    }

    /**
     * @notice Repays the principal portion of the loan.
     * @param paymentAmountInTokens The payment amount, expressed in principal tokens.
     */
    function repayPrincipal (uint256 paymentAmountInTokens) public onlyBorrower onlyIfActiveOrFunded {
        // Checks
        require(paymentAmountInTokens > 0, "Payment amount required");

        // Enforce the maintenance collateral ratio, if applicable
        _enforceMaintenanceRatio();

        // Get the current debt
        (, , uint256 principalDebtAmount, , , uint256 netDebtAmount, , , ,) = getDebt();

        // If the loan was called then the borrower is required to repay the net debt amount
        if (callbackDeadline > 0) require(paymentAmountInTokens == netDebtAmount, "Full payment expected");

        // If the loan was not called then the borrower can repay any principal amount of their preference 
        // as long as it does not exceed the net debt
        //require(paymentAmountInTokens <= netDebtAmount, "Amount exceeds net debt");

        // State changes
        uint256 delta = (paymentAmountInTokens <= principalDebtAmount) ? paymentAmountInTokens : principalDebtAmount;
        principalRepaid += delta;

        /*
        if (paymentAmountInTokens <= principalDebtAmount) {
            principalRepaid += paymentAmountInTokens;
        } else {
            principalRepaid += principalDebtAmount;
            require(principalRepaid == _loanAmountInPrincipalTokens, "Z3");
        }
        */

        emit OnPrincipalRepayment(paymentAmountInTokens);
        _depositToken(IERC20NonCompliant(principalToken), msg.sender, paymentAmountInTokens);
    }

    /**
     * @notice Calls the loan.
     * @dev Only the lender is allowed to call this function
     * @param callbackPeriodInHours The callback period, measured in hours.
     * @param gracePeriodInHours The grace period, measured in hours.
     */
    function callLoan (uint256 callbackPeriodInHours, uint256 gracePeriodInHours) public onlyLender onlyIfActiveOrFunded {
        require(callbackPeriodInHours > 0, "Callback period required");
        require(gracePeriodInHours > 0, "Grace period required");
        require(callbackDeadline == 0, "Loan was called already");

        callbackDeadline = (block.timestamp + callbackPeriodInHours * 1 hours) + (gracePeriodInHours * 1 hours); // solhint-disable-line not-rely-on-time

        emit OnLoanCalled(callbackPeriodInHours, gracePeriodInHours);
    }

    /**
     * @notice Liquidates the loan.
     * @dev Only the lender is allowed to call this function
     */
    function liquidate () public onlyLender onlyIfActiveOrFunded {
        require(callbackDeadline > 0, "Loan was not called yet");
        require(block.timestamp > callbackDeadline, "Callback period not elapsed"); // solhint-disable-line not-rely-on-time

        // State changes
        loanState = MATURED;

        // Transfer the collateral to the lender. Transfer any remaining principal to the lender as well.
        _transferPrincipalAndCollateral(lender, lender);

        emit OnLoanMatured();
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


    // ---------------------------------------------------------------
    // Views
    // ---------------------------------------------------------------
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

    // Enforces the maintenance collateral ratio
    function _enforceMaintenanceRatio () private view {
        if (!isSecured()) return;

        // This is the amount of collateral tokens the borrower is required to maintain.
        uint256 expectedCollatAmount = getMaintenanceCollateralAmount();

        IERC20NonCompliant collateralTokenInterface = IERC20NonCompliant(collateralToken);
        require(collateralTokenInterface.balanceOf(address(this)) >= expectedCollatAmount, "Insufficient maintenance ratio");
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