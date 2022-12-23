// SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721HolderUpgradeable.sol";
import "../interfaces/ITransferProxy.sol";
import "./NFTMarketReserveAuction.sol";
import "./TradeV4.sol";

/// @title EnigmaMarket
///
/// @dev This contract is a Transparent Upgradable based in openZeppelin v3.4.0.
///         Be careful when upgrade, you must respect the same storage.

contract EnigmaMarket is
    TradeV4,
    ERC721HolderUpgradeable, // Make sure the contract is able to use its
    NFTMarketReserveAuction
{
    /// oz-upgrades-unsafe-allow constructor
    // solhint-disable-next-line
    constructor() initializer {}

    /**
     * @notice Called once to configure the contract after the initial proxy deployment.
     * @dev This farms the initialize call out to inherited contracts as needed to initialize mutable variables.
     * @param _transferProxy the proxy from wich all NFT transfers are gonna be processed from.
     * @param _enigmaNFT721Address Enigma ERC721 NFT proxy.
     * @param _enigmaNFT1155Address Enigma ERC1155 NFT proxy.
     * @param _custodialAddress The address on wich NFTs are gonna be kept during Fiat Trades.
     * @param _minDuration The min duration for auctions, in seconds.
     * @param _maxDuration The max duration for auctions, in seconds.
     * @param _minIncrementPermille The minimum required when making an offer or placing a bid. Ej: 100 => 0.1 => 10%
     */
    function fullInitialize(
        ITransferProxy _transferProxy,
        address _enigmaNFT721Address,
        address _enigmaNFT1155Address,
        address _custodialAddress,
        uint256 _minDuration,
        uint256 _maxDuration,
        uint16 _minIncrementPermille
    ) external initializer {
        initializeTradeV4(_transferProxy, _enigmaNFT721Address, _enigmaNFT1155Address, _custodialAddress);
        __Ownable_init();
        __ReentrancyGuard_init();
        _initializeNFTMarketAuction();
        _initializeNFTMarketReserveAuction(_minDuration, _maxDuration);
        _initializeNFTMarketCore(_minIncrementPermille);
    }

    /**
     * @notice Called once to configure the contract after the initial proxy deployment.
     * @dev as we are updating an already deployed contracts, legacy vars don't need init.
     * @param _minDuration The min duration for auctions, in seconds.
     * @param _maxDuration The max duration for auctions, in seconds.
     */
    function upgradeInitialize(uint256 _minDuration, uint256 _maxDuration) external onlyOwner {
        _initializeNFTMarketAuction();
        _initializeNFTMarketReserveAuction(_minDuration, _maxDuration);
    }

    function getPlatformTreasury() public view returns (address payable) {
        // TODO: review if we don't need a new field for collecting fees
        return payable(owner());
    }

    /**
     * @inheritdoc NFTMarketCore
     */
    function _transferFromEscrow(
        address nftContract,
        uint256 tokenId,
        address recipient
    ) internal virtual override {
        // As we are transfering through our own market, there's no need to go by transferProxy
        IERC721(nftContract).transferFrom(address(this), recipient, tokenId);
    }

    /**
     * @inheritdoc NFTMarketCore
     */
    function _transferToEscrow(address nftContract, uint256 tokenId) internal virtual override {
        safeTransferFrom(AssetType.ERC721, msg.sender, address(this), nftContract, tokenId, 1);
    }

    /**
     * @dev Be careful when invoking this function as reentrancy guard should be put in place
     */
    // slither-disable-next-line reentrancy-eth
    function _distFunds(
        address nftContract,
        uint256 tokenId,
        uint256 amount,
        address payable seller,
        uint256 sellerFeesPerMille,
        uint256 buyerFeesPerMille
    )
        internal
        override
        returns (
            uint256 platformFee,
            uint256 royaltyFee,
            uint256 assetFee
        )
    {
        // Disable slither warning because it's only invoked from functions with nonReentrant checks
        FeeDistributionData memory feeDistributionData =
            getFees(amount, nftContract, tokenId, sellerFeesPerMille, buyerFeesPerMille, seller);
        _sendValueWithFallbackWithdraw(
            getPlatformTreasury(),
            feeDistributionData.fees.platformFee,
            SEND_VALUE_GAS_LIMIT_SINGLE_RECIPIENT
        );

        if (feeDistributionData.toRightsHolder > 0) {
            _sendValueWithFallbackWithdraw(
                payable(feeDistributionData.rightsHolder),
                feeDistributionData.toRightsHolder,
                SEND_VALUE_GAS_LIMIT_SINGLE_RECIPIENT
            );
        }

        if (feeDistributionData.toSeller > 0) {
            _sendValueWithFallbackWithdraw(seller, feeDistributionData.toSeller, SEND_VALUE_GAS_LIMIT_SINGLE_RECIPIENT);
        }

        return (
            feeDistributionData.fees.platformFee,
            feeDistributionData.fees.royaltyFee,
            feeDistributionData.fees.assetFee
        );
    }

    /*********************
     ** PUBLIC FUNCTIONS *
     *********************/

    /**
     * @notice Creates an auction for the given NFT.
     * The NFT is held in escrow until the auction is finalized or canceled.
     * @param nftContract The address of the NFT contract.
     * @param tokenId The id of the NFT.
     * @param duration seconds for how long an auction lasts for once the first bid has been received.
     * @param reservePrice The initial reserve price for the auction.
     */
    function createReserveAuction(
        address nftContract,
        uint256 tokenId,
        uint256 duration,
        uint256 reservePrice,
        PlatformFees calldata platformFees
    ) external nonReentrant onlyValidAuctionConfig(reservePrice) {
        // get the amount, including buyer fees for this reserve price
        uint256 amount = applyBuyerFee(reservePrice, platformFees.buyerFeePermille);
        createReserveAuctionFor(nftContract, tokenId, duration, reservePrice, amount, platformFees);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "../../introspection/IERC165.sol";

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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC721ReceiverUpgradeable.sol";
import "../../proxy/Initializable.sol";

  /**
   * @dev Implementation of the {IERC721Receiver} interface.
   *
   * Accepts all token transfers. 
   * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
   */
contract ERC721HolderUpgradeable is Initializable, IERC721ReceiverUpgradeable {
    function __ERC721Holder_init() internal initializer {
        __ERC721Holder_init_unchained();
    }

    function __ERC721Holder_init_unchained() internal initializer {
    }

    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

interface ITransferProxy {
    function erc721safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 tokenId
    ) external;

    function erc1155safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external;

    function erc20safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) external;
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

/// @dev Taken from https://github.com/f8n/fnd-protocol/tree/v2.0.3

import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

import "./NFTMarketAuction.sol";
import "./NFTMarketCore.sol";
import "./SendValueWithFallbackWithdraw.sol";
import "./TradeV4.sol";
import "./utils/PlatformFees.sol";

// The gas limit to send ETH to a single recipient, enough for a contract with a simple receiver.
uint256 constant SEND_VALUE_GAS_LIMIT_SINGLE_RECIPIENT = 20000;

// solhint-disable max-line-length
string constant ReserveAuction_Already_Listed = "ReserveAuction_Already_Listed";
string constant ReserveAuction_Bid_Must_Be_At_Least_Min_Amount = "ReserveAuction_Bid_Must_Be_At_Least_Min_Amount";
string constant ReserveAuction_Cannot_Admin_Cancel_Without_Reason = "ReserveAuction_Cannot_Admin_Cancel_Without_Reason";
string constant ReserveAuction_Cannot_Bid_Lower_Than_Reserve_Price = "ReserveAuction_Cannot_Bid_Lower_Than_Reserve_Price";
string constant ReserveAuction_Cannot_Bid_On_Ended_Auction = "ReserveAuction_Cannot_Bid_On_Ended_Auction";
string constant ReserveAuction_Cannot_Bid_On_Nonexistent_Auction = "ReserveAuction_Cannot_Bid_On_Nonexistent_Auction";
string constant ReserveAuction_Cannot_Cancel_Nonexistent_Auction = "ReserveAuction_Cannot_Cancel_Nonexistent_Auction";
string constant ReserveAuction_Cannot_Finalize_Already_Settled_Auction = "ReserveAuction_Cannot_Finalize_Already_Settled_Auction";
string constant ReserveAuction_Cannot_Finalize_Auction_In_Progress = "ReserveAuction_Cannot_Finalize_Auction_In_Progress";
string constant ReserveAuction_Cannot_Rebid_Over_Outstanding_Bid = "ReserveAuction_Cannot_Rebid_Over_Outstanding_Bid";
string constant ReserveAuction_Cannot_Update_Auction_In_Progress = "ReserveAuction_Cannot_Update_Auction_In_Progress";
string constant ReserveAuction_Subceeds_Min_Duration = "ReserveAuction_Subceeds_Min_Duration";
string constant ReserveAuction_Exceeds_Max_Duration = "ReserveAuction_Exceeds_Max_Duration";
string constant ReserveAuction_Less_Than_Extension_Duration = "ReserveAuction_Less_Than_Extension_Duration";
string constant ReserveAuction_Must_Set_Non_Zero_Reserve_Price = "ReserveAuction_Must_Set_Non_Zero_Reserve_Price";
string constant ReserveAuction_Not_Matching_Bidder = "ReserveAuction_Not_Matching_Bidder";
string constant ReserveAuction_Only_Owner_Can_Update_Auction = "ReserveAuction_Only_Owner_Can_Update_Auction";
string constant ReserveAuction_Price_Already_Set = "ReserveAuction_Price_Already_Set";

// solhint-enable max-line-length

/**
 * @title Allows the owner of an NFT to list it in auction.
 * @notice NFTs in auction are escrowed in the market contract.
 */
abstract contract NFTMarketReserveAuction is
    ReentrancyGuardUpgradeable,
    NFTMarketCore,
    NFTMarketAuction,
    SendValueWithFallbackWithdraw
{
    // Stores the auction configuration for a specific NFT.
    struct ReserveAuction {
        // The address of the NFT contract.
        address nftContract;
        // The id of the NFT.
        uint256 tokenId;
        // The owner of the NFT which listed it in auction.
        address payable seller;
        // The duration for this auction.
        uint256 duration;
        // The extension window for this auction.
        uint256 extensionDuration;
        // The time at which this auction will not accept any new bids.
        // @dev This is `0` until the first bid is placed.
        uint256 endTime;
        // The current highest bidder in this auction.
        // @dev This is `address(0)` until the first bid is placed.
        address payable bidder;
        // The latest amount locked in for this auction. Includes buyerFee.
        // @dev This is set to the reserve price + buyerFee, and then to the highest bid once the auction has started.
        uint256 amount;
        // The buyerFee at the moment the auction was created. Expressed as x1000 (ej: 100 => 10% = 0.1)
        uint8 buyerFeePermille;
        // The sellerFee at the moment the auction was created. Expressed as x1000 (ej: 100 => 10% = 0.1)
        uint8 sellerFeePermille;
    }

    /// @dev The auction configuration for a specific auction id.
    mapping(address => mapping(uint256 => uint256)) internal nftContractToTokenIdToAuctionId;

    /// @dev The auction id for a specific NFT.
    /// @dev This is deleted when an auction is finalized or canceled.
    mapping(uint256 => ReserveAuction) internal auctionIdToAuction;

    /// @dev Minimal value for how long an auction can lasts for once the first bid has been received.
    uint256 internal minDuration;

    /// @dev Maximal value for how long an auction can lasts for once the first bid has been received.
    uint256 internal maxDuration;

    /// @dev The window for auction extensions, any bid placed in the final 15 minutes
    /// of an auction will reset the time remaining to 15 minutes.
    uint256 internal constant EXTENSION_DURATION = 15 minutes;

    /// @dev Caps the max duration that may be configured so that overflows will not occur.
    uint256 internal constant MAX_MAX_DURATION = 1000 days;

    /**
     * @notice Emitted when a bid is placed.
     * @param auctionId The id of the auction this bid was for.
     * @param bidder The address of the bidder.
     * @param amount The amount of the bid.
     * @param endTime The new end time of the auction (which may have been set or extended by this bid).
     */
    event ReserveAuctionBidPlaced(uint256 indexed auctionId, address indexed bidder, uint256 amount, uint256 endTime);
    /**
     * @notice Emitted when an auction is cancelled.
     * @dev This is only possible if the auction has not received any bids.
     * @param auctionId The id of the auction that was cancelled.
     */
    event ReserveAuctionCanceled(uint256 indexed auctionId);
    /**
     * @notice Emitted when an auction is canceled by a Enigma admin.
     * @dev When this occurs, the highest bidder (if there was a bid) is automatically refunded.
     * @param auctionId The id of the auction that was cancelled.
     * @param reason The reason for the cancellation.
     */
    event ReserveAuctionCanceledByAdmin(uint256 indexed auctionId, string reason);
    /**
     * @notice Emitted when an NFT is listed for auction.
     * @param seller The address of the seller.
     * @param nftContract The address of the NFT contract.
     * @param tokenId The id of the NFT.
     * @param duration The duration of the auction (always 24-hours).
     * @param extensionDuration The duration of the auction extension window (always 15-minutes).
     * @param reservePrice The reserve price to kick off the auction.
     * @param bidAmount Reserve price, plus buyerFee. Min amount required to win this auction.
     * @param auctionId The id of the auction that was created.
     */
    event ReserveAuctionCreated(
        address indexed seller,
        address indexed nftContract,
        uint256 indexed tokenId,
        uint256 duration,
        uint256 extensionDuration,
        uint256 reservePrice,
        uint256 bidAmount,
        uint256 auctionId
    );
    /**
     * @notice Emitted when an auction that has already ended is finalized,
     * indicating that the NFT has been transferred and revenue from the sale distributed.
     * @dev The amount of the highest bid / final sale price for this auction is `f8nFee` + `creatorFee` + `ownerRev`.
     * @param auctionId The id of the auction that was finalized.
     * @param seller The address of the seller.
     * @param bidder The address of the highest bidder that won the NFT.
     * @param platformFee The amount of ETH that was sent to Enigma for this sale.
     * @param royaltyFee The amount of ETH that was sent to the creator for this sale.
     * @param sellerRev The amount of ETH that was sent to the sellet for this NFT.
     */
    event ReserveAuctionFinalized(
        uint256 indexed auctionId,
        address indexed seller,
        address indexed bidder,
        uint256 platformFee,
        uint256 royaltyFee,
        uint256 sellerRev
    );
    /**
     * @notice Emitted when the auction's reserve price is changed.
     * @dev This is only possible if the auction has not received any bids.
     * @param auctionId The id of the auction that was updated.
     * @param reservePrice The new reserve price for the auction.
     */
    event ReserveAuctionUpdated(uint256 indexed auctionId, uint256 reservePrice);

    /// @notice Confirms that the reserve price is not zero.
    modifier onlyValidAuctionConfig(uint256 reservePrice) {
        if (reservePrice == 0) {
            revert(ReserveAuction_Must_Set_Non_Zero_Reserve_Price);
        }
        _;
    }

    /// oz-upgrades-unsafe-allow constructor
    // solhint-disable-next-line
    constructor() {}

    /**
     * @notice Configures the duration for auctions.
     * @param _minDuration The min duration for auctions, in seconds.
     * @param _maxDuration The max duration for auctions, in seconds.
     */
    function _initializeNFTMarketReserveAuction(uint256 _minDuration, uint256 _maxDuration) internal {
        if (_maxDuration > MAX_MAX_DURATION) {
            // This ensures that math in this file will not overflow due to a huge duration.
            revert(ReserveAuction_Exceeds_Max_Duration);
        }
        if (_minDuration < EXTENSION_DURATION) {
            // The auction duration configuration must be greater than the extension window of 15 minutes
            revert(ReserveAuction_Less_Than_Extension_Duration);
        }
        minDuration = _minDuration;
        maxDuration = _maxDuration;
    }

    /**
     * @notice Creates an auction for the given NFT.
     * The NFT is held in escrow until the auction is finalized or canceled.
     * buyer and seller fees are locked at creation time
     * @param nftContract The address of the NFT contract.
     * @param tokenId The id of the NFT.
     * @param duration seconds for how long an auction lasts for once the first bid has been received.
     * @param reservePrice The initial reserve price for the auction.
     */
    function createReserveAuctionFor(
        address nftContract,
        uint256 tokenId,
        uint256 duration,
        uint256 reservePrice,
        uint256 amount,
        PlatformFees calldata platformFees
    ) internal {
        uint256 auctionId = nftContractToTokenIdToAuctionId[nftContract][tokenId];
        if (auctionId == 0) {
            // NFT is not in auction
            // If the `msg.sender` is not the owner of the NFT, transferring into escrow should fail.
            _transferToEscrow(nftContract, tokenId);
        } else {
            // Using storage saves gas since most of the data is not needed
            ReserveAuction storage auction = auctionIdToAuction[auctionId];
            if (auction.endTime == 0) {
                revert(ReserveAuction_Already_Listed);
            } else {
                // Auction in progress, confirm the highest bidder is a match
                if (auction.bidder != msg.sender) {
                    revert(ReserveAuction_Not_Matching_Bidder);
                }

                // Finalize auction but leave NFT in escrow, reverts if the auction has not ended
                _finalizeReserveAuction({ auctionId: auctionId, keepInEscrow: true });
            }
        }
        // Get the new Id
        auctionId = _getNextAndIncrementAuctionId();

        // This checks if duration is between acceptable
        if (minDuration > duration) {
            revert(ReserveAuction_Subceeds_Min_Duration);
        }
        if (duration > maxDuration) {
            revert(ReserveAuction_Exceeds_Max_Duration);
        }

        // Store the auction details
        nftContractToTokenIdToAuctionId[nftContract][tokenId] = auctionId;
        PlatformFeesFunctions.checkValidPlatformFees(platformFees, owner());
        auctionIdToAuction[auctionId] = ReserveAuction(
            nftContract,
            tokenId,
            payable(msg.sender),
            duration,
            EXTENSION_DURATION,
            0, // endTime is only known once the reserve price is met
            payable(0), // bidder is only known once a bid has been placed
            amount,
            platformFees.buyerFeePermille, // fees are locked-in at create time
            platformFees.sellerFeePermille
        );

        emit ReserveAuctionCreated(
            msg.sender,
            nftContract,
            tokenId,
            duration,
            EXTENSION_DURATION,
            reservePrice,
            amount,
            auctionId
        );
    }

    /**
     * @notice Once the countdown has expired for an auction, anyone can settle the auction.
     * This will send the NFT to the highest bidder and distribute revenue for this sale.
     * @param auctionId The id of the auction to settle.
     */
    function finalizeReserveAuction(uint256 auctionId) external nonReentrant {
        if (auctionIdToAuction[auctionId].endTime == 0) {
            revert(ReserveAuction_Cannot_Finalize_Already_Settled_Auction);
        }
        _finalizeReserveAuction({ auctionId: auctionId, keepInEscrow: false });
    }

    /**
     * @notice Settle an auction that has already ended.
     * This will send the NFT to the highest bidder and distribute revenue for this sale.
     * @param keepInEscrow If true, the NFT will be kept in escrow to save gas by avoiding
     * redundant transfers if the NFT should remain in escrow, such as when the new owner
     * sets a buy price or lists it in a new auction.
     */
    function _finalizeReserveAuction(uint256 auctionId, bool keepInEscrow) internal {
        ReserveAuction memory auction = auctionIdToAuction[auctionId];

        if (auction.endTime >= block.timestamp) {
            revert(ReserveAuction_Cannot_Finalize_Auction_In_Progress);
        }

        // Remove the auction.
        delete nftContractToTokenIdToAuctionId[auction.nftContract][auction.tokenId];
        delete auctionIdToAuction[auctionId];

        if (!keepInEscrow) {
            // The seller was authorized when the auction was originally created
            _transferFromEscrow(auction.nftContract, auction.tokenId, auction.bidder);
        }

        // Distribute revenue for this sale.
        (uint256 platformFee, uint256 royaltyFee, uint256 assetFee) = _distAuctionFunds(auction);

        emit ReserveAuctionFinalized(auctionId, auction.seller, auction.bidder, platformFee, royaltyFee, assetFee);
    }

    function _distAuctionFunds(ReserveAuction memory auction)
        internal
        returns (
            uint256 platformFee,
            uint256 royaltyFee,
            uint256 assetFee
        )
    {
        return
            _distFunds(
                auction.nftContract,
                auction.tokenId,
                auction.amount,
                auction.seller,
                auction.sellerFeePermille,
                auction.buyerFeePermille
            );
    }

    /**
     * @notice Allows Enigma to cancel an auction, refunding the bidder and returning the NFT to
     * the seller (if not active buy price set).
     * This should only be used for extreme cases such as DMCA takedown requests.
     * @param auctionId The id of the auction to cancel.
     * @param reason The reason for the cancellation (a required field).
     */
    function adminCancelReserveAuction(uint256 auctionId, string calldata reason) external onlyOwner nonReentrant {
        if (bytes(reason).length == 0) {
            revert(ReserveAuction_Cannot_Admin_Cancel_Without_Reason);
        }
        ReserveAuction memory auction = auctionIdToAuction[auctionId];
        if (auction.amount == 0) {
            revert(ReserveAuction_Cannot_Cancel_Nonexistent_Auction);
        }

        delete nftContractToTokenIdToAuctionId[auction.nftContract][auction.tokenId];
        delete auctionIdToAuction[auctionId];

        // Return the NFT to the owner.
        _transferFromEscrow(auction.nftContract, auction.tokenId, auction.seller);

        if (auction.bidder != address(0)) {
            // Refund the highest bidder if any bids were placed in this auction.
            _sendValueWithFallbackWithdraw(auction.bidder, auction.amount, SEND_VALUE_GAS_LIMIT_SINGLE_RECIPIENT);
        }

        emit ReserveAuctionCanceledByAdmin(auctionId, reason);
    }

    /**
     * @notice If an auction has been created but has not yet received bids, it may be canceled by the seller.
     * @dev The NFT is transferred back to the owner unless there is still a buy price set.
     * @param auctionId The id of the auction to cancel.
     */
    function cancelReserveAuction(uint256 auctionId) external nonReentrant {
        ReserveAuction memory auction = auctionIdToAuction[auctionId];
        if (auction.amount == 0) {
            revert(ReserveAuction_Cannot_Cancel_Nonexistent_Auction);
        }
        if (auction.seller != msg.sender) {
            revert(ReserveAuction_Only_Owner_Can_Update_Auction);
        }
        if (auction.endTime != 0) {
            revert(ReserveAuction_Cannot_Update_Auction_In_Progress);
        }

        // Remove the auction.
        delete nftContractToTokenIdToAuctionId[auction.nftContract][auction.tokenId];
        delete auctionIdToAuction[auctionId];

        // Transfer the NFT.
        _transferFromEscrow(auction.nftContract, auction.tokenId, auction.seller);

        emit ReserveAuctionCanceled(auctionId);
    }

    /**
     * @notice Place a bid in an auction.
     * A bidder may place a bid which is at least the value defined by `getMinBidAmount`.
     * If this is the first bid on the auction, the countdown will begin.
     * If there is already an outstanding bid, the previous bidder will be refunded at this time
     * and if the bid is placed in the final moments of the auction, the countdown may be extended.
     * @param auctionId The id of the auction to bid on.
     */
    /* solhint-disable-next-line code-complexity */
    function placeBid(uint256 auctionId) external payable nonReentrant {
        ReserveAuction storage auction = auctionIdToAuction[auctionId];

        if (auction.amount == 0) {
            // No auction found
            revert(ReserveAuction_Cannot_Bid_On_Nonexistent_Auction);
        }

        uint256 endTime = auction.endTime;
        if (endTime == 0) {
            // This is the first bid, kicking off the auction.

            if (msg.value < auction.amount) {
                // The bid must be >= the reserve price.
                revert(ReserveAuction_Cannot_Bid_Lower_Than_Reserve_Price);
            }

            // Store the bid details.
            auction.amount = msg.value;
            auction.bidder = payable(msg.sender);

            // On the first bid, set the endTime to now + duration.
            // Duration is always less than MAX MAX, so the below can't overflow.
            endTime = block.timestamp + auction.duration;

            auction.endTime = endTime;
        } else {
            if (endTime < block.timestamp) {
                // The auction has already ended.
                revert(ReserveAuction_Cannot_Bid_On_Ended_Auction);
            } else if (auction.bidder == msg.sender) {
                // We currently do not allow a bidder to increase their bid unless another user has outbid them first.
                revert(ReserveAuction_Cannot_Rebid_Over_Outstanding_Bid);
            } else {
                uint256 minIncrement = _getMinIncrement(auction.amount);
                if (msg.value < minIncrement) {
                    // If this bid outbids another, it must be at least 10% greater than the last bid.
                    revert(ReserveAuction_Bid_Must_Be_At_Least_Min_Amount);
                }
            }

            // Cache and update bidder state
            uint256 originalAmount = auction.amount;
            address payable originalBidder = auction.bidder;
            auction.amount = msg.value;
            auction.bidder = payable(msg.sender);

            // When a bid outbids another, check to see if a time extension should apply.
            // We confirmed that the auction has not ended, so endTime is always >= the current timestamp.
            // Current time plus extension duration (always 15 mins) cannot overflow.
            uint256 endTimeWithExtension = block.timestamp + EXTENSION_DURATION;
            if (endTime < endTimeWithExtension) {
                endTime = endTimeWithExtension;
                auction.endTime = endTime;
            }
            // Refund the previous bidder
            _sendValueWithFallbackWithdraw(originalBidder, originalAmount, SEND_VALUE_GAS_LIMIT_SINGLE_RECIPIENT);
        }
        emit ReserveAuctionBidPlaced(auctionId, msg.sender, msg.value, endTime);
    }

    /**
     * @notice If an auction has been created but has not yet received bids, the reservePrice may be
     * changed by the seller.
     * @param auctionId The id of the auction to change.
     * @param reservePrice The new reserve price for this auction.
     */
    function updateReserveAuction(uint256 auctionId, uint256 reservePrice)
        external
        onlyValidAuctionConfig(reservePrice)
    {
        ReserveAuction storage auction = auctionIdToAuction[auctionId];
        if (auction.seller != msg.sender) {
            revert(ReserveAuction_Only_Owner_Can_Update_Auction);
        } else if (auction.endTime != 0) {
            revert(ReserveAuction_Cannot_Update_Auction_In_Progress);
        }

        // get the amount, including buyer fee for this reserve price
        uint256 amount = applyBuyerFee(reservePrice, auction.buyerFeePermille);
        if (auction.amount == amount) revert(ReserveAuction_Price_Already_Set);

        // Update the current reserve price.
        auction.amount = amount;

        emit ReserveAuctionUpdated(auctionId, reservePrice);
    }

    /**
     * @notice Returns the minimum amount a bidder must spend to participate in an auction.
     * Bids must be greater than or equal to this value or they will revert.
     * @param auctionId The id of the auction to check.
     * @return minimum The minimum amount for a bid to be accepted.
     */
    function getMinBidAmount(uint256 auctionId) external view returns (uint256 minimum) {
        ReserveAuction storage auction = auctionIdToAuction[auctionId];
        if (auction.endTime == 0) {
            return auction.amount;
        }
        return _getMinIncrement(auction.amount);
    }

    /**
     * @notice Returns auction details for a given auctionId.
     * @param auctionId The id of the auction to lookup.
     * @return auction The auction details.
     */
    function getReserveAuction(uint256 auctionId) external view returns (ReserveAuction memory auction) {
        return auctionIdToAuction[auctionId];
    }

    /**
     * @notice Returns the auctionId for a given NFT, or 0 if no auction is found.
     * @dev If an auction is canceled, it will not be returned. However the auction may be over
     *  and pending finalization.
     * @param nftContract The address of the NFT contract.
     * @param tokenId The id of the NFT.
     * @return auctionId The id of the auction, or 0 if no auction is found.
     */
    function getReserveAuctionIdFor(address nftContract, uint256 tokenId) external view returns (uint256 auctionId) {
        auctionId = nftContractToTokenIdToAuctionId[nftContract][tokenId];
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[1000] private __gap;
}

// SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "../utils/AuthorizationBitmap.sol";
import "../utils/Types.sol";
import "../interfaces/ITransferProxy.sol";
import "../interfaces/IRoyaltyAwareNFT.sol";
import "../utils/BlockchainUtils.sol";
import "./utils/PlatformFees.sol";

/// @title TradeV4
///
/// @dev This contract is a Transparent Upgradable based in openZeppelin v3.4.0.
///         Be careful when upgrade, you must respect the same storage.

abstract contract TradeV4 is ReentrancyGuardUpgradeable, OwnableUpgradeable {
    using SafeMathUpgradeable for uint256;

    enum AssetType { ERC1155, ERC721 }

    event SellerFee(uint8 sellerFee);
    event BuyerFee(uint8 buyerFee);
    event CustodialAddressChanged(address prevAddress, address newAddress);
    event BuyAsset(address indexed assetOwner, uint256 indexed tokenId, uint256 quantity, address indexed buyer);
    event ExecuteBid(address indexed assetOwner, uint256 indexed tokenId, uint256 quantity, address indexed buyer);
    event TokenWithdraw(address indexed assetOwner, uint256 indexed authId, uint256 indexed tokenId, uint256 quantity);

    /// @dev deprecated
    uint8 internal _buyerFeePermille;
    /// @dev deprecated
    uint8 internal _sellerFeePermille;
    ITransferProxy public transferProxy;
    address public enigmaNFT721Address;
    address public enigmaNFT1155Address;
    // Address that acts as custodial for platform hold NFTs,
    address public custodialAddress;

    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    // This is a packed array of booleans, to track processed authorizations
    mapping(uint256 => uint256) internal processedAuthorizationsBitMap;

    struct FeeDistributionData {
        uint256 toRightsHolder; // Amount of tokens/ethers that will be sent to the rights holder(royalty receiver)
        uint256 toSeller; // Amount of tokens/ethers that will be sent to the seller
        address rightsHolder; // Rights holder address(tipically the creator, or a smart contract that splits the fees)
        Fees fees;
    }

    /// @notice Struct that contains all the fees of a given sale
    struct Fees {
        uint256 platformFee; // Sum of buyerFee + sellerFee, this is what the platform charges for a sale
        // Amount sent - royalty - platformFee, this is what is left after fees are
        // taken(usually goes to the seller unless this is a primary sale)
        uint256 assetFee;
        uint256 royaltyFee; // Royalty fee (could be split or not), it is intended to go to the artist/creator
        uint256 price; // Amount sent - buyerFee, it should be the price that the seller set on the asset
    }

    struct Order {
        address seller;
        address buyer;
        address erc20Address;
        address nftAddress;
        AssetType nftType;
        uint256 unitPrice;
        uint256 amount;
        uint256 tokenId;
        uint256 qty;
    }

    struct WithdrawRequest {
        uint256 authId; // Unique id for this withdraw authorization
        address assetAddress;
        AssetType assetType;
        uint256 tokenId;
        uint256 qty;
    }

    function initializeTradeV4(
        ITransferProxy _transferProxy,
        address _enigmaNFT721Address,
        address _enigmaNFT1155Address,
        address _custodialAddress
    ) internal initializer {
        transferProxy = _transferProxy;
        enigmaNFT721Address = _enigmaNFT721Address;
        enigmaNFT1155Address = _enigmaNFT1155Address;
        custodialAddress = _custodialAddress;
        __Ownable_init();
        __ReentrancyGuard_init();
    }

    function setCustodialAddress(address _custodialAddress) external onlyOwner returns (bool) {
        emit CustodialAddressChanged(custodialAddress, _custodialAddress);
        custodialAddress = _custodialAddress;
        return true;
    }

    function verifySellerSignature(
        address seller,
        uint256 tokenId,
        uint256 amount,
        address paymentAssetAddress,
        address assetAddress,
        uint8 sellerFeePermile,
        Signature memory signature
    ) internal pure {
        bytes32 hash =
            keccak256(
                abi.encodePacked(
                    BlockchainUtils.getChainID(),
                    assetAddress,
                    tokenId,
                    paymentAssetAddress,
                    amount,
                    sellerFeePermile
                )
            );
        require(seller == BlockchainUtils.getSigner(hash, signature), "seller sign verification failed");
    }

    /**
     * @notice Verifies the custodial authorization for this withdraw for this assetOwner
     * @param assetCustodial current asset holder
     * @param assetOwner real asset owner address
     * @param wr struct with the withdraw information. What asset and how much of it
     * @param signature struct combination of uint8, bytes32, bytes32 are v, r, s.
     */
    function verifyWithdrawSignature(
        address assetCustodial,
        address assetOwner,
        WithdrawRequest memory wr,
        Signature memory signature
    ) internal pure {
        bytes32 hash =
            keccak256(
                abi.encodePacked(
                    BlockchainUtils.getChainID(),
                    assetOwner,
                    wr.authId,
                    wr.tokenId,
                    wr.assetAddress,
                    wr.qty
                )
            );
        require(assetCustodial == BlockchainUtils.getSigner(hash, signature), "withdraw sign verification failed");
    }

    /**
     * @notice Calculates fees of an operation from the paymentAmount as well as ask for the royalty fees receiver
     * because it is part of the ERC2981 standard
     * @param paymentAmt Amount that the user sent(NOT the price, it is the price + buyer fee)
     * @param buyingAssetAddress the token symbol
     * @param tokenId Token id of the token being sold
     * @param sellerFeePermille Seller fee in Permille(unit per thousand of the total)
     * @param buyerFeePermille Buyer fee in Permille(unit per thousand of the total)
     */
    function calculateFees(
        uint256 paymentAmt,
        address buyingAssetAddress,
        uint256 tokenId,
        uint256 sellerFeePermille,
        uint256 buyerFeePermille
    ) internal view virtual returns (address, Fees memory) {
        Fees memory fees;
        address royaltyFeeReceiver;
        uint256 price = paymentAmt.mul(1000).div((1000 + buyerFeePermille));
        uint256 buyerFee = paymentAmt.sub(price);
        uint256 sellerFee = price.mul(sellerFeePermille).div((1000));
        fees.platformFee = buyerFee.add(sellerFee);

        bool success = IERC165Upgradeable(buyingAssetAddress).supportsInterface(_INTERFACE_ID_ERC2981);
        if (success) {
            (royaltyFeeReceiver, fees.royaltyFee) = IERC2981(buyingAssetAddress).royaltyInfo(tokenId, price);
        } else {
            fees.royaltyFee = 0;
        }
        fees.assetFee = price.sub(sellerFee).sub(fees.royaltyFee);
        fees.price = price;
        return (royaltyFeeReceiver, fees);
    }

    /**
     * @notice Calculates fees of an operation from the paymentAmount and to whom we should distribute it too
     *
     * @param paymentAmt Amount that the user sent(NOT the price, it is the price + buyer fee)
     * @param buyingAssetAddress the token symbol
     * @param tokenId Token id of the token being sold
     * @param sellerFeePermille Seller fee in Permille(unit per thousand of the total)
     * @param buyerFeePermille Buyer fee in Permille(unit per thousand of the total)
     * @param seller Address of the seller
     */
    function getFees(
        uint256 paymentAmt,
        address buyingAssetAddress,
        uint256 tokenId,
        uint256 sellerFeePermille,
        uint256 buyerFeePermille,
        address seller
    ) internal view virtual returns (FeeDistributionData memory) {
        (address royaltyFeesReceiver, Fees memory fees) =
            calculateFees(paymentAmt, buyingAssetAddress, tokenId, sellerFeePermille, buyerFeePermille);
        uint256 toRightsHolder = 0;
        uint256 toSeller = 0;
        bool isPrimarySale;

        try IRoyaltyAwareNFT(buyingAssetAddress).getCreator(tokenId) returns (address creator) {
            isPrimarySale = creator == seller;
        } catch {
            // We are not sure as this is probably an external token, we would take the safe path here
            isPrimarySale = false;
        }

        if (isPrimarySale) {
            toRightsHolder = fees.royaltyFee.add(fees.assetFee);
            // seller receives 0 in this case as all of it is split using the rightsHolder
        } else {
            toSeller = fees.assetFee;
            toRightsHolder = fees.royaltyFee; // This might be 0
        }

        return
            FeeDistributionData({
                toRightsHolder: toRightsHolder,
                toSeller: toSeller,
                rightsHolder: royaltyFeesReceiver,
                fees: fees
            });
    }

    function getFees(
        uint256 paymentAmt,
        address buyingAssetAddress,
        uint256 tokenId,
        address seller,
        PlatformFees calldata platformFees
    ) internal returns (FeeDistributionData memory) {
        require(tokenId == platformFees.tokenId, "TokenId mismatch");
        require(buyingAssetAddress == platformFees.assetAddress, "Asset address mismatch");
        PlatformFeesFunctions.checkValidPlatformFees(platformFees, owner());

        return
            getFees(
                paymentAmt,
                buyingAssetAddress,
                tokenId,
                platformFees.sellerFeePermille,
                platformFees.buyerFeePermille,
                seller
            );
    }

    function tradeNFT(Order memory order) internal virtual {
        safeTransferFrom(order.nftType, order.seller, order.buyer, order.nftAddress, order.tokenId, order.qty);
    }

    function safeTransferFrom(
        AssetType nftType,
        address from,
        address to,
        address nftAddress,
        uint256 tokenId,
        uint256 qty
    ) internal virtual {
        nftType == AssetType.ERC721
            ? transferProxy.erc721safeTransferFrom(nftAddress, from, to, tokenId)
            : transferProxy.erc1155safeTransferFrom(nftAddress, from, to, tokenId, qty, "");
    }

    /**
     * @dev Disable slither warning because there is a nonReentrant check and the address are known
     * https://github.com/crytic/slither/wiki/Detector-Documentation#functions-that-send-ether-to-arbitrary-destinations
     */
    function tradeAssetWithETH(Order memory order, FeeDistributionData memory feeDistributionData) internal virtual {
        tradeNFT(order);
        if (feeDistributionData.fees.platformFee > 0) {
            // TODO: review if we don't need a new field for collecting fees
            // slither-disable-next-line arbitrary-send
            (bool platformSuccess, ) = owner().call{ value: feeDistributionData.fees.platformFee }("");
            require(platformSuccess, "sending ETH to owner failed");
        }

        if (feeDistributionData.toRightsHolder > 0) {
            // TODO: can we trust this new address? don't we need some reentrancy checksor something else?
            // slither-disable-next-line arbitrary-send
            (bool royaltySuccess, ) =
                feeDistributionData.rightsHolder.call{ value: feeDistributionData.toRightsHolder }("");
            require(royaltySuccess, "sending ETH to creator failed");
        }

        if (feeDistributionData.toSeller > 0) {
            // TODO: can we trust this new address? don't we need some reentrancy checksor something else?
            // slither-disable-next-line arbitrary-send
            (bool sellerSuccess, ) = order.seller.call{ value: feeDistributionData.toSeller }("");
            require(sellerSuccess, "sending ETH to seller failed");
        }
    }

    /*********************
     ** PUBLIC FUNCTIONS *
     *********************/

    function buyAssetWithETH(
        Order memory order,
        Signature memory signature,
        PlatformFees calldata platformFees
    ) public payable nonReentrant returns (bool) {
        require(order.amount == msg.value, "Paid invalid ETH amount");
        FeeDistributionData memory feeDistributionData =
            getFees(order.amount, order.nftAddress, order.tokenId, order.seller, platformFees);
        require((feeDistributionData.fees.price >= order.unitPrice * order.qty), "Paid invalid amount");
        // Using the one sent here saves some checks as we need to make sure the same seller fees
        // where included in both singatures, no need for an extra param or assertion
        verifySellerSignature(
            order.seller,
            order.tokenId,
            order.unitPrice,
            address(0),
            order.nftAddress,
            platformFees.sellerFeePermille,
            signature
        );
        order.buyer = msg.sender;
        emit BuyAsset(order.seller, order.tokenId, order.qty, msg.sender);
        tradeAssetWithETH(order, feeDistributionData);
        return true;
    }

    /**
     * @notice Verifies and executes a safe Token withdraw for this sender, if authorized by the custodial
     * @param wr struct with the withdraw information. What asset and how much of it
     * @param signature asset custodial authorization signature
     */
    function withdrawToken(WithdrawRequest memory wr, Signature memory signature) external returns (bool) {
        address assetOwner = msg.sender;
        require(
            !AuthorizationBitmap.isAuthProcessed(processedAuthorizationsBitMap, wr.authId),
            "Authorization signature already processed"
        );
        // Verifies that this asset custodial, is actually authorizing this user withdraw
        verifyWithdrawSignature(custodialAddress, assetOwner, wr, signature);
        AuthorizationBitmap.setAuthProcessed(processedAuthorizationsBitMap, wr.authId);
        safeTransferFrom(wr.assetType, custodialAddress, assetOwner, wr.assetAddress, wr.tokenId, wr.qty);
        emit TokenWithdraw(assetOwner, wr.authId, wr.tokenId, wr.qty);
        return true;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[1000] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

pragma solidity >=0.6.0 <0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.7.6;

/// @dev Taken from https://github.com/f8n/fnd-protocol/tree/v2.0.3

/**
 * @title An abstraction layer for auctions.
 * @dev This contract can be expanded with reusable calls and data as more auction types are added.
 */
abstract contract NFTMarketAuction {
    /**
     * @dev A global id for auctions of any type.
     */
    uint256 private nextAuctionId;

    /**
     * @notice Called once to configure the contract after the initial proxy deployment.
     * @dev This sets the initial auction id to 1, making the first auction cheaper
     * and id 0 represents no auction found.
     */
    function _initializeNFTMarketAuction() internal {
        nextAuctionId = 1;
    }

    /**
     * @notice Returns id to assign to the next auction.
     */
    function _getNextAndIncrementAuctionId() internal returns (uint256) {
        // AuctionId cannot overflow 256 bits.
        return nextAuctionId++;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[1000] private __gap;
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.7.6;

/// @dev Taken from https://github.com/f8n/fnd-protocol/tree/v2.0.3

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "./TradeV4.sol";

/**
 * @title A place for common modifiers and functions used by various NFTMarket mixins, if any.
 * @dev This also leaves a gap which can be used to add a new mixin to the top of the inheritance tree.
 */
abstract contract NFTMarketCore is OwnableUpgradeable {
    using SafeMathUpgradeable for uint256;

    /// @notice Emitted when owner has updated the minIncrementPermille
    event MinIncrementPermilleUpdated(uint16 prevValue, uint16 newValue);

    /// @dev The minimum required when making an offer or placing a bid. Ej: 100 => 0.1 => 10%
    uint16 public minIncrementPermille;

    /**
     * @param _minIncrementPermille The increment to outbid. Ej: 100 => 0.1 => 10%
     */
    function _initializeNFTMarketCore(uint16 _minIncrementPermille) internal {
        minIncrementPermille = _minIncrementPermille;
    }

    function setMinIncrementPermille(uint16 _minIncrementPermille) external onlyOwner {
        emit MinIncrementPermilleUpdated(minIncrementPermille, _minIncrementPermille);
        minIncrementPermille = _minIncrementPermille;
    }

    /**
     * @notice Transfers the NFT from escrow and clears any state tracking this escrowed NFT.
     */
    function _transferFromEscrow(
        address nftContract,
        uint256 tokenId,
        address recipient
    ) internal virtual;

    /**
     * @notice Transfers an NFT into escrow
     */
    function _transferToEscrow(address nftContract, uint256 tokenId) internal virtual;

    /**
     * @notice Applies fees and distributes funds for a finalized market operation.
     * For all creator, platforma and seller.
     * @param nftContract The address of the NFT contract.
     * @param tokenId The id of the NFT.
     * @param amount Reserve price, plus buyerFee.
     * @param seller The address of the seller.
     * @return platformFee Platform share total from the sale, both taken from the buyer and seller
     * @return royaltyFee Rayalty fee distributed to owner/s
     * @return assetFee Total received bu the saller
     */
    function _distFunds(
        address nftContract,
        uint256 tokenId,
        uint256 amount,
        address payable seller,
        uint256 sellerFeesPerMille,
        uint256 buyerFeesPerMille
    )
        internal
        virtual
        returns (
            uint256 platformFee,
            uint256 royaltyFee,
            uint256 assetFee
        );

    /**
     * @notice For a given price and fee, it returns the total amount a buyer must provide to cover for both
     * @param _price the target price
     * @param _buyerFeePermille the fee taken from the buyer, expressed in *1000 (ej: 10% = 0.1 => 100)
     * @return amount the buyer must sent to comply to this price and fees
     */
    function applyBuyerFee(uint256 _price, uint8 _buyerFeePermille) internal pure returns (uint256 amount) {
        if (_buyerFeePermille == 0) {
            amount = _price;
        } else {
            amount = _price.add(_price.mul(_buyerFeePermille).div(1000));
        }
    }

    /**
     * @dev Determines the minimum amount when increasing an existing offer or bid.
     */
    function _getMinIncrement(uint256 currentAmount) internal view returns (uint256) {
        uint256 minIncrement = currentAmount.mul(minIncrementPermille).div(1000);
        if (minIncrement == 0) {
            // Since minIncrement reduces from the currentAmount, this cannot overflow.
            // The next amount must be at least 1 wei greater than the current.
            return currentAmount + 1;
        }

        return minIncrement + currentAmount;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[1000] private __gap;
}

// SPDX-License-Identifier: MIT OR Apache-2.0

/// @dev Taken from https://github.com/f8n/fnd-protocol/tree/v2.0.3

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

pragma solidity ^0.7.6;

/**
 * @title A mixin for sending ETH with a fallback withdraw mechanism.
 * @notice Attempt to send ETH and if the transfer fails or runs out of gas, store the balance
 * in the pendingWithdrawals for future withdrawal instead.
 */
abstract contract SendValueWithFallbackWithdraw is OwnableUpgradeable {
    /// @dev Tracks the amount of ETH that is stored in escrow for future withdrawal.
    mapping(address => uint256) internal pendingWithdrawals;

    /**
     * @notice Emitted when escrowed funds are withdrawn.
     * @param executor The account which has withdrawn ETH, either the owner or an Admin.
     * @param owner The owner whose ETH has been withdrawn from.
     * @param recipient The address where the funds were transfered to.
     * @param amount The amount of ETH which has been withdrawn.
     */
    event PendingWithdrawalCompleted(
        address indexed executor,
        address indexed owner,
        address recipient,
        uint256 amount
    );

    /**
     * @notice Emitted when escrowed funds are deposite into pending Withdrawals.
     * @param owner The owner whose ETH has been deposit.
     * @param amount The amount of ETH which has been deposit.
     */
    event PendingWithdrawalDeposit(address indexed owner, uint256 amount);

    /**
     * @dev Attempt to send a user or contract ETH and
     * if it fails store the amount owned for later withdrawal .
     *  @dev This function doesn't check for reentrancy issues so be careful when invoking
     */
    function _sendValueWithFallbackWithdraw(
        address payable user,
        uint256 amount,
        uint256 gasLimit
    ) internal {
        if (amount == 0) {
            return;
        }
        // Cap the gas to prevent consuming all available gas to block a tx from completing successfully
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = user.call{ value: amount, gas: gasLimit }("");
        if (!success) {
            // Store the funds that failed to send for the user pendingWithdrawals list
            pendingWithdrawals[user] += amount;
            emit PendingWithdrawalDeposit(user, amount);
        }
    }

    function _withdrawTo(address from, address payable recipient) internal {
        uint256 pendingAmount = pendingWithdrawals[from];
        if (pendingAmount != 0) {
            // No reentray is possible
            pendingWithdrawals[from] = 0;
            (bool success, ) = recipient.call{ value: pendingAmount }("");
            require(success, "withdrawal failed");
            emit PendingWithdrawalCompleted(msg.sender, from, recipient, pendingAmount);
        }
    }

    /**
     * @notice Allows owner to widthawl pending funds (on failed sale send).
     * @param recipient The address to sent the locked funds to.
     */
    function withdrawTo(address payable recipient) public {
        _withdrawTo(msg.sender, recipient);
    }

    /**
     * @notice Allows Enigma to widthawl pending funds (on failed sale send) on behalf of a user.
     * This should only be used for extreme cases when the user has prove unintended funds locked up.
     * @param fundsOwner The user address holding the pending funds.
     * @param recipient The address to sent the locked funds to.
     */
    function adminWithdrawTo(address fundsOwner, address payable recipient) external onlyOwner {
        _withdrawTo(fundsOwner, recipient);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[500] private __gap;
}

// SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "../../utils/Types.sol";
import "../../utils/BlockchainUtils.sol";

struct PlatformFees {
    address assetAddress;
    uint256 tokenId;
    uint8 buyerFeePermille;
    uint8 sellerFeePermille;
    Signature signature;
}

library PlatformFeesFunctions {
    function checkValidPlatformFees(PlatformFees calldata platformFees, address owner) internal pure {
        bytes32 hash =
            keccak256(
                abi.encodePacked(
                    BlockchainUtils.getChainID(),
                    platformFees.assetAddress,
                    platformFees.tokenId,
                    platformFees.buyerFeePermille,
                    platformFees.sellerFeePermille
                )
            );
        require(owner == BlockchainUtils.getSigner(hash, platformFees.signature), "fees sign verification failed");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";
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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

// SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.7.6;

/**
 * @dev This implementation is similar to the OZ one but due to the fact we are using an old version
 *			we weren't able to import it.
 */
library AuthorizationBitmap {
    struct Bitmap {
        mapping(uint256 => uint256) map_;
    }

    function isAuthProcessed(Bitmap storage bitmap, uint256 index) internal view returns (bool) {
        return isAuthProcessed(bitmap.map_, index);
    }

    function setAuthProcessed(Bitmap storage bitmap, uint256 index) internal {
        setAuthProcessed(bitmap.map_, index);
    }

    /**
     * @notice Verifies if this authorization index has already been processed
     * @param _index of the Authorization signature you want to know it's been processed
     */
    function isAuthProcessed(mapping(uint256 => uint256) storage _map, uint256 _index) internal view returns (bool) {
        uint256 wordIndex = _index / 256;
        uint256 bitIndex = _index % 256;
        uint256 processedWord = _map[wordIndex];
        uint256 mask = (1 << bitIndex);
        return processedWord & mask == mask;
    }

    /**
     * @notice Sets this authorization index as processed
     * @param _index of the Authorization signature you want to mark as processed
     */
    function setAuthProcessed(mapping(uint256 => uint256) storage _map, uint256 _index) internal {
        uint256 wordIndex = _index / 256;
        uint256 bitIndex = _index % 256;
        _map[wordIndex] = _map[wordIndex] | (1 << bitIndex);
    }
}

// SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

/* An ECDSA signature. */
struct Signature {
    uint8 v;
    bytes32 r;
    bytes32 s;
}

// SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "./IERC2981.sol";

interface IRoyaltyAwareNFT is IERC2981 {
    /**
     * @notice Get the creator of given tokenID.
     * @param tokenId ID of the Token.
     * @return creator of given ID.
     */
    function getCreator(uint256 tokenId) external view virtual returns (address);

    /**
     * @notice Get the rights holder (the one to receive royalties) of given tokenID.
     * @param tokenId ID of the Token.
     * @return rights holder of given ID.
     */
    function rightsHolder(uint256 tokenId) external view virtual returns (address);

    /**
     * @notice Updates the rights holder for a specific tokenId
     * @param tokenId ID of the Token.
     * @param newRightsHolder new rights holderof given ID.
     * @dev Rights holder should only be set by the token creator
     */
    function setRightsHolder(uint256 tokenId, address newRightsHolder) external virtual;

    /**
     * @notice Kind of like an initializer for the upgrade where we support ERC2981
     */
    function declareERC2981Interface() external virtual;
}

// SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.7.6;

import "./Types.sol";

library BlockchainUtils {
    // @dev When migrating to 0.8.0 ideally we should replace this by block.chainId
    function getChainID() internal pure returns (uint256) {
        uint256 id;
        //solhint-disable-next-line
        assembly {
            id := chainid()
        }
        return id;
    }

    function getSigner(bytes32 hash, Signature memory signature) internal pure returns (address) {
        return
            ecrecover(
                keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)),
                signature.v,
                signature.r,
                signature.s
            );
    }
}

// SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.7.6;

import "@openzeppelin/contracts-upgradeable/introspection/IERC165Upgradeable.sol";

///
/// @dev Interface for the NFT Royalty Standard
///
interface IERC2981 is IERC165Upgradeable {
    /// @notice Called with the sale price to determine how much royalty
    //          is owed and to whom.
    /// @param _tokenId - the NFT asset queried for royalty information
    /// @param _salePrice - the sale price of the NFT asset specified by _tokenId
    /// @return receiver - address of who should be sent the royalty payment
    /// @return royaltyAmount - the royalty payment amount for _salePrice
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        virtual
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
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