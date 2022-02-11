// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract NFT is ERC721Enumerable, Ownable 
{
  using Strings for uint256;

  string public baseURI;
  string public baseExtension = ".json";
  string public notRevealedUri;
  uint256 public cost = 0.02 ether;
  uint256 public maxSupply = 9898;
  uint256 public maxMintAmount = 10;
  uint256 public nftPerAddressLimit = 3;
  bool public paused = false;
  bool public revealed = false;
  bool public onlyWhitelisted = true;
  mapping (address => bool) public whitelistedAddresses;
  mapping(address => uint256) public addressMintedBalance;


  constructor(
    string memory _name,
    string memory _symbol,
    string memory _initBaseURI,
    string memory _initNotRevealedUri
  ) ERC721(_name, _symbol) {
    setBaseURI(_initBaseURI);
    setNotRevealedURI(_initNotRevealedUri);
  }

  // baseURI of NFT Metdata
  function _baseURI() internal view virtual override returns (string memory) 
  {
    return baseURI;
  }

  // Mint Function
  function mint(uint256 _mintAmount) public payable 
  {
    require(!paused, "The contract is paused");
    uint256 supply = totalSupply();
    require(_mintAmount > 0, "Minimum of 1 NFT to mint");
    require(_mintAmount <= maxMintAmount, "Max Mint Amount Exceeded");
    require(supply + _mintAmount <= maxSupply, "NFT Supply Exceeded");

    if (msg.sender != owner()) 
    {
        if(onlyWhitelisted == true) 
        {
            require(isWhitelisted(msg.sender), "Address not Whitelisted");
            uint256 ownerMintedCount = addressMintedBalance[msg.sender];
            require(ownerMintedCount + _mintAmount <= nftPerAddressLimit, "Address has more than maximum NFT limit per address");
        }
        require(msg.value >= cost * _mintAmount, "Insufficient funds");
    }
    
    for (uint256 i = 1; i <= _mintAmount; i++) 
    {
        addressMintedBalance[msg.sender]++;
      _safeMint(msg.sender, supply + i);
    }
  }

  //Verify if user is whitelisted
  function isWhitelisted(address _user) public view returns (bool) 
  {
    if( whitelistedAddresses[_user] == true )
    {
      return true;
    }
    return false;
  }
  function walletOfOwner(address _owner) public view returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory tokenIds = new uint256[](ownerTokenCount);
    for (uint256 i; i < ownerTokenCount; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokenIds;
  }
  //Returns the tokenURI for requested id
  function tokenURI(uint256 tokenId) public view virtual override returns (string memory)
  {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );
    
    if(revealed == false) 
    {
        return notRevealedUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
  }

  //Can Only Be Used By Owner of contract
  function reveal() public onlyOwner 
  {
      revealed = true;
  }
  
  function setNftPerAddressLimit(uint256 _limit) public onlyOwner 
  {
    nftPerAddressLimit = _limit;
  }
  
  function setCost(uint256 _newCost) public onlyOwner 
  {
    cost = _newCost;
  }

  function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner 
  {
    maxMintAmount = _newmaxMintAmount;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner 
  {
    baseURI = _newBaseURI;
  }

  function setBaseExtension(string memory _newBaseExtension) public onlyOwner 
  {
    baseExtension = _newBaseExtension;
  }
  
  function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner 
  {
    notRevealedUri = _notRevealedURI;
  }

  function pause(bool _state) public onlyOwner 
  {
    paused = _state;
  }
  
  function setOnlyWhitelisted(bool _state) public onlyOwner 
  {
    onlyWhitelisted = _state;
  }
  
  function addToWhitelist(address _newAddress) public onlyOwner 
  {
     whitelistedAddresses[_newAddress] = true;
  }
  function removeFromWhitelist(address _newAddress) public onlyOwner 
  {
      whitelistedAddresses[_newAddress] = false;
  }
  function addMultipleToWhitelist(address[] calldata _addresses) public onlyOwner 
  {
        require(_addresses.length <= 10000, "Provide less addresses in one function call");
        for (uint256 i = 0; i < _addresses.length; i++) 
        {
            whitelistedAddresses[_addresses[i]] = true;
        }
  }
  function removeMultipleFromWhitelist(address[] calldata _addresses) public onlyOwner 
  {
        require(_addresses.length <= 10000, "Provide less addresses in one function call");
        for (uint256 i = 0; i < _addresses.length; i++) 
        {
            whitelistedAddresses[_addresses[i]] = false;
        }
  }
  function withdraw() public payable onlyOwner 
  {
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
  }
}