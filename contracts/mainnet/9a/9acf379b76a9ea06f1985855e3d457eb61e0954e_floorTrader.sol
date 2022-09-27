/**
 *Submitted for verification at Etherscan.io on 2022-09-27
*/

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


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

// File: @openzeppelin/[email protected]/utils/introspection/IERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// File: @openzeppelin/[email protected]/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
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

    function whitelistAdd(address targetAddress, uint16 amount) external;

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// File: FloorTrader.sol



// "Floor Trader by benyy.eth on behalf of blockbusters.eth"
pragma solidity ^0.8.4;




contract floorTrader is ReentrancyGuard {

    address blockBusters;
    
    mapping(address => uint16[]) public poolTokens; 
    mapping(address => address) public poolOwner;
    mapping(address => uint256) public poolLength;
    mapping(address => uint256) public userRewards;
    mapping(address => uint256) public userTotalRewards;
    mapping(address => uint16) public poolTrades; 
    mapping(address => uint16) public userPoints; 

    address[] public allPools;    
    address[] private blank;

    address[] private temp;

    uint16 private poolCount;
    uint16 public tradeCount;
    uint16 public totalPools;
    uint16[] private blankTokens;
    constructor() {
    blockBusters = 0xed04ACBF9df59b9DB80851bfEEA0da51Bd6DE997; 

    
    }
    function getBalance() public view returns (uint) {
        return address(this).balance;
    }
    function Claim() public nonReentrant {
        address payable to = payable(msg.sender);
        uint256 rewards = userRewards[msg.sender];
        userRewards[msg.sender] = 0;
        to.transfer(rewards); 
    }
    function random(address NFTAddress) public view returns (uint256) {
        uint256 variety = poolLength[NFTAddress] - 1;
        uint256 rng = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, block.difficulty))) % variety;
        return rng;
    }


    function createPool(address NFTAddress, uint16[] calldata tokenIDs) public payable {
        require(msg.value >= 2000*10**13, "treasury demands 0.02 ETH payment.");
        IERC721 NFT = IERC721(NFTAddress); 
        require(tokenIDs.length >= 3, "Not enough tokens to create pool");
        require(poolLength[NFTAddress] == 0, "there is already a pool");
        require(NFT.isApprovedForAll(msg.sender, address(this)), "user has not approved token transfer");
        uint16 newID = poolCount + 1;
        uint256 newTotal = userRewards[blockBusters] + msg.value;
        
            for (uint i=0; i<tokenIDs.length; i++) {
                require(NFT.ownerOf(tokenIDs[i]) == msg.sender && tokenIDs[i] != 0, "user does not own token, or used a zero token.");
                NFT.transferFrom(msg.sender, address(this),  tokenIDs[i]);

                poolTokens[NFTAddress].push(tokenIDs[i]);
            }
        poolOwner[NFTAddress] = msg.sender;
        poolLength[NFTAddress] = uint256(tokenIDs.length);
        poolCount = newID;
        allPools.push(NFTAddress);
        totalPools += 1;
        userRewards[blockBusters] = newTotal;
    }

    function deletePool(address NFTAddress) public {
        IERC721 NFT = IERC721(NFTAddress); 
        address poolsOwner = poolOwner[NFTAddress];
        require(poolLength[NFTAddress] >= 1, "there is no pool");
        require(msg.sender == poolsOwner, "you dont own this pool");


        for (uint i=0; i<poolTokens[NFTAddress].length; i++) {
            require(NFT.ownerOf(poolTokens[NFTAddress][i]) == address(this), "we dont have this token");
            NFT.approve(msg.sender, poolTokens[NFTAddress][i]);
            NFT.transferFrom(address(this), msg.sender,  poolTokens[NFTAddress][i]);
        }
        poolTokens[NFTAddress] = blankTokens;
        poolOwner[NFTAddress] = blockBusters;
        poolLength[NFTAddress] = 0;
        poolTrades[NFTAddress] = 0; 
        temp = blank;
        for (uint z=0; z<allPools.length; z++) {
            if (allPools[z] == NFTAddress) {
                //omit the deleted address
            } else {
                temp.push(allPools[z]);
            }
        }
        allPools = temp;
        totalPools -= 1;
    }

    function trade(address NFTAddress, uint16 tokenID) public payable nonReentrant {
        require(msg.value >= 420*10**13, "treasury demands 0.00420 ETH payment.");
        IERC721 NFT = IERC721(NFTAddress); 
        require(poolLength[NFTAddress] >= 1, "this pool doesn't exist");
        require(NFT.isApprovedForAll(msg.sender, address(this)), "user has not approved token transfer");

        uint256 arrayNum = random(NFTAddress);
        uint16 result = poolTokens[NFTAddress][arrayNum];

        require(result != 0 && NFT.ownerOf(result) == address(this), "this token doesn't exist.");

        address poolsOwner = poolOwner[NFTAddress];
        uint16 poolTradeCount = poolTrades[NFTAddress] + 1;
        uint16 points = userPoints[msg.sender] + 1;
        uint16 ownerPoints = userPoints[poolsOwner] + 1;

        
        NFT.transferFrom(msg.sender, address(this),  tokenID);
        NFT.approve(msg.sender, result);
        NFT.transferFrom(address(this), msg.sender,  result);
        poolTokens[NFTAddress][arrayNum] = tokenID;

        uint256 newRewards = userRewards[poolsOwner] + (msg.value/2);
        uint256 newTotalRewards = userTotalRewards[poolsOwner] + (msg.value/2);
        userRewards[poolsOwner] = newRewards;
        userTotalRewards[poolsOwner] = newTotalRewards;

        uint256 treasuryRewards = userRewards[blockBusters] + (msg.value/2);
        uint256 newTreasuryTotalRewards = userTotalRewards[blockBusters] + (msg.value/2);
        userRewards[blockBusters] = treasuryRewards;
        userTotalRewards[blockBusters] = newTreasuryTotalRewards;

        poolTrades[NFTAddress] = poolTradeCount;
        tradeCount += 1;
        userPoints[msg.sender] = points;
        userPoints[poolsOwner] = ownerPoints;
    }

    





}