// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * This is a generated dummy diamond implementation for compatibility with 
 * etherscan. For full contract implementation, check out the diamond on louper:
 * https://louper.dev/diamond/0xc173ae57b7479b95EA9EF0B1A3C70a61e84d0F30?network=rinkeby
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
    
   function diamondCut(FacetCut[] memory _diamondCut, address _init, bytes memory _calldata) external {}

   function facetAddress(bytes4 _functionSelector) external view returns (address facetAddress_) {}

   function facetAddresses() external view returns (address[] memory facetAddresses_) {}

   function facetFunctionSelectors(address _facet) external view returns (bytes4[] memory facetFunctionSelectors_) {}

   function facets() external view returns (Facet[] memory facets_) {}

   function supportsInterface(bytes4 _interfaceId) external view returns (bool) {}

   function owner() external view returns (address owner_) {}

   function transferOwnership(address _newOwner) external {}

   function dummyImplementation() external view returns (address) {}

   function setDummyImplementation(address implementation) external {}
}