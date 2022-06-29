// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {SafeCast} from "../lib/SafeCast.sol";
import {Timestamp} from "../lib/Timestamp.sol";
import {ICorePool} from "../interface/ICorePool.sol";
import {IERC20Mintable} from "../interface/IERC20Mintable.sol";
import {ErrorHandler} from "../lib/ErrorHandler.sol";

/**
 *@title Pool Factory 
 * @dev Pool Factory manages Daolympics staking pools, provides a single
 *      public interface to access the pools, provides an interface for the pools
 *      to mint yield rewards, access pool-related info, update weights, etc.
 *
 * @dev The factory is authorized (via its owner) to register new pools, change weights
 *      of the existing pools, removing the pools (by changing their weights to zero).
 *
 * @dev The factory requires MINTER_ROLE permission on the DLP and RUN tokens to mint yield
 *      (see `mintYieldTo` function).
 *
 * @notice The contract uses Ownable implementation, so only the DAO is able to handle
 *         admin activities, such as registering new pools, doing contract upgrades,
 *         changing pool weights, managing emission schedules and so on.

 */
contract PoolFactory is
    Initializable,
    UUPSUpgradeable,
    OwnableUpgradeable,
    Timestamp
{
    using ErrorHandler for bytes4;
    using SafeCast for uint256;
    

    /// @dev Auxiliary data structure used only in getPoolData() view function
    struct PoolData {
        // @dev pool token address (like DLP)
        address poolToken;
        // @dev pool address (like deployed core pool instance)
        address poolAddress;
        // @dev pool weight (250 for DLP pools, 750 for DLP/ETH pools - set during deployment)
        uint32 weight;
        // @dev flash pool flag
        bool isFlashPool;
    }

    /**
     * @dev DLP/second determines yield farming reward base
     *      used by the yield pools controlled by the factory.
     */
    uint192 public dlpPerSecond;

    /**
     * @dev The yield is distributed proportionally to pool weights;
     *      total weight is here to help in determining the proportion.
     */
    uint32 public totalWeight;

    /**
     * @dev DLP/second decreases by 3% every seconds/update
     *      an update is triggered by executing `updateDLPPerSecond` public function.
     */
    uint32 public secondsPerUpdate;
    
    /**
     * @dev End time is the last timestamp when DLP/second can be decreased;
     *      it is implied that yield farming stops after that timestamp.
     */
    uint32 public endTime;
    /**
     * @dev Each time the DLP/second ratio gets updated, the timestamp
     *      when the operation has occurred gets recorded into `lastRatioUpdate`.
     * @dev This timestamp is then used to check if seconds/update `secondsPerUpdate`
     *      has passed when decreasing yield reward by 3%.
     */
    uint32 public lastRatioUpdate;
    /**
     * @dev Each time the DLP/second ratio gets updated, the timestamp
     *      when the operation has occurred gets recorded into `lastAdditionalRatioUpdate`.
     * @dev This timestamp is then used to check if seconds/update `secondsPerUpdate`
     *      has passed when decreasing yield reward by 3%.
     */
    uint32 public lastAdditionalRatioUpdate;

    /// @dev DLP token address.
    address private _dlp;

    /// @dev RUN token address
    address private _run;

    /// @dev Maps pool token address (like DLP) -> pool address (like core pool instance).
    mapping(address => address) public pools;

    /// @dev Keeps track of registered pool addresses, maps pool address -> exists flag.
    mapping(address => bool) public poolExists;

   /**
     * @dev Fired in registerPool()
     *
     * @param by an address which executed an action
     * @param poolToken pool token address (like DLP)
     * @param poolAddress deployed pool instance address
     * @param weight pool weight
     * @param isFlashPool flag indicating if pool is a flash pool
     */
    event LogRegisterPool(
        address indexed by,
        address indexed poolToken,
        address indexed poolAddress,
        uint64 weight,
        bool isFlashPool
    );

    /**
     * @dev Fired in `changePoolWeight()`.
     *
     * @param by an address which executed an action
     * @param poolAddress deployed pool instance address
     * @param weight new pool weight
     */
    event LogChangePoolWeight(address indexed by, address indexed poolAddress, uint32 weight);


    /**
     * @dev Fired in `updateDLPPerSecond()`.
     *
     * @param by an address which executed an action
     * @param newDlpPerSecond new DLP/second value
     */
    event LogUpdateDLPPerSecond(address indexed by, uint256 newDlpPerSecond);

    /**
     * @dev Fired in `setEndTime()`.
     *
     * @param by an address which executed the action
     * @param endTime new endTime value
     */
    event LogSetEndTime(address indexed by, uint32 endTime);

    /**
     * @dev Initializes a factory instance
     *
     * @param dlp_ DLP ERC20 token address
     * @param run_ run ERC20 token address
     * @param _dlpPerSecond initial DLP/second value for rewards
     * @param _secondsPerUpdate how frequently the rewards gets updated (decreased by 3%), seconds
     * @param _initTime timestamp to measure _secondsPerUpdate from
     * @param _endTime timestamp number when farming stops and rewards cannot be updated anymore
     */
    
    function initialize(
        address dlp_,
        address run_,
        uint192 _dlpPerSecond,
        uint32 _secondsPerUpdate,
        uint32 _initTime,
        uint32 _endTime
    ) external initializer {
        bytes4 fnSelector = this.initialize.selector;
        // verify the inputs are set correctly
        fnSelector.verifyNonZeroInput(uint160(dlp_), 0);
        fnSelector.verifyNonZeroInput(uint160(run_), 1);
        fnSelector.verifyNonZeroInput(_dlpPerSecond, 2);
        fnSelector.verifyNonZeroInput(_secondsPerUpdate, 3);
        fnSelector.verifyNonZeroInput(_initTime, 4);
        fnSelector.verifyInput(_endTime > _now256(), 5);

        __Ownable_init();

        // save the inputs into internal state variables
        _dlp = dlp_;
        _run = run_;
        dlpPerSecond = _dlpPerSecond;
        secondsPerUpdate = _secondsPerUpdate;
        lastRatioUpdate = _initTime;
        endTime = _endTime;
        lastAdditionalRatioUpdate=_initTime;
    }

        /**
     * @notice Given a pool token retrieves corresponding pool address.
     *
     * @dev A shortcut for `pools` mapping.
     *
     * @param poolToken pool token address (like DLP) to query pool address for
     * @return pool address for the token specified
     */
    function getPoolAddress(address poolToken) external view virtual returns (address) {
        // read the mapping and return
        return address(pools[poolToken]);
    }

    /**
     * @notice Reads pool information for the pool defined by its pool token address,
     *      designed to simplify integration with the front ends.
     *
     * @param _poolToken pool token address to query pool information for.
     * @return pool information packed in a PoolData struct.
     */
    function getPoolData(address _poolToken) public view virtual returns (PoolData memory) {
        bytes4 fnSelector = this.getPoolData.selector;
        // get the pool address from the mapping
        ICorePool pool = ICorePool(pools[_poolToken]);

        // throw if there is no pool registered for the token specified
        fnSelector.verifyState(uint160(address(pool)) != 0, 0);

        // read pool information from the pool smart contract
        // via the pool interface (ICorePool)
        address poolToken = pool.poolToken();
        bool isFlashPool = pool.isFlashPool();
        uint32 weight = pool.weight();

        // create the in-memory structure and return it
        return PoolData({ poolToken: poolToken, poolAddress: address(pool), weight: weight, isFlashPool: isFlashPool });
    }


 /**
     * @dev Verifies if `secondsPerUpdate` has passed since last DLP/second
     *      ratio update and if DLP/second reward can be decreased by 3%.
     *
     * @return true if enough time has passed and `updateDLPPerSecond` can be executed.
     */
    function shouldUpdateAdditionalRatio() public  virtual returns (bool) {
        // if yield farming period has ended
        if (_now256() >= lastAdditionalRatioUpdate + secondsPerUpdate) {
        // set current timestamp as the last ratio update timestamp
        lastAdditionalRatioUpdate = (_now256()).toUint32();
        return true;
        }
        // check if seconds/update have passed since last update
       return false;
    }

     /**
     * @dev Verifies if `secondsPerUpdate` has passed since last DLP/second
     *      ratio update and if DLP/second reward can be decreased by 3%.
     *
     * @return true if enough time has passed and `updateDLPPerSecond` can be executed.
     */
    function shouldUpdateRatio() public view virtual returns (bool) {
        // if yield farming period has ended
        if (_now256() > endTime) {
            // DLP/second reward cannot be updated anymore
            return false;
        }

        // check if seconds/update have passed since last update
        return _now256() >= lastRatioUpdate + secondsPerUpdate;
    }

 /**
     * @dev Registers an already deployed pool instance within the factory.
     *
     * @dev Can be executed by the pool factory owner only.
     *
     * @param pool address of the already deployed pool instance
     */
    function registerPool(address pool) public virtual onlyOwner {
        // read pool information from the pool smart contract
        // via the pool interface (ICorePool)
        address poolToken = ICorePool(pool).poolToken();
        bool isFlashPool = ICorePool(pool).isFlashPool();
        uint32 weight = ICorePool(pool).weight();

        // create pool structure, register it within the factory
        pools[poolToken] = pool;
        poolExists[pool] = true;
        // update total pool weight of the factory
        totalWeight += weight;

        // emit an event
        emit LogRegisterPool(msg.sender, poolToken, address(pool), weight, isFlashPool);
    }

     /**
     * @notice Decreases DLP/second reward by 3%, can be executed
     *      no more than once per `secondsPerUpdate` seconds.
     */
    function updateDLPPerSecond() external virtual {
        bytes4 fnSelector = this.updateDLPPerSecond.selector;
        // checks if ratio can be updated i.e. if seconds/update have passed
        fnSelector.verifyState(shouldUpdateRatio(), 0);

        // decreases DLP/second reward by 3%.
        // To achieve that we multiply by 97 and then
        // divide by 100
        dlpPerSecond = (dlpPerSecond * 97) / 100;

        // set current timestamp as the last ratio update timestamp
        lastRatioUpdate = (_now256()).toUint32();

        // emit an event
        emit LogUpdateDLPPerSecond(msg.sender, dlpPerSecond);
    }

     /**
     * @dev Mints DLP tokens; executed by DLP Pool only.
     *
     * @dev Requires factory to have ROLE_TOKEN_CREATOR permission
     *      on the DLP ERC20 token instance.
     *
     * @param _to an address to mint tokens to
     * @param _value amount of DLP tokens to mint
     * @param _useRUN whether DLP or RUN should be minted
     */
    function mintYieldTo(
        address _to,
        uint256 _value,
        bool _useRUN
    ) external virtual {
        bytes4 fnSelector = this.mintYieldTo.selector;
        // verify that sender is a pool registered withing the factory
        fnSelector.verifyState(poolExists[msg.sender], 0);

        // mints the requested token to the indicated address
        if (!_useRUN) {
            IERC20Mintable(_dlp).mint(_to, _value);
        } else {
            IERC20Mintable(_run).mint(_to, _value);
        }
    }


 /**
     * @dev Changes the weight of the pool;
     *      executed by the pool itself or by the factory owner.
     *
     * @param pool address of the pool to change weight for
     * @param weight new weight value to set to
     */
    function changePoolWeight(address pool, uint32 weight) external virtual {
        bytes4 fnSelector = this.changePoolWeight.selector;
        // verify function is executed either by factory owner or by the pool itself
        fnSelector.verifyAccess(msg.sender == owner() || poolExists[msg.sender]);

        // recalculate total weight
        totalWeight = totalWeight + weight - ICorePool(pool).weight();

        // set the new pool weight
        ICorePool(pool).setWeight(weight);

        // emit an event
        emit LogChangePoolWeight(msg.sender, address(pool), weight);
    }

     /**
     * @dev Updates yield generation ending timestamp.
     *
     * @param _endTime new end time value to be stored
     */
    function setEndTime(uint32 _endTime) external virtual onlyOwner {
        bytes4 fnSelector = this.setEndTime.selector;
        // checks if _endTime is a timestap after the last time that
        // DLP/second has been updated
        fnSelector.verifyInput(_endTime > lastRatioUpdate, 0);
        // updates endTime state var
        endTime = _endTime;

        // emits an event
        emit LogSetEndTime(msg.sender, _endTime);
    }


 /**
     * @dev Overrides `Ownable.renounceOwnership()`, to avoid accidentally
     *      renouncing ownership of the PoolFactory contract.
     */
    function renounceOwnership() public virtual override {}

    /// @dev See `CorePool._authorizeUpgrade()`
    function _authorizeUpgrade(address) internal virtual override onlyOwner {}

    /**
     * @dev Empty reserved space in storage. The size of the __gap array is calculated so that
     *      the amount of storage used by a contract always adds up to the 50.
     *      See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;

    function test() public pure returns(uint256){

        return 1+2;

    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

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
        bool isTopLevelCall = _setInitializedVersion(1);
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
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
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
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate that the this implementation remains valid after an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeCast.sol)

pragma solidity ^0.8.0;

import { ErrorHandler } from "./ErrorHandler.sol";

/**
 * @notice Copied from OpenZeppelin's SafeCast.sol, adapted to use just in the required
 * uint sizes.
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    using ErrorHandler for bytes4;

    /**
     * @dev Returns the downcasted uint248 from uint256, reverting on
     * overflow (when the input is greater than largest uint248).
     *
     * Counterpart to Solidity's `uint248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     */
    function toUint248(uint256 _value) internal pure returns (uint248) {
        // we're using selector to simplify input and state validation
        // internal function simulated selector is `bytes4(keccak256("toUint248(uint256))"))`
        bytes4 fnSelector = 0x3fd72672;
        fnSelector.verifyInput(_value <= type(uint248).max, 0);

        return uint248(_value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 _value) internal pure returns (uint128) {
        // we're using selector to simplify input and state validation
        // internal function simulated selector is `bytes4(keccak256("toUint128(uint256))"))`
        bytes4 fnSelector = 0x809fdd33;
        fnSelector.verifyInput(_value <= type(uint128).max, 0);

        return uint128(_value);
    }

    /**
     * @dev Returns the downcasted uint120 from uint256, reverting on
     * overflow (when the input is greater than largest uint120).
     *
     * Counterpart to Solidity's `uint120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     */
    function toUint120(uint256 _value) internal pure returns (uint120) {
        // we're using selector to simplify input and state validation
        // internal function simulated selector is `bytes4(keccak256("toUint120(uint256))"))`
        bytes4 fnSelector = 0x1e4e4bad;
        fnSelector.verifyInput(_value <= type(uint120).max, 0);

        return uint120(_value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 _value) internal pure returns (uint64) {
        // we're using selector to simplify input and state validation
        // internal function simulated selector is `bytes4(keccak256("toUint64(uint256))"))`
        bytes4 fnSelector = 0x2665fad0;
        fnSelector.verifyInput(_value <= type(uint64).max, 0);

        return uint64(_value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 _value) internal pure returns (uint32) {
        // we're using selector to simplify input and state validation
        // internal function simulated selector is `bytes4(keccak256("toUint32(uint256))"))`
        bytes4 fnSelector = 0xc8193255;
        fnSelector.verifyInput(_value <= type(uint32).max, 0);

        return uint32(_value);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Function for getting block timestamp.
/// @dev Base contract that is overridden for tests.
abstract contract Timestamp {
    /**
     * @dev Testing time-dependent functionality is difficult and the best way of
     *      doing it is to override time in helper test smart contracts.
     *
     * @return `block.timestamp` in mainnet, custom values in testnets (if overridden).
     */
    function _now256() internal view virtual returns (uint256) {
        // return current block timestamp
        return block.timestamp;
    }

    /**
     * @dev Empty reserved space in storage. The size of the __gap array is calculated so that
     *      the amount of storage used by a contract always adds up to the 50.
     *      See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Stake} from "../lib/Stake.sol";

interface ICorePool {
    function users(address _user)
        external
        view
        returns (
            uint128,
            uint128,
            uint256,
            uint256,
            uint256
        );

    function poolToken() external view returns (address);

    function isFlashPool() external view returns (bool);

    function weight() external view returns (uint32);

    function lastYieldDistribution() external view returns (uint64);

    function yieldRewardsPerWeight() external view returns (uint256);

    function globalWeight() external view returns (uint256);

    function pendingRewards(address _user)
        external
        view
        returns (uint256, uint256);

    function poolTokenReserve() external view returns (uint256);

    function balanceOf(address _user) external view returns (uint256);

    function getTotalReserves() external view returns (uint256);

    function getStake(address _user, uint256 _stakeId)
        external
        view
        returns (Stake.Data memory);

    function getStakesLength(address _user) external view returns (uint256);

    function sync() external;

    function setWeight(uint32 _weight) external;

    function receiveVaultRewards(uint256 value) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IERC20Mintable is IERC20Upgradeable {
    function mint(address _to, uint256 _value) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Errors Library.
 *
 * @notice Introduces some very common input and state validation for smart contracts,
 *      such as non-zero input validation, general boolean expression validation, access validation.
 *
 * @notice Throws pre-defined errors instead of string error messages to reduce gas costs.
 *
 * @notice Since the library handles only very common errors, concrete smart contracts may
 *      also introduce their own error types and handling.
 *
 */
library ErrorHandler {
    /**
     * @notice Thrown on zero input at index specified in a function specified.
     *
     * @param fnSelector function selector, defines a function where error was thrown
     * @param paramIndex function parameter index which caused an error thrown
     */
    error ZeroInput(bytes4 fnSelector, uint8 paramIndex);

    /**
     * @notice Thrown on invalid input at index specified in a function specified.
     *
     * @param fnSelector function selector, defines a function where error was thrown
     * @param paramIndex function parameter index which caused an error thrown
     */
    error InvalidInput(bytes4 fnSelector, uint8 paramIndex);

    /**
     * @notice Thrown on invalid state in a function specified.
     *
     * @param fnSelector function selector, defines a function where error was thrown
     * @param errorCode unique error code determining the exact place in code where error was thrown
     */
    error InvalidState(bytes4 fnSelector, uint256 errorCode);

    /**
     * @notice Thrown on invalid access to a function specified.
     *
     * @param fnSelector function selector, defines a function where error was thrown
     * @param addr an address which access was denied, usually transaction sender
     */
    error AccessDenied(bytes4 fnSelector, address addr);

    /**
     * @notice Verifies an input is set (non-zero).
     *
     * @param fnSelector function selector, defines a function which called the verification
     * @param value a value to check if it's set (non-zero)
     * @param paramIndex function parameter index which is verified
     */
    function verifyNonZeroInput(
        bytes4 fnSelector,
        uint256 value,
        uint8 paramIndex
    ) internal pure {
        if (value == 0) {
            revert ZeroInput(fnSelector, paramIndex);
        }
    }

    /**
     * @notice Verifies an input is correct.
     *
     * @param fnSelector function selector, defines a function which called the verification
     * @param expr a boolean expression used to verify the input
     * @param paramIndex function parameter index which is verified
     */
    function verifyInput(
        bytes4 fnSelector,
        bool expr,
        uint8 paramIndex
    ) internal pure {
        if (!expr) {
            revert InvalidInput(fnSelector, paramIndex);
        }
    }

    /**
     * @notice Verifies smart contract state is correct.
     *
     * @param fnSelector function selector, defines a function which called the verification
     * @param expr a boolean expression used to verify the contract state
     * @param errorCode unique error code determining the exact place in code which is verified
     */
    function verifyState(
        bytes4 fnSelector,
        bool expr,
        uint256 errorCode
    ) internal pure {
        if (!expr) {
            revert InvalidState(fnSelector, errorCode);
        }
    }

    /**
     * @notice Verifies an access to the function.
     *
     * @param fnSelector function selector, defines a function which called the verification
     * @param expr a boolean expression used to verify the access
     */
    function verifyAccess(bytes4 fnSelector, bool expr) internal view {
        if (!expr) {
            revert AccessDenied(fnSelector, msg.sender);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
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
pragma solidity ^0.8.0;

/**
 * @dev Stake library used by DLP pool and Uniswap LP Pool.
 *
 * @dev Responsible to manage weight calculation and store important constants
 *      related to stake period, base weight and multipliers utilized.
 */
library Stake {
    struct Data {
        /// @dev token amount staked
        uint120 value;
        /// @dev locking period - from
        uint64 lockedFrom;
        /// @dev locking period - until
        uint64 lockedUntil;
        /// @dev indicates if the stake was created as a yield reward
        bool isYield;
        ///@dev Is it the dividend generated by DLP transferred in by the foundation
        bool isAdditional;
    }

    /**
     * @dev Stake weight is proportional to stake value and time locked, precisely
     *      "stake value wei multiplied by (fraction of the year locked plus one)".
     * @dev To avoid significant precision loss due to multiplication by "fraction of the year" [0, 1],
     *      weight is stored multiplied by 1e6 constant, as an integer.
     * @dev Corner case 1: if time locked is zero, weight is stake value multiplied by 1e6 + base weight
     * @dev Corner case 2: if time locked is two years, division of
            (lockedUntil - lockedFrom) / MAX_STAKE_PERIOD is 1e6, and
     *      weight is a stake value multiplied by 2 * 1e6.
     */
    uint256 internal constant WEIGHT_MULTIPLIER = 1e6;

    /**
     * @dev Minimum weight value, if result of multiplication using WEIGHT_MULTIPLIER
     *      is 0 (e.g stake flexible), then BASE_WEIGHT is used.
     */
    uint256 internal constant BASE_WEIGHT = 1e6;
    /**
     * @dev Minimum period that someone can lock a stake for.
     */
    uint256 internal constant MIN_STAKE_PERIOD = 30 days;

    /**
     * @dev Maximum period that someone can lock a stake for.
     */
    uint256 internal constant MAX_STAKE_PERIOD = 365 days;

    /**
     * @dev Rewards per weight are stored multiplied by 1e20 as uint.
     */
    uint256 internal constant REWARD_PER_WEIGHT_MULTIPLIER = 1e20;

    /**
     * @dev When we know beforehand that staking is done for yield instead of
     *      executing `weight()` function we use the following constant.
     */
    uint256 internal constant YIELD_STAKE_WEIGHT_MULTIPLIER = 2 * 1e6;

    function weight(Data storage _self) internal view returns (uint256) {
        return
            uint256(
                (((_self.lockedUntil - _self.lockedFrom) * WEIGHT_MULTIPLIER) / MAX_STAKE_PERIOD + BASE_WEIGHT) *
                    _self.value

            );
    }

    /**
     * @dev Converts stake weight (not to be mixed with the pool weight) to
     *      DLP reward value, applying the 10^12 division on weight
     *
     * @param _weight stake weight
     * @param _rewardPerWeight DLP reward per weight
     * @param _rewardPerWeightPaid last reward per weight value used for user earnings
     * @return reward value normalized to 10^12
     */
    function earned(
        uint256 _weight,
        uint256 _rewardPerWeight,
        uint256 _rewardPerWeightPaid
    ) internal pure returns (uint256) {
        // apply the formula and return
        return (_weight * (_rewardPerWeight - _rewardPerWeightPaid)) / REWARD_PER_WEIGHT_MULTIPLIER;
    }

    /**
     * @dev Converts reward DLP value to stake weight (not to be mixed with the pool weight),
     *      applying the 10^12 multiplication on the reward.
     *      - OR -
     * @dev Converts reward DLP value to reward/weight if stake weight is supplied as second
     *      function parameter instead of reward/weight.
     *
     * @param _reward yield reward
     * @param _globalWeight total weight in the pool
     * @return reward per weight value
     */
    function getRewardPerWeight(uint256 _reward, uint256 _globalWeight) internal pure returns (uint256) {
        // apply the reverse formula and return
        return (_reward * REWARD_PER_WEIGHT_MULTIPLIER) / _globalWeight;
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