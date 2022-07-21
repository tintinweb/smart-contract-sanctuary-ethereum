// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./ERC721.sol";
import "./ERC20.sol";
import "./ReentrancyGuard.sol";
import "./Owned.sol";

error InsufficientBalance();
error ItemUnavailable();
error BadTransfer();
error ItemNotListed();
error WrongContract();
error ItemDelisted();
error IncorrectOwner();

contract InvaderMarketplace is ReentrancyGuard, Owned {
    uint256 public listedItems;
    uint256 public soldItems;
    ERC20 public spaceContract;

    constructor(address _spaceContract) Owned(msg.sender) {
        spaceContract = ERC20(_spaceContract);
    }

    struct MarketplaceItem {
        uint itemId;
        address nftContract;
        uint256 nftId;
        address payable seller;
        address payable owner;
        uint256 price;
        bool sold;
        bool forSale;
    }

    mapping(uint256 => MarketplaceItem) public idToItem;

    event MarketItemCreated (
        uint indexed itemId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address seller,
        address owner,
        uint256 price,
        bool sold,
        bool forSale
    );
    
    event MarketItemSold (
        uint indexed itemId,
        address owner
    );

    function listNFT (
        address nftAddress,
        uint256 tokenId,
        uint256 price
    ) public nonReentrant {
        if(price <= 0) revert InsufficientBalance();

        unchecked {
            ++listedItems;
        }

        idToItem[listedItems] = MarketplaceItem(
            listedItems,
            nftAddress,
            tokenId,
            payable(msg.sender),
            payable(msg.sender),
            price,
            false,
            true
        );

        emit MarketItemCreated(
            listedItems,
            nftAddress,
            tokenId,
            msg.sender,
            msg.sender,
            price,
            false,
            true
        );
    }

    function delistNFT (
        uint256 itemId
    ) public nonReentrant {
        address owner = idToItem[itemId].owner;
        if(msg.sender != owner) revert IncorrectOwner();

        idToItem[itemId].forSale = false;
    }

    function buyNFT (
        address nftAddress,
        uint256 itemId
    ) public nonReentrant {
        if(itemId > listedItems) revert ItemNotListed();

        uint price = idToItem[itemId].price;
        uint nftId = idToItem[itemId].nftId;
        bool sold = idToItem[itemId].sold;
        bool forSale = idToItem[itemId].forSale;
        address invaderSeller = idToItem[itemId].seller;
        address listedContract = idToItem[itemId].nftContract;

        if(sold == true) revert ItemUnavailable();
        if(forSale == false) revert ItemDelisted();
        if(nftAddress != listedContract) revert WrongContract();

        bool success = spaceContract.transferFrom(msg.sender, invaderSeller, price);
        if(!success) revert BadTransfer();

        ERC721(nftAddress).transferFrom(invaderSeller, msg.sender, nftId);

        emit MarketItemSold(
            itemId,
            msg.sender
        );

        idToItem[itemId].owner = payable(msg.sender);
        idToItem[itemId].sold = true;

        unchecked {
            ++soldItems;
        }
    }

    function getListedItems() public view returns(MarketplaceItem[] memory) {
        uint amtListed = listedItems - soldItems;
        uint count = 0;

        MarketplaceItem[] memory items = new MarketplaceItem[](amtListed);
        for (uint i = 1; i < listedItems; i++) {
            if (idToItem[i].sold == false) {
                MarketplaceItem storage currentItem = idToItem[i];
                items[count] = currentItem;
                count += 1;
            }
        }
        return items;
    }

    function setSpaceContract(address _spaceContract) external onlyOwner {
        spaceContract = ERC20(_spaceContract);
    } 
}