// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import { IAccessControl } from "./IAccessControl.sol";
import { AccessControlInternal } from "./AccessControlInternal.sol";

contract AccessControlFacet is IAccessControl, AccessControlInternal {
  function addAdmin(address newAdmin) external {
    _addAdmin(newAdmin);
  }

  function removeAdmin(address oldAdmin) external {
    _removeAdmin(oldAdmin);
  }
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import { IAccessControlErrors } from "./IAccessControlErrors.sol";
import { IAccessControlEvents } from "./IAccessControlEvents.sol";

interface IAccessControl is IAccessControlErrors, IAccessControlEvents {
  function addAdmin(address newAdmin) external;

  function removeAdmin(address oldAdmin) external;
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import { AccessControlStorage } from "./AccessControlStorage.sol";
import { Role } from "../../Meta/DataStructures.sol";
import { IAccessControlEvents } from "./IAccessControlEvents.sol";

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

interface IAccessControlErrors {
  error AccessControlModifiers_CallerIsNotAdmin(address caller);
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

interface IAccessControlEvents {
  event AdminAdded(address newAdmin);
  event AdminRemoved(address oldAdmin);
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

import { Role } from "../../Meta/DataStructures.sol";

library AccessControlStorage {
  struct State {
    mapping (address => Role) role;
  }

  bytes32 internal constant STORAGE_SLOT = keccak256("AccessControl.storage");

  function state() internal pure returns (State storage l) {
    bytes32 slot = STORAGE_SLOT;
    assembly {
      l.slot := slot
    }
  }
}