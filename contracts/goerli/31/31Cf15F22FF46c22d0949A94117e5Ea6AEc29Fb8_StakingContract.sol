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

pragma solidity ^0.8.4;

interface IICHOR {
    function name() external returns (string memory);

    function symbol() external returns (string memory);

    function decimals() external returns (uint8);

    function totalSupply() external returns (uint256);

    function balanceOf(address account) external returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function setCooldownEnabled(bool onoff) external;

    function setSwapEnabled(bool onoff) external;

    function openTrading() external;

    function setBots(address[] memory bots_) external;

    function setMaxBuyAmount(uint256 maxBuy) external;

    function setMaxSellAmount(uint256 maxSell) external;

    function setMaxWalletAmount(uint256 maxToken) external;

    function setSwapTokensAtAmount(uint256 newAmount) external;

    function setProjectWallet(address projectWallet) external;

    function setCharityAddress(address charityAddress) external;

    function getCharityAddress() external view returns (address charityAddress);

    function excludeFromFee(address account) external;

    function includeInFee(address account) external;

    function setBuyFee(uint256 buyProjectFee) external;

    function setSellFee(uint256 sellProjectFee) external;

    function setBlocksToBlacklist(uint256 blocks) external;

    function delBot(address notbot) external;

    function manualswap() external;

    function withdrawStuckETH() external;
}

pragma solidity ^0.8.4;

interface ISacrificeToken {
    function setStakingAddress(address stakingAddress_) external;

    function getStakingAddress(
        address stakingAddress_
    ) external view returns (address);

    function mint(address to, uint256 amount) external;

    function burn(address from, uint256 amount) external;

    function balanceOf(address user) external view returns (uint256);

    function totalSupply() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IICHOR.sol";
import "./interfaces/ISacrificeToken.sol";


contract StakingContract is Ownable {

    /// @notice Time reward distribution ends
    uint256 public finishAt;

    /// @notice Last time reward was updated
    uint256 public updatedAt;

    /// @notice Reward amount
    uint256 public rewardAmount;

    /// @notice Reward per token stored
    uint256 public rewardPerTokenStored;

    /// @notice Staking period
    uint256 public stakingPeriod;

    /// @notice Mapping (address => uint256). Contains reward per token paid for user
    mapping(address => uint256) public userRewardPerTokenPaid;

    /// @notice Mapping (address => uint256). Contains rewards for user
    mapping(address => uint256) public rewards;

    /// @notice Denominator
    uint256 private denominator = 100;

    /// @notice ICHOR token instance
    IICHOR private ichorToken;

    /// @notice Sacrifice token instance
    ISacrificeToken private sacrificeToken;

    /// @notice Mapping (address => bool). Shows if address has staked tokens
    mapping(address => bool) public isStaked;

    /// @notice Mapping (address => uint256). Shows time when stake ends for user
    mapping(address => uint256) public timeStakeEnds;

    /// @param stakingPeriod_ Staking period
    constructor(uint256 stakingPeriod_) {
        stakingPeriod = stakingPeriod_;
    }

    /// @notice Updates reward for user
    /// @param _account User address
    modifier updateReward(address _account) {
        rewardPerTokenStored = rewardPerToken();
        updatedAt = lastTimeRewardApplicable();

        if (_account != address(0)) {
            rewards[_account] = earned(_account);
            userRewardPerTokenPaid[_account] = rewardPerTokenStored;
        }

        _;
    }

    /// @notice Checks if caller is a trusted address (ICHOR or This).
    modifier onlyTrusted() {
        require(
            msg.sender == address(ichorToken) || msg.sender == address(this),
            "StakingContract: caller is not THIS or ICHOR token!"
        );
        _;
    }

    /// @notice Checks if staking period ended for user
    /// @param _account  User address
    modifier stakePeriodEnded(address _account) {
        require(
            block.timestamp >= timeStakeEnds[_account],
            "StakingContract: period not ended!"
        );
        _;
    }

    /// @notice Sets new ICHOR token address
    /// @param ichorToken_ New ICHOR token address
    /// @dev This method can be called only by an Owner of the contract
    function setIchorAddress(address ichorToken_) external onlyOwner {
        ichorToken = IICHOR(ichorToken_);
    }

    /// @notice Returns current ICHOR token address
    /// @return address Current ICHOR token address
    function getIchorAddress() external view returns (address) {
        return address(ichorToken);
    }

    /// @notice Sets new Sacrifice token address
    /// @param sacrificeToken_ New Sacrifice token address
    /// @dev This method can be called only by an Owner of the contract
    function setSacrificeToken(address sacrificeToken_) external onlyOwner {
        sacrificeToken = ISacrificeToken(sacrificeToken_);
    }

    /// @notice Returns current Sacrifice token address
    /// @return address Current Sacrifice token address
    function getSacrificeToken() external view returns (address) {
        return address(sacrificeToken);
    }

    /// @notice Returns user's amount of staked tokens
    /// @param user Address of user
    /// @return amount User's amount of staked tokens
    function getStakedAmount(address user) external view returns (uint256) {
        return sacrificeToken.balanceOf(user);
    }

    /// @notice Returns time when minimum stake period ends for user
    /// @param user Address of user
    /// @return time Time when minimum stake period ends for user
    function getTimeStakeEnds(address user) external view returns (uint256) {
        return timeStakeEnds[user];
    }

    /// @notice Returns last time reward applicable
    /// @return time Last time reward applicable
    function lastTimeRewardApplicable() public view returns (uint256) {
        return _min(finishAt, block.timestamp);
    }

    /// @notice Returns reward per token stored
    /// @return amount Reward per token stored
    function rewardPerToken() public view returns (uint256) {
        uint256 totalSupply = sacrificeToken.totalSupply();
        if (totalSupply == 0) {
            return rewardPerTokenStored;
        }

        return
            rewardPerTokenStored +
            (rewardAmount * (lastTimeRewardApplicable() - updatedAt) * 1e18) /
            totalSupply;
    }

    /// @notice Stakes ICHOR tokens from caller
    /// @param _amount Amount of ICHOR tokens to stake
    /// @dev Mints sacrifice tokens 1 to 1 on caller address 
    function stake(uint256 _amount) external updateReward(msg.sender) {
        require(
            sacrificeToken.balanceOf(msg.sender) == 0,
            "StakingContract: tokens already staked!"
        );
        require(_amount > 0, "StakingContract: amount is 0!");
        ichorToken.transferFrom(msg.sender, address(this), _amount);
        isStaked[msg.sender] = true;
        timeStakeEnds[msg.sender] = block.timestamp + stakingPeriod;
        sacrificeToken.mint(msg.sender, _amount);
    }

    /// @notice Unstakes ICHOR tokens to caller
    /// @dev Takes 15% fee if called before staking period ends
    /// @dev Burns sacrifice tokens and unstakes 1 to 1 of ICHOR tokens 
    function unstake() external updateReward(msg.sender) {
        require(
            sacrificeToken.balanceOf(msg.sender) > 0,
            "StakingContract: no tokens staked!"
        );
        uint256 amountToTransfer = rewards[msg.sender];
        uint256 amountToUnstake = sacrificeToken.balanceOf(msg.sender);

        sacrificeToken.burn(msg.sender, sacrificeToken.balanceOf(msg.sender));
        isStaked[msg.sender] = false;
        rewards[msg.sender] = 0;

        if (block.timestamp >= timeStakeEnds[msg.sender]) {
            ichorToken.transfer(msg.sender, amountToTransfer);
        } else {
            uint256 amountWithFee = amountToTransfer -
                (amountToTransfer * 15) /
                denominator;
            ichorToken.transfer(msg.sender, amountWithFee);
            this.notifyRewardAmount(amountToTransfer - amountWithFee);
        }
        ichorToken.transfer(msg.sender, amountToUnstake);
    }

    /// @notice Returns amount of earned tokens
    /// @param _account User address
    /// @return amount Amount of earned tokens
    function earned(address _account) public view returns (uint256) {
        uint256 balance = sacrificeToken.balanceOf(_account);
        return
            ((balance * (rewardPerToken() - userRewardPerTokenPaid[_account])) / 1e18) 
                + rewards[_account];
    }

    /// @notice Transfers reward to caller
    /// @dev Can be called only after staking period ends
    function getReward()
        external
        stakePeriodEnded(msg.sender)
        updateReward(msg.sender)
    {
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            ichorToken.transfer(msg.sender, reward);
        }
    }

    /// @notice Distribure rewards to stakers
    /// @param _amount Amount to distribure
    /// @dev This method can be called only by ICHOR or This
    function notifyRewardAmount(
        uint256 _amount
    ) public onlyTrusted updateReward(address(0)) {
        if (block.timestamp >= finishAt) {
            rewardAmount = _amount;
        } else {
            uint256 remainingRewards = (finishAt - block.timestamp) *
                rewardAmount;
            rewardAmount = _amount + remainingRewards;
        }

        require(rewardAmount > 0, "StakingContract: rewardAmount == 0!");
        require(
            rewardAmount <= ichorToken.balanceOf(address(this)),
            "StakingContract: rewardAmount > balance!"
        );

        finishAt = block.timestamp + 1;
        updatedAt = block.timestamp;
    }

    /// @notice Method for finding the minimum of 2 numbers
    /// @param x First number
    /// @param y Second number
    /// @return Number The smallest of 2 numbers
    function _min(uint256 x, uint256 y) private pure returns (uint256) {
        return x <= y ? x : y;
    }

    /// @notice Sets new minimal staking period
    /// @param stakingPeriod_ New minimal staking period
    /// @dev This method can be called only by an Owner of the contract
    function setMinimalStakingPeriod(
        uint256 stakingPeriod_
    ) external onlyOwner {
        stakingPeriod = stakingPeriod_;
    }
}