// SPDX-License-Identifier: None

pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ERC721AQueryable.sol";
import "./Context.sol";

contract HABIBIZHD is ERC721A, ERC721AQueryable, Ownable {
  uint256 constant EXTRA_MINT_PRICE = 0.003 ether;
  uint256 constant MAX_SUPPLY_PLUS_ONE = 5556;
  uint256 constant MAX_PER_TRANSACTION_PLUS_ONE = 11;

  string tokenBaseUri = "";

  bool public paused = true;

  address public immutable proxyRegistryAddress;

  mapping(address => uint256) private _freeMintedCount;

  constructor(address _proxyRegistryAddress) ERC721A("HABIBIZ HD", "HABIBIZ") {
    proxyRegistryAddress = _proxyRegistryAddress;
  }

  function mint(uint256 _quantity) external payable {
    require(!paused, "Minting is Paused");

    uint256 _totalSupply = totalSupply();

    require(_totalSupply + _quantity < MAX_SUPPLY_PLUS_ONE, "Exceeds Supply");
    require(_quantity < MAX_PER_TRANSACTION_PLUS_ONE, "Exceed Max Supply");

    // Free Mints
    uint256 payForCount = _quantity;
    uint256 freeMintCount = _freeMintedCount[msg.sender];

    if (freeMintCount < 1) {
      if (_quantity > 1) {
        payForCount = _quantity - 1;
      } else {
        payForCount = 0;
      }

      _freeMintedCount[msg.sender] = 1;
    }

    require(msg.value >= payForCount * EXTRA_MINT_PRICE, "Ether amount sent wrong");

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
   override(ERC721A, IERC721A)
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

  function flipSale() external onlyOwner {
    paused = !paused;
  }

function collectReserves(uint256 quantity) external onlyOwner {
    uint256 _totalSupply = totalSupply();

    require(_totalSupply + quantity <= MAX_SUPPLY_PLUS_ONE, "Exceeds max supply");

    _mint(msg.sender, quantity);
  }

  function withdraw() external onlyOwner {
    require(
      payable(owner()).send(address(this).balance),
      "WIThDRaW UNsucCEssFUl"
    );
  }
}

contract OwnableDelegateProxy {}

contract OpenSeaProxyRegistry {
  mapping(address => OwnableDelegateProxy) public proxies;
}