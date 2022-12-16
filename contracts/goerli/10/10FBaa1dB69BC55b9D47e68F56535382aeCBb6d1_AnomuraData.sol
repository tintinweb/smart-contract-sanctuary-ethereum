// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

interface IAnomuraData {
    struct Data {
        string[] body;
        string[] claws;
        string[] legs;
        string[] shell;
        string[] headPieces;
        string[] background;
        string[] prefixes;
        string[] suffixes;
        string[] unique;
        string[] backgroundPrefixes;
    }

    function getAnomuraData() external view returns (Data memory);
}

contract AnomuraData is IAnomuraData, Ownable {
    string[] private clawData;
    string[] private legData;
    string[] private bodyData;
    string[] private shellData;
    string[] private backgroundData;
    string[] private headpiecesData;
    string[] private prefixesData;
    string[] private uniqueData;
    string[] private suffixesData;
    string[] private backgroundPrefixesData;

    constructor() {
        clawData.push("Natural Claw");
        clawData.push("Coral Claw");
        clawData.push("Titian Claw");
        clawData.push("Pliers");
        clawData.push("Scissorhands");
        clawData.push("Laser Gun");
        clawData.push("Snow Claw");
        clawData.push("Sky Claw");
        clawData.push("Icicle Claw");
        clawData.push("Pincers");
        clawData.push("Hammer Logs");
        clawData.push("Carnivora Claw");
        clawData.push("Adventure Claw");
        clawData.push("Asteroids Lasergun");
        clawData.push("Pong Claw");

        legData.push("Argent Leg");
        legData.push("Sunlit Leg");
        legData.push("Auroral Leg");
        legData.push("Steel Leg");
        legData.push("Tungsten Leg");
        legData.push("Titanium Leg");
        legData.push("Crystal Leg");
        legData.push("Empyrean Leg");
        legData.push("Azure Leg");
        legData.push("Bamboo Leg");
        legData.push("Walmara Leg");
        legData.push("Pintobortri Leg");
        legData.push("Adventure Leg");
        legData.push("Asteroids Leg");
        legData.push("Pong Leg");

        bodyData.push("Premier Body");
        bodyData.push("Unhinged Body");
        bodyData.push("Mesmerizing Body");
        bodyData.push("Rave Body");
        bodyData.push("Combustion Body");
        bodyData.push("Radiating Eye");
        bodyData.push("Charring Body");
        bodyData.push("Inferno Body");
        bodyData.push("Siberian Body");
        bodyData.push("Antarctic Body");
        bodyData.push("Glacial Body");
        bodyData.push("Amethyst Body");
        bodyData.push("Beast");
        bodyData.push("Panga Panga");
        bodyData.push("Ceylon Ebony");
        bodyData.push("Katalox");
        bodyData.push("Diamond");
        bodyData.push("Golden");
        bodyData.push("Adventure Body");
        bodyData.push("Asteroids Body");
        bodyData.push("Pong Body");

        shellData.push("Auger Shell");
        shellData.push("Seasnail Shell");
        shellData.push("Miter Shell");
        shellData.push("Alembic");
        shellData.push("Chimney");
        shellData.push("Starship");
        shellData.push("Ice Cube");
        shellData.push("Ice Shell");
        shellData.push("Frosty");
        shellData.push("Mora");
        shellData.push("Carnivora");
        shellData.push("Pure Runes");
        shellData.push("Architect");
        shellData.push("Bee Hive");
        shellData.push("Coral");
        shellData.push("Crystal");
        shellData.push("Diamond");
        shellData.push("Ethereum");
        shellData.push("Golden Skull");
        shellData.push("Japan Temple");
        shellData.push("Planter");
        shellData.push("Snail");
        shellData.push("Tentacles");
        shellData.push("Tesla Coil");
        shellData.push("Cherry Blossom");
        shellData.push("Maple Green");
        shellData.push("Volcano");
        shellData.push("Adventure Shell");
        shellData.push("Asteroids Shell");
        shellData.push("Pong Shell");

        backgroundData.push("Crystal Cave");
        backgroundData.push("Crystal Cave Rainbow");
        backgroundData.push("Emerald Forest");
        backgroundData.push("Garden of Eden");
        backgroundData.push("Golden Glade");
        backgroundData.push("Beach");
        backgroundData.push("Magical Deep Sea");
        backgroundData.push("Natural Sea");
        backgroundData.push("Bioluminescent Abyss");
        backgroundData.push("Blazing Furnace");
        backgroundData.push("Steam Apparatus");
        backgroundData.push("Science Lab");
        backgroundData.push("Starship Throne");
        backgroundData.push("Happy Snowfield");
        backgroundData.push("Midnight Mountain");
        backgroundData.push("Cosmic Star");
        backgroundData.push("Sunset Cliffs");
        backgroundData.push("Space Nebula");
        backgroundData.push("Plains of Vietnam");
        backgroundData.push("ZED Run");
        backgroundData.push("African Savannah");
        backgroundData.push("Adventure Space");
        backgroundData.push("Asteroids Space");
        backgroundData.push("Pong Space");

        headpiecesData.push("Morning Sun Starfish");
        headpiecesData.push("Granulated Starfish");
        headpiecesData.push("Royal Starfish");
        headpiecesData.push("Sapphire");
        headpiecesData.push("Emerald");
        headpiecesData.push("Kunzite");
        headpiecesData.push("Rhodonite");
        headpiecesData.push("Aventurine");
        headpiecesData.push("Peridot");
        headpiecesData.push("Moldavite");
        headpiecesData.push("Jasper");
        headpiecesData.push("Alexandrite");
        headpiecesData.push("Copper Fire");
        headpiecesData.push("Chemical Fire");
        headpiecesData.push("Carmine Fire");
        headpiecesData.push("Adventure Key");

        prefixesData.push("Briny");
        prefixesData.push("Tempestuous");
        prefixesData.push("Limpid");
        prefixesData.push("Pacific");
        prefixesData.push("Atlantic");
        prefixesData.push("Abysmal");
        prefixesData.push("Profound");
        prefixesData.push("Misty");
        prefixesData.push("Solar");
        prefixesData.push("Empyrean");
        prefixesData.push("Sideral");
        prefixesData.push("Astral");
        prefixesData.push("Ethereal");
        prefixesData.push("Crystal");
        prefixesData.push("Quantum");
        prefixesData.push("Empiric");
        prefixesData.push("Alchemic");
        prefixesData.push("Crash Test");
        prefixesData.push("Nuclear");
        prefixesData.push("Syntethic");
        prefixesData.push("Tempered");
        prefixesData.push("Fossil");
        prefixesData.push("Craggy");
        prefixesData.push("Gemmed");
        prefixesData.push("Verdant");
        prefixesData.push("Lymphatic");
        prefixesData.push("Gnarled");
        prefixesData.push("Lithic");

        suffixesData.push("of the Coast");
        suffixesData.push("of Maelstrom");
        suffixesData.push("of Depths");
        suffixesData.push("of Eternity");
        suffixesData.push("of Peace");
        suffixesData.push("of Equilibrium");

        suffixesData.push("of the Universe");
        suffixesData.push("of the Galaxy");
        suffixesData.push("of Absolute Zero");
        suffixesData.push("of Constellations");
        suffixesData.push("of the Moon");
        suffixesData.push("of Lightspeed");

        suffixesData.push("of Evidence");
        suffixesData.push("of Relativity");
        suffixesData.push("of Evolution");
        suffixesData.push("of Consumption");
        suffixesData.push("of Progress");
        suffixesData.push("of Damascus");

        suffixesData.push("of Gaia");
        suffixesData.push("of The Wild");
        suffixesData.push("of Overgrowth");
        suffixesData.push("of Rebirth");
        suffixesData.push("of World Roots");
        suffixesData.push("of Stability");

        uniqueData.push("The Leviathan");
        uniqueData.push("Will of Oceanus");
        uniqueData.push("Suijin's Touch");
        uniqueData.push("Tiamat Kiss");
        uniqueData.push("Poseidon Vow");
        uniqueData.push("Long bao");

        uniqueData.push("Uranus Wish");
        uniqueData.push("Aim of Indra");
        uniqueData.push("Cry of Yuki Onna");
        uniqueData.push("Sirius");
        uniqueData.push("Vega");
        uniqueData.push("Altair");

        uniqueData.push("Ephestos Skill");
        uniqueData.push("Gift of Prometheus");
        uniqueData.push("Pandora's");
        uniqueData.push("Wit of Lu Dongbin");
        uniqueData.push("Thoth's Trick");
        uniqueData.push("Cyclopes Plan");

        uniqueData.push("Root of Dimu");
        uniqueData.push("Bhumi's Throne");
        uniqueData.push("Rive of Daphne");
        uniqueData.push("The Minotaur");
        uniqueData.push("Call of Cernunnos");
        uniqueData.push("Graze of Terra");

        backgroundPrefixesData.push("Bountiful");
        backgroundPrefixesData.push("Isolated");
        backgroundPrefixesData.push("Mechanical");
        backgroundPrefixesData.push("Reborn");
    }

    function getAnomuraData() external view returns (Data memory anomuraData) {
        anomuraData = Data({
            body: bodyData,
            claws: clawData,
            legs: legData,
            shell: shellData,
            headPieces: headpiecesData,
            background: backgroundData,
            prefixes: prefixesData,
            suffixes: suffixesData,
            unique: uniqueData,
            backgroundPrefixes: backgroundPrefixesData
        });
    }
}