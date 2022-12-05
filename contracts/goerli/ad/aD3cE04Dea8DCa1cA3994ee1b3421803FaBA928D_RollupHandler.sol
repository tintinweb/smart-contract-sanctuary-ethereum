// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

import "./HandlerHelpers.sol";
import "../interfaces/IExecuteProposal.sol";
import "../interfaces/IGetRollupInfo.sol";
import "../../utils/rollup/RollupTypes.sol";

contract RollupHandler is IGetRollupInfo, IExecuteProposal, HandlerHelpers {
    constructor(address bridgeAddress) HandlerHelpers(bridgeAddress) {}

    mapping(uint72 => Metadata) public rollupMetadata;

    struct Metadata {
        uint8 domainID;
        bytes32 resourceID;
        uint64 nonce;
        bytes32 rootHash;
        uint64 totalBatches;
    }

    /// @notice Proposal execution should be initiated when a proposal is finalized in the Bridge contract.
    ///
    /// @notice Requirements:
    /// - It must be called by only bridge.
    /// - {resourceID} must exist.
    /// - {contractAddress} must be allowed.
    /// - {resourceID} must be equal to the resource ID from metadata
    /// - Sender resource ID must exist.
    /// - Sender contract address must be allowed.
    ///
    /// @param data Consists of {resourceID}, {lenMetaData}, and {metaData}.
    ///
    /// @notice Data passed into the function should be constructed as follows:
    /// len(data)                              uint256     bytes  0  - 32
    /// data                                   bytes       bytes  32 - END
    ///
    /// @notice If {_contractAddressToExecuteFunctionSignature}[{contractAddress}] is set,
    /// {metaData} is expected to consist of needed function arguments.
    function executeProposal(bytes32 resourceID, bytes calldata data)
        external
        onlyBridge
    {
        address contractAddress = _resourceIDToTokenContractAddress[resourceID];
        require(contractAddress != address(0), "invalid resource ID");
        require(
            _contractWhitelist[contractAddress],
            "not an allowed contract address"
        );

        Metadata memory md = abi.decode(data, (Metadata));
        require(md.resourceID == resourceID, "different resource IDs");

        uint72 nonceAndID = (uint72(md.nonce) << 8) | uint72(md.domainID);
        rollupMetadata[nonceAndID] = md;
    }

    /// @notice Returns rollup info by original domain ID, resource ID and nonce.
    ///
    /// @notice Requirements:
    /// - {resourceID} must exist.
    /// - {resourceID} must be equal to the resource ID from metadata
    function getRollupInfo(
        uint8 originDomainID,
        bytes32 resourceID,
        uint64 nonce
    )
        external
        view
        returns (
            address,
            bytes32,
            uint64
        )
    {
        address settleableAddress = _resourceIDToTokenContractAddress[
            resourceID
        ];
        require(settleableAddress != address(0), "invalid resource ID");

        uint72 nonceAndID = (uint72(nonce) << 8) | uint72(originDomainID);
        Metadata memory md = rollupMetadata[nonceAndID];
        require(md.resourceID == resourceID, "different resource IDs");

        return (settleableAddress, md.rootHash, md.totalBatches);
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

import "../interfaces/IERCHandler.sol";

/// @notice This contract is intended to be used with the Bridge contract.

contract HandlerHelpers is IERCHandler {
    address public immutable _bridgeAddress;

    // resourceID => token contract address
    mapping(bytes32 => address) public _resourceIDToTokenContractAddress;

    // token contract address => resourceID
    mapping(address => bytes32) public _tokenContractAddressToResourceID;

    // token contract address => is whitelisted
    mapping(address => bool) public _contractWhitelist;

    // token contract address => is burnable
    mapping(address => bool) public _burnList;

    modifier onlyBridge() {
        _onlyBridge();
        _;
    }

    /// @param bridgeAddress Contract address of previously deployed Bridge.
    constructor(address bridgeAddress) {
        _bridgeAddress = bridgeAddress;
    }

    function _onlyBridge() private view {
        require(msg.sender == _bridgeAddress, "sender must be bridge contract");
    }

    /// @notice Sets {_resourceIDToContractAddress} with {contractAddress},
    /// {_contractAddressToResourceID} with {resourceID},
    /// and {_contractWhitelist} to true for {contractAddress}.
    /// @param resourceID ResourceID to be used when making deposits.
    /// @param contractAddress Address of contract to be called when a deposit is made and a deposited is executed.
    function setResource(bytes32 resourceID, address contractAddress)
        external
        override
        onlyBridge
    {
        _setResource(resourceID, contractAddress);
    }

    /// @notice First verifies {contractAddress} is whitelisted, then sets {_burnList}[{contractAddress}]
    /// to true.
    /// @param contractAddress Address of contract to be used when making or executing deposits.
    function setBurnable(address contractAddress) external override onlyBridge {
        _setBurnable(contractAddress);
    }

    function withdraw(bytes memory data) external virtual override {}

    function _setResource(bytes32 resourceID, address contractAddress)
        internal
    {
        _resourceIDToTokenContractAddress[resourceID] = contractAddress;
        _tokenContractAddressToResourceID[contractAddress] = resourceID;

        _contractWhitelist[contractAddress] = true;
    }

    function _setBurnable(address contractAddress) internal {
        // solhint-disable-next-line reason-string
        require(
            _contractWhitelist[contractAddress],
            "provided contract is not whitelisted"
        );
        _burnList[contractAddress] = true;
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

interface IExecuteProposal {
    /// @notice It is intended that proposals are executed by the Bridge contract.
    /// @param resourceID ResourceID to be used.
    /// @param data Consists of additional data needed for a specific deposit execution.
    function executeProposal(bytes32 resourceID, bytes calldata data) external;
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

interface IGetRollupInfo {
    function getRollupInfo(
        uint8 originDomainID,
        bytes32 resourceID,
        uint64 nonce
    )
        external
        view
        returns (
            address,
            bytes32,
            uint64
        );
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

struct StateContext {
    bool _writable;
    bytes32 _hash; // writable
    uint256 _startBlock; // writable
    // readable
    uint8 _epoch;
}

struct KeyValuePair {
    bytes key;
    bytes value;
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

interface IERCHandler {
    /// @notice gets token contract address.
    /// @param resourceID resource ID that is mapped to the contract address.
    /// @return tokenContractAddress contract address that is mapped to the resource ID.
    function _resourceIDToTokenContractAddress(bytes32 resourceID)
        external
        view
        returns (address);

    /// @notice Correlates {resourceID} with {contractAddress}.
    /// @param resourceID ResourceID to be used when making deposits.
    /// @param contractAddress Address of contract to be called when a deposit is made and a deposited is executed.
    function setResource(bytes32 resourceID, address contractAddress) external;

    /// @notice Marks {contractAddress} as mintable/burnable.
    /// @param contractAddress Address of contract to be used when making or executing deposits.
    function setBurnable(address contractAddress) external;

    /// @notice Withdraw funds from ERC safes.
    /// @param data ABI-encoded withdrawal params relevant to the handler.
    function withdraw(bytes memory data) external;
}