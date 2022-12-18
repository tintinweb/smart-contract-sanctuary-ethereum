/**
 *Submitted for verification at Etherscan.io on 2022-12-18
*/

// SPDX-License-Identifier: MIT
// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.8.0/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.6.0/contracts/utils/math/SafeMath.sol


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

// File: contracts/celeste_treasury_dai.sol



pragma solidity >=0.5.12 <0.8.17;



// Adding only the DaiToken ERC-20 functions required
interface DaiToken is IERC20 {
    function transfer(address dst, uint wad) external returns (bool);
    function balanceOf(address guy) external view returns (uint);
}

// Contract is owned, set withdrawalsAllowed and constructor
contract owned {
    DaiToken daitoken;
    address owner;

// Disable or enable deposits and withdraw
    bool public withdrawalAllowed;

    constructor() {
        owner = msg.sender;
        daitoken = DaiToken(0xdc31Ee1784292379Fbb2964b3B9C4124D8F89C60);
        withdrawalAllowed = false;
    }

// Set the onlyOwner modifer
    modifier onlyOwner {
        require(msg.sender == owner,
        "Only the contract owner can call this function");
        _;
    }
}

// Contract is owned by onlyOwner
contract mortal is owned {

// Only owner can shutdown this contract.
    function destroy() public onlyOwner {
        daitoken.transfer(owner, daitoken.balanceOf(address(this)));
        selfdestruct(payable(msg.sender));
    }
}

// Primary contract functions
contract CelesteTreasury is mortal {
    using SafeMath for uint256;

// Mapping to track the DAI balance of each user
    mapping (address => uint256) public userBalances;
    address [] users;

// The minimum and maximum deposit amounts and withdrawal fee
    uint256 public MIN_DEPOSIT = 500;
    uint256 public MAX_DEPOSIT = 1000000;
    uint256 public WITHDRAWAL_FEE = 5;

// The contract owner can pause the contract, preventing any further deposits or withdrawals
    function pause() public onlyOwner {
        require(msg.sender == owner, "Only the contract owner can pause the contract");
        selfdestruct(payable(msg.sender));
    }

// Only the contract owner can enable or disable withdrawals
    function setWithdrawalAllowed(bool _withdrawalAllowed) public onlyOwner {
        require(msg.sender == owner, "Only the contract owner can enable/disable withdrawals");
        withdrawalAllowed = _withdrawalAllowed;
    }

    event Withdraw(address indexed to, uint amount);
    event Deposit(address indexed from, uint amount);

// Users can deposit DAI to the contract
    function deposit() public payable {
        bool withdrawalLock = false;

        // Access the contract's state before making the external call
        require(withdrawalAllowed, "Withdrawals are not currently allowed");
        require(msg.value >= MIN_DEPOSIT && msg.value <= MAX_DEPOSIT, "Invalid deposit amount");

        // Update the user's balance in the mapping
        userBalances[msg.sender] = userBalances[msg.sender].add(msg.value);
        emit Deposit(msg.sender, msg.value);

        // Use a reentrancy lock to prevent untrusted callees from re-entering the contract
        require(!withdrawalLock, "Reentrancy detected");
        withdrawalLock = true;

        // Transfer the DAI to the contract
        require(daitoken.transfer(msg.sender, msg.value), "Transfer failed");

        // Unlock the contract to allow future withdrawals
        withdrawalLock = false;
    }

// Users can withdraw their DAI from the contract less the withdrawal fee
    function withdraw(uint withdraw_amount) public {

        // Declare the withdrawalLock variable
        bool withdrawalLock = false;

        // Access the contract's state before making the external call
        require(withdrawalAllowed, "Withdrawals are not currently allowed");
        require(userBalances[msg.sender] >= withdraw_amount, "Insufficient balance");
        require(userBalances[msg.sender] >= WITHDRAWAL_FEE, "Insufficient balance to cover withdrawal fee");

        // Use the withdrawalLock variable to prevent untrusted callees from re-entering the contract
        require(!withdrawalLock, "Reentrancy detected");
        withdrawalLock = true;

        // Transfer the requested DAI to the user, less the withdrawal fee
        address payable recipient = payable (msg.sender);
        require(daitoken.transfer(recipient, withdraw_amount.sub(WITHDRAWAL_FEE)), "Transfer failed");

        // Update the user's balance in the mapping
        userBalances[msg.sender] = userBalances[msg.sender].sub(withdraw_amount);
        emit Withdraw(msg.sender, withdraw_amount);

        // Unlock the contract to allow future withdrawals
        withdrawalLock = false;
    }

// User can check their balance
    function checkBalance() public view returns (uint256) {
        return userBalances[msg.sender];
    }

// Owner can withdraw all the DAI from contract
    function withdrawAll() public onlyOwner {
        require(msg.sender == owner, "Only the contract owner can withdraw all DAI from the contract");

        // Transfer all DAI to the contract owner
        uint withdraw_amount = daitoken.balanceOf(address(this));
        require(daitoken.transfer(owner, withdraw_amount), "Transfer failed");

        // Update the contract owner's balance in the mapping
        userBalances[owner] = userBalances[owner].add(withdraw_amount);
    }

// Reset all userBalances to 0
    function resetBalance(uint256 value) public onlyOwner {
        for (uint i=0; i< users.length ; i++){
        userBalances[users[i]] = value;
        }
    }

// Only the contract owner can refund all users
    function refund() public onlyOwner {

        // Iterate through the list of users
        for (uint i = 0; i < users.length; i++) {

        // Get the address of the current user
        address user = users[i];

        // Check if the user has a balance
        if (userBalances[user] > 0) {

        // Calculate the amount to refund
        uint refundAmount = userBalances[user].sub(WITHDRAWAL_FEE);

        // Transfer the refund amount to the user
        require (daitoken.transfer(user, refundAmount), "Transfer failed");

        // Emit a Withdraw event
        emit Withdraw(user, refundAmount);
        }
        }
    }
}