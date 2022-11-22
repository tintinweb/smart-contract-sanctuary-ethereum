// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "../abstracts/Extension.sol";
import "../interfaces/IDaoCore.sol";
import "../helpers/Constants.sol";

contract DaoCore is Extension, IDaoCore, Constants {
    /// @notice track all members of the DAO with their roles
    mapping(address => mapping(bytes4 => bool)) public members;

    /// @notice counter of existing members
    uint256 public override membersCount;

    /// @notice list of existing roles in the DAO
    bytes4[] private _roles;

    /// @notice track of Extensions and Adapters
    mapping(bytes4 => Entry) public entries;

    /**
     * @notice `admin` become grant the role of MANAGING and ONBOARDING to add
     * new member in the DAO and new Entries
     */
    constructor(address admin) Extension(address(this), Slot.CORE) {
        _addAdmin(admin);
        _addSlotEntry(Slot.MANAGING, admin, false);
        _addSlotEntry(Slot.ONBOARDING, admin, false);

        // push roles
        _roles.push(ROLE_MEMBER);
        _roles.push(ROLE_ADMIN);
        _roles.push(ROLE_PROPOSER);
    }

    /* //////////////////////////
            PUBLIC FUNCTIONS
    ////////////////////////// */
    function changeMemberStatus(
        address account,
        bytes4 role,
        bool value
    ) external onlyAdapter(Slot.ONBOARDING) {
        require(account != address(0), "Core: zero address used");
        if (role == ROLE_MEMBER && !value) {
            _revokeMember(account);
        } else {
            _changeMemberStatus(account, role, value);
        }
        emit MemberStatusChanged(account, role, value);
    }

    function addNewAdmin(address account) external onlyAdapter(Slot.ONBOARDING) {
        require(account != address(0), "Core: zero address used");
        _addAdmin(account);
        emit MemberStatusChanged(account, ROLE_ADMIN, true);
    }

    function changeSlotEntry(bytes4 slot, address contractAddr)
        external
        onlyAdapter(Slot.MANAGING)
    {
        require(slot != Slot.EMPTY, "Core: empty slot");
        Entry memory entry_ = entries[slot];

        if (contractAddr == address(0)) {
            _removeSlotEntry(slot);
        } else {
            // low level call "try/catch" => https://github.com/dragonfly-xyz/useful-solidity-patterns/tree/main/patterns/error-handling#low-level-calls
            (, bytes memory slotIdData) = address(contractAddr).staticcall(
                // Encode the call data (function on someContract to call + arguments)
                abi.encodeCall(ISlotEntry.slotId, ())
            );
            if (slotIdData.length != 32) {
                revert("Core: inexistant slotId() impl");
            }
            require(bytes4(slotIdData) == slot, "Core: slot & address not match");

            if (entry_.slot == Slot.EMPTY) {
                entry_.isExtension = ISlotEntry(contractAddr).isExtension();
                _addSlotEntry(slot, contractAddr, entry_.isExtension);
            } else {
                // replace => ext is ext!
                bool isExt = ISlotEntry(contractAddr).isExtension();
                require(entry_.isExtension == isExt, "Core: wrong entry setup");
                entry_.isExtension = isExt; // for event
                _addSlotEntry(slot, contractAddr, isExt);
            }
        }

        emit SlotEntryChanged(slot, entry_.isExtension, entry_.contractAddr, contractAddr);
    }

    /* //////////////////////////
                GETTERS
    ////////////////////////// */
    function hasRole(address account, bytes4 role) external view returns (bool) {
        return members[account][role];
    }

    function getRolesList() external view returns (bytes4[] memory) {
        return _roles;
    }

    function isSlotActive(bytes4 slot) external view returns (bool) {
        return entries[slot].slot != Slot.EMPTY;
    }

    function isSlotExtension(bytes4 slot) external view returns (bool) {
        return entries[slot].isExtension;
    }

    function getSlotContractAddr(bytes4 slot) external view returns (address) {
        return entries[slot].contractAddr;
    }

    /* //////////////////////////
        INTERNAL FUNCTIONS
    ////////////////////////// */
    function _addAdmin(address account) internal {
        if (!members[account][ROLE_MEMBER]) {
            unchecked {
                ++membersCount;
            }
            members[account][ROLE_MEMBER] = true;
        }
        require(!members[account][ROLE_ADMIN], "Core: already an admin");
        members[account][ROLE_ADMIN] = true;
    }

    function _revokeMember(address account) internal {
        bytes4[] memory rolesList = _roles;

        for (uint256 i; i < rolesList.length; ) {
            delete members[account][rolesList[i]];
            unchecked {
                ++i;
            }
        }
        unchecked {
            --membersCount;
        }
    }

    function _changeMemberStatus(
        address account,
        bytes4 role,
        bool value
    ) internal {
        require(members[account][role] != value, "Core: role not changing");
        if (role == ROLE_MEMBER && value) {
            unchecked {
                ++membersCount;
            }
        }
        members[account][role] = value;
    }

    function _addSlotEntry(
        bytes4 slot,
        address newContractAddr,
        bool isExt
    ) internal {
        entries[slot] = Entry(slot, isExt, newContractAddr);
    }

    function _removeSlotEntry(bytes4 slot) internal {
        delete entries[slot];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "openzeppelin-contracts/utils/Counters.sol";

import "./SlotEntry.sol";
import "../interfaces/IDaoCore.sol";

/**
 * @notice abstract contract used for Extension and DaoCore,
 * add a guard which accept only call from Adapters
 */
abstract contract Extension is SlotEntry {
    modifier onlyAdapter(bytes4 slot_) {
        require(
            IDaoCore(_core).getSlotContractAddr(slot_) == msg.sender,
            "Cores: not the right adapter"
        );
        _;
    }

    constructor(address core, bytes4 slot) SlotEntry(core, slot, true) {}
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IDaoCore {
    event SlotEntryChanged(
        bytes4 indexed slot,
        bool indexed isExtension,
        address oldContractAddr,
        address newContractAddr
    );

    event MemberStatusChanged(
        address indexed member,
        bytes4 indexed roles,
        bool indexed actualValue
    );

    struct Entry {
        bytes4 slot;
        bool isExtension;
        address contractAddr;
    }

    function changeSlotEntry(bytes4 slot, address contractAddr) external;

    function addNewAdmin(address account) external;

    function changeMemberStatus(
        address account,
        bytes4 role,
        bool value
    ) external;

    function membersCount() external returns (uint256);

    function hasRole(address account, bytes4 role) external returns (bool);

    function getRolesList() external returns (bytes4[] memory);

    function isSlotActive(bytes4 slot) external view returns (bool);

    function isSlotExtension(bytes4 slot) external view returns (bool);

    function getSlotContractAddr(bytes4 slot) external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

/**
 * @dev Constants used in the DAO
 */
contract Constants {
    // CREDIT
    bytes4 internal constant CREDIT_VOTE = bytes4(keccak256("credit-vote"));

    // VAULTS
    bytes4 internal constant TREASURY = bytes4(keccak256("treasury"));

    // VOTE PARAMS
    bytes4 internal constant VOTE_STANDARD = bytes4(keccak256("vote-standard"));

    /**
     * @dev Collection of roles available for DAO users
     */
    bytes4 internal constant ROLE_MEMBER = bytes4(keccak256("role-member"));
    bytes4 internal constant ROLE_PROPOSER = bytes4(keccak256("role-proposer"));
    bytes4 internal constant ROLE_ADMIN = bytes4(keccak256("role-admin"));
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "../helpers/Slot.sol";
import "../interfaces/ISlotEntry.sol";

/**
 * @notice abstract contract shared by Adapter, Extensions and
 * DaoCore, contains informations related to slots.
 *
 * @dev states of this contract are called to perform some checks,
 * especially when a new adapter or extensions is plugged to the
 * DAO
 */
abstract contract SlotEntry is ISlotEntry {
    address internal immutable _core;
    bytes4 public immutable override slotId;
    bool public immutable override isExtension;

    constructor(
        address core,
        bytes4 slot,
        bool isExt
    ) {
        require(core != address(0), "SlotEntry: zero address");
        require(slot != Slot.EMPTY, "SlotEntry: empty slot");
        _core = core;
        slotId = slot;
        isExtension = isExt;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

/**
 * @dev DAO Slot access collection
 */
library Slot {
    // GENERAL
    bytes4 internal constant EMPTY = 0x00000000;
    bytes4 internal constant CORE = 0xFFFFFFFF;

    // ADAPTERS
    bytes4 internal constant MANAGING = bytes4(keccak256("managing"));
    bytes4 internal constant ONBOARDING = bytes4(keccak256("onboarding"));
    bytes4 internal constant VOTING = bytes4(keccak256("voting"));
    bytes4 internal constant FINANCING = bytes4(keccak256("financing"));

    // EXTENSIONS
    bytes4 internal constant BANK = bytes4(keccak256("bank"));
    bytes4 internal constant AGORA = bytes4(keccak256("agora"));

    function concatWithSlot(bytes28 id, bytes4 slot) internal pure returns (bytes32) {
        return bytes32(bytes.concat(slot, id));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface ISlotEntry {
    function isExtension() external view returns (bool);

    function slotId() external view returns (bytes4);
}