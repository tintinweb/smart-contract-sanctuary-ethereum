// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

import { ERC20Helper }           from "../modules/erc20-helper/src/ERC20Helper.sol";
import { NonTransparentProxied } from "../modules/non-transparent-proxy/contracts/NonTransparentProxied.sol";

import {
    IDebtLockerLike,
    IERC20Like,
    ILoanFactoryLike,
    IMapleGlobalsLike,
    IMapleLoanLike,
    IMapleProxiedLike,
    IMapleProxyFactoryLike,
    IPoolManagerLike,
    IPoolV1Like,
    ITransitionLoanManagerLike
} from "./interfaces/Interfaces.sol";

import { IMigrationHelper } from "./interfaces/IMigrationHelper.sol";

contract MigrationHelper is IMigrationHelper, NonTransparentProxied {

    address public override globalsV2;
    address public override pendingAdmin;

    mapping(address => address) public override previousLenderOf;

    /******************************************************************************************************************************/
    /*** Modifiers                                                                                                              ***/
    /******************************************************************************************************************************/

    modifier onlyAdmin() {
        require(msg.sender == admin(), "MH:ONLY_ADMIN");
        _;
    }

    /******************************************************************************************************************************/
    /*** Admin Functions                                                                                                        ***/
    /******************************************************************************************************************************/

    function setPendingAdmin(address pendingAdmin_) external override onlyAdmin {
        emit PendingAdminSet(pendingAdmin = pendingAdmin_);
    }

    function acceptOwner() external override {
        require(msg.sender == pendingAdmin, "MH:AO:NO_AUTH");

        _setAddress(ADMIN_SLOT, msg.sender);

        pendingAdmin = address(0);

        emit OwnershipAccepted(msg.sender);
    }

    function setGlobals(address globalsV2_) external override onlyAdmin {
        emit GlobalsSet(globalsV2 = globalsV2_);
    }

    /******************************************************************************************************************************/
    /*** Step 1: Add Loans to TransitionLoanManager accounting (No contingency needed) [Phase 7]                                ***/
    /******************************************************************************************************************************/

    function addLoansToLoanManager(
        address poolV1_,
        address transitionLoanManager_,
        address[] calldata loans_,
        uint256 allowedDiff_
    )
        external override onlyAdmin
    {
        IMapleGlobalsLike globalsV2_ = IMapleGlobalsLike(globalsV2);

        // Check the protocol is not paused.
        require(!globalsV2_.protocolPaused(), "MH:ALTLM:PROTOCOL_PAUSED");

        // Check the TransitionLoanManager is valid.
        address loanManagerFactory_ = IMapleProxiedLike(transitionLoanManager_).factory();

        require(IMapleProxyFactoryLike(loanManagerFactory_).isInstance(transitionLoanManager_), "MH:ALTLM:INVALID_LM");
        require(globalsV2_.isFactory("LOAN_MANAGER", loanManagerFactory_),                      "MH:ALTLM:INVALID_LM_FACTORY");

        uint256 expectedPrincipal_ = IPoolV1Like(poolV1_).principalOut();
        uint256 countedPrincipal_  = 0;

        for (uint256 i; i < loans_.length; ++i) {
            address loan_ = loans_[i];
            require(IMapleLoanLike(loan_).claimableFunds() == 0, "MH:ALTLM:CLAIMABLE_FUNDS");

            countedPrincipal_ += IMapleLoanLike(loan_).principal();
            ITransitionLoanManagerLike(transitionLoanManager_).add(loan_);

            emit LoanAddedToTransitionLoanManager(transitionLoanManager_, loan_);
        }

        uint256 absError_ = expectedPrincipal_ > countedPrincipal_ ? expectedPrincipal_ - countedPrincipal_ : countedPrincipal_ - expectedPrincipal_;

        require(absError_ <= allowedDiff_, "MH:ALTLM:INVALID_PRINCIPAL");
    }

    /******************************************************************************************************************************/
    /*** Step 2: Airdrop tokens to all new LPs (No contingency needed) [Phase 10]                                               ***/
    /******************************************************************************************************************************/

    function airdropTokens(address poolV1Address_, address poolManager_, address[] calldata lpsV1_, address[] calldata lpsV2_, uint256 allowedDiff_) external override onlyAdmin {
        IPoolV1Like poolV1_ = IPoolV1Like(poolV1Address_);

        uint256 decimalConversionFactor_ = 10 ** IERC20Like(poolV1_.liquidityAsset()).decimals();
        uint256 totalLosses_             = poolV1_.poolLosses();
        address poolV2_                  = IPoolManagerLike(poolManager_).pool();

        uint256 totalPoolV1Value_ = ((poolV1_.totalSupply() * decimalConversionFactor_) / 1e18) + poolV1_.interestSum() - poolV1_.poolLosses();  // Add interfaces

        uint256 totalValueTransferred_;

        for (uint256 i = 0; i < lpsV1_.length; ++i) {
            address lpV1_ = lpsV1_[i];
            address lpV2_ = lpsV2_[i];

            uint256 lpLosses_ = totalLosses_ > 0 ? poolV1_.recognizableLossesOf(lpV1_) : 0;

            uint256 poolV2LPBalance_ = poolV1_.balanceOf(lpV1_) * decimalConversionFactor_ / 1e18 + poolV1_.withdrawableFundsOf(lpV1_) - lpLosses_;

            totalValueTransferred_ += poolV2LPBalance_;

            require(ERC20Helper.transfer(poolV2_, lpV2_, poolV2LPBalance_), "MH:AT:LP_TRANSFER_FAILED");

            emit TokensAirdropped(address(poolV1_), poolV2_, lpV1_, lpV2_, poolV2LPBalance_);
        }

        uint256 absError_ = totalPoolV1Value_ > totalValueTransferred_ ? totalPoolV1Value_ - totalValueTransferred_ : totalValueTransferred_ - totalPoolV1Value_;
        require(absError_ <= allowedDiff_, "MH:AT:VALUE_MISMATCH");

        uint256 dust_ = IERC20Like(address(poolV2_)).balanceOf(address(this));

        require(dust_ == 0 || ERC20Helper.transfer(poolV2_, lpsV2_[0], dust_), "MH:AT:PD_TRANSFER_FAILED");
    }

    /******************************************************************************************************************************/
    /*** Step 3: Set pending lender ownership for all loans to new LoanManager (Contingency needed) [Phase 12-13]               ***/
    /******************************************************************************************************************************/

    function setPendingLenders(
        address poolV1_,
        address poolV2ManagerAddress_,
        address loanFactoryAddress_,
        address[] calldata loans_,
        uint256 allowedDiff_
    )
        external override onlyAdmin
    {
        IMapleGlobalsLike globalsV2_ = IMapleGlobalsLike(globalsV2);

        // Check the protocol is not paused.
        require(!globalsV2_.protocolPaused(), "MH:SPL:PROTOCOL_PAUSED");

        // Check the PoolManager is valid (avoid stack too deep).
        {
            address poolManagerFactory_ = IPoolManagerLike(poolV2ManagerAddress_).factory();

            require(IMapleProxyFactoryLike(poolManagerFactory_).isInstance(poolV2ManagerAddress_), "MH:SPL:INVALID_PM");
            require(IMapleGlobalsLike(globalsV2).isFactory("POOL_MANAGER", poolManagerFactory_),   "MH:SPL:INVALID_PM_FACTORY");
        }

        address transitionLoanManager_ = IPoolManagerLike(poolV2ManagerAddress_).loanManagerList(0);

        // Check the TransitionLoanManager is valid (avoid stack too deep).
        {
            address loanManagerFactory_ = IMapleProxiedLike(transitionLoanManager_).factory();

            require(IMapleProxyFactoryLike(loanManagerFactory_).isInstance(transitionLoanManager_), "MH:SPL:INVALID_LM");
            require(IMapleGlobalsLike(globalsV2).isFactory("LOAN_MANAGER", loanManagerFactory_),    "MH:SPL:INVALID_LM_FACTORY");
        }

        // Check the Pool is active and owned by a valid PD (avoid stack too deep).
        {
            (
                address ownedPoolManager_,
                bool isPoolDelegate_
            ) = IMapleGlobalsLike(globalsV2).poolDelegates(IPoolManagerLike(poolV2ManagerAddress_).poolDelegate());

            require(IPoolManagerLike(poolV2ManagerAddress_).active(), "MH:SPL:PM_NOT_ACTIVE");
            require(ownedPoolManager_ == poolV2ManagerAddress_,       "MH:SPL:NOT_OWNED_PM");
            require(isPoolDelegate_,                                  "MH:SPL:INVALID_PD");
        }

        require(IMapleGlobalsLike(globalsV2).isFactory("LOAN", loanFactoryAddress_), "MH:SPL:INVALID_LOAN_FACTORY");

        uint256 expectedPrincipal_ = IPoolV1Like(poolV1_).principalOut();
        uint256 countedPrincipal_  = 0;

        for (uint256 i; i < loans_.length; ++i) {
            IMapleLoanLike  loan_       = IMapleLoanLike(loans_[i]);
            IDebtLockerLike debtLocker_ = IDebtLockerLike(loan_.lender());

            // Validate the PoolV1 address.
            require(debtLocker_.pool() == poolV1_, "MH:SPL:INVALID_DL_POOL");

            // Validate the loan.
            require(ILoanFactoryLike(loanFactoryAddress_).isLoan(address(loan_)), "MH:SPL:INVALID_LOAN");

            // Begin transfer of loan to the TransitionLoanManager.
            debtLocker_.setPendingLender(transitionLoanManager_);

            require(loan_.pendingLender() == transitionLoanManager_, "MH:SPL:INVALID_PENDING_LENDER");

            countedPrincipal_ += IMapleLoanLike(loan_).principal();

            emit PendingLenderSet(address(loan_), transitionLoanManager_);
        }

        uint256 absError_ = expectedPrincipal_ > countedPrincipal_ ? expectedPrincipal_ - countedPrincipal_ : countedPrincipal_ - expectedPrincipal_;

        require(absError_ <= allowedDiff_, "MH:SPL:INVALID_PRINCIPAL");
    }

    /******************************************************************************************************************************/
    /*** Step 4: Take ownership of all loans (Contingency needed) [Phase 14-15]                                                 ***/
    /******************************************************************************************************************************/

    function takeOwnershipOfLoans(
        address poolV1_,
        address transitionLoanManager_,
        address[] calldata loans_,
        uint256 allowedDiff_
    )
        external override onlyAdmin
    {
        IMapleGlobalsLike globalsV2_ = IMapleGlobalsLike(globalsV2);

        // Check the protocol is not paused.
        require(!globalsV2_.protocolPaused(), "MH:TOOL:PROTOCOL_PAUSED");

        // Check the TransitionLoanManager is valid.
        address loanManagerFactory_ = IMapleProxiedLike(transitionLoanManager_).factory();

        require(IMapleProxyFactoryLike(loanManagerFactory_).isInstance(transitionLoanManager_), "MH:TOOL:INVALID_LM");
        require(globalsV2_.isFactory("LOAN_MANAGER", loanManagerFactory_),                      "MH:TOOL:INVALID_LM_FACTORY");

        uint256 expectedPrincipal_ = IPoolV1Like(poolV1_).principalOut();
        uint256 countedPrincipal_  = 0;

        for (uint256 i; i < loans_.length; ++i) {
            address loan_ = loans_[i];

            countedPrincipal_ += IMapleLoanLike(loan_).principal();

            previousLenderOf[loan_] = IMapleLoanLike(loan_).lender();
        }

        uint256 absError_ = expectedPrincipal_ > countedPrincipal_ ? expectedPrincipal_ - countedPrincipal_ : countedPrincipal_ - expectedPrincipal_;

        require(absError_ <= allowedDiff_, "MH:TOOL:INVALID_PRINCIPAL");

        ITransitionLoanManagerLike(transitionLoanManager_).takeOwnership(loans_);

        for (uint256 i; i < loans_.length; ++i) {
            address loan_ = loans_[i];
            require(IMapleLoanLike(loan_).lender() == transitionLoanManager_, "MH:TOOL:INVALID_LENDER");
            emit LenderAccepted(loan_, transitionLoanManager_);
        }
    }

    /******************************************************************************************************************************/
    /*** Step 5: Upgrade Loan Manager (Contingency needed) [Phase 16]                                                           ***/
    /******************************************************************************************************************************/

    function upgradeLoanManager(address transitionLoanManager_, uint256 version_) public override onlyAdmin {
        IMapleGlobalsLike globalsV2_ = IMapleGlobalsLike(globalsV2);

        // Check the protocol is not paused.
        require(!globalsV2_.protocolPaused(), "MH:ULM:PROTOCOL_PAUSED");

        // Check the TransitionLoanManager is valid.
        address loanManagerFactory_ = IMapleProxiedLike(transitionLoanManager_).factory();
        require(IMapleProxyFactoryLike(loanManagerFactory_).isInstance(transitionLoanManager_), "MH:ULM:INVALID_LM");
        require(globalsV2_.isFactory("LOAN_MANAGER", loanManagerFactory_),                      "MH:ULM:INVALID_LM_FACTORY");

        ITransitionLoanManagerLike(transitionLoanManager_).upgrade(version_, "");

        emit LoanManagerUpgraded(transitionLoanManager_, version_);
    }

    /******************************************************************************************************************************/
    /*** Contingency Functions                                                                                                  ***/
    /******************************************************************************************************************************/

    // Rollback Step 3 [Phase 12-13]
    function rollback_setPendingLenders(address[] calldata loans_) external override onlyAdmin {
        for (uint256 i; i < loans_.length; ++i) {
            IDebtLockerLike(
                IMapleLoanLike(loans_[i]).lender()
            ).setPendingLender(address(0));
        }

        emit RolledBackSetPendingLenders(loans_);
    }

    // Rollback Step 4 [Phase 14-15]
    function rollback_takeOwnershipOfLoans(address transitionLoanManager_, address[] calldata loans_) external override onlyAdmin {
        address[] memory debtLockers_ = new address[](loans_.length);

        for (uint256 i; i < loans_.length; ++i) {
            address loan_ = loans_[i];
            debtLockers_[i] = previousLenderOf[loan_];
            delete previousLenderOf[loan_];
        }

        ITransitionLoanManagerLike(transitionLoanManager_).setOwnershipTo(loans_, debtLockers_);

        for (uint256 i; i < debtLockers_.length; ++i) {
            IDebtLockerLike(debtLockers_[i]).acceptLender();
        }

        emit RolledBackTakeOwnershipOfLoans(loans_, debtLockers_);
    }

    /******************************************************************************************************************************/
    /*** Helper Functions                                                                                                       ***/
    /******************************************************************************************************************************/

    function _setAddress(bytes32 slot_, address value_) private {
        assembly {
            sstore(slot_, value_)
        }
    }

}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

interface IMigrationHelper {

    /******************************************************************************************************************************/
    /*** Events                                                                                                                 ***/
    /******************************************************************************************************************************/

    /**
     *  @dev   Set the pending admin of the contract.
     *  @param pendingAdmin_ The address of the admin to take ownership of the contract.
     */
    event PendingAdminSet(address indexed pendingAdmin_);

    /**
     *  @dev   Accept ownership.
     *  @param newOwner_ The new owner of the contract.
     */
    event OwnershipAccepted(address indexed newOwner_);

    /**
     *  @dev   Set the globals address.
     *  @param globals_ The globals address.
     */
    event GlobalsSet(address indexed globals_);

    /**
     *  @dev   Add loans to the TransitionLoanManager, seeding the accounting state.
     *  @param loanManager_ The address of the TransitionLoanManager contract.
     *  @param loan_        The address of the loan that was added to the TransitionLoanManager.
     */
    event LoanAddedToTransitionLoanManager(address indexed loanManager_, address indexed loan_);

    /**
     *  @dev   Transfer initial mint of PoolV2 tokens to all PoolV1 LPs.
     *  @param poolV1_ The address of the PoolV1 contract.
     *  @param poolV2_ The address of the PoolManager contract for V2.
     *  @param lp1_    Array of all LP addresses in
     *  @param lp2_    The address of the pool delegate to transfer ownership to.
     *  @param amount_ The amount of PoolV2 tokens that was transferred to each LP.
     */
    event TokensAirdropped(address indexed poolV1_, address indexed poolV2_, address lp1_, address indexed lp2_, uint256 amount_);

    /**
     *  @dev   Set pending lender of an outstanding loan to the TransitionLoanManager.
     *  @param loan_          The address of the loan contract.
     *  @param pendingLender_ The address of the LoanManager that is set as pending lender.
     */
    event PendingLenderSet(address indexed loan_, address indexed pendingLender_);

    /**
     *  @dev   Accept ownership as lender of an outstanding loan to the TransitionLoanManager.
     *  @param loan_          The address of the loan contract.
     *  @param pendingLender_ The address of the LoanManager that accepted ownership.
     */
    event LenderAccepted(address indexed loan_, address indexed pendingLender_);

    /**
     *  @dev   Upgrade the LoanManager away from the TransitionLoanManager.
     *  @param loanManager_  The address of the LoanManager.
     *  @param version_      The version to set the LoanManager to on upgrade.
     */
    event LoanManagerUpgraded(address indexed loanManager_, uint256 version_);

    /**
     *  @dev   Setting of the pending lender on loans has been rolled back.
     *  @param loans_ The array of addresses of loans affected by the rollback.
     */
    event RolledBackSetPendingLenders(address[] loans_);

    /**
     *  @dev   Taking ownership of loans has been rolled back.
     *  @param loans_       The array of addresses of loans affected by the rollback.
     *  @param debtLockers_ The array of addresses of debt lockers that have bee reset as respective lenders by the rollback.
     */
    event RolledBackTakeOwnershipOfLoans(address[] loans_, address[] debtLockers_);

    /******************************************************************************************************************************/
    /*** State Variables                                                                                                        ***/
    /******************************************************************************************************************************/

    /**
     *  @dev The address of globals.
     */
    function globalsV2() external view returns (address globalsV2_);

    /**
     *  @dev The address of the pending admin.
     */
    function pendingAdmin() external view returns (address pendingAdmin_);

    /**
     *  @dev    Returns the previous lender of a given loan.
     *  @param  loan_           The address of the loan.
     *  @return previousLender_ The address of the previous lender.
     */
    function previousLenderOf(address loan_) external view returns (address previousLender_);

    /******************************************************************************************************************************/
    /*** Admin Functions                                                                                                        ***/
    /******************************************************************************************************************************/

    /**
     *  @dev Accept ownership.
     */
    function acceptOwner() external;

    /**
     *  @dev   Set the pending admin of the contract.
     *  @param pendingAdmin_ The address of the admin to take ownership of the contract.
     */
    function setPendingAdmin(address pendingAdmin_) external;


    /**
     *  @dev   Set the globals address.
     *  @param globalsV2_ The address of the globals V2 contract.
     */
    function setGlobals(address globalsV2_) external;

    /******************************************************************************************************************************/
    /*** Migration Functions                                                                                                    ***/
    /******************************************************************************************************************************/

    /**
     *  @dev   Add loans to the TransitionLoanManager, seeding the accounting state.
     *  @param poolV1_                The address of the PoolV1 contract.
     *  @param transitionLoanManager_ The address of the TransitionLoanManager contract.
     *  @param loans_                 Array of loans to add to the TransitionLoanManager.
     *  @param allowedDiff_           The allowed difference between the loan's principal and the sum of the loan's.
     */
    function addLoansToLoanManager(address poolV1_, address transitionLoanManager_, address[] calldata loans_, uint256 allowedDiff_) external;

    /**
     *  @dev   Transfer initial mint of PoolV2 tokens to all PoolV1 LPs.
     *  @param poolV1Address_ The address of the PoolV1 contract.
     *  @param poolManager_   The address of the PoolManager contract for V2.
     *  @param lpsV1_         Array of all LP addresses in
     *  @param lpsV2_         The address of the pool delegate to transfer ownership to.
     *  @param allowedDiff_   The allowed difference between the sum of PoolV2 tokens that were transferred to each LP and the expected value of PoolV1.
     */
    function airdropTokens(address poolV1Address_, address poolManager_, address[] calldata lpsV1_, address[] calldata lpsV2_, uint256 allowedDiff_) external;

    /**
     *  @dev   Set pending lender of all outstanding loans to the TransitionLoanManager.
     *  @param poolV1_                The address of the PoolV1 contract.
     *  @param poolV2ManagerAddress_  The address of the PoolManager contract for V2.
     *  @param loanFactoryAddress_    The address of the Loan factory contract.
     *  @param loans_                 Array of loans to add to transfer ownership on.
     *  @param allowedDiff_           The allowed difference between the loan's principal and the sum of the loan's.
     */
    function setPendingLenders(address poolV1_, address poolV2ManagerAddress_, address loanFactoryAddress_, address[] calldata loans_, uint256 allowedDiff_) external;

    /**
     *  @dev   Accept ownership of all outstanding loans to the TransitionLoanManager.
     *  @param poolV1_                The address of the PoolV1 contract.
     *  @param transitionLoanManager_ The address of the TransitionLoanManager contract.
     *  @param loans_                 Array of loans to accept ownership on.
     *  @param allowedDiff_           The allowed difference between the loan's principal and the sum of the loan's.
     */
    function takeOwnershipOfLoans(address poolV1_, address transitionLoanManager_, address[] calldata loans_, uint256 allowedDiff_) external;

    /**
     *  @dev   Upgrade the LoanManager from the TransitionLoanManager.
     *  @param transitionLoanManager_ The address of the TransitionLoanManager contract.
     *  @param version_               The version of the LoanManager to upgrade to.
     */
    function upgradeLoanManager(address transitionLoanManager_, uint256 version_) external;

    /******************************************************************************************************************************/
    /*** Contingency Functions                                                                                                  ***/
    /******************************************************************************************************************************/

    /**
     *  @dev   Function to revert the step to set all the pending lenders, setting all to zero.
     *  @param loans_ Array of loans to set pending lender to zero on.
     */
    function rollback_setPendingLenders(address[] calldata loans_) external;

    /**
     *  @dev   Function to revert the step to take ownership, returning ownership of loans to previous lenders.
     *  @param transitionLoanManager_ The address of the TransitionLoanManager contract.
     *  @param loans_                 Array of loans to revert ownership of.
     */
    function rollback_takeOwnershipOfLoans(address transitionLoanManager_, address[] calldata loans_) external;

}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

interface IDebtLockerLike {

    function acceptLender() external;

    function loan() external view returns (address loan_);

    function pool() external view returns (address pool_);

    function poolDelegate() external view returns (address poolDelegate_);

    function setPendingLender(address newLender_) external;
}

interface IERC20Like {

    function approve(address account_, uint256 amount) external returns (bool success_);

    function balanceOf(address account_) external view returns(uint256 balance_);

    function decimals() external view returns (uint8 decimals_);

    function transfer(address to_, uint256 amount) external returns (bool success_);

}

interface ILoanFactoryLike {

    function isLoan(address loan_) external view returns (bool isLoan_);

    function defaultVersion() external view returns (uint256 defaultVersion_);

    function implementationOf(uint256 version_) external view returns (address implementation_);

}

interface ILoanManagerLike {

    function accountedInterest() external view returns (uint256);

    function domainEnd() external view returns (uint256);

    function domainStart() external view returns (uint256);

    function getAccruedInterest() external view returns (uint256);

    function issuanceRate() external view returns (uint256);

    function paymentIdOf(address loan_) external view returns (uint24 paymentId_);

    function payments(uint256 paymentId_) external view returns (
        uint24  platformManagementFeeRate,
        uint24  delegateManagementFeeRate,
        uint48  startDate,
        uint48  paymentDueDate,
        uint128 incomingNetInterest,
        uint128 refinanceInterest,
        uint256 issuanceRate
    );

}

interface IMapleGlobalsLike {

    function isFactory(bytes32 factoryType_, address factory_) external view returns (bool valid_);

    function poolDelegates(address poolDelegate_) external view returns (address ownedPoolManager_, bool isPoolDelegate_);

    function delegateManagementFeeRate(address poolManager_) external view returns (uint256 delegateManagementFeeRate_);

    function platformManagementFeeRate(address poolManager_) external view returns (uint256 platformManagementFeeRate_);

    function protocolPaused() external view returns (bool paused_);

}

interface IMapleProxiedLike {

    function factory() external view returns (address factory_);

}

interface IMapleProxyFactoryLike {

    function isInstance(address instance_) external view returns (bool isInstance_);

    function versionOf(address instance_) external view returns (uint256 version_);

}

interface IMapleLoanLike is IMapleProxiedLike {

    function borrower() external view returns (address borrower_);

    function claimableFunds() external view returns (uint256 claimableFunds_);

    function closeLoan(uint256 amount_) external returns (uint256 principal_, uint256 interest_);

    function drawableFunds() external view returns (uint256 drawableFunds_);

    function getClosingPaymentBreakdown() external view returns (uint256 principal_, uint256 interest_, uint256 fees_);

    function getNextPaymentBreakdown() external view returns (uint256 principal_, uint256 interest_, uint256 delegateFee_, uint256 platformFee_);

    function implementation() external view returns (address implementation_);

    function interestRate() external view returns (uint256 interestRate_);

    function lateFeeRate() external view returns (uint256 lateFeeRate_);

    function lateInterestPremium() external view returns (uint256 lateInterestPremium_);

    function lender() external view returns (address lender_);

    function makePayment(uint256 amount_) external returns (uint256 principal_, uint256 interest_);

    function nextPaymentDueDate() external view returns (uint256 nextPaymentDueDate_);

    function paymentInterval() external view returns (uint256 paymentInterval_);

    function pendingLender() external view returns (address pendingLender_);

    function principal() external view returns (uint256 principal_);

    function refinanceInterest() external view returns (uint256 refinanceInterest_);

    function upgrade(uint256 toVersion_, bytes calldata arguments_) external;

}

interface IMapleLoanV4Like {

    function getNextPaymentBreakdown() external view returns (uint256 principal_, uint256 interest_, uint256 fees_);

    function getNextPaymentDetailedBreakdown() external view returns (uint256 principal_, uint256[3] memory interest_, uint256[2] memory fees_);

}

interface IPoolManagerLike is IMapleProxiedLike {

    function active() external view returns (bool active_);

    function asset() external view returns (address asset_);

    function delegateManagementFeeRate() external view returns (uint256 delegateManagementFeeRate_);

    function loanManagerList(uint256 index_) external view returns (address loanManager_);

    function pool() external view returns (address pool_);

    function poolDelegate() external view returns (address poolDelegate_);

    function totalAssets() external view returns (uint256 totalAssets_);

}

interface IPoolV1Like {

    function balanceOf(address account_) external view returns (uint256 balance_);

    function interestSum() external view returns (uint256 interestSum_);

    function liquidityAsset() external view returns (address liquidityAsset_);

    function poolLosses() external view returns (uint256 poolLosses_);

    function principalOut() external view returns (uint256 principalOut_);

    function recognizableLossesOf(address account_) external view returns (uint256 recognizableLosses_);

    function totalSupply() external view returns (uint256 totalSupply_);

    function withdrawableFundsOf(address account_) external view returns (uint256 withdrawableFunds_);

}

interface ITransitionLoanManagerLike {

    function add(address loan_) external;

    function setOwnershipTo(address[] calldata loans_, address[] calldata newLenders_) external;

    function takeOwnership(address[] calldata loans_) external;

    function upgrade(uint256 toVersion_, bytes calldata arguments_) external;

}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.7;

import { IERC20Like } from "./interfaces/IERC20Like.sol";

/**
 * @title Small Library to standardize erc20 token interactions.
 */
library ERC20Helper {

    /**************************/
    /*** Internal Functions ***/
    /**************************/

    function transfer(address token_, address to_, uint256 amount_) internal returns (bool success_) {
        return _call(token_, abi.encodeWithSelector(IERC20Like.transfer.selector, to_, amount_));
    }

    function transferFrom(address token_, address from_, address to_, uint256 amount_) internal returns (bool success_) {
        return _call(token_, abi.encodeWithSelector(IERC20Like.transferFrom.selector, from_, to_, amount_));
    }

    function approve(address token_, address spender_, uint256 amount_) internal returns (bool success_) {
        // If setting approval to zero fails, return false.
        if (!_call(token_, abi.encodeWithSelector(IERC20Like.approve.selector, spender_, uint256(0)))) return false;

        // If `amount_` is zero, return true as the previous step already did this.
        if (amount_ == uint256(0)) return true;

        // Return the result of setting the approval to `amount_`.
        return _call(token_, abi.encodeWithSelector(IERC20Like.approve.selector, spender_, amount_));
    }

    function _call(address token_, bytes memory data_) private returns (bool success_) {
        if (token_.code.length == uint256(0)) return false;

        bytes memory returnData;
        ( success_, returnData ) = token_.call(data_);

        return success_ && (returnData.length == uint256(0) || abi.decode(returnData, (bool)));
    }

}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.7;

/// @title Interface of the ERC20 standard as needed by ERC20Helper.
interface IERC20Like {

    function approve(address spender_, uint256 amount_) external returns (bool success_);

    function transfer(address recipient_, uint256 amount_) external returns (bool success_);

    function transferFrom(address owner_, address recipient_, uint256 amount_) external returns (bool success_);

}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.7;

import { INonTransparentProxied } from "./interfaces/INonTransparentProxied.sol";

contract NonTransparentProxied is INonTransparentProxied {

    bytes32 internal constant ADMIN_SLOT          = bytes32(uint256(keccak256("eip1967.proxy.admin"))          - 1);
    bytes32 internal constant IMPLEMENTATION_SLOT = bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1);

    function admin() public view override returns (address admin_) {
        admin_ = _getAddress(ADMIN_SLOT);
    }

    function implementation() public view override returns (address implementation_) {
        implementation_ = _getAddress(IMPLEMENTATION_SLOT);
    }

    function _getAddress(bytes32 slot_) private view returns (address value_) {
        assembly {
            value_ := sload(slot_)
        }
    }

}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.7;

interface INonTransparentProxied {

    /**
     *  @dev    Returns the proxy's admin address.
     *  @return admin_ The address of the admin.
     */
    function admin() external view returns (address admin_);

    /**
     *  @dev    Returns the proxy's implementation address.
     *  @return implementation_ The address of the implementation.
     */
    function implementation() external view returns (address implementation_);

}