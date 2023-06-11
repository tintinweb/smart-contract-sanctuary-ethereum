// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
// import Base64
// import "@openzeppelin/contracts/utils/Strings.sol";

import "../interfaces/IERC721Community.sol";
import "../interfaces/INFTExtension.sol";
import "./base/NFTExtension.sol";
import "../interfaces/IRenderer.sol";

library Base64Converter {
    function bytesToBase64(
        bytes memory data
    ) public pure returns (string memory) {
        bytes
            memory base64Chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

        uint256 len = data.length;
        uint256 outputLen = 4 * ((len + 2) / 3);
        bytes memory result = new bytes(outputLen);

        uint256 resultIndex = 0;
        uint256 dataIndex = 0;

        uint256 paddingLen = len % 3;
        uint256 mainLen = len - paddingLen;

        for (dataIndex = 0; dataIndex < mainLen; dataIndex += 3) {
            uint256 temp = (uint256(uint8(data[dataIndex])) << 16) |
                (uint256(uint8(data[dataIndex + 1])) << 8) |
                uint256(uint8(data[dataIndex + 2]));
            result[resultIndex++] = base64Chars[(temp >> 18) & 0x3F];
            result[resultIndex++] = base64Chars[(temp >> 12) & 0x3F];
            result[resultIndex++] = base64Chars[(temp >> 6) & 0x3F];
            result[resultIndex++] = base64Chars[temp & 0x3F];
        }

        if (paddingLen == 1) {
            uint256 temp = (uint256(uint8(data[dataIndex])) << 16);
            result[resultIndex++] = base64Chars[(temp >> 18) & 0x3F];
            result[resultIndex++] = base64Chars[(temp >> 12) & 0x3F];
            result[resultIndex++] = "=";
            result[resultIndex++] = "=";
        } else if (paddingLen == 2) {
            uint256 temp = (uint256(uint8(data[dataIndex])) << 16) |
                (uint256(uint8(data[dataIndex + 1])) << 8);
            result[resultIndex++] = base64Chars[(temp >> 18) & 0x3F];
            result[resultIndex++] = base64Chars[(temp >> 12) & 0x3F];
            result[resultIndex++] = base64Chars[(temp >> 6) & 0x3F];
            result[resultIndex++] = "=";
        }

        return string(result);
    }
}

contract OnchainArtStorageExtension is
    NFTExtension,
    INFTURIExtension,
    IRenderer
{
    string constant TOKEN_URI_TEMPLATE_START =
        'data:application/json;{"name":"OnchainArt","description":"OnchainArt","animation_url":"';
    string constant TOKEN_URI_TEMPLATE_END = '"}';

    // string constant HTML_BASE64_PREFIX = "data:text/html;base64,";
    string constant HTML_BASE64_PREFIX = "data:text/html;";

    bytes private template_start =
        bytes(
            '<!DOCTYPE html><html lang="en"><head><meta charset="utf-8"><script src="https://cdnjs.cloudflare.com/ajax/libs/pako/2.0.4/pako.min.js"></script><script id="hash-snippet">(()=>{let n=new URLSearchParams(window.location.search).get("dna");n||(n="0x"+Array(64).fill(0).map(n=>"0123456789abcdef"[16*Math.random()|0]).join("")),window.dna=n;let e={},o=function(n){for(var e=0,o=1779033703^n.length;e<n.length;e++)o=(o=Math.imul(o^n.charCodeAt(e),3432918353))<<13|o>>>19;return function(){return o=Math.imul((o=Math.imul(o^o>>>16,2246822507))^o>>>13,3266489909),(o^=o>>>16)>>>0}}(n);console.log("USING DNA:",n,", HASH:",o());let r=function(n,e,o,r){return function(){o|=0;var d=((n|=0)+(e|=0)|0)+(r|=0)|0;return r=r+1|0,n=e^e>>>9,e=o+(o<<3)|0,o=(o=o<<21|o>>>11)+d|0,(d>>>0)/4294967296}}(2654435769,608135816,3084996962,o());window.rendered=!1;let d=()=>{console.log("TRIGGER PREVIEW"),window.rendered=!0};window.rand=(n,e)=>void 0===n?r():void 0===e?r()*n:r()*(e-n)+n,window.preview=d,window.fxrand=rand,window.fxpreview=d,window.genome=[],e.evolve=(n,e)=>{let o=window.genome,r=o.find(e=>e.name===n);return r?r.value=e:o.push({name:n,value:e}),{name:n,value:e}},e.rand=rand,e.preview=d,e.genome=window.genome,window.Artgene=e})(window);</script><script src="https://cdnjs.cloudflare.com/ajax/libs/p5.js/1.6.0/p5.min.js"></script>'
            // '<script src="data:text/javascript;base64,eJzFU8FSwjAQvfcr9higQkgdRqdykQsHOTGj59imtENNmDRAq8O/u0mqrQ46cvJAE7Zv377dtw1KYSCVPA6CbC8TUygJlTD7HRnAWwCQaMGNWHB54BWZURoCPgYxvnnmyXaj1V6mJPKRRJVKr1QqyHJ9H0I0Q/SU9h4OVRmttuJJFJvckMiFpHpQCivaO2qBOay4ycdZqZQmWa051hjA0FK0JFIVlVgLkRLEY+TUk59qfmzV2+YqI3bIyGjcBnyuj9IxjbB1gMkEHoU2RcJLKAspKoxlSgOxGbVFxnjcwbFITW6vo7lj9nU8cTNFXE8uyV2TMGqRV+6MOzxDvMd0wdqSID30G3c9TIBZDtL+uR70ktgFSS4Ly2AHbhQE78NuKiFkmr+IBTpr+nFLyShyTakvjEU7CnYxxaf4BLW71emLd8tzg79b2vbp94YkH22jSag8xKmHKAVP5t6cWjeXShevSppzfjbezwb9bMeP9zOG1t8Nde7/6KdzwS/I151oLrTTLcZfk1xW07Pz/OztoH61s2F/oGD/YmdW77Q4FOJI/KcevANMH0pI"></script>',
        );

    bytes private template_end =
        bytes(
            '<script id="decoder">const e=document.querySelectorAll("script[type=\'text/javascript+gzip\']");e.forEach(e=>{let t=e.src.split(",")[1];!function(e){let t=atob(e);console.log("ARR",t);let o=Uint8Array.from(t,e=>e.charCodeAt(0));console.log("DECODED",o);let l=pako.inflate(o);console.log("TEXT",l);let c=new TextDecoder("utf-8").decode(l);console.log("DECODED",c);let n=document.createElement("script");n.textContent=c,document.head.appendChild(n)}(t)});</script><meta name="viewport" content="width=device-width, initial-scale=1"><title>artgene.xyz</title><style>html,body{margin:0;padding:0}main{background-color:#dedede;width:100vw;height:100vh;display:flex}canvas{object-fit:contain;max-width:100%;max-height:100%;margin:auto;display:block}</style></head><body> <main></main>  </body></html>'
        );

    // base64 encoded gunzipped script
    bytes private artScript =
        bytes(
            "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"
        );

    constructor(address _nft, string memory) NFTExtension(_nft) {
        // generativeArt = _art;
    }

    function updateArt(string calldata _generativeArt) external {
        // generativeArt = _generativeArt;
    }

    function tokenURI(
        uint256 tokenId
    )
        public
        view
        override(INFTURIExtension, IRenderer)
        returns (string memory)
    {
        return
            string.concat(
                TOKEN_URI_TEMPLATE_START,
                tokenHTML(tokenId, bytes32(0), bytes("")),
                TOKEN_URI_TEMPLATE_END
            );
    }

    function render(
        uint256 tokenId,
        bytes memory optional
    ) public view returns (string memory) {
        return tokenHTML(tokenId, bytes32(0), optional);
    }

    function tokenHTML(
        uint256,
        bytes32,
        bytes memory
    ) public view override returns (string memory) {
        return
            string.concat(
                HTML_BASE64_PREFIX,
                string(template_start),
                '<script type="text/javascript+gzip" src="data:text/javascript;base64,',
                string(artScript),
                "></script>",
                string(template_end)
            );
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(IERC165, NFTExtension) returns (bool) {
        return
            interfaceId == type(INFTURIExtension).interfaceId ||
            interfaceId == type(IRenderer).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

import "../../interfaces/INFTExtension.sol";
import "../../interfaces/IERC721Community.sol";

contract NFTExtension is INFTExtension, ERC165 {
    IERC721Community public immutable nft;

    constructor(address _nft) {
        nft = IERC721Community(_nft);
    }

    function beforeMint() internal view {
        require(
            nft.isExtensionAdded(address(this)),
            "NFTExtension: this contract is not allowed to be used as an extension"
        );
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165, ERC165)
        returns (bool)
    {
        return
            interfaceId == type(INFTExtension).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/** @dev config includes values have setters and can be changed later */
struct MintConfig {
    uint256 publicPrice;
    uint256 maxTokensPerMint;
    uint256 maxTokensPerWallet;
    uint256 royaltyFee;
    address payoutReceiver;
    bool shouldLockPayoutReceiver;
    bool shouldStartSale;
    bool shouldUseJsonExtension;
}

interface IERC721Community {

    // ------ View functions ------
    function saleStarted() external view returns (bool);

    function isExtensionAdded(address extension) external view returns (bool);

    /**
        Extra information stored for each tokenId. Optional, provided on mint
     */
    function data(uint256 tokenId) external view returns (bytes32);

    // ------ Mint functions ------
    /**
        Mint from NFTExtension contract. Optionally provide data parameter.
     */
    function mintExternal(
        uint256 amount,
        address to,
        bytes32 data
    ) external payable;

    // ------ Admin functions ------
    function addExtension(address extension) external;

    function revokeExtension(address extension) external;

    function withdraw() external;

    // ------ View functions ------
    /**
        Recommended royalty for tokenId sale.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);

    // ------ Admin functions ------
    function setRoyaltyReceiver(address receiver) external;

    function setRoyaltyFee(uint256 fee) external;
}

interface IERC721CommunityImplementation {
    function initialize(
        string memory _name,
        string memory _symbol,
        uint256 _maxSupply,
        uint256 _nReserved,
        bool _startAtOne,
        string memory uri,
        MintConfig memory config
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface INFTExtension is IERC165 {}

interface INFTURIExtension is INFTExtension {
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IRenderer is IERC165 {
    function render(uint256 tokenId, bytes memory optional) external view returns (string memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);

    function tokenHTML(uint256 tokenId, bytes32 dna, bytes calldata optional) external view returns (string memory);
}