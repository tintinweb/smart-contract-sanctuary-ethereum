// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

// ====================================================================
// ======================= Transfer Approver ======================
// ====================================================================

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IWhitelist.sol";

/**
 * @title Transfer Approver
 * @dev Allows accounts to be blacklisted by admin role
 */
contract TransferApprover is Ownable {
    IWhitelist private whitelist;

    enum Validation {
        ONLY_VALID,
        VALID_OR_NEW
    }

    Validation public validation_method;
    uint256 public time_delay;

    event SetValidationType(Validation _validation_method);
    event SetTimeDelay(uint256 _new_time_delay);
    event UnBlacklisted(address indexed _account);

    /* ========== CONSTRUCTOR ========== */

    constructor(address _whitelist) {
        whitelist = IWhitelist(_whitelist);
        validation_method = Validation.ONLY_VALID;
    }

    /**
     * @notice Returns token transferability
     * @param _from sender address
     * @param _to beneficiary address
     * @return (bool) true - allowance, false - denial
     */
    function checkTransfer(
        address _from,
        address _to
    ) external view returns (bool) {
        if (_from == address(0) || _to == address(0)) return true;

        return (isValid(_from) && isValid(_to)) ? true : false;
    }

    /**
     * @dev Checks if account is valid
     * @param _account The address to check
     */
    function isValid(address _account) public view returns (bool) {
        (IWhitelist.Status status, uint256 created_at) = whitelist.getUser(
            _account
        );

        if (created_at == 0) return false; // Non-WhiteList User

        if (status == IWhitelist.Status.VALID) {
            return true;
        } else if (
            status == IWhitelist.Status.NEW &&
            validation_method == Validation.VALID_OR_NEW
        ) {
            return
                time_delay == 0 || (block.timestamp - created_at > time_delay)
                    ? true
                    : false;
        } else {
            return false;
        }
    }

    /**
     * @dev Set time delay
     * @param _new_delay new time delay
     */
    function setTimeDelay(uint256 _new_delay) external onlyOwner {
        time_delay = _new_delay;

        emit SetTimeDelay(_new_delay);
    }

    /**
     * @dev Set validation method
     * @param _new_method new validation method
     */
    function setValidationType(Validation _new_method) external onlyOwner {
        validation_method = _new_method;

        emit SetValidationType(_new_method);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

interface IWhitelist {
    enum Status {
        INVALID,
        NEW,
        VALID
    }

    function getUser(address _account) external view returns (Status, uint256);
}