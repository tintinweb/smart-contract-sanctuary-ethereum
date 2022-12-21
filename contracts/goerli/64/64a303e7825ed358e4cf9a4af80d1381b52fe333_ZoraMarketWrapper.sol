// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.17;

/**
 * @title IMarketWrapper
 * @author Anna Carroll
 * @notice IMarketWrapper provides a common interface for
 * interacting with NFT auction markets.
 * Contracts can abstract their interactions with
 * different NFT markets using IMarketWrapper.
 * NFT markets can become compatible with any contract
 * using IMarketWrapper by deploying a MarketWrapper contract
 * that implements this interface using the logic of their Market.
 *
 * WARNING: MarketWrapper contracts should NEVER write to storage!
 * When implementing a MarketWrapper, exercise caution; a poorly implemented
 * MarketWrapper contract could permanently lose access to the NFT or user funds.
 */
interface IMarketWrapper {
    /**
     * @notice Given the auctionId, nftContract, and tokenId, check that:
     * 1. the auction ID matches the token
     * referred to by tokenId + nftContract
     * 2. the auctionId refers to an *ACTIVE* auction
     * (e.g. an auction that will accept bids)
     * within this market contract
     * 3. any additional validation to ensure that
     * a PartyBid can bid on this auction
     * (ex: if the market allows arbitrary bidding currencies,
     * check that the auction currency is ETH)
     * Note: This function probably should have been named "isValidAuction"
     * @dev Called in PartyBid.sol in `initialize` at line 174
     * @return TRUE if the auction is valid
     */
    function auctionIdMatchesToken(
        uint256 auctionId,
        address nftContract,
        uint256 tokenId
    ) external view returns (bool);

    /**
     * @notice Calculate the minimum next bid for this auction.
     * PartyBid contracts always submit the minimum possible
     * bid that will be accepted by the Market contract.
     * usually, this is either the reserve price (if there are no bids)
     * or a certain percentage increase above the current highest bid
     * @dev Called in PartyBid.sol in `bid` at line 251
     * @return minimum bid amount
     */
    function getMinimumBid(uint256 auctionId) external view returns (uint256);

    /**
     * @notice Query the current highest bidder for this auction
     * It is assumed that there is always 1 winning highest bidder for an auction
     * This is used to ensure that PartyBid cannot outbid itself if it is already winning
     * @dev Called in PartyBid.sol in `bid` at line 241
     * @return highest bidder
     */
    function getCurrentHighestBidder(uint256 auctionId) external view returns (address);

    /**
     * @notice Submit bid to Market contract
     * @dev Called in PartyBid.sol in `bid` at line 259
     */
    function bid(uint256 auctionId, uint256 bidAmount) external;

    /**
     * @notice Determine whether the auction has been finalized
     * Used to check if it is still possible to bid
     * And to determine whether the PartyBid should finalize the auction
     * @dev Called in PartyBid.sol in `bid` at line 247
     * @dev and in `finalize` at line 288
     * @return TRUE if the auction has been finalized
     */
    function isFinalized(uint256 auctionId) external view returns (bool);

    /**
     * @notice Finalize the results of the auction
     * on the Market contract
     * It is assumed  that this operation is performed once for each auction,
     * that after it is done the auction is over and the NFT has been
     * transferred to the auction winner.
     * @dev Called in PartyBid.sol in `finalize` at line 289
     */
    function finalize(uint256 auctionId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// ============ External Imports ============
import { IZoraAuctionHouse } from "../vendor/markets/IZoraAuctionHouse.sol";

// ============ Internal Imports ============
import { IMarketWrapper } from "./IMarketWrapper.sol";
import "../tokens/IERC721.sol";
import "../tokens/IERC20.sol";

/**
 * @title ZoraMarketWrapper
 * @author Anna Carroll
 * @notice MarketWrapper contract implementing IMarketWrapper interface
 * according to the logic of Zora's Auction Houses
 * Original Zora Auction House code: https://github.com/ourzora/auction-house/blob/main/contracts/AuctionHouse.sol
 */
contract ZoraMarketWrapper is IMarketWrapper {
    // ============ Internal Immutables ============

    IZoraAuctionHouse internal immutable market;
    uint8 internal immutable minBidIncrementPercentage;

    // ======== Constructor =========

    constructor(address _zoraAuctionHouse) {
        market = IZoraAuctionHouse(_zoraAuctionHouse);
        minBidIncrementPercentage = IZoraAuctionHouse(_zoraAuctionHouse).minBidIncrementPercentage();
    }

    // ======== External Functions =========

    /**
     * @notice Determine whether there is an existing auction
     * for this token on the market
     * @return TRUE if the auction exists
     */
    function auctionExists(uint256 auctionId) public view returns (bool) {
        // line 375 of Zora Auction House, _exists() function (not exposed publicly)
        IZoraAuctionHouse.Auction memory _auction = market.auctions(auctionId);
        return _auction.tokenOwner != address(0);
    }

    /**
     * @notice Determine whether the given auctionId is
     * an auction for the tokenId + nftContract
     * @return TRUE if the auctionId matches the tokenId + nftContract
     */
    function auctionIdMatchesToken(
        uint256 auctionId,
        address nftContract,
        uint256 tokenId
    ) public view override returns (bool) {
        IZoraAuctionHouse.Auction memory _auction = market.auctions(auctionId);
        return
            _auction.tokenId == tokenId &&
            _auction.tokenContract == IERC721(nftContract) &&
            _auction.auctionCurrency == IERC20(address(0));
    }

    /**
     * @notice Calculate the minimum next bid for this auction
     * @return minimum bid amount
     */
    function getMinimumBid(uint256 auctionId) external view override returns (uint256) {
        // line 173 of Zora Auction House, calculation within createBid() function (calculation not exposed publicly)
        IZoraAuctionHouse.Auction memory _auction = market.auctions(auctionId);
        if (_auction.bidder == address(0)) {
            // if there are NO bids, the minimum bid is the reserve price
            return _auction.reservePrice;
        } else {
            // if there ARE bids, the minimum bid is the current bid plus the increment buffer
            return _auction.amount + ((_auction.amount * minBidIncrementPercentage) / 100);
        }
    }

    /**
     * @notice Query the current highest bidder for this auction
     * @return highest bidder
     */
    function getCurrentHighestBidder(uint256 auctionId) external view override returns (address) {
        // line 279 of NFTMarketReserveAuction, getMinBidAmount() function
        IZoraAuctionHouse.Auction memory _auction = market.auctions(auctionId);
        return _auction.bidder;
    }

    /**
     * @notice Submit bid to Market contract
     */
    function bid(uint256 auctionId, uint256 bidAmount) external override {
        // line 153 of Zora Auction House, createBid() function
        (bool success, bytes memory returnData) = address(market).call{ value: bidAmount }(
            abi.encodeWithSignature("createBid(uint256,uint256)", auctionId, bidAmount)
        );
        require(success, string(returnData));
    }

    /**
     * @notice Determine whether the auction has been finalized
     * @return TRUE if the auction has been finalized
     */
    function isFinalized(uint256 auctionId) external view override returns (bool) {
        // line 302 of Zora Auction House,
        // the auction is deleted at the end of the endAuction() function
        // since we checked that the auction DID exist when we deployed the partyBid,
        // if it no longer exists that means the auction has been finalized.
        return !auctionExists(auctionId);
    }

    /**
     * @notice Finalize the results of the auction
     */
    function finalize(uint256 auctionId) external override {
        // line 249 of Zora Auction House, endAuction() function
        market.endAuction(auctionId);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8;

// Minimal ERC20 interface.
interface IERC20 {
    event Transfer(address indexed owner, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 allowance);

    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(address from, address to, uint256 amount) external returns (bool);

    function approve(address spender, uint256 allowance) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8;

// Minimal ERC721 interface.
interface IERC721 {
    event Transfer(address indexed owner, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed operator, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function transferFrom(address from, address to, uint256 tokenId) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    function approve(address operator, uint256 tokenId) external;

    function setApprovalForAll(address operator, bool isApproved) external;

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function getApproved(uint256 tokenId) external view returns (address);

    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function ownerOf(uint256 tokenId) external view returns (address);

    function balanceOf(address owner) external view returns (uint256);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8;

import "../../tokens/IERC721.sol";
import "../../tokens/IERC20.sol";

// Based on https://etherscan.io/address/0xe468ce99444174bd3bbbed09209577d25d1ad673#code
interface IZoraAuctionHouse {
    struct Auction {
        // ID for the ERC721 token
        uint256 tokenId;
        // Address for the ERC721 contract
        IERC721 tokenContract;
        // Whether or not the auction curator has approved the auction to start
        bool approved;
        // The current highest bid amount
        uint256 amount;
        // The length of time to run the auction for, after the first bid was made
        uint256 duration;
        // The time of the first bid
        uint256 firstBidTime;
        // The minimum price of the first bid
        uint256 reservePrice;
        // The sale percentage to send to the curator
        uint8 curatorFeePercentage;
        // The address that should receive the funds once the NFT is sold.
        address tokenOwner;
        // The address of the current highest bid
        address payable bidder;
        // The address of the auction's curator.
        // The curator can reject or approve an auction
        address payable curator;
        // The address of the ERC-20 currency to run the auction with.
        // If set to 0x0, the auction will be run in ETH
        IERC20 auctionCurrency;
    }

    event AuctionCreated(
        uint256 indexed auctionId,
        uint256 indexed tokenId,
        address indexed tokenContract,
        uint256 duration,
        uint256 reservePrice,
        address tokenOwner,
        address curator,
        uint8 curatorFeePercentage,
        address auctionCurrency
    );

    function createAuction(
        uint256 tokenId,
        IERC721 tokenContract,
        uint256 duration,
        uint256 reservePrice,
        address payable curator,
        uint8 curatorFeePercentages,
        IERC20 auctionCurrency
    ) external returns (uint256);

    function createBid(uint256 auctionId, uint256 amount) external payable;

    function endAuction(uint256 auctionId) external;

    function cancelAuction(uint256 auctionId) external;

    function auctions(uint256 auctionId) external view returns (Auction memory auction);

    function timeBuffer() external view returns (uint256);

    function minBidIncrementPercentage() external view returns (uint8);
}