// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/Clones.sol)

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
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create(0, 0x09, 0x37)
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
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create2(0, 0x09, 0x37, salt)
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
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(add(ptr, 0x38), deployer)
            mstore(add(ptr, 0x24), 0x5af43d82803e903d91602b57fd5bf3ff)
            mstore(add(ptr, 0x14), implementation)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73)
            mstore(add(ptr, 0x58), salt)
            mstore(add(ptr, 0x78), keccak256(add(ptr, 0x0c), 0x37))
            predicted := keccak256(add(ptr, 0x43), 0x55)
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Ownable} from "../utils/Ownable.sol";
import {CloneFactoryEventsAndErrors} from "../utils/CloneFactoryEventsAndErrors.sol";
import {IERC721TManager} from "../interfaces/IERC721TManager.sol";
import {ICatanLeagueLedger} from "../interfaces/ICatanLeagueLedger.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";

contract CatanLeagueCloneFactory is
    CloneFactoryEventsAndErrors,
    Ownable
{
    mapping(address => address) public ownershipLedger;

    constructor() {}

    function ownershipUpdateCallback(
        address newOwner,
        address existingContract
    ) external {
        if (ownershipLedger[existingContract] != msg.sender) {
            revert OwnershipUpdateError(existingContract);
        }
        ownershipLedger[existingContract] = newOwner;
        emit OwnerShipChanged(newOwner, existingContract);
    }

    function cloneERC721T(
        address implementation,
        address ledger,
        string calldata name_,
        string calldata symbol_
    ) internal returns (address) {
        address clone = Clones.clone(implementation);
        emit ClonedERC721T(clone);
        IERC721TManager(clone).initalizeERC721T(name_, symbol_, ledger);
        return clone;
    }

    function cloneLeagueLedger(
        address implementation,
        string calldata name_
    ) internal returns (address) {
        address clone = Clones.clone(implementation);
        emit ClonedLeagueLedger(clone);
        ICatanLeagueLedger(clone).initializeLedger(clone, name_);
        return clone;
    }

    function createFreshLeagueTemplate(
        address erc721Implementation,
        address ledgerImplementation,
        string calldata name_,
        string calldata symbol_,
        string calldata leagueName
    ) external {
        address clonedLeagueLedger = cloneLeagueLedger(
            ledgerImplementation,
            leagueName
        );
        address clonedERC721T = cloneERC721T(
            erc721Implementation,
            clonedLeagueLedger,
            name_,
            symbol_
        );
        ICatanLeagueLedger(clonedLeagueLedger).changeLeagueERC721Trophy(
            clonedERC721T
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface ICatanLeagueLedger {
    function initializeLedger(
        address leagueFactory_,
        string calldata name_
    ) external;

    function changeLeagueERC721Trophy(address erc721T) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IERC721TManager {
    function mint(address winner, uint256 tokenId) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function initalizeERC721T(
        string calldata name_,
        string calldata symbol_,
        address leagueLedger_
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract CloneFactoryEventsAndErrors {
    event ClonedLeagueLedger(address newLedger);
    event ClonedERC721T(address newToken);
    event UsernameChanged(address owner, string username);
    event OwnerShipChanged(address newOwner, address leagueContract);

    error OwnershipUpdateError(address existingContract);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract Ownable {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert("Only the owner can call this function.");
        }
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
    }
}