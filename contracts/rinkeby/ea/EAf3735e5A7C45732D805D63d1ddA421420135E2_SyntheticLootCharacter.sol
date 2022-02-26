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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
/// @dev Note that balanceOf does not revert if passed the zero address, in defiance of the ERC.
abstract contract ERC721 {
    /*///////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /*///////////////////////////////////////////////////////////////
                          METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    function tokenURI(uint256 id) public view virtual returns (string memory);

    /*///////////////////////////////////////////////////////////////
                            ERC721 STORAGE                        
    //////////////////////////////////////////////////////////////*/

    mapping(address => uint256) public balanceOf;

    mapping(uint256 => address) public ownerOf;

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*///////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /*///////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) public virtual {
        address owner = ownerOf[id];

        require(msg.sender == owner || isApprovedForAll[owner][msg.sender], "NOT_AUTHORIZED");

        getApproved[id] = spender;

        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        require(from == ownerOf[id], "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from || msg.sender == getApproved[id] || isApprovedForAll[from][msg.sender],
            "NOT_AUTHORIZED"
        );

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            balanceOf[from]--;

            balanceOf[to]++;
        }

        ownerOf[id] = to;

        delete getApproved[id];

        emit Transfer(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes memory data
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    /*///////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public pure virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*///////////////////////////////////////////////////////////////
                       INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 id) internal virtual {
        require(to != address(0), "INVALID_RECIPIENT");

        require(ownerOf[id] == address(0), "ALREADY_MINTED");

        // Counter overflow is incredibly unrealistic.
        unchecked {
            balanceOf[to]++;
        }

        ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = ownerOf[id];

        require(ownerOf[id] != address(0), "NOT_MINTED");

        // Ownership check above ensures no underflow.
        unchecked {
            balanceOf[owner]--;
        }

        delete ownerOf[id];

        delete getApproved[id];

        emit Transfer(owner, address(0), id);
    }

    /*///////////////////////////////////////////////////////////////
                       INTERNAL SAFE MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    function _safeMint(address to, uint256 id) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _safeMint(
        address to,
        uint256 id,
        bytes memory data
    ) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
interface ERC721TokenReceiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 id,
        bytes calldata data
    ) external returns (bytes4);
}

//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import "./abstract/ClaimableSynthetic.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./external/SyntheticLoot.sol";

contract SyntheticLootCharacter is ClaimableSynthetic {

    using Strings for string;

    string[8] public renderOrder = [
        "weapon",
        "chest",
        "head",
        "waist",
        "foot",
        "hand",
        "neck",
        "ring"
    ];

    string public constant cid = "QmbcKUu71Jh64tuJ41fWaLj4XRSkp3umYfaRRpnbjMxeH3";

    SyntheticLoot syntheticLoot;
    string[] gateways;

    constructor (string memory _name, string memory _symbol, address _syntheticLootAddress, string[] memory _gateways) ERC721(_name, _symbol) {
        syntheticLoot = SyntheticLoot(_syntheticLootAddress);
        gateways = _gateways;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        address walletAddress = getAddress(tokenId);
        string memory gateway = gateways[block.number % gateways.length];
        

        // TODO: Render all components, only getting names for now
        uint[8] memory componentNames = getComponentFilenames(walletAddress);

        string memory svg = '<svg preserveAspectRatio="xMinYMin meet" viewBox="0 0 500 500" xmlns="http://www.w3.org/2000/svg">';

        svg = string.concat(svg, '<image width="500" href="', gateway, cid, '/bg.png', '"/>');
        svg = string.concat(svg, '<image width="500" href="', gateway, cid, '/fg.png', '"/>');

        for (uint256 i = 0; i < componentNames.length; i++) {
            string memory url = string.concat(gateway, cid, '/', renderOrder[i], '/name/', Strings.toString(componentNames[i]), '.png');
            string memory image = string.concat('<image width="500" href="', url, '"/>');
            svg = string.concat(svg, image);
        }

        svg = string.concat(svg, '</svg>');

        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "Bag 0x', toAsciiString(walletAddress), '", "description": "Loot is randomized adventurer gear generated and stored on chain. Stats, images, and other functionality are intentionally omitted for others to interpret. Feel free to use Loot in any way you want.", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(svg)), '"}'))));
        string memory output = string(abi.encodePacked('data:application/json;base64,', json));

        return output;
    }

    function getComponentFilenames(address walletAddress) public view returns (uint[8] memory) {
        // return [
        //     processName(syntheticLoot.getWeapon(walletAddress)),
        //     processName(syntheticLoot.getChest(walletAddress)),
        //     processName(syntheticLoot.getHead(walletAddress)),
        //     processName(syntheticLoot.getWaist(walletAddress)),
        //     processName(syntheticLoot.getFoot(walletAddress)),
        //     processName(syntheticLoot.getHand(walletAddress)),
        //     processName(syntheticLoot.getNeck(walletAddress)),
        //     processName(syntheticLoot.getRing(walletAddress))
        // ];
        return [
            syntheticLoot.weaponComponents(walletAddress)[0],
            syntheticLoot.chestComponents(walletAddress)[0],
            syntheticLoot.headComponents(walletAddress)[0],
            syntheticLoot.waistComponents(walletAddress)[0],
            syntheticLoot.footComponents(walletAddress)[0],
            syntheticLoot.handComponents(walletAddress)[0],
            syntheticLoot.neckComponents(walletAddress)[0],
            syntheticLoot.ringComponents(walletAddress)[0]
        ];
    }

    /*
    *   Utils
    */
    function processName(string memory _base) internal pure returns (string memory) {
        bytes memory base = bytes(_base);
        bytes memory out;
        for (uint256 i = 0; i < base.length; i++) {
            if (base[i] != 0x22) {
                out = bytes.concat(out, _lowerUnderscore(base[i]));
            }
        }
        return string(out);
    }

    function _lowerUnderscore(bytes1 _b1)
        private
        pure
        returns (bytes1) {

        if (_b1 == 0x20) {
            return bytes1(0x5f);
        }

        if (_b1 >= 0x41 && _b1 <= 0x5A) {
            return bytes1(uint8(_b1) + 32);
        }

        return _b1;
    }

    // https://ethereum.stackexchange.com/a/8447
    function toAsciiString(address x) internal pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint(uint160(x)) / (2**(8*(19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2*i] = char(hi);
            s[2*i+1] = char(lo);            
        }
        return string(s);
    }

    // https://ethereum.stackexchange.com/a/8447
    function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }

    
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.12;

import "@rari-capital/solmate/src/tokens/ERC721.sol";

abstract contract ClaimableSynthetic is ERC721 {

  uint256 public immutable claimPrice = 0.02 ether;
  // address public immutable withdrawAddress; // TODO: Withdrawal
  // address immutable ensReverseAddress;
  string public constant claimMessage = "Message to claim";
  mapping(address => bool) public claimed;

  function claim() public payable {
    require(msg.value >= claimPrice, "Insufficient payment");
    _safeMint(msg.sender, getTokenID(msg.sender));
    claimed[msg.sender] = true;
    uint256 refund = msg.value - claimPrice;
    if (refund > 0) {
      payable(msg.sender).transfer(refund);
    }
  }

  function claimOther(address _signer, bytes memory _signature) public payable {
    require(msg.value >= claimPrice, "Insufficient payment");
    require(verify(_signer, claimMessage, _signature), "Invalid signature");

    _safeMint(msg.sender, getTokenID(_signer));
    claimed[_signer] = true;
    uint256 refund = msg.value - claimPrice;
    if (refund > 0) {
      payable(_signer).transfer(refund);
    }
  }

  function _tokenURI(address _address) public view returns (string memory) {
      return tokenURI(getTokenID(_address));
  }

  function getTokenID(address _address) public pure returns (uint256) {
      return uint256(uint160(_address));
  }

  function getAddress(uint256 id) public pure returns (address) {
      return address(uint160(id));
  }

  // ECDSA

  function getMessageHash(
    string memory _message
  ) public pure returns (bytes32) {
    return keccak256(abi.encodePacked(_message));
  }

  function getEthSignedMessageHash(bytes32 _messageHash)
    public
    pure 
    returns (bytes32)
  {
    return
      keccak256(
        abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash)
      );
  }

  function verify(
    address _signer,
    string memory _message,
    bytes memory signature
  ) public pure returns (bool) {
    bytes32 messageHash = getMessageHash(_message);
    bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

    return recoverSigner(ethSignedMessageHash, signature) == _signer;
  }

  function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature)
    public
    pure
    returns (address)
  {
    (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

    return ecrecover(_ethSignedMessageHash, v, r, s);
  }

  function splitSignature(bytes memory sig)
    public
    pure
    returns (
        bytes32 r,
        bytes32 s,
        uint8 v
    )
  {
    require(sig.length == 65, "invalid signature length");

    assembly {
      // first 32 bytes, after the length prefix
      r := mload(add(sig, 32))
      // second 32 bytes
      s := mload(add(sig, 64))
      // final byte (first byte of the next 32 bytes)
      v := byte(0, mload(add(sig, 96)))
    }
  }
}

/**
 *Submitted for verification at Etherscan.io on 2021-09-01
*/

// SPDX-License-Identifier: GPL-3.0

/*

    Synthetic Loot
    
    This contract creates a "virtual NFT" of Loot based
    on a given wallet address. 
    
    Because the wallet address is used as the deterministic 
    seed, there can only be one Loot bag per wallet. 
    
    Because it's not a real NFT, there is no 
    minting, transferability, etc.
    
    Creators building on top of Loot can choose to recognize 
    Synthetic Loot as a way to allow a wider range of 
    adventurers to participate in the ecosystem, while
    still being able to differentiate between 
    "original" Loot and Synthetic Loot.
    
    Anyone with an Ethereum wallet has Synthetic Loot.
    
    -----
    
    Also optionally returns data in LootComponents format:
    
    Call weaponComponents(), chestComponents(), etc. to get 
    an array of attributes that correspond to the item. 
    
    The return format is:
    
    uint256[5] =>
        [0] = Item ID
        [1] = Suffix ID (0 for none)
        [2] = Name Prefix ID (0 for none)
        [3] = Name Suffix ID (0 for none)
        [4] = Augmentation (0 = false, 1 = true)
    
    See the item and attribute tables below for corresponding IDs.
    
    The original LootComponents contract is at address:
    0x3eb43b1545a360d1D065CB7539339363dFD445F3

*/

pragma solidity ^0.8.4;

contract SyntheticLoot {

    string[] private weapons = [
        "Warhammer",            // 0
        "Quarterstaff",         // 1
        "Maul",                 // 2
        "Mace",                 // 3
        "Club",                 // 4
        "Katana",               // 5
        "Falchion",             // 6
        "Scimitar",             // 7
        "Long Sword",           // 8
        "Short Sword",          // 9
        "Ghost Wand",           // 10
        "Grave Wand",           // 11
        "Bone Wand",            // 12
        "Wand",                 // 13
        "Grimoire",             // 14
        "Chronicle",            // 15
        "Tome",                 // 16
        "Book"                  // 17
    ];
    
    string[] private chestArmor = [
        "Divine Robe",          // 0
        "Silk Robe",            // 1
        "Linen Robe",           // 2
        "Robe",                 // 3
        "Shirt",                // 4
        "Demon Husk",           // 5
        "Dragonskin Armor",     // 6
        "Studded Leather Armor",// 7
        "Hard Leather Armor",   // 8
        "Leather Armor",        // 9
        "Holy Chestplate",      // 10
        "Ornate Chestplate",    // 11
        "Plate Mail",           // 12
        "Chain Mail",           // 13
        "Ring Mail"             // 14
    ];
    
    string[] private headArmor = [
        "Ancient Helm",         // 0
        "Ornate Helm",          // 1
        "Great Helm",           // 2
        "Full Helm",            // 3
        "Helm",                 // 4
        "Demon Crown",          // 5
        "Dragon's Crown",       // 6
        "War Cap",              // 7
        "Leather Cap",          // 8
        "Cap",                  // 9
        "Crown",                // 10
        "Divine Hood",          // 11
        "Silk Hood",            // 12
        "Linen Hood",           // 13
        "Hood"                  // 14
    ];
    
    string[] private waistArmor = [
        "Ornate Belt",          // 0
        "War Belt",             // 1
        "Plated Belt",          // 2
        "Mesh Belt",            // 3
        "Heavy Belt",           // 4
        "Demonhide Belt",       // 5
        "Dragonskin Belt",      // 6
        "Studded Leather Belt", // 7
        "Hard Leather Belt",    // 8
        "Leather Belt",         // 9
        "Brightsilk Sash",      // 10
        "Silk Sash",            // 11
        "Wool Sash",            // 12
        "Linen Sash",           // 13
        "Sash"                  // 14
    ];
    
    string[] private footArmor = [
        "Holy Greaves",         // 0
        "Ornate Greaves",       // 1
        "Greaves",              // 2
        "Chain Boots",          // 3
        "Heavy Boots",          // 4
        "Demonhide Boots",      // 5
        "Dragonskin Boots",     // 6
        "Studded Leather Boots",// 7
        "Hard Leather Boots",   // 8
        "Leather Boots",        // 9
        "Divine Slippers",      // 10
        "Silk Slippers",        // 11
        "Wool Shoes",           // 12
        "Linen Shoes",          // 13
        "Shoes"                 // 14
    ];
    
    string[] private handArmor = [
        "Holy Gauntlets",       // 0
        "Ornate Gauntlets",     // 1
        "Gauntlets",            // 2
        "Chain Gloves",         // 3
        "Heavy Gloves",         // 4
        "Demon's Hands",        // 5
        "Dragonskin Gloves",    // 6
        "Studded Leather Gloves",// 7
        "Hard Leather Gloves",  // 8
        "Leather Gloves",       // 9
        "Divine Gloves",        // 10
        "Silk Gloves",          // 11
        "Wool Gloves",          // 12
        "Linen Gloves",         // 13
        "Gloves"                // 14
    ];
    
    string[] private necklaces = [
        "Necklace",             // 0
        "Amulet",               // 1
        "Pendant"               // 2
    ];
    
    string[] private rings = [
        "Gold Ring",            // 0
        "Silver Ring",          // 1
        "Bronze Ring",          // 2
        "Platinum Ring",        // 3
        "Titanium Ring"         // 4
    ];
    
    string[] private suffixes = [
        // <no suffix>          // 0
        "of Power",             // 1
        "of Giants",            // 2
        "of Titans",            // 3
        "of Skill",             // 4
        "of Perfection",        // 5
        "of Brilliance",        // 6
        "of Enlightenment",     // 7
        "of Protection",        // 8
        "of Anger",             // 9
        "of Rage",              // 10
        "of Fury",              // 11
        "of Vitriol",           // 12
        "of the Fox",           // 13
        "of Detection",         // 14
        "of Reflection",        // 15
        "of the Twins"          // 16
    ];
    
    string[] private namePrefixes = [
        // <no name>            // 0
        "Agony",                // 1
        "Apocalypse",           // 2
        "Armageddon",           // 3
        "Beast",                // 4
        "Behemoth",             // 5
        "Blight",               // 6
        "Blood",                // 7
        "Bramble",              // 8
        "Brimstone",            // 9
        "Brood",                // 10
        "Carrion",              // 11
        "Cataclysm",            // 12
        "Chimeric",             // 13
        "Corpse",               // 14
        "Corruption",           // 15
        "Damnation",            // 16
        "Death",                // 17
        "Demon",                // 18
        "Dire",                 // 19
        "Dragon",               // 20
        "Dread",                // 21
        "Doom",                 // 22
        "Dusk",                 // 23
        "Eagle",                // 24
        "Empyrean",             // 25
        "Fate",                 // 26
        "Foe",                  // 27
        "Gale",                 // 28
        "Ghoul",                // 29
        "Gloom",                // 30
        "Glyph",                // 31
        "Golem",                // 32
        "Grim",                 // 33
        "Hate",                 // 34
        "Havoc",                // 35
        "Honour",               // 36
        "Horror",               // 37
        "Hypnotic",             // 38
        "Kraken",               // 39
        "Loath",                // 40
        "Maelstrom",            // 41
        "Mind",                 // 42
        "Miracle",              // 43
        "Morbid",               // 44
        "Oblivion",             // 45
        "Onslaught",            // 46
        "Pain",                 // 47
        "Pandemonium",          // 48
        "Phoenix",              // 49
        "Plague",               // 50
        "Rage",                 // 51
        "Rapture",              // 52
        "Rune",                 // 53
        "Skull",                // 54
        "Sol",                  // 55
        "Soul",                 // 56
        "Sorrow",               // 57
        "Spirit",               // 58
        "Storm",                // 59
        "Tempest",              // 60
        "Torment",              // 61
        "Vengeance",            // 62
        "Victory",              // 63
        "Viper",                // 64
        "Vortex",               // 65
        "Woe",                  // 66
        "Wrath",                // 67
        "Light's",              // 68
        "Shimmering"            // 69  
    ];
    
    string[] private nameSuffixes = [
        // <no name>            // 0
        "Bane",                 // 1
        "Root",                 // 2
        "Bite",                 // 3
        "Song",                 // 4
        "Roar",                 // 5
        "Grasp",                // 6
        "Instrument",           // 7
        "Glow",                 // 8
        "Bender",               // 9
        "Shadow",               // 10
        "Whisper",              // 11
        "Shout",                // 12
        "Growl",                // 13
        "Tear",                 // 14
        "Peak",                 // 15
        "Form",                 // 16
        "Sun",                  // 17
        "Moon"                  // 18
    ];
    
    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }
    
    function weaponComponents(address walletAddress) public view returns (uint256[5] memory) {
        return pluck(walletAddress, "WEAPON", weapons);
    }
    
    function chestComponents(address walletAddress) public view returns (uint256[5] memory) {
        return pluck(walletAddress, "CHEST", chestArmor);
    }
    
    function headComponents(address walletAddress) public view returns (uint256[5] memory) {
        return pluck(walletAddress, "HEAD", headArmor);
    }
    
    function waistComponents(address walletAddress) public view returns (uint256[5] memory) {
        return pluck(walletAddress, "WAIST", waistArmor);
    }

    function footComponents(address walletAddress) public view returns (uint256[5] memory) {
        return pluck(walletAddress, "FOOT", footArmor);
    }
    
    function handComponents(address walletAddress) public view returns (uint256[5] memory) {
        return pluck(walletAddress, "HAND", handArmor);
    }
    
    function neckComponents(address walletAddress) public view returns (uint256[5] memory) {
        return pluck(walletAddress, "NECK", necklaces);
    }
    
    function ringComponents(address walletAddress) public view returns (uint256[5] memory) {
        return pluck(walletAddress, "RING", rings);
    }
    
    function getWeapon(address walletAddress) public view returns (string memory) {
        return pluckName(walletAddress, "WEAPON", weapons);
    }
    
    function getChest(address walletAddress) public view returns (string memory) {
        return pluckName(walletAddress, "CHEST", chestArmor);
    }
    
    function getHead(address walletAddress) public view returns (string memory) {
        return pluckName(walletAddress, "HEAD", headArmor);
    }
    
    function getWaist(address walletAddress) public view returns (string memory) {
        return pluckName(walletAddress, "WAIST", waistArmor);
    }

    function getFoot(address walletAddress) public view returns (string memory) {
        return pluckName(walletAddress, "FOOT", footArmor);
    }
    
    function getHand(address walletAddress) public view returns (string memory) {
        return pluckName(walletAddress, "HAND", handArmor);
    }
    
    function getNeck(address walletAddress) public view returns (string memory) {
        return pluckName(walletAddress, "NECK", necklaces);
    }
    
    function getRing(address walletAddress) public view returns (string memory) {
        return pluckName(walletAddress, "RING", rings);
    }
    
    function pluckName(address walletAddress, string memory keyPrefix, string[] memory sourceArray) internal view returns (string memory) {
        uint256 rand = random(string(abi.encodePacked(keyPrefix, abi.encodePacked(walletAddress))));
        string memory output = sourceArray[rand % sourceArray.length];
        uint256 greatness = rand % 21;
        if (greatness > 14) {
            output = string(abi.encodePacked(output, " ", suffixes[rand % suffixes.length]));
        }
        if (greatness >= 19) {
            string[2] memory name;
            name[0] = namePrefixes[rand % namePrefixes.length];
            name[1] = nameSuffixes[rand % nameSuffixes.length];
            if (greatness == 19) {
                output = string(abi.encodePacked('"', name[0], ' ', name[1], '" ', output));
            } else {
                output = string(abi.encodePacked('"', name[0], ' ', name[1], '" ', output, " +1"));
            }
        }
        return output;
    }

    function pluck(address walletAddress, string memory keyPrefix, string[] memory sourceArray) internal view returns (uint256[5] memory) {
        uint256[5] memory components;
        
        uint256 rand = random(string(abi.encodePacked(keyPrefix, abi.encodePacked(walletAddress))));
        
        components[0] = rand % sourceArray.length;
        components[1] = 0;
        components[2] = 0;
        
        uint256 greatness = rand % 21;
        if (greatness > 14) {
            components[1] = (rand % suffixes.length) + 1;
        }
        if (greatness >= 19) {
            components[2] = (rand % namePrefixes.length) + 1;
            components[3] = (rand % nameSuffixes.length) + 1;
            if (greatness == 19) {
                // ...
            } else {
                components[4] = 1;
            }
        }
        return components;
    }
    
    function tokenURI(address walletAddress) public view returns (string memory) {
        string[17] memory parts;
        parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" /><text x="10" y="20" class="base">';

        parts[1] = getWeapon(walletAddress);

        parts[2] = '</text><text x="10" y="40" class="base">';

        parts[3] = getChest(walletAddress);

        parts[4] = '</text><text x="10" y="60" class="base">';

        parts[5] = getHead(walletAddress);

        parts[6] = '</text><text x="10" y="80" class="base">';

        parts[7] = getWaist(walletAddress);

        parts[8] = '</text><text x="10" y="100" class="base">';

        parts[9] = getFoot(walletAddress);

        parts[10] = '</text><text x="10" y="120" class="base">';

        parts[11] = getHand(walletAddress);

        parts[12] = '</text><text x="10" y="140" class="base">';

        parts[13] = getNeck(walletAddress);

        parts[14] = '</text><text x="10" y="160" class="base">';

        parts[15] = getRing(walletAddress);

        parts[16] = '</text></svg>';

        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7], parts[8]));
        output = string(abi.encodePacked(output, parts[9], parts[10], parts[11], parts[12], parts[13], parts[14], parts[15], parts[16]));
        
        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "Bag 0x', toAsciiString(walletAddress), '", "description": "Loot is randomized adventurer gear generated and stored on chain. Stats, images, and other functionality are intentionally omitted for others to interpret. Feel free to use Loot in any way you want.", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))));
        output = string(abi.encodePacked('data:application/json;base64,', json));

        return output;
    }
    
    // https://ethereum.stackexchange.com/a/8447
    function toAsciiString(address x) internal pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint(uint160(x)) / (2**(8*(19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2*i] = char(hi);
            s[2*i+1] = char(lo);            
        }
        return string(s);
    }
    
    // https://ethereum.stackexchange.com/a/8447
    function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }
}

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

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
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
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