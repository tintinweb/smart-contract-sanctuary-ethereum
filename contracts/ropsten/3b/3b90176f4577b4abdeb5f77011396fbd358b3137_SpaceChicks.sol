// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";

contract SpaceChicks is ERC721A, Ownable {
  using Strings for uint256;

  enum Status { SALE_NOT_LIVE, PRESALE_LIVE, SALE_LIVE }

  uint256 public constant SUPPLY_MAX = 11_111;
  uint256 public constant RESERVE_MAX = 100;
  uint256 public constant PRESALE_PRICE = 0.06 ether;
  uint256 public constant PRICE = 0.08 ether;

  Status public state;
  bool public revealed;
  string public baseURI;

  uint256 private _reservedTokens;

  constructor() ERC721A("SpaceChicks", "SPACECHICKS") {
    _safeMint(address(this), 1);
    _burn(0);
  }

  function reserveTokens(address to, uint256 quantity) external onlyOwner {
    require(_reservedTokens + quantity <= RESERVE_MAX, "SpaceChicks: Reserved Tokens Already Minted");
    _reservedTokens += quantity;
    _safeMint(to, quantity);
  }

  function mint(uint256 quantity) external payable {
    require((state == Status.SALE_LIVE || state == Status.PRESALE_LIVE), "SpaceChicks: Sale Not Live");
    require(msg.sender == tx.origin, "SpaceChicks: Contract Interaction Not Allowed");
    require(totalSupply() + quantity <= SUPPLY_MAX, "SpaceChicks: Exceed Max Supply");
    require(quantity <= 10, "SpaceChicks: Exceeds Max Per TX");

    if(state == Status.PRESALE_LIVE) {
      require(_numberMinted(msg.sender) + quantity <= 2, "SpaceChicks: Exceeds Max Per Wallet");
      require(msg.value >= PRESALE_PRICE * quantity, "SpaceChicks: Insufficient ETH");
    } else {
      require(msg.value >= PRICE * quantity, "SpaceChicks: Insufficient ETH");
    }

    _safeMint(msg.sender, quantity);
  }

  function setSaleState(Status _state) external onlyOwner {
    state = _state;
  }

  function updateBaseURI(string memory newURI, bool reveal) external onlyOwner {
    baseURI = newURI;
    if(reveal) {
      revealed = reveal;
    }
  }

  function withdraw() external onlyOwner {
    payable(msg.sender).transfer(address(this).balance);
  }

  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
    if (!revealed) return _baseURI();
    return string(abi.encodePacked(_baseURI(), tokenId.toString(), ".json"));
  }

  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }
}