// SPDX-License-Identifier: MIT
// compiler version must be greater than or equal to 0.8.10 and less than 0.9.0
pragma solidity ^0.8.4;

import "./ERC721Enumerable.sol";
import "./INFTTamagoshi.sol";
import "./NFTTamagoshi.sol";
import "./Food.sol";
import "./Strings.sol";
import "./Pay.sol";

contract FactoryTamagoshi is ERC721Enumerable, Payable, Feedable {
  using Strings for uint256;

  string public baseURI;
  string public baseExtension = ".json";
  uint256 public maxSupply = 1000; //тут пишите общее количество нфт в вашей коллекции
  uint256 public maxMintAmount = 5;  // количество нфт которое можно сминтить при 1 транзакции
  bool public paused = false;
  mapping(address => bool) public whitelisted;
  mapping(uint256 => address) public tokenContract; // Return address of any NFT

  constructor(
    string memory _name,
    string memory _symbol,
    string memory _initBaseURI
  ) ERC721(_name, _symbol) {
    setBaseURI(_initBaseURI);
  }

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }
    // merge 2 words in 1 string
    // I using its for creating pretty name like "Tamagoshi #1"
  function nameWithTokenId(string memory _name) internal view returns (string memory){
    string memory supply = Strings.toString(totalSupply() + 1);
    return string(abi.encodePacked(_name,' #', supply));
  }

  // public
  function mint(
      address _to, 
      string memory _stablecoin,
      uint256 _mintAmount, 
      string memory _name
    ) public payable {
    uint256 supply = totalSupply();
    require(!paused);
    require(_mintAmount > 0);
    require(_mintAmount <= maxMintAmount);
    require(supply + _mintAmount <= maxSupply);

    if (msg.sender != owner()) {
        if(whitelisted[msg.sender] != true) {
          require(Pay(_stablecoin, _mintAmount), "Pay: Transfer was declined");
        }
    }

    for (uint256 i = 1; i <= _mintAmount; i++) {
      uint256 tokenId = supply + i;

      Tamagoshi nft = new Tamagoshi(
        nameWithTokenId(_name),
        ERC721.symbol(),
        tokenId,
        address(this)
      );
      _safeMint(_to, tokenId);
      tokenContract[tokenId] = address(nft);
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

  // NFT functions
  
  function feedUp(uint _tokenId, uint _amount) external {
    require(foodPay(_amount), "Factory - foodPay: Something went wrong");
    uint _time = foodTime() * _amount;
    INFTTamagoshi(tokenContract[_tokenId]).feed(_time);
  }

  function born(uint _tokenId) external {
    require(msg.sender == ownerOf(_tokenId), "Factory - born: You are not owner");
    INFTTamagoshi(tokenContract[_tokenId]).born();
  }  

  //only owner

  function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
    maxMintAmount = _newmaxMintAmount;
  }
  
  function setmaxSupply(uint256 _newmaxSupply) public onlyOwner {
    maxSupply = _newmaxSupply;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
  }

  function pause(bool _state) public onlyOwner {
    paused = _state;
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