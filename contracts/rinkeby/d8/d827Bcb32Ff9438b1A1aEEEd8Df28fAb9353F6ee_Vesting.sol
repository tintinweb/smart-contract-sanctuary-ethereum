// SPDX-License-Identifier: UNLICENSED
pragma solidity >0.0.0;
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

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

pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Vesting is Ownable {
    /**
     * @notice The structure is used in the contract createVestingScheduleBatch function to create vesting schedules
     * @param totalAmount the number of tokens to be vested during the vesting duration.
     * @param target the address that will receive tokens according to schedule parameters.
     * @param isStandard is the schedule standard type
     * @param percentsPerStages token percentages for each stage to be vest(% * 100). Empty array if schedule is standard
     * @param stagePeriods schedule stages in minutes(block.timestamp / 60). Empty array if schedule is standard
     */
    struct ScheduleData {
        uint256 totalAmount;
        address target;
        bool isStandard;
        uint16[] percentsPerStages;
        uint32[] stagePeriods;
    }

    /**
     * @notice Standard vesting schedules of an account.
     * @param initialized to check whether such a schedule already exists or not.
     * @param totalAmount the number of tokens to be vested during the vesting duration.
     * @param released the amount of the token released. It means that the account has called withdraw() and received
     * @param activeStage index of the stage starting from which tokens were not withdrawn.
     */
    struct StandardVestingSchedule {
        bool initialized;
        uint256 totalAmount;
        uint256 released;
        uint16 activeStage;
    }

    /**
     * @notice Non standard vesting schedules of an account.
     * @param initialized to check whether such a schedule already exists or not.
     * @param totalAmount the number of tokens to be vested during the vesting duration.
     * @param released the amount of the token released. It means that the account has called withdraw() and received
     * @param activeStage index of the stage starting from which tokens were not withdrawn.
     * @param percentsPerStages token percentages for each stage to be vest(% * 100).
     * @param stagePeriods schedule stages in minutes(block.timestamp / 60).
     */
    struct NonStandardVestingSchedule {
        bool initialized;
        uint256 totalAmount;
        uint256 released;
        uint16 activeStage;
        uint16[] percentsPerStages;
        uint32[] stagePeriods;
    }

    mapping(address => StandardVestingSchedule) public standardSchedules;
    mapping(address => NonStandardVestingSchedule) public nonStandardSchedules;

    IERC20 public immutable token;

    /// @notice token percentages for standard schedules for each stage to be vest. Percent multiplied by 100
    uint16[9] public percentsPerStages = [3000, 750, 750, 750, 750, 1000, 1000, 1000, 1000];
    /// @notice standard schedule stages in minutes. block.timestamp / 60
    uint32[9] public stagePeriods = [
        28381500,
        28512540,
        28645020,
        28777500,
        28908540,
        29038140,
        29170620,
        29303100,
        29434140
    ];

    event NewSchedule(address target, bool isStandard);
    event Withdrawal(address target, uint256 amount, bool isStandard);
    event EmergencyWithdrawal(address target, uint256 amount, bool isStandard);
    event UpdatedScheduleTarget(address oldTarget, address newTarget);

    constructor(IERC20 _token) {
        token = _token;
    }

    /**
     * @notice early withdraw tokens to owner address (in case if something goes wrong)
     * @param target withdrawal schedule target address
     */
    function emergencyWithdraw(address target) external onlyOwner {
        require(_isScheduleExist(target), "Vesting::MISSING_SCHEDULE");

        if (standardSchedules[target].initialized) {
            StandardVestingSchedule memory schedule = standardSchedules[target];

            delete standardSchedules[target];
            emit EmergencyWithdrawal(target, schedule.totalAmount - schedule.released, true);
            require(token.transfer(msg.sender, schedule.totalAmount - schedule.released));
        } else {
            NonStandardVestingSchedule memory schedule = nonStandardSchedules[target];

            delete nonStandardSchedules[target];
            emit EmergencyWithdrawal(target, schedule.totalAmount - schedule.released, false);
            require(token.transfer(msg.sender, schedule.totalAmount - schedule.released));
        }
    }

    /**
     * @notice create a new vesting schedules.
     * @param schedulesData an array of vesting schedules that will be created.
     */
    function createVestingScheduleBatch(ScheduleData[] memory schedulesData) external onlyOwner {
        uint256 length = schedulesData.length;
        uint256 tokenAmount;

        for (uint256 i = 0; i < length; i++) {
            ScheduleData memory schedule = schedulesData[i];

            tokenAmount += schedule.totalAmount;

            _isValidSchedule(schedule);
            require(!_isScheduleExist(schedule.target), "Vesting::EXISTING_SCHEDULE");

            _createVestingSchedule(schedule);
        }

        require(token.transferFrom(msg.sender, address(this), tokenAmount));
    }

    /**
     * @notice claim available (unlocked) tokens
     * @param target withdrawal schedule target address.
     */
    function withdraw(address target) external {
        require(_isScheduleExist(target), "Vesting::MISSING_SCHEDULE");

        bool isStandard = standardSchedules[target].initialized;
        uint256 amount;

        if (isStandard) {
            amount = _withdrawStandard(target, getTime());
        } else {
            amount = _withdrawNonStandard(target, getTime());
        }

        emit Withdrawal(target, amount, isStandard);

        require(token.transfer(target, amount));
    }

    /**
     * @notice update schedule target address
     * @param from old target address.
     * @param to new target address.
     */
    function updateTarget(address from, address to) external {
        require(msg.sender == owner() || msg.sender == from, "Vesting::FORBIDDEN");
        require(!_isScheduleExist(to), "Vesting::EXISTING_SCHEDULE");

        bool isStandard = standardSchedules[from].initialized;
        if (isStandard) {
            standardSchedules[to] = standardSchedules[from];
            delete standardSchedules[from];
        } else {
            nonStandardSchedules[to] = nonStandardSchedules[from];
            delete nonStandardSchedules[from];
        }
        emit UpdatedScheduleTarget(from, to);
    }

    /**
     * @notice withdraw stuck tokens
     * @param _token token for withdraw.
     * @param _amount amount of tokens.
     */
    function inCaseTokensGetStuck(address _token, uint256 _amount) external onlyOwner {
        require(address(token) != _token, "Vesting::FORBIDDEN");

        require(IERC20(_token).transfer(msg.sender, _amount));
    }

    /**
     * @notice get the amount of tokens available for withdrawal
     * @param target withdrawal schedule target address
     */
    function claimableAmount(address target) external view returns (uint256 amount) {
        require(_isScheduleExist(target), "Vesting::MISSING_SCHEDULE");
        uint16 stage;

        if (standardSchedules[target].initialized) {
            StandardVestingSchedule memory schedule = standardSchedules[target];

            for (stage = schedule.activeStage; stage < stagePeriods.length; stage++) {
                if (getTime() >= stagePeriods[stage]) {
                    amount += (percentsPerStages[stage] * schedule.totalAmount) / 10000;
                } else break;
            }
        } else {
            NonStandardVestingSchedule memory schedule = nonStandardSchedules[target];

            for (stage = schedule.activeStage; stage < schedule.stagePeriods.length; stage++) {
                if (getTime() >= schedule.stagePeriods[stage]) {
                    amount += (schedule.percentsPerStages[stage] * schedule.totalAmount) / 10000;
                } else break;
            }
        }
    }

    function getSchedulePercents(address target) external view returns (uint16[] memory) {
        return nonStandardSchedules[target].percentsPerStages;
    }

    function getScheduleStagePeriods(address target) external view returns (uint32[] memory) {
        return nonStandardSchedules[target].stagePeriods;
    }

    function getTime() internal view virtual returns (uint32) {
        return uint32(block.timestamp / 60);
    }

    function _withdrawStandard(address target, uint32 time) private returns (uint256 amount) {
        StandardVestingSchedule memory schedule = standardSchedules[target];
        require(stagePeriods[schedule.activeStage] <= time, "Vesting::TOO_EARLY");
        uint16 stage;

        for (stage = schedule.activeStage; stage < stagePeriods.length; stage++) {
            if (time >= stagePeriods[stage]) {
                amount += (percentsPerStages[stage] * schedule.totalAmount) / 10000;
            } else break;
        }

        // Remove the vesting schedule if all tokens were released to the account.
        if (schedule.released + amount == schedule.totalAmount) {
            delete standardSchedules[target];
            return amount;
        }
        standardSchedules[target].released += amount;
        standardSchedules[target].activeStage = stage;
    }

    function _withdrawNonStandard(address target, uint32 time) private returns (uint256 amount) {
        NonStandardVestingSchedule memory schedule = nonStandardSchedules[target];
        require(schedule.stagePeriods[schedule.activeStage] <= time, "Vesting::TOO_EARLY");
        uint16 stage;

        for (stage = schedule.activeStage; stage < schedule.stagePeriods.length; stage++) {
            if (time >= schedule.stagePeriods[stage]) {
                amount += (schedule.percentsPerStages[stage] * schedule.totalAmount) / 10000;
            } else break;
        }

        // Remove the vesting schedule if all tokens were released to the account.
        if (schedule.released + amount == schedule.totalAmount) {
            delete nonStandardSchedules[target];
            return amount;
        }
        nonStandardSchedules[target].released += amount;
        nonStandardSchedules[target].activeStage = stage;
    }

    function _isValidSchedule(ScheduleData memory schedule_) private pure {
        require(schedule_.target != address(0), "Vesting::ZERO_TARGET");
        require(schedule_.totalAmount > 0, "Vesting::ZERO_AMOUNT");
        if (!schedule_.isStandard) {
            require((schedule_.percentsPerStages).length > 0, "Vesting::MISSING_STAGES");
            require(
                (schedule_.percentsPerStages).length == (schedule_.stagePeriods).length,
                "Vesting::INVALID_PERCENTS_OR_STAGES"
            );
            uint256 totalPercents;
            for (uint256 i = 0; i < (schedule_.percentsPerStages).length; i++) {
                totalPercents += schedule_.percentsPerStages[i];
            }
            require(totalPercents == 10000, "Vesting::INVALID_PERCENTS");
        }
    }

    function _isScheduleExist(address scheduleTarget) private view returns (bool) {
        return standardSchedules[scheduleTarget].initialized || nonStandardSchedules[scheduleTarget].initialized;
    }

    function _createVestingSchedule(ScheduleData memory scheduleData) private {
        if (scheduleData.isStandard) {
            _createStandardVestingSchedule(scheduleData);
        } else {
            _createNonStandardVestingSchedule(scheduleData);
        }
    }

    function _createStandardVestingSchedule(ScheduleData memory scheduleData) private {
        standardSchedules[scheduleData.target] = StandardVestingSchedule({
            initialized: true,
            totalAmount: scheduleData.totalAmount,
            released: 0,
            activeStage: 0
        });
        emit NewSchedule(scheduleData.target, true);
    }

    function _createNonStandardVestingSchedule(ScheduleData memory scheduleData) private {
        nonStandardSchedules[scheduleData.target] = NonStandardVestingSchedule({
            initialized: true,
            totalAmount: scheduleData.totalAmount,
            released: 0,
            activeStage: 0,
            percentsPerStages: scheduleData.percentsPerStages,
            stagePeriods: scheduleData.stagePeriods
        });
        emit NewSchedule(scheduleData.target, false);
    }
}

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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

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
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
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
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
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
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
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
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
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
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TPYToken is ERC20 {
    constructor() ERC20("TPY Token", "TPY") {
        _mint(msg.sender, 1e9 * 1e8);
    }

    function mint(address account, uint256 amount) external {
        _mint(account, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TestToken is ERC20 {
    constructor() ERC20("Test Token", "TT") {
        _mint(msg.sender, 1e9 * 1e18);
    }

    function mint(address account, uint256 amount) external {
        _mint(account, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "../Vesting.sol";

contract VestingMock is Vesting {
    uint32 public time;

    constructor(IERC20 token) Vesting(token) {}

    function setMockTime(uint32 time_) public returns (uint32) {
        time = time_;
        return time;
    }

    function getTime() internal view override returns (uint32) {
        return time;
    }
}