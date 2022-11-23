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

import "openzeppelin-contracts/utils/Counters.sol";

import "./SlotEntry.sol";
import "../interfaces/IAdapter.sol";
import "../interfaces/IDaoCore.sol";
import "../helpers/Constants.sol";

/**
 * @notice abstract contract for Adapters, add guard modifier
 * to restrict access for only DAO members or contracts
 */
abstract contract Adapter is SlotEntry, IAdapter, Constants {
    constructor(address core, bytes4 slot) SlotEntry(core, slot, false) {}

    /* //////////////////////////
            MODIFIER
    ////////////////////////// */
    modifier onlyCore() {
        require(msg.sender == _core, "Adapter: not the core");
        _;
    }

    modifier onlyExtension(bytes4 slot) {
        IDaoCore core = IDaoCore(_core);
        require(
            core.isSlotExtension(slot) && core.getSlotContractAddr(slot) == msg.sender,
            "Adapter: wrong extension"
        );
        _;
    }

    /// NOTE consider using `hasRole(bytes4)` for future role in the DAO => AccessControl.sol
    modifier onlyMember() {
        require(IDaoCore(_core).hasRole(msg.sender, ROLE_MEMBER), "Adapter: not a member");
        _;
    }

    modifier onlyProposer() {
        require(IDaoCore(_core).hasRole(msg.sender, ROLE_PROPOSER), "Adapter: not a proposer");
        _;
    }

    modifier onlyAdmin() {
        require(IDaoCore(_core).hasRole(msg.sender, ROLE_ADMIN), "Adapter: not an admin");
        _;
    }

    /* //////////////////////////
            FUNCTIONS
    ////////////////////////// */
    /**
     * @notice delete storage and destruct the contract,
     * calls can still happen and ethers sended there are lost
     * for ever.
     *
     * @dev only callable when the contract is unplugged from DaoCore
     *
     * NOTE this operation is quite useless as the contract as not state
     */
    function eraseAdapter() public virtual override onlyExtension(Slot.AGORA) {
        require(
            IDaoCore(_core).getSlotContractAddr(slotId) != address(this),
            "Adapter: unplug from DaoCore"
        );
        selfdestruct(payable(_core));
    }

    /**
     * @notice internal getter
     * @return actual contract address associated with `slot`, return
     * address(0) if there is no contract address
     */
    function _slotAddress(bytes4 slot) internal view returns (address) {
        return IDaoCore(_core).getSlotContractAddr(slot);
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

import "../abstracts/Adapter.sol";

/**
 * @notice simpliest implementation of the Onboarding process
 */
contract Onboarding is Adapter {
    constructor(address core) Adapter(core, Slot.ONBOARDING) {}

    /**
     * @notice any address can become a member in the DAO
     */
    function joinDao() external {
        IDaoCore(_core).changeMemberStatus(msg.sender, ROLE_MEMBER, true);
    }

    /**
     * @notice any address can quit the DAO
     * tokens deposited in the DAO are not refunded
     */
    function quitDao() external {
        IDaoCore(_core).changeMemberStatus(msg.sender, ROLE_MEMBER, false);
    }

    /**
     * @notice any admin can add or remove an admin in the DAO
     * An admin can self-remove the role, and thus block the DAO
     */
    function setAdminMember(address account, bool isAdmin) external onlyAdmin {
        if (isAdmin) {
            IDaoCore(_core).addNewAdmin(account);
        } else {
            IDaoCore(_core).changeMemberStatus(account, ROLE_ADMIN, false);
        }
    }
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

interface IAdapter {
    function eraseAdapter() external;
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

interface ISlotEntry {
    function isExtension() external view returns (bool);

    function slotId() external view returns (bytes4);
}