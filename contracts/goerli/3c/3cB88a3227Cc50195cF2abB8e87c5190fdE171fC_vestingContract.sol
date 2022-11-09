//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import '@openzeppelin/contracts/utils/Context.sol';
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";


interface IToken {
    function transfer(address to, uint256 tokens)
        external
        returns (bool success);

    function burn(uint256 _amount) external;

    function balanceOf(address tokenOwner)
        external
        view
        returns (uint256 balance);

    function decimals() external
        view
        returns (uint256);
}


contract vestingContract {


    using Counters for Counters.Counter;
    using SafeMath for uint256;
    address public token;

    uint256 public timeUnit;
    address public admin;
    address walletFactory;
    // uint256 launchedAt;

     mapping(address => uint256[]) wallets;
    // launch Date - set

    // address public admin;
    uint256 public listedAt;
    Counters.Counter public _id;

    constructor (address _token) {
        admin = msg.sender;
        timeUnit = 60;
        token = _token;
       
        
    }


    struct claimInfo {
        bool initialized;
        address owner;
        uint totalEligible;
		uint totalClaimed;
		uint remainingBalTokens;
		uint lastClaimedAt;
        uint startTime;
        uint totalVestingDays;
        uint slicePeriod;

    }

    mapping(address => mapping(uint256 => claimInfo)) public userClaimData; 

    function launch() external  {
        require(admin == msg.sender,"caller is not the admin ");
        require(listedAt == 0, "Already Listed!");
        listedAt = block.timestamp;
    }

   
    function editListedAt(uint256 _time) public {
        require(admin == msg.sender,"caller is not the admin ");
        listedAt = _time;
    }

    function createVesting (address _creator,uint _totalDays, uint _slicePeriod,uint tokenAmount) public {
        
        
        uint256 launchedAt = listedAt;

        uint256 currentTime = getCurrentTime();
        _id.increment();
        
        wallets[_creator].push(_id.current());
        
        userClaimData[_creator][_id.current()] = claimInfo({
            initialized:true,
            owner:_creator,
            totalEligible:tokenAmount,
            totalClaimed:0,
            remainingBalTokens:tokenAmount,
            lastClaimedAt:launchedAt,
            startTime:currentTime,
            totalVestingDays:_totalDays,
            slicePeriod:_slicePeriod
        });
        
    }


    function getCurrentTime()internal virtual view
    returns(uint256){
        return block.timestamp;
    }

    function getLaunchedAt() public view returns(uint256 ) {
        return(listedAt);
    }


    function getClaimableAmount(address _walletAddress,uint256 _vestingId) public view returns(uint _claimAmount) {

        if(getLaunchedAt()==0) {
            return 0;
        }

        claimInfo storage userData = userClaimData[_walletAddress][_vestingId];        
        uint256 timeLeft = 0;
        uint slicePeriodSeconds = userData.slicePeriod * timeUnit;
        uint256 claimAmount =0;
        uint256 _amount =0;

        uint256 currentTime = getCurrentTime();
        uint totalEligible = userData.totalEligible;
        uint lastClaimedAt = userData.lastClaimedAt;
        if(getLaunchedAt() !=0 && lastClaimedAt==0){
            if(currentTime>getLaunchedAt()){
            timeLeft = currentTime.sub(getLaunchedAt());
      
            }else{
            timeLeft =  getLaunchedAt().sub(currentTime);
            }

        }else{
            
            if(currentTime>lastClaimedAt){
            timeLeft = currentTime.sub(lastClaimedAt);
      
            }else{
            timeLeft =  lastClaimedAt.sub(currentTime);
            }

        }
        _amount = totalEligible;

        if(timeLeft/slicePeriodSeconds > 0){
            claimAmount = ((_amount*userData.slicePeriod)/userData.totalVestingDays)*(timeLeft/slicePeriodSeconds) ;
        }

        uint _lastReleaseAmount = userData.totalClaimed;

        uint256 temp = _lastReleaseAmount.add(claimAmount);

        if(temp > totalEligible){
            _amount = totalEligible.sub(_lastReleaseAmount);
            return (_amount);
        }
        return (claimAmount);
      
    }

    function claim(address _walletAddress,uint256 _vestingId) public {
        require(getLaunchedAt() != 0,"Not yet launched");
        require(getClaimableAmount(_walletAddress,_vestingId)>0,'Insufficient funds to claims.');
        require( msg.sender==userClaimData[_walletAddress][_vestingId].owner,"You are not the owner");
        uint256 _amount = getClaimableAmount(_walletAddress,_vestingId);
        userClaimData[_walletAddress][_vestingId].totalClaimed += _amount;
        userClaimData[_walletAddress][_vestingId].remainingBalTokens = userClaimData[_walletAddress][_vestingId].totalEligible-userClaimData[_walletAddress][_vestingId].totalClaimed;
        userClaimData[_walletAddress][_vestingId].lastClaimedAt = getCurrentTime();
        IToken(token).transfer(_walletAddress, _amount);
    }


    function setAdmin(address account) external  {
        require(admin == msg.sender,"caller is not the admin ");
        require(account != address(0),"Invalid Address, Address should not be zero");
        admin = account;
    }

    function getWallets(address _walletAddress)  
    external view
    returns (uint[] memory)
    {
        return wallets[_walletAddress];
    }

    // remove token for admin

    function balance() public view returns(uint256){
        return IToken(token).balanceOf(address(this));
    }

    function removeERC20() public {
        require(admin == msg.sender,"caller is not the admin ");
        IToken(token).transfer(admin,IToken(token).balanceOf(address(this)));
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
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