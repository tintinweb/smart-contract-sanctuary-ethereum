// SPDX-License-Identifier: MIT
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


pragma solidity ^0.8.7;

/* Rinkeby Test address*/
// WP_contract_address 0x51468C1D027c772A6F5BEc71CAC1aC52512E183D
// Stake_contract_address 0x1360d95a53C835F4603cd6458860289717C58780
// Gift_contract_address 0xB310A4f6bDA500f8040575F624354ea439c13D00
// ["1660657334","1662657334"]

interface WPInterFace {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom( 
        address from,
        address to,
        uint256 tokenId
    ) external;
    function totalMinted() external view returns (uint256);
    function balanceOf(address owner) external view returns (uint256 balance);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

contract Stake is Ownable, ReentrancyGuard {    
    event Staked(address indexed owner, uint256 tokenID);
    event Reclaimed(address indexed owner, uint256 tokenID);
    event StakeInterrupted(uint256 indexed tokenId);
    event Withdraw(address indexed account, uint256 amount);
    event stakeTimeConfigChanged(Period config_);
    
    // Interface for Wandering Planet Contract
    WPInterFace WP_Contract;  

    struct Stake_Info{
        bool staked;
        address previous_owner;
        uint256 stake_time;
    }

    struct Period {
        uint256 startTime;
        uint256 endTime;
    }


    // Stake Data Sturcture
    mapping(uint256 => Stake_Info) public planetStakeInfo;
    // Mapping from owner to the list of staked token IDs(only for querying)
    mapping(address => uint256[]) private addressStakeList;
    // Mapping from token ID to index of the owner tokens list(support to operate the addressStakeList)
    mapping(uint256 => uint256) private addressStakeIndex;
    // List for all the tokens staked
    uint256 [] private allStakeList;
    // support to operate the allStake list
    mapping(uint256 => uint256) private allStakeIndex;

    Period public stakeTime;
    address public wandering_planet_address;
    uint256 public rewardPeriod = 10;


    constructor(address wandering_planet_address_, Period memory stake_time_) {
        require(wandering_planet_address_ != address(0), "invalid contract address");
        wandering_planet_address = wandering_planet_address_;
        stakeTime = stake_time_;
        WP_Contract = WPInterFace(wandering_planet_address);
    }
        
    /***********************************|
    |                Core               |
    |__________________________________*/
    
    /**
    * @dev Pubilc function for owners to reclaim their plantes
    * @param tokenID uint256 ID list of the token to be reclaim
    */
    function reclaimPlanets(uint256 [] memory tokenID) external callerIsUser nonReentrant{
        for(uint256 i = 0; i < tokenID.length; i++){
            _reclaim(tokenID[i]);
        }
    }

    /**
    * @dev Private function to stake one planet and update the state variabies
    * The function will be called when users transfer their tokens via 'safeTransferFrom'
    * @param tokenID uint256 ID of the token to be staked
    */
    function _stake(address owner, uint256 tokenID) internal{
        require(isStakeEnabled(), "stake not enabled");
        Stake_Info storage status = planetStakeInfo[tokenID];
        require(status.staked == false, "token is staking");
        status.staked = true;
        status.previous_owner = owner;
        status.stake_time = block.number;
        addEnumeration(owner, tokenID);
        addAllEnmeration(tokenID);
        emit Staked(owner, tokenID);
    }

    /**
    * @dev Private function to reclaim one planet and update the state variabies
    * @param tokenID uint256 ID of the token to be reclaimed
    */
    function _reclaim(uint256 tokenID) internal{
        require(isStakeEnabled(), "stake not enabled");
        Stake_Info storage status = planetStakeInfo[tokenID];
        require(status.staked == true, "the planet is freedom");
        require(status.previous_owner == msg.sender, "you are not the owner");
        WP_Contract.safeTransferFrom(address(this), msg.sender, tokenID);
        status.staked = false;
        status.previous_owner = address(0);
        status.stake_time = 0;
        removeEnumeration(msg.sender, tokenID);
        removeAllEnmeration(tokenID);
        emit Reclaimed(msg.sender, tokenID);
    }

   /**
    * @dev Public function to batach stake this planets
    * Approval for all the WP balances is needed
    * @param tokenIDs list of the tokens to be reclaimed
    */
    function batchStake(uint256 [] memory tokenIDs) external callerIsUser nonReentrant(){
        require(WP_Contract.isApprovedForAll(msg.sender, address(this)), "no authority");
        if (tokenIDs.length == 0){
            tokenIDs = getOwnedPlanets(msg.sender);
        }
        for(uint256 i = 0; i < tokenIDs.length; i++){
            WP_Contract.safeTransferFrom(msg.sender, address(this), tokenIDs[i]);
        }
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param address_ representing the owner of the given token ID
     * @param tokenID uint256 ID of the token to be added to the tokens list
     */
    function addEnumeration(address address_, uint256 tokenID) internal {
        addressStakeIndex[tokenID] = addressStakeList[address_].length;
        addressStakeList[address_].push(tokenID);
    }

    /**
    * @dev Private function to remove a token from this extension's ownership-tracking data structures.
    * @param address_ representing the previous owner of the given token ID
    * @param tokenID uint256 ID of the token to be removed from the tokens list of the given address
    */
    function removeEnumeration(address address_, uint256 tokenID) internal {

        require(addressStakeList[address_].length > 0, "No token staked by this address");
        uint256 lastTokenIndex = addressStakeList[address_].length - 1;
        uint256 tokenIndex = addressStakeIndex[tokenID];

        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = addressStakeList[address_][lastTokenIndex];

            addressStakeList[address_][tokenIndex] = lastTokenId;
            addressStakeIndex[lastTokenId] = tokenIndex; 
        }
        addressStakeList[address_].pop();
    }

    /*
    * @dev Private function to add a token to this extension's token tracking data structures.
    * @param tokenID uint256 ID of the token to be added to the tokens list
    */
    function addAllEnmeration(uint256 tokenID) internal {
        allStakeIndex[tokenID] = allStakeList.length;
        allStakeList.push(tokenID);
    }

    /**
    * @dev Private function to remove a token from this extension's ownership-tracking data structures.
    * @param tokenID uint256 ID of the token to be removed from the tokens list of the given address
    */
    function removeAllEnmeration(uint256 tokenID) internal {
        require(allStakeList.length > 0, "No token staked by this address");
        uint256 lastTokenIndex = allStakeList.length - 1;
        uint256 tokenIndex = allStakeIndex[tokenID];

        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = allStakeList[lastTokenIndex];

            allStakeList[tokenIndex] = lastTokenId;
            allStakeIndex[lastTokenId] = tokenIndex; 
        }
        allStakeList.pop();
    }


    /***********************************|
    |               State               |
    |__________________________________*/

    function isStakeEnabled() public view returns (bool){
        if (stakeTime.endTime > 0 && block.timestamp > stakeTime.endTime) {
            return false;
        }
        return stakeTime.startTime > 0 && 
            block.timestamp > stakeTime.startTime;
    }
    
    function getOwnedPlanets(address address_) public view returns (uint256 [] memory){
        uint256 max_tokenID = WP_Contract.totalMinted();
        uint256 balance = WP_Contract.balanceOf(address_);
        uint256 cnt = 0;
        uint256 [] memory ownedtokens = new uint256 [](balance);
        for(uint256 i = 0; i < max_tokenID; i++){
            if(WP_Contract.ownerOf(i) == address_){
                ownedtokens[cnt++] = i;
            }
        }
        return ownedtokens;
    }

    /**
    * @dev Public function to get the staked tokens of the given address
    * @param address_ representing owner address
    */
    function getStakeList(address address_) public view returns (uint256 [] memory){
        return addressStakeList[address_];
    }

    /**
    * @dev Public function to get all the stake list
    */
    function getAllStakeList() public view returns (uint256 [] memory){
        return allStakeList;
    }

    /**
    * @dev Public function to get all the staked tokens which satisify the condition of stake time
    */
    function getValidStakes() public view returns (uint256 [] memory, bool [] memory){
        uint256 stake_count = allStakeList.length;
        bool [] memory isvalidstake = new bool [](stake_count);
        for(uint256 i = 0; i < stake_count; i++){
            uint256 tokenID = allStakeList[i];
            Stake_Info memory status = planetStakeInfo[tokenID];
            if(status.staked && block.number - status.stake_time >= rewardPeriod){
                isvalidstake[i] = true;
            }
            else{
                isvalidstake[i] = false;
            }
        }
        return (allStakeList, isvalidstake);
    }

    function getStakeInfo(uint256 tokenID) public view returns (Stake_Info memory){
        return planetStakeInfo[tokenID];
    }



    /***********************************|
    |               Owner               |
    |__________________________________*/
    /**
    * @dev Owner function to write adward list
    */


    function setRewardPeriod(uint256 _rewardPeriod) external onlyOwner{
        require(_rewardPeriod > 0, "invalid parameter");
        rewardPeriod = _rewardPeriod;
    }

    function setStakeTime(Period calldata config_) external onlyOwner {
        stakeTime = config_;
        emit stakeTimeConfigChanged(config_);
    }

    /**
     * This method is used to prevent some users from mistakenly using transferFrom (instead of safeTransferFrom) to transfer NFT into the contract.
     * @param tokenIds_ the tokenId list
     * @param accounts_ the address list
     */
    function transferUnstakingTokens(uint256[] calldata tokenIds_, address[] calldata accounts_) external onlyOwner {
        require(tokenIds_.length == accounts_.length, "tokenIds_ and accounts_ length mismatch");
        require(tokenIds_.length > 0, "no tokenId");
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            uint256 tokenId = tokenIds_[i];
            address account = accounts_[i];
            require(planetStakeInfo[tokenId].stake_time == 0, "token is staking");
            WP_Contract.safeTransferFrom(address(this), account, tokenId);
        }
    }

    function stopStake(uint256[] calldata tokenIds_) external onlyOwner {
        for (uint256 i; i < tokenIds_.length; i++) {
            uint256 tokenId = tokenIds_[i];
            _reclaim(tokenId);
            emit StakeInterrupted(tokenId);
        }
    }


    function withdraw() external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        payable(_msgSender()).transfer(balance);
        emit Withdraw(_msgSender(), balance);
    }

    /***********************************|
    |              Modifier             |
    |__________________________________*/
    modifier callerIsUser() {
        require(tx.origin == _msgSender(), "caller is another contract");
        _;
    }

    /***********************************|
    |                Hook               |
    |__________________________________*/
    function onERC721Received(
        address,
        address _from,
        uint256 _tokenId,
        bytes memory
    ) public returns (bytes4) {
        require(msg.sender == wandering_planet_address, "only for WP");
        _stake(_from, _tokenId);
        return this.onERC721Received.selector;
    }
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