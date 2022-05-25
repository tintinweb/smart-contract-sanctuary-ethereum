// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import "./MultiSend.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// import "@openzeppelin/contracts/security/ReentrancyGuard.sol"; will import later

contract CryptoGame is Ownable, MultiSend {
    using SafeMath for uint256;

    address payable[] private t1Players;
    address payable[] private t2Players;
    address payable[] private t3Players;

    uint256 immutable t1EntrenceFee = 1 * (10**17);
    uint256 immutable t2EntrenceFee = 1 * (10**16);
    uint256 immutable t3EntrenceFee = 1 * (10**15);

    Tier public t1;
    Tier public t2;
    Tier public t3;

    // Mapping that stores all registered users
    mapping(address => bool) public _registered;

    // User(only registered) states
    enum Tiers {
        TIER1,
        TIER2,
        TIER3
    }

    // Custom data type of a tir
    struct Tier {
        Tiers tier;
    }

    constructor() {
        t1.tier = Tiers.TIER1;
        t2.tier = Tiers.TIER2;
        t3.tier = Tiers.TIER3;
    }

    // Event that triggers everytime someone enters the game
    event Registered(address user, Tiers tier);

    // Function for Owner to withdraw funds from contract
    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    // Pure function that returns User tier based on msg.value(The value is hardcoded) they sent
    function getUserTier(uint256 amount) public pure returns (Tiers) {
        if (amount == t1EntrenceFee) {
            return Tiers.TIER1;
        } else if (amount == t2EntrenceFee) {
            return Tiers.TIER2;
        } else if (amount == t3EntrenceFee) {
            return Tiers.TIER3;
        } else {
            revert("Not right amount");
        }
    }

    // Function that "converts"(makes another list) our specific list of players to list memory
    // It creates an instance, which appends elements of tNPlayers in a loop
    function createRecipientList(address payable[] memory _list)
        private
        pure
        returns (address payable[] memory)
    {
        address payable[] memory list = new address payable[](_list.length);
        for (uint256 i = 0; i < _list.length; i++) {
            list[i] = _list[i];
        }
        return list;
    }

    // Function that returns a list of uint, where each element represents user's payment
    function getRecipientValue(uint256 _value, uint256 _length)
        private
        pure
        returns (uint256[] memory)
    {
        uint256[] memory value = new uint256[](_length);
        uint256 temporary = ((_value / 100) * 74) / _length;
        for (uint256 i = 0; i < _length; i++) {
            value[i] = temporary;
        }
        return value;
    }

    // Function that combines all logic above
    // It checks if User is registered, if not
    // This function will append him to the tier list based on a value was sent
    // After that it takes 74% of of that value divided by the amount of users with higher tier
    // And sends funds to each of them
    // In the end emits Registered event, which will not allow to use this function twice from the same wallet
    function register() public payable {
        require(!_registered[msg.sender], "Already registered");
        require(msg.value >= 1 * (10**15), "Not enough funds");
        _registered[msg.sender] = true;

        address payable[] memory _t1recipients = createRecipientList(t1Players);
        address payable[] memory _t2recipients = createRecipientList(t2Players);

        if (getUserTier(msg.value) == Tiers.TIER1) {
            t1Players.push(payable(msg.sender));
        } else if (getUserTier(msg.value) == Tiers.TIER2) {
            t2Players.push(payable(msg.sender));
            uint256[] memory _value = getRecipientValue(
                msg.value,
                t1Players.length
            );
            withdrawls(_t1recipients, _value);
        } else if (getUserTier(msg.value) == Tiers.TIER3) {
            t3Players.push(payable(msg.sender));
            uint256 _tempLength = t1Players.length + t2Players.length;
            uint256[] memory _value = getRecipientValue(msg.value, _tempLength);
            withdrawls(_t1recipients, _value);
            withdrawls(_t2recipients, _value);
        } else {
            revert("Insufficient amount");
        }

        Tiers tier = getUserTier(msg.value);

        emit Registered(msg.sender, tier);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

abstract contract MultiSend {
    // to save the owner of the contract in construction
    address private owner;

    // to save the amount of ethers in the smart-contract
    uint256 total_value;

    // event for EVM logging
    event OwnerSet(address indexed oldOwner, address indexed newOwner);

    // modifier to check if the caller is owner
    modifier isOwner() {
        // If the first argument of 'require' evaluates to 'false', execution terminates and all
        // changes to the state and to Ether balances are reverted.
        // This used to consume all gas in old EVM versions, but not anymore.
        // It is often a good idea to use 'require' to check if functions are called correctly.
        // As a second argument, you can also provide an explanation about what went wrong.
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    /**
     * @dev Set contract deployer as owner
     */
    constructor() payable {
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
        emit OwnerSet(address(0), owner);

        total_value = msg.value; // msg.value is the ethers of the transaction
    }

    // the owner of the smart-contract can chage its owner to whoever
    // he/she wants
    function changeOwner(address newOwner) public isOwner {
        emit OwnerSet(owner, newOwner);
        owner = newOwner;
    }

    /**
     * @dev Return owner address
     * @return address of owner
     */
    function getOwner() external view returns (address) {
        return owner;
    }

    // charge enable the owner to store ether in the smart-contract
    function charge() public payable isOwner {
        // adding the message value to the smart contract
        total_value += msg.value;
    }

    // sum adds the different elements of the array and return its sum
    function sum(uint256[] memory amounts)
        private
        pure
        returns (uint256 retVal)
    {
        // the value of message should be exact of total amounts
        uint256 totalAmnt = 0;

        for (uint256 i = 0; i < amounts.length; i++) {
            totalAmnt += amounts[i];
        }

        return totalAmnt;
    }

    // withdraw perform the transfering of ethers
    function withdraw(address payable receiverAddr, uint256 receiverAmnt)
        private
    {
        receiverAddr.transfer(receiverAmnt);
    }

    // withdrawls enable to multiple withdraws to different accounts
    // at one call, and decrease the network fee
    function withdrawls(address payable[] memory addrs, uint256[] memory amnts)
        public
        payable
    {
        // first of all, add the value of the transaction to the total_value
        // of the smart-contract
        total_value += msg.value;

        // the addresses and amounts should be same in length
        require(
            addrs.length == amnts.length,
            "The length of two array should be the same"
        );

        // the value of the message in addition to sotred value should be more than total amounts
        uint256 totalAmnt = sum(amnts);

        require(
            total_value >= totalAmnt,
            "The value is not sufficient or exceed"
        );

        for (uint256 i = 0; i < addrs.length; i++) {
            // first subtract the transferring amount from the total_value
            // of the smart-contract then send it to the receiver
            total_value -= amnts[i];

            // send the specified amount to the recipient
            withdraw(addrs[i], amnts[i]);
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