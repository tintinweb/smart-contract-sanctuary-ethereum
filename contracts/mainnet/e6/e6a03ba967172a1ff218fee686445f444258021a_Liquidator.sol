// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

import { ERC20Helper } from "../modules/erc20-helper/src/ERC20Helper.sol";

import { MapleProxiedInternals } from "../modules/maple-proxy-factory/contracts/MapleProxiedInternals.sol";
import { IMapleProxyFactory }    from "../modules/maple-proxy-factory/contracts/interfaces/IMapleProxyFactory.sol";

import { ILiquidator } from "./interfaces/ILiquidator.sol";

import { ILoanManagerLike, IMapleGlobalsLike } from "./interfaces/Interfaces.sol";

import { LiquidatorStorage } from "./LiquidatorStorage.sol";

/*

    ██╗     ██╗ ██████╗ ██╗   ██╗██╗██████╗  █████╗ ████████╗ ██████╗ ██████╗
    ██║     ██║██╔═══██╗██║   ██║██║██╔══██╗██╔══██╗╚══██╔══╝██╔═══██╗██╔══██╗
    ██║     ██║██║   ██║██║   ██║██║██║  ██║███████║   ██║   ██║   ██║██████╔╝
    ██║     ██║██║▄▄ ██║██║   ██║██║██║  ██║██╔══██║   ██║   ██║   ██║██╔══██╗
    ███████╗██║╚██████╔╝╚██████╔╝██║██████╔╝██║  ██║   ██║   ╚██████╔╝██║  ██║
    ╚══════╝╚═╝ ╚══▀▀═╝  ╚═════╝ ╚═╝╚═════╝ ╚═╝  ╚═╝   ╚═╝    ╚═════╝ ╚═╝  ╚═╝

*/

contract Liquidator is ILiquidator, LiquidatorStorage, MapleProxiedInternals {

    /******************************************************************************************************************************/
    /*** Modifiers                                                                                                              ***/
    /******************************************************************************************************************************/

    modifier whenProtocolNotPaused() {
        require(!IMapleGlobalsLike(globals()).protocolPaused(), "LIQ:PROTOCOL_PAUSED");

        _;
    }

    modifier nonReentrant() {
        require(locked == 1, "LIQ:LOCKED");

        locked = 2;

        _;

        locked = 1;
    }

    /******************************************************************************************************************************/
    /*** Migration Functions                                                                                                    ***/
    /******************************************************************************************************************************/

    function migrate(address migrator_, bytes calldata arguments_) external override {
        require(msg.sender == _factory(),        "LIQ:M:NOT_FACTORY");
        require(_migrate(migrator_, arguments_), "LIQ:M:FAILED");
    }

    function setImplementation(address implementation_) external override {
        require(msg.sender == _factory(), "LIQ:SI:NOT_FACTORY");

        _setImplementation(implementation_);
    }

    function upgrade(uint256 version_, bytes calldata arguments_) external override {
        address poolDelegate_ = poolDelegate();

        require(msg.sender == poolDelegate_ || msg.sender == governor(), "LIQ:U:NOT_AUTHORIZED");

        IMapleGlobalsLike mapleGlobals = IMapleGlobalsLike(globals());

        if (msg.sender == poolDelegate_) {
            require(mapleGlobals.isValidScheduledCall(msg.sender, address(this), "LIQ:UPGRADE", msg.data), "LIQ:U:INVALID_SCHED_CALL");

            mapleGlobals.unscheduleCall(msg.sender, "LIQ:UPGRADE", msg.data);
        }

        IMapleProxyFactory(_factory()).upgradeInstance(version_, arguments_);
    }

    /******************************************************************************************************************************/
    /*** Liquidation Functions                                                                                                  ***/
    /******************************************************************************************************************************/

    function liquidatePortion(uint256 collateralAmount_, uint256 maxReturnAmount_, bytes calldata data_) external override whenProtocolNotPaused nonReentrant {
        require(msg.sender != collateralAsset && msg.sender != fundsAsset, "LIQ:LP:INVALID_CALLER");

        // Calculate the amount of fundsAsset required based on the amount of collateralAsset borrowed.
        uint256 returnAmount_ = getExpectedAmount(collateralAmount_);
        require(returnAmount_ <= maxReturnAmount_, "LIQ:LP:MAX_RETURN_EXCEEDED");

        // Transfer a requested amount of collateralAsset to the borrower.
        require(ERC20Helper.transfer(collateralAsset, msg.sender, collateralAmount_), "LIQ:LP:TRANSFER");

        collateralRemaining -= collateralAmount_;

        // Perform a low-level call to msg.sender, allowing a swap strategy to be executed with the transferred collateral.
        msg.sender.call(data_);

        emit PortionLiquidated(collateralAmount_, returnAmount_);

        // Pull required amount of fundsAsset from the borrower, if this amount of funds cannot be recovered atomically, revert.
        require(ERC20Helper.transferFrom(fundsAsset, msg.sender, address(this), returnAmount_), "LIQ:LP:TRANSFER_FROM");
    }

    function pullFunds(address token_, address destination_, uint256 amount_) external override {
        require(msg.sender == loanManager, "LIQ:PF:NOT_LM");

        emit FundsPulled(token_, destination_, amount_);

        require(ERC20Helper.transfer(token_, destination_, amount_), "LIQ:PF:TRANSFER");
    }

    function setCollateralRemaining(uint256 collateralAmount_) external override {
        require(msg.sender == loanManager, "LIQ:SCR:NOT_LM");

        collateralRemaining = collateralAmount_;
    }

    function getExpectedAmount(uint256 swapAmount_) public view override returns (uint256 expectedAmount_) {
        return ILoanManagerLike(loanManager).getExpectedAmount(collateralAsset, swapAmount_);
    }

    /******************************************************************************************************************************/
    /*** View Functions                                                                                                         ***/
    /******************************************************************************************************************************/

    function factory() public view override returns (address factory_) {
        factory_ = _factory();
    }

    function globals() public view returns (address globals_) {
        globals_ = IMapleProxyFactory(_factory()).mapleGlobals();
    }

    function governor() public view returns (address governor_) {
        governor_ = ILoanManagerLike(loanManager).governor();
    }

    function implementation() public view override returns (address implementation_) {
        implementation_ = _implementation();
    }

    function poolDelegate() public view returns (address poolDelegate_) {
        poolDelegate_ = ILoanManagerLike(loanManager).poolDelegate();
    }

}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

import { ILiquidatorStorage } from "./interfaces/ILiquidatorStorage.sol";

abstract contract LiquidatorStorage is ILiquidatorStorage {

    address public override collateralAsset;
    address public override fundsAsset;
    address public override loanManager;

    uint256 public override collateralRemaining;

    uint256 internal locked;

}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

import { IMapleProxied } from "../../modules/maple-proxy-factory/contracts/interfaces/IMapleProxied.sol";

import { ILiquidatorStorage } from "./ILiquidatorStorage.sol";

interface ILiquidator is ILiquidatorStorage, IMapleProxied {

    /******************************************************************************************************************************/
    /*** Events                                                                                                                 ***/
    /******************************************************************************************************************************/

    /**
     * @dev   Funds were withdrawn from the liquidator.
     * @param token_       Address of the token that was withdrawn.
     * @param destination_ Address of where tokens were sent.
     * @param amount_      Amount of tokens that were sent.
     */
    event FundsPulled(address token_, address destination_, uint256 amount_);

    /**
     * @dev   Portion of collateral was liquidated.
     * @param swapAmount_     Amount of collateralAsset that was liquidated.
     * @param returnedAmount_ Amount of fundsAsset that was returned.
     */
    event PortionLiquidated(uint256 swapAmount_, uint256 returnedAmount_);

    /******************************************************************************************************************************/
    /*** Functions                                                                                                              ***/
    /******************************************************************************************************************************/

    /**
     * @dev    Returns the expected amount to be returned from a flash loan given a certain amount of `collateralAsset`.
     * @param  swapAmount_     Amount of `collateralAsset` to be flash-borrowed.
     * @return expectedAmount_ Amount of `fundsAsset` that must be returned in the same transaction.
     */
    function getExpectedAmount(uint256 swapAmount_) external returns (uint256 expectedAmount_);

    /**
     * @dev   Flash loan function that:
     *        1. Transfers a specified amount of `collateralAsset` to `msg.sender`.
     *        2. Performs an arbitrary call to `msg.sender`, to trigger logic necessary to get `fundsAsset` (e.g., AMM swap).
     *        3. Performs a `transferFrom`, taking the corresponding amount of `fundsAsset` from the user.
     *        If the required amount of `fundsAsset` is not returned in step 3, the entire transaction reverts.
     * @param swapAmount_      Amount of `collateralAsset` that is to be borrowed in the flash loan.
     * @param maxReturnAmount_ Max amount of `fundsAsset` that can be returned to the liquidator contract.
     * @param data_            ABI-encoded arguments to be used in the low-level call to perform step 2.
     */
    function liquidatePortion(uint256 swapAmount_, uint256 maxReturnAmount_, bytes calldata data_) external;

    /**
     * @dev   Pulls a specified amount of ERC-20 tokens from the contract.
     *        Can only be called by `owner`.
     * @param token_       The ERC-20 token contract address.
     * @param destination_ The destination of the transfer.
     * @param amount_      The amount to transfer.
     */
    function pullFunds(address token_, address destination_, uint256 amount_) external;

    /**
     * @dev   Sets the initial amount of collateral to be liquidated.
     * @param collateralAmount_ The amount of collateral to be liquidated.
     */
    function setCollateralRemaining(uint256 collateralAmount_) external;

}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

interface ILiquidatorStorage {

    /**
     *  @dev    Returns the address of the collateral asset.
     *  @return collateralAsset_ Address of the asset used as collateral.
     */
    function collateralAsset() external view returns (address collateralAsset_);

    /**
     *  @dev    Returns the amount of collateral yet to be liquidated.
     *  @return collateralRemaining_ Amunt of collateral remaining to be liquidated.
     */
    function collateralRemaining() external view returns (uint256 collateralRemaining_);

    /**
     *  @dev    Returns the address of the funding asset.
     *  @return fundsAsset_ Address of the asset used for providing funds.
     */
    function fundsAsset() external view returns (address fundsAsset_);

    /**
     *  @dev    Returns the address of the loan manager contract.
     *  @return loanManager_ Address of the loan manager.
     */
    function loanManager() external view returns (address loanManager_);


}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

interface ILoanManagerLike {

    function getExpectedAmount(address collateralAsset_, uint256 swapAmount_) external view returns (uint256 expectedAmount_);

    function globals() external view returns (address globals_);

    function governor() external view returns (address governor_);

    function poolDelegate() external view returns (address poolDelegate_);

}

interface IERC20Like {

    function allowance(address account_, address spender_) external view returns (uint256 allowance_);

    function approve(address account_, uint256 amount_) external returns (bool success_);

    function balanceOf(address account_) external view returns (uint256 balance_);

    function decimals() external view returns (uint256 decimals_);

}

interface ILiquidatorLike {

    function getExpectedAmount(uint256 swapAmount_) external returns (uint256 expectedAmount_);

    function liquidatePortion(uint256 swapAmount_, uint256 maxReturnAmount_, bytes calldata data_) external;

}

interface IMapleGlobalsLike {

    function getLatestPrice(address asset_) external view returns (uint256 price_);

    function governor() external view returns (address governor_);

    function isFactory(bytes32 factoryId_, address factory_) external view returns (bool isValid_);

    function isValidScheduledCall(address caller_, address contract_, bytes32 functionId_, bytes calldata callData_) external view returns (bool isValid_);

    function protocolPaused() external view returns (bool protocolPaused_);

    function unscheduleCall(address caller_, bytes32 functionId_, bytes calldata callData_) external;

}

interface IOracleLike {

    function latestRoundData() external view returns (
        uint80  roundId_,
        int256  answer_,
        uint256 startedAt_,
        uint256 updatedAt_,
        uint80  answeredInRound_
    );

}

interface IUniswapRouterLike {

    function swapExactTokensForTokens(
        uint256 amountIn_,
        uint256 amountOutMin_,
        address[] calldata path_,
        address to_,
        uint256 deadline_
    ) external returns (uint256[] memory amounts_);

    function swapTokensForExactTokens(
        uint256 amountOut_,
        uint256 amountInMax_,
        address[] calldata path_,
        address to_,
        uint256 deadline_
    ) external returns (uint[] memory amounts_);

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

import { ProxiedInternals } from "../modules/proxy-factory/contracts/ProxiedInternals.sol";

/// @title A Maple implementation that is to be proxied, will need MapleProxiedInternals.
abstract contract MapleProxiedInternals is ProxiedInternals { }

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

import { SlotManipulatable } from "./SlotManipulatable.sol";

/// @title An implementation that is to be proxied, will need ProxiedInternals.
abstract contract ProxiedInternals is SlotManipulatable {

    /// @dev Storage slot with the address of the current factory. `keccak256('eip1967.proxy.factory') - 1`.
    bytes32 private constant FACTORY_SLOT = bytes32(0x7a45a402e4cb6e08ebc196f20f66d5d30e67285a2a8aa80503fa409e727a4af1);

    /// @dev Storage slot with the address of the current factory. `keccak256('eip1967.proxy.implementation') - 1`.
    bytes32 private constant IMPLEMENTATION_SLOT = bytes32(0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc);

    /// @dev Delegatecalls to a migrator contract to manipulate storage during an initialization or migration.
    function _migrate(address migrator_, bytes calldata arguments_) internal virtual returns (bool success_) {
        uint256 size;

        assembly {
            size := extcodesize(migrator_)
        }

        if (size == uint256(0)) return false;

        ( success_, ) = migrator_.delegatecall(arguments_);
    }

    /// @dev Sets the factory address in storage.
    function _setFactory(address factory_) internal virtual returns (bool success_) {
        _setSlotValue(FACTORY_SLOT, bytes32(uint256(uint160(factory_))));
        return true;
    }

    /// @dev Sets the implementation address in storage.
    function _setImplementation(address implementation_) internal virtual returns (bool success_) {
        _setSlotValue(IMPLEMENTATION_SLOT, bytes32(uint256(uint160(implementation_))));
        return true;
    }

    /// @dev Returns the factory address.
    function _factory() internal view virtual returns (address factory_) {
        return address(uint160(uint256(_getSlotValue(FACTORY_SLOT))));
    }

    /// @dev Returns the implementation address.
    function _implementation() internal view virtual returns (address implementation_) {
        return address(uint160(uint256(_getSlotValue(IMPLEMENTATION_SLOT))));
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