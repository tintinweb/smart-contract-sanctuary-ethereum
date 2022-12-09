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

// SPDX-License-Identifier: MIT
pragma solidity >0.8.0;

///
/// @dev Interface for the NFT Royalty Standard
///
interface IApprovedProxy {
    function call(
        address dest,
        bytes calldata data,
        uint8 howToCall
    ) external returns (bool);

    function assertCall(
        address dest,
        bytes calldata data,
        uint8 howToCall
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >0.8.0;

struct Royalties {
    address payable recepient;
    uint96 royalty;
}

interface IRoyaltyProvider {
    function getRoyalties(address token, uint256 tokenId)
        external
        returns (Royalties[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./interfaces/IRoyaltyProvider.sol";
import "./interfaces/IApprovedProxy.sol";

error NotAllowed(); 
error NotEnoughMoney();
error TokenAlreadyOnSale();
error NotTokenOwner();
error ItemNotOnAuction();
error ItemNotOnSell();
error AuctionTimeIsUp();
error WrongAuctionDuration();
error WrongAuctionStartTime();
error BidIsTooLow();
error AuctionStillRunning();
error AuctionNotRunning();
error UserNotInWhitelist();
error Locked();


contract Marketplace is Ownable {

    address feeRecepient;
    uint96 marketplaceFee; /// in BP, 1% = 100
    address proxy;
    uint96 offerId;
    bool locked;
    IRoyaltyProvider royaltyRegistry;

    enum State {
        DOESNTEXIST,
        EXIST,
        ONSELL,
        ONAUCTION
    }

    enum OfferState {
        DOESNTEXIST,
        EXIST,
        ACCEPTED,
        DELETED
    }

    struct Offer {
        uint256 nftId;
        address maker;
        address collection;
        OfferState offerState;
        Price price;
    }

    struct Item {
        address seller;
        uint96 marketFee;
        State itemState;
        Price price;
        AuctionInfo auctionInfo;
    }

    struct AuctionInfo {
        uint128 auctionStartTime;
        uint128 auctionEndTime;
        uint128 bids; // amount of bids
        uint96 minStep;
        address lastBidder;
    }

    struct Price {
        uint96 price;
        address tokenAddr; /// if address(0) then eth\bnb\etc...
    }

    mapping(address => mapping(uint256 => Item)) public items; // collection address => nft id => Item struct
    mapping(uint256 => Offer) public offers;
    mapping(address => bool) public approvedTokens;

    event ItemListed(
        address maker,
        uint256 price,
        address collection,
        uint256 nftId,
        address tokenAddr
    );
    event ItemSold(
        uint256 nftId,
        address collection,
        address buyer,
        address seller,
        uint256 price,
        address tokenAddr
    );
    event ItemRemoved(
        address seller,
        uint8 typeOfSell,
        address collection,
        uint256 nftId
    );
    event AuctionStarted(
        address maker,
        uint256 price,
        address collection,
        uint256 nftId,
        uint256 auctionEndTime,
        address tokenAddr,
        uint256 minStep,
        uint256 auctionStartTime
    );
    event Bid(
        address maker,
        uint256 price,
        address tokenAddr,
        address collection,
        uint256 nftId
    );
    event AuctionFinished(
        address seller,
        address buyer,
        address collection,
        uint256 nftId,
        uint256 price,
        address tokenAddr
    );
    event AuctionCancelled(
        address seller, 
        address collection, 
        uint256 nftId
    );
    event OfferCreated(
        uint256 offerId,
        address maker,
        uint256 price,
        address tokenAddr,
        address collection,
        uint256 nftId
    );
    event OfferAccepted(
        uint256 offerId,
        address seller,
        address maker,
        uint256 price,
        address tokenAddr
    );
    event OfferDeleted(
        uint256 offerId, 
        address maker
    );
    event FeePayout(
        Royalties[] royalty,
        address token,
        uint256 nftId,
        address payTokenAddr
    );
    event MarketFeeChanged(
        uint256 oldFee, 
        uint256 newFee
    );
    event TokenStateUpdated(
        address token, 
        bool state
    );
    event FeeRecepientUpdated(
        address oldRecepient, 
        address newRecepient
    );
    event ContractLock(
        bool curentState
    );

    modifier onlyApprovedTokens(address token) {
        if (!approvedTokens[token]) revert NotAllowed();
        _;
    }

    modifier isLocked() {
        if (locked) revert Locked();
        _;
    }

    modifier onlyTokenOwner(address _collection, uint256 _nftId) {
        address tokenOwner = IERC721(_collection).ownerOf(_nftId);
        if (msg.sender != tokenOwner) revert NotTokenOwner();
        _;
    }

    constructor(
        address _royaltyRegistry,
        address _feeRecepient,
        address _proxy
    ) {
        royaltyRegistry = IRoyaltyProvider(_royaltyRegistry);
        feeRecepient = _feeRecepient;
        proxy = _proxy;
    }

    receive() external payable {}

    function listItemOnDirectSale(uint256 _nftId, address _collection, Price calldata _price) external {
        AuctionInfo memory _auctionInfo;
        listItem(_nftId, _collection, _price, State.ONSELL, _auctionInfo);
    }

    function removeItem(address _collection, uint256 _nftId) onlyTokenOwner(_collection,_nftId) external {
        if (items[_collection][_nftId].seller != msg.sender)
            revert NotAllowed();

        State oldState = items[_collection][_nftId].itemState;
        if (oldState != State.ONSELL) {
            revert ItemNotOnSell();
        }
        items[_collection][_nftId].itemState = State.EXIST;

        emit ItemRemoved(
            items[_collection][_nftId].seller,
            uint8(oldState),
            _collection,
            _nftId
        );
    }

    function buyItem(address _collection, uint256 _nftId) external payable {
        if (items[_collection][_nftId].itemState != State.ONSELL) {
            revert NotAllowed();
        }

        address tokenOwner = IERC721(_collection).ownerOf(_nftId);
        if (items[_collection][_nftId].seller != tokenOwner) {
            revert ItemNotOnSell();
        }

        address buyer = msg.sender;
        transferWithFee(
            items[_collection][_nftId].price.price,
            _nftId,
            _collection,
            items[_collection][_nftId].price.tokenAddr,
            buyer,
            items[_collection][_nftId].seller
        );

        transferERC721(
            items[_collection][_nftId].seller,
            buyer,
            _nftId,
            _collection
        );

        items[_collection][_nftId].itemState = State.EXIST;

        emit ItemSold(
            _nftId,
            _collection,
            msg.sender,
            items[_collection][_nftId].seller,
            items[_collection][_nftId].price.price,
            items[_collection][_nftId].price.tokenAddr
        );
    }

    function listItemOnAuction(uint256 _nftId,
        address _collection,
        Price calldata _price,
        uint128 _auctionStartTime,
        uint128 _auctionDuration,
        uint96 _auctionMinStep
    ) external {
        if (_auctionDuration < 10 minutes || _auctionDuration > 1 days * 365)
            revert WrongAuctionDuration();

        if (_auctionStartTime > 1 days * 365 + block.timestamp)
            revert WrongAuctionStartTime();

        AuctionInfo memory _auctionInfo;
        _auctionInfo.auctionStartTime = _auctionStartTime;
        _auctionInfo.auctionEndTime = _auctionStartTime + _auctionDuration;
        _auctionInfo.minStep = _auctionMinStep;
        listItem(_nftId, _collection, _price, State.ONAUCTION, _auctionInfo);
    }

   function makeBid(uint256 _nftId, address _collection, uint96 _price) external payable {
        Item storage item = items[_collection][_nftId];
        
        if (item.price.tokenAddr == address(0)) _price = uint96(msg.value);

        if (item.itemState != State.ONAUCTION) revert ItemNotOnAuction();

        if (block.timestamp > item.auctionInfo.auctionEndTime) revert AuctionTimeIsUp();

        if (block.timestamp < item.auctionInfo.auctionStartTime) revert AuctionNotRunning();

        // first bit can be great or equal price 
        if (_price < item.price.price) revert BidIsTooLow();

        if (item.auctionInfo.bids != 0 && item.auctionInfo.minStep == 0  && _price == item.price.price) revert BidIsTooLow();

        if (item.auctionInfo.bids != 0 && item.auctionInfo.minStep != 0  && _price < item.auctionInfo.minStep + item.price.price) revert BidIsTooLow();



        if (item.auctionInfo.bids != 0) {
            transfer(
                item.price.price,
                item.price.tokenAddr,
                address(this),
                item.auctionInfo.lastBidder
            );
        }

        item.auctionInfo.lastBidder = msg.sender;
        item.price.price = _price;
        item.auctionInfo.bids++;
        address buyer = msg.sender;
        transfer(item.price.price, item.price.tokenAddr, buyer, address(this));

        emit Bid(msg.sender, _price, item.price.tokenAddr, _collection, _nftId);
    }

    function finishAuction(address _collection, uint256 _nftId) external {
        Item storage item = items[_collection][_nftId];
        if (item.itemState != State.ONAUCTION) revert ItemNotOnAuction();

        if (item.auctionInfo.bids > 0) {
            if (block.timestamp < item.auctionInfo.auctionEndTime)
                revert AuctionStillRunning();

            transferWithFee(
                item.price.price,
                _nftId,
                _collection,
                item.price.tokenAddr,
                address(this),
                item.seller
            );
            IERC721(_collection).approve(proxy, _nftId); //
            transferERC721(
                address(this),
                item.auctionInfo.lastBidder,
                _nftId,
                _collection
            );

            emit AuctionFinished(
                item.seller,
                item.auctionInfo.lastBidder,
                _collection,
                _nftId,
                item.price.price,
                item.price.tokenAddr
            );
        } else {
            if (item.seller != msg.sender) revert NotAllowed();

            IERC721(_collection).approve(proxy, _nftId); 
            transferERC721(
                address(this),
                item.seller,
                _nftId,
                _collection
            );

            emit AuctionCancelled(item.seller, _collection, _nftId);
        }

        item.itemState = State.EXIST;
    }

    function createOffer(
        uint256 _nftId,
        address _collection,
        Price calldata _price
    ) external {

        if (_price.tokenAddr == address(0)) revert NotAllowed();
        offerId++;
        offers[offerId].maker = msg.sender;
        offers[offerId].nftId = _nftId;
        offers[offerId].collection = _collection;
        offers[offerId].price = _price;
        offers[offerId].offerState = OfferState.EXIST;

        transfer(_price.price, _price.tokenAddr, msg.sender, address(this));
       
        emit OfferCreated(
            offerId,
            msg.sender,
            _price.price,
            _price.tokenAddr,
            _collection,
            _nftId
        );
    }

    function acceptOffer(uint256 _offerId)  external {
        Offer storage offer = offers[_offerId];

        address tokenOwner = IERC721(offer.collection).ownerOf(offer.nftId);
        if (msg.sender != tokenOwner) {
            revert NotTokenOwner();
        }

        if (offer.offerState != OfferState.EXIST) {
            revert NotAllowed();
        }

        transferWithFee(
            offer.price.price,
            offer.nftId,
            offer.collection,
            offer.price.tokenAddr,
            address(this),
            tokenOwner
        );

        transferERC721(tokenOwner, offer.maker, offer.nftId, offer.collection);

        items[offer.collection][offer.nftId].itemState = State.EXIST;
        offers[_offerId].offerState = OfferState.ACCEPTED;

        emit OfferAccepted(
            _offerId,
            tokenOwner,
            offer.maker,
            offer.price.price,
            offer.price.tokenAddr
        );
        items[offer.collection][offer.nftId].seller = tokenOwner;
    }

    function deleteOffer(uint256 _offerId) external {
        if (offers[_offerId].maker != msg.sender) revert NotAllowed();

        if (offers[_offerId].offerState != OfferState.EXIST)
            revert NotAllowed();

        transfer(
            offers[_offerId].price.price,
            offers[_offerId].price.tokenAddr,
            address(this),
            offers[_offerId].maker
        );
        
        offers[_offerId].offerState = OfferState.DELETED;

        emit OfferDeleted(_offerId, offers[_offerId].maker);
    }

    function setTokenState(address token, bool state) external onlyOwner {
        approvedTokens[token] = state;
        emit TokenStateUpdated(token, state);
    }

    function setMarketplaceFee(uint96 _marketplaceFee) external onlyOwner {
        uint256 oldFee = marketplaceFee;
        marketplaceFee = _marketplaceFee;
        emit MarketFeeChanged(oldFee, marketplaceFee);
    }

    function setFeeRecepient(address _feeRecepient) external onlyOwner {
        address oldRecepient = feeRecepient;
        feeRecepient = _feeRecepient;
        emit FeeRecepientUpdated(oldRecepient, feeRecepient);
    }

    function lock() external onlyOwner {
        locked = !locked;
        emit ContractLock(locked);
    }

    function sweep(address token, uint256 amount) external onlyOwner {
        if (token == address(0)) {
            (bool sent, ) = payable(msg.sender).call{value: amount}("");
        } else {
            IERC20(token).transfer(msg.sender, amount);
        }
    }
 
    function transferWithFee(
        uint256 sellingPrice,
        uint256 nftId,
        address collection,
        address payTokenAddr,
        address from,
        address to
    ) internal {
        Royalties[] memory royalty = royaltyRegistry.getRoyalties(
            collection,
            nftId
        );
        uint256 mFee = (sellingPrice * items[collection][nftId].marketFee) /
            10000;
        transfer(mFee, payTokenAddr, from, feeRecepient);

        uint256 leftAmount = sellingPrice - mFee;
        for (uint256 i; i < royalty.length; i++) {
            uint256 fee = (sellingPrice * royalty[i].royalty) / 10000;
            if (fee > 0) {
                transfer(fee, payTokenAddr, from, royalty[i].recepient);
                leftAmount -= fee;
            }
        }

        transfer(leftAmount, payTokenAddr, from, to);
        emit FeePayout(royalty, collection, nftId, payTokenAddr);
    }

    function transfer(
        uint256 price,
        address tokenAddr,
        address buyer,
        address seller
    ) internal {
        if (tokenAddr != address(0)) {
            if (buyer == address(this)) {
                IERC20(tokenAddr).transfer(seller, price);
            } else {
                proxyTransferErc20(buyer, seller, price, tokenAddr);
            }
        } else {
            if (buyer != address(this)) {
                if (msg.value < price) revert NotEnoughMoney();
            }
            (bool sent, ) = seller.call{value: price}("");
        }
    }



    function proxyTransferErc20(
        address buyer,
        address seller,
        uint256 amount,
        address tokenAddr
    ) internal {
        bytes4 selector = 0x23b872dd; // transferFrom selector
        IApprovedProxy(proxy).assertCall(
            tokenAddr,
            abi.encodeWithSelector(selector, buyer, seller, amount),
            0
        );
    }

    function transferERC721(
        address buyer,
        address seller,
        uint256 nftId,
        address tokenAddr
    ) internal {
        bytes4 selector = 0x23b872dd; // transferFrom selector
        IApprovedProxy(proxy).assertCall(
            tokenAddr,
            abi.encodeWithSelector(selector, buyer, seller, nftId),
            uint8(0)
        );
    }

    function listItem(
        uint256 _nftId,
        address _collection,
        Price calldata _price,
        State _state,
        AuctionInfo memory _auctionInfo
    ) private onlyApprovedTokens(_price.tokenAddr) onlyTokenOwner(_collection,_nftId) isLocked {
        if (items[_collection][_nftId].itemState == State.ONSELL && msg.sender == items[_collection][_nftId].seller) {
            revert TokenAlreadyOnSale();
        }

        items[_collection][_nftId].price = _price;
        items[_collection][_nftId].seller = msg.sender;
        items[_collection][_nftId].itemState = _state;
        items[_collection][_nftId].marketFee = marketplaceFee;
        if (_state == State.ONAUCTION) {
            transferERC721(msg.sender, address(this), _nftId, _collection);
            items[_collection][_nftId].auctionInfo = _auctionInfo;
            emit AuctionStarted(
                msg.sender,
                _price.price,
                _collection,
                _nftId,
                _auctionInfo.auctionEndTime,
                _price.tokenAddr,
                _auctionInfo.minStep,
                _auctionInfo.auctionStartTime
            );
        } else if (_state == State.ONSELL) {
            emit ItemListed(
                msg.sender,
                _price.price,
                _collection,
                _nftId,
                _price.tokenAddr
            );
        }
    }

}