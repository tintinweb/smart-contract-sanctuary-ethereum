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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

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
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract MightyJaxxMarketplace is Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;

    Counters.Counter private _saleIdCounter;

    address public platformRoyaltyReceiver;
    uint256 public platformRoyaltyPercentage;

    mapping(address => bool) public supportedCollections;
    mapping(bytes32 => bool) private isOnSale;
    mapping(uint256 => SaleDetails) public saleDetails;
    mapping(address => CollectionRoyaltyInfo) public collectionRoyaltyInfo;

    struct SaleDetails {
        uint256 id;
        address seller;
        address nftAddress;
        uint256 nftId;
        uint256 price;
    }

    struct CollectionRoyaltyInfo {
        address receiver;
        uint256 royaltyPercentage;
    }

    event TokenPutOnSale(address indexed seller, SaleDetails saleDetails);
    event TokenBought(
        address indexed buyer,
        address indexed seller,
        address indexed nftAddress,
        uint256 price,
        uint256 nftId
    );
    event TokenRemovedFromSale(
        address indexed seller,
        address indexed nftAddress,
        uint256 nftId,
        uint256 saleId
    );
    event TokenSalePriceUpdated(
        uint256 saleId,
        uint256 oldPrice,
        uint256 newPrice
    );
    event SupportedCollectionAdded(address indexed collectionAddress);
    event SupportedCollectionRemoved(address indexed collectionAddress);
    event PlatformRoyaltyInfoAdded(
        address indexed newReceiver,
        uint256 newPercentage
    );
    event CollectionRoyaltyInfoAdded(
        address indexed collection,
        address indexed receiver,
        uint256 percentage
    );

    constructor(address _receiver, uint256 _perc) {
        platformRoyaltyReceiver = _receiver;
        platformRoyaltyPercentage = _perc;
    }

    function putTokenOnSale(
        address _nftAddress,
        uint256 _nftId,
        uint256 _price
    ) external {
        require(supportedCollections[_nftAddress], "Unsuppported collection.");
        require(_price != 0, "Price is zero.");
        require(
            IERC721(_nftAddress).ownerOf(_nftId) == msg.sender,
            "Not NFT owner."
        );
        require(
            IERC721(_nftAddress).isApprovedForAll(msg.sender, address(this)),
            "NFT not approved."
        );

        bytes32 saleHash = keccak256(abi.encodePacked(_nftAddress, _nftId));
        require(!isOnSale[saleHash], "NFT already on sale.");

        _saleIdCounter.increment();
        uint256 saleId = _saleIdCounter.current();

        SaleDetails storage _saleDetails = saleDetails[saleId];

        _saleDetails.id = saleId;
        _saleDetails.seller = msg.sender;
        _saleDetails.nftAddress = _nftAddress;
        _saleDetails.nftId = _nftId;
        _saleDetails.price = _price;
        isOnSale[saleHash] = true;

        emit TokenPutOnSale(msg.sender, _saleDetails);
    }

    function buyTokenFromSale(uint256 _saleId) external payable nonReentrant {
        SaleDetails memory _saleDetails = saleDetails[_saleId];

        uint256 price = _saleDetails.price;
        uint256 nftId = _saleDetails.nftId;
        address seller = _saleDetails.seller;
        address nftAddress = _saleDetails.nftAddress;

        require(seller != address(0), "NFT not for sale.");
        require(msg.value >= price, "Insufficient buy amount.");

        {
            CollectionRoyaltyInfo memory _royaltyInfo = collectionRoyaltyInfo[
                nftAddress
            ];

            address collectionRoyaltyReceiver = _royaltyInfo.receiver;
            uint256 collectionRoyaltyPerc = _royaltyInfo.royaltyPercentage;

            uint256 collectionRoyalty = (price * collectionRoyaltyPerc) /
                10_000;
            uint256 platformRoyalty = (price * platformRoyaltyPercentage) /
                10_000;

            (bool sendToCollection, ) = collectionRoyaltyReceiver.call{
                value: collectionRoyalty
            }("");
            require(sendToCollection, "send to collection royalty failed.");

            (bool sendToPlatform, ) = platformRoyaltyReceiver.call{
                value: platformRoyalty
            }("");
            require(sendToPlatform, "send to platform royalty failed.");

            (bool sendToSeller, ) = seller.call{
                value: price - collectionRoyalty - platformRoyalty
            }("");
            require(sendToSeller, "send to seller failed.");

            if (msg.value - price > 0) {
                (bool sendToBuyer, ) = msg.sender.call{
                    value: msg.value - price
                }("");
                require(sendToBuyer, "send to buyer failed.");
            }
        }

        delete isOnSale[keccak256(abi.encodePacked(nftAddress, nftId))];
        delete saleDetails[_saleId];

        emit TokenBought(msg.sender, seller, nftAddress, price, nftId);

        IERC721(nftAddress).safeTransferFrom(seller, msg.sender, nftId);
    }

    function removeTokenFromSale(uint256 _saleId) external {
        SaleDetails memory _saleDetails = saleDetails[_saleId];

        uint256 nftId = _saleDetails.nftId;
        address seller = _saleDetails.seller;
        address nftAddress = _saleDetails.nftAddress;

        delete isOnSale[keccak256(abi.encodePacked(nftAddress, nftId))];
        delete saleDetails[_saleId];

        require(seller != address(0), "NFT not for sale.");
        require(msg.sender == seller, "Only seller can remove.");

        emit TokenRemovedFromSale(seller, nftAddress, nftId, _saleId);
    }

    function changeTokenSalePrice(uint256 _saleId, uint256 newPrice) external {
        SaleDetails storage _saleDetails = saleDetails[_saleId];

        address seller = _saleDetails.seller;
        uint256 oldPrice = _saleDetails.price;

        require(seller != address(0), "NFT not for sale.");
        require(msg.sender == seller, "Only seller can update.");

        _saleDetails.price = newPrice;

        emit TokenSalePriceUpdated(_saleId, oldPrice, newPrice);
    }

    function addSupportedCollection(address _collectionAddress)
        external
        onlyOwner
    {
        supportedCollections[_collectionAddress] = true;

        emit SupportedCollectionAdded(_collectionAddress);
    }

    function removeSupportedCollection(address _collectionAddress)
        external
        onlyOwner
    {
        supportedCollections[_collectionAddress] = false;

        emit SupportedCollectionRemoved(_collectionAddress);
    }

    function setPlatformRoyaltyInfo(
        address _royaltyReceiver,
        uint256 _percentage
    ) external onlyOwner {
        platformRoyaltyReceiver = _royaltyReceiver;
        platformRoyaltyPercentage = _percentage;

        emit PlatformRoyaltyInfoAdded(_royaltyReceiver, _percentage);
    }

    function setCollectionRoyaltyInfo(
        address _collection,
        address _royaltyReceiver,
        uint256 _royaltyPercentage
    ) external onlyOwner {
        CollectionRoyaltyInfo
            storage _collectionRoyaltyInfo = collectionRoyaltyInfo[_collection];

        _collectionRoyaltyInfo.receiver = _royaltyReceiver;
        _collectionRoyaltyInfo.royaltyPercentage = _royaltyPercentage;

        emit CollectionRoyaltyInfoAdded(
            _collection,
            _royaltyReceiver,
            _royaltyPercentage
        );
    }

    function fundsAvailable() public view returns (uint256 contractBalance) {
        return address(this).balance;
    }

    function withdrawFunds() external onlyOwner {
        uint256 contractBal = fundsAvailable();

        (bool sent, ) = msg.sender.call{value: contractBal}("");
        require(sent, "Failed to send Ether");
    }

    receive() external payable {}
}