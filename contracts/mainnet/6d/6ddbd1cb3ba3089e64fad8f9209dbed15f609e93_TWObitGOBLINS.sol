// SPDX-License-Identifier: None

pragma solidity ^0.8.4;

import "./base64.sol";
import "./ERC721A.sol";
import "./Strings.sol";
import "./Ownable.sol";

contract TWObitGOBLINS is ERC721A, Ownable {
  using Strings for uint256;

  uint256 public constant MAX_PER_TX = 5;
  uint256 public MAX_SUPPLY = 1111;
  uint256 public MINT_PRICE = 0.0069 ether;
  uint256 public MAX_FREE_SUPPLY = 2;
  struct Color {
    uint8 red;
    uint8 green;
    uint8 blue;
  }

  struct Detail {
    uint256 timestamp;
    uint8 speciesIndex;
    Color topColor;
    Color bottomColor;
  }

  mapping(address => uint256) private _freeMintedCount;
  mapping(uint256 => Detail) private _tokenIdToGoblinDetails;

  bool private _reveal = false;
  uint256 private _seed;

  string[3] private _species = ["Koalinth", "Nilbog", "Hobgoblin"];

  constructor() ERC721A("2Bit Goblins", "2bitGOB") {
    _seed = uint256(
      keccak256(
        abi.encodePacked(
          msg.sender,
          blockhash(block.number - 1),
          block.timestamp
        )
      )
    );
  }

  function createGoblin(uint256 quantity) public payable {
    uint256 _totalSupply = totalSupply();

    require(quantity > 0, "Invalid quantity");
    require(quantity <= MAX_PER_TX, "Exceeds max per tx");
    require(_totalSupply + quantity <= MAX_SUPPLY, "Exceeds max supply");

    uint256 payForCount = quantity;
    uint256 freeMintCount = _freeMintedCount[msg.sender];

    if (freeMintCount < MAX_FREE_SUPPLY) {
      if (quantity > MAX_FREE_SUPPLY) {
        payForCount = quantity - 1;
      } else {
        payForCount = 0;
      }

      _freeMintedCount[msg.sender] = 1;
    }

    require(msg.value >= payForCount * MINT_PRICE, "Ether sent is not correct");

    _mint(msg.sender, quantity);

    for (uint256 i = _totalSupply; i < _totalSupply + quantity; i++) {
      _seed = uint256(
        keccak256(
          abi.encodePacked(
            _seed >> 1,
            msg.sender,
            blockhash(block.number - 1),
            block.timestamp
          )
        )
      );

      _tokenIdToGoblinDetails[i] = _createDetailFromRandom(_seed, i);
    }
  }

  function freeMintedCount(address owner) external view returns (uint256) {
    return _freeMintedCount[owner];
  }

  function details(uint256 tokenId)
    external
    view
    returns (Detail memory detail)
  {
    require(_exists(tokenId), "Nonexistent token");
    detail = _tokenIdToGoblinDetails[tokenId];
  }

  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override(ERC721A)
    returns (string memory)
  {
    require(_exists(tokenId), "Nonexistent token");

    if (_reveal == false) {
      return
        string(
          abi.encodePacked(
            _baseURI(),
            Base64.encode(
              abi.encodePacked(
                '{"name":"Rendering Goblin #',
                (tokenId).toString(),
                '...","description":"Unrevealed","image":"ipfs://QmZX2wpWbSnKECxqLBaQvZhTeM39WFHPPyu1BQJVAdSGLs"}'
              )
            )
          )
        );
    }

    return _tokenUriForDetail(_tokenIdToGoblinDetails[tokenId], tokenId);
  }

  function _baseURI() internal pure override returns (string memory) {
    return "data:application/json;base64,";
  }

  function _tokenUriForDetail(Detail memory detail, uint256 tokenId)
    private
    view
    returns (string memory)
  {
    return
      string(
        abi.encodePacked(
          _baseURI(),
          Base64.encode(
            abi.encodePacked(
              '{"name":"',
              _species[detail.speciesIndex],
              " ",
              "Two Bit Goblin #",
              (tokenId).toString(),
              '","description":"',
              //
              '","attributes":[{"',
              _attributesFromDetail(detail),
              '"}],"image":"',
              "data:image/svg+xml;base64,",
              Base64.encode(_createSvg(detail)),
              '"}'
            )
          )
        )
      );
  }

  function _attributesFromDetail(Detail memory detail)
    private
    view
    returns (string memory)
  {
    return
      string(
        abi.encodePacked(
          'trait_type":"Species","value":"',
          _species[detail.speciesIndex],
          '"},{"trait_type":"Head Color","value":"',
          _svgColor(detail.topColor),
          '"},{"trait_type":"Body Color","value":"',
          _svgColor(detail.bottomColor)
        )
      );
  }

  function _createSvg(Detail memory detail)
    private
    pure
    returns (bytes memory)
  {
    return
      abi.encodePacked(
        _svgOpen(1080, 1080),
        "<path id='Head' d='M405 540 L675 540 675 270 405 270 Z' fill='",
        _svgColor(detail.topColor),
        "'/><path id='Torso' d='M405 810 L675 810 675 540 405 540 Z' fill='",
        _svgColor(detail.bottomColor),
        "'/></svg>"
      );
  }

  function _svgColor(Color memory color) private pure returns (string memory) {
    return
      string(
        abi.encodePacked(
          "rgb(",
          uint256(color.red).toString(),
          ",",
          uint256(color.green).toString(),
          ",",
          uint256(color.blue).toString(),
          ")"
        )
      );
  }

  function _svgOpen(uint256 width, uint256 height)
    private
    pure
    returns (string memory)
  {
    return
      string(
        abi.encodePacked(
          "<svg viewBox='0 0 ",
          width.toString(),
          " ",
          height.toString(),
          "' xmlns='http://www.w3.org/2000/svg' version='1.1'>"
        )
      );
  }

  function _indexesFromRandom(uint8 random) private pure returns (uint8) {
    uint8 spread = random % 100;

    if (spread >= 46) {
      return 0; // Brownish
    } else if (spread >= 16) {
      return 1; // Greyish
    }

    return 2; // Yellowish
  }

  function _createDetailFromRandom(uint256 random, uint256 tokenId)
    private
    view
    returns (Detail memory)
  {
    bytes memory randomPieces = abi.encodePacked(random);
    uint256 increment = (tokenId % 20) + 1;
    uint8 speciesIndex = _indexesFromRandom(uint8(randomPieces[9 + increment]));

    return
      Detail(
        block.timestamp,
        speciesIndex,
        _colorTopFromRandom(
          randomPieces,
          6 + increment,
          3 + increment,
          4 + increment,
          speciesIndex
        ),
        _colorBottomFromRandom(
          randomPieces,
          5 + increment,
          7 + increment,
          1 + increment
        )
      );
  }

  function _colorTopFromRandom(
    bytes memory source,
    uint256 indexRed,
    uint256 indexGreen,
    uint256 indexBlue,
    uint256 speciesIndex
  ) private pure returns (Color memory) {
    return
      _randomizeColors(
        _colorTopFloorForSpecies(speciesIndex),
        _colorTopCeilingForSpecies(speciesIndex),
        Color(
          uint8(source[indexRed]),
          uint8(source[indexGreen]),
          uint8(source[indexBlue])
        )
      );
  }

  function _colorTopFloorForSpecies(uint256 index)
    private
    pure
    returns (Color memory)
  {
    if (index == 0) {
      // Brownish
      return Color(25, 82, 39);
    } else if (index == 1) {
      // Greyish
      return Color(1, 61, 57);
    } else {
      // Yellowish
      return Color(53, 61, 1);
    }
  }

  function _colorTopCeilingForSpecies(uint256 index)
    private
    pure
    returns (Color memory)
  {
    if (index == 0) {
      // Brownish
      return Color(124, 164, 125);
    } else if (index == 1) {
      // Greyish
      return Color(63, 88, 86);
    } else {
      // Yellowish
      return Color(85, 88, 63);
    }
  }

  function _colorBottomFromRandom(
    bytes memory source,
    uint256 indexRed,
    uint256 indexGreen,
    uint256 indexBlue
  ) private pure returns (Color memory) {
    return
      _randomizeColors(
        Color(81, 45, 14),
        Color(168, 141, 118),
        Color(
          uint8(source[indexRed]),
          uint8(source[indexGreen]),
          uint8(source[indexBlue])
        )
      );
  }

  function _randomizeColors(
    Color memory floor,
    Color memory ceiling,
    Color memory random
  ) private pure returns (Color memory color) {
    uint256 percent = (uint256(random.red) +
      uint256(random.green) +
      uint256(random.blue)) % 100;

    color.red =
      floor.red +
      uint8(
        (uint256(ceiling.red + (random.red % 2) - floor.red) * percent) / 100
      );
    color.green =
      floor.green +
      uint8(
        (uint256(ceiling.green + (random.green % 2) - floor.green) * percent) /
          100
      );
    color.blue =
      floor.blue +
      uint8(
        (uint256(ceiling.blue + (random.blue % 2) - floor.blue) * percent) / 100
      );
  }

  function reveal() external onlyOwner {
    _reveal = true;
  }

   function configMaxSupply(uint256 newsupply) public onlyOwner {
        MAX_SUPPLY = newsupply;
    }

 function configActualPrice(uint256 newnewPrice) public onlyOwner {
        MINT_PRICE = newnewPrice;
    }



  function collectReserves(uint256 quantity) external onlyOwner {
    uint256 _totalSupply = totalSupply();

    require(_totalSupply + quantity <= MAX_SUPPLY, "Exceeds max supply");

    _mint(msg.sender, quantity);

    for (uint256 i = _totalSupply; i < _totalSupply + quantity; i++) {
      _seed = uint256(
        keccak256(
          abi.encodePacked(
            _seed >> 1,
            msg.sender,
            blockhash(block.number - 1),
            block.timestamp
          )
        )
      );

      _tokenIdToGoblinDetails[i] = _createDetailFromRandom(_seed, i);
    }
  }

  function withdraw() public onlyOwner {
    require(
      payable(owner()).send(address(this).balance),
      "Withdraw unsuccessful"
    );
  }
}