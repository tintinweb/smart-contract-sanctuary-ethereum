//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract CooCooNFT is ERC721Enumerable, Ownable {
  using Strings for uint256;

  string public baseURI;
  string public baseExtension = ".json";
  string public notRevealedURI;
  bool public saleOn = false;
  bool public revealed = false;
  uint256 public maxSupply = 1111;
  uint256 public saleCost = 30000000000000000; // 0.03 eth
  uint256 public maxMintAmount = 20;
  mapping (address => bool) public team;

  constructor(
    string memory _name,
    string memory _symbol,
    string memory _initBaseURI,
    string memory _initNotRevealedURI
  ) ERC721(_name, _symbol) {
    setBaseURI(_initBaseURI);
    setNotRevealedURI(_initNotRevealedURI);
  }

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  function mint(address _to, uint256 _mintAmount) public payable {
    require(saleOn, "Sale must be ON");
    uint256 supply = totalSupply();

    if (team[msg.sender] == false) {
      require(saleOn, "Publicsale must be ON");
      require(_mintAmount > 0, "Mint abmount must be more than 0");
      require(supply + _mintAmount <= maxSupply, "Purchase would exceed max supply of NFTs");
      require(msg.value >= saleCost * _mintAmount, "Ether value sent is not correct");      
    }

    for (uint256 i = 1; i <= _mintAmount; i++) {
          _safeMint(_to, supply + i);
    } 
   }

  function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory) {
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
        returns (string memory) {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        if (revealed == false) {
          return notRevealedURI;
        }

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        baseExtension
                    )
                )
                : "";
  }

  function addTeam(address[] memory teamAddresses) public onlyOwner {
      for(uint256 i=0; i<teamAddresses.length;i++)
        {
            team[teamAddresses[i]] = true;
        }
  }

  function setSaleCost(uint256 _saleCost) public onlyOwner {
    saleCost = _saleCost;
  }

  function setMaxMintAmount(uint256 _maxMintAmount) public onlyOwner {
    maxMintAmount = _maxMintAmount;
  }

  function setMaxSupply(uint256 _maxSupply) public onlyOwner {
    maxSupply = _maxSupply;
  }
    
  function flipSaleOn() public onlyOwner {
    saleOn = !saleOn;
  }

  function flipRevealed() public onlyOwner {
    revealed = !revealed;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function setNotRevealedURI(string memory _newNotRevealedURI) public onlyOwner {
    notRevealedURI = _newNotRevealedURI;
  }
  
  function setBaseExtension(string memory _newBaseExtension)
        public
        onlyOwner {
        baseExtension = _newBaseExtension;
  }

  function withdrawAll() external onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
  }

  function withdrawSome(uint _eth) external onlyOwner {
        payable(msg.sender).transfer(_eth);
  }
}