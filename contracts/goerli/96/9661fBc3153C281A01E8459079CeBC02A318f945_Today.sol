// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "./TodayRenderer.sol";

contract Today is IERC721, IERC2981, ERC721Enumerable, Ownable {
	uint256 public constant PRICE_MAX = 0.012 ether;
	uint256 public constant PRICE_DECREASE = 0.0005 ether;

	uint256 private constant NY_TIME_DIFF_HOURS = 4;
	uint256 private constant HOUR_IN_SECONDS = 3_600;
	uint256 private constant DAY_IN_SECONDS = 86_400;
	uint256 private constant YEAR_IN_SECONDS = 31_536_000;
	uint256 private constant LEAP_YEAR_IN_SECONDS = 31_622_400;
	uint16 private constant ORIGIN_YEAR = 1970;

	uint256 private constant LIFESPAN = 29_771 days;
	uint256 private deployedTime;
	uint256 private royaltyPercentage = 5;
	address private withdrawAddress = 0x6a24d24674780dC0F3415Af6513e36d5d622fd01;
	TodayRenderer private renderer;

	mapping(uint256 => uint256) private timeByTokenId;

	constructor() ERC721("Today", "TODAY") {
		deployedTime = block.timestamp;
		renderer = new TodayRenderer();
	}

	//--------------------------------------------------------------------------

	function mint() public payable {
		uint256 time = block.timestamp;
		// console.log("* mint time: %s", getDateStr(time));
		require(msg.value == getPrice(), "Incorrect payable amount");
		// console.log("mint:");
		// console.log("- block.timestamp", block.timestamp);
		// console.log("- deployedTime", deployedTime);
		// console.log("-   block.timestamp - deployedTime", block.timestamp - deployedTime);
		// console.log("- LIFESPAN", LIFESPAN);
		require((time - deployedTime) < LIFESPAN, "This contract has stopped activities");

		//limit
		uint256 tokenId = getTodayId(time);

		//unlimit
		// uint256 tokenId = time;

		timeByTokenId[tokenId] = time;
		_mint(_msgSender(), tokenId);
	}

	function getTodayId(uint256 time) public pure returns (uint256) {
		(uint16 year, uint8 month, uint8 day) = parseTime(time);

		return uint256(year) * 10000 + uint256(month) * 100 + uint256(day);
	}

	function getPrice() public view returns (uint256) {
		uint256 _nyTime = getNYTime(block.timestamp);
		uint256 hour = (_nyTime / 1 hours) % 24;
		uint256 price = PRICE_MAX - (PRICE_DECREASE * hour);
		return price;
	}

	function isMinted() public view returns (bool) {
		return _exists(getTodayId(block.timestamp));
	}

	function isOpen() public view returns (bool) {
		return (block.timestamp - deployedTime) < LIFESPAN;
	}

	//--------------------------------------------------------------------------

	function tokenURI(uint256 tokenId) public view override returns (string memory) {
		require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
		uint256 storedTime = timeByTokenId[tokenId];

		string memory svg = renderer.render(getDateStr(storedTime));

		bytes memory json = abi.encodePacked(
			'{"name": "',
			getDateStr(storedTime),
			'", "description": "This is full-onchain nft test.", "image": "data:image/svg+xml;base64,',
			Base64.encode(bytes(svg)),
			'"}'
		);
		return string(abi.encodePacked("data:application/json;base64,", Base64.encode(json)));
	}

	//--------------------------------------------------------------------------

	function getDateStr(uint256 time) internal pure returns (string memory) {
		//GMT
		(uint16 year, uint8 month, uint8 day) = parseTime(time);

		string[12] memory monthStr = [
			"JAN",
			"FEB",
			"MAR",
			"APR",
			"MAY",
			"JUN",
			"JUL",
			"AUG",
			"SEP",
			"OCT",
			"NOV",
			"DEC"
		];

		return string(abi.encodePacked(monthStr[month - 1], ".", Strings.toString(day), ",", Strings.toString(year)));
	}

	function getTimeStrDebug() public view returns (uint256) {
		uint256 time = block.timestamp;
		uint256 nyTime = getNYTime(time);

		(uint16 year, uint8 month, uint8 day) = parseTime(time);
		uint256 hour = (nyTime / 60 / 60) % 24;
		uint256 minute = (nyTime / 60) % 60;
		return
			uint256(year) *
			100000000 +
			uint256(month) *
			1000000 +
			uint256(day) *
			10000 +
			uint256(hour) *
			100 +
			uint256(minute);
	}

	function parseTime(uint256 time)
		internal
		pure
		returns (
			uint16 year,
			uint8 month,
			uint8 day
		)
	{
		uint256 secondsAccountedFor = 0;
		uint256 buf;
		uint8 i;

		//時差の計算
		uint256 nyTime = getNYTime(time);

		// Year
		year = getYear(nyTime);
		buf = leapYearsBefore(year) - leapYearsBefore(ORIGIN_YEAR);

		secondsAccountedFor += LEAP_YEAR_IN_SECONDS * buf;
		secondsAccountedFor += YEAR_IN_SECONDS * (year - ORIGIN_YEAR - buf);

		// Month
		uint256 secondsInMonth;
		for (i = 1; i <= 12; i++) {
			secondsInMonth = DAY_IN_SECONDS * getDaysInMonth(i, year);
			if (secondsInMonth + secondsAccountedFor > nyTime) {
				month = i;
				break;
			}
			secondsAccountedFor += secondsInMonth;
		}

		// Day
		for (i = 1; i <= getDaysInMonth(month, year); i++) {
			if (DAY_IN_SECONDS + secondsAccountedFor > nyTime) {
				day = i;
				break;
			}
			secondsAccountedFor += DAY_IN_SECONDS;
		}
	}

	function getYear(uint256 time) internal pure returns (uint16) {
		uint256 secondsAccountedFor = 0;
		uint16 year;
		uint256 numLeapYears;

		// Year
		year = uint16(ORIGIN_YEAR + time / YEAR_IN_SECONDS);
		numLeapYears = leapYearsBefore(year) - leapYearsBefore(ORIGIN_YEAR);

		secondsAccountedFor += LEAP_YEAR_IN_SECONDS * numLeapYears;
		secondsAccountedFor += YEAR_IN_SECONDS * (year - ORIGIN_YEAR - numLeapYears);

		while (secondsAccountedFor > time) {
			if (isLeapYear(uint16(year - 1))) {
				secondsAccountedFor -= LEAP_YEAR_IN_SECONDS;
			} else {
				secondsAccountedFor -= YEAR_IN_SECONDS;
			}
			year -= 1;
		}
		return year;
	}

	function isLeapYear(uint16 year) internal pure returns (bool) {
		if (year % 4 != 0) return false;
		if (year % 100 != 0) return true;
		if (year % 400 != 0) return false;
		return true;
	}

	function leapYearsBefore(uint256 year) internal pure returns (uint256) {
		year -= 1;
		return year / 4 - year / 100 + year / 400;
	}

	function getDaysInMonth(uint8 month, uint16 year) internal pure returns (uint8) {
		if (month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10 || month == 12) return 31;
		else if (month == 4 || month == 6 || month == 9 || month == 11) return 30;
		else if (isLeapYear(year)) return 29;
		else return 28;
	}

	function getNYTime(uint256 time) internal pure returns (uint256) {
		return time - NY_TIME_DIFF_HOURS * HOUR_IN_SECONDS;
	}

	//--------------------------------------------------------------------------

	function withdraw() public onlyOwner {
		payable(withdrawAddress).transfer(address(this).balance);
	}

	//--------------------------------------------------------------------------

	function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view override returns (address, uint256) {
		require(_exists(_tokenId), "No exist token");
		return (payable(withdrawAddress), (_salePrice / 100) * royaltyPercentage);
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract TodayRenderer {
	function render(string memory dateStr) public pure returns (string memory) {
		return
			string(
				abi.encodePacked(
					'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 300 300"><style>@font-face {font-family: "Kawara";src: url("data:application/font-woff2; charset=utf-8; base64,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") format("woff2");}text{fill:#fff;font-family:Kawara;}</style><rect width="100%" height="100%" fill="#000" /><text xmlns="http://www.w3.org/2000/svg" x="50%" y="50%" text-anchor="middle" dominant-baseline="central" font-size="40px">',
					dateStr,
					"</text></svg>"
				)
			);
	}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}