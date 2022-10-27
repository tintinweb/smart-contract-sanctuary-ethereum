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

pragma solidity ^0.8.0;

library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "../libs/Base64.sol";

/// @title NFTSVG
library MerchantTokenNFTSVG {
    using Strings for uint256;

    struct SVGParams {
        // merchant info
        uint256 merchantTokenId;
        string merchantName;
        address merchantOwner;
    }

    function generateSVG(SVGParams memory params)
    internal
    pure
    returns (string memory svg)
    {
        string memory meta = string(
            abi.encodePacked(
                '<svg xmlns="http://www.w3.org/2000/svg" version="1.1" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:svgjs="http://svgjs.dev/svgjs" width="800" height="800" viewBox="0 0 800 800" style="background-color:black">',
                '<defs>',
                '<path id="text-path-a" d="M100 55 H700 A45 45 0 0 1 745 100 V700 A45 45 0 0 1 700 745 H100 A45 45 0 0 1 55 700 V100 A45 45 0 0 1 100 55 z"/>',
                '<linearGradient x1="50%" y1="0%" x2="50%" y2="100%" id="nnneon-grad">',
                '<stop stop-color="hsl(230, 55%, 50%)" stop-opacity="1" offset="0%"/>',
                '<stop stop-color="hsl(230, 55%, 70%)" stop-opacity="1" offset="100%"/>',
                '</linearGradient>',
                '<filter id="nnneon-filter" x="-100%" y="-100%" width="400%" height="400%" filterUnits="objectBoundingBox" primitiveUnits="userSpaceOnUse" color-interpolation-filters="sRGB">',
                '<feGaussianBlur stdDeviation="17 8" x="0%" y="0%" width="100%" height="100%" in="SourceGraphic" edgeMode="none" result="blur"/>',
                '</filter>',
                '<filter id="nnneon-filter2" x="-100%" y="-100%" width="100%" height="100%" filterUnits="objectBoundingBox" primitiveUnits="userSpaceOnUse" color-interpolation-filters="sRGB">',
                '<feGaussianBlur stdDeviation="10 17" x="0%" y="0%" width="100%" height="100%" in="SourceGraphic" edgeMode="none" result="blur"/>',
                '</filter>',
                '</defs>',
                '<g stroke-width="16" stroke="url(#nnneon-grad)" fill="none">',
                '<rect width="700" height="700" x="50" y="50" filter="url(#nnneon-filter)" rx="45" ry="45"/>',
                '<rect width="700" height="700" x="88" y="50" filter="url(#nnneon-filter2)" opacity="0.25" rx="45" ry="45"/>',
                '<rect width="700" height="700" x="12" y="50" filter="url(#nnneon-filter2)" opacity="0.25" rx="45" ry="45"/>',
                '<rect width="700" height="700" x="50" y="50" rx="45" ry="45"/>',
                '</g>',
                '<g>',
                '<text y="200" x="100" fill="white" font-family="\\\'Courier New\\\', monospace" font-weight="200" font-size="60px">',
                params.merchantName,
                '</text>',
                '<text y="450" x="100" fill="white" font-family="\\\'Courier New\\\', monospace" font-weight="200" font-size="16px">',
                'Merchant Token Id : ', Strings.toString(params.merchantTokenId),
                '</text>',
                '<text y="480" x="100" fill="white" font-family="\\\'Courier New\\\', monospace" font-weight="200" font-size="16px">',
                'Merchant Owner : ', Strings.toHexString(uint160(params.merchantOwner)),
                '</text>',
                '</g>',
                '<g>',
                '<svg version="1.0" xmlns="http://www.w3.org/2000/svg" width="80" height="80" viewBox="0 0 1920 1920" preserveAspectRatio="xMidYMid meet" x="600" y="630">',
                '<g transform="translate(0.000000,1920.000000) scale(0.100000,-0.100000)" fill="white" stroke="none">',
                '<path d="M8833 13027 c-1855 -1855 -3373 -3379 -3373 -3386 0 -13 1393 -1411 ',
                '1407 -1411 4 0 1210 1202 2680 2672 l2672 2672 27 -24 c73 -68 3899 -3902 ',
                '3902 -3910 2 -5 -753 -766 -1677 -1690 -925 -925 -1681 -1687 -1681 -1693 0 ',
                '-22 1383 -1397 1405 -1397 13 0 823 803 2404 2384 1905 1905 2382 2387 2377 ',
                '2402 -9 27 -6738 6754 -6756 6754 -8 0 -1533 -1518 -3387 -3373z"/>',
                '<path d="M3492 13007 c-1854 -1854 -3372 -3376 -3372 -3381 0 -5 1521 -1530 ',
                '3380 -3389 l3381 -3381 3379 3379 c1859 1859 3380 3385 3380 3390 0 13 -1392 ',
                '1405 -1405 1405 -6 0 -1209 -1199 -2675 -2665 -1466 -1466 -2672 -2665 -2680 ',
                '-2665 -16 0 -3930 3909 -3930 3925 0 6 1199 1209 2665 2675 1466 1466 2665 ',
                '2672 2665 2680 0 20 -1380 1400 -1400 1400 -8 0 -1533 -1518 -3388 -3373z"/>',
                '<path d="M11517 4992 c-383 -383 -697 -702 -697 -707 0 -6 315 -325 699 -709 ',
                '643 -643 701 -698 718 -685 53 42 1383 1381 1383 1393 0 12 -1378 1397 -1397 ',
                '1403 -4 2 -322 -311 -706 -695z"/>',
                '</g>',
                '</svg>',
                '<text text-rendering="optimizeSpeed">',
                '<textPath startOffset="-100%" fill="black" font-family="\\\'Courier New\\\', monospace" font-size="13px" xlink:href="#text-path-a">',
                'S10N Protocol',
                 unicode' • ',
                'Merchant Token',
                '<animate additive="sum" attributeName="startOffset" from="0%" to="100%" begin="0s" dur="30s" repeatCount="indefinite"/>',
                '</textPath>',
                '<textPath startOffset="0%" fill="black" font-family="\\\'Courier New\\\', monospace" font-size="13px" xlink:href="#text-path-a">',
                'S10N Protocol',
                unicode' • ',
                'Merchant Token',
                '<animate additive="sum" attributeName="startOffset" from="0%" to="100%" begin="0s" dur="30s" repeatCount="indefinite"/>',
                '</textPath>',
                '<textPath startOffset="50%" fill="black" font-family="\\\'Courier New\\\', monospace" font-size="13px" xlink:href="#text-path-a">',
                'S10N Protocol',
                unicode' • ',
                'Merchant Token',
                '<animate additive="sum" attributeName="startOffset" from="0%" to="100%" begin="0s" dur="30s" repeatCount="indefinite"/>',
                '</textPath>',
                '<textPath startOffset="-50%" fill="black" font-family="\\\'Courier New\\\', monospace" font-size="13px" xlink:href="#text-path-a">',
                'S10N Protocol',
                unicode' • ',
                'Merchant Token',
                '<animate additive="sum" attributeName="startOffset" from="0%" to="100%" begin="0s" dur="30s" repeatCount="indefinite"/>',
                '</textPath>',
                '</text>',
                '</g>',
                '</svg>'
            )
        );

        string memory image = string(
            abi.encodePacked(
                "data:image/svg+xml;base64,",
                Base64.encode(bytes(meta))
            )
        );

        return image;
    }

}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface IMerchantTokenDescriptor {
    function tokenURI(uint256 tokenId, string memory name, address merchantOwner) external pure returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./IMerchantTokenDescriptor.sol";
import "../libs/MerchantTokenNFTSVG.sol";

contract MerchantTokenDescriptor is IMerchantTokenDescriptor, Initializable {

    function initialize() public initializer {
    }

    function tokenURI(uint256 tokenId, string memory name, address owner) external pure override returns (string memory) {
        MerchantTokenNFTSVG.SVGParams memory svgParams = MerchantTokenNFTSVG.SVGParams(tokenId, name, owner);

        string memory image = MerchantTokenNFTSVG.generateSVG(svgParams);

        string memory json;
        json = string(abi.encodePacked(
            '{"name": "S10N Merchant Token #',
            Strings.toString(tokenId),
            ' - ',
            name,
            '", "description": "S10N Merchant Token is a NFT that represents a merchant on S10N platform.", "image": "data:image/svg+xml;base64,',
            Base64.encode(bytes(image)),
            '"'
        ));
        json = string(abi.encodePacked(json, ', "attributes": ['));
        json = string(abi.encodePacked(json, '{"trait_type": "merchant_name", "value": "', name, '"},'));
        json = string(abi.encodePacked(json, '{"trait_type": "merchant_token_id", "value": "', Strings.toString(tokenId), '"}'));
        json = string(abi.encodePacked(json, ']'));

        json = string(abi.encodePacked(json, '}'));
        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(json))));
    }
}