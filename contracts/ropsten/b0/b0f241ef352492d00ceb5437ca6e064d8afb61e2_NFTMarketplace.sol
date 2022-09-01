// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./ERC4907.sol";

contract NFTMarketplace {
    event Listed(uint256 _tokenId, address _NFTFamily, uint256 _price);
    event StatusUpdated(uint256 _tokenId, address _NFTFamily, Status _status);
    event PriceUpdate(uint256 _tokenId, address _NFTFamily, uint256 _price);
    event Sold(uint256 _tokenId, address _NFTFamily, uint256 _price);

    enum Status {sold, paused, available, deleted, rented}

    struct RentInfo {
      bool forRent;
      uint256 rentPrice;
      uint256 expires;
    }
    struct SaleInfo {
      bool forSale;
      uint256 price;
    }
    struct NFT {
        uint256 tokenId;
        SaleInfo sale;
        RentInfo rent;
        address NFTFamily;
        Status status;
    }

    uint256 public immutable listingFees;
    address payable public marketOwner;
    mapping (uint256 => mapping (address => bool)) private isMarketNFT;
    //marketID to NFT ID to NFT Struct
    mapping (uint256 => mapping (address => NFT)) private marketNFTs;

    modifier notNull(address _addr) {
        require (_addr != address(0), "Null address");
        _;
    }

    modifier notListed (uint256 _tokenId, address _NFTFamily) {
        require (!isMarketNFT[_tokenId][_NFTFamily], "NFT already exsist in listing");
        _;
    }

    modifier isListed (uint256 _tokenId, address _NFTFamily) {
        require (isMarketNFT[_tokenId][_NFTFamily], "NFT doesn not exsist in listing");
        _;
    }

    //  //caller should be either authorised or owner
    modifier onlyNFTOwner (uint256 _tokenId, address _NFTFamily) {
        ERC4907 nft = ERC4907(_NFTFamily);
        address _owner = nft.ownerOf(_tokenId);
        require (_owner == msg.sender || nft.isApprovedForAll(_owner, msg.sender), "Invalid NFT ID");
        _;
    }

    constructor(uint256 _listingFees) {
        marketOwner = payable(msg.sender);
        listingFees = _listingFees;
    }

    function listNFT(uint256 _tokenId, SaleInfo memory _sale, RentInfo memory _rent, address _NFTFamily) payable public
     notNull(_NFTFamily) notListed(_tokenId,_NFTFamily) onlyNFTOwner(_tokenId,_NFTFamily) {

        require (msg.value == listingFees, "Listing fees not correct");
        ERC4907 nftToken = ERC4907(_NFTFamily);
        if (_sale.forSale) {
            require (_sale.price > 0, "NFT price should be > 0");
        }
        if (_rent.forRent) {
            require (_rent.rentPrice > 0, "NFT rent price should be > 0");
            //require (_rent.expires > block.timestamp, "NFT expire time invalid");
        }
        require (nftToken.getApproved(_tokenId) == address(this), "NFT not approved for marketplace");
        NFT memory nft = NFT(_tokenId, _sale, _rent, _NFTFamily, Status.available);
        marketNFTs[_tokenId][_NFTFamily] = nft;
        isMarketNFT[_tokenId][_NFTFamily] = true;

        //emit Listed(_tokenId, _NFTFamily, _price);
    }

    function pause(uint256 _tokenId, address _NFTFamily) public 
     notNull(_NFTFamily) isListed(_tokenId, _NFTFamily) onlyNFTOwner(_tokenId,_NFTFamily) {

        marketNFTs[_tokenId][_NFTFamily].status = Status.paused;

        emit StatusUpdated(_tokenId, _NFTFamily, Status.paused);
    }

    function start(uint256 _tokenId, address _NFTFamily) public 
     notNull(_NFTFamily) isListed(_tokenId, _NFTFamily) onlyNFTOwner(_tokenId,_NFTFamily) {

        marketNFTs[_tokenId][_NFTFamily].status = Status.available;

        emit StatusUpdated(_tokenId, _NFTFamily, Status.available);
    }

    function cancelNFT(uint256 _tokenId, address _NFTFamily) public
     notNull(_NFTFamily) isListed(_tokenId, _NFTFamily) onlyNFTOwner(_tokenId,_NFTFamily) {

        delete marketNFTs[_tokenId][_NFTFamily];

        emit StatusUpdated(_tokenId, _NFTFamily, Status.deleted);
    }

    function updatePrice(uint256 _tokenId, uint256 _price, uint256 _rentPrice, address _NFTFamily) public 
     notNull(_NFTFamily) isListed(_tokenId, _NFTFamily) onlyNFTOwner(_tokenId,_NFTFamily) {

        if (marketNFTs[_tokenId][_NFTFamily].sale.forSale) {
            require (_price > 0, "NFT price should be > 0");
            marketNFTs[_tokenId][_NFTFamily].sale.price = _price;
        }
        if (marketNFTs[_tokenId][_NFTFamily].rent.forRent) {
            require (_rentPrice > 0, "NFT rent price should be > 0");
            marketNFTs[_tokenId][_NFTFamily].rent.rentPrice = _price;
        }

        emit PriceUpdate(_tokenId, _NFTFamily, _price);
    }

    function buyNFT(uint256 _tokenId, address _NFTFamily) public payable notNull(_NFTFamily) isListed(_tokenId, _NFTFamily) {
        require(marketNFTs[_tokenId][_NFTFamily].sale.forSale, "Not for sale");
        require(marketNFTs[_tokenId][_NFTFamily].status == Status.available, "NFT not available");
        require(msg.value == marketNFTs[_tokenId][_NFTFamily].sale.price, "amount paid is less than NFT price");
        ERC4907 nftToken = ERC4907(_NFTFamily);
        address _owner = nftToken.ownerOf(_tokenId);
        nftToken.transferFrom(_owner, msg.sender, _tokenId);
        marketNFTs[_tokenId][_NFTFamily].status = Status.sold;
        isMarketNFT[_tokenId][_NFTFamily] = false;
        //forward money to owner
        (bool sent, ) = _owner.call{value: msg.value}("");
        require(sent, "Failed to send Ether to owner");

        emit StatusUpdated(_tokenId, _NFTFamily, Status.sold);
        emit Sold(_tokenId, _NFTFamily, msg.value);
    }

    function getNFT(uint256 _tokenId, address _NFTFamily) public view 
     notNull(_NFTFamily) isListed(_tokenId, _NFTFamily) returns(uint256,uint256,uint256, uint256, Status, address) {
        NFT memory nft = marketNFTs[_tokenId][_NFTFamily];
        return (nft.tokenId, nft.sale.price, nft.rent.rentPrice, nft.rent.expires, nft.status, nft.NFTFamily);
    }

    function withdrawBalance() public payable {
        require(msg.sender == marketOwner, "Not a market owner");
        require (address(this).balance > 0, "Contract balance is 0");
        (bool sent, ) = marketOwner.call{value: address(this).balance}("");
        require(sent, "Failed to send Ether"); 
    }

    function rentNFT(uint256 _tokenId, address _NFTFamily) payable public notNull(_NFTFamily) isListed(_tokenId, _NFTFamily) {
        require(marketNFTs[_tokenId][_NFTFamily].rent.forRent, "Not for rent");
        require(marketNFTs[_tokenId][_NFTFamily].status == Status.available, "NFT not available");
        ERC4907 nftToken = ERC4907(_NFTFamily);
        require(nftToken.userExpires(_tokenId) == 0 || nftToken.userExpires(_tokenId) < block.timestamp, "NFT already rented");
        require(msg.value == marketNFTs[_tokenId][_NFTFamily].rent.rentPrice, "amount paid is less than NFT price");
        
        address _owner = nftToken.ownerOf(_tokenId);
        nftToken.setUser(_tokenId, msg.sender, marketNFTs[_tokenId][_NFTFamily].rent.expires);
        marketNFTs[_tokenId][_NFTFamily].status = Status.rented;
        //forward money to owner
        (bool sent, ) = _owner.call{value: msg.value}("");
        require(sent, "Failed to send Ether to owner");

        emit StatusUpdated(_tokenId, _NFTFamily, Status.sold);
        emit Sold(_tokenId, _NFTFamily, msg.value);
    }
}