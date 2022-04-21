// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./interface/ICeresReward.sol";
import "./interface/ICeresStaking.sol";
import "./common/Ownable.sol";
import "./common/CeresBase.sol";

contract CeresReward is CeresBase, ICeresReward, Ownable {

    IERC20 public crs;
    uint256 public rewardSent;
    uint256 public override stakingLockTime;
    uint256 public override minStakingValue;
    uint256 public override minApplicantStakingRatio;
    address[] public appliedStakings;
    mapping(address => uint256) public lastTimeApplied;
    mapping(address => uint256) public amountApplied;
    mapping(address => StakingRewardConfig) public stakingRewardConfigs;
    uint256 public applicantCRSBonus;

    /* ---------- Events ---------- */
    event RewardAdded(uint256 amount);
    event RewardApplied(address indexed from, uint256 amount, uint256 bonus);

    constructor (address _owner, address _factory, address _crs, uint256 _bonus) Ownable(_owner) CeresBase(_factory){
        crs = IERC20(_crs);
        applicantCRSBonus = _bonus;
    }

    /* ---------- Views ---------- */
    function getAppliedStakings() external view override returns (address[] memory){
        return appliedStakings;
    }

    function getAppliedStakingsLength() external view override returns (uint256){
        return appliedStakings.length;
    }

    function getDefaultRewardDuration() public view returns (StakingRewardConfig memory) {
        return stakingRewardConfigs[address(0)];
    }

    /* ---------- Functions---------- */
    function applyReward() external override onlyStakings returns (uint256 _bonus) {

        ICeresStaking staking = ICeresStaking(msg.sender);
        require(factory.isStakingRewards(staking.token()), "CeresReward: This staking can not apply rewards now.");

        uint256 stakingValue = staking.value();
        require(stakingValue >= minStakingValue, "CeresReward: Staking value is not enough to apply reward!");

        StakingRewardConfig memory _config = stakingRewardConfigs[msg.sender];
        if (_config.amount == 0)
            _config = getDefaultRewardDuration();

        _bonus = 0;
        if (_config.amount > 0) {

            uint256 transferCRSAmount = _config.amount + applicantCRSBonus;
            require(crs.balanceOf(address(this)) >= transferCRSAmount, "CeresReward: Balance is not enough for applying reward.");
            crs.transfer(msg.sender, transferCRSAmount);
            staking.notifyReward(_config.amount, _config.duration);
            _bonus = applicantCRSBonus;

            if (lastTimeApplied[msg.sender] == 0)
                appliedStakings.push(msg.sender);

            lastTimeApplied[msg.sender] = block.timestamp;
            amountApplied[msg.sender] += _config.amount;
            emit RewardApplied(msg.sender, _config.amount, _bonus);
        }
    }


    /* ---------- Settings ---------- */
    function setStakingLockTime(uint256 _stakingLockTime) external onlyOwner {
        stakingLockTime = _stakingLockTime;
    }

    function setMinStakingValue(uint256 _minStakingValue) external onlyOwner {
        minStakingValue = _minStakingValue;
    }

    function setMinApplicantStakingRatio(uint256 _minApplicantStakingRatio) external onlyOwner {
        minApplicantStakingRatio = _minApplicantStakingRatio;
    }

    function setStakingRewardConfig(address _staking, uint256 _amount, uint256 _duration) public onlyOwner {
        require(_amount > 0, "CeresReward: Reward amount must be bigger than zero!");
        require(_duration > 0, "CeresReward: Reward duration must be bigger than zero!");

        stakingRewardConfigs[_staking].amount = _amount;
        stakingRewardConfigs[_staking].duration = _duration;
    }

    function setApplicantCRSBonus(uint256 _applicantCRSBonus) external onlyOwner {
        applicantCRSBonus = _applicantCRSBonus;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../interface/ICeresFactory.sol";

contract CeresBase {

    uint256 public constant CERES_PRECISION = 1e6;
    uint256 public constant SHARE_PRECISION = 1e18;
    
    ICeresFactory public factory;
    
    modifier onlyBank() {
        require(msg.sender == factory.getBank(), "Only Bank!");
        _;
    }
    
    modifier onlyStakings() {
        require(factory.isValidStaking(msg.sender) == true, "Only Staking!");
        _;
    }

    constructor(address _factory){
        factory = ICeresFactory(_factory);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";

abstract contract Ownable is Context {
    
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    constructor(address _owner_) {
        _setOwner(_owner_);
    }
    
    function owner() public view virtual returns (address) {
        return _owner;
    }
    
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Only Owner!");
        _;
    }
    
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

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
pragma solidity ^0.8.4;

interface ICeresFactory {
    
    struct TokenInfo {
        address tokenAddress;
        uint256 tokenType; // 1: asc, 2: crs, 3: col, 4: vol;
        address stakingAddress;
        address oracleAddress;
        bool isStakingRewards;
        bool isStakingMineable;
    }

    /* ---------- Views ---------- */
    function getBank() external view returns (address);
    function getReward() external view returns (address);
    function getTokenInfo(address token) external returns(TokenInfo memory);
    function getStaking(address token) external view returns (address);
    function getOracle(address token) external view returns (address);
    function isValidStaking(address sender) external view returns (bool);
    function volTokens(uint256 index) external view returns (address);

    function getTokens() external view returns (address[] memory);
    function getTokensLength() external view returns (uint256);
    function getVolTokensLength() external view returns (uint256);
    function getValidStakings() external view returns (address[] memory);
    function getTokenPrice(address token) external view returns(uint256);
    function isStakingRewards(address staking) external view returns (bool);
    function isStakingMineable(address staking) external view returns (bool);

    /* ---------- Functions ---------- */
    function setBank(address newAddress) external;
    function setReward(address newReward) external;
    function setCreator(address creator) external;
    function setTokenType(address token, uint256 tokenType) external;
    function setStaking(address token, address staking) external;
    function setOracle(address token, address oracle) external;
    function setIsStakingRewards(address token, bool _isStakingRewards) external;
    function setIsStakingMineable(address token, bool _isStakingMineable) external;
    function updateOracles(address[] memory tokens) external;
    function updateOracle(address token) external;
    function addStaking(address token, uint256 tokenType, address staking, address oracle, bool _isStakingRewards, bool _isStakingMineable) external;
    function removeStaking(address token, address staking) external;

    /* ---------- RRA ---------- */
    function createStaking(address token, bool ifCreateOracle) external returns (address staking, address oracle);
    function createStakingWithLiquidity(address token, uint256 tokenAmount, uint256 quoteAmount, bool ifCreateOracle) external returns (address staking, address oracle);
    function createOracle(address token) external returns (address);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ICeresReward {
    
    struct StakingRewardConfig {
        uint256 amount;
        uint256 duration;
    }

    /* ---------- Views ---------- */
    function getAppliedStakings() external view returns (address[] memory);
    function getAppliedStakingsLength() external view returns (uint256);
    function stakingLockTime() external view returns (uint256);
    function minStakingValue() external view returns (uint256);
    function minApplicantStakingRatio() external view returns (uint256);

    /* ---------- Functions ---------- */
    function applyReward() external returns (uint256);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ICeresStaking {

    struct UserLock {
        uint256 shareAmount;
        uint256 timeEnd;
    }

    /* ---------- Views ---------- */
    function token() external view returns (address);
    function totalStaking() external view returns (uint256);
    function stakingBalanceOf(address account) external view returns (uint256);
    function totalShare() external view returns (uint256);
    function shareBalanceOf(address account) external view returns (uint256);
    function unlockedShareBalanceOf(address account) external view returns (uint256);
    function unlockedStakingBalanceOf(address account) external view returns (uint256);
    function lockTime() external view returns (uint256);
    function earned(address account) external view returns (uint256);
    function rewardRate() external view returns (uint256);
    function rewardsDuration() external view returns (uint256);
    function periodFinish() external view returns (uint256);
    function yieldAPR() external view returns (uint256);
    function value() external view returns (uint256);
    function lastRewardApplicant() external view returns (address);
    function lastAppliedTimestamp() external view returns (uint256);

    /* ---------- Functions ---------- */
    function stake(uint256 amount) external;
    function withdraw(uint256 shareAmount) external;
    function claimRewardWithPercent(uint256) external;
    function reinvestReward() external;
    function applyReward() external;
    function notifyReward(uint256 amount, uint256 duration) external;
    function approveBank(uint256 amount) external;
    
}