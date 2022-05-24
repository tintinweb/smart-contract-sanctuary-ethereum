// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

import "ERC20.sol";
import "SafeERC20.sol";
import "IERC20.sol";
import "Ownable.sol";


/// @title Vinci Staking V1
/// @notice A smart contract to handle staking of Vinci ERC20 token across multiple artist pools. Picasso club tiers information also handled by this contract
/// @dev Jacobo Lansac
contract VinciStakingV1 is Ownable {
    using SafeERC20 for ERC20;

    ERC20 public vinciERC20;


    address[] stakeholders;
    mapping(address => uint) public activeStaking;
    mapping(address => uint) public scheduledUnstaking;
    mapping(address => uint) public claimable;
    mapping(address => uint) public unclaimable;
    mapping(address => uint) public lastBalancesUpdate;
    mapping(address => uint) public currentlyUnstaking;
    mapping(address => uint) public unlockTime; // Time from unstaking to claimable

    // The default (0) means that user has 100% (default pool)
    mapping(address => uint) public pledgeShare;  // percentage of the APR that the pool owner receives. Initialized as 0, all goes to the user
    mapping(address => uint) public tiers;
    mapping(address => uint) public checkpoint;
    mapping(address => bool) public superstaker;
    mapping(address => uint) public checkpointMultiplier;

    uint public baseAPR = 5.5 gwei;  // gwei is the number of decimals in the percentage
    uint public stakingRewardsFunds;
    //uint totalStaked; //TODO: Do we need it?  good question.. I guess it is convenient for offchain weights, but not really in the contract
    uint public penaltyPot;
    uint public ownersPot;
    uint constant maxCurrentlyUnstaking = 5; // For a given user, maximum number of currently unstaking instances.

    uint internal constant baseCheckpointMultiplier = 6;
    uint public checkpointBlockDuration;
    uint public epochDuration;
    uint public unstakingDuration;

    uint[] public tiersThresholdsInVinci;  // tiers need to be in contract for the relock function to work

    // Events
    event Staked(address indexed user, uint256 amount, uint poolid);
    event Unstaked(address indexed user, uint256 amount, uint poolid);
    event CanceledUnstaking(address indexed user);
    event ScheduledUnstake(address indexed user, uint256 amount, uint poolid, uint currentNextCheckpoint);
    event CancelScheduledUnstake(address indexed user, uint poolid);
    event Claimed(address indexed user, uint256 amount);
    event Reallocated(address indexed user, uint256 amount, uint fromPoolId, uint toPoolId);
    event VinciTransferredToContract(address from, uint amount);
    event FundedStakingRewardsFund(uint _amount);
    event AirdroppedFromPenaltypot(address indexed user, uint amount);
    event AirdroppedFromRewardsFund(address indexed user, uint amount);
    event AirdroppedFromWallet(address indexed user, uint amount);
    event TiersThresholdsUpdated(uint[] _vinciThresholds);
    event TierSet(address indexed _user, uint newTier);
    event CheckpointSet(address indexed _user, uint newCheckpoint);
    event NotEnoughFundsToGiveRewards(uint rewards, uint stakingRewardsFund);
    event CollectedFeesWithdrawn(address _to, uint amount);

    constructor(
        ERC20 _vinciTokenAddress,
        uint[] memory _tiersThresholdsInVinci,
        uint _epochDuration,
        uint _checkpointBlockDuration
    ) {
        vinciERC20 = _vinciTokenAddress;
        tiersThresholdsInVinci = _tiersThresholdsInVinci;
        epochDuration = _epochDuration;
        checkpointBlockDuration = _checkpointBlockDuration;
        unstakingDuration = 2 * epochDuration;
    }

    // reentrancy lock
    uint private locked = 0;
    modifier lock() {
        require(locked == 0, 'reentrancy guard locked');
        locked = 1;
        _;
        locked = 0;
    }

    /// ================ Modifiers ================
    modifier updateBalances(address sender) {
        //Also as function so as to be called externally
        updateUserBalances(sender);
        _;
    }

    /// ensures that a user checkpoint is always updated before executing other sensible functions
    modifier checkpointUpdated(address sender) {
        if (checkpoint[sender] != 0 && block.timestamp > checkpoint[sender]) {
            _crossCheckpoint(sender);
        }
        _;
    }

    /// ================== User functions =============================
    /**
    @dev Emits a {Staked} event.

    Requirements: see _stake() requirements
    @notice stake vinci tokens into a specific pool into the msgSender staking balance.
    */
    function stake(
        uint _amount,
        uint _poolId
    ) external checkpointUpdated(msg.sender) {
        _stake(_msgSender(), _amount, _poolId);
    }

    /// this function does not need the checkpointUpdated modifier, because this will only be used at the beginning of the contract
    function stakeTo(
        uint _amount,
        uint _poolId,
        address _to
    ) external onlyOwner {
        // cannot use checkpointUpdated modifier here, because it is not msg.sender we want to update
        if (block.timestamp > checkpoint[_to]) {_crossCheckpoint(_to);}
        _stake(_to, _amount, _poolId);
    }

    function unstake(
        uint _amount,
        uint _poolId
    ) external updateBalances(msg.sender) checkpointUpdated(msg.sender) {
        _unstake(_msgSender(), _amount, _poolId);
    }

    function cancelUnstake() external updateBalances(msg.sender) checkpointUpdated(msg.sender) {
        address sender = _msgSender();

        uint unstaking = currentlyUnstaking[sender];
        require(unstaking > 0, 'Nothing is currently unstaking');

        uint amount = unstaking;
        delete currentlyUnstaking[sender];
        activeStaking[sender] += amount;

        // todo if they lost superstaker status or tiers, should we give them back?

        emit CanceledUnstaking(sender);
    }

    function scheduleUnstake(
        uint _amount,
        uint _poolId
    ) external updateBalances(msg.sender) checkpointUpdated(msg.sender) {
        address sender = _msgSender();
        require(_amount <= activeStaking[sender], 'Not enough active staking to schedule to unstake');

        scheduledUnstaking[sender] += _amount;
        activeStaking[sender] -= _amount;

        emit ScheduledUnstake(sender, _amount, _poolId, checkpoint[sender]);
    }

    function cancelScheduledUnstake(uint _poolId) external updateBalances(msg.sender) checkpointUpdated(msg.sender) {
        address sender = _msgSender();
        require(scheduledUnstaking[sender] > 0);
        activeStaking[sender] += scheduledUnstaking[sender];
        delete scheduledUnstaking[sender];

        emit CancelScheduledUnstake(sender, _poolId);
    }

    function claim() external lock updateBalances(msg.sender) checkpointUpdated(msg.sender) {
        address sender = _msgSender();
        uint amount = claimable[sender];
        if (amount > 0) {
            vinciERC20.safeTransfer(sender, amount);
            delete claimable[sender];
        }
        // Emit event even if amount = 0.
        emit Claimed(sender, amount);
    }

    function claimAndStake(uint _poolId) external updateBalances(msg.sender) checkpointUpdated(msg.sender) {
        address sender = _msgSender();
        uint amount = claimable[sender];
        require(amount > 0, 'Not enough claimable funds');
        delete claimable[sender];
        _stake(sender, amount, _poolId);
        emit Claimed(sender, amount);
    }

    function relock() external updateBalances(msg.sender) checkpointUpdated(msg.sender) {
        address sender = _msgSender();
        _evaluateTier(sender);
        _postponeCheckpoint(sender, false);
        _evaluateIfKeepsSuperstaker(sender);
    }

    function moveFunds(uint _originPool, uint _destinationPool, uint _amount) external {
        // this function is intended to only emit an event
        // todo discuss with luuk if this function is even necessary
        // we cannot check the actual balance in the pool
        require(_amount > stakingBalance(_msgSender()));
        emit Reallocated(_msgSender(), _amount, _originPool, _destinationPool);
    }

    /// we dont evaluate user checkpoint in this function. The user has to actively execute crossCheckpoint()
    function updateUserBalances(address _user) public {
        if (block.timestamp - lastBalancesUpdate[_user] > 1 hours) {

            uint baseRewards = _calculateBaseStakingRewards(_user);

            if (baseRewards > 0) {// avoid update state variables if there is no rewards
                // staking rewards come out of the stakingRewardsFund!
                if (baseRewards > stakingRewardsFunds) emit NotEnoughFundsToGiveRewards(baseRewards, stakingRewardsFunds);
                require(stakingRewardsFunds >= baseRewards, 'not enough vinci funds in contract to update rewards');

                stakingRewardsFunds -= baseRewards;
                uint poolFeeTaken = (baseRewards * pledgeShare[_user]) / (100 gwei);
                uint userRewards = baseRewards - poolFeeTaken;

                if (poolFeeTaken > 0) {
                    ownersPot += poolFeeTaken;
                }
                if (userRewards > 0) {
                    unclaimable[_user] += userRewards;
                }
            }

            // Unstaking -> claimable if lock has passed
            _currentlyUnstakingToClaimable(_user);

            // update this update tracker for next times
            lastBalancesUpdate[_user] = block.timestamp;
        }
    }

    /// ==================== View functions should expose the potential realizations =================

    function stakingBalance(address _user) public view returns (uint) {
        return activeStaking[_user] + scheduledUnstaking[_user];
    }

    function unclaimableBalance(address _user) public view returns (uint) {
        uint baseRewards = _calculateBaseStakingRewards(_user);
        uint userShare = (100 gwei - pledgeShare[_user]);
        uint userRewards = (baseRewards * userShare) / (100 gwei);
        return unclaimable[_user] + userRewards;
    }

    function claimableBalance(address _user) public view returns (uint) {
        uint _claimable = claimable[_user];

        // Unstaking that is potentially unlocked should show here, as it will be updated in updateBalances()
        if (unlockTime[_user] > block.timestamp && currentlyUnstaking[_user] > 0) {
            _claimable += currentlyUnstaking[_user];
        }

        return _claimable;
    }

    function currentlyUnstakingBalance(address _user) public view returns (uint) {
        // This means that unstaking is claimable in reality
        if (unlockTime[_user] > block.timestamp) return 0;
        return currentlyUnstaking[_user];

    }

    function scheduledUnstakingBalance(address _user) public view returns (uint) {
        return scheduledUnstaking[_user];
    }

    function readLastBalancesUpdate(address _user) public view returns (uint) {
        return lastBalancesUpdate[_user];
    }

    function readUserTier(address _user) public view returns (uint) {
        return tiers[_user];
    }

    /// Checkpoint info updated means that the checkpoint is in the future and it is not possible to cross it
    function isUserCheckpointUpdated(address _user) public view returns (bool) {
        return checkpoint[_user] > block.timestamp;
    }

    function isSuperstaker(address _user) public view returns (bool) {
        return superstaker[_user];
    }

    function readTierThresholdsInVinci() external view returns (uint[] memory) {
        return tiersThresholdsInVinci;
    }

    function readTierThresholdInVinci(uint _tier) external view returns (uint) {
        require(_tier <= tiersThresholdsInVinci.length, 'Non existing tier');
        return (_tier > 0) ? tiersThresholdsInVinci[_tier - 1] : 0;
    }

    function readTotalStaked() public view returns (uint){
        uint totalStaked = 0;
        for (uint i = 0; i < stakeholders.length; i++) {
            totalStaked += activeStaking[stakeholders[i]] + scheduledUnstaking[stakeholders[i]];
        }
        return totalStaked;
    }

    function readTotalActiveStaking() public view returns (uint){
        uint totalStaked = 0;
        for (uint i = 0; i < stakeholders.length; i++) {
            totalStaked += activeStaking[stakeholders[i]];
        }
        return totalStaked;
    }

    function readTotalScheduledUnstaking() public view returns (uint){
        uint totalStaked = 0;
        for (uint i = 0; i < stakeholders.length; i++) {
            totalStaked += scheduledUnstaking[stakeholders[i]];
        }
        return totalStaked;
    }

    /**
    @notice Returns the tier associated to the given amount
    */
    function calculateTier(uint _amount) public view returns (uint) {
        uint newTier;
        if (_amount < tiersThresholdsInVinci[0]) {
            return 0;
        } else {
            for (uint tier = 1; tier <= tiersThresholdsInVinci.length; tier++) {
                if (_amount >= tiersThresholdsInVinci[tier - 1]) {
                    newTier = tier;
                }
            }
            return newTier;
        }
    }

    /// ================ Contact management =============
    /**
    @dev reentrancy lock is used as calls an external contract (ERC20).
    onlyOwner is not used here to allow any wallet funding the contract

    Requires ERC20 token approvals

    @notice Fund the staking contract with Vinci tokens for staking rewards. Funds cannot be ever retrieved
    */
    function fundContractWithVinci(uint _amount) external lock {
        _transferVinciToContract(_amount);
        stakingRewardsFunds += _amount;
        emit FundedStakingRewardsFund(_amount);
    }
    /// checkpointUpdated() modifier not used to save gas in pool airdrops
    function airdropFromWallet(uint _amount, address _to) external lock {
        _transferVinciToContract(_amount);
        unclaimable[_to] += _amount;
        emit AirdroppedFromWallet(_to, _amount);
    }

    /// checkpointUpdated() modifier not used to save gas in pool airdrops
    function airdropFromRewardsFund(uint _amount, address _to) external onlyOwner {
        require(stakingRewardsFunds >= _amount, 'Not enough StakingRewardsFunds in contract');
        stakingRewardsFunds -= _amount;
        unclaimable[_to] += _amount;
        emit AirdroppedFromRewardsFund(_to, _amount);
    }

    /// checkpointUpdated() modifier not used to save gas when doing the distribution
    function airdropFromPenaltyPot(uint _amount, address _to) external onlyOwner {
        require(penaltyPot >= _amount, 'Not enough funds in penaltyPot');
        require(superstaker[_to], 'address is not superstaker');
        penaltyPot -= _amount;
        unclaimable[_to] += _amount;
        emit AirdroppedFromPenaltypot(_to, _amount);
    }

    function crossCheckpoint(address _user) external {
        require(block.timestamp > checkpoint[_user], 'user cannot cross checkpoint yet');
        updateUserBalances(_user);
        _crossCheckpoint(_user);
    }

    function updateTierThresholds(uint[] memory thresholds) external onlyOwner {
        require(thresholds.length > 0, 'input at least one threshold');
        delete tiersThresholdsInVinci;
        for (uint t = 1; t < thresholds.length; t++) {
            require(thresholds[t] > thresholds[t - 1], 'thresholds should be sorted ascending');
        }
        tiersThresholdsInVinci = thresholds;
        emit TiersThresholdsUpdated(thresholds);
    }

    function sendToPoolOwner(uint _amount, address _to) external onlyOwner {
        // Very careful. As it is now, it can drain all owners funds for only one owner.ownersPot
        require(_amount <= ownersPot, 'amount must be lower than owners pot');
        vinciERC20.transferFrom(_msgSender(), _to, _amount);
        emit CollectedFeesWithdrawn(_to, _amount);
    }

    /**
    @notice
    _percentage is a uint, that should represent a number between 0 and 100 but have 9 extra digits for decimals.
    Example _percentage = 80000000000 == 80% going for the pool owner and 20% ofr the user
    @dev
    this function is only owner, because the pledge handling is partly centralized. contract owner sets the user pledge
    share based on how much he/she pledges into different artists pools, which they choose form the platform UI.
    Although the pledges logic is centralized, the staking functions emit events in the transactions signed by the users
    to mimic a recept of the user's intentions.
    This brings the problem of failed transactions: if a user has not enough amount in a pool, and tries to unstake from
    the pool, we have no way to require that onchain, so the event will be emmited anyway.
    // todo should we keep events or not. Talk with luuk
    */
    function setUserPledgeShare(uint _percentage) external onlyOwner {
        require(((_percentage >= 0) && (_percentage < 100 gwei)), 'percentage should have 9 digits for decimals');
        pledgeShare[_msgSender()] = _percentage;
    }

    /// This is only an emergency function in case somebody sends by accident other ERC20 tokens to the contract
    function returnLostFunds(ERC20 _tokenAddress, uint _amount, address _to) external onlyOwner {
        require(_tokenAddress != vinciERC20, 'only non-vinci ERC20 tokens can be removed with this method');
        _tokenAddress.safeTransfer(_to, _amount);
    }

    /// ================= Internal ====================

    function _currentlyUnstakingToClaimable(address _user) internal {
        if (block.timestamp > unlockTime[_user]) {
            claimable[_user] += currentlyUnstaking[_user];
            delete currentlyUnstaking[_user];
        }

    }

    function _stake(
        address _user,
        uint _amount,
        uint _poolId
    ) internal lock updateBalances(_user) checkpointUpdated(_user) {
        require(_amount > 0, 'stake amount cannot be 0');

        _transferVinciToContract(_amount);
        activeStaking[_user] += _amount;

        // set tier info for fist time stakers
        if (checkpoint[_user] == 0) {
            _initializeStakeholder(_user);
        }

        emit Staked(_user, _amount, _poolId);
    }

    function _unstake(
        address _user,
        uint _amount,
        uint _poolId
    ) internal updateBalances(_user) checkpointUpdated(_user) {
        require(_amount > 0, 'amount must be positive');
        require(_amount <= activeStaking[_user], 'Not enough active staking to unstake');

        uint totalStaked = activeStaking[_user] + scheduledUnstaking[_user];
        activeStaking[_user] -= _amount;
        currentlyUnstaking[_user] += _amount;
        unlockTime[_user] = block.timestamp + unstakingDuration;

        uint penalization = unclaimable[_user] * _amount / totalStaked;
        penaltyPot += penalization;
        unclaimable[_user] -= penalization;

        _evaluateIfKeepsSuperstaker(_user);

        // if they unstake, the tier is reevaluated only if new tier would be lower, but checkpoint is not postponed
        uint _potentialTier = calculateTier(stakingBalance(_user));
        if (_potentialTier < tiers[_user]) {
            _setTier(_user, _potentialTier);
        }

        emit Unstaked(_user, _amount, _poolId);
    }

    /**
    @dev This handles an ERC20 transfer of vinci from msgSender's wallet to the contract
    WARNING: this function receives the vinci tokens, but they are NOT accounted in any balance. It is responsibility of the function invoking this method to update the necessary balances

    Requires vinci ERC20 approvals

    Requires non zero balance of vinci in the msg.sender wallet
    */
    function _transferVinciToContract(uint _amount) internal {
        address sender = _msgSender();
        // transferFrom already checks that _amount is non zero and that there is enough balance
        // we dont need SafeTransfer here because we know the receiver is a smart contract (this)
        vinciERC20.transferFrom(sender, address(this), _amount);
        emit VinciTransferredToContract(sender, _amount);
    }

    // Calculates the base APR rewards for a user at a given time, WITHOUT discounting the pool fees
    function _calculateBaseStakingRewards(address _user) internal view returns (uint) {
        uint timeSinceLastReward = block.timestamp - lastBalancesUpdate[_user];
        uint staking = activeStaking[_user] + scheduledUnstaking[_user];
        uint baseRewards = (staking * baseAPR * timeSinceLastReward) / (365 days * 100 gwei);
        return baseRewards;
    }

    function _evaluateIfKeepsSuperstaker(address _user) internal {
        if (superstaker[_user] && (stakingBalance(_user) == 0)) {
            // remove superstaker and also set multiplier back to base value
            superstaker[_user] = false;
            checkpointMultiplier[_user] = baseCheckpointMultiplier;
        }
    }

    function _postponeCheckpoint(address _user, bool _decreaseMultiplier) internal {
        uint _prevCheckpoint = checkpoint[_user];
        checkpoint[_user] = _prevCheckpoint + checkpointMultiplier[_user] * checkpointBlockDuration;
        if (_decreaseMultiplier && (checkpointMultiplier[_user] > 1)) {
            checkpointMultiplier[_user] -= 1;
        }
        emit CheckpointSet(_user, checkpoint[_user]);
    }

    function _initCheckpoint(address _user) internal {
        checkpointMultiplier[_user] = baseCheckpointMultiplier;
        uint userCheckpoint = block.timestamp + baseCheckpointMultiplier * checkpointBlockDuration;
        checkpoint[_user] = userCheckpoint;
        emit CheckpointSet(_user, userCheckpoint);
    }

    function _initializeStakeholder(address _user) internal {
        stakeholders.push(_user);
        _initCheckpoint(_user);
        _evaluateTier(_user);
    }

    function _finishStakeholder(address _user) internal {
        // todo remove user from stakeholders
        // todo reset checkpoint to 0
        // todo reset tier to 0
    }

    function _evaluateTier(address _user) internal {
        uint oldTier = tiers[_user];
        uint newTier = calculateTier(stakingBalance(_user));
        if (newTier != oldTier) {
            _setTier(_user, newTier);
        }
    }

    function _setTier(address _user, uint _newTier) internal {
        tiers[_user] = _newTier;
        emit TierSet(_user, _newTier);
    }

    function _crossCheckpoint(address _user) internal {

        uint _newClaimable;

        if (unclaimable[_user] > 0) {
            _newClaimable += unclaimable[_user];
            delete unclaimable[_user];
        }

        if (scheduledUnstaking[_user] > 0) {
            uint scheduled = scheduledUnstaking[_user];
            _newClaimable += scheduled;
            delete scheduledUnstaking[_user];
            // unfortunately at this point we dont know the poolId, so we put 0.
            // This info could be extracted from a previously emited ScheduledUnstake event
            emit Unstaked(_user, scheduled, 0);
        }

        if (_newClaimable > 0) {
            claimable[_user] = _newClaimable;
        }

        // no need to update currentlyUnstaking as it is taken care of in the updateBalances() modifier
        _postponeCheckpoint(_user, true);
        _evaluateTier(_user);

        // this function is the only one to grant and remove superstaker. Other functions can only remove it
        uint userStaking = stakingBalance(_user);
        if (!superstaker[_user] && (userStaking > 0)) {
            superstaker[_user] = true;
        } else if (superstaker[_user] && (userStaking == 0)) {
            superstaker[_user] = false;
            checkpointMultiplier[_user] = baseCheckpointMultiplier;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "IERC20.sol";
import "IERC20Metadata.sol";
import "Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "IERC20.sol";
import "Address.sol";

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
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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