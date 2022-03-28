// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

 import "./ERC721.sol";
 import "./Ownable.sol";

contract TestMarket721 is ERC721, Ownable {
    struct AuctionItem {
        uint256 id;
        address tokenAddress;
        uint256 tokenId;
        address payable seller;
        uint256 askingPrice;
        string collection;
        bool isSold;
    }

    AuctionItem[] public itemsForSale;
    address payable public _contractOwner;
    
    mapping (address => mapping (uint256 => bool)) activeItems;

    event itemAdded(uint256 id, uint256 tokenId, address tokenAddress, uint256 askingPrice,string collection, bool isSold);
    event itemSold(uint256 id,address buyer,address seller, uint256 tokenId, uint256 askingPrice);

    modifier OnlyItemOwner(address tokenAddress, uint256 tokenId) {
        IERC721 tokenContract = IERC721(tokenAddress);
        require(tokenContract.ownerOf(tokenId) == msg.sender);
        _;
    }

    modifier HasTransferApproval(address tokenAddress, uint256 tokenId) {
        IERC721 tokenContract = IERC721(tokenAddress);
        require(tokenContract.getApproved(tokenId) == address(this));
        _;
    }

    modifier ItemExists(uint256 id) {
        require(id < itemsForSale.length && itemsForSale[id].id == id, "Could not find the item");
        _;
    }

      modifier IsForSale(uint256 id) {
        require(itemsForSale[id].isSold == false, "Item is already sold");
        _;
    }

    constructor() ERC721("TEST", "TST") {
        _contractOwner = payable(msg.sender);
    }

    function addItemToMarket(uint256 tokenId, address tokenAddress, uint256 askingPrice,string memory collection) OnlyItemOwner(tokenAddress, tokenId) HasTransferApproval(tokenAddress, tokenId) external returns(uint256) {
        require(activeItems[tokenAddress][tokenId] == false, "Item is already up sale");
        uint256 newItemId = itemsForSale.length;
        bool isSold = false;
        itemsForSale.push(AuctionItem(newItemId, tokenAddress, tokenId, payable(msg.sender), askingPrice,collection, isSold));
        activeItems[tokenAddress][tokenId] = true;

        assert(itemsForSale[newItemId].id == newItemId);
        emit itemAdded(newItemId, tokenId, tokenAddress, askingPrice, collection, isSold);
        return newItemId;
    }


    function buyItem(uint256 id, address creator, uint256 royalty) payable external ItemExists(id) IsForSale(id) HasTransferApproval(itemsForSale[id].tokenAddress, itemsForSale[id].tokenId) {
        require(msg.value >= itemsForSale[id].askingPrice, "Not enough funds sent");
        require(msg.sender != itemsForSale[id].seller);

        address payable _buyer = payable(msg.sender);
        address payable _creator = payable(creator);

        itemsForSale[id].isSold = true;
        activeItems[itemsForSale[id].tokenAddress][itemsForSale[id].tokenId] = false; 


        //_commissionValue = itemsForSale[id].askingPrice / 20 ;
        //_sellerValue = itemsForSale[id].askingPrice - _commissionValue;
        //_royaltyToCreator = itemsForSale[id].askingPrice * royalty /10000


        IERC721(itemsForSale[id].tokenAddress).safeTransferFrom(itemsForSale[id].seller, msg.sender, itemsForSale[id].tokenId);
       
        //transfer funds to seller
        itemsForSale[id].seller.transfer(itemsForSale[id].askingPrice - ((itemsForSale[id].askingPrice / 20) + itemsForSale[id].askingPrice * royalty /10000));
        //transfer funds to contract owner
        _contractOwner.transfer(itemsForSale[id].askingPrice / 20);
        //transfer royalty finds to creator
        _creator.transfer(itemsForSale[id].askingPrice * royalty /10000);

        //  If buyer sent more than price, we send them back their rest of funds
        if (msg.value > itemsForSale[id].askingPrice) {
            _buyer.transfer(msg.value - itemsForSale[id].askingPrice);
        }

        emit itemSold(id, msg.sender,itemsForSale[id].seller,itemsForSale[id].tokenId, itemsForSale[id].askingPrice);
    }
}