// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "../interfaces/0.8.x/IEngineRegistryV0.sol";
import "@openzeppelin-4.7/contracts/utils/introspection/ERC165.sol";

/**
 * @title Engine Registry contract, V0.
 * @author Art Blocks Inc.
 * @notice Privileged Roles and Ownership:
 * This contract intentionally has no owners or admins, and is intended
 * to be deployed with a permissioned `deployerAddress` that may speak
 * to this registry. If in the future multiple deployer addresses are
 * needed to interact with this registry, a new registry version with
 * more complex logic should be implemented and deployed to replace this.
 */
contract EngineRegistryV0 is IEngineRegistryV0, ERC165 {
    /// configuration variable (determined at time of deployment)
    /// that determines what address may perform registration actions.
    address internal immutable deployerAddress;

    /// internal mapping for managing known list of registered contracts.
    mapping(address => bool) internal registeredContractAddresses;

    constructor() {
        // The deployer of the registry becomes the permissioned deployer for speaking to the registry.
        deployerAddress = tx.origin;
    }

    /**
     * @inheritdoc IEngineRegistryV0
     */
    function registerContract(
        address _contractAddress,
        bytes32 _coreVersion,
        bytes32 _coreType
    ) external {
        // CHECKS
        // Validate against `tx.origin` rather than `msg.sender` as it is intended that this registration be
        // performed in an automated fashion *at the time* of contract deployment for the `_contractAddress`.
        require(
            tx.origin == deployerAddress,
            "Only allowed deployer-address TX origin"
        );

        // EFFECTS
        emit ContractRegistered(_contractAddress, _coreVersion, _coreType);
        registeredContractAddresses[_contractAddress] = true;
    }

    /**
     * @inheritdoc IEngineRegistryV0
     */
    function unregisterContract(address _contractAddress) external {
        // CHECKS
        // Validate against `tx.origin` rather than `msg.sender` for consistency with the above approach,
        // as we expect in usage of this contract `msg.sender == tx.origin` to be a true assessment.
        require(
            tx.origin == deployerAddress,
            "Only allowed deployer-address TX origin"
        );
        require(
            registeredContractAddresses[_contractAddress],
            "Only unregister already registered contracts"
        );

        // EFFECTS
        emit ContractUnregistered(_contractAddress);
        registeredContractAddresses[_contractAddress] = false;
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
// Created By: Art Blocks Inc.
pragma solidity ^0.8.17;

interface IEngineRegistryV0 {
    /// ADDRESS
    /**
     * @notice contract has been registered as a contract that is powered by the Art Blocks Engine.
     */
    event ContractRegistered(
        address indexed _contractAddress,
        bytes32 _coreVersion,
        bytes32 _coreType
    );

    /// ADDRESS
    /**
     * @notice contract has been unregistered as a contract that is powered by the Art Blocks Engine.
     */
    event ContractUnregistered(address indexed _contractAddress);

    /**
     * @notice Emits a `ContractRegistered` event with the provided information.
     * @dev this function should be gated to only deployer addresses.
     */
    function registerContract(
        address _contractAddress,
        bytes32 _coreVersion,
        bytes32 _coreType
    ) external;

    /**
     * @notice Emits a `ContractUnregistered` event with the provided information, validating that the provided
     *         address was indeed previously registered.
     * @dev this function should be gated to only deployer addresses.
     */
    function unregisterContract(address _contractAddress) external;
}