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

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.15;

/// @title Interface for the OpWorldID contract
interface IOpWorldID {
    /// @notice receiveRoot is called by the L1 Proxy contract which forwards new Semaphore roots to L2.
    /// @param newRoot new valid root with ROOT_HISTORY_EXPIRY validity
    /// @param timestamp Ethereum block timestamp of the new Semaphore root
    function receiveRoot(uint256 newRoot, uint128 timestamp) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.15;

/// @title ISemaphoreRoot
/// @author Worldcoin
/// @dev used to check if a root is valid for the StateBridge
interface IWorldIDIdentityManager {
    /// @notice Checks if a given root value is valid and has been added to the root history.
    /// @dev Reverts with `ExpiredRoot` if the root has expired, and `NonExistentRoot` if the root
    ///      is not in the root history.
    ///
    /// @param root The root of a given identity group.
    function checkValidRoot(uint256 root) external view returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.15;

// Optimism interface for cross domain messaging
import {IOpWorldID} from "../interfaces/IOpWorldID.sol";
import {Ownable} from "openzeppelin-contracts/access/Ownable.sol";
import {IWorldIDIdentityManager} from "../interfaces/IWorldIDIdentityManager.sol";

contract MockStateBridge is Ownable {
    /// @notice The address of the MockOpPolygonWorldID contract
    address public mockOpPolygonWorldIDAddress;

    /// @notice Interface for checkValidRoot within the WorldID Identity Manager contract
    address public worldIDAddress;

    IWorldIDIdentityManager internal worldID;

    /// @notice Emmited when the root is not a valid root in the canonical WorldID Identity Manager contract
    error InvalidRoot();

    /// @notice constructor
    /// @param _worldIDIdentityManager Deployment address of the WorldID Identity Manager contract
    /// @param _mockOpPolygonWorldIDAddress Address of the MockOpPolygonWorldID contract for the new root and timestamp
    constructor(address _worldIDIdentityManager, address _mockOpPolygonWorldIDAddress) {
        mockOpPolygonWorldIDAddress = _mockOpPolygonWorldIDAddress;
        worldIDAddress = _worldIDIdentityManager;
        worldID = IWorldIDIdentityManager(_worldIDIdentityManager);
    }

    /// @notice Sends the latest WorldID Identity Manager root to all chains.
    /// @dev Calls this method on the L1 Proxy contract to relay roots and timestamps to WorldID supported chains.
    /// @param root The latest WorldID Identity Manager root.
    function sendRootMultichain(uint256 root) public {
        // If the root is not a valid root in the canonical WorldID Identity Manager contract, revert
        // comment out for mock deployments

        if (!worldID.checkValidRoot(root)) revert InvalidRoot();

        uint128 timestamp = uint128(block.timestamp);
        _sendRootToMockOpPolygonWorldID(root, timestamp);
    }

    /*//////////////////////////////////////////////////////////////
                                OPTIMISM
    //////////////////////////////////////////////////////////////*/

    // @notice Sends the latest WorldID Identity Manager root to all chains.
    /// @dev Calls this method on the L1 Proxy contract to relay roots and timestamps to WorldID supported chains.
    /// @param root The latest WorldID Identity Manager root.
    /// @param timestamp The Ethereum block timestamp of the latest WorldID Identity Manager root.
    function _sendRootToMockOpPolygonWorldID(uint256 root, uint128 timestamp) internal {
        bytes memory message;

        message = abi.encodeCall(IOpWorldID.receiveRoot, (root, timestamp));

        mockOpPolygonWorldIDAddress.call(message);
    }
}