// SPDX-License-Identifier: BUSL
pragma solidity 0.8.11;

/**
 * @title Solidly+ governance killable proxy
 * @author Solidly+
 * @notice EIP-1967 upgradeable proxy with the ability to kill governance and render the contract immutable
 */
contract SolidlyProxy {
    bytes32 constant IMPLEMENTATION_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc; // keccak256('eip1967.proxy.implementation'), actually used for interface so etherscan picks up the interface
    bytes32 constant LOGIC_SLOT =
        0x5942be825425c77e56e4bce97986794ab0f100954e40fc1390ae0e003710a3ab; // keccak256('LOGIC') - 1, actual logic implementation
    bytes32 constant GOVERNANCE_SLOT =
        0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103; // keccak256('eip1967.proxy.admin')
    bytes32 constant INITIALIZED_SLOT =
        0x834ce84547018237034401a09067277cdcbe7bbf7d7d30f6b382b0a102b7b4a3; // keccak256('eip1967.proxy.initialized')

    /**
     * @notice Reverts if msg.sender is not governance
     */
    modifier onlyGovernance() {
        require(msg.sender == governanceAddress(), "Only governance");
        _;
    }

    /**
     * @notice Reverts if contract is already initialized
     * @dev Used by implementations to ensure initialize() is only called once
     */
    modifier notInitialized() {
        bool initialized;
        assembly {
            initialized := sload(INITIALIZED_SLOT)
            if eq(initialized, 1) {
                revert(0, 0)
            }
            sstore(INITIALIZED_SLOT, 1)
        }
        _;
    }

    /**
     * @notice Sets up deployer as a proxy governance
     */
    constructor() {
        address _governanceAddress = msg.sender;
        assembly {
            sstore(GOVERNANCE_SLOT, _governanceAddress)
        }
    }

    /**
     * @notice Detect whether or not governance is killed
     * @return Return true if governance is killed, false if not
     * @dev If governance is killed this contract becomes immutable
     */
    function governanceIsKilled() public view returns (bool) {
        return governanceAddress() == address(0);
    }

    /**
     * @notice Kill governance, making this contract immutable
     * @dev Only governance can kil governance
     */
    function killGovernance() external onlyGovernance {
        updateGovernanceAddress(address(0));
    }

    /**
     * @notice Update implementation address
     * @param _interfaceAddress Address of the new interface
     * @dev Only governance can update implementation
     */
    function updateInterfaceAddress(address _interfaceAddress)
        external
        onlyGovernance
    {
        assembly {
            sstore(IMPLEMENTATION_SLOT, _interfaceAddress)
        }
    }

    /**
     * @notice Actually updates interface, kept for etherscan pattern recognition
     * @param _implementationAddress Address of the new implementation
     * @dev Only governance can update implementation
     */
    function updateImplementationAddress(address _implementationAddress)
        external
        onlyGovernance
    {
        assembly {
            sstore(IMPLEMENTATION_SLOT, _implementationAddress)
        }
    }

    /**
     * @notice Update implementation address
     * @param _logicAddress Address of the new implementation
     * @dev Only governance can update implementation
     */
    function updateLogicAddress(address _logicAddress) external onlyGovernance {
        assembly {
            sstore(LOGIC_SLOT, _logicAddress)
        }
    }

    /**
     * @notice Update governance address
     * @param _governanceAddress New governance address
     * @dev Only governance can update governance
     */
    function updateGovernanceAddress(address _governanceAddress)
        public
        onlyGovernance
    {
        assembly {
            sstore(GOVERNANCE_SLOT, _governanceAddress)
        }
    }

    /**
     * @notice Fetch the current implementation address
     * @return _implementationAddress Returns the current implementation address
     */
    function implementationAddress()
        public
        view
        returns (address _implementationAddress)
    {
        assembly {
            _implementationAddress := sload(IMPLEMENTATION_SLOT)
        }
    }

    /**
     * @notice Fetch the current implementation address
     * @return _interfaceAddress Returns the current implementation address
     */
    function interfaceAddress()
        public
        view
        virtual
        returns (address _interfaceAddress)
    {
        assembly {
            _interfaceAddress := sload(IMPLEMENTATION_SLOT)
        }
    }

    /**
     * @notice Fetch the current implementation address
     * @return _logicAddress Returns the current implementation address
     */
    function logicAddress()
        public
        view
        virtual
        returns (address _logicAddress)
    {
        assembly {
            _logicAddress := sload(LOGIC_SLOT)
        }
    }

    /**
     * @notice Fetch current governance address
     * @return _governanceAddress Returns current governance address
     */
    function governanceAddress()
        public
        view
        virtual
        returns (address _governanceAddress)
    {
        assembly {
            _governanceAddress := sload(GOVERNANCE_SLOT)
        }
    }

    /**
     * @notice Fallback function that delegatecalls the subimplementation instead of what's in the IMPLEMENTATION_SLOT
     */
    function _delegateCallSubimplmentation() internal virtual {
        assembly {
            let contractLogic := sload(LOGIC_SLOT)
            calldatacopy(0x0, 0x0, calldatasize())
            let success := delegatecall(
                gas(),
                contractLogic,
                0x0,
                calldatasize(),
                0,
                0
            )
            let returnDataSize := returndatasize()
            returndatacopy(0, 0, returnDataSize)
            switch success
            case 0 {
                revert(0, returnDataSize)
            }
            default {
                return(0, returnDataSize)
            }
        }
    }

    /**
     * @notice Delegatecall fallback proxy
     */
    fallback() external payable virtual {
        _delegateCallSubimplmentation();
    }

    receive() external payable virtual {
        _delegateCallSubimplmentation();
    }
}