// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.0;

import { IClan } from "../Clan/IClan.sol";
import { ClanStorage, Clan, Proposal } from "../Clan/ClanStorage.sol";
import { ClanInternal } from "../Clan/ClanInternal.sol";
import { ItemsModifiers } from "../Items/ItemsModifiers.sol";
import { MetaModifiers } from "../Meta/MetaModifiers.sol";

contract ClanFacet is
  IClan,
  ItemsModifiers,
  ClanInternal,
  MetaModifiers
{

//Creation, Abandonment and Leader Change
  function create(uint256 knightId)
    external
  //ifOwnsItem(knightId)
    returns(uint)
  { return _create(knightId); }

  function abandon(uint256 clanId) 
    external 
  //ifOwnsItem(clanLeader(clanId))
  { _abandon(clanId); }

  function changeLeader(uint256 clanId, uint256 knightId)
    external
  //ifOwnsItem(clanLeader(clanId))
  { _changeLeader(clanId, knightId); }

// Clan stakes and leveling
  function onStake(address benefactor, uint256 clanId, uint256 amount)
    external
  //onlySBT
  { _onStake(benefactor, clanId, amount); }

  function onWithdraw(address benefactor, uint256 clanId, uint256 amount)
    external
  //onlySBT
  { _onWithdraw(benefactor, clanId, amount); }

//Join, Leave and Invite Proposals
  //ONLY knight supposed call the join function
  function join(uint256 knightId, uint256 clanId)
    external
  //ifOwnsItem(knightId)
  { _join(knightId, clanId); }

  //BOTH knights and leaders supposed call the leave function
  function leave(uint256 knightId)
    external
  { _leave(knightId); }

  //ONLY leaders supposed call the invite function
  function invite(uint256 knightId, uint256 clanId)
    external
  //ifOwnsItem(clanLeader(clanId))
  { _invite(knightId, clanId); }

//Public getters

  function getClanLeader(uint clanId) external view returns(uint256) {
    return _clanLeader(clanId);
  }

  function getClanTotalMembers(uint clanId) external view returns(uint) {
    return _clanTotalMembers(clanId);
  }
  
  function getClanStake(uint clanId) external view returns(uint256) {
    return _clanStake(clanId);
  }

  function getClanLevel(uint clanId) external view returns(uint) {
    return _clanLevel(clanId);
  }

  function getStakeOf(address benefactor, uint clanId) external view returns(uint256) {
    return _stakeOf(benefactor, clanId);
  }

  function getClanLevelThreshold(uint level) external view returns (uint) {
    return _clanLevelThreshold(level);
  }

  function getClanMaxLevel() external view returns (uint) {
    return _clanMaxLevel();
  }

  function getProposal(uint256 knightId, uint256 clanId) external view returns (Proposal) {
    return _proposal(knightId, clanId);
  }
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

import { IClanInternal } from "../Clan/IClanInternal.sol";
import { Clan, Proposal, ClanStorage } from "../Clan/ClanStorage.sol";
import { KnightStorage } from "../Knight/KnightStorage.sol";
import { KnightModifiers } from "../Knight/KnightModifiers.sol";
import { ClanGetters } from "../Clan/ClanGetters.sol";
import { ClanModifiers } from "../Clan/ClanModifiers.sol";
import { ItemsModifiers } from "../Items/ItemsModifiers.sol";

abstract contract ClanInternal is 
  IClanInternal, 
  ClanGetters, 
  KnightModifiers, 
  ClanModifiers,
  ItemsModifiers 
{
  using ClanStorage for ClanStorage.State;
  using KnightStorage for KnightStorage.State;

//Creation, Abandonment and Leader Change
  function _create(uint256 knightId)
    internal
    ifIsKnight(knightId)
    ifNotInClan(knightId)
    returns(uint clanId)
  {
    clanId = _clansInTotal() + 1;
    ClanStorage.state().clan[clanId] = Clan(knightId, 0, 1, 0);
    KnightStorage.state().knight[knightId].inClan = clanId;
    ClanStorage.state().clansInTotal++;
    emit ClanCreated(clanId, knightId);
  }

  function _abandon(uint256 clanId) 
    internal
  {
    uint256 leaderId = _clanLeader(clanId);
    KnightStorage.state().knight[leaderId].inClan = 0;
    ClanStorage.state().clan[clanId].leader = 0;
    emit ClanAbandoned(clanId, leaderId);
  }

  function _changeLeader(uint256 clanId, uint256 knightId)
    internal
    ifIsKnight(knightId)
    ifIsInClan(knightId, clanId)
    ifIsNotClanLeader(knightId, clanId)
  {
    ClanStorage.state().clan[clanId].leader = knightId;
  }

// Clan stakes and leveling
  function _onStake(address benefactor, uint256 clanId, uint256 amount)
    internal
    ifClanExists(clanId)
  {
    ClanStorage.state().stake[benefactor][clanId] += amount;
    ClanStorage.state().clan[clanId].stake += amount;
    _leveling(clanId);

    emit StakeAdded(benefactor, clanId, amount);
  }

  function _onWithdraw(address benefactor, uint256 clanId, uint256 amount)
    internal
    ifClanExists(clanId)
  {
    require(_stakeOf(benefactor, clanId) >= amount, "ClanFacet: Not enough SBT staked");
    
    ClanStorage.state().stake[benefactor][clanId] -= amount;
    ClanStorage.state().clan[clanId].stake -= amount;
    _leveling(clanId);

    emit StakeWithdrawn(benefactor, clanId, amount);
  }

  //Calculate clan level based on stake
  function _leveling(uint256 clanId) private {
    uint newLevel = 0;
    while (_clanStake(clanId) > _clanLevelThreshold(newLevel) &&
           newLevel < _clanMaxLevel()) {
      newLevel++;
    }
    if (_clanLevel(clanId) < newLevel) {
      ClanStorage.state().clan[clanId].level = newLevel;
      emit ClanLeveledUp (clanId, newLevel);
    } else if (_clanLevel(clanId) > newLevel) {
      ClanStorage.state().clan[clanId].level = newLevel;
      emit ClanLeveledDown (clanId, newLevel);
    }
  }

//Join, Leave and Invite Proposals
  //ONLY knight supposed call the join function
  function _join(uint256 knightId, uint256 clanId)
    internal
    ifIsKnight(knightId)
    ifClanExists(clanId)
  {
    require(!clanExists(_knightClan(knightId)) || notInClan(knightId),
      "ClanFacet: Leave your clan before joining a new one");
    if (_proposal(knightId, clanId) == Proposal.INVITE) {
      //join clan immediately if invited
      ClanStorage.state().clan[clanId].totalMembers++;
      KnightStorage.state().knight[knightId].inClan = clanId;
      ClanStorage.state().proposal[knightId][clanId] = Proposal.NONE;
      emit KnightJoinedClan(clanId, knightId);
    } else {
      //create join proposal
      ClanStorage.state().proposal[knightId][clanId] = Proposal.JOIN;
      emit KnightAskedToJoin(clanId, knightId);
    }
  }

  //BOTH knights and leaders supposed call the leave function
  function _leave(uint256 knightId)
    internal
    ifIsKnight(knightId)
    ifIsInAnyClan(knightId)
  { 
    uint256 clanId = _knightClan(knightId);
    if ((clanExists(clanId) && _proposal(knightId, clanId) != Proposal.LEAVE)) {
      //create leave proposal if clan exist & such proposal doesn't
      ClanStorage.state().proposal[knightId][clanId] = Proposal.LEAVE;
      emit KnightAskedToLeave(clanId, knightId);
    } else if(ownsItem(_clanLeader(clanId)) || !clanExists(clanId)) {
      //leave abandoned clan or allow knight to leave if clan leader
      _kick(knightId);
    } else {
      revert("ClanFacet: Either proposal already exist or you don't own a clan leader");
    }
  }

  function _kick(uint256 knightId)
    internal
    ifIsKnight(knightId)
    ifIsInAnyClan(knightId)
  {
    uint256 clanId = _knightClan(knightId);
    ClanStorage.state().clan[clanId].totalMembers--;
    KnightStorage.state().knight[knightId].inClan = 0;
    ClanStorage.state().proposal[knightId][clanId] = Proposal.NONE;
    emit KnightLeftClan(clanId, knightId);
  }

  //ONLY leaders supposed call the invite function
  function _invite(uint256 knightId, uint256 clanId)
    internal
    ifIsKnight(knightId)
    ifNotInClan(knightId)
  {
    if (_proposal(knightId, clanId) == Proposal.JOIN && notInClan(knightId)) {
      //welcome the knight to join if it already offered it
      ClanStorage.state().clan[clanId].totalMembers++;
      KnightStorage.state().knight[knightId].inClan = clanId;
      ClanStorage.state().proposal[knightId][clanId] = Proposal.NONE;
      emit KnightJoinedClan(clanId, knightId);
    } else {
      //create invite proposal for the knight
      ClanStorage.state().proposal[knightId][clanId] = Proposal.INVITE;
      emit KnightInvitedToClan(clanId, knightId);
    }
  }
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import { ERC1155BaseInternal } from "@solidstate/contracts/token/ERC1155/base/ERC1155BaseInternal.sol";

abstract contract ItemsModifiers is ERC1155BaseInternal {
  function ownsItem(uint256 itemId) internal view returns(bool) {
    return _balanceOf(msg.sender, itemId) > 0;
  }
  
  modifier ifOwnsItem(uint256 itemId) {
    require(ownsItem(itemId),
    "ItemModifiers: You don't own this item");
    _;
  }
}

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.0;

import { Pool, Coin, MetaStorage } from "./MetaStorage.sol";

abstract contract MetaModifiers {
  using MetaStorage for MetaStorage.State;
  
  function isVaildPool(Pool pool) internal view virtual returns(bool) {
    return pool != Pool.NONE ? true : false;
  }

  modifier ifIsVaildPool(Pool pool) {
    require(isVaildPool(pool), "MetaModifiers: This is not a valid pool");
    _;
  }

  function isValidCoin(Coin coin) internal view virtual returns(bool) {
    return coin != Coin.NONE ? true : false;
  }

  modifier ifIsValidCoin(Coin coin) {
    require(isValidCoin(coin), "MetaModifiers: This is not a valid coin");
    _;
  }

  function isCompatible(Pool p, Coin c) internal view virtual returns(bool) {
    return MetaStorage.state().compatible[p][c];
  }

  modifier ifIsCompatible(Pool p, Coin c) {
    require(isCompatible(p, c), "MetaModifiers: This token is incompatible with this pool");
    _;
  }

  function isSBV() internal view virtual returns(bool) {
    return MetaStorage.state().SBV == msg.sender;
  }

  modifier ifIsSBV {
    require(isSBV(), "MetaModifiers: can only be called by SBV");
    _;
  }

  function isSBT() internal view virtual returns(bool) {
    return MetaStorage.state().SBT == msg.sender;
  }

  modifier ifIsSBT {
    require(isSBT(),
      "MetaModifiers: can only be called by SBT");
    _;
  }

  function isSBD() internal view virtual returns(bool) {
    return address(this) == msg.sender;
  }

  modifier ifIsSBD {
    require(isSBD(), "MetaModifiers: can only be called by StableBattle");
    _;
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

import { KnightGetters } from "./KnightGetters.sol";

abstract contract KnightModifiers is KnightGetters {
  function isKnight(uint256 knightId) internal view virtual returns(bool) {
    return knightId >= type(uint256).max - _knightsMintedTotal();
  }
  
  modifier ifIsKnight(uint256 knightId) {
    require(isKnight(knightId),
      "KnightModifiers: Wrong id for knight");
    _;
  }

  function isInAnyClan(uint256 knightId) internal view virtual returns(bool) {
    return _knightClan(knightId) != 0;
  }

  modifier ifIsInAnyClan(uint256 knightId) {
    require(isInAnyClan(knightId),
      "KnightModifiers: This knight don't belong to any clan");
    _;
  }

  function isInClan(uint256 knightId, uint256 clanId) internal view virtual returns(bool) {
    return _knightClan(knightId) == clanId;
  }

  modifier ifIsInClan(uint256 knightId, uint256 clanId) {
    require(isInClan(knightId, clanId),
      "KnightModifiers: This knight don't belong to this clan");
    _;
  }

  function notInClan(uint256 knightId) internal view virtual returns(bool) {
    return _knightClan(knightId) == 0;
  }

  modifier ifNotInClan(uint256 knightId) {
    require(notInClan(knightId),
      "KnightModifiers: This knight already belongs to some clan");
    _;
  }
}

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.0;

import { Clan, Proposal, ClanStorage } from "../Clan/ClanStorage.sol";

abstract contract ClanGetters {
  using ClanStorage for ClanStorage.State;

  function _clanInfo(uint clanId) internal view virtual returns(Clan memory) {
    return ClanStorage.state().clan[clanId];
  }

  function _clanLeader(uint clanId) internal view virtual returns(uint256) {
    return ClanStorage.state().clan[clanId].leader;
  }

  function _clanTotalMembers(uint clanId) internal view virtual returns(uint) {
    return ClanStorage.state().clan[clanId].totalMembers;
  }
  
  function _clanStake(uint clanId) internal view virtual returns(uint256) {
    return ClanStorage.state().clan[clanId].stake;
  }

  function _clanLevel(uint clanId) internal view virtual returns(uint) {
    return ClanStorage.state().clan[clanId].level;
  }

  function _stakeOf(address benefactor, uint clanId) internal view virtual returns(uint256) {
    return ClanStorage.state().stake[benefactor][clanId];
  }

  function _clanLevelThreshold(uint level) internal view virtual returns (uint) {
    return ClanStorage.state().levelThresholds[level];
  }

  function _clanMaxLevel() internal view virtual returns (uint) {
    return ClanStorage.state().levelThresholds.length;
  }

  function _proposal(uint256 knightId, uint256 clanId) internal view virtual returns(Proposal) {
    return ClanStorage.state().proposal[knightId][clanId];
  }

  function _clansInTotal() internal view virtual returns(uint256) {
    return ClanStorage.state().clansInTotal;
  }
}

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.0;

import { ClanStorage, Clan, Proposal } from "../Clan/ClanStorage.sol";

abstract contract ClanModifiers {
  using ClanStorage for ClanStorage.State;
  
  function clanExists(uint256 clanId) internal view returns(bool) {
    return ClanStorage.state().clan[clanId].leader != 0;
  }

  modifier ifClanExists(uint256 clanId) {
    require(clanExists(clanId),
      "ClanModifiers: This clan doesn't exist");
    _;
  }

  function isClanLeader(uint256 knightId, uint256 clanId) internal view returns(bool) {
    return ClanStorage.state().clan[clanId].leader == knightId;
  }

  modifier ifIsClanLeader(uint256 knightId, uint clanId) {
    require(isClanLeader(knightId, clanId), 
      "ClanModifiers: This knight is doesn't own this clan");
    _;
  }

  function isNotClanLeader(uint256 knightId, uint256 clanId) internal view returns(bool) {
    return ClanStorage.state().clan[clanId].leader != knightId;
  }

  modifier ifIsNotClanLeader(uint256 knightId, uint clanId) {
    require(isNotClanLeader(knightId, clanId), 
      "ClanModifiers: This knight is already owns this clan");
    _;
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

import { Knight, KnightStorage } from "../Knight/KnightStorage.sol";
import { Pool, Coin } from "../Meta/MetaStorage.sol";

abstract contract KnightGetters {
  using KnightStorage for KnightStorage.State;

  function _knightInfo(uint256 knightId) internal view virtual returns(Knight memory) {
    return KnightStorage.state().knight[knightId];
  }

  function _knightCoin(uint256 knightId) internal view virtual returns(Coin) {
    return KnightStorage.state().knight[knightId].coin;
  }

  function _knightPool(uint256 knightId) internal view virtual returns(Pool) {
    return KnightStorage.state().knight[knightId].pool;
  }

  function _knightOwner(uint256 knightId) internal view virtual returns(address) {
    return KnightStorage.state().knight[knightId].owner;
  }

  function _knightClan(uint256 knightId) internal view virtual returns(uint256) {
    return KnightStorage.state().knight[knightId].inClan;
  }

  function _knightPrice(Coin coin) internal view virtual returns (uint256) {
    return KnightStorage.state().knightPrice[coin];
  }

  //returns amount of minted knights for a particular coin & pool
  function _knightsMinted(Pool pool, Coin coin) internal view virtual returns (uint256) {
    return KnightStorage.state().knightsMinted[pool][coin];
  }

  //returns amount of minted knights for any coin in a particular pool
  function _knightsMintedOfPool(Pool pool) internal view virtual returns (uint256 minted) {
    for (uint8 coin = 1; coin < uint8(type(Coin).max) + 1; coin++) {
      minted += _knightsMinted(pool, Coin(coin));
    }
  }

  //returns amount of minted knights for any pool in a particular coin
  function _knightsMintedOfCoin(Coin coin) internal view virtual returns (uint256 minted) {
    for (uint8 pool = 1; pool < uint8(type(Pool).max) + 1; pool++) {
      minted += _knightsMinted(Pool(pool), coin);
    }
  }

  //returns a total amount of minted knights
  function _knightsMintedTotal() internal view virtual returns (uint256 minted) {
    for (uint8 pool = 1; pool < uint8(type(Pool).max) + 1; pool++) {
      minted += _knightsMintedOfPool(Pool(pool));
    }
  }

  //returns amount of burned knights for a particular coin & pool
  function _knightsBurned(Pool pool, Coin coin) internal view virtual returns (uint256) {
    return KnightStorage.state().knightsBurned[pool][coin];
  }

  //returns amount of burned knights for any coin in a particular pool
  function _knightsBurnedOfPool(Pool pool) internal view virtual returns (uint256 burned) {
    for (uint8 coin = 1; coin < uint8(type(Coin).max) + 1; coin++) {
      burned += _knightsBurned(pool, Coin(coin));
    }
  }

  //returns amount of burned knights for any pool in a particular coin
  function _knightsBurnedOfCoin(Coin coin) internal view virtual returns (uint256 burned) {
    for (uint8 pool = 1; pool < uint8(type(Pool).max) + 1; pool++) {
      burned += _knightsBurned(Pool(pool), coin);
    }
  }

  //returns a total amount of burned knights
  function _knightsBurnedTotal() internal view virtual returns (uint256 burned) {
    for (uint8 pool = 1; pool < uint8(type(Pool).max) + 1; pool++) {
      burned += _knightsBurnedOfPool(Pool(pool));
    }
  }

  function _totalKnightSupply() internal view virtual returns (uint256) {
    return _knightsMintedTotal() - _knightsBurnedTotal();
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { AddressUtils } from '../../../utils/AddressUtils.sol';
import { IERC1155Internal } from '../IERC1155Internal.sol';
import { IERC1155Receiver } from '../IERC1155Receiver.sol';
import { ERC1155BaseStorage } from './ERC1155BaseStorage.sol';

/**
 * @title Base ERC1155 internal functions
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts/ (MIT license)
 */
abstract contract ERC1155BaseInternal is IERC1155Internal {
    using AddressUtils for address;

    /**
     * @notice query the balance of given token held by given address
     * @param account address to query
     * @param id token to query
     * @return token balance
     */
    function _balanceOf(address account, uint256 id)
        internal
        view
        virtual
        returns (uint256)
    {
        require(
            account != address(0),
            'ERC1155: balance query for the zero address'
        );
        return ERC1155BaseStorage.layout().balances[id][account];
    }

    /**
     * @notice mint given quantity of tokens for given address
     * @dev ERC1155Receiver implementation is not checked
     * @param account beneficiary of minting
     * @param id token ID
     * @param amount quantity of tokens to mint
     * @param data data payload
     */
    function _mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(account != address(0), 'ERC1155: mint to the zero address');

        _beforeTokenTransfer(
            msg.sender,
            address(0),
            account,
            _asSingletonArray(id),
            _asSingletonArray(amount),
            data
        );

        ERC1155BaseStorage.layout().balances[id][account] += amount;

        emit TransferSingle(msg.sender, address(0), account, id, amount);
    }

    /**
     * @notice mint given quantity of tokens for given address
     * @param account beneficiary of minting
     * @param id token ID
     * @param amount quantity of tokens to mint
     * @param data data payload
     */
    function _safeMint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        _mint(account, id, amount, data);

        _doSafeTransferAcceptanceCheck(
            msg.sender,
            address(0),
            account,
            id,
            amount,
            data
        );
    }

    /**
     * @notice mint batch of tokens for given address
     * @dev ERC1155Receiver implementation is not checked
     * @param account beneficiary of minting
     * @param ids list of token IDs
     * @param amounts list of quantities of tokens to mint
     * @param data data payload
     */
    function _mintBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(account != address(0), 'ERC1155: mint to the zero address');
        require(
            ids.length == amounts.length,
            'ERC1155: ids and amounts length mismatch'
        );

        _beforeTokenTransfer(
            msg.sender,
            address(0),
            account,
            ids,
            amounts,
            data
        );

        mapping(uint256 => mapping(address => uint256))
            storage balances = ERC1155BaseStorage.layout().balances;

        for (uint256 i; i < ids.length; ) {
            balances[ids[i]][account] += amounts[i];
            unchecked {
                i++;
            }
        }

        emit TransferBatch(msg.sender, address(0), account, ids, amounts);
    }

    /**
     * @notice mint batch of tokens for given address
     * @param account beneficiary of minting
     * @param ids list of token IDs
     * @param amounts list of quantities of tokens to mint
     * @param data data payload
     */
    function _safeMintBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        _mintBatch(account, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(
            msg.sender,
            address(0),
            account,
            ids,
            amounts,
            data
        );
    }

    /**
     * @notice burn given quantity of tokens held by given address
     * @param account holder of tokens to burn
     * @param id token ID
     * @param amount quantity of tokens to burn
     */
    function _burn(
        address account,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(account != address(0), 'ERC1155: burn from the zero address');

        _beforeTokenTransfer(
            msg.sender,
            account,
            address(0),
            _asSingletonArray(id),
            _asSingletonArray(amount),
            ''
        );

        mapping(address => uint256) storage balances = ERC1155BaseStorage
            .layout()
            .balances[id];

        unchecked {
            require(
                balances[account] >= amount,
                'ERC1155: burn amount exceeds balances'
            );
            balances[account] -= amount;
        }

        emit TransferSingle(msg.sender, account, address(0), id, amount);
    }

    /**
     * @notice burn given batch of tokens held by given address
     * @param account holder of tokens to burn
     * @param ids token IDs
     * @param amounts quantities of tokens to burn
     */
    function _burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(account != address(0), 'ERC1155: burn from the zero address');
        require(
            ids.length == amounts.length,
            'ERC1155: ids and amounts length mismatch'
        );

        _beforeTokenTransfer(msg.sender, account, address(0), ids, amounts, '');

        mapping(uint256 => mapping(address => uint256))
            storage balances = ERC1155BaseStorage.layout().balances;

        unchecked {
            for (uint256 i; i < ids.length; i++) {
                uint256 id = ids[i];
                require(
                    balances[id][account] >= amounts[i],
                    'ERC1155: burn amount exceeds balance'
                );
                balances[id][account] -= amounts[i];
            }
        }

        emit TransferBatch(msg.sender, account, address(0), ids, amounts);
    }

    /**
     * @notice transfer tokens between given addresses
     * @dev ERC1155Receiver implementation is not checked
     * @param operator executor of transfer
     * @param sender sender of tokens
     * @param recipient receiver of tokens
     * @param id token ID
     * @param amount quantity of tokens to transfer
     * @param data data payload
     */
    function _transfer(
        address operator,
        address sender,
        address recipient,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(
            recipient != address(0),
            'ERC1155: transfer to the zero address'
        );

        _beforeTokenTransfer(
            operator,
            sender,
            recipient,
            _asSingletonArray(id),
            _asSingletonArray(amount),
            data
        );

        mapping(uint256 => mapping(address => uint256))
            storage balances = ERC1155BaseStorage.layout().balances;

        unchecked {
            uint256 senderBalance = balances[id][sender];
            require(
                senderBalance >= amount,
                'ERC1155: insufficient balances for transfer'
            );
            balances[id][sender] = senderBalance - amount;
        }

        balances[id][recipient] += amount;

        emit TransferSingle(operator, sender, recipient, id, amount);
    }

    /**
     * @notice transfer tokens between given addresses
     * @param operator executor of transfer
     * @param sender sender of tokens
     * @param recipient receiver of tokens
     * @param id token ID
     * @param amount quantity of tokens to transfer
     * @param data data payload
     */
    function _safeTransfer(
        address operator,
        address sender,
        address recipient,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        _transfer(operator, sender, recipient, id, amount, data);

        _doSafeTransferAcceptanceCheck(
            operator,
            sender,
            recipient,
            id,
            amount,
            data
        );
    }

    /**
     * @notice transfer batch of tokens between given addresses
     * @dev ERC1155Receiver implementation is not checked
     * @param operator executor of transfer
     * @param sender sender of tokens
     * @param recipient receiver of tokens
     * @param ids token IDs
     * @param amounts quantities of tokens to transfer
     * @param data data payload
     */
    function _transferBatch(
        address operator,
        address sender,
        address recipient,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(
            recipient != address(0),
            'ERC1155: transfer to the zero address'
        );
        require(
            ids.length == amounts.length,
            'ERC1155: ids and amounts length mismatch'
        );

        _beforeTokenTransfer(operator, sender, recipient, ids, amounts, data);

        mapping(uint256 => mapping(address => uint256))
            storage balances = ERC1155BaseStorage.layout().balances;

        for (uint256 i; i < ids.length; ) {
            uint256 token = ids[i];
            uint256 amount = amounts[i];

            unchecked {
                uint256 senderBalance = balances[token][sender];

                require(
                    senderBalance >= amount,
                    'ERC1155: insufficient balances for transfer'
                );

                balances[token][sender] = senderBalance - amount;

                i++;
            }

            // balance increase cannot be unchecked because ERC1155Base neither tracks nor validates a totalSupply
            balances[token][recipient] += amount;
        }

        emit TransferBatch(operator, sender, recipient, ids, amounts);
    }

    /**
     * @notice transfer batch of tokens between given addresses
     * @param operator executor of transfer
     * @param sender sender of tokens
     * @param recipient receiver of tokens
     * @param ids token IDs
     * @param amounts quantities of tokens to transfer
     * @param data data payload
     */
    function _safeTransferBatch(
        address operator,
        address sender,
        address recipient,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        _transferBatch(operator, sender, recipient, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(
            operator,
            sender,
            recipient,
            ids,
            amounts,
            data
        );
    }

    /**
     * @notice wrap given element in array of length 1
     * @param element element to wrap
     * @return singleton array
     */
    function _asSingletonArray(uint256 element)
        private
        pure
        returns (uint256[] memory)
    {
        uint256[] memory array = new uint256[](1);
        array[0] = element;
        return array;
    }

    /**
     * @notice revert if applicable transfer recipient is not valid ERC1155Receiver
     * @param operator executor of transfer
     * @param from sender of tokens
     * @param to receiver of tokens
     * @param id token ID
     * @param amount quantity of tokens to transfer
     * @param data data payload
     */
    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try
                IERC1155Receiver(to).onERC1155Received(
                    operator,
                    from,
                    id,
                    amount,
                    data
                )
            returns (bytes4 response) {
                require(
                    response == IERC1155Receiver.onERC1155Received.selector,
                    'ERC1155: ERC1155Receiver rejected tokens'
                );
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert('ERC1155: transfer to non ERC1155Receiver implementer');
            }
        }
    }

    /**
     * @notice revert if applicable transfer recipient is not valid ERC1155Receiver
     * @param operator executor of transfer
     * @param from sender of tokens
     * @param to receiver of tokens
     * @param ids token IDs
     * @param amounts quantities of tokens to transfer
     * @param data data payload
     */
    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try
                IERC1155Receiver(to).onERC1155BatchReceived(
                    operator,
                    from,
                    ids,
                    amounts,
                    data
                )
            returns (bytes4 response) {
                require(
                    response ==
                        IERC1155Receiver.onERC1155BatchReceived.selector,
                    'ERC1155: ERC1155Receiver rejected tokens'
                );
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert('ERC1155: transfer to non ERC1155Receiver implementer');
            }
        }
    }

    /**
     * @notice ERC1155 hook, called before all transfers including mint and burn
     * @dev function should be overridden and new implementation must call super
     * @dev called for both single and batch transfers
     * @param operator executor of transfer
     * @param from sender of tokens
     * @param to receiver of tokens
     * @param ids token IDs
     * @param amounts quantities of tokens to transfer
     * @param data data payload
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { UintUtils } from './UintUtils.sol';

library AddressUtils {
    using UintUtils for uint256;

    function toString(address account) internal pure returns (string memory) {
        return uint256(uint160(account)).toHexString(20);
    }

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable account, uint256 amount) internal {
        (bool success, ) = account.call{ value: amount }('');
        require(success, 'AddressUtils: failed to send value');
    }

    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionCall(target, data, 'AddressUtils: failed low-level call');
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory error
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, error);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                'AddressUtils: failed low-level call with value'
            );
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory error
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            'AddressUtils: insufficient balance for call'
        );
        return _functionCallWithValue(target, data, value, error);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory error
    ) private returns (bytes memory) {
        require(
            isContract(target),
            'AddressUtils: function call to non-contract'
        );

        (bool success, bytes memory returnData) = target.call{ value: value }(
            data
        );

        if (success) {
            return returnData;
        } else if (returnData.length > 0) {
            assembly {
                let returnData_size := mload(returnData)
                revert(add(32, returnData), returnData_size)
            }
        } else {
            revert(error);
        }
    }
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

import { IERC165 } from '../../introspection/IERC165.sol';

/**
 * @title ERC1155 transfer receiver interface
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @notice validate receipt of ERC1155 transfer
     * @param operator executor of transfer
     * @param from sender of tokens
     * @param id token ID received
     * @param value quantity of tokens received
     * @param data data payload
     * @return function's own selector if transfer is accepted
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @notice validate receipt of ERC1155 batch transfer
     * @param operator executor of transfer
     * @param from sender of tokens
     * @param ids token IDs received
     * @param values quantities of tokens received
     * @param data data payload
     * @return function's own selector if transfer is accepted
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

library ERC1155BaseStorage {
    struct Layout {
        mapping(uint256 => mapping(address => uint256)) balances;
        mapping(address => mapping(address => bool)) operatorApprovals;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.ERC1155Base');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title utility functions for uint256 operations
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts/ (MIT license)
 */
library UintUtils {
    bytes16 private constant HEX_SYMBOLS = '0123456789abcdef';

    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return '0';
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

    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return '0x00';
        }

        uint256 length = 0;

        for (uint256 temp = value; temp != 0; temp >>= 8) {
            unchecked {
                length++;
            }
        }

        return toHexString(value, length);
    }

    function toHexString(uint256 value, uint256 length)
        internal
        pure
        returns (string memory)
    {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = '0';
        buffer[1] = 'x';

        unchecked {
            for (uint256 i = 2 * length + 1; i > 1; --i) {
                buffer[i] = HEX_SYMBOLS[value & 0xf];
                value >>= 4;
            }
        }

        require(value == 0, 'UintUtils: hex length insufficient');

        return string(buffer);
    }
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