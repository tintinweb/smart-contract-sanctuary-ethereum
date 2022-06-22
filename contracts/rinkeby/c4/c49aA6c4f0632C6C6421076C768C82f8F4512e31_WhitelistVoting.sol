// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "@openzeppelin/contracts/utils/Checkpoints.sol";
import "./../majority/MajorityVoting.sol";

/// @title A component for whitelist voting
/// @author Aragon Association - 2021-2022
/// @notice The majority voting implementation using an ERC-20 token
/// @dev This contract inherits from `MajorityVoting` and implements the `IMajorityVoting` interface
contract WhitelistVoting is MajorityVoting {
    using Checkpoints for Checkpoints.History;

    bytes4 internal constant WHITELIST_VOTING_INTERFACE_ID =
        MAJORITY_VOTING_INTERFACE_ID ^
            this.addWhitelistedUsers.selector ^
            this.removeWhitelistedUsers.selector ^
            this.isUserWhitelisted.selector ^
            this.whitelistedUserCount.selector;

    bytes32 public constant MODIFY_WHITELIST = keccak256("MODIFY_WHITELIST");

    mapping(address => Checkpoints.History) private _checkpoints;
    Checkpoints.History private _totalCheckpoints;

    error VoteCreationForbidden(address sender);

    event AddUsers(address[] users);
    event RemoveUsers(address[] users);

    /// @notice Initializes the component
    /// @dev This is required for the UUPS upgradability pattern
    /// @param _dao The IDAO interface of the associated DAO
    /// @param _gsnForwarder The address of the trusted GSN forwarder required for meta transactions
    /// @param _participationRequiredPct The minimal required participation in percent.
    /// @param _supportRequiredPct The minimal required support in percent.
    /// @param _minDuration The minimal duration of a vote
    /// @param _whitelisted The whitelisted addresses
    function initialize(
        IDAO _dao,
        address _gsnForwarder,
        uint64 _participationRequiredPct,
        uint64 _supportRequiredPct,
        uint64 _minDuration,
        address[] calldata _whitelisted
    ) public initializer {
        _registerStandard(WHITELIST_VOTING_INTERFACE_ID);
        __MajorityVoting_init(
            _dao,
            _gsnForwarder,
            _participationRequiredPct,
            _supportRequiredPct,
            _minDuration
        );

        // add whitelisted users
        _addWhitelistedUsers(_whitelisted);
    }

    /// @notice Returns the version of the GSN relay recipient
    /// @dev Describes the version and contract for GSN compatibility
    function versionRecipient() external view virtual override returns (string memory) {
        return "0.0.1+opengsn.recipient.WhitelistVoting";
    }

    /// @notice add new users to the whitelist.
    /// @param _users addresses of users to add
    function addWhitelistedUsers(address[] calldata _users) external auth(MODIFY_WHITELIST) {
        _addWhitelistedUsers(_users);
    }

    /// @dev Internal function to add new users to the whitelist.
    /// @param _users addresses of users to add
    function _addWhitelistedUsers(address[] calldata _users) internal {
        _whitelistUsers(_users, true);

        emit AddUsers(_users);
    }

    /// @notice remove new users to the whitelist.
    /// @param _users addresses of users to remove
    function removeWhitelistedUsers(address[] calldata _users) external auth(MODIFY_WHITELIST) {
        _whitelistUsers(_users, false);

        emit RemoveUsers(_users);
    }

    /// @notice Create a new vote on this concrete implementation
    /// @param _proposalMetadata The IPFS hash pointing to the proposal metadata
    /// @param _actions the actions that will be executed after vote passes
    /// @param _startDate state date of the vote. If 0, uses current timestamp
    /// @param _endDate end date of the vote. If 0, uses _start + minDuration
    /// @param _executeIfDecided Configuration to enable automatic execution on the last required vote
    /// @param _choice Vote choice to cast on creationr
    function newVote(
        bytes calldata _proposalMetadata,
        IDAO.Action[] calldata _actions,
        uint64 _startDate,
        uint64 _endDate,
        bool _executeIfDecided,
        VoterState _choice
    ) external override returns (uint256 voteId) {
        uint64 snapshotBlock = getBlockNumber64() - 1;

        if (!isUserWhitelisted(_msgSender(), snapshotBlock)) {
            revert VoteCreationForbidden(_msgSender());
        }

        // calculate start and end time for the vote
        uint64 currentTimestamp = getTimestamp64();

        if (_startDate == 0) _startDate = currentTimestamp;
        if (_endDate == 0) _endDate = _startDate + minDuration;

        if (_endDate - _startDate < minDuration || _startDate < currentTimestamp)
            revert VoteTimesForbidden({
                current: currentTimestamp,
                start: _startDate,
                end: _endDate,
                minDuration: minDuration
            });

        voteId = votesLength++;

        // create a vote.
        Vote storage vote_ = votes[voteId];
        vote_.startDate = _startDate;
        vote_.endDate = _endDate;
        vote_.snapshotBlock = snapshotBlock;
        vote_.supportRequiredPct = supportRequiredPct;
        vote_.participationRequiredPct = participationRequiredPct;
        vote_.votingPower = whitelistedUserCount(snapshotBlock);

        unchecked {
            for (uint256 i = 0; i < _actions.length; i++) {
                vote_.actions.push(_actions[i]);
            }
        }

        emit StartVote(voteId, _msgSender(), _proposalMetadata);

        if (_choice != VoterState.None && canVote(voteId, _msgSender())) {
            _vote(voteId, VoterState.Yea, _msgSender(), _executeIfDecided);
        }
    }

    /// @dev Internal function to cast a vote. It assumes the queried vote exists.
    /// @param _voteId voteId
    /// @param _choice Whether voter abstains, supports or not supports to vote.
    /// @param _executesIfDecided if true, and it's the last vote required, immediatelly executes a vote.
    function _vote(
        uint256 _voteId,
        VoterState _choice,
        address _voter,
        bool _executesIfDecided
    ) internal override {
        Vote storage vote_ = votes[_voteId];

        VoterState state = vote_.voters[_voter];

        // If voter had previously voted, decrease count
        if (state == VoterState.Yea) {
            vote_.yea = vote_.yea - 1;
        } else if (state == VoterState.Nay) {
            vote_.nay = vote_.nay - 1;
        } else if (state == VoterState.Abstain) {
            vote_.abstain = vote_.abstain - 1;
        }

        // write the updated/new vote for the voter.
        if (_choice == VoterState.Yea) {
            vote_.yea = vote_.yea + 1;
        } else if (_choice == VoterState.Nay) {
            vote_.nay = vote_.nay + 1;
        } else if (_choice == VoterState.Abstain) {
            vote_.abstain = vote_.abstain + 1;
        }

        vote_.voters[_voter] = _choice;

        emit CastVote(_voteId, _voter, uint8(_choice), 1);

        if (_executesIfDecided && _canExecute(_voteId)) {
            _execute(_voteId);
        }
    }

    /**
     *  @dev Tells whether user is whitelisted at specific block or past it.
     *  @param account user address
     *  @param blockNumber block number for which it checks if user is whitelisted
     */
    function isUserWhitelisted(address account, uint256 blockNumber) public view returns (bool) {
        if (blockNumber == 0) blockNumber = getBlockNumber64() - 1;

        return _checkpoints[account].getAtBlock(blockNumber) == 1;
    }

    /**
     *  @dev returns total count of users that are whitelisted at specific block
     *  @param blockNumber specific block to get count from
     *  @return count of users that are whitelisted blockNumber or prior to it.
     */
    function whitelistedUserCount(uint256 blockNumber) public view returns (uint256) {
        if (blockNumber == 0) blockNumber = getBlockNumber64() - 1;

        return _totalCheckpoints.getAtBlock(blockNumber);
    }

    /**
     * @dev Internal function to check if a voter can participate on a vote. It assumes the queried vote exists.
     * @param _voteId The voteId
     * @param _voter the address of the voter to check
     * @return True if the given voter can participate a certain vote, false otherwise
     */
    function _canVote(uint256 _voteId, address _voter) internal view override returns (bool) {
        Vote storage vote_ = votes[_voteId];
        return _isVoteOpen(vote_) && isUserWhitelisted(_voter, vote_.snapshotBlock);
    }

    /**
     *  @dev Adds or removes users from whitelist
     *  @param _users user addresses
     *  @param _enabled whether to add or remove from whitelist
     */
    function _whitelistUsers(address[] calldata _users, bool _enabled) internal {
        _totalCheckpoints.push(_enabled ? _add : _sub, _users.length);

        for (uint256 i = 0; i < _users.length; i++) {
            _checkpoints[_users[i]].push(_enabled ? 1 : 0);
        }
    }

    function _add(uint256 a, uint256 b) private pure returns (uint256) {
        unchecked {
            return a + b;
        }
    }

    function _sub(uint256 a, uint256 b) private pure returns (uint256) {
        unchecked {
            return a - b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Checkpoints.sol)
pragma solidity ^0.8.0;

import "./math/Math.sol";
import "./math/SafeCast.sol";

/**
 * @dev This library defines the `History` struct, for checkpointing values as they change at different points in
 * time, and later looking up past values by block number. See {Votes} as an example.
 *
 * To create a history of checkpoints define a variable type `Checkpoints.History` in your contract, and store a new
 * checkpoint for the current transaction block using the {push} function.
 *
 * _Available since v4.5._
 */
library Checkpoints {
    struct Checkpoint {
        uint32 _blockNumber;
        uint224 _value;
    }

    struct History {
        Checkpoint[] _checkpoints;
    }

    /**
     * @dev Returns the value in the latest checkpoint, or zero if there are no checkpoints.
     */
    function latest(History storage self) internal view returns (uint256) {
        uint256 pos = self._checkpoints.length;
        return pos == 0 ? 0 : self._checkpoints[pos - 1]._value;
    }

    /**
     * @dev Returns the value at a given block number. If a checkpoint is not available at that block, the closest one
     * before it is returned, or zero otherwise.
     */
    function getAtBlock(History storage self, uint256 blockNumber) internal view returns (uint256) {
        require(blockNumber < block.number, "Checkpoints: block not yet mined");

        uint256 high = self._checkpoints.length;
        uint256 low = 0;
        while (low < high) {
            uint256 mid = Math.average(low, high);
            if (self._checkpoints[mid]._blockNumber > blockNumber) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }
        return high == 0 ? 0 : self._checkpoints[high - 1]._value;
    }

    /**
     * @dev Pushes a value onto a History so that it is stored as the checkpoint for the current block.
     *
     * Returns previous value and new value.
     */
    function push(History storage self, uint256 value) internal returns (uint256, uint256) {
        uint256 pos = self._checkpoints.length;
        uint256 old = latest(self);
        if (pos > 0 && self._checkpoints[pos - 1]._blockNumber == block.number) {
            self._checkpoints[pos - 1]._value = SafeCast.toUint224(value);
        } else {
            self._checkpoints.push(
                Checkpoint({_blockNumber: SafeCast.toUint32(block.number), _value: SafeCast.toUint224(value)})
            );
        }
        return (old, value);
    }

    /**
     * @dev Pushes a value onto a History, by updating the latest value using binary operation `op`. The new value will
     * be set to `op(latest, delta)`.
     *
     * Returns previous value and new value.
     */
    function push(
        History storage self,
        function(uint256, uint256) view returns (uint256) op,
        uint256 delta
    ) internal returns (uint256, uint256) {
        return push(self, op(latest(self), delta));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "./IMajorityVoting.sol";
import "./../../core/component/MetaTxComponent.sol";
import "./../../utils/TimeHelpers.sol";

/// @title The abstract implementation of majority voting components
/// @author Aragon Association - 2022
/// @notice The abstract implementation of majority voting components
/// @dev This component implements the `IMajorityVoting` interface
abstract contract MajorityVoting is IMajorityVoting, MetaTxComponent, TimeHelpers {
    bytes4 internal constant MAJORITY_VOTING_INTERFACE_ID = type(IMajorityVoting).interfaceId;
    bytes32 public constant MODIFY_VOTE_CONFIG = keccak256("MODIFY_VOTE_CONFIG");

    uint64 public constant PCT_BASE = 10**18; // 0% = 0; 1% = 10^16; 100% = 10^18

    mapping(uint256 => Vote) internal votes;

    uint64 public supportRequiredPct;
    uint64 public participationRequiredPct;
    uint64 public minDuration;
    uint256 public votesLength;

    /// @notice Initializes the component
    /// @dev This is required for the UUPS upgradability pattern
    /// @param _dao The IDAO interface of the associated DAO
    /// @param _gsnForwarder The address of the trusted GSN forwarder required for meta transactions
    /// @param _participationRequiredPct The minimal required participation in percent.
    /// @param _supportRequiredPct The minimal required support in percent.
    /// @param _minDuration The minimal duration of a vote
    function __MajorityVoting_init(
        IDAO _dao,
        address _gsnForwarder,
        uint64 _participationRequiredPct,
        uint64 _supportRequiredPct,
        uint64 _minDuration
    ) internal onlyInitializing {
        _registerStandard(MAJORITY_VOTING_INTERFACE_ID);
        _validateAndSetSettings(_participationRequiredPct, _supportRequiredPct, _minDuration);

        __MetaTxComponent_init(_dao, _gsnForwarder);

        emit UpdateConfig(_participationRequiredPct, _supportRequiredPct, _minDuration);
    }

    /// @inheritdoc IMajorityVoting
    function changeVoteConfig(
        uint64 _participationRequiredPct,
        uint64 _supportRequiredPct,
        uint64 _minDuration
    ) external auth(MODIFY_VOTE_CONFIG) {
        _validateAndSetSettings(_participationRequiredPct, _supportRequiredPct, _minDuration);

        emit UpdateConfig(_participationRequiredPct, _supportRequiredPct, _minDuration);
    }

    /// @inheritdoc IMajorityVoting
    function newVote(
        bytes calldata _proposalMetadata,
        IDAO.Action[] calldata _actions,
        uint64 _startDate,
        uint64 _endDate,
        bool _executeIfDecided,
        VoterState _choice
    ) external virtual returns (uint256 voteId);

    /// @inheritdoc IMajorityVoting
    function vote(
        uint256 _voteId,
        VoterState _choice,
        bool _executesIfDecided
    ) external {
        if (_choice != VoterState.None && !_canVote(_voteId, _msgSender()))
            revert VoteCastForbidden(_voteId, _msgSender());
        _vote(_voteId, _choice, _msgSender(), _executesIfDecided);
    }

    /// @inheritdoc IMajorityVoting
    function execute(uint256 _voteId) public {
        if (!_canExecute(_voteId)) revert VoteExecutionForbidden(_voteId);
        _execute(_voteId);
    }

    /// @inheritdoc IMajorityVoting
    function getVoterState(uint256 _voteId, address _voter) public view returns (VoterState) {
        return votes[_voteId].voters[_voter];
    }

    /// @inheritdoc IMajorityVoting
    function canVote(uint256 _voteId, address _voter) public view returns (bool) {
        return _canVote(_voteId, _voter);
    }

    /// @inheritdoc IMajorityVoting
    function canExecute(uint256 _voteId) public view returns (bool) {
        return _canExecute(_voteId);
    }

    /// @inheritdoc IMajorityVoting
    function getVote(uint256 _voteId)
        public
        view
        returns (
            bool open,
            bool executed,
            uint64 startDate,
            uint64 endDate,
            uint64 snapshotBlock,
            uint64 supportRequired,
            uint64 participationRequired,
            uint256 votingPower,
            uint256 yea,
            uint256 nay,
            uint256 abstain,
            IDAO.Action[] memory actions
        )
    {
        Vote storage vote_ = votes[_voteId];

        open = _isVoteOpen(vote_);
        executed = vote_.executed;
        startDate = vote_.startDate;
        endDate = vote_.endDate;
        snapshotBlock = vote_.snapshotBlock;
        supportRequired = vote_.supportRequiredPct;
        participationRequired = vote_.participationRequiredPct;
        votingPower = vote_.votingPower;
        yea = vote_.yea;
        nay = vote_.nay;
        abstain = vote_.abstain;
        actions = vote_.actions;
    }

    /// @dev Internal function to cast a vote. It assumes the queried vote exists.
    /// @param _voteId voteId
    /// @param _choice Whether voter abstains, supports or not supports to vote.
    /// @param _executesIfDecided if true, and it's the last vote required, immediatelly executes a vote.
    function _vote(
        uint256 _voteId,
        VoterState _choice,
        address _voter,
        bool _executesIfDecided
    ) internal virtual;

    /// @dev Internal function to execute a vote. It assumes the queried vote exists.
    /// @param _voteId the vote Id
    function _execute(uint256 _voteId) internal virtual {
        bytes[] memory execResults = dao.execute(_voteId, votes[_voteId].actions);

        votes[_voteId].executed = true;

        emit ExecuteVote(_voteId, execResults);
    }

    /// @dev Internal function to check if a voter can participate on a vote. It assumes the queried vote exists.
    /// @param _voteId The voteId
    /// @param _voter the address of the voter to check
    /// @return True if the given voter can participate a certain vote, false otherwise
    function _canVote(uint256 _voteId, address _voter) internal view virtual returns (bool);

    /// @dev Internal function to check if a vote can be executed. It assumes the queried vote exists.
    /// @param _voteId vote id
    /// @return True if the given vote can be executed, false otherwise
    function _canExecute(uint256 _voteId) internal view virtual returns (bool) {
        Vote storage vote_ = votes[_voteId];

        if (vote_.executed) {
            return false;
        }

        // Voting is already decided
        if (_isValuePct(vote_.yea, vote_.votingPower, vote_.supportRequiredPct)) {
            return true;
        }

        // Vote ended?
        if (_isVoteOpen(vote_)) {
            return false;
        }

        uint256 totalVotes = vote_.yea + vote_.nay;

        // Have enough people's stakes participated ? then proceed.
        if (
            !_isValuePct(
                totalVotes + vote_.abstain,
                vote_.votingPower,
                vote_.participationRequiredPct
            )
        ) {
            return false;
        }

        // Has enough support?
        if (!_isValuePct(vote_.yea, totalVotes, vote_.supportRequiredPct)) {
            return false;
        }

        return true;
    }

    /// @dev Internal function to check if a vote is still open
    /// @param vote_ the vote struct
    /// @return True if the given vote is open, false otherwise
    function _isVoteOpen(Vote storage vote_) internal view virtual returns (bool) {
        return
            getTimestamp64() < vote_.endDate &&
            getTimestamp64() >= vote_.startDate &&
            !vote_.executed;
    }

    /// @dev Calculates whether `_value` is more than a percentage `_pct` of `_total`
    /// @param _value the current value
    /// @param _total the total value
    /// @param _pct the required support percentage
    /// @return returns if the _value is _pct or more percentage of _total.
    function _isValuePct(
        uint256 _value,
        uint256 _total,
        uint256 _pct
    ) internal pure returns (bool) {
        if (_total == 0) {
            return false;
        }

        uint256 computedPct = (_value * PCT_BASE) / _total;
        return computedPct > _pct;
    }

    function _validateAndSetSettings(
        uint64 _participationRequiredPct,
        uint64 _supportRequiredPct,
        uint64 _minDuration
    ) internal virtual {
        if (_supportRequiredPct > PCT_BASE) {
            revert VoteSupportExceeded({limit: PCT_BASE, actual: _supportRequiredPct});
        }

        if (_participationRequiredPct > PCT_BASE) {
            revert VoteParticipationExceeded({limit: PCT_BASE, actual: _participationRequiredPct});
        }

        if (_minDuration == 0) {
            revert VoteDurationZero();
        }

        participationRequiredPct = _participationRequiredPct;
        supportRequiredPct = _supportRequiredPct;
        minDuration = _minDuration;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeCast.sol)

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

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
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "./../../core/IDAO.sol";

/// @title The interface for majority voting contracts
/// @author Aragon Association - 2022
/// @notice The interface for majority voting contracts
interface IMajorityVoting {
    enum VoterState {
        None,
        Abstain,
        Yea,
        Nay
    }

    struct Vote {
        bool executed;
        uint64 startDate;
        uint64 endDate;
        uint64 snapshotBlock;
        uint64 supportRequiredPct;
        uint64 participationRequiredPct;
        uint256 yea;
        uint256 nay;
        uint256 abstain;
        uint256 votingPower;
        mapping(address => VoterState) voters;
        IDAO.Action[] actions;
    }

    error VoteSupportExceeded(uint64 limit, uint64 actual);
    error VoteParticipationExceeded(uint64 limit, uint64 actual);
    error VoteTimesForbidden(uint64 current, uint64 start, uint64 end, uint64 minDuration);
    error VoteDurationZero();
    error VoteCastForbidden(uint256 voteId, address sender);
    error VoteExecutionForbidden(uint256 voteId);
    error VotePowerZero();

    event StartVote(uint256 indexed voteId, address indexed creator, bytes metadata);
    event CastVote(
        uint256 indexed voteId,
        address indexed voter,
        uint8 voterState,
        uint256 voterWeight
    );
    event ExecuteVote(uint256 indexed voteId, bytes[] execResults);
    event UpdateConfig(
        uint64 participationRequiredPct,
        uint64 supportRequiredPct,
        uint64 minDuration
    );

    /// @notice Change required support and minQuorum
    /// @param _supportRequiredPct New required support
    /// @param _participationRequiredPct New acceptance quorum
    /// @param _minDuration each vote's minimum duration
    function changeVoteConfig(
        uint64 _participationRequiredPct,
        uint64 _supportRequiredPct,
        uint64 _minDuration
    ) external;

    /// @notice Create a new vote on this concrete implementation
    /// @param _proposalMetadata The IPFS hash pointing to the proposal metadata
    /// @param _actions the actions that will be executed after vote passes
    /// @param _startDate state date of the vote. If 0, uses current timestamp
    /// @param _endDate end date of the vote. If 0, uses _start + minDuration
    /// @param _executeIfDecided Configuration to enable automatic execution on the last required vote
    /// @param _choice Vote choice to cast on creation
    /// @return voteId The ID of the vote
    function newVote(
        bytes calldata _proposalMetadata,
        IDAO.Action[] calldata _actions,
        uint64 _startDate,
        uint64 _endDate,
        bool _executeIfDecided,
        VoterState _choice
    ) external returns (uint256 voteId);

    /// @notice Vote `[outcome = 1 = abstain], [outcome = 2 = supports], [outcome = 1 = not supports]
    /// @param _voteId Id for vote
    /// @param  _choice Whether voter abstains, supports or not supports to vote.
    /// @param _executesIfDecided Whether the vote should execute its action if it becomes decided
    function vote(
        uint256 _voteId,
        VoterState _choice,
        bool _executesIfDecided
    ) external;

    /// @dev Internal function to check if a voter can participate on a vote. It assumes the queried vote exists.
    /// @param _voteId the vote Id
    /// @param _voter the address of the voter to check
    /// @return bool true if user is allowed to vote
    function canVote(uint256 _voteId, address _voter) external view returns (bool);

    /// @dev Method to execute a vote if allowed to
    /// @param _voteId The ID of the vote to execute
    function execute(uint256 _voteId) external;

    /// @dev Method to execute a vote if allowed to
    /// @param _voteId The ID of the vote to execute
    function canExecute(uint256 _voteId) external view returns (bool);

    /// @dev Return the state of a voter for a given vote by its ID
    /// @param _voteId The ID of the vote
    /// @return VoterState of the requested voter for a certain vote
    function getVoterState(uint256 _voteId, address _voter) external view returns (VoterState);

    /// @dev Return all information for a vote by its ID
    /// @param _voteId Vote id
    /// @return open Vote open status
    /// @return executed Vote executed status
    /// @return startDate start date
    /// @return endDate end date
    /// @return snapshotBlock The block number of the snapshot taken for this vote
    /// @return supportRequired support required
    /// @return participationRequired minimum participation required
    /// @return votingPower power
    /// @return yea yeas amount
    /// @return nay nays amount
    /// @return abstain abstain amount
    /// @return actions Actions
    function getVote(uint256 _voteId)
        external
        view
        returns (
            bool open,
            bool executed,
            uint64 startDate,
            uint64 endDate,
            uint64 snapshotBlock,
            uint64 supportRequired,
            uint64 participationRequired,
            uint256 votingPower,
            uint256 yea,
            uint256 nay,
            uint256 abstain,
            IDAO.Action[] memory actions
        );
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "@opengsn/contracts/src/BaseRelayRecipient.sol";

import "./Component.sol";

/// @title Base component in the Aragon DAO framework supporting meta transactions
/// @author Aragon Association - 2022
/// @notice Any component within the Aragon DAO framework using meta transactions has to inherit from this contract
abstract contract MetaTxComponent is Component, BaseRelayRecipient {
    bytes32 public constant MODIFY_TRUSTED_FORWARDER = keccak256("MODIFY_TRUSTED_FORWARDER");

    event TrustedForwarderSet(address forwarder);

    /// @notice Initialization
    /// @param _dao the associated DAO address
    /// @param _trustedForwarder the trusted forwarder address who verifies the meta transaction
    function __MetaTxComponent_init(IDAO _dao, address _trustedForwarder)
        internal
        virtual
        onlyInitializing
    {
        __Component_init(_dao);

        _registerStandard(type(MetaTxComponent).interfaceId);

        _setTrustedForwarder(_trustedForwarder);
        emit TrustedForwarderSet(_trustedForwarder);
    }

    /// @notice overrides '_msgSender()' from 'Component'->'ContextUpgradeable' with that of 'BaseRelayRecipient'
    function _msgSender()
        internal
        view
        override(ContextUpgradeable, BaseRelayRecipient)
        returns (address)
    {
        return BaseRelayRecipient._msgSender();
    }

    /// @notice overrides '_msgData()' from 'Component'->'ContextUpgradeable' with that of 'BaseRelayRecipient'
    function _msgData()
        internal
        view
        override(ContextUpgradeable, BaseRelayRecipient)
        returns (bytes calldata)
    {
        return BaseRelayRecipient._msgData();
    }

    /// @notice Setter for the trusted forwarder verifying the meta transaction
    /// @param _trustedForwarder the trusted forwarder address
    /// @dev used to update the trusted forwarder
    function setTrustedForwarder(address _trustedForwarder)
        public
        virtual
        auth(MODIFY_TRUSTED_FORWARDER)
    {
        _setTrustedForwarder(_trustedForwarder);

        emit TrustedForwarderSet(_trustedForwarder);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "./Uint256Helpers.sol";

contract TimeHelpers {
    using Uint256Helpers for uint256;

    /// @dev Returns the current block number.
    ///      Using a function rather than `block.number` allows us to easily mock the block number in
    ///      tests.
    function getBlockNumber() internal view virtual returns (uint256) {
        return block.number;
    }

    /// @dev Returns the current block number, converted to uint64.
    ///      Using a function rather than `block.number` allows us to easily mock the block number in
    ///      tests.
    function getBlockNumber64() internal view virtual returns (uint64) {
        return getBlockNumber().toUint64();
    }

    /// @dev Returns the current timestamp.
    ///      Using a function rather than `block.timestamp` allows us to easily mock it in
    ///      tests.
    function getTimestamp() internal view virtual returns (uint256) {
        return block.timestamp; // solium-disable-line security/no-block-members
    }

    /// @dev Returns the current timestamp, converted to uint64.
    ///      Using a function rather than `block.timestamp` allows us to easily mock it in
    ///      tests.
    function getTimestamp64() internal view virtual returns (uint64) {
        return getTimestamp().toUint64();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

/// @title The interface required to have a DAO contract within the Aragon DAO framework
/// @author Aragon Association - 2022
abstract contract IDAO {
    bytes4 internal constant DAO_INTERFACE_ID = type(IDAO).interfaceId;

    struct Action {
        address to; // Address to call.
        uint256 value; // Value to be sent with the call. for example (ETH)
        bytes data; // FuncSig + arguments
    }

    /// @dev Required to handle the permissions within the whole DAO framework accordingly
    /// @param _where The address of the contract
    /// @param _who The address of a EOA or contract to give the permissions
    /// @param _role The hash of the role identifier
    /// @param _data The optional data passed to the ACLOracle registered.
    /// @return bool
    function hasPermission(
        address _where,
        address _who,
        bytes32 _role,
        bytes memory _data
    ) external virtual returns (bool);

    /// @notice Update the DAO metadata
    /// @dev Sets a new IPFS hash
    /// @param _metadata The IPFS hash of the new metadata object
    function setMetadata(bytes calldata _metadata) external virtual;

    event MetadataSet(bytes metadata);

    /// @notice If called, the list of provided actions will be executed.
    /// @dev It run a loop through the array of acctions and execute one by one.
    /// @dev If one acction fails, all will be reverted.
    /// @param _actions The aray of actions
    function execute(uint256 callId, Action[] memory _actions)
        external
        virtual
        returns (bytes[] memory);

    event Executed(address indexed actor, uint256 callId, Action[] actions, bytes[] execResults);

    /// @notice Deposit ETH or any token to this contract with a reference string
    /// @dev Deposit ETH (token address == 0) or any token with a reference
    /// @param _token The address of the token and in case of ETH address(0)
    /// @param _amount The amount of tokens to deposit
    /// @param _reference The deposit reference describing the reason of it
    function deposit(
        address _token,
        uint256 _amount,
        string calldata _reference
    ) external payable virtual;

    event Deposited(
        address indexed sender,
        address indexed token,
        uint256 amount,
        string _reference
    );
    // ETHDeposited and Deposited are both needed. ETHDeposited makes sure that whoever sends funds
    // with `send/transfer`, receive function can still be executed without reverting due to gas cost
    // increases in EIP-2929. To still use `send/transfer`, access list is needed that has the address
    // of the contract(base contract) that is behind the proxy.
    event ETHDeposited(address sender, uint256 amount);

    /// @notice Withdraw tokens or ETH from the DAO with a withdraw reference string
    /// @param _token The address of the token and in case of ETH address(0)
    /// @param _to The target address to send tokens or ETH
    /// @param _amount The amount of tokens to deposit
    /// @param _reference The deposit reference describing the reason of it
    function withdraw(
        address _token,
        address _to,
        uint256 _amount,
        string memory _reference
    ) external virtual;

    event Withdrawn(address indexed token, address indexed to, uint256 amount, string _reference);

    /// @notice Setter for the trusted forwarder verifying the meta transaction
    /// @param _trustedForwarder the trusted forwarder address
    /// @dev used to update the trusted forwarder
    function setTrustedForwarder(address _trustedForwarder) external virtual;

    /// @notice Setter for the trusted forwarder verifying the meta transaction
    /// @return the trusted forwarder address
    function trustedForwarder() external virtual returns (address);

    event TrustedForwarderSet(address forwarder);

    /// @notice Setter to set the signature validator contract of ERC1271
    /// @param _signatureValidator ERC1271 SignatureValidator
    function setSignatureValidator(address _signatureValidator) external virtual;

    /// @notice Method to validate the signature as described in ERC1271
    /// @param _hash Hash of the data to be signed
    /// @param _signature Signature byte array associated with _hash
    /// @return bytes4
    function isValidSignature(bytes32 _hash, bytes memory _signature)
        external
        virtual
        returns (bytes4);
}

// SPDX-License-Identifier: MIT
// solhint-disable no-inline-assembly
pragma solidity >=0.6.9;

import "./interfaces/IRelayRecipient.sol";

/**
 * A base contract to be inherited by any contract that want to receive relayed transactions
 * A subclass must use "_msgSender()" instead of "msg.sender"
 */
abstract contract BaseRelayRecipient is IRelayRecipient {

    /*
     * Forwarder singleton we accept calls from
     */
    address private _trustedForwarder;

    function trustedForwarder() public virtual view returns (address){
        return _trustedForwarder;
    }

    function _setTrustedForwarder(address _forwarder) internal {
        _trustedForwarder = _forwarder;
    }

    function isTrustedForwarder(address forwarder) public virtual override view returns(bool) {
        return forwarder == _trustedForwarder;
    }

    /**
     * return the sender of this call.
     * if the call came through our trusted forwarder, return the original sender.
     * otherwise, return `msg.sender`.
     * should be used in the contract anywhere instead of msg.sender
     */
    function _msgSender() internal override virtual view returns (address ret) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            // At this point we know that the sender is a trusted forwarder,
            // so we trust that the last bytes of msg.data are the verified sender address.
            // extract sender address from the end of msg.data
            assembly {
                ret := shr(96,calldataload(sub(calldatasize(),20)))
            }
        } else {
            ret = msg.sender;
        }
    }

    /**
     * return the msg.data of this call.
     * if the call came through our trusted forwarder, then the real sender was appended as the last 20 bytes
     * of the msg.data - so this method will strip those 20 bytes off.
     * otherwise (if the call was made directly and not through the forwarder), return `msg.data`
     * should be used in the contract instead of msg.data, where this difference matters.
     */
    function _msgData() internal override virtual view returns (bytes calldata ret) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            return msg.data[0:msg.data.length-20];
        } else {
            return msg.data;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";

import "./Permissions.sol";
import "../erc165/AdaptiveERC165.sol";
import "./../IDAO.sol";

/// @title Base component in the Aragon DAO framework
/// @author Samuel Furter - Aragon Association - 2021
/// @notice Any component within the Aragon DAO framework has to inherit from this contract
abstract contract Component is UUPSUpgradeable, AdaptiveERC165, Permissions {
    bytes32 public constant UPGRADE_ROLE = keccak256("UPGRADE_ROLE");

    /// @notice Initialization
    /// @param _dao the associated DAO address
    function __Component_init(IDAO _dao) internal virtual onlyInitializing {
        __Permissions_init(_dao);

        _registerStandard(type(Component).interfaceId);
    }

    /// @dev Used to check the permissions within the upgradability pattern implementation of OZ
    function _authorizeUpgrade(address) internal virtual override auth(UPGRADE_ROLE) {}

    /// @dev Fallback to handle future versions of the ERC165 standard.
    fallback() external {
        _handleCallback(msg.sig, _msgData()); // WARN: does a low-level return, any code below would be unreacheable
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

/**
 * a contract must implement this interface in order to support relayed transaction.
 * It is better to inherit the BaseRelayRecipient as its implementation.
 */
abstract contract IRelayRecipient {

    /**
     * return if the forwarder is trusted to forward relayed transactions to us.
     * the forwarder is required to verify the sender's signature, and verify
     * the call is not a replay.
     */
    function isTrustedForwarder(address forwarder) public virtual view returns(bool);

    /**
     * return the sender of this call.
     * if the call came through our trusted forwarder, then the real sender is appended as the last 20 bytes
     * of the msg.data.
     * otherwise, return `msg.sender`
     * should be used in the contract anywhere instead of msg.sender
     */
    function _msgSender() internal virtual view returns (address);

    /**
     * return the msg.data of this call.
     * if the call came through our trusted forwarder, then the real sender was appended as the last 20 bytes
     * of the msg.data - so this method will strip those 20 bytes off.
     * otherwise (if the call was made directly and not through the forwarder), return `msg.data`
     * should be used in the contract instead of msg.data, where this difference matters.
     */
    function _msgData() internal virtual view returns (bytes calldata);

    function versionRecipient() external virtual view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822.sol";
import "../ERC1967/ERC1967Upgrade.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is IERC1822Proxiable, ERC1967Upgrade {
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate that the this implementation remains valid after an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "./../IDAO.sol";
import "./../acl/ACL.sol";

/// @title Abstract implementation of the DAO permissions
/// @author Aragon Association - 2022
/// @notice This contract can be used to include the modifier logic(so contracts don't repeat the same code) that checks permissions on the dao.
/// @dev When your contract inherits from this, it is important to call __Permission_init with the associated DAO address.
abstract contract Permissions is Initializable, ContextUpgradeable {
    /// @dev Every component needs DAO at least for the permission management. See 'auth' modifier.
    IDAO internal dao;

    /// @notice Initializes the contract
    /// @param _dao the associated DAO address
    function __Permissions_init(IDAO _dao) internal virtual onlyInitializing {
        dao = _dao;
    }

    /// @dev Auth modifier used in all components of a DAO to check the permissions.
    /// @param _role The hash of the role identifier
    modifier auth(bytes32 _role) {
        if (!dao.hasPermission(address(this), _msgSender(), _role, _msgData()))
            revert ACLData.ACLAuth({
                here: address(this),
                where: address(this),
                who: _msgSender(),
                role: _role
            });

        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "./ERC165.sol";

/// @title AdaptiveERC165
/// @author Aragon Association - 2022
contract AdaptiveERC165 is ERC165 {
    /// @dev ERC165 interface ID -> whether it is supported
    mapping(bytes4 => bool) internal standardSupported;

    /// @dev Callback function signature -> magic number to return
    mapping(bytes4 => bytes32) internal callbackMagicNumbers;

    bytes32 internal constant UNREGISTERED_CALLBACK = bytes32(0);

    // Errors
    error AdapERC165UnkownCallback(bytes32 magicNumber);

    // Events
    event RegisteredStandard(bytes4 interfaceId);
    event RegisteredCallback(bytes4 sig, bytes4 magicNumber);
    event ReceivedCallback(bytes4 indexed sig, bytes data);

    /// @dev Method to check if the contract supports a specific interface or not
    /// @param _interfaceId The identifier of the interface to check for
    function supportsInterface(bytes4 _interfaceId) public view virtual override returns (bool) {
        return standardSupported[_interfaceId] || super.supportsInterface(_interfaceId);
    }

    /// @dev This method is existing to be able to support future versions of the ERC165 or similar without upgrading the contracts.
    /// @param _sig The function signature of the called method. (msg.sig)
    /// @param _data The data resp. arguments passed to the method
    function _handleCallback(bytes4 _sig, bytes memory _data) internal {
        bytes32 magicNumber = callbackMagicNumbers[_sig];
        if (magicNumber == UNREGISTERED_CALLBACK)
            revert AdapERC165UnkownCallback({magicNumber: magicNumber});

        emit ReceivedCallback(_sig, _data);

        // low-level return magic number
        assembly {
            mstore(0x00, magicNumber)
            return(0x00, 0x20)
        }
    }

    /// @dev Registers a standard and also callback
    /// @param _interfaceId The identifier of the interface to check for
    /// @param _callbackSig The function signature of the called method. (msg.sig)
    /// @param _magicNumber The data resp. arguments passed to the method
    function _registerStandardAndCallback(
        bytes4 _interfaceId,
        bytes4 _callbackSig,
        bytes4 _magicNumber
    ) internal {
        _registerStandard(_interfaceId);
        _registerCallback(_callbackSig, _magicNumber);
    }

    /// @dev Registers a standard resp. interface type
    /// @param _interfaceId The identifier of the interface to check for
    function _registerStandard(bytes4 _interfaceId) internal {
        standardSupported[_interfaceId] = true;
        emit RegisteredStandard(_interfaceId);
    }

    /// @dev Registers a callback
    /// @param _callbackSig The function signature of the called method. (msg.sig)
    /// @param _magicNumber The data resp. arguments passed to the method
    function _registerCallback(bytes4 _callbackSig, bytes4 _magicNumber) internal {
        callbackMagicNumbers[_callbackSig] = _magicNumber;
        emit RegisteredCallback(_callbackSig, _magicNumber);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822Proxiable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeacon.sol";
import "../../interfaces/draft-IERC1822.sol";
import "../../utils/Address.sol";
import "../../utils/StorageSlot.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967Upgrade {
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlot.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822Proxiable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlot.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlot.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlot.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(Address.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            Address.isContract(IBeacon(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlot.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(IBeacon(newBeacon).implementation(), data);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./IACLOracle.sol";

library ACLData {
    enum BulkOp {
        Grant,
        Revoke,
        Freeze
    }

    struct BulkItem {
        BulkOp op;
        bytes32 role;
        address who;
    }

    /// @notice Thrown if the function is not authorized
    /// @param here The contract containing the function
    /// @param where The contract being called
    /// @param who The address (EOA or contract) owning the permission
    /// @param role The role required to call the function
    error ACLAuth(address here, address where, address who, bytes32 role);

    /// @notice Thrown if the role was already granted to the address interacting with the target
    /// @param where The contract being called
    /// @param who The address (EOA or contract) owning the permission
    /// @param role The role required to call the function
    error ACLRoleAlreadyGranted(address where, address who, bytes32 role);

    /// @notice Thrown if the role was already revoked from the address interact with the target
    /// @param where The contract being called
    /// @param who The address (EOA or contract) owning the permission
    /// @param role The hash of the role identifier
    error ACLRoleAlreadyRevoked(address where, address who, bytes32 role);

    /// @notice Thrown if the address was already granted the role to interact with the target
    /// @param where The contract being called
    /// @param role The hash of the role identifier
    error ACLRoleFrozen(address where, bytes32 role);
}

/// @title The ACL used in the DAO contract to manage all permissions of a DAO.
/// @author Aragon Association - 2021
/// @notice This contract is used in the DAO contract and handles all the permissions of a DAO. This means it also handles the permissions of the processes or any custom component of the DAO.
contract ACL is Initializable {
    // @notice the ROOT_ROLE identifier used
    bytes32 public constant ROOT_ROLE = keccak256("ROOT_ROLE");

    // "Who" constants
    address internal constant ANY_ADDR = address(type(uint160).max);

    // "Access" flags
    address internal constant UNSET_ROLE = address(0);
    address internal constant ALLOW_FLAG = address(2);

    // hash(where, who, role) => Access flag(unset or allow) or ACLOracle (any other address denominates auth via ACLOracle)
    mapping(bytes32 => address) internal authPermissions;
    // hash(where, role) => true(role froze on the where), false(role is not frozen on the where)
    mapping(bytes32 => bool) internal freezePermissions;

    // Events
    event Granted(
        bytes32 indexed role,
        address indexed actor,
        address indexed who,
        address where,
        IACLOracle oracle
    );
    event Revoked(bytes32 indexed role, address indexed actor, address indexed who, address where);
    event Frozen(bytes32 indexed role, address indexed actor, address where);

    /// @dev The modifier used within the DAO framework to check permissions.
    //       Allows to set ROOT roles on specific contract or on the main, overal DAO.
    /// @param _where The contract that will be called
    /// @param _role The role required to call the method this modifier is applied to
    modifier auth(address _where, bytes32 _role) {
        if (
            !(willPerform(_where, msg.sender, _role, msg.data) ||
                willPerform(address(this), msg.sender, _role, msg.data))
        )
            revert ACLData.ACLAuth({
                here: address(this),
                where: _where,
                who: msg.sender,
                role: _role
            });
        _;
    }

    /// @dev Init method to set the owner of the ACL
    /// @param _who The callee of the method
    function __ACL_init(address _who) internal onlyInitializing {
        _initializeACL(_who);
    }

    /// @dev Method to grant permissions for a role on a contract to an address
    /// @param _where The address of the contract
    /// @param _who The address (EOA or contract) owning the permission
    /// @param _role The hash of the role identifier
    function grant(
        address _where,
        address _who,
        bytes32 _role
    ) external auth(_where, ROOT_ROLE) {
        _grant(_where, _who, _role);
    }

    /// @dev This method is used to grant access on a method of a contract based on a ACLOracle that allows us to have more dynamic permissions management.
    /// @param _where The address of the contract
    /// @param _who The address (EOA or contract) owning the permission
    /// @param _role The hash of the role identifier
    /// @param _oracle The ACLOracle responsible for this role on a specific method of a contract
    function grantWithOracle(
        address _where,
        address _who,
        bytes32 _role,
        IACLOracle _oracle
    ) external auth(_where, ROOT_ROLE) {
        _grantWithOracle(_where, _who, _role, _oracle);
    }

    /// @dev Method to revoke permissions of an address for a role of a contract
    /// @param _where The address of the contract
    /// @param _who The address (EOA or contract) owning the permission
    /// @param _role The hash of the role identifier
    function revoke(
        address _where,
        address _who,
        bytes32 _role
    ) external auth(_where, ROOT_ROLE) {
        _revoke(_where, _who, _role);
    }

    /// @dev Method to freeze a role of a contract
    /// @param _where The address of the contract
    /// @param _role The hash of the role identifier
    function freeze(address _where, bytes32 _role) external auth(_where, ROOT_ROLE) {
        _freeze(_where, _role);
    }

    /// @dev Method to do bulk operations on the ACL
    /// @param _where The address of the contract
    /// @param items A list of ACL operations to do
    function bulk(address _where, ACLData.BulkItem[] calldata items)
        external
        auth(_where, ROOT_ROLE)
    {
        for (uint256 i = 0; i < items.length; i++) {
            ACLData.BulkItem memory item = items[i];

            if (item.op == ACLData.BulkOp.Grant) _grant(_where, item.who, item.role);
            else if (item.op == ACLData.BulkOp.Revoke) _revoke(_where, item.who, item.role);
            else if (item.op == ACLData.BulkOp.Freeze) _freeze(_where, item.role);
        }
    }

    /// @dev This method is used to check if a callee has the permissions for. It is public to simplify the code within the DAO framework.
    /// @param _where The address of the contract
    /// @param _who The address (EOA or contract) owning the permission
    /// @param _role The hash of the role identifier
    /// @param _data The optional data passed to the ACLOracle registered.
    /// @return bool
    function willPerform(
        address _where,
        address _who,
        bytes32 _role,
        bytes memory _data
    ) public returns (bool) {
        return
            _checkRole(_where, _who, _role, _data) || // check if _who is eligible for _role on _where
            _checkRole(_where, ANY_ADDR, _role, _data) || // check if anyone is eligible for _role on _where
            _checkRole(ANY_ADDR, _who, _role, _data); // check if _who is eligible for _role on any contract.
    }

    /// @dev This method is used to check if a given role on a contract is frozen
    /// @param _where The address of the contract
    /// @param _role The hash of the role identifier
    /// @return bool Return true or false depending if it is frozen or not
    function isFrozen(address _where, bytes32 _role) public view returns (bool) {
        return freezePermissions[freezeHash(_where, _role)];
    }

    /// @dev This method is internally used to grant the ROOT_ROLE on initialization of the ACL
    /// @param _who The address (EOA or contract) owning the permission
    function _initializeACL(address _who) internal {
        _grant(address(this), _who, ROOT_ROLE);
    }

    /// @dev This method is used in the public grant method of the ACL
    /// @param _where The address of the contract
    /// @param _who The address (EOA or contract) owning the permission
    /// @param _role The hash of the role identifier
    function _grant(
        address _where,
        address _who,
        bytes32 _role
    ) internal {
        _grantWithOracle(_where, _who, _role, IACLOracle(ALLOW_FLAG));
    }

    /// @dev This method is used in the internal _grant method of the ACL
    /// @param _where The address of the contract
    /// @param _who The address (EOA or contract) owning the permission
    /// @param _role The hash of the role identifier
    /// @param _oracle The ACLOracle to be used or it is just the ALLOW_FLAG
    function _grantWithOracle(
        address _where,
        address _who,
        bytes32 _role,
        IACLOracle _oracle
    ) internal {
        if (isFrozen(_where, _role)) revert ACLData.ACLRoleFrozen({where: _where, role: _role});

        bytes32 permission = permissionHash(_where, _who, _role);
        if (authPermissions[permission] != UNSET_ROLE)
            revert ACLData.ACLRoleAlreadyGranted({where: _where, who: _who, role: _role});
        authPermissions[permission] = address(_oracle);

        emit Granted(_role, msg.sender, _who, _where, _oracle);
    }

    /// @dev This method is used in the public revoke method of the ACL
    /// @param _where The address of the contract
    /// @param _who The address (EOA or contract) owning the permission
    /// @param _role The hash of the role identifier
    function _revoke(
        address _where,
        address _who,
        bytes32 _role
    ) internal {
        if (isFrozen(_where, _role)) revert ACLData.ACLRoleFrozen({where: _where, role: _role});

        bytes32 permission = permissionHash(_where, _who, _role);
        if (authPermissions[permission] == UNSET_ROLE)
            revert ACLData.ACLRoleAlreadyRevoked({where: _where, who: _who, role: _role});
        authPermissions[permission] = UNSET_ROLE;

        emit Revoked(_role, msg.sender, _who, _where);
    }

    /// @dev This method is used in the public freeze method of the ACL
    /// @param _where The address of the contract
    /// @param _role The hash of the role identifier
    function _freeze(address _where, bytes32 _role) internal {
        bytes32 permission = freezeHash(_where, _role);
        if (freezePermissions[permission])
            revert ACLData.ACLRoleFrozen({where: _where, role: _role});
        freezePermissions[freezeHash(_where, _role)] = true;

        emit Frozen(_role, msg.sender, _where);
    }

    /// @dev This method is used in the public willPerform method of the ACL.
    /// @param _where The address of the contract
    /// @param _who The address (EOA or contract) owning the permission
    /// @param _role The hash of the role identifier
    /// @param _data The optional data passed to the ACLOracle registered.
    /// @return bool
    function _checkRole(
        address _where,
        address _who,
        bytes32 _role,
        bytes memory _data
    ) internal returns (bool) {
        address accessFlagOrAclOracle = authPermissions[permissionHash(_where, _who, _role)];

        if (accessFlagOrAclOracle == UNSET_ROLE) return false;
        if (accessFlagOrAclOracle == ALLOW_FLAG) return true;

        // Since it's not a flag, assume it's an ACLOracle and try-catch to skip failures
        try IACLOracle(accessFlagOrAclOracle).willPerform(_where, _who, _role, _data) returns (
            bool allowed
        ) {
            if (allowed) return true;
        } catch {}

        return false;
    }

    /// @dev This internal method is used to generate the hash for the authPermissions mapping based on the target contract, the address to grant permissions, and the role identifier.
    /// @param _where The address of the contract
    /// @param _who The address (EOA or contract) owning the permission
    /// @param _role The hash of the role identifier
    /// @return bytes32 The hash of the permissions
    function permissionHash(
        address _where,
        address _who,
        bytes32 _role
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("PERMISSION", _who, _where, _role));
    }

    /// @dev This internal method is used to generate the hash for the freezePermissions mapping based on the target contract and the role identifier.
    /// @param _where The address of the contract
    /// @param _role The hash of the role identifier
    /// @return bytes32 The freeze hash used in the freezePermissions mapping
    function freezeHash(address _where, bytes32 _role) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("FREEZE", _where, _role));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

/// @title The IACLOracle to have dynamic permissions
/// @author Aragon Association - 2021
/// @notice This contract used to have dynamic permissions as for example that only users with a token X can do Y.
interface IACLOracle {
    // @dev This method is used to check if a callee has the permissions for.
    // @param _where The address of the contract
    // @param _who The address of a EOA or contract to give the permissions
    // @param _role The hash of the role identifier
    // @param _data The optional data passed to the ACLOracle registered.
    // @return bool
    function willPerform(
        address _where,
        address _who,
        bytes32 _role,
        bytes calldata _data
    ) external returns (bool allowed);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

/// @title ERC165
/// @author Aragon Association - 2022
abstract contract ERC165 {
    // Includes supportsInterface method:
    bytes4 internal constant ERC165_INTERFACE_ID = bytes4(0x01ffc9a7);

    /// @dev Query if a contract implements a certain interface
    /// @param _interfaceId The interface identifier being queried, as specified in ERC-165
    /// @return True if the contract implements the requested interface and if its not 0xffffffff, false otherwise
    function supportsInterface(bytes4 _interfaceId) public view virtual returns (bool) {
        return _interfaceId == ERC165_INTERFACE_ID;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

library Uint256Helpers {
    uint256 private constant MAX_UINT64 = type(uint64).max;

    error OutOfBounds(uint256 maxValue, uint256 value);

    function toUint64(uint256 a) internal pure returns (uint64) {
        if (a > MAX_UINT64) revert OutOfBounds({maxValue: MAX_UINT64, value: a});
        return uint64(a);
    }
}