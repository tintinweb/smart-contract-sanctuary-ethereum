// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

interface IERC20BettingToken {
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function balanceOfAt(address account, uint256 snapshotId) external view returns (uint256);
    function totalSupplyAt(uint256 snapshotId) external view returns (uint256);
    function decimals() external view returns (uint);
    function snapshot() external returns(uint256);
    function unpause() external;
    function pause() external;
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function unpauseExceptSelling() external;
    function setPoolAddress(address pool) external;
    function isPaused() external view returns(bool);
    function name() external view returns(string memory);
    function symbol() external view returns(string memory);
}

import "../libraries/SharedStructs.sol";

interface IPredictionMarketManager{

    function getMatchData(uint256 betId) external view returns(SharedStructs.Match memory);
    function feePercent() external view returns(uint256);
}

interface IUniswapV2Pair {
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

pragma solidity 0.8.17;

library SharedStructs {
    struct Match {
        uint256 startDate; // the date the token was deployed
        Player player1;
        Player player2;
        string status;
        uint256 matchID; // lockID nonce per uni pair
        address owner;
        uint256 matchResult;
    }

    struct PlayerStats {
        address token;
        address pool;
        string tokenName;
        string tokenSymbol;
        uint256 price;
        uint256 amountToken0;
        uint256 amountToken1;
        uint32 timestampLast;
        uint256 marketcap;
        uint256 liquidityAmount;
        uint256 prizePerUnit;
        uint256 circulationSupply;
        bool traded;
    }

    struct Player {
        address lpToken;
        address token;
        uint256 amountLp;
        uint256 initialStableAmount;
        uint256 snapshotId;
    }
}

// SPDX-License-Identifier: UNLICENSED

// This contract locks uniswap v2 liquidity tokens pairs with a betting parameter. the wining side will be able to claim the losing side liquidity tokens

pragma solidity 0.8.17;
pragma experimental ABIEncoderV2;

import "./interfaces/IPredictionMarketManager.sol";
import "./libraries/SharedStructs.sol";
import "./interfaces/IUniswapV2Pair.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./interfaces/IERC20BettingToken.sol";

contract PMHelper {
    using SafeMath for uint256;

    IPredictionMarketManager pmManager;

    constructor(IPredictionMarketManager _predictionMarketManager) public {
        pmManager = _predictionMarketManager;

    }

    /**
       * @notice get the current total prize for each team
   * @param _betId the id of the lock bet
   */
    function getCurrentTotalPrizes(uint256 _betId) public view returns (uint256, uint256) {
        uint256 totalPrizeA;
        uint256 totalPrizeB;
        SharedStructs.Match memory matchData = pmManager.getMatchData(_betId);

        address stableCoin = IUniswapV2Pair(matchData.player1.lpToken).token1();
        if(stableCoin == matchData.player1.token){
            stableCoin =  IUniswapV2Pair(matchData.player1.lpToken).token0();
        }

        if(matchData.matchResult == 0){

            totalPrizeA = IERC20BettingToken(stableCoin).balanceOf(matchData.player2.lpToken).sub(matchData.player2.initialStableAmount);
            totalPrizeB = IERC20BettingToken(stableCoin).balanceOf(matchData.player1.lpToken).sub(matchData.player1.initialStableAmount);

        }else if(matchData.matchResult == 1){
            totalPrizeA = IERC20BettingToken(stableCoin).balanceOf(matchData.player2.lpToken);
            totalPrizeB = 0;

        }else if(matchData.matchResult == 2){
            totalPrizeA = 0;
            totalPrizeB = IERC20BettingToken(stableCoin).balanceOf(matchData.player1.lpToken);

        }

        //remove fee
//        uint256 fee = 0;
//        uint256 feePercent = pmManager.feePercent();
//        if(feePercent > 0){
//            if(totalPrizeA > 0){
//                fee = totalPrizeA.mul(feePercent).div(10000);
//                totalPrizeA = totalPrizeA.sub(fee);
//            }
//            if(totalPrizeB > 0){
//                fee = totalPrizeB.mul(feePercent).div(10000);
//                totalPrizeB = totalPrizeB.sub(fee);
//            }
//        }

        return (totalPrizeA, totalPrizeB);

    }

    /**
       * @notice retruns stats of a match
   * @param _betId the id of the lock bet
   */
    function getStats(uint256 _betId) external view returns (SharedStructs.PlayerStats memory, SharedStructs.PlayerStats memory,uint256 result,string memory status) {
        SharedStructs.Match memory matchData = pmManager.getMatchData(_betId);
        require(matchData.player1.lpToken != address(0x0000000000000000000000000000000000000000),"match id is not exist");
        (uint256 prizeA,uint256 prizeB) = getCurrentTotalPrizes(_betId);
        SharedStructs.PlayerStats memory statsA;
        address pool = matchData.player1.lpToken;
        statsA.token = matchData.player1.token;
        statsA.pool = matchData.player1.lpToken;

        (statsA.amountToken0,statsA.amountToken1,statsA.timestampLast) = IUniswapV2Pair(pool).getReserves();

        uint256 tokenDecimals = IERC20BettingToken(statsA.token).decimals();
        address stableAddress;

        if(statsA.token == IUniswapV2Pair(pool).token0()){
            stableAddress = IUniswapV2Pair(pool).token1();
        }else{
            stableAddress = IUniswapV2Pair(pool).token0();
            uint256 amountStables = statsA.amountToken0;
            statsA.amountToken1 = statsA.amountToken0;
            statsA.amountToken0 = amountStables;
        }

        uint256 decimalsDiff = tokenDecimals.sub(IERC20BettingToken(stableAddress).decimals());
        uint256 amountStable = IERC20BettingToken(stableAddress).balanceOf(statsA.pool);
        uint256 amountToken = IERC20BettingToken(statsA.token).balanceOf(statsA.pool);
        uint256 amountStableAfterDecimals = amountStable.mul(10 ** decimalsDiff);
        statsA.price = amountStableAfterDecimals.mul(1000000000).div(amountToken);
        statsA.marketcap = statsA.price * IERC20BettingToken(statsA.token).totalSupply().div(1000000000);
        statsA.traded = !IERC20BettingToken(statsA.token).isPaused();
        statsA.tokenName = IERC20BettingToken(statsA.token).name();
        statsA.tokenSymbol = IERC20BettingToken(statsA.token).symbol();
        statsA.circulationSupply = IERC20BettingToken(statsA.token).totalSupply().sub(IERC20BettingToken(statsA.token).balanceOf(statsA.pool));
        statsA.liquidityAmount = IERC20BettingToken(stableAddress).balanceOf(statsA.pool).mul(2);

        if(statsA.circulationSupply > 0){
            statsA.prizePerUnit = prizeA.mul(1000000000).div(statsA.circulationSupply);
        }else{
            statsA.prizePerUnit = prizeA.mul(1000000000);
        }

        SharedStructs.PlayerStats memory statsB;
        pool = matchData.player2.lpToken;
        statsB.token = matchData.player2.token;
        statsB.pool = pool;
        (statsB.amountToken0,statsB.amountToken1,statsB.timestampLast) = IUniswapV2Pair(pool).getReserves();
        tokenDecimals = IERC20BettingToken(statsB.token).decimals();

        if(statsB.token == IUniswapV2Pair(statsB.pool).token0()){
            stableAddress = IUniswapV2Pair(statsB.pool).token1();
        }else{
            stableAddress = IUniswapV2Pair(statsB.pool).token0();
            uint256 amountStables = statsB.amountToken0;
            statsB.amountToken1 = statsB.amountToken0;
            statsB.amountToken0 = amountStables;
        }
        decimalsDiff = tokenDecimals.sub(IERC20BettingToken(stableAddress).decimals());
        amountStable = IERC20BettingToken(stableAddress).balanceOf(statsB.pool);
        amountToken = IERC20BettingToken(statsB.token).balanceOf(statsB.pool);
        amountStableAfterDecimals = amountStable.mul(10 ** decimalsDiff);
        statsB.price = amountStableAfterDecimals.mul(1000000000).div(amountToken);
        statsB.marketcap = statsB.price * IERC20BettingToken(statsB.token).totalSupply().div(1000000000);
        statsB.traded = !IERC20BettingToken(statsB.token).isPaused();
        statsB.tokenName = IERC20BettingToken(statsB.token).name();
        statsB.tokenSymbol = IERC20BettingToken(statsB.token).symbol();
        statsB.circulationSupply = IERC20BettingToken(statsB.token).totalSupply().sub(IERC20BettingToken(statsB.token).balanceOf(statsB.pool));
        statsB.liquidityAmount = IERC20BettingToken(stableAddress).balanceOf(statsB.pool).mul(2);

        if(statsB.circulationSupply > 0){
            statsB.prizePerUnit = prizeB.mul(1000000000).div(statsB.circulationSupply);
        }else{
            statsB.prizePerUnit = prizeB.mul(1000000000);
        }
        return(statsA, statsB, matchData.matchResult, matchData.status);
    }

}