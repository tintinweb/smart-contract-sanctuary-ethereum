// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Strings.sol";

import "./IWc3Decorator.sol";

/// @title Decorator contract providing metadata content for Witty Creatures v3
/// @author Otherplane Labs, 2022.
contract Wc3Decorator is IWc3Decorator, Ownable {

    using Strings for uint256;
    using Wc3Lib for bytes32;
    using Wc3Lib for string;
    using Wc3Lib for Wc3Lib.WittyCreatureRarity;

    uint256 public constant TRAITS_MAX_SPREAD_RANK = 31;

    string internal constant _TRAITS_DEFAULT_BACKGROUND = "Plain";
    string internal constant _TRAITS_DEFAULT_EYES = "Default";
    string internal constant _TRAITS_DEFAULT_HEAD = "Default";
    string internal constant _TRAITS_DEFAULT_MOUTH = "Default";
    string internal constant _TRAITS_DEFAULT_OBJECT = "None";
    string internal constant _TRAITS_DEFAULT_OUTFIT = "Default";    

    bytes32 internal immutable __version;

    string public override baseURI;
    bool public override forged;
    uint256 public override immutable guildId;
    TraitRanges public ranges;

    mapping (uint256 => string) public backgrounds;
    mapping (uint256 => string) public colors;
    mapping (uint256 => string) public eyes;
    mapping (uint256 => string) public guilds;
    mapping (uint256 => string) public heads;
    mapping (uint256 => string) public mouths;
    mapping (uint256 => string) public objects;
    mapping (uint256 => string) public outfits;

    struct TraitRanges {
        uint16 totalBackgrounds;
        uint16 totalColors;
        uint16 totalEyes;
        uint16 totalHeads;
        uint16 totalMouths;
        uint16 totalObjects;
        uint16 totalOutfits;        
    }

    modifier checkRange(string[] memory _tags) {
        require(
            _tags.length <= TRAITS_MAX_SPREAD_RANK,
            "Wc3Decorator: out of range"
        );
        _;
    }

    modifier isForged {
        require(forged, "Wc3Decorator: not forged");
        _;
    }

    modifier notForged {
        require(!forged, "Wc3Decorator: already forged");
        _;
    }

    constructor(
        string memory _version,
        string memory _baseURI,
        string memory _chainName
    ) {
        __version = _version.toBytes32();
        setBaseURI(_baseURI);
        setGuildTag(block.chainid, _chainName);
        guildId = block.chainid;
    }

    function version()
        external view
        override
        returns (string memory)
    {
        return __version.toString();
    }

    function forge()
        external virtual
        notForged
        onlyOwner
    {
        require(ranges.totalBackgrounds > 0, "Wc3Decorator: no backgrounds");
        require(ranges.totalColors > 0, "Wc3Decorator: no colors");
        require(ranges.totalEyes > 0, "Wc3Decorator: no eyes");
        require(ranges.totalHeads > 0, "Wc3Decorator: no heads");
        require(ranges.totalMouths > 0, "Wc3Decorator: no mouths");
        require(ranges.totalObjects > 0, "Wc3Decorator: no objects");
        require(ranges.totalOutfits > 0, "Wc3Decorator: no outfits");
        require(
            bytes(guilds[block.chainid]).length > 0,
            "Wc3Decorator: guild name not set"
        );
        forged = true;
    }

    function getBackgrounds()
        public view
        virtual
        returns (string[] memory _tags)
    {
        _tags = new string[](ranges.totalBackgrounds);
        for (uint _i = 0; _i < _tags.length; _i ++) {
            _tags[_i] = backgrounds[_i];
        }
    }

    function getColors()
        public view
        virtual
        returns (string[] memory _tags)
    {
        _tags = new string[](ranges.totalColors);
        for (uint _i = 0; _i < _tags.length; _i ++) {
            _tags[_i] = colors[_i];
        }
    }

    function getEyes()
        public view
        virtual
        returns (string[] memory _tags)
    {
        _tags = new string[](ranges.totalEyes);
        for (uint _i = 0; _i < _tags.length; _i ++) {
            _tags[_i] = eyes[_i];
        }
    }

    function getGuildName()
        public view
        virtual
        returns (string memory)
    {
        return guilds[block.chainid];
    }

    function getHeads()
        public view
        virtual
        returns (string[] memory _tags)
    {
        _tags = new string[](ranges.totalHeads);
        for (uint _i = 0; _i < _tags.length; _i ++) {
            _tags[_i] = heads[_i];
        }
    }

    function getMouths()
        public view
        virtual
        returns (string[] memory _tags)
    {
        _tags = new string[](ranges.totalMouths);
        for (uint _i = 0; _i < _tags.length; _i ++) {
            _tags[_i] = mouths[_i];
        }
    }
    
    function getObjects()
        public view
        virtual
        returns (string[] memory _tags)
    {
        _tags = new string[](ranges.totalObjects);
        for (uint _i = 0; _i < _tags.length; _i ++) {
            _tags[_i] = objects[_i];
        }
    }

    function getOutfits()
        public view
        virtual
        returns (string[] memory _tags)
    {
        _tags = new string[](ranges.totalOutfits);
        for (uint _i = 0; _i < _tags.length; _i ++) {
            _tags[_i] = outfits[_i];
        }
    }

    function setBaseURI(string memory _baseURI)
        public virtual
        onlyOwner
    {
        bytes memory _rawURI = bytes(_baseURI);
        require(
            _rawURI.length > 0,
            "Wc3Decorator: empty URI"
        );
        require(
            _rawURI[_rawURI.length - 1] == "/",
            "Wc3Decorator: no trailing slash"
        );
        baseURI = _baseURI;  
    }

    // backgrounds
    function setBackgrounds(string[] memory _tags)
        public virtual
        notForged
        onlyOwner
        checkRange(_tags)
    {
        uint16 _total;
        for (uint _i = 0; _i < _tags.length; _i ++) {
            if (bytes(_tags[_i]).length > 0) {
                backgrounds[_i] = _tags[_i];
                _total ++;
            }
        }
        ranges.totalBackgrounds = _total;
    }

    // colors
    function setColors(string[] memory _tags)
        public virtual
        notForged
        onlyOwner
        checkRange(_tags)
    {
        uint16 _total;
        for (uint _i = 0; _i < _tags.length; _i ++) {
            if (bytes(_tags[_i]).length > 0) {
                colors[_i] = _tags[_i];
                _total ++;
            }
        }
        ranges.totalColors = _total;
    }

    // eyes
    function setEyes(string[] memory _tags)
        public virtual
        notForged
        onlyOwner
        checkRange(_tags)
    {
        uint16 _total;
        for (uint _i = 0; _i < _tags.length; _i ++) {
            if (bytes(_tags[_i]).length > 0) {
                eyes[_i] = _tags[_i];
                _total ++;
            }
        }
        ranges.totalEyes = _total;
    }

    // guild
    function setGuildTag(uint _index, string memory _tag)
        public virtual
        notForged
        onlyOwner
    {
        guilds[_index] = _tag;
    }

    // heads
    function setHeads(string[] memory _tags)
        public virtual
        notForged
        onlyOwner
        checkRange(_tags)
    {
        uint16 _total;
        for (uint _i = 0; _i < _tags.length; _i ++) {
            if (bytes(_tags[_i]).length > 0) {
                heads[_i] = _tags[_i];
                _total ++;
            }
        }
        ranges.totalHeads = _total;
    }

    // mouths
    function setMouths(string[] memory _tags)
        public virtual
        notForged
        onlyOwner
        checkRange(_tags)
    {
        uint16 _total;
        for (uint _i = 0; _i < _tags.length; _i ++) {
            if (bytes(_tags[_i]).length > 0) {
                mouths[_i] = _tags[_i];
                _total ++;
            }
        }
        ranges.totalMouths = _total;
    }

    // objects
    function setObjects(string[] memory _tags)
        public virtual
        notForged
        onlyOwner
        checkRange(_tags)
    {
        uint16 _total;
        for (uint _i = 0; _i < _tags.length; _i ++) {
            if (bytes(_tags[_i]).length > 0) {
                objects[_i] = _tags[_i];
                _total ++;
            }
        }
        ranges.totalObjects = _total;
    }

    // outfits
    function setOutfits(string[] memory _tags)
        public virtual
        notForged
        onlyOwner
        checkRange(_tags)
    {
        uint16 _total;
        for (uint _i = 0; _i < _tags.length; _i ++) {
            if (bytes(_tags[_i]).length > 0) {
                outfits[_i] = _tags[_i];
                _total ++;
            }
        }
        ranges.totalOutfits = _total;
    }

    function randomTraits(
            bytes32 _randomness,
            uint256 _eggIndex
        )
        external view
        override
        returns (Wc3Lib.WittyCreatureTraits memory)
    {
        return _splitRandomPhenotype(_randomness, _eggIndex);
    }

    function toJSON(
            bytes32 _randomness,
            Wc3Lib.WittyCreature memory _intrinsics
        )
        external view
        virtual override
        returns (string memory _json)
    {
        Wc3Lib.WittyCreatureTraits memory _traits = _splitRandomPhenotype(
            _randomness,
            _intrinsics.eggIndex
        );
        
        string memory _guildIdStr = block.chainid.toString();
        string memory _tokenIdStr = _intrinsics.eggGuildRanking.toString();
        string memory _baseURI = baseURI;

        string memory _name = string(abi.encodePacked(
            "\"name\": \"", _intrinsics.eggName, "\","
        ));
        string memory _description = string(abi.encodePacked(
            "\"description\": \"Witty Creature #",
                (_intrinsics.eggIndex + 1).toString(),
            " at EthCC[5] Paris, July 19-21, 2022."
            " The [Witnet multi-chain decentralized oracle](https://witnet.io) was used"
            " for both generating randomness and retrieving the last known [USD price at the moment this token"
            " got minted](https://witnet.network/search/",
                _intrinsics.mintUsdPriceWitnetProof.toHexString(), 
            ").\","
        ));
        string memory _externalUrl = string(abi.encodePacked(
            "\"external_url\": \"", _baseURI, "metadata/", _guildIdStr, "/", _tokenIdStr, "\","
        ));
        string memory _image = string(abi.encodePacked(
            "\"image\": \"", _baseURI, "image/", _guildIdStr, "/", _tokenIdStr, "\","
        ));
        string memory _attributes = string(abi.encodePacked(
            "\"attributes\": [",
                _loadAttributes(
                    _randomness,
                    _intrinsics,
                    _traits
                ),
            "]"
        ));
        return string(abi.encodePacked(
            "{", _name, _description, _externalUrl, _image, _attributes, "}"
        ));
    }

    function _loadAttributes(
            bytes32 _randomness,
            Wc3Lib.WittyCreature memory _intrinsics,
            Wc3Lib.WittyCreatureTraits memory _traits
        )
        internal view
        returns (string memory)
    {
        string memory _witnetRandomness = string(abi.encodePacked(
            "{", 
                "\"trait_type\": \"Witnet Randomness\",",
                "\"value\": \"0x", (
                    _randomness.toHexString()
                ), "\""
            "},"
        ));
        return string(abi.encodePacked(
            _witnetRandomness,
            _loadAttributesIntrinsics(_intrinsics),
            _loadAttributesRandomized(_intrinsics.eggRarity, _traits)
        ));        
    }

    function _loadAttributesIntrinsics(Wc3Lib.WittyCreature memory _intrinsics)
        internal view
        returns (string memory)
    {
        string memory _birthDate = string(abi.encodePacked(
            "{",
                "\"display_type\": \"date\",",
                "\"trait_type\": \"Birth date\",",
                "\"value\": ", _intrinsics.mintTimestamp.toString(),
            "},"
        ));
        string memory _eggColor = string(abi.encodePacked(
            "{",
                "\"trait_type\": \"Egg color\",",
                "\"value\": \"", (
                    colors[_intrinsics.eggIndex % ranges.totalColors]
                ), "\""
            "},"
        ));
        string memory _eggRarity = string(abi.encodePacked(
            "{", 
                "\"trait_type\": \"Egg rarity\",",
                "\"value\": \"", (
                    _intrinsics.eggRarity.toString()
                ), "\""
            "},"
        ));
        string memory _eggScore = string(abi.encodePacked(
            "{", 
                "\"trait_type\": \"Egg score\",",
                "\"value\": ", _intrinsics.eggScore.toString(),
            "},"
        ));
        string memory _globalRanking = string(abi.encodePacked(
            "{",
                "\"display_type\": \"number\",",
                "\"trait_type\": \"Global ranking\",",
                "\"value\": ", _intrinsics.eggGlobalRanking.toString(),
            "},"
        ));
        string memory _guild = string(abi.encodePacked(
            "{", 
                "\"trait_type\": \"Guild\",",
                "\"value\": \"", (
                    guilds[block.chainid]
                ), "\""
            "},"
        ));
        string memory _guildRanking = string(abi.encodePacked(
            "{",
                "\"display_type\": \"number\",",
                "\"trait_type\": \"Guild ranking\",",
                "\"value\": ", _intrinsics.eggGuildRanking.toString(),
            "},"
        ));
        string memory _mintGasPrice = string(abi.encodePacked(
            "{", 
                "\"trait_type\": \"Mint gas price (gwei)\",",
                "\"value\": ", _toStringDecimals2(_intrinsics.mintGasPrice / 10 ** 3),
            "},"
        ));
        string memory _mintUsdCost = string(abi.encodePacked(
            "{", 
                "\"trait_type\": \"Mint cost (USD)\",",
                "\"value\": ", _toStringDecimals2(_intrinsics.mintUsdCost6),
            "},"
        ));
        return string(abi.encodePacked(
            _birthDate,
            _eggColor,
            _eggRarity,
            _eggScore,
            _globalRanking,
            _guild,
            _guildRanking,
            _mintGasPrice,
            _mintUsdCost
        ));
    }

    function _loadAttributesRandomized(
            Wc3Lib.WittyCreatureRarity _rarity,
            Wc3Lib.WittyCreatureTraits memory _traits
        )
        internal view
        returns (string memory)
    {
        string memory _background = string(abi.encodePacked(
            "{",
                "\"trait_type\": \"Background\",",
                "\"value\": \"", (
                    _rarity != Wc3Lib.WittyCreatureRarity.Legendary
                        || bytes(backgrounds[_traits.background]).length == 0
                    ? _TRAITS_DEFAULT_BACKGROUND
                    : backgrounds[_traits.background]
                ), "\""
            "},"
        ));
        string memory _eyes = string(abi.encodePacked(
            "{",
                "\"trait_type\": \"Eyes\",",
                "\"value\": \"", (
                    bytes(eyes[_traits.eyes]).length == 0
                        ? _TRAITS_DEFAULT_EYES
                        : eyes[_traits.eyes]
                ), "\""
            "},"
        ));
        string memory _head = string(abi.encodePacked(
            "{",
                "\"trait_type\": \"Head\",",
                "\"value\": \"", (
                    bytes(heads[_traits.head]).length == 0
                        ? _TRAITS_DEFAULT_HEAD
                        : heads[_traits.head]
                ), "\""
            "},"
        ));
        string memory _mouth = string(abi.encodePacked(
            "{",
                "\"trait_type\": \"Mouth\",",
                "\"value\": \"", (
                    bytes(mouths[_traits.mouth]).length == 0
                        ? _TRAITS_DEFAULT_MOUTH
                        : mouths[_traits.mouth]
                ), "\""
            "},"
        ));
        string memory _object = string(abi.encodePacked(
            "{",
                "\"trait_type\": \"Object\",",
                "\"value\": \"", (
                    _rarity == Wc3Lib.WittyCreatureRarity.Common 
                        || bytes(objects[_traits.object]).length == 0
                    ? _TRAITS_DEFAULT_OBJECT
                    : objects[_traits.object]
                ), "\""
            "},"
        ));
        string memory _outfit = string(abi.encodePacked(
            "{",
                "\"trait_type\": \"Outfit\",",
                "\"value\": \"", (
                    bytes(outfits[_traits.outfit]).length == 0
                        ? _TRAITS_DEFAULT_OUTFIT
                        : outfits[_traits.outfit]
                ), "\""
            "}"
        ));
        return string(abi.encodePacked(
            _background,
            _eyes,
            _head,
            _mouth,
            _object,
            _outfit
        ));
    }

    function _splitRandomPhenotype(
            bytes32 _randomness,
            uint256 _eggIndex
        )
        internal view
        returns (Wc3Lib.WittyCreatureTraits memory _traits)
    {
        bytes32 _phenotype = keccak256(abi.encodePacked(
            _randomness,
            _eggIndex
        ));
        uint _nonce;
        _traits.background = _phenotype.randomUint8(_nonce ++, ranges.totalBackgrounds);
        _traits.eyes = _phenotype.randomUint8(_nonce ++, ranges.totalEyes * 2);
        _traits.head = _phenotype.randomUint8(_nonce ++, ranges.totalHeads + 1);
        _traits.object = _phenotype.randomUint8(_nonce ++, ranges.totalObjects);
        _traits.outfit = _phenotype.randomUint8(_nonce ++, ranges.totalOutfits * 2);
        _traits.mouth = _phenotype.randomUint8(_nonce ++, ranges.totalMouths * 2);
    }

    function _toStringDecimals2(uint256 _decimals6)
        internal pure
        returns (string memory _str)
    {
        uint256 _integer = _decimals6 / 10 ** 6;
        uint256 _fraction2 = (_decimals6 - _integer * 10 ** 6) / 10 ** 4;
        return string(abi.encodePacked(
            _integer.toString(),
            ".",
            _fraction2.toString()
        ));
    }

}