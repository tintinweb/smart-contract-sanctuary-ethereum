// SPDX-License-Identifier: MIT
  
pragma solidity ^0.8.0;

import "./presets/ERC721EnviousDynamicPreset.sol";

contract GhostCollection is ERC721EnviousDynamicPreset {
	
	address private _superUser;
	address private _superMinter;
	
	constructor(
		string memory tokenName,
		string memory tokenSymbol,
		string memory baseTokenURI,
		uint256[] memory edgeValues,
		uint256[] memory edgeOffsets,
		uint256[] memory edgeRanges,
		address tokenMeasurment
	) ERC721EnviousDynamicPreset(
		tokenName,
		tokenSymbol,
		baseTokenURI,
		edgeValues,
		edgeOffsets,
		edgeRanges,
		tokenMeasurment
	) {
		_superUser = _msgSender();
		_superMinter = _msgSender();
	}

	modifier onlySuperUser {
		require(_msgSender() == _superUser, "only for super user");
		_;
	}

	function mint(address to) public override {
		require(_msgSender() == _superMinter, "only for super minter");
		super.mint(to);
	}

	function setGhostAddresses(
		address ghostToken, 
		address ghostBonding
	) public override onlySuperUser {
		super.setGhostAddresses(ghostToken, ghostBonding);
	}

	function changeBaseUri(string memory newBaseURI) external onlySuperUser {
		super._changeBaseURI(newBaseURI);
	}

	function renewSuperMinter(address who) external onlySuperUser {
		_superMinter = who;
	}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../extension/ERC721Envious.sol";
import "../interfaces/IERC721EnviousDynamic.sol";
import "../openzeppelin/token/ERC721/extensions/ERC721Enumerable.sol";
import "../openzeppelin/token/ERC20/IERC20.sol";
import "../openzeppelin/token/ERC20/utils/SafeERC20.sol";
import "../openzeppelin/utils/Address.sol";
import "../openzeppelin/utils/Strings.sol";
import "../openzeppelin/utils/Counters.sol";

/**
 * @title ERC721 Collateralization Dynamic Mock
 * This mock shows an implementation of ERC721Envious with dynamic URI.
 * It will change on every collateral modification. Handmade `totalSupply` 
 * function will be used in order to be used in {_disperse} function.
 *
 * @author 5Tr3TcH @ghostchain
 * @author 571nkY @ghostchain
 */
contract ERC721EnviousDynamicPreset is IERC721EnviousDynamic, ERC721Enumerable, ERC721Envious {

	using SafeERC20 for IERC20;
	using Address for address;
	using Strings for uint256;
	using Counters for Counters.Counter;

	string private _baseTokenURI;
	Counters.Counter private _tokenTracker;

	// token that will be used for dynamic measurment
	address public measurmentTokenAddress;

	// edges within which redistribution of URI will take place
	Edge[] public edges;

	// solhint-disable-next-line
	string private constant ZERO_ADDRESS = "zero address found";
	
	constructor(
		string memory tokenName,
		string memory tokenSymbol,
		string memory baseTokenURI,
		uint256[] memory edgeValues,
		uint256[] memory edgeOffsets,
		uint256[] memory edgeRanges,
		address tokenMeasurment
	) ERC721(tokenName, tokenSymbol) {
		require(tokenMeasurment != address(0), ZERO_ADDRESS);
		require(
			edgeValues.length == edgeOffsets.length && 
			edgeValues.length == edgeRanges.length,
			ZERO_ADDRESS
		);

		measurmentTokenAddress = tokenMeasurment;
		_changeBaseURI(baseTokenURI);

		for (uint256 i = 0; i < edgeValues.length; i++) {
			edges.push(Edge({
				value: edgeValues[i], 
				offset: edgeOffsets[i], 
				range: edgeRanges[i]
			}));
		}
	}

	receive() external payable {
		_disperseTokenCollateral(msg.value, address(0));
	}

	/**
	 * @dev See {IERC165-supportsInterface}.
	 */
	function supportsInterface(bytes4 interfaceId)
		public
		view
		virtual
		override(IERC165, ERC721Enumerable, ERC721Envious)
		returns (bool)
	{
		return interfaceId == type(IERC721EnviousDynamic).interfaceId ||
			ERC721Enumerable.supportsInterface(interfaceId) ||
			ERC721Envious.supportsInterface(interfaceId);
	}

	/**
	 * @dev See {_baseURI}.
	 */
	function baseURI() external view virtual returns (string memory) {
		return _baseURI();
	}

	/**
	 * @dev Getter function for each token URI.
	 *
	 * Requirements:
	 * - `tokenId` must exist.
	 *
	 * @param tokenId unique identifier of token
	 * @return token URI string
	 */
	function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
		_requireMinted(tokenId);
		
		string memory currentURI = _baseURI();
		uint256 tokenPointer = getTokenPointer(tokenId);
		return string(abi.encodePacked(currentURI, tokenPointer.toString(), ".json"));
	}

	/**
	 * @dev Get `tokenURI` for specific token based on predefined `edges`.
	 *
	 * @param tokenId unique identifier for token
	 */
	function getTokenPointer(uint256 tokenId) public view virtual override returns (uint256) {
		uint256 collateral = collateralBalances[tokenId][measurmentTokenAddress];
		uint256 totalDisperse = disperseBalance[measurmentTokenAddress] / totalSupply();
		uint256	takenDisperse = disperseTaken[tokenId][measurmentTokenAddress];
		uint256 value = collateral + totalDisperse - takenDisperse;

		uint256 range = 1;
		uint256 offset = 0;

		for (uint256 i = edges.length; i > 0; i--) {
			if (value >= edges[i-1].value) {
				range = edges[i-1].range;
				offset = edges[i-1].offset;
				break;
			}
		}

		uint256 seed = uint256(keccak256(abi.encodePacked(tokenId, collateral, totalDisperse))) % range;
		return seed + offset;
	}

	/**
	 * @dev Set ghost related addresses.
	 *
	 * Requirements:
	 * - `ghostAddress` must be non-zero address
	 * - `ghostBonding` must be non-zero address
	 *
	 * @param ghostToken non-rebasing wrapping token address
	 * @param ghostBonding bonding contract address
	 */
	function setGhostAddresses(
		address ghostToken, 
		address ghostBonding
	) public virtual {
		require(
			ghostToken != address(0) && ghostBonding != address(0),
			ZERO_ADDRESS
		);
		_changeGhostAddresses(ghostToken, ghostBonding);
	}

	/**
	 * @dev See {IERC721Envious-_changeCommunityAddresses}.
	 */
	function changeCommunityAddresses(address newTokenAddress, address newBlackHole) public virtual {
		require(newTokenAddress != address(0), ZERO_ADDRESS);
		_changeCommunityAddresses(newTokenAddress, newBlackHole);
	}

	/**
	 * @dev See {ERC721EnviousDynamic-mint}
	 */
	function mint(address to) public virtual override {
		_tokenTracker.increment();
		_safeMint(to, _tokenTracker.current());
	}

	/**
	 * @dev See {ERC721-_burn}
	 */
	function burn(uint256 tokenId) public virtual {
		_burn(tokenId);
	}

	/**
	 * @dev See {ERC721Envious-_disperse}
	 */
	function _disperse(address tokenAddress, uint256 tokenId) internal virtual override {
		uint256 balance = disperseBalance[tokenAddress] / totalSupply();

		if (disperseTotalTaken[tokenAddress] + balance > disperseBalance[tokenAddress]) {
			balance = disperseBalance[tokenAddress] - disperseTotalTaken[tokenAddress];
		}

		if (balance > disperseTaken[tokenId][tokenAddress]) {
			uint256 amount = balance - disperseTaken[tokenId][tokenAddress];
			disperseTaken[tokenId][tokenAddress] += amount;

			(bool shouldAppend,) = _arrayContains(tokenAddress, collateralTokens[tokenId]);
			if (shouldAppend) {
				collateralTokens[tokenId].push(tokenAddress);
			}
			
			collateralBalances[tokenId][tokenAddress] += amount;
			disperseTotalTaken[tokenAddress] += amount;
		}
	}

	/**
	 * @dev Getter function for `_baseTokenURI`.
	 *
	 * @return base URI string
	 */
	function _baseURI() internal view virtual override returns (string memory) {
		return _baseTokenURI;
	}

	/**
	 * @dev Ability to change URI for the collection.
	 */
	function _changeBaseURI(string memory newBaseURI) internal virtual {
		_baseTokenURI = newBaseURI;
	}

	/**
	 * @dev See {ERC721-_beforeTokenTransfer}.
	 */
	function _beforeTokenTransfer(
		address from,
		address to,
		uint256 firstTokenId,
		uint256 batchSize
	) internal virtual override(ERC721, ERC721Enumerable) {
		ERC721Enumerable._beforeTokenTransfer(from, to, firstTokenId, batchSize);
	}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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
     * @dev See {ERC721-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);

        if (batchSize > 1) {
            // Will only trigger during construction. Batch transferring (minting) is not available afterwards.
            revert("ERC721Enumerable: consecutive transfers not supported");
        }

        uint256 tokenId = firstTokenId;

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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
        address owner = _ownerOf(tokenId);
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
            "ERC721: approve caller is not token owner or approved for all"
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
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");

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
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
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
     * @dev Returns the owner of the `tokenId`. Does NOT revert if token doesn't exist
     */
    function _ownerOf(uint256 tokenId) internal view virtual returns (address) {
        return _owners[tokenId];
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
        return _ownerOf(tokenId) != address(0);
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

        _beforeTokenTransfer(address(0), to, tokenId, 1);

        // Check that tokenId was not minted by `_beforeTokenTransfer` hook
        require(!_exists(tokenId), "ERC721: token already minted");

        unchecked {
            // Will not overflow unless all 2**256 token ids are minted to the same owner.
            // Given that tokens are minted one by one, it is impossible in practice that
            // this ever happens. Might change if we allow batch minting.
            // The ERC fails to describe this case.
            _balances[to] += 1;
        }

        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId, 1);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     * This is an internal function that does not check if the sender is authorized to operate on the token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId, 1);

        // Update ownership in case tokenId was transferred by `_beforeTokenTransfer` hook
        owner = ERC721.ownerOf(tokenId);

        // Clear approvals
        delete _tokenApprovals[tokenId];

        unchecked {
            // Cannot overflow, as that would require more tokens to be burned/transferred
            // out than the owner initially received through minting and transferring in.
            _balances[owner] -= 1;
        }
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId, 1);
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

        _beforeTokenTransfer(from, to, tokenId, 1);

        // Check that tokenId was not transferred by `_beforeTokenTransfer` hook
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");

        // Clear approvals from the previous owner
        delete _tokenApprovals[tokenId];

        unchecked {
            // `_balances[from]` cannot overflow for the same reason as described in `_burn`:
            // `from`'s balance is the number of token held, which is at least one before the current
            // transfer.
            // `_balances[to]` could overflow in the conditions described in `_mint`. That would require
            // all 2**256 token ids to be minted, which in practice is impossible.
            _balances[from] -= 1;
            _balances[to] += 1;
        }
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId, 1);
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
     * @dev Hook that is called before any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens will be transferred to `to`.
     * - When `from` is zero, the tokens will be minted for `to`.
     * - When `to` is zero, ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256, /* firstTokenId */
        uint256 batchSize
    ) internal virtual {
        if (batchSize > 1) {
            if (from != address(0)) {
                _balances[from] -= batchSize;
            }
            if (to != address(0)) {
                _balances[to] += batchSize;
            }
        }
    }

    /**
     * @dev Hook that is called after any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens were transferred to `to`.
     * - When `from` is zero, the tokens were minted for `to`.
     * - When `to` is zero, ``from``'s tokens were burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.0;

interface INoteKeeper {
    // Info for market note
	struct Note {
		uint256 payout; // gOHM remaining to be paid
		uint48 created; // time market was created
		uint48 matured; // timestamp when market is matured
		uint48 redeemed; // time market was redeemed
		uint48 marketID; // market ID of deposit. uint48 to avoid adding a slot.
	}
	
	function redeem(address _user, uint256[] memory _indexes, bool _sendgOHM) external returns (uint256);
	
	function redeemAll(address _user, bool _sendgOHM) external returns (uint256);
	
	function pushNote(address to, uint256 index) external;
	
	function pullNote(address from, uint256 index) external returns (uint256 newIndex_);
	
	function indexesFor(address _user) external view returns (uint256[] memory);
	
	function pendingFor(address _user, uint256 _index) external view returns (uint256 payout_, bool matured_);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721Envious.sol";

/**
 * @title Additional extension for IERC721Envious, in order to make 
 * `tokenURI` dynamic, based on actual collateral.
 * @author 571nkY @ghostchain
 * @dev Ability to get royalty payments from collateral NFTs.
 */
interface IERC721EnviousDynamic is IERC721Envious {
	struct Edge {
		uint256 value;
		uint256 offset;
		uint256 range;
	}

	/**
	 * @dev Get `tokenURI` for specific token based on edges. Where actual 
	 * collateral should define which edge should be used, range shows
	 * maximum value in current edge, offset shows minimal value in current
	 * edge.
	 *
	 * @param tokenId unique identifier for token
	 */
	function getTokenPointer(uint256 tokenId) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../openzeppelin/token/ERC721/IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional Envious extension.
 * @author F4T50 @ghostchain
 * @author 571nkY @ghostchain
 * @author 5Tr3TcH @ghostchain
 * @dev Ability to collateralize each NFT in collection.
 */
interface IERC721Envious is IERC721 {
	event Collateralized(uint256 indexed tokenId, uint256 amount, address tokenAddress);
	event Uncollateralized(uint256 indexed tokenId, uint256 amount, address tokenAddress);
	event Dispersed(address indexed tokenAddress, uint256 amount);
	event Harvested(address indexed tokenAddress, uint256 amount, uint256 scaledAmount);

	/**
	 * @dev An array with two elements. Each of them represents percentage from collateral
	 * to be taken as a commission. First element represents collateralization commission.
	 * Second element represents uncollateralization commission. There should be 3 
	 * decimal buffer for each of them, e.g. 1000 = 1%.
	 *
	 * @param index of value in array.
	 */
	function commissions(uint256 index) external view returns (uint256);

	/**
	 * @dev Address of token that will be paid on bonds.
	 *
	 * @return address address of token.
	 */
	function ghostAddress() external view returns (address);

	/**
	 * @dev Address of smart contract, that provides purchasing of DeFi 2.0 bonds.
	 *
	 * @return address address of bonding smart.
	 */
	function ghostBondingAddress() external view returns (address);

	/**
	 * @dev 'Black hole' is any address that guarantee tokens sent to it will not be 
	 * retrieved from there. Note: some tokens revert on transfer to zero address.
	 *
	 * @return address address of black hole.
	 */
	function blackHole() external view returns (address);

	/**
	 * @dev Token that will be used to harvest collected commissions.
	 *
	 * @return address address of token.
	 */
	function communityToken() external view returns (address);

	/**
	 * @dev Pool of available tokens for harvesting.
	 *
	 * @param index in array.
	 * @return address of token.
	 */
	function communityPool(uint256 index) external view returns (address);

	/**
	 * @dev Token balance available for harvesting.
	 *
	 * @param tokenAddress addres of token.
	 * @return uint256 token balance.
	 */
	function communityBalance(address tokenAddress) external view returns (uint256);

	/**
	 * @dev Array of tokens that were dispersed.
	 *
	 * @param index in array.
	 * @return address address of dispersed token.
	 */
	function disperseTokens(uint256 index) external view returns (address);

	/**
	 * @dev Amount of tokens that was dispersed.
	 *
	 * @param tokenAddress address of token.
	 * @return uint256 token balance.
	 */
	function disperseBalance(address tokenAddress) external view returns (uint256);

	/**
	 * @dev Amount of tokens that was already taken from the disperse.
	 *
	 * @param tokenAddress address of token.
	 * @return uint256 total amount of tokens already taken.
	 */
	function disperseTotalTaken(address tokenAddress) external view returns (uint256);

	/**
	 * @dev Amount of disperse already taken by each tokenId.
	 *
	 * @param tokenId unique identifier of unit.
	 * @param tokenAddress address of token.
	 * @return uint256 amount of tokens already taken.
	 */
	function disperseTaken(uint256 tokenId, address tokenAddress) external view returns (uint256);

	/**
	 * @dev Available payouts.
	 *
	 * @param bondId bond unique identifier.
	 * @return uint256 potential payout.
	 */
	function bondPayouts(uint256 bondId) external view returns (uint256);

	/**
	 * @dev Mapping of `tokenId`s to array of bonds.
	 *
	 * @param tokenId unique identifier of unit.
	 * @param index in array.
	 * @return uint256 index of bond.
	 */
	function bondIndexes(uint256 tokenId, uint256 index) external view returns (uint256);

	/**
	 * @dev Mapping of `tokenId`s to token addresses who have collateralized before.
	 *
	 * @param tokenId unique identifier of unit.
	 * @param index in array.
	 * @return address address of token.
	 */
	function collateralTokens(uint256 tokenId, uint256 index) external view returns (address);

	/**
	 * @dev Token balances that are stored under `tokenId`.
	 *
	 * @param tokenId unique identifier of unit.
	 * @param tokenAddress address of token.
	 * @return uint256 token balance.
	 */
	function collateralBalances(uint256 tokenId, address tokenAddress) external view returns (uint256);

	/**
	 * @dev Calculator function for harvesting.
	 *
	 * @param amount of `communityToken`s to spend
	 * @param tokenAddress of token to be harvested
	 * @return amount to harvest based on inputs
	 */
	function getAmount(uint256 amount, address tokenAddress) external view returns (uint256);

	/**
	 * @dev Collect commission fees gathered in exchange for `communityToken`.
	 *
	 * @param amounts array of amounts to collateralize
	 * @param tokenAddresses array of token addresses
	 */
	function harvest(uint256[] memory amounts, address[] memory tokenAddresses) external;

	/**
	 * @dev Collateralize NFT with different tokens and amounts.
	 *
	 * @param tokenId unique identifier for specific NFT
	 * @param amounts array of amounts to collateralize
	 * @param tokenAddresses array of token addresses
	 */
	function collateralize(
		uint256 tokenId,
		uint256[] memory amounts,
		address[] memory tokenAddresses
	) external payable;

	/**
	 * @dev Withdraw underlying collateral.
	 *
	 * Requirements:
	 * - only owner of NFT
	 *
	 * @param tokenId unique identifier for specific NFT
	 * @param amounts array of amounts to collateralize
	 * @param tokenAddresses array of token addresses
	 */
	function uncollateralize(
		uint256 tokenId, 
		uint256[] memory amounts, 
		address[] memory tokenAddresses
	) external;

	/**
	 * @dev Collateralize NFT with discount, based on available bonds. While
	 * purchased bond will have delay the owner will be current smart contract
	 *
	 * @param bondId the ID of the market
	 * @param tokenId unique identifier of NFT inside current smart contract
	 * @param amount the amount of quote token to spend
	 * @param maxPrice the maximum price at which to buy bond
	 */
	function getDiscountedCollateral(
		uint256 bondId,
		address quoteToken,
		uint256 tokenId,
		uint256 amount,
		uint256 maxPrice
	) external;

	/**
	 * @dev Claim collateral inside this smart contract and extending underlying
	 * data mappings.
	 *
	 * @param tokenId unique identifier of NFT inside current smart contract
	 * @param indexes array of note indexes to redeem
	 */
	function claimDiscountedCollateral(uint256 tokenId, uint256[] memory indexes) external;

	/**
	 * @dev Split collateral among all existent tokens.
	 *
	 * @param amounts to be dispersed among all NFT owners
	 * @param tokenAddresses of token to be dispersed
	 */
	function disperse(uint256[] memory amounts, address[] memory tokenAddresses) external payable;

	/**
	 * @dev See {IERC721-_mint}
	 */
	function mint(address who) external;
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.0;

import "../openzeppelin/token/ERC20/IERC20.sol";

interface IBondDepository {
	event CreateMarket(
		uint256 indexed id,
		address indexed baseToken,
		address indexed quoteToken,
		uint256 initialPrice
	);
	
	event CloseMarket(uint256 indexed id);
	
	event Bond(
		uint256 indexed id,
		uint256 amount,
		uint256 price
	);
	
	event Tuned(
		uint256 indexed id,
		uint64 oldControlVariable,
		uint64 newControlVariable
	);
	
	// Info about each type of market
	struct Market {
		uint256 capacity;           // capacity remaining
		IERC20 quoteToken;          // token to accept as payment
		bool capacityInQuote;       // capacity limit is in payment token (true) or in STRL (false, default)
		uint64 totalDebt;           // total debt from market
		uint64 maxPayout;           // max tokens in/out (determined by capacityInQuote false/true)
		uint64 sold;                // base tokens out
		uint256 purchased;          // quote tokens in
	}
	
	// Info for creating new markets
	struct Terms {
		bool fixedTerm;             // fixed term or fixed expiration
		uint64 controlVariable;     // scaling variable for price
		uint48 vesting;             // length of time from deposit to maturity if fixed-term
		uint48 conclusion;          // timestamp when market no longer offered (doubles as time when market matures if fixed-expiry)
		uint64 maxDebt;             // 9 decimal debt maximum in STRL
	}
	
	// Additional info about market.
	struct Metadata {
		uint48 lastTune;            // last timestamp when control variable was tuned
		uint48 lastDecay;           // last timestamp when market was created and debt was decayed
		uint48 length;              // time from creation to conclusion. used as speed to decay debt.
		uint48 depositInterval;     // target frequency of deposits
		uint48 tuneInterval;        // frequency of tuning
		uint8 quoteDecimals;        // decimals of quote token
	}
	
	// Control variable adjustment data
	struct Adjustment {
		uint64 change;              // adjustment for price scaling variable 
		uint48 lastAdjustment;      // time of last adjustment
		uint48 timeToAdjusted;      // time after which adjustment should happen
		bool active;                // if adjustment is available
	}
	
	function deposit(
		uint256 _bid,               // the ID of the market
		uint256 _amount,            // the amount of quote token to spend
		uint256 _maxPrice,          // the maximum price at which to buy
		address _user,              // the recipient of the payout
		address _referral           // the operator address
	) external returns (uint256 payout_, uint256 expiry_, uint256 index_);
	
	function create (
		IERC20 _quoteToken,         // token used to deposit
		uint256[3] memory _market,  // [capacity, initial price]
		bool[2] memory _booleans,   // [capacity in quote, fixed term]
		uint256[2] memory _terms,   // [vesting, conclusion]
		uint32[2] memory _intervals // [deposit interval, tune interval]
	) external returns (uint256 id_);
	
	function close(uint256 _id) external;
	function isLive(uint256 _bid) external view returns (bool);
	function liveMarkets() external view returns (uint256[] memory);
	function liveMarketsFor(address _quoteToken) external view returns (uint256[] memory);
	function payoutFor(uint256 _amount, uint256 _bid) external view returns (uint256);
	function marketPrice(uint256 _bid) external view returns (uint256);
	function currentDebt(uint256 _bid) external view returns (uint256);
	function debtRatio(uint256 _bid) external view returns (uint256);
	function debtDecay(uint256 _bid) external view returns (uint64);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../openzeppelin/token/ERC721/ERC721.sol";
import "../openzeppelin/token/ERC20/utils/SafeERC20.sol";
import "../openzeppelin/token/ERC20/IERC20.sol";
import "../openzeppelin/token/ERC20/extensions/IERC20Metadata.sol";
import "../openzeppelin/utils/Address.sol";

import "../interfaces/IERC721Envious.sol";
import "../interfaces/IBondDepository.sol";
import "../interfaces/INoteKeeper.sol";

/**
 * @title ERC721 Collateralization
 *
 * @author F4T50 @ghostchain
 * @author 571nkY @ghostchain
 * @author 5Tr3TcH @ghostchain
 *
 * @dev This implements an optional extension of {ERC721} defined in the GhostEnvy lightpaper that
 * adds collateralization functionality for all tokens behind this smart contract as well as any
 * unique tokenId can have it's own floor price and/or estimated future price.
 */
abstract contract ERC721Envious is ERC721, IERC721Envious {
	using SafeERC20 for IERC20;

	/// @dev See {IERC721Envious-commissions}
	uint256[2] public override commissions;
	/// @dev See {IERC721Envious-blackHole}
	address public override blackHole;

	/// @dev See {IERC721Envious-ghostAddress}
	address public override ghostAddress;
	/// @dev See {IERC721Envious-ghostBondingAddress}
	address public override ghostBondingAddress;

	/// @dev See {IERC721Envious-communityToken}
	address public override communityToken;
	/// @dev See {IERC721Envious-communityPool}
	address[] public override communityPool;
	/// @dev See {IERC721Envious-communityBalance}
	mapping(address => uint256) public override communityBalance;

	/// @dev See {IERC721Envious-disperseTokens}
	address[] public override disperseTokens;
	/// @dev See {IERC721Envious-disperseBalance}
	mapping(address => uint256) public override disperseBalance;
	/// @dev See {IERC721Envious-disperseTotalTaken}
	mapping(address => uint256) public override disperseTotalTaken;
	/// @dev See {IERC721Envious-disperseTaken}
	mapping(uint256 => mapping(address => uint256)) public override disperseTaken;

	/// @dev See {IERC721Envious-bondPayouts}
	mapping(uint256 => uint256) public override bondPayouts;
	/// @dev See {IERC721Envious-bondIndexes}
	mapping(uint256 => uint256[]) public override bondIndexes;

	/// @dev See {IERC721Envious-collateralTokens}
	mapping(uint256 => address[]) public override collateralTokens;
	/// @dev See {IERC721Envious-collateralBalances}
	mapping(uint256 => mapping(address => uint256)) public override collateralBalances;

	// solhint-disable-next-line
	string private constant LENGTHS_NOT_MATCH = "ERC721Envious: lengths not match";
	// solhint-disable-next-line
	string private constant LOW_AMOUNT = "ERC721Envious: low amount";
	// solhint-disable-next-line
	string private constant EMPTY_GHOST = "ERC721Envious: ghost is empty";
	// solhint-disable-next-line
	string private constant NO_DECIMALS = "ERC721Envious: no decimals";
	// solhint-disable-next-line
	string private constant NOT_TOKEN_OWNER = "ERC721Envious: only for owner";
	// solhint-disable-next-line
	string private constant COMMISSION_TOO_HIGH = "ERC721Envious: commission is too high";

	/**
	 * @dev See {IERC165-supportsInterface}.
	 */
	function supportsInterface(bytes4 interfaceId)
		public 
		view 
		virtual 
		override(IERC165, ERC721) 
		returns (bool) 
	{
		return interfaceId == type(IERC721Envious).interfaceId || ERC721.supportsInterface(interfaceId);
	}

	/**
	 * @dev See {IERC721Envious-harvest}.
	 */
	function harvest(
		uint256[] memory amounts, 
		address[] memory tokenAddresses
	) external override virtual {
		require(amounts.length == tokenAddresses.length, LENGTHS_NOT_MATCH);
		for (uint256 i = 0; i < tokenAddresses.length; i++) {
			_harvest(amounts[i], tokenAddresses[i]);
		}
	}

	/**
	 * @dev See {IERC721Envious-collateralize}.
	 */
	function collateralize(
		uint256 tokenId,
		uint256[] memory amounts,
		address[] memory tokenAddresses
	) external payable override virtual {
		require(amounts.length == tokenAddresses.length, LENGTHS_NOT_MATCH);
		uint256 ethAmount = msg.value;
		for (uint256 i = 0; i < tokenAddresses.length; i++) {
			if (tokenAddresses[i] == address(0)) {
				ethAmount -= amounts[i];
			}
			_addTokenCollateral(tokenId, amounts[i], tokenAddresses[i], false);
		}
		
		if (ethAmount > 0) {
			Address.sendValue(payable(_msgSender()), ethAmount);
		} 
	}

	/**
	 * @dev See {IERC721Envious-uncollateralize}.
	 */
	function uncollateralize(
		uint256 tokenId, 
		uint256[] memory amounts, 
		address[] memory tokenAddresses
	) external override virtual {
		require(amounts.length == tokenAddresses.length, LENGTHS_NOT_MATCH);
		for (uint256 i = 0; i < tokenAddresses.length; i++) {
			_removeTokenCollateral(tokenId, amounts[i], tokenAddresses[i]);
		}
	}

	/**
	 * @dev See {IERC721Envious-disperse}.
	 */
	function disperse(
		uint256[] memory amounts, 
		address[] memory tokenAddresses
	) external payable override virtual {
		require(amounts.length == tokenAddresses.length, LENGTHS_NOT_MATCH);
		uint256 ethAmount = msg.value;
		for (uint256 i = 0; i < tokenAddresses.length; i++) {
			if (tokenAddresses[i] == address(0)) {
				ethAmount -= amounts[i];
			}
			_disperseTokenCollateral(amounts[i], tokenAddresses[i]);
		}
		
		if (ethAmount > 0) {
			Address.sendValue(payable(_msgSender()), ethAmount);
		} 
	}

	/**
	 * @dev See {IERC721Envious-getDiscountedCollateral}.
	 */
	function getDiscountedCollateral(
		uint256 bondId,
		address quoteToken,
		uint256 tokenId,
		uint256 amount,
		uint256 maxPrice
	) external virtual override {
		// NOTE: this contract is temporary holder of `quoteToken` due to the need of
		// registration of bond inside. `amount` of `quoteToken`s should be empty in
		// the end of transaction.
		_requireMinted(tokenId);
		
		IERC20(quoteToken).safeTransferFrom(_msgSender(), address(this), amount);
		IERC20(quoteToken).safeApprove(ghostBondingAddress, amount);
		
		(uint256 payout,, uint256 index) = IBondDepository(ghostBondingAddress).deposit(
			bondId,
			amount,
			maxPrice,
			address(this),
			address(this)
		);
		
		if (payout > 0) {
			bondPayouts[tokenId] += payout;
			bondIndexes[tokenId].push(index);
		}
	}

	/**
	 * @dev See {IERC721Envious-claimDiscountedCollateral}.
	 */
	function claimDiscountedCollateral(
		uint256 tokenId,
		uint256[] memory indexes
	) external virtual override {
		require(ghostAddress != address(0), EMPTY_GHOST);
		
		for (uint256 i = 0; i < indexes.length; i++) {
			uint256 index = _arrayContains(indexes[i], bondIndexes[tokenId]);
			bondIndexes[tokenId][index] = bondIndexes[tokenId][bondIndexes[tokenId].length - 1];
			bondIndexes[tokenId].pop();
		}
		
		uint256 payout = INoteKeeper(ghostBondingAddress).redeem(address(this), indexes, true);
		
		if (payout > 0) {
			bondPayouts[tokenId] -= payout;
			_addTokenCollateral(tokenId, payout, ghostAddress, true);
		}
	}

	/**
	 * @dev See {IERC721Envious-getAmount}
     */
	function getAmount(
		uint256 amount,
		address tokenAddress
	) public view virtual override returns (uint256) {
		uint256 circulatingSupply = IERC20(communityToken).totalSupply() - IERC20(communityToken).balanceOf(blackHole);
		return amount * _scaledAmount(tokenAddress) / circulatingSupply;
	}

	/**
	 * @dev Loop over the array in order to find specific token address index.
	 *
	 * @param tokenAddress address representing the ERC20 token or zero address for ETH
	 * @param findFrom array of addresses in which search should happen
	 *
	 * @return shouldAppend whether address not found and should be added to array
	 * @return index in array, default to uint256 max value if not found
	 */
	function _arrayContains(
		address tokenAddress,
		address[] memory findFrom
	) internal pure virtual returns (bool shouldAppend, uint256 index) {
		shouldAppend = true;
		index = type(uint256).max;

		for (uint256 i = 0; i < findFrom.length; i++) {
			if (findFrom[i] == tokenAddress) {
				shouldAppend = false;
				index = i;
				break;
			}
		}
	}

	/**
	 * @dev Loop over the array in order to find specific note index.
	 *
	 * @param noteId index of note stored previously
	 * @param findFrom array of note indexes
	 *
	 * @return index in array, default to uint256 max value if not found
	 */
	function _arrayContains(
		uint256 noteId,
		uint256[] memory findFrom
	) internal pure virtual returns (uint256 index) {
		index = type(uint256).max;

		for (uint256 i = 0; i < findFrom.length; i++) {
			if (findFrom[i] == noteId) {
				index = i;
				break;
			}
		}
	}

	/**
	 * @dev Calculate amount to harvest with `communityToken` for the collected
	 * commission. Calculation should happen based on all available ERC20 in
	 * `communityPool`.
	 *
	 * @param tokenAddress address representing the ERC20 token or zero address for ETH
	 *
	 * @return maximum scaled proportion
	 */
	function _scaledAmount(address tokenAddress) internal view virtual returns (uint256) {
		uint256 totalValue = 0;
		uint256 scaled = 0;
		uint256 defaultDecimals = 10**IERC20Metadata(communityToken).decimals();

		for (uint256 i = 0; i < communityPool.length; i++) {
			uint256 innerDecimals = communityPool[i] == address(0) ? 10**18 : 10**IERC20Metadata(communityPool[i]).decimals();
			uint256 tempValue = communityBalance[communityPool[i]] * defaultDecimals / innerDecimals;
			
			totalValue += tempValue;

			if (communityPool[i] == tokenAddress) {
				scaled = tempValue;
			}
		}

		return communityBalance[tokenAddress] * totalValue / scaled;
	}

	/**
	 * @dev Function for `communityToken` owners if they want to redeem collected
	 * commission in exchange for `communityToken`, while tokens will be send to
	 * zero address in order to lock them forever.
	 *
	 * @param amount represents amount of `communityToken` to be send
	 * @param tokenAddress address representing the ERC20 token or zero address for ETH
	 */
	function _harvest(uint256 amount, address tokenAddress) internal virtual  {
		uint256 scaledAmount = getAmount(amount, tokenAddress);
		communityBalance[tokenAddress] -= scaledAmount;

		if (communityBalance[tokenAddress] == 0) {
			(, uint256 index) = _arrayContains(tokenAddress, communityPool);
			communityPool[index] = communityPool[communityPool.length - 1];
			communityPool.pop();
		}

		if (tokenAddress == address(0)) {
			Address.sendValue(payable(_msgSender()), scaledAmount);
		} else {
			IERC20(tokenAddress).safeTransfer(_msgSender(), scaledAmount);
		}

		// NOTE: not every token implements `burn` function, so that is a littl cheat
		IERC20(communityToken).safeTransferFrom(_msgSender(), blackHole, amount);

		emit Harvested(tokenAddress, amount, scaledAmount);
	}

	/**
	 * @dev Ability for any user to collateralize any existent ERC721 token with
	 * any ERC20 token.
	 *
	 * Requirements:
	 * - `tokenId` token must exist.
	 * - `amount` should be greater than zero.
	 *
	 * @param tokenId unique identifier of NFT inside current smart contract
	 * @param amount represents amount of ERC20 to be send
	 * @param tokenAddress address representing the ERC20 token or zero address for ETH
	 */
	function _addTokenCollateral(
		uint256 tokenId, 
		uint256 amount, 
		address tokenAddress,
		bool claim
	) internal virtual {
		require(amount > 0, LOW_AMOUNT);
		_requireMinted(tokenId);

		_disperse(tokenAddress, tokenId);

		(bool shouldAppend,) = _arrayContains(tokenAddress, collateralTokens[tokenId]);
		if (shouldAppend) {
			_checkValidity(tokenAddress);
			collateralTokens[tokenId].push(tokenAddress);
		}

		uint256 ownerBalance = _communityCommission(amount, commissions[0], tokenAddress);
		collateralBalances[tokenId][tokenAddress] += ownerBalance;

		if (tokenAddress != address(0) && !claim) {
			IERC20(tokenAddress).safeTransferFrom(_msgSender(), address(this), amount);
		}

		emit Collateralized(tokenId, amount, tokenAddress);
	}

	/**
	 * @dev Ability for ERC721 owner to withdraw ERC20 collateral that was
	 * previously pushed inside.
	 *
	 * Requirements:
	 * - `tokenId` token must exist.
	 * - `amount` must be less or equal than collateralized value.
	 *
	 * @param tokenId unique identifier of NFT inside current smart contract
	 * @param amount represents amount of ERC20 collateral to withdraw
	 * @param tokenAddress address representing the ERC20 token or zero address for ETH
	 */
	function _removeTokenCollateral(
		uint256 tokenId, 
		uint256 amount, 
		address tokenAddress
	) internal virtual {
		require(_ownerOf(tokenId) == _msgSender(), NOT_TOKEN_OWNER);
		_disperse(tokenAddress, tokenId);

		collateralBalances[tokenId][tokenAddress] -= amount;
		if (collateralBalances[tokenId][tokenAddress] == 0) {
			(, uint256 index) = _arrayContains(tokenAddress, collateralTokens[tokenId]);
			collateralTokens[tokenId][index] = collateralTokens[tokenId][collateralTokens[tokenId].length - 1];
			collateralTokens[tokenId].pop();
		}

		uint256 ownerBalance = _communityCommission(amount, commissions[1], tokenAddress);

		if (tokenAddress == address(0)) {
			Address.sendValue(payable(_msgSender()), ownerBalance);
		} else {
			IERC20(tokenAddress).safeTransfer(_msgSender(), ownerBalance);
		}

		emit Uncollateralized(tokenId, ownerBalance, tokenAddress);
	}

	/**
	 * @dev Disperse any input amount of tokens between all token owners in current
	 * smart contract. Balance will be stored inside `disperseBalance` after which
	 * any user can take it with help of {_disperse}.
	 *
	 * Requirements:
	 * - `amount` must be greater than zero.
	 *
	 * @param amount represents amount of ERC20 tokens to disperse
	 * @param tokenAddress address representing the ERC20 token or zero address for ETH
	 */
	function _disperseTokenCollateral(uint256 amount, address tokenAddress) internal virtual {
		require(amount > 0, LOW_AMOUNT);

		(bool shouldAppend,) = _arrayContains(tokenAddress, disperseTokens);
		if (shouldAppend) {
			_checkValidity(tokenAddress);
			disperseTokens.push(tokenAddress);
		}

		disperseBalance[tokenAddress] += amount;
		
		if (tokenAddress != address(0)) {
			IERC20(tokenAddress).safeTransferFrom(_msgSender(), address(this), amount);
		}

		emit Dispersed(tokenAddress, amount);
	}

	/**
	 * @dev Need to check if the token address has this function, because it will be used in
	 * scaledAmount later. Otherwise _scaledAmount will revert on every call.
	 *
	 * Requirements:
	 * - all addresses except zero address, because it is used for ETH
	 * - any check for decimals, the idea is to be reverted if function does not exist
	 *
	 * @param tokenAddress potential address of ERC20 token.
	 */
	function _checkValidity(address tokenAddress) internal virtual {
		if (tokenAddress != address(0)) {
			require(IERC20Metadata(tokenAddress).decimals() != type(uint8).max, NO_DECIMALS);
		}
	}

	/**
	 * @dev Function that calculates output amount after community commission taken.
	 *
	 * @param amount represents amount of ERC20 tokens or ETH to disperse
	 * @param percentage represents commission to be taken
	 * @param tokenAddress address representing the ERC20 token or zero address for ETH
	 *
	 * @return amount after commission
	 */
	function _communityCommission(
		uint256 amount,
		uint256 percentage,
		address tokenAddress
	) internal returns (uint256) {
		uint256 donation = amount * percentage / 1e5;

		(bool shouldAppend,) = _arrayContains(tokenAddress, communityPool);
		if (shouldAppend && donation > 0) {
			communityPool.push(tokenAddress);
		}

		communityBalance[tokenAddress] += donation;
		return amount - donation;
	}

	/**
	 * @dev Ability to change commission.
	 *
	 * @param incoming is commission when user collateralize
	 * @param outcoming is commission when user uncollateralize
	 */
	function _changeCommissions(uint256 incoming, uint256 outcoming) internal virtual {
		require(incoming < 1e5 && outcoming < 1e5, COMMISSION_TOO_HIGH);
		commissions[0] = incoming;
		commissions[1] = outcoming;
	}

	/**
	 * @dev Ability to change commission token.
	 *
	 * @param newTokenAddress represents new token for commission
	 * @param newBlackHole represents address for harvested tokens
	 */
	function _changeCommunityAddresses(address newTokenAddress, address newBlackHole) internal virtual {
		communityToken = newTokenAddress;
		blackHole = newBlackHole;
	}

	/**
	 * @dev Ability to change commission token.
	 *
	 * @param newGhostTokenAddress represents GHST token address
	 * @param newGhostBondingAddress represents ghostDAO bonding contract address
	 */
	function _changeGhostAddresses(
		address newGhostTokenAddress, 
		address newGhostBondingAddress
	) internal virtual {
		ghostAddress = newGhostTokenAddress;
		ghostBondingAddress = newGhostBondingAddress;
	}

	/**
	 * @dev Function that will disperse tokens from `disperseBalance` to any NFT
	 * owner. Should happen during uncollateralize process.
	 *
	 * @param tokenAddress address representing the ERC20 token or zero address for ETH
	 * @param tokenId unique identifier of NFT in collection
	 */
	function _disperse(address tokenAddress, uint256 tokenId) internal virtual {}
}