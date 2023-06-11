// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "./imports/ERC721Metadata.sol";
import "./imports/Store.sol";
import "./imports/TokenReceiver.sol";
import "./imports/Withdraw.sol";
import "./imports/ERC2981.sol";

contract Aelig is
    ERC165,
    Store,
    ERC721Metadata,
    TokenReceiver,
    Withdraw,
    ERC2981
{
    constructor(
        uint256 royaltyPercentage,
        address tokenAddress,
        uint256 rentPercentage
    )
        ERC2981(royaltyPercentage)
        Store(tokenAddress, rentPercentage)
    {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

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
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IERC165.sol";

contract ERC165 is IERC165 {
    mapping(bytes4 => bool) internal supportedInterfaces;

    constructor() {
        supportedInterfaces[0x01ffc9a7] = true; // ERC165
        supportedInterfaces[0x80ac58cd] = true; // ERC721
        supportedInterfaces[0x780e9d63] = true; // ERC721Enumerable
        supportedInterfaces[0x5b5e139f] = true; // ERC721Metadata
        supportedInterfaces[0xad092b5c] = true; // ERC4907
        supportedInterfaces[0x2a55205a] = true; // ERC2981
    }

    function supportsInterface(
        bytes4 _interfaceID
    )
        external
        override
        view
        returns (bool)
    {
        return supportedInterfaces[_interfaceID];
    }

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../interfaces/IERC2981.sol";
import "./Roles.sol";

contract ERC2981 is
    IERC2981,
    Roles
{
    uint256 public royaltyPercentage;

    constructor (uint256 _royaltyPercentage) {
        royaltyPercentage = _royaltyPercentage;
    }

    function royaltyInfo(
        uint256,
        uint256 _salePrice
    )
        external
        view
        override
        returns (
            address receiver,
            uint256 royaltyAmount
        )
    {
        return (address(this),  _salePrice / 10000 * royaltyPercentage);
    }

    function setRoyaltyInfo(
        uint256,
        uint256 _salePrice
    )
        external
        view
        override
        returns (
            address receiver,
            uint256 royaltyAmount
        )
    {
        return (address(this),  _salePrice / 10000 * royaltyPercentage);
    }

    function updateRoyaltyPercentage(
        uint256 percentage
    )
        external
        override
        isManager(msg.sender)
    {
        royaltyPercentage = percentage;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC165.sol";
import "../interfaces/IERC721.sol";
import "../interfaces/IERC721TokenReceiver.sol";
import "../libraries/AddressUtils.sol";
import "../libraries/Errors.sol";
import "../libraries/Constants.sol";


contract ERC721 is
    IERC721
{
    using AddressUtils for address;

    mapping (uint256 => address) internal idToOwner;
    mapping (uint256 => address) internal idToApproval;
    mapping (address => uint256) private ownerToNFTokenCount;
    mapping (address => mapping (address => bool)) internal ownerToOperators;

    /**
        @dev Guarantees that the msg.sender is an owner or operator of the given NFT.
        @param _tokenId ID of the NFT to validate.
    */
    modifier canOperate(
        uint256 _tokenId,
        address _operator
    )
    {
        address tokenOwner = idToOwner[_tokenId];
        require(
            tokenOwner == _operator || ownerToOperators[tokenOwner][_operator],
            errors.NOT_OWNER_OR_OPERATOR
        );
        _;
    }

    /**
        @dev Guarantees that the msg.sender is allowed to transfer NFT (msg.sender is owner, or approved, or operator).
        @param _tokenId ID of the NFT to transfer.
    */
    modifier canTransfer(
        uint256 _tokenId
    )
    {
        address tokenOwner = idToOwner[_tokenId];
        require(
            tokenOwner == msg.sender ||
            idToApproval[_tokenId] == msg.sender ||
            ownerToOperators[tokenOwner][msg.sender],
            errors.NOT_OWNER_APPROVED_OR_OPERATOR
        );
        _;
    }

    /**
        @dev Guarantees that _tokenId is a valid Token.
        @param _tokenId ID of the NFT to validate.
    */
    modifier validNFToken(
        uint256 _tokenId
    )
    {
        require(idToOwner[_tokenId] != address(0), errors.NOT_VALID_NFT);
        _;
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes calldata _data
    )
        external
        override
    {
        _safeTransferFrom(_from, _to, _tokenId, _data);
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    )
        external
        override
    {
        _safeTransferFrom(_from, _to, _tokenId, "");
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    )
        external
        override
        canTransfer(_tokenId)
        validNFToken(_tokenId)
    {
        address tokenOwner = idToOwner[_tokenId];
        require(tokenOwner == _from, errors.NOT_OWNER);
        require(_to != address(0), errors.ZERO_ADDRESS);

        _transfer(_to, _tokenId);
    }

    function approve(
        address _approved,
        uint256 _tokenId
    )
        external
        override
        canOperate(_tokenId, msg.sender)
        validNFToken(_tokenId)
    {
        address tokenOwner = idToOwner[_tokenId];
        require(_approved != tokenOwner, errors.IS_OWNER);

        idToApproval[_tokenId] = _approved;
        emit Approval(tokenOwner, _approved, _tokenId);
    }

    function setApprovalForAll(
        address _operator,
        bool _approved
    )
        external
        override
    {
        ownerToOperators[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    function balanceOf(
        address _owner
    )
        external
        override
        view
        returns (uint256)
    {
        require(_owner != address(0), errors.ZERO_ADDRESS);
        return _getOwnerNFTCount(_owner);
    }

    function ownerOf(
        uint256 _tokenId
    )
        external
        override
        view
        returns (address)
    {
        return _ownerOf(_tokenId);
    }

    function _ownerOf(
        uint256 _tokenId
    )
        internal
        view
        returns(address)
    {
        require(idToOwner[_tokenId] != address(0), errors.NOT_VALID_NFT);
        return idToOwner[_tokenId];
    }

    function getApproved(
        uint256 _tokenId
    )
        external
        override
        view
        validNFToken(_tokenId)
        returns (address)
    {
        return idToApproval[_tokenId];
    }

    function isApprovedForAll(
        address _owner,
        address _operator
    )
        external
        override
        view
        returns (bool)
    {
        return ownerToOperators[_owner][_operator];
    }

    function _transfer(
        address _to,
        uint256 _tokenId
    )
        internal
        virtual
    {
        address from = idToOwner[_tokenId];
        _clearApproval(_tokenId);

        _removeNFToken(from, _tokenId);
        _addNFToken(_to, _tokenId);

        emit Transfer(from, _to, _tokenId);
    }

    function _mint(
        address _to,
        uint256 _tokenId
    )
        internal
        virtual
    {
        require(_to != address(0), errors.ZERO_ADDRESS);
        require(idToOwner[_tokenId] == address(0), errors.NFT_ALREADY_EXISTS);

        _addNFToken(_to, _tokenId);

        emit Transfer(address(0), _to, _tokenId);
    }

    function _burn(
        uint256 _tokenId
    )
        internal
        virtual
        validNFToken(_tokenId)
    {
        address tokenOwner = idToOwner[_tokenId];
        _clearApproval(_tokenId);
        _removeNFToken(tokenOwner, _tokenId);
        emit Transfer(tokenOwner, address(0), _tokenId);
    }

    function _removeNFToken(
        address _from,
        uint256 _tokenId
    )
        internal
        virtual
    {
        require(idToOwner[_tokenId] == _from, errors.NOT_OWNER);
        ownerToNFTokenCount[_from] -= 1;
        delete idToOwner[_tokenId];
    }

    function _addNFToken(
        address _to,
        uint256 _tokenId
    )
        internal
        virtual
    {
        require(idToOwner[_tokenId] == address(0), errors.NFT_ALREADY_EXISTS);

        idToOwner[_tokenId] = _to;
        ownerToNFTokenCount[_to] += 1;
    }

    function _getOwnerNFTCount(
        address _owner
    )
        internal
        virtual
        view
        returns (uint256)
    {
        return ownerToNFTokenCount[_owner];
    }

    function _safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory _data
    )
        private
        canTransfer(_tokenId)
        validNFToken(_tokenId)
    {
        address tokenOwner = idToOwner[_tokenId];
        require(tokenOwner == _from, errors.NOT_OWNER);
        require(_to != address(0), errors.ZERO_ADDRESS);

        _transfer(_to, _tokenId);

        if (_to.isContract())
        {
            bytes4 retval = IERC721TokenReceiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data);
            require(retval == constants.MAGIC_ON_ERC721_RECEIVED, errors.NOT_ABLE_TO_RECEIVE_NFT);
        }
    }

    function _clearApproval(
        uint256 _tokenId
    )
        private
    {
        delete idToApproval[_tokenId];
    }

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../interfaces/IERC721Enumerable.sol";
import "./ERC721.sol";
import "../libraries/Errors.sol";

contract ERC721Enumerable is
    ERC721,
    IERC721Enumerable
{
    uint256 internal tokens;
    uint256 internal burnt;

    function totalSupply()
        external
        override
        view
        returns (uint256)
    {
        return tokens - burnt;
    }

    function mintedFrames()
        internal
        view
        returns(uint256)
    {
        return tokens;
    }

    function tokenByIndex(
        uint256 _index
    )
        external
        override
        view
        validNFToken(_index)
        returns (uint256)
    {
        return _index;
    }

    function tokenOfOwnerByIndex(
        address _owner,
        uint256 _index
    )
        external
        override
        view
        validNFToken(_index)
        returns (uint256)
    {
        require(_ownerOf(_index) == _owner, errors.NOT_OWNER);
        return _index;
    }

    function _mint(
        address _to,
        uint256 _tokenId
    )
        internal
        override
        virtual
    {
        super._mint(_to, _tokenId);
        tokens++;
    }

    function _burn(
        uint256 _tokenId
    )
        internal
        override
        virtual
    {
        super._burn(_tokenId);
        burnt++;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../interfaces/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./Lendable.sol";
import "./Roles.sol";

contract ERC721Metadata is
    IERC721Metadata,
    Lendable,
    Roles
{
    string internal constant nftName = "Aelig";
    string internal constant nftSymbol = "AELIG";
    string internal baseURL;

    function name()
        external
        override
        pure
        returns(string memory)
    {
        return nftName;
    }

    function symbol()
        external
        override
        pure
        returns(string memory)
    {
        return nftSymbol;
    }

    function tokenURI(
        uint256 _tokenId
    )
        external
        override
        view
        validNFToken(_tokenId)
        returns (string memory)
    {
        string memory uri = baseURL;
        uri = string.concat(uri, "?id=");
        uri = string.concat(uri, Strings.toString(block.chainid));
        uri = string.concat(uri, "-");
        uri = string.concat(uri, _toAsciiString(address(this)));
        uri = string.concat(uri, "-");
        uri = string.concat(uri, Strings.toString(_tokenId));
        return uri;
    }

    function updateBaseUrl(
        string memory _newBaseUrl
    )
        external
        override
    {
        require(msg.sender == manager, errors.NOT_AUTHORIZED);
        baseURL = _newBaseUrl;
    }

    function _toAsciiString(
        address x
    )
        internal
        pure
        returns (string memory)
    {
        bytes memory s = new bytes(40);
        for (uint i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint(uint160(x)) / (2**(8*(19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2*i] = _char(hi);
            s[2*i+1] = _char(lo);
        }
        return string(s);
    }

    function _char(
        bytes1 b
    )
        internal
        pure
        returns (bytes1 c)
    {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../interfaces/IFrameOwnership.sol";
import "./ERC721Enumerable.sol";
import "../interfaces/IERC1155.sol";

abstract contract FrameOwnership is
    IFrameOwnership,
    ERC721Enumerable
{
    mapping (uint256 => ExternalNFT) internal idToExternalNFT;

    modifier isEmptyFrame(uint256 _frameId) {
        require(idToExternalNFT[_frameId].contractAddress == address(0), errors.FRAME_NOT_EMPTY);
        _;
    }

    modifier isNotEmptyFrame(uint256 _frameId) {
        require(idToExternalNFT[_frameId].contractAddress != address(0), errors.FRAME_EMPTY);
        _;
    }

    function getNFTofFrame(
        uint256 frameId
    )
        external
        override
        view
        virtual
        validNFToken(frameId)
        returns(ExternalNFT memory)
    {
        return _getNFTofFrame(frameId);
    }

    function emptyFrame(
        address to,
        uint256 frameId
    )
        external
        override
    {
        require(_canEmptyFrame(frameId, msg.sender), errors.NOT_AUTHORIZED);
        _emptyFrame(frameId, to);
    }

    function _emptyFrame(
        uint256 frameId,
        address to
    )
        internal
        virtual
        validNFToken(frameId)
        isNotEmptyFrame(frameId)
    {
        require(to != address(0), errors.ZERO_ADDRESS);

        ExternalNFT memory nft = idToExternalNFT[frameId];

        IERC165 interfaceContract = IERC165(nft.contractAddress);

        if (interfaceContract.supportsInterface(0xd9b67a26)) {
            IERC1155 nftContract = IERC1155(nft.contractAddress);
            nftContract.safeTransferFrom(
                address(this),
                to,
                nft.id,
                1,
                ""
            );
        } else {
            IERC721 nftContract = ERC721(nft.contractAddress);
            nftContract.safeTransferFrom(
                address(this),
                to,
                nft.id
            );
        }

        delete idToExternalNFT[frameId];
        emit EmptyFrame(frameId, msg.sender);
    }

    function _canEmptyFrame(
        uint256 frameId,
        address account
    )
        internal
        virtual
        returns(bool)
    {
        address tokenOwner = idToOwner[frameId];
        return tokenOwner == account || ownerToOperators[tokenOwner][account];
    }

    function _burn(
        uint256 _tokenId
    )
        override
        virtual
        internal
    {
        if (idToExternalNFT[_tokenId].contractAddress != address(0)) {
            _emptyFrame(_tokenId, _ownerOf(_tokenId));
        }
        super._burn(_tokenId);
    }

    function _getNFTofFrame(
        uint256 frameId
    )
        internal
        validNFToken(frameId)
        virtual
        view
        isNotEmptyFrame(frameId)
        returns(ExternalNFT memory)
    {
        return idToExternalNFT[frameId];
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../interfaces/IERC4907.sol";
import "./FrameOwnership.sol";
import "../interfaces/ILendable.sol";

contract Lendable is
    IERC4907,
    ILendable,
    FrameOwnership
{
    mapping (uint256  => AccountInfo) internal idToAccountInfo; // id of frame to shared with account
    mapping (uint256 => bool) internal idToCanBeUpdated; // lent frame can be updated by receiver account
    mapping (uint256 => address) internal idToArtworkOwner; // id of frame to id of frame receiving artwork

    mapping (uint256 => FrameInfo) internal idToFrameInfo; // id of frame to id of frame receiving artwork

    modifier frameIsNotLent(uint256 frameId) {
        require(idToAccountInfo[frameId].expires < block.timestamp, errors.NOT_AUTHORIZED);
        _;
    }

    modifier artworkIsNotLent(uint256 frameId) {
        require(idToFrameInfo[frameId].expires < block.timestamp, errors.NOT_AUTHORIZED);
        _;
    }

    modifier userCanUpdateFrame(uint256 frameId, address user) {
        require(
            idToAccountInfo[frameId].expires < block.timestamp ||
            (idToAccountInfo[frameId].expires >= block.timestamp && idToCanBeUpdated[frameId]),
            errors.NOT_AUTHORIZED
        );
        _;
    }

    modifier notNullAddress(address account) {
        require(account != address(0), errors.ZERO_ADDRESS);
        _;
    }

    modifier isNotLendingToOwner(uint256 tokenId, address receiver) {
        address lender = _ownerOf(tokenId);
        require(lender != receiver, errors.NOT_AUTHORIZED);
        _;
    }

    function canBeUpdated(
        uint256 frameId
    )
        view
        external
        override
        returns(bool)
    {
        return idToAccountInfo[frameId].expires < block.timestamp || idToCanBeUpdated[frameId];
    }

    function setUser(
        uint256 tokenId,
        address user,
        uint64 expires
    )
        external
        override
    {
        _setUser(tokenId, user, expires);
    }

    function _setUser(
        uint256 tokenId,
        address user,
        uint64 expires
    )
        internal
        canTransfer(tokenId)
        frameIsNotLent(tokenId)
        notNullAddress(user)
        validNFToken(tokenId)
        isNotLendingToOwner(tokenId, user)
    {
        _lend(tokenId, user, expires, false);
    }

    function setUserWithUploads(
        uint256 tokenId,
        address user,
        uint64 expires
    )
        external
        override
    {
        _setUserWithUploads(tokenId, user, expires);
    }

    function _setUserWithUploads(
        uint256 tokenId,
        address user,
        uint64 expires
    )
        internal
        canTransfer(tokenId)
        frameIsNotLent(tokenId)
        notNullAddress(user)
        validNFToken(tokenId)
    {
        _lend(tokenId, user, expires, true);
    }

    function _lend(
        uint256 tokenId,
        address user,
        uint64 expires,
        bool canUpdate
    )
        private
    {
        if (idToArtworkOwner[tokenId] != address(0)) {
            _emptyFrame(tokenId, idToArtworkOwner[tokenId]);
        }
        idToCanBeUpdated[tokenId] = canUpdate;
        AccountInfo storage info =  idToAccountInfo[tokenId];
        info.account = user;
        info.expires = expires;
        emit UpdateUser(tokenId, user, expires);
    }

    function claimArtwork(
        address to,
        uint256 frameId
    )
        external
        override
        validNFToken(frameId)
        notNullAddress(to)
        frameIsNotLent(frameId)
        artworkIsNotLent(frameId)
    {
        _emptyFrame(frameId, to);
    }

    function claimFrame(
        uint256 frameId
    )
        external
        override
        frameIsNotLent(frameId)
        canTransfer(frameId)
        validNFToken(frameId)
    {
        _emptyFrame(frameId, idToArtworkOwner[frameId]);
    }

    function userOf(
        uint256 tokenId
    )
        external
        view
        override
        validNFToken(tokenId)
        returns(address)
    {
        if (uint256(idToAccountInfo[tokenId].expires) >=  block.timestamp) {
            return  idToAccountInfo[tokenId].account;
        }
        else {
            return address(0);
        }
    }

    function userExpires(
        uint256 tokenId
    )
        external
        view
        override
        validNFToken(tokenId)
        returns(uint256)
    {
        return idToAccountInfo[tokenId].expires;
    }

    function lendArtwork(
        uint256 lender,
        uint256 recipient,
        uint256 expires
    )
        external
        override
    {
        _lendArtwork(lender, recipient, expires);
    }

    function _lendArtwork(
        uint256 lender,
        uint256 recipient,
        uint256 expires
    )
        internal
        validNFToken(lender)
        validNFToken(recipient)
        canTransfer(lender)
        isEmptyFrame(recipient)
        isNotEmptyFrame(lender)
        frameIsNotLent(lender)
        artworkIsNotLent(lender)
    {
        FrameInfo storage info = idToFrameInfo[lender];
        info.expires = expires;
        info.frameId = recipient;
    }

    function _transfer(
        address _to,
        uint256 _tokenId
    )
        internal
        override
        frameIsNotLent(_tokenId)
    {
        if (idToArtworkOwner[_tokenId] != address(0)) {
            _emptyFrame(_tokenId, idToArtworkOwner[_tokenId]);
            idToArtworkOwner[_tokenId] = address(0);
        }
        super._transfer(_to, _tokenId);
    }

    function _emptyFrame(
        uint256 frameId,
        address to
    )
        internal
        override
    {
        if (idToArtworkOwner[frameId] == address(0)) {
            super._emptyFrame(frameId, to);
        } else {
            super._emptyFrame(frameId, idToArtworkOwner[frameId]);
            idToArtworkOwner[frameId] = address(0);
        }
    }

    function _getNFTofFrame(
        uint256 frameId
    )
        internal
        override
        view
        returns(ExternalNFT memory)
    {
        if (idToFrameInfo[frameId].expires >= block.timestamp) {
            revert(errors.FRAME_EMPTY);
        }
        for (uint256 i = 0; i < mintedFrames(); i++) {
            if (idToFrameInfo[i].frameId == frameId && idToFrameInfo[i].expires >= block.timestamp) {
                return super._getNFTofFrame(i);
            }
        }
        return super._getNFTofFrame(frameId);
    }

    function _burn(
        uint256 id
    )
        internal
        override
        frameIsNotLent(id)
        artworkIsNotLent(id)
    {
        super._burn(id);
    }

    function _canEmptyFrame(
        uint256 frameId,
        address account
    )
        internal
        override
        returns(bool)
    {
        return
            (
                idToAccountInfo[frameId].expires < block.timestamp &&
                super._canEmptyFrame(frameId, account) &&
                idToFrameInfo[frameId].expires < block.timestamp
            ) ||
            idToArtworkOwner[frameId] == msg.sender;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../interfaces/IRoles.sol";
import "../libraries/Errors.sol";

contract Roles is IRoles {
    mapping (address => bool) private addressToAdmin;

    address public manager;

    constructor() {
        manager = msg.sender;
    }

    modifier isManager(address account) {
        require(account == manager, errors.NOT_AUTHORIZED);
        _;
    }

    modifier isAdmin(address account) {
        require(addressToAdmin[account] || account == manager, errors.NOT_AUTHORIZED);
        _;
    }

    function setAdmin(
        address account
    )
        external
        override
        isManager(msg.sender)
    {
        require(account != address(0), errors.ZERO_ADDRESS);
        addressToAdmin[account] = true;
    }

    function revokeAdmin(
        address account
    )
        external
        override
        isManager(msg.sender)
    {
        addressToAdmin[account] = false;
    }

    function renounceAdmin()
        external
        override
        isAdmin(msg.sender)
    {
        require(msg.sender != manager, errors.INVALID_ADDRESS);
        addressToAdmin[msg.sender] = false;
    }

    function updateManager(
        address account
    )
        external
        override
        isManager(msg.sender)
    {
        require(account != address(0), errors.ZERO_ADDRESS);
        manager = account;
    }

    function isAccountAdmin(
        address account
    )
        external
        view
        returns(bool)
    {
        return addressToAdmin[account];
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../interfaces/IStore.sol";
import "./FrameOwnership.sol";
import "./Lendable.sol";
import "./Roles.sol";
import "../interfaces/IERC20.sol";

contract Store is
    IStore,
    Lendable,
    Roles
{
    mapping(uint256=>uint256) internal modelToStock;
    uint256 internal models;

    address public token;
    mapping(uint256=>uint256) internal modelToPrice;

    mapping(uint256=>uint256) internal idToModel;

    mapping(address=>uint256) internal accountToCheck;

    uint256 public feePercentage = 500;

    mapping(uint256=>uint256) internal idToRefund;

    constructor(address _token, uint256 rentPercentage) {
        models = 0;
        require(_token.code.length > 0, errors.INVALID_ADDRESS);
        token = _token;
        feePercentage = rentPercentage;
    }

    modifier isValidModel(uint256 model) {
        require(model < models, errors.NOT_VALID_MODEL);
        _;
    }

    modifier isInStock(uint256 model, uint256 quantity) {
        require(modelToStock[model] >= quantity, errors.NOT_IN_STOCK);
        _;
    }

    modifier isCheckValid(address account, uint256 check) {
        require(check > accountToCheck[account], errors.CHECK_NOT_VALID);
        _;
    }

    modifier canBeRefund(uint256 frameId, uint256 amount) {
        require(idToRefund[frameId] > 0 && idToRefund[frameId] == amount, errors.NOT_AUTHORIZED);
        _;
    }

    function setStock(
        uint256 newStock,
        uint256 model
    )
        external
        override
        isAdmin(msg.sender)
    {
        _setStock(newStock, model);
    }

    function getStock(
        uint256 model
    )
        external
        override
        view
        isValidModel(model)
        returns(uint256)
    {
        return modelToStock[model];
    }

    function getModels(

    )
        external
        view
        override
        returns(uint256)
    {
        return models;
    }

    function _setStock(
        uint256 newStock,
        uint256 model
    )
        internal
        isValidModel(model)
    {
        modelToStock[model] = newStock;
        if (model > models) {
            models = model;
        }
    }

    function setToken(
        address _token
    )
        external
        override
        isAdmin(msg.sender)
    {
        require(_token.code.length > 0, errors.INVALID_ADDRESS);
        token = _token;
    }

    function setPrice(
        uint256 price,
        uint256 model
    )
        override
        external
        isAdmin(msg.sender)
    {
        _setPrice(price, model);
    }

    function _setPrice(
        uint256 price,
        uint256 model
    )
        private
        isValidModel(model)
    {
        modelToPrice[model] = price;
    }

    function getModel(
        uint256 frameId
    )
        external
        view
        override
        validNFToken(frameId)
        returns(uint256)
    {
        return idToModel[frameId];
    }

    function getPrice(
        uint256 model
    )
        external
        view
        override
        isValidModel(model)
        returns(uint256)
    {
        return modelToPrice[model];
    }

    function putNewModel(
        uint256 price
    )
        external
        override
        isAdmin(msg.sender)
        returns(uint256)
    {
        modelToPrice[models] = price;
        models++;
        return models - 1;
    }

    function buy(
        address receiver,
        uint256 quantity,
        uint256 model
    )
        external
        override
    {
        _payAndMint(receiver, modelToPrice[model] * quantity, quantity, model);
    }

    function buy(
        address receiver,
        uint256 price,
        uint256 quantity,
        uint256 model,
        address signer,
        uint256 check,
        bytes calldata signature
    )
        external
        override
        isCheckValid(msg.sender, check)
        isAdmin(signer)
    {
        require(_isSignatureAuthentic(msg.sender, price, model, quantity, signer, signature), errors.INVALID_SIGNATURE);
        _payAndMint(receiver, price, quantity, model);
        accountToCheck[msg.sender]++;
    }

    function _isSignatureAuthentic(
        address account,
        uint256 price,
        uint256 model,
        uint256 quantity,
        address signer,
        bytes calldata signature
    )
        private
        view
        returns(bool)
    {
        bytes32 ethSignedMessageHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", _getMessageHash(account, price, model, quantity, this.getAccountCheck(account)))
        );
        (bytes32 r, bytes32 s, uint8 v) = _splitSignature(signature);
        address detectedSigner = ecrecover(ethSignedMessageHash, v, r, s);
        return detectedSigner == signer;
    }

    function _payAndMint(
        address receiver,
        uint256 price,
        uint256 quantity,
        uint256 model
    )
        private
        isValidModel(model)
        notNullAddress(receiver)
        isInStock(model, quantity)
    {
        IERC20(token).transferFrom(msg.sender, address(this), price);
        _mintBatch(receiver, model, quantity);
    }

    function _mintBatch(
        address receiver,
        uint256 model,
        uint256 quantity
    )
        private
    {
        for (uint256 i = 0; i < quantity; i++) {
            idToModel[mintedFrames()] = model;
            _mint(receiver, mintedFrames());
        }
        modelToStock[model] -= quantity;
    }

    function _getMessageHash(
        address account,
        uint256 price,
        uint256 model,
        uint256 quantity,
        uint256 check
    )
        private
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(account, price, model, quantity, check));
    }

    function _splitSignature(
        bytes memory sig
    )
        private
        pure
        returns (bytes32 r, bytes32 s, uint8 v)
    {
        require(sig.length == 65, errors.INVALID_SIGNATURE);

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }

     function getAccountCheck(
        address account
    )
        external
        view
        override
        notNullAddress(account)
        returns(uint256)
    {
        return accountToCheck[account] + 1;
    }

    function gift(
        address receiver,
        uint256 quantity,
        uint256 model
    )
        external
        isAdmin(msg.sender)
        notNullAddress(receiver)
        isInStock(model, quantity)
    {
        _mintBatch(receiver, model, quantity);
    }

    function setFeePercentage(
        uint256 newFeePercentage
    )
        external
        isAdmin(msg.sender)
    {
        feePercentage = newFeePercentage;
    }

    function lendFrameWithMoney(
        uint256 frameId,
        uint256 price,
        address _token,
        address receiver,
        uint64 expires,
        bool canUpdate
    )
        external
        override
        validNFToken(frameId)
    {
        _payWithFee(_token, price, receiver);
        _rent(frameId, receiver, expires, canUpdate);
    }
    function lendArtworkWithMoney(
        uint256 frameId,
        uint256 price,
        address _token,
        uint256 receiver,
        uint256 expires
    )
        external
        override
    {
        _payWithFee(_token, price, msg.sender);
        _lendArtwork(frameId, receiver, expires);
    }

    function _payWithFee(
        address _token,
        uint256 price,
        address receiver
    )
        private
    {
        uint256 feeToPay = price / 10000 * feePercentage;
        IERC20(_token).transferFrom(receiver, address(this), price);
        IERC20(_token).transfer(msg.sender, price - feeToPay);
    }

    function _rent(
        uint256 tokenId,
        address user,
        uint64 expires,
        bool canUpdate
    )
        private
    {
        if (canUpdate) {
            _setUserWithUploads(tokenId, user, expires);
        } else {
            _setUser(tokenId, user, expires);
        }
    }

    function burnAndRefund(
        uint256 frameId,
        uint256 amount
    )
        external
        override
        isAdmin(msg.sender)
        canBeRefund(frameId, amount)
    {
        IERC20(token).transfer(_ownerOf(frameId), idToRefund[frameId]);
        _burn(frameId);
    }

    function askForRefund(
        uint256 frameId,
        uint256 value
    )
        external
        override
        canTransfer(frameId)
    {
        idToRefund[frameId] = value;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Lendable.sol";
import "../interfaces/ITokenReceiver.sol";
import "../libraries/Constants.sol";

contract TokenReceiver is
    ITokenReceiver,
    Lendable
{

    modifier isSingleNFT(uint256 amount) {
        require(amount == 1, errors.NOT_SINGLE_NFT);
        _;
    }

    modifier canReceiveNFT(address _operator, uint256 _tokenId) {
        address tokenOwner = idToOwner[_tokenId];
        require(
            (uint256(idToAccountInfo[_tokenId].expires) < block.timestamp &&
                (
                    tokenOwner == _operator ||
                    ownerToOperators[tokenOwner][_operator]
                )
            )
            ||
            (
                uint256(idToAccountInfo[_tokenId].expires) >=  block.timestamp && idToAccountInfo[_tokenId].account == _operator
            ),
            errors.NOT_OWNER_OR_OPERATOR
        );
        _;
    }

    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes calldata _data
    )
        external
        override
        validNFToken(_bytesToInteger(_data))
        userCanUpdateFrame(_bytesToInteger(_data), _from)
        canReceiveNFT(_operator, _bytesToInteger(_data))
        returns(bytes4)
    {
        _onNFTReceived(_tokenId, _data, _from);
        return constants.MAGIC_ON_ERC721_RECEIVED;
    }

    function onERC1155Received(
        address _operator,
        address _from,
        uint256 _id,
        uint256 _value,
        bytes calldata _data
    )
        external
        override
        validNFToken(_bytesToInteger(_data))
        canReceiveNFT(_operator, _bytesToInteger(_data))
        userCanUpdateFrame(_bytesToInteger(_data), _from)
        isSingleNFT(_value)
        returns (bytes4)
    {
        _onNFTReceived(_id, _data, _from);
        return constants.MAGIC_ON_ERC1155_RECEIVED;
    }

    function _onNFTReceived(
        uint256 _tokenId,
        bytes memory _data,
        address from
    )
        private
    {
        uint256 frameId = _bytesToInteger(_data);

        if (idToExternalNFT[frameId].contractAddress != address(0)) {
            _emptyFrame(frameId, from);
        }

        if (idToAccountInfo[frameId].expires >= block.timestamp) {
            idToArtworkOwner[frameId] = idToAccountInfo[frameId].account;
        }

        idToExternalNFT[frameId] = ExternalNFT(msg.sender, _tokenId);
        emit NFTReceived(frameId, idToOwner[frameId], msg.sender, _tokenId);
    }

    function _bytesToInteger(
        bytes memory message
    )
        public
        pure
        returns(uint256)
    {
        require(message.length > 0, errors.FRAME_ID_MISSING);
        uint256 converted;
        for (uint i = 0; i < message.length; i++){
            converted = converted + uint8(message[i])*(2**(8*(message.length-(i+1))));
        }
        return converted;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../interfaces/IWithdraw.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/IERC721.sol";
import "../interfaces/IERC1155.sol";
import "./Store.sol";
import "./Roles.sol";

contract Withdraw is
    IWithdraw,
    Lendable,
    Roles
{
    modifier isNotAssignedNft(uint256 id, address nftContract) {
        for (uint256 i = 0; i < mintedFrames(); i++) {
            if (idToExternalNFT[id].contractAddress == nftContract && idToExternalNFT[id].id == id) {
                revert();
            }
        }
        _;
    }

    function withdrawERC20(
        address token,
        address to,
        uint256 amount
    )
        external
        override
        isManager(msg.sender)
    {
        require(to != address(0), errors.ZERO_ADDRESS);
        IERC20(token).transfer(to, amount);
    }

    function withdrawERC721(
        address to,
        address token,
        uint256 id
    )
        external
        override
        isManager(msg.sender)
        isNotAssignedNft(id, token)
    {
        require(to != address(0), errors.ZERO_ADDRESS);
        IERC721(token).safeTransferFrom(address(this), to, id);
    }

    function withdrawERC1155(
        address to,
        address token,
        uint256 id,
        uint256 amount
    )
        external
        override
        isManager(msg.sender)
        isNotAssignedNft(id, token)
    {
        require(to != address(0), errors.ZERO_ADDRESS);
        IERC1155(token).safeTransferFrom(address(this), to, id, amount, "0x00");
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IERC1155 {
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;
    function balanceOf(address _owner, uint256 _id) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IERC1155TokenReceiver {
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev A standard for detecting smart contract interfaces.
 * See: https://eips.ethereum.org/EIPS/eip-165.
 */
interface IERC165 {

    /**
        @dev Checks if the smart contract includes a specific interface. This function uses less than 30,000 gas.
        @param _interfaceID The interface identifier, as specified in ERC-165.
        @return True if _interfaceID is supported, false otherwise.
    */
    function supportsInterface(bytes4 _interfaceID) external view returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address _to, uint256 _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IERC2981 {
    struct RoyaltyInfo {
        address receiver;
        uint96 royaltyFraction;
    }

    /**
        @notice Called with the sale price to determine how much royalty is owed and to whom.
        @param _tokenId - the NFT asset queried for royalty information
        @param _salePrice - the sale price of the NFT asset specified by _tokenId
        @return receiver - address of who should be sent the royalty payment
        @return royaltyAmount - the royalty payment amount for _salePrice
    */
    function royaltyInfo(
        uint256 _tokenId,
        uint256 _salePrice
    ) external view returns (
        address receiver,
        uint256 royaltyAmount
    );

    function setRoyaltyInfo(
        uint256 _tokenId,
        uint256 _salePrice
    ) external view returns (
        address receiver,
        uint256 royaltyAmount
    );

    function updateRoyaltyPercentage(uint256 percentage) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IERC4907 {
    struct AccountInfo {
        address account;
        uint256 expires;
    }

    struct FrameInfo {
        uint256 frameId;
        uint256 expires;
    }

    event UpdateUser(uint256 indexed tokenId, address indexed user, uint64 expires);

    /**
        @notice Set the user and expires of an NFT. The user cannot upload or clear the frame. The owner cannot either.
        @dev The zero address indicates there is no user throws if `tokenId` is not valid NFT
        @param user  The new user of the NFT
        @param expires  UNIX timestamp, The new user could use the NFT before expires
    */
    function setUser(uint256 tokenId, address user, uint64 expires) external;

    /**
        @notice Get the user address of an NFT
        @dev The zero address indicates that there is no user or the user is expired
        @param tokenId The NFT to get the user address for
        @return The user address for this NFT
    */
    function userOf(uint256 tokenId) external view returns(address);

    /**
        @notice Get the user expires of an NFT
        @dev The zero value indicates that there is no user
        @param tokenId The NFT to get the user expires for
        @return The user expires for this NFT
    */
    function userExpires(uint256 tokenId) external view returns(uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC721 {

    /**
        @dev Emits when ownership of any NFT changes by any mechanism. This event emits when NFTs are created (`from` == 0) and destroyed (`to` == 0). Exception: during contract creation, any number of NFTs may be created and assigned without emitting Transfer. At the time of any transfer, the approved address for that NFT (if any) is reset to none.
   */
    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 indexed _tokenId
    );

    /**
        @dev This emits when the approved address for an NFT is changed or reaffirmed. The zero address indicates there is no approved address. When a Transfer event emits, this also indicates that the approved address for that NFT (if any) is reset to none.
    */
    event Approval(
        address indexed _owner,
        address indexed _approved,
        uint256 indexed _tokenId
    );

    /**
        @dev This emits when an operator is enabled or disabled for an owner. The operator can manage all NFTs of the owner.
    */
    event ApprovalForAll(
        address indexed _owner,
        address indexed _operator,
        bool _approved
    );

    /**
        @notice Throws unless `msg.sender` is the current owner, an authorized operator, or the approved address for this NFT. Throws if `_from` is not the current owner. Throws if `_to` is the zero address. Throws if `_tokenId` is not a valid NFT. When transfer is complete, this function checks if `_to` is a smart contract (code size > 0). If so, it calls `onERC721Received` on `_to` and throws if the return value is not `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`.
        @dev Transfers the ownership of an NFT from one address to another address. This function can be changed to payable.
        @param _from The current owner of the NFT.
        @param _to The new owner.
        @param _tokenId The NFT to transfer.
        @param _data Additional data with no specified format, sent in call to `_to`.
   */
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes calldata _data
    )
    external;

    /**
        @notice This works identically to the other function with an extra data parameter, except this function just sets data to ""
        @dev Transfers the ownership of an NFT from one address to another address. This function can be changed to payable.
        @param _from The current owner of the NFT.
        @param _to The new owner.
        @param _tokenId The NFT to transfer.
   */
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    )
    external;

    /**
        @notice The caller is responsible to confirm that `_to` is capable of receiving NFTs or else they may be permanently lost.
        @dev Throws unless `msg.sender` is the current owner, an authorized operator, or the approved address for this NFT. Throws if `_from` is not the current owner. Throws if `_to` is the zero address. Throws if `_tokenId` is not a valid NFT.  This function can be changed to payable.
        @param _from The current owner of the NFT.
        @param _to The new owner.
        @param _tokenId The NFT to transfer.
   */
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    )
    external;

    /**
        @notice The zero address indicates there is no approved address. Throws unless `msg.sender` is the current NFT owner, or an authorized operator of the current owner.
        @param _approved The new approved NFT controller.
        @dev Set or reaffirm the approved address for an NFT. This function can be changed to payable.
        @param _tokenId The NFT to approve.
   */
    function approve(
        address _approved,
        uint256 _tokenId
    )
    external;

    /**
        @notice The contract MUST allow multiple operators per owner.
        @dev Enables or disables approval for a third party ("operator") to manage all of `msg.sender`'s assets. It also emits the ApprovalForAll event.
        @param _operator Address to add to the set of authorized operators.
        @param _approved True if the operators is approved, false to revoke approval.
   */
    function setApprovalForAll(
        address _operator,
        bool _approved
    )
    external;

    /**
        @dev Returns the number of NFTs owned by `_owner`. NFTs assigned to the zero address are considered invalid, and this function throws for queries about the zero address.
        @notice Count all NFTs assigned to an owner.
        @param _owner Address for whom to query the balance.
        @return Balance of _owner.
   */
    function balanceOf(
        address _owner
    )
    external
    view
    returns (uint256);

    /**
        @notice Find the owner of an NFT.
        @dev Returns the address of the owner of the NFT. NFTs assigned to the zero address are considered invalid, and queries about them do throw.
        @param _tokenId The identifier for an NFT.
        @return Address of _tokenId owner.
   */
    function ownerOf(
        uint256 _tokenId
    )
    external
    view
    returns (address);

    /**
        @notice Throws if `_tokenId` is not a valid NFT.
        @dev Get the approved address for a single NFT.
        @param _tokenId The NFT to find the approved address for.
        @return Address that _tokenId is approved for.
   */
    function getApproved(
        uint256 _tokenId
    )
    external
    view
    returns (address);

    /**
        @notice Query if an address is an authorized operator for another address.
        @dev Returns true if `_operator` is an approved operator for `_owner`, false otherwise.
        @param _owner The address that owns the NFTs.
        @param _operator The address that acts on behalf of the owner.
        @return True if approved for all, false otherwise.
   */
    function isApprovedForAll(
        address _owner,
        address _operator
    )
    external
    view
    returns (bool);

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IERC721Enumerable {
    /**
        @dev Returns a count of valid NFTs tracked by this contract, where each one of them has an assigned and queryable owner not equal to the zero address.
        @return Total supply of NFTs.
    */
    function totalSupply()
    external
    view
    returns (uint256);

    /**
        @dev Returns the token identifier for the `_index`th NFT. Sort order is not specified.
        @param _index A counter less than `totalSupply()`.
        @return Token id.
    */
    function tokenByIndex(
        uint256 _index
    )
    external
    view
    returns (uint256);

    /**
        @dev Returns the token identifier for the `_index`th NFT assigned to `_owner`. Sort order is not specified. It throws if `_index` >= `balanceOf(_owner)` or if `_owner` is the zero address, representing invalid NFTs.
        @param _owner An address where we are interested in NFTs owned by them.
        @param _index A counter less than `balanceOf(_owner)`.
        @return Token id.
    */
    function tokenOfOwnerByIndex(
        address _owner,
        uint256 _index
    )
    external
    view
    returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IERC721Metadata {
    /**
        @dev Returns a descriptive name for a collection of NFTs in this contract.
        @return _name Representing name.
    */
    function name()
    external
    view
    returns (string memory _name);

    /**
        @dev Returns a abbreviated name for a collection of NFTs in this contract.
        @return _symbol Representing symbol.
    */
    function symbol()
    external
    view
    returns (string memory _symbol);

    /**
        @dev Returns a distinct Uniform Resource Identifier (URI) for a given asset. It Throws if `_tokenId` is not a valid NFT. URIs are defined in RFC3986. The URI may point to a JSON file that conforms to the "ERC721 Metadata JSON Schema".
        @return URI of _tokenId.
    */
    function tokenURI(uint256 _tokenId)
    external
    view
    returns (string memory);

    function updateBaseUrl(string memory _newBaseUrl)
    external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface IERC721TokenReceiver {

    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes calldata _data
    )
    external
    returns(bytes4);

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IFrameOwnership {
    struct ExternalNFT {
        address contractAddress;
        uint256 id;
    }

    /**
        @dev Returns the NFT owned by a frame. The frame id has to be valid and the frame not empty, otherwise an error is thrown.
        @param frameId The id the of frame.
        @return NFT owned by frame with id "frameId" as an ExternalNFT struct.
    */
    function getNFTofFrame(uint256 frameId) external view returns(ExternalNFT memory);

    /**
        @dev Transfer the NFT owned by a frame to the frame owner. If the sender is not the owner or operator of the frame, the frame is already empty, "to" address is null, or the id is not a valid frame.
        @param frameId The id the of frame.
        @param to The address which will receive the NFT.
    */
    function emptyFrame(address to, uint256 frameId) external;

    event EmptyFrame(uint256 frameId, address owner);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./IERC4907.sol";

interface ILendable is IERC4907 {
    function setUserWithUploads(
        uint256 tokenId,
        address user,
        uint64 expires
    ) external;

    function claimArtwork(
        address to,
        uint256 frameId
    ) external;

    function claimFrame(
        uint256 frameId
    ) external;

    function lendArtwork(
        uint256 lenderId,
        uint256 recipient,
        uint256 expires
    ) external;

    function canBeUpdated(
        uint256 frameId
    )
    view
    external
    returns(bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IRoles {

    function setAdmin(address account) external;
    function revokeAdmin(address account) external;
    function renounceAdmin() external;
    function updateManager(address account) external;
    function isAccountAdmin(address account) external view returns(bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IStore {
    function setStock(uint256 newStock, uint256 model) external;
    function getStock(uint256 model) external view returns(uint256);
    function getModels() external view returns(uint256);

    function setToken(address token) external;
    function setPrice(uint256 price, uint256 model) external;
    function getModel(uint256 frameId) external view returns(uint256);
    function getPrice(uint256 model) external view returns(uint256);

    function putNewModel(uint256 price) external returns(uint256);

    function buy(address receiver, uint256 quantity, uint256 model) external;
    function buy(address receiver, uint256 price, uint256 quantity, uint256 model, address signer, uint256 check, bytes calldata signature) external;
    function getAccountCheck(address account) external view returns(uint256);

    function gift(address receiver, uint256 quantity, uint256 model) external;

    function setFeePercentage(uint256 newFeePercentage) external;

    function lendFrameWithMoney(
        uint256 frameId,
        uint256 price,
        address token,
        address receiver,
        uint64 expires,
        bool canUpdate
    ) external;
    function lendArtworkWithMoney(
        uint256 frameId,
        uint256 price,
        address _token,
        uint256 receiver,
        uint256 expires
    ) external;

    function burnAndRefund(uint256 frameId, uint256 amount) external;
    function askForRefund(uint256 frameId, uint256 value) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./IERC721TokenReceiver.sol";
import "./IERC1155TokenReceiver.sol";

interface ITokenReceiver is
    IERC721TokenReceiver,
    IERC1155TokenReceiver
{
    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes calldata _data
    )
    external
    returns(bytes4);

    function onERC1155Received(
        address _operator,
        address _from,
        uint256 _id,
        uint256 _value,
        bytes calldata _data
    )
    external
    returns (bytes4);

    event NFTReceived(uint256 frameId, address owner, address nftAddress, uint256 nftId);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IWithdraw {

    function withdrawERC20(address token, address to, uint256 amount) external;
    function withdrawERC721(address to, address token, uint256 id) external;
    function withdrawERC1155(address to, address token, uint256 id, uint256 amount) external;

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
    @notice Based on: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol Requires EIP-1052.
    @dev Utility library of inline functions on addresses.
 */
library AddressUtils
{

    /**
        @dev Returns whether the target address is a contract.
        @param _addr Address to check.
        @return addressCheck True if _addr is a contract, false if not.
    */
    function isContract(
        address _addr
    )
        internal
        view
        returns (bool addressCheck)
    {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly { codehash := extcodehash(_addr) } // solhint-disable-line
        addressCheck = (codehash != 0x0 && codehash != accountHash);
    }

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

library constants {
    bytes4 public constant MAGIC_ON_ERC721_RECEIVED = 0x150b7a02;
    bytes4 internal constant MAGIC_ON_ERC1155_RECEIVED = 0xf23a6e61;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

library errors {
    string constant public NOT_AUTHORIZED = "001001";
    string constant public INVALID_ADDRESS = "001003";

    string constant public NOT_SINGLE_NFT = "002001";
    string constant public FRAME_ID_MISSING = "002002";

    string constant public ZERO_ADDRESS = "003001";
    string constant public NOT_VALID_NFT = "003002";
    string constant public NOT_OWNER_OR_OPERATOR = "003003";
    string constant public NOT_OWNER_APPROVED_OR_OPERATOR = "003004";
    string constant public NOT_ABLE_TO_RECEIVE_NFT = "003005";
    string constant public NFT_ALREADY_EXISTS = "003006";
    string constant public NOT_OWNER = "003007";
    string constant public IS_OWNER = "003008";

    string constant public FRAME_NOT_EMPTY = "004001";
    string constant public FRAME_EMPTY = "004002";

    string constant public NOT_VALID_MODEL = "005001";
    string constant public NOT_IN_STOCK = "005002";
    string constant public CHECK_NOT_VALID = "005003";
    string constant public INVALID_SIGNATURE = "005004";
}