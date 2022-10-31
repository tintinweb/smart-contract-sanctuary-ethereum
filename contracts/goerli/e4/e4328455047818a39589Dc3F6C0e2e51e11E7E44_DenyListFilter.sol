// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./Ownable.sol";
import "./OperatorFilter.sol";

contract DenyListFilter is Ownable, OperatorFilter {
	mapping(address => bool) blockedAddresses_;
	mapping(bytes32 => bool) blockedCodeHashes_;

	function mayTransfer(address operator) external view returns (bool) {
		if (blockedAddresses_[operator]) return false;
		if (blockedCodeHashes_[operator.codehash]) return false;
		return true;
	}

	function setAddressBlocked(address a, bool blocked) external onlyOwner {
		blockedAddresses_[a] = blocked;
	}

	function setCodeHashBlocked(bytes32 codeHash, bool blocked)
		external
		onlyOwner
	{
		if (codeHash == keccak256(""))
			revert("BlacklistOperatorFilter: can't block EOAs");
		blockedCodeHashes_[codeHash] = blocked;
	}

	function isAddressBlocked(address a) external view returns (bool) {
		return blockedAddresses_[a];
	}

	function isCodeHashBlocked(bytes32 codeHash) external view returns (bool) {
		return blockedCodeHashes_[codeHash];
	}

	/// Convenience function to compute the code hash of an arbitrary contract;
	/// the result can be passed to `setBlockedCodeHash`.
	function codeHashOf(address a) external view returns (bytes32) {
		return a.codehash;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/Context.sol";

abstract contract Ownable is Context {
	address private _owner;

	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

	constructor() {
		_transferOwnership(_msgSender());
	}

	modifier onlyOwner() {
		_checkOwner();
		_;
	}

	function owner() public view virtual returns (address) {
		return _owner;
	}

	function _checkOwner() internal view virtual {
		require(owner() == _msgSender(), "Ownable: caller is not the owner");
	}

	function transferOwnership(address newOwner) public virtual onlyOwner {
		require(newOwner != address(0), "Ownable: new owner is the zero address");
		_transferOwnership(newOwner);
	}

	function _transferOwnership(address newOwner) internal virtual {
		address oldOwner = _owner;
		_owner = newOwner;
		emit OwnershipTransferred(oldOwner, newOwner);
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface OperatorFilter {
	function mayTransfer(address operator) external view returns (bool);
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