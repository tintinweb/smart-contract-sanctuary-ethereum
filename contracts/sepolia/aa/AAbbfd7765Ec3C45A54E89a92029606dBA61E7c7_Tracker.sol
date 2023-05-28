// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

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
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
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
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

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
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
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
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

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

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

import {CommonErrors} from "./Errors.sol";

/// @title Auth
contract Auth {

    /// @dev Emitted when the Golem Foundation multisig address is set.
    /// @param oldValue The old Golem Foundation multisig address.
    /// @param newValue The new Golem Foundation multisig address.
    event MultisigSet(address oldValue, address newValue);

    /// @dev Emitted when the deployer address is set.
    /// @param oldValue The old deployer address.
    event DeployerRenounced(address oldValue);

    /// @dev The deployer address.
    address public deployer;

    /// @dev The multisig address.
    address public multisig;

    /// @param _multisig The initial Golem Foundation multisig address.
    constructor(address _multisig) {
        multisig = _multisig;
        deployer = msg.sender;
    }

    /// @dev Sets the multisig address.
    /// @param _multisig The new multisig address.
    function setMultisig(address _multisig) external {
        require(msg.sender == multisig, CommonErrors.UNAUTHORIZED_CALLER);
        emit MultisigSet(multisig, _multisig);
        multisig = _multisig;
    }

    /// @dev Leaves the contract without a deployer. It will not be possible to call
    /// `onlyDeployer` functions. Can only be called by the current deployer.
    function renounceDeployer() external {
        require(msg.sender == deployer, CommonErrors.UNAUTHORIZED_CALLER);
        emit DeployerRenounced(deployer);
        deployer = address(0);
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

library AllocationErrors {
    /// @notice Thrown when the user trying to allocate before first epoch has started
    /// @return HN:Allocations/not-started-yet
    string public constant EPOCHS_HAS_NOT_STARTED_YET =
        "HN:Allocations/first-epoch-not-started-yet";

    /// @notice Thrown when the user trying to allocate after decision window is closed
    /// @return HN:Allocations/decision-window-closed
    string public constant DECISION_WINDOW_IS_CLOSED =
        "HN:Allocations/decision-window-closed";

    /// @notice Thrown when user trying to allocate more than he has in rewards budget for given epoch.
    /// @return HN:Allocations/allocate-above-rewards-budget
    string public constant ALLOCATE_ABOVE_REWARDS_BUDGET =
        "HN:Allocations/allocate-above-rewards-budget";

    /// @notice Thrown when user trying to allocate to a proposal that does not exist.
    /// @return HN:Allocations/no-such-proposal
    string public constant ALLOCATE_TO_NON_EXISTING_PROPOSAL =
        "HN:Allocations/no-such-proposal";
}

library OracleErrors {
    /// @notice Thrown when trying to set the balance in oracle for epochs other then previous.
    /// @return HN:Oracle/can-set-balance-for-previous-epoch-only
    string public constant CANNOT_SET_BALANCE_FOR_PAST_EPOCHS =
        "HN:Oracle/can-set-balance-for-previous-epoch-only";

    /// @notice Thrown when trying to set the balance in oracle when balance can't yet be determined.
    /// @return HN:Oracle/can-set-balance-at-earliest-in-second-epoch
    string public constant BALANCE_CANT_BE_KNOWN =
        "HN:Oracle/can-set-balance-at-earliest-in-second-epoch";

    /// @notice Thrown when trying to set the oracle balance multiple times.
    /// @return HN:Oracle/balance-for-given-epoch-already-exists
    string public constant BALANCE_ALREADY_SET =
        "HN:Oracle/balance-for-given-epoch-already-exists";

    /// @notice Thrown if contract is misconfigured
    /// @return HN:Oracle/WithdrawalsTarget-not-set
    string public constant NO_TARGET =
        "HN:Oracle/WithdrawalsTarget-not-set";

    /// @notice Thrown if contract is misconfigured
    /// @return HN:Oracle/PayoutsManager-not-set
    string public constant NO_PAYOUTS_MANAGER =
        "HN:Oracle/PayoutsManager-not-set";

}

library DepositsErrors {
    /// @notice Thrown when transfer operation fails in GLM smart contract.
    /// @return HN:Deposits/cannot-transfer-from-sender
    string public constant GLM_TRANSFER_FAILED =
        "HN:Deposits/cannot-transfer-from-sender";

    /// @notice Thrown when trying to withdraw more GLMs than are in deposit.
    /// @return HN:Deposits/deposit-is-smaller
    string public constant DEPOSIT_IS_TO_SMALL =
        "HN:Deposits/deposit-is-smaller";
}

library EpochsErrors {
    /// @notice Thrown when calling the contract before the first epoch started.
    /// @return HN:Epochs/not-started-yet
    string public constant NOT_STARTED = "HN:Epochs/not-started-yet";

    /// @notice Thrown when updating epoch props to invalid values (decision window bigger than epoch duration.
    /// @return HN:Epochs/decision-window-bigger-than-duration
    string public constant DECISION_WINDOW_TOO_BIG = "HN:Epochs/decision-window-bigger-than-duration";
}

library TrackerErrors {
    /// @notice Thrown when trying to get info about effective deposits in future epochs.
    /// @return HN:Tracker/future-is-unknown
    string public constant FUTURE_IS_UNKNOWN = "HN:Tracker/future-is-unknown";

    /// @notice Thrown when trying to get info about effective deposits in epoch 0.
    /// @return HN:Tracker/epochs-start-from-1
    string public constant EPOCHS_START_FROM_1 =
        "HN:Tracker/epochs-start-from-1";
}

library PayoutsErrors {
    /// @notice Thrown when trying to register more funds than possess.
    /// @return HN:Payouts/registering-withdrawal-of-unearned-funds
    string public constant REGISTERING_UNEARNED_FUNDS =
        "HN:Payouts/registering-withdrawal-of-unearned-funds";
}

library ProposalsErrors {
    /// @notice Thrown when trying to change proposals that could already have been voted upon.
    /// @return HN:Proposals/only-future-proposals-changing-is-allowed
    string public constant CHANGING_PROPOSALS_IN_THE_PAST =
        "HN:Proposals/only-future-proposals-changing-is-allowed";
}

library CommonErrors {
    /// @notice Thrown when trying to call as an unauthorized account.
    /// @return HN:Common/unauthorized-caller
    string public constant UNAUTHORIZED_CALLER =
        "HN:Common/unauthorized-caller";
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

import {CommonErrors} from "./Errors.sol";
import "./Auth.sol";

/// @title OctantBase
/// @dev This is the base contract for all Octant contracts that have functions with access restricted
/// to deployer or the Golem Foundation multisig.
/// It provides functionality for setting and accessing the Golem Foundation multisig address.
abstract contract OctantBase {

    /// @dev The Auth contract instance
    Auth auth;

    /// @param _auth the contract containing Octant authorities.
    constructor(address _auth) {
        auth = Auth(_auth);
    }

    /// @dev Gets the Golem Foundation multisig address.
    function getMultisig() internal view returns (address) {
        return auth.multisig();
    }

    /// @dev Modifier that allows only the Golem Foundation multisig address to call a function.
    modifier onlyMultisig() {
        require(msg.sender == auth.multisig(), CommonErrors.UNAUTHORIZED_CALLER);
        _;
    }

    /// @dev Modifier that allows only deployer address to call a function.
    modifier onlyDeployer() {
        require(msg.sender == auth.deployer(), CommonErrors.UNAUTHORIZED_CALLER);
        _;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

import "../interfaces/IEpochs.sol";
import "../interfaces/ITracker.sol";
import "../interfaces/IDeposits.sol";

import "./TrackerWrapper.sol";
import "../OctantBase.sol";

import {TrackerErrors, CommonErrors} from "../Errors.sol";

/// external dependencies
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


/// @title Contract tracking effective deposits across epochs (Octant).
/// @author Golem Foundation
/// @notice This contract tracks effective deposits for particular epochs.
/// If deposit is lower than 100 GLM it is not taken into account.
/// For any epoch and participant, the lowest value of the deposit
/// is considered effective.
/// @dev Time is split into epochs, effective deposit is defined as min value
/// of GLM held by this contract on behalf of the depositor in particular epoch.
contract Tracker is OctantBase {
    /// @notice Epochs contract address.
    IEpochs public immutable epochs;

    /// @notice Deposits contract address
    IDeposits public immutable deposits;

    /// @notice GLM token (token after migration).
    ERC20 public immutable glm;

    /// @notice GNT token (original GNT, before migration).
    ERC20 public immutable gnt;

    /// @notice TrackerWrapper address
    address public wrapperAddress;

    struct EffectiveDeposit {
        bool isSet; // set to true to distinguish between null and zero values of ED
        uint224 amount;
    }

    /// @dev total effective deposit now
    uint224 public totalDeposit;

    /// @dev helper structure for effective deposit amounts tracking. See `depositAt` function
    /// GLMGE_it
    mapping(address => mapping(uint32 => EffectiveDeposit)) private effectiveDeposits;

    /// @dev Tracking total supply of GLM per epoch.
    mapping(uint32 => uint224) public tokenSupplyByEpoch;

    /// @dev total effective deposit in a particular epoch
    /// (sigma GLMGE_i for particular t)
    mapping(uint32 => EffectiveDeposit) private totalEffectiveDeposits;

    /// @param epochsAddress Address of Epochs contract.
    constructor(
        address epochsAddress,
        address depositsAddress,
        address glmAddress,
        address gntAddress,
        address _auth
    ) OctantBase(_auth) {
        epochs = IEpochs(epochsAddress);
        deposits = IDeposits(depositsAddress);
        glm = ERC20(glmAddress);
        gnt = ERC20(gntAddress);
    }

    /// @dev Handle GLM locking, compute epoch effective deposit.
    /// @param owner Owner of GLM
    /// @param oldDeposit Last value of owner's GLM deposit
    /// @param amount New funds being locked.
    function processLock(
        address owner,
        uint224 oldDeposit,
        uint224 amount
    ) external onlyTrackerWrapper {
        uint224 oldTotal = totalDeposit;
        totalDeposit =
            totalDeposit -
            _applyDepositCutoff(oldDeposit) +
            _applyDepositCutoff(oldDeposit + amount);
        uint32 epoch = epochs.getCurrentEpoch();
        _updatePrevED(owner, epoch, oldDeposit, oldTotal);
        _updateCurrentED(owner, epoch, oldDeposit, oldTotal);
    }

    /// @dev Handle GLM unlocking, compute epoch effective deposit.
    /// @param owner Owner of GLM
    /// @param oldDeposit Last value of owner's GLM deposit
    /// @param amount Amount of funds being unlocked.
    function processUnlock(
        address owner,
        uint224 oldDeposit,
        uint224 amount
    ) external onlyTrackerWrapper {
        uint224 oldTotal = totalDeposit;
        totalDeposit =
            totalDeposit -
            _applyDepositCutoff(oldDeposit) +
            _applyDepositCutoff(oldDeposit - amount);
        uint32 epoch = epochs.getCurrentEpoch();
        _updatePrevED(owner, epoch, oldDeposit, oldTotal);
    }

    /// @notice Check how much is locked at particular epoch. Note that contract tracks only minimal value of locked GLM particular depositor had at the epoch.
    /// @dev Call this to read ED for any user at particular epoch. Please note that worst-case gas cost is O(n) where n is
    /// the number of epochs contract has been active for.
    /// @param owner Owner of the deposit for which ED will be checked.
    /// @param epochNo Epoch number, for which ED will be checked.
    /// @return Effective deposit (GLM) in wei for particular epoch, particular owner.
    function depositAt(
        address owner,
        uint32 epochNo
    ) external view returns (uint256) {
        uint32 currentEpoch = epochs.getCurrentEpoch();
        require(epochNo <= currentEpoch, TrackerErrors.FUTURE_IS_UNKNOWN);
        require(epochNo > 0, TrackerErrors.EPOCHS_START_FROM_1);
        for (
            uint32 iEpoch = epochNo;
            iEpoch <= currentEpoch;
            iEpoch = iEpoch + 1
        ) {
            if (effectiveDeposits[owner][iEpoch].isSet) {
                return
                    uint256(
                        _applyDepositCutoff(
                            effectiveDeposits[owner][iEpoch].amount
                        )
                    );
            }
        }
        return uint256(_applyDepositCutoff(uint224(deposits.deposits(owner))));
    }

    /// @dev Returns the total deposit amount for the given epoch.
    /// @param epochNo The epoch to retrieve the total deposit for.
    /// @return The total deposit amount for the epoch.
    /// @notice If the epochNo is in the future or less than 1, this function will revert.
    function totalDepositAt(uint32 epochNo) external view returns (uint256) {
        uint32 currentEpoch = epochs.getCurrentEpoch();
        require(epochNo <= currentEpoch, TrackerErrors.FUTURE_IS_UNKNOWN);
        require(epochNo > 0, TrackerErrors.EPOCHS_START_FROM_1);
        for (
            uint32 iEpoch = epochNo;
            iEpoch <= currentEpoch;
            iEpoch = iEpoch + 1
        ) {
            if (totalEffectiveDeposits[iEpoch].isSet) {
                return uint256(totalEffectiveDeposits[iEpoch].amount);
            }
        }
        return totalDeposit;
    }

    /// @dev Returns the GLM supply for the given epoch.
    /// @param epochNo The epoch to retrieve the GLM supply for.
    /// @return The GLM supply for the epoch.
    /// @notice If the epochNo is in the future or less than 1, this function will revert.
    function tokenSupplyAt(uint32 epochNo) external view returns (uint224) {
        uint32 currentEpoch = epochs.getCurrentEpoch();
        require(epochNo <= currentEpoch, TrackerErrors.FUTURE_IS_UNKNOWN);
        require(epochNo > 0, TrackerErrors.EPOCHS_START_FROM_1);
        for (
            uint32 iEpoch = epochNo;
            iEpoch <= currentEpoch;
            iEpoch = iEpoch + 1
        ) {
            if (0 != tokenSupplyByEpoch[iEpoch]) {
                return tokenSupplyByEpoch[iEpoch];
            }
        }
        return tokenSupply();
    }

    /// @notice Compute total GLM token supply at this particular moment. Burned GLM is not part of the supply.
    function tokenSupply() public view returns (uint224) {
        address burnAddress = 0x0000000000000000000000000000000000000000;
        return
            uint224(glm.totalSupply()) +
            uint224(gnt.totalSupply()) -
            uint224(glm.balanceOf(burnAddress)) -
            uint224(gnt.balanceOf(burnAddress));
    }

    function setWrapperAddress(address _wrapperAddress) external onlyDeployer {
        require(address(wrapperAddress) == address(0x0));
        wrapperAddress = _wrapperAddress;
    }

    /// @dev Sets ED in a situation when funds are moved after a period of inactivity.
    function _updatePrevED(
        address owner,
        uint32 epoch,
        uint224 oldDeposit,
        uint224 oldTotal
    ) private {
        EffectiveDeposit memory prevED = effectiveDeposits[owner][epoch - 1];
        if (!prevED.isSet) {
            prevED.isSet = true;
            prevED.amount = oldDeposit;
            effectiveDeposits[owner][epoch - 1] = prevED;
        }

        EffectiveDeposit memory epochED = totalEffectiveDeposits[epoch - 1];
        if (!epochED.isSet) {
            epochED.isSet = true;
            epochED.amount = oldTotal;
            totalEffectiveDeposits[epoch - 1] = epochED;
            tokenSupplyByEpoch[epoch] = tokenSupply();
        }
    }

    /// @dev Tracks ED as min(deposit) for current epoch.
    function _updateCurrentED(
        address owner,
        uint32 epoch,
        uint224 oldDeposit,
        uint224 oldTotal
    ) private {
        EffectiveDeposit memory currentED = effectiveDeposits[owner][epoch];
        EffectiveDeposit memory epochED = totalEffectiveDeposits[epoch];
        if (!currentED.isSet) {
            currentED.amount = oldDeposit;
            currentED.isSet = true;
            effectiveDeposits[owner][epoch] = currentED;
        } else {
            currentED.amount = _min(oldDeposit, currentED.amount);
            effectiveDeposits[owner][epoch] = currentED;
        }
        if (!epochED.isSet) {
            epochED.amount = oldTotal;
            epochED.isSet = true;
            totalEffectiveDeposits[epoch] = epochED;
        } else {
            epochED.amount = _min(oldTotal, epochED.amount);
            totalEffectiveDeposits[epoch] = epochED;
            tokenSupplyByEpoch[epoch] = tokenSupply();
        }
    }

    /// @dev return smaller of two number values
    function _min(uint224 a, uint224 b) private pure returns (uint224) {
        return a <= b ? a : b;
    }

    /// @dev Implements cutoff of 100 GLM. Amounts lower than that are not eligible for rewards.
    /// @param actualAmount Amount of GLM currently deposited.
    /// @return Amount of GLM adjusted by 100 GLM cutoff.
    function _applyDepositCutoff(
        uint224 actualAmount
    ) private pure returns (uint224) {
        if (actualAmount < 100 ether) {
            return 0;
        }
        return actualAmount;
    }

    modifier onlyTrackerWrapper() {
        require(msg.sender == wrapperAddress, CommonErrors.UNAUTHORIZED_CALLER);
        _;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

import "../interfaces/ITracker.sol";
import "./Tracker.sol";

import {TrackerErrors, CommonErrors} from "../Errors.sol";

/// @title Wrapper to contract tracking effective deposits across epochs (Octant).
/// @author Golem Foundation
/// @notice This contract is a wrapper to Tracker. Purpose of it is to catch errors from Tracker and
/// convert it to boolean value.
contract TrackerWrapper is ITracker {
    /// @notice Tracker contract address.
    Tracker public immutable tracker;

    /// @notice Deposits contract address.
    address public depositsAddress;

    constructor(address _trackerAddress, address _depositsAddress) {
        tracker = Tracker(_trackerAddress);
        depositsAddress = _depositsAddress;
    }

    /// @dev Handle GLM locking, compute epoch effective deposit.
    /// @param owner Owner of GLM
    /// @param oldDeposit Last value of owner's GLM deposit
    /// @param amount New funds being locked.
    function processLock(
        address owner,
        uint224 oldDeposit,
        uint224 amount
    ) external onlyDeposits {
        tracker.processLock(owner, oldDeposit, amount);
    }

    /// @dev Handle GLM unlocking, compute epoch effective deposit.
    /// @param owner Owner of GLM
    /// @param oldDeposit Last value of owner's GLM deposit
    /// @param amount Amount of funds being unlocked.
    /// @return true if computation was successful, false in case of any error
    function processUnlock(
        address owner,
        uint224 oldDeposit,
        uint224 amount
    ) external onlyDeposits returns (bool, bytes memory) {
        try tracker.processUnlock(owner, oldDeposit, amount) {
            return (true, "");
        } catch Error(string memory reason) {
            // This is executed in case
            // revert was called inside tracker.processUnlock()
            // and a reason string was provided.
            return (false, bytes(reason));
        } catch (bytes memory reason) {
            // This is executed in case revert() was used
            // or there was a failing assertion, division
            // by zero, etc. inside tracker.processUnlock().
            return (false, reason);
        }
    }

    modifier onlyDeposits() {
        require(
            msg.sender == depositsAddress,
            CommonErrors.UNAUTHORIZED_CALLER
        );
        _;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

interface IDeposits {
    function deposits(address) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

interface IEpochs {
    function getCurrentEpoch() external view returns (uint32);

    function getEpochDuration() external view returns (uint256);

    function getDecisionWindow() external view returns (uint256);

    function isStarted() external view returns (bool);

    function isDecisionWindowOpen() external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

interface ITracker {
    function processLock(address, uint224, uint224) external;

    function processUnlock(
        address,
        uint224,
        uint224
    ) external returns (bool, bytes memory);
}