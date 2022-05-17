// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./token/ERC721/IERC721.sol";
import "./token/common/IERC2981.sol";
import "./utils/Counters.sol";
import "./utils/introspection/IERC165.sol"; // import "./OZ/ERC165Checker.sol";
import "./access/Ownable.sol";

/**
    ███    ██ ██ ███    ██ ███████  █████  
    ████   ██ ██ ████   ██ ██      ██   ██ 
    ██ ██  ██ ██ ██ ██  ██ █████   ███████ 
    ██  ██ ██ ██ ██  ██ ██ ██      ██   ██ 
    ██   ████ ██ ██   ████ ██      ██   ██                                                                               
 */

/// @custom:security-contact [email protected]
contract NinfaEnglishAuction is Ownable {

    using Counters for Counters.Counter;
    
    Counters.Counter private auctionId;

    mapping(address => mapping(uint256 => uint256)) private tokenIdToAuctionId; // The auction configuration for a specific auction id.
    mapping(uint256 => _Auction) private auctions; // The auction id for a specific NFT. This is deleted when an auction is finalized or canceled.
    mapping(address => bool) private ERC721Whitelist;
    address payable public feeAccount; // multisig for receiving trading fees
    uint24 private ninfaPrimaryFee; // Ninfa Marketplace fee percentage for primary sales, expressed in basis points. It is not constant because primary sale fees are at 0% for 2022 and will need to be set afterwards to 10%.
    uint24 private constant NINFA_SECONDARY_FEE = 500; // 5% fee on all secondary sales paid to Ninfa (seller receives the remainder after paying 10% royalties to artist/gallery and 5% Ninfa, i.e. 85%)
    bytes4 private constant INTERFACE_ID_ERC2981 = 0x2a55205a; // https://eips.ethereum.org/EIPS/eip-2981
    uint256 private immutable DURATION; // How long an auction lasts for once the first bid has been received.
    uint256 private constant EXTENSION_DURATION = 15 minutes; // The window for auction extensions, any bid placed in the final 15 minutes of an auction will reset the time remaining to 15 minutes.
    uint256 private constant MAX_MAX_DURATION = 1000 days; // Caps the max duration that may be configured so that overflows will not occur.
    uint256 private minBidRaise; // the last highest bid is divided by this number in order to obtain the minimum bid increment. E.g. minBidRaise = 10 is 10% increment, 20 is 5%, 2 is 50%. I.e. 100 / minBidRaise

    /// @notice Stores the auction configuration for a specific NFT.
    struct _Auction {
        address collection;
        uint256 tokenId;
        address payable seller; // auction beneficiary, needs to be payable in order to receive funds from the auction sale
        address payable bidder; // highest bidder, needs to be payable in order to receive refund in case of being outbid
        uint256 price; // reserve price or highest bid
        uint256 end; // The time at which this auction will not accept any new bids. This is `0` until the first bid is placed.
    }

    /**
     * @notice Emitted when an NFT is listed for auction.
     * @param seller The address of the seller.
     * @param collection The address of the NFT contract.
     * @param tokenId The id of the NFT.
     * @param price The reserve price to kick off the auction.
     * @param auctionId The id of the auction that was created.
     */
    event Created(   address indexed collection, uint256 indexed tokenId, address indexed seller, uint256 price, uint256 auctionId );

    /**
     * @notice Emitted when an auction is cancelled.
     * @dev This is only possible if the auction has not received any bids.
     * @param auctionId The id of the auction that was cancelled.
     */
    event Canceled(uint256 indexed auctionId);

    /**
     * @notice Emitted when a bid is placed.
     * @param collection nft address
     * @param tokenId nft id
     * @param bidder The address of the bidder.
     * @param price The amount of the bid.
     * @param auctionId The id of the auction this bid was for.
     * @param end The new end time of the auction (which may have been set or extended by this bid).
     */
    event Bid( address indexed collection, uint256 indexed tokenId, address indexed bidder, uint256 price, uint256 auctionId, uint256 end );
    
    /**
     * @notice Emitted when the auction's reserve price is changed.
     * @dev This is only possible if the auction has not received any bids.
     * @param auctionId The id of the auction that was updated.
     * @param price The new reserve price for the auction.
     */
    event Updated(uint256 indexed auctionId, uint256 price);
    
    /**
     * @notice Emitted when an auction that has already ended is finalized,
     * indicating that the NFT has been transferred and revenue from the sale distributed.
     * @dev The amount of the highest bid / final sale price for this auction
     * is `protocolFee` + `creatorFee` + `sellerRev`.
     * @param collection nft address
     * @param tokenId nft id 
     * @param bidder The address of the highest bidder that won the NFT.
     * @param seller The address of the seller.
     * @param auctionId The id of the auction that was finalized.
     * @param price eth amount sold for
     */
    event Finalized( address indexed collection, uint256 indexed tokenId, address indexed bidder, uint256 price, address seller, uint256 auctionId );

    event Trade( address indexed collection, uint256 indexed tokenId, address indexed bidder, uint256 price, address seller, uint256 auctionId );

    event RoyaltyPayment( address indexed collection, uint256 indexed tokenId, address indexed to, uint256 amount);

    constructor(uint256 _duration, uint256 _minBidRaise) {

        require(_duration < MAX_MAX_DURATION);
        require(_duration > EXTENSION_DURATION);

        DURATION = _duration;
        minBidRaise = _minBidRaise;
    }

    /**
     * @notice Creates an auction for the given NFT. The NFT is held in escrow until the auction is finalized or canceled.
     * @param _collection The address of the NFT contract.
     * @param _tokenId The id of the NFT.
     * @param _price The initial reserve price for the auction.
     */
    function createAuction(
        address _collection,
        uint256 _tokenId,
        uint256 _price
    ) external {
        require( _price > 0, "must set reserve price");
        require( ERC721Whitelist[_collection] == true, "token not whitelisted");
        require( tokenIdToAuctionId[_collection][_tokenId] == 0, "already listed");
        
        auctionId.increment(); // start counter at 1

        IERC721(_collection).transferFrom(msg.sender, address(this), _tokenId);

        tokenIdToAuctionId[_collection][_tokenId] = auctionId.current();

        auctions[auctionId.current()] = _Auction(
            _collection,
            _tokenId,
            payable(msg.sender), // // auction beneficiary, needs to be payable in order to receive funds from the auction sale
            payable(0), // bidder is only known once a bid has been placed. // highest bidder, needs to be payable in order to receive refund in case of being outbid
            _price, // The time at which this auction will not accept any new bids. This is `0` until the first bid is placed.
            0 // end is only known once the reserve price is met
        );

        emit Created(_collection, _tokenId, msg.sender, _price, auctionId.current());
    }

    /**
     * @notice Place a bid in an auction.
     * A bidder may place a bid which is at least the amount defined by `getMinBidAmount`.
     * If this is the first bid on the auction, the countdown will begin.
     * If there is already an outstanding bid, the previous bidder will be refunded at this time
     * and if the bid is placed in the final moments of the auction, the countdown may be extended.
     * @param _auctionId The id of the auction to bid on.
     */
    function bid(uint256 _auctionId) external payable {

        _Auction storage _auction = auctions[_auctionId];
        
        require(_auction.price > 0, "nonexistent auction");
        
        if ( _auction.bidder == address(0x0) ) {
            require(msg.value > _auction.price, "value < reserve price");
            // if the auction price has been set but there is no bidder yet, set the auction timer. On the first bid, set the end to now + duration. Duration is always set to 24hrs so the below can't overflow.
            unchecked {
                _auction.end = block.timestamp + DURATION;
            }
        } else {
            require(block.timestamp < _auction.end, "ended");
            require(_auction.bidder != msg.sender, "cannot bid twice");   // We currently do not allow a bidder to increase their bid unless another user has outbid them first.
            require(msg.value - _auction.price >  _auction.price / minBidRaise ); // the raise amount must be bigger than highest bid divided by `minBidRaise`.
            // if there is less than 15 minutes left, increment end time by 15 more. EXTENSION_DURATION is always set to 15 minutes so the below can't overflow.
            if (block.timestamp + EXTENSION_DURATION > _auction.end) {
                 unchecked {
                     _auction.end += EXTENSION_DURATION;
                }
            }
            // if there is a previous highest bidder, refund the previous bid
            // solhint-disable-next-line avoid-low-level-calls
            (bool success, ) = payable(_auction.bidder).call{value: _auction.price}("");
            require(success);
        }

        _auction.price = msg.value; // new highest bit
        _auction.bidder = payable(msg.sender); // new highest bidder

        emit Bid( _auction.collection, _auction.tokenId, msg.sender, msg.value, _auctionId, _auction.end );
    }

    /**
     * @notice If an auction has been created but has not yet received bids, the reservePrice may be
     * changed by the seller.
     * @param _auctionId The id of the auction to change.
     * @param _price The new reserve price for this auction.
     */
    function updateAuction(uint256 _auctionId, uint256 _price) external {

        _Auction storage _auction = auctions[_auctionId];
        require(_price > 0, "Price must be more than 0"); // can't set to zero or else it will not be possible to take bids because the auction will be considered nonexistent.
        require(_auction.seller == msg.sender, "must be auction creator"); // implicitly also checks that the auction exists
        require(_auction.end == 0, "auction already started");
        require(_auction.price != _price, "cannot be old price");

        // Update the current reserve price.
        auctions[_auctionId].price = _price;

        emit Updated(_auctionId, _price);
    }

    /**
     * @notice If an auction has been created but has not yet received bids, it may be canceled by the seller.
     * @dev The NFT is transferred back to the owner unless there is still a buy price set.
     * @param _auctionId The id of the auction to cancel.
     */
    function cancelAuction(uint256 _auctionId) external {
        _Auction memory _auction = auctions[_auctionId];

        require(_auction.seller == msg.sender, "must be auction creator");
        require(_auction.end == 0, "auction has started");

        // Remove the _auction.
        delete tokenIdToAuctionId[_auction.collection][_auction.tokenId];
        delete auctions[_auctionId];

        IERC721(_auction.collection).transferFrom(address(this), _auction.seller, _auction.tokenId);

        emit Canceled(_auctionId);
    }

    /**
     * TODO create function _getCreatorPaymentInfo as in `NFTMarketCreators.sol` from Foundation, that tries all different royalties interfaces out there, not just erc2981
     */
    function finalize(uint256 _auctionId) external {

        _Auction memory _auction = auctions[_auctionId];

        require(_auction.end > 0, "auction not started"); // there must be at least one bid higher than the reserve price in order to execute the trade, no bids mean no end time
        require(block.timestamp > _auction.end, "auction in progress");

        // Remove the auction.
        delete tokenIdToAuctionId[_auction.collection][_auction.tokenId];
        delete auctions[_auctionId];

        // transfer nft to auction winner
        IERC721(_auction.collection).transferFrom(address(this), _auction.bidder, _auction.tokenId);
        // pay seller, royalties and fees
        _trade(_auctionId, _auction.bidder, _auction.seller, _auction.price , _auction.tokenId, _auction.collection);

        emit Trade( _auction.collection, _auction.tokenId, _auction.seller, _auction.price, _auction.bidder, _auctionId);
        
    }

    /**
     * @param _auctionId order Id
     * @param _buyer order or offer creator, depending on who `msg.sender` is
     * @param _price NFT's price
     * @param _tokenId NFT's Id
     */
    function _trade(uint256 _auctionId, address _buyer, address _seller, uint256 _price, uint256 _tokenId, address _collection) private {

        uint256 marketplaceFeeAmount = _price * NINFA_SECONDARY_FEE / 10000;
        uint256 sellerAmount;
        bool success;

        // All NFTs implement 165 so we skip that check, individual interfaces should return false if 165 is not implemented
        // TODO check for other interfaces that implement royalties, see Foundation's contract `NFTMarketCreators`
        if ( IERC165(_collection).supportsInterface(INTERFACE_ID_ERC2981) ) {
            // If the collection supports the erc2981 royalties interface, store the receiver address and amount in memory. This is needed as all external collections are considered as secondary sales.
            ( address royaltyReceiver, uint256 royaltyAmount ) = IERC2981(_collection).royaltyInfo(_tokenId, _price);
            // if `royaltyAmount == (_price - marketplaceFeeAmount)` then `sellerAmount == 0` which is default. in the EVM, there is an opcode for less than and greater than, but not less than or equal to or greater than or equal to. 
            if( royaltyReceiver != address(0) && royaltyAmount > 0 && royaltyAmount < (_price - marketplaceFeeAmount) ) { // if `royaltyAmount == (_price - marketplaceFeeAmount)` then `sellerAmount == 0` which is default. in the EVM, there is an opcode for less than and greater than, but not less than or equal to or greater than or equal to. 
                sellerAmount = ( _price - royaltyAmount - marketplaceFeeAmount );
                // pay royalties
                (success, ) = royaltyReceiver.call{ value: royaltyAmount }("");
                require(success);

                emit RoyaltyPayment(_collection, _tokenId, royaltyReceiver, royaltyAmount);
            }
            
        }

        /**
         * Pay marketplace fee (primary or secondary)
         */
        (success, ) = feeAccount.call{ value: marketplaceFeeAmount }("");
        require(success);

        /**
         * Pay seller 
         */
        (success, ) = payable(_seller).call{ value: sellerAmount /*(_price - marketplaceFeeAmount - royaltyAmount)*/ }("");
        require(success);

        emit Trade(_collection, _tokenId, _seller, _price, _buyer, _auctionId);
    }

    /**
     * @notice whitelist collection to be traded on marketplace
     * @param _collection address of collection ERC721
     */
    function whitelistERC721(address _collection) onlyOwner external {
        ERC721Whitelist[_collection] = true;
    }

    /**
    * @dev setter function only callable by contract admin used to change the address to which fees are paid
    * @param _feeAccount is the address owned by NINFA that will collect sales fees 
    */
    function setFeeAccount(address payable _feeAccount) onlyOwner external {
        feeAccount = _feeAccount;
    }

    function setMinBidRaise(uint256 _minBidRaise) onlyOwner external {
        minBidRaise = _minBidRaise;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

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

pragma solidity 0.8.13;

/**
 * @title Counters
 * @dev Stripped down version of OpenZeppelin Contracts v4.4.1 (utils/Counters.sol), identical to CountersUpgradeable.sol being a library. Provides counters that can only be incremented. Used to track the total supply of ERC721 ids.
 * @dev Include with `using Counters for Counters.Counter;`
 */
library Counters {

    struct Counter {
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    /// @dev if implementing ERC721A there could be an overflow risk by removing overflow protection with `unchecked`, unless we limit the amount of tokens that can be minted, or require that totalsupply be less than 2^256 - 1
    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/IERC2981.sol)

pragma solidity 0.8.13;

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be payed in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

interface IERC721 {
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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

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
abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(msg.sender);
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
        require(owner() == msg.sender, "Ownable: caller is not the owner");
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