// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "../RoyaltyEngineV1.sol";
import "../token/ERC721/IERC721.sol";
import "../token/ERC1155/IERC1155.sol";
import "../token/common/IERC2981.sol";
import "../utils/Counters.sol";
import "../access/Ownable.sol";
import "../utils/introspection/ERC165Checker.sol";

/**
    ███    ██ ██ ███    ██ ███████  █████  
    ████   ██ ██ ████   ██ ██      ██   ██ 
    ██ ██  ██ ██ ██ ██  ██ █████   ███████ 
    ██  ██ ██ ██ ██  ██ ██ ██      ██   ██ 
    ██   ████ ██ ██   ████ ██      ██   ██                                                                               
 */

/// @custom:security-contact [email protected]
contract TestNinfaEnglishAuction is Ownable, RoyaltyEngineV1 {
    using Counters for Counters.Counter;
    using ERC165Checker for address;

    Counters.Counter private auctionId;

    mapping(address => mapping(uint256 => uint256)) private tokenIdToAuctionId; // The auction configuration for a specific auction id.
    mapping(uint256 => _Auction) private auctions; // The auction id for a specific NFT. This is deleted when an auction is finalized or canceled.
    address payable public feeAccount; // multisig for receiving trading fees
    address[] public collectionsRegistries; // used to check for access control, i.e. whether a collection is whitelisted. Should contain any erc721 or erc1155 factory contract and the marketplace contract.
    uint256 public DURATION = 1 days; // How long an auction lasts for once the first bid has been received.
    uint24 public MARKETPLACE_FEE = 500; // 5% fee on all secondary sales paid to Ninfa (seller receives the remainder after paying 10% royalties to artist/gallery and 5% Ninfa, i.e. 85%)
    bytes4 public INTERFACE_ID_ERC2981 = 0x2a55205a; // https://eips.ethereum.org/EIPS/eip-2981
    uint256 public EXTENSION_DURATION = 15 minutes; // The window for auction extensions, any bid placed in the final 15 minutes of an auction will reset the time remaining to 15 minutes.
    uint256 public MIN_BID_RAISE = 20; // the last highest bid is divided by this number in order to obtain the minimum bid increment. E.g. MIN_BID_RAISE = 10 is 10% increment, 20 is 5%, 2 is 50%. I.e. 100 / MIN_BID_RAISE. OpenSea uses a fixed 5% increment while SuperRare between 5-10%

    /// @notice Stores the auction configuration for a specific NFT.
    struct _Auction {
        address collection;
        uint256 tokenId;
        address payable seller; // auction beneficiary, needs to be payable in order to receive funds from the auction sale
        address payable bidder; // highest bidder, needs to be payable in order to receive refund in case of being outbid
        uint256 price; // reserve price or highest bid
        uint256 amount; // 0 for erc721, 1> for erc1155
        uint256 end; // The time at which this auction will not accept any new bids. This is `0` until the first bid is placed.
        address payable commissionReceiver;
        uint256 commissionShares;
    }

    /**
     * @notice Emitted when an NFT is listed for auction.
     * @param seller The address of the seller.
     * @param collection The address of the NFT contract.
     * @param tokenId The id of the NFT.
     * @param price The reserve price to kick off the auction.
     * @param auctionId The id of the auction that was created.
     */
    event AuctionCreated(
        address indexed collection, // todo is collection information really needed, or just the auction id?
        uint256 indexed tokenId,
        address indexed seller,
        uint256 price,
        uint256 amount,
        uint256 auctionId
    );

    /**
     * @notice Emitted when an auction is cancelled.
     * @dev This is only possible if the auction has not received any bids.
     * @param auctionId The id of the auction that was cancelled.
     */
    event AuctionCanceled(uint256 indexed auctionId);

    /**
     * @notice Emitted when a bid is placed.
     * @param collection nft address
     * @param tokenId nft id
     * @param bidder The address of the bidder.
     * @param price The amount of the bid.
     * @param auctionId The id of the auction this bid was for.
     * @param end The new end time of the auction (which may have been set or extended by this bid).
     */
    event Bid(
        address indexed collection, // todo is collection information really needed, or just the auction id?
        uint256 indexed tokenId,
        address indexed bidder,
        uint256 price,
        uint256 auctionId,
        uint256 end
    );

    /**
     * @notice Emitted when the auction's reserve price is changed.
     * @dev This is only possible if the auction has not received any bids.
     * @param auctionId The id of the auction that was updated.
     * @param price The new reserve price for the auction.
     */
    event AuctionUpdated(uint256 indexed auctionId, uint256 price);

    /**
     * @notice Emitted when an auction that has already ended is finalized,
     * indicating that the NFT has been transferred and revenue from the sale distributed.
     * @dev The amount of the highest bid / final sale price for this auction
     * is `protocolFee` + `creatorFee` + `sellerRev`.
     * @param collection nft address
     * @param tokenId nft id
     * @param bidder The address of the highest bidder that won the NFT.
     * @param seller The address of the seller.
     * @param price eth amount sold for
     */
    event AuctionFinalized(
        address indexed collection,
        uint256 indexed tokenId,
        address indexed bidder,
        uint256 price,
        address seller
    );

    /// @dev ERC721 and ERC1155 collections must be whitelisted.
    modifier isWhitelisted(address _collection) {
        uint256 i;
        while (i < collectionsRegistries.length) {
            // function selector: 0xf6a3d24e or bytes4(keccak256("exists(address)"));
            (, bytes memory data) = collectionsRegistries[i].staticcall(
                abi.encodeWithSelector(0xf6a3d24e, _collection)
            );
            // exists (bytes data) contains a boolean returned by hasRole, if `true` break the loop and continue, i.e. the collection is whitelisted
            if (abi.decode(data, (bool)) == true) break;
            // if `i` equals the last index in the array AND the loop hasn't hit the break statement yet (the collection is not whitelisetd) revert (before incrementing `i` in order to save some gas).
            if (i == collectionsRegistries.length - 1) revert Unauthorized();
            // increment after, because array indexes begin at 0
            i++;
        }
        _;
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
        uint256 _price,
        uint256 _amount,
        address _commissionReceiver,
        uint256 _commissionShares,
        address _seller
    ) external isWhitelisted(_collection) {
        if (_price == 0) revert InvalidAmount(_price); // todo is this required for security or just to protect users?
        // if the seller (msg.sender) is the _commissionReceiver, i.e. if msg.sender is a gallery, they must put themselves as the _commissionReceiver, and store the artist's/collector's address in the _seller parameter.
        // This is a security check in order for the _trade function to know the seller's addres to be paid
        require(_seller != _commissionReceiver);
        require(
            tokenIdToAuctionId[_collection][_tokenId] == 0,
            "already listed"
        ); // todo is this required? i.e. won't it fail anyway if it is already listed? plus erc1155 should allow multiple listings for the same tokenId
        auctionId.increment(); // start counter at 1
        _transferNFT(
            _collection, // collection,
            msg.sender, // from
            address(this), // to
            _tokenId, // tokenId
            _amount // amount
        );
        tokenIdToAuctionId[_collection][_tokenId] = auctionId.current();
        auctions[auctionId.current()] = _Auction(
            _collection,
            _tokenId,
            payable(_seller), // // auction beneficiary, needs to be payable in order to receive funds from the auction sale
            payable(0), // bidder is only known once a bid has been placed. // highest bidder, needs to be payable in order to receive refund in case of being outbid
            _price, // The time at which this auction will not accept any new bids. This is `0` until the first bid is placed.
            _amount,
            0, // end is only known once the reserve price is met,
            payable(_commissionReceiver),
            _commissionShares
        );
        emit AuctionCreated(
            _collection,
            _tokenId,
            _seller,
            _price,
            _amount,
            auctionId.current()
        );
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

        if (_auction.bidder == address(0x0)) {
            require(msg.value > _auction.price, "value < reserve price");
            // if the auction price has been set but there is no bidder yet, set the auction timer. On the first bid, set the end to now + duration. Duration is always set to 24hrs so the below can't overflow.
            unchecked {
                _auction.end = block.timestamp + DURATION;
            }
        } else {
            require(block.timestamp < _auction.end, "ended");
            require(_auction.bidder != msg.sender, "cannot bid twice"); // We currently do not allow a bidder to increase their bid unless another user has outbid them first.
            require(
                msg.value - _auction.price > _auction.price / MIN_BID_RAISE
            ); // the raise amount setRegistrarsmust be bigger than highest bid divided by `MIN_BID_RAISE`.
            // if there is less than 15 minutes left, increment end time by 15 more. EXTENSION_DURATION is always set to 15 minutes so the below can't overflow.
            if (block.timestamp + EXTENSION_DURATION > _auction.end) {
                unchecked {
                    _auction.end += EXTENSION_DURATION;
                }
            }
            // if there is a previous highest bidder, refund the previous bid
            // solhint-disable-next-line avoid-low-level-calls
            (bool success, ) = payable(_auction.bidder).call{
                value: _auction.price
            }("");
            require(success);
        }

        _auction.price = msg.value; // new highest bit
        _auction.bidder = payable(msg.sender); // new highest bidder

        emit Bid(
            _auction.collection,
            _auction.tokenId,
            msg.sender,
            msg.value,
            _auctionId,
            _auction.end
        );
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

        emit AuctionUpdated(_auctionId, _price);
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

        // todo if seller is a gallery then it's address will not be the seller's address but the commissionReceiver's
        _transferNFT(
            _auction.collection,
            address(this),
            _auction.seller,
            _auction.tokenId,
            _auction.amount
        );

        emit AuctionCanceled(_auctionId);
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
        _transferNFT(
            _auction.collection,
            address(this),
            _auction.bidder,
            _auction.tokenId,
            _auction.amount
        );

        // pay seller, royalties and fees
        _trade(_auction);
    }

    function _trade(_Auction memory _auction) private {
        // calculate marketplace fees
        uint256 marketplaceAmount = (_auction.price * MARKETPLACE_FEE) / 10000;

        // This is a security check as well as a variable assignment, because it would revert if there was an underflow
        // note that sellerAmount may be 0 if royalties are set too high for an external collection.
        // If `royaltyAmount == (_price - marketplaceAmount)` then `sellerAmount == 0`.
        // if royalties amount exceeds price - fees amount the transaction will revert.
        uint256 sellerAmount = _auction.price - marketplaceAmount;
        bool success;

        /**
         * Pay royalties, if any
         */

        // retrieve royalties information
        (address royaltyReceiver, uint256 royaltyAmount) = getRoyalty(
            _auction.collection,
            _auction.tokenId,
            _auction.price
        );

        /*****************
         * Pay Royalties *
         ****************/

        /// @dev "Marketplaces that support this standard SHOULD NOT send a zero-value transaction if the royaltyAmount returned is 0. This would waste gas and serves no useful purpose in this EIP." - https://eips.ethereum.org/EIPS/eip-2981
        ///     Requires that `royaltyAmount > (trade.price - marketplaceAmount)`. If `royaltyAmount == (trade.price - marketplaceAmount)` then `sellerAmount == 0`.
        ///     I.e. as long as `trade.price - royaltyAmount - marketplaceAmount >= 0` the trade will not revert, royalties will be paid first and the seller will get paid whatever is left after royalties, which may even be 0 if the royalties are 95% of the sale (100% - 5% marketplace fees).
        ///     "Marketplaces that support this standard MUST pay royalties no matter where the sale occurred or in what currency" - https://eips.ethereum.org/EIPS/eip-2981 . I.e. for this reason we pay royalties before seller
        if (royaltyAmount > 0) {
            sellerAmount -= royaltyAmount; // Only subtract `royaltyAmount` if secondary sale. This assignment indirectly checks that: `royaltyAmount < (trade.price - marketplaceAmount)`, otherwise it would revert. This guarantees that external NFTs' royalties do not overflow!

            (success, ) = royaltyReceiver.call{value: royaltyAmount}("");
            require(success);
            // todo // if (success == false) revert InvalidAmount(royaltyAmount); // todo it is unlikely that the reason of this revert is the invalid amount; use another error without any parameters

            // emit RoyaltyPayment(
            //     trade.collection,
            //     trade.tokenId,
            //     royaltyReceiver,
            //     royaltyAmount
            // );
        }

        /***************************
         * Pay seller commissions *
         **************************/

        // calculate commission amount, only if commission shares/bps have been added in `createAuction`. This is both a security check and for saving gas (only calculates commission amount if bps > 0)
        if (_auction.commissionShares > 0) {
            uint256 commissionAmount = (_auction.price *
                _auction.commissionShares) / 10000;

            /**
             * since the seller can arbitrarily provide a value for commission shares, should the seller input a BPS/shares value that exceeds the amount they are entitled to for the sale, commissions will not be paid but instead the remaining amount (after royalties and fees) is paid to the seller.
             * this is a security check in order to avoid paying more than the actual price
             * `if` is better than `require` because should the royalties or commissions be set too high be mistake, the nft and eth may get locked in the contract forever
             */
            if (sellerAmount - commissionAmount > 0) {
                /**
                 * Pay commissions, if any
                 */
                (success, ) = payable(_auction.commissionReceiver).call{
                    value: commissionAmount
                }(""); /*(_price - marketplaceAmount - royaltyAmount)*/
                require(success);
                // note commission details are not emitted in Trade event
            }
        }

        /**********************************************
         * Pay marketplace fee (primary or secondary) *
         *********************************************/

        (success, ) = feeAccount.call{value: marketplaceAmount}("");
        require(success);

        /**************
         * Pay seller *
         *************/
        (success, ) = payable(_auction.seller).call{value: sellerAmount}(""); /*(_price - marketplaceAmount - royaltyAmount)*/
        require(success);

        emit AuctionFinalized(
            _auction.collection,
            _auction.tokenId,
            _auction.bidder,
            _auction.price,
            _auction.seller
        );
        // todo what about emitting all receivers and amounts, i.e. royalty, commission, marketplace amount, seller amount
    }

    function _transferNFT(
        address _collection,
        address _from,
        address _to,
        uint256 _tokenId,
        uint256 _amount
    ) private {
        if (_amount == 0)
            IERC721(_collection).transferFrom(_from, _to, _tokenId);
        else
            IERC1155(_collection).safeTransferFrom(
                _from,
                _to,
                _tokenId,
                _amount,
                "" // new bytes(0)
            );
    }

    /// @notice append to array, this will increase array length by 1
    /// @dev important, add them in the order of most likely collection registry, i.e. marketplace (for now), in order to reduce the number of exxeternal calls done by `isWhitelisted` modifier
    function pushCollectionsRegistry(address _newCollectionsRegistry)
        external
        onlyOwner
    {
        collectionsRegistries.push(_newCollectionsRegistry);
    }

    /// @notice remove array element by copying last element into the index to remove.
    /// @dev Deleting an element creates a gap in the array. One trick to keep the array compact is to move the last element into the place to delete.
    /// @dev If there is only one element left this won't work, that's intentional in order to avoid human mistakes; the `createAuction` function requires at least one registry to be set or else it will revert.
    function popCollectionsRegistry(uint256 _index) external onlyOwner {
        collectionsRegistries[_index] = collectionsRegistries[
            collectionsRegistries.length - 1
        ];
        collectionsRegistries.pop();
    }

    // Solidity can return the entire array. But this function should be avoided for arrays that can grow indefinitely in length.
    function getCollectionsRegistry() external view returns (address[] memory) {
        return collectionsRegistries;
    }

    /**
     * @dev setter function only callable by contract admin used to change the address to which fees are paid
     * @param _feeAccount is the address owned by NINFA that will collect sales fees
     */
    function setFeeAccount(address payable _feeAccount) external onlyOwner {
        feeAccount = _feeAccount;
    }

    function setConstants(
        uint256 _duration,
        uint24 _marketplaceFee,
        bytes4 _erc2981InterfaceId,
        uint256 _extensionDuration,
        uint256 _minRaise
    ) external {
        DURATION = _duration; // How long an auction lasts for once the first bid has been received.
        MARKETPLACE_FEE = _marketplaceFee; // 5% fee on all secondary sales paid to Ninfa (seller receives the remainder after paying 10% royalties to artist/gallery and 5% Ninfa, i.e. 85%)
        INTERFACE_ID_ERC2981 = _erc2981InterfaceId; // https://eips.ethereum.org/EIPS/eip-2981
        EXTENSION_DURATION = _extensionDuration; // The window for auction extensions, any bid placed in the final 15 minutes of an auction will reset the time remaining to 15 minutes.
        MIN_BID_RAISE = _minRaise; // the last highest bid is divided by this number in order to obtain the minimum bid increment. E.g. MIN_BID_RAISE = 10 is 10% increment, 20 is 5%, 2 is 50%. I.e. 100 / MIN_BID_RAISE. OpenSea uses a fixed 5% increment while SuperRare between 5-10%
    }

    /**
     * @param _royaltyRegistry see https://royaltyregistry.xyz/lookup for public addresses
     */
    constructor(address _royaltyRegistry) RoyaltyEngineV1(_royaltyRegistry) {}
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165Checker.sol)

pragma solidity 0.8.16;

import "./IERC165.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function supportsERC165Interface(address account, bytes4 interfaceId)
        internal
        view
        returns (bool)
    {
        bytes memory encodedParams = abi.encodeWithSelector(
            IERC165.supportsInterface.selector,
            interfaceId
        );
        (bool success, bytes memory result) = account.staticcall{gas: 30000}(
            encodedParams
        );
        if (result.length < 32) return false;
        return success && abi.decode(result, (bool));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library SuperRareContracts {
    address internal constant SUPERRARE_REGISTRY =
        0x17B0C8564E53f22364A6C8de6F7ca5CE9BEa4e5D;
    address internal constant SUPERRARE_V1 =
        0x41A322b28D0fF354040e2CbC676F0320d8c8850d;
    address internal constant SUPERRARE_V2 =
        0xb932a70A57673d89f4acfFBE830E8ed7f75Fb9e0;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

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

pragma solidity 0.8.16;

/// @dev Interface for the NFT Royalty Standard
interface IERC2981 {
    /// @notice Called with the sale price to determine how much royalty
    //          is owed and to whom.
    /// @param _tokenId - the NFT asset queried for royalty information
    /// @param _salePrice - the sale price of the NFT asset specified by _tokenId
    /// @return receiver - address of who should be sent the royalty payment
    /// @return royaltyAmount - the royalty payment amount for _salePrice
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);

    function setRoyaltyReceiver(address _royaltyReceiver) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

interface IERC721 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

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
    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

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
    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

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

pragma solidity 0.8.16;

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
    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 value
    );

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
    event ApprovalForAll(
        address indexed account,
        address indexed operator,
        bool approved
    );

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
    function balanceOf(address account, uint256 id)
        external
        view
        returns (uint256);

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
    function isApprovedForAll(address account, address operator)
        external
        view
        returns (bool);

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

    function totalSupply() external view returns (uint256);

    function mint(
        address _to,
        bytes32 _tokenURI,
        uint256 _amount,
        bytes memory _data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * Paired down version of the Zora Market interface
 */
interface IZoraMarket {
    struct ZoraDecimal {
        uint256 value;
    }

    struct ZoraBidShares {
        // % of sale value that goes to the _previous_ owner of the nft
        ZoraDecimal prevOwner;
        // % of sale value that goes to the original creator of the nft
        ZoraDecimal creator;
        // % of sale value that goes to the seller (current owner) of the nft
        ZoraDecimal owner;
    }

    function bidSharesForToken(uint256 tokenId) external view returns (ZoraBidShares memory);
}

/**
 * Paired down version of the Zora Media interface
 */
interface IZoraMedia {

    /**
     * Auto-generated accessors of public variables
     */
    function marketContract() external view returns(address);
    function previousTokenOwners(uint256 tokenId) external view returns(address);
    function tokenCreators(uint256 tokenId) external view returns(address);

    /**
     * ERC721 function
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

/**
 * Interface for a Zora media override
 */
interface IZoraOverride {

    /**
     * @dev Convert bid share configuration of a Zora Media token into an array of receivers and bps values
     *      Does not support prevOwner and sell-on amounts as that is specific to Zora marketplace implementation
     *      and requires updates on the Zora Media and Marketplace to update the sell-on amounts/previous owner values.
     *      An off-Zora marketplace sale will break the sell-on functionality.
     */
    function convertBidShares(address media, uint256 tokenId) external view returns (address payable[] memory, uint256[] memory);

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ISuperRareRegistry {
    /**
     * @dev Get the royalty fee percentage for a specific ERC721 contract.
     * @param _contractAddress address ERC721Contract address.
     * @param _tokenId uint256 token ID.
     * @return uint8 wei royalty fee.
     */
    function getERC721TokenRoyaltyPercentage(
        address _contractAddress,
        uint256 _tokenId
    ) external view returns (uint8);

    /**
     * @dev Utililty function to calculate the royalty fee for a token.
     * @param _contractAddress address ERC721Contract address.
     * @param _tokenId uint256 token ID.
     * @param _amount uint256 wei amount.
     * @return uint256 wei fee.
     */
    function calculateRoyaltyFee(
        address _contractAddress,
        uint256 _tokenId,
        uint256 _amount
    ) external view returns (uint256);

    /**
     * @dev Get the token creator which will receive royalties of the given token
     * @param _contractAddress address ERC721Contract address.
     * @param _tokenId uint256 token ID.
     */
    function tokenCreator(address _contractAddress, uint256 _tokenId)
        external
        view
        returns (address payable);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IRaribleV1 {
    /*
     * bytes4(keccak256('getFeeBps(uint256)')) == 0x0ebd4c7f
     * bytes4(keccak256('getFeeRecipients(uint256)')) == 0xb9c4d9fb
     *
     * => 0x0ebd4c7f ^ 0xb9c4d9fb == 0xb7799584
     */
    function getFeeBps(uint256 id) external view returns (uint[] memory);
    function getFeeRecipients(uint256 id) external view returns (address payable[] memory);
}


interface IRaribleV2 {
    /*
     *  bytes4(keccak256('getRaribleV2Royalties(uint256)')) == 0xcad96cca
     */
    struct Part {
        address payable account;
        uint96 value;
    }
    function getRaribleV2Royalties(uint256 id) external view returns (Part[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

/**
 * @dev Royalty interface for creator core classes
 */
interface IManifold {

    /**
     * @dev Get royalites of a token.  Returns list of receivers and basisPoints
     *
     *  bytes4(keccak256('getRoyalties(uint256)')) == 0xbb3bafd6
     *
     *  => 0xbb3bafd6 = 0xbb3bafd6
     */
    function getRoyalties(uint256 tokenId) external view returns (address payable[] memory, uint256[] memory);
}

// SPDX-License-Identifier: MIT

/// @author: knownorigin.io

pragma solidity ^0.8.0;

interface IKODAV2 {
    function editionOfTokenId(uint256 _tokenId) external view returns (uint256 _editionNumber);

    function artistCommission(uint256 _editionNumber) external view returns (address _artistAccount, uint256 _artistCommission);

    function editionOptionalCommission(uint256 _editionNumber) external view returns (uint256 _rate, address _recipient);
}

interface IKODAV2Override {

    /// @notice Emitted when the royalties fee changes
    event CreatorRoyaltiesFeeUpdated(uint256 _oldCreatorRoyaltiesFee, uint256 _newCreatorRoyaltiesFee);

    /// @notice For the given KO NFT and token ID, return the addresses and the amounts to pay
    function getKODAV2RoyaltyInfo(address _tokenAddress, uint256 _id, uint256 _amount)
    external
    view
    returns (address payable[] memory, uint256[] memory);

    /// @notice Allows the owner() to update the creator royalties
    function updateCreatorRoyalties(uint256 _creatorRoyaltiesFee) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IFoundation {
    /*
     *  bytes4(keccak256('getFees(uint256)')) == 0xd5a06d4c
     *
     *  => 0xd5a06d4c = 0xd5a06d4c
     */
    function getFees(uint256 tokenId) external view returns (address payable[] memory, uint256[] memory);
}

interface IFoundationTreasuryNode {
    function getFoundationTreasury() external view returns (address payable);
}

interface IFoundationTreasury {
    function isAdmin(address account) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * EIP-2981
 */
interface IEIP2981 {
    /**
     * bytes4(keccak256("royaltyInfo(uint256,uint256)")) == 0x2a55205a
     *
     * => 0x2a55205a = 0x2a55205a
     */
    function royaltyInfo(uint256 tokenId, uint256 value) external view returns (address, uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 *  Interface for an Art Blocks override
 */
interface IArtBlocksOverride {
    /**
     * @dev Get royalites of a token at a given tokenAddress.
     *      Returns array of receivers and basisPoints.
     *
     *  bytes4(keccak256('getRoyalties(address,uint256)')) == 0x9ca7dc7a
     *
     *  => 0x9ca7dc7a = 0x9ca7dc7a
     */
    function getRoyalties(address tokenAddress, uint256 tokenId)
        external
        view
        returns (address payable[] memory, uint256[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(msg.sender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
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
    function renounceOwnership() external onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import "./utils/SuperRareContracts.sol";

import "./specs/IManifold.sol";
import "./specs/IRarible.sol";
import "./specs/IFoundation.sol";
import "./specs/ISuperRare.sol";
import "./specs/IEIP2981.sol";
import "./specs/IZoraOverride.sol";
import "./specs/IArtBlocksOverride.sol";
import "./specs/IKODAV2Override.sol";
import "./IRoyaltyRegistry.sol";

/**
 * @dev Trimmed down implementation RoyaltyEngineV1 by manifold.xyz - https://github.com/manifoldxyz/royalty-registry-solidity
 * @dev Marketplaces may choose to directly inherit the Royalty Engine to save a bit of gas (from our testing, a possible savings of 6400 gas per lookup).
 * @dev ERC165 was removed because we removed all functions and modified return parameters of `getRoyalty`, thus no function interface is the same as before (0xcb23f816).
 */
contract RoyaltyEngineV1 {

    /**
     * @dev The Royalty Registry is an on chain contract that is responsible for storing Royalty configuration overrides.
     * A reference EIP2981 override implementation can be found here: https://github.com/manifoldxyz/royalty-registry-solidity/blob/main/contracts/overrides/RoyaltyOverride.sol.
     * An upgradeable version of both the Royalty Registry and Royalty Engine (v1) has been deployed for public consumption. There should only be one instance of the Royalty Registry (in order to ensure that people who wish to override do not have to do so in multiple places), while many instances of the Royalty Engine can exist.
     * @dev the original contract was modified in order to remove the need for a constructor, as the royalty registry address is public and immutable (it's an upgradable proxy)
     */
    address internal immutable ROYALTY_REGISTRY;
    

    error Unauthorized();
    error InvalidAmount(uint256 amount);
    error LengthMismatch(uint256 recipients, uint256 bps); // only used in RoyaltyEngineV1
    
    /**
     * Get the royalties for a given token and sale amount. 
     *
     * @param tokenAddress - address of token
     * @param tokenId - id of token
     * @param value - sale value of token
     * Returns two arrays, first is the list of royalty recipients, second is the amounts for each recipient.
     */
    function getRoyalty(
        address tokenAddress,
        uint256 tokenId,
        uint256 value
    )
        internal
        view
        returns (address payable/*[] memory*/ recipient, uint256/*[] memory*/ amount)
    {
        // External call to limit gas
        try
            /// @dev The way in which RoyaltyEngineV1.getRoyalty is constructed is too trusting by default given that it calls out to a registry of contracts that are user-settable without any restriction on their functionality, and therefore allows for different kinds of attacks for any marketplace that does not explicitly guard itself from gas griefing, control flow hijack or out of gas attacks.
            ///     To mitigate the griefing vector and other potential vulnerabilities, I suggest to limit the gas by default that _getRoyalty is given to an amount that no reasonable use of the RoyaltyRegistry should exceed - in my opinion at most 50,000 gas, but certainly no more than 100,000 gas.
            ///     I would suggest also to use .staticcall by default when calling out to the untrusted royalty-info supplying addresses, as no one should be modifying state within a Royalty*Lookup* context, and that would also by default prevent reentrancy.
            ///     to limit gas effectively it's necessary to limit it when calling into your own trusted function, then calling from that trusted function to an untrusted function
            ///     source: https://githubrecord.com/issue/manifoldxyz/royalty-registry-solidity/17/1067105243
            this._getRoyalty{gas: 100000}(tokenAddress, tokenId, value)
        returns (
            address payable[] memory _recipients,
            uint256[] memory _amounts
        ) {
            recipient = _recipients[0];
            amount = _amounts[0];
        } catch {
            revert InvalidAmount(amount); // technically, it could be any error, perhaps todo i should add the error message instead of simply returning the returned amount (which will be 0 anyay if the tx failed right?!)
        }
    }

    /**
     * @dev Get the royalty for a given token
     * @dev the original RoyaltyEngineV1 has been modified by removing the _specCache and the associated code,
     * using try catch statements is very cheap, no need to store `_specCache` mapping, see {RoyaltyEngineV1-_specCache}. Reference: https://www.reddit.com/r/ethdev/comments/szot8r/comment/hy5vsxb/?utm_source=share&utm_medium=web2x&context=3
     * returns recipients array, amounts array, royalty address
     */
    function _getRoyalty(
        address tokenAddress,
        uint256 tokenId,
        uint256 value
    )
        external
        view
        returns (
            address payable[] memory recipients,
            uint256[] memory amounts
        )
    {
        if (msg.sender != address(this) ) revert Unauthorized();

        address royaltyAddress = IRoyaltyRegistry(ROYALTY_REGISTRY)
            .getRoyaltyLookupAddress(tokenAddress);

        try IEIP2981(royaltyAddress).royaltyInfo(tokenId, value) returns (
            address recipient,
            uint256 amount
        ) {
            // Supports EIP2981. Return amounts
            if (amount > value ) revert InvalidAmount(amount); // note doesn't revert if amount == value
            recipients = new address payable[](1);
            amounts = new uint256[](1);
            recipients[0] = payable(recipient);
            amounts[0] = amount;
            return (
                recipients,
                amounts
            );
        } catch { }

        // SuperRare handling
        if (
            tokenAddress == SuperRareContracts.SUPERRARE_V1 ||
            tokenAddress == SuperRareContracts.SUPERRARE_V2
        ) {
            try
                ISuperRareRegistry(SuperRareContracts.SUPERRARE_REGISTRY)
                    .tokenCreator(tokenAddress, tokenId)
            returns (address payable creator) {
                try
                    ISuperRareRegistry(
                        SuperRareContracts.SUPERRARE_REGISTRY
                    ).calculateRoyaltyFee(tokenAddress, tokenId, value)
                returns (uint256 amount) {
                    recipients = new address payable[](1);
                    amounts = new uint256[](1);
                    recipients[0] = creator;
                    amounts[0] = amount;
                    return (
                        recipients,
                        amounts
                    );
                } catch {}
            } catch {}
        }

        try IManifold(royaltyAddress).getRoyalties(tokenId) returns (
            address payable[] memory recipients_,
            uint256[] memory bps
        ) {
            // Supports manifold interface.  Compute amounts
            if(recipients_.length != bps.length) revert LengthMismatch(recipients_.length, bps.length);
            return (
                recipients_,
                _computeAmounts(value, bps)
            );
        } catch {}

        try
            IRaribleV2(royaltyAddress).getRaribleV2Royalties(tokenId)
        returns (IRaribleV2.Part[] memory royalties) {
            // Supports rarible v2 interface. Compute amounts
            recipients = new address payable[](royalties.length);
            amounts = new uint256[](royalties.length);
            uint256 totalAmount;
            for (uint256 i = 0; i < royalties.length; i++) {
                recipients[i] = royalties[i].account;
                amounts[i] = (value * royalties[i].value) / 10000;
                totalAmount += amounts[i];
            }
            if (totalAmount > value ) revert InvalidAmount(totalAmount);
            return (
                recipients,
                amounts
            );
        } catch {}
        try IRaribleV1(royaltyAddress).getFeeRecipients(tokenId) returns (
            address payable[] memory recipients_
        ) {
            // Supports rarible v1 interface. Compute amounts
            recipients_ = IRaribleV1(royaltyAddress).getFeeRecipients(
                tokenId
            );
            try IRaribleV1(royaltyAddress).getFeeBps(tokenId) returns (
                uint256[] memory bps
            ) {
                if(recipients_.length != bps.length) revert LengthMismatch(recipients_.length, bps.length);
                return (
                    recipients_,
                    _computeAmounts(value, bps)
                );
            } catch {}
        } catch {}
        try IFoundation(royaltyAddress).getFees(tokenId) returns (
            address payable[] memory recipients_,
            uint256[] memory bps
        ) {
            // Supports foundation interface.  Compute amounts
            if(recipients_.length != bps.length) revert LengthMismatch(recipients_.length, bps.length);
            return (
                recipients_,
                _computeAmounts(value, bps)
            );
        } catch {}
        try
            IZoraOverride(royaltyAddress).convertBidShares(
                tokenAddress,
                tokenId
            )
        returns (
            address payable[] memory recipients_,
            uint256[] memory bps
        ) {
            // Support Zora override
            if(recipients_.length != bps.length) revert LengthMismatch(recipients_.length, bps.length);
            return (
                recipients_,
                _computeAmounts(value, bps)
            );
        } catch {}
        try
            IArtBlocksOverride(royaltyAddress).getRoyalties(
                tokenAddress,
                tokenId
            )
        returns (
            address payable[] memory recipients_,
            uint256[] memory bps
        ) {
            // Support Art Blocks override
            if(recipients_.length != bps.length) revert LengthMismatch(recipients_.length, bps.length);
            return (
                recipients_,
                _computeAmounts(value, bps)
            );
        } catch {}
        try
            IKODAV2Override(royaltyAddress).getKODAV2RoyaltyInfo(
                tokenAddress,
                tokenId,
                value
            )
        returns (
            address payable[] memory _recipients,
            uint256[] memory _amounts
        ) {
            // Support KODA V2 override
            if(_recipients.length != _amounts.length) revert LengthMismatch(_recipients.length, _amounts.length);
            return (
                _recipients,
                _amounts
            );
        } catch {}

        // No supported royalties configured
        return (recipients, amounts);

    }

    /**
     * Compute royalty amounts
     */
    function _computeAmounts(uint256 value, uint256[] memory bps)
        private
        pure
        returns (uint256[] memory amounts)
    {
        amounts = new uint256[](bps.length);
        uint256 totalAmount;
        for (uint256 i = 0; i < bps.length; i++) {
            amounts[i] = (value * bps[i]) / 10000;
            totalAmount += amounts[i];
        }
        if (totalAmount > value ) revert InvalidAmount(totalAmount);
        return amounts;
    }

    constructor(address _royaltyRegistry) {
        ROYALTY_REGISTRY = _royaltyRegistry;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

/// @author: manifold.xyz

/**
 * @dev Royalty registry interface. Modified to include only used functions, in this case only used by marketplace in order to getRoyaltyLookupAddress.
 */
interface IRoyaltyRegistry {
    /**
     * Returns royalty address location.  Returns the tokenAddress by default, or the override if it exists
     *
     * @param tokenAddress    - The token address you are looking up the royalty for
     */
    function getRoyaltyLookupAddress(address tokenAddress)
        external
        view
        returns (address);
}