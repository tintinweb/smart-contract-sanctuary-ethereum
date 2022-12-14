/**
 *Submitted for verification at Etherscan.io on 2022-12-14
*/

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Context.sol


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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol


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

// File: nahmii/IERC721Reward.sol



pragma solidity 0.8.4;



/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Reward  {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
      * @dev Safely transfers `tokenId` token from `from` to `to`.
      *
      * Requirements:
      *
      * - `from` cannot be the zero address.
      * - `to` cannot be the zero address.
      * - `tokenId` token must exist and be owned by `from`.
      * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
      * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
      *
      * Emits a {Transfer} event.
      */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;


	function mintReward(address to,uint256 tokenId) external;
}

// File: nahmii/hatching.sol

pragma solidity 0.8.4;

// import "@openzeppelin/contracts/token/ERC721/IERC721.sol";


//import "@openzeppelin/contracts/access/Ownable.sol";

contract hatching is Ownable {

     //@notice  Interfaces for ERC20 and ERC721
	address public rewardsToken;
    address public nftCollection;

    // @notice time frame to withdraw reward
    uint256 public timeFrame ;

    uint256 public tokenMint = 0;

    //@notice  mapping user address ,tokenId  to bool
    mapping(address => mapping(uint256 => bool)) public UserHasClaimed;

    //@notice  mapping collection address ,tokenId  to bool
    mapping(address => mapping(uint256 => bool))
        public DepositCollectionClaimed;
    //@notice  mapping reward collection address ,tokenId to bool
    mapping(address => mapping(uint256 => bool)) public rewardNftHasClaimed;

    //@notice mapping to  keep track of deposited tokenId
    mapping(address => mapping(uint256 => bool)) public tokenDeposit;

    //@notice mapping to track time for tokenId;
    mapping(address => mapping(uint256 => uint256)) public tokenTime;

    //@notice mapping tokenId to bool
    mapping(uint256 => bool) public tokenIdClaimed;

    //  //@notice mapping track tokenId deposited to number of rewardNFTs
    //  mapping (uint =>numToken) numTokenMinted;

    /**
     * @dev Initializes the contract by setting a `_nftCollection` and a `_rewardsToken` to the token collection and reward.
     */
    constructor(address _nftCollection, address _rewardsToken) {
        require(_nftCollection != address(0), "not zero address");
        nftCollection = _nftCollection;
     	 rewardsToken = _rewardsToken;
        timeFrame = 2 minutes; //1 days;
    }

    /**
     * @notice deposit nftToken to smart contract
     * @dev nft collection `_tokenId`.
     */
    function depositToken(uint256 _tokenId) external {
        require(
            UserHasClaimed[msg.sender][_tokenId] == false,
            "token already claimed"
        );
        require(
            DepositCollectionClaimed[nftCollection][_tokenId] == false,
            "collection token  claimed"
        );
        //require(rewardNftHasClaimed[address(nftCollection)][_tokenId] == false,"collection token  claimed");
        require(
            IERC721Reward(nftCollection).ownerOf(_tokenId) == msg.sender &&
               IERC721Reward(nftCollection) .isApprovedForAll(msg.sender, address(this)),
            "not owner"
        );
        require(tokenIdClaimed[_tokenId] == false, "token already hatched");
        tokenTime[nftCollection][_tokenId] = _getNow();
        IERC721Reward(nftCollection).transferFrom(msg.sender, address(this), _tokenId);
        tokenDeposit[msg.sender][_tokenId] = true;
         
    }

    /**
     * @notice claim reward and withdraw token
     * @dev nft collection `_tokenId`.
     */

    function claimReward(uint256 _tokenId) external {
        require(
            tokenDeposit[msg.sender][_tokenId] == true,
            "Did not deposit token"
        );
        uint256 time = tokenTime[nftCollection][_tokenId];
        tokenIdClaimed[_tokenId] = true;
        DepositCollectionClaimed[nftCollection][_tokenId] = true;
        require(
            UserHasClaimed[msg.sender][_tokenId] == false,
            "token already claimed"
        );

        require(block.timestamp >= time + timeFrame, "not yet time");
		
        UserHasClaimed[msg.sender][_tokenId] = true;
        tokenMint++;
        IERC721Reward(rewardsToken).mintReward(msg.sender, _tokenId);
         IERC721Reward(nftCollection).transferFrom(address(this), msg.sender, _tokenId);
    }

    /**
     * @notice setTime of which user can claim reward, this can be don only when the pool is empty
     * @dev new `_time`.
     */
    function setTime(uint256 _time) external onlyOwner {
        require(IERC721Reward(nftCollection).balanceOf(address(this)) == 0, "must be 0");
        timeFrame = _time;
    }
	/**
     * @notice setRewardToken set the NFT collection that will be claimed as reward 
     * @dev new `_time`.
     */  
    function setRewardToken(address _rewardsToken) external onlyOwner {
           require(_rewardsToken != address(0), "not zero address");
        rewardsToken = _rewardsToken;
    }
	/**
     * @notice setCollectionToken set the NFT collection that will be deposited 
     */
    function setCollectionToken(address _CollectionToken) external onlyOwner {
           require( _CollectionToken != address(0), "not zero address");
        nftCollection = _CollectionToken;
    }

    function _getNow() internal view virtual returns (uint256) {
        return block.timestamp;
    }
    

    
}