// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/Address.sol";

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
        return !Address.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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
// OpenZeppelin Contracts v4.4.1 (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
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

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/StorageSlot.sol";
import "../interfaces/IWeightedValidator.sol";
import "../extensions/HasProxyAdmin.sol";

contract RoninValidator is Initializable, IWeightedValidator, HasProxyAdmin {
  uint256 internal _num;
  uint256 internal _denom;
  uint256 internal _totalWeights;

  /// @dev Mapping from validator address => weight
  mapping(address => uint256) internal _validatorWeight;
  /// @dev Mapping from governor address => weight
  mapping(address => uint256) internal _governorWeight;
  /// @dev Validators array
  address[] internal _validators;
  /// @dev Governors array
  address[] internal _governors;

  uint256 public nonce;

  /**
   * @dev Initializes contract storage.
   */
  function initialize(
    WeightedValidator[] calldata _initValidators,
    uint256 _numerator,
    uint256 _denominator
  ) external virtual initializer {
    _addValidators(_initValidators);
    _setThreshold(_numerator, _denominator);
  }

  /**
   * @dev See {IWeightedValidator-getValidatorWeight}.
   */
  function getValidatorWeight(address _validator) external view virtual returns (uint256) {
    return _validatorWeight[_validator];
  }

  /**
   * @dev See {IWeightedValidator-getGovernorWeight}.
   */
  function getGovernorWeight(address _governor) external view virtual returns (uint256) {
    return _governorWeight[_governor];
  }

  /**
   * @dev See {IWeightedValidator-sumValidatorWeights}.
   */
  function sumValidatorWeights(address[] calldata _addrList) external view virtual returns (uint256 _weight) {
    for (uint256 _i; _i < _addrList.length; _i++) {
      _weight += _validatorWeight[_addrList[_i]];
    }
  }

  /**
   * @dev See {IWeightedValidator-sumGovernorWeights}.
   */
  function sumGovernorWeights(address[] calldata _addrList) external view virtual returns (uint256 _weight) {
    for (uint256 _i; _i < _addrList.length; _i++) {
      _weight += _governorWeight[_addrList[_i]];
    }
  }

  /**
   * @dev See {IWeightedValidator-getValidatorInfo}.
   */
  function getValidatorInfo() external view virtual returns (WeightedValidator[] memory _list) {
    _list = new WeightedValidator[](_validators.length);
    address _validator;
    for (uint256 _i; _i < _list.length; _i++) {
      _validator = _validators[_i];
      _list[_i].validator = _validator;
      _list[_i].governor = _governors[_i];
      _list[_i].weight = _validatorWeight[_validator];
    }
  }

  /**
   * @dev See {IWeightedValidator-getValidators}.
   */
  function getValidators() external view virtual returns (address[] memory) {
    return _validators;
  }

  /**
   * @dev See {IWeightedValidator-getGovernors}.
   */
  function getGovernors() external view virtual returns (address[] memory) {
    return _governors;
  }

  /**
   * @dev See {IWeightedValidator-validators}.
   */
  function validators(uint256 _index) external view virtual returns (WeightedValidator memory) {
    address _validator = _validators[_index];
    return WeightedValidator(_validator, _governors[_index], _validatorWeight[_validator]);
  }

  /**
   * @dev See {IWeightedValidator-totalWeights}.
   */
  function totalWeights() external view virtual returns (uint256) {
    return _totalWeights;
  }

  /**
   * @dev See {IWeightedValidator-totalValidators}.
   */
  function totalValidators() external view virtual returns (uint256) {
    return _validators.length;
  }

  /**
   * @dev See {IWeightedValidator-addValidators}.
   */
  function addValidators(WeightedValidator[] calldata _validatorList) external virtual onlyAdmin {
    return _addValidators(_validatorList);
  }

  /**
   * @dev See {IWeightedValidator-updateValidators}.
   */
  function updateValidators(WeightedValidator[] calldata _validatorList) external virtual onlyAdmin {
    for (uint256 _i; _i < _validatorList.length; _i++) {
      _updateValidator(_validatorList[_i]);
    }
    emit ValidatorsUpdated(nonce++, _validatorList);
  }

  /**
   * @dev See {IWeightedValidator-removeValidators}.
   */
  function removeValidators(address[] calldata _validatorList) external virtual onlyAdmin {
    for (uint256 _i; _i < _validatorList.length; _i++) {
      _removeValidator(_validatorList[_i]);
    }
    emit ValidatorsRemoved(nonce++, _validatorList);
  }

  /**
   * @dev See {IQuorum-getThreshold}.
   */
  function getThreshold() external view virtual returns (uint256, uint256) {
    return (_num, _denom);
  }

  /**
   * @dev See {IQuorum-checkThreshold}.
   */
  function checkThreshold(uint256 _voteWeight) external view virtual returns (bool) {
    return _voteWeight * _denom >= _num * _totalWeights;
  }

  /**
   * @dev See {IQuorum-minimumVoteWeight}.
   */
  function minimumVoteWeight() external view virtual returns (uint256) {
    return (_num * _totalWeights + _denom - 1) / _denom;
  }

  /**
   * @dev See {IQuorum-setThreshold}.
   */
  function setThreshold(uint256 _numerator, uint256 _denominator)
    external
    virtual
    onlyAdmin
    returns (uint256 _previousNum, uint256 _previousDenom)
  {
    return _setThreshold(_numerator, _denominator);
  }

  /**
   * @dev Sets threshold and return the old one.
   */
  function _setThreshold(uint256 _numerator, uint256 _denominator)
    internal
    virtual
    returns (uint256 _previousNum, uint256 _previousDenom)
  {
    require(_numerator <= _denominator, "RoninValidator: invalid threshold");
    _previousNum = _num;
    _previousDenom = _denom;
    _num = _numerator;
    _denom = _denominator;
    emit ThresholdUpdated(nonce++, _numerator, _denominator, _previousNum, _previousDenom);
  }

  /**
   * @dev Adds multiple validators.
   */
  function _addValidators(WeightedValidator[] calldata _validatorList) internal virtual {
    for (uint256 _i; _i < _validatorList.length; _i++) {
      _addValidator(_validatorList[_i]);
    }
    emit ValidatorsAdded(nonce++, _validatorList);
  }

  /**
   * @dev Adds the address list as validators.
   *
   * Requirements:
   * - The weight is larger than 0.
   * - The validator is not added.
   *
   */
  function _addValidator(WeightedValidator memory _v) internal virtual {
    require(_v.weight > 0, "RoninValidator: invalid weight");

    if (_validatorWeight[_v.validator] > 0) {
      revert(
        string(
          abi.encodePacked(
            "RoninValidator: ",
            Strings.toHexString(uint160(_v.validator), 20),
            " is a validator already"
          )
        )
      );
    }

    if (_governorWeight[_v.governor] > 0) {
      revert(
        string(
          abi.encodePacked("RoninValidator: ", Strings.toHexString(uint160(_v.validator), 20), " is a governor already")
        )
      );
    }

    _validators.push(_v.validator);
    _governors.push(_v.governor);
    _validatorWeight[_v.validator] = _v.weight;
    _governorWeight[_v.governor] = _v.weight;
    _totalWeights += _v.weight;
  }

  /**
   * @dev Removes the address list as validators.
   *
   * Requirements:
   * - The weight is larger than 0.
   * - The validator is added.
   *
   */
  function _updateValidator(WeightedValidator memory _v) internal virtual {
    require(_v.weight > 0, "RoninValidator: invalid weight");

    uint256 _weight = _validatorWeight[_v.validator];
    if (_weight == 0) {
      revert(
        string(
          abi.encodePacked("RoninValidator: ", Strings.toHexString(uint160(_v.validator), 20), " is not a validator")
        )
      );
    }

    uint256 _count = _validators.length;
    for (uint256 _i = 0; _i < _count; _i++) {
      if (_validators[_i] == _v.validator) {
        _totalWeights -= _weight;
        _totalWeights += _v.weight;

        if (_governors[_i] != _v.governor) {
          require(_governorWeight[_v.governor] == 0, "RoninValidator: query for duplicated governor");
          delete _governorWeight[_governors[_i]];
          _governors[_i] = _v.governor;
        }

        _validatorWeight[_v.validator] = _v.weight;
        _governorWeight[_v.governor] = _v.weight;
        return;
      }
    }
  }

  /**
   * @dev Removes the address list as validators.
   *
   * Requirements:
   * - The validator is added.
   *
   */
  function _removeValidator(address _addr) internal virtual {
    uint256 _weight = _validatorWeight[_addr];
    if (_weight == 0) {
      revert(
        string(abi.encodePacked("RoninValidator: ", Strings.toHexString(uint160(_addr), 20), " is not a validator"))
      );
    }

    uint256 _index;
    uint256 _count = _validators.length;
    for (uint256 _i = 0; _i < _count; _i++) {
      if (_validators[_i] == _addr) {
        _index = _i;
        break;
      }
    }

    _totalWeights -= _weight;
    delete _validatorWeight[_addr];
    _validators[_index] = _validators[_count - 1];
    _validators.pop();

    delete _governorWeight[_governors[_index]];
    _governors[_index] = _governors[_count - 1];
    _governors.pop();
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/StorageSlot.sol";

abstract contract HasProxyAdmin {
  // bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1));
  bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

  modifier onlyAdmin() {
    require(msg.sender == _getAdmin(), "HasProxyAdmin: unauthorized sender");
    _;
  }

  /**
   * @dev Returns proxy admin.
   */
  function _getAdmin() internal view returns (address) {
    return StorageSlot.getAddressSlot(_ADMIN_SLOT).value;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IQuorum {
  /// @dev Emitted when the threshold is updated
  event ThresholdUpdated(
    uint256 indexed nonce,
    uint256 indexed numerator,
    uint256 indexed denominator,
    uint256 previousNumerator,
    uint256 previousDenominator
  );

  /**
   * @dev Returns the threshold.
   */
  function getThreshold() external view returns (uint256 _num, uint256 _denom);

  /**
   * @dev Checks whether the `_voteWeight` passes the threshold.
   */
  function checkThreshold(uint256 _voteWeight) external view returns (bool);

  /**
   * @dev Returns the minimum vote weight to pass the threshold.
   */
  function minimumVoteWeight() external view returns (uint256);

  /**
   * @dev Sets the threshold.
   *
   * Requirements:
   * - The method caller is admin.
   *
   * Emits the `ThresholdUpdated` event.
   *
   */
  function setThreshold(uint256 _numerator, uint256 _denominator)
    external
    returns (uint256 _previousNum, uint256 _previousDenom);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IQuorum.sol";

interface IWeightedValidator is IQuorum {
  struct WeightedValidator {
    address validator;
    address governor;
    uint256 weight;
  }

  /// @dev Emitted when the validators are added
  event ValidatorsAdded(uint256 indexed nonce, WeightedValidator[] validators);
  /// @dev Emitted when the validators are updated
  event ValidatorsUpdated(uint256 indexed nonce, WeightedValidator[] validators);
  /// @dev Emitted when the validators are removed
  event ValidatorsRemoved(uint256 indexed nonce, address[] validators);

  /**
   * @dev Returns validator weight of the validator.
   */
  function getValidatorWeight(address _addr) external view returns (uint256);

  /**
   * @dev Returns governor weight of the governor.
   */
  function getGovernorWeight(address _addr) external view returns (uint256);

  /**
   * @dev Returns total validator weights of the address list.
   */
  function sumValidatorWeights(address[] calldata _addrList) external view returns (uint256 _weight);

  /**
   * @dev Returns total governor weights of the address list.
   */
  function sumGovernorWeights(address[] calldata _addrList) external view returns (uint256 _weight);

  /**
   * @dev Returns the validator list attached with governor address and weight.
   */
  function getValidatorInfo() external view returns (WeightedValidator[] memory _list);

  /**
   * @dev Returns the validator list.
   */
  function getValidators() external view returns (address[] memory _validators);

  /**
   * @dev Returns the validator at `_index` position.
   */
  function validators(uint256 _index) external view returns (WeightedValidator memory);

  /**
   * @dev Returns total of validators.
   */
  function totalValidators() external view returns (uint256);

  /**
   * @dev Returns total weights.
   */
  function totalWeights() external view returns (uint256);

  /**
   * @dev Adds validators.
   *
   * Requirements:
   * - The weights are larger than 0.
   * - The validators are not added.
   * - The method caller is admin.
   *
   * Emits the `ValidatorsAdded` event.
   *
   */
  function addValidators(WeightedValidator[] calldata _validators) external;

  /**
   * @dev Updates validators.
   *
   * Requirements:
   * - The weights are larger than 0.
   * - The validators are added.
   * - The method caller is admin.
   *
   * Emits the `ValidatorsUpdated` event.
   *
   */
  function updateValidators(WeightedValidator[] calldata _validators) external;

  /**
   * @dev Removes validators.
   *
   * Requirements:
   * - The validators are added.
   * - The method caller is admin.
   *
   * Emits the `ValidatorsRemoved` event.
   *
   */
  function removeValidators(address[] calldata _validators) external;
}