// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract NFTMarketPublic is ReentrancyGuard, AccessControl, ERC721Holder {
    using Counters for Counters.Counter;
    using SafeERC20 for IERC20;

    error HighFee(uint96 fee, uint96 maxFee);
    error LowPrice(uint256 price, uint256 minPrice);
    error WrongTradeState(TradeState state, TradeState requiredState);
    error WrongAuctionState(AuctionState state, AuctionState requiredState);
    error AuctionIsNotAllowed();
    error IncorrectFunds(uint256 sent, uint256 required);
    error InsufficientFunds(uint256 sent, uint256 required);
    error EarlyToExecute(uint256 executeTime);
    error LateToExecute(uint256 executeTime);
    error CallerIsNotAllowed();
    error NftContractIsNotAllowed();

    // fees are expressed in basis points
    uint96 public constant MAX_FEE = 5000; // means 50
    uint96 private constant _FEE_DENOMINATOR = 10000; // means 100

    enum TradeState {
        INVALID,
        ON_SALE,
        SOLD,
        CANCELED
    }

    enum AuctionState {
        INVALID,
        ON_AUCTION,
        SOLD,
        CANCELED,
        FAILED
    }

    struct TradeItem {
        address nftContract;
        address tokenContract;
        address seller;
        TradeState state;
        uint256 tradeId;
        uint256 tokenId;
        uint256 price;
    }

    struct AuctionParameters {
        uint256 bidStartPrice;
        uint256 minBidderCount;
    }

    struct AuctionItem {
        address nftContract;
        address tokenContract;
        address seller;
        address highestBidder;
        AuctionState state;
        uint256 deadline;
        uint256 auctionId;
        uint256 tokenId;
        uint256 bidCount;
        uint256 highestBid;
        AuctionParameters parameters;
    }

    bool public isAuctionAllowed;
    uint256 public minBidderCount = 2;
    uint256 public auctionLength = 3 days;

    Counters.Counter private _tradeId;
    Counters.Counter private _auctionId;

    mapping(uint256 => TradeItem) private _tradeItems;
    mapping(uint256 => AuctionItem) private _auctionItems;

    mapping(address => bool) private _nftContractWhitelist;

    uint96 public fee;

    event TradeStateChanged(uint256 indexed itemId, address indexed caller, TradeState state);

    event AuctionStateChanged(uint256 indexed itemId, address indexed caller, AuctionState state);

    event NFTContractWhitelistChanged(address indexed nftContract, bool allowed);

    event AuctionBidMade(uint256 indexed itemId, address indexed bidderAddress, uint256 bidAmount);

    constructor(uint96 defaultFee, bool defaultAuctionAllowed) {
        fee = defaultFee;
        isAuctionAllowed = defaultAuctionAllowed;

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function setFee(uint96 _fee) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_fee > MAX_FEE) revert HighFee({ fee: _fee, maxFee: MAX_FEE });
        fee = _fee;
    }

    function setAuctionAllowed(bool allowed) external onlyRole(DEFAULT_ADMIN_ROLE) {
        isAuctionAllowed = allowed;
    }

    function setMinBidderCount(uint256 bidderCount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        minBidderCount = bidderCount;
    }

    function setAuctionLength(uint256 length) external onlyRole(DEFAULT_ADMIN_ROLE) {
        auctionLength = length;
    }

    function setNftContractAllowed(address nftContract, bool allowed) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_nftContractWhitelist[nftContract] != allowed) {
            _nftContractWhitelist[nftContract] = allowed;

            emit NFTContractWhitelistChanged(nftContract, allowed);
        }
    }

    /* Places an item for sale on the marketplace */
    function listTradeItem(
        address nftContract,
        address tokenContract,
        uint256 tokenId,
        uint256 price
    ) external nonReentrant {
        if (!_nftContractWhitelist[nftContract]) revert NftContractIsNotAllowed();
        if (price < _FEE_DENOMINATOR) revert LowPrice({ price: price, minPrice: _FEE_DENOMINATOR });

        uint256 itemId = _tradeId.current();
        _tradeId.increment();

        TradeItem storage tradeItem = _tradeItems[itemId];
        tradeItem.nftContract = nftContract;
        tradeItem.tokenContract = tokenContract;
        tradeItem.seller = msg.sender;
        tradeItem.tradeId = itemId;
        tradeItem.tokenId = tokenId;
        tradeItem.price = price;

        IERC721(nftContract).safeTransferFrom(msg.sender, address(this), tokenId);

        _updateTradeState(itemId, msg.sender, TradeState.ON_SALE);
    }

    function listAuctionItem(
        address nftContract,
        address tokenContract,
        uint256 tokenId,
        uint256 bidStartPrice
    ) external nonReentrant {
        if (!isAuctionAllowed) revert AuctionIsNotAllowed();
        if (!_nftContractWhitelist[nftContract]) revert NftContractIsNotAllowed();
        if (bidStartPrice < _FEE_DENOMINATOR) revert LowPrice({ price: bidStartPrice, minPrice: _FEE_DENOMINATOR });

        uint256 itemId = _auctionId.current();
        _auctionId.increment();

        AuctionItem storage auctionItem = _auctionItems[itemId];
        auctionItem.nftContract = nftContract;
        auctionItem.tokenContract = tokenContract;
        auctionItem.deadline = block.timestamp + auctionLength;
        auctionItem.seller = msg.sender;
        auctionItem.auctionId = itemId;
        auctionItem.tokenId = tokenId;

        auctionItem.parameters.bidStartPrice = bidStartPrice;
        auctionItem.parameters.minBidderCount = minBidderCount;

        IERC721(nftContract).safeTransferFrom(msg.sender, address(this), tokenId);

        _updateAuctionState(itemId, msg.sender, AuctionState.ON_AUCTION);
    }

    function withdrawFeesNative() external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 amount = address(this).balance;

        payable(msg.sender).transfer(amount);
    }

    function withdrawFeesToken(address _tokenContract, uint256 amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        IERC20 tokenContract = IERC20(_tokenContract);

        tokenContract.safeTransfer(msg.sender, amount);
    }

    /* Creates the sale of a marketplace item */
    /* Transfers ownership of the item, as well as funds between parties */
    function buyTradeItem(uint256 tradeId) external payable nonReentrant {
        TradeItem memory tradeItem = _tradeItems[tradeId];
        if (tradeItem.state != TradeState.ON_SALE)
            revert WrongTradeState({ state: tradeItem.state, requiredState: TradeState.ON_SALE });

        bool isNative = tradeItem.tokenContract == address(0);

        if (isNative && msg.value != tradeItem.price)
            revert IncorrectFunds({ sent: msg.value, required: tradeItem.price });

        uint256 feeTransfer = _getFee(tradeItem.price);
        uint256 sellerTransfer = tradeItem.price - feeTransfer;

        if (isNative) payable(tradeItem.seller).transfer(sellerTransfer);
        else _transferFundsToken(tradeItem.tokenContract, tradeItem.seller, tradeItem.price);

        IERC721(tradeItem.nftContract).safeTransferFrom(address(this), msg.sender, tradeItem.tokenId);

        _updateTradeState(tradeItem.tradeId, msg.sender, TradeState.SOLD);
    }

    function bidAuctionItem(uint256 auctionId, uint256 bid) external payable nonReentrant {
        AuctionItem storage auctionItem = _auctionItems[auctionId];
        if (auctionItem.state != AuctionState.ON_AUCTION)
            revert WrongAuctionState({ state: auctionItem.state, requiredState: AuctionState.ON_AUCTION });
        if (auctionItem.deadline < block.timestamp) {
            revert LateToExecute({ executeTime: auctionItem.deadline });
        }
        if (bid < auctionItem.parameters.bidStartPrice)
            revert InsufficientFunds({ sent: bid, required: auctionItem.parameters.bidStartPrice });
        if (bid <= auctionItem.highestBid)
            revert InsufficientFunds({ sent: bid, required: auctionItem.highestBid + 1 });

        bool isNative = auctionItem.tokenContract == address(0);

        if (isNative && msg.value != bid) revert IncorrectFunds({ sent: msg.value, required: bid });

        if (!isNative) _checkBalanceAndTransfer(auctionItem.tokenContract, msg.sender, address(this), bid);

        // returns previous highest bidder it's funds
        if (auctionItem.highestBidder != address(0))
            if (isNative) {
                payable(auctionItem.highestBidder).transfer(auctionItem.highestBid);
            } else {
                IERC20(auctionItem.tokenContract).safeTransfer(auctionItem.highestBidder, auctionItem.highestBid);
            }

        auctionItem.highestBidder = msg.sender;
        auctionItem.highestBid = bid;
        auctionItem.bidCount++;

        emit AuctionBidMade(auctionId, msg.sender, bid);
    }

    function finishAuction(uint256 auctionId) external nonReentrant {
        AuctionItem memory auctionItem = _auctionItems[auctionId];
        if (auctionItem.state != AuctionState.ON_AUCTION)
            revert WrongAuctionState({ state: auctionItem.state, requiredState: AuctionState.ON_AUCTION });
        if (auctionItem.deadline > block.timestamp) revert EarlyToExecute({ executeTime: auctionItem.deadline });

        bool isNative = auctionItem.tokenContract == address(0);

        AuctionState state;

        // Auction is failed
        if (auctionItem.bidCount < auctionItem.parameters.minBidderCount) {
            // send funds back to highest bidder
            if (auctionItem.highestBidder != address(0)) {
                if (isNative) payable(auctionItem.highestBidder).transfer(auctionItem.highestBid);
                else IERC20(auctionItem.tokenContract).safeTransfer(auctionItem.highestBidder, auctionItem.highestBid);
            }

            // send nft back to seller
            IERC721(auctionItem.nftContract).safeTransferFrom(address(this), auctionItem.seller, auctionItem.tokenId);

            state = AuctionState.FAILED;
        } else {
            uint256 feeTransfer = _getFee(auctionItem.highestBid);
            uint256 sellerTransfer = auctionItem.highestBid - feeTransfer;

            // send funds to seller (fees are deducted)
            if (isNative) payable(auctionItem.seller).transfer(sellerTransfer);
            else IERC20(auctionItem.tokenContract).safeTransfer(auctionItem.seller, sellerTransfer);

            // send highest bidder its nft
            IERC721(auctionItem.nftContract).safeTransferFrom(
                address(this),
                auctionItem.highestBidder,
                auctionItem.tokenId
            );

            state = AuctionState.SOLD;
        }

        _updateAuctionState(auctionId, msg.sender, state);
    }

    /* cancels sale  and transfers the token back to original seller*/
    function cancelTrade(uint256 tradeId) external nonReentrant {
        TradeItem memory tradeItem = _tradeItems[tradeId];

        if (tradeItem.seller != msg.sender) revert CallerIsNotAllowed();
        if (tradeItem.state != TradeState.ON_SALE)
            revert WrongTradeState({ state: tradeItem.state, requiredState: TradeState.ON_SALE });

        IERC721(tradeItem.nftContract).safeTransferFrom(address(this), tradeItem.seller, tradeItem.tokenId);

        _updateTradeState(tradeItem.tradeId, msg.sender, TradeState.CANCELED);
    }

    function cancelAuction(uint256 auctionId) external nonReentrant {
        AuctionItem memory auctionItem = _auctionItems[auctionId];

        if (auctionItem.seller != msg.sender) revert CallerIsNotAllowed();
        if (auctionItem.state != AuctionState.ON_AUCTION)
            revert WrongAuctionState({ state: auctionItem.state, requiredState: AuctionState.ON_AUCTION });

        bool isNative = auctionItem.tokenContract == address(0);

        // returns bidder it's funds
        if (auctionItem.highestBidder != address(0))
            if (isNative) {
                payable(auctionItem.highestBidder).transfer(auctionItem.highestBid);
            } else {
                IERC20(auctionItem.tokenContract).safeTransfer(auctionItem.highestBidder, auctionItem.highestBid);
            }

        IERC721(auctionItem.nftContract).safeTransferFrom(address(this), auctionItem.seller, auctionItem.tokenId);

        _updateAuctionState(auctionItem.auctionId, msg.sender, AuctionState.CANCELED);
    }

    function fetchNftContractAllowed(address nftContract) external view returns (bool allowed) {
        allowed = _nftContractWhitelist[nftContract];
    }

    function fetchTradeItem(uint256 tradeId) external view returns (TradeItem memory item) {
        item = _tradeItems[tradeId];
    }

    function fetchTradeItems(address itemOwner, TradeState state) external view returns (TradeItem[] memory items) {
        uint256 totalItemCount = _tradeId.current();
        uint256 currentIndex = 0;

        bool isAddressFiltered = itemOwner != address(0);
        bool isFiltered = state != TradeState.INVALID;

        uint256 itemCount = fetchTradeItemsCount(itemOwner, state);
        items = new TradeItem[](itemCount);

        for (uint256 i = 0; i < totalItemCount; i++) {
            TradeItem memory currentItem = _tradeItems[i];
            if ((isAddressFiltered && currentItem.seller == itemOwner) || !isAddressFiltered) {
                if ((isFiltered && currentItem.state == state) || !isFiltered) {
                    items[currentIndex++] = currentItem;
                }
            }
        }
    }

    function fetchAuctionItem(uint256 auctionId) external view returns (AuctionItem memory item) {
        item = _auctionItems[auctionId];
    }

    function fetchAuctionItems(address itemOwner, AuctionState state)
        external
        view
        returns (AuctionItem[] memory items)
    {
        uint256 totalItemCount = _auctionId.current();
        uint256 currentIndex = 0;

        bool isAddressFiltered = itemOwner != address(0);
        bool isFiltered = state != AuctionState.INVALID;

        uint256 itemCount = fetchAuctionItemsCount(itemOwner, state);
        items = new AuctionItem[](itemCount);

        for (uint256 i = 0; i < totalItemCount; i++) {
            AuctionItem memory currentItem = _auctionItems[i];
            if ((isAddressFiltered && currentItem.seller == itemOwner) || !isAddressFiltered) {
                if ((isFiltered && currentItem.state == state) || !isFiltered) {
                    items[currentIndex++] = currentItem;
                }
            }
        }
    }

    function fetchTradeItemsCount(address itemOwner, TradeState state) public view returns (uint256 itemCount) {
        uint256 totalItemCount = _tradeId.current();

        bool isAddressFiltered = itemOwner != address(0);
        bool isFiltered = state != TradeState.INVALID;

        for (uint256 i = 0; i < totalItemCount; i++) {
            TradeItem memory currentItem = _tradeItems[i];
            if ((isAddressFiltered && currentItem.seller == itemOwner) || !isAddressFiltered) {
                if ((isFiltered && currentItem.state == state) || !isFiltered) {
                    itemCount += 1;
                }
            }
        }
    }

    function fetchAuctionItemsCount(address itemOwner, AuctionState state) public view returns (uint256 itemCount) {
        uint256 totalItemCount = _auctionId.current();

        bool isAddressFiltered = itemOwner != address(0);
        bool isFiltered = state != AuctionState.INVALID;

        for (uint256 i = 0; i < totalItemCount; i++) {
            AuctionItem memory currentItem = _auctionItems[i];
            if ((isAddressFiltered && currentItem.seller == itemOwner) || !isAddressFiltered) {
                if ((isFiltered && currentItem.state == state) || !isFiltered) {
                    itemCount += 1;
                }
            }
        }
    }

    function _transferFundsToken(
        address addressTokenContract,
        address addressSeller,
        uint256 itemPrice
    ) private {
        uint256 feeTransfer = _getFee(itemPrice);
        uint256 sellerTransfer = itemPrice - feeTransfer;

        _checkBalanceAndTransfer(addressTokenContract, msg.sender, address(this), itemPrice);
        IERC20(addressTokenContract).safeTransfer(addressSeller, sellerTransfer);
    }

    function _checkBalanceAndTransfer(
        address addressTokenContract,
        address addressSender,
        address addressReceiver,
        uint256 amount
    ) private {
        IERC20 tokenContract = IERC20(addressTokenContract);
        uint256 callerBalance = tokenContract.balanceOf(addressSender);
        if (callerBalance < amount) revert InsufficientFunds({ sent: callerBalance, required: amount });

        tokenContract.safeTransferFrom(addressSender, addressReceiver, amount);
    }

    function _getFee(uint256 price) private view returns (uint256 calculatedFee) {
        calculatedFee = (price * fee) / _FEE_DENOMINATOR;
    }

    function _updateTradeState(
        uint256 itemId,
        address caller,
        TradeState state
    ) private {
        TradeItem storage item = _tradeItems[itemId];
        item.state = state;

        emit TradeStateChanged(itemId, caller, state);
    }

    function _updateAuctionState(
        uint256 itemId,
        address caller,
        AuctionState state
    ) private {
        AuctionItem storage item = _auctionItems[itemId];
        item.state = state;

        emit AuctionStateChanged(itemId, caller, state);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
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