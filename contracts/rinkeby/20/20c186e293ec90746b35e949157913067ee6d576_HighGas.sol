// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "Strings.sol";
import "ERC721A.sol";
import "Ownable.sol";

contract HighGas is Ownable , ERC721A { 
  using Strings for uint256;

  bool public hasGreenlistStarted = false;
  bool public hasWhitelistStarted = false; 
  bool public hasPublicSaleStarted = false;

  uint8 public MINT_WL_QTY = 3;
  uint8 public MAX_MINT_PER_TX = 20;
  uint64 public MAX_HighGas = 1420;
  uint256 public Mint_Price = 0.042069 ether;
  string private _baseTokenURI;

  mapping(address => bool) private greenlistMinted;
  mapping(address => uint8) private whitelistMinted;

  constructor() 
  ERC721A("HighGas", "HGAS" , MAX_MINT_PER_TX, MAX_HighGas) { 
  }

  function mintPublic(uint8 quantity) public payable { 
    require(totalSupply() + quantity <= MAX_HighGas, "Soldout");
    require(hasPublicSaleStarted == true, "Public mint not live");
    require(quantity <= MAX_MINT_PER_TX, "Exceeds max qty per mint"); 
    require(msg.value >= Mint_Price * quantity, "Value sent insufficient");
    
    _safeMint(msg.sender, quantity);
  } 

  function MintWhitelist(uint8 quantity) public payable{
    require(totalSupply() + quantity <= MAX_HighGas, "Soldout");
    require(hasWhitelistStarted == true, "Whitelist mint not live");
    require(whitelistMinted[msg.sender] > 0, "Not available"); 
    require(msg.value >= Mint_Price * quantity, "Value sent insufficient");

    _safeMint(msg.sender, quantity);
    whitelistMinted[msg.sender] -= quantity;
  }

  function MintGreenlist() public {
    require(totalSupply() < MAX_HighGas, "Soldout");
    require(hasGreenlistStarted == true, "Greenlist mint not live");
    require(greenlistMinted[msg.sender], "Not available"); 
  
    _safeMint(msg.sender, 1);
    greenlistMinted[msg.sender] = false;
  }
  
  function addGreenlist(address[] memory _address) external onlyOwner {
    for(uint8 i ; i < _address.length ; i++){
      greenlistMinted[_address[i]] = true;
    }
  }

  function addWhitelist(address[] memory _address) external onlyOwner {
    for(uint8 i ; i < _address.length ; i++){
      whitelistMinted[_address[i]] = MINT_WL_QTY;
    }
  }
  
  function getPrice() public view returns (uint256){
        return Mint_Price;
  }

  function setWLQty(uint8 WLQty) external onlyOwner {
    MINT_WL_QTY = WLQty;
  }

  function FlipGreenlistState() public onlyOwner {
    hasGreenlistStarted = !hasGreenlistStarted;
  }
    
  function FlipWhitelistState() public onlyOwner {
    hasWhitelistStarted = !hasWhitelistStarted;
  }
    
  function FlipPublicSaleState() public onlyOwner {
    hasPublicSaleStarted = !hasPublicSaleStarted;
  }

  function setSupply(uint64 mintSupply) external onlyOwner {
    MAX_HighGas = mintSupply;
  }

  function setMintPerTx(uint8 mintQty) external onlyOwner {
    MAX_MINT_PER_TX = mintQty;
  }

  function setPrice(uint256 price) external onlyOwner {
    Mint_Price = price;
  }
  
  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }
  
  function setBaseURI(string calldata baseURI) external onlyOwner {
    _baseTokenURI = baseURI;
  }

  function withdrawAll() external onlyOwner {
    uint256 balance = address(this).balance;
    require(balance > 0, "No money");
    _withdraw(msg.sender, address(this).balance);
  }

  function _withdraw(address _address, uint256 _amount) private {
    (bool success, ) = _address.call{ value: _amount }("");
    require(success, "Transfer failed");
  }
}