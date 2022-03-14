//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./EnsLibrary.sol";

contract PublicEnsProxy {
    address public immutable ensRegistry;

    constructor(address _ensRegistry) {
        ensRegistry = _ensRegistry;
    }

    function getAddressFromEnsNode(bytes32 ensNode)
        public
        view
        returns (address)
    {
        return EnsLibrary.ensNodeToAddressFromEnsRegistry(ensRegistry, ensNode);
    }

    /*
     * proxyDestination: the contract you want to proxy to
     * offsets: the offset in bytes into data where you want to insert a 32 byte ens addresses
     * ensNodes: the ens nodes you want to resolve and then replace in data
     * NOTE: offsets must be the same length as ensNodes
     * data: the data you want to pass along to the proxy contract
     */
    function forwardWithEnsParamaterResolution(
        address proxyDestination,
        uint256[] calldata offsets,
        bytes32[] calldata ensNodes,
        bytes calldata data
    ) public payable returns (bytes memory) {
        require(
            offsets.length == ensNodes.length,
            "offsets and ensNodes length doesn't match"
        );

        bytes memory dataCopy = new bytes(data.length);
        for (uint256 i = 0; i < data.length; i++) {
            dataCopy[i] = data[i];
        }
        for (uint256 i = 0; i < offsets.length; i++) {
            address ensAddr = getAddressFromEnsNode(ensNodes[i]);
            // mstore offsets are indexed at the end of the 32 byte value you want to store
            // so we have to add 32 to account for the size of the ens address
            uint256 offset = offsets[i] + 32;
            assembly {
                mstore(add(dataCopy, offset), ensAddr)
            }
        }
        (bool success, bytes memory returnData) = proxyDestination.call{
            value: msg.value
        }(dataCopy);
        require(success, "Proxy failed");
        return returnData;
    }

    /*
     * An extension of forwardWithEnsParamaterResolution that also allows you
     * to resolve the destination contract you are proxing to.
     */
    function forwardWithEnsParamaterAndEnsProxyDestinationResolution(
        bytes32 proxyDestinationEnsNode,
        uint256[] calldata offsets,
        bytes32[] calldata ensNodes,
        bytes calldata data
    ) public payable returns (bytes memory) {
        return
            forwardWithEnsParamaterResolution(
                getAddressFromEnsNode(proxyDestinationEnsNode),
                offsets,
                ensNodes,
                data
            );
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface EnsRegistry {
    function resolver(bytes32 node) external view returns (address);
}

interface EnsResolver {
    function addr(bytes32 node) external view returns (address);
}

library EnsLibrary {
    function ensNodeToAddressFromEnsRegistry(
        address ensRegistry,
        bytes32 ensNode
    ) internal view returns (address) {
        address resolver = EnsRegistry(ensRegistry).resolver(ensNode);
        require(resolver != address(0), "The resolver for ensNode DNE");
        address addr = EnsResolver(resolver).addr(ensNode);
        require(addr != address(0), "The address for resolver DNE");
        return addr;
    }
}