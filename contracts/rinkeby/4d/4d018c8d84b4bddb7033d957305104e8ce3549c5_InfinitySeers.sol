// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "Strings.sol";
import "ERC721A.sol";
import "Ownable.sol";

abstract contract InfinityPass {
  function tokenOfOwnerByIndex(address owner, uint256 index) external virtual view returns (uint256);
  function balanceOf(address owner) external virtual view returns (uint256);
}

contract InfinitySeers is Ownable , ERC721A { 
  InfinityPass private IPass;
  using Strings for uint256;

  bool public hasMintStarted = false;
  bool[500] private IPasscheck;

  uint8 public ReserveQty = 20;
  uint8 public FreeMintQty = 25;
  uint8 public MAX_MINT_PER_TX = 20;
  
  uint64 public MAX_SEERS = 2000;
  uint256 public IPass_Price = 0.03 ether;
  uint256 public Whitelist1_Price = 0.04 ether;
  uint256 public Mint_Price = 0.05 ether;
  string private _baseTokenURI = "ipfs://Qme43wERM79oKQmj6zTNVbj8oTANuzm1tCwr3WMfHaBS9r/";
  address IPassAddress = 0x471fdF6685bADaA7169C1F4fc553D226635Db0e4;
  mapping(address => bool) private FreeMintWhitelist;
  mapping(address => bool) private Whitelist1;
  mapping(address => bool) private Whitelist2;

  constructor() 
  ERC721A("Infinity Seers", "SEERS" , MAX_MINT_PER_TX, MAX_SEERS) { 
    IPass = InfinityPass(IPassAddress);
  }

  function IPassOfOwnerByIndex(address owner, uint256 index) public view returns (uint256) { 
    return IPass.tokenOfOwnerByIndex(owner,index);
  }

  function IPassbalanceOf(address owner) public view returns (uint256) { 
    return IPass.balanceOf(owner);
  }

  function IPassStatus(uint256 tokenId) public view returns (bool) { 
    return IPasscheck[tokenId];
  }

  function reserveMint(uint8 quantity) public onlyOwner{
    require(totalSupply() + quantity <= MAX_SEERS, "Soldout");
    require(quantity <= ReserveQty, "Exceed Max Reserve Mint");

    ReserveQty -= quantity;
    _safeMint(msg.sender, quantity);
  }

  function freeMint() public {
    require(totalSupply() < MAX_SEERS, "Soldout");
    require(hasMintStarted == true, "Mint not live");
    require(FreeMintQty >= 1, "Exceed Max Free Mint");
    require(FreeMintWhitelist[msg.sender], "Free Mint Not Available");

    FreeMintQty -= 1;
    FreeMintWhitelist[msg.sender] = false;
    _safeMint(msg.sender, 1);
  }

  function addFreeMintWhitelist(address[] memory _address) public onlyOwner {
    for(uint i = 0 ; i < _address.length ; i++){
      FreeMintWhitelist[_address[i]] = true;
    }
  }

  function IPassholderMint(uint8 quantity) public payable{  //to optimise
    require(totalSupply() + quantity <= MAX_SEERS, "Soldout");
    require(hasMintStarted == true, "Mint not live");

    uint balance = IPass.balanceOf(msg.sender);
    uint8 counter = 0;
    for (uint8 i = 0; i < balance; i++) {
      if (IPasscheck[IPass.tokenOfOwnerByIndex(msg.sender, i)] == false) {
        counter += 1;     
      }
    }
    require(quantity <= counter, "Mint Exceed IPass Qty");
    require(msg.value >= IPass_Price * quantity, "Value Insufficient");

    _safeMint(msg.sender, quantity);

    uint8 index = 0;
    for (uint8 i = 0; i < quantity; i++) {
      for (uint8 j = index; j < balance; j++){  
        if (IPasscheck[IPass.tokenOfOwnerByIndex(msg.sender, j)] == false) {
          IPasscheck[IPass.tokenOfOwnerByIndex(msg.sender, j)] = true; 
          index = j+1;  
          j = 254;     
        }
      }
    }
  }

  function IPassUseable(address owner) public view returns (uint8){  //change to internal
    uint balance = IPass.balanceOf(owner);
    uint8 index = 0;
        
    for (uint8 i = 0; i < balance; i++) {
      if (IPasscheck[IPass.tokenOfOwnerByIndex(owner, i)] == false) {
        index += 1;     
      }
    }
    return index;
  }

  function whitelist1Mint() public payable {
    require(totalSupply() < MAX_SEERS, "Soldout");
    require(hasMintStarted == true, "Mint not live");
    require(Whitelist1[msg.sender], "Whitelist1 Mint Not Available");
    require(msg.value >= Whitelist1_Price, "Value Insufficient");

    _safeMint(msg.sender, 1);
    Whitelist1[msg.sender] = false;
  }

  function addWhitelist1(address[] memory _address) public onlyOwner {
    for(uint i = 0 ; i < _address.length ; i++){
      Whitelist1[_address[i]] = true;
    }
  }

  function whitelist2Mint(uint8 quantity) public payable {
    require(totalSupply() + quantity <= MAX_SEERS, "Soldout");
    require(hasMintStarted == true, "Mint not live");
    require(Whitelist2[msg.sender], "Whitelist2 Mint Not Available");
    require(quantity <= 5, "Exceed Max Mint Per Tx");
    require(msg.value >= Mint_Price * quantity, "Value Insufficient");

    _safeMint(msg.sender, quantity);
    Whitelist2[msg.sender] = false;
  }

  function addWhitelist2(address[] memory _address) public onlyOwner {
    for(uint i = 0 ; i < _address.length ; i++){
      Whitelist2[_address[i]] = true;
    }
  }

  function publicMint(uint8 quantity) public payable { 
    require(totalSupply() + quantity <= MAX_SEERS, "Soldout");
    require(hasMintStarted == true, "Mint not live");
    require(quantity <= MAX_MINT_PER_TX, "Exceed Max Mint Per Tx");
    require(msg.value >= Mint_Price * quantity, "Value Insufficient");
  
    _safeMint(msg.sender, quantity);
  }

  function mint(address[] memory _address) public onlyOwner { 
    require(totalSupply() + _address.length < MAX_SEERS, "Soldout");

    for (uint256 i = 0; i < _address.length; i++) {
            _safeMint(_address[i], 1);
    }
  }
    
  function flipMintState() public onlyOwner {
    hasMintStarted = !hasMintStarted;
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