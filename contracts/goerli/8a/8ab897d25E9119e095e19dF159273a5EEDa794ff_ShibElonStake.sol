/**
 *Submitted for verification at Etherscan.io on 2023-01-20
*/

// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

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

// File: contracts/ShibElon/ShibElonMaster.sol


// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
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


interface IERC721 {
    function balanceOf(address owner) external view returns (uint256 balance);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function getTokenIds(address _owner) external view returns (uint256[] memory);
    function getApproved(uint256 tokenId) external view returns (address operator);
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

interface ERC721TokenReceiver
{
  function onERC721Received(address, address, uint256, bytes calldata) external returns(bytes4);
}
contract ShibElonStake is IERC721Receiver, Ownable, ReentrancyGuard{
    
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4){
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
        uint256 withdrawalFee;
        uint256 unstakeFee;
        uint256 earlyUnstakePenalty;
        uint256 stakedTokens;
        uint256 claimedRewards;
        uint256 status; //1: created, 2: active, 3: cancelled
        uint256 createdTime;
    }

    stakePool[] public stakePoolArray;

    struct userStake{
        uint256 id;
        uint256 nftTokenId;
        uint256 stakePoolId;
	    uint256 stakeBalance;
    	uint256 totalClaimedRewards;
    	uint256 lastClaimedTime;
        uint256 status; //0 : Unstaked, 1 : Staked
        address owner;
    	uint256 createdTime;
        uint256 lockedTime;
        uint256 unlockTime;
        uint256 lockDuration;
    }

    userStake[] public userStakeArray;

    ERC721TokenReceiver erc721Receiver = ERC721TokenReceiver(address(this));

    mapping (uint256 => stakePool) public stakePoolsById;
    mapping (uint256 => userStake) public userStakesById;

    mapping (address => uint256[]) public userStakeIds;
    mapping (address => userStake[]) public userStakeLists;

    mapping (address => user) public users;

    mapping (uint256 => mapping(uint256 => uint256)) public apys;
    mapping (uint256 => uint256) public nftRarities;

    uint256 public maxStakableTokensPerNFT = 50*10**9;

    uint256 public totalInjectedRewardsSupply;
    uint256 public totalStakedBalance;
    uint256 public totalClaimedBalance;
  
    uint256 public magnitude = 100000000;

    uint256 public userIndex;
    uint256 public poolIndex;
    uint256 public stakeIndex;

    bool public isPaused;

    address nftTokenAddress = 0xbd8cB0CE8D65fC25c4Da90dCc3B543425Cd998D8;

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

    uint256[] _durationArray = [7,15,30,365];
    //uint256[] _withdrawalFeeArray = [0,0,0,0];
    uint256[] _unstakePenaltyArray = [80,80,80,80];
    
    
    constructor(address _stakeToken, address _rewardToken, address _owner) {
        address _baseTokenAddress = _stakeToken; 
        address _rewardTokensAddress = _rewardToken;

        baseTokenAddress = _baseTokenAddress;
        rewardTokensAddress = _rewardTokensAddress;
        
        stakeToken = IERC20(baseTokenAddress);
        rewardToken = IERC20(rewardTokensAddress);

        for(uint256 i = 0; i < _durationArray.length; i++){
            addStakePool(
                _durationArray[i], // Duration in days
                _unstakePenaltyArray[i] // Early unstake penalty
            );
        }

        transferOwnership(_owner);
    }
    
    function addStakePool(uint256 _duration, uint256 _unstakePenalty) public onlyOwner returns (bool){

        stakePool memory stakePoolDetails;
        
        stakePoolDetails.id = poolIndex;
        stakePoolDetails.duration = _duration;
        stakePoolDetails.earlyUnstakePenalty = _unstakePenalty;
        
        stakePoolDetails.createdTime = block.timestamp;
       
        stakePoolArray.push(stakePoolDetails);
        stakePoolsById[poolIndex++] = stakePoolDetails;

        return true;
    }

    function setAPYs( uint256[] calldata _APY1, uint256[] calldata _APY2, uint256[] calldata _APY3, uint256[] calldata _APY4, uint256[] calldata _APY5) external onlyOwner {
        apys[1][7] = _APY1[0]; //APY based on rarity,locked days
        apys[1][15] = _APY1[1]; 
        apys[1][30] = _APY1[2];
        apys[1][365] = _APY1[3];
        
        apys[2][7] = _APY2[0]; //APY based on rarity,locked days
        apys[2][15] = _APY2[1]; 
        apys[2][30] = _APY2[2];
        apys[2][365] = _APY2[3];

        apys[3][7] = _APY3[0]; //APY based on rarity,locked days
        apys[3][15] = _APY3[1]; 
        apys[3][30] = _APY3[2];
        apys[3][365] = _APY3[3];

        apys[4][7] = _APY4[0]; //APY based on rarity,locked days
        apys[4][15] = _APY4[1]; 
        apys[4][30] = _APY4[2];
        apys[4][365] = _APY4[3];

        apys[4][7] = _APY5[0]; //APY based on rarity,locked days
        apys[4][15] = _APY5[1]; 
        apys[4][30] = _APY5[2];
        apys[4][365] = _APY5[3];
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
        uint256[] memory tokenIds = nftToken.getTokenIds(msg.sender);
        uint256 temp_var;
       
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if(temp_var < nftRarities[tokenIds[i]]){
               temp_var = nftRarities[tokenIds[i]];
            }
        }
        return temp_var;
    }

    function getNFTs() public view returns(uint256[] memory) {
        uint256[] memory tokenIds = nftToken.getTokenIds(msg.sender);
        return tokenIds;
    }

    function getMaxStakableTokens() public view returns(uint256) {
        return (maxStakableTokensPerNFT * nftToken.getTokenIds(msg.sender).length);
    }

    function getHoldingNFTRarities() public view returns(uint256, uint256[5] memory) {
        uint256[] memory tokenIds = nftToken.getTokenIds(msg.sender);
        uint256 golden_santa_count;
        uint256 legendary_count;
        uint256 rare_count;
        uint256 uncommon_count;
        uint256 common_count;
        uint256 high_rarity_nft;
        
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if(nftRarities[tokenIds[i]] == 5){
               if(high_rarity_nft == 0){
                   high_rarity_nft = tokenIds[i];
               }
               golden_santa_count++;
            }
            if(nftRarities[tokenIds[i]] == 4){
               if(high_rarity_nft == 0){
                   high_rarity_nft = tokenIds[i];
               }
               legendary_count++;
            }else if(nftRarities[tokenIds[i]] == 3){
                if(high_rarity_nft == 0){
                   high_rarity_nft = tokenIds[i];
               }
               rare_count++;
            }else if(nftRarities[tokenIds[i]] == 2){
                if(high_rarity_nft == 0){
                   high_rarity_nft = tokenIds[i];
               }
               uncommon_count++;
            }else if(nftRarities[tokenIds[i]] == 1){
                if(high_rarity_nft == 0){
                   high_rarity_nft = tokenIds[i];
               }
               common_count++;
            }
        }

        uint256[5] memory holdingNFTRarityCounts = [golden_santa_count,legendary_count,rare_count,uncommon_count,common_count];
        return (high_rarity_nft,holdingNFTRarityCounts);
    }

    function getAPY(uint256 _rarity, uint256 _lockDuration) public view returns (uint256){
        return apys[_rarity][_lockDuration];
    }

    
    function getDPR(uint256 _rarity, uint256 _lockDuration) public view returns (uint256){
        uint256 apy = getAPY(_rarity,_lockDuration);
        uint256 dpr = (apy * magnitude) / 365;
        return dpr;
    }

    function getStakePoolDetailsById(uint256 _stakePoolId) public view returns(stakePool memory){
        return (stakePoolArray[_stakePoolId]);
    }

    function stake(uint256 _stakePoolId, uint256 _nftTokenInd, uint256 _amount) unpaused external returns (bool) {
        stakePool memory stakePoolDetails = stakePoolsById[_stakePoolId];

        require(_amount <= getMaxStakableTokens(),"You need more NFTs to stake this amount");
        require(stakeToken.allowance(msg.sender, address(this)) >= _amount,"Tokens not approved for transfer");
        require(nftToken.ownerOf(_nftTokenInd) == msg.sender,"You don't own the NFT");
        require(nftToken.getApproved(_nftTokenInd) == address(this),"NFT not approved to stake");

        nftToken.safeTransferFrom(msg.sender,address(this),_nftTokenInd);
        //bytes4 retval = erc721Receiver.onERC721Received(address(this), msg.sender, _nftTokenInd, data);

        bool success = stakeToken.transferFrom(msg.sender, address(this), _amount);
        require(success, "Token Transfer failed.");

        userStake memory userStakeDetails;

        uint256 userStakeid = stakeIndex++;
        userStakeDetails.id = userStakeid;
        userStakeDetails.nftTokenId = _nftTokenInd;
        userStakeDetails.stakePoolId = _stakePoolId;
        userStakeDetails.stakeBalance = _amount;
        userStakeDetails.status = 1;
        userStakeDetails.owner = msg.sender;
        userStakeDetails.createdTime = block.timestamp;
        userStakeDetails.unlockTime = block.timestamp + (stakePoolDetails.duration * 1 days);
        userStakeDetails.lockDuration = stakePoolDetails.duration;
        userStakeDetails.lockedTime = block.timestamp;
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

   /*
    function restake(uint256 _stakeId) nonReentrant unpaused external returns (bool){
        userStake memory userStakeDetails = userStakesById[_stakeId];
      
        require(userStakeDetails.owner == msg.sender,"You don't own this stake");
        require(userStakeDetails.status == 1,"You have already unstaked");

        userStakeDetails.lockedTime = block.timestamp;
        userStakeDetails.unlockTime = userStakeDetails.lockDuration * 1 days;

        userStakesById[_stakeId] = userStakeDetails;
        updateStakeArray(_stakeId);

        return true; 
    }
    */

    function unstake(uint256 _stakeId) nonReentrant external returns (bool){
        userStake memory userStakeDetails = userStakesById[_stakeId];
        uint256 stakePoolId = userStakeDetails.stakePoolId;
        uint256 stakeBalance = userStakeDetails.stakeBalance;
        
        require(userStakeDetails.owner == msg.sender,"You don't own this stake");
        require(userStakeDetails.status == 1,"You have already unstaked");
        
        stakePool memory stakePoolDetails = stakePoolsById[stakePoolId];

        uint256 unstakableBalance;
  
        uint256 claimableRewards;
        uint256 earlyUnstakePenaltyAmount;

        if(isStakeLocked(_stakeId) && isPaused == false){
            claimableRewards = getUnclaimedRewards(_stakeId);
            earlyUnstakePenaltyAmount = (claimableRewards * stakePoolDetails.earlyUnstakePenalty)/100;
          
            unstakableBalance = stakeBalance + (claimableRewards - earlyUnstakePenaltyAmount);
           
        }else{
            unstakableBalance = stakeBalance;
        }

        userStakeDetails.status = 0;

        userStakesById[_stakeId] = userStakeDetails;

        stakePoolDetails.stakedTokens = stakePoolDetails.stakedTokens - stakeBalance;

        uint256 nftTokenId = userStakeDetails.nftTokenId;

        userStakesById[_stakeId] = userStakeDetails;

        user memory userDetails = users[msg.sender];
        userDetails.totalStakedBalance =   userDetails.totalStakedBalance - stakeBalance;

        users[msg.sender] = userDetails;

        stakePoolsById[stakePoolId] = stakePoolDetails;

        updateStakeArray(_stakeId);

        totalStakedBalance =  totalStakedBalance - stakeBalance;

        require(stakeToken.balanceOf(address(this)) >= unstakableBalance, "Insufficient contract token balance");
        
        bool success;

        success = stakeToken.transfer(msg.sender, unstakableBalance);
        require(success, "Token Transfer failed.");

        success = false;

        if(earlyUnstakePenaltyAmount > 0 && stakeToken.balanceOf(address(this)) > 0){
            success = rewardToken.transfer(owner(), earlyUnstakePenaltyAmount);
            require(success, "Token Transfer failed.");

            nftToken.safeTransferFrom(address(this),msg.sender,nftTokenId);
        }

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
        uint256 stakeApr = getDPR(getRarityToApply(), stakePoolDetails.duration);

        uint applicableRewards = (userStakeDetails.stakeBalance * stakeApr)/(magnitude * 100); //divided by 10000 to handle decimal percentages like 0.1%
        uint unclaimedRewards = (applicableRewards * getElapsedTime(_stakeId));

        return unclaimedRewards; 
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
    /*
    function getUserDetails(address _userAddress) external view returns (user memory){
        user memory userDetails = users[_userAddress];
        return(userDetails);
    }
    */
    function pauseStake(bool _pauseStatus) public onlyOwner(){
        isPaused = _pauseStatus;
    }
    
    function setMaxStakableTokensPerNFT(uint256 _maxStakableTokensPerNFT) public onlyOwner{
        maxStakableTokensPerNFT = _maxStakableTokensPerNFT;
    }

    function injectRewardsSupply(uint256 _amount) public {
        require(rewardToken.allowance(msg.sender, address(this)) >= _amount,'Tokens not approved for transfer');
        
        bool success = rewardToken.transferFrom(msg.sender, address(this), _amount);
        require(success, "Token Transfer failed.");
        totalInjectedRewardsSupply += _amount;
    }

    function withdrawInjectedRewardSupply(uint256 _amount) public onlyOwner paused returns(bool){
        bool success;
        
        require(_amount <= totalInjectedRewardsSupply,"Can not withdraw more than injected supply");
        success = rewardToken.transfer(msg.sender, _amount);
        require(success, "Token Transfer failed.");

        totalInjectedRewardsSupply -= _amount;
        return true;
    }
}