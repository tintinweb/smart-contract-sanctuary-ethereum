/**
 *Submitted for verification at Etherscan.io on 2022-06-28
*/

/**
 *Submitted for verification at Etherscan.io on 2022-06-27
*/

pragma solidity ^0.8.15;


// // SPDX-License-Identifier: MIT
// // OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)



// // CAUTION
// // This version of SafeMath should only be used with Solidity 0.8 or later,
// // because it relies on the compiler's built in overflow checks.

// /**
//  * @dev Wrappers over Solidity's arithmetic operations.
//  *
//  * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
//  * now has built in overflow checking.
//  */
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

    contract VomoPresale {
        using SafeMath for uint256;
/// Fields:
    string public constant name = "VOMO";
    string public constant symbol = "Vomo";
    uint public constant decimals = 18;
    uint public constant PRICE = 100; // per 1 Ether
    uint actualPrice =PRICE-((PRICE/100)*2);
    

// price
// Cap is 4000 ETH
// 1 eth = 100; presale 
// uint public constant TOKEN_SUPPLY = 50000000 ;

    enum State{
    Init,
    Running
    }
    uint256 public PRESALE_END_COUNTDOWN;
    uint numTokens;
    uint256 totalSupply_;
    address funder1 = 0x69e56D0aF44380BC3B0D666c4207BBF910f0ADC9;
    address funder2 = 0x11a99181d9d954863B41C3Ec51035D856b69E9e8;
    address _referral;
    State public currentState = State.Running;
    uint public initialToken = 0; // amount of tokens already sold

// Gathered funds can be withdrawn only to escrow's address.
    address public escrow ;
    mapping (address => uint256) private balances;
    mapping (address => bool) ownerAppended;
    address[] public owners;

/// Modifiers:
    modifier onlyInState(State state){ require(state == currentState); _; }

/// Events:

    event Transfer(address indexed from, address indexed to, uint256 _value);

/// Functions:
/// @dev Constructor
    constructor (address _escrow, uint256 _PRESALE_END_COUNTDOWN) public {
    PRESALE_END_COUNTDOWN = _PRESALE_END_COUNTDOWN;
    //require(_escrow != 0);
    escrow = _escrow;
    totalSupply_ = 1400000000000000000000000000;

    uint fundToken1 = (totalSupply_/100)*15;
    balances[funder1] += fundToken1;
   emit Transfer(msg.sender, funder1,  fundToken1);
    
    uint fundToken2 = (totalSupply_/100)*5;
    balances[funder2] += fundToken2;
   emit Transfer(msg.sender, funder2,  fundToken2);
    uint totalFunder = (fundToken1 +  fundToken2);
    uint supplyBal = totalSupply_ - totalFunder;

    balances[msg.sender] = supplyBal;


    }


    function buyTokens(address _buyer, address _referral) public payable onlyInState(State.Running) {
   // require(_referral!=0x0);
    require(_referral != address(0));
    require(block.timestamp <= PRESALE_END_COUNTDOWN, "Presale Date Exceed.");
    require(msg.value != 0);

    uint newTokens = msg.value * actualPrice;
    uint refToken = (newTokens/100)*4;
    require(initialToken + newTokens <= totalSupply_);

    balances[_referral] += refToken;
    emit Transfer(msg.sender, _referral,  refToken);

    balances[_buyer] += newTokens;
    uint deductTokens = newTokens + refToken;
    balances[msg.sender] -= deductTokens;
    initialToken += newTokens;
    if(!ownerAppended[_buyer]) {
    ownerAppended[_buyer] = true;
    owners.push(_buyer);
    }
    emit Transfer(msg.sender, _buyer,  newTokens);
    
    // if(this.balance > 0) {
    // require(escrow.send(this.balance));
    // }

    if(address(this).balance > 0) {
    //  Transfer(escrow.send(address(this).balance));
     emit Transfer(_buyer,msg.sender,msg.value);
     balances[msg.sender] += msg.value;
    }

    }

/// @dev Returns number of tokens owned by given address.
/// @param _owner Address of token owner.
     function balanceOf(address _owner) public view virtual returns (uint256) {
        return balances[_owner];
    }

    function getPrice() public view virtual returns(uint) {
    return PRICE;
    }
    address public owner;

//Transfer Function
    // uint numTokens = 1000000000000000000;
    mapping(address => bool) public hasClaimed;
    
// Transfer Ownership
    function Ownable() public virtual returns (address) {
    owner = msg.sender;
    }

    modifier onlyOwner() {
    require(msg.sender == owner);
    _ ;
    }
    function transferOwnership(address newOwner) internal virtual {
    if (newOwner != address(0)) {
    owner = newOwner;
    }
    }

    function  fallback () external payable {
    buyTokens(msg.sender, _referral);
    }
    
}