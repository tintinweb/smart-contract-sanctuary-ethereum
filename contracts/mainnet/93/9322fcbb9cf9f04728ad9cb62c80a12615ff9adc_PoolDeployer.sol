// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

import { ERC20Helper }        from "../modules/erc20-helper/src/ERC20Helper.sol";
import { IMapleProxyFactory } from "../modules/maple-proxy-factory/contracts/interfaces/IMapleProxyFactory.sol";

import { ILoanManagerInitializerLike, IMapleGlobalsLike, IWithdrawalManagerInitializerLike } from "./interfaces/Interfaces.sol";

import { IPoolDeployer }           from "./interfaces/IPoolDeployer.sol";
import { IPoolManager }            from "./interfaces/IPoolManager.sol";
import { IPoolManagerInitializer } from "./interfaces/IPoolManagerInitializer.sol";

/*

    ██████╗  ██████╗  ██████╗ ██╗         ██████╗ ███████╗██████╗ ██╗      ██████╗ ██╗   ██╗███████╗██████╗
    ██╔══██╗██╔═══██╗██╔═══██╗██║         ██╔══██╗██╔════╝██╔══██╗██║     ██╔═══██╗╚██╗ ██╔╝██╔════╝██╔══██╗
    ██████╔╝██║   ██║██║   ██║██║         ██║  ██║█████╗  ██████╔╝██║     ██║   ██║ ╚████╔╝ █████╗  ██████╔╝
    ██╔═══╝ ██║   ██║██║   ██║██║         ██║  ██║██╔══╝  ██╔═══╝ ██║     ██║   ██║  ╚██╔╝  ██╔══╝  ██╔══██╗
    ██║     ╚██████╔╝╚██████╔╝███████╗    ██████╔╝███████╗██║     ███████╗╚██████╔╝   ██║   ███████╗██║  ██║
    ╚═╝      ╚═════╝  ╚═════╝ ╚══════╝    ╚═════╝ ╚══════╝╚═╝     ╚══════╝ ╚═════╝    ╚═╝   ╚══════╝╚═╝  ╚═╝

*/

contract PoolDeployer is IPoolDeployer {

    address public override globals;

    constructor(address globals_) {
        require((globals = globals_) != address(0), "PD:C:ZERO_ADDRESS");
    }

    function deployPool(
        address[3] memory factories_,
        address[3] memory initializers_,
        address asset_,
        string memory name_,
        string memory symbol_,
        uint256[6] memory configParams_
    )
        external override returns (
            address poolManager_,
            address loanManager_,
            address withdrawalManager_
        )
    {
        address poolDelegate_ = msg.sender;

        IMapleGlobalsLike globals_ = IMapleGlobalsLike(globals);

        require(globals_.isPoolDelegate(poolDelegate_), "PD:DP:INVALID_PD");

        require(globals_.isFactory("POOL_MANAGER",       factories_[0]), "PD:DP:INVALID_PM_FACTORY");
        require(globals_.isFactory("LOAN_MANAGER",       factories_[1]), "PD:DP:INVALID_LM_FACTORY");
        require(globals_.isFactory("WITHDRAWAL_MANAGER", factories_[2]), "PD:DP:INVALID_WM_FACTORY");

        // Avoid stack too deep error
        {
            IMapleProxyFactory PMFactory_ = IMapleProxyFactory(factories_[0]);
            IMapleProxyFactory LMFactory_ = IMapleProxyFactory(factories_[1]);
            IMapleProxyFactory WMFactory_ = IMapleProxyFactory(factories_[2]);

            require(initializers_[0] == PMFactory_.migratorForPath(PMFactory_.defaultVersion(), PMFactory_.defaultVersion()), "PD:DP:INVALID_PM_INITIALIZER");
            require(initializers_[1] == LMFactory_.migratorForPath(LMFactory_.defaultVersion(), LMFactory_.defaultVersion()), "PD:DP:INVALID_LM_INITIALIZER");
            require(initializers_[2] == WMFactory_.migratorForPath(WMFactory_.defaultVersion(), WMFactory_.defaultVersion()), "PD:DP:INVALID_WM_INITIALIZER");
        }

        bytes32 salt_ = keccak256(abi.encode(poolDelegate_));

        // Deploy Pool Manager
        bytes memory arguments = IPoolManagerInitializer(initializers_[0]).encodeArguments(poolDelegate_, asset_, configParams_[5], name_, symbol_);
        poolManager_           = IMapleProxyFactory(factories_[0]).createInstance(arguments, salt_);
        address pool_          = IPoolManager(poolManager_).pool();

        // Deploy Loan Manager
        arguments    = ILoanManagerInitializerLike(initializers_[1]).encodeArguments(pool_);
        loanManager_ = IMapleProxyFactory(factories_[1]).createInstance(arguments, salt_);

        // Deploy Withdrawal Manager
        arguments          = IWithdrawalManagerInitializerLike(initializers_[2]).encodeArguments(pool_, configParams_[3], configParams_[4]);
        withdrawalManager_ = IMapleProxyFactory(factories_[2]).createInstance(arguments, salt_);

        // Configure Pool Manager
        IPoolManager(poolManager_).configure(loanManager_, withdrawalManager_, configParams_[0], configParams_[1]);

        require(ERC20Helper.transferFrom(asset_, poolDelegate_, IPoolManager(poolManager_).poolDelegateCover(), configParams_[2]), "PD:DP:TRANSFER_FAILED");
    }

}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

interface IPoolDeployer {

    function globals() external view returns (address globals_);

    /**
     *  @dev   Deploys a pool along with its dependencies.
     *  @param factories_    Array of deployer addresses. Array used to avoid stack too deep issues.
     *                        [0]: poolManagerFactory
     *                        [1]: loanManagerFactory
     *                        [2]: withdrawalManagerFactory
     *  @param initializers_ Array of initializer addresses.
     *                        [0]: poolManagerInitializer
     *                        [1]: loanManagerInitializer
     *                        [2]: withdrawalManagerInitializer
     *  @param configParams_ Array of uint256 config parameters. Array used to avoid stack too deep issues.
     *                        [0]: liquidityCap
     *                        [1]: delegateManagementFeeRate
     *                        [2]: coverAmountRequired
     *                        [3]: cycleDuration
     *                        [4]: windowDuration
     *                        [5]: initialSupply
     */
    function deployPool(
        address[3] memory factories_,
        address[3] memory initializers_,
        address asset_,
        string memory name_,
        string memory symbol_,
        uint256[6] memory configParams_
    ) external returns (
        address poolManager_,
        address loanManager_,
        address withdrawalManager_
    );

}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

import { IMapleProxied } from "../../modules/maple-proxy-factory/contracts/interfaces/IMapleProxied.sol";

import { IPoolManagerStorage } from "./IPoolManagerStorage.sol";

interface IPoolManager is IMapleProxied, IPoolManagerStorage {

    /******************************************************************************************************************************/
    /*** Events                                                                                                                 ***/
    /******************************************************************************************************************************/

    /**
     *  @dev   Emitted when a new allowed lender is called.
     *  @param lender_ The address of the new lender.
     *  @param isValid_ Whether the new lender is valid.
     */
    event AllowedLenderSet(address indexed lender_, bool isValid_);

    /**
     *  @dev   Emitted when a collateral liquidations is triggered.
     *  @param loan_ The address of the loan.
     */
    event CollateralLiquidationTriggered(address indexed loan_);

    /**
     *  @dev   Emitted when a collateral liquidations is finished.
     *  @param loan_             The address of the loan.
     *  @param unrealizedLosses_ The amount of unrealized losses.
     */
    event CollateralLiquidationFinished(address indexed loan_, uint256 unrealizedLosses_);

    /**
     *  @dev   Emitted when cover is deposited.
     *  @param amount_ The amount of cover deposited.
     */
    event CoverDeposited(uint256 amount_);

    /**
     *  @dev   Emitted when cover is withdrawn.
     *  @param amount_ The amount of cover withdrawn.
     */
    event CoverWithdrawn(uint256 amount_);

    /**
     *  @dev   Emitted when a loan impairment is removed.
     *  @param loan_ The address of the loan.
     */
    event LoanImpairmentRemoved(address indexed loan_);

    /**
     *  @dev   Emitted when a loan impairment is triggered.
     *  @param loan_              The address of the loan.
     *  @param newPaymentDueDate_ The new payment due date.
     */
    event LoanImpaired(address indexed loan_, uint256 newPaymentDueDate_);

    /**
     *  @dev   Emitted when a new management fee rate is set.
     *  @param managementFeeRate_ The amount of management fee rate.
     */
    event DelegateManagementFeeRateSet(uint256 managementFeeRate_);

    /**
     *  @dev   Emitted when a new loan manager is added.
     *  @param loanManager_ The address of the new loan manager.
     */
    event LoanManagerAdded(address indexed loanManager_);

    /**
     *  @dev   Emitted when a new liquidity cap is set.
     *  @param liquidityCap_ The value of liquidity cap.
     */
    event LiquidityCapSet(uint256 liquidityCap_);

    /**
     *  @dev   Emitted when a new loan is funded.
     *  @param loan_        The address of the loan.
     *  @param loanManager_ The address of the loan manager.
     *  @param amount_      The amount funded to the loan.
     */
    event LoanFunded(address indexed loan_, address indexed loanManager_, uint256 amount_);

    /**
     *  @dev   Emitted when a new loan manager is removed.
     *  @param loanManager_ The address of the new loan manager.
     */
    event LoanManagerRemoved(address indexed loanManager_);

    /**
     *  @dev   Emitted when a loan is refinanced.
     *  @param loan_              Loan to be refinanced.
     *  @param refinancer_        The address of the refinancer.
     *  @param deadline_          The new deadline to execute the refinance.
     *  @param calls_             The encoded calls to set new loan terms.
     *  @param principalIncrease_ The amount of principal increase.
     */
    event LoanRefinanced(address indexed loan_, address refinancer_, uint256 deadline_, bytes[] calls_, uint256 principalIncrease_);

    /**
     *  @dev Emitted when a pool is open to public.
     */
    event OpenToPublic();

    /**
     *  @dev   Emitted when the pending pool delegate accepts the ownership transfer.
     *  @param previousDelegate_ The address of the previous delegate.
     *  @param newDelegate_      The address of the new delegate.
     */
    event PendingDelegateAccepted(address indexed previousDelegate_, address indexed newDelegate_);

    /**
     *  @dev   Emitted when the pending pool delegate is set.
     *  @param previousDelegate_ The address of the previous delegate.
     *  @param newDelegate_      The address of the new delegate.
     */
    event PendingDelegateSet(address indexed previousDelegate_, address indexed newDelegate_);

    /**
     *  @dev   Emitted when the pool is configured the pool.
     *  @param loanManager_               The address of the new loan manager.
     *  @param withdrawalManager_         The address of the withdrawal manager.
     *  @param liquidityCap_              The new liquidity cap.
     *  @param delegateManagementFeeRate_ The management fee rate.
     */
    event PoolConfigured(address loanManager_, address withdrawalManager_, uint256 liquidityCap_, uint256 delegateManagementFeeRate_);

    /**
     *  @dev   Emitted when a redemption of shares from the pool is processed.
     *  @param owner_            The owner of the shares.
     *  @param redeemableShares_ The amount of redeemable shares.
     *  @param resultingAssets_  The amount of assets redeemed.
     */
    event RedeemProcessed(address indexed owner_, uint256 redeemableShares_, uint256 resultingAssets_);

    /**
     *  @dev   Emitted when a redemption of shares from the pool is requested.
     *  @param owner_  The owner of the shares.
     *  @param shares_ The amount of redeemable shares.
     */
    event RedeemRequested(address indexed owner_, uint256 shares_);

    /**
     *  @dev   Emitted when a pool is sets to be active or inactive.
     *  @param active_ Whether the pool is active.
     */
    event SetAsActive(bool active_);

    /**
     *  @dev   Emitted when shares are removed from the pool.
     *  @param owner_  The address of the owner of the shares.
     *  @param shares_ The amount of shares removed.
     */
    event SharesRemoved(address indexed owner_, uint256 shares_);

    /**
     *  @dev   Emitted when the withdrawal manager is set.
     *  @param withdrawalManager_ The address of the withdrawal manager.
     */
    event WithdrawalManagerSet(address indexed withdrawalManager_);

    /**
     *  @dev   Emitted when withdrawal of assets from the pool is processed.
     *  @param owner_            The owner of the assets.
     *  @param redeemableShares_ The amount of redeemable shares.
     *  @param resultingAssets_  The amount of assets redeemed.
     */
    event WithdrawalProcessed(address indexed owner_, uint256 redeemableShares_, uint256 resultingAssets_);

    /******************************************************************************************************************************/
    /*** Ownership Transfer Functions                                                                                           ***/
    /******************************************************************************************************************************/

    /**
     *  @dev Accepts the role of pool delegate.
     */
    function acceptPendingPoolDelegate() external;

    /**
     *  @dev   Sets an address as the pending pool delegate.
     *  @param pendingPoolDelegate_ The address of the new pool delegate.
     */
    function setPendingPoolDelegate(address pendingPoolDelegate_) external;

    /******************************************************************************************************************************/
    /*** Administrative Functions                                                                                               ***/
    /******************************************************************************************************************************/

    /**
     *  @dev   Configures the pool.
     *  @param loanManager_       The address of the new loan manager.
     *  @param withdrawalManager_ The address of the withdrawal manager.
     *  @param liquidityCap_      The new liquidity cap.
     *  @param managementFee_     The management fee rate.
     */
    function configure(address loanManager_, address withdrawalManager_, uint256 liquidityCap_, uint256 managementFee_) external;

    /**
     *  @dev   Adds a new loan manager.
     *  @param loanManager_ The address of the new loan manager.
     */
    function addLoanManager(address loanManager_) external;

    /**
     *  @dev   Removes a loan manager.
     *  @param loanManager_ The address of the new loan manager.
     */
    function removeLoanManager(address loanManager_) external;

    /**
     *  @dev   Sets a the pool to be active or inactive.
     *  @param active_ Whether the pool is active.
     */
    function setActive(bool active_) external;

    /**
     *  @dev   Sets a new lender as valid or not.
     *  @param lender_  The address of the new lender.
     *  @param isValid_ Whether the new lender is valid.
     */
    function setAllowedLender(address lender_, bool isValid_) external;

    /**
     *  @dev   Sets the allowed slippage for an asset on a loanManager.
     *  @param loanManager_     The address of the loanManager to set the slippage for.
     *  @param collateralAsset_ The address of the collateral asset.
     *  @param allowedSlippage_ The new allowed slippage.
     */
    function setAllowedSlippage(address loanManager_, address collateralAsset_, uint256 allowedSlippage_) external;

    /**
     *  @dev   Sets the value for liquidity cap.
     *  @param liquidityCap_ The value for liquidity cap.
     */
    function setLiquidityCap(uint256 liquidityCap_) external;

    /**
     *  @dev   Sets the value for the delegate management fee rate.
     *  @param delegateManagementFeeRate_ The value for the delegate management fee rate.
     */
    function setDelegateManagementFeeRate(uint256 delegateManagementFeeRate_) external;

    /**
     *  @dev   Sets the minimum ratio for an asset on a loanManager.
     *  @param loanManager_     The address of the loan Manager to set the ratio for.
     *  @param collateralAsset_ The address of the collateral asset.
     *  @param minRatio_        The new minimum ratio to set.
     */
    function setMinRatio(address loanManager_, address collateralAsset_, uint256 minRatio_) external;

    /**
     *  @dev Sets pool open to public depositors.
     */
    function setOpenToPublic() external;

    /**
     *  @dev   Sets the address of the withdrawal manager.
     *  @param withdrawalManager_ The address of the withdrawal manager.
     */
    function setWithdrawalManager(address withdrawalManager_) external;

    /******************************************************************************************************************************/
    /*** Loan Functions                                                                                                         ***/
    /******************************************************************************************************************************/

    /**
     *  @dev   Accepts new loan terms triggering a loan refinance.
     *  @param loan_              Loan to be refinanced.
     *  @param refinancer_        The address of the refinancer.
     *  @param deadline_          The new deadline to execute the refinance.
     *  @param calls_             The encoded calls to set new loan terms.
     *  @param principalIncrease_ The amount of principal increase.
     */
    function acceptNewTerms(
        address loan_,
        address refinancer_,
        uint256 deadline_,
        bytes[] calldata calls_,
        uint256 principalIncrease_
    ) external;

    function fund(uint256 principal_, address loan_, address loanManager_) external;

    /******************************************************************************************************************************/
    /*** Liquidation Functions                                                                                                  ***/
    /******************************************************************************************************************************/

    /**
     *  @dev   Finishes the collateral liquidation
     *  @param loan_ Loan that had its collateral liquidated.
     */
    function finishCollateralLiquidation(address loan_) external;

    /**
     *  @dev   Removes the loan impairment for a loan.
     *  @param loan_ Loan to remove the loan impairment.
     */
    function removeLoanImpairment(address loan_) external;

    /**
     *  @dev   Triggers the default of a loan.
     *  @param loan_              Loan to trigger the default.
     *  @param liquidatorFactory_ Factory used to deploy the liquidator.
     */
    function triggerDefault(address loan_, address liquidatorFactory_) external;

    /**
     *  @dev   Triggers the loan impairment for a loan.
     *  @param loan_ Loan to trigger the loan impairment.
     */
    function impairLoan(address loan_) external;

    /******************************************************************************************************************************/
    /*** Exit Functions                                                                                                         ***/
    /******************************************************************************************************************************/

    /**
     *  @dev    Processes a redemptions of shares for assets from the pool.
     *  @param  shares_           The amount of shares to redeem.
     *  @param  owner_            The address of the owner of the shares.
     *  @param  sender_           The address of the sender of the redeem call.
     *  @return redeemableShares_ The amount of shares redeemed.
     *  @return resultingAssets_  The amount of assets withdrawn.
     */
    function processRedeem(uint256 shares_, address owner_, address sender_) external returns (uint256 redeemableShares_, uint256 resultingAssets_);

    /**
     *  @dev    Processes a redemptions of shares for assets from the pool.
     *  @param  assets_           The amount of assets to withdraw.
     *  @param  owner_            The address of the owner of the shares.
     *  @param  sender_           The address of the sender of the withdraw call.
     *  @return redeemableShares_ The amount of shares redeemed.
     *  @return resultingAssets_  The amount of assets withdrawn.
     */
    function processWithdraw(uint256 assets_, address owner_, address sender_) external returns (uint256 redeemableShares_, uint256 resultingAssets_);

    /**
     *  @dev    Requests a redemption of shares from the pool.
     *  @param  shares_         The amount of shares to redeem.
     *  @param  owner_          The address of the owner of the shares.
     *  @return sharesReturned_ The amount of shares withdrawn.
     */
    function removeShares(uint256 shares_, address owner_) external returns (uint256 sharesReturned_);

    /**
     *  @dev   Requests a redemption of shares from the pool.
     *  @param shares_ The amount of shares to redeem.
     *  @param owner_  The address of the owner of the shares.
     *  @param sender_ The address of the sender of the shares.
     */
    function requestRedeem(uint256 shares_, address owner_, address sender_) external;

    /**
     *  @dev   Requests a withdrawal of assets from the pool.
     *  @param shares_ The amount of shares to redeem.
     *  @param assets_ The amount of assets to withdraw.
     *  @param owner_  The address of the owner of the shares.
     *  @param sender_ The address of the sender of the shares.
     */
     function requestWithdraw(uint256 shares_, uint256 assets_, address owner_, address sender_) external;

    /******************************************************************************************************************************/
    /*** Cover Functions                                                                                                        ***/
    /******************************************************************************************************************************/

    /**
     *  @dev   Deposits cover into the pool.
     *  @param amount_ The amount of cover to deposit.
     */
    function depositCover(uint256 amount_) external;

    /**
     *  @dev  Withdraws cover from the pool.
     *  @param amount_    The amount of cover to withdraw.
     *  @param recipient_ The address of the recipient.
     */
    function withdrawCover(uint256 amount_, address recipient_) external;

    /******************************************************************************************************************************/
    /*** LP Token View Functions                                                                                                ***/
    /******************************************************************************************************************************/

    /**
     *  @dev    Gets the information of escrowed shares.
     *  @param  owner_        The address of the owner of the shares.
     *  @param  shares_       The amount of shares to get the information of.
     *  @return escorwShares_ The amount of escrowed shares.
     *  @return destination_  The address of the destination.
     */
    function getEscrowParams(address owner_, uint256 shares_) external view returns (uint256 escorwShares_, address destination_);

    /**
     *  @dev    Returns the amount of exit shares for the input amount.
     *  @param  amount_  Address of the account.
     *  @return shares_  Amount of shares able to be exited.
     */
    function convertToExitShares(uint256 amount_) external view returns (uint256 shares_);

    /**
     *  @dev   Gets the amount of assets that can be deposited.
     *  @param receiver_  The address to check the deposit for.
     *  @param maxAssets_ The maximum amount assets to deposit.
     */
    function maxDeposit(address receiver_) external view returns (uint256 maxAssets_);

    /**
     *  @dev   Gets the amount of shares that can be minted.
     *  @param receiver_  The address to check the mint for.
     *  @param maxShares_ The maximum amount shares to mint.
     */
    function maxMint(address receiver_) external view returns (uint256 maxShares_);

    /**
     *  @dev   Gets the amount of shares that can be redeemed.
     *  @param owner_     The address to check the redemption for.
     *  @param maxShares_ The maximum amount shares to redeem.
     */
    function maxRedeem(address owner_) external view returns (uint256 maxShares_);

    /**
     *  @dev   Gets the amount of assets that can be withdrawn.
     *  @param owner_     The address to check the withdraw for.
     *  @param maxAssets_ The maximum amount assets to withdraw.
     */
    function maxWithdraw(address owner_) external view returns (uint256 maxAssets_);

    /**
     *  @dev    Gets the amount of shares that can be redeemed.
     *  @param  owner_   The address to check the redemption for.
     *  @param  shares_  The amount of requested shares to redeem.
     *  @return assets_  The amount of assets that will be returned for `shares_`.
     */
    function previewRedeem(address owner_, uint256 shares_) external view returns (uint256 assets_);

    /**
     *  @dev    Gets the amount of assets that can be redeemed.
     *  @param  owner_   The address to check the redemption for.
     *  @param  assets_  The amount of requested shares to redeem.
     *  @return shares_  The amount of assets that will be returned for `assets_`.
     */
    function previewWithdraw(address owner_, uint256 assets_) external view returns (uint256 shares_);

    /******************************************************************************************************************************/
    /*** View Functions                                                                                                         ***/
    /******************************************************************************************************************************/

    /**
     *  @dev    Checks if a scheduled call can be executed.
     *  @param  functionId_   The function to check.
     *  @param  caller_       The address of the caller.
     *  @param  data_         The data of the call.
     *  @return canCall_      True if the call can be executed, false otherwise.
     *  @return errorMessage_ The error message if the call cannot be executed.
     */
    function canCall(bytes32 functionId_, address caller_, bytes memory data_) external view returns (bool canCall_, string memory errorMessage_);

    /**
     *  @dev    Gets the address of the globals.
     *  @return globals_ The address of the globals.
     */
    function globals() external view returns (address globals_);

    /**
     *  @dev    Gets the address of the governor.
     *  @return governor_ The address of the governor.
     */
    function governor() external view returns (address governor_);

    /**
     *  @dev    Returns if pool has sufficient cover.
     *  @return hasSufficientCover_ True if pool has sufficient cover.
     */
    function hasSufficientCover() external view returns (bool hasSufficientCover_);

    /**
     *  @dev    Returns the amount of total assets.
     *  @return totalAssets_ Amount of of total assets.
     */
    function totalAssets() external view returns (uint256 totalAssets_);

    /**
     *  @dev    Returns the amount unrealized losses.
     *  @return unrealizedLosses_ Amount of unrealized losses.
     */
    function unrealizedLosses() external view returns (uint256 unrealizedLosses_);

}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

interface IPoolManagerInitializer {

    event Initialized(address owner_, address asset_, address pool_);

    function decodeArguments(bytes calldata encodedArguments_) external pure
        returns (address owner_, address asset_, uint256 initialSupply_, string memory name_, string memory symbol_);

    function encodeArguments(address owner_, address asset_, uint256 initialSupply_, string memory name_, string memory symbol_) external pure
        returns (bytes memory encodedArguments_);

}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

interface IPoolManagerStorage {

    /**
     *  @dev    Returns whether or not a pool is active.
     *  @return active_ True if the pool is active.
     */
    function active() external view returns (bool active_);

    /**
     *  @dev    Gets the address of the funds asset.
     *  @return asset_ The address of the funds asset.
     */
    function asset() external view returns (address asset_);

    /**
     *  @dev    Returns whether or not a pool is configured.
     *  @return configured_ True if the pool is configured.
     */
    function configured() external view returns (bool configured_);

    /**
     *  @dev    Returns whether or not the given address is a loan manager.
     *  @param  loan_          The address of the loan.
     *  @return isLoanManager_ True if the address is a loan manager.
     */
    function isLoanManager(address loan_) external view returns (bool isLoanManager_);

    /**
     *  @dev    Returns whether or not the given address is a valid lender.
     *  @param  lender_        The address of the lender.
     *  @return isValidLender_ True if the address is a valid lender.
     */
    function isValidLender(address lender_) external view returns (bool isValidLender_);

    /**
     *  @dev    Gets the address of the loan manager in the list.
     *  @param  index_       The index to get the address of.
     *  @return loanManager_ The address in the list.
     */
    function loanManagerList(uint256 index_) external view returns (address loanManager_);

    /**
     *  @dev    Gets the liquidity cap for the pool.
     *  @return liquidityCap_ The liquidity cap for the pool.
     */
    function liquidityCap() external view returns (uint256 liquidityCap_);

    /**
     *  @dev    Gets the delegate management fee rate.
     *  @return delegateManagementFeeRate_ The value for the delegate management fee rate.
     */
    function delegateManagementFeeRate() external view returns (uint256 delegateManagementFeeRate_);

    /**
     *  @dev    Returns whether or not a pool is open to public deposits.
     *  @return openToPublic_ True if the pool is open to public deposits.
     */
    function openToPublic() external view returns (bool openToPublic_);

    /**
     *  @dev    Gets the address of the pending pool delegate.
     *  @return pendingPoolDelegate_ The address of the pending pool delegate.
     */
    function pendingPoolDelegate() external view returns (address pendingPoolDelegate_);

    /**
     *  @dev    Gets the address of the pool.
     *  @return pool_ The address of the pool.
     */
    function pool() external view returns (address pool_);

    /**
     *  @dev    Gets the address of the pool delegate.
     *  @return poolDelegate_ The address of the pool delegate.
     */
    function poolDelegate() external view returns (address poolDelegate_);

    /**
     *  @dev    Gets the address of the pool delegate cover.
     *  @return poolDelegateCover_ The address of the pool delegate cover.
     */
    function poolDelegateCover() external view returns (address poolDelegateCover_);

    /**
     *  @dev    Gets the address of the withdrawal manager.
     *  @return withdrawalManager_ The address of the withdrawal manager.
     */
    function withdrawalManager() external view returns (address withdrawalManager_);

}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

interface IERC20Like {

    function balanceOf(address account_) external view returns (uint256 balance_);

    function decimals() external view returns (uint8 decimals_);

    function totalSupply() external view returns (uint256 totalSupply_);

}

interface ILoanManagerLike {

    function acceptNewTerms(
        address loan_,
        address refinancer_,
        uint256 deadline_,
        bytes[] calldata calls_
    ) external;

    function assetsUnderManagement() external view returns (uint256 assetsUnderManagement_);

    function claim(address loan_, bool hasSufficientCover_) external;

    function finishCollateralLiquidation(address loan_) external returns (uint256 remainingLosses_, uint256 serviceFee_);

    function fund(address loan_) external;

    function removeLoanImpairment(address loan_, bool isGovernor_) external;

    function setAllowedSlippage(address collateralAsset_, uint256 allowedSlippage_) external;

    function setMinRatio(address collateralAsset_, uint256 minRatio_) external;

    function impairLoan(address loan_, bool isGovernor_) external;

    function triggerDefault(address loan_, address liquidatorFactory_) external returns (bool liquidationComplete_, uint256 remainingLosses_, uint256 platformFees_);

    function unrealizedLosses() external view returns (uint256 unrealizedLosses_);

}

interface ILoanManagerInitializerLike {

    function encodeArguments(address pool_) external pure returns (bytes memory calldata_);

    function decodeArguments(bytes calldata calldata_) external pure returns (address pool_);

}

interface ILiquidatorLike {

    function collateralRemaining() external view returns (uint256 collateralRemaining_);

    function liquidatePortion(uint256 swapAmount_, uint256 maxReturnAmount_, bytes calldata data_) external;

    function pullFunds(address token_, address destination_, uint256 amount_) external;

    function setCollateralRemaining(uint256 collateralAmount_) external;

}

interface IMapleGlobalsLike {

    function bootstrapMint(address asset_) external view returns (uint256 bootstrapMint_);

    function getLatestPrice(address asset_) external view returns (uint256 price_);

    function governor() external view returns (address governor_);

    function isBorrower(address account_) external view returns (bool isBorrower_);

    function isFactory(bytes32 factoryId_, address factory_) external view returns (bool isValid_);

    function isPoolAsset(address asset_) external view returns (bool isPoolAsset_);

    function isPoolDelegate(address account_) external view returns (bool isPoolDelegate_);

    function isPoolDeployer(address poolDeployer_) external view returns (bool isPoolDeployer_);

    function isValidScheduledCall(address caller_, address contract_, bytes32 functionId_, bytes calldata callData_) external view returns (bool isValid_);

    function platformManagementFeeRate(address poolManager_) external view returns (uint256 platformManagementFeeRate_);

    function maxCoverLiquidationPercent(address poolManager_) external view returns (uint256 maxCoverLiquidationPercent_);

    function migrationAdmin() external view returns (address migrationAdmin_);

    function minCoverAmount(address poolManager_) external view returns (uint256 minCoverAmount_);

    function mapleTreasury() external view returns (address mapleTreasury_);

    function ownedPoolManager(address poolDelegate_) external view returns (address poolManager_);

    function protocolPaused() external view returns (bool protocolPaused_);

    function transferOwnedPoolManager(address fromPoolDelegate_, address toPoolDelegate_) external;

    function unscheduleCall(address caller_, bytes32 functionId_, bytes calldata callData_) external;

}

interface IMapleLoanLike {

    function acceptLender() external;

    function acceptNewTerms(address refinancer_, uint256 deadline_, bytes[] calldata calls_) external returns (bytes32 refinanceCommitment_);

    function batchClaimFunds(uint256[] memory amounts_, address[] memory destinations_) external;

    function borrower() external view returns (address borrower_);

    function claimFunds(uint256 amount_, address destination_) external;

    function collateral() external view returns (uint256 collateral);

    function collateralAsset() external view returns(address asset_);

    function feeManager() external view returns (address feeManager_);

    function fundsAsset() external view returns (address asset_);

    function fundLoan(address lender_) external returns (uint256 fundsLent_);

    function getClosingPaymentBreakdown() external view returns (
        uint256 principal_,
        uint256 interest_,
        uint256 delegateServiceFee_,
        uint256 platformServiceFee_
    );

    function getNextPaymentDetailedBreakdown() external view returns (
        uint256 principal_,
        uint256[3] memory interest_,
        uint256[2] memory fees_
    );

    function getNextPaymentBreakdown() external view returns (
        uint256 principal_,
        uint256 interest_,
        uint256 fees_
    );

    function getUnaccountedAmount(address asset_) external view returns (uint256 unaccountedAmount_);

    function gracePeriod() external view returns (uint256 gracePeriod_);

    function interestRate() external view returns (uint256 interestRate_);

    function isImpaired() external view returns (bool isImpaired_);

    function lateFeeRate() external view returns (uint256 lateFeeRate_);

    function lender() external view returns (address lender_);

    function nextPaymentDueDate() external view returns (uint256 nextPaymentDueDate_);

    function originalNextPaymentDueDate() external view returns (uint256 originalNextPaymentDueDate_);

    function paymentInterval() external view returns (uint256 paymentInterval_);

    function paymentsRemaining() external view returns (uint256 paymentsRemaining_);

    function principal() external view returns (uint256 principal_);

    function principalRequested() external view returns (uint256 principalRequested_);

    function refinanceInterest() external view returns (uint256 refinanceInterest_);

    function removeLoanImpairment() external;

    function repossess(address destination_) external returns (uint256 collateralRepossessed_, uint256 fundsRepossessed_);

    function setPendingLender(address pendingLender_) external;

    function skim(address token_, address destination_) external returns (uint256 skimmed_);

    function impairLoan() external;

    function unimpairedPaymentDueDate() external view returns (uint256 unimpairedPaymentDueDate_);

}

interface IMapleLoanV3Like {

    function acceptLender() external;

    function getNextPaymentBreakdown() external view returns (uint256 principal_, uint256 interest_, uint256, uint256);

    function nextPaymentDueDate() external view returns (uint256 nextPaymentDueDate_);

    function paymentInterval() external view returns (uint256 paymentInterval_);

    function principal() external view returns (uint256 principal_);

    function refinanceInterest() external view returns (uint256 refinanceInterest_);

    function setPendingLender(address pendingLender_) external;

}

interface IMapleProxyFactoryLike {

    function mapleGlobals() external view returns (address mapleGlobals_);

}

interface ILoanFactoryLike {

    function isLoan(address loan_) external view returns (bool isLoan_);

}

interface IPoolDelegateCoverLike {

    function moveFunds(uint256 amount_, address recipient_) external;

}

interface IPoolLike is IERC20Like {

    function allowance(address owner_, address spender_) external view returns (uint256 allowance_);

    function asset() external view returns (address asset_);

    function convertToAssets(uint256 shares_) external view returns (uint256 assets_);

    function convertToExitAssets(uint256 shares_) external view returns (uint256 assets_);

    function convertToExitShares(uint256 assets_) external view returns (uint256 shares_);

    function deposit(uint256 assets_, address receiver_) external returns (uint256 shares_);

    function manager() external view returns (address manager_);

    function previewDeposit(uint256 assets_) external view returns (uint256 shares_);

    function previewMint(uint256 shares_) external view returns (uint256 assets_);

    function processExit(uint256 shares_, uint256 assets_, address receiver_, address owner_) external;

    function redeem(uint256 shares_, address receiver_, address owner_) external returns (uint256 assets_);

}

interface IPoolManagerLike {

    function addLoanManager(address loanManager_) external;

    function canCall(bytes32 functionId_, address caller_, bytes memory data_) external view returns (bool canCall_, string memory errorMessage_);

    function convertToExitShares(uint256 assets_) external view returns (uint256 shares_);

    function claim(address loan_) external;

    function delegateManagementFeeRate() external view returns (uint256 delegateManagementFeeRate_);

    function fund(uint256 principalAmount_, address loan_, address loanManager_) external;

    function getEscrowParams(address owner_, uint256 shares_) external view returns (uint256 escrowShares_, address escrow_);

    function globals() external view returns (address globals_);

    function hasSufficientCover() external view returns (bool hasSufficientCover_);

    function loanManager() external view returns (address loanManager_);

    function maxDeposit(address receiver_) external view returns (uint256 maxAssets_);

    function maxMint(address receiver_) external view returns (uint256 maxShares_);

    function maxRedeem(address owner_) external view returns (uint256 maxShares_);

    function maxWithdraw(address owner_) external view returns (uint256 maxAssets_);

    function previewRedeem(address owner_, uint256 shares_) external view returns (uint256 assets_);

    function previewWithdraw(address owner_, uint256 assets_) external view returns (uint256 shares_);

    function processRedeem(uint256 shares_, address owner_, address sender_) external returns (uint256 redeemableShares_, uint256 resultingAssets_);

    function processWithdraw(uint256 assets_, address owner_, address sender_) external returns (uint256 redeemableShares_, uint256 resultingAssets_);

    function poolDelegate() external view returns (address poolDelegate_);

    function poolDelegateCover() external view returns (address poolDelegateCover_);

    function removeLoanManager(address loanManager_) external;

    function removeShares(uint256 shares_, address owner_) external returns (uint256 sharesReturned_);

    function requestRedeem(uint256 shares_, address owner_, address sender_) external;

    function requestWithdraw(uint256 shares_, uint256 assets_, address owner_, address sender_) external;

    function setWithdrawalManager(address withdrawalManager_) external;

    function totalAssets() external view returns (uint256 totalAssets_);

    function unrealizedLosses() external view returns (uint256 unrealizedLosses_);

    function withdrawalManager() external view returns (address withdrawalManager_);

}

interface IWithdrawalManagerInitializerLike {

    function encodeArguments(address pool_, uint256 cycleDuration_, uint256 windowDuration_) external pure returns (bytes memory calldata_);

    function decodeArguments(bytes calldata calldata_) external pure returns (address pool_, uint256 cycleDuration_, uint256 windowDuration_);

}

interface IWithdrawalManagerLike {

    function addShares(uint256 shares_, address owner_) external;

    function isInExitWindow(address owner_) external view returns (bool isInExitWindow_);

    function lockedLiquidity() external view returns (uint256 lockedLiquidity_);

    function lockedShares(address owner_) external view returns (uint256 lockedShares_);

    function previewRedeem(address owner_, uint256 shares) external view returns (uint256 redeemableShares, uint256 resultingAssets_);

    function previewWithdraw(address owner_, uint256 assets_) external view returns (uint256 redeemableAssets_, uint256 resultingShares_);

    function processExit(uint256 shares_, address account_) external returns (uint256 redeemableShares_, uint256 resultingAssets_);

    function removeShares(uint256 shares_, address owner_) external returns (uint256 sharesReturned_);

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

import { IProxied } from "../../modules/proxy-factory/contracts/interfaces/IProxied.sol";

/// @title A Maple implementation that is to be proxied, must implement IMapleProxied.
interface IMapleProxied is IProxied {

    /**
     *  @dev   The instance was upgraded.
     *  @param toVersion_ The new version of the loan.
     *  @param arguments_ The upgrade arguments, if any.
     */
    event Upgraded(uint256 toVersion_, bytes arguments_);

    /**
     *  @dev   Upgrades a contract implementation to a specific version.
     *         Access control logic critical since caller can force a selfdestruct via a malicious `migrator_` which is delegatecalled.
     *  @param toVersion_ The version to upgrade to.
     *  @param arguments_ Some encoded arguments to use for the upgrade.
     */
    function upgrade(uint256 toVersion_, bytes calldata arguments_) external;

}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.7;

import { IDefaultImplementationBeacon } from "../../modules/proxy-factory/contracts/interfaces/IDefaultImplementationBeacon.sol";

/// @title A Maple factory for Proxy contracts that proxy MapleProxied implementations.
interface IMapleProxyFactory is IDefaultImplementationBeacon {

    /******************************************************************************************************************************/
    /*** Events                                                                                                                  ***/
    /******************************************************************************************************************************/

    /**
     *  @dev   A default version was set.
     *  @param version_ The default version.
     */
    event DefaultVersionSet(uint256 indexed version_);

    /**
     *  @dev   A version of an implementation, at some address, was registered, with an optional initializer.
     *  @param version_               The version registered.
     *  @param implementationAddress_ The address of the implementation.
     *  @param initializer_           The address of the initializer, if any.
     */
    event ImplementationRegistered(uint256 indexed version_, address indexed implementationAddress_, address indexed initializer_);

    /**
     *  @dev   A proxy contract was deployed with some initialization arguments.
     *  @param version_                 The version of the implementation being proxied by the deployed proxy contract.
     *  @param instance_                The address of the proxy contract deployed.
     *  @param initializationArguments_ The arguments used to initialize the proxy contract, if any.
     */
    event InstanceDeployed(uint256 indexed version_, address indexed instance_, bytes initializationArguments_);

    /**
     *  @dev   A instance has upgraded by proxying to a new implementation, with some migration arguments.
     *  @param instance_           The address of the proxy contract.
     *  @param fromVersion_        The initial implementation version being proxied.
     *  @param toVersion_          The new implementation version being proxied.
     *  @param migrationArguments_ The arguments used to migrate, if any.
     */
    event InstanceUpgraded(address indexed instance_, uint256 indexed fromVersion_, uint256 indexed toVersion_, bytes migrationArguments_);

    /**
     *  @dev   The MapleGlobals was set.
     *  @param mapleGlobals_ The address of a Maple Globals contract.
     */
    event MapleGlobalsSet(address indexed mapleGlobals_);

    /**
     *  @dev   An upgrade path was disabled, with an optional migrator contract.
     *  @param fromVersion_ The starting version of the upgrade path.
     *  @param toVersion_   The destination version of the upgrade path.
     */
    event UpgradePathDisabled(uint256 indexed fromVersion_, uint256 indexed toVersion_);

    /**
     *  @dev   An upgrade path was enabled, with an optional migrator contract.
     *  @param fromVersion_ The starting version of the upgrade path.
     *  @param toVersion_   The destination version of the upgrade path.
     *  @param migrator_    The address of the migrator, if any.
     */
    event UpgradePathEnabled(uint256 indexed fromVersion_, uint256 indexed toVersion_, address indexed migrator_);

    /******************************************************************************************************************************/
    /*** State Variables                                                                                                        ***/
    /******************************************************************************************************************************/

    /**
     *  @dev The default version.
     */
    function defaultVersion() external view returns (uint256 defaultVersion_);

    /**
     *  @dev The address of the MapleGlobals contract.
     */
    function mapleGlobals() external view returns (address mapleGlobals_);

    /**
     *  @dev    Whether the upgrade is enabled for a path from a version to another version.
     *  @param  toVersion_   The initial version.
     *  @param  fromVersion_ The destination version.
     *  @return allowed_     Whether the upgrade is enabled.
     */
    function upgradeEnabledForPath(uint256 toVersion_, uint256 fromVersion_) external view returns (bool allowed_);

    /******************************************************************************************************************************/
    /*** State Changing Functions                                                                                               ***/
    /******************************************************************************************************************************/

    /**
     *  @dev    Deploys a new instance proxying the default implementation version, with some initialization arguments.
     *          Uses a nonce and `msg.sender` as a salt for the CREATE2 opcode during instantiation to produce deterministic addresses.
     *  @param  arguments_ The initialization arguments to use for the instance deployment, if any.
     *  @param  salt_      The salt to use in the contract creation process.
     *  @return instance_  The address of the deployed proxy contract.
     */
    function createInstance(bytes calldata arguments_, bytes32 salt_) external returns (address instance_);

    /**
     *  @dev   Enables upgrading from a version to a version of an implementation, with an optional migrator.
     *         Only the Governor can call this function.
     *  @param fromVersion_ The starting version of the upgrade path.
     *  @param toVersion_   The destination version of the upgrade path.
     *  @param migrator_    The address of the migrator, if any.
     */
    function enableUpgradePath(uint256 fromVersion_, uint256 toVersion_, address migrator_) external;

    /**
     *  @dev   Disables upgrading from a version to a version of a implementation.
     *         Only the Governor can call this function.
     *  @param fromVersion_ The starting version of the upgrade path.
     *  @param toVersion_   The destination version of the upgrade path.
     */
    function disableUpgradePath(uint256 fromVersion_, uint256 toVersion_) external;

    /**
     *  @dev   Registers the address of an implementation contract as a version, with an optional initializer.
     *         Only the Governor can call this function.
     *  @param version_               The version to register.
     *  @param implementationAddress_ The address of the implementation.
     *  @param initializer_           The address of the initializer, if any.
     */
    function registerImplementation(uint256 version_, address implementationAddress_, address initializer_) external;

    /**
     *  @dev   Sets the default version.
     *         Only the Governor can call this function.
     *  @param version_ The implementation version to set as the default.
     */
    function setDefaultVersion(uint256 version_) external;

    /**
     *  @dev   Sets the Maple Globals contract.
     *         Only the Governor can call this function.
     *  @param mapleGlobals_ The address of a Maple Globals contract.
     */
    function setGlobals(address mapleGlobals_) external;

    /**
     *  @dev   Upgrades the calling proxy contract's implementation, with some migration arguments.
     *  @param toVersion_ The implementation version to upgrade the proxy contract to.
     *  @param arguments_ The migration arguments, if any.
     */
    function upgradeInstance(uint256 toVersion_, bytes calldata arguments_) external;

    /******************************************************************************************************************************/
    /*** View Functions                                                                                                         ***/
    /******************************************************************************************************************************/

    /**
     *  @dev    Returns the deterministic address of a potential proxy, given some arguments and salt.
     *  @param  arguments_       The initialization arguments to be used when deploying the proxy.
     *  @param  salt_            The salt to be used when deploying the proxy.
     *  @return instanceAddress_ The deterministic address of a potential proxy.
     */
    function getInstanceAddress(bytes calldata arguments_, bytes32 salt_) external view returns (address instanceAddress_);

    /**
     *  @dev    Returns the address of an implementation version.
     *  @param  version_        The implementation version.
     *  @return implementation_ The address of the implementation.
     */
    function implementationOf(uint256 version_) external view returns (address implementation_);

    /**
     *  @dev    Returns if a given address has been deployed by this factory/
     *  @param  instance_   The address to check.
     *  @return isInstance_ A boolean indication if the address has been deployed by this factory.
     */
    function isInstance(address instance_) external view returns (bool isInstance_);

    /**
     *  @dev    Returns the address of a migrator contract for a migration path (from version, to version).
     *          If oldVersion_ == newVersion_, the migrator is an initializer.
     *  @param  oldVersion_ The old version.
     *  @param  newVersion_ The new version.
     *  @return migrator_   The address of a migrator contract.
     */
    function migratorForPath(uint256 oldVersion_, uint256 newVersion_) external view returns (address migrator_);

    /**
     *  @dev    Returns the version of an implementation contract.
     *  @param  implementation_ The address of an implementation contract.
     *  @return version_        The version of the implementation contract.
     */
    function versionOf(address implementation_) external view returns (uint256 version_);

}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.7;

/// @title An beacon that provides a default implementation for proxies, must implement IDefaultImplementationBeacon.
interface IDefaultImplementationBeacon {

    /// @dev The address of an implementation for proxies.
    function defaultImplementation() external view returns (address defaultImplementation_);

}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.7;

/// @title An implementation that is to be proxied, must implement IProxied.
interface IProxied {

    /**
     *  @dev The address of the proxy factory.
     */
    function factory() external view returns (address factory_);

    /**
     *  @dev The address of the implementation contract being proxied.
     */
    function implementation() external view returns (address implementation_);

    /**
     *  @dev   Modifies the proxy's implementation address.
     *  @param newImplementation_ The address of an implementation contract.
     */
    function setImplementation(address newImplementation_) external;

    /**
     *  @dev   Modifies the proxy's storage by delegate-calling a migrator contract with some arguments.
     *         Access control logic critical since caller can force a selfdestruct via a malicious `migrator_` which is delegatecalled.
     *  @param migrator_  The address of a migrator contract.
     *  @param arguments_ Some encoded arguments to use for the migration.
     */
    function migrate(address migrator_, bytes calldata arguments_) external;

}