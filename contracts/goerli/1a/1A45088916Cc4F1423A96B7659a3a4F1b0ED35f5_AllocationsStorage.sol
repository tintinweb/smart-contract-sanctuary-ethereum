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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

library AllocationErrors {
    /// @notice Thrown when the user trying to allocate for proposal with id equals 0
    /// @return HN:Allocations/proposal-id-equals-0
    string public constant PROPOSAL_ID_CANNOT_BE_ZERO = "HN:Allocations/proposal-id-equals-0";

    /// @notice Thrown when the user trying to allocate before first epoch has started
    /// @return HN:Allocations/not-started-yet
    string public constant EPOCHS_HAS_NOT_STARTED_YET = "HN:Allocations/first-epoch-not-started-yet";

    /// @notice Thrown when the user trying to allocate after decision window is closed
    /// @return HN:Allocations/decision-window-closed
    string public constant DECISION_WINDOW_IS_CLOSED = "HN:Allocations/decision-window-closed";

    /// @notice Thrown when user trying to allocate more than he has in rewards budget for given epoch.
    /// @return HN:Allocations/allocate-above-rewards-budget
    string public constant ALLOCATE_ABOVE_REWARDS_BUDGET = "HN:Allocations/allocate-above-rewards-budget";
}

library AllocationStorageErrors {
    /// @notice Thrown when trying to allocate without removing it first. Should never occur as this
    /// is called from Allocations contract
    /// @return HN:AllocationsStorage/allocation-already-exists
    string public constant ALLOCATION_ALREADY_EXISTS = "HN:AllocationsStorage/allocation-already-exists";

    /// @notice Thrown when trying to allocate which does not exist. Should never occur as this
    /// is called from Allocations contract.
    /// @return HN:AllocationsStorage/allocation-does-not-exist
    string public constant ALLOCATION_DOES_NOT_EXIST = "HN:AllocationsStorage/allocation-does-not-exist";
}

library OracleErrors {
    /// @notice Thrown when trying to set the balance in oracle for epochs other then previous.
    /// @return HN:Oracle/can-set-balance-for-previous-epoch-only
    string public constant CANNOT_SET_BALANCE_FOR_PAST_EPOCHS =
    "HN:Oracle/can-set-balance-for-previous-epoch-only";

    /// @notice Thrown when trying to set the oracle balance multiple times.
    /// @return HN:Oracle/balance-for-given-epoch-already-exists
    string public constant BALANCE_ALREADY_SET = "HN:Oracle/balance-for-given-epoch-already-exists";
}

library DepositsErrors {
    /// @notice Thrown when transfer operation fails in GLM smart contract.
    /// @return HN:Deposits/cannot-transfer-from-sender
    string public constant GLM_TRANSFER_FAILED = "HN:Deposits/cannot-transfer-from-sender";

    /// @notice Thrown when trying to withdraw more GLMs than are in deposit.
    /// @return HN:Deposits/deposit-is-smaller
    string public constant DEPOSIT_IS_TO_SMALL = "HN:Deposits/deposit-is-smaller";
}

library EpochsErrors {
    /// @notice Thrown when calling the contract before the first epoch started.
    /// @return HN:Epochs/not-started-yet
    string public constant NOT_STARTED = "HN:Epochs/not-started-yet";
}

library TrackerErrors {
    /// @notice Thrown when trying to get info about effective deposits in future epochs.
    /// @return HN:Tracker/future-is-unknown
    string public constant FUTURE_IS_UNKNOWN = "HN:Tracker/future-is-unknown";

    /// @notice Thrown when trying to get info about effective deposits in epoch 0.
    /// @return HN:Tracker/epochs-start-from-1
    string public constant EPOCHS_START_FROM_1 = "HN:Tracker/epochs-start-from-1";

    /// @notice Thrown when trying updat effective deposits as an unauthorized account.
    /// @return HN:Tracker/invalid-caller
    string public constant UNAUTHORIZED_CALLER = "HN:Tracker/unauthorized-caller";
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IAllocationsStorage.sol";

import {AllocationStorageErrors} from "../Errors.sol";

contract AllocationsStorage is Ownable, IAllocationsStorage {
    mapping(bytes32 => Allocation) private allocationsByUser;
    mapping(bytes32 => address) private allocationsByProposal;
    mapping(bytes32 => uint256) private allocationsCount;
    mapping(bytes32 => uint256) private allocationIndex;

    // @notice Get user's allocation in given epoch.
    function getUserAllocation(uint256 _epoch, address _user) external view returns (Allocation memory) {
        return _getAllocationByUser(_epoch, _user);
    }

    // @notice Add an allocation. Requires that the allocation does not exist.
    function addAllocation(
        uint256 _epoch,
        uint256 _proposalId,
        address _user,
        uint256 _fundsToAllocate
    ) external onlyOwner {
        require(
            _getAllocationIndex(_epoch, _proposalId, _user) == 0,
            AllocationStorageErrors.ALLOCATION_ALREADY_EXISTS
        );
        uint256 count = _getAllocationsCount(_epoch, _proposalId);
        _setAllocationByProposal(_epoch, _proposalId, count + 1, _user);
        _setAllocationIndex(_epoch, _proposalId, _user, count + 1);
        _setAllocationsCount(_epoch, _proposalId, count + 1);
        _setAllocationByUser(_epoch, _user, _proposalId, _fundsToAllocate);
    }

    // @notice Remove an allocation. Swaps the item with the last item in the set and truncates it; computationally cheap.
    // Requires that the allocation exists.
    function removeAllocation(uint256 _epoch, uint256 _proposalId, address _user) external onlyOwner {
        uint256 index = _getAllocationIndex(_epoch, _proposalId, _user);
        require(index > 0, AllocationStorageErrors.ALLOCATION_DOES_NOT_EXIST);
        uint256 count = _getAllocationsCount(_epoch, _proposalId);
        if (index < count) {
            address lastAllocation = _getAllocationByProposal(_epoch, _proposalId, count);
            _setAllocationByProposal(_epoch, _proposalId, index, lastAllocation);
            _setAllocationIndex(_epoch, _proposalId, lastAllocation, index);
        }
        _setAllocationIndex(_epoch, _proposalId, _user, 0);
        _setAllocationsCount(_epoch, _proposalId, count - 1);
        _setAllocationByUser(_epoch, _user, 0, 0);
    }

    /// @notice Users with their allocations in WEI. Returns two arrays where every element corresponds
    /// to the same element from second array.
    /// example: array1[0] is the address which allocated array2[0] funds to some proposal.
    /// @return 0: array of user addresses
    /// 1: array of user allocation in WEI
    function getUsersWithTheirAllocations(
        uint256 _epoch,
        uint256 _proposalId
    ) external view returns (address[] memory, uint256[] memory) {
        uint256 count = _getAllocationsCount(_epoch, _proposalId);
        address[] memory users = new address[](count);
        uint256[] memory allocations = new uint256[](count);
        for (uint256 i = 1; i <= count; i++) {
            address user = getUser(_epoch, _proposalId, i);
            users[i - 1] = user;
            allocations[i - 1] = _getAllocationByUser(_epoch, user).allocation;
        }
        return (users, allocations);
    }

    // @notice The number of allocations for proposal.
    function getAllocationsCount(uint256 _epoch, uint256 _proposalId) external view returns (uint256) {
        return _getAllocationsCount(_epoch, _proposalId);
    }

    // @notice The user address by index. Iteration starts from 1.
    function getUser(
        uint256 _epoch,
        uint256 _proposalId,
        uint256 _index
    ) public view returns (address) {
        return _getAllocationByProposal(_epoch, _proposalId, _index);
    }

    // @notice Get allocation by proposal.
    function _getAllocationByProposal(
        uint256 _epoch,
        uint256 _proposalId,
        uint256 _index
    ) private view returns (address) {
        bytes32 key = keccak256(
            abi.encodePacked(_epoch, ".proposalId", _proposalId, ".index", _index)
        );
        return allocationsByProposal[key];
    }

    // @notice Set allocation by proposal.
    function _setAllocationByProposal(
        uint256 _epoch,
        uint256 _proposalId,
        uint256 _index,
        address _user
    ) private {
        bytes32 key = keccak256(
            abi.encodePacked(_epoch, ".proposalId", _proposalId, ".index", _index)
        );
        allocationsByProposal[key] = _user;
    }

    // @notice Get allocation by user.
    function _getAllocationByUser(uint256 _epoch, address _user) private view returns (Allocation memory) {
        bytes32 key = keccak256(abi.encodePacked(_epoch, ".user", _user));
        return allocationsByUser[key];
    }

    // @notice Set allocation by user.
    function _setAllocationByUser(
        uint256 _epoch,
        address _user,
        uint256 _proposalId,
        uint256 _fundsToAllocate
    ) private {
        bytes32 key = keccak256(abi.encodePacked(_epoch, ".user", _user));
        allocationsByUser[key] = Allocation(_fundsToAllocate, _proposalId);
    }

    // @notice Get allocations count.
    function _getAllocationsCount(uint256 _epoch, uint256 _proposalId) private view returns (uint256) {
        bytes32 key = keccak256(abi.encodePacked(_epoch, ".proposalId", _proposalId));
        return allocationsCount[key];
    }

    // @notice Set allocations count.
    function _setAllocationsCount(uint256 _epoch, uint256 _proposalId, uint256 _count) private {
        bytes32 key = keccak256(abi.encodePacked(_epoch, ".proposalId", _proposalId));
        allocationsCount[key] = _count;
    }

    // @notice Get allocation index.
    function _getAllocationIndex(
        uint256 _epoch,
        uint256 _proposalId,
        address _user
    ) private view returns (uint256) {
        bytes32 key = keccak256(
            abi.encodePacked(_epoch, ".proposalId", _proposalId, ".user", _user)
        );
        return allocationIndex[key];
    }

    // @notice Set allocation index.
    function _setAllocationIndex(
        uint256 _epoch,
        uint256 _proposalId,
        address _user,
        uint256 _index
    ) private {
        bytes32 key = keccak256(
            abi.encodePacked(_epoch, ".proposalId", _proposalId, ".user", _user)
        );
        allocationIndex[key] = _index;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IAllocationsStorage {
    struct Allocation {
        uint256 allocation;
        uint256 proposalId;
    }

    function getUserAllocation(uint256 _epoch, address _user) external view returns (Allocation memory);

    function addAllocation(uint256 _epoch, uint256 _proposalId, address _user, uint256 _fundsToAllocate) external;

    function removeAllocation(uint256 _epoch, uint256 _proposalId, address _user) external;

    function getUsersWithTheirAllocations(
        uint256 _epoch,
        uint256 _proposalId
    ) external view returns (address[] memory, uint256[] memory);

    function getAllocationsCount(uint256 _epoch, uint256 _proposalId) external view returns (uint256);

    function getUser(
        uint256 _epoch,
        uint256 _proposalId,
        uint256 _index
    ) external view returns (address);
}