// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {LibDiamond} from "../../libraries/LibDiamond.sol";
import {IERC173} from "../../interfaces/IERC173.sol";
import {IERC165} from "../../interfaces/IERC165.sol";
import {IDiamondCut} from "../../interfaces/IDiamondCut.sol";
import {IDiamondLoupe} from "../../interfaces/IDiamondLoupe.sol";
import {ICCMPRouterAdaptor} from "../../interfaces/ICCMPRouterAdaptor.sol";
import {ICCMPGateway, ICCMPConfiguration} from "../../interfaces/ICCMPGateway.sol";
import {ICCMPExecutor} from "../../interfaces/ICCMPExecutor.sol";

contract CCMPConfigurationFacet is IERC173, ICCMPConfiguration {
    function transferOwnership(
        address _newOwner
    ) external override(IERC173, ICCMPConfiguration) {
        LibDiamond._enforceIsContractOwner();
        LibDiamond._setContractOwner(_newOwner);
    }

    function owner()
        external
        view
        override(IERC173, ICCMPConfiguration)
        returns (address owner_)
    {
        owner_ = LibDiamond._contractOwner();
    }

    function setGatewayBatch(
        uint256[] calldata _chainId,
        ICCMPGateway[] calldata _gateway
    ) external {
        LibDiamond._enforceIsContractOwner();
        if (_chainId.length != _gateway.length) {
            revert ParameterArrayLengthMismatch();
        }
        uint256 length = _chainId.length;
        unchecked {
            for (uint256 i; i < length; ++i) {
                LibDiamond._diamondStorage().gateways[_chainId[i]] = _gateway[
                    i
                ];
                emit GatewayUpdated(_chainId[i], _gateway[i]);
            }
        }
    }

    function setGateway(uint256 _chainId, ICCMPGateway _gateway) external {
        LibDiamond._enforceIsContractOwner();
        LibDiamond._diamondStorage().gateways[_chainId] = _gateway;
        emit GatewayUpdated(_chainId, _gateway);
    }

    function gateway(
        uint256 _chainId
    ) external view returns (ICCMPGateway gateway_) {
        gateway_ = LibDiamond._diamondStorage().gateways[_chainId];
    }

    function setRouterAdaptorBatch(
        string[] calldata names,
        ICCMPRouterAdaptor[] calldata adaptors
    ) external {
        LibDiamond._enforceIsContractOwner();
        if (names.length != adaptors.length) {
            revert ParameterArrayLengthMismatch();
        }
        uint256 length = names.length;
        unchecked {
            for (uint256 i; i < length; ++i) {
                LibDiamond._diamondStorage().adaptors[names[i]] = adaptors[i];
                emit AdaptorUpdated(names[i], address(adaptors[i]));
            }
        }
    }

    function setRouterAdaptor(
        string calldata name,
        ICCMPRouterAdaptor adaptor
    ) external {
        LibDiamond._enforceIsContractOwner();
        LibDiamond._diamondStorage().adaptors[name] = adaptor;
        emit AdaptorUpdated(name, address(adaptor));
    }

    function routerAdaptor(
        string calldata name
    ) external view returns (ICCMPRouterAdaptor adaptor) {
        adaptor = LibDiamond._diamondStorage().adaptors[name];
    }

    function setCCMPExecutor(ICCMPExecutor _ccmpExecutor) external {
        LibDiamond._enforceIsContractOwner();
        LibDiamond._diamondStorage().ccmpExecutor = _ccmpExecutor;
        emit CCMPExecutorUpdated(_ccmpExecutor);
    }

    function ccmpExecutor() external view returns (ICCMPExecutor executor) {
        executor = LibDiamond._diamondStorage().ccmpExecutor;
    }

    function pauser() external view returns (address pauser_) {
        pauser_ = LibDiamond._diamondStorage().pauser;
    }

    function setPauser(address _pauser) external {
        LibDiamond._enforceIsContractOwner();
        LibDiamond._diamondStorage().pauser = _pauser;
        emit PauserUpdated(_pauser);
    }

    function pause() external {
        LibDiamond._enforceIsContractPauser();
        LibDiamond._pauseContract();
        emit ContractPaused();
    }

    function unpause() external {
        LibDiamond._enforceIsContractPauser();
        LibDiamond._unpauseContract();
        emit ContractUnpaused();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/
import {IDiamond} from "../interfaces/IDiamond.sol";
import {IDiamondCut} from "../interfaces/IDiamondCut.sol";
import {ICCMPExecutor} from "../interfaces/ICCMPExecutor.sol";
import {ICCMPRouterAdaptor} from "../interfaces/ICCMPRouterAdaptor.sol";
import {ICCMPGateway} from "../interfaces/ICCMPGateway.sol";

// Remember to add the loupe functions from DiamondLoupeFacet to the diamond.
// The loupe functions are required by the EIP2535 Diamonds standard

error NoSelectorsGivenToAdd();
error NotContractOwner(address _user, address _contractOwner);
error NoSelectorsProvidedForFacetForCut(address _facetAddress);
error CannotAddSelectorsToZeroAddress(bytes4[] _selectors);
error NoBytecodeAtAddress(address _contractAddress, string _message);
error IncorrectFacetCutAction(uint8 _action);
error CannotAddFunctionToDiamondThatAlreadyExists(bytes4 _selector);
error CannotReplaceFunctionsFromFacetWithZeroAddress(bytes4[] _selectors);
error CannotReplaceImmutableFunction(bytes4 _selector);
error CannotReplaceFunctionWithTheSameFunctionFromTheSameFacet(
    bytes4 _selector
);
error CannotReplaceFunctionThatDoesNotExists(bytes4 _selector);
error RemoveFacetAddressMustBeZeroAddress(address _facetAddress);
error CannotRemoveFunctionThatDoesNotExist(bytes4 _selector);
error CannotRemoveImmutableFunction(bytes4 _selector);
error InitializationFunctionReverted(
    address _initializationContractAddress,
    bytes _calldata
);
error ContractIsPaused();
error NotContractPauser(address _user, address _contractPauser);

library LibDiamond {
    bytes32 constant DIAMOND_STORAGE_POSITION =
        keccak256("diamond.standard.diamond.storage");

    struct FacetAddressAndSelectorPosition {
        address facetAddress;
        uint16 selectorPosition;
    }

    struct CCMPDiamondStorage {
        // function selector => facet address and selector position in selectors array
        mapping(bytes4 => FacetAddressAndSelectorPosition) facetAddressAndSelectorPosition;
        bytes4[] selectors;
        mapping(bytes4 => bool) supportedInterfaces;
        // owner of the contract
        address contractOwner;
        // CCMP Executor
        ICCMPExecutor ccmpExecutor;
        // Adaptor Name => Adaptor Address
        mapping(string => ICCMPRouterAdaptor) adaptors;
        // Global Nonce (when used, it's prefixe with block.chainid)
        uint128 nextNonce;
        // Destination Chain ID => Gateway Address.
        // This is set in the outbound message and is verified on the destination chain
        mapping(uint256 => ICCMPGateway) gateways;
        // Whether a message with nonce N has been executed or not
        mapping(uint256 => bool) nonceUsed;
        // Contract pausibility
        address pauser;
        bool paused;
        // Gas Fee Accounting
        mapping(bytes32 => mapping(address => uint256)) gasFeePaidByToken;
    }

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    event DiamondCut(
        IDiamondCut.FacetCut[] _diamondCut,
        address _init,
        bytes _calldata
    );

    function _diamondStorage()
        internal
        pure
        returns (CCMPDiamondStorage storage ds)
    {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    // Ownable
    function _setContractOwner(address _newOwner) internal {
        CCMPDiamondStorage storage ds = _diamondStorage();
        address previousOwner = ds.contractOwner;
        ds.contractOwner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    function _contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = _diamondStorage().contractOwner;
    }

    function _enforceIsContractOwner() internal view {
        if (msg.sender != _diamondStorage().contractOwner) {
            revert NotContractOwner(
                msg.sender,
                _diamondStorage().contractOwner
            );
        }
    }

    // Pauser
    function _setContractPauser(address _newPauser) internal {
        _diamondStorage().pauser = _newPauser;
    }

    function _contractPauser() internal view returns (address pauser_) {
        pauser_ = _diamondStorage().pauser;
    }

    function _enforceIsContractNotPaused() internal view {
        if (_diamondStorage().paused) {
            revert ContractIsPaused();
        }
    }

    function _enforceIsContractPauser() internal view {
        if (msg.sender != _diamondStorage().pauser) {
            revert NotContractPauser(msg.sender, _diamondStorage().pauser);
        }
    }

    function _pauseContract() internal {
        _diamondStorage().paused = true;
    }

    function _unpauseContract() internal {
        _diamondStorage().paused = false;
    }

    // Internal function version of diamondCut
    function _diamondCut(
        IDiamondCut.FacetCut[] memory __diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        for (
            uint256 facetIndex;
            facetIndex < __diamondCut.length;
            facetIndex++
        ) {
            bytes4[] memory functionSelectors = __diamondCut[facetIndex]
                .functionSelectors;
            address facetAddress = __diamondCut[facetIndex].facetAddress;
            if (functionSelectors.length == 0) {
                revert NoSelectorsProvidedForFacetForCut(facetAddress);
            }
            IDiamondCut.FacetCutAction action = __diamondCut[facetIndex].action;
            if (action == IDiamond.FacetCutAction.Add) {
                _addFunctions(facetAddress, functionSelectors);
            } else if (action == IDiamond.FacetCutAction.Replace) {
                _replaceFunctions(facetAddress, functionSelectors);
            } else if (action == IDiamond.FacetCutAction.Remove) {
                _removeFunctions(facetAddress, functionSelectors);
            } else {
                revert IncorrectFacetCutAction(uint8(action));
            }
        }
        emit DiamondCut(__diamondCut, _init, _calldata);
        _initializeDiamondCut(_init, _calldata);
    }

    function _addFunctions(
        address _facetAddress,
        bytes4[] memory _functionSelectors
    ) internal {
        if (_facetAddress == address(0)) {
            revert CannotAddSelectorsToZeroAddress(_functionSelectors);
        }
        CCMPDiamondStorage storage ds = _diamondStorage();
        uint16 selectorCount = uint16(ds.selectors.length);
        _enforceHasContractCode(
            _facetAddress,
            "LibDiamondCut: Add facet has no code"
        );
        for (
            uint256 selectorIndex;
            selectorIndex < _functionSelectors.length;
            selectorIndex++
        ) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds
                .facetAddressAndSelectorPosition[selector]
                .facetAddress;
            if (oldFacetAddress != address(0)) {
                revert CannotAddFunctionToDiamondThatAlreadyExists(selector);
            }
            ds.facetAddressAndSelectorPosition[
                    selector
                ] = FacetAddressAndSelectorPosition(
                _facetAddress,
                selectorCount
            );
            ds.selectors.push(selector);
            selectorCount++;
        }
    }

    function _replaceFunctions(
        address _facetAddress,
        bytes4[] memory _functionSelectors
    ) internal {
        CCMPDiamondStorage storage ds = _diamondStorage();
        if (_facetAddress == address(0)) {
            revert CannotReplaceFunctionsFromFacetWithZeroAddress(
                _functionSelectors
            );
        }
        _enforceHasContractCode(
            _facetAddress,
            "LibDiamondCut: Replace facet has no code"
        );
        for (
            uint256 selectorIndex;
            selectorIndex < _functionSelectors.length;
            selectorIndex++
        ) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds
                .facetAddressAndSelectorPosition[selector]
                .facetAddress;
            // can't replace immutable functions -- functions defined directly in the diamond in this case
            if (oldFacetAddress == address(this)) {
                revert CannotReplaceImmutableFunction(selector);
            }
            if (oldFacetAddress == _facetAddress) {
                revert CannotReplaceFunctionWithTheSameFunctionFromTheSameFacet(
                    selector
                );
            }
            if (oldFacetAddress == address(0)) {
                revert CannotReplaceFunctionThatDoesNotExists(selector);
            }
            // replace old facet address
            ds
                .facetAddressAndSelectorPosition[selector]
                .facetAddress = _facetAddress;
        }
    }

    function _removeFunctions(
        address _facetAddress,
        bytes4[] memory _functionSelectors
    ) internal {
        CCMPDiamondStorage storage ds = _diamondStorage();
        uint256 selectorCount = ds.selectors.length;
        if (_facetAddress != address(0)) {
            revert RemoveFacetAddressMustBeZeroAddress(_facetAddress);
        }
        for (
            uint256 selectorIndex;
            selectorIndex < _functionSelectors.length;
            selectorIndex++
        ) {
            bytes4 selector = _functionSelectors[selectorIndex];
            FacetAddressAndSelectorPosition
                memory oldFacetAddressAndSelectorPosition = ds
                    .facetAddressAndSelectorPosition[selector];
            if (oldFacetAddressAndSelectorPosition.facetAddress == address(0)) {
                revert CannotRemoveFunctionThatDoesNotExist(selector);
            }

            // can't remove immutable functions -- functions defined directly in the diamond
            if (
                oldFacetAddressAndSelectorPosition.facetAddress == address(this)
            ) {
                revert CannotRemoveImmutableFunction(selector);
            }
            // replace selector with last selector
            selectorCount--;
            if (
                oldFacetAddressAndSelectorPosition.selectorPosition !=
                selectorCount
            ) {
                bytes4 lastSelector = ds.selectors[selectorCount];
                ds.selectors[
                    oldFacetAddressAndSelectorPosition.selectorPosition
                ] = lastSelector;
                ds
                    .facetAddressAndSelectorPosition[lastSelector]
                    .selectorPosition = oldFacetAddressAndSelectorPosition
                    .selectorPosition;
            }
            // delete last selector
            ds.selectors.pop();
            delete ds.facetAddressAndSelectorPosition[selector];
        }
    }

    function _initializeDiamondCut(address _init, bytes memory _calldata)
        internal
    {
        if (_init == address(0)) {
            return;
        }
        _enforceHasContractCode(
            _init,
            "LibDiamondCut: _init address has no code"
        );
        (bool success, bytes memory error) = _init.delegatecall(_calldata);
        if (!success) {
            if (error.length > 0) {
                // bubble up error
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(error)
                    revert(add(32, error), returndata_size)
                }
            } else {
                revert InitializationFunctionReverted(_init, _calldata);
            }
        }
    }

    function _enforceHasContractCode(
        address _contract,
        string memory _errorMessage
    ) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        if (contractSize == 0) {
            revert NoBytecodeAtAddress(_contract, _errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title ERC-173 Contract Ownership Standard
///  Note: the ERC-165 identifier for this interface is 0x7f5828d0
/* is ERC165 */
interface IERC173 {
    /// @dev This emits when ownership of a contract changes.
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /// @notice Get the address of the owner
    /// @return owner_ The address of the owner.
    function owner() external view returns (address owner_);

    /// @notice Set the address of the new owner of the contract
    /// @dev Set _newOwner to address(0) to renounce any ownership.
    /// @param _newOwner The address of the new owner of the contract
    function transferOwnership(address _newOwner) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceId The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

import {IDiamond} from "./IDiamond.sol";

interface IDiamondCut is IDiamond {
    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

// A loupe is a small magnifying glass used to look at diamonds.
// These functions look at diamonds
interface IDiamondLoupe {
    /// These functions are expected to be called frequently
    /// by tools.

    struct Facet {
        address facetAddress;
        bytes4[] functionSelectors;
    }

    /// @notice Gets all facet addresses and their four byte function selectors.
    /// @return facets_ Facet
    function facets() external view returns (Facet[] memory facets_);

    /// @notice Gets all the function selectors supported by a specific facet.
    /// @param _facet The facet address.
    /// @return facetFunctionSelectors_
    function facetFunctionSelectors(address _facet)
        external
        view
        returns (bytes4[] memory facetFunctionSelectors_);

    /// @notice Get all the facet addresses used by a diamond.
    /// @return facetAddresses_
    function facetAddresses()
        external
        view
        returns (address[] memory facetAddresses_);

    /// @notice Gets the facet that supports the given selector.
    /// @dev If facet is not found return address(0).
    /// @param _functionSelector The function selector.
    /// @return facetAddress_ The facet address.
    function facetAddress(bytes4 _functionSelector)
        external
        view
        returns (address facetAddress_);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../structures/CrossChainMessage.sol";
import "./ICCMPGateway.sol";

interface ICCMPRouterAdaptor {
    error CallerIsNotCCMPGateway();
    error InvalidAddress(string parameterName, address value);
    error ParameterArrayLengthMismatch();

    event CCMPGatewayUpdated(ICCMPGateway indexed newCCMPGateway);

    function verifyPayload(
        CCMPMessage calldata _ccmpMessage,
        bytes calldata _verificationData
    ) external returns (bool, string memory);

    function routePayload(
        CCMPMessage calldata _ccmpMessage,
        bytes calldata _routeArgs
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../structures/CrossChainMessage.sol";
import "./ICCMPRouterAdaptor.sol";
import "./ICCMPExecutor.sol";

interface ICCMPGatewayBase {
    error UnsupportedAdapter(string adaptorName);
}

interface ICCMPGatewaySender is ICCMPGatewayBase {
    // Errors
    error UnsupportedDestinationChain(uint256 destinationChainId);
    error InvalidPayload(string reason);
    error AmountIsZero();
    error NativeAmountMismatch();
    error NativeTransferFailed(address relayer, bytes data);
    error AmountExceedsBalance(uint256 _amount, uint256 balance);
    error InsufficientNativeAmount(
        uint256 requiredAmount,
        uint256 actualAmount
    );

    // Events
    event CCMPMessageRouted(
        bytes32 indexed hash,
        address indexed sender,
        ICCMPGateway sourceGateway,
        ICCMPRouterAdaptor sourceAdaptor,
        uint256 sourceChainId,
        ICCMPGateway destinationGateway,
        uint256 indexed destinationChainId,
        uint256 nonce,
        string routerAdaptor,
        GasFeePaymentArgs gasFeePaymentArgs,
        CCMPMessagePayload[] payload
    );
    event FeePaid(
        address indexed _tokenAddress,
        uint256 indexed _amount,
        address indexed _relayer
    );

    // Functions
    function sendMessage(
        uint256 _destinationChainId,
        string calldata _adaptorName,
        CCMPMessagePayload[] calldata _payloads,
        GasFeePaymentArgs calldata _gasFeePaymentArgs,
        bytes calldata _routerArgs
    ) external payable returns (bool sent);

    function getGasFeePaymentDetails(
        bytes32 _messageHash,
        address[] calldata _tokens
    ) external view returns (uint256[] memory balances);

    /// @notice Handles fee payment
    function addGasFee(
        GasFeePaymentArgs memory _args,
        bytes32 _messageHash,
        address _sender
    ) external payable;
}

interface ICCMPGatewayReceiver is ICCMPGatewayBase {
    // Errors
    error InvalidSource(uint256 sourceChainId, ICCMPGateway sourceGateway);
    error WrongDestination(
        uint256 destinationChainId,
        ICCMPGateway destinationGateway
    );
    error AlreadyExecuted(uint256 nonce);
    error VerificationFailed(string reason);
    error ExternalCallFailed(
        uint256 index,
        address contractAddress,
        bytes returndata
    );

    // Events
    event CCMPMessageExecuted(
        bytes32 indexed hash,
        address indexed sender,
        ICCMPGateway sourceGateway,
        ICCMPRouterAdaptor sourceAdaptor,
        uint256 sourceChainId,
        ICCMPGateway destinationGateway,
        uint256 indexed destinationChainId,
        uint256 nonce,
        string routerAdaptor,
        GasFeePaymentArgs gasFeePaymentArgs,
        CCMPMessagePayload[] payload
    );

    event CCMPPayloadExecuted(
        uint256 indexed index,
        address indexed contractAddress,
        bool success,
        bytes returndata
    );

    // Functions
    function receiveMessage(
        CCMPMessage calldata _message,
        bytes calldata _verificationData,
        bool _allowPartialCompletion
    ) external returns (bool received);
}

interface ICCMPConfiguration {
    error ParameterArrayLengthMismatch();

    // Events
    event GatewayUpdated(
        uint256 indexed destinationChainId,
        ICCMPGateway indexed gateway
    );
    event CCMPExecutorUpdated(ICCMPExecutor indexed _ccmpExecutor);
    event AdaptorUpdated(string indexed adaptorName, address indexed adaptor);
    event ContractPaused();
    event ContractUnpaused();
    event PauserUpdated(address indexed pauser);

    // Functions
    function setGateway(uint256 _chainId, ICCMPGateway _gateway) external;

    function setRouterAdaptor(
        string calldata name,
        ICCMPRouterAdaptor adaptor
    ) external;

    function setGatewayBatch(
        uint256[] calldata _chainId,
        ICCMPGateway[] calldata _gateway
    ) external;

    function setRouterAdaptorBatch(
        string[] calldata names,
        ICCMPRouterAdaptor[] calldata adaptors
    ) external;

    function setCCMPExecutor(ICCMPExecutor _ccmpExecutor) external;

    function setPauser(address _pauser) external;

    function gateway(
        uint256 _chainId
    ) external view returns (ICCMPGateway gateway_);

    function routerAdaptor(
        string calldata name
    ) external view returns (ICCMPRouterAdaptor adaptor);

    function ccmpExecutor() external view returns (ICCMPExecutor executor);

    function transferOwnership(address _newOwner) external;

    function owner() external view returns (address owner_);

    function pauser() external view returns (address pauser_);

    function pause() external;

    function unpause() external;
}

interface ICCMPGateway is
    ICCMPGatewaySender,
    ICCMPGatewayReceiver,
    ICCMPConfiguration
{}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICCMPExecutor {
    function execute(address _to, bytes calldata _calldata)
        external
        returns (bool success, bytes memory returndata);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

interface IDiamond {
    enum FacetCutAction {
        Add,
        Replace,
        Remove
    }
    // Add=0, Replace=1, Remove=2

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "../interfaces/ICCMPGateway.sol";
import "../interfaces/ICCMPRouterAdaptor.sol";

struct CCMPMessagePayload {
    address to;
    bytes _calldata;
}

struct GasFeePaymentArgs {
    address feeTokenAddress;
    uint256 feeAmount;
    address relayer;
}

/*
    {
        "sender": "0xUSER",
        "sourceGateway": "0xGATEWAY",
        "sourceAdaptor": "0xADAPTOR",
        "sourceChainId: 80001,
        "destinationChainGateway": "0xGATEWAY2",
        "destinationChainId": "1",
        "nonce": 1,
        "routerAdaptor": "wormhole",
        "gasFeePaymentArgs": GasFeePaymentArgs,
        "payload": [
            {
                "to": 0xCONTRACT,
                "_calldata": "0xabc"
            }
        ]
    }
*/
struct CCMPMessage {
    address sender;
    ICCMPGateway sourceGateway;
    ICCMPRouterAdaptor sourceAdaptor;
    uint256 sourceChainId;
    ICCMPGateway destinationGateway;
    uint256 destinationChainId;
    uint256 nonce;
    string routerAdaptor;
    GasFeePaymentArgs gasFeePaymentArgs;
    CCMPMessagePayload[] payload;
}

library CCMPMessageUtils {
    function hash(CCMPMessage memory message) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    message.sender,
                    address(message.sourceGateway),
                    address(message.sourceAdaptor),
                    message.sourceChainId,
                    address(message.destinationGateway),
                    message.destinationChainId,
                    message.nonce,
                    message.routerAdaptor,
                    message.gasFeePaymentArgs.feeTokenAddress,
                    message.gasFeePaymentArgs.feeAmount,
                    message.gasFeePaymentArgs.relayer,
                    message.payload
                )
            );
    }
}