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
import "./interfaces/IWatchClubWatchRenderer.sol";
import "./interfaces/IWatchClubRenderer.sol";
import "./interfaces/IWatchClubPersonRenderer.sol";

// TODO: update function visibilities

contract WatchClubRenderer is Ownable, IWatchClubRenderer {
    error TraitNotFound();

    address public watchRenderer;
    address public personRenderer;
    
    constructor() {}

    function setPersonRenderer(address _personRenderer) external onlyOwner {
        personRenderer = _personRenderer;
    }

    function setWatchRenderer(address _watchRenderer) external onlyOwner {
        watchRenderer = _watchRenderer;
    }

    function _getTraitNumberFromWeightsArray(uint8[10] memory weightsArray, uint16 numberFromDna) public pure returns (uint8) {
        uint8 i;
        for (; i < weightsArray.length;) {
            if (weightsArray[i] >= numberFromDna) {
                return i;
            }
            ++i;
        }
        revert TraitNotFound();
    }

    // same with getTraitNumberFromWeightsArray, just with an 64 length
    function _getWatchType(uint16[64] memory weightsArray, uint16 numberFromDna) public pure returns (uint8) {
        uint8 i;
        for (; i < weightsArray.length;) {
            if (weightsArray[i] >= numberFromDna) {
                return i;
            }
            ++i;
        }
        revert TraitNotFound();
    }

    function splitDna(uint256 dna) public pure returns (uint16[7] memory) {
        uint16[7] memory numbers;
        uint256 i;
        unchecked {
            for (; i < numbers.length; ) {
                if (i == 0) {
                    numbers[i] = uint16(dna % 1000);
                    dna /= 1000;
                } else {
                    numbers[i] = uint16(dna % 100);
                    dna /= 100;
                }
                ++i;
            }
            return numbers;
        }
    }

    function renderWatch(uint256 dna) public view returns (string memory) {
        uint16[64] memory WATCH_WEIGHTS = [
            2, 8, 14, 20, 25,  // PP
            31, 37, 43, 49, 54, 59, 62,  // AP
            69, 76, 83, 89,  // VC
            107, 125, 135, 153, 163, 173, 183, 193, 203,  // SUB
            211, 219,  // YACHT
            231, 243, 255, 267, 272, 284, 296,  // OP
            308, 320, 332, 344, 354,  // DJ
            364, 374,  // EXP
            384, 394, 404, 412, 420, 425, 430,  // DD
            445, 460, 475, 490,  // AQUA
            500, 510, 520, 525,  // PILOT
            527,  // SENATOR
            537,  // GS
            547, 555, 563,  // TANK
            565, 567, 569  // TANK F
        ];
        uint16[7] memory numbersFromDna = splitDna(dna);
        string memory watch = IWatchClubWatchRenderer(watchRenderer).renderWatch(
            IWatchClubWatchRenderer.WatchType(_getWatchType(WATCH_WEIGHTS, numbersFromDna[0]))
        );
        return watch;

    }

    function renderPerson(uint256 dna) public view returns (string memory) {
        uint8[10] memory GLASSES_WEIGHTS = [24, 49, 59, 69, 99, 0, 0, 0, 0, 0];
        uint8[10] memory EAR_WEIGHTS = [19, 99, 0, 0, 0, 0, 0, 0, 0, 0];
        uint8[10] memory SHIRT_WEIGHTS = [12, 25, 37, 50, 63, 75, 87, 99, 0, 0];
        uint8[10] memory MOUTH_WEIGHTS = [49, 99, 0, 0, 0, 0, 0, 0, 0, 0];
        uint8[10] memory BACKGROUND_WEIGHTS = [12, 25, 37, 50, 63, 75, 87, 99, 0, 0];
        uint8[10][10] memory HAT_WEIGHTS;
        // To prevent shirt + hat combos that look bad, HAT_WEIGHTS[x][y] is a 2D array where x is the shirt type and y is the hat type
        HAT_WEIGHTS[0] = [14, 28, 0, 42, 56, 70, 84, 0, 99, 0];
        HAT_WEIGHTS[1] = [16, 33, 49, 66, 0, 0, 83, 0, 99, 0];
        HAT_WEIGHTS[2] = [14, 28, 0, 42, 56, 70, 84, 0, 99, 0];
        HAT_WEIGHTS[3] = [16, 33, 0, 49,66, 0, 83, 0, 99, 0];
        HAT_WEIGHTS[4] = [19, 0, 0, 39, 0, 59, 79, 0, 99, 0];
        HAT_WEIGHTS[5] = [14, 28, 0, 42, 0, 56, 70, 84, 99, 0];
        HAT_WEIGHTS[6] = [16, 0, 0, 0, 33, 49, 66, 83, 99, 0];
        HAT_WEIGHTS[7] = [11, 22, 33, 44, 55, 66, 77, 88, 99, 0];

        uint16[7] memory numbersFromDna = splitDna(dna);
        uint8 shirt = _getTraitNumberFromWeightsArray(SHIRT_WEIGHTS, numbersFromDna[4]);
        string memory person = IWatchClubPersonRenderer(personRenderer).renderPerson(
            IWatchClubPersonRenderer.HatType(_getTraitNumberFromWeightsArray(HAT_WEIGHTS[shirt], numbersFromDna[1])),
            IWatchClubPersonRenderer.GlassesType(_getTraitNumberFromWeightsArray(GLASSES_WEIGHTS, numbersFromDna[2])),
            IWatchClubPersonRenderer.EarType(_getTraitNumberFromWeightsArray(EAR_WEIGHTS, numbersFromDna[3])),
            IWatchClubPersonRenderer.ShirtType(shirt),
            IWatchClubPersonRenderer.MouthType(_getTraitNumberFromWeightsArray(MOUTH_WEIGHTS, numbersFromDna[5])),
            IWatchClubPersonRenderer.BackgroundType(_getTraitNumberFromWeightsArray(BACKGROUND_WEIGHTS, numbersFromDna[6]))
        );
        return person;
    }

    function tokenURI(uint256 tokenId, uint256 dna) external pure returns (string memory) {
        // TODO: fill this out
        return string(abi.encodePacked(
            tokenId,
            dna
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IWatchClubRenderer {

    function tokenURI(uint256 tokenId, uint256 dna) external view returns (string memory);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IWatchClubWatchRenderer {
    enum WatchType { 
        // 0
        PP_TIFFANY, PP_BLUE, PP_GREEN, PP_WHITE, PP_CHOCOLATE,
        // 5
        AP_WHITE, AP_BLUE, AP_GREY, AP_BLACK, AP_BLUE_RG, AP_BLACK_RG, AP_BLACK_CERAMIC,
        // 12
        VC_BLUE, VC_BLACK, VC_WHITE, VC_BLUE_RG,
        // 16
        SUB_BLACK, SUB_GREEN, SUB_BLUE, SUB_GREEN_BLACK, SUB_BLUE_BLACK, SUB_BLACK_TT, SUB_BLUE_TT, SUB_BLACK_YG, SUB_BLUE_YG,
        // 25
        YACHT_RHODIUM, YACHT_BLUE,
        // 27
        OP_YELLOW, OP_GREEN, OP_CORAL, OP_TIFFANY, OP_PINK, OP_BLACK, OP_BLUE,
        // 34
        DJ_WHITE, DJ_BLUE, DJ_RHODIUM, DJ_BLACK, DJ_CHAMPAGNE_TT,
        // 39
        EXP, EXP_TT,
        // 41
        DD_WHITE_YG, DD_CHAMPAGNE_YG, DD_BLACK_YG, DD_OLIVE_RG, DD_CHOCOLATE_RG, DD_ICE_P, DD_OLIVE_P,
        // 48
        AQ_WHITE, AQ_BLUE, AQ_GREY, AQ_BLACK,
        // 52
        PILOT_BLACK, PILOT_WHITE, PILOT_BLUE, PILOT_TG, 
        // 56
        SENATOR,
        // 57
        GS,
        // 58
        TANK, TANK_RG, TANK_YG,
        // 61
        TANK_F, TANK_F_RG, TANK_F_YG
    }

    function renderWatch(WatchType watchType)
        external
        view
        returns (string memory);
        
}