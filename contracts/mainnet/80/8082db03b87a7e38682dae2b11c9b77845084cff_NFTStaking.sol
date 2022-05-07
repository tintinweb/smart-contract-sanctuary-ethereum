/**
 *Submitted for verification at Etherscan.io on 2022-05-07
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

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721 is IERC165 {
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function approve(address to, uint256 tokenId) external;

    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

    function setApprovalForAll(address operator, bool _approved) external;

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
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
    address private _coOwner;

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

    function coOwner() public view virtual returns (address) {
        return _coOwner;
    }

    modifier onlyOwner() {
        require(
            owner() == _msgSender() || coOwner() == _msgSender(),
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

    function setCoOwner(address newCoOwner) external {
        _coOwner = newCoOwner;
    }
}

contract NFTStaking is Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.AddressSet private blacklisted;

    IERC20 public DurhamInuToken;
    bool public isPaused = false;

    EnumerableSet.AddressSet private allowedNfts;

    struct StakedNft {
        uint256 nftId;
        address nftAddress;
    }
    struct StakeItem {
        uint256 stakedTokens;
        StakedNft stakedNft;
        EnumerableSet.UintSet raffleIds;
        bool isStaked;
        uint256 lastUpdated;
    }

    mapping(address => StakeItem) private currentStakeInfo;
    mapping(uint256 => address) public raffleEntries;
    EnumerableSet.UintSet private removedRaffleIds;

    EnumerableSet.AddressSet private stakedAddresses;

    Counters.Counter private raffleIds;

    uint256 public minToken = 1e5 * 10**18; // 100K tokens, 1 entry per minimum tokens
    uint256 public maxQty = 10; // qty * minToken

    uint8 public entryPerMinToken = 1;
    uint8 public entryPerNft = 5;

    struct PrizeItem {
        bool isTangible;
        string name;
        string desc;
        string imageUrl;
        uint256 ethReward;
        uint256 requiredPoints;
    }

    mapping(uint256 => PrizeItem) private prizeItems;
    uint256 private prizeLength;

    struct ClaimedHistoryItem {
        address userAddress;
        string email;
        bool isTangible;
        string name;
        string desc;
        uint256 ethReward;
        uint256 requiredPoints;
        uint256 timestamp;
    }
    Counters.Counter private claimedHistoryIds;
    mapping(uint256 => ClaimedHistoryItem) private claimedHistoryMap;
    mapping(address => uint256[]) private userClaimedIds;

    struct WinnerHistoryItem {
        address userAddress;
        uint256 rewardPoints;
        uint256 timestamp;
    }
    mapping(uint256 => WinnerHistoryItem) private WinnerHistories;
    Counters.Counter private winnerIds;

    mapping(address => uint256) private rewardPointBalance;

    Counters.Counter public totalTangibleClaims;
    Counters.Counter public totalNonTangibleClaims;
    struct Staker {
        address userAddress;
        uint256 stakedTokens;
        uint256 nftId;
        address nftAddress;
        uint256 noOfEntries;
        bool isStaked;
        uint256 lastUpdated;
    }

    event StakeTokens(address _address, uint256 _tokenAmount);
    event StakeNFT(address _address, uint256 _tokenId, uint256 _tokenAddress);
    event UnStake(address _address);
    event ClaimPrize(address _address, uint256 _prizeItem);

    constructor(address _durhamInuTokenAddress, address[] memory _allowedNfts) {
        DurhamInuToken = IERC20(_durhamInuTokenAddress);

        for (uint256 i = 0; i < _allowedNfts.length; i++) {
            allowedNfts.add(_allowedNfts[i]);
        }
    }

    function setEntryPerNFT(uint8 _entryPerNFT) external onlyOwner {
        require(_entryPerNFT > 0);
        entryPerNft = _entryPerNFT;
    }

    function setAllowableNFts(address[] calldata _nftAddress, bool _isAllowed)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < _nftAddress.length; i++) {
            if (_isAllowed && !allowedNfts.contains(_nftAddress[i])) {
                allowedNfts.add(_nftAddress[i]);
            } else if (!_isAllowed && allowedNfts.contains(_nftAddress[i])) {
                allowedNfts.remove(_nftAddress[i]);
            }
        }
    }

    function setTokenStakeSettings(
        uint256 _minToken,
        uint256 _maxQty,
        uint8 _entryPerMinToken
    ) external onlyOwner {
        require(_minToken > 0 && _maxQty > 0 && _entryPerMinToken > 0);
        minToken = _minToken;
        maxQty = _maxQty;
        entryPerMinToken = _entryPerMinToken;
    }

    function clearAndSetPrizes(PrizeItem[] calldata _prizeItems)
        external
        onlyOwner
    {
        prizeLength = _prizeItems.length;
        for (uint256 x = 0; x < prizeLength; x++) {
            if (_prizeItems[x].isTangible) {
                require(
                    _prizeItems[x].ethReward == 0,
                    "Durham_Inu_Staking: ETH reward must be 0 for tangible prize"
                );
            } else {
                require(
                    _prizeItems[x].ethReward > 0,
                    "Durham_Inu_Staking:  ETH reward must be greater than 0 for non-tangible prize"
                );
            }
            prizeItems[x + 1] = _prizeItems[x];
        }
    }

    function getAllowedNfts() external view returns (address[] memory) {
        return allowedNfts.values();
    }

    function getPrizeList() external view returns (PrizeItem[] memory) {
        PrizeItem[] memory prizeList = new PrizeItem[](prizeLength);
        for (uint256 x = 0; x < prizeLength; x++) {
            prizeList[x] = prizeItems[x + 1];
        }
        return prizeList;
    }

    function getUserCurrentStakeInfo(address _address)
        external
        view
        returns (Staker memory staker)
    {
        staker.userAddress = _address;
        staker.stakedTokens = currentStakeInfo[_address].stakedTokens;
        staker.nftId = currentStakeInfo[_address].stakedNft.nftId;
        staker.nftAddress = currentStakeInfo[_address].stakedNft.nftAddress;
        staker.noOfEntries = currentStakeInfo[_address].raffleIds.length();
        staker.isStaked = currentStakeInfo[_address].isStaked;
        staker.lastUpdated = currentStakeInfo[_address].lastUpdated;
    }

    function getAllCurrentStakers(uint256 _limit, uint256 _pageNumber)
        external
        view
        onlyOwner
        returns (Staker[] memory)
    {
        require(
            _limit > 0 && _pageNumber > 0,
            "Durham_Inu_Staking: Invalid arguments"
        );

        uint256 stakerCount = stakedAddresses.length();
        uint256 end = _pageNumber * _limit;
        uint256 start = end - _limit;
        require(start < stakerCount, "Durham_Inu_Staking: Out of range");
        uint256 limit = _limit;
        if (end > stakerCount) {
            end = stakerCount;
            limit = stakerCount % _limit;
        }

        Staker[] memory stakers = new Staker[](limit);
        uint256 currentIndex = 0;
        for (uint256 i = start; i < end; i++) {
            stakers[currentIndex].userAddress = stakedAddresses.at(i);
            stakers[currentIndex].stakedTokens = currentStakeInfo[
                stakedAddresses.at(i)
            ].stakedTokens;

            stakers[currentIndex].nftId = currentStakeInfo[
                stakedAddresses.at(i)
            ].stakedNft.nftId;
            stakers[currentIndex].nftAddress = currentStakeInfo[
                stakedAddresses.at(i)
            ].stakedNft.nftAddress;
            stakers[currentIndex].noOfEntries = currentStakeInfo[
                stakedAddresses.at(i)
            ].raffleIds.length();
            stakers[currentIndex].isStaked = currentStakeInfo[
                stakedAddresses.at(i)
            ].isStaked;
            stakers[currentIndex].lastUpdated = currentStakeInfo[
                stakedAddresses.at(i)
            ].lastUpdated;

            currentIndex += 1;
        }
        return stakers;
    }

    function getCurrentStakersCount() external view returns (uint256) {
        return stakedAddresses.length();
    }

    function getRewardPointsBalance(address _address)
        external
        view
        returns (uint256)
    {
        return rewardPointBalance[_address];
    }

    function getUserStatus(address _address)
        external
        view
        returns (
            bool canStake,
            bool canUnStake,
            bool canClaim
        )
    {
        canStake = !currentStakeInfo[_address].isStaked;
        canUnStake = currentStakeInfo[_address].isStaked;
        canClaim = rewardPointBalance[_address] > 0;
    }

    function getWinnerHistory(uint256 _limit, uint256 _pageNumber)
        external
        view
        returns (WinnerHistoryItem[] memory)
    {
        require(
            _limit > 0 && _pageNumber > 0,
            "Durham_Inu_Staking: Invalid arguments"
        );

        uint256 winnerCount = winnerIds.current();
        uint256 end = _pageNumber * _limit;
        uint256 start = end - _limit;
        require(start < winnerCount, "Durham_Inu_Staking: Out of range");
        uint256 limit = _limit;
        if (end > winnerCount) {
            end = winnerCount;
            limit = winnerCount % _limit;
        }

        WinnerHistoryItem[] memory winners = new WinnerHistoryItem[](limit);
        uint256 currentIndex = 0;
        for (uint256 i = end; i > start; i--) {
            winners[currentIndex] = WinnerHistories[i];
            currentIndex += 1;
        }
        return winners;
    }

    function getWinnersCount() external view returns (uint256) {
        return winnerIds.current();
    }

    function getUserClaimedHistory(
        address _address,
        uint256 _limit,
        uint256 _pageNumber
    ) external view returns (ClaimedHistoryItem[] memory) {
        require(
            _limit > 0 && _pageNumber > 0,
            "Durham_Inu_Staking: Invalid arguments"
        );

        uint256 userClaimedCount = userClaimedIds[_address].length;
        uint256 end = _pageNumber * _limit;
        uint256 start = end - _limit;
        require(start < userClaimedCount, "Durham_Inu_Staking: Out of range");
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
            myClaimedEth[currentIndex] = claimedHistoryMap[hId];
            currentIndex += 1;
        }
        return myClaimedEth;
    }

    function getUserClaimedHistoryCount(address _address)
        external
        view
        returns (uint256)
    {
        return userClaimedIds[_address].length;
    }

    function getAllClaimedHistory(uint256 _limit, uint256 _pageNumber)
        external
        view
        returns (ClaimedHistoryItem[] memory)
    {
        require(
            _limit > 0 && _pageNumber > 0,
            "Durham_Inu_Staking: Invalid arguments"
        );

        uint256 claimedCount = claimedHistoryIds.current();
        uint256 end = _pageNumber * _limit;
        uint256 start = end - _limit;
        require(start < claimedCount, "Durham_Inu_Staking: Out of range");
        uint256 limit = _limit;
        if (end > claimedCount) {
            end = claimedCount;
            limit = claimedCount % _limit;
        }

        ClaimedHistoryItem[] memory claims = new ClaimedHistoryItem[](limit);
        uint256 currentIndex = 0;
        for (uint256 i = end; i > start; i--) {
            claims[currentIndex] = claimedHistoryMap[i];
            currentIndex += 1;
        }
        return claims;
    }

    function getAllClaimedHistoryCount() external view returns (uint256) {
        return claimedHistoryIds.current();
    }

    function drawWinner(uint256 _rewardPoints, uint256 _seed)
        external
        onlyOwner
    {
        require(
            stakedAddresses.length() > 0,
            "Durham_Inu_Staking: can't draw a winner, no staker found"
        );
        uint256 lastWinnerId = winnerIds.current();
        address lastWinnerAddress = WinnerHistories[lastWinnerId].userAddress;
        address winnerAddress = address(0);
        uint256 seed = _seed;
        uint256 counter = 0;
        while (winnerAddress == address(0)) {
            uint256 randNumber = rand(
                raffleIds.current(),
                seed,
                lastWinnerId,
                lastWinnerAddress
            );
            counter = counter.add(1);
            seed = seed.add(counter);
            if (counter > 10) {
                uint256 randNumber2 = rand(
                    stakedAddresses.length(),
                    seed,
                    lastWinnerId,
                    lastWinnerAddress
                );
                if (randNumber2 > 0) {
                    winnerAddress = stakedAddresses.at(randNumber2 - 1);
                }
            } else {
                winnerAddress = raffleEntries[randNumber];
            }
        }

        winnerIds.increment();
        uint256 winnerId = winnerIds.current();

        WinnerHistories[winnerId].userAddress = winnerAddress;
        WinnerHistories[winnerId].rewardPoints = _rewardPoints;
        WinnerHistories[winnerId].timestamp = block.timestamp;

        rewardPointBalance[winnerAddress] = rewardPointBalance[winnerAddress]
            .add(_rewardPoints);
    }

    function stakeTokensOnly(uint256 _qty) external {
        require(
            !blacklisted.contains(msg.sender),
            "Durham_Inu_Staking: address is blocked"
        );
        require(!isPaused, "Durham_Inu_Staking: Staking is paused");
        require(
            currentStakeInfo[msg.sender].isStaked == false,
            "Durham_Inu_Staking: You can stake once at a time"
        );

        stakedAddresses.add(msg.sender);
        _stakeTokens(msg.sender, _qty);
    }

    function stakeTokensAndNft(
        uint256 _qty,
        uint256 _nftId,
        address _nftAddress
    ) external {
        require(
            !blacklisted.contains(msg.sender),
            "Durham_Inu_Staking: address is blocked"
        );
        require(!isPaused, "Durham_Inu_Staking: Staking is paused");
        require(
            currentStakeInfo[msg.sender].isStaked == false,
            "Durham_Inu_Staking: You can stake once at a time"
        );

        stakedAddresses.add(msg.sender);
        _stakeTokens(msg.sender, _qty);
        _stakeNft(msg.sender, _nftId, _nftAddress);
    }

    function unstake() external {
        stakedAddresses.remove(msg.sender);
        _unStake(msg.sender);
    }

    function _stakeTokens(address _address, uint256 _qty) internal {
        require(
            maxQty >= _qty,
            "Durham_Inu_Staking: exceed the maximum quantity allowed"
        );
        uint256 userTokenBalance = DurhamInuToken.balanceOf(_address);
        uint256 tokenAmount = minToken * _qty;
        require(
            userTokenBalance >= tokenAmount,
            "Durham_Inu_Staking: not enought durham inu token"
        );
        uint256 entries = _qty.mul(uint256(entryPerMinToken));
        for (uint256 x = 0; x < entries; x++) {
            uint256 id;
            if (removedRaffleIds.length() > 0) {
                id = removedRaffleIds.at(0);
                removedRaffleIds.remove(id);
            } else {
                raffleIds.increment();
                id = raffleIds.current();
            }
            raffleEntries[id] = _address;
            currentStakeInfo[_address].raffleIds.add(id);
        }

        currentStakeInfo[_address].stakedTokens = tokenAmount;
        currentStakeInfo[_address].isStaked = true;
        currentStakeInfo[_address].lastUpdated = block.timestamp;
        DurhamInuToken.transferFrom(_address, address(this), tokenAmount);

        emit StakeTokens(_address, tokenAmount);
    }

    function _stakeNft(
        address _address,
        uint256 _nftId,
        address _nftAddress
    ) internal {
        require(
            allowedNfts.contains(_nftAddress),
            "Durham_Inu_Staking: this nft is not allowed to stake"
        );
        require(
            IERC721(_nftAddress).ownerOf(_nftId) == _address,
            "Durham_Inu_Staking: you are not the owner of this nft"
        );
        for (uint8 x = 0; x < entryPerNft; x++) {
            uint256 id;
            if (removedRaffleIds.length() > 0) {
                id = removedRaffleIds.at(0);
                removedRaffleIds.remove(id);
            } else {
                raffleIds.increment();
                id = raffleIds.current();
            }
            raffleEntries[id] = _address;
            currentStakeInfo[_address].raffleIds.add(id);
        }

        currentStakeInfo[_address].stakedNft.nftId = _nftId;
        currentStakeInfo[_address].stakedNft.nftAddress = _nftAddress;
        currentStakeInfo[_address].isStaked = true;
        currentStakeInfo[_address].lastUpdated = block.timestamp;
        IERC721(_nftAddress).transferFrom(_address, address(this), _nftId);
    }

    function _unStake(address _address) internal {
        require(
            !blacklisted.contains(_address),
            "Durham_Inu_Staking: address is blocked"
        );
        require(
            currentStakeInfo[_address].isStaked == true,
            "Durham_Inu_Staking: no staked items"
        );

        uint256 stakedTokens = currentStakeInfo[_address].stakedTokens;
        uint256 stakedNftId = currentStakeInfo[_address].stakedNft.nftId;
        address stakedNftAddress = currentStakeInfo[_address]
            .stakedNft
            .nftAddress;
        uint256 userRaffleCount = currentStakeInfo[_address].raffleIds.length();

        for (uint256 x = 0; x < userRaffleCount; x++) {
            uint256 id = currentStakeInfo[_address].raffleIds.at(0);
            removedRaffleIds.add(id);

            raffleEntries[id] = address(0);
            currentStakeInfo[_address].raffleIds.remove(id);
        }

        currentStakeInfo[_address].stakedTokens = 0;
        currentStakeInfo[_address].stakedNft.nftId = 0;
        currentStakeInfo[_address].stakedNft.nftAddress = address(0);
        currentStakeInfo[_address].isStaked = false;
        currentStakeInfo[_address].lastUpdated = block.timestamp;
        if (stakedTokens > 0) {
            DurhamInuToken.transfer(_address, stakedTokens);
        }

        if (stakedNftId > 0 && stakedNftAddress != address(0)) {
            IERC721(stakedNftAddress).transferFrom(
                address(this),
                _address,
                stakedNftId
            );
        }

        emit UnStake(_address);
    }

    function claim(uint256 _prizeItem, string calldata _email) external {
        require(
            _prizeItem != 0 && _prizeItem <= prizeLength,
            "Durham_Inu_Staking: Invalid prize item"
        );
        require(
            rewardPointBalance[msg.sender] >=
                prizeItems[_prizeItem].requiredPoints,
            "Durham_Inu_Staking: Not enough reward points"
        );
        rewardPointBalance[msg.sender] = rewardPointBalance[msg.sender].sub(
            prizeItems[_prizeItem].requiredPoints
        );

        bool isTangible = prizeItems[_prizeItem].isTangible;
        uint256 ethReward = prizeItems[_prizeItem].ethReward;
        claimedHistoryIds.increment();
        uint256 hId = claimedHistoryIds.current();
        claimedHistoryMap[hId].userAddress = msg.sender;
        claimedHistoryMap[hId].isTangible = isTangible;
        claimedHistoryMap[hId].name = prizeItems[_prizeItem].name;
        claimedHistoryMap[hId].desc = prizeItems[_prizeItem].desc;
        claimedHistoryMap[hId].ethReward = ethReward;
        claimedHistoryMap[hId].requiredPoints = prizeItems[_prizeItem]
            .requiredPoints;
        claimedHistoryMap[hId].timestamp = block.timestamp;
        claimedHistoryMap[hId].email = _email;
        userClaimedIds[msg.sender].push(hId);
        if (!prizeItems[_prizeItem].isTangible) {
            require(
                address(this).balance >= ethReward,
                "Durham_Inu_Staking: Not enough contract balance"
            );
            (bool status, ) = msg.sender.call{value: ethReward}("");
            require(status);

            totalNonTangibleClaims.increment();
        } else {
            totalTangibleClaims.increment();
        }

        emit ClaimPrize(msg.sender, _prizeItem);
    }

    function setBlacklist(address[] calldata _accounts, bool _isBlock)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < _accounts.length; i++) {
            if (_isBlock && !blacklisted.contains(_accounts[i])) {
                blacklisted.add(_accounts[i]);
            } else if (!_isBlock && blacklisted.contains(_accounts[i])) {
                blacklisted.remove(_accounts[i]);
            }
        }
    }

    function getBlacklisted() external view returns (address[] memory) {
        return blacklisted.values();
    }

    function pause() external onlyOwner {
        require(!isPaused, "Durham_Inu_Staking: Staking is already paused");
        isPaused = true;
    }

    function resume() external onlyOwner {
        require(isPaused, "Durham_Inu_Staking: Staking is already resumed");
        isPaused = false;
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
            _tokenAddr != address(DurhamInuToken),
            "Durham_Inu_Staking: Cannot transfer this token"
        );
        IERC20(_tokenAddr).transfer(_to, _amount);
    }

    receive() external payable {}

    function rand(
        uint256 _max,
        uint256 _seed,
        uint256 _lastWinnerId,
        address _lastWinnerAddress
    ) internal view returns (uint256) {
        if (_max == 0) {
            return 0;
        }
        uint256 _rand = uint256(
            keccak256(
                abi.encodePacked(
                    _seed,
                    _lastWinnerId,
                    _lastWinnerAddress,
                    _lastWinnerAddress.balance,
                    block.number,
                    block.timestamp,
                    block.coinbase
                )
            )
        );
        return _rand % (_max + 1);
    }
}