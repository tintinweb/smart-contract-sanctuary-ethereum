/**
 *Submitted for verification at Etherscan.io on 2022-03-31
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IETH {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);


    function transfer(address recipient, uint256 amount) external returns (bool);


    function allowance(address owner, address spender) external view returns (uint256);


    function approve(address spender, uint256 amount) external returns (bool);


    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

interface INFTDatabase {
    function mint(address to, string memory _tokenURI) external returns (uint256);

    function burn(uint256 nftId) external returns (uint256);

    function totalSupply() external view returns (uint256);

    function tokenURI(uint256 nftId) external view returns (string memory);

    function balanceOf(address owner) external view returns (uint256 balance);

    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    function tokenByIndex(uint256 index) external view returns (uint256);

    function approve(address to, uint256 nftId) external;

    function setApprovalForAll(address operator, bool _approved) external;

    function getApproved(uint256 nftId) external view returns (address operator);

    function ownerOf(uint256 nftId) external view returns (address owner);
}

    struct MarketplaceNft {
        uint256 nftId;
        bool isSaling;
        uint256 lastestPrice;
    }

contract Marketplace {
    INFTDatabase private database = INFTDatabase(0xDcE4D07A194eaF005ec8251CE6CfE7bCa314fdBa);
    address devWallet = 0x1331A37f2E68a58ABCE998fC9E53Ad32a049baF8;
    IETH private eth = IETH(0xc778417E063141139Fce010982780140Aa0cD5Ab);
    mapping(uint256 => bool) private nftsOnMarketplace;
    mapping(uint256 => uint256) private nftPricesOnMarketplace;
    MarketplaceNft[] private marketplaceNfts;


    function IsSalingOnMarketplace(uint256 nftId) public view returns (bool){
        return nftsOnMarketplace[nftId];
    }

    function GetPriceOnMarketplace(uint256 nftId) public view returns (uint256){
        return nftPricesOnMarketplace[nftId];
    }

    function GetNftsSalingOnMarketplace() public view returns (uint256[] memory ids, uint256[] memory prices){
        uint256[] memory nftIds;
        uint256[] memory nftPrices;

        uint256 counter = 0;
        for (uint i = 0; i < marketplaceNfts.length; i++) {
            if (marketplaceNfts[i].isSaling) {
                nftIds[counter] = marketplaceNfts[i].nftId;
                nftPrices[counter] = marketplaceNfts[i].lastestPrice;
                counter++;

            }
        }

        return (nftIds, nftPrices);
    }

    function WithdrawOnMarketplace(uint256 nftId) external {
        require(IsExistOnMarketplace(nftId), "this nft does not exist on marketplace");
        require(database.ownerOf(nftId) == msg.sender, "this token is not owned by caller");

        _withdrawOnMarketplace(nftId);
    }

    function _withdrawOnMarketplace(uint256 nftId) private {
        delete nftsOnMarketplace[nftId];
        delete nftPricesOnMarketplace[nftId];

        MarketplaceNft memory nft = FindNftOnMarketplace(nftId);
        nft.isSaling = false;
    }

    function BuyNftOnMarketplace(uint256 nftId) external {
        require(database.ownerOf(nftId) != msg.sender, "caller is the owner");
        require(IsExistOnMarketplace(nftId), "this nft does not exist on marketplace");

        MarketplaceNft memory nft = FindNftOnMarketplace(nftId);
        require(eth.balanceOf(msg.sender) >= nft.lastestPrice, "sufficient amount");

        eth.transferFrom(msg.sender, database.ownerOf(nftId), nft.lastestPrice);

        _withdrawOnMarketplace(nftId);

    }

    function SaleOnMarketplace(uint256 nftId, uint256 price) external {
        require(database.ownerOf(nftId) == msg.sender, "this token is not owned by caller");
        require(price > 0, "price must greater than 0");

        uint256 taxSale;
    unchecked{
        taxSale = (price / 100);
    }
        require(eth.balanceOf(msg.sender) >= taxSale, "sufficient amount tax !");
        eth.transferFrom(msg.sender, devWallet, taxSale);

        nftsOnMarketplace[nftId] = true;
        nftPricesOnMarketplace[nftId] = price;
        if (IsExistOnMarketplace(nftId)) {
            MarketplaceNft memory nft = FindNftOnMarketplace(nftId);
            nft.isSaling = nftsOnMarketplace[nftId];
            nft.lastestPrice = nftPricesOnMarketplace[nftId];
        } else {
            marketplaceNfts.push(MarketplaceNft(nftId, nftsOnMarketplace[nftId], nftPricesOnMarketplace[nftId]));
        }
    }


    function IsExistOnMarketplace(uint256 nftId) public view returns (bool){
        for (uint i; i < marketplaceNfts.length; i++) {
            if (marketplaceNfts[i].nftId == nftId) {
                return true;
            }
        }
        return false;
    }

    function FindNftOnMarketplace(uint256 nftId) public view returns (MarketplaceNft memory){
        for (uint i; i < marketplaceNfts.length; i++) {
            if (marketplaceNfts[i].nftId == nftId) {
                return marketplaceNfts[i];
            }
        }
        return MarketplaceNft(0, false, 0);
    }


    function GetNftsOf(address owner) public view returns (uint256[] memory, string[] memory){

        uint256 amount = database.balanceOf(owner);

        require(amount > 0, "this address has no nfts");

        uint256[] memory nftIds = new uint256[](amount);
        string[] memory nftUris = new  string[](amount);

        for (uint256 i = 0; i < amount; i++) {
            nftIds[i] = database.tokenOfOwnerByIndex(owner, i);
            nftUris[i] = database.tokenURI(nftIds[i]);
        }
        return (nftIds, nftUris);
    }

}