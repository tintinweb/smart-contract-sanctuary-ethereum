// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../libraries/Helper.sol";
import { IPTMarket } from "../interfaces/IPTMarket.sol";
import { IPTCollection } from "../interfaces/IPTCollection.sol";

contract PTMarket is IPTMarket, Ownable {
    uint256 private constant EXPIRY_ALLOW_PERIOD = 40;
    uint256 private constant DENOMINATOR = 1000;
    uint256 public feePercent; // 25 means 2.5%

    mapping(address => bool) public currencyList;
    mapping(address => mapping(uint256 => NFTVoucher)) private vouchers;
    mapping(address => mapping(uint256 => MarketItem)) public marketItems;
    mapping(address => mapping(uint256 => Offer)) public offers;
    mapping(address => mapping(uint256 => bool)) private nonReentrantLocks;

    modifier whitelisted(address currency) {
        require(currencyList[currency], "Unsupported token");
        _;
    }

    modifier nonReentrant(address collection, uint256 tokenId) {
        if (nonReentrantLocks[collection][tokenId]) {
            revert PTMarket__ReentrancyError(collection, tokenId);
        }
        nonReentrantLocks[collection][tokenId] = true;
        _;
        nonReentrantLocks[collection][tokenId] = false;
    }

    constructor() {
        whitelistCurrency(address(0), true);
        setFeePercent(25);
    }

    /// @notice this function is used whitelist/unwhitlist market supporting ERC20 tokens
    /// @param collection address of Collection
    function whitelistCollection(address collection) external override onlyOwner {
        emit CollectionWhitelisted(collection);
    }

    /// @notice this function is used whitelist/unwhitlist market supporting ERC20 tokens
    /// @param currency address of ERC20 token
    /// @param addOrRemove true => whitelist, false => unwhitelist
    function whitelistCurrency(address currency, bool addOrRemove) public override onlyOwner {
        currencyList[currency] = addOrRemove;
        emit CurrencyWhitelisted(currency, addOrRemove);
    }

    /// @notice create an item
    /// @param collection nft collection address
    /// @param tokenId nft tokenId
    /// @param currency desired currency to sell nft
    /// @param minPrice minimum price
    /// @param expiresAt number of days in expiry period, can be zero if isFixedPrice
    /// @param isFixedPrice false if and only if auction mode
    function listItem(
        address collection,
        uint256 tokenId,
        address currency,
        uint256 minPrice,
        uint256 expiresAt,
        bool isFixedPrice
    ) external override whitelisted(currency) nonReentrant(collection, tokenId) {
        require(minPrice > 0, "Listed price should be greater then zero");
        require(isFixedPrice || expiresAt > 0, "expiresAt should not be zero in auction mode");
        require(IERC721(collection).ownerOf(tokenId) == msg.sender, "Only owner of NFT will list into market");
        require(IERC721(collection).getApproved(tokenId) == address(this), "It should be allowed to markeplace");
        uint256 expiry = expiresAt == 0 ? 0 : block.timestamp + (expiresAt * 1 days);
        require(marketItems[collection][tokenId].seller == address(0), "Already listed");
        marketItems[collection][tokenId] = MarketItem(msg.sender, currency, minPrice, expiry, isFixedPrice);
        emit ItemListed(collection, tokenId, msg.sender, currency, minPrice, expiry, isFixedPrice);
    }

    /// @notice buy a fixed price of Item
    /// @param collection nft collection address
    /// @param tokenId nft tokenId
    function buyItem(address collection, uint256 tokenId) external payable override nonReentrant(collection, tokenId) {
        MarketItem storage marketItem = marketItems[collection][tokenId];
        require(marketItem.minPrice > 0, "Such market item doesn't exist");

        if (marketItem.expiry != 0 && marketItem.expiry < (block.timestamp + EXPIRY_ALLOW_PERIOD)) {
            revert PTMarket__MarketItemExpired(marketItem.expiry);
        }
        require(marketItem.isFixedPrice, "The item is not fixed price mode");
        _checkNFTApproved(collection, tokenId, false);

        _lockMoney(marketItem.currency, marketItem.minPrice, msg.sender);
        _executeTrade(
            collection,
            tokenId,
            marketItem.seller,
            msg.sender,
            marketItem.currency,
            marketItem.minPrice,
            false
        );

        emit ItemBought(collection, tokenId, msg.sender, false);
    }

    /// @notice buy a fixed price of Item
    /// @param collection nft collection address
    /// @param voucher voucher of LazzNFT
    function buyLazzNFT(address collection, NFTVoucher calldata voucher)
        external
        payable
        override
        nonReentrant(collection, voucher.tokenId)
    {
        require(voucher.isFixedPrice, "This voucher is not in fixed price mode");

        uint256 tokenId = voucher.tokenId;
        _checkNFTApproved(collection, tokenId, true);
        address seller = IPTCollection(collection).verifySignature(voucher);

        _lockMoney(voucher.currency, voucher.minPrice, msg.sender);

        vouchers[collection][tokenId] = voucher;
        emit VoucherWritten(collection, voucher.tokenId, voucher.uri, voucher.currency, voucher.signature);

        _executeTrade(collection, voucher.tokenId, seller, msg.sender, voucher.currency, voucher.minPrice, true);

        emit ItemBought(collection, voucher.tokenId, msg.sender, true);
    }

    /// @notice create a new offer for existing item
    /// @param collection nft collection address
    /// @param tokenId nft tokenId
    /// @param offerPrice offerring price to buy
    function createOffer(
        address collection,
        uint256 tokenId,
        uint256 offerPrice
    ) external payable override nonReentrant(collection, tokenId) {
        MarketItem storage marketItem = marketItems[collection][tokenId];
        require(marketItem.minPrice > 0, "Such market item doesn't exist");

        if (marketItem.expiry != 0 && marketItem.expiry < (block.timestamp + EXPIRY_ALLOW_PERIOD)) {
            revert PTMarket__MarketItemExpired(marketItem.expiry);
        }
        require(!marketItem.isFixedPrice, "The item is fixed price mode");
        _checkNFTApproved(collection, tokenId, false);

        uint256 lastPrice = marketItem.minPrice - 1;
        Offer storage lastOffer = offers[collection][tokenId];
        if (lastOffer.buyer != address(0)) {
            lastPrice = lastOffer.offerPrice;
        }
        if (lastPrice >= offerPrice) {
            revert PTMarket__LowerPriceThanPrevious(lastPrice);
        }
        address lastBuyer = lastOffer.buyer;
        _lockMoney(marketItem.currency, offerPrice, msg.sender);
        offers[collection][tokenId] = Offer(msg.sender, offerPrice, false);
        if (lastBuyer != address(0)) {
            _unlockMoney(marketItem.currency, lastPrice, lastBuyer);
            emit OfferDeactivated(collection, tokenId, lastBuyer, lastPrice);
        }
        emit OfferCreated(collection, tokenId, msg.sender, offerPrice, false);
    }

    /// @notice create a new offer for lazz NFT
    /// @param collection nft collection address
    /// @param voucher voucher of LazzNFT
    /// @param offerPrice offerring price to buy
    function createLazzOffer(
        address collection,
        NFTVoucher calldata voucher,
        uint256 offerPrice
    ) external payable override whitelisted(voucher.currency) nonReentrant(collection, voucher.tokenId) {
        require(!voucher.isFixedPrice, "This voucher is in fixed price mode");
        uint256 tokenId = voucher.tokenId;
        _checkNFTApproved(collection, tokenId, true);

        uint256 lastPrice = voucher.minPrice - 1;
        Offer storage lastOffer = offers[collection][tokenId];
        if (lastOffer.buyer != address(0)) {
            lastPrice = lastOffer.offerPrice;
        }
        if (lastPrice >= offerPrice) {
            revert PTMarket__LowerPriceThanPrevious(lastPrice);
        }
        address lastBuyer = lastOffer.buyer;
        _lockMoney(voucher.currency, offerPrice, msg.sender);
        offers[collection][tokenId] = Offer(msg.sender, offerPrice, true);
        if (lastBuyer == address(0)) {
            vouchers[collection][tokenId] = voucher;
            emit VoucherWritten(collection, voucher.tokenId, voucher.uri, voucher.currency, voucher.signature);
        }
        if (lastBuyer != address(0)) {
            _unlockMoney(voucher.currency, lastPrice, lastBuyer);
            emit OfferDeactivated(collection, tokenId, lastBuyer, lastPrice);
        }
        emit OfferCreated(collection, tokenId, msg.sender, offerPrice, true);
    }

    /// @notice accept/reject existing offer
    /// @param collection nft collection address
    /// @param tokenId nft tokenId
    /// @param acceptOrReject true => accept, false => reject
    function acceptOffer(
        address collection,
        uint256 tokenId,
        bool acceptOrReject
    ) external override nonReentrant(collection, tokenId) {
        Offer storage offer = offers[collection][tokenId];
        bool isVoucher = offer.isVoucher;
        require(offer.buyer != address(0), "Such offer doesn't exist");
        address buyer = offer.buyer;
        uint256 offerPrice = offer.offerPrice;
        address currency;
        address seller;
        if (isVoucher) {
            NFTVoucher storage voucher = vouchers[collection][tokenId];
            currency = voucher.currency;
            seller = IPTCollection(collection).verifySignature(voucher);
        } else {
            MarketItem storage marketItem = marketItems[collection][tokenId];
            currency = marketItem.currency;
            seller = marketItem.seller;
        }

        if (seller != msg.sender) {
            revert PTMarket__NotSeller(seller);
        }
        _checkNFTApproved(collection, tokenId, isVoucher);
        delete offers[collection][tokenId];
        if (acceptOrReject) {
            _executeTrade(collection, tokenId, seller, buyer, currency, offerPrice, isVoucher);
            emit OfferAccepted(collection, tokenId, buyer);
        } else {
            _unlockMoney(currency, offerPrice, buyer);
            emit OfferDeactivated(collection, tokenId, buyer, offerPrice);
            emit OfferRejected(collection, tokenId, buyer);
        }
    }

    /// @notice remove existing item
    /// @param collection nft collection address
    /// @param tokenId nft tokenId
    function unlistItem(address collection, uint256 tokenId) external override nonReentrant(collection, tokenId) {
        MarketItem storage marketItem = marketItems[collection][tokenId];
        if (marketItem.seller != msg.sender) {
            revert PTMarket__NotSeller(marketItem.seller);
        }
        address currency = marketItem.currency;
        delete marketItems[collection][tokenId];
        if (offers[collection][tokenId].buyer != address(0)) {
            _cancelOffer(collection, tokenId, currency);
        }
        emit ItemUnlisted(collection, tokenId);
    }

    /// @notice remove existing offer
    /// @param collection nft collection address
    /// @param tokenId nft tokenId
    function withdrawOffer(address collection, uint256 tokenId) external override nonReentrant(collection, tokenId) {
        Offer storage offer = offers[collection][tokenId];
        if (offer.buyer != msg.sender) {
            revert PTMarket__NotOfferer(offer.buyer);
        }
        _cancelOffer(collection, tokenId, marketItems[collection][tokenId].currency);
        emit OfferWithdrawn(collection, tokenId);
    }

    /// @notice update feePercent
    /// @param newFeePercent fee percent
    function setFeePercent(uint256 newFeePercent) public override onlyOwner {
        feePercent = newFeePercent;
        emit FeePercentUpadated(newFeePercent);
    }

    function _cancelOffer(
        address collection,
        uint256 tokenId,
        address currency
    ) private {
        Offer storage offer = offers[collection][tokenId];
        address buyer = offer.buyer;
        uint256 offerPrice = offer.offerPrice;
        if (offer.isVoucher) {
            delete vouchers[collection][tokenId];
        }
        delete offers[collection][tokenId];
        _unlockMoney(currency, offerPrice, buyer);
        emit OfferDeactivated(collection, tokenId, buyer, offerPrice);
    }

    function _checkNFTApproved(
        address collection,
        uint256 tokenId,
        bool isVoucher
    ) private view {
        if (isVoucher) {
            require(!IPTCollection(collection).exists(tokenId), "The Voucher is already minted");
        } else {
            require(
                IERC721(collection).getApproved(tokenId) == address(this),
                "Collection is not approved to the market"
            );
        }
    }

    function _lockMoney(
        address currency,
        uint256 amount,
        address user
    ) private {
        if (currency == address(0)) {
            require(msg.value >= amount, "Insufficient eth value");
        } else {
            IERC20(currency).transferFrom(user, address(this), amount);
        }
    }

    function _unlockMoney(
        address currency,
        uint256 amount,
        address user
    ) private {
        if (currency == address(0)) {
            payable(user).transfer(amount);
        } else {
            IERC20(currency).transfer(user, amount);
        }
    }

    function _executeTrade(
        address collection,
        uint256 tokenId,
        address seller,
        address buyer,
        address currency,
        uint256 price,
        bool isVoucher
    ) private {
        uint256 fee = (price * feePercent) / DENOMINATOR;
        if (currency == address(0)) {
            payable(seller).transfer(price - fee);
            payable(owner()).transfer(fee);
        } else {
            IERC20(currency).transfer(seller, price - fee);
            IERC20(currency).transfer(owner(), fee);
        }

        if (isVoucher) {
            NFTVoucher memory voucher = vouchers[collection][tokenId];
            delete vouchers[collection][tokenId];
            IPTCollection(collection).redeem(buyer, voucher);
        } else {
            IERC721(collection).safeTransferFrom(seller, buyer, tokenId);
        }
        emit TradeExecuted(collection, tokenId, seller, buyer, currency, price, isVoucher);

        delete offers[collection][tokenId];
        delete marketItems[collection][tokenId];
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

struct NFTVoucher {
    /// @notice The id of the token to be redeemed. Must be unique - if another token with this ID already exists, the redeem function will revert.
    uint256 tokenId;
    /// @notice The metadata URI to associate with this token.
    string uri;
    /// @notice The token address on which user want to sale the NFT.
    address currency;
    /// @notice Minimum price of the nft.
    uint256 minPrice;
    /// @notice True if and only if fixed price mode.
    bool isFixedPrice;
    /// @notice the EIP-712 signature of all other fields in the NFTVoucher struct. For a voucher to be valid, it must be signed by an account with the MINTER_ROLE.
    bytes signature;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "../libraries/Helper.sol";

interface IPTCollection {
    error PTCollection__OnlyMarketPlace();

    function redeem(address redeemer, NFTVoucher calldata voucher) external;

    function verifySignature(NFTVoucher calldata voucher) external view returns (address);

    function exists(uint256 tokenId) external view returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "../libraries/Helper.sol";

interface IPTMarket {
    function whitelistCollection(address collection) external;

    function whitelistCurrency(address currency, bool addOrRemove) external;

    function listItem(
        address collection,
        uint256 tokenId,
        address currency,
        uint256 minPrice,
        uint256 expiresAt,
        bool isFixedPrice
    ) external;

    function buyItem(address collection, uint256 tokenId) external payable;

    function buyLazzNFT(address collection, NFTVoucher calldata voucher) external payable;

    function createOffer(
        address collection,
        uint256 tokenId,
        uint256 offerPrice
    ) external payable;

    function createLazzOffer(
        address collection,
        NFTVoucher calldata voucher,
        uint256 offerPrice
    ) external payable;

    function acceptOffer(
        address collection,
        uint256 tokenId,
        bool acceptOrReject
    ) external;

    function unlistItem(address collection, uint256 tokenId) external;

    function withdrawOffer(address collection, uint256 tokenId) external;

    function setFeePercent(uint256 newFeePercent) external;

    // structs
    struct MarketItem {
        address seller;
        address currency;
        uint256 minPrice;
        uint256 expiry;
        bool isFixedPrice;
    }
    struct Offer {
        address buyer;
        uint256 offerPrice;
        bool isVoucher;
    }

    // events
    event ItemListed(
        address indexed collection,
        uint256 indexed tokenId,
        address indexed seller,
        address currency,
        uint256 minPrice,
        uint256 expiry,
        bool isFixedPrice
    );
    event TradeExecuted(
        address indexed collection,
        uint256 indexed tokenId,
        address seller,
        address buyer,
        address currency,
        uint256 price,
        bool isVoucher
    );

    event VoucherWritten(
        address indexed collection,
        uint256 indexed tokenId,
        string uri,
        address currency,
        bytes signature
    );
    event CollectionWhitelisted(address indexed collection);
    event CurrencyWhitelisted(address indexed currency, bool addOrRemove);
    event ItemBought(address indexed collection, uint256 indexed tokenId, address buyer, bool isVoucher);
    event OfferCreated(
        address indexed collection,
        uint256 indexed tokenId,
        address buyer,
        uint256 offerPrice,
        bool isVoucher
    );
    event OfferAccepted(address indexed collection, uint256 indexed tokenId, address buyer);
    event OfferRejected(address indexed collection, uint256 indexed tokenId, address buyer);
    event ItemUnlisted(address indexed collection, uint256 indexed tokenId);
    event OfferWithdrawn(address indexed collection, uint256 indexed tokenId);
    event OfferDeactivated(address indexed collection, uint256 indexed tokenId, address buyer, uint256 offerPrice);
    event FeePercentUpadated(uint256 newFeePercent);

    // errors
    error PTMarket__ReentrancyError(address collection, uint256 tokenId);
    error PTMarket__NotSeller(address seller);
    error PTMarket__NotOfferer(address buyer);
    error PTMarket__MarketItemExpired(uint256 expiry);
    error PTMarket__LowerPriceThanPrevious(uint256 lastOfferPrice);
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