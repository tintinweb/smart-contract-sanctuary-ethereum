// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;


/**
 * @title UDS User Data Service based partly on ENS contracts (especially for resolvers)
 */
contract UDS  {
  
    address public _owner; // uds owner
    uint256 public chainId;
    mapping(bytes32 => address) private _resolvers;

    mapping(bytes32 => address) public owner; // profile data owner
    constructor() {
        _owner = msg.sender;
    }

    function _chainId() internal {
        chainId = block.chainid;
    }

    function isPolygon() internal view returns(bool) {
        return chainId == 137 || chainId == 80001;
    }

    function isMainnet() internal view returns(bool) {
        return chainId == 1 || chainId == 5;
    }

    function setResolver(bytes32 rootNode, address resolver) external {
        _resolvers[rootNode] = resolver;
    }


}