//SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract ApeCoinStaking is Ownable {

    using SafeERC20 for IERC20;

    // Pool
    struct Pool {
        uint256 lastRewardedTimestampHour;
        uint256 lastRewardsRangeIndex;
        uint256 stakedAmount;
        uint256 accumulatedRewardsPerShare;
        RewardsPerHourInRange[] rewardsPerHourInRanges;
    }

    struct RewardsPerHourInRange {
        uint256 startTimestampHour;
        uint256 endTimestampHour;
        uint256 rewardsPerHour;
        uint256 capPerPosition;
    }

    struct Position {
        uint256 stakedAmount;
        int256 rewardsDebt;
    }
    mapping (address => Position) public addressPosition;

    // NFT
    struct SingleNft {
        uint256 tokenId;
        uint256 amount;
    }
    struct PairNftWithAmount {
        uint256 mainTokenId;
        uint256 bakcTokenId;
        uint256 amount;
    }
    struct PairNft {
        uint256 mainTokenId;
        uint256 bakcTokenId;
    }
    struct PairingStatus {
        uint256 tokenId;
        bool isPaired;
    }

    // UI
    struct DashboardStake {
        uint256 poolId;
        uint256 tokenId;
        uint256 deposited;
        uint256 unclaimed;
        uint256 rewards24hr;
        DashboardPair pair;
    }
    struct DashboardPair {
        uint256 mainTokenId;
        uint256 mainTypePoolId;
    }
    DashboardPair private NULL_PAIR = DashboardPair(0, 0);

    IERC20 public immutable apeCoin;
    uint256 private constant APE_COIN_PRECISION = 1e18;
    uint256 private constant MIN_DEPOSIT = 1 * APE_COIN_PRECISION;
    uint256 private constant SECONDS_PER_HOUR = 3600;
    uint256 private constant SECONDS_PER_MINUTE = 60;

    uint256 constant APECOIN_POOL_ID = 0;
    uint256 constant BAYC_POOL_ID = 1;
    uint256 constant MAYC_POOL_ID = 2;
    uint256 constant BAKC_POOL_ID = 3;
    Pool[4] public pools;

    mapping(uint256 => ERC721Enumerable) public nftContracts;
    // poolId => tokenId => nft position
    mapping(uint256 => mapping(uint256 => Position)) public nftPosition;
    // main type pool ID: 1: BAYC 2: MAYC => main token ID => bakc token ID
    mapping(uint256 => mapping(uint256 => PairingStatus)) public mainToBakc;
    // bakc Token ID => main type pool ID: 1: BAYC 2: MAYC => main token ID
    mapping(uint256 => mapping(uint256 => PairingStatus)) public bakcToMain;

    // Events
    event UpdatePool(
        uint256 indexed poolId,
        uint256 lastRewardedBlock,
        uint256 stakedAmount,
        uint256 accumulatedRewardsPerShare
    );
    event Deposit(
        address indexed user,
        uint256 amount,
        address recipient
    );
    event DepositNft(
        address indexed user,
        uint256 indexed poolId,
        uint256 amount,
        uint256 tokenId
    );
    event DepositPairNft(
        address indexed user,
        uint256 amount,
        uint256 mainTypePoolId,
        uint256 mainTokenId,
        uint256 bakcTokenId
    );
    event Withdraw(
        address indexed user,
        uint256 amount,
        address recipient
    );
    event WithdrawNft(
        address indexed user,
        uint256 indexed poolId,
        uint256 amount,
        address recipient,
        uint256 tokenId
    );
    event WithdrawPairNft(
        address indexed user,
        uint256 amount,
        uint256 mainTypePoolId,
        uint256 mainTokenId,
        uint256 bakcTokenId
    );
    event ClaimRewards(
        address indexed user,
        uint256 amount,
        address recipient
    );
    event ClaimRewardsNft(
        address indexed user,
        uint256 indexed poolId,
        uint256 amount,
        uint256 tokenId
    );
    event ClaimRewardsPairNft(
        address indexed user,
        uint256 amount,
        uint256 mainTypePoolId,
        uint256 mainTokenId,
        uint256 bakcTokenId
    );

    constructor(
        address _apeCoinContractAddress,
        address _baycContractAddress,
        address _maycContractAddress,
        address _bakcContractAddress
    ) {
        apeCoin = IERC20(_apeCoinContractAddress);
        nftContracts[BAYC_POOL_ID] = ERC721Enumerable(_baycContractAddress);
        nftContracts[MAYC_POOL_ID] = ERC721Enumerable(_maycContractAddress);
        nftContracts[BAKC_POOL_ID] = ERC721Enumerable(_bakcContractAddress);
    }

    // Deposit/Commit Methods

    /**
     * @dev Deposits `_amount` of $APE to `_recipient` address in ApeCoin pool.
     */
    function depositApeCoin(uint256 _amount, address _recipient) public {
        require(_amount >= MIN_DEPOSIT, "Can't deposit less than 1 $APE");
        updatePool(APECOIN_POOL_ID);

        Position storage position = addressPosition[_recipient];
        _deposit(APECOIN_POOL_ID, position, _amount);

        emit Deposit(msg.sender, _amount, _recipient);
    }

    /**
     * @dev Deposits `_amount` of $APE to caller address in ApeCoin pool.
     */
    function depositSelfApeCoin(uint256 _amount) external {
        depositApeCoin(_amount, msg.sender);
    }

    /**
     * @dev Commits/Deposits $APE to NFTs in the BAYC pool.
     * Expects an input array of token IDs/amount of $APE to deposit for each NFT.
     */
    function depositBAYC(SingleNft[] calldata _nfts) external {
        _depositNft(BAYC_POOL_ID, _nfts);
    }

    /**
     * @dev Commits/Deposits $APE to NFTs in the MAYC pool.
     * Expects an input array of token IDs/amount of $APE to deposit for each NFT.
     */
    function depositMAYC(SingleNft[] calldata _nfts) external {
        _depositNft(MAYC_POOL_ID, _nfts);
    }

    /**
     * @dev Commits/Deposits $APE to pairs in the BAKC pool.
     * Expects an input array of pair Token IDs/amount of $APE to deposit for each pair.
     * - `_baycPairs`: Array for BAYC/BAKC pairs
     * - `_maycPairs`: Array for MAYC/BAKC pairs
     */
    function depositBAKC(PairNftWithAmount[] calldata _baycPairs, PairNftWithAmount[] calldata _maycPairs) external {
        updatePool(BAKC_POOL_ID);
        _depositPairNft(BAYC_POOL_ID, _baycPairs);
        _depositPairNft(MAYC_POOL_ID, _maycPairs);
    }

    // Claim Rewards Methods

    /**
     * @dev Claims current $APE rewards for caller address in ApeCoin Pool.
     * Sends rewards to `_recipient` address.
     */
    function claimApeCoin(address _recipient) public {
        updatePool(APECOIN_POOL_ID);

        Position storage position = addressPosition[msg.sender];
        uint rewardsToBeClaimed = _claim(APECOIN_POOL_ID, position, _recipient);

        emit ClaimRewards(msg.sender, rewardsToBeClaimed, _recipient);
    }

    /**
     * @dev Claims current $APE rewards for caller address in ApeCoin Pool.
     * Sends rewards to caller address itself.
     */
    function claimSelfApeCoin() external {
        claimApeCoin(msg.sender);
    }

    /**
     * @dev Claims current $APE rewards for NFTs in BAYC Pool.
     * Sends rewards to `_recipient`.
     */
    function claimBAYC(uint256[] calldata _nfts, address _recipient) external {
        _claimNft(BAYC_POOL_ID, _nfts, _recipient);
    }

    /**
     * @dev Claims current $APE rewards for NFTs in BAYC Pool.
     * Sends rewards to caller address itself.
     */
    function claimSelfBAYC(uint256[] calldata _nfts) external {
        _claimNft(BAYC_POOL_ID, _nfts, msg.sender);
    }

    /**
     * @dev Claims current $APE rewards for NFTs in MAYC Pool.
     * Sends rewards to `_recipient`.
     */
    function claimMAYC(uint256[] calldata _nfts, address _recipient) external {
        _claimNft(MAYC_POOL_ID, _nfts, _recipient);
    }

    /**
     * @dev Claims current $APE rewards for NFTs in MAYC Pool.
     * Sends rewards to caller address itself.
     */
    function claimSelfMAYC(uint256[] calldata _nfts) external {
        _claimNft(MAYC_POOL_ID, _nfts, msg.sender);
    }

    /**
     * @dev Claims current $APE rewards for pairs in BAKC Pool.
     * Sends rewards to `_recipient`.
     * - `_baycPairs`: Array for BAYC/BAKC pairs
     * - `_maycPairs`: Array for MAYC/BAKC pairs
     */
    function claimBAKC(PairNft[] calldata _baycPairs, PairNft[] calldata _maycPairs, address _recipient) public {
        updatePool(BAKC_POOL_ID);
        _claimPairNft(BAYC_POOL_ID, _baycPairs, _recipient);
        _claimPairNft(MAYC_POOL_ID, _maycPairs, _recipient);
    }

    /**
     * @dev Claims current $APE rewards for pairs in BAKC Pool.
     * Sends rewards to caller address itself.
     */
    function claimSelfBAKC(PairNft[] calldata _baycPairs, PairNft[] calldata _maycPairs) external {
        claimBAKC(_baycPairs, _maycPairs, msg.sender);
    }

    // Uncommit/Withdraw Methods

    /**
     * @dev Withdraws `_amount` of staked $APE from caller address.
     * Sends $APE to `_recipient`.
     */
    function withdrawApeCoin(uint256 _amount, address _recipient) public {
        updatePool(APECOIN_POOL_ID);

        Position storage position = addressPosition[msg.sender];
        _withdraw(APECOIN_POOL_ID, position, _amount, _recipient);

        emit Withdraw(msg.sender, _amount, _recipient);
    }

    /**
     * @dev Withdraws `_amount` of staked $APE from caller address.
     * Sends $APE to caller address itself.
     */
    function withdrawSelfApeCoin(uint256 _amount) external {
        withdrawApeCoin(_amount, msg.sender);
    }

    /**
     * @dev Uncommits/Withdraws given amount of staked $APE from NFTs in BAYC Pool.
     * Sends $APE to `_recipient`.
     */
    function withdrawBAYC(SingleNft[] calldata _nfts, address _recipient) external {
        _withdrawNft(BAYC_POOL_ID, _nfts, _recipient);
    }

    /**
     * @dev Uncommits/Withdraws given amount of staked $APE from NFTs in BAYC Pool.
     * Sends $APE to caller address itself.
     */
    function withdrawSelfBAYC(SingleNft[] calldata _nfts) external {
        _withdrawNft(BAYC_POOL_ID, _nfts, msg.sender);
    }

    /**
     * @dev Uncommits/Withdraws given amount of staked $APE from NFTs in MAYC Pool.
     * Sends $APE to `_recipient`.
     */
    function withdrawMAYC(SingleNft[] calldata _nfts, address _recipient) external {
        _withdrawNft(MAYC_POOL_ID, _nfts, _recipient);
    }

    /**
     * @dev Uncommits/Withdraws given amount of staked $APE from NFTs in MAYC Pool.
     * Sends $APE to `_recipient`.
     */
    function withdrawSelfMAYC(SingleNft[] calldata _nfts) external {
        _withdrawNft(MAYC_POOL_ID, _nfts, msg.sender);
    }

    /**
     * @dev Uncommits/Withdraws given amount of staked $APE from NFTs in BAKC Pool.
     */
    function withdrawBAKC(PairNftWithAmount[] calldata _baycPairs, PairNftWithAmount[] calldata _maycPairs) external {
        updatePool(BAKC_POOL_ID);
        _withdrawPairNft(BAYC_POOL_ID, _baycPairs);
        _withdrawPairNft(MAYC_POOL_ID, _maycPairs);
    }

    // Time Range Methods

    /**
     * @dev Sets time ranges with a given rewards per hour for a given pool
     * In practice one Time Range will likely represent one quarter (defined by `_startTimestamp`and `_endTimeStamp` as whole hours)
     * where the rewards per hour is constant for a given pool.
     */
    function setRewardsPerTimeRange(
        uint256 _poolId,
        uint256 _amount,
        uint256 _startTimestamp,
        uint256 _endTimeStamp,
        uint256 _capPerPosition) external onlyOwner
    {
        require (_poolId < 4, "Invalid poolId");
        require (_startTimestamp < _endTimeStamp, "_startTimestamp should be less than _endTimeStamp");
        require(getMinute(_startTimestamp) == 0 && getSecond(_startTimestamp) == 0, "_startTimestamp is not a whole hour");
        require(getMinute(_endTimeStamp) == 0 && getSecond(_endTimeStamp) == 0, "_endTimeStamp is not a whole hour");

        Pool storage pool = pools[_poolId];
        uint256 hoursInSeconds = _endTimeStamp - _startTimestamp;
        uint256 rewardsPerHour = _amount * SECONDS_PER_HOUR / hoursInSeconds;

        RewardsPerHourInRange memory next = RewardsPerHourInRange(_startTimestamp, _endTimeStamp, rewardsPerHour, _capPerPosition);
        pool.rewardsPerHourInRanges.push(next);
    }

    /**
     * @dev Removes the last Time Range for a given pool.
     */
    function removeLastTimeRange(uint256 _poolId) external onlyOwner {
        Pool storage pool = pools[_poolId];
        pool.rewardsPerHourInRanges.pop();
    }

    function getRewardsPerHourInRange(uint256 _poolId, uint256 _index) public view returns (RewardsPerHourInRange memory) {
        Pool memory pool = pools[_poolId];
        return pool.rewardsPerHourInRanges[_index];
    }

    // Pool Methods

    /**
     * @dev Calculates amount of $APE rewards to be distributed from given `_from` timestamp to `_to` timestamp
     * for a given pool ID.
     */
    function rewardsBy(uint256 _poolId, uint256 _from, uint256 _to) public view returns (uint256, uint256) {
        Pool memory pool = pools[_poolId];
        if(_to < pool.rewardsPerHourInRanges[0].startTimestampHour) return (0, pool.lastRewardsRangeIndex);

        uint256 rewards;
        for(uint256 i = pool.lastRewardsRangeIndex; i < pool.rewardsPerHourInRanges.length; ++i) {
            RewardsPerHourInRange memory current = pool.rewardsPerHourInRanges[i];

            uint256 startTimestampHour = _from <= current.startTimestampHour ? current.startTimestampHour : _from;
            uint256 endTimestampHour = _to <= current.endTimestampHour ? _to : current.endTimestampHour;
            rewards = rewards + (endTimestampHour - startTimestampHour) * current.rewardsPerHour / SECONDS_PER_HOUR;

            if(_to <= endTimestampHour) {
                return (rewards, i);
            }
        }

        return (rewards, pool.rewardsPerHourInRanges.length - 1);
    }

    /**
     * @dev Updates reward variables `lastRewardedTimestampHour`, `accumulatedRewardsPerShare` and `lastRewardsRangeIndex`
     * for given pool.
     */
    function updatePool(uint256 _poolId) public {
        Pool storage pool = pools[_poolId];

        if (block.timestamp < pool.rewardsPerHourInRanges[0].startTimestampHour) return;
        if (block.timestamp <= pool.lastRewardedTimestampHour + SECONDS_PER_HOUR) return;

        uint256 lastTimestampHour = pool.rewardsPerHourInRanges[pool.rewardsPerHourInRanges.length-1].endTimestampHour;
        uint256 previousTimestampHour = getPreviousTimestampHour(block.timestamp);

        if (pool.stakedAmount == 0) {
            pool.lastRewardedTimestampHour = previousTimestampHour > lastTimestampHour ? lastTimestampHour : previousTimestampHour;
            return;
        }

        (uint256 rewards, uint256 index) = rewardsBy(_poolId, pool.lastRewardedTimestampHour, getPreviousTimestampHour(block.timestamp));
        if (pool.lastRewardsRangeIndex != index) {
            pool.lastRewardsRangeIndex = index;
        }
        pool.accumulatedRewardsPerShare = pool.accumulatedRewardsPerShare + (rewards * APE_COIN_PRECISION) / pool.stakedAmount;
        pool.lastRewardedTimestampHour = previousTimestampHour > lastTimestampHour ? lastTimestampHour : previousTimestampHour;

        emit UpdatePool(_poolId, pool.lastRewardedTimestampHour, pool.stakedAmount, pool.accumulatedRewardsPerShare);
    }

    // Read Methods

    /**
     * @dev Returns staked amount for addressPosition [APECOIN] and nftPositions [BAYC, MAYC, and Pair(BAKC)].
     */
    function stakedTotal(address _addr) external view returns (uint256) {
        uint256 total = addressPosition[_addr].stakedAmount;

        total += _stakedTotal(BAYC_POOL_ID, _addr);
        total += _stakedTotal(MAYC_POOL_ID, _addr);
        total += _stakedTotal(BAKC_POOL_ID, _addr);

        return total;
    }

    function _stakedTotal(uint256 _poolId, address _addr) private view returns (uint256) {
        uint256 total = 0;
        uint256 nftCount = nftContracts[_poolId].balanceOf(_addr);
        for(uint256 i = 0; i < nftCount; ++i) {
            uint256 tokenId = nftContracts[_poolId].tokenOfOwnerByIndex(_addr, i);
            total += nftPosition[_poolId][tokenId].stakedAmount;
        }

        return total;
    }

    /**
     * @dev Returns staked amount, pending rewards, and estimated rewards over the last 24 hours
     *      for addressPosition [APECOIN, BAYC, MAYC, BAKC].
     */
    function getAllStakes(address _address) public view returns (DashboardStake[] memory) {

        DashboardStake memory apeCoinStake = getApeCoinStake(_address);
        DashboardStake[] memory baycStakes = getBaycStakes(_address);
        DashboardStake[] memory maycStakes = getMaycStakes(_address);
        DashboardStake[] memory bakcStakes = getBakcStakes(_address);

        uint256 count = (baycStakes.length + maycStakes.length + bakcStakes.length + 1);
        DashboardStake[] memory allStakes = new DashboardStake[](count);

        uint256 offset = 0;
        allStakes[offset] = apeCoinStake;
        ++offset;

        for(uint256 i = 0; i < baycStakes.length; ++i) {
            allStakes[offset] = baycStakes[i];
            ++offset;
        }

        for(uint256 i = 0; i < maycStakes.length; ++i) {
            allStakes[offset] = maycStakes[i];
            ++offset;
        }

        for(uint256 i = 0; i < bakcStakes.length; ++i) {
            allStakes[offset] = bakcStakes[i];
            ++offset;
        }

        return allStakes;
    }

    /**
     * @dev Returns staked amount, pending rewards, and estimated rewards over the last 24 hours
     *      for addressPosition [APECOIN].
     */
    function getApeCoinStake(address _address) public view returns (DashboardStake memory) {
        uint256 tokenId = 0;
        uint256 deposited = addressPosition[_address].stakedAmount;
        uint256 unclaimed = this.pendingRewards(0, _address, tokenId);
        uint256 rewards24Hrs = _estimate24HourRewards(0, _address, 0);

        return DashboardStake(APECOIN_POOL_ID, tokenId, deposited, unclaimed, rewards24Hrs, NULL_PAIR);
    }

    /**
     * @dev Returns staked amount, pending rewards, and estimated rewards over the last 24 hours
     *      for addressPosition [BAYC].
     */
    function getBaycStakes(address _address) public view returns (DashboardStake[] memory) {
        return _getStakes(_address, BAYC_POOL_ID);
    }

    /**
     * @dev Returns staked amount, pending rewards, and estimated rewards over the last 24 hours
     *      for addressPosition [MAYC].
     */
    function getMaycStakes(address _address) public view returns (DashboardStake[] memory) {
        return _getStakes(_address, MAYC_POOL_ID);
    }

    /**
     * @dev Returns staked amount, pending rewards, and estimated rewards over the last 24 hours
     *      for addressPosition [BAKC].
     */
    function getBakcStakes(address _address) public view returns (DashboardStake[] memory) {
        return _getStakes(_address, BAKC_POOL_ID);
    }

    function _getStakes(address _address, uint256 _poolId) private view returns (DashboardStake[] memory) {
        uint256 nftCount = nftContracts[_poolId].balanceOf(_address);
        DashboardStake[] memory dashboardStakes = new DashboardStake[](nftCount);
        for(uint256 i = 0; i < nftCount; ++i) {
            uint256 tokenId = nftContracts[_poolId].tokenOfOwnerByIndex(_address, i);
            uint256 deposited = nftPosition[_poolId][tokenId].stakedAmount;
            uint256 unclaimed = this.pendingRewards(_poolId, _address, tokenId);
            uint256 rewards24Hrs = _estimate24HourRewards(_poolId, _address, tokenId);

            DashboardPair memory pair = NULL_PAIR;
            if(_poolId == BAKC_POOL_ID) {
                if(bakcToMain[tokenId][BAYC_POOL_ID].isPaired) {
                    pair = DashboardPair(bakcToMain[tokenId][BAYC_POOL_ID].tokenId, BAYC_POOL_ID);
                } else if(bakcToMain[tokenId][MAYC_POOL_ID].isPaired) {
                    pair = DashboardPair(bakcToMain[tokenId][MAYC_POOL_ID].tokenId, MAYC_POOL_ID);
                }
            }

            DashboardStake memory dashboardStake = DashboardStake(_poolId, tokenId, deposited, unclaimed, rewards24Hrs, pair);
            dashboardStakes[i] = dashboardStake;
        }

        return dashboardStakes;
    }

    function _estimate24HourRewards(uint256 _poolId, address _address, uint256 _tokenId) private view returns (uint256) {
        Pool memory pool = pools[_poolId];
        Position memory position = _poolId == 0 ? addressPosition[_address]: nftPosition[_poolId][_tokenId];

        RewardsPerHourInRange memory rewards = getRewardsPerHourInRange(_poolId, pool.lastRewardsRangeIndex);
        return ((position.stakedAmount / pool.stakedAmount) * rewards.rewardsPerHour * 24);
    }

    /**
     * @dev Returns current amount of claimable $APE rewards for a given position from a given pool.
     */
    function pendingRewards(uint256 _poolId, address _address, uint256 _tokenId) external view returns (uint256) {
        Pool memory pool = pools[_poolId];
        Position memory position = _poolId == 0 ? addressPosition[_address]: nftPosition[_poolId][_tokenId];

        (uint256 rewardsSinceLastCalculated,) = rewardsBy(_poolId, pool.lastRewardedTimestampHour, getPreviousTimestampHour(block.timestamp));
        uint256 accumulatedRewardsPerShare = pool.accumulatedRewardsPerShare;

        if (block.timestamp > pool.lastRewardedTimestampHour + SECONDS_PER_HOUR && pool.stakedAmount != 0) {
            accumulatedRewardsPerShare = accumulatedRewardsPerShare + rewardsSinceLastCalculated * APE_COIN_PRECISION / pool.stakedAmount;
        }
        return uint256(int256((position.stakedAmount * accumulatedRewardsPerShare / APE_COIN_PRECISION)) - position.rewardsDebt);
    }

    // Convenience methods for timestamp calculation

    /**
     * @dev Returns the minutes (0 to 59) of a timestamp
     */
    function getMinute(uint256 timestamp) internal pure returns (uint256 minute) {
        uint secs = timestamp % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
    }

    /**
     * @dev Returns the seconds (0 to 59) of a timestamp
     */
    function getSecond(uint256 timestamp) internal pure returns (uint256 second) {
        second = timestamp % SECONDS_PER_MINUTE;
    }

    /**
     * @dev Returns the previous whole hour of a timestamp
     */
    function getPreviousTimestampHour(uint256 timestamp) internal pure returns (uint256) {
        return timestamp - (getMinute(timestamp) * 60 + getSecond(timestamp));
    }

    // Private Methods - shared logic
    function _deposit(uint256 _poolId, Position storage _position, uint256 _amount) private {
        Pool storage pool = pools[_poolId];

        _position.stakedAmount += _amount;
        pool.stakedAmount += _amount;
        _position.rewardsDebt += int256(_amount * pool.accumulatedRewardsPerShare / APE_COIN_PRECISION);

        apeCoin.safeTransferFrom(msg.sender, address(this), _amount);
    }

    function _depositNft(uint256 _poolId, SingleNft[] calldata _nfts) private {
        updatePool(_poolId);
        for(uint i; i < _nfts.length; ++i) {
            uint256 tokenId = _nfts[i].tokenId;
            uint256 amount = _nfts[i].amount;
            Position storage position = nftPosition[_poolId][tokenId];
            require(position.stakedAmount > 0 || nftContracts[_poolId].ownerOf(tokenId) == msg.sender, "Token not owned by caller");
            _depositNftGuard(_poolId, position, amount);
            emit DepositNft(msg.sender, _poolId, amount, tokenId);
        }
    }

    function _depositPairNft(uint256 mainTypePoolId, PairNftWithAmount[] calldata _nfts) private {
        for(uint i; i < _nfts.length; ++i) {
            uint256 mainTokenId = _nfts[i].mainTokenId;
            uint256 bakcTokenId = _nfts[i].bakcTokenId;
            uint256 amount = _nfts[i].amount;
            Position storage position = nftPosition[BAKC_POOL_ID][bakcTokenId];

            if(position.stakedAmount == 0) {
                require(nftContracts[mainTypePoolId].ownerOf(mainTokenId) == msg.sender && !mainToBakc[mainTypePoolId][mainTokenId].isPaired
                , "Main Token not owned by caller or already paired");
                require(nftContracts[BAKC_POOL_ID].ownerOf(bakcTokenId) == msg.sender && !bakcToMain[bakcTokenId][mainTypePoolId].isPaired
                ,"BAKC Token not owned by caller or already paired");
                mainToBakc[mainTypePoolId][mainTokenId] = PairingStatus(bakcTokenId, true);
                bakcToMain[bakcTokenId][mainTypePoolId] = PairingStatus(mainTokenId, true);
            } else {
                require(mainTokenId == bakcToMain[bakcTokenId][mainTypePoolId].tokenId, "BAKC Token already paired");
            }

            _depositNftGuard(BAKC_POOL_ID, position, amount);
            emit DepositPairNft(msg.sender, amount, mainTypePoolId, mainTokenId, bakcTokenId);
        }
    }

    function _depositNftGuard(uint256 _poolId, Position storage _position, uint256 _amount) private {
        require(_amount >= MIN_DEPOSIT, "Can't deposit less than 1 $APE");
        require(_amount + _position.stakedAmount
            <= pools[_poolId].rewardsPerHourInRanges[pools[_poolId].lastRewardsRangeIndex].capPerPosition, "Can't stake more than cap amount");

        _deposit(_poolId, _position, _amount);
    }

    function _claim(uint256 _poolId, Position storage _position, address _recipient) private returns (uint256) {
        Pool storage pool = pools[_poolId];

        int256 accumulatedApeCoins = int256(_position.stakedAmount * pool.accumulatedRewardsPerShare / APE_COIN_PRECISION);
        uint256 rewardsToBeClaimed = uint256(accumulatedApeCoins - _position.rewardsDebt);

        _position.rewardsDebt = accumulatedApeCoins;

        if (rewardsToBeClaimed != 0) {
            apeCoin.safeTransfer(_recipient, rewardsToBeClaimed);
        }
        return rewardsToBeClaimed;
    }

    function _claimNft(uint256 _poolId, uint256[] calldata _nfts, address _recipient) private {
        updatePool(_poolId);
        for(uint i; i < _nfts.length; ++i) {
            uint256 tokenId = _nfts[i];
            Position storage position = nftPosition[_poolId][tokenId];
            require(nftContracts[_poolId].ownerOf(tokenId) == msg.sender, "Token not owned by caller");
            uint256 rewardsToBeClaimed = _claim(_poolId, position, _recipient);
            emit ClaimRewardsNft(msg.sender, _poolId, rewardsToBeClaimed, tokenId);
        }
    }

    function _claimPairNft(uint256 mainTypePoolId, PairNft[] calldata _pairs, address _recipient) private {
        for(uint i; i < _pairs.length; ++i) {
            uint256 mainTokenId = _pairs[i].mainTokenId;
            uint256 bakcTokenID = _pairs[i].bakcTokenId;

            Position storage position = nftPosition[BAKC_POOL_ID][bakcTokenID];

            require(nftContracts[mainTypePoolId].ownerOf(mainTokenId) == msg.sender, "Main Token not owned by caller");
            require(nftContracts[BAKC_POOL_ID].ownerOf(bakcTokenID) == msg.sender, "BAKC Token not owned by caller");

            uint256 rewardsToBeClaimed = _claim(BAKC_POOL_ID, position, _recipient);
            emit ClaimRewardsPairNft(msg.sender, rewardsToBeClaimed, mainTypePoolId, mainTokenId, bakcTokenID);
        }
    }

    function _withdraw(uint256 _poolId, Position storage _position, uint256 _amount, address _recipient) private {
        Pool storage pool = pools[_poolId];

        _position.stakedAmount -= _amount;
        pool.stakedAmount -= _amount;
        _position.rewardsDebt -= int256(_amount * pool.accumulatedRewardsPerShare / APE_COIN_PRECISION);

        apeCoin.safeTransfer(_recipient, _amount);
    }

    function _withdrawNft(uint256 _poolId, SingleNft[] calldata _nfts, address _recipient) private {
        updatePool(_poolId);
        for(uint i; i < _nfts.length; ++i) {
            uint256 tokenId = _nfts[i].tokenId;
            uint256 amount = _nfts[i].amount;
            require(nftContracts[_poolId].ownerOf(tokenId) == msg.sender, "Token not owned by caller");

            Position storage position = nftPosition[_poolId][tokenId];
            if (amount == position.stakedAmount) {
                uint256 rewardsToBeClaimed = _claim(_poolId, position, _recipient);
                emit ClaimRewardsNft(msg.sender, _poolId, rewardsToBeClaimed, tokenId);
            }
            _withdraw(_poolId, position, amount, _recipient);
            emit WithdrawNft(msg.sender, _poolId, amount, _recipient, tokenId);
        }
    }

    function _withdrawPairNft(uint256 mainTypePoolId, PairNftWithAmount[] calldata _nfts) private {
        for(uint i; i < _nfts.length; ++i) {
            uint256 mainTokenId = _nfts[i].mainTokenId;
            uint256 bakcTokenId = _nfts[i].bakcTokenId;
            uint256 amount = _nfts[i].amount;
            address mainTokenOwner = nftContracts[mainTypePoolId].ownerOf(mainTokenId);
            address bakcOwner = nftContracts[BAKC_POOL_ID].ownerOf(bakcTokenId);

            require(mainTokenOwner == msg.sender || bakcOwner == msg.sender, "At least one token in pair must be owned by caller");

            Position storage position = nftPosition[BAKC_POOL_ID][bakcTokenId];
            require(mainTokenOwner == bakcOwner || amount == position.stakedAmount, "Split pair can't partially withdraw");

            if (amount == position.stakedAmount) {
                uint256 rewardsToBeClaimed = _claim(BAKC_POOL_ID, position, bakcOwner);
                mainToBakc[mainTypePoolId][mainTokenId].isPaired = false;
                bakcToMain[bakcTokenId][mainTypePoolId].isPaired = false;
                emit ClaimRewardsPairNft(msg.sender, rewardsToBeClaimed, mainTypePoolId, mainTokenId, bakcTokenId);
            }
            _withdraw(BAKC_POOL_ID, position, amount, mainTokenOwner);
            emit WithdrawPairNft(msg.sender, amount, mainTypePoolId, mainTokenId, bakcTokenId);
        }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
                /// @solidity memory-safe-assembly
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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}