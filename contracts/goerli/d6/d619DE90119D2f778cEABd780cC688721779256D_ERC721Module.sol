// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../CoreStorage.sol";
import "../common/Executor.sol";
import "../common/Utils.sol";

contract ERC721Module is CoreStorage, IModule, Executor {
    // keccak256('Wallet.ERC721Module.lockedERC721')
    bytes32 private constant LOCKER_SLOT = 0xfe8e4f0338c8a53570f91f75341b5e53c6e2ab3f276f588c937a6dd7d264e5f0;

    // bytes4(keccak256("transferFrom(address,address,uint256)"))
    bytes4 private constant ERC721_TRANSFER_FROM = 0x23b872dd;

    // bytes4(keccak256("safeTransferFrom(address,address,uint256)"))
    bytes4 private constant ERC721_SAFE_TRANSFER_FROM = 0x42842e0e;

    // bytes4(keccak256("safeTransferFrom(address,address,uint256,bytes)"))
    bytes4 private constant ERC721_SAFE_TRANSFER_FROM_BYTES = 0xb88d4fde;

    // bytes4(keccak256("approve(address,uint256)"))
    bytes4 private constant ERC721_APPROVE = 0x095ea7b3;

    event SetLockedERC721Token(address collection, uint256 tokenId, bool isLocked);

    /// @inheritdoc IModule
    function handleTransaction(
        address collection,
        uint256 value,
        bytes memory data
    ) external payable override returns (bytes memory) {
        bytes4 funcHash = Utils.parseFunctionSelector(data);
        if (
            funcHash == ERC721_TRANSFER_FROM ||
            funcHash == ERC721_SAFE_TRANSFER_FROM ||
            funcHash == ERC721_SAFE_TRANSFER_FROM_BYTES
        ) {
            uint256 tokenId = Utils.getUint256At(data, 0x44);
            require(!checkIsLocked(collection, tokenId), "Cannot perform this action on locked token.");
        }
        if (funcHash == ERC721_APPROVE) {
            uint256 tokenId = Utils.getUint256At(data, 0x24);
            require(!checkIsLocked(collection, tokenId), "Cannot perform this action on locked token.");
        }

        return _execute(collection, value, data);
    }

    /// @notice Allows operators to lock/unlock the token.
    /// @param collection Collection address.
    /// @param tokenId Token id.
    /// @param isLocked Boolean represents lock/unlock.
    function setLockedERC721Token(
        address collection,
        uint256 tokenId,
        bool isLocked
    ) external {
        _getLockedTokens()[collection][tokenId] = isLocked;
        emit SetLockedERC721Token(collection, tokenId, isLocked);
    }

    /// @notice Allows operators to get the defaulted token.
    ///     Note: Can only transfer if token is locked.
    /// @param collection Collection address.
    /// @param tokenId Token ID.
    /// @param to Receiver address.
    function getDefaultedERC721(
        address collection,
        uint256 tokenId,
        address to
    ) external returns (bytes memory) {
        require(checkIsLocked(collection, tokenId), "Cannot perform this action on non-locked token.");
        bytes memory data = abi.encodeWithSelector(ERC721_SAFE_TRANSFER_FROM, address(this), to, tokenId);

        return _execute(collection, 0, data);
    }

    /// @notice Checks whether the token is locked or not.
    /// @param collection Collection address.
    /// @param tokenId Token ID.
    /// @return isLocked Whether the token is locked or not.
    function checkIsLocked(address collection, uint256 tokenId) public view returns (bool isLocked) {
        isLocked = _getLockedTokens()[collection][tokenId];
    }

    /// @dev Returns the map of the locked tokens.
    /// @return result Map of the locked tokens.
    ///     Note: Collection Address => Token ID => isLocked
    function _getLockedTokens() internal pure returns (mapping(address => mapping(uint256 => bool)) storage result) {
        assembly {
            result.slot := LOCKER_SLOT
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/StorageSlot.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "./managers/DelegateCallManager.sol";
import "./managers/RoleManager.sol";
import "./managers/ModuleManager.sol";

// This contract must be very the first parent of Core contract and Module contracts.
abstract contract CoreStorage is RoleManagerStorage, ModuleManagerStorage {

}

abstract contract ICoreStorage is DelegateCallManager, IRoleManager, IModuleManager {
    constructor(address admin) IRoleManager(admin) {}

    /// @inheritdoc IModuleManager
    function setModule(
        address target,
        bytes4 funcHash,
        IModule module
    ) external override noDelegateCall onlyAdmin {
        _modules[target][funcHash] = module;
        emit SetModule(target, funcHash, module);
    }

    /// @inheritdoc IModuleManager
    function setInternalModule(bytes4 funcHash, IModule module) external override noDelegateCall onlyAdmin {
        _internalModules[funcHash] = module;
        emit SetInternalModule(funcHash, module);
    }

    /// @inheritdoc IRoleManager
    function setOwner(address owner) external override onlyOwner onlyDelegateCall {
        _owner = owner;
        emit SetOwner(owner);
    }

    /// @inheritdoc IRoleManager
    function getOwner() external view override onlyDelegateCall returns (address) {
        return _owner;
    }

    /// @inheritdoc IRoleManager
    function setAdmin(address admin) external override noDelegateCall onlyAdmin {
        _admin = admin;
        emit SetAdmin(admin);
    }

    /// @inheritdoc IRoleManager
    function getAdmin() external view override noDelegateCall returns (address) {
        return _admin;
    }

    /// @inheritdoc IRoleManager
    function setOperator(uint8 index, address operator) external override noDelegateCall onlyAdmin {
        _operators[index] = operator;
        emit SetOperator(index, operator);
    }

    /// @inheritdoc IRoleManager
    function getOperators() external view override noDelegateCall returns (address[3] memory) {
        return _operators;
    }

    /// @inheritdoc IRoleManager
    function _checkOnlyAdmin() internal view override {
        if (address(this) != _this) {
            require(ICoreStorage(_this).getAdmin() == msg.sender, "Caller is not an admin.");
        } else {
            require(_admin == msg.sender, "Caller is not an admin.");
        }
    }

    /// @inheritdoc IRoleManager
    function isOperator(address operator) external view override noDelegateCall returns (bool result) {
        assembly {
            result := or(
                or(eq(sload(_operators.slot), operator), eq(sload(add(_operators.slot, 0x14)), operator)),
                eq(sload(add(_operators.slot, 0x28)), operator)
            )
        }
    }

    /// @inheritdoc IRoleManager
    function _checkOnlyOperator() internal view override onlyDelegateCall {
        require(ICoreStorage(_this).isOperator(msg.sender), "Caller is not an operator.");
    }

    /// @inheritdoc IRoleManager
    function _checkOnlyOwner() internal view override onlyDelegateCall {
        require(_owner == msg.sender, "Caller is not an owner.");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

library Utils {
    /// @notice Recover signer address from signature.
    function recoverSigner(bytes32 signedHash, bytes memory signature) internal pure returns (address) {
        uint8 v;
        bytes32 r;
        bytes32 s;
        // we jump 32 (0x20) as the first slot of bytes contains the length
        // we jump 65 (0x41) per signature
        // for v we load 32 bytes ending with v (the first 31 come from s) then apply a mask
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }
        require(v == 27 || v == 28, "Utils: bad v value in signature");

        address recoveredAddress = ecrecover(signedHash, v, r, s);
        require(recoveredAddress != address(0), "Utils: ecrecover returned 0");
        return recoveredAddress;
    }

    /// @notice Helper method to parse the function selector from data.
    /// @param data Any data to be parsed, mostly calldata of transaction.
    /// @return result Parsed function sighash.
    function parseFunctionSelector(bytes memory data) internal pure returns (bytes4 result) {
        assembly {
            result := mload(add(data, 0x20))
        }
    }

    /// @notice Parse uint256 from given data.
    /// @param data Any data to be parsed, mostly calldata of transaction.
    /// @param position Position in the data.
    /// @return result Uint256 parsed from given data.
    function getUint256At(bytes memory data, uint8 position) internal pure returns (uint256 result) {
        assembly {
            result := mload(add(data, add(position, 0x20)))
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

abstract contract Executor {
    /// @notice Executes a transaction to the given address.
    /// @param to Target address.
    /// @param value ETH value to be sent to the address.
    /// @param data Data to be sent to the address.
    /// @return Result of the transaciton.
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

abstract contract RoleManagerStorage {
    address[3] internal _operators;
    address internal _admin;
    address internal _owner;
}

abstract contract IRoleManager is RoleManagerStorage {
    event SetOwner(address owner);
    event SetAdmin(address admin);
    event SetOperator(uint8 index, address operator);

    modifier onlyOperator() {
        _checkOnlyOperator();
        _;
    }

    modifier onlyAdmin() {
        _checkOnlyAdmin();
        _;
    }

    modifier onlyOwner() {
        _checkOnlyOwner();
        _;
    }

    constructor(address admin) {
        _admin = admin;
    }

    /// @notice Allows the owner to transfer ownership of the wallet.
    /// @param owner New owner address.
    function setOwner(address owner) external virtual;

    /// @notice Returns current owner of the wallet.
    /// @return Address of the current owner.
    function getOwner() external view virtual returns (address);

    /// @notice Changes the current admin.
    /// @param admin New admin address.
    function setAdmin(address admin) external virtual;

    /// @notice Returns current admin of the core contract.
    /// @return Address of the current admin.
    function getAdmin() external view virtual returns (address);

    /// @notice Sets the operator in the given index.
    /// @param index Index of the operator.
    /// @param operator Operator address.
    function setOperator(uint8 index, address operator) external virtual;

    /// @notice Returns an array of operators.
    /// @return An array of the operator addresses.
    function getOperators() external view virtual returns (address[3] memory);

    /// @notice Checks whether the given address is an operator.
    /// @param operator Address that will be checked.
    /// @return result Boolean result.
    function isOperator(address operator) external view virtual returns (bool result);

    /// @notice Checks whether the message sender is an operator.
    function _checkOnlyOperator() internal view virtual;

    /// @notice Checks whether the message sender is an admin.
    function _checkOnlyAdmin() internal view virtual;

    /// @notice Checks whether the message sender is an owner.
    function _checkOnlyOwner() internal view virtual;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @title Manage the delegatecall to a contract
/// @notice Base contract that provides a modifier for managing delegatecall to methods in a child contract
abstract contract DelegateCallManager {
    /// @dev The address of this contract
    address payable internal immutable _this;

    constructor() {
        // Immutables are computed in the init code of the contract, and then inlined into the deployed bytecode.
        // In other words, this variable won't change when it's checked at runtime.
        _this = payable(address(this));
    }

    /// @dev Private method is used instead of inlining into modifier because modifiers are copied into each method,
    ///     and the use of immutable means the address bytes are copied in every place the modifier is used.
    function _checkNotDelegateCall() private view {
        require(address(this) == _this, "Only direct calls allowed.");
    }

    /// @dev Private method is used instead of inlining into modifier because modifiers are copied into each method,
    ///     and the use of immutable means the address bytes are copied in every place the modifier is used.
    function _checkOnlyDelegateCall() private view {
        require(address(this) != _this, "Cannot be called directly.");
    }

    /// @notice Prevents delegatecall into the modified method
    modifier noDelegateCall() {
        _checkNotDelegateCall();
        _;
    }

    /// @notice Prevents non delegatecall into the modified method
    modifier onlyDelegateCall() {
        _checkOnlyDelegateCall();
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../modules/IModule.sol";

abstract contract ModuleManagerStorage {
    /// @notice Storing an allowed contract methods.
    ///     Note: Target Contract Address => Sighash of method => Module address
    mapping(address => mapping(bytes4 => IModule)) internal _modules;

    /// @notice Storing an internally allowed module methods.
    ///     Note: Sighash of module method => Module address
    mapping(bytes4 => IModule) internal _internalModules;
}

abstract contract IModuleManager is ModuleManagerStorage {
    event SetModule(address target, bytes4 funcHash, IModule module);
    event SetInternalModule(bytes4 funcHash, IModule module);

    /// @notice Sets the handler module of the target's function.
    /// @param target Address of the target contract.
    /// @param funcHash Sighash of the target contract's method.
    /// @param module Address of the handler module.
    function setModule(
        address target,
        bytes4 funcHash,
        IModule module
    ) external virtual;

    /// @notice Returns a handling module of the target function.
    /// @param target Address of the target contract.
    /// @param funcHash Sighash of the target contract's method.
    /// @return module Handler module.
    function getModule(address target, bytes4 funcHash) external view returns (IModule module) {
        module = _modules[target][funcHash];
    }

    /// @notice Sets the handler module of the function.
    /// @param funcHash Sighash of the module method.
    /// @param module Address of the handler module.
    function setInternalModule(bytes4 funcHash, IModule module) external virtual;

    /// @notice Returns a handling module of the given function.
    /// @param funcHash Sighash of the module's method.
    /// @return module Handler module.
    function getInternalModule(bytes4 funcHash) external view returns (IModule module) {
        module = _internalModules[funcHash];
    }

    /// @notice Used to call module functions on the wallet.
    ///     Usually used to call locking function of the module on the wallet.
    /// @param data Data payload of the transaction.
    /// @return Result of the execution.
    function executeModule(bytes memory data) external virtual returns (bytes memory);
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IModule {
    /// @notice Executes given transaction data to given address.
    /// @param to Target contract address.
    /// @param value Value of the given transaction.
    /// @param data Calldata of the transaction.
    /// @return Result of the execution.
    function handleTransaction(
        address to,
        uint256 value,
        bytes memory data
    ) external payable returns (bytes memory);
}