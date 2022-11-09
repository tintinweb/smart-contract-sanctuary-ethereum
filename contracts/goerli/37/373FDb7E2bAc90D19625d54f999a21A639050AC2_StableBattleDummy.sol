// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import { DiamondCutFacetDummy } from "../DiamondCut/DiamondCutFacetDummy.sol";
import { DiamondLoupeFacetDummy } from "../DiamondLoupe/DiamondLoupeFacetDummy.sol";
import { OwnershipFacetDummy } from "../Ownership/OwnershipFacetDummy.sol";
import { ItemsFacetDummy } from "../Items/ItemsFacetDummy.sol";
import { ClanFacetDummy } from "../Clan/ClanFacetDummy.sol";
import { KnightFacetDummy } from "../Knight/KnightFacetDummy.sol";
import { SBVHookFacetDummy } from "../SBVHook/SBVHookFacetDummy.sol";
import { TournamentFacetDummy } from "../Tournament/TournamentFacetDummy.sol";
import { TreasuryFacetDummy } from "../Treasury/TreasuryFacetDummy.sol";
import { GearFacetDummy } from "../Gear/GearFacetDummy.sol";
import { EtherscanFacetDummy } from "../Etherscan/EtherscanFacetDummy.sol";
import { DemoFightFacetDummy } from "../DemoFight/DemoFightFacetDummy.sol";
import { AdminFacetDummy } from "../Admin/AdminFacetDummy.sol";

/*
  This is a dummy implementation of StableBattle contracts.
  This contract is needed due to Etherscan proxy recognition difficulties.
  This implementation will be updated alongside StableBattle Diamond updates.
  
  To get addresses of the real implementation code either use Louper.dev or look into scripts/config/(network)
*/

contract StableBattleDummy is 
  DiamondCutFacetDummy,
  DiamondLoupeFacetDummy,
  OwnershipFacetDummy,
  ItemsFacetDummy,
  ClanFacetDummy,
  KnightFacetDummy,
  SBVHookFacetDummy,
  TournamentFacetDummy,
  TreasuryFacetDummy,
  GearFacetDummy,
  EtherscanFacetDummy,
  DemoFightFacetDummy,
  AdminFacetDummy
{
  function supportsInterface(bytes4 interfaceId)
    external
    view
    override(DiamondLoupeFacetDummy, ItemsFacetDummy)
    returns (bool)
  {}
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import { IDiamondCut } from "./IDiamondCut.sol";

contract DiamondCutFacetDummy is IDiamondCut {
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external override {}
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import { IItems } from "../Items/IItems.sol";

contract ItemsFacetDummy is IItems {

//ERC165 openzeppelin thing
  function supportsInterface(bytes4 interfaceId) external virtual view returns (bool) {}

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

import { IDiamondLoupe } from "./IDiamondLoupe.sol";
import { IERC165 } from "@openzeppelin/contracts/interfaces/IERC165.sol";

contract DiamondLoupeFacetDummy is IDiamondLoupe, IERC165 {
    function facets() external override view returns (Facet[] memory facets_) {}

    function facetFunctionSelectors(address _facet) external override view returns (bytes4[] memory _facetFunctionSelectors) {}

    function facetAddresses() external override view returns (address[] memory facetAddresses_) {}

    function facetAddress(bytes4 _functionSelector) external override view returns (address facetAddress_) {}
    
    function supportsInterface(bytes4 _interfaceId) external virtual override view returns (bool) {}
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import { Coin, Pool, Knight } from "../../Meta/DataStructures.sol";
import { IKnight } from "./IKnight.sol";

contract KnightFacetDummy is IKnight {

//Knight Facet
  function mintKnight(Pool p, Coin c) external {}

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

import { ISBVHook } from "./ISBVHook.sol";

contract SBVHookFacetDummy is ISBVHook {
  function SBV_hook(uint id, address newOwner, bool mint) external {}
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import { Proposal } from "../../Meta/DataStructures.sol";
import { IClan } from "./IClan.sol";

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IERC173 } from "./IERC173.sol";

contract OwnershipFacetDummy is IERC173 {
    function transferOwnership(address _newOwner) external override {}

    function owner() external override view returns (address owner_) {}
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import { ITreasury } from "./ITreasury.sol";

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

contract EtherscanFacetDummy {
  function setDummyImplementation(address newImplementation) external {}

  function getDummyImplementation() external view returns (address) {}

  event DummyUpgraded(address newImplementation);
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import { gearSlot } from "../../Meta/DataStructures.sol";
import { IGear } from "./IGear.sol";

contract GearFacetDummy is IGear {

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
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import { ITournament } from "./ITournament.sol";

contract TournamentFacetDummy is ITournament {
  function updateCastleOwnership(uint clanId) external {}

  function getCastleHolderClan() external view returns(uint){}
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import { Pool, Coin } from "../../Meta/DataStructures.sol";

contract AdminFacetDummy {
  function setBaseURI(string memory baseURI) external {}

  function setTokenURI(uint256 tokenId, string memory tokenURI) external {}

  function debugEnablePoolCoinMinting(Pool pool, Coin coin) external {}

  function debugDisablePoolCoinMinting(Pool pool, Coin coin) external {}
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import { IDemoFight } from "./IDemoFight.sol";

contract DemoFightFacetDummy is IDemoFight {

  function battleWonBy(address user, uint256 reward) public {}

  function claimReward(address user) public {}

//External getters

  function getTotalYield() external view returns(uint256) {}

  function getCurrentYield() external view returns(uint256) {}

  function getLockedYield() external view returns(uint256) {}

  function getStakedByKnights() external view returns(uint256) {}

  function getUserReward(address user) external view returns(uint256) {}

  function getYieldInfo()
    external
    view
    returns(uint256, uint256, uint256, uint256)
  {}
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

import { ISolidStateERC1155 } from "@solidstate/contracts/token/ERC1155/ISolidStateERC1155.sol";
import { IItemsErrors } from "../Items/IItemsErrors.sol";

interface IItems is ISolidStateERC1155, IItemsErrors {}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IItemsErrors {
  error ItemsFacet_DontOwnThisItem(uint256 itemId);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC1155Base } from './base/IERC1155Base.sol';
import { IERC1155Enumerable } from './enumerable/IERC1155Enumerable.sol';
import { IERC1155Metadata } from './metadata/IERC1155Metadata.sol';

interface ISolidStateERC1155 is
    IERC1155Base,
    IERC1155Enumerable,
    IERC1155Metadata
{}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC1155 } from '../IERC1155.sol';

/**
 * @title ERC1155 base interface
 */
interface IERC1155Base is IERC1155 {

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC1155Internal } from '../IERC1155Internal.sol';

/**
 * @title ERC1155 enumerable and aggregate function interface
 */
interface IERC1155Enumerable is IERC1155Internal {
    /**
     * @notice query total minted supply of given token
     * @param id token id to query
     * @return token supply
     */
    function totalSupply(uint256 id) external view returns (uint256);

    /**
     * @notice query total number of holders for given token
     * @param id token id to query
     * @return quantity of holders
     */
    function totalHolders(uint256 id) external view returns (uint256);

    /**
     * @notice query holders of given token
     * @param id token id to query
     * @return list of holder addresses
     */
    function accountsByToken(uint256 id)
        external
        view
        returns (address[] memory);

    /**
     * @notice query tokens held by given address
     * @param account address to query
     * @return list of token ids
     */
    function tokensByAccount(address account)
        external
        view
        returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC1155MetadataInternal } from './IERC1155MetadataInternal.sol';

/**
 * @title ERC1155Metadata interface
 */
interface IERC1155Metadata is IERC1155MetadataInternal {
    /**
     * @notice get generated URI for given token
     * @return token URI
     */
    function uri(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC1155Internal } from './IERC1155Internal.sol';
import { IERC165 } from '../../introspection/IERC165.sol';

/**
 * @title ERC1155 interface
 * @dev see https://github.com/ethereum/EIPs/issues/1155
 */
interface IERC1155 is IERC1155Internal, IERC165 {
    /**
     * @notice query the balance of given token held by given address
     * @param account address to query
     * @param id token to query
     * @return token balance
     */
    function balanceOf(address account, uint256 id)
        external
        view
        returns (uint256);

    /**
     * @notice query the balances of given tokens held by given addresses
     * @param accounts addresss to query
     * @param ids tokens to query
     * @return token balances
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @notice query approval status of given operator with respect to given address
     * @param account address to query for approval granted
     * @param operator address to query for approval received
     * @return whether operator is approved to spend tokens held by account
     */
    function isApprovedForAll(address account, address operator)
        external
        view
        returns (bool);

    /**
     * @notice grant approval to or revoke approval from given operator to spend held tokens
     * @param operator address whose approval status to update
     * @param status whether operator should be considered approved
     */
    function setApprovalForAll(address operator, bool status) external;

    /**
     * @notice transfer tokens between given addresses, checking for ERC1155Receiver implementation if applicable
     * @param from sender of tokens
     * @param to receiver of tokens
     * @param id token ID
     * @param amount quantity of tokens to transfer
     * @param data data payload
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @notice transfer batch of tokens between given addresses, checking for ERC1155Receiver implementation if applicable
     * @param from sender of tokens
     * @param to receiver of tokens
     * @param ids list of token IDs
     * @param amounts list of quantities of tokens to transfer
     * @param data data payload
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC165 } from '../../introspection/IERC165.sol';

/**
 * @title Partial ERC1155 interface needed by internal functions
 */
interface IERC1155Internal {
    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 value
    );

    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    event ApprovalForAll(
        address indexed account,
        address indexed operator,
        bool approved
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title ERC165 interface registration interface
 * @dev see https://eips.ethereum.org/EIPS/eip-165
 */
interface IERC165 {
    /**
     * @notice query whether contract has registered support for given interface
     * @param interfaceId interface id
     * @return bool whether interface is supported
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title Partial ERC1155Metadata interface needed by internal functions
 */
interface IERC1155MetadataInternal {
    event URI(string value, uint256 indexed tokenId);
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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

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

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.0;

enum Pool { NONE, TEST, AAVE }

enum Coin { NONE, TEST, USDT, USDC, EURS }

struct Knight {
  Pool pool;
  Coin coin;
  address owner;
  uint256 inClan;
}

enum gearSlot { NONE, WEAPON, SHIELD, HELMET, ARMOR, PANTS, SLEEVES, GLOVES, BOOTS, JEWELRY, CLOAK }

enum Proposal { NONE, JOIN, LEAVE, INVITE }

struct Clan {
  uint256 leader;
  uint256 stake;
  uint totalMembers;
  uint level;
}

enum Role {
  NONE,
  ADMIN
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import { Coin, Pool, Knight } from "../../Meta/DataStructures.sol";
import { IKnightEvents } from "../Knight/IKnightEvents.sol";
import { IKnightErrors } from "../Knight/IKnightErrors.sol";
import { Knight } from "../Knight/KnightStorage.sol";

interface IKnight is IKnightEvents, IKnightErrors {

//Knight Facet
  function mintKnight(Pool p, Coin c) external;

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

import { Coin, Pool } from "../../Meta/DataStructures.sol";

interface IKnightEvents {
  event KnightMinted (uint knightId, address wallet, Pool c, Coin p);
  event KnightBurned (uint knightId, address wallet, Pool c, Coin p);
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

interface IKnightErrors {
  error KnightFacet_InsufficientFunds(uint256 avalible, uint256 required);
  error KnightModifiers_WrongKnightId(uint256 wrongId);
  error KnightModifiers_KnightNotInAnyClan(uint256 knightId);
  error KnightModifiers_KnightNotInClan(uint256 knightId, uint256 wrongClanId, uint256 correctClanId);
  error KnightModifiers_KnightInSomeClan(uint256 knightId, uint256 clanId);
}

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.0;

import { Pool, Coin, Knight } from "../../Meta/DataStructures.sol";

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

interface ISBVHook {
  function SBV_hook(uint id, address newOwner, bool mint) external;

  event VillageInfoUpdated(uint id, address newOwner, uint villageAmount);
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import { Proposal } from "../../Meta/DataStructures.sol";
import { IClanEvents } from "../Clan/IClanEvents.sol";
import { IClanErrors } from "../Clan/IClanErrors.sol";

interface IClan is IClanEvents, IClanErrors {
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

interface IClanErrors {
  error ClanModifiers_ClanDoesntExist(uint256 clanId);
  error ClanModifiers_KnightIsNotClanLeader(uint256 knightId, uint256 clanId);
  error ClanModifiers_KnightIsClanLeader(uint256 knightId, uint256 clanId);

  error ClanFacet_InsufficientStake(uint256 stakeAvalible, uint256 withdrawAmount);
  error ClanFacet_CantJoinAlreadyInClan(uint256 knightId, uint256 clanId);
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

interface IClanEvents {
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

import { ITreasuryEvents } from "../Treasury/ITreasuryEvents.sol";
import { ITreasuryErrors } from "../Treasury/ITreasuryErrors.sol";

interface ITreasury is ITreasuryEvents, ITreasuryErrors {

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

interface ITreasuryEvents {
  event BeneficiaryUpdated(uint village, address beneficiary);
  event NewTaxSet(uint tax);
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

interface ITreasuryErrors {
  error TreasuryModifiers_OnlyCallableByCastleHolder();
  error TreasuryFacet_CantSetTaxAboveThreshold(uint8 threshold);
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import { gearSlot } from "../../Meta/DataStructures.sol";
import { IGearEvents } from "../Gear/IGearEvents.sol";
import { IGearErrors } from "../Gear/IGearErrors.sol";

interface IGear is IGearEvents, IGearErrors {

//Gear Facet
  function createGear(uint id, gearSlot slot, string memory name) external;

  function updateKnightGear(uint256 knightId, uint256[] memory items) external;

  function mintGear(uint id, uint amount, address to) external;

  function mintGear(uint id, uint amount) external;

  function burnGear(uint id, uint amount, address from) external;

  function burnGear(uint id, uint amount) external;

//Gear Getters
  function getGearSlotOf(uint256 itemId) external view returns(gearSlot);

  function getGearName(uint256 itemId) external view returns(string memory);

  function getEquipmentInSlot(uint256 knightId, gearSlot slot) external view returns(uint256);

  function getGearEquipable(address account, uint256 itemId) external view returns(uint256);

  function getGearEquipable(uint256 itemId) external view returns(uint256);
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

interface IGearErrors {
  error GearModifiers_WrongGearId(uint256 gearId);
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import { gearSlot } from "../../Meta/DataStructures.sol";

interface IGearEvents {
  event GearCreated(uint256 id, gearSlot slot, string name);
  event GearMinted(uint256 id, uint256 amount, address to);
  event GearBurned(uint256 id, uint256 amount, address from);
  event GearEquipped(uint256 knightId, gearSlot slot, uint256 itemId);
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import { ITournamentEvents } from "../Tournament/ITournamentEvents.sol";
import { ITournamentErrors } from "../Tournament/ITournamentErrors.sol";

interface ITournament is ITournamentEvents, ITournamentErrors {
  function updateCastleOwnership(uint clanId) external;

  function getCastleHolderClan() external view returns(uint);
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

interface ITournamentEvents {
  event CastleHolderChanged(uint clanId);
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

interface ITournamentErrors {}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import { IDemoFightEvents } from "./IDemoFightEvents.sol";
import { IDemoFightErrors } from "./IDemoFightErrors.sol";

interface IDemoFight is IDemoFightEvents, IDemoFightErrors {

  function battleWonBy(address user, uint256 reward) external;

  function claimReward(address user) external;

//External getters

  function getTotalYield() external view returns(uint256);

  function getCurrentYield() external view returns(uint256);

  function getLockedYield() external view returns(uint256);

  function getStakedByKnights() external view returns(uint256);

  function getUserReward(address user) external view returns(uint256);

  function getYieldInfo()
    external
    view
    returns(uint256, uint256, uint256, uint256);
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

interface IDemoFightErrors {
  error DemoFightFacet_RewardBiggerThanYield(uint256 reward, uint256 currentYield);
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

interface IDemoFightEvents {
  event NewWinner(address user, uint256 reward);
  event RewardClaimed(address user, uint256 reward);
}