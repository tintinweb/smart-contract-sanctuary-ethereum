// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";
import "./IERC20.sol";

contract PepeLegion is ERC721A, Ownable, ReentrancyGuard {
  uint256 public totalMintedByLegion;
  uint256 public immutable maxLegionMint = 1111;
  uint256 public immutable maxPerAddress;
  uint256 public immutable maxSupply;

  uint256 immutable cost = 0.002 ether;

  IERC20 public erc20Token;

  string public _baseTokenURI;

  mapping(address => bool) public addressLegionMint;

  constructor(
    uint256 maxBatchSize_,
    uint256 collectionSize_,
    address erc20TokenAddress,
    string memory initURI_
  ) ERC721A("PepeLegion", "LEGION", maxBatchSize_, collectionSize_) {
    maxPerAddress = maxBatchSize_;
    maxSupply = collectionSize_;
    erc20Token = IERC20(erc20TokenAddress);
    _baseTokenURI = initURI_;
  }

  modifier callerIsUser() {
    require(tx.origin == msg.sender, "caller is another contract");
    _;
  }

  function legionMint() external callerIsUser {
    require(erc20Token.balanceOf(msg.sender) > 0, "insufficient token balance");
    require(!addressLegionMint[msg.sender], "address has already minted");
    require(totalMintedByLegion + 1 <= maxLegionMint, "reached max legion mints");
    require(totalSupply() + 1 <= maxSupply, "reached max supply");

    _safeMint(msg.sender, 1);
    addressLegionMint[msg.sender] = true;
    totalMintedByLegion ++;
  }

  function mint(uint256 quantity) external payable callerIsUser {
    require(quantity > 0, "cannot mint less than one");
    require(msg.value >= cost * quantity, "not enough funds");
    require(totalSupply() + quantity <= maxSupply, "reached max supply");
    require(quantity <= maxPerAddress, "can not mint this many");
    
    _safeMint(msg.sender, quantity);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function setBaseURI(string calldata baseURI) external onlyOwner {
    _baseTokenURI = baseURI;
  }

  function withdraw() public onlyOwner nonReentrant {
    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
  }

  function getOwnershipData(uint256 tokenId)
    external
    view
    returns (TokenOwnership memory)
  {
    return ownershipOf(tokenId);
  }
}