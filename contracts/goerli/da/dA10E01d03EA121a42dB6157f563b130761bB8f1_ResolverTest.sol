// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import {ENS} from "@ensdomains/ens/contracts/ENS.sol";
import {ContentHashResolver} from
  "@ensdomains/resolver/contracts/profiles/ContentHashResolver.sol";


contract ResolverTest {
  ENS public immutable ens;
  bytes32 public baseNode;

  event NewCID(bytes32 indexed _baseNode, bytes indexed _hash, bytes _notIndexedHash);

  constructor(ENS _ens, bytes32 _baseNode) {
      ens = _ens;
      baseNode = _baseNode;
  }

  // 'mrfrog.eth' 0xfc91bf97833949c1acd8d88e082f539b3f5f77e2066a10277ecb2af5d67cf878
  function transferENSOwnership(bytes32 _node, address _owner) public {
    ens.setOwner(_node, _owner);
  }

  /// @notice Set the content identifier for the subnode via the ENS public resolver
  /// @param _hash The CID
  function setCID(bytes calldata _hash, bytes32 _subnode) public {
    ContentHashResolver(ens.resolver(_subnode)).setContenthash(_subnode, _hash);
    emit NewCID(_subnode, _hash, _hash);
  }

  function getEns() public returns (address) {
    return address(ens);
  }

  function getBaseNode() public returns (bytes32){
    return baseNode;
  }

  function createSubnode(bytes32 label) public {
    ens.setSubnodeOwner(baseNode, label, 0x5cF66013B7AD15646Dfcf229acB26A888CE476aa);
  }

}

//

pragma solidity ^0.7.0;

interface ENS {

    // Logged when the owner of a node assigns a new owner to a subnode.
    event NewOwner(bytes32 indexed node, bytes32 indexed label, address owner);

    // Logged when the owner of a node transfers ownership to a new account.
    event Transfer(bytes32 indexed node, address owner);

    // Logged when the resolver for a node changes.
    event NewResolver(bytes32 indexed node, address resolver);

    // Logged when the TTL of a node changes
    event NewTTL(bytes32 indexed node, uint64 ttl);

    // Logged when an operator is added or removed.
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function setRecord(bytes32 node, address owner, address resolver, uint64 ttl) external virtual;
    function setSubnodeRecord(bytes32 node, bytes32 label, address owner, address resolver, uint64 ttl) external virtual;
    function setSubnodeOwner(bytes32 node, bytes32 label, address owner) external virtual returns(bytes32);
    function setResolver(bytes32 node, address resolver) external virtual;
    function setOwner(bytes32 node, address owner) external virtual;
    function setTTL(bytes32 node, uint64 ttl) external virtual;
    function setApprovalForAll(address operator, bool approved) external virtual;
    function owner(bytes32 node) external virtual view returns (address);
    function resolver(bytes32 node) external virtual view returns (address);
    function ttl(bytes32 node) external virtual view returns (uint64);
    function recordExists(bytes32 node) external virtual view returns (bool);
    function isApprovedForAll(address owner, address operator) external virtual view returns (bool);
}

pragma solidity ^0.7.4;
import "../ResolverBase.sol";

abstract contract ContentHashResolver is ResolverBase {
    bytes4 constant private CONTENT_HASH_INTERFACE_ID = 0xbc1c58d1;

    event ContenthashChanged(bytes32 indexed node, bytes hash);

    mapping(bytes32=>bytes) hashes;

    /**
     * Sets the contenthash associated with an ENS node.
     * May only be called by the owner of that node in the ENS registry.
     * @param node The node to update.
     * @param hash The contenthash to set
     */
    function setContenthash(bytes32 node, bytes calldata hash) external authorised(node) {
        hashes[node] = hash;
        emit ContenthashChanged(node, hash);
    }

    /**
     * Returns the contenthash associated with an ENS node.
     * @param node The ENS node to query.
     * @return The associated contenthash.
     */
    function contenthash(bytes32 node) external view returns (bytes memory) {
        return hashes[node];
    }

    function supportsInterface(bytes4 interfaceID) virtual override public pure returns(bool) {
        return interfaceID == CONTENT_HASH_INTERFACE_ID || super.supportsInterface(interfaceID);
    }
}

pragma solidity ^0.7.4;
abstract contract ResolverBase {
    bytes4 private constant INTERFACE_META_ID = 0x01ffc9a7;

    function supportsInterface(bytes4 interfaceID) virtual public pure returns(bool) {
        return interfaceID == INTERFACE_META_ID;
    }

    function isAuthorised(bytes32 node) internal virtual view returns(bool);

    modifier authorised(bytes32 node) {
        require(isAuthorised(node));
        _;
    }

    function bytesToAddress(bytes memory b) internal pure returns(address payable a) {
        require(b.length == 20);
        assembly {
            a := div(mload(add(b, 32)), exp(256, 12))
        }
    }

    function addressToBytes(address a) internal pure returns(bytes memory b) {
        b = new bytes(20);
        assembly {
            mstore(add(b, 32), mul(a, exp(256, 12)))
        }
    }
}