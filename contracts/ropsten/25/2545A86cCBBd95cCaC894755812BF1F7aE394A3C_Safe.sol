// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Safe {
    using SafeMath for uint256;

    /// @dev account details
    /// @param unlockDates next unlock dates list
    /// @param unclaimedAmount total amount
    /// @param nextUnlockDate next unlock date
    struct SafeDetails {
        uint256[] unlockDates;
        uint256 unclaimedAmount;
        uint256 nextUnlockDate;
    }
    /// @dev account array
    mapping(address => SafeDetails) accounts;
    
    /// @dev owner address
    address payable owner;  

    /// @dev owner defination
    constructor(){ owner = payable(msg.sender); }

    /// @dev allows to deposit coins
    function depositLockedFunds() payable public {}

    /// @dev returns the amount of coins on the contract
    /// @return uint
    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    /// @dev allows the creation of a new payment account
    /// @param _accountAddress address of the created account
    /// @param _details account details
    function addAccount(address _accountAddress, SafeDetails memory _details) public {
        require(owner == msg.sender, "Only owner.");
        accounts[_accountAddress] = _details;
    }

    /// @dev allows to withdraw coins when coins are unlocked
    /// @param _accountAddress account address
    /// @return uint256
    function withdraw(address payable _accountAddress) public payable returns (uint256){
        require(owner == msg.sender, "Only owner.");
        require(accounts[_accountAddress].unclaimedAmount != 0, "Unclaimed amount is zero.");
        require(accounts[_accountAddress].nextUnlockDate < block.timestamp, "Too early to withdraw.");
        uint256 unclaimedAmount = getUnlockedAmount(_accountAddress);
        if(unclaimedAmount > 0){
            // TODO: DO THIS 1e18
            _accountAddress.transfer(unclaimedAmount * 1e10);
        }
        return unclaimedAmount;
    }

    /// @dev returns the remaining balance in the account
    /// @param _accountAddress account address
    /// @return uint256
    function getUnclaimedAmount(address _accountAddress) public view returns (uint256){
        return accounts[_accountAddress].unclaimedAmount;
    }

    /// @dev returns the time of the next lock opening
    /// @param _accountAddress account address
    /// @return uint256
    function getAccountUnlockDate(address _accountAddress) public view returns (uint256){
        return accounts[_accountAddress].nextUnlockDate;
    }

    /// @dev returns the amount of coins unlocked for the given address
    /// @param _accountAddress account address
    /// @return uint
    function getUnlockedAmount(address _accountAddress) internal returns(uint256) { 
        SafeDetails memory details = accounts[_accountAddress];
        uint256 amount = 0;
        while(details.nextUnlockDate <= block.timestamp && details.unlockDates.length > 0){
            if(details.unlockDates.length == 0 || details.unclaimedAmount == 0) { break; }
            amount += details.unclaimedAmount.div(details.unlockDates.length);
            details.unclaimedAmount -= details.unclaimedAmount.div(details.unlockDates.length);
            deleteFirstElementFromArray(details);
            details.nextUnlockDate = details.unlockDates.length > 0 ? details.unlockDates[0] : 0;
        }
        accounts[_accountAddress] = details;
        return amount;
    }
    /// @dev delete first element from unlock dates array
    /// @param _details account details
    function deleteFirstElementFromArray(SafeDetails memory _details) internal pure {
        if (_details.unlockDates.length == 0) return;
        uint256[] memory arrayNew = new uint256[](_details.unlockDates.length-1);
        for (uint i = 0; i < arrayNew.length; i++){
            arrayNew[i] = _details.unlockDates[i+1];
        }
        _details.unlockDates = arrayNew;
    }
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