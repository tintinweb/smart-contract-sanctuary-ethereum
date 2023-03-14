// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/MathUpgradeable.sol";

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = MathUpgradeable.log10(value) + 1;
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
            return toHexString(value, MathUpgradeable.log256(value) + 1);
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
library MathUpgradeable {
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
pragma solidity ^0.8.12;

import "../interface/IBearIpSetting.sol";
import "../interface/IBearIpChangeAdmin.sol";
import "../interface/INftVault.sol";

import "@openzeppelin-upgradeable/contracts-upgradeable/utils/StringsUpgradeable.sol";

library BearIpBox {
    enum BoxStatus {
        Inactive,
        Live,
        Ended,
        TimeOut,
        Opened,
        Redeemed,
        WithDrawFailed,
        Canceled
    }
    enum BoxType {
        Infinity,
        Bear
    }

    struct BoxInfo {
        address owner;
        BoxStatus boxStatus;
        uint256 startBlock;
        uint256 mintableBlockIndex;
        BoxType boxType;
        bytes32[] bids;
        address[] nfts;
        uint256[] ids;
        uint256 price_ticket;
        uint256 target_amount;
        uint256 max_ticket_amount;
        address[] winners_address;
        bytes32[] winners_bids;
        bool exist;
    }

    using StringsUpgradeable for uint256;

    error BearIpBoxAlreadyExist(bytes32 box_id);
    error BearIpBoxTransferNft(bytes32 box_id);

    event NewBox(
        address owner,
        bytes32 box_id,
        uint256 _mintable_blocks,
        BoxType _box_type,
        uint256 _target_amount,
        uint256 _price_ticket
    );

    function createBox(
        mapping(bytes32 => BoxInfo) storage all_boxs,
        IBearIpSetting _settings,
        uint256 _mintable_block_index,
        BoxType _box_type,
        uint256 _target_amount,
        uint256 _price_ticket,
        address[] calldata _nfts,
        uint256[] calldata _nft_ids
    ) internal returns (bytes32 box_id) {
        // require(_start_block > block.number, "start block must be greater than current block");
        require(_mintable_block_index >=0, "mintable block index must be greater than 0");
        // require(_target_amount > 0, "target amount must be greater than 0");
        require(_price_ticket > 0, "price ticket must be greater than 0");
        //require(_max_ticket_amount > 0, "ticket amount must be greater than 0");
        require(_nfts.length > 0, "nfts must be greater than 0");
        require(_nft_ids.length > 0, "nft ids must be greater than 0");
        require(_nfts.length == _nft_ids.length, "nfts and nft ids must be equal length");

        // if(_box_type == BoxType.Bear){
        //     require(_max_ticket_amount == _nfts.length, "_max_ticket_amount  must be  equal to nfts");
        // }
        uint256 minimal = _settings.create_box_fee();
        require(msg.value >= minimal, "not enough ether to create box");

        (bool succ,) = _settings.protocol_fee_pool().call{value: minimal}("");

        require(succ, "transfer fee failed");
        uint256 exchange = msg.value - minimal;
        if (exchange != 0) {
            (succ,) = msg.sender.call{value: exchange}("");
            require(succ, "transfer exchange failed");
        }

        box_id = keccak256(abi.encodePacked(block.number, msg.sender, msg.data, tx.origin));

        //    vault = INftVault(settings.nft_721_vault());
        //     vault.depositNft( msg.sender,_nfts, _nft_ids);

        if (all_boxs[box_id].exist) revert BearIpBoxAlreadyExist(box_id);
        {
            //    vault = ;
            //     ;

            if (!INftVault(_settings.nft_721_vault()).depositNft(payable(msg.sender), _nfts, _nft_ids)) {
                revert BearIpBoxTransferNft(box_id);
            }
            BoxInfo storage box = all_boxs[box_id];
            box.owner = msg.sender;
            box.price_ticket = _price_ticket;
            box.boxStatus = BoxStatus.Live;
            box.startBlock = block.number;
            box.mintableBlockIndex = _mintable_block_index;
            box.boxType = _box_type;
            if (_box_type == BoxType.Bear) {
                box.max_ticket_amount = _nfts.length;
                box.target_amount = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
            } else {
                box.target_amount = _target_amount;
                box.max_ticket_amount = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
            }

            box.nfts = _nfts;
            box.ids = _nft_ids;
            box.exist = true;
        }
        emit NewBox(msg.sender, box_id, _mintable_block_index, _box_type, _target_amount, _price_ticket);

        return box_id;
    }


    function getBoxBids(mapping(bytes32=>BoxInfo) storage all_boxes,
                             bytes32 _box_id) internal view returns(bytes32[] memory _bids){
    BoxInfo storage bi = all_boxes[_box_id];
    return bi.bids;
  }

    function getBoxWinners(mapping(bytes32=>BoxInfo) storage all_boxes,
                             bytes32 _box_id) internal view returns(address[] memory _winners){
    BoxInfo storage bi = all_boxes[_box_id];
    return bi.winners_address;
  }

    function getBoxWinnersBids(mapping(bytes32=>BoxInfo) storage all_boxes,
                             bytes32 _box_id) internal view returns(bytes32[] memory _winners){
    BoxInfo storage bi = all_boxes[_box_id];
    return bi.winners_bids;
  }

    function getBoxNfts(mapping(bytes32=>BoxInfo) storage all_boxes,
                             bytes32 _box_id) internal view returns(address[] memory _nfts){
    BoxInfo storage bi = all_boxes[_box_id];
    return bi.nfts;
  }

    function getBoxNftIds(mapping(bytes32=>BoxInfo) storage all_boxes,
                             bytes32 _box_id) public view returns(uint256[] memory _nft_ids){
    BoxInfo storage bi = all_boxes[_box_id];
    return bi.ids;
  }

    function getBoxInfo(mapping(bytes32=>BoxInfo) storage all_boxes,
                             bytes32 _box_id) public view returns(address _owner,
                                                                    BoxStatus _box_status,
                                                                    uint256 _start_block,
                                                                    uint256 _mintable_block_index,
                                                                    BoxType _box_type,
                                                                    uint256 _price_ticket,
                                                                    uint256 _target_amount,
                                                                    uint256 _max_ticket_amount,
                                                                    uint256 _ticket_amount,
                                                                    uint256 _winner_amount){
    BoxInfo storage bi = all_boxes[_box_id];
    return (bi.owner,
            bi.boxStatus,
            bi.startBlock,
            bi.mintableBlockIndex,
            bi.boxType,
            bi.price_ticket,
            bi.target_amount,
            bi.max_ticket_amount,
            bi.bids.length,
            bi.winners_address.length);
  }

    function getBoxStatus(mapping(bytes32=>BoxInfo) storage all_boxes,
                             bytes32 _box_id) public view returns(BoxStatus _box_status){
    BoxInfo storage bi = all_boxes[_box_id];
    return bi.boxStatus;
  }

    function getBoxOwner(mapping(bytes32=>BoxInfo) storage all_boxes,
                             bytes32 _box_id) public view returns(address _owner){
    BoxInfo storage bi = all_boxes[_box_id];
    return bi.owner;
  }













}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface IBearIpChangeAdmin {
    function changeAdmin(address new_admin) external;

    function transferOwnership(address new_owner) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface IBearIpOwnerProxy {
    function ownerOf(bytes32 hash) external view returns (address);

    function initOwnerOf(bytes32 hash, address addr) external returns (bool);

    function transferOwnership(bytes32 hash, address newOwner) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./IBearIpOwnerProxy.sol";

contract IBearIpSetting {
    uint256 public ratio_base;

    uint256 public create_box_fee;
    address public protocol_fee_pool;
    address public asset_fee_pool;

    address public nft_721_vault;

    uint256 public service_bi_fee_ratio;

    uint256[] public duration_blocks;

    IBearIpOwnerProxy public owner_proxy;



    function getDurationBlocks(uint256 index) public view returns (uint256) {
        return duration_blocks[index];
    }

    function getDurationBlocksLength() public view returns (uint256) {
        return duration_blocks.length;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface INftVault {
    function depositNft(address payable trader, address[] memory tokenAddresses, uint256[] memory tokenIds)
        external
        payable
        returns (bool);
    function withdrawNftSingle(address payable trader, address  tokenAddresses, uint256  tokenIds)
        external
        returns (bool);
}