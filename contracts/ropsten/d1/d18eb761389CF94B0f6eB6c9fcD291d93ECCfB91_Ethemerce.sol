// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Ethemerce{

    using SafeMath for uint256;
    
    // mediator is a nodejs application
    address public mediator;
    address public creator;
    uint    public resource;
    bool internal locked;

    mapping(address => uint256) public cost;
    mapping(address => uint256) public payment;
    mapping(address => bool) public alreadypay;
    mapping(address => bool) public commitpurchase;

    // Ethemerce Events
    event AddCost(uint time, address purchaser, uint amount);
    event Commit(uint time, address purchaser);
    event Purchase(uint time, address purchaser, uint amount);
    event Cancel(uint time, address purchaser);

    constructor(address addr){
        creator = msg.sender;
        mediator = addr;
    }

    modifier CheckMediator(){
        //@guard only non contract account
        require(tx.origin == mediator,'revert: not a mediator');
        require(tx.origin == msg.sender,'revert: delegation');
        _;
    }

    modifier CheckCreator(){
        //@guard only non contract account
        require(tx.origin == creator,'revert: not a creator');
        require(tx.origin == msg.sender,'revert: delegation');
        _;
    }

    modifier ReentrancyGuard() {
        require(!locked, "No re-entrancy");
        locked = true;
        _;
        locked = false;
    }

    /* ---Only Mediator--- */
    function addcost(address purchaser, uint256 newcost) CheckMediator external{
        require(newcost > 0 ether, 'erroneous cost value');
        cost[purchaser] = newcost;
        payment[purchaser] = 0;
        alreadypay[purchaser] = false;
        commitpurchase[purchaser] = false;
        emit AddCost(block.timestamp, purchaser, newcost);
    }

    function commit(address purchaser) CheckMediator external{
        require(alreadypay[purchaser] == true,'purchase did not called');
        commitpurchase[purchaser] = true;
        emit Commit(block.timestamp, purchaser);
    }

    /* ---Only Purchaser--- */
    function costof() external view returns(uint256){
        return cost[msg.sender];
    }

    function purchase() external payable{
        require(msg.value == cost[msg.sender],'value is not same as the mediator');
        payment[msg.sender] = payment[msg.sender].add(msg.value);
        resource = resource.add(msg.value);
        alreadypay[msg.sender] = true;
        emit Purchase(block.timestamp, msg.sender, msg.value);
    }

    function cancelpurchase() ReentrancyGuard external{
        require(commitpurchase[msg.sender] == false,'mediator has been commited');
        require(payment[msg.sender] > 0 wei,'account balance empty');
        safeTransferETH(payable(msg.sender), payment[msg.sender]);
        payment[msg.sender] = 0;
        alreadypay[msg.sender] = false;
        emit Cancel(block.timestamp, msg.sender);
    }

    function safeTransferETH(address payable recipient, uint256 amount) internal{
        require(amount > 0 ether,'transaction include zero amount');
        (bool success, ) = recipient.call{value: amount}("");
        require(success, 'transfer failed');
        resource = resource.sub(amount);
    }

    function withdraw() CheckCreator external{
        require(address(this).balance > 0 ether,'out of balance');
        safeTransferETH(payable(msg.sender), address(this).balance);
    }

    // all right reserved for E͎t͎h͎e͎m͎e͎r͎c͎e͎
}

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