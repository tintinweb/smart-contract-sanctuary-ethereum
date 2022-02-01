// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
*
* Implementation of a diamond.
/******************************************************************************/

import "./libraries/LibDiamond.sol";
import "./interfaces/IDiamondCut.sol";
import "./interfaces/IDiamondLoupe.sol";

contract Diamond {

    constructor(IDiamondCut.FacetCut[] memory _diamondCut, address _init, bytes memory _calldata) payable {
        LibDiamond.diamondCut(_diamondCut, _init, _calldata);
    }

    // Find facet for function that is called and execute the
    // function if a facet is found and return any value.
    fallback() external payable {
        LibDiamond.DiamondStorage storage ds;
        bytes32 position = LibDiamond.DIAMOND_STORAGE_POSITION;
        // get diamond storage
        assembly {
            ds.slot := position
        }
        // get facet from function selector
        address facet = address(bytes20(ds.facets[msg.sig]));
        require(facet != address(0), "Diamond: Function does not exist");
        // Execute external function from facet using delegatecall and return any value.
        assembly {
            // copy function selector and any arguments
            calldatacopy(0, 0, calldatasize())
            // execute function call using the facet
            let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/
import { IDiamondCut } from "../interfaces/IDiamondCut.sol";

library LibDiamond {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

    struct DiamondStorage {
        // maps function selectors to the facets that execute the functions.
        // and maps the selectors to their position in the selectorSlots array.
        // func selector => address facet, selector position
        mapping(bytes4 => bytes32) facets;
        // array of slots of function selectors.
        // each slot holds 8 function selectors.
        mapping(uint256 => bytes32) selectorSlots;
        // The number of function selectors in selectorSlots
        uint16 selectorCount;
    }

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    event DiamondCut(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);

    bytes32 constant CLEAR_ADDRESS_MASK = bytes32(uint256(0xffffffffffffffffffffffff));
    bytes32 constant CLEAR_SELECTOR_MASK = bytes32(uint256(0xffffffff << 224));

    // Internal function version of diamondCut
    // This code is almost the same as the external diamondCut,
    // except it is using 'Facet[] memory _diamondCut' instead of
    // 'Facet[] calldata _diamondCut'.
    // The code is duplicated to prevent copying calldata to memory which
    // causes an error for a two dimensional array.
    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        DiamondStorage storage ds = diamondStorage();
        uint256 originalSelectorCount = ds.selectorCount;
        uint256 selectorCount = originalSelectorCount;
        bytes32 selectorSlot;
        // Check if last selector slot is not full
        // "selectorCount & 7" is a gas efficient modulo by eight "selectorCount % 8"
        if (selectorCount & 7 > 0) {
            // get last selectorSlot
            // "selectorSlot >> 3" is a gas efficient division by 8 "selectorSlot / 8"
            selectorSlot = ds.selectorSlots[selectorCount >> 3];
        }
        // loop through diamond cut
        for (uint256 facetIndex; facetIndex < _diamondCut.length; facetIndex++) {
            (selectorCount, selectorSlot) = addReplaceRemoveFacetSelectors(
                selectorCount,
                selectorSlot,
                _diamondCut[facetIndex].facetAddress,
                _diamondCut[facetIndex].action,
                _diamondCut[facetIndex].functionSelectors
            );
        }
        if (selectorCount != originalSelectorCount) {
            ds.selectorCount = uint16(selectorCount);
        }
        // If last selector slot is not full
        // "selectorCount & 7" is a gas efficient modulo by eight "selectorCount % 8"
        if (selectorCount & 7 > 0) {
            // "selectorSlot >> 3" is a gas efficient division by 8 "selectorSlot / 8"
            ds.selectorSlots[selectorCount >> 3] = selectorSlot;
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addReplaceRemoveFacetSelectors(
        uint256 _selectorCount,
        bytes32 _selectorSlot,
        address _newFacetAddress,
        IDiamondCut.FacetCutAction _action,
        bytes4[] memory _selectors
    ) internal returns (uint256, bytes32) {
        DiamondStorage storage ds = diamondStorage();
        require(_selectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        if (_action == IDiamondCut.FacetCutAction.Add) {
            enforceHasContractCode(_newFacetAddress, "LibDiamondCut: Add facet has no code");
            for (uint256 selectorIndex; selectorIndex < _selectors.length; selectorIndex++) {
                bytes4 selector = _selectors[selectorIndex];
                bytes32 oldFacet = ds.facets[selector];
                require(address(bytes20(oldFacet)) == address(0), "LibDiamondCut: Can't add function that already exists");
                // add facet for selector
                ds.facets[selector] = bytes20(_newFacetAddress) | bytes32(_selectorCount);
                // "_selectorCount & 7" is a gas efficient modulo by eight "_selectorCount % 8"
                uint256 selectorInSlotPosition = (_selectorCount & 7) << 5;
                // clear selector position in slot and add selector
                _selectorSlot = (_selectorSlot & ~(CLEAR_SELECTOR_MASK >> selectorInSlotPosition)) | (bytes32(selector) >> selectorInSlotPosition);
                // if slot is full then write it to storage
                if (selectorInSlotPosition == 224) {
                    // "_selectorSlot >> 3" is a gas efficient division by 8 "_selectorSlot / 8"
                    ds.selectorSlots[_selectorCount >> 3] = _selectorSlot;
                    _selectorSlot = 0;
                }
                _selectorCount++;
            }
        } else if (_action == IDiamondCut.FacetCutAction.Replace) {
            enforceHasContractCode(_newFacetAddress, "LibDiamondCut: Replace facet has no code");
            for (uint256 selectorIndex; selectorIndex < _selectors.length; selectorIndex++) {
                bytes4 selector = _selectors[selectorIndex];
                bytes32 oldFacet = ds.facets[selector];
                address oldFacetAddress = address(bytes20(oldFacet));
                // only useful if immutable functions exist
                require(oldFacetAddress != address(this), "LibDiamondCut: Can't replace immutable function");
                require(oldFacetAddress != _newFacetAddress, "LibDiamondCut: Can't replace function with same function");
                require(oldFacetAddress != address(0), "LibDiamondCut: Can't replace function that doesn't exist");
                // replace old facet address
                ds.facets[selector] = (oldFacet & CLEAR_ADDRESS_MASK) | bytes20(_newFacetAddress);
            }
        } else if (_action == IDiamondCut.FacetCutAction.Remove) {
            require(_newFacetAddress == address(0), "LibDiamondCut: Remove facet address must be address(0)");
            // "_selectorCount >> 3" is a gas efficient division by 8 "_selectorCount / 8"
            uint256 selectorSlotCount = _selectorCount >> 3;
            // "_selectorCount & 7" is a gas efficient modulo by eight "_selectorCount % 8"
            uint256 selectorInSlotIndex = _selectorCount & 7;
            for (uint256 selectorIndex; selectorIndex < _selectors.length; selectorIndex++) {
                if (_selectorSlot == 0) {
                    // get last selectorSlot
                    selectorSlotCount--;
                    _selectorSlot = ds.selectorSlots[selectorSlotCount];
                    selectorInSlotIndex = 7;
                } else {
                    selectorInSlotIndex--;
                }
                bytes4 lastSelector;
                uint256 oldSelectorsSlotCount;
                uint256 oldSelectorInSlotPosition;
                // adding a block here prevents stack too deep error
                {
                    bytes4 selector = _selectors[selectorIndex];
                    bytes32 oldFacet = ds.facets[selector];
                    require(address(bytes20(oldFacet)) != address(0), "LibDiamondCut: Can't remove function that doesn't exist");
                    // only useful if immutable functions exist
                    require(address(bytes20(oldFacet)) != address(this), "LibDiamondCut: Can't remove immutable function");
                    // replace selector with last selector in ds.facets
                    // gets the last selector
                    lastSelector = bytes4(_selectorSlot << (selectorInSlotIndex << 5));
                    if (lastSelector != selector) {
                        // update last selector slot position info
                        ds.facets[lastSelector] = (oldFacet & CLEAR_ADDRESS_MASK) | bytes20(ds.facets[lastSelector]);
                    }
                    delete ds.facets[selector];
                    uint256 oldSelectorCount = uint16(uint256(oldFacet));
                    // "oldSelectorCount >> 3" is a gas efficient division by 8 "oldSelectorCount / 8"
                    oldSelectorsSlotCount = oldSelectorCount >> 3;
                    // "oldSelectorCount & 7" is a gas efficient modulo by eight "oldSelectorCount % 8"
                    oldSelectorInSlotPosition = (oldSelectorCount & 7) << 5;
                }
                if (oldSelectorsSlotCount != selectorSlotCount) {
                    bytes32 oldSelectorSlot = ds.selectorSlots[oldSelectorsSlotCount];
                    // clears the selector we are deleting and puts the last selector in its place.
                    oldSelectorSlot =
                        (oldSelectorSlot & ~(CLEAR_SELECTOR_MASK >> oldSelectorInSlotPosition)) |
                        (bytes32(lastSelector) >> oldSelectorInSlotPosition);
                    // update storage with the modified slot
                    ds.selectorSlots[oldSelectorsSlotCount] = oldSelectorSlot;
                } else {
                    // clears the selector we are deleting and puts the last selector in its place.
                    _selectorSlot =
                        (_selectorSlot & ~(CLEAR_SELECTOR_MASK >> oldSelectorInSlotPosition)) |
                        (bytes32(lastSelector) >> oldSelectorInSlotPosition);
                }
                if (selectorInSlotIndex == 0) {
                    delete ds.selectorSlots[selectorSlotCount];
                    _selectorSlot = 0;
                }
            }
            _selectorCount = selectorSlotCount * 8 + selectorInSlotIndex;
        } else {
            revert("LibDiamondCut: Incorrect FacetCutAction");
        }
        return (_selectorCount, _selectorSlot);
    }

    function initializeDiamondCut(address _init, bytes memory _calldata) internal {
        if (_init == address(0)) {
            require(_calldata.length == 0, "LibDiamondCut: _init is address(0) but_calldata is not empty");
        } else {
            require(_calldata.length > 0, "LibDiamondCut: _calldata is empty but _init is not address(0)");
            if (_init != address(this)) {
                enforceHasContractCode(_init, "LibDiamondCut: _init address has no code");
            }
            (bool success, bytes memory error) = _init.delegatecall(_calldata);
            if (!success) {
                if (error.length > 0) {
                    // bubble up the error
                    revert(string(error));
                } else {
                    revert("LibDiamondCut: _init function reverted");
                }
            }
        }
    }

    function enforceHasContractCode(address _contract, string memory _errorMessage) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

interface IDiamondCut {
    enum FacetCutAction {Add, Replace, Remove}
    // Add=0, Replace=1, Remove=2

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

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
    function facetFunctionSelectors(address _facet) external view returns (bytes4[] memory facetFunctionSelectors_);

    /// @notice Get all the facet addresses used by a diamond.
    /// @return facetAddresses_
    function facetAddresses() external view returns (address[] memory facetAddresses_);

    /// @notice Gets the facet that supports the given selector.
    /// @dev If facet is not found return address(0).
    /// @param _functionSelector The function selector.
    /// @return facetAddress_ The facet address.
    function facetAddress(bytes4 _functionSelector) external view returns (address facetAddress_);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import "./IDiamondCutGovernable.sol";
import "./IDiamondLoupe.sol";
import "./IRouter.sol";
import "./ITeleportDApp.sol";
import "./IGovernance.sol";
import "./IUtility.sol";

interface IRouterDiamond is IGovernance, IDiamondCutGovernable, IDiamondLoupe, IUtility, IRouter, ITeleportDApp {}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

import "./IDiamondCut.sol";

interface IDiamondCutGovernable is IDiamondCut {
    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    /// @param _signatures Governance members' signatures authorizing the operation
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata,
        bytes[] calldata _signatures
    ) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import "../libraries/LibRouter.sol";

interface IRouter {
    enum TargetAction {Unlock, Mint}

    struct CollectionWithTokens {
        address collection;
        uint256[] tokenIds;
    }

    /// @notice An event emitted once a Lock transaction is executed
    event LockMint(uint8 targetChain, address collection, uint256[] tokenIds, bytes receiver);
    /// @notice An event emitted once a Burn transaction is executed
    event BurnMint(uint8 targetChain, address collection, uint256[] tokenIds, bytes receiver);
    /// @notice An event emitted once a BurnAndTransfer transaction is executed
    event BurnUnlock(uint8 targetChain, address collection, uint256[] tokenIds, bytes receiver);
    /// @notice An event emitted once an Unlock transaction is executed
    event Unlock(address collection, uint256[] tokenIds, address receiver);
    /// @notice An even emitted once a Mint transaction is executed
    event Mint(address collection, uint256[] tokenIds, address receiver);
    /// @notice An event emitted once a new wrapped token is deployed by the contract
    event WrappedCollectionDeployed(uint8 sourceChain, bytes nativeColllection, address wrappedColllection);
    /// @notice An event emitted when setting the teleport address
    event TeleportAddressSet(address teleportAddress);


    function nativeToWrappedCollection(uint8 _chainId, bytes memory _nativeCollection) external view returns (address);
    function wrappedToNativeCollection(address _wrappedCollection) external view returns (LibRouter.NativeCollectionWithChainId memory);
    function serviceFee() external view returns (uint256);

    function egress(
        uint8 targetChain_,
        CollectionWithTokens[] calldata assets, bytes calldata receiver_) external payable;

}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

interface ITeleportDApp {
    /**
     * @notice Called by a Teleport contract to deliver a verified payload to a dApp
     * @param _sourceChainId The chainID where the transmission originated
     * @param _transmissionSender The address that invoked `transmit()` on the source chain
     * @param _dAppId an identifier for the dApp
     * @param _payload a dApp-specific byte array with the message data
     */
    function onTeleportMessage(
        uint8 _sourceChainId,
        bytes calldata _transmissionSender,
        bytes32 _dAppId,
        bytes calldata _payload) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

interface IGovernance {
    /// @notice An event emitted once member is updated
    event MemberUpdated(address member, bool status);

    /**
     *  @notice Initializes the Governance facet with an initial set of members
     *  @param data_ Calldata containing the initial set of members
     */
    function init(bytes memory data_) external;

    /**
     *  @notice Adds/removes a member account
     *  @param _account The account to be modified
     *  @param _status Whether the account will be set as member or not
     *  @param _signatures The signatures of the validators authorizing this member update
     */
    function updateMember(address _account, bool _status, bytes[] calldata _signatures) external;

    /// @return True/false depending on whether a given address is member or not
    function isMember(address _member) external view returns (bool);

    /// @return The count of members in the members set
    function membersCount() external view returns (uint256);

    /// @return The address of a member at a given index
    function memberAt(uint256 _index) external view returns (address);

    /// @return The current administrative nonce
    function administrativeNonce() external view returns (uint256);
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

interface IUtility {

    struct SubInit {
        address contractAddress;
        bytes callParams;
    }

    struct TeleportSender {
        uint8 chainId;
        bytes senderAddress;
    }

    enum CollectionAction {Pause, Unpause}

    function pauseCollection(address collectionAddress_, bytes[] calldata signatures_) external;
    function unpauseCollection(address collectionAddress_, bytes[] calldata signatures_) external;

    function setWrappedCollection(
        uint8 nativeChainId_, bytes calldata _nativeCollection, address wrappedCollection_, bytes[] calldata signatures_
    ) external;
    function unsetWrappedCollection(address wrappedCollection_, bytes[] calldata signatures_) external;

    function setTeleportSenders(TeleportSender[] calldata senders_, bytes[] calldata signatures_) external;
    function dappId() external view returns (bytes32);
    function setDappId(bytes32 dappId_, bytes[] calldata signatures_) external;

    event CollectionPaused(address account_, address collection_);
    event CollectionUnpaused(address account_, address collection_);
    event WrappedCollectionSet(uint8 nativeChainId_, bytes _nativeCollection, address wrappedCollection_);
    event WrappedCollectionUnset(address wrappedCollection_);
    event TeleportSenderSet(TeleportSender[] senders_);
    event DappIdSet(bytes32 dappId_);

}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

library LibRouter {
    bytes32 constant STORAGE_POSITION = keccak256("diamond.standard.router.storage");

    /// @notice Struct containing information about a token's address and its native chain
    struct NativeCollectionWithChainId {
        uint8 chainId;
        bytes contractAddress;
    }

    struct Storage {
        // Maps chainId => (nativeToken => wrappedToken)
        mapping(uint8 => mapping(bytes => address)) nativeToWrappedCollection;

        // Maps wrapped tokens in the current chain to their native chain + token address
        mapping(address => NativeCollectionWithChainId) wrappedToNativeCollection;

        // Who is allowed to send us teleport messages
        mapping(uint8 => bytes) bridgeAddressByChainId;

        // The chainId of the current chain
        uint8 chainId;
        address teleportAddress;
        bytes32 dAppId;
    }

    /// @notice sets the wrapped to native token mapping
    function setCollectionMappings(uint8 sourceChain_, bytes memory nativeCollection_, address deployedCollection) internal {
        Storage storage rs = routerStorage();
        rs.nativeToWrappedCollection[sourceChain_][nativeCollection_] = deployedCollection;
        rs.wrappedToNativeCollection[deployedCollection].chainId = sourceChain_;
        rs.wrappedToNativeCollection[deployedCollection].contractAddress = nativeCollection_;
    }

    function routerStorage() internal pure returns (Storage storage ds) {
        bytes32 position = STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import "../libraries/LibRouter.sol";
import "../libraries/LibDiamond.sol";

import "../WrappedERC721.sol";
import "../Governable.sol";

import "../interfaces/IUtility.sol";

contract UtilityFacet is IUtility, Governable {
    using Counters for Counters.Counter;

    /**
     * @notice Calls the init functions of other diamond facets
     * @dev This method is to be delegatecall-ed from diamondCutGovernableFacet.diamondCut
     * and takes as parameter the encoded call data for the init methods of any other diamond facets.
     */
    function init(bytes memory data_) external {
        (IUtility.SubInit[] memory subInits) = abi.decode(data_,
            (IUtility.SubInit[]));

        for (uint256 i = 0; i < subInits.length; i++) {
            // callParams is abi.encodeWithSignature("init(bytes)", _bytes)
            LibDiamond.initializeDiamondCut(subInits[i].contractAddress, subInits[i].callParams);
        }
    }

    /**
     *  @notice Pauses a given collection contract
     *  @param collectionAddress_ The collection contract
     *  @param signatures_ The array of signatures from the members, authorising the operation
     */
    function pauseCollection(address collectionAddress_, bytes[] calldata signatures_)
        external override
        onlyConsensusNonce(computeCollectionActionMessage(IUtility.CollectionAction.Pause, collectionAddress_), signatures_)
    {
        WrappedERC721(collectionAddress_).pause();
        emit CollectionPaused(msg.sender, collectionAddress_);
    }

    /**
     *  @notice Unpauses a given collection contract
     *  @param collectionAddress_ The collection contract
     *  @param signatures_ The array of signatures from the members, authorising the operation
     */
    function unpauseCollection(address collectionAddress_, bytes[] calldata signatures_)
        external override
        onlyConsensusNonce(computeCollectionActionMessage(IUtility.CollectionAction.Unpause, collectionAddress_), signatures_)
    {
        WrappedERC721(collectionAddress_).unpause();
        emit CollectionUnpaused(msg.sender, collectionAddress_);
    }

    /**
     *  @param _action denotes pause or unpause
     *  @param _collectionAddress The collection address
     *  @return Hash message represeting the pause/unpause collection operation
     */
    function computeCollectionActionMessage(IUtility.CollectionAction _action, address _collectionAddress) internal view returns (bytes32) {
        return ECDSA.toEthSignedMessageHash(keccak256(
            abi.encode(
                LibRouter.routerStorage().chainId, "computeCollectionActionMessage",
                uint8(_action), _collectionAddress,
                LibGovernance.governanceStorage().administrativeNonce.current())
            )
        );
    }

    /**
     *  @notice Adds an existing collection contract to use as a WrappedERC721
     *  @param nativeChainId_ The native network for the collection
     *  @param nativeCollection_ The address in the native network
     *  @param wrappedCollection_ The wrapped collection address in this network
     *  @param signatures_ The array of signatures from the members, authorising the operation
     */
    function setWrappedCollection(uint8 nativeChainId_, bytes calldata nativeCollection_, address wrappedCollection_, bytes[] calldata signatures_)
        external override
        onlyConsensusNonce(computeSetWrappedCollectionMessage(nativeChainId_, nativeCollection_, wrappedCollection_), signatures_)
    {
        require(wrappedCollection_ != address(0), "Wrapped collection address must be non-zero");
        LibRouter.setCollectionMappings(nativeChainId_, nativeCollection_, wrappedCollection_);
        emit WrappedCollectionSet(nativeChainId_, nativeCollection_, wrappedCollection_);
    }

    /**
     *  @notice Computes the Eth signed message to use for extracting signature signers for toggling a collection state
     *  @param nativeChainId_ The native network for the collection
     *  @param nativeCollection_ The address in the native network
     *  @param wrappedCollection_ The wrapped collection address in this network
     */
    function computeSetWrappedCollectionMessage(uint8 nativeChainId_, bytes calldata nativeCollection_, address wrappedCollection_)
        internal view returns (bytes32)
    {
        return ECDSA.toEthSignedMessageHash(keccak256(
            abi.encode(
                LibRouter.routerStorage().chainId, "computeSetWrappedCollectionMessage",
                nativeChainId_, nativeCollection_, wrappedCollection_,
                LibGovernance.governanceStorage().administrativeNonce.current())
            )
        );
    }

    /**
     *  @notice Removes a wrapped-native collection pair from the bridge
     *  @param wrappedCollection_ The wrapped collection address in this network
     *  @param signatures_ The array of signatures from the members, authorising the operation
     */
    function unsetWrappedCollection(address wrappedCollection_, bytes[] calldata signatures_)
        external override
        onlyConsensusNonce(computeUnsetWrappedCollectionMessage(wrappedCollection_), signatures_)
    {
        LibRouter.Storage storage rs = LibRouter.routerStorage();
        delete rs.nativeToWrappedCollection[rs.wrappedToNativeCollection[wrappedCollection_].chainId][rs.wrappedToNativeCollection[wrappedCollection_].contractAddress];
        delete rs.wrappedToNativeCollection[wrappedCollection_];
        emit WrappedCollectionUnset(wrappedCollection_);
    }

    /**
     *  @notice Computes the Eth signed message to use for extracting signature signers for toggling a collection state
     *  @param wrappedCollection_ The wrapped collection address in this network
     */
    function computeUnsetWrappedCollectionMessage(address wrappedCollection_)
        internal view returns (bytes32)
    {
        return ECDSA.toEthSignedMessageHash(keccak256(
            abi.encode(
                LibRouter.routerStorage().chainId, "computeUnsetWrappedCollectionMessage",
                wrappedCollection_,
                LibGovernance.governanceStorage().administrativeNonce.current())
            )
        );
    }

    /**
     *  @notice Set the allowed state for the specified teleport senders
     *  @param senders_ Array of chainId and sender
     *  @param signatures_ The array of signatures from the members, authorising the operation
     */
    function setTeleportSenders(TeleportSender[] calldata senders_, bytes[] calldata signatures_)
        external override
        onlyConsensusNonce(computeSetTeleportSenders(senders_), signatures_)
    {
        LibRouter.Storage storage rs = LibRouter.routerStorage();
        for (uint256 i = 0; i < senders_.length; i++) {
            rs.bridgeAddressByChainId[senders_[i].chainId] = senders_[i].senderAddress;
        }

        emit TeleportSenderSet(senders_);
    }

    /**
     *  @param senders_ Array of chainId and sender
     *  @return Hash message represeting the setTeleportSenders operation
     */
    function computeSetTeleportSenders(TeleportSender[] calldata senders_) internal view returns (bytes32) {
        return ECDSA.toEthSignedMessageHash(keccak256(
            abi.encode(
                LibRouter.routerStorage().chainId, "computeSetTeleportSenders",
                senders_,
                LibGovernance.governanceStorage().administrativeNonce.current())
            )
        );
    }

    /**
     *  @return Set the bridge dappId
     */
    function dappId() external view override returns (bytes32) {
        return LibRouter.routerStorage().dAppId;
    }

    /**
     *  @notice Set the bridge dappId
     *  @param dappId_ Array of chainId and sender
     *  @param signatures_ The array of signatures from the members, authorising the operation
     */
    function setDappId(bytes32 dappId_, bytes[] calldata signatures_)
        external override
        onlyConsensusNonce(computeSetDappId(dappId_), signatures_)
    {
        LibRouter.routerStorage().dAppId = dappId_;

        emit DappIdSet(dappId_);
    }

    /**
     *  @param dappId_ dappId hash
     *  @return Hash message represeting the setTeleportSenders operation
     */
    function computeSetDappId(bytes32 dappId_) internal view returns (bytes32) {
        return ECDSA.toEthSignedMessageHash(keccak256(
            abi.encode(
                LibRouter.routerStorage().chainId, "computeSetDappId",
                dappId_,
                LibGovernance.governanceStorage().administrativeNonce.current())
            )
        );
    }


}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

/**
 * @notice Used for the wrapped versions of bridged ERC721 collections
 */
contract WrappedERC721 is ERC721Enumerable, Pausable, Ownable {
    /// @dev We can't use baseURI as it is non-standard, so we manage tokenURIs individually
    mapping(uint256 => string) private _tokenURIs;

    /**
     *  @notice Construct a new WrappedERC721 contract
     *  @param collectionName_ The collection name
     *  @param collectionSymbol_ The collection symbol
     */
    constructor(
        string memory collectionName_,
        string memory collectionSymbol_
    ) ERC721(collectionName_, collectionSymbol_) {}

    /**
     * @param tokenId_ ID of the token
     * @return The token URI
     */
    function tokenURI(uint256 tokenId_) public view override returns (string memory) {
        require(_exists(tokenId_), "WrappedERC721: URI query for nonexistent token");
        return _tokenURIs[tokenId_];
    }

    /**
     * @notice Mints a number of tokens at once
     * @param to_ Receiver address
     * @param tokenIds_ Array of token IDs
     * @param tokenURIs_ Array of corresponding token URIs
     */
    function batchMint(address to_, uint256[] calldata tokenIds_, string[] calldata tokenURIs_)
        external onlyOwner
    {
        require(tokenIds_.length == tokenURIs_.length, "WrappedERC721: wrong batchMint parameters");
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            super._safeMint(to_, tokenIds_[i]);
            _tokenURIs[tokenIds_[i]] = tokenURIs_[i];
        }
    }

    /**
     * @notice Burns a number of tokens at once
     * @param owner_ Owner of the tokens
     * @param tokenIds_ Array of token IDs
     */
    function batchBurnFrom(address owner_, uint256[] calldata tokenIds_)
        external onlyOwner
    {
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            require(_isApprovedOrOwner(_msgSender(), tokenIds_[i]), "WrappedERC721: burn not approved");
            require(ownerOf(tokenIds_[i]) == owner_, "WrappedERC721: wrong owner");
            super._burn(tokenIds_[i]);
            delete _tokenURIs[tokenIds_[i]];
        }
    }

    /**
     * @notice Updates the token URIs for existing tokens
     * @param tokenIds_ Array of token IDs
     * @param tokenURIs_ Array of corresponding token URIs
     */
    function batchUpdateTokenURI(uint256[] calldata tokenIds_, string[] calldata tokenURIs_)
        external onlyOwner
    {
        require(tokenIds_.length == tokenURIs_.length, "WrappedERC721: wrong batchUpdate parameters");
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            require(_exists(tokenIds_[i]), "WrappedERC721: URI query for nonexistent token");
            _tokenURIs[tokenIds_[i]] = tokenURIs_[i];
        }
    }

    /// @notice Pauses the contract
    function pause() public onlyOwner {
        super._pause();
    }

    /// @notice Unpauses the contract
    function unpause() public onlyOwner {
        super._unpause();
    }

    /// @notice Prevent actions on a paused contract
    function _beforeTokenTransfer(address from_, address to_, uint256 tokenId_) internal virtual override {
        super._beforeTokenTransfer(from_, to_, tokenId_);

        require(!paused(), "WrappedERC721: token transfer while paused");
    }

}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import "./libraries/LibGovernance.sol";

/**
 * @notice Provides modifiers for securing methods behind a governance vote
 */
abstract contract Governable {
    using Counters for Counters.Counter;

    /**
     * @notice Verifies the message hash against the signatures. Requires a majority.
     * @param _ethHash hash to verify
     * @param _signatures governance hash signatures
     */
    function onlyConsensus(bytes32 _ethHash, bytes[] calldata _signatures) internal view {
        uint256 members = LibGovernance.membersCount();
        require(_signatures.length <= members, "Governance: Invalid number of signatures");
        require(_signatures.length > members / 2, "Governance: Invalid number of signatures");

        address[] memory signers = new address[](_signatures.length);
        for (uint256 i = 0; i < _signatures.length; i++) {
            address signer = ECDSA.recover(_ethHash, _signatures[i]);
            require(LibGovernance.isMember(signer), "Governance: invalid signer");
            for (uint256 j = 0; j < i; j++) {
                require(signer != signers[j], "Governance: duplicate signatures");
            }
            signers[i] = signer;
        }
    }

    /**
     * @notice Verifies the message hash against the signatures. Requires a majority. Burns a nonce.
     * @param _ethHash hash to verify
     * @param _signatures governance hash signatures
     */
    modifier onlyConsensusNonce(bytes32 _ethHash, bytes[] calldata _signatures) {
        onlyConsensus(_ethHash, _signatures);
        LibGovernance.governanceStorage().administrativeNonce.increment();
        _;
    }

    /**
     * @notice Verifies the message hash against the signatures. Requires a majority. Burns the hash.
     * @param _ethHash hash to verify
     * @param _signatures governance hash signatures
     */
    modifier onlyConsensusHash(bytes32 _ethHash, bytes[] calldata _signatures) {
        LibGovernance.Storage storage gs = LibGovernance.governanceStorage();
        require(!gs.hashesUsed[_ethHash], "Governance: message hash already used");
        gs.hashesUsed[_ethHash] = true;
        onlyConsensus(_ethHash, _signatures);
        _;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

library LibGovernance {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Counters for Counters.Counter;
    bytes32 constant STORAGE_POSITION = keccak256("diamond.standard.governance.storage");

    struct Storage {
        // nonce used for making administrative changes
        Counters.Counter administrativeNonce;
        // the set of active validators
        EnumerableSet.AddressSet membersSet;
        // governance message hashes we've executed
        mapping(bytes32 => bool) hashesUsed;
    }

    function governanceStorage() internal pure returns (Storage storage gs) {
        bytes32 position = STORAGE_POSITION;
        assembly {
            gs.slot := position
        }
    }

    /// @notice Adds/removes a validator from the member set
    function updateMember(address _account, bool _status) internal {
        Storage storage gs = governanceStorage();
        if (_status) {
            require(
                gs.membersSet.add(_account),
                "Governance: Account already added"
            );
        } else if (!_status) {
            require(
                gs.membersSet.length() > 1,
                "Governance: Would become memberless"
            );
            require(
                gs.membersSet.remove(_account),
                "Governance: Account is not a member"
            );
        }
    }

    /// @notice Returns true/false depending on whether a given address is member or not
    function isMember(address _member) internal view returns (bool) {
        Storage storage gs = governanceStorage();
        return gs.membersSet.contains(_member);
    }

    /// @notice Returns the count of the members
    function membersCount() internal view returns (uint256) {
        Storage storage gs = governanceStorage();
        return gs.membersSet.length();
    }

    /// @notice Returns the address of a member at a given index
    function memberAt(uint256 _index) internal view returns (address) {
        Storage storage gs = governanceStorage();
        return gs.membersSet.at(_index);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Counters.sol";
import "../interfaces/IGovernance.sol";
import "../libraries/LibGovernance.sol";
import "../libraries/LibRouter.sol";
import "../Governable.sol";

/// @notice Handles the management of governance members
contract GovernanceFacet is IGovernance, Governable {
    using Counters for Counters.Counter;

    /**
     * @notice initializes the state for the Governance facet
     * @param data_ abi encoded data - the list of governance members.
     */
    function init(bytes memory data_) external override {
        (address[] memory members) = abi.decode(data_, (address[]));
        require(members.length > 0, "Governance: member list empty");
        for (uint256 i = 0; i < members.length; i++) {
            LibGovernance.updateMember(members[i], true);
            emit MemberUpdated(members[i], true);
        }
    }

    /**
     *  @notice Adds/removes a member account
     *  @param account_ The account to be modified
     *  @param status_ Whether the account will be set as member or not
     *  @param signatures_ The signatures of the validators authorizing this member update
     */
    function updateMember(address account_, bool status_, bytes[] calldata signatures_)
        onlyConsensusNonce(computeMemberUpdateMessage(account_, status_), signatures_)
        external override
    {
        LibGovernance.updateMember(account_, status_);
        emit MemberUpdated(account_, status_);
    }

    /// @notice Computes the bytes32 ethereum signed message hash of the member update message
    function computeMemberUpdateMessage(address account_, bool status_) internal view returns (bytes32) {
        return ECDSA.toEthSignedMessageHash(keccak256(
            abi.encode(
                LibRouter.routerStorage().chainId, "computeMemberUpdateMessage",
                account_, status_,
                LibGovernance.governanceStorage().administrativeNonce.current())
            )
        );
    }

    /// @return True/false depending on whether a given address is member or not
    function isMember(address member_) external view override returns (bool) {
        return LibGovernance.isMember(member_);
    }

    /// @return The count of members in the members set
    function membersCount() external view override returns (uint256) {
        return LibGovernance.membersCount();
    }

    /// @return The address of a member at a given index
    function memberAt(uint256 index_) external view override returns (address) {
        return LibGovernance.memberAt(index_);
    }

    /// @return The current administrative nonce
    function administrativeNonce() external view override returns (uint256) {
        return LibGovernance.governanceStorage().administrativeNonce.current();
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import "../../interfaces/ITeleport.sol";
import "../../libraries/LibRouter.sol";

contract Test2Facet {
    event TestEvent(uint256);

    function serviceFee() external returns (uint256 fee) {
        fee = ITeleport(LibRouter.routerStorage().teleportAddress).serviceFee();
        emit TestEvent(fee);
    }

    function F2() external pure returns (string memory) {
        return "Test2Facet::F2()";
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

interface ITeleport {
    /// @notice emitted when transmitting a payload
    event Transmission(bytes transmissionSender, uint8 targetChainId, bytes transmissionReceiver, bytes32 dAppId, bytes payload);
    /// @notice emitted when collecting fees
    event TransmissionFees(uint256 serviceFee);
    /// @notice emitted when delivering a payload
    event Delivery(bytes32 transmissionId);

    /// @return The currently set service fee
    function serviceFee() external view returns (uint256);

    function transmit(
        uint8 targetChainId,
        bytes calldata transmissionReceiver,
        bytes32 dAppId,
        bytes calldata payload
    ) external payable;

    function deliver(
        bytes32 transmissionId,
        uint8 sourceChainId,
        bytes calldata transmissionSender,
        address transmissionReceiver,
        bytes32 dAppId,
        bytes calldata payload,
        bytes[] calldata signatures
    ) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import "../WrappedERC721.sol";
import "../interfaces/IRouter.sol";
import "../interfaces/ITeleport.sol";
import "../interfaces/ITeleportDApp.sol";
import "../libraries/LibRouter.sol";

/**
 *  @notice Handles the bridging of ERC721 tokens
 */
contract RouterFacet is IRouter, ITeleportDApp {

    /**
     * @notice initializes the state for the Router facet
     * @param data_ abi encoded data - chain ID, teleport address and dAppId.
     */
    function init(bytes memory data_) external {
        LibRouter.Storage storage rs = LibRouter.routerStorage();
        (rs.chainId, rs.teleportAddress, rs.dAppId) = abi.decode(data_,
            (uint8, address, bytes32));

        emit TeleportAddressSet(rs.teleportAddress);
    }

    /**
     *  @notice Send tokens to another chain via Teleport.
     *  @param targetChainId_ Our ID of the destination chain
     *  @param assets_ An array of structs, containing a collection address and an array of token IDs
     *  @param receiver_ Address who will receive the tokens on the destination chain
     *  @dev We determine the action for each ERC721 contract (collection) and build the appropriate payload
     */
    function egress(uint8 targetChainId_,
        CollectionWithTokens[] calldata assets_, bytes calldata receiver_)
        external override payable
    {
        LibRouter.Storage storage rs = LibRouter.routerStorage();
        bytes[] memory actions = new bytes[](assets_.length);

        for (uint256 i = 0; i < assets_.length; i++) {
            LibRouter.NativeCollectionWithChainId memory nativeCollection = wrappedToNativeCollection(assets_[i].collection);

            if (nativeCollection.chainId == 0) {
                emit LockMint(targetChainId_, assets_[i].collection, assets_[i].tokenIds, receiver_);

                actions[i] = abi.encode(
                        IRouter.TargetAction.Mint, _addressToBytes(assets_[i].collection),
                        _lockMint(assets_[i].collection, assets_[i].tokenIds)
                    );
            }
            else {
                if (nativeCollection.chainId == targetChainId_) {
                    emit BurnUnlock(targetChainId_, assets_[i].collection, assets_[i].tokenIds, receiver_);

                    actions[i] = abi.encode(
                            IRouter.TargetAction.Unlock, nativeCollection.contractAddress,
                            _burnUnlock(assets_[i].collection, assets_[i].tokenIds)
                        );
                }
                else {
                    emit BurnMint(targetChainId_, assets_[i].collection, assets_[i].tokenIds, receiver_);

                    actions[i] = abi.encode(
                            IRouter.TargetAction.Mint, nativeCollection.contractAddress,
                            _burnMint(nativeCollection.chainId, assets_[i].collection, assets_[i].tokenIds)
                        );
                }
            }
        }

        bytes memory payload = abi.encode(
                receiver_,
                actions
            );

        uint256 feeOwed = serviceFee();
        require(msg.value >= feeOwed, "Router: insufficient fee");
        require(rs.bridgeAddressByChainId[targetChainId_].length > 0, "Router: unknown destination");
        ITeleport(rs.teleportAddress).transmit{value: msg.value}(
                targetChainId_, rs.bridgeAddressByChainId[targetChainId_], rs.dAppId,
                payload
            );
    }

    /**
     *  @param collectionAddress_ The ERC721 contract address
     *  @param tokenIds_ An array of token IDs to be locked and bridged
     *  @return Payload for sending native tokens to a non-native chain
     *  @dev If the ERC721 contract supports the metadata extension, we have to pass it too
     */
    function _lockMint(address collectionAddress_, uint256[] calldata tokenIds_) internal returns (bytes memory) {
        string[] memory tokenURIs = new string[](tokenIds_.length);
        string memory collectionName;
        string memory collectionSymbol;

        if (ERC721(collectionAddress_).supportsInterface(type(IERC721Metadata).interfaceId)) {
            for (uint256 i = 0; i < tokenIds_.length; i++) {
                tokenURIs[i] = ERC721(collectionAddress_).tokenURI(tokenIds_[i]);
                ERC721(collectionAddress_).transferFrom(msg.sender, address(this), tokenIds_[i]);
            }

            collectionName = string(abi.encodePacked("Wrapped ", ERC721(collectionAddress_).name()));
            collectionSymbol = string(abi.encodePacked("W", ERC721(collectionAddress_).symbol()));
        }
        else {
            for (uint256 i = 0; i < tokenIds_.length; i++) {
                ERC721(collectionAddress_).transferFrom(msg.sender, address(this), tokenIds_[i]);
            }
        }

        return abi.encode(tokenIds_, LibRouter.routerStorage().chainId, tokenURIs, collectionName, collectionSymbol);
    }

    /**
     *  @param collectionAddress_ The ERC721 contract address
     *  @param tokenIds_ An array of token IDs to be burned and bridged
     *  @return Payload for sending non-native tokens to their native chain
     */
    function _burnUnlock(address collectionAddress_, uint256[] calldata tokenIds_) internal returns (bytes memory) {
        // we need to check if msg.sender owns what he wants to transfer (burn)
        WrappedERC721(collectionAddress_).batchBurnFrom(msg.sender, tokenIds_);

        return abi.encode(tokenIds_);
    }

    /**
     *  @param collectionAddress_ The ERC721 contract address
     *  @param tokenIds_ An array of token IDs to be burned and bridged
     *  @return Payload for sending non-native tokens to a non-native chain
     */
    function _burnMint(uint8 nativeChainId_, address collectionAddress_, uint256[] calldata tokenIds_) internal returns (bytes memory) {
        string[] memory tokenURIs = new string[](tokenIds_.length);

        for (uint256 i = 0; i < tokenIds_.length; i++) {
            tokenURIs[i] = ERC721(collectionAddress_).tokenURI(tokenIds_[i]);
        }
        WrappedERC721(collectionAddress_).batchBurnFrom(msg.sender, tokenIds_);

        return abi.encode(tokenIds_, nativeChainId_, tokenURIs, ERC721(collectionAddress_).name(), ERC721(collectionAddress_).symbol());
    }

    /**
     *  @notice Receive tokens from another chain via Teleport.
     *  @param sourceChainId_ Chain ID the teleport message comes from
     *  @param transmissionSender_ Sender address of the teleport message
     *  @param dAppId_ dAppId for the teleport message
     *  @param payload_ Data payload of teleport message
     */
    function onTeleportMessage(
            uint8 sourceChainId_, bytes calldata transmissionSender_,
            bytes32 dAppId_, bytes calldata payload_)
        external override
    {
        // Check message validity
        LibRouter.Storage storage rs = LibRouter.routerStorage();
        require(msg.sender == rs.teleportAddress, "Router: unknown teleport");
        require(dAppId_ == rs.dAppId, "Router: unknown dAppId");
        require(keccak256(rs.bridgeAddressByChainId[sourceChainId_]) == keccak256(transmissionSender_), "Router: unknown sender");

        (bytes memory receiver, bytes[] memory actions) = abi.decode(payload_,
            (bytes, bytes[]));

        for (uint256 i = 0; i < actions.length; i++) {
            // Decode the common action data
            (IRouter.TargetAction actionType, bytes memory nativeAddress, bytes memory actionData) = abi.decode(actions[i],
                (IRouter.TargetAction, bytes, bytes));

            // and call the corresponding receive function
            if (actionType == IRouter.TargetAction.Unlock) {
                // with its specific payload
                (uint256[] memory tokenIds) = abi.decode(actionData, (uint256[]));
                _unlock(_bytesToAddress(nativeAddress), tokenIds, _bytesToAddress(receiver));
            }
            else {
                (uint256[] memory tokenIds, uint8 nativeChainId, string[] memory tokenURIs,
                    string memory collectionName, string memory collectionSymbol) = abi.decode(actionData,

                    (uint256[], uint8, string[],
                        string, string));

                _mint(nativeAddress, tokenIds, _bytesToAddress(receiver),
                    nativeChainId, tokenURIs, collectionName, collectionSymbol);
            }
        }
    }

    /**
     *  @notice Release previously locked native tokens.
     *  @param collectionAddress_ The ERC721 contract address
     *  @param tokenIds_ The token IDs to be unlocked
     *  @param receiver_ The address to receive the tokens
     */
    function _unlock(address collectionAddress_, uint256[] memory tokenIds_, address receiver_) internal {
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            // sends tokens to unknown user supplied address, so we are being safe
            ERC721(collectionAddress_).safeTransferFrom(address(this), receiver_, tokenIds_[i]);
        }
        emit Unlock(collectionAddress_, tokenIds_, receiver_);
    }

    /**
     *  @notice Mint wrapped versions of non-native tokens. Deploys a new collection contract if necessary.
     *  @param nativeAddress_ The ERC721 contract address on the native chain
     *  @param tokenIds_ The token IDs to be minted
     *  @param receiver_ The address to receive the tokens
     *  @param nativeChainId_ Our chain ID for the native network
     *  @param tokenURIs_ Token URIs for the new tokens
     *  @param collectionName_ Name for the wrapped collection
     *  @param collectionSymbol_ Symbol for the wrapped collection
     */
    function _mint(bytes memory nativeAddress_, uint256[] memory tokenIds_, address receiver_,
            uint8 nativeChainId_, string[] memory tokenURIs_, string memory collectionName_, string memory collectionSymbol_)
        internal
    {
        address wrappedCollection = nativeToWrappedCollection(nativeChainId_, nativeAddress_);
        if (wrappedCollection == address(0)) {
            wrappedCollection = deployWrappedCollection(nativeChainId_, nativeAddress_, collectionName_, collectionSymbol_);
        }

        WrappedERC721(wrappedCollection).batchMint(receiver_, tokenIds_, tokenURIs_);
        emit Mint(wrappedCollection, tokenIds_, receiver_);
    }

    /**
     *  @notice Deploys a wrapped version of a native collection to the current chain
     *  @param sourceChain_ Our chain ID for the native chain
     *  @param nativeCollection_ ERC721 contract address on the native chain
     *  @param collectionName_ Name for the wrapped collection
     *  @param collectionSymbol_ Symbol for the wrapped collection
     */
    function deployWrappedCollection(
            uint8 sourceChain_, bytes memory nativeCollection_,
            string memory collectionName_, string memory collectionSymbol_)
        internal
        returns (address)
    {
        address createdContract;
        bytes32 salt = keccak256(abi.encode(sourceChain_, nativeCollection_));
        bytes memory initCode = abi.encodePacked(type(WrappedERC721).creationCode, abi.encode(collectionName_, collectionSymbol_));
        assembly {
            createdContract := create2(0, add(initCode, 0x20), mload(initCode), salt)
        }
        require(createdContract != address(0), "Router: target address occupied");

        LibRouter.setCollectionMappings(sourceChain_, nativeCollection_, createdContract);
        emit WrappedCollectionDeployed(sourceChain_, nativeCollection_, createdContract);

        return createdContract;
    }

    /**
     *  @param chainId_ Our chain ID for the native chain
     *  @param nativeCollection_ ERC721 contract address on the native chain
     *  @return The address of the wrapped counterpart of `nativeToken` in the current chain
     */
    function nativeToWrappedCollection(uint8 chainId_, bytes memory nativeCollection_) public view override returns (address) {
        return LibRouter.routerStorage().nativeToWrappedCollection[chainId_][nativeCollection_];
    }

    /**
     *  @param wrappedCollection_ ERC721 contract address of the wrapped collection
     *  @return The chainId and address of the original token
     */
    function wrappedToNativeCollection(address wrappedCollection_) public view override returns (LibRouter.NativeCollectionWithChainId memory) {
        return LibRouter.routerStorage().wrappedToNativeCollection[wrappedCollection_];
    }

    /**
     *  @return Required fee amount for bridging
     */
    function serviceFee() public view override returns (uint256) {
        return ITeleport(LibRouter.routerStorage().teleportAddress).serviceFee();
    }

    /**
     *  @param addressAsBytes value of type bytes
     *  @return addr addressAsBytes value converted to type address
     */
    function _bytesToAddress(bytes memory addressAsBytes) internal pure returns (address addr) {
        require(addressAsBytes.length == 20, "Router: wrong address length");
        assembly {
            addr := mload(add(addressAsBytes, 20))
        }
    }

    /**
     *  @param addr value of type address
     *  @return addr value converted to type bytes
     */
    function _addressToBytes(address addr) internal pure returns (bytes memory) {
        return abi.encodePacked(addr);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

import "../interfaces/IDiamondCutGovernable.sol";
import "../libraries/LibDiamond.sol";
import "../libraries/LibRouter.sol";
import "../libraries/LibGovernance.sol";
import "../Governable.sol";

contract DiamondCutGovernableFacet is IDiamondCutGovernable, Governable {
    using Counters for Counters.Counter;

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(FacetCut[] calldata _diamondCut, address _init, bytes calldata _calldata, bytes[] calldata _signatures)
        external override
        onlyConsensusNonce(computeDiamondCutMessage(_diamondCut, _init, _calldata), _signatures)
    {
        LibDiamond.diamondCut(_diamondCut, _init, _calldata);
    }

    ///  @notice Computes the bytes32 ethereum signed message hash of the signature
    function computeDiamondCutMessage(FacetCut[] calldata _diamondCut, address _init, bytes calldata _calldata)
        internal view
        returns (bytes32)
    {
        return ECDSA.toEthSignedMessageHash(keccak256(
            abi.encode(
                LibRouter.routerStorage().chainId, "computeDiamondCutMessage",
                _diamondCut, _init, _calldata,
                LibGovernance.governanceStorage().administrativeNonce.current())
            )
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

import { LibDiamond } from  "../libraries/LibDiamond.sol";
import { IDiamondLoupe } from "../interfaces/IDiamondLoupe.sol";

contract DiamondLoupeFacet is IDiamondLoupe {
    // Diamond Loupe Functions
    ////////////////////////////////////////////////////////////////////
    /// These functions are expected to be called frequently by tools.
    //
    // struct Facet {
    //     address facetAddress;
    //     bytes4[] functionSelectors;
    // }
    /// @notice Gets all facets and their selectors.
    /// @return facets_ Facet
    function facets() external override view returns (Facet[] memory facets_) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        facets_ = new Facet[](ds.selectorCount);
        uint8[] memory numFacetSelectors = new uint8[](ds.selectorCount);
        uint256 numFacets;
        uint256 selectorIndex;
        // loop through function selectors
        for (uint256 slotIndex; selectorIndex < ds.selectorCount; slotIndex++) {
            bytes32 slot = ds.selectorSlots[slotIndex];
            for (uint256 selectorSlotIndex; selectorSlotIndex < 8; selectorSlotIndex++) {
                selectorIndex++;
                if (selectorIndex > ds.selectorCount) {
                    break;
                }
                bytes4 selector = bytes4(slot << (selectorSlotIndex << 5));
                address facetAddress_ = address(bytes20(ds.facets[selector]));
                bool continueLoop = false;
                for (uint256 facetIndex; facetIndex < numFacets; facetIndex++) {
                    if (facets_[facetIndex].facetAddress == facetAddress_) {
                        facets_[facetIndex].functionSelectors[numFacetSelectors[facetIndex]] = selector;
                        // probably will never have more than 256 functions from one facet contract
                        require(numFacetSelectors[facetIndex] < 255);
                        numFacetSelectors[facetIndex]++;
                        continueLoop = true;
                        break;
                    }
                }
                if (continueLoop) {
                    continueLoop = false;
                    continue;
                }
                facets_[numFacets].facetAddress = facetAddress_;
                facets_[numFacets].functionSelectors = new bytes4[](ds.selectorCount);
                facets_[numFacets].functionSelectors[0] = selector;
                numFacetSelectors[numFacets] = 1;
                numFacets++;
            }
        }
        for (uint256 facetIndex; facetIndex < numFacets; facetIndex++) {
            uint256 numSelectors = numFacetSelectors[facetIndex];
            bytes4[] memory selectors = facets_[facetIndex].functionSelectors;
            // setting the number of selectors
            assembly {
                mstore(selectors, numSelectors)
            }
        }
        // setting the number of facets
        assembly {
            mstore(facets_, numFacets)
        }
    }

    /// @notice Gets all the function selectors supported by a specific facet.
    /// @param _facet The facet address.
    /// @return _facetFunctionSelectors The selectors associated with a facet address.
    function facetFunctionSelectors(address _facet) external override view returns (bytes4[] memory _facetFunctionSelectors) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        uint256 numSelectors;
        _facetFunctionSelectors = new bytes4[](ds.selectorCount);
        uint256 selectorIndex;
        // loop through function selectors
        for (uint256 slotIndex; selectorIndex < ds.selectorCount; slotIndex++) {
            bytes32 slot = ds.selectorSlots[slotIndex];
            for (uint256 selectorSlotIndex; selectorSlotIndex < 8; selectorSlotIndex++) {
                selectorIndex++;
                if (selectorIndex > ds.selectorCount) {
                    break;
                }
                bytes4 selector = bytes4(slot << (selectorSlotIndex << 5));
                address facet = address(bytes20(ds.facets[selector]));
                if (_facet == facet) {
                    _facetFunctionSelectors[numSelectors] = selector;
                    numSelectors++;
                }
            }
        }
        // Set the number of selectors in the array
        assembly {
            mstore(_facetFunctionSelectors, numSelectors)
        }
    }

    /// @notice Get all the facet addresses used by a diamond.
    /// @return facetAddresses_
    function facetAddresses() external override view returns (address[] memory facetAddresses_) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        facetAddresses_ = new address[](ds.selectorCount);
        uint256 numFacets;
        uint256 selectorIndex;
        // loop through function selectors
        for (uint256 slotIndex; selectorIndex < ds.selectorCount; slotIndex++) {
            bytes32 slot = ds.selectorSlots[slotIndex];
            for (uint256 selectorSlotIndex; selectorSlotIndex < 8; selectorSlotIndex++) {
                selectorIndex++;
                if (selectorIndex > ds.selectorCount) {
                    break;
                }
                bytes4 selector = bytes4(slot << (selectorSlotIndex << 5));
                address facetAddress_ = address(bytes20(ds.facets[selector]));
                bool continueLoop = false;
                for (uint256 facetIndex; facetIndex < numFacets; facetIndex++) {
                    if (facetAddress_ == facetAddresses_[facetIndex]) {
                        continueLoop = true;
                        break;
                    }
                }
                if (continueLoop) {
                    continueLoop = false;
                    continue;
                }
                facetAddresses_[numFacets] = facetAddress_;
                numFacets++;
            }
        }
        // Set the number of facet addresses in the array
        assembly {
            mstore(facetAddresses_, numFacets)
        }
    }

    /// @notice Gets the facet that supports the given selector.
    /// @dev If facet is not found return address(0).
    /// @param _functionSelector The function selector.
    /// @return facetAddress_ The facet address.
    function facetAddress(bytes4 _functionSelector) external override view returns (address facetAddress_) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        facetAddress_ = address(bytes20(ds.facets[_functionSelector]));
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

import "../interfaces/IDiamondCutSimple.sol";
import "../libraries/LibDiamond.sol";

contract DiamondCutSimpleFacet is IDiamondCutSimple {
    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(FacetCut[] calldata _diamondCut, address _init, bytes calldata _calldata)
        external override
    {
        LibDiamond.diamondCut(_diamondCut, _init, _calldata);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

import "./IDiamondCut.sol";

interface IDiamondCutSimple is IDiamondCut {
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