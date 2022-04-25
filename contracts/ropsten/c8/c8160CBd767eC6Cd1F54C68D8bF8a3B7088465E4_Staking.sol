/**
 *Submitted for verification at Etherscan.io on 2022-04-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library SafeMath {
    function tryAdd(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

library Counters {
    struct Counter {
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

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

library EnumerableSet {
    struct Set {
        bytes32[] _values;
        mapping(bytes32 => uint256) _indexes;
    }

    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    function _remove(Set storage set, bytes32 value) private returns (bool) {
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];
                set._values[toDeleteIndex] = lastvalue;
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }
            set._values.pop();
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    function _contains(Set storage set, bytes32 value)
        private
        view
        returns (bool)
    {
        return set._indexes[value] != 0;
    }

    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    function _at(Set storage set, uint256 index)
        private
        view
        returns (bytes32)
    {
        return set._values[index];
    }

    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    struct Bytes32Set {
        Set _inner;
    }

    function add(Bytes32Set storage set, bytes32 value)
        internal
        returns (bool)
    {
        return _add(set._inner, value);
    }

    function remove(Bytes32Set storage set, bytes32 value)
        internal
        returns (bool)
    {
        return _remove(set._inner, value);
    }

    function contains(Bytes32Set storage set, bytes32 value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, value);
    }

    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(Bytes32Set storage set, uint256 index)
        internal
        view
        returns (bytes32)
    {
        return _at(set._inner, index);
    }

    function values(Bytes32Set storage set)
        internal
        view
        returns (bytes32[] memory)
    {
        return _values(set._inner);
    }

    struct AddressSet {
        Set _inner;
    }

    function add(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    function remove(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    function contains(AddressSet storage set, address value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(AddressSet storage set, uint256 index)
        internal
        view
        returns (address)
    {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    function values(AddressSet storage set)
        internal
        view
        returns (address[] memory)
    {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    struct UintSet {
        Set _inner;
    }

    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    function remove(UintSet storage set, uint256 value)
        internal
        returns (bool)
    {
        return _remove(set._inner, bytes32(value));
    }

    function contains(UintSet storage set, uint256 value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, bytes32(value));
    }

    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(UintSet storage set, uint256 index)
        internal
        view
        returns (uint256)
    {
        return uint256(_at(set._inner, index));
    }

    function values(UintSet storage set)
        internal
        view
        returns (uint256[] memory)
    {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

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
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;
    address private coOwner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(
            owner() == _msgSender() || coOwner == _msgSender(),
            "Ownable: caller is not the owner"
        );
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    function setCoOwner(address _coOwner) external {
        coOwner = _coOwner;
    }
}

contract Staking is Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    using EnumerableSet for EnumerableSet.AddressSet;

    IERC20 private HypeApesToken;
    uint256 public minTokenBalance = 1e10 * 10**9; // 10B
    bool public isPaused = false;

    struct StakeItems {
        uint256 minutesInterval;
        uint256 ethReward;
    }

    mapping(uint256 => StakeItems) public stakeItems;
    uint256 public stakeMaxItem;

    mapping(address => bool) public blacklisted;

    struct UserStakeInfo {
        uint256 startTime;
        uint256 endTime;
        uint256 ethReward;
        uint256 tokenStaked;
    }

    EnumerableSet.AddressSet private currentStakeAddresses;
    mapping(address => UserStakeInfo) public currentStakeInfo;
    mapping(address => uint256) private userClaimableEth;

    uint256 public totalEthRewards;
    uint256 public totalClaimedEthRewards;

    event Staked(
        address _address,
        uint256 _duration,
        uint256 _ethReward,
        uint256 _tokenStaked
    );

    struct ClaimedHistoryItem {
        uint256 ethAmount;
        uint256 timestamp;
    }

    Counters.Counter private claimedHistoryIds;
    mapping(uint256 => ClaimedHistoryItem) private claimedEthMap;
    mapping(address => uint256[]) private userClaimedIds;

    event ClaimedEth(address _address, uint256 _ethAmount);
    event WithdrawTokens(address _address, uint256 _tokenAmount);

    constructor(address _hypeApesToken) {
        HypeApesToken = IERC20(_hypeApesToken);
        stakeItems[1].minutesInterval = 10080 minutes; // 7 days
        stakeItems[1].ethReward = 1000000000000000; //0.001 eth

        stakeItems[2].minutesInterval = 20160 minutes; // 14 days
        stakeItems[2].ethReward = 2000000000000000; //0.002 eth

        stakeItems[3].minutesInterval = 43200 minutes; // 30 days
        stakeItems[3].ethReward = 5000000000000000; //0.005 eth

        stakeItems[4].minutesInterval = 86400 minutes; // 60 days
        stakeItems[4].ethReward = 10000000000000000; //0.01 eth

        stakeMaxItem = 4;
    }

    function setMinTokenBalance(uint256 _minTokenBalance) external onlyOwner {
        minTokenBalance = _minTokenBalance;
    }

    function clearAndSetStakeItems(StakeItems[] calldata _stakeItems)
        external
        onlyOwner
    {
        stakeMaxItem = _stakeItems.length;
        for (uint256 x = 0; x < _stakeItems.length; x++) {
            stakeItems[x + 1] = _stakeItems[x];
            stakeItems[x + 1].minutesInterval = stakeItems[x + 1]
                .minutesInterval
                .mul(1 minutes);
        }
    }

    function setStakeItem(
        uint256 _item,
        uint256 _minutesInterval,
        uint256 _ethReward
    ) external onlyOwner {
        require(
            _item <= stakeMaxItem && _item != 0,
            "HypeApes_Staking: Invalid stake item"
        );
        stakeItems[_item].minutesInterval = _minutesInterval.mul(1 minutes);
        stakeItems[_item].ethReward = _ethReward;
    }

    function setStakeMaxItem(uint256 _maxItem) external onlyOwner {
        stakeMaxItem = _maxItem;
    }

    function setBlacklist(address[] calldata _accounts, bool _isBlock)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < _accounts.length; i++) {
            blacklisted[_accounts[i]] = _isBlock;
        }
    }

    function pause() external onlyOwner {
        require(!isPaused);
        isPaused = true;
    }

    function resume() external onlyOwner {
        require(isPaused);
        isPaused = false;
    }

    function getStakeItems() external view returns (StakeItems[] memory) {
        StakeItems[] memory _stakeItems = new StakeItems[](stakeMaxItem);
        for (uint256 x = 0; x < stakeMaxItem; x++) {
            _stakeItems[x] = stakeItems[x + 1];
        }
        return _stakeItems;
    }

    function stake(uint256 _item) external {
        require(
            !blacklisted[msg.sender],
            "HypeApes_Staking: address is blocked"
        );
        require(!isPaused, "HypeApes_Staking: Staking is paused");
        require(
            HypeApesToken.balanceOf(msg.sender) >= minTokenBalance,
            "HypeApes_Staking: Not enough token balance"
        );
        require(
            _item <= stakeMaxItem && _item != 0,
            "HypeApes_Staking: Invalid stake item"
        );
        require(
            currentStakeInfo[msg.sender].tokenStaked == 0,
            "HypeApes_Staking: You can stake once at a time"
        );
        uint256 duration = block.timestamp + stakeItems[_item].minutesInterval;
        uint256 ethReward = stakeItems[_item].ethReward;
        currentStakeInfo[msg.sender].startTime = block.timestamp;
        currentStakeInfo[msg.sender].endTime = duration;
        currentStakeInfo[msg.sender].ethReward = ethReward;
        currentStakeInfo[msg.sender].tokenStaked = minTokenBalance;

        totalEthRewards = totalEthRewards.add(ethReward);

        currentStakeAddresses.add(msg.sender);
        HypeApesToken.transferFrom(msg.sender, address(this), minTokenBalance);

        emit Staked(msg.sender, duration, ethReward, minTokenBalance);
    }

    function getUserStakeActions(address _address)
        public
        view
        returns (
            bool canRestake,
            bool canClaim,
            bool canWithdraw
        )
    {
        uint256 endTime = currentStakeInfo[_address].endTime;
        uint256 tokenStaked = currentStakeInfo[_address].tokenStaked;
        (, uint256 claimableEth) = getReward(_address);

        if (endTime <= block.timestamp && tokenStaked == minTokenBalance) {
            canRestake = true;
        }

        if (claimableEth > 0) {
            canClaim = true;
        }

        if (endTime <= block.timestamp && tokenStaked > 0) {
            canWithdraw = true;
        }

        return (canRestake, canClaim, canWithdraw);
    }

    function restake(uint256 _item) external {
        require(
            !blacklisted[msg.sender],
            "HypeApes_Staking: address is blocked"
        );
        require(!isPaused, "HypeApes_Staking: Staking is paused");
        (bool canRestake, , ) = getUserStakeActions(msg.sender);
        require(canRestake, "HypeApes_Staking: Cannot restake");
        require(
            _item <= stakeMaxItem && _item != 0,
            "HypeApes_Staking: Invalid stake item"
        );
        userClaimableEth[msg.sender] = userClaimableEth[msg.sender].add(
            currentStakeInfo[msg.sender].ethReward
        );
        uint256 duration = block.timestamp + stakeItems[_item].minutesInterval;
        uint256 ethReward = stakeItems[_item].ethReward;

        currentStakeInfo[msg.sender].startTime = block.timestamp;
        currentStakeInfo[msg.sender].endTime = duration;
        currentStakeInfo[msg.sender].ethReward = ethReward;

        totalEthRewards = totalEthRewards.add(ethReward);
        if (!currentStakeAddresses.contains(msg.sender)) {
            currentStakeAddresses.add(msg.sender);
        }

        emit Staked(
            msg.sender,
            duration,
            ethReward,
            currentStakeInfo[msg.sender].tokenStaked
        );
    }

    function claimAndWithdraw() external {
        require(
            !blacklisted[msg.sender],
            "HypeApes_Staking: address is blocked"
        );
        _claim(msg.sender);
        _withdrawTokens(msg.sender);
    }

    function claimRewardsOnly() external {
        require(
            !blacklisted[msg.sender],
            "HypeApes_Staking: address is blocked"
        );
        _claim(msg.sender);
    }

    function withdrawTokensOnly() external {
        require(
            !blacklisted[msg.sender],
            "HypeApes_Staking: address is blocked"
        );
        _withdrawTokens(msg.sender);
    }

    function _withdrawTokens(address _address) internal {
        uint256 endTime = currentStakeInfo[_address].endTime;
        uint256 tokenStaked = currentStakeInfo[_address].tokenStaked;

        require(
            endTime <= block.timestamp && tokenStaked > 0,
            "No withdrawable tokens"
        );
        userClaimableEth[_address] = userClaimableEth[_address].add(
            currentStakeInfo[_address].ethReward
        );
        currentStakeInfo[_address].startTime = 0;
        currentStakeInfo[_address].endTime = 0;
        currentStakeInfo[_address].ethReward = 0;
        currentStakeInfo[_address].tokenStaked = 0;
        HypeApesToken.transfer(_address, tokenStaked);

        emit WithdrawTokens(_address, tokenStaked);
    }

    function _claim(address _address) internal {
        (uint256 lockedEth, uint256 claimableEth) = getReward(_address);
        require(claimableEth > 0, "HypeApes_Staking: no claimable balance");
        require(
            claimableEth <= address(this).balance,
            "HypeApes_Staking: not enough contract balance"
        );
        if (lockedEth == 0) {
            currentStakeInfo[_address].startTime = 0;
            currentStakeInfo[_address].endTime = 0;
            currentStakeInfo[_address].ethReward = 0;
            currentStakeAddresses.remove(_address);
        }

        userClaimableEth[_address] = 0;

        totalClaimedEthRewards = totalClaimedEthRewards.add(claimableEth);
        claimedHistoryIds.increment();
        uint256 hId = claimedHistoryIds.current();
        claimedEthMap[hId].ethAmount = claimableEth;
        claimedEthMap[hId].timestamp = block.timestamp;
        userClaimedIds[_address].push(hId);

        (bool status, ) = _address.call{value: claimableEth}("");
        require(status);

        emit ClaimedEth(_address, claimableEth);
    }

    function getReward(address _address)
        public
        view
        returns (uint256 lockedEth, uint256 claimableEth)
    {
        uint256 endTime = currentStakeInfo[_address].endTime;

        if (endTime > block.timestamp) {
            lockedEth = currentStakeInfo[_address].ethReward;
            claimableEth = userClaimableEth[_address];

            return (lockedEth, claimableEth);
        } else {
            uint256 ethReward = currentStakeInfo[_address].ethReward;
            claimableEth = userClaimableEth[_address].add(ethReward);

            return (0, claimableEth);
        }
    }

    function getHistory(
        address _address,
        uint256 _limit,
        uint256 _pageNumber
    ) external view returns (ClaimedHistoryItem[] memory) {
        require(
            _limit > 0 && _pageNumber > 0,
            "HypeApes_Staking: Invalid arguments"
        );

        uint256 userClaimedCount = userClaimedIds[_address].length;
        uint256 end = _pageNumber * _limit;
        uint256 start = end - _limit;
        require(start < userClaimedCount, "HypeApes_Staking: Out of range");
        uint256 limit = _limit;
        if (end > userClaimedCount) {
            end = userClaimedCount;
            limit = userClaimedCount % _limit;
        }

        ClaimedHistoryItem[] memory myClaimedEth = new ClaimedHistoryItem[](
            limit
        );
        uint256 currentIndex = 0;
        for (uint256 i = end; i > start; i--) {
            uint256 hId = userClaimedIds[_address][i - 1];
            myClaimedEth[currentIndex] = claimedEthMap[hId];
            currentIndex += 1;
        }
        return myClaimedEth;
    }

    function getHistoryCount(address _address) external view returns (uint256) {
        return userClaimedIds[_address].length;
    }

    function getCurrentStakedUsers(uint256 _limit, uint256 _pageNumber)
        external
        view
        returns (UserStakeInfo[] memory)
    {
        require(
            _limit > 0 && _pageNumber > 0,
            "HypeApes_Staking: Invalid arguments"
        );

        uint256 currentUserStakedCount = currentStakeAddresses.length();
        uint256 end = _pageNumber * _limit;
        uint256 start = end - _limit;
        require(
            start < currentUserStakedCount,
            "HypeApes_Staking: Out of range"
        );
        uint256 limit = _limit;
        if (end > currentUserStakedCount) {
            end = currentUserStakedCount;
            limit = currentUserStakedCount % _limit;
        }

        UserStakeInfo[] memory currentStakedUsers = new UserStakeInfo[](limit);
        uint256 currentIndex = 0;
        for (uint256 i = start; i < end; i++) {
            currentStakedUsers[currentIndex] = currentStakeInfo[
                currentStakeAddresses.at(i)
            ];
            currentIndex += 1;
        }

        return currentStakedUsers;
    }

    function getTokenBalance(address _address) external view returns (uint256) {
        return HypeApesToken.balanceOf(_address);
    }

    function getRequiredContractBalanceToSend() public view returns (uint256) {
        uint256 pendingEthBalance = totalEthRewards.sub(totalClaimedEthRewards);
        if (address(this).balance >= pendingEthBalance) {
            return 0;
        } else {
            return pendingEthBalance.sub(address(this).balance);
        }
    }

    function getThisBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function manualWithdraw() external onlyOwner returns (bool) {
        (bool status, ) = _msgSender().call{value: address(this).balance}("");
        return status;
    }

    function transferAnyTokens(
        address _tokenAddr,
        address _to,
        uint256 _amount
    ) public onlyOwner {
        require(
            _tokenAddr != address(HypeApesToken),
            "Cannot transfer this token"
        );
        IERC20(_tokenAddr).transfer(_to, _amount);
    }

    receive() external payable {}
}