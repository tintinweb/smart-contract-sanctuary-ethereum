// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "./SVG.sol";

contract Today is IERC721, ERC721Enumerable {
	SVG private svg;

	//for debug
	uint256 public constant PRICE_MAX = 1024_000 gwei;
	uint256 public constant PRICE_MIN = 10 gwei;

	//for mainnet
	// uint256 public constant PRICE_MAX = 1024_000_000_000 gwei;
	// uint256 public constant PRICE_MIN = 10_000_000 gwei;

	uint256 public constant PRICE_DECREASE_PERCENTAGE = 50;
	uint256 private constant NY_TIME_DIFF_HOURS = 4;
	uint256 private constant HOUR_IN_SECONDS = 3_600;
	uint256 private constant DAY_IN_SECONDS = 86_400;
	uint256 private constant YEAR_IN_SECONDS = 31_536_000;
	uint256 private constant LEAP_YEAR_IN_SECONDS = 31_622_400;
	uint256 private constant ORIGIN_YEAR = 1970;
	mapping(uint256 => uint256) private timeByTokenId;

	constructor() ERC721("Today", "TODAY") {
		svg = new SVG();
	}

	function mint() public payable {
		uint256 time = block.timestamp;
		require(msg.value == getPrice(), "Incorrect payable amount");

		//for debug
		uint256 tokenId = time;

		//for mainnet
		// uint256 tokenId = getTodayId(time);

		timeByTokenId[tokenId] = time;
		_mint(_msgSender(), tokenId);
	}

	function getTodayId(uint256 time) public pure returns (uint256) {
		(uint256 year, uint256 month, uint256 day) = parseTime(time);
		return year * 10000 + month * 100 + day;
	}

	function getPrice() public view returns (uint256) {
		uint256 _nyTime = getNYTime(block.timestamp);
		uint256 hour = (_nyTime / 1 hours) % 24;
		uint256 price = PRICE_MAX;
		for (uint256 i = 0; i < hour; i++) {
			uint256 currentPrice = (price * PRICE_DECREASE_PERCENTAGE) / 100;
			price = PRICE_MIN >= currentPrice ? PRICE_MIN : currentPrice;
		}
		return price;
	}

	function isMinted() public view returns (bool) {
		return _exists(getTodayId(block.timestamp));
	}

	function tokenURI(uint256 tokenId) public view override returns (string memory) {
		require(_exists(tokenId), "nonexistent token");
		string memory dateStr = getDateStr(timeByTokenId[tokenId]);
		return
			string(
				abi.encodePacked(
					"data:application/json;base64,",
					Base64.encode(
						abi.encodePacked(
							'{"name": "',
							dateStr,
							'", "image": "data:image/svg+xml;base64,',
							Base64.encode(bytes(svg.render(dateStr))),
							'"}'
						)
					)
				)
			);
	}

	function currentImage() public view returns (string memory) {
		return
			string(
				abi.encodePacked(
					"data:image/svg+xml;base64,",
					Base64.encode(bytes(svg.render(getDateStr(block.timestamp))))
				)
			);
	}

	function getDateStr(uint256 time) private pure returns (string memory) {
		(uint256 year, uint256 month, uint256 day) = parseTime(time);
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

	function parseTime(uint256 time)
		private
		pure
		returns (
			uint256 year,
			uint256 month,
			uint256 day
		)
	{
		uint256 nyTime = getNYTime(time);
		year = ORIGIN_YEAR + nyTime / YEAR_IN_SECONDS;
		uint256 numLeapYears = leapYearsBefore(year) - leapYearsBefore(ORIGIN_YEAR);
		uint256 secondsAccountedFor = LEAP_YEAR_IN_SECONDS * numLeapYears;
		secondsAccountedFor += YEAR_IN_SECONDS * (year - ORIGIN_YEAR - numLeapYears);
		while (secondsAccountedFor > nyTime) {
			if (isLeapYear(year - 1)) {
				secondsAccountedFor -= LEAP_YEAR_IN_SECONDS;
			} else {
				secondsAccountedFor -= YEAR_IN_SECONDS;
			}
			year -= 1;
		}
		uint256 buf = leapYearsBefore(year) - leapYearsBefore(ORIGIN_YEAR);
		secondsAccountedFor = LEAP_YEAR_IN_SECONDS * buf;
		secondsAccountedFor += YEAR_IN_SECONDS * (year - ORIGIN_YEAR - buf);
		for (uint256 i = 1; i <= 12; i++) {
			uint256 secondsInMonth = DAY_IN_SECONDS * getDaysInMonth(i, year);
			if (secondsInMonth + secondsAccountedFor > nyTime) {
				month = i;
				break;
			}
			secondsAccountedFor += secondsInMonth;
		}
		for (uint256 i = 1; i <= getDaysInMonth(month, year); i++) {
			if (DAY_IN_SECONDS + secondsAccountedFor > nyTime) {
				day = i;
				break;
			}
			secondsAccountedFor += DAY_IN_SECONDS;
		}
	}

	function isLeapYear(uint256 year) private pure returns (bool) {
		if (year % 4 != 0) return false;
		if (year % 100 != 0) return true;
		if (year % 400 != 0) return false;
		return true;
	}

	function leapYearsBefore(uint256 year) private pure returns (uint256) {
		year -= 1;
		return year / 4 - year / 100 + year / 400;
	}

	function getDaysInMonth(uint256 month, uint256 year) private pure returns (uint256) {
		if (month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10 || month == 12) return 31;
		else if (month == 4 || month == 6 || month == 9 || month == 11) return 30;
		else if (isLeapYear(year)) return 29;
		else return 28;
	}

	function getNYTime(uint256 time) private pure returns (uint256) {
		return time - NY_TIME_DIFF_HOURS * HOUR_IN_SECONDS;
	}

	function withdraw() public pure {
		revert();
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Strings.sol";

contract SVG {
	function render(string memory dateStr) public pure returns (string memory) {
		uint256 hue;
		uint256 sat;
		uint256 lum;
		{
			uint256 seed = uint256(keccak256(abi.encodePacked(dateStr)));
			uint256 maxHue;
			uint256 minHue;
			uint256 maxSat;
			uint256 minSat;
			uint256 maxLum;
			uint256 minLum;
			uint256 count = 0;
			uint256 noise = rand(seed, ++count) % 100;
			if (noise < 80) {
				maxHue = 181;
				minHue = 159;
				maxSat = 35;
				minSat = 12;
				maxLum = 12;
				minLum = 7;
				if (noise < 5) {
					maxSat = 100;
					minSat = 99;
					maxLum = 25;
					minLum = 15;
					if (noise < 1) {
						maxHue = 370;
						minHue = 350;
						maxLum = 40;
						minLum = 10;
					}
				}
			} else if (noise >= 80 && noise < 85) {
				maxHue = 59;
				minHue = 24;
				maxSat = 15;
				minSat = 8;
				maxLum = 13;
				minLum = 8;
			} else if (noise >= 85 && noise <= 100) {
				maxHue = 215;
				minHue = 205;
				maxSat = 90;
				minSat = 50;
				maxLum = 30;
				minLum = 15;
			}
			hue = minHue + (rand(seed, ++count) % (maxHue - minHue));
			sat = minSat + (rand(seed, ++count) % (maxSat - minSat));
			lum = minLum + (rand(seed, ++count) % (maxLum - minLum));
		}
		return
			string(
				abi.encodePacked(
					'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 660 500"><style>svg{background-color:#000;}@font-face{font-family:"Today";src:url("data:application/font-woff2;charset=utf-8;base64,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")format("woff2");}text{fill:#fff;font-family:Today;}</style><rect width="100%" height="100%" style="fill:hsl(',
					Strings.toString(hue),
					",",
					Strings.toString(sat),
					"%,",
					Strings.toString(lum),
					'%);" /><text x="50%" y="260px" text-anchor="middle" dominant-baseline="central" font-size="90px">',
					dateStr,
					"</text></svg>"
				)
			);
	}

	function rand(uint256 seed0, uint256 seed1) private pure returns (uint256) {
		return uint256(keccak256(abi.encodePacked(seed0, seed1)));
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