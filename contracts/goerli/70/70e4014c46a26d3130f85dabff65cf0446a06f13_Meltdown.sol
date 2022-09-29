// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "ERC721A.sol";
import "Ownable.sol";
import "ReentrancyGuard.sol";
import "Strings.sol";

contract Meltdown is Ownable, ERC721A, ReentrancyGuard {
  constructor() ERC721A("Meltdown", "MELTDOWN") {}

  uint8 public PHASE = 0;
  uint256 public MINT_PRICE = 1;
  uint16 public immutable COLLECTION_SIZE = 3333;
  uint8 public immutable MAX_MINT_PER_ADDRESS_DURING_PUBLIC = 2;


  // Whitelists
  address[] public OG_WHITELIST;
  address[] public WL_WHITELIST;

  function find(address value, address[] storage whitelist) private view returns(uint) {
      uint i = 0;
      while (whitelist[i] != value) {
          i++;
      }
      return i;
  }

  function removeByIndex(uint i, address[] storage whitelist) private {
    while (i<whitelist.length-1) {
        whitelist[i] = whitelist[i+1];
        i++;
    }
    whitelist.pop();
  }
  
  // OG
  function removeOG(address addr) external onlyOwner {
      uint i = find(addr, OG_WHITELIST);
      removeByIndex(i, OG_WHITELIST);
  }

  function removeOG() public {
      uint i = find(msg.sender, OG_WHITELIST);
      removeByIndex(i, OG_WHITELIST);
  }

  function getOG() public view returns(address[] memory) {
      return OG_WHITELIST;
  }

  function addOG(address[] memory addresses) external onlyOwner {
    for (uint256 i = 0; i < addresses.length; i++) {
      OG_WHITELIST.push(addresses[i]);
    }
  }

  function isUserOnOG() public view returns (bool) {
    for (uint256 i = 0; i < OG_WHITELIST.length; i++) {
      if (msg.sender == OG_WHITELIST[i]) {
        return true;
      }
    }
    return false;
  }

  // WL
  function removeWL(address addr) external onlyOwner {
      uint i = find(addr, WL_WHITELIST);
      removeByIndex(i, WL_WHITELIST);
  }

  function removeWL() public {
      uint i = find(msg.sender, WL_WHITELIST);
      removeByIndex(i, WL_WHITELIST);
  }

  function getWL() public view returns(address[] memory) {
      return WL_WHITELIST;
  }

  function addWL(address[] memory addresses) external onlyOwner {
    for (uint256 i = 0; i < addresses.length; i++) {
      WL_WHITELIST.push(addresses[i]);
    }
  }

  function isUserOnWL() public view returns (bool) {
    for (uint256 i = 0; i < WL_WHITELIST.length; i++) {
      if (msg.sender == WL_WHITELIST[i]) {
        return true;
      }
    }
    return false;
  }


  // mint (combined)

  function mint(uint256 quantity) external payable {
    require(PHASE > 0 && PHASE <= 3, "The mint hasn't started yet");

    require(
      totalSupply() + quantity <= COLLECTION_SIZE,
      "not enough remaining NFTs to support desired mint amount"
    );

    if (PHASE == 1) { // public mint
      require(
        numberMinted(msg.sender) + quantity <= MAX_MINT_PER_ADDRESS_DURING_PUBLIC,
        "can not mint this many"
      );
    } else if (PHASE == 2) { // OG mint
      require(isUserOnOG(), "Address not found on the OG whitelist.");
      removeWL();
    } else if (PHASE == 3) { // WL mint
      require(isUserOnWL(), "Address not found on the WL whitelist.");
      removeOG();
    } else {
      revert("Configuration error: PHASE is invalid");
    }
    
    uint256 totalCost = MINT_PRICE * quantity;
    _mint(msg.sender, quantity);
    refundIfOver(totalCost);

    _mint(msg.sender, quantity);
  }
  
  function numberMinted(address owner) public view returns (uint256) {
    return _numberMinted(owner);
  }

  function setPhase(uint8 phase) external onlyOwner {
    PHASE = phase;
  }

  function refundIfOver(uint256 price) private {
    require(msg.value >= price, "Need to send more ETH.");
    if (msg.value > price) {
      payable(msg.sender).transfer(msg.value - price);
    }
  }

  // Tools
  
  // // metadata URI
  string private _baseTokenURI;

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function setBaseURI(string calldata baseURI) external onlyOwner {
    _baseTokenURI = baseURI;
  }

  function withdrawMoney() external onlyOwner nonReentrant {
    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    require(success, "Transfer failed.");
  }

  function getOwnershipData(uint256 tokenId)
    external
    view
    returns (TokenOwnership memory)
  {
    return _ownershipOf(tokenId);
  }
}