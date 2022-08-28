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

    enum AuctionStatus {
        PENDING,
        CLAIMED,
        CANCELLED
    }

    struct Sell {
        uint256 tokenId;
        uint256 price;
        uint256 timestamp;
        uint256 amount;
        uint256 sold;
        address owner;
        uint256 sellerId;
    }

    struct Trade {
        uint256 time;
        uint256 tokenId;
        address seller;
        address buyer;
        uint256 price;
        uint256 amount;
        uint256 sellId;
        uint256 auctionId;
    }

    struct Auction {
        uint256 tokenId;
        uint256 price;
        uint256 addTime;
        uint256 expireTime;
        uint256 amount;
        address owner;
        address currentBidder;
        uint256 currentBidderId;
        uint256 currentBid;
        uint256 currentBidTime;
        uint256 bidders;
        AuctionStatus status;
        uint256 sellerId;
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
        uint256 currentBidderId;
        uint256 currentBid;
        uint256 currentBidTime;
        uint256 bidders;
        AuctionStatus status;
        uint256 sellerId;
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
        uint256 sellerId;
    }

    struct TradeView {
        uint256 time;
        uint256 tradeId;
        string metadata;
        uint256 tokenId;
        address seller;
        address buyer;
        uint256 price;
        uint256 amount;
        uint256 sellId;
        uint256 auctionId;
    }

    constructor(address sevenNFTAddress) {
        sevenNFT = ISevenNFT(sevenNFTAddress);
    }

    // Events
    event PutOnSale(uint256 saleId, uint256 timeStamp
    //, uint256 price, uint256 amount, uint256 tokenId
    );
    event PutOnAuction(uint256 auctionId, uint256 createTime
    //, uint256 price, uint256 expireTime, uint256 amount, uint tokenId
    );
    event Traded(uint256 tradeId);

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
                list.owner,
                list.sellerId
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
                    list.owner,
                    list.sellerId
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
                trade.time,
                i,
                sevenNFT.getMetaData(trade.tokenId),
                trade.tokenId,
                trade.seller,
                trade.buyer,
                trade.price,
                trade.amount,
                trade.sellId,
                trade.auctionId
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
                    trade.time,
                    i,
                    sevenNFT.getMetaData(trade.tokenId),
                    trade.tokenId,
                    trade.seller,
                    trade.buyer,
                    trade.price,
                    trade.amount,
                    trade.sellId,
                    trade.auctionId
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
                auction.currentBidderId,
                auction.currentBid,
                auction.currentBidTime,
                auction.bidders,
                auction.status,
                auction.sellerId
            );
        }
        return auctions;
    }

    function getUserAuctions(address _user) public view returns (AuctionView[] memory) {
        uint256 size = 0;
        for (uint256 i = 1; i <= auctionId; i++)
            if (auctionList[i].owner == _user || auctionList[i].currentBidder == _user)
                size++;

        AuctionView[] memory auctions = new AuctionView[](size);
        uint256 counter = 0;
        for (uint256 i = 1; i <= auctionId; i++) {
            if (auctionList[i].owner == _user || auctionList[i].currentBidder == _user) {
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
                    auction.currentBidderId,
                    auction.currentBid,
                    auction.currentBidTime,
                    auction.bidders,
                    auction.status,
                    auction.sellerId
                );
                counter++;
            }
        }
        return auctions;
    }

    function getTokenSaleList(uint256 _tokenId) public view returns (SellView[] memory) {
        uint256 arraySize = 0;
        for (uint256 i = 1; i < sellId; i++) {
            if (saleList[i].tokenId == _tokenId && saleList[i].amount > saleList[i].sold) {
                arraySize++;
            }
        }

        SellView[] memory listedItems = new SellView[](arraySize);
        uint256 index = 0;
        for (uint256 i = 1; i < sellId; i++) {
            if (saleList[i].tokenId == _tokenId && saleList[i].amount > saleList[i].sold) {
                Sell memory list = saleList[i];
                listedItems[index] = SellView(
                    i,
                    sevenNFT.getMetaData(list.tokenId),
                    list.tokenId,
                    list.price,
                    list.timestamp,
                    list.amount,
                    list.sold,
                    list.owner,
                    list.sellerId
                );
                index++;
            }
        }
        return listedItems;
    }

    function getTokenAuctionList(uint256 _tokenId) public view returns (AuctionView[] memory) {
        uint256 arraySize = 0;
        for (uint256 i = 1; i < auctionId; i++) {
            if (
                auctionList[i].tokenId == _tokenId //&&
            // auctionList[i].status == AuctionStatus.PENDING &&
            // auctionList[_tokenId].expireTime > block.timestamp
            ) {
                arraySize++;
            }
        }

        AuctionView[] memory auctions = new AuctionView[](arraySize);
        uint256 index = 0;
        for (uint256 i = 1; i < auctionId; i++) {
            if (
                auctionList[i].tokenId == _tokenId //&&
            // auctionList[i].status == AuctionStatus.PENDING &&
            // auctionList[_tokenId].expireTime > block.timestamp
            ) {
                Auction memory auction = auctionList[i];
                auctions[index] = AuctionView(
                    i,
                    auction.tokenId,
                    sevenNFT.getMetaData(auction.tokenId),
                    auction.price,
                    auction.addTime,
                    auction.expireTime,
                    auction.amount,
                    auction.owner,
                    auction.currentBidder,
                    auction.currentBidderId,
                    auction.currentBid,
                    auction.currentBidTime,
                    auction.bidders,
                    auction.status,
                    auction.sellerId
                );
                index++;
            }
        }
        return auctions;
    }

    function getTokenTradeList(uint256 _tokenId) public view returns (TradeView[] memory) {
        uint256 arraySize = 0;
        for (uint256 i = 1; i < tradeId; i++) {
            if (tradeHistory[i].tokenId == _tokenId) {
                arraySize++;
            }
        }

        TradeView[] memory userTrades = new TradeView[](arraySize);
        uint256 index = 0;
        for (uint256 i = 1; i < tradeId; i++) {
            if (tradeHistory[i].tokenId == _tokenId) {
                Trade memory trade = tradeHistory[i];
                userTrades[index] = TradeView(
                    trade.time,
                    i,
                    sevenNFT.getMetaData(trade.tokenId),
                    trade.tokenId,
                    trade.seller,
                    trade.buyer,
                    trade.price,
                    trade.amount,
                    trade.sellId,
                    trade.auctionId
                );
                index++;
            }
        }
        return userTrades;
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
        uint256 _amount,
        uint256 _sellerId
    ) external payable {
        require(sevenNFT.balanceOf(tx.origin, _tokenId) >= _amount, "insufficient balance");
        sevenNFT.safeTransferFrom(tx.origin, address(this), _tokenId, _amount, "0x00");
        saleList[sellId] = Sell(_tokenId, _price, block.timestamp, _amount, 0, tx.origin, _sellerId);
        userSaleCounter[tx.origin]++;
        emit PutOnSale(sellId, block.timestamp);
        sellId++;
    }

    function removeFromSellingList(
        uint256 _tokenId,
        uint256 _sellId,
        uint256 _amount
    ) public payable {
        require(saleList[_sellId].amount >= _amount, "amount specified is higher than available NFT amount");
        require(saleList[_sellId].tokenId == _tokenId, "tokenId doesn't belong to this sale");
        require(saleList[_sellId].owner == tx.origin, "caller is not token owner");

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

        tradeHistory[tradeId] = Trade(block.timestamp, tokenId, owner, msg.sender, price, _amount, _sellId, 0);
        isTokenTraded[tokenId] = true;
        emit Traded(tradeId);

        saleList[_sellId].amount = saleList[_sellId].amount - _amount;
        saleList[_sellId].sold = saleList[_sellId].sold + _amount;

        userTradeCounter[msg.sender]++;
        userTradeCounter[owner]++;

        sevenNFT.safeTransferFrom(address(this), msg.sender, tokenId, _amount, "0x00");

        uint256 royalty = (_amount * price * sevenNFT.getRoyalty(tokenId)) / 100;
        address minter = sevenNFT.getMinter(tokenId);

        payable(minter).transfer(royalty);
        payable(owner).transfer((price * _amount) - royalty);
        tradeId++;
    }

    function putOnAuction(
        uint256 _tokenId,
        uint256 _price,
        uint256 _amount,
        uint256 _expireTime,
        uint256 _sellerId
    ) external payable {
        require(sevenNFT.balanceOf(tx.origin, _tokenId) >= _amount, "insufficient balance");
        require(_expireTime >= block.timestamp, "expire time is passed");
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
            0,
            AuctionStatus.PENDING,
            _sellerId
        );
        userAuctionCounter[tx.origin]++;
        emit PutOnAuction(auctionId, block.timestamp);
        auctionId++;
    }

    function cancelAuction(uint256 _auctionId) public payable {
        require(auctionList[_auctionId].status == AuctionStatus.PENDING, "auction is not pending to resolve");
        require(msg.sender == auctionList[_auctionId].owner, "auction does not belong to you");
        require(block.timestamp < auctionList[_auctionId].expireTime, "auction is over");
        require(auctionList[_auctionId].bidders == 0, "can't cancel bidded auction");
        sevenNFT.safeTransferFrom(
            address(this),
            msg.sender,
            auctionList[_auctionId].tokenId,
            auctionList[_auctionId].amount,
            "0x00"
        );
        auctionList[_auctionId].status = AuctionStatus.CANCELLED;
    }

    function bid(uint256 _auctionId, uint256 _bidderId) public payable {
        uint256 currentBid = auctionList[_auctionId].currentBid;
        address currentBidder = auctionList[_auctionId].currentBidder;

        require(block.timestamp < auctionList[_auctionId].expireTime, "auction is over");
        require(tx.origin != auctionList[_auctionId].owner, "you can't bid yourself");
        require(msg.value >= auctionList[_auctionId].price, "bid is too low");
        if (currentBid > 0) {
            require(msg.value >= currentBid + bidDif, "the bid is not bigger than the current bid");
        }

        if (currentBid > 0) {
            payable(currentBidder).transfer(currentBid);
        }

        auctionList[_auctionId].currentBid = msg.value;
        auctionList[_auctionId].currentBidder = tx.origin;
        auctionList[_auctionId].currentBidderId = _bidderId;
        auctionList[_auctionId].currentBidTime = block.timestamp;
        auctionList[_auctionId].bidders++;
    }

    function resolveAuction(uint256 _auctionId) public {
        address owner = auctionList[_auctionId].owner;
        address bidder = auctionList[_auctionId].currentBidder;
        uint256 tokenId = auctionList[_auctionId].tokenId;
        uint256 amount = auctionList[_auctionId].amount;
        uint256 bid = auctionList[_auctionId].currentBid;

        require(auctionList[_auctionId].status == AuctionStatus.PENDING, "auction is not pending to resolve");
        require(tx.origin == owner || tx.origin == bidder, "this auction is not related to you");
        require(auctionList[_auctionId].expireTime < block.timestamp, "auction is not ended");

        if (auctionList[_auctionId].bidders == 0) {
            sevenNFT.safeTransferFrom(address(this), owner, tokenId, amount, "0x00");
        } else {
            uint256 price = bid;
            uint256 royalty = (price * sevenNFT.getRoyalty(tokenId)) / 100;
            address minter = sevenNFT.getMinter(tokenId);

            payable(minter).transfer(royalty);
            payable(owner).transfer(price - royalty);
            // payable(owner).transfer(bid);

            sevenNFT.safeTransferFrom(address(this), bidder, tokenId, amount, "0x00");
            tradeHistory[tradeId] = Trade(block.timestamp, tokenId, owner, bidder, bid, amount, 0, _auctionId);
            emit Traded(tradeId);
            tradeId++;
        }
        auctionList[_auctionId].status = AuctionStatus.CLAIMED;
    }

    function addTrade(uint256 _tokenId, uint256 _amount) external {
        tradeHistory[tradeId] = Trade(
            block.timestamp,
            _tokenId,
            0x0000000000000000000000000000000000000000,
            tx.origin,
            0,
            _amount,
            0,
            0
        );
        emit Traded(tradeId);
        tradeId++;
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