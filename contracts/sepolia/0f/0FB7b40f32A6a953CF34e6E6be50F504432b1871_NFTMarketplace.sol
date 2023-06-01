// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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
// OpenZeppelin Contracts (last updated v4.9.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(
        uint256 tokenId,
        uint256 salePrice
    ) external view returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

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

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC721/IERC721.sol)

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function setApprovalForAll(address operator, bool approved) external;

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
// Aglive Labs 2023
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/*** INTERFACES ***/

/// @title IERC721_IERC2981
/// @dev Interface for a contract that complies with ERC721 and ERC2981 standards.
interface IERC721_IERC2981 is IERC721, IERC2981 {
    /// @notice This function is used to get the owner of the contract.
    /// @dev No implementation needed since it's an interface.
    /// @return Address of the owner.
    function owner() external returns (address);
}

/// @title IPaymentSplitter
/// @dev Interface for a contract that enables splitting of payments among several accounts.
interface IPaymentSplitter {
    /// @notice This function is used to release the specified account's proportional share of the total amount.
    /// @dev No implementation needed since it's an interface.
    /// @param account The account to release.
    function release(address account) external;
}

/*** ERROR HANDLING ***/

/// @dev Emitted when the set price is not met.
error PriceNotMet(
    address nftAddress,
    uint256 tokenId,
    uint256 price,
    uint256 priceInWei
);

/// @dev Emitted when the NFT is not listed for sale.
error NotListed(address nftAddress, uint256 tokenId);

/// @dev Emitted when the NFT is already listed for sale.
error AlreadyListed(address nftAddress, uint256 tokenId);

/// @dev Emitted when the caller is not the owner of the NFT.
error NotOwner();

/// @dev Emitted when the NFT is not approved for marketplace.
error NotApprovedForMarketplace();

/// @dev Emitted when the set price is zero.
error PriceMustBeAboveZero();

/// @dev Emitted when the account balance is zero.
error BalanceMustBeAboveZero();

/// @dev Emitted when the contract is not a redemption contract.
error NotRedemptionContract();

/// @dev Emitted when the NFT is not transferred successfully.
error NotTransferred();

/// @dev Emitted when the caller is not an investor.
error NotInvestor();

/// @dev Emitted when the NFT is already redeemed.
error AlreadyRedeem();

/// @dev Emitted when the address provided is the zero address.
error ZeroAddress();

/// @dev Emitted when the owner of the NFT is changed without updating the record.
error OwnerChangedWithoutUpdate();

/// @title NFTMarketplace
/// @notice This is the contract for the NFT marketplace.
/// @dev The contract inherits from Ownable and ReentrancyGuard for access control and re-entrancy protection respectively.
contract NFTMarketplace is Ownable, ReentrancyGuard {
    /*** DATA TYPES ***/

    /// @dev The price feed interface for getting the latest price.
    AggregatorV3Interface private priceFeed;

    /// @dev The listing fee in basis points.
    uint256 private listingFeeBPS;

    /// @dev The address of the redemption contract.
    address private redemptionContractAddress;

    /// @notice Enum for the state of a listing.
    enum State {
        NOTLISTED, /// @notice The item is not listed.
        LISTED, /// @notice The item is listed for sale.
        CANCELLED, /// @notice The listing has been cancelled.
        TRANSFERRED, /// @notice The item has been transferred.
        REDEEMED /// @notice The profit from the sale of the item has been redeemed.
    }

    /// @notice Struct for a listing.
    struct Listing {
        address creator; /// @notice The creator of the item.
        address owner; /// @notice The current owner of the item.
        uint256 price; /// @notice The price of the item.
        State state; /// @notice The current state of the item.
    }

    /// @notice Mapping of NFT addresses to token IDs to listings.
    mapping(address => mapping(uint256 => Listing)) private listings;

    /*** CONSTRUCTOR ***/

    /// @notice Contract constructor which sets the listing fee to 2%
    constructor() {
        listingFeeBPS = 200; // 2%
    }

    /*** EVENTS ***/

    /// @notice Event emitted when an item is listed for sale
    event ItemListed(
        address indexed owner,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 price
    );

    /// @notice Event emitted when an item listing is cancelled
    event ItemCanceled(
        address indexed owner,
        address indexed nftAddress,
        uint256 indexed tokenId
    );

    /// @notice Event emitted when an item is bought
    event ItemBought(
        address indexed owner,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 price,
        uint256 priceInWei
    );

    /// @notice Event emitted when the redeem contract address is updated
    event UpdateRedeemContractAddress(address redeemContractAddress);

    /// @notice Event emitted when the listing fee is updated
    event UpdateListingFee(uint256 listingFeeBPS);

    /// @notice Event emitted when the price feed address is updated
    event UpdatePriceFeedAddress(address chainLink);

    /// @notice Event emitted when the lock status is updated
    event LockStatus(uint256 status);

    /*** MODIFIER ***/

    /// @notice Modifier to check if the NFT is listed
    modifier isListed(address nftAddress, uint256 tokenId) {
        if (listings[nftAddress][tokenId].state != State.LISTED) {
            revert NotListed(nftAddress, tokenId);
        }
        _;
    }

    /// @notice Modifier to check if the caller is the owner of the token
    modifier isTokenOwner(address nftAddress, uint256 tokenId) {
        IERC721_IERC2981 nft = IERC721_IERC2981(nftAddress);
        address owner = nft.ownerOf(tokenId);
        if (msg.sender != owner) {
            revert NotOwner();
        }
        _;
    }

    /// @notice Modifier to check if the token is approved for the marketplace
    modifier isApproved(address nftAddress, uint256 tokenId) {
        IERC721_IERC2981 nft = IERC721_IERC2981(nftAddress);
        if (
            nft.getApproved(tokenId) != address(this) &&
            !nft.isApprovedForAll(msg.sender, address(this))
        ) {
            revert NotApprovedForMarketplace();
        }
        _;
    }

    /*** EXTERNAL & VIEW FUNCTIONS ***/

    /// @notice Get the current version of the contract
    /// @return The version of the contract
    function getVersion() external pure returns (int256) {
        return 1;
    }

    /// @notice Get the address of the price feed contract
    /// @return The address of the price feed contract
    function getPriceFeedAddress() external view returns (address) {
        return address(priceFeed);
    }

    /// @notice Get the basis points used for the listing fee
    /// @return The listing fee in basis points
    function getListingFeeBPS() external view returns (uint256) {
        return listingFeeBPS;
    }

    /// @notice Get the address of the redemption contract
    /// @return The address of the redemption contract
    function getRedemptionContractAddress() external view returns (address) {
        return redemptionContractAddress;
    }

    /// @notice Get the listing for a particular NFT
    /// @param nftAddress The address of the NFT contract
    /// @param tokenId The ID of the token
    /// @return The listing of the token
    function getListing(
        address nftAddress,
        uint256 tokenId
    ) external view returns (Listing memory) {
        return listings[nftAddress][tokenId];
    }

    /// @notice Retrieves the latest price from the price feed
    /// @return The latest price as an int256 value
    function getLatestPrice() public view returns (int256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return price;
    }

    /// @notice Retrieves the number of decimal places for the price feed
    /// @return The number of decimal places as a uint8 value
    function getDecimals() public view returns (uint8) {
        return priceFeed.decimals();
    }

    /// @notice Calculates the required price in Wei based on a given USD price
    /// @param requiredPriceInUSD The required price in USD
    /// @return The required price in Wei as a uint256 value
    function getRequiredPriceInWei(
        uint256 requiredPriceInUSD
    ) public view returns (uint256) {
        int256 eth_usd = getLatestPrice();
        uint256 eth_usd_price = uint256(eth_usd) * 1e10;
        return (requiredPriceInUSD * 1e34) / eth_usd_price;
    }

    /*** INTERNAL FUNCTIONS ***/

    /// @notice Calculates various balances and amounts related to a transaction
    /// @dev This function reverts if the payment does not meet the price or if the balance is zero or below
    /// @param nftAddress The address of the NFT contract
    /// @param tokenId The ID of the token
    /// @param price The price of the token
    /// @param payment The payment amount
    /// @return A tuple containing the calculated values: (priceInWei, paymentSplitterAddress, royaltyAmount, balance, paymentToMarketplace)
    function balanceCalculation(
        address nftAddress,
        uint256 tokenId,
        uint256 price,
        uint256 payment
    ) internal view returns (uint256, address, uint256, uint256, uint256) {
        // get latest price from chainlink
        uint256 priceInWei = getRequiredPriceInWei(price);

        if (!(payment == priceInWei)) {
            revert PriceNotMet(nftAddress, tokenId, price, priceInWei);
        }

        // Amount to Marketplace
        uint256 paymentToMarketplace = (priceInWei * listingFeeBPS) / 10_000;

        // Amount to Royalty
        (
            address paymentSplitterAddress,
            uint256 royaltyAmount
        ) = IERC721_IERC2981(nftAddress).royaltyInfo(tokenId, priceInWei);

        // Amount to Collection Owner
        uint256 balance = priceInWei - paymentToMarketplace - royaltyAmount;
        if (balance <= 0) {
            revert BalanceMustBeAboveZero();
        }

        return (
            priceInWei,
            paymentSplitterAddress,
            royaltyAmount,
            balance,
            paymentToMarketplace
        );
    }

    /*** EXTERNAL FUNCTIONS (WRITE) ***/

    /// @notice Updates the listing fee
    /// @param newFeesBPS The new listing fee in basis points (e.g., for 2% listing fees, input 200)
    function updateListingFee(uint256 newFeesBPS) external onlyOwner {
        listingFeeBPS = newFeesBPS;
        emit UpdateListingFee(newFeesBPS);
    }

    /// @notice Updates the price feed address
    /// @param chainlink The address of the Chainlink price feed
    function updatePriceFeedAddress(address chainlink) external onlyOwner {
        if (chainlink == address(0)) {
            revert ZeroAddress();
        }
        priceFeed = AggregatorV3Interface(chainlink);
        emit UpdatePriceFeedAddress(chainlink);
    }

    /// @notice Updates the address of the redemption contract
    /// @param _redemptionContractAddress The address of the new redemption contract
    function updateRedeemContractAddress(
        address _redemptionContractAddress
    ) external onlyOwner {
        if (_redemptionContractAddress == address(0)) {
            revert ZeroAddress();
        }
        redemptionContractAddress = _redemptionContractAddress;
        emit UpdateRedeemContractAddress(_redemptionContractAddress);
    }

    /// @notice List an NFT item for sale
    /// @dev This function reverts if the token is already listed or redeemed, or if the price is zero or below
    /// @param nftAddress The address of the NFT contract
    /// @param tokenId The ID of the NFT to list
    /// @param price The price at which the NFT will be listed
    function listItem(
        address nftAddress,
        uint256 tokenId,
        uint256 price
    )
        external
        isTokenOwner(nftAddress, tokenId)
        isApproved(nftAddress, tokenId)
        nonReentrant
    {
        State state = listings[nftAddress][tokenId].state;
        if (state == State.LISTED) {
            revert AlreadyListed(nftAddress, tokenId);
        }
        if (state == State.REDEEMED) {
            revert AlreadyRedeem();
        }
        if (price <= 0) {
            revert PriceMustBeAboveZero();
        }

        address creator = IERC721_IERC2981(nftAddress).owner();

        listings[nftAddress][tokenId] = Listing(
            creator,
            msg.sender,
            price,
            State.LISTED
        );

        emit ItemListed(msg.sender, nftAddress, tokenId, price);
    }

    /// @notice Cancel a listed NFT item
    /// @param nftAddress The address of the NFT contract
    /// @param tokenId The ID of the NFT to cancel the listing for
    function cancelListing(
        address nftAddress,
        uint256 tokenId
    )
        external
        isTokenOwner(nftAddress, tokenId)
        isListed(nftAddress, tokenId)
        nonReentrant
    {
        Listing storage listing = listings[nftAddress][tokenId];
        listing.state = State.CANCELLED;
        emit ItemCanceled(msg.sender, nftAddress, tokenId);
    }

    /// @notice Buy a listed NFT item
    /// @dev This function reverts if the owner of the token has changed without update or the token is not approved for the marketplace
    /// @param nftAddress The address of the NFT contract
    /// @param tokenId The ID of the NFT to buy
    function buyItem(
        address nftAddress,
        uint256 tokenId
    ) external payable isListed(nftAddress, tokenId) nonReentrant {
        Listing storage listedItem = listings[nftAddress][tokenId];

        IERC721_IERC2981 nft = IERC721_IERC2981(nftAddress);
        if (nft.ownerOf(tokenId) != listedItem.owner) {
            revert OwnerChangedWithoutUpdate();
        }

        if (
            nft.getApproved(tokenId) != address(this) &&
            !nft.isApprovedForAll(listedItem.owner, address(this))
        ) {
            revert NotApprovedForMarketplace();
        }

        (
            uint256 priceInWei,
            address paymentSplitterAddress,
            uint256 royaltyAmount,
            uint256 balance,
            uint256 paymentToMarketplace
        ) = balanceCalculation(
                nftAddress,
                tokenId,
                listedItem.price,
                msg.value
            );

        // Release to paymentSplitter
        payable(paymentSplitterAddress).transfer(royaltyAmount);

        // Release royalty to NFTMarketplace Owner and Collection Creator
        IPaymentSplitter(paymentSplitterAddress).release(payable(owner()));
        IPaymentSplitter(paymentSplitterAddress).release(listedItem.creator);

        // Release balance to Collection Owner
        payable(listedItem.owner).transfer(balance);

        // Release balance to Marketplace Owner
        payable(owner()).transfer(paymentToMarketplace);

        nft.safeTransferFrom(listedItem.owner, msg.sender, tokenId);

        listedItem.owner = msg.sender;
        listedItem.state = State.TRANSFERRED;

        emit ItemBought(
            msg.sender,
            nftAddress,
            tokenId,
            listedItem.price,
            priceInWei
        );
    }

    /// @notice Allows an investor to redeem profit from an NFT
    /// @dev The function reverts if called by a contract other than the redemption contract, or if the state of the NFT is not 'transferred'
    /// @param nftAddress The address of the NFT contract
    /// @param tokenId The ID of the token to redeem profit from
    /// @param investor The address of the investor
    function redeemProfit(
        address nftAddress,
        uint256 tokenId,
        address investor
    ) external nonReentrant {
        if (msg.sender != redemptionContractAddress) {
            revert NotRedemptionContract();
        }
        Listing storage listing = listings[nftAddress][tokenId];
        if (listing.state == State.REDEEMED) {
            revert AlreadyRedeem();
        }
        if (listing.state != State.TRANSFERRED) {
            revert NotTransferred();
        }

        if (listing.owner != investor) {
            revert NotInvestor();
        }
        listing.state = State.REDEEMED;
    }

    /// @notice Updates the price of a listed item
    /// @dev The function reverts if the new price is zero or below
    /// @param nftAddress The address of the NFT contract
    /// @param tokenId The ID of the token whose listing will be updated
    /// @param newPrice The new price for the listed item
    function updateListing(
        address nftAddress,
        uint256 tokenId,
        uint256 newPrice
    )
        external
        isListed(nftAddress, tokenId)
        isTokenOwner(nftAddress, tokenId)
        nonReentrant
    {
        if (newPrice <= 0) {
            revert PriceMustBeAboveZero();
        }
        listings[nftAddress][tokenId].price = newPrice;
        emit ItemListed(msg.sender, nftAddress, tokenId, newPrice);
    }
}