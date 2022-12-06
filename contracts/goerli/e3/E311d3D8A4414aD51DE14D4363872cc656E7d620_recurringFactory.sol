//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./fintech_recurring.sol";

contract recurringFactory {
    Subscription[] public subscriptionAddresses;
    event SubscriptionCreated(Subscription subscription);

    address private metaCoinOwner;

    function createMetaCoin(uint256 _price, uint256 _numsubscriptions, string memory _name) external {
        Subscription subscription = new Subscription(_price, _numsubscriptions, _name);

        subscriptionAddresses.push(subscription);
        emit SubscriptionCreated(subscription);
    }

    function getMetaCoins() external view returns (Subscription[] memory) {
        return subscriptionAddresses;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

interface iUSDc {
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function balanceOf(address account) external view returns (uint);
}

interface iDai {
    function transferFrom(address src, address dst, uint wad) external returns (bool);
    function balanceOf(address guy) external view returns (uint);
}

interface iUSDt {
    function transferFrom(address _from, address _to, uint256 _value) external;
    function balanceOf(address who) external view returns (uint);
}

contract Subscription is Ownable {
    using SafeMath for uint256;

    uint256 public subscriptionPrice;
    uint256 public numSubscriptionLevels;
    bool public renewalsEnabled = true;
    string public name;
  
    mapping(address => uint256) public expiryTime;

    event renewed(address _addr, uint256 _expiryTime);

    iUSDc public USDc;
    iDai public Dai;
    iUSDt public USDt;

    constructor(uint256 _rate, uint256 _numsubscriptions, string memory _name) {
        subscriptionPrice = _rate * 1e18;
        numSubscriptionLevels = _numsubscriptions;
        name = _name;

        //below can be edited to just putting the actual addresses.
        USDc = iUSDc(0x07865c6E87B9F70255377e024ace6630C1Eaa37F);
        Dai = iDai(0x11fE4B6AE13d2a6055C8D9cF65c55bac32B5d844);
        USDt = iUSDt(0x11fE4B6AE13d2a6055C8D9cF65c55bac32B5d844);
    }

    // need to approve from FE first.
    function renewalStables(address _addr, uint256 _stablesId) public {
        require(renewalsEnabled, "Renewals are currently disabled");
        require(_stablesId <= 2);
        uint256 _currentexpiryTime = expiryTime[_addr];

        if (_stablesId == 0) {
            //usdc
            require(USDc.balanceOf(msg.sender) >= subscriptionPrice);
            USDc.transferFrom(msg.sender, address(this), subscriptionPrice);
        } else if (_stablesId == 1) {
            //dai
            require(Dai.balanceOf(msg.sender) >= subscriptionPrice);
            Dai.transferFrom(msg.sender, address(this), subscriptionPrice);
        } else {
            //usdt
            require(USDt.balanceOf(msg.sender) >= subscriptionPrice);
            USDt.transferFrom(msg.sender, address(this), subscriptionPrice);
        }

        if (block.timestamp > _currentexpiryTime) {
            expiryTime[_addr] = block.timestamp + 30 days;
        } else {
            expiryTime[_addr] += 30 days;
        }
        emit renewed(_addr, expiryTime[_addr]);
    }

    // renewal via eth. maybe not ideal due to continuous price fluctuations.
    // fixed price would work best, else the use of oracles to get eth/usd is needed
    function renewalEth(address _addr) public payable{
        require(msg.value >= subscriptionPrice, "Incorrect amount of ether sent.");
        require(renewalsEnabled, "Renewals are currently disabled");

        uint256 _currentexpiryTime = expiryTime[_addr];

        if (block.timestamp > _currentexpiryTime) {
            expiryTime[_addr] = block.timestamp + 30 days;
        } else {
            expiryTime[_addr] += 30 days;
        }
        emit renewed(_addr, expiryTime[_addr]);
    }
    
    function toggleRenewalsActive(bool _state) external onlyOwner {
        renewalsEnabled = _state;
    }

    // to counter inflation
    function updateSubscriptionPrice(uint256 _newPrice) external onlyOwner {
        require(subscriptionPrice != _newPrice, "Price did not change.");
        subscriptionPrice = _newPrice;
    }

    // this can be improved on to only call transferfrom for cryptos that balance is >0
    function withdraw() public payable onlyOwner {
        uint balance = address(this).balance;
        require(balance >= 0, "No ether left to withdraw");
        (bool success, ) = (msg.sender).call{value: balance}("");
        USDc.transferFrom(address(this), msg.sender, USDc.balanceOf(address(this)));
        Dai.transferFrom(address(this), msg.sender, Dai.balanceOf(address(this)));
        USDt.transferFrom(address(this), msg.sender, USDt.balanceOf(address(this)));
        require(success, "Transfer failed.");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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