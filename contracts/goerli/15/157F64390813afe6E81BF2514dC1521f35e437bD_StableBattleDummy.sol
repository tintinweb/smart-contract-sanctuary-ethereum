// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import { DiamondCutFacetDummy } from "../dummies/DiamondCutFacetDummy.sol";
import { DiamondLoupeFacetDummy } from "../dummies/DiamondLoupeFacetDummy.sol";
import { OwnershipFacetDummy } from "../dummies/OwnershipFacetDummy.sol";
import { ItemsFacetDummy } from "../dummies/ItemsFacetDummy.sol";
import { ClanFacetDummy } from "../dummies/ClanFacetDummy.sol";
import { KnightFacetDummy } from "../dummies/KnightFacetDummy.sol";
import { SBVHookFacetDummy } from "../dummies/SBVHookFacetDummy.sol";
import { TournamentFacetDummy } from "../dummies/TournamentFacetDummy.sol";
import { TreasuryFacetDummy } from "../dummies/TreasuryFacetDummy.sol";
import { GearFacetDummy } from "../dummies/GearFacetDummy.sol";
import { EtherscanFacetDummy } from "../dummies/EtherscanFacetDummy.sol";

/*
  This is a dummy implementation of StableBattle contracts.
  This contract is needed due to Etherscan proxy recognition difficulties.
  This implementation will be updated alongside StableBattle Diamond updates
*/

contract StableBattleDummy is DiamondCutFacetDummy,
                              DiamondLoupeFacetDummy,
                              OwnershipFacetDummy,
                              ItemsFacetDummy,
                              ClanFacetDummy,
                              KnightFacetDummy,
                              SBVHookFacetDummy,
                              TournamentFacetDummy,
                              TreasuryFacetDummy,
                              GearFacetDummy,
                              EtherscanFacetDummy {}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import { IDiamondCut } from "../../../shared/interfaces/IDiamondCut.sol";

contract DiamondCutFacetDummy is IDiamondCut {
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external override {}
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import { LibDiamond } from  "../../../shared/libraries/LibDiamond.sol";
import { IDiamondLoupe } from "../../../shared/interfaces/IDiamondLoupe.sol";
import { IERC165 } from "../../../shared/interfaces/IERC165.sol";

contract DiamondLoupeFacetDummy is IDiamondLoupe, IERC165 {
    function facets() external override view returns (Facet[] memory facets_) {}

    function facetFunctionSelectors(address _facet) external override view returns (bytes4[] memory _facetFunctionSelectors) {}

    function facetAddresses() external override view returns (address[] memory facetAddresses_) {}

    function facetAddress(bytes4 _functionSelector) external override view returns (address facetAddress_) {}
    
    function supportsInterface(bytes4 _interfaceId) external override view returns (bool) {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IERC173 } from "../../../shared/interfaces/IERC173.sol";

contract OwnershipFacetDummy is IERC173 {
    function transferOwnership(address _newOwner) external override {}

    function owner() external override view returns (address owner_) {}
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

contract ItemsFacetDummy {

//ERC1155
  function balanceOf(address account, uint256 id)
    external
    view
    returns (uint256) {}
      
  function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
    external
    view
    returns (uint256[] memory) {}
      
  function isApprovedForAll(address account, address operator)
    external
    view
    returns (bool) {}
      
  function setApprovalForAll(address operator, bool status) external {}
  
  function safeTransferFrom(
    address from,
    address to,
    uint256 id,
    uint256 amount,
    bytes calldata data
  ) external {}
  
  function safeBatchTransferFrom(
    address from,
    address to,
    uint256[] calldata ids,
    uint256[] calldata amounts,
    bytes calldata data
  ) external {}

//ERC1155Enumerable
  function totalSupply(uint256 id) external view returns (uint256) {}
  
  function totalHolders(uint256 id) external view returns (uint256) {}
  
  function accountsByToken(uint256 id)
      external
      view
      returns (address[] memory) {}
      
  function tokensByAccount(address account)
      external
      view
      returns (uint256[] memory) {}

//ERC1155Metadata
  function uri(uint256 tokenId) external view returns (string memory) {}
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import { IClan, Proposal } from "../../Clan/IClan.sol";

contract ClanFacetDummy is IClan {

  function create(uint256 knightId) external returns(uint clanId) {}

  function abandon(uint256 clanId) external {}

  function changeLeader(uint256 clanId, uint256 knightId) external {}

// Clan stakes and leveling
  function onStake(address benefactor, uint256 clanId, uint256 amount) external {}

  function onWithdraw(address benefactor, uint256 clanId, uint256 amount) external {}

//Join, Leave and Invite Proposals
  function join(uint256 knightId, uint256 clanId) external {}

  function leave(uint256 knightId) external {}

  function invite(uint256 knightId, uint256 clanId) external {}

//Public getters

  function getClanLeader(uint clanId) external view returns(uint256) {}

  function getClanTotalMembers(uint clanId) external view returns(uint) {}
  
  function getClanStake(uint clanId) external view returns(uint256) {}

  function getClanLevel(uint clanId) external view returns(uint) {}

  function getStakeOf(address benefactor, uint clanId) external view returns(uint256) {}

  function getClanLevelThreshold(uint level) external view returns (uint) {}

  function getClanMaxLevel() external view returns (uint) {}

  function getProposal(uint256 knightId, uint256 clanId) external view returns (Proposal) {}
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import { Knight } from "../../Knight/KnightStorage.sol";
import { Coin, Pool } from "../../Meta/MetaStorage.sol";
import { IKnight } from "../../Knight/IKnight.sol";

contract KnightFacetDummy is IKnight {

//Knight Facet
  function mintKnight(Pool p, Coin c, string memory uri) external {}

  function burnKnight (uint256 knightId) external {}

//Knight Getters
  function getKnightInfo(uint256 knightId) external view returns(Knight memory) {}

  function getKnightPool(uint256 knightId) external view returns(Pool) {}

  function getKnightCoin(uint256 knightId) external view returns(Coin) {}

  function getKnightOwner(uint256 knightId) external view returns(address) {}

  function getKnightClan(uint256 knightId) external view returns(uint256) {}

  function getKnightPrice(Coin coin) external view returns (uint256) {}

  //returns amount of minted knights for a particular coin & pool
  function getKnightsMinted(Pool pool, Coin coin) external view returns (uint256) {}

  //returns amount of minted knights for any coin in a particular pool
  function getKnightsMintedOfPool(Pool pool) external view returns (uint256 knightsMintedTotal) {}

  //returns amount of minted knights for any pool in a particular coin
  function getKnightsMintedOfCoin(Coin coin) external view returns (uint256) {}

  //returns a total amount of minted knights
  function getKnightsMintedTotal() external view returns (uint256) {}

  //returns amount of burned knights for a particular coin & pool
  function getKnightsBurned(Pool pool, Coin coin) external view returns (uint256) {}

  //returns amount of burned knights for any coin in a particular pool
  function getKnightsBurnedOfPool(Pool pool) external view returns (uint256 knightsBurnedTotal) {}

  //returns amount of burned knights for any pool in a particular coin
  function getKnightsBurnedOfCoin(Coin coin) external view returns (uint256) {}

  //returns a total amount of burned knights
  function getKnightsBurnedTotal() external view returns (uint256) {}

  function getTotalKnightSupply() external view returns (uint256) {}

  function getPoolAndCoinCompatibility(Pool p, Coin c) external view returns (bool) {}
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import { ISBVHook } from "../../SBVHook/ISBVHook.sol";

contract SBVHookFacetDummy is ISBVHook {

  function SBV_hook(uint id, address newOwner, bool mint) external {}
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import { ITournament } from "../../Tournament/ITournament.sol";

contract TournamentFacetDummy is ITournament {

  function updateCastleOwnership(uint clanId) external {}

  function getCastleHolderClan() external view returns(uint){}

}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import { ITreasury } from "../../Treasury/ITreasury.sol";

contract TreasuryFacetDummy is ITreasury {

//Treasury Facet

  function claimRewards() external{}

  function setTax(uint8 tax) external{}

//Public Getters

  function getCastleTax() external view returns(uint){}
  
  function getLastBlock() external view returns(uint){}

  function getRewardPerBlock() external view returns(uint){}
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import { gearSlot } from "../../Gear/GearStorage.sol";

contract GearFacetDummy {

//Gear Facet
  function createGear(uint id, gearSlot slot, string memory name) external {}

  function updateKnightGear(uint256 knightId, uint256[] memory items) external {}

  function mintGear(uint id, uint amount, address to) external {}

  function mintGear(uint id, uint amount) external {}

  function burnGear(uint id, uint amount, address from) external {}

  function burnGear(uint id, uint amount) external {}

//Gear Getters
  function getGearSlotOf(uint256 itemId) external view returns(gearSlot) {}

  function getGearName(uint256 itemId) external view returns(string memory) {}

  function getEquipmentInSlot(uint256 knightId, gearSlot slot) external view returns(uint256) {}

  function getGearEquipable(address account, uint256 itemId) external view returns(uint256) {}

  function getGearEquipable(uint256 itemId) external view returns(uint256) {}

  event GearCreated(uint256 id, gearSlot slot, string name);
  event GearEquipped(uint256 knightId, gearSlot slot, uint256 itemId);
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

contract EtherscanFacetDummy {

  function setDummyImplementation(address newImplementation) external {}

  function getDummyImplementation() external view returns (address) {}

  event DummyUpgraded(address newImplementation);
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/
import { IDiamondCut } from "../interfaces/IDiamondCut.sol";

// Remember to add the loupe functions from DiamondLoupeFacet to the diamond.
// The loupe functions are required by the EIP2535 Diamonds standard

library LibDiamond {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

    struct FacetAddressAndSelectorPosition {
        address facetAddress;
        uint16 selectorPosition;
    }

    struct DiamondStorage {
        // function selector => facet address and selector position in selectors array
        mapping(bytes4 => FacetAddressAndSelectorPosition) facetAddressAndSelectorPosition;
        bytes4[] selectors;
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

    // Internal function version of diamondCut
    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        for (uint256 facetIndex; facetIndex < _diamondCut.length; facetIndex++) {
            IDiamondCut.FacetCutAction action = _diamondCut[facetIndex].action;
            if (action == IDiamondCut.FacetCutAction.Add) {
                addFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else if (action == IDiamondCut.FacetCutAction.Replace) {
                replaceFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else if (action == IDiamondCut.FacetCutAction.Remove) {
                removeFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else {
                revert("LibDiamondCut: Incorrect FacetCutAction");
            }
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        uint16 selectorCount = uint16(ds.selectors.length);
        require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
        enforceHasContractCode(_facetAddress, "LibDiamondCut: Add facet has no code");
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.facetAddressAndSelectorPosition[selector].facetAddress;
            require(oldFacetAddress == address(0), "LibDiamondCut: Can't add function that already exists");
            ds.facetAddressAndSelectorPosition[selector] = FacetAddressAndSelectorPosition(_facetAddress, selectorCount);
            ds.selectors.push(selector);
            selectorCount++;
        }
    }

    function replaceFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        require(_facetAddress != address(0), "LibDiamondCut: Replace facet can't be address(0)");
        enforceHasContractCode(_facetAddress, "LibDiamondCut: Replace facet has no code");
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.facetAddressAndSelectorPosition[selector].facetAddress;
            // can't replace immutable functions -- functions defined directly in the diamond
            require(oldFacetAddress != address(this), "LibDiamondCut: Can't replace immutable function");
            require(oldFacetAddress != _facetAddress, "LibDiamondCut: Can't replace function with same function");
            require(oldFacetAddress != address(0), "LibDiamondCut: Can't replace function that doesn't exist");
            // replace old facet address
            ds.facetAddressAndSelectorPosition[selector].facetAddress = _facetAddress;
        }
    }

    function removeFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        uint256 selectorCount = ds.selectors.length;
        require(_facetAddress == address(0), "LibDiamondCut: Remove facet address must be address(0)");
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            FacetAddressAndSelectorPosition memory oldFacetAddressAndSelectorPosition = ds.facetAddressAndSelectorPosition[selector];
            require(oldFacetAddressAndSelectorPosition.facetAddress != address(0), "LibDiamondCut: Can't remove function that doesn't exist");
            // can't remove immutable functions -- functions defined directly in the diamond
            require(oldFacetAddressAndSelectorPosition.facetAddress != address(this), "LibDiamondCut: Can't remove immutable function.");
            // replace selector with last selector
            selectorCount--;
            if (oldFacetAddressAndSelectorPosition.selectorPosition != selectorCount) {
                bytes4 lastSelector = ds.selectors[selectorCount];
                ds.selectors[oldFacetAddressAndSelectorPosition.selectorPosition] = lastSelector;
                ds.facetAddressAndSelectorPosition[lastSelector].selectorPosition = oldFacetAddressAndSelectorPosition.selectorPosition;
            }
            // delete last selector
            ds.selectors.pop();
            delete ds.facetAddressAndSelectorPosition[selector];
        }
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title ERC-173 Contract Ownership Standard
///  Note: the ERC-165 identifier for this interface is 0x7f5828d0
/* is ERC165 */
interface IERC173 {
    /// @dev This emits when ownership of a contract changes.
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @notice Get the address of the owner
    /// @return owner_ The address of the owner.
    function owner() external view returns (address owner_);

    /// @notice Set the address of the new owner of the contract
    /// @dev Set _newOwner to address(0) to renounce any ownership.
    /// @param _newOwner The address of the new owner of the contract
    function transferOwnership(address _newOwner) external;
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import { Proposal } from "../Clan/ClanStorage.sol";
import { IClanInternal } from "../Clan/IClanInternal.sol";

interface IClan is IClanInternal{
  function create(uint256 knightId) external returns(uint clanId);

  function abandon(uint256 clanId) external;

  function changeLeader(uint256 clanId, uint256 knightId) external;

// Clan stakes and leveling
  function onStake(address benefactor, uint256 clanId, uint256 amount) external;

  function onWithdraw(address benefactor, uint256 clanId, uint256 amount) external;

//Join, Leave and Invite Proposals
  function join(uint256 knightId, uint256 clanId) external;

  function leave(uint256 knightId) external;

  function invite(uint256 knightId, uint256 clanId) external;

//Public getters

  function getClanLeader(uint clanId) external view returns(uint256);

  function getClanTotalMembers(uint clanId) external view returns(uint);
  
  function getClanStake(uint clanId) external view returns(uint256);

  function getClanLevel(uint clanId) external view returns(uint);

  function getStakeOf(address benefactor, uint clanId) external view returns(uint256);

  function getClanLevelThreshold(uint level) external view returns (uint);

  function getClanMaxLevel() external view returns (uint);

  function getProposal(uint256 knightId, uint256 clanId) external view returns (Proposal);
}

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.0;

enum Proposal {
  NONE,
  JOIN,
  LEAVE,
  INVITE
}

struct Clan {
  uint256 leader;
  uint256 stake;
  uint totalMembers;
  uint level;
}

library ClanStorage {
  struct State {
    uint MAX_CLAN_MEMBERS;
    uint[] levelThresholds;
    // clanId => Clan
    mapping(uint256 => Clan) clan;
    // knightId => clanId => proposalType
    mapping (uint256 => mapping(uint256 => Proposal)) proposal;
    // address => clanId => amount
    mapping (address => mapping (uint => uint256)) stake;
    
    uint256 clansInTotal;
  }

  bytes32 internal constant STORAGE_SLOT = keccak256("Clan.storage");

  function state() internal pure returns (State storage l) {
    bytes32 slot = STORAGE_SLOT;
    assembly {
      l.slot := slot
    }
  }
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

interface IClanInternal {
  event ClanCreated(uint clanId, uint256 knightId);
  event ClanAbandoned(uint clanId, uint256 knightId);
  event ClanLeaderChanged(uint clanId, uint256 knightId);

  event StakeAdded(address benefactor, uint clanId, uint amount);
  event StakeWithdrawn(address benefactor, uint clanId, uint amount);
  event ClanLeveledUp(uint clanId, uint newLevel);
  event ClanLeveledDown(uint clanId, uint newLevel);

  event KnightAskedToJoin(uint clanId, uint256 knightId);
  event KnightJoinedClan(uint clanId, uint256 knightId);
  event KnightAskedToLeave(uint clanId, uint256 knightId);
  event KnightLeftClan(uint clanId, uint256 knightId);
  event KnightInvitedToClan(uint clanId, uint256 knightId);
}

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.0;

import { Pool, Coin } from "../Meta/MetaStorage.sol";

struct Knight {
  Pool pool;
  Coin coin;
  address owner;
  uint256 inClan;
}

library KnightStorage {
  struct State {
    mapping(uint256 => Knight) knight;
    mapping(Coin => uint256) knightPrice;
    mapping(Pool => mapping(Coin => uint256)) knightsMinted;
    mapping(Pool => mapping(Coin => uint256)) knightsBurned;
  }

  bytes32 internal constant STORAGE_SLOT = keccak256("Knight.storage");

  function state() internal pure returns (State storage l) {
    bytes32 slot = STORAGE_SLOT;
    assembly {
      l.slot := slot
    }
  }
}

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.0;

enum Pool {
  NONE,
  AAVE,
  TEST
}

enum Coin {
  NONE,
  USDT,
  USDC,
  TEST
}

library MetaStorage {
  struct State {
    // StableBattle EIP20 Token address
    address SBT;
    // StableBattle EIP721 Village address
    address SBV;

    mapping (Pool => address) pool;
    mapping (Coin => address) coin;
    mapping (Pool => mapping (Coin => bool)) compatible;
  }

  bytes32 internal constant STORAGE_SLOT = keccak256("Meta.storage");

  function state() internal pure returns (State storage l) {
    bytes32 slot = STORAGE_SLOT;
    assembly {
      l.slot := slot
    }
  }
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import { IKnightInternal } from "../Knight/IKnightInternal.sol";
import { Knight } from "../Knight/KnightStorage.sol";
import { Coin, Pool } from "../Meta/MetaStorage.sol";

interface IKnight is IKnightInternal {

//Knight Facet
  function mintKnight(Pool p, Coin c, string memory uri) external;

  function burnKnight (uint256 knightId) external;

//Knight Getters
  function getKnightInfo(uint256 knightId) external view returns(Knight memory);

  function getKnightPool(uint256 knightId) external view returns(Pool);

  function getKnightCoin(uint256 knightId) external view returns(Coin);

  function getKnightOwner(uint256 knightId) external view returns(address);

  function getKnightClan(uint256 knightId) external view returns(uint256);

  function getKnightPrice(Coin coin) external view returns (uint256);

  //returns amount of minted knights for a particular coin & pool
  function getKnightsMinted(Pool pool, Coin coin) external view returns (uint256);

  //returns amount of minted knights for any coin in a particular pool
  function getKnightsMintedOfPool(Pool pool) external view returns (uint256 knightsMintedTotal);

  //returns amount of minted knights for any pool in a particular coin
  function getKnightsMintedOfCoin(Coin coin) external view returns (uint256);

  //returns a total amount of minted knights
  function getKnightsMintedTotal() external view returns (uint256);

  //returns amount of burned knights for a particular coin & pool
  function getKnightsBurned(Pool pool, Coin coin) external view returns (uint256);

  //returns amount of burned knights for any coin in a particular pool
  function getKnightsBurnedOfPool(Pool pool) external view returns (uint256 knightsBurnedTotal);

  //returns amount of burned knights for any pool in a particular coin
  function getKnightsBurnedOfCoin(Coin coin) external view returns (uint256);

  //returns a total amount of burned knights
  function getKnightsBurnedTotal() external view returns (uint256);

  function getTotalKnightSupply() external view returns (uint256);

  function getPoolAndCoinCompatibility(Pool p, Coin c) external view returns (bool);
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import { Coin, Pool } from "../Meta/MetaStorage.sol";

interface IKnightInternal {
  event KnightMinted (uint knightId, address wallet, Pool c, Coin p);
  event KnightBurned (uint knightId, address wallet, Pool c, Coin p);
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

interface ISBVHook {
  
  function SBV_hook(uint id, address newOwner, bool mint) external;

  event VillageInfoUpdated(uint id, address newOwner, uint villageAmount);
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import { ITournamentInternal } from "../Tournament/ITournamentInternal.sol";

interface ITournament is ITournamentInternal{

  function updateCastleOwnership(uint clanId) external;

  function getCastleHolderClan() external view returns(uint);
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

interface ITournamentInternal {
  event CastleHolderChanged(uint clanId);
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import { ITreasuryInternal } from "../Treasury/ITreasuryInternal.sol";

interface ITreasury is ITreasuryInternal {

//Treasury Facet

  function claimRewards() external;

  function setTax(uint8 tax) external;

//Public Getters

  function getCastleTax() external view returns(uint);
  
  function getLastBlock() external view returns(uint);

  function getRewardPerBlock() external view returns(uint);
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

interface ITreasuryInternal {
  event BeneficiaryUpdated (uint village, address beneficiary);
  event NewTaxSet(uint tax);
}

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.0;

enum gearSlot {
  NONE,
  WEAPON,
  SHIELD,
  HELMET,
  ARMOR,
  PANTS,
  SLEEVES,
  GLOVES,
  BOOTS,
  JEWELRY,
  CLOAK
}

library GearStorage {
  struct State {
    uint256 gearRangeLeft;
    uint256 gearRangeRight;
    //knightId => gearSlot => itemId
    //Returns an itemId of item equipped in gearSlot for Knight with knightId
    mapping(uint256 => mapping(gearSlot => uint256)) knightSlotItem;
    //itemId => slot
    //Returns gear slot for particular item per itemId
    mapping(uint256 => gearSlot) gearSlot;
    //itemId => itemName
    //Returns a name of particular item per itemId
    mapping(uint256 => string) gearName;
    //knightId => itemId => amount 
    //Returns amount of nonequippable (either already equipped or lended or in pending sell order)
      //items per itemId for a particular wallet
    mapping(address => mapping(uint256 => uint256)) notEquippable;
  }

  bytes32 internal constant STORAGE_SLOT = keccak256("Gear.storage");

  function state() internal pure returns (State storage l) {
    bytes32 slot = STORAGE_SLOT;
    assembly {
      l.slot := slot
    }
  }
}