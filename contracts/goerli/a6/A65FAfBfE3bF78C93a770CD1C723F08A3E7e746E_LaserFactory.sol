// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.16;

/**
 * @title IERC165
 * @notice Support of ERC165.
 */
interface IERC165 {
    /**
     * @notice Query if a contract implements an interface
     * @param interfaceID The interface identifier, as specified in ERC-165
     * @dev Interface identification is specified in ERC-165. This function
     * uses less than 30,000 gas.
     * @return `true` if the contract implements `interfaceID` and
     * interfaceID` is not 0xffffffff, `false` otherwise
     */
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.16;

import "../proxies/LaserProxy.sol";

interface ILaserFactory {
    event ProxyCreation(address proxy);

    ///@dev constructor() custom error.
    error LaserFactory__constructor__invalidSingleton();

    ///@dev createProxyWithCreate2() custom error.
    error LaserFactory__create2Failed();

    ///@dev Creates a new proxy with create 2, initializes the wallet and refunds the relayer.
    function deployProxyAndRefund(
        address owner,
        uint256 maxFeePerGas,
        uint256 maxPriorityFeePerGas,
        uint256 gasLimit,
        address relayer,
        address smartSocialRecoveryModule,
        address laserVault,
        bytes calldata smartSocialRecoveryInitData,
        uint256 saltNumber,
        bytes memory ownerSignature
    ) external returns (LaserProxy proxy);

    ///@dev Precomputes the address of a proxy that is created through 'create2'.
    function preComputeAddress(
        address owner,
        address laserModule,
        bytes calldata laserModuleData,
        uint256 saltNumber
    ) external view returns (address);

    ///@dev Allows to retrieve the runtime code of a deployed Proxy. This can be used to check that the expected Proxy was deployed.
    function proxyRuntimeCode() external pure returns (bytes memory);

    ///@dev Allows to retrieve the creation code used for the Proxy deployment. With this it is easily possible to calculate predicted address.
    function proxyCreationCode() external pure returns (bytes memory);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.16;

/**
 * @title  ILaserWallet
 *
 * @author Rodrigo Herrera I.
 *
 * @notice Laser is a modular smart contract wallet made for the Ethereum Virtual Machine.
 *         It has modularity (programmability) and security at its core.
 *
 * @dev    This interface has all events, errors, and external function for LaserWallet.
 */
interface ILaserWallet {
    event Setup(address owner, address laserModule);
    event ExecSuccess(address to, uint256 value, uint256 nonce);
    event ExecFailure(address to, uint256 value, uint256 nonce);

    // init() custom errors.
    error LW__init__notOwner();
    error LW__init__refundFailure();

    // exec() custom errors.
    error LW__exec__invalidNonce();
    error LW__exec__walletLocked();
    error LW__exec__notOwner();
    error LW__exec__refundFailure();

    // execFromModule() custom errors.
    error LW__execFromModule__unauthorizedModule();
    error LW__execFromModule__mainCallFailed();
    error LW__execFromModule__refundFailure();

    // simulateTransaction() custom errors.
    error LW__SIMULATION__invalidNonce();
    error LW__SIMULATION__walletLocked();
    error LW__SIMULATION__notOwner();
    error LW__SIMULATION__refundFailure();

    // isValidSignature() Laser custom error.
    error LaserWallet__invalidSignature();

    struct Transaction {
        address to;
        uint256 value;
        bytes callData;
        uint256 nonce;
        uint256 maxFeePerGas;
        uint256 maxPriorityFeePerGas;
        uint256 gasLimit;
        address relayer;
        bytes signatures;
    }

    /**
     * @notice Setup function, sets initial storage of the wallet.
     *         It can't be called after initialization.
     *
     * @param _owner                        The owner of the wallet.
     * @param maxFeePerGas                  Maximum WEI the owner is willing to pay per unit of gas.
     * @param maxPriorityFeePerGas          Miner's tip.
     * @param gasLimit                      Maximum amount of gas the owner is willing to use for this transaction.
     * @param relayer                       Address to refund for the inclusion of this transaction.
     * @param smartSocialRecoveryModule     Address of the initial module to setup -> Smart Social Recovery.
     * @param _laserMasterGuard             Address of the parent guard module 'LaserMasterGuard'.
     * @param laserVault                    Address of the guard sub-module 'LaserVault'.
     * @param _laserRegistry                Address of the Laser registry: module that keeps track of authorized modules.
     * @param smartSocialRecoveryInitData   Initialization data for the provided module.
     * @param ownerSignature                Signature of the owner that validates approval for initialization.
     */
    function init(
        address _owner,
        uint256 maxFeePerGas,
        uint256 maxPriorityFeePerGas,
        uint256 gasLimit,
        address relayer,
        address smartSocialRecoveryModule,
        address _laserMasterGuard,
        address laserVault,
        address _laserRegistry,
        bytes calldata smartSocialRecoveryInitData,
        bytes memory ownerSignature
    ) external;

    /**
     * @notice Executes a generic transaction.
     *         If 'gasLimit' does not match the actual gas limit of the transaction, the relayer can incur losses.
     *         It is the relayer's responsability to make sure that they are the same,
     *         the user does not get affected if a mistake is made.
     *
     * @param to                    Destination address.
     * @param value                 Amount in WEI to transfer.
     * @param callData              Data payload for the transaction.
     * @param _nonce                Anti-replay number.
     * @param maxFeePerGas          Maximum WEI the owner is willing to pay per unit of gas.
     * @param maxPriorityFeePerGas  Miner's tip.
     * @param gasLimit              Maximum amount of gas the owner is willing to use for this transaction.
     * @param relayer               Address to refund for the inclusion of this transaction.
     * @param signatures            The signature(s) of the hash for this transaction.
     */
    function exec(
        address to,
        uint256 value,
        bytes calldata callData,
        uint256 _nonce,
        uint256 maxFeePerGas,
        uint256 maxPriorityFeePerGas,
        uint256 gasLimit,
        address relayer,
        bytes calldata signatures
    ) external returns (bool success);

    /**
     * @notice Executes a transaction from an authorized module.
     *         If 'gasLimit' does not match the actual gas limit of the transaction, the relayer can incur losses.
     *         It is the relayer's responsability to make sure that they are the same,
     *         the user does not get affected if a mistake is made.
     *
     * @param to                    Destination address.
     * @param value                 Amount in WEI to transfer.
     * @param callData              Data payload for the transaction.
     * @param maxFeePerGas          Maximum WEI the owner is willing to pay per unit of gas.
     * @param maxPriorityFeePerGas  Miner's tip.
     * @param gasLimit              Maximum amount of gas the owner is willing to use for this transaction.
     * @param relayer               Address to refund for the inclusion of this transaction.
     */
    function execFromModule(
        address to,
        uint256 value,
        bytes calldata callData,
        uint256 maxFeePerGas,
        uint256 maxPriorityFeePerGas,
        uint256 gasLimit,
        address relayer
    ) external;

    /**
     * @notice Simulates a transaction.
     *         It needs to be called off-chain from address(0).
     *
     * @param to                    Destination address.
     * @param value                 Amount in WEI to transfer.
     * @param callData              Data payload for the transaction.
     * @param _nonce                Anti-replay number.
     * @param maxFeePerGas          Maximum WEI the owner is willing to pay per unit of gas.
     * @param maxPriorityFeePerGas  Miner's tip.
     * @param gasLimit              Maximum amount of gas the owner is willing to use for this transaction.
     * @param relayer               Address to refund for the inclusion of this transaction.
     * @param signatures            The signature(s) of the hash of this transaction.
     *
     * @return gasUsed The gas used for this transaction.
     */
    function simulateTransaction(
        address to,
        uint256 value,
        bytes calldata callData,
        uint256 _nonce,
        uint256 maxFeePerGas,
        uint256 maxPriorityFeePerGas,
        uint256 gasLimit,
        address relayer,
        bytes calldata signatures
    ) external returns (uint256 gasUsed);

    /**
     * @notice Locks the wallet. Once locked, only the SSR module can unlock it or recover it.
     *
     * @dev Can only be called by address(this).
     */
    function lock() external;

    /**
     * @notice Unlocks the wallet. Can only be unlocked or recovered from the SSR module.
     *
     * @dev Can only be called by address(this).
     */
    function unlock() external;

    /**
     * @notice Should return whether the signature provided is valid for the provided hash.
     *
     * @param hash      Hash of the data to be signed.
     * @param signature Signature byte array associated with hash.
     *
     * MUST return the bytes4 magic value 0x1626ba7e when function passes.
     * MUST NOT modify state (using STATICCALL for solc < 0.5, view modifier for solc > 0.5)
     * MUST allow external calls
     *
     * @return Magic value if signature matches the owner's address and the wallet is not locked.
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4);

    /**
     * @notice Returns the hash to be signed to execute a transaction.
     */
    function operationHash(
        address to,
        uint256 value,
        bytes calldata callData,
        uint256 _nonce,
        uint256 maxFeePerGas,
        uint256 maxPriorityFeePerGas,
        uint256 gasLimit
    ) external view returns (bytes32);

    /**
     * @return chainId The chain id of this.
     */
    function getChainId() external view returns (uint256 chainId);

    /**
     * @notice Domain separator for this wallet.
     */
    function domainSeparator() external view returns (bytes32);
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.16;

import "../interfaces/IERC165.sol";
import "../interfaces/ILaserFactory.sol";
import "../interfaces/ILaserWallet.sol";

/**
 * @title LaserFactory
 *
 * @notice Factory that creates new Laser proxies, and has helper methods.
 */
contract LaserFactory is ILaserFactory {
    address public immutable singleton;

    address public immutable laserRegistry;

    address public immutable laserMasterGuard;

    /// @param _singleton Master copy of the proxy.
    constructor(
        address _singleton,
        address _laserRegistry,
        address _laserMasterGuard
    ) {
        // Laser Wallet contract: bytes4(keccak256("I_AM_LASER"))
        if (!IERC165(_singleton).supportsInterface(0xae029e0b)) revert LaserFactory__constructor__invalidSingleton();
        singleton = _singleton;
        laserRegistry = _laserRegistry;
        laserMasterGuard = _laserMasterGuard;
    }

    function deployProxyAndRefund(
        address owner,
        uint256 maxFeePerGas,
        uint256 maxPriorityFeePerGas,
        uint256 gasLimit,
        address relayer,
        address smartSocialRecoveryModule,
        address laserVault,
        bytes memory smartSocialRecoveryInitData,
        uint256 saltNumber,
        bytes memory ownerSignature
    ) external returns (LaserProxy proxy) {
        {
            bytes32 salt = getSalt(owner, smartSocialRecoveryModule, smartSocialRecoveryInitData, saltNumber);
            proxy = createProxyWithCreate2(salt);

            ILaserWallet(address(proxy)).init(
                owner,
                maxFeePerGas,
                maxPriorityFeePerGas,
                gasLimit,
                relayer,
                smartSocialRecoveryModule,
                laserMasterGuard,
                laserVault,
                laserRegistry,
                smartSocialRecoveryInitData,
                ownerSignature
            );

            emit ProxyCreation(address(proxy));
        }
    }

    ///@dev Precomputes the address of a proxy that is created through 'create2'.
    function preComputeAddress(
        address owner,
        address laserModule,
        bytes calldata laserModuleData,
        uint256 saltNumber
    ) external view returns (address) {
        bytes memory creationCode = proxyCreationCode();
        bytes memory data = abi.encodePacked(creationCode, uint256(uint160(singleton)));

        bytes32 salt = getSalt(owner, laserModule, laserModuleData, saltNumber);
        bytes32 hash = keccak256(abi.encodePacked(bytes1(0xff), address(this), salt, keccak256(data)));

        return address(uint160(uint256(hash)));
    }

    ///@dev Allows to retrieve the runtime code of a deployed Proxy. This can be used to check that the expected Proxy was deployed.
    function proxyRuntimeCode() external pure returns (bytes memory) {
        return type(LaserProxy).runtimeCode;
    }

    ///@dev Allows to retrieve the creation code used for the Proxy deployment. With this it is easily possible to calculate predicted address.
    function proxyCreationCode() public pure returns (bytes memory) {
        return type(LaserProxy).creationCode;
    }

    ///@dev Allows to create new proxy contact using CREATE2 but it doesn't run the initializer.
    ///This method is only meant as an utility to be called from other methods.
    function createProxyWithCreate2(bytes32 salt) internal returns (LaserProxy proxy) {
        bytes memory deploymentData = abi.encodePacked(type(LaserProxy).creationCode, uint256(uint160(singleton)));
        assembly {
            proxy := create2(0x0, add(0x20, deploymentData), mload(deploymentData), salt)
        }
        //@todo change the custom error name.
        if (address(proxy) == address(0)) revert LaserFactory__create2Failed();
    }

    /**
     * @dev Generates the salt for deployment.
     */
    function getSalt(
        address owner,
        address laserModule,
        bytes memory laserModuleData,
        uint256 saltNumber
    ) internal pure returns (bytes32 salt) {
        salt = keccak256(abi.encodePacked(owner, laserModule, laserModuleData, saltNumber));
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.16;

/**
 * @title LaserProxy
 *
 * @notice Proxy contract that delegates all calls to a master copy.
 */
contract LaserProxy {
    // The singleton always needs to be at storage slot 0.
    address internal singleton;

    /**
     * @param _singleton Singleton address.
     */
    constructor(address _singleton) {
        // The proxy creation is done through the LaserProxyFactory.
        // The singleton is created at the factory's creation, so there is no need to do checks here.
        singleton = _singleton;
    }

    /**
     * @dev Fallback function forwards all transactions and returns all received return data.
     */
    fallback() external payable {
        address _singleton = singleton;
        assembly {
            calldatacopy(0, 0, calldatasize())
            let success := delegatecall(gas(), _singleton, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            if eq(success, 0) {
                revert(0, returndatasize())
            }
            return(0, returndatasize())
        }
    }
}