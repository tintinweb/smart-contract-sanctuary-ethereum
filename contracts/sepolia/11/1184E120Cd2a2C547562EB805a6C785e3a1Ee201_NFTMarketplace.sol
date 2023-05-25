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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";

interface IERC721_IERC2981 is
    IERC721,
    IERC2981
{
    function owner() external returns (address);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.8;
import "./IERC721_IERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

interface IPaymentSplitter {
    function release(address) external;
}

enum State {
    NOTLISTED, // First state
    LISTED, //NFT listed by creator or owner
    CANCELED, //NFT canceled from listing
    TRANSFERED, //NFT sold to owner
    REDEEMED //NFT profit redeemed by owner
}

struct Listing {
    address creator; // collection owner. For royalty purpose
    address owner; // token owner, initially is collection owner
    uint256 price; // price in USD, two decimal place (1.00 ==  100)
    State state; // State of the token
}

struct Proceed {
    address paymentSplitterAddress;
    uint256 balance;
    uint256 royaltyAmount;
}

error PriceNotMet(
    address nftAddress,
    uint256 tokenId,
    uint256 price,
    uint256 priceInWei
);
error ItemNotForSale(address nftAddress, uint256 tokenId);
error NotListed(address nftAddress, uint256 tokenId);

error AlreadyListed(address nftAddress, uint256 tokenId);
error NoProceeds();
error NotOwner();
error NotApprovedForMarketplace();
error PriceMustBeAboveZero();
error BalanceMustBeAboveZero();

error NotRedemptionContract();
error NotTransfered();
error NotInvestor();
error AlreadyRedeem();
error FunctionLocked();
error ZeroAddress();

contract NFTMarketplace is
    Ownable,
    ReentrancyGuard
{
    AggregatorV3Interface private priceFeed;
    uint256 private listingFeeBPS;
    address private redemptionContractAddress;


    // nftAddress => tokenId => listing
    mapping(address => mapping(uint256 => Listing)) private listings;
    // nftAddress => tokenId => listingFee
    mapping(address => mapping(uint256 => uint256)) private listingFees;
    // nftAddress => tokenId => seller address  => proceed
    // mapping(address => mapping(uint256 => mapping(address => Proceed))) private proceeds;
    // nftAddress => creator

    // uint256[50] public __NFTMarketGap;

    /* ---------------------------------------------------------------------------------------------- */
    function getPriceFeedAddress() external view returns (address) {
        return address(priceFeed);
    }

    function getListingFeeBPS() external view returns (uint256) {
        return listingFeeBPS;
    }

    function getRedemptionContractAddress() external view returns (address) {
        return redemptionContractAddress;
    }

    function getListing(
        address nftAddress,
        uint256 tokenId
    ) external view returns (Listing memory) {
        return listings[nftAddress][tokenId];
    }

    // function getProceed(
    //     address nftAddress,
    //     uint256 tokenId
    // ) external view returns (Proceed memory) {
    //     return proceeds[nftAddress][tokenId][msg.sender];
    // }

    function getListingFee(
        address nftAddress,
        uint256 tokenId
    ) external view returns (uint256) {
        return listingFees[nftAddress][tokenId];
    }



    /* ---------------------------------------------------------------------------------------------- */
    event ItemListed(
        address indexed owner,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 price
    );

    event ItemCanceled(
        address indexed owner,
        address indexed nftAddress,
        uint256 indexed tokenId
    );

    event ItemBought(
        address indexed owner,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 price,
        uint256 priceInWei
    );

    event UpdateRedeemContractAddress(address redeemContractAddress);

    event UpdateListingFee(uint256 listingFeeBPS);

    event UpdatePriceFeedAddress(address chainLink);

    event LockStatus(uint256 status);
    /* ---------------------------------------------------------------------------------------------- */
    modifier isListed(address nftAddress, uint256 tokenId) {
        if (listings[nftAddress][tokenId].state != State.LISTED) {
            revert NotListed(nftAddress, tokenId);
        }
        _;
    }

    modifier isTokenOwner(address nftAddress, uint256 tokenId) {
        IERC721_IERC2981 nft = IERC721_IERC2981(
            nftAddress
        );
        address owner = nft.ownerOf(tokenId);
        if (msg.sender != owner) {
            revert NotOwner();
        }
        _;
    }
    modifier isApproved(address nftAddress, uint256 tokenId) {
        IERC721_IERC2981 nft = IERC721_IERC2981(
            nftAddress
        );
        if (
            nft.getApproved(tokenId) != address(this) &&
            !nft.isApprovedForAll(msg.sender, address(this))
        ) {
            revert NotApprovedForMarketplace();
        }
        _;
    }

    /* ---------------------------------------------------------------------------------------------- */
    function getVersion() external pure returns (int256) {
        return 1;
    }

    constructor() {
        listingFeeBPS = 200; // 2%
        priceFeed = AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306); // ETH/USD for Sepolia Testnet
    }

    /* ---------------------------------------------------------------------------------------------- */
    function updateListingFee(uint256 newFeesBPS) external onlyOwner {
        listingFeeBPS = newFeesBPS;
        emit UpdateListingFee(newFeesBPS);
    }

    function updatePriceFeedAddress(address chainlink) external onlyOwner {
        if(chainlink==address(0)){
            revert ZeroAddress();
        }
        priceFeed = AggregatorV3Interface(chainlink);
        emit UpdatePriceFeedAddress(chainlink);
    }

    function updateRedeemContractAddress(
        address _redemptionContractAddress
    ) external onlyOwner {
        if(_redemptionContractAddress==address(0)){
            revert ZeroAddress();
        }
        redemptionContractAddress = _redemptionContractAddress;
        emit UpdateRedeemContractAddress(_redemptionContractAddress);
    }



    /* ---------------------------------------------------------------------------------------------- */

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

    function cancelListing(
        address nftAddress,
        uint256 tokenId
    ) external isTokenOwner(nftAddress, tokenId) isListed(nftAddress, tokenId) nonReentrant {
        Listing storage listing = listings[nftAddress][tokenId];
        listing.state = State.CANCELED;
        emit ItemCanceled(msg.sender, nftAddress, tokenId);
    }

    /* ---------------------------------------------------------------------------------------------- */
    function buyItem(
        address nftAddress,
        uint256 tokenId
    )
        external
        payable
        isListed(nftAddress, tokenId)
        nonReentrant
    {
        Listing storage listedItem = listings[nftAddress][tokenId];

        IERC721_IERC2981 nft = IERC721_IERC2981(
            nftAddress
        );

        if (
            nft.getApproved(tokenId) != address(this) &&
            !nft.isApprovedForAll(listedItem.creator, address(this))
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

        nft.safeTransferFrom(
            listedItem.owner,
            msg.sender,
            tokenId
        );


        listedItem.owner = msg.sender;
        listedItem.state = State.TRANSFERED;

        emit ItemBought(
            msg.sender,
            nftAddress,
            tokenId,
            listedItem.price,
            priceInWei
        );
    }

 

    /* ---------------------------------------------------------------------------------------------- */
    function getLatestPrice() public view returns (int256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return price;
    }

    function getDecimals() public view returns (uint8) {
        return priceFeed.decimals();
    }

    function getRequiredPriceInWei(
        uint256 requiredPriceInUSD
    ) public view returns (uint256) {
        int256 eth_usd = getLatestPrice();
        uint256 eth_usd_price = uint256(eth_usd) * 1e10;
        return (requiredPriceInUSD * 1e34) / eth_usd_price;
    }

    function balanceCalculation(
        address nftAddress,
        uint256 tokenId,
        uint256 price,
        uint256 payment
    ) public view returns (uint256, address, uint256, uint256, uint256) {
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
        ) = IERC721_IERC2981(nftAddress).royaltyInfo(
                tokenId,
                priceInWei
            );

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


    /* ---------------------------------------------------------------------------------------------- */
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
        if (listing.state != State.TRANSFERED) {
            revert NotTransfered();
        }

        if (listing.owner != investor) {
            revert NotInvestor();
        }
        listing.state = State.REDEEMED;
    }

    /* ---------------------------------------------------------------------------------------------- */

    function updateListing(
        address nftAddress,
        uint256 tokenId,
        uint256 newPrice
    ) external isListed(nftAddress, tokenId) isTokenOwner(nftAddress, tokenId) nonReentrant {
        if (newPrice <= 0) {
            revert PriceMustBeAboveZero();
        }
        listings[nftAddress][tokenId].price = newPrice;
        emit ItemListed(msg.sender, nftAddress, tokenId, newPrice);
    }
}