/**
 *Submitted for verification at Etherscan.io on 2022-06-17
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
    mapping(bytes32 => address) public receipts;
    mapping(bytes32 => uint256) public amounts;
    mapping(address => uint256) public balanceOf; 
    mapping(string => address) public delegate;
    mapping(string => bytes32) public IDrissHashes;

    constructor() {
        delegate["IDriss"] = contractOwner;
        percent["IDriss"] = 100;
    }

    event PaymentDone(address indexed payer, uint256 amount, bytes32 paymentId_hash, string indexed IDrissHash, uint256 date);
    event AdminAdded(address indexed admin);
    event AdminDeleted(address indexed admin);
    event DelegateAdded(string delegateHandle, address indexed delegateAddress);
    event DelegateDeleted(string delegateHandle, address indexed delegateAddress);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

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

    function addDelegateException(address delegateAddress, string memory delegateHandle, uint256 percentage) external {
        require(msg.sender == contractOwner, "Only contractOwner can add special delegate partner.");
        require(delegate[delegateHandle] == address(0), "Delegate handle exists.");
        require(delegateAddress != address(0), "Ownable: delegateAddress is the zero address.");
        delegate[delegateHandle] = delegateAddress;
        percent[delegateHandle] = percentage;
        emit DelegateAdded(delegateHandle, delegateAddress);
    }

    // Anyone can create a delegate link for anyone
    function addDelegate(address delegateAddress, string memory delegateHandle) external {
        require(delegate[delegateHandle] == address(0), "Delegate handle exists.");
        require(delegateAddress != address(0), "Ownable: delegateAddress is the zero address.");
        delegate[delegateHandle] = delegateAddress;
        percent[delegateHandle] = 20;
        emit DelegateAdded(delegateHandle, delegateAddress);
    }

    // Delete the delegation link if needed.
    function deleteDelegate(string memory delegateHandle) external {
        require(msg.sender == delegate[delegateHandle], "Only delegate can delete delegation link.");
        address deletedDelegate = delegate[delegateHandle];
        delete delegate[delegateHandle];
        delete percent[delegateHandle];
        emit DelegateDeleted(delegateHandle, deletedDelegate);
    }

    // Payment function distributing the payment into two balances.
    function payNative(bytes32 paymentId_hash, string memory IDrissHash, string memory delegateHandle) external payable {
        require(receipts[paymentId_hash] == address(0), "Already paid this receipt.");
        receipts[paymentId_hash] = msg.sender;
        amounts[paymentId_hash] = msg.value;
        IDrissHashes[IDrissHash] = paymentId_hash;
        if (delegate[delegateHandle] != address(0)) {
            balanceOf[contractOwner] += msg.value.sub((msg.value.mul(percent[delegateHandle])).div(100));
            balanceOf[delegate[delegateHandle]] += (msg.value.mul(percent[delegateHandle])).div(100);
        } else {
            balanceOf[contractOwner] += msg.value;
        }
        emit PaymentDone(receipts[paymentId_hash], amounts[paymentId_hash], paymentId_hash, IDrissHash, block.timestamp);
    }

    // Anyone can withraw funds to any participating delegate
    function withdraw(uint256 amount, string memory delegateHandle) external returns (bytes memory) {
        require(amount <= balanceOf[delegate[delegateHandle]]);
        balanceOf[delegate[delegateHandle]] -= amount;
        (bool sent, bytes memory data) = delegate[delegateHandle].call{value: amount, gas: 40000}("");
        require(sent, "Failed to  withdraw");
        return data;
    }

    // commit payment hash creation
    function hashReceipt(string memory receiptId, address paymAddr) public pure returns (bytes32) {
        require(paymAddr != address(0), "Payment address cannot be null address.");
        return keccak256(abi.encode(receiptId, paymAddr));
    }

    // reveal payment hash
    function verifyReceipt(string memory receiptId, address paymAddr) public view returns (bool) {
        require(paymAddr != address(0), "Payment address cannot be null address.");
        require(receipts[hashReceipt(receiptId, paymAddr)] == paymAddr);
        return true;
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
        delegate["IDriss"] = newOwner;
        // set balance of new owner
        balanceOf[newOwner] = ownerAmount;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}