pragma solidity >=0.8.4;

interface IReverseRegistrar {
    function setDefaultResolver(address resolver) external;

    function claim(address owner) external returns (bytes32);

    function claimForAddr(
        address addr,
        address owner,
        address resolver
    ) external returns (bytes32);

    function claimWithResolver(
        address owner,
        address resolver
    ) external returns (bytes32);

    function setName(string memory name) external returns (bytes32);

    function setNameForAddr(
        address addr,
        address owner,
        address resolver,
        string memory name
    ) external returns (bytes32);

    function node(address addr) external pure returns (bytes32);
}

// SPDX-License-Identifier: MIT

import "@ens/registry/IReverseRegistrar.sol";

pragma solidity ^0.8.16;

abstract contract PrimaryEns {
    IReverseRegistrar public immutable REVERSE_REGISTRAR;

    address private deployer;

    constructor() {
        deployer = msg.sender;
        REVERSE_REGISTRAR = IReverseRegistrar(
            0x084b1c3C81545d370f3634392De611CaaBFf8148
        );
    }

    /*
     * @description Set the primary name of the contract
     * @param _ens The ENS that is set to the contract address. Must be full name
     * including the .eth. Can also be a subdomain.
     */
    function setPrimaryName(string calldata _ens) public {
        require(msg.sender == deployer, "only deployer");
        REVERSE_REGISTRAR.setName(_ens);
    }
}

pragma solidity >=0.8.4;

interface ENS {
    // Logged when the owner of a node assigns a new owner to a subnode.
    event NewOwner(bytes32 indexed node, bytes32 indexed label, address owner);

    // Logged when the owner of a node transfers ownership to a new account.
    event Transfer(bytes32 indexed node, address owner);

    // Logged when the resolver for a node changes.
    event NewResolver(bytes32 indexed node, address resolver);

    // Logged when the TTL of a node changes
    event NewTTL(bytes32 indexed node, uint64 ttl);

    // Logged when an operator is added or removed.
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    function setRecord(
        bytes32 node,
        address owner,
        address resolver,
        uint64 ttl
    ) external;

    function setSubnodeRecord(
        bytes32 node,
        bytes32 label,
        address owner,
        address resolver,
        uint64 ttl
    ) external;

    function setSubnodeOwner(
        bytes32 node,
        bytes32 label,
        address owner
    ) external returns (bytes32);

    function setResolver(bytes32 node, address resolver) external;

    function setOwner(bytes32 node, address owner) external;

    function setTTL(bytes32 node, uint64 ttl) external;

    function setApprovalForAll(address operator, bool approved) external;

    function owner(bytes32 node) external view returns (address);

    function resolver(bytes32 node) external view returns (address);

    function ttl(bytes32 node) external view returns (uint64);

    function recordExists(bytes32 node) external view returns (bool);

    function isApprovedForAll(
        address owner,
        address operator
    ) external view returns (bool);
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
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
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
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
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
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
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
            return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
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

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./IRegister.sol";

interface IManager {
    function IdToLabelMap(
        uint256 _tokenId
    ) external view returns (string memory label);

    function IdToOwnerId(
        uint256 _tokenId
    ) external view returns (uint256 ownerId);

    function IdToDomain(
        uint256 _tokenId
    ) external view returns (string memory domain);

    function TokenLocked(uint256 _tokenId) external view returns (bool locked);

    function IdImageMap(
        uint256 _tokenId
    ) external view returns (string memory image);

    function IdToHashMap(
        uint256 _tokenId
    ) external view returns (bytes32 _hash);

    function text(
        bytes32 node,
        string calldata key
    ) external view returns (string memory _value);

    function DefaultMintPrice(
        uint256 _tokenId
    ) external view returns (uint256 _priceInWei);

    function transferDomainOwnership(uint256 _id, address _newOwner) external;

    function TokenOwnerMap(uint256 _id) external view returns (address);

    function registerSubdomain(
        uint256 _id,
        string calldata _label,
        bytes32[] calldata _proofs
    ) external payable;

    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external;

    function updateRegistrationStrategy(
        uint256[] calldata _ids,
        IRegister _registrationStrategy
    ) external;
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IMetadata {
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IRegister {
    function canRegister(
        uint256 _tokenId,
        string memory _label,
        address _addr,
        uint256 _priceInWei,
        bytes32[] calldata _proofs
    ) external returns (bool);

    function mintPrice(
        uint256 _tokenId,
        string calldata _label,
        address _addr,
        bytes32[] calldata _proofs
    ) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./IRegister.sol";
import "./IManager.sol";
import "./IMetadata.sol";
import "lib/EnsPrimaryContractNamer/src/PrimaryEns.sol";
import "ens-contracts/registry/ENS.sol";
import "openzeppelin-contracts/token/ERC721/IERC721Receiver.sol";
import "openzeppelin-contracts/utils/Strings.sol";

struct SubscriptionDetails {
    uint256[] prices;
    uint256[] daylengths;
}

interface IENSToken {
    function nameExpires(uint256 id) external view returns (uint256);

    function reclaim(uint256 id, address addr) external;

    function setResolver(address _resolverAddress) external;

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

contract SubscriptionRegistrationRules is
    IMetadata,
    IRegister,
    PrimaryEns,
    IERC721Receiver
{
    IManager public immutable domainManager;
    uint256 public constant COMMISSION = 2;

    mapping(uint256 => SubscriptionDetails) internal mintPrices;
    mapping(uint256 => uint256) public maxTokens;
    mapping(bytes32 => uint256) public expires;
    mapping(address => uint256) public renewalsBalance;
    mapping(uint256 => string) public descriptions;
    mapping(uint256 => uint256) public mintCount;

    address private tokenOwner;

    bytes4 constant ERC721_SELECTOR = this.onERC721Received.selector;

    event UpdateSubscriptionDetails(
        uint256 indexed _tokenId,
        SubscriptionDetails _details
    );
    event UpdateMaxMint(uint256 indexed _tokenId, uint256 _maxMint);
    event UpdateDescription(uint256 indexed _tokenId, string _description);
    event RenewDomain(
        bytes32 indexed _subdomain,
        address _owner,
        uint256 _expires
    );

    using Strings for uint256;

    IManager public Manager;
    ENS private constant ens = ENS(0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e);
    IENSToken public constant ensToken =
        IENSToken(0x57f1887a8BF19b14fC0dF6Fd9B2acc9Af147eA85);
    string public constant DefaultImage =
        "ipfs://QmYWSU93qnqDvAwHGEpJbEEghGa7w7RbsYo9mYYroQnr1D";

    constructor(address _esf) {
        domainManager = IManager(_esf);
    }

    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes calldata _data
    ) public returns (bytes4) {
        domainManager.transferFrom(address(this), tokenOwner, _tokenId);
        return ERC721_SELECTOR;
    }

    function canRegister(
        uint256 _tokenId,
        string calldata _label,
        address _addr,
        uint256 _priceInWei,
        bytes32[] calldata _proofs
    ) public view returns (bool) {
        require(_addr == address(this), "incorrect minting address");
        return true;
    }

    function registerSubdomain(
        uint256 _id,
        string calldata _label,
        bytes32[] calldata _proofs,
        address _mintTo
    ) external payable {
        //only do price and whitelist checks for none owner addresses
        require(_proofs.length == 1, "expiry in proof");

        uint256 duration = uint256(_proofs[0]);
        uint256 currentMint = mintCount[_id];
        if (msg.sender != domainManager.TokenOwnerMap(_id)) {
            require(
                domainManager.DefaultMintPrice(_id) != 0,
                "not for primary sale"
            );

            require(
                currentMint < maxTokens[_id],
                "max mint reached for this token"
            );

            require(
                msg.value >= mintPrice(_id, _label, msg.sender, _proofs),
                "incorrect price"
            );
        }

        unchecked {
            mintCount[_id] = currentMint + 1;
        }

        tokenOwner = _mintTo;
        domainManager.registerSubdomain{value: msg.value}(_id, _label, _proofs);
        delete tokenOwner;

        bytes32 subdomain = subdomainHash(_id, _label);
        uint256 newExpires = getExpiry(subdomain, duration);
        expires[subdomain] = newExpires;

        emit RenewDomain(subdomain, _mintTo, newExpires);
    }

    function ownerBulkMint(
        uint256 _tokenId,
        address[] calldata _addr,
        string[] calldata _labels,
        uint256[] calldata _durations
    ) public payable isTokenOwner(_tokenId) {
        require(
            _addr.length == _labels.length,
            "arrays need to be same length"
        );

        bytes32[] memory duration = new bytes32[](1);

        uint256 count = _addr.length;

        for (uint256 i; i < count; ) {
            require(_addr[i] != address(0), "cannot mint to zero address");
            tokenOwner = _addr[i];
            duration[0] = bytes32(_durations[i]);

            domainManager.registerSubdomain{value: msg.value}(
                _tokenId,
                _labels[i],
                duration
            );
            {
                bytes32 subdomain = subdomainHash(_tokenId, _labels[i]);
                uint256 expiry = block.timestamp + _durations[i];
                expires[subdomain] = expiry;

                emit RenewDomain(subdomain, _addr[i], expiry);
            }
            unchecked {
                ++i;
            }
        }

        unchecked {
            mintCount[_tokenId] += count;
        }

        delete tokenOwner;
    }

    function updateSubscriptionDetails(
        uint256 _tokenId,
        SubscriptionDetails calldata _details
    ) public isTokenOwner(_tokenId) {
        require(
            _details.prices.length == _details.daylengths.length,
            "arrays need to be same length"
        );
        require(_details.prices.length > 0, "need at least one price");
        mintPrices[_tokenId] = _details;
    }

    function updateMaxMint(
        uint256 _tokenId,
        uint256 _maxMint
    ) public isTokenOwner(_tokenId) {
        maxTokens[_tokenId] = _maxMint;

        emit UpdateMaxMint(_tokenId, _maxMint);
    }

    function updateMaxMintAndSubscription(
        uint256 _tokenId,
        uint256 _maxMint,
        SubscriptionDetails calldata _details
    ) public isTokenOwner(_tokenId) {
        require(
            _details.prices.length == _details.daylengths.length,
            "arrays need to be same length"
        );
        require(_details.prices.length > 0, "need at least one price");
        mintPrices[_tokenId] = _details;
        maxTokens[_tokenId] = _maxMint;

        emit UpdateMaxMint(_tokenId, _maxMint);
    }

    function updateMaxMintDescriptionAndSubscription(
        uint256 _tokenId,
        uint256 _maxMint,
        string calldata _description,
        SubscriptionDetails calldata _details
    ) public isTokenOwner(_tokenId) {
        require(
            _details.prices.length == _details.daylengths.length,
            "arrays need to be same length"
        );
        require(_details.prices.length > 0, "need at least one price");
        mintPrices[_tokenId] = _details;
        maxTokens[_tokenId] = _maxMint;
        descriptions[_tokenId] = _description;

        emit UpdateMaxMint(_tokenId, _maxMint);
        emit UpdateDescription(_tokenId, _description);
    }

    function updateDescriptionA(
        uint256 _tokenId,
        string calldata _description
    ) public isTokenOwner(_tokenId) {
        descriptions[_tokenId] = _description;
        emit UpdateDescription(_tokenId, _description);
    }

    function renewDomain(
        uint256 _tokenId,
        string calldata _label,
        bytes32[] calldata _duration
    ) public payable {
        bytes32 node = subdomainHash(_tokenId, _label);
        require(expires[node] > 0, "domain not registered");
        require(_duration.length == 1, "duration must be 1");
        require(_duration[0] > 0, "duration must be greater than 0");

        // token owner can extend any of their subdomain tokens for free

        address owner = domainManager.TokenOwnerMap(_tokenId);
        if (owner == msg.sender) {
            expires[node] = (block.timestamp + uint256(_duration[0]) * 1 days);

        } else {

            uint256 price = mintPrice(_tokenId, _label, msg.sender, _duration);

            require(msg.value >= price, "incorrect price");
            uint256 currentExpiry;
            if (expires[node] < block.timestamp) {
                currentExpiry = block.timestamp;
            } else {
                currentExpiry = expires[node];
            }

            expires[node] = currentExpiry + (uint256(_duration[0]) * 1 days);

            uint256 commission = msg.value / 50;

            renewalsBalance[owner] = renewalsBalance[owner] + msg.value - commission;
            payable(address(domainManager)).call{value: commission}("");

        }


        emit RenewDomain(node, msg.sender, expires[node]);
    }

    function withdrawRenewals() public {
        uint256 balance = renewalsBalance[msg.sender];
        require(balance > 0, "no balance");

        renewalsBalance[msg.sender] = 0;
        payable(msg.sender).transfer(balance);
    }

    function mintPrice(
        uint256 _tokenId,
        string calldata _label,
        address _addr,
        bytes32[] calldata _proofs
    ) public view returns (uint256) {
        require(
            _proofs.length > 0,
            "require registration length in first value of proofs"
        );

        if (_addr == domainManager.TokenOwnerMap(_tokenId)) {
            return 0;
        } else {
            uint256 registrationLength = uint256(_proofs[0]);
            SubscriptionDetails memory dets = mintPrices[_tokenId];

            uint256 previousPrice;
            require(
                registrationLength >= dets.daylengths[0] &&
                    registrationLength <= 365,
                "registration length too short"
            );
            for (uint256 i; i < dets.prices.length; ) {
                if (registrationLength < dets.daylengths[i]) {
                    return previousPrice * registrationLength;
                }

                previousPrice = dets.prices[i];

                unchecked {
                    ++i;
                }
            }
            return previousPrice * registrationLength;
        }
    }

    function getExpiry(
        bytes32 subdomain,
        uint256 _duration
    ) public view returns (uint256) {
        uint256 currentExpiry = expires[subdomain];

        if (currentExpiry < block.timestamp) {
            currentExpiry = block.timestamp;
        }

        return currentExpiry + (_duration * 1 days);
    }

    function tokenURI(uint256 tokenId) external view returns (string memory) {
        string memory label = domainManager.IdToLabelMap(tokenId);

        uint256 ownerId = domainManager.IdToOwnerId(tokenId);
        string memory parentName = domainManager.IdToDomain(ownerId);
        string memory ensName = string(
            abi.encodePacked(label, ".", parentName, ".eth")
        );
        string memory locked = (ensToken.ownerOf(ownerId) ==
            address(domainManager)) && (domainManager.TokenLocked(ownerId))
            ? "True"
            : "False";
        string memory image = domainManager.IdImageMap(ownerId);

        bytes32 hashed = domainManager.IdToHashMap(tokenId);

        string memory active;

        {
            address resolver = ens.resolver(hashed);
            active = resolver == address(domainManager) ? "True" : "False";
        }

        uint256 expiry = ensToken.nameExpires(ownerId);

        uint256 subExpires = expires[subdomainHash(ownerId, label)];

        string memory subActive = subExpires > block.timestamp
            ? "True"
            : "False";

        string memory description = descriptions[tokenId];

        bytes memory data = abi.encodePacked(
            'data:application/json;utf8,{"name": "',
            ensName,
            '","description": "Transferable ',
            parentName,
            ".eth sub-domain. ",
            description,
            '","image":"',
            (bytes(image).length == 0 ? DefaultImage : image),
            '","attributes":[{"trait_type" : "parent name", "value" : "',
            parentName
        );

        return
            string(
                abi.encodePacked(
                    data,
                    '.eth"},{"trait_type" : "parent locked", "value" : "',
                    locked,
                    '"},{"trait_type" : "ens active", "value" : "',
                    active,
                    '"},{"trait_type" : "subscription active", "value" : "',
                    active,
                    '" },{"trait_type" : "subscription expiry", "display_type": "date","value": "',
                    subExpires.toString(),
                    '" },{"trait_type" : "parent expiry", "display_type": "date","value": ',
                    expiry.toString(),
                    "}]}"
                )
            );
    }

    function subdomainHash(
        uint256 _parent,
        string memory _label
    ) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(_parent, keccak256(bytes(_label))));
    }

    modifier isTokenOwner(uint256 _tokenId) {
        require(
            domainManager.TokenOwnerMap(_tokenId) == msg.sender,
            "not authorised"
        );
        _;
    }
}