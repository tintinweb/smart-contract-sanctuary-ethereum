// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {RegistryStorage} from "contracts/storage/RegistryStorage.sol";

/**
 * @title SafeRegistryProxy
 */
contract SafeRegistryProxy is RegistryStorage {

    constructor(
        address _registry,
        bytes32[] memory factoryNames,
        address[] memory factoryAddress,
        address _masterfile
    ) {
        _safeRegistry = _registry;

        require(factoryNames.length == factoryAddress.length, "Registry: Factory length mismatch");
        for(uint256 i = 0; i < factoryNames.length; i++) {
            factories[factoryNames[i]].push(factoryAddress[i]);
            isFactory[factoryNames[i]][factoryAddress[i]] = true;
        }

        masterfile = _masterfile;
        _owner = msg.sender;
    }

    fallback() external payable {
        address _impl = implementation();
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize())
            let result := delegatecall(gas(), _impl, ptr, calldatasize(), 0, 0)
            let size := returndatasize()
            returndatacopy(ptr, 0, size)

            switch result
                case 0 {
                    revert(ptr, size)
                }
                default {
                    return(ptr, size)
                }
        }
    }

    /**
     * @notice  Returns the implementation of this proxy
     * @return  registry     Implementation address
     */
    function implementation() public view returns(address registry) {
        return _safeRegistry;
    }

	// Plain ETH transfers.
    receive() external payable {
        revert();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @notice RegistryStorage
 */
contract RegistryStorage {
    address internal _safeRegistry;
    address internal _owner;
    address public masterfile;
    mapping(address  => bool) public whitelisted;
    mapping(bytes32 => mapping(address => bool)) public isDeployment;
    mapping(bytes32 => address[]) internal factories;
    mapping(bytes32 => mapping(address => bool)) public isFactory;
}