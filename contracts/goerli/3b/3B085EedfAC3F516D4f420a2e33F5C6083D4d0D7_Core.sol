// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/StorageSlot.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "./managers/OwnerManager.sol";
import "./managers/OperatorManager.sol";
import "./managers/ModuleManager.sol";
import "./managers/FallbackManager.sol";

import "./common/Executor.sol";
import "./common/Utils.sol";

import "./modules/IModule.sol";

// This contract must be very first parent of Core contract.
abstract contract CoreStorage is OwnerManager, OperatorManager, ModuleManager {
    // EIP-1967: bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1)
    bytes32 internal constant CORE_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    function getCore() public view returns (address) {
        return StorageSlot.getAddressSlot(CORE_SLOT).value;
    }

    function setCore(address core) internal {
        require(Address.isContract(core), "ERC1967: new implementation is not a contract");
        StorageSlot.getAddressSlot(CORE_SLOT).value = core;
    }

    function setModule(
        address target,
        bytes4 funcHash,
        IModule module
    ) public override onlyAdmin {
        _modules[target][funcHash] = module;
        emit SetModule(target, funcHash, module);
    }
}

contract Core is CoreStorage, FallbackManager, Executor {
    bytes4 internal constant ERC1271_MAGIC_VALUE = bytes4(keccak256("isValidSignature(bytes32,bytes)"));

    // TODO check permission
    function setupWallet(address operator, address owner) external {
        _operator = operator;
        _owner = owner;
    }

    function execute(
        address to,
        uint256 value,
        bytes memory data
    ) external payable onlyOwner returns (bytes memory) {
        bytes4 funcHash = Utils.parseFunctionSelector(data);

        if (funcHash == bytes4(0)) {
            require(address(this).balance >= value, "Not enough eth.");
        } else {
            IModule module = _modules[to][funcHash];
            require(address(module) != address(0x0), "Not supported method.");

            return _callModule(address(module), to, data);
        }

        return _execute(to, value, data);
    }

    function executeModule(address module, bytes memory data) external onlyOperator returns (bytes memory) {
        // TODO remove module parameter.
        assembly {
            let success := delegatecall(gas(), module, add(data, 0x20), mload(data), 0, 0)
            returndatacopy(0, 0, returndatasize())
            if gt(success, 0) {
                return(0, returndatasize())
            }

            revert(0, returndatasize())
        }
    }

    function transferERC20(
        address token,
        address receiver,
        uint256 amount
    ) external onlyOwner returns (bool transferred) {
        // 0xa9059cbb - keccack("transfer(address,uint256)")
        bytes memory data = abi.encodeWithSelector(0xa9059cbb, receiver, amount);

        assembly {
            // We write the return value to scratch space.
            // See https://docs.soliditylang.org/en/v0.7.6/internals/layout_in_memory.html#layout-in-memory
            let success := call(sub(gas(), 10000), token, 0, add(data, 0x20), mload(data), 0, 0x20)
            switch returndatasize()
            case 0 {
                transferred := success
            }
            case 0x20 {
                transferred := iszero(or(iszero(success), iszero(mload(0))))
            }
            default {
                transferred := 0
            }
        }
    }

    function _callModule(
        address module,
        address to,
        bytes memory data
    ) internal returns (bytes memory) {
        (bool success, bytes memory result) = module.delegatecall(
            abi.encodeWithSignature("handleTransaction(address,bytes)", to, data)
        );
        if (success == false) {
            assembly {
                let ptr := mload(0x40)
                returndatacopy(ptr, 0, returndatasize())
                revert(ptr, returndatasize())
            }
        }
        return result;
    }

    function setFallbackHandler(address handler) public override onlyAdmin {
        _setFallbackHandler(handler);
        emit ChangedFallbackHandler(handler);
    }

    // ERC1271 handler
    function isValidSignature(bytes32 hash, bytes memory signature) public view returns (bytes4 magicValue) {
        require(signature.length == 65, "Invalid signature length");
        address signer = Utils.recoverSigner(hash, signature);
        require(signer == _owner, "Invalid signer");
        return ERC1271_MAGIC_VALUE;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

abstract contract OperatorManager {
    address internal _operator;
    address internal _admin;

    event SetOperator(address owner);
    event SetAdmin(address admin);

    modifier onlyOperator() {
        require(_operator == msg.sender, "Caller is not the operator");
        _;
    }

    modifier onlyAdmin() {
        require(_admin == msg.sender, "Caller is not the admin");
        _;
    }

    function setOperator(address operator) public onlyAdmin {
        _operator = operator;
        emit SetOperator(operator);
    }

    function setAdmin(address admin) public {
        _admin = admin;
        emit SetAdmin(admin);
    }

    function getOperator() public view returns (address) {
        return _operator;
    }

    function getAdmin() public view returns (address) {
        return _admin;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../modules/IModule.sol";

abstract contract ModuleManager {
    // Target => Function => IModule
    mapping(address => mapping(bytes4 => IModule)) internal _modules;

    event SetModule(address target, bytes4 funcHash, IModule module);

    function setModule(
        address target,
        bytes4 funcHash,
        IModule module
    ) public virtual;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

abstract contract Executor {
    function _execute(
        address to,
        uint256 value,
        bytes memory data
    ) internal returns (bytes memory) {
        assembly {
            let success := call(gas(), to, value, add(data, 0x20), mload(data), 0, 0)
            returndatacopy(0, 0, returndatasize())
            if eq(success, 0) {
                revert(0, returndatasize())
            }
            return(0, returndatasize())
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

abstract contract OwnerManager {
    address internal _owner;

    event SetOwner(address owner);

    modifier onlyOwner() {
        require(_owner == msg.sender, "Caller is not the owner");
        _;
    }

    // TODO check permission
    function setOwner(address owner) public {
        _owner = owner;
        emit SetOwner(owner);
    }

    function getOwner() public view returns (address) {
        return _owner;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

library Utils {
    /**
     * @notice Recover signer address from signature.
     */
    function recoverSigner(bytes32 signedHash, bytes memory signature) internal pure returns (address) {
        uint8 v;
        bytes32 r;
        bytes32 s;
        // we jump 32 (0x20) as the first slot of bytes contains the length
        // we jump 65 (0x41) per signature
        // for v we load 32 bytes ending with v (the first 31 come from s) then apply a mask
        assembly {
            r := mload(add(signature, add(0x20, mul(0x41, 0))))
            s := mload(add(signature, add(0x40, mul(0x41, 0))))
            v := and(mload(add(signature, add(0x41, mul(0x41, 0)))), 0xff)
        }
        require(v == 27 || v == 28, "Utils: bad v value in signature");

        address recoveredAddress = ecrecover(signedHash, v, r, s);
        require(recoveredAddress != address(0), "Utils: ecrecover returned 0");
        return recoveredAddress;
    }

    /**
     * @notice Helper method to parse the function selector from data.
     */
    function parseFunctionSelector(bytes memory data) public pure returns (bytes4 result) {
        assembly {
            result := mload(add(data, 0x20))
        }
    }

    /**
     * @notice Parse address from given data.
     * The method returns address at given position
     * @param data Any data to be parsed, mostly calldata of transaction.
     * @param location Position of address.
     */
    function getAddressAt(bytes memory data, uint8 location) public pure returns (address result) {
        assembly {
            result := mload(add(data, location))
        }
    }

    /**
     * @notice Parse uint256 from given data.
     * The method returns uint256 at given position
     * @param data Any data to be parsed, mostly calldata of transaction.
     * @param location Position of uint256.
     */
    function getUint256At(bytes memory data, uint8 location) public pure returns (uint256 result) {
        assembly {
            result := mload(add(data, location))
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

abstract contract FallbackManager {
    // keccak256("core.fallback_handler.address")
    bytes32 private constant FALLBACK_HANDLER_STORAGE_SLOT =
        0xf9859c642165e8c26d40ad1b16bb977656abad7c423cae424e2fb17fed7a50b6;

    event ChangedFallbackHandler(address handler);
    event EthReceived(address indexed sender, uint256 value);

    function _setFallbackHandler(address handler) internal {
        bytes32 slot = FALLBACK_HANDLER_STORAGE_SLOT;
        assembly {
            sstore(slot, handler)
        }
        emit ChangedFallbackHandler(handler);
    }

    function setFallbackHandler(address handler) public virtual;

    receive() external payable {
        emit EthReceived(msg.sender, msg.value);
    }

    fallback() external payable {
        bytes32 slot = FALLBACK_HANDLER_STORAGE_SLOT;
        assembly {
            let handler := sload(slot)
            if iszero(handler) {
                return(0, 0)
            }

            calldatacopy(0, 0, calldatasize())
            let success := delegatecall(gas(), handler, callvalue(), calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            if gt(success, 0) {
                return(0, returndatasize())
            }

            revert(0, returndatasize())
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IModule {
    function handleTransaction(address to, bytes memory data) external payable returns (bytes memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

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
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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