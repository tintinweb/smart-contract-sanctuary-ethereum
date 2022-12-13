// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

import { MapleProxiedInternals } from "../modules/maple-proxy-factory/contracts/MapleProxiedInternals.sol";

import { IPoolLike }                     from "./interfaces/Interfaces.sol";
import { IWithdrawalManagerInitializer } from "./interfaces/IWithdrawalManagerInitializer.sol";

import { WithdrawalManagerStorage } from "./WithdrawalManagerStorage.sol";

contract WithdrawalManagerInitializer is IWithdrawalManagerInitializer, WithdrawalManagerStorage, MapleProxiedInternals {

    fallback() external {
        ( address pool_, uint256 cycleDuration_, uint256 windowDuration_ ) = decodeArguments(msg.data);

        _initialize(pool_, cycleDuration_, windowDuration_);
    }

    function decodeArguments(bytes calldata encodedArguments_) public pure override
        returns (
            address pool_,
            uint256 cycleDuration_,
            uint256 windowDuration_
        )
    {
        ( pool_, cycleDuration_, windowDuration_ ) = abi.decode(encodedArguments_, (address, uint256, uint256));
    }

    function encodeArguments(
        address pool_,
        uint256 cycleDuration_,
        uint256 windowDuration_
    )
        public pure override returns (bytes memory encodedArguments_)
    {
        encodedArguments_ = abi.encode(pool_, cycleDuration_, windowDuration_);
    }

    function _initialize(address pool_, uint256 cycleDuration_, uint256 windowDuration_) internal {
        require(pool_           != address(0),     "WMI:ZERO_POOL");
        require(windowDuration_ != 0,              "WMI:ZERO_WINDOW");
        require(windowDuration_ <= cycleDuration_, "WMI:WINDOW_OOB");

        pool        = pool_;
        poolManager = IPoolLike(pool_).manager();

        cycleConfigs[0] = CycleConfig({
            initialCycleId:   1,
            initialCycleTime: uint64(block.timestamp),
            cycleDuration:    uint64(cycleDuration_),
            windowDuration:   uint64(windowDuration_)
        });

        emit Initialized(pool_, cycleDuration_, windowDuration_);
        emit ConfigurationUpdated({
            configId_:         0,
            initialCycleId_:   1,
            initialCycleTime_: uint64(block.timestamp),
            cycleDuration_:    uint64(cycleDuration_),
            windowDuration_:   uint64(windowDuration_)
        });
    }

}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

import { IWithdrawalManagerEvents }  from "./interfaces/IWithdrawalManagerEvents.sol";
import { IWithdrawalManagerStorage } from "./interfaces/IWithdrawalManagerStorage.sol";

abstract contract WithdrawalManagerStorage is IWithdrawalManagerStorage, IWithdrawalManagerEvents {

    address public override pool;
    address public override poolManager;

    uint256 public override latestConfigId;

    mapping(address => uint256) public override exitCycleId;
    mapping(address => uint256) public override lockedShares;

    mapping(uint256 => uint256) public override totalCycleShares;

    mapping(uint256 => CycleConfig) public override cycleConfigs;

}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

interface IWithdrawalManagerEvents {

    /**
     *  @dev   Emitted when the withdrawal configuration is updated.
     *  @param configId_         The identifier of the configuration.
     *  @param initialCycleId_   The identifier of the withdrawal cycle when the configuration takes effect.
     *  @param initialCycleTime_ The timestamp of the beginning of the withdrawal cycle when the configuration takes effect.
     *  @param cycleDuration_    The new duration of the withdrawal cycle.
     *  @param windowDuration_   The new duration of the withdrawal window.
     */
    event ConfigurationUpdated(uint256 indexed configId_, uint64 initialCycleId_, uint64 initialCycleTime_, uint64 cycleDuration_, uint64 windowDuration_);

    /**
     *  @dev   Emitted when a withdrawal request is cancelled.
     *  @param account_ Address of the account whose withdrawal request has been cancelled.
     */
    event WithdrawalCancelled(address indexed account_);

    /**
     *  @dev   Emitted when a withdrawal request is processed.
     *  @param account_          Address of the account processing their withdrawal request.
     *  @param sharesToRedeem_   Amount of shares that the account will redeem.
     *  @param assetsToWithdraw_ Amount of assets that will be withdrawn from the pool.
     */
    event WithdrawalProcessed(address indexed account_, uint256 sharesToRedeem_, uint256 assetsToWithdraw_);

    /**
     *  @dev   Emitted when a withdrawal request is updated.
     *  @param account_      Address of the account whose request has been updated.
     *  @param lockedShares_ Total amount of shares the account has locked.
     *  @param windowStart_  Time when the withdrawal window for the withdrawal request will begin.
     *  @param windowEnd_    Time when the withdrawal window for the withdrawal request will end.
     */
    event WithdrawalUpdated(address indexed account_, uint256 lockedShares_, uint64 windowStart_, uint64 windowEnd_);

}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

interface IWithdrawalManagerInitializer {

    event Initialized(address pool_, uint256 cycleDuration_, uint256 windowDuration_);

    function decodeArguments(bytes calldata encodedArguments_) external pure
        returns (address pool_, uint256 cycleDuration_, uint256 windowDuration_);

    function encodeArguments(address pool_, uint256 cycleDuration_, uint256 windowDuration_) external pure
        returns (bytes memory encodedArguments_);

}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

interface IWithdrawalManagerStorage {

    struct CycleConfig {
        uint64 initialCycleId;    // Identifier of the first withdrawal cycle using this configuration.
        uint64 initialCycleTime;  // Timestamp of the first withdrawal cycle using this configuration.
        uint64 cycleDuration;     // Duration of the withdrawal cycle.
        uint64 windowDuration;    // Duration of the withdrawal window.
    }

    /**
     *  @dev    Gets the configuration for a given config id.
     *  @param  configId_        The id of the configuration to use.
     *  @return initialCycleId   Identifier of the first withdrawal cycle using this configuration.
     *  @return initialCycleTime Timestamp of the first withdrawal cycle using this configuration.
     *  @return cycleDuration    Duration of the withdrawal cycle.
     *  @return windowDuration   Duration of the withdrawal window.
     */
    function cycleConfigs(uint256 configId_) external returns (uint64 initialCycleId, uint64 initialCycleTime, uint64 cycleDuration, uint64 windowDuration);

    /**
     *  @dev    Gets the id of the cycle that account can exit on.
     *  @param  account_ The address to check the exit for.
     *  @return cycleId_ The id of the cycle that account can exit on.
     */
    function exitCycleId(address account_) external view returns (uint256 cycleId_);

    /**
     *  @dev    Gets the most recent configuration id.
     *  @return configId_ The id of the mostrecent configuration.
     */
    function latestConfigId() external view returns (uint256 configId_);

    /**
     *  @dev    Gets the amount of locked shares for an account.
     *  @param  account_      The address to check the exit for.
     *  @return lockedShares_ The amount of shares locked.
     */
    function lockedShares(address account_) external view returns (uint256 lockedShares_);

    /**
     *  @dev    Gets the address of the pool associated with this withdrawal manager.
     *  @return pool_ The address of the pool.
     */
    function pool() external view returns (address pool_);

    /**
     *  @dev    Gets the address of the pool manager associated with this withdrawal manager.
     *  @return poolManager_ The address of the pool manager.
     */
    function poolManager() external view returns (address poolManager_);

    /**
     *  @dev    Gets the amount of shares for a cycle.
     *  @param  cycleId_          The id to cycle to check.
     *  @return totalCycleShares_ The amount of shares in the cycle.
     */
    function totalCycleShares(uint256 cycleId_) external view returns (uint256 totalCycleShares_);

}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.7;

interface IMapleGlobalsLike {

    function governor() external view returns (address governor_);

    function isPoolDeployer(address poolDeployer_) external view returns (bool isPoolDeployer_);

    function isValidScheduledCall(address caller_, address contract_, bytes32 functionId_, bytes calldata callData_) external view returns (bool isValid_);

    function protocolPaused() external view returns (bool protocolPaused_);

    function unscheduleCall(address caller_, bytes32 functionId_, bytes calldata callData_) external;

}

interface IERC20Like {

    function balanceOf(address account_) external view returns (uint256 balance_);

}

interface IPoolLike {

    function asset() external view returns (address asset_);

    function convertToShares(uint256 assets_) external view returns (uint256 shares_);

    function manager() external view returns (address manager_);

    function previewRedeem(uint256 shares_) external view returns (uint256 assets_);

    function redeem(uint256 shares_, address receiver_, address owner_) external returns (uint256 assets_);

    function totalSupply() external view returns (uint256 totalSupply_);

    function transfer(address account_, uint256 amount_) external returns (bool success_);

}

interface IPoolManagerLike {

    function globals() external view returns (address globals_);

    function poolDelegate() external view returns (address poolDelegate_);

    function totalAssets() external view returns (uint256 totalAssets_);

    function unrealizedLosses() external view returns (uint256 unrealizedLosses_);

}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.7;

import { ProxiedInternals } from "../modules/proxy-factory/contracts/ProxiedInternals.sol";

/// @title A Maple implementation that is to be proxied, will need MapleProxiedInternals.
abstract contract MapleProxiedInternals is ProxiedInternals { }

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