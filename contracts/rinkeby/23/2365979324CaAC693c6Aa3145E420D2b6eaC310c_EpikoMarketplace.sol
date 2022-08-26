//SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

import "./interfaces/IERC721Minter.sol";
import "./interfaces/IERC1155Minter.sol";
import "./interfaces/IMarket.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract EpikoMarketplace is IMarket, Ownable {
    IERC1155Minter private epikoErc1155;
    IERC721Minter private epikoErc721;

    uint256 private _buyTax = 110; //divide by 100
    uint256 private _sellTax = 110; //divide by 100
    uint256 private constant PERCENTAGE_DENOMINATOR = 10000;
    address private mediaContract;
    bytes4 private constant ERC721INTERFACEID = 0x80ac58cd; // Interface Id of ERC721
    bytes4 private constant ERC1155INTERFACEID = 0xd9b67a26; // Interface Id of ERC1155
    bytes4 private constant ROYALTYINTERFACEID = 0x2a55205a; // interface Id of Royalty

    /// @dev mapping from NFT contract to user address to tokenId is item on auction check
    mapping(address => mapping(address => mapping(uint256 => bool)))
        private itemIdOnAuction;
    /// @dev mapping from NFT contract to user address to tokenId is item on sale check
    mapping(address => mapping(address => mapping(uint256 => bool)))
        private itemIdOnSale;
    /// @dev Mapping from Nft contract to tokenId to Auction structure
    mapping(address => mapping(address => mapping(uint256 => Auction)))
        public nftAuctionItem;
    /// @dev Mapping from Nft contract to tokenId to Sale structure
    mapping(address => mapping(address => mapping(uint256 => Sale)))
        public nftSaleItem;
    /// @dev Mapping from NFT contract to tokenId to bidders address
    mapping(address => mapping(uint256 => address[])) private bidderList;
    /// @dev mapping from NFT conntract to tokenid to bidder address to bid value
    mapping(address => mapping(uint256 => mapping(address => uint256)))
        private fundsByBidder;

    /// @dev mapping from Nft contract to tokenId to bid array
    mapping(address => mapping(uint256 => Bid[])) private bidAndValue;

    constructor() Ownable() {}

    fallback() external {}

    receive() external payable {}

    function onlyMedia() internal view {
        require(msg.sender == mediaContract, "Market: unauthorized Access");
    }

    function configureMedia(address _mediaContract) external onlyOwner {
        require(
            _mediaContract != address(0),
            "Market: Media address is invalid"
        );
        require(
            mediaContract == address(0),
            "Market: Media is already configured"
        );
        mediaContract = _mediaContract;
    }

    /* Places item for sale on the marketplace */
    function sellitem(
        address nftAddress,
        address erc20Token,
        address seller,
        uint256 tokenId,
        uint256 amount,
        uint256 price
    ) external override {
        onlyMedia();

        Sale storage sale = nftSaleItem[nftAddress][seller][tokenId];

        require(
            !itemIdOnSale[nftAddress][seller][tokenId],
            "Market: Nft already on Sale"
        );
        require(
            !itemIdOnAuction[nftAddress][seller][tokenId],
            "Market: Nft already on Auction"
        );
        sale.tokenId = tokenId;
        sale.price = price;
        sale.seller = seller;
        sale.erc20Token = erc20Token;
        sale.quantity = amount;
        sale.time = block.timestamp;

        itemIdOnSale[nftAddress][seller][tokenId] = true;

        emit MarketItemCreated(nftAddress, msg.sender, price, tokenId, amount);
    }

    /* Place buy order for Multiple item on marketplace */
    function buyItem(
        address nftAddress,
        address seller,
        address buyer,
        uint256 tokenId,
        uint256 quantity
    ) external payable override {
        onlyMedia();

        Sale storage sale = nftSaleItem[nftAddress][seller][tokenId];
        require(
            quantity <= sale.quantity,
            "Market: not enough quantity available"
        );
        validSale(nftAddress, seller, tokenId);

        uint256 price = sale.price;

        // ItemForSellOrForAuction storage sellItem = _itemOnSellAuction[tokenId][seller];

        if (IERC721(nftAddress).supportsInterface(ERC721INTERFACEID)) {
            uint256 totalNftValue = price * quantity;

            if (!IERC721(nftAddress).supportsInterface(ROYALTYINTERFACEID)) {
                _transferTokens(
                    totalNftValue,
                    0,
                    sale.seller,
                    buyer,
                    address(0),
                    sale.erc20Token
                );
                IERC721(nftAddress).transferFrom(
                    sale.seller,
                    buyer,
                    sale.tokenId
                );
            } else {
                (address user, uint256 royaltyAmount) = IERC2981(nftAddress)
                    .royaltyInfo(sale.tokenId, totalNftValue);
                _transferTokens(
                    totalNftValue,
                    royaltyAmount,
                    sale.seller,
                    buyer,
                    user,
                    sale.erc20Token
                );
                IERC721(nftAddress).transferFrom(
                    sale.seller,
                    buyer,
                    sale.tokenId
                );
            }

            sale.sold = true;
            itemIdOnSale[nftAddress][seller][tokenId] = false;

            delete nftSaleItem[nftAddress][seller][tokenId];
            // sellItem.onSell = false;
            emit Buy(seller, buyer, price, tokenId, sale.quantity);
        } else if (
            IERC1155Minter(nftAddress).supportsInterface(ERC1155INTERFACEID)
        ) {
            uint256 totalNftValue = price * quantity;

            if (!IERC1155(nftAddress).supportsInterface(ROYALTYINTERFACEID)) {
                _transferTokens(
                    totalNftValue,
                    0,
                    sale.seller,
                    buyer,
                    address(0),
                    sale.erc20Token
                );
                IERC1155(nftAddress).safeTransferFrom(
                    sale.seller,
                    buyer,
                    sale.tokenId,
                    quantity,
                    ""
                );
                sale.quantity -= quantity;
            } else {
                (address user, uint256 royaltyAmount) = IERC2981(nftAddress)
                    .royaltyInfo(sale.tokenId, totalNftValue);
                _transferTokens(
                    totalNftValue,
                    royaltyAmount,
                    sale.seller,
                    buyer,
                    user,
                    sale.erc20Token
                );
                IERC1155(nftAddress).safeTransferFrom(
                    sale.seller,
                    buyer,
                    sale.tokenId,
                    quantity,
                    ""
                );
                sale.quantity -= quantity;
            }

            if (sale.quantity == 0) {
                sale.sold = true;
                itemIdOnSale[nftAddress][seller][tokenId] = false;
                delete nftSaleItem[nftAddress][seller][tokenId];
            }
            // sellItem.onSell = false;
            emit Buy(seller, buyer, price, tokenId, quantity);
        } else {
            revert("Market: Token not exist");
        }
    }

    /* Create Auction for item on marketplace */
    function createAuction(
        address nftAddress,
        address erc20Token,
        address seller,
        uint256 tokenId,
        uint256 amount,
        uint256 basePrice,
        uint256 endTime
    ) external override {
        onlyMedia();

        require(
            !itemIdOnSale[nftAddress][seller][tokenId],
            "Market: NFT already on sale"
        );
        require(
            !itemIdOnAuction[nftAddress][seller][tokenId],
            "Market: NFT already on auction"
        );

        uint256 startTime = block.timestamp;

        Auction storage auction = nftAuctionItem[nftAddress][seller][tokenId];

        if (IERC721(nftAddress).supportsInterface(ERC721INTERFACEID)) {
            require(!auction.sold, "Market: Already on sell");
            require(
                IERC721(nftAddress).ownerOf(tokenId) == seller,
                "Market: not nft owner"
            );
            require(
                IERC721(nftAddress).getApproved(tokenId) == address(this),
                "Market: nft not approved for auction"
            );

            _addItemtoAuction(
                nftAddress,
                erc20Token,
                tokenId,
                amount,
                basePrice,
                startTime,
                endTime,
                seller
            );
            emit AuctionCreated(
                nftAddress,
                tokenId,
                seller,
                basePrice,
                amount,
                startTime,
                endTime
            );
        } else if (IERC1155(nftAddress).supportsInterface(ERC1155INTERFACEID)) {
            require(!auction.sold, "Market: Already on sell");
            require(
                IERC1155(nftAddress).balanceOf(seller, tokenId) >= amount,
                "Market: Not enough nft Balance"
            );
            require(
                IERC1155(nftAddress).isApprovedForAll(seller, address(this)),
                "Market: NFT not approved for auction"
            );

            _addItemtoAuction(
                nftAddress,
                erc20Token,
                tokenId,
                amount,
                basePrice,
                startTime,
                endTime,
                seller
            );
            emit AuctionCreated(
                nftAddress,
                tokenId,
                seller,
                basePrice,
                amount,
                startTime,
                endTime
            );
        } else {
            revert("Market: Token not Exist");
        }
    }

    /* Place bid for item  on marketplace */
    function placeBid(
        address nftAddress,
        address bidder,
        address seller,
        uint256 tokenId,
        uint256 price
    ) external payable override {
        onlyMedia();

        Auction storage auction = nftAuctionItem[nftAddress][seller][tokenId];
        validAuction(nftAddress, seller, tokenId);

        require(auction.endTime > block.timestamp, "Market: Auction ended");
        require(
            auction.startTime < block.timestamp,
            "Market: Auction not started"
        );
        require(
            price >= auction.basePrice && price > auction.highestBid.bid,
            "Market: place highest bid"
        );
        require(auction.seller != bidder, "Market: seller not allowed");

        if (auction.erc20Token != address(0)) {
            require(
                IERC20(auction.erc20Token).allowance(bidder, address(this)) >=
                    price,
                "Market: please proivde asking price"
            );
            IERC20(auction.erc20Token).transferFrom(
                bidder,
                address(this),
                price
            );
        } else {
            require(msg.value >= price, "Market: please proivde asking price");
        }

        auction.highestBid.bid = price;
        auction.highestBid.bidder = bidder;
        // fundsByBidder[nftAddress][tokenId][bidder] = price;
        // bidAndValue[nftAddress][tokenId].push(Bid(bidder, price));
        auction.bids.push(Bid(bidder, price));

        emit PlaceBid(nftAddress, bidder, price, tokenId);
    }

    /* To Approve bid*/
    function approveBid(
        address nftAddress,
        address seller,
        uint256 tokenId,
        address bidder
    ) external override {
        onlyMedia();

        Auction storage auction = nftAuctionItem[nftAddress][seller][tokenId];
        validAuction(nftAddress, seller, tokenId);

        // require(
        //     fundsByBidder[nftAddress][tokenId][bidder] != 0,
        //     "Market: bidder not found"
        // );
        require(
            getBidAndBidder(auction, bidder) != 0,
            "Market: bidder not found"
        );
        require(auction.endTime > block.timestamp, "Market: Auction ended");
        require(
            auction.startTime < block.timestamp,
            "Market: Auction not started"
        );
        require(auction.seller == seller, "Market: not authorised");
        require(auction.tokenId == tokenId, "Market: Auction not found");

        uint256 bidderValue = getBidAndBidder(auction, bidder);
        // uint256 bidderValue = fundsByBidder[nftAddress][tokenId][bidder];

        if (IERC721(nftAddress).supportsInterface(ERC721INTERFACEID)) {
            if (!IERC721(nftAddress).supportsInterface(ROYALTYINTERFACEID)) {
                _tokenDistribute(
                    auction,
                    bidderValue,
                    0,
                    auction.seller,
                    address(0),
                    bidder,
                    auction.erc20Token
                );
                IERC721(nftAddress).transferFrom(
                    auction.seller,
                    bidder,
                    auction.tokenId
                );
            } else {
                (address user, uint256 amount) = IERC2981(nftAddress)
                    .royaltyInfo(auction.tokenId, bidderValue);
                _tokenDistribute(
                    auction,
                    bidderValue,
                    amount,
                    auction.seller,
                    user,
                    bidder,
                    auction.erc20Token
                );
                IERC721(nftAddress).transferFrom(
                    auction.seller,
                    bidder,
                    auction.tokenId
                );
            }

            auction.sold = true;
            itemIdOnAuction[nftAddress][auction.seller][tokenId] = false;
            emit Buy(
                auction.seller,
                bidder,
                bidderValue,
                tokenId,
                auction.quantity
            );

            delete nftAuctionItem[nftAddress][seller][tokenId];
        } else if (IERC1155(nftAddress).supportsInterface(ERC1155INTERFACEID)) {
            if (!IERC721(nftAddress).supportsInterface(ROYALTYINTERFACEID)) {
                _tokenDistribute(
                    auction,
                    bidderValue,
                    0,
                    auction.seller,
                    address(0),
                    bidder,
                    auction.erc20Token
                );
                IERC1155(nftAddress).safeTransferFrom(
                    auction.seller,
                    bidder,
                    auction.tokenId,
                    auction.quantity,
                    ""
                );
            } else {
                (address user, uint256 amount) = IERC2981(nftAddress)
                    .royaltyInfo(auction.tokenId, bidderValue);
                _tokenDistribute(
                    auction,
                    bidderValue,
                    amount,
                    auction.seller,
                    user,
                    bidder,
                    auction.erc20Token
                );
                IERC1155(nftAddress).safeTransferFrom(
                    auction.seller,
                    bidder,
                    auction.tokenId,
                    auction.quantity,
                    ""
                );
            }

            auction.sold = true;
            itemIdOnAuction[nftAddress][auction.seller][tokenId] = false;
            emit Buy(
                auction.seller,
                bidder,
                bidderValue,
                tokenId,
                auction.quantity
            );

            delete nftAuctionItem[nftAddress][seller][tokenId];
        } else {
            revert("Market: NFT not supported");
        }
    }

    /* To Claim NFT bid*/
    function claimNft(
        address nftAddress,
        address bidder,
        address seller,
        uint256 tokenId
    ) external override {
        onlyMedia();

        Auction storage auction = nftAuctionItem[nftAddress][seller][tokenId];

        require(nftAddress != address(0), "Market: address zero given");
        require(tokenId > 0, "Market: not valid nft id");
        require(auction.endTime < block.timestamp, "Market: Auction not ended");
        require(
            auction.highestBid.bidder == bidder,
            "Market: Only highest bidder can claim"
        );

        uint256 bidderValue = getBidAndBidder(auction, bidder);
        // uint256 bidderValue = fundsByBidder[nftAddress][tokenId][bidder];

        if (IERC721(nftAddress).supportsInterface(ERC721INTERFACEID)) {
            if (!IERC721(nftAddress).supportsInterface(ROYALTYINTERFACEID)) {
                _tokenDistribute(
                    auction,
                    bidderValue,
                    0,
                    auction.seller,
                    address(0),
                    bidder,
                    auction.erc20Token
                );
                IERC721(nftAddress).transferFrom(
                    auction.seller,
                    bidder,
                    auction.tokenId
                );
            } else {
                (address user, uint256 amount) = IERC2981(nftAddress)
                    .royaltyInfo(auction.tokenId, bidderValue);
                _tokenDistribute(
                    auction,
                    bidderValue,
                    amount,
                    auction.seller,
                    user,
                    bidder,
                    auction.erc20Token
                );
                IERC721(nftAddress).transferFrom(
                    auction.seller,
                    bidder,
                    auction.tokenId
                );
            }

            auction.sold = true;
            itemIdOnAuction[nftAddress][auction.seller][tokenId] = false;
            emit Buy(
                auction.seller,
                bidder,
                bidderValue,
                tokenId,
                auction.quantity
            );

            delete nftAuctionItem[nftAddress][seller][tokenId];
        } else if (IERC1155(nftAddress).supportsInterface(ERC1155INTERFACEID)) {
            if (!IERC721(nftAddress).supportsInterface(ROYALTYINTERFACEID)) {
                _tokenDistribute(
                    auction,
                    bidderValue,
                    0,
                    auction.seller,
                    address(0),
                    bidder,
                    auction.erc20Token
                );
                IERC1155(nftAddress).safeTransferFrom(
                    auction.seller,
                    bidder,
                    auction.tokenId,
                    auction.quantity,
                    ""
                );
            } else {
                (address user, uint256 amount) = IERC2981(nftAddress)
                    .royaltyInfo(auction.tokenId, bidderValue);
                _tokenDistribute(
                    auction,
                    bidderValue,
                    amount,
                    auction.seller,
                    user,
                    bidder,
                    auction.erc20Token
                );
                IERC1155(nftAddress).safeTransferFrom(
                    auction.seller,
                    bidder,
                    auction.tokenId,
                    auction.quantity,
                    ""
                );
            }

            auction.sold = true;
            itemIdOnAuction[nftAddress][auction.seller][tokenId] = false;
            emit Buy(
                auction.seller,
                bidder,
                bidderValue,
                tokenId,
                auction.quantity
            );

            delete nftAuctionItem[nftAddress][seller][tokenId];
        } else {
            revert("Market: NFT not supported");
        }
    }

    /* To cancel Auction */
    function cancelAuction(
        address nftAddress,
        address seller,
        uint256 tokenId
    ) external override {
        onlyMedia();

        Auction storage auction = nftAuctionItem[nftAddress][seller][tokenId];
        require(
            auction.seller == seller || owner() == seller,
            "Market: only seller or owner can cancel sell"
        );
        validAuction(nftAddress, seller, tokenId);

        require(auction.endTime > block.timestamp, "Market: Auction ended");
        require(!auction.sold, "Market: Already sold");

        if (auction.highestBid.bid > 0) {
            for (uint256 index = auction.bids.length - 1; index >= 0; index--) {
                IERC20(auction.erc20Token).transfer(
                    auction.bids[index].bidder,
                    auction.bids[index].bid
                );
                delete auction.bids[index];
                // bidAndValue[nftAddress][tokenId][index] = bidAndValue[nftAddress][tokenId][bidAndValue[nftAddress][tokenId].length - 1];
                auction.bids.pop();
                if (index == 0) {
                    break;
                }
            }
        }
        delete nftAuctionItem[nftAddress][seller][tokenId];
        itemIdOnAuction[nftAddress][seller][tokenId] = false;
    }

    /* To cancel sell */
    function cancelSell(
        address nftAddress,
        address seller,
        uint256 tokenId
    ) external override {
        onlyMedia();

        Sale storage sale = nftSaleItem[nftAddress][seller][tokenId];

        require(
            (sale.seller == seller) || owner() == seller,
            "Market: Only seller or owner can cancel sell"
        );
        validSale(nftAddress, seller, tokenId);

        require(
            !nftSaleItem[nftAddress][seller][tokenId].sold,
            "Market: NFT Sold"
        );

        delete nftSaleItem[nftAddress][seller][tokenId];
        itemIdOnSale[nftAddress][seller][tokenId] = false;
    }

    // function unsafe_inc(uint256 i) private pure returns (uint256) {
    //     unchecked {
    //         return i + 1;
    //     }
    // }

    /* To cancel auction bid */
    function cancelBid(
        address nftAddress,
        address bidder,
        address seller,
        uint256 tokenId
    ) external override {
        onlyMedia();

        Auction storage auction = nftAuctionItem[nftAddress][seller][tokenId];

        require(
            nftAuctionItem[nftAddress][seller][tokenId].endTime >
                block.timestamp,
            "Market: Auction ended"
        );
        require(
            getBidAndBidder(auction, bidder) > 0,
            "Market: not bided on auction"
        );
        // require(
        //     fundsByBidder[nftAddress][tokenId][bidder] > 0,
        //     "Market: not bided on auction"
        // );
        // uint256 bidLength = bidAndValue[nftAddress][tokenId].length;
        uint256 bidLength = auction.bids.length;
        for (uint256 index = 0; index < bidLength; index++) {
            if (auction.bids[index].bidder == bidder) {
                if (auction.erc20Token != address(0)) {
                    IERC20(auction.erc20Token).transfer(
                        auction.bids[index].bidder,
                        auction.bids[index].bid
                    );
                } else {
                    payable(auction.bids[index].bidder).transfer(
                        auction.bids[index].bid
                    );
                }

                delete auction.bids[index];
                auction.bids[index].bidder = auction.bids[bidLength - 1].bidder;
                auction.bids[index].bid = auction.bids[bidLength - 1].bid;
                auction.bids.pop();
                if (auction.highestBid.bidder == bidder) {
                    auction.highestBid.bidder = auction
                        .bids[auction.bids.length - 1]
                        .bidder;
                    auction.highestBid.bid = auction
                        .bids[auction.bids.length - 1]
                        .bid;
                }
                // bidAndValue[nftAddress][tokenId].pop();
                break;
            }
        }
        if (bidLength < 1) {
            auction.highestBid.bidder = address(0);
            auction.highestBid.bid = 0;
        }

        emit CancelBid(tokenId, seller, bidder);
    }

    /* To check list of bidder */
    // function checkBidderList(address nftAddress, uint256 tokenId)
    //     external
    //     view
    //     returns (Bid[] memory bid)
    // {
    //     require(tokenId > 0, "Market: not valid id");

    //     return bidAndValue[nftAddress][tokenId];
    // }

    /* To transfer nfts from `from` to `to` */
    function transfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount
    ) external {
        require(to != address(0), "Market: Transfer to zero address");
        require(from != address(0), "Market: Transfer from zero address");
        require(tokenId > 0, "Market: Not valid tokenId");

        if (epikoErc721._isExist(tokenId)) {
            epikoErc721.transferFrom(from, to, tokenId);
        } else if (epikoErc1155._isExist(tokenId)) {
            epikoErc1155.safeTransferFrom(from, to, tokenId, amount, "");
        }
    }

    /* owner can set selltax(fees) */
    function setSellTax(uint256 percentage) external onlyOwner {
        require(
            percentage <= PERCENTAGE_DENOMINATOR,
            "Market: percentage must be less than 100"
        );
        _sellTax = percentage;
    }

    /* owner can set buytax(fees) */
    function setBuyTax(uint256 percentage) external onlyOwner {
        require(
            percentage <= PERCENTAGE_DENOMINATOR,
            "Market: percentage must be less than 100"
        );
        _buyTax = percentage;
    }

    function getBuyTax() public view returns (uint256) {
        return _buyTax;
    }

    function getSellTax() public view returns (uint256) {
        return _sellTax;
    }

    function getBidAndBidder(Auction memory auction, address bidder)
        internal
        pure
        returns (uint256 bid)
    {
        for (uint256 index = 0; index < auction.bids.length; index++) {
            if (auction.bids[index].bidder == bidder) {
                return auction.bids[index].bid;
            }
        }
    }

    function _transferTokens(
        uint256 price,
        uint256 royaltyAmount,
        address _seller,
        address _buyer,
        address royaltyReceiver,
        address token
    ) private {
        uint256 amountForOwner;
        // uint256 buyingValue = price.add(price.mul(_sellTax)).div(PERCENTAGE_DENOMINATOR);
        uint256 buyingValue = price +
            (price * _sellTax) /
            PERCENTAGE_DENOMINATOR;
        uint256 amountForSeller = price -
            (price * _buyTax) /
            PERCENTAGE_DENOMINATOR;
        amountForOwner = buyingValue - amountForSeller;

        if (token != address(0)) {
            require(
                IERC20(token).allowance(_buyer, address(this)) >= buyingValue,
                "Market: please proivde asking price"
            );
            IERC20(token).transferFrom(_buyer, address(this), buyingValue);
            IERC20(token).transfer(owner(), amountForOwner);
            IERC20(token).transfer(_seller, amountForSeller - royaltyAmount);
            if (royaltyReceiver != address(0)) {
                IERC20(token).transfer(royaltyReceiver, royaltyAmount);
            }
        } else {
            require(msg.value >= buyingValue, "Market: Provide asking price");

            payable(owner()).transfer(amountForOwner);
            payable(_seller).transfer(amountForSeller - royaltyAmount);
            if (royaltyReceiver != address(0)) {
                payable(royaltyReceiver).transfer(royaltyAmount);
            }
        }
    }

    function _tokenDistribute(
        Auction memory auction,
        uint256 price,
        uint256 _amount,
        address _seller,
        address royaltyReceiver,
        address _bidder,
        address token
    ) private {
        uint256 amountForOwner;
        uint256 amountForSeller = price -
            ((price * (_buyTax + _sellTax)) / PERCENTAGE_DENOMINATOR);
        // uint256 amountForSeller = price.sub(price.mul(_buyTax.add(_sellTax))).div(PERCENTAGE_DENOMINATOR);

        amountForOwner = price - amountForSeller;
        amountForSeller = amountForSeller - _amount;

        if (token != address(0)) {
            IERC20(token).transfer(owner(), amountForOwner);
            IERC20(token).transfer(_seller, amountForSeller);

            if (royaltyReceiver != address(0)) {
                IERC20(token).transfer(royaltyReceiver, _amount);
            }
        } else {
            if (royaltyReceiver != address(0)) {
                payable(royaltyReceiver).transfer(_amount);
            }
        }

        for (uint256 index = 0; index < auction.bids.length; index++) {
            if (auction.bids[index].bidder != _bidder) {
                if (token != address(0)) {
                    IERC20(token).transfer(
                        auction.bids[index].bidder,
                        auction.bids[index].bid
                    );
                } else {
                    payable(auction.bids[index].bidder).transfer(
                        auction.bids[index].bid
                    );
                }
            }
        }
    }

    function _addItemtoAuction(
        address nftAddress,
        address erc20Token,
        uint256 tokenId,
        uint256 _amount,
        uint256 basePrice,
        uint256 startTime,
        uint256 endTime,
        address _seller
    ) private {
        Auction storage auction = nftAuctionItem[nftAddress][_seller][tokenId];

        auction.nftContract = nftAddress;
        auction.erc20Token = erc20Token;
        auction.tokenId = tokenId;
        auction.basePrice = basePrice;
        auction.seller = _seller;
        auction.quantity = _amount;
        auction.time = block.timestamp;
        auction.startTime = startTime;
        auction.endTime = endTime;

        itemIdOnAuction[nftAddress][_seller][tokenId] = true;
    }

    function revokeAuction(
        address nftAddress,
        address seller,
        uint256 tokenId
    ) external override {
        onlyMedia();
        validAuction(nftAddress, seller, tokenId);
        require(
            nftAuctionItem[nftAddress][seller][tokenId].endTime <
                block.timestamp,
            "Auction is not ended"
        );
        require(
            nftAuctionItem[nftAddress][seller][tokenId].highestBid.bid == 0,
            "Revoke not Allowed"
        );

        itemIdOnAuction[nftAddress][seller][tokenId] = false;
    }

    function validAuction(
        address nftAddress,
        address seller,
        uint256 tokenId
    ) internal view {
        require(
            itemIdOnAuction[nftAddress][seller][tokenId],
            "Market: NFT not on sale"
        );
    }

    function validSale(
        address nftAddress,
        address seller,
        uint256 tokenId
    ) internal view {
        require(
            itemIdOnSale[nftAddress][seller][tokenId],
            "Market: NFT not on sale"
        );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

interface IMarket {
    struct Sale {
        uint256 itemId;
        uint256 tokenId;
        uint256 price;
        uint256 quantity;
        uint256 time;
        address nftContract;
        address erc20Token;
        address buyer;
        address seller;
        bool sold;
    }

    struct Auction {
        uint256 itemId;
        uint256 tokenId;
        uint256 startTime;
        uint256 endTime;
        uint256 basePrice;
        uint256 quantity;
        uint256 time;
        Bid[] bids;
        address seller;
        address nftContract;
        address erc20Token;
        bool sold;
        Bid highestBid;
    }

    struct Bid {
        address bidder;
        uint256 bid;
    }

    event Mint(address from, address to, uint256 indexed tokenId);
    event PlaceBid(
        address nftAddress,
        address bidder,
        uint256 price,
        uint256 tokenId
    );
    event MarketItemCreated(
        address indexed nftAddress,
        address indexed seller,
        uint256 price,
        uint256 indexed tokenId,
        uint256 quantity
    );
    event Buy(
        address indexed seller,
        address bidder,
        uint256 indexed price,
        uint256 indexed tokenId,
        uint256 quantity
    );
    event AuctionCreated(
        address indexed nftAddress,
        uint256 indexed tokenId,
        address indexed seller,
        uint256 price,
        uint256 quantity,
        uint256 startTime,
        uint256 endTime
    );
    event CancelBid(
        uint256 indexed tokenId,
        address indexed seller,
        address indexed bidder
    );

    function sellitem(
        address nftAddress,
        address erc20Token,
        address seller,
        uint256 tokenId,
        uint256 amount,
        uint256 price
    ) external;

    function buyItem(
        address nftAddress,
        address seller,
        address buyer,
        uint256 tokenId,
        uint256 quantity
    ) external payable;

    function createAuction(
        address nftAddress,
        address erc20Token,
        address seller,
        uint256 tokenId,
        uint256 amount,
        uint256 basePrice,
        uint256 endTime
    ) external;

    function placeBid(
        address nftAddress,
        address bidder,
        address seller,
        uint256 tokenId,
        uint256 price
    ) external payable;

    function approveBid(
        address nftAddress,
        address seller,
        uint256 tokenId,
        address bidder
    ) external;

    function claimNft(
        address nftAddress,
        address bidder,
        address seller,
        uint256 tokenId
    ) external;

    function cancelBid(
        address nftAddress,
        address _bidder,
        address seller,
        uint256 tokenId
    ) external;

    function cancelSell(
        address nftAddress,
        address seller,
        uint256 tokenId
    ) external;

    function cancelAuction(
        address nftAddress,
        address seller,
        uint256 tokenId
    ) external;

    function revokeAuction(
        address nftAddress,
        address seller,
        uint256 tokenId
    ) external;
}

//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/interfaces/IERC1155.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";

interface IERC1155Minter is IERC1155,IERC2981{
    function getArtist(uint256 tokenId) external view returns(address);
    function burn(address from, uint256 id, uint256 amounts) external; 
    function mint(address to, uint256 amount, uint256 _royaltyFraction, string memory uri,bytes memory data)external returns(uint256);
    function _isExist(uint256 tokenId) external returns(bool);
}

//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";

interface IERC721Minter is IERC721,IERC2981{
    function mint(address to, uint256 royaltyFraction, string memory _uri)external returns(uint256);
    function burn(uint256 tokenId) external;
    function _isExist(uint256 tokenId)external view returns(bool);
    function isApprovedOrOwner(address spender, uint256 tokenId)external view returns(bool);
    function getArtist(uint256 tokenId)external view returns(address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1155.sol)

pragma solidity ^0.8.0;

import "../token/ERC1155/IERC1155.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

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
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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