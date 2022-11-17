/*
 * SPDX-License-Identitifer:    MIT
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
 * SPDX-License-Identitifer:    MIT
 */

pragma solidity ^0.4.24;


interface IACL {
    function initialize(address permissionsCreator) external;

    // TODO: this should be external
    // See https://github.com/ethereum/solidity/issues/4832
    function hasPermission(address who, address where, bytes32 what, bytes how) public view returns (bool);
}

/*
 * SPDX-License-Identitifer:    MIT
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
 * SPDX-License-Identitifer:    MIT
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
 * SPDX-License-Identitifer:    MIT
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
 * SPDX-License-Identitifer:    MIT
 */

pragma solidity ^0.4.24;


// aragonOS and aragon-apps rely on address(0) to denote native ETH, in
// contracts where both tokens and ETH are accepted
contract EtherTokenConstant {
    address internal constant ETH = address(0);
}

/*
 * SPDX-License-Identitifer:    MIT
 */

pragma solidity ^0.4.24;


interface IForwarder {
    function isForwarder() external pure returns (bool);

    // TODO: this should be external
    // See https://github.com/ethereum/solidity/issues/4832
    function canForward(address sender, bytes evmCallScript) public view returns (bool);

    // TODO: this should be external
    // See https://github.com/ethereum/solidity/issues/4832
    function forward(bytes evmCallScript) public;
}

/*
 * SPDX-License-Identitifer:    MIT
 */

pragma solidity ^0.4.24;


interface IVaultRecoverable {
    event RecoverToVault(address indexed vault, address indexed token, uint256 amount);

    function transferToVault(address token) external;

    function allowRecoverability(address token) external view returns (bool);
    function getRecoveryVault() external view returns (address);
}

/*
 * SPDX-License-Identitifer:    MIT
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
 * SPDX-License-Identitifer:    MIT
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
 * SPDX-License-Identitifer:    MIT
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
 * SPDX-License-Identitifer:    MIT
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
 * SPDX-License-Identitifer:    MIT
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
 * SPDX-License-Identitifer:    MIT
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
 * SPDX-License-Identitifer:    MIT
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
 * SPDX-License-Identitifer:    MIT
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
 * SPDX-License-Identitifer:    MIT
 */

pragma solidity ^0.4.24;


interface IEVMScriptExecutor {
    function execScript(bytes script, bytes input, address[] blacklist) external returns (bytes);
    function executorType() external pure returns (bytes32);
}

/*
 * SPDX-License-Identitifer:    MIT
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
 * SPDX-License-Identitifer:    MIT
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
 * SPDX-License-Identitifer:    MIT
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

/*
 * SPDX-License-Identitifer:    GPL-3.0-or-later
 */

pragma solidity ^0.4.24;


/**
 * @title Checkpointing
 * @notice Checkpointing library for keeping track of historical values based on an arbitrary time
 *         unit (e.g. seconds or block numbers).
 * @dev Inspired by:
 *   - MiniMe token (https://github.com/aragon/minime/blob/master/contracts/MiniMeToken.sol)
 *   - Staking (https://github.com/aragon/staking/blob/master/contracts/Checkpointing.sol)
 */
library Checkpointing {
    string private constant ERROR_PAST_CHECKPOINT = "CHECKPOINT_PAST_CHECKPOINT";

    struct Checkpoint {
        uint64 time;
        uint192 value;
    }

    struct History {
        Checkpoint[] history;
    }

    function addCheckpoint(History storage _self, uint64 _time, uint192 _value) internal {
        uint256 length = _self.history.length;
        if (length == 0) {
            _self.history.push(Checkpoint(_time, _value));
        } else {
            Checkpoint storage currentCheckpoint = _self.history[length - 1];
            uint256 currentCheckpointTime = uint256(currentCheckpoint.time);

            if (_time > currentCheckpointTime) {
                _self.history.push(Checkpoint(_time, _value));
            } else if (_time == currentCheckpointTime) {
                currentCheckpoint.value = _value;
            } else { // ensure list ordering
                revert(ERROR_PAST_CHECKPOINT);
            }
        }
    }

    function getValueAt(History storage _self, uint64 _time) internal view returns (uint256) {
        return _getValueAt(_self, _time);
    }

    function lastUpdated(History storage _self) internal view returns (uint256) {
        uint256 length = _self.history.length;
        if (length > 0) {
            return uint256(_self.history[length - 1].time);
        }

        return 0;
    }

    function latestValue(History storage _self) internal view returns (uint256) {
        uint256 length = _self.history.length;
        if (length > 0) {
            return uint256(_self.history[length - 1].value);
        }

        return 0;
    }

    function _getValueAt(History storage _self, uint64 _time) private view returns (uint256) {
        uint256 length = _self.history.length;

        // Short circuit if there's no checkpoints yet
        // Note that this also lets us avoid using SafeMath later on, as we've established that
        // there must be at least one checkpoint
        if (length == 0) {
            return 0;
        }

        // Check last checkpoint
        uint256 lastIndex = length - 1;
        Checkpoint storage lastCheckpoint = _self.history[lastIndex];
        if (_time >= lastCheckpoint.time) {
            return uint256(lastCheckpoint.value);
        }

        // Check first checkpoint (if not already checked with the above check on last)
        if (length == 1 || _time < _self.history[0].time) {
            return 0;
        }

        // Do binary search
        // As we've already checked both ends, we don't need to check the last checkpoint again
        uint256 low = 0;
        uint256 high = lastIndex - 1;

        while (high > low) {
            uint256 mid = (high + low + 1) / 2; // average, ceil round
            Checkpoint storage checkpoint = _self.history[mid];
            uint64 midTime = checkpoint.time;

            if (_time > midTime) {
                low = mid;
            } else if (_time < midTime) {
                // Note that we don't need SafeMath here because mid must always be greater than 0
                // from the while condition
                high = mid - 1;
            } else {
                // _time == midTime
                return uint256(checkpoint.value);
            }
        }

        return uint256(_self.history[low].value);
    }
}

pragma solidity ^0.4.24;


library CheckpointingHelpers {
    uint256 private constant MAX_UINT64 = uint64(-1);
    uint256 private constant MAX_UINT192 = uint192(-1);

    string private constant ERROR_UINT64_TOO_BIG = "UINT64_NUMBER_TOO_BIG";
    string private constant ERROR_UINT192_TOO_BIG = "UINT192_NUMBER_TOO_BIG";

    function toUint64Time(uint256 _a) internal pure returns (uint64) {
        require(_a <= MAX_UINT64, ERROR_UINT64_TOO_BIG);
        return uint64(_a);
    }

    function toUint192Value(uint256 _a) internal pure returns (uint192) {
        require(_a <= MAX_UINT192, ERROR_UINT192_TOO_BIG);
        return uint192(_a);
    }
}

/*
 * SPDX-License-Identitifer:    GPL-3.0-or-later
 */

pragma solidity ^0.4.24;

import "@aragon/os/contracts/lib/token/ERC20.sol";


/**
 * @title ERC20ViewOnly
 * @notice Abstract ERC20 interface that is "view-only" by disallowing transfers and allowances. Implementations must track account balances via another mechanism.
 * @dev Implemented functions at this level **NEVER** revert
 */
contract ERC20ViewOnly is ERC20 {
    string private constant ERROR_ERC20_VIEW_ONLY = "ERC20_VIEW_ONLY";

    function approve(address, uint256) public returns (bool) {
        revert(ERROR_ERC20_VIEW_ONLY);
    }

    function transfer(address, uint256) public returns (bool) {
        revert(ERROR_ERC20_VIEW_ONLY);
    }

    function transferFrom(address, address, uint256) public returns (bool) {
        revert(ERROR_ERC20_VIEW_ONLY);
    }

    function allowance(address, address) public view returns (uint256) {
        return 0;
    }
}

/*
 * SPDX-License-Identitifer:    GPL-3.0-or-later
 */

pragma solidity ^0.4.24;


library StaticInvoke {
    function staticInvoke(address _addr, bytes memory _calldata)
        internal
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
}

/*
 * SPDX-License-Identitifer:    GPL-3.0-or-later
 */

pragma solidity 0.4.24;

import "@aragon/os/contracts/lib/token/ERC20.sol";


contract IERC20WithCheckpointing is ERC20 {
    function balanceOfAt(address _owner, uint256 _blockNumber) public view returns (uint256);
    function totalSupplyAt(uint256 _blockNumber) public view returns (uint256);
}

/*
 * SPDX-License-Identitifer:    GPL-3.0-or-later
 */

pragma solidity 0.4.24;

import "@aragon/os/contracts/apps/AragonApp.sol";
import "@aragon/os/contracts/common/IForwarder.sol";
import "@aragon/os/contracts/common/IsContract.sol";
import "@aragon/os/contracts/lib/math/SafeMath.sol";
import "@aragon/os/contracts/lib/token/ERC20.sol";

import "@aragonone/voting-connectors-contract-utils/contracts/Checkpointing.sol";
import "@aragonone/voting-connectors-contract-utils/contracts/CheckpointingHelpers.sol";
import "@aragonone/voting-connectors-contract-utils/contracts/ERC20ViewOnly.sol";
import "@aragonone/voting-connectors-contract-utils/contracts/StaticInvoke.sol";
import "@aragonone/voting-connectors-contract-utils/contracts/interfaces/IERC20WithCheckpointing.sol";

import "./interfaces/IERC900History.sol";

/**
 * @title VotingAggregator
 * @notice Voting power aggregator across many sources that provides a "view-only" checkpointed
 *         ERC20 implementation.
 */
contract VotingAggregator is IERC20WithCheckpointing, IForwarder, IsContract, ERC20ViewOnly, AragonApp {
    using SafeMath for uint256;
    using StaticInvoke for address;
    using Checkpointing for Checkpointing.History;
    using CheckpointingHelpers for uint256;

    /* Hardcoded constants to save gas
    bytes32 public constant ADD_POWER_SOURCE_ROLE = keccak256("ADD_POWER_SOURCE_ROLE");
    bytes32 public constant MANAGE_POWER_SOURCE_ROLE = keccak256("MANAGE_POWER_SOURCE_ROLE");
    bytes32 public constant MANAGE_WEIGHTS_ROLE = keccak256("MANAGE_WEIGHTS_ROLE");
    */
    bytes32 public constant ADD_POWER_SOURCE_ROLE = 0x10f7c4af0b190fdd7eb73fa36b0e280d48dc6b8d355f89769b4f1a50a61d1929;
    bytes32 public constant MANAGE_POWER_SOURCE_ROLE = 0x79ac9d2706bbe6bcdb60a65ba8145a498f6d506aaa455baa7675dff5779cb99f;
    bytes32 public constant MANAGE_WEIGHTS_ROLE = 0xa36fcade8375289791865312a33263fdc82d07e097c13524c9d6436c0de396ff;

    // Arbitrary number, but having anything close to this number would most likely be unwieldy.
    // Note the primary protection this provides is to ensure that one cannot continue adding
    // sources to break gas limits even with all sources disabled.
    uint256 internal constant MAX_SOURCES = 20;
    uint192 internal constant SOURCE_ENABLED_VALUE = 1;
    uint192 internal constant SOURCE_DISABLED_VALUE = 0;

    string private constant ERROR_NO_POWER_SOURCE = "VA_NO_POWER_SOURCE";
    string private constant ERROR_POWER_SOURCE_TYPE_INVALID = "VA_POWER_SOURCE_TYPE_INVALID";
    string private constant ERROR_POWER_SOURCE_INVALID = "VA_POWER_SOURCE_INVALID";
    string private constant ERROR_POWER_SOURCE_ALREADY_ADDED = "VA_POWER_SOURCE_ALREADY_ADDED";
    string private constant ERROR_TOO_MANY_POWER_SOURCES = "VA_TOO_MANY_POWER_SOURCES";
    string private constant ERROR_ZERO_WEIGHT = "VA_ZERO_WEIGHT";
    string private constant ERROR_SAME_WEIGHT = "VA_SAME_WEIGHT";
    string private constant ERROR_SOURCE_NOT_ENABLED = "VA_SOURCE_NOT_ENABLED";
    string private constant ERROR_SOURCE_NOT_DISABLED = "VA_SOURCE_NOT_DISABLED";
    string private constant ERROR_CAN_NOT_FORWARD = "VA_CAN_NOT_FORWARD";
    string private constant ERROR_SOURCE_CALL_FAILED = "VA_SOURCE_CALL_FAILED";
    string private constant ERROR_INVALID_CALL_OR_SELECTOR = "VA_INVALID_CALL_OR_SELECTOR";

    enum PowerSourceType {
        Invalid,
        ERC20WithCheckpointing,
        ERC900
    }

    enum CallType {
        BalanceOfAt,
        TotalSupplyAt
    }

    struct PowerSource {
        PowerSourceType sourceType;
        Checkpointing.History enabledHistory;
        Checkpointing.History weightHistory;
    }

    string public name;
    string public symbol;
    uint8 public decimals;

    mapping (address => PowerSource) internal powerSourceDetails;
    address[] public powerSources;

    event AddPowerSource(address indexed sourceAddress, PowerSourceType sourceType, uint256 weight);
    event ChangePowerSourceWeight(address indexed sourceAddress, uint256 newWeight);
    event DisablePowerSource(address indexed sourceAddress);
    event EnablePowerSource(address indexed sourceAddress);

    modifier sourceExists(address _sourceAddr) {
        require(_powerSourceExists(_sourceAddr), ERROR_NO_POWER_SOURCE);
        _;
    }

    /**
     * @notice Create a new voting power aggregator
     * @param _name The aggregator's display name
     * @param _symbol The aggregator's display symbol
     * @param _decimals The aggregator's display decimal units
     */
    function initialize(string _name, string _symbol, uint8 _decimals) external onlyInit {
        initialized();

        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

    /**
     * @notice Add a new power source (`_sourceAddr`) with `_weight` weight
     * @param _sourceAddr Address of the power source
     * @param _sourceType Interface type of the power source
     * @param _weight Weight to assign to the source
     */
    function addPowerSource(address _sourceAddr, PowerSourceType _sourceType, uint256 _weight)
        external
        authP(ADD_POWER_SOURCE_ROLE, arr(_sourceAddr, _weight))
    {
        // Sanity check arguments
        require(
            _sourceType == PowerSourceType.ERC20WithCheckpointing || _sourceType == PowerSourceType.ERC900,
            ERROR_POWER_SOURCE_TYPE_INVALID
        );
        require(_weight > 0, ERROR_ZERO_WEIGHT);
        require(_sanityCheckSource(_sourceAddr, _sourceType), ERROR_POWER_SOURCE_INVALID);

        // Ensure internal consistency
        require(!_powerSourceExists(_sourceAddr), ERROR_POWER_SOURCE_ALREADY_ADDED);
        require(powerSources.length < MAX_SOURCES, ERROR_TOO_MANY_POWER_SOURCES);

        // Add source
        powerSources.push(_sourceAddr);

        PowerSource storage source = powerSourceDetails[_sourceAddr];
        source.sourceType = _sourceType;

        // Start enabled and weight history
        source.enabledHistory.addCheckpoint(getBlockNumber64(), SOURCE_ENABLED_VALUE);
        source.weightHistory.addCheckpoint(getBlockNumber64(), _weight.toUint192Value());

        emit AddPowerSource(_sourceAddr, _sourceType, _weight);
    }

    /**
     * @notice Change weight of power source at `_sourceAddr` to `_weight`
     * @param _sourceAddr Power source's address
     * @param _weight New weight to assign
     */
    function changeSourceWeight(address _sourceAddr, uint256 _weight)
        external
        authP(MANAGE_WEIGHTS_ROLE, arr(_weight, powerSourceDetails[_sourceAddr].weightHistory.latestValue()))
        sourceExists(_sourceAddr)
    {
        require(_weight > 0, ERROR_ZERO_WEIGHT);

        Checkpointing.History storage weightHistory = powerSourceDetails[_sourceAddr].weightHistory;
        require(weightHistory.latestValue() != _weight, ERROR_SAME_WEIGHT);

        weightHistory.addCheckpoint(getBlockNumber64(), _weight.toUint192Value());

        emit ChangePowerSourceWeight(_sourceAddr, _weight);
    }

    /**
     * @notice Disable power source at `_sourceAddr`
     * @param _sourceAddr Power source's address
     */
    function disableSource(address _sourceAddr)
        external
        authP(MANAGE_POWER_SOURCE_ROLE, arr(uint256(0)))
        sourceExists(_sourceAddr)
    {
        Checkpointing.History storage enabledHistory = powerSourceDetails[_sourceAddr].enabledHistory;
        require(
            enabledHistory.latestValue() == uint256(SOURCE_ENABLED_VALUE),
            ERROR_SOURCE_NOT_ENABLED
        );

        enabledHistory.addCheckpoint(getBlockNumber64(), SOURCE_DISABLED_VALUE);

        emit DisablePowerSource(_sourceAddr);
    }

    /**
     * @notice Enable power source at `_sourceAddr`
     * @param _sourceAddr Power source's address
     */
    function enableSource(address _sourceAddr)
        external
        sourceExists(_sourceAddr)
        authP(MANAGE_POWER_SOURCE_ROLE, arr(uint256(1)))
    {
        Checkpointing.History storage enabledHistory = powerSourceDetails[_sourceAddr].enabledHistory;
        require(
            enabledHistory.latestValue() == uint256(SOURCE_DISABLED_VALUE),
            ERROR_SOURCE_NOT_DISABLED
        );

        enabledHistory.addCheckpoint(getBlockNumber64(), SOURCE_ENABLED_VALUE);

        emit EnablePowerSource(_sourceAddr);
    }

    // ERC20 fns - note that this token is a non-transferrable "view-only" implementation.
    // Users should only be changing balances by changing their balances in the underlying tokens.
    // These functions do **NOT** revert if the app is uninitialized to stay compatible with normal ERC20s.

    function balanceOf(address _owner) public view returns (uint256) {
        return balanceOfAt(_owner, getBlockNumber());
    }

    function totalSupply() public view returns (uint256) {
        return totalSupplyAt(getBlockNumber());
    }

    // Checkpointed fns
    // These functions do **NOT** revert if the app is uninitialized to stay compatible with normal ERC20s.

    function balanceOfAt(address _owner, uint256 _blockNumber) public view returns (uint256) {
        return _aggregateAt(_blockNumber, CallType.BalanceOfAt, abi.encode(_owner, _blockNumber));
    }

    function totalSupplyAt(uint256 _blockNumber) public view returns (uint256) {
        return _aggregateAt(_blockNumber, CallType.TotalSupplyAt, abi.encode(_blockNumber));
    }

    // Forwarding fns

    /**
    * @notice Tells whether the VotingAggregator app is a forwarder or not
    * @dev IForwarder interface conformance
    * @return Always true
    */
    function isForwarder() public pure returns (bool) {
        return true;
    }

    /**
     * @notice Execute desired action if you have voting power
     * @dev IForwarder interface conformance
     * @param _evmScript Script being executed
     */
    function forward(bytes _evmScript) public {
        require(canForward(msg.sender, _evmScript), ERROR_CAN_NOT_FORWARD);
        bytes memory input = new bytes(0);

        // No blacklist needed as this contract should not hold any tokens from its sources
        runScript(_evmScript, input, new address[](0));
    }

    /**
    * @notice Tells whether `_sender` can forward actions or not
    * @dev IForwarder interface conformance
    * @param _sender Address of the account intending to forward an action
    * @return True if the given address can forward actions, false otherwise
    */
    function canForward(address _sender, bytes) public view returns (bool) {
        return hasInitialized() && balanceOf(_sender) > 0;
    }

    // Getter fns

    /**
     * @dev Return information about a power source
     * @param _sourceAddr Power source's address
     * @return Power source type
     * @return Whether power source is enabled
     * @return Power source weight
     */
    function getPowerSourceDetails(address _sourceAddr)
        public
        view
        sourceExists(_sourceAddr)
        returns (
            PowerSourceType sourceType,
            bool enabled,
            uint256 weight
        )
    {
        PowerSource storage source = powerSourceDetails[_sourceAddr];

        sourceType = source.sourceType;
        enabled = source.enabledHistory.latestValue() == uint256(SOURCE_ENABLED_VALUE);
        weight = source.weightHistory.latestValue();
    }

    /**
     * @dev Return number of added power sources
     * @return Number of added power sources
     */
    function getPowerSourcesLength() public view isInitialized returns (uint256) {
        return powerSources.length;
    }

    // Internal fns

    function _aggregateAt(uint256 _blockNumber, CallType _callType, bytes memory _paramdata) internal view returns (uint256) {
        uint64 _blockNumberUint64 = _blockNumber.toUint64Time();

        uint256 aggregate = 0;
        for (uint256 i = 0; i < powerSources.length; i++) {
            address sourceAddr = powerSources[i];
            PowerSource storage source = powerSourceDetails[sourceAddr];

            if (source.enabledHistory.getValueAt(_blockNumberUint64) == uint256(SOURCE_ENABLED_VALUE)) {
                bytes memory invokeData = abi.encodePacked(_selectorFor(_callType, source.sourceType), _paramdata);
                (bool success, uint256 value) = sourceAddr.staticInvoke(invokeData);
                require(success, ERROR_SOURCE_CALL_FAILED);

                uint256 weight = source.weightHistory.getValueAt(_blockNumberUint64);
                aggregate = aggregate.add(weight.mul(value));
            }
        }

        return aggregate;
    }

    function _powerSourceExists(address _sourceAddr) internal view returns (bool) {
        // All attached power sources must have a valid source type
        return powerSourceDetails[_sourceAddr].sourceType != PowerSourceType.Invalid;
    }

    function _selectorFor(CallType _callType, PowerSourceType _sourceType) internal pure returns (bytes4) {
        if (_sourceType == PowerSourceType.ERC20WithCheckpointing) {
            if (_callType == CallType.BalanceOfAt) {
                return IERC20WithCheckpointing(0).balanceOfAt.selector;
            }
            if (_callType == CallType.TotalSupplyAt) {
                return IERC20WithCheckpointing(0).totalSupplyAt.selector;
            }
        }

        if (_sourceType == PowerSourceType.ERC900) {
            if (_callType == CallType.BalanceOfAt) {
                return IERC900History(0).totalStakedForAt.selector;
            }
            if (_callType == CallType.TotalSupplyAt) {
                return IERC900History(0).totalStakedAt.selector;
            }
        }

        revert(ERROR_INVALID_CALL_OR_SELECTOR);
    }

    // Private functions
    function _sanityCheckSource(address _sourceAddr, PowerSourceType _sourceType) private view returns (bool) {
        if (!isContract(_sourceAddr)) {
            return false;
        }

        // Sanity check that the source and its declared type work for at least the current block
        bytes memory balanceOfCalldata = abi.encodePacked(
            _selectorFor(CallType.BalanceOfAt, _sourceType),
            abi.encode(this, getBlockNumber())
        );
        (bool balanceOfSuccess,) = _sourceAddr.staticInvoke(balanceOfCalldata);

        bytes memory totalSupplyCalldata = abi.encodePacked(
            _selectorFor(CallType.TotalSupplyAt, _sourceType),
            abi.encode(getBlockNumber())
        );
        (bool totalSupplySuccess,) = _sourceAddr.staticInvoke(totalSupplyCalldata);

        return balanceOfSuccess && totalSupplySuccess;
    }
}

/*
 * SPDX-License-Identitifer:    GPL-3.0-or-later
 */

pragma solidity ^0.4.24;


interface IERC900History {
    function totalStakedForAt(address addr, uint256 blockNumber) external view returns (uint256);
    function totalStakedAt(uint256 blockNumber) external view returns (uint256);

    function supportsHistory() external pure returns (bool);
}