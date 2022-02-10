// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.6;

import { ProxyFactory } from './factory/ProxyFactory.sol';
import { Ownable } from '@openzeppelin/contracts/access/Ownable.sol';
import { IAludel } from './aludel/IAludel.sol';

contract AludelFactory is Ownable {
    /// @notice array of template addresses
	address[] private _templates;

    /// @dev event emitted every time a new aludel is spawned
	event AludelSpawned(address aludel);

	constructor() Ownable() {}

    /// @notice perform a minimal proxy deploy
    /// @param templateId the number of the template to launch
    /// @param data the calldata to use on the new aludel initialization
    /// @return aludel the new aludel address.
	function launch(uint256 templateId, bytes calldata data) public returns (address aludel) {
        // get the aludel template address
		address template = _templates[templateId];

		// create clone and initialize
		aludel = ProxyFactory._create(
            template,
            abi.encodeWithSelector(IAludel.initialize.selector, data)
        );

		// emit event
		emit AludelSpawned(aludel);

		// explicit return
		return aludel;
	}

	function addTemplate(address template) public onlyOwner {
		// do we need any checks here?
        require(template != address(0), "invalid template");

		// add template to the list
		_templates.push(template);

        // bleep?
	}

	function getTemplate(uint256 templateId) public view returns (address) {
		return _templates[templateId];
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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