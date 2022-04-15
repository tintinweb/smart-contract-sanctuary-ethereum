/**
 *Submitted for verification at Etherscan.io on 2022-04-14
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;



// Part: IERC721

interface IERC721 {
    function safeTransferFrom(
        address from,
        address to,
        uint tokenId
    ) external;

    function transferFrom(
        address,
        address,
        uint
    ) external;
}

// File: Auction.sol

/*
 * @title: Auction Smart Contract.
 * @author: Anthony (fps) https://github.com/fps8k .
 * @dev: Reference [README.md].
*/

contract MyAuction
{
    // Creating necessary state variables.
    // Time of deployment and time span of the bidding.

    uint256 private deploy_time;
    uint64 private bid_time_span = 7 days;
    bool private still_bidding;
    bool locked;


    // Highest bidder price.

    uint256 private highest_bid;
    
    
    // Mapping amount bidded to address.

    mapping(uint256 => address) private price_to_bidder;    // No two bidders can have the same bid.
    mapping(address => uint256) private bidder_to_price;    // No two bidders can have the same bid.


    // NFT Details for constructor.

    IERC721 private nft;
    uint256 private nft_id;
    uint256 private starting_bid;
    address private seller;


    constructor(address _nft_address, uint256 _nft_id) payable
    {
        nft = IERC721(_nft_address);
        nft_id = _nft_id;
        starting_bid = msg.value;
        seller = msg.sender;

        deploy_time = block.timestamp;
        still_bidding = true;
    }

    fallback() payable external {}
    receive() payable external {}




    // Getter functions and modifiers.
    // Returns whoever called a function.

    function getMessageSender() private view returns(address)
    {
        address _msg_sender = msg.sender;
        return _msg_sender;
    }


    // Validates that the caller is a valid adress.

    modifier isValidCaller()
    {
        require(getMessageSender() != address(0), "Invalid calling address.");
        _;
    }


    // Protects from re-entrancy hack.

    modifier noReEntrance()
    {
        require(!locked, "No re-entrancy");
        locked = true;
        _;
        locked = false;
    }


    // Checks if the bid was made within time, also if the time is over 7 days, it sets `still_bidding` to false, stopping any new bids.
    
    modifier withinTime()
    {
        uint256 time_now = block.timestamp;
        uint256 _deploy_time = deploy_time;
        uint256 _bid_time_span = bid_time_span;

        if((time_now >= (_deploy_time + _bid_time_span)))
        {
            still_bidding = false;
        }

        require((time_now < (_deploy_time + _bid_time_span)), "Auction expired.");
        _;
    }


    // Checks if the bidding is still ongoing or ended.

    modifier stillBidding()
    {
        require(still_bidding, "Auction expired.");
        _;
    }


    // Returns the highest bid.

    function getHighestBid() private view returns(uint256)
    {
        uint256 _highest_bid = highest_bid;
        return _highest_bid;
    }


    // Checks to make sure that the price is unique and no two persons can bid the same thing.

    function isUniquePrice(uint256 price) private view returns(bool)
    {
        // Returns true if the address with the price is empty.
        bool is_unique_price = price_to_bidder[price] == address(0);        // Returns true if the address with the price is empty.
        return is_unique_price;
    }


    // Prevents the user from bidding twice.

    function hasMadeABid() private view returns (bool)
    {
        // Returns true if the amount associated with the address is != 0.
        bool has_made_bid = bidder_to_price[getMessageSender()] != 0;
        return has_made_bid;
    }




    /* 
    * @dev:
    * {bid()} function allows the caller to make a fresh bid.
    *
    * Conditions:
    * - Caller cannot be a 0 address.
    * - Caller cannot be the `seller` of the token.
    * - `msg.value` must be greater than the `starting_bid`.
    * - It must still be within time of bid.
    * - It must be still the validity of the bid.
    * - `msg.value` sent for the bid, must be unique.
    *
    * - If the new bid is higher than the current highest bid, then, it replaces the value.
    */

    function bid() public payable isValidCaller() noReEntrance() withinTime() stillBidding()
    {
        address _seller = seller;
        uint256 _starting_bid = starting_bid;
        require(getMessageSender() != _seller, "You can't bid your nft.");
        require(msg.value >= _starting_bid, "Price lower than minimum bid."); // Price must be >= starting bid;
        uint256 bid_price = msg.value;
        require(isUniquePrice(bid_price), "Bid taken, make a unique bid.");

        if(bid_price > getHighestBid())
        {
            highest_bid = bid_price;
        }

        price_to_bidder[bid_price] = getMessageSender();
        bidder_to_price[getMessageSender()] = bid_price;
    }




    /* 
    * @dev:
    * {withdraw()} function allows anyone who is not the highest bidder to withdraw his funds.
    *
    * Conditions:
    * - Caller cannot be a 0 address.
    * - Caller cannot be the `seller` of the token.
    * - Caller cannot be the highest bidder.
    *
    * - After paying, deletes the relevant records for the caller.
    */

    function withdraw() public payable isValidCaller() noReEntrance()
    {
        address _seller = seller;
        require(getMessageSender() != _seller, "You can't withdraw or bid your nft.");
        require(hasMadeABid(), "You have not made a bid.");
        require(price_to_bidder[getHighestBid()] != getMessageSender(), "You are the highest bidder, you cannot withdraw.");

        address payto_address = getMessageSender();
        uint256 _bid_return_price = bidder_to_price[payto_address];
        payable(payto_address).transfer(_bid_return_price);

        delete bidder_to_price[getMessageSender()];
        delete price_to_bidder[_bid_return_price];
    }




    /* 
    * @dev:
    * {end()} function allows the seller to end the auction and send the nft to the highest bidder.
    *
    * Conditions:
    * - Caller cannot be a 0 address.
    * - Caller must be the `seller` of the token.
    * - Highest bid cannot be 0.
    *
    * - It sets `still_bidding` to false, stopping any new bids.
    */

    function end() public payable isValidCaller() noReEntrance()
    {
        address _seller = seller;
        require(getMessageSender() == _seller, "You cannot call this function.");
        uint256 __highest_bid = getHighestBid();
        require(__highest_bid > 0, "No one bid your nft.");
        address _winner = price_to_bidder[__highest_bid];

        nft.safeTransferFrom(_seller, _winner, nft_id);
        still_bidding = false;
    }

}