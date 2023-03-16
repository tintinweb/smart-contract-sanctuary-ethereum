/**
 *Submitted for verification at Etherscan.io on 2023-03-16
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

    function name() external view returns (string memory);

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

contract KinaInuBetting is Ownable, ReentrancyGuard {
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(address => bool) public isAuthorized;

    EnumerableSet.AddressSet private activeTokens;
    EnumerableSet.AddressSet private closedTokens;
    mapping(address => uint256) public amountWonByAccount;
    mapping(address => mapping (address => uint256)) public tokenWinningsByAccount; // account => tokenAddress => amount
    mapping(address => mapping (address => uint256)) public tokenWinningsPendingByAccount; // account => tokenAddress => amount
    mapping(address => EnumerableSet.AddressSet) private accountMatchesPending;
    mapping(address => TokenInfo) private tokenInformation;
    mapping(uint256 => address) public tokenIndexToAddress;

    EnumerableSet.AddressSet private validTokens;
    mapping(address => uint256) public maxBetPerToken;

    address public feeReceiver;
    uint256 public feePercent = 400;

    uint256 public totalPayoutsPaid;
    uint256 public tokenIndex;
    uint256 public bettingTimeInSeconds = 172800; // In seconds

    struct Player {
        uint256 winnerSelected;
        uint256 amountBet;
    }

    struct TokenInfo {
        string description;
        string logoPath;
        uint256 eventStartTime;
        uint256 shareOfPlayersBettingRug;
        uint256 shareOfPlayersBettingNotRug;
        mapping(address => Player) players;
        uint256 totalPayout;
        uint256 winner;
        bool active;
        bool betInEth;
        address tokenBetAddress;
    }

    event MatchCreated(
        address indexed tokenId,
        string description,
        uint256 indexed eventStartTime
    );

    event PlayerBet(
        address indexed tokenId,
        address indexed walletAddress,
        uint256 indexed selection,
        uint256 amount
    );

    event TokenClosed(uint256 indexed tokenId);

    event PaidOut(bool isEth, address indexed player, uint256 amount);
    event PaidOutTokens(address token, address indexed player, uint256 amount);

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


    function addValidToken(address token) external onlyOwner {
        if(!validTokens.contains(token)){
            validTokens.add(token);
        } else {
            revert("Token already added!");
        }
    }

    function removeValidToken(address token) external onlyOwner {
        if(validTokens.contains(token)){
            validTokens.remove(token);
        } else {
            revert("Token already removed!");
        }
    }

    function setBettingTime(uint256 _bettingTimeInSeconds) external onlyOwner {
        require(bettingTimeInSeconds > 0, "Betting time cannot be 0");

        bettingTimeInSeconds = _bettingTimeInSeconds;
    }

    // note: A = 1, B = 2, Draw = 3
    function bet(address tokenId, uint256 willRug)
        external
        payable
        nonReentrant
    {
        TokenInfo storage tokenInfo = tokenInformation[tokenId];
        require(tokenInfo.betInEth, "Must bet in Tokens");
        require(msg.value >= 0 ether, "Cannot bet 0");
        require(msg.sender == tx.origin, "Contracts cannot play");
        
        require(
             tokenInfo.eventStartTime + (bettingTimeInSeconds * 1 seconds) > block.timestamp,
            "Cannot bet anymore"
        );
        Player storage player = tokenInfo.players[msg.sender];
        require(
            player.winnerSelected == 0,
            "Cannot select again or add more to bet"
        );
        require(
            willRug <= 2 && willRug != 0,
            "Can only select rug or not rug"
        );
        uint256 amountForBet = msg.value;

        // handle fees
        if (feePercent > 0) {
            bool success;
            uint256 amountForFee = (msg.value * feePercent) / 10000;
            (success, ) = address(feeReceiver).call{value: amountForFee}("");
            amountForBet -= amountForFee;
        }

        player.winnerSelected = willRug;
        player.amountBet = amountForBet;
        accountMatchesPending[msg.sender].add(tokenId);
        tokenInfo.totalPayout += amountForBet;

        if (willRug == 1) {
            tokenInfo.shareOfPlayersBettingRug += amountForBet;
        } else if (willRug == 2) {
            tokenInfo.shareOfPlayersBettingNotRug += amountForBet;
        }
        emit PlayerBet(tokenId, msg.sender, willRug, amountForBet);
    }

    // note: A = 1, B = 2, Draw = 3
    function betInTokens(address tokenId, uint256 willRug, uint256 amount)
        external
        nonReentrant
    {
        require(msg.sender == tx.origin, "Contracts cannot play");
        TokenInfo storage tokenInfo = tokenInformation[tokenId];
        require(!tokenInfo.betInEth, "Must bet in ETH");
        IERC20 bettingToken = IERC20(tokenInfo.tokenBetAddress);
        require(amount >= 0 ether, "Cannot bet 0");
        require(
            tokenInfo.eventStartTime + (bettingTimeInSeconds * 1 seconds) > block.timestamp,
            "Cannot bet anymore"
        );
        Player storage player = tokenInfo.players[msg.sender];
        require(
            player.winnerSelected == 0,
            "Cannot select again or add more to bet"
        );
        require(
            willRug <= 3 && willRug != 0,
            "Can only select team A, B, or Draw"
        );
        uint256 amountForBet = amount;

        // handle fees
        if (feePercent > 0) {
            uint256 amountForFee = (amount * feePercent) / 10000;
            bettingToken.transferFrom(msg.sender, feeReceiver, amountForFee);
            amountForBet -= amountForFee;
        }

        bettingToken.transferFrom(msg.sender, address(this), amountForBet);

        player.winnerSelected = willRug;
        player.amountBet = amountForBet;
        accountMatchesPending[msg.sender].add(tokenId);
        tokenInfo.totalPayout += amountForBet;

        if (willRug == 1) {
            tokenInfo.shareOfPlayersBettingRug += amountForBet;
        } else if (willRug == 2) {
            tokenInfo.shareOfPlayersBettingNotRug += amountForBet;
        }
        emit PlayerBet(tokenId, msg.sender, willRug, amountForBet);
    }

    // used to start a match
    function initializeNewToken(
        address tokenId,
        uint256 eventStartTime,
        bool betInEth,
        address tokenBetAddress,
        string memory logoUrl
    ) external onlyAuthorized {
        require(!activeTokens.contains(tokenId), "Match already created");
        require(eventStartTime > block.timestamp, "Match already started");
        activeTokens.add(tokenId);
        TokenInfo storage tokenInfo = tokenInformation[tokenId];
        tokenInfo.description = IERC20(tokenId).name();
        tokenInfo.active = true;
        tokenInfo.betInEth = betInEth;
        tokenInfo.logoPath = logoUrl;
        if(!betInEth){
            require(tokenBetAddress != address(0), "cannot set token to address 0");
            require(validTokens.contains(tokenBetAddress), "invalid token");
            tokenInfo.tokenBetAddress = tokenBetAddress;
        }
        tokenInfo.eventStartTime = eventStartTime;
        tokenIndex++;
        tokenIndexToAddress[tokenIndex] = tokenId;
        emit MatchCreated(tokenId, tokenInfo.description, eventStartTime);
    }

    function initializeNewTokens(
        address[] calldata tokenId,
        uint256[] calldata eventStartTime,
        bool[] calldata betInEth,
        address[] calldata tokenBetAddress
    ) external onlyAuthorized {
        require(tokenId.length == eventStartTime.length, "array length mismatch");
        for(uint256 i = 0; i < tokenId.length; i++){
            require(!activeTokens.contains(tokenId[i]), "Match already created");
            require(eventStartTime[i] > block.timestamp, "Match already started");
            activeTokens.add(tokenId[i]);
            TokenInfo storage tokenInfo = tokenInformation[tokenId[i]];
            tokenInfo.description = IERC20(tokenId[i]).name();
            tokenInfo.active = true;
            tokenInfo.betInEth = betInEth[i];
            if(!betInEth[i]){
                require(tokenBetAddress[i] != address(0), "cannot set token to address 0");
                require(validTokens.contains(tokenBetAddress[i]), "invalid token");
                tokenInfo.tokenBetAddress = tokenBetAddress[i];
            }
            tokenIndex++;
            tokenIndexToAddress[tokenIndex] = tokenId[i];
            tokenInfo.eventStartTime = eventStartTime[i];
            emit MatchCreated(tokenId[i], tokenInfo.description, eventStartTime[i]);
        }
    }

    // note: Rug = 1, Not Rug = 2

    function setWinner(address tokenId, uint256 winner)
        external
        onlyAuthorized
    {
        TokenInfo storage tokenInfo = tokenInformation[tokenId];
        require(activeTokens.contains(tokenId), "Match is closed");
        require(
            winner <= 3 && winner != 0,
            "Can only select Rug, Not Rug, or Cancelled"
        );
        tokenInfo.winner = winner;

        uint256 shares;
        if (tokenInfo.winner == 1) {
            shares = tokenInfo.shareOfPlayersBettingRug;
        } else if (tokenInfo.winner == 2) {
            shares = tokenInfo.shareOfPlayersBettingNotRug;
        } else if (tokenInfo.winner == 3) {
            shares = tokenInfo.totalPayout;
        }

        // in the rare case of NO winners, fee receiver takes pool
        if (shares == 0 && tokenInfo.totalPayout > 0) {
            if(tokenInfo.betInEth){
                (bool success, ) = address(feeReceiver).call{
                    value: tokenInfo.totalPayout
                }("");
                require(success, "failed to process payment to fee receiver");
            } else {
                IERC20 bettingToken = IERC20(tokenInfo.tokenBetAddress);
                bettingToken.transferFrom(address(this), feeReceiver, tokenInfo.totalPayout);
            }
        }

        activeTokens.remove(tokenId);
        closedTokens.add(tokenId);
        tokenInfo.active = false;
    }

    function cashOut(address tokenId) external nonReentrant {
        require(msg.sender == tx.origin, "Contracts cannot play");
        bool success;
        TokenInfo storage tokenInfo = tokenInformation[tokenId];
        Player storage player = tokenInfo.players[msg.sender];
        if (
            closedTokens.contains(tokenId) &&
            accountMatchesPending[msg.sender].contains(tokenId)
        ) {
            accountMatchesPending[msg.sender].remove(tokenId);

            if (player.winnerSelected == tokenInfo.winner) {
                uint256 shares;
                if (tokenInfo.winner == 1) {
                    shares = tokenInfo.shareOfPlayersBettingRug;
                } else if (tokenInfo.winner == 2) {
                    shares = tokenInfo.shareOfPlayersBettingNotRug;
                }

                uint256 amountForPayout = (player.amountBet *
                    tokenInfo.totalPayout) / shares;
                
                if (amountForPayout > 0) {
                    if(tokenInfo.betInEth){
                        amountWonByAccount[msg.sender] += amountForPayout;
                        (success, ) = address(msg.sender).call{
                            value: amountForPayout
                        }("");
                        require(success, "withdraw unsuccessful");
                    } else {
                        IERC20 bettingToken = IERC20(tokenInfo.tokenBetAddress);
                        bettingToken.transferFrom(address(this), msg.sender, amountForPayout);
                        tokenWinningsByAccount[msg.sender][tokenInfo.tokenBetAddress] += amountForPayout;
                        emit PaidOutTokens(tokenInfo.tokenBetAddress, msg.sender, amountForPayout);
                    }
                }
            } else if (tokenInfo.winner == 3 && player.amountBet > 0) {
                if(tokenInfo.betInEth){
                    amountWonByAccount[msg.sender] += player.amountBet;
                    (success, ) = address(msg.sender).call{value: player.amountBet}(
                        ""
                    );
                    require(success, "withdraw unsuccessful");
                } else {
                    IERC20 bettingToken = IERC20(tokenInfo.tokenBetAddress);
                    bettingToken.transferFrom(address(this), msg.sender, player.amountBet);
                    tokenWinningsByAccount[msg.sender][tokenInfo.tokenBetAddress] += player.amountBet;
                }
            }
        }
    }

    function cashOutAll() external nonReentrant {
        require(msg.sender == tx.origin, "Contracts cannot play");
        address[] memory tokenIds = accountMatchesPending[msg.sender].values();
        uint256 amountForPayout;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            TokenInfo storage tokenInfo = tokenInformation[tokenIds[i]];
            Player storage player = tokenInfo.players[msg.sender];

            if (
                closedTokens.contains(tokenIds[i]) &&
                accountMatchesPending[msg.sender].contains(tokenIds[i])
            ) {
                accountMatchesPending[msg.sender].remove(tokenIds[i]);

                uint256 shares;
                if (tokenInfo.winner == 1) {
                    shares = tokenInfo.shareOfPlayersBettingRug;
                } else if (tokenInfo.winner == 2) {
                    shares = tokenInfo.shareOfPlayersBettingNotRug;
                }

                if (player.winnerSelected == tokenInfo.winner) {
                    if(tokenInfo.betInEth){
                        amountForPayout +=
                            (player.amountBet * tokenInfo.totalPayout) /
                            shares;
                    } else {
                        tokenWinningsPendingByAccount[msg.sender][tokenInfo.tokenBetAddress] += 
                            (player.amountBet * tokenInfo.totalPayout) / 
                            shares;
                    }
                } else if (tokenInfo.winner == 3) {
                    if(tokenInfo.betInEth){
                        amountForPayout += player.amountBet;
                    } else {
                        tokenWinningsPendingByAccount[msg.sender][tokenInfo.tokenBetAddress] += 
                            player.amountBet;
                    }
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

        address[] memory tokens = validTokens.values();
        uint256 tokenPayout;
        
        for(uint256 i = 0; i < tokens.length; i++){
            tokenPayout = tokenWinningsPendingByAccount[msg.sender][tokens[i]];
            if(tokenPayout > 0){
                tokenWinningsByAccount[msg.sender][tokens[i]] += tokenPayout;
                tokenWinningsPendingByAccount[msg.sender][tokens[i]] = 0;
                IERC20(tokens[i]).transfer(msg.sender, tokenPayout);
                emit PaidOutTokens(tokens[i], msg.sender, tokenPayout);
            }
        }
    }

    function getAmountClaimableByTokenId(address tokenId, address account)
        external
        view
        returns (uint256)
    {
        TokenInfo storage tokenInfo = tokenInformation[tokenId];
        Player storage player = tokenInfo.players[account];
        if (
            closedTokens.contains(tokenId) &&
            accountMatchesPending[account].contains(tokenId)
        ) {
            if (player.winnerSelected == tokenInfo.winner) {
                uint256 shares;
                if (tokenInfo.winner == 1) {
                    shares = tokenInfo.shareOfPlayersBettingRug;
                } else if (tokenInfo.winner == 2) {
                    shares = tokenInfo.shareOfPlayersBettingNotRug;
                }
                uint256 amountForPayout = (player.amountBet *
                    tokenInfo.totalPayout) / shares;
                return amountForPayout;
            } else if (tokenInfo.winner == 3) {
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
        address[] memory tokenIds = accountMatchesPending[account].values();
        uint256 amountForPayout;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            TokenInfo storage tokenInfo = tokenInformation[tokenIds[i]];
            Player storage player = tokenInfo.players[account];
            if (
                closedTokens.contains(tokenIds[i]) &&
                accountMatchesPending[account].contains(tokenIds[i])
            ) {
                uint256 shares;

                if (tokenInfo.winner == 1) {
                    shares = tokenInfo.shareOfPlayersBettingRug;
                } else if (tokenInfo.winner == 2) {
                    shares = tokenInfo.shareOfPlayersBettingNotRug;
                }

                if (player.winnerSelected == tokenInfo.winner) {
                    amountForPayout +=
                        (player.amountBet * tokenInfo.totalPayout) /
                        shares;
                } else if (tokenInfo.winner == 3) {
                    amountForPayout += player.amountBet;
                }
            }
        }
        return amountForPayout;
    }

    function getTokenInfo(address tokenId)
        external
        view
        returns (
            string memory description,
            uint256 eventStart,
            uint256 rugShares,
            uint256 notRugShares,
            uint256 totalPayout,
            bool active,
            uint256 winner,
            bool isEth,
            address bettingToken,
            string memory logoPath
        )
    {
        TokenInfo storage tokenInfo = tokenInformation[tokenId];
        description = tokenInfo.description;
        eventStart = tokenInfo.eventStartTime;
        rugShares = tokenInfo.shareOfPlayersBettingRug;
        notRugShares = tokenInfo.shareOfPlayersBettingNotRug;
        totalPayout = tokenInfo.totalPayout;
        active = tokenInfo.active;
        winner = tokenInfo.winner;
        isEth = tokenInfo.betInEth;
        bettingToken = tokenInfo.tokenBetAddress;
        logoPath = tokenInfo.logoPath;
    }

    function getPlayerInfoByTokenId(address tokenId, address account)
        external
        view
        returns (uint256 amountBet, uint256 winnerSelected)
    {
        TokenInfo storage tokenInfo = tokenInformation[tokenId];
        Player storage player = tokenInfo.players[account];
        amountBet = player.amountBet;
        winnerSelected = player.winnerSelected;
    }

    function getActiveMatches() external view returns (address[] memory) {
        return activeTokens.values();
    }

    function getInactiveTokens() external view returns (address[] memory) {
        return closedTokens.values();
    }

    function getAccountMatchesPending(address account)
        external
        view
        returns (address[] memory)
    {
        return accountMatchesPending[account].values();
    }
    
    function getValidTokens() 
        external 
        view 
        returns (address[] memory)
    {
        return validTokens.values();
    }
}