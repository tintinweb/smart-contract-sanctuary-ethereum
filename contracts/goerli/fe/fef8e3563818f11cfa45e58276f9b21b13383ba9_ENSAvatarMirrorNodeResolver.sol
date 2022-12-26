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

    constructor(address _ens) {
        ens = _ens;
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
}