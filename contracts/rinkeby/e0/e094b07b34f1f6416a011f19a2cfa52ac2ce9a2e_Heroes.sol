// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./Traits.sol";
import "./Traits2.sol";

contract Heroes is ERC721Enumerable, Ownable, ReentrancyGuard {
  using ECDSA for bytes32;

  uint256 PRICE_PER_TOKEN = 0.08 ether;
  uint256 MAX_SUPPLY = 3333;
  address SIGNER;
  uint256 currentId;
  string BASE_URI;

  mapping(uint256 => uint256) public tokenIdToSeed;

  HeroTraits traitStorage;
  HeroTraits2 traitStorage2;

  constructor(
    string memory baseUri,
    string memory name,
    address traits,
    address traits2
  ) ERC721(name, "HERO") {
    BASE_URI = baseUri;
    traitStorage = HeroTraits(traits);
    traitStorage2 = HeroTraits2(traits2);
  }

  function withdraw(address sendTo) public onlyOwner {
    uint256 balance = address(this).balance;
    payable(sendTo).transfer(balance);
  }

  struct Traits {
    uint256 race;
    uint256 pants;
    uint256 weapon;
    uint256 shield;
    uint256 clothes;
    uint256 head;
    uint256 shoes;
    uint256 hair;
    uint256 bg;
    uint256 magic;
    uint256 strength;
    uint256 intelligence;
    uint256 stamina;
    uint256 dexterity;
    uint256 creativity;
  }

  function getSeed(uint256 tokenId) public view returns (uint256) {
    return tokenIdToSeed[tokenId];
  }

  // get trait modulo 10 and then have a percentage
  function _getRandomMod(uint256 rand, uint256 chance)
    internal
    pure
    returns (bool)
  {
    return ((rand % 1000) + 1) <= chance;
  }

  function genTraits(uint256 tokenId) public view returns (Traits memory) {
    uint256 seed = getSeed(tokenId);

    Traits memory traits = Traits({
      race: uint256(keccak256(abi.encode(seed, 1))),
      pants: uint256(keccak256(abi.encode(seed, 2))),
      weapon: uint256(keccak256(abi.encode(seed, 3))),
      shield: uint256(keccak256(abi.encode(seed, 4))),
      clothes: uint256(keccak256(abi.encode(seed, 5))),
      head: uint256(keccak256(abi.encode(seed, 6))),
      shoes: uint256(keccak256(abi.encode(seed, 7))),
      hair: uint256(keccak256(abi.encode(seed, 8))),
      bg: uint256(keccak256(abi.encode(seed, 9))),
      magic: uint256(keccak256(abi.encode(seed, 10))),
      strength: uint256(keccak256(abi.encode(seed, 11))),
      intelligence: uint256(keccak256(abi.encode(seed, 12))),
      stamina: uint256(keccak256(abi.encode(seed, 13))),
      dexterity: uint256(keccak256(abi.encode(seed, 14))),
      creativity: uint256(keccak256(abi.encode(seed, 15)))
    });

    uint256 head = _getRandomMod(traits.head, 500)
      ? traits.head % traitStorage.getHeadLength()
      : 0;

    bool isHood = head >= 1 && head <= 5;

    // default is human1
    uint256 race = 0;
    bool isHuman1 = _getRandomMod(traits.race, 500);
    bool isHuman2 = _getRandomMod(traits.race, 340);
    bool isHuman3 = _getRandomMod(traits.race, 180);
    bool isZombie = _getRandomMod(traits.race, 600);
    bool isSkeleton = _getRandomMod(traits.race, 700);
    bool isWizard = _getRandomMod(traits.race, 800);
    bool isGhost = _getRandomMod(traits.race, 900);
    bool isFrog = _getRandomMod(traits.race, 960);
    bool isPizza = _getRandomMod(traits.race, 970);

    if (isHuman3) {
      race = 2;
    } else if (isHuman2) {
      race = 1;
    } else if (isHuman1) {
      race = 0;
    } else if (isZombie) {
      race = 3;
    } else if (isSkeleton) {
      race = 4;
    } else if (isWizard) {
      race = 5;
    } else if (isGhost) {
      race = 6;
    } else if (isFrog) {
      race = 7;
    } else if (isPizza) {
      race = 8;
      // monkies
    } else if (_getRandomMod(traits.race, 972)) {
      race = 9;
    } else if (_getRandomMod(traits.race, 974)) {
      race = 10;
    } else if (_getRandomMod(traits.race, 976)) {
      race = 11;
    } else if (_getRandomMod(traits.race, 978)) {
      race = 12;
    } else if (_getRandomMod(traits.race, 980)) {
      race = 13;
    } else if (_getRandomMod(traits.race, 982)) {
      race = 14;
    } else if (_getRandomMod(traits.race, 984)) {
      race = 15;
    } else if (_getRandomMod(traits.race, 986)) {
      race = 16;
    } else if (_getRandomMod(traits.race, 988)) {
      race = 17;
    } else if (_getRandomMod(traits.race, 990)) {
      race = 18;
    } else if (_getRandomMod(traits.race, 993)) {
      race = 19;
    } else if (_getRandomMod(traits.race, 997)) {
      race = 20;
    } else if (_getRandomMod(traits.race, 1000)) {
      race = 21;
    }

    return
      Traits({
        race: race,
        weapon: _getRandomMod(traits.weapon, 800)
          ? traits.weapon % traitStorage.getWeaponsLength()
          : 0,
        clothes: traits.clothes % traitStorage.getClothesLength(),
        shield: _getRandomMod(traits.shield, 100)
          ? traits.shield % traitStorage.getShieldsLength()
          : 0,
        head: head,
        pants: traits.pants % traitStorage.getPantsLength(),
        bg: traits.bg % traitStorage.getBgLength(),
        hair: isHood ? 0 : _getRandomMod(traits.weapon, 950)
          ? traits.hair % traitStorage2.getHairLength()
          : 0,
        shoes: traits.shoes % traitStorage.getShoesLength(),
        magic: (traits.magic % 1000) + 1,
        strength: (traits.strength % 1000) + 1,
        intelligence: (traits.intelligence % 1000) + 1,
        stamina: (traits.stamina % 1000) + 1,
        dexterity: (traits.dexterity % 1000) + 1,
        creativity: (traits.creativity % 1000) + 1
      });
  }

  function genSvg(uint256 tokenId) public view returns (string memory) {
    require(_exists(tokenId), "Token ID does not exist");

    Traits memory traits = genTraits(tokenId);

    string[9] memory parts;

    // bg
    // shadow
    // base
    // shoes
    // pants
    // clothes
    // hair
    // hats
    // shield
    // weapons

    // bg, shadow
    parts[0] = string(
      abi.encodePacked(
        '<rect width="100%" height="100%" fill="',
        traitStorage.getBg()[traits.bg],
        '" />',
        '<image width="100%" height="100%" href="',
        _baseURI(),
        traitStorage.getShadow(),
        '" />'
      )
    );

    // race
    parts[1] = string(
      abi.encodePacked(
        '<g transform=""><image width="100%" height="100%" href="',
        _baseURI(),
        traitStorage.getRace()[traits.race][1],
        '" />'
      )
    );

    // shoes
    parts[2] = traits.shoes == 0
      ? ""
      : string(
        abi.encodePacked(
          '<image width="100%" height="100%" href="',
          _baseURI(),
          traitStorage.getShoes()[traits.shoes][1],
          '" />'
        )
      );

    // pants
    parts[3] = string(
      abi.encodePacked(
        '<image width="100%" height="100%" href="',
        _baseURI(),
        traitStorage.getPants()[traits.pants][1],
        '" />'
      )
    );

    // clothes
    parts[4] = traits.clothes == 0
      ? ""
      : string(
        abi.encodePacked(
          '<image width="100%" height="100%" href="',
          _baseURI(),
          traitStorage.getClothes()[traits.clothes][1],
          '" />'
        )
      );

    parts[5] = traits.hair == 0
      ? ""
      : string(
        abi.encodePacked(
          '<image width="100%" height="100%" href="',
          _baseURI(),
          traitStorage2.getHair()[traits.hair][1],
          '" />'
        )
      );

    // hats
    parts[6] = traits.head == 0
      ? ""
      : string(
        abi.encodePacked(
          '<image width="100%" height="100%" href="',
          _baseURI(),
          traitStorage.getHead()[traits.head][1],
          '" />'
        )
      );

    // shield
    parts[7] = traits.shield == 0
      ? ""
      : string(
        abi.encodePacked(
          '<image width="100%" height="100%" href="',
          _baseURI(),
          traitStorage.getShields()[traits.shield][1],
          '" />'
        )
      );

    // weapon
    parts[8] = traits.weapon == 0
      ? ""
      : string(
        abi.encodePacked(
          '<image width="100%" height="100%" href="',
          _baseURI(),
          traitStorage.getWeapons()[traits.weapon][1],
          '" />'
        )
      );

    string memory svg = string(
      abi.encodePacked(
        '<svg version="1.1" viewBox="0 0 800 800" width="800" height="800" xmlns="http://www.w3.org/2000/svg">',
        parts[0],
        parts[1],
        parts[2],
        parts[3],
        parts[4],
        parts[5],
        parts[6],
        parts[7],
        parts[8],
        "</g></svg>"
      )
    );

    return svg;
  }

  function getSeedPart(uint256 tokenId, uint256 num)
    public
    view
    returns (uint16)
  {
    return uint16(getSeed(tokenId) >> num);
  }

  function setBaseUri(string memory baseUri) public onlyOwner {
    BASE_URI = baseUri;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return BASE_URI;
  }

  string DESCRIPTION;

  function updateDescription(string memory d) public onlyOwner {
    DESCRIPTION = d;
  }

  function uintToStr(uint256 _i)
    internal
    pure
    returns (string memory _uintAsString)
  {
    if (_i == 0) {
      return "0";
    }
    uint256 j = _i;
    uint256 len;
    while (j != 0) {
      len++;
      j /= 10;
    }
    bytes memory bstr = new bytes(len);
    uint256 k = len;
    while (_i != 0) {
      k = k - 1;
      uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
      bytes1 b1 = bytes1(temp);
      bstr[k] = b1;
      _i /= 10;
    }
    return string(bstr);
  }

  function updateSigner(address signer) public onlyOwner {
    SIGNER = signer;
  }

  function _genOptionalTraits(Traits memory traits)
    internal
    view
    returns (string memory)
  {
    // 0 weapon
    // 1 shield
    // 2 head
    // 3 hair
    // 4 clothes
    // 5 shoes
    string[6] memory parts;

    if (traits.weapon != 0) {
      parts[0] = string(
        abi.encodePacked(
          ',{"trait_type":"Weapon","value":"',
          traitStorage.getWeapons()[traits.weapon][0],
          '"}'
        )
      );
    }

    if (traits.shield != 0) {
      parts[1] = string(
        abi.encodePacked(
          ',{"trait_type":"Shield","value":"',
          traitStorage.getShields()[traits.shield][0],
          '"}'
        )
      );
    }

    if (traits.head != 0) {
      parts[2] = string(
        abi.encodePacked(
          ',{"trait_type":"Head","value":"',
          traitStorage.getHead()[traits.head][0],
          '"}'
        )
      );
    }

    if (traits.hair != 0) {
      parts[3] = string(
        abi.encodePacked(
          ',{"trait_type":"Hair","value":"',
          traitStorage2.getHair()[traits.hair][0],
          '"}'
        )
      );
    }

    if (traits.clothes != 0) {
      parts[4] = string(
        abi.encodePacked(
          ',{"trait_type":"Clothes","value":"',
          traitStorage.getClothes()[traits.clothes][0],
          '"}'
        )
      );
    }

    if (traits.shoes != 0) {
      parts[5] = string(
        abi.encodePacked(
          ',{"trait_type":"Shoes","value":"',
          traitStorage.getShoes()[traits.shoes][0],
          '"}'
        )
      );
    }

    return
      string(
        abi.encodePacked(
          parts[0],
          parts[1],
          parts[2],
          parts[3],
          parts[4],
          parts[5]
        )
      );
  }

  function _genTraitString(uint256 tokenId)
    internal
    view
    returns (string memory)
  {
    Traits memory traits = genTraits(tokenId);

    return
      string(
        abi.encodePacked(
          '"attributes": [',
          '{"trait_type":"Race","value":"',
          traitStorage.getRace()[traits.race][0],
          '"},',
          '{"trait_type":"Pants","value":"',
          traitStorage.getPants()[traits.pants][0],
          '"}',
          _genOptionalTraits(traits)
        )
      );
  }

  function _genStatsString(uint256 tokenId)
    internal
    view
    returns (string memory)
  {
    Traits memory traits = genTraits(tokenId);
    string[8] memory parts;
    parts[0] = ',{"trait_type":"Magic","value":';
    parts[1] = uintToStr(traits.magic);
    parts[2] = '},{"trait_type":"Strength","value":';
    parts[3] = uintToStr(traits.strength);

    parts[4] = '},{"trait_type":"Intelligence","value":';
    parts[5] = uintToStr(traits.intelligence);
    parts[6] = '},{"trait_type":"Stamina","value":';
    parts[7] = string(
      abi.encodePacked(
        uintToStr(traits.stamina),
        '},{"trait_type":"Dexterity","value":',
        uintToStr(traits.dexterity),
        '},{"trait_type":"Creativity","value":',
        uintToStr(traits.creativity),
        "}"
      )
    );

    return
      string(
        abi.encodePacked(
          parts[0],
          parts[1],
          parts[2],
          parts[3],
          parts[4],
          parts[5],
          parts[6],
          parts[7]
        )
      );
  }

  bool public CDN_ENABLED = false;
  string public CDN_PREFIX = "";

  // Smart contract creates inline SVG, however due to browser security
  // protocols SVGs may not show up in NFT marketplaces. CDN is a back up
  // Smart contract is source of truth for all traits and stats.
  function enableCdn(bool value, string memory prefix) public onlyOwner {
    CDN_ENABLED = value;
    CDN_PREFIX = prefix;
  }

  function getJsonString(uint256 tokenId) public view returns (string memory) {
    return
      string(
        abi.encodePacked(
          '{"name": "Hero #',
          uintToStr(tokenId),
          '", "description": "',
          DESCRIPTION,
          '",',
          '"image": "data:image/svg+xml;base64,',
          Base64.encode(bytes(genSvg(tokenId))),
          '",',
          _genTraitString(tokenId),
          _genStatsString(tokenId),
          "]}"
        )
      );
  }

  function tokenURI(uint256 tokenId)
    public
    view
    override
    returns (string memory)
  {
    require(_exists(tokenId), "Token ID does not exist");

    if (CDN_ENABLED) {
      return string(abi.encodePacked(CDN_PREFIX, uintToStr(tokenId)));
    }

    if (tokenId >= 10000) {
      return string(abi.encodePacked(_baseURI(), customs[tokenId].uriHash));
    }

    return
      string(
        abi.encodePacked(
          "data:application/json;base64,",
          Base64.encode(bytes(getJsonString(tokenId)))
        )
      );
  }

  function _mint(uint256 amount) internal {
    for (uint256 i = 0; i < amount; i++) {
      uint256 tokenId = ++currentId;
      _safeMint(msg.sender, tokenId);
      tokenIdToSeed[tokenId] = uint256(
        keccak256(
          abi.encodePacked(tokenId, blockhash(block.number - 1), msg.sender)
        )
      );
    }
  }

  function mint(uint256 amount) public payable nonReentrant {
    require(amount <= 10, "Can only mint up to 10");
    require(currentId + amount <= MAX_SUPPLY, "Not allowed");
    require(currentId < MAX_SUPPLY, "All minted");
    require(amount * PRICE_PER_TOKEN == msg.value, "Invalid value");
    _mint(amount);
  }

  uint256 merlinMinted = 0;

  function merlinMint(uint256 amount) public payable onlyOwner {
    require(merlinMinted + amount <= 100, "Merlin can only summon 100 heroes");
    require(currentId < MAX_SUPPLY, "All minted");
    merlinMinted += amount;
    _mint(amount);
  }

  uint256 customMintId = 10000;
  struct Custom {
    bool exists;
    string uriHash;
  }
  mapping(uint256 => Custom) customs;

  function mintCustom(string memory tokenUriHash, address to) public onlyOwner {
    customs[customMintId] = Custom({ exists: true, uriHash: tokenUriHash });
    _safeMint(to, customMintId);
    customMintId += 1;
  }
}

library Base64 {
  bytes internal constant TABLE =
    "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

  /// @notice Encodes some bytes to the base64 representation
  function encode(bytes memory data) internal pure returns (string memory) {
    uint256 len = data.length;
    if (len == 0) return "";

    // multiply by 4/3 rounded up
    uint256 encodedLen = 4 * ((len + 2) / 3);

    // Add some extra buffer at the end
    bytes memory result = new bytes(encodedLen + 32);

    bytes memory table = TABLE;

    assembly {
      let tablePtr := add(table, 1)
      let resultPtr := add(result, 32)

      for {
        let i := 0
      } lt(i, len) {

      } {
        i := add(i, 3)
        let input := and(mload(add(data, i)), 0xffffff)

        let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
        out := shl(8, out)
        out := add(
          out,
          and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF)
        )
        out := shl(8, out)
        out := add(
          out,
          and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF)
        )
        out := shl(8, out)
        out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
        out := shl(224, out)

        mstore(resultPtr, out)

        resultPtr := add(resultPtr, 4)
      }

      switch mod(len, 3)
      case 1 {
        mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
      }
      case 2 {
        mstore(sub(resultPtr, 1), shl(248, 0x3d))
      }

      mstore(result, encodedLen)
    }

    return string(result);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract HeroTraits2 {
  function getHairLength() public pure returns (uint256) {
    return getHair().length;
  }

  function getHair() public pure returns (string[2][109] memory) {
    return [
      ["", ""],
      ["Hair 1", "QmVR4Agrosv1FUsYUL3VazA6U6iKP8TsjpnSt9i8b3rWo6"],
      ["Hair 2", "QmdzHAR6kvwzNtTFc4K7Si3JYu2HK7nMWjJHYqjGg8UGey"],
      ["Hair 3", "QmbSETVbdXvxYzfnmWqje7JhrTyzuBs78cmNtkDMjRX8UD"],
      ["Hair 4", "QmTq6YusqEtE49K2FskYhhhkYudXG3eycfuFEtX93CkQqt"],
      ["Hair 5", "QmY1MUML2xeQrjJMtGqamMaJNmbNpsYrpj7SimfgPu6kMG"],
      ["Hair 6", "QmSuu6bKH49g8PLdiKWAeUeZBcirVvp6FtVRa6a3AVGCD8"],
      ["Hair 7", "QmSfCFqsKsC5YfEfhGuvNWUfppEQtc97kEg2DaMAbk7P1T"],
      ["Hair 8", "QmbgFJyFvVoNV6GwH7JVmCBXUJRmth4sZA6eCHvGD9Ayst"],
      ["Hair 9", "QmaNm9SkL13mBbztEGEAYLhGFD9PVuVNgrNE1wEQgdnCYb"],
      ["Hair 10", "QmcSHYeCh3TDxLuUHZeL1bXpPzf3s1KP2zDkw74b55vgx9"],
      ["Hair 11", "QmVeJPSR6CxAXUyfqXxijxHxVNSVPu4bXL12C4X2tt2JpM"],
      ["Hair 12", "QmV94RyUbvYZZRRh9R5pzYgRf1Lfd5qy69J6qgSShYpfAB"],
      ["Hair 13", "QmNXikU6eU6xCkLkR3apued1gbU2r1upFk3eyWvj9jXxuZ"],
      ["Hair 14", "QmZTTegdX9hhnQy3HqTMpBfMzkWKdodm88hnzAij3ATqEq"],
      ["Hair 15", "QmaAieRfrDZVzzSUWbbNoJH4JS3hkdy2ziHQqH5LYyUrWk"],
      ["Hair 16", "QmQPvYaQfVZv8NJgUyyVRejeab6GAwdVzQEgznDejvsWGS"],
      ["Hair 17", "QmYMB68YQtgUptCuUZFUjkY8z3ACVXQLbYQ3EtjnGF9EWQ"],
      ["Hair 18", "QmR6HC7R3VKK9o6FUMsGDdH4QW2XRXijZxDRtt2eDQ4cfq"],
      ["Hair 19", "QmNT4AyAo3Wo5EnToCqGdMqeEEY27YWY2945K5LW8FyCUV"],
      ["Hair 20", "Qmb8skGpSyiu8qMstcpz1t58a437en8UKEysiFpqmRanCC"],
      ["Hair 21", "QmeGczhaEDt4XGJPU85yEqpQTu6P6uXzZ3nYkF4W9bxsxp"],
      ["Hair 22", "Qma3aqjuJFiezXRcJV7DmJJ4Lqx17TGuXrEu6ceRgKfs8W"],
      ["Hair 23", "QmTowaiJ9TYSomNVd5En1UCQfmtbMW9zxbkxi8JXHAizGu"],
      ["Hair 24", "QmZahpiQvGR9z5VvNtTVe8htiGPRdyiRBJs5btoMattmMx"],
      ["Hair 25", "QmTifJ8MF1bA1BCoSkCcWNkVEgs5rTzgcHEVJVJgN2f63q"],
      ["Hair 26", "QmYbqFoGv8g3CTnvYJiL9vUZCki1XjkRt1NGND1DZse9XP"],
      ["Hair 27", "QmUwuPGpuSqiGFz5S4SmEKNs7BVB4eUFtCbapu7UZqWMVb"],
      ["Hair 28", "QmegmyWNx6jxD7Hubrsyt7s8yPBavPSp9DoV87tmZUw8oM"],
      ["Hair 29", "QmShV3vwUjgxViYMbL8tAsei4QXE9oCT55hNeYHJPN46Hv"],
      ["Hair 30", "QmR8NbJzAmM4idNC63se3iz5ovCW3xQ8Qr7io86hHKEDbd"],
      ["Hair 31", "QmRgqEYE8KKkvbVW6L9xtZM4BTWkQqoyArQrN5PKWbj4fC"],
      ["Hair 32", "QmTohKmQXEYp3EGBX9ux7nJhGnm1ceUhJCFajMfSqUvUF5"],
      ["Hair 33", "QmWJvgkV5kGAWqoeUAwt6cuMiSdi3R52k7bs53vXnEHVNW"],
      ["Hair 34", "QmbLHLXW6BwnSoWdrHqLGwR9kqLSQBQLDp9cJMdyM8T7Ti"],
      ["Hair 35", "QmNVxTU8MpPE4xzx4DS3rBMcQ4dn65Ya1CVL7GL17HmB45"],
      ["Hair 36", "QmarD1Z6brfx1ABbQdejCK844D6sdCx9TV5K3sfJZVea8x"],
      ["Hair 37", "Qme3QWm2Z2LDorfFQ129mHfHFjhdw8HPpKphdDowmmW1t7"],
      ["Hair 38", "QmZGsagUe78rk3AiryQ5qoS8rH3jiEGQnQc5iSuEjCd1Ud"],
      ["Hair 39", "QmSfVDqsHqbQtHPUk7U7iKmybHia4dp2vxCNfjroWhkXqw"],
      ["Hair 40", "QmdjShCw7LiKEDpYUPW3FHpNiuepiZEAFb7otR9SCorFX5"],
      ["Hair 41", "QmTPv8esjqKb17fPTf3kpdEbbXcH591wzTeVFBXeKVqJCd"],
      ["Hair 42", "Qmd43EPyY6g6pXXDpCAxyMjtR5VHbrK7zLarTyPjd4K6Cw"],
      ["Hair 43", "QmYD2WyJGqe7SKwKxe5drmGhzxN6741NfGgQhX8ASBG7We"],
      ["Hair 44", "QmeXappknixDZ95Bw64ifeTuKYAdmLrEtu6cdsVJ395Lps"],
      ["Hair 45", "QmNQcRV79PHPAEue75PcjE6DuQLUeoNTEbdkKMhdvgNmT6"],
      ["Hair 46", "QmfKHZecgh4JsY3N7q6qf3r3C4Wj9xNYT3xRPohbX7idY5"],
      ["Hair 47", "QmaDTiRVmqusHowbg4ij4Yw82EVdjUe5EbFe1UDc55eEfz"],
      ["Hair 48", "QmWNcABFm7xRVzzbpQhfYGUbSz4mfaQkJjfaBpUnPVX9NX"],
      ["Hair 49", "Qmcqmq4FMXedKRZ1DmC8TBNh5nS32m3mXvXhw4pukLCrdE"],
      ["Hair 50", "QmaQ2LBn9feY8vzxUDXZK44cMb5mn3cxAunoFfZ6R4ANrL"],
      ["Hair 51", "QmfR5C4hxMDNLgySiGYnLxMfrdzunbhzfyxUGmfTr6ZqTy"],
      ["Hair 52", "QmUmCDgFYnm3y1xyhJg5GSeQtXqqzC11vAhgfVb5kBj4P5"],
      ["Hair 53", "QmdAD2f1nTuAtY4z5XzVE3xP1unRQjf1M55u4FNkv8ERWo"],
      ["Hair 54", "QmajUPh1zkNDy919LHi1bLaVZTbzHXv4JGZ7Try2QmhNSx"],
      ["Hair 55", "QmeNCwHvqrNH81gcsvSeD335iZga1fR6SCZ2avSGBfLe2N"],
      ["Hair 56", "QmfXU1KCRCuBf5NBAZVV9xxKndQxaGsbhfQR443XUb6VYE"],
      ["Hair 57", "QmZrkxM7Wc2STa3tdk4nfBq2o2JG4nvMdEnxyEUvhb2xGg"],
      ["Hair 58", "Qmcqes6SnpLP228UzQbEigJNVHXZzwEwkXHbrVSBXvpwZp"],
      ["Hair 59", "QmSgPWVS7HqhUGonuw4uxBXjP6mRKMH4SpoWbDTf5Nogre"],
      ["Hair 60", "QmfP9FWjgJzeivFhknACVMTyCU8Mtse7VsMZYDR6P6dmLE"],
      ["Hair 61", "QmPwcmqrDMHHt73MZ4Aga1EGg5KCduo7wcMRC7Hms5nyfh"],
      ["Hair 62", "QmbbVkDt7Y6K3pnt6m79obn61MwsoeW1NHqYgW2poAYWvz"],
      ["Hair 63", "QmcKATVT8NUpWRwBhuLJgFhQX1yxUeGyRhsfJtzkPGFR6W"],
      ["Hair 64", "QmRB2Np8aih7LfvfLFGbPu7R2X3nCerJvJgBiYzECUFguT"],
      ["Hair 65", "QmUAyjR8TzV53Uatwgja2WBkVqaCQ36ZMwW45Wfv7vyTKB"],
      ["Hair 66", "QmTcaK9nghZV6LuMBruaa7nq9WXic6W5hiC5Ech755Myx4"],
      ["Hair 67", "QmbipeCH6nLmqSrx12UM9FMXVjRbrVicveJbGtoqFrCQPi"],
      ["Hair 68", "QmTPvtSd7kykCVVd7zMy5wTKBPMWXW4a1sivzaCrG4L3yy"],
      ["Hair 69", "QmQ4bfdYJqiCRjK7xqZB1Jmnhr7h5ghnR11MTAUtiwcr6G"],
      ["Hair 70", "QmV3Wi2N78DQDXcVTBYeYwfUp8ijWe7Ce43e4JEbSSHPLV"],
      ["Hair 71", "QmcaFf4MN3NJ1jDFcH9n7czPSCcnQ5L86Me5FvRZxBs59E"],
      ["Hair 72", "QmQdTwNiEqnebVdYh5Bcepr4WwgZDLmZEVRnGLPXtexgzH"],
      ["Hair 73", "QmaSM75ikFySmNyA5ZGVWPjfScLycRjioTaRne8WKibBsc"],
      ["Hair 74", "QmNWmpyciad8YtR3KKtLssPpM1mDQYGUaA5wF5XZ3dturg"],
      ["Hair 75", "QmW5rJbTHRS8K1RcYDGXsMfrTwMqvbx8pVX75ZeLSWKJ5G"],
      ["Hair 76", "QmU2oooeZUnAUCcPUTqDLL6WeGLoGBq77Sari2kDsxfV24"],
      ["Hair 77", "QmTgfbD9NAfppAXGwod4XQmaD5Wc63mVSL3UXxSJrBDRU9"],
      ["Hair 78", "QmaimS11NaXAb3wvKtCs3BZZryvCcswAHCe6kTPD2fva87"],
      ["Hair 79", "QmVD1ekc7gfUuYaJ7yiEFpGRcVAD1nbBpvYQbv5wRPcuWR"],
      ["Hair 80", "QmSTrw4zyrRjt8kdpaPRHV5qeyvm6qDAtZz7qqBD8Cxi1v"],
      ["Hair 81", "QmfZ7LkgjARn6H7JV5pS4iPTjXcxwP5NmmWviCq4oMpXfk"],
      ["Hair 82", "QmbFu7FMm9u3ic7nZQp2SDRUALFnKudLZyXk3hjsTiRtCL"],
      ["Hair 83", "QmbAF7TdKvoWYkNQsL1TKxmih3yArVUH4ubyEiCCvcJaWr"],
      ["Hair 84", "QmR9n4981fVdQ4K7m8HJbB9pdxP2q8PmoWABDpe684grP3"],
      ["Hair 85", "QmTPbfaPAgyTdX1ppo8frxGBN4CQrs5WjFuLtMVKTsYZ84"],
      ["Hair 86", "QmYcyYG2TeHbDGGK5PMPyV61ye5SbnaMoAkvfqNBc9GCox"],
      ["Hair 87", "QmP4ZXYa7g9ZmHuVh5w9iQWp7m9Vm2uVsni1VZNmva16ca"],
      ["Hair 88", "QmedG9KE12FePh4TGbFEecCws3PubmoWDqVVW7GeyP439B"],
      ["Hair 89", "Qmb8KJnrfM3SFZyXd7ZXCZVrcweohcXLpRmomZgQ7uxvx4"],
      ["Hair 90", "Qmc1593Mkjhs9dxYw8Z4bH63QZ1jXEtmsuj4ugxnP2DKS2"],
      ["Hair 91", "QmeQ7HfbfQRFManSHa49AvXyVFv8Z4uRwN3n85FedbbKiF"],
      ["Hair 92", "QmTBbq66ufbjo4RQ5kM18AHkjK9fbXnX1UcAwFijUSGHYn"],
      ["Hair 93", "QmRocj4DoqMzdaGFrosD8Gjf42oH227GZgpCQFFyubQCRL"],
      ["Hair 94", "QmUoEZdnsm8tDHmEMrE2TzoNbkbsMX5JpXx9mVNLupz5hv"],
      ["Hair 95", "QmRBST9zT92eDLCY9qDWrFquRoY3gjPKs1vqcZA9u6xCKq"],
      ["Hair 96", "QmZEoxDe67kN34LxWQnHKBhHDkXuWj3ZCoPugLwXjqyyJo"],
      ["Hair 97", "QmWf1fL3uuFPAGTjy6uyKUjt88yFBLZvMwapXwcGi39bJR"],
      ["Hair 98", "QmTUeMeKB8HFRc7QhUq1sWb851H7Ru3c614M31XuUDzr9Y"],
      ["Hair 99", "QmTfXVdNcWwFBL6dzzgH6APpaUD8L7P5fFkHRWtJaVJRad"],
      ["Hair 100", "QmNxdDQ8oQ3kiFwmkY5zx1j14MmuGr4KrN9UoCH8PM227q"],
      ["Hair 101", "QmVP865PD44yX6NjRXtMLqmWP634fzgWYdDRRU4mrPvFHn"],
      ["Hair 102", "QmVi8pzkHqjgYXgkkvL3qXjNvP1BmH7UTyP1CAt2P5PP1N"],
      ["Hair 103", "QmPPGbaDeetLKc1QFXRNXP8WVSazyniSMZM2Dyhqp9mZgK"],
      ["Hair 104", "QmY5iQcSzG8cChzVbVNWPRzcK1ETXbP7heSSfwEdHmn3CX"],
      ["Hair 105", "QmddMPzse52GK7wh3BWAkpA5BmXxVA2rkzBV27RNAqRLQ5"],
      ["Hair 106", "QmP1KfmDzDaSFkQ7Pw4ZkWLhjmgzN4w8W5SznP3SC4WgFb"],
      ["Hair 107", "QmVd8UUu2ApmjxeTkt672nf5vdoojTfjmJw77rfgXF9moh"],
      ["Hair 108", "QmdDtkeqd2dMLFtwFAK6Yq4johr8SyY1MLc61VhD9FwduJ"]
    ];
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract HeroTraits {
  function getPantsLength() public pure returns (uint256) {
    return getPants().length;
  }

  function getPants() public pure returns (string[2][5] memory) {
    return [
      ["White Pants", "QmS1ugwVyGemvvcu8xhvYPLJcM9XiCzev19hL5S4118mvY"],
      ["Red Pants", "QmQRw479rzessc1ms2kcnKQCvCs2aQ1Ep25vK7xgo9cEJt"],
      ["Blue Pants", "QmePEJz87mRjQt9BmYib14Fcxn8j13Xkdj6MfYoUZbQi79"],
      ["Green Pants", "QmZ6sjTg936aJCM67NPsPcCjMphAYEWoyQXHNHduKzLyf7"],
      ["Purple Pants", "QmPP9edeKhcJAM2YKxVfJhLaFHmLxJLm3WGcwWBvNvGXkZ"]
    ];
  }

  function getWeaponsLength() public pure returns (uint256) {
    return getWeapons().length;
  }

  function getWeapons() public pure returns (string[2][19] memory) {
    return [
      ["", ""],
      ["Boomerang of Wood", "QmeZpiK4w2G4nQnEsm9m83h1oZXSaxX5P9tg1ai7cEzCvc"],
      ["Bow of Focus", "QmNSq5KzbDhRJNuFkUmLc3MZBe5fcVKbvQcNSfThsG4KXw"],
      ["Mythal Short Sword", "Qmbbz8kkycoEK4r3oMUyw3aqrTQbCfdTno9i9eCKfFTCmz"],
      ["Bow of Honor", "QmNMApPhGawYMQtCsVNbkD2tSsyA7wfHeNuspw8jSrFaBL"],
      ["Axe of Honor", "QmeLEVz3Jy2FhWRBrQqN8szyUhYtjFxDPGVHxnTJY1xd2h"],
      ["Wood Long Sword", "QmXnwjgest5CZVz5ZhUyNnLo1diWFhkKhBck98xY4cpvRP"],
      ["Boomerang of Flight", "QmPeNnTj25uXJz67mFrJr4ro1zxENYXAGX6kfSxAC9GBxs"],
      ["Axe of Wonder", "QmT32TRmyg1xJCA9n7oFBRcuRW5vbb5TboXh5LygyLTXbi"],
      ["Bow of Mystery", "QmbQLEKE1QbGnqNjKeBLLVwcDEoQNB98fsoEQgUbVgrPJk"],
      ["Axe of Strength", "QmRfhpxsSQHCmsxGPbSDAD7rTKAjVfqgHVBfdoVZBALWFC"],
      [
        "Elvish Staff of the Forest",
        "QmZTTFEmaGu54yj9kUwH3xL4mZrfXJXp8RtzqYMHMYww6p"
      ],
      ["Staff of the Sea", "QmUsxTdawFhmWPEbBwqRUi9SGpNBeUN8RwxUUQczxVP8TX"],
      ["Universe Staff", "Qmab3zQ2n1ZPYpTEgkivDHuryM6A5P1sTjCQoWN5N9ADWE"],
      ["Mythal Long Sword", "QmSx6MiY29hFoYV2pnehEdbmuFipwupz2y2DJZyCN54jdZ"],
      ["Wood Short Sword", "QmWFFLygzSa9UXNJAtthRAurazVXjhfZ1ZsDAAsFrKWSQm"],
      ["Boomerang of Focus", "QmXPDw8pxgnsFsGoz4bw7cWA2G1ZK1MDXArNKHr1VPv3GQ"],
      ["Iron Short Sword", "QmTqDh8schE195bh6HSsoPfYLVYZLRrXaRen92nJfZcFDC"],
      ["Iron Long Sword", "QmfYEHBEReGSDKWZuRUBMRiHGhiBo1jTFwpWnVaAG11saw"]
    ];
  }

  function getBgLength() public pure returns (uint256) {
    return getBg().length;
  }

  function getBg() public pure returns (string[26] memory) {
    return [
      "#FEDD00",
      "#74D1EA",
      "#9DE7D7",
      "#9E978E",
      "#84754E",
      "#00B08B",
      "#222223",
      "#6B4C4C",
      "#ff2424",
      "#FF808B",
      "#DF1995",
      "#C1A7E2",
      "#685BC7",
      "#DDDAE8",
      "#1B365D",
      "#A4BCC2",
      "#407EC9",
      "#009CDE",
      "#003865",
      "#40C1AC",
      "#279989",
      "#00BFB3",
      "#006F62",
      "#ADDC91",
      "#007041",
      "#58eb34"
    ];
  }

  function getRaceLength() public pure returns (uint256) {
    return getRace().length;
  }

  function getRace() public pure returns (string[2][22] memory) {
    return [
      ["Human", "QmbVrpTTEciNQPxb8TjntcmpQMDLrzgEsJxYrpGanCmH88"],
      ["Human", "QmWTzCYevtrCY9Yu9HZ1RudJ5DZ3ySMbbb6V8j1GMoFd2W"],
      ["Human", "QmYhchiEeh4iJPYSksxoUAoy9SZCCEU21UQzEyeFxWBcBj"],
      ["Undead", "QmTtNfnd3HZ7moKrzaJaYyUM5idGbKy2sgHE14fpeyU9UL"],
      ["Skeleton", "QmcMDNnc8SNjwvPBpcb6hXG3yjz9WSiQ5qzbJTZre7N2uB"],
      ["Wizard", "QmYotarEMJ98MHfZGDKhsgCcZU54EzTRPCuS88vG9PBUtd"],
      ["Ghost", "QmTuv44nHYMAix3L36HuBkPV5sQ6NPiGhxSFGSTnAHipJk"],
      ["Frogling", "QmPXTBPcjrxrjwAaH9VaLzV8uZVpHuy2VnytHT1LWsYWuX"],
      ["Pizza", "QmaJFAM6iV473UUcEQUPP7hCtP1Zh5jspvMHb9sJYiyutJ"],
      ["Slate Monkey", "QmNZezfUXKEQZkrXfobHsudcqqAECt97yYZQRUV12jkNbj"],
      ["Emerald Monkey", "Qmdy1tBPBa85TeDMYb9KVPHanU7Wor39yLEpAJwEUDfgK8"],
      ["Red Monkey", "Qmb23Pp17Xg5nBQJnfkzQ4rMWPKYnNNWqJcYDaDoJJnwSN"],
      ["Gold Slate Monkey", "QmNn3agjVqz4WFNvcm3Srzg2EuKJoJi2W2t32E1aDVhAwg"],
      ["White Monkey", "QmTH9fLyHLzbP6KXUFdJKCKYZqPUHEv7vrYeP95s8AZ57B"],
      ["Emerald Red Monkey", "QmZJQQE2QS9kMHhUe1PbCNnG1QvGH7hiW6sPETZtqpeEZK"],
      ["Yellow Monkey", "QmRdNLRMzuTmEuQZVtJAXj9ydxs3Ztb1EdCcF8eqRFQBBe"],
      ["Honey Monkey", "QmbgrRnunnkJSS9L945bvbP9gd54nRJ8D6YMi1jECvHhei"],
      ["Red Furred Monkey", "QmdHwSAhmthUbTUfSTqD7EMFWcZ13LLZbvoNTYgKjJb5Vj"],
      ["Snow Monkey", "QmYvjKEGeSZH2dMhSvgooPt5AatSZzQm2UvMBNhoKvUvER"],
      ["Brown Monkey", "QmehwhevsQdDyAoG2maHFA7Pip4x6KLVRU1KVfmV4pfDmu"],
      ["Gold Monkey", "QmTsvwBm7MTRgZBhLmV2GFtC7FzBggwcNNWDmk5iNyk2oP"],
      ["Tree Monkey", "QmYJBTHYE8WjNFV2udVre3yXTy9Y5xwScBW4bgHvaoPL5r"]
    ];
  }

  function getClothesLength() public pure returns (uint256) {
    return getClothes().length;
  }

  function getClothes() public pure returns (string[2][25] memory) {
    return [
      ["", ""],
      ["Robe of Fire", "QmUH91Yysb2SsDNKZSrkUMevUcoSU3dmcvpcozWAuEvr18"],
      ["Shirt of Mystery", "QmXRYw9yfgDYAU27KMQafT41hKQFVGJZBqwjs3nkWEUpAp"],
      ["Vest of Fire", "QmZDeqtzajKwxV9YgfzcZ8Wfap1zARUicUWjTJmJBMdQdw"],
      ["Tunic of Wonder", "QmaS95LAjXoF3EWxPowwbybBvhG7NtqAA6KeWLYpAzKUVZ"],
      ["Tunic of Mystery", "QmYJ1xzvptgSVakpUGQgaXjF4w8nnZyNCoDz9v9TJKEcpz"],
      ["Shirt of Fire", "QmQc1ThSSgbdC6z5nwLDyMyPYqrUC6JBDhfu7WWkyyx9QP"],
      ["Vest of White", "QmYXx2ihhkFWbjHGkyyfSsQf5jnHPojmo1cWBS9RNjLo8R"],
      ["Tunic of Fire", "QmcfVUUiFDNoJnZP8W8eSHPq11WRj99oeK4LLaJQtQ1fb8"],
      ["Robe of Mystery", "QmW9xSXtHfikeScmhpB56kWHdNSDPJaA2F4DRiRdS1gt96"],
      ["Robe of White", "QmRdTAV3jspvFCdWuTL1wYvz34BS1BXhUY9ctsouy11vfR"],
      ["Shirt of Emerald", "QmU3i6M3JgPUSFMzfwCjgAkcFtwtmEvwgdSvTEN9gBQ2Ld"],
      ["Vest of Mystery", "Qme5ZavY4PMvt5bSmrLJErrnDyUckaNH9FrgT5aYqdnnBf"],
      ["Robe of Emerald", "QmZynRUwPjL6Du9LsGyPA3u1fYabmKuefjRnyTgAm99S8D"],
      ["Vest of Wishing", "QmUWNR2XF8dAgPXyakxUmpbr5SWz3kytzu49dAhRBo3gLZ"],
      ["Gown of Magic", "QmQBvcfZ1tsue32nerkpRCsYzDJfNpy466zAhwZ7jWENLw"],
      ["Robe of Wonder", "Qmbidcgmae5LJqcQKoVwF1832maJ7nMdScNr79hkvMtkkd"],
      [
        "Gown of the Universe",
        "Qmehwi2m5aqrZcqUxBjeJbXRcfWjErxywu3HbwXKPZXa2p"
      ],
      ["Tunic of Light", "QmQvhTVqSFRo4zm8uye1f6tYUSUoNvksdgrDzKychyDTKR"],
      ["Snow Gown", "QmZRoMDJFGr7umyFhH6KBporsrqG7mS1d65xMtzcTHipLj"],
      ["Blue Vest", "QmXnYYxyexqF7qcYkPDhzrrzbLkwSTeHEDfwobQLvwMd75"],
      ["Gown of Flowers", "QmaG7srwBaMSUBsExqhUuAUtQbKG12qjcmT1KKoihk7n34"],
      ["White Shirt", "Qmb7iqzgFA3NcJJQutWYFgT946bcy5JwfGHevzc9TFFXt1"],
      ["Blue Shirt", "QmQosecPGEQ8qhP1AvPNrphzrga8f3jkpNvB7HPku49cej"],
      ["Tunic of Emerald", "Qmb6yH7Ss23kL75LfrJTGZXb4oNTXx8A9Uhdr18txKFbqQ"]
    ];
  }

  function getHeadLength() public pure returns (uint256) {
    return getHead().length;
  }

  function getHead() public pure returns (string[2][24] memory) {
    return [
      ["", ""],
      ["Dark Hood", "QmecUFzdxqbhzQGQzpoxqWViFXybMA4amKC9vcwddEzj3y"],
      ["Emerald Hood", "QmQR7CLWNY66kicK51cPjzpf7tcZVEVjZm8PhMtHjBJthi"],
      ["Blue Hood", "QmUEhNvJQ5PmPWvJfABNJ5mwZg9s9uANgeFh8wBfwnftk1"],
      ["White Hood", "QmSNTEq8GsBkzRq19T3Rh9jdULr46KCtKJxVEKTgUQajAo"],
      ["Red Hood", "Qmc4VPaLnV1JPUvpzsYxsKaYofaCbrhgKK3TaDcnf6tW3L"],
      ["Helmet 1", "QmcuWWeEsqWMh6ESKEi4BpbicnoqpQt5WQcLhqC9kggj2M"],
      ["Phrygian Cap", "QmRYZTTanct9LqJw6Mr4EjuTN5iGvySnbgB3GAviy9QAaX"],
      ["Reddish Hat", "QmemYuaZ6ti3f9hZB6sMnCZ9CyHnPRsBCTsSBrTGp7jgFS"],
      ["Hat of Luck", "Qmed5Ebw2HqfeDBn845Sb6UJdSFeedZvwcF2eDeDVTt5Q8"],
      ["Purple Hat", "QmTaet5S2Q8tRa6fa4REPQ3USdn7G6Ptemm4nMb3BpLhZ5"],
      ["Wizard Hat", "QmTAoe4qpfHsER7swyzbGj1zSR6GuRTsMfBaWdWQtsVUAu"],
      ["Helmet 2", "QmQd9zjzVbCEG3HTsnLSjfj4D8g2YbVAwJD9jLnf6x3SqH"],
      ["Helmet of Nebulous", "QmWEvHZyBXuezBcAFKvM55MdVWDnqQCXQXL4xDUzPCVYY6"],
      ["Helmet of Valoria", "QmZX3jJVEhJNTtQM5mTJNkfCSZxqfULsZ88bHg1ekELiGT"],
      ["Hat of White", "Qma6pcKWCwCbLdQfbLqYA8vNr8jr74uTM2dNiK5Ga6GSQL"],
      ["Helmet of Thulium", "QmWWFXsfSuSNRTN4qVdjPH9cf6bccZ3mUbJz8MXXY7Ky8n"],
      ["Helmet of Wonder", "QmNQQ9rZUscy6fLHdhqndmDm43dSe1xo45JBqkiKNN95qz"],
      ["Helmet of Valoria 2", "Qmd1Xza7bLMXNdHmpCP2Dt2Fo7YkyECnQxnsbNgPPEkipK"],
      ["Beep Bop", "QmaPxQGtBVHp7HWDmc7hjnHXCWbubNHFb3dctqetfT5S8S"],
      ["Helmet of Power", "Qmaqi98rt2oFwzjwJxbWmVgdbrjQshCPt5cCpmLUHsM9Cn"],
      ["Beep Bop 2", "QmTNiTTa7BZdAHNni9AgVdcQ86GNkDrDcmreLRRCVHnE4V"],
      ["Beep Bop 3", "QmXnP7hifqudavHmH92o9eDATz8qvpZef7CtGZDdgi5Hoz"],
      ["Helmet of the Sea", "QmXQBQtsdaM5CNC84r3LvjqsQPcBWnmsKvP2U1SdnGdHph"]
    ];
  }

  function getShoesLength() public pure returns (uint256) {
    return getShoes().length;
  }

  function getShoes() public pure returns (string[2][5] memory) {
    return [
      ["", ""],
      ["Shoes", "QmZuWKcMRRRP28eCFq7oZ19VHp5fKsHfKeLPvRh9AhQw3G"],
      ["Golden Runners", "QmSBkmnuG4N8GXMRhAMyYEqoajApFwHymt1aPcDaQXoiX8"],
      ["Blue Shoes", "QmXrspeWB4J3kSYovtuGCz6FqAs5KgxpZs13obSUoSBW3D"],
      ["Blue Boots", "QmZVtB16f6Z8MgEzkv2XCE9ayFe34tTRwouRPKbVZiNjF1"]
    ];
  }

  function getShieldsLength() public pure returns (uint256) {
    return getShields().length;
  }

  function getShadow() public pure returns (string memory) {
    return "QmcRNVeYU1CeMe2yD1HKpg5bvBQCfcW5xZp67HYSstAzSZ";
  }

  function getShields() public pure returns (string[2][11] memory) {
    return [
      ["", ""],
      [
        "Shield of the Forest 1",
        "QmVSwjgTzn7w9jYFvmzadBmFYDaTFi5H9JK8hUW5EJ6Uq3"
      ],
      ["Shield of Iron 1", "QmZWnaVywirur14yBBGfBJdQiqit6rQwB5NUAzkdJzqnPS"],
      ["Mythal Shield 2", "QmebyDHQq24xgLEjoN33aSSQUCFX3vTpf9koRo62GCB6bM"],
      ["Mythal Shield 3", "QmbVKssPYZS1V9bZmkDfpU1EqKyFSKkVLunqQasiipQCkD"],
      ["Shield of Iron 2", "QmYpmqDQZvPPQoNsiH4jDUksozTgWiK13KfWT24YorFsY7"],
      ["Mythal Shield 1", "QmT21FSftCYKcSvjK262vyw79zqQpzxuPCvPNKY23CbNzn"],
      ["Shield of Absolute", "QmPGtk89gzqK93hV8v1noqJthoB3QAccxZGVw9TZUKrKmZ"],
      [
        "Shield of the Forest 2",
        "QmcDwGHTrcdFusDAagX3632cDjAczawoWL6uChv4Y68gF2"
      ],
      ["Shield of Iron 3", "QmPvccz4cMBh3589fht4hCdwRJYyNAHMRggy4YUwKzGKv4"],
      [
        "Shield of the Forest 3",
        "QmRPvKjbSQafzLcxwU4CFBKuemNRxGBS8U3ra8rGFJRRGy"
      ]
    ];
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}