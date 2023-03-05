/**
 *Submitted for verification at Etherscan.io on 2023-03-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract DutchAuctionSolution {
    enum BidState {notStarted, secretBid, openBid, endedBid}

    struct NFT {
 	    string name;
	    string imageUrl;
	    uint256 id;
	    address payable owner;
        bool isOwner;
        string bidState;
    }

    struct NFTBiding {
        uint256 highestBid;
        uint8 maxBidMultiplier;
        uint256 reservePrice;
        uint256 bidStartTime;
        BidState bidState;
    }

    mapping(uint256 => NFTBiding) nftBidingData;
    mapping(uint256 => mapping(address => bool)) participants;

    mapping(uint256 => NFT) nftList;
    uint256 public nftItemCount = 0;
    uint8 constant discountPerSec = 100;
    event SecretBidStarted(uint256 nftId);
    event StartOpenBid(uint256 nftId, uint256 startTime, uint256 startAmount);
    event AuctionCompleted(uint256 nftId, string msg);
    // event TestPrice(string, uint256);

    function addItem(string memory name, string memory url, uint256 _reservePrice, uint8 maxMultiplier) public returns (NFT memory) {
        NFT memory newNFT = NFT(name, url, nftItemCount, payable(msg.sender), true, "notStarted");
        nftList[nftItemCount] = newNFT;
        nftBidingData[nftItemCount].highestBid = _reservePrice;
        nftBidingData[nftItemCount].maxBidMultiplier = maxMultiplier;
        nftBidingData[nftItemCount].reservePrice = _reservePrice;
        nftItemCount++;
        return newNFT;
    }

    function startSecretBid(uint256 id) public returns (bool) {
        require(id < nftItemCount, "Item doesn't exists");
        NFTBiding memory bidingData = nftBidingData[id];
        NFT memory nftData = nftList[id];
        require(bidingData.bidState == BidState.notStarted, "Secret Bid has not started yet");
        require(nftData.owner == payable(msg.sender), "Only owner can start the bid");
        emit SecretBidStarted(id);
        nftBidingData[id].bidState = BidState.secretBid;
        return true;
    }

    function addSecretBid(uint256 id, uint256 bidAmount) public returns (bool) {
        require(id < nftItemCount, "Item doesn't exists");
        NFTBiding memory bidingData = nftBidingData[id];
        NFT memory nftData = nftList[id];
        require(bidingData.bidState == BidState.secretBid, "Secret Bid has not started yet");
        require(nftData.owner != payable(msg.sender), "Owner can't place the bid");
        if (bidingData.highestBid < bidAmount) {
            nftBidingData[id].highestBid = bidAmount;
        }
        participants[id][msg.sender] = true;
        return true;
    }

    function startOpenBid(uint256 id) public returns (uint256) {
        require(id < nftItemCount, "Item doesn't exists");
        NFTBiding memory bidingData = nftBidingData[id];
        NFT memory nftData = nftList[id];
        require(bidingData.bidState == BidState.secretBid, "Secret Bid has not started yet");
        require(nftData.owner == payable(msg.sender), "Only owner can start the bid");
        nftBidingData[id].bidStartTime = block.timestamp;
        nftBidingData[id].bidState = BidState.openBid;
        uint256 startAmount = bidingData.highestBid * bidingData.maxBidMultiplier;
        emit StartOpenBid(id, nftBidingData[id].bidStartTime, startAmount);
        return startAmount;
    }

    function endOpenBid(uint256 id) public returns (bool) {
        require(id < nftItemCount, "Item doesn't exists");
        NFT memory nftData = nftList[id];
        NFTBiding memory bidingData = nftBidingData[id];
        require(bidingData.bidState == BidState.openBid, "Bid has not started yet");
        require(nftData.owner == payable(msg.sender), "Only owner can start the bid");
        nftBidingData[id].bidState = BidState.endedBid;
        emit AuctionCompleted(id, "Bid Ended");
        return true;
    }
    
    function getBidState(uint256 id) public view returns (string memory) {
        require(id < nftItemCount, "Item doesn't exists");
        NFTBiding memory bidingData = nftBidingData[id];
        return getBidStateString(bidingData.bidState);
    }

    function getBidStateString(BidState bidState) private pure returns (string memory) {
        if (bidState == BidState.notStarted) {
            return "notStarted";
        } else if (bidState == BidState.secretBid) {
            return "secretBid";
        } else if (bidState == BidState.openBid) {
            return "openBid";
        } else {
            return "endedBid";
        }
    }

    function getItemCurrentPrice(uint256 id) public view returns (uint256) {
        require(id < nftItemCount, "Item doesn't exists");
        NFTBiding memory bidingData = nftBidingData[id];
        require(bidingData.bidState == BidState.openBid, "Open Bid has not started yet");
        uint256 elapsedTime = block.timestamp - bidingData.bidStartTime;
        uint256 discountPercentage = elapsedTime * (discountPerSec / 100);
        uint256 startAmount = (bidingData.highestBid * bidingData.maxBidMultiplier);
        uint256 discountAmout =  (startAmount * discountPercentage) / 100;
        if (discountAmout > startAmount) {
            return 0;
        }
        return startAmount - discountAmout;
    }

    function placeBid(uint256 id, uint256 amount) public payable {
        require(id < nftItemCount, "Item doesn't exists");
        NFTBiding memory bidingData = nftBidingData[id];
        NFT memory nftData = nftList[id];
        require(nftData.owner != payable(msg.sender), "Owner can't place the bid");
        require(bidingData.bidState == BidState.openBid, "Open bid has not started yet");
        require(amount > bidingData.reservePrice, "Bid price should not be less than reserve price");
        require(participants[id][msg.sender] == true, "Only Secret bid participants can place open bid");
        // emit TestPrice("value", msg.value);
        // emit TestPrice("amount", amount);
        require(msg.value >= amount, "Insuficient balance");
        nftList[id].owner.transfer(msg.value);
        nftList[id].owner = payable(msg.sender);
        nftBidingData[id].bidState = BidState.endedBid;
        emit AuctionCompleted(id, "Owner changed");
    }

    function getNFTOwners() public view returns (NFT[] memory) {
        NFT[] memory ownerData = new NFT[](nftItemCount);
        for (uint8 i = 0; i < nftItemCount; i++) {
            ownerData[i] = nftList[i];
            ownerData[i].isOwner = msg.sender == ownerData[i].owner;
            ownerData[i].bidState = getBidStateString(nftBidingData[i].bidState);
        }
        return ownerData;
    }
}