// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import { IAccessControl } from "./IAccessControl.sol";
import { AccessControlInternal } from "./AccessControlInternal.sol";
import { AccessControlModifiers } from "./AccessControlModifiers.sol";

contract AccessControlFacet is IAccessControl, AccessControlInternal, AccessControlModifiers {
  function addAdmin(address newAdmin) external ifCallerIsAdmin {
    _addAdmin(newAdmin);
  }

  function removeAdmin(address oldAdmin) external ifCallerIsAdmin {
    _removeAdmin(oldAdmin);
  }
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import { AccessControlStorage } from "./AccessControlStorage.sol";
import { Role } from "../../Meta/DataStructures.sol";
import { IAccessControlEvents } from "./IAccessControl.sol";

abstract contract AccessControlInternal is  IAccessControlEvents {
  function _addAdmin(address newAdmin) internal {
    AccessControlStorage.state().role[newAdmin] = Role.ADMIN;
    emit AdminAdded(newAdmin);
  }

  function _removeAdmin(address oldAdmin) internal {
    AccessControlStorage.state().role[oldAdmin] = Role.ADMIN;
    emit AdminRemoved(oldAdmin);
  }
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