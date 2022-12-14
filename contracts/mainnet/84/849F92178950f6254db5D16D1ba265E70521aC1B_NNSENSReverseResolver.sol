pragma solidity >=0.8.4;

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
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    function setRecord(
        bytes32 node,
        address owner,
        address resolver,
        uint64 ttl
    ) external;

    function setSubnodeRecord(
        bytes32 node,
        bytes32 label,
        address owner,
        address resolver,
        uint64 ttl
    ) external;

    function setSubnodeOwner(
        bytes32 node,
        bytes32 label,
        address owner
    ) external returns (bytes32);

    function setResolver(bytes32 node, address resolver) external;

    function setOwner(bytes32 node, address owner) external;

    function setTTL(bytes32 node, uint64 ttl) external;

    function setApprovalForAll(address operator, bool approved) external;

    function owner(bytes32 node) external view returns (address);

    function resolver(bytes32 node) external view returns (address);

    function ttl(bytes32 node) external view returns (uint64);

    function recordExists(bytes32 node) external view returns (bool);

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface INameResolver {
    event NameChanged(bytes32 indexed node, string name);

    /**
     * Returns the name associated with an ENS node, for reverse records.
     * Defined in EIP181.
     * @param node The ENS node to query.
     * @return The associated name.
     */
    function name(bytes32 node) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

library ENSNamehash {

  function namehash(bytes memory domain) internal pure returns (bytes32) {
    return namehash(domain, 0);
  }

  function namehash(bytes memory domain, uint i) internal pure returns (bytes32) {
    if (domain.length <= i)
      return 0x0000000000000000000000000000000000000000000000000000000000000000;

    uint len = LabelLength(domain, i);

    return keccak256(abi.encodePacked(namehash(domain, i+len+1), keccak(domain, i, len)));
  }

  function LabelLength(bytes memory domain, uint i) private pure returns (uint) {
    uint len;
    while (i+len != domain.length && domain[i+len] != 0x2e) {
      len++;
    }
    return len;
  }

  function keccak(bytes memory data, uint offset, uint len) private pure returns (bytes32 ret) {
    require(offset + len <= data.length);
    assembly {
      ret := keccak256(add(add(data, 32), offset), len)
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;
import {ENS} from '../registry/ENS.sol';
import {INameResolver} from '../resolvers/profiles/INameResolver.sol';
import {IAddrResolver} from '../resolvers/profiles/IAddrResolver.sol';
import './ENSNamehash.sol';

contract NNSENSReverseResolver {

  using ENSNamehash for bytes;

  bytes32 private constant ADDR_REVERSE_NODE =
    0x91d1777781884d03a6757a803996e38de2a42967fb37eeaca72729271025a9e2;
  bytes32 private constant ZERO_ADDRESS =
    0x918d5359431a7007dec0d4722530b0726c0e1010a959bd8b871a6a5d6337144a;

  ENS public immutable ens;
  ENS public immutable nns;

  constructor(address _nns, address _ens) {
    nns = ENS(_nns);
    ens = ENS(_ens);
  }

  function resolve(address addr) public view returns (string memory) {
    string memory name = _resolve(addr, nns);
    if (bytes(name).length == 0 && address(ens) != address(0)) {
      return _resolve(addr, ens);
    }
    return name;
  }

  function _resolve(address addr, ENS registry)
    private
    view
    returns (string memory)
  {
    // Resolve addr to name.
    bytes32 n = reverseAddrNode(addr);
    address resolverAddress = registry.resolver(n);
    if (resolverAddress == address(0)) {
      return '';
    }
    INameResolver nameResolver = INameResolver(resolverAddress);
    string memory name = nameResolver.name(n);
    if (
      bytes(name).length == 0 ||
      keccak256(abi.encodePacked(name)) == ZERO_ADDRESS
    ) {
      return '';
    }

    // Reverse check.
    bytes32 nameNode = bytes(name).namehash();
    address addrResolverAddr = registry.resolver(nameNode);
    if (addrResolverAddr == address(0)) {
      return '';
    }
    IAddrResolver addrResolver = IAddrResolver(addrResolverAddr);
    address revAddr = addrResolver.addr(nameNode);
    if (revAddr != addr) {
      return '';
    }
 
    return name;
  }

  function reverseAddrNode(address addr) private pure returns (bytes32) {
    return keccak256(abi.encodePacked(ADDR_REVERSE_NODE, sha3HexAddress(addr)));
  }

  function sha3HexAddress(address addr) private pure returns (bytes32 ret) {
    addr;
    ret; // Stop warning us about unused variables
    assembly {
      let
        lookup
      := 0x3031323334353637383961626364656600000000000000000000000000000000

      for {
        let i := 40
      } gt(i, 0) {

      } {
        i := sub(i, 1)
        mstore8(i, byte(and(addr, 0xf), lookup))
        addr := div(addr, 0x10)
        i := sub(i, 1)
        mstore8(i, byte(and(addr, 0xf), lookup))
        addr := div(addr, 0x10)
      }

      ret := keccak256(0, 40)
    }
  }
}