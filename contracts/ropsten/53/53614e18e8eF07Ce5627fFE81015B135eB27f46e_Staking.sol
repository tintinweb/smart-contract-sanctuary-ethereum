//SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.0;

import "./interface/IDAO.sol";
import "./interface/IStaking.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Staking is IStaking, Ownable {

    /**
     * @dev Represents a stakeholder
     */
    struct Stakeholder {
        uint256 stake;
        uint256 lastStakeDate;
        uint256 reward;
        uint256 rewardUpdateDate;
    }

    address public override rewardToken;

    address public override stakingToken;

    uint256 public override rewardPercentage;

    uint256 public override rewardPeriod;

    uint256 public override stakeWithdrawalTimeout;

    uint256 public override totalStake;

    address public override dao;

    /**
     * @dev A mapping "stakholder address => Stakeholder"
     */
    mapping(address => Stakeholder) private stakeholders;

    modifier onlyDAO() {
        require(msg.sender == address(dao), "Caller is not the DAO");
        _;
    }

    constructor (
        address _stakingToken,
        address _rewardToken,
        uint256 _rewardPercentage,
        uint256 _rewardPeriod,
        uint256 _stakeWithdrawalTimeout,
        address _dao
    ) public Ownable() {
        setRewardPercentage(_rewardPercentage);
        setRewardPeriod(_rewardPeriod);
        stakeWithdrawalTimeout = _stakeWithdrawalTimeout;
        dao = _dao;
        stakingToken = _stakingToken;
        rewardToken = _rewardToken;
    }

    function stake(uint256 amount) external override {
        Stakeholder storage stakeholder = stakeholders[msg.sender];

        _updateReward();

        stakeholder.stake += amount;
        totalStake += amount;

        stakeholder.lastStakeDate = block.timestamp;
        require(IERC20(stakingToken).transferFrom(msg.sender, address(this), amount), "Staking token transfer failed");
    }

    function claim() external override {
        Stakeholder storage stakeholder = stakeholders[msg.sender];

        _updateReward();

        uint256 reward = stakeholder.reward;

        require(reward > 0, "No reward for the caller");

        stakeholder.reward = 0;
        require(IERC20(rewardToken).transfer(msg.sender, reward), "Reward token transfer failed");
    }

    function unstake() external override {
        Stakeholder storage stakeholder = stakeholders[msg.sender];
        uint256 stake = stakeholder.stake;

        require(stake > 0, "The caller has nothing at stake");

        uint256 lastStakeDate = stakeholder.lastStakeDate;
        require(block.timestamp - lastStakeDate >= stakeWithdrawalTimeout, "Timeout is not met");
        require(!IDAO(dao).isParticipant(msg.sender), "A proposal participant");

        _updateReward();
        stakeholder.stake = 0;
        totalStake -= stake;
        require(IERC20(stakingToken).transfer(msg.sender, stake), "Staking token transfer failed");
    }

    function setRewardPercentage(uint256 _rewardPercentage) public override onlyOwner {
        require(_rewardPercentage > 0, "Percentage can not be 0");
        require(_rewardPercentage < 100, "Percentage can not exceed 100%");
        rewardPercentage = _rewardPercentage;
    }

    function setRewardPeriod(uint256 _rewardPeriod) public override onlyOwner {
        require(_rewardPeriod > 0, "Reward period can not be zero");
        rewardPeriod = _rewardPeriod;
    }

    function setStakeWithdrawalTimeout(uint256 _stakeWithdrawalTimeout) public override onlyDAO {
        stakeWithdrawalTimeout = _stakeWithdrawalTimeout;
    }

    function getStake(address stakeholder) public override view returns (uint256) {
        return stakeholders[stakeholder].stake;
    }

    function _updateReward() internal {
        Stakeholder storage stakeholder = stakeholders[msg.sender];

        if (stakeholder.stake == 0) {
            stakeholder.rewardUpdateDate = block.timestamp;
            return;
        }

        uint256 rewardPeriods = (block.timestamp - stakeholder.rewardUpdateDate) / rewardPeriod;
        uint256 reward = stakeholder.stake * rewardPeriods * rewardPercentage / 100;
        stakeholder.reward += reward;
        stakeholder.rewardUpdateDate = block.timestamp;
    }
}

//SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.0;

import "./IStaking.sol";

interface IDAO {

    /**
     * @notice creates a new proposal
     */
    function addProposal(bytes memory data, address recipient, string memory _description) external;

    /**
     * @notice registers `msg.sender` vote
     */
    function vote(uint256 proposalId, bool votesFor) external;

    /**
     * @notice finishes the proposal with id `proposalId`
     */
    function finishProposal(uint256 proposalId) external;

    /**
     * @notice Transfers chairman grants to a `_chairman`
     */
    function changeChairman(address _chairman) external;

    /**
     * @notice Sets the minimum quorum
     */
    function setMinimumQuorum(uint256 _minimumQuorum) external;

    /**
     * @notice Sets the debating period duration
     */
    function setDebatingPeriodDuration(uint256 _debatingPeriodDuration) external;

    /**
     * @return A description of a proposal with the id `proposalId`
     */
    function description(uint256 proposalId) external view returns (string memory);

    /**
     * @return Whether a given EOA is participating in proposals
     */
    function isParticipant(address stakeholder) external view returns (bool);

    /**
     * @notice EOA responsible for proposals creation
     */
    function chairman() external view returns (address);

    /**
     * @notice The minimum amount of votes needed to consider a proposal to be successful. Quorum = (votes / staking total supply) * 100.
     */
    function minimumQuorum() external view returns (uint256);

    /**
     * @notice EOA responsible for proposals creation
     */
    function debatingPeriodDuration() external view returns (uint256);

    /**
     * @notice Staking contract
     */
    function staking() external view returns (IStaking);

    /**
     * @return true if DAO had been initialized
     */
    function isInitialized() external view returns(bool);
}

//SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.0;

interface IStaking {

    /**
     * @notice Transfers the `amount` of tokens from `msg.sender` address to the StakingContract address
     * @param amount the amount of tokens to stake
     */
    function stake(uint256 amount) external;

    /**
     * @notice Transfers the reward tokens if any to the `msg.sender` address
     */
    function claim() external;

    /**
     * @notice Transfers staked tokens if any to the `msg.sender` address
     */
    function unstake() external;

    /**
     * @notice Sets the reward percentage
     * @param _rewardPercentage is the reward percentage to be set
     */
    function setRewardPercentage(uint256 _rewardPercentage) external;

    /**
     * @notice Sets the reward period
     * @param _rewardPeriod is the reward period to be set
     */
    function setRewardPeriod(uint256 _rewardPeriod) external;

    /**
     * @notice Sets the stake withdrawal timeout
     * @param _stakeWithdrawalTimeout is the stake withdrawal timeout to be set
     */
    function setStakeWithdrawalTimeout(uint256 _stakeWithdrawalTimeout) external;

    /**
     * @notice The reward percentage
     */
    function rewardPercentage() external view returns (uint256);

    /**
     * @notice The reward period in seconds
     */
    function rewardPeriod() external view returns (uint256);

    /**
     * @notice The stake withdrawal timeout in seconds
     */
    function stakeWithdrawalTimeout() external view returns (uint256);

    /**
     * @notice Total value locked
     */
    function totalStake() external view returns (uint256);

    /**
     * @notice Returns the total amount of staked tokens for the `stakeholder`
     * @param stakeholder is the address of the stakeholder
     * @return the total amount of staked tokens for the `stakeholder`
     */
    function getStake(address stakeholder) external view returns (uint256);

    /**
     * @dev The reward token which is used to pay stakeholders
     */
    function rewardToken() external view returns (address);

    /**
     * @dev The staking token which is used by stakeholders to participate
     */
    function stakingToken() external view returns (address);

    /**
     * @dev The DAO which uses this contract to perform voting
     */
    function dao() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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