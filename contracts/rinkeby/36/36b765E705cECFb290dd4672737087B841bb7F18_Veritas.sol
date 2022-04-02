// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./MerkleProof.sol";

contract Veritas is ERC721A, Ownable, Pausable {
  using Strings for uint256;

  uint256 private currentHunt;
  mapping(uint256 => uint256) private paidHunt;
  address private communityWallet;
  bytes32 private merkleRoot;
  bytes32 private freeMintMerkleRoot;
  bool private freeMintActive = false;
  bool private presaleActive = true;
  uint private presalePrice = 0.06 ether;
  uint private publicPrice = 0.06 ether;
  uint private huntPrice = 0.04 ether;
  uint private maxSupply = 5000;
  uint private maxPresaleMint = 2;
  uint private maxPublicMint = 2;
  string private baseURI;

  constructor() ERC721A("Veritas", "VERITAS") {}

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function setMaxSupply(uint256 supply) external onlyOwner {
    maxSupply = supply;
  }

  function getMaxSupply() public view virtual returns (uint256) {
    return maxSupply;
  }

  ///////////////////
  /// Public mint ///
  ///////////////////

  function mint(uint256 quantity) external payable whenNotPaused mintCompliance(quantity) {
    require(!presaleActive, "Public is not active");
    _setCurrentHuntForTokens(_currentIndex, quantity);
    _safeMint(_msgSender(), quantity);
  }

  modifier mintCompliance(uint256 quantity) {
    uint256 max = presaleActive ? maxPublicMint : maxPublicMint;
    uint256 price = presaleActive ? presalePrice : publicPrice;
    require(msg.value == price * quantity, "Invalid mint price!");
    require(quantity > 0 && quantity <= max, "Invalid mint amount!");
    require(totalSupply() + quantity <= maxSupply, "Max supply exceeded!");
    uint256 totalMax = max;
    if (!presaleActive && _getAux(_msgSender()) > 0) {
      // means wallet already minted during presale
      totalMax += maxPresaleMint;
    }
    require(_numberMinted(_msgSender()) + quantity <= totalMax, "Max mint exceeded");
    _;
  }

  function _setCurrentHuntForTokens(uint256 startId, uint256 quantity) internal {
    if (currentHunt > 0) {
      for (uint256 i = 0; i < quantity; i++) {
        paidHunt[startId + i] = currentHunt;
      }
    }
  }

  function setPublicPrice(uint256 price) external onlyOwner {
    publicPrice = price;
  }

  function getPublicPrice() public view virtual returns (uint256) {
    return publicPrice;
  }

  function setMaxPublicMint(uint256 max) external onlyOwner {
    maxPublicMint = max;
  }

  function getMaxPublicMint() public view virtual returns (uint256) {
    return maxPublicMint;
  }

  ////////////////////
  /// Presale mint ///
  ////////////////////

  function mintPresale(uint256 quantity, bytes32[] calldata proof) external payable whenNotPaused mintCompliance(quantity) {
    require(presaleActive, "Presale is not active");
    require(_verify(_msgSender(), proof), "Not on presale list");
    _setCurrentHuntForTokens(_currentIndex, quantity);
    _safeMint(_msgSender(), quantity);
    // increment presale mint count
    _setAux(_msgSender(), _getAux(_msgSender()) + uint64(quantity));
  }

  function _verify(address wallet, bytes32[] memory proof) internal view returns (bool) {
    return MerkleProof.verify(proof, merkleRoot, _leaf(wallet));
  }

  function _leaf(address wallet) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(wallet));
  }

  function setPresaleActive(bool active) external onlyOwner {
    presaleActive = active;
  }

  function isPresaleActive() public view virtual returns (bool) {
    return presaleActive;
  }

  function setPresalePrice(uint256 price) external onlyOwner {
    presalePrice = price;
  }

  function getPresalePrice() public view virtual returns (uint256) {
    return presalePrice;
  }

  function setMaxPresaleMint(uint256 max) external onlyOwner {
    maxPresaleMint = max;
  }

  function getMaxPresaleMint() public view virtual returns (uint256) {
    return maxPresaleMint;
  }

  function setMerkleRoot(bytes32 root) external onlyOwner {
    merkleRoot = root;
  }

  function getMerkleRoot() public view virtual returns (bytes32) {
    return merkleRoot;
  }

  /////////////////
  /// Free mint ///
  /////////////////

  function mintFree(uint256 quantity, bytes32[] calldata proof) external whenNotPaused {
    require(freeMintActive, "Free mint is not active");
    require(quantity == 1, "Invalid mint amount!");
    require(totalSupply() + 1 <= maxSupply, "Max supply exceeded!");
    require(_verify(_msgSender(), proof), "Not on free mint list");
    _setCurrentHuntForTokens(_currentIndex, quantity);
    _safeMint(_msgSender(), quantity);
    // increment presale mint count
    _setAux(_msgSender(), _getAux(_msgSender()) + uint64(quantity));
  }

  function setFreeMintActive(bool active) external onlyOwner {
    freeMintActive = active;
  }

  function isFreeMintActive() public view virtual returns (bool) {
    return freeMintActive;
  }

  function setFreeMintMerkleRoot(bytes32 root) external onlyOwner {
    freeMintMerkleRoot = root;
  }

  function getFreeMintMerkleRoot() public view virtual returns (bytes32) {
    return freeMintMerkleRoot;
  }

  ////////////
  /// Team ///
  ////////////

  function mintTeam(uint256 quantity) external onlyOwner {
    require(totalSupply() + quantity <= maxSupply, "Max supply exceeded!");
    _safeMint(_msgSender(), quantity);
  }

  function payForHuntsTeam(uint256[] memory tokenIds) external onlyOwner {
    require(tokenIds.length > 0, "No tokens to upgrade");
    _updateTokensForHunts(tokenIds);
  }

  function setCommunityWallet(address wallet) external onlyOwner {
    communityWallet = wallet;
  }

  function getCommunityWallet() public view virtual returns (address) {
    return communityWallet;
  }

  function withdraw() external onlyOwner {
    require(address(this).balance > 0, "No balance to withdraw");
    // 60% goes to community wallet
    (bool hs, ) = payable(communityWallet).call{value: address(this).balance * 60 / 100}("");
    require(hs);
    // rest to team wallet
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
  }

  ////////////
  /// Hunt ///
  ////////////

  function payForHunt(uint256 tokenId) external payable whenNotPaused {
    require(_exists(tokenId), "Token does not exist");
    require(ownerOf(tokenId) == _msgSender(), "Not owner of token");
    require(paidHunt[tokenId] < currentHunt, "Token already paid for current hunt");
    require(msg.value == huntPrice, "Invalid hunt price");
    paidHunt[tokenId] = currentHunt;
  }

  function payForHunts(uint256[] memory tokenIds) external payable whenNotPaused {
    require(tokenIds.length > 0, "No tokens to pay for");
    require(msg.value == huntPrice * tokenIds.length, "Invalid hunt price");
    _updateTokensForHunts(tokenIds);
  }

  function _updateTokensForHunts(uint256[] memory tokenIds) internal {
    for (uint256 i = 0; i < tokenIds.length; i++) {
      uint256 tokenId = tokenIds[i];
      require(ownerOf(tokenId) == _msgSender(), "Not owner of token");
      require(paidHunt[tokenId] < currentHunt, "Token already paid for current hunt");
    }
    for (uint256 i = 0; i < tokenIds.length; i++) {
      uint256 tokenId = tokenIds[i];
      paidHunt[tokenId] = currentHunt;
    }
  }

  function setHunt(uint256 hunt) external onlyOwner {
    currentHunt = hunt;
  }

  function getHunt() public view virtual returns (uint256) {
    return currentHunt;
  }

  function getPaidHunt(uint256 tokenId) public view virtual returns (uint256) {
    return paidHunt[tokenId];
  }

  function setHuntPrice(uint256 price) external onlyOwner {
    huntPrice = price;
  }

  function getHuntPrice() public view virtual returns (uint256) {
    return huntPrice;
  }

  ////////////////
  /// Pausable ///
  ////////////////

  function pause() external onlyOwner {
    _pause();
  }

  function unpause() external onlyOwner {
    _unpause();
  }

  //////////////
  /// Reveal ///
  //////////////

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "Token does not exist");
    return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), '.json')) : '';
  }

  function setBaseURI(string memory uri) external onlyOwner {
    baseURI = uri;
  }

  function getBaseURI() public view virtual returns (string memory) {
    return baseURI;
  }
}