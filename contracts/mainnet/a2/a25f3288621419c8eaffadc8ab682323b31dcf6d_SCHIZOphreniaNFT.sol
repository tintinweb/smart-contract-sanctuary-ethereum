//.dP"Y8  dP""b8 88  88 88 8888P  dP"Yb      88""Yb 88  88 88""Yb 888888 88b 88 88    db    
//`Ybo." dP   `" 88  88 88   dP  dP   Yb     88__dP 88  88 88__dP 88__   88Yb88 88   dPYb   
//o.`Y8b Yb      888888 88  dP   Yb   dP .o. 88"""  888888 88"Yb  88""   88 Y88 88  dP__Yb  
//8bodP'  YboodP 88  88 88 d8888  YbodP  `"' 88     88  88 88  Yb 888888 88  Y8 88 dP""""Yb



//I'm hearing voices.
// SPDX-License-Identifier: None

pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ERC721AQueryable.sol";
import "./Context.sol";

contract SCHIZOphreniaNFT is ERC721A, ERC721AQueryable, Ownable {
  uint256 public EXTRA_MINT_PRICE = 0.005 ether;
  uint256 public MAX_SUPPLY_PLUS_ONE  = 5001;
  uint256 public MAX_FREE_SUPPLY = 1;
  uint256 public constant MAX_PER_TRANSACTION_PLUS_ONE = 11;


  string tokenBaseUri = "";

  bool public paused = true;

  address public immutable proxyRegistryAddress;

  mapping(address => uint256) private _freeMintedCount;

  constructor(address _proxyRegistryAddress) ERC721A("SCHIZO.PHRENIA", "SCHIZO") {
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
        payForCount = _quantity - MAX_FREE_SUPPLY;
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

    function configtotalsupply(uint256 newsupply) public onlyOwner {
        MAX_SUPPLY_PLUS_ONE = newsupply;
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

function collectReserves(address[] calldata addresses, uint256 quantity)
    external
    onlyOwner
  {
    uint256 _totalSupply = totalSupply();

    require(
      _totalSupply + quantity * addresses.length <= MAX_SUPPLY_PLUS_ONE,
      "Exceeds max supply"
    );

    for (uint256 i = 0; i < addresses.length; i++) {
      _mint(addresses[i], quantity);
    }
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