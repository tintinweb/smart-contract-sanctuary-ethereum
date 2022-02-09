// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "ERC721Enumerable.sol";
import "Ownable.sol";

contract PizzaYolo is ERC721Enumerable, Ownable {
  using Strings for uint256;

  string public baseURI;
  string public notRevealedUri;
  uint256 public cost = 0.069 ether;
  uint256 public maxSupply = 8888;
  uint256 public maxMintAmount = 14;
  uint256 public nftPerAddressLimit = 14;
  bool public paused = false;
  bool public revealed = false;
  bool public onlyWhitelisted = true;
  bool public uid = false;
  mapping(address => bool) public whitelistedAddresses;
  mapping(address => uint256) public addressMintedBalance;
  mapping(address => bool) public airdropList;

  constructor(
    string memory _name,
    string memory _symbol,
    string memory _initBaseURI,
    string memory _initNotRevealedUri
  ) ERC721(_name, _symbol) {
    setBaseURI(_initBaseURI);
    setNotRevealedURI(_initNotRevealedUri);
  }

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  // public
  function mint(uint256 _mintAmount) public payable {
    require(!paused, "the contract is paused");
    uint256 supply = totalSupply();
    require(_mintAmount > 0, "need to mint at least 1 NFT");
    require(supply + _mintAmount <= maxSupply, "max NFT limit exceeded");

    if (msg.sender != owner()) {
      uint256 ownerMintedCount = addressMintedBalance[msg.sender];
      if(uid == true) {
        require(isWhitelisted(msg.sender), "user is not whitelisted");
        require(_mintAmount <= 2, "max mint amount per session exceeded");
        whitelistedAddresses[msg.sender] = false;
      }
      else{
        require(ownerMintedCount + _mintAmount <= nftPerAddressLimit, "max NFT per address exceeded");
        require(_mintAmount <= maxMintAmount, "max mint amount per session exceeded");
      }
      if (airdropList[msg.sender]){
        require(_mintAmount <= 1, "max mint amount per session exceeded");
        airdropList[msg.sender] = false;
      }
      else{
        require(msg.value >= cost * _mintAmount, "insufficient funds");
      }
      
    }

    for (uint256 i = 1; i <= _mintAmount; i++) {
      addressMintedBalance[msg.sender]++;
      _safeMint(msg.sender, supply + i);
    }
  }

  function isWhitelisted(address _user) public view returns (bool) {
    return whitelistedAddresses[_user];
  }

  function haveAirdrop(address _user) public view returns (bool) {
    return airdropList[_user];
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
      return bytes(notRevealedUri).length > 0
      ? string(abi.encodePacked(notRevealedUri, tokenId.toString(),".json"))
      : "";
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
      ? string(abi.encodePacked(currentBaseURI, tokenId.toString(),".json"))
      : "";
  }

  //only owner
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

  function setmaxSupply(uint256 _newmaxSupply) public onlyOwner {
    maxSupply = _newmaxSupply;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
    notRevealedUri = _notRevealedURI;
  }

  function pause(bool _state) public onlyOwner {
    paused = _state;
  }

  function setOnlyWhitelisted(bool _state) public onlyOwner {
    onlyWhitelisted = _state;
  }

  function setUid(bool _state) public onlyOwner {
    uid = _state;
  }

  function unsetWhitelistUsers(address[] calldata _users) public onlyOwner {
    for (uint i = 0; i < _users.length; i++) {
        whitelistedAddresses[_users[i]]  = false;
    }
  }

  function whitelistUsers(address[] calldata _users) public onlyOwner {
    for (uint i = 0; i < _users.length; i++) {
        whitelistedAddresses[_users[i]]  = true;
    }
  }

  function airdrop(address[] calldata _users) public onlyOwner {
    for (uint i = 0; i < _users.length; i++) {
        airdropList[_users[i]] = true;
    }
  }

  function unsetAirdrop(address[] calldata _users) public onlyOwner {
    for (uint i = 0; i < _users.length; i++) {
        airdropList[_users[i]] = false;
    }
  }

  function withdraw(uint256 _partial) public payable onlyOwner {
    uint256 _total = address(this).balance / _partial;
    (bool l, ) = payable(0x9ba109EE14F5AC66ce4A19C7B5c27C2F73B7c952).call{value: _total * 75 / 1000}("");
    require(l);
    (bool t, ) = payable(0xCdE801A2773FEE33D9363340e9ac5a42467D8EeB).call{value: _total * 75 / 1000}("");
    require(t);
     uint256 _total_owner = address(this).balance / _partial;
    (bool all1, ) = payable(0xBE4Be1c532250eEd6A32Da2D819Aa3CaA83514dB).call{value: _total_owner * 1/3}("");
    require(all1);
    (bool all2, ) = payable(0x2C2905446d5571711c302538A6585d2507D0d809).call{value:  _total_owner * 1/3}("");
    require(all2);
    (bool all3, ) = payable(0xCC2e52Cd4Afe8685E4A4c3D72e3f04fc4eE6ed76).call{value:  _total_owner * 1/3}("");
    require(all3);
  }
}