// SPDX-License-Identifier: MIT
// Stash Controller

pragma solidity ^0.8.0;

import "./Ownable.sol";

// contract interface
interface Stash {
  function updateMerkleRoot(address, bytes32) external;
  function transferOwnership(address) external;
  function merkleRoot(address) external view returns (bytes32);
}


contract StashController is Ownable {

	// merkle stash
	Stash public stash; // MultiMerkleStash contract

    /* ========== CONSTRUCTOR ========== */

    constructor(address _multiMerkleStash) {
      stash = Stash(_multiMerkleStash);
    }

	// freeze roots
	function multiFreeze(address[] calldata _tokens) public onlyOwner {
		for(uint256 i = 0; i<_tokens.length; i++) {
			stash.updateMerkleRoot(_tokens[i], 0);
		}
	}

	// update roots
	function multiSet(address[] calldata _tokens, bytes32[] calldata _roots) public onlyOwner {
		for(uint256 i = 0; i<_tokens.length; i++) {
			require(stash.merkleRoot(_tokens[i]) == 0, "must freeze first");
			stash.updateMerkleRoot(_tokens[i], _roots[i]);
		}
	}

	// Change ownership of stash
	function newController(address _newController) public onlyOwner {
		stash.transferOwnership(_newController);
	}

	// Change stash address
	function newStash(address _newStash) public onlyOwner {
		stash = Stash(_newStash);
	}

	// Fallback executable function
	function execute(address _to, uint256 _value, bytes calldata _data) external onlyOwner returns (bool, bytes memory) {
    (bool success, bytes memory result) = _to.call{value:_value}(_data);
    return (success, result);
  }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";

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
    address private _owner = 0xF930EBBd05eF8b25B1797b9b2109DDC9B0d43063; // Stake DAO multisig

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

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