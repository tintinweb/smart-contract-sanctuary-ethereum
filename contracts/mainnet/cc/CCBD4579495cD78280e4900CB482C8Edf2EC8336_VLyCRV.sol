// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.17;

import "IERC20.sol";

contract VLyCRV {
    struct UserInfo {
        uint128 balance;
        uint128 votesSpent;
        uint40 lastVoteTime;
        uint40 unlockTime;
        address voteDelegate;
    }

    event Deposit(address indexed user, uint value);
    event Withdraw(address indexed user, uint value);
    event Vote(
        address indexed user,
        address indexed gauge,
        uint indexed period,
        uint value
    );
    event SetVoteDelegate(address indexed user, address indexed delegate);
    event ClearVoteDelegate(address indexed user, address indexed delegate);
    event DismissLocks(bool indexedlockDismissed);
    event NewPeriod(uint indexed period);
    event SnapshotTaken(address indexed snapshotter, uint indexed timestamp);
    event GovernanceChanged(
        address indexed oldGovernance,
        address indexed newGovernance
    );
    event WhitelistChanged(address indexed depositer, bool indexed whitelisted);

    uint constant WEEK = 7 days;
    address public constant CONTROLLER =
        0x2F50D538606Fa9EDD2B11E2446BEb18C9D5846bB;
    IERC20 public constant YCRV =
        IERC20(0xFCc5c47bE19d06BF83eB04298b026F81069ff65b);

    address public governance = 0xFEB4acf3df3cDEA7399794D0869ef76A6EfAff52;
    uint256 public currentPeriod;
    uint256 public totalVotes; // keep track of the sum of votes in votes
    uint256 public maxGauges; //max number of gauges we can vote on
    bool public lockDismissed;
    address public pendingGovernance;

    mapping(address => UserInfo) public userInfo;
    uint256 public votesVirtualLength = 1; // 0th index is emtpy.
    uint256[] public votes; // 0th index is emtpy. we will make a priority list. Add 1 at a time. if len > maxgauges. pop
    mapping(uint256 => uint256) public votesPointers;
    mapping(address => bool) public whitelisted;

    mapping(uint256 => uint[]) public snapshots;

    uint256 lastGaugeId;
    mapping(uint256 => address) public idToGauge;
    mapping(address => uint256) public gaugeToId;

    //we gonna pack 4 into 1.
    //16 bits per id (max 65536 gauges). 48 bits for the votes (2.8e14). we scale down vote by 3 decimals. 64 bits per pair. 256 per 4 pairs

    modifier onlyGovernance() {
        require(msg.sender == governance, "!governance");
        _;
    }

    constructor(uint256 _maxGauges, address _governance) {
        votes = new uint256[](1); // we dont use the 0th index
        maxGauges = _maxGauges;
        currentPeriod = (block.timestamp / WEEK) * WEEK; // Beginning of current week
        pendingGovernance = _governance;
    }

    function name() external view returns (string memory) {
        return "Vote Locked Yearn CRV";
    }

    function symbol() external view returns (string memory) {
        return "vl-yCRV";
    }

    function setMaxGauges(uint256 _maxGauges) external onlyGovernance {
        require(_maxGauges < 10_000, "Too many gauges");
        maxGauges = _maxGauges;
    }

    function balanceOf(address _user) external view returns (uint) {
        return userInfo[_user].balance;
    }

    /// @notice Return decoded vote data for current period.
    /// @return gaugesList gauges voted on during current period
    /// @return voteAmounts amount of votes received by each voted gauge in this period.
    function getVotesUnpacked()
        external
        view
        returns (address[] memory gaugesList, uint256[] memory voteAmounts)
    {
        uint _length = votesVirtualLength - 1;
        gaugesList = new address[](_length);
        voteAmounts = new uint256[](_length);

        // as we ignore 0th index in votes we go back one each step
        for (uint i; i < _length;) {
            (uint16 guint, uint48 v) = decodeVotes(i + 1);

            address g = idToGauge[guint];

            gaugesList[i] = g;
            voteAmounts[i] = uint(v) * 1e15;

            unchecked {
                i = i + 1;
            }
        }
    }

    /// @notice Return raw packed of snapshot of votes.
    /// @dev use getSnapshotUnpacked for readable version
    /// @param snapshot The timestamp the snapshot was taken.
    /// @return votes list of votes packed 4 into each uint.
    function getSnapshotRaw(
        uint snapshot
    ) external view returns (uint[] memory) {
        return snapshots[snapshot];
    }

    /// @notice Return decoded vote data for snapshot timestamp.
    /// @param snapshot The timestamp the snapshot was taken.
    /// @return gaugesList gauges voted on at the snapshot timestamp.
    /// @return voteAmounts amount of votes received by each voted gauge at the snapshot timestamp.
    function getSnapshotUnpacked(
        uint snapshot
    )
        external
        view
        returns (address[] memory gaugesList, uint256[] memory voteAmounts)
    {
        uint[] memory snaps = snapshots[snapshot];
        uint length = snaps.length;
        require(length > 0, "no snapshot saved");

        uint _virtualvoteslength;

        uint last = snaps[length - 1];
        if (uint64(last >> (64 * 2)) == 0) {
            _virtualvoteslength = length * 4 - 3; //add one because indexed at 0
        } else if (uint64(last >> (64 * 1)) == 0) {
            _virtualvoteslength = length * 4 - 2;
        } else if (uint64(last) == 0) {
            _virtualvoteslength = length * 4 - 1;
        } else {
            _virtualvoteslength = length * 4;
        }

        //find last
        gaugesList = new address[](_virtualvoteslength);
        voteAmounts = new uint256[](_virtualvoteslength);

        // as we ignore 0th index in votes we go back one each step
        for (uint i; i < _virtualvoteslength;) {
            uint index = (i) / 4;
            uint remainder = (i) % 4;
            (uint16 guint, uint48 v) = getVotes(snaps[index], remainder);

            address g = idToGauge[guint];

            gaugesList[i] = g;
            voteAmounts[i] = uint(v) * 1e15;

            unchecked {
                i = i + 1;
            }
        }
    }

    /// @notice Deposit to vl-yCRV. Balance only becomes locked after voting.
    /// @param _amount Amount of yCRV to deposit.
    function deposit(uint128 _amount) external {
        //ycrv reverts if transferFrom fails
        IERC20(YCRV).transferFrom(msg.sender, address(this), _amount);
        uint128 bal = userInfo[msg.sender].balance;
        userInfo[msg.sender].balance = bal + _amount;
        emit Deposit(msg.sender, _amount);
    }

    /// @notice Withdraw from vl-yCRV. Only possible if not locked.
    /// @dev User can only withdraw if they haven't voted in neither the current nor previous period.
    /// @param _amount Amount of yCRV to withdraw.
    function withdraw(uint128 _amount) external {
        if (!lockDismissed && !whitelisted[msg.sender]){
            require(block.timestamp > userInfo[msg.sender].unlockTime, "vl-yCRV: Locked");
        }
            
        uint128 bal = userInfo[msg.sender].balance;
        userInfo[msg.sender].balance = bal - _amount; //reverts if not enough balance to withdraw
        IERC20(YCRV).transfer(msg.sender, _amount);
        emit Withdraw(msg.sender, _amount);
    }

    /// @notice
    ///     Cast vote for a single gauge in current period.
    ///     Balance becomes locked until end of next period (up to 28 days) upon voting.
    /// @dev Max vote size is 96 bits which is plenty. Allows for over 10x CRV total supply.
    /// @param _gauge Address of the Curve gauge to vote for.
    /// @param _numVotes Number of votes to apply. Will spend this amount of user's votes until next period.
    function vote(address _gauge, uint96 _numVotes) external {
        address[] memory _gauges = new address[](1);
        uint96[] memory _votes = new uint96[](1);
        _gauges[0] = _gauge;
        _votes[0] = _numVotes;
        _vote(msg.sender, _gauges, _votes);
    }

    /// @notice
    ///     Cast vote on behalf of user who has delegated.
    ///     Balance becomes locked until end of next period (up to 21 days) upon voting.
    /// @param _user Address of the user to vote for. Must have delegated to msg.sender.
    /// @param _gauge Address of the Curve gauge to vote for.
    /// @param _numVotes Number of user's remaining votes to apply.
    function voteFor(address _user, address _gauge, uint96 _numVotes) external {
        require(
            msg.sender == userInfo[_user].voteDelegate,
            "vl-yCRV: Invalid Delegate"
        );
        address[] memory _gauges = new address[](1);
        uint96[] memory _votes = new uint96[](1);
        _gauges[0] = _gauge;
        _votes[0] = _numVotes;
        _vote(_user, _gauges, _votes);
    }

    /// @notice
    ///     Cast vote for a multiple gauges in current period.
    ///     Balance becomes locked until end of next period (up to 21 days) upon voting.
    /// @param _gauges Addresses of the Curve gauges to vote for.
    /// @param _numVotes Numbers of votes to apply to each gauge. Will spend this amount of user's votes until next period.
    function voteMany(
        address[] memory _gauges,
        uint96[] memory _numVotes
    ) external {
        require(
            _gauges.length == _numVotes.length,
            "vl-yCRV: Different Length Inputs"
        );
        _vote(msg.sender, _gauges, _numVotes);
    }

    /// @notice
    ///     Cast vote on behalf of user who has delegated for a multiple gauges in current period.
    ///     Balance becomes locked until end of next period (up to 21 days) upon voting.
    /// @param _user Address of the user to vote for. Must have delegated to msg.sender.
    /// @param _gauges Addresses of the Curve gauges to vote for.
    /// @param _numVotes Numbers of votes to apply to each gauge. Will spend this amount of user's votes until next period.
    function voteManyFor(
        address _user,
        address[] memory _gauges,
        uint96[] memory _numVotes
    ) external {
        require(
            _gauges.length == _numVotes.length,
            "vl-yCRV: Different Length Inputs"
        );
        require(
            msg.sender == userInfo[_user].voteDelegate,
            "vl-yCRV: Invalid Delegate"
        );
        _vote(_user, _gauges, _numVotes);
    }

    function _vote(
        address _user,
        address[] memory _gauges,
        uint96[] memory _numVotes
    ) internal {
        _updatePeriod();
        UserInfo storage ui = userInfo[_user]; //storage pointer
        uint128 votesLeft = ui.balance;
        if (ui.lastVoteTime >= currentPeriod) {
            require(votesLeft > ui.votesSpent, "vl-yCRV:Amount Exceeds votesLeft");
            unchecked {
                votesLeft = votesLeft - ui.votesSpent;
            }
        }

        for (uint i = 0; i < _gauges.length;) {
            require(_gauges[i] != address(0), "vl-yCRV:Voted For 0 Address");
            require(_numVotes[i] > 0, "vl-yCRV:Voted Zero");
            require(_numVotes[i] <= votesLeft, "vl-yCRV:Too Many Votes");

            uint16 gaugeId = uint16(gaugeToId[_gauges[i]]);
            if (gaugeId == 0) {
                //only external call if pointer doesnt exist
                bytes memory data = abi.encodeWithSignature(
                    "gauge_types(address)",
                    _gauges[i]
                );
                (bool success, ) = CONTROLLER.call(data);
                require(success, "vl-yCRV:Gauge Does Not Exist");

                gaugeId = uint16(lastGaugeId + 1);
                lastGaugeId = gaugeId;
                idToGauge[gaugeId] = _gauges[i];
                gaugeToId[_gauges[i]] = gaugeId;
            }

            unchecked { //require statement assures votesLeft >= _numVotes[i]
                votesLeft = votesLeft - _numVotes[i];
            }

            _insert(gaugeId, uint48(_numVotes[i] / 1e15));
            emit Vote(_user, _gauges[i], currentPeriod, _numVotes[i]);

            unchecked {
                i = i + 1;
            }
        }

        ui.lastVoteTime = uint40(block.timestamp);
        ui.unlockTime = uint40(nextPeriod() + 14 days);
        ui.votesSpent = ui.balance - votesLeft;
    }

    function _resetVotes() internal {
        //dont actually delete so we arent paying a lot to set each new storage slot
        // // ignore zero index
        uint _votesVirtualLength = votesVirtualLength;
        for (uint i = 1; i < _votesVirtualLength;) {
            (uint16 g, ) = decodeVotes(i);
            delete votesPointers[g];

            unchecked {
                i = i + 1;
            }
        }

        votesVirtualLength = 1;
        totalVotes = 0;
    }

    /// @dev
    ///     if it already exists in the queue we add to it. then bubble down
    ///     if it does not exist we push to the end then bubble up
    ///     if we now have too many we remove the smallest
    ///     the expensive part is the bubbling. we do max two bubbles.
    ///     which has max iterations of 2*log2(maxGauges). 16 iterations for 256 gauges.
    function _insert(uint16 _gauge, uint48 _votes) internal {
        totalVotes = totalVotes + uint(_votes) * 1e15;
        //is it in already?
        uint256 index = votesPointers[_gauge];

        if (index != 0) {
            (uint16 g, uint48 v) = decodeVotes(index);
            v = v + _votes;
            _setVotes(index, g, v);

            //reheap. now we need to bubble down. only down as the votes can only increase
            _bubbleDown(index);
        } else {
            //check if we have too many. if so swap with top and bubble down
            // + 1 because we ignore 0th
            if (votesVirtualLength >= maxGauges + 1) {
                (uint16 g, uint48 v) = decodeVotes(1);

                //if new one has less than current min exit early
                if (v >= _votes) {
                    totalVotes = totalVotes - uint(_votes) * 1e15;
                    return;
                }

                //remove pointer for first
                votesPointers[g] = 0;
                totalVotes = totalVotes - uint(v) * 1e15; //deleting the votes

                //put our new vote in 1st position
                _setVotes(1, _gauge, _votes);
                // votes[1] = encoded;
                votesPointers[_gauge] = 1;

                //bubble down from the top
                _bubbleDown(1);
            } else {
                uint _votesVirtualLength = votesVirtualLength;
                //else add to bottom and bubble up
                _setVotes(_votesVirtualLength, _gauge, _votes);
                
                votesPointers[_gauge] = _votesVirtualLength; //virtual index has increased but we store a local number from before the increase
                _bubbleUp(_votesVirtualLength);
            }
        }
    }

    /// @dev
    ///     iterations is max depth of the tree. Which is log2(maxGauges). 8 iterations for 256 gauges.
    ///     2 + 2 overwrite sstores per iteration
    function _bubbleUp(uint256 _index) internal {
        // uint256 bubblingEncoded = votes[_index];
        (uint16 bubblingGauge, uint48 bubblingVote) = decodeVotes(_index);

        uint originalPosition = _index;
        // Bubble up until it is larger than it's parent
        // we can use div 2 because it removes the remainder. so if index is 7 we get parent of 3.
        while (_index > 1) {
            // we can use div 2 because it removes the remainder. so if index is 7 we get parent of 3.
            (uint16 parentGauge, uint48 parentVote) = decodeVotes(_index / 2);
            if (parentVote < bubblingVote) {
                break;
            }

            // swap with the parent
            _setVotes(_index, parentGauge, parentVote);

            //replace the pointers
            votesPointers[parentGauge] = _index;

            // change our current Index to go up to the parent
            _index = _index / 2;
        }

        if (originalPosition != _index) {
            _setVotes(_index, bubblingGauge, bubblingVote);
            votesPointers[bubblingGauge] = _index;
        }
    }

    /// @dev
    ///     bubbling down moves larger gauges down
    ///     iterations is max depth of the tree. Which is log2(maxGauges). 8 iterations for 256 gauges.
    ///     2+ 2 overwrite sstores per iteration.
    function _bubbleDown(uint256 _index) internal {
        // uint256 bubblingEncoded = votes[_index];
        (uint16 bubblingGauge, uint48 bubblingVote) = decodeVotes(_index);

        uint256 length = votesVirtualLength - 1;
        uint originalPosition = _index;
        while (_index * 2 < length) {
            // get the current index of the children
            uint256 j = _index * 2;

            // left child value
            (uint16 leftChildGauge, uint48 leftChildVote) = decodeVotes(j);
            // right child value
            (uint16 rightChildGauge, uint48 rightChildVote) = decodeVotes(
                j + 1
            );

            // Compare the left and right child. if the rightChild is smaller, then point j to it's index and swap into left
            if (leftChildVote > rightChildVote) {
                j = j + 1;
                leftChildVote = rightChildVote;
                leftChildGauge = rightChildGauge;
            }

            // compare the current parent value with the lowest child, if the parent is lower, we're done
            if (bubblingVote < leftChildVote) {
                break;
            }

            // else swap the value
            _setVotes(_index, leftChildGauge, leftChildVote);

            //replace the pointers
            votesPointers[leftChildGauge] = _index;

            // and let's keep going down the heap
            _index = j;
        }

        if (originalPosition != _index) {
            _setVotes(_index, bubblingGauge, bubblingVote);
            votesPointers[bubblingGauge] = _index;
        }
    }

    /// @notice Saves the current votes for future reference
    function takeSnapshot() external {
        uint time = block.timestamp;

        if (snapshots[time].length != 0) {
            return;
        }

        emit SnapshotTaken(msg.sender, time);

        uint lastIndex = (votesVirtualLength - 1) / 4;
        uint rem = (votesVirtualLength - 1) % 4;

        if (rem != 0) {
            //if we are not an even number we need to overflow to next index
            lastIndex += 1;
        }

        for (uint i; i < lastIndex;) {
            uint left = 0;
            if (i == lastIndex - 1) {
                uint remainder = 4 - rem; //3 =1, 2=2,1=3, 0 =4.

                if (remainder != 4) {
                    left = 64 * remainder;
                    left = 2 ** left - 1; // rem 3 = 0001, 2 = 0011, 1=0111, 0=0000
                }
            }

            snapshots[time].push(votes[i] & ~left);

            unchecked {
                i = i + 1;
            }
        }
    }

    function decodedVotePointers(address gauge) external view returns (uint) {
        return votesPointers[gaugeToId[gauge]];
    }

    function decodeVotes(
        uint256 _virtualIndex
    ) public view returns (uint16 g, uint48 v) {
        uint index = (_virtualIndex - 1) / 4;
        uint remainder = (_virtualIndex - 1) % 4;

        return (getVotes(votes[index], remainder));
    }

    function getVotes(
        uint256 _packed,
        uint _remainder
    ) public view returns (uint16 g, uint48 v) {
        uint offset = 192 - (_remainder * 64); //remainder is max 3

        uint encoded = _packed >> offset;

        g = uint16(encoded);
        v = uint48(encoded >> 16);
    }

    function _setVotes(uint256 _virtualIndex, uint16 g, uint48 v) internal {
        if (_virtualIndex >= votesVirtualLength) {
            votesVirtualLength += 1;
        }

        uint index = (_virtualIndex - 1) / 4;
        uint remainder = (_virtualIndex - 1) % 4;
        uint offset = 192 - (remainder * 64);

        uint current;

        if (index + 1 > votes.length) {
            current = 0;
        } else {
            uint mask = 2 ** 64 - 1;
            mask = mask << offset;

            current = votes[index] & ~mask; // remove current one
        }

        uint256 encoded = v;
        encoded = encoded << 16;
        encoded += g;
        encoded = encoded << offset;
        current = current + encoded;

        if (index + 1 > votes.length) {
            votes.push(current);
        } else {
            votes[index] = current;
        }
    }

    function updatePeriod() external {
        _updatePeriod();
    }

    function _updatePeriod() internal {
        uint next = nextPeriod();
        if (block.timestamp >= next) {
            currentPeriod = next;
            _resetVotes();
            next = nextPeriod();
        }
        while (block.timestamp >= next) {
            currentPeriod = next;
            next = nextPeriod();
        }

        emit NewPeriod(currentPeriod);
    }

    function nextPeriod() public view returns (uint256) {
        return currentPeriod + 14 days;
    }

    function acceptGovernance() external {
        require(msg.sender == pendingGovernance, "!governance");
        address old = governance;
        governance = pendingGovernance;
        emit GovernanceChanged(old, governance);
    }

    function setGovernance(address _governance) external onlyGovernance {
        pendingGovernance = _governance;
    }

    function whitelist(
        address _depositer,
        bool _whitelisted
    ) external onlyGovernance {
        whitelisted[_depositer] = _whitelisted;
        emit WhitelistChanged(_depositer, _whitelisted);
    }

    /// @notice Allow governance to dismiss all locks
    /// @dev Useful if ever a migration is needed
    /// @param _lockDismissed True to dismiss all user locks. False to enforce user individual locks.
    function setLockDismissed(bool _lockDismissed) external onlyGovernance {
        lockDismissed = _lockDismissed;
        emit DismissLocks(_lockDismissed);
    }

    /// @notice
    ///     Set a delegate who will be given rights to spend your vote
    ///     Setting a delegate may be helpful for automating votes each period.
    /// @dev Can use this function to update from one delegate to another.
    function setDelegate(address _delegate) external {
        require(_delegate != msg.sender, "Can't delegate to self");
        require(_delegate != address(0), "Can't delegate to 0x0");
        address current_delegate = userInfo[msg.sender].voteDelegate;
        require(
            _delegate != current_delegate,
            "Already delegated to this address"
        );

        userInfo[msg.sender].voteDelegate = _delegate;
        if (current_delegate != address(0)) {
            emit ClearVoteDelegate(msg.sender, current_delegate);
        }
        emit SetVoteDelegate(msg.sender, _delegate);
    }

    /// @notice Clear an actively set delegate
    function clearDelegate() external {
        address current_delegate = userInfo[msg.sender].voteDelegate;
        require(current_delegate != address(0), "No delegate set");
        userInfo[msg.sender].voteDelegate = address(0);
        emit ClearVoteDelegate(msg.sender, current_delegate);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}