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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ICookiData} from "./ICookiData.sol";
import {ICookiCard} from "./ICookiCard.sol";

//Spend some time build these out more - really make an exhaustive list

contract CookiData is ICookiData, Ownable {
    using SafeMath for uint256;

    bool public initialised;

    ICookiCard public cookiCard;

    modifier onlyCookiCard() {
        require(msg.sender == address(cookiCard));
        _;
    }

    constructor() {}

    function init(ICookiCard _cookiCard) external onlyOwner {
        require(!initialised);
        cookiCard = _cookiCard;
        initialised = true;
    }

    //////////////////
    //Load Functions//
    //////////////////

    function loadData() external onlyCookiCard {
        loadDisplaySettings();
        loadBackgroundColours0();
        loadBackgroundColours1();
        loadFaceColours();
        loadHatColours();
        loadNeutralColours();
        loadInitialBacking();
    }

    function loadDisplaySettings() internal {
        NamedDisplaySetting memory _displaySetting0 = NamedDisplaySetting({
            name: "Midrasil",
            display: 0
        });
        NamedDisplaySetting memory _displaySetting1 = NamedDisplaySetting({
            name: "Fryst",
            display: 1
        });
        NamedDisplaySetting memory _displaySetting2 = NamedDisplaySetting({
            name: "Backamir",
            display: 2
        });

        cookiCard.loadDisplaySetting(_displaySetting0);
        cookiCard.loadDisplaySetting(_displaySetting1);
        cookiCard.loadDisplaySetting(_displaySetting2);
    }

    //Mythical/whimsical ficticious words
    function loadBackgroundColours0() internal {
        NamedBackgroundColours memory _backgroundColours0 = NamedBackgroundColours({
            name: "Luminescera",
            colour: "#fff8dc"
        });
        NamedBackgroundColours memory _backgroundColours1 = NamedBackgroundColours({
            name: "Aureldust",
            colour: "#dbc9c9"
        });
        NamedBackgroundColours memory _backgroundColours2 = NamedBackgroundColours({
            name: "Faeleth",
            colour: "#84b4d0"
        });
        NamedBackgroundColours memory _backgroundColours3 = NamedBackgroundColours({
            name: "Vellumia",
            colour: "#d0a7c7"
        });
        NamedBackgroundColours memory _backgroundColours4 = NamedBackgroundColours({
            name: "Sylphidora",
            colour: "#80ebeb"
        });
        NamedBackgroundColours memory _backgroundColours5 = NamedBackgroundColours({
            name: "Meridiania",
            colour: "#dee5e5"
        });
        NamedBackgroundColours memory _backgroundColours6 = NamedBackgroundColours({
            name: "Illusora",
            colour: "#efcd76"
        });
        NamedBackgroundColours memory _backgroundColours7 = NamedBackgroundColours({
            name: "Nimbella",
            colour: "#ed8f90"
        });
        NamedBackgroundColours memory _backgroundColours8 = NamedBackgroundColours({
            name: "Chromatica",
            colour: "#747470"
        });
        NamedBackgroundColours memory _backgroundColours9 = NamedBackgroundColours({
            name: "Faythorn",
            colour: "#69a975"
        });
        NamedBackgroundColours memory _backgroundColours10 = NamedBackgroundColours({
            name: "Arcanora",
            colour: "#8467a9"
        });
        NamedBackgroundColours memory _backgroundColours11 = NamedBackgroundColours({
            name: "Hydrorosea",
            colour: "#df6cc3"
        });
        NamedBackgroundColours memory _backgroundColours12 = NamedBackgroundColours({
            name: "Glissandria",
            colour: "#f18c51"
        });
        NamedBackgroundColours memory _backgroundColours13 = NamedBackgroundColours({
            name: "Aetherion",
            colour: "#1fc29f"
        });

        cookiCard.loadBackgroundColours(_backgroundColours0);
        cookiCard.loadBackgroundColours(_backgroundColours1);
        cookiCard.loadBackgroundColours(_backgroundColours2);
        cookiCard.loadBackgroundColours(_backgroundColours3);
        cookiCard.loadBackgroundColours(_backgroundColours4);
        cookiCard.loadBackgroundColours(_backgroundColours5);
        cookiCard.loadBackgroundColours(_backgroundColours6);
        cookiCard.loadBackgroundColours(_backgroundColours7);
        cookiCard.loadBackgroundColours(_backgroundColours8);
        cookiCard.loadBackgroundColours(_backgroundColours9);
        cookiCard.loadBackgroundColours(_backgroundColours10);
        cookiCard.loadBackgroundColours(_backgroundColours11);
        cookiCard.loadBackgroundColours(_backgroundColours12);
        cookiCard.loadBackgroundColours(_backgroundColours13);
    }

    function loadBackgroundColours1() internal {
        NamedBackgroundColours memory _backgroundColours14 = NamedBackgroundColours({
            name: "Nivaria",
            colour: "#79916f"
        });

        cookiCard.loadBackgroundColours(_backgroundColours14);
    }

    //Crystals
    function loadFaceColours() internal {
        NamedFaceColours memory _faceColours0 = NamedFaceColours({
            name: "Prismarine",
            light: "#896bef",
            dark: "#2d0ba7"
        });
        NamedFaceColours memory _faceColours1 = NamedFaceColours({
            name: "Diamorite",
            light: "#68bee1",
            dark: "#0b7ba7"
        });
        NamedFaceColours memory _faceColours2 = NamedFaceColours({
            name: "Aetherionite",
            light: "#c8a968",
            dark: "#a37306"
        });
        NamedFaceColours memory _faceColours3 = NamedFaceColours({
            name: "Shimmerstone",
            light: "#6475b8",
            dark: "#082084"
        });
        NamedFaceColours memory _faceColours4 = NamedFaceColours({
            name: "Crystulite",
            light: "#9d95a5",
            dark: "#48444d"
        });
        NamedFaceColours memory _faceColours5 = NamedFaceColours({
            name: "Radianceite",
            light: "#499568",
            dark: "#025524"
        });
        NamedFaceColours memory _faceColours6 = NamedFaceColours({
            name: "Illunyx",
            light: "#af60a2",
            dark: "#5b014a"
        });
        NamedFaceColours memory _faceColours7 = NamedFaceColours({
            name: "Valtairite",
            light: "#eb885e",
            dark: "#8e2c02"
        });
        NamedFaceColours memory _faceColours8 = NamedFaceColours({
            name: "Xyloflorite",
            light: "#d55d6b",
            dark: "#8e0214"
        });
        NamedFaceColours memory _faceColours9 = NamedFaceColours({
            name: "Illunylite",
            light: "#ac74df",
            dark: "#500095"
        });
        NamedFaceColours memory _faceColours10 = NamedFaceColours({
            name: "Plasmalith",
            light: "#e371b3",
            dark: "#99085d"
        });
        NamedFaceColours memory _faceColours11 = NamedFaceColours({
            name: "Spectracryst",
            light: "#71a59a",
            dark: "#044d41"
        });

        cookiCard.loadFaceColours(_faceColours0);
        cookiCard.loadFaceColours(_faceColours1);
        cookiCard.loadFaceColours(_faceColours2);
        cookiCard.loadFaceColours(_faceColours3);
        cookiCard.loadFaceColours(_faceColours4);
        cookiCard.loadFaceColours(_faceColours5);
        cookiCard.loadFaceColours(_faceColours6);
        cookiCard.loadFaceColours(_faceColours7);
        cookiCard.loadFaceColours(_faceColours8);
        cookiCard.loadFaceColours(_faceColours9);
        cookiCard.loadFaceColours(_faceColours10);
        cookiCard.loadFaceColours(_faceColours11);
    }

    //Gases
    function loadHatColours() internal {
        NamedHatColours memory _hatColours0 = NamedHatColours({
            name: "Helixir",
            light: "#f8869d",
            medium: "#dc143c",
            dark: "#740e23"
        });
        NamedHatColours memory _hatColours1 = NamedHatColours({
            name: "Celestros",
            light: "#635ab5",
            medium: "#2717ed",
            dark: "#100880"
        });
        NamedHatColours memory _hatColours2 = NamedHatColours({
            name: "Terravapor",
            light: "#e576ed",
            medium: "#e216f1",
            dark: "#870891"
        });
        NamedHatColours memory _hatColours3 = NamedHatColours({
            name: "Zephyronite",
            light: "#79e178",
            medium: "#0eb80c",
            dark: "#025d01"
        });
        NamedHatColours memory _hatColours4 = NamedHatColours({
            name: "Sylpholite",
            light: "#d375e7",
            medium: "#bf11e5",
            dark: "#700388"
        });
        NamedHatColours memory _hatColours5 = NamedHatColours({
            name: "Oceirium",
            light: "#e39f4f",
            medium: "#dc7a05",
            dark: "#a35903"
        });
        NamedHatColours memory _hatColours6 = NamedHatColours({
            name: "Fraxionyx",
            light: "#5acfea",
            medium: "#05b4d5",
            dark: "#03819a"
        });
        NamedHatColours memory _hatColours7 = NamedHatColours({
            name: "Nepturionite",
            light: "#69dfa0",
            medium: "#13cc69",
            dark: "#008c3e"
        });
        NamedHatColours memory _hatColours8 = NamedHatColours({
            name: "Alchemirine",
            light: "#a5a5a8",
            medium: "#6f6f73",
            dark: "#3d3d3f"
        });
        NamedHatColours memory _hatColours9 = NamedHatColours({
            name: "Eurydilith",
            light: "#a55454",
            medium: "#af0c0c",
            dark: "#610303"
        });

        cookiCard.loadHatColours(_hatColours0);
        cookiCard.loadHatColours(_hatColours1);
        cookiCard.loadHatColours(_hatColours2);
        cookiCard.loadHatColours(_hatColours3);
        cookiCard.loadHatColours(_hatColours4);
        cookiCard.loadHatColours(_hatColours5);
        cookiCard.loadHatColours(_hatColours6);
        cookiCard.loadHatColours(_hatColours7);
        cookiCard.loadHatColours(_hatColours8);
        cookiCard.loadHatColours(_hatColours9);
    }

    //Liquids
    function loadNeutralColours() internal {
        NamedNeutralColours memory _neutralColours0 = NamedNeutralColours({
            name: "Maelstromix",
            skin: "#cfc497",
            border: "#000000"
        });
        NamedNeutralColours memory _neutralColours1 = NamedNeutralColours({
            name: "Astralum",
            skin: "#969176",
            border: "#000000"
        });
        NamedNeutralColours memory _neutralColours2 = NamedNeutralColours({
            name: "Glitterine",
            skin: "#756c59",
            border: "#000000"
        });

        cookiCard.loadNeutralColours(_neutralColours0);
        cookiCard.loadNeutralColours(_neutralColours1);
        cookiCard.loadNeutralColours(_neutralColours2);
    }

    function loadInitialBacking() internal {
        //Style it in terms of a business card? At the very least add some more flair to it - fix later

        string memory newBackString = '<rect width="100%" height="100%" fill="black" /><style>.std {fill: cornsilk; font-family: serif; font-size: 50px; text-anchor: middle;}</style><text x="120" y="80" class="std">GM</text>';
        string memory newAnimationValues = "1;1;1;0;0;1";
        string memory newAnimationDuration = "12s";

        cookiCard.changeBackString(newBackString);
        cookiCard.changeAnimationValues(newAnimationValues);
        cookiCard.changeAnimationDuration(newAnimationDuration);
    }

    ////////////////
    //Manual Loads//
    ////////////////

    //Allow for manual addition of colour pallettes?
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {ICookiStructs} from "./ICookiStructs.sol";

interface ICookiCard is ICookiStructs {
    function changeBackString(string memory _newBackString) external;

    function changeAnimationValues(string memory _newAnimationValues) external;

    function changeAnimationDuration(string memory _newAnimationDuration) external;

    function loadDisplaySetting(NamedDisplaySetting memory _namedDisplaySetting) external;

    function loadBackgroundColours(NamedBackgroundColours memory _namedBackgroundColours) external;

    function loadFaceColours(NamedFaceColours memory _namedFaceColours) external;

    function loadHatColours(NamedHatColours memory _namedHatColours) external;

    function loadNeutralColours(NamedNeutralColours memory _namedNeutralColours) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {ICookiStructs} from "./ICookiStructs.sol";
import {ICookiCard} from "./ICookiCard.sol";

interface ICookiData is ICookiStructs {
    function loadData() external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface ICookiStructs {
    struct NamedDisplaySetting {
        string name;
        uint256 display;
    }

    struct NamedBackgroundColours {
        string name;
        string colour;
    }

    struct NamedFaceColours {
        string name;
        string light;
        string dark;
    }

    struct NamedHatColours {
        string name;
        string light;
        string medium;
        string dark;
    }

    struct NamedNeutralColours {
        string name;
        string skin;
        string border;
    }
}