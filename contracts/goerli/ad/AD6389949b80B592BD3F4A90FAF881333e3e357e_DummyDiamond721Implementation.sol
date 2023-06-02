// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/**
 * This is a generated dummy diamond implementation for compatibility with
 * etherscan. For full contract implementation, check out the diamond on louper:
 * https://louper.dev/
 */

contract DummyDiamond721Implementation {
    struct Tuple4362849 {
        address addr;
        uint64 startTimestamp;
        bool burned;
        uint24 extraData;
    }

    struct Tuple4244095 {
        address addr;
        uint64 startTimestamp;
        bool burned;
        uint24 extraData;
    }

    struct Tuple6871229 {
        address facetAddress;
        uint8 action;
        bytes4[] functionSelectors;
    }

    struct Tuple576603 {
        address account;
        uint256 allowance;
    }

    struct Tuple1236461 {
        address facetAddress;
        bytes4[] functionSelectors;
    }

    function airdrop() external view returns (bool) {}

    function approve(address to, uint256 tokenId) external {}

    function balanceOf(address owner) external view returns (uint256) {}

    function burn(uint256 tokenId) external {}

    function getApproved(uint256 tokenId) external view returns (address) {}

    function isApprovedForAll(
        address owner,
        address operator
    ) external view returns (bool) {}

    function isSoulbound() external view returns (bool) {}

    function maxMintPerAddress() external view returns (uint256) {}

    function maxMintPerTx() external view returns (uint256) {}

    function maxSupply() external view returns (uint256) {}

    function mint(address to, uint256 amount) external payable {}

    function mint(address to) external payable {}

    function name() external view returns (string memory) {}

    function ownerOf(uint256 tokenId) external view returns (address) {}

    function price() external view returns (uint256) {}

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external {}

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) external {}

    function setAirdrop(bool _airdrop) external {}

    function setApprovalForAll(address operator, bool approved) external {}

    function setAutomaticUSDConversion(bool _automaticUSDConversion) external {}

    function setIsPriceUSD(bool _isPriceUSD) external {}

    function setMaxMintPerAddress(uint256 _maxMintPerAddress) external {}

    function setMaxMintPerTx(uint256 _maxMintPerTx) external {}

    function setMaxSupply(uint256 _maxSupply) external {}

    function setName(string memory _name) external {}

    function setPrice(uint256 _price) external {}

    function setSoulbound(bool _isSoulbound) external {}

    function setSymbol(string memory _symbol) external {}

    function setTokenURI(string memory tokenURI) external {}

    function symbol() external view returns (string memory) {}

    function tokenURI(uint256 tokenId) external view returns (string memory) {}

    function totalSupply() external view returns (uint256) {}

    function transferFrom(address from, address to, uint256 tokenId) external {}

    function createEdition(
        string memory _name,
        uint256 _maxSupply,
        uint256 _price
    ) external {}

    function enableEditions() external {}

    function maxSupply(uint256 _editionIndex) external view returns (uint256) {}

    function mint(
        address to,
        uint256 amount,
        uint256 editionIndex
    ) external payable {}

    function price(uint256 _editionIndex) external view returns (uint256) {}

    function setMaxSupply(uint256 _maxSupply, uint256 _editionIndex) external {}

    function setPrice(uint256 _price, uint256 _editionIndex) external {}

    function totalSupply(
        uint256 _editionIndex
    ) external view returns (uint256) {}

    function updateTotalSupply(
        uint256 _totalSuppy,
        uint256 _editionIndex
    ) external {}

    function explicitOwnershipOf(
        uint256 tokenId
    ) external view returns (Tuple4362849 memory) {}

    function explicitOwnershipsOf(
        uint256[] memory tokenIds
    ) external view returns (Tuple4244095[] memory) {}

    function getEditionIndex(
        uint256 _tokenId
    ) external view returns (uint256) {}

    function getEditionsByOwner(
        address _owner
    ) external view returns (uint256[] memory) {}

    function getOwners() external view returns (address[] memory) {}

    function getOwners(
        uint256 _editionIndex
    ) external view returns (address[] memory) {}

    function getTokensByOwner(
        address _owner
    ) external view returns (uint256[] memory) {}

    function getTokensByOwner(
        address _owner,
        uint256 _editionIndex
    ) external view returns (uint256[] memory) {}

    function ownsEdition(
        address _owner,
        uint256 editionIndex
    ) external view returns (bool) {}

    function tokensOfOwner(
        address owner
    ) external view returns (uint256[] memory) {}

    function tokensOfOwnerIn(
        address owner,
        uint256 start,
        uint256 stop
    ) external view returns (uint256[] memory) {}

    function __transitiveOwner() external view returns (address) {}

    function addPayee(address account, uint256 shares_) external {}

    function addToAllowList(uint256 tokenId, address account) external {}

    function addToAllowList(
        uint256 tokenId,
        address[] memory accounts,
        uint256 allowance
    ) external {}

    function addToAllowList(
        uint256 tokenId,
        address account,
        uint256 allowance,
        uint256 allowTime
    ) external {}

    function addToAllowList(
        uint256 tokenId,
        address[] memory accounts
    ) external {}

    function addToAllowList(
        uint256 tokenId,
        address account,
        uint256 allowance
    ) external {}

    function addToAllowList(
        uint256 tokenId,
        address[] memory accounts,
        uint256 allowance,
        uint256 allowTime
    ) external {}

    function allowList(
        uint256 _tokenId
    ) external view returns (Tuple576603[] memory allowListMap) {}

    function allowListContains(
        uint256 tokenId,
        address account
    ) external view returns (bool contains) {}

    function allowListEnabled(
        uint256 _tokenId
    ) external view returns (bool enabled) {}

    function contractURI() external view returns (string memory) {}

    function diamondCut(
        Tuple6871229[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) external {}

    function disableAllowList(uint256 _tokenId) external {}

    function enableAllowList(uint256 _tokenId) external {}

    function facetAddress(
        bytes4 _functionSelector
    ) external view returns (address facetAddress_) {}

    function facetAddresses()
        external
        view
        returns (address[] memory facetAddresses_)
    {}

    function facetFunctionSelectors(
        address _facet
    ) external view returns (bytes4[] memory _facetFunctionSelectors) {}

    function facets() external view returns (Tuple1236461[] memory facets_) {}

    function implementation() external view returns (address) {}

    function owner() external view returns (address) {}

    function pause() external {}

    function paused() external view returns (bool) {}

    function payee(uint256 index) external view returns (address) {}

    function releasable(address account) external view returns (uint256) {}

    function releasable(
        address token,
        address account
    ) external view returns (uint256) {}

    function release(address account) external {}

    function release(address token, address account) external {}

    function released(
        address token,
        address account
    ) external view returns (uint256) {}

    function released(address account) external view returns (uint256) {}

    function removeFromAllowList(uint256 tokenId, address account) external {}

    function removeFromAllowList(
        uint256 tokenId,
        address[] memory accounts
    ) external {}

    function royaltyInfo(
        uint256 tokenId,
        uint256 salePrice
    ) external view returns (address, uint256) {}

    function setDefaultRoyalty(
        uint16 _defaultRoyaltyBPS,
        address _defaultRoyalyReceiver
    ) external {}

    function setDummyImplementation(address _implementation) external {}

    function shares(address account) external view returns (uint256) {}

    function supportsInterface(
        bytes4 interfaceId
    ) external view returns (bool) {}

    function totalReleased(address token) external view returns (uint256) {}

    function totalReleased() external view returns (uint256) {}

    function totalShares() external view returns (uint256) {}

    function transferOwnership(address account) external {}

    function unpause() external {}

    function updatePaymentSplitterAddress(
        address _newPayee
    ) external returns (bool success) {}
}