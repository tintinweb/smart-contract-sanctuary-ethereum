// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);
    function allowance(address _owner, address spender)
        external
        view
        returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

interface IERC721 {
    function balanceOf(address owner) external view returns (uint256 balance);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function walletOfOwner(address _owner) external view returns (uint256[] memory);
}
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
    mapping (address => bool) authorized;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
        authorized[_msgSender()] = true;

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
        require(owner() == _msgSender() || authorized[_msgSender()] == true , "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract PYRStake is Ownable {
    
    struct user{
        uint256 id;
        uint256 totalStakedBalance;
        uint256 totalClaimedRewards;
        uint256 createdTime;
    }

    struct stakePool{
        uint256 id;
        uint256 duration;
        uint256 withdrawalFee;
        uint256 unstakePenalty;
        uint256 stakedTokens;
        uint256 claimedRewards;
        uint256 status; //1: created, 2: active, 3: cancelled
        address creator;
        uint256 createdTime;
    }

    stakePool[] public stakePoolArray;
    uint256[] apys;

    struct userStake{
        uint256 id;
        uint256 stakePoolId;
	    uint256 stakeBalance;
    	uint256 totalClaimedRewards;
    	uint256 lastClaimedTime;
        address tokenAddress;
        uint256 status; //0 : Unstaked, 1 : Staked
        address owner;
    	uint256 createdTime;
        uint256 unlockTime;
    }

    userStake[] public userStakeArray;

    mapping (uint256 => stakePool) public stakePoolsById;
    mapping (uint256 => userStake) public userStakesById;

    mapping (address => uint256[]) public userStakeIds;
    mapping (address => userStake[]) userStakeLists;
   
    mapping (address => user) users;

    uint256 public totalStakedBalance;
    uint256 public totalClaimedBalance;
    uint256 public magnitude = 100000000;

    uint256 public userIndex;
    uint256 public poolIndex;
    uint256 public stakeIndex;

    bool public isPaused = false;

    address baseTokenAddress = 0x56398335Fb45C5D390E0613Df882FB88afD1d24c; // Testnet - Your ERC20 token address (LunaCats Token)  
    //address baseTokenAddress = 0x16f322072E05748B9EAd2F8f281daE10AB9CfFe9; // Local - Your ERC20 token address (LunaCats Token)
    IERC20 stakeToken = IERC20(baseTokenAddress);

    address rewardTokensAddress = 0x8F58D494864aBF682a3827F36E6819F9CAB1EA40; // Testnet
    IERC20 rewardToken = IERC20(rewardTokensAddress);
    

    modifier unpaused {
      require(isPaused == false);
      _;
    }

    constructor() {   
        
        addStakePool(
            7, // Duration in days
            50, // APY %
            0, // Withdrawal Fee %
            0 // Unstaking Penalty %
        );

        
        addStakePool(
            14, // 30 Days lock pool
            70, // APY %
            0,
            0
        );

        addStakePool(
            13, // 14 Days lock pool
            90, // APY %
            0,
            0
        );
        
    }
    
   

    function addStakePool(uint256 _duration, uint256 _apy, uint256 _withdrawalFee, uint256 _unstakePenalty ) public onlyOwner returns (bool){
    
        stakePool memory stakePoolDetails;
        
        stakePoolDetails.id = poolIndex++;
        stakePoolDetails.duration = _duration;
        stakePoolDetails.withdrawalFee = _withdrawalFee;
        stakePoolDetails.unstakePenalty = _unstakePenalty;
        stakePoolDetails.creator = msg.sender;
        stakePoolDetails.createdTime = block.timestamp;
       
        stakePoolArray.push(stakePoolDetails);
        apys.push(_apy);
        return true;
    }

    function setStakePoolStatus (uint256 _stakePoolId, uint256 _status) external onlyOwner returns (bool) {
        require((_status == 0 || _status == 1 || _status == 2 || _status == 3),"Invalid status");
        stakePool memory stakePoolDetails = stakePoolsById[_stakePoolId];
        stakePoolDetails.status = _status;
        stakePoolsById[_stakePoolId] = stakePoolDetails;
        return true;
    }

    function setStakePoolDuration (uint256 _stakePoolId, uint256 _duration) external onlyOwner returns (bool) {
        stakePool memory stakePoolDetails = stakePoolsById[_stakePoolId];
        stakePoolDetails.duration = _duration;
        stakePoolsById[_stakePoolId] = stakePoolDetails;
        return true;
    }

    function getAPY(uint256 _stakePoolId) public view returns (uint256){
        return apys[_stakePoolId];
    }

    function getDPR(uint256 _stakePoolId) public view returns (uint256){
        uint256 apy = getAPY(_stakePoolId);
        uint256 dpr = (apy * magnitude) / 360;
        return dpr;
    }

    function getStakePoolDetailsById(uint256 _stakePoolId) public view returns(stakePool memory){
        //stakePool memory stakePoolDetails = stakePoolArray[_stakePoolId];
        return (stakePoolArray[_stakePoolId]);
    }

    function updateLastClaimedTime(uint256 _stakeId, uint256 _newTimestamp) public {
        userStake memory userStakeDetails = userStakesById[_stakeId];
        userStakeDetails.lastClaimedTime = _newTimestamp;

        userStakesById[_stakeId] = userStakeDetails;
    }

    function getLastClaimedTime(uint256 _stakeId) public view returns(uint256){
        userStake memory userStakeDetails = userStakesById[_stakeId];
        return userStakeDetails.lastClaimedTime;
    }

    function getElapsedTime(uint256 _stakeId) public view returns(uint256){
        userStake memory userStakeDetails = userStakesById[_stakeId];
        if(userStakeDetails.lastClaimedTime == 0){
            uint256 lapsedDays = ((block.timestamp - userStakeDetails.createdTime)/3600)/24; //3600 seconds per hour so: lapsed days = lapsed time * (3600seconds /24hrs)
            return lapsedDays;
        }else {
            uint256 lapsedDays = ((block.timestamp - userStakeDetails.lastClaimedTime)/3600)/24; //3600 seconds per hour so: lapsed days = lapsed time * (3600seconds /24hrs)
            return lapsedDays;
        }
    }

    function stake(uint256 _stakePoolId, uint256 _amount) unpaused external returns (bool){
        stakePool memory stakePoolDetails = stakePoolsById[_stakePoolId];

        /*
        //IERC20 stakeToken = IERC20(stakePoolDetails.tokenAddress);
        require(stakeToken.allowance(msg.sender, address(this)) >= _amount,'Tokens not approved for transfer');

        
        bool success = stakeToken.transferFrom(msg.sender, address(this), _amount);
        require(success, "Token Transfer failed.");
        */

        userStake memory userStakeDetails;

        uint256 userStakeid = stakeIndex++;
        userStakeDetails.id = userStakeid;
        userStakeDetails.stakePoolId = _stakePoolId;
        userStakeDetails.stakeBalance = _amount;
        userStakeDetails.status = 1;
        userStakeDetails.owner = msg.sender;
        userStakeDetails.lastClaimedTime = (block.timestamp - 1 days);
        userStakeDetails.createdTime = block.timestamp;
        userStakeDetails.unlockTime = block.timestamp + (stakePoolDetails.duration * 86400) ;
        
        userStakesById[userStakeid] = userStakeDetails;
        
        uint256[] storage userStakeIdsArray = userStakeIds[msg.sender];
        
        userStakeIdsArray.push(userStakeid);
        userStakeArray.push(userStakeDetails);
        
        userStake[] storage userStakeList = userStakeLists[msg.sender];
        userStakeList.push(userStakeDetails);
        //userStakeLists[msg.sender] = userStakeListDetails;

        user memory userDetails = users[msg.sender];

        if(userDetails.id == 0){
            userDetails.id = block.timestamp;
            userDetails.createdTime = block.timestamp;
        }

        userDetails.totalStakedBalance = userDetails.totalStakedBalance + _amount;

        users[msg.sender] = userDetails;

        stakePoolDetails.stakedTokens = stakePoolDetails.stakedTokens + _amount;
        
        stakePoolsById[_stakePoolId] = stakePoolDetails;

        totalStakedBalance = totalStakedBalance + _amount;

        return true;
    }

    function unstake(uint256 _stakeId) unpaused external returns (bool){
        require(isStakeLocked(_stakeId) == false,"The staked is locked");
        
        userStake memory userStakeDetails = userStakesById[_stakeId];
        uint256 stakePoolId = userStakeDetails.stakePoolId;
        //uint256 createdTime = userStakeDetails.createdTime;
        uint256 stakeBalance = userStakeDetails.stakeBalance;
        
        require(userStakeDetails.owner == msg.sender,"You don't own this stake");
        IERC20 token = IERC20(userStakeDetails.tokenAddress);
        
        stakePool memory stakePoolDetails = stakePoolsById[stakePoolId];

        uint256 unstakableBalance = stakeBalance;
        userStakeDetails.stakeBalance = 0;
        userStakeDetails.status = 0;

        userStakesById[_stakeId] = userStakeDetails;

        stakePoolDetails.stakedTokens = stakePoolDetails.stakedTokens - stakeBalance;

        //userStakeDetails.lastClaimedTime = block.timestamp;
        userStakesById[_stakeId] = userStakeDetails;

        user memory userDetails = users[msg.sender];
        userDetails.totalStakedBalance =   userDetails.totalStakedBalance - unstakableBalance;

        users[msg.sender] = userDetails;
        stakePoolsById[stakePoolId] = stakePoolDetails;

        totalStakedBalance =  totalStakedBalance - unstakableBalance;
    
        bool success = token.transfer(msg.sender, unstakableBalance);
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

    function getUserStakeDetailsByStakeId(uint256 _stakeId) public view returns(userStake memory, stakePool memory){ 
        userStake memory userStakeDetails = userStakeArray[_stakeId];
        uint256 userStakePoolId = userStakeDetails.stakePoolId;
        return (userStakeArray[_stakeId], stakePoolArray[userStakePoolId]);
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

        //uint256 lapsedDays = ((block.timestamp - userStakeDetails.lastClaimedTime)/3600)/24; //3600 seconds per hour so: lapsed days = lapsed time * (3600seconds /24hrs)
        uint applicableRewards = (userStakeDetails.stakeBalance * stakeApr)/(magnitude * 100); //divided by 10000 to handle decimal percentages like 0.1%
        uint unclaimedRewards = applicableRewards * getElapsedTime(_stakeId);

        return unclaimedRewards; 
    }

    function getTotalUnclaimedRewards() public view returns (uint256){
        uint256[] memory stakeIds = getUserStakeIds();
        uint256 totalUnclaimedRewards;
        for(uint256 i = 0; i < stakeIds.length; i++) {
            totalUnclaimedRewards += getUnclaimedRewards(stakeIds[i]);
        }
        return totalUnclaimedRewards;
    }

    function getTotalUnclaimedRewardsByAddress(address _userAddress) public view returns (uint256){
        uint256[] memory stakeIds = getUserStakeIdsByAddress(_userAddress);
        uint256 totalUnclaimedRewards;
        for(uint256 i = 0; i < stakeIds.length; i++) {
            totalUnclaimedRewards += getUnclaimedRewards(stakeIds[i]);
        }
        return totalUnclaimedRewards;
    }

    
    function getAllPoolDetails() public view returns(stakePool[] memory, uint256[] memory){
        return (stakePoolArray,apys);
    }

    function claimRewards(uint256 _stakeId) unpaused external returns (bool){
        address userStakeOwner = getUserStakeOwner(_stakeId);
        require(userStakeOwner == msg.sender,"You don't own this stake");

        userStake memory userStakeDetails = userStakesById[_stakeId];
        require(((block.timestamp - userStakeDetails.lastClaimedTime)/3600) > 24,"You already claimed rewards today");
        
        uint256 unclaimedRewards = getUnclaimedRewards(_stakeId);
        
        userStakeDetails.totalClaimedRewards = userStakeDetails.totalClaimedRewards + unclaimedRewards;
        userStakeDetails.lastClaimedTime = block.timestamp;
        userStakesById[_stakeId] = userStakeDetails;

        totalClaimedBalance += unclaimedRewards;

        user memory userDetails = users[msg.sender];
        userDetails.totalClaimedRewards  +=  unclaimedRewards;

        users[msg.sender] = userDetails;

        //IERC20 token = IERC20(userStakeDetails.tokenAddress);

        bool success = rewardToken.transfer(msg.sender, unclaimedRewards);
        require(success, "Token Transfer failed.");

        return true;
    }

    function getUserDetails() external view returns (user memory){
        user memory userDetails = users[msg.sender];
        return(userDetails);
    }

    function getUserDetailsByAddress(address _userAddress) external view returns (user memory){
        user memory userDetails = users[_userAddress];
        return(userDetails);
    }

    function pauseStake() public onlyOwner(){
        isPaused = true;
    }

    function unpauseStake() public onlyOwner(){
        isPaused = false;
    }

    function withdrawContractETH() public onlyOwner returns(bool){
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");

        return true;
    }

    function withdrawContractRewardTokens() public onlyOwner returns(bool){
        //IERC20 token = IERC20(baseTokenAddress);

        bool success = rewardToken.transfer(msg.sender, rewardToken.balanceOf(msg.sender));
        require(success, "Token Transfer failed.");

        return true;
    }

    receive() external payable {
    }
}