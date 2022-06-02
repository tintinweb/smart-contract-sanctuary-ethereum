// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "Ownable.sol";
import "ReentrancyGuard.sol";
import "Address.sol"; 

contract FBI is ERC721A, Ownable, ReentrancyGuard {
  using Address for address;
  using Strings for uint;

  string  public  baseURI = "ipfs://QmZN15KDcnqpreKMMaJFbbhxtVTANtBaqTMRBcP4A6MqNv";

  uint256 public  maxSupply = 1111;
  uint256 public  FREE_MINTS_PER_USER = 2;
  uint256 public  PUBLIC_SALE_PRICE = 0.005 ether;
  uint256 public  TOTAL_FREE_MINTS = 2;
  bool public isPublicSaleActive = true;

  constructor(

  ) ERC721A("Freeblock", "FBI") {

  }

  function mint(uint256 numberOfTokens)
      external
      payable
  {
    require(
      totalSupply() + numberOfTokens <= maxSupply,
      "Maximum supply exceeded"
    );
    require(
        numberOfTokens < 21,
        "Max mint per txn is 20"
    );
    require(
        (PUBLIC_SALE_PRICE * numberOfTokens) <= msg.value,
        "Incorrect ETH value sent"
    );
    _safeMint(msg.sender, numberOfTokens);
  }

  function freeMint() public nonReentrant {
    require(_numberMinted(msg.sender) < FREE_MINTS_PER_USER, "You Must Pay You Greedy Goblin");
    require(
      totalSupply() + 2 <= TOTAL_FREE_MINTS,
      "Maximum supply exceeded"
    );
    _safeMint(msg.sender, 2);
  }

  function setBaseURI(string memory baseURI_)
    public
    onlyOwner
  {
    baseURI = baseURI_;
  }

  function treasuryMint(uint quantity, address user)
    public
    onlyOwner
  {
    require(
      totalSupply() + quantity <= maxSupply,
      "Maximum supply exceeded"
    );
    _safeMint(user, quantity);
  }

  function withdraw()
    public
    onlyOwner
  {
    uint256 balance = address(this).balance;
    payable(msg.sender).transfer(balance);
  }

  function tokenURI(uint _tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(_tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );
    return string(abi.encodePacked(baseURI, "/", _tokenId.toString(), ".json"));
  }

  function _baseURI()
    internal
    view
    virtual
    override
    returns (string memory)
  {
    return baseURI;
  }

  function setNumFreeMints(uint256 _numfreemints)
    external
  onlyOwner
  {
      TOTAL_FREE_MINTS = _numfreemints;
  }

  function setSalePrice(uint256 _price)
      external
      onlyOwner
  {
      PUBLIC_SALE_PRICE = _price;
  }


}