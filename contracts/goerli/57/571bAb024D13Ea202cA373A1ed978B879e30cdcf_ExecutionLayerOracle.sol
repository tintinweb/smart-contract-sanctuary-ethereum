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

interface IEpochs {
    function getCurrentEpoch() external view returns (uint32);

    function isStarted() external view returns (bool);

    function isDecisionWindowOpen() external view returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IEpochs.sol";

import {OracleErrors} from "../Errors.sol";

/// @title Implementation of execution layer oracle.
/// @notice The goal of the oracle is to provide balance of the Golem Foundation validator execution layer's account
/// which collects fee.
/// Balance for epoch will be taken just after the epoch finished (check `Epochs.sol` contract).
contract ExecutionLayerOracle is Ownable {
    /// @notice Epochs contract address.
    IEpochs public immutable epochs;

    /// @notice validator's address collecting fees
    address public feeAddress;

    /// @notice execution layer account balance in given epoch
    mapping(uint256 => uint256) public balanceByEpoch;

    /// @param epochsAddress Address of Epochs contract.
    constructor(address epochsAddress) {
        epochs = IEpochs(epochsAddress);
    }

    /// @notice set ETH balance in given epoch. Balance has to be in WEI.
    /// Updating epoch other then previous or setting the balance multiple times will be reverted.
    function setBalance(uint256 epoch, uint256 balance) external onlyOwner {
        require(
            epoch > 0 && epoch == epochs.getCurrentEpoch() - 1,
            OracleErrors.CANNOT_SET_BALANCE_FOR_PAST_EPOCHS
        );
        require(balanceByEpoch[epoch] == 0, OracleErrors.BALANCE_ALREADY_SET);
        balanceByEpoch[epoch] = balance;
    }

    /// @notice set execution layer's fee address
    function setFeeAddress(address _feeAddress) external onlyOwner {
        feeAddress = _feeAddress;
    }
}