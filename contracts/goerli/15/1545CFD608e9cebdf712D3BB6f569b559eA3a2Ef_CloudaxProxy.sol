// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

import "./ICloudaxMarketplace.sol";
// import "./interfaces/ICloudaxMarketplace.sol";
// import "./interfaces/IAuctionFulfillment.sol";
// import "./interfaces/IOrderFulfillment.sol";

//Test params
// www.cloudax.com.metadate/1
// 000000000000000000

contract CloudaxProxy {

    // -----------------------------------VARIABLES-----------------------------------
    address public owner;
    ICloudaxMarketplace public marketplace;
    // IAuctionFulfillment public auction;
    // IOrderFulfillment public offer;


    constructor(
        address _marketplace
    // address _auction, 
    // address _offer
    ) {
    marketplace = ICloudaxMarketplace(_marketplace);
    // auction = IAuctionFulfillment(_auction);
    // offer = IOrderFulfillment(_offer);
  }

// --------------------------MARKETPLACE----------------------------
    function buyItemCopy(
        address payable _fundingRecipient,
        uint256 collectionId,
        string memory itemId,
        string memory _tokenUri,
        uint256 _price,
        uint256 _qty,
        uint256 _supply
    ) public payable{
        (bool success, ) = address(marketplace).delegatecall(
            abi.encodeWithSignature("buyItemCopy(address,uint256,string,string,uint256,uint256,uint256)",
            _fundingRecipient, collectionId, itemId, _tokenUri, _price, _qty, _supply)
        );
        require(success, "buyItemCopy failed");
        }

    function createCollection(
        uint256 creatorFee,
        address payable fundingRecipient
    ) public{
        (bool success, ) = address(marketplace).delegatecall(
            abi.encodeWithSignature("createCollection(uint256,address)", creatorFee, fundingRecipient)
        );
            require(success, "Collection creation failed");
        }

}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;


interface ICloudaxMarketplace {
    function setContractBaseURI(string memory __contractBaseURI) external;

    function setERC20Token(address newToken) external;

    function buyItemCopy(
        address payable _fundingRecipient,
        uint256 collectionId,
        string memory itemId,
        string memory _tokenUri,
        uint256 _price,
        uint256 _qty,
        uint256 _supply
    ) external payable;

    function listToken(
        address nftAddress,
        uint256 tokenId,
        uint256 price,
        uint256 collectionId,
        address payable fundingRecipient
    ) external; 

    function updateListing
    (
        address nftAddress, 
        uint256 tokenId, 
        uint256 newPrice
    ) external;

    function cancelListing(address nftAddress, uint256 tokenId) external;

    function createCollection(
        uint256 creatorFee,
        address payable fundingRecipient
    ) external;

    function updateCollection(
        uint256 collectionId,
        uint256 creatorFee,
        address payable fundingRecipient
    ) external;

    function deleteCollection(uint256 collectionId) external; 

    function buyNft(address nftAddress, uint256 tokenId) external payable;

    function withdrawEarnings() external;
    
}