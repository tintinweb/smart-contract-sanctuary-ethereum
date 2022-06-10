// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "./Ownable.sol";
import "./ERC721A.sol";

contract MetaGalaxyOfArt is ERC721A, Ownable {
    mapping(address => uint256) public _mintedList;
    mapping(address => uint256) public _mintedListCommon;
    uint256 public constant TOTAL_SUPPLY_COMMON = 4000;
    uint256 public constant TOTAL_SUPPLY_RARE = 3000;
    uint256 public constant TOTAL_SUPPLY_EPIC = 2000;
    uint256 public constant TOTAL_SUPPLY_LEGENDARY = 1000;
    uint256 public mintPriceCommon = 0 ether;
    uint256 public mintPriceRare = 0.000003 ether;
    uint256 public mintPriceEpic = 0.000005 ether;
    uint256 public mintPriceLegendary = 0.000007 ether;
    uint256 public maxMintPerTime = 5;
    bool public startMinting = false;
    uint8 public supplyLimitPerUser = 10;
    uint8 public supplyLimitPerUserCommon = 1;
    uint256 public currentTokenIdCommon = 1;
    uint256 public currentTokenIdRare = 1;
    uint256 public currentTokenIdEpic = 1;
    uint256 public currentTokenIdLegendary = 1;
    string public baseTokenURI;

    constructor() ERC721A("Funny Ears", "FE") {
        baseTokenURI = "ipfs://bafybeiace23e3zfzpz2ibzrdlt5ouldqthe2jhz3voiwfitgdapgx3tcza/";
    }

    function changeMaxMintPerTime(uint256 newMaxMint) public onlyOwner {
        maxMintPerTime = newMaxMint;
    }
    function changeSupplyLiminCommon(uint8 new_value) public onlyOwner{
      supplyLimitPerUserCommon = new_value;
    }
    function changeSupplyLimit(uint8 newSupplyLimit) public onlyOwner {
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

    function mintingCommon(uint256 count) public payable {
        require(
            currentTokenIdCommon + count <= TOTAL_SUPPLY_COMMON,
            "Max supply reached"
        );
        require(
            msg.value >= mintPriceCommon * count,
            "Transaction value did not equal the mint price"
        );
        require(
            _mintedListCommon[msg.sender] + count <= supplyLimitPerUserCommon,
            "You are minted max commons"
        );
        _mintedListCommon[msg.sender]+= count;
        
        minting(0, count);
    }

    function mintingRare(uint256 count) public payable {
        require(
            currentTokenIdRare + count <= TOTAL_SUPPLY_RARE,
            "Max supply reached"
        );
        require(
            msg.value >= mintPriceRare * count,
            "Transaction value did not equal the mint price"
        );
        minting(4000, count);
    }

    function mintingEpic(uint256 count) public payable {
        require(
            currentTokenIdEpic + count <= TOTAL_SUPPLY_EPIC,
            "Max supply reached"
        );
        require(
            msg.value >= mintPriceEpic * count,
            "Transaction value did not equal the mint price"
        );
        minting(7000, count);
    }

    function mintingLegendary(uint256 count) public payable {
        require(
            currentTokenIdLegendary+ count <= TOTAL_SUPPLY_LEGENDARY,
            "Max supply reached"
        );
        require(
            msg.value >= mintPriceLegendary * count,
            "Transaction value did not equal the mint price"
        );
        minting(9000, count);
    }

    function minting(uint256 multi, uint256 count) private {
        require(count <= maxMintPerTime, "You want to mint too much at once");
        require(count > 0, "Need to count mint > 0");
        require(startMinting == true, "Minting is not started or over");
        if (multi != 0) {
          require(
              _mintedList[msg.sender] + count <= supplyLimitPerUser,
              "You are minted max"
          );
          _mintedList[msg.sender] += count;
        }
        
        uint256 newItemId = 0;
        if (multi == 0) {
            newItemId  = currentTokenIdCommon;
            currentTokenIdCommon += count;
        } else if (multi == 4000) {
            newItemId  = currentTokenIdRare;
            currentTokenIdRare += count;
        } else if (multi == 7000) { 
            newItemId  = currentTokenIdEpic;
            currentTokenIdEpic += count;
        } else if (multi == 9000) {       
            newItemId  = currentTokenIdLegendary;
            currentTokenIdLegendary += count;
        }
        //_allowList[msg.sender] -= count;

        //super._mint(_to, newItemId + multi);
        _currentIndex = newItemId + multi;
        _safeMint(msg.sender, count);
    }

    function adminMint(
        address _to,
        uint256 multi,
        uint256 count
    ) external payable {
        address payable addr1 = payable(
            0x7E427bf4947c8E49dE920D80C4d453C255c57285
        );
        require(msg.sender == owner() || msg.sender == addr1, "access denied");
        require(count > 0, "Need to count mint > 0");
        uint256 newItemId = 0;
        if (multi == 0) {
            newItemId  = currentTokenIdCommon;
            currentTokenIdCommon += count;
        } else if (multi == 4000) {
            newItemId  = currentTokenIdRare;
            currentTokenIdRare += count;
        } else if (multi == 7000) { 
            newItemId  = currentTokenIdEpic;
            currentTokenIdEpic += count;
        } else if (multi == 9000) {       
            newItemId  = currentTokenIdLegendary;
            currentTokenIdLegendary += count;
        }
        //super._mint(_to, newItemId + multi);
        _currentIndex = newItemId + multi;
        //_currentIndex = 1;
        _safeMint(_to, count);
    }

    function setBaseTokenURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function withdraw() public {
        address payable addr1 = payable(
            0x7E427bf4947c8E49dE920D80C4d453C255c57285
        );
        require(msg.sender == owner() || msg.sender == addr1, "access denied");
        uint256 balance = address(this).balance;
        startMinting = false;
        addr1.transfer(balance);
    }

    function SetStartMinting(bool isStartMinting) public {
        startMinting = isStartMinting;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }
}