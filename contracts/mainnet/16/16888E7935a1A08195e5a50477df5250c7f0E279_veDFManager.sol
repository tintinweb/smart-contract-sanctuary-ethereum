//SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
import "./veDFCore.sol";

contract veDFManager is veDFCore {
    IERC20Upgradeable public DF;

    event SupplySDF(uint256 amount);

    constructor(
        IveDF _veDF,
        IStakedDF _sDF,
        IERC20Upgradeable _rewardToken,
        uint256 _startTime,
        address _rewardDistributor
    ) public {
        initialize(_veDF, _sDF, _rewardToken, _startTime, _rewardDistributor);
    }

    function initialize(
        IveDF _veDF,
        IStakedDF _sDF,
        IERC20Upgradeable _rewardToken,
        uint256 _startTime,
        address _rewardDistributor
    ) public override {
        require(
            _sDF.DF() == IRewardDistributor(_rewardDistributor).rewardToken(),
            "veDFManager: vault distribution token error"
        );

        require(
            address(_sDF) == address(_rewardToken),
            "veDFManager: Distributed as SDF"
        );

        super.initialize(_veDF, _sDF, _rewardToken, _startTime, _rewardDistributor);
        DF = IERC20Upgradeable(_sDF.DF());
        DF.safeApprove(address(sDF), uint256(-1));
    }

    ///@notice Supply SDF to be distributed
    ///@param _amount DF amount
    function supplySDFUnderlying(uint256 _amount) public onlyOwner {
        require(
            _amount > 0,
            "veDFManager: supply SDF Underlying amount must greater than 0"
        );
        DF.safeTransferFrom(rewardDistributor, address(this), _amount);
        sDF.stake(address(this), _amount);
        emit SupplySDF(_amount);
    }

    ///@notice Supply SDF to be distributed
    ///@param _amount sDF amount
    function supplySDF(uint256 _amount) external onlyOwner {
        require(_amount > 0, "veDFManager: supply SDF amount must greater than 0");

        //Calculate the number of needed DF based on _exchangeRate
        uint256 _exchangeRate = sDF.getCurrentExchangeRate();
        uint256 _underlyingAmount = _amount.rmul(_exchangeRate);
        supplySDFUnderlying(_underlyingAmount);
    }

    /**
     * @notice Lock DF and harvest veDF, One operation will DF lock
     * @dev Create lock-up information and mint veDF on lock-up amount and duration.
     * @param _amount DF token amount.
     * @param _dueTime Due time timestamp, in seconds.
     */
    function createInOne(uint256 _amount, uint256 _dueTime)
        external
        sanityCheck(_amount)
        isDueTimeValid(_dueTime)
        updateReward(msg.sender)
    {
        DF.safeTransferFrom(msg.sender, address(this), _amount);

        uint256 _sDFAmount = sDF.stake(address(this), _amount);

        uint256 _duration = _dueTime.sub(block.timestamp);
        uint256 _veDFAmount = veDF.create(msg.sender, _sDFAmount, _duration);

        totalSupply = totalSupply.add(_veDFAmount);
        balances[msg.sender] = balances[msg.sender].add(_veDFAmount);
        nodes[_dueTime].balance = nodes[_dueTime].balance.add(_veDFAmount);

        emit Create(msg.sender, _sDFAmount, _duration, _veDFAmount);
    }

    function refillInOne(uint256 _amount)
        external
        sanityCheck(_amount)
        updateReward(msg.sender)
    {
        DF.safeTransferFrom(msg.sender, address(this), _amount);
        uint256 _sDFAmount = sDF.stake(address(this), _amount);

        uint256 _veDFAmount = veDF.refill(msg.sender, _sDFAmount);

        (uint32 _dueTime, , ) = veDF.getLocker(msg.sender);

        totalSupply = totalSupply.add(_veDFAmount);
        balances[msg.sender] = balances[msg.sender].add(_veDFAmount);
        nodes[_dueTime].balance = nodes[_dueTime].balance.add(_veDFAmount);

        emit Refill(msg.sender, _sDFAmount, _veDFAmount);
    }

    ///@param _increment The number of DF added to the original number of locked warehouses
    function refreshInOne(uint256 _increment, uint256 _dueTime)
        external
        isDueTimeValid(_dueTime)
        nonReentrant
        updateReward(msg.sender)
    {
        (, , uint256 _lockedSDF) = veDF.getLocker(msg.sender);
        uint256 _newSDF = _lockedSDF;

        if (_increment > 0) {
            DF.safeTransferFrom(msg.sender, address(this), _increment);
            uint256 _incrementSDF = sDF.stake(address(this), _increment);
            _newSDF = _newSDF.add(_incrementSDF);
        }

        uint256 _duration = _dueTime.sub(block.timestamp);
        uint256 _oldVEDFAmount = balances[msg.sender];
        (uint256 _newVEDFAmount, ) = veDF.refresh(msg.sender, _newSDF, _duration);

        balances[msg.sender] = _newVEDFAmount;
        userRewardPerTokenPaid[msg.sender] = rewardPerTokenStored;

        totalSupply = totalSupply.add(_newVEDFAmount).sub(_oldVEDFAmount);
        nodes[_dueTime].balance = nodes[_dueTime].balance.add(_newVEDFAmount);
        accSettledBalance = accSettledBalance.sub(_oldVEDFAmount);

        emit Refresh(
            msg.sender,
            _lockedSDF,
            _newSDF,
            _duration,
            _oldVEDFAmount,
            _newVEDFAmount
        );
    }

    function _withdraw() internal {
        (, , uint96 _lockedSDF) = veDF.getLocker(msg.sender);
        uint256 _burnVEDF = veDF.withdraw(msg.sender);
        uint256 _oldBalance = balances[msg.sender];

        totalSupply = totalSupply.sub(_oldBalance);
        balances[msg.sender] = balances[msg.sender].sub(_oldBalance);

        //Since totalsupply is reduced and the operation must be performed after the lock expires,
        //accsettledbalance should be reduced at the same time
        accSettledBalance = accSettledBalance.sub(_oldBalance);

        uint256 _DFAmount = sDF.unstake(address(this), _lockedSDF);
        DF.safeTransfer(msg.sender, _DFAmount);

        emit Withdraw(msg.sender, _burnVEDF, _oldBalance);
    }

    function getReward() public override updateReward(msg.sender) {
        uint256 _reward = rewards[msg.sender];
        if (_reward > 0) {
            rewards[msg.sender] = 0;
            rewardToken.safeTransfer(msg.sender, _reward);
            emit RewardPaid(msg.sender, _reward);
        }
    }

    function getRewardInOne() public updateReward(msg.sender) {
        uint256 _reward = rewards[msg.sender];
        if (_reward > 0) {
            rewards[msg.sender] = 0;
            uint256 _DFAmount = sDF.unstake(address(this), _reward);
            DF.safeTransfer(msg.sender, _DFAmount);
            emit RewardPaid(msg.sender, _reward);
        }
    }

    function exit2() external {
        getReward();
        _withdraw();
    }

    function exitInOne() external {
        getRewardInOne();
        _withdraw();
    }

    function earnedInOne(address _account)
        public
        updateReward(_account)
        returns (uint256 _reward)
    {
        _reward = rewards[_account];
        if (_reward > 0) {
            uint256 _exchangeRate = sDF.getCurrentExchangeRate();
            _reward = _reward.rmul(_exchangeRate);
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./LPTokenWrapper.sol";
import "../interface/IStakedDF.sol";
import "../interface/IRewardDistributor.sol";
import "../library/SafeRatioMath.sol";
import "../library/Ownable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/MathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

/**
 * @notice Minter of veDF
 * @dev The contract does not store parameters such as the number of SDFs
 */
contract veDFCore is
    Ownable,
    Initializable,
    ReentrancyGuardUpgradeable,
    LPTokenWrapper
{
    using SafeRatioMath for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeERC20Upgradeable for IStakedDF;

    ///@dev Min lock step (seconds of a week).
    uint256 internal constant MIN_STEP = 1 weeks;

    ///@dev Token of reward
    IERC20Upgradeable public rewardToken;
    IStakedDF public sDF;
    address public rewardDistributor;

    uint256 public rewardRate = 0;

    ///@dev The timestamp that started to distribute token reward.
    uint256 public startTime;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;

    uint256 public lastRateUpdateTime;
    uint256 public rewardDistributedStored;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    ///@dev Due time of settlement to node
    uint256 public lastSettledTime;
    ///@dev Total overdue balance settled
    uint256 public accSettledBalance;

    struct SettleLocalVars {
        uint256 lastUpdateTime;
        uint256 lastSettledTime;
        uint256 accSettledBalance;
        uint256 rewardPerToken;
        uint256 rewardRate;
        uint256 totalSupply;
    }

    struct Node {
        uint256 rewardPerTokenSettled;
        uint256 balance;
    }

    ///@dev due time timestamp => data
    mapping(uint256 => Node) internal nodes;

    event RewardRateUpdated(uint256 oldRewardRate, uint256 newRewardRate);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);

    ///@dev Emitted when `create` is called.
    ///@param recipient Address of receiving veDF
    ///@param sDFLocked Number of locked sDF
    ///@param duration Lock duration
    ///@param veDFReceived Number of veDF received
    event Create(
        address recipient,
        uint256 sDFLocked,
        uint256 duration,
        uint256 veDFReceived
    );

    ///@dev Emitted when `refill` is called.
    ///@param recipient Address of receiving veDF
    ///@param sDFRefilled Increased number of sDF
    ///@param veDFReceived Number of veDF received
    event Refill(address recipient, uint256 sDFRefilled, uint256 veDFReceived);

    ///@dev Emitted when `extend` is called.
    ///@param recipient Address of receiving veDF
    ///@param preDueTime Old expiration time
    ///@param newDueTime New expiration time
    ///@param duration Lock duration
    ///@param veDFReceived Number of veDF received
    event Extend(
        address recipient,
        uint256 preDueTime,
        uint256 newDueTime,
        uint256 duration,
        uint256 veDFReceived
    );

    ///@dev Emitted when `refresh` is called.
    ///@param recipient Address of receiving veDF
    ///@param presDFLocked Old number of locked sDF
    ///@param newsDFLocked New number of locked sDF
    ///@param duration Lock duration
    ///@param preveDFBalance Original veDF balance
    ///@param newveDFBalance New of veDF balance
    event Refresh(
        address recipient,
        uint256 presDFLocked,
        uint256 newsDFLocked,
        uint256 duration,
        uint256 preveDFBalance,
        uint256 newveDFBalance
    );

    ///@dev Emitted when `withdraw` is called.
    ///@param recipient Address of receiving veDF
    ///@param veDFBurned Amount of veDF burned
    ///@param sDFRefunded Number of sDF returned
    event Withdraw(address recipient, uint256 veDFBurned, uint256 sDFRefunded);

    function initialize(
        IveDF _veDF,
        IStakedDF _sDF,
        IERC20Upgradeable _rewardToken,
        uint256 _startTime,
        address _rewardDistributor
    ) public virtual initializer {
        require(
            _startTime > block.timestamp,
            "veDFManager: Start time must be greater than the block timestamp"
        );

        __Ownable_init();
        __ReentrancyGuard_init();

        veDF = _veDF;
        sDF = _sDF;
        rewardToken = _rewardToken;
        startTime = _startTime;
        lastSettledTime = _startTime;
        lastUpdateTime = _startTime;
        rewardDistributor = _rewardDistributor;

        sDF.safeApprove(address(veDF), uint256(-1));
    }

    ///@notice Update distribution of historical nodes and users
    ///@dev Basically all operations will be called
    modifier updateReward(address _account) {
        if (startTime <= block.timestamp) {
            _settleNode(block.timestamp);
            if (_account != address(0)) {
                _updateUserReward(_account);
            }
        }
        _;
    }

    modifier updateRewardDistributed() {
        rewardDistributedStored = rewardDistributed();
        lastRateUpdateTime = block.timestamp;
        _;
    }

    modifier sanityCheck(uint256 _amount) {
        require(_amount != 0, "veDFManager: Stake amount can not be zero!");
        _;
    }

    ///@dev Check duetime rules
    modifier isDueTimeValid(uint256 _dueTime) {
        require(
            _dueTime > block.timestamp,
            "veDFManager: Due time must be greater than the current time"
        );
        require(
            _dueTime.sub(startTime).mod(MIN_STEP) == 0,
            "veDFManager: The minimum step size must be `MIN_STEP`"
        );
        _;
    }

    modifier onlyRewardDistributor() {
        require(
            rewardDistributor == msg.sender,
            "veDFManager: caller is not the rewardDistributor"
        );
        _;
    }

    /*********************************/
    /******** Owner functions ********/
    /*********************************/

    ///@notice Set a new reward rate
    function setRewardRate(uint256 _rewardRate)
        external
        onlyRewardDistributor
        updateRewardDistributed
        updateReward(address(0))
    {
        uint256 _oldRewardRate = rewardRate;
        rewardRate = _rewardRate;

        emit RewardRateUpdated(_oldRewardRate, _rewardRate);
    }

    // This function allows governance to take unsupported tokens out of the
    // contract, since this one exists longer than the other pools.
    // This is in an effort to make someone whole, should they seriously
    // mess up. There is no guarantee governance will vote to return these.
    // It also allows for removal of airdropped tokens.
    function rescueTokens(
        IERC20Upgradeable _token,
        uint256 _amount,
        address _to
    ) external onlyRewardDistributor {
        _token.safeTransfer(_to, _amount);
    }

    /*********************************/
    /****** Internal functions *******/
    /*********************************/

    ///@dev Update the expired lock of the history node and calculate the `rewardPerToken` at that time
    function _settleNode(uint256 _now) private {
        //Using local variables to save gas
        SettleLocalVars memory _var;
        _var.lastUpdateTime = lastUpdateTime;
        _var.lastSettledTime = lastSettledTime;
        _var.accSettledBalance = accSettledBalance;
        _var.rewardPerToken = rewardPerTokenStored;
        _var.rewardRate = rewardRate;
        _var.totalSupply = totalSupply;

        //Cycle through each node in the history
        while (_var.lastSettledTime < _now) {
            Node storage _node = nodes[_var.lastSettledTime];
            if (_node.balance > 0) {
                _var.rewardPerToken = _var.rewardPerToken.add(
                    _var
                        .lastSettledTime
                        .sub(_var.lastUpdateTime)
                        .mul(_var.rewardRate)
                        .rdiv(_var.totalSupply.sub(_var.accSettledBalance))
                );

                //After the rewardpertoken is settled, add the balance of this node to accsettledbalance
                _var.accSettledBalance = _var.accSettledBalance.add(
                    _node.balance
                );

                //Record node settlement results
                _node.rewardPerTokenSettled = _var.rewardPerToken;
                //The first settlement is the time from the last operation to the first one behind it,
                //and then updated to the next node time
                _var.lastUpdateTime = _var.lastSettledTime;
            }

            //If accsettledbalance and totalsupply are equal,
            //it is equivalent to all lock positions expire.
            if (_var.accSettledBalance == _var.totalSupply) {
                //At this time, update lastsettledtime, and then jump out of the loop
                _var.lastSettledTime = MIN_STEP
                    .sub(_now.sub(_var.lastSettledTime).mod(MIN_STEP))
                    .add(_now);
                break;
            }

            //Update to next node time
            _var.lastSettledTime += MIN_STEP;
        }

        accSettledBalance = _var.accSettledBalance;
        lastSettledTime = _var.lastSettledTime;

        rewardPerTokenStored = _var.totalSupply == _var.accSettledBalance
            ? _var.rewardPerToken
            : _var.rewardPerToken.add(
                _now.sub(_var.lastUpdateTime).mul(_var.rewardRate).rdiv(
                    _var.totalSupply.sub(_var.accSettledBalance)
                )
            );
        lastUpdateTime = _now;
    }

    ///@dev Update the reward of specific users
    function _updateUserReward(address _account) private {
        (uint32 _dueTime, , ) = veDF.getLocker(_account);
        uint256 _rewardPerTokenStored = rewardPerTokenStored;

        if (_dueTime > 0) {
            //If the user's lock expires, retrieve the rewardpertokenstored of the expired node
            if (_dueTime < block.timestamp) {
                _rewardPerTokenStored = nodes[_dueTime].rewardPerTokenSettled;
            }

            rewards[_account] = balances[_account]
                .rmul(
                    _rewardPerTokenStored.sub(userRewardPerTokenPaid[_account])
                )
                .add(rewards[_account]);
        }

        userRewardPerTokenPaid[_account] = _rewardPerTokenStored;
    }

    /*********************************/
    /******* Users functions *********/
    /*********************************/

    /**
     * @notice Lock StakedDF and harvest veDF.
     * @dev Create lock-up information and mint veDF on lock-up amount and duration.
     * @param _amount StakedDF token amount.
     * @param _dueTime Due time timestamp, in seconds.
     */
    function create(uint256 _amount, uint256 _dueTime)
        public
        sanityCheck(_amount)
        isDueTimeValid(_dueTime)
        updateReward(msg.sender)
    {
        uint256 _duration = _dueTime.sub(block.timestamp);
        sDF.safeTransferFrom(msg.sender, address(this), _amount);
        uint256 _veDFAmount = veDF.create(msg.sender, _amount, _duration);

        totalSupply = totalSupply.add(_veDFAmount);
        balances[msg.sender] = balances[msg.sender].add(_veDFAmount);
        nodes[_dueTime].balance = nodes[_dueTime].balance.add(_veDFAmount);

        emit Create(msg.sender, _amount, _duration, _veDFAmount);
    }

    /**
     * @notice Increased locked staked sDF and harvest veDF.
     * @dev According to the expiration time in the lock information, the minted veDF.
     * @param _amount StakedDF token amount.
     */
    function refill(uint256 _amount)
        external
        sanityCheck(_amount)
        updateReward(msg.sender)
    {
        sDF.safeTransferFrom(msg.sender, address(this), _amount);
        uint256 _veDFAmount = veDF.refill(msg.sender, _amount);

        (uint32 _dueTime, , ) = veDF.getLocker(msg.sender);

        totalSupply = totalSupply.add(_veDFAmount);
        balances[msg.sender] = balances[msg.sender].add(_veDFAmount);
        nodes[_dueTime].balance = nodes[_dueTime].balance.add(_veDFAmount);

        emit Refill(msg.sender, _amount, _veDFAmount);
    }

    /**
     * @notice Increase the lock duration and harvest veDF.
     * @dev According to the amount of locked StakedDF and expansion time, the minted veDF.
     * @param _dueTime new Due time timestamp, in seconds.
     */
    function extend(uint256 _dueTime)
        external
        isDueTimeValid(_dueTime)
        updateReward(msg.sender)
    {
        (uint32 _oldDueTime, , ) = veDF.getLocker(msg.sender);
        uint256 _oldBalance = balances[msg.sender];

        //Subtract the user balance of the original node
        nodes[_oldDueTime].balance = nodes[_oldDueTime].balance.sub(
            _oldBalance
        );

        uint256 _duration = _dueTime.sub(_oldDueTime);
        uint256 _veDFAmount = veDF.extend(msg.sender, _duration);

        totalSupply = totalSupply.add(_veDFAmount);
        balances[msg.sender] = balances[msg.sender].add(_veDFAmount);

        //Add the user balance of the original node to the new node
        nodes[_dueTime].balance = nodes[_dueTime].balance.add(_veDFAmount).add(
            _oldBalance
        );

        emit Extend(msg.sender, _oldDueTime, _dueTime, _duration, _veDFAmount);
    }

    /**
     * @notice Lock Staked sDF and and update veDF balance.
     * @dev Update the lockup information and veDF balance, return the excess sDF to the user or receive transfer increased amount.
     * @param _amount StakedDF token new amount.
     * @param _dueTime Due time timestamp, in seconds.
     */
    function refresh(uint256 _amount, uint256 _dueTime)
        external
        sanityCheck(_amount)
        isDueTimeValid(_dueTime)
        nonReentrant
        updateReward(msg.sender)
    {
        (, , uint256 _lockedSDF) = veDF.getLocker(msg.sender);
        //If the new amount is greater than the original lock volume, the difference needs to be supplemented
        if (_amount > _lockedSDF) {
            sDF.safeTransferFrom(
                msg.sender,
                address(this),
                _amount.sub(_lockedSDF)
            );
        }

        uint256 _duration = _dueTime.sub(block.timestamp);
        uint256 _oldVEDFAmount = balances[msg.sender];
        uint256 _newVEDFAmount = veDF.refresh2(msg.sender, _amount, _duration);

        balances[msg.sender] = _newVEDFAmount;
        userRewardPerTokenPaid[msg.sender] = rewardPerTokenStored;

        totalSupply = totalSupply.add(_newVEDFAmount).sub(_oldVEDFAmount);
        nodes[_dueTime].balance = nodes[_dueTime].balance.add(_newVEDFAmount);
        accSettledBalance = accSettledBalance.sub(_oldVEDFAmount);

        emit Refresh(
            msg.sender,
            _lockedSDF,
            _amount,
            _duration,
            _oldVEDFAmount,
            _newVEDFAmount
        );
    }

    /**
     * @notice Unlock Staked sDF and burn veDF.
     * @dev Burn veDF and clear lock information.
     */
    function _withdraw2() internal {
        uint256 _burnVEDF = veDF.withdraw2(msg.sender);
        uint256 _oldBalance = balances[msg.sender];

        totalSupply = totalSupply.sub(_oldBalance);
        balances[msg.sender] = balances[msg.sender].sub(_oldBalance);

        //Since totalsupply is reduced and the operation must be performed after the lock expires,
        //accsettledbalance should be reduced at the same time
        accSettledBalance = accSettledBalance.sub(_oldBalance);

        emit Withdraw(msg.sender, _burnVEDF, _oldBalance);
    }

    ///@notice Extract reward
    function getReward() public virtual updateReward(msg.sender) {
        uint256 _reward = rewards[msg.sender];
        if (_reward > 0) {
            rewards[msg.sender] = 0;
            rewardToken.safeTransferFrom(
                rewardDistributor,
                msg.sender,
                _reward
            );
            emit RewardPaid(msg.sender, _reward);
        }
    }

    function exit() external {
        getReward();
        _withdraw2();
    }

    /*********************************/
    /******** Query function *********/
    /*********************************/

    function rewardPerToken()
        external
        updateReward(address(0))
        returns (uint256)
    {
        return rewardPerTokenStored;
    }

    function rewardDistributed() public view returns (uint256) {
        // Have not started yet
        if (block.timestamp < startTime) {
            return rewardDistributedStored;
        }

        return
            rewardDistributedStored.add(
                block
                    .timestamp
                    .sub(MathUpgradeable.max(startTime, lastRateUpdateTime))
                    .mul(rewardRate)
            );
    }

    function earned(address _account)
        public
        updateReward(_account)
        returns (uint256)
    {
        return rewards[_account];
    }

    /**
     * @dev Used to query the information of the locker.
     * @param _lockerAddress veDF locker address.
     * @return Information of the locker.
     *         due time;
     *         Lock up duration;
     *         Lock up sDF amount;
     */
    function getLocker(address _lockerAddress)
        external
        view
        returns (
            uint32,
            uint32,
            uint96
        )
    {
        return veDF.getLocker(_lockerAddress);
    }

    /**
     * @dev Used to query the information of the locker.
     * @param _lockerAddress veDF locker address.
     * @param _startTime Start time.
     * @param _dueTime Due time.
     * @param _duration Lock up duration.
     * @param _sDFAmount Lock up sDF amount.
     * @param _veDFAmount veDF amount.
     * @param _rewardAmount Reward amount.
     * @param _lockedStatus Locked status, 0: no lockup; 1: locked; 2: Lock expired.
     */
    function getLockerInfo(address _lockerAddress)
        external
        returns (
            uint32 _startTime,
            uint32 _dueTime,
            uint32 _duration,
            uint96 _sDFAmount,
            uint256 _veDFAmount,
            uint256 _stakedveDF,
            uint256 _rewardAmount,
            uint256 _lockedStatus
        )
    {
        (_dueTime, _duration, _sDFAmount) = veDF.getLocker(_lockerAddress);
        _startTime = _dueTime > _duration ? _dueTime - _duration : 0;

        _veDFAmount = veDF.balanceOf(_lockerAddress);

        _rewardAmount = earned(_lockerAddress);

        _lockedStatus = 2;
        if (_dueTime > block.timestamp) {
            _lockedStatus = 1;
            _stakedveDF = _veDFAmount;
        }
        if (_dueTime == 0) _lockedStatus = 0;
    }

    /**
     * @dev Calculate the expected amount of users.
     * @param _lockerAddress veDF locker address.
     * @param _amount StakedDF token amount.
     * @param _duration Duration, in seconds.
     * @return veDF amount.
     */
    function calcBalanceReceived(
        address _lockerAddress,
        uint256 _amount,
        uint256 _duration
    ) external view returns (uint256) {
        return veDF.calcBalanceReceived(_lockerAddress, _amount, _duration);
    }

    /**
     * @dev Calculate the expected annual interest rate of users.
     * @param _lockerAddress veDF locker address.
     * @return annual interest.
     */
    function estimateLockerAPY(address _lockerAddress)
        external
        updateReward(_lockerAddress)
        returns (uint256)
    {
        uint256 _totalSupply = totalSupply.sub(accSettledBalance);
        if (_totalSupply == 0) return 0;

        (uint256 _dueTime, , uint96 _sDFAmount) = veDF.getLocker(_lockerAddress);
        uint256 _principal = uint256(_sDFAmount);
        if (_dueTime <= block.timestamp || _principal == 0) return 0;

        uint256 _annualInterest = rewardRate
            .mul(balances[_lockerAddress])
            .mul(365 days)
            .div(_totalSupply);

        return _annualInterest.rdiv(_principal);
    }

    /**
     * @dev Query veDF lock information.
     * @return veDF total supply.
     *         Total locked sDF
     *         Total settlement due
     *         Reward rate per second
     */
    function getLockersInfo()
        external
        updateReward(address(0))
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return (
            veDF.totalSupply(),
            sDF.balanceOf(address(veDF)),
            accSettledBalance,
            rewardRate
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
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
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {_setPendingOwner} and {_acceptOwner}.
 */
contract Ownable {
    /**
     * @dev Returns the address of the current owner.
     */
    address payable public owner;

    /**
     * @dev Returns the address of the current pending owner.
     */
    address payable public pendingOwner;

    event NewOwner(address indexed previousOwner, address indexed newOwner);
    event NewPendingOwner(
        address indexed oldPendingOwner,
        address indexed newPendingOwner
    );

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner == msg.sender, "onlyOwner: caller is not the owner");
        _;
    }

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal {
        owner = msg.sender;
        emit NewOwner(address(0), msg.sender);
    }

    /**
     * @notice Base on the inputing parameter `newPendingOwner` to check the exact error reason.
     * @dev Transfer contract control to a new owner. The newPendingOwner must call `_acceptOwner` to finish the transfer.
     * @param newPendingOwner New pending owner.
     */
    function _setPendingOwner(address payable newPendingOwner)
        external
        onlyOwner
    {
        require(
            newPendingOwner != address(0) && newPendingOwner != pendingOwner,
            "_setPendingOwner: New owenr can not be zero address and owner has been set!"
        );

        // Gets current owner.
        address oldPendingOwner = pendingOwner;

        // Sets new pending owner.
        pendingOwner = newPendingOwner;

        emit NewPendingOwner(oldPendingOwner, newPendingOwner);
    }

    /**
     * @dev Accepts the admin rights, but only for pendingOwenr.
     */
    function _acceptOwner() external {
        require(
            msg.sender == pendingOwner,
            "_acceptOwner: Only for pending owner!"
        );

        // Gets current values for events.
        address oldOwner = owner;
        address oldPendingOwner = pendingOwner;

        // Set the new contract owner.
        owner = pendingOwner;

        // Clear the pendingOwner.
        pendingOwner = address(0);

        emit NewOwner(oldOwner, owner);
        emit NewPendingOwner(oldPendingOwner, pendingOwner);
    }

    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeRatioMath {
    using SafeMathUpgradeable for uint256;

    uint256 private constant BASE = 10**18;

    function rdiv(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a.mul(BASE).div(b);
    }

    function rmul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a.mul(b).div(BASE);
    }

    function rdivup(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a.mul(BASE).add(b.sub(1)).div(b);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IRewardDistributor {

    function addRecipient(address _recipient) external;
    function removeRecipient(address _recipient) external;

    function setRecipientRewardRate(address _recipient, uint256 _rewardRate) external;
    function addRecipientAndSetRewardRate(address _recipient, uint256 _rewardRate) external;

    function rescueStakingPoolTokens(
        address _stakingPool,
        address _token,
        uint256 _amount,
        address _to
    ) external;

    function rewardToken() external view returns (address);

    function getAllRecipients() external view returns (address[] memory _allRecipients);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IStakedDF is IERC20Upgradeable {
    function stake(address _recipient, uint256 _rawUnderlyingAmount)
        external
        returns (uint256 _tokenAmount);

    function unstake(address _recipient, uint256 _rawTokenAmount)
        external
        returns (uint256 _tokenAmount);

    function getCurrentExchangeRate()
        external
        view
        returns (uint256 _exchangeRate);

    function DF() external view returns (address);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "../interface/IveDF.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";

contract LPTokenWrapper {
    using SafeMathUpgradeable for uint256;

    IveDF public veDF;

    uint256 public totalSupply;

    mapping(address => uint256) internal balances;

    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMathUpgradeable {
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20Upgradeable.sol";
import "../../math/SafeMathUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";

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
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;

    function safeTransfer(IERC20Upgradeable token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20Upgradeable token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20Upgradeable token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IveDF is IERC20Upgradeable {
    function create(
        address _recipient,
        uint256 _amount,
        uint256 _duration
    ) external returns (uint96);

    function refresh(
        address _recipient,
        uint256 _amount,
        uint256 _duration
    ) external returns (uint96, uint256);

    function refresh2(
        address _recipient,
        uint256 _amount,
        uint256 _duration
    ) external returns (uint96);

    function refill(address _recipient, uint256 _amount)
        external
        returns (uint96);

    function extend(address _recipient, uint256 _duration)
        external
        returns (uint96);

    function withdraw(address _from) external returns (uint96);

    function withdraw2(address _from) external returns (uint96);

    /**
     * @dev Used to query the information of the locker.
     * @param _lockerAddress veDF locker address.
     * @return Information of the locker.
     *         due time;
     *         Lock up duration;
     *         Lock up sDF amount;
     */
    function getLocker(address _lockerAddress)
        external
        view
        returns (
            uint32,
            uint32,
            uint96
        );

    /**
     * @dev Calculate the expected amount of users.
     * @param _lockerAddress veDF locker address.
     * @param _amount Staked DF token amount.
     * @param _duration Duration, in seconds.
     * @return veDF amount.
     */
    function calcBalanceReceived(
        address _lockerAddress,
        uint256 _amount,
        uint256 _duration
    ) external view returns (uint256);

    function getAnnualInterestRate(
        address _lockerAddress,
        uint256 _amount,
        uint256 _duration
    ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;


/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 * 
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 * 
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
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
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

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

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        address self = address(this);
        uint256 cs;
        // solhint-disable-next-line no-inline-assembly
        assembly { cs := extcodesize(self) }
        return cs == 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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