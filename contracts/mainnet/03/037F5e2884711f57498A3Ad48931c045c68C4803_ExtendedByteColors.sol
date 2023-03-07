// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IColors.sol";
import "./IExtendedColors.sol";

contract ExtendedByteColors is IExtendedColors, Ownable
{
    IColors public byteColors;

    string[][] public colorNames;

    constructor() {
        initData();
    }

    function initData() internal {

        //0  splurge    5x
        colorNames.push([ "Tomato", "Dark Purple", "Sky Magenta", "Sea Green", "Selective Yellow" ]);

        //1  New Growth 5x
        colorNames.push([ "Charcoal", "Persian Green", "Saffron", "Sandy Brown", "Burnt Sienna" ]);

        //2  pink velvet    10x
        colorNames.push([ "Folly", "French Rose", "Bright Pink", "Rose Pompadour", "Tickle Me Pink", "Salmon Pink", "Cherry Blossom Pink", "Pink", "Tea Rose", "Misty Rose" ]);

        //3  marshmallow    5x
        colorNames.push([ "Platinum", "Champagne Pink", "Pink", "Cherry Blossom Pink", "Mountbatten Pink" ]);

        //4  space station lights   5x
        colorNames.push([ "Aero", "Slate Blue", "Fluorescent Cyan", "Fuchsia", "Icterine" ]);

        //5  gentle dragon  x6
        colorNames.push([ "English Violet", "Cool Grey", "Pearl", "Old Rose", "Air Superiority Blue", "Platinum" ]);

        //6  wood   x5
        colorNames.push([ "Coffee", "Barn Red", "Raw Umber", "Buff", "Antique White" ]);

        //7  clay flora x6
        colorNames.push([ "Brown", "Burnt Orange", "Alloy Orange", "Reseda Green", "Ebony", "Dark Green" ]);

        //8  neon   x6
        colorNames.push([ "Hot Magenta", "Lawn Green", "Aquamarine", "Azure", "Electric Purple", "Cerise" ]);

        //9 ultra violetta  x10
        colorNames.push([ "Blue", "Electric Indigo", "Violet", "Veronica", "Veronica II", "Electric Purple", "Steel Pink", "Steel Pink II", "Hollywood Cerise", "Magenta" ]);

        //10  powder reveal x9
        colorNames.push([ "Sky Magenta", "Persian Pink", "Plum", "Mauve", "Mauve II", "Periwinkle", "Jordy Blue", "Light Sky Blue", "Pale Azure" ]);

        //11 pastel 2   x5
        colorNames.push([ "Carnation Pink", "Lemon Chiffon", "Nyaza", "Uranian Blue", "Mauve" ]);

        //12 matured    x5
        colorNames.push([ "Oxford Blue", "Hooker's Green", "Jasmine", "Engineering Orange", "Dark Red" ]);

        //13 black & yellow x5
        colorNames.push([ "Timberwolf", "Aureolin", "Jonquil", "Eerie Black", "Jet" ]);

        //14 pure   x2
        colorNames.push([ "Black", "White" ]);

        //15 emeralds   x5
        colorNames.push([ "Light Sea Green", "Pine Green", "Midnight Green", "Light Sea Green", "Persian Green" ]);

        //16 yellow bloom   x6
        colorNames.push([ "Vanilla", "Citron", "Battleship Gray", "Sky Blue", "Non Photo Blue", "Light Cyan" ]);

        //17 blue flamed log   x6
        colorNames.push([ "Lion", "Peach Yellow", "Antique White", "Columbia Blue", "Light Blue", "Air Superiority Blue II" ]);

        //18 bausin     x4
        colorNames.push([ "Bronze", "Raisin Black", "Brown Sugar", "Moonstone" ]);

    }

    function getPalette(uint idx) external view virtual override returns (string[] memory) {
        return byteColors.getPalette(idx);
    }

    function getPaletteSize(uint idx) external view virtual override returns (uint) {
        return byteColors.getPaletteSize(idx);
    }

    function getSkyPalette(uint idx) external view virtual override returns (string[] memory) {
        return byteColors.getSkyPalette(idx);
    }

    function getNumSkys() external view virtual override returns (uint numSkys) {
        return byteColors.getNumSkys();
    }

    function getNumPalettes() external view virtual override returns (uint numPalettes) {
        return byteColors.getNumPalettes();
    }

    function getSkyName(uint idx) external view virtual override returns (string memory name) {
        return byteColors.getSkyName(idx);
    }

    function getPaletteName(uint idx) external view virtual override returns (string memory name) {
        return byteColors.getPaletteName(idx);
    }

    function getColorName(uint paletteIdx, uint colorIndex) external view returns (string memory name) {
        return colorNames[paletteIdx][colorIndex];
    }

    function getSkyRarities() external view virtual override returns (uint8[] memory) {
        return byteColors.getSkyRarities();
    }

    function geColorPaletteRarities() external view virtual override returns (uint8[] memory) {
        return byteColors.geColorPaletteRarities();
    }

    //------------------------------
    //owner only

    function setColorsAddr(address addr) external virtual onlyOwner {
        byteColors = IColors(addr);
    }

    function validateContract() external view returns (string memory) {
        if (address(byteColors) == address(0)) {
            return "No colors";
        }
        else {
            return "";
        }
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IValidatable {
    function validateContract() external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./IColors.sol";
import "./pings/IValidatable.sol";

interface IExtendedColors is IColors, IValidatable {
    function getColorName(uint paletteIdx, uint colorIndex) external view returns (string calldata name);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface IColors
{

    function getPalette(uint idx) external view returns (string[] calldata colors);
    function getPaletteSize(uint idx) external view returns (uint numColors) ;
    function getSkyPalette(uint idx) external view returns (string[] calldata colors);

    function getNumSkys() external view returns (uint numSkys);
    function getNumPalettes() external view returns (uint numPalettes);

    function getSkyName(uint idx) external view returns (string calldata name);
    function getPaletteName(uint idx) external view returns (string calldata name);

    function getSkyRarities() external view returns (uint8[] memory);
    function geColorPaletteRarities() external view returns (uint8[] memory);

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