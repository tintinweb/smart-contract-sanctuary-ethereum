/**
 *Submitted for verification at Etherscan.io on 2022-11-12
*/

/**
 *Submitted for verification at BscScan.com on 2022-10-31
*/

/**
 *Submitted for verification at BscScan.com on 2022-10-29
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


/**
 * @dev Interface of the BEP20 standard as defined in the BIP.
 */
interface IBEP20 {
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
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract Stake is Ownable {

    IBEP20 private token;

    struct PoolStruct {
        address tokenAddress;
        uint256 rewardPer;
        uint256 referralPer;
        uint256 lockPeriod;
        uint256 time;
    }

    struct UserStruct{
        bool isExist;
        address referral;   
        uint256 harvested;  
        uint256 referralReward;
        uint256[] stakingIds; 
    }

    struct StakeStruct {
        address staker;
        uint256 amount;
        uint256 stakeTime;
        uint256 unstakeTime;
        uint256 poolId;
    }

    uint256 private stakingId = 0;

    mapping(address => UserStruct)private userDetails;
    mapping (uint256 => StakeStruct) private stakeDetails;
    mapping(address => uint256) private referralReward;
    PoolStruct[] private pool;

    event Staked(address indexed staker, uint256 poolId, uint256 amount, address referral, uint256 time);
    event UnStaked(address indexed staker, uint256 poolId, uint256 amount, uint256 time);
    event Rewards(address staker, uint256 amount, uint256 time);
    event PoolCreated (uint256 poolId, address tokenAddress, uint256 rewardPer, uint256 referralPer, uint256 lockPeriod, uint256 time);
    event PoolUpdated (uint256 poolId, uint256 rewardPer, uint256 referralPer, uint256 lockPeriod, uint256 time);

    function intialize(address _token) public onlyOwner returns (bool){
        require(_token != address(0),"Invalid Address");
        token = IBEP20(_token);
        return true;
    }
    
    function createPool(address _tokenAddress, uint256 _rewardPer, uint256 _referralPer , uint256 _lockPeriod) public onlyOwner returns (bool){
        require(_tokenAddress != address(0), "Invalid Address");
        require(_rewardPer > 0, "Reward per must be greater than 0");
        PoolStruct memory poolInfo;
        poolInfo = PoolStruct({
            tokenAddress : _tokenAddress,
            rewardPer    : _rewardPer,
            referralPer  : _referralPer,
            lockPeriod   : _lockPeriod,
            time         : block.timestamp
        });
        pool.push(poolInfo);
        emit PoolCreated(pool.length - 1, _tokenAddress, _rewardPer, _referralPer, _lockPeriod, block.timestamp);
        return true;
    }

    function updatePool(uint256 _poolId, uint256 _rewardPer, uint256 _referralPer, uint256 _lockPeriod) public onlyOwner returns (bool){
        require(pool[_poolId].tokenAddress != address(0), "Pool not exist");
        pool[_poolId].rewardPer = _rewardPer;
        pool[_poolId].referralPer = _referralPer;
        pool[_poolId].lockPeriod = _lockPeriod;
        emit PoolUpdated(_poolId, _rewardPer, _referralPer, _lockPeriod, block.timestamp);
        return true;      
    }

    function stake(uint256 _poolId, uint256 _amount, address _referral) public returns(bool) {
        require(msg.sender != _referral, "Staker and referral address must not same");
        require(_referral == address(0) || userDetails[_referral].isExist || userDetails[msg.sender].isExist, "Wrong Referral");
        require(pool[_poolId].tokenAddress != address(0), "Invalid Pool");
        require (IBEP20(pool[_poolId].tokenAddress).allowance(msg.sender, address(this)) >= _amount, "Token not approved");  
        IBEP20(pool[_poolId].tokenAddress).transferFrom(msg.sender, address(this), _amount);     
        if(!userDetails[msg.sender].isExist){
            UserStruct memory userInfo;
            userInfo = UserStruct({
                isExist : true,
                referral : _referral,
                harvested : 0,
                referralReward : 0,
                stakingIds : new uint256[](0)
            });
            userDetails[msg.sender] = userInfo;           
        }
        if(address(0) != userDetails[msg.sender].referral){
            userDetails[_referral].referralReward += _amount * pool[_poolId].referralPer / 10000;
            IBEP20(pool[_poolId].tokenAddress).transfer(_referral, _amount * pool[_poolId].referralPer / 10000);
            referralReward[msg.sender] += _amount * pool[_poolId].referralPer / 10000;
        }
        StakeStruct memory stakerinfo;
        stakerinfo = StakeStruct({
            staker  : msg.sender,
            amount : _amount,
            stakeTime : block.timestamp,
            unstakeTime : block.timestamp + pool[_poolId].lockPeriod,
            poolId : _poolId
        });       
        stakeDetails[stakingId] = stakerinfo;       
        userDetails[msg.sender].stakingIds.push(stakingId);
        stakingId++;
        emit Staked(msg.sender, _poolId, _amount, _referral, block.timestamp);
        return true;
    }


    function unstake(uint256 _stakingId) public returns (bool){    
        require(stakeDetails[_stakingId].staker == msg.sender, "You are not a staker");    
        require(stakeDetails[_stakingId].unstakeTime <= block.timestamp, "Token can unstake after locking period");      
        for(uint256 i = 0; i < userDetails[msg.sender].stakingIds.length; i++){
            if(userDetails[msg.sender].stakingIds[i] == _stakingId){
                userDetails[msg.sender].stakingIds[i] = userDetails[msg.sender].stakingIds[userDetails[msg.sender].stakingIds.length-1];
                delete userDetails[msg.sender].stakingIds[userDetails[msg.sender].stakingIds.length-1];
                userDetails[msg.sender].stakingIds.pop();
                break;
            }
        }
        delete stakeDetails[_stakingId];
        IBEP20(pool[stakeDetails[_stakingId].poolId].tokenAddress).transfer(msg.sender, stakeDetails[_stakingId].amount);
        emit UnStaked(msg.sender, stakeDetails[_stakingId].poolId, stakeDetails[_stakingId].amount, block.timestamp);
        return true;
    }

    function viewPoolLength() public view returns(uint256){
        return pool.length;
    }

    function transferTokens(uint256 _amount, address _token) public onlyOwner{
        require(IBEP20(_token).balanceOf(address(this)) > _amount , "Not Enough Tokens");
        IBEP20(_token).transfer(owner(), _amount);
    } 

    function rewards() public {
        require(userDetails[msg.sender].isExist, "Address is not a staker");
        uint _amount = viewStakerTotalROI(msg.sender) - userDetails[msg.sender].harvested;
        token.transfer(msg.sender, _amount);
        userDetails[msg.sender].harvested += _amount;
        emit Rewards(msg.sender, _amount, block.timestamp);
    }

    function viewToken() public view returns(IBEP20){
        return token;
    }

    function viewPoolDetails(uint256 _poolId) public view returns(PoolStruct memory){
        return pool[_poolId];
    }

    function viewUserDetails(address _staker) public view returns(uint256 len, uint256[] memory id, UserStruct memory){
        return (userDetails[_staker].stakingIds.length, userDetails[_staker].stakingIds, userDetails[_staker]);
    }

    function viewStakingDetails(uint256 _stakingId) public view returns(StakeStruct memory){
        return stakeDetails[_stakingId];
    }

    function viewCurrentStakingId() public view returns(uint256){
        return stakingId;
    }

    function viewStakerTotalROI(address _staker) public view returns(uint256 roi){
        roi = 0;
        for(uint256 i = 0; i < userDetails[_staker].stakingIds.length; i++){
            roi += viewROI(userDetails[_staker].stakingIds[i]);
        }
        return roi;
    }

    function viewROI(uint256 _stakingId) public view returns(uint256 ROI){
        if(stakeDetails[_stakingId].unstakeTime < block.timestamp){
            return ( ( (block.timestamp - stakeDetails[_stakingId].unstakeTime) / 10 minutes * stakeDetails[_stakingId].amount * pool[stakeDetails[_stakingId].poolId].rewardPer / 10000) );
        }else{
            return ( ( (block.timestamp - stakeDetails[_stakingId].stakeTime) / 10 minutes * stakeDetails[_stakingId].amount * pool[stakeDetails[_stakingId].poolId].rewardPer / 10000) );
        }
    }   

    function viewReferralReward(address _staker) public view returns(uint256 amount){
        return referralReward[_staker];
    }
}