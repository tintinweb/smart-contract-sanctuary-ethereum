// SPDX-License-Identifier: MIT
/*******************************************************************

  ____                          _____     _                 _ 
 |  _ \                        |_   _|   | |               | |
 | |_) |_   _ _ __  _ __  _   _  | |  ___| | __ _ _ __   __| |
 |  _ <| | | | '_ \| '_ \| | | | | | / __| |/ _` | '_ \ / _` |
 | |_) | |_| | | | | | | | |_| |_| |_\__ \ | (_| | | | | (_| |
 |____/ \__,_|_| |_|_| |_|\__, |_____|___/_|\__,_|_| |_|\__,_|
                           __/ |                              
                          |___/                               

                              __
                     /\    .-" /
                    /  ; .'  .' 
                   :   :/  .'   
                    \  ;-.'     
       .--""""--..__/     `.    
     .'           .'    `o  \   
    /                    `   ;  
   :                  \      :  
 .-;        -.         `.__.-'  
:  ;          \     ,   ;       
'._:           ;   :   (        
    \/  .__    ;    \   `-.     
     ;     "-,/_..--"`-..__)    
     '""--.._:
********************************************************************/

pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Counters.sol";
import "./Address.sol";
import "./Strings.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
  mapping(address => OwnableDelegateProxy) public proxies;
}

contract BunnyIsland is ERC721, ReentrancyGuard, Ownable {
  using Counters for Counters.Counter;

  using Strings for uint256;

  constructor(string memory customBaseURI_, address proxyRegistryAddress_)
  ERC721("BunnyIsland", "LAND")
  {
    customBaseURI = customBaseURI_;
    proxyRegistryAddress = proxyRegistryAddress_;
  }

  /** TOKEN PARAMETERS **/

  struct TokenParameters {
    address proxyRegistryAddress_;
    string customBaseURI_;
  }

  mapping(uint256 => TokenParameters) private tokenParametersMap;

  function tokenParameters(uint256 tokenId) external view
    returns (TokenParameters memory)
  {
    return tokenParametersMap[tokenId];
  }

  /** MINTING **/

  uint256 public constant MAX_SUPPLY = 5555;

  uint256 public constant MAX_MULTIMINT = 20;

  uint256 public PRICE = 50000000000000000;

  Counters.Counter private supplyCounter;

  function mint(uint256 count) public payable nonReentrant {
    require(saleIsActive, "Sale not active");

    require(totalSupply() + count - 1 < MAX_SUPPLY, "Exceeds max supply");

    require(count <= MAX_MULTIMINT, "Mint at most 20 at a time");

    require(
      msg.value >= PRICE * count, "Insufficient payment, 0.05 ETH per item"
    );

    for (uint256 i = 0; i < count; i++) {
      _mint(msg.sender, totalSupply());

      supplyCounter.increment();
    }
  }

  function setMintPrice(uint256 PRICE_) external onlyOwner {
    PRICE = PRICE_;
  }  

  function totalSupply() public view returns (uint256) {
    return supplyCounter.current();
  }

  /** ACTIVATION **/

  bool public saleIsActive = false;

  function setSaleIsActive(bool saleIsActive_) external onlyOwner {
    saleIsActive = saleIsActive_;
  }


  /** URI HANDLING **/

  string private customBaseURI;

  mapping(uint256 => string) private tokenURIMap;

  function setTokenURI(uint256 tokenId, string memory tokenURI_)
    external
    onlyOwner
  {
    tokenURIMap[tokenId] = tokenURI_;
  }

  function setBaseURI(string memory customBaseURI_) external onlyOwner {
    customBaseURI = customBaseURI_;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return customBaseURI;
  }

  function tokenURI(uint256 tokenId) public view override
    returns (string memory)
  {
    string memory tokenURI_ = tokenURIMap[tokenId];

    if (bytes(tokenURI_).length > 0) {
      return tokenURI_;
    }

    return string(abi.encodePacked(super.tokenURI(tokenId)));
  }

  /** PAYOUT **/

  function withdraw() public nonReentrant {
    uint256 balance = address(this).balance;

    Address.sendValue(payable(owner()), balance);
  }

  /** PROXY REGISTRY **/

  address private immutable proxyRegistryAddress;

  function isApprovedForAll(address owner, address operator)
    override
    public
    view
    returns (bool)
  {
    ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);

    if (address(proxyRegistry.proxies(owner)) == operator) {
      return true;
    }

    return super.isApprovedForAll(owner, operator);
  }
}