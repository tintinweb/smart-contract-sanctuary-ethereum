// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "Strings.sol";
import "ERC721A.sol";
import "Ownable.sol";

contract InfinityPass is Ownable , ERC721A { 
  using Strings for uint256;
 
  bool public hasMintStarted = false;

  uint8 public MAX_MINT_PER_TX = 3;
  uint64 public MAX_PASS = 1000;
  uint256 public Mint_Price = 0.01 ether;
  string private _baseTokenURI;

  mapping(address => bool) private FreeMinted;

  constructor() 
  ERC721A("Infinity Pass", "IPASS" , MAX_MINT_PER_TX, MAX_PASS) { 
  }

  function mint(uint8 quantity) public payable { 
    require(totalSupply() + quantity <= MAX_PASS, "Soldout");
    require(hasMintStarted == true, "Mint not live");
    require(quantity <= MAX_MINT_PER_TX, "Exceed Max Mint"); 
    require(msg.value >= Mint_Price * quantity, "Value Insufficient");
    
    _safeMint(msg.sender, quantity);
  } 

  function mint_free() public { 
    require(totalSupply() <= 100, "Free Mint Unavailable");
    require(hasMintStarted == true, "Mint not live");
    require(!FreeMinted[msg.sender], "Not Available");

    _safeMint(msg.sender, 1);
    FreeMinted[msg.sender] = true;
  } 
  
  function getPrice() public view returns (uint256){
        return Mint_Price;
  }

  function FlipMintState() public onlyOwner {
    hasMintStarted = !hasMintStarted;
  }

  function setSupply(uint64 mintSupply) external onlyOwner {
    MAX_PASS = mintSupply;
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