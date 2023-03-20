// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import "./interface/IERC721.sol";
import "./interface/IFactory.sol";

interface Dao {
    function getVotingStatus(address _user) external view returns (bool);
}

interface IUniswapV3PositionUtility{
    function getAstraAmount (uint256 _tokenID) external view returns (uint256);
}

contract MasterChefV2 is Initializable, OwnableUpgradeable, IERC721ReceiverUpgradeable {
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        uint256 maxStakingScore;
        uint256 maxMultiplier;
        uint256 lastDeposit;
        bool cooldown;
        uint256 cooldowntimestamp;
        //
        // We do some fancy math here. Basically, any point in time, the amount of ASTRAs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accAstraPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accAstraPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20Upgradeable lpToken; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. ASTRAs to distribute per block.
        uint256 lastRewardBlock; // Last block number that ASTRAs distribution occurs.
        uint256 accAstraPerShare; // Accumulated ASTRAs per share, times 1e12. See below.
        uint256 totalStaked;
        uint256 maxMultiplier; // Total Astra staked amount.
    }

    //staking info structure
    struct StakeInfo {
        uint256 amount;
        uint256 timestamp;
        uint256 vault;
        uint256 withdrawTime;
        uint256 tokenId;
        bool isERC721;
    }

    //Highest staked users
    struct HighestAstaStaker {
        uint256 deposited;
        address addr;
    }

    // The ASTRA TOKEN!
    IERC20Upgradeable public astra;
    // Dev address.
    address public governanceAddress;
    IUniswapV3PositionUtility public uniswapUtility;

    IERC721 public erc721Token;
    // Block number when bonus ASTRA period ends.
    uint256 public bonusEndBlock;
    // ASTRA tokens created per block.
    uint256 public astraPerBlock;
    uint256 public constant ZERO_MONTH_VAULT = 0;
    uint256 public constant SIX_MONTH_VAULT = 6;
    uint256 public constant NINE_MONTH_VAULT = 9;
    uint256 public constant TWELVE_MONTH_VAULT = 12;
    uint256 public constant AVG_STAKING_SCORE_CAL_TIME = 60;
    uint256 public constant MAX_STAKING_SCORE_CAL_TIME_SECONDS = 5184000;
    uint256 public constant SECONDS_IN_DAY = 86400;
    uint256 public constant STAKING_SCORE_TIME_CONSTANT = 5184000;
    uint256 public constant VAULT_MULTIPLIER_FOR_STAKING_SCORE = 5;
    uint256 public constant MULTIPLIER_DECIMAL = 10000000000000;
    uint256 public constant SLASHING_FEES_CONSTANT = 90;
    uint256 public constant DEFAULT_POOL = 0;
    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // Total allocation poitns. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint;
    // The block number when ASTRA rewards distribution starts.
    uint256 public startBlock;
    uint256 public totalRewards;
    uint256 public maxPerBlockReward;
    uint256 public constant coolDownPeriodTime = 1;
    uint256 public constant coolDownClaimTime = 1;

    mapping(uint256 => mapping(address => uint256)) private userStakeCounter;
    mapping(uint256 => mapping(address => mapping(uint256 => StakeInfo)))
        public userStakeInfo;
    mapping(uint256 => bool) public isValidVault;
    mapping(uint256 => uint256) public usersTotalStakedInVault;
    mapping(uint256 => uint256) public stakingVaultMultiplier;

    mapping(uint256 => HighestAstaStaker[]) public highestStakerInPool;
    mapping(address => bool) public isAllowedContract;

    mapping(address => uint256) public unClaimedReward;
    mapping(address => mapping(address => bool)) public lpTokensStatus;
    bool private isFirstDepositInitialized;

    mapping(uint256 => mapping(address => uint256)) public averageStakedTime;
    // mapping(address => uint256) public unClaimedMultiplier;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );
    event AddPool(address indexed token0, address indexed token1);

    /**
    @notice This function is used for initializing the contract with sort of parameter
    @param _astra : astra contract address
    @param _startBlock : start block number for starting rewars distribution
    @param _bonusEndBlock : end block number for ending reward distribution
    @param _totalRewards : Total ASTRA rewards
    @dev Description :
    This function is basically used to initialize the necessary things of chef contract and set the owner of the
    contract. This function definition is marked "external" because this fuction is called only from outside the contract.
    */
    function initialize(
        IERC20Upgradeable _astra,
        uint256 _startBlock,
        uint256 _bonusEndBlock,
        uint256 _totalRewards
    ) external initializer {
        require(address(_astra) != address(0), "Zero Address");
        __Ownable_init();
        astra = _astra;
        bonusEndBlock = _bonusEndBlock;
        startBlock = _startBlock;
        totalRewards = _totalRewards;
        maxPerBlockReward = totalRewards.div(bonusEndBlock.sub(startBlock));
        astraPerBlock = totalRewards.div(bonusEndBlock.sub(startBlock));
        isValidVault[ZERO_MONTH_VAULT] = true;
        isValidVault[SIX_MONTH_VAULT] = true;
        isValidVault[NINE_MONTH_VAULT] = true;
        isValidVault[TWELVE_MONTH_VAULT] = true;
        stakingVaultMultiplier[ZERO_MONTH_VAULT] = 10000000000000;
        stakingVaultMultiplier[SIX_MONTH_VAULT] = 11000000000000;
        stakingVaultMultiplier[NINE_MONTH_VAULT] = 13000000000000;
        stakingVaultMultiplier[TWELVE_MONTH_VAULT] = 18000000000000;
        add(100, _astra);
        // updateRewardRate(startBlock,1, 1, 0);
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(
        uint256 _allocPoint,
        IERC20Upgradeable _lpToken
    ) internal {
        uint256 lastRewardBlock = block.number > startBlock
            ? block.number
            : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(
            PoolInfo({
                lpToken: _lpToken,
                allocPoint: _allocPoint,
                lastRewardBlock: lastRewardBlock,
                accAstraPerShare: 0,
                totalStaked: 0,
                maxMultiplier: MULTIPLIER_DECIMAL
            })
        );
    }

        // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function addUniswapVersion3(
        IERC721 _erc721Token,
        address _token0,
        address _token1,
        uint24 fee,
        bool _withUpdate
    ) public onlyOwner {
        require(address(_erc721Token) != address(0), "Zero Address");
        require(_token0 != address(0), "Zero Address");
        require(_token1 != address(0), "Zero Address");
        require(
            IUniswapV3Factory(_erc721Token.factory()).getPool(
                _token0,
                _token1,
                fee
            ) != address(0),
            "Pair not created"
        );

        erc721Token = _erc721Token;

        if (_withUpdate) {
            updatePool();
        }
        // Setting the lp token status true becuase pool is active.
        lpTokensStatus[_token0][_token1] = true;
        lpTokensStatus[_token1][_token0] = true;

        emit AddPool(_token0, _token1);
    }

    /**
    @notice Add vault month. Can only be called by the owner.
    @param _vault : value of month like 0, 3, 6, 9, 12
    @dev    this function definition is marked "external" because this fuction is called only from outside the contract.
    */
    function addVault(uint256 _vault) external onlyOwner {
        isValidVault[_vault] = true;
    }

    /**
    @notice Add contract address. Can only be called by the owner.
    @param _contractAddress : Contract address.
    @dev    Add contract address for external deposit.
    */
    function whitelistDepositContract(address _contractAddress, bool _value)
        external
        onlyOwner
    {
        isAllowedContract[_contractAddress] = _value;
    }

    // Update dev address by the previous dev.
    function setGovernanceAddress(address _governanceAddress)
        external
        onlyOwner
    {
        governanceAddress = _governanceAddress;
    }

    function setUtilityContractAddress(IUniswapV3PositionUtility _uniswapUtility) external onlyOwner{
        uniswapUtility = _uniswapUtility;
    }

    // Update the given pool's ASTRA allocation point. Can only be called by the owner.
    function set(
        
        uint256 _allocPoint,
        bool _withUpdate
    ) public onlyOwner {
        if (_withUpdate) {
            updatePool();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[DEFAULT_POOL].allocPoint).add(
            _allocPoint
        );
        poolInfo[DEFAULT_POOL].allocPoint = _allocPoint;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to)
        public
        view
        returns (uint256)
    {
        if (_to <= bonusEndBlock) {
            return _to.sub(_from);
        } else if (_from >= bonusEndBlock) {
            return _to.sub(_from);
        } else {
            return
                bonusEndBlock.sub(_from).add(
                    _to.sub(bonusEndBlock)
                );
        }
    }

    // View function to see pending ASTRAs on frontend.
    function pendingAstra( address _user)
        external
        view
        returns (uint256)
    {
        PoolInfo storage pool = poolInfo[DEFAULT_POOL];
        UserInfo storage user = userInfo[DEFAULT_POOL][_user];
        uint256 accAstraPerShare = pool.accAstraPerShare;
        uint256 lpSupply = pool.totalStaked;
        uint256 PoolEndBlock = block.number;
        uint256 userMultiplier;
        if (block.number > bonusEndBlock) {
            // If current block number is greater than bonusEndBlock than PoolEndBlock will have the bonusEndBlock value.
            // otherwise it will have current block number value.
            PoolEndBlock = bonusEndBlock;
        }
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(
                pool.lastRewardBlock,
                PoolEndBlock
            );
            uint256 astraReward = multiplier
                .mul(astraPerBlock)
                .mul(pool.allocPoint)
                .div(totalAllocPoint);
            accAstraPerShare = accAstraPerShare.add(
                astraReward.mul(1e12).div(lpSupply)
            );
        }
        (, userMultiplier, ) = stakingScoreAndMultiplier(
            _user,
            user.amount
        );
        return
            unClaimedReward[_user]
                .add(
                    (
                        user.amount.mul(accAstraPerShare).div(1e12).sub(
                            user.rewardDebt
                        )
                    )
                )
                .mul(userMultiplier)
                .div(MULTIPLIER_DECIMAL);
    }

    function restakeAstraReward() public {
        updatePool();
        PoolInfo storage pool = poolInfo[DEFAULT_POOL];
        UserInfo storage user = userInfo[DEFAULT_POOL][msg.sender];
        uint256 userMaxMultiplier;
        uint256 claimableReward;
        uint256 slashedReward;
        uint256 newPoolMaxMultiplier;

        (, , userMaxMultiplier) = stakingScoreAndMultiplier(
            
            msg.sender,
            user.amount
        );

        claimableReward = unClaimedReward[msg.sender].add(
            (
                (
                    user.amount.mul(pool.accAstraPerShare).div(1e12).sub(
                        user.rewardDebt
                    )
                ).mul(userMaxMultiplier).div(MULTIPLIER_DECIMAL)
            )
        );

            updateUserDepositDetails(
                msg.sender,
                claimableReward,
                SIX_MONTH_VAULT,
                0,
                false
            );

            (, , userMaxMultiplier) = stakingScoreAndMultiplier(
                msg.sender,
                user.amount.add(claimableReward)
            );
            newPoolMaxMultiplier = user
                .amount
                .add(claimableReward)
                .mul(userMaxMultiplier)
                .add(pool.totalStaked.mul(pool.maxMultiplier))
                .sub(user.amount.mul(user.maxMultiplier))
                .div(pool.totalStaked.add(claimableReward));
            user.amount = user.amount.add(claimableReward);
            pool.totalStaked = pool.totalStaked.add(claimableReward);
            user.maxMultiplier = userMaxMultiplier;

            pool.maxMultiplier = newPoolMaxMultiplier;
        user.rewardDebt = user.amount.mul(pool.accAstraPerShare).div(1e12);
        unClaimedReward[msg.sender] = 0;
        updateRewardRate(
            pool.lastRewardBlock,
            pool.maxMultiplier,
            slashedReward
        );
        emit Deposit(msg.sender, DEFAULT_POOL, claimableReward);
    }

    function claimAstra() public {
        updatePool();
        PoolInfo storage pool = poolInfo[DEFAULT_POOL];
        UserInfo storage user = userInfo[DEFAULT_POOL][msg.sender];
        uint256 userMultiplier;
        uint256 userMaxMultiplier;
        uint256 slashedReward;
        uint256 claimableReward;
        uint256 slashingFees;

        (, userMultiplier, userMaxMultiplier) = stakingScoreAndMultiplier(
            msg.sender,
            user.amount
        );
        claimableReward = unClaimedReward[msg.sender].add(
            (
                user.amount.mul(pool.accAstraPerShare).div(1e12).sub(
                    user.rewardDebt
                )
            )
        );
        if (userMaxMultiplier > userMultiplier) {
            slashedReward = (
                claimableReward.mul(userMaxMultiplier).sub(
                    claimableReward.mul(userMultiplier)
                )
            ).div(MULTIPLIER_DECIMAL);
        }

        claimableReward = claimableReward
            .mul(userMaxMultiplier)
            .div(MULTIPLIER_DECIMAL)
            .sub(slashedReward);
        uint256 slashDays = block.timestamp.sub(averageStakedTime[DEFAULT_POOL][msg.sender]).div(
            SECONDS_IN_DAY
        );
        if (slashDays < 90 && slashDays >= 0) {
            slashingFees = claimableReward
                .mul(SLASHING_FEES_CONSTANT.sub(slashDays))
                .div(100);
        }
        slashedReward = slashedReward.add(slashingFees);
        user.rewardDebt = user.amount.mul(pool.accAstraPerShare).div(1e12);
        safeAstraTransfer(msg.sender, claimableReward.sub(slashingFees));
        updateRewardRate(
            pool.lastRewardBlock,
            pool.maxMultiplier,
            slashedReward
        );
        unClaimedReward[msg.sender] = 0;
    }

    // Update reward vairables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool();
        }
    }

    function updateRewardRate(
        uint256 lastUpdatedBlock,
        uint256 newMaxMultiplier,
        uint256 slashedReward
    ) internal {
        uint256 _startBlock = lastUpdatedBlock >= bonusEndBlock
            ? bonusEndBlock
            : lastUpdatedBlock;
        uint256 blockLeft = bonusEndBlock.sub(_startBlock);
        if (blockLeft > 0) {
            if (!isFirstDepositInitialized) {
                maxPerBlockReward = totalRewards.div(blockLeft);
                isFirstDepositInitialized = true;
            } else {
                maxPerBlockReward = slashedReward
                    .add(maxPerBlockReward.mul(blockLeft))
                    .mul(MULTIPLIER_DECIMAL)
                    .div(blockLeft)
                    .div(MULTIPLIER_DECIMAL);
            }
            astraPerBlock = blockLeft
                .mul(maxPerBlockReward)
                .mul(MULTIPLIER_DECIMAL)
                .div(blockLeft)
                .div(newMaxMultiplier);
        }
    }

    function updateUserAverageSlashingFees( address _userAddress, uint256 previousDepositAmount, uint256 newDepositAmount, uint256 currentTimestamp) internal {
        if(averageStakedTime[DEFAULT_POOL][_userAddress] == 0){
            averageStakedTime[DEFAULT_POOL][_userAddress] = currentTimestamp;
        }else{
            uint256 previousDepositedWeight = averageStakedTime[DEFAULT_POOL][_userAddress].mul(previousDepositAmount);
            uint256 newDepositedWeight = newDepositAmount.mul(currentTimestamp);
            averageStakedTime[DEFAULT_POOL][_userAddress] = newDepositedWeight.add(previousDepositedWeight).div(previousDepositAmount.add(newDepositAmount));
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool() public {
        PoolInfo storage pool = poolInfo[DEFAULT_POOL];
        // PoolEndBlock is nothing just contains the value of end block.
        uint256 PoolEndBlock = block.number;
        if (block.number > bonusEndBlock) {
            // If current block number is greater than bonusEndBlock than PoolEndBlock will have the bonusEndBlock value.
            // otherwise it will have current block number value.
            PoolEndBlock = bonusEndBlock;
        }
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.totalStaked;
        if (lpSupply == 0) {
            pool.lastRewardBlock = PoolEndBlock;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, PoolEndBlock);
        uint256 astraReward = multiplier
            .mul(astraPerBlock)
            .mul(pool.allocPoint)
            .div(totalAllocPoint);
        pool.accAstraPerShare = pool.accAstraPerShare.add(
            astraReward.mul(1e12).div(lpSupply)
        );

        pool.lastRewardBlock = PoolEndBlock;
    }

    function calculateMultiplier(uint256 _stakingScore)
        public
        pure
        returns (uint256)
    {
        if (_stakingScore >= 100000 ether && _stakingScore < 300000 ether) {
            return 12000000000000;
        } else if (
            _stakingScore >= 300000 ether && _stakingScore < 800000 ether
        ) {
            return 13000000000000;
        } else if (_stakingScore >= 800000 ether) {
            return 17000000000000;
        } else {
            return 10000000000000;
        }
    }

    function stakingScoreAndMultiplier(
        
        address _userAddress,
        uint256 _stakedAmount
    )
        public
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 currentStakingScore;
        uint256 currentMultiplier;
        uint256 vaultMultiplier;
        uint256 multiplierPerStake;
        uint256 maxMultiplier;
        for (uint256 i = 0; i < userStakeCounter[DEFAULT_POOL][_userAddress]; i++) {
            StakeInfo memory stakerDetails = userStakeInfo[DEFAULT_POOL][_userAddress][
                i
            ];
            if (
                stakerDetails.withdrawTime == 0 ||
                stakerDetails.withdrawTime == block.timestamp
            ) {
                uint256 stakeTime = block.timestamp.sub(
                    stakerDetails.timestamp
                );
                stakeTime = stakeTime >= STAKING_SCORE_TIME_CONSTANT
                    ? STAKING_SCORE_TIME_CONSTANT
                    : stakeTime;
                multiplierPerStake = multiplierPerStake.add(
                    stakerDetails.amount.mul(
                        stakingVaultMultiplier[stakerDetails.vault]
                    )
                );
                if (stakerDetails.vault == TWELVE_MONTH_VAULT) {
                    currentStakingScore = currentStakingScore.add(
                        stakerDetails.amount
                    );
                } else {
                    uint256 userStakedTime = block.timestamp.sub(
                        stakerDetails.timestamp
                    ) >= MAX_STAKING_SCORE_CAL_TIME_SECONDS
                        ? MAX_STAKING_SCORE_CAL_TIME_SECONDS
                        : block.timestamp.sub(stakerDetails.timestamp);
                    uint256 tempCalculatedStakingScore = (
                        stakerDetails.amount.mul(userStakedTime)
                    ).div(
                            AVG_STAKING_SCORE_CAL_TIME
                                .sub(
                                    stakerDetails.vault.mul(
                                        VAULT_MULTIPLIER_FOR_STAKING_SCORE
                                    )
                                )
                                .mul(SECONDS_IN_DAY)
                        );
                    uint256 finalStakingScoreForCurrentStake = tempCalculatedStakingScore >=
                            stakerDetails.amount
                            ? stakerDetails.amount
                            : tempCalculatedStakingScore;
                    currentStakingScore = currentStakingScore.add(
                        finalStakingScoreForCurrentStake
                    );
                }
            }
        }
        if (_stakedAmount == 0) {
            vaultMultiplier = MULTIPLIER_DECIMAL;
        } else {
            vaultMultiplier = multiplierPerStake.div(_stakedAmount);
        }
        currentMultiplier = vaultMultiplier
            .add(calculateMultiplier(currentStakingScore))
            .sub(MULTIPLIER_DECIMAL);
        maxMultiplier = vaultMultiplier
            .add(calculateMultiplier(_stakedAmount))
            .sub(MULTIPLIER_DECIMAL);
        return (currentStakingScore, currentMultiplier, maxMultiplier);
    }

    function updateUserDepositDetails(
        
        address _userAddress,
        uint256 _amount,
        uint256 _vault,
        uint256 __tokenId,
        bool _isERC721
    ) internal {
        uint256 userstakeid = userStakeCounter[DEFAULT_POOL][_userAddress];
        // Fetch the stakeInfo which saved on stake id.
        StakeInfo storage staker = userStakeInfo[DEFAULT_POOL][_userAddress][
            userstakeid
        ];
        // Here sets the below values in the object.
        staker.amount = _amount;
        staker.timestamp = block.timestamp;
        staker.vault = _vault;
        staker.withdrawTime = 0;
        staker.tokenId = __tokenId;
        staker.isERC721 = _isERC721;
        userStakeCounter[DEFAULT_POOL][_userAddress] = userStakeCounter[DEFAULT_POOL][
            _userAddress
        ].add(1);
    }

    function transferNFTandGetAmount(uint256 _tokenId) internal returns(uint256){
        uint256 _amount;
        address _token0;
        address _token1;

        (, , _token0, _token1, , , , , , , , ) = erc721Token.positions(
            _tokenId
        );

        require(lpTokensStatus[_token0][_token1], "LP token not added");
        require(lpTokensStatus[_token1][_token0], "LP token not added");
        _amount = uniswapUtility.getAstraAmount(_tokenId);
        erc721Token.safeTransferFrom(
                address(msg.sender),
                address(this),
                _tokenId
        );

        return _amount;

    }

    function deposit(
        
        uint256 _amount,
        uint256 _vault,
        uint256 _tokenId,
        bool _isERC721
    ) external {
        if(_isERC721){
            _amount = transferNFTandGetAmount(_tokenId);
        }else{
            poolInfo[DEFAULT_POOL].lpToken.safeTransferFrom(
            address(msg.sender),
            address(this),
            _amount
            );
        }
        _deposit( _amount, _vault, msg.sender, _tokenId, _isERC721);
    }

    // This function will be used by other contracts to deposit on user's behalf.
    function depositFromOtherContract(
        
        uint256 _amount,
        uint256 _vault,
        address _userAddress
    ) external {
        require(isAllowedContract[msg.sender], "Invalid sender");
        poolInfo[DEFAULT_POOL].lpToken.safeTransferFrom(
            address(msg.sender),
            address(this),
            _amount
        );
        _deposit( _amount, _vault, _userAddress, 0, false);
    }

    // Deposit LP tokens to MasterChef for ASTRA allocation.
    function _deposit(
        
        uint256 _amount,
        uint256 _vault,
        address _userAddress,
        uint256 _tokenId,
        bool _isERC721
    ) internal {
        require(isValidVault[_vault], "Invalid vault");
        uint256 _stakingScore;
        uint256 _currentMultiplier;
        uint256 _maxMultiplier;

        PoolInfo storage pool = poolInfo[DEFAULT_POOL];
        UserInfo storage user = userInfo[DEFAULT_POOL][_userAddress];
        updatePool();

        if (user.amount > 0) {
            uint256 pending = user
                .amount
                .mul(pool.accAstraPerShare)
                .div(1e12)
                .sub(user.rewardDebt);
            unClaimedReward[_userAddress] = unClaimedReward[_userAddress].add(
                pending
            );
        }
        uint256 updateStakedAmount = user.amount.add(_amount);
        uint256 newPoolMaxMultiplier;
        updateUserDepositDetails( _userAddress, _amount, _vault, _tokenId, _isERC721);

        (
            _stakingScore,
            _currentMultiplier,
            _maxMultiplier
        ) = stakingScoreAndMultiplier( _userAddress, updateStakedAmount);
        newPoolMaxMultiplier = updateStakedAmount
            .mul(_maxMultiplier)
            .add(pool.totalStaked.mul(pool.maxMultiplier))
            .sub(user.amount.mul(user.maxMultiplier))
            .div(pool.totalStaked.add(_amount));
        updateUserAverageSlashingFees( _userAddress, user.amount, _amount, block.timestamp);
        user.amount = updateStakedAmount;
        pool.totalStaked = pool.totalStaked.add(_amount);
        if (user.maxMultiplier == 0) {
            user.maxMultiplier = MULTIPLIER_DECIMAL;
        }
        user.maxMultiplier = _maxMultiplier;
        user.rewardDebt = user.amount.mul(pool.accAstraPerShare).div(1e12);
        pool.maxMultiplier = newPoolMaxMultiplier;
        user.lastDeposit = block.timestamp;
        updateRewardRate(pool.lastRewardBlock, pool.maxMultiplier, 0);
        addHighestStakedUser( user.amount, _userAddress);
        emit Deposit(_userAddress, DEFAULT_POOL, _amount);
    }

    function withdraw( bool _withStake) external {
        UserInfo storage user = userInfo[DEFAULT_POOL][msg.sender];
        //Instead of transferring to a standard staking vault, Astra tokens can be locked (meaning that staker forfeits the right to unstake them for a fixed period of time). There are following lockups vaults: 6,9 and 12 months.
        if (user.cooldown == false) {
            user.cooldown = true;
            user.cooldowntimestamp = block.timestamp;
            return;
        } else {
            
                require(
                    block.timestamp >=
                        user.cooldowntimestamp.add(
                            SECONDS_IN_DAY.mul(coolDownPeriodTime)
                        ),
                    "withdraw: cooldown period"
                );
                user.cooldown = false;
                // Calling withdraw function after all the validation like cooldown period, eligible amount etc.
                _withdraw( _withStake);
        }
    }

    // Withdraw LP tokens from MasterChef.
    function _withdraw( bool _withStake) internal {
        PoolInfo storage pool = poolInfo[DEFAULT_POOL];
        UserInfo storage user = userInfo[DEFAULT_POOL][msg.sender];
        uint256 _amount;
        uint256 _erc721Amount;
        (_amount, _erc721Amount) = checkEligibleAmount( msg.sender);
        require(user.amount >= _amount, "withdraw: not good");
        if (_withStake) {
            restakeAstraReward();
        } else {
            claimAstra();
        }

        uint256 _stakingScore;
        uint256 _currentMultiplier;
        uint256 _maxMultiplier;
        uint256 updateStakedAmount = user.amount.sub(_amount);
        uint256 newPoolMaxMultiplier;
        if (pool.totalStaked.sub(_amount) > 0) {
            (
                _stakingScore,
                _currentMultiplier,
                _maxMultiplier
            ) = stakingScoreAndMultiplier( msg.sender, updateStakedAmount);
            newPoolMaxMultiplier = updateStakedAmount
                .mul(_maxMultiplier)
                .add(pool.totalStaked.mul(pool.maxMultiplier))
                .sub(user.amount.mul(user.maxMultiplier))
                .div(pool.totalStaked.sub(_amount));
        } else {
            newPoolMaxMultiplier = MULTIPLIER_DECIMAL;
        }

        user.amount = updateStakedAmount;
        pool.totalStaked = pool.totalStaked.sub(_amount);
        if (user.maxMultiplier == 0) {
            user.maxMultiplier = MULTIPLIER_DECIMAL;
        }
        user.maxMultiplier = _maxMultiplier;
        user.rewardDebt = user.amount.mul(pool.accAstraPerShare).div(1e12);
        pool.maxMultiplier = newPoolMaxMultiplier;
        user.lastDeposit = block.timestamp;
        updateRewardRate(pool.lastRewardBlock, pool.maxMultiplier, 0);
        safeAstraTransfer(msg.sender, _amount.sub(_erc721Amount));
        removeHighestStakedUser( user.amount, msg.sender);
        emit Withdraw(msg.sender, DEFAULT_POOL, _amount);
    }

    /**
    @notice View the eligible amount which is able to withdraw.
    @param _user : user address
    @dev Description :
    View the eligible amount which needs to be withdrawn if user deposits amount in multiple vaults. This function
    definition is marked "public" because this fuction is called from outside and inside the contract.
    */
    function viewEligibleAmount( address _user)
        external
        view
        returns (uint256)
    {
        uint256 eligibleAmount = 0;
        // Getting count of stake which is managed at the time of deposit
        uint256 countofstake = userStakeCounter[DEFAULT_POOL][_user];
        // This loop is applied for calculating the eligible withdrawn amount. This will fetch the user StakeInfo and calculate
        // the eligible amount which needs to be withdrawn
        for (uint256 i = 0; i <= countofstake; i++) {
            // Single stake info by stake id.
            StakeInfo storage stkInfo = userStakeInfo[DEFAULT_POOL][_user][i];
            // Checking the deposit variable is true
            if (
                stkInfo.withdrawTime == 0 ||
                stkInfo.withdrawTime == block.timestamp
            ) {
                uint256 vaultdays = stkInfo.vault.mul(60);
                uint256 timeaftervaultmonth = stkInfo.timestamp.add(
                    vaultdays.mul(60)
                );
                // Checking if the duration of vault month is passed.
                if (block.timestamp >= timeaftervaultmonth) {
                    eligibleAmount = eligibleAmount.add(stkInfo.amount);
                }
            }
        }
        return eligibleAmount;
    }

    /**
    @notice Check the eligible amount which is able to withdraw.
    @param _user : user address
    @dev Description :
    This function is like viewEligibleAmount just here we update the state of stakeInfo object. This function definition
    is marked "private" because this fuction is called only from inside the contract.
    */
    function checkEligibleAmount( address _user)
        private
        returns (uint256, uint256)
    {
        uint256 eligibleAmount = 0;
        uint256 _erc721Amount;
        uint256 totaldepositAmount;
        averageStakedTime[DEFAULT_POOL][_user] = 0;
        // Getting count of stake which is managed at the time of deposit
        uint256 countofstake = userStakeCounter[DEFAULT_POOL][_user];
        // This loop is applied for calculating the eligible withdrawn amount. This will fetch the user StakeInfo and
        // calculate the eligible amount which needs to be withdrawn and StakeInfo is getting updated in this function.
        // Means if amount is eligible then false value needs to be set in deposit varible.
        for (uint256 i = 0; i <= countofstake; i++) {
            // Single stake info by stake id.
            StakeInfo storage stkInfo = userStakeInfo[DEFAULT_POOL][_user][i];
            // Checking the deposit variable is true
            if (
                stkInfo.withdrawTime == 0 ||
                stkInfo.withdrawTime == block.timestamp
            ) {
                uint256 vaultdays = stkInfo.vault.mul(60);
                uint256 timeaftervaultmonth = stkInfo.timestamp.add(
                    vaultdays.mul(60)
                );
                // Checking if the duration of vault month is passed.
                if (block.timestamp >= timeaftervaultmonth) {
                    eligibleAmount = eligibleAmount.add(stkInfo.amount);
                    stkInfo.withdrawTime = block.timestamp;
                    if(stkInfo.isERC721){
                        _erc721Amount = _erc721Amount.add(stkInfo.amount);
                        erc721Token.safeTransferFrom(
                        address(this),
                        address(msg.sender),
                        stkInfo.tokenId
                    );
                    }
                } else {
                    updateUserAverageSlashingFees( _user, totaldepositAmount, stkInfo.amount, stkInfo.timestamp);
                    totaldepositAmount = totaldepositAmount.add(stkInfo.amount);
                }
            }
        }
        return (eligibleAmount,_erc721Amount);
    }

    /**
    @notice store Highest 100 staked users
    @param _amount : amount
    @dev Description :
    During the first 60 days after Astra network goes live date, DAO governance will be performed by the
    top 100 wallets with the highest amount of staked Astra tokens. After the first 90 days, DAO governors
    will be based on the staking score, without any limitations.
    */
    function addHighestStakedUser(
        
        uint256 _amount,
        address user
    ) private {
        uint256 i;
        // Getting the array of Highest staker as per pool id.
        HighestAstaStaker[] storage higheststaker = highestStakerInPool[DEFAULT_POOL];
        //for loop to check if the staking address exist in array
        for (i = 0; i < higheststaker.length; i++) {
            if (higheststaker[i].addr == user) {
                higheststaker[i].deposited = _amount;
                // Called the function for sorting the array in ascending order.
                quickSort( 0, higheststaker.length - 1);
                return;
            }
        }

        if (higheststaker.length < 100) {
            // Here if length of highest staker is less than 100 than we just push the object into array.
            higheststaker.push(HighestAstaStaker(_amount, user));
        } else {
            // Otherwise we check the last staker amount in the array with new one.
            if (higheststaker[0].deposited < _amount) {
                // If the last staker deposited amount is less than new then we put the greater one in the array.
                higheststaker[0].deposited = _amount;
                higheststaker[0].addr = user;
            }
        }
        // Called the function for sorting the array in ascending order.
        quickSort( 0, higheststaker.length - 1);
    }

    /**
    @notice Astra staking track the Highest 100 staked users
    @param user : user address
    @dev Description :
    During the first 60 days after Astra network goes live date, DAO governance will be performed by the
    top 100 wallets with the highest amount of staked Astra tokens. 
    */
    function checkHighestStaker( address user)
        external
        view
        returns (bool)
    {
        HighestAstaStaker[] storage higheststaker = highestStakerInPool[DEFAULT_POOL];
        uint256 i = 0;
        // Applied the loop to check the user in the highest staker list.
        for (i; i < higheststaker.length; i++) {
            if (higheststaker[i].addr == user) {
                // If user is exists in the list then we return true otherwise false.
                return true;
            }
        }
    }

    /**
    @notice Fetching the list of top astra stakers 
    @dev    this function definition is marked "external" because this fuction is called only from outside the contract.
    */
    function getStakerList()
        public
        view
        returns (HighestAstaStaker[] memory)
    {
        return highestStakerInPool[DEFAULT_POOL];
    }

    /**
    @notice Sorting the highes astra staker in pool
    @param left : left
    @param right : right
    @dev Description :
        It is used for sorting the highes astra staker in pool. This function definition is marked
        "internal" because this fuction is called only from inside the contract.
    */
    function quickSort(
        
        uint256 left,
        uint256 right
    ) internal {
        HighestAstaStaker[] storage arr = highestStakerInPool[DEFAULT_POOL];
        if (left >= right) return;
        uint256 divtwo = 2;
        uint256 p = arr[(left + right) / divtwo].deposited; // p = the pivot element
        uint256 i = left;
        uint256 j = right;
        while (i < j) {
            // HighestAstaStaker memory a;
            // HighestAstaStaker memory b;
            while (arr[i].deposited < p) ++i;
            while (arr[j].deposited > p) --j; // arr[j] > p means p still to the left, so j > 0
            if (arr[i].deposited > arr[j].deposited) {
                (arr[i].deposited, arr[j].deposited) = (
                    arr[j].deposited,
                    arr[i].deposited
                );
                (arr[i].addr, arr[j].addr) = (arr[j].addr, arr[i].addr);
            } else ++i;
        }
        // Note --j was only done when a[j] > p.  So we know: a[j] == p, a[<j] <= p, a[>j] > p
        if (j > left) quickSort( left, j - 1); // j > left, so j > 0
        quickSort( j + 1, right);
    }

    /**
    @notice Remove highest staker from the staker array
    @param user : user address
    @dev Description :
    This function is basically called from the withdraw function and update the highest staker list. It is used to remove
    highest staker from the staker array. This function definition is marked "private" because this fuction is called only
    from inside the contract.
    */
    function removeHighestStakedUser(
        
        uint256 _amount,
        address user
    ) private {
        // Getting Highest staker list as per the pool id
        HighestAstaStaker[] storage highestStaker = highestStakerInPool[DEFAULT_POOL];
        // Applied this loop is just to find the staker
        for (uint256 i = 0; i < highestStaker.length; i++) {
            if (highestStaker[i].addr == user) {
                // Deleting the staker from the array.
                delete highestStaker[i];
                if (_amount > 0) {
                    // If amount is greater than 0 than we need to add this again in the hisghest staker list.
                    addHighestStakedUser( _amount, user);
                }
                return;
            }
        }
        quickSort( 0, highestStaker.length - 1);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw( uint256 _amount) public onlyOwner {
        PoolInfo storage pool = poolInfo[DEFAULT_POOL];
        pool.lpToken.safeTransfer(address(msg.sender), _amount);
        emit EmergencyWithdraw(msg.sender, DEFAULT_POOL, _amount);
    }

    // Safe astra transfer function, just in case if rounding error causes pool to not have enough ASTRAs.
    function safeAstraTransfer(address _to, uint256 _amount) internal {
        uint256 astraBal = astra.balanceOf(address(this));
        if (_amount > astraBal) {
            astra.transfer(_to, astraBal);
        } else {
            astra.transfer(_to, _amount);
        }
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external override returns (bytes4) {
        return IERC721ReceiverUpgradeable.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 {
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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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

    function positions(uint256 tokenId)
        external
        view
        returns (
            uint96 nonce,
            address operator,
            address token0,
            address token1,
            uint24 fee,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );
    
    function factory()
        external
        view
        returns (
            address
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/// @title The interface for the Uniswap V3 Factory
/// @notice The Uniswap V3 Factory facilitates creation of Uniswap V3 pools and control over the protocol fees
interface IUniswapV3Factory {
    /// @notice Emitted when the owner of the factory is changed
    /// @param oldOwner The owner before the owner was changed
    /// @param newOwner The owner after the owner was changed
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);

    /// @notice Emitted when a pool is created
    /// @param token0 The first token of the pool by address sort order
    /// @param token1 The second token of the pool by address sort order
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks
    /// @param pool The address of the created pool
    event PoolCreated(
        address indexed token0,
        address indexed token1,
        uint24 indexed fee,
        int24 tickSpacing,
        address pool
    );

    /// @notice Emitted when a new fee amount is enabled for pool creation via the factory
    /// @param fee The enabled fee, denominated in hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks for pools created with the given fee
    event FeeAmountEnabled(uint24 indexed fee, int24 indexed tickSpacing);

    /// @notice Returns the current owner of the factory
    /// @dev Can be changed by the current owner via setOwner
    /// @return The address of the factory owner
    function owner() external view returns (address);

    /// @notice Returns the tick spacing for a given fee amount, if enabled, or 0 if not enabled
    /// @dev A fee amount can never be removed, so this value should be hard coded or cached in the calling context
    /// @param fee The enabled fee, denominated in hundredths of a bip. Returns 0 in case of unenabled fee
    /// @return The tick spacing
    function feeAmountTickSpacing(uint24 fee) external view returns (int24);

    /// @notice Returns the pool address for a given pair of tokens and a fee, or address 0 if it does not exist
    /// @dev tokenA and tokenB may be passed in either token0/token1 or token1/token0 order
    /// @param tokenA The contract address of either token0 or token1
    /// @param tokenB The contract address of the other token
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @return pool The pool address
    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view returns (address pool);

    /// @notice Creates a pool for the given two tokens and fee
    /// @param tokenA One of the two tokens in the desired pool
    /// @param tokenB The other of the two tokens in the desired pool
    /// @param fee The desired fee for the pool
    /// @dev tokenA and tokenB may be passed in either order: token0/token1 or token1/token0. tickSpacing is retrieved
    /// from the fee. The call will revert if the pool already exists, the fee is invalid, or the token arguments
    /// are invalid.
    /// @return pool The address of the newly created pool
    function createPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external returns (address pool);

    /// @notice Updates the owner of the factory
    /// @dev Must be called by the current owner
    /// @param _owner The new owner of the factory
    function setOwner(address _owner) external;

    /// @notice Enables a fee amount with the given tickSpacing
    /// @dev Fee amounts may never be removed once enabled
    /// @param fee The fee amount to enable, denominated in hundredths of a bip (i.e. 1e-6)
    /// @param tickSpacing The spacing between ticks to be enforced for all pools created with the given fee amount
    function enableFeeAmount(uint24 fee, int24 tickSpacing) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
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
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
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

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
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

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/draft-IERC20PermitUpgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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
        IERC20PermitUpgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
interface IERC20PermitUpgradeable {
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