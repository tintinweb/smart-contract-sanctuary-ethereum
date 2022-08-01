// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "./datatypes/AccessoryDataTypes.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Accessory Dictionary
 *
 * @dev Mappings between the Accessory's metadata uint8/enum values to the official property name (string)
 *
 * @author Yuri Fernandes
 */
contract AccessoryDictionaryImpl is Ownable {
    /// @dev events emitted when dictionary is updated
    event DictionaryUpdated(string indexed dictionaryName, string indexed path, string newValue);

    /// @dev dictionaries
    mapping(uint8 => string) public line;
    mapping(uint8 => string) public variation;
    mapping(uint8 => string) public slotType;
    mapping(uint8 => mapping(uint8 => string)) public lineStageToName;
    mapping(uint8 => mapping(uint8 => string)) public lineStageToDescription;

    constructor() {
        // initialize line dictionary
        _initializeLineDictionary();

        // initialize variation dictionary
        _initializeVariationDictionary();

        // initialize slotType dictionary
        _initializeSlotTypeDictionary();

        // initialize names dictionary
        _initializeNameDictionary();

        // initialize description dictionary
        // TODO: Uncomment!
        //_initializeDescriptionDictionary();
    }

    function name(uint8 _line, uint8 _stage) external view returns (string memory) {
        return lineStageToName[_line][_stage];
    }

    function addName(
        uint8 _line,
        uint8 _stage,
        string calldata _name
    ) external onlyOwner {
        lineStageToName[_line][_stage] = _name;

        emit DictionaryUpdated("Name", string(abi.encodePacked(_itoa8(_line), ",", _itoa8(_stage))), _name);
    }

    function description(uint8 _line, uint8 _stage) external view returns (string memory) {
        return lineStageToDescription[_line][_stage];
    }

    function addDescription(
        uint8 _line,
        uint8 _stage,
        string calldata _description
    ) external onlyOwner {
        lineStageToDescription[_line][_stage] = _description;

        emit DictionaryUpdated(
            "Description",
            string(abi.encodePacked(_itoa8(_line), ",", _itoa8(_stage))),
            _description
        );
    }

    function addLine(uint8 _line, string calldata _lineName) external onlyOwner {
        line[_line] = _lineName;

        emit DictionaryUpdated("Line", string(_itoa8(_line)), _lineName);
    }

    function addVariation(uint8 _variation, string calldata _variationName) external onlyOwner {
        line[_variation] = _variationName;

        emit DictionaryUpdated("Variation", string(_itoa8(_variation)), _variationName);
    }

    function _initializeLineDictionary() internal {
        line[uint8(AccessoryLine.ClassyPipe)] = "Classy Pipe";
        line[uint8(AccessoryLine.ClassyCigar)] = "Classy Cigar";
        line[uint8(AccessoryLine.M0z4rtAntenna)] = "M0z4rt Antenna";
        line[uint8(AccessoryLine.IlluviumBadge)] = "Illuvium Badge";
        line[uint8(AccessoryLine.ClownNose)] = "Clown Nose";
        line[uint8(AccessoryLine.EyeScar)] = "Eye Scar";
        line[uint8(AccessoryLine.WarPaint)] = "War Paint";
        line[uint8(AccessoryLine.GlowingTattoo)] = "Glowing Tattoo";
        line[uint8(AccessoryLine.Bandaid)] = "Bandaid";
        line[uint8(AccessoryLine.Piercing)] = "Piercing";
        line[uint8(AccessoryLine.Halo)] = "Halo";
        line[uint8(AccessoryLine.SoldierHelmet)] = "Soldier Helmet";
        line[uint8(AccessoryLine.Bandana)] = "Bandana";
        line[uint8(AccessoryLine.Fedora)] = "Fedora";
        line[uint8(AccessoryLine.IlluviumBaseballCap)] = "Illuvium Baseball Cap";
        line[uint8(AccessoryLine.ButterflyTie)] = "Butterfly Tie";
        line[uint8(AccessoryLine.NeckChain)] = "Neck Chain";
        line[uint8(AccessoryLine.QuantumCollar)] = "Quantum Collar";
        line[uint8(AccessoryLine.Amulet)] = "Amulet";
        line[uint8(AccessoryLine.DogCollar)] = "Dog Collar";
        line[uint8(AccessoryLine.Sunglasses)] = "Sunglasses";
        line[uint8(AccessoryLine.Monocle)] = "Monocle";
        line[uint8(AccessoryLine.MemeGlasses)] = "Meme Glasses";
        line[uint8(AccessoryLine.PartySlides)] = "Party Slides";
        line[uint8(AccessoryLine.ILVCoins)] = "ILV Coins";
    }

    function _initializeVariationDictionary() internal {
        variation[uint8(AccessoryVariation.Original)] = "Original";
    }

    function _initializeSlotTypeDictionary() internal {
        slotType[uint8(SlotType.Skin)] = "Skin";
        slotType[uint8(SlotType.BodyWear)] = "BodyWear";
        slotType[uint8(SlotType.EyeWear)] = "EyeWear";
        slotType[uint8(SlotType.HeadWear)] = "HeadWear";
        slotType[uint8(SlotType.Prop)] = "Prop";
    }

    function _initializeNameDictionary() internal {
        lineStageToName[uint8(AccessoryLine.ClassyPipe)][1] = "Bronze";
        lineStageToName[uint8(AccessoryLine.ClassyPipe)][2] = "Silver";
        lineStageToName[uint8(AccessoryLine.ClassyPipe)][3] = "Obelisk";
        lineStageToName[uint8(AccessoryLine.ClassyCigar)][1] = "Brown";
        lineStageToName[uint8(AccessoryLine.ClassyCigar)][2] = "Gold Trim";
        lineStageToName[uint8(AccessoryLine.ClassyCigar)][3] = "Obelisk";
        lineStageToName[uint8(AccessoryLine.M0z4rtAntenna)][1] = "Grey";
        lineStageToName[uint8(AccessoryLine.M0z4rtAntenna)][2] = "Bubblegum";
        lineStageToName[uint8(AccessoryLine.M0z4rtAntenna)][3] = "Obelisk";
        lineStageToName[uint8(AccessoryLine.IlluviumBadge)][1] = "Plastic";
        lineStageToName[uint8(AccessoryLine.IlluviumBadge)][2] = "Gold";
        lineStageToName[uint8(AccessoryLine.IlluviumBadge)][3] = "Glowing";
        lineStageToName[uint8(AccessoryLine.ClownNose)][1] = "Plastic";
        lineStageToName[uint8(AccessoryLine.ClownNose)][2] = "Fluffy";
        lineStageToName[uint8(AccessoryLine.ClownNose)][3] = "Glowing";
        lineStageToName[uint8(AccessoryLine.EyeScar)][1] = "Small";
        lineStageToName[uint8(AccessoryLine.EyeScar)][2] = "Double";
        lineStageToName[uint8(AccessoryLine.EyeScar)][3] = "Thick";
        lineStageToName[uint8(AccessoryLine.WarPaint)][1] = "Black";
        lineStageToName[uint8(AccessoryLine.WarPaint)][2] = "Single";
        lineStageToName[uint8(AccessoryLine.WarPaint)][3] = "Bar";
        lineStageToName[uint8(AccessoryLine.GlowingTattoo)][1] = "Dotted";
        lineStageToName[uint8(AccessoryLine.GlowingTattoo)][2] = "Elaborated";
        lineStageToName[uint8(AccessoryLine.GlowingTattoo)][3] = "Illuvium";
        lineStageToName[uint8(AccessoryLine.Bandaid)][1] = "Plain";
        lineStageToName[uint8(AccessoryLine.Bandaid)][2] = "Double";
        lineStageToName[uint8(AccessoryLine.Bandaid)][3] = "Illuvium";
        lineStageToName[uint8(AccessoryLine.Piercing)][1] = "Silver";
        lineStageToName[uint8(AccessoryLine.Piercing)][2] = "Gold";
        lineStageToName[uint8(AccessoryLine.Piercing)][3] = "Rainbow";
        lineStageToName[uint8(AccessoryLine.Halo)][1] = "Metal Wire";
        lineStageToName[uint8(AccessoryLine.Halo)][2] = "Gold";
        lineStageToName[uint8(AccessoryLine.Halo)][3] = "Shiny";
        lineStageToName[uint8(AccessoryLine.SoldierHelmet)][1] = "Plain";
        lineStageToName[uint8(AccessoryLine.SoldierHelmet)][2] = "Illuvium";
        lineStageToName[uint8(AccessoryLine.SoldierHelmet)][3] = "Obelisk";
        lineStageToName[uint8(AccessoryLine.Bandana)][1] = "Black";
        lineStageToName[uint8(AccessoryLine.Bandana)][2] = "Chrome";
        lineStageToName[uint8(AccessoryLine.Bandana)][3] = "Iridescent";
        lineStageToName[uint8(AccessoryLine.Fedora)][1] = "Grey";
        lineStageToName[uint8(AccessoryLine.Fedora)][2] = "Fancy Purple";
        lineStageToName[uint8(AccessoryLine.Fedora)][3] = "Shiny Gold";
        lineStageToName[uint8(AccessoryLine.IlluviumBaseballCap)][1] = "Black";
        lineStageToName[uint8(AccessoryLine.IlluviumBaseballCap)][2] = "Purple";
        lineStageToName[uint8(AccessoryLine.IlluviumBaseballCap)][3] = "Rainbow";
        lineStageToName[uint8(AccessoryLine.ButterflyTie)][1] = "Black";
        lineStageToName[uint8(AccessoryLine.ButterflyTie)][2] = "Striped";
        lineStageToName[uint8(AccessoryLine.ButterflyTie)][3] = "Obelisk";
        lineStageToName[uint8(AccessoryLine.NeckChain)][1] = "Slim Metal";
        lineStageToName[uint8(AccessoryLine.NeckChain)][2] = "Thick Gold";
        lineStageToName[uint8(AccessoryLine.NeckChain)][3] = "Radiating Shackle";
        lineStageToName[uint8(AccessoryLine.QuantumCollar)][1] = "Purple Carbon";
        lineStageToName[uint8(AccessoryLine.QuantumCollar)][2] = "Silver Carbon";
        lineStageToName[uint8(AccessoryLine.QuantumCollar)][3] = "Black Illuvium";
        lineStageToName[uint8(AccessoryLine.Amulet)][1] = "Metal";
        lineStageToName[uint8(AccessoryLine.Amulet)][2] = "Gold";
        lineStageToName[uint8(AccessoryLine.Amulet)][3] = "Cosmic";
        lineStageToName[uint8(AccessoryLine.DogCollar)][1] = "Red Leather";
        lineStageToName[uint8(AccessoryLine.DogCollar)][2] = "Black Spiked";
        lineStageToName[uint8(AccessoryLine.DogCollar)][3] = "Golden Spiked";
        lineStageToName[uint8(AccessoryLine.Sunglasses)][1] = "Black";
        lineStageToName[uint8(AccessoryLine.Sunglasses)][2] = "Silver";
        lineStageToName[uint8(AccessoryLine.Sunglasses)][3] = "Neon";
        lineStageToName[uint8(AccessoryLine.Monocle)][1] = "Gunmetal";
        lineStageToName[uint8(AccessoryLine.Monocle)][2] = "Gold";
        lineStageToName[uint8(AccessoryLine.Monocle)][3] = "Nethersight";
        lineStageToName[uint8(AccessoryLine.MemeGlasses)][1] = "Black";
        lineStageToName[uint8(AccessoryLine.MemeGlasses)][2] = "Sparkly";
        lineStageToName[uint8(AccessoryLine.MemeGlasses)][3] = "Anime";
        lineStageToName[uint8(AccessoryLine.PartySlides)][1] = "Pink";
        lineStageToName[uint8(AccessoryLine.PartySlides)][2] = "Green Neon";
        lineStageToName[uint8(AccessoryLine.PartySlides)][3] = "Rainbow";
        lineStageToName[uint8(AccessoryLine.ILVCoins)][1] = "Silver Replica";
        lineStageToName[uint8(AccessoryLine.ILVCoins)][2] = "Gold Replica";
        lineStageToName[uint8(AccessoryLine.ILVCoins)][3] = "Original";
    }

    function _initializeDescriptionDictionary() internal {
        // TODO: Definitely not the final version
        lineStageToDescription[uint8(AccessoryLine.ClassyPipe)][1] = "A plain bronze pipe.";
        lineStageToDescription[uint8(AccessoryLine.ClassyPipe)][2] = "Silver, with a red Obelisk light.";
        lineStageToDescription[uint8(AccessoryLine.ClassyPipe)][3] = "Ivory Pipe with gold trim and holographic smoke.";
        lineStageToDescription[uint8(AccessoryLine.ClassyCigar)][1] = "Small Cigar - partially burned.";
        lineStageToDescription[uint8(AccessoryLine.ClassyCigar)][2] = "Large Gold Trim Cigar.";
        lineStageToDescription[uint8(AccessoryLine.ClassyCigar)][3] = "An Obelisk White + Gold Trim Cigar.";
        lineStageToDescription[uint8(AccessoryLine.M0z4rtAntenna)][1] = (
            "Dark Grey Mozart Antenna with small glowy orb on the end making its way into the frame."
        );
        lineStageToDescription[uint8(AccessoryLine.M0z4rtAntenna)][2] = (
            "Bubblegum Pink Mozart Antenna with a Sparkly Blue Antenna."
        );
        lineStageToDescription[uint8(AccessoryLine.M0z4rtAntenna)][3] = (
            "Obelisk White with Gold Trim Antenna a Heated / Hot Antenna."
        );
        lineStageToDescription[uint8(AccessoryLine.IlluviumBadge)][1] = (
            "Small, round plastic badge with an illuvium logo on it."
        );
        lineStageToDescription[uint8(AccessoryLine.IlluviumBadge)][2] = (
            "Metal round badge with the obelisk logo on it."
        );
        lineStageToDescription[uint8(AccessoryLine.IlluviumBadge)][3] = (
            "A shiny, glowing badge with the obelisk logo on it."
        );
        lineStageToDescription[uint8(AccessoryLine.ClownNose)][1] = "Red Clown nose - Basic - Plastic.";
        lineStageToDescription[uint8(AccessoryLine.ClownNose)][2] = "Fluffy/hairy Clown Nose.";
        lineStageToDescription[uint8(AccessoryLine.ClownNose)][3] = "Glowing Clown Nose.";
        lineStageToDescription[uint8(AccessoryLine.EyeScar)][1] = "Small Single Eyescar - Crossing Eyebrow and Cheek.";
        lineStageToDescription[uint8(AccessoryLine.EyeScar)][2] = (
            "Double Eyescar Crossing Eyebrow and Cheek - A bit longer/larger than Stage 1."
        );
        lineStageToDescription[uint8(AccessoryLine.EyeScar)][3] = (
            "A more elaborate scar crossing 1 of the eyes and cheek."
        );
        lineStageToDescription[uint8(AccessoryLine.WarPaint)][1] = "Small Black Bars below the eyes.";
        lineStageToDescription[uint8(AccessoryLine.WarPaint)][2] = (
            "More elaborate face paint - Focussed on 1 side of the face."
        );
        lineStageToDescription[uint8(AccessoryLine.WarPaint)][3] = (
            "A Black warpaint bar crossing the eyes (when possible) and going around the head, "
            "so it is always visible, also when a pair of glasses is worn by the portrait."
        );
        lineStageToDescription[uint8(AccessoryLine.GlowingTattoo)][1] = (
            "Small dotted Glowing tattoo's - Very few dots."
        );
        lineStageToDescription[uint8(AccessoryLine.GlowingTattoo)][2] = (
            "More elaborate face tattoo - with more glowing dots."
        );
        lineStageToDescription[uint8(AccessoryLine.GlowingTattoo)][3] = (
            "An elaborate pattern of the obelisk Glowing over the skin."
        );
        lineStageToDescription[uint8(AccessoryLine.Bandaid)][1] = "";
        lineStageToDescription[uint8(AccessoryLine.Bandaid)][2] = "";
        lineStageToDescription[uint8(AccessoryLine.Bandaid)][3] = "";
        lineStageToDescription[uint8(AccessoryLine.Piercing)][1] = "";
        lineStageToDescription[uint8(AccessoryLine.Piercing)][2] = "";
        lineStageToDescription[uint8(AccessoryLine.Piercing)][3] = "";
        lineStageToDescription[uint8(AccessoryLine.Halo)][1] = "Metal Wire Halo - with a stick in the neck.";
        lineStageToDescription[uint8(AccessoryLine.Halo)][2] = "Gold halo.";
        lineStageToDescription[uint8(AccessoryLine.Halo)][3] = "Shining / Radiating Gold halo.";
        lineStageToDescription[uint8(AccessoryLine.SoldierHelmet)][1] = "Dull green soldier hat.";
        lineStageToDescription[uint8(AccessoryLine.SoldierHelmet)][2] = "Camoflaged Helmet.";
        lineStageToDescription[uint8(AccessoryLine.SoldierHelmet)][3] = (
            "Obelisk White Soldier helmet with Cold-Flake camo patches."
        );
        lineStageToDescription[uint8(AccessoryLine.Bandana)][1] = ("Black and yellow/gold Bandana (OBELISK LOGOS).");
        lineStageToDescription[uint8(AccessoryLine.Bandana)][2] = "Metal/Chrome Dotted Banadana.";
        lineStageToDescription[uint8(AccessoryLine.Bandana)][3] = "Holographic Fabric Bandana.";
        lineStageToDescription[uint8(AccessoryLine.Fedora)][1] = "Grey Fedora.";
        lineStageToDescription[uint8(AccessoryLine.Fedora)][2] = "Fancy Purple Fedora.";
        lineStageToDescription[uint8(AccessoryLine.Fedora)][3] = "Gold Shining Fedora - with an Obelisk Logo.";
        lineStageToDescription[uint8(AccessoryLine.IlluviumBaseballCap)][1] = (
            "Black Baseball Cap with Small white Obelisk Logo."
        );
        lineStageToDescription[uint8(AccessoryLine.IlluviumBaseballCap)][2] = (
            "Purple Carbon/Mesh cap with a little bit larger Obelisk Logo."
        );
        lineStageToDescription[uint8(AccessoryLine.IlluviumBaseballCap)][3] = (
            "Holographic Cap with a White-Lighted-Obelisk Logo."
        );
        lineStageToDescription[uint8(AccessoryLine.ButterflyTie)][1] = "Black Butterfly Tie.";
        lineStageToDescription[uint8(AccessoryLine.ButterflyTie)][2] = (
            "Black and Purple Striped Butterfly Tie - Also bigger in size as the Stage 1."
        );
        lineStageToDescription[uint8(AccessoryLine.ButterflyTie)][3] = (
            "White with gold trim Butterfly Tie - Sparkling."
        );
        lineStageToDescription[uint8(AccessoryLine.NeckChain)][1] = "Metal Neck Chain - Fairly Slim.";
        lineStageToDescription[uint8(AccessoryLine.NeckChain)][2] = (
            "Gold Neck Chain - Also bigger in size as the Stage 1."
        );
        lineStageToDescription[uint8(AccessoryLine.NeckChain)][3] = (
            "Radiating Neck Chain (Green Uranium) - Large shackles."
        );
        lineStageToDescription[uint8(AccessoryLine.QuantumCollar)][1] = (
            "Purple + Carbon Pattern - Slick Sci Fi Collar."
        );
        lineStageToDescription[uint8(AccessoryLine.QuantumCollar)][2] = (
            "Silver/Metal + Carbon Pattern With glowing edges - STAGE 2 HAS 1 COLOUR LIGHT."
        );
        lineStageToDescription[uint8(AccessoryLine.QuantumCollar)][3] = "Black Carbon with Holographic Lighted Edges.";
        lineStageToDescription[uint8(AccessoryLine.Amulet)][1] = "SciFi Amulet - Somewhat Simple, silver/metal amulet.";
        lineStageToDescription[uint8(AccessoryLine.Amulet)][2] = (
            "SciFi Amulet - Gold Amulet, mixed with some silvery bits and a symbol / gem."
        );
        lineStageToDescription[uint8(AccessoryLine.Amulet)][3] = (
            "Sci Fi Amulet - Gold with White Obelisk material - and a holographic light / gem."
        );
        lineStageToDescription[uint8(AccessoryLine.DogCollar)][1] = "Thick Red leather Dog Collar.";
        lineStageToDescription[uint8(AccessoryLine.DogCollar)][2] = "Thick Black Leather Dog Collar.";
        lineStageToDescription[uint8(AccessoryLine.DogCollar)][3] = (
            "Thick Black Leather Dog Collar with - Shiny Gold Spikes."
        );
        lineStageToDescription[uint8(AccessoryLine.Sunglasses)][1] = "Black - black glass.";
        lineStageToDescription[uint8(AccessoryLine.Sunglasses)][2] = "Silver frame - black glass.";
        lineStageToDescription[uint8(AccessoryLine.Sunglasses)][3] = "Fluoric color / Neon/glow in the dark.";
        lineStageToDescription[uint8(AccessoryLine.Monocle)][1] = "Metal - black glass.";
        lineStageToDescription[uint8(AccessoryLine.Monocle)][2] = "Gold - Colored Glass.";
        lineStageToDescription[uint8(AccessoryLine.Monocle)][3] = "Gold - Lights - Holographic glass.";
        lineStageToDescription[uint8(AccessoryLine.MemeGlasses)][1] = "Black Meme Glasses.";
        lineStageToDescription[uint8(AccessoryLine.MemeGlasses)][2] = "Black Meme Glasses with Shines/Sparks.";
        lineStageToDescription[uint8(AccessoryLine.MemeGlasses)][3] = (
            "Black - Shines/Sparks + and lighted glasses (anime meme)."
        );
        lineStageToDescription[uint8(AccessoryLine.PartySlides)][1] = "Pink Party Slides.";
        lineStageToDescription[uint8(AccessoryLine.PartySlides)][2] = "Neon Party Slides that glow in the dark.";
        lineStageToDescription[uint8(AccessoryLine.PartySlides)][3] = "Holographic Party Slides.";
        lineStageToDescription[uint8(AccessoryLine.ILVCoins)][1] = "Silver Coins with ILV logo.";
        lineStageToDescription[uint8(AccessoryLine.ILVCoins)][2] = "Gold Coins with ILV logo.";
        lineStageToDescription[uint8(AccessoryLine.ILVCoins)][3] = "Holographic ILV Coins (logo) with slight glow.";
    }

    function _itoa8(uint8 i) internal pure returns (bytes memory a) {
        while (i != 0) {
            a = abi.encodePacked((i % 10) + 0x30, a);
            i /= 10;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

enum SlotType {
    Skin,
    BodyWear,
    EyeWear,
    HeadWear,
    Prop
}

enum AccessoryLine {
    ClassyPipe,
    ClassyCigar,
    M0z4rtAntenna,
    IlluviumBadge,
    ClownNose,
    EyeScar,
    WarPaint,
    GlowingTattoo,
    Bandaid,
    Piercing,
    Halo,
    SoldierHelmet,
    Bandana,
    Fedora,
    IlluviumBaseballCap,
    ButterflyTie,
    NeckChain,
    QuantumCollar,
    Amulet,
    DogCollar,
    Sunglasses,
    Monocle,
    MemeGlasses,
    PartySlides,
    ILVCoins
}

enum AccessoryVariation {
    Original
}

/// @dev Accessory Metadata struct
struct AccessoryMetadata {
    uint8 set;
    uint8 batch;
    uint8 tier; // tier
    AccessoryLine line;
    uint8 stage;
    AccessoryVariation variation;
    SlotType slotType; // Slot type
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