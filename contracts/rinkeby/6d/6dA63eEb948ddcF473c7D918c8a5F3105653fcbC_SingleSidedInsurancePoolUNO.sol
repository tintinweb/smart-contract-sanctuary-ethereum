// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

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
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/ICapitalAgent.sol";
import "./interfaces/IExchangeAgent.sol";
import "./interfaces/IMigration.sol";
import "./interfaces/IRewarderFactory.sol";
import "./interfaces/IRiskPoolFactory.sol";
import "./interfaces/ISingleSidedInsurancePool.sol";
import "./interfaces/IRewarder.sol";
import "./interfaces/IRiskPool.sol";
import "./interfaces/ISyntheticSSIPFactory.sol";
import "./libraries/TransferHelper.sol";

contract SingleSidedInsurancePoolUNO is ISingleSidedInsurancePool, ReentrancyGuard, Ownable {
    address public claimAssessor;
    address private exchangeAgent;
    address public migrateTo;
    address public capitalAgent;
    address public syntheticSSIP;

    uint256 public LOCK_TIME = 10 days;
    uint256 public constant ACC_UNO_PRECISION = 1e18;
    uint256 public STAKING_START_TIME;

    address public rewarder;
    address public override riskPool;
    struct PoolInfo {
        uint128 lastRewardBlock;
        uint128 accUnoPerShare;
        uint256 unoMultiplierPerBlock;
    }

    struct UserInfo {
        uint256 lastWithdrawTime;
        uint256 rewardDebt;
        uint256 amount;
    }

    mapping(address => UserInfo) public userInfo;

    PoolInfo public poolInfo;

    event RiskPoolCreated(address indexed _SSIP, address indexed _pool);
    event StakedInPool(address indexed _staker, address indexed _pool, uint256 _amount);
    event LeftPool(address indexed _staker, address indexed _pool, uint256 _requestAmount);
    event LogUpdatePool(uint128 _lastRewardBlock, uint256 _lpSupply, uint256 _accUnoPerShare);
    event Harvest(address indexed _user, address indexed _receiver, uint256 _amount);
    event LogSetExchangeAgent(address indexed _exchangeAgent);
    event LogLeaveFromPendingSSIP(
        address indexed _user,
        address indexed _riskPool,
        uint256 _withdrawLpAmount,
        uint256 _withdrawUnoAmount
    );
    event PolicyClaim(address indexed _user, uint256 _claimAmount);
    event LogLpTransferInSSIP(address indexed _from, address indexed _to, uint256 _amount);
    event LogCreateRewarder(address indexed _SSIP, address indexed _rewarder, address _currency);
    event LogCreateSyntheticSSIP(address indexed _SSIP, address indexed _syntheticSSIP, address indexed _lpToken);
    event LogCancelWithdrawRequest(address indexed _user, uint256 _cancelAmount, uint256 _cancelAmountInUno);
    event LogMigrate(address indexed _user, address indexed _migrateTo, uint256 _migratedAmount);
    event LogSetCapitalAgent(address indexed _SSIP, address indexed _capitalAgent);
    event LogSetRewardMultiplier(address indexed _SSIP, uint256 _rewardPerBlock);
    event LogSetClaimAssessor(address indexed _SSIP, address indexed _claimAssessor);
    event LogSetMigrateTo(address indexed _SSIP, address indexed _migrateTo);
    event LogSetMinLPCapital(address indexed _SSIP, uint256 _minLPCapital);
    event LogSetLockTime(address indexed _SSIP, uint256 _lockTime);
    event LogSetStakingStartTime(address indexed _SSIP, uint256 _startTime);

    constructor(
        address _claimAssessor,
        address _exchangeAgent,
        address _capitalAgent,
        address _multiSigWallet
    ) {
        require(_claimAssessor != address(0), "UnoRe: zero claimAssessor address");
        require(_exchangeAgent != address(0), "UnoRe: zero exchangeAgent address");
        require(_capitalAgent != address(0), "UnoRe: zero capitalAgent address");
        require(_multiSigWallet != address(0), "UnoRe: zero multisigwallet address");
        exchangeAgent = _exchangeAgent;
        claimAssessor = _claimAssessor;
        capitalAgent = _capitalAgent;
        // transferOwnership(_multiSigWallet);
    }

    modifier onlyClaimAssessor() {
        require(msg.sender == claimAssessor, "UnoRe: Forbidden");
        _;
    }

    modifier isStartTime() {
        require(block.timestamp >= STAKING_START_TIME, "UnoRe: not available time");
        _;
    }

    function setExchangeAgent(address _exchangeAgent) external onlyOwner {
        require(_exchangeAgent != address(0), "UnoRe: zero address");
        exchangeAgent = _exchangeAgent;
        emit LogSetExchangeAgent(_exchangeAgent);
    }

    function setCapitalAgent(address _capitalAgent) external onlyOwner {
        require(_capitalAgent != address(0), "UnoRe: zero address");
        capitalAgent = _capitalAgent;
        emit LogSetCapitalAgent(address(this), _capitalAgent);
    }

    function setRewardMultiplier(uint256 _rewardMultiplier) external onlyOwner {
        require(_rewardMultiplier > 0, "UnoRe: zero value");
        poolInfo.unoMultiplierPerBlock = _rewardMultiplier;
        emit LogSetRewardMultiplier(address(this), _rewardMultiplier);
    }

    function setClaimAssessor(address _claimAssessor) external onlyOwner {
        require(_claimAssessor != address(0), "UnoRe: zero address");
        claimAssessor = _claimAssessor;
        emit LogSetClaimAssessor(address(this), _claimAssessor);
    }

    function setMigrateTo(address _migrateTo) external onlyOwner {
        require(_migrateTo != address(0), "UnoRe: zero address");
        migrateTo = _migrateTo;
        emit LogSetMigrateTo(address(this), _migrateTo);
    }

    function setMinLPCapital(uint256 _minLPCapital) external onlyOwner {
        require(_minLPCapital > 0, "UnoRe: not allow zero value");
        IRiskPool(riskPool).setMinLPCapital(_minLPCapital);
        emit LogSetMinLPCapital(address(this), _minLPCapital);
    }

    function setLockTime(uint256 _lockTime) external onlyOwner {
        require(_lockTime > 0, "UnoRe: not allow zero lock time");
        LOCK_TIME = _lockTime;
        emit LogSetLockTime(address(this), _lockTime);
    }

    function setStakingStartTime(uint256 _startTime) external onlyOwner {
        STAKING_START_TIME = _startTime + block.timestamp;
        emit LogSetStakingStartTime(address(this), STAKING_START_TIME);
    }

    /**
     * @dev create Risk pool with UNO from SSIP owner
     */
    function createRiskPool(
        string calldata _name,
        string calldata _symbol,
        address _factory,
        address _currency,
        uint256 _rewardMultiplier,
        uint256 _SCR
    ) external onlyOwner nonReentrant {
        require(riskPool == address(0), "UnoRe: risk pool created already");
        require(_factory != address(0), "UnoRe: zero factory address");
        riskPool = IRiskPoolFactory(_factory).newRiskPool(_name, _symbol, address(this), _currency);
        poolInfo.lastRewardBlock = uint128(block.number);
        poolInfo.accUnoPerShare = 0;
        poolInfo.unoMultiplierPerBlock = _rewardMultiplier;
        ICapitalAgent(capitalAgent).addPool(address(this), _currency, _SCR);
        emit RiskPoolCreated(address(this), riskPool);
    }

    function createRewarder(
        address _operator,
        address _factory,
        address _currency
    ) external onlyOwner nonReentrant {
        require(_factory != address(0), "UnoRe: rewarder factory no exist");
        require(_operator != address(0), "UnoRe: zero operator address");
        rewarder = IRewarderFactory(_factory).newRewarder(_operator, _currency, address(this));
        emit LogCreateRewarder(address(this), rewarder, _currency);
    }

    function createSyntheticSSIP(address _multiSigWallet, address _factory) external onlyOwner nonReentrant {
        require(_multiSigWallet != address(0), "UnoRe: zero owner address");
        require(_factory != address(0), "UnoRe:zero factory address");
        require(riskPool != address(0), "UnoRe:zero LP token address");
        syntheticSSIP = ISyntheticSSIPFactory(_factory).newSyntheticSSIP(_multiSigWallet, riskPool);
        emit LogCreateSyntheticSSIP(address(this), syntheticSSIP, riskPool);
    }

    function migrate() external nonReentrant {
        require(migrateTo != address(0), "UnoRe: zero address");
        _harvest(msg.sender);
        uint256 lpPrice = IRiskPool(riskPool).lpPriceUno();
        uint256 amount = userInfo[msg.sender].amount;
        bool isUnLocked = block.timestamp - userInfo[msg.sender].lastWithdrawTime > LOCK_TIME;
        uint256 migratedAmount = IRiskPool(riskPool).migrateLP(msg.sender, migrateTo, isUnLocked);
        ICapitalAgent(capitalAgent).SSIPPolicyCaim((amount * lpPrice) / 1e18);
        IMigration(migrateTo).onMigration(msg.sender, amount, "");
        userInfo[msg.sender].amount = 0;
        userInfo[msg.sender].rewardDebt = 0;
        emit LogMigrate(msg.sender, migrateTo, migratedAmount);
    }

    function pendingUno(address _to) external view returns (uint256 pending) {
        uint256 tokenSupply = IERC20(riskPool).totalSupply();
        uint128 accUnoPerShare = poolInfo.accUnoPerShare;
        if (block.number > poolInfo.lastRewardBlock && tokenSupply != 0) {
            uint256 blocks = block.number - uint256(poolInfo.lastRewardBlock);
            uint256 unoReward = blocks * poolInfo.unoMultiplierPerBlock;
            accUnoPerShare = accUnoPerShare + uint128((unoReward * ACC_UNO_PRECISION) / tokenSupply);
        }
        uint256 userBalance = userInfo[_to].amount;
        pending = (userBalance * uint256(accUnoPerShare)) / ACC_UNO_PRECISION - userInfo[_to].rewardDebt;
    }

    function updatePool() public override {
        if (block.number > poolInfo.lastRewardBlock) {
            uint256 tokenSupply = IERC20(riskPool).totalSupply();
            if (tokenSupply > 0) {
                uint256 blocks = block.number - uint256(poolInfo.lastRewardBlock);
                uint256 unoReward = blocks * poolInfo.unoMultiplierPerBlock;
                poolInfo.accUnoPerShare = poolInfo.accUnoPerShare + uint128(((unoReward * ACC_UNO_PRECISION) / tokenSupply));
            }
            poolInfo.lastRewardBlock = uint128(block.number);
            emit LogUpdatePool(poolInfo.lastRewardBlock, tokenSupply, poolInfo.accUnoPerShare);
        }
    }

    function enterInPool(uint256 _amount) external payable override isStartTime nonReentrant {
        require(_amount != 0, "UnoRe: ZERO Value");
        updatePool();
        address token = IRiskPool(riskPool).currency();
        uint256 lpPriceUno = IRiskPool(riskPool).lpPriceUno();
        if (token == address(0)) {
            require(msg.value >= _amount, "UnoRe: insufficient paid");
            if (msg.value > _amount) {
                TransferHelper.safeTransferETH(msg.sender, msg.value - _amount);
            }
            TransferHelper.safeTransferETH(riskPool, _amount);
        } else {
            TransferHelper.safeTransferFrom(token, msg.sender, riskPool, _amount);
        }
        IRiskPool(riskPool).enter(msg.sender, _amount);
        userInfo[msg.sender].rewardDebt =
            userInfo[msg.sender].rewardDebt +
            ((_amount * 1e18 * uint256(poolInfo.accUnoPerShare)) / lpPriceUno) /
            ACC_UNO_PRECISION;
        userInfo[msg.sender].amount = userInfo[msg.sender].amount + ((_amount * 1e18) / lpPriceUno);
        ICapitalAgent(capitalAgent).SSIPStaking(_amount);
        emit StakedInPool(msg.sender, riskPool, _amount);
    }

    /**
     * @dev WR will be in pending for 10 days at least
     */
    function leaveFromPoolInPending(uint256 _amount) external override isStartTime nonReentrant {
        _harvest(msg.sender);
        require(ICapitalAgent(capitalAgent).checkCapitalByMCR(address(this), _amount), "UnoRe: minimum capital underflow");
        // Withdraw desired amount from pool
        uint256 amount = userInfo[msg.sender].amount;
        uint256 lpPriceUno = IRiskPool(riskPool).lpPriceUno();
        (uint256 pendingAmount, , ) = IRiskPool(riskPool).getWithdrawRequest(msg.sender);
        require(((amount - pendingAmount) * lpPriceUno) / 1e18 >= _amount, "UnoRe: withdraw amount overflow");
        IRiskPool(riskPool).leaveFromPoolInPending(msg.sender, _amount);

        userInfo[msg.sender].lastWithdrawTime = block.timestamp;
        emit LeftPool(msg.sender, riskPool, _amount);
    }

    /**
     * @dev user can submit claim again and receive his funds into his wallet after 10 days since last WR.
     */
    function leaveFromPending() external override isStartTime nonReentrant {
        require(block.timestamp - userInfo[msg.sender].lastWithdrawTime >= LOCK_TIME, "UnoRe: Locked time");
        _harvest(msg.sender);
        uint256 amount = userInfo[msg.sender].amount;
        (uint256 pendingAmount, , uint256 pendingAmountInUNO) = IRiskPool(riskPool).getWithdrawRequest(msg.sender);
        ICapitalAgent(capitalAgent).SSIPWithdraw(pendingAmountInUNO);

        uint256 accumulatedUno = (amount * uint256(poolInfo.accUnoPerShare)) / ACC_UNO_PRECISION;
        userInfo[msg.sender].rewardDebt =
            accumulatedUno -
            ((pendingAmount * uint256(poolInfo.accUnoPerShare)) / ACC_UNO_PRECISION);
        (uint256 withdrawAmount, uint256 withdrawAmountInUNO) = IRiskPool(riskPool).leaveFromPending(msg.sender);
        userInfo[msg.sender].amount = amount - withdrawAmount;
        emit LogLeaveFromPendingSSIP(msg.sender, riskPool, withdrawAmount, withdrawAmountInUNO);
    }

    function lpTransfer(
        address _from,
        address _to,
        uint256 _amount
    ) external override nonReentrant {
        require(msg.sender == address(riskPool), "UnoRe: not allow others transfer");
        if (_from != syntheticSSIP && _to != syntheticSSIP) {
            _harvest(_from);
            uint256 amount = userInfo[_from].amount;
            (uint256 pendingAmount, , ) = IRiskPool(riskPool).getWithdrawRequest(_from);
            require(amount - pendingAmount >= _amount, "UnoRe: balance overflow");
            uint256 accumulatedUno = (amount * uint256(poolInfo.accUnoPerShare)) / ACC_UNO_PRECISION;
            userInfo[_from].rewardDebt = accumulatedUno - ((_amount * uint256(poolInfo.accUnoPerShare)) / ACC_UNO_PRECISION);
            userInfo[_from].amount = amount - _amount;

            userInfo[_to].rewardDebt =
                userInfo[_to].rewardDebt +
                ((_amount * uint256(poolInfo.accUnoPerShare)) / ACC_UNO_PRECISION);
            userInfo[_to].amount = userInfo[_to].amount + _amount;

            emit LogLpTransferInSSIP(_from, _to, _amount);
        }
    }

    function harvest(address _to) external override isStartTime nonReentrant {
        _harvest(_to);
    }

    function _harvest(address _to) private {
        updatePool();
        uint256 amount = userInfo[_to].amount;
        uint256 accumulatedUno = (amount * uint256(poolInfo.accUnoPerShare)) / ACC_UNO_PRECISION;
        uint256 _pendingUno = accumulatedUno - userInfo[_to].rewardDebt;

        // Effects
        userInfo[msg.sender].rewardDebt = accumulatedUno;
        uint256 rewardAmount = 0;

        if (rewarder != address(0) && _pendingUno != 0) {
            rewardAmount = IRewarder(rewarder).onReward(_to, _pendingUno);
        }

        emit Harvest(msg.sender, _to, rewardAmount);
    }

    function cancelWithdrawRequest() external nonReentrant {
        (uint256 cancelAmount, uint256 cancelAmountInUno) = IRiskPool(riskPool).cancelWithrawRequest(msg.sender);
        emit LogCancelWithdrawRequest(msg.sender, cancelAmount, cancelAmountInUno);
    }

    function policyClaim(address _to, uint256 _amount) external onlyClaimAssessor isStartTime nonReentrant {
        require(_to != address(0), "UnoRe: zero address");
        require(_amount > 0, "UnoRe: zero amount");
        uint256 realClaimAmount = IRiskPool(riskPool).policyClaim(_to, _amount);
        ICapitalAgent(capitalAgent).SSIPPolicyCaim(realClaimAmount);
        emit PolicyClaim(_to, realClaimAmount);
    }

    function getStakedAmountPerUser(address _to) external view returns (uint256 unoAmount, uint256 lpAmount) {
        lpAmount = userInfo[_to].amount;
        uint256 lpPriceUno = IRiskPool(riskPool).lpPriceUno();
        unoAmount = (lpAmount * lpPriceUno) / 1e18;
    }

    /**
     * @dev get withdraw request amount in pending per user in UNO
     */
    function getWithdrawRequestPerUser(address _user)
        external
        view
        returns (
            uint256 pendingAmount,
            uint256 pendingAmountInUno,
            uint256 originUnoAmount,
            uint256 requestTime
        )
    {
        uint256 lpPriceUno = IRiskPool(riskPool).lpPriceUno();
        (pendingAmount, requestTime, originUnoAmount) = IRiskPool(riskPool).getWithdrawRequest(_user);
        pendingAmountInUno = (pendingAmount * lpPriceUno) / 1e18;
    }

    /**
     * @dev get total withdraw request amount in pending for the risk pool in UNO
     */
    function getTotalWithdrawPendingAmount() external view returns (uint256) {
        return IRiskPool(riskPool).getTotalWithdrawRequestAmount();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

interface ICapitalAgent {
    function addPool(
        address _ssip,
        address _currency,
        uint256 _scr
    ) external;

    function setPolicy(address _policy) external;

    function SSIPWithdraw(uint256 _withdrawAmount) external;

    function SSIPStaking(uint256 _stakingAmount) external;

    function SSIPPolicyCaim(uint256 _withdrawAmount) external;

    function checkCapitalByMCR(address _pool, uint256 _withdrawAmount) external view returns (bool);

    function checkCoverageByMLR(uint256 _coverageAmount) external view returns (bool);

    function policySale(uint256 _coverageAmount) external;

    function updatePolicyStatus(uint256 _policyId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

interface IExchangeAgent {
    function USDC_TOKEN() external view returns (address);

    function getTokenAmountForUSDC(address _token, uint256 _usdtAmount) external view returns (uint256);

    function getETHAmountForUSDC(uint256 _usdtAmount) external view returns (uint256);

    function getETHAmountForToken(address _token, uint256 _tokenAmount) external view returns (uint256);

    function getTokenAmountForETH(address _token, uint256 _ethAmount) external view returns (uint256);

    function getNeededTokenAmount(
        address _token0,
        address _token1,
        uint256 _token0Amount
    ) external view returns (uint256);

    function convertForToken(
        address _token0,
        address _token1,
        uint256 _token0Amount
    ) external returns (uint256);

    function convertForETH(address _token, uint256 _convertAmount) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

interface IMigration {
    function onMigration(
        address who_,
        uint256 amount_,
        bytes memory data_
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

interface IRewarder {
    function currency() external view returns (address);

    function onReward(address to, uint256 unoAmount) external payable returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.0;

interface IRewarderFactory {
    function newRewarder(
        address _operator,
        address _currency,
        address _pool
    ) external returns (address);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.0;

interface IRiskPool {
    function enter(address _from, uint256 _amount) external;

    function leaveFromPoolInPending(address _to, uint256 _amount) external;

    function leaveFromPending(address _to) external returns (uint256, uint256);

    function cancelWithrawRequest(address _to) external returns (uint256, uint256);

    function policyClaim(address _to, uint256 _amount) external returns (uint256 realClaimAmount);

    function migrateLP(
        address _to,
        address _migrateTo,
        bool _isUnLocked
    ) external returns (uint256);

    function setMinLPCapital(uint256 _minLPCapital) external;

    function currency() external view returns (address);

    function getTotalWithdrawRequestAmount() external view returns (uint256);

    function getWithdrawRequest(address _to)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    function lpPriceUno() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.0;

interface IRiskPoolFactory {
    function newRiskPool(
        string calldata _name,
        string calldata _symbol,
        address _pool,
        address _currency
    ) external returns (address);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.0;

interface ISingleSidedInsurancePool {
    function updatePool() external;

    function enterInPool(uint256 _amount) external payable;

    function leaveFromPoolInPending(uint256 _amount) external;

    function leaveFromPending() external;

    function harvest(address _to) external;

    function lpTransfer(
        address _from,
        address _to,
        uint256 _amount
    ) external;

    function riskPool() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.0;

interface ISyntheticSSIPFactory {
    function newSyntheticSSIP(address _multiSigWallet, address _lpToken) external returns (address);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.0;

// from Uniswap TransferHelper library
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper::safeApprove: approve failed");
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper::safeTransfer: transfer failed");
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper::transferFrom: transferFrom failed");
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "TransferHelper::safeTransferETH: ETH transfer failed");
    }
}