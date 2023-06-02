// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.13;

/// @author: manifold.xyz

import {Create2} from "openzeppelin/utils/Create2.sol";

import {Address} from "../../lib/Address.sol";
import {ERC1167ProxyBytecode} from "../../lib/ERC1167ProxyBytecode.sol";
import {IAccountRegistryFactory} from "./IAccountRegistryFactory.sol";

contract AccountRegistryFactory is IAccountRegistryFactory {
    using Address for address;

    error InitializationFailed();

    address private immutable registryImplementation = 0xAE669d2D218fcc602301ea39B2cfec436Ce8d05e;

    function createRegistry(
        uint96 index,
        address accountImplementation,
        bytes calldata accountInitData
    ) external returns (address) {
        bytes32 salt = _getSalt(msg.sender, index);
        bytes memory code = ERC1167ProxyBytecode.createCode(registryImplementation);
        address _registry = Create2.computeAddress(salt, keccak256(code));

        if (_registry.isDeployed()) return _registry;

        _registry = Create2.deploy(0, salt, code);

        (bool success, ) = _registry.call(
            abi.encodeWithSignature(
                "initialize(address,address,bytes)",
                msg.sender,
                accountImplementation,
                accountInitData
            )
        );
        if (!success) revert InitializationFailed();

        emit AccountRegistryCreated(_registry, accountImplementation, index);

        return _registry;
    }

    function registry(address deployer, uint96 index) external view override returns (address) {
        bytes32 salt = _getSalt(deployer, index);
        bytes memory code = ERC1167ProxyBytecode.createCode(registryImplementation);
        return Create2.computeAddress(salt, keccak256(code));
    }

    function _getSalt(address deployer, uint96 index) private pure returns (bytes32) {
        return bytes32(abi.encodePacked(deployer, index));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Create2.sol)

pragma solidity ^0.8.0;

/**
 * @dev Helper to make usage of the `CREATE2` EVM opcode easier and safer.
 * `CREATE2` can be used to compute in advance the address where a smart
 * contract will be deployed, which allows for interesting new mechanisms known
 * as 'counterfactual interactions'.
 *
 * See the https://eips.ethereum.org/EIPS/eip-1014#motivation[EIP] for more
 * information.
 */
library Create2 {
    /**
     * @dev Deploys a contract using `CREATE2`. The address where the contract
     * will be deployed can be known in advance via {computeAddress}.
     *
     * The bytecode for a contract can be obtained from Solidity with
     * `type(contractName).creationCode`.
     *
     * Requirements:
     *
     * - `bytecode` must not be empty.
     * - `salt` must have not been used for `bytecode` already.
     * - the factory must have a balance of at least `amount`.
     * - if `amount` is non-zero, `bytecode` must have a `payable` constructor.
     */
    function deploy(uint256 amount, bytes32 salt, bytes memory bytecode) internal returns (address addr) {
        require(address(this).balance >= amount, "Create2: insufficient balance");
        require(bytecode.length != 0, "Create2: bytecode length is zero");
        /// @solidity memory-safe-assembly
        assembly {
            addr := create2(amount, add(bytecode, 0x20), mload(bytecode), salt)
        }
        require(addr != address(0), "Create2: Failed on deploy");
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy}. Any change in the
     * `bytecodeHash` or `salt` will result in a new destination address.
     */
    function computeAddress(bytes32 salt, bytes32 bytecodeHash) internal view returns (address) {
        return computeAddress(salt, bytecodeHash, address(this));
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy} from a contract located at
     * `deployer`. If `deployer` is this contract's address, returns the same value as {computeAddress}.
     */
    function computeAddress(bytes32 salt, bytes32 bytecodeHash, address deployer) internal pure returns (address addr) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40) // Get free memory pointer

            // |                   | ↓ ptr ...  ↓ ptr + 0x0B (start) ...  ↓ ptr + 0x20 ...  ↓ ptr + 0x40 ...   |
            // |-------------------|---------------------------------------------------------------------------|
            // | bytecodeHash      |                                                        CCCCCCCCCCCCC...CC |
            // | salt              |                                      BBBBBBBBBBBBB...BB                   |
            // | deployer          | 000000...0000AAAAAAAAAAAAAAAAAAA...AA                                     |
            // | 0xFF              |            FF                                                             |
            // |-------------------|---------------------------------------------------------------------------|
            // | memory            | 000000...00FFAAAAAAAAAAAAAAAAAAA...AABBBBBBBBBBBBB...BBCCCCCCCCCCCCC...CC |
            // | keccak(start, 85) |            ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑ |

            mstore(add(ptr, 0x40), bytecodeHash)
            mstore(add(ptr, 0x20), salt)
            mstore(ptr, deployer) // Right-aligned with 12 preceding garbage bytes
            let start := add(ptr, 0x0b) // The hashed data starts at the final garbage byte which we will set to 0xff
            mstore8(start, 0xff)
            addr := keccak256(start, 85)
        }
    }
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.13;

interface IAccountRegistryFactory {
    event AccountRegistryCreated(address registry, address accountImplementation, uint96 index);

    function createRegistry(
        uint96 index,
        address accountImplementation,
        bytes calldata accountInitData
    ) external returns (address);

    function registry(address deployer, uint96 index) external view returns (address);
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.13;

library Address {
    function isDeployed(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.13;

library ERC1167ProxyBytecode {

    function createCode(
        address implementation
    ) internal pure returns (bytes memory) {
        return
            abi.encodePacked(
                hex"3d608e80600a3d3981f3363d3d373d3d3d363d73",
                implementation,
                hex"5af43d82803e903d91602b57fd5bf300"
            );
    }
}