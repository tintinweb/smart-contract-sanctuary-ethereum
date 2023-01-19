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
pragma solidity >=0.8.17 <0.9;

import { BoutState, BoutFighter } from "./Objects.sol";

error NotAllowedError();

error CallerMustBeAdminError();
error CallerMustBeServerError();
error SignerMustBeServerError();
error SignatureExpiredError();

error BoutInWrongStateError(uint boutNum, BoutState state);
error MinimumBetAmountError(uint boutNum, address supporter, uint amount);
error InvalidBetTargetError(uint boutNum, address supporter, uint8 br);
error BoutAlreadyFullyRevealedError(uint boutNum);
error InvalidWinnerError(uint boutNum, BoutFighter winner);

error TokenBalanceInsufficient(uint256 userBalance, uint256 amount);

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17 <0.9;

import { ERC2771Context } from "src/shared/ERC2771Context.sol";
import { LibDiamond } from "lib/diamond-2-hardhat/contracts/libraries/LibDiamond.sol";

import { CallerMustBeAdminError, CallerMustBeServerError } from "./Errors.sol";
import { AppStorage, LibAppStorage } from "./Objects.sol";
import { LibConstants } from "./libs/LibConstants.sol";

abstract contract FacetBase is ERC2771Context {
    modifier isAdmin() {
        if (LibDiamond.contractOwner() != _msgSender()) {
            revert CallerMustBeAdminError();
        }
        _;
    }

    modifier isServer() {
        AppStorage storage s = LibAppStorage.diamondStorage();
        if (s.addresses[LibConstants.SERVER_ADDRESS] != _msgSender()) {
            revert CallerMustBeServerError();
        }
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17 <0.9;

enum BoutState {
    Unknown,
    Created,
    BetsRevealed,
    Ended
}

enum BoutFighter {
    Unknown,
    FighterA,
    FighterB
}

enum MemeBuySizeDollars {
    Five,
    Ten,
    Twenty,
    Fifty,
    Hundred
}

struct Bout {
    uint id;
    uint numSupporters;
    uint numRevealedBets;
    uint totalPot;
    uint revealTime;
    uint endTime;
    BoutState state;
    BoutFighter winner;
    BoutFighter loser;
    mapping(uint => address) supporters;
    mapping(address => uint8) hiddenBets;
    mapping(address => BoutFighter) revealedBets;
    mapping(address => uint) betAmounts;
    mapping(address => bool) winningsClaimed;
    mapping(BoutFighter => uint) fighterIds;
    mapping(BoutFighter => uint) fighterPots;
    mapping(BoutFighter => uint) fighterPotBalances;
}

/**
 * @dev Same as Bout, except with mapping fields removed.
 *
 * This is used to return Bout data from external calls.
 */
struct BoutNonMappingInfo {
    uint id;
    uint numSupporters;
    uint numRevealedBets;
    uint totalPot;
    uint revealTime;
    uint endTime;
    BoutState state;
    BoutFighter winner;
    BoutFighter loser;
}

// from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/cryptography/EIP712.sol
struct EIP712 {
    bytes32 CACHED_DOMAIN_SEPARATOR;
    uint256 CACHED_CHAIN_ID;
    address CACHED_THIS;
    bytes32 HASHED_NAME;
    bytes32 HASHED_VERSION;
    bytes32 TYPE_HASH;
}

struct AppStorage {
    bool diamondInitialized;
    ///
    /// EIP712
    ///

    // eip712 data
    EIP712 eip712;
    ///
    /// Settings
    ///

    mapping(bytes32 => address) addresses;
    mapping(bytes32 => bytes32) bytes32s;
    ///
    /// MEME token
    ///

    // token id => wallet => balance
    mapping(uint => mapping(address => uint)) tokenBalances;
    // token id => supply
    mapping(uint => uint) tokenSupply;
    ///
    /// Fights
    ///

    // no. of bouts created
    uint totalBouts;
    // no. of bouts finished
    uint endedBouts;
    // bout => details
    mapping(uint => Bout) bouts;
    ///
    /// Fight supporters
    ///

    // wallet => no. of bouts supported
    mapping(address => uint) userBoutsSupported;
    // wallet => no. of bouts where winnings claimed
    mapping(address => uint) userBoutsWinningsClaimed;
    // wallet => list of bouts supported
    mapping(address => mapping(uint => uint)) userBoutsSupportedByIndex;
    // tokenId => is this an item being sold by DegenFighter?
    mapping(uint256 => bool) itemForSale;
    // tokenId => cost of item in MEMEs
    mapping(uint256 => uint256) costOfItem;
    ///
    /// ERC2771 meta transactions
    ///
    address trustedForwarder;
}

library LibAppStorage {
    bytes32 internal constant DIAMOND_APP_STORAGE_POSITION = keccak256("diamond.app.storage");

    function diamondStorage() internal pure returns (AppStorage storage ds) {
        bytes32 position = DIAMOND_APP_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17 <0.9;

import { FacetBase } from "../FacetBase.sol";
import { AppStorage, LibAppStorage, Bout, BoutFighter, BoutNonMappingInfo } from "../Objects.sol";
import { IInfoFacet } from "../interfaces/IInfoFacet.sol";

contract InfoFacet is FacetBase, IInfoFacet {
    constructor() FacetBase() {}

    function getTotalBouts() external view returns (uint) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.totalBouts;
    }

    function getEndedBouts() external view returns (uint) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.endedBouts;
    }

    function getUserBoutsWinningsClaimed(address wallet) external view returns (uint) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.userBoutsWinningsClaimed[wallet];
    }

    function getUserBoutsSupported(address wallet) external view returns (uint) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.userBoutsSupported[wallet];
    }

    function getUserSupportedBoutAtIndex(address wallet, uint index) external view returns (uint) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.userBoutsSupportedByIndex[wallet][index];
    }

    function getBoutNonMappingInfo(uint boutNum) external view returns (BoutNonMappingInfo memory) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        Bout storage bout = s.bouts[boutNum];

        return BoutNonMappingInfo(boutNum, bout.numSupporters, bout.numRevealedBets, bout.totalPot, bout.revealTime, bout.endTime, bout.state, bout.winner, bout.loser);
    }

    function getBoutSupporter(uint boutNum, uint supporterNum) external view returns (address) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        Bout storage bout = s.bouts[boutNum];
        return bout.supporters[supporterNum];
    }

    function getBoutHiddenBet(uint boutNum, address supporter) external view returns (uint8) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        Bout storage bout = s.bouts[boutNum];
        return bout.hiddenBets[supporter];
    }

    function getBoutRevealedBet(uint boutNum, address supporter) external view returns (BoutFighter) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        Bout storage bout = s.bouts[boutNum];
        return bout.revealedBets[supporter];
    }

    function getBoutBetAmount(uint boutNum, address supporter) external view returns (uint) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        Bout storage bout = s.bouts[boutNum];
        return bout.betAmounts[supporter];
    }

    function getBoutWinningsClaimed(uint boutNum, address supporter) external view returns (bool) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        Bout storage bout = s.bouts[boutNum];
        return bout.winningsClaimed[supporter];
    }

    function getBoutFighterId(uint boutNum, BoutFighter p) external view returns (uint) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        Bout storage bout = s.bouts[boutNum];
        return bout.fighterIds[p];
    }

    function getBoutFighterPot(uint boutNum, BoutFighter p) external view returns (uint) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        Bout storage bout = s.bouts[boutNum];
        return bout.fighterPots[p];
    }

    function getBoutFighterPotBalance(uint boutNum, BoutFighter p) external view returns (uint) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        Bout storage bout = s.bouts[boutNum];
        return bout.fighterPotBalances[p];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17 <0.9;

import { BoutNonMappingInfo, BoutFighter } from "../Objects.sol";

interface IInfoFacet {
    function getTotalBouts() external view returns (uint);

    function getEndedBouts() external view returns (uint);

    function getUserBoutsWinningsClaimed(address wallet) external view returns (uint);

    function getUserBoutsSupported(address wallet) external view returns (uint);

    function getUserSupportedBoutAtIndex(address wallet, uint index) external view returns (uint);

    function getBoutNonMappingInfo(uint boutNum) external view returns (BoutNonMappingInfo memory);

    function getBoutSupporter(uint boutNum, uint supporterNum) external view returns (address);

    function getBoutHiddenBet(uint boutNum, address supporter) external view returns (uint8);

    function getBoutRevealedBet(uint boutNum, address supporter) external view returns (BoutFighter);

    function getBoutBetAmount(uint boutNum, address supporter) external view returns (uint);

    function getBoutWinningsClaimed(uint boutNum, address supporter) external view returns (bool);

    function getBoutFighterId(uint boutNum, BoutFighter p) external view returns (uint);

    function getBoutFighterPot(uint boutNum, BoutFighter p) external view returns (uint);

    function getBoutFighterPotBalance(uint boutNum, BoutFighter p) external view returns (uint);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17 <0.9;

library LibConstants {
    bytes32 public constant EIP712_DOMAIN_HASH = keccak256("EIP712_DOMAIN_HASH");

    bytes32 public constant MEME_TOKEN_ADDRESS = keccak256("MEME_TOKEN_ADDRESS");
    bytes32 public constant SERVER_ADDRESS = keccak256("SERVER_ADDRESS");
    bytes32 public constant TREASURY_ADDRESS = keccak256("TREASURY_ADDRESS");

    uint public constant MIN_BET_AMOUNT = 10 ether;

    uint public constant TOKEN_MEME = 1;

    address internal constant WMATIC_POLYGON_ADDRESS = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
}

library LibTokenIds {
    uint256 internal constant TOKEN_MEME = 1;
    uint256 internal constant BROADCAST_MSG = 2;
    uint256 internal constant SUPPORTER_INFLUENCE = 3;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (metatx/ERC2771Context.sol)

pragma solidity ^0.8.9;

import "lib/openzeppelin-contracts/contracts/utils/Context.sol";
import { AppStorage, LibAppStorage } from "src/Objects.sol";

/**
 * @dev Context variant with ERC2771 support.
 */
abstract contract ERC2771Context is Context {
    function isTrustedForwarder(address forwarder) internal view virtual returns (bool) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return forwarder == s.trustedForwarder;
    }

    function _msgSender() internal view virtual override returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            /// @solidity memory-safe-assembly
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }

    function _msgData() internal view virtual override returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return super._msgData();
        }
    }
}