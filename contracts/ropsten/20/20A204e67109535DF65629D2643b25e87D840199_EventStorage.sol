// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "./roles/AdminRole.sol";

contract EventStorage is AdminRole {
    struct Event {
        bytes[] request;
        bytes[] response;
        bool processed;
        address creator;
    }

    /// Event with provided id is already processed
    error EventProcessed(uint256 id);

    /// Event with provided id is not exist
    error EventIsNotExist(uint256 id);

    mapping (uint256 => Event) internal _event;
    uint256 public totalEventsCount;

    function addRequest(bytes[] calldata request) external {
        Event memory event_ = _event[totalEventsCount];
        event_.request = request;
        event_.creator = msg.sender;

        _event[totalEventsCount] = event_;
        totalEventsCount += 1;
    }

    function addResponse(uint256 id, bytes[] calldata response) external onlyAdmin {
        _addResponse(id, response);
    }

    function addResponse(uint256[] calldata id, bytes[][] calldata response) external onlyAdmin {
        uint256 len = id.length;
        for (uint256 i = 0; i < len; ++i) {
            _addResponse(id[i], response[i]);
        }
    }

    function getEvent(uint256 id) external view returns(Event memory event_) {
        return _event[id];
    }

    function _addResponse(uint256 id, bytes[] calldata response) private {
        Event memory event_ = _event[id];
        if (event_.request.length == 0) { revert EventIsNotExist(id); }
        if (event_.processed) { revert EventProcessed(id); }

        event_.response = response;
        event_.processed = true;
        _event[id] = event_;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Roles.sol";
import "../utils/Context.sol";
import "./Ownable.sol";


/**
 * @title AdminRole
 * @dev An operator role contract.
 */
abstract contract AdminRole is Ownable {
    using Roles for Roles.Role;

    event AdminAdded(address indexed account);
    event AdminRemoved(address indexed account);

    Roles.Role private _admins;

    /**
     * @dev Makes function callable only if sender is an admin.
     */
    modifier onlyAdmin() {
        require(isAdmin(_msgSender()), "AdminRole: caller does not have the Admin role");
        _;
    }

    /**
     * @dev Checks if the address is an admin.
     */
    function isAdmin(address account) public view returns (bool) {
        return _admins.has(account);
    }

    /**
     * @dev Makes the address an admin.
     */
    function addAdmin(address account) external virtual onlyOwner {
        require(!isAdmin(account), "(addAdmin) account is already a Admin");
        _addAdmin(account);
    }

    /**
     * @dev Remove admin role from the address.
     */
    function removeAdmin(address account) external virtual onlyOwner {
        require(isAdmin(account), "(addAdmin) account is not a Admin");
        _removeAdmin(account);
    }

    function _addAdmin(address account) internal {
        _admins.add(account);
        emit AdminAdded(account);
    }

    function _removeAdmin(address account) internal {
        _admins.remove(account);
        emit AdminRemoved(account);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;


/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
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
pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
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
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}