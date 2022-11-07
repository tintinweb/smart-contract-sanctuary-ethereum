// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.12;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract NordleWordBank is Ownable {
		string[] public words = ["unicorn", "outlier", "ethereum", "pepe", "rainbow", "happy", "royal", "gold", "shiny", "ape"];
		string[] public requested;

		mapping(string => uint256) public wordsMap;
		mapping(string => uint256) public requestedMap;

		constructor() {
				// Finish initializing default words
				for (uint i = 0; i < words.length;) {
					wordsMap[words[i]] = i;
					unchecked {
						i++;
					}
				}
		}

		function requestWord(string memory word) public {
				require(requestedMap[word] == 0, 'Already requested');
				// comparing string memory to literal_string can be done by hashing w keccak
				require(wordsMap[word] == 0 && keccak256(bytes(word)) != keccak256(bytes('unicorn')), 'Already added');
				requested.push(word);
				requestedMap[word] = requested.length-1;
		}

		function acceptWord(string memory word) public onlyOwner {
				require(wordsMap[word] == 0 && keccak256(bytes(word)) != keccak256(bytes('unicorn')), 'Already added');
				words.push(word);
				wordsMap[word] = words.length-1;
				deleteRequestedWord(word);
		}

		function rejectWord(string memory word) public onlyOwner {
				// require word exists in requested?
				deleteRequestedWord(word);
		}

		function deleteRequestedWord(string memory word) internal {
				uint index = requestedMap[word];
				requested[index] = requested[requested.length-1];
				requestedMap[requested[index]] = index;
				delete requested[requested.length-1];
				delete requestedMap[word];
		}

		function removeWord(string memory word) public onlyOwner {
				uint index = wordsMap[word];
				if (index == 0) return; // caveat: item 0 is undeletable, but that's ok because it's unicorn
				// if (words.length > 1) // we don't need to check if words.length > 1 ^^
				words[index] = words[words.length-1];
				wordsMap[words[index]] = index;
				delete words[words.length-1];
				delete wordsMap[word];
		}

		function exists(string memory word)	public view returns (bool) {
				return wordsMap[word] != 0 || keccak256(bytes(word)) == keccak256(bytes('unicorn'));
		}

		function wordBank() public view returns (string[] memory) {
			return words;
		}
		// receive() external payable {}
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