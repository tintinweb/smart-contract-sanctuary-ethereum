// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.16;

interface IInitializable {
    function initialized() external view returns (bool);

    function initializer() external view returns (address);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.16;

import {IInitializable} from "./IInitializable.sol";

interface ISimpleInitializable is IInitializable {
    function initialize() external;
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.16;

interface IAccountWhitelist {
    event AccountAdded(address account);
    event AccountRemoved(address account);

    function getWhitelistedAccounts() external view returns (address[] memory);

    function isAccountWhitelisted(address account) external view returns (bool);

    function addAccountToWhitelist(address account) external;

    function removeAccountFromWhitelist(address account) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.16;

import {IOwnable} from "../../lib/IOwnable.sol";

import {ISimpleInitializable} from "../init/ISimpleInitializable.sol";

import {IAccountWhitelist} from "./IAccountWhitelist.sol";

// solhint-disable-next-line no-empty-blocks
interface IOwnableAccountWhitelist is IAccountWhitelist, IOwnable, ISimpleInitializable {

}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.16;

import {Clones} from "../../lib/Clones.sol";

import {IOwnableAccountWhitelist} from "./IOwnableAccountWhitelist.sol";

/**
 * Factory that deploys `OwnableAccountWhitelist` contract clones by making use of minimal proxy
 *
 * Meant to be utility class for internal usage only
 */
contract OwnableAccountWhitelistFactory {
    address private immutable _ownableAccountWhitelistPrototype;

    constructor(address ownableAccountWhitelistPrototype_) {
        _ownableAccountWhitelistPrototype = ownableAccountWhitelistPrototype_;
    }

    function deployClone() external returns (address ownableAccountWhitelist) {
        ownableAccountWhitelist = Clones.clone(_ownableAccountWhitelistPrototype);
        IOwnableAccountWhitelist(ownableAccountWhitelist).initialize();
        IOwnableAccountWhitelist(ownableAccountWhitelist).transferOwnership(msg.sender);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/Clones.sol)

/**
 * @dev xSwap modifications of original OpenZeppelin's {Clones} implementation:
 * - bump `pragma solidity` (`^0.8.0` -> `^0.8.16`)
 * - shortify `require` messages (`ERC1167:` -> `CL:`)
 */

pragma solidity ^0.8.16;

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
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "CL: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "CL: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt
    ) internal view returns (address predicted) {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

interface IOwnable {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() external view returns (address);

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() external;

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) external;
}