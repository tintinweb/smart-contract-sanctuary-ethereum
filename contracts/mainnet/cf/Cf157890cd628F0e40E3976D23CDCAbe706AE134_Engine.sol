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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

//import "./AddressUtils.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Engine is Ownable, ReentrancyGuard {

    event OfferCreated(
        uint256 indexed _tokenId,
        address indexed _creator,
        address indexed _assetAddress,
        uint256 numCopies,
        uint256 amount,
        bool isSale
    );
    // Event triggered when an auction is created
    event AuctionCreated(
        bytes32 indexed _auctionId,
        address indexed _creator,
        address _assetAddress,
        uint256 _tokenId,
        uint256 _startPrice
    );
    // Event triggered when an auction receives a bid
    event AuctionBid(bytes32 indexed auctionId, address indexed _bidder, uint256 amount);
    // Event triggered when an ended auction winner claims the NFT
    event Claim(bytes32 indexed auctionId, address indexed claimer);
    // Event triggered when an auction received a bid that implies sending funds back to previous best bidder
    event ReturnBidFunds(bytes32 indexed auctionId, address indexed _bidder, uint256 amount);
    // Event triggered when a payment to the owner is generated, either on direct sales or on auctions.assetAddress
    // This event is useful to check that all the payments funds are the right ones.
    event PaymentToOwner(
        address receiver,
        uint256 amount,
        //    uint256 paidByCustomer,
        uint256 commission,
        uint256 safetyCheckValue
    );
    event Buy(bytes32 indexed offerId, address assetAddress, uint256 tokenId, address indexed buyer, uint256 _amount);
    // Fired when setCommission is called
    event SetCommission(uint256 oldCommission, uint256 newCommission);

    // Status of an auction, calculated using the start date, the duration and the current timeblock
    enum Status {
        pending,
        active,
        finished
    }
    // Data of an auction
    struct Auction {
        address assetAddress; // token address
        uint256 assetId; // token id
        address payable creator; // creator of the auction, which is the token owner
        uint256 startTime; // time (unix, in seconds) where the auction will start
        uint256 duration; // duration in seconds of the auction
        uint256 currentBidAmount; // amount in ETH of the current bid amount
        address payable currentBidOwner; // address of the user who places the best bid
        uint256 bidCount; // number of bids of the auction
    }

    mapping(bytes32 => Auction) public auctions;

    uint256 public commission = 0; // this is the commission in basic points that will charge the marketplace by default.
    uint256 public accumulatedCommission = 0; // this is the amount in ETH accumulated on marketplace wallet
    uint256 public totalSales = 0;
    uint256 public totalAuctions = 0;

    // used to whitelist and blacklist collections that can be sold on the marketplace
    mapping(address => bool) public whitelist;

    struct Offer {
        address assetAddress; // address of the token
        uint256 tokenId; // the tokenId returned when calling "createItem"
        address payable creator; // who creates the offer
        uint256 price; // price of each token
        bool isOnSale; // is on sale or not
        bool isAuction; // is this offer is for an auction
        bytes32 auctionId; // the id of the auction
    }
    mapping(bytes32 => Offer) public offers;

    constructor() Ownable() {

    }

    // Every time a token is put on sale, an offer is created. An offer can be a direct sale, an auction
    // or a combination of both.
    function createOffer(
        address _assetAddress, // address of the token
        uint256 _tokenId, // tokenId
        bool _isDirectSale, // true if can be bought on a direct sale
        bool _isAuction, // true if can be bought in an auction
        uint256 _price, // price that if paid in a direct sale, transfers the NFT
        uint256 _startPrice, // minimum price on the auction
        uint256 _startTime, // time when the auction will start. Check the format with frontend
        uint256 _duration // duration in seconds of the auction
    ) public {
        require(whitelist[_assetAddress], "Collection is not whitelisted");
        IERC721 asset = IERC721(_assetAddress);
        require(asset.ownerOf(_tokenId) == msg.sender, "Not the owner");
        require(
            asset.getApproved(_tokenId) == address(this),
            "NFT not approved"
        );
        // compute the unique offerid for this asset and token id
        bytes32 offerId = getAuctionId(_assetAddress,_tokenId);
        // Could not be used to update an existing offer (#02)
        Offer memory previous = offers[offerId];
        require(
            previous.isOnSale == false && previous.isAuction == false,
            "An active offer already exists"
        );

        // First create the offer
        Offer memory offer = Offer({
            assetAddress: _assetAddress,
            tokenId: _tokenId,
            creator: payable(msg.sender),
            price: _price,
            isOnSale: _isDirectSale,
            isAuction: _isAuction,
            auctionId: 0
        });
        // only if the offer has the "is_auction" flag, add the auction to the list
        if (_isAuction) {
            offer.auctionId = createAuction(
                _assetAddress,
                _tokenId,
                _startPrice,
                _startTime,
                _duration
            );
        }
        offers[offerId] = offer;
        emit OfferCreated(
            _tokenId,
            msg.sender,
            _assetAddress,
            1,
            _price,
            _isDirectSale
        );
    }

    // returns the auctionId from the offerId
    function getAuctionId(address _assetAddress, uint256 _tokenId) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_assetAddress, _tokenId));
    }

    // Remove an auction from the offer that did not have previous bids. Beware could be a direct sale
    function removeFromAuction(bytes32 auctionId) public {
        Offer memory offer = offers[auctionId];
        require(msg.sender == offer.creator, "You are not the owner");
        Auction memory auction = auctions[auctionId];
        require(auction.assetAddress != address(0), "There is no auction");
        require(auction.bidCount == 0, "Bids existing");
        offer.isAuction = false;
        offer.auctionId = 0;
        offers[auctionId] = offer;
        delete auctions[auctionId];
    }

    // remove a direct sale from an offer. Beware that could be an auction for the token
    function removeFromSale(bytes32 offerId) public {
        Offer memory offer = offers[offerId];
        require(msg.sender == offer.creator, "You are not the owner");
        offer.isOnSale = false;
        offers[offerId] = offer;
    }

    // Changes the default commission. Only the owner of the marketplace can do that. In basic points
    function setCommission(uint256 _commission) public onlyOwner {
        require(_commission <= 5000, "Commission too high");
        emit SetCommission(
            commission,
            _commission
        );
        commission = _commission;
    }

    // Admin has the ability of whitelisting sellable collections
    function whitelistCollection(address collectionAddr, bool whitelisted) public onlyOwner {
       whitelist[collectionAddr] = whitelisted;
    }

    // called in a direct sale by the customer. Transfer the nft to the customer,
    // the commission for the marketplace is keeped on the contract and the remaining
    // funds are transferred to the token owner.
    // is there is an auction open, the last bid amount is sent back to the last bidder
    // After that, the offer is cleared.
    function buy(bytes32 offerId) external payable nonReentrant {
        address buyer = msg.sender;
        uint256 paidPrice = msg.value;

        Offer memory offer = offers[offerId];
        require(offer.isOnSale == true, "NFT not in direct sale");
        uint256 price = offer.price;
        require(paidPrice >= price, "Price is not enough");

        //if there is a bid and the auction is closed but not claimed, give priority to claim
        require(
            !(offer.isAuction == true &&
                isFinished(offer.auctionId) &&
                auctions[offer.auctionId].bidCount > 0),
            "Claim asset from auction has priority"
        );

        emit Claim(offerId, buyer);
        IERC721 asset = IERC721(offer.assetAddress);
        asset.safeTransferFrom(offer.creator, buyer, offer.tokenId);

        uint256 commissionToPay = paidPrice * commission / 10000;

        uint256 amountToPay = paidPrice - commissionToPay;

        (bool success2, ) = offer.creator.call{value: amountToPay}("");
        require(success2, "Transfer failed.");
        emit PaymentToOwner(
            offer.creator,
            amountToPay,
            //     paidPrice,
            commissionToPay,
            amountToPay + ((paidPrice * commission) / 10000) // using safemath will trigger an error because of stack size
        );

        // is there is an auction open, we have to give back the last bid amount to the last bidder
        if (offer.isAuction == true) {
            Auction memory auction = auctions[offer.auctionId];
            // #4. Only if there is at least a bid and the bid amount > 0, give it back to last bidder
            if (auction.currentBidAmount != 0 && auction.bidCount > 0) {
                // return funds to the previuos bidder
                (bool success3, ) = auction.currentBidOwner.call{
                    value: auction.currentBidAmount
                }("");
                require(success3, "Transfer failed.");
                emit ReturnBidFunds(
                    offer.auctionId,
                    auction.currentBidOwner,
                    auction.currentBidAmount
                );
            }
            delete auctions[offer.auctionId];
        }

        emit Buy(offerId, offer.assetAddress, offer.tokenId, msg.sender, msg.value);

        accumulatedCommission += commissionToPay;

        delete offers[offerId];

        totalSales += msg.value;
    }

    // Creates an auction for a token. It is linked to an offer
    function createAuction(
        address _assetAddress, // address of the SeahorseNFT token
        uint256 _assetId, // id of the NFT
        uint256 _startPrice, // minimum price
        uint256 _startTime, // time when the auction will start. Check with frontend because is unix time in seconds, not millisecs!
        uint256 _duration // duration in seconds of the auction
    ) private returns (bytes32) {
        if (_startTime == 0) {
            _startTime = block.timestamp;
        }
        require(_startTime >= block.timestamp,"Invalid start time");

        bytes32 auctionId = getAuctionId(_assetAddress, _assetId);

        Auction memory auction = Auction({
            creator: payable(msg.sender),
            assetAddress: _assetAddress,
            assetId: _assetId,
            startTime: _startTime,
            duration: _duration,
            currentBidAmount: _startPrice,
            currentBidOwner: payable(address(0)),
            bidCount: 0
        });
        auctions[auctionId] = auction;
        totalAuctions++;
        emit AuctionCreated(auctionId, auction.creator, _assetAddress, _assetId, _startPrice);

        return auctionId;
    }

    // At the end of the call, the amount is saved on the marketplace wallet and the previous bid amount is returned to old bidder
    // except in the case of the first bid, as could exists a minimum price set by the creator as first bid.
    function bid(bytes32 auctionId) public payable nonReentrant {
        Auction storage auction = auctions[auctionId];
        require(auction.creator != address(0), "Cannot bid. Error in auction");
        require(isActive(auctionId), "Bid not active");
        require(msg.value > auction.currentBidAmount, "Bid too low");
        // we got a better bid. Return funds to the previous best bidder
        // and register the sender as `currentBidOwner`

        // this check is for not transferring back funds on the first bid, as the fist bid is the minimum price set by the auction creator
        // and the bid owner is address(0)
        if (
            auction.currentBidAmount != 0 &&
            auction.currentBidOwner != address(0)
        ) {
            // return funds to the previuos bidder
            (bool success, ) = auction.currentBidOwner.call{
                value: auction.currentBidAmount
            }("");
            require(success, "Transfer failed.");
            emit ReturnBidFunds(
                auctionId,
                auction.currentBidOwner,
                auction.currentBidAmount
            );
        }
        // register new bidder
        auction.currentBidAmount = msg.value;
        auction.currentBidOwner = payable(msg.sender);
        auction.bidCount++;

        emit AuctionBid(auctionId, msg.sender, msg.value);
    }

    function getTotalAuctions() public view returns (uint256) {
        return totalAuctions;
    }

    function isActive(bytes32 auctionId) public view returns (bool) {
        return getStatus(auctionId) == Status.active;
    }

    function isFinished(bytes32 auctionId) public view returns (bool) {
        return getStatus(auctionId) == Status.finished;
    }

    // The auctions did not be affected if the current time is 15 seconds wrong
    // So, according to Consensys security advices, it is safe using block.timestamp
    function getStatus(bytes32 auctionId) public view returns (Status) {
        Auction storage auction = auctions[auctionId];
        if (block.timestamp < auction.startTime) {
            return Status.pending;
        } else if (block.timestamp < (auction.startTime + auction.duration)) {
            return Status.active;
        } else {
            return Status.finished;
        }
    }

    // returns the end date of the auction, in unix time using seconds
    function endDate(bytes32 auctionId) public view returns (uint256) {
        Auction storage auction = auctions[auctionId];
        return auction.startTime + auction.duration;
    }

    // returns the user with the best bid until now on an auction
    function getCurrentBidOwner(bytes32 auctionId)
        public
        view
        returns (address)
    {
        return auctions[auctionId].currentBidOwner;
    }

    // returns the amount in ETH of the best bid until now on an auction
    function getCurrentBidAmount(bytes32 auctionId)
        public
        view
        returns (uint256)
    {
        return auctions[auctionId].currentBidAmount;
    }

    // returns the number of bids of an auction (0 by default)
    function getBidCount(bytes32 auctionId) public view returns (uint256) {
        return auctions[auctionId].bidCount;
    }

    // returns the winner of an auction once the auction finished
    function getWinner(bytes32 auctionId) public view returns (address) {
        require(isFinished(auctionId), "Auction not finished yet");
        return auctions[auctionId].currentBidOwner;
    }

    // called when the auction is finished by the user who won the auction
    // transfer the nft to the caller,
    // the commission of the marketplace is calculated, and the remaining funds
    // are transferred to the token owner
    // After this, the offer is disabled
    function closeAuction(bytes32 auctionId) public {
        //    address winner = getWinner(auctionIndex);
        //    require(winner == msg.sender, "You are not the winner of the auction");
        auctionTransferAsset(auctionId);
    }

    function auctionTransferAsset(bytes32 auctionId) private nonReentrant {
        // require(isFinished(auctionId), "The auction is still active");
        address winner = getWinner(auctionId);

        Auction storage auction = auctions[auctionId];

        // the token could be sold in direct sale or the owner cancelled the auction
        Offer memory offer = offers[auctionId];
        require(offer.isAuction == true, "NFT not in auction");

        if (auction.bidCount > 0) {
            IERC721 asset = IERC721(auction.assetAddress);

            // #3, check if the asset owner had removed their approval or the offer creator is not the token owner anymore.
            require(
                asset.getApproved(auction.assetId) == address(this),
                "NFT not approved"
            );
            require(
                asset.ownerOf(auction.assetId) == auction.creator,
                "Auction creator is not nft owner"
            );

            asset.safeTransferFrom(auction.creator, winner, auction.assetId);

            emit Claim(auctionId, winner);

            uint256 commissionToPay = auction.currentBidAmount * commission / 10000;
            uint256 amountToPay = auction.currentBidAmount - commissionToPay;

            (bool success, ) = auction.creator.call{value: amountToPay}("");
            require(success, "Transfer failed.");
            emit PaymentToOwner(
                auction.creator,
                amountToPay,
                //  auction.currentBidAmount,
                commissionToPay,
                amountToPay + commissionToPay
            );

            accumulatedCommission += commissionToPay;

            totalSales += auction.currentBidAmount;
        }

        delete offers[auctionId];
        delete auctions[auctionId];
        totalAuctions--;
    }

    //Call this method
    function cancelAuctionOfToken(bytes32 auctionId)
        external
        nonReentrant
    {
        Offer memory offer = offers[auctionId];
        // is there is an auction open, we have to give back the last bid amount to the last bidder
        require(offer.isAuction, "Offer is not an auction");
        Auction memory auction = auctions[auctionId];
        // in case the caller is not the owner, check that the asset is no longer available
        // if the asset no longer belongs to the owner or the engine no longer has an approval,
        // the auction can be canceled by anyone
        if(msg.sender != owner()) {
            IERC721 asset = IERC721(auction.assetAddress);
            require(
                asset.getApproved(auction.assetId) != address(this) ||
                asset.ownerOf(auction.assetId) != auction.creator,
                "The asset behind this auction is still valid"
            );
        }
        

        if (auction.bidCount > 0) returnLastBid(offer, auction);

        delete offers[auctionId];
        delete auctions[auctionId];
    }

    function returnLastBid(Offer memory offer, Auction memory auction)
        internal
    {
        // is there is an auction open, we have to give back the last bid amount to the last bidder
        require(offer.isAuction, "Offer is not an auction");
        // #4. Only if there is at least a bid and the bid amount > 0, give it back to last bidder
        require(
            auction.currentBidAmount != 0 &&
                auction.bidCount > 0 &&
                auction.currentBidOwner != address(0),
            "No bids yet"
        );
        require(
            offer.creator != auction.currentBidOwner,
            "Offer owner cannot retrieve own funds"
        );
        // return funds to the previuos bidder
        (bool success3, ) = auction.currentBidOwner.call{
            value: auction.currentBidAmount
        }("");
        require(success3, "Transfer failed.");
        emit ReturnBidFunds(
            offer.auctionId,
            auction.currentBidOwner,
            auction.currentBidAmount
        );
    }

    // This method is only callable by the marketplace owner and transfer funds from
    // the marketplace to the caller.
    // It us used to move the funds from the marketplace to the investors
    function extractBalance() public nonReentrant onlyOwner {
        address payable me = payable(msg.sender);
        (bool success, ) = me.call{value: accumulatedCommission}("");
        require(success, "Transfer failed.");
        accumulatedCommission = 0;
    }
}