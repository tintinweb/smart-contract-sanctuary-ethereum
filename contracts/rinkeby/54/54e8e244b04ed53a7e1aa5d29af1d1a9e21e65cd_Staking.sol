/**
 *Submitted for verification at Etherscan.io on 2022-06-20
*/

// File: all-code/locknesss/Context.sol


// OpenZeppelin Contracts v4.3.2 (utils/Context.sol)

pragma solidity ^0.8.0;

// import "hardhat/console.sol";
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
// File: all-code/lockness/Ownable.sol


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
// File: all-code/lockness/BEP20.sol


pragma solidity ^0.8.0;
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


pragma solidity ^0.8.0;

contract Staking is Ownable {
//    using SafeMath for uint256;

    IERC20 public stakeToken;
   // IERC20 public rewardToken;

   // uint256 private _totalSupply;
   
    uint256 public totalRewardsGiven;
    uint256 public totalRewardFunds;
    uint256 public totalStaking;
    uint256 public rewardBalance = totalRewardFunds;
    uint256 public Mythpool = 10000*10**18;
    uint256 public Legendpool = 100000*10**18;
    uint256 public Iconpool = 1000000*10**18;
    uint public MythApr = 30;
    uint public LegendApr = 40;
    uint public IconApr = 50;
   
    uint day = 60;
  

    mapping (address => uint) public rewardStored;


    mapping (address => uint) public stakeTime;
    mapping(address => uint256) public StakesPerUser;
     mapping(address=>mapping(uint=>mapping(uint=>bool))) public isGetReward ;
     mapping(address => bool) public isBlocked;

    event RewardAdded(uint256 reward);
    event Staked(address indexed user,address _thisaddress, uint256 amount,uint256 poolType,uint256 id);
    event Unstaked(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event rewards(address _user, uint _amount);
    event RecoverToken(address indexed token, uint256 indexed amount);


    mapping (address => stakerDetails[]) public Stakers;

    struct stakerDetails {
        uint id;
        uint stakeTime;
        uint stakeAmount;
        uint poolType;
        uint lastUpdatedTime1;
        uint lastUpdatedTime2;
        uint lastUpdatedTime3;
    }

   
    function setTokenAddress(address _addr) public onlyOwner {
        stakeToken = IERC20(_addr);
    }

    function setMythApr(uint _APR) public onlyOwner {
        MythApr= _APR;
    }
    function setLegendApr(uint _APR) public onlyOwner {
        LegendApr = _APR;
    }
    function setIconApr(uint _APR) public onlyOwner {
        IconApr =_APR;
    }

     function setMythPool(uint _poolValue) public onlyOwner {
        Mythpool = _poolValue;
    }
    function setLegendPool(uint _poolValue) public onlyOwner {
        Legendpool = _poolValue;
    }
    function setIconPool(uint _poolValue) public onlyOwner {
        Iconpool = _poolValue;
    }

function depositRewards(uint amount) public onlyOwner {
        stakeToken.transferFrom(msg.sender, address(this), amount);
        totalRewardFunds += amount;
        rewardBalance += amount;
    }

    function getReward(address account,uint id,uint poolType) public view returns (uint256) {
         uint256 amount;
         uint totalDays;

         
         
        if(poolType ==1){
             uint depositedAmount = Stakers[account][id].stakeAmount;
             amount = ((depositedAmount* MythApr)/100)/365;
           if(!isGetReward[account][id][poolType]){
             totalDays = (block.timestamp - Stakers[account][id].stakeTime)/ 1 minutes;
           }else{
             totalDays=(block.timestamp - Stakers[account][id].lastUpdatedTime1)/ 1 minutes;
           }
          
            uint finalAmount = rewardStored[account]+amount * totalDays;
             if(Stakers[account][id].stakeTime==0){
                finalAmount=0;
            }
            return finalAmount;
        }

        else if(poolType ==2){
            uint256 depositedAmount = Stakers[account][id].stakeAmount;
            amount = ((depositedAmount* LegendApr)/100)/365;
            if(!isGetReward[account][id][poolType]){
               totalDays = (block.timestamp - Stakers[account][id].stakeTime)/ 1 minutes;
            }else{
               totalDays=(block.timestamp - Stakers[account][id].lastUpdatedTime2)/ 1 minutes;
            }
            uint finalAmount = rewardStored[account]+amount * totalDays;
             if(Stakers[account][id].stakeTime==0){
                finalAmount=0;
            }
            return finalAmount;
        }
        

        else{
            uint depositedAmount = Stakers[account][id].stakeAmount;
            amount = ((depositedAmount* IconApr)/100)/365;
            if(!isGetReward[account][id][poolType]){
             totalDays = (block.timestamp - Stakers[account][id].stakeTime)/ 1 minutes;
            }else{
                totalDays=(block.timestamp - Stakers[account][id].lastUpdatedTime3)/ 1 minutes;
            }
            uint finalAmount = rewardStored[account]+amount * totalDays;
             if(Stakers[account][id].stakeTime==0){
                finalAmount=0;
            }
            return finalAmount;

        }
    }
   

    function stake(uint256 poolType) public {
        if(poolType==1){
             stakerDetails memory staker;
             staker.stakeTime = block.timestamp;
             staker.stakeAmount = Mythpool;
             staker.poolType =1; 
             totalStaking+=Mythpool;
             StakesPerUser[msg.sender] += 1;
             staker.id = StakesPerUser[msg.sender];
             Stakers[msg.sender].push(staker);
             stakeToken.transferFrom(msg.sender, address(this),Mythpool);
             emit Staked(address(this),msg.sender,Mythpool,poolType,staker.id);
        }else if(poolType==2){
             stakerDetails memory staker;
             staker.stakeTime = block.timestamp;
             staker.stakeAmount = Legendpool;
             staker.poolType =2;
             totalStaking+=Legendpool;
             StakesPerUser[msg.sender] += 1;
             staker.id = StakesPerUser[msg.sender];
             Stakers[msg.sender].push(staker);
             stakeToken.transferFrom(msg.sender, address(this),Legendpool);
             emit Staked(address(this),msg.sender,Legendpool,poolType,staker.id);
        }else if(poolType==3){
             stakerDetails memory staker;
             staker.stakeTime = block.timestamp;   
             StakesPerUser[msg.sender] += 1;
             staker.id = StakesPerUser[msg.sender];
             staker.stakeAmount = Iconpool;
             staker.poolType =3;
             totalStaking+=Iconpool;
             Stakers[msg.sender].push(staker);
             stakeToken.transferFrom(msg.sender, address(this),Iconpool);
             emit Staked(address(this),msg.sender,Iconpool,poolType,staker.id);
        }
    }


function withdrawRewards (uint id,uint256 poolType) public { 
          require(!isBlocked[msg.sender],"User Blocked");
           uint totalRewards = getReward(msg.sender,id,poolType);
            isGetReward[msg.sender][id][poolType]=true;
            rewardStored[msg.sender] = 0;
            totalRewardsGiven+=totalRewards;
            if(poolType==1){
            Stakers[msg.sender][id].lastUpdatedTime1 = block.timestamp;}
            else if(poolType==2){
               Stakers[msg.sender][id].lastUpdatedTime2 = block.timestamp; 
            }else{
                Stakers[msg.sender][id].lastUpdatedTime3 = block.timestamp; 
            }

            stakeToken.transfer (msg.sender, totalRewards);
            emit rewards(msg.sender,totalRewards);

        }


    function unstake(uint id,uint poolType) public {
        require(!isBlocked[msg.sender],"User Blocked");
         uint _amount = (Stakers[msg.sender][id].stakeAmount) ;
             withdrawRewards(id,poolType);
             totalStaking-=_amount;
            stakeToken.transfer (msg.sender, _amount);
            delete Stakers[msg.sender][id];
            emit Unstaked(msg.sender, _amount);
    }


    function recoverExcessToken(address _tokenAddress, uint256 amount) external onlyOwner {
        IERC20(_tokenAddress).transfer(msg.sender, amount);
        emit RecoverToken(_tokenAddress, amount);
    }

    function getContractTokenBalance() public view returns(uint256) {
        return stakeToken.balanceOf(address(this));
    }
    function blockUser(address _userAddress) external onlyOwner{
               isBlocked[_userAddress]=true;
    }
    function unBlockUser(address _userAddress) external onlyOwner{
               isBlocked[_userAddress]=false;
    }
    function TotalRewards() public view returns(uint256){
        uint256 tRewards = totalRewardFunds - totalRewardsGiven;
        return tRewards;
    }
}