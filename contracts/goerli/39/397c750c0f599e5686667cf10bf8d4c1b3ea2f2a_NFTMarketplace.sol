// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "IERC721.sol";

//---------------------//
//        Errors       //
//---------------------//
error NotOwner();
error NoProceeds();
error NotApproved();
error TransferFailed();
error PriceCannotBeZero();
error NotListed(address nftAddress, uint256 tokenId);
error NftAlreadyListed(address nftAddress, uint256 tokenId);
error PriceNotMet(address nftAddress, uint256 tokenId, uint256 price);

contract NFTMarketplace {
    //---------------------//
    //     Declarations    //
    //---------------------//
    struct Listing {
        uint256 price;
        address seller;
    }
    mapping(address => mapping(uint256 => Listing)) private listings;
    mapping(address => uint256) private proceeds;

    //---------------------//
    //        Events       //
    //---------------------//
    event ItemListed(
        address indexed seller,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 price
    );

    event ItemBought(
        address indexed buyer,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 price
    );

    event ItemCancelled(
        address indexed sender,
        address indexed nftAddress,
        uint256 indexed tokenId
    );

    //---------------------//
    //      Modifiers      //
    //---------------------//

    modifier notListed(
        address nftAddress,
        uint256 tokenId,
        address owner
    ) {
        Listing memory listing = listings[nftAddress][tokenId];
        if (listing.price > 0) {
            revert NftAlreadyListed(nftAddress, tokenId);
        }
        _;
    }

    modifier isOwner(
        address nftAddress,
        uint256 tokenId,
        address spender
    ) {
        IERC721 nft = IERC721(nftAddress);
        address owner = nft.ownerOf(tokenId);
        if (spender != owner) {
            revert NotOwner();
        }
        _;
    }

    modifier isListed(address nftAddress, uint256 tokenId) {
        Listing memory listing = listings[nftAddress][tokenId];
        if (listing.price <= 0) {
            revert NotListed(nftAddress, tokenId);
        }
        _;
    }

    //---------------------//
    //    Main Functions   //
    //---------------------//
    function listItem(
        address nftAddress,
        uint256 tokenId,
        uint256 price
    )
        public
        notListed(nftAddress, tokenId, msg.sender)
        isOwner(nftAddress, tokenId, msg.sender)
    {
        if (price == 0) {
            revert PriceCannotBeZero();
        }
        IERC721 nft = IERC721(nftAddress);
        if (nft.getApproved(tokenId) != address(this)) {
            revert NotApproved();
        }
        listings[nftAddress][tokenId] = Listing(price, msg.sender);

        emit ItemListed(nft.ownerOf(tokenId), nftAddress, tokenId, price);
        //     event ItemListed(
        //     address indexed seller,
        //     address indexed nftAddress,
        //     uint256 indexed tokenId,
        //     uint256 price
        // );
    }

    function buyItem(address nftAddress, uint256 tokenId)
        external
        payable
        isListed(nftAddress, tokenId)
    {
        Listing memory listedItem = listings[nftAddress][tokenId];
        if (msg.value < listedItem.price) {
            revert PriceNotMet(nftAddress, tokenId, listedItem.price);
        }
        proceeds[listedItem.seller] += msg.value;
        delete (listings[nftAddress][tokenId]);
        IERC721(nftAddress).safeTransferFrom(
            listedItem.seller,
            msg.sender,
            tokenId
        );
        emit ItemBought(msg.sender, nftAddress, tokenId, listedItem.price);
    }

    function cancelListing(address nftAddress, uint256 tokenId)
        external
        isOwner(nftAddress, tokenId, msg.sender)
        isListed(nftAddress, tokenId)
    {
        delete (listings[nftAddress][tokenId]);
        emit ItemCancelled(msg.sender, nftAddress, tokenId);
    }

    function updateListing(
        address nftAddress,
        uint256 tokenId,
        uint256 newPrice
    )
        external
        isListed(nftAddress, tokenId)
        isOwner(nftAddress, tokenId, msg.sender)
    {
        listings[nftAddress][tokenId].price = newPrice;
        emit ItemListed(msg.sender, nftAddress, tokenId, newPrice);
    }

    function withdrawProceeds() external {
        uint256 userProceeds = proceeds[msg.sender];
        if (userProceeds <= 0) {
            revert NoProceeds();
        }
        proceeds[msg.sender] = 0;
        (bool success, ) = payable(msg.sender).call{value: userProceeds}("");
        if (!success) {
            revert TransferFailed();
        }
    }

    function getListing(address nftAddress, uint256 tokenId)
        external
        view
        returns (Listing memory)
    {
        return listings[nftAddress][tokenId];
    }

    function getProceeds(address seller) external view returns (uint256) {
        return proceeds[seller];
    }
}