// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract Freestyle is ERC721Enumerable, Ownable{
  //使用库合约
  using Strings for uint256;
  //nft地址
  string baseURI;
  string public baseExtension = ".json";
  uint256 public cost = 0.01 ether;//铸造花费
  uint256 public maxSupply = 48;//总供应量
  uint256 public maxMintAmount = 2;//单次最大铸造数量
  bool public paused = false;//暂停开关
  bool public revealed = false;//开图开关
  string public notRevealedUri;//未开图的默认展示地址

  constructor(
    string memory _name,
    string memory _symbol,
    string memory _initBaseURI,
    string memory _initNotRevealedUri
  ) ERC721(_name, _symbol) {
    setBaseURI(_initBaseURI);
    setNotRevealedURI(_initNotRevealedUri);
  }

  // internal setBaseURI
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  // public
  function mint(uint256 _mintAmount) public payable {
    uint256 supply = totalSupply();//ERC721Enumerable.sol
    require(!paused);//判断铸造开关
    require(_mintAmount > 0);//判断铸造数量大于0
    require(_mintAmount <= maxMintAmount);//判断铸造数量小于规定数量
    require(supply + _mintAmount <= maxSupply);//判断是否超过总量

    if (msg.sender != owner()) {//非合约拥有者需要付费, 计算携带的主币是否足够
      require(msg.value >= cost * _mintAmount);
    }

    for (uint256 i = 1; i <= _mintAmount; i++) {//循环铸造
      _safeMint(msg.sender, supply + i);
    }
  }
  
  //返回地址持有的tokenids[]
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

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
    
    if(revealed == false) {
        return notRevealedUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
  }

  //only owner
  function reveal() public onlyOwner {
      revealed = true;
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
  //暂停
  function pause(bool _state) public onlyOwner {
    paused = _state;
  }
 
  function withdraw() public payable onlyOwner {

    // This will payout the owner 95% of the contract balance.
    // Do not remove this otherwise you will not be able to withdraw the funds.
    // =============================================================================
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
    // =============================================================================
  }
}