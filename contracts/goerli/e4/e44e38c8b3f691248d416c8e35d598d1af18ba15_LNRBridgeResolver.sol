/**
 *Submitted for verification at Etherscan.io on 2022-10-13
*/

// SPDX-License-Identifier: MIT

// File: @ensdomains/ens-contracts/contracts/resolvers/profiles/IAddressResolver.sol

pragma solidity >=0.8.4;

/**
 * Interface for the new (multicoin) addr function.
 */
interface IAddressResolver {
    event AddressChanged(
        bytes32 indexed node,
        uint256 coinType,
        bytes newAddress
    );

    function addr(bytes32 node, uint256 coinType)
        external
        view
        returns (bytes memory);
}

// File: @ensdomains/ens-contracts/contracts/resolvers/profiles/IAddrResolver.sol

pragma solidity >=0.8.4;

/**
 * Interface for the legacy (ETH-only) addr function.
 */
interface IAddrResolver {
    event AddrChanged(bytes32 indexed node, address a);

    /**
     * Returns the address associated with an ENS node.
     * @param node The ENS node to query.
     * @return The associated address.
     */
    function addr(bytes32 node) external view returns (address payable);
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

contract LNRBridgeResolver is ERC165 {
    mapping(bytes32=>bytes32) nodes;

    LNRegistrar lnr = LNRegistrar(0x74ad104851eC9f920F28B1F015a89549B97272c3);
    LNRBridgeStorage lnrStorage = LNRBridgeStorage(0x702BB4a12489e1056E53073deF91Fe0C77D332D7);

    modifier onlyOwner(bytes32 name) {
        require(isOwner(name), "Restricted to name owner");
        _;
    }

    function addr(bytes32 node) external view returns (address) {
        return lnr.addr(lnrStorage.getName(node));
    }

    function addr(bytes32 node, uint256 coinType) external view returns (bytes memory) {
        return addressToBytes(lnr.addr(lnrStorage.getName(node)));
    }

    function addressToBytes(address a) internal pure returns (bytes memory b) {
        b = new bytes(20);
        assembly {
            mstore(add(b, 32), mul(a, exp(256, 12)))
        }
    }

    function isOwner(bytes32 name) internal view returns(bool) {
        return lnr.owner(name) == msg.sender;
    }

    function setName(bytes32 node, bytes32 name) external onlyOwner(name) {
        lnrStorage.setName(node, name);
    }

    function supportsInterface(bytes4 interfaceID) public pure override returns (bool) {
        return interfaceID == type(IAddrResolver).interfaceId || interfaceID == type(IAddressResolver).interfaceId;
    }
}