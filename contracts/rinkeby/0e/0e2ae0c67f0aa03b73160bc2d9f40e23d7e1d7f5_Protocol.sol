// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Strategy.sol";

contract Protocol is Ownable {
    mapping(uint256 => uint256) public lastRun; // strategy id => last run block
    IStrategy[] public approvedStrategy;
    uint256[] public reward;
    mapping(uint256 => bool) public unapproved;
    mapping(uint256 => mapping(address => uint256)) public shares;
    mapping(uint256 => uint256) public totalShares;
    mapping(address => mapping(uint256 => uint256)) public stopLoss;
    // stopLossReward can be considered as the fee to execute the stoploss
    // the currency is the reward token
    mapping(address => mapping(uint256 => uint256)) public stopLossReward;
    mapping(uint256 => uint256) public initValuePerShare;
    event SetStopLoss(address indexed user, uint256 indexed strategyId);
    event ExecStopLoss(address indexed user, uint256 indexed strategyId);
    IERC20 public rewardToken;

    constructor(IERC20 rewardToken_) {
        rewardToken = rewardToken_;
    }

    function approve(IStrategy strategy, uint256 rewardPergas)
        external
        onlyOwner
    {
        uint256 id = approvedStrategy.length;
        approvedStrategy.push(strategy);
        reward.push(rewardPergas);
        strategy.init(id);
    }

    function unapprove(uint256 strategyId) external onlyOwner {
        unapproved[strategyId] = true;
    }

    function deposit(uint256 strategyId, uint256 amount) external {
        require(!unapproved[strategyId], "Unapproved strategy");
        uint256 share = approvedStrategy[strategyId].handleDeposit(
            msg.sender,
            amount
        );
        shares[strategyId][msg.sender] += share;
        totalShares[strategyId] += share;
        if (initValuePerShare[strategyId] == 0)
            initValuePerShare[strategyId] = valuePerShare(strategyId);
    }

    function withdraw(uint256 strategyId, uint256 amount) external {
        require(!unapproved[strategyId], "Unapproved strategy");
        uint256 share = approvedStrategy[strategyId].handleWithdraw(
            msg.sender,
            amount
        );
        shares[strategyId][msg.sender] -= share;
        totalShares[strategyId] -= share;
    }

    function valuePerShare(uint256 strategyId) public returns (uint256) {
        return
            totalShares[strategyId] == 0
                ? 0
                : approvedStrategy[strategyId].totalValue() /
                    totalShares[strategyId];
    }

    function run(uint256 strategyId) external returns (uint256 tokenReward) {
        require(
            lastRun[strategyId] < block.number,
            "Already run in this block"
        );
        uint256 preGas = gasleft();

        lastRun[strategyId] = block.number;
        approvedStrategy[strategyId].run(msg.sender);

        tokenReward = (preGas - gasleft()) * reward[strategyId];
        rewardToken.transfer(msg.sender, tokenReward);
    }

    function setReward(uint256 strategyId, uint256 rewardPerGas)
        external
        onlyOwner
    {
        reward[strategyId] = rewardPerGas;
    }

    function setStopLoss(
        uint256 strategyId,
        uint256 stopLoss_,
        uint256 reward_
    ) external {
        uint256 prevStopLoss = stopLossReward[msg.sender][strategyId];
        stopLoss[msg.sender][strategyId] = stopLoss_;
        stopLossReward[msg.sender][strategyId] = reward_;

        if (prevStopLoss >= reward_) rewardToken.transfer(msg.sender, prevStopLoss - reward_);
        else rewardToken.transferFrom(msg.sender, address(this), reward_ - prevStopLoss);

        emit SetStopLoss(msg.sender, strategyId);
    }

    function executeStopLoss(address target, uint256 strategyId) external {
        require(approvedStrategy[strategyId].value(target) <= stopLoss[target][strategyId]);
        uint256 share = approvedStrategy[strategyId].handleWithdraw(
            target,
            approvedStrategy[strategyId].value(target)
        );
        shares[strategyId][target] -= share;
        totalShares[strategyId] -= share;
        // although the remaining share should be 0, not checking here
        // since it might have some share unable to withdraw

        uint256 fee = stopLossReward[target][strategyId];
        stopLossReward[target][strategyId] = 0;
        rewardToken.transfer(msg.sender, fee);

        emit ExecStopLoss(msg.sender, strategyId);
    }
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IStrategy {
    // return the information link of this strategy
    function strategyURI() external returns (string memory);

    // return the address of the investing token
    function currency() external returns (address);

    // return if an address is allowed to invest
    // return 1 for address(0x0) if it's open to all
    function allowed(address) external returns (bool);

    // should check if msg.sender is the pool
    function init(uint256 strategyId) external;

    // return total value of the strategy
    function totalValue() external returns (uint256);

    function run(address sender) external;

    function handleDeposit(
        address depositor,
        uint256 amount // of currency
    ) external returns (uint256);

    function handleWithdraw(
        address withdrawer,
        uint256 amount // of currency
    ) external returns (uint256);

    function invested(address investor) external view returns (uint256);

    function value(address investor) external view returns (uint256);
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