/**
 *Submitted for verification at Etherscan.io on 2022-03-16
*/

// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/utils/Counters.sol


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

// File: contracts/MarketSale.sol



pragma solidity ^0.8.4;


abstract contract Nft {
    function isApprovedOrOwner(address spender, uint256 tokenId)
        public
        view
        virtual
        returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual;
}
// address - 0x50c3e05E0800DFb8d1b442bFB713E3fd5e5ca63C
contract MarketPlace {
    using Counters for Counters.Counter;
    Counters.Counter private _saleId;

    // Core nft contract on which marketplace would be created.
    Nft nft;

    // Minimum difference between to bids.
    uint256 bidDifference = 10 wei;

    address owner;

    // Struct to represent active items on market sale.
    struct activeSaleItem {
        uint256 id;
        uint256 tokenId;
        address payable seller;
        address payable currentBidder;
        uint256 currentBidValue;
        bool onSale;
        uint256 endTime;
    }
    // Keeps track of sale items.
    mapping(uint256 => activeSaleItem) tokenIdToItem;

    event marketSaleCreated(
        uint256 tokenId,
        address publisher,
        uint256 initPrice,
        uint256 endTime
    );
    event newBid(uint256 tokenId, address from, uint256 biddingValue);
    event saleCompleted(address from, uint256 price, address to);

    // Init core nft contract for which market sale would be created.
    constructor(address nftContract) {
        nft = Nft(nftContract);
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Only owner can call");
        _;
    }
    

    /*
     * @dev Update Bid difference contract variable.
     * @param newValue to assign.
     */
    function updateBidPrecesion(uint256 newValue) public onlyOwner {
        bidDifference = newValue;
    }

    /*
     * @dev Creates new sale for given token Id.
     * @param tokenId token id to create sale for.
     * @param initBidAmount is minimum bidding for item buyers.
     * @param end time for market sale.
     */
    function createMarketSale(
        uint256 tokenId,
        uint256 initBidAmount,
        uint256 endTime
    ) public {
        require(
            nft.isApprovedOrOwner(msg.sender, tokenId),
            "caller not an owner or approved"
        );
        require(tokenIdToItem[tokenId].onSale == false, "Already on sale");
        _saleId.increment();
        tokenIdToItem[tokenId] = activeSaleItem(
            _saleId.current(),
            tokenId,
            payable(msg.sender),
            payable(address(0)),
            initBidAmount,
            true,
            endTime
        );

        emit marketSaleCreated(tokenId, msg.sender, initBidAmount, endTime);
    }

    /*
     * @dev Bid for a market sale token id.
     * @param token Id to bid for.
     */
    function bid(uint256 tokenId) public payable {
        require(tokenIdToItem[tokenId].onSale == true, "Token not on sale");
        require(tokenIdToItem[tokenId].endTime > block.timestamp, "Sale Ended");
        require(
            msg.value >= tokenIdToItem[tokenId].currentBidValue + bidDifference,
            "Bid value smaller than min bid value"
        );
        tokenIdToItem[tokenId].currentBidder = payable(msg.sender);
        tokenIdToItem[tokenId].currentBidValue = msg.value;
        emit newBid(tokenId, msg.sender, msg.value);
    }

    /*
     * @dev Current bidder can claim item/ nft after sale is over.
     * @param token Id to claim.
     */
    function claimItem(uint256 tokenId) public {
        require(
            tokenIdToItem[tokenId].endTime <= block.timestamp,
            "Sale not ended"
        );
        activeSaleItem memory itemStruct = tokenIdToItem[tokenId];
        itemStruct.seller.transfer(itemStruct.currentBidValue);
        nft.transferFrom(itemStruct.seller, itemStruct.currentBidder, tokenId);
        emit saleCompleted(
            tokenIdToItem[tokenId].seller,
            itemStruct.currentBidValue,
            itemStruct.currentBidder
        );
        delete tokenIdToItem[tokenId];
    }
}