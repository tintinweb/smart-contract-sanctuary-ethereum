// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "RegistryStorageModel.sol";
import "BaseModuleStorage.sol";

contract Registry is RegistryStorageModel, BaseModuleStorage {
    bytes32 public constant NAME = "Registry";

    constructor(address _controller, bytes32 _initialRelease) {
        // Init
        release = _initialRelease;
        contracts[release]["InstanceOperatorService"] = msg.sender;
        contractNames[release].push("InstanceOperatorService");
        contractsInRelease[release] = 1;
        _assignController(_controller);
        // register the deployment block for reading logs
        startBlock = block.number;
    }

    function assignController(address _controller) external {
        // todo: use onlyInstanceOperator modifier
        require(
            msg.sender == contracts[release]["InstanceOperator"],
            "ERROR:REG-001:NOT_AUTHORIZED"
        );
        _assignController(_controller);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "IRegistry.sol";

contract RegistryStorageModel is IRegistry {
    /**
     * @dev Current release
     * We use semantic versioning.
     */
    bytes32 public release;
    uint256 public startBlock;

    /**
     * @dev  Save number of items to iterate through
     * Currently we have < 20 contracts.
     */
    uint256 public maxContracts = 100;

    // release => contract name => contract address
    mapping(bytes32 => mapping(bytes32 => address)) public contracts;
    // release => contract name []
    mapping(bytes32 => bytes32[]) public contractNames;
    // number of contracts in release
    mapping(bytes32 => uint256) public contractsInRelease;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

interface IRegistry {
    event LogContractRegistered(
        bytes32 release,
        bytes32 contractName,
        address contractAddress,
        bool isNew
    );

    event LogContractDeregistered(bytes32 release, bytes32 contractName);

    event LogReleasePrepared(bytes32 release);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "Delegator.sol";

contract BaseModuleStorage is Delegator {
    address public controller;

    /* solhint-disable payable-fallback */
    fallback() external virtual {
        _delegate(controller);
    }

    /* solhint-enable payable-fallback */

    function _assignController(address _controller) internal {
        controller = _controller;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

contract Delegator {
    function _delegate(address _implementation) internal {
        require(
            _implementation != address(0),
            "ERROR:DEL-001:UNKNOWN_IMPLEMENTATION"
        );

        bytes memory data = msg.data;

        /* solhint-disable no-inline-assembly */
        assembly {
            let result := delegatecall(
                gas(),
                _implementation,
                add(data, 0x20),
                mload(data),
                0,
                0
            )
            let size := returndatasize()
            let ptr := mload(0x40)
            returndatacopy(ptr, 0, size)
            switch result
                case 0 {
                    revert(ptr, size)
                }
                default {
                    return(ptr, size)
                }
        }
        /* solhint-enable no-inline-assembly */
    }
}