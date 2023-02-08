// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC1155MetadataInternal } from './IERC1155MetadataInternal.sol';
import { ERC1155MetadataStorage } from './ERC1155MetadataStorage.sol';

/**
 * @title ERC1155Metadata internal functions
 */
abstract contract ERC1155MetadataInternal is IERC1155MetadataInternal {
    /**
     * @notice set base metadata URI
     * @dev base URI is a non-standard feature adapted from the ERC721 specification
     * @param baseURI base URI
     */
    function _setBaseURI(string memory baseURI) internal {
        ERC1155MetadataStorage.layout().baseURI = baseURI;
    }

    /**
     * @notice set per-token metadata URI
     * @param tokenId token whose metadata URI to set
     * @param tokenURI per-token URI
     */
    function _setTokenURI(uint256 tokenId, string memory tokenURI) internal {
        ERC1155MetadataStorage.layout().tokenURIs[tokenId] = tokenURI;
        emit URI(tokenURI, tokenId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title ERC1155 metadata extensions
 */
library ERC1155MetadataStorage {
    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.ERC1155Metadata');

    struct Layout {
        string baseURI;
        mapping(uint256 => string) tokenURIs;
    }

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
 * @title Partial ERC1155Metadata interface needed by internal functions
 */
interface IERC1155MetadataInternal {
    event URI(string value, uint256 indexed tokenId);
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import { AccessControlStorage } from "./AccessControlStorage.sol";
import { Role } from "../../Meta/DataStructures.sol";
import { IAccessControlErrors } from "./IAccessControl.sol";

abstract contract AccessControlModifiers is IAccessControlErrors {
  function callerIsAdmin() internal view returns(bool) {
    return AccessControlStorage.state().role[msg.sender] == Role.ADMIN;
  }

  modifier ifCallerIsAdmin() {
    if(!callerIsAdmin()) {
      revert AccessControlModifiers_CallerIsNotAdmin(msg.sender);
    }
    _;
  }
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import { Role, ClanRole } from "../../Meta/DataStructures.sol";

library AccessControlStorage {
  struct State {
    mapping (address => Role) role;
    //knightId => ClanRole
    mapping (uint256 => ClanRole) clanRole;
  }

  bytes32 internal constant STORAGE_SLOT = keccak256("AccessControl.storage");

  function state() internal pure returns (State storage l) {
    bytes32 slot = STORAGE_SLOT;
    assembly {
      l.slot := slot
    }
  }
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

interface IAccessControlEvents {
  event AdminAdded(address newAdmin);
  event AdminRemoved(address oldAdmin);
}

interface IAccessControlErrors {
  error AccessControlModifiers_CallerIsNotAdmin(address caller);
}

interface IAccessControl is IAccessControlEvents, IAccessControlErrors {
  function addAdmin(address newAdmin) external;

  function removeAdmin(address oldAdmin) external;
}

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.0;

import { Clan, ClanRole } from "../../Meta/DataStructures.sol";

library ClanStorage {
  struct State {
    uint[] levelThresholds;
    uint[] maxMembers;
    uint256 clansInTotal;

    //Clan => clan leader id
    mapping(uint256 => uint256) clanLeader;
    //Clan => stake amount
    mapping(uint256 => uint256) clanStake;
    //Clan => amount of members in clanId
    mapping(uint256 => uint256) clanTotalMembers;
    //Clan => level of clanId
    mapping(uint256 => uint256) clanLevel;
    //Clan => name of said clan
    mapping(uint256 => string) clanName;
    //Clan name => taken or not
    mapping(string => bool) clanNameTaken;
    
    //Knight => id of clan where join proposal is sent
    mapping (uint256 => uint256) joinProposal;
    //Knight => end of cooldown
    mapping(uint256 => uint256) clanActivityCooldown;
    //Knight => clan join proposal sent
    mapping(uint256 => bool) joinProposalPending;
    //Kinight => Role in clan
    mapping(uint256 => ClanRole) roleInClan;
    //Knight => kick cooldown duration
    mapping(uint256 => uint) clanKickCooldown;

    //address => clanId => amount
    mapping (address => mapping (uint => uint256)) stake;
    //address => withdrawal cooldown
    mapping (address => uint256) withdrawalCooldown;
    //address => allowed withdrawal
    mapping (address => uint256) allowedWithdrawal;
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

import { Pool, Coin } from "../../Meta/DataStructures.sol";

import { ERC1155MetadataInternal } from "@solidstate/contracts/token/ERC1155/metadata/ERC1155MetadataInternal.sol";
import { MetaStorage } from "../../Meta/MetaStorage.sol";
import { KnightStorage } from "../Knight/KnightStorage.sol";
import { ClanStorage } from "../Clan/ClanStorage.sol";
import { AccessControlModifiers } from "../AccessControl/AccessControlModifiers.sol";

import { IDebug } from "../Debug/IDebug.sol";

contract DebugFacet is IDebug, ERC1155MetadataInternal, AccessControlModifiers {
  function debugSetBaseURI(string memory baseURI) external ifCallerIsAdmin {
    _setBaseURI(baseURI);
  }

  function debugSetTokenURI(uint256 tokenId, string memory tokenURI) external ifCallerIsAdmin {
    _setTokenURI(tokenId, tokenURI);
  }

  function debugEnablePoolCoinMinting(Pool pool, Coin coin) external ifCallerIsAdmin {
    MetaStorage.state().compatible[pool][coin] = true;
  }

  function debugDisablePoolCoinMinting(Pool pool, Coin coin) external ifCallerIsAdmin {
    MetaStorage.state().compatible[pool][coin] = true;
  }

  function debugSetCoinAddress(Coin coin, address newAddress) external ifCallerIsAdmin {
    MetaStorage.state().coin[coin] = newAddress;
  }

  function debugSetACoinAddress(Coin coin, address newAddress) external ifCallerIsAdmin {
    MetaStorage.state().acoin[coin] = newAddress;
  }

  function debugSetKnightPrice(Coin coin, uint256 newPrice) external ifCallerIsAdmin {
    KnightStorage.state().knightPrice[coin] = newPrice;
  }

  function debugSetLevelThresholds(uint[] memory newThresholds) external ifCallerIsAdmin {
    ClanStorage.state().levelThresholds = newThresholds;
  }
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import { Pool, Coin } from "../../Meta/DataStructures.sol";

interface IDebug {
  function debugSetBaseURI(string memory baseURI) external;

  function debugSetTokenURI(uint256 tokenId, string memory tokenURI) external;

  function debugEnablePoolCoinMinting(Pool pool, Coin coin) external;

  function debugDisablePoolCoinMinting(Pool pool, Coin coin) external;

  function debugSetCoinAddress(Coin coin, address newAddress) external;

  function debugSetACoinAddress(Coin coin, address newAddress) external;

  function debugSetKnightPrice(Coin coin, uint256 newPrice) external;

  function debugSetLevelThresholds(uint[] memory newThresholds) external;
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

enum Pool { NONE, TEST, AAVE }

enum Coin { NONE, TEST, USDT, USDC, EURS }

struct Knight {
  Pool pool;
  Coin coin;
  address owner;
  uint256 inClan;
}

enum gearSlot { NONE, WEAPON, SHIELD, HELMET, ARMOR, PANTS, SLEEVES, GLOVES, BOOTS, JEWELRY, CLOAK }

struct Clan {
  uint256 leader;
  uint256 stake;
  uint totalMembers;
  uint level;
}

enum Role { NONE, ADMIN }

enum ClanRole { NONE, PRIVATE, MOD, ADMIN, OWNER }

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.0;

import { Coin, Pool } from "../Meta/DataStructures.sol";

library MetaStorage {
  struct State {
    // StableBattle EIP20 Token address
    address BEER;
    // StableBattle EIP721 Village address
    address SBV;

    mapping (Pool => address) pool;
    mapping (Coin => address) coin;
    mapping (Coin => address) acoin;
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