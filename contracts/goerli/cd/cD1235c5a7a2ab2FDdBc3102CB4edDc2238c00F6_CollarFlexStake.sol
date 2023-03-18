/**
 *Submitted for verification at Etherscan.io on 2023-03-18
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

interface IERC20 {
    
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address _owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom( address sender, address recipient, uint256 amount) external returns (bool);
}

contract Context {
    
    constructor()  {}

    function _msgSender() internal view returns (address ) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; 
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor()  {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), 'Ownable: caller is not the owner');
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

abstract contract ReentrancyGuard {

    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

contract Pausable is Context {
    
    event Paused(address account);

    event Unpaused(address account);

    bool private _paused;

    constructor () {
        _paused = false;
    }

    function paused() public view returns (bool) {
        return _paused;
    }

    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

contract CollarFlexStake is Ownable, ReentrancyGuard, Pausable {

    IERC20 public CollarToken;
    uint256 constant public stakeDays = 365;
    uint256 public stakeLimit;
    uint256 public currentPool;
    uint256 public rewardBalance = (200 * 1e6 * 1e18) * 33 /100;

    struct UserInfo {
        address staker;
        uint256 poolID;
        uint256 stakeID;
        uint256 stakeAmount;
        uint256 stakeTime;
        uint256 withdrawTime;
        uint256 rewardEndTime;
        uint256 APY_percentage;
        uint256 lastClaim;
        uint256 rewardAmount;
        uint256 maxReward;
    }

    struct poolInfo {
        uint256 poolID;
        IERC20 stakeToken;
        uint256 APYpercentage;
        uint256 poolStakeID;
        uint256 totalStakedToken;
        bool InActive;
    }
    
    struct userID{
        uint256[] stakeIDs;
    }

    mapping(uint256 => mapping(uint256 => UserInfo)) internal userDetails;
    mapping(address => mapping(uint256 => userID)) internal userIDs;
    mapping(uint256 => poolInfo) internal poolDetails;

    event emergencySafe(address indexed receiver, address tokenAddressss, uint256 TokenAmount);
    event CreatePool(address indexed creator,uint256 poolID, address stakeToken,uint256 APYPercentage);
    event staking(address indexed staker, uint256 stakeID, uint256 stakeAmount, uint256 stakeTime);
    event unstaking(address indexed staker, uint256 stakeID, uint256 stakeAmount, uint256 WithdrawTime);
    event setAPYPercentage(address indexed owner,uint256 poolID, uint256 newPercentage);
    event RewardClaimed(address indexed staker,uint256 stakeID, uint256 rewardAmount, uint256 claimTime);
    event adminDeposits(address indexed owner, uint256 RewardDepositamount);
    event UpdatePoolStatus(address indexed owner,uint256 poolID,bool status);
    event Retrieve(address tokens, address to,uint256 amount,uint256 currentTime);

    constructor ( uint256 _maxTokenStake, address _CollarAddress) {
        stakeLimit = _maxTokenStake;
        CollarToken = IERC20(_CollarAddress);
    }

    function viewUserDetails(uint256 _poolID, uint256 _stakeID) external view returns(UserInfo memory){
        return userDetails[_poolID][_stakeID];
    }

    function veiwPools(uint256 _poolID) external view returns(poolInfo memory){
        return poolDetails[_poolID];
    }

    function userStakeIDs(address _account, uint256 _poolID) external view returns(uint256[] memory stakeIDs){
        return userIDs[_account][_poolID].stakeIDs;
    }

    function updateMaxTokenStake(uint256 _maxTokenStake) external onlyOwner  {
        stakeLimit = _maxTokenStake;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unPause() external onlyOwner {
        _unpause();
    }

    function updatePoolAPYpercentage(uint256 _poolID, uint256 _APYpercentage) external onlyOwner  {
        poolInfo storage pool = poolDetails[_poolID];
        pool.APYpercentage = _APYpercentage;

        emit setAPYPercentage(msg.sender, _poolID, _APYpercentage);
    }

    function updateCollarToken(address _CollarToken) external onlyOwner  {
        require(_CollarToken != address(0x0),"Collar is not a zero address");
        CollarToken = IERC20(_CollarToken);
    }

    function poolCreation(address _stakeToken, uint256 _APYPercentage) external onlyOwner  {
        currentPool++;
        poolInfo storage pool = poolDetails[currentPool];
        pool.stakeToken = IERC20(_stakeToken);
        pool.APYpercentage = _APYPercentage;
        pool.poolID = currentPool;

        emit CreatePool(msg.sender, currentPool, _stakeToken, _APYPercentage);
    }

    function poolStatus(uint256 poolID, bool status) external onlyOwner  {
        poolInfo storage pool = poolDetails[poolID];
        require(pool.poolID > 0,"Pool Not found");
        pool.InActive  = status;

        emit UpdatePoolStatus(msg.sender, poolID, status);
    }

    function stake(uint256 _poolID,uint256 _tokenAmount) external nonReentrant whenNotPaused {
        require( _tokenAmount > 0 && _tokenAmount < stakeLimit,"incorrect token amount");
        poolInfo storage pool = poolDetails[_poolID];
        require(!pool.InActive,"pool is not active");
        pool.poolStakeID++;
        UserInfo storage user = userDetails[_poolID][pool.poolStakeID];
        user.staker = _msgSender();
        user.stakeID = pool.poolStakeID;
        user.poolID = _poolID;
        user.stakeAmount = _tokenAmount;
        user.stakeTime = block.timestamp;
        user.lastClaim = block.timestamp;
        user.rewardEndTime = (block.timestamp + (365 * (86400)));
        user.APY_percentage = pool.APYpercentage;
        user.maxReward = _tokenAmount * pool.APYpercentage / 1000;
        if(rewardBalance < user.maxReward) { revert("reward amount exceed"); }
        rewardBalance -= user.maxReward;
        pool.totalStakedToken = pool.totalStakedToken + (_tokenAmount);
        userIDs[_msgSender()][_poolID].stakeIDs.push(pool.poolStakeID);

        (pool.stakeToken).transferFrom(_msgSender(), address(this), _tokenAmount);
        emit staking(_msgSender(), pool.poolStakeID, _tokenAmount, block.timestamp);
    }

    function withdraw(uint256 _poolID,uint256 _stakeID) external nonReentrant whenNotPaused {
        UserInfo storage user = userDetails[_poolID][_stakeID];
        require(user.withdrawTime == 0, "user already claim this ID");
        require(user.staker == _msgSender()," invalid user ID");
        claimReward( _poolID,_stakeID);
        rewardBalance += (user.maxReward - user.rewardAmount);
        user.withdrawTime = block.timestamp;
        CollarToken.transfer(_msgSender(), user.stakeAmount); 
        
        emit unstaking(_msgSender(), _stakeID, user.stakeAmount, block.timestamp);
    }

    function claimReward(uint256 _poolID,uint256 _stakeID) public whenNotPaused {
        UserInfo storage user = userDetails[_poolID][_stakeID];
        require(user.staker == _msgSender()," invalid user ID");
        require(user.withdrawTime == 0, "user already claim this ID");
        uint256 rewardAmount = pendingReward(_poolID,_stakeID);
        if(block.timestamp > user.rewardEndTime){
            user.lastClaim = user.rewardEndTime;
        } else{   user.lastClaim = block.timestamp; }
        user.rewardAmount += rewardAmount;
        CollarToken.transfer(_msgSender(), rewardAmount); 

        emit RewardClaimed(_msgSender(),_stakeID, rewardAmount, user.lastClaim);
    }

    function pendingReward(uint256 _poolID, uint256 _stakeID) public view returns(uint256 Reward) {
        UserInfo storage user = userDetails[_poolID][_stakeID];
        require(user.withdrawTime == 0, "ID unstaked");
        uint256[3] memory localVar;
        if(user.lastClaim <= user.rewardEndTime){
            localVar[2] = block.timestamp;
            if(block.timestamp > user.rewardEndTime){ localVar[2] = user.rewardEndTime; }
            
            localVar[0] = (localVar[2]) - (user.lastClaim);
            localVar[1] = (user.APY_percentage) * (1e16) / (stakeDays);
            Reward = user.stakeAmount * (localVar[0]) * (localVar[1]) / (1000) / (1e16) / (86400);
        } else {
            Reward = 0;
        }
    }

    function adminDeposit(uint256 _tokenAmount) external onlyOwner {
        CollarToken.transferFrom(_msgSender(), address(this), _tokenAmount);
        emit adminDeposits(_msgSender(), _tokenAmount);
    }

    function retrieve(address _token,address to,uint amount) external onlyOwner{
        require(to != address(0) && amount > 0 ,"CollarFlex:Invalid Address || amount");

        if(_token == address(0)){
             require(address(this).balance >=amount, "CollarFlex:Invalid Amount");
             require(payable(to).send(amount),"CollarFlex : Transaction failed");
        }
        else{
            require(IERC20(_token).balanceOf(address(this)) >=amount,"CollarFlex:Invalid Amount");
            IERC20(_token).transfer(to,amount);
        }
        emit Retrieve(_token,to,amount,block.timestamp);
    }

}