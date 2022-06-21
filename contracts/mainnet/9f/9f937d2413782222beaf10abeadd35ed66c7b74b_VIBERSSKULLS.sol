//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
//%%%%%%%%%%%%%%%%%%%%%%%%%%%###%%%%%%%%%%%%%%%%%%%%####%%%%%%%%%%%%%%%%%%%%%%%%%%
//%%%%%%%%%%%%%%%%%%%%%%%%######%%%%%%%%%%%%%%%%%%%%####%#%%%%%%%%%%%%%%%%%%%%%%%%
//%%%%%%%%%%%%%%%%%%%%%%%%######%%%%%%%%%%%%%%%%%%%%#######%%%%%%%%%%%%%%%%%%%%%%%
//%%%%%%%%%%%%%%%%%%%%#######%%%%%%%###%%%%%%%###%%%%%%%######%%%%%%%%%%%%%%%%%%%%
//%%%%%%%%%%%%%%%%%%%%########################################%%%%%%%%%%%%%%%%%%%%
//%%%%%%%%%%%%%%%%&##########(((((((#############(((((((##########%%%%%%%%%%%%%%%%
//%%%%%%%%%%%%%%%%%##########///////#############///////##########%%%%%%%%%%%%%%%%
//%%%%%%%%%%%%%%%%%#######/////////////#######/////////////#######%%%%%%%%%%%%%%%%
//%%%%%%%%%%%%%%%%%###(///////////////////////////////////////####%%%%%%%%%%%%%%%%
//%%%%%%%%%%%%%%%%%###(///////////////////////////////////////####%%%%%%%%%%%%%%%%
//%%%%%%%%%%%%%%%%%###(///////////////////////////////////////####%%%%%%%%%%%%%%%%
//%%%%%%%%%%%%%%%%%###@@@@//////,...///#######///...///////@@@####%%%%%%%%%%%%%%%%
//%%%%%%%%%%%%%%%%%###(/////////,.../////////////...//////////####%%%%%%%%%%%%%%%%
//%%%%%%%%%%%%%%%%%###(/////////,.../////////////...//////////####%%%%%%%%%%%%%%%%
//%%%%%%%%%%%%%%%%%###(/////////,.../////////////...//////////####%%%%%%%%%%%%%%%%
//%%%%%%%%%%%%%%%%%###(///////////////////////////////////////####%%%%%%%%%%%%%%%%
//%%%%%%%%%%%%%%%%%###(////////////////%%%%%%%////////////////####%%%%%%%%%%%%%%%%
//%%%%%%%%%%%%%%%%%%%%####/////////////////////////////////###%%%%%%%%%%%%%%%%%%%%
//%%%%%%%%%%%%%%%%%%%%####/////////////////////////////////###%%%%%%%%%%%%%%%%%%%%
//%%%%%%%%%%%%%%%%%%%%%%%%###///////////////////////////###%%%%%%%%%%%%%%%%%%%%%%%
//%%%%%%%%%%%%%%%%%%%%%%%%###%%%(///%%%///%%%%///%%%////###%%%%%%%%%%%%%%%%%%%%%%%
//%%%%%%%%%%%%%%%%%%%%%%%%###///%%&%///%%%////&%%///%&%%###%%%%%%%%%%%%%%%%%%%%%%%
//%%%%%%%%%%%%%%%%%%%%%%%%###///%%%&///%%%(///&%%///%%%%###%%%%%%%%%%%%%%%%%%%%%%%
//%%%%%%%%%%%%%%%%%%%%%%%%###///////////////////////////###%%%%%%%%%%%%%%%%%%%%%%%
//%%%%%%%%%%%%%%%%%%%%%%%%%%%###(///////////////////####%%%%%%%%%%%%%%%%%%%%%%%%%%
//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%&####################%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%####################%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%acting as a key to the next drop%%%%%%%%%%%%%%%%%
// SPDX-License-Identifier: None

pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ERC721AQueryable.sol";
import "./Context.sol";

contract VIBERSSKULLS is ERC721A, ERC721AQueryable, Ownable {
  uint256 public EXTRA_MINT_PRICE = 0.005 ether;
  uint256 public MAX_SUPPLY_PLUS_ONE  = 1001;
  uint256 public MAX_FREE_SUPPLY = 2;
  uint256 public constant MAX_PER_TRANSACTION_PLUS_ONE = 11;


  string tokenBaseUri = "ipfs://QmZh1BvVr1Wb1pXACxBqPk7istJbi8PjHyWXKzufSbUphq/";

  bool public paused = false;

  address public immutable proxyRegistryAddress;

  mapping(address => uint256) private _freeMintedCount;

  constructor(address _proxyRegistryAddress) ERC721A("VIBERS SKULLS", "VIBERS") {
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