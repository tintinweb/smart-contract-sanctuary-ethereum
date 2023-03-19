/**
 *Submitted for verification at Etherscan.io on 2023-03-19
*/

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

pragma solidity ^0.8.0;

contract BitCoin {
using SafeMath for uint256;

string public name = "Bit Coin";
string public symbol = "BTC";
uint256 public totalSupply = 10000 * 10 ** 18;
uint8 public decimals = 18;

address public marketingAddress = 0x6bAf3Cff4990Ab11BcD83b3904dd1640e1d79067;
address public owner;

uint256 private constant MAX_FEE = 100; // 10%
uint256 private constant FEE_DENOMINATOR = 10000;

uint256 private addLiquidityFee = 200; // 2%
uint256 private marketingFee = 200; // 2%
uint256 private burnFee = 400; // 4%

mapping(address => uint256) public balanceOf;
mapping(address => mapping(address => uint256)) public allowance;

event Transfer(address indexed from, address indexed to, uint256 value);
event Approval(address indexed owner, address indexed spender, uint256 value);

constructor() {
    owner = msg.sender;
    balanceOf[msg.sender] = totalSupply;
}

function setFees(uint256 _addLiquidityFee, uint256 _marketingFee, uint256 _burnFee) external {
    require(msg.sender == owner, "Only owner can set fees");
    require(_addLiquidityFee.add(_marketingFee).add(_burnFee) <= MAX_FEE, "Fees too high");

    addLiquidityFee = _addLiquidityFee;
    marketingFee = _marketingFee;
    burnFee = _burnFee;
}

function transfer(address _to, uint256 _value) external returns (bool success) {
    _transfer(msg.sender, _to, _value);
    return true;
}

function approve(address _spender, uint256 _value) external returns (bool success) {
    allowance[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
}

function transferFrom(address _from, address _to, uint256 _value) external returns (bool success) {
    require(_value <= balanceOf[_from], "Insufficient balance");
    require(_value <= allowance[_from][msg.sender], "Insufficient allowance");

    allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
    _transfer(_from, _to, _value);
    return true;
}

function _transfer(address _from, address _to, uint256 _value) internal {
    require(_to != address(0), "Cannot transfer to zero address");
    require(_value > 0, "Transfer value must be greater than zero");
    require(balanceOf[_from] >= _value, "Insufficient balance");

    uint256 fee = calculateFee(_value);
    uint256 burnAmount = calculateBurnAmount(fee);
uint256 feeHalf = fee.div(2);

    balanceOf[_from] = balanceOf[_from].sub(_value);
    balanceOf[_to] = balanceOf[_to].add(_value).sub(fee);

    if (burnAmount > 0) {
        uint256 zeroAddressBalance = balanceOf[address(0)];
        balanceOf[address(0)] = zeroAddressBalance.add(burnAmount);
        emit Transfer(_from, address(0), burnAmount);
    }

    if (fee > 0) {
        uint256 marketingFeeAmount = feeHalf;
        uint256 ownerFeeAmount = fee.sub(marketingFeeAmount);

        balanceOf[marketingAddress] = balanceOf[marketingAddress].add(marketingFeeAmount);
        emit Transfer(_from, marketingAddress, marketingFeeAmount);

        balanceOf[owner] = balanceOf[owner].add(ownerFeeAmount);
        emit Transfer(_from, owner, ownerFeeAmount);
    }

    emit Transfer(_from, _to, _value.sub(fee));
}

function calculateFee(uint256 _value) public view returns (uint256) {
    return _value.mul(addLiquidityFee.add(marketingFee).add(burnFee)).div(FEE_DENOMINATOR);
}

function calculateBurnAmount(uint256 _fee) public view returns (uint256) {
    uint256 zeroAddressBalance = balanceOf[address(this)];
    return _fee.mul(zeroAddressBalance).div(totalSupply);
}
}