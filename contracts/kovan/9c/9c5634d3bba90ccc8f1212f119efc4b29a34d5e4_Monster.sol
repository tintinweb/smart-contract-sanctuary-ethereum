// SPDX-License-Identifier: MIT
pragma solidity 0.7.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

interface IMonster {
    function getMonsterInfo(uint256 monsterId) external view returns(uint256, uint256, uint256, string memory, string memory);
    function getMonsterToHunt(uint256 ap) external view returns (uint256);
}

contract Monster is IMonster {
    using SafeMath for uint256;
    
    address public legion;
    address public rewardpool;
    struct Monster {
        uint256 percent;
        uint256 attack_power;
        uint256 reward;
        string jpg;
        string gif;
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
        monsterData[1].jpg = "QmaVaMWogFQwuABYq8tEdqAuYzQVJuMrcDSkvgjhgFGHJc";
        monsterData[1].gif = "QmfSdAjVdQQAAax796z9A3rcGCggbG92o2Voeb8tGkQk69";
        monsterData[2].percent = 82;
        monsterData[2].attack_power = 5000;
        monsterData[2].reward = 160;
        monsterData[2].jpg = "QmNhZUtoZxUKJ6USw26Lz12Pr8f7u1ZKVSykvh3ZjKZKsm";
        monsterData[2].gif = "QmaNNA3RnHRd64EYCAS31oLTCzZUET8mTBY5qDmcDEFCAL";
        monsterData[3].percent = 78;
        monsterData[3].attack_power = 8000;
        monsterData[3].reward = 260;
        monsterData[3].jpg = "QmfA6bDhho36RNpgB4GmiDXMUBULP4oR8qqiao2bqpME7y";
        monsterData[3].gif = "QmTcyp5U3vVda3rvb4MkMbufm2htAe1ByEkxMac7kF6PR2";
        monsterData[4].percent = 75;
        monsterData[4].attack_power = 10000;
        monsterData[4].reward = 325;
        monsterData[4].jpg = "QmVzcCtDP34HdpZ5SW46MtvLjVVw1iGsWhpfFjtk7hRihK";
        monsterData[4].gif = "QmYn35BQoYxHEJ4t9aLxyZ83M6mJWQfXao8ANtDSb1gh2u";
        monsterData[5].percent = 72;
        monsterData[5].attack_power = 13000;
        monsterData[5].reward = 440;
        monsterData[5].jpg = "QmPJQ4wqHm68nURYJRPopug6ZyEgNroRp2dAtgo3h8FGKG";
        monsterData[5].gif = "QmcMiN47AYZpFxp1GG6npBuRXStuWFXhab2RcMqHng66q9";
        monsterData[6].percent = 68;
        monsterData[6].attack_power = 17000;
        monsterData[6].reward = 605;
        monsterData[6].jpg = "QmVcka2zcxGteZaFC8HLDHyAxHRdCThJoW2QeanRcPoyfY";
        monsterData[6].gif = "QmU5yjhoUZXBZq3zrqk97Bg4G3zvqtdPywm8FXWy2PoRne";
        monsterData[7].percent = 65;
        monsterData[7].attack_power = 20000;
        monsterData[7].reward = 740;
        monsterData[7].jpg = "QmYazkYVDt6gDbykUALmX61DHDguwtw3r2JHjFMHyywZLY";
        monsterData[7].gif = "QmdQQCjMoNGodctMtXT28RKWTxSTRS8sKDt72vNkGrPuVY";
        monsterData[8].percent = 62;
        monsterData[8].attack_power = 22000;
        monsterData[8].reward = 850;
        monsterData[8].jpg = "QmNZHhpRjtyWiv2C9SisZ5spBtrNZgPmZXyBYLrxVsdZY4";
        monsterData[8].gif = "QmRunDufqd9n793sSUPKgK7akhLGsiEzYUgv6Wuh5Rcvvj";
        monsterData[9].percent = 59;
        monsterData[9].attack_power = 25000;
        monsterData[9].reward = 1010;
        monsterData[9].jpg = "QmeTMoTRgH2A9gmcDr17uaiQUB6p9GDymbrXerW9i5rBcz";
        monsterData[9].gif = "Qma2BojPvTKvfxUX4htfu21nbvSTZiff6f31BuEmRPi7Pv";
        monsterData[10].percent = 55;
        monsterData[10].attack_power = 28000;
        monsterData[10].reward = 1210;
        monsterData[10].jpg = "QmRJJgx3DneuE5b4QovaZ1VqbJ3K6qAHJctvJN5JZaGxwD";
        monsterData[10].gif = "QmXsmgUGaEiSTLupLRvkPmqxJm3mskYvrYNVoYgEjgqfnz";
        monsterData[11].percent = 52;
        monsterData[11].attack_power = 31000;
        monsterData[11].reward = 1410;
        monsterData[11].jpg = "QmeUaPhVyxc3xXaGA55D9sUuJFweXMnpHALQsnab6Kyjx7";
        monsterData[11].gif = "QmNQW45M3XKKkg2jzyX5453J7KZRDYeRLch96WywF8SCGi";
        monsterData[12].percent = 49;
        monsterData[12].attack_power = 34000;
        monsterData[12].reward = 1620;
        monsterData[12].jpg = "QmX82xvxCas1p9hnNtqSqvtrnF94Kt93sMmxaEqwytfWMw";
        monsterData[12].gif = "QmS2veKCqPuXfA7NQx55tBmNeh7sSEJm6d5qrEqowJsCMo";
        monsterData[13].percent = 45;
        monsterData[13].attack_power = 37000;
        monsterData[13].reward = 1900;
        monsterData[13].jpg = "QmWwAsqQLTXZLguaZDpGAXqSNqasaXxit1hBjaoNyL97Ln";
        monsterData[13].gif = "QmXEwyJs3g1ZdegcNWzekBmeCajSyme7LbmZmVg8BTVt7V";
        monsterData[14].percent = 42;
        monsterData[14].attack_power = 40000;
        monsterData[14].reward = 2150;
        monsterData[14].jpg = "QmZ3ZzGf1NmNhZCBR7nypCacVMtJNcKTAX3dbqQ68TATwm";
        monsterData[14].gif = "QmU6rUGBryVH8fk3KQzY3fSWsgyma52SA1iDnMeYMyUhYc";
        monsterData[15].percent = 41;
        monsterData[15].attack_power = 42000;
        monsterData[15].reward = 2450;
        monsterData[15].jpg = "QmXB7htXDEaGvaMKJLr66AwPHv1vESWDfAsBzF7ZDzweET";
        monsterData[15].gif = "QmTTL5V5p7mGKsdGVgu4wczWr272GGmTHorWBN9WZ3ompy";
        monsterData[16].percent = 41;
        monsterData[16].attack_power = 47000;
        monsterData[16].reward = 2950;
        monsterData[16].jpg = "QmdrwiwZEcBZvaeBwFPEWPdM531aeLrEM2aH7XqzJ9vTX8";
        monsterData[16].gif = "QmQpaM3ebf7zJ4DWW1yUKKw9ewkFdHv5SVRhgvp4YpDGxe";
        monsterData[17].percent = 41;
        monsterData[17].attack_power = 50000;
        monsterData[17].reward = 3250;
        monsterData[17].jpg = "Qme1gswDd6Rcbv2CC3n2y5fdNtdnQgwjXsst7gXWBzk6HZ";
        monsterData[17].gif = "QmagmjrkxR8k697mg9FetnRNF3BKnLTQWRsuXHy2RwxxhE";
        monsterData[18].percent = 39;
        monsterData[18].attack_power = 53000;
        monsterData[18].reward = 3800;
        monsterData[18].jpg = "QmZo3yHHvduPAVqe2An4M76GDD3sTrF6MhgzSVABP3SjND";
        monsterData[18].gif = "QmYPavSDjmZZxrKNHqLBveLSo9uUb6snU7asFiwfHTVhwq";
        monsterData[19].percent = 39;
        monsterData[19].attack_power = 56000;
        monsterData[19].reward = 4300;
        monsterData[19].jpg = "QmWp2kHf3ivGDxh6GHJ8eZcDF57dgTcu7YkeAWcQRCNUt7";
        monsterData[19].gif = "QmPKrwq2TCPrGwLH5RvxwU6Urk9vjtCNogyBR6VotqLoKh";
        monsterData[20].percent = 39;
        monsterData[20].attack_power = 60000;
        monsterData[20].reward = 4900;
        monsterData[20].jpg = "QmcYp6mvoJkguqtizLPKdKJczoDwBLbCd3g19RA8NyYbR1";
        monsterData[20].gif = "QmVDUS7mUCKWGWtu7e76LvhNCaDDXk36yZRVK8tc67LZ9Z";
        monsterData[21].percent = 35;
        monsterData[21].attack_power = 250000;
        monsterData[21].reward = 23000;
        monsterData[21].jpg = "QmRnQ8YBsAzJBcQCyATMS99WP18Jnir5xAAHJqaJzbSyCK";
        monsterData[21].gif = "QmPQ6fnxNqwzn9VymkEq7w8PtF6oxuzsWThARhUX9SNUA1";
        monsterData[22].percent = 30;
        monsterData[22].attack_power = 300000;
        monsterData[22].reward = 33000;
        monsterData[22].jpg = "QmYtBGsWzLTwjxTkk7Mm6hsK3acFoxxCc5aQj7X8sgyMuu";
        monsterData[22].gif = "QmZtQPRR6SEiuJdmwq7UTx5hwTVNd2utKR7AwMtKShhkq7";
    }
    
    function getMonsterInfo(uint256 monsterId) external override view returns(uint256, uint256, uint256, string memory, string memory) {
        require(monsterId>0&&monsterId<23, "Monster is not registered");
        return (monsterData[monsterId].percent, monsterData[monsterId].attack_power, monsterData[monsterId].reward, monsterData[monsterId].gif, monsterData[monsterId].jpg);
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