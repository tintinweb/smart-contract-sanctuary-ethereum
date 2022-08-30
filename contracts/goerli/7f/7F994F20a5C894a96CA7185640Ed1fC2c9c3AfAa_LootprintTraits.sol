// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./OwnableBase.sol";

interface IMoonCatRescueTraits {
  function hueIntOf (uint256 rescueOrder) external view returns (uint16);
}

contract LootprintTraits is OwnableBase {

  /* Name String Data */

  string[4] internal honorifics =
    [
      "Legendary",
      "Notorious",
      "Distinguished",
      "Renowned"
    ];

  string[32] internal adjectives =
    [
      "Turbo",
      "Tectonic",
      "Rugged",
      "Derelict",
      "Scratchscarred",
      "Purrfect",
      "Rickety",
      "Sparkly",
      "Ethereal",
      "Hissing",
      "Pouncing",
      "Stalking",
      "Standing",
      "Sleeping",
      "Playful",
      "Menancing", // Poor Steve.
      "Cuddly",
      "Neurotic",
      "Skittish",
      "Impulsive",
      "Sly",
      "Ponderous",
      "Prodigal",
      "Hungry",
      "Grumpy",
      "Harmless",
      "Mysterious",
      "Frisky",
      "Furry",
      "Scratchy",
      "Patchy",
      "Hairless"
    ];

  string[15] internal mods =
    [
      "Star",
      "Galaxy",
      "Constellation",
      "World",
      "Moon",
      "Alley",
      "Midnight",
      "Wander",
      "Tuna",
      "Mouse",
      "Catnip",
      "Toy",
      "Kibble",
      "Hairball",
      "Litterbox"
    ];

  string[32] internal mains =
    [
      "Lightning",
      "Wonder",
      "Toebean",
      "Whisker",
      "Paw",
      "Fang",
      "Tail",
      "Purrbox",
      "Meow",
      "Claw",
      "Scratcher",
      "Chomper",
      "Nibbler",
      "Mouser",
      "Racer",
      "Teaser",
      "Chaser",
      "Hunter",
      "Leaper",
      "Sleeper",
      "Pouncer",
      "Stalker",
      "Stander",
      "TopCat",
      "Ambassador",
      "Admiral",
      "Commander",
      "Negotiator",
      "Vandal",
      "Mischief",
      "Ultimatum",
      "Frolic"
    ];

  string[16] internal designations =
    [
      "Alpha",
      "Tau",
      "Pi",
      "I",
      "II",
      "III",
      "IV",
      "V",
      "X",
      "Prime",
      "Proper",
      "1",
      "1701-D",
      "2017",
      "A",
      "Runt"
    ];

  // chosen by fair block hashes.
  // guaranteed to be random.
  // https://xkcd.com/221/
  bytes32[20] public revealBlockHashes = 
    [
      bytes32(0x4b070ab0f3977ed60155863326e18aa33893eea2994bef7dbf993b7f5bc056f4),
      0xf4051b701f9e5f413456292a42f1c13492d4177859c300fa61cdbaef23b7defb,
      0x29909d5dbd1d3e1ecf28c26ad7158b0e9e420066392523bec53296a9c9730159,
      0xce27d7465d3ca6ffcc475092bf41ac170605fc6fb6a4df3f36894e281891bc38,
      0x3616afa76e65c2c0e8357e14178429d3f6a2b2119c1599021f269b9d8a5bc63b,
      0x2161b097abb27883e7529f222980f3e09a59b6a473b56cccf45fc84e8d7155f0,
      0x24c8dd6c765a265d612be4ac67d4f89190c99e4f7b4cdc0f46e65302578e66ea,
      0x07133d9d62e47e7309749ee6f52ffc11a7235e5724e3fa675f084e39df41c756,
      0x6e009c9a36f53d808e34ea46eb912a5f097bd2d6036163ee8ceba220364e5cf6,
      0x44010cc875248257026b952ee5d2cce15bbd099d23abd6e4ea0245d8c1117312,
      0x530e72cd291578d2ca6bddd054bb89638d6e364a92cc1705c619b20c136da6c7,
      0xaa1702c4ef7a85d68d7f5f363650d07e00a263ea024cf9d7cd69334797412b08,
      0x771823c421180482c57658c880ff3e732c70d064b66c60b9be67c0f7296fc948,
      0x2a331e173389e7a49876ce1321a32fdf6961686ad6edaa29bbfa4fefe0e25766,
      0x14814e199c8230013fb2a485aa809c23b79fd92dccbf7b333ca45f9ad859e4a8,
      0x9cd8ef618851f637da4db0bacba7a746ccbc904d48ffaef2a5d4a414bcab6727,
      0x6c190cf2897edb23131e1ccaac6fa3db757ced227a658961691fee48c1293a0f,
      0x5f45f0272a59823b63c4502c5644c063a30ebc67d74f991f2e4438a6d6cac6f0,
      0x2c8cf5baca864e851c97a5c61239889107bea8499d1422815c4d4c502bfa8622,
      0x7aca66f97ef29fc7c910aec95a515e8f853a5d0829c24c0ff08e342a2953da22
    ];

  /* Data */

  bytes32[1423] private lootprintIndexes;
  bool public finalized = false;
  IMoonCatRescueTraits public MoonCatRescueTraits;

  constructor (address documentationAddress, address moonCatTraitsAddress) OwnableBase(documentationAddress) {
    MoonCatRescueTraits = IMoonCatRescueTraits(moonCatTraitsAddress);
  }

  function setLootprintIndexes (uint256 offset, bytes32[] calldata indexes) public onlyRole(ADMIN_ROLE) {
    require(!finalized, "metadata is finalized");
    for (uint i = 0; i < indexes.length; i++) {
      lootprintIndexes[offset + i] = indexes[i];
    }
  }

  /**
   * @dev Update address for on-chain MoonCat Trait data.
   */
  function setMoonCatRescueTraits (address moonCatTraitsAddress) public onlyRole(ADMIN_ROLE) {
    MoonCatRescueTraits = IMoonCatRescueTraits(moonCatTraitsAddress);
  }

  function finalize () public onlyRole(ADMIN_ROLE) {
    finalized = true;
  }

  /* Traits */

  string[5] internal class_names =
    [
      "Mech",
      "Sub",
      "Tank",
      "Cruiser",
      "Unknown"
    ];

  /**
   * @dev Convert a Classification ID number into a string name
   */
  function getClassName (uint8 classId) public view returns (string memory) {
    return class_names[classId];
  }

  string[15] internal color_names =
    [
      "Hero Silver",
      "Genesis White",
      "Genesis Black",
      "Red",
      "Orange",
      "Yellow",
      "Chartreuse",
      "Green",
      "Teal",
      "Cyan",
      "SkyBlue",
      "Blue",
      "Purple",
      "Magenta",
      "Fuchsia"
    ];

  /**
   * @dev Convert a Color ID number into a string name
   */
  function getColorName (uint8 colorId) public view returns (string memory) {
    return color_names[colorId];
  }

  function colorOf (uint256 lootprintId) public view returns (uint8) {
    if (lootprintId >= 25440) {
      return 0;
    }
    uint16 moonCatColor = MoonCatRescueTraits.hueIntOf(lootprintId);
    if (moonCatColor == 1000) {
      return 2;
    } else if (moonCatColor == 2000) {
      return 1;
    } else if (moonCatColor <= 15) {
      // MoonCat is Red; lootprint is Cyan
      return 9;
    } else if (moonCatColor <= 45) {
      // MoonCat is Orange; lootprint is Sky Blue
      return 10;
    } else if (moonCatColor <= 75) {
      // MoonCat is Yellow; lootprint is Blue
      return 11;
    } else if (moonCatColor <= 105) {
      // MoonCat is Chartreuse; lootprint is Purple
      return 12;
    } else if (moonCatColor <= 135) {
      // MoonCat is Green; lootprint is Magenta
      return 13;
    } else if (moonCatColor <= 165) {
      // MoonCat is Teal; lootprint is Fuchsia
      return 14;
    } else if (moonCatColor <= 195) {
      // MoonCat is Cyan; lootprint is Red
      return 3;
    } else if (moonCatColor <= 225) {
      // MoonCat is Sky Blue; lootprint is Orange
      return 4;
    } else if (moonCatColor <= 255) {
      // MoonCat is Blue; lootprint is Yellow
      return 5;
    } else if (moonCatColor <= 285) {
      // MoonCat is Purple; lootprint is Chartreuse
      return 6;
    } else if (moonCatColor <= 315) {
      // MoonCat is Magenta; lootprint is Green
      return 7;
    } else if (moonCatColor <= 345) {
      // MoonCat is Fuchsia; lootprint is Teal
      return 8;
    } else {
      // MoonCat is Red; lootprint is Cyan
      return 9;
    }
  }

  function decodeClass (uint32 seed) internal pure returns (uint8) {
    uint class_determiner = seed & 15;
    if (class_determiner < 2) {
      return 0;
    } else if (class_determiner < 5) {
      return 1;
    } else if (class_determiner < 9) {
      return 2;
    } else {
      return 3;
    }
  }

  function decodeBays (uint32 seed) internal pure returns (uint8) {
    uint bay_determiner = (seed >> 4) & 15;

    if (bay_determiner < 3) {
      return 5;
    } else if (bay_determiner < 8) {
      return 4;
    } else {
      return 3;
    }
  }

  function decodeName (uint32 seed) internal view returns (string memory) {
    seed = seed >> 8;
    uint index;
    string[9] memory parts;
    //honorific
    index = seed & 15;
    if (index < 8) {
      parts[0] = "The ";
      if (index < 4) {
        parts[1] = honorifics[index];
        parts[2] = " ";
      }
    }
    seed >>= 4;
    //adjective
    if ((seed & 1) == 1) {
      index = (seed >> 1) & 31;
      parts[3] = adjectives[index];
      parts[4] = " ";
    }
    seed >>= 6;
    //mod
    index = seed & 15;
    if (index < 15) {
      parts[5] = mods[index];
    }
    seed >>= 4;
    //main
    index = seed & 31;
    parts[6] = mains[index];
    seed >>= 5;
    //designation
    if ((seed & 1) == 1) {
      index = (seed >> 1) & 15;
      parts[7] = " ";
      parts[8] = designations[index];
    }

    return string(abi.encodePacked(
      parts[0], parts[1], parts[2],
      parts[3], parts[4], parts[5],
      parts[6], parts[7], parts[8]
    ));
  }

  function indexOf (uint256 lootprintId) public view returns (uint16) {
    uint16 index = uint16(uint256(lootprintIndexes[lootprintId / 18]) >> ((lootprintId % 18) * 14)) & 0x3fff;
    require (index != 0x3fff, "lootprint doesn't exist");
    return index;
  }

  function seedOf (uint256 lootprintId) public view returns (uint32) {
    return uint32(uint256(keccak256(
      abi.encodePacked(lootprintId, revealBlockHashes[indexOf(lootprintId) / 1280])
    )));
  }

  function classOf (uint256 lootprintId) public view returns (uint8) {
    return decodeClass(seedOf(lootprintId));
  }

  function baysOf (uint256 lootprintId) public view returns (uint8) {
    return decodeBays(seedOf(lootprintId));
  }

  function nameOf (uint256 lootprintId) public view returns (string memory) {
    return decodeName(seedOf(lootprintId));
  }

  function getDetails (uint256 lootprintId) public view returns (
    uint8 class, uint8 color, uint8 bays, string memory shipName, uint16 index, uint32 seed
  ) {
    index = uint16(uint256(lootprintIndexes[lootprintId / 18]) >> ((lootprintId % 18) * 14)) & 0x3fff;
    require (index != 0x3fff, "lootprint doesn't exist");
    seed = uint32(uint256(keccak256(
      abi.encodePacked(lootprintId, revealBlockHashes[index / 1280])
    )));

    return (
      decodeClass(seed),
      colorOf(lootprintId),
      decodeBays(seed),
      decodeName(seed),
      index,
      seed
    );
  }

}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.9;

interface IReverseResolver {
  function claim (address owner) external returns (bytes32);
}

interface IERC20 {
  function balanceOf (address account) external view returns (uint256);
  function transfer (address recipient, uint256 amount) external returns (bool);
}

interface IERC721 {
  function safeTransferFrom (address from, address to, uint256 tokenId ) external;
}

interface IDocumentationRepository {
  function doc (address contractAddress) external view returns (string memory name, string memory description, string memory details);
}

error MissingRole(bytes32 role, address operator);

abstract contract OwnableBase {
  bytes32 public constant ADMIN_ROLE = 0x00;
  mapping(bytes32 => mapping(address => bool)) internal roles; // role => operator => hasRole
  mapping(bytes32 => uint256) internal validSignatures; // message hash => expiration block height
  IDocumentationRepository public DocumentationRepository;

  event RoleChange (bytes32 indexed role, address indexed account, bool indexed isGranted, address sender);

  constructor (address documentationAddress) {
    roles[ADMIN_ROLE][msg.sender] = true;
    DocumentationRepository = IDocumentationRepository(documentationAddress);
  }

  function doc () public view returns (string memory name, string memory description, string memory details) {
    return DocumentationRepository.doc(address(this));
  }

  /**
   * @dev See {ERC1271-isValidSignature}.
   */
  function isValidSignature(bytes32 hash, bytes memory)
    external
    view
    returns (bytes4 magicValue)
  {
    if (validSignatures[hash] >= block.number) {
      return 0x1626ba7e; // bytes4(keccak256("isValidSignature(bytes32,bytes)")
    } else {
      return 0xffffffff;
    }
  }

  /**
   * @dev Inspect whether a specific address has a specific role.
   */
  function hasRole (bytes32 role, address account) public view returns (bool) {
    return roles[role][account];
  }

  /* Modifiers */

  modifier onlyRole (bytes32 role) {
    if (roles[role][msg.sender] != true) revert MissingRole(role, msg.sender);
    _;
  }

  /* Administration */

  /**
   * @dev Allow current administrators to be able to grant/revoke admin role to other addresses.
   */
  function setAdmin (address account, bool isAdmin) public onlyRole(ADMIN_ROLE) {
    roles[ADMIN_ROLE][account] = isAdmin;
    emit RoleChange(ADMIN_ROLE, account, isAdmin, msg.sender);
  }

  /**
   * @dev Claim ENS reverse-resolver rights for this contract.
   * https://docs.ens.domains/contract-api-reference/reverseregistrar#claim-address
   */
  function setReverseResolver (address registrar) public onlyRole(ADMIN_ROLE) {
    IReverseResolver(registrar).claim(msg.sender);
  }

  /**
   * @dev Update address for on-chain documentation lookup.
   */
  function setDocumentationRepository (address documentationAddress) public onlyRole(ADMIN_ROLE) {
    DocumentationRepository = IDocumentationRepository(documentationAddress);
  }

  /**
   * @dev Set a message as valid, to be queried by ERC1271 clients.
   */
  function markMessageSigned (bytes32 hash, uint256 expirationLength) public onlyRole(ADMIN_ROLE) {
    validSignatures[hash] = block.number + expirationLength;
  }

  /**
   * @dev Rescue ERC20 assets sent directly to this contract.
   */
  function withdrawForeignERC20 (address tokenContract) public onlyRole(ADMIN_ROLE) {
    IERC20 token = IERC20(tokenContract);
    token.transfer(msg.sender, token.balanceOf(address(this)));
  }

  /**
   * @dev Rescue ERC721 assets sent directly to this contract.
   */
  function withdrawForeignERC721 (address tokenContract, uint256 tokenId)
    public
    virtual
    onlyRole(ADMIN_ROLE)
  {
    IERC721(tokenContract).safeTransferFrom(
      address(this),
      msg.sender,
      tokenId
    );
  }

  function withdrawEth () public onlyRole(ADMIN_ROLE) {
    payable(msg.sender).transfer(address(this).balance);
  }

}