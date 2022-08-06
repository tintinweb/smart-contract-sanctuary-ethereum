/**
 *Submitted for verification at Etherscan.io on 2022-08-05
*/

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// File: Staking.sol


pragma solidity ^0.8.4;



abstract contract MartianClub {
    uint256 public   maxPerAddressDuringMint;
    mapping(address => uint256) public allowlist;
    function numberMinted(address owner) public view virtual returns (uint256);
    function seedAllowlist(address[] memory addresses, uint256[] memory numSlots) virtual external;
    function transfer(address recipient, uint256 amount) public virtual returns (bool);

}

contract StakeForMCSlot is Ownable {


    
    constructor() {
        stakeholders.push();
        stakeconfigs.push();
    }
    
    struct Stake{
        address user;
        address tokenAddress;
        uint256 amount;
        uint256 since;
        uint256 unstakeTime;
        uint256 reward;
        uint256 grantedSlots;
    }
   
    struct Stakeholder{
        address user;
        Stake[] address_stakes;
        
    }
    
     struct StakingSummary{
         uint256 total_amount;
         uint256 total_reward;
         uint256 total_grantedSlot;
         Stake[] stakes;
     }


    struct StakeConfig{
        uint256 startTime;
        uint256 endTime;
        uint256 unstakeTime;
        uint256 slotPrice;
        uint256 increment;
        uint256 totalSlot;
        address tokenAddress;
        address nftAddress;
        uint256 rewardPerMillion;
        uint256 totalStaked;
        uint256 totalReward;
        uint256 usedSlot;
    }

    
    
    


   
    Stakeholder[] internal stakeholders;

    StakeConfig[] public stakeconfigs;

    /**
    * @notice 
    * stakes is used to keep track of the INDEX for the stakers in the stakes array
     */
    mapping(address => uint256) internal stakes;
    /**
    * @notice Staked event is triggered whenever a user stakes tokens, address is indexed to make it filterable
     */
    event Staked(address indexed user, uint256 amount, uint256 index, uint256 timestamp);
    event Unstaked(address indexed user, uint256 amount,uint256 reward, uint256 index, uint256 timestamp);



    





    /**
    * @notice _addStakeholder takes care of adding a stakeholder to the stakeholders array
     */
    function _addStakeholder(address staker) internal returns (uint256){
        // Push a empty item to the Array to make space for our new stakeholder
        stakeholders.push();
        // Calculate the index of the last item in the array by Len-1
        uint256 userIndex = stakeholders.length - 1;
        // Assign the address to the new index
        stakeholders[userIndex].user = staker;
        // Add index to the stakeHolders
        stakes[staker] = userIndex;
        return userIndex; 
    }

    /**
    * @notice
    * _Stake is used to make a stake for an sender. It will remove the amount staked from the stakers account and place those tokens inside a stake container
    * StakeID 
    */
    // function _stake(uint256 _amount) internal{
       
        

    //     // Mappings in solidity creates all values, but empty, so we can just check the address
    //     uint256 index = stakes[msg.sender];
    //     // block.timestamp = timestamp of the current block in seconds since the epoch
    //     uint256 timestamp = block.timestamp;
    //     // See if the staker already has a staked index or if its the first time
    //     if(index == 0){
    //         // This stakeholder stakes for the first time
    //         // We need to add him to the stakeHolders and also map it into the Index of the stakes
    //         // The index returned will be the index of the stakeholder in the stakeholders array
    //         index = _addStakeholder(msg.sender);
    //     }
    //     require(stakeconfigs.length>0,"No valid stake config");
    //     StakeConfig memory currentConfig=stakeconfigs[stakeconfigs.length-1];
    //     require(timestamp>=currentConfig.startTime && timestamp<=currentConfig.endTime,"Current stake period is closed");
    //     // Use the index to push a new Stake
    //     // push a newly created Stake with the current block timestamp.
    //     // May have overflow problem?
    //     stakeholders[index].address_stakes.push(Stake(msg.sender, currentConfig.tokenAddress,_amount, timestamp,currentConfig.timePeriod, _amount*currentConfig.rewardPerMillion/1000000));
    //     // Emit an event that the stake has occured
    //     stakeconfigs[stakeconfigs.length-1].totalStaked+=_amount;
    //     stakeconfigs[stakeconfigs.length-1].totalReward+=_amount*currentConfig.rewardPerMillion/1000000;
    //     emit Staked(msg.sender, _amount, index,timestamp);
    // }
   
    /**
     * @notice
     * withdrawStake takes in an amount and a index of the stake and will remove tokens from that stake
     * Notice index of the stake is the users stake counter, starting at 0 for the first stake
     * Will return the amount to MINT onto the acount
     * Will also calculateStakeReward and reset timer
    */
     function _withdrawStake() internal returns(uint256){
         // Grab user_index which is the index to use to grab the Stake[]
        uint256 user_index = stakes[msg.sender];
        Stake[] memory current_stakes = stakeholders[user_index].address_stakes;
        uint256 total;
        uint256 mintTotal;
        for (uint256 s=0;s<current_stakes.length;s+=1){
            total=current_stakes[s].reward+current_stakes[s].amount;
            mintTotal+=total;
            require(current_stakes[s].unstakeTime <= block.timestamp, "Staking: Cannot withdraw before staking ends");
            stakeconfigs[stakeconfigs.length-1].totalStaked-=current_stakes[s].amount;
            stakeconfigs[stakeconfigs.length-1].totalReward-=current_stakes[s].reward;
            delete stakeholders[user_index].address_stakes[s];
            emit Unstaked(msg.sender,current_stakes[s].amount,current_stakes[s].reward,s,block.timestamp);       

        }
        
        return mintTotal;
     }

     /**
     * @notice
     * hasStake is used to check if a account has stakes and the total amount along with all the seperate stakes
     */
    function hasStake(address _staker) public view returns(StakingSummary memory){
        // totalStakeAmount is used to count total staked amount of the address
        uint256 totalStakeAmount; 
        uint256 totalStakeReward;
        uint256 totalGrantedSlots;
        // Keep a summary in memory since we need to calculate this
        StakingSummary memory summary = StakingSummary(0,0,0, stakeholders[stakes[_staker]].address_stakes);
        // Itterate all stakes and grab amount of stakes
        for (uint256 s = 0; s < summary.stakes.length; s += 1){
           totalStakeAmount = totalStakeAmount+summary.stakes[s].amount;
           totalStakeReward=totalStakeReward+summary.stakes[s].reward;
           totalGrantedSlots=totalGrantedSlots+summary.stakes[s].grantedSlots;
       }
       // Assign calculate amount to summary
       summary.total_amount = totalStakeAmount;
       summary.total_reward=totalStakeReward;
       summary.total_grantedSlot=totalGrantedSlots;
        return summary;
    }

    /**
    * Add functionality to the _stake afunction
    *
     */
    function stakeForSlot(uint256 quantity) public  {
        require(stakeconfigs.length>0,"No valid stake config");
        StakeConfig memory currentConfig=stakeconfigs[stakeconfigs.length-1];
        uint256 timestamp = block.timestamp;
        require(timestamp>=currentConfig.startTime && timestamp<=currentConfig.endTime,"Current stake period is closed");

        require(currentConfig.usedSlot+quantity<=currentConfig.totalSlot,"Insufficent remaining slot");
        uint256 _amount=currentConfig.slotPrice*quantity+ currentConfig.increment*quantity*(quantity-1)/2;
        // Check payment approval and buyer balance
        IERC20 tokenContract = IERC20(currentConfig.tokenAddress);
        require(
            tokenContract.balanceOf(msg.sender) >= _amount,
            "Insufficient token balance"
        );
        require(
            tokenContract.allowance(msg.sender,address(this)) >= _amount,
            "Insufficient approved balance"
        );
         // Mappings in solidity creates all values, but empty, so we can just check the address
        uint256 index = stakes[msg.sender];
        // See if the staker already has a staked index or if its the first time
        if(index == 0){
            // This stakeholder stakes for the first time
            // We need to add him to the stakeHolders and also map it into the Index of the stakes
            // The index returned will be the index of the stakeholder in the stakeholders array
            index = _addStakeholder(msg.sender);
        }

        uint256 grantedSlots;
        // Itterate all stakes and grab amount of granted slots
        for (uint256 s = 0; s < stakeholders[index].address_stakes.length; s += 1){
           
           grantedSlots=grantedSlots+stakeholders[index].address_stakes[s].grantedSlots;
       }
        MartianClub mcContract=MartianClub(currentConfig.nftAddress);
        require(grantedSlots+quantity<=mcContract.maxPerAddressDuringMint(),"Cannot get too many slots");
        // Use the index to push a new Stake
        // push a newly created Stake with the current block timestamp.
        // May have overflow problem?
        stakeholders[index].address_stakes.push(Stake(msg.sender, currentConfig.tokenAddress,_amount, timestamp,currentConfig.unstakeTime, _amount*currentConfig.rewardPerMillion/1000000,quantity));
        // Emit an event that the stake has occured
        stakeconfigs[stakeconfigs.length-1].totalStaked+=_amount;
        stakeconfigs[stakeconfigs.length-1].totalReward+=_amount*currentConfig.rewardPerMillion/1000000;

        stakeconfigs[stakeconfigs.length-1].usedSlot+=quantity;
        stakeconfigs[stakeconfigs.length-1].slotPrice+=stakeconfigs[stakeconfigs.length-1].increment;
        emit Staked(msg.sender, _amount, index,timestamp);        

        address[] memory addresses= new address[](1);
        uint256[] memory numslots=new uint256[](1);
        addresses[0]=msg.sender;
        numslots[0]=quantity;
       
        mcContract.seedAllowlist(addresses,numslots);
        tokenContract.transferFrom(msg.sender,address(this),_amount);
        


               
    }

    // function currentStakeConfig() public view returns(StakeConfig memory currentStakeConfig) {
    //     require(stakeconfigs.length>0,"No valid stake config");
    //     return stakeconfigs[stakeconfigs.length-1];
    // }

    // /**
    // * @notice withdrawStake is used to withdraw stakes from the account holder
    //  */
    function withdrawStake()  public {

        uint256 amount_to_mint = _withdrawStake();
        require(stakeconfigs.length>0,"No valid stake config");
        StakeConfig memory currentConfig=stakeconfigs[stakeconfigs.length-1];
        IERC20 tokenContract = IERC20(currentConfig.tokenAddress);
        require(tokenContract.transfer(msg.sender,amount_to_mint),"Unstake failed");
     
    }

    function startNewStakeSession(
        uint256 startTime,
        uint256 endTime,
        uint256 unstakeTime,
        uint256 slotPrice,
        uint256 increment,
        uint256 remainSlot,
        address tokenAddress,
        address nftAddress,
        uint256 rewardPerMillion) external onlyOwner {
        stakeconfigs.push(StakeConfig(
          startTime,
          endTime,
          unstakeTime,
          slotPrice,
          increment,
          remainSlot,
          tokenAddress,
          nftAddress,
          rewardPerMillion,
          0,
          0,
          0
      ));

      

  }

  function getCurrentSessionIndex() public view returns(uint256 index){
        require(stakeconfigs.length>0,"No valid stake config");
        return stakeconfigs.length-1;
  }

  function getCurrentStakeConfig() public view returns (StakeConfig memory config){
        require(stakeconfigs.length>0,"No valid stake config");
        return stakeconfigs[stakeconfigs.length-1];

  }

}