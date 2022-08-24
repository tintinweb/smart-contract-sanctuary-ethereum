// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {INounletRegistry as IRegistry} from "../interfaces/INounletRegistry.sol";
import {INounletSupply as ISupply} from "../interfaces/INounletSupply.sol";

/// @title NounletSupply
/// @author Fractional Art
/// @notice Target contract for minting and burning fractions
contract NounletSupply is ISupply {
    /// @notice Address of NounletRegistry contract
    address public immutable registry;

    /// @dev Initializes NounletRegistry contract
    constructor(address _registry) {
        registry = _registry;
    }

    /// @notice Batch burns multiple fractions
    /// @param _from Source address
    /// @param _ids Token IDs to burn
    function batchBurn(address _from, uint256[] calldata _ids) external {
        IRegistry(registry).batchBurn(_from, _ids);
    }

    /// @notice Mints fractional tokens
    /// @param _to Target address
    /// @param _id ID of the token
    function mint(address _to, uint256 _id) external {
        IRegistry(registry).mint(_to, _id);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

/// @dev Interface for NounletRegistry contract
interface INounletRegistry {
    /// @dev Emitted when the caller is not a registered vault
    error UnregisteredVault(address _sender);

    /// @dev Event log for deploying vault
    /// @param _vault Address of the vault
    /// @param _token Address of the token
    event VaultDeployed(address indexed _vault, address indexed _token);

    function batchBurn(address _from, uint256[] memory _ids) external;

    function create(
        bytes32 _merkleRoot,
        address[] memory _plugins,
        bytes4[] memory _selectors,
        address _descriptor,
        uint256 _nounId
    ) external returns (address vault);

    function factory() external view returns (address);

    function implementation() external view returns (address);

    function mint(address _to, uint256 _id) external;

    function nounsToken() external view returns (address);

    function royaltyBeneficiary() external view returns (address);

    function uri(address _vault, uint256 _id) external view returns (string memory);

    function vaultToToken(address) external view returns (address token);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

/// @dev Interface for NounletSupply target contract
interface INounletSupply {
    function batchBurn(address _from, uint256[] memory _ids) external;

    function mint(address _to, uint256 _id) external;
}