/**
 *Submitted for verification at Etherscan.io on 2022-10-16
*/

// Sources flattened with hardhat v2.10.1 https://hardhat.org
// SPDX-License-Identifier: MIT

// File @openzeppelin/contracts/proxy/[email protected]

// OpenZeppelin Contracts v4.4.1 (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(
                ptr,
                0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            )
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(
                add(ptr, 0x28),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt)
        internal
        returns (address instance)
    {
        assembly {
            let ptr := mload(0x40)
            mstore(
                ptr,
                0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            )
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(
                add(ptr, 0x28),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        assembly {
            let ptr := mload(0x40)
            mstore(
                ptr,
                0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            )
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(
                add(ptr, 0x28),
                0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000
            )
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// File contracts/interfaces/ISodiumWalletFactory.sol

pragma solidity ^0.8.0;

interface ISodiumWalletFactory {
    /* ===== EVENTS ===== */

    // Emitted when a Sodium Wallet is created for a user
    event WalletCreated(address indexed owner, address wallet);

    /* ===== METHODS ===== */

    function createWallet(address borrower) external returns (address);
}


// File contracts/interfaces/ISodiumWallet.sol

pragma solidity ^0.8.0;

interface ISodiumWallet {
    function initialize(
        address _owner,
        address _core,
        address _registry
    ) external;

    function execute(
        address[] calldata contractAddresses,
        bytes[] memory calldatas,
        uint256[] calldata values
    ) external payable;

    function transferERC721(
        address recipient,
        address tokenAddress,
        uint256 tokenId
    ) external;

    function transferERC1155(
        address recipient,
        address tokenAddress,
        uint256 tokenId
    ) external;

    function isValidSignature(bytes32 hash, bytes memory signature)
        external
        view
        returns (bytes4);
}

// File contracts/SodiumWalletFactory.sol

pragma solidity ^0.8.0;

/// @notice Simple clone factory for creating minimal proxy Sodium Wallets
contract SodiumWalletFactory is ISodiumWalletFactory {
    /* ===== STATE ===== */

    // Wallet implementation contract
    address public implementation;

    // The address of the current Sodium Registry
    address public registry;

    /* ===== CONSTRUCTOR ===== */

    /// @param implementation_ The contract to which wallets deployed by this contract delegate their calls
    /// @param registry_ Used by the wallets to determine external call permission
    constructor(address implementation_, address registry_) {
        implementation = implementation_;
        registry = registry_;
    }

    /* ===== CORE METHODS ===== */

    /// @notice Called by the Core to create new wallets
    /// @dev Deploys a minimal EIP-1167 proxy that delegates its calls to `implementation`
    /// @param requester The owner of the new wallet
    function createWallet(address requester)
        external
        override
        returns (address)
    {
        // Deploy
        address wallet = Clones.clone(implementation);

        // Configure
        ISodiumWallet(wallet).initialize(requester, msg.sender, registry);

        emit WalletCreated(requester, wallet);

        // Pass address back to Core
        return wallet;
    }
}