/**
 *Submitted for verification at Etherscan.io on 2022-05-09
*/

// SPDX-License-Identifier: MIT
// File: contracts/Interfaces/IStake.sol



pragma solidity >=0.8.4;

interface IStake {

    struct Deposit {
    uint256 amount;
    uint40 time;
    }

    struct Staker {
    uint256 dividend_amount;
    uint40 last_payout;
    uint256 total_invested_amount;
    uint256 total_withdrawn_amount;
    Deposit[] deposits;
    }
    
    event NewDeposit(address indexed addr, uint256 amount);
    event Withdraw(address indexed addr, uint256 amount);

    function withdraw(uint256 amountToWithdraw, uint40 timestamp)  external;

    function withdrawAmount(address _addr) external returns(uint256) ;
}
// File: contracts/Owned.sol


pragma solidity ^0.8.4;


contract owned {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Caller should be Owner");
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}

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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeMath.sol


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
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
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

// File: contracts/MSpace.sol



pragma solidity ^0.8.7;





contract MSpaceStake is owned, IStake{
	using SafeMath for uint256;
	using SafeMath for uint40;

    uint256 public invested_amount;
    uint256 public withdrawn_amount;
    
    IERC20 public MSPACE;

    mapping(address => Staker) public stakers;
    
    
	address public gameDevWallet;


    constructor(address _gameDevWallet, address _coinAddress) {
        require(!isContract(gameDevWallet));
		gameDevWallet = _gameDevWallet;
        MSPACE = IERC20(_coinAddress);
        
    }

    function updateGameDevWallet(address _newGameDevWallet) public onlyOwner {
        gameDevWallet = _newGameDevWallet;
    }

    function updateCoinAddress(address _coinAddress) public onlyOwner {
        MSPACE = IERC20(_coinAddress);
    }

    function _withdrawAmount(address _addr) private {
        uint256 amount = this.withdrawAmount(_addr);

        if(amount > 0) {
            stakers[_addr].last_payout = uint40(block.timestamp);
            stakers[_addr].dividend_amount += amount;
        }
    }

    function deposit(uint256 amount) external {
        require(amount > 0, "deposit is invalid");

        MSPACE.transferFrom(msg.sender, gameDevWallet, amount);
        Staker storage staker = stakers[msg.sender];
        require(staker.deposits.length < 100, "Max 100 deposits per address");

        staker.deposits.push(Deposit({
            amount: amount,
            time: uint40(block.timestamp)
        }));

        staker.total_invested_amount+= amount;
        invested_amount+= amount;
        
        emit NewDeposit(msg.sender, amount);
    }


    function allUserDeposits(address _addr) public view returns(Deposit[] memory) {
        Staker storage staker = stakers[_addr];

        Deposit[] memory userDeposits = new Deposit[](staker.deposits.length);
        
        for(uint256 i = 0; i < staker.deposits.length; i++) {
            userDeposits[i] = staker.deposits[i];
        }

        return userDeposits;
    }

    
    function withdraw(uint256 amountToWithdraw, uint40 timestamp) external override{
        Staker storage staker = stakers[msg.sender];
        
        
        _withdrawAmount(msg.sender);
        require(MSPACE.balanceOf(gameDevWallet) >= amountToWithdraw, "Can not send requested amount at the moment");
        require(staker.dividend_amount >= amountToWithdraw, "not enough balance to withdraw");

        staker.dividend_amount -=  amountToWithdraw;
        staker.total_withdrawn_amount += amountToWithdraw;
        withdrawn_amount += amountToWithdraw;

        
        for(uint256 i = 0; i < staker.deposits.length; i++) {
            if(staker.deposits[i].time == timestamp){
                require(staker.deposits[i].amount >= amountToWithdraw, "Not enought balance to withdraw");
                staker.deposits[i].amount -= amountToWithdraw;
            }
        }

        MSPACE.transferFrom(gameDevWallet, msg.sender, amountToWithdraw);
        
        emit Withdraw(msg.sender, amountToWithdraw);
    }

    function withdrawAmount(address _addr) view external override returns(uint256) {
        Staker storage staker = stakers[_addr];
        uint256 value = 0;
        
        for(uint256 i = 0; i < staker.deposits.length; i++) {
            Deposit storage depInstance = staker.deposits[i];
            uint daysDeposited = (uint40(block.timestamp) - depInstance.time) / 60;

            if(daysDeposited >= 3 && daysDeposited < 9){
                value += (((depInstance.amount) * daysDeposited * 111 /200) / 100) + depInstance.amount; // 1/3
            }

            else if(daysDeposited >= 9 && daysDeposited < 18){
                value += (((depInstance.amount) * daysDeposited * 833 / 1000) / 100)+ depInstance.amount; // 1/2
            }
            else if(daysDeposited >= 18) {
                value += (((depInstance.amount) * daysDeposited * 1667 / 1000) / 100)+ depInstance.amount; // 1
            }
            else{
                value += 0;
            }

        }

        return value;
    }


    
    function addressDetails(address _addr) view external returns(uint256 for_withdraw, uint256 total_invested_amount, uint256 total_withdrawn_amount) {
        Staker storage staker = stakers[_addr];

        uint256 amount = this.withdrawAmount(_addr);

        return (
            amount + staker.dividend_amount,
            staker.total_invested_amount,
            staker.total_withdrawn_amount
        );
    }

    function contractDetails() view external returns(uint256 _invested_amount, uint256 _withdrawn_amount) {
        return (invested_amount, withdrawn_amount);
    }

	function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }
}