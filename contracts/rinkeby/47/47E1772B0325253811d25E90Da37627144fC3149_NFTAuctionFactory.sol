/**
 *Submitted for verification at Etherscan.io on 2022-09-06
*/

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.7.4;

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 {
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

library SafeMathLib {
  function times(uint a, uint b) public pure returns (uint) {
    uint c = a * b;
    require(a == 0 || c / a == b, 'Overflow detected');
    return c;
  }

  function minus(uint a, uint b) public pure returns (uint) {
    require(b <= a, 'Underflow detected');
    return a - b;
  }

  function plus(uint a, uint b) public pure returns (uint) {
    uint c = a + b;
    require(c>=a && c>=b, 'Overflow detected');
    return c;
  }

}

contract NFTAuctionFactory {
    using SafeMathLib for uint;

    enum AuctionState {
        NASCENT,
        STARTED,
        CONCLUDED,
        CANCELLED
    }

    struct AuctionStructure {
        uint id;
        bytes32 metadata;
        uint numSamplesBeforeSale;
        uint startingPrice;
        address nftContract;
        uint tokenForSale;
        uint beneficiary1Pct;
        address payable beneficiary1;
        address payable beneficiary2;
        bool beneficiariesPaid;
        bool nftDistributed;
    }

    struct Auction {
        uint id;
        uint startTime;
        uint startDelay;
        uint lastBid;
        uint lastBidTime;
        uint endTime;
        uint secondsPerSample;
        address payable lastBidder;
        AuctionState state;
    }

    uint public numAuctions;
    uint public currentAuctionId = 1;
    uint public cancellationTimer;
    address public management;
    mapping (uint => Auction) public auctions;
    mapping (uint => AuctionStructure) public structures;

    mapping (address => mapping (uint => bool)) public whitelistedNFTs;
    bytes4 private constant ERC721_RECEIVED = 0x150b7a02;

    event BidOccurred(address indexed bidder, address lastBidder, uint bidAmount, uint lastBidAmount);
    event AuctionCreated(uint indexed id);
    event ManagementUpdated(address oldManagement, address newManagement);
    event CancellationTimerUpdated(uint oldTimer, uint newTimer);

    modifier managementOnly() {
        require (msg.sender == management, 'Only management may call this');
        _;
    }

    constructor(address mgmt, uint cancelTimer) {
        management = mgmt;
        cancellationTimer = cancelTimer;
    }

    // change the management key
    function setManagement(address newMgmt) public managementOnly {
        address oldMgmt = management;
        management = newMgmt;
        emit ManagementUpdated(oldMgmt, newMgmt);
    }

    function setCancellationTime(uint newTimer) public managementOnly {
        uint oldTimer = cancellationTimer;
        cancellationTimer = newTimer;
        emit CancellationTimerUpdated(oldTimer, newTimer);
    }

    function addAuction(uint _numSamplesBeforeSale,
                uint _secondsPerSample,
                uint _startingPrice,
                uint _beneficiary1Pct,
                uint _startDelay,
                bytes32 _metadata,
                address payable _beneficiary1,
                address payable _beneficiary2,
                address _nftContract,
                uint _tokenForSale) public managementOnly {

        require(_numSamplesBeforeSale > 0, '_numSamplesBeforeSale must be positive');
        require(_secondsPerSample > 0, '_secondsPerSample must be positive');
        require(_startingPrice > 0, '_startingPrice must be positive');
        require(_beneficiary1Pct > 0 && _beneficiary1Pct <= 100, '_beneficiary1Pct must be between 0 and 100');
        require(whitelistedNFTs[_nftContract][_tokenForSale] == false, 'cannot have same nft in queue twice simultaneously');

        // omitting this check, since we don't want to ask nft owner to have to trust us
        // we should commit to auction then they should send the nft
        //        require(IERC721(_nftContract).ownerOf(_tokenForSale) == address(this), 'Must transfer nft to auction contract first');

        // truncate numSamples, since we use it for bitshifting later
        if (_numSamplesBeforeSale > 255) {
            _numSamplesBeforeSale = 255;
        }
        numAuctions = numAuctions.plus(1);

        {
            AuctionStructure storage structure = structures[numAuctions];
            structure.id = numAuctions;
            structure.metadata = _metadata;
            structure.numSamplesBeforeSale = _numSamplesBeforeSale;
            structure.startingPrice = _startingPrice;
            structure.beneficiary1Pct = _beneficiary1Pct;
            structure.beneficiary1 = _beneficiary1;
            structure.beneficiary2 = _beneficiary2;
            structure.nftContract = _nftContract;
            structure.tokenForSale = _tokenForSale;
            // make sure we can receive the nft (see onERC721Received)
            whitelistedNFTs[_nftContract][_tokenForSale] = true;
        }
        Auction storage auction = auctions[numAuctions];
        auction.id = numAuctions;
        auction.secondsPerSample = _secondsPerSample;
        auction.startDelay = _startDelay;
        emit AuctionCreated(auction.id);
    }
    
    function doWeOwn(address nftContract, uint tokenId) public view returns (bool) {
        // check that we are the owner of this nft
        // have to use try catch because erc721 standard
        // has no way to ask "does this token exist" without a possible revert
        try IERC721(nftContract).ownerOf(tokenId) returns (address owner) {
            return owner == address(this);
        } catch {
            return false;
        }
    }

    function canStart() public view returns (bool) {
        uint auctionId1 = currentAuctionId.minus(1);
        uint auctionId2 = currentAuctionId;
        Auction memory previousAuction = auctions[auctionId1];
        Auction memory nextAuction = auctions[auctionId2];
        AuctionStructure memory nextStructure = structures[auctionId2];
        bool correctOwner = false;
        bool nextAuctionExists = nextAuction.id == auctionId2;

        // need to short circuit the try catch if next auction doesn't exist
        if (nextAuctionExists == false) {
            return false;
        }

        // check that we are the owner of this nft
        // have to use try catch because erc721 standard
        // has no way to ask "does this token exist" without a possible revert
        try this.doWeOwn(nextStructure.nftContract, nextStructure.tokenForSale) returns (bool _correctOwner) {
            correctOwner = _correctOwner;
        } catch {
            return false;
        }

        bool firstAuction = auctionId1 == 0;
        bool previousFinished = previousAuction.state == AuctionState.CONCLUDED || previousAuction.state == AuctionState.CANCELLED;

        return (
            (firstAuction || previousFinished) &&
            nextAuction.state == AuctionState.NASCENT &&
            correctOwner
        );
    }

    function startAuction() public {
        require(canStart(), 'Check that contract owns nft for sale and previous auction was concluded');
        Auction storage auction = auctions[currentAuctionId];
        auction.state = AuctionState.STARTED;
        auction.startTime = block.timestamp;
    }

    function getSamplesSinceLastBid() public view returns (uint) {
        Auction memory auction = auctions[currentAuctionId];
        if (auction.lastBidTime == 0) {
            return 0;
        }
        uint timeDiff = block.timestamp.minus(auction.lastBidTime);
        uint samplesDiff = timeDiff / auction.secondsPerSample;

        if (samplesDiff > 255) {
            samplesDiff = 255;
        }
        return samplesDiff;
    }

    function getCurrentPrice() public view returns (uint) {
        Auction memory auction = auctions[currentAuctionId];
        AuctionStructure memory structure = structures[currentAuctionId];
        if (auction.lastBid == 0) {
            return structure.startingPrice;
        } else if (auction.state != AuctionState.STARTED) {
            return 0;
        } else {
            uint samplesDiff = getSamplesSinceLastBid();
            return auction.lastBid.plus(auction.lastBid / (1 << samplesDiff));
        }
    }

    function bid(uint auctionId) public payable {
        // check the auction id is the current one to prevent accidentally bidding on next auction
        require(auctionId == currentAuctionId, 'Invalid auctionId');

        // check that they sent enough eth
        uint price = getCurrentPrice();
        require(price <= msg.value, 'Please send more ETH');

        // check that we have completed countdown
        Auction storage auction = auctions[currentAuctionId];
        require(auction.startTime.plus(auction.startDelay) < block.timestamp, 'Must wait for delay to pass');
        require(auction.state == AuctionState.STARTED, 'Not started yet');

        // record last bid/der info to close re-entrance gate
        address payable previousBidder = auction.lastBidder;
        uint previousPrice = auction.lastBid;

        // close re-entrance gate so re-entry just means they send some eth to themselves
        auction.lastBid = price;
        auction.lastBidTime = block.timestamp;
        auction.lastBidder = msg.sender;

        // refund user excess eth and
        // make sure bidder can receive eth (possibly 0) (i.e. is not malicious contract)
        require(msg.sender.send(msg.value.minus(price)), 'Cannot refund bidder');

        // if this is not the first bid, send the previous bidder back their eth
        if (previousBidder != address(0)) {
            // using "send" so this could fail if lastBidder is a contract
            // that cannot receive this eth but that's their fault, so we keep going
            previousBidder.send(previousPrice);
        }

        emit BidOccurred(msg.sender, previousBidder, price, previousPrice);
    }

    function canConclude() public view returns (bool) {
        AuctionStructure memory structure = structures[currentAuctionId];
        Auction memory auction = auctions[currentAuctionId];
        return auction.state == AuctionState.STARTED && getSamplesSinceLastBid() >= structure.numSamplesBeforeSale;
    }

    function concludeAuction() public {
        require(canConclude(), 'Contract already concluded or not enough samples passed');
        endAuction(false);
    }

    function canCancel() public view returns (bool) {
        Auction storage auction = auctions[currentAuctionId];
        bool auctionExists = auction.id == currentAuctionId;
        if (auctionExists == false) {
           return false;
        }

        bool timerUp = block.timestamp > auction.startTime.plus(cancellationTimer);
        bool started = auction.state == AuctionState.STARTED;
        bool noBidder = auction.lastBid == 0;
        bool nascent = auction.state == AuctionState.NASCENT;
        bool cantStart = canStart() == false;
        return (
            (started && timerUp && noBidder) ||
            (cantStart && nascent)
        );
    }

    function cancelAuction() public managementOnly {
        require(canCancel(), 'Cannot cancel auction, check that either no bids have occurred or canCancel returns false');

        AuctionStructure memory structure = structures[currentAuctionId];
        // check that we are the owner of this nft
        // have to use try catch because erc721 standard
        // has no way to ask "does this token exist" without a possible revert
        try this.doWeOwn(structure.nftContract, structure.tokenForSale) returns (bool correctOwner) {
            if (correctOwner == false) {
                whitelistedNFTs[structure.nftContract][structure.tokenForSale] = false;
            }
        } catch {
            // continue
        }
        endAuction(true);
    }

    function endAuction(bool cancelled) internal {
        Auction storage auction = auctions[currentAuctionId];
        if (cancelled) {
            auction.state = AuctionState.CANCELLED;
        } else {
            auction.state = AuctionState.CONCLUDED;
        }
        auction.endTime = block.timestamp;
        currentAuctionId = currentAuctionId.plus(1);
    }

    function withdrawNFT(uint auctionId) public {
        AuctionStructure storage structure = structures[auctionId];
        Auction memory auction = auctions[auctionId];
        require(structure.nftDistributed == false, 'NFT already distributed');
        // state can be either cancelled or concluded since nft needs transferring in either case
        require(auction.state == AuctionState.CANCELLED || auction.state == AuctionState.CONCLUDED, 'Cannot withdraw NFT unless auction is finished');

        // close gate
        structure.nftDistributed = true;
        // allow nft to be auctioned again, this can be useful if the nft cannot be transferred for some reason
        whitelistedNFTs[structure.nftContract][structure.tokenForSale] = false;
        if (auction.state == AuctionState.CANCELLED) {
            // no bids occurred, send nft to beneficiary1
            IERC721(structure.nftContract).safeTransferFrom(address(this), structure.beneficiary1, structure.tokenForSale);
        } else if (auction.state == AuctionState.CONCLUDED) {
            // last bidder is owner
            IERC721(structure.nftContract).safeTransferFrom(address(this), auction.lastBidder, structure.tokenForSale);
        }
    }

    function withdrawEarnings(uint auctionId) public {
        AuctionStructure storage structure = structures[auctionId];
        Auction memory auction = auctions[auctionId];
        require(structure.beneficiariesPaid == false, 'Beneficiaries already paid');
        // must be in concluded state, since if it was cancelled, there were no bids
        require(auction.state == AuctionState.CONCLUDED, 'Auction must be in concluded state to withdraw');
        // close the gate, preventing re-entrance before transferring ether
        structure.beneficiariesPaid = true;

        // compute amounts, should sum to auction.lastBid
        uint amount1 = auction.lastBid.times(structure.beneficiary1Pct) / 100;
        uint amount2 = auction.lastBid.minus(amount1);

        // either one of these can fail, trapping ether in the contract
        // but that's their fault if they gave management an address that can't receive ether
        structure.beneficiary1.send(amount1);
        structure.beneficiary2.send(amount2);
    }

    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4) {
        address nftContract = msg.sender;
        require(whitelistedNFTs[nftContract][tokenId], 'Not expecting to receive this NFT');
        return ERC721_RECEIVED;
    }

}