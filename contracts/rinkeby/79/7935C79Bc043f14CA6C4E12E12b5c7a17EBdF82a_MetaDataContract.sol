// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
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
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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

// solhint-disable max-line-length

/**
 * SPDX-License-Identifier: MIT
 * @author a1rsupp0rt
 */

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./OwnableUpgradeable.sol";
import "./StringUtils.sol";

contract MetaDataContract is OwnableUpgradeable {
    using Strings for uint256;
    using StringUtils for string;

    struct Character {
        string name;
        string faction;
        string imageBase64;
    }

    modifier onlyCitizenContract() {
        require(msg.sender == citizenContr, "NOTALLOWED");
        _;
    }

    uint8 constant TRAIT_CATEGORIES = 2;
    uint8 constant TRAITS_PER_CATEGORY = 6;
    uint256 constant MAX_TRAITS = 6**2;

    mapping(uint8 => Character) public characters;
    mapping(uint256 => uint256) public traitsOfToken;
    mapping(uint256 => bool) public traitsTaken;

    string[3] categoryNames;
    address citizenContr;

    function initialize() public initializer {
        __Ownable__init();

        //  "Type", "Level", "Bag"
        categoryNames = ["Name", "Faction", "Type"];
    }

    // -----------------------------------------METADATA - GET----------------------------------------------------------

    function tokenMetadata(uint256 tokenId, bool isRaider)
        public
        view
        returns (string memory)
    {
        uint8[] memory traits = new uint8[](TRAIT_CATEGORIES);
        uint256 traitIdBackUp = traitsOfToken[tokenId];

        for (uint8 i = 0; i < TRAIT_CATEGORIES; i++) {
            uint8 exp = TRAIT_CATEGORIES - 1 - i;
            uint8 tmp = uint8(traitIdBackUp / (TRAITS_PER_CATEGORY**exp));
            traits[i] = tmp;
            traitIdBackUp -= tmp * TRAITS_PER_CATEGORY**exp;
        }

        string memory svgString = drawCharacter(characters[traits[0]]);

        string memory metadata = string(
            abi.encodePacked(
                "{",
                '"name": "',
                tokenId.toString(),
                '",',
                '"description": "Somethings moving in the streets of castle...",',
                '"image": "data:image/svg+xml;base64,',
                base64(bytes(svgString)),
                '",',
                '"attributes":',
                compileAttributes(isRaider, traits),
                "}"
            )
        );

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    base64(bytes(metadata))
                )
            );
    }

    // -----------------------------------------METADATA - UPDATE----------------------------------------------------------

    // -----------------------------------------METADATA - COMPILE----------------------------------------------------------

    function compileAttributes(bool isRaider, uint8[] memory traits)
        public
        view
        returns (string memory)
    {
        string memory attributes = string(
            abi.encodePacked(
                encodeAttributeWithValue(
                    categoryNames[0],
                    isRaider ? characters[6].name : characters[traits[0]].name,
                    ""
                ),
                ",",
                encodeAttributeWithValue(
                    categoryNames[1],
                    characters[traits[1]].faction,
                    ""
                ),
                ",",
                encodeAttributeWithValue(
                    categoryNames[2],
                    isRaider ? "Raider" : "Citizen",
                    ""
                )
            )
        );

        return string(abi.encodePacked("[", attributes, "]"));
    }

    function drawCharacter(Character memory character)
        internal
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    '<svg id="citizen" width="100%" height="100%" version="1.1" viewBox="0 0 106 106" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">',
                    '<image x="5" y="5" width="96" height="96" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,',
                    character.imageBase64,
                    '"/></svg>'
                )
            );
    }

    // -----------------------------------------METADATA - UPLOAD----------------------------------------------------------

    function uploadCharacters(Character[] calldata _characters)
        public
        onlyOwner
    {
        for (uint8 i = 0; i < _characters.length; i++) {
            characters[i] = Character(
                _characters[i].name,
                _characters[i].imageBase64,
                _characters[i].faction
            );
        }
    }

    /** @dev Calculates a seed that will be used to determine the traits of a token
     * @param tokenId Unique identifier of the token
     * @param randomWord Random number from the VRF request
     */
    function calculateTraits(uint256 tokenId, uint256 randomWord)
        external
        onlyCitizenContract
    {
        uint256 randomNr = uint256(keccak256(abi.encode(randomWord, 1)));
        uint256 traitId = randomNr % MAX_TRAITS;

        while (traitsTaken[traitId]) {
            randomNr = uint256(keccak256(abi.encode(randomNr, 1)));
            traitId = randomNr % MAX_TRAITS;
        }

        traitsTaken[traitId] = true;
        traitsOfToken[tokenId] = traitId;
    }

    function setCitizenContractAddress(address _citizenContr)
        external
        onlyOwner
    {
        citizenContr = _citizenContr;
    }

    // -----------------------------------------METADATA - UTILS - PURE----------------------------------------------------------

    function encodeAttributeWithValue(
        string memory categoryDisplayName,
        string memory value,
        string memory displayType
    ) internal pure returns (string memory) {
        if (!isEmptyString(displayType)) {
            return
                string(
                    abi.encodePacked(
                        "{",
                        encodeParamsAsKeyValuePair(
                            "trait_type",
                            categoryDisplayName
                        ),
                        ",",
                        encodeParamsAsKeyValuePair("display_type", displayType),
                        ",",
                        encodeParamsAsKeyValuePair("value", value),
                        "}"
                    )
                );
        }

        return
            string(
                abi.encodePacked(
                    "{",
                    encodeParamsAsKeyValuePair(
                        "trait_type",
                        categoryDisplayName
                    ),
                    ",",
                    encodeParamsAsKeyValuePair("value", value),
                    "}"
                )
            );
    }

    function encodeParamsAsKeyValuePair(string memory key, string memory value)
        internal
        pure
        returns (string memory)
    {
        return string(abi.encodePacked('"', key, '": "', value, '"'));
    }

    function isEmptyString(string memory s) public pure returns (bool) {
        return (keccak256(abi.encodePacked((s))) ==
            keccak256(abi.encodePacked((""))));
    }

    /** BASE 64 - Written by Brech Devos */

    string internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function base64(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        // load the table into memory
        string memory table = TABLE;

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
            for {

            } lt(dataPtr, endPtr) {

            } {
                dataPtr := add(dataPtr, 3)

                // read 3 bytes
                let input := mload(dataPtr)

                // write 4 characters
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(input, 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
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

/**
 * SPDX-License-Identifier: MIT
 * @author a1rsupp0rt
 */

pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

abstract contract OwnableUpgradeable is Initializable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    function __Ownable__init() public initializer {
        _setOwner(msg.sender);
    }

    function ownerOfContract() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(
            ownerOfContract() == msg.sender,
            "Ownable: caller is not the owner"
        );
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnershipTo(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

library StringUtils {
    /** @dev Concatenates five strings.
     * @param _a a string to be concatenated
     * @param _b a string to be concatenated
     * @param _c a string to be concatenated
     * @param _d a string to be concatenated
     * @param _e a string to be concatenated
     * @return _concat the concatenated string
     */
    function strConcat(
        string memory _a,
        string memory _b,
        string memory _c,
        string memory _d,
        string memory _e
    ) internal pure returns (string memory _concat) {
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        bytes memory _bc = bytes(_c);
        bytes memory _bd = bytes(_d);
        bytes memory _be = bytes(_e);
        string memory abcde = new string(
            _ba.length + _bb.length + _bc.length + _bd.length + _be.length
        );
        bytes memory babcde = bytes(abcde);
        uint256 k = 0;
        for (uint256 i = 0; i < _ba.length; i++) babcde[k++] = _ba[i];
        for (uint256 i = 0; i < _bb.length; i++) babcde[k++] = _bb[i];
        for (uint256 i = 0; i < _bc.length; i++) babcde[k++] = _bc[i];
        for (uint256 i = 0; i < _bd.length; i++) babcde[k++] = _bd[i];
        for (uint256 i = 0; i < _be.length; i++) babcde[k++] = _be[i];
        return string(babcde);
    }

    /** @dev Concatenates four strings.
     * @param _a a string to be concatenated
     * @param _b a string to be concatenated
     * @param _c a string to be concatenated
     * @param _d a string to be concatenated
     * @return _concat the concatenated string
     */
    function strConcat(
        string memory _a,
        string memory _b,
        string memory _c,
        string memory _d
    ) internal pure returns (string memory _concat) {
        return strConcat(_a, _b, _c, _d, "");
    }

    /** @dev Concatenates three strings.
     * @param _a a string to be concatenated
     * @param _b a string to be concatenated
     * @param _c a string to be concatenated
     * @return _concat the concatenated string
     */
    function strConcat(
        string memory _a,
        string memory _b,
        string memory _c
    ) internal pure returns (string memory _concat) {
        return strConcat(_a, _b, _c, "", "");
    }

    /** @dev Concatenates two strings.
     * @param _a a string to be concatenated
     * @param _b a string to be concatenated
     * @return _concat the concatenated string
     */
    function strConcat(string memory _a, string memory _b)
        internal
        pure
        returns (string memory _concat)
    {
        return strConcat(_a, _b, "", "", "");
    }

    /** @dev Returns the string representation of a uint256.
     * @param _i the integer to be stringified
     * @return _uintAsString the integer as string
     */
    function uint2str(uint256 _i)
        internal
        pure
        returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len - 1;
        while (_i != 0) {
            bstr[k--] = bytes1(uint8(48 + (_i % 10)));
            _i /= 10;
        }
        return string(bstr);
    }
}