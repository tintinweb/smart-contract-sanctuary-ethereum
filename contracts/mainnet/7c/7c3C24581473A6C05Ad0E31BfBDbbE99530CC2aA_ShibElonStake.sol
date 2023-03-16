/**
 *Submitted for verification at Etherscan.io on 2023-03-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

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


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

pragma solidity ^0.8.15;

interface IERC20 {
    function decimals() external view returns (uint8);
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

interface IERC721 {
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function getTokenIds(address _owner) external view returns (uint256[] memory);
    function getApproved(uint256 tokenId) external view returns (address operator);
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

interface ShibElonStakeMasterInterface{
    function addUserStake(address _stakeAddress, address _userAddress, uint256[] memory _tokenIds, uint256 _stakeId) external;
    function nftRarities(uint256 _tokenId) external view returns (uint256);
    function owner() external view returns(address); 
}

interface ERC721TokenReceiver
{
  function onERC721Received(address, address, uint256, bytes calldata) external returns(bytes4);
}

contract ShibElonStake is IERC721Receiver, Ownable {
    ERC721TokenReceiver erc721Receiver = ERC721TokenReceiver(address(this));
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external pure returns (bytes4){
        (operator);
        (from);
        (tokenId);
        (data);
        return this.onERC721Received.selector;
    }

    struct user{
        uint256 id;
        uint256 totalStakedBalance;
        uint256 totalClaimedRewards;
        uint256 createdTime;
    }

    struct stakePool{
        uint256 id;
        uint256 duration;
        uint256 stakedTokens;
        uint256 claimedRewards;
    }

    stakePool[] public stakePoolArray;

    struct userStake{
        uint256 id;
        uint256 stakePoolId;
        uint256 stakeBalance;
        uint256 totalClaimedRewards;
        uint256 lastClaimedTime;
        uint256 status; //0 : Unstaked, 1 : Staked
        address owner;
        uint256 lockedTime;
        uint256 unlockTime;
        uint256 lockDuration;
    }

    userStake[] public userStakeArray;

    mapping (uint256 => stakePool) public stakePoolsById;
    mapping (uint256 => userStake) public userStakesById;
    mapping (address => uint256[]) public userStakeIds;
    mapping (address => userStake[]) public userStakeLists;
    mapping (address => user) public users;
    mapping (uint256 => mapping(uint256 => uint256)) public apys;
    mapping(uint256 => uint256[]) public stakedNFTs;

    uint256 public maxStakableTokensPerNFT;

    uint256 public totalInjectedRewardsSupply;
    uint256 public totalStakedBalance;
    uint256 public totalClaimedBalance;
  
    uint256 public magnitude = 100000000;

    uint256 public userIndex;
    uint256 public poolIndex;
    uint256 public stakeIndex;

    bool public isPaused;
 
    address public ShibElonStakeMasterAddress;
    ShibElonStakeMasterInterface stakeMaster;

    address public nftTokenAddress = 0xcD9404cf5A67994012BC7BD306b8de91bdD785D4;
    
    IERC721 nftToken = IERC721(nftTokenAddress);

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

    uint256[] public stakeDurations;
   
    constructor(address _masterStake, address _stakeToken, address _rewardToken, uint256[] memory _durationArray) {
        ShibElonStakeMasterAddress = _masterStake;
        stakeMaster = ShibElonStakeMasterInterface(ShibElonStakeMasterAddress);

        stakeDurations = _durationArray;

        address _baseTokenAddress = _stakeToken; 
        address _rewardTokensAddress = _rewardToken;

        baseTokenAddress = _baseTokenAddress;
        rewardTokensAddress = _rewardTokensAddress;
        
        stakeToken = IERC20(baseTokenAddress);
        rewardToken = IERC20(rewardTokensAddress);

        maxStakableTokensPerNFT = 50*10**stakeToken.decimals();
        
        for(uint256 i = 0; i < _durationArray.length; i++){
            addStakePool(
                _durationArray[i] // Duration in days
            );
        }
        
        transferOwnership(stakeMaster.owner());
    }
    
    function addStakePool(uint256 _duration) public onlyOwner {
        stakePool memory stakePoolDetails;
        stakePoolDetails.id = poolIndex;
        stakePoolDetails.duration = _duration;
        stakePoolArray.push(stakePoolDetails);
        stakePoolsById[poolIndex++] = stakePoolDetails;
    }

    function setAPYs(uint256 _duration, uint256[] memory _APYArray) public onlyOwner {
        apys[1][_duration] = _APYArray[0]; //APY based on rarity,locked days
        apys[2][_duration] = _APYArray[1]; 
        apys[3][_duration] = _APYArray[2];
        apys[4][_duration] = _APYArray[3];
        apys[5][_duration] = _APYArray[4];
    }
    
    function getMaxStakableTokens(address _userAddress) public view returns(uint256) {
        return (maxStakableTokensPerNFT * nftToken.getTokenIds(_userAddress).length);
    }

    function getAPY(uint256 _rarity, uint256 _lockDuration) public view returns (uint256){
        return apys[_rarity][_lockDuration];
    }

    function getAllAPYs(uint256 _rarity) public view returns (uint256[] memory) {
        uint256[] memory APY_array = new uint[](stakeDurations.length);
        for(uint256 i=0; i < stakeDurations.length; i++){
            APY_array[i] = getAPY(_rarity, stakeDurations[i]);
        }
        return(APY_array);
    }

    function getMaxRarity(uint256[] memory nftTokenIds) public view returns(uint){
       
        uint maxRarity = 0;
        uint i;
        
        for(i=0; i < nftTokenIds.length; i++){
           if(maxRarity < stakeMaster.nftRarities(nftTokenIds[i])){
               maxRarity = stakeMaster.nftRarities(nftTokenIds[i]);
           }
        }
        return maxRarity;
    }

    function stake(uint256 _stakePoolId, uint256[] memory _nftTokenIds, uint256 _amount) unpaused external returns (bool) {
        stakePool memory stakePoolDetails = stakePoolsById[_stakePoolId];

        require(_amount <= getMaxStakableTokens(msg.sender),"You need more NFTs to stake this amount");
        require(stakeToken.allowance(msg.sender, address(this)) >= _amount,"Tokens not approved for transfer");
        
        for(uint256 i = 0; i < _nftTokenIds.length; i++){
            require(nftToken.ownerOf(_nftTokenIds[i]) == msg.sender,"You don't own the NFT");
            require(nftToken.getApproved(_nftTokenIds[i]) == address(this),"NFT not approved to stake");
            nftToken.safeTransferFrom(msg.sender,address(this),_nftTokenIds[i]);
            
        }
      
        bool success = stakeToken.transferFrom(msg.sender, address(this), _amount);
        require(success, "Token Transfer failed.");

        userStake memory userStakeDetails;

        uint256 userStakeid = stakeIndex++;
        userStakeDetails.id = userStakeid;
        userStakeDetails.stakePoolId = _stakePoolId;
        userStakeDetails.stakeBalance = _amount;
        userStakeDetails.status = 1;
        userStakeDetails.owner = msg.sender;
        userStakeDetails.unlockTime = block.timestamp + (stakePoolDetails.duration * 1 days);
        userStakeDetails.lockDuration = stakePoolDetails.duration;
        userStakeDetails.lockedTime = block.timestamp;
        userStakesById[userStakeid] = userStakeDetails;
    
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

        stakedNFTs[userStakeid] = _nftTokenIds;

        stakeMaster.addUserStake(ShibElonStakeMasterAddress, msg.sender, _nftTokenIds, userStakeid);
        return true;
    }

    function unstake(uint256 _stakeId) external {
        userStake memory userStakeDetails = userStakesById[_stakeId];
        uint256 stakePoolId = userStakeDetails.stakePoolId;
        uint256 stakeBalance = userStakeDetails.stakeBalance;
        
        require(userStakeDetails.owner == msg.sender,"You don't own this stake");
        require(userStakeDetails.status == 1,"You have already unstaked");
        
        stakePool memory stakePoolDetails = stakePoolsById[stakePoolId];

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

        require(stakeToken.balanceOf(address(this)) >= stakeBalance, "Insufficient contract token balance");
        
        bool success = stakeToken.transfer(msg.sender, stakeBalance);
        require(success, "Token Transfer failed.");

        for(uint256 i = 0; i < stakedNFTs[_stakeId].length; i++){
            nftToken.safeTransferFrom(address(this),msg.sender,stakedNFTs[_stakeId][i]);
        }
    }

    function isStakeLocked(uint256 _stakeId) public view returns (bool) {
        userStake memory userStakeDetails = userStakesById[_stakeId];
        if(block.timestamp < userStakeDetails.unlockTime){
            return true;
        }else{
            return false;
        }
    }
   function getStakedNFTs(uint256 _stakeId) public view returns (uint256[] memory) {
       return(stakedNFTs[_stakeId]);
       
    }
    function getStakePoolIdByStakeId(uint256 _stakeId) public view returns(uint256){
        userStake memory userStakeDetails = userStakesById[_stakeId];
        return userStakeDetails.stakePoolId;
    }

    function getUserStakeIdsByAddress(address _userAddress) public view returns(uint256[] memory){
         return(userStakeIds[_userAddress]);
    }

    function getUserAllStakeDetailsByAddress(address _userAddress) public view returns(userStake[] memory){
        return (userStakeLists[_userAddress]);
    }

    function getUserStakeOwner(uint256 _stakeId) public view returns (address){
        return userStakesById[_stakeId].owner;
    }
    
    function isClaimable() public view returns (bool) {
        if(totalStakedBalance <= (stakeToken.balanceOf(address(this)))){
            return true;
        }else{
            return false;
        }
    }

    function getUnclaimedRewards(uint256 _stakeId) public view returns (uint256){
        userStake memory userStakeDetails = userStakeArray[_stakeId];
        uint256 stakePoolId = userStakeDetails.stakePoolId;

        stakePool memory stakePoolDetails = stakePoolsById[stakePoolId];

        uint256 maxRarity = getMaxRarity(stakedNFTs[_stakeId]);

        uint256 stakeApr = (getAPY(maxRarity, stakePoolDetails.duration) * magnitude) / 365;

        uint applicableRewards = (userStakeDetails.stakeBalance * stakeApr)/(magnitude * 100); //divided by 10000 to handle decimal percentages like 0.1%
        uint256 unclaimedRewards = applicableRewards * getElapsedTime(_stakeId);
        
        unclaimedRewards = adjustDecimals(unclaimedRewards);
        return (unclaimedRewards); 
    }

    function getElapsedTime(uint256 _stakeId) public view returns(uint256){
        userStake memory userStakeDetails = userStakesById[_stakeId];
        uint256 lapsedDays;

        if(block.timestamp > userStakeDetails.unlockTime){  
            lapsedDays = userStakeDetails.lockDuration;
        } else{
            lapsedDays = ((block.timestamp - userStakeDetails.lockedTime)/3600)/24; //3600 seconds per hour so: lapsed days = lapsed time * (3600seconds /24hrs)
        }
        return lapsedDays;  
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

        totalUnclaimedRewards = adjustDecimals(totalUnclaimedRewards);

        return totalUnclaimedRewards;
    }

    
    function getAllPoolDetails() public view returns(stakePool[] memory){
        return (stakePoolArray);
    }

    function claimRewards(uint256 _stakeId) unpaused public returns (bool){
        require(isClaimable() == true,"Claiming is not possible contract balnce too low!");
        require(userStakesById[_stakeId].owner == msg.sender,"You don't own this stake");

        userStake memory userStakeDetails = userStakesById[_stakeId];
        uint256 stakePoolId = userStakeDetails.stakePoolId;

        require(userStakeDetails.status == 1, "You can not claim after unstaked");
        require(isStakeLocked(_stakeId) == false,"You can not withdraw");
        
        stakePool memory stakePoolDetails = stakePoolsById[stakePoolId];

        uint256 unclaimedRewards = getUnclaimedRewards(_stakeId);
        
        userStakeDetails.totalClaimedRewards = userStakeDetails.totalClaimedRewards + unclaimedRewards;
        userStakeDetails.lastClaimedTime = block.timestamp;
        userStakeDetails.lockedTime = block.timestamp;

        userStakeDetails.unlockTime = userStakeDetails.lockedTime + (stakePoolDetails.duration * 1 days);
        
        userStakesById[_stakeId] = userStakeDetails;
        updateStakeArray(_stakeId);

        totalClaimedBalance += unclaimedRewards;

        user memory userDetails = users[msg.sender];
        userDetails.totalClaimedRewards  +=  unclaimedRewards;

        users[msg.sender] = userDetails;

        require(rewardToken.balanceOf(address(this)) >= unclaimedRewards, "Insufficient contract reward token balance");

        bool success = rewardToken.transfer(msg.sender, unclaimedRewards);
        require(success, "Token Transfer failed.");

        return true;
    }

    function adjustDecimals(uint256 _amount) public view returns(uint256){
        if(rewardToken.decimals() < stakeToken.decimals()){
            _amount = _amount / (10**(stakeToken.decimals() - rewardToken.decimals()));
        }else if(rewardToken.decimals() > stakeToken.decimals()){
            _amount = _amount * (10**(rewardToken.decimals() - stakeToken.decimals()));
        }
        return _amount;
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
   
    function pauseStake(bool _pauseStatus) public onlyOwner(){
        isPaused = _pauseStatus;
    }
    
    function setMaxStakableTokensPerNFT(uint256 _maxStakableTokensPerNFT) public onlyOwner{
        maxStakableTokensPerNFT = _maxStakableTokensPerNFT*10**stakeToken.decimals();
    }

    function injectRewardsSupply(uint256 _amount) public  {
        require(rewardToken.allowance(msg.sender, address(this)) >= _amount,"Tokens not approved for transfer");
        bool success = rewardToken.transferFrom(msg.sender, address(this), _amount);
        require(success, "Token Transfer failed.");
        totalInjectedRewardsSupply += _amount;
    }

    function withdrawInjectedRewardSupply(uint256 _amount) public onlyOwner paused returns(bool){
        require(_amount <= totalInjectedRewardsSupply,"Can not withdraw more than injected supply");
        bool success = rewardToken.transfer(msg.sender, _amount);
        require(success, "Token Transfer failed.");
        totalInjectedRewardsSupply -= _amount;
        return true;
    }
}