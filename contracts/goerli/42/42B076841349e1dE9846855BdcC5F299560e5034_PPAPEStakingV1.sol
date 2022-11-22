// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PPAPEStakingV1 is ReentrancyGuard, Ownable {
  uint256 private constant MAX_SUPPLY = 10000;

  uint256 public stakeStartTime;
  uint256 public stakingCooldownDurationInSeconds = 86400;

  IERC721 public immutable nftCollection;

  // Constructor function to set the NFT collection addresses
  constructor(IERC721 _nftCollection) {
    nftCollection = _nftCollection;
    stakeStartTime = 1667876400;
  }

  struct StakedToken {
    address fromAddr;
    uint256 tokenId;
    uint256 tokenStakedAt;
  }

  // Staker info
  struct Staker {
    uint256 amountStaked;
    uint256[] tokenIds;
  }

  struct TokensOfOwner {
    uint256[] unstaked;
    StakedToken[] staked;
  }

  // userAddr => Staker
  mapping(address => Staker) public userAddrStakerMap;

  // tokenId => StakedToken Mapping
  mapping(uint256 => StakedToken) public tokenIdStakedTokenMap;

  // @notice event emitted when a user has staked a nft
  event Staked(address owner, uint256 tokenId, uint256 stakedAt);

  // @notice event emitted when a user has withdraw a nft
  event Unstaked(address owner, uint256 tokenId, uint256 stakedAt);

  // Function to set staking start time
  function setStakeStartTime(uint256 ts) external onlyOwner {
      stakeStartTime = ts;
  }

  // Function to stake user's NFT.
  function stake(uint256 tokenId) external nonReentrant {
    require(block.timestamp >= stakeStartTime, "the staking is not started yet");
    _stake(msg.sender, tokenId);
  }

  // Function to stake the NFTs in a batch.
  function stakeBatch(uint256[] memory tokenIds) external nonReentrant {
    require(block.timestamp >= stakeStartTime, "the staking is not started yet");
    for (uint256 i = 0; i < tokenIds.length; i++) {
      _stake(msg.sender, tokenIds[i]);
    }
  }

  // Increment the amountStaked and map msg.sender to the Token Id of the staked
  // Token to later send back on withdrawal.
  function _stake(address _addr, uint256 _tokenId) private {
    // Token must be the crafted NFT, so tokenId >= 10000 && tokenId < 15000
    require(
      _tokenId >= MAX_SUPPLY  && _tokenId < MAX_SUPPLY+(MAX_SUPPLY/2),
      "Can not stake uncrafted token"
    );
    // Wallet must own the token they are trying to stake
    require(
      nftCollection.ownerOf(_tokenId) == _addr,
      "You don't own this token!"
    );

    // Transfer the token from the wallet to this Smart Contract
    nftCollection.transferFrom(_addr, address(this), _tokenId);

    // Create StakedToken
    StakedToken memory stakedToken = StakedToken(
      _addr,
      _tokenId,
      block.timestamp
    );

    // Update the mapping of the tokenId to the staker's address
    tokenIdStakedTokenMap[_tokenId] = stakedToken;

    // Add the token to the stakedTokens array
    userAddrStakerMap[_addr].tokenIds.push(_tokenId);

    // Increment the amount staked for this wallet
    userAddrStakerMap[_addr].amountStaked++;

    emit Staked(_addr, _tokenId, stakedToken.tokenStakedAt);
  }

  // Function to set the cooldown duration time in seconds.
  function setStakingCooldownDurationInSeconds(uint256 sec) external onlyOwner {
    stakingCooldownDurationInSeconds = sec;
  }

  // Function to refund the NFT to original owner
  function refund(uint256 tokenId) external onlyOwner {
    _unstake(tokenIdStakedTokenMap[tokenId].fromAddr, tokenId);
  }

  // Function to unstake (redeem) 
  function unstake(uint256 tokenId) external nonReentrant {
    _unstake(msg.sender, tokenId);
  }

  // Function to unstake the NFTs in a batch
  function unstakeBatch(uint256[] memory tokenIds) external nonReentrant {
    for (uint256 i = 0; i < tokenIds.length; i++) {
      _unstake(msg.sender, tokenIds[i]);
    }
  }

  // Check if user has any ERC721 Tokens Staked and if they tried to withdraw,
  // decrement the amountStaked of the user and transfer the ERC721 token back to them
  function _unstake(address _addr, uint256 _tokenId) private {
    // Make sure the user has at least one token staked before withdrawing
    require(userAddrStakerMap[_addr].amountStaked > 0, "You have no tokens staked");

    // Wallet must own the token they are trying to withdraw
    require(tokenIdStakedTokenMap[_tokenId].fromAddr == _addr, "You don't own this token!");

    for (uint256 i = 0; i < userAddrStakerMap[_addr].tokenIds.length; i++) {
      if (userAddrStakerMap[_addr].tokenIds[i] == _tokenId) {
        // Staking time must more than 1 day
        require(
          tokenIdStakedTokenMap[_tokenId].tokenStakedAt + (stakingCooldownDurationInSeconds * 1 seconds) < block.timestamp,
          "Token still in staking cooldown time"
        );


        // Decrement the amount staked for this wallet
        userAddrStakerMap[_addr].amountStaked--;

        delete userAddrStakerMap[_addr].tokenIds[i];
        delete tokenIdStakedTokenMap[_tokenId];

        // Transfer the token back to the withdrawer
        nftCollection.transferFrom(address(this), _addr, _tokenId);

        emit Unstaked(_addr, _tokenId, tokenIdStakedTokenMap[_tokenId].tokenStakedAt);

        break;
      }
    }
  }

  // Function to get staked tokens of the staker.
  function getStakedTokensOfStaker(address _addr) external view returns (StakedToken[] memory) {
    // Check if we know this user
    if (userAddrStakerMap[_addr].amountStaked > 0) {
      // Return all the tokens in the stakedToken Array for this user that are not -1
      StakedToken[] memory _stakedTokens = new StakedToken[](
        userAddrStakerMap[_addr].amountStaked
      );

      uint256 _index = 0;
      for (uint256 i = 0; i < userAddrStakerMap[_addr].tokenIds.length; i++) {
        // the tokenId:0 can not be staked, so, we treat 0 as unstaked token. (we deleted the tokenIds[x] when unstake() invoked)
        if (userAddrStakerMap[_addr].tokenIds[i] != (0)) {
          _stakedTokens[_index] = tokenIdStakedTokenMap[userAddrStakerMap[_addr].tokenIds[i]];
          _index++;
        }
      }

      return _stakedTokens;
    }
    // Otherwise, return empty array
    else {
      return new StakedToken[](0);
    }
  }

  // Function to get all staked tokens.
  function getStakedTokens() external view returns (StakedToken[] memory) {
    uint256[] memory stakedTokenIds = _getTokenIdsOfOwner(address(this));

    StakedToken[] memory _stakedTokens = new StakedToken[](
      stakedTokenIds.length
    );

    for (uint256 i = 0; i < stakedTokenIds.length; i++) {
      _stakedTokens[i] = tokenIdStakedTokenMap[stakedTokenIds[i]];
    }

    return _stakedTokens;
  }

  // Function for client getting owner's tokens.
  function _getTokenIdsOfOwner(address _addr) private view returns (uint256[] memory) {
    bytes memory payload = abi.encodeWithSignature("getTokenIdsOfOwner(address)", _addr);
    (bool success, bytes memory returnData) = address(nftCollection).staticcall(payload);
    require(success, "Get response failed");

    return abi.decode(returnData, (uint256[]));
  }

  // Function for client getting unstaked and staked tokens at once.
  function getTokenIdsOfStaker(address _addr) external view returns (TokensOfOwner memory) {
    return TokensOfOwner(
      _getTokenIdsOfOwner(_addr), // unstaked tokenIds 
      this.getStakedTokensOfStaker(_addr) // staked tokenIds
    );
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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