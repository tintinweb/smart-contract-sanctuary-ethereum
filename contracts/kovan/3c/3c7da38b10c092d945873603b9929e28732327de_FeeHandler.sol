// SPDX-License-Identifier: MIT
pragma solidity 0.7.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./IFeeHandler.sol";

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IDEXRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function getAmountsOut(
        uint256 amountIn,
        address[] calldata path
    ) external pure returns(uint256[] memory);
}

contract FeeHandler is IFeeHandler {
    /*
        Marketplace tax,
        Hunting tax,
        Damage for legions,
        Summon fee,
        14 Days Hunting Supplies Discounted Fee,
        28 Days Hunting Supplies Discounted Fee
    */
    
    using SafeMath for uint256;
    address constant BUSD = 0x07de306FF27a2B630B1141956844eB1552B956B5;
    address constant BLST = 0xd8344cc7fEbce19C2182988Ad219cF3553664356;
    uint[6] fees = [1500,250,100,18,13,24];
    address legion;
    IDEXRouter public router;
    modifier onlyLegion() {
        require(msg.sender == legion); _;
    }
    constructor() {
        legion = msg.sender;
        router = IDEXRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    }
    function getFee(uint8 _index) external view override returns (uint) {
        return fees[_index];
    }
    function setFee(uint _fee, uint8 _index) external override onlyLegion {
        require(_index>=0 && _index<6, "Unknown fee type");
        fees[_index] = _fee;
    }

    function getSummoningPrice(uint256 _amount) external view override returns(uint256) {
        uint256 UsdValue = fees[3];
        uint256 amountIn;
        if(_amount==1) {
            amountIn = UsdValue;
        } else if(_amount==10) {
            amountIn = UsdValue.mul(10).mul(99).div(100);
        } else if(_amount==50) {
            amountIn = UsdValue.mul(50).mul(97).div(100);
        } else if(_amount==200) {
            amountIn = UsdValue.mul(200).mul(95).div(100);
        } else if(_amount==500) {
            amountIn = UsdValue.mul(500).mul(90).div(100);
        } else {
            amountIn = UsdValue.mul(_amount);
        }
        return getBLSTAmount(amountIn);
    }
    function getTrainingCost(uint256 _count) external view override returns(uint256) {
        address[] memory path = new address[](2);
        path[0] = BUSD;
        path[1] = BLST;
        return router.getAmountsOut(_count*(10**6)/2, path)[1];
    }
    function getSupplyCost(uint256 _warriorCount, uint256 _supply) external view override returns(uint256) {
        if(_supply==7) {
            return getBLSTAmount(7*_warriorCount);
        } else if(_supply==14) {
            return getBLSTAmount(fees[4]*_warriorCount);
        } else if (_supply==28) {
            return getBLSTAmount(fees[5]*_warriorCount);
        } else {
            return getBLSTAmount(_supply*_warriorCount);
        }
    }
    function getCostForAddingWarrior(uint256 _warriorCount, uint256 _remainingHunts) external view override returns(uint256) {
        address[] memory path = new address[](2);
        path[0] = BUSD;
        path[1] = BLST;
        uint256 cost = router.getAmountsOut((_remainingHunts*_warriorCount)*10**6+_warriorCount*10**6/2, path)[1];
        return cost;
    }
    function getBLSTAmountFromUSD(uint256 _usd) external view override returns(uint256) {
        return getBLSTAmount(_usd);
    }
    function getBLSTAmount(uint256 _usd) internal view returns(uint256) {
        address[] memory path = new address[](2);
        path[0] = BUSD;
        path[1] = BLST;
        return router.getAmountsOut(_usd*10**6, path)[1];
    }
}

// SPDX-License-Identifier: MIT

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
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
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
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.0;

interface IFeeHandler {
    function getFee(uint8 _index) external view returns(uint);
    function setFee(uint _fee, uint8 _index) external;
    function getSummoningPrice(uint256 _amount) external view returns(uint256);
    function getTrainingCost(uint256 _count) external view returns(uint256);
    function getBLSTAmountFromUSD(uint256 _usd) external view returns(uint256);
    function getSupplyCost(uint256 _warriorCount, uint256 _supply) external view returns(uint256);
    function getCostForAddingWarrior(uint256 _warriorCount, uint256 _remainingHunts) external view returns(uint256);
}