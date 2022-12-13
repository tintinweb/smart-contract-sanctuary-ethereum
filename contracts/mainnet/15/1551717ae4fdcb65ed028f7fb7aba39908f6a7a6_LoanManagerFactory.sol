// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

import { IMapleProxyFactory } from "../../modules/maple-proxy-factory/contracts/MapleProxyFactory.sol";

interface ILoanManagerFactory is IMapleProxyFactory { }

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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

import { IMapleProxyFactory, MapleProxyFactory } from "../../modules/maple-proxy-factory/contracts/MapleProxyFactory.sol";

import { ILoanManagerFactory } from "../interfaces/ILoanManagerFactory.sol";
import { IMapleGlobalsLike }   from "../interfaces/Interfaces.sol";

contract LoanManagerFactory is ILoanManagerFactory, MapleProxyFactory {

    constructor(address globals_) MapleProxyFactory(globals_) { }

    function createInstance(bytes calldata arguments_, bytes32 salt_) override(IMapleProxyFactory, MapleProxyFactory) public returns (address instance_) {
        require(IMapleGlobalsLike(mapleGlobals).isPoolDeployer(msg.sender), "LMF:CI:NOT_DEPLOYER");

        instance_ = super.createInstance(arguments_, salt_);
    }

}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.7;

import { ProxyFactory } from "../modules/proxy-factory/contracts/ProxyFactory.sol";

import { IMapleGlobalsLike }  from "./interfaces/Interfaces.sol";
import { IMapleProxied }      from "./interfaces/IMapleProxied.sol";
import { IMapleProxyFactory } from "./interfaces/IMapleProxyFactory.sol";

/// @title A Maple factory for Proxy contracts that proxy MapleProxied implementations.
contract MapleProxyFactory is IMapleProxyFactory, ProxyFactory {

    address public override mapleGlobals;

    uint256 public override defaultVersion;

    mapping(address => bool) public override isInstance;

    mapping(uint256 => mapping(uint256 => bool)) public override upgradeEnabledForPath;

    constructor(address mapleGlobals_) {
        require(IMapleGlobalsLike(mapleGlobals = mapleGlobals_).governor() != address(0), "MPF:C:INVALID_GLOBALS");
    }

    modifier onlyGovernor() {
        require(msg.sender == IMapleGlobalsLike(mapleGlobals).governor(), "MPF:NOT_GOVERNOR");
        _;
    }

    modifier whenProtocolNotPaused() {
        require(!IMapleGlobalsLike(mapleGlobals).protocolPaused(), "MPF:PROTOCOL_PAUSED");
        _;
    }

    /******************************************************************************************************************************/
    /*** Admin Functions                                                                                                        ***/
    /******************************************************************************************************************************/

    function disableUpgradePath(uint256 fromVersion_, uint256 toVersion_) public override virtual onlyGovernor {
        require(fromVersion_ != toVersion_,                              "MPF:DUP:OVERWRITING_INITIALIZER");
        require(_registerMigrator(fromVersion_, toVersion_, address(0)), "MPF:DUP:FAILED");

        emit UpgradePathDisabled(fromVersion_, toVersion_);

        upgradeEnabledForPath[fromVersion_][toVersion_] = false;
    }

    function enableUpgradePath(uint256 fromVersion_, uint256 toVersion_, address migrator_) public override virtual onlyGovernor {
        require(fromVersion_ != toVersion_,                             "MPF:EUP:OVERWRITING_INITIALIZER");
        require(_registerMigrator(fromVersion_, toVersion_, migrator_), "MPF:EUP:FAILED");

        emit UpgradePathEnabled(fromVersion_, toVersion_, migrator_);

        upgradeEnabledForPath[fromVersion_][toVersion_] = true;
    }

    function registerImplementation(uint256 version_, address implementationAddress_, address initializer_) public override virtual onlyGovernor {
        // Version 0 reserved as "no version" since default `defaultVersion` is 0.
        require(version_ != uint256(0), "MPF:RI:INVALID_VERSION");

        emit ImplementationRegistered(version_, implementationAddress_, initializer_);

        require(_registerImplementation(version_, implementationAddress_), "MPF:RI:FAIL_FOR_IMPLEMENTATION");

        // Set migrator for initialization, which understood as fromVersion == toVersion.
        require(_registerMigrator(version_, version_, initializer_), "MPF:RI:FAIL_FOR_MIGRATOR");
    }

    function setDefaultVersion(uint256 version_) public override virtual onlyGovernor {
        // Version must be 0 (to disable creating new instances) or be registered.
        require(version_ == 0 || _implementationOf[version_] != address(0), "MPF:SDV:INVALID_VERSION");

        emit DefaultVersionSet(defaultVersion = version_);
    }

    function setGlobals(address mapleGlobals_) public override virtual onlyGovernor {
        require(IMapleGlobalsLike(mapleGlobals_).governor() != address(0), "MPF:SG:INVALID_GLOBALS");

        emit MapleGlobalsSet(mapleGlobals = mapleGlobals_);
    }

    /******************************************************************************************************************************/
    /*** Instance Functions                                                                                                     ***/
    /******************************************************************************************************************************/

    function createInstance(bytes calldata arguments_, bytes32 salt_) public override virtual whenProtocolNotPaused returns (address instance_) {
        bool success;
        ( success, instance_ ) = _newInstance(arguments_, keccak256(abi.encodePacked(arguments_, salt_)));
        require(success, "MPF:CI:FAILED");

        isInstance[instance_] = true;

        emit InstanceDeployed(defaultVersion, instance_, arguments_);
    }

    // NOTE: The implementation proxied by the instance defines the access control logic for its own upgrade.
    function upgradeInstance(uint256 toVersion_, bytes calldata arguments_) public override virtual whenProtocolNotPaused {
        uint256 fromVersion = _versionOf[IMapleProxied(msg.sender).implementation()];

        require(upgradeEnabledForPath[fromVersion][toVersion_], "MPF:UI:NOT_ALLOWED");

        emit InstanceUpgraded(msg.sender, fromVersion, toVersion_, arguments_);

        require(_upgradeInstance(msg.sender, toVersion_, arguments_), "MPF:UI:FAILED");
    }

    /******************************************************************************************************************************/
    /*** View Functions                                                                                                         ***/
    /******************************************************************************************************************************/

    function getInstanceAddress(bytes calldata arguments_, bytes32 salt_) public view override virtual returns (address instanceAddress_) {
        return _getDeterministicProxyAddress(keccak256(abi.encodePacked(arguments_, salt_)));
    }

    function implementationOf(uint256 version_) public view override virtual returns (address implementation_) {
        return _implementationOf[version_];
    }

    function defaultImplementation() external view override returns (address defaultImplementation_) {
        return _implementationOf[defaultVersion];
    }

    function migratorForPath(uint256 oldVersion_, uint256 newVersion_) public view override virtual returns (address migrator_) {
        return _migratorForPath[oldVersion_][newVersion_];
    }

    function versionOf(address implementation_) public view override virtual returns (uint256 version_) {
        return _versionOf[implementation_];
    }

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

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.7;

interface IMapleGlobalsLike {

    /// @dev The address of the Governor responsible for management of global Maple variables.
    function governor() external view returns (address governor_);

    function protocolPaused() external view returns (bool protocolPaused_);

}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.7;

import { IDefaultImplementationBeacon } from "./interfaces/IDefaultImplementationBeacon.sol";

import { SlotManipulatable } from "./SlotManipulatable.sol";

/// @title A completely transparent, and thus interface-less, proxy contract.
contract Proxy is SlotManipulatable {

    /// @dev Storage slot with the address of the current factory. `keccak256('eip1967.proxy.factory') - 1`.
    bytes32 private constant FACTORY_SLOT = bytes32(0x7a45a402e4cb6e08ebc196f20f66d5d30e67285a2a8aa80503fa409e727a4af1);

    /// @dev Storage slot with the address of the current factory. `keccak256('eip1967.proxy.implementation') - 1`.
    bytes32 private constant IMPLEMENTATION_SLOT = bytes32(0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc);

    /**
     *  @dev   The constructor requires at least one of `factory_` or `implementation_`.
     *         If an implementation is not provided, the factory is treated as an IDefaultImplementationBeacon to fetch the default implementation.
     *  @param factory_        The address of a proxy factory, if any.
     *  @param implementation_ The address of the implementation contract being proxied, if any.
     */
    constructor(address factory_, address implementation_) {
        _setSlotValue(FACTORY_SLOT, bytes32(uint256(uint160(factory_))));

        // If the implementation is empty, fetch it from the factory, which can act as a beacon.
        address implementation = implementation_ == address(0) ? IDefaultImplementationBeacon(factory_).defaultImplementation() : implementation_;

        require(implementation != address(0));

        _setSlotValue(IMPLEMENTATION_SLOT, bytes32(uint256(uint160(implementation))));
    }

    fallback() payable external virtual {
        bytes32 implementation = _getSlotValue(IMPLEMENTATION_SLOT);

        require(address(uint160(uint256(implementation))).code.length != uint256(0));

        assembly {
            calldatacopy(0, 0, calldatasize())

            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            returndatacopy(0, 0, returndatasize())

            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.7;

import { IProxied } from "./interfaces/IProxied.sol";

import { Proxy } from "./Proxy.sol";

/// @title A factory for Proxy contracts that proxy Proxied implementations.
abstract contract ProxyFactory {

    mapping(uint256 => address) internal _implementationOf;

    mapping(address => uint256) internal _versionOf;

    mapping(uint256 => mapping(uint256 => address)) internal _migratorForPath;

    /// @dev Returns the implementation of `proxy_`.
    function _getImplementationOfProxy(address proxy_) private view returns (bool success_, address implementation_) {
        bytes memory returnData;
        // Since `_getImplementationOfProxy` is a private function, no need to check `proxy_` is a contract.
        ( success_, returnData ) = proxy_.staticcall(abi.encodeWithSelector(IProxied.implementation.selector));
        implementation_ = abi.decode(returnData, (address));
    }

    /// @dev Initializes `proxy_` using the initializer for `version_`, given some initialization arguments.
    function _initializeInstance(address proxy_, uint256 version_, bytes memory arguments_) private returns (bool success_) {
        // The migrator, where fromVersion == toVersion, is an initializer.
        address initializer = _migratorForPath[version_][version_];

        // If there is no initializer, then no initialization is necessary, so long as no initialization arguments were provided.
        if (initializer == address(0)) return arguments_.length == uint256(0);

        // Call the migrate function on the proxy, passing any initialization arguments.
        // Since `_initializeInstance` is a private function, no need to check `proxy_` is a contract.
        ( success_, ) = proxy_.call(abi.encodeWithSelector(IProxied.migrate.selector, initializer, arguments_));
    }

    /// @dev Deploys a new proxy for some version, with some initialization arguments, using `create` (i.e. factory's nonce determines the address).
    function _newInstance(uint256 version_, bytes memory arguments_) internal virtual returns (bool success_, address proxy_) {
        address implementation = _implementationOf[version_];

        if (implementation == address(0)) return (false, address(0));

        proxy_   = address(new Proxy(address(this), implementation));
        success_ = _initializeInstance(proxy_, version_, arguments_);
    }

    /// @dev Deploys a new proxy, with some initialization arguments, using `create2` (i.e. salt determines the address).
    ///      This factory needs to be IDefaultImplementationBeacon, since the proxy will pull its implementation from it.
    function _newInstance(bytes memory arguments_, bytes32 salt_) internal virtual returns (bool success_, address proxy_) {
        proxy_ = address(new Proxy{ salt: salt_ }(address(this), address(0)));

        // Fetch the implementation from the proxy. Don't care about success, since the version of the implementation will be checked in the next step.
        ( , address implementation ) = _getImplementationOfProxy(proxy_);

        // Get the version of the implementation.
        uint256 version = _versionOf[implementation];

        // Successful if version is nonzero (i.e. implementation fetched successfully from proxy) and initializing the instance succeeds.
        success_ = (version != uint256(0)) && _initializeInstance(proxy_, version, arguments_);
    }

    /// @dev Registers an implementation for some version.
    function _registerImplementation(uint256 version_, address implementation_) internal virtual returns (bool success_) {
        // Version 0 is not allowed since its the default value of all _versionOf[implementation_].
        // Implementation cannot already be registered and cannot be empty account (and thus also not address(0)).
        if (
            version_ == uint256(0) ||
            _implementationOf[version_] != address(0) ||
            _versionOf[implementation_] != uint256(0) ||
            !_isContract(implementation_)
        ) return false;

        // Store in two-way mappings.
        _implementationOf[version_] = implementation_;
        _versionOf[implementation_] = version_;

        return true;
    }

    /// @dev Registers a migrator for between two versions. If `fromVersion_ == toVersion_`, migrator is an initializer.
    function _registerMigrator(uint256 fromVersion_, uint256 toVersion_, address migrator_) internal virtual returns (bool success_) {
        // Version 0 is invalid.
        if (fromVersion_ == uint256(0) || toVersion_ == uint256(0)) return false;

        // Migrator must either be zero (clearing) or a contract (setting).
        if (migrator_ != address(0) && !_isContract(migrator_)) return false;

        _migratorForPath[fromVersion_][toVersion_] = migrator_;

        return true;
    }

    /// @dev Upgrades a proxy to a new version of an implementation, with some migration arguments.
    ///      Inheritor should revert on `success_ = false`, since proxy can be set to new implementation, but failed to migrate.
    function _upgradeInstance(address proxy_, uint256 toVersion_, bytes memory arguments_) internal virtual returns (bool success_) {
        // Check that the proxy is currently a contract, just once, ahead of the 3 times it will be low-level-called.
        if (!_isContract(proxy_)) return false;

        address toImplementation = _implementationOf[toVersion_];

        // The implementation being migrated must have been registered (which also implies that `toVersion_` was not 0).
        if (toImplementation == address(0)) return false;

        // Fetch the implementation from the proxy.
        address fromImplementation;
        ( success_, fromImplementation ) = _getImplementationOfProxy(proxy_);

        if (!success_) return false;

        // Set the proxy's implementation.
        ( success_, ) = proxy_.call(abi.encodeWithSelector(IProxied.setImplementation.selector, toImplementation));

        if (!success_) return false;

        // Get the version of the `fromImplementation`, then get the `migrator` of the upgrade path to `toVersion_`.
        address migrator = _migratorForPath[_versionOf[fromImplementation]][toVersion_];

        // If there is no migrator, then no migration is necessary, so long as no migration arguments were provided.
        if (migrator == address(0)) return arguments_.length == uint256(0);

        // Call the migrate function on the proxy, passing any migration arguments.
        ( success_, ) = proxy_.call(abi.encodeWithSelector(IProxied.migrate.selector, migrator, arguments_));
    }

    /// @dev Returns the deterministic address of a proxy given some salt.
    function _getDeterministicProxyAddress(bytes32 salt_) internal virtual view returns (address deterministicProxyAddress_) {
        // See https://docs.soliditylang.org/en/v0.8.7/control-structures.html#salted-contract-creations-create2
        return address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            bytes1(0xff),
                            address(this),
                            salt_,
                            keccak256(abi.encodePacked(type(Proxy).creationCode, abi.encode(address(this), address(0))))
                        )
                    )
                )
            )
        );
    }

    /// @dev Returns whether the account is currently a contract.
    function _isContract(address account_) internal view returns (bool isContract_) {
        return account_.code.length != uint256(0);
    }

}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.7;

abstract contract SlotManipulatable {

    function _getReferenceTypeSlot(bytes32 slot_, bytes32 key_) internal pure returns (bytes32 value_) {
        return keccak256(abi.encodePacked(key_, slot_));
    }

    function _getSlotValue(bytes32 slot_) internal view returns (bytes32 value_) {
        assembly {
            value_ := sload(slot_)
        }
    }

    function _setSlotValue(bytes32 slot_, bytes32 value_) internal {
        assembly {
            sstore(slot_, value_)
        }
    }

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