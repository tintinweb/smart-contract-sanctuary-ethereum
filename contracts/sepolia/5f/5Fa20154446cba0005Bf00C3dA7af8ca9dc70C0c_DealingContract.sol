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
pragma solidity ^0.8.18;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
contract DealingContract {
    using SafeMath for uint256;
    struct Deal {
        address payable initiator;
        address payable acceptor;
        address payable oracle;
        uint256 inamount;
        uint256 acamount;
        bool initiatorG;
        bool accepted;
        bool completed;
        bool initiatorSuccess;
        bool acceptorSuccess;
        bool initiatorFailure;
        bool acceptorFailure;
    }
    struct Oracle {
        uint256 fee;
    }
    mapping (bytes32 => Deal) public deals;
    mapping (address => Oracle) public oracles;
    address public owner;
    event DealInitiated(bytes32 indexed dealID, address indexed initiator, uint amount, bool initiatorG);
    event DealAccepted(bytes32 indexed dealID, address indexed acceptor);
    event DealCompleted(bytes32 indexed dealID, bool initiatorSuccess, bool acceptorSuccess);
    event DealDispute(bytes32 indexed dealID, bool initiatorSuccess, bool acceptorSuccess);
    event Success(bytes32 indexed dealID, bool initiatorSuccess, bool acceptorSuccess);
    event Failure(bytes32 indexed dealID, bool initiatorFailure, bool acceptorFailure);
    event DealCanceled(bytes32 indexed dealID, bool initiatorSuccess, bool acceptorSuccess);
    event ResultRequired(bytes32 indexed dealID, bool initiatorG);
    constructor( ){
        owner = msg.sender;
    }
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    function failure(bytes32 dealID) public {
        require(deals[dealID].completed == false, "Deal already completed");
        require(msg.sender == deals[dealID].initiator || msg.sender == deals[dealID].acceptor, "Only the parties involved can call this");
        if (deals[dealID].accepted == false){
            deals[dealID].initiator.transfer(deals[dealID].inamount);
            deals[dealID].completed = true;
            emit DealCanceled(dealID, false, false);
        }else{
            if (msg.sender == deals[dealID].initiator) {
                deals[dealID].initiatorFailure = true;
                emit Failure(dealID, true, false);
            } else {
                deals[dealID].acceptorFailure = true;
                emit Failure(dealID, false, true);
            }}}
    function success(bytes32 dealID) public {
        Deal storage deal = deals[dealID];
        require(!deal.completed, "Deal already completed");
        require(msg.sender == deal.initiator || msg.sender == deal.acceptor, "Only the parties involved can call this");
        if (msg.sender == deal.initiator) {
            deal.initiatorSuccess = true;
            emit Success(dealID, true, false);
        } else {
            deal.acceptorSuccess = true;
            emit Success(dealID, false, true);
        }}
    function decide(bytes32 dealID) public {
        Deal storage deal = deals[dealID];
        require(!deal.completed, "Deal already completed");
        require(deal.accepted, "Deal not accepted yet");
        if (deal.initiatorSuccess && deal.acceptorFailure) {
            deal.initiator.transfer(deal.inamount + deal.acamount);
            deal.completed = true;
            emit DealCompleted(dealID, true, false);
        } else if(deal.acceptorSuccess && deal.initiatorFailure){
            deal.acceptor.transfer(deal.inamount + deal.acamount);
            deal.completed = true;
            emit DealCompleted(dealID, false, true);
        } else if(deal.acceptorFailure && deal.initiatorFailure){
            deal.acceptor.transfer(deal.inamount + deal.acamount);
            deal.completed = true;
            emit DealCanceled(dealID, false, false);
        } else if(deal.acceptorSuccess && deal.initiatorSuccess){
            emit DealDispute(dealID, true, true);
        }else{
            emit ResultRequired(dealID, deal.initiatorG);
        }}
    function initiateDeal(bytes32 dealID, bool initiatorG, uint256 initiatorValue, uint256 acceptorValue, address payable oracle) public payable {
        require(initiatorValue > 0 && acceptorValue > 0, "Values should be greater than 0");
        require(oracles[oracle].fee > 0, "Oracle not verified");
        require(deals[dealID].initiator == address(0), "Deal for this ID already exists");
        uint256 oracleValue = (initiatorValue + acceptorValue).mul(oracles[oracle].fee).div(100);
        require(msg.value == (initiatorValue + oracleValue), "More ETH needed");
        Deal memory newDeal = Deal({
        initiator: payable(msg.sender),
        acceptor: payable(address(0)),
        oracle: payable(oracle),
        inamount: initiatorValue,
        acamount: acceptorValue,
        initiatorG: initiatorG,
        accepted: false,
        completed: false,
        initiatorSuccess: false,
        acceptorSuccess: false,
        initiatorFailure: false,
        acceptorFailure: false
        });
        deals[dealID] = newDeal;
        (bool success1, ) = address(oracle).call{value: oracleValue}("");
        require(success1, "Failed to send fee to oracle");
        (bool success2, ) = address(this).call{value: initiatorValue}("");
        require(success2, "Failed to send to Contract");
        emit DealInitiated(dealID, newDeal.oracle, msg.value, initiatorG);
    }
    function acceptDeal(bytes32 dealID) public payable {
        Deal storage deal = deals[dealID];
        require(deal.initiator != address(0), "Deal for this ID doesn't exist");
        require(!deal.completed, "Deal already completed");
        require(!deal.accepted, "Deal already accepted");
        require(msg.value == deal.acamount, "Incorrect fee amount");
        deal.acceptor = payable(msg.sender);
        deal.accepted = true;
        (bool success1, ) = address(this).call{value: deal.acamount}("");
        require(success1, "Failed to send funds to contract");
        emit DealAccepted(dealID, deal.oracle);
    }
    function updateDealOutcome(bytes32 dealID, bool initiatorSuccess, bool acceptorSuccess, bool initiatorFailure, bool acceptorFailure) public{
        Deal storage deal = deals[dealID];
        require(deal.oracle == msg.sender, "Must be oracle address.");
        require(deal.accepted == true, "Deal not accepted yet");
        require(deal.completed == false, "Deal already completed.");
        deal.initiatorSuccess = initiatorSuccess;
        deal.acceptorSuccess = acceptorSuccess;
        deal.initiatorFailure = initiatorFailure;
        deal.acceptorFailure = acceptorFailure;
    }
    //    add and remove verified oracles
    function setOracleFee(address oracle, uint256 fee) public onlyOwner {
        oracles[oracle] = Oracle(fee);
    }
    function removeOracle(address oracle) public onlyOwner{
        require(oracles[oracle].fee > 0, "Invalid oracle address.");
        delete oracles[oracle];
    }
    receive() external payable {
    }

}