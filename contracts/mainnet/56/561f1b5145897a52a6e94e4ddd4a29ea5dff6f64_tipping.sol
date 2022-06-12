/**
 *Submitted for verification at Etherscan.io on 2022-06-12
*/

/**
 *Submitted for verification at polygonscan.com on 2022-05-31
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1; 

interface ERC20 {
    function balanceOf(address _tokenOwner) external view returns (uint balance);
    function transfer(address _to, uint _tokens) external returns (bool success);
    function allowance(address _contract, address _spender) external view returns (uint256 remaining);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
}
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

contract tipping {

    using SafeMath for uint256;
    address public contractOwner = msg.sender;  
    mapping(address => uint256) public balanceOf;
    mapping(address => bool) public admins; 

    event TipMessage(address indexed recipientAddress, string message, uint256 amount);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function sendTo(address recipient_, string memory message_) public payable {
        (bool success, ) = recipient_.call{value: msg.value.sub(msg.value.div(100))}("");
        require(success, "Failed to send.");
        emit TipMessage(recipient_, message_, msg.value);
    }

    function sendTokenTo(address recipient_, uint256 amount_, address tokenContractAddr_, string memory message_) public payable {
        ERC20 paymentTc = ERC20(tokenContractAddr_);
        require(paymentTc.allowance(msg.sender, address(this)) >= amount_, "Insufficient Allowance");
        require(paymentTc.transferFrom(msg.sender, address(this), amount_), "Transfer failed");
        require(paymentTc.transfer(recipient_, amount_.sub(amount_.div(100))), "Transfer failed");
        emit TipMessage(recipient_, message_, amount_);
    }

    function withdraw() external {
        require(admins[msg.sender] == true, "Only admin can withdraw.");
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Failed to withdraw.");
    }

    function withdrawToken(address tokenContract) external {
        require(admins[msg.sender] == true, "Only admin can withdraw.");
        ERC20 withdrawTC = ERC20(tokenContract);
        withdrawTC.transfer(msg.sender, withdrawTC.balanceOf(address(this)));
    }

    function addAdmin(address adminAddress) external {
        require(msg.sender == contractOwner, "Only contractOwner can add admins.");
        admins[adminAddress] = true;
    }

    function deleteAdmin(address adminAddress) external {
        require(msg.sender == contractOwner, "Only contractOwner can delete admins.");
        admins[adminAddress] = false;
    }

    // Transfer contract ownership
    function transferContractOwnership(address newOwner) public payable {
        require(msg.sender == contractOwner, "Only contractOwner can change ownership of contract.");
        require(newOwner != address(0), "Ownable: new contractOwner is the zero address.");
        _transferOwnership(newOwner);
    }

    // Helper function
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = contractOwner;
        contractOwner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}