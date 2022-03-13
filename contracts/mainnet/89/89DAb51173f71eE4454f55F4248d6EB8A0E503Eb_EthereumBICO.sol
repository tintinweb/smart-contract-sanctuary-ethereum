// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "../SvgHelperBase.sol";

contract EthereumBICO is SvgHelperBase {
    using Strings for uint256;

    constructor(uint256 _decimals) SvgHelperBase(_decimals) {}

    function getTokenSvg(
        uint256 _tokenId,
        uint256 _suppliedLiquidity,
        uint256 _totalSuppliedLiquidity
    ) public view virtual override returns (string memory) {
        string memory tokenId = _tokenId.toString();
        string memory suppliedLiquidity = _divideByPowerOf10(_suppliedLiquidity, tokenDecimals, 3);
        string memory sharePercent = _calculatePercentage(_suppliedLiquidity, _totalSuppliedLiquidity);
        return
            string(
                abi.encodePacked(
                    '<svg version="1.1" id="prefix__Layer_1" xmlns="http://www.w3.org/2000/svg" x="0" y="0" viewBox="0 0 405 405" xml:space="preserve"><style>.prefix__st2{fill:#fff}.prefix__st9{font-family:&apos;Courier&apos;}.prefix__st10{font-size:24px}</style><radialGradient id="prefix__SVGID_1_" cx="454.998" cy="403.611" r="1" gradientTransform="scale(327.499 -327.499) rotate(-90 26.003 428.995)" gradientUnits="userSpaceOnUse"><stop offset="0" stop-color="#8c8c8c"/><stop offset="1"/></radialGradient><path d="M30 0h345c16.57 0 30 13.43 30 30v345c0 16.57-13.43 30-30 30H30c-16.57 0-30-13.43-30-30V30C0 13.43 13.43 0 30 0z" fill="url(#prefix__SVGID_1_)"/><radialGradient id="prefix__SVGID_00000149348912856748424340000004453863865774411953_" cx="454.998" cy="402.284" r="1" gradientTransform="matrix(0 270.995 167.538 0 -67195.375 -123224.695)" gradientUnits="userSpaceOnUse"><stop offset="0" stop-color="#fff"/><stop offset=".711" stop-color="#d85111"/><stop offset="1" stop-opacity="0"/><stop offset="1" stop-opacity="0"/></radialGradient><path d="M214.93 95.88c-5.94-8.8-18.93-8.8-24.87 0-43.56 64.49-70.9 107.33-70.9 149.07 0 45.6 37.28 82.55 83.33 82.55s83.33-36.95 83.33-82.55c.01-41.74-27.33-84.58-70.89-149.07z" fill="url(#prefix__SVGID_00000149348912856748424340000004453863865774411953_)"/><path class="prefix__st2" d="M271.41 338.62a.8.8 0 00-.59-.24h-1.66a.8.8 0 00-.59.24.8.8 0 00-.24.59v5c0 .11-.02.22-.06.32-.04.1-.1.2-.18.27a.8.8 0 01-.59.24h-8.33c-.11 0-.22-.02-.32-.06s-.2-.1-.27-.18-.14-.17-.18-.27a.866.866 0 01-.06-.32v-5a.8.8 0 00-.24-.59.8.8 0 00-.59-.24h-1.67c-.22 0-.43.09-.59.24s-.24.37-.24.59v15a.8.8 0 00.24.59.8.8 0 00.59.24h1.67a.8.8 0 00.59-.24.8.8 0 00.24-.59v-5a.8.8 0 01.24-.59.8.8 0 01.59-.24h8.33a.8.8 0 01.59.24.8.8 0 01.24.59v5c0 .11.02.22.06.32.04.1.1.2.18.27s.17.14.27.18.21.06.32.06h1.66c.11 0 .22-.02.32-.06.1-.04.2-.1.27-.18s.14-.17.18-.27c.04-.1.06-.21.06-.32v-15c0-.11-.02-.22-.06-.32-.04-.11-.1-.2-.18-.27zM321.41 341.91a.8.8 0 00-.59-.24h-5.83v.04h-2.5a.8.8 0 01-.59-.24.8.8 0 01-.24-.59v-5a.8.8 0 00-.24-.59.8.8 0 00-.59-.24h-1.66c-.11 0-.22.02-.32.06-.1.04-.2.1-.27.18a.8.8 0 00-.24.59v18.33c0 .11.02.22.06.32.04.1.1.2.18.27a.8.8 0 00.59.24h1.66c.11 0 .22-.02.32-.06.1-.04.2-.1.27-.18a.8.8 0 00.24-.59v-8.33a.8.8 0 01.24-.59.8.8 0 01.59-.24h5a.8.8 0 01.59.24.8.8 0 01.24.59v8.33c0 .11.02.22.06.32.04.1.1.2.18.27a.8.8 0 00.59.24h1.66c.11 0 .22-.02.32-.06.1-.04.2-.1.27-.18a.8.8 0 00.24-.59v-11.7c0-.11-.02-.22-.06-.32a.624.624 0 00-.17-.28zM338.08 341.91a.8.8 0 00-.59-.24h-11.67c-.11 0-.22.02-.32.06a.98.98 0 00-.27.18.8.8 0 00-.24.59v11.66a.8.8 0 00.24.59.8.8 0 00.59.24h11.67a.8.8 0 00.59-.24.8.8 0 00.24-.59v-1.66c0-.11-.02-.22-.06-.32-.04-.1-.1-.2-.18-.27a.8.8 0 00-.59-.24h-8.33c-.22 0-.43-.09-.59-.24-.16-.16-.24-.37-.24-.59s.09-.43.24-.59c.16-.16.37-.24.59-.24h8.33a.8.8 0 00.59-.24.8.8 0 00.24-.59v-6.66c0-.11-.02-.22-.06-.32a.841.841 0 00-.18-.29zm-3.16 4.24a.8.8 0 01-.18.27.8.8 0 01-.59.24h-5a.8.8 0 01-.59-.24.8.8 0 01-.24-.59.8.8 0 01.24-.59.8.8 0 01.59-.24h5a.8.8 0 01.59.24.8.8 0 01.24.59c0 .11-.02.22-.06.32zM354.74 341.91a.8.8 0 00-.59-.24l-2.5.04h-9.17a.8.8 0 00-.59.24.8.8 0 00-.24.59v11.66c0 .11.02.22.06.32.04.1.1.2.18.27a.8.8 0 00.59.24h1.67a.8.8 0 00.59-.24.8.8 0 00.24-.59v-8.33a.8.8 0 01.24-.59.8.8 0 01.59-.24h5c.11 0 .22.02.32.06.1.04.2.1.27.18a.8.8 0 01.24.59v8.33c0 .11.02.22.06.32.04.1.1.2.18.27a.8.8 0 00.59.24h1.67a.8.8 0 00.59-.24.8.8 0 00.24-.59v-11.7c0-.11-.02-.22-.06-.32a.65.65 0 00-.17-.27zM288.08 341.91a.8.8 0 00-.59-.24h-1.67c-.11 0-.22.02-.32.06a.98.98 0 00-.27.18.8.8 0 00-.24.59v8.33a.8.8 0 01-.24.59.8.8 0 01-.59.24h-5c-.11 0-.22-.02-.32-.06-.1-.04-.2-.1-.27-.18a.8.8 0 01-.24-.59v-8.33c0-.11-.02-.22-.06-.32-.04-.1-.1-.2-.18-.27a.8.8 0 00-.59-.24h-1.67c-.11 0-.22.02-.32.06a.98.98 0 00-.27.18.8.8 0 00-.24.59v11.66a.8.8 0 00.24.59.8.8 0 00.59.24h8.34c.22 0 .43.09.59.24.16.16.24.37.24.59s-.09.43-.24.59c-.16.16-.37.24-.59.24h-5c-.11 0-.22.02-.32.06s-.2.1-.27.18-.14.17-.18.27c-.04.1-.06.21-.06.32v1.66c0 .11.02.22.06.32.04.1.1.2.18.27s.17.14.27.18.21.06.32.06h8.33a.8.8 0 00.59-.24.8.8 0 00.24-.59v-16.66c0-.11-.02-.22-.06-.32-.05-.08-.12-.17-.19-.25zM304.74 341.91a.8.8 0 00-.59-.24h-11.67a.8.8 0 00-.59.24.8.8 0 00-.24.59v16.66c0 .11.02.22.06.32.04.1.1.2.18.27a.8.8 0 00.59.24h1.67a.8.8 0 00.59-.24.8.8 0 00.24-.59v-3.33a.8.8 0 01.24-.59.8.8 0 01.59-.24h8.34a.8.8 0 00.59-.24.8.8 0 00.24-.59v-11.66a.866.866 0 00-.24-.6zm-3.09 8.93a.8.8 0 01-.52.77c-.1.04-.21.06-.32.06h-5a.8.8 0 01-.59-.24.8.8 0 01-.24-.59v-5a.8.8 0 01.24-.59.8.8 0 01.59-.24h5a.866.866 0 01.6.24.8.8 0 01.24.59v5zM329.97 96.59c.28 0 .57-.05.83-.16s.5-.27.7-.47a2.116 2.116 0 00.63-1.53V81.49a2.182 2.182 0 00-.62-1.52 2.105 2.105 0 00-1.52-.63h-4.31c-.57 0-1.12.23-1.52.63-.4.4-.63.95-.63 1.52v4.31c0 .28-.05.57-.16.83s-.27.5-.47.7a2.116 2.116 0 01-1.53.63h-4.31c-.28 0-.57-.05-.83-.16s-.5-.27-.7-.47a2.116 2.116 0 01-.63-1.53V64.24c0-.28.05-.57.16-.83s.27-.5.47-.7a2.116 2.116 0 011.53-.63h1.25c.42 0 .84-.12 1.2-.36.35-.24.63-.57.79-.97a2.138 2.138 0 00-.49-2.33l-7.68-7.76c-.2-.21-.44-.37-.7-.48a2.124 2.124 0 00-1.66 0c-.26.11-.5.27-.7.48l-7.72 7.76c-.3.3-.51.68-.59 1.09s-.04.85.12 1.24.43.73.78.96c.35.24.76.37 1.19.37h1.25c.29 0 .57.05.83.16s.5.27.7.47c.2.2.36.44.47.7.11.26.16.55.16.83v30.2c0 .28.05.57.16.83s.27.5.47.7a2.116 2.116 0 001.53.63h21.55z"/><path class="prefix__st2" d="M324.14 70.08a2.116 2.116 0 001.53.63h4.31c.28 0 .57-.05.83-.16s.5-.27.7-.47a2.116 2.116 0 00.63-1.53v-4.31c0-.28.05-.57.16-.83s.27-.5.47-.7a2.116 2.116 0 011.53-.63h4.32c.28 0 .57.05.83.16s.5.27.7.47c.2.2.36.44.47.7.11.26.16.55.16.83v21.57c0 .28-.05.57-.16.83s-.27.5-.47.7a2.116 2.116 0 01-1.53.63h-1.26c-.42 0-.84.13-1.2.36-.35.24-.63.57-.79.97-.16.39-.2.83-.11 1.24.09.42.3.8.6 1.1l7.73 7.72c.2.2.44.37.7.48a2.124 2.124 0 002.36-.48l7.72-7.72c.3-.3.5-.69.58-1.1.08-.42.04-.85-.12-1.24a2.12 2.12 0 00-.79-.96c-.35-.24-.77-.36-1.19-.36h-1.29c-.28 0-.57-.05-.83-.16s-.5-.27-.7-.47a2.116 2.116 0 01-.63-1.53V55.6c0-.28-.05-.57-.16-.83s-.27-.5-.47-.7c-.2-.2-.44-.36-.7-.47-.26-.11-.55-.16-.83-.16h-21.57c-.28 0-.57.05-.83.16s-.5.27-.7.47a2.116 2.116 0 00-.63 1.53v12.95c0 .28.05.57.16.83s.27.5.47.7z"/><text transform="translate(73.686 67)" class="prefix__st2 prefix__st9 prefix__st10">',
                    suppliedLiquidity,
                    ' BICO</text><text transform="rotate(-90 213.61 143.092)" class="prefix__st2 prefix__st9 prefix__st10">',
                    sharePercent,
                    '%</text><path fill="none" stroke="#fff" stroke-miterlimit="10" d="M61.86 267.12V114.71"/><text transform="translate(79.915 355)" class="prefix__st2 prefix__st9" font-size="10">ID: ',
                    tokenId,
                    '</text><g><path d="M136.03 77.23H56.69c-2.76 0-5 2.24-5 5v7.47c0 2.76 2.24 5 5 5h79.34c2.76 0 5-2.24 5-5v-7.47c0-2.76-2.24-5-5-5z" fill="#8c8c8c"/><text transform="translate(56.685 89.706)" class="prefix__st2" font-size="12" font-family="Courier-Bold">ON ETHEREUM</text></g><g><circle cx="60.19" cy="58.5" r="8.5"/><linearGradient id="prefix__SVGID_00000121240735984433054910000011952518464616340407_" gradientUnits="userSpaceOnUse" x1="58.709" y1="66.872" x2="61.662" y2="50.128"><stop offset="0" stop-color="#fff"/><stop offset="1" stop-color="#fff"/></linearGradient><path d="M60.19 50.75c4.27 0 7.75 3.48 7.75 7.75s-3.48 7.75-7.75 7.75-7.75-3.48-7.75-7.75 3.47-7.75 7.75-7.75m0-.75c-4.69 0-8.5 3.81-8.5 8.5s3.81 8.5 8.5 8.5 8.5-3.81 8.5-8.5-3.81-8.5-8.5-8.5z" fill="url(#prefix__SVGID_00000121240735984433054910000011952518464616340407_)"/><g><path d="M61.53 54.53c-.31-.18-.68-.28-1.06-.28h-2.12c.59 0 1.06.48 1.06 1.06v3.19h1.06c.39 0 .75-.1 1.06-.29.23-.13.44-.31.6-.52.29-.36.46-.82.46-1.32 0-.78-.42-1.47-1.06-1.84z" fill="#d85111"/><path class="prefix__st2" d="M62.14 57.69a2.131 2.131 0 01-1.66.81h-1.06v-3.19a1.06 1.06 0 00-2.12 0V62.75H61c.18 0 .36-.02.53-.05a2.66 2.66 0 002.12-2.6c.01-1.07-.62-1.98-1.51-2.41z"/></g></g></svg>'
                )
            );
    }

    function getChainName() public pure override returns (string memory) {
        return "Ethereum";
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "base64-sol/base64.sol";

abstract contract SvgHelperBase is Ownable {
    using Strings for uint256;

    uint256 public tokenDecimals;

    event BackgroundUrlUpdated(string newBackgroundUrl);
    event TokenDecimalsUpdated(uint256 newTokenDecimals);

    constructor(uint256 _tokenDecimals) Ownable() {
        tokenDecimals = _tokenDecimals;
    }

    function setTokenDecimals(uint256 _tokenDecimals) public onlyOwner {
        tokenDecimals = _tokenDecimals;
        emit TokenDecimalsUpdated(_tokenDecimals);
    }

    /// @notice Given an integer, returns the number of digits in it's decimal representation.
    /// @param _number The number to get the number of digits in.
    /// @return The number of digits in the decimal representation of the given number.
    function _getDigitsCount(uint256 _number) internal pure returns (uint256) {
        uint256 count = 0;
        while (_number > 0) {
            ++count;
            _number /= 10;
        }
        return count;
    }

    /// @notice Generates a string containing 0s of the given length.
    /// @param _length The length of the string to generate.
    /// @return A string of 0s of the given length.
    function _getZeroString(uint256 _length) internal pure returns (string memory) {
        if (_length == 0) {
            return "";
        }
        string memory result;
        for (uint256 i = 0; i < _length; ++i) {
            result = string(abi.encodePacked(result, "0"));
        }
        return result;
    }

    /// @notice Truncate Digits from the right
    function _truncateDigitsFromRight(uint256 _number, uint256 _digitsCount) internal pure returns (uint256) {
        uint256 result = _number /= (10**_digitsCount);
        // Remove Leading Zeroes
        while (result != 0 && result % 10 == 0) {
            result /= 10;
        }
        return result;
    }

    /// @notice Return str(_value / 10^_power)
    function _divideByPowerOf10(
        uint256 _value,
        uint256 _power,
        uint256 _maxDigitsAfterDecimal
    ) internal pure returns (string memory) {
        uint256 integerPart = _value / 10**_power;
        uint256 leadingZeroesToAddBeforeDecimal = 0;
        uint256 fractionalPartTemp = _value % (10**_power);

        uint256 powerRemaining = _power;
        if (fractionalPartTemp != 0) {
            // Remove Leading Zeroes
            while (fractionalPartTemp != 0 && fractionalPartTemp % 10 == 0) {
                fractionalPartTemp /= 10;
                if (powerRemaining > 0) {
                    powerRemaining--;
                }
            }

            uint256 expectedFractionalDigits = powerRemaining;
            if (_getDigitsCount(fractionalPartTemp) < expectedFractionalDigits) {
                leadingZeroesToAddBeforeDecimal = expectedFractionalDigits - _getDigitsCount(fractionalPartTemp);
            }
        }

        if (fractionalPartTemp == 0) {
            return integerPart.toString();
        }
        uint256 digitsToTruncateCount = _getDigitsCount(fractionalPartTemp) + leadingZeroesToAddBeforeDecimal >
            _maxDigitsAfterDecimal
            ? _getDigitsCount(fractionalPartTemp) + leadingZeroesToAddBeforeDecimal - _maxDigitsAfterDecimal
            : 0;
        return
            string(
                abi.encodePacked(
                    integerPart.toString(),
                    ".",
                    _getZeroString(leadingZeroesToAddBeforeDecimal),
                    _truncateDigitsFromRight(fractionalPartTemp, digitsToTruncateCount).toString()
                )
            );
    }

    function getAttributes(uint256 _suppliedLiquidity, uint256 _totalSuppliedLiquidity)
        public
        view
        virtual
        returns (string memory)
    {
        string memory suppliedLiquidity = _divideByPowerOf10(_suppliedLiquidity, tokenDecimals, 3);
        string memory sharePercent = _calculatePercentage(_suppliedLiquidity, _totalSuppliedLiquidity);
        return
            string(
                abi.encodePacked(
                    "[",
                    '{ "trait_type": "Supplied Liquidity", "display_type": "number", "value": ',
                    suppliedLiquidity,
                    '},{ "trait_type": "Share Percentage", "value": "',
                    sharePercent,
                    '%"}]'
                )
            );
    }

    function getDescription(uint256, uint256) public view virtual returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "This NFT represents your position as Liquidity Provider on Hyphen Bridge on ",
                    getChainName(),
                    ". To visit the bridge, visit [Hyphen](https://hyphen.biconomy.io)."
                )
            );
    }

    /// @notice Return str(_value / _denom * 100)
    function _calculatePercentage(uint256 _num, uint256 _denom) internal pure returns (string memory) {
        return _divideByPowerOf10((_num * 10**(18 + 2)) / _denom, 18, 2);
    }

    function getTokenSvg(
        uint256 _tokenId,
        uint256 _suppliedLiquidity,
        uint256 _totalSuppliedLiquidity
    ) public view virtual returns (string memory);

    function getChainName() public view virtual returns (string memory);
}

// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

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