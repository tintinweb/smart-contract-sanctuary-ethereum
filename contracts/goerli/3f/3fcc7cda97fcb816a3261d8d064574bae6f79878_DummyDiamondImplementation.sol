// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * Author https://juicelabs.io
 *
 * This is a generated dummy diamond implementation for compatibility with 
 * etherscan. For full contract implementation, check out the diamond on 
 * https://louper.dev
 */

contract DummyDiamondImplementation {     

   struct LazyMintStorage {
        uint256 publicMintPrice;
        uint256 maxMintsPerTxn;
        uint256 maxMintsPerWallet;
        uint256 maxMintableAtCurrentStage;
    } 

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

   function allOwners() external view returns (address[] memory) {}

   function allTokensForOwner(address _owner) external view returns (uint256[] memory) {}

   function approve(address to, uint256 tokenId) external {}

   function balanceOf(address _owner) external view returns (uint256) {}

   function burn(uint256 tokenId) external {}

   function defaultRoyaltyFraction() external view returns (uint256) {}

   function deleteDefaultRoyalty() external {}

   function devMint(address to, uint256 quantity) external payable {}

   function devMintUnsafe(address to, uint256 quantity) external payable {}

   function devMintWithTokenURI(address to, string memory _tokenURI) external payable {}

   function exists(uint256 tokenId) external view returns (bool) {}

   function folderStorageBaseURI() external view returns (string memory) {}

   function getApproved(uint256 tokenId) external view returns (address) {}

   function isApprovedForAll(address _owner, address operator) external view returns (bool) {}

   function lockMetadata() external {}

   function maxMintable() external view returns (uint256) {}

   function metadataLocked() external view returns (bool) {}

   function name() external view returns (string memory) {}

   function numberMinted(address tokenOwner) external view returns (uint256) {}

   function ownerOf(uint256 tokenId) external view returns (address) {}

   function removeTokenURIOverrideSelector() external {}

   function royaltyInfo(uint256 tokenId, uint256 salePrice) external view returns (address, uint256) {}

   function safeTransferFrom(address from, address to, uint256 tokenId) external {}

   function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) external {}

   function saleState() external view returns (uint256) {}

   function setApprovalForAll(address operator, bool approved) external {}

   function setDefaultRoyalty(uint96 feeNumerator) external {}

   function setFolderStorageBaseURI(string memory _baseURI) external {}

   function setMaxMintable(uint256 _maxMintable) external {}

   function setSaleState(uint256 _saleState) external {}

   function setTokenMeta(string memory _name, string memory _symbol, uint96 _defaultRoyalty) external {}

   function setTokenStorageBaseURI(string memory _baseURI) external {}

   function setTokenURI(uint256 tokenId, string memory _tokenURI) external {}

   function setTokenURIOverrideSelector(bytes4 selector) external {}

   function startTokenId() external pure returns (uint256) {}

   function symbol() external view returns (string memory) {}

   function tokenStorageBaseURI() external view returns (string memory) {}

   function tokenURI(uint256 tokenId) external view returns (string memory) {}

   function tokenURIOverrideSelector() external view returns (bytes4) {}

   function totalMinted() external view returns (uint256) {}

   function totalSupply() external view returns (uint256) {}

   function transferFrom(address from, address to, uint256 tokenId) external {}

   function lazyMintConfig() external pure returns (LazyMintStorage memory) {}

   function maxMintableAtCurrentStage() external view returns (uint256) {}

   function maxMintsPerTransaction() external view returns (uint256) {}

   function maxMintsPerWallet() external view returns (uint256) {}

   function publicMint(uint256 quantity) external payable returns (uint256) {}

   function publicMintPrice() external view returns (uint256) {}

   function setLazyMintConfig(uint256 _maxMintsPerTxn, uint256 _maxMintsPerWallet, uint256 _maxMintableAtCurrStage, uint256 _publicMintPrice) external {}

   function setMaxMintableAtCurrentStage(uint256 _maxMintable) external {}

   function setMaxMintsPerTransaction(uint256 _maxMints) external {}

   function setMaxMintsPerWallet(uint256 _maxMints) external {}

   function setPublicMintPrice(uint256 _mintPrice) external {}

   function diamondCut(FacetCut[] calldata _diamondCut, address _init, bytes memory _calldata) external {}

   function facetAddress(bytes4 _functionSelector) external view returns (address facetAddress_) {}

   function facetAddresses() external view returns (address[] memory facetAddresses_) {}

   function facetFunctionSelectors(address _facet) external view returns (bytes4[] memory facetFunctionSelectors_) {}

   function facets() external view returns (Facet[] memory facets_) {}

   function gasCacheForSelector(bytes4 selector) external view returns (address) {}

   function grantOperator(address _operator) external {}

   function immutableUntilBlock() external view returns (uint256) {}

   function initializeDiamondClone(address diamondSawAddress, address[] memory _facetAddresses) external {}

   function owner() external view returns (address) {}

   function pause() external {}

   function paused() external view returns (bool) {}

   function renounceOwnership() external {}

   function revokeOperator(address _operator) external {}

   function setGasCacheForSelector(bytes4 selector) external {}

   function setImmutableUntilBlock(uint256 blockNumber) external {}

   function supportsInterface(bytes4 _interfaceId) external view returns (bool) {}

   function transferOwnership(address newOwner) external {}

   function unpause() external {}

   function upgradeDiamondSaw(address _upgradeSaw, address[] memory _oldFacetAddresses, address[] memory _newFacetAddresses, address _init, bytes memory _calldata) external {}
}