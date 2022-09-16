// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "base64-sol/base64.sol";
import {IBrawlerBearzRenderer} from "./interfaces/IBrawlerBearzRenderer.sol";
import {IBrawlerBearzDynamicItems} from "./interfaces/IBrawlerBearzDynamicItems.sol";
import {Genes} from "./Genes.sol";

/*******************************************************************************
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@|(@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@|,|@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&@@@@@@@@@@@|,*|&@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%,**%@@@@@@@@%|******%&@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&##*****|||**,(%%%%%**|%@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@***,#%%%%**#&@@@@@#**,|@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@*,(@@@@@@@@@@**,(&@@@@#**%@@@@@@||(%@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@%|,****&@((@&***&@@@@@@%||||||||#%&@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@&%#*****||||||**#%&@%%||||||||#@&%#(@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@&**,(&@@@@@%|||||*##&&&&##|||||(%@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@**,%@@@@@@@(|*|#%@@@@@@@@#||#%%@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@#||||#@@@@||*|%@@@@@@@@&|||%%&@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@#,,,,,,*|**||%|||||||###&@@@@@@@#|||#%@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@&#||*|||||%%%@%%%#|||%@@@@@@@@&(|(%&@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@&&%%(||||@@@@@@&|||||(%&((||(#%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@%%(||||||||||#%#(|||||%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@&%#######%%@@**||(#%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%##%%&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
********************************************************************************/

/**************************************************
 * @title BrawlerBearzRenderer
 * @author @ScottMitchell18
 **************************************************/

contract BrawlerBearzRenderer is IBrawlerBearzRenderer, Ownable {
    using Strings for uint256;
    using Genes for uint256;

    uint256 constant STR_BASIS = 100;
    uint256 constant END_BASIS = 100;
    uint256 constant INT_BASIS = 100;
    uint256 constant LCK_BASIS = 10;
    uint256 constant XP_BASIS = 2000;

    /// @notice Base URI for assets
    string public baseURI;

    /// @notice Animation URI for assets
    string public animationURI;

    /// @notice Vendor contract
    IBrawlerBearzDynamicItems public vendorContract;

    constructor(string memory _baseURI, string memory _animationURI) {
        baseURI = _baseURI;
        animationURI = _animationURI;
    }

    function toJSONProperty(string memory key, string memory value)
        public
        pure
        returns (string memory)
    {
        return string(abi.encodePacked('"', key, '" : "', value, '"'));
    }

    function toJSONNumberAttribute(string memory key, string memory value)
        public
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    '{ "trait_type":"',
                    key,
                    '", "value": "',
                    value,
                    '", "display_type": "number"',
                    "}"
                )
            );
    }

    function toJSONAttribute(string memory key, string memory value)
        public
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    '{ "trait_type":"',
                    key,
                    '", "value": "',
                    value,
                    '"}'
                )
            );
    }

    function toJSONAttributeList(string[] memory attributes)
        internal
        pure
        returns (string memory)
    {
        bytes memory attributeListBytes = "[";
        for (uint256 i = 0; i < attributes.length; i++) {
            attributeListBytes = abi.encodePacked(
                attributeListBytes,
                attributes[i],
                i != attributes.length - 1 ? "," : "]"
            );
        }
        return string(attributeListBytes);
    }

    function gaussianTrait(
        uint256 seed,
        uint256 numSampling,
        uint256 samplingBits
    ) internal pure returns (uint256 trait) {
        uint256 samplingMask = (1 << samplingBits) - 1;
        unchecked {
            for (uint256 i = 0; i < numSampling; i++) {
                trait += (seed >> (i * samplingBits)) & samplingMask;
            }
        }
    }

    function factionIdToName(uint256 factionId)
        internal
        pure
        returns (string memory)
    {
        if (factionId == 1) {
            return "IRONBEARZ";
        } else if (factionId == 2) {
            return "GEOSCAPEZ";
        } else if (factionId == 3) {
            return "PAWPUNKZ";
        } else if (factionId == 4) {
            return "TECHHEADZ";
        } else {
            return "NOMAD";
        }
    }

    function getHiddenProperties(uint256 tokenId)
        internal
        view
        returns (Bear memory)
    {
        Traits memory traits;
        CustomMetadata memory dynamic;
        return
            Bear({
                name: string(
                    abi.encodePacked("Brawler #", Strings.toString(tokenId))
                ),
                description: "Fight or die. This is the life of the brawlers...",
                dna: "hidden",
                traits: traits,
                dynamic: dynamic
            });
    }

    function getProperties(
        uint256 tokenId,
        uint256 seed,
        CustomMetadata memory md
    ) internal view returns (Bear memory) {
        uint256 chromosome = Genes.seedToChromosome(seed);

        Traits memory traits;
        CustomMetadata memory dynamic;

        // Faction
        traits.faction = factionIdToName(md.faction);
        dynamic.faction = md.faction;

        // Evolving
        traits.level = 1 + (md.xp > 0 ? sqrt(md.xp / XP_BASIS) : 0);
        traits.locked = md.isUnlocked ? "FALSE" : "TRUE";

        traits.strength =
            traits.level *
            (STR_BASIS +
                gaussianTrait(
                    (
                        uint256(
                            keccak256(abi.encode(seed, keccak256("strength")))
                        )
                    ),
                    5,
                    5
                ));

        traits.endurance =
            traits.level *
            (END_BASIS +
                gaussianTrait(
                    (
                        uint256(
                            keccak256(abi.encode(seed, keccak256("endurance")))
                        )
                    ),
                    5,
                    5
                ));

        traits.intelligence = (INT_BASIS +
            gaussianTrait(
                (
                    uint256(
                        keccak256(abi.encode(seed, keccak256("intelligence")))
                    )
                ),
                5,
                5
            ));

        traits.luck =
            (LCK_BASIS +
                gaussianTrait(
                    (uint256(keccak256(abi.encode(seed, keccak256("luck"))))),
                    3,
                    3
                )) %
            100;

        traits.xp = md.xp;

        // Base traits
        traits.skin = Genes.getSkinValue(chromosome);
        traits.head = Genes.getHeadValue(chromosome);
        traits.eyes = Genes.getEyesValue(chromosome);
        traits.outfit = Genes.getOutfitValue(chromosome);
        traits.mouth = Genes.getMouthValue(chromosome);
        traits.background = Genes.getBackgroundValue(chromosome);

        // Dynamic traits
        dynamic.background = 0; // Has default + dynamic background

        traits.weapon = "NONE";
        dynamic.weapon = 0;

        traits.armor = "NONE";
        dynamic.armor = 0;

        traits.faceArmor = "NONE";
        dynamic.faceArmor = 0;

        traits.eyewear = "NONE";
        dynamic.eyewear = 0;

        traits.misc = "NONE";
        dynamic.misc = 0;

        // Set dynamic background
        if (md.background > 0) {
            traits.background = vendorContract.getItemName(md.background);
            dynamic.background = md.background;
            chromosome <<= 8;
            chromosome |= md.background;
        } else {
            chromosome <<= 8;
            chromosome |= 0;
        }

        // Set dynamic weapon
        if (md.weapon > 0) {
            traits.weapon = vendorContract.getItemName(md.weapon);
            dynamic.weapon = md.weapon;
            chromosome <<= 8;
            chromosome |= md.weapon;
        } else {
            chromosome <<= 8;
            chromosome |= 0;
        }

        // Set dynamic armor
        if (md.armor > 0) {
            traits.armor = vendorContract.getItemName(md.armor);
            dynamic.armor = md.armor;
            chromosome <<= 8;
            chromosome |= md.armor;
        } else {
            chromosome <<= 8;
            chromosome |= 0;
        }

        // Set dynamic face armor
        if (md.faceArmor > 0) {
            traits.faceArmor = vendorContract.getItemName(md.faceArmor);
            dynamic.faceArmor = md.faceArmor;
            chromosome <<= 8;
            chromosome |= md.faceArmor;
        } else {
            chromosome <<= 8;
            chromosome |= 0;
        }

        // Set dynamic eyewear
        if (md.eyewear > 0) {
            traits.eyewear = vendorContract.getItemName(md.eyewear);
            dynamic.eyewear = md.eyewear;
            chromosome <<= 8;
            chromosome |= md.eyewear;
        } else {
            chromosome <<= 8;
            chromosome |= 0;
        }

        // Set dynamic misc
        if (md.misc > 0) {
            traits.misc = vendorContract.getItemName(md.misc);
            dynamic.misc = md.misc;
            chromosome <<= 8;
            chromosome |= md.misc;
        } else {
            chromosome <<= 8;
            chromosome |= 0;
        }

        // Set dynamic head
        if (md.head > 0) {
            traits.head = vendorContract.getItemName(md.head);
            dynamic.head = md.head;
            chromosome <<= 8;
            chromosome |= md.head;
        } else {
            chromosome <<= 8;
            chromosome |= 0;
        }

        return
            Bear({
                name: (bytes(md.name).length > 0)
                    ? md.name
                    : string(
                        abi.encodePacked("Brawler #", Strings.toString(tokenId))
                    ),
                description: (bytes(md.lore).length > 0) ? md.lore : "",
                dna: Strings.toString(chromosome),
                traits: traits,
                dynamic: dynamic
            });
    }

    // ========================================
    // NFT display helpers
    // ========================================

    /**
     * @notice Sets the base URI for the image asset
     * @param _baseURI A base uri
     */
    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    /**
     * @notice Sets the animation URI for the image asset
     * @param _animationURI A base uri
     */
    function setAnimationURI(string memory _animationURI) external onlyOwner {
        animationURI = _animationURI;
    }

    /**
     * @notice Returns a json list of dynamic properties
     * @param instance A bear instance
     */
    function toDynamicProperties(Bear memory instance)
        internal
        view
        returns (string memory)
    {
        string[] memory dynamic = new string[](15);

        dynamic[0] = toJSONAttribute(
            "Background Id",
            Strings.toString(instance.dynamic.background)
        );

        dynamic[1] = toJSONAttribute(
            "Background Name",
            vendorContract.getItemName(instance.dynamic.background)
        );

        dynamic[2] = toJSONAttribute(
            "Weapon Id",
            Strings.toString(instance.dynamic.weapon)
        );

        dynamic[3] = toJSONAttribute(
            "Weapon Name",
            vendorContract.getItemName(instance.dynamic.weapon)
        );

        dynamic[4] = toJSONAttribute(
            "Face Armor Id",
            Strings.toString(instance.dynamic.faceArmor)
        );

        dynamic[5] = toJSONAttribute(
            "Face Armor Name",
            vendorContract.getItemName(instance.dynamic.faceArmor)
        );

        dynamic[6] = toJSONAttribute(
            "Armor Id",
            Strings.toString(instance.dynamic.armor)
        );

        dynamic[7] = toJSONAttribute(
            "Armor Name",
            vendorContract.getItemName(instance.dynamic.armor)
        );

        dynamic[8] = toJSONAttribute(
            "Eyewear Id",
            Strings.toString(instance.dynamic.eyewear)
        );

        dynamic[9] = toJSONAttribute(
            "Eyewear Name",
            vendorContract.getItemName(instance.dynamic.eyewear)
        );

        dynamic[10] = toJSONAttribute(
            "Misc Id",
            Strings.toString(instance.dynamic.misc)
        );

        dynamic[11] = toJSONAttribute(
            "Misc Name",
            vendorContract.getItemName(instance.dynamic.misc)
        );

        dynamic[12] = toJSONAttribute(
            "Faction Id",
            Strings.toString(instance.dynamic.faction)
        );

        dynamic[13] = toJSONAttribute(
            "Head Id",
            Strings.toString(instance.dynamic.head)
        );

        dynamic[14] = toJSONAttribute(
            "Head Name",
            vendorContract.getItemName(instance.dynamic.head)
        );

        return toJSONAttributeList(dynamic);
    }

    /**
     * @notice Sets the bearz vendor item contract
     * @dev only owner call this function
     * @param _vendorContractAddress The new contract address
     */
    function setVendorContractAddress(address _vendorContractAddress)
        public
        onlyOwner
    {
        vendorContract = IBrawlerBearzDynamicItems(_vendorContractAddress);
    }

    /**
     * @notice Returns a json list of attribute properties
     * @param instance A bear instance
     */
    function toAttributesProperty(Bear memory instance)
        internal
        pure
        returns (string memory)
    {
        string[] memory attributes = new string[](19);

        attributes[0] = toJSONAttribute("Head", instance.traits.head);

        attributes[1] = toJSONAttribute("Skin", instance.traits.skin);

        attributes[2] = toJSONAttribute("Eyes", instance.traits.eyes);

        attributes[3] = toJSONAttribute("Outfit", instance.traits.outfit);

        attributes[4] = toJSONAttribute("Mouth", instance.traits.mouth);

        attributes[5] = toJSONAttribute(
            "Background",
            instance.traits.background
        );

        attributes[6] = toJSONAttribute("Armor", instance.traits.armor);

        attributes[7] = toJSONAttribute(
            "Face Armor",
            instance.traits.faceArmor
        );

        attributes[8] = toJSONAttribute("Eyewear", instance.traits.eyewear);

        attributes[9] = toJSONAttribute("Weapon", instance.traits.weapon);

        attributes[10] = toJSONAttribute("Miscellaneous", instance.traits.misc);

        attributes[11] = toJSONNumberAttribute(
            "XP",
            Strings.toString(instance.traits.xp)
        );

        attributes[12] = toJSONNumberAttribute(
            "Level",
            Strings.toString(instance.traits.level)
        );

        attributes[13] = toJSONNumberAttribute(
            "Strength",
            Strings.toString(instance.traits.strength)
        );

        attributes[14] = toJSONNumberAttribute(
            "Endurance",
            Strings.toString(instance.traits.endurance)
        );

        attributes[15] = toJSONNumberAttribute(
            "Intelligence",
            Strings.toString(instance.traits.intelligence)
        );

        attributes[16] = toJSONNumberAttribute(
            "Luck",
            Strings.toString(instance.traits.luck)
        );

        attributes[17] = toJSONAttribute("Is Locked", instance.traits.locked);

        attributes[18] = toJSONAttribute("Faction", instance.traits.faction);

        return toJSONAttributeList(attributes);
    }

    /**
     * @notice Returns hidden base64 json metadata
     * @param _tokenId The bear token id
     */
    function hiddenURI(uint256 _tokenId) public view returns (string memory) {
        Bear memory instance = getHiddenProperties(_tokenId);
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                "{",
                                toJSONProperty("name", instance.name),
                                ",",
                                toJSONProperty(
                                    "description",
                                    instance.description
                                ),
                                ",",
                                toJSONProperty(
                                    "image",
                                    string(
                                        abi.encodePacked(baseURI, instance.dna)
                                    )
                                ),
                                ",",
                                toJSONProperty(
                                    "animation_url",
                                    string(
                                        abi.encodePacked(
                                            animationURI,
                                            instance.dna
                                        )
                                    )
                                ),
                                ",",
                                toJSONProperty(
                                    "external_url",
                                    string(
                                        abi.encodePacked(
                                            animationURI,
                                            instance.dna
                                        )
                                    )
                                ),
                                ",",
                                toJSONProperty(
                                    "tokenId",
                                    Strings.toString(_tokenId)
                                ),
                                ",",
                                toJSONProperty("dna", instance.dna),
                                "}"
                            )
                        )
                    )
                )
            );
    }

    /// @notice Returns the dna for a given token, seed, and metadata
    function dna(
        uint256 _tokenId,
        uint256 _seed,
        CustomMetadata memory _md
    ) public view returns (string memory) {
        Bear memory instance = getProperties(_tokenId, _seed, _md);
        return instance.dna;
    }

    /**
     * @notice Returns a base64 json metadata
     * @param _tokenId The bear token id
     * @param _seed The generated seed
     * @param _md The custom metadata
     */
    function tokenURI(
        uint256 _tokenId,
        uint256 _seed,
        CustomMetadata memory _md
    ) public view returns (string memory) {
        Bear memory instance = getProperties(_tokenId, _seed, _md);
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                "{",
                                toJSONProperty("name", instance.name),
                                ",",
                                toJSONProperty(
                                    "description",
                                    instance.description
                                ),
                                ",",
                                toJSONProperty(
                                    "image",
                                    string(
                                        abi.encodePacked(baseURI, instance.dna)
                                    )
                                ),
                                ",",
                                toJSONProperty(
                                    "animation_url",
                                    string(
                                        abi.encodePacked(
                                            animationURI,
                                            instance.dna
                                        )
                                    )
                                ),
                                ",",
                                toJSONProperty(
                                    "external_url",
                                    string(
                                        abi.encodePacked(
                                            animationURI,
                                            instance.dna
                                        )
                                    )
                                ),
                                ",",
                                abi.encodePacked(
                                    '"equipped": ',
                                    toDynamicProperties(instance)
                                ),
                                ",",
                                abi.encodePacked(
                                    '"attributes": ',
                                    toAttributesProperty(instance)
                                ),
                                ",",
                                toJSONProperty(
                                    "tokenId",
                                    Strings.toString(_tokenId)
                                ),
                                ",",
                                toJSONProperty("seed", Strings.toString(_seed)),
                                ",",
                                toJSONProperty("dna", instance.dna),
                                "}"
                            )
                        )
                    )
                )
            );
    }

    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
        // else z = 0 (default value)
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

pragma solidity >=0.6.0;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides functions for encoding/decoding base64
library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    bytes  internal constant TABLE_DECODE = hex"0000000000000000000000000000000000000000000000000000000000000000"
                                            hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
                                            hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
                                            hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE_ENCODE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }

    function decode(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // every 4 characters represent 3 bytes
        uint256 decodedLen = (data.length / 4) * 3;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes(decodedLen + 32);

        assembly {
            // padding with '='
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }

            // set the actual output length
            mstore(result, decodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 4 characters at a time
            for {} lt(dataPtr, endPtr) {}
            {
               // read 4 characters
               dataPtr := add(dataPtr, 4)
               let input := mload(dataPtr)

               // write 3 bytes
               let output := add(
                   add(
                       shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                       shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
                   add(
                       shl( 6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
                               and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IBrawlerBearzCommon} from "./IBrawlerBearzCommon.sol";

interface IBrawlerBearzRenderer is IBrawlerBearzCommon {
    function hiddenURI(uint256 _tokenId) external view returns (string memory);

    function tokenURI(
        uint256 _tokenId,
        uint256 _seed,
        CustomMetadata memory _md
    ) external view returns (string memory);

    function dna(
        uint256 _tokenId,
        uint256 _seed,
        CustomMetadata memory _md
    ) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";

interface IBrawlerBearzDynamicItems is IERC1155Upgradeable {
    struct CustomMetadata {
        string typeOf;
        string name;
        uint256 xp; // Min XP required to equip
        string rarity; // LEGENDARY, SUPER_RARE, RARE, UNCOMMON, COMMON
        uint256 atk; // Correlated to Strength (5%-50%)
        uint256 def; // Correlated to Endurance (5%-30%), resistance to attack
        uint256 usageChance; // Correlated to Luck + Intelligence (20%-90%)
        string usageDuration; // PERSISTENT - equipable items, TEMPORARY - battles, ONE-TIME - buffs
        string description;
    }

    function getMetadata(uint256 tokenId)
        external
        view
        returns (CustomMetadata memory);

    function getMetadataBatch(uint256[] calldata tokenIds)
        external
        view
        returns (CustomMetadata[] memory);

    function getItemType(uint256 tokenId) external view returns (string memory);

    function getItemName(uint256 tokenId) external view returns (string memory);

    function getItemXPReq(uint256 tokenId) external view returns (uint256);

    function setItemMetadata(
        uint256 tokenId,
        string calldata typeOf,
        string calldata name,
        uint256 xp
    ) external;

    function setItemMetadataStruct(
        uint256 tokenId,
        CustomMetadata memory metadata
    ) external;

    function shopDrop(address _toAddress, uint256 _amount) external;

    function dropItems(address _toAddress, uint256[] calldata itemIds) external;

    function burnItemForOwnerAddress(
        uint256 _typeId,
        uint256 _quantity,
        address _materialOwnerAddress
    ) external;

    function mintItemToAddress(
        uint256 _typeId,
        uint256 _quantity,
        address _toAddress
    ) external;

    function mintBatchItemsToAddress(
        uint256[] memory _typeIds,
        uint256[] memory _quantities,
        address _toAddress
    ) external;

    function bulkSafeTransfer(
        uint256 _typeId,
        uint256 _quantityPerRecipient,
        address[] calldata recipients
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// GENERATED CODE DO NOT MODIFY!

/*******************************************************************************
 * Genes
 * Developed By: @ScottMitchell18
 * Each of those seedTo{Group} function select 4 bytes from the seed
 * and use those selected bytes to pick a trait using the A.J. Walker
 * algorithm O(1) complexity. The rarity and aliases are calculated off-chain.
 *******************************************************************************/

library Genes {
    function getGene(uint256 chromosome, uint32 position)
        internal
        pure
        returns (uint256)
    {
        unchecked {
            uint32 shift = 8 * position;
            return (chromosome & (0xFF << shift)) >> shift;
        }
    }

    function seedToBackground(uint256 seed) internal pure returns (uint256) {
        unchecked {
            uint256 traitSeed = (seed >> 16) & 0xFFFF;
            uint256 trait = traitSeed % 14;
            if (
                traitSeed >> 8 <
                [
                    255,
                    122,
                    215,
                    133,
                    250,
                    130,
                    117,
                    107,
                    71,
                    235,
                    133,
                    120,
                    35,
                    17
                ][trait]
            ) return trait;
            return [0, 0, 0, 1, 3, 4, 5, 1, 3, 6, 9, 10, 6, 11][trait];
        }
    }

    function getBackgroundValue(uint256 chromosome)
        public
        pure
        returns (string memory)
    {
        uint256 gene = getBackground(chromosome);

        if (gene == 0) {
            return "Gray";
        }

        if (gene == 1) {
            return "Moss";
        }

        if (gene == 2) {
            return "Orange";
        }

        if (gene == 3) {
            return "Red";
        }

        if (gene == 4) {
            return "Green";
        }

        if (gene == 5) {
            return "Blue";
        }

        if (gene == 6) {
            return "Brown";
        }

        if (gene == 7) {
            return "Smoke";
        }

        if (gene == 8) {
            return "Red Smoke";
        }

        if (gene == 9) {
            return "Maroon";
        }

        if (gene == 10) {
            return "Purple";
        }

        if (gene == 11) {
            return "Navy";
        }

        if (gene == 12) {
            return "Graffiti";
        }

        if (gene == 13) {
            return "Cyber Safari";
        }
        return "";
    }

    function getBackground(uint256 chromosome) internal pure returns (uint256) {
        return getGene(chromosome, 5);
    }

    function seedToSkin(uint256 seed) internal pure returns (uint256) {
        unchecked {
            uint256 traitSeed = (seed >> 32) & 0xFFFF;
            uint256 trait = traitSeed % 21;
            if (
                traitSeed >> 8 <
                [
                    34,
                    16,
                    69,
                    256,
                    94,
                    215,
                    131,
                    188,
                    162,
                    98,
                    188,
                    255,
                    212,
                    92,
                    212,
                    218,
                    75,
                    147,
                    53,
                    205,
                    173
                ][trait]
            ) return trait;
            return
                [
                    9,
                    13,
                    13,
                    0,
                    14,
                    14,
                    14,
                    14,
                    3,
                    8,
                    19,
                    19,
                    9,
                    12,
                    13,
                    14,
                    19,
                    20,
                    20,
                    15,
                    19
                ][trait];
        }
    }

    function getSkinValue(uint256 chromosome)
        public
        pure
        returns (string memory)
    {
        uint256 gene = getSkin(chromosome);

        if (gene == 0) {
            return "Plasma";
        }

        if (gene == 1) {
            return "Sun Breaker";
        }

        if (gene == 2) {
            return "Negative";
        }

        if (gene == 3) {
            return "Mash";
        }

        if (gene == 4) {
            return "Grey Tiger";
        }

        if (gene == 5) {
            return "Polar Bear";
        }

        if (gene == 6) {
            return "Tan Tiger";
        }

        if (gene == 7) {
            return "Tiger";
        }

        if (gene == 8) {
            return "Chocolate Striped";
        }

        if (gene == 9) {
            return "Ripper";
        }

        if (gene == 10) {
            return "Brown Panda";
        }

        if (gene == 11) {
            return "Panda";
        }

        if (gene == 12) {
            return "Brown";
        }

        if (gene == 13) {
            return "Grey";
        }

        if (gene == 14) {
            return "Tan";
        }

        if (gene == 15) {
            return "Black Bear";
        }

        if (gene == 16) {
            return "Toxic";
        }

        if (gene == 17) {
            return "Green Chalk";
        }

        if (gene == 18) {
            return "Negative Tiger";
        }

        if (gene == 19) {
            return "Metal";
        }

        if (gene == 20) {
            return "Orange";
        }
        return "";
    }

    function getSkin(uint256 chromosome) internal pure returns (uint256) {
        return getGene(chromosome, 4);
    }

    function seedToHead(uint256 seed) internal pure returns (uint256) {
        unchecked {
            uint256 traitSeed = (seed >> 48) & 0xFFFF;
            uint256 trait = traitSeed % 72;
            if (
                traitSeed >> 8 <
                [
                    196,
                    196,
                    18,
                    204,
                    130,
                    149,
                    138,
                    154,
                    201,
                    138,
                    206,
                    238,
                    188,
                    180,
                    167,
                    112,
                    122,
                    125,
                    156,
                    170,
                    78,
                    117,
                    183,
                    130,
                    183,
                    256,
                    156,
                    209,
                    143,
                    156,
                    159,
                    235,
                    209,
                    198,
                    235,
                    151,
                    143,
                    196,
                    222,
                    170,
                    23,
                    104,
                    130,
                    104,
                    130,
                    78,
                    26,
                    167,
                    189,
                    218,
                    91,
                    170,
                    225,
                    220,
                    239,
                    182,
                    243,
                    235,
                    177,
                    145,
                    31,
                    78,
                    130,
                    173,
                    209,
                    237,
                    252,
                    136,
                    250,
                    179,
                    220,
                    170
                ][trait]
            ) return trait;
            return
                [
                    33,
                    33,
                    33,
                    34,
                    35,
                    35,
                    35,
                    47,
                    47,
                    47,
                    47,
                    47,
                    48,
                    48,
                    48,
                    49,
                    52,
                    52,
                    52,
                    52,
                    52,
                    52,
                    52,
                    53,
                    53,
                    0,
                    53,
                    53,
                    53,
                    53,
                    53,
                    53,
                    53,
                    25,
                    33,
                    34,
                    54,
                    54,
                    54,
                    54,
                    54,
                    55,
                    55,
                    59,
                    63,
                    63,
                    64,
                    35,
                    47,
                    48,
                    65,
                    66,
                    49,
                    52,
                    53,
                    54,
                    55,
                    56,
                    57,
                    58,
                    67,
                    69,
                    70,
                    59,
                    63,
                    64,
                    65,
                    66,
                    67,
                    68,
                    69,
                    70
                ][trait];
        }
    }

    function getHeadValue(uint256 chromosome)
        public
        pure
        returns (string memory)
    {
        uint256 gene = getHead(chromosome);

        if (gene == 0) {
            return "Green Soda Hat";
        }

        if (gene == 1) {
            return "Orange Soda Hat";
        }

        if (gene == 2) {
            return "Golden Gladiator Helmet";
        }

        if (gene == 3) {
            return "Gladiator Helmet";
        }

        if (gene == 4) {
            return "Bone Head";
        }

        if (gene == 5) {
            return "Holiday Beanie";
        }

        if (gene == 6) {
            return "Pan";
        }

        if (gene == 7) {
            return "Snow Trooper";
        }

        if (gene == 8) {
            return "Bearlympics Headband";
        }

        if (gene == 9) {
            return "Sea Cap";
        }

        if (gene == 10) {
            return "Green Goggles";
        }

        if (gene == 11) {
            return "Red Goggles";
        }

        if (gene == 12) {
            return "Society Cap";
        }

        if (gene == 13) {
            return "Fireman Hat";
        }

        if (gene == 14) {
            return "Vendor Cap";
        }

        if (gene == 15) {
            return "Banana";
        }

        if (gene == 16) {
            return "Cake";
        }

        if (gene == 17) {
            return "Rabbit Ears";
        }

        if (gene == 18) {
            return "Party Hat";
        }

        if (gene == 19) {
            return "Rice Hat";
        }

        if (gene == 20) {
            return "None";
        }

        if (gene == 21) {
            return "Alarm";
        }

        if (gene == 22) {
            return "Karate Band";
        }

        if (gene == 23) {
            return "Butchered";
        }

        if (gene == 24) {
            return "Green Bear Rag";
        }

        if (gene == 25) {
            return "Red Bear Rag";
        }

        if (gene == 26) {
            return "Wizard Hat";
        }

        if (gene == 27) {
            return "Ninja Headband";
        }

        if (gene == 28) {
            return "Sombrero";
        }

        if (gene == 29) {
            return "Blue Ice Cream";
        }

        if (gene == 30) {
            return "Red Ice Cream";
        }

        if (gene == 31) {
            return "Viking Helmet";
        }

        if (gene == 32) {
            return "Snow Hat";
        }

        if (gene == 33) {
            return "Green Bucket Hat";
        }

        if (gene == 34) {
            return "Blue Bucket Hat";
        }

        if (gene == 35) {
            return "Red Bucket Hat";
        }

        if (gene == 36) {
            return "Chef Hat";
        }

        if (gene == 37) {
            return "Bearz Police";
        }

        if (gene == 38) {
            return "Cowboy Hat";
        }

        if (gene == 39) {
            return "Straw Hat";
        }

        if (gene == 40) {
            return "Kings Crown";
        }

        if (gene == 41) {
            return "Halo";
        }

        if (gene == 42) {
            return "Jester Hat";
        }

        if (gene == 43) {
            return "Dark Piratez";
        }

        if (gene == 44) {
            return "Santa Hat";
        }

        if (gene == 45) {
            return "Cyber Rice hat";
        }

        if (gene == 46) {
            return "Wulfz";
        }

        if (gene == 47) {
            return "Two Toned Cap";
        }

        if (gene == 48) {
            return "Black Cap";
        }

        if (gene == 49) {
            return "Green Cap";
        }

        if (gene == 50) {
            return "Trainer Cap";
        }

        if (gene == 51) {
            return "Horn";
        }

        if (gene == 52) {
            return "Green Punk Hair";
        }

        if (gene == 53) {
            return "Blue Punk Hair";
        }

        if (gene == 54) {
            return "Red Punk Hair";
        }

        if (gene == 55) {
            return "Purple Punk Hair";
        }

        if (gene == 56) {
            return "Grey Poof";
        }

        if (gene == 57) {
            return "Blue Beanie";
        }

        if (gene == 58) {
            return "Orange Beanie";
        }

        if (gene == 59) {
            return "Red Beanie";
        }

        if (gene == 60) {
            return "Green Flames";
        }

        if (gene == 61) {
            return "Blue Flames";
        }

        if (gene == 62) {
            return "Flames";
        }

        if (gene == 63) {
            return "Grey Headphones";
        }

        if (gene == 64) {
            return "Blue Headphones";
        }

        if (gene == 65) {
            return "Red Headphones";
        }

        if (gene == 66) {
            return "Black Snapback";
        }

        if (gene == 67) {
            return "Green Snapback";
        }

        if (gene == 68) {
            return "Blue Snapback";
        }

        if (gene == 69) {
            return "Two Tones Snapback";
        }

        if (gene == 70) {
            return "Red Snapback";
        }

        if (gene == 71) {
            return "Vault Bear";
        }
        return "";
    }

    function getHead(uint256 chromosome) internal pure returns (uint256) {
        return getGene(chromosome, 3);
    }

    function seedToEyes(uint256 seed) internal pure returns (uint256) {
        unchecked {
            uint256 traitSeed = (seed >> 64) & 0xFFFF;
            uint256 trait = traitSeed % 13;
            if (
                traitSeed >> 8 <
                [255, 242, 241, 231, 197, 68, 166, 58, 124, 13, 58, 67, 74][
                    trait
                ]
            ) return trait;
            return [0, 0, 1, 2, 3, 4, 0, 1, 1, 3, 11, 5, 11][trait];
        }
    }

    function getEyesValue(uint256 chromosome)
        public
        pure
        returns (string memory)
    {
        uint256 gene = getEyes(chromosome);

        if (gene == 0) {
            return "Real Green";
        }

        if (gene == 1) {
            return "Black";
        }

        if (gene == 2) {
            return "Black Side Eye";
        }

        if (gene == 3) {
            return "Real Black";
        }

        if (gene == 4) {
            return "Real Blue";
        }

        if (gene == 5) {
            return "Honey";
        }

        if (gene == 6) {
            return "Ghost";
        }

        if (gene == 7) {
            return "Snake";
        }

        if (gene == 8) {
            return "Worried";
        }

        if (gene == 9) {
            return "Cyber";
        }

        if (gene == 10) {
            return "Lizard";
        }

        if (gene == 11) {
            return "Brown";
        }

        if (gene == 12) {
            return "Bloodshot";
        }
        return "";
    }

    function getEyes(uint256 chromosome) internal pure returns (uint256) {
        return getGene(chromosome, 2);
    }

    function seedToMouth(uint256 seed) internal pure returns (uint256) {
        unchecked {
            uint256 traitSeed = (seed >> 80) & 0xFFFF;
            uint256 trait = traitSeed % 11;
            if (
                traitSeed >> 8 <
                [255, 211, 42, 70, 254, 211, 138, 174, 197, 140, 14][trait]
            ) return trait;
            return [0, 0, 0, 6, 0, 6, 4, 6, 6, 6, 7][trait];
        }
    }

    function getMouthValue(uint256 chromosome)
        public
        pure
        returns (string memory)
    {
        uint256 gene = getMouth(chromosome);

        if (gene == 0) {
            return "Serious";
        }

        if (gene == 1) {
            return "Tongue";
        }

        if (gene == 2) {
            return "Ramen";
        }

        if (gene == 3) {
            return "Lollipop";
        }

        if (gene == 4) {
            return "Orge";
        }

        if (gene == 5) {
            return "Tiger";
        }

        if (gene == 6) {
            return "Smile";
        }

        if (gene == 7) {
            return "Angry";
        }

        if (gene == 8) {
            return "Worried";
        }

        if (gene == 9) {
            return "Rage";
        }

        if (gene == 10) {
            return "Bloody Fangs";
        }
        return "";
    }

    function getMouth(uint256 chromosome) internal pure returns (uint256) {
        return getGene(chromosome, 1);
    }

    function seedToOutfit(uint256 seed) internal pure returns (uint256) {
        unchecked {
            uint256 traitSeed = (seed >> 96) & 0xFFFF;
            uint256 trait = traitSeed % 75;
            if (
                traitSeed >> 8 <
                [
                    74,
                    24,
                    248,
                    198,
                    256,
                    124,
                    186,
                    149,
                    223,
                    111,
                    213,
                    171,
                    216,
                    153,
                    123,
                    80,
                    207,
                    152,
                    97,
                    151,
                    187,
                    192,
                    174,
                    24,
                    94,
                    248,
                    124,
                    223,
                    211,
                    223,
                    248,
                    248,
                    223,
                    186,
                    223,
                    124,
                    99,
                    233,
                    227,
                    192,
                    171,
                    136,
                    223,
                    174,
                    186,
                    198,
                    186,
                    174,
                    223,
                    198,
                    136,
                    144,
                    194,
                    141,
                    139,
                    198,
                    198,
                    198,
                    176,
                    196,
                    179,
                    250,
                    240,
                    197,
                    174,
                    249,
                    157,
                    248,
                    194,
                    226,
                    161,
                    213,
                    219,
                    129,
                    74
                ][trait]
            ) return trait;
            return
                [
                    15,
                    18,
                    18,
                    18,
                    0,
                    19,
                    19,
                    19,
                    19,
                    20,
                    4,
                    10,
                    20,
                    11,
                    13,
                    14,
                    15,
                    16,
                    17,
                    18,
                    19,
                    20,
                    21,
                    24,
                    22,
                    24,
                    25,
                    24,
                    24,
                    25,
                    25,
                    25,
                    25,
                    25,
                    25,
                    26,
                    26,
                    26,
                    37,
                    38,
                    37,
                    37,
                    37,
                    38,
                    39,
                    39,
                    39,
                    60,
                    60,
                    61,
                    63,
                    66,
                    69,
                    69,
                    70,
                    70,
                    70,
                    71,
                    71,
                    39,
                    59,
                    60,
                    61,
                    62,
                    72,
                    63,
                    65,
                    72,
                    72,
                    66,
                    69,
                    70,
                    71,
                    72,
                    73
                ][trait];
        }
    }

    function getOutfitValue(uint256 chromosome)
        public
        pure
        returns (string memory)
    {
        uint256 gene = getOutfit(chromosome);

        if (gene == 0) {
            return "Dark Space Suit";
        }

        if (gene == 1) {
            return "Golden Space Suit";
        }

        if (gene == 2) {
            return "Space Suit";
        }

        if (gene == 3) {
            return "Rugged Jacket";
        }

        if (gene == 4) {
            return "Multi Jacket";
        }

        if (gene == 5) {
            return "Plated Suit";
        }

        if (gene == 6) {
            return "T16 Jacket";
        }

        if (gene == 7) {
            return "Sand Raider Armor";
        }

        if (gene == 8) {
            return "Raider Armor";
        }

        if (gene == 9) {
            return "Tuxedo";
        }

        if (gene == 10) {
            return "Blue Don Jacket";
        }

        if (gene == 11) {
            return "Green Don Jacket";
        }

        if (gene == 12) {
            return "Purple Don Jacket";
        }

        if (gene == 13) {
            return "Red Don Jacket";
        }

        if (gene == 14) {
            return "Hunter Jacket";
        }

        if (gene == 15) {
            return "Brawler Bearz Hoodie";
        }

        if (gene == 16) {
            return "Quartz Paw Hoodie";
        }

        if (gene == 17) {
            return "Cyan Paw Hoodie";
        }

        if (gene == 18) {
            return "Blue Two Tone Hoodie";
        }

        if (gene == 19) {
            return "Red Two Tone Hoodie";
        }

        if (gene == 20) {
            return "Purple Two Tone Hoodie";
        }

        if (gene == 21) {
            return "Orange Paw Hoodie";
        }

        if (gene == 22) {
            return "Green Paw Hoodie";
        }

        if (gene == 23) {
            return "MVHQ Hoodie";
        }

        if (gene == 24) {
            return "Green Bearz Hoodie";
        }

        if (gene == 25) {
            return "Red Bearz Hoodie";
        }

        if (gene == 26) {
            return "Street Hoodie";
        }

        if (gene == 27) {
            return "Ranger Trench Jacket";
        }

        if (gene == 28) {
            return "Night Rider Jacket";
        }

        if (gene == 29) {
            return "Blue Utility Jacket";
        }

        if (gene == 30) {
            return "Orange Utility Jacket";
        }

        if (gene == 31) {
            return "Red Utility Jacket";
        }

        if (gene == 32) {
            return "Brown Neo Jacket";
        }

        if (gene == 33) {
            return "Green Neo Jacet";
        }

        if (gene == 34) {
            return "Forester Jacket";
        }

        if (gene == 35) {
            return "Robe";
        }

        if (gene == 36) {
            return "Champions Robe";
        }

        if (gene == 37) {
            return "Red Flame Pullover";
        }

        if (gene == 38) {
            return "Blue Flame Pullover";
        }

        if (gene == 39) {
            return "Leather Jacket";
        }

        if (gene == 40) {
            return "Chain";
        }

        if (gene == 41) {
            return "Tech Suit";
        }

        if (gene == 42) {
            return "Red 10 Plate Armor";
        }

        if (gene == 43) {
            return "Blue 10 Plate Armor";
        }

        if (gene == 44) {
            return "Orange 10 Plate Armor";
        }

        if (gene == 45) {
            return "Green 9 Plate Armor";
        }

        if (gene == 46) {
            return "Orange 9 Plate Armor";
        }

        if (gene == 47) {
            return "Blue 9 Plate Armor";
        }

        if (gene == 48) {
            return "Red 9 Plate Armor";
        }

        if (gene == 49) {
            return "Forester Bandana";
        }

        if (gene == 50) {
            return "Purple Striped Bandana";
        }

        if (gene == 51) {
            return "Green Striped Bandana";
        }

        if (gene == 52) {
            return "Green Bandana";
        }

        if (gene == 53) {
            return "Blue Striped Bandana";
        }

        if (gene == 54) {
            return "Red Striped Bandana";
        }

        if (gene == 55) {
            return "Red Bandana";
        }

        if (gene == 56) {
            return "Red Arm Bandana";
        }

        if (gene == 57) {
            return "Blue Arm Bandana";
        }

        if (gene == 58) {
            return "Black Arm Bandana";
        }

        if (gene == 59) {
            return "Black Tee";
        }

        if (gene == 60) {
            return "White Tee";
        }

        if (gene == 61) {
            return "Two Toned Tee";
        }

        if (gene == 62) {
            return "Two Tone Long Sleeve";
        }

        if (gene == 63) {
            return "Bearz Long Sleeve";
        }

        if (gene == 64) {
            return "Bearz Tee";
        }

        if (gene == 65) {
            return "Graphic Tee";
        }

        if (gene == 66) {
            return "Black Graphic Tee";
        }

        if (gene == 67) {
            return "Dark Piratez Suit";
        }

        if (gene == 68) {
            return "Green Arm Bandana";
        }

        if (gene == 69) {
            return "Black Bearz Hoodie";
        }

        if (gene == 70) {
            return "White Futura Jacket";
        }

        if (gene == 71) {
            return "Orange Futura Jacket";
        }

        if (gene == 72) {
            return "Red Futura Jacket";
        }

        if (gene == 73) {
            return "Damaged Shirt";
        }

        if (gene == 74) {
            return "None";
        }
        return "";
    }

    function getOutfit(uint256 chromosome) internal pure returns (uint256) {
        return getGene(chromosome, 0);
    }

    function seedToChromosome(uint256 seed)
        internal
        pure
        returns (uint256 chromosome)
    {
        chromosome |= seedToBackground(seed);
        chromosome <<= 8;

        chromosome |= seedToSkin(seed);
        chromosome <<= 8;

        chromosome |= seedToHead(seed);
        chromosome <<= 8;

        chromosome |= seedToEyes(seed);
        chromosome <<= 8;

        chromosome |= seedToMouth(seed);
        chromosome <<= 8;

        chromosome |= seedToOutfit(seed);
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBrawlerBearzCommon {
    struct CustomMetadata {
        string name;
        string lore;
        uint256 background;
        uint256 head;
        uint256 weapon;
        uint256 armor;
        uint256 faceArmor;
        uint256 eyewear;
        uint256 misc;
        uint256 xp;
        bool isUnlocked;
        uint256 faction;
    }

    struct Traits {
        uint256 strength;
        uint256 endurance;
        uint256 intelligence;
        uint256 luck;
        uint256 xp;
        uint256 level;
        string skin;
        string head;
        string eyes;
        string outfit;
        string mouth;
        string background;
        string weapon;
        string armor;
        string eyewear;
        string faceArmor;
        string misc;
        string locked;
        string faction;
    }

    struct Bear {
        string name;
        string description;
        string dna;
        Traits traits;
        CustomMetadata dynamic;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
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
interface IERC165Upgradeable {
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