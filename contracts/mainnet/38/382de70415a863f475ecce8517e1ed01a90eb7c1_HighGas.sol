// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "Strings.sol";
import "ERC721A.sol";
import "Ownable.sol";

contract HighGas is Ownable , ERC721A { 
  using Strings for uint256;

  bool public hasMintStarted = false;

  uint8 public FREE_QTY = 5;
  uint8 public MAX_MINT_PER_TX = 50;
  uint64 public MAX_HighGas = 10420;
  uint256 public Mint_Price = 0.01 ether;
  string private _baseTokenURI = "ipfs://Qme43wERM79oKQmj6zTNVbj8oTANuzm1tCwr3WMfHaBS9r/";

  mapping(address => uint8) private FreeMinted;

  constructor() 
  ERC721A("HighGas", "HGAS" , MAX_MINT_PER_TX, MAX_HighGas) { 
  }

  function mint(uint8 quantity) public payable { 
    require(totalSupply() + quantity <= MAX_HighGas, "Soldout");
    require(hasMintStarted == true, "Mint not live");
    if (totalSupply() < 420) {
      require(quantity <= FREE_QTY, "Exceed Free Max Mint");
      require(FreeMinted[msg.sender] + quantity <= FREE_QTY, "Exceed Free Max Limit");
      _safeMint(msg.sender, quantity);
      FreeMinted[msg.sender] += quantity;
    } else
    {
      require(quantity <= MAX_MINT_PER_TX, "Exceed Max Mint"); 
      require(msg.value >= Mint_Price * quantity, "Value Insufficient");
      _safeMint(msg.sender, quantity);
    }
  }
    
  function FlipMintState() public onlyOwner {
    hasMintStarted = !hasMintStarted;
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

  function setSupply(uint64 mintSupply) external onlyOwner {
    MAX_HighGas = mintSupply;
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