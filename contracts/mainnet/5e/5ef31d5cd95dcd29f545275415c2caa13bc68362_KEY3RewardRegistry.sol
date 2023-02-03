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
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Context.sol";

contract Controllable is Context {
    mapping(address => bool) public controllers;

    event ControllerAdded(address indexed controller);
    event ControllerRemoved(address indexed controller);

    modifier onlyController() {
        require(controllers[_msgSender()]);
        _;
    }

    function _addController(address controller_) internal virtual {
        controllers[controller_] = true;
        emit ControllerAdded(controller_);
    }

    function _removeController(address controller_) internal virtual {
        controllers[controller_] = false;
        emit ControllerRemoved(controller_);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IKEY3RewardRegistry {
    struct Reward {
        string name;
        uint256 claimedAt;
        uint256 expiredAt;
        bool claimed;
    }

    event Claim(address indexed user, string name);

    function baseNode() external view returns (bytes32);

    function rewardsOf(address user) external view returns (Reward[] memory);

    function exists(address user, string memory name)
        external
        view
        returns (bool, uint);

    function claim(address user) external returns (string[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./IKEY3RewardRegistry.sol";
import "./access/Controllable.sol";

contract KEY3RewardRegistry is IKEY3RewardRegistry, Ownable, Controllable {
    mapping(address => Reward[]) public rewards;
    bytes32 public baseNode;

    constructor(bytes32 baseNode_) {
        baseNode = baseNode_;
    }

    function addController(address controller_) public onlyOwner {
        _addController(controller_);
    }

    function removeController(address controller_) public onlyOwner {
        _removeController(controller_);
    }

    function addRewards(
        address[] memory users_,
        string[] memory names_,
        uint256 expiredAt_
    ) public onlyOwner {
        require(users_.length == names_.length, "users length != names length");
        for (uint i = 0; i < users_.length; i++) {
            (bool exist, uint index) = _exists(users_[i], names_[i]);
            if (exist) {
                Reward memory reward = rewards[users_[i]][index];
                if (!reward.claimed) {
                    reward.expiredAt = expiredAt_;
                    rewards[users_[i]][index] = reward;
                }
            } else {
                rewards[users_[i]].push(
                    Reward({
                        name: names_[i],
                        expiredAt: expiredAt_,
                        claimed: false,
                        claimedAt: 0
                    })
                );
            }
        }
    }

    function removeRewards(
        address[] memory users_,
        string[] memory names_
    ) public onlyOwner {
        require(users_.length == names_.length, "users length != names length");
        for (uint i = 0; i < users_.length; i++) {
            (bool exist, uint index) = _exists(users_[i], names_[i]);
            if (exist) {
                delete rewards[users_[i]][index];
            }
        }
    }

    function rewardsOf(address user_) public view returns (Reward[] memory) {
        return rewards[user_];
    }

    function exists(
        address user_,
        string memory name_
    ) public view returns (bool, uint) {
        (bool exist, uint index) = _exists(user_, name_);
        if (!exist) {
            return (exist, index);
        }
        Reward memory reward = rewards[user_][index];
        if (
            (reward.claimed && reward.claimedAt != block.timestamp) ||
            reward.expiredAt <= block.timestamp
        ) {
            return (false, 0);
        }
        return (exist, index);
    }

    function claim(
        address user_
    ) external onlyController returns (string[] memory) {
        string[] memory temp = new string[](rewards[user_].length);
        uint index = 0;
        for (uint i = 0; i < rewards[user_].length; i++) {
            Reward memory reward = rewards[user_][i];
            if (reward.claimed || reward.expiredAt <= block.timestamp) {
                continue;
            }

            reward.claimed = true;
            reward.claimedAt = block.timestamp;
            rewards[user_][i] = reward;

            temp[index] = reward.name;
            emit Claim(user_, reward.name);

            index++;
        }

        string[] memory names = new string[](index);
        for (uint i = 0; i < index; i++) {
            names[i] = temp[i];
        }

        return names;
    }

    function _exists(
        address user_,
        string memory name_
    ) internal view returns (bool, uint) {
        if (bytes(name_).length == 0) {
            return (false, 0);
        }

        for (uint i = 0; i < rewards[user_].length; i++) {
            Reward memory reward = rewards[user_][i];
            if (keccak256(bytes(reward.name)) == keccak256(bytes(name_))) {
                return (true, i);
            }
        }

        return (false, 0);
    }
}