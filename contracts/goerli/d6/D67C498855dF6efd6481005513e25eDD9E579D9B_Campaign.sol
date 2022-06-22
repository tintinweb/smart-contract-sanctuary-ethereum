//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

// Campaign Contract v1.0.1

contract Campaign {

    address public owner;
    address public admin;
    address payable public recipient;   
    uint256 public totalAmount;

    constructor(address _admin) {
        owner = msg.sender;
        admin = _admin;
    }

    string public name;
    uint256 public goal;
    uint256 public startAt;
    uint256 public endAt;
    string public imgURL;
    string public description;

    using SafeMath for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private dropId;

    function setParams(
        string memory _name,
        uint256 _goal,
        uint256 _startAt,
        uint256 _endAt,
        address payable _recipient,
        string memory _imgURL,
        string memory _description
    ) external onlyOwner {
        require(_endAt > _startAt, "Bitis tarihi baslangic tarihinden sonra olmali.");
        require(block.timestamp < _startAt, "Baslangic tarihi gecmis bir tarih olamaz.");
        name = _name;
        goal = _goal;
        startAt = _startAt;
        endAt = _endAt;
        recipient = _recipient;
        imgURL = _imgURL;
        description= _description;
    }

    bool public isOpen = true;

    struct Drop {
        uint id;
        address addr;
        uint256 value;
        uint256 timestamp;
    }

    Drop[] public drops;

    address[] public dropAddresses;
    uint256 public dropsCount;

    event DropsClaimed(uint256 timestamp);
    event CampaingClosed(uint256 timestamp);
    event GoalReached(uint256 timestamp);
    event ReceiveDrop(address indexed addr, uint256 value, uint256 timestamp);
    event RefundDrop(uint256 value, uint256 timestamp);

    function sendDrop() external payable onlyIfOpen {   
      
        dropId.increment();
        uint _dropId = dropId.current();

        Drop memory drop = Drop({
            id: _dropId,
            addr: msg.sender,
            value: msg.value,
            timestamp: block.timestamp
        });

        drops.push(drop);
        dropAddresses.push(msg.sender);

        totalAmount = totalAmount.add(msg.value);
        dropsCount++;
        emit ReceiveDrop(msg.sender, msg.value, block.timestamp);

        if (checkGoalIsReached()) {
            closeCampaign();
            emit GoalReached(block.timestamp);
        }

    }

    function checkGoalIsReached() public view returns (bool) {
        return (totalAmount >= goal) ? true : false;
    }

    function closeCampaign() internal onlyIfOpen {
        isOpen = false;
        emit CampaingClosed(block.timestamp);
    }

    function getAddresses() public view returns(address[] memory) {
        return dropAddresses;
    }

    function getDrops() public view returns(Drop[] memory) {
        return drops;
    }

    function claimDrops() external onlyRecipient onlyIfClosed {
        uint256 balance = address(this).balance;
        require(goal <= balance, "Yeterli miktar yok.");

        (bool success, ) = recipient.call{value: goal}(new bytes(0));
        require(success, "Transfer gerceklesmedi.");
        totalAmount = totalAmount.sub(goal);
        emit DropsClaimed(block.timestamp);
    }

    function refundDrops() external onlyAdmin {
        require(block.timestamp > endAt, "Kampanya devam ediyor");
        require(!checkGoalIsReached(), "Hedefe ulasildi.");
         
        for(uint i = 0; i < dropsCount; i++) {
            refund(payable(drops[i].addr), drops[i].value);
        }
    }

    function refund(address payable _address, uint256 _value) internal {
        (bool success, ) = _address.call{value: _value}(new bytes(0));
        require(success, "Transfer gerceklesmedi.");
        totalAmount = totalAmount.sub(_value);
        emit RefundDrop(_value, block.timestamp);
    }
    
    modifier onlyRecipient() {
        require(msg.sender == recipient, "Alici adres yanlis.");
        _;
    }

    modifier onlyIfOpen() {
        require(isOpen, "Kampanya aktif degil.");
        require(block.timestamp < endAt, "Kampanya suresi doldu.");
        _;
    }

    modifier onlyIfClosed() {
        require(!isOpen, "Kampanya devam ediyor.");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Sadece yetkili.");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Sadece yetkili Admin.");
        _;
    }

    receive() external payable {}
    fallback() external payable {}

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}