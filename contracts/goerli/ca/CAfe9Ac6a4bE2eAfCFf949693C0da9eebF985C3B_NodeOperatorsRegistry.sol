/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.4.24;


contract ACLSyntaxSugar {
    function arr() internal pure returns (uint256[]) {
        return new uint256[](0);
    }

    function arr(bytes32 _a) internal pure returns (uint256[] r) {
        return arr(uint256(_a));
    }

    function arr(bytes32 _a, bytes32 _b) internal pure returns (uint256[] r) {
        return arr(uint256(_a), uint256(_b));
    }

    function arr(address _a) internal pure returns (uint256[] r) {
        return arr(uint256(_a));
    }

    function arr(address _a, address _b) internal pure returns (uint256[] r) {
        return arr(uint256(_a), uint256(_b));
    }

    function arr(address _a, uint256 _b, uint256 _c) internal pure returns (uint256[] r) {
        return arr(uint256(_a), _b, _c);
    }

    function arr(address _a, uint256 _b, uint256 _c, uint256 _d) internal pure returns (uint256[] r) {
        return arr(uint256(_a), _b, _c, _d);
    }

    function arr(address _a, uint256 _b) internal pure returns (uint256[] r) {
        return arr(uint256(_a), uint256(_b));
    }

    function arr(address _a, address _b, uint256 _c, uint256 _d, uint256 _e) internal pure returns (uint256[] r) {
        return arr(uint256(_a), uint256(_b), _c, _d, _e);
    }

    function arr(address _a, address _b, address _c) internal pure returns (uint256[] r) {
        return arr(uint256(_a), uint256(_b), uint256(_c));
    }

    function arr(address _a, address _b, uint256 _c) internal pure returns (uint256[] r) {
        return arr(uint256(_a), uint256(_b), uint256(_c));
    }

    function arr(uint256 _a) internal pure returns (uint256[] r) {
        r = new uint256[](1);
        r[0] = _a;
    }

    function arr(uint256 _a, uint256 _b) internal pure returns (uint256[] r) {
        r = new uint256[](2);
        r[0] = _a;
        r[1] = _b;
    }

    function arr(uint256 _a, uint256 _b, uint256 _c) internal pure returns (uint256[] r) {
        r = new uint256[](3);
        r[0] = _a;
        r[1] = _b;
        r[2] = _c;
    }

    function arr(uint256 _a, uint256 _b, uint256 _c, uint256 _d) internal pure returns (uint256[] r) {
        r = new uint256[](4);
        r[0] = _a;
        r[1] = _b;
        r[2] = _c;
        r[3] = _d;
    }

    function arr(uint256 _a, uint256 _b, uint256 _c, uint256 _d, uint256 _e) internal pure returns (uint256[] r) {
        r = new uint256[](5);
        r[0] = _a;
        r[1] = _b;
        r[2] = _c;
        r[3] = _d;
        r[4] = _e;
    }
}


contract ACLHelpers {
    function decodeParamOp(uint256 _x) internal pure returns (uint8 b) {
        return uint8(_x >> (8 * 30));
    }

    function decodeParamId(uint256 _x) internal pure returns (uint8 b) {
        return uint8(_x >> (8 * 31));
    }

    function decodeParamsList(uint256 _x) internal pure returns (uint32 a, uint32 b, uint32 c) {
        a = uint32(_x);
        b = uint32(_x >> (8 * 4));
        c = uint32(_x >> (8 * 8));
    }
}

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.4.24;


interface IACL {
    function initialize(address permissionsCreator) external;

    // TODO: this should be external
    // See https://github.com/ethereum/solidity/issues/4832
    function hasPermission(address who, address where, bytes32 what, bytes how) public view returns (bool);
}

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.4.24;

import "../common/UnstructuredStorage.sol";
import "../kernel/IKernel.sol";


contract AppStorage {
    using UnstructuredStorage for bytes32;

    /* Hardcoded constants to save gas
    bytes32 internal constant KERNEL_POSITION = keccak256("aragonOS.appStorage.kernel");
    bytes32 internal constant APP_ID_POSITION = keccak256("aragonOS.appStorage.appId");
    */
    bytes32 internal constant KERNEL_POSITION = 0x4172f0f7d2289153072b0a6ca36959e0cbe2efc3afe50fc81636caa96338137b;
    bytes32 internal constant APP_ID_POSITION = 0xd625496217aa6a3453eecb9c3489dc5a53e6c67b444329ea2b2cbc9ff547639b;

    function kernel() public view returns (IKernel) {
        return IKernel(KERNEL_POSITION.getStorageAddress());
    }

    function appId() public view returns (bytes32) {
        return APP_ID_POSITION.getStorageBytes32();
    }

    function setKernel(IKernel _kernel) internal {
        KERNEL_POSITION.setStorageAddress(address(_kernel));
    }

    function setAppId(bytes32 _appId) internal {
        APP_ID_POSITION.setStorageBytes32(_appId);
    }
}

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.4.24;

import "./AppStorage.sol";
import "../acl/ACLSyntaxSugar.sol";
import "../common/Autopetrified.sol";
import "../common/ConversionHelpers.sol";
import "../common/ReentrancyGuard.sol";
import "../common/VaultRecoverable.sol";
import "../evmscript/EVMScriptRunner.sol";


// Contracts inheriting from AragonApp are, by default, immediately petrified upon deployment so
// that they can never be initialized.
// Unless overriden, this behaviour enforces those contracts to be usable only behind an AppProxy.
// ReentrancyGuard, EVMScriptRunner, and ACLSyntaxSugar are not directly used by this contract, but
// are included so that they are automatically usable by subclassing contracts
contract AragonApp is AppStorage, Autopetrified, VaultRecoverable, ReentrancyGuard, EVMScriptRunner, ACLSyntaxSugar {
    string private constant ERROR_AUTH_FAILED = "APP_AUTH_FAILED";

    modifier auth(bytes32 _role) {
        require(canPerform(msg.sender, _role, new uint256[](0)), ERROR_AUTH_FAILED);
        _;
    }

    modifier authP(bytes32 _role, uint256[] _params) {
        require(canPerform(msg.sender, _role, _params), ERROR_AUTH_FAILED);
        _;
    }

    /**
    * @dev Check whether an action can be performed by a sender for a particular role on this app
    * @param _sender Sender of the call
    * @param _role Role on this app
    * @param _params Permission params for the role
    * @return Boolean indicating whether the sender has the permissions to perform the action.
    *         Always returns false if the app hasn't been initialized yet.
    */
    function canPerform(address _sender, bytes32 _role, uint256[] _params) public view returns (bool) {
        if (!hasInitialized()) {
            return false;
        }

        IKernel linkedKernel = kernel();
        if (address(linkedKernel) == address(0)) {
            return false;
        }

        return linkedKernel.hasPermission(
            _sender,
            address(this),
            _role,
            ConversionHelpers.dangerouslyCastUintArrayToBytes(_params)
        );
    }

    /**
    * @dev Get the recovery vault for the app
    * @return Recovery vault address for the app
    */
    function getRecoveryVault() public view returns (address) {
        // Funds recovery via a vault is only available when used with a kernel
        return kernel().getRecoveryVault(); // if kernel is not set, it will revert
    }
}

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.4.24;

import "./Petrifiable.sol";


contract Autopetrified is Petrifiable {
    constructor() public {
        // Immediately petrify base (non-proxy) instances of inherited contracts on deploy.
        // This renders them uninitializable (and unusable without a proxy).
        petrify();
    }
}

pragma solidity ^0.4.24;


library ConversionHelpers {
    string private constant ERROR_IMPROPER_LENGTH = "CONVERSION_IMPROPER_LENGTH";

    function dangerouslyCastUintArrayToBytes(uint256[] memory _input) internal pure returns (bytes memory output) {
        // Force cast the uint256[] into a bytes array, by overwriting its length
        // Note that the bytes array doesn't need to be initialized as we immediately overwrite it
        // with the input and a new length. The input becomes invalid from this point forward.
        uint256 byteLength = _input.length * 32;
        assembly {
            output := _input
            mstore(output, byteLength)
        }
    }

    function dangerouslyCastBytesToUintArray(bytes memory _input) internal pure returns (uint256[] memory output) {
        // Force cast the bytes array into a uint256[], by overwriting its length
        // Note that the uint256[] doesn't need to be initialized as we immediately overwrite it
        // with the input and a new length. The input becomes invalid from this point forward.
        uint256 intsLength = _input.length / 32;
        require(_input.length == intsLength * 32, ERROR_IMPROPER_LENGTH);

        assembly {
            output := _input
            mstore(output, intsLength)
        }
    }
}

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.4.24;


// aragonOS and aragon-apps rely on address(0) to denote native ETH, in
// contracts where both tokens and ETH are accepted
contract EtherTokenConstant {
    address internal constant ETH = address(0);
}

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.4.24;

import "./TimeHelpers.sol";
import "./UnstructuredStorage.sol";


contract Initializable is TimeHelpers {
    using UnstructuredStorage for bytes32;

    // keccak256("aragonOS.initializable.initializationBlock")
    bytes32 internal constant INITIALIZATION_BLOCK_POSITION = 0xebb05b386a8d34882b8711d156f463690983dc47815980fb82aeeff1aa43579e;

    string private constant ERROR_ALREADY_INITIALIZED = "INIT_ALREADY_INITIALIZED";
    string private constant ERROR_NOT_INITIALIZED = "INIT_NOT_INITIALIZED";

    modifier onlyInit {
        require(getInitializationBlock() == 0, ERROR_ALREADY_INITIALIZED);
        _;
    }

    modifier isInitialized {
        require(hasInitialized(), ERROR_NOT_INITIALIZED);
        _;
    }

    /**
    * @return Block number in which the contract was initialized
    */
    function getInitializationBlock() public view returns (uint256) {
        return INITIALIZATION_BLOCK_POSITION.getStorageUint256();
    }

    /**
    * @return Whether the contract has been initialized by the time of the current block
    */
    function hasInitialized() public view returns (bool) {
        uint256 initializationBlock = getInitializationBlock();
        return initializationBlock != 0 && getBlockNumber() >= initializationBlock;
    }

    /**
    * @dev Function to be called by top level contract after initialization has finished.
    */
    function initialized() internal onlyInit {
        INITIALIZATION_BLOCK_POSITION.setStorageUint256(getBlockNumber());
    }

    /**
    * @dev Function to be called by top level contract after initialization to enable the contract
    *      at a future block number rather than immediately.
    */
    function initializedAt(uint256 _blockNumber) internal onlyInit {
        INITIALIZATION_BLOCK_POSITION.setStorageUint256(_blockNumber);
    }
}

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.4.24;


contract IsContract {
    /*
    * NOTE: this should NEVER be used for authentication
    * (see pitfalls: https://github.com/fergarrui/ethereum-security/tree/master/contracts/extcodesize).
    *
    * This is only intended to be used as a sanity check that an address is actually a contract,
    * RATHER THAN an address not being a contract.
    */
    function isContract(address _target) internal view returns (bool) {
        if (_target == address(0)) {
            return false;
        }

        uint256 size;
        assembly { size := extcodesize(_target) }
        return size > 0;
    }
}

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.4.24;


interface IVaultRecoverable {
    event RecoverToVault(address indexed vault, address indexed token, uint256 amount);

    function transferToVault(address token) external;

    function allowRecoverability(address token) external view returns (bool);
    function getRecoveryVault() external view returns (address);
}

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.4.24;

import "./Initializable.sol";


contract Petrifiable is Initializable {
    // Use block UINT256_MAX (which should be never) as the initializable date
    uint256 internal constant PETRIFIED_BLOCK = uint256(-1);

    function isPetrified() public view returns (bool) {
        return getInitializationBlock() == PETRIFIED_BLOCK;
    }

    /**
    * @dev Function to be called by top level contract to prevent being initialized.
    *      Useful for freezing base contracts when they're used behind proxies.
    */
    function petrify() internal onlyInit {
        initializedAt(PETRIFIED_BLOCK);
    }
}

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.4.24;

import "../common/UnstructuredStorage.sol";


contract ReentrancyGuard {
    using UnstructuredStorage for bytes32;

    /* Hardcoded constants to save gas
    bytes32 internal constant REENTRANCY_MUTEX_POSITION = keccak256("aragonOS.reentrancyGuard.mutex");
    */
    bytes32 private constant REENTRANCY_MUTEX_POSITION = 0xe855346402235fdd185c890e68d2c4ecad599b88587635ee285bce2fda58dacb;

    string private constant ERROR_REENTRANT = "REENTRANCY_REENTRANT_CALL";

    modifier nonReentrant() {
        // Ensure mutex is unlocked
        require(!REENTRANCY_MUTEX_POSITION.getStorageBool(), ERROR_REENTRANT);

        // Lock mutex before function call
        REENTRANCY_MUTEX_POSITION.setStorageBool(true);

        // Perform function call
        _;

        // Unlock mutex after function call
        REENTRANCY_MUTEX_POSITION.setStorageBool(false);
    }
}

// Inspired by AdEx (https://github.com/AdExNetwork/adex-protocol-eth/blob/b9df617829661a7518ee10f4cb6c4108659dd6d5/contracts/libs/SafeERC20.sol)
// and 0x (https://github.com/0xProject/0x-monorepo/blob/737d1dc54d72872e24abce5a1dbe1b66d35fa21a/contracts/protocol/contracts/protocol/AssetProxy/ERC20Proxy.sol#L143)

pragma solidity ^0.4.24;

import "../lib/token/ERC20.sol";


library SafeERC20 {
    // Before 0.5, solidity has a mismatch between `address.transfer()` and `token.transfer()`:
    // https://github.com/ethereum/solidity/issues/3544
    bytes4 private constant TRANSFER_SELECTOR = 0xa9059cbb;

    string private constant ERROR_TOKEN_BALANCE_REVERTED = "SAFE_ERC_20_BALANCE_REVERTED";
    string private constant ERROR_TOKEN_ALLOWANCE_REVERTED = "SAFE_ERC_20_ALLOWANCE_REVERTED";

    function invokeAndCheckSuccess(address _addr, bytes memory _calldata)
        private
        returns (bool)
    {
        bool ret;
        assembly {
            let ptr := mload(0x40)    // free memory pointer

            let success := call(
                gas,                  // forward all gas
                _addr,                // address
                0,                    // no value
                add(_calldata, 0x20), // calldata start
                mload(_calldata),     // calldata length
                ptr,                  // write output over free memory
                0x20                  // uint256 return
            )

            if gt(success, 0) {
                // Check number of bytes returned from last function call
                switch returndatasize

                // No bytes returned: assume success
                case 0 {
                    ret := 1
                }

                // 32 bytes returned: check if non-zero
                case 0x20 {
                    // Only return success if returned data was true
                    // Already have output in ptr
                    ret := eq(mload(ptr), 1)
                }

                // Not sure what was returned: don't mark as success
                default { }
            }
        }
        return ret;
    }

    function staticInvoke(address _addr, bytes memory _calldata)
        private
        view
        returns (bool, uint256)
    {
        bool success;
        uint256 ret;
        assembly {
            let ptr := mload(0x40)    // free memory pointer

            success := staticcall(
                gas,                  // forward all gas
                _addr,                // address
                add(_calldata, 0x20), // calldata start
                mload(_calldata),     // calldata length
                ptr,                  // write output over free memory
                0x20                  // uint256 return
            )

            if gt(success, 0) {
                ret := mload(ptr)
            }
        }
        return (success, ret);
    }

    /**
    * @dev Same as a standards-compliant ERC20.transfer() that never reverts (returns false).
    *      Note that this makes an external call to the token.
    */
    function safeTransfer(ERC20 _token, address _to, uint256 _amount) internal returns (bool) {
        bytes memory transferCallData = abi.encodeWithSelector(
            TRANSFER_SELECTOR,
            _to,
            _amount
        );
        return invokeAndCheckSuccess(_token, transferCallData);
    }

    /**
    * @dev Same as a standards-compliant ERC20.transferFrom() that never reverts (returns false).
    *      Note that this makes an external call to the token.
    */
    function safeTransferFrom(ERC20 _token, address _from, address _to, uint256 _amount) internal returns (bool) {
        bytes memory transferFromCallData = abi.encodeWithSelector(
            _token.transferFrom.selector,
            _from,
            _to,
            _amount
        );
        return invokeAndCheckSuccess(_token, transferFromCallData);
    }

    /**
    * @dev Same as a standards-compliant ERC20.approve() that never reverts (returns false).
    *      Note that this makes an external call to the token.
    */
    function safeApprove(ERC20 _token, address _spender, uint256 _amount) internal returns (bool) {
        bytes memory approveCallData = abi.encodeWithSelector(
            _token.approve.selector,
            _spender,
            _amount
        );
        return invokeAndCheckSuccess(_token, approveCallData);
    }

    /**
    * @dev Static call into ERC20.balanceOf().
    * Reverts if the call fails for some reason (should never fail).
    */
    function staticBalanceOf(ERC20 _token, address _owner) internal view returns (uint256) {
        bytes memory balanceOfCallData = abi.encodeWithSelector(
            _token.balanceOf.selector,
            _owner
        );

        (bool success, uint256 tokenBalance) = staticInvoke(_token, balanceOfCallData);
        require(success, ERROR_TOKEN_BALANCE_REVERTED);

        return tokenBalance;
    }

    /**
    * @dev Static call into ERC20.allowance().
    * Reverts if the call fails for some reason (should never fail).
    */
    function staticAllowance(ERC20 _token, address _owner, address _spender) internal view returns (uint256) {
        bytes memory allowanceCallData = abi.encodeWithSelector(
            _token.allowance.selector,
            _owner,
            _spender
        );

        (bool success, uint256 allowance) = staticInvoke(_token, allowanceCallData);
        require(success, ERROR_TOKEN_ALLOWANCE_REVERTED);

        return allowance;
    }

    /**
    * @dev Static call into ERC20.totalSupply().
    * Reverts if the call fails for some reason (should never fail).
    */
    function staticTotalSupply(ERC20 _token) internal view returns (uint256) {
        bytes memory totalSupplyCallData = abi.encodeWithSelector(_token.totalSupply.selector);

        (bool success, uint256 totalSupply) = staticInvoke(_token, totalSupplyCallData);
        require(success, ERROR_TOKEN_ALLOWANCE_REVERTED);

        return totalSupply;
    }
}

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.4.24;

import "./Uint256Helpers.sol";


contract TimeHelpers {
    using Uint256Helpers for uint256;

    /**
    * @dev Returns the current block number.
    *      Using a function rather than `block.number` allows us to easily mock the block number in
    *      tests.
    */
    function getBlockNumber() internal view returns (uint256) {
        return block.number;
    }

    /**
    * @dev Returns the current block number, converted to uint64.
    *      Using a function rather than `block.number` allows us to easily mock the block number in
    *      tests.
    */
    function getBlockNumber64() internal view returns (uint64) {
        return getBlockNumber().toUint64();
    }

    /**
    * @dev Returns the current timestamp.
    *      Using a function rather than `block.timestamp` allows us to easily mock it in
    *      tests.
    */
    function getTimestamp() internal view returns (uint256) {
        return block.timestamp; // solium-disable-line security/no-block-members
    }

    /**
    * @dev Returns the current timestamp, converted to uint64.
    *      Using a function rather than `block.timestamp` allows us to easily mock it in
    *      tests.
    */
    function getTimestamp64() internal view returns (uint64) {
        return getTimestamp().toUint64();
    }
}

pragma solidity ^0.4.24;


library Uint256Helpers {
    uint256 private constant MAX_UINT64 = uint64(-1);

    string private constant ERROR_NUMBER_TOO_BIG = "UINT64_NUMBER_TOO_BIG";

    function toUint64(uint256 a) internal pure returns (uint64) {
        require(a <= MAX_UINT64, ERROR_NUMBER_TOO_BIG);
        return uint64(a);
    }
}

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.4.24;


library UnstructuredStorage {
    function getStorageBool(bytes32 position) internal view returns (bool data) {
        assembly { data := sload(position) }
    }

    function getStorageAddress(bytes32 position) internal view returns (address data) {
        assembly { data := sload(position) }
    }

    function getStorageBytes32(bytes32 position) internal view returns (bytes32 data) {
        assembly { data := sload(position) }
    }

    function getStorageUint256(bytes32 position) internal view returns (uint256 data) {
        assembly { data := sload(position) }
    }

    function setStorageBool(bytes32 position, bool data) internal {
        assembly { sstore(position, data) }
    }

    function setStorageAddress(bytes32 position, address data) internal {
        assembly { sstore(position, data) }
    }

    function setStorageBytes32(bytes32 position, bytes32 data) internal {
        assembly { sstore(position, data) }
    }

    function setStorageUint256(bytes32 position, uint256 data) internal {
        assembly { sstore(position, data) }
    }
}

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.4.24;

import "../lib/token/ERC20.sol";
import "./EtherTokenConstant.sol";
import "./IsContract.sol";
import "./IVaultRecoverable.sol";
import "./SafeERC20.sol";


contract VaultRecoverable is IVaultRecoverable, EtherTokenConstant, IsContract {
    using SafeERC20 for ERC20;

    string private constant ERROR_DISALLOWED = "RECOVER_DISALLOWED";
    string private constant ERROR_VAULT_NOT_CONTRACT = "RECOVER_VAULT_NOT_CONTRACT";
    string private constant ERROR_TOKEN_TRANSFER_FAILED = "RECOVER_TOKEN_TRANSFER_FAILED";

    /**
     * @notice Send funds to recovery Vault. This contract should never receive funds,
     *         but in case it does, this function allows one to recover them.
     * @param _token Token balance to be sent to recovery vault.
     */
    function transferToVault(address _token) external {
        require(allowRecoverability(_token), ERROR_DISALLOWED);
        address vault = getRecoveryVault();
        require(isContract(vault), ERROR_VAULT_NOT_CONTRACT);

        uint256 balance;
        if (_token == ETH) {
            balance = address(this).balance;
            vault.transfer(balance);
        } else {
            ERC20 token = ERC20(_token);
            balance = token.staticBalanceOf(this);
            require(token.safeTransfer(vault, balance), ERROR_TOKEN_TRANSFER_FAILED);
        }

        emit RecoverToVault(vault, _token, balance);
    }

    /**
    * @dev By default deriving from AragonApp makes it recoverable
    * @param token Token address that would be recovered
    * @return bool whether the app allows the recovery
    */
    function allowRecoverability(address token) public view returns (bool) {
        return true;
    }

    // Cast non-implemented interface to be public so we can use it internally
    function getRecoveryVault() public view returns (address);
}

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.4.24;

import "./IEVMScriptExecutor.sol";
import "./IEVMScriptRegistry.sol";

import "../apps/AppStorage.sol";
import "../kernel/KernelConstants.sol";
import "../common/Initializable.sol";


contract EVMScriptRunner is AppStorage, Initializable, EVMScriptRegistryConstants, KernelNamespaceConstants {
    string private constant ERROR_EXECUTOR_UNAVAILABLE = "EVMRUN_EXECUTOR_UNAVAILABLE";
    string private constant ERROR_PROTECTED_STATE_MODIFIED = "EVMRUN_PROTECTED_STATE_MODIFIED";

    /* This is manually crafted in assembly
    string private constant ERROR_EXECUTOR_INVALID_RETURN = "EVMRUN_EXECUTOR_INVALID_RETURN";
    */

    event ScriptResult(address indexed executor, bytes script, bytes input, bytes returnData);

    function getEVMScriptExecutor(bytes _script) public view returns (IEVMScriptExecutor) {
        return IEVMScriptExecutor(getEVMScriptRegistry().getScriptExecutor(_script));
    }

    function getEVMScriptRegistry() public view returns (IEVMScriptRegistry) {
        address registryAddr = kernel().getApp(KERNEL_APP_ADDR_NAMESPACE, EVMSCRIPT_REGISTRY_APP_ID);
        return IEVMScriptRegistry(registryAddr);
    }

    function runScript(bytes _script, bytes _input, address[] _blacklist)
        internal
        isInitialized
        protectState
        returns (bytes)
    {
        IEVMScriptExecutor executor = getEVMScriptExecutor(_script);
        require(address(executor) != address(0), ERROR_EXECUTOR_UNAVAILABLE);

        bytes4 sig = executor.execScript.selector;
        bytes memory data = abi.encodeWithSelector(sig, _script, _input, _blacklist);

        bytes memory output;
        assembly {
            let success := delegatecall(
                gas,                // forward all gas
                executor,           // address
                add(data, 0x20),    // calldata start
                mload(data),        // calldata length
                0,                  // don't write output (we'll handle this ourselves)
                0                   // don't write output
            )

            output := mload(0x40) // free mem ptr get

            switch success
            case 0 {
                // If the call errored, forward its full error data
                returndatacopy(output, 0, returndatasize)
                revert(output, returndatasize)
            }
            default {
                switch gt(returndatasize, 0x3f)
                case 0 {
                    // Need at least 0x40 bytes returned for properly ABI-encoded bytes values,
                    // revert with "EVMRUN_EXECUTOR_INVALID_RETURN"
                    // See remix: doing a `revert("EVMRUN_EXECUTOR_INVALID_RETURN")` always results in
                    // this memory layout
                    mstore(output, 0x08c379a000000000000000000000000000000000000000000000000000000000)         // error identifier
                    mstore(add(output, 0x04), 0x0000000000000000000000000000000000000000000000000000000000000020) // starting offset
                    mstore(add(output, 0x24), 0x000000000000000000000000000000000000000000000000000000000000001e) // reason length
                    mstore(add(output, 0x44), 0x45564d52554e5f4558454355544f525f494e56414c49445f52455455524e0000) // reason

                    revert(output, 100) // 100 = 4 + 3 * 32 (error identifier + 3 words for the ABI encoded error)
                }
                default {
                    // Copy result
                    //
                    // Needs to perform an ABI decode for the expected `bytes` return type of
                    // `executor.execScript()` as solidity will automatically ABI encode the returned bytes as:
                    //    [ position of the first dynamic length return value = 0x20 (32 bytes) ]
                    //    [ output length (32 bytes) ]
                    //    [ output content (N bytes) ]
                    //
                    // Perform the ABI decode by ignoring the first 32 bytes of the return data
                    let copysize := sub(returndatasize, 0x20)
                    returndatacopy(output, 0x20, copysize)

                    mstore(0x40, add(output, copysize)) // free mem ptr set
                }
            }
        }

        emit ScriptResult(address(executor), _script, _input, output);

        return output;
    }

    modifier protectState {
        address preKernel = address(kernel());
        bytes32 preAppId = appId();
        _; // exec
        require(address(kernel()) == preKernel, ERROR_PROTECTED_STATE_MODIFIED);
        require(appId() == preAppId, ERROR_PROTECTED_STATE_MODIFIED);
    }
}

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.4.24;


interface IEVMScriptExecutor {
    function execScript(bytes script, bytes input, address[] blacklist) external returns (bytes);
    function executorType() external pure returns (bytes32);
}

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.4.24;

import "./IEVMScriptExecutor.sol";


contract EVMScriptRegistryConstants {
    /* Hardcoded constants to save gas
    bytes32 internal constant EVMSCRIPT_REGISTRY_APP_ID = apmNamehash("evmreg");
    */
    bytes32 internal constant EVMSCRIPT_REGISTRY_APP_ID = 0xddbcfd564f642ab5627cf68b9b7d374fb4f8a36e941a75d89c87998cef03bd61;
}


interface IEVMScriptRegistry {
    function addScriptExecutor(IEVMScriptExecutor executor) external returns (uint id);
    function disableScriptExecutor(uint256 executorId) external;

    // TODO: this should be external
    // See https://github.com/ethereum/solidity/issues/4832
    function getScriptExecutor(bytes script) public view returns (IEVMScriptExecutor);
}

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.4.24;

import "../acl/IACL.sol";
import "../common/IVaultRecoverable.sol";


interface IKernelEvents {
    event SetApp(bytes32 indexed namespace, bytes32 indexed appId, address app);
}


// This should be an interface, but interfaces can't inherit yet :(
contract IKernel is IKernelEvents, IVaultRecoverable {
    function acl() public view returns (IACL);
    function hasPermission(address who, address where, bytes32 what, bytes how) public view returns (bool);

    function setApp(bytes32 namespace, bytes32 appId, address app) public;
    function getApp(bytes32 namespace, bytes32 appId) public view returns (address);
}

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.4.24;


contract KernelAppIds {
    /* Hardcoded constants to save gas
    bytes32 internal constant KERNEL_CORE_APP_ID = apmNamehash("kernel");
    bytes32 internal constant KERNEL_DEFAULT_ACL_APP_ID = apmNamehash("acl");
    bytes32 internal constant KERNEL_DEFAULT_VAULT_APP_ID = apmNamehash("vault");
    */
    bytes32 internal constant KERNEL_CORE_APP_ID = 0x3b4bf6bf3ad5000ecf0f989d5befde585c6860fea3e574a4fab4c49d1c177d9c;
    bytes32 internal constant KERNEL_DEFAULT_ACL_APP_ID = 0xe3262375f45a6e2026b7e7b18c2b807434f2508fe1a2a3dfb493c7df8f4aad6a;
    bytes32 internal constant KERNEL_DEFAULT_VAULT_APP_ID = 0x7e852e0fcfce6551c13800f1e7476f982525c2b5277ba14b24339c68416336d1;
}


contract KernelNamespaceConstants {
    /* Hardcoded constants to save gas
    bytes32 internal constant KERNEL_CORE_NAMESPACE = keccak256("core");
    bytes32 internal constant KERNEL_APP_BASES_NAMESPACE = keccak256("base");
    bytes32 internal constant KERNEL_APP_ADDR_NAMESPACE = keccak256("app");
    */
    bytes32 internal constant KERNEL_CORE_NAMESPACE = 0xc681a85306374a5ab27f0bbc385296a54bcd314a1948b6cf61c4ea1bc44bb9f8;
    bytes32 internal constant KERNEL_APP_BASES_NAMESPACE = 0xf1f3eb40f5bc1ad1344716ced8b8a0431d840b5783aea1fd01786bc26f35ac0f;
    bytes32 internal constant KERNEL_APP_ADDR_NAMESPACE = 0xd6f028ca0e8edb4a8c9757ca4fdccab25fa1e0317da1188108f7d2dee14902fb;
}

// See https://github.com/OpenZeppelin/openzeppelin-solidity/blob/d51e38758e1d985661534534d5c61e27bece5042/contracts/math/SafeMath.sol
// Adapted to use pragma ^0.4.24 and satisfy our linter rules

pragma solidity ^0.4.24;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {
    string private constant ERROR_ADD_OVERFLOW = "MATH_ADD_OVERFLOW";
    string private constant ERROR_SUB_UNDERFLOW = "MATH_SUB_UNDERFLOW";
    string private constant ERROR_MUL_OVERFLOW = "MATH_MUL_OVERFLOW";
    string private constant ERROR_DIV_ZERO = "MATH_DIV_ZERO";

    /**
    * @dev Multiplies two numbers, reverts on overflow.
    */
    function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (_a == 0) {
            return 0;
        }

        uint256 c = _a * _b;
        require(c / _a == _b, ERROR_MUL_OVERFLOW);

        return c;
    }

    /**
    * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b > 0, ERROR_DIV_ZERO); // Solidity only automatically asserts when dividing by 0
        uint256 c = _a / _b;
        // assert(_a == _b * c + _a % _b); // There is no case in which this doesn't hold

        return c;
    }

    /**
    * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b <= _a, ERROR_SUB_UNDERFLOW);
        uint256 c = _a - _b;

        return c;
    }

    /**
    * @dev Adds two numbers, reverts on overflow.
    */
    function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
        uint256 c = _a + _b;
        require(c >= _a, ERROR_ADD_OVERFLOW);

        return c;
    }

    /**
    * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, ERROR_DIV_ZERO);
        return a % b;
    }
}

// See https://github.com/OpenZeppelin/openzeppelin-solidity/blob/d51e38758e1d985661534534d5c61e27bece5042/contracts/math/SafeMath.sol
// Adapted for uint64, pragma ^0.4.24, and satisfying our linter rules
// Also optimized the mul() implementation, see https://github.com/aragon/aragonOS/pull/417

pragma solidity ^0.4.24;


/**
 * @title SafeMath64
 * @dev Math operations for uint64 with safety checks that revert on error
 */
library SafeMath64 {
    string private constant ERROR_ADD_OVERFLOW = "MATH64_ADD_OVERFLOW";
    string private constant ERROR_SUB_UNDERFLOW = "MATH64_SUB_UNDERFLOW";
    string private constant ERROR_MUL_OVERFLOW = "MATH64_MUL_OVERFLOW";
    string private constant ERROR_DIV_ZERO = "MATH64_DIV_ZERO";

    /**
    * @dev Multiplies two numbers, reverts on overflow.
    */
    function mul(uint64 _a, uint64 _b) internal pure returns (uint64) {
        uint256 c = uint256(_a) * uint256(_b);
        require(c < 0x010000000000000000, ERROR_MUL_OVERFLOW); // 2**64 (less gas this way)

        return uint64(c);
    }

    /**
    * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
    */
    function div(uint64 _a, uint64 _b) internal pure returns (uint64) {
        require(_b > 0, ERROR_DIV_ZERO); // Solidity only automatically asserts when dividing by 0
        uint64 c = _a / _b;
        // assert(_a == _b * c + _a % _b); // There is no case in which this doesn't hold

        return c;
    }

    /**
    * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint64 _a, uint64 _b) internal pure returns (uint64) {
        require(_b <= _a, ERROR_SUB_UNDERFLOW);
        uint64 c = _a - _b;

        return c;
    }

    /**
    * @dev Adds two numbers, reverts on overflow.
    */
    function add(uint64 _a, uint64 _b) internal pure returns (uint64) {
        uint64 c = _a + _b;
        require(c >= _a, ERROR_ADD_OVERFLOW);

        return c;
    }

    /**
    * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint64 a, uint64 b) internal pure returns (uint64) {
        require(b != 0, ERROR_DIV_ZERO);
        return a % b;
    }
}

// See https://github.com/OpenZeppelin/openzeppelin-solidity/blob/a9f910d34f0ab33a1ae5e714f69f9596a02b4d91/contracts/token/ERC20/ERC20.sol

pragma solidity ^0.4.24;


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 {
    function totalSupply() public view returns (uint256);

    function balanceOf(address _who) public view returns (uint256);

    function allowance(address _owner, address _spender)
        public view returns (uint256);

    function transfer(address _to, uint256 _value) public returns (bool);

    function approve(address _spender, uint256 _value)
        public returns (bool);

    function transferFrom(address _from, address _to, uint256 _value)
        public returns (bool);

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// SPDX-FileCopyrightText: 2023 Lido <[email protected]>
// SPDX-License-Identifier: MIT

// Copied from: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/0457042d93d9dfd760dbaa06a4d2f1216fdbe297/contracts/utils/math/Math.sol

// See contracts/COMPILERS.md
// solhint-disable-next-line
pragma solidity ^0.4.24;


library Packed64x4 {
    using Packed64x4 for Packed64x4.Packed;

    // string private constant ERROR_OFFSET_OUT_OF_RANGE = "OFFSET_OUT_OF_RANGE";
    uint256 internal constant UINT64_MAX = 0xFFFFFFFFFFFFFFFF;

    struct Packed {
        uint256 v;
    }

    //extract n-th uint64 from uint256
    function get(Packed memory _self, uint8 n) internal pure returns (uint64 r) {
        // require(n < 4, ERROR_OFFSET_OUT_OF_RANGE);
        r = uint64((_self.v >> (64 * n)) & UINT64_MAX);
    }

    //merge n-th uint64 to uint256
    function set(Packed memory _self, uint8 n, uint64 x) internal pure {
        // require(n < 4, ERROR_OFFSET_OUT_OF_RANGE);
        _self.v = _self.v & ~(UINT64_MAX << (64 * n)) | ((uint256(x) & UINT64_MAX) << (64 * n));
    }
}

// SPDX-FileCopyrightText: 2023 Lido <[email protected]>
// SPDX-License-Identifier: GPL-3.0

// See contracts/COMPILERS.md
pragma solidity 0.4.24;

import {SafeMath} from "@aragon/os/contracts/lib/math/SafeMath.sol";
import {SafeMath64} from "@aragon/os/contracts/lib/math/SafeMath64.sol";

/// @title Library for manage operator keys in storage
/// @author KRogLA
library SigningKeys {
    using SafeMath for uint256;
    using SafeMath64 for uint64;
    using SigningKeys for bytes32;

    uint64 internal constant PUBKEY_LENGTH = 48;
    uint64 internal constant SIGNATURE_LENGTH = 96;
    uint256 internal constant UINT64_MAX = 0xFFFFFFFFFFFFFFFF;

    event SigningKeyAdded(uint256 indexed nodeOperatorId, bytes pubkey);
    event SigningKeyRemoved(uint256 indexed nodeOperatorId, bytes pubkey);

    function getKeyOffset(bytes32 _position, uint256 _nodeOperatorId, uint256 _keyIndex) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(_position, _nodeOperatorId, _keyIndex)));
    }

    /// @dev store opeartor keys to storage
    /// @param _position storage slot
    /// @param _nodeOperatorId operator id
    /// @param _startIndex start index
    /// @param _keysCount keys count to load
    /// @param _pubkeys kes buffer to read from
    /// @param _signatures signatures buffer to read from
    /// @return new total keys count
    function saveKeysSigs(
        bytes32 _position,
        uint256 _nodeOperatorId,
        uint256 _startIndex,
        uint256 _keysCount,
        bytes _pubkeys,
        bytes _signatures
    ) internal returns (uint256) {
        require(_keysCount > 0 && _startIndex.add(_keysCount - 1) <= UINT64_MAX, "INVALID_KEYS_COUNT");
        require(
            _pubkeys.length == _keysCount.mul(PUBKEY_LENGTH) && _signatures.length == _keysCount.mul(SIGNATURE_LENGTH),
            "LENGTH_MISMATCH"
        );

        uint256 curOffset;
        bool isEmpty;
        bytes memory tmpKey = new bytes(48);

        for (uint256 i; i < _keysCount;) {
            curOffset = _position.getKeyOffset(_nodeOperatorId, _startIndex);
            assembly {
                let _ofs := add(add(_pubkeys, 0x20), mul(i, 48)) //PUBKEY_LENGTH = 48
                let _part1 := mload(_ofs) // bytes 0..31
                let _part2 := mload(add(_ofs, 0x10)) // bytes 16..47
                isEmpty := iszero(or(_part1, _part2))
                mstore(add(tmpKey, 0x30), _part2) // store 2nd part first
                mstore(add(tmpKey, 0x20), _part1) // store 1st part with overwrite bytes 16-31
            }

            require(!isEmpty, "EMPTY_KEY");
            assembly {
                // store key
                sstore(curOffset, mload(add(tmpKey, 0x20))) // store bytes 0..31
                sstore(add(curOffset, 1), shl(128, mload(add(tmpKey, 0x30)))) // store bytes 32..47
                // store signature
                let _ofs := add(add(_signatures, 0x20), mul(i, 96)) //SIGNATURE_LENGTH = 96
                sstore(add(curOffset, 2), mload(_ofs))
                sstore(add(curOffset, 3), mload(add(_ofs, 0x20)))
                sstore(add(curOffset, 4), mload(add(_ofs, 0x40)))
                i := add(i, 1)
                _startIndex := add(_startIndex, 1)
            }
            emit SigningKeyAdded(_nodeOperatorId, tmpKey);
        }
        return _startIndex;
    }

    /// @dev remove opeartor keys from storage
    /// @param _position storage slot
    /// @param _nodeOperatorId operator id
    /// @param _startIndex start index
    /// @param _keysCount keys count to load
    /// @param _totalKeysCount current total keys count for operator
    /// @return new _totalKeysCount
    function removeKeysSigs(
        bytes32 _position,
        uint256 _nodeOperatorId,
        uint256 _startIndex,
        uint256 _keysCount,
        uint256 _totalKeysCount
    ) internal returns (uint256) {
        require(
            _keysCount > 0 && _startIndex.add(_keysCount) <= _totalKeysCount && _totalKeysCount <= UINT64_MAX,
            "INVALID_KEYS_COUNT"
        );

        uint256 curOffset;
        uint256 lastOffset;
        uint256 j;
        bytes memory tmpKey = new bytes(48);
        // removing from the last index
        for (uint256 i = _startIndex + _keysCount; i > _startIndex;) {
            curOffset = _position.getKeyOffset(_nodeOperatorId, i - 1);
            assembly {
                // read key
                mstore(add(tmpKey, 0x30), shr(128, sload(add(curOffset, 1)))) // bytes 16..47
                mstore(add(tmpKey, 0x20), sload(curOffset)) // bytes 0..31
            }
            if (i < _totalKeysCount) {
                lastOffset = _position.getKeyOffset(_nodeOperatorId, _totalKeysCount - 1);
                // move last key to deleted key index
                for (j = 0; j < 5;) {
                    assembly {
                        sstore(add(curOffset, j), sload(add(lastOffset, j)))
                        j := add(j, 1)
                    }
                }
                curOffset = lastOffset;
            }
            // clear storage
            for (j = 0; j < 5;) {
                assembly {
                    sstore(add(curOffset, j), 0)
                    j := add(j, 1)
                }
            }
            assembly {
                _totalKeysCount := sub(_totalKeysCount, 1)
                i := sub(i, 1)
            }
            emit SigningKeyRemoved(_nodeOperatorId, tmpKey);
        }
        return _totalKeysCount;
    }

    /// @dev laod opeartor keys from storage
    /// @param _position storage slot
    /// @param _nodeOperatorId operator id
    /// @param _startIndex start index
    /// @param _keysCount keys count to load
    /// @param _pubkeys preallocated kes buffer to read in
    /// @param _signatures preallocated signatures buffer to read in
    /// @param _bufOffset start offset in `_pubkeys`/`_signatures` buffer to place values (in number of keys)
    function loadKeysSigs(
        bytes32 _position,
        uint256 _nodeOperatorId,
        uint256 _startIndex,
        uint256 _keysCount,
        bytes memory _pubkeys,
        bytes memory _signatures,
        uint256 _bufOffset
    ) internal view {
        uint256 curOffset;
        for (uint256 i; i < _keysCount;) {
            curOffset = _position.getKeyOffset(_nodeOperatorId, _startIndex + i);
            assembly {
                // read key
                let _ofs := add(add(_pubkeys, 0x20), mul(add(_bufOffset, i), 48)) //PUBKEY_LENGTH = 48
                mstore(add(_ofs, 0x10), shr(128, sload(add(curOffset, 1)))) // bytes 16..47
                mstore(_ofs, sload(curOffset)) // bytes 0..31
                // store signature
                _ofs := add(add(_signatures, 0x20), mul(add(_bufOffset, i), 96)) //SIGNATURE_LENGTH = 96
                mstore(_ofs, sload(add(curOffset, 2)))
                mstore(add(_ofs, 0x20), sload(add(curOffset, 3)))
                mstore(add(_ofs, 0x40), sload(add(curOffset, 4)))
                i := add(i, 1)
            }
        }
    }

    function initKeysSigsBuf(uint256 _count) internal pure returns (bytes memory, bytes memory) {
        return (new bytes(_count.mul(PUBKEY_LENGTH)), new bytes(_count.mul(SIGNATURE_LENGTH)));
    }
}

// SPDX-FileCopyrightText: 2023 Lido <[email protected]>
// SPDX-License-Identifier: GPL-3.0

// See contracts/COMPILERS.md
pragma solidity 0.4.24;

import {AragonApp} from "@aragon/os/contracts/apps/AragonApp.sol";
import {SafeMath} from "@aragon/os/contracts/lib/math/SafeMath.sol";
import {SafeMath64} from "@aragon/os/contracts/lib/math/SafeMath64.sol";
import {UnstructuredStorage} from "@aragon/os/contracts/common/UnstructuredStorage.sol";

import {Math256} from "../../common/lib/Math256.sol";
import {MinFirstAllocationStrategy} from "../../common/lib/MinFirstAllocationStrategy.sol";
import {ILidoLocator} from "../../common/interfaces/ILidoLocator.sol";
import {IBurner} from "../../common/interfaces/IBurner.sol";
import {SigningKeys} from "../lib/SigningKeys.sol";
import {Packed64x4} from "../lib/Packed64x4.sol";
import {Versioned} from "../utils/Versioned.sol";

interface IStETH {
    function sharesOf(address _account) external view returns (uint256);
    function transferShares(address _recipient, uint256 _sharesAmount) external returns (uint256);
    function approve(address _spender, uint256 _amount) external returns (bool);
}

/// @title Node Operator registry
/// @notice Node Operator registry manages signing keys and other node operator data.
/// @dev Must implement the full version of IStakingModule interface, not only the one declared locally.
///      It's also responsible for distributing rewards to node operators.
/// NOTE: the code below assumes moderate amount of node operators, i.e. up to `MAX_NODE_OPERATORS_COUNT`.
contract NodeOperatorsRegistry is AragonApp, Versioned {
    using SafeMath for uint256;
    using SafeMath64 for uint64;
    using UnstructuredStorage for bytes32;
    using SigningKeys for bytes32;
    using Packed64x4 for Packed64x4.Packed;

    //
    // EVENTS
    //
    event NodeOperatorAdded(uint256 nodeOperatorId, string name, address rewardAddress, uint64 stakingLimit);
    event NodeOperatorActiveSet(uint256 indexed nodeOperatorId, bool active);
    event NodeOperatorNameSet(uint256 indexed nodeOperatorId, string name);
    event NodeOperatorRewardAddressSet(uint256 indexed nodeOperatorId, address rewardAddress);
    event NodeOperatorTotalKeysTrimmed(uint256 indexed nodeOperatorId, uint64 totalKeysTrimmed);
    event KeysOpIndexSet(uint256 keysOpIndex);
    event StakingModuleTypeSet(bytes32 moduleType);
    event RewardsDistributed(address indexed rewardAddress, uint256 sharesAmount);
    event LocatorContractSet(address locatorAddress);
    event VettedSigningKeysCountChanged(uint256 indexed nodeOperatorId, uint256 approvedValidatorsCount);
    event DepositedSigningKeysCountChanged(uint256 indexed nodeOperatorId, uint256 depositedValidatorsCount);
    event ExitedSigningKeysCountChanged(uint256 indexed nodeOperatorId, uint256 exitedValidatorsCount);
    event TotalSigningKeysCountChanged(uint256 indexed nodeOperatorId, uint256 totalValidatorsCount);

    event NonceChanged(uint256 nonce);
    event StuckPenaltyDelayChanged(uint256 stuckPenaltyDelay);
    event StuckPenaltyStateChanged(
        uint256 indexed nodeOperatorId,
        uint256 stuckValidatorsCount,
        uint256 refundedValidatorsCount,
        uint256 stuckPenaltyEndTimestamp
    );
    event TargetValidatorsCountChanged(uint256 indexed nodeOperatorId, uint256 targetValidatorsCount);
    event NodeOperatorPenalized(address indexed recipientAddress, uint256 sharesPenalizedAmount);

    //
    // ACL
    //
    // bytes32 public constant MANAGE_SIGNING_KEYS = keccak256("MANAGE_SIGNING_KEYS");
    bytes32 public constant MANAGE_SIGNING_KEYS = 0x75abc64490e17b40ea1e66691c3eb493647b24430b358bd87ec3e5127f1621ee;
    // bytes32 public constant SET_NODE_OPERATOR_LIMIT_ROLE = keccak256("SET_NODE_OPERATOR_LIMIT_ROLE");
    bytes32 public constant SET_NODE_OPERATOR_LIMIT_ROLE = 0x07b39e0faf2521001ae4e58cb9ffd3840a63e205d288dc9c93c3774f0d794754;
    // bytes32 public constant ACTIVATE_NODE_OPERATOR_ROLE = keccak256("MANAGE_NODE_OPERATOR_ROLE");
    bytes32 public constant MANAGE_NODE_OPERATOR_ROLE = 0x78523850fdd761612f46e844cf5a16bda6b3151d6ae961fd7e8e7b92bfbca7f8;
    // bytes32 public constant STAKING_ROUTER_ROLE = keccak256("STAKING_ROUTER_ROLE");
    bytes32 public constant STAKING_ROUTER_ROLE = 0xbb75b874360e0bfd87f964eadd8276d8efb7c942134fc329b513032d0803e0c6;

    //
    // CONSTANTS
    //
    uint256 public constant MAX_NODE_OPERATORS_COUNT = 200;
    uint256 public constant MAX_NODE_OPERATOR_NAME_LENGTH = 255;
    uint256 public constant MAX_STUCK_PENALTY_DELAY = 365 days;

    uint256 internal constant UINT64_MAX = 0xFFFFFFFFFFFFFFFF;

    // SigningKeysStats
    /// @dev Operator's max validator keys count approved for deposit by the DAO
    uint8 internal constant TOTAL_VETTED_KEYS_COUNT_OFFSET = 0;
    /// @dev Number of keys in the EXITED state for this operator for all time
    uint8 internal constant TOTAL_EXITED_KEYS_COUNT_OFFSET = 1;
    /// @dev Total number of keys of this operator for all time
    uint8 internal constant TOTAL_KEYS_COUNT_OFFSET = 2;
    /// @dev Number of keys of this operator which were in DEPOSITED state for all time
    uint8 internal constant TOTAL_DEPOSITED_KEYS_COUNT_OFFSET = 3;

    // TargetValidatorsStats
    /// @dev Flag enable/disable limiting target active validators count for operator
    uint8 internal constant IS_TARGET_LIMIT_ACTIVE_OFFSET = 0;
    /// @dev relative target active validators limit for operator, set by DAO
    /// @notice used to check how many keys should go to exit, 0 - means all deposited keys would be exited
    uint8 internal constant TARGET_VALIDATORS_COUNT_OFFSET = 1;
    /// @dev actual operators's number of keys which could be deposited
    uint8 internal constant MAX_VALIDATORS_COUNT_OFFSET = 2;

    // StuckPenaltyStats
    /// @dev stuck keys count from oracle report
    uint8 internal constant STUCK_VALIDATORS_COUNT_OFFSET = 0;
    /// @dev refunded keys count from dao
    uint8 internal constant REFUNDED_VALIDATORS_COUNT_OFFSET = 1;
    /// @dev extra penalty time after stuck keys resolved (refunded and/or exited)
    /// @notice field is also used as flag for "half-cleaned" penalty status
    ///         Operator is PENALIZED if `STUCK_VALIDATORS_COUNT > REFUNDED_VALIDATORS_COUNT` or
    ///         `STUCK_VALIDATORS_COUNT <= REFUNDED_VALIDATORS_COUNT && STUCK_PENALTY_END_TIMESTAMP <= refund timestamp + STUCK_PENALTY_DELAY`
    ///         When operator refund all stuck validators and time has pass STUCK_PENALTY_DELAY, but STUCK_PENALTY_END_TIMESTAMP not zeroed,
    ///         then Operator can receive rewards but can't get new deposits until the new Oracle report or `clearNodeOperatorPenalty` is called.
    uint8 internal constant STUCK_PENALTY_END_TIMESTAMP_OFFSET = 2;

    // Summary SigningKeysStats
    uint8 internal constant SUMMARY_MAX_VALIDATORS_COUNT_OFFSET = 0;
    /// @dev Number of keys in the EXITED state for this operator for all time
    uint8 internal constant SUMMARY_EXITED_KEYS_COUNT_OFFSET = 1;
    /// @dev Total number of keys of this operator for all time
    uint8 internal constant SUMMARY_TOTAL_KEYS_COUNT_OFFSET = 2;
    /// @dev Number of keys of this operator which were in DEPOSITED state for all time
    uint8 internal constant SUMMARY_DEPOSITED_KEYS_COUNT_OFFSET = 3;

    //
    // UNSTRUCTURED STORAGE POSITIONS
    //
    // bytes32 internal constant SIGNING_KEYS_MAPPING_NAME = keccak256("lido.NodeOperatorsRegistry.signingKeysMappingName");
    bytes32 internal constant SIGNING_KEYS_MAPPING_NAME = 0xeb2b7ad4d8ce5610cfb46470f03b14c197c2b751077c70209c5d0139f7c79ee9;

    // bytes32 internal constant LIDO_LOCATOR_POSITION = keccak256("lido.NodeOperatorsRegistry.lidoLocator");
    bytes32 internal constant LIDO_LOCATOR_POSITION = 0xfb2059fd4b64256b64068a0f57046c6d40b9f0e592ba8bcfdf5b941910d03537;

    /// @dev Total number of operators
    // bytes32 internal constant TOTAL_OPERATORS_COUNT_POSITION = keccak256("lido.NodeOperatorsRegistry.totalOperatorsCount");
    bytes32 internal constant TOTAL_OPERATORS_COUNT_POSITION =
        0xe2a589ae0816b289a9d29b7c085f8eba4b5525accca9fa8ff4dba3f5a41287e8;

    /// @dev Cached number of active operators
    // bytes32 internal constant ACTIVE_OPERATORS_COUNT_POSITION = keccak256("lido.NodeOperatorsRegistry.activeOperatorsCount");
    bytes32 internal constant ACTIVE_OPERATORS_COUNT_POSITION =
        0x6f5220989faafdc182d508d697678366f4e831f5f56166ad69bfc253fc548fb1;

    /// @dev link to the index of operations with keys
    // bytes32 internal constant KEYS_OP_INDEX_POSITION = keccak256("lido.NodeOperatorsRegistry.keysOpIndex");
    bytes32 internal constant KEYS_OP_INDEX_POSITION = 0xcd91478ac3f2620f0776eacb9c24123a214bcb23c32ae7d28278aa846c8c380e;

    /// @dev module type
    // bytes32 internal constant TYPE_POSITION = keccak256("lido.NodeOperatorsRegistry.type");
    bytes32 internal constant TYPE_POSITION = 0xbacf4236659a602d72c631ba0b0d67ec320aaf523f3ae3590d7faee4f42351d0;

    // bytes32 internal constant TYPE_POSITION = keccak256("lido.NodeOperatorsRegistry.stuckPenaltyDelay");
    bytes32 internal constant STUCK_PENALTY_DELAY_POSITION = 0x8e3a1f3826a82c1116044b334cae49f3c3d12c3866a1c4b18af461e12e58a18e;

    //
    // DATA TYPES
    //

    /// @dev Node Operator parameters and internal state
    struct NodeOperator {
        /// @dev Flag indicating if the operator can participate in further staking and reward distribution
        bool active;
        /// @dev Ethereum address on Execution Layer which receives stETH rewards for this operator
        address rewardAddress;
        /// @dev Human-readable name
        string name;
        /// @dev The below variables store the signing keys info of the node operator.
        ///     signingKeysStats - contains packed variables: uint64 exitedSigningKeysCount, uint64 depositedSigningKeysCount,
        ///                        uint64 vettedSigningKeysCount, uint64 totalSigningKeysCount
        ///
        ///     These variables can take values in the following ranges:
        ///
        ///                0             <=  exitedSigningKeysCount   <= depositedSigningKeysCount
        ///     exitedSigningKeysCount   <= depositedSigningKeysCount <=  vettedSigningKeysCount
        ///    depositedSigningKeysCount <=   vettedSigningKeysCount  <=   totalSigningKeysCount
        ///    depositedSigningKeysCount <=   totalSigningKeysCount   <=        MAX_UINT64
        ///
        /// Additionally, the exitedSigningKeysCount and depositedSigningKeysCount values are monotonically increasing:
        /// :                              :         :         :         :
        /// [....exitedSigningKeysCount....]-------->:         :         :
        /// [....depositedSigningKeysCount :.........]-------->:         :
        /// [....vettedSigningKeysCount....:.........:<--------]-------->:
        /// [....totalSigningKeysCount.....:.........:<--------:---------]------->
        /// :                              :         :         :         :
        Packed64x4.Packed signingKeysStats;
        Packed64x4.Packed stuckPenaltyStats;
        Packed64x4.Packed targetValidatorsStats;
    }

    struct NodeOperatorSummary {
        Packed64x4.Packed summarySigningKeysStats;
    }

    //
    // STORAGE VARIABLES
    //

    /// @dev Mapping of all node operators. Mapping is used to be able to extend the struct.
    mapping(uint256 => NodeOperator) internal _nodeOperators;
    NodeOperatorSummary internal _nodeOperatorSummary;

    //
    // METHODS
    //
    function initialize(address _locator, bytes32 _type, uint256 _stuckPenaltyDelay) public onlyInit {
        // Initializations for v1 --> v2
        _initialize_v2(_locator, _type, _stuckPenaltyDelay);
        initialized();
    }

    /// @notice A function to finalize upgrade to v2 (from v1). Can be called only once
    /// For more details see https://github.com/lidofinance/lido-improvement-proposals/blob/develop/LIPS/lip-10.md
    function finalizeUpgrade_v2(address _locator, bytes32 _type, uint256 _stuckPenaltyDelay) external {
        require(hasInitialized(), "CONTRACT_NOT_INITIALIZED");
        _checkContractVersion(0);
        _initialize_v2(_locator, _type, _stuckPenaltyDelay);

        uint256 totalOperators = getNodeOperatorsCount();
        Packed64x4.Packed memory signingKeysStats;
        Packed64x4.Packed memory operatorTargetStats;
        Packed64x4.Packed memory summarySigningKeysStats = Packed64x4.Packed(0);
        uint64 vettedSigningKeysCountBefore;
        uint64 totalSigningKeysCount;
        uint64 depositedSigningKeysCount;
        for (uint256 nodeOperatorId; nodeOperatorId < totalOperators; ++nodeOperatorId) {
            signingKeysStats = _loadOperatorSigningKeysStats(nodeOperatorId);
            vettedSigningKeysCountBefore = signingKeysStats.get(TOTAL_VETTED_KEYS_COUNT_OFFSET);
            totalSigningKeysCount = signingKeysStats.get(TOTAL_KEYS_COUNT_OFFSET);
            depositedSigningKeysCount = signingKeysStats.get(TOTAL_DEPOSITED_KEYS_COUNT_OFFSET);

            uint64 vettedSigningKeysCountAfter;
            if (!_nodeOperators[nodeOperatorId].active) {
                // trim vetted signing keys count when node operator is not active
                vettedSigningKeysCountAfter = depositedSigningKeysCount;
            } else {
                vettedSigningKeysCountAfter = uint64(
                    Math256.min(
                        totalSigningKeysCount,
                        Math256.max(uint256(depositedSigningKeysCount), uint256(vettedSigningKeysCountBefore))
                    )
                );
            }

            if (vettedSigningKeysCountBefore != vettedSigningKeysCountAfter) {
                signingKeysStats.set(TOTAL_VETTED_KEYS_COUNT_OFFSET, vettedSigningKeysCountAfter);
                _saveOperatorSigningKeysStats(nodeOperatorId, signingKeysStats);
                emit VettedSigningKeysCountChanged(nodeOperatorId, vettedSigningKeysCountAfter);
            }

            operatorTargetStats = _loadOperatorTargetValidatorsStats(nodeOperatorId);
            operatorTargetStats.set(MAX_VALIDATORS_COUNT_OFFSET, vettedSigningKeysCountAfter);
            _saveOperatorTargetValidatorsStats(nodeOperatorId, operatorTargetStats);

            summarySigningKeysStats.set(
                SUMMARY_MAX_VALIDATORS_COUNT_OFFSET,
                summarySigningKeysStats.get(SUMMARY_MAX_VALIDATORS_COUNT_OFFSET).add(vettedSigningKeysCountAfter)
            );
            summarySigningKeysStats.set(
                SUMMARY_DEPOSITED_KEYS_COUNT_OFFSET,
                summarySigningKeysStats.get(SUMMARY_DEPOSITED_KEYS_COUNT_OFFSET).add(depositedSigningKeysCount)
            );
            summarySigningKeysStats.set(
                SUMMARY_EXITED_KEYS_COUNT_OFFSET,
                summarySigningKeysStats.get(SUMMARY_EXITED_KEYS_COUNT_OFFSET).add(
                    signingKeysStats.get(TOTAL_EXITED_KEYS_COUNT_OFFSET)
                )
            );
            summarySigningKeysStats.set(
                SUMMARY_TOTAL_KEYS_COUNT_OFFSET,
                summarySigningKeysStats.get(SUMMARY_TOTAL_KEYS_COUNT_OFFSET).add(totalSigningKeysCount)
            );
        }

        _saveSummarySigningKeysStats(summarySigningKeysStats);

        _increaseValidatorsKeysNonce();
    }

    function _initialize_v2(address _locator, bytes32 _type, uint256 _stuckPenaltyDelay) internal {
        _onlyNonZeroAddress(_locator);
        LIDO_LOCATOR_POSITION.setStorageAddress(_locator);
        TYPE_POSITION.setStorageBytes32(_type);

        _setContractVersion(2);

        _setStuckPenaltyDelay(_stuckPenaltyDelay);

        // set unlimited allowance for burner from staking router
        // to burn stuck keys penalized shares
        IStETH(getLocator().lido()).approve(getLocator().burner(), ~uint256(0));

        emit LocatorContractSet(_locator);
        emit StakingModuleTypeSet(_type);
    }

    /// @notice Add node operator named `name` with reward address `rewardAddress` and staking limit = 0 validators
    /// @param _name Human-readable name
    /// @param _rewardAddress Ethereum 1 address which receives stETH rewards for this operator
    /// @return id a unique key of the added operator
    function addNodeOperator(string _name, address _rewardAddress) external returns (uint256 id) {
        _onlyValidNodeOperatorName(_name);
        _onlyNonZeroAddress(_rewardAddress);
        _auth(MANAGE_NODE_OPERATOR_ROLE);

        id = getNodeOperatorsCount();
        require(id < MAX_NODE_OPERATORS_COUNT, "MAX_OPERATORS_COUNT_EXCEEDED");

        TOTAL_OPERATORS_COUNT_POSITION.setStorageUint256(id + 1);

        NodeOperator storage operator = _nodeOperators[id];

        uint256 activeOperatorsCount = getActiveNodeOperatorsCount();
        ACTIVE_OPERATORS_COUNT_POSITION.setStorageUint256(activeOperatorsCount + 1);

        operator.active = true;
        operator.name = _name;
        operator.rewardAddress = _rewardAddress;

        emit NodeOperatorAdded(id, _name, _rewardAddress, 0);
    }

    /// @notice Activates deactivated node operator with given id
    /// @param _nodeOperatorId Node operator id to activate
    function activateNodeOperator(uint256 _nodeOperatorId) external {
        _onlyExistedNodeOperator(_nodeOperatorId);
        _auth(MANAGE_NODE_OPERATOR_ROLE);

        _onlyCorrectNodeOperatorState(!getNodeOperatorIsActive(_nodeOperatorId));

        ACTIVE_OPERATORS_COUNT_POSITION.setStorageUint256(getActiveNodeOperatorsCount() + 1);

        _nodeOperators[_nodeOperatorId].active = true;

        emit NodeOperatorActiveSet(_nodeOperatorId, true);
        _increaseValidatorsKeysNonce();
    }

    /// @notice Deactivates active node operator with given id
    /// @param _nodeOperatorId Node operator id to deactivate
    function deactivateNodeOperator(uint256 _nodeOperatorId) external {
        _onlyExistedNodeOperator(_nodeOperatorId);
        _auth(MANAGE_NODE_OPERATOR_ROLE);

        _onlyCorrectNodeOperatorState(getNodeOperatorIsActive(_nodeOperatorId));

        uint256 activeOperatorsCount = getActiveNodeOperatorsCount();
        ACTIVE_OPERATORS_COUNT_POSITION.setStorageUint256(activeOperatorsCount.sub(1));

        _nodeOperators[_nodeOperatorId].active = false;

        emit NodeOperatorActiveSet(_nodeOperatorId, false);

        Packed64x4.Packed memory signingKeysStats = _loadOperatorSigningKeysStats(_nodeOperatorId);
        uint64 vettedSigningKeysCount = signingKeysStats.get(TOTAL_VETTED_KEYS_COUNT_OFFSET);
        uint64 depositedSigningKeysCount = signingKeysStats.get(TOTAL_DEPOSITED_KEYS_COUNT_OFFSET);

        // reset vetted keys count to the deposited validators count
        if (vettedSigningKeysCount > depositedSigningKeysCount) {
            signingKeysStats.set(TOTAL_VETTED_KEYS_COUNT_OFFSET, depositedSigningKeysCount);
            _saveOperatorSigningKeysStats(_nodeOperatorId, signingKeysStats);

            emit VettedSigningKeysCountChanged(_nodeOperatorId, depositedSigningKeysCount);

            _updateSummaryMaxValidatorsCount(_nodeOperatorId);
        }
        _increaseValidatorsKeysNonce();
    }

    /// @notice Change human-readable name of the node operator with given id
    /// @param _nodeOperatorId Node operator id to set name for
    /// @param _name New human-readable name of the node operator
    function setNodeOperatorName(uint256 _nodeOperatorId, string _name) external {
        _onlyValidNodeOperatorName(_name);
        _onlyExistedNodeOperator(_nodeOperatorId);
        _auth(MANAGE_NODE_OPERATOR_ROLE);

        _requireNotSameValue(keccak256(bytes(_nodeOperators[_nodeOperatorId].name)) != keccak256(bytes(_name)));
        _nodeOperators[_nodeOperatorId].name = _name;
        emit NodeOperatorNameSet(_nodeOperatorId, _name);
    }

    /// @notice Change reward address of the node operator with given id
    /// @param _nodeOperatorId Node operator id to set reward address for
    /// @param _rewardAddress Execution layer Ethereum address to set as reward address
    function setNodeOperatorRewardAddress(uint256 _nodeOperatorId, address _rewardAddress) external {
        _onlyNonZeroAddress(_rewardAddress);
        _onlyExistedNodeOperator(_nodeOperatorId);
        _auth(MANAGE_NODE_OPERATOR_ROLE);

        _requireNotSameValue(_nodeOperators[_nodeOperatorId].rewardAddress != _rewardAddress);
        _nodeOperators[_nodeOperatorId].rewardAddress = _rewardAddress;
        emit NodeOperatorRewardAddressSet(_nodeOperatorId, _rewardAddress);
    }

    /// @notice Set the maximum number of validators to stake for the node operator with given id
    /// @dev Current implementation preserves invariant: depositedSigningKeysCount <= vettedSigningKeysCount <= totalSigningKeysCount.
    ///     If _vettedSigningKeysCount out of range [depositedSigningKeysCount, totalSigningKeysCount], the new vettedSigningKeysCount
    ///     value will be set to the nearest range border.
    /// @param _nodeOperatorId Node operator id to set reward address for
    /// @param _vettedSigningKeysCount New staking limit of the node operator
    function setNodeOperatorStakingLimit(uint256 _nodeOperatorId, uint64 _vettedSigningKeysCount) external {
        _onlyExistedNodeOperator(_nodeOperatorId);
        _authP(SET_NODE_OPERATOR_LIMIT_ROLE, arr(uint256(_nodeOperatorId), uint256(_vettedSigningKeysCount)));
        _onlyCorrectNodeOperatorState(getNodeOperatorIsActive(_nodeOperatorId));

        Packed64x4.Packed memory signingKeysStats = _loadOperatorSigningKeysStats(_nodeOperatorId);
        uint64 vettedSigningKeysCountBefore = signingKeysStats.get(TOTAL_VETTED_KEYS_COUNT_OFFSET);
        uint64 depositedSigningKeysCount = signingKeysStats.get(TOTAL_DEPOSITED_KEYS_COUNT_OFFSET);
        uint64 totalSigningKeysCount = signingKeysStats.get(TOTAL_KEYS_COUNT_OFFSET);

        uint64 vettedSigningKeysCountAfter = uint64(
            Math256.min(
                totalSigningKeysCount, Math256.max(uint256(_vettedSigningKeysCount), uint256(depositedSigningKeysCount))
            )
        );

        if (vettedSigningKeysCountAfter == vettedSigningKeysCountBefore) {
            return;
        }

        signingKeysStats.set(TOTAL_VETTED_KEYS_COUNT_OFFSET, vettedSigningKeysCountAfter);
        _saveOperatorSigningKeysStats(_nodeOperatorId, signingKeysStats);

        emit VettedSigningKeysCountChanged(_nodeOperatorId, vettedSigningKeysCountAfter);

        _updateSummaryMaxValidatorsCount(_nodeOperatorId);
        _increaseValidatorsKeysNonce();
    }

    /// @notice Called by StakingRouter to signal that stETH rewards were minted for this module.
    function onRewardsMinted(uint256 /* _totalShares */) external view {
        _auth(STAKING_ROUTER_ROLE);
        // since we're pushing rewards to operators after exited validators counts are
        // updated (as opposed to pulling by node ops), we don't need any handling here
        // see `onExitedAndStuckValidatorsCountsUpdated()`
    }

    function _checkReportPayload(uint256 idsLength, uint256 countsLength) internal pure returns (uint256 count) {
        count = idsLength / 8;
        require(countsLength / 16 == count && idsLength % 8 == 0 && countsLength % 16 == 0, "INVALID_REPORT_DATA");
    }

    /// @notice Called by StakingRouter to update the number of the validators of the given node
    /// operator that were requested to exit but failed to do so in the max allowed time
    ///
    /// @param _nodeOperatorIds bytes packed array of the node operators id
    /// @param _stuckValidatorsCounts bytes packed array of the new number of stuck validators for the node operators
    function updateStuckValidatorsCount(bytes _nodeOperatorIds, bytes _stuckValidatorsCounts) external {
        _auth(STAKING_ROUTER_ROLE);
        uint256 nodeOperatorsCount = _checkReportPayload(_nodeOperatorIds.length, _stuckValidatorsCounts.length);
        uint256 totalNodeOperatorsCount = getNodeOperatorsCount();

        uint256 nodeOperatorId;
        uint64 validatorsCount;
        uint256 _nodeOperatorIdsOffset;
        uint256 _stuckValidatorsCountsOffset;

        /// @dev calldata layout:
        /// | func sig (4 bytes) | ABI-enc data |
        ///
        /// ABI-enc data:
        ///
        /// |    32 bytes    |     32 bytes      |  32 bytes  | ... |  32 bytes  | ...... |
        /// | ids len offset | counts len offset |  ids len   | ids | counts len | counts |
        assembly {
            _nodeOperatorIdsOffset := add(calldataload(4), 36) // arg1 calldata offset + 4 (signature len) + 32 (length slot)
            _stuckValidatorsCountsOffset := add(calldataload(36), 36) // arg2 calldata offset + 4 (signature len) + 32 (length slot))
        }
        for (uint256 i; i < nodeOperatorsCount;) {
            /// @solidity memory-safe-assembly
            assembly {
                nodeOperatorId := shr(192, calldataload(add(_nodeOperatorIdsOffset, mul(i, 8))))
                validatorsCount := shr(128, calldataload(add(_stuckValidatorsCountsOffset, mul(i, 16))))
                i := add(i, 1)
            }
            _requireValidRange(nodeOperatorId < totalNodeOperatorsCount);
            _updateStuckValidatorsCount(nodeOperatorId, validatorsCount);
        }
    }

    /// @notice Called by StakingRouter to update the number of the validators in the EXITED state
    /// for node operator with given id
    ///
    /// @param _nodeOperatorIds bytes packed array of the node operators id
    /// @param _exitedValidatorsCounts bytes packed array of the new number of EXITED validators for the node operators
    function updateExitedValidatorsCount(
        bytes _nodeOperatorIds,
        bytes _exitedValidatorsCounts
    )
        external
    {
        _auth(STAKING_ROUTER_ROLE);
        uint256 nodeOperatorsCount = _checkReportPayload(_nodeOperatorIds.length, _exitedValidatorsCounts.length);
        uint256 totalNodeOperatorsCount = getNodeOperatorsCount();

        uint256 nodeOperatorId;
        uint64 validatorsCount;
        uint256 _nodeOperatorIdsOffset;
        uint256 _exitedValidatorsCountsOffset;
        /// @dev see comments for `updateStuckValidatorsCount`
        assembly {
            _nodeOperatorIdsOffset := add(calldataload(4), 36) // arg1 calldata offset + 4 (signature len) + 32 (length slot)
            _exitedValidatorsCountsOffset := add(calldataload(36), 36) // arg2 calldata offset + 4 (signature len) + 32 (length slot))
        }
        for (uint256 i; i < nodeOperatorsCount;) {
            /// @solidity memory-safe-assembly
            assembly {
                nodeOperatorId := shr(192, calldataload(add(_nodeOperatorIdsOffset, mul(i, 8))))
                validatorsCount := shr(128, calldataload(add(_exitedValidatorsCountsOffset, mul(i, 16))))
                i := add(i, 1)
            }
            _requireValidRange(nodeOperatorId < totalNodeOperatorsCount);
            _updateExitedValidatorsCount(nodeOperatorId, validatorsCount, false);
        }
    }

    /// @notice Updates the number of the refunded validators for node operator with the given id
    /// @param _nodeOperatorId Id of the node operator
    /// @param _refundedValidatorsCount New number of refunded validators of the node operator
    function updateRefundedValidatorsCount(uint256 _nodeOperatorId, uint256 _refundedValidatorsCount) external {
        _onlyExistedNodeOperator(_nodeOperatorId);
        _auth(STAKING_ROUTER_ROLE);

        _updateRefundValidatorsKeysCount(_nodeOperatorId, uint64(_refundedValidatorsCount));
    }

    /// @notice Called by StakingRouter after it finishes updating exited and stuck validators
    /// counts for this module's node operators.
    ///
    /// Guaranteed to be called after an oracle report is applied, regardless of whether any node
    /// operator in this module has actually received any updated counts as a result of the report
    /// but given that the total number of exited validators returned from getStakingModuleSummary
    /// is the same as StakingRouter expects based on the total count received from the oracle.
    function onExitedAndStuckValidatorsCountsUpdated() external {
        _auth(STAKING_ROUTER_ROLE);
        // for the permissioned module, we're distributing rewards within oracle operation
        // since the number of node ops won't be high and thus gas costs are limited
        _distributeRewards();
    }

    /// @notice Unsafely updates the number of validators in the EXITED/STUCK states for node operator with given id
    ///      'unsafely' means that this method can both increase and decrease exited and stuck counters
    /// @param _nodeOperatorId Id of the node operator
    /// @param _exitedValidatorsCount New number of EXITED validators for the node operator
    /// @param _stuckValidatorsCount New number of STUCK validator for the node operator
    function unsafeUpdateValidatorsCount(
        uint256 _nodeOperatorId,
        uint256 _exitedValidatorsCount,
        uint256 _stuckValidatorsCount
    ) external {
        _onlyExistedNodeOperator(_nodeOperatorId);
        _auth(STAKING_ROUTER_ROLE);

        _updateExitedValidatorsCount(_nodeOperatorId, uint64(_exitedValidatorsCount), true /* _allowDecrease */ );
        _updateStuckValidatorsCount(_nodeOperatorId, uint64(_stuckValidatorsCount));
    }

    function _updateExitedValidatorsCount(uint256 _nodeOperatorId, uint64 _exitedValidatorsKeysCount, bool _allowDecrease)
        internal
    {
        Packed64x4.Packed memory signingKeysStats = _loadOperatorSigningKeysStats(_nodeOperatorId);
        int64 totalExitedValidatorsDelta =
            int64(_exitedValidatorsKeysCount) - int64(signingKeysStats.get(TOTAL_EXITED_KEYS_COUNT_OFFSET));

        if (totalExitedValidatorsDelta != 0) {
            _requireValidRange(_exitedValidatorsKeysCount <= signingKeysStats.get(TOTAL_DEPOSITED_KEYS_COUNT_OFFSET));
            if (totalExitedValidatorsDelta < 0 && !_allowDecrease) {
                revert("EXITED_VALIDATORS_COUNT_DECREASED");
            }

            signingKeysStats.set(TOTAL_EXITED_KEYS_COUNT_OFFSET, _exitedValidatorsKeysCount);
            _saveOperatorSigningKeysStats(_nodeOperatorId, signingKeysStats);
            emit ExitedSigningKeysCountChanged(_nodeOperatorId, _exitedValidatorsKeysCount);

            // upd totals
            Packed64x4.Packed memory summarySigningKeysStats = _loadSummarySigningKeysStats();
            summarySigningKeysStats.set(
                SUMMARY_EXITED_KEYS_COUNT_OFFSET,
                uint64(int64(summarySigningKeysStats.get(SUMMARY_EXITED_KEYS_COUNT_OFFSET)) + totalExitedValidatorsDelta)
            );
            _saveSummarySigningKeysStats(summarySigningKeysStats);

            _updateSummaryMaxValidatorsCount(_nodeOperatorId);
        }
    }

    /// @notice Updates the limit of the validators that can be used for deposit by DAO
    /// @param _nodeOperatorId Id of the node operator
    /// @param _targetLimit Target limit of the node operator
    /// @param _isTargetLimitActive active flag
    function updateTargetValidatorsLimits(uint256 _nodeOperatorId, bool _isTargetLimitActive, uint256 _targetLimit) external {
        _onlyExistedNodeOperator(_nodeOperatorId);
        _auth(STAKING_ROUTER_ROLE);
        _requireValidRange(_targetLimit <= UINT64_MAX);

        Packed64x4.Packed memory operatorTargetStats = _loadOperatorTargetValidatorsStats(_nodeOperatorId);
        operatorTargetStats.set(IS_TARGET_LIMIT_ACTIVE_OFFSET, _isTargetLimitActive ? 1 : 0);
        operatorTargetStats.set(TARGET_VALIDATORS_COUNT_OFFSET, _isTargetLimitActive ? uint64(_targetLimit) : 0);
        _saveOperatorTargetValidatorsStats(_nodeOperatorId, operatorTargetStats);

        emit TargetValidatorsCountChanged(_nodeOperatorId, _targetLimit);

        _updateSummaryMaxValidatorsCount(_nodeOperatorId);
    }

    /**
     * @notice Set the stuck signings keys count
     */
    function _updateStuckValidatorsCount(uint256 _nodeOperatorId, uint64 _stuckValidatorsCount) internal {
        Packed64x4.Packed memory stuckPenaltyStats = _loadOperatorStuckPenaltyStats(_nodeOperatorId);
        uint64 curStuckValidatorsCount = stuckPenaltyStats.get(STUCK_VALIDATORS_COUNT_OFFSET);
        if (_stuckValidatorsCount == curStuckValidatorsCount) return;

        Packed64x4.Packed memory signingKeysStats = _loadOperatorSigningKeysStats(_nodeOperatorId);
        _requireValidRange(
            _stuckValidatorsCount
                <= signingKeysStats.get(TOTAL_DEPOSITED_KEYS_COUNT_OFFSET) - signingKeysStats.get(TOTAL_EXITED_KEYS_COUNT_OFFSET)
        );

        uint64 curRefundedValidatorsCount = stuckPenaltyStats.get(REFUNDED_VALIDATORS_COUNT_OFFSET);
        if (_stuckValidatorsCount <= curRefundedValidatorsCount && curStuckValidatorsCount > curRefundedValidatorsCount) {
            stuckPenaltyStats.set(STUCK_PENALTY_END_TIMESTAMP_OFFSET, uint64(block.timestamp + getStuckPenaltyDelay()));
        }

        stuckPenaltyStats.set(STUCK_VALIDATORS_COUNT_OFFSET, _stuckValidatorsCount);
        _saveOperatorStuckPenaltyStats(_nodeOperatorId, stuckPenaltyStats);
        emit StuckPenaltyStateChanged(
            _nodeOperatorId,
            _stuckValidatorsCount,
            curRefundedValidatorsCount,
            stuckPenaltyStats.get(STUCK_PENALTY_END_TIMESTAMP_OFFSET)
            );

        _updateSummaryMaxValidatorsCount(_nodeOperatorId);
    }

    function _updateRefundValidatorsKeysCount(uint256 _nodeOperatorId, uint64 _refundedValidatorsCount) internal {
        Packed64x4.Packed memory stuckPenaltyStats = _loadOperatorStuckPenaltyStats(_nodeOperatorId);
        uint64 curRefundedValidatorsCount = stuckPenaltyStats.get(REFUNDED_VALIDATORS_COUNT_OFFSET);
        if (_refundedValidatorsCount == curRefundedValidatorsCount) return;

        Packed64x4.Packed memory signingKeysStats = _loadOperatorSigningKeysStats(_nodeOperatorId);
        _requireValidRange(_refundedValidatorsCount <= signingKeysStats.get(TOTAL_DEPOSITED_KEYS_COUNT_OFFSET));

        uint64 curStuckValidatorsCount = stuckPenaltyStats.get(STUCK_VALIDATORS_COUNT_OFFSET);
        if (_refundedValidatorsCount >= curStuckValidatorsCount && curRefundedValidatorsCount < curStuckValidatorsCount) {
            stuckPenaltyStats.set(STUCK_PENALTY_END_TIMESTAMP_OFFSET, uint64(block.timestamp + getStuckPenaltyDelay()));
        }

        stuckPenaltyStats.set(REFUNDED_VALIDATORS_COUNT_OFFSET, _refundedValidatorsCount);
        _saveOperatorStuckPenaltyStats(_nodeOperatorId, stuckPenaltyStats);
        emit StuckPenaltyStateChanged(
            _nodeOperatorId,
            curStuckValidatorsCount,
            _refundedValidatorsCount,
            stuckPenaltyStats.get(STUCK_PENALTY_END_TIMESTAMP_OFFSET)
            );
        _updateSummaryMaxValidatorsCount(_nodeOperatorId);
    }

    // @dev Recalculate and update the max validator count for operator and summary stats
    function _updateSummaryMaxValidatorsCount(uint256 _nodeOperatorId) internal returns (int64 maxSigningKeysDelta) {
        maxSigningKeysDelta = _applyNodeOperatorLimits(_nodeOperatorId);
        if (maxSigningKeysDelta != 0) {
            Packed64x4.Packed memory summarySigningKeysStats = _loadSummarySigningKeysStats();

            summarySigningKeysStats.set(
                SUMMARY_MAX_VALIDATORS_COUNT_OFFSET,
                uint64(int64(summarySigningKeysStats.get(SUMMARY_MAX_VALIDATORS_COUNT_OFFSET)) + maxSigningKeysDelta)
            );
            _saveSummarySigningKeysStats(summarySigningKeysStats);
        }
    }

    /// @notice Invalidates all unused deposit data for all node operators
    function onWithdrawalCredentialsChanged() external {
        _auth(STAKING_ROUTER_ROLE);
        uint256 operatorsCount = getNodeOperatorsCount();
        if (operatorsCount > 0) {
            _invalidateReadyToDepositKeysRange(0, operatorsCount - 1);
        }
    }

    /// @notice Invalidates all unused validators keys for node operators in the given range
    /// @param _indexFrom the first index (inclusive) of the node operator to invalidate keys for
    /// @param _indexTo the last index (inclusive) of the node operator to invalidate keys for
    function invalidateReadyToDepositKeysRange(uint256 _indexFrom, uint256 _indexTo) external {
        _auth(MANAGE_NODE_OPERATOR_ROLE);
        _invalidateReadyToDepositKeysRange(_indexFrom, _indexTo);
    }

    function _invalidateReadyToDepositKeysRange(uint256 _indexFrom, uint256 _indexTo) internal {
        _requireValidRange(_indexFrom <= _indexTo && _indexTo < getNodeOperatorsCount());

        uint64 trimmedKeysCount;
        uint64 totalTrimmedKeysCount;
        Packed64x4.Packed memory signingKeysStats;

        for (uint256 nodeOperatorId = _indexFrom; nodeOperatorId <= _indexTo; ++nodeOperatorId) {
            signingKeysStats = _loadOperatorSigningKeysStats(nodeOperatorId);

            uint64 depositedSigningKeysCount = signingKeysStats.get(TOTAL_DEPOSITED_KEYS_COUNT_OFFSET);
            trimmedKeysCount = signingKeysStats.get(TOTAL_KEYS_COUNT_OFFSET) - depositedSigningKeysCount;
            if (trimmedKeysCount == 0) continue;
            totalTrimmedKeysCount += trimmedKeysCount;

            signingKeysStats.set(TOTAL_KEYS_COUNT_OFFSET, depositedSigningKeysCount);
            signingKeysStats.set(TOTAL_VETTED_KEYS_COUNT_OFFSET, depositedSigningKeysCount);
            _saveOperatorSigningKeysStats(nodeOperatorId, signingKeysStats);

            _updateSummaryMaxValidatorsCount(nodeOperatorId);

            emit TotalSigningKeysCountChanged(nodeOperatorId, depositedSigningKeysCount);
            emit VettedSigningKeysCountChanged(nodeOperatorId, depositedSigningKeysCount);
            emit NodeOperatorTotalKeysTrimmed(nodeOperatorId, trimmedKeysCount);
        }

        if (totalTrimmedKeysCount > 0) {
            Packed64x4.Packed memory summarySigningKeysStats = _loadSummarySigningKeysStats();
            summarySigningKeysStats.set(
                SUMMARY_TOTAL_KEYS_COUNT_OFFSET,
                summarySigningKeysStats.get(SUMMARY_TOTAL_KEYS_COUNT_OFFSET) - totalTrimmedKeysCount
            );
            _saveSummarySigningKeysStats(summarySigningKeysStats);
            _increaseValidatorsKeysNonce();
        }
    }

    /// @notice Obtains deposit data to be used by StakingRouter to deposit to the Ethereum Deposit
    ///     contract
    /// @param _depositsCount Number of deposits to be done
    /// @return publicKeys Batch of the concatenated public validators keys
    /// @return signatures Batch of the concatenated deposit signatures for returned public keys
    function obtainDepositData(
        uint256 _depositsCount,
        bytes /* _depositCalldata */
    ) external returns (bytes memory publicKeys, bytes memory signatures) {
        _auth(STAKING_ROUTER_ROLE);

        if (_depositsCount == 0) return (new bytes(0), new bytes(0));

        (
            uint256 allocatedKeysCount,
            uint256[] memory nodeOperatorIds,
            uint256[] memory activeKeysCountAfterAllocation
        ) = _getSigningKeysAllocationData(_depositsCount);

        require(allocatedKeysCount == _depositsCount, "INVALID_ALLOCATED_KEYS_COUNT");

        (publicKeys, signatures) = _loadAllocatedSigningKeys(
            allocatedKeysCount,
            nodeOperatorIds,
            activeKeysCountAfterAllocation
        );
        _increaseValidatorsKeysNonce();
    }

    function _getNodeOperator(uint256 _nodeOperatorId)
        internal
        view
        returns (uint64 maxSigningKeysCount, uint64 exitedSigningKeysCount, uint64 depositedSigningKeysCount)
    {
        Packed64x4.Packed memory signingKeysStats = _loadOperatorSigningKeysStats(_nodeOperatorId);
        Packed64x4.Packed memory operatorTargetStats = _loadOperatorTargetValidatorsStats(_nodeOperatorId);

        exitedSigningKeysCount = signingKeysStats.get(TOTAL_EXITED_KEYS_COUNT_OFFSET);
        depositedSigningKeysCount = signingKeysStats.get(TOTAL_DEPOSITED_KEYS_COUNT_OFFSET);
        maxSigningKeysCount = operatorTargetStats.get(MAX_VALIDATORS_COUNT_OFFSET);
    }

    function _applyNodeOperatorLimits(uint256 _nodeOperatorId) internal returns (int64 maxSigningKeysDelta) {
        Packed64x4.Packed memory signingKeysStats = _loadOperatorSigningKeysStats(_nodeOperatorId);
        Packed64x4.Packed memory operatorTargetStats = _loadOperatorTargetValidatorsStats(_nodeOperatorId);

        uint64 exitedSigningKeysCount = signingKeysStats.get(TOTAL_EXITED_KEYS_COUNT_OFFSET);
        uint64 depositedSigningKeysCount = signingKeysStats.get(TOTAL_DEPOSITED_KEYS_COUNT_OFFSET);
        uint64 vettedSigningKeysCount = signingKeysStats.get(TOTAL_VETTED_KEYS_COUNT_OFFSET);

        uint64 oldMaxSigningKeysCount = operatorTargetStats.get(MAX_VALIDATORS_COUNT_OFFSET);
        uint64 newMaxSigningKeysCount = depositedSigningKeysCount;

        if (isOperatorPenaltyCleared(_nodeOperatorId)) {
            if (operatorTargetStats.get(IS_TARGET_LIMIT_ACTIVE_OFFSET) == 0) {
                newMaxSigningKeysCount = vettedSigningKeysCount;
            } else {
                // correct max count according to target if target is enabled
                // targetLimit is limited to UINT64_MAX
                uint256 targetLimit = Math256.min(uint256(exitedSigningKeysCount).add(operatorTargetStats.get(TARGET_VALIDATORS_COUNT_OFFSET)), UINT64_MAX);
                if (targetLimit > depositedSigningKeysCount) {
                    newMaxSigningKeysCount = uint64(Math256.min(vettedSigningKeysCount, targetLimit));
                }
            }
        } // else newMaxSigningKeysCount = depositedSigningKeysCount, so depositable keys count = 0

        if (oldMaxSigningKeysCount != newMaxSigningKeysCount) {
            operatorTargetStats.set(MAX_VALIDATORS_COUNT_OFFSET, newMaxSigningKeysCount);
            _saveOperatorTargetValidatorsStats(_nodeOperatorId, operatorTargetStats);
            maxSigningKeysDelta = int64(newMaxSigningKeysCount) - int64(oldMaxSigningKeysCount);
        }
    }

    function _getSigningKeysAllocationData(uint256 _keysCount)
        internal
        view
        returns (uint256 allocatedKeysCount, uint256[] memory nodeOperatorIds, uint256[] memory activeKeyCountsAfterAllocation)
    {
        uint256 activeNodeOperatorsCount = getActiveNodeOperatorsCount();
        nodeOperatorIds = new uint256[](activeNodeOperatorsCount);
        activeKeyCountsAfterAllocation = new uint256[](activeNodeOperatorsCount);
        uint256[] memory activeKeysCapacities = new uint256[](activeNodeOperatorsCount);

        uint256 activeNodeOperatorIndex;
        uint256 nodeOperatorsCount = getNodeOperatorsCount();
        uint256 maxSigningKeysCount;
        uint256 depositedSigningKeysCount;
        uint256 exitedSigningKeysCount;

        for (uint256 nodeOperatorId; nodeOperatorId < nodeOperatorsCount; ++nodeOperatorId) {
            (maxSigningKeysCount, exitedSigningKeysCount, depositedSigningKeysCount) = _getNodeOperator(nodeOperatorId);

            // the node operator has no available signing keys
            if (depositedSigningKeysCount == maxSigningKeysCount) continue;

            nodeOperatorIds[activeNodeOperatorIndex] = nodeOperatorId;
            activeKeyCountsAfterAllocation[activeNodeOperatorIndex] = depositedSigningKeysCount - exitedSigningKeysCount;
            activeKeysCapacities[activeNodeOperatorIndex] = maxSigningKeysCount - exitedSigningKeysCount;
            ++activeNodeOperatorIndex;
        }

        if (activeNodeOperatorIndex == 0) return (0, new uint256[](0), new uint256[](0));

        /// @dev shrink the length of the resulting arrays if some active node operators have no available keys to be deposited
        if (activeNodeOperatorIndex < activeNodeOperatorsCount) {
            assembly {
                mstore(nodeOperatorIds, activeNodeOperatorIndex)
                mstore(activeKeyCountsAfterAllocation, activeNodeOperatorIndex)
                mstore(activeKeysCapacities, activeNodeOperatorIndex)
            }
        }

        allocatedKeysCount =
            MinFirstAllocationStrategy.allocate(activeKeyCountsAfterAllocation, activeKeysCapacities, uint64(_keysCount));

        /// @dev method NEVER allocates more keys than was requested
        assert(allocatedKeysCount <= _keysCount);
    }

    function _loadAllocatedSigningKeys(
        uint256 _keysCountToLoad,
        uint256[] memory _nodeOperatorIds,
        uint256[] memory _activeKeyCountsAfterAllocation
    ) internal returns (bytes memory pubkeys, bytes memory signatures) {
        (pubkeys, signatures) = SigningKeys.initKeysSigsBuf(_keysCountToLoad);

        uint256 loadedKeysCount = 0;
        uint64 depositedSigningKeysCountBefore;
        uint64 depositedSigningKeysCountAfter;
        uint256 keysCount;
        Packed64x4.Packed memory signingKeysStats;
        for (uint256 i; i < _nodeOperatorIds.length; ++i) {
            signingKeysStats = _loadOperatorSigningKeysStats(_nodeOperatorIds[i]);
            depositedSigningKeysCountBefore = signingKeysStats.get(TOTAL_DEPOSITED_KEYS_COUNT_OFFSET);
            depositedSigningKeysCountAfter =
                signingKeysStats.get(TOTAL_EXITED_KEYS_COUNT_OFFSET) + uint64(_activeKeyCountsAfterAllocation[i]);

            keysCount = depositedSigningKeysCountAfter.sub(depositedSigningKeysCountBefore);
            if (keysCount == 0) continue;

            SIGNING_KEYS_MAPPING_NAME.loadKeysSigs(
                _nodeOperatorIds[i], depositedSigningKeysCountBefore, keysCount, pubkeys, signatures, loadedKeysCount
            );
            loadedKeysCount += keysCount;

            emit DepositedSigningKeysCountChanged(_nodeOperatorIds[i], depositedSigningKeysCountAfter);
            signingKeysStats.set(TOTAL_DEPOSITED_KEYS_COUNT_OFFSET, depositedSigningKeysCountAfter);
            _saveOperatorSigningKeysStats(_nodeOperatorIds[i], signingKeysStats);
            _updateSummaryMaxValidatorsCount(_nodeOperatorIds[i]);
        }

        assert(loadedKeysCount == _keysCountToLoad);

        Packed64x4.Packed memory summarySigningKeysStats = _loadSummarySigningKeysStats();
        summarySigningKeysStats.set(
            SUMMARY_DEPOSITED_KEYS_COUNT_OFFSET,
            summarySigningKeysStats.get(SUMMARY_DEPOSITED_KEYS_COUNT_OFFSET).add(uint64(loadedKeysCount))
        );
        _saveSummarySigningKeysStats(summarySigningKeysStats);
    }

    /// @notice Returns the node operator by id
    /// @param _nodeOperatorId Node Operator id
    /// @param _fullInfo If true, name will be returned as well
    function getNodeOperator(uint256 _nodeOperatorId, bool _fullInfo)
        external
        view
        returns (
            bool active,
            string name,
            address rewardAddress,
            uint64 stakingLimit,
            uint64 stoppedValidators,
            uint64 totalSigningKeys,
            uint64 usedSigningKeys
        )
    {
        _onlyExistedNodeOperator(_nodeOperatorId);

        NodeOperator storage nodeOperator = _nodeOperators[_nodeOperatorId];

        active = nodeOperator.active;
        rewardAddress = nodeOperator.rewardAddress;
        name = _fullInfo ? nodeOperator.name : ""; // reading name is 2+ SLOADs

        Packed64x4.Packed memory signingKeysStats = _loadOperatorSigningKeysStats(_nodeOperatorId);

        stakingLimit = signingKeysStats.get(TOTAL_VETTED_KEYS_COUNT_OFFSET);
        stoppedValidators = signingKeysStats.get(TOTAL_EXITED_KEYS_COUNT_OFFSET);
        totalSigningKeys = signingKeysStats.get(TOTAL_KEYS_COUNT_OFFSET);
        usedSigningKeys = signingKeysStats.get(TOTAL_DEPOSITED_KEYS_COUNT_OFFSET);
    }

    /// @notice Returns the rewards distribution proportional to the effective stake for each node operator.
    /// @param _totalRewardShares Total amount of reward shares to distribute.
    function getRewardsDistribution(uint256 _totalRewardShares)
        public
        view
        returns (address[] memory recipients, uint256[] memory shares, bool[] memory penalized)
    {
        uint256 nodeOperatorCount = getNodeOperatorsCount();

        uint256 activeCount = getActiveNodeOperatorsCount();
        recipients = new address[](activeCount);
        shares = new uint256[](activeCount);
        penalized = new bool[](activeCount);
        uint256 idx = 0;

        uint256 totalActiveValidatorsCount = 0;
        for (uint256 operatorId; operatorId < nodeOperatorCount; ++operatorId) {
            if (!getNodeOperatorIsActive(operatorId)) continue;

            Packed64x4.Packed memory signingKeysStats = _loadOperatorSigningKeysStats(operatorId);
            uint256 activeValidatorsCount =
                signingKeysStats.get(TOTAL_DEPOSITED_KEYS_COUNT_OFFSET) - signingKeysStats.get(TOTAL_EXITED_KEYS_COUNT_OFFSET);
            totalActiveValidatorsCount = totalActiveValidatorsCount.add(activeValidatorsCount);

            recipients[idx] = _nodeOperators[operatorId].rewardAddress;
            // prefill shares array with 'key share' for recipient, see below
            shares[idx] = activeValidatorsCount;
            penalized[idx] = isOperatorPenalized(operatorId);

            ++idx;
        }

        if (totalActiveValidatorsCount == 0) return (recipients, shares, penalized);

        for (idx = 0; idx < activeCount; ++idx) {
            /// @dev unsafe division used below for gas savings. It's safe in the current case
            ///     because SafeMath.div() only validates that the divider isn't equal to zero.
            ///     totalActiveValidatorsCount guaranteed greater than zero.
            shares[idx] = shares[idx].mul(_totalRewardShares) / totalActiveValidatorsCount;
        }

        return (recipients, shares, penalized);
    }

    /// @notice Add `_quantity` validator signing keys to the keys of the node operator #`_nodeOperatorId`. Concatenated keys are: `_pubkeys`
    /// @dev Along with each key the DAO has to provide a signatures for the
    ///      (pubkey, withdrawal_credentials, 32000000000) message.
    ///      Given that information, the contract'll be able to call
    ///      deposit_contract.deposit on-chain.
    /// @param _nodeOperatorId Node Operator id
    /// @param _keysCount Number of signing keys provided
    /// @param _publicKeys Several concatenated validator signing keys
    /// @param _signatures Several concatenated signatures for (pubkey, withdrawal_credentials, 32000000000) messages
    function addSigningKeys(uint256 _nodeOperatorId, uint256 _keysCount, bytes _publicKeys, bytes _signatures) external {
        _addSigningKeys(_nodeOperatorId, _keysCount, _publicKeys, _signatures);
    }

    /// @notice Add `_quantity` validator signing keys of operator #`_id` to the set of usable keys. Concatenated keys are: `_pubkeys`. Can be done by node operator in question by using the designated rewards address.
    /// @dev Along with each key the DAO has to provide a signatures for the
    ///      (pubkey, withdrawal_credentials, 32000000000) message.
    ///      Given that information, the contract'll be able to call
    ///      deposit_contract.deposit on-chain.
    /// @param _nodeOperatorId Node Operator id
    /// @param _keysCount Number of signing keys provided
    /// @param _publicKeys Several concatenated validator signing keys
    /// @param _signatures Several concatenated signatures for (pubkey, withdrawal_credentials, 32000000000) messages
    /// @dev DEPRECATED use addSigningKeys instead
    function addSigningKeysOperatorBH(uint256 _nodeOperatorId, uint256 _keysCount, bytes _publicKeys, bytes _signatures)
        external
    {
        _addSigningKeys(_nodeOperatorId, _keysCount, _publicKeys, _signatures);
    }

    function _addSigningKeys(uint256 _nodeOperatorId, uint256 _keysCount, bytes _publicKeys, bytes _signatures) internal {
        _onlyExistedNodeOperator(_nodeOperatorId);
        _onlyNodeOperatorManager(msg.sender, _nodeOperatorId);

        _requireValidRange(_keysCount != 0 && _keysCount <= UINT64_MAX);

        Packed64x4.Packed memory signingKeysStats = _loadOperatorSigningKeysStats(_nodeOperatorId);
        uint256 totalSigningKeysCount = signingKeysStats.get(TOTAL_KEYS_COUNT_OFFSET);

        _requireValidRange(totalSigningKeysCount.add(_keysCount) <= UINT64_MAX);

        totalSigningKeysCount =
            SIGNING_KEYS_MAPPING_NAME.saveKeysSigs(_nodeOperatorId, totalSigningKeysCount, _keysCount, _publicKeys, _signatures);

        emit TotalSigningKeysCountChanged(_nodeOperatorId, totalSigningKeysCount);

        signingKeysStats.set(TOTAL_KEYS_COUNT_OFFSET, uint64(totalSigningKeysCount));
        _saveOperatorSigningKeysStats(_nodeOperatorId, signingKeysStats);

        // upd totals
        Packed64x4.Packed memory summarySigningKeysStats = _loadSummarySigningKeysStats();
        summarySigningKeysStats.set(
            SUMMARY_TOTAL_KEYS_COUNT_OFFSET, summarySigningKeysStats.get(SUMMARY_TOTAL_KEYS_COUNT_OFFSET).add(uint64(_keysCount))
        );
        _saveSummarySigningKeysStats(summarySigningKeysStats);

        _increaseValidatorsKeysNonce();
    }

    /// @notice Removes a validator signing key #`_index` from the keys of the node operator #`_nodeOperatorId`
    /// @param _nodeOperatorId Node Operator id
    /// @param _index Index of the key, starting with 0
    /// @dev DEPRECATED use removeSigningKeys instead
    function removeSigningKey(uint256 _nodeOperatorId, uint256 _index) external {
        _removeUnusedSigningKeys(_nodeOperatorId, _index, 1);
    }

    /// @notice Removes an #`_keysCount` of validator signing keys starting from #`_index` of operator #`_id` usable keys. Executed on behalf of DAO.
    /// @param _nodeOperatorId Node Operator id
    /// @param _fromIndex Index of the key, starting with 0
    /// @param _keysCount Number of keys to remove
    function removeSigningKeys(uint256 _nodeOperatorId, uint256 _fromIndex, uint256 _keysCount) external {
        _removeUnusedSigningKeys(_nodeOperatorId, _fromIndex, _keysCount);
    }

    /// @notice Removes a validator signing key #`_index` of operator #`_id` from the set of usable keys. Executed on behalf of Node Operator.
    /// @param _nodeOperatorId Node Operator id
    /// @param _index Index of the key, starting with 0
    /// @dev DEPRECATED use removeSigningKeys instead
    function removeSigningKeyOperatorBH(uint256 _nodeOperatorId, uint256 _index) external {
        _removeUnusedSigningKeys(_nodeOperatorId, _index, 1);
    }

    /// @notice Removes an #`_keysCount` of validator signing keys starting from #`_index` of operator #`_id` usable keys. Executed on behalf of Node Operator.
    /// @param _nodeOperatorId Node Operator id
    /// @param _fromIndex Index of the key, starting with 0
    /// @param _keysCount Number of keys to remove
    /// @dev DEPRECATED use removeSigningKeys instead
    function removeSigningKeysOperatorBH(uint256 _nodeOperatorId, uint256 _fromIndex, uint256 _keysCount) external {
        _removeUnusedSigningKeys(_nodeOperatorId, _fromIndex, _keysCount);
    }

    function _removeUnusedSigningKeys(uint256 _nodeOperatorId, uint256 _fromIndex, uint256 _keysCount) internal {
        _onlyExistedNodeOperator(_nodeOperatorId);
        _onlyNodeOperatorManager(msg.sender, _nodeOperatorId);

        // preserve the previous behavior of the method here and just return earlier
        if (_keysCount == 0) return;

        Packed64x4.Packed memory signingKeysStats = _loadOperatorSigningKeysStats(_nodeOperatorId);
        uint256 totalSigningKeysCount = signingKeysStats.get(TOTAL_KEYS_COUNT_OFFSET);
        // comapring _fromIndex.add(_keysCount) <= totalSigningKeysCount is enough as totalSigningKeysCount is always less than MAX_UINT64
        _requireValidRange(_fromIndex >= signingKeysStats.get(TOTAL_DEPOSITED_KEYS_COUNT_OFFSET) && _fromIndex.add(_keysCount) <= totalSigningKeysCount);

        totalSigningKeysCount =
            SIGNING_KEYS_MAPPING_NAME.removeKeysSigs(_nodeOperatorId, _fromIndex, _keysCount, totalSigningKeysCount);
        signingKeysStats.set(TOTAL_KEYS_COUNT_OFFSET, uint64(totalSigningKeysCount));
        emit TotalSigningKeysCountChanged(_nodeOperatorId, totalSigningKeysCount);

        uint64 vettedSigningKeysCount = signingKeysStats.get(TOTAL_VETTED_KEYS_COUNT_OFFSET);
        if (_fromIndex < vettedSigningKeysCount) {
            // decreasing the staking limit so the key at _index can't be used anymore
            signingKeysStats.set(TOTAL_VETTED_KEYS_COUNT_OFFSET, uint64(_fromIndex));
            emit VettedSigningKeysCountChanged(_nodeOperatorId, _fromIndex);
        }
        _saveOperatorSigningKeysStats(_nodeOperatorId, signingKeysStats);

        // upd totals
        Packed64x4.Packed memory summarySigningKeysStats = _loadSummarySigningKeysStats();
        summarySigningKeysStats.set(
            SUMMARY_TOTAL_KEYS_COUNT_OFFSET,
            summarySigningKeysStats.get(SUMMARY_TOTAL_KEYS_COUNT_OFFSET).sub(uint64(_keysCount))
        );
        _saveSummarySigningKeysStats(summarySigningKeysStats);
        _updateSummaryMaxValidatorsCount(_nodeOperatorId);

        _increaseValidatorsKeysNonce();
    }

    /// @notice Returns total number of signing keys of the node operator #`_nodeOperatorId`
    function getTotalSigningKeyCount(uint256 _nodeOperatorId) external view returns (uint256) {
        _onlyExistedNodeOperator(_nodeOperatorId);
        Packed64x4.Packed memory signingKeysStats = _loadOperatorSigningKeysStats(_nodeOperatorId);
        return signingKeysStats.get(TOTAL_KEYS_COUNT_OFFSET);
    }

    /// @notice Returns number of usable signing keys of the node operator #`_nodeOperatorId`
    function getUnusedSigningKeyCount(uint256 _nodeOperatorId) external view returns (uint256) {
        _onlyExistedNodeOperator(_nodeOperatorId);

        Packed64x4.Packed memory signingKeysStats = _loadOperatorSigningKeysStats(_nodeOperatorId);
        return signingKeysStats.get(TOTAL_KEYS_COUNT_OFFSET) - signingKeysStats.get(TOTAL_DEPOSITED_KEYS_COUNT_OFFSET);
    }

    /// @notice Returns n-th signing key of the node operator #`_nodeOperatorId`
    /// @param _nodeOperatorId Node Operator id
    /// @param _index Index of the key, starting with 0
    /// @return key Key
    /// @return depositSignature Signature needed for a deposit_contract.deposit call
    /// @return used Flag indication if the key was used in the staking
    function getSigningKey(uint256 _nodeOperatorId, uint256 _index)
        external
        view
        returns (bytes key, bytes depositSignature, bool used)
    {
        bool[] memory keyUses;
        (key, depositSignature, keyUses) = getSigningKeys(_nodeOperatorId, _index, 1);
        used = keyUses[0];
    }

    /// @notice Returns n signing keys of the node operator #`_nodeOperatorId`
    /// @param _nodeOperatorId Node Operator id
    /// @param _offset Offset of the key, starting with 0
    /// @param _limit Number of keys to return
    /// @return pubkeys Keys concatenated into the bytes batch
    /// @return signatures Signatures concatenated into the bytes batch needed for a deposit_contract.deposit call
    /// @return used Array of flags indicated if the key was used in the staking
    function getSigningKeys(uint256 _nodeOperatorId, uint256 _offset, uint256 _limit)
        public
        view
        returns (bytes memory pubkeys, bytes memory signatures, bool[] memory used)
    {
        _onlyExistedNodeOperator(_nodeOperatorId);

        Packed64x4.Packed memory signingKeysStats = _loadOperatorSigningKeysStats(_nodeOperatorId);
        _requireValidRange(_offset.add(_limit) <= signingKeysStats.get(TOTAL_KEYS_COUNT_OFFSET));

        uint256 depositedSigningKeysCount = signingKeysStats.get(TOTAL_DEPOSITED_KEYS_COUNT_OFFSET);
        (pubkeys, signatures) = SigningKeys.initKeysSigsBuf(_limit);
        used = new bool[](_limit);

        SIGNING_KEYS_MAPPING_NAME.loadKeysSigs(_nodeOperatorId, _offset, _limit, pubkeys, signatures, 0);
        for (uint256 i; i < _limit; ++i) {
            used[i] = (_offset + i) < depositedSigningKeysCount;
        }
    }

    /// @notice Returns the type of the staking module
    function getType() external view returns (bytes32) {
        return TYPE_POSITION.getStorageBytes32();
    }

    function getStakingModuleSummary()
        external
        view
        returns (uint256 totalExitedValidators, uint256 totalDepositedValidators, uint256 depositableValidatorsCount)
    {
        Packed64x4.Packed memory summarySigningKeysStats = _loadSummarySigningKeysStats();
        totalExitedValidators = summarySigningKeysStats.get(SUMMARY_EXITED_KEYS_COUNT_OFFSET);
        totalDepositedValidators = summarySigningKeysStats.get(SUMMARY_DEPOSITED_KEYS_COUNT_OFFSET);
        depositableValidatorsCount = summarySigningKeysStats.get(SUMMARY_MAX_VALIDATORS_COUNT_OFFSET) - totalDepositedValidators;
    }

    function getNodeOperatorSummary(uint256 _nodeOperatorId)
        external
        view
        returns (
            bool isTargetLimitActive,
            uint256 targetValidatorsCount,
            uint256 stuckValidatorsCount,
            uint256 refundedValidatorsCount,
            uint256 stuckPenaltyEndTimestamp,
            uint256 totalExitedValidators,
            uint256 totalDepositedValidators,
            uint256 depositableValidatorsCount
    ) {
        _onlyExistedNodeOperator(_nodeOperatorId);

        Packed64x4.Packed memory operatorTargetStats = _loadOperatorTargetValidatorsStats(_nodeOperatorId);
        Packed64x4.Packed memory stuckPenaltyStats = _loadOperatorStuckPenaltyStats(_nodeOperatorId);

        isTargetLimitActive = operatorTargetStats.get(IS_TARGET_LIMIT_ACTIVE_OFFSET) != 0;
        targetValidatorsCount = operatorTargetStats.get(TARGET_VALIDATORS_COUNT_OFFSET);
        stuckValidatorsCount = stuckPenaltyStats.get(STUCK_VALIDATORS_COUNT_OFFSET);
        refundedValidatorsCount = stuckPenaltyStats.get(REFUNDED_VALIDATORS_COUNT_OFFSET);
        stuckPenaltyEndTimestamp = stuckPenaltyStats.get(STUCK_PENALTY_END_TIMESTAMP_OFFSET);

        (totalExitedValidators, totalDepositedValidators, depositableValidatorsCount) =
            _getNodeOperatorValidatorsSummary(_nodeOperatorId);
    }

    function _getNodeOperatorValidatorsSummary(uint256 _nodeOperatorId) internal view returns (
        uint256 totalExitedValidators,
        uint256 totalDepositedValidators,
        uint256 depositableValidatorsCount
    ) {
        uint256 totalMaxValidators;
        (totalMaxValidators, totalExitedValidators, totalDepositedValidators) = _getNodeOperator(_nodeOperatorId);

        depositableValidatorsCount = totalMaxValidators - totalDepositedValidators;
    }

    function _isOperatorPenalized(Packed64x4.Packed memory stuckPenaltyStats) internal view returns (bool) {
        return stuckPenaltyStats.get(REFUNDED_VALIDATORS_COUNT_OFFSET) < stuckPenaltyStats.get(STUCK_VALIDATORS_COUNT_OFFSET)
            || block.timestamp <= stuckPenaltyStats.get(STUCK_PENALTY_END_TIMESTAMP_OFFSET);
    }

    function isOperatorPenalized(uint256 _nodeOperatorId) public view returns (bool) {
        Packed64x4.Packed memory stuckPenaltyStats = _loadOperatorStuckPenaltyStats(_nodeOperatorId);
        return _isOperatorPenalized(stuckPenaltyStats);
    }

    function isOperatorPenaltyCleared(uint256 _nodeOperatorId) public view returns (bool) {
        Packed64x4.Packed memory stuckPenaltyStats = _loadOperatorStuckPenaltyStats(_nodeOperatorId);
        return !_isOperatorPenalized(stuckPenaltyStats) && stuckPenaltyStats.get(STUCK_PENALTY_END_TIMESTAMP_OFFSET) == 0;
    }

    function clearNodeOperatorPenalty(uint256 _nodeOperatorId) public returns (bool) {
        Packed64x4.Packed memory stuckPenaltyStats = _loadOperatorStuckPenaltyStats(_nodeOperatorId);
        require(
            !_isOperatorPenalized(stuckPenaltyStats) && stuckPenaltyStats.get(STUCK_PENALTY_END_TIMESTAMP_OFFSET) != 0,
            "CANT_CLEAR_PENALTY"
        );
        stuckPenaltyStats.set(STUCK_PENALTY_END_TIMESTAMP_OFFSET, 0);
        _saveOperatorStuckPenaltyStats(_nodeOperatorId, stuckPenaltyStats);
        _updateSummaryMaxValidatorsCount(_nodeOperatorId);
    }

    /// @notice Returns total number of node operators
    function getNodeOperatorsCount() public view returns (uint256) {
        return TOTAL_OPERATORS_COUNT_POSITION.getStorageUint256();
    }

    /// @notice Returns number of active node operators
    function getActiveNodeOperatorsCount() public view returns (uint256) {
        return ACTIVE_OPERATORS_COUNT_POSITION.getStorageUint256();
    }

    /// @notice Returns if the node operator with given id is active
    function getNodeOperatorIsActive(uint256 _nodeOperatorId) public view returns (bool) {
        return _nodeOperators[_nodeOperatorId].active;
    }

    /// @notice Returns up to `_limit` node operator ids starting from the `_offset`.
    function getNodeOperatorIds(uint256 _offset, uint256 _limit)
        external
        view
        returns (uint256[] memory nodeOperatorIds) {
        uint256 nodeOperatorsCount = getNodeOperatorsCount();
        if (_offset >= nodeOperatorsCount || _limit == 0) return;
        nodeOperatorIds = new uint256[](Math256.min(_limit, nodeOperatorsCount - _offset));
        for (uint256 i = 0; i < nodeOperatorIds.length; ++i) {
            nodeOperatorIds[i] = _offset + i;
        }
    }

    /// @notice Returns a counter that MUST change it's value when any of the following happens:
    ///     1. a node operator's deposit data is added
    ///     2. a node operator's deposit data is removed
    ///     3. a node operator's ready-to-deposit data size is changed
    ///     4. a node operator was activated/deactivated
    ///     5. a node operator's deposit data is used for the deposit
    function getNonce() external view returns (uint256) {
        return KEYS_OP_INDEX_POSITION.getStorageUint256();
    }

    /// @notice Returns a counter that MUST change its value whenever the deposit data set changes.
    ///     Below is the typical list of actions that requires an update of the nonce:
    ///     1. a node operator's deposit data is added
    ///     2. a node operator's deposit data is removed
    ///     3. a node operator's ready-to-deposit data size is changed
    ///     4. a node operator was activated/deactivated
    ///     5. a node operator's deposit data is used for the deposit
    ///     Note: Depending on the StakingModule implementation above list might be extended
    /// @dev DEPRECATED use getNonce() instead
    function getKeysOpIndex() external view returns (uint256) {
        return KEYS_OP_INDEX_POSITION.getStorageUint256();
    }

    /// @notice distributes rewards among node operators
    /// @return the amount of stETH shares distributed among node operators
    function _distributeRewards() internal returns (uint256 distributed) {
        IStETH stETH = IStETH(getLocator().lido());

        uint256 sharesToDistribute = stETH.sharesOf(address(this));
        if (sharesToDistribute == 0) {
            return;
        }

        (address[] memory recipients, uint256[] memory shares, bool[] memory penalized) =
            getRewardsDistribution(sharesToDistribute);

        uint256 toBurn;
        for (uint256 idx; idx < recipients.length; ++idx) {
            /// @dev skip ultra-low amounts processing to avoid transfer zero amount in case of a penalty
            if (shares[idx] < 2) continue;
            if (penalized[idx]) {
                /// @dev half reward punishment
                /// @dev ignore remainder since it accumulated on contract balance
                shares[idx] >>= 1;
                toBurn = toBurn.add(shares[idx]);
                emit NodeOperatorPenalized(recipients[idx], shares[idx]);
            }
            stETH.transferShares(recipients[idx], shares[idx]);
            distributed = distributed.add(shares[idx]);
            emit RewardsDistributed(recipients[idx], shares[idx]);
        }
        if (toBurn > 0) {
            IBurner(getLocator().burner()).requestBurnShares(address(this), toBurn);
        }
    }

    function getLocator() public view returns (ILidoLocator) {
        return ILidoLocator(LIDO_LOCATOR_POSITION.getStorageAddress());
    }

    function getStuckPenaltyDelay() public view returns (uint256) {
        return STUCK_PENALTY_DELAY_POSITION.getStorageUint256();
    }

    function setStuckPenaltyDelay(uint256 _delay) external {
        _auth(MANAGE_NODE_OPERATOR_ROLE);

        _setStuckPenaltyDelay(_delay);
    }

    /// @dev set new stuck penalty delay, duration in sec
    function _setStuckPenaltyDelay(uint256 _delay) internal {
        _requireValidRange(_delay <= MAX_STUCK_PENALTY_DELAY);
        STUCK_PENALTY_DELAY_POSITION.setStorageUint256(_delay);
        emit StuckPenaltyDelayChanged(_delay);
    }

    function _increaseValidatorsKeysNonce() internal {
        uint256 keysOpIndex = KEYS_OP_INDEX_POSITION.getStorageUint256() + 1;
        KEYS_OP_INDEX_POSITION.setStorageUint256(keysOpIndex);
        /// @dev [DEPRECATED] event preserved for tooling compatibility
        emit KeysOpIndexSet(keysOpIndex);
        emit NonceChanged(keysOpIndex);
    }

    function _loadSummarySigningKeysStats() internal view returns (Packed64x4.Packed memory) {
        return _nodeOperatorSummary.summarySigningKeysStats;
    }

    function _saveSummarySigningKeysStats(Packed64x4.Packed memory _val) internal {
        _nodeOperatorSummary.summarySigningKeysStats = _val;
    }

    function _loadOperatorTargetValidatorsStats(uint256 _nodeOperatorId) internal view returns (Packed64x4.Packed memory) {
        return _nodeOperators[_nodeOperatorId].targetValidatorsStats;
    }

    function _saveOperatorTargetValidatorsStats(uint256 _nodeOperatorId, Packed64x4.Packed memory _val) internal {
        _nodeOperators[_nodeOperatorId].targetValidatorsStats = _val;
    }

    function _loadOperatorStuckPenaltyStats(uint256 _nodeOperatorId) internal view returns (Packed64x4.Packed memory) {
        return _nodeOperators[_nodeOperatorId].stuckPenaltyStats;
    }

    function _saveOperatorStuckPenaltyStats(uint256 _nodeOperatorId, Packed64x4.Packed memory _val) internal {
        _nodeOperators[_nodeOperatorId].stuckPenaltyStats = _val;
    }

    function _loadOperatorSigningKeysStats(uint256 _nodeOperatorId) internal view returns (Packed64x4.Packed memory) {
        return _nodeOperators[_nodeOperatorId].signingKeysStats;
    }

    function _saveOperatorSigningKeysStats(uint256 _nodeOperatorId, Packed64x4.Packed memory _val) internal {
        _nodeOperators[_nodeOperatorId].signingKeysStats = _val;
    }

    function _requireAuth(bool _pass) internal pure {
        require(_pass, "APP_AUTH_FAILED");
    }

    function _requireNotSameValue(bool _pass) internal pure {
        require(_pass, "VALUE_IS_THE_SAME");
    }

    function _requireValidRange(bool _pass) internal pure {
        require(_pass, "OUT_OF_RANGE");
    }

    function _onlyCorrectNodeOperatorState(bool _pass) internal pure {
        require(_pass, "WRONG_OPERATOR_ACTIVE_STATE");
    }

    function _auth(bytes32 _role) internal view {
        _requireAuth(canPerform(msg.sender, _role, new uint256[](0)));
    }

    function _authP(bytes32 _role, uint256[] _params) internal view {
        _requireAuth(canPerform(msg.sender, _role, _params));
    }

    function _onlyNodeOperatorManager(address _sender, uint256 _nodeOperatorId) internal view {
        bool isRewardAddress = _sender == _nodeOperators[_nodeOperatorId].rewardAddress;
        _requireAuth(isRewardAddress || canPerform(_sender, MANAGE_SIGNING_KEYS, arr(_nodeOperatorId)));
    }

    function _onlyExistedNodeOperator(uint256 _nodeOperatorId) internal view {
        _requireValidRange(_nodeOperatorId < getNodeOperatorsCount());
    }

    function _onlyValidNodeOperatorName(string _name) internal pure {
        require(bytes(_name).length > 0 && bytes(_name).length <= MAX_NODE_OPERATOR_NAME_LENGTH, "WRONG_NAME_LENGTH");
    }

    function _onlyNonZeroAddress(address _a) internal pure {
        require(_a != address(0), "ZERO_ADDRESS");
    }
}

// SPDX-FileCopyrightText: 2023 Lido <[email protected]>
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.4.24;

import "@aragon/os/contracts/common/UnstructuredStorage.sol";

/**
 * @title Adapted code of /contracts/0.8.9/utils/Versioned.sol
 *
 * This contract contains only core part of original Versioned.sol
 * to reduce contract size
 */
contract Versioned {
    using UnstructuredStorage for bytes32;

    event ContractVersionSet(uint256 version);

    /// @dev Storage slot: uint256 version
    /// Version of the initialized contract storage.
    /// The version stored in CONTRACT_VERSION_POSITION equals to:
    /// - 0 right after the deployment, before an initializer is invoked (and only at that moment);
    /// - N after calling initialize(), where N is the initially deployed contract version;
    /// - N after upgrading contract by calling finalizeUpgrade_vN().
    bytes32 internal constant CONTRACT_VERSION_POSITION =
        0x4dd0f6662ba1d6b081f08b350f5e9a6a7b15cf586926ba66f753594928fa64a6; // keccak256("lido.Versioned.contractVersion");

    uint256 internal constant PETRIFIED_VERSION_MARK = uint256(-1);

    constructor() public {
        // lock version in the implementation's storage to prevent initialization
        CONTRACT_VERSION_POSITION.setStorageUint256(PETRIFIED_VERSION_MARK);
    }

    /// @notice Returns the current contract version.
    function getContractVersion() public view returns (uint256) {
        return CONTRACT_VERSION_POSITION.getStorageUint256();
    }

    function _checkContractVersion(uint256 version) internal view {
        require(version == getContractVersion(), "UNEXPECTED_CONTRACT_VERSION");
    }

    function _setContractVersion(uint256 version) internal {
        CONTRACT_VERSION_POSITION.setStorageUint256(version);
        emit ContractVersionSet(version);
    }
}

// SPDX-FileCopyrightText: 2023 Lido <[email protected]>
// SPDX-License-Identifier: GPL-3.0

// See contracts/COMPILERS.md
// solhint-disable-next-line
pragma solidity >=0.4.24 <0.9.0;

interface IBurner {
    /**
     * Commit cover/non-cover burning requests and logs cover/non-cover shares amount just burnt.
     *
     * NB: The real burn enactment to be invoked after the call (via internal Lido._burnShares())
     */
    function commitSharesToBurn(uint256 _stETHSharesToBurn) external;

    /**
     * Request burn shares
     */
    function requestBurnShares(address _from, uint256 _sharesAmount) external;

    /**
      * Returns the current amount of shares locked on the contract to be burnt.
      */
    function getSharesRequestedToBurn() external view returns (uint256 coverShares, uint256 nonCoverShares);

    /**
      * Returns the total cover shares ever burnt.
      */
    function getCoverSharesBurnt() external view returns (uint256);

    /**
      * Returns the total non-cover shares ever burnt.
      */
    function getNonCoverSharesBurnt() external view returns (uint256);
}

// SPDX-FileCopyrightText: 2023 Lido <[email protected]>
// SPDX-License-Identifier: GPL-3.0

// See contracts/COMPILERS.md
// solhint-disable-next-line
pragma solidity >=0.4.24 <0.9.0;

interface ILidoLocator {
    function accountingOracle() external view returns(address);
    function depositSecurityModule() external view returns(address);
    function elRewardsVault() external view returns(address);
    function legacyOracle() external view returns(address);
    function lido() external view returns(address);
    function oracleReportSanityChecker() external view returns(address);
    function burner() external view returns(address);
    function stakingRouter() external view returns(address);
    function treasury() external view returns(address);
    function validatorsExitBusOracle() external view returns(address);
    function withdrawalQueue() external view returns(address);
    function withdrawalVault() external view returns(address);
    function postTokenRebaseReceiver() external view returns(address);
    function oracleDaemonConfig() external view returns(address);
    function coreComponents() external view returns(
        address elRewardsVault,
        address oracleReportSanityChecker,
        address stakingRouter,
        address treasury,
        address withdrawalQueue,
        address withdrawalVault
    );
    function oracleReportComponentsForLido() external view returns(
        address accountingOracle,
        address elRewardsVault,
        address oracleReportSanityChecker,
        address burner,
        address withdrawalQueue,
        address withdrawalVault,
        address postTokenRebaseReceiver
    );
}

// SPDX-FileCopyrightText: 2023 Lido <[email protected]>
// SPDX-License-Identifier: MIT

// Copied from: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/0457042d93d9dfd760dbaa06a4d2f1216fdbe297/contracts/utils/math/Math.sol

// See contracts/COMPILERS.md
// solhint-disable-next-line
pragma solidity >=0.4.24 <0.9.0;

library Math256 {
    /// @dev Returns the absolute unsigned value of a signed value.
    function abs(int256 n) internal pure returns (uint256) {
        return uint256(n >= 0 ? n : -n);
    }

    /// @dev Returns the largest of two numbers.
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /// @dev Returns the smallest of two numbers.
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /// @dev Returns the largest of two numbers.
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    /// @dev Returns the smallest of two numbers.
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /// @dev Returns the ceiling of the division of two numbers.
    ///
    /// This differs from standard division with `/` in that it rounds up instead
    /// of rounding down.
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }
}

// SPDX-FileCopyrightText: 2023 Lido <[email protected]>
// SPDX-License-Identifier: GPL-3.0

/* See contracts/COMPILERS.md */
// solhint-disable-next-line
pragma solidity >=0.4.24 <0.9.0;

import {Math256} from "./Math256.sol";

/// @notice Library with methods to calculate "proportional" allocations among buckets with different
///     capacity and level of filling.
/// @dev The current implementation favors buckets with the least fill factor
library MinFirstAllocationStrategy {
    uint256 private constant MAX_UINT256 = 2**256 - 1;

    /// @notice Allocates passed maxAllocationSize among the buckets. The resulting allocation doesn't exceed the
    ///     capacities of the buckets. An algorithm starts filling from the least populated buckets to equalize the fill factor.
    ///     For example, for buckets: [9998, 70, 0], capacities: [10000, 101, 100], and maxAllocationSize: 101, the allocation happens
    ///     following way:
    ///         1. top up the bucket with index 2 on 70. Intermediate state of the buckets: [9998, 70, 70]. According to the definition,
    ///            the rest allocation must be proportionally split among the buckets with the same values.
    ///         2. top up the bucket with index 1 on 15. Intermediate state of the buckets: [9998, 85, 70].
    ///         3. top up the bucket with index 2 on 15. Intermediate state of the buckets: [9998, 85, 85].
    ///         4. top up the bucket with index 1 on 1. Nothing to distribute. The final state of the buckets: [9998, 86, 85]
    /// @dev Method modifies the passed buckets array to reduce the gas costs on memory allocation.
    /// @param buckets The array of current allocations in the buckets
    /// @param capacities The array of capacities of the buckets
    /// @param allocationSize The desired value to allocate among the buckets
    /// @return allocated The total value allocated among the buckets. Can't exceed the allocationSize value
    function allocate(
        uint256[] memory buckets,
        uint256[] memory capacities,
        uint256 allocationSize
    ) internal pure returns (uint256 allocated) {
        uint256 allocatedToBestCandidate = 0;
        while (allocated < allocationSize) {
            allocatedToBestCandidate = allocateToBestCandidate(buckets, capacities, allocationSize - allocated);
            if (allocatedToBestCandidate == 0) {
                break;
            }
            allocated += allocatedToBestCandidate;
        }
    }

    /// @notice Allocates the max allowed value not exceeding allocationSize to the bucket with the least value.
    ///     The candidate search happens according to the following algorithm:
    ///         1. Find the first least filled bucket which has free space. Count the number of such buckets.
    ///         2. If no buckets are found terminate the search - no free buckets
    ///         3. Find the first bucket with free space, which has the least value greater
    ///             than the bucket found in step 1. To preserve proportional allocation the resulting allocation can't exceed this value.
    ///         4. Calculate the allocation size as:
    ///             min(
    ///                 (count of least filling buckets > 1 ? ceilDiv(allocationSize, count of least filling buckets) : allocationSize),
    ///                 fill factor of the bucket found in step 3,
    ///                 free space of the least filled bucket
    ///             )
    /// @dev Method modifies the passed buckets array to reduce the gas costs on memory allocation.
    /// @param buckets The array of current allocations in the buckets
    /// @param capacities The array of capacities of the buckets
    /// @param allocationSize The desired value to allocate to the bucket
    /// @return allocated The total value allocated to the bucket. Can't exceed the allocationSize value
    function allocateToBestCandidate(
        uint256[] memory buckets,
        uint256[] memory capacities,
        uint256 allocationSize
    ) internal pure returns (uint256 allocated) {
        uint256 bestCandidateIndex = buckets.length;
        uint256 bestCandidateAllocation = MAX_UINT256;
        uint256 bestCandidatesCount = 0;

        if (allocationSize == 0) {
            return 0;
        }

        for (uint256 i = 0; i < buckets.length; ++i) {
            if (buckets[i] >= capacities[i]) {
                continue;
            } else if (bestCandidateAllocation > buckets[i]) {
                bestCandidateIndex = i;
                bestCandidatesCount = 1;
                bestCandidateAllocation = buckets[i];
            } else if (bestCandidateAllocation == buckets[i]) {
                bestCandidatesCount += 1;
            }
        }

        if (bestCandidatesCount == 0) {
            return 0;
        }

        // cap the allocation by the smallest larger allocation than the found best one
        uint256 allocationSizeUpperBound = MAX_UINT256;
        for (uint256 j = 0; j < buckets.length; ++j) {
            if (buckets[j] >= capacities[j]) {
                continue;
            } else if (buckets[j] > bestCandidateAllocation && buckets[j] < allocationSizeUpperBound) {
                allocationSizeUpperBound = buckets[j];
            }
        }

        allocated = Math256.min(
            bestCandidatesCount > 1 ? Math256.ceilDiv(allocationSize, bestCandidatesCount) : allocationSize,
            Math256.min(allocationSizeUpperBound, capacities[bestCandidateIndex]) - bestCandidateAllocation
        );
        buckets[bestCandidateIndex] += allocated;
    }
}