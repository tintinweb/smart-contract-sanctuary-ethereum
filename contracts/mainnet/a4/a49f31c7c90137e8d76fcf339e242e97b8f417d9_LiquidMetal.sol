///////////////////////////////////////////////////////////////////////////
//                                                                       //
//▄▄▄█████▓ ██▀███   ██▓ ██▓███   ██▓    ▓█████      ██████  ██▓▒██   ██▒//
//▓  ██▒ ▓▒▓██ ▒ ██▒▓██▒▓██░  ██▒▓██▒    ▓█   ▀    ▒██    ▒ ▓██▒▒▒ █ █ ▒░//
//▒ ▓██░ ▒░▓██ ░▄█ ▒▒██▒▓██░ ██▓▒▒██░    ▒███      ░ ▓██▄   ▒██▒░░  █   ░//
//░ ▓██▓ ░ ▒██▀▀█▄  ░██░▒██▄█▓▒ ▒▒██░    ▒▓█  ▄      ▒   ██▒░██░ ░ █ █ ▒ //
//  ▒██▒ ░ ░██▓ ▒██▒░██░▒██▒ ░  ░░██████▒░▒████▒   ▒██████▒▒░██░▒██▒ ▒██▒//
//  ▒ ░░   ░ ▒▓ ░▒▓░░▓  ▒▓▒░ ░  ░░ ▒░▓  ░░░ ▒░ ░   ▒ ▒▓▒ ▒ ░░▓  ▒▒ ░ ░▓ ░//
//    ░      ░▒ ░ ▒░ ▒ ░░▒ ░     ░ ░ ▒  ░ ░ ░  ░   ░ ░▒  ░ ░ ▒ ░░░   ░▒ ░//
//  ░        ░░   ░  ▒ ░░░         ░ ░      ░      ░  ░  ░   ▒ ░ ░    ░  //
//            ░      ░               ░  ░   ░  ░         ░   ░   ░    ░  //
///////////////////////////////////////////////////////////////////////////
//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";

contract LiquidMetal is ERC721A, Ownable {
  using Strings for uint256;

  string baseURI;
  string public baseExtension = ".json";
  string public notRevealedUri;
  uint256 public cost = 0.02 ether;
  uint256 public maxSupply = 6666;
  uint256 public maxMintAmount = 5;
  uint256 public nftPerAddressLimit = 15;

  bool public paused = true;
  bool public revealed = false;
  bool public onlyWhitelisted = true;
  bool public pausedBurn = true;
  mapping(address => bool) public whitelist;
  mapping(address => uint256) public addressMintedBalance;

  constructor(
    string memory _name,
    string memory _symbol,
    string memory _initBaseURI,
    string memory _initNotRevealedUri
  ) ERC721A(_name, _symbol) {
    setBaseURI(_initBaseURI);
    setNotRevealedURI(_initNotRevealedUri);
  }

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  // public
  function mint(uint256 _mintAmount) public payable {
    uint256 supply = totalSupply();
    require(_mintAmount > 0, "ERROR: mintAmount must be higher than 0");
    require(supply + _mintAmount <= maxSupply, "ERROR: Too many tokens. Reduce mintAmount so that the totalSupply doesnt exceed maxSupply.");

    if (msg.sender != owner()) {
        require(!paused, "ERROR: Public sale is paused.");
        require(_mintAmount <= maxMintAmount, "ERROR: You are exceeding the maximum allowed tokens to mint per transaction.");
        if(onlyWhitelisted == true) {
            require(isWhitelisted(msg.sender), "ERROR: User is not whitelisted");
            uint256 ownerMintedCount = addressMintedBalance[msg.sender];
            require(ownerMintedCount + _mintAmount <= nftPerAddressLimit, "ERROR: Max NFT per address exceeded");
        }
        require(msg.value >= cost * _mintAmount, "ERROR: Cost doesn't match");
    }

    _safeMint(msg.sender, _mintAmount);
    addressMintedBalance[msg.sender] += _mintAmount;
  }

  function isWhitelisted(address _user) public view returns (bool) {
    return whitelist[_user];
  }

  function burnToken(uint256 tokenId) public {
    require(!pausedBurn,"ERROR: Burn is paused");
    _burn(tokenId);
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

  function reveal() public onlyOwner {
    revealed = true;
  }

  function setNftPerAddressLimit(uint256 _limit) public onlyOwner {
    nftPerAddressLimit = _limit;
  }
  
  function setCost(uint256 _newCost) public onlyOwner {
    cost = _newCost;
  }

  function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
    maxMintAmount = _newmaxMintAmount;
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

  function pauseBurn(bool _state) public onlyOwner {
    pausedBurn = _state;
  }

  function setOnlyWhitelisted(bool _state) public onlyOwner {
    onlyWhitelisted = _state;
  }

  function whitelistUsers(address[] calldata addresses) external onlyOwner {
    for (uint256 i = 0; i < addresses.length; i++) {
      whitelist[addresses[i]] = true;
    }
  }

  function removeUsersFromWhitelist(address[] calldata addresses) external onlyOwner {
    for (uint256 i = 0; i < addresses.length; i++) {
      whitelist[addresses[i]] = false;
    }
  }
 
  function withdraw() public payable onlyOwner {
    uint256 balance = address(this).balance;
    uint256 dev_share = (balance * 13) / 100;
    payable(0x553963D4f8a92FdAfE28B1828bc0dc137732ee3F).transfer(dev_share);
    payable(owner()).transfer(address(this).balance);
  }
}