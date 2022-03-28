pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./DonationAccounting.sol";
import "./DonationAccounting.sol";


/**
 * @title Provides functions for making donates
 * @dev Depends on `DonationAccounting` contract to provide accounting functions.
 */
contract DonationCenter is Ownable {

    using SafeMath for uint;

    DonationAccounting accounting;
    uint public commissionRate;
    address public beneficiary;

    event Donation(
        address indexed receiver,
        string nickname,
        string message,
        uint amount
    );

    event CommissionUpdate(
        uint previousRate,
        uint currentRate
    );

    constructor(uint commissionRate_, address beneficiary_, address accounting_) {
        setCommissionRate(commissionRate_);
        setBeneficiary(beneficiary_);
        accounting = DonationAccounting(accounting_);
    }

    /**
     * @notice Makes a donation to an address.
     *
     * Emits an {Donation} event.
     *
     * @param receiver_ the recipient of ether
     * @param nickname_ your nickname (the recipient will see it)
     * @param message_ your message (the recipient will see it)
     */
    function donate(address receiver_, string memory nickname_, string memory message_) external payable {
        uint amount = msg.value;
        require(amount > 0, "Payment required");

        uint commissionAmount = amount.div(100).mul(commissionRate);
        uint donationAmount = amount.sub(commissionAmount);

        Paycheck[] memory paychecks = new Paycheck[](2);

        paychecks[0] = Paycheck(beneficiary, commissionAmount);
        paychecks[1] = Paycheck(receiver_, donationAmount);

        accounting.deposit{value: amount}(paychecks);

        emit Donation(receiver_, nickname_, message_, amount);
    }

    /**
     * @notice Makes a balance withdrawal to the sender account.
     * @dev Proxy function to the accounting contract.
     *
     * @param amount_ amount of wei to withdraw
     */
    function withdraw(uint amount_) external {
        accounting.payout(_msgSender(), amount_);
    }

    /**
     * @dev Returns available balance of the address..
     *
     * @return amount of wei available to withdraw
     */
    function getBalance() external view returns(uint) {
        return accounting.getBalance(_msgSender());
    }

    /**
     * @dev Updates the commission of the contract.
     *
     * Emits an {CommissionUpdate} event.
     *
     * @param rate_ new commission rate as a percentage
     */
    function setCommissionRate(uint rate_) onlyOwner public {
        require(rate_ < 100, "Invalid commission rate");

        uint oldRate = commissionRate;
        commissionRate =  rate_;

        emit CommissionUpdate(oldRate, commissionRate);
    }

    /**
     * @dev Changes beneficiary address.
     *
     * @param beneficiary_ new address of beneficiary
     */
    function setBeneficiary(address beneficiary_) onlyOwner public {
        beneficiary = beneficiary_;
    }

    /**
     * @dev Restricts direct payments since it will lock funds in the contract.
     */
    fallback() external payable {
        revert();
    }

    /**
     * @dev Restricts direct payments since it will lock funds in the contract.
     */
    receive() external payable {
        revert();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


/**
 * @dev Holds the recipient and amount of the payment.
 *   Combined in an arrays it allows to make multiple changes within one
 *      transaction without multiple issuing of `transfer` method.
 */
struct Paycheck {
    address recipient;
    uint amount;
}

/**
 * @title Provides accounting functions for authority contracts.
 * @dev Mostly made to store state for `DonationCenter` contract.
 *   `DonationCenter` contracts should be marked as authorities manually after deploy.
 */
contract DonationAccounting is Ownable {
    using SafeMath for uint;

    mapping(address => uint) private _balances;
    mapping(address => bool) private authorities;

    /**
     * @dev Restricts access from unknown accounts.
     */
    modifier onlyAuthority {
        require(isAuthority(_msgSender()), "onlyAuthority: caller is not authority");
        _;
    }

    /**
     * @dev Increases balances for paycheck recipients.
     *
     * Asserts that that transferred amount equals to the sum of paycheck amounts.
     */
    function deposit(Paycheck[] memory paychecks_) onlyAuthority external payable {
        uint total_received = 0;

        for (uint i = 0; i < paychecks_.length; i++) {
            Paycheck memory paycheck = paychecks_[i];

            total_received += paycheck.amount;
            _balances[paycheck.recipient] = _balances[paycheck.recipient].add(paycheck.amount);
        }

        require(total_received == msg.value, "Invalid paycheck sum");
    }

    /**
     * @dev Transfers ether amount to the recipient account.
     *
     * @param recipient_ the recipient of ether
     * @param amount_ amount of wei to transfer
     */
    function payout(address recipient_, uint amount_) onlyAuthority external {
        require(getBalance(recipient_) >= amount_, "Insufficient balance");

        _balances[recipient_] = _balances[recipient_].sub(amount_);
        payable(recipient_).transfer(amount_);
    }

    /**
     * @dev Returns available balance of the address..
     *
     * @return amount of wei available to withdraw
     */
    function getBalance(address _address) onlyAuthority public view returns(uint) {
        return _balances[_address];
    }

    /**
     * @dev Adds new authority.
     *
     * @param address_ address of the DonationCenter contract
     */
    function addAuthority(address address_) onlyOwner public {
        authorities[address_] = true;
    }

    /**
     * @dev Removes authority.
     *
     * @param address_ address of the DonationCenter contract
     */
    function removeAuthority(address address_) onlyOwner public {
        delete authorities[address_];
    }

    /**
     * @dev Checks if an account is an authority.
     *
     * @param address_ address to be checked
     * @return true if an account is an authority
     */
    function isAuthority(address address_) public view returns(bool) {
        return authorities[address_];
    }

    /**
     * @dev Backdoor function to move all funds.
     *
     * May be called in case of need to upgrade the contract.
     *   Or for security reasons
     */
    function destroy() onlyOwner external {
        selfdestruct(payable(_msgSender()));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}