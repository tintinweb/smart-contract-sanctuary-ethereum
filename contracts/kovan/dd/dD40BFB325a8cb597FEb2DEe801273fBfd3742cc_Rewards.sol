// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IDAOStaking.sol";

contract Rewards is Ownable {
    uint256 constant decimals = 10 ** 18;

    struct Pull {
        address source;
        uint256 startTs;
        uint256 endTs;
        uint256 totalDuration;
        uint256 totalAmount;
    }

    Pull public pullFeature;
    bool public disabled;
    uint256 public lastPullTs;

    uint256 public balanceBefore;
    uint256 public currentMultiplier;

    mapping(address => uint256) public userMultiplier;
    mapping(address => uint256) public owed;

    IDAOStaking public daoStaking;
    IERC20 public rewardToken;

    event Claim(address indexed user, uint256 amount);

    constructor(address _owner, address _token, address _daoStaking) {
        require(_token != address(0), "reward token must not be 0x0");
        require(_daoStaking != address(0), "daoStaking address must not be 0x0");

        transferOwnership(_owner);

        rewardToken = IERC20(_token);
        daoStaking = IDAOStaking(_daoStaking);
    }

    // registerUserAction is called by the DAOStaking every time the user does a deposit or withdrawal in order to
    // account for the changes in reward that the user should get
    // it updates the amount owed to the user without transferring the funds
    function registerUserAction(address user) public {
        require(msg.sender == address(daoStaking), 'only callable by daoStaking');

        _calculateOwed(user);
    }

    // claim calculates the currently owed reward and transfers the funds to the user
    function claim() public returns (uint256){
        _calculateOwed(msg.sender);

        uint256 amount = owed[msg.sender];
        require(amount > 0, "nothing to claim");

        owed[msg.sender] = 0;

        rewardToken.transfer(msg.sender, amount);

        // acknowledge the amount that was transferred to the user
        ackFunds();

        emit Claim(msg.sender, amount);

        return amount;
    }

    // ackFunds checks the difference between the last known balance of `token` and the current one
    // if it goes up, the multiplier is re-calculated
    // if it goes down, it only updates the known balance
    function ackFunds() public {
        uint256 balanceNow = rewardToken.balanceOf(address(this));

        if (balanceNow == 0 || balanceNow <= balanceBefore) {
            balanceBefore = balanceNow;
            return;
        }

        uint256 totalStakedGovToken = daoStaking.govTokenStaked();
        // if there's no governance token staked, it doesn't make sense to ackFunds because there's nobody to distribute them to
        // and the calculation would fail anyways due to division by 0
        if (totalStakedGovToken == 0) {
            return;
        }

        uint256 diff = balanceNow - balanceBefore;
        uint256 multiplier = currentMultiplier + diff * decimals / totalStakedGovToken;

        balanceBefore = balanceNow;
        currentMultiplier = multiplier;
    }

    // setupPullToken is used to setup the rewards system; only callable by contract owner
    // set source to address(0) to disable the functionality
    function setupPullToken(address source, uint256 startTs, uint256 endTs, uint256 amount) public {
        require(msg.sender == owner(), "!owner");
        require(!disabled, "contract is disabled");

        if (pullFeature.source != address(0)) {
            require(source == address(0), "contract is already set up, source must be 0x0");
            disabled = true;
        } else {
            require(source != address(0), "contract is not setup, source must be != 0x0");
        }

        if (source == address(0)) {
            require(startTs == 0, "disable contract: startTs must be 0");
            require(endTs == 0, "disable contract: endTs must be 0");
            require(amount == 0, "disable contract: amount must be 0");
        } else {
            require(endTs > startTs, "setup contract: endTs must be greater than startTs");
            require(amount > 0, "setup contract: amount must be greater than 0");
        }

        pullFeature.source = source;
        pullFeature.startTs = startTs;
        pullFeature.endTs = endTs;
        pullFeature.totalDuration = endTs - startTs;
        pullFeature.totalAmount = amount;

        if (lastPullTs < startTs) {
            lastPullTs = startTs;
        }
    }

    // setDAOStaking sets the address of the DAO Staking contract into the state variable
    function setDAOStaking(address _daoStaking) public {
        require(_daoStaking != address(0), 'daoStaking address must not be 0x0');
        require(msg.sender == owner(), '!owner');

        daoStaking = IDAOStaking(_daoStaking);
    }

    // _pullToken calculates the amount based on the time passed since the last pull relative
    // to the total amount of time that the pull functionality is active and executes a transferFrom from the
    // address supplied as `pullTokenFrom`, if enabled
    function _pullToken() internal {
        if (
            pullFeature.source == address(0) ||
            block.timestamp < pullFeature.startTs
        ) {
            return;
        }

        uint256 timestampCap = pullFeature.endTs;
        if (block.timestamp < pullFeature.endTs) {
            timestampCap = block.timestamp;
        }

        if (lastPullTs >= timestampCap) {
            return;
        }

        uint256 timeSinceLastPull = timestampCap - lastPullTs;
        uint256 shareToPull = timeSinceLastPull * decimals / pullFeature.totalDuration;
        uint256 amountToPull = pullFeature.totalAmount * shareToPull / decimals;

        lastPullTs = block.timestamp;
        rewardToken.transferFrom(pullFeature.source, address(this), amountToPull);
    }

    // _calculateOwed calculates and updates the total amount that is owed to an user and updates the user's multiplier
    // to the current value
    // it automatically attempts to pull the token from the source and acknowledge the funds
    function _calculateOwed(address user) internal {
        _pullToken();
        ackFunds();

        uint256 reward = _userPendingReward(user);

        owed[user] = owed[user] + reward;
        userMultiplier[user] = currentMultiplier;
    }

    // _userPendingReward calculates the reward that should be based on the current multiplier / anything that's not included in the `owed[user]` value
    // it does not represent the entire reward that's due to the user unless added on top of `owed[user]`
    function _userPendingReward(address user) internal view returns (uint256) {
        uint256 multiplier = currentMultiplier - userMultiplier[user];

        return daoStaking.balanceOf(user) * multiplier / decimals;
    }
}

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

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.10;

import "../libraries/LibStakingStorage.sol";

interface IDAOStaking {
    // deposit allows a user to add more governance token to his staked balance
    function deposit(uint256 amount) external;

    // withdraw allows a user to withdraw funds if the balance is not locked
    function withdraw(uint256 amount) external;

    // lock a user's currently staked balance until timestamp & add the bonus to his voting power
    function lock(uint256 timestamp) external;

    // delegate allows a user to delegate his voting power to another user
    function delegate(address to) external;

    // stopDelegate allows a user to take back the delegated voting power
    function stopDelegate() external;

    // lock the balance of a proposal creator until the voting ends; only callable by DAO
    function lockCreatorBalance(address user, uint256 timestamp) external;

    // balanceOf returns the current governance token balance of a user (bonus not included)
    function balanceOf(address user) external view returns (uint256);

    // balanceAtTs returns the amount of governance token that the user currently staked (bonus NOT included)
    function balanceAtTs(address user, uint256 timestamp) external view returns (uint256);

    // stakeAtTs returns the Stake object of the user that was valid at `timestamp`
    function stakeAtTs(address user, uint256 timestamp) external view returns (LibStakingStorage.Stake memory);

    // votingPower returns the voting power (bonus included) + delegated voting power for a user at the current block
    function votingPower(address user) external view returns (uint256);

    // votingPowerAtTs returns the voting power (bonus included) + delegated voting power for a user at a point in time
    function votingPowerAtTs(address user, uint256 timestamp) external view returns (uint256);

    // govTokenStaked returns the total raw amount of governance token staked at the current block
    function govTokenStaked() external view returns (uint256);

    // govTokenStakedAtTs returns the total raw amount of governance token users have deposited into the contract
    // it does not include any bonus
    function govTokenStakedAtTs(uint256 timestamp) external view returns (uint256);

    // delegatedPower returns the total voting power that a user received from other users
    function delegatedPower(address user) external view returns (uint256);

    // delegatedPowerAtTs returns the total voting power that a user received from other users at a point in time
    function delegatedPowerAtTs(address user, uint256 timestamp) external view returns (uint256);

    // multiplierAtTs calculates the multiplier at a given timestamp based on the user's stake a the given timestamp
    // it includes the decay mechanism
    function multiplierAtTs(address user, uint256 timestamp) external view returns (uint256);

    // userLockedUntil returns the timestamp until the user's balance is locked
    function userLockedUntil(address user) external view returns (uint256);

    // userDidDelegate returns the address to which a user delegated their voting power; address(0) if not delegated
    function userDelegatedTo(address user) external view returns (address);
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

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IRewards.sol";

library LibStakingStorage {
    bytes32 constant STORAGE_POSITION = keccak256("com.dao.staking.storage");

    struct Checkpoint {
        uint256 timestamp;
        uint256 amount;
    }

    struct Stake {
        uint256 timestamp;
        uint256 amount;
        uint256 expiryTimestamp;
        address delegatedTo;
    }

    struct Storage {
        bool initialized;

        // mapping of user address to history of Stake objects
        // every user action creates a new object in the history
        mapping(address => Stake[]) userStakeHistory;

        // array of governance tokens staked Checkpoint
        // deposits/withdrawals create a new object in the history (max one per block)
        Checkpoint[] govTokenStakedHistory;

        // mapping of user address to history of delegated power
        // every delegate/stopDelegate call create a new checkpoint (max one per block)
        mapping(address => Checkpoint[]) delegatedPowerHistory;

        IERC20 govToken;
        IRewards rewards;
    }

    function getPointer() internal pure returns (Storage storage ds) {
        bytes32 position = STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.10;

interface IRewards {
    function registerUserAction(address user) external;
}