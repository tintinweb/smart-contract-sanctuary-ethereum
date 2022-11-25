// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./PriceConsumerV3.sol";

contract GoldStaking is Ownable {
    PriceConsumerV3 internal priceConsumerV3;

    IERC20Metadata public goldToken;
    IUniswapV2Pair public goldLP;

    struct META_DATA {
        uint256 amount;
        uint256 stakeTime;
        uint256 claimTime;
    }

    mapping(address => mapping(uint8 => META_DATA[])) internal tokenStakeData;
    mapping(address => mapping(uint8 => META_DATA[])) internal lpStakeData;

    uint256[6] public tokenStakeAPR;
    uint256[6] public lpStakeAPR;
    uint256[6] public penaltyForEarlyClaim;
    uint256[6] public lockTerm;

    uint256[6] public tokenStakeAmount;
    uint256[6] public lpStakeAmount;

    uint256[6] public tokenMaxStakeAmount;

    constructor(address _goldToken, address _goldLP) {
        priceConsumerV3 = new PriceConsumerV3();
        goldToken = IERC20Metadata(_goldToken);
        goldLP = IUniswapV2Pair(_goldLP);

        tokenStakeAPR[0] = 10;
        tokenStakeAPR[1] = 15;
        tokenStakeAPR[2] = 20;
        tokenStakeAPR[3] = 25;
        tokenStakeAPR[4] = 35;
        tokenStakeAPR[5] = 45;

        lpStakeAPR[0] = 20;
        lpStakeAPR[1] = 25;
        lpStakeAPR[2] = 30;
        lpStakeAPR[3] = 35;
        lpStakeAPR[4] = 45;
        lpStakeAPR[5] = 55;

        penaltyForEarlyClaim[0] = 0;
        penaltyForEarlyClaim[1] = 50;
        penaltyForEarlyClaim[2] = 40;
        penaltyForEarlyClaim[3] = 30;
        penaltyForEarlyClaim[4] = 25;
        penaltyForEarlyClaim[5] = 20;

        lockTerm[0] = 0;
        lockTerm[1] = 1 * 30 days;
        lockTerm[2] = 2 * 30 days;
        lockTerm[3] = 3 * 30 days;
        lockTerm[4] = 6 * 30 days;
        lockTerm[5] = 12 * 30 days;

        tokenMaxStakeAmount[0] = 19750000 * 1e18;
        tokenMaxStakeAmount[1] = 7900000 * 1e18;
        tokenMaxStakeAmount[2] = 19750000 * 1e18;
        tokenMaxStakeAmount[3] = 15800000 * 1e18;
        tokenMaxStakeAmount[4] = 11285700 * 1e18;
        tokenMaxStakeAmount[5] = 8777777 * 1e18;
    }

    function updateTokenStakeAPR(uint256 lockType, uint256 apr)
        external
        onlyOwner
    {
        require(lockType < 6, "lockType should be less than 6");
        tokenStakeAPR[lockType] = apr;
    }

    function updateLpStakeAPR(uint256 lockType, uint256 apr)
        external
        onlyOwner
    {
        require(lockType < 6, "lockType should be less than 6");
        lpStakeAPR[lockType] = apr;
    }

    function updateTokenMaxStakeAmount(uint256 lockType, uint256 maxTokenAmount)
        external
        onlyOwner
    {
        require(lockType < 6, "lockType should be less than 6");
        tokenMaxStakeAmount[lockType] = maxTokenAmount;
    }

    function updatePenaltyAPR(uint256 lockType, uint256 penalty)
        external
        onlyOwner
    {
        require(lockType < 6, "lockType should be less than 6");
        penaltyForEarlyClaim[lockType] = penalty;
    }

    function updateLockTerm(uint256 lockType, uint256 month)
        external
        onlyOwner
    {
        require(lockType < 6, "lockType should be less than 6");
        lockTerm[lockType] = month * 30 days;
    }

    function getEthPrice() public view returns (uint256) {
        return uint256(priceConsumerV3.getLatestPrice());
    }

    function getTokenPrice() public view returns (uint256) {
        uint112 reserve0;
        uint112 reserve1;
        uint256 tokenPrice;

        (reserve0, reserve1, ) = goldLP.getReserves();

        uint256 ethPrice = getEthPrice();

        if (goldLP.token0() == address(goldToken))
            tokenPrice = ((ethPrice * reserve1) /
                reserve0 /
                (10**(18 - goldToken.decimals())));
        else
            tokenPrice = ((ethPrice * reserve0) /
                reserve1 /
                (10**(18 - goldToken.decimals())));

        return tokenPrice;
    }

    function getLpPrice() public view returns (uint256) {
        uint112 reserve0;
        uint112 reserve1;
        uint256 lpPrice;

        (reserve0, reserve1, ) = goldLP.getReserves();
        uint256 ethPrice = getEthPrice();
        uint256 lpTotalSupply = goldLP.totalSupply();
        if (goldLP.token0() == address(goldToken))
            lpPrice = ((ethPrice * reserve1 * 2) / lpTotalSupply);
        else lpPrice = ((ethPrice * reserve0 * 2) / lpTotalSupply);
        return lpPrice;
    }

    function getTokenStakeData(address user, uint8 lockType)
        external
        view
        returns (META_DATA[] memory)
    {
        return tokenStakeData[user][lockType];
    }

    function getLpStakeData(address user, uint8 lockType)
        external
        view
        returns (META_DATA[] memory)
    {
        return lpStakeData[user][lockType];
    }

    function tokenStake(uint256 amount, uint8 lockType) external {
        require(amount > 0 && lockType <= 6, "Invalid arguments.");
        require(
            tokenStakeAmount[lockType] < tokenMaxStakeAmount[lockType],
            "Full staked already."
        );

        uint256 stakeAmount = Math.min(
            amount,
            tokenMaxStakeAmount[lockType] - tokenStakeAmount[lockType]
        );
        goldToken.transferFrom(msg.sender, address(this), stakeAmount);

        META_DATA memory temp = META_DATA(
            stakeAmount,
            block.timestamp,
            block.timestamp
        );
        tokenStakeData[msg.sender][lockType].push(temp);

        tokenStakeAmount[lockType] = tokenStakeAmount[lockType] + stakeAmount;
    }

    function lpStake(uint256 amount, uint8 lockType) external {
        require(amount > 0 && lockType <= 6, "Invalid arguments.");
        goldLP.transferFrom(msg.sender, address(this), amount);

        META_DATA memory temp = META_DATA(
            amount,
            block.timestamp,
            block.timestamp
        );
        lpStakeData[msg.sender][lockType].push(temp);

        lpStakeAmount[lockType] = lpStakeAmount[lockType] + amount;
    }

    function tokenStakeReward(
        address user,
        uint8 lockType,
        uint256 index,
        bool claim
    ) public view returns (uint256) {
        require(
            index < tokenStakeData[user][lockType].length,
            "Invalid claim index"
        );
        META_DATA memory temp = tokenStakeData[user][lockType][index];

        uint256 lastTime = claim ? temp.claimTime : temp.stakeTime;
        return
            (((temp.amount * tokenStakeAPR[lockType]) / 100) *
                (block.timestamp - lastTime)) / 360 days;
    }

    function lpStakeReward(
        address user,
        uint8 lockType,
        uint256 index,
        bool claim
    ) public view returns (uint256) {
        require(
            index < lpStakeData[user][lockType].length,
            "Invalid claim index"
        );
        META_DATA memory temp = lpStakeData[user][lockType][index];

        uint256 tokenPrice = getTokenPrice();
        uint256 lpPrice = getLpPrice();

        uint256 lastTime = claim ? temp.claimTime : temp.stakeTime;
        return
            (((((temp.amount * lpPrice) / tokenPrice) * lpStakeAPR[lockType]) /
                100) * (block.timestamp - lastTime)) / 360 days;
    }

    function availableRewardAmount() internal view returns (uint256) {
        return
            goldToken.balanceOf(address(this)) -
            tokenStakeAmount[0] -
            tokenStakeAmount[1] -
            tokenStakeAmount[2] -
            tokenStakeAmount[3] -
            tokenStakeAmount[4] -
            tokenStakeAmount[5];
    }

    function tokenClaim(uint8 lockType, uint256 index) external {
        require(
            index < tokenStakeData[msg.sender][lockType].length,
            "Invalid claim index"
        );

        META_DATA storage temp = tokenStakeData[msg.sender][lockType][index];
        uint256 originReward = tokenStakeReward(
            msg.sender,
            lockType,
            index,
            true
        );

        uint256 nextClaimableTime = temp.claimTime + lockTerm[lockType];
        if (lockType == 0 || nextClaimableTime <= block.timestamp)
            goldToken.transfer(
                msg.sender,
                Math.min(originReward, availableRewardAmount())
            );
        else {
            goldToken.transfer(
                msg.sender,
                Math.min(
                    (originReward * penaltyForEarlyClaim[lockType]) / 100,
                    availableRewardAmount()
                )
            );
        }
        temp.claimTime = block.timestamp;
    }

    function lpClaim(uint8 lockType, uint256 index) external {
        require(
            index < lpStakeData[msg.sender][lockType].length,
            "Invalid claim index"
        );

        META_DATA storage temp = lpStakeData[msg.sender][lockType][index];
        uint256 originReward = lpStakeReward(msg.sender, lockType, index, true);

        uint256 nextClaimableTime = temp.claimTime + lockTerm[lockType];
        if (lockType == 0 || nextClaimableTime <= block.timestamp)
            goldToken.transfer(
                msg.sender,
                Math.min(originReward, availableRewardAmount())
            );
        else {
            goldToken.transfer(
                msg.sender,
                Math.min(
                    (originReward * penaltyForEarlyClaim[lockType]) / 100,
                    availableRewardAmount()
                )
            );
        }
        temp.claimTime = block.timestamp;
    }

    function tokenUnstake(
        uint256 amount,
        uint8 lockType,
        uint256 index
    ) external {
        require(amount > 0, "Amount should be not 0.");
        require(
            index < tokenStakeData[msg.sender][lockType].length,
            "Invalid claim index"
        );

        META_DATA storage temp = tokenStakeData[msg.sender][lockType][index];
        require(amount <= temp.amount, "Amount exceeds staking amount.");

        uint256 originReward = tokenStakeReward(
            msg.sender,
            lockType,
            index,
            false
        );
        originReward = (originReward * amount) / temp.amount;

        uint256 nextClaimableTime = temp.stakeTime + lockTerm[lockType];
        if (lockType == 0 || nextClaimableTime <= block.timestamp)
            goldToken.transfer(
                msg.sender,
                Math.min(originReward, availableRewardAmount()) + amount
            );
        else
            goldToken.transfer(
                msg.sender,
                Math.min(
                    (originReward * penaltyForEarlyClaim[lockType]) / 100,
                    availableRewardAmount()
                ) + amount
            );

        temp.amount = temp.amount - amount;
        tokenStakeAmount[lockType] = tokenStakeAmount[lockType] - amount;
    }

    function lpUnstake(
        uint256 amount,
        uint8 lockType,
        uint256 index
    ) external {
        require(amount > 0, "Amount should be not 0.");
        require(
            index < lpStakeData[msg.sender][lockType].length,
            "Invalid claim index"
        );

        META_DATA storage temp = lpStakeData[msg.sender][lockType][index];
        require(amount <= temp.amount, "Amount exceeds staking amount.");

        uint256 originReward = lpStakeReward(
            msg.sender,
            lockType,
            index,
            false
        );
        originReward = (originReward * amount) / temp.amount;

        uint256 nextClaimableTime = temp.stakeTime + lockTerm[lockType];
        if (lockType == 0 || nextClaimableTime <= block.timestamp)
            goldToken.transfer(
                msg.sender,
                Math.min(originReward, availableRewardAmount())
            );
        else
            goldToken.transfer(
                msg.sender,
                Math.min(
                    (originReward * penaltyForEarlyClaim[lockType]) / 100,
                    availableRewardAmount()
                )
            );

        temp.amount = temp.amount - amount;
        lpStakeAmount[lockType] = lpStakeAmount[lockType] - amount;

        goldLP.transfer(msg.sender, amount);
    }
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

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
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

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract PriceConsumerV3 {
    AggregatorV3Interface internal priceFeed;

    /**
     * Network: Goerli
     * Aggregator: ETH/USD
     * Address: 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
     */
    constructor() {
        priceFeed = AggregatorV3Interface(
            0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        );
    }

    /**
     * Returns the latest price
     */
    function getLatestPrice() public view returns (int) {
        (
            ,
            /*uint80 roundID*/ int price /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/,
            ,
            ,

        ) = priceFeed.latestRoundData();
        return price;
    }
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
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}