// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.16;

import {IAuth} from "./IAuth.sol";

/**
 * @title Auth Module
 *
 * @dev The `Auth` contract module provides a basic access control mechanism,
 *      where a set of addresses are granted access to protected functions.
 *      These addresses are said to be _auth'ed_.
 *
 *      Initially, the deployer address is the only address auth'ed. Through
 *      the `rely(address)` and `deny(address)` functions, auth'ed callers are
 *      able to grant/renounce auth to/from addresses.
 *
 *      This module is used through inheritance. It will make available the
 *      modifier `auth`, which can be applied to functions to restrict their
 *      use to only auth'ed callers.
 */
abstract contract Auth is IAuth {
    /// @dev Mapping storing whether address is auth'ed.
    /// @custom:invariant Image of mapping is {0, 1}.
    ///                     ∀x ∊ Address: _wards[x] ∊ {0, 1}
    /// @custom:invariant Only deployer address authenticated after deployment.
    ///                     deployment → (∀x ∊ Address: _wards[x] == 1 → x == msg.sender)
    /// @custom:invariant Only functions `rely` and `deny` may mutate the mapping's state.
    ///                     ∀x ∊ Address: preTx(_wards[x]) != postTx(_wards[x])
    ///                                     → (msg.sig == "rely" ∨ msg.sig == "deny")
    /// @custom:invariant Mapping's state may only be mutated by authenticated caller.
    ///                     ∀x ∊ Address: preTx(_wards[x]) != postTx(_wards[x]) → _wards[msg.sender] = 1
    mapping(address => uint) private _wards;

    /// @dev List of addresses possibly being auth'ed.
    /// @dev May contain duplicates.
    /// @dev May contain addresses not being auth'ed anymore.
    /// @custom:invariant Every address being auth'ed once is element of the list.
    ///                     ∀x ∊ Address: authed(x) -> x ∊ _wardsTouched
    address[] private _wardsTouched;

    /// @dev Ensures caller is auth'ed.
    modifier auth() {
        /// @solidity memory-safe-assembly
        assembly {
            // Compute slot of _wards[msg.sender].
            mstore(0x00, caller())
            mstore(0x20, _wards.slot)
            let slot := keccak256(0x00, 0x40)

            // Revert if caller not auth'ed.
            let isAuthed := sload(slot)
            if iszero(isAuthed) {
                // Store selector of `NotAuthorized(address)`.
                mstore(0x00, 0x4a0bfec1)
                // Store msg.sender.
                mstore(0x20, caller())
                // Revert with (offset, size).
                revert(0x1c, 0x24)
            }
        }
        _;
    }

    constructor() {
        _wards[msg.sender] = 1;
        _wardsTouched.push(msg.sender);

        // Note to use address(0) as caller to keep invariant that no address
        // can grant itself auth.
        emit AuthGranted(address(0), msg.sender);
    }

    /// @inheritdoc IAuth
    function rely(address who) external override(IAuth) auth {
        if (_wards[who] == 1) return;

        _wards[who] = 1;
        _wardsTouched.push(who);
        emit AuthGranted(msg.sender, who);
    }

    /// @inheritdoc IAuth
    function deny(address who) external override(IAuth) auth {
        if (_wards[who] == 0) return;

        _wards[who] = 0;
        emit AuthRenounced(msg.sender, who);
    }

    /// @inheritdoc IAuth
    function authed(address who) public view override(IAuth) returns (bool) {
        return _wards[who] == 1;
    }

    /// @inheritdoc IAuth
    /// @custom:invariant Only contains auth'ed addresses.
    ///                     ∀x ∊ authed(): _wards[x] == 1
    /// @custom:invariant Contains all auth'ed addresses.
    ///                     ∀x ∊ Address: _wards[x] == 1 → x ∊ authed()
    function authed() public view override(IAuth) returns (address[] memory) {
        // Initiate array with upper limit length.
        address[] memory wardsList = new address[](_wardsTouched.length);

        // Iterate through all possible auth'ed addresses.
        uint ctr;
        for (uint i; i < wardsList.length; i++) {
            // Add address only if still auth'ed.
            if (_wards[_wardsTouched[i]] == 1) {
                wardsList[ctr++] = _wardsTouched[i];
            }
        }

        // Set length of array to number of auth'ed addresses actually included.
        /// @solidity memory-safe-assembly
        assembly {
            mstore(wardsList, ctr)
        }

        return wardsList;
    }

    /// @inheritdoc IAuth
    function wards(address who) public view override(IAuth) returns (uint) {
        return _wards[who];
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.16;

interface IAuth {
    /// @notice Thrown by protected function if caller not auth'ed.
    /// @param caller The caller's address.
    error NotAuthorized(address caller);

    /// @notice Emitted when auth granted to address.
    /// @param caller The caller's address.
    /// @param who The address auth got granted to.
    event AuthGranted(address indexed caller, address indexed who);

    /// @notice Emitted when auth renounced from address.
    /// @param caller The caller's address.
    /// @param who The address auth got renounced from.
    event AuthRenounced(address indexed caller, address indexed who);

    /// @notice Grants address `who` auth.
    /// @dev Only callable by auth'ed address.
    /// @param who The address to grant auth.
    function rely(address who) external;

    /// @notice Renounces address `who`'s auth.
    /// @dev Only callable by auth'ed address.
    /// @param who The address to renounce auth.
    function deny(address who) external;

    /// @notice Returns whether address `who` is auth'ed.
    /// @param who The address to check.
    /// @return True if `who` is auth'ed, false otherwise.
    function authed(address who) external view returns (bool);

    /// @notice Returns full list of addresses granted auth.
    /// @dev May contain duplicates.
    /// @return List of addresses granted auth.
    function authed() external view returns (address[] memory);

    /// @notice Returns whether address `who` is auth'ed.
    /// @custom:deprecated Use `authed(address)(bool)` instead.
    /// @param who The address to check.
    /// @return 1 if `who` is auth'ed, 0 otherwise.
    function wards(address who) external view returns (uint);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.16;

interface ITorAddressRegister {
    /// @notice Thrown if provided index out of bounds.
    /// @param index The provided index.
    /// @param maxIndex The maximum valid index.
    error IndexOutOfBounds(uint index, uint maxIndex);

    /// @notice Emitted when new tor address added.
    /// @param caller The caller's address.
    /// @param torAddress The tor addresses added.
    event TorAddressAdded(address indexed caller, string torAddress);

    /// @notice Emitted when tor address removed.
    /// @param caller The caller's address.
    /// @param torAddress The tor addresses removed..
    event TorAddressRemoved(address indexed caller, string torAddress);

    /// @notice Returns the tor address at index `index`.
    /// @dev Reverts if index out of bounds.
    /// @param index The index of the tor address to return.
    /// @return The tor address stored at given index.
    function get(uint index) external view returns (string memory);

    /// @notice Returns the tor address at index `index`.
    /// @param index The index of the tor address to return.
    /// @return True if tor address at index `index` exists, false otherwise.
    /// @return The tor address stored at index `index` if index exists, empty
    ///         string otherwise.
    function tryGet(uint index) external view returns (bool, string memory);

    /// @notice Returns the full list of tor addresses stored.
    /// @dev May contain duplicates.
    /// @dev Stable ordering not guaranteed.
    /// @dev May contain the empty string or other invalid tor addresses.
    /// @return The list of tor addresses stored.
    function list() external view returns (string[] memory);

    /// @notice Returns the number of tor addresses stored.
    /// @return The number of tor addresses stored.
    function count() external view returns (uint);

    /// @notice Adds a new tor address.
    /// @dev Only callable by auth'ed addresses.
    /// @param torAddress The tor address to add.
    function add(string calldata torAddress) external;

    /// @notice Adds a list of new tor addresses.
    /// @dev Only callable by auth'ed addresses.
    /// @param torAddresses The tor addresses to add.
    function add(string[] calldata torAddresses) external;

    /// @notice Removes the tor address at index `index`.
    /// @dev Only callable by auth'ed addresses.
    /// @dev Reverts if index `index` out of bounds.
    /// @param index The index of the the tor address to remove.
    function remove(uint index) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.16;

import {Auth} from "chronicle-std/auth/Auth.sol";

import {ITorAddressRegister} from "./ITorAddressRegister.sol";

/**
 * @title TorAddressRegister
 *
 * @notice The `TorAddressRegister` contract provides a register for tor
 *         addresses.
 *
 * @dev The contract uses the `chronicle-std/Auth` module for access control.
 *      While the register is publicly readable, state mutating functions are
 *      only callable by auth'ed addresses.
 *
 *      Note that the register does not guarantee stable ordering, may contain
 *      duplicates, and does not sanity-check newly added tor addresses.
 */
contract TorAddressRegister is ITorAddressRegister, Auth {
    /// @dev May contain duplicates.
    /// @dev Stable ordering not guaranteed.
    /// @dev May contain the empty string or other invalid tor addresses.
    string[] private _register;

    /// @inheritdoc ITorAddressRegister
    function get(uint index) external view returns (string memory) {
        if (index >= _register.length) {
            revert IndexOutOfBounds(index, _register.length);
        }

        return _register[index];
    }

    /// @inheritdoc ITorAddressRegister
    function tryGet(uint index) external view returns (bool, string memory) {
        if (index >= _register.length) {
            return (false, "");
        } else {
            return (true, _register[index]);
        }
    }

    /// @inheritdoc ITorAddressRegister
    function list() external view returns (string[] memory) {
        return _register;
    }

    /// @inheritdoc ITorAddressRegister
    function count() external view returns (uint) {
        return _register.length;
    }

    /// @inheritdoc ITorAddressRegister
    function add(string calldata torAddress) external auth {
        _register.push(torAddress);
        emit TorAddressAdded(msg.sender, torAddress);
    }

    /// @inheritdoc ITorAddressRegister
    function add(string[] calldata torAddresses) external auth {
        for (uint i; i < torAddresses.length; i++) {
            _register.push(torAddresses[i]);
            emit TorAddressAdded(msg.sender, torAddresses[i]);
        }
    }

    /// @inheritdoc ITorAddressRegister
    /// @dev Note to not provide a "bulk remove" function as the ordering of tor
    ///      addresses inside the register may change during removal.
    function remove(uint index) external auth {
        if (index >= _register.length) {
            revert IndexOutOfBounds(index, _register.length);
        }

        emit TorAddressRemoved(msg.sender, _register[index]);
        _register[index] = _register[_register.length - 1];
        _register.pop();
    }
}