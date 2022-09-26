// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.15;
import '@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol';
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./library/StringUtils.sol";
import "./library/Structs.sol";
import "./library/Base64.sol";
import "./library/NogBuilder.sol";

contract NogsDescriptorV1 is Initializable, OwnableUpgradeable {
    using StringsUpgradeable for uint256;
    using StringsUpgradeable for uint160;
    using StringUtils for string;
    using NogBuilder for string;

    /* 
    ⌐◨—————————————————————————————————————————————————————————————◨
                                set state
    ⌐◨—————————————————————————————————————————————————————————————◨ */    
    Structs.NogStyle[] private NogStyles;
    address private _owner;
    string public basePath;
    string public eyesPath;
    string public shadowPath;
    string public shadowAnimate;
    string public nogAnimate;
    string[5] public styleNames;
    string[5] public stylePaths;
    string[7] public shades;
    string[8] public backgroundStyles;
    uint8[5] public frameColorLength;
    string public description;
    string public name;
    bool public floatingNogs;

    function initialize(address owner) public initializer {
        _owner = owner;
        basePath = string(abi.encodePacked('<path class="a" d="M10 50v10h5V50h-5Zm15-5H10v5h15v-5Zm35 0h-5v5h5v-5ZM25 35v30h30V35H25Zm35 0v30h30V35H60Z"/>'));
        eyesPath = string(abi.encodePacked('<path fill="#fff" d="M30 40v20h10V40H30Z"/><path fill="#000" d="M40 40v20h10V40H40Z"/><path fill="#fff" d="M65 40v20h10V40H65Z"/><path fill="#000" d="M75 40v20h10V40H75Z"/>'));
        shadowPath = string(abi.encodePacked('<defs><filter id="sh" color-interpolation-filters="sRGB" filterUnits="userSpaceOnUse"><feGaussianBlur stdDeviation="4"/></filter></defs><g filter="url(#sh)" opacity="0.33"><path fill="#000" d="M81 84.875c0 1.035-11.529 1.875-25.75 1.875s-25.75-.84-25.75-1.875C29.5 83.84 41.029 83 55.25 83S81 83.84 81 84.875Z"/></g>'));
        shadowAnimate = string(abi.encodePacked('<defs><filter id="sh" color-interpolation-filters="sRGB" filterUnits="userSpaceOnUse"><feGaussianBlur stdDeviation="4"/></filter></defs><g filter="url(#sh)" opacity=".33"><animateTransform attributeName="transform" type="scale" values="1; 0.95; 1; 0.95; 1" dur="8s" repeatCount="indefinite"/><path fill="#000" d="M81 84.875c0 1.035-11.529 1.875-25.75 1.875s-25.75-.84-25.75-1.875C29.5 83.84 41.029 83 55.25 83S81 83.84 81 84.875Z"/></g>'));
        styleNames = [
            string(abi.encodePacked('Standard')),
            string(abi.encodePacked('Multi-color')),
            string(abi.encodePacked('Tri-color')),
            string(abi.encodePacked('Solid-color')),
            string(abi.encodePacked('Hip'))
        ];
        backgroundStyles = [
            string(abi.encodePacked('Standard')),
            string(abi.encodePacked('Cool')),
            string(abi.encodePacked('Warm')),
            string(abi.encodePacked('Mono')),
            string(abi.encodePacked('Mesh gradient')),
            string(abi.encodePacked('Radial gradient')),
            string(abi.encodePacked('Linear gradient')),
            string(abi.encodePacked('Light gradient'))
        ];
        
        frameColorLength = [1, 2, 3, 1, 1];
        stylePaths = [
            string(abi.encodePacked(basePath, eyesPath)),
            string(abi.encodePacked(basePath, eyesPath, '<path class="b" d="M25 35v30h30V35H25Zm25 15v10H30V40h20v10Z"/>')),
            string(abi.encodePacked(basePath, '<path fill="#000" d="M10 50v10h5V50h-5Zm15-5H10v5h15v-5Zm35 0h-5v5h5v-5ZM25 35v30h30V35H25Zm35 0v30h30V35H60Z"/><path class="a" fill="#ff0e0e" d="M45 40h-5v5h5v-5Zm35 0h-5v5h5v-5Z"/><path class="b" fill="#0adc4d" d="M35 50h-5v5h5v-5Z"/><path class="c" fill="#1929f4" d="M50 50h-5v5h5v-5Z"/><path class="b" fill="#0adc4d" d="M70 50h-5v5h5v-5Z"/><path class="c" fill="#1929f4" d="M85 50h-5v5h5v-5Z"/>')),
            string(abi.encodePacked(basePath, "<path class='y' d='M45 45v5h5V40h-5zm35-5h5v10h-5z' />")),
            string(abi.encodePacked(basePath, '<path class="a" d="M25 50H10V55H25V50ZM60 50H55V55H60V50Z"/>', eyesPath))
        ];
        nogAnimate = string(abi.encodePacked('<defs><path xmlns="http://www.w3.org/2000/svg" id="nogs" d="M53.5 41.2c-.2.7-.3 1.8 0 1.8s.2-1 0-1.8zm0 0c-.2-.8-.3-1.7 0-1.7s.2 1 0 1.7z"/></defs><animateMotion xmlns="http://www.w3.org/2000/svg" dur="8s" repeatCount="indefinite" calcMode="linear"><mpath xmlns:xlink="http://www.w3.org/1999/xlink" xlink:href="#nogs"/></animateMotion>'));
        shades = [string(abi.encodePacked('rgba(255,255,255,0.45)')), string(abi.encodePacked('rgba(255,255,255,0.35)')), string(abi.encodePacked('rgba(255,255,255,0.25)')), string(abi.encodePacked('rgba(0,0,0,0.45)')), string(abi.encodePacked('rgba(0,0,0,0.35)')), string(abi.encodePacked('rgba(0,0,0,0.25)')), string(abi.encodePacked('rgba(0,0,0,0.15)'))];
        description = string(abi.encodePacked('nogs.wtf is a celebration of Nouns'));
        floatingNogs = true;

        // Run style setter
        setNogStyles();
    }
    
    function setNogStyles() public {
        require(msg.sender == _owner, 'Rejected: not owner');
        for (uint8 i = 0; i < styleNames.length; i++) {
            Structs.NogStyle memory NogStyle = Structs.NogStyle(styleNames[i], stylePaths[i], frameColorLength[i]); // This declaration shadows an existing declaration.
            NogStyles.push(NogStyle);
        }
    }

    /* 
    ⌐◨—————————————————————————————————————————————————————————————◨
                               get parts
    ⌐◨—————————————————————————————————————————————————————————————◨ */  

    function getColors(address minterAddress) internal pure returns (string[7] memory) {
        string memory addr = uint160(minterAddress).toHexString(20);
        string memory color;
        string[7] memory list;
        for (uint i; i < 7; ++i) {
            if (i == 0) {
                color = addr._substring(6, 2);
            } else if (i == 1) {
                color = addr._substring(6, int(i) * 8);
            } else {
                color = addr._substring(6, int(i) * 6);
            }
            list[i] = color;
        }    
        return list;
    }

    function buildSeed(Structs.Nog memory nog, uint256 tokenId) internal view returns (Structs.Seed memory seed) {
        string memory shadow;
        string memory shadowAnimation;
        string memory nogAnimation;

        if (nog.hasShadow == true) {
            shadow = shadowPath;
        }
        if (nog.hasAnimation == true && floatingNogs == true) {
            shadowAnimation = shadowAnimate;
            nogAnimation = nogAnimate;
        }

        seed = Structs.Seed({
            tokenId: tokenId,
            minterAddress: nog.minterAddress, 
            colorPalette: nog.colorPalette,
            colors: getColors(nog.minterAddress),
            nogStyle: nog.nogStyle,
            nogStyleName: NogStyles[nog.nogStyle].name,
            nogShape: NogStyles[nog.nogStyle].shape,
            frameColorLength: NogStyles[nog.nogStyle].frameColorLength,
            backgroundStyle: nog.backgroundStyle,
            backgroundStyleName: backgroundStyles[nog.backgroundStyle],
            shade: shades[nog.colorPalette[6]],            
            shadow: shadow, 
            shadowAnimation: shadowAnimation,
            hasAnimation: nog.hasAnimation
        });
    }

    function constructTokenURI(Structs.Nog memory nog, uint256 tokenId) external view returns (string memory) {
        Structs.Seed memory seed = buildSeed(nog, tokenId);
        Structs.NogParts memory nogParts = NogBuilder.buildParts(seed);

        return
            string(
                abi.encodePacked(
                    'data:application/json;base64,',
                    Base64.encode(
                        bytes(
                            string(
                                abi.encodePacked(
                                    '{"name": "Nogs #', abi.encodePacked(string(tokenId.toString())),'",',
                                    '"description": "', abi.encodePacked(string(description)), '",',
                                    '"image": "data:image/svg+xml;base64,', abi.encodePacked(string(nogParts.image)),'", ',
                                    '"attributes": [',
                                        NogBuilder.getAttributesMetadata(seed),
                                    ']',
                                    ', "palette": [',
                                        string(abi.encodePacked(nogParts.colorPalette)),
                                    ']}'
                                )
                            )
                        )
                    )
                )
            );
    }

    /*
    ⌐◨—————————————————————————————————————————————————————————————◨
                           utility functions
    ⌐◨—————————————————————————————————————————————————————————————◨ 
    */  

    function setDescription(string memory _description) external {
        require(msg.sender == _owner, 'Rejected: not owner');

        description = _description;
    }

    function getPseudorandomness(uint tokenId, uint num) external view returns (uint256 pseudorandomness) {        
        return uint256(keccak256(abi.encodePacked(num * tokenId * tokenId + 1, msg.sender, blockhash(block.number - 1))));
    }

    function getStylesCount() external view returns (uint16 stylesCount) {
        stylesCount = uint16(styleNames.length);
    }

    function getBackgroundIndex(uint16 backgroundOdds) external pure returns (uint16 backgroundIndex) {
        backgroundIndex = 0;
        if (backgroundOdds >= 45 && backgroundOdds < 49) { backgroundIndex = 1; }
        if (backgroundOdds >= 50 && backgroundOdds < 54) { backgroundIndex = 2; }
        if (backgroundOdds >= 55 && backgroundOdds < 67) { backgroundIndex = 3; }
        if (backgroundOdds >= 68 && backgroundOdds < 75) { backgroundIndex = 4; }
        if (backgroundOdds >= 75 && backgroundOdds < 82) { backgroundIndex = 5; }
        if (backgroundOdds >= 82 && backgroundOdds < 91) { backgroundIndex = 6; }
        if (backgroundOdds >= 91 && backgroundOdds < 100) { backgroundIndex = 7; }
        
        return backgroundIndex;
    }

    function toggleFloatingNogs() external {
        require(msg.sender == _owner, 'Rejected: not owner');

        floatingNogs = !floatingNogs;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library CountersUpgradeable {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
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
library SafeMathUpgradeable {
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

pragma solidity ^0.8.15;

/**
 * Strings Library
 * 
 * In summary this is a simple library of string functions which make simple 
 * string operations less tedious in solidity.
 * 
 * Please be aware these functions can be quite gas heavy so use them only when
 * necessary not to clog the blockchain with expensive transactions.
 * 
 * @author James Lockhart <[email protected]>
 */

library StringUtils {

    /**
     * Concat (High gas cost)
     * 
     * Appends two strings together and returns a new value
     * 
     * @param _base When being used for a data type this is the extended object
     *              otherwise this is the string which will be the concatenated
     *              prefix
     * @param _value The value to be the concatenated suffix
     * @return string The resulting string from combinging the base and value
     */
    function concat(string memory _base, string memory _value)
        internal
        pure
        returns (string memory) {
        bytes memory _baseBytes = bytes(_base);
        bytes memory _valueBytes = bytes(_value);

        assert(_valueBytes.length > 0);

        string memory _tmpValue = new string(_baseBytes.length +
            _valueBytes.length);
        bytes memory _newValue = bytes(_tmpValue);

        uint i;
        uint j;

        for (i = 0; i < _baseBytes.length; i++) {
            _newValue[j++] = _baseBytes[i];
        }

        for (i = 0; i < _valueBytes.length; i++) {
            _newValue[j++] = _valueBytes[i];
        }

        return string(_newValue);
    }

    /**
     * Index Of
     *
     * Locates and returns the position of a character within a string
     * 
     * @param _base When being used for a data type this is the extended object
     *              otherwise this is the string acting as the haystack to be
     *              searched
     * @param _value The needle to search for, at present this is currently
     *               limited to one character
     * @return int The position of the needle starting from 0 and returning -1
     *             in the case of no matches found
     */
    function indexOf(string memory _base, string memory _value)
        internal
        pure
        returns (int) {
        return _indexOf(_base, _value, 0);
    }

    /**
     * Index Of
     *
     * Locates and returns the position of a character within a string starting
     * from a defined offset
     * 
     * @param _base When being used for a data type this is the extended object
     *              otherwise this is the string acting as the haystack to be
     *              searched
     * @param _value The needle to search for, at present this is currently
     *               limited to one character
     * @param _offset The starting point to start searching from which can start
     *                from 0, but must not exceed the length of the string
     * @return int The position of the needle starting from 0 and returning -1
     *             in the case of no matches found
     */
    function _indexOf(string memory _base, string memory _value, uint _offset)
        internal
        pure
        returns (int) {
        bytes memory _baseBytes = bytes(_base);
        bytes memory _valueBytes = bytes(_value);

        assert(_valueBytes.length == 1);

        for (uint i = _offset; i < _baseBytes.length; i++) {
            if (_baseBytes[i] == _valueBytes[0]) {
                return int(i);
            }
        }

        return -1;
    }

    /**
     * Length
     * 
     * Returns the length of the specified string
     * 
     * @param _base When being used for a data type this is the extended object
     *              otherwise this is the string to be measured
     * @return uint The length of the passed string
     */
    function length(string memory _base)
        internal
        pure
        returns (uint) {
        bytes memory _baseBytes = bytes(_base);
        return _baseBytes.length;
    }

    /**
     * Sub String
     * 
     * Extracts the beginning part of a string based on the desired length
     * 
     * @param _base When being used for a data type this is the extended object
     *              otherwise this is the string that will be used for 
     *              extracting the sub string from
     * @param _length The length of the sub string to be extracted from the base
     * @return string The extracted sub string
     */
    function substring(string memory _base, int _length)
        internal
        pure
        returns (string memory) {
        return _substring(_base, _length, 0);
    }

    /**
     * Sub String
     * 
     * Extracts the part of a string based on the desired length and offset. The
     * offset and length must not exceed the lenth of the base string.
     * 
     * @param _base When being used for a data type this is the extended object
     *              otherwise this is the string that will be used for 
     *              extracting the sub string from
     * @param _length The length of the sub string to be extracted from the base
     * @param _offset The starting point to extract the sub string from
     * @return string The extracted sub string
     */
    function _substring(string memory _base, int _length, int _offset)
        internal
        pure
        returns (string memory) {
        bytes memory _baseBytes = bytes(_base);

        assert(uint(_offset + _length) <= _baseBytes.length);

        string memory _tmp = new string(uint(_length));
        bytes memory _tmpBytes = bytes(_tmp);

        uint j = 0;
        for (uint i = uint(_offset); i < uint(_offset + _length); i++) {
            _tmpBytes[j++] = _baseBytes[i];
        }

        return string(_tmpBytes);
    }


    function split(string memory _base, string memory _value)
        internal
        pure
        returns (string[] memory splitArr) {
        bytes memory _baseBytes = bytes(_base);

        uint _offset = 0;
        uint _splitsCount = 1;
        while (_offset < _baseBytes.length - 1) {
            int _limit = _indexOf(_base, _value, _offset);
            if (_limit == -1)
                break;
            else {
                _splitsCount++;
                _offset = uint(_limit) + 1;
            }
        }

        splitArr = new string[](_splitsCount);

        _offset = 0;
        _splitsCount = 0;
        while (_offset < _baseBytes.length - 1) {

            int _limit = _indexOf(_base, _value, _offset);
            if (_limit == - 1) {
                _limit = int(_baseBytes.length);
            }

            string memory _tmp = new string(uint(_limit) - _offset);
            bytes memory _tmpBytes = bytes(_tmp);

            uint j = 0;
            for (uint i = _offset; i < uint(_limit); i++) {
                _tmpBytes[j++] = _baseBytes[i];
            }
            _offset = uint(_limit) + 1;
            splitArr[_splitsCount++] = string(_tmpBytes);
        }
        return splitArr;
    }

    /**
     * Compare To
     * 
     * Compares the characters of two strings, to ensure that they have an 
     * identical footprint
     * 
     * @param _base When being used for a data type this is the extended object
     *               otherwise this is the string base to compare against
     * @param _value The string the base is being compared to
     * @return bool Simply notates if the two string have an equivalent
     */
    function compareTo(string memory _base, string memory _value)
        internal
        pure
        returns (bool) {
        bytes memory _baseBytes = bytes(_base);
        bytes memory _valueBytes = bytes(_value);

        if (_baseBytes.length != _valueBytes.length) {
            return false;
        }

        for (uint i = 0; i < _baseBytes.length; i++) {
            if (_baseBytes[i] != _valueBytes[i]) {
                return false;
            }
        }

        return true;
    }

    /**
     * Compare To Ignore Case (High gas cost)
     * 
     * Compares the characters of two strings, converting them to the same case
     * where applicable to alphabetic characters to distinguish if the values
     * match.
     * 
     * @param _base When being used for a data type this is the extended object
     *               otherwise this is the string base to compare against
     * @param _value The string the base is being compared to
     * @return bool Simply notates if the two string have an equivalent value
     *              discarding case
     */
    function compareToIgnoreCase(string memory _base, string memory _value)
        internal
        pure
        returns (bool) {
        bytes memory _baseBytes = bytes(_base);
        bytes memory _valueBytes = bytes(_value);

        if (_baseBytes.length != _valueBytes.length) {
            return false;
        }

        for (uint i = 0; i < _baseBytes.length; i++) {
            if (_baseBytes[i] != _valueBytes[i] &&
            _upper(_baseBytes[i]) != _upper(_valueBytes[i])) {
                return false;
            }
        }

        return true;
    }

    /**
     * Upper
     * 
     * Converts all the values of a string to their corresponding upper case
     * value.
     * 
     * @param _base When being used for a data type this is the extended object
     *              otherwise this is the string base to convert to upper case
     * @return string 
     */
    function upper(string memory _base)
        internal
        pure
        returns (string memory) {
        bytes memory _baseBytes = bytes(_base);
        for (uint i = 0; i < _baseBytes.length; i++) {
            _baseBytes[i] = _upper(_baseBytes[i]);
        }
        return string(_baseBytes);
    }

    /**
     * Lower
     * 
     * Converts all the values of a string to their corresponding lower case
     * value.
     * 
     * @param _base When being used for a data type this is the extended object
     *              otherwise this is the string base to convert to lower case
     * @return string 
     */
    function lower(string memory _base)
        internal
        pure
        returns (string memory) {
        bytes memory _baseBytes = bytes(_base);
        for (uint i = 0; i < _baseBytes.length; i++) {
            _baseBytes[i] = _lower(_baseBytes[i]);
        }
        return string(_baseBytes);
    }

    /**
     * Upper
     * 
     * Convert an alphabetic character to upper case and return the original
     * value when not alphabetic
     * 
     * @param _b1 The byte to be converted to upper case
     * @return bytes1 The converted value if the passed value was alphabetic
     *                and in a lower case otherwise returns the original value
     */
    function _upper(bytes1 _b1)
        private
        pure
        returns (bytes1) {

        if (_b1 >= 0x61 && _b1 <= 0x7A) {
            return bytes1(uint8(_b1) - 32);
        }

        return _b1;
    }

    /**
     * Lower
     * 
     * Convert an alphabetic character to lower case and return the original
     * value when not alphabetic
     * 
     * @param _b1 The byte to be converted to lower case
     * @return bytes1 The converted value if the passed value was alphabetic
     *                and in a upper case otherwise returns the original value
     */
    function _lower(bytes1 _b1)
        private
        pure
        returns (bytes1) {

        if (_b1 >= 0x41 && _b1 <= 0x5A) {
            return bytes1(uint8(_b1) + 32);
        }

        return _b1;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.15;

library Structs {
     struct Nog {
        address minterAddress;
        uint16[7] colorPalette;
        uint16 nogStyle;
        uint16 backgroundStyle;
        bool hasShadow;
        bool hasAnimation;
    }

    struct NogStyle {
        string name;
        string shape;
        uint8 frameColorLength;
    }

    struct Seed {
        uint256 tokenId;
        address minterAddress;
        uint16[7] colorPalette;
        string[7] colors;
        uint16 nogStyle;
        string nogStyleName;
        string nogShape;
        uint8 frameColorLength;
        uint16 backgroundStyle;
        string backgroundStyleName;
        string shade;
        string shadow;
        string shadowAnimation;
        bool hasAnimation;
    }

    struct NogParts {
        string image;
        string colorMetadata;
        string colorPalette;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides a function for encoding some bytes in base64
library Base64 {
    string internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(string memory _data) internal pure returns (string memory) {
        return encode(bytes(_data));
    }

    function encode(bytes memory _data) internal pure returns (string memory) {
        if (_data.length == 0) return "";

        // load the table into memory
        string memory table = TABLE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((_data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := _data
            let endPtr := add(dataPtr, mload(_data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {

            } lt(dataPtr, endPtr) {

            } {
                dataPtr := add(dataPtr, 3)

                // read 3 bytes
                let input := mload(dataPtr)

                // write 4 characters
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
                resultPtr := add(resultPtr, 1)
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
                resultPtr := add(resultPtr, 1)
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(6, input), 0x3F)))))
                resultPtr := add(resultPtr, 1)
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(input, 0x3F)))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(_data), 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./StringUtils.sol";
import "./Structs.sol";
import "./Base64.sol";

library NogBuilder {
    using StringUtils for string;
    using Strings for uint160;
    using Strings for uint256;    

    /* 
    ⌐◨—————————————————————————————————————————————————————————————◨
                            nog colors
    ⌐◨—————————————————————————————————————————————————————————————◨ 
    */  

    function getColorPalette(Structs.Seed memory seed) internal view returns (string memory colorMetadata) {
        bytes memory list;
        for (uint i; i < seed.colors.length; ++i) {
            if (i < seed.colors.length - 1) {
                list = abi.encodePacked(list, string.concat('"#', seed.colors[seed.colorPalette[i]],'", '));
            } else {
                list = abi.encodePacked(list, string.concat('"#', seed.colors[seed.colorPalette[i]],'"'));
            }
        }
        return string(list);
    }

    function getNogColorStyles(Structs.Seed memory seed) internal view returns (string memory nogColorStyles) {
        string memory bg = seed.colors[seed.colorPalette[0]];
        if (seed.backgroundStyle == 1) {
            bg = 'd5d7e1';
        }
        if (seed.backgroundStyle == 2) {
            bg = 'e1d7d5';
        }
        if (seed.backgroundStyle == 3) {
            bg = seed.colors[seed.colorPalette[1]];
        }
        
        return string(
            abi.encodePacked(
                '<style>.shade{fill:',
                seed.shade,
                '}.bg{fill:#',
                bg,
                '}.a{fill:#',
                seed.colors[seed.colorPalette[1]],
                '}.b{fill:#',
                seed.colors[seed.colorPalette[2]],
                '}.c{fill:#',
                seed.colors[seed.colorPalette[3]],
                ';}.d{fill:#',
                seed.colors[seed.colorPalette[4]],
                ';}.e{fill:#',
                seed.colors[seed.colorPalette[5]],
                ';}.y{fill:#',
                'fff',
                '}.p{fill:#',
                '000',
                '}</style>'
            )
        );
    }

    function getColorMetadata(uint frameColorLength, uint16[7] memory colorPalette, string[7] memory colors) internal view returns (string memory colorMetadata) {
        bytes memory list;
        for (uint i; i < frameColorLength; ++i) {
            list = abi.encodePacked(list, string.concat('{"trait_type":"Nog color", "value":"#', colors[colorPalette[i + 1]],'"},'));
        }
        return string(list);
    }
    
    function getColors(address minterAddress) public view returns (string[7] memory) {
        string memory addr = Strings.toHexString(minterAddress);
        string memory color;
        string[7] memory list;
        for (uint i; i < 7; ++i) {
            if (i == 0) {
                color = addr._substring(6, 2);
            } else if (i == 1) {
                color = addr._substring(6, int(i) * 8);
            } else {
                color = addr._substring(6, int(i) * 6);
            }
            list[i] = color;
        }    
        return list;
    }

    /* 
    ⌐◨—————————————————————————————————————————————————————————————◨
                            create nogs
    ⌐◨—————————————————————————————————————————————————————————————◨ 
    */  

    function getTokenIdSvg(Structs.Seed memory seed) internal view returns (string memory svg) {
        string memory backgroundGradient = getBackground(seed);
        string memory shade = string(abi.encodePacked('<path class="shade" d="M0 0h100v100H0z"/>'));
        string memory nogs = string(abi.encodePacked(seed.nogShape));
        string memory shadow;
        if (seed.backgroundStyle == 1 || seed.backgroundStyle == 2) {
            shade = '';
        }
        if (isStringEmpty(seed.shadow) == false) {
            shadow = string(abi.encodePacked(seed.shadow));
        }
        if (isStringEmpty(seed.shadow) == false && seed.hasAnimation == true) {
            // bounce nogs
            nogs = string(abi.encodePacked(
                '<g shape-rendering="optimizeSpeed" transform="translate(-55 -42)">',
                    seed.nogShape,
                    '<defs><path xmlns="http://www.w3.org/2000/svg" id="nogs" d="M53.5 41.2c-.2.7-.3 1.8 0 1.8s.2-1 0-1.8zm0 0c-.2-.8-.3-1.7 0-1.7s.2 1 0 1.7z"/></defs><animateMotion xmlns="http://www.w3.org/2000/svg" dur="8s" repeatCount="indefinite" calcMode="linear"><mpath xmlns:xlink="http://www.w3.org/1999/xlink" xlink:href="#nogs"/></animateMotion>',
                '</g>'
            ));
            shadow = string(abi.encodePacked(seed.shadowAnimation));
        }

        return
            string(
                abi.encodePacked(
                    '<svg viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg" style="shape-rendering:crispedges">',
                        '<defs>',
                            string(abi.encodePacked(getNogColorStyles(seed))),
                        '</defs>',
                        '<svg viewBox="0 0 100 100"><path class="bg" d="M0 0h100v100H0z"/>',
                        shade, 
                            string(abi.encodePacked(backgroundGradient)),
                            string(abi.encodePacked(shadow)),
                        '</svg>',
                        '<svg viewBox="0 0 100 100" class="nogs">',
                            string(abi.encodePacked(nogs)),
                        '</svg>',
                    '</svg>'
                )
            );
    }    

    function buildParts(Structs.Seed memory seed) public view returns (Structs.NogParts memory parts) {
        parts = Structs.NogParts({
            image: string(abi.encodePacked(Base64.encode(bytes(getTokenIdSvg(seed))))),
            colorMetadata: getColorMetadata(seed.frameColorLength, seed.colorPalette, seed.colors),
            colorPalette: getColorPalette(seed)
        });
    }

    function getBackground(Structs.Seed memory seed) public view returns (string memory backgroundGradient) {
        string[5] memory vals = ["22", "33", "44", "55", "66"];
        string[8] memory animations = [
            '',
            '',
            '',
            '',
            string(abi.encodePacked('<animateTransform attributeType="xml" attributeName="transform" type="rotate" from="360 50 50" to="0 50 50" dur="22s" additive="sum" repeatCount="indefinite"/><animateTransform xmlns="http://www.w3.org/2000/svg" attributeType="xml" attributeName="transform" type="scale" values="0.8; 1.8; 0.8" dur="33s" additive="sum" repeatCount="indefinite"/>')),
            string(abi.encodePacked('<animate attributeName="r" values="1; 1.66; 1" dur="18s" repeatCount="indefinite"></animate>')),
            string(abi.encodePacked('<animate attributeName="x2" values="100;',vals[getPseudorandomness(seed.tokenId, 17) % 5],';100" dur="28s" repeatCount="indefinite"></animate><animate attributeName="y2" values="10;85;10" dur="17s" repeatCount="indefinite"></animate>')),
            string(abi.encodePacked('<animate attributeName="x1" values="',vals[getPseudorandomness(seed.tokenId, 17) % 5], ';100;',vals[getPseudorandomness(seed.tokenId, 23) % 5], '" dur="42s" repeatCount="indefinite"></animate><animate attributeName="y1" values="10;66;10" dur="22s" repeatCount="indefinite"></animate>'))
        ];
        
        string memory animation;
        if (seed.hasAnimation == true) {
            animation = animations[seed.backgroundStyle];
        }

        if (isStringEmpty(seed.shadow) == false && seed.hasAnimation == true) {
            animation = '';
        }

        string memory meshGradient = string(abi.encodePacked(
            '<path d="M0 0h100v100H0z" fill="#fff" opacity="0.', vals[getPseudorandomness(seed.tokenId, 13) % 5], '"/>',
            '<g filter="url(#grad)" transform="scale(1.', vals[getPseudorandomness(seed.tokenId, 17) % 5], ') translate(-25 -25)" opacity="0.', vals[getPseudorandomness(seed.tokenId, 23) % 5], '">',
                '<path d="M32.15 0H0v80.55L71 66 32.15 0Z" fill="#', seed.colors[2], '"/><path d="M0 80.55V100h80l-9-34L0 80.55Z" fill="#', seed.colors[3], '"/><path d="M80 100h20V19.687L71 66l9 34Z" fill="#', seed.colors[5], '"/><path d="M100 0H32.15L71 66l29-46.313V0Z" fill="#', seed.colors[2], '"/>',
                '<defs><filter id="grad" x="-50" y="-50" width="200" height="200" filterUnits="userSpaceOnUse" color-interpolation-filters="sRGB"><feBlend result="shape"/><feGaussianBlur stdDeviation="10"/></filter></defs>',
                animation,
            '</g>'
        ));

        string memory gradientRadial = string(abi.encodePacked(
            '<path fill="url(#grad)" d="M-73-17h246v246H-73z" opacity="0.8"  /><defs><radialGradient id="grad" cx="0" cy="0" r="1" gradientTransform="rotate(44.737 -114.098 135.14) scale(165.905)" gradientUnits="userSpaceOnUse"><stop stop-color="#', seed.colors[seed.nogStyle], '"/><stop offset=".6" stop-color="#', seed.colors[seed.nogStyle], '" stop-opacity="0"/>', animation, '</radialGradient></defs>'
        ));

        string memory linearGradient = string(abi.encodePacked(
            '<path fill="url(#grad)" opacity=".66" d="M0 0h100v100H0z"/><defs><linearGradient id="grad" x1="7" y1="8" x2="100" y2="100" gradientUnits="userSpaceOnUse"><stop stop-color="#', seed.colors[seed.nogStyle], '"/><stop offset="1" stop-color="#', seed.colors[seed.nogStyle], '" stop-opacity=".2"/>', animation,'</linearGradient></defs>'
        ));

        string memory lightGradient = string(abi.encodePacked(
            '<path fill="url(#grad)" opacity=".44" d="M0 0h100v100H0z"/><defs><linearGradient id="grad" x1="7" y1="8" x2="100" y2="100" gradientUnits="userSpaceOnUse"><stop stop-color="#fff" stop-opacity=".67"/><stop offset="1" stop-color="#fff" stop-opacity=".21"/>', animation, '</linearGradient></defs>'
        ));
    
        string[8] memory backgrounds = ['', '', '', '', meshGradient, gradientRadial, linearGradient, lightGradient];

        backgroundGradient = string (
            abi.encodePacked(backgrounds[seed.backgroundStyle])
        );
    }

    function getAttributesMetadata(Structs.Seed memory seed) public view returns (string memory extraMetadata) {
        string memory animatedMetadata;
        string memory floatingMetadata;
        string memory bg = string(abi.encodePacked('#',seed.colors[0]));
        if (seed.hasAnimation && seed.backgroundStyle > 1) {
            animatedMetadata = string(abi.encodePacked(
                '{"value":"Animated"},'
            ));
        }
        if (isStringEmpty(seed.shadow) == false) {
            floatingMetadata = string(abi.encodePacked(
                '{"value":"Floating"},'
            ));
        }
        if (seed.backgroundStyle == 1) {
            bg = string(abi.encodePacked('Cool'));
        }
        if (seed.backgroundStyle == 2) {
            bg = string(abi.encodePacked('Warm'));
        }
        
        return string(abi.encodePacked(
            '{"trait_type":"Nog type", "value":"',
                abi.encodePacked(string(seed.nogStyleName)),
            '"},',
                abi.encodePacked(string(getColorMetadata(seed.frameColorLength, seed.colorPalette, seed.colors))),
            '{"trait_type":"Background type", "value":"',
                abi.encodePacked(string(seed.backgroundStyleName)),
            '"},',    
            '{"trait_type":"Background color", "value":"',
                bg,
            '"},',
            animatedMetadata, 
            floatingMetadata,
            '{"trait_type":"Minted by", "value":"',
                abi.encodePacked(string(uint160(seed.minterAddress).toHexString(20))),
            '"}'
        ));
    }

    /*
    ⌐◨—————————————————————————————————————————————————————————————◨
                           utility functions
    ⌐◨—————————————————————————————————————————————————————————————◨ 
    */  

    function isStringEmpty(string memory val) public view returns(bool) {
        bytes memory checkString = bytes(val);
        if (checkString.length > 0) {
            return false;
        } else {
            return true;
        }
    }

    function getPseudorandomness(uint tokenId, uint num) public view returns (uint256 pseudorandomness) {        
        return uint256(keccak256(abi.encodePacked(num * tokenId * tokenId + 1, msg.sender)));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
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