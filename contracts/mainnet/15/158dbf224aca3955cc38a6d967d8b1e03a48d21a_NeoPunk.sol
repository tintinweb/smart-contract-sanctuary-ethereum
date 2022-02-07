// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "ERC721Enumerable.sol";
import "Ownable.sol";

contract NeoPunk is ERC721Enumerable, Ownable {
  using Strings for uint256;

  string public baseURI;
  string public notRevealedUri;
  uint256 public cost = 0.2 ether;
  uint256 public whiteCost = 0.17 ether;
  uint256 public maxSupply = 7777;
  uint256 public nftPerAddressLimit = 5;
  bool public paused = false;
  bool public revealed = false;
  bool public onlyWhitelisted = true;
  bool public baseUriForever = false;
  mapping(address => uint256) public whitelistedAddresses;
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
      uint256 code = isWhitelisted(msg.sender);
      if(onlyWhitelisted == true) {
        require(code == 1 || code == 2 || code == 3 || code == 4 , "user is not whitelisted");
        require(_mintAmount <= 2, "max mint amount per session exceeded");
        require(ownerMintedCount + _mintAmount <= 2, "max NFT per address exceeded");
        whitelistedAddresses[msg.sender] = 5;
        if(code == 1){
          require(msg.value >= whiteCost * _mintAmount, "insufficient funds");
        }
        else if(code == 2){
          require(msg.value >= (whiteCost * 93/100) * _mintAmount, "insufficient funds");
        }
        else if(code == 3){
          require(msg.value >= (whiteCost * 95/100) * _mintAmount, "insufficient funds");
        }
        else if(code == 4){
          require(msg.value >= (whiteCost * 97/100) * _mintAmount, "insufficient funds");
        }
      }
      else{
        if (airdropList[msg.sender]){
        require(_mintAmount <= 1, "max mint amount per session exceeded");
        airdropList[msg.sender] = false;
        }
        else{
          require(ownerMintedCount + _mintAmount <= nftPerAddressLimit, "max NFT per address exceeded");
          require(_mintAmount <= nftPerAddressLimit, "max mint amount per session exceeded");
          require(msg.value >= cost * _mintAmount, "insufficient funds");
        }
      }
      
    }

    for (uint256 i = 1; i <= _mintAmount; i++) {
      addressMintedBalance[msg.sender]++;
      _safeMint(msg.sender, supply + i);
    }
  }

  function isWhitelisted(address _user) public view returns (uint256) {
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

  function activateBaseUriForever() public onlyOwner {
    baseUriForever = true;
  }

  function setNftPerAddressLimit(uint256 _limit) public onlyOwner {
    nftPerAddressLimit = _limit;
  }

  function setCost(uint256 _newCost) public onlyOwner {
    cost = _newCost;
  }

  function setmaxSupply(uint256 _newmaxSupply) public onlyOwner {
    maxSupply = _newmaxSupply;
  }

  function setWhiteCost(uint256 _newCost) public onlyOwner {
    whiteCost = _newCost;
  }

  function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
    notRevealedUri = _notRevealedURI;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    require(!baseUriForever, "The base URI is set forever");
    baseURI = _newBaseURI;
  }

  function pause(bool _state) public onlyOwner {
    paused = _state;
  }

  function setOnlyWhitelisted(bool _state) public onlyOwner {
    onlyWhitelisted = _state;
  }

  function whitelistUsers(address[] calldata _users, uint256 code) public onlyOwner {
    for (uint i = 0; i < _users.length; i++) {
        whitelistedAddresses[_users[i]]  = code;
      }
  }

  function airdrop(address[] calldata _users) public onlyOwner {
    for (uint i = 0; i < _users.length; i++) {
      airdropList[_users[i]] = true;       
    }
  }

  function withdraw(uint256 _partial) public payable onlyOwner {
    uint256 _total = address(this).balance / _partial;
    (bool roadmap, ) = payable(0x8096a54610A5672398D48Eed1955Bb53d343bFC3).call{value: _total * 3775/10000}("");
    require(roadmap);
    (bool marketing, ) = payable(0x3B288Fab671629224AE65106f6Ba09963CB1112E).call{value:  _total * 2775/10000}("");
    require(marketing);
    (bool investor, ) = payable(0xD87793Bc81032E6D14C5386B59183da09768A42a).call{value:  _total * 65/1000}("");
    require(investor);
    (bool cofounder2, ) = payable(0xc6Fe706552E8B00F2363DA8295357B662D604308).call{value:  _total * 165/1000}("");
    require(cofounder2);
    (bool cofounder3, ) = payable(0x2661a07738645E5E5614f7ecA088daC0c257B29a).call{value:  _total * 2/100}("");
    require(cofounder3);
    (bool cm, ) = payable(0x33bD27c56388638441cf464eF2190e3928159522).call{value:  _total * 5/1000}("");
    require(cm);
    (bool advroadmap, ) = payable(0x84254F1435d9B004a85302CB0E238210e7e3DeB6).call{value:  _total * 1/100}("");
    require(advroadmap);
    (bool advmarketing, ) = payable(0x93a47f062687FaBB8D833D9d68bFbE5034B501DD).call{value:  _total * 2/100}("");
    require(advmarketing);
    (bool ads1, ) = payable(0xfaF32dfBb4E51Da68C93a0FB4DC312E83c393449).call{value:  _total * 2/100}("");
    require(ads1);
    (bool ads2, ) = payable(0x248bDB6908282A7F444A20F91ab1CF25de3C7bfE).call{value:  _total * 2/100}("");
    require(ads2);
    (bool dev1, ) = payable(0xE554050cE6d1a4091D697746C2d6C93E6D27Edc9).call{value: _total * 1 / 100}("");
    require(dev1);
    (bool dev2, ) = payable(0xf6F0D5ACC732Baf6CB630686583d0b2d8F8E726d).call{value: _total * 1 / 100}("");
    require(dev2);
  }

}