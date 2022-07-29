/**
 *Submitted for verification at Etherscan.io on 2022-07-29
*/

// File: @uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

// File: @uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol

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

// File: lib/SafeMath.sol



pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// File: interface/IERC20.sol


pragma solidity ^0.6.12;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Returns the amount of decimals of the token
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// File: oracles/UniswapV2TwapPriceOracleRoot.sol


pragma solidity ^0.6.12;





/**
 * @title UniswapV2TwapPriceOracleRoot
 * @notice Stores cumulative prices and returns TWAPs for assets on Uniswap V2 pairs.
 */
contract UniswapV2TwapPriceOracleRoot {
    using SafeMath for uint256;

    /**
     * @dev Minimum TWAP interval.
     */
    uint256 public constant MIN_TWAP_TIME = 15 minutes;

    address public immutable WETH;

    /*
    mainnet: _WETH        : 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
    kovan:   _WETH        : 0xd0A1E359811322d97991E03f863a0C30C2cF029C
    */

    constructor(address _WETH) public {
        WETH = _WETH;
    }

    /**
     * @dev Return the TWAP value price0. Revert if TWAP time range is not within the threshold.
     * Copied from: https://github.com/AlphaFinanceLab/homora-v2/blob/master/contracts/oracle/BaseKP3ROracle.sol
     * @param pair The pair to query for price0.
     */
    function price0TWAP(address pair) internal view returns (uint256) {
        uint256 length = observationCount[pair];
        require(length > 0, "No length-1 TWAP observation.");
        Observation memory lastObservation = observations[pair][
            (length - 1) % OBSERVATION_BUFFER
        ];
        if (lastObservation.timestamp > now - MIN_TWAP_TIME) {
            require(length > 1, "No length-2 TWAP observation.");
            lastObservation = observations[pair][
                (length - 2) % OBSERVATION_BUFFER
            ];
        }
        uint256 elapsedTime = now - lastObservation.timestamp;
        require(elapsedTime >= MIN_TWAP_TIME, "Bad TWAP time.");
        uint256 currPx0Cumu = currentPx0Cumu(pair);
        return
            (currPx0Cumu - lastObservation.price0Cumulative) /
            (now - lastObservation.timestamp); // overflow is desired
    }

    /**
     * @dev Return the TWAP value price1. Revert if TWAP time range is not within the threshold.
     * Copied from: https://github.com/AlphaFinanceLab/homora-v2/blob/master/contracts/oracle/BaseKP3ROracle.sol
     * @param pair The pair to query for price1.
     */
    function price1TWAP(address pair) internal view returns (uint256) {
        uint256 length = observationCount[pair];
        require(length > 0, "No length-1 TWAP observation.");
        Observation memory lastObservation = observations[pair][
            (length - 1) % OBSERVATION_BUFFER
        ];
        if (lastObservation.timestamp > now - MIN_TWAP_TIME) {
            require(length > 1, "No length-2 TWAP observation.");
            lastObservation = observations[pair][
                (length - 2) % OBSERVATION_BUFFER
            ];
        }
        uint256 elapsedTime = now - lastObservation.timestamp;
        require(elapsedTime >= MIN_TWAP_TIME, "Bad TWAP time.");
        uint256 currPx1Cumu = currentPx1Cumu(pair);
        return
            (currPx1Cumu - lastObservation.price1Cumulative) /
            (now - lastObservation.timestamp); // overflow is desired
    }

    /**
     * @dev Return the current price0 cumulative value on Uniswap.
     * Copied from: https://github.com/AlphaFinanceLab/homora-v2/blob/master/contracts/oracle/BaseKP3ROracle.sol
     * @param pair The uniswap pair to query for price0 cumulative value.
     */
    function currentPx0Cumu(address pair)
        internal
        view
        returns (uint256 px0Cumu)
    {
        uint32 currTime = uint32(now);
        px0Cumu = IUniswapV2Pair(pair).price0CumulativeLast();
        (uint256 reserve0, uint256 reserve1, uint32 lastTime) = IUniswapV2Pair(
            pair
        ).getReserves();
        if (lastTime != now) {
            uint32 timeElapsed = currTime - lastTime; // overflow is desired
            px0Cumu += uint256((reserve1 << 112) / reserve0) * timeElapsed; // overflow is desired
        }
    }

    /**
     * @dev Return the current price1 cumulative value on Uniswap.
     * Copied from: https://github.com/AlphaFinanceLab/homora-v2/blob/master/contracts/oracle/BaseKP3ROracle.sol
     * @param pair The uniswap pair to query for price1 cumulative value.
     */
    function currentPx1Cumu(address pair)
        internal
        view
        returns (uint256 px1Cumu)
    {
        uint32 currTime = uint32(now);
        px1Cumu = IUniswapV2Pair(pair).price1CumulativeLast();
        (uint256 reserve0, uint256 reserve1, uint32 lastTime) = IUniswapV2Pair(
            pair
        ).getReserves();
        if (lastTime != currTime) {
            uint32 timeElapsed = currTime - lastTime; // overflow is desired
            px1Cumu += uint256((reserve0 << 112) / reserve1) * timeElapsed; // overflow is desired
        }
    }

    /**
     * @dev Returns the price of `underlying` in terms of `baseToken` given `factory`.
     */
    function price(address underlying, address factory)
        external
        view
        returns (uint256)
    {
        // Return ERC20/ETH TWAP
        address baseToken = WETH;
        address pair = IUniswapV2Factory(factory).getPair(
            underlying,
            baseToken
        );
        // Return 0 if pair not found
        if (address(pair) == address(0)) return 0;

        uint256 baseUnit = 10**uint256(IERC20(underlying).decimals());
        return
            (underlying < baseToken ? price0TWAP(pair) : price1TWAP(pair))
                .div(2**56)
                .mul(baseUnit)
                .div(2**56); // Scaled by 1e18, not 2 ** 112
    }

    /**
     * @dev Struct for cumulative price observations.
     */
    struct Observation {
        uint32 timestamp;
        uint256 price0Cumulative;
        uint256 price1Cumulative;
    }

    /**
     * @dev Length after which observations roll over to index 0.
     */
    uint8 public constant OBSERVATION_BUFFER = 4;

    /**
     * @dev Total observation count for each pair.
     */
    mapping(address => uint256) public observationCount;

    /**
     * @dev Array of cumulative price observations for each pair.
     */
    mapping(address => Observation[OBSERVATION_BUFFER]) public observations;

    /// @notice Get pairs for token combinations.
    function pairsFor(
        address[] calldata tokenA,
        address[] calldata tokenB,
        address factory
    ) external view returns (address[] memory) {
        require(
            tokenA.length > 0 && tokenA.length == tokenB.length,
            "Token array lengths must be equal and greater than 0."
        );
        address[] memory pairs = new address[](tokenA.length);
        for (uint256 i = 0; i < tokenA.length; i++)
            pairs[i] = IUniswapV2Factory(factory).getPair(tokenA[i], tokenB[i]);
        return pairs;
    }

    /// @notice Check which of multiple pairs are workable/updatable.
    function workable(
        address[] calldata pairs,
        address[] calldata baseTokens,
        uint256[] calldata minPeriods,
        uint256[] calldata deviationThresholds
    ) external view returns (bool[] memory) {
        require(
            pairs.length > 0 &&
                pairs.length == baseTokens.length &&
                pairs.length == minPeriods.length &&
                pairs.length == deviationThresholds.length,
            "Array lengths must be equal and greater than 0."
        );
        bool[] memory answers = new bool[](pairs.length);
        for (uint256 i = 0; i < pairs.length; i++)
            answers[i] = _workable(
                pairs[i],
                baseTokens[i],
                minPeriods[i],
                deviationThresholds[i]
            );
        return answers;
    }

    /// @dev Internal function to check if a pair is workable (updateable AND reserves have changed AND deviation threshold is satisfied).
    function _workable(
        address pair,
        address baseToken,
        uint256 minPeriod,
        uint256 deviationThreshold
    ) internal view returns (bool) {
        // Workable if:
        // 1) We have no observations
        // 2) The elapsed time since the last observation is > minPeriod AND reserves have changed AND deviation threshold is satisfied
        // Note that we loop observationCount[pair] around OBSERVATION_BUFFER so we don't waste gas on new storage slots
        if (observationCount[pair] <= 0) return true;
        (, , uint32 lastTime) = IUniswapV2Pair(pair).getReserves();
        return
            (block.timestamp -
                observations[pair][
                    (observationCount[pair] - 1) % OBSERVATION_BUFFER
                ].timestamp) >
            (minPeriod >= MIN_TWAP_TIME ? minPeriod : MIN_TWAP_TIME) &&
            lastTime !=
            observations[pair][
                (observationCount[pair] - 1) % OBSERVATION_BUFFER
            ].timestamp &&
            _deviation(pair, baseToken) >= deviationThreshold;
    }

    /// @dev Internal function to check if a pair's spot price's deviation from its TWAP price as a ratio scaled by 1e18
    function _deviation(address pair, address baseToken)
        internal
        view
        returns (uint256)
    {
        // Get token base unit
        address token0 = IUniswapV2Pair(pair).token0();
        bool useToken0Price = token0 != baseToken;
        address underlying = useToken0Price
            ? token0
            : IUniswapV2Pair(pair).token1();
        uint256 baseUnit = 10**uint256(IERC20(underlying).decimals());

        // Get TWAP price
        uint256 twapPrice = (
            useToken0Price ? price0TWAP(pair) : price1TWAP(pair)
        ).div(2**56).mul(baseUnit).div(2**56); // Scaled by 1e18, not 2 ** 112

        // Get spot price
        (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(pair)
            .getReserves();
        uint256 spotPrice = useToken0Price
            ? reserve1.mul(baseUnit).div(reserve0)
            : reserve0.mul(baseUnit).div(reserve1);

        // Get ratio and return deviation
        uint256 ratio = spotPrice.mul(1e18).div(twapPrice);
        return ratio >= 1e18 ? ratio - 1e18 : 1e18 - ratio;
    }

    /// @dev Internal function to check if a pair is updatable at all.
    function _updateable(address pair) internal view returns (bool) {
        // Updateable if:
        // 1) We have no observations
        // 2) The elapsed time since the last observation is > MIN_TWAP_TIME
        // Note that we loop observationCount[pair] around OBSERVATION_BUFFER so we don't waste gas on new storage slots
        return
            observationCount[pair] <= 0 ||
            (block.timestamp -
                observations[pair][
                    (observationCount[pair] - 1) % OBSERVATION_BUFFER
                ].timestamp) >
            MIN_TWAP_TIME;
    }

    /// @notice Update one pair.
    function update(address pair) external {
        require(_update(pair), "Failed to update pair.");
    }

    /// @notice Update multiple pairs at once.
    function update(address[] calldata pairs) external {
        bool worked = false;
        for (uint256 i = 0; i < pairs.length; i++)
            if (_update(pairs[i])) worked = true;
        require(worked, "No pairs can be updated (yet).");
    }

    /// @dev Internal function to update a single pair.
    function _update(address pair) internal returns (bool) {
        // Check if workable
        if (!_updateable(pair)) return false;

        // Get cumulative price(s)
        uint256 price0Cumulative = IUniswapV2Pair(pair).price0CumulativeLast();
        uint256 price1Cumulative = IUniswapV2Pair(pair).price1CumulativeLast();

        // Loop observationCount[pair] around OBSERVATION_BUFFER so we don't waste gas on new storage slots
        (, , uint32 lastTime) = IUniswapV2Pair(pair).getReserves();
        observations[pair][
            observationCount[pair] % OBSERVATION_BUFFER
        ] = Observation(lastTime, price0Cumulative, price1Cumulative);
        observationCount[pair]++;
        return true;
    }
}