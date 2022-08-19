// SPDX-License-Identifier:UNLICENSED
pragma experimental ABIEncoderV2;
pragma solidity ^0.8.4;
import "./IERC165.sol";
import "./IERC721.sol";
import "./IERC1155.sol";
import "./IERC20.sol";
import "./Ownable.sol";
 contract MarketPlace is Ownable{
    enum BuyType {ERC1155, ERC721}
    event BuyAsset(address indexed Owner , uint256 indexed tokenId, uint256 quantity, address indexed buyer);
    event ExecuteBid(address indexed Owner , uint256 indexed tokenId, uint256 quantity, address indexed buyer);
    uint8 private buyerFee;
    uint8 private sellerFee;
    address public Owner;
    struct Fee {
        uint platformFee;
        uint assetFee;
        uint royaltyFee;
        uint price;
        address tokenCreator;
    }
  
    struct Trade {
        address seller;
        address buyer;
        address erc20Address;
        address nftAddress;
        BuyType nftType;
        uint unitPrice;
        uint amount;
        uint tokenId;
        uint qty;
    }
    
    constructor (uint8 _buyerFee, uint8 _sellerFee) {
        buyerFee = _buyerFee;
        sellerFee = _sellerFee;
    }
    function buyerServiceFee() external view virtual returns (uint8) {
        return buyerFee;
    }
    function sellerServiceFee() external view virtual returns (uint8) {
        return sellerFee;
    }
    function setBuyerServiceFee(uint8 _buyerFee) onlyOwner external  returns(bool) {
        buyerFee = _buyerFee;
        return true;
    }
    function setSellerServiceFee(uint8 _sellerFee) onlyOwner external  returns(bool) {
        sellerFee = _sellerFee;
        return true;
    }
   
    
function Sell(Trade calldata trade, Fee memory fee, address buyer, address seller) internal {
      if(trade.nftType == BuyType.ERC721) {
            IERC721(trade.nftAddress).safeTransferFrom(seller, buyer, trade.tokenId);
        }
        if(trade.nftType == BuyType.ERC1155)  {
            IERC1155(trade.nftAddress).safeTransferFrom(seller, buyer, trade.tokenId, trade.qty, "");
        }
        if(fee.platformFee > 0) {
            IERC20(trade.erc20Address).transferFrom(buyer, Owner, fee.platformFee);
        }
        if(fee.royaltyFee > 0) {
            IERC20(trade.erc20Address).transferFrom(buyer, fee.tokenCreator, fee.royaltyFee);
        }
        IERC20(trade.erc20Address).transferFrom(buyer, seller, fee.assetFee);
    }


function getFees(BuyType buytype, address _nftAddress, uint _tokenId )internal view returns(Fee memory) {
    Trade memory trade;
         
            uint platformFee = (25*(trade.unitPrice))/1000;
            uint assetFee =(trade.unitPrice);
            uint royaltyFee = (10*(trade.unitPrice)/100);
            uint price =  (trade.unitPrice * trade.qty);
            //uint amount = price;
            address tokenCreator;
           if(buytype == BuyType.ERC721) {
            tokenCreator= IERC721(_nftAddress).getCreator(_tokenId);
        }
        if(buytype == BuyType.ERC1155) {
        tokenCreator= IERC1155(_nftAddress).getCreator(_tokenId);
        }
            return Fee(platformFee,assetFee,royaltyFee,price,tokenCreator);
          
          
   }   

    function buyAsset(Trade calldata trade) external returns(bool) {
       Fee memory fee  = getFees( trade.nftType, trade.nftAddress, trade.tokenId);
      //require((fee.price == trade.unitPrice * trade.qty), "Paid invalid amount");
        address buyer = msg.sender;
        Sell(trade, fee, buyer, trade.seller);
        emit BuyAsset(trade.seller, trade.tokenId, trade.qty, msg.sender);
        return true;
    }
      
// struct Auction {     
//       uint256 tokenId;
//       uint256 Price;
//       uint256 duration;
//       uint256 quantity;
//       bool result;
//     }

//     struct HighestBid {    
//       address payable bidder;
//       uint256 bid;
//       uint256 lastBidTime;
//     }
    
//   event HighestBidIncreased(address bidder, uint256 amount); 
//    mapping(uint256 => HighestBid) public highestBids;
//    mapping(uint256 => Auction) public auctions;
//    uint256 auctionStart;
//    Auction[] internal NumAuctions;
   
// function createAuction(Trade calldata trade, uint _biddingtime) public  {// what about buyer address in trade ???
//        require(trade.seller==msg.sender, "Not the Owner of NFT");
//       auctionStart = block.timestamp;
//     Auction memory auction = Auction({  
//         tokenId: trade.tokenId,
//         Price : trade.unitPrice,
//         duration : _biddingtime,
//         quantity : trade.qty,
//         result : true   
//     });
//     auctions[auction.tokenId] = auction;
//     NumAuctions.push(auction);     
//     }  

// function placeBid(uint256 _tokenId) external payable {  
//        if (block.timestamp > auctionStart + auctions[_tokenId].duration)
//             revert("Auction period has ended");
//            HighestBid storage highestBid = highestBids[_tokenId];
           
//             if (msg.value < highestBid.bid)
//             revert("Bid must be higher than current highest bid");

//         uint256 bidAmount = msg.value;     
//         // new bid
//         uint256 newBid= highestBid.bid += bidAmount;
//         if (highestBid.bidder != address(0)) {
//             refund(highestBid.bidder, highestBid.bid);//???
//         }
//         // updating highestBid
//         highestBid.bidder = payable(msg.sender);
//         highestBid.bid = newBid;
//         highestBid.lastBidTime = block.timestamp;

//        emit HighestBidIncreased(msg.sender, msg.value);
//     }

//     function finalize(Trade calldata trade) public {  
       
//         uint256 tokenId;
//         HighestBid storage highestBid = highestBids[tokenId];
//         address winner = highestBid.bidder;
//         if(trade.nftType == BuyType.ERC721) {
//             IERC20(trade.erc20Address).transferFrom(highestBid.bidder, trade.seller,highestBid.bid);
//             IERC721(trade.nftAddress).safeTransferFrom(trade.seller, winner, trade.tokenId);
//         }
//           if(trade.nftType == BuyType.ERC1155)  {
//             IERC20(trade.erc20Address).transferFrom(highestBid.bidder, trade.seller, highestBid.bid);
//              IERC1155(trade.nftAddress).safeTransferFrom(trade.seller, winner, trade.tokenId, trade.qty, "");
//         }
//     }

// function cancelAuction (uint256 _tokenId) public {
//    HighestBid storage highestBid = highestBids[_tokenId];
//             if (highestBid.bidder != address(0)) {            
//                 // Refunding to highest bidder
//                 refund(highestBid.bidder, highestBid.bid);
//                 delete highestBids[_tokenId];
//             }
//         delete auctions[_tokenId];
//    }


//    function refund(address payable _Bidder, uint256 _HighestBid) private {
        
//         (bool success,) = _Bidder.call{value : _HighestBid}("");
        
//         require(success);
//    }  

// function getAuctionDetails(uint _tokenId) public view returns(Auction memory)
// {
//     return auctions[_tokenId];
// }

}