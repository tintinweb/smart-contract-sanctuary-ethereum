pragma solidity ^0.8.0;


// SPDX-License-Identifier: MIT


/**
 * This is a generated dummy diamond implementation for compatibility with 
 * etherscan. For full contract implementation, check out the diamond on louper:
 * https://louper.dev/diamond/0x930b13F4CAd42cdF3DA764632EB38e44f05A5873?network=localhost
 */

contract DummyDiamondImplementation {
   enum FacetCutAction {Add, Replace, Remove}

   struct FacetCut {
      address facetAddress;
      FacetCutAction action;
      bytes4[] functionSelectors;
   }

   struct Facet {
      address facetAddress;
      bytes4[] functionSelectors;
   }

   struct ClaimAmounts {
      uint256 primaryCreator;
      uint256[] collabs;
      uint256 reseller;
      uint256 gallery;
      uint256[] sios;
      uint256 protocol;
   }

   struct SalesLimitsParams {
      uint256 maxPrice;
      uint16 minMintPortionSio;
      uint16 maxMintPortionSio;
      uint16 minResalePortionSio;
      uint16 maxResalePortionSio;
      uint16 minResalePortionCreator;
      uint16 maxResalePortionCreator;
      uint16 minCombinedResalePortionsSioCreator;
      uint16 maxCombinedResalePortionsSioCreator;
      uint16 minMinHigherBid;
      uint16 maxMinHigherBid;
      int40 minExtendBidTime;
      int40 maxExtendBidTime;
      uint40 minExtendSpan;
      uint40 maxExtendSpan;
      uint16 hopAmountOutMinPortion;
      uint40 hopDeadlineDiff;
   }

   function diamondCut(FacetCut[] memory _diamondCut, address _init, bytes memory _calldata) external {}

   function facetAddress(bytes4 _functionSelector) external view returns (address facetAddress_) {}

   function facetAddresses() external view returns (address[] memory facetAddresses_) {}

   function facetFunctionSelectors(address _facet) external view returns (bytes4[] memory _facetFunctionSelectors) {}

   function facets() external view returns (Facet[] memory facets_) {}

   function supportsInterface(bytes4 _interfaceId) external view returns (bool) {}

   function owner() external view returns (address owner_) {}

   function transferOwnership(address _newOwner) external {}

   function balanceOf(address _owner, uint256 _id) external view returns (uint256) {}

   function balanceOfBatch(address[] memory _owners, uint256[] memory _ids) external view returns (uint256[] memory) {}

   function getIDBinIndex(uint256 _id) external pure returns (uint256 bin, uint256 index) {}

   function getValueInBin(uint256 _binValues, uint256 _index) external pure returns (uint256) {}

   function isApprovedForAll(address _owner, address _operator) external view returns (bool) {}

   function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory) external pure returns (bytes4) {}

   function onERC1155Received(address, address, uint256, uint256, bytes memory) external pure returns (bytes4) {}

   function safeBatchTransferFrom(address _from, address _to, uint256[] memory _ids, uint256[] memory _amounts, bytes memory _data) external {}

   function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _amount, bytes memory _data) external {}

   function setApprovalForAll(address _operator, bool _approved) external {}

   function uri(uint256 tokenId) external view returns (string memory) {}

   function calculateNftClaimAmounts(address creator, uint32 creatorTypeId, address gallery, bool isResale, uint256 price) external view returns (ClaimAmounts memory claimAmounts) {}

   function claimProtocolShares(uint256[] memory tokenSaleIds) external {}

   function claimShares(address recipient, uint256[] memory nftSaleIds, uint8[] memory saleRoles, uint8[] memory collabIdxs) external {}

   function claimSioShares(uint32 sioId, uint256[] memory tokenSaleIds, uint256 bonderFee) external {}

   function deregisterSalesFacet(uint16 saleTypeId) external {}

   function deregisterSalesFacetBatch(uint16[] memory saleTypeIds) external {}

   function initSalesCommonFacet(address salesController, address usdc, address hopBridgeL2, uint16 mintPortionProtocol, uint16 resalePortionProtocol, uint16 mintPortionGallery, uint16 resalePortionGallery, SalesLimitsParams memory salesLimits) external {}

   function lockSalesCommonFacet(bool lock) external {}

   function registerSalesFacet(uint16 saleTypeId, bytes4 sellFunctionSelector, bytes4 revokeSaleFunctionSelector, bytes4 buyFunctionSelector, address facetAddress) external {}

   function registerSalesFacetBatch(uint16[] memory saleTypeIds, bytes4[] memory sellFunctionSelectors, bytes4[] memory revokeSaleFunctionSelectors, bytes4[] memory buyFunctionSelectors, address[] memory facetAddresses) external {}

   function setHopAmountOutMinPortion(uint16 hopAmountOutMinPortion) external {}

   function setHopDeadlineDiff(uint40 hopDeadlineDiff) external {}

   function setMaxCombinedPortionsSioCreator(uint16 maxCombinedPortionsSioCreator) external {}

   function setMaxExtendBidTime(int40 maxExtendBidTime) external {}

   function setMaxExtendSpan(uint40 maxExtendSpan) external {}

   function setMaxMinHigherBid(uint16 maxMinHigherBid) external {}

   function setMaxMintPortionSio(uint16 maxMintPortionSio) external {}

   function setMaxPrice(uint256 maxPrice) external {}

   function setMaxResalePortionCreator(uint16 maxResalePortionCreator) external {}

   function setMaxResalePortionSio(uint16 maxResalePortionSio) external {}

   function setMinCombinedPortionsSioCreator(uint16 minCombinedPortionsSioCreator) external {}

   function setMinExtendBidTime(int40 minExtendBidTime) external {}

   function setMinExtendSpan(uint40 minExtendSpan) external {}

   function setMinMinHigherBid(uint16 minMinHigherBid) external {}

   function setMinMintPortionSio(uint16 minMintPortionSio) external {}

   function setMinResalePortionCreator(uint16 minResalePortionCreator) external {}

   function setMinResalePortionSio(uint16 minResalePortionSio) external {}

   function setSalesController(address newController) external {}

   function setSalesGlobals(uint16 mintPortionProtocol, uint16 resalePortionProtocol, uint16 mintPortionGallery, uint16 resalePortionGallery) external {}

   function setSalesLimits(SalesLimitsParams memory params) external {}

   function dummyImplementation() external view returns (address) {}

   function setDummyImplementation(address implementation) external {}
}