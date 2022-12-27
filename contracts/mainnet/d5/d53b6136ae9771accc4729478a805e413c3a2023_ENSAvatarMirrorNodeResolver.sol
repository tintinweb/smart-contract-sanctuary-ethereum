// SPDX-License-Identifier: CC0-1.0

/// @title ENS Avatar Mirror Node Resolver

/**
 *        ><<    ><<<<< ><<    ><<      ><<
 *      > ><<          ><<      ><<      ><<
 *     >< ><<         ><<       ><<      ><<
 *   ><<  ><<        ><<        ><<      ><<
 *  ><<<< >< ><<     ><<        ><<      ><<
 *        ><<        ><<       ><<<<    ><<<<
 */

pragma solidity ^0.8.17;

contract ENSAvatarMirrorNodeResolver {
    address internal ens;
    address internal reverseRegistrar;
    address internal defaultReverseResolver;

    constructor(address _ens, address _reverseRegistrar, address _defaultReverseResolver) {
        ens = _ens;
        reverseRegistrar = _reverseRegistrar;
        defaultReverseResolver = _defaultReverseResolver;
    }

    function getNodeResolver(bytes32 node) internal view returns (address) {
        (bool success, bytes memory data) = ens.staticcall(abi.encodeWithSignature("resolver(bytes32)", node));

        // solhint-disable-next-line reason-string
        require(success);

        return abi.decode(data, (address));
    }

    function getNodeOwner(bytes32 node) external view returns (address owner) {
        (bool success, bytes memory data) = ens.staticcall(abi.encodeWithSignature("owner(bytes32)", node));

        // solhint-disable-next-line reason-string
        require(success);

        owner = abi.decode(data, (address));

        if (owner.code.length > 0) {
            (success, data) = owner.staticcall(abi.encodeWithSignature("isWrapped(bytes32)", node));

            // solhint-disable-next-line reason-string
            require(success && abi.decode(data, (bool)));

            (success, data) = owner.staticcall(abi.encodeWithSignature("ownerOf(uint256)", node));

            // solhint-disable-next-line reason-string
            require(success);

            owner = abi.decode(data, (address));
        }

        return owner;
    }

    function resolveText(bytes32 node, string memory key) external view returns (string memory) {
        address resolver = getNodeResolver(node);
        (bool success, bytes memory data) =
            resolver.staticcall(abi.encodeWithSignature("text(bytes32,string)", node, key));

        if (success) {
            return abi.decode(data, (string));
        }
        return "";
    }

    function reverseNode(address addr) public view returns (bytes32) {
        (bool success, bytes memory data) = reverseRegistrar.staticcall(abi.encodeWithSignature("node(address)", addr));

        // solhint-disable-next-line reason-string
        require(success);

        return abi.decode(data, (bytes32));
    }

    function reverseDomain(address addr) external view returns (string memory) {
        bytes32 node = reverseNode(addr);
        (bool success, bytes memory data) =
            defaultReverseResolver.staticcall(abi.encodeWithSignature("name(bytes32)", node));

        // solhint-disable-next-line reason-string
        require(success);

        return abi.decode(data, (string));
    }
}