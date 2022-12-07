// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IFactory {
    function governanceAddress() external view returns (address);

    function childSubImplementationAddress() external view returns (address);

    function childInterfaceAddress() external view returns (address);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.11;
import "./SolidlyProxy.sol";
import "./interfaces/IFactory.sol";

/**
 * @notice Child Proxy deployed by factories for pairs, fees, gauges, and bribes. Calls back to the factory to fetch proxy implementation.
 */
contract SolidlyChildProxy is SolidlyProxy {
    bytes32 constant FACTORY_SLOT =
        0x547b500e425d72fd0723933cceefc203cef652b4736fd04250c3369b3e1a0a72; // keccak256('FACTORY') - 1

    modifier onlyFactory() {
        require(msg.sender == factoryAddress(), "only Factory");
        _;
    }

    /**
     * @notice Records factory address and current interface implementation
     */
    constructor() {
        address _factory = msg.sender;
        address _interface = IFactory(msg.sender).childInterfaceAddress();
        assembly {
            sstore(FACTORY_SLOT, _factory)
            sstore(IMPLEMENTATION_SLOT, _interface) // Storing the interface into EIP-1967's implementation slot so Etherscan picks up the interface
        }
    }

    /****************************************
                    SETTINGS
     ****************************************/

    /**
     * @notice Governance callable method to update the Factory address
     */
    function updateFactoryAddress(address _factory) external onlyGovernance {
        assembly {
            sstore(FACTORY_SLOT, _factory)
        }
    }

    /**
     * @notice Publically callable function to sync proxy interface with the one recorded in the factory
     */
    function updateInterfaceAddress() external {
        address _newInterfaceAddress = IFactory(factoryAddress())
            .childInterfaceAddress();
        require(
            implementationAddress() != _newInterfaceAddress,
            "Nothing to update"
        );
        assembly {
            sstore(IMPLEMENTATION_SLOT, _newInterfaceAddress)
        }
    }

    /****************************************
                  VIEW METHODS 
     ****************************************/

    /**
     * @notice Fetch current governance address from factory
     * @return _governanceAddress Returns current governance address
     */
    function governanceAddress()
        public
        view
        override
        returns (address _governanceAddress)
    {
        return IFactory(factoryAddress()).governanceAddress();
    }

    function factoryAddress() public view returns (address _factory) {
        assembly {
            _factory := sload(FACTORY_SLOT)
        }
    }

    /**
     *@notice Fetch address where actual contract logic is at
     */
    function subImplementationAddress()
        public
        view
        returns (address _subimplementation)
    {
        return IFactory(factoryAddress()).childSubImplementationAddress();
    }

    /**
     * @notice Fetch address where the interface for the contract is
     */
    function interfaceAddress()
        public
        view
        override
        returns (address _interface)
    {
        assembly {
            _interface := sload(IMPLEMENTATION_SLOT)
        }
    }

    /****************************************
                  FALLBACK METHODS 
     ****************************************/

    /**
     * @notice Fallback function that delegatecalls the subimplementation instead of what's in the IMPLEMENTATION_SLOT
     */
    function _delegateCallSubimplmentation() internal override {
        address contractLogic = IFactory(factoryAddress())
            .childSubImplementationAddress();
        assembly {
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

    fallback() external payable override {
        _delegateCallSubimplmentation();
    }
}

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