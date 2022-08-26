// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.16;

/**
 * @title IERC165
 * @notice Support of ERC165.
 */
interface IERC165 {
    /**
     * @notice Query if a contract implements an interface
     *
     * @param interfaceID The interface identifier, as specified in ERC-165
     *
     * @dev Interface identification is specified in ERC-165. This function
     * uses less than 30,000 gas.
     *
     * @return `true` if the contract implements `interfaceID` and
     * interfaceID` is not 0xffffffff, `false` otherwise
     */
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.16;

import "../proxies/LaserProxy.sol";

/**
 * @title  LaserFactory
 *
 * @notice Factory that creates new Laser proxies, and has helper methods.
 *
 * @dev    This interface has all events, errors, and external function for LaserFactory.
 */
interface ILaserFactory {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event LaserCreated(address laser);

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    error LF__constructor__invalidSingleton();

    error LF__createProxy__creationFailed();

    error LF__deployProxy__create2Failed();

    /*//////////////////////////////////////////////////////////////
                                 STATE
    //////////////////////////////////////////////////////////////*/

    function singleton() external view returns (address);

    /*//////////////////////////////////////////////////////////////
                                EXTERNAL
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Allows to create new proxy contact and execute a message call to the new proxy within one transaction.
     *
     * @param initializer   Payload for message call sent to new proxy contract.
     * @param saltNonce     Nonce that will be used to generate the salt to calculate the address of the new proxy contract.
     */
    function createProxy(bytes memory initializer, uint256 saltNonce) external returns (LaserProxy proxy);

    /**
     * @dev Precomputes the address of a proxy that is created through 'create2'.
     */
    function preComputeAddress(bytes memory initializer, uint256 saltNonce) external view returns (address);

    /**
     * @dev Allows to retrieve the runtime code of a deployed Proxy. This can be used to check that the expected Proxy was deployed.
     */
    function proxyRuntimeCode() external pure returns (bytes memory);

    /**
     *  @dev Allows to retrieve the creation code used for the Proxy deployment. With this it is easily possible to calculate predicted address.
     */
    function proxyCreationCode() external pure returns (bytes memory);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.16;

struct Transaction {
    address to;
    uint256 value;
    bytes callData;
    uint256 nonce;
    bytes signatures;
}

/**
 * @title  ILaserWallet
 *
 * @author Rodrigo Herrera I.
 *
 * @notice Laser is a secure smart contract wallet (vault) made for the Ethereum Virtual Machine.
 *
 * @dev    This interface has all events, errors, and external function for LaserWallet.
 */
interface ILaserWallet {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event ExecSuccess(address to, uint256 value, uint256 nonce, bytes4 funcSig);

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    error LW__init__notOwner();

    error LW__exec__invalidNonce();

    error LW__exec__walletLocked();

    error LW__exec__invalidSignatureLength();

    error LW__exec__invalidSignature();

    error LW__exec__callFailed();

    error LW__recovery__invalidNonce();

    error LW__recovery__invalidSignatureLength();

    error LW__recovery__duplicateSigner();

    error LW__recoveryLock__invalidSignature();

    error LW__recoveryUnlock__invalidSignature();

    error LW__recoveryRecover__invalidSignature();

    error LW__recovery__invalidOperation();

    error LW__recovery__callFailed();

    error LaserWallet__invalidSignature();

    /*//////////////////////////////////////////////////////////////
                                EXTERNAL
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Setup function, sets initial storage of the wallet.
     *         It can't be called after initialization.
     *
     * @param _owner           The owner of the wallet.
     * @param _guardians       Array of guardians.
     * @param _recoveryOwners  Array of recovery owners.
     * @param ownerSignature   Signature of the owner that validates the correctness of the address.
     */
    function init(
        address _owner,
        address[] calldata _guardians,
        address[] calldata _recoveryOwners,
        bytes calldata ownerSignature
    ) external;

    /**
     * @notice Executes a generic transaction.
     *         The transaction is required to be signed by the owner + recovery owner or owner + guardian
     *         while the wallet is not locked.
     *
     * @param to         Destination address.
     * @param value      Amount in WEI to transfer.
     * @param callData   Data payload to send.
     * @param _nonce     Anti-replay number.
     * @param signatures Signatures of the hash of the transaction.
     */
    function exec(
        address to,
        uint256 value,
        bytes calldata callData,
        uint256 _nonce,
        bytes calldata signatures
    ) external returns (bool success);

    /**
     * @notice Executes a batch of transactions.
     *
     * @param transactions An array of Laser transactions.
     */
    function multiCall(Transaction[] calldata transactions) external;

    /**
     * @notice Triggers the recovery mechanism.
     *
     * @param callData   Data payload, can only be either lock(), unlock() or recover().
     * @param signatures Signatures of the hash of the transaction.
     */
    function recovery(
        uint256 _nonce,
        bytes calldata callData,
        bytes calldata signatures
    ) external;

    /**
     * @notice Returns the hash to be signed to execute a transaction.
     */
    function operationHash(
        address to,
        uint256 value,
        bytes calldata callData,
        uint256 _nonce
    ) external view returns (bytes32);

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
     * @return Magic value.
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4);

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

    /**
     * @param _singleton Base contract.
     */
    constructor(address _singleton) {
        // Laser Wallet contract: bytes4(keccak256("I_AM_LASER"))
        if (!IERC165(_singleton).supportsInterface(0xae029e0b)) {
            revert LF__constructor__invalidSingleton();
        }
        singleton = _singleton;
    }

    /**
     * @dev Allows to create new proxy contact and execute a message call to the new proxy within one transaction.
     *
     * @param initializer   Payload for message call sent to new proxy contract.
     * @param saltNonce     Nonce that will be used to generate the salt to calculate the address of the new proxy contract.
     */
    function createProxy(bytes memory initializer, uint256 saltNonce) external returns (LaserProxy proxy) {
        proxy = deployProxy(initializer, saltNonce);

        bool success;
        assembly {
            // We initialize the wallet in a single call.
            success := call(gas(), proxy, 0, add(initializer, 0x20), mload(initializer), 0, 0)
        }

        if (!success) revert LF__createProxy__creationFailed();

        emit LaserCreated(address(proxy));
    }

    /**
     * @dev Precomputes the address of a proxy that is created through 'create2'.
     */
    function preComputeAddress(bytes memory initializer, uint256 saltNonce) external view returns (address) {
        bytes memory creationCode = proxyCreationCode();
        bytes memory data = abi.encodePacked(creationCode, uint256(uint160(singleton)));

        bytes32 salt = keccak256(abi.encodePacked(keccak256(initializer), saltNonce));

        bytes32 hash = keccak256(abi.encodePacked(bytes1(0xff), address(this), salt, keccak256(data)));

        return address(uint160(uint256(hash)));
    }

    /**
     * @dev Allows to retrieve the runtime code of a deployed Proxy. This can be used to check that the expected Proxy was deployed.
     */
    function proxyRuntimeCode() external pure returns (bytes memory) {
        return type(LaserProxy).runtimeCode;
    }

    /**
     *  @dev Allows to retrieve the creation code used for the Proxy deployment. With this it is easily possible to calculate predicted address.
     */
    function proxyCreationCode() public pure returns (bytes memory) {
        return type(LaserProxy).creationCode;
    }

    /**
     * @notice Allows to create new proxy contact using CREATE2 but it doesn't run the initializer.
     *         This method is only meant as an utility to be called from other methods.
     *
     * @param initializer Payload for message call sent to new proxy contract.
     * @param saltNonce Nonce that will be used to generate the salt to calculate the address of the new proxy contract.
     */
    function deployProxy(bytes memory initializer, uint256 saltNonce) internal returns (LaserProxy proxy) {
        // If the initializer changes the proxy address should change too. Hashing the initializer data is cheaper than just concatinating it
        bytes32 salt = keccak256(abi.encodePacked(keccak256(initializer), saltNonce));

        bytes memory deploymentData = abi.encodePacked(type(LaserProxy).creationCode, uint256(uint160(singleton)));

        assembly {
            proxy := create2(0x0, add(0x20, deploymentData), mload(deploymentData), salt)
        }

        if (address(proxy) == address(0)) revert LF__deployProxy__create2Failed();
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