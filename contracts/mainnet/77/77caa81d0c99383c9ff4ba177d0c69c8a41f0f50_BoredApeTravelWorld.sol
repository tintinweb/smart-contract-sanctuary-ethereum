// SPDX-License-Identifier: GPL-3.0


pragma solidity >=0.7.0 <0.9.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract BoredApeTravelWorld is ERC721Enumerable, Ownable {
  using Strings for uint256;

  string public baseURI = "ipfs://QmRrXBSb76QAP8phAoiCyfzAtyHbEVxkJj5kbhnxszyqCq/";
  string public baseExtension = ".json";
  uint256 public cost = 0 ether;
  uint256 public maxSupply = 4000;
  uint256 public maxMintAmount = 2;
  bool public isMintActive = false;
  mapping(address => bool) public whitelisted;

  mapping(address => uint) public minted;

constructor() ERC721("Bored Ape Travel World", "BATW") {}

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  // public
  function mint(uint256 _mintAmount) public payable {
    uint256 supply = totalSupply();
    require(isMintActive, "BATW: Minting needs to be enabled.");
    require(_mintAmount > 0);
    require(supply + _mintAmount <= maxSupply, "BATW: Mint/order exceeds supply");
    require(_mintAmount + minted[msg.sender] <= maxMintAmount, "BATW: mintAmount must be less than or equal maxMintAmount");

    minted[msg.sender] += _mintAmount;
    for (uint256 i = 1; i <= _mintAmount; i++) {
      _safeMint(msg.sender, supply + i);
    }
  }

  function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory tokenIds = new uint256[](ownerTokenCount);
    for (uint256 i; i < ownerTokenCount; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokenIds;
  }

  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
  }

  //only owner
  function airdrop(uint[] calldata amount, address[] calldata recipient) public onlyOwner {
    require(amount.length == recipient.length, "BATW: Must provide equal amounts and recipients");

    uint totalAmount;
    uint supply = totalSupply();
    for(uint i; i < amount.length; i++) {
      totalAmount += amount[i];
    }
    require(supply + totalAmount < maxSupply, "BATW: Mint/order exceeds supply");

    for(uint i; i < recipient.length; i++) {
      for(uint j = 1; j <= amount[i]; j++) {
        _safeMint(recipient[i], supply + j);
      }
    }
  }

  function setCost(uint256 _newCost) public onlyOwner {
    cost = _newCost;
  }

  function setMaxSupply(uint256 _newSupply) public onlyOwner {
    maxSupply = _newSupply;
  }

  function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
    maxMintAmount = _newmaxMintAmount;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
  }

  function setMintingActive(bool _state) public onlyOwner {
    require(isMintActive != _state, "BATW: New value matches old");
    isMintActive = _state;
  }
 
  function whitelistUser(address _user) public onlyOwner {
    whitelisted[_user] = true;
  }
 
  function removeWhitelistUser(address _user) public onlyOwner {
    whitelisted[_user] = false;
  }

  function withdraw() public payable onlyOwner {
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
  }
}