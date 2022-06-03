// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
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
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";

library ProxyFactory {
    /* functions */

    function _create(address logic, bytes memory data) internal returns (address proxy) {
        // deploy clone
        proxy = Clones.clone(logic);

        // attempt initialization
        if (data.length > 0) {
            (bool success, bytes memory err) = proxy.call(data);
            require(success, string(err));
        }

        // explicit return
        return proxy;
    }

    function _create2(
        address logic,
        bytes memory data,
        bytes32 salt
    ) internal returns (address proxy) {
        // deploy clone
        proxy = Clones.cloneDeterministic(logic, salt);

        // attempt initialization
        if (data.length > 0) {
            (bool success, bytes memory err) = proxy.call(data);
            require(success, string(err));
        }

        // explicit return
        return proxy;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;

import { ProxyFactory } from 'alchemist/factory/ProxyFactory.sol';
import { Ownable } from '@openzeppelin/contracts/access/Ownable.sol';
import { IAludel } from './aludel/IAludel.sol';
import { InstanceRegistry } from "./libraries/InstanceRegistry.sol";

import {EnumerableSet} from "./libraries/EnumerableSet.sol";

import {EnumerableSet} from "./libraries/EnumerableSet.sol";

contract AludelFactory is Ownable, InstanceRegistry {

	using EnumerableSet for EnumerableSet.TemplateDataSet;

	struct ProgramData {
		address template;
		uint64 creation;
		string name;
		string stakingTokenUrl;
	}

    /// @notice set of template data
	EnumerableSet.TemplateDataSet private _templates;

	/// @notice address => ProgramData mapping
	mapping(address => ProgramData) private _programs;

	/// @dev emitted when a new template is added 
	event TemplateAdded(address template);
	/// @dev emitted when a template is updated 
	event TemplateUpdated(address template, bool disabled);

	/// @dev emitted when a program's url is changed
	event StakingTokenURLChanged(address program, string url);
	/// @dev emitted when a program's name is changed
	event NameChanged(address program, string name);

	error InvalidTemplate();
	error TemplateNotRegistered();
	error TemplateDisabled();
	error TemplateAlreadyAdded();
	error ProgramAlreadyRegistered();

	/// @notice perform a minimal proxy deploy of a predefined aludel templat
	/// @param template the number of the template to launch
	/// @param name the string represeting the program's name
	/// @param stakingTokenUrl the program's url
	/// @param data the calldata to use on the new aludel initialization
	/// @return aludel the new aludel deployed address.
	function launch(
		address template,
		string memory name,
		string memory stakingTokenUrl,
		bytes calldata data
	) public returns (address aludel) {

		// reverts when template address is not registered
		if (!_templates.contains(template)) {
			revert TemplateNotRegistered();
		}

		// reverts when template is disabled
		if (_templates.at(template).disabled) {
			revert TemplateDisabled();
		}

		// create clone and initialize
		aludel = ProxyFactory._create(
            template,
            abi.encodeWithSelector(IAludel.initialize.selector, data)
        );
		
		// add program's data to the storage 
		_programs[aludel] = ProgramData({
			creation: uint64(block.timestamp),
			template: template,
			name: name,
			stakingTokenUrl: stakingTokenUrl
		});

		// register aludel instance
		_register(aludel);
		
		// explicit return
		return aludel;
	}

	/* admin */

	/// @notice adds a new template to the factory
	function addTemplate(address template) public onlyOwner returns (uint256 templateIndex) {

		// cannot add address(0) as template
		if (template == address(0)) {
			revert InvalidTemplate();
		}

		// create template data
		EnumerableSet.TemplateData memory data = EnumerableSet.TemplateData({
			template: template,
			disabled: false
		});

		// add template to the storage
		if (!_templates.add(data)) {
			revert TemplateAlreadyAdded();
		}

		// emit event
		emit TemplateAdded(template);

		return _templates.length();
	}

	/// @notice sets a template as disable or enabled 
	function updateTemplate(address template, bool disabled) external onlyOwner {
		if (!_templates.contains(template)) {
			revert InvalidTemplate();
		}
		// update disable value for the given template
		require(_templates.update(template, disabled));
		// emit event
		emit TemplateUpdated(template, disabled);
	}

	/// @notice updates the stakingTokenUrl for a given program
	function updateStakingTokenUrl(address program, string memory newUrl) external onlyOwner {
		// check if the address is already registered
		require(isInstance(program));
		// update storage
		_programs[program].stakingTokenUrl = newUrl;
		// emit event
		emit StakingTokenURLChanged(program, newUrl);
	}

	/// @notice updates the name for a given program
	function updateName(address program, string memory newName) external onlyOwner {
		// check if the address is already registered
		require(isInstance(program));
		// update storage
		_programs[program].name = newName;
		// emit event
		emit NameChanged(program, newName);	
	}

	/// @notice allow owner to manually add a program
	/// @dev this allows onchain storage of pre-aludel factory programs
	function addProgram(
		address program,
		address template,
		string memory name,
		string memory stakingTokenUrl
	) external onlyOwner {

		// register aludel instance
		// if program is already registered this will revert
		_register(program);

		// add program's data to the storage 
		_programs[program] = ProgramData({
			creation: uint64(block.timestamp),
			template: template,
			name: name,
			stakingTokenUrl: stakingTokenUrl
		});
	}

	/// @notice removes program as a registered instance of the factory.
	function delistProgram(address program) external onlyOwner {
		_unregister(program);
	}

	/* getters */

	/// @notice retrieves the program's url
	function getStakingTokenUrl(address program) external view returns (string memory) {
		return _programs[program].stakingTokenUrl;
	}

	/// @notice retrieves a program's data
	function getProgram(address program) external view returns (ProgramData memory) {
		return _programs[program];
	}

	/// @notice retrieves the full list of templates (even disabled templates)
	function getTemplates() external view returns(EnumerableSet.TemplateData[] memory) {
		return _templates.values();
	}

	/// @notice retrieves a template's data
	function getTemplate(address template) external view returns(EnumerableSet.TemplateData memory) {
		return _templates.at(template);
	}

}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;
pragma abicoder v2;

interface IRageQuit {
    function rageQuit() external;
}

interface IAludel is IRageQuit {
    /* admin events */

    event AludelCreated(address rewardPool, address powerSwitch);
    event AludelFunded(uint256 amount, uint256 duration);
    event BonusTokenRegistered(address token);
    event VaultFactoryRegistered(address factory);
    event VaultFactoryRemoved(address factory);

    /* user events */

    event Staked(address vault, uint256 amount);
    event Unstaked(address vault, uint256 amount);
    event RewardClaimed(address vault, address token, uint256 amount);

    /* data types */

    struct AludelData {
        address stakingToken;
        address rewardToken;
        address rewardPool;
        RewardScaling rewardScaling;
        uint256 rewardSharesOutstanding;
        uint256 totalStake;
        uint256 totalStakeUnits;
        uint256 lastUpdate;
        RewardSchedule[] rewardSchedules;
    }

    struct RewardSchedule {
        uint256 duration;
        uint256 start;
        uint256 shares;
    }

    struct VaultData {
        uint256 totalStake;
        StakeData[] stakes;
    }

    struct StakeData {
        uint256 amount;
        uint256 timestamp;
    }

    struct RewardScaling {
        uint256 floor;
        uint256 ceiling;
        uint256 time;
    }

    struct RewardOutput {
        uint256 lastStakeAmount;
        uint256 newStakesCount;
        uint256 reward;
        uint256 newTotalStakeUnits;
    }

    function initializeLock() external;

    function initialize(
        bytes calldata
    ) external;

    /* user functions */

    function stake(
        address vault,
        uint256 amount,
        bytes calldata permission
    ) external;

    function unstakeAndClaim(
        address vault,
        uint256 amount,
        bytes calldata permission
    ) external;

    /* admin functions */

    function fund(uint256 amount, uint256 duration) external;
    
    function registerVaultFactory(address factory) external;
    
    function removeVaultFactory(address factory) external;
    
    function registerBonusToken(address bonusToken) external;

    function rescueTokensFromRewardPool(
        address token,
        address recipient,
        uint256 amount
    ) external;

    /* getter functions */

    function getAludelData() external view returns (AludelData memory aludel);

    function getBonusTokenSetLength() external view returns (uint256 length);

    function getBonusTokenAtIndex(uint256 index) external view returns (address bonusToken);

    function getVaultFactorySetLength() external view returns (uint256 length);

    function getVaultFactoryAtIndex(uint256 index) external view returns (address factory);

    function getVaultData(address vault) external view returns (VaultData memory vaultData);

    function isValidAddress(address target) external view returns (bool validity);

    function isValidVault(address target) external view returns (bool validity);

    function getCurrentUnlockedRewards() external view returns (uint256 unlockedRewards);

    function getFutureUnlockedRewards(uint256 timestamp)
        external
        view
        returns (uint256 unlockedRewards);

    function getCurrentVaultReward(address vault) external view returns (uint256 reward);

    function getCurrentStakeReward(address vault, uint256 stakeAmount)
        external
        view
        returns (uint256 reward);

    function getFutureVaultReward(address vault, uint256 timestamp)
        external
        view
        returns (uint256 reward);

    function getFutureStakeReward(
        address vault,
        uint256 stakeAmount,
        uint256 timestamp
    ) external view returns (uint256 reward);

    function getCurrentVaultStakeUnits(address vault) external view returns (uint256 stakeUnits);

    function getFutureVaultStakeUnits(address vault, uint256 timestamp)
        external
        view
        returns (uint256 stakeUnits);

    function getCurrentTotalStakeUnits() external view returns (uint256 totalStakeUnits);

    function getFutureTotalStakeUnits(uint256 timestamp)
        external
        view
        returns (uint256 totalStakeUnits);

    /* pure functions */

    function calculateTotalStakeUnits(StakeData[] memory stakes, uint256 timestamp)
        external
        pure
        returns (uint256 totalStakeUnits);

    function calculateStakeUnits(
        uint256 amount,
        uint256 start,
        uint256 end
    ) external pure returns (uint256 stakeUnits);

    function calculateUnlockedRewards(
        RewardSchedule[] memory rewardSchedules,
        uint256 rewardBalance,
        uint256 sharesOutstanding,
        uint256 timestamp
    ) external pure returns (uint256 unlockedRewards);

    function calculateRewardFromStakes(
        StakeData[] memory stakes,
        uint256 unstakeAmount,
        uint256 unlockedRewards,
        uint256 totalStakeUnits,
        uint256 timestamp,
        RewardScaling memory rewardScaling
    ) external pure returns (RewardOutput memory out);

    function calculateReward(
        uint256 unlockedRewards,
        uint256 stakeAmount,
        uint256 stakeDuration,
        uint256 totalStakeUnits,
        RewardScaling memory rewardScaling
    ) external pure returns (uint256 reward);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct TemplateData {
        address template;
        bool disabled;
    }

    struct TemplateDataSet {
        // Storage of set values
        TemplateData[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(address => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(TemplateDataSet storage set, TemplateData memory value) internal returns (bool) {
        if (!contains(set, value.template)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value.template] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(TemplateDataSet storage set, TemplateData memory value) internal returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value.template];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                TemplateData memory lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue.template] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value.template];

            return true;
        } else {
            return false;
        }
    }

    function update(TemplateDataSet storage set, address template, bool disabled) internal returns (bool) {
        // check whether `template` is present in the set`
        if (contains(set, template)) {
            // get value's index
            uint256 valueIndex = set._indexes[template];
            // update value at `valueIndex` position with `disabled` value.
            set._values[valueIndex - 1].disabled = disabled;

            return true;
        }

        // no effects
        return false;
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(TemplateDataSet storage set, address template) internal view returns (bool) {
        return set._indexes[template] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(TemplateDataSet storage set) internal view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored with a template value matching `template` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `template` must exist as a key in `_indexes`.
     */
    function at(TemplateDataSet storage set, address template) internal view returns (TemplateData memory) {
        uint256 index = set._indexes[template];
        return set._values[index-1];
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `template` must be exist less than {length}.
     */
    function at(TemplateDataSet storage set, uint256 index) internal view returns (TemplateData memory) {
        
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(TemplateDataSet storage set) internal view returns (TemplateData[] memory) {
        return set._values;
    }

    // /**
    //  * @dev Return the entire set in an array
    //  *
    //  * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
    //  * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
    //  * this function has an unbounded cost, and using it as part of a state-changing function may render the function
    //  * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
    //  */
    // function values(AddressSet storage set) internal view returns (address[] memory) {
    //     bytes32[] memory store = _values(set._inner);
    //     address[] memory result;

    //     assembly {
    //         result := store
    //     }

    //     return result;
    // }

}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

interface IInstanceRegistry {
    /* events */

    event InstanceAdded(address instance);
    event InstanceRemoved(address instance);

    /* errors */

    error InstanceAlreadyRegistered();

    error InstanceNotRegistered();

    /* view functions */

    function isInstance(address instance) external view returns (bool validity);

    function instanceCount() external view returns (uint256 count);

    function instanceAt(uint256 index) external view returns (address instance);
}

/// @title InstanceRegistry
contract InstanceRegistry is IInstanceRegistry {
    using EnumerableSet for EnumerableSet.AddressSet;

    /* storage */

    EnumerableSet.AddressSet private _instanceSet;

    /* view functions */

    function isInstance(address instance) public view override returns (bool validity) {
        return _instanceSet.contains(instance);
    }

    function instanceCount() public view override returns (uint256 count) {
        return _instanceSet.length();
    }

    function instanceAt(uint256 index) public view override returns (address instance) {
        return _instanceSet.at(index);
    }

    /* admin functions */

    function _register(address instance) internal {
        if (!_instanceSet.add(instance)) {
            revert InstanceAlreadyRegistered();
        }
        emit InstanceAdded(instance);
    }

    function _unregister(address instance) internal {
        if (!_instanceSet.contains(instance)) {
            revert InstanceNotRegistered();
        }

        require(_instanceSet.remove(instance));

        emit InstanceRemoved(instance);
    }
}