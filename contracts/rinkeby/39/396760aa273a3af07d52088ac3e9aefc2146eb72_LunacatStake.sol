/**
 *Submitted for verification at Etherscan.io on 2022-06-13
*/

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

contract LunacatStake is Ownable {
    
    struct user{
        uint256 id;
        uint256 totalStakedBalance;
        uint256 totalClaimedRewards;
        uint256 createdTime;
    }

    struct stakePool{
        uint256 id;
        address tokenAddress;
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

    struct stakePoolList{
        uint256[] poolIds;
    }

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
    }

    struct userStakeList{
        uint256[] stakeIds;
    }

    mapping (uint256 => stakePool) public stakePools;
    mapping (uint256 => userStake) public userStakes;
   
    mapping (uint256 => mapping(uint256 => uint256)) apys;

    mapping (address => userStakeList) userStakeLists;
    mapping (address => stakePoolList) stakePoolLists;
   
    mapping (address => user) users;

    mapping (uint256 => uint256) public nftRarities;

    uint256 public totalStakedBalance;
    uint256 public totalClaimedLockedBalance;
    uint256 public magnitude = 100000000;

    bool public isPaused = false;
    address nftTokenAddress = 0x107f98144fe8665882bc305d19357487E51A2D15; // Testnet LunaCats NFT address
    //address nftTokenAddress = 0xf8e81D47203A594245E36C48e151709F0C19fBe8; // Local LunaCats NFT address

    IERC721 nftToken = IERC721(nftTokenAddress);

    address baseTokenAddress = 0x16f322072E05748B9EAd2F8f281daE10AB9CfFe9; // Testnet - Your ERC20 token address (LunaCats Token)
    //address baseTokenAddress = 0x16f322072E05748B9EAd2F8f281daE10AB9CfFe9; // Local - Your ERC20 token address (LunaCats Token)

    modifier unpaused {
      require(isPaused == false);
      _;
    }

    constructor() {   

        addStakePool(
            baseTokenAddress,
            0, // Duration in days (When duration is 0, its a Flexy Pool)
            20, // Withdrawal Fee 2%
            20 // Unstaking Penalty 0% (For flexy pools 0% unstaking penalty)
        );
        addStakePool(
            baseTokenAddress,
            7, // 30 Days lock pool
            20,
            20
        );

        addStakePool(
            baseTokenAddress,
            14, // 14 Days lock pool
            20,
            20
        );

        addStakePool(
            baseTokenAddress,
            21, // 21 Days lock pool
            20,
            30
        );

        addStakePool(
            baseTokenAddress,
            28, // 28 Days lock pool
            20,
            40
        );
        
        apys[1][0] = 300; //APY based on rarity,locked days
        apys[1][7] = 360;
        apys[1][14] = 450;
        apys[1][21] = 600;
        apys[1][28] = 750;

        apys[2][0] = 450;
        apys[2][7] = 540;
        apys[2][14] = 675;
        apys[2][21] = 900;
        apys[2][28] = 1125;

        apys[3][0] = 900;
        apys[3][7] = 1080;
        apys[3][14] = 1350;
        apys[3][21] = 1800;
        apys[3][28] = 2250;

        apys[4][0] = 1500;
        apys[4][7] = 1800;
        apys[4][14] = 2250;
        apys[4][21] = 3000;
        apys[4][28] = 3750;
      
    }
    
    function updateNFTRarity(uint256 _tokenId, uint256 _rarity) public {
        nftRarities[_tokenId] = _rarity;
    }

    function updateBulkNFTRarity(uint256[] calldata _tokenIds, uint256[] calldata _rarities) external onlyOwner {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            nftRarities[_tokenIds[i]] = _rarities[i];
        }
    }

    function getRarityToApply() public view returns(uint256){
        uint256[] memory tokenIds = nftToken.walletOfOwner(msg.sender);
        uint256 temp_var;
       
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if(temp_var < nftRarities[tokenIds[i]]){
               temp_var = nftRarities[tokenIds[i]];
            }
        }
        return temp_var;
    }

    function getNFTs() public view returns(uint256[] memory) {
        uint256[] memory tokenIds = nftToken.walletOfOwner(msg.sender);
        return tokenIds;
    }

    function getHoldingNFTRarities() public view returns(uint256[4] memory) {
        uint256[] memory tokenIds = nftToken.walletOfOwner(msg.sender);

        uint256 legendary_count;
        uint256 rare_count;
        uint256 uncommon_count;
        uint256 common_count;
       
        for (uint256 i = 0; i < tokenIds.length; i++) {

            if(nftRarities[tokenIds[i]] == 4){
               legendary_count++;
            }else if(nftRarities[tokenIds[i]] == 3){
               rare_count++;
            }else if(nftRarities[tokenIds[i]] == 2){
               uncommon_count++;
            }else if(nftRarities[tokenIds[i]] == 1){
               common_count++;
            }
        }

        uint256[4] memory holdingNFTRarityCounts = [legendary_count,rare_count,uncommon_count,common_count];
        return (holdingNFTRarityCounts);
    }

    function addStakePool(address _tokenAddress, uint256 _duration, uint256 _withdrawalFee, uint256 _unstakePenalty ) public onlyOwner returns (bool){
        uint256 stakePoolId = block.timestamp;

        stakePoolList storage stakePoolListDetails = stakePoolLists[_tokenAddress];
        uint256[] memory stakePoolIds = stakePoolListDetails.poolIds;
        stakePoolId = stakePoolId + stakePoolIds.length;
        
        stakePoolListDetails.poolIds.push(stakePoolId);
        stakePoolLists[_tokenAddress] = stakePoolListDetails;

        stakePool memory stakePoolDetails;
        
        stakePoolDetails.id = stakePoolId;
        stakePoolDetails.tokenAddress = _tokenAddress;
        stakePoolDetails.duration = _duration;
        stakePoolDetails.withdrawalFee = _withdrawalFee;
        stakePoolDetails.unstakePenalty = _unstakePenalty;
        stakePoolDetails.creator = msg.sender;
        stakePoolDetails.createdTime = block.timestamp;
        
        stakePools[stakePoolId] = stakePoolDetails;
        stakePoolArray.push(stakePoolDetails);
        return true;
    }

    function setStakePoolStatus (uint256 _stakePoolId, uint256 _status) external onlyOwner returns (bool) {
        require((_status == 0 || _status == 1 || _status == 2 || _status == 3),"Invalid status");
        stakePool memory stakePoolDetails = stakePools[_stakePoolId];
        stakePoolDetails.status = _status;
        stakePools[_stakePoolId] = stakePoolDetails;
        return true;
    }

    function setStakePoolDuration (uint256 _stakePoolId, uint256 _duration) external onlyOwner returns (bool) {
        stakePool memory stakePoolDetails = stakePools[_stakePoolId];
        stakePoolDetails.duration = _duration;
        stakePools[_stakePoolId] = stakePoolDetails;
        return true;
    }

    function getAPY(uint256 _rarity, uint256 _lockDuration) public view returns (uint256){
        uint256 dpr = ((apys[_rarity][_lockDuration] * magnitude) / 360);
        return dpr;
    }

    function setStakePoolWithdrawalFee (uint256 _stakePoolId, uint256 _withdrawalFee) external onlyOwner returns (bool) {
        stakePool memory stakePoolDetails = stakePools[_stakePoolId];
        stakePoolDetails.withdrawalFee = _withdrawalFee;
        stakePools[_stakePoolId] = stakePoolDetails;
        return true;
    }

     function setStakeUnstakePoolPenalty (uint256 _stakePoolId, uint256 _unstakePenalty) external onlyOwner returns (bool) {
        stakePool memory stakePoolDetails = stakePools[_stakePoolId];
        stakePoolDetails.unstakePenalty = _unstakePenalty;
        stakePools[_stakePoolId] = stakePoolDetails;
        return true;
    }

    function getStakePoolIds(address _tokenAddress) public view returns(uint256[] memory){
        stakePoolList memory stakePoolListDetails = stakePoolLists[_tokenAddress];
        return stakePoolListDetails.poolIds;
    }

    function getStakePoolDetails(uint256 _stakePoolId) public view returns(address, address, uint256[] memory,string memory){
        stakePool memory stakePoolDetails = stakePools[_stakePoolId];
        uint [] memory stakePoolDetailsArray = new uint[](12);
        IERC20 token = IERC20(stakePoolDetails.tokenAddress);

        stakePoolDetailsArray[0] = stakePoolDetails.id;
        stakePoolDetailsArray[1] = stakePoolDetails.duration;
    	stakePoolDetailsArray[2] = 0;
        stakePoolDetailsArray[3] = 0;
    	stakePoolDetailsArray[4] = stakePoolDetails.withdrawalFee;
    	stakePoolDetailsArray[5] = stakePoolDetails.unstakePenalty;
        stakePoolDetailsArray[6] = stakePoolDetails.stakedTokens;
        stakePoolDetailsArray[7] = stakePoolDetails.claimedRewards;
        stakePoolDetailsArray[8] = 0;
        stakePoolDetailsArray[9] = 0;
        stakePoolDetailsArray[10] = stakePoolDetails.status;
        stakePoolDetailsArray[11] = stakePoolDetails.createdTime;
        
        return (stakePoolDetails.tokenAddress, stakePoolDetails.creator, stakePoolDetailsArray, token.name());
    }

    function updateLastClaimedTime(uint256 _stakeId, uint256 _newTimestamp) public {
        userStake memory userStakeDetails = userStakes[_stakeId];
        userStakeDetails.lastClaimedTime = _newTimestamp;

        userStakes[_stakeId] = userStakeDetails;
    }

    function getLastClaimedTime(uint256 _stakeId) public view returns(uint256){
        userStake memory userStakeDetails = userStakes[_stakeId];
        return userStakeDetails.lastClaimedTime;
    }

    function getElapsedTime(uint256 _stakeId) public view returns(uint256){
        userStake memory userStakeDetails = userStakes[_stakeId];
        uint256 lapsedDays = ((block.timestamp - userStakeDetails.lastClaimedTime)/3600)/24; //3600 seconds per hour so: lapsed days = lapsed time * (3600seconds /24hrs)
        return lapsedDays;
    }

    function getStakePoolTokenAddress(uint256 _stakePoolId) public view returns(address){
        stakePool memory stakePoolDetails = stakePools[_stakePoolId];
        return stakePoolDetails.tokenAddress;
    }

    function stake(uint256 _stakePoolId, uint256 _amount) unpaused external returns (bool){
        stakePool memory stakePoolDetails = stakePools[_stakePoolId];

        
        IERC20 token = IERC20(stakePoolDetails.tokenAddress);
        require(token.allowance(msg.sender, address(this)) >= _amount,'Tokens not approved for transfer');

        
        bool success = token.transferFrom(msg.sender, address(this), _amount);
        require(success, "Token Transfer failed.");
        

        userStake memory userStakeDetails;

        uint256 userStakeid = block.timestamp;
        userStakeDetails.id = userStakeid;
        userStakeDetails.stakePoolId = _stakePoolId;
        userStakeDetails.stakeBalance = _amount;
        userStakeDetails.tokenAddress = stakePoolDetails.tokenAddress;
        userStakeDetails.status = 1;
        userStakeDetails.owner = msg.sender;
        //userStakeDetails.lastClaimedTime = (block.timestamp - 1 days);
        userStakeDetails.createdTime = block.timestamp;
    
        userStakes[userStakeid] = userStakeDetails;
        
        userStakeList storage userStakeListDetails = userStakeLists[msg.sender];
        userStakeListDetails.stakeIds.push(userStakeid);
        userStakeLists[msg.sender] = userStakeListDetails;
        
        user memory userDetails = users[msg.sender];

        if(userDetails.id == 0){
            userDetails.id = block.timestamp;
            userDetails.createdTime = block.timestamp;
        }

        userDetails.totalStakedBalance = userDetails.totalStakedBalance + _amount;

        users[msg.sender] = userDetails;

        stakePoolDetails.stakedTokens = stakePoolDetails.stakedTokens + _amount;
        
        stakePools[_stakePoolId] = stakePoolDetails;

        totalStakedBalance = totalStakedBalance + _amount;

        return true;
    }

    function unstake(uint256 _stakeId) unpaused external returns (bool){
        userStake memory userStakeDetails = userStakes[_stakeId];
        uint256 stakePoolId = userStakeDetails.stakePoolId;
        uint256 createdTime = userStakeDetails.createdTime;
        uint256 stakeBalance = userStakeDetails.stakeBalance;
        
        require(userStakeDetails.owner == msg.sender,"You don't own this stake");
        IERC20 token = IERC20(userStakeDetails.tokenAddress);
        
        stakePool memory stakePoolDetails = stakePools[stakePoolId];

        uint256 duration = stakePoolDetails.duration;
        uint256 withdrawalFee = stakePoolDetails.withdrawalFee;
        uint256 unstakePenalty = stakePoolDetails.unstakePenalty;
        
        uint256 lapsedTime = (block.timestamp - createdTime)/3600;

        if(duration > 0 && lapsedTime < duration){
            stakeBalance = stakeBalance - (stakeBalance * unstakePenalty)/10000;
        }

        uint256 unstakableBalance = stakeBalance - (stakeBalance * withdrawalFee)/10000;

        userStakeDetails.stakeBalance = 0;
        userStakeDetails.status = 0;

        userStakes[_stakeId] = userStakeDetails;

        stakePoolDetails.stakedTokens = stakePoolDetails.stakedTokens - stakeBalance;

        userStakeDetails.lastClaimedTime = block.timestamp;
        userStakes[_stakeId] = userStakeDetails;

        bool success = token.transfer(msg.sender, unstakableBalance);
        require(success, "Token Transfer failed.");

        user memory userDetails = users[msg.sender];
        userDetails.totalStakedBalance =   userDetails.totalStakedBalance - unstakableBalance;

        users[msg.sender] = userDetails;
        stakePools[stakePoolId] = stakePoolDetails;

        totalStakedBalance =  totalStakedBalance - unstakableBalance;

        return true;
    }

    function getStakePoolIdByStakeId(uint256 _stakeId) public view returns(uint256){
        userStake memory userStakeDetails = userStakes[_stakeId];
        return userStakeDetails.stakePoolId;
    }

    function getUserStakeIds() public view returns(uint256[] memory){
        userStakeList memory userStakeListDetails = userStakeLists[msg.sender];
        return userStakeListDetails.stakeIds;
    }

    function getUserStakeIdsByAddress(address _userAddress) public view returns(uint256[] memory){
        userStakeList memory userStakeListDetails = userStakeLists[_userAddress];
        return userStakeListDetails.stakeIds;
    }

    function getUserStakeDetails(uint256 _stakeId) public view returns(uint256[] memory, uint256[] memory){
        userStake memory userStakeDetails = userStakes[_stakeId];
        
        uint [] memory userStakeDetailsArray = new uint[](9);
        
        userStakeDetailsArray[0] = userStakeDetails.id;
        
        userStakeDetailsArray[1] = userStakeDetails.stakePoolId;
    	userStakeDetailsArray[2] = userStakeDetails.stakeBalance;
    	userStakeDetailsArray[3] = userStakeDetails.totalClaimedRewards;
    	userStakeDetailsArray[4] = 0;
        userStakeDetailsArray[5] = getUnclaimedRewards(userStakeDetails.id);   
    	userStakeDetailsArray[6] = userStakeDetails.lastClaimedTime;
        userStakeDetailsArray[7] = userStakeDetails.status;
        userStakeDetailsArray[8] = userStakeDetails.createdTime;
        
        (, , uint256[] memory stakePoolDetailsArray, ) = getStakePoolDetails(userStakeDetails.stakePoolId);
        return (userStakeDetailsArray, stakePoolDetailsArray);
    }

    function getUserStakeOwner(uint256 _stakeId) public view returns (address){
        userStake memory userStakeDetails = userStakes[_stakeId];
        return userStakeDetails.owner;
    }

    function getUserStakeBalance(uint256 _stakeId) public view returns (uint256){
        userStake memory userStakeDetails = userStakes[_stakeId];
        return userStakeDetails.stakeBalance;
    }
    
    function getUnclaimedRewards(uint256 _stakeId) public view returns (uint256){
        userStake memory userStakeDetails = userStakes[_stakeId];
        uint256 stakePoolId = userStakeDetails.stakePoolId;

        stakePool memory stakePoolDetails = stakePools[stakePoolId];
        uint256 stakeApr = getAPY(getRarityToApply(), stakePoolDetails.duration);

        uint256 lapsedDays = ((block.timestamp - userStakeDetails.lastClaimedTime)/3600)/24; //3600 seconds per hour so: lapsed days = lapsed time * (3600seconds /24hrs)
        uint applicableRewards = (userStakeDetails.stakeBalance * stakeApr)/(magnitude * 100); //divided by 10000 to handle decimal percentages like 0.1%
        uint unclaimedRewards = applicableRewards * lapsedDays;

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

    
    function getAllPoolDetails() public view returns(stakePool[] memory){
        return stakePoolArray;
    }
    

    function getFlexyPoolDetails (address _tokenAddress) external view returns (uint256[] memory) {
        uint256[] memory stakePoolIds = getStakePoolIds(_tokenAddress);
        uint256[] memory stakePoolDetails;

        uint256 flexyPoolId = stakePoolIds[0];
        uint256 totalFlexyPoolStakedBalance;
        uint256 totalFlexyPoolClaimedLockedRewards;
        uint256 totalFlexyPoolsClaimedUnlockedRewards;
        uint256 totalFlexyPoolWeight;
        uint256 totalFlexyPoolAPR;

        (, , stakePoolDetails,) = getStakePoolDetails(flexyPoolId);

        totalFlexyPoolStakedBalance = stakePoolDetails[6] + totalFlexyPoolStakedBalance;
        totalFlexyPoolClaimedLockedRewards = stakePoolDetails[7] + totalFlexyPoolClaimedLockedRewards;
        totalFlexyPoolsClaimedUnlockedRewards = stakePoolDetails[8] + totalFlexyPoolsClaimedUnlockedRewards;
        totalFlexyPoolWeight = stakePoolDetails[2] + totalFlexyPoolWeight;
        totalFlexyPoolAPR = stakePoolDetails[3] + totalFlexyPoolAPR;
        
        uint [] memory FlexyPoolDetailsArray = new uint[](5);
        
        FlexyPoolDetailsArray[0] = totalFlexyPoolStakedBalance;
        FlexyPoolDetailsArray[1] = totalFlexyPoolClaimedLockedRewards;
    	FlexyPoolDetailsArray[2] = totalFlexyPoolsClaimedUnlockedRewards;
    	FlexyPoolDetailsArray[3] = totalFlexyPoolWeight;
    	FlexyPoolDetailsArray[4] = totalFlexyPoolAPR;


        return (FlexyPoolDetailsArray);
    }

    function getLockedPoolsDetails (address _tokenAddress) external view returns (uint256[] memory) {
        uint256[] memory stakePoolIds = getStakePoolIds(_tokenAddress);
        uint256[] memory stakePoolDetails;
        uint256 totalLockedPoolsStakedBalance;
        uint256 totalLockedPoolsClaimedLockedRewards;
        uint256 totalLockedPoolsClaimedUnlockedRewards;
        uint256 totalLockedPoolWeight;
        uint256 totalLockedPoolAPR;

        for(uint i = 1; i < stakePoolIds.length; i++){
            (, , stakePoolDetails,) = getStakePoolDetails( stakePoolIds[i]);
            totalLockedPoolsStakedBalance = stakePoolDetails[6] + totalLockedPoolsStakedBalance;
            totalLockedPoolsClaimedLockedRewards = stakePoolDetails[7] + totalLockedPoolsClaimedLockedRewards;
            totalLockedPoolsClaimedUnlockedRewards = stakePoolDetails[8] + totalLockedPoolsClaimedUnlockedRewards;
            totalLockedPoolWeight = stakePoolDetails[2] + totalLockedPoolWeight;
            totalLockedPoolAPR = stakePoolDetails[3] + totalLockedPoolAPR;
        }
       
        uint [] memory lockedPoolsDetailsArray = new uint[](5);
        
        lockedPoolsDetailsArray[0] = totalLockedPoolsStakedBalance;
        lockedPoolsDetailsArray[1] = totalLockedPoolsClaimedLockedRewards;
    	lockedPoolsDetailsArray[2] = totalLockedPoolsClaimedUnlockedRewards;
    	lockedPoolsDetailsArray[3] = totalLockedPoolWeight;
    	lockedPoolsDetailsArray[4] = totalLockedPoolAPR;


        return (lockedPoolsDetailsArray);
    }

    function claimRewards(uint256 _stakeId) unpaused external returns (bool){
        address userStakeOwner = getUserStakeOwner(_stakeId);
        require(userStakeOwner == msg.sender,"You don't own this stake");

        userStake memory userStakeDetails = userStakes[_stakeId];
        require(((block.timestamp - userStakeDetails.lastClaimedTime)/3600) > 24,"You already claimed rewards today");
        
        uint256 unclaimedRewards = getUnclaimedRewards(_stakeId);
        
        userStakeDetails.totalClaimedRewards = userStakeDetails.totalClaimedRewards + unclaimedRewards;
        userStakeDetails.lastClaimedTime = block.timestamp;
        userStakes[_stakeId] = userStakeDetails;

        IERC20 token = IERC20(userStakeDetails.tokenAddress);

        bool success = token.transfer(msg.sender, unclaimedRewards);
        require(success, "Token Transfer failed.");

        return true;
    }

    function getUserDetails() external view returns (uint256[] memory){
        user memory userDetails = users[msg.sender];

        uint256 [] memory userDetailsArray = new uint256[](5);
        
        userDetailsArray[0] = userDetails.id;
        userDetailsArray[1] = userDetails.totalStakedBalance;
    	userDetailsArray[2] = userDetails.totalClaimedRewards;
    	userDetailsArray[3] = 0;
    	userDetailsArray[4] = userDetails.createdTime;
        
        return(userDetailsArray);
    }

    function getUserDetailsByAddress(address _address) external view returns (uint256[] memory){
        user memory userDetails = users[_address];

        uint256 [] memory userDetailsArray = new uint256[](5);
        
        userDetailsArray[0] = userDetails.id;
        userDetailsArray[1] = userDetails.totalStakedBalance;
    	userDetailsArray[2] = userDetails.totalClaimedRewards;
    	userDetailsArray[3] = 0;
    	userDetailsArray[4] = userDetails.createdTime;
        
        return(userDetailsArray);
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

    function withdrawContractTokens() public onlyOwner returns(bool){
        IERC20 token = IERC20(baseTokenAddress);

        bool success = token.transfer(msg.sender, token.balanceOf(msg.sender));
        require(success, "Token Transfer failed.");

        return true;
    }

    receive() external payable {
    }
}