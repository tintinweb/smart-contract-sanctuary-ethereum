// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import {IERC721, IERC165} from "../../openzeppelin/token/ERC721/IERC721.sol";
import {IERC1155} from "../../openzeppelin/token/ERC1155/IERC1155.sol";
import {ReentrancyGuard} from "../../openzeppelin/security/ReentrancyGuard.sol";
import {IERC20} from "../../openzeppelin/token/ERC20/IERC20.sol";
import {SafeERC20} from "../../openzeppelin/token/ERC20/utils/SafeERC20.sol";
import {ICreatorCore} from "../../manifold/creator-core/core/ICreatorCore.sol";
import {AdminControl} from "../../manifold/libraries-solidity/access/AdminControl.sol";
import {MerkleProof} from "../../openzeppelin/utils/cryptography/MerkleProof.sol";
import {Address} from "../../openzeppelin/utils/Address.sol";
import {ECDSA} from "../../openzeppelin/utils/cryptography/ECDSA.sol";
import "../../mojito/interfaces/IRoyaltyEngine.sol";

/**
 * @title onchainAuction, enabling collectors and curators to run their own auctions
 */

contract onchainAuction is ReentrancyGuard, AdminControl {
    using SafeERC20 for IERC20;
    using ECDSA for bytes32;

    /// @notice The metadata for a given Order
    /// @param nftContractAddress the nft contract address
    /// @param tokenId the Nft token Id
    /// @param quantityOf1155 the quantity of 1155 for auction
    /// @param tokenOwnerAddress the address of the nft owner of the auction
    /// @param mimimumCryptoPrice the mimimum price of the crypto in
    /// @param paymentCurrency the payment currency for seller requirement
    /// @param whitelistedBuyers the root hash of the list of whitelisted address
    /// @param blacklistedBuyers the root hash of the list of blackisted address
    /// @param paymentSettlement the settlement address and payment percentage provided in basis points
    struct createAuctionList {
        address nftContractAddress;
        uint256 tokenId;
        uint256 quantityOf1155;
        address tokenOwnerAddress;
        uint256 minimumBidCryptoPrice;
        uint256 ReservedPrice;
        address paymentCurrency; // cant support multiple currency here
        bytes32 whitelistedBuyers;
        bytes32 blacklistedBuyers;
        settlementList paymentSettlement;
    }

    /// @notice The metadata for a given Order
    /// @param paymentSettlementAddress the settlement address for the listed tokens
    /// @param taxSettlementAddress the taxsettlement address for settlement of tax fee
    /// @param platformSettlementAddress the platform address for settlement of platform fee
    /// @param platformFeePercentage the platform fee given in basis points
    /// @param commissionAddress the commission address for settlement of commission fee
    /// @param commissionFeePercentage the commission fee given in basis points
    struct settlementList {
        address paymentSettlementAddress;
        address taxSettlementAddress;
        address commissionAddress;
        address platformSettlementAddress;
        uint16 commissionFeePercentage; // in basis points
        uint16 platformFeePercentage; // in basis points
    }

    // Interface ID constants
    bytes4 private constant ERC721_INTERFACE_ID = 0x80ac58cd;
    bytes4 private constant ERC1155_INTERFACE_ID = 0xd9b67a26;

    // Platform Address
    address payable platformAddress;

    // Fee percentage to the Platform
    uint16 platformFeePercentage;

    // The address of the royaltySupport to use via this contract
    IRoyaltyEngine public royaltySupport;

    /// @notice the bid history of tokenId
    /// @param startTime the time when the bid starts
    /// @param endTime the time when the bid ends
    /// @param bidder the address of the last three bidder
    /// @param amount the bid amount of the last three bidder
    struct bidHistory {
        uint256 startTime;
        uint256 endTime;
        address highestBidder;
        uint256 highestBid;
        uint256 tax;
    }

    /// @notice The Bidding List for a Token
    /// @param highestBidder Address of the Bidder
    /// @param highestBid Price quote by them
    struct BidList {
        address highestBidder;
        uint256 highestBid;
    }

    uint256 durationForCheck;
    uint256 durationToIncrease;

    // listing the auction details in the string named auction Id
    mapping(string => createAuctionList) public listings;

    // listing auctionId to tokenId to get the bidHistory for each tokens seperately.
    mapping(string => bidHistory) public bidderDetails;

    // validating saleId
    mapping(string => bool) public usedAuctionId;

    // @notice Emitted when an auction cration is completed
    //  @param createdDetails the details of the created auction
    event AuctionCreated(
        string indexed auctionId,
        createAuctionList indexed createdDetails,
        uint256 startTime,
        uint256 endTime);
    // @notice Emitted when an auction bid is completed
    // @param auctionId the id of the created auction
    // @param tokenId the tokenId for which bid is made
    // @param bidder the address of the bidder
    // @param bidAmount the amount of the bid
    event AuctionBid(
        string indexed auctionId,
        address indexed bidder,
        uint256 indexed bidAmount
    );
    // @notice Emitted when an auction is ended
    // @param auctionId the id of the created auction
    // @param tokenId the tokenId of the nft
    // @param createdDetails the details of the auction
    // @param AuctionHistory the history of the auction
    event AuctionEnded(
        string indexed auctionId,
        createAuctionList createdDetails,
        bidHistory AuctionHistory
    );
    // @notice Emitted when an auction is closed
    // @param auctionId the id of the created auction
    event CancellAuction(string indexed auctionId);

    /// @notice Emitted when an Royalty Payout is executed
    /// @param tokenId The NFT tokenId
    /// @param tokenContract The NFT Contract address
    /// @param recipient Address of the Royalty Recipient
    /// @param amount Amount sent to the royalty recipient address
    event RoyaltyPayout(
        address tokenContract,
        uint256 tokenId,
        address recipient,
        uint256 amount
    );
    
    // @notice Emitted when an end Time of auction is Extended automatically
    // @param auctionId the id of the created auction
    // @param oldEndTime the old end time of the created auction
    // @param newEndTime the extended end time of the created auction
    event endTimeExtended(
        string indexed auctionId,
        uint256 indexed oldEndTime,
        uint256 indexed newEndTime
    );
       
    // @notice Emitted when minimumPrice is Updated
    // @param auctionId the id of the created auction
    // @param oldMinimumBidPrice the old MinimumBidPrice of the created auction
    // @param newMinimumBidPrice the new MinimumBidPrice of the created auction
    event minimumPriceUpdated(
        string indexed auctionId,
        uint256 indexed oldMinimumBidPrice,
        uint256 indexed newMinimumBidPrice
    );

    // @notice Emitted when startTime is Updated
    // @param auctionId the id of the created auction
    // @param oldStartTime the old start time of the created auction
    // @param newStartTime the new start time of the created auction
    event startTimeUpdated(
        string indexed auctionId,
        uint256 indexed oldStartTime,
        uint256 indexed newStartTime
    );
    
    // @notice Emitted when an end Time of auction is updated
    // @param auctionId the id of the created auction
    // @param oldEndTime the old end time of the created auction
    // @param newEndTime the new end time of the created auction
    event endTimeUpdated(
        string indexed auctionId,
        uint256 indexed oldEndTime,
        uint256 indexed newEndTime
    );

    // @notice Emitted when paymentSettlementAddress is Updated
    // @param auctionId the id of the created auction
    // @param oldPaymentSettlementAddress the old PaymentSettlementAddress of the created auction
    // @param newPaymentSettlementAddress the new PaymentSettlementAddress of the created auction
    event paymentSettlementAddressUpdated(
        string indexed auctionId,
        address indexed oldPaymentSettlementAddress,
        address indexed newPaymentSettlementAddress
    );
    
    // @notice Emitted when taxSettlementAddress is Updated
    // @param auctionId the id of the created auction
    // @param oldTaxSettlementAddress the old TaxSettlementAddress of the created auction
    // @param newTaxSettlementAddress the new TaxSettlementAddress of the created auction
    event taxSettlementAddressUpdated(
        string indexed auctionId,
        address indexed oldTaxSettlementAddress,
        address indexed newTaxSettlementAddress
    );
    
    // @notice Emitted when platformAddress is Updated at contract Level
    // @param oldPlatformAddress the old PlatformAddress of the created auction
    // @param newPlatformAddress the new PlatformAddress of the created auction
    event platformAddressUpdated(
        address indexed oldPlatformAddress,
        address indexed newPlatformAddress
    );
    
    // @notice Emitted when platformFeePercentage is Updated at contract Level
    // @param oldPlatformFeePercentage the old platformFeePercentage of the created auction
    // @param newPlatformFeePercentage the new platformFeePercentage of the created auction
    event platformFeePercentageUpdated(
        uint16 indexed oldPlatformFeePercentage,
        uint16 indexed newPlatformFeePercentage
    );

    // @notice Emitted when an AutoTimeExtensionValues are Updated
    // @param oldDurationForCheck the old Time period to check if nearing to end
    // @param oldDurationToIncrease the old Time Extension of end time
    // @param newDurationForCheck the new Time period to check if nearing to end
    // @param newDurationToIncrease the new Time Extension of end time
        event AutoTimeExtensionUpdated(
        uint256 oldDurationForCheck,
        uint256 newDurationForCheck,
        uint256 oldDurationToIncrease,
        uint256 newDurationToIncrease
    );
    
    // @notice Emitted when withdrawn is called by admin
    // @param to the To address
    // @param amount the amount transferred from contract
    // @param paymentCurrency the type of transfer (ETH OR ERC20)
    event withdrew(address indexed to,uint256 amount,address paymentCurrency);

    /// @param _platformAddress The Platform Address
    /// @param _platformFeePercentage The Platform fee percentage
    /// @param _royaltySupport The address of RoyaltyEngine
    /// @param _durationForCheck the Time period to check if nearing to end
    /// @param _durationToIncrease the Time Extension of end time
    constructor(
        address _platformAddress,
        uint16 _platformFeePercentage,
        IRoyaltyEngine _royaltySupport,
        uint256 _durationForCheck,
        uint256 _durationToIncrease) {
        require(_platformAddress != address(0), "Invalid Platform Address");
        require(
            _platformFeePercentage < 10000,
            "platformFee should not be more than 100 %"
        );

       require(_durationForCheck > 0 && _durationToIncrease > 0, "Invalid Time Data");
       durationForCheck = _durationForCheck;
       durationToIncrease = _durationToIncrease;

        platformAddress = payable(_platformAddress);
        platformFeePercentage = _platformFeePercentage;
        royaltySupport = _royaltySupport;
    }

    /*
     * @notice creating a auction .
     * @param list gives the listing details to create a auction
     * @param auctionId consist of the id of the listed auction
     * @param startTime the starting time stamp of auction
     * @param endTime the ending time stamp of auction
     */
    function createAuction(
        string calldata auctionId,
        createAuctionList calldata list,
        uint32 startTime,
        uint32 endTime
    ) external nonReentrant {
        // checks for should not use the same auctionId
        require(!usedAuctionId[auctionId], "auctionId is already used");

        require(
            isAdmin(msg.sender) || list.tokenOwnerAddress == msg.sender,
            "Only the admin of this contract or Token owner can call this function"
        );

        uint16 totalFeeBasisPoints;
        // checks for platform and commission fee to be less than 100 %
        if (list.paymentSettlement.platformFeePercentage != 0) {
            totalFeeBasisPoints += (list
                .paymentSettlement
                .platformFeePercentage +
                list.paymentSettlement.commissionFeePercentage);
        } else {
            totalFeeBasisPoints += (platformFeePercentage +
                list.paymentSettlement.commissionFeePercentage);
        }
        require(
            totalFeeBasisPoints < 10000,
            "The total fee basis point should be less than 10000"
        );
        // checks for amount to buy the token should not be provided as zero
        require(
            list.minimumBidCryptoPrice > 0,
            "minimum price should be greater than zero"
        );

        // checks to provide only supported interface for nftContractAddress
        require(
            IERC165(list.nftContractAddress).supportsInterface(
                ERC721_INTERFACE_ID
            ) ||
                IERC165(list.nftContractAddress).supportsInterface(
                    ERC1155_INTERFACE_ID
                ),
            "should provide only supported Nft Address"
        );
        if (
            IERC165(list.nftContractAddress).supportsInterface(
                ERC721_INTERFACE_ID
            )
        ) {
            require(
                IERC721(list.nftContractAddress).ownerOf(list.tokenId) ==
                    list.tokenOwnerAddress,
                "maker is not the owner"
            );
            require(
                IERC721(list.nftContractAddress).isApprovedForAll(
                    list.tokenOwnerAddress,address(this)) == true,
                    " Approval for All is not given"
            );
        } else if (
            IERC165(list.nftContractAddress).supportsInterface(
                ERC1155_INTERFACE_ID
            )
        ) {
            uint256 tokenQty = IERC1155(list.nftContractAddress).balanceOf(
                list.tokenOwnerAddress,
                list.tokenId
            );
            require(
                list.quantityOf1155 <= tokenQty && list.quantityOf1155 > 0,
                "Insufficient token balance"
            );
            require(
                IERC1155(list.nftContractAddress).isApprovedForAll(
                    list.tokenOwnerAddress,address(this)) == true,
                    " Approval for All is not given"
            );
        }

        // checks for paymentSettlementAddress should not be zero
        require(
            list.paymentSettlement.paymentSettlementAddress != address(0),
            "should provide Settlement address"
        );

        // checks to support only erc-20 and native currency
        require(
            Address.isContract(list.paymentCurrency) ||
                list.paymentCurrency == address(0),
            "Auction support only native and erc20 currency"
        );

        // checks for taxSettlementAddress should not be zero
        require(
            list.paymentSettlement.taxSettlementAddress != address(0),
            "should provide tax Settlement address"
        );

        // checks for timestamp for starttime and endtime to be greater than zero
        require(
            startTime > 0 && endTime > startTime,
            "auction time should not be provided as zero"
        );
        listings[auctionId] = list;

        bidderDetails[auctionId].startTime = startTime;

        bidderDetails[auctionId].endTime = endTime;

        usedAuctionId[auctionId] = true;

        emit AuctionCreated(
            auctionId,
            list,
            bidderDetails[auctionId].startTime,
            bidderDetails[auctionId].endTime
            );
    }

    /**
     * @notice bid, making a bid of a token in created auction
     * @param auctionId the id if the created auction
     * @param bidAmount the amount of to the bid
     * @param tax the tax amount 
     * @param whitelistedProof proof of the whiltelisted leaf
     * @param blacklistedProof proof of the blacklisted leaf
     */
    function bid(
        string calldata auctionId,
        uint256 bidAmount,
        uint256 tax,
        bytes32[] memory whitelistedProof,
        bytes32[] memory blacklistedProof
    ) external payable nonReentrant {
        // checks for auctionId is created for auction
        require(usedAuctionId[auctionId], "unsupported sale");

        createAuctionList memory listingDetails = listings[auctionId];
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        // Whitelisted address validation using Merkle Proof of caller Address
        if (listingDetails.whitelistedBuyers != bytes32(0)) {
            require(
                MerkleProof.verify(
                    whitelistedProof,
                    listingDetails.whitelistedBuyers,
                    leaf
                ),
                "bidder should be a whitelisted Buyer"
            );
        }
        // Blacklisted address validation using Merkle Proof of caller Address
        if (listingDetails.blacklistedBuyers != bytes32(0)) {
            require(
                !MerkleProof.verify(
                    blacklistedProof,
                    listingDetails.blacklistedBuyers,
                    leaf
                ),
                "you are been blacklisted from bidding"
            );
        }
        require(
            bidderDetails[auctionId].startTime <= block.timestamp,
            "the auction has not started"
        );
        require(
            bidderDetails[auctionId].endTime > block.timestamp,
            "the auction has already ended"
        );
        if (
            bidAmount >= listingDetails.minimumBidCryptoPrice &&
            bidAmount > bidderDetails[auctionId].highestBid
        ) {
            if (listingDetails.paymentCurrency != address(0)) {
                // check for enough token allowance to create offer
                require(
                    IERC20(listingDetails.paymentCurrency).allowance(msg.sender, address(this)) >=
                    (bidAmount + tax),
                "insufficent token allowance"
                );
                // checks the buyer has sufficient amount to buy the nft
                require(
                    IERC20(listingDetails.paymentCurrency).balanceOf(
                        msg.sender
                    ) >= (bidAmount + tax),
                    "insufficient Erc20 amount"
                );
            } else if (listingDetails.paymentCurrency == address(0)) {
                require(
                    msg.value >= (bidAmount + tax),
                    "insufficent Eth amount"
                );
            }
        } else {
            revert("provide bid amount higher than previous bid");
        }

        if (bidderDetails[auctionId].highestBid != 0) {
            _handlePayment(
                payable(bidderDetails[auctionId].highestBidder),
                listingDetails.paymentCurrency,
                (bidderDetails[auctionId].highestBid +
                    bidderDetails[auctionId].tax)
            );
        }

        if (listingDetails.paymentCurrency != address(0)) {
            IERC20(listingDetails.paymentCurrency).safeTransferFrom(msg.sender,address(this),(bidAmount + tax));
        }
        bidderDetails[auctionId].highestBidder = msg.sender;
        bidderDetails[auctionId].highestBid = bidAmount;
        bidderDetails[auctionId].tax = tax;
        if (bidderDetails[auctionId].endTime - durationForCheck < block.timestamp) {
            emit endTimeExtended(
                auctionId,
                bidderDetails[auctionId].endTime,
                bidderDetails[auctionId].endTime+durationToIncrease
                );
            bidderDetails[auctionId].endTime += durationToIncrease;
            }
        emit AuctionBid(auctionId, msg.sender, bidAmount);
    }

    function endAuction(string memory auctionId) external nonReentrant {
        // checks for auctionId is created for auction
        require(usedAuctionId[auctionId], "unsupported sale");

        bidHistory memory bidderdetails = bidderDetails[auctionId];
        createAuctionList memory listingDetails = listings[auctionId];
        settlementList memory paymentSettlement = listings[auctionId]
            .paymentSettlement;
        // should be called by the contract admins or by the buyer
        require(
            isAdmin(msg.sender) || bidderdetails.highestBidder == msg.sender,
            "Only the admin of this contract or HighestBidder can call this function"
        );

        // checks the auction time is ended
        require(
            block.timestamp >= bidderdetails.endTime,
            "auction has not yet ended"
        );

        uint256 bidAmount = bidderdetails.highestBid;
        address buyer = bidderdetails.highestBidder;
        address paymentToken = listingDetails.paymentCurrency;
        address tokenContract = listingDetails.nftContractAddress;
        uint256 tokenId = listingDetails.tokenId;
        if (listingDetails.ReservedPrice > bidAmount) {
            // bid doesen't meet the reserved price so we are returning the amount+tax to highest bidder
            _handlePayment(
                payable(buyer),
                paymentToken,
                (bidAmount + bidderdetails.tax)
            );
            } else if (listingDetails.ReservedPrice <= bidAmount) {
            // Transferring  the NFT tokens to the highest Bidder
            _tokenTransaction(
                listingDetails.tokenOwnerAddress,
                tokenContract,
                buyer,
                tokenId,
                listingDetails.quantityOf1155
            );

            // transferring the excess amount given by by buyer as tax to taxSettlementAddress
            if (bidderdetails.tax != 0) {
                _handlePayment(
                    payable(paymentSettlement.taxSettlementAddress),
                    paymentToken,
                    bidderdetails.tax
                );
            }

            uint256 remainingProfit = bidAmount;

            // PlatformFee Settlement
            uint256 paymentAmount;
            // transferring the platformFee amount  to the platformSettlementAddress
            if (
                paymentSettlement.platformSettlementAddress != address(0) &&
                paymentSettlement.platformFeePercentage > 0
            ) {
                _handlePayment(
                    payable(paymentSettlement.platformSettlementAddress),
                    paymentToken,
                    paymentAmount += ((remainingProfit *
                        paymentSettlement.platformFeePercentage) / 10000)
                );
            } else if (
                platformAddress != address(0) && platformFeePercentage > 0
            ) {
                _handlePayment(
                    platformAddress,
                    paymentToken,
                    paymentAmount += ((remainingProfit *
                        platformFeePercentage) / 10000)
                );
            }
           
            // transferring the commissionfee amount  to the commissionAddress
            if (
                paymentSettlement.commissionAddress != address(0) &&
                paymentSettlement.commissionFeePercentage > 0
            ) {
                paymentAmount += ((remainingProfit *
                    paymentSettlement.commissionFeePercentage) / 10000);
                _handlePayment(
                    payable(paymentSettlement.commissionAddress),
                    paymentToken,
                    ((remainingProfit *
                        paymentSettlement.commissionFeePercentage) / 10000)
                );
            }
            remainingProfit = remainingProfit - paymentAmount;
            // Royalty Fee Payout Settlement
            if(royaltySupport!=IRoyaltyEngine(address(0)))
            {
            remainingProfit = _handleRoyaltyEnginePayout(
                tokenContract,
                tokenId,
                remainingProfit,
                paymentToken
            );
            }
            // Transfer the balance to the tokenOwner
            _handlePayment(
                payable(paymentSettlement.paymentSettlementAddress),
                paymentToken,
                remainingProfit
            );

            emit AuctionEnded(
                auctionId,
                listingDetails,
                bidderdetails
            );
        delete (listings[auctionId]);
        delete (bidderDetails[auctionId]);
        }
    }
    
    /// @notice The details to be provided to buy the token
    /// @param _tokenOwner the owner of the nft token
    /// @param _tokenContract the address of the nft contract
    /// @param _buyer the address of the buyer
    /// @param _tokenId the token Id of the owner owns
    /// @param _quantity the quantity of tokens for 1155 only
    function _tokenTransaction(
        address _tokenOwner,
        address _tokenContract,
        address _buyer,
        uint256 _tokenId,
        uint256 _quantity
    ) private {
        if (IERC165(_tokenContract).supportsInterface(ERC721_INTERFACE_ID)) {
            require(
                IERC721(_tokenContract).ownerOf(_tokenId) == _tokenOwner,
                "maker is not the owner"
            );
            // Transferring the ERC721
            IERC721(_tokenContract).safeTransferFrom(
                _tokenOwner,
                _buyer,
                _tokenId
            );
        } else if (
            IERC165(_tokenContract).supportsInterface(ERC1155_INTERFACE_ID)
        ) {
            uint256 ownerBalance = IERC1155(_tokenContract).balanceOf(
                _tokenOwner,
                _tokenId
            );
            require(
                _quantity <= ownerBalance && _quantity > 0,
                "Insufficeint token balance"
            );

            // Transferring the ERC1155
            IERC1155(_tokenContract).safeTransferFrom(
                _tokenOwner,
                _buyer,
                _tokenId,
                _quantity,
                "0x"
            );
        }
    }

    /// @notice Settle the Payment based on the given parameters
    /// @param _to Address to whom need to settle the payment
    /// @param _paymentToken Address of the ERC20 Payment Token
    /// @param _amount Amount to be transferred
    function _handlePayment(
        address payable _to,
        address _paymentToken,
        uint256 _amount
    ) private {
        bool success;
        if (_paymentToken == address(0)) {
            // transferreng the native currency
            (success, ) = _to.call{value: _amount}(new bytes(0));
            require(success, "transaction failed");
        } else {
            // transferring ERC20 currency
            IERC20(_paymentToken).safeTransfer(_to, _amount);
        }
    }

    /// @notice Settle the Royalty Payment based on the given parameters
    /// @param _tokenContract The NFT Contract address
    /// @param _tokenId The NFT tokenId
    /// @param _amount Amount to be transferred
    /// @param _payoutCurrency Address of the ERC20 Payout
    function _handleRoyaltyEnginePayout(
        address _tokenContract,
        uint256 _tokenId,
        uint256 _amount,
        address _payoutCurrency
    ) private returns (uint256) {
        // Store the initial amount
        uint256 amountRemaining = _amount;
        uint256 feeAmount;

        // Verifying whether the token contract supports Royalties of supported interfaces
        (
            address payable[] memory recipients,
            uint256[] memory bps // Royalty amount denominated in basis points
        ) = royaltySupport.getRoyalty(_tokenContract, _tokenId);

        // Store the number of recipients
        uint256 totalRecipients = recipients.length;

        // If there are no royalties, return the initial amount
        if (totalRecipients == 0) return _amount;

        // Payout each royalty
        for (uint256 i = 0; i < totalRecipients; ) {
            // Cache the recipient and amount
            address payable recipient = recipients[i];

            feeAmount = (bps[i] * _amount) / 10000;

            // Ensure that we aren't somehow paying out more than we have
            require(amountRemaining >= feeAmount, "insolvent");

            _handlePayment(recipient, _payoutCurrency, feeAmount);
            emit RoyaltyPayout(_tokenContract, _tokenId, recipient, feeAmount);

            // Cannot underflow as remaining amount is ensured to be greater than or equal to royalty amount
            unchecked {
                amountRemaining -= feeAmount;
                ++i;
            }
        }
        return amountRemaining;
    }
    
    
    /// @notice cancel the sale of a listed token
    /// @param auctionId to cansel the sale
    function cancelAuction(string memory auctionId) external adminRequired {
        
        require(usedAuctionId[auctionId], "unsupported sale");
        require(
                bidderDetails[auctionId].highestBid == 0,
            "the auction bid has already started"
        );
        delete(listings[auctionId]);
        emit CancellAuction(auctionId);
    }
   
      
    /// @notice Update the MinimumPrice
    /// @param auctionId The Auction Id
    /// @param minimumBidPrice The minimumBidPrice
    function updateMinimumPrice(
        string calldata auctionId,
        uint256 minimumBidPrice
    ) external adminRequired {
        // checks for auctionId is created for auction
        require(usedAuctionId[auctionId], "unsupported sale");

        require(
                bidderDetails[auctionId].highestBid == 0,
            "the auction bid has already started"
        );
        emit minimumPriceUpdated(
            auctionId,
            listings[auctionId].minimumBidCryptoPrice,
            minimumBidPrice
            );
        listings[auctionId].minimumBidCryptoPrice = minimumBidPrice;
    }
    
    /// @notice Update the StartTime
    /// @param auctionId The Auction Id
    /// @param startTime The startTime
    function updateStartTime(string calldata auctionId, uint32 startTime)
        external
        adminRequired
    {
        // checks for auctionId is created for auction
        require(usedAuctionId[auctionId], "unsupported sale");

        require(
                bidderDetails[auctionId].highestBid == 0,
            "the auction bid has already started"
        );
        emit startTimeUpdated(auctionId,bidderDetails[auctionId].startTime,startTime);
        bidderDetails[auctionId].startTime = startTime;
    }
    
    /// @notice Update the EndTime
    /// @param auctionId The Auction Id
    /// @param endTime The endTime
    function updateEndTime(string calldata auctionId, uint32 endTime)
        external
        adminRequired
    {
        // checks for auctionId is created for auction
        require(usedAuctionId[auctionId], "unsupported sale");

        require(
            listings[auctionId].nftContractAddress!=address(0),
            "auction Closed"
        );
        require(
            bidderDetails[auctionId].endTime <= block.timestamp || 
               bidderDetails[auctionId].highestBid == 0,
            "auction has not started or not yet ended"
        );
        require(bidderDetails[auctionId].endTime < endTime, "New EndTime must be greater than old EndTIme");
        emit endTimeUpdated(auctionId,bidderDetails[auctionId].endTime,endTime);
        bidderDetails[auctionId].endTime = endTime;
    }
        
    /// @notice Update the Payment Settlement Address
    /// @param auctionId The Auction Id
    /// @param paymentSettlementAddress The Payment Settlement Address 
    function updatePaymentSettlementAddress(
        string calldata auctionId,
        address paymentSettlementAddress
    ) external adminRequired {
        // checks for auctionId is created for auction
        require(usedAuctionId[auctionId], "unsupported sale");

        require(
            bidderDetails[auctionId].startTime >= block.timestamp ||
                bidderDetails[auctionId].highestBid == 0,
            "the auction bid has already started"
        );

        require(paymentSettlementAddress != address(0));
        emit paymentSettlementAddressUpdated(
            auctionId,
            listings[auctionId].paymentSettlement.paymentSettlementAddress,
            paymentSettlementAddress
            );
        listings[auctionId]
            .paymentSettlement
            .paymentSettlementAddress = paymentSettlementAddress;
    }
    
    /// @notice Update the Tax Settlement Address
    /// @param auctionId The Auction Id
    /// @param taxSettlementAddress The TAX Settlement Address
    function updateTaxSettlementAddress(
        string calldata auctionId,
        address taxSettlementAddress
    ) external adminRequired {
        // checks for auctionId is created for auction
        require(usedAuctionId[auctionId], "unsupported sale");

        require(
            bidderDetails[auctionId].startTime >= block.timestamp ||
                bidderDetails[auctionId].highestBid == 0,
            "the auction bid has already started"
        );

        require(taxSettlementAddress != address(0));
        emit taxSettlementAddressUpdated(
            auctionId,
            listings[auctionId].paymentSettlement.taxSettlementAddress,
            taxSettlementAddress
            );
        listings[auctionId]
            .paymentSettlement
            .taxSettlementAddress = taxSettlementAddress;
    }
    
    /// @notice Update the values of AutoTimeExtension
    /// @param _durationForCheck Time period to check the nearest to end.
    /// @param _durationToIncrease  Time Extension of end time. 
    function UpdateValuesOfAutoTimeExtension(uint256 _durationForCheck, uint256 _durationToIncrease)
    external adminRequired {
        require(_durationForCheck > 0 && _durationToIncrease > 0, "Invalid Time Data");
       emit AutoTimeExtensionUpdated(durationForCheck,_durationForCheck,durationToIncrease,_durationToIncrease);
       durationForCheck = _durationForCheck;
       durationToIncrease = _durationToIncrease;
    }

    /// @notice Update the platform Address
    /// @param _platformAddress The Platform Address
    function updatePlatformAddress(address _platformAddress)
        external
        adminRequired
    {
        require(_platformAddress != address(0), "Invalid Platform Address");
        emit platformAddressUpdated(platformAddress,_platformAddress);
        platformAddress = payable(_platformAddress);
    }

    /// @notice Update the Platform Fee Percentage
    /// @param _platformFeePercentage The Platform fee percentage
    function updatePlatformFeePercentage(uint16 _platformFeePercentage)
        external
        adminRequired
    {
        require(
            _platformFeePercentage < 10000,
            "platformFee should not be more than 100 %"
        );
        emit platformFeePercentageUpdated(platformFeePercentage,_platformFeePercentage);
        platformFeePercentage = _platformFeePercentage;
       
    }
    
    /// @notice Withdraw the funds to owner
    function withdraw(address paymentCurrency) external adminRequired {
        bool success;
        address payable to = payable(msg.sender);
        if(paymentCurrency == address(0)){
            (success, ) = to.call{value: address(this).balance}(new bytes(0));
            require(success, "withdraw to withdraw funds. Please try again");
            emit withdrew(to,(payable(address(this))).balance,paymentCurrency);
        } else if (paymentCurrency != address(0)){
            // transferring ERC20 currency
            uint256 amount = IERC20(paymentCurrency).balanceOf(address(this));
            IERC20(paymentCurrency).safeTransfer(to, amount);  
            emit withdrew(to,amount,paymentCurrency);  
        }    
    }

    receive() external payable {}
    fallback() external payable {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

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
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

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
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

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
    function balanceOf(address account, uint256 id) external view returns (uint256);

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
    function isApprovedForAll(address account, address operator) external view returns (bool);

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
}

// SPDX-License-Identifier: MIT

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

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor () {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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
    function transferFrom(
        address sender,
        address recipient,
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
// OpenZeppelin Contracts v4.4.0 (token/ERC20/utils/SafeERC20.sol)

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

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "../../../openzeppelin/utils/introspection/IERC165.sol";

/**
 * @dev Core creator interface
 */
interface ICreatorCore is IERC165 {
    event ExtensionRegistered(
        address indexed extension,
        address indexed sender
    );
    event ExtensionUnregistered(
        address indexed extension,
        address indexed sender
    );
    event ExtensionBlacklisted(
        address indexed extension,
        address indexed sender
    );
    event MintPermissionsUpdated(
        address indexed extension,
        address indexed permissions,
        address indexed sender
    );
    event RoyaltiesUpdated(
        uint256 indexed tokenId,
        address payable[] receivers,
        uint256[] basisPoints
    );
    event DefaultRoyaltiesUpdated(
        address payable[] receivers,
        uint256[] basisPoints
    );
    event ExtensionRoyaltiesUpdated(
        address indexed extension,
        address payable[] receivers,
        uint256[] basisPoints
    );
    event ExtensionApproveTransferUpdated(
        address indexed extension,
        bool enabled
    );

    /**
     * @dev gets address of all extensions
     */
    function getExtensions() external view returns (address[] memory);

    /**
     * @dev add an extension.  Can only be called by contract owner or admin.
     * extension address must point to a contract implementing ICreatorExtension.
     * Returns True if newly added, False if already added.
     */
    function registerExtension(address extension, string calldata baseURI)
        external;

    /**
     * @dev add an extension.  Can only be called by contract owner or admin.
     * extension address must point to a contract implementing ICreatorExtension.
     * Returns True if newly added, False if already added.
     */
    function registerExtension(
        address extension,
        string calldata baseURI,
        bool baseURIIdentical
    ) external;

    /**
     * @dev add an extension.  Can only be called by contract owner or admin.
     * Returns True if removed, False if already removed.
     */
    function unregisterExtension(address extension) external;

    /**
     * @dev blacklist an extension.  Can only be called by contract owner or admin.
     * This function will destroy all ability to reference the metadata of any tokens created
     * by the specified extension. It will also unregister the extension if needed.
     * Returns True if removed, False if already removed.
     */
    function blacklistExtension(address extension) external;

    /**
     * @dev set the baseTokenURI of an extension.  Can only be called by extension.
     */
    function setBaseTokenURIExtension(string calldata uri) external;

    /**
     * @dev set the baseTokenURI of an extension.  Can only be called by extension.
     * For tokens with no uri configured, tokenURI will return "uri+tokenId"
     */
    function setBaseTokenURIExtension(string calldata uri, bool identical)
        external;

    /**
     * @dev set the common prefix of an extension.  Can only be called by extension.
     * If configured, and a token has a uri set, tokenURI will return "prefixURI+tokenURI"
     * Useful if you want to use ipfs/arweave
     */
    function setTokenURIPrefixExtension(string calldata prefix) external;

    /**
     * @dev set the tokenURI of a token extension.  Can only be called by extension that minted token.
     */
    function setTokenURIExtension(uint256 tokenId, string calldata uri)
        external;

    /**
     * @dev set the tokenURI of a token extension for multiple tokens.  Can only be called by extension that minted token.
     */
    function setTokenURIExtension(
        uint256[] memory tokenId,
        string[] calldata uri
    ) external;

    /**
     * @dev set the baseTokenURI for tokens with no extension.  Can only be called by owner/admin.
     * For tokens with no uri configured, tokenURI will return "uri+tokenId"
     */
    function setBaseTokenURI(string calldata uri) external;

    /**
     * @dev set the common prefix for tokens with no extension.  Can only be called by owner/admin.
     * If configured, and a token has a uri set, tokenURI will return "prefixURI+tokenURI"
     * Useful if you want to use ipfs/arweave
     */
    function setTokenURIPrefix(string calldata prefix) external;

    /**
     * @dev set the tokenURI of a token with no extension.  Can only be called by owner/admin.
     */
    function setTokenURI(uint256 tokenId, string calldata uri) external;

    /**
     * @dev set the tokenURI of multiple tokens with no extension.  Can only be called by owner/admin.
     */
    function setTokenURI(uint256[] memory tokenIds, string[] calldata uris)
        external;

    /**
     * @dev set a permissions contract for an extension.  Used to control minting.
     */
    function setMintPermissions(address extension, address permissions)
        external;

    /**
     * @dev Configure so transfers of tokens created by the caller (must be extension) gets approval
     * from the extension before transferring
     */
    function setApproveTransferExtension(bool enabled) external;

    /**
     * @dev get the extension of a given token
     */
    function tokenExtension(uint256 tokenId) external view returns (address);

    /**
     * @dev Set default royalties
     */
    function setRoyalties(
        address payable[] calldata receivers,
        uint256[] calldata basisPoints
    ) external;

    /**
     * @dev Set royalties of a token
     */
    function setRoyalties(
        uint256 tokenId,
        address payable[] calldata receivers,
        uint256[] calldata basisPoints
    ) external;

    /**
     * @dev Set royalties of an extension
     */
    function setRoyaltiesExtension(
        address extension,
        address payable[] calldata receivers,
        uint256[] calldata basisPoints
    ) external;

    /**
     * @dev Get royalites of a token.  Returns list of receivers and basisPoints
     */
    function getRoyalties(uint256 tokenId)
        external
        view
        returns (address payable[] memory, uint256[] memory);

    // Royalty support for various other standards
    function getFeeRecipients(uint256 tokenId)
        external
        view
        returns (address payable[] memory);

    function getFeeBps(uint256 tokenId)
        external
        view
        returns (uint256[] memory);

    function getFees(uint256 tokenId)
        external
        view
        returns (address payable[] memory, uint256[] memory);

    function royaltyInfo(uint256 tokenId, uint256 value)
        external
        view
        returns (address, uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "../../../openzeppelin/utils/introspection/ERC165.sol";
import "../../../openzeppelin/utils/structs/EnumerableSet.sol";
import "../../../openzeppelin/access/Ownable.sol";
import "./IAdminControl.sol";

abstract contract AdminControl is Ownable, IAdminControl, ERC165 {
    using EnumerableSet for EnumerableSet.AddressSet;

    // Track registered admins
    EnumerableSet.AddressSet private _admins;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IAdminControl).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev Only allows approved admins to call the specified function
     */
    modifier adminRequired() {
        require(
            owner() == msg.sender || _admins.contains(msg.sender),
            "AdminControl: Must be owner or admin"
        );
        _;
    }

    /**
     * @dev See {IAdminControl-getAdmins}.
     */
    function getAdmins()
        external
        view
        override
        returns (address[] memory admins)
    {
        admins = new address[](_admins.length());
        for (uint256 i = 0; i < _admins.length(); i++) {
            admins[i] = _admins.at(i);
        }
        return admins;
    }

    /**
     * @dev See {IAdminControl-approveAdmin}.
     */
    function approveAdmin(address admin) external override onlyOwner {
        if (!_admins.contains(admin)) {
            emit AdminApproved(admin, msg.sender);
            _admins.add(admin);
        }
    }

    /**
     * @dev See {IAdminControl-revokeAdmin}.
     */
    function revokeAdmin(address admin) external override onlyOwner {
        if (_admins.contains(admin)) {
            emit AdminRevoked(admin, msg.sender);
            _admins.remove(admin);
        }
    }

    /**
     * @dev See {IAdminControl-isAdmin}.
     */
    function isAdmin(address admin) public view override returns (bool) {
        return (owner() == admin || _admins.contains(admin));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merklee tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }
        return computedHash;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
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
// OpenZeppelin Contracts v4.4.0 (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

/**
 * @title Interface for RoyaltyEngine
 */
interface IRoyaltyEngine {
    /**
     * @notice Emits when an collection level Royalty is configured
     * @param collectionAddress contract address 
     * @param receivers set of royalty receivers
     * @param basisPoints set of royalty Bps
     */
    event RoyaltiesUpdated(
        address indexed collectionAddress,
        address payable[] receivers,
        uint256[] basisPoints
    );

    /**
     * @notice Emits when an Token level Royalty is configured
     * @param collectionAddress contract address 
     * @param tokenId Token Id 
     * @param receivers set of royalty receivers
     * @param basisPoints set of royalty Bps
     */
    event TokenRoyaltiesUpdated(
        address collectionAddress,
        uint256 indexed tokenId,
        address payable[] receivers,
        uint256[] basisPoints
    );
    
    /**
     * @notice Emits when address is added into Black List.
     * @param account BlackListed NFT contract address or wallet address
     * @param sender caller address
    **/
    event AddedBlacklistedAddress(
        address indexed account,
        address indexed sender
    );

    /**
     * @notice Eits when address is removed from Black List.
     * @param account BlackListed NFT contract address or wallet address
     * @param sender caller address
    **/
    event RevokedBlacklistedAddress(
        address indexed account,
        address indexed sender
    );
    
    /**
     * @notice Setting royalty for NFT Collection.
     * @param collectionAddress NFT contract address 
     * @param receivers set of royalty receivers
     * @param basisPoints set of royalty Bps
     */
    function setRoyalty(
        address collectionAddress,
        address payable[] calldata receivers,
        uint256[] calldata basisPoints
    ) external;
    
    /**
     * @notice Setting royalty for token.
     * @param collectionAddress contract address 
     * @param tokenId Token Id 
     * @param receivers set of royalty receivers
     * @param basisPoints set of royalty Bps
     */
    function setTokenRoyalty(
        address collectionAddress,
        uint256 tokenId,
        address payable[] calldata receivers,
        uint256[] calldata basisPoints
    ) external;

    /**
     * @notice getting royalty information from Other royalty standard.
     * @param collectionAddress contract address 
     * @param tokenId Token Id 
     * @return receivers returns set of royalty receivers address
     * @return basisPoints returns set of Bps to calculate Shares.
    **/
    function getRoyalty(address collectionAddress, uint256 tokenId)
        external view
        returns (address payable[] memory receivers, uint256[] memory basisPoints);
    
    /**
     * @notice Compute royalty Shares
     * @param collectionAddress contract address 
     * @param tokenId Token Id 
     * @param amount amount involved to compute the Shares. 
     * @return receivers returns set of royalty receivers address
     * @return basisPoints returns set of Bps.
     * @return feeAmount returns set of Shares.
    **/
    function getRoyaltySplitshare(
        address collectionAddress,
        uint256 tokenId,
        uint256 amount
    )
        external view
        returns (
            address payable[] memory receivers,
            uint256[] memory basisPoints,
            uint256[] memory feeAmount
        );
    
    /**
     * @notice Adds collection address as blacklist
     * @param collectionAddress user wallet address 
    **/
    function blacklistCollectionAddress(address collectionAddress) external;

    /**
     * @notice Adds user address as blacklist
     * @param walletAddress user wallet address 
    **/
    function blacklistWalletAddress(address walletAddress) external;
    
    /**
     * @notice revoke the blacklistedAddress
     * @param commonAddress address info
    **/
    function revokeBlaclistedAddress(address commonAddress) external;
        
    /**
     * @notice checks the blacklistedAddress
     * @param commonAddress address info
    **/
    function isBlacklistedAddress(address commonAddress)
        external view
        returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/introspection/ERC165.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT

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
    constructor () {
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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "../../../openzeppelin/utils/introspection/IERC165.sol";

/**
 * @dev Interface for admin control
 */
interface IAdminControl is IERC165 {
    event AdminApproved(address indexed account, address indexed sender);
    event AdminRevoked(address indexed account, address indexed sender);

    /**
     * @dev gets address of all admins
     */
    function getAdmins() external view returns (address[] memory);

    /**
     * @dev add an admin.  Can only be called by contract owner.
     */
    function approveAdmin(address admin) external;

    /**
     * @dev remove an admin.  Can only be called by contract owner.
     */
    function revokeAdmin(address admin) external;

    /**
     * @dev checks whether or not given address is an admin
     * Returns True if they are
     */
    function isAdmin(address admin) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/Strings.sol)

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