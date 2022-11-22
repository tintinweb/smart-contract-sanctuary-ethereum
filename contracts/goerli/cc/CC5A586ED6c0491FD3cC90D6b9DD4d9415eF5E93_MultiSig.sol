// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

contract MultiSig {
    struct Txn {
        address to;
        bool executed;
        bytes data;
    }

    modifier onlyOwner() {
        _onlyOwner();
        _;
    }

    modifier txnExists(uint256 _txnId) {
        _txnExists(_txnId);
        _;
    }

    modifier notApproved(uint256 _txnId) {
        _notApproved(_txnId);
        _;
    }

    modifier notExecuted(uint256 _txnId) {
        _notExecuted(_txnId);
        _;
    }

    address[] public owners;
    mapping(address => bool) isOwner;
    uint256 immutable public required;
    Txn[] public txns;

    mapping(uint256 => mapping(address => bool)) public approved;

    constructor(address[] memory _owners, uint256 _required) {
        require(_owners.length > 0, "Owners required");
        require(_required > 0 && _required <= _owners.length, "Invalid required number of owners");

        for (uint256 i = 0; i < _owners.length; i++) {
            address owner = _owners[i];

            require(!isOwner[owner], "Owner is not unique");

            isOwner[owner] = true;
            owners.push(owner);
        }

        required = _required;
    }

    function submit(address _to, bytes calldata _data) external onlyOwner returns(uint256) {
        txns.push(Txn({
            to: _to,
            data: _data,
            executed: false
        }));

        return txns.length - 1;
    }

    function approve(uint256 _txnId) external onlyOwner txnExists(_txnId) notExecuted(_txnId) notApproved(_txnId) {
        approved[_txnId][msg.sender] = true;
    }

    function getApprovalCount(uint256 _txnId) private view returns (uint256 count) {
        uint256 ownersLength = owners.length;

        for (uint256 i = 0; i < ownersLength; i++) {
            if (approved[_txnId][owners[i]]) {
                unchecked {
                    ++count;
                }
            }
        }
    }

    function execute(uint256 _txnId) external txnExists(_txnId) notExecuted(_txnId) {
        require(getApprovalCount(_txnId) >= required, "Not enough approvals");

        Txn storage txn = txns[_txnId];

        txn.executed = true;

        (bool success, bytes memory result) = txn.to.call{value: 0}(txn.data);

        if (!success) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }
    }

    // Modifier impls
    function _onlyOwner() private view {
        require(isOwner[msg.sender], "Not owner");
    }

    function _txnExists(uint256 _txnId) private view {
        require(_txnId < txns.length, "Txn does not exist");
    }

    function _notApproved(uint256 _txnId) private view {
        require(!approved[_txnId][msg.sender], "Txn already approved");
    }

    function _notExecuted(uint256 _txnId) private view {
        require(!txns[_txnId].executed, "Txn already executed");
    }
}

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