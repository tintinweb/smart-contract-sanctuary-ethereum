/**
 *Submitted for verification at Etherscan.io on 2022-12-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

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

library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

}


interface IERC721 {

    // event
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    // Query
    function balanceOf(address owner) external view returns (uint256);
    function ownerOf(uint256 tokenId) external view returns (address);

    // transfer
    // function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
    // function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;

    // approve
    function approve(address to, uint256 tokenId) external;
    function setApprovalForAll(address operator, bool approved) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    // 鑄造與銷毀, 不是必須標準
    // mint
    function mint() external;
    // function safemint(address to, uint tokenId, bytes memory data) external;
    // function safemint(address to, uint tokenId) external;
    
    // burn
    function burn(uint tokenId) external;
}

interface IERC721Metadata {
    function name() external view returns(string memory);
    function symbo() external view returns(string memory);
    function tokenURI(uint256 tokenId) external view returns(string memory);
}

interface IERC165 {
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

contract ERC721 is IERC721, IERC721Metadata, IERC165{

    uint totalSupply = 0;
    string _name;
    string _symbo;
    string baseURI = "ipfs://QmSF5PnAK7tgnzrcGLbHTSkXwnw8B7WyJn13RTiKFjRaxt/";
    string baseExtension = ".json";

    mapping(address => uint) _balanceOf; //mint次數, 一人至多2次
    mapping(uint => address) _ownerOf;
    mapping(uint => address) _tokenApprovals;
    mapping(address => mapping(address => bool)) approvedOpperator;
    mapping(uint256 => string) _tokenURI;

    address _projectOwner;

    constructor(string memory name_, string memory symbo_){
        _name = name_;
        _symbo = symbo_;
        _projectOwner = msg.sender;
    }

    function name() external view returns(string memory){
        return _name;
    }

    function symbo() external view returns(string memory){
        return _symbo;
    }

    function tokenURI(uint256 tokenId) public view returns(string memory){
        require(_ownerOf[tokenId] != address(0), "no this token!");
        return _tokenURI[tokenId];
    }

    function setTokenURI(uint tokenId, string memory URI) internal {
        address owner = _ownerOf[tokenId];
        require(owner != address(0), "not this nft");
        _tokenURI[tokenId] = URI;
    }

    function balanceOf(address owner) public view returns (uint256){
        require(owner != address(0), "Error, addres in invalid");
        return _balanceOf[owner];
    }

    function ownerOf(uint256 tokenId) public view returns (address){
        address owner = _ownerOf[tokenId];
        require(owner != address(0), "Error, token is invalid");
        return owner;
    }

    function getTotalSupply() public view returns (uint totalySupply){
        return totalSupply;
    }

    // 查詢是否授權可以搞全部東西
    function isApprovedForAll(address owner, address operator) public view returns (bool){
        return approvedOpperator[owner][operator];
    }

    function approve(address to, uint256 tokenId) public {
        address owner = _ownerOf[tokenId];
        require(owner != to, " owner == to ?");
        require(owner == msg.sender, "no access to approve");
        require(isApprovedForAll(owner, msg.sender), "no access to approve");

        _tokenApprovals[tokenId] = to;
        emit Approval(owner,to , tokenId);
    }

    function getApproved(uint256 tokenId) public view returns (address){
        address owner = _ownerOf[tokenId];
        require(owner != address(0), "no this tokenId");
        return _tokenApprovals[tokenId];
    }

    // 設置可否搞全部nft
    function setApprovalForAll(address operator, bool approved) public {
        require(msg.sender != operator, "approve yourself ?");
        approvedOpperator[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    // 呼叫internal
    function transferFrom(address from, address to, uint256 tokenId) public{
        _transfer(from, to, tokenId);
    }

    // internal版
    function _transfer(address from, address to, uint tokenId) internal{

        address tokenOwner = _ownerOf[tokenId];
        // token在不在from那邊
        require(_ownerOf[tokenId] == from);
        // 擁有者, 授權者, 授權所有
        require(tokenOwner == msg.sender || msg.sender == getApproved(tokenId) || isApprovedForAll(tokenOwner, msg.sender), "no access");

        _ownerOf[tokenId] = to;
        emit Transfer(from, to, tokenId);

        // 刪除授權
        delete _tokenApprovals[tokenId];

        // 數量增減
        _balanceOf[from] -= 1;
        _balanceOf[to] += 1;
    }

    // 取隨機
    function random(uint number) internal view returns(uint) {
        return uint(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender))) % number;
    } 

    // 鑄造, 條件依商業模式或者喜好制定
    function mint() public {

        require(_balanceOf[msg.sender] < 2 || msg.sender == _projectOwner, "mint twice only for each person");
        require(totalSupply<=100,"no more supply ...");

        _balanceOf[msg.sender] += 1;
        totalSupply += 1;
        _ownerOf[totalSupply] = msg.sender;

        emit Transfer(address(0), msg.sender, totalSupply);

        // 取 0~9其中一隻
        uint getRandom = random(10);
        // 組URL, ipfs://Qme7j7mBW3fwcgZTu8x1oGWeFbBGTYaucH9sWyTaKdYtoH/0123456789.json
        string memory metaURI = getTokenURI(getRandom);
        setTokenURI(totalSupply, metaURI);

    }

    // 串接 tokenURI
    function getTokenURI(uint tokenId) public view returns(string memory) {
        string memory dataToString = Strings.toString(tokenId);
        return string(abi.encodePacked(baseURI, dataToString, baseExtension));
    }

    function burn(uint tokenId) public{

        address owner = _ownerOf[tokenId];

        require(msg.sender == owner, "only owner can burn it!");
        _balanceOf[msg.sender] -= 1;

        owner = address(0); // delete owner;
        delete _tokenApprovals[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    // IERC165, 告知有符合哪些應用
    function supportsInterface(bytes4 interfaceId) public pure returns (bool){
        return interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IERC165).interfaceId;
    }

}