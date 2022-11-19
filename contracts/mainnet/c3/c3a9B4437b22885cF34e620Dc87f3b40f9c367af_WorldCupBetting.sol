/**
 *Submitted for verification at Etherscan.io on 2022-11-19
*/

pragma solidity 0.8.17;

// SPDX-License-Identifier: MIT

library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value)
        private
        view
        returns (bool)
    {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index)
        private
        view
        returns (bytes32)
    {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value)
        internal
        returns (bool)
    {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value)
        internal
        returns (bool)
    {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index)
        internal
        view
        returns (bytes32)
    {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set)
        internal
        view
        returns (bytes32[] memory)
    {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index)
        internal
        view
        returns (address)
    {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set)
        internal
        view
        returns (address[] memory)
    {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value)
        internal
        returns (bool)
    {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index)
        internal
        view
        returns (uint256)
    {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set)
        internal
        view
        returns (uint256[] memory)
    {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function decimals() external view returns (uint8);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() external virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract WorldCupBetting is Ownable, ReentrancyGuard {
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.Bytes32Set;

    mapping(address => bool) public isAuthorized;

    EnumerableSet.UintSet private activeMatches;
    EnumerableSet.UintSet private closedMatches;
    mapping(address => uint256) public amountWonByAccount;
    mapping(address => EnumerableSet.UintSet) private accountMatchesPending;
    mapping(uint256 => MatchInfo) private matchInformation;
    address public feeReceiver;
    uint256 public feePercent = 1000;
    uint256 public maxBet = 1 ether;

    uint256 public totalPayoutsPaid;

    struct Player {
        uint256 winnerSelected;
        uint256 amountBet;
    }

    struct MatchInfo {
        string description;
        uint256 eventStartTime;
        uint256 shareOfPlayersBettingA;
        uint256 shareOfPlayersBettingB;
        uint256 shareOfPlayersBettingDraw;
        mapping(address => Player) players;
        uint256 totalPayout;
        uint256 winner;
        bool active;
    }

    event MatchCreated(
        uint256 indexed matchId,
        string description,
        uint256 indexed eventStartTime
    );
    event PlayerBet(
        uint256 indexed matchId,
        address indexed walletAddress,
        uint256 indexed winner,
        uint256 amount
    );
    event MatchClosed(uint256 indexed matchId);

    constructor() {
        isAuthorized[msg.sender] = true;
        feeReceiver = msg.sender;
    }

    modifier onlyAuthorized() {
        require(isAuthorized[msg.sender], "Not Authorized");
        _;
    }

    function setAuthorization(address account, bool authorized)
        external
        onlyOwner
    {
        isAuthorized[account] = authorized;
    }

    function setFeeReceiver(address _feeReceiver) external onlyOwner {
        feeReceiver = _feeReceiver;
    }

    function setFee(uint256 feePerc) external onlyOwner {
        require(feePerc < 1000, "Cannot be more than 10%");
        feePercent = feePerc;
    }

    function setMaxBet(uint256 _maxBet) external onlyOwner {
        require(_maxBet >= .001 ether, "too low");
        maxBet = _maxBet;
    }

    // note: A = 1, B = 2, Draw = 3
    function bet(uint256 matchId, uint256 winnerSelection)
        external
        payable
        nonReentrant
    {
        require(msg.value <= maxBet, "Amount sent too high");
        require(msg.value >= .001 ether, "Cannot bet less than 0.001 ether");
        require(msg.sender == tx.origin, "Contracts cannot play");
        MatchInfo storage matchInfo = matchInformation[matchId];
        require(
            matchInfo.eventStartTime > block.timestamp,
            "Cannot bet anymore"
        );
        Player storage player = matchInfo.players[msg.sender];
        require(
            player.winnerSelected == 0,
            "Cannot select again or add more to bet"
        );
        require(
            winnerSelection <= 3 && winnerSelection != 0,
            "Can only select team A, B, or Draw"
        );
        uint256 amountForBet = msg.value;

        // handle fees
        if (feePercent > 0) {
            bool success;
            uint256 amountForFee = (msg.value * feePercent) / 10000;
            (success, ) = address(feeReceiver).call{value: amountForFee}("");
            amountForBet -= amountForFee;
        }

        player.winnerSelected = winnerSelection;
        player.amountBet = amountForBet;
        accountMatchesPending[msg.sender].add(matchId);
        matchInfo.totalPayout += amountForBet;

        if (winnerSelection == 1) {
            matchInfo.shareOfPlayersBettingA += amountForBet;
        } else if (winnerSelection == 2) {
            matchInfo.shareOfPlayersBettingB += amountForBet;
        } else {
            matchInfo.shareOfPlayersBettingDraw += amountForBet;
        }
        emit PlayerBet(matchId, msg.sender, winnerSelection, amountForBet);
    }

    // used to start a match
    // note: A = 1, B = 2, Draw = 3
    function initializeNewMatch(
        uint256 matchId,
        uint256 eventStartTime,
        string calldata desc
    ) external onlyAuthorized {
        require(!activeMatches.contains(matchId), "Match already created");
        require(eventStartTime > block.timestamp, "Match already started");
        activeMatches.add(matchId);
        MatchInfo storage matchInfo = matchInformation[matchId];
        matchInfo.description = desc;
        matchInfo.active = true;
        matchInfo.eventStartTime = eventStartTime;
        emit MatchCreated(matchId, desc, eventStartTime);
    }

    function setWinner(uint256 matchId, uint256 winner)
        external
        onlyAuthorized
    {
        MatchInfo storage matchInfo = matchInformation[matchId];
        require(activeMatches.contains(matchId), "Match is closed");
        require(
            winner <= 4 && winner != 0,
            "Can only select team A, B, or Draw or Cancelled"
        );
        matchInfo.winner = winner;

        uint256 shares;
        if (matchInfo.winner == 1) {
            shares = matchInfo.shareOfPlayersBettingA;
        } else if (matchInfo.winner == 2) {
            shares = matchInfo.shareOfPlayersBettingB;
        } else if (matchInfo.winner == 3) {
            shares = matchInfo.shareOfPlayersBettingDraw;
        } else if (matchInfo.winner == 4) {
            shares = matchInfo.totalPayout;
        }

        // in the rare case of NO winners, fee receiver takes pool
        if (shares == 0 && matchInfo.totalPayout > 0) {
            (bool success, ) = address(feeReceiver).call{
                value: matchInfo.totalPayout
            }("");
            require(success, "failed to process payment to fee receiver");
        }

        activeMatches.remove(matchId);
        closedMatches.add(matchId);
        matchInfo.active = false;
    }

    function cashOut(uint256 matchId) external nonReentrant {
        require(msg.sender == tx.origin, "Contracts cannot play");
        bool success;
        MatchInfo storage matchInfo = matchInformation[matchId];
        Player storage player = matchInfo.players[msg.sender];
        if (
            closedMatches.contains(matchId) &&
            accountMatchesPending[msg.sender].contains(matchId)
        ) {
            accountMatchesPending[msg.sender].remove(matchId);

            if (player.winnerSelected == matchInfo.winner) {
                uint256 shares;
                if (matchInfo.winner == 1) {
                    shares = matchInfo.shareOfPlayersBettingA;
                } else if (matchInfo.winner == 2) {
                    shares = matchInfo.shareOfPlayersBettingB;
                } else {
                    shares = matchInfo.shareOfPlayersBettingDraw;
                }

                uint256 amountForPayout = (player.amountBet *
                    matchInfo.totalPayout) / shares;
                amountWonByAccount[msg.sender] += amountForPayout;
                if (amountForPayout > 0) {
                    (success, ) = address(msg.sender).call{
                        value: amountForPayout
                    }("");
                    require(success, "withdraw unsuccessful");
                }
            } else if (matchInfo.winner == 4 && player.amountBet > 0) {
                amountWonByAccount[msg.sender] += player.amountBet;
                (success, ) = address(msg.sender).call{value: player.amountBet}(
                    ""
                );
                require(success, "withdraw unsuccessful");
            }
        }
    }

    function cashOutAll() external nonReentrant {
        require(msg.sender == tx.origin, "Contracts cannot play");
        uint256[] memory matchIds = accountMatchesPending[msg.sender].values();
        uint256 amountForPayout;
        for (uint256 i = 0; i < matchIds.length; i++) {
            MatchInfo storage matchInfo = matchInformation[matchIds[i]];
            Player storage player = matchInfo.players[msg.sender];

            if (
                closedMatches.contains(matchIds[i]) &&
                accountMatchesPending[msg.sender].contains(matchIds[i])
            ) {
                accountMatchesPending[msg.sender].remove(matchIds[i]);

                uint256 shares;
                if (matchInfo.winner == 1) {
                    shares = matchInfo.shareOfPlayersBettingA;
                } else if (matchInfo.winner == 2) {
                    shares = matchInfo.shareOfPlayersBettingB;
                } else {
                    shares = matchInfo.shareOfPlayersBettingDraw;
                }

                if (player.winnerSelected == matchInfo.winner) {
                    amountForPayout +=
                        (player.amountBet * matchInfo.totalPayout) /
                        shares;
                } else if (matchInfo.winner == 4) {
                    amountForPayout += player.amountBet;
                }
            }
        }

        if (amountForPayout > 0) {
            amountWonByAccount[msg.sender] += amountForPayout;
            (bool success, ) = address(msg.sender).call{value: amountForPayout}(
                ""
            );
            require(success, "withdraw unsuccessful");
        }
    }

    function getAmountClaimableByMatchId(uint256 matchId, address account)
        external
        view
        returns (uint256)
    {
        MatchInfo storage matchInfo = matchInformation[matchId];
        Player storage player = matchInfo.players[account];
        if (
            closedMatches.contains(matchId) &&
            accountMatchesPending[account].contains(matchId)
        ) {
            if (player.winnerSelected == matchInfo.winner) {
                uint256 shares;
                if (matchInfo.winner == 1) {
                    shares = matchInfo.shareOfPlayersBettingA;
                } else if (matchInfo.winner == 2) {
                    shares = matchInfo.shareOfPlayersBettingB;
                } else {
                    shares = matchInfo.shareOfPlayersBettingDraw;
                }
                uint256 amountForPayout = (player.amountBet *
                    matchInfo.totalPayout) / shares;
                return amountForPayout;
            } else if (matchInfo.winner == 4) {
                uint256 amountForPayout = player.amountBet;
                return amountForPayout;
            }
        }
        return 0;
    }

    function getAmountTotalClaimable(address account)
        external
        view
        returns (uint256)
    {
        uint256[] memory matchIds = accountMatchesPending[account].values();
        uint256 amountForPayout;
        for (uint256 i = 0; i < matchIds.length; i++) {
            MatchInfo storage matchInfo = matchInformation[matchIds[i]];
            Player storage player = matchInfo.players[account];
            if (
                closedMatches.contains(matchIds[i]) &&
                accountMatchesPending[account].contains(matchIds[i])
            ) {
                uint256 shares;

                if (matchInfo.winner == 1) {
                    shares = matchInfo.shareOfPlayersBettingA;
                } else if (matchInfo.winner == 2) {
                    shares = matchInfo.shareOfPlayersBettingB;
                } else {
                    shares = matchInfo.shareOfPlayersBettingDraw;
                }

                if (player.winnerSelected == matchInfo.winner) {
                    amountForPayout +=
                        (player.amountBet * matchInfo.totalPayout) /
                        shares;
                } else if (matchInfo.winner == 4) {
                    amountForPayout += player.amountBet;
                }
            }
        }
        return amountForPayout;
    }

    function getMatchInfo(uint256 matchId)
        external
        view
        returns (
            string memory description,
            uint256 aShares,
            uint256 bShares,
            uint256 drawShares,
            uint256 totalPayout,
            bool active,
            uint256 winner
        )
    {
        MatchInfo storage matchInfo = matchInformation[matchId];
        description = matchInfo.description;
        aShares = matchInfo.shareOfPlayersBettingA;
        bShares = matchInfo.shareOfPlayersBettingB;
        drawShares = matchInfo.shareOfPlayersBettingDraw;
        totalPayout = matchInfo.totalPayout;
        active = matchInfo.active;
        winner = matchInfo.winner;
    }

    function getPlayerInfoByMatchId(uint256 matchId, address account)
        external
        view
        returns (uint256 amountBet, uint256 winnerSelected)
    {
        MatchInfo storage matchInfo = matchInformation[matchId];
        Player storage player = matchInfo.players[account];
        amountBet = player.amountBet;
        winnerSelected = player.winnerSelected;
    }

    function getActiveMatches() external view returns (uint256[] memory) {
        return activeMatches.values();
    }

    function getInactiveMatches() external view returns (uint256[] memory) {
        return closedMatches.values();
    }

    function getAccountMatchesPending(address account)
        external
        view
        returns (uint256[] memory)
    {
        return accountMatchesPending[account].values();
    }
}