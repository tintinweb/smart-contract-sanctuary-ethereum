// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import {CreatorLib} from "../libraries/CreatorLib.sol";

contract CreatorFacet {
    event CreatorInitialized(address wallet, uint256 id, uint256 date);

    /**
     * @notice initiates Creator for a msg.sender
     *
     * @custom:limit ONLY ONE Creator per wallet address
     */
    function initiateCreator() external {
        CreatorLib.initiateCreator();
    }

    /** @notice Rate a Creator
     * @param _creatorAddress – address of a Creator
     *
     * @custom:limit ONLY ONE vote per wallet
     */
    function rateCreator(address _creatorAddress) external {
        CreatorLib.rateCreator(_creatorAddress);
    }

    /**
     * @notice Get Creator's supporters (those who donated/tipped)
     * @param _creatorAddress – Creator's address
     */
  function getSupporters(address _creatorAddress) external view {
    CreatorLib.getSupporters(_creatorAddress);
  }

  function getCreator(address _creatorAddress) external view {
    CreatorLib.getCreator(_creatorAddress);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import {AppLib} from "./AppLib.sol";

library CreatorLib {
    bytes32 internal constant CREATOR = keccak256("cryptokudos.lib.creator");
    bytes32 internal constant CREATORSTATS = keccak256("cryptokudos.lib.creatorstats");

    /**
     @notice the Creator struct is responsible for organizing a creator's info
     @custom wallet – creator's wallet
     @custom id – creator's id
     @custom rating – creator's rating on the platform
     @custom revenue – amount of funds to be withdrawn
     @custom totalAmountCollected – a counter for all the funds collected my a Creator
     @custom donations – donations/tips received by a Creator
     @custom supporters – addresses of those who donated/tipped a Creator
     @custom rated – addresses who rated a Creator
     *
     @notice ONLY ONE Creator per wallet address
     */

    struct Creator {
        address wallet;
        uint256 id;
        uint256 rating;
        uint256 revenue;
        uint256 totalAmountCollected;
        uint256[] donations;
        address[] supporters;
        address[] rated;
    }

    /**
     @notice the CreatorStats struct is responsible for tracking current creator's stats
     @custom  creators – cracks adresses for easy counting;
     @custom existingCreators – helps veryfing whether a creator's address is registered
     @custom creatorsIDs – a counterd for creators' IDs
     @custom totalFundsCollected – a counter for all the funds aggregated by Creators

     */
    struct CreatorsStats {
        mapping(address => Creator) creators;
        mapping(address => bool) existingCreators;
        uint256 creatorsIDs;
        uint256 totalFundsCollected;
    }

    event CreatorInitialized(address wallet, uint256 id, uint256 date);
    event CreatorGotAVote(address voter, address creator, uint256 rating, uint256 date);

    /**
     @notice creates a retrievable storage for the Creator struct
     */
    function getCreatorStorage() internal pure returns (Creator storage c) {
        bytes32 position = CREATOR;
        assembly {
            c.slot := position
        }
    }

    /**
     @notice creates a retrievable storage for the CreatorStats struct
     */
    function getCreatorsStatsStorage() internal pure returns (CreatorsStats storage cs) {
        bytes32 position = CREATORSTATS;
        assembly {
            cs.slot := position
        }
    }

    /**
     @notice initiates Creator for a msg.sender
     @custom:limit only ONE creator per wallet
     */
    function initiateCreator() internal returns (uint256) {
        require(msg.sender != address(0));
        require(!getCreatorsStatsStorage().existingCreators[msg.sender], "Account already exists");
        Creator storage c = getCreatorStorage();
        CreatorsStats storage cs = getCreatorsStatsStorage();
        c = cs.creators[msg.sender];
        cs.existingCreators[msg.sender] = true;
        c.wallet = msg.sender;
        c.rating = 0;
        cs.creatorsIDs++;
        c.id = cs.creatorsIDs;
        emit CreatorInitialized(msg.sender, c.id, block.timestamp);
        return cs.creatorsIDs;
    }

    /**
    @notice Allows retrieving a specific creator's account
    @return Returns a creator's struct with the data
    */
    function getExistingCreator(address _creatorAddress) internal view returns (bool) {
        return getCreatorsStatsStorage().existingCreators[_creatorAddress];
    }

    /**
    @notice Allows rating a specific creator
    @dev using ++creator.rating instead of creator.rating++ to minimize gas 
    @return Creator's rating
    */
    function rateCreator(address _creatorAddress) internal returns (uint256) {
        require(msg.sender != address(0));
        require(msg.sender != _creatorAddress, "Creator: you can't vote for yourself");
        Creator storage c = getCreatorsStatsStorage().creators[_creatorAddress];
        for (uint256 i = 0; i < c.rated.length; i++) {
            require(c.rated[i] != msg.sender, "You have already rated this creator");
        }
        c.rated.push(msg.sender);
        ++c.rating;
        emit CreatorGotAVote(msg.sender, _creatorAddress, c.rating, block.timestamp);

        return c.rating;
    }

    /**
    @notice Gets all the creators registered on the platform
 */
    function getAllCreators() internal view returns (Creator[] memory) {
        CreatorsStats storage cs = getCreatorsStatsStorage();
        Creator[] memory allCreators = new Creator[](cs.creatorsIDs);

        for (uint256 i = 0; i < cs.creatorsIDs; i++) {
            Creator storage c = getCreatorStorage();
            allCreators[i] = c;
        }

        return allCreators;
    }

    function getTotalFundsCollected() internal view returns (uint256) {
        CreatorsStats storage cs = getCreatorsStatsStorage();
        return cs.totalFundsCollected;
    }

    function getCreatorsIDs() internal view returns (uint256) {
        CreatorsStats storage cs = getCreatorsStatsStorage();
        return cs.creatorsIDs;
    }

    /**
     * @dev Get Creator's supporters (those who donated/tipped)
     * @param _creatorAddress – Creator's address
     */
    function getSupporters(address _creatorAddress) internal view returns (address[] memory, uint256[] memory) {
        CreatorsStats storage cs = getCreatorsStatsStorage();
        return (cs.creators[_creatorAddress].supporters, cs.creators[_creatorAddress].donations);
    }

    function getCreator(address _creatorAddress)
        internal
        view
        returns (
            address,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        Creator storage c = getCreatorsStatsStorage().creators[_creatorAddress];
        return (c.wallet, c.id, c.rating, c.revenue, c.totalAmountCollected);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {LibDiamond} from "./LibDiamond.sol";

library AppLib {
    bytes32 internal constant APPSTORAGE = keccak256("cryptokudos.lib.app");

    /**
     * @dev the AppStorage struct is responsible for storing the app's state and general data
     * @param version – version of the app
     * @param paused – a state of the contract
     * @param totalFeesCollected  – a counter for the fees collected by the platforms
     * @param platformFee – a percentage of a fee to be held back
     * @param platformFeeRecipient – fees colector
     * @param owner – owner of the platform
     * @param creators – a registry for Creators' addresses
     * @param existingCreators – a registry to check against if a wallet has already initiated a Creator
     */
    struct AppStorage {
        string version;
        bool paused;
        uint256 totalFeesCollected;
        uint256 platformFee;
        address platformFeeRecipient;
        address owner;
    }

    function getStorage() internal pure returns (AppStorage storage s) {
        bytes32 position = APPSTORAGE;
        assembly {
            s.slot := position
        }
    }

    function getVersion() internal view returns (string memory) {
        return getStorage().version;
    }

    function setVersion(string calldata _version) internal {
        AppStorage storage s = getStorage();
        LibDiamond.enforceIsContractOwner();

        s.version = _version;
    }

    function getPaused() internal view returns (bool) {
        return getStorage().paused;
    }

    function pause() internal returns (bool) {
        LibDiamond.enforceIsContractOwner();
        AppStorage storage s = getStorage();
        s.paused = !s.paused;

        return s.paused;
    }

    function getPlatformFee() internal view returns (uint256) {
        return getStorage().platformFee;
    }

    function setPlatformFee(uint256 _fee) internal returns (uint256) {
        LibDiamond.enforceIsContractOwner();
        AppStorage storage s = getStorage();

        s.platformFee = _fee;

        return s.platformFee;
    }

    function getPlatfromFeeRecipient() internal view returns (address) {
        return getStorage().platformFeeRecipient;
    }

    function setPlatformFeeRecipient(address _platformFeeRecipient) internal returns (address) {
        LibDiamond.enforceIsContractOwner();
        AppStorage storage s = getStorage();

        s.platformFeeRecipient = _platformFeeRecipient;

        return s.platformFeeRecipient;
    }

    function getTotalFeesCollected() internal view returns (uint256) {
        AppStorage storage s = getStorage();
        return s.totalFeesCollected;
    }

    function getOwner() internal view returns (address) {
        AppStorage storage s = getStorage();
        return s.owner;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/
import { IDiamondCut } from "../interfaces/IDiamondCut.sol";

// Remember to add the loupe functions from DiamondLoupeFacet to the diamond.
// The loupe functions are required by the EIP2535 Diamonds standard

error InitializationFunctionReverted(address _initializationContractAddress, bytes _calldata);

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
        // Used to query if a contract implements an interface.
        // Used to implement ERC-165.
        mapping(bytes4 => bool) supportedInterfaces;
        // owner of the contract
        address contractOwner;
    }

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

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
        require(msg.sender == diamondStorage().contractOwner, "LibDiamond: Must be contract owner");
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
        for (uint256 facetIndex; facetIndex < _diamondCut.length; ) {
            (selectorCount, selectorSlot) = addReplaceRemoveFacetSelectors(
                selectorCount,
                selectorSlot,
                _diamondCut[facetIndex].facetAddress,
                _diamondCut[facetIndex].action,
                _diamondCut[facetIndex].functionSelectors
            );

            unchecked {
                facetIndex++;
            }
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
            for (uint256 selectorIndex; selectorIndex < _selectors.length; ) {
                bytes4 selector = _selectors[selectorIndex];
                bytes32 oldFacet = ds.facets[selector];
                require(address(bytes20(oldFacet)) == address(0), "LibDiamondCut: Can't add function that already exists");
                // add facet for selector
                ds.facets[selector] = bytes20(_newFacetAddress) | bytes32(_selectorCount);
                // "_selectorCount & 7" is a gas efficient modulo by eight "_selectorCount % 8" 
                // " << 5 is the same as multiplying by 32 ( * 32)
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

                unchecked {
                    selectorIndex++;
                }
            }
        } else if (_action == IDiamondCut.FacetCutAction.Replace) {
            enforceHasContractCode(_newFacetAddress, "LibDiamondCut: Replace facet has no code");
            for (uint256 selectorIndex; selectorIndex < _selectors.length; ) {
                bytes4 selector = _selectors[selectorIndex];
                bytes32 oldFacet = ds.facets[selector];
                address oldFacetAddress = address(bytes20(oldFacet));
                // only useful if immutable functions exist
                require(oldFacetAddress != address(this), "LibDiamondCut: Can't replace immutable function");
                require(oldFacetAddress != _newFacetAddress, "LibDiamondCut: Can't replace function with same function");
                require(oldFacetAddress != address(0), "LibDiamondCut: Can't replace function that doesn't exist");
                // replace old facet address
                ds.facets[selector] = (oldFacet & CLEAR_ADDRESS_MASK) | bytes20(_newFacetAddress);

                unchecked {
                    selectorIndex++;
                }
            }
        } else if (_action == IDiamondCut.FacetCutAction.Remove) {
            require(_newFacetAddress == address(0), "LibDiamondCut: Remove facet address must be address(0)");
            // "_selectorCount >> 3" is a gas efficient division by 8 "_selectorCount / 8"
            uint256 selectorSlotCount = _selectorCount >> 3;
            // "_selectorCount & 7" is a gas efficient modulo by eight "_selectorCount % 8" 
            uint256 selectorInSlotIndex = _selectorCount & 7;
            for (uint256 selectorIndex; selectorIndex < _selectors.length; ) {
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
                    // " << 5 is the same as multiplying by 32 ( * 32)
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
                    // " << 5 is the same as multiplying by 32 ( * 32)
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

                unchecked {
                    selectorIndex++;
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
            return;
        }
        enforceHasContractCode(_init, "LibDiamondCut: _init address has no code");        
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

    function enforceHasContractCode(address _contract, string memory _errorMessage) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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