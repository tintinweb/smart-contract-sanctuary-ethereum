// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";

contract FemmesBizarre is ERC721A, Ownable {
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

  mapping(address => bool) public whitelist;

  event WhitelistedAddressAdded(address addr);
  event WhitelistedAddressRemoved(address addr);

  constructor() ERC721A("FemmesBizarre", "FB") {
    _safeMint(address(this), 1);
    _burn(0);
  }

  function reserveTokens(address to, uint256 quantity) external onlyOwner {
    require(_reservedTokens + quantity <= RESERVE_MAX, "FemmesBizarre: Reserved Tokens Already Minted");
    unchecked {
      _reservedTokens += quantity;
    }
    _safeMint(to, quantity);
  }

  function mint(uint256 quantity) external payable {
    require((state == Status.SALE_LIVE || state == Status.PRESALE_LIVE), "FemmesBizarre: Sale Not Live");
    require(msg.sender == tx.origin, "FemmesBizarre: Contract Interaction Not Allowed");
    require(totalSupply() + quantity <= SUPPLY_MAX, "FemmesBizarre: Exceed Max Supply");
    require(quantity <= 10, "FemmesBizarre: Exceeds Max Per TX");

    if(state == Status.PRESALE_LIVE) {
      require(whitelist[msg.sender], "FemmesBizarre: Sender not in WhiteList");
      require(_numberMinted(msg.sender) + quantity <= 2, "FemmesBizarre: Exceeds Max Per Wallet");
      require(msg.value >= PRESALE_PRICE * quantity, "FemmesBizarre: Insufficient ETH");
    } else {
      require(msg.value >= PRICE * quantity, "FemmesBizarre: Insufficient ETH");
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

  function addAddressToWhitelist(address user) onlyOwner public returns(bool success) {
    if (!whitelist[user]) {
      whitelist[user] = true;
      emit WhitelistedAddressAdded(user);
      success = true;
    }
  }

  function addAddressesToWhitelist(address[] calldata users) onlyOwner external returns(bool success) {
    unchecked {
      for (uint256 i = 0; i < users.length; i++) {
        if (addAddressToWhitelist(users[i])) {
          success = true;
        }
      }
    }
  }

  function removeAddressFromWhitelist(address user) onlyOwner public returns(bool success) {
    if (whitelist[user]) {
      whitelist[user] = false;
      emit WhitelistedAddressRemoved(user);
      success = true;
    }
  }

  function removeAddressesFromWhitelist(address[] calldata users) onlyOwner external returns(bool success) {
    unchecked {
      for (uint256 i = 0; i < users.length; i++) {
        if (removeAddressFromWhitelist(users[i])) {
          success = true;
        }
      }
    }
  }
}