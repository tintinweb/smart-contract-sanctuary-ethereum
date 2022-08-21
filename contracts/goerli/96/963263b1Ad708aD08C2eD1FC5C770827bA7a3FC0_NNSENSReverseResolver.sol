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

pragma solidity >=0.8.4;
import {ENS} from '../registry/ENS.sol';
import {INameResolver} from '../resolvers/profiles/INameResolver.sol';

contract NNSENSReverseResolver {
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
    bytes32 n = node(addr);
    address resolverAddress = registry.resolver(n);
    if (resolverAddress == address(0)) {
      return '';
    }
    INameResolver resolver = INameResolver(resolverAddress);
    string memory name = resolver.name(n);
    if (
      bytes(name).length == 0 ||
      keccak256(abi.encodePacked(name)) == ZERO_ADDRESS
    ) {
      return '';
    }
    return name;
  }

  function node(address addr) private pure returns (bytes32) {
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