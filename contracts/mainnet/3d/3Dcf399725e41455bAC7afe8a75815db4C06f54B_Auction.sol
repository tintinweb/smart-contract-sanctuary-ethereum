// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "Ownable.sol";
import "Pausable.sol";
import "SafeMath.sol";
import "IAllocationMinter.sol";

contract Auction is Ownable, Pausable {
    using SafeMath for uint;

    IAllocationMinter public immutable token;
    bytes32 public immutable allocationRole;

    // project-specific multisig address where raised funds will be sent
    address payable destAddress;

    uint public secondsPerAuction;
    uint public currentAuction;
    uint public currentAuctionEndTime;
    uint public totalContributed;
    uint public totalEmitted;
    uint public ewma;

    // The number of participants in a particular auction.
    mapping(uint => uint) public auctionMemberCount;
    // The participants in a particular auction.
    mapping(uint => address[]) public auctionMembers;
    // The total units contributed in a particular auction.
    mapping(uint => uint) public auctionUnits;
    // The remaining unclaimed units from a particular auction.
    mapping(uint => uint) public auctionUnitsRemaining;
    // All tokens auctioned in a paticular auction.
    mapping(uint => uint) public auctionSupply;
    // The remaining unclaimed tokens from a particular auction.
    mapping(uint => uint) public auctionSupplyRemaining;
    // Participant's remaining (unclaimed) units for a particular auction.
    mapping(uint => mapping(address => uint)) public auctionMemberUnitsRemaining;
    // Participant's particular auctions.
    mapping(address => uint[]) public memberAuctions;

    // Events
    event NewAuction(uint auction, uint endTime, uint previousAuctionTotal, uint previousAuctionEmission, uint historicEWMA, uint previousAuctionMembers);
    event Contribution(address indexed payer, address indexed member, uint auction, uint units, uint dailyTotal);
    event Claim(address indexed caller, address indexed member, uint auction, uint value, uint remaining);

    constructor(address payable daoMultisig, IAllocationMinter token_, bytes32 allocationRole_, uint secondsPerAuction_) {
        require(address(daoMultisig) != address(0), "Invalid daoMultisig address");
        require(address(token_) != address(0), "Invalid token_ address");

        _transferOwnership(daoMultisig);

        token = token_;
        allocationRole = allocationRole_;
        destAddress = daoMultisig;
        secondsPerAuction = secondsPerAuction_;
        currentAuction = 1;
        currentAuctionEndTime = block.timestamp + secondsPerAuction;
        require(token_.allocationMinted(allocationRole_) == 0, "auction allocation must have a clean slate");
        uint256 available = token_.allocationSupplyAt(allocationRole_, currentAuctionEndTime);
        auctionSupply[currentAuction] = available;
        auctionSupplyRemaining[currentAuction] = available;
    }

    function setDestAddress(address payable destAddress_)
        public
        onlyOwner()
    {
        require(address(destAddress_) != address(0), "invalid destAddress_");
        destAddress = destAddress_;
    }

    receive()
        external payable
        whenNotPaused
    {
        _contributeFor(msg.sender);
    }

    function contributeFor(address member)
        external payable
        whenNotPaused
    {
        _contributeFor(member);
    }

    function auctionsContributed(address member)
        public view
        returns (uint)
    {
        return memberAuctions[member].length;
    }

    function claim()
        external
        whenNotPaused
        returns (uint value)
    {
        _checkpoint();
        uint length = memberAuctions[msg.sender].length;
        for (uint i = 0; i < length; ++i) {
            uint auction = memberAuctions[msg.sender][i];
            if (auction < currentAuction) {
                uint memberUnits = auctionMemberUnitsRemaining[auction][msg.sender];
                if (memberUnits != 0) {
                    value += _prepareClaim(auction, msg.sender, memberUnits);
                }
            }
        }
        _mint(msg.sender, value);
    }

    function emissionShare(uint auction, address member)
        public view
        returns (uint value)
    {
        uint memberUnits = auctionMemberUnitsRemaining[auction][member];
        if (memberUnits != 0) {
            uint totalUnits = auctionUnitsRemaining[auction];
            uint emissionRemaining = auctionSupplyRemaining[auction];
            value = (emissionRemaining * memberUnits) / totalUnits;
        }
    }

    function impliedPriceEWMA(bool includeCurrent) public view returns (uint) {
        return ewma == 0 || includeCurrent ? computeEWMA() : ewma;
    }

    function computeEWMA() public view returns (uint) {
        uint price = 10**9 * (auctionUnits[currentAuction] / (auctionSupply[currentAuction] / 10**9));
		return ewma == 0 ? price : (7 * price + 3 * ewma) / 10; // alpha = 0.7
    }

    function checkpoint() external {
        _checkpoint();
    }

    function pause()
        public
        onlyOwner()
        whenNotPaused
    {
        _pause();
    }

    function unpause()
        public
        onlyOwner()
        whenPaused
    {
        _unpause();
    }

    function _checkpoint()
        private
    {
        if (block.timestamp >= currentAuctionEndTime) {
            uint units = auctionUnits[currentAuction];
            uint emission = auctionSupply[currentAuction];
			if (units > 0) {
				ewma = computeEWMA();
			}
            uint members = auctionMemberCount[currentAuction];
            currentAuctionEndTime = block.timestamp + secondsPerAuction;
            uint256 available = token.allocationSupplyAt(allocationRole, currentAuctionEndTime) - auctionSupply[currentAuction];

            currentAuction += 1;
            auctionSupply[currentAuction] = available;
            auctionSupplyRemaining[currentAuction] = available;

            emit NewAuction(currentAuction, currentAuctionEndTime, units, emission, ewma, members);
        }
    }

    function _contributeFor(address member)
        private
    {
        require(msg.value > 0, "ETH required");
        _checkpoint();
        _claimPrior(member);
        if (auctionMemberUnitsRemaining[currentAuction][member] == 0) {
            // If hasn't contributed to this Auction yet
            memberAuctions[member].push(currentAuction);
            auctionMemberCount[currentAuction] += 1;
            auctionMembers[currentAuction].push(member);
        }
        auctionMemberUnitsRemaining[currentAuction][member] += msg.value;
        auctionUnits[currentAuction] += msg.value;
        auctionUnitsRemaining[currentAuction] += msg.value;
        totalContributed += msg.value;
        (bool success,) = destAddress.call{value: msg.value}("");
        require(success, "");
        emit Contribution(msg.sender, member, currentAuction, msg.value, auctionUnits[currentAuction]);
    }

    function _claimPrior(address member) private {
        uint i = memberAuctions[member].length;
        while (i > 0) {
            --i;
            uint auction = memberAuctions[member][i];
            if (auction < currentAuction) {
                uint units = auctionMemberUnitsRemaining[auction][member];
                if (units > 0) {
                    _mint(member, _prepareClaim(auction, member, units));
                    //
                    // If a prior auction is found, then it is the only prior auction
                    // that has not already been withdrawn, so there's nothing left to do.
                    //
                    return;
                }
            }
        }
    }

    function _prepareClaim(uint _auction, address _member, uint memberUnits)
        private
        returns (uint value)
    {
        uint totalUnits = auctionUnitsRemaining[_auction];
        uint emissionRemaining = auctionSupplyRemaining[_auction];
        value = (emissionRemaining * memberUnits) / totalUnits;
        auctionMemberUnitsRemaining[_auction][_member] = 0; // since it will be withdrawn
        auctionUnitsRemaining[_auction] = auctionUnitsRemaining[_auction].sub(memberUnits);
        auctionSupplyRemaining[_auction] = auctionSupplyRemaining[_auction].sub(value);
        emit Claim(msg.sender, _member, _auction, value, auctionSupplyRemaining[_auction]);
    }
    
    function _mint(address member, uint value)
        private
    {
        token.allocationMint(member, allocationRole, value);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/math/SafeMath.sol)

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

pragma solidity ^0.8.2;

interface IAllocationMinter {
    function allocationSupplyAt(bytes32 role, uint256 timestamp) external view returns (uint256);
    function allocationAvailable(bytes32 role) external view returns (uint256);
    function allocationMint(address to, bytes32 role, uint256 amount) external;
    function allocationMinted(bytes32 role) external view returns (uint256);
}