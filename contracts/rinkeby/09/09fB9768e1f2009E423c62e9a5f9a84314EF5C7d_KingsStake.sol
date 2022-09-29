// SPDX-License-Identifier: MIT
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

pragma solidity ^0.8.15;

interface IERC20 {
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);
    function allowance(address _owner, address spender)
        external
        view
        returns (uint256);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

contract KingsStake is Ownable, ReentrancyGuard {
    
    struct user{
        uint256 id;
        uint256 totalStakedBalance;
        uint256 totalClaimedRewards;
        uint256 createdTime;
    }

    struct stakePool{
        uint256 id;
        uint256 duration;
        uint256 multiplier; // Used for dynamic APY
        uint256 APY; // Used for fixed APY
        uint256 withdrawalFee;
        uint256 unstakeFee;
        uint256 earlyUnstakePenalty;
        uint256 stakedTokens;
        uint256 claimedRewards;
        uint256 claimFrequency;
        uint256 status; //1: created, 2: active, 3: cancelled
        uint256 createdTime;
    }

    stakePool[] public stakePoolArray;

    struct userStake{
        uint256 id;
        uint256 stakePoolId;
	    uint256 stakeBalance;
    	uint256 totalClaimedRewards;
    	uint256 lastClaimedTime;
        uint256 nextClaimTime;
        uint256 status; //0 : Unstaked, 1 : Staked
        address owner;
    	uint256 createdTime;
        uint256 unlockTime;
        uint256 lockDuration;
    }

    userStake[] public userStakeArray;


    mapping (uint256 => stakePool) public stakePoolsById;
    mapping (uint256 => userStake) public userStakesById;

    mapping (address => uint256[]) public userStakeIds;
    mapping (address => userStake[]) public userStakeLists;

    mapping (address => user) public users;

    uint256 public totalStakedBalance;
    uint256 public totalClaimedBalance;
  
    uint256 public magnitude = 100000000;

    uint256 public userIndex;
    uint256 public poolIndex;
    uint256 public stakeIndex;

    bool public dynamicApy;
    bool public unstakePenalty;
    bool public isPaused;

    address public baseTokenAddress;
    IERC20 stakeToken = IERC20(baseTokenAddress);

    address public rewardTokensAddress;
    IERC20 rewardToken = IERC20(rewardTokensAddress);
    

    modifier unpaused {
      require(isPaused == false);
      _;
    }

    modifier paused {
      require(isPaused == true);
      _;
    }

    uint256[] _durationArray = [30,60,90];
    uint256[] _multiplierArray = [0,0,0];
    uint256[] _apyArray = [11500,15500,21500]; 
    uint256[] _withdrawalFeeArray = [0,0,0];
    uint256[] _unstakePenaltyArray = [50,50,50];
    uint256[] _claimFrequencyArray = [30,60,90];
    
    constructor() {
        address _baseTokenAddress = 0x4cc7d47C32bfF3Ba391f1612DEBff254457BC509; 
        address _rewardTokensAddress = 0x4cc7d47C32bfF3Ba391f1612DEBff254457BC509;

        dynamicApy = false;
        unstakePenalty = true; 

        baseTokenAddress = _baseTokenAddress;
        rewardTokensAddress = _rewardTokensAddress;
        
        stakeToken = IERC20(baseTokenAddress);
        rewardToken = IERC20(rewardTokensAddress);

        for(uint256 i = 0; i < _durationArray.length; i++){
            addStakePool(
                _durationArray[i], // Duration in days
                _multiplierArray[i], // Multiplier for Dynamic APY
                _apyArray[i], // APY percentage for static APY
                _withdrawalFeeArray[i], // Withdrawal fees percentage
                _unstakePenaltyArray[i], // Early unstake penalty
                _claimFrequencyArray[i]
            );
        }
    }
    
    function addStakePool(uint256 _duration, uint256 _multiplier, uint256 _apy, uint256 _withdrawalFee, uint256 _unstakePenalty, uint256 _claimFrequency ) public onlyOwner returns (bool){
        if(dynamicApy == true){
            require(_multiplier > 0,"Multipier is required for dynamic APY pools");
            require(_apy == 0,"Fixed APY percentage must be 0 for dynamic APY pools");
        }else{
            require(_apy > 0,"Fixed APY percentage is required for fixed APY pools");
            require(_multiplier == 0,"Multipier must be 0 for fixed APY pools");
        }

        if(unstakePenalty == true) {
            require(_unstakePenalty > 0,"Unstake penalty must be greater than 0 if unstake penalty is enabled");
        }else {
            require(_unstakePenalty == 0,"Unstake penalty must be 0 if unstake penalty is disabled");
        }

        stakePool memory stakePoolDetails;
        
        stakePoolDetails.id = poolIndex;
        stakePoolDetails.duration = _duration;
        stakePoolDetails.multiplier = _multiplier;
        stakePoolDetails.APY = _apy;
        stakePoolDetails.withdrawalFee = _withdrawalFee;
        stakePoolDetails.earlyUnstakePenalty = _unstakePenalty;
        stakePoolDetails.claimFrequency = _claimFrequency;
        
        stakePoolDetails.createdTime = block.timestamp;
       
        stakePoolArray.push(stakePoolDetails);
        stakePoolsById[poolIndex++] = stakePoolDetails;

        return true;
    }

    function getDPR(uint256 _stakePoolId) public view returns (uint256){
        uint256 apy;
        uint256 dpr;

        stakePool memory stakePoolDetails = getStakePoolDetailsById(_stakePoolId);

        if(dynamicApy == false){
            
            apy = stakePoolDetails.APY;
            dpr = (apy * magnitude) / (365 * 100);
        }else{
            uint256 rewardTokenBalance = rewardToken.balanceOf(address(this));
            
            uint256 poolMultiplier = stakePoolDetails.multiplier;
            uint256 totalPoolsAPY = rewardTokenBalance / totalStakedBalance;
            apy = totalPoolsAPY * poolMultiplier;
            dpr = (apy * magnitude) / (365 * 100);
        }
        return (dpr);
    }

    function getAPYOfAllPools() public view returns (uint256[] memory) {
        uint256[] memory allPoolAPY = new uint256[](stakePoolArray.length);
        stakePool memory stakePoolDetails;
        uint256 stakePoolAPY;

        if(dynamicApy == false){
            
            uint256 rewardTokenBalance = rewardToken.balanceOf(address(this));
            uint256 poolMultiplier;
            uint256 totalPoolsAPY;

            for(uint256 i = 0; i < stakePoolArray.length; i++ ){
                stakePoolDetails = stakePoolArray[i];
                poolMultiplier = stakePoolDetails.multiplier;
                totalPoolsAPY = rewardTokenBalance / totalStakedBalance;
                stakePoolAPY = totalPoolsAPY * poolMultiplier;
                allPoolAPY[i] = stakePoolAPY;
            }
        }else{
            for(uint256 i = 0; i < stakePoolArray.length; i++ ){
                stakePoolDetails = stakePoolArray[i];
                stakePoolAPY = stakePoolDetails.APY;
                allPoolAPY[i] = stakePoolAPY;
            }
        }
        return (allPoolAPY);
    }

    function getStakePoolDetailsById(uint256 _stakePoolId) public view returns(stakePool memory){
        return (stakePoolArray[_stakePoolId]);
    }

    function getElapsedTime(uint256 _stakeId) public view returns(uint256){
        userStake memory userStakeDetails = userStakesById[_stakeId];
        uint256 lapsedDays = ((block.timestamp - userStakeDetails.lastClaimedTime)/3600)/24; //3600 seconds per hour so: lapsed days = lapsed time * (3600seconds /24hrs)
        return lapsedDays;  
    }

    function stake(uint256 _stakePoolId, uint256 _amount) unpaused external returns (bool) {
        stakePool memory stakePoolDetails = stakePoolsById[_stakePoolId];

        require(stakeToken.allowance(msg.sender, address(this)) >= _amount,'Tokens not approved for transfer');
        
        bool success = stakeToken.transferFrom(msg.sender, address(this), _amount);
        require(success, "Token Transfer failed.");

        userStake memory userStakeDetails;

        uint256 userStakeid = stakeIndex++;
        userStakeDetails.id = userStakeid;
        userStakeDetails.stakePoolId = _stakePoolId;
        userStakeDetails.stakeBalance = _amount;
        userStakeDetails.status = 1;
        userStakeDetails.owner = msg.sender;
        userStakeDetails.createdTime = block.timestamp;
        userStakeDetails.unlockTime = block.timestamp + (stakePoolDetails.duration * 86400);
        userStakeDetails.lockDuration = stakePoolDetails.duration;
        userStakeDetails.lastClaimedTime = block.timestamp - 2 days;
        userStakeDetails.nextClaimTime = userStakeDetails.lastClaimedTime + (stakePoolDetails.claimFrequency * 1 days);
        userStakesById[userStakeid] = userStakeDetails;
    
        uint256[] storage userStakeIdsArray = userStakeIds[msg.sender];
    
        userStakeIdsArray.push(userStakeid);
        userStakeArray.push(userStakeDetails);
    
        userStake[] storage userStakeList = userStakeLists[msg.sender];
        userStakeList.push(userStakeDetails);
        
        user memory userDetails = users[msg.sender];

        if(userDetails.id == 0){
            userDetails.id = ++userIndex;
            userDetails.createdTime = block.timestamp;
        }

        userDetails.totalStakedBalance += _amount;

        users[msg.sender] = userDetails;

        stakePoolDetails.stakedTokens += _amount;
    
        stakePoolArray[_stakePoolId] = stakePoolDetails;
        
        stakePoolsById[_stakePoolId] = stakePoolDetails;

        totalStakedBalance = totalStakedBalance + _amount;
        
        return true;
    }

    function unstake(uint256 _stakeId) nonReentrant unpaused external returns (bool){
        userStake memory userStakeDetails = userStakesById[_stakeId];
        uint256 stakePoolId = userStakeDetails.stakePoolId;
        uint256 stakeBalance = userStakeDetails.stakeBalance;
        
        require(userStakeDetails.owner == msg.sender,"You don't own this stake");
        
        stakePool memory stakePoolDetails = stakePoolsById[stakePoolId];

        uint256 unstakableBalance;
        if(isStakeLocked(_stakeId)){
            unstakableBalance = stakeBalance - (stakeBalance * stakePoolDetails.earlyUnstakePenalty)/(100);
        }else{
            unstakableBalance = stakeBalance;
        }

        userStakeDetails.status = 0;

        userStakesById[_stakeId] = userStakeDetails;

        stakePoolDetails.stakedTokens = stakePoolDetails.stakedTokens - stakeBalance;

        userStakesById[_stakeId] = userStakeDetails;

        user memory userDetails = users[msg.sender];
        userDetails.totalStakedBalance =   userDetails.totalStakedBalance - stakeBalance;

        users[msg.sender] = userDetails;

        stakePoolsById[stakePoolId] = stakePoolDetails;

        updateStakeArray(_stakeId);

        totalStakedBalance =  totalStakedBalance - stakeBalance;

        require(stakeToken.balanceOf(address(this)) >= unstakableBalance, "Insufficient contract stake token balance");
        
        bool success = stakeToken.transfer(msg.sender, unstakableBalance);
        require(success, "Token Transfer failed.");

        return true;
    }

    function isStakeLocked(uint256 _stakeId) public view returns (bool) {
        userStake memory userStakeDetails = userStakesById[_stakeId];
        if(block.timestamp < userStakeDetails.unlockTime){
            return true;
        }else{
            return false;
        }
    }

    function getStakePoolIdByStakeId(uint256 _stakeId) public view returns(uint256){
        userStake memory userStakeDetails = userStakesById[_stakeId];
        return userStakeDetails.stakePoolId;
    }

    function getUserStakeIds() public view returns(uint256[] memory){
        return (userStakeIds[msg.sender]);
    }

    function getUserStakeIdsByAddress(address _userAddress) public view returns(uint256[] memory){
         return(userStakeIds[_userAddress]);
    }

    
    function getUserAllStakeDetails() public view returns(userStake[] memory){
        return (userStakeLists[msg.sender]);
    }

    function getUserAllStakeDetailsByAddress(address _userAddress) public view returns(userStake[] memory){
        return (userStakeLists[_userAddress]);
    }

    function getUserStakeOwner(uint256 _stakeId) public view returns (address){
        userStake memory userStakeDetails = userStakesById[_stakeId];
        return userStakeDetails.owner;
    }

    function getUserStakeBalance(uint256 _stakeId) public view returns (uint256){
        userStake memory userStakeDetails = userStakesById[_stakeId];
        return userStakeDetails.stakeBalance;
    }
    
    function getUnclaimedRewards(uint256 _stakeId) public view returns (uint256){
        userStake memory userStakeDetails = userStakeArray[_stakeId];
        uint256 stakePoolId = userStakeDetails.stakePoolId;

        stakePool memory stakePoolDetails = stakePoolsById[stakePoolId];
        uint256 stakeApr = getDPR(stakePoolDetails.id);

        uint applicableRewards = (userStakeDetails.stakeBalance * stakeApr)/(magnitude * 100); //divided by 10000 to handle decimal percentages like 0.1%
        uint unclaimedRewards = (applicableRewards * getElapsedTime(_stakeId));

        return unclaimedRewards; 
    }

    function getTotalUnclaimedRewards(address _userAddress) public view returns (uint256){
        uint256[] memory stakeIds = getUserStakeIdsByAddress(_userAddress);
        uint256 totalUnclaimedRewards;
        for(uint256 i = 0; i < stakeIds.length; i++) {
            userStake memory userStakeDetails = userStakesById[stakeIds[i]];
            if(userStakeDetails.status == 1){
                totalUnclaimedRewards += getUnclaimedRewards(stakeIds[i]);
            }
        }
        return totalUnclaimedRewards;
    }

    
    function getAllPoolDetails() public view returns(stakePool[] memory){
        return (stakePoolArray);
    }

    function claimRewards(uint256 _stakeId) nonReentrant unpaused public returns (bool){
        address userStakeOwner = getUserStakeOwner(_stakeId);
        require(userStakeOwner == msg.sender,"You don't own this stake");

        userStake memory userStakeDetails = userStakesById[_stakeId];
        uint256 stakePoolId = userStakeDetails.stakePoolId;

        stakePool memory stakePoolDetails = getStakePoolDetailsById(stakePoolId);
 
        require(userStakeDetails.status == 1, "You can not claim after unstaked");
        
        if(userStakeDetails.nextClaimTime <= userStakeDetails.unlockTime){
            require(userStakeDetails.nextClaimTime <= block.timestamp,"You can not withdraw");
        }
        uint256 unclaimedRewards = getUnclaimedRewards(_stakeId);
        
        userStakeDetails.totalClaimedRewards = userStakeDetails.totalClaimedRewards + unclaimedRewards;
        userStakeDetails.lastClaimedTime = block.timestamp;
        userStakeDetails.nextClaimTime = userStakeDetails.lastClaimedTime + (stakePoolDetails.claimFrequency * 1 days);
        userStakesById[_stakeId] = userStakeDetails;
        updateStakeArray(_stakeId);

        totalClaimedBalance += unclaimedRewards;

        user memory userDetails = users[msg.sender];
        userDetails.totalClaimedRewards  +=  unclaimedRewards;

        users[msg.sender] = userDetails;

        require(rewardToken.balanceOf(address(this)) >= unclaimedRewards, "Insufficient contract reward token balance");

        if(rewardToken.decimals() < stakeToken.decimals()){
            unclaimedRewards = unclaimedRewards * (10**(stakeToken.decimals() - rewardToken.decimals()));
        }else if(rewardToken.decimals() > stakeToken.decimals()){
            unclaimedRewards = unclaimedRewards / (10**(rewardToken.decimals() - stakeToken.decimals()));
        }

        bool success = rewardToken.transfer(msg.sender, unclaimedRewards);
        require(success, "Token Transfer failed.");

        return true;
    }

    function updateStakeArray(uint256 _stakeId) internal {
        userStake[] storage userStakesArray = userStakeLists[msg.sender];
        
        for(uint i = 0; i < userStakesArray.length; i++){
            userStake memory userStakeFromArrayDetails = userStakesArray[i];
            if(userStakeFromArrayDetails.id == _stakeId){
                userStake memory userStakeDetails = userStakesById[_stakeId];
                userStakesArray[i] = userStakeDetails;
            }
        }
    }

    function getUserDetails(address _userAddress) external view returns (user memory){
        user memory userDetails = users[_userAddress];
        return(userDetails);
    }
    
    function pauseStake(bool _pauseStatus) public onlyOwner(){
        isPaused = _pauseStatus;
    }
    
    function withdrawContractETH() public onlyOwner paused returns(bool){
        bool success;
        (success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");

        success = false;
        
        success = rewardToken.transfer(msg.sender, rewardToken.balanceOf(address(this)));
        require(success, "Token Transfer failed.");

        return true;
    }
    
    receive() external payable {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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