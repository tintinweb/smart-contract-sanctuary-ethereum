// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

import { ERC20Helper }        from "../modules/erc20-helper/src/ERC20Helper.sol";
import { IMapleProxyFactory } from "../modules/maple-proxy-factory/contracts/interfaces/IMapleProxyFactory.sol";

import { IGlobalsLike, IPoolManagerLike } from "./interfaces/Interfaces.sol";
import { IPoolDeployer }                  from "./interfaces/IPoolDeployer.sol";

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
        address           poolManagerFactory_,
        address           withdrawalManagerFactory_,
        address[]  memory loanManagerFactories_,
        address           asset_,
        string     memory name_,
        string     memory symbol_,
        uint256[6] memory configParams_
    )
        external override
        returns (address poolManager_)
    {
        IGlobalsLike globals_ = IGlobalsLike(globals);

        require(globals_.isPoolDelegate(msg.sender), "PD:DP:INVALID_PD");

        require(globals_.isInstanceOf("POOL_MANAGER_FACTORY",       poolManagerFactory_),       "PD:DP:INVALID_PM_FACTORY");
        require(globals_.isInstanceOf("WITHDRAWAL_MANAGER_FACTORY", withdrawalManagerFactory_), "PD:DP:INVALID_WM_FACTORY");

        // Deploy Pool Manager (and Pool).
        poolManager_ = IMapleProxyFactory(poolManagerFactory_).createInstance(
            abi.encode(msg.sender, asset_, configParams_[5], name_, symbol_),
            keccak256(abi.encode(msg.sender))
        );

        address pool_ = IPoolManagerLike(poolManager_).pool();

        // Deploy Withdrawal Manager.
        address withdrawalManager_ = IMapleProxyFactory(withdrawalManagerFactory_).createInstance(
            abi.encode(pool_, configParams_[3], configParams_[4]),
            keccak256(abi.encode(poolManager_))
        );

        address[] memory loanManagers_ = new address[](loanManagerFactories_.length);

        for (uint256 i_; i_ < loanManagerFactories_.length; ++i_) {
            loanManagers_[i_] = IPoolManagerLike(poolManager_).addLoanManager(loanManagerFactories_[i_]);
        }

        emit PoolDeployed(pool_, poolManager_, withdrawalManager_, loanManagers_);

        uint256 coverAmount_ = configParams_[2];

        require(
            coverAmount_ == 0 ||
            ERC20Helper.transferFrom(asset_, msg.sender, IPoolManagerLike(poolManager_).poolDelegateCover(), coverAmount_),
            "PD:DP:TRANSFER_FAILED"
        );

        IPoolManagerLike(poolManager_).setDelegateManagementFeeRate(configParams_[1]);
        IPoolManagerLike(poolManager_).setLiquidityCap(configParams_[0]);
        IPoolManagerLike(poolManager_).setWithdrawalManager(withdrawalManager_);
        IPoolManagerLike(poolManager_).completeConfiguration();
    }

    function getDeploymentAddresses(
        address           poolDelegate_,
        address           poolManagerFactory_,
        address           withdrawalManagerFactory_,
        address[]  memory loanManagerFactories_,
        address           asset_,
        string     memory name_,
        string     memory symbol_,
        uint256[6] memory configParams_
    )
        public view override
        returns (
            address          poolManager_,
            address          pool_,
            address          poolDelegateCover_,
            address          withdrawalManager_,
            address[] memory loanManagers_
        )
    {
        poolManager_ = IMapleProxyFactory(poolManagerFactory_).getInstanceAddress(
            abi.encode(poolDelegate_, asset_, configParams_[5], name_, symbol_),
            keccak256(abi.encode(poolDelegate_))
        );

        pool_              = _addressFrom(poolManager_, 1);
        poolDelegateCover_ = _addressFrom(poolManager_, 2);

        withdrawalManager_ = IMapleProxyFactory(withdrawalManagerFactory_).getInstanceAddress(
            abi.encode(pool_, configParams_[3], configParams_[4]),
            keccak256(abi.encode(poolManager_))
        );

        loanManagers_ = new address[](loanManagerFactories_.length);

        for (uint256 i_; i_ < loanManagerFactories_.length; ++i_) {
            loanManagers_[i_] = IMapleProxyFactory(loanManagerFactories_[i_]).getInstanceAddress(
                abi.encode(poolManager_),
                keccak256(abi.encode(poolManager_, i_))
            );
        }
    }

    function _addressFrom(address origin_, uint nonce_) internal pure returns (address address_) {
        address_ = address(
            uint160(
                uint256(
                    keccak256(
                        nonce_ == 0x00     ? abi.encodePacked(bytes1(0xd6), bytes1(0x94), origin_, bytes1(0x80))                 :
                        nonce_ <= 0x7f     ? abi.encodePacked(bytes1(0xd6), bytes1(0x94), origin_, uint8(nonce_))                :
                        nonce_ <= 0xff     ? abi.encodePacked(bytes1(0xd7), bytes1(0x94), origin_, bytes1(0x81), uint8(nonce_))  :
                        nonce_ <= 0xffff   ? abi.encodePacked(bytes1(0xd8), bytes1(0x94), origin_, bytes1(0x82), uint16(nonce_)) :
                        nonce_ <= 0xffffff ? abi.encodePacked(bytes1(0xd9), bytes1(0x94), origin_, bytes1(0x83), uint24(nonce_)) :
                                             abi.encodePacked(bytes1(0xda), bytes1(0x94), origin_, bytes1(0x84), uint32(nonce_))
                    )
                )
            )
        );
    }

}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.7;

import { IERC20Like } from "./interfaces/IERC20Like.sol";

/**
 * @title Small Library to standardize erc20 token interactions.
 */
library ERC20Helper {

    /**************************************************************************************************************************************/
    /*** Internal Functions                                                                                                             ***/
    /**************************************************************************************************************************************/

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

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.7;

import { IDefaultImplementationBeacon } from "../../modules/proxy-factory/contracts/interfaces/IDefaultImplementationBeacon.sol";

/// @title A Maple factory for Proxy contracts that proxy MapleProxied implementations.
interface IMapleProxyFactory is IDefaultImplementationBeacon {

    /**************************************************************************************************************************************/
    /*** Events                                                                                                                         ***/
    /**************************************************************************************************************************************/

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

    /**************************************************************************************************************************************/
    /*** State Variables                                                                                                                ***/
    /**************************************************************************************************************************************/

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

    /**************************************************************************************************************************************/
    /*** State Changing Functions                                                                                                       ***/
    /**************************************************************************************************************************************/

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

    /**************************************************************************************************************************************/
    /*** View Functions                                                                                                                 ***/
    /**************************************************************************************************************************************/

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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

interface IERC20Like {

    function allowance(address owner_, address spender_) external view returns (uint256 allowance_);

    function balanceOf(address account_) external view returns (uint256 balance_);

    function totalSupply() external view returns (uint256 totalSupply_);

}

interface IGlobalsLike {

    function bootstrapMint(address asset_) external view returns (uint256 bootstrapMint_);

    function governor() external view returns (address governor_);

    function isFunctionPaused(bytes4 sig_) external view returns (bool isFunctionPaused_);

    function isInstanceOf(bytes32 instanceId_, address instance_) external view returns (bool isInstance_);

    function isPoolAsset(address asset_) external view returns (bool isPoolAsset_);

    function isPoolDelegate(address account_) external view returns (bool isPoolDelegate_);

    function isPoolDeployer(address poolDeployer_) external view returns (bool isPoolDeployer_);

    function isValidScheduledCall(address caller_, address contract_, bytes32 functionId_, bytes calldata callData_)
        external view
        returns (bool isValid_);

    function mapleTreasury() external view returns (address mapleTreasury_);

    function maxCoverLiquidationPercent(address poolManager_) external view returns (uint256 maxCoverLiquidationPercent_);

    function migrationAdmin() external view returns (address migrationAdmin_);

    function minCoverAmount(address poolManager_) external view returns (uint256 minCoverAmount_);

    function ownedPoolManager(address poolDelegate_) external view returns (address poolManager_);

    function securityAdmin() external view returns (address securityAdmin_);

    function transferOwnedPoolManager(address fromPoolDelegate_, address toPoolDelegate_) external;

    function unscheduleCall(address caller_, bytes32 functionId_, bytes calldata callData_) external;

}

interface ILoanManagerLike {

    function assetsUnderManagement() external view returns (uint256 assetsUnderManagement_);

    function finishCollateralLiquidation(address loan_) external returns (uint256 remainingLosses_, uint256 serviceFee_);

    function triggerDefault(address loan_, address liquidatorFactory_)
        external
        returns (bool liquidationComplete_, uint256 remainingLosses_, uint256 platformFees_);

    function unrealizedLosses() external view returns (uint256 unrealizedLosses_);

}

interface ILoanLike {

    function lender() external view returns (address lender_);

}

interface IMapleProxyFactoryLike {

    function mapleGlobals() external view returns (address mapleGlobals_);

}

interface IPoolDelegateCoverLike {

    function moveFunds(uint256 amount_, address recipient_) external;

}

interface IPoolLike is IERC20Like {

    function convertToExitShares(uint256 assets_) external view returns (uint256 shares_);

    function previewDeposit(uint256 assets_) external view returns (uint256 shares_);

    function previewMint(uint256 shares_) external view returns (uint256 assets_);

}

interface IPoolManagerLike {

    function addLoanManager(address loanManagerFactory_) external returns (address loanManager_);

    function canCall(bytes32 functionId_, address caller_, bytes memory data_)
        external view
        returns (bool canCall_, string memory errorMessage_);

    function completeConfiguration() external;

    function getEscrowParams(address owner_, uint256 shares_) external view returns (uint256 escrowShares_, address escrow_);

    function maxDeposit(address receiver_) external view returns (uint256 maxAssets_);

    function maxMint(address receiver_) external view returns (uint256 maxShares_);

    function maxRedeem(address owner_) external view returns (uint256 maxShares_);

    function maxWithdraw(address owner_) external view returns (uint256 maxAssets_);

    function pool() external view returns (address pool_);

    function poolDelegateCover() external view returns (address poolDelegateCover_);

    function previewRedeem(address owner_, uint256 shares_) external view returns (uint256 assets_);

    function previewWithdraw(address owner_, uint256 assets_) external view returns (uint256 shares_);

    function processRedeem(uint256 shares_, address owner_, address sender_)
        external
        returns (uint256 redeemableShares_, uint256 resultingAssets_);

    function processWithdraw(uint256 assets_, address owner_, address sender_)
        external
        returns (uint256 redeemableShares_, uint256 resultingAssets_);

    function removeShares(uint256 shares_, address owner_) external returns (uint256 sharesReturned_);

    function requestRedeem(uint256 shares_, address owner_, address sender_) external;

    function requestWithdraw(uint256 shares_, uint256 assets_, address owner_, address sender_) external;

    function setDelegateManagementFeeRate(uint256 delegateManagementFeeRate_) external;

    function setLiquidityCap(uint256 liquidityCap_) external;

    function setWithdrawalManager(address withdrawalManager_) external;

    function totalAssets() external view returns (uint256 totalAssets_);

    function unrealizedLosses() external view returns (uint256 unrealizedLosses_);

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

interface IPoolDeployer {

    /**
     *  @dev   Emitted when a new pool is deployed.
     *  @param pool_              The address of the Pool deployed.
     *  @param poolManager_       The address of the PoolManager deployed.
     *  @param withdrawalManager_ The address of the WithdrawalManager deployed.
     *  @param loanManagers_      An array of the addresses of the LoanManagers deployed.
     */
    event PoolDeployed(address indexed pool_, address indexed poolManager_, address indexed withdrawalManager_, address[] loanManagers_);

    /**
     *  @dev   Deploys a pool along with its dependencies.
     *  @param poolManagerFactory_       The address of the PoolManager factory to use.
     *  @param withdrawalManagerFactory_ The address of the WithdrawalManager factory to use.
     *  @param loanManagerFactories_     An array of LoanManager factories to use.
     *  @param configParams_             Array of uint256 config parameters. Array used to avoid stack too deep issues.
     *                                    [0]: liquidityCap
     *                                    [1]: delegateManagementFeeRate
     *                                    [2]: coverAmountRequired
     *                                    [3]: cycleDuration
     *                                    [4]: windowDuration
     *                                    [5]: initialSupply
     *  @return poolManager_ The address of the PoolManager.
     */
    function deployPool(
        address           poolManagerFactory_,
        address           withdrawalManagerFactory_,
        address[]  memory loanManagerFactories_,
        address           asset_,
        string     memory name_,
        string     memory symbol_,
        uint256[6] memory configParams_
    )
        external
        returns (address poolManager_);

    /**
     *  @dev   Gets the addresses that would result from a deployment.
     *  @param poolDelegate_             The address of the PoolDelegate that will deploy the Pool.
     *  @param poolManagerFactory_       The address of the PoolManager factory to use.
     *  @param withdrawalManagerFactory_ The address of the WithdrawalManager factory to use.
     *  @param loanManagerFactories_     An array of LoanManager factories to use.
     *  @param configParams_             Array of uint256 config parameters. Array used to avoid stack too deep issues.
     *                                    [0]: liquidityCap
     *                                    [1]: delegateManagementFeeRate
     *                                    [2]: coverAmountRequired
     *                                    [3]: cycleDuration
     *                                    [4]: windowDuration
     *                                    [5]: initialSupply
     *  @return poolManager_       The address of the PoolManager contract that will be deployed.
     *  @return pool_              The address of the Pool contract that will be deployed.
     *  @return poolDelegateCover_ The address of the PoolDelegateCover contract that will be deployed.
     *  @return withdrawalManager_ The address of the WithdrawalManager contract that will be deployed.
     *  @return loanManagers_      The address of the LoanManager contracts that will be deployed.
     */
    function getDeploymentAddresses(
        address           poolDelegate_,
        address           poolManagerFactory_,
        address           withdrawalManagerFactory_,
        address[]  memory loanManagerFactories_,
        address           asset_,
        string     memory name_,
        string     memory symbol_,
        uint256[6] memory configParams_
    )
        external view
        returns (
            address          poolManager_,
            address          pool_,
            address          poolDelegateCover_,
            address          withdrawalManager_,
            address[] memory loanManagers_
        );

    function globals() external view returns (address globals_);

}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.7;

/// @title Interface of the ERC20 standard as needed by ERC20Helper.
interface IERC20Like {

    function approve(address spender_, uint256 amount_) external returns (bool success_);

    function transfer(address recipient_, uint256 amount_) external returns (bool success_);

    function transferFrom(address owner_, address recipient_, uint256 amount_) external returns (bool success_);

}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.7;

/// @title An beacon that provides a default implementation for proxies, must implement IDefaultImplementationBeacon.
interface IDefaultImplementationBeacon {

    /// @dev The address of an implementation for proxies.
    function defaultImplementation() external view returns (address defaultImplementation_);

}