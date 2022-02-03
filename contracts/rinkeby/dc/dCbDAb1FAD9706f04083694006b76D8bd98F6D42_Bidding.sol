/**
 *Submitted for verification at Etherscan.io on 2022-02-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
interface IERC721 {
    function transfer(address, uint256) external;

    function transferFrom(
        address,
        address,
        uint256
    ) external;
}
contract Bidding {
    address payable public seller;
    bool public started;
    bool public ended;
    IERC721 public nft;
    uint256 public nftId;
    event result(address highestBidder, uint256 highestBid);
    struct info{
        address bidder;
        uint bidderprice;
    }
    info[] Bids;
    constructor() public {
        seller = payable(msg.sender);
        Bids.push(info(0x75e6d26FC1B2289799792e505D0223652b900C49 , 0));
        

    }
    function start(IERC721 _nft,uint256 _nftId) external payable {
        require(!started, "Bidding was Already started!");
        started = true;
        nft = _nft;
        nftId = _nftId;
        
    }
    function enterbid(uint _bidderprice) public{
        require(started, "Bidding is not yet started.");
        uint lastentry = Bids.length - 1;
        require(_bidderprice > Bids[lastentry].bidderprice,"Price is not sufficient to enter the Bid");
        Bids.push(info(msg.sender,_bidderprice));
    }
    function end() external {
        require(started, "You need to start first!");
        require(!ended, "Auction already ended!");
        ended = true;
        started = false;
    }
    
    function bidresult() external payable{
        uint lastentry = Bids.length-1;
        require(ended,"Event is not ended");
        (address highestbidder,uint highestbidamount) = (Bids[lastentry].bidder,Bids[lastentry].bidderprice);
        nft.transferFrom(msg.sender,highestbidder, nftId);
        (bool sent, bytes memory data) = seller.call{value: highestbidamount}("");
        require(sent, "Could not pay seller!");
        
        emit result(highestbidder,highestbidamount);
    }
}