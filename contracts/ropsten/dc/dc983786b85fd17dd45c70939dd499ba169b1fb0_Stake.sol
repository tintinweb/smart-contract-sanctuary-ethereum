/**
 *Submitted for verification at Etherscan.io on 2022-03-17
*/

// File: @openzeppelin/contracts/utils/Context.sol

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

// File: @openzeppelin/contracts/access/Ownable.sol

// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// File: contracts/Stake.sol

pragma solidity ^0.8.0;

contract Stake is Ownable {
	struct sStake {
    uint256 total_rewards_unclaimed;
    uint256 total_rewards_claimed;
    uint256 total_staked;
    uint256 rewards_claimed_at;
    uint256 stake_started_at;
	}

  // Stakes
  mapping(address => sStake) public stakes;

  // Refers
  mapping(address => address) public refers;

  // total staked
  uint256 public totalStaked = 0;

  // minimum value to stake
  uint256 public minValueToStake = 0.01 ether;

  // maximum value to stake
  uint256 public maxValueToStake = 1 ether;

  // Yield multiply by 10000
  uint256 public yield = 110;

  // Maximum Claim Rewards
  uint256 public maximumClaimRewardsPorcentage = 3;

  // Refer Porcentage
  uint256 public referPorcentage = 10;

  function setMinValueToStake(uint256 _value) public onlyOwner {
    minValueToStake = _value;
  }

  function setMaxValueToStake(uint256 _value) public onlyOwner {
    maxValueToStake = _value;
  }

  function setYield(uint256 _value) public onlyOwner {
    yield = _value;
  }

  function setMaximumClaimRewardsPorcentage(uint256 _value) public onlyOwner {
    maximumClaimRewardsPorcentage = _value;
  }

  function setReferPorcentage(uint256 _value) public onlyOwner {
    referPorcentage = _value;
  }

  function stake(address _address, address _refer) public payable {
    require(minValueToStake <= msg.value, "Value not enoght!");
    require(maxValueToStake >= (msg.value + stakes[_address].total_staked), "Maximum of stake exceeded!");
    require(_address != _refer, "Address and Refer can not be equal!");

    _stake(_address, msg.value);

    // Set refer address
    if(refers[_address] == address(0x0)){
      refers[_address] = _refer;
    }else{
      _refer = refers[_address];
    }

    // Indication to refer
    if(referPorcentage > 0 && stakes[_refer].total_staked > 0){
      _stake(_refer, msg.value / referPorcentage);
    }
  }

  function _stake(address _address, uint256 _value) internal {
    // Update the actual rewards unclaimed
    if(stakes[_address].total_staked > 0){
      updateAndGetTotalRewardsUnclaimed(_address);
    }

    totalStaked += _value;
    stakes[_address].total_staked += _value;
    stakes[_address].stake_started_at = block.timestamp;

    emit StartStake(_address, msg.value);
  }

  function claimRewards(address payable _address) public payable{
    // Get rewards unclaimed
    uint256 _total_rewards_unclaimed = updateAndGetTotalRewardsUnclaimed(_address);

    require(address(this).balance > _total_rewards_unclaimed, "Balance of contract not enoght!");

    if(_total_rewards_unclaimed > 0){
      //Update total rewards unclaimed
      stakes[_address].total_rewards_unclaimed = 0;

      // Update total rewards claimed
      stakes[_address].total_rewards_claimed += _total_rewards_unclaimed;

      // If Stake is Over
      if(stakes[_address].total_rewards_claimed >= getMaximumClaimRewardsTotal(_address)){
        uint256 _total_rewards_claimed = stakes[_address].total_rewards_claimed;

        // Remove of total staked
        totalStaked -= stakes[_address].total_staked;

        // Reset All Stake Data
        stakes[_address].total_rewards_claimed = 0;
        stakes[_address].total_staked = 0;
        stakes[_address].rewards_claimed_at = 0;
        stakes[_address].stake_started_at = 0;

        emit StopStake(_address, _total_rewards_claimed);
      }

      _address.transfer(_total_rewards_unclaimed);
      emit ClaimRewards(_address, _total_rewards_unclaimed);
    }
  }

  function updateAndGetTotalRewardsUnclaimed(address _address) public returns(uint256){
    //Update total rewards unclaimed
    stakes[_address].total_rewards_unclaimed = getTotalRewardsUnclaimed(_address);

    //Update reward claimed at
    stakes[_address].rewards_claimed_at = block.timestamp;

    //Return total rewards unclaimed
    return stakes[_address].total_rewards_unclaimed;
  }

  function getTotalRewardsUnclaimed(address _address) public view returns(uint256){
    // Set total rewards unclaimed
    uint256 totalRewardsUnclaimed = stakes[_address].total_rewards_unclaimed + calculeStakeBalance(_address);

    // Set the maximum Claim Rewards Total
    uint256 maximumClaimRewardsTotal = getMaximumClaimRewardsTotal(_address);

    // Check the maximum of Rewards
    if((totalRewardsUnclaimed + stakes[_address].total_rewards_claimed) > maximumClaimRewardsTotal) {
      totalRewardsUnclaimed -= (totalRewardsUnclaimed + stakes[_address].total_rewards_claimed) - maximumClaimRewardsTotal;
    }

    // Filter to 0
    if(totalRewardsUnclaimed < 0){
      totalRewardsUnclaimed = 0;
    }

    return totalRewardsUnclaimed;
  }

  function getMaximumClaimRewardsTotal(address _address) public view returns(uint256){
    uint256 maximumClaimRewardsTotal;

    // Set the maximum Claim Rewards Total
    maximumClaimRewardsTotal = (maximumClaimRewardsPorcentage*stakes[_address].total_staked);

    return maximumClaimRewardsTotal;
  }

  function calculeStakeBalance(address _address) public view returns(uint256){
    uint256 totalReward;
    uint256 timeStakingBySeconds;
    uint256 actualTime;

    actualTime = block.timestamp;
    timeStakingBySeconds = 0;

    // Calculate total brains staked
    if(stakes[_address].rewards_claimed_at > 0){
      timeStakingBySeconds = actualTime - stakes[_address].rewards_claimed_at;
    }else{
      timeStakingBySeconds = actualTime - stakes[_address].stake_started_at;
    }

    totalReward = (yield * stakes[_address].total_staked * timeStakingBySeconds) / 864000000;

    // Filter to 0
    if(totalReward < 0){
      totalReward = 0;
    }

    return totalReward;
  }

  function withdraw(uint256 amount) public onlyOwner {
    require(amount <= address(this).balance, "Amount should be equal or lower of balance.");
    payable(msg.sender).transfer(amount);
  }
  /*
   * Event
   */

  event StartStake(address _address, uint256 value);
  event StopStake(address _address, uint256 value);
  event ClaimRewards(address _address, uint256 value);
}