// SPDX-License-Identifier: MIT
//
//    ██████████
//   █          █
//  █            █
//  █            █
//  █            █
//  █    ░░░░    █
//  █   ▓▓▓▓▓▓   █
//  █  ████████  █
//
// https://endlesscrawler.io
// @EndlessCrawler
//
/// @title Endless Crawler Founder Cards Store (v.2)
/// @author Studio Avante
/// @notice Contains token info for Founder Cards (ids 1, 2, 3, 4)
/// @dev Serves CardsMinter.sol, will be upgraded to a generic store eventually
pragma solidity ^0.8.16;
import { Ownable } from '@openzeppelin/contracts/access/Ownable.sol';
import { Base64 } from '@openzeppelin/contracts/utils/Base64.sol';
import { ICardsStore } from './ICardsStore.sol';

contract FounderStoreV2 is ICardsStore, Ownable {

	uint8 constant TYPE_CLASS = 1;

	struct Card {
		uint256 price;
		uint128 supply;
		uint8 cardType;
		string name;
		string edition;
		string description;
		string imageData;
	}
	
	mapping(uint256 => Card) private _cards;

	/// @notice Emitted when a new card is created
	/// @param id Token id
	/// @param name The name of the card
	event Created(uint256 indexed id, string indexed name);

	constructor() {
		_createCard(1, Card(
			1_000_000_000_000_000_000, // 1 eth
			16,
			TYPE_CLASS,
			'Champion',
			'Founder',
			'The keeper of this card is a Crawler Champion. Grants all native cards!',
			'<svg xmlns="http://www.w3.org/2000/svg" shape-rendering="crispEdges" viewBox="0 -0.5 16 16"><path stroke="#1a1a1a" d="M2 0h12M1 1h2m10 0h2M1 2h1m1 0h10m1 0h1M1 3h1m1 0h2m2 0h2m1 0h3m1 0h1M1 4h1m1 0h1m1 0h2m1 0h1m1 0h3m1 0h1M1 5h1m1 0h1m1 0h4m1 0h3m1 0h1M1 6h1m1 0h1m1 0h4m2 0h2m1 0h1M1 7h1m1 0h1m1 0h4m1 0h1m1 0h1m1 0h1M1 8h1m1 0h1m1 0h2m1 0h1m1 0h1m1 0h1m1 0h1M1 9h1m1 0h2m2 0h2m1 0h1m1 0h1m1 0h1M1 10h1m1 0h10m1 0h1M1 11h2m1 0h3m1 0h1m1 0h2m1 0h2M2 12h2m1 0h6m1 0h2M3 13h2m1 0h4m1 0h2m-9 1h2m4 0h2m-7 1h6"/><path stroke="#ffbfa6" d="M3 1h10M2 2h1m10 0h1M2 3h1m10 0h1M2 4h1m10 0h1M2 5h1m10 0h1M2 6h1m10 0h1M2 7h1m10 0h1M2 8h1m10 0h1M2 9h1m10 0h1M2 10h1m10 0h1M3 11h1m8 0h1m-9 1h1m6 0h1m-7 1h1m4 0h1m-5 1h4"/><path stroke="#f2e9c3" d="M5 3h2m2 0h1M4 4h1m2 0h1m1 0h1M4 5h1m4 0h1M4 6h1m4 0h2M4 7h1m4 0h1m1 0h1M4 8h1m2 0h1m1 0h1m1 0h1M5 9h2m2 0h1m1 0h1"/><path stroke="#784f40" d="M7 11h1m1 0h1"/></svg>'
		));
		_createCard(2, Card(
			80_000_000_000_000_000, // 0.08 eth
			256,
			TYPE_CLASS,
			'Hero',
			'Founder',
			'The keeper of this card is a Crawler Hero. Grants all native cards!',
			'<svg xmlns="http://www.w3.org/2000/svg" shape-rendering="crispEdges" viewBox="0 -0.5 16 16"><path stroke="#1a1a1a" d="M2 0h12M1 1h2m10 0h2M1 2h1m1 0h10m1 0h1M1 3h1m1 0h1m1 0h2m1 0h5m1 0h1M1 4h1m1 0h1m1 0h2m1 0h5m1 0h1M1 5h1m1 0h1m1 0h2m1 0h5m1 0h1M1 6h1m1 0h1m4 0h2m2 0h1m1 0h1M1 7h1m1 0h1m1 0h2m1 0h1m1 0h3m1 0h1M1 8h1m1 0h1m1 0h2m1 0h1m1 0h3m1 0h1M1 9h1m1 0h1m1 0h2m1 0h1m1 0h1m1 0h1m1 0h1M1 10h1m1 0h10m1 0h1M1 11h2m1 0h3m1 0h1m1 0h2m1 0h2M2 12h2m1 0h6m1 0h2M3 13h2m1 0h4m1 0h2m-9 1h2m4 0h2m-7 1h6"/><path stroke="#ffbfa6" d="M3 1h10M2 2h1m10 0h1M2 3h1m10 0h1M2 4h1m10 0h1M2 5h1m10 0h1M2 6h1m10 0h1M2 7h1m10 0h1M2 8h1m10 0h1M2 9h1m10 0h1M2 10h1m10 0h1M3 11h1m8 0h1m-9 1h1m6 0h1m-7 1h1m4 0h1m-5 1h4"/><path stroke="#f2e9c3" d="M4 3h1m2 0h1M4 4h1m2 0h1M4 5h1m2 0h1M4 6h4m2 0h2M4 7h1m2 0h1m1 0h1M4 8h1m2 0h1m1 0h1M4 9h1m2 0h1m1 0h1m1 0h1"/><path stroke="#784f40" d="M7 11h1m1 0h1"/></svg>'
		));
		_createCard(3, Card(
			20_000_000_000_000_000, // 0.02 eth
			1000,
			TYPE_CLASS,
			'Crawler',
			'1st',
			'The keeper of this card is an Original Crawler.',
			'<svg xmlns="http://www.w3.org/2000/svg" shape-rendering="crispEdges" viewBox="0 -0.5 16 16"><path stroke="#1a1a1a" d="M2 0h12M1 1h2m10 0h2M1 2h1m1 0h10m1 0h1M1 3h1m1 0h2m2 0h6m1 0h1M1 4h1m1 0h1m1 0h2m1 0h5m1 0h1M1 5h1m1 0h1m1 0h8m1 0h1M1 6h1m1 0h1m1 0h5m2 0h1m1 0h1M1 7h1m1 0h1m1 0h4m1 0h3m1 0h1M1 8h1m1 0h1m1 0h2m1 0h1m1 0h3m1 0h1M1 9h1m1 0h2m2 0h2m1 0h1m1 0h1m1 0h1M1 10h1m1 0h10m1 0h1M1 11h2m1 0h3m1 0h1m1 0h2m1 0h2M2 12h2m1 0h6m1 0h2M3 13h2m1 0h4m1 0h2m-9 1h2m4 0h2m-7 1h6"/><path stroke="#ffbfa6" d="M3 1h10M2 2h1m10 0h1M2 3h1m10 0h1M2 4h1m10 0h1M2 5h1m10 0h1M2 6h1m10 0h1M2 7h1m10 0h1M2 8h1m10 0h1M2 9h1m10 0h1M2 10h1m10 0h1M3 11h1m8 0h1m-9 1h1m6 0h1m-7 1h1m4 0h1m-5 1h4"/><path stroke="#f2e9c3" d="M5 3h2M4 4h1m2 0h1M4 5h1M4 6h1m5 0h2M4 7h1m4 0h1M4 8h1m2 0h1m1 0h1M5 9h2m2 0h1m1 0h1"/><path stroke="#784f40" d="M7 11h1m1 0h1"/></svg>'
		));
		_createCard(4, Card(
			0, // Free
			0, // Not released yet
			TYPE_CLASS,
			'Adventurer',
			'Limited',
			'The keeper of this card is a Loot Adventurer. Claimable soon with Loot (for Adventurers).',
			'<svg xmlns="http://www.w3.org/2000/svg" shape-rendering="crispEdges" viewBox="0 -0.5 16 16"><path stroke="#1a1a1a" d="M2 0h12M1 1h2m10 0h2M1 2h1m1 0h10m1 0h1M1 3h1m1 0h2m2 0h4m1 0h1m1 0h1M1 4h1m1 0h1m1 0h2m1 0h3m1 0h1m1 0h1M1 5h1m1 0h1m1 0h2m1 0h3m1 0h1m1 0h1M1 6h1m1 0h1m4 0h2m2 0h1m1 0h1M1 7h1m1 0h1m1 0h2m1 0h1m1 0h1m1 0h1m1 0h1M1 8h1m1 0h1m1 0h2m1 0h1m1 0h1m1 0h1m1 0h1M1 9h1m1 0h1m1 0h2m1 0h2m1 0h2m1 0h1M1 10h1m1 0h10m1 0h1M1 11h2m1 0h3m1 0h1m1 0h2m1 0h2M2 12h2m1 0h6m1 0h2M3 13h2m1 0h4m1 0h2m-9 1h2m4 0h2m-7 1h6"/><path stroke="#ffbfa6" d="M3 1h10M2 2h1m10 0h1M2 3h1m10 0h1M2 4h1m10 0h1M2 5h1m10 0h1M2 6h1m10 0h1M2 7h1m10 0h1M2 8h1m10 0h1M2 9h1m10 0h1M2 10h1m10 0h1M3 11h1m8 0h1m-9 1h1m6 0h1m-7 1h1m4 0h1m-5 1h4"/><path stroke="#f2e9c3" d="M5 3h2m4 0h1M4 4h1m2 0h1m3 0h1M4 5h1m2 0h1m3 0h1M4 6h4m2 0h2M4 7h1m2 0h1m1 0h1m1 0h1M4 8h1m2 0h1m1 0h1m1 0h1M4 9h1m2 0h1m2 0h1"/><path stroke="#784f40" d="M7 11h1m1 0h1"/></svg>'
		));
	}

	function _createCard(uint256 id, Card memory card) internal {
		_cards[id] = card;
		emit Created(id, _cards[id].name);
	}

	//---------------
	// Public
	//

	/// @notice Returns the Store version
	/// @return version This contract version (1)
	function getVersion() public pure override returns (uint8) {
		return 2;
	}

	/// @notice Check if a Token exists
	/// @param id Token id
	/// @return bool True if it exists, False if not
	function exists(uint256 id) public pure override returns (bool) {
		return (id >= 1 && id <= 4);
	}

	/// @notice Returns a Token stored info
	/// @param id Token id
	/// @return card FounderStoreV2.Card structure
	function getCard(uint256 id) public view returns (Card memory) {
		require(exists(id), 'Card does not exist');
		return _cards[id];
	}

	/// @notice Returns the number of Cards maintained by this contract
	/// @return number 2
	function getCardCount() public pure override returns (uint256) {
		return 4;
	}

	/// @notice Returns the total amount of Cards available for purchase
	/// @param id Token id
	/// @return number
	function getCardSupply(uint256 id) public view override returns (uint256) {
		require(exists(id), 'Card does not exist');
		return _cards[id].supply;
	}

	/// @notice Returns the price of a Card
	/// @param id Token id
	/// @return price The Card price, in WEI
	function getCardPrice(uint256 id) public view override returns (uint256) {
		require(exists(id), 'Card does not exist');
		return _cards[id].price;
	}

	/// @notice Run all the required tests to purchase a Card, reverting the transaction if not allowed to purchase
	/// @param id Token id
	/// @param currentSupply The total amount of minted Tokens, from all accounts
	/// @param balance The amount of tokens the purchaser owns
	/// @param value Transaction value sent, in WEI
	function beforeMint(uint256 id, uint256 currentSupply, uint256 balance, uint256 value) public view override {
		require(exists(id), 'Card does not exist');
		Card storage card = _cards[id];
		require(currentSupply < card.supply, 'Sold out');
		require(balance == 0, 'One per wallet');
		require(value >= card.price, 'Bad value');
	}

	/// @notice Returns a token metadata, compliant with ERC1155Metadata_URI
	/// @param id Token id
	/// @return metadata Token metadata, as json string base64 encoded
	function uri(uint256 id) public view override returns (string memory) {
		require(exists(id), 'Card does not exist');
		Card storage card = _cards[id];
		bytes memory json = abi.encodePacked(
			'{'
				'"name":"', card.name, '",'
				'"description":"', card.description, '",'
				'"external_url":"https://endlesscrawler.io",'
				'"background_color":"7D381F",'
				'"attributes":['
					'{"trait_type":"Type","value":"Class"},'
					'{"trait_type":"Class","value":"', card.name, '"},'
					'{"trait_type":"Edition","value":"', card.edition, '"}'
				'],'
				'"image":"data:image/svg+xml;base64,', Base64.encode(bytes(card.imageData)), '"'
			'}'
		);
		return string(abi.encodePacked('data:application/json;base64,', Base64.encode(json)));
	}
}

// SPDX-License-Identifier: MIT
//
//    ██████████
//   █          █
//  █            █
//  █            █
//  █            █
//  █    ░░░░    █
//  █   ▓▓▓▓▓▓   █
//  █  ████████  █
//
// https://endlesscrawler.io
// @EndlessCrawler
//
/// @title Cards Store interface
/// @author Studio Avante
/// @notice Cards Store interface
/// @dev Serves CardsMinter.sol
pragma solidity ^0.8.16;

interface ICardsStore {
	function getVersion() external view returns (uint8);
	function exists(uint256 id) external view returns (bool);
	function getCardCount() external view returns (uint256);
	function getCardSupply(uint256 id) external view returns (uint256);
	function getCardPrice(uint256 id) external view returns (uint256);
	function beforeMint(uint256 id, uint256 currentSupply, uint256 balance, uint256 value) external view;
	function uri(uint256 id) external view returns (string memory);
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Base64.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides a set of functions to operate with Base64 strings.
 *
 * _Available since v4.5._
 */
library Base64 {
    /**
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        /// @solidity memory-safe-assembly
        assembly {
            // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // To write each character, shift the 3 bytes (18 bits) chunk
                // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
                // and apply logical AND with 0x3F which is the number of
                // the previous character in the ASCII table prior to the Base64 Table
                // The result is then added to the table to get the character to write,
                // and finally write it in the result pointer but with a left shift
                // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

            // When data `bytes` is not exactly 3 bytes long
            // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }

        return result;
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