/**
 *Submitted for verification at Etherscan.io on 2022-07-15
*/

//SPDX-License-Identifier:MIT
pragma solidity ^0.8.4;
/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned)
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



// OpenZeppelin Contracts v4.3.2 (access/Ownable.sol)

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



pragma solidity ^0.8.4;
/**
 * @dev Interface of the BEP20 standard as defined in the EIP.
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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}


pragma solidity ^0.8.4;

contract IkonicStaking is Ownable {

    IERC20 public stakeToken;
    bool public isAbleToStake;
    uint256 public totalRewardsGiven;
    uint256 public totalRewardFunds;
    uint256 public totalStaking;
    uint public IkonStakersRecord;
    // Max Stakers Limt in third pool 
    uint public maxIkonStakes=2;          
    //Stake pool size for three pools 
    uint[] public poolSize=[0,10000 ether,100000 ether, 1000000 ether];
    // Pool Types 1=>MYTH ,2=>LEGEND ,3=> IKONIC
    uint[] public poolTypes=[0,1,2,3];    
    //APR % For Pools 1=>MYTH ,2=>LEGEND ,3=> IKONIC                          
    uint[] public APR=[0,10,15,20];  
    //Locking period pool                                
    uint[] public lockTime=[0, 30 days,90 days , 180 days] ;                      
  
    mapping (address => uint) public stakeTime;
    mapping(address => uint256) public StakesPerUser;
    mapping(address=>mapping(uint=>mapping(uint=>bool))) public isGetReward ;
    mapping(address => bool) public isBlocked;
    mapping (address => stakerDetails[]) public Stakers;
    mapping(address=>mapping(uint=>mapping(uint=>uint))) public lastUpdatedTime; 

    event Staked(address indexed user,address _thisaddress, uint256 amount,uint256 poolType,uint256 id);
    event Unstaked(address indexed user, uint256 amount);
    event rewards(address _user, uint _amount);
    event RecoverToken(address indexed token, uint256 indexed amount);
   // Staker Details 
    struct stakerDetails {
        uint id;
        uint stakeTime;
        uint stakeAmount;
        uint poolType;
    }

   // Set Reward Token Address
    function setTokenAddress(address _addr) public onlyOwner {
        stakeToken = IERC20(_addr);
    }

    // set Reward APR for Pools

    function setApr(uint[] memory _APR) public onlyOwner {
        APR=_APR;
    }
    
    // set Stake Amount for Pools

     function setPools(uint[] memory _poolValue) public onlyOwner {
        poolSize = _poolValue;
    }

    // set Locking Period for Pools  NOTE : Provide time in seconds 1 Month = 2592000 Sec
    function setLockPeriod(uint[] memory _locktime) public onlyOwner{
        lockTime=_locktime;
    }
   // Set max Stakers in IKONIC pool
    function setMaxIkonStakers(uint _stakes) external onlyOwner{
        maxIkonStakes=_stakes;
    }
  // Deposit Reward Tokens to Contract
    function depositRewards(uint amount) public onlyOwner {
            stakeToken.transferFrom(msg.sender, address(this), amount);
            totalRewardFunds += amount;
        }
  
    // Calculate Reward Tokens for Pools
    function getReward(address account,uint id) public view returns (uint256) {
         uint256 amount;
         uint totalDays;
         uint finalAmount;
        if(Stakers[account][id].poolType ==poolTypes[Stakers[account][id].poolType]){
             uint depositedAmount = Stakers[account][id].stakeAmount;
             amount = ((depositedAmount* APR[Stakers[account][id].poolType])/100)/365;
             
           if(!isGetReward[account][id][Stakers[account][id].poolType]){
             totalDays = (block.timestamp - Stakers[account][id].stakeTime)/ 1 days ;
           }else{
             totalDays=(block.timestamp - lastUpdatedTime[account][id][Stakers[account][id].poolType])/ 1 days;
           }
           
            finalAmount =amount * totalDays;
             if(Stakers[account][id].stakeTime==0){
                finalAmount=0;
            } 
        }
         return finalAmount;
    }
  

  // Function to Pause Staking 
    function pauseStake(bool _stake) external onlyOwner{
        isAbleToStake=_stake;
    }
  // User Staking function
    function stake(uint256 poolType) public {
        require(!isAbleToStake,"Temperory Staking Paused");
        if(poolType==poolTypes[poolType]){
            if(poolType==3){
               require(IkonStakersRecord<maxIkonStakes,"No More Ikon Stake");
               IkonStakersRecord+=1; 
            }
             stakerDetails memory staker;
             staker.stakeTime = block.timestamp;
             staker.stakeAmount = poolSize[poolType];
             staker.poolType =poolType; 
             totalStaking+=poolSize[poolType];
             StakesPerUser[msg.sender] += 1;
             staker.id = StakesPerUser[msg.sender];
             Stakers[msg.sender].push(staker);
             stakeToken.transferFrom(msg.sender, address(this),poolSize[poolType]);
             emit Staked(address(this),msg.sender,staker.stakeAmount,poolType,staker.id);
        }else{
            require(poolTypes[poolType]<=3," wrongPool");
        }
    }

    //Reward Claim Function 
       function withdrawRewards (uint id) public { 
          require(!isBlocked[msg.sender],"User Blocked");
           uint totalRewards = getReward(msg.sender,id);
           require(totalRewards>0,"Zero Rewards");
            isGetReward[msg.sender][id][Stakers[msg.sender][id].poolType]=true;
            totalRewardsGiven+=totalRewards;
            if(Stakers[msg.sender][id].poolType==poolTypes[Stakers[msg.sender][id].poolType]){
                lastUpdatedTime[msg.sender][id][poolTypes[Stakers[msg.sender][id].poolType]]=block.timestamp;
            stakeToken.transfer (msg.sender, totalRewards);
            emit rewards(msg.sender,totalRewards);}
        }

     // Unstake Funtion
    function unstake(uint id) public {
        require(block.timestamp>=Stakers[msg.sender][id].stakeTime+lockTime[Stakers[msg.sender][id].poolType],"lockTime !Completed");
        require(!isBlocked[msg.sender],"User Blocked");
         uint _amount = (Stakers[msg.sender][id].stakeAmount) ;
             withdrawRewards(id);
             totalStaking-=_amount;
            stakeToken.transfer (msg.sender, _amount);
            delete Stakers[msg.sender][id];
            emit Unstaked(msg.sender, _amount);
    }

   // Recover  Excess reward Tokens from contract
    function recoverExcessToken(address _tokenAddress, uint256 amount) external onlyOwner {
        IERC20(_tokenAddress).transfer(msg.sender, amount);
        emit RecoverToken(_tokenAddress, amount);
    }
  // Read Stake Token Balance
    function getContractTokenBalance() public view returns(uint256) {
        return stakeToken.balanceOf(address(this));
    }
   // Block User 
    function blockUser(address _userAddress) external onlyOwner{
               isBlocked[_userAddress]=true;
    }
    // UnBlock the Blocked user 
    function unBlockUser(address _userAddress) external onlyOwner{
               isBlocked[_userAddress]=false;
    }
   // Remaining RewardTokens 
    function TotalRewards() public view returns(uint256){
        uint256 tRewards = totalRewardFunds - totalRewardsGiven;
        return tRewards;
    }
}