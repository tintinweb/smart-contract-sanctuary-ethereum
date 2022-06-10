// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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
pragma solidity 0.8.14;

import "./utils/Interfaces.sol";
import "./utils/MathUtil.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title Controller contract
/// @dev Controller contract for Prime Pools is based on the convex Booster.sol contract
contract Controller {
    event OwnerChanged(address _newOwner);
    event FeeManagerChanged(address _newFeeManager);
    event PoolManagerChanged(address _newPoolManager);
    event TreasuryChanged(address _newTreasury);
    event FeesChanged(uint256 _newPlatformFee, uint256 _newProfitFee);

    error Unauthorized();
    error Shutdown();
    error PoolIsClosed();
    error InvalidParameters();

    uint256 public constant MAX_FEES = 2000;
    uint256 public constant FEE_DENOMINATOR = 10000;
    uint256 public constant MAX_LOCK_TIME = 365 days; // 1 year is the time for the new deposided tokens to be locked until they can be withdrawn

    address public immutable bal;
    address public immutable staker;
    address public immutable voteOwnership; // 0xE478de485ad2fe566d49342Cbd03E49ed7DB3356
    address public immutable voteParameter; // 0xBCfF8B0b9419b9A88c44546519b1e909cF330399
    address public immutable feeDistro; // Balancer FeeDistributor

    uint256 public profitFees = 250; //2.5% // FEE_DENOMINATOR/100*2.5
    uint256 public platformFees = 1000; //10% //possible fee to build treasury

    address public owner;
    address public feeManager;
    address public poolManager;
    address public rewardFactory;
    address public stashFactory;
    address public tokenFactory;
    address public voteDelegate;
    address public treasury;
    address public lockRewards;
    address public lockFees;
    IERC20 public feeToken;

    bool public isShutdown;

    struct PoolInfo {
        address lptoken;
        address token;
        address gauge;
        address balRewards;
        address stash;
        bool shutdown;
    }

    //index(pid) -> pool
    PoolInfo[] public poolInfo;
    mapping(address => bool) public gaugeMap;

    event Deposited(
        address indexed user,
        uint256 indexed poolid,
        uint256 amount
    );

    event Withdrawn(
        address indexed user,
        uint256 indexed poolid,
        uint256 amount
    );

    constructor(
        address _staker,
        address _bal,
        address _feeDistro,
        address _voteOwnership,
        address _voteParameter
    ) {
        bal = _bal;
        feeDistro = _feeDistro;
        voteOwnership = _voteOwnership;
        voteParameter = _voteParameter;
        staker = _staker;
        owner = msg.sender;
        voteDelegate = msg.sender;
        feeManager = msg.sender;
        poolManager = msg.sender;
    }

    modifier onlyAddress(address authorizedAddress) {
        if (msg.sender != authorizedAddress) {
            revert Unauthorized();
        }
        _;
    }

    modifier isNotShutDown() {
        if (isShutdown) {
            revert Shutdown();
        }
        _;
    }

    /// SETTER SECTION ///

    /// @notice sets the owner variable
    /// @param _owner The address of the owner of the contract
    function setOwner(address _owner) external onlyAddress(owner) {
        owner = _owner;
        emit OwnerChanged(_owner);
    }

    /// @notice sets the feeManager variable
    /// @param _feeM The address of the fee manager
    function setFeeManager(address _feeM) external onlyAddress(feeManager) {
        feeManager = _feeM;
        emit FeeManagerChanged(_feeM);
    }

    /// @notice sets the poolManager variable
    /// @param _poolM The address of the pool manager
    function setPoolManager(address _poolM) external onlyAddress(poolManager) {
        poolManager = _poolM;
        emit PoolManagerChanged(_poolM);
    }

    /// @notice sets the reward, token, and stash factory addresses
    /// @param _rfactory The address of the reward factory
    /// @param _sfactory The address of the stash factory
    /// @param _tfactory The address of the token factory
    function setFactories(
        address _rfactory,
        address _sfactory,
        address _tfactory
    ) external onlyAddress(owner) {
        //reward factory only allow this to be called once even if owner
        //removes ability to inject malicious staking contracts
        //token factory can also be immutable
        if (rewardFactory == address(0)) {
            rewardFactory = _rfactory;
            tokenFactory = _tfactory;
        }

        //stash factory should be considered more safe to change
        //updating may be required to handle new types of gauges
        stashFactory = _sfactory;
    }

    /// @notice sets the voteDelegate variable
    /// @param _voteDelegate The address of whom votes will be delegated to
    function setVoteDelegate(address _voteDelegate) external {
        if (msg.sender != voteDelegate) {
            revert Unauthorized();
        }
        voteDelegate = _voteDelegate;
    }

    /// @notice sets the lockRewards variable
    /// @param _rewards The address of the rewards contract
    function setRewardContracts(address _rewards) external onlyAddress(owner) {
        //reward contracts are immutable or else the owner
        //has a means to redeploy and mint bal via rewardClaimed()
        if (lockRewards == address(0)) {
            lockRewards = _rewards;
        }
    }

    /// @notice sets the address of the feeToken
    /// @param _feeToken feeToken
    function setFeeInfo(IERC20 _feeToken) external onlyAddress(feeManager) {
        //create a new reward contract for the new token
        lockFees = IRewardFactory(rewardFactory).createTokenRewards(
            address(_feeToken),
            lockRewards,
            address(this)
        );
        feeToken = _feeToken;
    }

    /// @notice sets the lock, staker, caller, platform fees and profit fees
    /// @param _profitFee The amount to set for the profit fees
    /// @param _platformFee The amount to set for the platform fees
    function setFees(uint256 _platformFee, uint256 _profitFee)
        external
        onlyAddress(feeManager)
    {
        uint256 total = _profitFee + _platformFee;
        if (total > MAX_FEES) {
            revert InvalidParameters();
        }

        //values must be within certain ranges
        if (
            _platformFee >= 500 && //5%
            _platformFee <= 2000 && //20%
            _profitFee >= 100 &&
            _profitFee <= 500
        ) {
            platformFees = _platformFee;
            profitFees = _profitFee;
            emit FeesChanged(_platformFee, _profitFee);
        }
    }

    /// @notice sets the contracts treasury variables
    /// @param _treasury The address of the treasury contract
    function setTreasury(address _treasury) external onlyAddress(feeManager) {
        treasury = _treasury;
        emit TreasuryChanged(_treasury);
    }

    /// END SETTER SECTION ///

    /// @notice returns the length of the pool
    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    /// @notice creates a new pool
    /// @param _lptoken The address of the lp token
    /// @param _gauge The address of the gauge controller
    function addPool(address _lptoken, address _gauge)
        external
        onlyAddress(poolManager)
        isNotShutDown
        returns (bool)
    {
        if (_gauge == address(0) || _lptoken == address(0)) {
            revert InvalidParameters();
        }
        //the next pool's pid
        uint256 pid = poolInfo.length;
        //create a tokenized deposit
        address token = ITokenFactory(tokenFactory).createDepositToken(
            _lptoken
        );
        //create a reward contract for bal rewards
        address newRewardPool = IRewardFactory(rewardFactory).createBalRewards(
            pid,
            token
        );
        //create a stash to handle extra incentives
        address stash = IStashFactory(stashFactory).createStash(
            pid,
            _gauge,
            staker
        );
        //add the new pool
        poolInfo.push(
            PoolInfo({
                lptoken: _lptoken,
                token: token,
                gauge: _gauge,
                balRewards: newRewardPool,
                stash: stash,
                shutdown: false
            })
        );
        gaugeMap[_gauge] = true;
        //give stashes access to rewardfactory and voteproxy
        //   voteproxy so it can grab the incentive tokens off the contract after claiming rewards
        //   reward factory so that stashes can make new extra reward contracts if a new incentive is added to the gauge
        if (stash != address(0)) {
            poolInfo[pid].stash = stash;
            IVoterProxy(staker).setStashAccess(stash, true);
            IRewardFactory(rewardFactory).setAccess(stash, true);
        }
        return true;
    }

    /// @notice shuts down a currently active pool
    /// @param _pid The id of the pool to shutdown
    function shutdownPool(uint256 _pid)
        external
        onlyAddress(poolManager)
        returns (bool)
    {
        PoolInfo storage pool = poolInfo[_pid];

        //withdraw from gauge
        // solhint-disable-next-line
        try IVoterProxy(staker).withdrawAll(pool.lptoken, pool.gauge) {
            // solhint-disable-next-line
        } catch {}

        pool.shutdown = true;
        gaugeMap[pool.gauge] = false;
        return true;
    }

    /// @notice shuts down all pools
    /// @dev This shuts down the contract, unstakes and withdraws all LP tokens
    function shutdownSystem() external onlyAddress(owner) {
        isShutdown = true;

        for (uint256 i = 0; i < poolInfo.length; i++) {
            PoolInfo storage pool = poolInfo[i];
            if (pool.shutdown) continue;

            address token = pool.lptoken;
            address gauge = pool.gauge;

            //withdraw from gauge
            try IVoterProxy(staker).withdrawAll(token, gauge) {
                pool.shutdown = true;
                // solhint-disable-next-line
            } catch {}
        }
    }

    /// @notice deposits an amount into a specific pool, mints reward tokens and stakes them into the reward contract
    /// @param _pid The pool id to deposit lp tokens into
    /// @param _amount The amount of lp tokens to be deposited
    /// @param _stake bool for wheather the tokens should be staked
    function deposit(
        uint256 _pid,
        uint256 _amount,
        bool _stake
    ) public isNotShutDown returns (bool) {
        PoolInfo storage pool = poolInfo[_pid];
        if (pool.shutdown) {
            revert PoolIsClosed();
        }
        //send to proxy to stake
        address lptoken = pool.lptoken;
        IERC20(lptoken).transferFrom(msg.sender, staker, _amount);

        //stake
        address gauge = pool.gauge;
        IVoterProxy(staker).deposit(lptoken, gauge); // VoterProxy

        //some gauges claim rewards when depositing, stash them in a seperate contract until next claim
        address stash = pool.stash;
        if (stash != address(0)) {
            IStash(stash).stashRewards();
        }

        address token = pool.token; //D2DPool token
        if (_stake) {
            //mint here and send to rewards on user behalf
            ITokenMinter(token).mint(address(this), _amount);
            address rewardContract = pool.balRewards;
            IERC20(token).approve(rewardContract, _amount);
            IRewards(rewardContract).stakeFor(msg.sender, _amount);
        } else {
            //add user balance directly
            ITokenMinter(token).mint(msg.sender, _amount);
        }

        emit Deposited(msg.sender, _pid, _amount);
        return true;
    }

    /// @notice deposits and stakes all LP tokens
    /// @param _pid The pool id to deposit lp tokens into
    /// @param _stake bool for wheather the tokens should be staked
    function depositAll(uint256 _pid, bool _stake) external returns (bool) {
        address lptoken = poolInfo[_pid].lptoken;
        uint256 balance = IERC20(lptoken).balanceOf(msg.sender);
        deposit(_pid, balance, _stake);
        return true;
    }

    /// @notice internal function that withdraws lp tokens from the pool
    /// @param _pid The pool id to withdraw the tokens from
    /// @param _amount amount of LP tokens to withdraw
    /// @param _from address of where the lp tokens will be withdrawn from
    /// @param _to address of where the lp tokens will be sent to
    function _withdraw(
        uint256 _pid,
        uint256 _amount,
        address _from,
        address _to
    ) internal {
        PoolInfo storage pool = poolInfo[_pid];
        address lptoken = pool.lptoken;
        address gauge = pool.gauge;

        //remove lp balance
        address token = pool.token;
        ITokenMinter(token).burn(_from, _amount);

        //pull from gauge if not shutdown
        // if shutdown tokens will be in this contract
        if (!pool.shutdown) {
            IVoterProxy(staker).withdraw(lptoken, gauge, _amount);
        }

        //some gauges claim rewards when withdrawing, stash them in a seperate contract until next claim
        //do not call if shutdown since stashes wont have access
        address stash = pool.stash;
        if (stash != address(0) && !isShutdown && !pool.shutdown) {
            IStash(stash).stashRewards();
        }

        //return lp tokens
        IERC20(lptoken).transfer(_to, _amount);

        emit Withdrawn(_to, _pid, _amount);
    }

    /// @notice withdraws lp tokens from the pool
    /// @param _pid The pool id to withdraw lp tokens from
    /// @param _amount amount of LP tokens to withdraw
    function withdraw(uint256 _pid, uint256 _amount) public returns (bool) {
        _withdraw(_pid, _amount, msg.sender, msg.sender);
        return true;
    }

    /// @notice withdraws all of the lp tokens in the pool
    /// @param _pid The pool id to withdraw lp tokens from
    function withdrawAll(uint256 _pid) public returns (bool) {
        address token = poolInfo[_pid].token;
        uint256 userBal = IERC20(token).balanceOf(msg.sender);
        withdraw(_pid, userBal);
        return true;
    }

    /// @notice withdraws LP tokens and sends rewards to a specified address
    /// @param _pid The pool id to deposit lp tokens into
    /// @param _amount amount of LP tokens to withdraw
    function withdrawTo(
        uint256 _pid,
        uint256 _amount,
        address _to
    ) external returns (bool) {
        address rewardContract = poolInfo[_pid].balRewards;
        if (msg.sender != rewardContract) {
            revert Unauthorized();
        }
        _withdraw(_pid, _amount, msg.sender, _to);
        return true;
    }

    //withdraw WethBal, which was unlocked after a year of usage
    function withdrawUnlockedWethBal(uint256 _pid, uint256 _amount)
        public
        returns (bool)
    {
        PoolInfo storage pool = poolInfo[_pid];
        address gauge = pool.gauge;

        //pull from gauge if not shutdown
        // if shutdown tokens will be in this contract
        if (!pool.shutdown) {
            IVoterProxy(staker).withdrawWethBal(treasury, gauge, _amount);
        }

        return true;
    }

    // restake wethBAL, which was unlocked after a year of usage
    function restake(uint256 _pid) public isNotShutDown returns (bool) {
        PoolInfo storage pool = poolInfo[_pid];
        if (pool.shutdown) {
            revert PoolIsClosed();
        }
        //some gauges claim rewards when depositing, stash them in a seperate contract until next claim
        address stash = pool.stash;

        if (stash != address(0)) {
            IStash(stash).stashRewards();
        }

        address token = pool.token;

        uint256 _amount = IERC20(token).balanceOf(msg.sender); //need to get current balance; user could withdraw some amount earlier
        // solhint-disable-next-line
        IVoterProxy(staker).increaseTime(block.timestamp + MAX_LOCK_TIME);

        emit Deposited(msg.sender, _pid, _amount);
        return true;
    }

    /// @notice submits votes for proposals
    /// @param _voteId the id of the vote
    /// @param _votingAddress the address placing the vote
    /// @param _support boolean for the vote support
    function vote(
        uint256 _voteId,
        address _votingAddress,
        bool _support
    ) external onlyAddress(voteDelegate) returns (bool) {
        require(
            _votingAddress == voteOwnership || _votingAddress == voteParameter,
            "!voteAddr"
        );

        IVoterProxy(staker).vote(_voteId, _votingAddress, _support);
        return true;
    }

    /// @notice sets the voteGaugeWeight
    /// @param _gauge array of gauge addresses
    /// @param _weight array of vote weights
    function voteGaugeWeight(
        address[] calldata _gauge,
        uint256[] calldata _weight
    ) external onlyAddress(voteDelegate) returns (bool) {
        for (uint256 i = 0; i < _gauge.length; i++) {
            IVoterProxy(staker).voteGaugeWeight(_gauge[i], _weight[i]);
        }
        return true;
    }

    /// @notice claims rewards from a specific pool
    /// @param _pid the id of the pool
    /// @param _gauge address of the gauge
    function claimRewards(uint256 _pid, address _gauge)
        external
        returns (bool)
    {
        address stash = poolInfo[_pid].stash;
        if (msg.sender != stash) {
            revert Unauthorized();
        }
        IVoterProxy(staker).claimRewards(_gauge);
        return true;
    }

    /// @notice sets the gauge redirect address
    /// @param _pid the id of the pool
    function setGaugeRedirect(uint256 _pid) external returns (bool) {
        address stash = poolInfo[_pid].stash;
        if (msg.sender != stash) {
            revert Unauthorized();
        }
        address gauge = poolInfo[_pid].gauge;
        bytes memory data = abi.encodeWithSelector(
            bytes4(keccak256("set_rewards_receiver(address)")),
            stash
        );
        IVoterProxy(staker).execute(gauge, uint256(0), data);
        return true;
    }

    /// @notice internal function that claims rewards from a pool and disperses them to the rewards contract
    /// @param _pid the id of the pool where lp tokens are held
    function _earmarkRewards(uint256 _pid) internal {
        PoolInfo storage pool = poolInfo[_pid];
        if (pool.shutdown) {
            revert PoolIsClosed();
        }
        address gauge = pool.gauge;

        //claim bal
        IVoterProxy(staker).claimBal(gauge);

        //check if there are extra rewards
        address stash = pool.stash;
        if (stash != address(0)) {
            //claim extra rewards
            IStash(stash).claimRewards();
            //process extra rewards
            IStash(stash).processStash();
        }

        //bal balance
        uint256 balBal = IERC20(bal).balanceOf(address(this));

        if (balBal > 0) {
            //Profit fees are taken on the rewards together with platform fees.
            uint256 _profit = (balBal * profitFees) / FEE_DENOMINATOR;
            //profit fees are distributed to the gnosisSafe, which owned by Prime; which is here feeManager
            IERC20(bal).transfer(feeManager, _profit);

            //send treasury
            if (
                treasury != address(0) &&
                treasury != address(this) &&
                platformFees > 0
            ) {
                //only subtract after address condition check
                uint256 _platform = (balBal * platformFees) / FEE_DENOMINATOR;
                balBal = balBal - _platform;
                IERC20(bal).transfer(treasury, _platform);
            }
            balBal = balBal - _profit;

            //send bal to lp provider reward contract
            address rewardContract = pool.balRewards;
            IERC20(bal).transfer(rewardContract, balBal);
            IRewards(rewardContract).queueNewRewards(balBal);
        }
    }

    /// @notice external function that claims rewards from a pool and disperses them to the rewards contract
    /// @param _pid the id of the pool where lp tokens are held
    function earmarkRewards(uint256 _pid)
        external
        isNotShutDown
        returns (bool)
    {
        _earmarkRewards(_pid);
        return true;
    }

    /// @notice claims fees from the feeDistro contract, transfers the lockfees into the rewards contract
    function earmarkFees() external returns (bool) {
        //claim fee rewards
        IVoterProxy(staker).claimFees(feeDistro, feeToken);
        //send fee rewards to reward contract
        uint256 _balance = feeToken.balanceOf(address(this));
        feeToken.transfer(lockFees, _balance);
        IRewards(lockFees).queueNewRewards(_balance);
        return true;
    }

    /// @notice  callback function that gets called when a reward is claimed and recieved
    /// @param _pid the id of the pool
    function rewardClaimed(
        uint256 _pid,
        address,
        uint256
    ) external view returns (bool) {
        address rewardContract = poolInfo[_pid].balRewards;
        require(
            msg.sender == rewardContract || msg.sender == lockRewards,
            "!auth"
        );
        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IBalGauge {
    function deposit(uint256) external;

    function balanceOf(address) external view returns (uint256);

    function withdraw(uint256) external;

    function claim_rewards() external;

    function reward_tokens(uint256) external view returns (address);

    function lp_token() external view returns (address);
}

interface IBalVoteEscrow {
    function create_lock(uint256, uint256) external;

    function increase_amount(uint256) external;

    function increase_unlock_time(uint256) external;

    function withdraw() external;

    function smart_wallet_checker() external view returns (address);

    function balanceOf(address, uint256) external view returns (uint256);

    function balanceOfAt(address, uint256) external view returns (uint256);
}

interface IWalletChecker {
    function check(address) external view returns (bool);
}

interface IVoting {
    function vote(
        uint256,
        bool,
        bool
    ) external; //voteId, support, executeIfDecided

    function vote_for_gauge_weights(address, uint256) external;
}

interface IMinter {
    function mint(address) external;
}

interface IVoterProxy {
    function deposit(address _token, address _gauge) external;

    function withdrawWethBal(
        address,
        address,
        uint256
    ) external returns (bool);

    function withdraw(IERC20 _asset) external returns (uint256 balance);

    function withdraw(
        address _token,
        address _gauge,
        uint256 _amount
    ) external;

    function withdrawAll(address _token, address _gauge) external;

    function createLock(uint256 _value, uint256 _unlockTime) external;

    function increaseAmount(uint256 _value) external;

    function increaseTime(uint256 _unlockTimestamp) external;

    function release() external;

    function claimBal(address _gauge) external returns (uint256);

    function claimRewards(address _gauge) external;

    function claimFees(address _distroContract, IERC20 _token)
        external
        returns (uint256);

    function setStashAccess(address _stash, bool _status) external;

    function vote(
        uint256 _voteId,
        address _votingAddress,
        bool _support
    ) external;

    function voteGaugeWeight(address _gauge, uint256 _weight) external;

    function balanceOfPool(address _gauge) external view returns (uint256);

    function operator() external view returns (address);

    function execute(
        address _to,
        uint256 _value,
        bytes calldata _data
    ) external returns (bool, bytes memory);
}

interface IRewards {
    function stake(address, uint256) external;

    function stakeFor(address, uint256) external;

    function withdraw(address, uint256) external;

    function exit(address) external;

    function getReward(address) external;

    function queueNewRewards(uint256) external;

    function notifyRewardAmount(uint256) external;

    function addExtraReward(address) external;

    function stakingToken() external view returns (address);

    function rewardToken() external view returns (address);

    function earned(address account) external view returns (uint256);
}

interface IStash {
    function stashRewards() external returns (bool);

    function processStash() external returns (bool);

    function claimRewards() external returns (bool);

    function initialize(
        uint256 _pid,
        address _operator,
        address _staker,
        address _gauge,
        address _rewardFactory
    ) external;
}

interface IFeeDistro {
    /**
     * @notice Claims all pending distributions of the provided token for a user.
     * @dev It's not necessary to explicitly checkpoint before calling this function, it will ensure the FeeDistributor
     * is up to date before calculating the amount of tokens to be claimed.
     * @param user - The user on behalf of which to claim.
     * @param token - The ERC20 token address to be claimed.
     * @return The amount of `token` sent to `user` as a result of claiming.
     */
    function claimToken(address user, IERC20 token) external returns (uint256);

    /**
     * @notice Claims a number of tokens on behalf of a user.
     * @dev A version of `claimToken` which supports claiming multiple `tokens` on behalf of `user`.
     * See `claimToken` for more details.
     * @param user - The user on behalf of which to claim.
     * @param tokens - An array of ERC20 token addresses to be claimed.
     * @return An array of the amounts of each token in `tokens` sent to `user` as a result of claiming.
     */
    function claimTokens(address user, IERC20[] calldata tokens)
        external
        returns (uint256[] memory);
}

interface ITokenMinter {
    function mint(address, uint256) external;

    function burn(address, uint256) external;
}

interface IDeposit {
    function isShutdown() external view returns (bool);

    function balanceOf(address _account) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function poolInfo(uint256)
        external
        view
        returns (
            address,
            address,
            address,
            address,
            address,
            bool
        );

    function rewardClaimed(
        uint256,
        address,
        uint256
    ) external;

    function withdrawTo(
        uint256,
        uint256,
        address
    ) external;

    function claimRewards(uint256, address) external returns (bool);

    function rewardArbitrator() external returns (address);

    function setGaugeRedirect(uint256 _pid) external returns (bool);

    function owner() external returns (address);
}

interface ICrvDeposit {
    function deposit(uint256, bool) external;

    function lockIncentive() external view returns (uint256);
}

interface IRewardFactory {
    function setAccess(address, bool) external;

    function createBalRewards(uint256, address) external returns (address);

    function createTokenRewards(
        address,
        address,
        address
    ) external returns (address);

    function activeRewardCount(address) external view returns (uint256);

    function addActiveReward(address, uint256) external returns (bool);

    function removeActiveReward(address, uint256) external returns (bool);
}

interface IStashFactory {
    function createStash(
        uint256,
        address,
        address
    ) external returns (address);
}

interface ITokenFactory {
    function createDepositToken(address) external returns (address);
}

interface IPools {
    function addPool(address, address) external returns (bool);

    function forceAddPool(address, address) external returns (bool);

    function shutdownPool(uint256) external returns (bool);

    function poolInfo(uint256)
        external
        view
        returns (
            address,
            address,
            address,
            address,
            address,
            bool
        );

    function poolLength() external view returns (uint256);

    function gaugeMap(address) external view returns (bool);

    function setPoolManager(address _poolM) external;
}

interface IVestedEscrow {
    function fund(address[] calldata _recipient, uint256[] calldata _amount)
        external
        returns (bool);
}

interface GaugeController {
    function gauge_types(address _addr) external returns (int128);
}

interface LiquidityGauge {
    function integrate_fraction(address _address) external returns (uint256);

    function user_checkpoint(address _address) external returns (bool);
}

interface IProxyFactory {
    function clone(address _target) external returns (address);
}

interface IRewardHook {
    function onRewardClaim() external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

// copied from https://github.com/Uniswap/v2-core/blob/master/contracts/libraries/SafeMath.sol

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUtil {
    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /// @dev Gas optimization for loops that iterate over extra rewards
    /// We know that this can't overflow because we can't interate over big arrays
    function unsafeInc(uint256 x) internal pure returns (uint256) {
        unchecked {
            return x + 1;
        }
    }
}