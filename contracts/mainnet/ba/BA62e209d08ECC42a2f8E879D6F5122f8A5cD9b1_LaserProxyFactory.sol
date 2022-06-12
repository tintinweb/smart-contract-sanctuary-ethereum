// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.14;

import "../interfaces/IERC165.sol";
import "../interfaces/IProxyFactory.sol";

/**
 * @title Proxy Factory - Allows to create new proxy contact and execute a message call to the new proxy within one transaction.
 */
contract LaserProxyFactory is IProxyFactory {
    address public immutable singleton;

    /**
     * @param _singleton Master copy of the proxy.
     */
    constructor(address _singleton) {
        // Laser Wallet contract: bytes4(keccak256("I_AM_LASER"))
        if (!IERC165(_singleton).supportsInterface(0xae029e0b))
            revert ProxyFactory__constructor__invalidSingleton();
        singleton = _singleton;
    }

    /**
     * @dev Allows to create new proxy contact and execute a message call to the new proxy within one transaction.
     * @param data Payload for message call sent to new proxy contract.
     */
    function createProxy(bytes memory data)
        external
        returns (LaserProxy proxy)
    {
        proxy = new LaserProxy(singleton);
        if (data.length > 0)
            // solhint-disable-next-line no-inline-assembly
            assembly {
                if eq(
                    call(gas(), proxy, 0, add(data, 0x20), mload(data), 0, 0),
                    0
                ) {
                    revert(0, 0)
                }
            }
        emit ProxyCreation(address(proxy), singleton);
    }

    /**
     * @dev Allows to create new proxy contact and execute a message call to the new proxy within one transaction.
     * @param initializer Payload for message call sent to new proxy contract.
     * @param saltNonce Nonce that will be used to generate the salt to calculate the address of the new proxy contract.
     */
    function createProxyWithNonce(bytes memory initializer, uint256 saltNonce)
        external
        returns (LaserProxy proxy)
    {
        proxy = deployProxyWithNonce(initializer, saltNonce);

        if (initializer.length > 0)
            assembly {
                if eq(
                    call(
                        gas(),
                        proxy,
                        0,
                        add(initializer, 0x20),
                        mload(initializer),
                        0,
                        0
                    ),
                    0
                ) {
                    revert(0, 0)
                }
            }
        emit ProxyCreation(address(proxy), singleton);
    }

    /**
     * @dev Precomputes the address of a proxy that is created through 'create2'.
     */
    function preComputeAddress(bytes memory initializer, uint256 saltNonce)
        external
        view
        returns (address)
    {
        bytes memory creationCode = proxyCreationCode();
        bytes memory data = abi.encodePacked(
            creationCode,
            uint256(uint160(singleton))
        );

        bytes32 salt = keccak256(
            abi.encodePacked(keccak256(initializer), saltNonce)
        );

        bytes32 hash = keccak256(
            abi.encodePacked(bytes1(0xff), address(this), salt, keccak256(data))
        );

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
     * @dev Allows to create new proxy contact using CREATE2 but it doesn't run the initializer.
     * This method is only meant as an utility to be called from other methods.
     * @param initializer Payload for message call sent to new proxy contract.
     * @param saltNonce Nonce that will be used to generate the salt to calculate the address of the new proxy contract.
     */
    function deployProxyWithNonce(bytes memory initializer, uint256 saltNonce)
        internal
        returns (LaserProxy proxy)
    {
        // If the initializer changes the proxy address should change too. Hashing the initializer data is cheaper than just concatinating it
        bytes32 salt = keccak256(
            abi.encodePacked(keccak256(initializer), saltNonce)
        );

        bytes memory deploymentData = abi.encodePacked(
            type(LaserProxy).creationCode,
            uint256(uint160(singleton))
        );
        assembly {
            proxy := create2(
                0x0,
                add(0x20, deploymentData),
                mload(deploymentData),
                salt
            )
        }
        require(address(proxy) != address(0), "Create2 call failed");
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.14;

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
pragma solidity 0.8.14;

import "../proxies/LaserProxy.sol";

/**
 * @title IProxyFactory
 * @notice Has all the external functions, events and errors for ProxyFactory.sol.
 */

interface IProxyFactory {
    event ProxyCreation(address proxy, address singleton);

    ///@dev constructor() custom error.
    error ProxyFactory__constructor__invalidSingleton();

    /**
     * @dev Allows to create new proxy contact and execute a message call to the new proxy within one transaction.
     * @param data Payload for message call sent to new proxy contract.
     */
    function createProxy(bytes memory data) external returns (LaserProxy proxy);

    /**
     * @dev Allows to create new proxy contact and execute a message call to the new proxy within one transaction.
     * @param initializer Payload for message call sent to new proxy contract.
     * @param saltNonce Nonce that will be used to generate the salt to calculate the address of the new proxy contract.
     */
    function createProxyWithNonce(bytes memory initializer, uint256 saltNonce)
        external
        returns (LaserProxy proxy);

    /**
     * @dev Precomputes the address of a proxy that is created through 'create2'.
     */
    function preComputeAddress(bytes memory initializer, uint256 saltNonce)
        external
        view
        returns (address);

    /**
     * @dev Allows to retrieve the runtime code of a deployed Proxy. This can be used to check that the expected Proxy was deployed.
     */
    function proxyRuntimeCode() external pure returns (bytes memory);

    /**
     *  @dev Allows to retrieve the creation code used for the Proxy deployment. With this it is easily possible to calculate predicted address.
     */
    function proxyCreationCode() external pure returns (bytes memory);
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.14;

/**
 * @title LaserProxy - Proxy contract that delegates all calls to a master copy.
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
            let success := delegatecall(
                gas(),
                _singleton,
                0,
                calldatasize(),
                0,
                0
            )
            returndatacopy(0, 0, returndatasize())
            if eq(success, 0) {
                revert(0, returndatasize())
            }
            return(0, returndatasize())
        }
    }
}