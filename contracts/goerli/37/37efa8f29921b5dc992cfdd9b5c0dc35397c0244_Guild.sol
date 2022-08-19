// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.13;

import { Soul } from "./Soul.sol";
import { Vault } from "./utils/Vault.sol";
import { Error } from "./interfaces/Error.sol";
import { IGuild, Role, GuildType } from "./interfaces/IGuild.sol";
import { SafeCastLib } from "solmate/utils/SafeCastLib.sol";

contract Guild is IGuild, Vault {
  using SafeCastLib for uint256;
  using Soul for address;

  GuildType public guildType;

  uint32 public maxMembers;

  uint32 public currentMembers;

  constructor(
    address owner_,
    GuildType guildType_,
    uint32 maxMembers_
  ) {
    if (maxMembers_ < 1) revert Error.MaxMembersCannotBeSmallerThanMemberCount();

    // Set the guild info
    guildType = guildType_;
    maxMembers = maxMembers_;
    currentMembers = 1;

    // Set role to OWNER
    _setRole(owner_, Role.OWNER);
  }

  function batchQuerySouls(address[] calldata accounts) external view returns (SoulQuery[] memory) {
    SoulQuery[] memory souls = new SoulQuery[](accounts.length);
    for (uint256 i = 0; i < accounts.length; ++i) {
      souls[i] = SoulQuery({
        blacklisted: accounts[i].isBlacklisted(),
        role: accounts[i].getRole(),
        data: accounts[i].getData()
      });
    }
    return souls;
  }

  function joinGuild() external matchRole(Role.NON_MEMBER) {
    if (guildType != GuildType.PUBLIC) revert Error.GuildNotPublic();

    if (maxMembers - currentMembers++ < 1) revert Error.ExceedsMemberLimit();

    if (msg.sender.isBlacklisted()) revert Error.Blacklisted(msg.sender);

    _setRole(msg.sender, Role.MEMBER);
  }

  function addMembers(address[] calldata members) external hasRole(Role.MANAGER) {
    if ((currentMembers += members.length.safeCastTo32()) > maxMembers) {
      revert Error.ExceedsMemberLimit();
    }

    for (uint256 i = 0; i < members.length; ++i) {
      if (members[i].hasRole(Role.MEMBER)) revert Error.AlreadyJoined(members[i]);

      if (members[i].isBlacklisted()) revert Error.Blacklisted(members[i]);

      _setRole(members[i], Role.MEMBER);
    }
  }

  function leaveGuild() external hasRole(Role.MEMBER) {
    if (msg.sender.matchRole(Role.OWNER)) revert Error.OwnerCannotLeave();

    --currentMembers;

    _setRole(msg.sender, Role.NON_MEMBER);
  }

  function removeMembers(address[] calldata members) external hasRole(Role.MANAGER) {
    currentMembers -= members.length.safeCastTo32();

    for (uint256 i = 0; i < members.length; ++i) {
      if (members[i].matchRole(Role.OWNER)) revert Error.OwnerCannotLeave();

      if (members[i].matchRole(Role.NON_MEMBER)) revert Error.NotMember(members[i]);

      _setRole(members[i], Role.NON_MEMBER);
    }
  }

  function setBlacklist(address[] calldata accounts, bool blacklist)
    external
    hasRole(Role.MANAGER)
  {
    for (uint256 i = 0; i < accounts.length; ++i) {
      if (accounts[i].hasRole(Role.MEMBER)) revert Error.MemberCannotBeBlacklisted(accounts[i]);

      accounts[i].setBlacklist(blacklist);

      emit UpdateBlacklist(accounts[i], blacklist);
    }
  }

  function setMemberRoles(address[] calldata members, Role role) external matchRole(Role.OWNER) {
    if (role == Role.OWNER || role == Role.NON_MEMBER) {
      revert Error.CannotSetToOwnerOrNonMember();
    }

    for (uint256 i = 0; i < members.length; ++i) {
      if (members[i].matchRole(Role.NON_MEMBER)) revert Error.NotMember(members[i]);

      if (members[i] == msg.sender) revert Error.OnlyOneOwner();

      _setRole(members[i], role);
    }
  }

  function transferOwnership(address to, Role newRole) external matchRole(Role.OWNER) {
    if (newRole == Role.OWNER || newRole == Role.NON_MEMBER) {
      revert Error.CannotSetToOwnerOrNonMember();
    }

    if (to.matchRole(Role.NON_MEMBER)) revert Error.NotMember(to);

    _setRole(msg.sender, newRole);

    _setRole(to, Role.OWNER);
  }

  function changeGuildType(GuildType guildType_) external matchRole(Role.OWNER) {
    guildType = guildType_;

    emit UpdateGuildType(guildType_);
  }

  function changeMaxMembers(uint32 maxMembers_) external matchRole(Role.OWNER) {
    if ((maxMembers = maxMembers_) < currentMembers) {
      revert Error.MaxMembersCannotBeSmallerThanMemberCount();
    }

    emit UpdateMaxMembers(maxMembers_);
  }

  function executeTransaction(
    address to,
    uint256 value,
    bytes memory data
  ) external hasRole(Role.MANAGER) returns (bytes memory) {
    (bool success, bytes memory result) = to.call{ value: value }(data);

    if (!success) revert Error.TransactionExecutionFailed(result);

    emit ExecuteTransaction(msg.sender, to, value, data);

    return result;
  }

  function _setRole(address to, Role newRole) private {
    emit UpdateRole(to, to.getRole(), newRole);

    to.setRole(newRole);
  }

  modifier hasRole(Role role) {
    if (msg.sender.hasRole(role) == false) revert Error.Unauthorized(role);
    _;
  }

  modifier matchRole(Role role) {
    if (msg.sender.matchRole(role) == false) revert Error.Unauthorized(role);
    _;
  }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.13;

import { Role, IGuild } from "./interfaces/IGuild.sol";

// @notice Soul storage library, partially inspired by Diamond storage library
// @author regohiro
library Soul {
  struct SoulStorage {
    /**
     * Mapping from address to soul metadata
     *
     * Bits layout:
     * - [0]      Soulbound token minted boolean
     * - [1..2]   Role enum (0: non-member, 1: member, 2: manager, 3: owner)
     * - [3]      Blacklist boolean
     * - [4..7]   Padding
     * - [8..255] 31 bytes Soul data
     */
    mapping(address => uint256) soul;
  }

  function _soulStorage() internal pure returns (SoulStorage storage ss) {
    bytes32 position = keccak256("soul.storage");
    assembly {
      ss.slot := position
    }
  }

  function setRole(address account, Role role) internal {
    SoulStorage storage ss = _soulStorage();
    uint256 masked = ss.soul[account] & ~uint256(0x6); // Mask index 1-2 with zeros
    uint256 newSoul = masked | (uint256(role) << 1);
    ss.soul[account] = newSoul;
  }

  function matchRole(address account, Role role) internal view returns (bool) {
    SoulStorage storage ss = _soulStorage();
    return (ss.soul[account] >> 1) & 0x3 == uint256(role);
  }

  function hasRole(address account, Role role) internal view returns (bool) {
    SoulStorage storage ss = _soulStorage();
    return (ss.soul[account] >> 1) & 0x3 >= uint256(role);
  }

  function getRole(address account) internal view returns (Role) {
    SoulStorage storage ss = _soulStorage();
    uint256 role = (ss.soul[account] >> 1) & 0x3;
    return Role(role);
  }

  function setBlacklist(address account, bool blacklist) internal {
    SoulStorage storage ss = _soulStorage();
    uint256 masked = ss.soul[account] & ~uint256(0x8);
    uint256 newSoul = masked | ((blacklist ? 0x1 : 0x0) << 3);
    ss.soul[account] = newSoul;
  }

  function isBlacklisted(address account) internal view returns (bool result) {
    SoulStorage storage ss = _soulStorage();
    uint256 value = ss.soul[account] & 0x8;

    assembly {
      result := value // Auto cast to boolean
    }
  }

  function setAsMinted(address account) internal {
    SoulStorage storage ss = _soulStorage();
    ss.soul[account] |= 0x1;
  }

  function isMinted(address account) internal view returns (bool result) {
    SoulStorage storage ss = _soulStorage();
    uint256 value = ss.soul[account] & 0x1;

    assembly {
      result := value // Auto cast to boolean
    }
  }

  function setData(address account, uint248 data) internal {
    SoulStorage storage ss = _soulStorage();
    uint256 masked = ss.soul[account] & 0xFF;
    uint256 newSoul = masked | (uint256(data) << 8);
    ss.soul[account] = newSoul;
  }

  function getData(address account) internal view returns (uint256) {
    SoulStorage storage ss = _soulStorage();
    return ss.soul[account] >> 8;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

// @notice Utility contract for receiving ethers, ERC721 and ERC1155 tokens
// @author regohiro
abstract contract Vault {
  event ReceivedEther(address indexed from, uint256 value);

  event ReceivedERC721(address indexed token, address indexed from, uint256 indexed id);

  event ReceivedERC1155(
    address indexed token,
    address indexed from,
    uint256 indexed id,
    uint256 amount
  );

  event ReceivedERC1155Batch(
    address indexed token,
    address indexed from,
    uint256[] indexed ids,
    uint256[] amounts
  );

  receive() external payable {
    emit ReceivedEther(msg.sender, msg.value);
  }

  function onERC721Received(
    address from,
    address,
    uint256 id,
    bytes calldata
  ) external returns (bytes4) {
    emit ReceivedERC721(msg.sender, from, id);
    return this.onERC721Received.selector;
  }

  function onERC1155Received(
    address from,
    address,
    uint256 id,
    uint256 amount,
    bytes calldata
  ) external returns (bytes4) {
    emit ReceivedERC1155(msg.sender, from, id, amount);
    return this.onERC1155Received.selector;
  }

  function onERC1155BatchReceived(
    address from,
    address,
    uint256[] calldata ids,
    uint256[] calldata amounts,
    bytes calldata
  ) external returns (bytes4) {
    emit ReceivedERC1155Batch(msg.sender, from, ids, amounts);
    return this.onERC1155BatchReceived.selector;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import { Role } from "./IGuild.sol";

// Error namespace
library Error {
  error ZeroAddress();

  error NotMinted();

  error InvalidAccess(Role requiredRole);

  error Unauthorized(Role requiredRole);

  error OnlyOneOwner();

  error OwnerCannotLeave();

  error GuildNotPublic();

  error NotMember(address account);

  error ExceedsMemberLimit();

  error AlreadyJoined(address account);

  error CannotSetToOwnerOrNonMember();

  error Blacklisted(address account);

  error MaxMembersCannotBeSmallerThanMemberCount();

  error MemberCannotBeBlacklisted(address account);

  error OnlyMetadataOperator();

  error TransactionExecutionFailed(bytes result);

  error OnlyOwner();
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.0;

enum Role {
  NON_MEMBER,
  MEMBER,
  MANAGER,
  OWNER
}

enum GuildType {
  PUBLIC,
  PROTECTED,
  PRIVATE
}

interface IGuild {
  struct SoulQuery {
    bool blacklisted;
    Role role;
    uint256 data;
  }

  event UpdateRole(address indexed account, Role indexed previousRole, Role indexed role);

  event UpdateGuildType(GuildType guildType);

  event UpdateMaxMembers(uint256 maxMember);

  event ExecuteTransaction(address indexed from, address indexed to, uint256 value, bytes data);

  event UpdateBlacklist(address indexed account, bool indexed blacklist);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @notice Safe unsigned integer casting library that reverts on overflow.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/SafeCastLib.sol)
library SafeCastLib {
    function safeCastTo248(uint256 x) internal pure returns (uint248 y) {
        require(x < 1 << 248);

        y = uint248(x);
    }

    function safeCastTo224(uint256 x) internal pure returns (uint224 y) {
        require(x < 1 << 224);

        y = uint224(x);
    }

    function safeCastTo192(uint256 x) internal pure returns (uint192 y) {
        require(x < 1 << 192);

        y = uint192(x);
    }

    function safeCastTo160(uint256 x) internal pure returns (uint160 y) {
        require(x < 1 << 160);

        y = uint160(x);
    }

    function safeCastTo128(uint256 x) internal pure returns (uint128 y) {
        require(x < 1 << 128);

        y = uint128(x);
    }

    function safeCastTo96(uint256 x) internal pure returns (uint96 y) {
        require(x < 1 << 96);

        y = uint96(x);
    }

    function safeCastTo64(uint256 x) internal pure returns (uint64 y) {
        require(x < 1 << 64);

        y = uint64(x);
    }

    function safeCastTo32(uint256 x) internal pure returns (uint32 y) {
        require(x < 1 << 32);

        y = uint32(x);
    }

    function safeCastTo8(uint256 x) internal pure returns (uint8 y) {
        require(x < 1 << 8);

        y = uint8(x);
    }
}