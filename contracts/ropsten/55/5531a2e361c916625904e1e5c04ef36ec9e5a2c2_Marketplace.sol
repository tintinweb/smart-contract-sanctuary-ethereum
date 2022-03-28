/**
 *Submitted for verification at Etherscan.io on 2022-03-28
*/

// SPDX-License-Identifier: MIT
// Sources flattened with hardhat v2.5.0 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]


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


// File @openzeppelin/contracts/access/[email protected]


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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


// File @openzeppelin/contracts/security/[email protected]


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
     * by making the `nonReentrant` function external, and make it call a
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


// File @openzeppelin/contracts/utils/introspection/[email protected]


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


// File @openzeppelin/contracts/token/ERC721/[email protected]


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


// File @openzeppelin/contracts/token/ERC1155/[email protected]


pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts/token/ERC20/[email protected]


pragma solidity ^0.8.0;

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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


// File @openzeppelin/contracts/utils/[email protected]


pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}


// File contracts/interfaces/IFeeProvider.sol


pragma solidity ^0.8.0;

interface IFeeProvider {
    event FeeChanged(uint256 oldPercentFee, uint256 newPercentFee);

    function dev() external view returns (address);

    function devFeePercent() external view returns (uint256);

    function nftContractToFeePercent(address nftContract) external view returns (uint256);

    function nftContractToOwner(address nftContract) external view returns (address);
}


// File contracts/interfaces/IMarketplace.sol


pragma solidity ^0.8.0;

interface IMarketplace {
    struct Listing {
        uint256 listingId;
        address nftContract;
        uint256 tokenId;
        address exchangeToken; // if exchangeToken is address(0), it means order accept native coin
        uint256 price;
        address seller;
        address buyer;
        uint256 createdAt;
        uint256 withdrawnAt;
        uint256 soldAt;
        bool isKAP1155;
    }

    event ListingCreated(
        address indexed seller,
        address indexed nftContract,
        uint256 indexed tokenId,
        uint256 price,
        uint256 createdAt,
        uint256 listingId
    );
    event ItemSold(
        address indexed buyer,
        address indexed nftContract,
        uint256 indexed tokenId,
        address seller,
        uint256 soldAt,
        uint256 listingId
    );
    event ItemWithdrawn(
        address indexed seller,
        address indexed nftContract,
        uint256 indexed tokenId,
        uint256 withdrawnAt,
        uint256 listingId
    );

    function listingItem(
        address _nftContract,
        uint256 _tokenId,
        address _exchangeToken,
        uint256 _price,
        bool isKAP1155
    ) external;

    function delegateListingItem(
        address _seller,
        address _nftContract,
        uint256 _tokenId,
        address _exchangeToken,
        uint256 _price,
        bool isKAP1155
    ) external;

    function withdrawItem(uint256 _listingIdx) external;

    function delegateWithdrawItem(uint256 _listingIdx, address _seller) external;

    function buyWithKUB(uint256 _listingIdx) external payable;

    function buyWithToken(uint256 _listingIdx, uint256 _submitAmount) external;

    function delegateBuyWithToken(
        uint256 _listingIdx,
        address _buyer,
        uint256 _submitAmount
    ) external;
}


// File contracts/interfaces/IKKUB.sol


pragma solidity ^0.8.0;

interface IKKUB {
    function deposit() external payable;

    function withdraw(uint256 value) external;
}


// File contracts/interfaces/IItemHistoryStorage.sol


pragma solidity ^0.8.0;

interface IItemHistoryStorage {
    function addHistory(address nftContract, uint256 tokenId) external;
}


// File @openzeppelin/contracts/utils/introspection/[email protected]


pragma solidity ^0.8.0;

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


// File contracts/interfaces/IKAP1155Receiver.sol


pragma solidity ^0.8.0;

interface IKAP1155Receiver is IERC165 {
    function onKAP1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    function onKAP1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}


// File contracts/abstracts/KAP1155Receiver.sol


pragma solidity ^0.8.0;



abstract contract KAP1155Receiver is ERC165, IKAP1155Receiver {
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IKAP1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}


// File contracts/Marketplace.sol


pragma solidity ^0.8.0;









contract Marketplace is Ownable, ReentrancyGuard, IMarketplace, KAP1155Receiver {
    using Counters for Counters.Counter;
    Counters.Counter private _allListingCount;
    Counters.Counter private _withdrawListingCount;
    Counters.Counter private _soldListingCount;

    IFeeProvider public feeProvider;
    IItemHistoryStorage public itemHistoryStorage;
    address public wrappedKUB;

    mapping(uint256 => Listing) public idToListing;
    mapping(address => uint256[]) public sellerToListingId;
    mapping(uint256 => uint256[]) public listingHistory;

    constructor(IFeeProvider _feeProvider, address _wrappedKUB) {
        feeProvider = _feeProvider;
        wrappedKUB = _wrappedKUB;
    }

    function updateFeeProvider(IFeeProvider _feeProvider) public onlyOwner {
        feeProvider = _feeProvider;
    }

    function setItemHistoryStorage(IItemHistoryStorage _itemHistoryStorage) public onlyOwner {
        itemHistoryStorage = _itemHistoryStorage;
    }

    function listingItem(
        address _nftContract,
        uint256 _tokenId,
        address _exchangeToken,
        uint256 _price,
        bool isKAP1155
    ) public override nonReentrant {
        _listingItem(msg.sender, _nftContract, _tokenId, _exchangeToken, _price, address(0), isKAP1155);
    }

    function delegateListingItem(
        address _seller,
        address _nftContract,
        uint256 _tokenId,
        address _exchangeToken,
        uint256 _price,
        bool isKAP1155
    ) public override nonReentrant {
        _listingItem(_seller, _nftContract, _tokenId, _exchangeToken, _price, msg.sender, isKAP1155);
    }

    function _listingItem(
        address _seller,
        address _nftContract,
        uint256 _tokenId,
        address _exchangeToken,
        uint256 _price,
        address delegator,
        bool isKAP1155
    ) private {
        require(_price > 0, "KAP721MarketPlace: Price must be at least 1 wei");
        _allListingCount.increment();
        uint256 listingId = _allListingCount.current();

        Listing memory listing = Listing(
            listingId,
            _nftContract,
            _tokenId,
            _exchangeToken == address(0) ? wrappedKUB : _exchangeToken,
            _price,
            _seller,
            address(0),
            block.timestamp,
            0,
            0,
            isKAP1155
        );

        idToListing[listingId] = listing;
        listingHistory[listingId].push(block.number);
        sellerToListingId[_seller].push(listingId);

        if (!isKAP1155) {
            itemHistoryStorage.addHistory(_nftContract, _tokenId);
        }

        if (delegator != address(0)) {
            if (!isKAP1155) {
                IERC721(_nftContract).transferFrom(delegator, address(this), _tokenId);
            } else {
                IERC1155(_nftContract).safeTransferFrom(delegator, address(this), _tokenId, 1, "");
            }
        } else {
            if (!isKAP1155) {
                IERC721(_nftContract).transferFrom(_seller, address(this), _tokenId);
            } else {
                IERC1155(_nftContract).safeTransferFrom(_seller, address(this), _tokenId, 1, "");
            }
        }

        emit ListingCreated(_seller, _nftContract, _tokenId, _price, block.timestamp, listingId);
    }

    function withdrawItem(uint256 _listingId) public override nonReentrant {
        _withdrawItem(_listingId, msg.sender);
    }

    function delegateWithdrawItem(uint256 _listingId, address _seller) public override nonReentrant {
        _withdrawItem(_listingId, _seller);
    }

    function _withdrawItem(uint256 _listingId, address _seller) private {
        Listing storage listing = idToListing[_listingId];

        address nftContract = listing.nftContract;
        uint256 tokenId = listing.tokenId;
        address seller = listing.seller;
        bool isKAP1155 = listing.isKAP1155;

        require(
            listing.soldAt == 0 && listing.withdrawnAt == 0,
            "KAP721MarketPlace: This listing has already been sold or withdrawn"
        );
        require(seller == _seller, "KAP721MarketPlace: Only seller can withdraw item");

        if (!isKAP1155) {
            IERC721(nftContract).transferFrom(address(this), _seller, tokenId);
        } else {
            IERC1155(nftContract).safeTransferFrom(address(this), _seller, tokenId, 1, "");
        }

        _withdrawListingCount.increment();
        listing.withdrawnAt = block.timestamp;
        listingHistory[_listingId].push(block.number);

        if (!listing.isKAP1155) {
            itemHistoryStorage.addHistory(nftContract, tokenId);
        }

        emit ItemWithdrawn(_seller, nftContract, tokenId, block.timestamp, _listingId);
    }

    function buyWithKUB(uint256 _listingId) public payable override nonReentrant {
        IKKUB(wrappedKUB).deposit{ value: msg.value }();
        _buy(_listingId, true, msg.value, msg.sender, address(0));
    }

    function buyWithToken(uint256 _listingId, uint256 _submitAmount) public override nonReentrant {
        _buy(_listingId, false, _submitAmount, msg.sender, address(0));
    }

    function delegateBuyWithToken(
        uint256 _listingId,
        address _buyer,
        uint256 _submitAmount
    ) public override nonReentrant {
        _buy(_listingId, false, _submitAmount, _buyer, msg.sender);
    }

    function allListingsCount() external view returns (uint256) {
        return _allListingCount.current();
    }

    function allWithdrawListingCount() external view returns (uint256) {
        return _withdrawListingCount.current();
    }

    function allSoldListingCount() external view returns (uint256) {
        return _soldListingCount.current();
    }

    function allListingsCountBySeller(address seller) external view returns (uint256) {
        return sellerToListingId[seller].length;
    }

    function allListingHistoryLength(uint256 _listingId) external view returns (uint256) {
        return listingHistory[_listingId].length;
    }

    function _buy(
        uint256 _listingId,
        bool _isFromBuyWithKUB,
        uint256 _submitAmount,
        address _buyer,
        address delegator
    ) internal {
        Listing storage listing = idToListing[_listingId];

        address nftContract = listing.nftContract;
        uint256 tokenId = listing.tokenId;
        address seller = listing.seller;
        address exchangeToken = listing.exchangeToken;
        uint256 price = listing.price;

        require(
            listing.soldAt == 0 && listing.withdrawnAt == 0,
            "KAP721MarketPlace: This listing has already been sold or withdrawn"
        );
        require(_submitAmount > 0 && _submitAmount == price, "KAP721MarketPlace: Submit amount do not match listing");

        if (!_isFromBuyWithKUB) {
            if (delegator != address(0)) {
                require(
                    IERC20(exchangeToken).transferFrom(delegator, address(this), _submitAmount),
                    "KAP721MarketPlace: Payment transfer to marketplace failed"
                );
            } else {
                require(
                    IERC20(exchangeToken).transferFrom(_buyer, address(this), _submitAmount),
                    "KAP721MarketPlace: Payment transfer to marketplace failed"
                );
            }
        }

        {
            uint256 devFee = (price * feeProvider.devFeePercent()) / 10000;
            uint256 nftOwnerFee = (price * feeProvider.nftContractToFeePercent(nftContract)) / 10000;

            address devAddress = feeProvider.dev();
            address nftOwner = feeProvider.nftContractToOwner(nftContract);
            if (devAddress != address(0)) {
                IERC20(exchangeToken).transfer(devAddress, devFee);
            }

            if (nftOwner != address(0)) {
                IERC20(exchangeToken).transfer(nftOwner, nftOwnerFee);
            }

            IERC20(exchangeToken).transfer(seller, price - devFee - nftOwnerFee);
        }

        if (!listing.isKAP1155) {
            IERC721(nftContract).transferFrom(address(this), _buyer, tokenId);
        } else {
            IERC1155(nftContract).safeTransferFrom(address(this), _buyer, tokenId, 1, "");
        }

        _soldListingCount.increment();
        listing.buyer = _buyer;
        listing.soldAt = block.timestamp;
        listingHistory[_listingId].push(block.number);

        if (!listing.isKAP1155) {
            itemHistoryStorage.addHistory(nftContract, tokenId);
        }

        emit ItemSold(_buyer, nftContract, tokenId, seller, block.timestamp, listing.listingId);
    }

    function onKAP1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external pure override returns (bytes4) {
        return this.onKAP1155Received.selector;
    }

    function onKAP1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external pure override returns (bytes4) {
        return this.onKAP1155BatchReceived.selector;
    }
}