// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./interfaces/INeptunity.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// ███    ██ ███████ ██████  ████████ ██    ██ ███    ██ ██ ████████ ██    ██
// ████   ██ ██      ██   ██    ██    ██    ██ ████   ██ ██    ██     ██  ██
// ██ ██  ██ █████   ██████     ██    ██    ██ ██ ██  ██ ██    ██      ████
// ██  ██ ██ ██      ██         ██    ██    ██ ██  ██ ██ ██    ██       ██
// ██   ████ ███████ ██         ██     ██████  ██   ████ ██    ██       ██

contract NeptunityEnglishAuction is Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private auctionId;
    // solhint-disable-next-line
    INeptunity private NeptunityERC721;

    uint256 private constant DURATION = 1 days; // How long an auction lasts for once the first bid has been received.
    uint256 private constant EXTENSION_DURATION = 15 minutes; // The window for auction extensions, any bid placed in the final 15 minutes of an auction will reset the time remaining to 15 minutes.
    uint256 private constant MIN_BID_RAISE = 50; // next bid should be 2% more than last price

    mapping(uint256 => Auction) private auctions; // The auction id for a specific NFT. This is deleted when an auction is finalized or canceled.
    mapping(uint256 => bool) private isAuctionFinalized; //

    /// @notice Stores the auction configuration for a specific NFT.
    struct Auction {
        uint256 tokenId;
        address payable seller; // auction beneficiary, needs to be payable in order to receive funds from the auction sale
        address payable bidder; // highest bidder, needs to be payable in order to receive refund in case of being outbid
        uint256 price; // reserve price or highest bid
        uint256 end; // The time at which this auction will not accept any new bids. This is `0` until the first bid is placed.
    }

    /**
     * @notice Emitted when an NFT is listed for auction.
     * @param seller The address of the seller.
     * @param tokenId The id of the NFT.
     * @param price The reserve price to kick off the auction.
     * @param auctionId The id of the auction that was created.
     */
    event Created(
        uint256 indexed tokenId,
        address indexed seller,
        uint256 indexed auctionId,
        uint256 price
    );

    /**
     * @notice Emitted when an auction is cancelled.
     * @dev This is only possible if the auction has not received any bids.
     * @param auctionId The id of the auction that was cancelled.
     */
    event Canceled(uint256 indexed auctionId);

    /**
     * @notice Emitted when a bid is placed.
     * @param bidder The address of the bidder.
     * @param tokenId nft id
     * @param auctionId The id of the auction this bid was for.
     * @param price The amount of the bid.
     * @param end The new end time of the auction (which may have been set or extended by this bid).
     */
    event Bid(
        address indexed bidder,
        uint256 indexed tokenId,
        uint256 indexed auctionId,
        uint256 price,
        uint256 end
    );

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
     * @dev The amount of the highest bid/final sale price for this auction
     * is `marketplace` + `creatorFee` + `sellerRev`.
     * @param tokenId nft id
     * @param bidder The address of the highest bidder that won the NFT.
     * @param seller The address of the seller.
     * @param auctionId The id of the auction that was finalized.
     * @param price wei amount sold for.
     */
    event Finalized(
        uint256 indexed tokenId,
        address indexed bidder,
        uint256 price,
        address seller,
        uint256 auctionId
    );

    /********************************/
    /*********** MODIFERS ***********/
    /********************************/

    modifier auctionRequirements(uint256 _auctionId) {
        Auction memory _auction = auctions[_auctionId];

        require(_auction.seller == msg.sender, "must be auction creator"); // implicitly also checks that the auction exists
        require(_auction.end == 0, "auction already started");
        _;
    }

    /**
     * @notice Creates an auction for the given NFT. The NFT is held in escrow until the auction is finalized or canceled.
     * @param _tokenId The id of the NFT.
     * @param _price The initial reserve price for the auction.
     */
    function createAuction(uint256 _tokenId, uint256 _price) external {
        require(_price > 0);

        auctionId.increment(); // start counter at 1

        NeptunityERC721.transferFrom(msg.sender, address(this), _tokenId);

        auctions[auctionId.current()] = Auction(
            _tokenId,
            payable(msg.sender), // // auction beneficiary, needs to be payable in order to receive funds from the auction sale
            payable(0), // bidder is only known once a bid has been placed. // highest bidder, needs to be payable in order to receive refund in case of being outbid
            _price, // The time at which this auction will not accept any new bids. This is `0` until the first bid is placed.
            0 // end is only known once the reserve price is met,
        );

        emit Created(_tokenId, msg.sender, auctionId.current(), _price);
    }

    function finalize(uint256 _auctionId) external {
        Auction memory _auction = auctions[_auctionId];

        require(!isAuctionFinalized[_auctionId], "auction already finalized");
        require(_auction.end > 0, "auction not started"); // there must be at least one bid higher than the reserve price in order to execute the trade, no bids mean no end time

        require(block.timestamp > _auction.end, "auction in progress");

        // Remove the auction.
        delete auctions[_auctionId];
        isAuctionFinalized[_auctionId] = true;

        // transfer nft to auction winner
        NeptunityERC721.transferFrom(
            address(this),
            _auction.bidder,
            _auction.tokenId
        );
        // pay seller, royalties and fees

        _trade(_auction.seller, _auction.tokenId, _auction.price);

        emit Finalized(
            _auction.tokenId,
            _auction.bidder,
            _auction.price,
            _auction.seller,
            _auctionId
        );
    }

    /**
     * @notice Place a bid in an auction
     * @dev If this is the first bid on the auction, the countdown will begin. If there is already an outstanding bid, the previous bidder will be refunded at this time and if the bid is placed in the final moments of the auction, the countdown may be extended.
     * @param _auctionId The id of the auction to bid on
     */
    function placeBid(uint256 _auctionId) external payable {
        Auction storage _auction = auctions[_auctionId];

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
            require(msg.value > _auction.price); // the bid must be bigger than highest bid divided by `MIN_BID_RAISE`.
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
            msg.sender,
            _auction.tokenId,
            _auctionId,
            msg.value,
            _auction.end
        );
    }

    /**
     * @notice If an auction has been created but has not yet received bids, the reservePrice may be
     * changed by the seller.
     * @param _auctionId The id of the auction to change.
     * @param _price The new reserve price for this auction.
     */
    function updateAuction(uint256 _auctionId, uint256 _price)
        external
        auctionRequirements(_auctionId)
    {
        require(_price > 0, "Price must be more than 0"); // can't set to zero or else it will not be possible to take bids because the auction will be considered nonexistent.

        // Update the current reserve price.
        auctions[_auctionId].price = _price;

        emit Updated(_auctionId, _price);
    }

    /**
     * @notice If an auction has been created but has not yet received bids, it may be canceled by the seller.
     * @dev The NFT is transferred back to the owner unless there is still a buy price set.
     * @param _auctionId The id of the auction to cancel.
     */
    function cancelAuction(uint256 _auctionId)
        external
        auctionRequirements(_auctionId)
    {
        Auction memory _auction = auctions[_auctionId];

        delete auctions[_auctionId];

        NeptunityERC721.transferFrom(
            address(this),
            _auction.seller,
            _auction.tokenId
        );

        emit Canceled(_auctionId);
    }

    /**
     * @dev to pay royalties and sales amount
     */
    function _trade(
        address _seller,
        uint256 _tokenId,
        uint256 _price
    ) private {
        // extract data from neptunity erc721
        (
            address marketplaceFeeWallet,
            bool isSecondarySale,
            uint24 artistFee,
            uint24 primaryPlatformBPs,
            uint24 secondaryPlatformBPs,
            address artist
        ) = NeptunityERC721.getStateInfo(_tokenId);

        uint256 sellerAmount = _price;
        uint256 platformFee;
        uint256 royaltiesFee;
        bool success;

        if (!isSecondarySale) {
            //  for primary sale pay primaryPlatformBPs
            platformFee = (sellerAmount * primaryPlatformBPs) / 10000;
            sellerAmount -= platformFee; // subtracting primaryfee amount
            // solhint-disable-next-line avoid-low-level-calls
            (success, ) = marketplaceFeeWallet.call{value: platformFee}(""); // pay marketplaceFee
            // solhint-disable-next-line
            require(success);

            // mark primary sale complete for tokenId
            NeptunityERC721.setSecondarySale(_tokenId);
        } else {
            //  for secondaryPlatformBPs precentages.
            platformFee = (sellerAmount * secondaryPlatformBPs) / 10000;
            sellerAmount -= platformFee; // subtracting secondary fee amount
            // solhint-disable-next-line avoid-low-level-calls
            (success, ) = marketplaceFeeWallet.call{value: platformFee}(""); // pay marketplaceFee
            // solhint-disable-next-line
            require(success);

            //  pay royalties to artist
            royaltiesFee = (sellerAmount * artistFee) / 10000; // Fee paid by the user that fills the order, a.k.a. msg.sender.
            sellerAmount -= royaltiesFee;

            // solhint-disable-next-line avoid-low-level-calls
            (success, ) = payable(artist).call{value: royaltiesFee}(""); // transfer secondary sale fees to fee artist
            // solhint-disable-next-line reason-string
            require(success);
        }

        // solhint-disable-next-line avoid-low-level-calls
        (success, ) = _seller.call{value: sellerAmount}(""); // pay the seller fee (price - marketplaceFee - royaltiesFee )
        // solhint-disable-next-line
        require(success);
    }

    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE` to the account that deploys the contract.
     */
    constructor(address neptunityERC721) {
        require(neptunityERC721 != address(0), "Invalid address");

        NeptunityERC721 = INeptunity(neptunityERC721);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface INeptunity {
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

    function mint(
        string memory _tokenURI,
        address _to,
        uint24 _artistFee
    ) external;

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function exists(uint256 tokenId) external view returns (bool);

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) external view returns (address);

    /**
     * @dev returns the artist wallet address for the token Id
     */
    function artists(uint256 _tokenId) external view returns (address);

    /**
     * @dev only either auction or marketplace contract can call it to set tokenId as secondary sale.
     */
    function setSecondarySale(uint256 _tokenId) external;

    /**
     * @dev returns basic information about the token, and marketplace*/
    function getStateInfo(uint256 _tokenId)
        external
        view
        returns (
            address,
            bool,
            uint24,
            uint24,
            uint24,
            address
        );
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