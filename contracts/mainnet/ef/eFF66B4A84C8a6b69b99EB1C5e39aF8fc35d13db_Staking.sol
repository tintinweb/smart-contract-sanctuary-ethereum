// SPDX-License-Identifier: MIT

pragma solidity >=0.8.14;

import "./interfaces/IStaking.sol";
import "./interfaces/InitializableOwnable.sol";

contract Staking is InitializableOwnable, IStaking {

    /* ========== HELPER STRUCTURES ========== */

    struct UserInfo {
        uint amount;
        uint rewardAccountedForHarvest;
        uint availableHarvest;
        uint lastHarvestTimestamp;
    }

    /* ========== CONSTANTS ========== */

    IERC20 public immutable stakingToken;

    string public name;
    string public symbol;
    uint public immutable harvestInterval;
    uint8 public immutable decimals;

    uint public constant calcDecimals = 1e14;
    uint public constant secondsInYear = 31557600;
    uint public constant aprDenominator = 10000;

    /* ========== STATE VARIABLES ========== */

    address public admin;
    bool public paused;
    bool public unstakePermitted;
    uint public aprBasisPoints;

    uint public amountStaked;
    uint public accumulatedRewardPerShare;
    uint public lastRewardTimestamp;

    mapping(address => UserInfo) public userInfo;
    mapping(address => mapping(address => uint)) public allowances;

    /* ========== CONSTRUCTOR ========== */

    constructor(
        IERC20 token_,
        string memory name_,
        string memory symbol_,
        uint aprBasisPoints_,
        uint harvestInterval_
    ) {
        initOwner(msg.sender);
        stakingToken = token_;
        name = name_;
        symbol = symbol_;
        aprBasisPoints = aprBasisPoints_;
        harvestInterval = harvestInterval_;
        lastRewardTimestamp = block.timestamp;
        decimals = IERC20Metadata(address(token_)).decimals();
    }

    /* ========== VIEWS ========== */

    function totalSupply() external view returns (uint256) {
        return amountStaked; 
    }

    function currentRewardDelta() public view returns (uint) {
        uint timeDelta = block.timestamp - lastRewardTimestamp;
        return (timeDelta * aprBasisPoints * calcDecimals) / (aprDenominator * secondsInYear);
    }

    function calculateRewardForStake(uint amount) internal view returns (uint) {
        return accumulatedRewardPerShare * amount / calcDecimals;
    }

    function balanceOf(address user_) external view returns(uint) {
        UserInfo storage user = userInfo[user_];
        uint updAccumulatedRewardPerShare = accumulatedRewardPerShare + currentRewardDelta();

        uint virtualReward = 
            updAccumulatedRewardPerShare * user.amount / calcDecimals 
            - user.rewardAccountedForHarvest;
        return user.amount + user.availableHarvest + virtualReward;
    }

    function allowance(address owner, address spender) external view returns (uint256) {
        return allowances[owner][spender];
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function approve(
        address spender, 
        uint amount
    ) external whenNotPaused virtual override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function _transfer(
        address sender_,
        address recipient_,
        uint amount
    ) internal {
        updateRewardPool();
        require(sender_ != address(0), "ERC20: transfer from the zero address");
        require(recipient_ != address(0), "ERC20: transfer to the zero address");

        UserInfo storage sender = userInfo[sender_];
        UserInfo storage recipient = userInfo[recipient_];
        require(amount <= sender.amount, "ERC20: transfer amount exceeds balance");

        sender.availableHarvest += calculateRewardForStake(sender.amount) - sender.rewardAccountedForHarvest;
        sender.amount -= amount; 
        sender.rewardAccountedForHarvest = calculateRewardForStake(sender.amount);

        recipient.availableHarvest += calculateRewardForStake(recipient.amount) - recipient.rewardAccountedForHarvest;
        recipient.amount += amount; 
        recipient.rewardAccountedForHarvest = calculateRewardForStake(recipient.amount);

        emit Transfer(sender_, recipient_, amount);
    }

    function transfer(
        address recipient, 
        uint256 amount
    ) external whenNotPaused virtual override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    } 

    function transferFrom(
        address spender,
        address recipient,
        uint256 amount
    ) external whenNotPaused virtual override returns (bool) {
        _transfer(spender, recipient, amount);
        uint256 currentAllowance = allowances[spender][msg.sender];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(spender, msg.sender, currentAllowance - amount);
        return true;
    }

    function updateRewardPool() public canUnstake {
        accumulatedRewardPerShare += currentRewardDelta();
        lastRewardTimestamp = block.timestamp;
    }

    function stake(
        uint amount, 
        address to
    ) external whenNotPaused {
        updateRewardPool();
        require(amount > 0, "Staking: Nothing to deposit");
        require(to != address(0));
        require(stakingToken.transferFrom(msg.sender, address(this), amount), "Staking: transfer failed");

        UserInfo storage user = userInfo[to];
        user.availableHarvest += calculateRewardForStake(user.amount) - user.rewardAccountedForHarvest;
        amountStaked += amount;
        user.amount += amount;
        user.rewardAccountedForHarvest = calculateRewardForStake(user.amount);
        emit Transfer(address(0), to, amount);
        emit Stake(to, amount);
    }

    function harvest(uint256 amount) external whenNotPaused {
        updateRewardPool();
        UserInfo storage user = userInfo[msg.sender];
        require(user.lastHarvestTimestamp + harvestInterval <= block.timestamp || 
            user.lastHarvestTimestamp == 0, "Staking: less than 24 hours since last harvest");
        user.lastHarvestTimestamp = block.timestamp;
        uint reward = calculateRewardForStake(user.amount);
        user.availableHarvest += reward - user.rewardAccountedForHarvest;
        user.rewardAccountedForHarvest = reward;

        require(amount > 0, "Staking: Nothing to harvest");
        require(amount <= user.availableHarvest, "Staking: Insufficient to harvest");
        user.availableHarvest -= amount;
        require(stakingToken.transfer(msg.sender, amount), "Staking: transfer failed");
        emit Harvest(msg.sender, amount);
    }

    function unstake(
        address to, 
        uint256 amount
    ) external canUnstake {
        updateRewardPool();
        require(amount > 0, "Staking: Nothing to unstake");
        require(to != address(0));

        UserInfo storage user = userInfo[msg.sender];
        require(amount <= user.amount, "Staking: Insufficient share");
        user.availableHarvest += calculateRewardForStake(user.amount) - user.rewardAccountedForHarvest;
        amountStaked -= amount;
        user.amount -= amount;
        user.rewardAccountedForHarvest = calculateRewardForStake(user.amount);

        require(stakingToken.transfer(to, amount), "Staking: Not enough token to transfer");
        emit Transfer(to, address(0), amount);
        emit Unstake(to, amount);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function setApr(uint aprBasisPoints_) external onlyOwner {
        updateRewardPool();
        uint oldAprBasisPoints = aprBasisPoints;
        aprBasisPoints = aprBasisPoints_;
        emit SetApr(oldAprBasisPoints, aprBasisPoints);
    }

    function togglePause() external onlyOwner {
        paused = !paused;
        emit Pause(paused);
    }

    function toggleUnstake() external onlyOwner {
        unstakePermitted = !unstakePermitted;
        emit UnstakePermit(unstakePermitted);
    }

    function withdrawToken(
        IERC20 tokenToWithdraw, 
        address to, 
        uint amount
    ) external onlyOwner {
        require(tokenToWithdraw.transfer(to, amount));
    }

    /* ========== MODIFIERS ========== */

    modifier whenNotPaused() {
        require(!paused, "Staking: contract paused.");
        _;
    }

    modifier canUnstake() {
        require(unstakePermitted || (!paused), "Staking: contract paused or unstake denied.");
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.14;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface IStaking is IERC20, IERC20Metadata {

     /* ========== CONSTANTS ========== */

    function calcDecimals() external view returns (uint);

    function secondsInYear() external view returns (uint);

    function aprDenominator() external view returns (uint);

    /* ========== STATE VARIABLES ========== */

    function aprBasisPoints() external view returns (uint);

    /* ========== MUTATIVE FUNCTIONS ========== */

    function updateRewardPool() external;

    function stake(uint amount, address to) external;

    function harvest(uint256 amount) external;

    function unstake(address to, uint256 amount) external;

    /* ========== RESTRICTED FUNCTIONS ========== */

    function setApr(uint _aprBasisPoints) external;

    function togglePause() external;

    function toggleUnstake() external;

    function withdrawToken(IERC20 tokenToWithdraw, address to, uint amount) external;

    /* ========== EVENTS ========== */

    event Pause(bool indexed flag);
    event UnstakePermit(bool indexed flag);
    event SetApr(uint indexed oldBasisPoints, uint indexed newBasisPoints);
    event Stake(address indexed user, uint indexed amount);
    event Unstake(address indexed user, uint indexed amount);
    event Harvest(address indexed user, uint indexed amount);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity >=0.8.14;

contract InitializableOwnable {

    address public owner;
    address public newOwner;

    bool internal initialized;

    // ============ Events ============

    event OwnerTransferRequested(
        address indexed oldOwner, 
        address indexed newOwner
    );

    event OwnershipTransferred(
        address indexed oldOwner, 
        address indexed newOwner
    );

    /* ========== MUTATIVE FUNCTIONS ========== */

    function initOwner(address _newOwner) public notInitialized {
        initialized = true;
        owner = _newOwner;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        emit OwnerTransferRequested(owner, _newOwner);
        newOwner = _newOwner;
    }

    function claimOwnership() public {
        require(msg.sender == newOwner, "Claim from wrong address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }

    /* ========== MODIFIERS ========== */

    modifier notInitialized() {
        require(!initialized, "Not initialized");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

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