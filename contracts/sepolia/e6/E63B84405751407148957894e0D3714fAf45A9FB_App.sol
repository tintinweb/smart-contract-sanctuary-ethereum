// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";

contract App is Ownable {
  uint private _id = 1;

  mapping(uint => StatusInfo) private _statuses;

  struct StatusInfo {
    uint id;
    address from;
    address to;
    uint oc;
    string status;
  }

  event Progress(
    uint indexed id,
    address indexed from,
    address indexed to,
    uint oc,
    string previousStatus,
    string newStatus
  );

  function applyFor(address from, address to, uint oc, string calldata status_) external {
    _applyFor(from, to, oc, status_);
  }

  function batchApplyFor(
    address[] calldata from,
    address[] calldata to,
    uint[] calldata oc,
    string[] calldata status_
  ) external {
    uint length = from.length;
    for (uint i = 0; i < length; i++) {
      _applyFor(from[i], to[i], oc[i], status_[i]);
    }
  }

  function updateStatus(uint id, string calldata newStatus) external {
    _updateStatus(id, newStatus);
  }

  function batchUpdateStatus(uint[] calldata id, string[] calldata newStatus) external {
    uint length = id.length;
    for (uint i = 0; i < length; i++) {
      _updateStatus(id[i], newStatus[i]);
    }
  }

  function status(uint id) external view returns (StatusInfo memory) {
    require(_statuses[id].id == id, "id of status doesn't exist.");

    StatusInfo memory statusInfo = _statuses[id];

    return statusInfo;
  }

  function _applyFor(address from, address to, uint oc, string memory status_) internal {
    _statuses[_id] = StatusInfo(_id, from, to, oc, status_);

    emit Progress(_id++, from, to, oc, "", status_);
  }

  function _updateStatus(uint id, string memory newStatus) internal {
    StatusInfo storage statusInfo = _statuses[id];

    require(statusInfo.id == id, "id of status doesn't exist.");
    require(
      owner() == msg.sender || statusInfo.from == msg.sender || statusInfo.to == msg.sender,
      "Only owner, from or to can update status."
    );
    require(
      keccak256(abi.encodePacked(statusInfo.status)) != keccak256(abi.encodePacked(newStatus)),
      "status doesn't change."
    );

    string memory previousStatus = statusInfo.status;
    statusInfo.status = newStatus;

    emit Progress(id, statusInfo.from, statusInfo.to, statusInfo.oc, previousStatus, newStatus);
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