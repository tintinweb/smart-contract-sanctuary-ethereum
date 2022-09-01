// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin-4.7/contracts/access/Ownable.sol";

import "./interfaces/IGashapondo.sol";
import "./interfaces/IPrizeRedemption.sol";

contract PrizeRedemption is Ownable, IPrizeRedemption {
    uint256 public constant ONE_MILLION = 1_000_000;
    bytes32 public constant PRIZE_ADDED_NEW = keccak256("ADDED_NEW");
    bytes32 public constant PRIZE_UPDATED_NAME = keccak256("UPDATED_NAME");
    bytes32 public constant PRIZE_UPDATED_DESCRIPTION = keccak256("UPDATED_DESCRIPTION");
    bytes32 public constant PRIZE_UPDATED_TOTAL = keccak256("UPDATED_TOTAL");
    bytes32 public constant PRIZE_UPDATED_REQUIREMENT = keccak256("UPDATED_REQUIREMENT");
    bytes32 public constant PRIZE_UPDATED_PRIZE_COLLECTION = keccak256("UPDATED_PRIZE_COLLECTION");
    bytes32 public constant PRIZE_UPDATED_STATE = keccak256("PRIZE_UPDATED_STATE");
    bytes32 public constant PRIZE_REDEEMED = keccak256("REDEEMED");
    bytes32 public constant PLATFORM_ADDED_ADMIN = keccak256("ADDED_ADMIN");
    bytes32 public constant PLATFORM_REMOVED_ADMIN = keccak256("REMOVED_ADMIN");

    IGashapondo public gashapondoContract;
    mapping(address => bool) public admins;

    mapping(uint256 => mapping(uint256 => bool)) public redeemedTokenIdsInPrize;

    mapping(uint256 => Prize) private _prizes;
    uint256 private _prizeCount;

    constructor(address gashapondo) {
        gashapondoContract = IGashapondo(gashapondo);
    }

    /**
     * @dev Throws if called by any account other than admins.
     */
    modifier onlyAdmin() {
        require(admins[_msgSender()], "Caller is not the admin");
        _;
    }

    /**
     * @dev Throws if invalid state.
     */
    modifier whenInState(PrizeState state, uint256 prizeId) {
        require(_prizes[prizeId].state == state, "Invalid state");
        _;
    }

    /**
     * @dev Throws if not exist
     */
    modifier prizeExists(uint256 prizeId) {
        require(prizeId <= _prizeCount, "Prize does not exist");
        _;
    }

    /** ----external functions - BEGIN-----*/

    function redeem(
        address to,
        uint256 prizeId,
        uint24 slots,
        uint256[] calldata tokenIds
    ) external override prizeExists(prizeId) whenInState(PrizeState.ACTIVE, prizeId) {
        // CHECKS
        Prize memory prize = _prizes[prizeId];
        require(prize.redeemed + slots <= prize.total, "Not enough slots to redeem");
        require(slots * prize.tokensRequired == tokenIds.length, "Token ids must match slots");
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(gashapondoContract.ownerOf(tokenIds[i]) == _msgSender(), "Not the ower of token");
            require(tokenIds[i] / ONE_MILLION == prize.requiredCollectionId, "Incorrect token of required collection");
            require(redeemedTokenIdsInPrize[prizeId][tokenIds[i]] == false, "A token has already been used");
        }

        // EFFECTS
        for (uint256 i = 0; i < tokenIds.length; i++) {
            redeemedTokenIdsInPrize[prizeId][tokenIds[i]] = true;
        }
        uint24 redeemed = prize.redeemed + slots;
        _prizes[prizeId].redeemed = redeemed;
        if (redeemed == prize.total) {
            prize.state = PrizeState.COMPLETED;
            prize.endDate = uint24(block.timestamp);
        }

        // INTERACTIONS
        gashapondoContract.mintBatch(to, _prizes[prizeId].prizeCollectionId, slots);
        emit PrizeUpdated(prizeId, PRIZE_REDEEMED);
    }

    function setGashapondo(address gashapondo) external onlyOwner {
        gashapondoContract = IGashapondo(gashapondo);
    }

    /**
     * Add a new admin
     */
    function addAdmin(address admin) external override onlyOwner {
        admins[admin] = true;
        emit PlatformUpdated(PLATFORM_ADDED_ADMIN);
    }

    /**
     * Remove admin
     */
    function removeAdmin(address admin) external override onlyOwner {
        admins[admin] = false;
        emit PlatformUpdated(PLATFORM_REMOVED_ADMIN);
    }

    function addPrize(
        string calldata name,
        string calldata description,
        uint24 total,
        uint256 requiredCollectionId,
        uint24 tokensRequired,
        uint256 prizeCollectionId
    ) external override onlyAdmin returns (uint256 prizeId) {
        _prizeCount += 1; // start from 1
        prizeId = _prizeCount;
        _prizes[prizeId].name = name;
        _prizes[prizeId].description = description;
        _prizes[prizeId].total = total;
        _prizes[prizeId].requiredCollectionId = requiredCollectionId;
        _prizes[prizeId].tokensRequired = tokensRequired;
        _prizes[prizeId].prizeCollectionId = prizeCollectionId;
        emit PrizeUpdated(prizeId, PRIZE_ADDED_NEW);
    }

    function setPrizeName(uint256 prizeId, string calldata name) external override onlyAdmin prizeExists(prizeId) {
        _prizes[prizeId].name = name;
        emit PrizeUpdated(prizeId, PRIZE_UPDATED_NAME);
    }

    function setPrizeDescription(uint256 prizeId, string calldata description)
        external
        override
        onlyAdmin
        prizeExists(prizeId)
    {
        _prizes[prizeId].description = description;
        emit PrizeUpdated(prizeId, PRIZE_UPDATED_DESCRIPTION);
    }

    function setPrizeTotal(uint256 prizeId, uint24 total) external override onlyAdmin prizeExists(prizeId) {
        _prizes[prizeId].total = total;
        emit PrizeUpdated(prizeId, PRIZE_UPDATED_TOTAL);
    }

    function setPrizeRequirement(
        uint256 prizeId,
        uint256 requiredCollectionId,
        uint24 tokensRequired
    ) external override onlyAdmin prizeExists(prizeId) {
        _prizes[prizeId].requiredCollectionId = requiredCollectionId;
        _prizes[prizeId].tokensRequired = tokensRequired;
        emit PrizeUpdated(prizeId, PRIZE_UPDATED_REQUIREMENT);
    }

    function setPrizeCollection(uint256 prizeId, uint256 prizeCollectionId)
        external
        override
        onlyAdmin
        prizeExists(prizeId)
    {
        _prizes[prizeId].prizeCollectionId = prizeCollectionId;
        emit PrizeUpdated(prizeId, PRIZE_UPDATED_PRIZE_COLLECTION);
    }

    function setPrizeState(uint256 prizeId, PrizeState nextState) external override onlyAdmin prizeExists(prizeId) {
        PrizeState currentState = _prizes[prizeId].state;
        require(currentState != PrizeState.COMPLETED, "Cannot change state anymore");
        if (currentState == PrizeState.DRAFT) {
            require(nextState == PrizeState.ACTIVE, "Only able to change to ACTIVE");
            _prizes[prizeId].startDate = uint24(block.timestamp);
        } else if (currentState == PrizeState.ACTIVE) {
            require(nextState == PrizeState.PAUSED, "Only able to change to PAUSED");
        } else {
            require(nextState == PrizeState.ACTIVE, "Only able to change to ACTIVE");
        }
        _prizes[prizeId].state = nextState;
        emit PrizeUpdated(prizeId, PRIZE_UPDATED_STATE);
    }

    function getPrize(uint256 prizeId) external view override returns (Prize memory prize) {
        prize = _prizes[prizeId];
    }

    function getPrizeCount() external view override returns (uint256 count) {
        count = _prizeCount;
    }

    function isRedeemed(uint256 prizeId, uint256[] calldata tokenIds)
        external
        view
        override
        returns (bool[] memory statuses)
    {
        statuses = new bool[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            statuses[i] = redeemedTokenIdsInPrize[prizeId][tokenId];
        }
    }

    /** ----external functions - END-----*/
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin-4.7/contracts/token/ERC721/IERC721.sol";

/**
 * TODO: add collection metadata
 */
interface IGashapondo is IERC721 {
    enum CollectionState {
        DRAFT,
        ACTIVE,
        PAUSED,
        LOCKED,
        COMPLETED,
        FROZEN
    }

    struct Collection {
        uint24 totalTokens;
        uint24 minted;
        uint24 metadataCount;
        uint24 maxPurchasePerTx;
        uint24 startDate;
        uint24 endDate;
        bool useIpfs;
        bool useRandomTokenId;
        address payable authorAddress;
        CollectionState state;
        string name;
        string baseUri;
        string tokenUriSuffix;
        string author;
        string description;
        string websiteUri;
        string license;
        string imageUri;
    }

    struct CollectionMintPrice {
        uint256 gasPriceInWei;
        mapping(address => bool) acceptedErc20Tokens;
        mapping(address => uint256) erc20TokenPricesInWei;
    }

    struct CollectionPayment {
        mapping(uint256 => address payable) additionalPayees;
        mapping(uint256 => uint256) additionalPayeePercentages;
        uint256 numberOfAddtionalPayees;
    }

    struct PayeeInfo {
        address payable addr;
        uint256 percentage;
    }

    struct PaymentMetadata {
        address payable authorAddress;
        address payable platformPrimarySalesAddress;
        uint256 platformPrimarySalesPercentage;
        PayeeInfo[] payees;
    }

    event CollectionUpdated(uint256 indexed collectionId, bytes32 eventName);
    event PlatformUpdated(bytes32 eventName);

    function mint(address to, uint256 collectionId) external returns (uint256 tokenId);

    function mintBatch(
        address to,
        uint256 collectionId,
        uint24 numberOfTokens
    ) external returns (uint256[] memory tokenIds);

    function setRandomizer(address randomizer) external;

    function setPlatformPrimarySalesAddress(address payable addr) external;

    function setPlatformPrimarySalesPercentage(uint256 newPercentage) external;

    function addAdmin(address admin) external;

    function removeAdmin(address admin) external;

    function addMinter(uint256 collectionId, address minter) external;

    function removeMinter(uint256 collectionId, address minter) external;

    function addCollection(
        string calldata name,
        address payable authorAddress,
        string calldata baseUri,
        string calldata tokenUriSuffix,
        bool useIpfs,
        bool useRandomTokenId,
        uint24 totalTokens,
        uint24 maxPurchasePerTx
    ) external returns (uint256 collectionId);

    function setCollectionGasPriceInWei(uint256 collectionId, uint256 gasPriceInWei) external;

    function setCollectionErc20PriceInWei(
        uint256 collectionId,
        address[] calldata erc20Tokens,
        bool[] calldata supported,
        uint256[] calldata pricesInWei
    ) external;

    function addPayees(
        uint256 collectionId,
        address payable[] calldata payees,
        uint256[] calldata percentages
    ) external;

    function removeLastPayees(uint256 collectionId, uint256 numberOfLastPayees) external;

    function setCollectionName(uint256 collectionId, string calldata name) external;

    function setCollectionAuthorAddress(uint256 collectionId, address payable authorAddress) external;

    function setCollectionTokenUri(
        uint256 collectionId,
        string calldata baseUri,
        string calldata tokenUriSuffix,
        bool useIpfs
    ) external;

    function setCollectionRandomTokenId(uint256 collectionId, bool useRandomTokenId) external;

    function setCollectionTotalTokens(uint256 collectionId, uint24 totalTokens) external;

    function setCollectionMaxPurchasePerTx(uint256 collectionId, uint24 maxPurchasePerTx) external;

    function setCollectionState(uint256 collectionId, CollectionState nextState) external;

    function togglePaused(uint256 collectionId) external;

    function setCollectionAuthor(uint256 collectionId, string calldata author) external;

    function setCollectionDescription(uint256 collectionId, string calldata description) external;

    function setCollectionWebsiteUri(uint256 collectionId, string calldata websiteUri) external;

    function setCollectionLicense(uint256 collectionId, string calldata license) external;

    function setCollectionImageUri(uint256 collectionId, string calldata imageUri) external;

    function getCollection(uint256 collectionId) external view returns (Collection memory collection);

    function getCollectionGasPriceInWei(uint256 collectionId) external view returns (uint256 gasPriceInWei);

    function getCollectionErc20TokenPrice(uint256 collectionId, address erc20Token)
        external
        view
        returns (uint256 priceInWei);

    function isErc20TokenPaymentSupported(uint256 collectionId, address erc20Token)
        external
        view
        returns (bool supported);

    function getCollectionPaymentMetadata(uint256 collectionId)
        external
        view
        returns (PaymentMetadata memory paymentMetadata);

    function getCollectionCount() external view returns (uint256 count);

    function platformPrimarySalesPercentage() external view returns (uint256 percentage);

    function getCollectionId(uint256 tokenId) external pure returns (uint256 collectionId);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IPrizeRedemption {
    enum PrizeState {
        DRAFT,
        ACTIVE,
        PAUSED,
        COMPLETED
    }

    struct Prize {
        uint24 total;
        uint24 redeemed;
        uint24 tokensRequired;
        uint24 startDate;
        uint24 endDate;
        PrizeState state;
        uint256 requiredCollectionId;
        uint256 prizeCollectionId;
        string name;
        string description;
    }

    event PrizeUpdated(uint256 indexed prizeId, bytes32 eventName);
    event PlatformUpdated(bytes32 eventName);

    function redeem(
        address to,
        uint256 prizeId,
        uint24 slots,
        uint256[] calldata tokenIds
    ) external;

    function addAdmin(address admin) external;

    function removeAdmin(address admin) external;

    function addPrize(
        string calldata name,
        string calldata description,
        uint24 total,
        uint256 requiredCollectionId,
        uint24 tokensRequired,
        uint256 prizeCollectionId
    ) external returns (uint256 prizeId);

    function setPrizeName(uint256 prizeId, string calldata name) external;

    function setPrizeDescription(uint256 prizeId, string calldata description) external;

    function setPrizeTotal(uint256 prizeId, uint24 total) external;

    function setPrizeRequirement(
        uint256 prizeId,
        uint256 requiredCollectionId,
        uint24 tokensRequired
    ) external;

    function setPrizeCollection(uint256 prizeId, uint256 prizeCollectionId) external;

    function setPrizeState(uint256 prizeId, PrizeState nextState) external;

    function getPrize(uint256 prizeId) external view returns (Prize memory prize);

    function getPrizeCount() external view returns (uint256 count);

    function isRedeemed(uint256 prizeId, uint256[] calldata tokenIds) external view returns (bool[] memory statuses);
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