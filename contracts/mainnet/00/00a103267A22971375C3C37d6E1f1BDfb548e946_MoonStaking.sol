/**
 *Submitted for verification at Etherscan.io on 2022-02-27
*/

pragma solidity ^0.8.7;
// SPDX-License-Identifier: MIT

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)
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

// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)
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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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


// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)
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


// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)
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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)
/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)
/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)
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


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)
/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)
/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)
/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)
/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}


contract MoonStaking is ERC1155Holder, Ownable, ReentrancyGuard {
    IERC721 public ApeNft;
    IERC721 public LootNft;
    IERC1155 public PetNft;
    IERC721 public TreasuryNft;
    IERC721 public BreedingNft;

    uint256 public constant SECONDS_IN_DAY = 86400;

    bool public stakingLaunched;
    bool public depositPaused;

    mapping(address => mapping(uint256 => uint256)) stakerPetAmounts;
    mapping(address => mapping(uint256 => uint256)) stakerApeLoot;

    struct Staker {
      uint256 currentYield;
      uint256 accumulatedAmount;
      uint256 lastCheckpoint;
      uint256[] stakedAPE;
      uint256[] stakedTREASURY;
      uint256[] stakedBREEDING;
      uint256[] stakedPET;
    }

    mapping(address => Staker) private _stakers;

    enum ContractTypes {
      APE,
      LOOT,
      PET,
      TREASURY,
      BREEDING
    }

    mapping(address => ContractTypes) private _contractTypes;

    mapping(address => uint256) public _baseRates;
    mapping(address => mapping(uint256 => uint256)) private _individualRates;
    mapping(address => mapping(uint256 => address)) private _ownerOfToken;
    mapping (address => bool) private _authorised;
    address[] public authorisedLog;

    event Stake721(address indexed staker,address contractAddress,uint256 tokensAmount);
    event StakeApesWithLoots(address indexed staker,uint256 apesAmount);
    event AddLootToStakedApes(address indexed staker,uint256 apesAmount);
    event RemoveLootFromStakedApes(address indexed staker,uint256 lootsAmount);
    event StakePets(address indexed staker,uint256 numberOfPetIds);
    event Unstake721(address indexed staker,address contractAddress,uint256 tokensAmount);
    event UnstakePets(address indexed staker,uint256 numberOfPetIds);
    event ForceWithdraw721(address indexed receiver, address indexed tokenAddress, uint256 indexed tokenId);
    

    constructor(address _ape) {
        ApeNft = IERC721(_ape);
        _contractTypes[_ape] = ContractTypes.APE;
        _baseRates[_ape] = 150 ether;
    }

    modifier authorised() {
      require(_authorised[_msgSender()], "The token contract is not authorised");
        _;
    }

    function stake721(address contractAddress, uint256[] memory tokenIds) public nonReentrant {
      require(!depositPaused, "Deposit paused");
      require(stakingLaunched, "Staking is not launched yet");
      require(contractAddress != address(0) && contractAddress == address(ApeNft) || contractAddress == address(TreasuryNft) || contractAddress == address(BreedingNft), "Unknown contract or staking is not yet enabled for this NFT");
      ContractTypes contractType = _contractTypes[contractAddress];

      Staker storage user = _stakers[_msgSender()];
      uint256 newYield = user.currentYield;

      for (uint256 i; i < tokenIds.length; i++) {
        require(IERC721(contractAddress).ownerOf(tokenIds[i]) == _msgSender(), "Not the owner of staking NFT");
        IERC721(contractAddress).safeTransferFrom(_msgSender(), address(this), tokenIds[i]);

        _ownerOfToken[contractAddress][tokenIds[i]] = _msgSender();

        newYield += getTokenYield(contractAddress, tokenIds[i]);

        if (contractType == ContractTypes.APE) { user.stakedAPE.push(tokenIds[i]); }
        if (contractType == ContractTypes.BREEDING) { user.stakedBREEDING.push(tokenIds[i]); }
        if (contractType == ContractTypes.TREASURY) { user.stakedTREASURY.push(tokenIds[i]); }
      }

      accumulate(_msgSender());
      user.currentYield = newYield;

      emit Stake721(_msgSender(), contractAddress, tokenIds.length);
    }

    function stake1155(uint256[] memory tokenIds, uint256[] memory amounts) public nonReentrant {
      require(!depositPaused, "Deposit paused");
      require(stakingLaunched, "Staking is not launched yet");
      require(address(PetNft) != address(0), "Moon Pets staking is not yet enabled");

      Staker storage user = _stakers[_msgSender()];
      uint256 newYield = user.currentYield;

      for (uint256 i; i < tokenIds.length; i++) {
        require(amounts[i] > 0, "Invalid amount");
        require(PetNft.balanceOf(_msgSender(), tokenIds[i]) >= amounts[i], "Not the owner of staking Pet or insufficiant balance of staking Pet");

        newYield += getPetTokenYield(tokenIds[i], amounts[i]);
        if (stakerPetAmounts[_msgSender()][tokenIds[i]] == 0){
            user.stakedPET.push(tokenIds[i]);
        }
        stakerPetAmounts[_msgSender()][tokenIds[i]] += amounts[i];
      }

      PetNft.safeBatchTransferFrom(_msgSender(), address(this), tokenIds, amounts, "");

      accumulate(_msgSender());
      user.currentYield = newYield;

      emit StakePets(_msgSender(), tokenIds.length);
    }

    function addLootToStakedApes(uint256[] memory apeIds, uint256[] memory lootIds) public nonReentrant {
      require(!depositPaused, "Deposit paused");
      require(stakingLaunched, "Staking is not launched yet");
      require(apeIds.length == lootIds.length, "Lists not same length");
      require(address(LootNft) != address(0), "Loot Bags staking is not yet enabled");

      Staker storage user = _stakers[_msgSender()];
      uint256 newYield = user.currentYield;

      for (uint256 i; i < apeIds.length; i++) {
        require(_ownerOfToken[address(ApeNft)][apeIds[i]] == _msgSender(), "Not the owner of staked Ape");
        require(stakerApeLoot[_msgSender()][apeIds[i]] == 0, "Selected staked Ape already has Loot staked together");
        require(lootIds[i] > 0, "Invalid Loot NFT");
        require(IERC721(address(LootNft)).ownerOf(lootIds[i]) == _msgSender(), "Not the owner of staking Loot");
        IERC721(address(LootNft)).safeTransferFrom(_msgSender(), address(this), lootIds[i]);

        _ownerOfToken[address(LootNft)][lootIds[i]] = _msgSender();

        newYield += getApeLootTokenYield(apeIds[i], lootIds[i]) - getTokenYield(address(ApeNft), apeIds[i]);

        stakerApeLoot[_msgSender()][apeIds[i]] = lootIds[i];
      }

      accumulate(_msgSender());
      user.currentYield = newYield;

      emit AddLootToStakedApes(_msgSender(), apeIds.length);
    }

    function removeLootFromStakedApes(uint256[] memory apeIds) public nonReentrant{
       Staker storage user = _stakers[_msgSender()];
       uint256 newYield = user.currentYield;

       for (uint256 i; i < apeIds.length; i++) {
        require(_ownerOfToken[address(ApeNft)][apeIds[i]] == _msgSender(), "Not the owner of staked Ape");
        uint256 ape_loot = stakerApeLoot[_msgSender()][apeIds[i]];
        require(ape_loot > 0, "Selected staked Ape does not have any Loot staked with");
        require(_ownerOfToken[address(LootNft)][ape_loot] == _msgSender(), "Not the owner of staked Ape");
        IERC721(address(LootNft)).safeTransferFrom(address(this), _msgSender(), ape_loot);

        _ownerOfToken[address(LootNft)][ape_loot] = address(0);

        newYield -= getApeLootTokenYield(apeIds[i], ape_loot);
        newYield += getTokenYield(address(ApeNft), apeIds[i]);

        stakerApeLoot[_msgSender()][apeIds[i]] = 0;
      }

      accumulate(_msgSender());
      user.currentYield = newYield;

      emit RemoveLootFromStakedApes(_msgSender(), apeIds.length);
    }

    function stakeApesWithLoots(uint256[] memory apeIds, uint256[] memory lootIds) public nonReentrant {
      require(!depositPaused, "Deposit paused");
      require(stakingLaunched, "Staking is not launched yet");
      require(apeIds.length == lootIds.length, "Lists not same length");
      require(address(LootNft) != address(0), "Loot Bags staking is not yet enabled");

      Staker storage user = _stakers[_msgSender()];
      uint256 newYield = user.currentYield;

      for (uint256 i; i < apeIds.length; i++) {
        require(IERC721(address(ApeNft)).ownerOf(apeIds[i]) == _msgSender(), "Not the owner of staking Ape");
        if (lootIds[i] > 0){
          require(IERC721(address(LootNft)).ownerOf(lootIds[i]) == _msgSender(), "Not the owner of staking Loot");
          IERC721(address(LootNft)).safeTransferFrom(_msgSender(), address(this), lootIds[i]);
          _ownerOfToken[address(LootNft)][lootIds[i]] = _msgSender();
          stakerApeLoot[_msgSender()][apeIds[i]] = lootIds[i];
        }
        
        IERC721(address(ApeNft)).safeTransferFrom(_msgSender(), address(this), apeIds[i]);
        _ownerOfToken[address(ApeNft)][apeIds[i]] = _msgSender();
        
        newYield += getApeLootTokenYield(apeIds[i], lootIds[i]);
        user.stakedAPE.push(apeIds[i]);
      }

      accumulate(_msgSender());
      user.currentYield = newYield;

      emit StakeApesWithLoots(_msgSender(), apeIds.length);
    }

    function unstake721(address contractAddress, uint256[] memory tokenIds) public nonReentrant {
      require(contractAddress != address(0) && contractAddress == address(ApeNft) || contractAddress == address(TreasuryNft) || contractAddress == address(BreedingNft), "Unknown contract or staking is not yet enabled for this NFT");
      ContractTypes contractType = _contractTypes[contractAddress];
      Staker storage user = _stakers[_msgSender()];
      uint256 newYield = user.currentYield;

      for (uint256 i; i < tokenIds.length; i++) {
        require(IERC721(contractAddress).ownerOf(tokenIds[i]) == address(this), "Not the owner");

        _ownerOfToken[contractAddress][tokenIds[i]] = address(0);

        if (user.currentYield != 0) {
            if (contractType == ContractTypes.APE){
                uint256 ape_loot = stakerApeLoot[_msgSender()][tokenIds[i]];
                uint256 tokenYield = getApeLootTokenYield(tokenIds[i], ape_loot);
                newYield -= tokenYield;
                if (ape_loot > 0){
                  IERC721(address(LootNft)).safeTransferFrom(address(this), _msgSender(), ape_loot);
                  _ownerOfToken[address(LootNft)][ape_loot] = address(0);
                }
                
            } else {
                uint256 tokenYield = getTokenYield(contractAddress, tokenIds[i]);
                newYield -= tokenYield;
            }
        }

        if (contractType == ContractTypes.APE) {
          user.stakedAPE = _prepareForDeletion(user.stakedAPE, tokenIds[i]);
          user.stakedAPE.pop();
          stakerApeLoot[_msgSender()][tokenIds[i]] = 0;
        }
        if (contractType == ContractTypes.TREASURY) {
          user.stakedTREASURY = _prepareForDeletion(user.stakedTREASURY, tokenIds[i]);
          user.stakedTREASURY.pop();
        }
        if (contractType == ContractTypes.BREEDING) {
          user.stakedBREEDING = _prepareForDeletion(user.stakedBREEDING, tokenIds[i]);
          user.stakedBREEDING.pop();
        }

        IERC721(contractAddress).safeTransferFrom(address(this), _msgSender(), tokenIds[i]);
      }

      if (user.stakedAPE.length == 0 && user.stakedTREASURY.length == 0 && user.stakedPET.length == 0 && user.stakedBREEDING.length == 0) {
        newYield = 0;
      }

      accumulate(_msgSender());
      user.currentYield = newYield;

      emit Unstake721(_msgSender(), contractAddress, tokenIds.length);
    }

    function unstake1155(uint256[] memory tokenIds) public nonReentrant {
      Staker storage user = _stakers[_msgSender()];
      uint256 newYield = user.currentYield;
      uint256[] memory transferAmounts = new uint256[](tokenIds.length);

      for (uint256 i; i < tokenIds.length; i++) {
        require(stakerPetAmounts[_msgSender()][tokenIds[i]] > 0, "Not the owner of staked Pet");
        transferAmounts[i] = stakerPetAmounts[_msgSender()][tokenIds[i]];

        newYield -= getPetTokenYield(tokenIds[i], transferAmounts[i]);

        user.stakedPET = _prepareForDeletion(user.stakedPET, tokenIds[i]);
        user.stakedPET.pop();
        stakerPetAmounts[_msgSender()][tokenIds[i]] = 0;
      }

      if (user.stakedAPE.length == 0 && user.stakedTREASURY.length == 0 && user.stakedPET.length == 0 && user.stakedBREEDING.length == 0) {
        newYield = 0;
      }
      PetNft.safeBatchTransferFrom(address(this), _msgSender(), tokenIds, transferAmounts, "");

      accumulate(_msgSender());
      user.currentYield = newYield;

      emit UnstakePets(_msgSender(), tokenIds.length);
    }

    function getTokenYield(address contractAddress, uint256 tokenId) public view returns (uint256) {
      uint256 tokenYield = _individualRates[contractAddress][tokenId];
      if (tokenYield == 0) { tokenYield = _baseRates[contractAddress]; }

      return tokenYield;
    }

    function getApeLootTokenYield(uint256 apeId, uint256 lootId) public view returns (uint256){
        uint256 apeYield = _individualRates[address(ApeNft)][apeId];
        if (apeYield == 0) { apeYield = _baseRates[address(ApeNft)]; }

        uint256 lootBoost = _individualRates[address(LootNft)][lootId];
        if (lootId == 0){
            lootBoost = 10;
        } else {
            if (lootBoost == 0) { lootBoost = _baseRates[address(LootNft)]; }
        }
        
        return apeYield * lootBoost / 10;
    }

    function getPetTokenYield(uint256 petId, uint256 amount) public view returns(uint256){
        uint256 petYield = _individualRates[address(PetNft)][petId];
        if (petYield == 0) { petYield = _baseRates[address(PetNft)]; }
        return petYield * amount;
    }

    function getStakerYield(address staker) public view returns (uint256) {
      return _stakers[staker].currentYield;
    }

    function getStakerNFT(address staker) public view returns (uint256[] memory, uint256[] memory, uint256[] memory, uint256[] memory, uint256[] memory) {
        uint256[] memory lootIds = new uint256[](_stakers[staker].stakedAPE.length);
        uint256[] memory petAmounts = new uint256[](8);
        for (uint256 i; i < _stakers[staker].stakedAPE.length; i++){
            lootIds[i] = stakerApeLoot[staker][_stakers[staker].stakedAPE[i]];
        }
        for (uint256 i; i < 8; i++){
            petAmounts[i] = stakerPetAmounts[staker][i];
        }
      return (_stakers[staker].stakedAPE, lootIds, _stakers[staker].stakedTREASURY, petAmounts, _stakers[staker].stakedBREEDING);
    }

    function _prepareForDeletion(uint256[] memory list, uint256 tokenId) internal pure returns (uint256[] memory) {
      uint256 tokenIndex = 0;
      uint256 lastTokenIndex = list.length - 1;
      uint256 length = list.length;

      for(uint256 i = 0; i < length; i++) {
        if (list[i] == tokenId) {
          tokenIndex = i + 1;
          break;
        }
      }
      require(tokenIndex != 0, "Not the owner or duplicate NFT in list");

      tokenIndex -= 1;

      if (tokenIndex != lastTokenIndex) {
        list[tokenIndex] = list[lastTokenIndex];
        list[lastTokenIndex] = tokenId;
      }

      return list;
    }

    function getCurrentReward(address staker) public view returns (uint256) {
      Staker memory user = _stakers[staker];
      if (user.lastCheckpoint == 0) { return 0; }
      return (block.timestamp - user.lastCheckpoint) * user.currentYield / SECONDS_IN_DAY;
    }

    function getAccumulatedAmount(address staker) external view returns (uint256) {
      return _stakers[staker].accumulatedAmount + getCurrentReward(staker);
    }

    function accumulate(address staker) internal {
      _stakers[staker].accumulatedAmount += getCurrentReward(staker);
      _stakers[staker].lastCheckpoint = block.timestamp;
    }

    /**
    * CONTRACTS
    */
    function ownerOf(address contractAddress, uint256 tokenId) public view returns (address) {
      return _ownerOfToken[contractAddress][tokenId];
    }

    function balanceOf(address user) public view returns (uint256){
      return _stakers[user].stakedAPE.length;
    }

    function setTREASURYContract(address _treasury, uint256 _baseReward) public onlyOwner {
      TreasuryNft = IERC721(_treasury);
      _contractTypes[_treasury] = ContractTypes.TREASURY;
      _baseRates[_treasury] = _baseReward;
    }

    function setPETContract(address _pet, uint256 _baseReward) public onlyOwner {
      PetNft = IERC1155(_pet);
      _contractTypes[_pet] = ContractTypes.PET;
      _baseRates[_pet] = _baseReward;
    }

    function setLOOTContract(address _loot, uint256 _baseBoost) public onlyOwner {
      LootNft = IERC721(_loot);
      _contractTypes[_loot] = ContractTypes.LOOT;
      _baseRates[_loot] = _baseBoost;
    }

    function setBREEDING(address _breeding, uint256 _baseReward) public onlyOwner{
      BreedingNft = IERC721(_breeding);
      _contractTypes[_breeding] = ContractTypes.BREEDING;
      _baseRates[_breeding] = _baseReward;
    }

    /**
    * ADMIN
    */
    function authorise(address toAuth) public onlyOwner {
      _authorised[toAuth] = true;
      authorisedLog.push(toAuth);
    }

    function unauthorise(address addressToUnAuth) public onlyOwner {
      _authorised[addressToUnAuth] = false;
    }

    function forceWithdraw721(address tokenAddress, uint256[] memory tokenIds) public onlyOwner {
      require(tokenIds.length <= 50, "50 is max per tx");
      pauseDeposit(true);
      for (uint256 i; i < tokenIds.length; i++) {
        address receiver = _ownerOfToken[tokenAddress][tokenIds[i]];
        if (receiver != address(0) && IERC721(tokenAddress).ownerOf(tokenIds[i]) == address(this)) {
          IERC721(tokenAddress).transferFrom(address(this), receiver, tokenIds[i]);
          emit ForceWithdraw721(receiver, tokenAddress, tokenIds[i]);
        }
      }
    }

    function pauseDeposit(bool _pause) public onlyOwner {
      depositPaused = _pause;
    }

    function launchStaking() public onlyOwner {
      require(!stakingLaunched, "Staking has been launched already");
      stakingLaunched = true;
    }

    function updateBaseYield(address _contract, uint256 _yield) public onlyOwner {
      _baseRates[_contract] = _yield;
    }

    function setIndividualRates(address contractAddress, uint256[] memory tokenIds, uint256[] memory rates) public onlyOwner{
        require(contractAddress != address(0) && contractAddress == address(ApeNft) || contractAddress == address(LootNft) || contractAddress == address(TreasuryNft) || contractAddress == address(PetNft), "Unknown contract");
        require(tokenIds.length == rates.length, "Lists not same length");
        for (uint256 i; i < tokenIds.length; i++){
            _individualRates[contractAddress][tokenIds[i]] = rates[i];
        }
    }

    function onERC721Received(address, address, uint256, bytes calldata) external pure returns(bytes4){
      return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }

    function withdrawETH() external onlyOwner {
      payable(owner()).transfer(address(this).balance);
    }
}