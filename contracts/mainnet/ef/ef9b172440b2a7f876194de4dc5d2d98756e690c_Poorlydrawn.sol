// SPDX-License-Identifier: None

pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ERC721AQueryable.sol";

contract Poorlydrawn is ERC721A, ERC721AQueryable, Ownable {
  uint256 public mintPrice = 0.0035 ether;
  uint256 public maxSupply = 5000;
  uint256 public maxPerTxn = 10;
  uint256 public maxFree = 1;

  string tokenBaseUri = "";

  bool public paused = true;

  address public immutable proxyRegistryAddress;

  mapping(address => uint256) private _freeMintedCount;

  constructor(address _proxyRegistryAddress) ERC721A("Poorlydrawn.wtf", "PD.WTF") {
    proxyRegistryAddress = _proxyRegistryAddress;
  }

  function mint(uint256 _quantity) external payable {
    require(!paused, "Minting is paused");

    uint256 _totalSupply = totalSupply();

    require(_totalSupply + _quantity <= maxSupply, "Exceeds Supply");
    require(_quantity <= maxPerTxn, "Exceeds max per tx");

    // Free Mints
    uint256 payForCount = _quantity;
    uint256 freeMintCount = _freeMintedCount[msg.sender];

    if (freeMintCount < maxFree) {
      payForCount = _quantity - maxFree;
      _freeMintedCount[msg.sender] = maxFree;
    }

    require(msg.value >= payForCount * mintPrice, "Ether sent is not correct");

    _mint(msg.sender, _quantity);
  }

  function freeMintedCount(address owner) external view returns (uint256) {
    return _freeMintedCount[owner];
  }

  function _startTokenId() internal pure override returns (uint256) {
    return 1;
  }

  function _baseURI() internal view override returns (string memory) {
    return tokenBaseUri;
  }

  function isApprovedForAll(address owner, address operator)
    public
    view
    override(ERC721A)
    returns (bool)
  {
    OpenSeaProxyRegistry proxyRegistry = OpenSeaProxyRegistry(
      proxyRegistryAddress
    );

    if (address(proxyRegistry.proxies(owner)) == operator) {
      return true;
    }

    return super.isApprovedForAll(owner, operator);
  }

  function setBaseURI(string calldata _newBaseUri) external onlyOwner {
    tokenBaseUri = _newBaseUri;
  }

  function setMaxFree(uint256 _maxFree) public onlyOwner {
    maxFree = _maxFree;
  }

  function setMintPrice(uint256 _mintPrice) public onlyOwner {
    mintPrice = _mintPrice;
  }

  function setMaxSupply(uint256 _maxSupply) public onlyOwner {
    maxSupply = _maxSupply;
  }

  function flipSale() external onlyOwner {
    paused = !paused;
  }

  function collectReserves() external onlyOwner {
    require(totalSupply() <= maxSupply, "No more nfts");
    _mint(msg.sender, 100);
  }

    function airdrop(address _to, uint256 _mintAmount) external onlyOwner {
    require(totalSupply() <= maxSupply, "No more nfts");
    _mint(_to, _mintAmount);
  }

  function withdraw() external onlyOwner {
    require(
      payable(owner()).send(address(this).balance),
      "Withdraw Unsuccessful"
    );
  }
}

contract OwnableDelegateProxy {}

contract OpenSeaProxyRegistry {
  mapping(address => OwnableDelegateProxy) public proxies;
}