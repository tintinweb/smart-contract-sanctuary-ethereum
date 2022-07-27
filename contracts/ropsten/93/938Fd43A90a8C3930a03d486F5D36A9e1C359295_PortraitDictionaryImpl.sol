// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "./datatypes/PortraitDataTypes.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PortraitDictionaryImpl is Ownable {
    mapping(uint8 => string) public line;
    mapping(uint8 => string) public affinity;
    mapping(uint8 => string) public class;
    mapping(uint8 => string) public variation;
    mapping(uint8 => string) public expression;
    mapping(uint8 => string) public finish;
    mapping(uint8 => string) public backgroundLine;
    mapping(uint8 => string) public backgroundVariation;
    mapping(bytes32 => string) public typeHashToCommonName;

    constructor() {
        // initialize line dictionary
        line[uint8(PortraitLine.Axolotl)] = "Axolotl";
        line[uint8(PortraitLine.Pterodactyl)] = "Pterodactyl";
        line[uint8(PortraitLine.SeaScorpion)] = "SeaScorpion";
        line[uint8(PortraitLine.Thylacine)] = "Thylacine";
        line[uint8(PortraitLine.Turtle)] = "Turtle";
        line[uint8(PortraitLine.AntEater)] = "AntEater";
        line[uint8(PortraitLine.Beetle)] = "Beetle";
        line[uint8(PortraitLine.Dodo)] = "Dodo";
        line[uint8(PortraitLine.Pangolin)] = "Pangolin";
        line[uint8(PortraitLine.Shoebill)] = "Shoebill";
        line[uint8(PortraitLine.StarNosedMole)] = "StarNosedMole";
        line[uint8(PortraitLine.Taipan)] = "Taipan";
        line[uint8(PortraitLine.Squid)] = "Squid";
        line[uint8(PortraitLine.Snail)] = "Snail";
        line[uint8(PortraitLine.Penguin)] = "Penguin";
        line[uint8(PortraitLine.Lynx)] = "Lynx";
        line[uint8(PortraitLine.Doka)] = "Doka";
        line[uint8(PortraitLine.Grokko)] = "Grokko";
        line[uint8(PortraitLine.Fliish)] = "Fliish";

        // initialize affinity dictionary
        affinity[uint8(Affinity.Water)] = "Water";
        affinity[uint8(Affinity.Tsunami)] = "Tsunami";
        affinity[uint8(Affinity.Inferno)] = "Inferno";
        affinity[uint8(Affinity.Nature)] = "Nature";
        affinity[uint8(Affinity.Granite)] = "Granite";
        affinity[uint8(Affinity.Air)] = "Air";
        affinity[uint8(Affinity.Magma)] = "Magma";
        affinity[uint8(Affinity.Bloom)] = "Bloom";
        affinity[uint8(Affinity.Fire)] = "Fire";
        affinity[uint8(Affinity.Shock)] = "Shock";
        affinity[uint8(Affinity.Frost)] = "Frost";
        affinity[uint8(Affinity.Neutral)] = "Neutral";
        affinity[uint8(Affinity.Earth)] = "Earth";

        // initialize class dictionary
        class[uint8(Class.None)] = "None";
        class[uint8(Class.Bulwark)] = "Bulwark";
        class[uint8(Class.Harbinder)] = "Harbinder";
        class[uint8(Class.Phantom)] = "Phantom";
        class[uint8(Class.Fighter)] = "Fighter";
        class[uint8(Class.Rogue)] = "Rogue";
        class[uint8(Class.Empath)] = "Empath";
        class[uint8(Class.Psion)] = "Psion";
        class[uint8(Class.Vanguard)] = "Vanguard";

        // initialize variation dictionary
        variation[uint8(PortraitVariation.Original)] = "Original";

        // initialize expression dictionary
        expression[uint8(Expression.Normal)] = "Normal";
        expression[uint8(Expression.Uncommon)] = "Uncommon";
        expression[uint8(Expression.Rare)] = "Rare";

        // initialize finish dictionary
        finish[uint8(Finish.Colour)] = "Colour";
        finish[uint8(Finish.Holo)] = "Holo";

        // initialize common names dictionary
        typeHashToCommonName[keccak256("Axolotl Stage 1")] = "Atlas";
        typeHashToCommonName[keccak256("Axolotl Stage 2")] = "Axon";
        typeHashToCommonName[keccak256("Axolotl Stage 3")] = "Axodon";
        typeHashToCommonName[keccak256("Pterodactyl Stage 3")] = "Rhamphyre";
        typeHashToCommonName[keccak256("SeaScorpion Stage 1")] = "Rypter";
        typeHashToCommonName[keccak256("Thylacine Stage 1")] = "Dash";
        typeHashToCommonName[keccak256("Turtle Stage 1")] = "Archie";
        typeHashToCommonName[keccak256("Beetle Stage 2")] = "Goliant";
        typeHashToCommonName[keccak256("Dodo Stage 1")] = "Kukka";
        typeHashToCommonName[keccak256("Pangolin Stage 2")] = "Singe";
        typeHashToCommonName[keccak256("StarNosedMole Stage 2")] = "Loulura";
        typeHashToCommonName[keccak256("Taipan Stage 1")] = "Phyri";
        typeHashToCommonName[keccak256("Squid Stage 1")] = "Squizz";
        typeHashToCommonName[keccak256("Snail Stage 2")] = "Teeantee";
        typeHashToCommonName[keccak256("Penguin Stage 3")] = "Slashin";
        typeHashToCommonName[keccak256("Lynx Stage 1 Neutral None")] = "Lynx";
        typeHashToCommonName[keccak256("Lynx Stage 2 Neutral Rogue")] = "Nimble Lynx";
        typeHashToCommonName[keccak256("Lynx Stage 2 Neutral Psion")] = "Arcane Lynx";
        typeHashToCommonName[keccak256("Lynx Stage 3 Earth Empath")] = "Virtuous Terralynx";
        typeHashToCommonName[keccak256("Lynx Stage 3 Fire Fighter")] = "Relentless Emberlynx";
        typeHashToCommonName[keccak256("Earth Doka Stage 1")] = "Lesser Earth Doka";
        typeHashToCommonName[keccak256("Fire Grokko Stage 1")] = "Lesser Fire Grokko";
        typeHashToCommonName[keccak256("Water Fliish Stage 1")] = "Lesser Water Fliish";

        // initialize backgroundLine dictionary
        backgroundLine[uint8(BackgroundLine.Dots)] = "Dots";
        backgroundLine[uint8(BackgroundLine.Flash)] = "Flash";
        backgroundLine[uint8(BackgroundLine.Hexagon)] = "Hexagon";
        backgroundLine[uint8(BackgroundLine.Rain)] = "Rain";
        backgroundLine[uint8(BackgroundLine.Spotlight)] = "Spotlight";
        backgroundLine[uint8(BackgroundLine.M0z4rt)] = "M0z4rt";
        backgroundLine[uint8(BackgroundLine.Affinity)] = "Affinity";
        backgroundLine[uint8(BackgroundLine.Arena)] = "Arena";
        backgroundLine[uint8(BackgroundLine.Token)] = "Token";
        backgroundLine[uint8(BackgroundLine.Encounter)] = "Encounter";

        // initialize backgroundVariation dictionary
        backgroundVariation[uint8(BackgroundVariation.Orange)] = "Orange";
        backgroundVariation[uint8(BackgroundVariation.Purple)] = "Purple";
        backgroundVariation[uint8(BackgroundVariation.Red)] = "Red";
        backgroundVariation[uint8(BackgroundVariation.Teal)] = "Teal";
        backgroundVariation[uint8(BackgroundVariation.White)] = "White";
        backgroundVariation[uint8(BackgroundVariation.Yellow)] = "Yellow";
        backgroundVariation[uint8(BackgroundVariation.Blue)] = "Blue";
        backgroundVariation[uint8(BackgroundVariation.Green)] = "Green";
        backgroundVariation[uint8(BackgroundVariation.Mangenta)] = "Mangenta";
        backgroundVariation[uint8(BackgroundVariation.Air)] = "Air";
        backgroundVariation[uint8(BackgroundVariation.Earth)] = "Earth";
        backgroundVariation[uint8(BackgroundVariation.Fire)] = "Fire";
        backgroundVariation[uint8(BackgroundVariation.Nature)] = "Nature";
        backgroundVariation[uint8(BackgroundVariation.Water)] = "Water";
        backgroundVariation[uint8(BackgroundVariation.Original)] = "Original";
    }

    function commonName(string calldata _type) external view returns (string memory) {
        return typeHashToCommonName[keccak256(bytes(_type))];
    }

    function addCommonName(string calldata _type, string calldata _commonName) external onlyOwner {
        typeHashToCommonName[keccak256(bytes(_type))] = _commonName;
    }

    function addLine(uint8 _line, string calldata _lineName) external onlyOwner {
        line[_line] = _lineName;
    }

    function addAffinity(uint8 _affinity, string calldata _affinityName) external onlyOwner {
        affinity[_affinity] = _affinityName;
    }

    function addClass(uint8 _class, string calldata _className) external onlyOwner {
        class[_class] = _className;
    }

    function addVariation(uint8 _variation, string calldata _variationName) external onlyOwner {
        variation[_variation] = _variationName;
    }

    function addExpression(uint8 _expression, string calldata _expressionName) external onlyOwner {
        expression[_expression] = _expressionName;
    }

    function addFinish(uint8 _finish, string calldata _finishName) external onlyOwner {
        expression[_finish] = _finishName;
    }

    function addBackgroundLine(uint8 _backgroundLine, string calldata _backgroundLineName) external onlyOwner {
        backgroundLine[_backgroundLine] = _backgroundLineName;
    }

    function addBackgroundVariation(uint8 _backgroundVariation, string calldata _backgroundVariationName)
        external
        onlyOwner
    {
        backgroundVariation[_backgroundVariation] = _backgroundVariationName;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

enum PortraitLine {
    Axolotl,
    Pterodactyl,
    SeaScorpion,
    Thylacine,
    Turtle,
    AntEater,
    Beetle,
    Dodo,
    Pangolin,
    Shoebill,
    StarNosedMole,
    Taipan,
    Squid,
    Snail,
    Penguin,
    Lynx,
    Doka,
    Grokko,
    Fliish
}

enum PortraitVariation {
    Original
}

enum Expression {
    Normal,
    Uncommon,
    Rare
}

enum Finish {
    Colour,
    Holo
}

enum Affinity {
    Water,
    Tsunami,
    Inferno,
    Nature,
    Granite,
    Air,
    Magma,
    Bloom,
    Fire,
    Shock,
    Frost,
    Neutral,
    Earth
}

enum Class {
    None,
    Bulwark,
    Harbinder,
    Phantom,
    Fighter,
    Rogue,
    Empath,
    Psion,
    Vanguard
}

enum BackgroundLine {
    Dots,
    Flash,
    Hexagon,
    Rain,
    Spotlight,
    M0z4rt,
    Affinity,
    Arena,
    Token,
    Encounter
}

enum BackgroundVariation {
    Original,
    Orange,
    Purple,
    Red,
    Teal,
    White,
    Yellow,
    Blue,
    Green,
    Mangenta,
    Air,
    Earth,
    Fire,
    Nature,
    Water,
    Rainbow
}

struct BackgroundMetadata {
    // Background metadata
    uint8 set;
    uint8 tier;
    BackgroundLine line;
    uint8 stage;
    BackgroundVariation variation;
}

struct SlotMetadata {
    // Bonded accessory token ids
    uint256 skinId; // bonded skin id
    uint256 bodyId; // bonded body id
    uint256 eyeId; // bonded eye wear id
    uint256 headId; // bonded head wear id
    uint256 propId; // bonded props id
}

/// @dev Illuvitar Metadata struct
struct PortraitMetadata {
    uint8 batch;
    uint8 set;
    uint8 tier; // tier
    PortraitLine line;
    uint8 stage;
    PortraitVariation variation;
    Expression expression;
    Finish finish;
    Affinity affinity;
    Class class;
    BackgroundMetadata background;
    SlotMetadata slots;
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