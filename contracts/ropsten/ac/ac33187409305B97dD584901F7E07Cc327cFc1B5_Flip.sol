/**
 *Submitted for verification at Etherscan.io on 2022-08-11
*/

// File: @openzeppelin/contracts/utils/math/SafeMath.sol


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

// File: contracts/Flip.sol



pragma solidity 0.8.16;


contract Flip{
    using SafeMath for uint256;

    modifier onlyOwner(){
        require(
            _owner == msg.sender,
            "Ownable: caller is not the owner"
        );
        _;
    }
        modifier onlyCoinFlip(){
        require(msg.value >= minBetAmt, "Less than MAX BET AMNT ");
        require(msg.value <= maxBetAmt, "More than MAX BET AMNT ");
        require(msg.value <= address(this).balance, "The contract does not have enough funds to process your bet");


        _;

    }

address _owner;

address userAddress = msg.sender;
uint256 minBetAmt = 10000000000000000; //.1 ether (TODO: change to CRO)
uint256 maxBetAmt = 50000000000000000; //.5 ether (TODO: change to CRO)
uint256 public balance;




event BetOutcome(address userAddress, uint256 betAmount, uint256 winAmount, bool wonOrLost);

function placeBet(uint256 bettedOutcome) public payable onlyCoinFlip {
        require(bettedOutcome == 0 || bettedOutcome == 1,"user must bet on either Heads (0) or Tails (1)");
        uint256 betAmount = msg.value;
        
        

        if (bettedOutcome == flipCoin()) {
            
        uint256 _marketingPayout = betAmount.mul(2).div(100).mul(5);
        uint256 _devPayout = betAmount.mul(2).div(100).mul(5);
        uint256 _winAmount = betAmount.mul(2).div(100).mul(10);
        address marketingFeeRcvr = 0x8a66F88416C7Aca651A0A79Fd204120A18F5939b;
        address devFeeRcvr = 0xc5CAba18e73b83D55a638B894cDfeFD44912ABdc;
        
            (bool success, ) = 
            msg.sender.call{value: _winAmount}('');
            require(success, "Transfer Failed");
            payable(marketingFeeRcvr).transfer(_marketingPayout);
            require(success, "Fee Transfer Failed");
            payable(devFeeRcvr).transfer(_devPayout);
            
           

            
            emit BetOutcome(msg.sender, msg.value, _winAmount, true);
        } else {
            
            emit BetOutcome(msg.sender, msg.value, 0, false);
        }
    }

    // TODO: use an oracle
    function flipCoin() public virtual view returns (uint256) {
        return block.timestamp % 2;
    }






    function setMinBetAmt(uint256 _newMin) public onlyOwner {
        minBetAmt = _newMin;
    }
        function setMaxBetAmt(uint256 _newMax) public onlyOwner {
        maxBetAmt = _newMax;
    }
        function deposit(uint256 amount) payable public onlyOwner {
        require(msg.value == amount);
        balance += msg.value;
    }


    // receivable function - necessary to fund the contract
    receive() external payable {
        require(msg.value > 0);
        balance += msg.value;
        assert(balance > 0);
        assert(balance == address(this).balance);
    }

}