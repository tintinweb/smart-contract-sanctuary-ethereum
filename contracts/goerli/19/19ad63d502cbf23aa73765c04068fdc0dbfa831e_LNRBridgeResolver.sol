/**
 *Submitted for verification at Etherscan.io on 2022-10-12
*/

// SPDX-License-Identifier: MIT

// File: @ensdomains/ens-contracts/contracts/resolvers/profiles/IVersionableResolver.sol

pragma solidity >=0.8.4;

interface IVersionableResolver {
    event VersionChanged(bytes32 indexed node, uint64 newVersion);

    function recordVersions(bytes32 node) external view returns (uint64);
}

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol

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

// File: @openzeppelin/contracts/utils/introspection/ERC165.sol

// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

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

// File: @ensdomains/ens-contracts/contracts/resolvers/ResolverBase.sol


pragma solidity >=0.8.4;

abstract contract ResolverBase is ERC165, IVersionableResolver {
    mapping(bytes32 => uint64) public recordVersions;

    function isAuthorised(bytes32 node) internal view virtual returns (bool);

    modifier authorised(bytes32 node) {
        require(isAuthorised(node));
        _;
    }

    /**
     * Increments the record version associated with an ENS node.
     * May only be called by the owner of that node in the ENS registry.
     * @param node The node to update.
     */
    function clearRecords(bytes32 node) public virtual authorised(node) {
        recordVersions[node]++;
        emit VersionChanged(node, recordVersions[node]);
    }

    function supportsInterface(bytes4 interfaceID)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceID == type(IVersionableResolver).interfaceId ||
            super.supportsInterface(interfaceID);
    }
}

// File: contracts/LNRBridgeResolver.sol

pragma solidity ^0.8.17;

abstract contract LNRegistrar {
    function addr(bytes32 name) public virtual view returns (address);
    function owner(bytes32 name) public virtual view returns (address);
}

abstract contract LNRBridgeStorage {
    function deleteName(bytes32 node) external virtual;
    function getName(bytes32 node) external virtual view returns(bytes32);
    function setName(bytes32 node, bytes32 name) external virtual;
}

contract LNRBridgeResolver is ResolverBase {
    mapping(bytes32=>bytes32) nodes;

    LNRegistrar lnr = LNRegistrar(0x74ad104851eC9f920F28B1F015a89549B97272c3);
    LNRBridgeStorage lnrStorage = LNRBridgeStorage(0x702BB4a12489e1056E53073deF91Fe0C77D332D7);

    function addr(bytes32 node) external view returns (address) {
        return lnr.addr(lnrStorage.getName(node));
    }

    function isAuthorised(bytes32 name) internal view override returns(bool) {
        return lnr.owner(name) == msg.sender;
    }

    function setName(bytes32 node, bytes32 name) external authorised(name) {
        lnrStorage.setName(node, name);
    }

    function supportsInterface(bytes4 interfaceID) public pure override returns (bool) {
        return interfaceID == 0x3b3b57de;
    }
}