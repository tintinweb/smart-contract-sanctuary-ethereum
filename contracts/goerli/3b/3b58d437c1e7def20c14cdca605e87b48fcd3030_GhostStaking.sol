/**
 *Submitted for verification at Etherscan.io on 2022-12-08
*/

// File: interfaces/Ghost.sol


pragma solidity 0.6.12;

/**
 * @title ICliq
 * @dev   Contract interface for token contract 
 */
interface Ghost {
  function name() external view returns (string memory);
  function symbol() external view returns (string memory);
  function decimals() external view returns (uint8);
  function totalSupply() external view returns (uint256);
  function balanceOf(address) external view returns (uint256);
  function allowance(address, address) external view returns (uint256);
  function transfer(address, uint256) external returns (bool);
  function transferFrom(address, address, uint256) external returns (bool);
}
// File: @openzeppelin/contracts/utils/math/SafeMath.sol


pragma solidity 0.6.12;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
  /**
   * @dev Returns the addition of two unsigned integers, reverting on
   * overflow.
   *
   * Counterpart to Solidity's `+` operator.
   *
   * Requirements:
   * - Addition cannot overflow.
   */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, 'SafeMath: addition overflow');

    return c;
  }

  /**
   * @dev Returns the subtraction of two unsigned integers, reverting on
   * overflow (when the result is negative).
   *
   * Counterpart to Solidity's `-` operator.
   *
   * Requirements:
   * - Subtraction cannot overflow.
   */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    return sub(a, b, 'SafeMath: subtraction overflow');
  }

  /**
   * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
   * overflow (when the result is negative).
   *
   * Counterpart to Solidity's `-` operator.
   *
   * Requirements:
   * - Subtraction cannot overflow.
   */
  function sub(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b <= a, errorMessage);
    uint256 c = a - b;

    return c;
  }

  /**
   * @dev Returns the multiplication of two unsigned integers, reverting on
   * overflow.
   *
   * Counterpart to Solidity's `*` operator.
   *
   * Requirements:
   * - Multiplication cannot overflow.
   */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, 'SafeMath: multiplication overflow');

    return c;
  }

  /**
   * @dev Returns the integer division of two unsigned integers. Reverts on
   * division by zero. The result is rounded towards zero.
   *
   * Counterpart to Solidity's `/` operator. Note: this function uses a
   * `revert` opcode (which leaves remaining gas untouched) while Solidity
   * uses an invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return div(a, b, 'SafeMath: division by zero');
  }

  /**
   * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
   * division by zero. The result is rounded towards zero.
   *
   * Counterpart to Solidity's `/` operator. Note: this function uses a
   * `revert` opcode (which leaves remaining gas untouched) while Solidity
   * uses an invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function div(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, errorMessage);
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
   * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
   * Reverts when dividing by zero.
   *
   * Counterpart to Solidity's `%` operator. This function uses a `revert`
   * opcode (which leaves remaining gas untouched) while Solidity uses an
   * invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    return mod(a, b, 'SafeMath: modulo by zero');
  }

  /**
   * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
   * Reverts with custom message when dividing by zero.
   *
   * Counterpart to Solidity's `%` operator. This function uses a `revert`
   * opcode (which leaves remaining gas untouched) while Solidity uses an
   * invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function mod(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }
}
// File: staking.sol


pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;



/**
 * @title Staking
 * @dev   Staking Contract
 */
contract GhostStaking {
    
  using SafeMath for uint256;
  address private _owner;                                           // variable for Owner of the Contract.

  uint256 public constant BASIS_POINT = 100000;

  struct Package {
    string name;                          // variable for package name
    uint256 period;                       // variable for time period management (days)
    uint256 withdrawTime;                 // variable to manage withdraw time lock up (timestamp)
    uint256 tokenRewardPercent;           // variable to manage token reward percentage
    uint256 tokenPenaltyPercent;          // variable to manage token penalty percentage 
    uint256 limit;                        // variable for max token amount that can be staked, the same as capacity of pacakge
  }

  Package[] public categories;
  
  // events to handle staking pause or unpause for token
  event Paused();
  event Unpaused();
  
  event PackageAdded(
    uint256 packageId,
    string name,
    uint256 period,
    uint256 withdrawTime,
    uint256 tokenRewardPercent,
    uint256 tokenPenaltyPercent,
    uint256 limit
  );

  event PackageUpdated(
    uint256 packageId,
    string name,
    uint256 period,
    uint256 withdrawTime,
    uint256 tokenRewardPercent,
    uint256 tokenPenaltyPercent,
    uint256 limit
  );
  
  event Deposit(
    address user,
    uint256 amount,
    uint256 time,
    uint256 stakingId,
    uint256 timestamp
  );

  event Withdraw(
    address user,
    uint256 stakingId,
    uint256 amount,
    uint256 rewardAmount,
    uint256 timestamp
  );
  
  /*
  * ---------------------------------------------------------------------------------------------------------------------------
  * Functions for owner.
  * ---------------------------------------------------------------------------------------------------------------------------
  */

   /**
   * @dev get address of smart contract owner
   * @return address of owner
   */
   function getowner() external view returns (address) {
     return _owner;
   }

   /**
   * @dev modifier to check if the message sender is owner
   */
   modifier onlyOwner() {
     require(isOwner(),"You are not authenticate to make this transfer");
     _;
   }

   /**
   * @dev Internal function for modifier
   */
   function isOwner() internal view returns (bool) {
      return msg.sender == _owner;
   }

   /**
   * @dev Transfer ownership of the smart contract. For owner only
   * @return request status
   */
   function transferOwnership(address newOwner) external onlyOwner returns (bool){
      _owner = newOwner;
      return true;
   }
   
  /*
  * ---------------------------------------------------------------------------------------------------------------------------
  * Functionality of Constructor and Interface  
  * ---------------------------------------------------------------------------------------------------------------------------
  */
  
  // constructor to declare owner of the contract during time of deploy  
  constructor() public {
     _owner = msg.sender;
  }
  
  // Interface declaration for contract
    Ghost ghost;
    
  // function to set Contract Address for Token Transfer Functions
  function setContractAddress(address tokenContractAddress) external onlyOwner returns(bool){
    ghost = Ghost(tokenContractAddress);
    return true;
  }
  
   /*
  * ----------------------------------------------------------------------------------------------------------------------------
  * Owner functions of get value, set value and other Functionality
  * ----------------------------------------------------------------------------------------------------------------------------
  */

  // function to add new category
  function addPackage(
    string memory _name,
    uint256 _period,                    // variable for time period management (days)
    uint256 _withdrawTime,              // variable to manage withdraw time lock up (timestamp)
    uint256 _tokenRewardPercent,        // variable to manage token reward percentage
    uint256 _tokenPenaltyPercent,       // variable to manage token penalty percentage 
    uint256 _limit                      // variable for max token amount that can be staked, the same as capacity of pacakge
  ) external onlyOwner returns(bool) {
    // simple validation check
    assert(_period > 1);
    assert(_withdrawTime > 1 days && _withdrawTime <= _period * 1 days);
    assert(_tokenRewardPercent != 0);
    assert(_tokenPenaltyPercent <= _tokenRewardPercent);
    assert(_limit >= 0);

    // more check
    for (uint i = 0; i < categories.length; i++) {
      if (_period == categories[i].period) assert(false);       // can't add package that has the same period as the existing package
    }

    Package memory package = Package({
      name: _name,
      period: _period,
      withdrawTime: _withdrawTime,
      tokenRewardPercent: _tokenRewardPercent,
      tokenPenaltyPercent: _tokenPenaltyPercent,
      limit: _limit
    });

    categories.push(package);
    
    emit PackageAdded(
      categories.length - 1,
      _name,
      _period,
      _withdrawTime,
      _tokenRewardPercent,
      _tokenPenaltyPercent,
      _limit
    );

    return true;
  }

  // function to set package parameters
  function setPackage(
    uint256 packageId,                      // package id to set
    string memory _name,
    uint256 _period, 
    uint256 _withdrawTime, 
    uint256 _tokenRewardPercent, 
    uint256 _tokenPenaltyPercent, 
    uint256 _limit
  ) external onlyOwner returns (bool) {
    // simple validation check
    assert(_period > 1);
    assert(_withdrawTime > 1 days && _withdrawTime <= _period * 1 days);
    assert(_tokenRewardPercent != 0);
    assert(_tokenPenaltyPercent <= _tokenRewardPercent);
    assert(_limit >= 0);

    // confirm
    for (uint i = 0; i < categories.length; i++) {
      if (packageId == i) continue;
      if (_period == categories[i].period) assert(false);       // can't add package that has the same period as the existing package
    }

    categories[packageId] = Package({
      name: _name,
      period: _period,
      withdrawTime: _withdrawTime,
      tokenRewardPercent: _tokenRewardPercent,
      tokenPenaltyPercent: _tokenPenaltyPercent,
      limit: _limit
    });

    emit PackageUpdated(
      packageId,
      _name,
      _period,
      _withdrawTime,
      _tokenRewardPercent,
      _tokenPenaltyPercent,
      _limit
    );

    return true;
  }
  
  // function to add token reward in contract
  function addTokenReward(uint256 token) external onlyOwner returns(bool){
    ghost.transferFrom(msg.sender, address(this), token);
    _ownerTokenAllowance = _ownerTokenAllowance.add(token);
    return true;
  }
  
  // function to withdraw added token reward in contract
  function withdrawAddedTokenReward(uint256 token) external onlyOwner returns(bool){
    require(token < _ownerTokenAllowance,"Value is not feasible, Please Try Again!!!");
    ghost.transferFrom(address(this), msg.sender, token);
    _ownerTokenAllowance = _ownerTokenAllowance.sub(token);
    return true;
  }
  
  // function to get token reward in contract
  function getTokenReward() external view returns(uint256){
    return _ownerTokenAllowance;
  }

  // function to get distributed reward amount of the system
  function getDistributedRewardAmount() external view returns (uint256) {
    return _distributedRewardAmount;
  }
  
  // function to pause Token Staking
  function pauseTokenStaking() external onlyOwner {
    tokenPaused = true;
    emit Paused();
  }

  // function to unpause Token Staking
  function unpauseTokenStaking() external onlyOwner {
    tokenPaused = false;
    emit Unpaused();
  }
  
  /*
  * ----------------------------------------------------------------------------------------------------------------------------
  * Variable, Mapping for Token Staking Functionality
  * ----------------------------------------------------------------------------------------------------------------------------
  */
  
  // mapping for users with id => address Staking Address
  mapping (uint256 => address) private _tokenStakingAddress;
  
  // mapping for users with address => id staking id
  mapping (address => uint256[]) private _tokenStakingId;

  // mapping for users with id => Staking Time
  mapping (uint256 => uint256) private _tokenStakingStartTime;
  
  // mapping for users with id => End Time
  mapping (uint256 => uint256) private _tokenStakingEndTime;

  // mapping for users with id => Tokens 
  mapping (uint256 => uint256) private _usersTokens;
  
  // mapping for users with id => Status
  mapping (uint256 => bool) private _TokenTransactionStatus;    
  
  // mapping to keep track of final withdraw value of staked token
  mapping(uint256=>uint256) private _finalTokenStakeWithdraw;
  
  // mapping to keep track total number of staking days
  mapping(uint256=>uint256) private _tokenTotalDays;
  
  // variable to keep count of Token Staking
  uint256 private _tokenStakingCount = 0;
  
  // variable to keep track on reward added by owner
  uint256 private _ownerTokenAllowance = 0;

  // variable to keep track on paid out reward of the system
  uint256 private _distributedRewardAmount = 0;

  // variable for token time management
  uint256 private _tokentime;
  
  // variable for token staking pause and unpause mechanism
  bool public tokenPaused = false;
  
  // variable for total Token staked by user
  uint256 public totalStakedToken = 0;
  
  // variable for total stake token in contract
  uint256 public totalTokenStakesInContract = 0;

  // variable for total stake tokens for package in contract
  mapping (uint256 => uint256) public totalStakedInPackage;
  
  // modifier to check the user for staking || Re-enterance Guard
  modifier tokenStakeCheck(uint256 tokens, uint256 timePeriod){
    require(tokens > 0, "Invalid Token Amount, Please Try Again!!! ");
    bool validTime = false;
    for (uint i = 0; i < categories.length; i++) {
      if (timePeriod == categories[i].period) {
        require(totalStakedInPackage[timePeriod].add(tokens) <= categories[i].limit, "Selected Package was already filled. Try another package.");
        validTime = true;
      }
    }
    require(validTime == true, "Enter the Valid Time Period and Try Again !!!");
    _;
  }
    
  /*
  * ------------------------------------------------------------------------------------------------------------------------------
  * Functions for Token Staking Functionality
  * ------------------------------------------------------------------------------------------------------------------------------
  */

  // function to performs staking for user tokens for a specific period of time
  function stakeToken(uint256 tokens, uint256 time) external tokenStakeCheck(tokens, time) returns(bool){
    require(tokenPaused == false, "Staking is Paused, Please try after staking get unpaused!!!");
    
    _tokentime = block.timestamp + (time * 1 days);
    _tokenStakingCount = _tokenStakingCount + 1;
    _tokenTotalDays[_tokenStakingCount] = time;
    _tokenStakingAddress[_tokenStakingCount] = msg.sender;
    _tokenStakingId[msg.sender].push(_tokenStakingCount);
    _tokenStakingEndTime[_tokenStakingCount] = _tokentime;
    _tokenStakingStartTime[_tokenStakingCount] = block.timestamp;
    _usersTokens[_tokenStakingCount] = tokens;
    _TokenTransactionStatus[_tokenStakingCount] = false;
    totalStakedToken = totalStakedToken.add(tokens);
    totalTokenStakesInContract = totalTokenStakesInContract.add(tokens);
    totalStakedInPackage[time] = totalStakedInPackage[time].add(tokens);
    ghost.transferFrom(msg.sender, address(this), tokens);

    emit Deposit(msg.sender, tokens, time, _tokenStakingCount, block.timestamp);

    return true;
  }

  // function to get staking count for token
  function getTokenStakingCount() external view returns(uint256){
    return _tokenStakingCount;
  }
  
  // function to get total Staked tokens
  function getTotalStakedToken() external view returns(uint256){
    return totalStakedToken;
  }
  
  // function to calculate reward for the message sender for token
  function getTokenRewardDetailsByStakingId(uint256 id) public view returns(uint256){
    for (uint i = 0; i < categories.length; i++) {
      if (_tokenTotalDays[id] == categories[i].period) {
        return (_usersTokens[id] * categories[i].tokenRewardPercent/BASIS_POINT);
      }
    }

    return 0;
  }

  // function to calculate penalty for the message sender for token
  function getTokenPenaltyDetailByStakingId(uint256 id) public view returns(uint256){
    if(_tokenStakingEndTime[id] > block.timestamp){
        for (uint i = 0; i < categories.length; i++) {
          if (_tokenTotalDays[id] == categories[i].period) {
            return (_usersTokens[id] * categories[i].tokenPenaltyPercent/BASIS_POINT);
          }
        }
        return 0;
    } else{
       return 0;
     }
  }
 
  // function for withdrawing staked tokens
  function withdrawStakedTokens(uint256 stakingId) external returns(bool) {
    require(_tokenStakingAddress[stakingId] == msg.sender,"No staked token found on this address and ID");
    require(_TokenTransactionStatus[stakingId] != true,"Either tokens are already withdrawn or blocked by admin");
    
    for (uint i = 0; i < categories.length; i++) {
      if (_tokenTotalDays[stakingId] == categories[i].period) {
        require(block.timestamp >= _tokenStakingStartTime[stakingId] + categories[i].withdrawTime, "Unable to Withdraw Staked token before withdraw time of staking start time, Please Try Again Later!!!");
        _TokenTransactionStatus[stakingId] = true;
        
        if(block.timestamp >= _tokenStakingEndTime[stakingId]) {
          _finalTokenStakeWithdraw[stakingId] = _usersTokens[stakingId].add(getTokenRewardDetailsByStakingId(stakingId));
          _distributedRewardAmount += getTokenRewardDetailsByStakingId(stakingId);
        } else {
          _finalTokenStakeWithdraw[stakingId] = _usersTokens[stakingId].add(getTokenPenaltyDetailByStakingId(stakingId));
          _distributedRewardAmount += getTokenPenaltyDetailByStakingId(stakingId);
        }
        ghost.transferFrom(address(this), msg.sender,_finalTokenStakeWithdraw[stakingId]);
        totalTokenStakesInContract = totalTokenStakesInContract.sub(_usersTokens[stakingId]);
        totalStakedInPackage[categories[i].period] = totalStakedInPackage[categories[i].period].sub(_usersTokens[stakingId]);

        emit Withdraw(msg.sender, stakingId, _usersTokens[stakingId], _finalTokenStakeWithdraw[stakingId].sub(_usersTokens[stakingId]), block.timestamp);

        return true;
      }
    }

    return false;
  }
  
  // function to get Final Withdraw Staked value for token
  function getFinalTokenStakeWithdraw(uint256 id) external view returns(uint256){
    return _finalTokenStakeWithdraw[id];
  }
  
  // function to get total token stake in contract
  function getTotalTokenStakesInContract() external view returns(uint256){
      return totalTokenStakesInContract;
  }
  
  /*
  * -------------------------------------------------------------------------------------------------------------------------------
  * Get Functions for Stake Token Functionality
  * -------------------------------------------------------------------------------------------------------------------------------
  */

  // function to get Token Staking address by id
  function getTokenStakingAddressById(uint256 id) external view returns (address){
    require(id <= _tokenStakingCount,"Unable to reterive data on specified id, Please try again!!");
    return _tokenStakingAddress[id];
  }
  
  // function to get Token staking id by address
  function getTokenStakingIdByAddress(address add) external view returns(uint256[] memory){
    require(add != address(0),"Invalid Address, Pleae Try Again!!!");
    return _tokenStakingId[add];
  }
  
  // function to get Token Staking Starting time by id
  function getTokenStakingStartTimeById(uint256 id) external view returns(uint256){
    require(id <= _tokenStakingCount,"Unable to reterive data on specified id, Please try again!!");
    return _tokenStakingStartTime[id];
  }
  
  // function to get Token Staking Ending time by id
  function getTokenStakingEndTimeById(uint256 id) external view returns(uint256){
    require(id <= _tokenStakingCount,"Unable to reterive data on specified id, Please try again!!");
    return _tokenStakingEndTime[id];
  }
  
  // function to get Token Staking Total Days by Id
  function getTokenStakingTotalDaysById(uint256 id) external view returns(uint256){
    require(id <= _tokenStakingCount,"Unable to reterive data on specified id, Please try again!!");
    return _tokenTotalDays[id];
  }

  // function to get Staking tokens by id
  function getStakingTokenById(uint256 id) external view returns(uint256){
    require(id <= _tokenStakingCount,"Unable to reterive data on specified id, Please try again!!");
    return _usersTokens[id];
  }

  // function to get Token lockstatus by id
  function getTokenLockStatus(uint256 id) external view returns(bool){
    require(id <= _tokenStakingCount,"Unable to reterive data on specified id, Please try again!!");
    return _TokenTransactionStatus[id];
  }

  // function to get staked amount, earned amount and reward amount of user based on address
  function getUserInfoByAddress(address addr) external view returns (uint256 staked, uint256 earned, uint256 reward) {
    require(addr != address(0), "Invalid Address, Pleae Try Again!!!");
    uint256[] memory tokenStakingIds = _tokenStakingId[addr];

    for (uint i = 0; i < tokenStakingIds.length; i++) {
      uint256 stakingId = tokenStakingIds[i];
      if (_finalTokenStakeWithdraw[stakingId] == 0) {
        staked += _usersTokens[stakingId];
        for (uint j = 0; j < categories.length; j++) {
          if (_tokenTotalDays[stakingId] == categories[j].period) {
            if(block.timestamp >= _tokenStakingEndTime[stakingId]) {
              reward += getTokenRewardDetailsByStakingId(stakingId);
            } else {
              reward += getTokenPenaltyDetailByStakingId(stakingId);
            }
            break;
          }
        }
      }
      
      earned += _finalTokenStakeWithdraw[tokenStakingIds[i]];
    }
  }

  // function to get category list
  function getCategories() external view returns (Package[] memory) {
    return categories;
  }

  struct UserActivePackage {
    string name;
    uint256 period;
    uint256 amount;
  }

  // Get the user's staked balance per package
  function getActivePackagesByAddress(address addr) external view returns (UserActivePackage[] memory) {
    require(addr != address(0), "Invalid Address, Pleae Try Again!!!");
    uint256 length = categories.length;
    UserActivePackage[] memory packages = new UserActivePackage[](length);
    uint256[] memory tokenStakingIds = _tokenStakingId[addr];

    for (uint i = 0; i < categories.length; i++) {
      packages[i].name = categories[i].name;
      packages[i].period = categories[i].period;
      packages[i].amount = 0;
      
      for (uint j = 0; j < tokenStakingIds.length; j++) {
        uint256 stakingId = tokenStakingIds[j];
        if (_finalTokenStakeWithdraw[stakingId] == 0 && _tokenTotalDays[stakingId] == categories[i].period) {
          packages[i].amount += _usersTokens[stakingId];
        }
      }
    }

    return packages;
  }
  
}