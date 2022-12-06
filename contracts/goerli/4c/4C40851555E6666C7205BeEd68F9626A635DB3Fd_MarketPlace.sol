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

pragma solidity ^0.8.9;

interface IMarketPlace {
    error Unauthorized(address caller);
    error PriceNotCovered();
    error UnavailableAction(uint256 itemId);

    event ItemListed(address indexed from, uint256 itemId, uint256 price);
    event ItemDeleted(address indexed from, uint256 itemId);
    event Sale(
        address indexed from,
        address indexed to,
        uint256 itemId,
        uint256 price
    );
    event Offer(
        address indexed from,
        address indexed to,
        uint256 itemId,
        uint256 price
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interface/IMarketErrors.sol";

contract MarketPlace is Ownable, IMarketPlace {
    using Counters for Counters.Counter;
    Counters.Counter private _itemId;

    uint256 private _listingPrice = 0.0025 ether;
    uint256 _ownerPercent = 5;

    enum ListingType {
        AUCTION,
        SALE
    }

    function setListingPrice(uint256 price) external onlyOwner {
        _listingPrice = price;
    }

    function setOwnerPercent(uint256 percent_) external onlyOwner {
        _ownerPercent = percent_;
    }

    function getListingPrice() external view returns (uint256) {
        return _listingPrice;
    }

    function _checkTimeRange(
        uint256 endTime,
        uint256 startTime,
        uint256 itemId
    ) internal view {
        if (block.timestamp > endTime && endTime > 0)
            revert UnavailableAction(itemId);
        if (block.timestamp < startTime) revert UnavailableAction(itemId);
    }

    struct Item {
        uint256 itemId;
        address erc721;
        uint256 tokenId;
        address owner;
        uint256 endTime;
        uint256 startTime;
        uint256 price;
        address bidder;
        ListingType listingType;
    }

    mapping(uint256 => Item) public _items;

    function listItem(
        address erc721Address,
        uint256 tokenId,
        uint256 endTime,
        uint256 startTime,
        uint256 price,
        uint8 listingType
    ) external payable {
        if (msg.value != _listingPrice) {
            revert PriceNotCovered();
        }
        IERC721 erc721 = IERC721(erc721Address);
        if (erc721.ownerOf(tokenId) != msg.sender) {
            revert Unauthorized(msg.sender);
        }
        _itemId.increment();
        uint256 currentId = _itemId.current();

        _items[currentId] = Item(
            currentId,
            erc721Address,
            tokenId,
            msg.sender,
            endTime,
            startTime,
            price,
            address(0),
            ListingType(listingType)
        );

        erc721.transferFrom(msg.sender, address(this), tokenId);
        payable(owner()).transfer(_listingPrice);
        emit ItemListed(msg.sender, currentId, price);
    }

    function _transferItem(Item memory item, address to) internal {
        delete _items[item.itemId];
        IERC721(item.erc721).transferFrom(address(this), to, item.tokenId);
    }

    function deleteListing(uint256 itemId) external {
        Item memory item = _items[itemId];
        if (item.owner != msg.sender) {
            revert Unauthorized(msg.sender);
        }

        if (block.timestamp < item.endTime)
            revert UnavailableAction(item.itemId);

        if (item.bidder != address(0) && msg.sender != item.bidder)
            revert Unauthorized(msg.sender);
        if (item.bidder == address(0) && msg.sender != item.owner)
            revert Unauthorized(msg.sender);

        _transferItem(item, msg.sender);
        emit ItemDeleted(msg.sender, item.itemId);
    }

    function _percent(
        uint256 percent_,
        uint256 value_
    ) internal pure returns (uint256) {
        return (value_ * percent_) / 100;
    }

    function purchase(uint256 itemId) external payable {
        Item memory item = _items[itemId];
        if (item.listingType != ListingType.SALE)
            revert UnavailableAction(item.itemId);
        _checkTimeRange(item.endTime, item.startTime, item.itemId);
        if (msg.value != item.price) {
            revert PriceNotCovered();
        }

        _transferItem(item, msg.sender);
        _transferProfits(item);
        emit Sale(item.owner, msg.sender, item.itemId, msg.value);
    }

    function bid(uint256 itemId) external payable {
        Item memory item = _items[itemId];
        _checkTimeRange(item.endTime, item.startTime, item.itemId);
        if (item.listingType != ListingType.AUCTION)
            revert UnavailableAction(item.itemId);
        if (msg.value <= item.price) revert PriceNotCovered();

        Item storage itemStorage = _items[itemId];
        itemStorage.bidder = msg.sender;
        itemStorage.price = msg.value;

        if (item.bidder == address(0)) return;

        payable(item.bidder).transfer(item.price);
        emit Offer(msg.sender, item.owner, item.itemId, item.price);
    }

    function claimItem(uint256 itemId) external {
        Item memory item = _items[itemId];
        if (block.timestamp < item.endTime)
            revert UnavailableAction(item.itemId);

        if (item.bidder != address(0) && msg.sender != item.bidder)
            revert Unauthorized(msg.sender);
        if (item.bidder == address(0) && msg.sender != item.owner)
            revert Unauthorized(msg.sender);

        _transferItem(item, msg.sender);

        if (item.bidder == address(0)) return;
        _transferProfits(item);
    }

    function _transferProfits(Item memory item) internal {
        uint256 earnsOwner = _percent(_ownerPercent, item.price);

        (bool success, bytes memory result) = item.erc721.call(
            abi.encodeWithSignature(
                "royaltyInfo(uin256,uint256)",
                item.tokenId,
                item.price
            )
        );

        address receiver;
        uint256 royalties;

        if (success) {
            (receiver, royalties) = abi.decode(result, (address, uint256));
            payable(receiver).transfer(royalties);
        }
        uint256 earnsSeller = item.price - earnsOwner - royalties;

        payable(owner()).transfer(earnsOwner);
        payable(item.owner).transfer(earnsSeller);
    }

    function getItems(
        ListingType listingType_
    ) external view returns (Item[] memory) {
        uint256 totalItemCount = _itemId.current();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 1; i < totalItemCount; ) {
            if (_items[i].listingType == listingType_) {
                unchecked {
                    ++itemCount;
                }
            }
            unchecked {
                ++i;
            }
        }

        Item[] memory items = new Item[](itemCount);
        for (uint256 i = 1; i < totalItemCount; ) {
            if (_items[i].listingType == listingType_) {
                items[currentIndex] = _items[i];
                unchecked {
                    ++currentIndex;
                }
            }

            unchecked {
                ++i;
            }
        }
        return items;
    }
}