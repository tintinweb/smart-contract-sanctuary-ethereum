// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

/******************************************************************************\
* A custom implementation of EIP-2535
* EIP-2535: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

import {ParaProxyLib} from "./lib/ParaProxyLib.sol";
import {IParaProxy} from "../../../interfaces/IParaProxy.sol";

contract ParaProxy is IParaProxy {
    constructor(address _contractOwner) payable {
        ParaProxyLib.setContractOwner(_contractOwner);
    }

    function updateImplementation(
        ProxyImplementation[] calldata _implementationParams,
        address _init,
        bytes calldata _calldata
    ) external override {
        ParaProxyLib.enforceIsContractOwner();
        ParaProxyLib.updateImplementation(
            _implementationParams,
            _init,
            _calldata
        );
    }

    // Find implementation for function that is called and execute the
    // function if a implementation is found and return any value.
    fallback() external payable {
        ParaProxyLib.ProxyStorage storage ds;
        bytes32 position = ParaProxyLib.PROXY_STORAGE_POSITION;
        // get proxy storage
        assembly {
            ds.slot := position
        }
        // get implementation from function selector
        address implementation = ds
            .selectorToImplAndPosition[msg.sig]
            .implAddress;
        require(
            implementation != address(0),
            "ParaProxy: Function does not exist"
        );
        // Execute external function from implementation using delegatecall and return any value.
        assembly {
            // copy function selector and any arguments
            calldatacopy(0, 0, calldatasize())
            // execute function call using the implementation
            let result := delegatecall(
                gas(),
                implementation,
                0,
                calldatasize(),
                0,
                0
            )
            // get any return value
            returndatacopy(0, 0, returndatasize())
            // return any return value or error back to the caller
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    receive() external payable {}
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.10;

/******************************************************************************\
* EIP-2535: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

interface IParaProxy {
    enum ProxyImplementationAction {
        Add,
        Replace,
        Remove
    }
    // Add=0, Replace=1, Remove=2

    struct ProxyImplementation {
        address implAddress;
        ProxyImplementationAction action;
        bytes4[] functionSelectors;
    }

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _implementationParams Contains the implementation addresses and function selectors
    /// @param _init The address of the contract or implementation to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function updateImplementation(
        ProxyImplementation[] calldata _implementationParams,
        address _init,
        bytes calldata _calldata
    ) external;

    event ImplementationUpdated(
        ProxyImplementation[] _implementationParams,
        address _init,
        bytes _calldata
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

/******************************************************************************\
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

import {IParaProxy} from "../../../../interfaces/IParaProxy.sol";

library ParaProxyLib {
    bytes32 constant PROXY_STORAGE_POSITION =
        bytes32(
            uint256(keccak256("paraspace.proxy.implementation.storage")) - 1
        );

    struct ImplementationAddressAndPosition {
        address implAddress;
        uint96 functionSelectorPosition; // position in implementationFunctionSelectors.functionSelectors array
    }

    struct ImplementationFunctionSelectors {
        bytes4[] functionSelectors;
        uint256 implementationAddressPosition; // position of implAddress in implementationAddresses array
    }

    struct ProxyStorage {
        // maps function selector to the implementation address and
        // the position of the selector in the implementationFunctionSelectors.selectors array
        mapping(bytes4 => ImplementationAddressAndPosition) selectorToImplAndPosition;
        // maps implementation addresses to function selectors
        mapping(address => ImplementationFunctionSelectors) implementationFunctionSelectors;
        // implementation addresses
        address[] implementationAddresses;
        // Used to query if a contract implements an interface.
        // Used to implement ERC-165.
        mapping(bytes4 => bool) supportedInterfaces;
        // owner of the contract
        address contractOwner;
    }

    function diamondStorage() internal pure returns (ProxyStorage storage ds) {
        bytes32 position = PROXY_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    function setContractOwner(address _newOwner) internal {
        ProxyStorage storage ds = diamondStorage();
        address previousOwner = ds.contractOwner;
        ds.contractOwner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = diamondStorage().contractOwner;
    }

    function enforceIsContractOwner() internal view {
        require(
            msg.sender == diamondStorage().contractOwner,
            "ParaProxy: Must be contract owner"
        );
    }

    event ImplementationUpdated(
        IParaProxy.ProxyImplementation[] _implementationData,
        address _init,
        bytes _calldata
    );

    // Internal function version of diamondCut
    function updateImplementation(
        IParaProxy.ProxyImplementation[] memory _implementationData,
        address _init,
        bytes memory _calldata
    ) internal {
        for (
            uint256 implIndex;
            implIndex < _implementationData.length;
            implIndex++
        ) {
            IParaProxy.ProxyImplementationAction action = _implementationData[
                implIndex
            ].action;
            if (action == IParaProxy.ProxyImplementationAction.Add) {
                addFunctions(
                    _implementationData[implIndex].implAddress,
                    _implementationData[implIndex].functionSelectors
                );
            } else if (action == IParaProxy.ProxyImplementationAction.Replace) {
                replaceFunctions(
                    _implementationData[implIndex].implAddress,
                    _implementationData[implIndex].functionSelectors
                );
            } else if (action == IParaProxy.ProxyImplementationAction.Remove) {
                removeFunctions(
                    _implementationData[implIndex].implAddress,
                    _implementationData[implIndex].functionSelectors
                );
            } else {
                revert("ParaProxy: Incorrect ProxyImplementationAction");
            }
        }
        emit ImplementationUpdated(_implementationData, _init, _calldata);
        initializeImplementation(_init, _calldata);
    }

    function addFunctions(
        address _implementationAddress,
        bytes4[] memory _functionSelectors
    ) internal {
        require(
            _functionSelectors.length > 0,
            "ParaProxy: No selectors in implementation to cut"
        );
        ProxyStorage storage ds = diamondStorage();
        require(
            _implementationAddress != address(0),
            "ParaProxy: Add implementation can't be address(0)"
        );
        uint96 selectorPosition = uint96(
            ds
                .implementationFunctionSelectors[_implementationAddress]
                .functionSelectors
                .length
        );
        // add new implementation address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _implementationAddress);
        }
        for (
            uint256 selectorIndex;
            selectorIndex < _functionSelectors.length;
            selectorIndex++
        ) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldImplementationAddress = ds
                .selectorToImplAndPosition[selector]
                .implAddress;
            require(
                oldImplementationAddress == address(0),
                "ParaProxy: Can't add function that already exists"
            );
            addFunction(ds, selector, selectorPosition, _implementationAddress);
            selectorPosition++;
        }
    }

    function replaceFunctions(
        address _implementationAddress,
        bytes4[] memory _functionSelectors
    ) internal {
        require(
            _functionSelectors.length > 0,
            "ParaProxy: No selectors in implementation to cut"
        );
        ProxyStorage storage ds = diamondStorage();
        require(
            _implementationAddress != address(0),
            "ParaProxy: Add implementation can't be address(0)"
        );
        uint96 selectorPosition = uint96(
            ds
                .implementationFunctionSelectors[_implementationAddress]
                .functionSelectors
                .length
        );
        // add new implementation address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _implementationAddress);
        }
        for (
            uint256 selectorIndex;
            selectorIndex < _functionSelectors.length;
            selectorIndex++
        ) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldImplementationAddress = ds
                .selectorToImplAndPosition[selector]
                .implAddress;
            require(
                oldImplementationAddress != _implementationAddress,
                "ParaProxy: Can't replace function with same function"
            );
            removeFunction(ds, oldImplementationAddress, selector);
            addFunction(ds, selector, selectorPosition, _implementationAddress);
            selectorPosition++;
        }
    }

    function removeFunctions(
        address _implementationAddress,
        bytes4[] memory _functionSelectors
    ) internal {
        require(
            _functionSelectors.length > 0,
            "ParaProxy: No selectors in implementation to cut"
        );
        ProxyStorage storage ds = diamondStorage();
        // if function does not exist then do nothing and return
        require(
            _implementationAddress == address(0),
            "ParaProxy: Remove implementation address must be address(0)"
        );
        for (
            uint256 selectorIndex;
            selectorIndex < _functionSelectors.length;
            selectorIndex++
        ) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldImplementationAddress = ds
                .selectorToImplAndPosition[selector]
                .implAddress;
            removeFunction(ds, oldImplementationAddress, selector);
        }
    }

    function addFacet(ProxyStorage storage ds, address _implementationAddress)
        internal
    {
        enforceHasContractCode(
            _implementationAddress,
            "ParaProxy: New implementation has no code"
        );
        ds
            .implementationFunctionSelectors[_implementationAddress]
            .implementationAddressPosition = ds.implementationAddresses.length;
        ds.implementationAddresses.push(_implementationAddress);
    }

    function addFunction(
        ProxyStorage storage ds,
        bytes4 _selector,
        uint96 _selectorPosition,
        address _implementationAddress
    ) internal {
        ds
            .selectorToImplAndPosition[_selector]
            .functionSelectorPosition = _selectorPosition;
        ds
            .implementationFunctionSelectors[_implementationAddress]
            .functionSelectors
            .push(_selector);
        ds
            .selectorToImplAndPosition[_selector]
            .implAddress = _implementationAddress;
    }

    function removeFunction(
        ProxyStorage storage ds,
        address _implementationAddress,
        bytes4 _selector
    ) internal {
        require(
            _implementationAddress != address(0),
            "ParaProxy: Can't remove function that doesn't exist"
        );
        // an immutable function is a function defined directly in a paraProxy
        require(
            _implementationAddress != address(this),
            "ParaProxy: Can't remove immutable function"
        );
        // replace selector with last selector, then delete last selector
        uint256 selectorPosition = ds
            .selectorToImplAndPosition[_selector]
            .functionSelectorPosition;
        uint256 lastSelectorPosition = ds
            .implementationFunctionSelectors[_implementationAddress]
            .functionSelectors
            .length - 1;
        // if not the same then replace _selector with lastSelector
        if (selectorPosition != lastSelectorPosition) {
            bytes4 lastSelector = ds
                .implementationFunctionSelectors[_implementationAddress]
                .functionSelectors[lastSelectorPosition];
            ds
                .implementationFunctionSelectors[_implementationAddress]
                .functionSelectors[selectorPosition] = lastSelector;
            ds
                .selectorToImplAndPosition[lastSelector]
                .functionSelectorPosition = uint96(selectorPosition);
        }
        // delete the last selector
        ds
            .implementationFunctionSelectors[_implementationAddress]
            .functionSelectors
            .pop();
        delete ds.selectorToImplAndPosition[_selector];

        // if no more selectors for implementation address then delete the implementation address
        if (lastSelectorPosition == 0) {
            // replace implementation address with last implementation address and delete last implementation address
            uint256 lastImplementationAddressPosition = ds
                .implementationAddresses
                .length - 1;
            uint256 implementationAddressPosition = ds
                .implementationFunctionSelectors[_implementationAddress]
                .implementationAddressPosition;
            if (
                implementationAddressPosition !=
                lastImplementationAddressPosition
            ) {
                address lastImplementationAddress = ds.implementationAddresses[
                    lastImplementationAddressPosition
                ];
                ds.implementationAddresses[
                    implementationAddressPosition
                ] = lastImplementationAddress;
                ds
                    .implementationFunctionSelectors[lastImplementationAddress]
                    .implementationAddressPosition = implementationAddressPosition;
            }
            ds.implementationAddresses.pop();
            delete ds
                .implementationFunctionSelectors[_implementationAddress]
                .implementationAddressPosition;
        }
    }

    function initializeImplementation(address _init, bytes memory _calldata)
        internal
    {
        if (_init == address(0)) {
            require(
                _calldata.length == 0,
                "ParaProxy: _init is address(0) but_calldata is not empty"
            );
        } else {
            require(
                _calldata.length > 0,
                "ParaProxy: _calldata is empty but _init is not address(0)"
            );
            if (_init != address(this)) {
                enforceHasContractCode(
                    _init,
                    "ParaProxy: _init address has no code"
                );
            }
            (bool success, bytes memory error) = _init.delegatecall(_calldata);
            if (!success) {
                if (error.length > 0) {
                    // bubble up the error
                    revert(string(error));
                } else {
                    revert("ParaProxy: _init function reverted");
                }
            }
        }
    }

    function enforceHasContractCode(
        address _contract,
        string memory _errorMessage
    ) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }
}