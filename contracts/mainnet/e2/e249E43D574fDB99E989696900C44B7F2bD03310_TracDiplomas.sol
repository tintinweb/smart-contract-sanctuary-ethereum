// SPDX-License-Identifier: GPL-3.0
//A Solidity Contract by Crypto N That

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

pragma solidity >=0.7.0 <0.9.0;

contract deployedContract {
    function ownerOf(uint256) public returns (address) {}
    function balanceOf(address) public returns (uint256) {}
}

contract TracDiplomas is ERC721Enumerable, Ownable {
  using Strings for uint256;

  string baseURI;
  address public checkerContract;
  string public baseExtension = ".json";
  uint256 public cost = 0 ether;
  uint256 public maxSupply = 8888;
  bool public paused = false;
  bool public revealed = false;
  string public notRevealedUri;
  mapping(address => uint256) public nftsMintedByAddress;
  mapping(address => uint256) public nftsAllowedToMint;

  constructor(
    string memory _name,
    string memory _symbol,
    string memory _initBaseURI,
    string memory _initNotRevealedUri
  ) ERC721(_name, _symbol) {
    setBaseURI(_initBaseURI);
    setNotRevealedURI(_initNotRevealedUri);
  }

  //INTERNAL
  function checkOwned(address _senderAddress, address  _contractAddress) internal returns (uint256) {
      return deployedContract(_contractAddress).balanceOf(_senderAddress);
  }

  //refreshAllowedMint
  function refreshNftsAllowedToMint(address _address) public returns (uint256)  {
      uint256 senderBalance = checkOwned(_address, checkerContract);
      if (senderBalance > 0) {
        if (senderBalance < 10) {
            nftsAllowedToMint[_address] = 1;
            return 1;
        } else {
            uint256 mintBalance;
            if (senderBalance % 10 == 0) {
                mintBalance = (senderBalance / 10);
            } else {
                mintBalance = (senderBalance / 10) + 1;
            }
            nftsAllowedToMint[_address] = mintBalance;
            return mintBalance;
        }
      } else {
          return 0;
      }
  }

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  // public
  function mintDiploma(uint256 _mintAmount) public payable {
    refreshNftsAllowedToMint(msg.sender);
    require(nftsAllowedToMint[msg.sender] > 0);
    uint256 supply = totalSupply();
    uint256 nftsAllowed = nftsAllowedToMint[msg.sender] - nftsMintedByAddress[msg.sender];
    require(!paused);
    require(_mintAmount > 0);
    require(_mintAmount <= nftsAllowed);
    require(supply + _mintAmount <= maxSupply);

    if (msg.sender != owner()) {
      require(msg.value >= cost * _mintAmount);
    }

    for (uint256 i = 1; i <= _mintAmount; i++) {
      uint256 currentMinted = nftsMintedByAddress[msg.sender];
      _safeMint(msg.sender, supply + i);
      nftsMintedByAddress[msg.sender] = currentMinted + 1;
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
    
    if(revealed == false) {
        return notRevealedUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
  }

  //only owner
  function setCheckerContract(address _contractAddress) public onlyOwner {
    checkerContract = _contractAddress;
  }

  function reveal() public onlyOwner {
      revealed = true;
  }
  
  function setCost(uint256 _newCost) public onlyOwner {
    cost = _newCost;
  }
  
  function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
    notRevealedUri = _notRevealedURI;
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
 
  function withdraw() public payable onlyOwner {
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
  }
}