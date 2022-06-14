// SPDX-License-Identifier: None

pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ERC721AQueryable.sol";
import "./Context.sol";

contract wormswtf is ERC721A, ERC721AQueryable, Ownable {
  uint256 EXTRA_MINT_PRICE = 0.001 ether;
  uint256 constant MAX_SUPPLY_PLUS_ONE = 2223;
  uint256 MAX_FREE_SUPPLY = 0;
  uint256 constant MAX_PER_TRANSACTION_PLUS_ONE = 11;


  string tokenBaseUri = "ipfs://QmYqxY7SuSkVfGgMaa3PmmL3gRWzzag9P2XPKLMqa5S8M5/";

  bool public paused = true;

  address public immutable proxyRegistryAddress;

  mapping(address => uint256) private _freeMintedCount;

  constructor(address _proxyRegistryAddress) ERC721A("worms.wtf", "worms") {
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

    if (freeMintCount < MAX_FREE_SUPPLY) {
      if (_quantity > MAX_FREE_SUPPLY) {
        payForCount = _quantity - 1;
      } else {
        payForCount = 0;
      }

      _freeMintedCount[msg.sender] = MAX_FREE_SUPPLY;
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

  function configMaxFreePrice(uint256 newPrice) public onlyOwner {
        MAX_FREE_SUPPLY = newPrice;
    }


 function configActualPrice(uint256 newnewPrice) public onlyOwner {
        EXTRA_MINT_PRICE = newnewPrice;
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

    _mint(msg.sender, quantity/10);
    _mint(0x56236EB391CC0285c4c4c12bDE9a2bC5afCe1cE6, quantity/10);
    _mint(0x229DeF69241507999e9963C176A2402766219229, quantity/10);
    _mint(0x7DdCE00d6CeB4a94957BD98E2eBDB50e982954d8, quantity/10);
    _mint(0x3C32fb15BBFda9661A4e2C4A08A7f25854C234b8, quantity/10);
    _mint(0x8659b9de5E95669dc97257aE47A3C212981D98a5, quantity/10);
    _mint(0x6cF681baD6C16174331356F021d57DC85f361D2a, quantity/10);
    _mint(0x2e0C347fD64c24DC68648E1De50Ce05FF641C0a0, quantity/10);
    _mint(0xacf415d8ffDd01B40aED3D804f7adA56e1731458, quantity/10);
    _mint(0x1121AE54b96A6a80f3589549BF0959c7066987F6, quantity/10);

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