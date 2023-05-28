// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

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
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
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
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
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
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Base64.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides a set of functions to operate with Base64 strings.
 *
 * _Available since v4.5._
 */
library Base64 {
    /**
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        /// @solidity memory-safe-assembly
        assembly {
            // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // To write each character, shift the 3 bytes (18 bits) chunk
                // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
                // and apply logical AND with 0x3F which is the number of
                // the previous character in the ASCII table prior to the Base64 Table
                // The result is then added to the table to get the character to write,
                // and finally write it in the result pointer but with a left shift
                // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

            // When data `bytes` is not exactly 3 bytes long
            // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
//solhint-disable no-inline-assembly, no-empty-blocks
pragma solidity ^0.8.20;

import { IERC721 } from "../interfaces/IERC721.sol";

import { LibUtils } from "../libraries/LibUtils.sol";
import { LibERC721, StorageLayout } from "../libraries/LibERC721.sol";
import { LibTraitManager } from "../libraries/LibTraitManager.sol";

import { DefaultOperatorFiltererUpgradeable } from "operator-filter-registry/src/upgradeable/DefaultOperatorFiltererUpgradeable.sol";

/**
 * @title ERC721A
 *
 * @dev Original contract author Chiru Labs [https://github.com/chiru-labs/ERC721A]
 *      Implementation has been modified.
 */
contract ERC721Facet is IERC721, DefaultOperatorFiltererUpgradeable {
  // =============================================================
  //                           CONSTANTS
  // =============================================================
  uint256 private constant _BITPOS_NUMBER_MINTED = 64;
  uint256 private constant _BITPOS_AUX = 192;
  uint256 private constant _BITMASK_AUX_COMPLEMENT = (1 << 192) - 1;
  uint256 private constant _BITPOS_START_TIMESTAMP = 160;
  uint256 private constant _BITPOS_EXTRA_DATA = 232;
  uint256 private constant _BITMASK_EXTRA_DATA_COMPLEMENT = (1 << 232) - 1;

  // =============================================================
  //                   TOKEN COUNTING OPERATIONS
  // =============================================================

  function totalSupply() public view returns (uint256) {
    unchecked {
      return LibERC721.totalSupply();
    }
  }

  function creatorSupply() public view returns (uint16) {
    unchecked {
      return LibERC721.getStorage().creatorSupply;
    }
  }

  function maxSupply() public view returns (uint16) {
    return LibERC721.getStorage().maxSupply;
  }

  function creatorMaxSupply() public view returns (uint16) {
    return LibERC721.getStorage().creatorMaxSupply;
  }

  function _totalMinted() internal view returns (uint256) {
    unchecked {
      return LibERC721.getStorage()._currentIndex - LibERC721._startTokenId();
    }
  }

  function _totalBurned() internal view returns (uint256) {
    return LibERC721.getStorage()._burnCounter;
  }

  // =============================================================
  //                    ADDRESS DATA OPERATIONS
  // =============================================================

  function balanceOf(address owner) public view returns (uint256) {
    return LibERC721.balanceOf(owner);
  }

  function _numberMinted(address owner) internal view returns (uint256) {
    return (LibERC721.getStorage()._packedAddressData[owner] >> _BITPOS_NUMBER_MINTED) & LibERC721._BITMASK_ADDRESS_DATA_ENTRY;
  }

  function _numberBurned(address owner) internal view returns (uint256) {
    return (LibERC721.getStorage()._packedAddressData[owner] >> LibERC721._BITPOS_NUMBER_BURNED) & LibERC721._BITMASK_ADDRESS_DATA_ENTRY;
  }

  function _getAux(address owner) internal view returns (uint64) {
    return uint64(LibERC721.getStorage()._packedAddressData[owner] >> _BITPOS_AUX);
  }

  function _setAux(address owner, uint64 aux) internal {
    StorageLayout storage ds = LibERC721.getStorage();
    uint256 packed = ds._packedAddressData[owner];
    uint256 auxCasted;
    // Cast `aux` with assembly to avoid redundant masking.
    assembly {
      auxCasted := aux
    }
    packed = (packed & _BITMASK_AUX_COMPLEMENT) | (auxCasted << _BITPOS_AUX);
    ds._packedAddressData[owner] = packed;
  }

  // =============================================================
  //                        IERC721Metadata
  // =============================================================

  function name() public view returns (string memory) {
    return LibERC721.getStorage().name;
  }

  function symbol() public view returns (string memory) {
    return LibERC721.getStorage().symbol;
  }

  function tokenURI(uint256 tokenId) public view returns (string memory) {
    if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

    return LibTraitManager.getTokenURI(uint16(tokenId));
  }

  // =============================================================
  //                     OWNERSHIPS OPERATIONS
  // =============================================================

  function ownerOf(uint256 tokenId) public view returns (address) {
    return LibERC721.ownerOf(tokenId);
  }

  function _ownershipOf(uint256 tokenId) internal view returns (TokenOwnership memory) {
    return _unpackedOwnership(LibERC721._packedOwnershipOf(tokenId));
  }

  function _ownershipAt(uint256 index) internal view returns (TokenOwnership memory) {
    return _unpackedOwnership(LibERC721.getStorage()._packedOwnerships[index]);
  }

  function _initializeOwnershipAt(uint256 index) internal {
    StorageLayout storage ds = LibERC721.getStorage();
    if (ds._packedOwnerships[index] == 0) {
      ds._packedOwnerships[index] = LibERC721._packedOwnershipOf(index);
    }
  }

  function _unpackedOwnership(uint256 packed) private pure returns (TokenOwnership memory ownership) {
    ownership.addr = address(uint160(packed));
    ownership.startTimestamp = uint64(packed >> _BITPOS_START_TIMESTAMP);
    ownership.burned = packed & LibERC721._BITMASK_BURNED != 0;
    ownership.extraData = uint24(packed >> _BITPOS_EXTRA_DATA);
  }

  // =============================================================
  //                      APPROVAL OPERATIONS
  // =============================================================

  function approve(address to, uint256 tokenId) public payable onlyAllowedOperatorApproval(to) {
    _approve(to, tokenId, true);
  }

  function getApproved(uint256 tokenId) public view returns (address) {
    if (!_exists(tokenId)) revert ApprovalQueryForNonexistentToken();

    return LibERC721.getStorage()._tokenApprovals[tokenId].value;
  }

  function setApprovalForAll(address operator, bool approved) public onlyAllowedOperatorApproval(operator) {
    LibERC721.getStorage()._operatorApprovals[LibUtils.msgSender()][operator] = approved;
    emit ApprovalForAll(LibUtils.msgSender(), operator, approved);
  }

  function isApprovedForAll(address owner, address operator) public view returns (bool) {
    return LibERC721.isApprovedForAll(owner, operator);
  }

  function _exists(uint256 tokenId) internal view returns (bool) {
    StorageLayout storage ds = LibERC721.getStorage();
    return
      LibERC721._startTokenId() <= tokenId &&
      tokenId < ds._currentIndex && // If within bounds,
      ds._packedOwnerships[tokenId] & LibERC721._BITMASK_BURNED == 0; // and not burned.
  }

  // =============================================================
  //                      TRANSFER OPERATIONS
  // =============================================================

  function transferFrom(address from, address to, uint256 tokenId) public payable onlyAllowedOperatorApproval(from) {
    LibERC721.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId) public payable onlyAllowedOperatorApproval(from) {
    safeTransferFrom(from, to, tokenId, "");
  }

  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public payable onlyAllowedOperatorApproval(from) {
    LibERC721.safeTransferFrom(from, to, tokenId, _data);
  }

  function transferMany(address from, address to, uint256[] calldata tokens) external {
    for (uint256 index = 0; index < tokens.length; index++) {
      safeTransferFrom(from, to, tokens[index], "");
    }
  }

  // =============================================================
  //                       APPROVAL OPERATIONS
  // =============================================================

  function _approve(address to, uint256 tokenId) internal {
    _approve(to, tokenId, false);
  }

  function _approve(address to, uint256 tokenId, bool approvalCheck) internal {
    address owner = ownerOf(tokenId);

    if (approvalCheck)
      if (LibUtils.msgSender() != owner)
        if (!isApprovedForAll(owner, LibUtils.msgSender())) {
          revert ApprovalCallerNotOwnerNorApproved();
        }

    LibERC721.getStorage()._tokenApprovals[tokenId].value = to;
    emit Approval(owner, to, tokenId);
  }

  // =============================================================
  //                     EXTRA DATA OPERATIONS
  // =============================================================

  function _setExtraDataAt(uint256 index, uint24 extraData) internal {
    uint256 packed = LibERC721.getStorage()._packedOwnerships[index];
    if (packed == 0) revert OwnershipNotInitializedForExtraData();
    uint256 extraDataCasted;
    assembly {
      extraDataCasted := extraData
    }
    packed = (packed & _BITMASK_EXTRA_DATA_COMPLEMENT) | (extraDataCasted << _BITPOS_EXTRA_DATA);
    LibERC721.getStorage()._packedOwnerships[index] = packed;
  }
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.2.3
// Creator: Chiru Labs

pragma solidity ^0.8.20;

/**
 * @dev Interface of ERC721A.
 */
interface IERC721 {
  /**
   * The caller must own the token or be an approved operator.
   */
  error ApprovalCallerNotOwnerNorApproved();

  /**
   * The token does not exist.
   */
  error ApprovalQueryForNonexistentToken();

  /**
   * Cannot query the balance for the zero address.
   */
  error BalanceQueryForZeroAddress();

  /**
   * Cannot mint to the zero address.
   */
  error MintToZeroAddress();

  /**
   * The quantity of tokens minted must be more than zero.
   */
  error MintZeroQuantity();

  /**
   * The token does not exist.
   */
  error OwnerQueryForNonexistentToken();

  /**
   * The caller must own the token or be an approved operator.
   */
  error TransferCallerNotOwnerNorApproved();

  /**
   * The token must be owned by `from`.
   */
  error TransferFromIncorrectOwner();

  /**
   * Cannot safely transfer to a contract that does not implement the
   * ERC721Receiver interface.
   */
  error TransferToNonERC721ReceiverImplementer();

  /**
   * Cannot transfer to the zero address.
   */
  error TransferToZeroAddress();

  /**
   * The token does not exist.
   */
  error URIQueryForNonexistentToken();

  /**
   * The `extraData` cannot be set on an unintialized ownership slot.
   */
  error OwnershipNotInitializedForExtraData();

  // =============================================================
  //                            STRUCTS
  // =============================================================

  struct TokenOwnership {
    // The address of the owner.
    address addr;
    // Stores the start time of ownership with minimal overhead for tokenomics.
    uint64 startTimestamp;
    // Whether the token has been burned.
    bool burned;
    // Arbitrary data similar to `startTimestamp` that can be set via {_extraData}.
    uint24 extraData;
  }

  // =============================================================
  //                         TOKEN COUNTERS
  // =============================================================

  /**
   * @dev Returns the total number of tokens in existence.
   * Burned tokens will reduce the count.
   * To get the total number of tokens minted, please see {_totalMinted}.
   */
  function totalSupply() external view returns (uint256);

  // =============================================================
  //                            IERC721
  // =============================================================

  /**
   * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
   */
  event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

  /**
   * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
   */
  event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

  /**
   * @dev Emitted when `owner` enables or disables
   * (`approved`) `operator` to manage all of its assets.
   */
  event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

  /**
   * @dev Returns the number of tokens in `owner`'s account.
   */
  function balanceOf(address owner) external view returns (uint256 balance);

  /**
   * @dev Returns the owner of the `tokenId` token.
   *
   * Requirements:
   *
   * - `tokenId` must exist.
   */
  function ownerOf(uint256 tokenId) external view returns (address owner);

  /**
   * @dev Safely transfers `tokenId` token from `from` to `to`,
   * checking first that contract recipients are aware of the ERC721 protocol
   * to prevent tokens from being forever locked.
   *
   * Requirements:
   *
   * - `from` cannot be the zero address.
   * - `to` cannot be the zero address.
   * - `tokenId` token must exist and be owned by `from`.
   * - If the caller is not `from`, it must be have been allowed to move
   * this token by either {approve} or {setApprovalForAll}.
   * - If `to` refers to a smart contract, it must implement
   * {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
   *
   * Emits a {Transfer} event.
   */
  function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external payable;

  /**
   * @dev Equivalent to `safeTransferFrom(from, to, tokenId, '')`.
   */
  function safeTransferFrom(address from, address to, uint256 tokenId) external payable;

  /**
   * @dev Transfers `tokenId` from `from` to `to`.
   *
   * WARNING: Usage of this method is discouraged, use {safeTransferFrom}
   * whenever possible.
   *
   * Requirements:
   *
   * - `from` cannot be the zero address.
   * - `to` cannot be the zero address.
   * - `tokenId` token must be owned by `from`.
   * - If the caller is not `from`, it must be approved to move this token
   * by either {approve} or {setApprovalForAll}.
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(address from, address to, uint256 tokenId) external payable;

  /**
   * @dev Gives permission to `to` to transfer `tokenId` token to another account.
   * The approval is cleared when the token is transferred.
   *
   * Only a single account can be approved at a time, so approving the
   * zero address clears previous approvals.
   *
   * Requirements:
   *
   * - The caller must own the token or be an approved operator.
   * - `tokenId` must exist.
   *
   * Emits an {Approval} event.
   */
  function approve(address to, uint256 tokenId) external payable;

  /**
   * @dev Approve or remove `operator` as an operator for the caller.
   * Operators can call {transferFrom} or {safeTransferFrom}
   * for any token owned by the caller.
   *
   * Requirements:
   *
   * - The `operator` cannot be the caller.
   *
   * Emits an {ApprovalForAll} event.
   */
  function setApprovalForAll(address operator, bool _approved) external;

  /**
   * @dev Returns the account approved for `tokenId` token.
   *
   * Requirements:
   *
   * - `tokenId` must exist.
   */
  function getApproved(uint256 tokenId) external view returns (address operator);

  /**
   * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
   *
   * See {setApprovalForAll}.
   */
  function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { LibUtils } from "./LibUtils.sol";
import { LibIdentity } from "./LibIdentity.sol";
import { LibMarketplace } from "./LibMarketplace.sol";

interface IERC721Receiver {
  function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

struct TokenApprovalRef {
  address value;
}

struct StorageLayout {
  string name;
  string symbol;
  uint16 maxSupply;
  uint16 creatorSupply;
  uint16 creatorMaxSupply;
  bool burnActive;
  uint256 _currentIndex;
  uint256 _burnCounter;
  mapping(uint256 => uint256) _packedOwnerships;
  mapping(address => uint256) _packedAddressData;
  mapping(uint256 => TokenApprovalRef) _tokenApprovals;
  mapping(address => mapping(address => bool)) _operatorApprovals;
}

//solhint-disable no-inline-assembly, reason-string, no-empty-blocks
library LibERC721 {
  bytes32 internal constant STORAGE_SLOT = keccak256("ERC721A.contracts.storage.ERC721A");
  uint256 internal constant _BITMASK_ADDRESS_DATA_ENTRY = (1 << 64) - 1;
  uint256 internal constant _BITMASK_BURNED = 1 << 224;
  uint256 internal constant _BITPOS_NUMBER_BURNED = 128;
  uint256 internal constant _BITMASK_NEXT_INITIALIZED = 1 << 225;
  uint256 internal constant _BITMASK_ADDRESS = (1 << 160) - 1;

  function getStorage() internal pure returns (StorageLayout storage strg) {
    bytes32 slot = STORAGE_SLOT;
    assembly {
      strg.slot := slot
    }
  }

  // =============================================================
  //                        MINT OPERATIONS
  // =============================================================

  function _mint(address to, uint256 quantity) internal {
    StorageLayout storage ds = getStorage();
    uint256 startTokenId = ds._currentIndex;

    require(quantity > 0, "LibERC721: Cant mint 0 tokens");
    require(totalSupply() + quantity <= ds.maxSupply, "LibERC721: Max supply exceeded");
    bytes32 transferEventSig = 0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef;
    uint256 bitMaskAddress = (1 << 160) - 1;

    unchecked {
      ds._packedAddressData[to] += quantity * ((1 << 64) | 1);
      ds._packedOwnerships[startTokenId] = _packOwnershipData(to, _nextInitializedFlag(quantity) | _nextExtraData(address(0), to, 0));

      uint256 toMasked;
      uint256 end = startTokenId + quantity;

      assembly {
        toMasked := and(to, bitMaskAddress)
        log4(0, 0, transferEventSig, 0, toMasked, startTokenId)
        for {
          let tokenId := add(startTokenId, 1)
        } iszero(eq(tokenId, end)) {
          tokenId := add(tokenId, 1)
        } {
          log4(0, 0, transferEventSig, 0, toMasked, tokenId)
        }
      }
      require(toMasked != 0, "LibERC721: Cant mint to zero address");
      ds._currentIndex = end;
    }
  }

  function _safeMint(address to, uint256 quantity, bytes memory _data) internal {
    StorageLayout storage ds = getStorage();
    _mint(to, quantity);

    unchecked {
      if (to.code.length != 0) {
        uint256 end = ds._currentIndex;
        uint256 index = end - quantity;
        do {
          if (!_checkContractOnERC721Received(address(0), to, index++, _data)) {
            revert("LibERC721: Transfer to non ERC721Receiver");
          }
        } while (index < end);
        // Reentrancy protection.
        // solhint-disable-next-line reason-string
        if (ds._currentIndex != end) revert();
      }
    }
  }

  // =============================================================
  //                        BURN OPERATIONS
  // =============================================================

  function _burn(uint256 tokenId) internal {
    _burn(tokenId, false);
  }

  event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

  function _burn(uint256 tokenId, bool approvalCheck) internal {
    StorageLayout storage ds = getStorage();
    uint256 prevOwnershipPacked = _packedOwnershipOf(tokenId);
    address from = address(uint160(prevOwnershipPacked));
    (uint256 approvedAddressSlot, address approvedAddress) = _getApprovedSlotAndAddress(tokenId);

    if (approvalCheck) {
      if (!_isSenderApprovedOrOwner(approvedAddress, from, LibUtils.msgSender()))
        if (!isApprovedForAll(from, LibUtils.msgSender())) revert("LibERC721: Call not authorized");
    }

    LibERC721._beforeTokenTransfers(from, address(0), tokenId, 1);

    assembly {
      if approvedAddress {
        sstore(approvedAddressSlot, 0)
      }
    }

    unchecked {
      ds._packedAddressData[from] += (1 << _BITPOS_NUMBER_BURNED) - 1;
      ds._packedOwnerships[tokenId] = LibERC721._packOwnershipData(
        from,
        (_BITMASK_BURNED | _BITMASK_NEXT_INITIALIZED) | LibERC721._nextExtraData(from, address(0), prevOwnershipPacked)
      );

      if (prevOwnershipPacked & _BITMASK_NEXT_INITIALIZED == 0) {
        uint256 _nextTokenId = tokenId + 1;
        if (ds._packedOwnerships[_nextTokenId] == 0) {
          if (_nextTokenId != ds._currentIndex) {
            ds._packedOwnerships[_nextTokenId] = prevOwnershipPacked;
          }
        }
      }
    }

    emit Transfer(from, address(0), tokenId);
    LibERC721._afterTokenTransfers(from, address(0), tokenId, 1);

    unchecked {
      ds._burnCounter++;
    }
  }

  function transferFrom(address from, address to, uint256 tokenId) internal {
    StorageLayout storage ds = getStorage();
    uint256 prevOwnershipPacked = _packedOwnershipOf(tokenId);

    if (address(uint160(prevOwnershipPacked)) != from) revert("LibERC721: Transfer from incorrect owner");

    (uint256 approvedAddressSlot, address approvedAddress) = _getApprovedSlotAndAddress(tokenId);

    if (!_isSenderApprovedOrOwner(approvedAddress, from, LibUtils.msgSender()))
      if (!isApprovedForAll(from, LibUtils.msgSender()) || LibUtils.msgSender() != address(this)) revert("LibERC721: Caller not owner nor approved");

    if (to == address(0)) revert("LibERC721: Transfer to zero address");

    _beforeTokenTransfers(from, to, tokenId, 1);

    assembly {
      if approvedAddress {
        sstore(approvedAddressSlot, 0)
      }
    }

    unchecked {
      --ds._packedAddressData[from];
      ++ds._packedAddressData[to];

      ds._packedOwnerships[tokenId] = _packOwnershipData(to, _BITMASK_NEXT_INITIALIZED | _nextExtraData(from, to, prevOwnershipPacked));

      if (prevOwnershipPacked & _BITMASK_NEXT_INITIALIZED == 0) {
        uint256 _nextTokenId = tokenId + 1;
        if (ds._packedOwnerships[_nextTokenId] == 0) {
          if (_nextTokenId != ds._currentIndex) {
            ds._packedOwnerships[_nextTokenId] = prevOwnershipPacked;
          }
        }
      }
    }

    emit Transfer(from, to, tokenId);
    _afterTokenTransfers(from, to, tokenId, 1);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) internal {
    transferFrom(from, to, tokenId);
    if (to.code.length != 0)
      if (!_checkContractOnERC721Received(from, to, tokenId, _data)) {
        revert("LibERC721: Transfer to non ERC721 receiver");
      }
  }

  function isApprovedForAll(address owner, address operator) internal view returns (bool) {
    return getStorage()._operatorApprovals[owner][operator];
  }

  function _isSenderApprovedOrOwner(address approvedAddress, address owner, address msgSender) internal pure returns (bool result) {
    assembly {
      owner := and(owner, _BITMASK_ADDRESS)
      msgSender := and(msgSender, _BITMASK_ADDRESS)
      result := or(eq(msgSender, owner), eq(msgSender, approvedAddress))
    }
  }

  function _checkContractOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data) internal returns (bool) {
    try IERC721Receiver(to).onERC721Received(LibUtils.msgSender(), from, tokenId, _data) returns (bytes4 retval) {
      return retval == IERC721Receiver(to).onERC721Received.selector;
    } catch (bytes memory reason) {
      require(reason.length > 0, "LibERC721: Transfer to non ERC721Receiver");
      assembly {
        revert(add(32, reason), mload(reason))
      }
    }
  }

  function _beforeTokenTransfers(address from, address to, uint256 tokenId, uint256 quantity) internal {}

  function _afterTokenTransfers(address from, address, uint256 tokenId, uint256) internal {
    if (from != address(0)) {
      if (balanceOf(from) == 0) LibIdentity.nukeIdentity(from);
      if (LibMarketplace.isListed(tokenId)) LibMarketplace.cancelListing(tokenId);
    }
  }

  function _nextInitializedFlag(uint256 quantity) internal pure returns (uint256 result) {
    // For branchless setting of the `nextInitialized` flag.
    assembly {
      // `(quantity == 1) << _BITPOS_NEXT_INITIALIZED`.
      result := shl(225, eq(quantity, 1))
    }
  }

  function _nextExtraData(address from, address to, uint256 prevOwnershipPacked) internal view returns (uint256) {
    uint24 extraData = uint24(prevOwnershipPacked >> 232);
    return uint256(_extraData(from, to, extraData)) << 232;
  }

  function _extraData(address from, address to, uint24 previousExtraData) internal view returns (uint24) {}

  function _packOwnershipData(address owner, uint256 flags) internal view returns (uint256 result) {
    uint256 bitMaskAddress = (1 << 160) - 1;
    assembly {
      // Mask `owner` to the lower 160 bits, in case the upper bits somehow aren't clean.
      owner := and(owner, bitMaskAddress)
      // `owner | (block.timestamp << _BITPOS_START_TIMESTAMP) | flags`.
      result := or(owner, or(shl(160, timestamp()), flags))
    }
  }

  function _startTokenId() internal pure returns (uint256) {
    return 1;
  }

  function nextTokenId() internal view returns (uint256) {
    return getStorage()._currentIndex;
  }

  function balanceOf(address owner) internal view returns (uint256) {
    require(owner != address(0), "LibERC721: Invalid address");
    return LibERC721.getStorage()._packedAddressData[owner] & LibERC721._BITMASK_ADDRESS_DATA_ENTRY;
  }

  function ownerOf(uint256 tokenId) internal view returns (address) {
    return address(uint160(_packedOwnershipOf(tokenId)));
  }

  function totalSupply() internal view returns (uint256) {
    // Counter underflow is impossible as _burnCounter cannot be incremented
    // more than `_currentIndex - _startTokenId()` times.
    unchecked {
      return getStorage()._currentIndex - getStorage()._burnCounter - _startTokenId();
    }
  }

  function _packedOwnershipOf(uint256 tokenId) internal view returns (uint256 packed) {
    StorageLayout storage ds = LibERC721.getStorage();
    if (LibERC721._startTokenId() <= tokenId) {
      packed = ds._packedOwnerships[tokenId];
      if (packed & _BITMASK_BURNED == 0) {
        if (packed == 0) {
          if (tokenId >= ds._currentIndex) revert("LibERC721: Owner query for non existing token");
          for (;;) {
            unchecked {
              packed = ds._packedOwnerships[--tokenId];
            }
            if (packed == 0) continue;
            return packed;
          }
        }
        return packed;
      }
    }
    revert("LibERC721: Owner query for non existing token");
  }

  function _getApprovedSlotAndAddress(uint256 tokenId) internal view returns (uint256 approvedAddressSlot, address approvedAddress) {
    TokenApprovalRef storage tokenApproval = getStorage()._tokenApprovals[tokenId];
    assembly {
      approvedAddressSlot := tokenApproval.slot
      approvedAddress := sload(approvedAddressSlot)
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

struct IDField {
  string name;
  string data;
}

struct Identity {
  uint8 fieldCount;
  uint8 unlockedFields;
  uint16 assignedToken;
  uint256 scrollId;
  mapping(uint8 => IDField) fields;
}

struct IdentityExternal {
  uint8 fieldCount;
  uint8 unlockedFields;
  IDField[] fields;
}

struct IdentityLayout {
  uint8 maxFields;
  uint8 maxScrollsPerToken;
  uint16 identitiesRecorded;
  uint256 scrollSupply;
  mapping(uint256 => bool) usedScrolls;
  mapping(address => Identity) userIdentity;
}

library LibIdentity {
  bytes32 internal constant IDENTITY_DATA_SLOT = keccak256("user.identity.data.layout");

  function getStorage() internal pure returns (IdentityLayout storage strg) {
    bytes32 slot = IDENTITY_DATA_SLOT;
    assembly {
      strg.slot := slot
    }
  }

  function nukeIdentity(address user) internal {
    IdentityLayout storage idStorage = getStorage();

    for (uint8 i = 0; i < idStorage.userIdentity[user].fieldCount; i++) {
      delete idStorage.userIdentity[user].fields[i];
    }

    idStorage.identitiesRecorded--;
    delete idStorage.userIdentity[user].fieldCount;
    delete idStorage.userIdentity[user].unlockedFields;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

struct Listing {
  uint256 id;
  address seller;
  address sell_to;
  uint256 tokenId;
  uint256 price;
  uint256 sold_on;
  address sold_to;
  bool cancelled;
  uint256 created_on;
  uint256 modified_on;
}

struct ListingCounters {
  uint256 totalListings;
  uint256 activeListings;
}

struct TokenListingData {
  bool isListed;
  uint256 listingId;
}

struct MarketplaceLayout {
  ListingCounters listingCounts;
  mapping(uint256 => Listing) listings;
  mapping(address => ListingCounters) userCounts;
  mapping(address => uint256[]) userListings;
  mapping(uint256 => TokenListingData) token;
}

library LibMarketplace {
  bytes32 internal constant MARKETPLACE_DATA_SLOT = keccak256("erc721.marketplace.storage.layout");

  function getStorage() internal pure returns (MarketplaceLayout storage strg) {
    bytes32 slot = MARKETPLACE_DATA_SLOT;
    assembly {
      strg.slot := slot
    }
  }

  function increaseCounters(ListingCounters storage strg, uint256 total, uint256 active) internal {
    strg.totalListings += total;
    strg.activeListings += active;
  }

  function decreaseCounters(ListingCounters storage strg, uint256 total, uint256 active) internal {
    strg.totalListings -= total;
    strg.activeListings -= active;
  }

  function cancelListing(uint256 tokenId) internal {
    MarketplaceLayout storage ls = getStorage();
    TokenListingData storage currentToken = ls.token[tokenId];
    Listing storage currentListing = ls.listings[currentToken.listingId];

    currentListing.cancelled = true;
    currentListing.modified_on = block.timestamp;
    ls.token[tokenId] = TokenListingData({ isListed: false, listingId: 0 });

    decreaseCounters(ls.listingCounts, 0, 1);
    decreaseCounters(ls.userCounts[currentListing.seller], 0, 1);
  }

  function isListed(uint256 tokenId) internal view returns (bool) {
    return getStorage().token[tokenId].isListed;
  }
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.20;
//solhint-disable no-inline-assembly, not-rely-on-time

import { LibUtils } from "./LibUtils.sol";
import { Base64 } from "@openzeppelin/contracts/utils/Base64.sol";

struct TraitExternal {
  string layerName;
  string traitName;
  uint16 traitId;
}

struct TokenMetadataExternal {
  string name;
  TraitExternal[] attributes;
}

struct LayerSetup {
  string layerName;
  uint8 layerId;
  uint256 traitCount;
}

struct TraitSetup {
  uint8 layerId;
  string name;
  string dataURL;
  uint16 weight;
}

struct Trait {
  string name;
  string dataURL;
  uint16 weight;
}

struct Layer {
  string name;
  Trait[] traits;
}

struct LayerData {
  Layer[] layers;
  mapping(bytes32 => bool) dnaExist;
  mapping(uint256 => uint16) totalWeights;
}

struct TokenMetadata {
  string name;
  uint16[] attributes;
}

struct TokenDataLayout {
  mapping(uint16 => TokenMetadata) tokens;
  mapping(uint16 => bool) tokenExist;
}

library LibTraitManager {
  bytes32 internal constant LAYER_DATA_SLOT = keccak256("trait.manager.layer.data");
  bytes32 internal constant TOKEN_DATA_SLOT = keccak256("trait.manager.token.metadata");

  /* prettier-ignore */
  string internal constant SVGTAG_HEADER = "<svg id=\"token\" width=\"100%\" height=\"100%\" version=\"1.1\" viewBox=\"0 0 64 64\" xmlns=\"http://www.w3.org/2000/svg\" xmlns:xlink=\"http://www.w3.org/1999/xlink\">";
  /* prettier-ignore */
  string internal constant SVGTAG_FOOTER = "<style>#token{shape-rendering: crispedges; image-rendering: -webkit-crisp-edges; image-rendering: -moz-crisp-edges; image-rendering: crisp-edges; image-rendering: pixelated; -ms-interpolation-mode: nearest-neighbor;}</style></svg>";
  string internal constant TOKEN_NAME_PREFIX = "My Fancy Collection #";

  function getLayerStorage() internal pure returns (LayerData storage strg) {
    bytes32 slot = LAYER_DATA_SLOT;
    assembly {
      strg.slot := slot
    }
  }

  function getTokenStorage() internal pure returns (TokenDataLayout storage strg) {
    bytes32 slot = TOKEN_DATA_SLOT;
    assembly {
      strg.slot := slot
    }
  }

  function enforceTokenExistence(uint16 tokenId) internal view {
    require(getTokenStorage().tokenExist[tokenId], "TraitManager: Token doesnt exist");
  }

  function createToken(uint16 tokenId, uint16[] calldata seeds) internal {
    TokenDataLayout storage tokenData = getTokenStorage();

    unchecked {
      tokenData.tokens[tokenId] = TokenMetadata({
        name: string(abi.encodePacked(TOKEN_NAME_PREFIX, LibUtils.numberToString(tokenId))),
        attributes: generateMetadata(tokenId, seeds)
      });
      tokenData.tokenExist[tokenId] = true;
    }
  }

  function createMultiple(uint16 startTokenId, uint16 amount, uint16[] calldata seeds) internal {
    unchecked {
      for (uint16 index = startTokenId; index < amount + startTokenId; index++) {
        createToken(index, seeds);
      }
    }
  }

  function generateMetadata(uint tokenId, uint16[] calldata seeds) internal returns (uint16[] memory) {
    LayerData storage layerStorage = getLayerStorage();
    uint256 layerCount = layerStorage.layers.length;

    unchecked {
      uint16 iteration = 1;
      uint16[] memory metadata = new uint16[](layerStorage.layers.length);

      for (uint8 index = 0; index < layerCount; index++) {
        metadata[index] = selectRandomTrait(layerStorage, index, tokenId, seeds[index], iteration, true);
      }

      bytes32 dnaHash = generateDNA(metadata);
      if (layerStorage.dnaExist[dnaHash]) {
        uint256 indexToChange = 0;
        bool foundUniqueDnaHash = false;
        while (!foundUniqueDnaHash) {
          iteration++;
          metadata[indexToChange] = selectRandomTrait(layerStorage, indexToChange, tokenId, seeds[indexToChange], iteration, true);

          dnaHash = generateDNA(metadata);
          if (!layerStorage.dnaExist[dnaHash]) {
            foundUniqueDnaHash = true;
            layerStorage.dnaExist[dnaHash] = true;
            break;
          }

          indexToChange = (indexToChange + 1) % layerCount;
        }
      }

      return metadata;
    }
  }

  function selectRandomTrait(
    LayerData storage layerStorage,
    uint256 layer,
    uint tokenId,
    uint seed,
    uint i,
    bool required
  ) internal view returns (uint16) {
    uint16 index;
    uint randomValIteration = 1;
    uint layerWeight = layerStorage.totalWeights[layer];

    /* solhint-disable */
    uint256 randomValue = randomize(tokenId, seed, i, layerWeight);

    if (required && randomValue == 0) {
      do {
        randomValIteration++;
        randomValue = randomize(tokenId * randomValIteration, seed * randomValIteration, i, layerWeight);
      } while (randomValue == 0);
    }
    /* solhint-enable */

    // TODO: maybe load traits in to memory first then attempt assembly
    // while (randomValue >= layerStorage.layers[layer].traits[traitIndex].weight) {
    //   randomValue -= layerStorage.layers[layer].traits[traitIndex].weight;
    //   traitIndex++;
    // }

    Layer storage selectedLayer = layerStorage.layers[layer];
    Trait[] storage traits = selectedLayer.traits;

    // prettier-ignore
    assembly {
      let traitIndex := 0
      let rnd := randomValue

      for {} lt(rnd, mload(add(add(traits.slot, mul(0x40, traitIndex)), 0x40))) {} {
        rnd := sub(rnd, mload(add(add(traits.slot, mul(0x40, traitIndex)), 0x40)))
        traitIndex := add(traitIndex, 1)
      }

      index := sub(traitIndex, 1)
    }

    return index;
  }

  function getTraitName(uint8 layerId, uint16 traitId) internal view returns (string memory) {
    return getLayerStorage().layers[layerId].traits[traitId].name;
  }

  function getLayerName(uint8 layerId) internal view returns (string memory) {
    return getLayerStorage().layers[layerId].name;
  }

  function getTraitDataURL(uint8 layerId, uint16 traitId) internal view returns (string memory) {
    return getLayerStorage().layers[layerId].traits[traitId].dataURL;
  }

  function getTokenMetadata(uint16 tokenId) internal view returns (TokenMetadataExternal memory) {
    enforceTokenExistence(tokenId);
    TokenMetadata memory token = getTokenStorage().tokens[tokenId];

    TokenMetadataExternal memory metadata;
    metadata.name = token.name;
    metadata.attributes = new TraitExternal[](token.attributes.length);

    for (uint8 index = 0; index < token.attributes.length; index++) {
      metadata.attributes[index] = TraitExternal({
        layerName: getLayerName(index),
        traitName: getTraitName(index, token.attributes[index]),
        traitId: token.attributes[index]
      });
    }

    return metadata;
  }

  function getTokenURI(uint16 tokenId) internal view returns (string memory) {
    enforceTokenExistence(tokenId);

    TokenMetadataExternal memory metadata = getTokenMetadata(tokenId);
    string memory svgData = generateSVG(metadata.attributes);

    /* prettier-ignore */
    return string(abi.encodePacked(
      "data:application/json;base64,",
      Base64.encode(bytes(string(abi.encodePacked(
        "{ \"name\": \"", metadata.name, "\", ",
          "\"attributes\": [",
            buildAttributesString(metadata.attributes),
          "], ",
          "\"image_data\": \"",
            svgData,
          "\"",
        " }"
      ))))
    ));
  }

  function buildAttributesString(TraitExternal[] memory attributes) internal pure returns (string memory) {
    string memory attributesString;
    /* prettier-ignore */
    for (uint8 i = 0; i < attributes.length; i++) {
      attributesString = string(
        abi.encodePacked(attributesString, "{ \"trait_type\": \"", attributes[i].layerName, "\", \"value\": \"", attributes[i].traitName, "\" }")
      );
      
      if (i < attributes.length - 1) {
        attributesString = string(abi.encodePacked(attributesString, ", "));
      }
    }
    return attributesString;
  }

  ////////////////////////////////////////////////////////////////////
  //
  //                        SVG FUNCTIONS
  //
  ////////////////////////////////////////////////////////////////////

  function generateSVG(TraitExternal[] memory attributes) internal view returns (string memory) {
    string memory svg = SVGTAG_HEADER;

    for (uint8 layerId = 0; layerId < attributes.length; layerId++) {
      svg = string(abi.encodePacked(svg, wrapDataURL(getTraitDataURL(layerId, attributes[layerId].traitId))));
    }

    svg = string(abi.encodePacked(svg, SVGTAG_FOOTER));

    return string(abi.encodePacked("data:image/svg+xml;base64,", Base64.encode(bytes(svg))));
  }

  /* prettier-ignore */
  function wrapDataURL(string memory dataURL) internal pure returns (string memory) {
    return string(abi.encodePacked("<image x=\"0\" y=\"0\" width=\"64\" height=\"64\" image-rendering=\"pixelated\" preserveAspectRatio=\"xMidYMid\" xlink:href=\"data:image/svg+xml;base64,", dataURL, "\"/>"));
  }

  ////////////////////////////////////////////////////////////////////
  //
  //                          UTILS
  //
  ////////////////////////////////////////////////////////////////////

  function generateDNA(uint16[] memory attributes) internal pure returns (bytes32) {
    bytes memory encoded;
    uint256 length = attributes.length;

    assembly {
      let data := add(attributes, 0x20)

      for {
        let i := 0
      } lt(i, length) {
        i := add(i, 1)
      } {
        let attribute := mload(add(data, mul(i, 0x20)))

        encoded := add(encoded, attribute)
      }
    }

    return keccak256(encoded);
  }

  function randomize(uint tokenId, uint seed, uint iteration, uint layerWeight) internal view returns (uint256) {
    uint256 result;
    uint256 currentTimestamp = block.timestamp;

    assembly {
      let data := mload(0x40)

      mstore(data, shl(96, caller()))
      mstore(add(data, 0x20), tokenId)
      mstore(add(data, 0x40), mul(tokenId, iteration))
      mstore(add(data, 0x60), div(currentTimestamp, iteration))
      mstore(add(data, 0x80), mul(currentTimestamp, iteration))
      mstore(add(data, 0xA0), number())
      mstore(add(data, 0xC0), mul(seed, iteration))

      let hash := keccak256(data, 0xE0)
      result := mod(hash, layerWeight)
    }

    return result;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// solhint-disable no-inline-assembly
library LibUtils {
  function msgSender() internal view returns (address sender_) {
    if (msg.sender == address(this)) {
      bytes memory array = msg.data;
      uint256 index = msg.data.length;
      assembly {
        // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
        sender_ := and(mload(add(array, index)), 0xffffffffffffffffffffffffffffffffffffffff)
      }
    } else {
      sender_ = msg.sender;
    }
  }

  function numberToString(uint256 value) internal pure returns (string memory str) {
    assembly {
      let m := add(mload(0x40), 0xa0)
      mstore(0x40, m)
      str := sub(m, 0x20)
      mstore(str, 0)

      let end := str

      // prettier-ignore
      // solhint-disable-next-line no-empty-blocks
      for { let temp := value } 1 {} {
        str := sub(str, 1)
        mstore8(str, add(48, mod(temp, 10)))
        temp := div(temp, 10)
        if iszero(temp) { break }
      }

      let length := sub(end, str)
      str := sub(str, 0x20)
      mstore(str, length)
    }
  }

  function addressToString(address _addr) internal pure returns (string memory) {
    bytes32 value = bytes32(uint256(uint160(_addr)));
    bytes memory alphabet = "0123456789abcdef";

    bytes memory str = new bytes(42);
    str[0] = "0";
    str[1] = "x";
    for (uint i = 0; i < 20; i++) {
      str[2 + i * 2] = alphabet[uint(uint8(value[i + 12] >> 4))];
      str[3 + i * 2] = alphabet[uint(uint8(value[i + 12] & 0x0f))];
    }
    return string(str);
  }

  function getMax(uint256[6] memory nums) internal pure returns (uint256 maxNum) {
    maxNum = nums[0];
    for (uint256 i = 1; i < nums.length; i++) {
      if (nums[i] > maxNum) maxNum = nums[i];
    }
  }

  function compareStrings(string memory str1, string memory str2) internal pure returns (bool) {
    return keccak256(abi.encodePacked(str1)) == keccak256(abi.encodePacked(str2));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IOperatorFilterRegistry {
    /**
     * @notice Returns true if operator is not filtered for a given token, either by address or codeHash. Also returns
     *         true if supplied registrant address is not registered.
     */
    function isOperatorAllowed(address registrant, address operator) external view returns (bool);

    /**
     * @notice Registers an address with the registry. May be called by address itself or by EIP-173 owner.
     */
    function register(address registrant) external;

    /**
     * @notice Registers an address with the registry and "subscribes" to another address's filtered operators and codeHashes.
     */
    function registerAndSubscribe(address registrant, address subscription) external;

    /**
     * @notice Registers an address with the registry and copies the filtered operators and codeHashes from another
     *         address without subscribing.
     */
    function registerAndCopyEntries(address registrant, address registrantToCopy) external;

    /**
     * @notice Unregisters an address with the registry and removes its subscription. May be called by address itself or by EIP-173 owner.
     *         Note that this does not remove any filtered addresses or codeHashes.
     *         Also note that any subscriptions to this registrant will still be active and follow the existing filtered addresses and codehashes.
     */
    function unregister(address addr) external;

    /**
     * @notice Update an operator address for a registered address - when filtered is true, the operator is filtered.
     */
    function updateOperator(address registrant, address operator, bool filtered) external;

    /**
     * @notice Update multiple operators for a registered address - when filtered is true, the operators will be filtered. Reverts on duplicates.
     */
    function updateOperators(address registrant, address[] calldata operators, bool filtered) external;

    /**
     * @notice Update a codeHash for a registered address - when filtered is true, the codeHash is filtered.
     */
    function updateCodeHash(address registrant, bytes32 codehash, bool filtered) external;

    /**
     * @notice Update multiple codeHashes for a registered address - when filtered is true, the codeHashes will be filtered. Reverts on duplicates.
     */
    function updateCodeHashes(address registrant, bytes32[] calldata codeHashes, bool filtered) external;

    /**
     * @notice Subscribe an address to another registrant's filtered operators and codeHashes. Will remove previous
     *         subscription if present.
     *         Note that accounts with subscriptions may go on to subscribe to other accounts - in this case,
     *         subscriptions will not be forwarded. Instead the former subscription's existing entries will still be
     *         used.
     */
    function subscribe(address registrant, address registrantToSubscribe) external;

    /**
     * @notice Unsubscribe an address from its current subscribed registrant, and optionally copy its filtered operators and codeHashes.
     */
    function unsubscribe(address registrant, bool copyExistingEntries) external;

    /**
     * @notice Get the subscription address of a given registrant, if any.
     */
    function subscriptionOf(address addr) external returns (address registrant);

    /**
     * @notice Get the set of addresses subscribed to a given registrant.
     *         Note that order is not guaranteed as updates are made.
     */
    function subscribers(address registrant) external returns (address[] memory);

    /**
     * @notice Get the subscriber at a given index in the set of addresses subscribed to a given registrant.
     *         Note that order is not guaranteed as updates are made.
     */
    function subscriberAt(address registrant, uint256 index) external returns (address);

    /**
     * @notice Copy filtered operators and codeHashes from a different registrantToCopy to addr.
     */
    function copyEntriesOf(address registrant, address registrantToCopy) external;

    /**
     * @notice Returns true if operator is filtered by a given address or its subscription.
     */
    function isOperatorFiltered(address registrant, address operator) external returns (bool);

    /**
     * @notice Returns true if the hash of an address's code is filtered by a given address or its subscription.
     */
    function isCodeHashOfFiltered(address registrant, address operatorWithCode) external returns (bool);

    /**
     * @notice Returns true if a codeHash is filtered by a given address or its subscription.
     */
    function isCodeHashFiltered(address registrant, bytes32 codeHash) external returns (bool);

    /**
     * @notice Returns a list of filtered operators for a given address or its subscription.
     */
    function filteredOperators(address addr) external returns (address[] memory);

    /**
     * @notice Returns the set of filtered codeHashes for a given address or its subscription.
     *         Note that order is not guaranteed as updates are made.
     */
    function filteredCodeHashes(address addr) external returns (bytes32[] memory);

    /**
     * @notice Returns the filtered operator at the given index of the set of filtered operators for a given address or
     *         its subscription.
     *         Note that order is not guaranteed as updates are made.
     */
    function filteredOperatorAt(address registrant, uint256 index) external returns (address);

    /**
     * @notice Returns the filtered codeHash at the given index of the list of filtered codeHashes for a given address or
     *         its subscription.
     *         Note that order is not guaranteed as updates are made.
     */
    function filteredCodeHashAt(address registrant, uint256 index) external returns (bytes32);

    /**
     * @notice Returns true if an address has registered
     */
    function isRegistered(address addr) external returns (bool);

    /**
     * @dev Convenience method to compute the code hash of an arbitrary contract
     */
    function codeHashOf(address addr) external returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

address constant CANONICAL_OPERATOR_FILTER_REGISTRY_ADDRESS = 0x000000000000AAeB6D7670E522A718067333cd4E;
address constant CANONICAL_CORI_SUBSCRIPTION = 0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6;

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {OperatorFiltererUpgradeable} from "./OperatorFiltererUpgradeable.sol";
import {CANONICAL_CORI_SUBSCRIPTION} from "../lib/Constants.sol";

/**
 * @title  DefaultOperatorFiltererUpgradeable
 * @notice Inherits from OperatorFiltererUpgradeable and automatically subscribes to the default OpenSea subscription
 *         when the init function is called.
 */
abstract contract DefaultOperatorFiltererUpgradeable is OperatorFiltererUpgradeable {
    /// @dev The upgradeable initialize function that should be called when the contract is being deployed.
    function __DefaultOperatorFilterer_init() internal onlyInitializing {
        OperatorFiltererUpgradeable.__OperatorFilterer_init(CANONICAL_CORI_SUBSCRIPTION, true);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IOperatorFilterRegistry} from "../IOperatorFilterRegistry.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @title  OperatorFiltererUpgradeable
 * @notice Abstract contract whose constructor automatically registers and optionally subscribes to or copies another
 *         registrant's entries in the OperatorFilterRegistry when the init function is called.
 * @dev    This smart contract is meant to be inherited by token contracts so they can use the following:
 *         - `onlyAllowedOperator` modifier for `transferFrom` and `safeTransferFrom` methods.
 *         - `onlyAllowedOperatorApproval` modifier for `approve` and `setApprovalForAll` methods.
 */
abstract contract OperatorFiltererUpgradeable is Initializable {
    /// @notice Emitted when an operator is not allowed.
    error OperatorNotAllowed(address operator);

    IOperatorFilterRegistry constant OPERATOR_FILTER_REGISTRY =
        IOperatorFilterRegistry(0x000000000000AAeB6D7670E522A718067333cd4E);

    /// @dev The upgradeable initialize function that should be called when the contract is being upgraded.
    function __OperatorFilterer_init(address subscriptionOrRegistrantToCopy, bool subscribe)
        internal
        onlyInitializing
    {
        // If an inheriting token contract is deployed to a network without the registry deployed, the modifier
        // will not revert, but the contract will need to be registered with the registry once it is deployed in
        // order for the modifier to filter addresses.
        if (address(OPERATOR_FILTER_REGISTRY).code.length > 0) {
            if (!OPERATOR_FILTER_REGISTRY.isRegistered(address(this))) {
                if (subscribe) {
                    OPERATOR_FILTER_REGISTRY.registerAndSubscribe(address(this), subscriptionOrRegistrantToCopy);
                } else {
                    if (subscriptionOrRegistrantToCopy != address(0)) {
                        OPERATOR_FILTER_REGISTRY.registerAndCopyEntries(address(this), subscriptionOrRegistrantToCopy);
                    } else {
                        OPERATOR_FILTER_REGISTRY.register(address(this));
                    }
                }
            }
        }
    }

    /**
     * @dev A helper modifier to check if the operator is allowed.
     */
    modifier onlyAllowedOperator(address from) virtual {
        // Allow spending tokens from addresses with balance
        // Note that this still allows listings and marketplaces with escrow to transfer tokens if transferred
        // from an EOA.
        if (from != msg.sender) {
            _checkFilterOperator(msg.sender);
        }
        _;
    }

    /**
     * @dev A helper modifier to check if the operator approval is allowed.
     */
    modifier onlyAllowedOperatorApproval(address operator) virtual {
        _checkFilterOperator(operator);
        _;
    }

    /**
     * @dev A helper function to check if the operator is allowed.
     */
    function _checkFilterOperator(address operator) internal view virtual {
        // Check registry code length to facilitate testing in environments without a deployed registry.
        if (address(OPERATOR_FILTER_REGISTRY).code.length > 0) {
            // under normal circumstances, this function will revert rather than return false, but inheriting or
            // upgraded contracts may specify their own OperatorFilterRegistry implementations, which may behave
            // differently
            if (!OPERATOR_FILTER_REGISTRY.isOperatorAllowed(address(this), operator)) {
                revert OperatorNotAllowed(operator);
            }
        }
    }
}