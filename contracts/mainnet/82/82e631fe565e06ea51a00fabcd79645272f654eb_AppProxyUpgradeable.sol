pragma solidity 0.4.24;

import "contracts/lib/AppProxyBase.sol";

contract AppProxyUpgradeable is AppProxyBase {
    /**
     * @dev Initialize AppProxyUpgradeable (makes it an upgradeable Aragon app)
     * @param _kernel Reference to organization kernel for the app
     * @param _appId Identifier for app
     * @param _initializePayload Payload for call to be made after setup to initialize
     */
    constructor(
        IKernel _kernel,
        bytes32 _appId,
        bytes _initializePayload // solium-disable-line visibility-first
    ) public AppProxyBase(_kernel, _appId, _initializePayload) {
        // solium-disable-previous-line no-empty-blocks
    }

    /**
     * @dev ERC897, the address the proxy would delegate calls to
     */
    function implementation() public view returns (address) {
        return getAppBase(appId());
    }

    /**
     * @dev ERC897, whether it is a forwarding (1) or an upgradeable (2) proxy
     */
    function proxyType() public pure returns (uint256 proxyTypeId) {
        return UPGRADEABLE;
    }
}

pragma solidity 0.4.24;

import "contracts/lib/AppStorage.sol";
import "contracts/lib/DepositableDelegateProxy.sol";
import "contracts/lib/KernelNamespaceConstants.sol";

contract AppProxyBase is
    AppStorage,
    DepositableDelegateProxy,
    KernelNamespaceConstants
{
    /**
     * @dev Initialize AppProxy
     * @param _kernel Reference to organization kernel for the app
     * @param _appId Identifier for app
     * @param _initializePayload Payload for call to be made after setup to initialize
     */
    constructor(
        IKernel _kernel,
        bytes32 _appId,
        bytes _initializePayload
    ) public {
        setKernel(_kernel);
        setAppId(_appId);

        // Implicit check that kernel is actually a Kernel
        // The EVM doesn't actually provide a way for us to make sure, but we can force a revert to
        // occur if the kernel is set to 0x0 or a non-code address when we try to call a method on
        // it.
        address appCode = getAppBase(_appId);

        // If initialize payload is provided, it will be executed
        if (_initializePayload.length > 0) {
            require(isContract(appCode));
            // Cannot make delegatecall as a delegateproxy.delegatedFwd as it
            // returns ending execution context and halts contract deployment
            require(appCode.delegatecall(_initializePayload));
        }
    }

    function getAppBase(bytes32 _appId) internal view returns (address) {
        return kernel().getApp(KERNEL_APP_BASES_NAMESPACE, _appId);
    }
}

pragma solidity 0.4.24;

import "contracts/lib/IKernel.sol";
import "contracts/lib/UnstructuredStorage.sol";

contract AppStorage {
    using UnstructuredStorage for bytes32;

    /* Hardcoded constants to save gas
    bytes32 internal constant KERNEL_POSITION = keccak256("aragonOS.appStorage.kernel");
    bytes32 internal constant APP_ID_POSITION = keccak256("aragonOS.appStorage.appId");
    */
    bytes32 internal constant KERNEL_POSITION =
        0x4172f0f7d2289153072b0a6ca36959e0cbe2efc3afe50fc81636caa96338137b;
    bytes32 internal constant APP_ID_POSITION =
        0xd625496217aa6a3453eecb9c3489dc5a53e6c67b444329ea2b2cbc9ff547639b;

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

pragma solidity 0.4.24;

import "contracts/lib/DelegateProxy.sol";
import "contracts/lib/DepositableStorage.sol";

contract DepositableDelegateProxy is DepositableStorage, DelegateProxy {
    event ProxyDeposit(address sender, uint256 value);

    function() external payable {
        uint256 forwardGasThreshold = FWD_GAS_LIMIT;
        bytes32 isDepositablePosition = DEPOSITABLE_POSITION;

        // Optimized assembly implementation to prevent EIP-1884 from breaking deposits, reference code in Solidity:
        // https://github.com/aragon/aragonOS/blob/v4.2.1/contracts/common/DepositableDelegateProxy.sol#L10-L20
        assembly {
            // Continue only if the gas left is lower than the threshold for forwarding to the implementation code,
            // otherwise continue outside of the assembly block.
            if lt(gas, forwardGasThreshold) {
                // Only accept the deposit and emit an event if all of the following are true:
                // the proxy accepts deposits (isDepositable), msg.data.length == 0, and msg.value > 0
                if and(
                    and(sload(isDepositablePosition), iszero(calldatasize)),
                    gt(callvalue, 0)
                ) {
                    // Equivalent Solidity code for emitting the event:
                    // emit ProxyDeposit(msg.sender, msg.value);

                    let logData := mload(0x40) // free memory pointer
                    mstore(logData, caller) // add 'msg.sender' to the log data (first event param)
                    mstore(add(logData, 0x20), callvalue) // add 'msg.value' to the log data (second event param)

                    // Emit an event with one topic to identify the event: keccak256('ProxyDeposit(address,uint256)') = 0x15ee...dee1
                    log1(
                        logData,
                        0x40,
                        0x15eeaa57c7bd188c1388020bcadc2c436ec60d647d36ef5b9eb3c742217ddee1
                    )

                    stop() // Stop. Exits execution context
                }

                // If any of above checks failed, revert the execution (if ETH was sent, it is returned to the sender)
                revert(0, 0)
            }
        }

        address target = implementation();
        delegatedFwd(target, msg.data);
    }
}

pragma solidity 0.4.24;

contract KernelNamespaceConstants {
    /* Hardcoded constants to save gas
    bytes32 internal constant KERNEL_CORE_NAMESPACE = keccak256("core");
    bytes32 internal constant KERNEL_APP_BASES_NAMESPACE = keccak256("base");
    bytes32 internal constant KERNEL_APP_ADDR_NAMESPACE = keccak256("app");
    */
    bytes32 internal constant KERNEL_CORE_NAMESPACE =
        0xc681a85306374a5ab27f0bbc385296a54bcd314a1948b6cf61c4ea1bc44bb9f8;
    bytes32 internal constant KERNEL_APP_BASES_NAMESPACE =
        0xf1f3eb40f5bc1ad1344716ced8b8a0431d840b5783aea1fd01786bc26f35ac0f;
    bytes32 internal constant KERNEL_APP_ADDR_NAMESPACE =
        0xd6f028ca0e8edb4a8c9757ca4fdccab25fa1e0317da1188108f7d2dee14902fb;
}

pragma solidity 0.4.24;

import "contracts/lib/IACL.sol";
import "contracts/lib/IKernelEvents.sol";
import "contracts/lib/IVaultRecoverable.sol";

// This should be an interface, but interfaces can't inherit yet :(
contract IKernel is IKernelEvents, IVaultRecoverable {
    function acl() public view returns (IACL);

    function hasPermission(
        address who,
        address where,
        bytes32 what,
        bytes how
    ) public view returns (bool);

    function setApp(
        bytes32 namespace,
        bytes32 appId,
        address app
    ) public;

    function getApp(bytes32 namespace, bytes32 appId)
        public
        view
        returns (address);
}

pragma solidity 0.4.24;

library UnstructuredStorage {
    function getStorageBool(bytes32 position)
        internal
        view
        returns (bool data)
    {
        assembly {
            data := sload(position)
        }
    }

    function getStorageAddress(bytes32 position)
        internal
        view
        returns (address data)
    {
        assembly {
            data := sload(position)
        }
    }

    function getStorageBytes32(bytes32 position)
        internal
        view
        returns (bytes32 data)
    {
        assembly {
            data := sload(position)
        }
    }

    function getStorageUint256(bytes32 position)
        internal
        view
        returns (uint256 data)
    {
        assembly {
            data := sload(position)
        }
    }

    function setStorageBool(bytes32 position, bool data) internal {
        assembly {
            sstore(position, data)
        }
    }

    function setStorageAddress(bytes32 position, address data) internal {
        assembly {
            sstore(position, data)
        }
    }

    function setStorageBytes32(bytes32 position, bytes32 data) internal {
        assembly {
            sstore(position, data)
        }
    }

    function setStorageUint256(bytes32 position, uint256 data) internal {
        assembly {
            sstore(position, data)
        }
    }
}

pragma solidity 0.4.24;

import "contracts/lib/ERCProxy.sol";
import "contracts/lib/IsContract.sol";

contract DelegateProxy is ERCProxy, IsContract {
    uint256 internal constant FWD_GAS_LIMIT = 10000;

    /**
     * @dev Performs a delegatecall and returns whatever the delegatecall returned (entire context execution will return!)
     * @param _dst Destination address to perform the delegatecall
     * @param _calldata Calldata for the delegatecall
     */
    function delegatedFwd(address _dst, bytes _calldata) internal {
        require(isContract(_dst));
        uint256 fwdGasLimit = FWD_GAS_LIMIT;

        assembly {
            let result := delegatecall(
                sub(gas, fwdGasLimit),
                _dst,
                add(_calldata, 0x20),
                mload(_calldata),
                0,
                0
            )
            let size := returndatasize
            let ptr := mload(0x40)
            returndatacopy(ptr, 0, size)

            // revert instead of invalid() bc if the underlying call failed with invalid() it already wasted gas.
            // if the call returned error data, forward it
            switch result
            case 0 {
                revert(ptr, size)
            }
            default {
                return(ptr, size)
            }
        }
    }
}

pragma solidity 0.4.24;

import "contracts/lib/UnstructuredStorage.sol";

contract DepositableStorage {
    using UnstructuredStorage for bytes32;

    // keccak256("aragonOS.depositableStorage.depositable")
    bytes32 internal constant DEPOSITABLE_POSITION =
        0x665fd576fbbe6f247aff98f5c94a561e3f71ec2d3c988d56f12d342396c50cea;

    function isDepositable() public view returns (bool) {
        return DEPOSITABLE_POSITION.getStorageBool();
    }

    function setDepositable(bool _depositable) internal {
        DEPOSITABLE_POSITION.setStorageBool(_depositable);
    }
}

pragma solidity 0.4.24;

interface IACL {
    function initialize(address permissionsCreator) external;

    // TODO: this should be external
    // See https://github.com/ethereum/solidity/issues/4832
    function hasPermission(
        address who,
        address where,
        bytes32 what,
        bytes how
    ) public view returns (bool);
}

pragma solidity 0.4.24;

interface IKernelEvents {
    event SetApp(bytes32 indexed namespace, bytes32 indexed appId, address app);
}

pragma solidity 0.4.24;

interface IVaultRecoverable {
    event RecoverToVault(
        address indexed vault,
        address indexed token,
        uint256 amount
    );

    function transferToVault(address token) external;

    function allowRecoverability(address token) external view returns (bool);

    function getRecoveryVault() external view returns (address);
}

pragma solidity 0.4.24;

contract ERCProxy {
    uint256 internal constant FORWARDING = 1;
    uint256 internal constant UPGRADEABLE = 2;

    function proxyType() public pure returns (uint256 proxyTypeId);

    function implementation() public view returns (address codeAddr);
}

pragma solidity 0.4.24;

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
        assembly {
            size := extcodesize(_target)
        }
        return size > 0;
    }
}