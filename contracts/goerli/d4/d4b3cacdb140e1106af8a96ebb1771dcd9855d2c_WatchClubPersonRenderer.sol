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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./interfaces/IWatchClubPersonRenderer.sol";

contract WatchClubPersonRenderer is Ownable, IWatchClubPersonRenderer {
    constructor() {}

    string[8] private HAT_COLORS = ['#322E32', '#7D5C49', '#D7002F', '#005AC6', '#193352', '#CBC2E6', '#F2F3F4', '#587DA7'];
    string[8] private HAT_SHADOW_COLORS = ['#282528', '#5C4436', '#AA0025', '#004292', '#132841', '#ADA5C5', '#CDCDCF', '#466385'];
    string[8] private SHIRT_COLORS = ['#005AC6', '#D7002F', '#9063D8', '#7D5C49', '#193352', '#F0E7DB', '#B0B9C2', '#F2F3F4'];
    string[8] private SHIRT_SHADOW_COLORS = ['#004292', '#AA0025', '#634698', '#5C4436', '#132841', '#C6BDB1', '#8B939A', '#CDCDCF'];
    string [8] private BACKGROUND_COLORS = ['#FBF6E9', '#C4EAF2', '#E5E4EB', '#FDFDFD', '#FFEDE6', '#FFFBE3', '#B8C6A9', '#FAD5DC'];

    function _renderHat(IWatchClubPersonRenderer.HatType hatType) private view returns (string memory) {
        if (hatType == IWatchClubPersonRenderer.HatType.NONE) {
            return '';
        }
        string memory color = HAT_COLORS[uint256(hatType)];
        string memory shadow = HAT_SHADOW_COLORS[uint256(hatType)];
        string memory partOne = '<path d="m254.32 130.77c0 3.302-1.809 7.212-6.78 11.512-4.953 4.287-12.471 8.419-22.28 12.009-19.571 7.163-47.006 11.711-77.602 11.711-30.595 0-58.03-4.548-77.601-11.711-9.8095-3.59-17.327-7.722-22.28-12.009-4.9704-4.3-6.7795-8.21-6.7795-11.512s1.8091-7.211 6.7795-11.512c4.9536-4.286 12.471-8.418 22.28-12.008 19.571-7.163 47.006-11.711 77.601-11.711 30.596 0 58.031 4.5484 77.602 11.711 9.809 3.59 17.327 7.722 22.28 12.008 4.971 4.301 6.78 8.21 6.78 11.512z" fill="';
        string memory partTwo = '" stroke="#161B1F" stroke-width="12"/><path d="m65.639 110.2 240.53 39.226c-5.388-70.084-65.145-123.06-133.74-118.42-49.222 3.3277-89.653 35.421-106.79 79.194z" clip-rule="evenodd" fill="';
        string memory partThree = '" fill-rule="evenodd"/><path d="m295.5 149.55c0.167-15-5.3-51.2-26.5-80" stroke="';
        string memory partFour = '" stroke-width="12"/><path d="m305.68 150.4-239.47-41.723c-1.1705-0.203 2.4386-7.611 4.3894-11.29 14.046-26.702 37.391-44.177 47.308-49.576 39.407-23.561 82.423-16.362 99.005-9.8171 55.014 16.885 78.87 63.811 85.838 88.354 3.121 10.995 6.015 24.542 2.926 24.052z" stroke="#161B1F" stroke-width="12"/><path d="m234.03 34.324c-1.096 3.1984-6.172 6.3409-13 4.0002-6.827-2.3407-8.907-7.9367-7.811-11.135 1.097-3.1984 6.173-6.3409 13-4.0002 6.828 2.3407 8.908 7.9367 7.811 11.135z" fill="';
        string memory partFive = '" stroke="#161B1F" stroke-width="12"/>';
        return string(abi.encodePacked(partOne, color, partTwo, color, partThree, shadow, partFour, color, partFive));
    }

    function _renderGlasses(IWatchClubPersonRenderer.GlassesType glassesType) private pure returns (string memory) {
        string memory blackLens = '#404042';
        string memory goldLens = '#FBECC8';
        string memory roundPartOne = '<line x1="150" y1="146" x2="174" y2="146" stroke="black" stroke-width="10"/><line x1="236" y1="146" x2="262" y2="146" stroke="black" stroke-width="10" stroke-linecap="round"/><line x1="74" y1="146" x2="84" y2="146" stroke="black" stroke-width="10" stroke-linecap="round"/><circle cx="114" cy="158" r="35" fill="';
        string memory roundPartTwo = '" stroke="black" stroke-width="10"/><circle cx="209" cy="158" r="35" fill="';
        string memory roundPartThree = '" stroke="black" stroke-width="10"/>';
        string memory aviatorPartOne = '<ellipse cx="112" cy="155.96" rx="39" ry="35.963" fill="';
        string memory aviatorPartTwo = '"/><ellipse cx="211" cy="155.96" rx="39" ry="35.963" fill="';
        string memory aviatorPartThree = '"/><path d="m77.745 145.58c5.038-17.058 24.059-21.669 32.94-21.842 8.914 0 18.893 1.387 22.768 2.08 13.951 1.664 17.439 11.788 17.439 16.641-0.775 9.569-2.261 16.815-2.906 19.242-3.488 15.809-16.632 25.308-22.768 28.082-13.176 5.824-26.804 2.427-31.972 0-19.764-7.489-18.569-32.589-15.501-44.203z" stroke="#000" stroke-width="10"/><path d="m245.93 145.06c-5.038-17.057-24.06-21.668-32.941-21.841-8.913 0-18.892 1.386-22.767 2.08-13.952 1.664-17.439 11.787-17.439 16.641 0.775 9.569 2.26 16.815 2.906 19.242 3.488 15.809 16.632 25.308 22.768 28.082 13.176 5.824 26.804 2.426 31.971 0 19.764-7.489 18.57-32.589 15.502-44.204z" stroke="#000" stroke-width="10"/><path d="m152.36 140.63c2.833-1.214 10.4-2.913 18 0" stroke="#000" stroke-width="10"/><line x1="118" x2="202" y1="123.99" y2="123.99" stroke="#000" stroke-width="10"/><line x1="250" x2="260" y1="150.43" y2="150.43" stroke="#000" stroke-linecap="round" stroke-width="10"/><line x1="72" x2="73" y1="150.43" y2="150.43" stroke="#000" stroke-linecap="round" stroke-width="10"/>';

        if (glassesType == IWatchClubPersonRenderer.GlassesType.NONE) {
            return '';
        } else if (glassesType == IWatchClubPersonRenderer.GlassesType.AVIATOR) {
            return string(abi.encodePacked(aviatorPartOne, blackLens, aviatorPartTwo, blackLens, aviatorPartThree));
        } else if (glassesType == IWatchClubPersonRenderer.GlassesType.AVIATOR_GOLD) {
            return string(abi.encodePacked(aviatorPartOne, goldLens, aviatorPartTwo, goldLens, aviatorPartThree));
        } else if (glassesType == IWatchClubPersonRenderer.GlassesType.ROUND) {
            return string(abi.encodePacked(roundPartOne, blackLens, roundPartTwo, blackLens, roundPartThree));
        } else {
            // ROUND_GOLD
            return string(abi.encodePacked(roundPartOne, goldLens, roundPartTwo, goldLens, roundPartThree));
        }
    }

    function _renderBodyAndBackground(
        IWatchClubPersonRenderer.ShirtType shirtType,
        IWatchClubPersonRenderer.BackgroundType backgroundType
    ) private view returns (string memory) {
        string memory partOne = '<g><rect width="380" height="380" fill="';
        string memory partTwo = '"/><rect x="153" y="253" width="94" height="187" fill="';
        string memory partThree = '"/><rect x="196.293" y="266.171" width="53.1566" height="201.704" transform="rotate(-15.3932 196.293 266.171)" fill="';
        string memory partFour = '"/><path d="M239.766 243C228.48 249.211 211.739 272.472 159.331 264.441" stroke="';
        string memory partFive = '" stroke-width="48"/><path d="M127 357C156.599 334.333 221.237 296.337 243 325.69" stroke="#161B1F" stroke-width="12" stroke-linecap="round"/><path d="M153 280C146.39 289.981 131.936 319.356 127 357" stroke="#161B1F" stroke-width="12" stroke-linecap="round"/><path d="M306 154.5C306 215.757 253.278 266 187.5 266C121.722 266 69 215.757 69 154.5C69 93.2426 121.722 43 187.5 43C253.278 43 306 93.2426 306 154.5Z" fill="white" stroke="#161B1F" stroke-width="12"/><path fill-rule="evenodd" clip-rule="evenodd" d="M193.152 273.263C193.218 273.261 193.285 273.259 193.351 273.257C193.352 273.257 193.352 273.257 193.352 273.257C193.285 273.259 193.219 273.261 193.152 273.263ZM258.364 72.6905C276.684 93.3708 288.08 120.12 288.92 149.592C289.962 186.16 274.542 219.468 249.218 242.741C280.786 223.446 301.053 189.368 299.978 151.646C299.068 119.718 283.042 91.2675 258.364 72.6905Z" fill="#E7E3E4"/><path d="M155 263.5C153.667 286.5 150.9 352.4 150.5 440" stroke="#161B1F" stroke-width="12" stroke-linecap="round"/><path d="M242 256C250.333 277.833 272.5 347.9 294.5 453.5" stroke="#161B1F" stroke-width="12" stroke-linecap="round"/><ellipse cx="122.682" cy="141.872" rx="7.68156" ry="11.8715" fill="#161B1F"/><ellipse cx="211.682" cy="141.872" rx="7.68156" ry="11.8715" fill="#161B1F"/><path d="M249.5 278C251.5 309.333 255.8 363.6 251 360C219 337.667 153.7 299.9 148.5 327.5" stroke="#161B1F" stroke-width="12" stroke-linecap="round"/>';
        
        return string(abi.encodePacked(
            partOne, 
            BACKGROUND_COLORS[uint256(backgroundType)],
            partTwo, 
            SHIRT_COLORS[uint256(shirtType)],
            partThree,
            SHIRT_COLORS[uint256(shirtType)], 
            partFour,
            SHIRT_SHADOW_COLORS[uint256(shirtType)],
            partFive
        ));
    }

    function _renderFace(IWatchClubPersonRenderer.MouthType mouthType, IWatchClubPersonRenderer.EarType earType) private pure returns (string memory) {
        string memory mouth;
        string memory airpods = '<line x1="283.408" y1="185.637" x2="279.452" y2="185.05" stroke="#CCCDD1" stroke-width="5"/><path d="M288.108 165.137C287.443 170.064 282.913 173.518 277.99 172.853C273.068 172.189 269.615 167.658 270.28 162.731C270.945 157.804 275.476 154.351 280.398 155.015C285.32 155.679 288.773 160.21 288.108 165.137Z" fill="white" stroke="black" stroke-width="5"/><line x1="279.893" y1="172.491" x2="277.012" y2="191.271" stroke="black" stroke-width="5"/><line x1="288.185" y1="164.623" x2="283.789" y2="193.288" stroke="black" stroke-width="5"/><line x1="286.609" y1="191.231" x2="274.748" y2="189.407" stroke="black" stroke-width="5"/><ellipse cx="276.274" cy="162.371" rx="2.495" ry="2.5" transform="rotate(7.6862 276.274 162.371)" fill="black"/>';
        if (mouthType == IWatchClubPersonRenderer.MouthType.SERIOUS) {
            mouth = '<path d="M174.5 234.5C172.167 232.333 165.4 227.8 157 227" stroke="#161B1F" stroke-width="10" stroke-linecap="round"/>';
        } else {
            mouth = '<path d="M150 232.659C154.5 235 174 238 185 230" stroke="#161B1F" stroke-width="12" stroke-linecap="round"/>';
        }
        if (earType == IWatchClubPersonRenderer.EarType.NONE) {
            return mouth;
        } else {
            return string(abi.encodePacked(
                mouth, 
                airpods
            ));
        }
    }

    function renderPerson(
        IWatchClubPersonRenderer.HatType hatType, 
        IWatchClubPersonRenderer.GlassesType glassesType, 
        IWatchClubPersonRenderer.EarType earType, 
        IWatchClubPersonRenderer.ShirtType shirtType, 
        IWatchClubPersonRenderer.MouthType mouthType, 
        IWatchClubPersonRenderer.BackgroundType backgroundType
    ) public view returns (string memory) {
        string memory bodyAndBackground = _renderBodyAndBackground(shirtType, backgroundType);
        string memory face = _renderFace(mouthType, earType);
        string memory hat = _renderHat(hatType);
        string memory glasses = _renderGlasses(glassesType);
        return string(abi.encodePacked(
            bodyAndBackground, 
            face,
            glasses,
            hat,
            '</g>'
        ));
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IWatchClubPersonRenderer {
    enum HatType { BLACK, BROWN, RED, BLUE, NAVY, LAVENDER, WHITE, DENIM, NONE }
    enum GlassesType { ROUND, AVIATOR, ROUND_GOLD, AVIATOR_GOLD, NONE }
    enum EarType { AIRPODS, NONE }
    enum ShirtType { BLUE, RED, PURPLE, BROWN, NAVY, CREAM, GREY, WHITE}
    enum MouthType { SMILE, SERIOUS }
    enum BackgroundType { CREAM, ICE, SILVER, PLATINUM, BROWN, ROSE, GOLD, OLIVE, PINK}

    function renderPerson(
        HatType hatType, 
        GlassesType glassesType, 
        EarType earType, 
        ShirtType shirtType, 
        MouthType mouthType, 
        BackgroundType backgroundType
    ) external view returns (string memory);
}