/**
 *Submitted for verification at Etherscan.io on 2022-10-31
*/

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

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


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

// File: contracts/ShonenJunkQuesting.sol


pragma solidity ^0.8.9;




contract ShonenJunkQuesting is ReentrancyGuard, Context {
    /*
          .__                                     __              __    
      _____|  |__   ____   ____   ____   ____     |__|__ __  ____ |  | __
    /  ___/  |  \ /  _ \ /    \_/ __ \ /    \    |  |  |  \/    \|  |/ /
    \___ \|   Y  (  <_> )   |  \  ___/|   |  \   |  |  |  /   |  \    < 
    /____  >___|  /\____/|___|  /\___  >___|  /\__|  |____/|___|  /__|_ \
        \/     \/            \/     \/     \/\______|          \/     \/
    */
    IERC721 public immutable nftCollection;
    uint16 public immutable maxSupply;
    uint16 public totalStaked = 0;
    address[] private activeStakers;

    constructor(IERC721 _nftCollection, uint16 _maxSupply) {
        nftCollection = _nftCollection;
        maxSupply = _maxSupply;
    }

    struct StakedToken {
        address staker;
        uint16 tokenId;
        // The time when this token started staking
        uint256 timeOfStaking;
        // Duration in sconds which is calculated during retrieval
        uint256 durationOfStaking;
    }

    struct Staker {
        uint16 amountStaked;
        StakedToken[] stakedTokens;
        uint256 timeOfLastUpdate;
    }

    // Mapping of owner address to staker info
    mapping(address => Staker) public stakers;

    // Mapping of Token Id to original owner address
    mapping(uint256 => address) public stakerAddress;

    function stake(uint16 _tokenId) external nonReentrant {
        address invoker = _msgSender();
        // Staker must own the Token Id being staked
        require(
            nftCollection.ownerOf(_tokenId) == invoker,
            "You don't own this token."
        );

        bool isApproved = nftCollection.isApprovedForAll(
            invoker,
            address(this)
        );
        if (!isApproved) {
            nftCollection.setApprovalForAll(address(this), true);
        }

        // Transfer the token from the staker to the smart contract address
        nftCollection.transferFrom(invoker, address(this), _tokenId);

        // Create StakedToken
        StakedToken memory stakedToken = StakedToken(
            invoker,
            _tokenId,
            block.timestamp,
            0
        );

        // Find the index of the token from the sharedTokens list if it exists
        uint16 tokenIndex = maxSupply;
        for (uint16 i = 0; i < stakers[invoker].stakedTokens.length; i++) {
            if (stakers[invoker].stakedTokens[i].tokenId == _tokenId) {
                tokenIndex = i;
                break;
            }
        }

        // Add the token to the stakers stakedTokens list
        if (tokenIndex < maxSupply) {
            stakers[invoker].stakedTokens[tokenIndex] = stakedToken;
        } else {
            stakers[invoker].stakedTokens.push(stakedToken);
        }

        // Update metadata
        stakers[invoker].amountStaked++;
        totalStaked++;
        stakers[invoker].timeOfLastUpdate = block.timestamp;

        // Update list of active stakers
        if (stakers[invoker].amountStaked == 1) {
            activeStakers.push(invoker);
        }

        // Update the mapping of the Token Id to the stakers address
        stakerAddress[_tokenId] = invoker;
    }

    function withdraw(uint16 _tokenId) external nonReentrant {
        address invoker = _msgSender();
        // Ensure user has staked tokens
        require(stakers[invoker].amountStaked > 0, "You have no token staked.");

        // Staker must own the Token Id they are trying to withdraw
        require(
            stakerAddress[_tokenId] == invoker,
            "Token Id is not staked or not owned by sender."
        );

        // Transfer the token from the smart contract address to the staker
        nftCollection.transferFrom(address(this), invoker, _tokenId);

        // Find the index of the token from the sharedTokens list
        uint16 tokenIndex = 0;
        for (uint16 i = 0; i < stakers[invoker].stakedTokens.length; i++) {
            if (stakers[invoker].stakedTokens[i].tokenId == _tokenId) {
                tokenIndex = i;
                break;
            }
        }

        // Remove this token from then users stakedTokens list
        stakers[invoker].stakedTokens[tokenIndex].staker = address(0);
        // Update metadata
        stakers[invoker].amountStaked--;
        totalStaked--;
        stakers[invoker].timeOfLastUpdate = block.timestamp;

        // Update list of active stakers
        if (stakers[invoker].amountStaked == 0) {
            removeFromActiveStakers(invoker);
        }

        // Set the stakerAddress for the tokenId to address(0) to indicate that the token is no longer staked
        stakerAddress[_tokenId] = address(0);
    }

    function bulkStake(uint16[] memory _tokenIds) external nonReentrant {
        address invoker = _msgSender();

        // Staker must own the Token Id being staked
        bool validTokenIds = false;
        for (uint16 i = 0; i < _tokenIds.length; i++) {
            validTokenIds = true;
            if (nftCollection.ownerOf(_tokenIds[i]) != invoker) {
                validTokenIds = false;
                break;
            }
        }
        require(
            validTokenIds,
            "You don't own one or more of the tokens you're staking."
        );

        bool isApproved = nftCollection.isApprovedForAll(
            invoker,
            address(this)
        );
        if (!isApproved) {
            nftCollection.setApprovalForAll(address(this), true);
        }

        // Transfer the token from the staker to the smart contract address
        for (uint16 i = 0; i < _tokenIds.length; i++) {
            nftCollection.transferFrom(invoker, address(this), _tokenIds[i]);

            // Create StakedToken
            StakedToken memory stakedToken = StakedToken(
                invoker,
                _tokenIds[i],
                block.timestamp,
                0
            );

            // Find the index of the token from the sharedTokens list if it exists
            uint16 tokenIndex = maxSupply;
            for (uint16 j = 0; j < stakers[invoker].stakedTokens.length; j++) {
                if (stakers[invoker].stakedTokens[j].tokenId == _tokenIds[i]) {
                    tokenIndex = j;
                    break;
                }
            }

            // Add the token to the stakers stakedTokens list
            if (tokenIndex < maxSupply) {
                stakers[invoker].stakedTokens[tokenIndex] = stakedToken;
            } else {
                stakers[invoker].stakedTokens.push(stakedToken);
            }

            // Update metadata
            stakers[invoker].amountStaked++;
            totalStaked++;
            stakers[invoker].timeOfLastUpdate = block.timestamp;

            // Update list of active stakers
            if (stakers[invoker].amountStaked == 1) {
                activeStakers.push(invoker);
            }

            // Update the mapping of the Token Id to the stakers address
            stakerAddress[_tokenIds[i]] = invoker;
        }
    }

    function bulkWithdraw(uint16[] memory _tokenIds) external nonReentrant {
        address invoker = _msgSender();

        // Ensure user has staked tokens
        require(
            stakers[invoker].amountStaked >= _tokenIds.length,
            "Amount of your staked tokens is less than the amount you want to withdraw."
        );

        // User must own the Token Id being staked
        bool validTokenIds = false;
        for (uint16 i = 0; i < _tokenIds.length; i++) {
            validTokenIds = true;
            if (stakerAddress[_tokenIds[i]] != invoker) {
                validTokenIds = false;
                break;
            }
        }
        // User must own the Token Id they are trying to withdraw
        require(
            validTokenIds,
            "You don't own one or more of the tokens you're withdrawing."
        );

        for (uint16 i = 0; i < _tokenIds.length; i++) {
            // Transfer the token from the smart contract address to the staker
            nftCollection.transferFrom(address(this), invoker, _tokenIds[i]);

            // Find the index of the token from the sharedTokens list
            uint16 tokenIndex = 0;
            for (uint16 j = 0; j < stakers[invoker].stakedTokens.length; j++) {
                if (stakers[invoker].stakedTokens[j].tokenId == _tokenIds[i]) {
                    tokenIndex = j;
                    break;
                }
            }

            // Remove this token from then users stakedTokens list
            stakers[invoker].stakedTokens[_tokenIds[i]].staker = address(0);
            // Update metadata
            stakers[invoker].amountStaked--;
            totalStaked--;
            stakers[invoker].timeOfLastUpdate = block.timestamp;

            // Update list of active stakers
            if (stakers[invoker].amountStaked == 0) {
                removeFromActiveStakers(invoker);
            }

            // Set the stakerAddress for the tokenId to address(0) to indicate that the token is no longer staked
            stakerAddress[_tokenIds[i]] = address(0);
        }
    }

    // VIEW ONLY FUNCTIONS
    function getStakedTokensByOwner(address _owner)
        public
        view
        returns (StakedToken[] memory)
    {
        // Return empty list if address has how staked tokens
        if (stakers[_owner].amountStaked < 1) {
            return new StakedToken[](0);
        }

        // Return all the tokens actively staked by this owner
        StakedToken[] memory _activeStakedTokens = new StakedToken[](
            stakers[_owner].amountStaked
        );
        uint16 index = 0;

        // Loop thru each valid staked tokens
        for (uint16 i = 0; i < stakers[_owner].stakedTokens.length; i++) {
            if (stakers[_owner].stakedTokens[i].staker != (address(0))) {
                // Copy the staked token information
                _activeStakedTokens[index] = stakers[_owner].stakedTokens[i];
                // Update the duration of stake
                _activeStakedTokens[index].durationOfStaking =
                    block.timestamp -
                    _activeStakedTokens[index].timeOfStaking;

                index++;
            }
        }

        return _activeStakedTokens;
    }

    function getAllActiveStakers() public view returns (address[] memory) {
        return activeStakers;
    }

    // INTERNAL
    function removeFromActiveStakers(address inactiveStakerAddress) internal {
        for (uint256 i = 0; i < activeStakers.length; i++) {
            if (activeStakers[i] == inactiveStakerAddress) {
                activeStakers[i] = activeStakers[activeStakers.length - 1];
                activeStakers.pop();
                break;
            }
        }
    }
}