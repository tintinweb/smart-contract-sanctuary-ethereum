/**
 *Submitted for verification at Etherscan.io on 2022-03-27
*/

// SPDX-License-Identifier: MIT

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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

// File: sKronos.sol



// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

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




contract AlphaseekVesting {
    using SafeMath for uint256;

    IERC20 public   immutable SEEK;

    address public  immutable LIQUIDITY_WALLET;
    address public  immutable TEAM_WALLET;
    address public  immutable RESERVE_WALLET;
    address public  immutable PRIVATE_SALE_WALLET;
    address public  immutable ECOSYSTEM_WALLET;
    address public  immutable INSURANCE_FUND_WALLET;




    uint256 public  constant LIQUIDITY_SHARE = 60900000*1e18;
    uint256 public  constant TEAM_SHARE = 52500000*1e18; 
    uint256 public  constant RESERVE_SHARE = 42000000*1e18; 
    uint256 public  constant PRIVATE_SALE_SHARE = 21000000*1e18;
    uint256 public  constant ECOSYSTEM_SHARE= 21000000*1e18;
    uint256 public  constant INSURANCE_FUND_SHARE = 12600000*1e18;

    uint256 public constant ONE_MONTH = 30 days;



    uint256 public   LIQUIDITY_SHARE_CLAIMED;
    uint256 public   TEAM_SHARE_CLAIMED;
    uint256 public   RESERVE_SHARE_CLAIMED;
    uint256 public   PRIVATE_SALE_SHARE_CLAIMED;
    uint256 public   ECOSYSTEM_SHARE_CLAIMED;
    uint256 public   INSURANCE_FUND_SHARE_CLAIMED ;



    uint256 public   LIQUIDITY_SHARE_NEXT_CLAIM;
    uint256 public   TEAM_SHARE_NEXT_CLAIM = block.timestamp +(ONE_MONTH*6);
    uint256 public   RESERVE_SHARE_NEXT_CLAIM =  block.timestamp +(ONE_MONTH*12);
    uint256 public   PRIVATE_SALE_SHARE_NEXT_CLAIM = block.timestamp +(ONE_MONTH*3);
    uint256 public   ECOSYSTEM_SHARE_NEXT_CLAIM =block.timestamp +(ONE_MONTH*6);
    uint256 public   INSURANCE_FUND_SHARE_NEXT_CLAIM;



    constructor(IERC20 _SEEK, 
        address _LIQUIDITY_WALLET,
        address _TEAM_WALLET,
        address _RESERVE_WALLET,
        address _PRIVATE_SALE_WALLET,
        address _ECOSYSTEM_WALLET,
        address _INSURANCE_FUND_WALLET
    ) {
        SEEK = _SEEK;
        LIQUIDITY_WALLET = _LIQUIDITY_WALLET;
        TEAM_WALLET = _TEAM_WALLET;
        RESERVE_WALLET = _RESERVE_WALLET;
        PRIVATE_SALE_WALLET = _PRIVATE_SALE_WALLET;
        ECOSYSTEM_WALLET = _ECOSYSTEM_WALLET;
        INSURANCE_FUND_WALLET = _INSURANCE_FUND_WALLET;
    }


    function claimLiquidity () public {
        require(LIQUIDITY_SHARE_CLAIMED != LIQUIDITY_SHARE,"Claimed All Shares");
        uint256 tokensAmount = LIQUIDITY_SHARE;
        LIQUIDITY_SHARE_CLAIMED += tokensAmount;
        SEEK.transfer(LIQUIDITY_WALLET,tokensAmount);
        LIQUIDITY_SHARE_NEXT_CLAIM = block.timestamp;
    }


    function claimTeam () public {
        require(TEAM_SHARE_CLAIMED != TEAM_SHARE,"Claimed All Shares");
        require(TEAM_SHARE_NEXT_CLAIM < block.timestamp,"Time has not reached");
        uint256 tokensAmount = TEAM_SHARE/30;
        TEAM_SHARE_CLAIMED += tokensAmount;
        SEEK.transfer(TEAM_WALLET,tokensAmount);
        TEAM_SHARE_NEXT_CLAIM = block.timestamp+ONE_MONTH;
    }



    function claimReserve () public {
        require(RESERVE_SHARE_CLAIMED != RESERVE_SHARE,"Claimed All Shares");
        require(RESERVE_SHARE_NEXT_CLAIM < block.timestamp,"Time has not reached");
        uint256 tokensAmount = RESERVE_SHARE/24;
        RESERVE_SHARE_CLAIMED += tokensAmount;
        SEEK.transfer(RESERVE_WALLET,tokensAmount);
        RESERVE_SHARE_NEXT_CLAIM = block.timestamp+ONE_MONTH;
    }




    function claimPrivateSale() public {
        require(PRIVATE_SALE_SHARE_CLAIMED != PRIVATE_SALE_SHARE,"Claimed All Shares");
        require(PRIVATE_SALE_SHARE_NEXT_CLAIM < block.timestamp,"Time has not reached");
        uint256 tokensAmount = PRIVATE_SALE_SHARE/15;
        PRIVATE_SALE_SHARE_CLAIMED += tokensAmount;
        SEEK.transfer(PRIVATE_SALE_WALLET,tokensAmount);
        PRIVATE_SALE_SHARE_NEXT_CLAIM = block.timestamp+ONE_MONTH;
    }

    function claimEcoSystem() public {
        require(ECOSYSTEM_SHARE_CLAIMED != ECOSYSTEM_SHARE,"Claimed All Shares");
        require(ECOSYSTEM_SHARE_NEXT_CLAIM < block.timestamp,"Time has not reached");
        uint256 tokensAmount = ECOSYSTEM_SHARE/9;
        ECOSYSTEM_SHARE_CLAIMED += tokensAmount;
        SEEK.transfer(ECOSYSTEM_WALLET,tokensAmount);
        ECOSYSTEM_SHARE_NEXT_CLAIM = block.timestamp+ONE_MONTH;
    }


     function claimInsuranceFund() public {
        require(INSURANCE_FUND_SHARE_CLAIMED != INSURANCE_FUND_SHARE,"Claimed All Shares");
        require(INSURANCE_FUND_SHARE_NEXT_CLAIM < block.timestamp,"Time has not reached");
        uint256 tokensAmount = INSURANCE_FUND_SHARE;
        INSURANCE_FUND_SHARE_CLAIMED += tokensAmount;
        SEEK.transfer(INSURANCE_FUND_WALLET,tokensAmount);
        INSURANCE_FUND_SHARE_NEXT_CLAIM = block.timestamp+ONE_MONTH;
    }
}