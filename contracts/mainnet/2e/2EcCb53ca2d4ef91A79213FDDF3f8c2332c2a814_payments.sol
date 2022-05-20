/**
 *Submitted for verification at Etherscan.io on 2022-05-20
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1; 
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


contract payments {
    using SafeMath for uint256;
    mapping(string => uint256) percent;
    mapping(address => bool) private admins;
    address public contractOwner = msg.sender; 
    mapping(uint256 => address) public receipts;
    mapping(uint256 => uint256) public amounts;
    mapping(address => uint256) public balanceOf; 
    mapping(string => address) public delegationOwner;
    mapping(string => address) public delegationWithdrawAddress;

    constructor() {
        delegationOwner["IDriss"] = contractOwner;
        delegationWithdrawAddress["IDriss"] = 0xc62d0142c91Df69BcdfC13954a87d6Fe1DdfdEd6;
        percent["IDriss"] = 100;
    }

    event PaymentDone(address payer, uint256 amount, uint256 paymentId, uint256 date);
    event AdminAdded(address indexed admin);
    event AdminDeleted(address indexed admin);
    event DelegateAdded(string delegateHandle, address indexed delegateAddress);
    event DelegateDeleted(string delegateHandle, address indexed delegateAddress);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event WithdrawAddressChanged(string delegateHandle, address indexed newWithdrawAddress);

    function addAdmin(address adminAddress) external {
        require(msg.sender == contractOwner, "Only contractOwner can add admins.");
        admins[adminAddress] = true;
        emit AdminAdded(adminAddress);
    }

    function deleteAdmin(address adminAddress) external {
        require(msg.sender == contractOwner, "Only contractOwner can delete admins.");
        admins[adminAddress] = false;
        emit AdminDeleted(adminAddress);
    }

    function addDelegateException(address delegateAddress, address delegateWithdrawAddress, string memory delegateHandle, uint256 percentage) external {
        require(msg.sender == contractOwner, "Only contractOwner can add special delegate partner.");
        require(delegationOwner[delegateHandle] == address(0), "Delegate handle exists.");
        require(delegateWithdrawAddress != address(0), "Ownable: delegateWithdrawAddress is the zero address.");
        require(delegateAddress != address(0), "Ownable: delegateAddress is the zero address.");
        delegationOwner[delegateHandle] = delegateAddress;
        delegationWithdrawAddress[delegateHandle] = delegateWithdrawAddress;
        percent[delegateHandle] = percentage;
        emit DelegateAdded(delegateHandle, delegateAddress);
    }

    // Anyone can create a delegate link for anyone
    function addDelegate(address delegateAddress, address delegateWithdrawAddress, string memory delegateHandle) external {
        require(delegationOwner[delegateHandle] == address(0), "Delegate handle exists.");
        require(delegateWithdrawAddress != address(0), "Ownable: delegateWithdrawAddress is the zero address.");
        require(delegateAddress != address(0), "Ownable: delegateAddress is the zero address.");
        delegationOwner[delegateHandle] = delegateAddress;
        delegationWithdrawAddress[delegateHandle] = delegateWithdrawAddress;
        percent[delegateHandle] = 20;
        emit DelegateAdded(delegateHandle, delegateAddress);
    }

    // Delete the delegation link if needed.
    function deleteDelegate(string memory delegateHandle) external {
        require(msg.sender == delegationOwner[delegateHandle], "Only delegateOwner can delete delegation link.");
        address deletedDelegate = delegationOwner[delegateHandle];
        delete delegationOwner[delegateHandle];
        delete delegationWithdrawAddress[delegateHandle];
        delete percent[delegateHandle];
        emit DelegateDeleted(delegateHandle, deletedDelegate);
    }

    // Change the withdraw address for a delegate (change of treasury, ...).
    function changeWithdrawAddress(string memory delegateHandle, address newWithdrawAddress) external {
        require(msg.sender == delegationOwner[delegateHandle], "Only delegateOwner can change withdraw address.");
        delegationWithdrawAddress[delegateHandle] = newWithdrawAddress;
        emit WithdrawAddressChanged(delegateHandle, newWithdrawAddress);
    }

    // Payment function distributing the payment into two balances.
    function payNative(uint256 paymentId, string memory delegateHandle) external payable {
        require(receipts[paymentId] == address(0), "Already paid this receipt.");
        receipts[paymentId] = msg.sender;
        amounts[paymentId] = msg.value;
        if (delegationOwner[delegateHandle] != address(0)) {
            balanceOf[contractOwner] += msg.value.sub((msg.value.mul(percent[delegateHandle])).div(100));
            balanceOf[delegationOwner[delegateHandle]] += (msg.value.mul(percent[delegateHandle])).div(100);
        } else {
            balanceOf[contractOwner] += msg.value;
        }
        emit PaymentDone(receipts[paymentId], amounts[paymentId], paymentId, block.timestamp);
    }

    // Anyone can withraw funds to any participating delegate
    function withdraw(uint256 amount, string memory delegateHandle) external returns (bytes memory) {
        require(amount <= balanceOf[delegationOwner[delegateHandle]]);
        balanceOf[delegationOwner[delegateHandle]] -= amount;
        (bool sent, bytes memory data) = delegationWithdrawAddress[delegateHandle].call{value: amount, gas: 40000}("");
        require(sent, "Failed to  withdraw");
        return data;
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
        // transfer balance of old owner to new owner
        uint256 ownerAmount = balanceOf[oldOwner];
        // delete balance of old owner
        balanceOf[oldOwner] = 0;
        contractOwner = newOwner;
        // set new owner
        delegationOwner["IDriss"] = newOwner;
        // set balance of new owner
        balanceOf[newOwner] = ownerAmount;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}