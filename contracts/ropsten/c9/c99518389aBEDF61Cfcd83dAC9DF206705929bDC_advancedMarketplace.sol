// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Counters.sol';

interface ISimpleMarketplaceNativeERC721 {
    event NewListing(
        uint256 indexed tokenId,
        address indexed seller,
        uint256 price,
        address currency,
        uint256 timestamp
    );
    event Sold(
        uint256 indexed tokenId,
        address indexed seller,
        address indexed buyer,
        uint256 price,
        address currency,
        uint256 timestamp
    );
    event delisted(
        address indexed NFT,
        uint256 indexed tokenId,
        address indexed seller
    );
    event madeOffer(
        address indexed offerSender,
        address indexed NFT, 
        uint256 indexed tokenId, 
        uint256 offerAmount
    );
    event acceptedOffer(
        address indexed offerMaker,
        address indexed offerTaker,
        address indexed NFT, 
        uint256 tokenId, 
        uint256 amount
    );
    event deletedOffer(
        address indexed offerMaker,
        address indexed NFT,
        uint256 indexed tokenId,
        uint256 amountRefunded
    );

    function list(uint256 tokenId, uint256 price, address ) external;

    function buy(address nftAddress, uint256 tokenId) external payable;
}

contract advancedMarketplace is
    Ownable,
    ISimpleMarketplaceNativeERC721
{
    using Counters for Counters.Counter;
    Counters.Counter private lastListingId;
    Counters.Counter private lastBiddingId;

    struct Listing {
        address seller;
        address currency;
        uint256 tokenId;
        uint256 price;
        bool isSold;
        bool exist;
    }

    struct Bidding {
        address buyer;
        uint256 tokenId;
        uint256 offer;
    }

    struct Token {
        address tokenContract;
        uint256 tokenId;
    }
//////////////////multiple contracts attempt//////////////////
    mapping(address => mapping(uint256 => Listing)) public contractListing;
    mapping(address => mapping(uint256 => Bidding)) public contractBids;
    mapping(address => mapping(uint256 => bool)) public contractTokensListing;
    mapping(address => mapping(uint256 => bool)) public contractTokensBidding;
/////////////////////////////////////////////////////////////

    mapping(uint256 => Listing) public listings;
    mapping(uint256 => Bidding) public bids;
    mapping(uint256 => uint256) public tokensBidding;
    mapping(uint256 => uint256) public tokensListing;

    modifier onlyItemOwner(uint256 tokenId, address addy) {
        isItemOwner(tokenId, addy);
        _;
    }

    modifier onlyTransferApproval(address owner, address addy) {
        isTransferApproval(owner, addy);
        _;
    }

    function isItemOwner(uint256 tokenId, address nftAddy) internal view {
        IERC721 token = IERC721(nftAddy);
        require(
            token.ownerOf(tokenId) == _msgSender(),
            'Marketplace: Not the item owner'
        );
    }

    function isTransferApproval(address owner, address nftAddy) internal view {
        IERC721 token = IERC721(nftAddy);
        require(
            token.isApprovedForAll(owner, address(this)),
            'Marketplace: Marketplace is not approved to use this tokenId'
        );
    }

    function list(uint256 tokenId, uint256 price, address nftAddress)
        external
        override
        onlyItemOwner(tokenId, nftAddress)
        onlyTransferApproval(msg.sender, nftAddress)
    {

        require(
            contractTokensListing[nftAddress][tokenId] == false,
            'Marketplace: the token is already listed'
        );

        contractTokensListing[nftAddress][tokenId] = true;

        Listing memory _list = contractListing[nftAddress][tokenId];
        require(_list.exist == false, 'Marketplace: List already exist');
        require(
            _list.isSold == false,
            'Marketplace: Can not list an already sold item'
        );

        Listing memory newListing = Listing(
            msg.sender,
            address(0),
            tokenId,
            price,
            false,
            true
        );

        contractListing[nftAddress][tokenId] = newListing;

        emit NewListing(
            tokenId,
            msg.sender,
            price,
            address(0),
            block.timestamp
        );
    }

    //custom function
    function removeListing(address nftAddress, uint256 tokenId) external onlyItemOwner(tokenId, nftAddress){
        require(contractTokensListing[nftAddress][tokenId] == true, "Marketplace: token was never listed");
        Listing memory _list = contractListing[nftAddress][tokenId];
        require(_list.isSold == false, "Marketplace: token is already sold");

        emit delisted(
            nftAddress,
            tokenId,
            msg.sender
        );
        clearStorage(nftAddress, tokenId);
    }
    //custom function
    function makeOffer(address nftAddress, uint256 tokenId, uint256 offer) external payable {
        require(offer == msg.value, "Marketplace: offer does not equal transfered amount");
        IERC721 token = getToken(nftAddress);
        require(token.ownerOf(tokenId) != msg.sender, "Marketplace: bidder is the token owner");
        Bidding memory _bid = Bidding(
            msg.sender,
            tokenId,
            offer
        );
        if(contractTokensBidding[nftAddress][tokenId]) {
            require(contractBids[nftAddress][tokenId].offer < _bid.offer, "Marketplace: a higher bid already exists for this token");
            bool sent = payable(contractBids[nftAddress][tokenId].buyer).send(contractBids[nftAddress][tokenId].offer);                                     //need to return last bidders funds so they dont get stuck in the contract
            require(sent, "Marketplace: failed to send previous bidder their funds");
        }

        contractBids[nftAddress][tokenId] = _bid;
        contractTokensBidding[nftAddress][tokenId] = true;
        emit madeOffer(msg.sender, nftAddress, tokenId, msg.value);
    }

    function acceptOffer(address nftAddress, uint256 tokenId) 
    external 
    payable 
    onlyItemOwner(tokenId, nftAddress) 
    onlyTransferApproval(msg.sender, nftAddress) {

        require(msg.value == 0, "Marketplace: sent value should be 0 to avoid funds getting stuck.");
        require(contractTokensBidding[nftAddress][tokenId] == true, "Marketplace: the token has no active offers");
        uint256 amount = contractBids[nftAddress][tokenId].offer;
        bool sent = payable(msg.sender).send(amount);
        require(sent, "funds failed to send");
        IERC721 token = getToken(nftAddress);
        token.safeTransferFrom(msg.sender, contractBids[nftAddress][tokenId].buyer, tokenId, '');
        emit acceptedOffer(bids[tokenId].buyer, msg.sender, nftAddress, tokenId, amount);  
        delete contractBids[nftAddress][tokenId];
        delete contractTokensBidding[nftAddress][tokenId];
    }

    function deleteOffer(address nftAddress, uint256 tokenId) external payable {
        require(msg.value == 0, "Marketplace: sent value should be 0 to avoid funds getting stuck.");
        require(contractBids[nftAddress][tokenId].buyer == msg.sender, "Marketplace: cannot delete a bid that is not yours");
        uint256 amount = contractBids[nftAddress][tokenId].offer;
        bool sent = payable(contractBids[nftAddress][tokenId].buyer).send(amount);
        require(sent, "Marketplace: failed to return funds to bidder");
        delete contractBids[nftAddress][tokenId];
        delete contractTokensBidding[nftAddress][tokenId];
        emit deletedOffer(msg.sender, nftAddress, tokenId, amount);
    }

    function declineOffer(address nftAddress, uint256 tokenId) external payable {
        require(msg.value == 0, "Marketplace: sent value should be 0 to avoid funds getting stuck.");
        IERC721 token = getToken(nftAddress);
        require(token.ownerOf(tokenId) == msg.sender, "Marketplace: cannot decline an offer to a token you do not own.");
        uint256 amount = contractBids[nftAddress][tokenId].offer;
        bool sent = payable(contractBids[nftAddress][tokenId].buyer).send(amount);
        require(sent, "Marketplace: failed to return funds to bidder");
        delete contractBids[nftAddress][tokenId];
        delete contractTokensBidding[nftAddress][tokenId];
        emit deletedOffer(msg.sender, nftAddress, tokenId, amount);
    }

    function viewOffer(address nftAddress, uint256 tokenId) external view returns(Bidding memory tokenBid) {
        return contractBids[nftAddress][tokenId];
    }

    function buy(address nftAddress, uint256 tokenId) external payable override {
        Listing storage _list = contractListing[nftAddress][tokenId];
        require(
            _list.price == msg.value,
            "Marketplace: The sent value doesn't equal the price"
        );
        require(_list.isSold == false, 'Marketplace: item is already sold');
        require(_list.exist == true, 'Marketplace: item does not exist');
        require(
            _list.currency == address(0),
            'Marketplace: item currency is not the native one'
        );
        require(
            _list.seller != msg.sender,
            'Marketplace: seller has the same address as buyer'
        );
        IERC721 token = getToken(nftAddress);
        token.safeTransferFrom(_list.seller, msg.sender, tokenId, '');
        payable(_list.seller).transfer(msg.value);

        _list.isSold = true;

        emit Sold(
            tokenId,
            _list.seller,
            msg.sender,
            msg.value,
            address(0),
            block.timestamp
        );
        clearStorage(nftAddress, tokenId);
    }



    function getToken(address nftAddress) internal pure returns (IERC721) {
        IERC721 token = IERC721(nftAddress);
        return token;
    }

    function clearStorage(address nftAddress, uint256 tokenId) internal {
        delete contractListing[nftAddress][tokenId];
        delete contractTokensListing[nftAddress][tokenId];
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