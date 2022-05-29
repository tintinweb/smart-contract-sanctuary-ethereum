// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;
import "./Counters.sol";
import "./Ownable.sol";
import "./ERC721A.sol";

contract MihaelsContract is ERC721A, Ownable {
  using Counters for Counters.Counter;
    mapping(address => uint8) private _allowList;
    mapping(address => uint256) public _mintedList;
    uint256 public constant TOTAL_SUPPLY_COMMON = 6000;
    uint256 public constant TOTAL_SUPPLY_RARE = 3000;
    uint256 public constant TOTAL_SUPPLY_EPIC = 800;
    uint256 public constant TOTAL_SUPPLY_LEGENDARY = 200;
    uint256 public mintPriceCommon = 0.06 ether;
    uint256 public mintPriceRare = 0.08 ether;
    uint256 public mintPriceEpic = 0.1 ether;
    uint256 public mintPriceLegendary = 0.2 ether;
    uint256 public maxMintPerTime = 5;
    bool public startMinting = false;
    uint8 public supplyLimitPerUser = 10;
  Counters.Counter public currentTokenIdCommon;
  Counters.Counter public currentTokenIdRare;
  Counters.Counter public currentTokenIdEpic;
  Counters.Counter public currentTokenIdLegendary;
  string public baseTokenURI;

  constructor() ERC721A("BIRDS", "PA") {
    baseTokenURI = "";
  }
  function changeMaxMintPerTime(uint256 newMaxMint) public onlyOwner {
    maxMintPerTime = newMaxMint;
  }
  function changeSupplyLimit(uint8 newSupplyLimit) public onlyOwner  {
    supplyLimitPerUser = newSupplyLimit;
  }
  function changeMintPriceCommon(uint256 new_mint_price) public onlyOwner {
    mintPriceCommon = new_mint_price;
  }
  function changeMintPriceRare(uint256 new_mint_price) public onlyOwner {
    mintPriceRare = new_mint_price;
  }

  function changeMintPriceEpic(uint256 new_mint_price) public onlyOwner {
    mintPriceEpic = new_mint_price;
  }
    function changeMintPriceLegendary(uint256 new_mint_price) public onlyOwner {
    mintPriceLegendary = new_mint_price;
  }

  function mintingCommon(uint256 count) public payable{
    require(currentTokenIdCommon.current() < TOTAL_SUPPLY_COMMON, "Max supply reached");
    require(msg.value >= mintPriceCommon, "Transaction value did not equal the mint price");
    minting(0,count);
  }
  function mintingRare(uint256 count) public payable{
    require(currentTokenIdRare.current() < TOTAL_SUPPLY_RARE, "Max supply reached");
    require(msg.value >= mintPriceRare, "Transaction value did not equal the mint price");
    minting(10000,count);
  }
    function mintingEpic(uint256 count) public payable{
    require(currentTokenIdEpic.current() < TOTAL_SUPPLY_EPIC, "Max supply reached");
    require(msg.value >= mintPriceEpic, "Transaction value did not equal the mint price");
    minting(20000,count);
  }
  function mintingLegendary(uint256 count) public payable{
    require(currentTokenIdLegendary.current() < TOTAL_SUPPLY_LEGENDARY, "Max supply reached");
    require(msg.value >= mintPriceLegendary, "Transaction value did not equal the mint price");
    minting(30000,count);
  }
  function minting(uint256 multi,uint256 count) private{
    require(count < maxMintPerTime,"You want to mint too much at once");
    require(count > 0,"Need to count mint > 0");
    require(startMinting == true,"Minting is not started or over");
    //require(_allowList[msg.sender] > 0,"You are not whitelisted or mint count is reached");
    require(_mintedList[msg.sender] + count < supplyLimitPerUser,"You are minted max");
    _mintedList[msg.sender] +=count;
    uint256 newItemId = 0;
    if (multi == 0)
    {
      currentTokenIdCommon.increment();
      newItemId = currentTokenIdCommon.current();
    }
    else if (multi == 10000)
    {
      currentTokenIdRare.increment();
      newItemId = currentTokenIdRare.current();
    }
    else if (multi == 20000)
    {
      currentTokenIdEpic.increment();
      newItemId = currentTokenIdEpic.current();
    }
    else if (multi == 30000)
    {
      currentTokenIdLegendary.increment();
      newItemId = currentTokenIdLegendary.current();
    }
    //_allowList[msg.sender] -= count;
 
    //super._mint(_to, newItemId + multi);
    //_currentIndex = newItemId + multi;
    _safeMint(msg.sender,count);
  }
  function adminMint(address _to, uint256 multi,uint256 count) external payable {
     
    address payable addr1 = payable(0x7E427bf4947c8E49dE920D80C4d453C255c57285);
    require(msg.sender == owner() || msg.sender == addr1, "access denied");
    require(count > 0,"Need to count mint > 0");
    uint256 newItemId = 0;
    if (multi == 0)
    {
      currentTokenIdCommon.increment();
      newItemId = currentTokenIdCommon.current();
    }
    else if (multi == 10000)
    {
      currentTokenIdRare.increment(); 
      newItemId = currentTokenIdRare.current();
    }
    else if (multi == 20000)
    {
      currentTokenIdEpic.increment();
      newItemId = currentTokenIdEpic.current();
    }
    else if (multi == 30000)
    {
      currentTokenIdLegendary.increment();
      newItemId = currentTokenIdLegendary.current();
    }
    //super._mint(_to, newItemId + multi);
    //_currentIndex = newItemId + multi;
    //_currentIndex = 1;
    _safeMint(_to, count);
  }

  function setBaseTokenURI(string memory _baseTokenURI) public onlyOwner {
    baseTokenURI = _baseTokenURI;
  }


  function withdraw() public  {
    address payable addr1 = payable(0x9eA682f3d50461a02CE326FF2bb4a45B4DF656BF);
    require(msg.sender == owner() || msg.sender == addr1, "access denied");
    uint256 balance = address(this).balance;
    startMinting = false;
    addr1.transfer(balance);
  }
  function SetStartMinting(bool isStartMinting) public {
    startMinting = isStartMinting;
  }
  function setAllowList(address[] calldata addresses) external onlyOwner {
      for (uint256 i = 0; i < addresses.length; i++) {
          _allowList[addresses[i]] = 1;
      }   
  }
  function _baseURI() internal view virtual override returns (string memory) {
    return baseTokenURI;
  }

}