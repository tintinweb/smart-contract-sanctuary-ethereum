// SPDX-License-Identifier: MIT
//
// Made by: NFT Stack
//          https://nftstack.info
//

pragma solidity ^0.8.1;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract UnusualGuests is ERC721Enumerable, Ownable {
  uint256 public mintPrice = 0.0678 ether;
  uint256 public preSaleMintPrice = 0.0678 ether;

  string _baseTokenURI;
  string public PROVENANCE = "";

  bool public isMintActive = false;
  bool public isPreSaleMintActive = false;
  bool public isClosedMintForever = false;

  uint256 public maximumMintSupply = 4567;
  uint256 public maximumAllowedTokensPerPurchase = 5;

  address private OtherAddress = 0x669fbb9A6c3186E00198B8756fDA4B64500208c1;

  mapping(address => uint8) private _allowList;

  event AssetMinted(uint256 tokenId, address sender);
  event SaleActivation(bool isMintActive);

  constructor(string memory baseURI) ERC721("Unusual Guests", "UG") {
    setBaseURI(baseURI);
  }

  modifier saleIsOpen {
    require(totalSupply() <= maximumMintSupply, "Sale has ended.");
    _;
  }

  modifier onlyAuthorized() {
    require(owner() == msg.sender);
    _;
  }

  function setMintActive(bool val) public onlyAuthorized {
    isMintActive = val;
    emit SaleActivation(val);
  }

  function setIsPreSaleMintActive(bool _isPreSaleMintActive) external onlyAuthorized {
    isPreSaleMintActive = _isPreSaleMintActive;
  }

  function addToAllowList(address[] calldata addresses, uint8 numAllowedToMint) external onlyAuthorized {
    for (uint256 i = 0; i < addresses.length; i++) {
      require(addresses[i] != address(0), "Can't add a null address");
      _allowList[addresses[i]] = numAllowedToMint;
    }
  }

  function numAvailableToMint(address addr) external view returns (uint8) {
    return _allowList[addr];
  }

  function setProvenanceHash(string memory provenanceHash) public onlyAuthorized {
    PROVENANCE = provenanceHash;
  }

  function setBaseURI(string memory baseURI) public onlyAuthorized {
    _baseTokenURI = baseURI;
  }

  function setMintPrice(uint256 _mintPrice) public onlyAuthorized() {
    mintPrice = _mintPrice;
  }

  function setPreSaleMintPrice(uint256 _preSaleMintPrice) public onlyAuthorized() {
    preSaleMintPrice = _preSaleMintPrice;
  }

  function setIsClosedMintForever() external onlyAuthorized {
    isClosedMintForever = true;
  }

  function getTotalSupply() external view returns (uint256) {
    return totalSupply();
  }

  function getContractOwner() public view returns (address) {
    return owner();
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function reserveToCustomWallet(address _walletAddress, uint256 _count) public onlyAuthorized {
    for (uint256 i = 0; i < _count; i++) {
      require(_walletAddress!= address(0), "Not Mint for the zero address");
      emit AssetMinted(totalSupply(), _walletAddress);
      _safeMint(_walletAddress, totalSupply());
    }
  }

  function mint(address _to, uint256 _count) public payable saleIsOpen {
    if (msg.sender != owner()) {
      require(isMintActive, "Sale is not active currently.");
    }

    require(totalSupply() + _count <= maximumMintSupply, "Purchase would exceed max tokens");
    require(
      _count <= maximumAllowedTokensPerPurchase,
      "Exceeds maximum allowed tokens"
    );
    require(!isClosedMintForever, "Mint Closed Forever");

    require(msg.value >= mintPrice * _count, "Insuffient ETH amount sent.");

    for (uint256 i = 0; i < _count; i++) {
      emit AssetMinted(totalSupply(), _to);
      _safeMint(_to, totalSupply());
    }
  }

  function preSaleMint(uint8 _count) public payable saleIsOpen {
    require(!isClosedMintForever, 'Mint Closed Forever');
    require(isPreSaleMintActive, 'Pre Sale Mint is not active');
    require(_count <= _allowList[msg.sender], 'Exceeded max available to purchase');
    require(_count + totalSupply() <= maximumMintSupply, 'Purchase would exceed max tokens');
    require(msg.value >= preSaleMintPrice * _count, 'Insuffient ETH amount sent.');

    _allowList[msg.sender] -= _count;
    for (uint256 i = 0; i < _count; i++) {
      emit AssetMinted(totalSupply(), msg.sender);
      _safeMint(msg.sender, totalSupply());
    }
  }

  function walletOfOwner(address _owner) external view returns(uint256[] memory) {
    uint tokenCount = balanceOf(_owner);
    uint256[] memory tokensId = new uint256[](tokenCount);

    for(uint i = 0; i < tokenCount; i++){
      tokensId[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokensId;
  }

  function withdraw() external onlyAuthorized {
    uint balance = address(this).balance;
    payable(OtherAddress).transfer(balance * 10000 / 10000);
    payable(owner()).transfer(balance * 0 / 10000);
  }
}