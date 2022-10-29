//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import '@openzeppelin/contracts/utils/Context.sol';
import "@openzeppelin/contracts/utils/math/SafeMath.sol";


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

    using SafeMath for uint256;
    address public token;
    uint256 public totalVestingDays;
    uint256 public slicePeriod;
    uint256 public timeUnit;
    address public admin;
    address walletFactory;
    // uint256 launchedAt;

    struct claimInfo {
        bool initialized;
        address owner;
        uint totalEligible;
		uint totalClaimed;
		uint remainingBalTokens;
		uint lastClaimedAt;
        uint startTime;
    }

    mapping(address => mapping(address => claimInfo)) public userClaimData; 


    constructor (address _admin,address _creator,uint _totalDays, uint _slicePeriod, uint _timeUnit,uint tokenAmount, address _token,address _walletFactory) {

        totalVestingDays = _totalDays;
        slicePeriod = _slicePeriod;
        timeUnit = _timeUnit;
        token = _token;
        admin = _admin;
        walletFactory = _walletFactory;
        uint256 launchedAt = vestingContractFactory(_walletFactory).listedAt();

        uint256 currentTime = getCurrentTime();
        
        userClaimData[_creator][address(this)] = claimInfo({
            initialized:true,
            owner:_creator,
            totalEligible:tokenAmount,
            totalClaimed:0,
            remainingBalTokens:tokenAmount,
            lastClaimedAt:launchedAt,
            startTime:currentTime
        });
        
    }


    function getCurrentTime()internal virtual view
    returns(uint256){
        return block.timestamp;
    }

    function getLaunchedAt() public view returns(uint256 ) {
        return(vestingContractFactory(walletFactory).listedAt());
    }


    function getClaimableAmount(address _walletAddress,address _vestingAddress) public view returns(uint _claimAmount) {

        if(getLaunchedAt()==0) {
            return 0;
        }
        uint256 timeLeft = 0;
        uint slicePeriodSeconds = slicePeriod * timeUnit;
        uint256 claimAmount =0;
        uint256 _amount =0;

        uint256 currentTime = getCurrentTime();
        uint totalEligible = userClaimData[_walletAddress][_vestingAddress].totalEligible;
        uint lastClaimedAt = userClaimData[_walletAddress][_vestingAddress].lastClaimedAt;
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
            claimAmount = ((_amount*slicePeriod)/totalVestingDays)*(timeLeft/slicePeriodSeconds) ;
        }

        uint _lastReleaseAmount = userClaimData[_walletAddress][_vestingAddress].totalClaimed;

        uint256 temp = _lastReleaseAmount.add(claimAmount);

        if(temp > totalEligible){
            _amount = totalEligible.sub(_lastReleaseAmount);
            return (_amount);
        }
        return (claimAmount);
      
    }

    function claim(address _walletAddress,address _vestingAddress) public {
        require(getLaunchedAt() != 0,"Not yet launched");
        require(getClaimableAmount(_walletAddress,_vestingAddress)>0,'Insufficient funds to claims.');
        require( msg.sender==userClaimData[_walletAddress][_vestingAddress].owner,"You are not the owner");
        uint256 _amount = getClaimableAmount(_walletAddress,_vestingAddress);
        userClaimData[_walletAddress][_vestingAddress].totalClaimed += _amount;
        userClaimData[_walletAddress][_vestingAddress].remainingBalTokens = userClaimData[_walletAddress][_vestingAddress].totalEligible-userClaimData[_walletAddress][_vestingAddress].totalClaimed;
        userClaimData[_walletAddress][_vestingAddress].lastClaimedAt = getCurrentTime();
        IToken(token).transfer(_walletAddress, _amount);
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


contract vestingContractFactory {
 
    mapping(address => address[]) wallets;
    // launch Date - set

    address public admin;
    uint256 public listedAt;

    constructor () {
        admin = msg.sender;
    }


    function launch() external  {
        require(admin == msg.sender,"caller is not the admin ");
        require(listedAt == 0, "Already Listed!");
        listedAt = block.timestamp;
    }

    function setAdmin(address account) external  {
        require(admin == msg.sender,"caller is not the admin ");
        require(account != address(0),"Invalid Address, Address should not be zero");
        admin = account;
    }



    function getWallets(address _user)  
    external view
    returns (address[] memory)
    {
        return wallets[_user];
    }



    function newVestingWallet(address _admin,address _creator,uint256 _totalDays, uint256 _slicePeriod,uint _timeUnit,uint tokenAmount, address _token)
    external 
    returns(address wallet)
    {
        // Create new wallet.
        
        wallet = address(new vestingContract(_admin,_creator,_totalDays,_slicePeriod,_timeUnit,tokenAmount,_token,address(this)));
       
       // ERC20 _tokenAddress = tokenAddress;
        // Add wallet to sender's wallets.
        wallets[msg.sender].push(wallet);

        // If owner is the same as sender then add wallet to sender's wallets too.
        if(msg.sender != _creator){
            wallets[_creator].push(wallet);
        }

        return wallet;
        
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