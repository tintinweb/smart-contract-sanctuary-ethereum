// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IERC721, IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";

import "./interfaces/IReceivable.sol";
import "./BaseCreditPool.sol";
import "./ReceivableFactoringPoolStorage.sol";

import "./Errors.sol";

/**
 * @notice Receivable Factoring is the process for the receivable owner to trade in their
 * receivable for immediate access to portion of the fund tied with the receivable, and
 * receive the remainder after the receivable is paid in full.
 */
contract ReceivableFactoringPool is
    IReceivable,
    BaseCreditPool,
    ReceivableFactoringPoolStorage,
    IERC721Receiver
{
    using SafeERC20 for IERC20;
    using ERC165Checker for address;

    event ReceivedPaymentProcessed(
        address indexed sender,
        address indexed borrower,
        uint256 amount,
        bytes32 paymentIdHash
    );
    event ExtraFundsDispersed(address indexed receiver, uint256 amount);
    event PaymentInvalidated(bytes32 paymentIdHash);
    event DrawdownMadeWithReceivable(
        address indexed borrower,
        uint256 borrowAmount,
        uint256 netAmountToBorrower,
        address receivableAsset,
        uint256 receivableParam
    );
    event PaymentFlaggedForReview(
        bytes32 indexed paymentIdHash,
        address indexed borrower,
        uint256 amount
    );

    /**
     * @notice After the EA (EvalutionAgent) has approved a factoring, it calls this function
     * to record the approval on chain and mark as factoring as approved, which will enable
     * the borrower to drawdown (borrow) from the approved credit.
     * @param borrower the borrower address
     * @param creditLimit the limit of the credit
     * @param receivableAsset the receivable asset used for this credit
     * @param receivableParam additional parameter of the receivable asset, e.g. NFT tokenid
     * @param receivableAmount amount of the receivable asset
     * @param intervalInDays time interval for each payback in units of days
     * @param remainingPeriods the number of pay periods for this credit
     * @dev Only Evaluation Agents for this contract can call this function.
     */
    function approveCredit(
        address borrower,
        uint256 creditLimit,
        uint256 intervalInDays,
        uint256 remainingPeriods,
        uint256 aprInBps,
        address receivableAsset,
        uint256 receivableParam,
        uint256 receivableAmount
    ) external virtual override(IReceivable) {
        onlyEAServiceAccount();

        _checkReceivableRequirement(creditLimit, receivableAmount);

        // Populates fields related to receivable
        if (receivableAsset == address(0)) revert Errors.zeroAddressProvided();

        _setReceivableInfo(borrower, receivableAsset, receivableParam, receivableAmount);

        // Pool status and data validation happens within initiate().
        _initiateCredit(borrower, creditLimit, aprInBps, intervalInDays, remainingPeriods, true);
    }

    /**
     * @notice changes the limit of the borrower's credit line.
     * @dev The credit line is marked as Deleted if 1) the new credit line is 0 and
     * 2) there is no due or unbilled principals.
     * @param borrower the owner of the credit line
     * @param newCreditLimit the new limit of the line in the unit of pool token
     * @dev only Evaluation Agent can call
     */
    function changeCreditLine(address borrower, uint256 newCreditLimit) public virtual override {
        _checkReceivableAssetFor(borrower, newCreditLimit);
        super.changeCreditLine(borrower, newCreditLimit);
    }

    /**
     * @notice Drawdown function is disabled for this contract intentionally.
     * drawdownWithReceivable() should be used instead.
     */
    function drawdown(
        uint256 /*borrowAmount*/
    ) external virtual override {
        /// Intentional empty implementation to disable this function.
        revert Errors.drawdownFunctionUsedInsteadofDrawdownWithReceivable();
    }

    //      * @param receivableAsset the contract address of the receivable
    //  * @param receivableParam is additional parameter of the receivable asset. For ERC721,
    //  * it is tokenId; for ERC20, it is the quantity of the asset

    function drawdownWithReceivable(
        uint256 borrowAmount,
        address receivableAsset,
        uint256 receivableParam
    ) external virtual override {
        address borrower = msg.sender;
        BS.CreditRecord memory cr = _getCreditRecord(borrower);
        super._checkDrawdownEligibility(borrower, cr, borrowAmount);

        if (receivableAsset == address(0)) revert Errors.zeroAddressProvided();

        if (cr.state != BS.CreditState.Approved) revert Errors.creditLineNotInApprovedState();

        _transferReceivableAsset(borrower, receivableAsset, receivableParam);

        uint256 netAmountToBorrower = super._drawdown(borrower, cr, borrowAmount);
        emit DrawdownMadeWithReceivable(
            borrower,
            borrowAmount,
            netAmountToBorrower,
            receivableAsset,
            receivableParam
        );
    }

    /**
     * @notice Used by the PDS service account to invalidate a payment and stop automatic
     * processing services like subgraph from ingesting this payment.
     * This will be called manually by the pool owner in extremely rare situations
     * when an SDK bug or payment reaches an invalid state and bookkeeping must be
     * manually made by the pool owners.
     */
    function markPaymentInvalid(bytes32 paymentIdHash) external {
        onlyPDSServiceAccount();
        _markPaymentInvalid(paymentIdHash);
    }

    function onERC721Received(
        address, /*operator*/
        address, /*from*/
        uint256, /*tokenId*/
        bytes calldata /*data*/
    ) external virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /**
     * @notice Borrower makes one payment. If this is the final payment,
     * it automatically triggers the payoff process.
     *
     */
    function onReceivedPayment(
        address borrower,
        uint256 amount,
        bytes32 paymentIdHash
    ) external virtual override {
        onlyPDSServiceAccount();
        _processReceivedPayment(
            borrower,
            amount,
            paymentIdHash,
            BS.PaymentStatus.ReceivedNotVerified
        );
    }

    function processPaymentAfterReview(bytes32 paymentIdHash, bool approved) external {
        _poolConfig.onlyPoolOwner(msg.sender);
        BS.FlagedPaymentRecord memory fpr = _paymentsToBeReviewed[paymentIdHash];

        if (fpr.paymentReceiver == address(0)) revert Errors.paymentIdNotUnderReview();

        delete _paymentsToBeReviewed[paymentIdHash];
        if (!approved) {
            _markPaymentInvalid(paymentIdHash);
        } else {
            _processReceivedPayment(
                fpr.paymentReceiver,
                fpr.amount,
                paymentIdHash,
                BS.PaymentStatus.ReceivedAndVerified
            );
        }
    }

    function isPaymentProcessed(bytes32 paymentIdHash)
        external
        view
        virtual
        override
        returns (bool)
    {
        return _processedPaymentIds[paymentIdHash];
    }

    function isPaymentUnderReview(bytes32 paymentIdHash) external view returns (bool) {
        BS.FlagedPaymentRecord memory fpr = _paymentsToBeReviewed[paymentIdHash];
        return fpr.paymentReceiver != address(0);
    }

    function receivableInfoMapping(address account)
        external
        view
        returns (BS.ReceivableInfo memory)
    {
        return _receivableInfoMapping[account];
    }

    function receivableOwnershipMapping(bytes32 receivableHash) external view returns (address) {
        return _receivableOwnershipMapping[receivableHash];
    }

    /**
     * @notice disburse the remaining funds associated with the factoring to the borrower
     * @param receiver receiver of the funds, namely, the borrower
     * @param amount the amount of the dispursement
     */
    function _disburseRemainingFunds(address receiver, uint256 amount) internal {
        _underlyingToken.safeTransfer(receiver, amount);
        emit ExtraFundsDispersed(receiver, amount);
    }

    function _flagForReview(
        bytes32 paymentIdHash,
        address borrower,
        uint256 amount
    ) internal {
        _paymentsToBeReviewed[paymentIdHash] = BS.FlagedPaymentRecord(borrower, amount);
        emit PaymentFlaggedForReview(paymentIdHash, borrower, amount);
    }

    function _markPaymentInvalid(bytes32 paymentIdHash) internal {
        _processedPaymentIds[paymentIdHash] = true;
        emit PaymentInvalidated(paymentIdHash);
    }

    function _processReceivedPayment(
        address borrower,
        uint256 amount,
        bytes32 paymentIdHash,
        BS.PaymentStatus paymentStatus
    ) internal {
        _protocolAndPoolOn();
        // Makes sure no repeated processing of a payment.
        if (_processedPaymentIds[paymentIdHash]) revert Errors.paymentAlreadyProcessed();

        (uint256 amountPaid, bool paidoff, bool toReview) = _makePayment(
            borrower,
            amount,
            paymentStatus
        );

        if (!toReview) {
            _processedPaymentIds[paymentIdHash] = true;

            if (amount > amountPaid) _disburseRemainingFunds(borrower, amount - amountPaid);

            // Removes the receivable information for the borrower.
            if (paidoff) _setReceivableInfo(borrower, address(0), 0, 0);

            emit ReceivedPaymentProcessed(msg.sender, borrower, amount, paymentIdHash);
        } else {
            _flagForReview(paymentIdHash, borrower, amount);
        }
    }

    /**
     * @notice Sets the receivable asset for the borrower
     */
    function _setReceivableInfo(
        address borrower,
        address receivableAsset,
        uint256 receivableParam,
        uint256 receivableAmount
    ) internal virtual {
        // If receivables are required, they need to be ERC721 or ERC20.
        if (
            receivableAsset != address(0) &&
            !receivableAsset.supportsInterface(type(IERC721).interfaceId) &&
            !receivableAsset.supportsInterface(type(IERC20).interfaceId)
        ) revert Errors.unsupportedReceivableAsset();

        BS.ReceivableInfo memory ri = BS.ReceivableInfo(
            receivableAsset,
            uint88(receivableAmount),
            receivableParam
        );
        _receivableInfoMapping[borrower] = ri;
    }

    /**
     * @notice Transfers the backing asset for the credit line. The BaseCreditPool does not
     * require backing asset, thus empty implementation. The extended contracts can
     * support various backing assets, such as receivables, ERC721, and ERC20.
     * @param borrower the borrower
     * @param receivableAsset the contract address of the receivable asset.
     * @param receivableParam parameter of the receivable asset.
     */
    function _transferReceivableAsset(
        address borrower,
        address receivableAsset,
        uint256 receivableParam
    ) internal virtual {
        // Transfer receivable asset.
        BS.ReceivableInfo memory ri = _receivableInfoMapping[borrower];

        assert(ri.receivableAsset != address(0));

        if (receivableAsset != ri.receivableAsset) revert Errors.receivableAssetMismatch();
        if (receivableAsset.supportsInterface(type(IERC721).interfaceId)) {
            // Store a keccak256 hash of the receivableAsset and receivableParam on-chain
            // for lookup by off-chain payment processers
            _receivableOwnershipMapping[
                keccak256(abi.encode(receivableAsset, receivableParam))
            ] = borrower;

            // For ERC721, receivableParam is the tokenId
            if (ri.receivableParam != receivableParam)
                revert Errors.receivableAssetParamMismatch();

            IERC721(receivableAsset).safeTransferFrom(borrower, address(this), receivableParam);
        } else {
            // This has to be ERC20
            if (receivableParam < ri.receivableParam) revert Errors.insufficientReceivableAmount();

            IERC20(receivableAsset).safeTransferFrom(borrower, address(this), receivableParam);
        }
    }

    /**
     * @notice Checks if the borrower has enough receivable to back the requested credit line.
     * @param borrower the borrower address
     * @param newCreditLimit the credit limit requested
     */
    function _checkReceivableAssetFor(address borrower, uint256 newCreditLimit)
        internal
        view
        virtual
    {
        // Checks to make sure the receivable value satisfies the requirement
        assert(_receivableInfoMapping[borrower].receivableAsset != address(0));
        _checkReceivableRequirement(
            newCreditLimit,
            _receivableInfoMapping[borrower].receivableAmount
        );
    }

    /**
     * @notice Checks if the receivable provided is able fulfill the receivable requirement
     * for the requested credit line.
     * @param creditLine the credit limit requested
     * @param receivableAmount the value of the receivable
     */
    function _checkReceivableRequirement(uint256 creditLine, uint256 receivableAmount)
        internal
        view
    {
        if (
            receivableAmount <
            (creditLine * _poolConfig.receivableRequiredInBps()) / HUNDRED_PERCENT_IN_BPS
        ) revert Errors.insufficientReceivableAmount();
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

contract Errors {
    // common
    error sameValue(); // 0x0811ff09
    error zeroAddressProvided(); // 0x5ff75ab0
    error zeroAmountProvided(); // 0x71799f2a
    error amountTooLow(); // 0x5b05bfbf
    error invalidBasisPointHigherThan10000(); // 0x07982d85
    error withdrawnAmountHigherThanBalance(); // 0x477c0ab2

    // security
    error permissionDeniedNotAdmin(); // 0xf2c5b6a7
    error permissionDeniedNotLender(); // 0x68299b20
    error evaluationAgentServiceAccountRequired(); // 0x9b3b1ed6
    error paymentDetectionServiceAccountRequired(); // 0x731b978f
    error poolOperatorRequired(); // 0xdc2dc6d0
    error notPoolOwner(); // 0xd39208c9
    error notProtocolOwner(); // 0x97924c20
    error notEvaluationAgent(); // 0x66f7b8b7
    error notOperator(); // 0xf67113fe
    error notPoolOwnerTreasury(); // 0x325bf3c2
    error notPoolOwnerOrEA(); // 0xd6ed9384
    error notPoolOwnerTreasuryOrEA(); // 0xc74cb44c
    error notPauser(); // 0xdcdea7c8
    error notPool(); // 0x26d29bbf
    error drawdownFunctionUsedInsteadofDrawdownWithReceivable(); // 0x7e737537
    error notNFTOwner(); // 0x091a5762

    // system config
    error defaultGracePeriodLessThanMinAllowed(); // 0xa733ff9c
    error treasuryFeeHighThanUpperLimit(); // 0x39cda0d1
    error alreadyAnOperator(); // 0x75cea0fc
    error alreadyAPauser(); // 0xfbca9e38
    error alreadyPoolAdmin(); // 0x7bb356e2

    // fee config
    error minPrincipalPaymentRateSettingTooHigh(); // 0xc11fc042

    // pool config
    error proposedEADoesNotOwnProvidedEANFT(); // 0x75b0da3b
    error underlyingTokenNotApprovedForHumaProtocol(); // 0xce179d6d
    error poolOwnerNotEnoughLiquidity(); // 0xe95282e2
    error evaluationAgentNotEnoughLiquidity(); // 0x67e26217

    // pool state
    error protocolIsPaused(); // 0x8f6fa2d4
    error poolIsNotOn(); // 0x69b355df

    // pool credit line
    error creditExpiredDueToFirstDrawdownTooLate(); // 0x9fac7390
    error creditExpiredDueToMaturity(); // 0xa52f3c3f
    error creditLineNotInGoodStandingState(); // 0x96e79474
    error creditLineNotInStateForMakingPayment(); // 0xf023e48b
    error creditLineNotInStateForDrawdown(); // 0x4ff95a6d
    error creditLineExceeded(); // 0xef7d66ff
    error creditLineAlreadyExists(); // 0x6c5805f2
    error creditLineGreatThanUpperLimit(); // 0xd8c27d2f
    error greaterThanMaxCreditLine(); // 0x8a754ae8
    error requestedCreditWithZeroDuration(); // 0xb16dd34d
    error onlyBorrowerOrEACanReduceCreditLine(); // 0xd61dbe31
    error creditLineNotInApprovedState(); // 0xfc91a989
    error paymentIdNotUnderReview(); // 0xd1696aaa
    error creditLineTooHigh(); // 0x552b8377

    // pool operation
    error exceededPoolLiquidityCap(); // 0x5642ebd4
    error receivableAssetMismatch(); // 0x41dbeec1
    error unsupportedReceivableAsset(); // 0xe60c383e
    error receivableAssetParamMismatch(); // 0x1400a0b4
    error insufficientReceivableAmount(); // 0xf7f34854
    error borrowingAmountLessThanPlatformFees(); // 0x97fde118
    error withdrawTooSoon(); // 0x67982472
    error paymentAlreadyProcessed(); // 0xfd6754cf

    error defaultTriggeredTooEarly(); // 0x7872424e
    error defaultHasAlreadyBeenTriggered(); // 0xeb8d2ccc
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "./interfaces/ICredit.sol";

import "./BasePool.sol";
import "./BaseCreditPoolStorage.sol";
import "./Errors.sol";

import "hardhat/console.sol";

/**
 * @notice BaseCreditPool is the basic form of a complete pool in Huma Protocol.
 * All production pools are expected to be instances of BaseCreditPool or
 * contracts derived from it (e.g. ReceivableFactoringPool).
 *
 * All borrowing for BaseCreditPool starts with a credit line. As long as the account is in good
 * standing and below the approved limit, the borrower can borrow and repay again and again,
 * very similar to how a credit card works.
 */
contract BaseCreditPool is BasePool, BaseCreditPoolStorage, ICredit {
    using SafeERC20 for IERC20;
    using BS for BS.CreditRecord;

    enum CreditLineClosureReason {
        Paidoff,
        CreditLimitChangedToBeZero,
        OverwrittenByNewLine
    }

    /// Account billing info refreshed with the updated due amount and date
    event BillRefreshed(address indexed borrower, uint256 newDueDate, address by);
    /// Credit line request has been approved
    event CreditApproved(
        address indexed borrower,
        uint256 creditLimit,
        uint256 intervalInDays,
        uint256 remainingPeriods,
        uint256 aprInBps
    );

    /**
     * @notice Credit line created
     * @param borrower the address of the borrower
     * @param creditLimit the credit limit of the credit line
     * @param aprInBps interest rate (APR) expressed in basis points, 1% is 100, 100% is 10000
     * @param payPeriodInDays the number of days in each pay cycle
     * @param remainingPeriods how many cycles are there before the credit line expires
     * @param approved flag that shows if the credit line has been approved or not
     */
    event CreditInitiated(
        address indexed borrower,
        uint256 creditLimit,
        uint256 aprInBps,
        uint256 payPeriodInDays,
        uint256 remainingPeriods,
        bool approved
    );
    /// Credit limit for an existing credit line has been changed
    event CreditLineChanged(
        address indexed borrower,
        uint256 oldCreditLimit,
        uint256 newCreditLimit
    );

    /**
     * @notice An existing credit line has been closed
     * @param reasonCode the reason for the credit line closure
     */
    event CreditLineClosed(
        address indexed borrower,
        address by,
        CreditLineClosureReason reasonCode
    );
    /**
     * @notice The expiration (maturity) date of a credit line has been extended.
     * @param borrower the address of the borrower
     * @param numOfPeriods the number of pay periods to be extended
     * @param remainingPeriods the remaining number of pay periods after the extension
     */
    event CreditLineExtended(
        address indexed borrower,
        uint256 numOfPeriods,
        uint256 remainingPeriods,
        address by
    );
    /**
     * @notice The credit line has been marked as Defaulted.
     * @param borrower the address of the borrower
     * @param losses the total losses to be written off because of the default.
     * @param by the address who has triggered the default
     */
    event DefaultTriggered(address indexed borrower, uint256 losses, address by);
    /**
     * @notice A borrowing event has happened to the credit line
     * @param borrower the address of the borrower
     * @param borrowAmount the amount the user has borrowed
     * @param netAmountToBorrower the borrowing amount minus the fees that are charged upfront
     */
    event DrawdownMade(
        address indexed borrower,
        uint256 borrowAmount,
        uint256 netAmountToBorrower
    );
    /**
     * @notice A payment has been made against the credit line
     * @param borrower the address of the borrower
     * @param amount the payback amount
     * @param by the address that has triggered the process of marking the payment made.
     * In most cases, it is the borrower. In receivable factoring, it is PDSServiceAccount.
     */
    event PaymentMade(
        address indexed borrower,
        uint256 amount,
        uint256 totalDue,
        uint256 unbilledPrincipal,
        address by
    );

    /**
     * @notice Approves the credit request with the terms provided.
     * @param borrower the address of the borrower
     * @param creditLimit the credit limit of the credit line
     * @param intervalInDays the number of days in each pay cycle
     * @param remainingPeriods how many cycles are there before the credit line expires
     * @param aprInBps interest rate (APR) expressed in basis points, 1% is 100, 100% is 10000
     * @dev only Evaluation Agent can call
     */
    function approveCredit(
        address borrower,
        uint256 creditLimit,
        uint256 intervalInDays,
        uint256 remainingPeriods,
        uint256 aprInBps
    ) public virtual override {
        _protocolAndPoolOn();
        onlyEAServiceAccount();
        _maxCreditLineCheck(creditLimit);
        BS.CreditRecordStatic memory crs = _getCreditRecordStatic(borrower);
        crs.creditLimit = uint96(creditLimit);
        crs.aprInBps = uint16(aprInBps);
        crs.intervalInDays = uint16(intervalInDays);
        _creditRecordStaticMapping[borrower] = crs;

        BS.CreditRecord memory cr = _getCreditRecord(borrower);
        cr.remainingPeriods = uint16(remainingPeriods);
        _setCreditRecord(borrower, _approveCredit(cr));

        emit CreditApproved(borrower, creditLimit, intervalInDays, remainingPeriods, aprInBps);
    }

    /**
     * @notice changes the limit of the borrower's credit line.
     * @param borrower the owner of the credit line
     * @param newCreditLimit the new limit of the line in the unit of pool token
     * @dev The credit line is marked as Deleted if 1) the new credit line is 0 AND
     * 2) there is no due or unbilled principals.
     * @dev only Evaluation Agent can call
     */
    function changeCreditLine(address borrower, uint256 newCreditLimit) public virtual override {
        _protocolAndPoolOn();
        // Borrowing amount needs to be lower than max for the pool.
        _maxCreditLineCheck(newCreditLimit);

        uint256 oldCreditLimit = _creditRecordStaticMapping[borrower].creditLimit;

        // Only EA can increase credit line. Only EA or the borrower can reduce credit line.
        if (newCreditLimit > oldCreditLimit) onlyEAServiceAccount();
        else {
            if (msg.sender != borrower && msg.sender != _humaConfig.eaServiceAccount())
                revert Errors.onlyBorrowerOrEACanReduceCreditLine();
        }

        _creditRecordStaticMapping[borrower].creditLimit = uint96(newCreditLimit);

        // Mark the line as Deleted when there is no due or unbilled principal
        if (newCreditLimit == 0) {
            // Bring the account current
            BS.CreditRecord memory cr = _updateDueInfo(borrower, false, true);
            // Note: updated state and remainingPeriods directly instead of the entire cr
            // for contract size consideration
            if (cr.totalDue == 0 && cr.unbilledPrincipal == 0) {
                _creditRecordMapping[borrower].state = BS.CreditState.Deleted;
                emit CreditLineClosed(
                    borrower,
                    msg.sender,
                    CreditLineClosureReason.CreditLimitChangedToBeZero
                );
            }
            _creditRecordMapping[borrower].remainingPeriods = 0;
        }
        emit CreditLineChanged(borrower, oldCreditLimit, newCreditLimit);
    }

    /**
     * @notice allows the borrower to borrow against an approved credit line.
     * The borrower can borrow and pay back as many times as they would like.
     * @param borrowAmount the amount to borrow
     */
    function drawdown(uint256 borrowAmount) external virtual override {
        address borrower = msg.sender;
        // Open access to the borrower
        if (borrowAmount == 0) revert Errors.zeroAmountProvided();
        BS.CreditRecord memory cr = _getCreditRecord(borrower);

        _checkDrawdownEligibility(borrower, cr, borrowAmount);
        uint256 netAmountToBorrower = _drawdown(borrower, cr, borrowAmount);
        emit DrawdownMade(borrower, borrowAmount, netAmountToBorrower);
    }

    /**
     * @notice The expiration (maturity) date of a credit line has been extended.
     * @param borrower the address of the borrower
     * @param numOfPeriods the number of pay periods to be extended
     */
    function extendCreditLineDuration(address borrower, uint256 numOfPeriods)
        external
        virtual
        override
    {
        onlyEAServiceAccount();
        // Although it is not essential to call _updateDueInfo() to extend the credit line duration
        // it is good practice to bring the account current while we update one of the fields.
        // Also, only if we call _updateDueInfo(), we can write proper tests.
        _updateDueInfo(borrower, false, true);
        _creditRecordMapping[borrower].remainingPeriods += uint16(numOfPeriods);
        emit CreditLineExtended(
            borrower,
            numOfPeriods,
            _creditRecordMapping[borrower].remainingPeriods,
            msg.sender
        );
    }

    /**
     * @notice Makes one payment for the borrower. This can be initiated by the borrower
     * or by PDSServiceAccount with the allowance approval from the borrower.
     * If this is the final payment, it automatically triggers the payoff process.
     * @return amountPaid the actual amount paid to the contract. When the tendered
     * amount is larger than the payoff amount, the contract only accepts the payoff amount.
     * @return paidoff a flag indicating whether the account has been paid off.
     * @notice Warning, payments should be made by calling this function
     * No token should be transferred directly to the contract
     */
    function makePayment(address borrower, uint256 amount)
        public
        virtual
        override
        returns (uint256 amountPaid, bool paidoff)
    {
        if (msg.sender != borrower) onlyPDSServiceAccount();

        (amountPaid, paidoff, ) = _makePayment(borrower, amount, BS.PaymentStatus.NotReceived);
    }

    /**
     * @notice Updates the account and brings its billing status current
     * @dev If the account is defaulted, no need to update the account anymore.
     * @dev If the account is ready to be defaulted but not yet, update the account without
     * distributing the income for the upcoming period. Otherwise, update and distribute income
     * note the reason that we do not distribute income for the final cycle anymore since
     * it does not make sense to distribute income that we know cannot be collected to the
     * administrators (e.g. protocol, pool owner and EA) since it will only add more losses
     * to the LPs. Unfortunately, this special business consideration added more complexity
     * and cognitive load to _updateDueInfo(...).
     */
    function refreshAccount(address borrower)
        external
        virtual
        override
        returns (BS.CreditRecord memory cr)
    {
        if (_creditRecordMapping[borrower].state != BS.CreditState.Defaulted) {
            if (isDefaultReady(borrower)) return _updateDueInfo(borrower, false, false);
            else return _updateDueInfo(borrower, false, true);
        }
    }

    /**
     * @notice accepts a credit request from msg.sender
     * @param creditLimit the credit line (number of pool token)
     * @param intervalInDays duration of a payment cycle, typically 30 days
     * @param numOfPayments number of cycles for the credit line to be valid.
     */
    function requestCredit(
        uint256 creditLimit,
        uint256 intervalInDays,
        uint256 numOfPayments
    ) external virtual override {
        // Open access to the borrower. Data validation happens in _initiateCredit()
        _initiateCredit(
            msg.sender,
            creditLimit,
            _poolConfig.poolAprInBps(),
            intervalInDays,
            numOfPayments,
            false
        );
    }

    /**
     * @notice Triggers the default process
     * @return losses the amount of remaining losses to the pool
     * @dev It is possible for the borrower to payback even after default, especially in
     * receivable factoring cases.
     */
    function triggerDefault(address borrower) external virtual override returns (uint256 losses) {
        _protocolAndPoolOn();

        // check to make sure the default grace period has passed.
        BS.CreditRecord memory cr = _getCreditRecord(borrower);

        if (cr.state == BS.CreditState.Defaulted) revert Errors.defaultHasAlreadyBeenTriggered();

        if (block.timestamp > cr.dueDate) {
            cr = _updateDueInfo(borrower, false, false);
        }

        // Check if grace period has exceeded. Please note it takes a full pay period
        // before the account is considered to be late. The time passed should be one pay period
        // plus the grace period.
        if (!isDefaultReady(borrower)) revert Errors.defaultTriggeredTooEarly();

        // default amount includes all outstanding principals
        losses = cr.unbilledPrincipal + cr.totalDue - cr.feesAndInterestDue;

        _creditRecordMapping[borrower].state = BS.CreditState.Defaulted;

        _creditRecordStaticMapping[borrower].defaultAmount = uint96(losses);

        distributeLosses(losses);

        emit DefaultTriggered(borrower, losses, msg.sender);

        return losses;
    }

    function creditRecordMapping(address account) external view returns (BS.CreditRecord memory) {
        return _creditRecordMapping[account];
    }

    function creditRecordStaticMapping(address account)
        external
        view
        returns (BS.CreditRecordStatic memory)
    {
        return _creditRecordStaticMapping[account];
    }

    function isApproved(address borrower) external view virtual override returns (bool) {
        if ((_creditRecordMapping[borrower].state >= BS.CreditState.Approved)) return true;
        else return false;
    }

    /**
     * @notice checks if the credit line is ready to be triggered as defaulted
     */
    function isDefaultReady(address borrower) public view virtual override returns (bool) {
        uint16 intervalInDays = _creditRecordStaticMapping[borrower].intervalInDays;
        return
            _creditRecordMapping[borrower].missedPeriods * intervalInDays * SECONDS_IN_A_DAY >
                _poolConfig.poolDefaultGracePeriodInSeconds()
                ? true
                : false;
    }

    /** 
     * @notice checks if the credit line is behind in payments
     * @dev When the account is in Approved state, there is no borrowing yet, thus being late
     * does not apply. Thus the check on account state. 
     * @dev after the bill is refreshed, the due date is updated, it is possible that the new due 
     // date is in the future, but if the bill refresh has set missedPeriods, the account is late.
     */
    function isLate(address borrower) external view virtual override returns (bool) {
        return
            (_creditRecordMapping[borrower].state > BS.CreditState.Approved &&
                (_creditRecordMapping[borrower].missedPeriods > 0 ||
                    block.timestamp > _creditRecordMapping[borrower].dueDate))
                ? true
                : false;
    }

    function _approveCredit(BS.CreditRecord memory cr)
        internal
        view
        returns (BS.CreditRecord memory)
    {
        // Note: Special logic. dueDate is normally used to track the next bill due.
        // Before the first drawdown, it is also used to set the deadline for the first
        // drawdown to happen, otherwise, the credit line expires.
        // Decided to use this field in this way to save one field for the struct.
        // Although we have room in the struct after split struct creditRecord and
        // struct creditRecordStatic, we keep it unchanged to leave room for the struct
        // to expand in the future (note Solidity has limit on 13 fields in a struct)
        uint256 validPeriod = _poolConfig.creditApprovalExpirationInSeconds();
        if (validPeriod > 0) cr.dueDate = uint64(block.timestamp + validPeriod);

        cr.state = BS.CreditState.Approved;

        return cr;
    }

    /**
     * @notice Checks if drawdown is allowed for the credit line at this point of time
     * @dev the requester can be the borrower or the EA
     * @dev requires the credit line to be in Approved (first drawdown) or
     * Good Standing (return drawdown) state.
     * @dev for first drawdown, after the credit line is approved, it needs to happen within
     * the expiration window configured by the pool
     * @dev the drawdown should not put the account over the approved credit limit
     * @dev Please note cr.dueDate is the credit expiration date for the first drawdown.
     */
    function _checkDrawdownEligibility(
        address borrower,
        BS.CreditRecord memory cr,
        uint256 borrowAmount
    ) internal view {
        _protocolAndPoolOn();

        if (cr.state != BS.CreditState.GoodStanding && cr.state != BS.CreditState.Approved)
            revert Errors.creditLineNotInStateForDrawdown();
        else if (cr.state == BS.CreditState.Approved) {
            // After the credit approval, if the pool has credit expiration for the 1st drawdown,
            // the borrower must complete the first drawdown before the expiration date, which
            // is set in cr.dueDate in approveCredit().
            // note For pools without credit expiration for first drawdown, cr.dueDate is 0
            // before the first drawdown, thus the cr.dueDate > 0 condition in the check
            if (cr.dueDate > 0 && block.timestamp > cr.dueDate)
                revert Errors.creditExpiredDueToFirstDrawdownTooLate();

            if (borrowAmount > _creditRecordStaticMapping[borrower].creditLimit)
                revert Errors.creditLineExceeded();
        }
    }

    /**
     * @notice helper function for drawdown
     * @param borrower the borrower
     * @param borrowAmount the amount to borrow
     */
    function _drawdown(
        address borrower,
        BS.CreditRecord memory cr,
        uint256 borrowAmount
    ) internal virtual returns (uint256) {
        if (cr.state == BS.CreditState.Approved) {
            // Flow for first drawdown
            // Update total principal
            _creditRecordMapping[borrower].unbilledPrincipal = uint96(borrowAmount);

            // Generates the first bill
            // Note: the interest is calculated at the beginning of each pay period
            cr = _updateDueInfo(borrower, true, true);

            // Set account status in good standing
            cr.state = BS.CreditState.GoodStanding;
        } else {
            // Return drawdown flow
            // Bring the account current.
            if (block.timestamp > cr.dueDate) {
                cr = _updateDueInfo(borrower, false, true);
                if (cr.state != BS.CreditState.GoodStanding)
                    revert Errors.creditLineNotInGoodStandingState();
            }

            if (
                borrowAmount >
                (_creditRecordStaticMapping[borrower].creditLimit -
                    cr.unbilledPrincipal -
                    (cr.totalDue - cr.feesAndInterestDue))
            ) revert Errors.creditLineExceeded();

            // note Drawdown is not allowed in the final pay period since the payment due for
            // such drawdown will fall outside of the window of the credit line.
            // note since we bill at the beginning of a period, cr.remainingPeriods is zero
            // in the final period.
            if (cr.remainingPeriods == 0) revert Errors.creditExpiredDueToMaturity();

            // For non-first bill, we do not update the current bill, the interest for the rest of
            // this pay period is accrued in correction and will be added to the next bill.
            cr.correction += int96(
                uint96(
                    _calcCorrection(
                        cr.dueDate,
                        _creditRecordStaticMapping[borrower].aprInBps,
                        borrowAmount
                    )
                )
            );

            cr.unbilledPrincipal = uint96(cr.unbilledPrincipal + borrowAmount);
        }

        _setCreditRecord(borrower, cr);

        (uint256 netAmountToBorrower, uint256 platformFees) = _feeManager.distBorrowingAmount(
            borrowAmount
        );

        if (platformFees > 0) distributeIncome(platformFees);

        // Transfer funds to the _borrower
        _underlyingToken.safeTransfer(borrower, netAmountToBorrower);

        return netAmountToBorrower;
    }

    /**
     * @notice initiation of a credit line
     * @param borrower the address of the borrower
     * @param creditLimit the amount of the liquidity asset that the borrower obtains
     */
    function _initiateCredit(
        address borrower,
        uint256 creditLimit,
        uint256 aprInBps,
        uint256 intervalInDays,
        uint256 remainingPeriods,
        bool preApproved
    ) internal virtual {
        if (remainingPeriods == 0) revert Errors.requestedCreditWithZeroDuration();

        _protocolAndPoolOn();
        // Borrowers cannot have two credit lines in one pool. They can request to increase line.
        BS.CreditRecord memory cr = _getCreditRecord(borrower);

        if (cr.state != BS.CreditState.Deleted) {
            // If the user has an existing line, but there is no balance, close the old one
            // and initiate the new one automatically.
            cr = _updateDueInfo(borrower, false, true);
            if (cr.totalDue == 0 && cr.unbilledPrincipal == 0) {
                cr.state = BS.CreditState.Deleted;
                cr.remainingPeriods = 0;
                emit CreditLineClosed(
                    borrower,
                    msg.sender,
                    CreditLineClosureReason.OverwrittenByNewLine
                );
            } else {
                revert Errors.creditLineAlreadyExists();
            }
        }

        // Borrowing amount needs to be lower than max for the pool.
        _maxCreditLineCheck(creditLimit);

        _creditRecordStaticMapping[borrower] = BS.CreditRecordStatic({
            creditLimit: uint96(creditLimit),
            aprInBps: uint16(aprInBps),
            intervalInDays: uint16(intervalInDays),
            defaultAmount: uint96(0)
        });

        BS.CreditRecord memory ncr;
        ncr.remainingPeriods = uint16(remainingPeriods);

        if (preApproved) {
            ncr = _approveCredit(ncr);
            emit CreditApproved(borrower, creditLimit, intervalInDays, remainingPeriods, aprInBps);
        } else ncr.state = BS.CreditState.Requested;

        _setCreditRecord(borrower, ncr);

        emit CreditInitiated(
            borrower,
            creditLimit,
            aprInBps,
            intervalInDays,
            remainingPeriods,
            preApproved
        );
    }

    /**
     * @notice Borrower makes one payment. If this is the final payment,
     * it automatically triggers the payoff process.
     * @param borrower the address of the borrower
     * @param amount the payment amount
     * @param paymentStatus a flag that indicates the status the payment.
     * Ideally, two boolean parameters (isPaymentReceived, isPaymentVerified) are used
     * instead of paymentStatus. Due to stack too deep issue, one parameter is used.
     * NotReceived: Payment not received
     * ReceivedNotVerified: the system thinks the payment has been received but no manual
     * verification yet. Outlier cases might be flagged for manual review.
     * ReceivedAndVerified: the system thinks the payment has been received and it has been
     * manually verified after being flagged by the system.
     * @return amountPaid the actual amount paid to the contract. When the tendered
     * amount is larger than the payoff amount, the contract only accepts the payoff amount.
     * @return paidoff a flag indciating whether the account has been paid off.
     * @return isReviewRequired a flag indicating whether this payment transaction has been
     * flagged for review.
     */
    function _makePayment(
        address borrower,
        uint256 amount,
        BS.PaymentStatus paymentStatus
    )
        internal
        returns (
            uint256 amountPaid,
            bool paidoff,
            bool isReviewRequired
        )
    {
        _protocolAndPoolOn();

        if (amount == 0) revert Errors.zeroAmountProvided();

        BS.CreditRecord memory cr = _getCreditRecord(borrower);

        if (
            cr.state == BS.CreditState.Requested ||
            cr.state == BS.CreditState.Approved ||
            cr.state == BS.CreditState.Deleted
        ) {
            if (paymentStatus == BS.PaymentStatus.NotReceived)
                revert Errors.creditLineNotInStateForMakingPayment();
            else if (paymentStatus == BS.PaymentStatus.ReceivedNotVerified)
                return (0, false, true);
        }

        if (block.timestamp > cr.dueDate) {
            // Bring the account current. This is necessary since the account might have been dormant for
            // several cycles.
            cr = _updateDueInfo(borrower, false, true);
        }

        // Computes the final payoff amount. Needs to consider the correction associated with
        // all outstanding principals.
        uint256 payoffCorrection = _calcCorrection(
            cr.dueDate,
            _creditRecordStaticMapping[borrower].aprInBps,
            cr.unbilledPrincipal + cr.totalDue - cr.feesAndInterestDue
        );

        uint256 payoffAmount = uint256(
            int256(int96(cr.totalDue + cr.unbilledPrincipal)) + int256(cr.correction)
        ) - payoffCorrection;

        // If the reported received payment amount is far higher than the invoice amount,
        // flags the transaction for review.
        if (paymentStatus == BS.PaymentStatus.ReceivedNotVerified) {
            // Check against in-memory payoff amount first is purely for gas consideration.
            // We expect near 100% of the payments to fail in the first check
            if (amount > REVIEW_MULTIPLIER * payoffAmount) {
                if (
                    amount >
                    REVIEW_MULTIPLIER * uint256(_getCreditRecordStatic(borrower).creditLimit)
                ) return (0, false, true);
            }
        }

        // The amount to be collected from the borrower. When _amount is more than what is needed
        // for payoff, only the payoff amount will be transferred
        uint256 amountToCollect;

        // The amount to be applied towards principal
        uint256 principalPayment = 0;

        if (amount < payoffAmount) {
            if (amount < cr.totalDue) {
                amountToCollect = amount;
                cr.totalDue = uint96(cr.totalDue - amount);

                if (amount <= cr.feesAndInterestDue) {
                    cr.feesAndInterestDue = uint96(cr.feesAndInterestDue - amount);
                } else {
                    principalPayment = amount - cr.feesAndInterestDue;
                    cr.feesAndInterestDue = 0;
                }
            } else {
                amountToCollect = amount;

                // Apply extra payments towards principal, reduce unbilledPrincipal amount
                cr.unbilledPrincipal -= uint96(amount - cr.totalDue);

                principalPayment = amount - cr.feesAndInterestDue;
                cr.totalDue = 0;
                cr.feesAndInterestDue = 0;
                cr.missedPeriods = 0;

                // Moves account to GoodStanding if it was delayed.
                if (cr.state == BS.CreditState.Delayed) cr.state = BS.CreditState.GoodStanding;
            }

            // Gets the correction.
            if (principalPayment > 0) {
                // If there is principal payment, calculate new correction
                cr.correction -= int96(
                    uint96(
                        _calcCorrection(
                            cr.dueDate,
                            _creditRecordStaticMapping[borrower].aprInBps,
                            principalPayment
                        )
                    )
                );
            }

            // Recovers funds to the pool if the account is Defaulted.
            // Only moves it to GoodStanding only after payoff, handled in the payoff branch
            if (cr.state == BS.CreditState.Defaulted)
                _recoverDefaultedAmount(borrower, amountToCollect);
        } else {
            // Payoff logic
            principalPayment = cr.unbilledPrincipal + cr.totalDue - cr.feesAndInterestDue;
            amountToCollect = payoffAmount;

            if (cr.state == BS.CreditState.Defaulted) {
                _recoverDefaultedAmount(borrower, amountToCollect);
            } else {
                // Distribut or reverse income to consume outstanding correction.
                // Positive correction is generated because of a drawdown within this period.
                // It is not booked or distributed yet, needs to be distributed.
                // Negative correction is generated because of a payment including principal
                // within this period. The extra interest paid is not accounted for yet, thus
                // a reversal.
                // Note: For defaulted account, we do not distribute fees and interests
                // until they are paid. It is handled in _recoverDefaultedAmount().
                cr.correction = cr.correction - int96(int256(payoffCorrection));
                if (cr.correction > 0) distributeIncome(uint256(uint96(cr.correction)));
                else if (cr.correction < 0) reverseIncome(uint256(uint96(0 - cr.correction)));
            }

            cr.correction = 0;
            cr.unbilledPrincipal = 0;
            cr.feesAndInterestDue = 0;
            cr.totalDue = 0;
            cr.missedPeriods = 0;

            // Closes the credit line if it is in the final period
            if (cr.remainingPeriods == 0) {
                cr.state = BS.CreditState.Deleted;
                emit CreditLineClosed(borrower, msg.sender, CreditLineClosureReason.Paidoff);
            } else cr.state = BS.CreditState.GoodStanding;
        }

        _setCreditRecord(borrower, cr);

        if (amountToCollect > 0 && paymentStatus == BS.PaymentStatus.NotReceived) {
            // Transfer assets from the _borrower to pool locker
            _underlyingToken.safeTransferFrom(borrower, address(this), amountToCollect);
            emit PaymentMade(
                borrower,
                amountToCollect,
                cr.totalDue,
                cr.unbilledPrincipal,
                msg.sender
            );
        }

        // amountToCollect == payoffAmount indicates whether it is paid off or not.
        // Use >= as a safe practice
        return (amountToCollect, amountToCollect >= payoffAmount, false);
    }

    /**
     * @notice Recovers amount when a payment is paid towards a defaulted account.
     * @dev For any payment after a default, it is applied towards principal losses first.
     * Only after the principal is fully recovered, it is applied towards fees & interest.
     */
    function _recoverDefaultedAmount(address borrower, uint256 amountToCollect) internal {
        uint96 _defaultAmount = _creditRecordStaticMapping[borrower].defaultAmount;

        if (_defaultAmount > 0) {
            uint256 recoveredPrincipal;
            if (_defaultAmount >= amountToCollect) {
                recoveredPrincipal = amountToCollect;
            } else {
                recoveredPrincipal = _defaultAmount;
                distributeIncome(amountToCollect - recoveredPrincipal);
            }
            _totalPoolValue += recoveredPrincipal;
            _defaultAmount -= uint96(recoveredPrincipal);
            _creditRecordStaticMapping[borrower].defaultAmount = _defaultAmount;
        } else {
            // note The account is moved out of Defaulted state only if the entire due
            // including principals, fees&Interest are paid off. It is possible for
            // the account to owe fees&Interest after _defaultAmount becomes zero.
            distributeIncome(amountToCollect);
        }
    }

    /// Checks if the given amount is higher than what is allowed by the pool
    function _maxCreditLineCheck(uint256 amount) internal view {
        if (amount > _poolConfig.maxCreditLine()) {
            revert Errors.greaterThanMaxCreditLine();
        }
    }

    /**
     * @notice updates CreditRecord for `_borrower` using the most up to date information.
     * @dev this is used in both makePayment() and drawdown() to bring the account current
     * @dev getDueInfo() gets the due information of the most current cycle. This function
     * updates the record in creditRecordMapping for `_borrower`
     * @param borrower the address of the borrwoer
     * @param isFirstDrawdown whether this request is for the first drawdown of the credit line
     * @param distributeChargesForLastCycle whether to distribute income to different parties
     * (protocol, poolOwner, EA, and the pool). A `false` value is used in special cases
     * like `default` when we do not pause the accrue and distribution of fees.
     */
    function _updateDueInfo(
        address borrower,
        bool isFirstDrawdown,
        bool distributeChargesForLastCycle
    ) internal virtual returns (BS.CreditRecord memory cr) {
        cr = _getCreditRecord(borrower);
        if (isFirstDrawdown) cr.dueDate = 0;
        bool alreadyLate = cr.totalDue > 0 ? true : false;

        // Gets the up-to-date due information for the borrower. If the account has been
        // late or dormant for multiple cycles, getDueInfo() will bring it current and
        // return the most up-to-date due information.
        uint256 periodsPassed = 0;
        int96 newCharges;
        (
            periodsPassed,
            cr.feesAndInterestDue,
            cr.totalDue,
            cr.unbilledPrincipal,
            newCharges
        ) = _feeManager.getDueInfo(cr, _getCreditRecordStatic(borrower));

        if (periodsPassed > 0) {
            cr.correction = 0;
            // Distribute income
            if (cr.state != BS.CreditState.Defaulted) {
                if (!distributeChargesForLastCycle)
                    newCharges = newCharges - int96(cr.feesAndInterestDue);

                if (newCharges > 0) distributeIncome(uint256(uint96(newCharges)));
                else if (newCharges < 0) reverseIncome(uint256(uint96(0 - newCharges)));
            }

            uint16 intervalInDays = _creditRecordStaticMapping[borrower].intervalInDays;
            if (cr.dueDate > 0)
                cr.dueDate = uint64(
                    cr.dueDate + periodsPassed * intervalInDays * SECONDS_IN_A_DAY
                );
            else cr.dueDate = uint64(block.timestamp + intervalInDays * SECONDS_IN_A_DAY);

            // Adjusts remainingPeriods, special handling when reached the maturity of the credit line
            if (cr.remainingPeriods > periodsPassed) {
                cr.remainingPeriods = uint16(cr.remainingPeriods - periodsPassed);
            } else {
                cr.remainingPeriods = 0;
            }

            // Sets the right missedPeriods and state for the credit record
            if (alreadyLate) cr.missedPeriods = uint16(cr.missedPeriods + periodsPassed);
            else cr.missedPeriods = 0;

            if (cr.missedPeriods > 0) {
                if (cr.state != BS.CreditState.Defaulted) cr.state = BS.CreditState.Delayed;
            } else cr.state = BS.CreditState.GoodStanding;

            _setCreditRecord(borrower, cr);

            emit BillRefreshed(borrower, cr.dueDate, msg.sender);
        }
    }

    /// Shared setter to the credit record mapping for contract size consideration
    function _setCreditRecord(address borrower, BS.CreditRecord memory cr) internal {
        _creditRecordMapping[borrower] = cr;
    }

    /// Shared accessor for contract size consideration
    function _calcCorrection(
        uint256 dueDate,
        uint256 aprInBps,
        uint256 amount
    ) internal view returns (uint256) {
        return _feeManager.calcCorrection(dueDate, aprInBps, amount);
    }

    /// Shared accessor to the credit record mapping for contract size consideration
    function _getCreditRecord(address account) internal view returns (BS.CreditRecord memory) {
        return _creditRecordMapping[account];
    }

    /// Shared accessor to the credit record static mapping for contract size consideration
    function _getCreditRecordStatic(address account)
        internal
        view
        returns (BS.CreditRecordStatic memory)
    {
        return _creditRecordStaticMapping[account];
    }

    /// "Modifier" function that limits access to pdsServiceAccount only.
    function onlyPDSServiceAccount() internal view {
        if (msg.sender != HumaConfig(_humaConfig).pdsServiceAccount())
            revert Errors.paymentDetectionServiceAccountRequired();
    }

    /// "Modifier" function that limits access to eaServiceAccount only
    function onlyEAServiceAccount() internal view {
        if (msg.sender != _humaConfig.eaServiceAccount())
            revert Errors.evaluationAgentServiceAccountRequired();
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {BaseStructs as BS} from "./libraries/BaseStructs.sol";

contract ReceivableFactoringPoolStorage {
    /// mapping from wallet address to the receivable supplied by this wallet
    mapping(address => BS.ReceivableInfo) internal _receivableInfoMapping;

    /// mapping from the keccak256 hash of the payment event emitting address and its unique
    /// payment ID to a boolean. Used for preventing duplicate payment processing calls.
    mapping(bytes32 => bool) internal _processedPaymentIds;
    /// mapping from the keccak256 hash of the receivableAddress and receivableParam to
    /// the borrower address. This is needed for us to locate the borrower using
    /// the received receivable asset.
    mapping(bytes32 => address) internal _receivableOwnershipMapping;

    /// list of outlier payments that require manual review before processing
    mapping(bytes32 => BS.FlagedPaymentRecord) internal _paymentsToBeReviewed;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[99] private __gap;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/**
 * @notice Interface for contracts that can record pre-approved credit request
 */
interface IReceivable {
    /**
     * @param _borrower the borrower address
     * @param _creditLimit the limit of the credit
     * @param _receivableAsset the receivable asset used for this credit
     * @param _receivableParam additional parameter of the receivable asset, e.g. NFT tokenid
     * @param _receivableAmount amount of the receivable asset
     * @param _intervalInDays time interval for each payback in units of days
     * @param _remainingPeriods the number of pay periods for this credit
     */
    function approveCredit(
        address _borrower,
        uint256 _creditLimit,
        uint256 _intervalInDays,
        uint256 _remainingPeriods,
        uint256 _aprInBps,
        address _receivableAsset,
        uint256 _receivableParam,
        uint256 _receivableAmount
    ) external;

    /**
     * @notice reports after an payment is received for the borrower from a source
     * other than the borrower wallet
     */
    function onReceivedPayment(
        address borrower,
        uint256 amount,
        bytes32 paymentIdHash
    ) external;

    /**
     * @notice Reports if a payment has been processed
     * @param paymentIdHash the hash of the payment id
     */
    function isPaymentProcessed(bytes32 paymentIdHash) external view returns (bool);

    /// Makes drawdown using receivables included in the approval of the credit line
    function drawdownWithReceivable(
        uint256 borrowAmount,
        address receivableAsset,
        uint256 receivableParam
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.2) (utils/introspection/ERC165Checker.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface,
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            _supportsERC165Interface(account, type(IERC165).interfaceId) &&
            !_supportsERC165Interface(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && _supportsERC165Interface(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool[] memory)
    {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = _supportsERC165Interface(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in _interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!_supportsERC165Interface(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function _supportsERC165Interface(address account, bytes4 interfaceId) private view returns (bool) {
        // prepare call
        bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);

        // perform static call
        bool success;
        uint256 returnSize;
        uint256 returnValue;
        assembly {
            success := staticcall(30000, account, add(encodedParams, 0x20), mload(encodedParams), 0x00, 0x20)
            returnSize := returndatasize()
            returnValue := mload(0x00)
        }

        return success && returnSize >= 0x20 && returnValue > 0;
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {IERC20, IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "./interfaces/ILiquidityProvider.sol";
import "./interfaces/IPool.sol";

import "./BasePoolStorage.sol";
import "./Errors.sol";
import "./EvaluationAgentNFT.sol";
import "./HDT/HDT.sol";
import "./HumaConfig.sol";

import "hardhat/console.sol";

abstract contract BasePool is Initializable, BasePoolStorage, ILiquidityProvider, IPool {
    using SafeERC20 for IERC20;

    event LiquidityDeposited(address indexed account, uint256 assetAmount, uint256 shareAmount);
    event LiquidityWithdrawn(address indexed account, uint256 assetAmount, uint256 shareAmount);

    event PoolConfigChanged(address indexed sender, address newPoolConfig);
    event PoolCoreDataChanged(
        address indexed sender,
        address underlyingToken,
        address poolToken,
        address humaConfig,
        address feeManager
    );

    event PoolDisabled(address indexed by);
    event PoolEnabled(address indexed by);

    event AddApprovedLender(address indexed lender, address by);
    event RemoveApprovedLender(address indexed lender, address by);

    /**
     * @dev This event emits when new losses are distributed
     * @param lossesDistributed the amount of losses by the pool
     */
    event LossesDistributed(uint256 lossesDistributed, uint256 updatedPoolValue);

    constructor() {
        _disableInitializers();
    }

    function initialize(address poolConfigAddr) external initializer {
        _poolConfig = BasePoolConfig(poolConfigAddr);
        _updateCoreData();

        // note approve max amount to pool config for admins to withdraw their rewards
        _safeApproveForPoolConfig(type(uint256).max);

        // All pools are off when initiated, will turn on after admins' initial deposits
        _status = PoolStatus.Off;
    }

    //********************************************/
    //               LP Functions                //
    //********************************************/
    /**
     * @notice LP deposits to the pool to earn interest, and share losses
     *
     * @notice All deposits should be made by calling this function and
     * makeInitialDeposit() (for pool owner and EA's initial deposit) only.
     * Please do NOT directly transfer any digital assets to the contracts,
     * which will cause a permanent loss and we cannot help reverse transactions
     * or retrieve assets from the contracts.
     *
     * @param amount the number of underlyingToken to be deposited
     */
    function deposit(uint256 amount) external virtual override {
        _protocolAndPoolOn();
        return _deposit(msg.sender, amount);
    }

    /**
     * @notice Allows the pool owner and EA to make initial deposit before the pool goes live
     * @param amount the number of `poolToken` to be deposited
     */
    function makeInitialDeposit(uint256 amount) external virtual override {
        _poolConfig.onlyPoolOwnerTreasuryOrEA(msg.sender);
        return _deposit(msg.sender, amount);
    }

    /**
     * @notice Withdraw capital from the pool in the unit of underlyingToken
     * @dev Withdrawals are not allowed when 1) the pool withdraw is paused or
     *      2) the LP has not reached lockout period since their last depsit
     *      3) the requested amount is higher than the LP's remaining principal
     * @dev the `amount` is total amount to withdraw, not the number of HDT shares,
     * which will be computed based on the current price per share
     */
    function withdraw(uint256 amount) public virtual override {
        _protocolAndPoolOn();
        if (amount == 0) revert Errors.zeroAmountProvided();
        if (
            block.timestamp <
            _lastDepositTime[msg.sender] + _poolConfig.withdrawalLockoutPeriodInSeconds()
        ) revert Errors.withdrawTooSoon();

        uint256 withdrawableAmount = _poolToken.withdrawableFundsOf(msg.sender);
        if (amount > withdrawableAmount) revert Errors.withdrawnAmountHigherThanBalance();

        _poolConfig.checkWithdrawLiquidityRequirement(msg.sender, withdrawableAmount - amount);

        uint256 shares = _poolToken.burnAmount(msg.sender, amount);
        _totalPoolValue -= amount;
        _underlyingToken.safeTransfer(msg.sender, amount);

        emit LiquidityWithdrawn(msg.sender, amount, shares);
    }

    /**
     * @notice Withdraw all balance from the pool.
     */
    function withdrawAll() external virtual override {
        withdraw(_poolToken.withdrawableFundsOf(msg.sender));
    }

    function _deposit(address lender, uint256 amount) internal {
        if (amount == 0) revert Errors.zeroAmountProvided();
        _onlyApprovedLender(lender);

        if (_totalPoolValue + amount > _poolConfig.poolLiquidityCap())
            revert Errors.exceededPoolLiquidityCap();

        uint256 shares = _poolToken.mintAmount(lender, amount);
        _lastDepositTime[lender] = block.timestamp;
        _totalPoolValue += amount;
        _underlyingToken.safeTransferFrom(lender, address(this), amount);

        emit LiquidityDeposited(lender, amount, shares);
    }

    /**
     * @notice Distributes income to token holders.
     */
    function distributeIncome(uint256 value) internal virtual {
        uint256 poolIncome = _poolConfig.distributeIncome(value);
        _totalPoolValue += poolIncome;
    }

    /**
     * @notice Distributes losses associated with the token.
     * Note: The pool (i.e. LPs) is responsible for the losses in a default. The protocol does not
     * participate in loss distribution. PoolOwner and EA only participate in their LP capacity.
     * @param value the amount of losses to be distributed
     * @dev We chose not to change distributeIncome to accepted int256 to cover losses for
     * readability consideration.
     * @dev It does not make sense to combine reserveIncome() and distributeLosses() since protocol,
     * poolOwner and EA do not participate in losses, but they participate in income reverse.
     */
    function distributeLosses(uint256 value) internal virtual {
        if (_totalPoolValue > value) _totalPoolValue -= value;
        else _totalPoolValue = 0;
        emit LossesDistributed(value, _totalPoolValue);
    }

    /**
     * @notice Reverse income to token holders.
     * @param value the amount of income to be reverted
     * @dev this is needed when the user pays off early. We collect and distribute interest
     * at the beginning of the pay period. When the user pays off early, the interest
     * for the remainder of the period will be automatically subtraced from the payoff amount.
     * The portion of the income will be reversed. We can also change the parameter of
     * distributeIncome to int256. Choose to use a separate function for better readability.
     */
    function reverseIncome(uint256 value) internal virtual {
        uint256 poolIncome = _poolConfig.reverseIncome(value);
        if (_totalPoolValue > poolIncome) _totalPoolValue -= poolIncome;
        else _totalPoolValue = 0;
    }

    //********************************************/
    //            Admin Functions                //
    //********************************************/

    /**
     * @notice Lenders need to pass compliance requirements. Pool operator will administer off-chain
     * to make sure potential lenders meet the requirements. Afterwords, the pool operator will
     * call this function to mark a lender as approved.
     */
    function addApprovedLender(address lender) external virtual override {
        _onlyPoolOperator();
        _approvedLenders[lender] = true;
        emit AddApprovedLender(lender, msg.sender);
    }

    /**
     * @notice turns off the pool. Any pool operator can do so when they see abnormalities.
     */
    function disablePool() external virtual override {
        _onlyPoolOperator();
        _status = PoolStatus.Off;
        emit PoolDisabled(msg.sender);
    }

    /**
     * @notice turns on the pool. Only the pool owner or protocol owner can enable a pool.
     */
    function enablePool() external virtual override {
        _onlyOwnerOrHumaMasterAdmin();

        _poolConfig.checkLiquidityRequirement();

        _status = PoolStatus.On;
        emit PoolEnabled(msg.sender);
    }

    /**
     * @notice Disables a lender. This prevents the lender from making more deposits.
     * The capital that the lender has contributed can continue to work as normal.
     */
    function removeApprovedLender(address lender) external virtual override {
        _onlyPoolOperator();
        _approvedLenders[lender] = false;
        emit RemoveApprovedLender(lender, msg.sender);
    }

    /**
     * @notice Points the pool configuration to PoolConfig contract
     */
    function setPoolConfig(address poolConfigAddr) external override {
        _onlyOwnerOrHumaMasterAdmin();
        address oldConfig = address(_poolConfig);
        if (poolConfigAddr == oldConfig) revert Errors.sameValue();

        // note set old pool config allowance to 0
        _safeApproveForPoolConfig(0);

        BasePoolConfig newPoolConfig = BasePoolConfig(poolConfigAddr);
        newPoolConfig.onlyOwnerOrHumaMasterAdmin(msg.sender);

        _poolConfig = newPoolConfig;

        // note approve max amount to pool config for admin withdraw functions
        _safeApproveForPoolConfig(type(uint256).max);

        emit PoolConfigChanged(msg.sender, poolConfigAddr);
    }

    /**
     * @notice Updates references to core supporting contracts: underlying token, pool token,
     * Huma Config, and Fee Manager.
     */
    function updateCoreData() external {
        _onlyOwnerOrHumaMasterAdmin();
        _updateCoreData();
    }

    /**
     * @notice Gets the address of core supporting contracts: underlying token, pool token,
     * Huma Config, and Fee Manager.
     */
    function getCoreData()
        external
        view
        returns (
            address underlyingToken_,
            address poolToken_,
            address humaConfig_,
            address feeManager_
        )
    {
        underlyingToken_ = address(_underlyingToken);
        poolToken_ = address(_poolToken);
        humaConfig_ = address(_humaConfig);
        feeManager_ = address(_feeManager);
    }

    /// Reports if the given account has been approved as a lender for this pool
    function isApprovedLender(address account) external view virtual override returns (bool) {
        return _approvedLenders[account];
    }

    /// Gets the on/off status of the pool
    function isPoolOn() external view virtual override returns (bool status) {
        if (_status == PoolStatus.On) return true;
        else return false;
    }

    /// Gets the last deposit time of the given lender
    function lastDepositTime(address account) external view virtual override returns (uint256) {
        return _lastDepositTime[account];
    }

    /// Gets the address of poolConfig
    function poolConfig() external view virtual override returns (address) {
        return address(_poolConfig);
    }

    /// Gets the total value of the pool, measured by the units of underlying token
    function totalPoolValue() external view override returns (uint256) {
        return _totalPoolValue;
    }

    /**
     * @notice In PoolConfig, the admins (protocol, pool owner, EA) can withdraw the rewards
     * that they have earned so far. This gives allowance for PoolConfig to enable such withdraw.
     */
    function _safeApproveForPoolConfig(uint256 amount) internal {
        address config = address(_poolConfig);
        uint256 allowance = _underlyingToken.allowance(address(this), config);

        // Call safeApprove when the allowance is changed from >0 to 0, or from 0 to >0.
        if ((amount == 0 && allowance > 0) || (amount > 0 && allowance == 0)) {
            _underlyingToken.safeApprove(config, amount);
        }
    }

    /// Refreshes the cache of addresses for key contracts using the current data in PoolConfig
    function _updateCoreData() private {
        (
            address underlyingTokenAddr,
            address poolTokenAddr,
            address humaConfigAddr,
            address feeManagerAddr
        ) = _poolConfig.getCoreData();
        _underlyingToken = IERC20(underlyingTokenAddr);
        _poolToken = IHDT(poolTokenAddr);
        _humaConfig = HumaConfig(humaConfigAddr);
        _feeManager = BaseFeeManager(feeManagerAddr);

        emit PoolCoreDataChanged(
            msg.sender,
            underlyingTokenAddr,
            poolTokenAddr,
            humaConfigAddr,
            feeManagerAddr
        );
    }

    /// "Modifier" function that limits access only when both protocol and pool are on.
    /// Did not use modifier for contract size consideration.
    function _protocolAndPoolOn() internal view {
        if (_humaConfig.paused()) revert Errors.protocolIsPaused();
        if (_status != PoolStatus.On) revert Errors.poolIsNotOn();
    }

    /// "Modifier" function that limits access to approved lenders only.
    function _onlyApprovedLender(address lender) internal view {
        if (!_approvedLenders[lender]) revert Errors.permissionDeniedNotLender();
    }

    /// "Modifier" function that limits access to pool owner or protocol owner
    function _onlyOwnerOrHumaMasterAdmin() internal view {
        _poolConfig.onlyOwnerOrHumaMasterAdmin(msg.sender);
    }

    /// "Modifier" function that limits access to pool operators only
    function _onlyPoolOperator() internal view {
        if (!_poolConfig.isOperator(msg.sender)) revert Errors.poolOperatorRequired();
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {BaseStructs as BS} from "./libraries/BaseStructs.sol";

contract BaseCreditPoolStorage {
    /// mapping from wallet address to the credit record
    mapping(address => BS.CreditRecord) internal _creditRecordMapping;
    mapping(address => BS.CreditRecordStatic) internal _creditRecordStaticMapping;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[100] private __gap;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;
import {BaseStructs as BS} from "../libraries/BaseStructs.sol";

interface ICredit {
    /// Approves a credit line request
    function approveCredit(
        address borrower,
        uint256 creditLimit,
        uint256 intervalInDays,
        uint256 remainingPeriods,
        uint256 aprInBps
    ) external;

    /// Updating the credit limit of an existing credit line
    function changeCreditLine(address _borrower, uint256 newLine) external;

    /// Makes drawdown from an approved credit line
    function drawdown(uint256 _borrowAmount) external;

    /// Extends the validity period of the credit line
    function extendCreditLineDuration(address borrower, uint256 numOfPeriods) external;

    /**
     * @notice Makes a payment towardds an open credit line
     * @param _borrower the borrower
     * @param _amount the payment amount
     * @param amountPaid the amount actually paid
     * @return amountPaid the actuall amount paid to the contract. When the tendered
     * amount is larger than the payoff amount, the contract only accepts the payoff amount.
     * @return paidoff a flag indciating whether the account has been paid off.
     */
    function makePayment(address _borrower, uint256 _amount)
        external
        returns (uint256 amountPaid, bool paidoff);

    /**
     * @notice Refreshes the account status
     * @param borrower the address of the borrower
     * @return cr the refreshed credit record of the borrower.
     */
    function refreshAccount(address borrower) external returns (BS.CreditRecord memory cr);

    /**
     * @notice Requests a credit line
     * @param _creditLimit the limit of the credit line
     * @param  _intervalInDays the time interval between two payments
     * @param _numOfPayments total number of payment cycles for the credit line
     */
    function requestCredit(
        uint256 _creditLimit,
        uint256 _intervalInDays,
        uint256 _numOfPayments
    ) external;

    /**
     * @notice Triggers default for the credit line owned by the borrower
     * @param borrower the address of the borrower
     * @return losses the write off by the pool because of this default
     */
    function triggerDefault(address borrower) external returns (uint256 losses);

    /// Gets the approval status of the credit line for the borrower
    function isApproved(address borrower) external view returns (bool);

    /// Checks if the credit line owned by the borrower is ready for default
    function isDefaultReady(address borrower) external view returns (bool);

    /// Checks if the credit line owned by the borrower is late in payments
    function isLate(address borrower) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int256)", p0));
	}

	function logUint(uint256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint256 p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256)", p0, p1));
	}

	function log(uint256 p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string)", p0, p1));
	}

	function log(uint256 p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool)", p0, p1));
	}

	function log(uint256 p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address)", p0, p1));
	}

	function log(string memory p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint256 p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "./Errors.sol";

contract EvaluationAgentNFT is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    event NFTGenerated(uint256 tokenId, address recipient);
    event SetURI(uint256 tokenId, string tokenURI);

    constructor() ERC721("EvaluationAgentNFT", "EANFT") {}

    /**
     * @notice  Minting an NFT only gets a placeholder for an EA
     * the NFT has attributes such as "status" that can only be updated by
     * Huma to indicate whether the corresponding EA is approved or not.
     * Merely owning an EANFT does NOT mean the owner has any authority
     */
    function mintNFT(address recipient) external returns (uint256) {
        _tokenIds.increment();

        uint256 newItemId = _tokenIds.current();
        _mint(recipient, newItemId);

        emit NFTGenerated(newItemId, recipient);
        return newItemId;
    }

    function burn(uint256 tokenId) external returns (uint256) {
        if (msg.sender != ownerOf(tokenId)) revert Errors.notNFTOwner();
        _burn(tokenId);
        return tokenId;
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        // Intentionally disable transfer by doing nothing.
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        // Intentionally disable transfer by doing nothing.
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        // Intentionally disable transfer by doing nothing.
    }

    function setTokenURI(uint256 tokenId, string memory uri) external onlyOwner {
        emit SetURI(tokenId, uri);
        _setTokenURI(tokenId, uri);
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./HDT/interfaces/IHDT.sol";
import "./BasePoolConfig.sol";
import "./BaseFeeManager.sol";

contract BasePoolStorage {
    uint256 internal constant HUNDRED_PERCENT_IN_BPS = 10000;
    uint256 internal constant SECONDS_IN_A_DAY = 1 days;
    /// A multiplier over the credit limit, which is up to 80% of the invoice amount,
    /// that determines whether a payment amount should be flagged for review.
    /// It is possible for the actual invoice payment is higher than the invoice amount,
    /// however, it is too high, the chance for a fraud is high and thus requires review.
    uint256 internal constant REVIEW_MULTIPLIER = 5;

    enum PoolStatus {
        Off,
        On
    }

    // The ERC20 token this pool manages
    IERC20 internal _underlyingToken;

    // The HDT token for this pool
    IHDT internal _poolToken;

    BasePoolConfig internal _poolConfig;

    // Reference to HumaConfig. Removed immutable since Solidity disallow reference it in the constructor,
    // but we need to retrieve the poolDefaultGracePeriod in the constructor.
    HumaConfig internal _humaConfig;

    // Reference to the fee manager contract
    BaseFeeManager internal _feeManager;

    // The amount of underlying token belongs to lenders
    uint256 internal _totalPoolValue;

    // Tracks the last deposit time for each lender in this pool
    mapping(address => uint256) internal _lastDepositTime;

    // Whether the pool is ON or OFF
    PoolStatus internal _status;

    // The addresses that are allowed to lend to this pool. Configurable only by the pool owner
    mapping(address => bool) internal _approvedLenders;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[100] private __gap;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "./Errors.sol";

import "hardhat/console.sol";

/** @notice HumaConfig maintains all the global configurations supported by Huma protocol.
 */
contract HumaConfig is Ownable, Pausable {
    /// Lower bound of protocol default grace period.
    uint32 private constant MIN_DEFAULT_GRACE_PERIOD = 1 days;

    /// The initial value for default grace period.
    uint32 private constant PROTOCOL_DEFAULT_GRACE_PERIOD = 60 days;

    /// The default treasury fee in bps.
    uint16 private constant DEFAULT_TREASURY_FEE = 1000; // 10%

    /// The treasury fee upper bound in bps.
    uint16 private constant TREASURY_FEE_UPPER_BOUND = 5000; // 50%

    /// Seconds passed the due date before a default can be triggered
    uint32 public protocolDefaultGracePeriodInSeconds;

    /// % of platform income that will be reserved in the protocol, measured in basis points
    uint16 public protocolFee;

    /// Huma protocol treasury
    address public humaTreasury;

    /// address of EvaluationAgentNFT contract
    address public eaNFTContractAddress;

    /// service account for Huma's evaluation agent hosting service
    address public eaServiceAccount;

    /// service account for Huma's payment detection service
    address public pdsServiceAccount;

    /// pausers can pause the pool.
    mapping(address => bool) private pausers;

    // poolAdmins has the list of approved accounts who can create and operate pools
    mapping(address => bool) private poolAdmins;

    /// List of assets supported by the protocol for investing and borrowing
    mapping(address => bool) private validLiquidityAssets;

    /// Contract address for Evaluation Agent NFT changed
    event EANFTContractAddressChanged(address eaNFT);

    /// Service account for the Evaluation Agent platform has changed
    event EAServiceAccountChanged(address eaService);

    /// The treasury address for Huma protocol has changed
    event HumaTreasuryChanged(address indexed newTreasuryAddress);

    /// New underlying asset supported by the protocol is added
    event LiquidityAssetAdded(address asset, address by);

    /// Remove the asset that is no longer supported by the protocol
    event LiquidityAssetRemoved(address asset, address by);

    /// A pauser has been added. A pauser is someone who can pause the protocol.
    event PauserAdded(address indexed pauser, address by);

    /// A pauser has been removed
    event PauserRemoved(address indexed pauser, address by);

    /// Service account for Payment Detection Service has been changed
    event PDSServiceAccountChanged(address pdsService);

    event PoolAdminAdded(address indexed poolAdmin, address by);
    event PoolAdminRemoved(address indexed poolAdmin, address by);
    event ProtocolDefaultGracePeriodChanged(uint256 gracePeriod);
    event ProtocolInitialized(address by);
    event TreasuryFeeChanged(uint256 oldFee, uint256 newFee);

    /// Makes sure the msg.sender is one of the pausers
    modifier onlyPausers() {
        if (!pausers[msg.sender]) revert Errors.notPauser();
        _;
    }

    /**
     * @notice Initiates the config. Only the protocol owner can set the treasury
     * address, add pausers and pool admins, change the default grace period,
     * treasury fee, add or remove assets to be supported by the protocol.
     * @dev Emit ProtocolInitialized event and HumaTreasuryChanged event
     */
    constructor() {
        protocolDefaultGracePeriodInSeconds = PROTOCOL_DEFAULT_GRACE_PERIOD;

        protocolFee = DEFAULT_TREASURY_FEE;

        emit ProtocolInitialized(msg.sender);
    }

    /**
     * @notice Adds a pauser, who can pause the entire protocol. Only proto admin can do so.
     * @param _pauser Address to be added to the pauser list
     * @dev If address(0) is provided, revert with "zeroAddressProvided()"
     * @dev If the address is already a pauser, revert w/ "alreadyAPauser"
     * @dev Emits a PauserAdded event.
     */
    function addPauser(address _pauser) external onlyOwner {
        if (_pauser == address(0)) revert Errors.zeroAddressProvided();
        if (pausers[_pauser]) revert Errors.alreadyAPauser();

        pausers[_pauser] = true;

        emit PauserAdded(_pauser, msg.sender);
    }

    /**
     * @notice Adds a pool admin.  Only proto admin can do so.
     * @param _poolAdmin Address to be added as a pool admin
     * @dev If address(0) is provided, revert with "zeroAddressProvided()"
     * @dev If the address is already a poolAdmin, revert w/ "ALREADY_A_POOL_ADMIN"
     * @dev Emits a PauserAdded event.
     */
    function addPoolAdmin(address _poolAdmin) external onlyOwner {
        if (_poolAdmin == address(0)) revert Errors.zeroAddressProvided();
        if (poolAdmins[_poolAdmin]) revert Errors.alreadyPoolAdmin();

        poolAdmins[_poolAdmin] = true;

        emit PoolAdminAdded(_poolAdmin, msg.sender);
    }

    /**
     * @notice Pauses the entire protocol. Used in extreme cases by the pausers.
     * @dev This function will not be governed by timelock due to its sensitivity to timing.
     */
    function pause() external onlyPausers {
        _pause();
    }

    /**
     * @notice Removes a pauser. Only proto admin can do so.
     * @param _pauser Address to be removed from the pauser list
     * @dev If address(0) is provided, revert with "zeroAddressProvided()"
     * @dev If the address is not currently a pauser, revert w/ "notPauser()"
     * @dev Emits a PauserRemoved event.
     */
    function removePauser(address _pauser) external onlyOwner {
        if (_pauser == address(0)) revert Errors.zeroAddressProvided();
        if (!pausers[_pauser]) revert Errors.notPauser();

        pausers[_pauser] = false;

        emit PauserRemoved(_pauser, msg.sender);
    }

    /**
     * @notice Removes a poolAdmin. Only proto admin can do so.
     * @param _poolAdmin Address to be removed from the poolAdmin list
     * @dev If address(0) is provided, revert with "zeroAddressProvided()"
     * @dev If the address is not currently a poolAdmin, revert w/ "notPoolOwner()"
     * @dev Emits a PauserRemoved event.
     */
    function removePoolAdmin(address _poolAdmin) external onlyOwner {
        if (_poolAdmin == address(0)) revert Errors.zeroAddressProvided();
        if (!poolAdmins[_poolAdmin]) revert Errors.notPoolOwner();

        poolAdmins[_poolAdmin] = false;

        emit PoolAdminRemoved(_poolAdmin, msg.sender);
    }

    /**
     * @notice Sets the contract address for Evaluation Agent NFT contract. Only proto admin can do so.
     */
    function setEANFTContractAddress(address contractAddress) external onlyOwner {
        if (contractAddress == address(0)) revert Errors.zeroAddressProvided();
        eaNFTContractAddress = contractAddress;
        emit EANFTContractAddressChanged(contractAddress);
    }

    /**
     * @notice Sets the service account for Evaluation Agent service. This is the account
     * that can approve credit requests. Only proto admin can make the change.
     */
    function setEAServiceAccount(address accountAddress) external onlyOwner {
        if (accountAddress == address(0)) revert Errors.zeroAddressProvided();
        eaServiceAccount = accountAddress;
        emit EAServiceAccountChanged(accountAddress);
    }

    /**
     * @notice Sets the address of Huma Treasury. Only proto admin can do so.
     * @param treasury the new Huma Treasury address
     * @dev If address(0) is provided, revert with "zeroAddressProvided()"
     * @dev emit HumaTreasuryChanged(address newTreasury) event
     */
    function setHumaTreasury(address treasury) external onlyOwner {
        if (treasury == address(0)) revert Errors.zeroAddressProvided();
        if (treasury != humaTreasury) {
            humaTreasury = treasury;
            emit HumaTreasuryChanged(treasury);
        }
    }

    /**
     * @notice Sets the validity of an asset for liquidity in Huma. Only proto admin can do so.
     * @param asset Address of the valid asset.
     * @param valid The new validity status of a Liquidity Asset in Pools.
     * @dev Emits a LiquidityAssetAdded event when the asset is set to be valid
     * Emits a LiquidityAssetRemoved event when the asset is set to be invalid
     */
    function setLiquidityAsset(address asset, bool valid) external onlyOwner {
        if (valid) {
            validLiquidityAssets[asset] = true;
            emit LiquidityAssetAdded(asset, msg.sender);
        } else {
            validLiquidityAssets[asset] = false;
            emit LiquidityAssetRemoved(asset, msg.sender);
        }
    }

    /**
     * @notice Sets the service account for Payment Detection Service. Only proto admin can do so.
     * This is the account that can report to the contract that a payment has been received.
     */
    function setPDSServiceAccount(address accountAddress) external onlyOwner {
        if (accountAddress == address(0)) revert Errors.zeroAddressProvided();
        pdsServiceAccount = accountAddress;
        emit PDSServiceAccountChanged(accountAddress);
    }

    /**
     * @notice Sets the default grace period at the protocol level. Only proto admin can do so.
     * @param gracePeriod new default grace period in seconds
     * @dev Rejects any grace period shorter than 1 day to guard against fat finger or attack.
     * @dev Emits ProtocolDefaultGracePeriodChanged(uint256 newGracePeriod) event
     */
    function setProtocolDefaultGracePeriod(uint256 gracePeriod) external onlyOwner {
        if (gracePeriod < MIN_DEFAULT_GRACE_PERIOD)
            revert Errors.defaultGracePeriodLessThanMinAllowed();
        protocolDefaultGracePeriodInSeconds = uint32(gracePeriod);
        emit ProtocolDefaultGracePeriodChanged(gracePeriod);
    }

    /**
     * @notice Sets the treasury fee (in basis points). Only proto admin can do so.
     * @param fee the new treasury fee (in bps)
     * @dev Treasury fee cannot exceed 5000 bps, i.e. 50%
     * @dev Emits a TreasuryFeeChanged event
     */
    function setTreasuryFee(uint256 fee) external onlyOwner {
        if (fee > TREASURY_FEE_UPPER_BOUND) revert Errors.treasuryFeeHighThanUpperLimit();
        uint256 oldFee = protocolFee;
        protocolFee = uint16(fee);
        emit TreasuryFeeChanged(oldFee, fee);
    }

    /**
     * @notice Unpause the entire protocol. Only the protocol owner can do so.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /// Reports if the asset is supported by the protocol or not
    function isAssetValid(address asset) external view returns (bool) {
        return validLiquidityAssets[asset];
    }

    /// Reports if a given user account is an approved pauser or not
    function isPauser(address account) external view returns (bool) {
        return pausers[account];
    }

    /// Reports ia given user account is an approved pool admin
    function isPoolAdmin(address account) external view returns (bool) {
        return poolAdmins[account];
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "../libraries/BaseStructs.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IPool {
    /// Adds a lender to the pool after required off-chain background checking
    function addApprovedLender(address lender) external;

    /// Stops the pool. This stops all money moving in or out of the pool.
    function disablePool() external;

    /// Enables the pool to operate
    function enablePool() external;

    /// Removes a lender from the pool.
    function removeApprovedLender(address lender) external;

    /// Sets the poolConfig for the pool
    function setPoolConfig(address poolConfigAddr) external;

    /// Returns if an account has been approved to contribute to the pool.
    function isApprovedLender(address account) external view returns (bool);

    /// Returns if the pool is on or not
    function isPoolOn() external view returns (bool status);

    /// Returns the last time when the account has contributed to the pool as an LP
    function lastDepositTime(address account) external view returns (uint256);

    /// Returns the pool config associated the pool
    function poolConfig() external view returns (address);

    /// Gets the total pool value right now
    function totalPoolValue() external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

interface ILiquidityProvider {
    /**
     * Allows LPs to deposit into the pool.
     */
    function deposit(uint256 amount) external;

    /** 
     * Allows the pool owner and EA to make required initial deposit before turning on the pool
     */
    function makeInitialDeposit(uint256 amount) external;

    /**
     * Allows LPs to withdraw from the pool
     */
    function withdraw(uint256 amount) external;

    /**
     * Allows an LP to withdraw all their shares from the pool
     */
    function withdrawAll() external;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IERC20MetadataUpgradeable, ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "./interfaces/IHDT.sol";
import "./HDTStorage.sol";
import "../Errors.sol";

/**
 * @title Huma Distribution Token
 * @notice HDT tracks the principal, earnings and losses associated with a token.
 */
contract HDT is ERC20Upgradeable, OwnableUpgradeable, HDTStorage, IHDT {
    event PoolChanged(address pool);

    constructor() {
        _disableInitializers();
    }

    /**
     * @param name the name of the token
     * @param symbol the symbol of the token
     * @param underlyingToken the address of the underlying token used for the pool
     */
    function initialize(
        string memory name,
        string memory symbol,
        address underlyingToken
    ) external initializer {
        if (underlyingToken == address(0)) revert Errors.zeroAddressProvided();
        _assetToken = underlyingToken;

        __ERC20_init(name, symbol);
        // HDT uses the same decimal as the underlyingToken
        _decimals = IERC20MetadataUpgradeable(underlyingToken).decimals();

        __Ownable_init();
    }

    /**
     * @notice Associates the HDT with the pool
     * @dev Pool and HDT references each other. This call is expected to be called once at setup.
     */
    function setPool(address poolAddress) external onlyOwner {
        _pool = IPool(poolAddress);
        emit PoolChanged(poolAddress);
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    /**
     * @notice Returns the toal value of the pool, in the units of underlyingToken
     */
    function totalAssets() public view returns (uint256) {
        return _pool.totalPoolValue();
    }

    /**
     * @notice Mints HDTs when LPs contribute capital to the pool
     * @param account the address of the account to mint
     * @param amount the number of underlyingTokens used to mint HDTs
     */
    function mintAmount(address account, uint256 amount)
        external
        override
        onlyPool
        returns (uint256 shares)
    {
        shares = convertToShares(amount);
        if (shares == 0) revert Errors.zeroAmountProvided();
        _mint(account, shares);
    }

    /**
     * @notice Burns HDTs when LPs withdraw from the pool
     * @param account the address of the account to burn
     * @param amount the amount of underlyingTokens used to burn HDTs with equivalent value
     */
    function burnAmount(address account, uint256 amount)
        external
        override
        onlyPool
        returns (uint256 shares)
    {
        shares = convertToShares(amount);
        if (shares == 0) revert Errors.zeroAmountProvided();
        _burn(account, shares);
    }

    function convertToShares(uint256 assets) internal view virtual returns (uint256) {
        uint256 ts = totalSupply();
        uint256 ta = totalAssets();

        return ta == 0 ? assets : (assets * ts) / ta;
    }

    function convertToAssets(uint256 shares) internal view virtual returns (uint256) {
        uint256 ts = totalSupply();
        uint256 ta = totalAssets();

        return ts == 0 ? shares : (shares * ta) / ts;
    }

    /**
     * @notice Gets the amount of funds (in units of underlyingToken) that an address can withdraw
     * @param account The address of a token holder.
     * @return The amount funds that the account can withdraw.
     */
    function withdrawableFundsOf(address account)
        external
        view
        virtual
        override
        returns (uint256)
    {
        return convertToAssets(balanceOf(account));
    }

    /**
     * @notice the underlying token used in the associated pool
     */
    function assetToken() external view override returns (address) {
        return _assetToken;
    }

    /**
     * @notice the associated pool
     */
    function pool() external view returns (address) {
        return address(_pool);
    }

    /**
     * @notice Only the pool contract itself can call the functions.
     */
    modifier onlyPool() {
        if (msg.sender != address(_pool)) revert Errors.notPool();
        _;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
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
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
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
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
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
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
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
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/extensions/ERC721URIStorage.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";

/**
 * @dev ERC721 token with storage based token URI management.
 */
abstract contract ERC721URIStorage is ERC721 {
    using Strings for uint256;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev See {ERC721-_burn}. This override additionally checks to see if a
     * token-specific URI was set for the token, and if so, it deletes the token URI from
     * the storage mapping.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
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

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {IERC20, IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "./HDT/HDT.sol";
import "./HumaConfig.sol";
import "./BasePool.sol";
import "./Errors.sol";

import "hardhat/console.sol";

contract BasePoolConfig is Ownable, Initializable {
    using SafeERC20 for IERC20;

    /**
     * @notice Stores required liquidity rate and rewards rate for Pool Owner and EA
     */
    struct PoolConfig {
        // The max liquidity allowed for the pool.
        uint256 _liquidityCap;
        // How long a lender has to wait after the last deposit before they can withdraw
        uint256 _withdrawalLockoutPeriodInSeconds;
        // Percentage of pool income allocated to EA
        uint256 _rewardRateInBpsForEA;
        // Percentage of pool income allocated to Pool Owner
        uint256 _rewardRateInBpsForPoolOwner;
        // Percentage of the _liquidityCap to be contributed by EA
        uint256 _liquidityRateInBpsByEA;
        // Percentage of the _liquidityCap to be contributed by Pool Owner
        uint256 _liquidityRateInBpsByPoolOwner;
        // the maximum credit line for an address in terms of the amount of poolTokens
        uint88 _maxCreditLine;
        // the grace period at the pool level before a Default can be triggered
        uint256 _poolDefaultGracePeriodInSeconds;
        // pay period for the pool, measured in number of days
        uint256 _payPeriodInDays;
        // Percentage of receivable required for credits in this pool in terms of basis points
        // For over receivableization, use more than 100%, for no receivable, use 0.
        uint256 _receivableRequiredInBps;
        // the default APR for the pool in terms of basis points.
        uint256 _poolAprInBps;
        // the duration of a credit line without an initial drawdown
        uint256 _creditApprovalExpirationInSeconds;
    }

    struct AccruedIncome {
        uint128 _protocolIncome;
        uint128 _poolOwnerIncome;
        uint128 _eaIncome;
    }

    struct AccruedWithdrawn {
        uint128 _eaIncomeWithdrawn;
        uint128 _protocolIncomeWithdrawn;
        uint128 _poolOwnerIncomeWithdrawn;
    }

    uint256 private constant HUNDRED_PERCENT_IN_BPS = 10000;
    uint256 private constant SECONDS_IN_A_DAY = 1 days;
    uint256 private constant SECONDS_IN_180_DAYS = 180 days;
    uint256 private constant WITHDRAWAL_LOCKOUT_PERIOD_IN_SECONDS = SECONDS_IN_180_DAYS;

    string public poolName;

    address public pool;

    HumaConfig public humaConfig;

    address public feeManager;

    // The HDT token for this pool
    HDT public poolToken;

    // The ERC20 token this pool manages
    IERC20 public underlyingToken;

    // Evaluation Agents (EA) are the risk underwriting agents that associated with the pool.
    address public evaluationAgent;

    uint256 public evaluationAgentId;

    PoolConfig internal _poolConfig;

    AccruedIncome internal _accuredIncome;

    AccruedWithdrawn internal _accuredWithdrawn;

    /// Pool operators can add or remove lenders.
    mapping(address => bool) private poolOperators;

    // Address for the account that handles the treasury functions for the pool owner:
    // liquidity deposits, liquidity withdrawls, and reward withdrawals
    address public poolOwnerTreasury;

    event APRChanged(uint256 aprInBps, address by);
    event CreditApprovalExpirationChanged(uint256 durationInSeconds, address by);
    event EARewardsAndLiquidityChanged(
        uint256 rewardsRate,
        uint256 liquidityRate,
        address indexed by
    );
    event EvaluationAgentChanged(address oldEA, address newEA, uint256 newEAId, address by);
    event EvaluationAgentRewardsWithdrawn(address receiver, uint256 amount, address by);
    event FeeManagerChanged(address feeManager, address by);
    event HDTChanged(address hdt, address udnerlyingToken, address by);
    event HumaConfigChanged(address humaConfig, address by);
    event IncomeDistributed(
        uint256 protocolFee,
        uint256 ownerIncome,
        uint256 eaIncome,
        uint256 poolIncome
    );

    event IncomeReversed(
        uint256 protocolFee,
        uint256 ownerIncome,
        uint256 eaIncome,
        uint256 poolIncome
    );
    event MaxCreditLineChanged(uint256 maxCreditLine, address by);
    event PoolChanged(address pool, address by);
    event PoolDefaultGracePeriodChanged(uint256 gracePeriodInDays, address by);
    event PoolLiquidityCapChanged(uint256 liquidityCap, address by);
    event PoolNameChanged(string name, address by);
    event PoolOwnerRewardsAndLiquidityChanged(
        uint256 rewardsRate,
        uint256 liquidityRate,
        address indexed by
    );
    event PoolOwnerTreasuryChanged(address treasury, address indexed by);
    event PoolPayPeriodChanged(uint256 periodInDays, address by);
    event PoolRewardsWithdrawn(address receiver, uint256 amount);
    event ProtocolRewardsWithdrawn(address receiver, uint256 amount, address by);
    event ReceivableRequiredInBpsChanged(uint256 receivableInBps, address by);
    event WithdrawalLockoutPeriodChanged(uint256 lockoutPeriodInDays, address by);

    /// An operator has been added. An operator is someone who can add or remove approved lenders.
    event PoolOperatorAdded(address indexed operator, address by);

    /// A operator has been removed
    event PoolOperatorRemoved(address indexed operator, address by);

    function initialize(
        string memory _poolName,
        address _poolToken,
        address _humaConfig,
        address _feeManager
    ) external onlyOwner initializer {
        poolName = _poolName;
        if (_poolToken == address(0)) revert Errors.zeroAddressProvided();
        if (_humaConfig == address(0)) revert Errors.zeroAddressProvided();
        if (_feeManager == address(0)) revert Errors.zeroAddressProvided();
        poolToken = HDT(_poolToken);

        humaConfig = HumaConfig(_humaConfig);

        address assetTokenAddress = poolToken.assetToken();
        if (!humaConfig.isAssetValid(assetTokenAddress))
            revert Errors.underlyingTokenNotApprovedForHumaProtocol();
        underlyingToken = IERC20(assetTokenAddress);

        feeManager = _feeManager;

        _poolConfig._withdrawalLockoutPeriodInSeconds = WITHDRAWAL_LOCKOUT_PERIOD_IN_SECONDS;
        _poolConfig._poolDefaultGracePeriodInSeconds = HumaConfig(humaConfig)
            .protocolDefaultGracePeriodInSeconds();

        // Default values for the pool configurations. The pool owners are expected to reset
        // these values when setting up the pools. Setting these default values to avoid
        // strange behaviors when the pool owner missed setting up these configurations.
        // _liquidityCap, _maxCreditLine, _creditApprovalExpirationInSeconds are left at 0.
        _poolConfig._rewardRateInBpsForEA = 100;
        _poolConfig._rewardRateInBpsForPoolOwner = 100;
        _poolConfig._liquidityRateInBpsByEA = 200;
        _poolConfig._liquidityRateInBpsByPoolOwner = 200;
        _poolConfig._payPeriodInDays = 30;
        _poolConfig._receivableRequiredInBps = 10000;
        _poolConfig._poolAprInBps = 1500;
    }

    /**
     * @notice Adds a operator, who can add or remove approved lenders.
     * @param _operator Address to be added to the operator list
     * @dev If address(0) is provided, revert with "zeroAddressProvided()"
     * @dev If the address is already an operator, revert w/ "alreadyAnOperator"
     * @dev Emits a PoolOperatorAdded event.
     */
    function addPoolOperator(address _operator) external onlyOwner {
        if (_operator == address(0)) revert Errors.zeroAddressProvided();
        if (poolOperators[_operator]) revert Errors.alreadyAnOperator();

        poolOperators[_operator] = true;

        emit PoolOperatorAdded(_operator, msg.sender);
    }

    function distributeIncome(uint256 value) external returns (uint256 poolIncome) {
        if (msg.sender != pool) {
            revert Errors.notPool();
        }

        AccruedIncome memory tempIncome = _accuredIncome;

        uint256 protocolFee = (uint256(humaConfig.protocolFee()) * value) / HUNDRED_PERCENT_IN_BPS;
        tempIncome._protocolIncome += uint128(protocolFee);

        uint256 valueForPool = value - protocolFee;

        uint256 ownerIncome = (valueForPool * _poolConfig._rewardRateInBpsForPoolOwner) /
            HUNDRED_PERCENT_IN_BPS;
        tempIncome._poolOwnerIncome += uint128(ownerIncome);

        uint256 eaIncome = (valueForPool * _poolConfig._rewardRateInBpsForEA) /
            HUNDRED_PERCENT_IN_BPS;
        tempIncome._eaIncome += uint128(eaIncome);

        _accuredIncome = tempIncome;

        poolIncome = (valueForPool - ownerIncome - eaIncome);

        emit IncomeDistributed(protocolFee, ownerIncome, eaIncome, poolIncome);
    }

    function reverseIncome(uint256 value) external returns (uint256 poolIncome) {
        if (msg.sender != pool) {
            revert Errors.notPool();
        }

        AccruedIncome memory tempIncome = _accuredIncome;

        uint256 protocolFee = (uint256(humaConfig.protocolFee()) * value) / HUNDRED_PERCENT_IN_BPS;
        tempIncome._protocolIncome -= uint128(protocolFee);

        uint256 valueForPool = value - protocolFee;

        uint256 ownerIncome = (valueForPool * _poolConfig._rewardRateInBpsForPoolOwner) /
            HUNDRED_PERCENT_IN_BPS;
        tempIncome._poolOwnerIncome -= uint128(ownerIncome);

        uint256 eaIncome = (valueForPool * _poolConfig._rewardRateInBpsForEA) /
            HUNDRED_PERCENT_IN_BPS;
        tempIncome._eaIncome -= uint128(eaIncome);

        _accuredIncome = tempIncome;

        poolIncome = (valueForPool - ownerIncome - eaIncome);

        emit IncomeReversed(protocolFee, ownerIncome, eaIncome, poolIncome);
    }

    /**
     * @notice change the default APR for the pool
     * @param aprInBps APR in basis points, use 500 for 5%
     */
    function setAPR(uint256 aprInBps) external {
        _onlyOwnerOrHumaMasterAdmin();
        if (aprInBps > HUNDRED_PERCENT_IN_BPS) revert Errors.invalidBasisPointHigherThan10000();
        _poolConfig._poolAprInBps = aprInBps;
        emit APRChanged(aprInBps, msg.sender);
    }

    function setCreditApprovalExpiration(uint256 durationInDays) external {
        _onlyOwnerOrHumaMasterAdmin();
        _poolConfig._creditApprovalExpirationInSeconds = durationInDays * SECONDS_IN_A_DAY;
        emit CreditApprovalExpirationChanged(durationInDays * SECONDS_IN_A_DAY, msg.sender);
    }

    function setEARewardsAndLiquidity(uint256 rewardsRate, uint256 liquidityRate) external {
        _onlyOwnerOrHumaMasterAdmin();

        if (rewardsRate > HUNDRED_PERCENT_IN_BPS || liquidityRate > HUNDRED_PERCENT_IN_BPS)
            revert Errors.invalidBasisPointHigherThan10000();
        _poolConfig._rewardRateInBpsForEA = rewardsRate;
        _poolConfig._liquidityRateInBpsByEA = liquidityRate;
        emit EARewardsAndLiquidityChanged(rewardsRate, liquidityRate, msg.sender);
    }

    /**
     * @notice Adds an evaluation agent to the list who can approve loans.
     * @param agent the evaluation agent to be added
     */
    function setEvaluationAgent(uint256 eaId, address agent) external {
        if (agent == address(0)) revert Errors.zeroAddressProvided();
        _onlyOwnerOrHumaMasterAdmin();

        if (IERC721(HumaConfig(humaConfig).eaNFTContractAddress()).ownerOf(eaId) != agent)
            revert Errors.proposedEADoesNotOwnProvidedEANFT();

        // Make sure the new EA has met the liquidity requirements
        if (BasePool(pool).isPoolOn()) {
            checkLiquidityRequirementForEA(poolToken.withdrawableFundsOf(agent));
        }

        // Transfer the accrued EA income to the old EA's wallet.
        // Decided not to check if there is enough balance in the pool. If there is
        // not enough balance, the transaction will fail. PoolOwner has to find enough
        // liquidity to pay the EA before replacing it.
        address oldEA = evaluationAgent;
        evaluationAgent = agent;
        evaluationAgentId = eaId;

        if (oldEA != address(0)) {
            uint256 rewardsToPayout = _accuredIncome._eaIncome -
                _accuredWithdrawn._eaIncomeWithdrawn;
            if (rewardsToPayout > 0) {
                _withdrawEAFee(msg.sender, oldEA, rewardsToPayout);
            }
        }

        emit EvaluationAgentChanged(oldEA, agent, eaId, msg.sender);
    }

    function setFeeManager(address _feeManager) external {
        _onlyOwnerOrHumaMasterAdmin();
        if (_feeManager == address(0)) revert Errors.zeroAddressProvided();
        feeManager = _feeManager;
        emit FeeManagerChanged(_feeManager, msg.sender);
    }

    function setHumaConfig(address _humaConfig) external {
        _onlyOwnerOrHumaMasterAdmin();
        if (_humaConfig == address(0)) revert Errors.zeroAddressProvided();
        humaConfig = HumaConfig(_humaConfig);
        emit HumaConfigChanged(_humaConfig, msg.sender);
    }

    /**
     * @notice Sets the min and max of each loan/credit allowed by the pool.
     * @param creditLine the max amount of a credit line
     */
    function setMaxCreditLine(uint256 creditLine) external {
        _onlyOwnerOrHumaMasterAdmin();
        if (creditLine == 0) revert Errors.zeroAmountProvided();
        if (creditLine >= 2**88) revert Errors.creditLineTooHigh();
        _poolConfig._maxCreditLine = uint88(creditLine);
        emit MaxCreditLineChanged(creditLine, msg.sender);
    }

    function setPool(address _pool) external {
        _onlyOwnerOrHumaMasterAdmin();
        if (_pool == address(0)) revert Errors.zeroAddressProvided();
        pool = _pool;
        emit PoolChanged(_pool, msg.sender);
    }

    /**
     * Sets the default grace period for this pool.
     * @param gracePeriodInDays the desired grace period in days.
     */
    function setPoolDefaultGracePeriod(uint256 gracePeriodInDays) external {
        _onlyOwnerOrHumaMasterAdmin();
        _poolConfig._poolDefaultGracePeriodInSeconds = gracePeriodInDays * SECONDS_IN_A_DAY;
        emit PoolDefaultGracePeriodChanged(gracePeriodInDays, msg.sender);
    }

    /**
     * @notice Sets the cap of the pool liquidity.
     * @param liquidityCap the upper bound that the pool accepts liquidity from the depositors
     */
    function setPoolLiquidityCap(uint256 liquidityCap) external {
        _onlyOwnerOrHumaMasterAdmin();
        if (liquidityCap == 0) revert Errors.zeroAmountProvided();
        _poolConfig._liquidityCap = liquidityCap;
        emit PoolLiquidityCapChanged(liquidityCap, msg.sender);
    }

    function setPoolOwnerRewardsAndLiquidity(uint256 rewardsRate, uint256 liquidityRate) external {
        _onlyOwnerOrHumaMasterAdmin();
        if (rewardsRate > HUNDRED_PERCENT_IN_BPS || liquidityRate > HUNDRED_PERCENT_IN_BPS)
            revert Errors.invalidBasisPointHigherThan10000();

        _poolConfig._rewardRateInBpsForPoolOwner = rewardsRate;
        _poolConfig._liquidityRateInBpsByPoolOwner = liquidityRate;
        emit PoolOwnerRewardsAndLiquidityChanged(rewardsRate, liquidityRate, msg.sender);
    }

    function setPoolPayPeriod(uint256 periodInDays) external {
        _onlyOwnerOrHumaMasterAdmin();
        if (periodInDays == 0) revert Errors.zeroAmountProvided();
        _poolConfig._payPeriodInDays = periodInDays;
        emit PoolPayPeriodChanged(periodInDays, msg.sender);
    }

    /**
     * @notice Change pool name
     */
    function setPoolName(string memory newName) external {
        _onlyOwnerOrHumaMasterAdmin();
        poolName = newName;
        emit PoolNameChanged(newName, msg.sender);
    }

    function setPoolOwnerTreasury(address _poolOwnerTreasury) external {
        _onlyOwnerOrHumaMasterAdmin();
        if (_poolOwnerTreasury == address(0)) revert Errors.zeroAddressProvided();
        poolOwnerTreasury = _poolOwnerTreasury;
        emit PoolOwnerTreasuryChanged(_poolOwnerTreasury, msg.sender);
    }

    function setPoolToken(address _poolToken) external {
        _onlyOwnerOrHumaMasterAdmin();
        if (_poolToken == address(0)) revert Errors.zeroAddressProvided();
        poolToken = HDT(_poolToken);
        address assetToken = poolToken.assetToken();
        underlyingToken = IERC20(poolToken.assetToken());
        emit HDTChanged(_poolToken, assetToken, msg.sender);
    }

    /**
     * @notice Set the receivable rate in terms of basis points.
     * When the rate is higher than 10000, it means the backing is higher than the borrow amount,
     * similar to an over-collateral situation.
     * @param receivableInBps the percentage. A percentage over 10000 means overreceivableization.
     */
    function setReceivableRequiredInBps(uint256 receivableInBps) external {
        _onlyOwnerOrHumaMasterAdmin();
        // note: this rate can be over 10000 when it requires more backing than the credit limit
        _poolConfig._receivableRequiredInBps = receivableInBps;
        emit ReceivableRequiredInBpsChanged(receivableInBps, msg.sender);
    }

    /**
     * Sets withdrawal lockout period after the lender makes the last deposit
     * @param lockoutPeriodInDays the lockout period in terms of days
     */
    function setWithdrawalLockoutPeriod(uint256 lockoutPeriodInDays) external {
        _onlyOwnerOrHumaMasterAdmin();
        _poolConfig._withdrawalLockoutPeriodInSeconds = lockoutPeriodInDays * SECONDS_IN_A_DAY;
        emit WithdrawalLockoutPeriodChanged(lockoutPeriodInDays, msg.sender);
    }

    function withdrawEAFee(uint256 amount) external {
        // Either Pool owner or EA can trigger reward withdraw for EA.
        // When it is triggered by pool owner, the fund still flows to the EA's account.
        onlyPoolOwnerOrEA(msg.sender);
        if (amount == 0) revert Errors.zeroAmountProvided();
        if (amount + _accuredWithdrawn._eaIncomeWithdrawn > _accuredIncome._eaIncome)
            revert Errors.withdrawnAmountHigherThanBalance();
        // Note: the transfer can only goes to evaluationAgent
        _withdrawEAFee(msg.sender, evaluationAgent, amount);
    }

    function withdrawPoolOwnerFee(uint256 amount) external {
        onlyPoolOwnerTreasury(msg.sender);
        if (amount == 0) revert Errors.zeroAmountProvided();
        if (amount + _accuredWithdrawn._poolOwnerIncomeWithdrawn > _accuredIncome._poolOwnerIncome)
            revert Errors.withdrawnAmountHigherThanBalance();
        _accuredWithdrawn._poolOwnerIncomeWithdrawn += uint128(amount);
        underlyingToken.safeTransferFrom(pool, msg.sender, amount);
        emit PoolRewardsWithdrawn(msg.sender, amount);
    }

    function withdrawProtocolFee(uint256 amount) external {
        if (msg.sender != humaConfig.owner()) revert Errors.notProtocolOwner();
        if (amount + _accuredWithdrawn._protocolIncomeWithdrawn > _accuredIncome._protocolIncome)
            revert Errors.withdrawnAmountHigherThanBalance();
        _accuredWithdrawn._protocolIncomeWithdrawn += uint128(amount);
        address treasuryAddress = humaConfig.humaTreasury();
        // It is possible that Huma protocolTreasury is missed in the setup. If that happens,
        // the transaction is reverted. The protocol owner can still withdraw protocol fee
        // after protocolTreasury is configured in HumaConfig.
        assert(treasuryAddress != address(0));
        underlyingToken.safeTransferFrom(pool, treasuryAddress, amount);
        emit ProtocolRewardsWithdrawn(treasuryAddress, amount, msg.sender);
    }

    function accruedIncome()
        external
        view
        returns (
            uint256 protocolIncome,
            uint256 poolOwnerIncome,
            uint256 eaIncome,
            uint256 protocolIncomeWithdrawn,
            uint256 poolOwnerIncomeWithdrawn,
            uint256 eaIncomeWithdrawn
        )
    {
        return (
            _accuredIncome._protocolIncome,
            _accuredIncome._poolOwnerIncome,
            _accuredIncome._eaIncome,
            _accuredWithdrawn._protocolIncomeWithdrawn,
            _accuredWithdrawn._poolOwnerIncomeWithdrawn,
            _accuredWithdrawn._eaIncomeWithdrawn
        );
    }

    function checkLiquidityRequirementForPoolOwner(uint256 balance) public view {
        if (
            balance <
            (_poolConfig._liquidityCap * _poolConfig._liquidityRateInBpsByPoolOwner) /
                HUNDRED_PERCENT_IN_BPS
        ) revert Errors.poolOwnerNotEnoughLiquidity();
    }

    function checkLiquidityRequirementForEA(uint256 balance) public view {
        if (
            balance <
            (_poolConfig._liquidityCap * _poolConfig._liquidityRateInBpsByEA) /
                HUNDRED_PERCENT_IN_BPS
        ) revert Errors.evaluationAgentNotEnoughLiquidity();
    }

    /// Checks to make sure both EA and pool owner treasury meet the pool's liquidity requirements
    function checkLiquidityRequirement() public view {
        checkLiquidityRequirementForPoolOwner(poolToken.withdrawableFundsOf(poolOwnerTreasury));
        checkLiquidityRequirementForEA(poolToken.withdrawableFundsOf(evaluationAgent));
    }

    /// When the pool owner treasury or EA wants to withdraw liquidity from the pool,
    /// checks to make sure the remaining liquidity meets the pool's requirements
    function checkWithdrawLiquidityRequirement(address lender, uint256 newBalance) public view {
        if (lender == evaluationAgent) {
            checkLiquidityRequirementForEA(newBalance);
        } else if (lender == poolOwnerTreasury) {
            // note poolOwnerTreasury handles all thing financial-related for pool owner
            checkLiquidityRequirementForPoolOwner(newBalance);
        }
    }

    function creditApprovalExpirationInSeconds() external view returns (uint256) {
        return _poolConfig._creditApprovalExpirationInSeconds;
    }

    function getCoreData()
        external
        view
        returns (
            address underlyingToken_,
            address poolToken_,
            address humaConfig_,
            address feeManager_
        )
    {
        underlyingToken_ = address(underlyingToken);
        poolToken_ = address(poolToken);
        humaConfig_ = address(humaConfig);
        feeManager_ = feeManager;
    }

    /**
     * Returns a summary information of the pool.
     * @return token the address of the pool token
     * @return apr the default APR of the pool
     * @return payPeriod the standard pay period for the pool
     * @return maxCreditAmount the max amount for the credit line
     */
    function getPoolSummary()
        external
        view
        returns (
            address token,
            uint256 apr,
            uint256 payPeriod,
            uint256 maxCreditAmount,
            uint256 liquiditycap,
            string memory name,
            string memory symbol,
            uint8 decimals,
            uint256 eaId,
            address eaNFTAddress
        )
    {
        IERC20Metadata erc20Contract = IERC20Metadata(address(underlyingToken));
        return (
            address(underlyingToken),
            _poolConfig._poolAprInBps,
            _poolConfig._payPeriodInDays,
            _poolConfig._maxCreditLine,
            _poolConfig._liquidityCap,
            erc20Contract.name(),
            erc20Contract.symbol(),
            erc20Contract.decimals(),
            evaluationAgentId,
            humaConfig.eaNFTContractAddress()
        );
    }

    function isPoolOwnerTreasuryOrEA(address account) public view returns (bool) {
        return (account == poolOwnerTreasury || account == evaluationAgent);
    }

    /// Reports if a given user account is an approved operator or not
    function isOperator(address account) external view returns (bool) {
        return poolOperators[account];
    }

    function maxCreditLine() external view returns (uint256) {
        return _poolConfig._maxCreditLine;
    }

    function onlyPoolOwner(address account) public view {
        if (account != owner()) revert Errors.notPoolOwner();
    }

    function onlyPoolOwnerTreasury(address account) public view {
        if (account != poolOwnerTreasury) revert Errors.notPoolOwnerTreasury();
    }

    /// "Modifier" function that limits access to pool owner or EA.
    function onlyPoolOwnerOrEA(address account) public view {
        if (account != owner() && account != evaluationAgent) revert Errors.notPoolOwnerOrEA();
    }

    /// "Modifier" function that limits access to pool owner treasury or EA.
    function onlyPoolOwnerTreasuryOrEA(address account) public view {
        if (!isPoolOwnerTreasuryOrEA(account)) revert Errors.notPoolOwnerTreasuryOrEA();
    }

    function payPeriodInDays() external view returns (uint256) {
        return _poolConfig._payPeriodInDays;
    }

    function poolAprInBps() external view returns (uint256) {
        return _poolConfig._poolAprInBps;
    }

    function poolDefaultGracePeriodInSeconds() external view returns (uint256) {
        return _poolConfig._poolDefaultGracePeriodInSeconds;
    }

    function poolLiquidityCap() external view returns (uint256) {
        return _poolConfig._liquidityCap;
    }

    function receivableRequiredInBps() external view returns (uint256) {
        return _poolConfig._receivableRequiredInBps;
    }

    /**
     * @notice Removes a pool operator.
     * @param _operator Address to be removed from the operator list
     * @dev If address(0) is provided, revert with "zeroAddressProvided()"
     * @dev If the address is not currently a operator, revert w/ "notOperator()"
     * @dev Emits a PoolOperatorRemoved event.
     */
    function removePoolOperator(address _operator) external onlyOwner {
        if (_operator == address(0)) revert Errors.zeroAddressProvided();
        if (!poolOperators[_operator]) revert Errors.notOperator();

        poolOperators[_operator] = false;

        emit PoolOperatorRemoved(_operator, msg.sender);
    }

    function rewardsAndLiquidityRateForEA()
        external
        view
        returns (uint256 rewardRateInBpsForEA, uint256 liquidityRateInBpsByEA)
    {
        return (_poolConfig._rewardRateInBpsForEA, _poolConfig._liquidityRateInBpsByEA);
    }

    function rewardsAndLiquidityRateForPoolOwner()
        external
        view
        returns (uint256 rewardRateInBpsForPoolOwner, uint256 liquidityRateInBpsByPoolOwner)
    {
        return (
            _poolConfig._rewardRateInBpsForPoolOwner,
            _poolConfig._liquidityRateInBpsByPoolOwner
        );
    }

    function withdrawalLockoutPeriodInSeconds() external view returns (uint256) {
        return _poolConfig._withdrawalLockoutPeriodInSeconds;
    }

    // Allow for sensitive pool functions only to be called by
    // the pool owner and the huma master admin
    function onlyOwnerOrHumaMasterAdmin(address account) public view {
        if (account != owner() && account != humaConfig.owner()) {
            revert Errors.permissionDeniedNotAdmin();
        }
    }

    function _withdrawEAFee(
        address caller,
        address receiver,
        uint256 amount
    ) internal {
        _accuredWithdrawn._eaIncomeWithdrawn += uint96(amount);
        underlyingToken.safeTransferFrom(pool, receiver, amount);

        emit EvaluationAgentRewardsWithdrawn(receiver, amount, caller);
    }

    /// "Modifier" function that limits access to pool owner or Huma protocol owner
    function _onlyOwnerOrHumaMasterAdmin() internal view {
        onlyOwnerOrHumaMasterAdmin(msg.sender);
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/IFeeManager.sol";
import "./HumaConfig.sol";
import "./Errors.sol";
import {BaseStructs as BS} from "./libraries/BaseStructs.sol";
import "hardhat/console.sol";

/**
 *
 */
contract BaseFeeManager is IFeeManager, Ownable {
    using BS for BS.CreditRecord;

    // Divider to convert BPS to percentage
    uint256 private constant HUNDRED_PERCENT_IN_BPS = 10000;
    // Divider to get monthly interest rate from APR BPS. 10000 * 12
    uint256 private constant SECONDS_IN_A_YEAR = 365 days;
    uint256 private constant SECONDS_IN_A_DAY = 1 days;
    uint256 private constant MAX_PERIODS = 360; // 30 years monthly loan

    /// Part of platform fee, charged as a flat amount when a borrow happens
    uint256 public frontLoadingFeeFlat;

    /// Part of platform fee, charged as a % of the borrowing amount when a borrow happens
    uint256 public frontLoadingFeeBps;

    /// Part of late fee, charged as a flat amount when a payment is late
    uint256 public lateFeeFlat;

    /// Part of late fee, charged as % of the totaling outstanding balance when a payment is late
    uint256 public lateFeeBps;

    // membership fee per pay period. It is a flat fee
    uint256 public membershipFee;

    ///The min % of the outstanding principal to be paid in the statement for each each period
    uint256 public minPrincipalRateInBps;

    event FeeChanged(
        uint256 frontLoandingFeeFlat,
        uint256 frontLoadingFeeBps,
        uint256 lateFeeFlat,
        uint256 lateFeeBps,
        uint256 membershipFee
    );

    event MinPrincipalRateChanged(uint256 minPrincipalRateInBps);

    /**
     * @notice Sets the standard front loading and late fee policy for the fee manager
     * @param _frontLoadingFeeFlat flat fee portion of the front loading fee
     * @param _frontLoadingFeeBps a fee in the percentage of a new borrowing
     * @param _lateFeeFlat flat fee portion of the late
     * @param _lateFeeBps a fee in the percentage of the outstanding balance
     * @dev Only owner can make this setting
     */
    function setFees(
        uint256 _frontLoadingFeeFlat,
        uint256 _frontLoadingFeeBps,
        uint256 _lateFeeFlat,
        uint256 _lateFeeBps,
        uint256 _membershipFee
    ) external virtual override onlyOwner {
        frontLoadingFeeFlat = _frontLoadingFeeFlat;
        frontLoadingFeeBps = _frontLoadingFeeBps;
        lateFeeFlat = _lateFeeFlat;
        lateFeeBps = _lateFeeBps;
        membershipFee = _membershipFee;
        emit FeeChanged(
            _frontLoadingFeeFlat,
            _frontLoadingFeeBps,
            _lateFeeFlat,
            _lateFeeBps,
            _membershipFee
        );
    }

    /**
     * @notice Sets the min percentage of principal to be paid in each billing period
     * @param _minPrincipalRateInBps the min % in unit of bps. For example, 5% will be 500
     * @dev Only owner can make this setting
     * @dev There is a global limit of 5000 bps (50%).
     */
    function setMinPrincipalRateInBps(uint256 _minPrincipalRateInBps)
        external
        virtual
        override
        onlyOwner
    {
        if (_minPrincipalRateInBps >= 5000) revert Errors.minPrincipalPaymentRateSettingTooHigh();
        minPrincipalRateInBps = _minPrincipalRateInBps;
        emit MinPrincipalRateChanged(_minPrincipalRateInBps);
    }

    /**
     * @notice Computes the amount to be offseted due to in-cycle drawdown or principal payment
     * @dev Correction is used when there is change to the principal in the middle of the cycle
     * due to drawdown or principal payment. Since Huma computes the interest at the beginning
     * of each cycle, if there is a drawdown, the interest for this extra borrowing is not
     * billed, there will be a positive correction to be added in the next bill. Conversely,
     * since the interest has been computed for the entire cycle, if there is principal payment
     * in the middle, some of the interest should be refunded. It will be marked as negative
     * correction and be subtracted in the next bill.
     */
    function calcCorrection(
        uint256 dueDate,
        uint256 aprInBps,
        uint256 amount
    ) external view virtual override returns (uint256 correction) {
        // rounding to days
        uint256 remainingTime = dueDate - block.timestamp;

        return (amount * aprInBps * remainingTime) / SECONDS_IN_A_YEAR / HUNDRED_PERCENT_IN_BPS;
    }

    /**
     * @notice Computes the front loading fee including both the flat fee and percentage fee
     * @param _amount the borrowing amount
     * @return fees the amount of fees to be charged for this borrowing
     */
    function calcFrontLoadingFee(uint256 _amount)
        public
        view
        virtual
        override
        returns (uint256 fees)
    {
        fees = frontLoadingFeeFlat;
        if (frontLoadingFeeBps > 0)
            fees += (_amount * frontLoadingFeeBps) / HUNDRED_PERCENT_IN_BPS;
    }

    /**
     * @notice Computes the late fee including both the flat fee and percentage fee
     * @param dueDate the due date of the payment
     * @param totalDue the amount that is due
     * @param totalBalance the total balance including amount due and unbilled principal
     * @return fees the amount of late fees to be charged
     * @dev Charges only if 1) there is outstanding due, 2) the due date has passed
     */
    function calcLateFee(
        uint256 dueDate,
        uint256 totalDue,
        uint256 totalBalance
    ) public view virtual override returns (uint256 fees) {
        if (block.timestamp > dueDate && totalDue > 0) {
            fees = lateFeeFlat;
            if (lateFeeBps > 0) fees += (totalBalance * lateFeeBps) / HUNDRED_PERCENT_IN_BPS;
        }
    }

    /**
     * @notice Apply front loading fee, distribute the total amount to borrower, pool, & protocol
     * @param borrowAmount the amount of the borrowing
     * @return amtToBorrower the amount that the borrower can take
     * @return platformFees the platform charges
     * @dev the protocol always takes a percentage of the total fee generated
     */
    function distBorrowingAmount(uint256 borrowAmount)
        external
        view
        returns (uint256 amtToBorrower, uint256 platformFees)
    {
        // Calculate platform fee, which includes protocol fee and pool fee
        platformFees = calcFrontLoadingFee(borrowAmount);

        if (borrowAmount < platformFees) revert Errors.borrowingAmountLessThanPlatformFees();

        amtToBorrower = borrowAmount - platformFees;

        return (amtToBorrower, platformFees);
    }

    /**
     * @notice Gets the current total due, fees and interest due, and payoff amount.
     * Because there is no "cron" kind of mechanism, it is possible that the account is behind
     * for multiple cycles due to a lack of activities. This function will traverse through
     * these cycles to get the most up-to-date due information.
     * @dev This is a view only function, it does not update the account status. It is used to
     * help the borrowers to get their balances without paying gases.
     * @dev the difference between totalDue and feesAndInterestDue is required principal payment
     * @dev payoffAmount is good until the next statement date. It includes the interest for the
     * entire current/new billing period. We will ask for allowance of the total payoff amount,
     * but if the borrower pays off before the next due date, we will subtract the interest saved
     * and only transfer an amount lower than the original payoff estimate.
     * @dev please note the first due date is set after the initial drawdown. All the future due
     * dates are computed by adding multiples of the payment interval to the first due date.
     * @param _cr the credit record associated the account
     * @return periodsPassed the number of billing periods has passed since the last statement.
     * If it is within the same period, it will be 0.
     * @return feesAndInterestDue the sum of fees and interest due. If multiple cycles have passed,
     * this amount is not necessarily the total fees and interest charged. It only returns the amount
     * that is due currently.
     * @return totalDue amount due in this period, it includes fees, interest, and min principal
     */
    function getDueInfo(
        BaseStructs.CreditRecord memory _cr,
        BaseStructs.CreditRecordStatic memory _crStatic
    )
        public
        view
        virtual
        override
        returns (
            uint256 periodsPassed,
            uint96 feesAndInterestDue,
            uint96 totalDue,
            uint96 unbilledPrincipal,
            int96 totalCharges
        )
    {
        // Directly returns if it is still within the current period
        if (block.timestamp <= _cr.dueDate) {
            return (0, _cr.feesAndInterestDue, _cr.totalDue, _cr.unbilledPrincipal, 0);
        }

        // Computes how many billing periods have passed. 1+ is needed since Solidity always
        // round to zero. When it is exactly at a billing cycle, it is desirable to 1+ as well
        if (_cr.dueDate > 0) {
            periodsPassed =
                1 +
                (block.timestamp - _cr.dueDate) /
                (_crStatic.intervalInDays * SECONDS_IN_A_DAY);
            // No credit line has more than 360 periods. If it is longer than that, something
            // is wrong. Set it to 361 so that the non view function can emit an event.
            assert(periodsPassed <= MAX_PERIODS);
        } else {
            periodsPassed = 1;
        }

        /**
         * Loops through the cycles as we would generate statements for each cycle.
         * The logic for each iteration is as follows:
         * 1. Calcuate late fee if it is past due based on outstanding principal and due
         * 2. Add membership fee
         * 3  Add outstanding due amount and corrections to the unbilled principal
         *    as the new base for principal
         * 4. Calcuate interest for this new cycle using the new principal
         * 5. Calculate the principal due, and minus it from the unbilled principal amount
         */
        uint256 fees = 0;
        uint256 interest = 0;

        for (uint256 i = 0; i < periodsPassed; i++) {
            // step 1. late fee calculation
            if (_cr.totalDue > 0)
                fees = calcLateFee(
                    _cr.dueDate + i * _crStatic.intervalInDays * SECONDS_IN_A_DAY,
                    _cr.totalDue,
                    _cr.unbilledPrincipal + _cr.totalDue
                );

            // step 2. membership fee
            fees += membershipFee;

            // step 3. adding dues to principal
            _cr.unbilledPrincipal += _cr.totalDue;
            // Negative correction is generated by in-cycle payments only.
            // Positive correction is generated by in-cycle drawdowns only.
            // Incorporate pending corrections into principals
            if (_cr.correction != 0) {
                totalCharges += _cr.correction;
                if (_cr.correction < 0) {
                    uint96 correctionAbs = uint96(0 - _cr.correction);
                    // Note: If _cr.unbilledPrincipal is less than abs(correction), the account
                    // should have been paid off in the last payment. Thus the assertion below.
                    // One outlier case is drastic interest hike at the time of payments made.
                    //
                    assert(_cr.unbilledPrincipal > correctionAbs);
                    _cr.unbilledPrincipal -= correctionAbs;
                } else _cr.unbilledPrincipal += uint96(_cr.correction);
                _cr.correction = 0;
            }

            // step 4. compute interest
            interest =
                (_cr.unbilledPrincipal *
                    _crStatic.aprInBps *
                    _crStatic.intervalInDays *
                    SECONDS_IN_A_DAY) /
                SECONDS_IN_A_YEAR /
                HUNDRED_PERCENT_IN_BPS;

            // step 5. compute principal due and adjust unbilled principal
            uint256 principalToBill = (_cr.unbilledPrincipal * minPrincipalRateInBps) /
                HUNDRED_PERCENT_IN_BPS;
            _cr.feesAndInterestDue = uint96(fees + interest);
            totalCharges += int96(uint96(fees + interest));
            _cr.totalDue = uint96(fees + interest + principalToBill);
            _cr.unbilledPrincipal = uint96(_cr.unbilledPrincipal - principalToBill);
        }

        // If passed final period, all principal is due
        if (periodsPassed >= _cr.remainingPeriods) {
            _cr.totalDue += _cr.unbilledPrincipal;
            _cr.unbilledPrincipal = 0;
        }

        return (
            periodsPassed,
            _cr.feesAndInterestDue,
            _cr.totalDue,
            _cr.unbilledPrincipal,
            totalCharges
        );
    }

    /**
     * @notice Gets the fee structure for the pool
     * @param _frontLoadingFeeFlat flat fee portion of the front loading fee
     * @param _frontLoadingFeeBps a fee in the percentage of a new borrowing
     * @param _lateFeeFlat flat fee portion of the late
     * @param _lateFeeBps a fee in the percentage of the outstanding balance
     */
    function getFees()
        external
        view
        virtual
        override
        returns (
            uint256 _frontLoadingFeeFlat,
            uint256 _frontLoadingFeeBps,
            uint256 _lateFeeFlat,
            uint256 _lateFeeBps,
            uint256 _membershipFee
        )
    {
        return (frontLoadingFeeFlat, frontLoadingFeeBps, lateFeeFlat, lateFeeBps, membershipFee);
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/**
 * @notice A token that tracks the gains and losses that the token owner can claim.
 */
interface IHDT {
    /**
     * @dev Returns the total amount of funds a given address is able to withdraw currently.
     * @param owner Address of the token holder
     * @return a uint256 representing the available funds for a given account
     */
    function withdrawableFundsOf(address owner) external view returns (uint256);

    function mintAmount(address account, uint256 amount) external returns (uint256 shares);

    function burnAmount(address account, uint256 amount) external returns (uint256 shares);

    function assetToken() external view returns (address);
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IPool.sol";

contract HDTStorage {
    address internal _assetToken;
    uint8 internal _decimals;

    IPool internal _pool;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
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
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
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
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
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
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "../interfaces/IFeeManager.sol";
import "hardhat/console.sol";

library BaseStructs {
    /**
     * @notice CreditRecord stores the overall info and status about a credit.
     * @dev amounts are stored in uint96, all counts are stored in uint16
     * @dev each struct can have no more than 13 elements.
     */
    struct CreditRecord {
        uint96 unbilledPrincipal; // the amount of principal not included in the bill
        uint64 dueDate; // the due date of the next payment
        // correction is the adjustment of interest over or under-counted because of drawdown
        // or principal payment in the middle of a billing period
        int96 correction;
        uint96 totalDue; // the due amount of the next payment
        uint96 feesAndInterestDue; // interest and fees due for the next payment
        uint16 missedPeriods; // # of consecutive missed payments, for default processing
        uint16 remainingPeriods; // # of payment periods until the maturity of the credit line
        CreditState state; // status of the credit line
    }

    struct CreditRecordStatic {
        uint96 creditLimit; // the limit of the credit line
        uint16 aprInBps; // annual percentage rate in basis points, 3.75% is represented as 375
        uint16 intervalInDays; // # of days in one billing period
        uint96 defaultAmount; // the amount that has been defaulted.
    }

    /**
     * @notice ReceivableInfo stores receivable used for credits.
     * @dev receivableParam is used to store info such as NFT tokenId
     */
    struct ReceivableInfo {
        address receivableAsset;
        uint96 receivableAmount;
        uint256 receivableParam;
    }

    struct FlagedPaymentRecord {
        address paymentReceiver;
        uint256 amount;
    }

    enum CreditState {
        Deleted,
        Requested,
        Approved,
        GoodStanding,
        Delayed,
        Defaulted
    }
    enum PaymentStatus {
        NotReceived,
        ReceivedNotVerified,
        ReceivedAndVerified
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "../libraries/BaseStructs.sol";

interface IFeeManager {
    /**
     * @notice Computes the amuont to be offseted due to in-cycle drawdown or principal payment
     * @dev Correction is used when there is change to the principal in the middle of the cycle
     * due to drawdown or principal payment. Since Huma computes the interest at the beginning
     * of each cycle, if there is a drawdown, the interest for this extra borrowing is not
     * billed, there will be a positive correction to be added in the next bill. Conversely,
     * since the interest has been computed for the entire cycle, if there is principal payment
     * in the middle, some of the interest should be refunded. It will be marked as negative
     * correction and be subtracted in the next bill.
     */
    function calcCorrection(
        uint256 dueDate,
        uint256 aprInBps,
        uint256 amount
    ) external view returns (uint256 correction);

    /**
     * @notice Computes the front loading fee, which is also known as origination fee.
     * @param _amount the borrowing amount
     * @return fees the amount of fees to be charged for this borrowing
     */
    function calcFrontLoadingFee(uint256 _amount) external view returns (uint256 fees);

    /**
     * @notice Computes the late fee including both the flat fee and percentage fee
     * @param dueDate the due date of the payment
     * @param totalDue the amount that is due
     * @param balance the total balance including amount due and unbilled principal
     * @return fees the amount of late fees to be charged
     * @dev Charges only if 1) there is outstanding due, 2) the due date has passed
     */
    function calcLateFee(
        uint256 dueDate,
        uint256 totalDue,
        uint256 balance
    ) external view returns (uint256 fees);

    /**
     * @notice Gets the current total due, fees and interest due, and payoff amount.
     * Because there is no "cron" kind of mechanism, it is possible that the account is behind
     * for multiple cycles due to a lack of activities. This function will traverse through
     * these cycles to get the most up-to-date due information.
     * @param _cr the credit record associated the account
     * @return periodsPassed the number of billing periods has passed since the last statement.
     * If it is within the same period, it will be 0.
     * @return feesAndInterestDue the sum of fees and interest due. If multiple cycles have passed,
     * this amount is not necessarily the stotal fees and interest charged. It only returns the amount
     * that is due currently.
     * @return totalDue amount due in this period, it includes fees, interest, and min principal
     */
    function getDueInfo(
        BaseStructs.CreditRecord memory _cr,
        BaseStructs.CreditRecordStatic memory _crStatic
    )
        external
        view
        returns (
            uint256 periodsPassed,
            uint96 feesAndInterestDue,
            uint96 totalDue,
            uint96 unbilledPrincipal,
            int96 totalCharges
        );

    /**
     * @notice Sets the standard front loading and late fee policy for the fee manager
     * @param _frontLoadingFeeFlat flat fee portion of the front loading fee
     * @param _frontLoadingFeeBps a fee in the percentage of a new borrowing
     * @param _lateFeeFlat flat fee portion of the late
     * @param _lateFeeBps a fee in the percentage of the outstanding balance
     * @dev Only owner can make this setting
     */
    function setFees(
        uint256 _frontLoadingFeeFlat,
        uint256 _frontLoadingFeeBps,
        uint256 _lateFeeFlat,
        uint256 _lateFeeBps,
        uint256 _membershipFee
    ) external;

    /**
     * @notice Sets the min percentage of principal to be paid in each billing period
     * @param _minPrincipalRateInBps the min % in unit of bps. For example, 5% will be 500
     * @dev Only owner can make this setting
     * @dev This is a global limit of 5000 bps (50%).
     */
    function setMinPrincipalRateInBps(uint256 _minPrincipalRateInBps) external;

    /**
     * @notice Gets the fee structure for the pool
     * @param _frontLoadingFeeFlat flat fee portion of the front loading fee
     * @param _frontLoadingFeeBps a fee in the percentage of a new borrowing
     * @param _lateFeeFlat flat fee portion of the late
     * @param _lateFeeBps a fee in the percentage of the outstanding balance
     */
    function getFees()
        external
        view
        returns (
            uint256 _frontLoadingFeeFlat,
            uint256 _frontLoadingFeeBps,
            uint256 _lateFeeFlat,
            uint256 _lateFeeBps,
            uint256 _membershipFee
        );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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