// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {LibVersion} from "../libraries/LibVersion.sol";
import {LibAppStorage, AppStorage} from "../libraries/LibAppStorage.sol";
import {LibDiamond} from "../libraries/LibDiamond.sol";
import {IDiamondLoupe} from "../interfaces/IDiamondLoupe.sol";
import {IDiamondCut} from "../interfaces/IDiamondCut.sol";

/**
 * @title VersionFacet
 * @author PartyFinance
 * @notice Facet that handles the unsupervised upgrades of Party's facets
 */
contract VersionFacet {
    event VersionDiamondCut(
        IDiamondCut.FacetCut[] _diamondCut,
        address updater
    );

    /**
     * @notice Retrieves the platform required state from the PartyFactory
     */
    function getRequiredState()
        internal
        view
        returns (address feeCollector, uint256 fee, address sentinel)
    {
        address factory = LibAppStorage.diamondStorage().platformFactory;
        (bool success, bytes memory data) = factory.staticcall(
            abi.encodeWithSignature("getPlatformInfo()")
        );
        require(success, "Failed retrieving facets from Factory");
        (feeCollector, fee, sentinel) = abi.decode(
            data,
            (address, uint256, address)
        );
    }

    /**
     * @notice Checks if the Party has the platform required state up-to-date
     * @dev Verifies the Party platform variables against the PartyFactory
     * @return areEqual Whether if the Party's Platform state is up-to-date
     */
    function checkEnsureState() external view returns (bool areEqual) {
        (
            address feeCollector,
            uint256 fee,
            address sentinel
        ) = getRequiredState();
        AppStorage storage s = LibAppStorage.diamondStorage();
        areEqual =
            feeCollector == s.platformFeeCollector &&
            fee == s.platformFee &&
            sentinel == s.platformSentinel;
    }

    /**
     * @notice Ensures that the Party platform variables are the same as the PartyFactory
     * @dev This will change the Platform Fee collector, Platform Fee and Platform Sentinel on the Party if needed
     */
    function ensureState() external {
        (
            address feeCollector,
            uint256 fee,
            address sentinel
        ) = getRequiredState();
        AppStorage storage s = LibAppStorage.diamondStorage();
        require(
            feeCollector != s.platformFeeCollector ||
                fee != s.platformFee ||
                sentinel != s.platformSentinel,
            "Platform state on Party is already updated"
        );
        s.platformFeeCollector = feeCollector;
        s.platformFee = fee;
        s.platformSentinel = sentinel;
    }

    /**
     * @notice Retrieves the required cut established in the PartyFactory
     * @dev It excludes the DiamondCutFacet, since its handled after so that its always
     *      included as a required facet.
     */
    function getRequiredCut()
        internal
        view
        returns (IDiamondCut.FacetCut[] memory requiredCut)
    {
        address factory = LibAppStorage.diamondStorage().platformFactory;
        (bool success, bytes memory data) = factory.staticcall(
            abi.encodeWithSignature("getPartyDefaultFacetCut()")
        );
        require(success, "Failed retrieving facets from Factory");
        requiredCut = abi.decode(data, (IDiamondCut.FacetCut[]));
    }

    /**
     * @notice Checks if the Party need an upgrade (diamondCut)
     * @return areEqual If Party's facets are equal with required by the PartyFactory
     * @return currentFacets Current Party's facets
     * @return modelDiamondCut Required DiamondCut by the PartyFactory
     */
    function checkEnsureVersion()
        external
        view
        returns (
            bool areEqual,
            IDiamondLoupe.Facet[] memory currentFacets,
            IDiamondCut.FacetCut[] memory modelDiamondCut
        )
    {
        // Get current facets
        currentFacets = IDiamondLoupe(address(this)).facets();

        // Get required facets
        modelDiamondCut = getRequiredCut();

        // Diamond comparison
        areEqual = LibVersion.diamondEquals(currentFacets, modelDiamondCut);
    }

    /**
     * @notice Clones the functions from a Diamond model and overwrites the current Diamond functions
     * @dev Calling this function will guarantee that the function selectors are the same as the Diamond implementation
     */
    function ensureDiamond() external {
        // 1) Clear current function selectors
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        IDiamondCut.FacetCut[] memory removeCut = new IDiamondCut.FacetCut[](1);
        bytes4[] memory selectors = new bytes4[](ds.selectorCount);
        uint256 selectorIndex;
        for (uint256 slotIndex; selectorIndex < ds.selectorCount; slotIndex++) {
            bytes32 slot = ds.selectorSlots[slotIndex];
            for (
                uint256 selectorSlotIndex;
                selectorSlotIndex < 8;
                selectorSlotIndex++
            ) {
                selectorIndex++;
                if (selectorIndex > ds.selectorCount) {
                    break;
                }
                bytes4 selector = bytes4(slot << (selectorSlotIndex << 5));
                selectors[selectorIndex - 1] = selector;
            }
        }
        removeCut[0].action = IDiamondCut.FacetCutAction.Remove;
        removeCut[0].functionSelectors = selectors;
        LibDiamond.diamondCut(removeCut, address(0), "");

        // 2) Get the desired cut from the Diamond Model;
        IDiamondCut.FacetCut[] memory _modelCut = getRequiredCut();

        // 3) Overwrite the current function selectors with the Diamond Implementation
        LibDiamond.diamondCut(_modelCut, address(0), "");
        emit VersionDiamondCut(_modelCut, tx.origin);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IDiamondLoupe} from "../interfaces/IDiamondLoupe.sol";
import {IDiamondCut} from "../interfaces/IDiamondCut.sol";

library LibVersion {
    /**
     * @notice Retrieves the function selector's facet address from a list of Facet structs
     * @param _selector function selector to look up
     * @param _facets Array of Facet structs that could contain the function selector
     */
    function getSelectorFacetAddress(
        bytes4 _selector,
        IDiamondLoupe.Facet[] memory _facets
    ) internal pure returns (address) {
        for (uint256 i = 0; i < _facets.length; i++) {
            for (uint256 j = 0; j < _facets[i].functionSelectors.length; j++) {
                if (_facets[i].functionSelectors[j] == _selector) {
                    return _facets[i].facetAddress;
                }
            }
        }
        return address(0);
    }

    /**
     * @notice Retrieves the function selector's facet address from a list of FacetCut structs
     * @param _selector function selector to look up
     * @param _facets Array of FacetCut structs that could contain the function selector
     */
    function getSelectorFacetCutAddress(
        bytes4 _selector,
        IDiamondCut.FacetCut[] memory _facets
    ) internal pure returns (address) {
        for (uint256 i = 0; i < _facets.length; i++) {
            for (uint256 j = 0; j < _facets[i].functionSelectors.length; j++) {
                if (_facets[i].functionSelectors[j] == _selector) {
                    return _facets[i].facetAddress;
                }
            }
        }
        return address(0);
    }

    /**
     * @notice Compares two EIP-2535 Diamonds and checks if have same facets
     * @param _currentFacets Current Diamond facets (array of Facut structs retrieved from the `facets()` function in the `DiamondLouperFacet`)
     * @param _modelDiamondCut Model Diamond facets (as array of FacetCut structs)
     */
    function diamondEquals(
        IDiamondLoupe.Facet[] memory _currentFacets,
        IDiamondCut.FacetCut[] memory _modelDiamondCut
    ) internal pure returns (bool) {
        // 1) Check Current Diamond against the Model Diamond
        for (uint256 i = 0; i < _currentFacets.length; i++) {
            for (
                uint256 j = 0;
                j < _currentFacets[i].functionSelectors.length;
                j++
            ) {
                // Check if the selector exists in the Model Diamond
                bytes4 selector = _currentFacets[i].functionSelectors[j];
                address foundAddress = getSelectorFacetCutAddress(
                    selector,
                    _modelDiamondCut
                );
                if (foundAddress == _currentFacets[i].facetAddress) continue;
                // selector was removed or its facet address was changed -> Not equal
                return false;
            }
        }

        // 2) Check Model Diamond against the Current Diamond
        for (uint256 i = 0; i < _modelDiamondCut.length; i++) {
            for (
                uint256 j = 0;
                j < _modelDiamondCut[i].functionSelectors.length;
                j++
            ) {
                // Check if the selector exists in the Current Diamond
                bytes4 selector = _modelDiamondCut[i].functionSelectors[j];
                address foundAddress = getSelectorFacetAddress(
                    selector,
                    _currentFacets
                );
                if (foundAddress == _modelDiamondCut[i].facetAddress) continue;
                // selector was removed or its facet address was changed -> Not equal
                return false;
            }
        }

        // 3) If we went here it's because diamonds are equal
        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/
import {IDiamondCut} from "../interfaces/IDiamondCut.sol";

library LibDiamond {
    bytes32 constant DIAMOND_STORAGE_POSITION =
        keccak256("diamond.standard.diamond.storage");

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
        // Used to query if a contract implements an interface.
        // Used to implement ERC-165.
        mapping(bytes4 => bool) supportedInterfaces;
        // owner of the contract
        address contractOwner;
    }

    function diamondStorage()
        internal
        pure
        returns (DiamondStorage storage ds)
    {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    function setContractOwner(address _newOwner) internal {
        DiamondStorage storage ds = diamondStorage();
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
            "LibDiamond: Must be contract owner"
        );
    }

    event DiamondCut(
        IDiamondCut.FacetCut[] _diamondCut,
        address _init,
        bytes _calldata
    );

    bytes32 constant CLEAR_ADDRESS_MASK =
        bytes32(uint256(0xffffffffffffffffffffffff));
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
        for (
            uint256 facetIndex;
            facetIndex < _diamondCut.length;
            facetIndex++
        ) {
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
        require(
            _selectors.length > 0,
            "LibDiamondCut: No selectors in facet to cut"
        );
        if (_action == IDiamondCut.FacetCutAction.Add) {
            enforceHasContractCode(
                _newFacetAddress,
                "LibDiamondCut: Add facet has no code"
            );
            for (
                uint256 selectorIndex;
                selectorIndex < _selectors.length;
                selectorIndex++
            ) {
                bytes4 selector = _selectors[selectorIndex];
                bytes32 oldFacet = ds.facets[selector];
                require(
                    address(bytes20(oldFacet)) == address(0),
                    "LibDiamondCut: Can't add function that already exists"
                );
                // add facet for selector
                ds.facets[selector] =
                    bytes20(_newFacetAddress) |
                    bytes32(_selectorCount);
                // "_selectorCount & 7" is a gas efficient modulo by eight "_selectorCount % 8"
                // " << 5 is the same as multiplying by 32 ( * 32)
                uint256 selectorInSlotPosition = (_selectorCount & 7) << 5;
                // clear selector position in slot and add selector
                _selectorSlot =
                    (_selectorSlot &
                        ~(CLEAR_SELECTOR_MASK >> selectorInSlotPosition)) |
                    (bytes32(selector) >> selectorInSlotPosition);
                // if slot is full then write it to storage
                if (selectorInSlotPosition == 224) {
                    // "_selectorSlot >> 3" is a gas efficient division by 8 "_selectorSlot / 8"
                    ds.selectorSlots[_selectorCount >> 3] = _selectorSlot;
                    _selectorSlot = 0;
                }
                _selectorCount++;
            }
        } else if (_action == IDiamondCut.FacetCutAction.Replace) {
            enforceHasContractCode(
                _newFacetAddress,
                "LibDiamondCut: Replace facet has no code"
            );
            for (
                uint256 selectorIndex;
                selectorIndex < _selectors.length;
                selectorIndex++
            ) {
                bytes4 selector = _selectors[selectorIndex];
                bytes32 oldFacet = ds.facets[selector];
                address oldFacetAddress = address(bytes20(oldFacet));
                // only useful if immutable functions exist
                require(
                    oldFacetAddress != address(this),
                    "LibDiamondCut: Can't replace immutable function"
                );
                require(
                    oldFacetAddress != _newFacetAddress,
                    "LibDiamondCut: Can't replace function with same function"
                );
                require(
                    oldFacetAddress != address(0),
                    "LibDiamondCut: Can't replace function that doesn't exist"
                );
                // replace old facet address
                ds.facets[selector] =
                    (oldFacet & CLEAR_ADDRESS_MASK) |
                    bytes20(_newFacetAddress);
            }
        } else if (_action == IDiamondCut.FacetCutAction.Remove) {
            require(
                _newFacetAddress == address(0),
                "LibDiamondCut: Remove facet address must be address(0)"
            );
            // "_selectorCount >> 3" is a gas efficient division by 8 "_selectorCount / 8"
            uint256 selectorSlotCount = _selectorCount >> 3;
            // "_selectorCount & 7" is a gas efficient modulo by eight "_selectorCount % 8"
            uint256 selectorInSlotIndex = _selectorCount & 7;
            for (
                uint256 selectorIndex;
                selectorIndex < _selectors.length;
                selectorIndex++
            ) {
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
                    require(
                        address(bytes20(oldFacet)) != address(0),
                        "LibDiamondCut: Can't remove function that doesn't exist"
                    );
                    // only useful if immutable functions exist
                    require(
                        address(bytes20(oldFacet)) != address(this),
                        "LibDiamondCut: Can't remove immutable function"
                    );
                    // replace selector with last selector in ds.facets
                    // gets the last selector
                    // " << 5 is the same as multiplying by 32 ( * 32)
                    lastSelector = bytes4(
                        _selectorSlot << (selectorInSlotIndex << 5)
                    );
                    if (lastSelector != selector) {
                        // update last selector slot position info
                        ds.facets[lastSelector] =
                            (oldFacet & CLEAR_ADDRESS_MASK) |
                            bytes20(ds.facets[lastSelector]);
                    }
                    delete ds.facets[selector];
                    uint256 oldSelectorCount = uint16(uint256(oldFacet));
                    // "oldSelectorCount >> 3" is a gas efficient division by 8 "oldSelectorCount / 8"
                    oldSelectorsSlotCount = oldSelectorCount >> 3;
                    // "oldSelectorCount & 7" is a gas efficient modulo by eight "oldSelectorCount % 8"
                    // " << 5 is the same as multiplying by 32 ( * 32)
                    oldSelectorInSlotPosition = (oldSelectorCount & 7) << 5;
                }
                if (oldSelectorsSlotCount != selectorSlotCount) {
                    bytes32 oldSelectorSlot = ds.selectorSlots[
                        oldSelectorsSlotCount
                    ];
                    // clears the selector we are deleting and puts the last selector in its place.
                    oldSelectorSlot =
                        (oldSelectorSlot &
                            ~(CLEAR_SELECTOR_MASK >>
                                oldSelectorInSlotPosition)) |
                        (bytes32(lastSelector) >> oldSelectorInSlotPosition);
                    // update storage with the modified slot
                    ds.selectorSlots[oldSelectorsSlotCount] = oldSelectorSlot;
                } else {
                    // clears the selector we are deleting and puts the last selector in its place.
                    _selectorSlot =
                        (_selectorSlot &
                            ~(CLEAR_SELECTOR_MASK >>
                                oldSelectorInSlotPosition)) |
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

    function initializeDiamondCut(address _init, bytes memory _calldata)
        internal
    {
        if (_init == address(0)) {
            require(
                _calldata.length == 0,
                "LibDiamondCut: _init is address(0) but_calldata is not empty"
            );
        } else {
            require(
                _calldata.length > 0,
                "LibDiamondCut: _calldata is empty but _init is not address(0)"
            );
            if (_init != address(this)) {
                enforceHasContractCode(
                    _init,
                    "LibDiamondCut: _init address has no code"
                );
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

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
pragma solidity ^0.8.17;

import {LibMeta} from "./LibMeta.sol";

/**
 * @notice A struct containing the Party info tracked in storage.
 * @param name Name of the Party
 * @param bio Description of the Party
 * @param img Image URL of the Party (path to storage without protocol/domain)
 * @param model Model of the Party: "Democracy", "Monarchy", "WeightedDemocracy", "Republic"
 * @param purpose Purpose of the Party: "Trading", "YieldFarming", "LiquidityProviding", "NFT"
 * @param isPublic Visibility of the Party. (Private parties requires an accepted join request)
 * @param minDeposit Minimum deposit allowed in denomination asset
 * @param maxDeposit Maximum deposit allowed in denomination asset
 */
struct PartyInfo {
    string name;
    string bio;
    string img;
    string model;
    string purpose;
    bool isPublic;
    uint256 minDeposit;
    uint256 maxDeposit;
}

/**
 * @notice A struct containing the Announcement info tracked in storage.
 * @param title Title of the Announcement
 * @param bio Content of the Announcement
 * @param img Any external URL to include in the Announcement
 * @param model Model of the Party: "Democracy", "Monarchy", "WeightedDemocracy", "Republic"
 * @param created Block timestamp date of the Announcement creation
 * @param updated Block timestamp date of any Announcement edition
 */
struct Announcement {
    string title;
    string content;
    string url;
    string img;
    uint256 created;
    uint256 updated;
}

struct AppStorage {
    //
    // Party vault token
    //
    string name;
    string symbol;
    uint256 totalSupply;
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowances;
    //
    // Denomination token asset for deposit/withdraws
    //
    address denominationAsset;
    //
    // Party info
    //
    PartyInfo partyInfo;
    bool closed; // Party life status
    //
    // Party access
    //
    mapping(address => bool) managers; // Maping to get if address is a manager
    mapping(address => bool) members; // Maping to get if address is a member
    //
    // Party ERC-20 holdings
    //
    address[] tokens; // Array of current party tokens holdings
    //
    // Party Announcements
    //
    Announcement[] announcements;
    //
    // Party Join Requests
    //
    address[] joinRequests; // Array of users that requested to join the party
    mapping(address => bool) acceptedRequests; // Mapping of requests accepted by a manager
    //
    // PLATFORM
    //
    uint256 platformFee; // Platform fee (in bps, 50 bps -> 0.5%)
    address platformFeeCollector; // Platform fee collector
    address platformSentinel; // Platform sentinel
    address platformFactory; // Platform factory
    //
    // Extended Party access
    //
    address creator; // Creator of the Party
}

library LibAppStorage {
    function diamondStorage() internal pure returns (AppStorage storage ds) {
        assembly {
            ds.slot := 0
        }
    }
}

contract Modifiers {
    AppStorage internal s;

    modifier onlyCreator() {
        require(s.creator == LibMeta.msgSender(), "Only Party Creator allowed");
        _;
    }

    modifier onlyManager() {
        require(s.managers[LibMeta.msgSender()], "Only Party Managers allowed");
        _;
    }

    modifier onlyMember() {
        require(s.members[LibMeta.msgSender()], "Only Party Members allowed");
        _;
    }

    modifier notMember() {
        require(
            !s.members[LibMeta.msgSender()],
            "Only non Party Members allowed"
        );
        _;
    }

    modifier onlyFactory() {
        require(
            LibMeta.msgSender() == s.platformFactory,
            "Only Factory allowed"
        );
        _;
    }

    modifier isAlive() {
        require(!s.closed, "Party is closed");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

interface IDiamondCut {
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

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library LibMeta {
    function getChainID() internal view returns (uint256 id) {
        assembly {
            id := chainid()
        }
    }

    function msgSender() internal view returns (address sender_) {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender_ := and(
                    mload(add(array, index)),
                    0xffffffffffffffffffffffffffffffffffffffff
                )
            }
        } else {
            sender_ = msg.sender;
        }
    }
}