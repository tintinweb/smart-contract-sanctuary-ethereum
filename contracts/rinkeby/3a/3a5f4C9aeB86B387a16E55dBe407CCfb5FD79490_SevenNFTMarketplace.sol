// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "./ERC1155Receiver.sol";
import "./Ownable.sol";
import "./ISevenNFT.sol";

contract SevenNFTMarketplace is Ownable {
    ISevenNFT public sevenNFT;
    uint256 public sellId = 1;
    uint256 public tradeId = 1;
    uint256 public auctionId = 1;
    uint256 public bidDif = 0.01 ether;

    mapping(uint256 => Trade) public tradeHistory;
    mapping(uint256 => Sell) public saleList;
    mapping(uint256 => Auction) public auctionList;
    mapping(uint256 => bool) public isTokenTraded;
    mapping(address => uint256) public userSaleCounter;
    mapping(address => uint256) public userTradeCounter;
    mapping(address => uint256) public userAuctionCounter;

    struct Sell {
        uint256 tokenId;
        uint256 price;
        uint256 timestamp;
        uint256 amount;
        uint256 sold;
        address owner;
    }

    struct Trade {
        uint256 tokenId;
        address seller;
        address buyer;
        uint256 price;
        uint256 amount;
        uint256 sellId;
    }

    struct Auction {
        uint256 tokenId;
        uint256 price;
        uint256 addTime;
        uint256 expireTime;
        uint256 amount;
        address owner;
        address currentBidder;
        uint256 currentBid;
        uint256 currentBidTime;
        uint256 bidders;
        bool claimed;
    }

    struct AuctionView {
        uint256 auctionId;
        uint256 tokenId;
        string metadata;
        uint256 price;
        uint256 addTime;
        uint256 expireTime;
        uint256 amount;
        address owner;
        address currentBidder;
        uint256 currentBid;
        uint256 currentBidTime;
        uint256 bidders;
        bool claimed;
    }

    struct SellView {
        uint256 sellId;
        string metadata;
        uint256 tokenId;
        uint256 price;
        uint256 timestamp;
        uint256 amount;
        uint256 sold;
        address owner;
    }

    struct TradeView {
        uint256 tradeId;
        string metadata;
        uint256 tokenId;
        address seller;
        address buyer;
        uint256 price;
        uint256 amount;
        uint256 sellId;
    }

    constructor(address sevenNFTAddress) {
        sevenNFT = ISevenNFT(sevenNFTAddress);
    }

    // Events
    event PutOnSale(uint256 tokenId, uint256 price, uint256 sellId);

    function setSevenNFTAddress(address sevenNFTAddress) public onlyOwner {
        sevenNFT = ISevenNFT(sevenNFTAddress);
    }

    function setBidDif(uint256 dif) public onlyOwner {
        bidDif = dif;
    }

    // ----------------------------------------------------------------------------------------------------------------
    // CALLS ----------------------------------------------------------------------------------------------------------
    // ----------------------------------------------------------------------------------------------------------------
    function getListedItems() public view returns (SellView[] memory) {
        SellView[] memory listedItems = new SellView[](sellId - 1);
        for (uint256 i = 1; i <= sellId - 1; i++) {
            Sell memory list = saleList[i];
            listedItems[i - 1] = SellView(
                i,
                sevenNFT.getMetaData(list.tokenId),
                list.tokenId,
                list.price,
                list.timestamp,
                list.amount,
                list.sold,
                list.owner
            );
        }
        return listedItems;
    }

    function getUserListedItems(address _user) public view returns (SellView[] memory) {
        uint256 size = userSaleCounter[_user];
        SellView[] memory listedItems = new SellView[](size);
        uint256 counter = 0;
        for (uint256 i = 1; i <= sellId; i++) {
            if (saleList[i].owner == _user) {
                Sell memory list = saleList[i];
                listedItems[counter] = SellView(
                    i,
                    sevenNFT.getMetaData(list.tokenId),
                    list.tokenId,
                    list.price,
                    list.timestamp,
                    list.amount,
                    list.sold,
                    list.owner
                );
                counter++;
            }
        }
        return listedItems;
    }

    function getTrades() public view returns (TradeView[] memory) {
        TradeView[] memory tradedItems = new TradeView[](tradeId - 1);
        for (uint256 i = 1; i <= tradeId - 1; i++) {
            Trade memory trade = tradeHistory[i];
            tradedItems[i - 1] = TradeView(
                i,
                sevenNFT.getMetaData(trade.tokenId),
                trade.tokenId,
                trade.seller,
                trade.buyer,
                trade.price,
                trade.amount,
                trade.sellId
            );
        }
        return tradedItems;
    }

    function getUserTrades(address _user) public view returns (TradeView[] memory) {
        uint256 size = userTradeCounter[_user];
        TradeView[] memory userTrades = new TradeView[](size);
        uint256 counter = 0;
        for (uint256 i = 1; i <= tradeId; i++) {
            if (tradeHistory[i].seller == _user || tradeHistory[i].buyer == _user) {
                Trade memory trade = tradeHistory[i];
                userTrades[counter] = TradeView(
                    i,
                    sevenNFT.getMetaData(trade.tokenId),
                    trade.tokenId,
                    trade.seller,
                    trade.buyer,
                    trade.price,
                    trade.amount,
                    trade.sellId
                );
                counter++;
            }
        }
        return userTrades;
    }

    function getAuctions() public view returns (AuctionView[] memory) {
        AuctionView[] memory auctions = new AuctionView[](auctionId - 1);
        for (uint256 i = 1; i <= auctionId - 1; i++) {
            Auction memory auction = auctionList[i];
            auctions[i - 1] = AuctionView(
                i,
                auction.tokenId,
                sevenNFT.getMetaData(auction.tokenId),
                auction.price,
                auction.addTime,
                auction.expireTime,
                auction.amount,
                auction.owner,
                auction.currentBidder,
                auction.currentBid,
                auction.currentBidTime,
                auction.bidders,
                auction.claimed
            );
        }
        return auctions;
    }

    function getUserAuctions(address _user) public view returns (AuctionView[] memory) {
        uint256 size = userAuctionCounter[_user];
        AuctionView[] memory auctions = new AuctionView[](size);
        uint256 counter = 0;
        for (uint256 i = 1; i <= auctionId; i++) {
            if (auctionList[i].owner == _user) {
                Auction memory auction = auctionList[i];
                auctions[counter] = AuctionView(
                    i,
                    auction.tokenId,
                    sevenNFT.getMetaData(auction.tokenId),
                    auction.price,
                    auction.addTime,
                    auction.expireTime,
                    auction.amount,
                    auction.owner,
                    auction.currentBidder,
                    auction.currentBid,
                    auction.currentBidTime,
                    auction.bidders,
                    auction.claimed
                );
                counter++;
            }
        }
        return auctions;
    }

    function isTraded(uint256 _tokenId) external view returns (bool) {
        return isTokenTraded[_tokenId];
    }

    function _getMetaData(uint256 _tokenId) internal view returns (string memory) {
        return sevenNFT.getMetaData(_tokenId);
    }

    // ----------------------------------------------------------------------------------------------------------------
    // SENDS ----------------------------------------------------------------------------------------------------------
    // ----------------------------------------------------------------------------------------------------------------
    function putNftOnSale(
        uint256 _tokenId,
        uint256 _price,
        uint256 _amount
    ) external payable {
        require(sevenNFT.balanceOf(tx.origin, _tokenId) >= _amount, "insufficient balance");
        sevenNFT.safeTransferFrom(tx.origin, address(this), _tokenId, _amount, "0x00");
        saleList[sellId] = Sell(_tokenId, _price, block.timestamp, _amount, 0, tx.origin);
        userSaleCounter[tx.origin]++;
        emit PutOnSale(_tokenId, _price, sellId);
        sellId++;
    }

    function removeFromSellingList(
        uint256 _tokenId,
        uint256 _sellId,
        uint256 _amount
    ) public payable {
        require(saleList[_sellId].owner == tx.origin, "caller is not token owner");
        require(saleList[_sellId].amount >= _amount, "amount specified is higher than available NFT amount");
        require(saleList[_sellId].tokenId == _tokenId, "tokenId doesn't belong to this sale");

        sevenNFT.safeTransferFrom(address(this), msg.sender, _tokenId, _amount, "0x00");

        saleList[_sellId].amount = saleList[_sellId].amount - _amount;
    }

    function buyNFT(uint256 _sellId, uint256 _amount) public payable {
        address owner = saleList[_sellId].owner;
        uint256 price = saleList[_sellId].price;
        uint256 amount = saleList[_sellId].amount;
        uint256 tokenId = saleList[_sellId].tokenId;
        require(amount >= _amount && _amount > 0, "amount specified is higher than available NFT amount");
        require(price * _amount == msg.value, "Send value is not equal to NFT price");
        require(owner != msg.sender, "NFT already yours");

        tradeHistory[tradeId] = Trade(tokenId, owner, msg.sender, price, _amount, _sellId);
        isTokenTraded[tokenId] = true;

        saleList[_sellId].amount = saleList[_sellId].amount - _amount;
        saleList[_sellId].sold = saleList[_sellId].sold + _amount;

        userTradeCounter[msg.sender]++;
        userTradeCounter[owner]++;

        sevenNFT.safeTransferFrom(address(this), msg.sender, tokenId, _amount, "0x00");
        payable(owner).transfer(price * _amount);
        tradeId++;
    }

    function putOnAuction(
        uint256 _tokenId,
        uint256 _price,
        uint256 _amount,
        uint256 _expireTime
    ) external payable {
        require(sevenNFT.balanceOf(tx.origin, _tokenId) >= _amount, "insufficient balance");
        sevenNFT.safeTransferFrom(tx.origin, address(this), _tokenId, _amount, "0x00");
        auctionList[auctionId] = Auction(
            _tokenId,
            _price,
            block.timestamp,
            _expireTime,
            _amount,
            tx.origin,
            address(0),
            0,
            0,
            0,
            false
        );
        userAuctionCounter[tx.origin]++;
        auctionId++;
    }

    function bid(uint256 _auctionId) public payable {
        uint256 currentBid = auctionList[_auctionId].currentBid;
        address currentBidder = auctionList[_auctionId].currentBidder;

        require(tx.origin != auctionList[_auctionId].owner, "you can't bid yourself");
        require(block.timestamp < auctionList[_auctionId].expireTime, "bidding is over");
        require(msg.value >= auctionList[_auctionId].price, "bid is too low");
        if (currentBid > 0) {
            require(msg.value >= currentBid + bidDif, "the bid is not bigger than the current bid");
        }

        if (currentBid > 0) {
            payable(currentBidder).transfer(currentBid);
        }

        auctionList[_auctionId].currentBid = msg.value;
        auctionList[_auctionId].currentBidder = tx.origin;
        auctionList[_auctionId].currentBidTime = block.timestamp;
        auctionList[_auctionId].bidders++;
    }

    function resolveAuction(uint256 _auctionId) public {
        address owner = auctionList[_auctionId].owner;
        address bidder = auctionList[_auctionId].currentBidder;

        require(tx.origin == owner || tx.origin == bidder, "this auction is not related to you");
        require(auctionList[_auctionId].expireTime < block.timestamp, "auction is not ended");

        payable(owner).transfer(auctionList[_auctionId].currentBid);
        sevenNFT.safeTransferFrom(
            address(this),
            bidder,
            auctionList[_auctionId].tokenId,
            auctionList[_auctionId].amount,
            "0x00"
        );

        auctionList[_auctionId].claimed = true;
    }

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4) {
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }
}