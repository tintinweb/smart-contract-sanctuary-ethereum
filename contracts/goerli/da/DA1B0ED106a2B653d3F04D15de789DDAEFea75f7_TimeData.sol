/**
 *Submitted for verification at Etherscan.io on 2023-03-03
*/

// SPDX-License-Identifier: MIT

// File: Context.sol

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
// File: Ownable.sol



pragma solidity ^0.8.0;


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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
// File: GetData1.sol



// File: SafeMath.sol

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
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
// File: GetData.sol


pragma solidity ^0.8.0;

// import "./interface.sol";


pragma solidity ^0.8.0;

interface NftInterface {
    function alive(uint256 tokenId) external view returns (bool);
    function Unit(uint256 tokenId) external view returns (
        string memory name_, uint256 createdAt_, uint256 feedLevel_,
        uint256 generation_, uint256 generationTicker_, uint256 lastPlayTime_,
        uint256 availableFreeDays_, uint256 prestige_, uint256 rewards_,
        uint256 tokensToRevive_, uint256 packChoice
    );
}

contract TimeData is Ownable {
    using SafeMath for uint256;

    uint256 public ONE_DAY = 86400;
    uint256 public ONE_HOUR = 3600; 
    uint256 public MAX_TIME = 2**256 - 1;
    
    address public NftAddress = 0xA719215571Eb6049AbCdBB6600568E546C89C28c; // change to mainnet pet contract
    
    function updateAddress(address _address) public onlyOwner {
        NftAddress = _address;
    }

    function getTimeData(uint256 tokenId) public view returns (
        bool isItPlayTime_, uint256 secondsUntilNextPlay_, uint256 timeBetweenPlays_, uint256 playsPerGeneration_,
        bool isInFeedWindow_, uint256 secondsUntilNextFeed_, uint256 secondsLeftInFeedWindow_ ) {( 
            ,uint256 createdAt_, uint256 feedLevel_, uint256 generation_,,
            uint256 lastPlayTime_,, uint256 prestige_,,,
        ) = NftInterface(NftAddress).Unit(tokenId);
            
        uint256 elapsed;
        
        if (createdAt_ != MAX_TIME && NftInterface(NftAddress).alive(tokenId)) {
            
            if (block.timestamp.sub(lastPlayTime_) > ONE_HOUR.add(prestige_.mul(ONE_HOUR))) { // in play
                elapsed = block.timestamp.sub(lastPlayTime_);
                if (feedLevel_ > uint256(block.timestamp.sub(createdAt_)).div(ONE_DAY)) { // not in a feed
                    return (
                        true, 0, ONE_HOUR.add(prestige_.mul(ONE_HOUR)), generation_,  
                        false, feedLevel_.mul(ONE_DAY).sub(block.timestamp.sub(createdAt_)), ONE_HOUR.mul(generation_) 
                    );
                }
                if (feedLevel_ == uint256(block.timestamp.sub(createdAt_)).div(ONE_DAY) && block.timestamp.sub(createdAt_).mod(ONE_DAY) < ONE_HOUR.mul(generation_)) { // in feeding window
                    return (
                        true, 0, ONE_HOUR.add(prestige_.mul(ONE_HOUR)), generation_, 
                        true, 0,  ONE_HOUR.mul(generation_).sub(block.timestamp.sub(createdAt_).mod(ONE_DAY))
                    );
                }
            } else { // not in play
                elapsed = block.timestamp.sub(lastPlayTime_);
                if (feedLevel_ > uint256(block.timestamp.sub(createdAt_)).div(ONE_DAY)) {  // not in a feed
                    return (
                        false, ONE_HOUR.add(prestige_.mul(ONE_HOUR)).sub(elapsed), ONE_HOUR.add(prestige_.mul(ONE_HOUR)), generation_, 
                        false, feedLevel_.mul(ONE_DAY).sub(block.timestamp.sub(createdAt_)), ONE_HOUR.mul(generation_)
                    );
                }
                if (feedLevel_ == uint256(block.timestamp.sub(createdAt_)).div(ONE_DAY) && block.timestamp.sub(createdAt_).mod(ONE_DAY) < ONE_HOUR.mul(generation_)) { // in feeding window
                    return (
                        false, ONE_HOUR.add(prestige_.mul(ONE_HOUR)).sub(elapsed), ONE_HOUR.add(prestige_.mul(ONE_HOUR)), generation_, 
                        true, 0, ONE_HOUR.mul(generation_).sub(block.timestamp.sub(createdAt_).mod(ONE_DAY))
                    );
                }
            }
        }
        return (false, 0, 0, 0, false, 0, 0);
    }
}