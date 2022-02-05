// SPDX-License-Identifier: MIT
pragma solidity 0.7.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

interface IMonster {
    function getMonsterInfo(uint256 monsterId) external view returns(uint256, uint256, uint256);
    function getMonsterToHunt(uint256 ap) external view returns (uint256);
}

contract Monster is IMonster {
    using SafeMath for uint256;
    address public legion;
    address public rewardpool;
    string public baseGifUrl = "https://gateway.pinata.cloud/ipfs/QmcXzv8YAVctL8maUdB83sruPBkV2i7WdRNvxLfvbdnagF";
    string public baseJpgUrl = "https://gateway.pinata.cloud/ipfs/QmfX6GLJBGpQBfDRCnqUgTuQkFTp1BaM65F9QHxLNBZUJE";
    struct Monster {
        uint256 percent;
        uint256 attack_power;
        uint256 reward;
    }
    mapping (uint256 => Monster) monsterData;
    modifier onlyLegion() {
        require(msg.sender == legion); _;
    }

    constructor (address _rewardpool) {
        legion = msg.sender;
        rewardpool = _rewardpool;
        initiateMonsterData();
    }

    function initiateMonsterData() internal {
        monsterData[1].percent = 85;
        monsterData[1].attack_power = 2000;
        monsterData[1].reward = 65;
        monsterData[2].percent = 82;
        monsterData[2].attack_power = 5000;
        monsterData[2].reward = 160;
        monsterData[3].percent = 78;
        monsterData[3].attack_power = 8000;
        monsterData[3].reward = 260;
        monsterData[4].percent = 75;
        monsterData[4].attack_power = 10000;
        monsterData[4].reward = 325;
        monsterData[5].percent = 72;
        monsterData[5].attack_power = 13000;
        monsterData[5].reward = 440;
        monsterData[6].percent = 68;
        monsterData[6].attack_power = 17000;
        monsterData[6].reward = 605;
        monsterData[7].percent = 65;
        monsterData[7].attack_power = 20000;
        monsterData[7].reward = 740;
        monsterData[8].percent = 62;
        monsterData[8].attack_power = 22000;
        monsterData[8].reward = 850;
        monsterData[9].percent = 59;
        monsterData[9].attack_power = 25000;
        monsterData[9].reward = 1010;
        monsterData[10].percent = 55;
        monsterData[10].attack_power = 28000;
        monsterData[10].reward = 1210;
        monsterData[11].percent = 52;
        monsterData[11].attack_power = 31000;
        monsterData[11].reward = 1410;
        monsterData[12].percent = 49;
        monsterData[12].attack_power = 34000;
        monsterData[12].reward = 1620;
        monsterData[13].percent = 45;
        monsterData[13].attack_power = 37000;
        monsterData[13].reward = 1900;
        monsterData[14].percent = 42;
        monsterData[14].attack_power = 40000;
        monsterData[14].reward = 2150;
        monsterData[15].percent = 41;
        monsterData[15].attack_power = 42000;
        monsterData[15].reward = 2450;
        monsterData[16].percent = 41;
        monsterData[16].attack_power = 47000;
        monsterData[16].reward = 2950;
        monsterData[17].percent = 41;
        monsterData[17].attack_power = 50000;
        monsterData[17].reward = 3250;
        monsterData[18].percent = 39;
        monsterData[18].attack_power = 53000;
        monsterData[18].reward = 3800;
        monsterData[19].percent = 39;
        monsterData[19].attack_power = 56000;
        monsterData[19].reward = 4300;
        monsterData[20].percent = 39;
        monsterData[20].attack_power = 60000;
        monsterData[20].reward = 4900;
        monsterData[21].percent = 35;
        monsterData[21].attack_power = 250000;
        monsterData[21].reward = 23000;
        monsterData[22].percent = 30;
        monsterData[22].attack_power = 300000;
        monsterData[22].reward = 33000;
    }
    
    function getMonsterInfo(uint256 monsterId) external override view returns(uint256, uint256, uint256) {
        require(monsterId>0&&monsterId<23, "Monster is not registered");
        return (monsterData[monsterId].percent, monsterData[monsterId].attack_power, monsterData[monsterId].reward);
    }

    function getMonsterToHunt(uint256 ap) external override view onlyLegion returns (uint256) {
        uint256 retVal = 0;
        for(uint i=1;i<23;i++) {
            if(ap<=monsterData[i].attack_power) continue;
            retVal = i;
            break;
        }
        return retVal;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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