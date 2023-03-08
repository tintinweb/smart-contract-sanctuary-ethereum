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
// OpenZeppelin Contracts (last updated v4.8.0) (access/Ownable2Step.sol)

pragma solidity ^0.8.0;

import "./Ownable.sol";

/**
 * @dev Contract module which provides access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership} and {acceptOwnership}.
 *
 * This module is used through inheritance. It will make available all functions
 * from parent (Ownable).
 */
abstract contract Ownable2Step is Ownable {
    address private _pendingOwner;

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        _pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner(), newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`) and deletes any pending owner.
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual override {
        delete _pendingOwner;
        super._transferOwnership(newOwner);
    }

    /**
     * @dev The new owner accepts the ownership transfer.
     */
    function acceptOwnership() external {
        address sender = _msgSender();
        require(pendingOwner() == sender, "Ownable2Step: caller is not the new owner");
        _transferOwnership(sender);
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

// SPDX-License-Identifier: LGPL-3.0
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./interfaces/IGombocController.sol";
import "./interfaces/IVotingEscrow.sol";
import "light-lib/contracts/LibTime.sol";

contract GombocController is Ownable2Step, IGombocController {
    // 7 * 86400 seconds - all future times are rounded by week
    uint256 private constant _DAY = 86400;
    uint256 private constant _WEEK = _DAY * 7;
    // Cannot change weight votes more often than once in 10 days
    uint256 private constant _WEIGHT_VOTE_DELAY = 10 * _DAY;

    uint256 private constant _MULTIPLIER = 10 ** 18;

    // lt token
    address public immutable token;
    // veLT token
    address public immutable override votingEscrow;

    // Gomboc parameters
    // All numbers are "fixed point" on the basis of 1e18
    int128 public nGombocTypes;
    int128 public nGomboc;
    mapping(int128 => string) public gombocTypeNames;

    // Needed for enumeration
    mapping(uint256 => address) public gombocs;

    // we increment values by 1 prior to storing them here so we can rely on a value
    // of zero as meaning the gomboc has not been set
    mapping(address => int128) private _gombocTypes;

    // user -> gombocAddr -> VotedSlope
    mapping(address => mapping(address => VotedSlope)) public voteUserSlopes;
    // Total vote power used by user
    mapping(address => uint256) public voteUserPower;
    // Last user vote's timestamp for each gomboc address
    mapping(address => mapping(address => uint256)) public lastUserVote;

    // user -> gombocAddr -> epoch -> Point
    mapping(address => mapping(address => mapping(uint256 => UserPoint))) public voteVeLtPointHistory;
    // user -> gombocAddr -> lastEpoch
    mapping(address => mapping(address => uint256)) public lastVoteVeLtPointEpoch;

    // Past and scheduled points for gomboc weight, sum of weights per type, total weight
    // Point is for bias+slope
    // changes_* are for changes in slope
    // time_* are for the last change timestamp
    // timestamps are rounded to whole weeks

    // gombocAddr -> time -> Point
    mapping(address => mapping(uint256 => Point)) public pointsWeight;
    // gombocAddr -> time -> slope
    mapping(address => mapping(uint256 => uint256)) private _changesWeight;
    // gombocAddr -> last scheduled time (next week)
    mapping(address => uint256) public timeWeight;

    //typeId -> time -> Point
    mapping(int128 => mapping(uint256 => Point)) public pointsSum;
    // typeId -> time -> slope
    mapping(int128 => mapping(uint256 => uint256)) public changesSum;
    //typeId -> last scheduled time (next week)
    mapping(uint256 => uint256) public timeSum;

    // time -> total weight
    mapping(uint256 => uint256) public pointsTotal;
    // last scheduled time
    uint256 public timeTotal;

    // typeId -> time -> type weight
    mapping(int128 => mapping(uint256 => uint256)) public pointsTypeWeight;
    // typeId -> last scheduled time (next week)
    mapping(uint256 => uint256) public timeTypeWeight;

    /**
     * @notice Contract constructor
     * @param tokenAddress  LT contract address
     * @param votingEscrowAddress veLT contract address
     */
    constructor(address tokenAddress, address votingEscrowAddress) {
        require(tokenAddress != address(0), "CE000");
        require(votingEscrowAddress != address(0), "CE000");

        token = tokenAddress;
        votingEscrow = votingEscrowAddress;
        timeTotal = LibTime.timesRoundedByWeek(block.timestamp);
    }

    /**
     * @notice Get gomboc type for address
     *  @param _addr Gomboc address
     * @return Gomboc type id
     */
    function gombocTypes(address _addr) external view override returns (int128) {
        int128 gombocType = _gombocTypes[_addr];
        require(gombocType != 0, "CE000");
        return gombocType - 1;
    }

    /**
     * @notice Add gomboc `addr` of type `gombocType` with weight `weight`
     * @param addr Gomboc address
     * @param gombocType Gomboc type
     * @param weight Gomboc weight
     */
    function addGomboc(address addr, int128 gombocType, uint256 weight) external override onlyOwner {
        require(gombocType >= 0 && gombocType < nGombocTypes, "GC001");
        require(_gombocTypes[addr] == 0, "GC002");

        int128 n = nGomboc;
        nGomboc = n + 1;
        gombocs[_int128ToUint256(n)] = addr;

        _gombocTypes[addr] = gombocType + 1;
        uint256 nextTime = LibTime.timesRoundedByWeek(block.timestamp + _WEEK);

        if (weight > 0) {
            uint256 _typeWeight = _getTypeWeight(gombocType);
            uint256 _oldSum = _getSum(gombocType);
            uint256 _oldTotal = _getTotal();

            pointsSum[gombocType][nextTime].bias = weight + _oldSum;
            timeSum[_int128ToUint256(gombocType)] = nextTime;
            pointsTotal[nextTime] = _oldTotal + _typeWeight * weight;
            timeTotal = nextTime;

            pointsWeight[addr][nextTime].bias = weight;
        }

        if (timeSum[_int128ToUint256(gombocType)] == 0) {
            timeSum[_int128ToUint256(gombocType)] = nextTime;
        }
        timeWeight[addr] = nextTime;

        emit NewGomboc(addr, gombocType, weight);
    }

    /**
     * @notice Checkpoint to fill data common for all gombocs
     */
    function checkpoint() external override {
        _getTotal();
    }

    /**
     * @notice Checkpoint to fill data for both a specific gomboc and common for all gomboc
     * @param addr Gomboc address
     */
    function checkpointGomboc(address addr) external override {
        _getWeight(addr);
        _getTotal();
    }

    /**
     * @notice Get Gomboc relative weight (not more than 1.0) normalized to 1e18(e.g. 1.0 == 1e18). Inflation which will be received by
     * it is inflation_rate * relative_weight / 1e18
     * @param gombocAddress Gomboc address
     * @param time Relative weight at the specified timestamp in the past or present
     * @return Value of relative weight normalized to 1e18
     */
    function gombocRelativeWeight(address gombocAddress, uint256 time) external view override returns (uint256) {
        return _gombocRelativeWeight(gombocAddress, time);
    }

    /**
     *  @notice Get gomboc weight normalized to 1e18 and also fill all the unfilled values for type and gomboc records
     * @dev Any address can call, however nothing is recorded if the values are filled already
     * @param gombocAddress Gomboc address
     * @param time Relative weight at the specified timestamp in the past or present
     * @return Value of relative weight normalized to 1e18
     */
    function gombocRelativeWeightWrite(address gombocAddress, uint256 time) external override returns (uint256) {
        _getWeight(gombocAddress);
        // Also calculates get_sum;
        _getTotal();
        return _gombocRelativeWeight(gombocAddress, time);
    }

    /**
     * @notice Add gomboc type with name `_name` and weight `weight`
     * @dev only owner call
     * @param _name Name of gomboc type
     * @param weight Weight of gomboc type
     */
    function addType(string memory _name, uint256 weight) external override onlyOwner {
        int128 typeId = nGombocTypes;
        gombocTypeNames[typeId] = _name;
        nGombocTypes = typeId + 1;
        if (weight != 0) {
            _changeTypeWeight(typeId, weight);
        }
        emit AddType(_name, typeId);
    }

    /**
     * @notice Change gomboc type `typeId` weight to `weight`
     * @dev only owner call
     * @param typeId Gomboc type id
     * @param weight New Gomboc weight
     */
    function changeTypeWeight(int128 typeId, uint256 weight) external override onlyOwner {
        _changeTypeWeight(typeId, weight);
    }

    /**
     * @notice Change weight of gomboc `addr` to `weight`
     * @param gombocAddress `Gomboc` contract address
     * @param weight New Gomboc weight
     */
    function changeGombocWeight(address gombocAddress, uint256 weight) external override onlyOwner {
        int128 gombocType = _gombocTypes[gombocAddress] - 1;
        require(gombocType >= 0, "GC000");
        _changeGombocWeight(gombocAddress, weight);
    }

    /**
     * @notice Allocate voting power for changing pool weights
     * @param gombocAddressList Gomboc of list which `msg.sender` votes for
     * @param userWeightList Weight of list for a gomboc in bps (units of 0.01%). Minimal is 0.01%.
     */
    function batchVoteForGombocWeights(address[] memory gombocAddressList, uint256[] memory userWeightList) public {
        require(gombocAddressList.length == userWeightList.length, "GC007");
        for (uint256 i = 0; i < gombocAddressList.length && i < 128; i++) {
            voteForGombocWeights(gombocAddressList[i], userWeightList[i]);
        }
    }

    //avoid Stack too deep
    struct VoteForGombocWeightsParam {
        VotedSlope oldSlope;
        VotedSlope newSlope;
        uint256 oldDt;
        uint256 oldBias;
        uint256 newDt;
        uint256 newBias;
        UserPoint newUserPoint;
    }

    /**
     * @notice Allocate voting power for changing pool weights
     * @param gombocAddress Gomboc which `msg.sender` votes for
     * @param userWeight Weight for a gomboc in bps (units of 0.01%). Minimal is 0.01%.
     *        example: 10%=1000,3%=300,0.01%=1,100%=10000
     */
    function voteForGombocWeights(address gombocAddress, uint256 userWeight) public override {
        int128 gombocType = _gombocTypes[gombocAddress] - 1;
        require(gombocType >= 0, "GC000");

        uint256 slope = uint256(IVotingEscrow(votingEscrow).getLastUserSlope(msg.sender));
        uint256 lockEnd = IVotingEscrow(votingEscrow).lockedEnd(msg.sender);
        uint256 nextTime = LibTime.timesRoundedByWeek(block.timestamp + _WEEK);
        require(lockEnd > nextTime, "GC003");
        require(userWeight >= 0 && userWeight <= 10000, "GC004");
        require(block.timestamp >= lastUserVote[msg.sender][gombocAddress] + _WEIGHT_VOTE_DELAY, "GC005");

        VoteForGombocWeightsParam memory param;

        // Prepare slopes and biases in memory
        param.oldSlope = voteUserSlopes[msg.sender][gombocAddress];
        param.oldDt = 0;
        if (param.oldSlope.end > nextTime) {
            param.oldDt = param.oldSlope.end - nextTime;
        }
        param.oldBias = param.oldSlope.slope * param.oldDt;

        param.newSlope = VotedSlope({slope: (slope * userWeight) / 10000, end: lockEnd, power: userWeight});

        // dev: raises when expired
        param.newDt = lockEnd - nextTime;
        param.newBias = param.newSlope.slope * param.newDt;
        param.newUserPoint = UserPoint({bias: param.newBias, slope: param.newSlope.slope, ts: nextTime, blk: block.number});

        // Check and update powers (weights) used
        uint256 powerUsed = voteUserPower[msg.sender];
        powerUsed = powerUsed + param.newSlope.power - param.oldSlope.power;
        voteUserPower[msg.sender] = powerUsed;
        require((powerUsed >= 0) && (powerUsed <= 10000), "GC006");

        //// Remove old and schedule new slope changes
        // Remove slope changes for old slopes
        // Schedule recording of initial slope for nextTime
        uint256 oldWeightBias = _getWeight(gombocAddress);
        uint256 oldWeightSlope = pointsWeight[gombocAddress][nextTime].slope;
        uint256 oldSumBias = _getSum(gombocType);
        uint256 oldSumSlope = pointsSum[gombocType][nextTime].slope;

        pointsWeight[gombocAddress][nextTime].bias = Math.max(oldWeightBias + param.newBias, param.oldBias) - param.oldBias;
        pointsSum[gombocType][nextTime].bias = Math.max(oldSumBias + param.newBias, param.oldBias) - param.oldBias;

        if (param.oldSlope.end > nextTime) {
            pointsWeight[gombocAddress][nextTime].slope =
                Math.max(oldWeightSlope + param.newSlope.slope, param.oldSlope.slope) -
                param.oldSlope.slope;
            pointsSum[gombocType][nextTime].slope =
                Math.max(oldSumSlope + param.newSlope.slope, param.oldSlope.slope) -
                param.oldSlope.slope;
        } else {
            pointsWeight[gombocAddress][nextTime].slope += param.newSlope.slope;
            pointsSum[gombocType][nextTime].slope += param.newSlope.slope;
        }

        if (param.oldSlope.end > block.timestamp) {
            // Cancel old slope changes if they still didn't happen
            _changesWeight[gombocAddress][param.oldSlope.end] -= param.oldSlope.slope;
            changesSum[gombocType][param.oldSlope.end] -= param.oldSlope.slope;
        }

        //Add slope changes for new slopes
        _changesWeight[gombocAddress][param.newSlope.end] += param.newSlope.slope;
        changesSum[gombocType][param.newSlope.end] += param.newSlope.slope;

        _getTotal();

        voteUserSlopes[msg.sender][gombocAddress] = param.newSlope;

        // Record last action time
        lastUserVote[msg.sender][gombocAddress] = block.timestamp;

        //record user point history
        uint256 voteVeLtPointEpoch = lastVoteVeLtPointEpoch[msg.sender][gombocAddress] + 1;
        voteVeLtPointHistory[msg.sender][gombocAddress][voteVeLtPointEpoch] = param.newUserPoint;
        lastVoteVeLtPointEpoch[msg.sender][gombocAddress] = voteVeLtPointEpoch;

        emit VoteForGomboc(msg.sender, gombocAddress, block.timestamp, userWeight);
    }

    /**
     * @notice Get current gomboc weight
     * @param addr Gomboc address
     * @return Gomboc weight
     */
    function getGombocWeight(address addr) external view override returns (uint256) {
        return pointsWeight[addr][timeWeight[addr]].bias;
    }

    /**
     * @notice Get current type weight
     * @param typeId Type id
     * @return Type weight
     */
    function getTypeWeight(int128 typeId) external view override returns (uint256) {
        return pointsTypeWeight[typeId][timeTypeWeight[_int128ToUint256(typeId)]];
    }

    /**
     * @notice Get current total (type-weighted) weight
     * @return Total weight
     */
    function getTotalWeight() external view override returns (uint256) {
        return pointsTotal[timeTotal];
    }

    /**
     * @notice Get sum of gomboc weights per type
     * @param typeId Type id
     * @return Sum of gomboc weights
     */
    function getWeightsSumPreType(int128 typeId) external view override returns (uint256) {
        return pointsSum[typeId][timeSum[_int128ToUint256(typeId)]].bias;
    }

    /**
     * @notice Fill historic type weights week-over-week for missed checkins and return the type weight for the future week
     * @param gombocType Gomboc type id
     * @return Type weight
     */
    function _getTypeWeight(int128 gombocType) internal returns (uint256) {
        uint256 t = timeTypeWeight[_int128ToUint256(gombocType)];
        if (t <= 0) {
            return 0;
        }

        uint256 w = pointsTypeWeight[gombocType][t];
        for (uint256 i = 0; i < 500; i++) {
            if (t > block.timestamp) {
                break;
            }
            t += _WEEK;
            pointsTypeWeight[gombocType][t] = w;
            if (t > block.timestamp) {
                timeTypeWeight[_int128ToUint256(gombocType)] = t;
            }
        }
        return w;
    }

    /**
     * @notice Fill sum of gomboc weights for the same type week-over-week for missed checkins and return the sum for the future week
     * @param gombocType Gomboc type id
     * @return Sum of weights
     */
    function _getSum(int128 gombocType) internal returns (uint256) {
        uint256 ttype = _int128ToUint256(gombocType);
        uint256 t = timeSum[ttype];
        if (t <= 0) {
            return 0;
        }

        Point memory pt = pointsSum[gombocType][t];
        for (uint256 i = 0; i < 500; i++) {
            if (t > block.timestamp) {
                break;
            }
            t += _WEEK;
            uint256 dBias = pt.slope * _WEEK;
            if (pt.bias > dBias) {
                pt.bias -= dBias;
                uint256 dSlope = changesSum[gombocType][t];
                pt.slope -= dSlope;
            } else {
                pt.bias = 0;
                pt.slope = 0;
            }
            pointsSum[gombocType][t] = pt;
            if (t > block.timestamp) {
                timeSum[ttype] = t;
            }
        }
        return pt.bias;
    }

    /**
     * @notice Fill historic total weights week-over-week for missed checkins and return the total for the future week
     * @return Total weight
     */
    function _getTotal() internal returns (uint256) {
        uint256 t = timeTotal;
        int128 _nGombocTypes = nGombocTypes;
        if (t > block.timestamp) {
            // If we have already checkpointed - still need to change the value
            t -= _WEEK;
        }
        uint256 pt = pointsTotal[t];

        for (int128 gombocType = 0; gombocType < 100; gombocType++) {
            if (gombocType == _nGombocTypes) {
                break;
            }
            _getSum(gombocType);
            _getTypeWeight(gombocType);
        }

        for (uint256 i = 0; i < 500; i++) {
            if (t > block.timestamp) {
                break;
            }
            t += _WEEK;
            pt = 0;
            // Scales as n_types * n_unchecked_weeks (hopefully 1 at most)
            for (int128 gombocType = 0; gombocType < 100; gombocType++) {
                if (gombocType == _nGombocTypes) {
                    break;
                }
                uint256 typeSum = pointsSum[gombocType][t].bias;
                uint256 typeWeight = pointsTypeWeight[gombocType][t];
                pt += typeSum * typeWeight;
            }

            pointsTotal[t] = pt;
            if (t > block.timestamp) {
                timeTotal = t;
            }
        }

        return pt;
    }

    /**
     * @notice Fill historic gomboc weights week-over-week for missed checkins and return the total for the future week
     * @param gombocAddr Address of the gomboc
     * @return Gomboc weight
     */
    function _getWeight(address gombocAddr) internal returns (uint256) {
        uint256 t = timeWeight[gombocAddr];

        if (t <= 0) {
            return 0;
        }
        Point memory pt = pointsWeight[gombocAddr][t];
        for (uint256 i = 0; i < 500; i++) {
            if (t > block.timestamp) {
                break;
            }
            t += _WEEK;
            uint256 dBias = pt.slope * _WEEK;
            if (pt.bias > dBias) {
                pt.bias -= dBias;
                uint256 dSlope = _changesWeight[gombocAddr][t];
                pt.slope -= dSlope;
            } else {
                pt.bias = 0;
                pt.slope = 0;
            }
            pointsWeight[gombocAddr][t] = pt;
            if (t > block.timestamp) {
                timeWeight[gombocAddr] = t;
            }
        }
        return pt.bias;
    }

    /**
     * @notice Get Gomboc relative weight (not more than 1.0) normalized to 1e18 (e.g. 1.0 == 1e18).
     * Inflation which will be received by it is inflation_rate * relative_weight / 1e18
     * @param addr Gomboc address
     * @param time Relative weight at the specified timestamp in the past or present
     * @return Value of relative weight normalized to 1e18
     */
    function _gombocRelativeWeight(address addr, uint256 time) internal view returns (uint256) {
        uint256 t = LibTime.timesRoundedByWeek(time);
        uint256 _totalWeight = pointsTotal[t];
        if (_totalWeight <= 0) {
            return 0;
        }

        int128 gombocType = _gombocTypes[addr] - 1;
        uint256 _typeWeight = pointsTypeWeight[gombocType][t];
        uint256 _gombocWeight = pointsWeight[addr][t].bias;
        return (_MULTIPLIER * _typeWeight * _gombocWeight) / _totalWeight;
    }

    function _changeGombocWeight(address addr, uint256 weight) internal {
        // Change gomboc weight
        //Only needed when testing in reality
        int128 gombocType = _gombocTypes[addr] - 1;
        uint256 oldGombocWeight = _getWeight(addr);
        uint256 typeWeight = _getTypeWeight(gombocType);
        uint256 oldSum = _getSum(gombocType);
        uint256 _totalWeight = _getTotal();
        uint256 nextTime = LibTime.timesRoundedByWeek(block.timestamp + _WEEK);

        pointsWeight[addr][nextTime].bias = weight;
        timeWeight[addr] = nextTime;

        uint256 newSum = oldSum + weight - oldGombocWeight;
        pointsSum[gombocType][nextTime].bias = newSum;
        timeSum[_int128ToUint256(gombocType)] = nextTime;

        _totalWeight = _totalWeight + newSum * typeWeight - oldSum * typeWeight;
        pointsTotal[nextTime] = _totalWeight;
        timeTotal = nextTime;

        emit NewGombocWeight(addr, block.timestamp, weight, _totalWeight);
    }

    /**
     *  @notice Change type weight
     * @param typeId Type id
     * @param weight New type weight
     */
    function _changeTypeWeight(int128 typeId, uint256 weight) internal {
        uint256 oldWeight = _getTypeWeight(typeId);
        uint256 oldSum = _getSum(typeId);
        uint256 _totalWeight = _getTotal();
        uint256 nextTime = LibTime.timesRoundedByWeek(block.timestamp + _WEEK);

        _totalWeight = _totalWeight + oldSum * weight - oldSum * oldWeight;
        pointsTotal[nextTime] = _totalWeight;
        pointsTypeWeight[typeId][nextTime] = weight;
        timeTotal = nextTime;
        timeTypeWeight[_int128ToUint256(typeId)] = nextTime;

        emit NewTypeWeight(typeId, nextTime, weight, _totalWeight);
    }

    function _int128ToUint256(int128 from) internal pure returns (uint256) {
        return uint256(uint128(from));
    }
}

// SPDX-License-Identifier: LGPL-3.0

pragma solidity 0.8.17;

interface IGombocController {
    struct Point {
        uint256 bias;
        uint256 slope;
    }

    struct VotedSlope {
        uint256 slope;
        uint256 power;
        uint256 end;
    }

    struct UserPoint {
        uint256 bias;
        uint256 slope;
        uint256 ts;
        uint256 blk;
    }

    event AddType(string name, int128 type_id);

    event NewTypeWeight(int128 indexed type_id, uint256 time, uint256 weight, uint256 total_weight);

    event NewGombocWeight(address indexed gomboc_address, uint256 time, uint256 weight, uint256 total_weight);

    event VoteForGomboc(address indexed user, address indexed gomboc_address, uint256 time, uint256 weight);

    event NewGomboc(address indexed gomboc_address, int128 gomboc_type, uint256 weight);

    /**
     * @notice Get gomboc type for address
     *  @param _addr Gomboc address
     * @return Gomboc type id
     */
    function gombocTypes(address _addr) external view returns (int128);

    /**
     * @notice Add gomboc `addr` of type `gomboc_type` with weight `weight`
     * @param addr Gomboc address
     * @param gombocType Gomboc type
     * @param weight Gomboc weight
     */
    function addGomboc(address addr, int128 gombocType, uint256 weight) external;

    /**
     * @notice Checkpoint to fill data common for all gombocs
     */
    function checkpoint() external;

    /**
     * @notice Checkpoint to fill data for both a specific gomboc and common for all gomboc
     * @param addr Gomboc address
     */
    function checkpointGomboc(address addr) external;

    /**
     * @notice Get Gomboc relative weight (not more than 1.0) normalized to 1e18(e.g. 1.0 == 1e18). Inflation which will be received by
     * it is inflation_rate * relative_weight / 1e18
     * @param gombocAddress Gomboc address
     * @param time Relative weight at the specified timestamp in the past or present
     * @return Value of relative weight normalized to 1e18
     */
    function gombocRelativeWeight(address gombocAddress, uint256 time) external view returns (uint256);

    /**
     *  @notice Get gomboc weight normalized to 1e18 and also fill all the unfilled values for type and gauge records
     * @dev Any address can call, however nothing is recorded if the values are filled already
     * @param gombocAddress Gomboc address
     * @param time Relative weight at the specified timestamp in the past or present
     * @return Value of relative weight normalized to 1e18
     */
    function gombocRelativeWeightWrite(address gombocAddress, uint256 time) external returns (uint256);

    /**
     * @notice Add gomboc type with name `_name` and weight `weight`
     * @dev only owner call
     * @param _name Name of gauge type
     * @param weight Weight of gauge type
     */
    function addType(string memory _name, uint256 weight) external;

    /**
     * @notice Change gomboc type `type_id` weight to `weight`
     * @dev only owner call
     * @param type_id Gomboc type id
     * @param weight New Gomboc weight
     */
    function changeTypeWeight(int128 type_id, uint256 weight) external;

    /**
     * @notice Change weight of gomboc `addr` to `weight`
     * @param gombocAddress `Gomboc` contract address
     * @param weight New Gomboc weight
     */
    function changeGombocWeight(address gombocAddress, uint256 weight) external;

    /**
     * @notice Allocate voting power for changing pool weights
     * @param gombocAddress Gomboc which `msg.sender` votes for
     * @param userWeight Weight for a gomboc in bps (units of 0.01%). Minimal is 0.01%. Ignored if 0.
     *        example: 10%=1000,3%=300,0.01%=1,100%=10000
     */
    function voteForGombocWeights(address gombocAddress, uint256 userWeight) external;

    /**
     * @notice Get current gomboc weight
     * @param addr Gomboc address
     * @return Gomboc weight
     */

    function getGombocWeight(address addr) external view returns (uint256);

    /**
     * @notice Get current type weight
     * @param type_id Type id
     * @return Type weight
     */
    function getTypeWeight(int128 type_id) external view returns (uint256);

    /**
     * @notice Get current total (type-weighted) weight
     * @return Total weight
     */
    function getTotalWeight() external view returns (uint256);

    /**
     * @notice Get sum of gomboc weights per type
     * @param type_id Type id
     * @return Sum of gomboc weights
     */
    function getWeightsSumPreType(int128 type_id) external view returns (uint256);

    function votingEscrow() external view returns (address);
}

// SPDX-License-Identifier: LGPL-3.0
pragma solidity 0.8.17;

interface IVotingEscrow {
    struct Point {
        int256 bias;
        int256 slope;
        uint256 ts;
        uint256 blk;
    }

    struct LockedBalance {
        int256 amount;
        uint256 end;
    }

    event Deposit(
        address indexed provider,
        address indexed beneficiary,
        uint256 value,
        uint256 afterAmount,
        uint256 indexed locktime,
        uint256 _type,
        uint256 ts
    );
    event Withdraw(address indexed provider, uint256 value, uint256 ts);

    event Supply(uint256 prevSupply, uint256 supply);

    event SetSmartWalletChecker(address sender, address indexed newChecker, address oldChecker);

    event SetPermit2Address(address oldAddress, address newAddress);

    /***
     * @dev Get the most recently recorded rate of voting power decrease for `_addr`
     * @param _addr Address of the user wallet
     * @return Value of the slope
     */
    function getLastUserSlope(address _addr) external view returns (int256);

    /***
     * @dev Get the timestamp for checkpoint `_idx` for `_addr`
     * @param _addr User wallet address
     * @param _idx User epoch number
     * @return Epoch time of the checkpoint
     */
    function userPointHistoryTs(address _addr, uint256 _idx) external view returns (uint256);

    /***
     * @dev Get timestamp when `_addr`'s lock finishes
     * @param _addr User wallet
     * @return Epoch time of the lock end
     */
    function lockedEnd(address _addr) external view returns (uint256);

    function createLock(uint256 _value, uint256 _unlockTime, uint256 nonce, uint256 deadline, bytes memory signature) external;

    function createLockFor(
        address _beneficiary,
        uint256 _value,
        uint256 _unlockTime,
        uint256 nonce,
        uint256 deadline,
        bytes memory signature
    ) external;

    function increaseAmount(uint256 _value, uint256 nonce, uint256 deadline, bytes memory signature) external;

    function increaseAmountFor(address _beneficiary, uint256 _value, uint256 nonce, uint256 deadline, bytes memory signature) external;

    function increaseUnlockTime(uint256 _unlockTime) external;

    function checkpointSupply() external;

    function withdraw() external;

    function epoch() external view returns (uint256);

    function getUserPointHistory(address _userAddress, uint256 _index) external view returns (Point memory);

    function supplyPointHistory(uint256 _index) external view returns (int256 bias, int256 slope, uint256 ts, uint256 blk);

    /***
     * @notice Get the current voting power for `msg.sender`
     * @dev Adheres to the ERC20 `balanceOf` interface for Aragon compatibility
     * @param _addr User wallet address
     * @param _t Epoch time to return voting power at
     * @return User voting power
     * @dev return the present voting power if _t is 0
     */
    function balanceOfAtTime(address _addr, uint256 _t) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function totalSupplyAtTime(uint256 _t) external view returns (uint256);

    function userPointEpoch(address _user) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.17;

library LibTime {

    // 7 * 86400 seconds - all future times are rounded by week
    uint256 public constant DAY = 86400;
    uint256 public constant WEEK = DAY * 7;

    /**
     * @dev times are rounded by week
     * @param time time
     */
    function timesRoundedByWeek(uint256 time) internal pure returns (uint256) {
        return (time / WEEK) * WEEK;
    }
}