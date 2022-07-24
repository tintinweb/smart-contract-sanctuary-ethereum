// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./lib/TimeHelpers.sol";

contract RosetteStone is TimeHelpers {
    error InvalidEntry(bytes32 scope, bytes4 sig, bytes cid);

    enum EntryStatus {
        Empty,
        Added
    }

    struct Entry {
        uint64 upsertAt; // Blocktime at which entry was upserted
        bytes cid; // IPFS CID of the file containing the entry data
        address submitter; // Address that upserted the entry
    }

    /**
     * A nested mapping of scope -> sig -> entry.
     */
    mapping(bytes32 => mapping(bytes4 => Entry)) private entries;

    // /////////////////////// MODIFIERS ////////////////////////////////////////////////////////////////////////

    modifier validEntry(
        bytes32 _scope,
        bytes4 _sig,
        bytes memory _cid
    ) {
        if (_scope == bytes32(0) || _sig == bytes4(0) || _cid.length == 0) {
            revert InvalidEntry(_scope, _sig, _cid);
        }
        _;
    }

    // ////////////////////////// EVENTS ///////////////////////////////////////////////////////////////////////

    /**
     * @dev Emitted when an entry is inserted or updated.
     * @param scope The contract's bytecode hash.
     * @param sig The signature of the method the entry is describing.
     * @param submitter The address that upserted the entry.
     * @param cid The IPFS CID of the file containing the Radspec description.
     */
    event EntryUpserted(
        bytes32 indexed scope,
        bytes4 indexed sig,
        address submitter,
        bytes cid
    );

    /**
     * @dev Emitted when an entry is removed.
     * @param scope The contract's bytecode hash.
     * @param sig The signature of the method the entry is describing.
     */
    event EntryRemoved(bytes32 indexed scope, bytes4 indexed sig);

    // /////////////////////// CONSTRUCTOR //////////////////////////////////////////////////////////////////////

    constructor() {}

    // ///////////////////// EXTERNAL ///////////////////////////////////////////////////////////////////////////

    /**
     * @dev Upsert a registry entry.
     * @param _scope The contract's bytecode hash.
     * @param _sig The signature of the method the entry is describing.
     * @param _cid The IPFS CID of the file containing the description.
     */
    function upsertEntry(
        bytes32 _scope,
        bytes4 _sig,
        bytes memory _cid
    ) public payable validEntry(_scope, _sig, _cid) {
        EntryStatus status = _entryStatus(_scope, _sig);
        if (status == EntryStatus.Added) {
            Entry storage entry_ = entries[_scope][_sig];
            require(
                entry_.submitter == msg.sender,
                "RosetteStone: not authorized address"
            );
        }

        _upsertEntry(_scope, _sig, _cid, msg.sender, getTimestamp64());
    }

    /**
     * @dev Upsert a list of entries.
     * @param _scopes The list of contract's bytecode hash.
     * @param _sigs The list of function signatures.
     * @param _cids The list of IPFS CIDs of the file containing the description.
     */
    function upsertEntries(
        bytes32[] memory _scopes,
        bytes4[] memory _sigs,
        bytes[] memory _cids
    ) external payable {
        for (uint256 i = 0; i < _scopes.length; i++) {
            upsertEntry(_scopes[i], _sigs[i], _cids[i]);
        }
    }

    /**
     * @dev Get an entry from the registry.
     * @param _scope The contract's bytecode hash.
     * @param _sig The signature of the method the entry is describing.
     * @return The CID, submitter, and status of the entry.
     */
    function getEntry(bytes32 _scope, bytes4 _sig)
        external
        view
        returns (
            bytes memory,
            address,
            EntryStatus
        )
    {
        Entry memory entry_ = entries[_scope][_sig];
        return (entry_.cid, entry_.submitter, _entryStatus(_scope, _sig));
    }

    /**
     * @dev Remove an entry from the registry.
     * @param _scope The contract's bytecode hash.
     * @param _sig The signature of the method the entry is describing.
     */
    function removeEntry(bytes32 _scope, bytes4 _sig) public {
        Entry memory entry_ = entries[_scope][_sig];
        require(
            entry_.submitter == msg.sender,
            "RosetteStone: not authorized address"
        );

        _removeEntry(_scope, _sig);
    }

    /**
     * @dev Remove a list of entries.
     * @param _scopes The list of contract's bytecode hash.
     * @param _sigs The list of function signatures.
     */
    function removeEntries(bytes32[] memory _scopes, bytes4[] memory _sigs)
        external
        payable
    {
        for (uint256 i = 0; i < _scopes.length; i++) {
            this.removeEntry(_scopes[i], _sigs[i]);
        }
    }

    // ///////////////////////// INTERNAL //////////////////////////////////////////////////////////////////////

    function _upsertEntry(
        bytes32 _scope,
        bytes4 _sig,
        bytes memory _cid,
        address _submitter,
        uint64 _upsertAt
    ) internal {
        Entry storage entry_ = entries[_scope][_sig];
        entry_.upsertAt = _upsertAt;
        entry_.cid = _cid;
        entry_.submitter = _submitter;

        emit EntryUpserted(_scope, _sig, _submitter, _cid);
    }

    function _removeEntry(bytes32 _scope, bytes4 _sig) internal {
        delete entries[_scope][_sig];
        emit EntryRemoved(_scope, _sig);
    }

    /**
     * @dev Get the current status of an entry.
     * @param _scope The contract's bytecode hash.
     * @param _sig The signature of the method the entry is describing.
     * @return The current EntryStatus
     */
    function _entryStatus(bytes32 _scope, bytes4 _sig)
        internal
        view
        returns (EntryStatus)
    {
        Entry memory entry_ = entries[_scope][_sig];
        if (entry_.submitter == address(0)) {
            return EntryStatus.Empty;
        }

        return EntryStatus.Added;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Uint256Helpers.sol";

contract TimeHelpers {
    using Uint256Helpers for uint256;

    /**
     * @dev Returns the current timestamp.
     *      Using a function rather than `block.timestamp` allows us to easily mock it in
     *      tests.
     */
    function getTimestamp() internal view returns (uint256) {
        return block.timestamp;
    }

    /**
     * @dev Returns the current timestamp, converted to uint64.
     *      Using a function rather than `block.timestamp` allows us to easily mock it in
     *      tests.
     */
    function getTimestamp64() internal view returns (uint64) {
        return getTimestamp().toUint64();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Uint256Helpers {
    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(
            value <= type(uint64).max,
            "SafeCast: value doesn't fit in 64 bits"
        );
        return uint64(value);
    }
}