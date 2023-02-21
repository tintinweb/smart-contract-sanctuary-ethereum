// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC20 } from '../interfaces/IERC20.sol';
import { IAxelarGateway } from '../interfaces/IAxelarGateway.sol';
import { IExpressProxy } from '../interfaces/IExpressProxy.sol';
import { IGMPExpressService } from '../interfaces/IGMPExpressService.sol';
import { IExpressRegistry } from '../interfaces/IExpressRegistry.sol';
import { IExpressExecutable } from '../interfaces/IExpressExecutable.sol';
import { FinalProxy } from '../upgradable/FinalProxy.sol';
import { SafeTokenTransfer, SafeTokenTransferFrom } from '../utils/SafeTransfer.sol';
import { Create3 } from '../deploy/Create3.sol';

contract ExpressProxy is FinalProxy, IExpressProxy {
    using SafeTokenTransfer for IERC20;
    using SafeTokenTransferFrom for IERC20;

    bytes32 internal constant REGISTRY_SALT = keccak256('express-registry');

    IAxelarGateway public immutable gateway;

    constructor(
        address implementationAddress,
        address owner,
        bytes memory setupParams,
        address gateway_
    ) FinalProxy(implementationAddress, owner, setupParams) {
        if (gateway_ == address(0)) revert InvalidAddress();

        gateway = IAxelarGateway(gateway_);
    }

    modifier onlyRegistry() {
        if (msg.sender != address(registry())) revert NotExpressRegistry();

        _;
    }

    function registry() public view returns (IExpressRegistry) {
        // Computing address is cheaper than using storage
        // Can't use immutable storage as it will alter the codehash for each proxy instance
        return IExpressRegistry(Create3.deployedAddress(REGISTRY_SALT, address(this)));
    }

    // @notice should be called right after the proxy is deployed
    function deployRegistry(bytes calldata registryCreationCode) external {
        Create3.deploy(
            REGISTRY_SALT,
            abi.encodePacked(registryCreationCode, abi.encode(address(gateway), address(this)))
        );
    }

    function execute(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload
    ) external override {
        bytes32 payloadHash = keccak256(payload);

        if (!gateway.validateContractCall(commandId, sourceChain, sourceAddress, payloadHash))
            revert NotApprovedByGateway();

        _execute(sourceChain, sourceAddress, payload);
    }

    function expressExecuteWithToken(
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload,
        string calldata tokenSymbol,
        uint256 amount
    ) external override {
        bytes32 payloadHash = keccak256(payload);
        address token = gateway.tokenAddresses(tokenSymbol);

        if (IExpressExecutable(implementation()).enableExpressCallWithToken() == false) revert ExpressCallNotEnabled();

        if (token == address(0)) revert InvalidTokenSymbol();

        registry().registerExpressCallWithToken(
            msg.sender,
            sourceChain,
            sourceAddress,
            payloadHash,
            tokenSymbol,
            amount
        );

        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        _executeWithToken(sourceChain, sourceAddress, payload, tokenSymbol, amount);
    }

    /// @notice used to handle a normal GMP call when it arrives
    function executeWithToken(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload,
        string calldata tokenSymbol,
        uint256 amount
    ) external override {
        registry().processExecuteWithToken(commandId, sourceChain, sourceAddress, payload, tokenSymbol, amount);
    }

    /// @notice callback to complete the GMP call
    function completeExecuteWithToken(
        address expressCaller,
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload,
        string calldata tokenSymbol,
        uint256 amount
    ) external override onlyRegistry {
        bytes32 payloadHash = keccak256(payload);

        if (
            !gateway.validateContractCallAndMint(
                commandId,
                sourceChain,
                sourceAddress,
                payloadHash,
                tokenSymbol,
                amount
            )
        ) revert NotApprovedByGateway();

        if (expressCaller == address(0)) {
            _executeWithToken(sourceChain, sourceAddress, payload, tokenSymbol, amount);
        } else {
            // Returning the lent token
            address token = gateway.tokenAddresses(tokenSymbol);

            if (token == address(0)) revert InvalidTokenSymbol();

            IERC20(token).safeTransfer(expressCaller, amount);
        }
    }

    // Doing internal call to the implementation
    function _execute(
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload
    ) internal {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = implementation().delegatecall(
            abi.encodeWithSelector(ExpressProxy.execute.selector, bytes32(0), sourceChain, sourceAddress, payload)
        );

        // if not success revert with the original revert data
        if (!success) {
            // solhint-disable-next-line no-inline-assembly
            assembly {
                let ptr := mload(0x40)
                let size := returndatasize()
                returndatacopy(ptr, 0, size)
                revert(ptr, size)
            }
        }
    }

    // Doing internal call to the implementation
    function _executeWithToken(
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload,
        string calldata tokenSymbol,
        uint256 amount
    ) internal {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = implementation().delegatecall(
            abi.encodeWithSelector(
                ExpressProxy.executeWithToken.selector,
                bytes32(0),
                sourceChain,
                sourceAddress,
                payload,
                tokenSymbol,
                amount
            )
        );

        // if not success revert with the original revert data
        if (!success) {
            // solhint-disable-next-line no-inline-assembly
            assembly {
                let ptr := mload(0x40)
                let size := returndatasize()
                returndatacopy(ptr, 0, size)
                revert(ptr, size)
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    error InvalidAccount();

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IAxelarGateway {
    /**********\
    |* Errors *|
    \**********/

    error NotSelf();
    error NotProxy();
    error InvalidCodeHash();
    error SetupFailed();
    error InvalidAuthModule();
    error InvalidTokenDeployer();
    error InvalidAmount();
    error InvalidChainId();
    error InvalidCommands();
    error TokenDoesNotExist(string symbol);
    error TokenAlreadyExists(string symbol);
    error TokenDeployFailed(string symbol);
    error TokenContractDoesNotExist(address token);
    error BurnFailed(string symbol);
    error MintFailed(string symbol);
    error InvalidSetMintLimitsParams();
    error ExceedMintLimit(string symbol);

    /**********\
    |* Events *|
    \**********/

    event TokenSent(
        address indexed sender,
        string destinationChain,
        string destinationAddress,
        string symbol,
        uint256 amount
    );

    event ContractCall(
        address indexed sender,
        string destinationChain,
        string destinationContractAddress,
        bytes32 indexed payloadHash,
        bytes payload
    );

    event ContractCallWithToken(
        address indexed sender,
        string destinationChain,
        string destinationContractAddress,
        bytes32 indexed payloadHash,
        bytes payload,
        string symbol,
        uint256 amount
    );

    event Executed(bytes32 indexed commandId);

    event TokenDeployed(string symbol, address tokenAddresses);

    event ContractCallApproved(
        bytes32 indexed commandId,
        string sourceChain,
        string sourceAddress,
        address indexed contractAddress,
        bytes32 indexed payloadHash,
        bytes32 sourceTxHash,
        uint256 sourceEventIndex
    );

    event ContractCallApprovedWithMint(
        bytes32 indexed commandId,
        string sourceChain,
        string sourceAddress,
        address indexed contractAddress,
        bytes32 indexed payloadHash,
        string symbol,
        uint256 amount,
        bytes32 sourceTxHash,
        uint256 sourceEventIndex
    );

    event TokenMintLimitUpdated(string symbol, uint256 limit);

    event OperatorshipTransferred(bytes newOperatorsData);

    event Upgraded(address indexed implementation);

    /********************\
    |* Public Functions *|
    \********************/

    function sendToken(
        string calldata destinationChain,
        string calldata destinationAddress,
        string calldata symbol,
        uint256 amount
    ) external;

    function callContract(
        string calldata destinationChain,
        string calldata contractAddress,
        bytes calldata payload
    ) external;

    function callContractWithToken(
        string calldata destinationChain,
        string calldata contractAddress,
        bytes calldata payload,
        string calldata symbol,
        uint256 amount
    ) external;

    function isContractCallApproved(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        address contractAddress,
        bytes32 payloadHash
    ) external view returns (bool);

    function isContractCallAndMintApproved(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        address contractAddress,
        bytes32 payloadHash,
        string calldata symbol,
        uint256 amount
    ) external view returns (bool);

    function validateContractCall(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes32 payloadHash
    ) external returns (bool);

    function validateContractCallAndMint(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes32 payloadHash,
        string calldata symbol,
        uint256 amount
    ) external returns (bool);

    /***********\
    |* Getters *|
    \***********/

    function authModule() external view returns (address);

    function tokenDeployer() external view returns (address);

    function tokenMintLimit(string memory symbol) external view returns (uint256);

    function tokenMintAmount(string memory symbol) external view returns (uint256);

    function allTokensFrozen() external view returns (bool);

    function implementation() external view returns (address);

    function tokenAddresses(string memory symbol) external view returns (address);

    function tokenFrozen(string memory symbol) external view returns (bool);

    function isCommandExecuted(bytes32 commandId) external view returns (bool);

    function adminEpoch() external view returns (uint256);

    function adminThreshold(uint256 epoch) external view returns (uint256);

    function admins(uint256 epoch) external view returns (address[] memory);

    /*******************\
    |* Admin Functions *|
    \*******************/

    function setTokenMintLimits(string[] calldata symbols, uint256[] calldata limits) external;

    function upgrade(
        address newImplementation,
        bytes32 newImplementationCodeHash,
        bytes calldata setupParams
    ) external;

    /**********************\
    |* External Functions *|
    \**********************/

    function setup(bytes calldata params) external;

    function execute(bytes calldata input) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IAxelarExecutable } from './IAxelarExecutable.sol';
import { IExpressRegistry } from './IExpressRegistry.sol';

interface IExpressProxy is IAxelarExecutable {
    error NotExpressRegistry();
    error InvalidTokenSymbol();
    error ExpressCallNotEnabled();

    function registry() external view returns (IExpressRegistry);

    function deployRegistry(bytes calldata registryCreationCode) external;

    function expressExecuteWithToken(
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload,
        string calldata tokenSymbol,
        uint256 amount
    ) external;

    function completeExecuteWithToken(
        address expressCaller,
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload,
        string calldata tokenSymbol,
        uint256 amount
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IExpressProxyFactory } from './IExpressProxyFactory.sol';

// This should be owned by the microservice that is paying for gas.
interface IGMPExpressService is IExpressProxyFactory {
    error InvalidOperator();
    error InvalidContractAddress();
    error InvalidTokenSymbol();
    error NotOperator();

    function expressOperator() external returns (address);

    function callWithToken(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        address contractAddress,
        bytes calldata payload,
        string calldata tokenSymbol,
        uint256 amount
    ) external;

    function withdraw(
        address payable receiver,
        address token,
        uint256 amount
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IAxelarGateway } from './IAxelarGateway.sol';

interface IExpressRegistry {
    error InvalidGateway();
    error NotExpressProxy();
    error AlreadyExpressCalled();

    function gateway() external returns (IAxelarGateway);

    function proxyCodeHash() external returns (bytes32);

    function registerExpressCallWithToken(
        address caller,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes32 payloadHash,
        string calldata tokenSymbol,
        uint256 amount
    ) external;

    function processExecuteWithToken(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload,
        string calldata tokenSymbol,
        uint256 amount
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IAxelarExecutable } from './IAxelarExecutable.sol';

interface IExpressExecutable is IAxelarExecutable {
    function enableExpressCallWithToken() external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IProxy } from '../interfaces/IProxy.sol';
import { IFinalProxy } from '../interfaces/IFinalProxy.sol';
import { Create3 } from '../deploy/Create3.sol';
import { BaseProxy } from './BaseProxy.sol';
import { Proxy } from './Proxy.sol';

// @notice FinalProxy is a proxy that can be upgraded to final implementation that uses less gas to proxy calls
contract FinalProxy is Proxy, IFinalProxy {
    bytes32 internal constant FINAL_IMPLEMENTATION_SALT = keccak256('final-implementation');

    constructor(
        address implementationAddress,
        address owner,
        bytes memory setupParams
    ) Proxy(implementationAddress, owner, setupParams) {}

    // @dev final implementation uses less gas to compute compared to using storage
    // that makes FinalProxy to be more efficient in proxying calls when final implementation is deployed
    function implementation() public view override(BaseProxy, IProxy) returns (address implementation_) {
        implementation_ = _finalImplementation();
        if (implementation_ == address(0)) {
            implementation_ = super.implementation();
        }
    }

    function isFinal() public view returns (bool) {
        return _finalImplementation() != address(0);
    }

    function _finalImplementation() internal view virtual returns (address implementation_) {
        // Computing address is cheaper than using storage
        implementation_ = Create3.deployedAddress(FINAL_IMPLEMENTATION_SALT, address(this));

        if (implementation_.code.length == 0) implementation_ = address(0);
    }

    function finalUpgrade(bytes memory bytecode, bytes calldata setupParams)
        public
        returns (address finalImplementation_)
    {
        address owner;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            owner := sload(_OWNER_SLOT)
        }
        if (msg.sender != owner) revert NotOwner();
        if (implementation() != address(0)) revert AlreadyInitialized();

        finalImplementation_ = Create3.deploy(FINAL_IMPLEMENTATION_SALT, bytecode);
        if (setupParams.length != 0) {
            // solhint-disable-next-line avoid-low-level-calls
            (bool success, ) = finalImplementation_.delegatecall(
                abi.encodeWithSelector(BaseProxy.setup.selector, setupParams)
            );
            if (!success) revert SetupFailed();
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC20 } from '../interfaces/IERC20.sol';

error TokenTransferFailed();
error NativeTransferFailed();

library SafeTokenCall {
    function safeCall(IERC20 token, bytes memory callData) internal {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returnData) = address(token).call(callData);
        bool transferred = success && (returnData.length == uint256(0) || abi.decode(returnData, (bool)));

        if (!transferred || address(token).code.length == 0) revert TokenTransferFailed();
    }
}

library SafeTokenTransfer {
    function safeTransfer(
        IERC20 token,
        address receiver,
        uint256 amount
    ) internal {
        SafeTokenCall.safeCall(token, abi.encodeWithSelector(IERC20.transfer.selector, receiver, amount));
    }
}

library SafeTokenTransferFrom {
    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        SafeTokenCall.safeCall(token, abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, amount));
    }
}

library SafeNativeTransfer {
    uint256 internal constant NATIVE_TRANSFER_GAS_LIMIT = 2300;

    function safeNativeTransfer(address receiver, uint256 amount) internal {
        bool success;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            success := call(NATIVE_TRANSFER_GAS_LIMIT, receiver, amount, 0, 0, 0, 0)
        }

        if (!success) revert NativeTransferFailed();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

error AlreadyDeployed();
error EmptyBytecode();
error DeployFailed();

contract CreateDeployer {
    function deploy(bytes memory bytecode) external {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            pop(create(0, add(bytecode, 32), mload(bytecode)))
        }

        selfdestruct(payable(msg.sender));
    }
}

library Create3 {
    bytes32 internal constant DEPLOYER_BYTECODE_HASH = keccak256(type(CreateDeployer).creationCode);

    function deploy(bytes32 salt, bytes memory bytecode) internal returns (address deployed) {
        deployed = deployedAddress(salt, address(this));

        if (deployed.code.length != 0) revert AlreadyDeployed();
        if (bytecode.length == 0) revert EmptyBytecode();

        // CREATE2
        CreateDeployer deployer = new CreateDeployer{ salt: salt }();

        if (address(deployer) == address(0)) revert DeployFailed();

        deployer.deploy(bytecode);

        if (deployed.code.length == 0) revert DeployFailed();
    }

    function deployedAddress(bytes32 salt, address host) internal pure returns (address deployed) {
        address deployer = address(
            uint160(uint256(keccak256(abi.encodePacked(hex'ff', host, salt, DEPLOYER_BYTECODE_HASH))))
        );

        deployed = address(uint160(uint256(keccak256(abi.encodePacked(hex'd6_94', deployer, hex'01')))));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IAxelarGateway } from './IAxelarGateway.sol';

interface IAxelarExecutable {
    error InvalidAddress();
    error NotApprovedByGateway();

    function gateway() external view returns (IAxelarGateway);

    function execute(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload
    ) external;

    function executeWithToken(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload,
        string calldata tokenSymbol,
        uint256 amount
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IAxelarExecutable } from './IAxelarExecutable.sol';

// This should be owned by the microservice that is paying for gas.
interface IExpressProxyFactory is IAxelarExecutable {
    error NotExpressProxy();
    error InvalidSourceAddress();
    error InvalidCommand();
    error FailedDeploy();
    error EmptyBytecode();
    error WrongGasAmounts();

    function isExpressProxy(address proxyAddress) external view returns (bool);

    function deployedProxyAddress(bytes32 salt, address sender) external view returns (address deployedAddress);

    function deployExpressProxy(
        bytes32 salt,
        address implementationAddress,
        address owner,
        bytes calldata setupParams
    ) external returns (address);

    function deployExpressExecutable(
        bytes32 salt,
        bytes memory implementationBytecode,
        address owner,
        bytes calldata setupParams
    ) external returns (address);

    function deployExpressExecutableOnChains(
        bytes32 salt,
        bytes memory implementationBytecode,
        address owner,
        bytes calldata setupParams,
        string[] calldata destinationChains,
        uint256[] calldata gasPayments,
        address gasRefundAddress
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// General interface for upgradable contracts
interface IProxy {
    error InvalidOwner();
    error InvalidImplementation();
    error SetupFailed();
    error NotOwner();
    error AlreadyInitialized();

    function implementation() external view returns (address implementation_);

    function setup(bytes calldata setupParams) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IProxy } from './IProxy.sol';

// General interface for upgradable contracts
interface IFinalProxy is IProxy {
    function isFinal() external view returns (bool);

    function finalUpgrade(bytes memory bytecode, bytes calldata setupParams) external returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IProxy } from '../interfaces/IProxy.sol';
import { IUpgradable } from '../interfaces/IUpgradable.sol';

abstract contract BaseProxy is IProxy {
    // bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1)
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
    // keccak256('owner')
    bytes32 internal constant _OWNER_SLOT = 0x02016836a56b71f0d02689e69e326f4f4c1b9057164ef592671cf0d37c8040c0;

    function implementation() public view virtual returns (address implementation_) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            implementation_ := sload(_IMPLEMENTATION_SLOT)
        }
    }

    // solhint-disable-next-line no-empty-blocks
    function setup(bytes calldata setupParams) external {}

    function contractId() internal pure virtual returns (bytes32) {
        return bytes32(0);
    }

    // solhint-disable-next-line no-complex-fallback
    fallback() external payable virtual {
        address implementaion_ = implementation();
        // solhint-disable-next-line no-inline-assembly
        assembly {
            calldatacopy(0, 0, calldatasize())

            let result := delegatecall(gas(), implementaion_, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())

            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    // solhint-disable-next-line no-empty-blocks
    receive() external payable virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IProxy } from '../interfaces/IProxy.sol';
import { IUpgradable } from '../interfaces/IUpgradable.sol';
import { BaseProxy } from './BaseProxy.sol';

contract Proxy is BaseProxy {
    constructor(
        address implementationAddress,
        address owner,
        bytes memory setupParams
    ) {
        if (owner == address(0)) revert InvalidOwner();
        if (implementation() != address(0)) revert AlreadyInitialized();

        bytes32 id = contractId();
        if (id != bytes32(0) && IUpgradable(implementationAddress).contractId() != id) revert InvalidImplementation();

        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(_IMPLEMENTATION_SLOT, implementationAddress)
            sstore(_OWNER_SLOT, owner)
        }

        if (setupParams.length != 0) {
            // solhint-disable-next-line avoid-low-level-calls
            (bool success, ) = implementationAddress.delegatecall(
                abi.encodeWithSelector(IUpgradable.setup.selector, setupParams)
            );
            if (!success) revert SetupFailed();
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IOwnable } from './IOwnable.sol';

// General interface for upgradable contracts
interface IUpgradable is IOwnable {
    error InvalidCodeHash();
    error InvalidImplementation();
    error SetupFailed();
    error NotProxy();

    event Upgraded(address indexed newImplementation);

    function implementation() external view returns (address);

    function upgrade(
        address newImplementation,
        bytes32 newImplementationCodeHash,
        bytes calldata params
    ) external;

    function setup(bytes calldata data) external;

    function contractId() external pure returns (bytes32);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// General interface for upgradable contracts
interface IOwnable {
    error NotOwner();
    error InvalidOwner();

    event OwnershipTransferStarted(address indexed newOwner);
    event OwnershipTransferred(address indexed newOwner);

    // Get current owner
    function owner() external view returns (address);

    // Get pending ownership transfer
    function pendingOwner() external view returns (address);

    function transferOwnership(address newOwner) external;

    function acceptOwnership() external;
}