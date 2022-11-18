/**
 *Submitted for verification at Etherscan.io on 2022-11-18
*/

// SPDX-License-Identifier: MIT
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





contract ShonenJunkQuesting is ReentrancyGuard, Context, Ownable {
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
    bool public stakingEnabled = true;
    bool public unstakingEnabled = true;
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
        // Duration in seconds which is calculated during retrieval
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
        require(stakingEnabled, "Staking is currently disabled.");

        address invoker = _msgSender();

        require(
            nftCollection.ownerOf(_tokenId) == invoker,
            "You don't own this token."
        );

        require(
            stakerAddress[_tokenId] != invoker,
            "You already staked this token."
        );

        stakeTokenIdWithAddress(invoker, _tokenId);
        updateStakingMetadata(invoker);
    }

    function unstake(uint16 _tokenId) external nonReentrant {
        require(unstakingEnabled, "Unstaking is currently disabled.");

        address invoker = _msgSender();

        require(
            nftCollection.ownerOf(_tokenId) == invoker,
            "You don't own this token."
        );

        require(stakerAddress[_tokenId] == invoker, "Token is not staked.");

        unstakeTokenIdWithAddress(invoker, _tokenId);
        updateStakingMetadata(invoker);
    }

    function bulkStake(uint16[] memory _tokenIds) external nonReentrant {
        require(stakingEnabled, "Staking is currently disabled.");

        address invoker = _msgSender();

        bool ownedAllTokens = false;
        bool tokensNotYetStaked = false;
        for (uint16 i = 0; i < _tokenIds.length; i++) {
            ownedAllTokens = true;
            tokensNotYetStaked = true;
            if (nftCollection.ownerOf(_tokenIds[i]) != invoker) {
                ownedAllTokens = false;
                break;
            } else if (stakerAddress[_tokenIds[i]] == invoker) {
                tokensNotYetStaked = false;
                break;
            }
        }

        require(
            ownedAllTokens,
            "You don't own one or more of the tokens you're staking."
        );
        require(
            tokensNotYetStaked,
            "One or more of the tokens you're staking is already staked."
        );

        for (uint16 i = 0; i < _tokenIds.length; i++) {
            stakeTokenIdWithAddress(invoker, _tokenIds[i]);
        }

        updateStakingMetadata(invoker);
    }

    function bulkUnstake(uint16[] memory _tokenIds) external nonReentrant {
        require(unstakingEnabled, "Unstaking is currently disabled.");

        address invoker = _msgSender();

        bool ownedAllTokens = false;
        bool tokensAreStaked = false;
        for (uint16 i = 0; i < _tokenIds.length; i++) {
            ownedAllTokens = true;
            tokensAreStaked = true;
            if (nftCollection.ownerOf(_tokenIds[i]) != invoker) {
                ownedAllTokens = false;
                break;
            } else if (stakerAddress[_tokenIds[i]] != invoker) {
                tokensAreStaked = false;
                break;
            }
        }
        require(
            ownedAllTokens,
            "You don't own one or more of the tokens you're unstaking."
        );
        require(
            tokensAreStaked,
            "One or more of the tokens you're unstaking is not staked."
        );

        for (uint16 i = 0; i < _tokenIds.length; i++) {
            unstakeTokenIdWithAddress(invoker, _tokenIds[i]);
        }

        updateStakingMetadata(invoker);
    }

    function unstakeAll() external nonReentrant {
        require(unstakingEnabled, "Unstaking is currently disabled.");

        address invoker = _msgSender();

        unstakeAllByAddress(invoker);
    }

    // OWNER ONLY FUNCTIONS
    function allowStaking(bool _flag) external onlyOwner {
        require(
            _flag != stakingEnabled,
            "The new value is the same as the current value."
        );

        stakingEnabled = _flag;
    }

    function allowUnstaking(bool _flag) external onlyOwner {
        require(
            _flag != unstakingEnabled,
            "The new value is the same as the current value."
        );

        unstakingEnabled = _flag;
    }

    function forceBulkStake(uint16[] memory _tokenIds)
        external
        onlyOwner
        nonReentrant
    {
        address targetStaker = nftCollection.ownerOf(_tokenIds[0]);

        bool ownedAllTokens = false;
        bool tokensNotYetStaked = false;
        for (uint16 i = 0; i < _tokenIds.length; i++) {
            ownedAllTokens = true;
            tokensNotYetStaked = true;
            if (nftCollection.ownerOf(_tokenIds[i]) != targetStaker) {
                ownedAllTokens = false;
                break;
            } else if (stakerAddress[_tokenIds[i]] == targetStaker) {
                tokensNotYetStaked = false;
                break;
            }
        }

        require(ownedAllTokens, "Tokens must belong to the same address.");
        require(
            tokensNotYetStaked,
            "One or more of the tokes is already staked."
        );

        for (uint16 i = 0; i < _tokenIds.length; i++) {
            stakeTokenIdWithAddress(targetStaker, _tokenIds[i]);
        }

        updateStakingMetadata(targetStaker);
    }

    function forceBulkUnstake(uint16[] memory _tokenIds)
        external
        onlyOwner
        nonReentrant
    {
        address targetStaker = nftCollection.ownerOf(_tokenIds[0]);

        bool ownedAllTokens = false;
        bool tokensAreStaked = false;
        for (uint16 i = 0; i < _tokenIds.length; i++) {
            ownedAllTokens = true;
            tokensAreStaked = true;
            if (nftCollection.ownerOf(_tokenIds[i]) != targetStaker) {
                ownedAllTokens = false;
                break;
            } else if (stakerAddress[_tokenIds[i]] != targetStaker) {
                tokensAreStaked = false;
                break;
            }
        }
        require(ownedAllTokens, "Tokens must belong to the same address.");
        require(tokensAreStaked, "One or more of the tokens is not staked.");

        for (uint16 i = 0; i < _tokenIds.length; i++) {
            unstakeTokenIdWithAddress(targetStaker, _tokenIds[i]);
        }

        updateStakingMetadata(targetStaker);
    }

    function forceUpdateTimeOfStaking(
        uint16[] memory _tokenIds,
        uint256 timeOfStaking
    ) external onlyOwner nonReentrant {
        address targetStaker = nftCollection.ownerOf(_tokenIds[0]);

        bool validTokenIds = false;
        for (uint16 i = 0; i < _tokenIds.length; i++) {
            validTokenIds = true;
            if (nftCollection.ownerOf(_tokenIds[i]) != targetStaker) {
                validTokenIds = false;
                break;
            }
        }
        require(validTokenIds, "Tokens must belong to the same address.");

        // Try and update the timeOfStaking for each token Id
        for (uint16 i = 0; i < _tokenIds.length; i++) {
            uint16 currentTokenId = _tokenIds[i];
            // Retrieve the tokenIndex from the stakers array of staked tokens
            uint16 tokenIndex = maxSupply;
            for (
                uint16 j = 0;
                j < stakers[targetStaker].stakedTokens.length;
                j++
            ) {
                if (
                    stakers[targetStaker].stakedTokens[j].tokenId ==
                    currentTokenId
                ) {
                    tokenIndex = j;
                    break;
                }
            }

            // Ensure the tokenIndex is not out of bounds
            if (tokenIndex < maxSupply) {
                bool dataIsCorrect = stakers[targetStaker]
                    .stakedTokens[tokenIndex]
                    .staker ==
                    targetStaker &&
                    stakerAddress[currentTokenId] == targetStaker;
                bool stillInOwnersWallet = nftCollection.ownerOf(
                    currentTokenId
                ) == targetStaker;

                // Update the time of staking if the all other staking information is still intact
                if (dataIsCorrect && stillInOwnersWallet) {
                    stakers[targetStaker]
                        .stakedTokens[tokenIndex]
                        .timeOfStaking = timeOfStaking;
                }
            }
        }
    }

    function forceUnstakeAll(address _targetStaker) external onlyOwner {
        unstakeAllByAddress(_targetStaker);
    }

    // VIEW ONLY FUNCTIONS
    function getMyTotalStakeCount() external view returns (uint16) {
        address invoker = _msgSender();

        return getStakeCountByAddress(invoker);
    }

    function getStakedTokensByAddress(address _staker)
        external
        view
        returns (StakedToken[] memory)
    {
        uint16 totalStakeCountByAddress = getStakeCountByAddress(_staker);
        // Return empty list if address has no staked tokens
        if (totalStakeCountByAddress < 1) {
            return new StakedToken[](0);
        }

        // Return all the tokens actively staked by this owner
        StakedToken[] memory activeStakedTokens = new StakedToken[](
            totalStakeCountByAddress
        );
        uint16 index = 0;

        // Go thru each staked tokens and validate before adding them to list
        for (uint16 i = 0; i < stakers[_staker].stakedTokens.length; i++) {
            StakedToken memory stakedTokenInfo = stakers[_staker].stakedTokens[
                i
            ];
            bool dataIsCorrect = stakedTokenInfo.staker == _staker &&
                stakerAddress[stakedTokenInfo.tokenId] == _staker;
            bool stillInOwnersWallet = nftCollection.ownerOf(
                stakedTokenInfo.tokenId
            ) == _staker;

            if (dataIsCorrect && stillInOwnersWallet) {
                // Copy the staked token information
                activeStakedTokens[index] = stakedTokenInfo;
                // Update the duration of stake
                activeStakedTokens[index].durationOfStaking =
                    block.timestamp -
                    activeStakedTokens[index].timeOfStaking;

                index++;
            }
        }

        return activeStakedTokens;
    }

    function getAllActiveStakers() external view returns (address[] memory) {
        address[] memory verifiedStakers = new address[](activeStakers.length);
        uint16 counter = 0;
        for (uint16 i = 0; i < activeStakers.length; i++) {
            address currentAddress = activeStakers[i];
            StakedToken[] memory stakedTokens = stakers[currentAddress]
                .stakedTokens;
            for (uint16 j = 0; j < stakedTokens.length; j++) {
                if (
                    stakerAddress[stakedTokens[j].tokenId] == currentAddress &&
                    nftCollection.ownerOf(stakedTokens[j].tokenId) ==
                    currentAddress
                ) {
                    verifiedStakers[counter] = currentAddress;
                    counter++;
                    break;
                }
            }
        }

        address[] memory filteredActiveStakers = new address[](counter);
        for (uint16 i = 0; i < counter; i++) {
            filteredActiveStakers[i] = verifiedStakers[i];
        }

        return filteredActiveStakers;
    }

    function getAllActiveStakersCount() external view returns (uint16) {
        address[] memory verifiedStakers = new address[](activeStakers.length);
        uint16 counter = 0;
        for (uint16 i = 0; i < activeStakers.length; i++) {
            address currentAddress = activeStakers[i];
            StakedToken[] memory stakedTokens = stakers[currentAddress]
                .stakedTokens;
            for (uint16 j = 0; j < stakedTokens.length; j++) {
                if (
                    stakerAddress[stakedTokens[j].tokenId] == currentAddress &&
                    nftCollection.ownerOf(stakedTokens[j].tokenId) ==
                    currentAddress
                ) {
                    verifiedStakers[counter] = currentAddress;
                    counter++;
                    break;
                }
            }
        }

        return counter;
    }

    // INTERNAL
    function stakeTokenIdWithAddress(address _staker, uint16 _tokenId)
        internal
    {
        // Create StakedToken
        StakedToken memory stakedToken = StakedToken(
            _staker,
            _tokenId,
            block.timestamp,
            0
        );

        // Find the index of the token from the stakedToken list if it exists
        uint16 tokenIndex = maxSupply;
        for (uint16 i = 0; i < stakers[_staker].stakedTokens.length; i++) {
            if (stakers[_staker].stakedTokens[i].tokenId == _tokenId) {
                tokenIndex = i;
                break;
            }
        }

        // Add or update
        if (tokenIndex < maxSupply) {
            stakers[_staker].stakedTokens[tokenIndex] = stakedToken;
        } else {
            stakers[_staker].stakedTokens.push(stakedToken);
        }

        // Update the mapping of the Token Id to the stakers address
        bindAddressToTokenId(_staker, _tokenId);
    }

    function unstakeTokenIdWithAddress(address _staker, uint16 _tokenId)
        internal
    {
        // Find the index of the token from the stakedToken list
        uint16 tokenIndex = maxSupply;
        for (uint16 i = 0; i < stakers[_staker].stakedTokens.length; i++) {
            if (stakers[_staker].stakedTokens[i].tokenId == _tokenId) {
                tokenIndex = i;
                break;
            }
        }

        // _tokenId is in stakedTokens
        if (tokenIndex < maxSupply) {
            // Remove this token from the users stakedTokens list
            stakers[_staker].stakedTokens[tokenIndex].staker = address(0);
            stakers[_staker].stakedTokens[tokenIndex].timeOfStaking = 0;

            // Set the stakerAddress for the tokenId to address(0) to indicate that the token is no longer staked
            if (stakerAddress[_tokenId] == _staker) {
                stakerAddress[_tokenId] = address(0);
            }
        }
    }

    // This method ensures that the staking data is intact
    // must be called after all the stakeTokenIdWithAddress/unstakeTokenIdWithAddress calls are finished
    function updateStakingMetadata(address _staker) internal {
        uint16 totalStakedCountByAddress = getStakeCountByAddress(_staker);
        stakers[_staker].amountStaked = totalStakedCountByAddress;
        stakers[_staker].timeOfLastUpdate = block.timestamp;

        bool completelyUnstaked = totalStakedCountByAddress == 0;
        if (completelyUnstaked) {
            unstakeAllByAddress(_staker);
        } else {
            addToActiveStakers(_staker);
        }
    }

    function addToActiveStakers(address _staker) internal {
        for (uint16 i = 0; i < activeStakers.length; i++) {
            if (activeStakers[i] == _staker) {
                return;
            }
        }

        activeStakers.push(_staker);
    }

    function removeFromActiveStakers(address _inactiveStakerAddress)
        internal
        returns (bool)
    {
        for (uint256 i = 0; i < activeStakers.length; i++) {
            if (activeStakers[i] == _inactiveStakerAddress) {
                activeStakers[i] = activeStakers[activeStakers.length - 1];
                activeStakers.pop();
                return true;
            }
        }

        return false;
    }

    // Clear staking data of an address
    function unstakeAllByAddress(address _staker) internal {
        removeFromActiveStakers(_staker);
        stakers[_staker].timeOfLastUpdate = block.timestamp;
        delete stakers[_staker].stakedTokens;
        stakers[_staker].amountStaked = 0;
    }

    // Binds the staker information to a token Id
    function bindAddressToTokenId(address _staker, uint16 _tokenId) internal {
        address previousStakerAddress = stakerAddress[_tokenId];
        bool hasValidPreviousStakerAddress = previousStakerAddress != _staker &&
            previousStakerAddress != address(0);

        // Unstake and update previous owner if there's any
        if (hasValidPreviousStakerAddress) {
            unstakeTokenIdWithAddress(previousStakerAddress, _tokenId);
            updateStakingMetadata(previousStakerAddress);
        }

        stakerAddress[_tokenId] = _staker;
    }

    function getStakeCountByAddress(address _staker)
        internal
        view
        returns (uint16)
    {
        uint16 stakeCount = 0;

        for (uint16 i = 0; i < stakers[_staker].stakedTokens.length; i++) {
            uint16 currentTokenId = stakers[_staker].stakedTokens[i].tokenId;
            bool dataIsCorrect = stakers[_staker].stakedTokens[i].staker ==
                _staker &&
                stakerAddress[currentTokenId] == _staker;
            bool stillInOwnersWallet = nftCollection.ownerOf(currentTokenId) ==
                _staker;

            // Count only those that have valid staking data and still owned by the staker
            if (stillInOwnersWallet && dataIsCorrect) {
                stakeCount++;
            }
        }

        return stakeCount;
    }
}