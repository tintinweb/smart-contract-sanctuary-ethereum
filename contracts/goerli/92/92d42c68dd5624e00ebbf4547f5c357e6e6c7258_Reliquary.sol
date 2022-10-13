// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./interfaces/IReliquary.sol";
import "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import "openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "openzeppelin-contracts/contracts/utils/Multicall.sol";
import "openzeppelin-contracts/contracts/access/AccessControlEnumerable.sol";
import "openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";

/*
 + @title Reliquary
 + @author Justin Bebis, Zokunei & the Byte Masons team
 +
 + @notice This system is designed to manage incentives for deposited assets such that
 + behaviors can be programmed on a per-pool basis using maturity levels. Stake in a
 + pool, also referred to as "position," is represented by means of an NFT called a
 + "Relic." Each position has a "maturity" which captures the age of the position.
 +
 + @notice Deposits are tracked by Relic ID instead of by user. This allows for
 + increased composability without affecting accounting logic too much, and users can
 + trade their Relics without withdrawing liquidity or affecting the position's maturity.
*/
contract Reliquary is
    IReliquary,
    ERC721Burnable,
    ERC721Enumerable,
    AccessControlEnumerable,
    Multicall,
    ReentrancyGuard
{
    using SafeERC20 for IERC20;

    /// @notice Access control roles.
    bytes32 private constant OPERATOR = keccak256("OPERATOR");
    bytes32 private constant EMISSION_CURVE = keccak256("EMISSION_CURVE");

    /// @notice Indicates whether tokens are being added to, or removed from, a pool
    enum Kind {
        DEPOSIT,
        WITHDRAW,
        OTHER
    }

    /// @notice Level of precision rewards are calculated to
    uint private constant ACC_REWARD_PRECISION = 1e12;

    /// @notice Nonce to use for new relicId
    uint private nonce;

    /// @notice Address of the reward token contract.
    IERC20 public immutable rewardToken;
    /// @notice Address of each NFTDescriptor contract.
    INFTDescriptor[] public nftDescriptor;
    /// @notice Address of EmissionCurve contract.
    IEmissionCurve public emissionCurve;
    /// @notice Info of each Reliquary pool.
    PoolInfo[] private poolInfo;
    /// @notice Level system for each Reliquary pool.
    LevelInfo[] private levels;
    /// @notice Address of the LP token for each Reliquary pool.
    IERC20[] public poolToken;
    /// @notice Address of each `IRewarder` contract.
    IRewarder[] public rewarder;

    /// @notice Info of each staked position
    mapping(uint => PositionInfo) private positionForId;

    /// @dev Total allocation points. Must be the sum of all allocation points in all pools.
    uint public totalAllocPoint;

    event CreateRelic(
        uint indexed pid,
        address indexed to,
        uint indexed relicId
    );
    event Deposit(
        uint indexed pid,
        uint amount,
        address indexed to,
        uint indexed relicId
    );
    event Withdraw(
        uint indexed pid,
        uint amount,
        address indexed to,
        uint indexed relicId
    );
    event EmergencyWithdraw(
        uint indexed pid,
        uint amount,
        address indexed to,
        uint indexed relicId
    );
    event Harvest(
        uint indexed pid,
        uint amount,
        address indexed to,
        uint indexed relicId
    );
    event LogPoolAddition(
        uint indexed pid,
        uint allocPoint,
        IERC20 indexed poolToken,
        IRewarder indexed rewarder,
        INFTDescriptor nftDescriptor
    );
    event LogPoolModified(
        uint indexed pid,
        uint allocPoint,
        IRewarder indexed rewarder,
        INFTDescriptor nftDescriptor
    );
    event LogUpdatePool(
        uint indexed pid,
        uint lastRewardTime,
        uint lpSupply,
        uint accRewardPerShare
    );
    event LogSetEmissionCurve(IEmissionCurve indexed emissionCurveAddress);
    event LevelChanged(uint indexed relicId, uint newLevel);
    event Split(uint indexed fromId, uint indexed toId, uint amount);
    event Shift(uint indexed fromId, uint indexed toId, uint amount);
    event Merge(uint indexed fromId, uint indexed toId, uint amount);

    /*
     + @notice Constructs and initializes the contract
     + @param _rewardToken The reward token contract address.
     + @param _emissionCurve The contract address for the EmissionCurve, which will return the emission rate
    */
    constructor(IERC20 _rewardToken, IEmissionCurve _emissionCurve) ERC721("Reliquary Deposit", "RELIC") {
        rewardToken = _rewardToken;
        emissionCurve = _emissionCurve;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /// @notice Implement ERC165 to return which interfaces this contract conforms to
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(IReliquary, AccessControlEnumerable, ERC721, ERC721Enumerable)
        returns (bool)
    {
        return
            interfaceId == type(IReliquary).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /// @notice Returns the number of Reliquary pools.
    function poolLength() public view override returns (uint pools) {
        pools = poolInfo.length;
    }

    function tokenURI(uint tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        require(_exists(tokenId), "token does not exist");
        return
            nftDescriptor[positionForId[tokenId].poolId].constructTokenURI(
                tokenId
            );
    }

    /// @param _emissionCurve The contract address for EmissionCurve, which will return the base emission rate
    function setEmissionCurve(IEmissionCurve _emissionCurve)
        external
        override
        onlyRole(EMISSION_CURVE)
    {
        emissionCurve = _emissionCurve;
        emit LogSetEmissionCurve(_emissionCurve);
    }

    function getPositionForId(uint relicId)
        external
        view
        override
        returns (PositionInfo memory position)
    {
        position = positionForId[relicId];
    }

    function getPoolInfo(uint pid)
        external
        view
        override
        returns (PoolInfo memory pool)
    {
        pool = poolInfo[pid];
    }

    function getLevelInfo(uint pid)
        external
        view
        override
        returns (LevelInfo memory levelInfo)
    {
        levelInfo = levels[pid];
    }

    function burn(uint tokenId) public override(IReliquary, ERC721Burnable) {
        require(positionForId[tokenId].amount == 0, "contains deposit");
        require(pendingReward(tokenId) == 0, "contains pending rewards");
        super.burn(tokenId);
    }

    /*
     + @notice Add a new pool for the specified LP.
     +         Can only be called by an operator.
     +
     + @param allocPoint The allocation points for the new pool
     + @param _poolToken Address of the pooled ERC-20 token
     + @param _rewarder Address of the rewarder delegate
     + @param requiredMaturity Array of maturity (in seconds) required to achieve each level for this pool
     + @param allocPoints The allocation points for each level within this pool
     + @param name Name of pool to be displayed in NFT image
     + @param _nftDescriptor The contract address for NFTDescriptor, which will return the token URI
    */
    function addPool(
        uint allocPoint,
        IERC20 _poolToken,
        IRewarder _rewarder,
        uint[] calldata requiredMaturity,
        uint[] calldata allocPoints,
        string memory name,
        INFTDescriptor _nftDescriptor
    ) external override onlyRole(OPERATOR) {
        require(_poolToken != rewardToken, "cannot add reward token as pool");
        require(requiredMaturity.length != 0, "empty levels array");
        require(
            requiredMaturity.length == allocPoints.length,
            "array length mismatch"
        );
        require(requiredMaturity[0] == 0, "requiredMaturity[0] != 0");
        if (requiredMaturity.length > 1) {
            uint highestMaturity;
            for (
                uint i = 1;
                i < requiredMaturity.length;
                i = _uncheckedInc(i)
            ) {
                require(
                    requiredMaturity[i] > highestMaturity,
                    "unsorted levels array"
                );
                highestMaturity = requiredMaturity[i];
            }
        }

        uint length = poolLength();
        for (uint i; i < length; i = _uncheckedInc(i)) {
            _updatePool(i);
        }

        uint totalAlloc = totalAllocPoint + allocPoint;
        require(totalAlloc != 0, "totalAllocPoint cannot be 0");
        totalAllocPoint = totalAlloc;
        poolToken.push(_poolToken);
        rewarder.push(_rewarder);
        nftDescriptor.push(_nftDescriptor);

        poolInfo.push(
            PoolInfo({
                allocPoint: allocPoint,
                lastRewardTime: block.timestamp,
                accRewardPerShare: 0,
                name: name
            })
        );
        levels.push(
            LevelInfo({
                requiredMaturity: requiredMaturity,
                allocPoint: allocPoints,
                balance: new uint[](allocPoints.length)
            })
        );

        emit LogPoolAddition(
            (poolToken.length - 1),
            allocPoint,
            _poolToken,
            _rewarder,
            _nftDescriptor
        );
    }

    /*
     + @notice Modify the given pool's properties.
     +         Can only be called by the operator.
     +
     + @param pid The index of the pool. See `poolInfo`.
     + @param allocPoint New AP of the pool.
     + @param _rewarder Address of the rewarder delegate.
     + @param name Name of pool to be displayed in NFT image
     + @param overwriteRewarder True if _rewarder should be set. Otherwise `_rewarder` is ignored.
     + @param _nftDescriptor The contract address for NFTDescriptor, which will return the token URI
    */
    function modifyPool(
        uint pid,
        uint allocPoint,
        IRewarder _rewarder,
        string calldata name,
        INFTDescriptor _nftDescriptor,
        bool overwriteRewarder
    ) external override onlyRole(OPERATOR) {
        require(pid < poolInfo.length, "set: pool does not exist");

        uint length = poolLength();
        for (uint i; i < length; i = _uncheckedInc(i)) {
            _updatePool(i);
        }

        PoolInfo storage pool = poolInfo[pid];
        uint totalAlloc = totalAllocPoint + allocPoint - pool.allocPoint;
        require(totalAlloc != 0, "totalAllocPoint cannot be 0");
        totalAllocPoint = totalAlloc;
        pool.allocPoint = allocPoint;

        if (overwriteRewarder) {
            rewarder[pid] = _rewarder;
        }

        pool.name = name;
        nftDescriptor[pid] = _nftDescriptor;

        emit LogPoolModified(
            pid,
            allocPoint,
            overwriteRewarder ? _rewarder : rewarder[pid],
            _nftDescriptor
        );
    }

    /*
     + @notice View function to see pending reward tokens on frontend.
     + @param relicId ID of the position.
     + @return pending reward amount for a given position owner.
    */
    function pendingReward(uint relicId) public view override returns (uint pending) {
        PositionInfo storage position = positionForId[relicId];
        uint poolId = position.poolId;
        PoolInfo storage pool = poolInfo[poolId];
        uint accRewardPerShare = pool.accRewardPerShare;
        uint lpSupply = _poolBalance(position.poolId);

        uint lastRewardTime = pool.lastRewardTime;
        uint secondsSinceReward = block.timestamp - lastRewardTime;
        if (secondsSinceReward != 0 && lpSupply != 0) {
            uint reward = secondsSinceReward * _baseEmissionsPerSecond(lastRewardTime) * pool.allocPoint / totalAllocPoint;
            accRewardPerShare += reward * ACC_REWARD_PRECISION / lpSupply;
        }

        uint leveledAmount = position.amount * levels[poolId].allocPoint[position.level];
        pending = leveledAmount * accRewardPerShare / ACC_REWARD_PRECISION + position.rewardCredit - position.rewardDebt;
    }

    /*
     + @notice View function to see level of position if it were to be updated.
     + @param relicId ID of the position.
     + @return level Level for given position upon update.
    */
    function levelOnUpdate(uint relicId) public view override returns (uint level) {
        PositionInfo storage position = positionForId[relicId];
        LevelInfo storage levelInfo = levels[position.poolId];
        uint length = levelInfo.requiredMaturity.length;
        if (length == 1) {
            return 0;
        }

        uint maturity = block.timestamp - position.entry;
        for (level = length - 1; true; level = _uncheckedDec(level)) {
            if (maturity >= levelInfo.requiredMaturity[level]) {
                break;
            }
        }
    }

    /*
     + @notice Update reward variables for all pools. Be careful of gas spending!
     + @param pids Pool IDs of all to be updated. Make sure to update all active pools.
    */
    function massUpdatePools(uint[] calldata pids)
        external
        override
        nonReentrant
    {
        for (uint i; i < pids.length; i = _uncheckedInc(i)) {
            _updatePool(pids[i]);
        }
    }

    /*
     + @notice Update reward variables of the given pool.
     + @param pid The index of the pool. See `poolInfo`.
     + @return pool Returns the pool that was updated.
    */
    function updatePool(uint pid) external override nonReentrant {
        _updatePool(pid);
    }

    /// @dev Internal _updatePool function without nonReentrant modifier
    function _updatePool(uint pid) internal returns (uint accRewardPerShare) {
        require(pid < poolLength(), "invalid pool ID");
        PoolInfo storage pool = poolInfo[pid];
        uint timestamp = block.timestamp;
        uint lastRewardTime = pool.lastRewardTime;
        uint secondsSinceReward = timestamp - lastRewardTime;

        accRewardPerShare = pool.accRewardPerShare;
        if (secondsSinceReward != 0) {
            uint lpSupply = _poolBalance(pid);

            if (lpSupply != 0) {
                uint reward = secondsSinceReward * _baseEmissionsPerSecond(lastRewardTime) * pool.allocPoint /
                    totalAllocPoint;
                accRewardPerShare += reward * ACC_REWARD_PRECISION / lpSupply;
                pool.accRewardPerShare = accRewardPerShare;
            }

            pool.lastRewardTime = timestamp;

            emit LogUpdatePool(pid, timestamp, lpSupply, accRewardPerShare);
        }
    }

    /*
     + @notice Create a new Relic NFT and deposit into this position
     + @param to Address to mint the Relic to
     + @param pid The index of the pool. See `poolInfo`.
     + @param amount Token amount to deposit.
    */
    function createRelicAndDeposit(
        address to,
        uint pid,
        uint amount
    ) external override nonReentrant returns (uint id) {
        require(pid < poolInfo.length, "invalid pool ID");
        id = _mint(to);
        positionForId[id].poolId = pid;
        _deposit(amount, id);
        emit CreateRelic(pid, to, id);
    }

    /*
     + @notice Deposit LP tokens to Reliquary for reward token allocation.
     + @param amount Token amount to deposit.
     + @param relicId NFT ID of the position being deposited to.
    */
    function deposit(uint amount, uint relicId) external override nonReentrant {
        _requireApprovedOrOwner(relicId);
        _deposit(amount, relicId);
    }

    /// @dev Internal deposit function that assumes relicId is valid.
    function _deposit(uint amount, uint relicId) internal {
        require(amount != 0, "depositing 0 amount");

        (uint poolId, ) = _updatePosition(amount, relicId, Kind.DEPOSIT, false);

        poolToken[poolId].safeTransferFrom(msg.sender, address(this), amount);

        emit Deposit(poolId, amount, ownerOf(relicId), relicId);
    }

    /*
     + @notice Withdraw LP tokens.
     + @param amount token amount to withdraw.
     + @param relicId NFT ID of the position being withdrawn.
    */
    function withdraw(uint amount, uint relicId)
        external
        override
        nonReentrant
    {
        require(amount != 0, "withdrawing 0 amount");
        _requireApprovedOrOwner(relicId);

        (uint poolId, ) = _updatePosition(
            amount,
            relicId,
            Kind.WITHDRAW,
            false
        );

        poolToken[poolId].safeTransfer(msg.sender, amount);

        emit Withdraw(poolId, amount, msg.sender, relicId);
    }

    /*
     + @notice Harvest proceeds for transaction sender to owner of `relicId`.
     + @param relicId NFT ID of the position being harvested.
    */
    function harvest(uint relicId) external override nonReentrant {
        _requireApprovedOrOwner(relicId);

        (uint poolId, uint _pendingReward) = _updatePosition(0, relicId, Kind.OTHER, true);

        emit Harvest(poolId, _pendingReward, msg.sender, relicId);
    }

    /*
     + @notice Withdraw LP tokens and harvest proceeds for transaction sender to owner of `relicId`.
     + @param amount token amount to withdraw.
     + @param relicId NFT ID of the position being withdrawn and harvested.
    */
    function withdrawAndHarvest(uint amount, uint relicId)
        external
        override
        nonReentrant
    {
        require(amount != 0, "withdrawing 0 amount");
        _requireApprovedOrOwner(relicId);

        (uint poolId, uint _pendingReward) = _updatePosition(amount, relicId, Kind.WITHDRAW, true);

        poolToken[poolId].safeTransfer(msg.sender, amount);

        emit Withdraw(poolId, amount, msg.sender, relicId);
        emit Harvest(poolId, _pendingReward, msg.sender, relicId);
    }

    /*
     + @notice Withdraw without caring about rewards. EMERGENCY ONLY.
     + @param relicId NFT ID of the position to emergency withdraw from and burn.
    */
    function emergencyWithdraw(uint relicId) external override nonReentrant {
        address to = ownerOf(relicId);
        require(to == msg.sender, "you do not own this position");

        PositionInfo storage position = positionForId[relicId];
        uint amount = position.amount;
        uint poolId = position.poolId;

        levels[poolId].balance[position.level] -= amount;

        _burn(relicId);
        delete positionForId[relicId];

        poolToken[poolId].safeTransfer(to, amount);

        emit EmergencyWithdraw(poolId, amount, to, relicId);
    }

    /// @notice Update position without performing a deposit/withdraw/harvest.
    /// @param relicId The NFT ID of the position being updated.
    function updatePosition(uint relicId) external override nonReentrant {
        _updatePosition(0, relicId, Kind.OTHER, false);
    }

    /*
     + @dev Internal function called whenever a position's state needs to be modified.
     + @param amount Amount of poolToken to deposit/withdraw.
     + @param relicId The NFT ID of the position being updated.
     + @param kind Indicates whether tokens are being added to, or removed from, a pool.
     + @param _harvest Whether a harvest should be performed.
     + @return pending reward for a given position owner.
    */
    function _updatePosition(
        uint amount,
        uint relicId,
        Kind kind,
        bool _harvest
    ) internal returns (uint poolId, uint _pendingReward) {
        PositionInfo storage position = positionForId[relicId];
        poolId = position.poolId;
        uint accRewardPerShare = _updatePool(poolId);

        uint oldAmount = position.amount;
        uint newAmount;
        if (kind == Kind.DEPOSIT) {
            _updateEntry(amount, relicId);
            newAmount = oldAmount + amount;
            position.amount = newAmount;
        } else if (kind == Kind.WITHDRAW) {
            newAmount = oldAmount - amount;
            position.amount = newAmount;
        } else {
            newAmount = oldAmount;
        }

        uint oldLevel = position.level;
        uint newLevel = _updateLevel(relicId);
        if (oldLevel != newLevel) {
            levels[poolId].balance[oldLevel] -= oldAmount;
            levels[poolId].balance[newLevel] += newAmount;
        } else if (kind == Kind.DEPOSIT) {
            levels[poolId].balance[oldLevel] += amount;
        } else if (kind == Kind.WITHDRAW) {
            levels[poolId].balance[oldLevel] -= amount;
        }

        _pendingReward = oldAmount * levels[poolId].allocPoint[oldLevel] * accRewardPerShare
            / ACC_REWARD_PRECISION - position.rewardDebt;
        position.rewardDebt = newAmount * levels[poolId].allocPoint[newLevel] * accRewardPerShare
            / ACC_REWARD_PRECISION;

        if (!_harvest && _pendingReward != 0) {
            position.rewardCredit += _pendingReward;
        } else if (_harvest) {
            uint total = _pendingReward + position.rewardCredit;
            uint received = _receivedReward(total);
            position.rewardCredit = total - received;
            if (received != 0) {
                rewardToken.safeTransfer(msg.sender, received);
                IRewarder _rewarder = rewarder[poolId];
                if (address(_rewarder) != address(0)) {
                    _rewarder.onReward(relicId, received);
                }
            }
        }

        if (kind == Kind.DEPOSIT) {
            IRewarder _rewarder = rewarder[poolId];
            if (address(_rewarder) != address(0)) {
                _rewarder.onDeposit(relicId, amount);
            }
        } else if (kind == Kind.WITHDRAW) {
            IRewarder _rewarder = rewarder[poolId];
            if (address(_rewarder) != address(0)) {
                _rewarder.onWithdraw(relicId, amount);
            }
        }
    }

    /// @notice Split an owned Relic into a new one, while maintaining maturity
    /// @param fromId The NFT ID of the Relic to split from
    /// @param amount Amount to move from existing Relic into the new one
    /// @param to Address to mint the Relic to
    /// @return newId The NFT ID of the new Relic
    function split(
        uint fromId,
        uint amount,
        address to
    ) external override nonReentrant returns (uint newId) {
        require(amount != 0, "cannot split zero amount");
        _requireApprovedOrOwner(fromId);

        PositionInfo storage fromPosition = positionForId[fromId];
        uint fromAmount = fromPosition.amount;
        require(amount <= fromAmount, "amount exceeds deposited");
        uint newFromAmount = fromAmount - amount;
        fromPosition.amount = newFromAmount;

        newId = _mint(to);
        PositionInfo storage newPosition = positionForId[newId];
        newPosition.amount = amount;
        newPosition.entry = fromPosition.entry;
        uint level = fromPosition.level;
        newPosition.level = level;
        uint poolId = fromPosition.poolId;
        newPosition.poolId = poolId;

        uint multiplier = _updatePool(poolId) * levels[poolId].allocPoint[level];
        uint pendingFrom = fromAmount * multiplier / ACC_REWARD_PRECISION - fromPosition.rewardDebt;
        if (pendingFrom != 0) {
            fromPosition.rewardCredit += pendingFrom;
        }
        fromPosition.rewardDebt = newFromAmount * multiplier / ACC_REWARD_PRECISION;
        newPosition.rewardDebt = amount * multiplier / ACC_REWARD_PRECISION;

        emit Split(fromId, newId, amount);
    }

    /// @notice Transfer amount from one Relic into another, updating maturity in the receiving Relic
    /// @param fromId The NFT ID of the Relic to transfer from
    /// @param toId The NFT ID of the Relic being transferred to
    /// @param amount The amount being transferred
    function shift(
        uint fromId,
        uint toId,
        uint amount
    ) external override nonReentrant {
        require(amount != 0, "cannot shift zero amount");
        require(fromId != toId, "cannot shift into same Relic");
        _requireApprovedOrOwner(fromId);
        _requireApprovedOrOwner(toId);

        PositionInfo storage fromPosition = positionForId[fromId];
        uint fromAmount = fromPosition.amount;
        require(amount <= fromAmount, "amount exceeds deposited");

        uint poolId = fromPosition.poolId;
        PositionInfo storage toPosition = positionForId[toId];
        require(poolId == toPosition.poolId, "Relics not of the same pool");

        uint toAmount = toPosition.amount;
        toPosition.entry =
            (fromAmount * fromPosition.entry + toAmount * toPosition.entry) /
            (fromAmount + toAmount);

        uint newFromAmount = fromAmount - amount;
        fromPosition.amount = newFromAmount;

        uint newToAmount = toAmount + amount;
        toPosition.amount = newToAmount;

        (
            uint fromLevel,
            uint oldToLevel,
            uint newToLevel
        ) = _shiftLevelBalances(
                fromId,
                toId,
                poolId,
                amount,
                toAmount,
                newToAmount
            );

        uint accRewardPerShare = _updatePool(poolId);
        uint fromMultiplier = accRewardPerShare * levels[poolId].allocPoint[fromLevel];
        uint pendingFrom = fromAmount * fromMultiplier / ACC_REWARD_PRECISION - fromPosition.rewardDebt;
        if (pendingFrom != 0) {
            fromPosition.rewardCredit += pendingFrom;
        }
        uint pendingTo = toAmount * levels[poolId].allocPoint[oldToLevel] * accRewardPerShare
            / ACC_REWARD_PRECISION - toPosition.rewardDebt;
        if (pendingTo != 0) {
            toPosition.rewardCredit += pendingTo;
        }
        fromPosition.rewardDebt = newFromAmount * fromMultiplier / ACC_REWARD_PRECISION;
        toPosition.rewardDebt = newToAmount * accRewardPerShare * levels[poolId].allocPoint[newToLevel]
            / ACC_REWARD_PRECISION;

        emit Shift(fromId, toId, amount);
    }

    /// @notice Transfer entire position (including rewards) from one Relic into another, burning it
    /// and updating maturity in the receiving Relic
    /// @param fromId The NFT ID of the Relic to transfer from
    /// @param toId The NFT ID of the Relic being transferred to
    function merge(uint fromId, uint toId) external override nonReentrant {
        require(fromId != toId, "cannot merge same Relic");
        _requireApprovedOrOwner(fromId);
        _requireApprovedOrOwner(toId);

        PositionInfo storage fromPosition = positionForId[fromId];
        uint fromAmount = fromPosition.amount;

        uint poolId = fromPosition.poolId;
        PositionInfo storage toPosition = positionForId[toId];
        require(poolId == toPosition.poolId, "Relics not of the same pool");

        uint toAmount = toPosition.amount;
        uint newToAmount = toAmount + fromAmount;
        require(newToAmount != 0, "cannot merge empty Relics");
        toPosition.entry =
            (fromAmount * fromPosition.entry + toAmount * toPosition.entry) /
            newToAmount;

        toPosition.amount = newToAmount;

        (
            uint fromLevel,
            uint oldToLevel,
            uint newToLevel
        ) = _shiftLevelBalances(
                fromId,
                toId,
                poolId,
                fromAmount,
                toAmount,
                newToAmount
            );

        uint accRewardPerShare = _updatePool(poolId);
        uint pendingTo = accRewardPerShare * (fromAmount * levels[poolId].allocPoint[fromLevel]
            + toAmount * levels[poolId].allocPoint[oldToLevel])
            / ACC_REWARD_PRECISION + fromPosition.rewardCredit - fromPosition.rewardDebt - toPosition.rewardDebt;
        if (pendingTo != 0) {
            toPosition.rewardCredit += pendingTo;
        }
        toPosition.rewardDebt = newToAmount * accRewardPerShare * levels[poolId].allocPoint[newToLevel]
            / ACC_REWARD_PRECISION;

        _burn(fromId);
        delete positionForId[fromId];

        emit Merge(fromId, toId, fromAmount);
    }

    function _shiftLevelBalances(
        uint fromId,
        uint toId,
        uint poolId,
        uint amount,
        uint toAmount,
        uint newToAmount
    )
        internal
        returns (
            uint fromLevel,
            uint oldToLevel,
            uint newToLevel
        )
    {
        fromLevel = positionForId[fromId].level;
        oldToLevel = positionForId[toId].level;
        newToLevel = _updateLevel(toId);
        if (fromLevel != newToLevel) {
            levels[poolId].balance[fromLevel] -= amount;
        }
        if (oldToLevel != newToLevel) {
            levels[poolId].balance[oldToLevel] -= toAmount;
        }
        if (fromLevel != newToLevel && oldToLevel != newToLevel) {
            levels[poolId].balance[newToLevel] += newToAmount;
        } else if (fromLevel != newToLevel) {
            levels[poolId].balance[newToLevel] += amount;
        } else if (oldToLevel != newToLevel) {
            levels[poolId].balance[newToLevel] += toAmount;
        }
    }

    /// @notice Calculate how much the owner will actually receive on harvest, given available reward tokens
    /// @param _pendingReward Amount of reward token owed
    /// @return received The minimum between amount owed and amount available
    function _receivedReward(uint _pendingReward) internal view returns (uint received) {
        uint available = rewardToken.balanceOf(address(this));
        received = (available > _pendingReward) ? _pendingReward : available;
    }

    /// @notice Gets the base emission rate from external, upgradable contract
    function _baseEmissionsPerSecond(uint lastRewardTime) internal view returns (uint rate) {
        rate = emissionCurve.getRate(lastRewardTime);
        require(rate <= 6e18, "maximum emission rate exceeded");
    }

    /*
     + @notice Utility function to find weights without any underflows or zero division problems.
     + @param addedValue New value being added
     + @param oldValue Current amount of x
    */
    function _findWeight(uint addedValue, uint oldValue)
        internal
        pure
        returns (uint weightNew)
    {
        if (oldValue == 0) {
            weightNew = 1e18;
        } else {
            if (oldValue < addedValue) {
                uint weightOld = (oldValue * 1e18) / (addedValue + oldValue);
                weightNew = 1e18 - weightOld;
            } else if (addedValue < oldValue) {
                weightNew = (addedValue * 1e18) / (addedValue + oldValue);
            } else {
                weightNew = 1e18 / 2;
            }
        }
    }

    /*
     + @notice Updates the user's entry time based on the weight of their deposit or withdrawal
     + @param amount The amount of the deposit / withdrawal
     + @param relicId The NFT ID of the position being updated
    */
    function _updateEntry(uint amount, uint relicId) internal {
        PositionInfo storage position = positionForId[relicId];
        uint weight = _findWeight(amount, position.amount);
        uint maturity = block.timestamp - position.entry;
        position.entry += (maturity * weight) / 1e18;
    }

    /*
     + @notice Updates the position's level based on entry time
     + @param relicId The NFT ID of the position being updated
     + @return newLevel Level of position after update
    */
    function _updateLevel(uint relicId) internal returns (uint newLevel) {
        newLevel = levelOnUpdate(relicId);
        PositionInfo storage position = positionForId[relicId];
        if (position.level != newLevel) {
            position.level = newLevel;
            emit LevelChanged(relicId, newLevel);
        }
    }

    /*
     + @notice returns The total deposits of the pool's token, weighted by maturity level allocation.
     + @param pid The index of the pool. See `poolInfo`.
     + @return The amount of pool tokens held by the contract
    */
    function _poolBalance(uint pid) internal view returns (uint total) {
        LevelInfo storage levelInfo = levels[pid];
        uint length = levelInfo.balance.length;
        for (uint i; i < length; i = _uncheckedInc(i)) {
            total += levelInfo.balance[i] * levelInfo.allocPoint[i];
        }
    }

    /// @notice Require the sender is either the owner of the Relic or approved to transfer it
    /// @param relicId The NFT ID of the Relic
    function _requireApprovedOrOwner(uint relicId) internal view {
        require(
            _isApprovedOrOwner(msg.sender, relicId),
            "not owner or approved"
        );
    }

    /// @dev Utility function to bypass overflow checking, saving gas
    function _uncheckedInc(uint i) internal pure returns (uint) {
        unchecked {
            return i + 1;
        }
    }

    /// @dev Utility function to bypass underflow checking, saving gas
    function _uncheckedDec(uint i) internal pure returns (uint) {
        unchecked {
            return i - 1;
        }
    }

    function _mint(address to) private returns (uint id) {
        id = ++nonce;
        _safeMint(to, id);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        ERC721Enumerable._beforeTokenTransfer(from, to, tokenId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-contracts/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "./IEmissionCurve.sol";
import "./INFTDescriptor.sol";
import "./IRewarder.sol";

/*
 + @notice Info for each Reliquary position.
 + `amount` LP token amount the position owner has provided
 + `rewardDebt` Amount of reward token accumalated before the position's entry or last harvest
 + `rewardCredit` Amount of reward token owed to the user on next harvest
 + `entry` Used to determine the maturity of the position
 + `poolId` ID of the pool to which this position belongs
 + `level` Index of this position's level within the pool's array of levels
*/
struct PositionInfo {
    uint amount;
    uint rewardDebt;
    uint rewardCredit;
    uint entry; // position owner's relative entry into the pool.
    uint poolId; // ensures that a single Relic is only used for one pool.
    uint level;
}

/*
 + @notice Info of each Reliquary pool
 + `accRewardPerShare` Accumulated reward tokens per share of pool (1 / 1e12)
 + `lastRewardTime` Last timestamp the accumulated reward was updated
 + `allocPoint` Pool's individual allocation - ratio of the total allocation
 + `name` Name of pool to be displayed in NFT image
*/
struct PoolInfo {
    uint accRewardPerShare;
    uint lastRewardTime;
    uint allocPoint;
    string name;
}

/*
 + @notice Level that determines how maturity is rewarded
 + `requiredMaturity` The minimum maturity (in seconds) required to reach this Level
 + `allocPoint` Level's individual allocation - ratio of the total allocation
 + `balance` Total number of tokens deposited in positions at this Level
*/
struct LevelInfo {
    uint[] requiredMaturity;
    uint[] allocPoint;
    uint[] balance;
}

interface IReliquary is IERC721Enumerable {

  function burn(uint tokenId) external;
  function setEmissionCurve(IEmissionCurve _emissionCurve) external;
  function supportsInterface(bytes4 interfaceId) external view returns (bool);
  function addPool(
        uint allocPoint,
        IERC20 _poolToken,
        IRewarder _rewarder,
        uint[] calldata requiredMaturity,
        uint[] calldata allocPoints,
        string memory name,
        INFTDescriptor _nftDescriptor
    ) external;
  function modifyPool(
        uint pid,
        uint allocPoint,
        IRewarder _rewarder,
        string calldata name,
        INFTDescriptor _nftDescriptor,
        bool overwriteRewarder
    ) external;
  function pendingReward(uint relicId) external view returns (uint pending);
  function levelOnUpdate(uint relicId) external view returns (uint level);
  function massUpdatePools(uint[] calldata pids) external;
  function updatePool(uint pid) external;
  function createRelicAndDeposit(
        address to,
        uint pid,
        uint amount
    ) external returns (uint id);
  function deposit(uint amount, uint relicId) external;
  function withdraw(uint amount, uint relicId) external;
  function harvest(uint relicId) external;
  function withdrawAndHarvest(uint amount, uint relicId) external;
  function emergencyWithdraw(uint relicId) external;
  function updatePosition(uint relicId) external;
  function split(uint relicId, uint amount, address to) external returns (uint newId);
  function shift(uint fromId, uint toId, uint amount) external;
  function merge(uint fromId, uint toId) external;

  // State

  function rewardToken() external view returns (IERC20);
  function nftDescriptor(uint) external view returns (INFTDescriptor);
  function emissionCurve() external view returns (IEmissionCurve);
  function getPoolInfo(uint) external view returns (PoolInfo memory);
  function getLevelInfo(uint) external view returns (LevelInfo memory);
  function poolToken(uint) external view returns (IERC20);
  function rewarder(uint) external view returns (IRewarder);

  function getPositionForId(uint) external view returns (PositionInfo memory);
  function totalAllocPoint() external view returns (uint);
  function poolLength() external view returns (uint);

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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/extensions/ERC721Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "../../../utils/Context.sol";

/**
 * @title ERC721 Burnable Token
 * @dev ERC721 Token that can be burned (destroyed).
 */
abstract contract ERC721Burnable is Context, ERC721 {
    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) public virtual {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
        _burn(tokenId);
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Multicall.sol)

pragma solidity ^0.8.0;

import "./Address.sol";

/**
 * @dev Provides a function to batch together multiple calls in a single external call.
 *
 * _Available since v4.1._
 */
abstract contract Multicall {
    /**
     * @dev Receives and executes a batch of function calls on this contract.
     */
    function multicall(bytes[] calldata data) external virtual returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            results[i] = Address.functionDelegateCall(address(this), data[i]);
        }
        return results;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlEnumerable.sol";
import "./AccessControl.sol";
import "../utils/structs/EnumerableSet.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerable is IAccessControlEnumerable, AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(bytes32 => EnumerableSet.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view virtual override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view virtual override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {_grantRole} to track enumerable memberships
     */
    function _grantRole(bytes32 role, address account) internal virtual override {
        super._grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {_revokeRole} to track enumerable memberships
     */
    function _revokeRole(bytes32 role, address account) internal virtual override {
        super._revokeRole(role, account);
        _roleMembers[role].remove(account);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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

pragma solidity ^0.8.15;

interface IEmissionCurve {
    function getRate(uint lastRewardTime) external view returns (uint rate);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

interface INFTDescriptor {
    function constructTokenURI(uint relicId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

interface IRewarder {
    function onReward(
        uint relicId,
        uint rewardAmount
    ) external;

    function onDeposit(
        uint relicId,
        uint depositAmount
    ) external;

    function onWithdraw(
        uint relicId,
        uint withdrawalAmount
    ) external;

    function pendingTokens(
        uint relicId,
        uint rewardAmount
    ) external view returns (IERC20[] memory, uint[] memory);
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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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
            "ERC721: approve caller is not token owner or approved for all"
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
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");

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
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
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
     * This is an internal function that does not check if the sender is authorized to operate on the token.
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
        delete _tokenApprovals[tokenId];

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
        delete _tokenApprovals[tokenId];

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
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable is IAccessControl {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(account),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
 * ====
 */
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
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
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
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
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
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
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
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
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
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
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
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
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
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
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
    function values(AddressSet storage set) internal view returns (address[] memory) {
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
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
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
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
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
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
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
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
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