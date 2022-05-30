// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.11;

import "../interfaces/IGenericHandler.sol";

/**
    @title Handles generic deposits and deposit executions.
    @author ChainSafe Systems.
    @notice This contract is intended to be used with the Bridge contract.
 */
contract GenericHandler is IGenericHandler {
    address public immutable _bridgeAddress;

    // resourceID => contract address
    mapping (bytes32 => address) public _resourceIDToContractAddress;

    // contract address => resourceID
    mapping (address => bytes32) public _contractAddressToResourceID;

    // contract address => deposit function signature
    mapping (address => bytes4) public _contractAddressToDepositFunctionSignature;

    // contract address => depositer address position offset in the metadata
    mapping (address => uint256) public _contractAddressToDepositFunctionDepositerOffset;

    // contract address => execute proposal function signature
    mapping (address => bytes4) public _contractAddressToExecuteFunctionSignature;

    // token contract address => is whitelisted
    mapping (address => bool) public _contractWhitelist;

    modifier onlyBridge() {
        _onlyBridge();
        _;
    }

    function _onlyBridge() private view {
        require(msg.sender == _bridgeAddress, "sender must be bridge contract");
    }

    /**
        @param bridgeAddress Contract address of previously deployed Bridge.
     */
    constructor(
        address          bridgeAddress
    ) public {
        _bridgeAddress = bridgeAddress;
    }

    /**
        @notice First verifies {_resourceIDToContractAddress}[{resourceID}] and
        {_contractAddressToResourceID}[{contractAddress}] are not already set,
        then sets {_resourceIDToContractAddress} with {contractAddress},
        {_contractAddressToResourceID} with {resourceID},
        {_contractAddressToDepositFunctionSignature} with {depositFunctionSig},
        {_contractAddressToDepositFunctionDepositerOffset} with {depositFunctionDepositerOffset},
        {_contractAddressToExecuteFunctionSignature} with {executeFunctionSig},
        and {_contractWhitelist} to true for {contractAddress}.
        @param resourceID ResourceID to be used when making deposits.
        @param contractAddress Address of contract to be called when a deposit is made and a deposited is executed.
        @param depositFunctionSig Function signature of method to be called in {contractAddress} when a deposit is made.
        @param depositFunctionDepositerOffset Depositer address position offset in the metadata, in bytes.
        @param executeFunctionSig Function signature of method to be called in {contractAddress} when a deposit is executed.
     */
    function setResource(
        bytes32 resourceID,
        address contractAddress,
        bytes4 depositFunctionSig,
        uint256 depositFunctionDepositerOffset,
        bytes4 executeFunctionSig
    ) external onlyBridge override {

        _setResource(resourceID, contractAddress, depositFunctionSig, depositFunctionDepositerOffset, executeFunctionSig);
    }

    /**
        @notice A deposit is initiatied by making a deposit in the Bridge contract.
        @param resourceID ResourceID used to find address of contract to be used for deposit.
        @param depositer Address of the account making deposit in the Bridge contract.
        @param data Consists of: {resourceID}, {lenMetaData}, and {metaData} all padded to 32 bytes.
        @notice Data passed into the function should be constructed as follows:
        len(data)                              uint256     bytes  0  - 32
        data                                   bytes       bytes  64 - END
        @notice {contractAddress} is required to be whitelisted
        @notice If {_contractAddressToDepositFunctionSignature}[{contractAddress}] is set,
        {metaData} is expected to consist of needed function arguments.
        @return Returns the raw bytes returned from the call to {contractAddress}.
     */
    function deposit(bytes32 resourceID, address depositer, bytes calldata data) external onlyBridge returns (bytes memory) {
        uint256      lenMetadata;
        bytes memory metadata;

        lenMetadata = abi.decode(data, (uint256));
        metadata = bytes(data[32:32 + lenMetadata]);

        address contractAddress = _resourceIDToContractAddress[resourceID];
        uint256 depositerOffset = _contractAddressToDepositFunctionDepositerOffset[contractAddress];
        if (depositerOffset > 0) {
            uint256 metadataDepositer;
            // Skipping 32 bytes of length prefix and depositerOffset bytes.
            assembly {
                metadataDepositer := mload(add(add(metadata, 32), depositerOffset))
            }
            // metadataDepositer contains 0xdepositerAddressdepositerAddressdeposite************************
            // Shift it 12 bytes right:   0x000000000000000000000000depositerAddressdepositerAddressdeposite
            require(depositer == address(uint160(metadataDepositer >> 96)), 'incorrect depositer in the data');
        }

        require(_contractWhitelist[contractAddress], "provided contractAddress is not whitelisted");

        bytes4 sig = _contractAddressToDepositFunctionSignature[contractAddress];
        if (sig != bytes4(0)) {
            bytes memory callData = abi.encodePacked(sig, metadata);
            (bool success, bytes memory handlerResponse) = contractAddress.call(callData);
            require(success, "call to contractAddress failed");
            return handlerResponse;
        }
    }

    /**
        @notice Proposal execution should be initiated when a proposal is finalized in the Bridge contract.
        @param data Consists of {resourceID}, {lenMetaData}, and {metaData}.
        @notice Data passed into the function should be constructed as follows:
        len(data)                              uint256     bytes  0  - 32
        data                                   bytes       bytes  32 - END
        @notice {contractAddress} is required to be whitelisted
        @notice If {_contractAddressToExecuteFunctionSignature}[{contractAddress}] is set,
        {metaData} is expected to consist of needed function arguments.
     */
    function executeProposal(bytes32 resourceID, bytes calldata data) external onlyBridge {
        uint256      lenMetadata;
        bytes memory metaData;

        lenMetadata = abi.decode(data, (uint256));
        metaData = bytes(data[32:32 + lenMetadata]);

        address contractAddress = _resourceIDToContractAddress[resourceID];
        require(_contractWhitelist[contractAddress], "provided contractAddress is not whitelisted");

        bytes4 sig = _contractAddressToExecuteFunctionSignature[contractAddress];
        if (sig != bytes4(0)) {
            bytes memory callData = abi.encodePacked(sig, metaData);
            (bool success,) = contractAddress.call(callData);
            require(success, "delegatecall to contractAddress failed");
        }
    }

    function _setResource(
        bytes32 resourceID,
        address contractAddress,
        bytes4 depositFunctionSig,
        uint256 depositFunctionDepositerOffset,
        bytes4 executeFunctionSig
    ) internal {
        _resourceIDToContractAddress[resourceID] = contractAddress;
        _contractAddressToResourceID[contractAddress] = resourceID;
        _contractAddressToDepositFunctionSignature[contractAddress] = depositFunctionSig;
        _contractAddressToDepositFunctionDepositerOffset[contractAddress] = depositFunctionDepositerOffset;
        _contractAddressToExecuteFunctionSignature[contractAddress] = executeFunctionSig;

        _contractWhitelist[contractAddress] = true;
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.11;

/**
    @title Interface for handler that handles generic deposits and deposit executions.
    @author ChainSafe Systems.
 */
interface IGenericHandler {
    /**
        @notice Correlates {resourceID} with {contractAddress}, {depositFunctionSig}, and {executeFunctionSig}.
        @param resourceID ResourceID to be used when making deposits.
        @param contractAddress Address of contract to be called when a deposit is made and a deposited is executed.
        @param depositFunctionSig Function signature of method to be called in {contractAddress} when a deposit is made.
        @param depositFunctionDepositerOffset Depositer address position offset in the metadata, in bytes.
        @param executeFunctionSig Function signature of method to be called in {contractAddress} when a deposit is executed.
     */
    function setResource(
        bytes32 resourceID,
        address contractAddress,
        bytes4 depositFunctionSig,
        uint depositFunctionDepositerOffset,
        bytes4 executeFunctionSig) external;
}