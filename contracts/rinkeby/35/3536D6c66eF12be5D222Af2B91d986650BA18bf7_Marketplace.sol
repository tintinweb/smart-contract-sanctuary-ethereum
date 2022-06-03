// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
contract Marketplace is ERC1155Holder, Ownable {
    uint private _characterListingCount;
    uint private _characterOfferCount;
    uint private _skinsListingCount;
    uint private _skinsOfferCount;
    // (collectionSymbol + tokenId) -> address
    mapping(string => address) public _characterOwners;
    mapping(uint => CharacterListing) public _characterListings;
    mapping(uint => CharacterOffer) public _characterOffers;
    // (collectionSymbol + tokenId) -> address
    mapping(string => address) public _skinsOwners;
    mapping(uint => SkinsListing) public _skinsListings;
    mapping(uint => SkinsOffer) public _skinsOffers;
    mapping(address => uint) public _userFunds;
    // (collectionSymbol + tokenId) -> highest offer
    mapping(string => CharacterOffer) public _highestCharacterOffer;
    IERC20 public _currencyToken;
    IERC721Metadata public _charactersCollection;
    IERC1155 public _skinsCollection;
    struct CharacterListing {
        uint listingId;
        IERC721Metadata collection;
        uint tokenId;
        address user;
        uint price;
        bool fulfilled;
        bool cancelled;
    }
    struct CharacterOffer {
        uint offerId;
        IERC721Metadata collection;
        uint tokenId;
        address user;
        uint price;
        uint expiry;
        bool fulfilled;
        bool cancelled;
    }
    struct SkinsListing {
        uint listingId;
        IERC1155 collection;
        uint tokenId;
        uint amount;
        address user;
        uint price;
        bool fulfilled;
        bool cancelled;
    }
    struct SkinsOffer {
        uint offerId;
        IERC1155 collection;
        uint tokenId;
        uint amount;
        address user;
        uint price;
        uint expiry;
        bool fulfilled;
        bool cancelled;
    }
    // Character Events
    event CharacterListed(uint listingId, IERC721Metadata collection, uint tokenId, address user, uint price, uint currentTime);
    event CharacterListingFulfilled(uint listingId, IERC721Metadata collection, uint tokenId, address newOwner, uint currentTime);
    event CharacterListingCancelled(uint listingId, uint currentTime);
    event CharacterOffered(uint offerId, IERC721Metadata collection, uint tokenId, address user, uint price, uint expiry, uint currentTime);
    event CharacterOfferFulfilled(uint offerId, IERC721Metadata collection, uint tokenId, address newOwner, uint currentTime);
    event CharacterOfferCancelled(uint offerId, uint currentTime);
    // Skins Events
    event SkinsListed(uint listingId, IERC1155 collection, uint tokenId, uint amount, uint price, address user, uint currentTime);
    event SkinsListingFulfilled(uint listingId, IERC1155 collection, uint tokenId, uint amount, address oldOwner, address newOwner, uint currentTime);
    event SkinsListingCancelled(uint listingId, uint currentTime);
    event SkinsOffered(uint offerId, IERC1155 collection, uint tokenId, uint amount, uint price, address user, uint expiry, uint currentTime);
    event SkinsOfferFulfilled(uint offerId, IERC1155 collection, uint tokenId, uint amount, address oldOwner, address newOwner, uint currentTime);
    event SkinsOfferCancelled(uint offerId, uint currentTime);
    // Misc. Events
    event FundsAdded(address user, uint amount);
    event ClaimedFunds(address user, uint amount, uint currentTime);
    constructor(IERC20 __currencyToken, IERC721Metadata __charactersCollection, IERC1155 __skinsCollection) {
        _currencyToken = __currencyToken;
        _charactersCollection = __charactersCollection;
        _skinsCollection = __skinsCollection;
    }
    function listingCount() public view virtual returns (uint) {
        return _characterListingCount;
    }

    function offerCount() public view virtual returns (uint) {
        return _characterOfferCount;
    }
    function claimFunds() external {
        require(_userFunds[msg.sender] > 0, 'This user has no funds to be claimed');
        // transfer coins from marketplace to msg.sender
        _currencyToken.transfer(msg.sender, _userFunds[msg.sender]);
        emit ClaimedFunds(msg.sender, _userFunds[msg.sender], block.timestamp);
        _userFunds[msg.sender] = 0;
    }
    // CHARACTER FUNCTIONS
    function makeCharacterListing(uint __tokenId, uint __price) external {
        address tokenOwner = _charactersCollection.ownerOf(__tokenId);
        require(msg.sender == tokenOwner, "Sender is not token's owner");
        require(__price > 0, "Invalid price");
        _characterOwners[
        string(abi.encodePacked(
                _charactersCollection.symbol(),
                Strings.toString(__tokenId)
            ))
        ] = tokenOwner;
        _charactersCollection.transferFrom(msg.sender, address(this), __tokenId);
        _characterListingCount ++;
        _characterListings[_characterListingCount] = CharacterListing(
            _characterListingCount, _charactersCollection, __tokenId, msg.sender, __price, false, false
        );
        emit CharacterListed(_characterListingCount, _charactersCollection, __tokenId, msg.sender, __price, block.timestamp);
    }
    function fulfillCharactersListing(uint __listingId) external {
        CharacterListing memory listing = _characterListings[__listingId];
        uint allowance = _currencyToken.allowance(msg.sender, address(this));
        require(listing.listingId == __listingId, 'The listing must exist');
        require(listing.user != msg.sender, 'The owner of the listing cannot fill it');
        require(!listing.fulfilled, 'Listing already fulfilled');
        require(!listing.cancelled, 'Listing already cancelled');
        require(allowance >= listing.price, "Insufficient allowance");
        _characterOwners[
        string(abi.encodePacked(
                listing.collection.symbol(),
                Strings.toString(listing.tokenId)
            ))
        ] = msg.sender;
        _currencyToken.transferFrom(msg.sender, address(this), listing.price);
        listing.collection.transferFrom(address(this), msg.sender, listing.tokenId);
        listing.fulfilled = true;
        _characterListings[__listingId] = listing;
        _userFunds[listing.user] += listing.price;
        emit FundsAdded(msg.sender , listing.price);
        emit CharacterListingFulfilled(__listingId, listing.collection, listing.tokenId, msg.sender, block.timestamp);
    }
    function cancelCharacterListing(uint __listingId) external {
        CharacterListing memory listing = _characterListings[__listingId];
        require(listing.listingId == __listingId, 'The listing must exist');
        require(listing.user == msg.sender, 'The listing can only be canceled by the owner');
        require(!listing.fulfilled, 'CharacterListing already fulfilled');
        require(!listing.cancelled, 'CharacterListing already cancelled');
        listing.collection.transferFrom(address(this), msg.sender, listing.tokenId);
        listing.cancelled = true;
        _characterListings[__listingId] = listing;
        emit CharacterListingCancelled(__listingId, block.timestamp);
    }
    function makeCharacterOffer(uint __tokenId, uint __price, uint __expiry) external {
        string memory uuid = string(abi.encodePacked(_charactersCollection.symbol(), Strings.toString(__tokenId)));
        address tokenOwner = _characterOwners[uuid];
        if (tokenOwner == address(0)) {
            address placeholder = _charactersCollection.ownerOf(__tokenId);
            tokenOwner = placeholder;
            _characterOwners[uuid] = placeholder;
        }
        CharacterOffer memory highestOffer = _highestCharacterOffer[uuid];
        require(tokenOwner != msg.sender, "Owner of token can't make offer");
        require(highestOffer.price < __price, "New offer must be greater than current highest offer");
        // create new offer
        _characterOfferCount++;
        CharacterOffer memory newOffer = CharacterOffer(
            _characterOfferCount,
            _charactersCollection,
            __tokenId,
            msg.sender,
            __price,
            __expiry,
            false,
            false
        );
        _characterOffers[_characterOfferCount] = newOffer;
        _highestCharacterOffer[uuid] = newOffer;
        emit CharacterOffered(_characterOfferCount, _charactersCollection, __tokenId, msg.sender, __price, __expiry, block.timestamp);
    }
    function fulfillCharacterOffer(uint __offerId) external {
        CharacterOffer memory offer = _characterOffers[__offerId];
        string memory uuid = string(abi.encodePacked(offer.collection.symbol(), Strings.toString(offer.tokenId)));
        address tokenOwner = _characterOwners[uuid];
        uint allowance = _currencyToken.allowance(offer.user, address(this));
        require(offer.offerId == __offerId, 'The offer must exist');
        require(offer.user != msg.sender, 'The owner of offer cannot fill it');
        require(tokenOwner != address(this), "NFT already available for sale");
        require(tokenOwner == msg.sender, 'Only owner of token can fill it');
        require(!offer.fulfilled, 'Offer already filled');
        require(!offer.cancelled, 'Offer already cancelled');
        require(offer.expiry > block.timestamp, 'Offer expired');
        require(allowance >= offer.price, "Insufficient allowance from Offer");
        _characterOwners[
        string(abi.encodePacked(
                offer.collection.symbol(),
                Strings.toString(offer.tokenId)
            ))
        ] = offer.user;
        // transfer coins from offer-user to marketplace
        _currencyToken.transferFrom(offer.user, address(this), offer.price);
        // transfer NFT from owner to offer-user
        offer.collection.transferFrom(tokenOwner, offer.user, offer.tokenId);
        offer.fulfilled = true;
        _characterOffers[__offerId] = offer;
        _userFunds[tokenOwner] += offer.price;
        emit FundsAdded(msg.sender , offer.price);
        emit CharacterOfferFulfilled(__offerId, _charactersCollection, offer.tokenId, offer.user, block.timestamp);
    }
    function cancelCharacterOffer(uint __offerId) external {
        CharacterOffer memory offer = _characterOffers[__offerId];
        require(offer.offerId == __offerId, 'The offer must exist');
        require(offer.user == msg.sender, 'The offer can only be canceled by the owner');
        require(!offer.fulfilled, 'Offer already filled');
        require(!offer.cancelled, 'Offer already cancelled');
        require(offer.expiry > block.timestamp, 'Offer already expired');
        offer.cancelled = true;
        _characterOffers[__offerId] = offer;
        emit CharacterOfferCancelled(__offerId, block.timestamp);
    }
    // CHARACTER FUNCTIONS
    // SKINS FUNCTIONS
    function makeSkinsListing(uint __tokenId, uint __amount, uint __price) external {
        uint balance = _skinsCollection.balanceOf(msg.sender, __tokenId);
        require(balance >= __amount, "Insufficient token amount in wallet");
        require(__price > 0, "Invalid price");
        _skinsCollection.safeTransferFrom(msg.sender, address(this), __tokenId, __amount, "");
        _skinsListingCount++;
        _skinsListings[_skinsListingCount] = SkinsListing(
            _skinsListingCount, _skinsCollection, __tokenId, __amount, msg.sender, __price, false, false
        );
        emit SkinsListed(_skinsListingCount, _skinsCollection, __tokenId, __amount, __price, msg.sender, block.timestamp);
    }
    function fulfillSkinsListing(uint __listingId) external {
        SkinsListing memory listing = _skinsListings[__listingId];
        uint allowance = _currencyToken.allowance(msg.sender, address(this));
        require(listing.listingId == __listingId, 'The listing must exist');
        require(listing.user != msg.sender, 'The owner of the listing cannot fill it');
        require(!listing.fulfilled, 'Listing already fulfilled');
        require(!listing.cancelled, 'Listing already cancelled');
        require(allowance >= (listing.price * listing.amount), "Insufficient allowance");
        // take coins
        _currencyToken.transferFrom(msg.sender, address(this), (listing.price * listing.amount));
        // give NFTs
        listing.collection.safeTransferFrom(address(this), msg.sender, listing.tokenId, listing.amount, "");
        listing.fulfilled = true;
        _skinsListings[__listingId] = listing;
        _userFunds[listing.user] += listing.price;
        emit FundsAdded(msg.sender , listing.price);
        emit SkinsListingFulfilled(__listingId, listing.collection, listing.tokenId, listing.amount, listing.user, msg.sender, block.timestamp);
    }
    function cancelSkinsListing(uint __listingId) external {
        SkinsListing memory listing = _skinsListings[__listingId];
        require(listing.listingId == __listingId, 'The listing must exist');
        require(listing.user == msg.sender, 'The listing can only be canceled by the owner');
        require(!listing.fulfilled, 'CharacterListing already fulfilled');
        require(!listing.cancelled, 'CharacterListing already cancelled');
        listing.collection.safeTransferFrom(address(this), msg.sender, listing.tokenId, listing.amount, "");
        listing.cancelled = true;
        _skinsListings[__listingId] = listing;
        emit SkinsListingCancelled(__listingId, block.timestamp);
    }
    function makeSkinsOffer(uint __tokenId, uint __price, uint __amount, uint __expiry) external {
        uint allowance = _currencyToken.allowance(msg.sender, address(this));
        require(allowance >= __price, "Insufficient allowance");
        require(__price > 0, "Invalid price");
        _skinsOfferCount++;
        _skinsOffers[_skinsOfferCount] = SkinsOffer(
            _skinsOfferCount,
            _skinsCollection,
            __tokenId,
            __amount,
            msg.sender,
            __price,
            __expiry,
            false,
            false
        );
        emit SkinsOffered(_skinsOfferCount, _skinsCollection, __tokenId, __amount, __price, msg.sender, __expiry, block.timestamp);
    }
    function fulfillSkinsOffer(uint __offerId) external {
        SkinsOffer memory offer = _skinsOffers[__offerId];
        uint acceptorBalance = _skinsCollection.balanceOf(msg.sender, offer.tokenId);
        uint allowance = _currencyToken.allowance(offer.user, address(this));
        require(offer.offerId == __offerId, 'The offer must exist');
        require(offer.user != msg.sender, 'The owner of offer cannot fill it');
        require(acceptorBalance >= offer.amount, 'Insufficient skins to accept offer');
        require(!offer.fulfilled, 'Offer already filled');
        require(!offer.cancelled, 'Offer already cancelled');
        require(offer.expiry > block.timestamp, 'Offer expired');
        require(allowance >= (offer.price * offer.amount), "Insufficient allowance from Offer");
        // transfer coins from offer-user to marketplace
        _currencyToken.transferFrom(offer.user, address(this), (offer.price * offer.amount));
        // transfer NFTs to offer-user
        offer.collection.safeTransferFrom(msg.sender, offer.user, offer.tokenId, offer.amount, "");
        // mark offered as filled
        offer.fulfilled = true;
        _skinsOffers[__offerId] = offer;
        _userFunds[msg.sender] += offer.price;
        emit FundsAdded(msg.sender , offer.price);
        emit SkinsOfferFulfilled(offer.offerId, offer.collection, offer.tokenId, offer.amount, msg.sender, offer.user, block.timestamp);
    }
    function cancelSkinsOffer(uint __offerId) external {
        SkinsOffer memory offer = _skinsOffers[__offerId];
        require(offer.offerId == __offerId, 'The offer must exist');
        require(offer.user == msg.sender, 'The listing can only be canceled by the owner');
        require(!offer.fulfilled, 'CharacterOffer already filled');
        require(!offer.cancelled, 'CharacterOffer already cancelled');
        require(offer.expiry > block.timestamp, 'CharacterOffer already expired');
        offer.cancelled = true;
        _skinsOffers[__offerId] = offer;
        emit SkinsOfferCancelled(__offerId, block.timestamp);
    }
    // SKINS FUNCTIONS
    // Fallback: reverts if Ether is sent to this smart-contract by mistake
    fallback() external {
        revert();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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