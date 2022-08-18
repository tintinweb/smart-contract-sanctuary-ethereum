pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later
// STAX (investments/frax-gauge/tranche/ConvexVaultTranche.sol)

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "../../../interfaces/external/convex/IConvexStakingProxyERC20Joint.sol";
import "../../../interfaces/external/convex/IConvexRewards.sol";
import "../../../interfaces/external/convex/IConvexVeFxsProxy.sol";
import "../../../interfaces/external/convex/IConvexBooster.sol";

import "./BaseTranche.sol";

/**
  * @notice A tranche which locks the LP into Convex's FRAX vaults (which in turn locks in the gauge)
  * Convex gets an 'owner' fee, and if they are supplying the veFXS boost they also get a booster fee
  * STAX gets a 'joint owner' fee from the convex vault.
  *
  * @dev It's possible to switch the veFXS booster from Convex's proxy <-->  STAX's proxy
  */
contract ConvexVaultTranche is BaseTranche {
    using SafeERC20 for IERC20;

    /// @notice The convex vault implementation to use when creating a new tranche.
    /// @dev If a new implementation id needs to be used (eg convex releases updated vault),
    /// then that will need a new Tranche template to be deployed.
    uint256 public immutable convexVaultImplementationId;

    /// @notice The STAX owner of the Joint Vault (co-owned with convex)
    /// @dev New tranches need to be whitelisted on this so it's able to create a new convex vault.
    address public immutable convexVaultOps;

    /// @notice Convex's immutable veFXS proxy contract which is whitelisted on FRAX
    IConvexVeFxsProxy public immutable convexVeFxsProxy;
    
    /// @notice The underlying convex vault which is created on initialization
    IConvexStakingProxyERC20Joint public convexVault;

    error NotSupported();

    function trancheType() external pure returns (TrancheType) {
        return TrancheType.CONVEX_VAULT;
    }

    function trancheVersion() external pure returns (uint256) {
        return 1;
    }

    constructor(uint256 _convexVaultImplementationId, address _convexVaultOps, address _convexVeFxsProxy) {
        convexVaultImplementationId = _convexVaultImplementationId;
        convexVaultOps = _convexVaultOps;
        convexVeFxsProxy = IConvexVeFxsProxy(_convexVeFxsProxy);
    }

    function _initialize() internal override {
        // The registry execute() is used to whitelist this new tranche on Convex Vault Ops
        // such that it's able to create a convex vault.
        registry.execute(
            convexVaultOps,
            0,
            abi.encodeWithSelector(bytes4(keccak256("setAllowedAddress(address,bool)")), address(this), true)
        );

        // Create the convex vault
        // This needs to be done via the Convex Booster contract - which is upgradeable
        // So lookup the current booster from their VeFXSProxy (which is whitelisted and won't change)
        convexVault = IConvexStakingProxyERC20Joint(
            IConvexBooster(convexVeFxsProxy.operator()).createVault(convexVaultImplementationId)
        );

        // Set the underlying gauge/staking token, pulled from the convex vault.
        underlyingGauge = IFraxGauge(convexVault.stakingAddress());
        stakingToken = IERC20(convexVault.stakingToken());

        // Set staking token allowance to max on initialization, rather than
        // one-by-one later.
        stakingToken.safeIncreaseAllowance(address(convexVault), type(uint256).max);
    }

    function _stakeLocked(uint256 liquidity, uint256 secs) internal override returns (bytes32) {
        convexVault.stakeLocked(liquidity, secs);

        // Need to access the underlying gauge to get the new lock info, it's not returned by the convex vault.
        IFraxGauge.LockedStake[] memory existingLockedStakes = underlyingGauge.lockedStakesOf(address(convexVault));
        uint256 lockedStakesLength = existingLockedStakes.length;
        return existingLockedStakes[lockedStakesLength-1].kek_id;
    }

    function _lockAdditional(bytes32 kek_id, uint256 addl_liq) internal override {
        convexVault.lockAdditional(kek_id, addl_liq);
        emit AdditionalLocked(address(this), kek_id, addl_liq);
    }

    function _withdrawLocked(bytes32 kek_id, address destination_address) internal override returns (uint256 withdrawnAmount) {      
        // The convex vault doesn't have a destination address option.
        // So first withdraw here, and then transfer to the destination
        uint256 stakingTokensBefore = stakingToken.balanceOf(address(this));
        convexVault.withdrawLocked(kek_id);
        unchecked {
            withdrawnAmount = stakingToken.balanceOf(address(this)) - stakingTokensBefore;
        }

        if (destination_address != address(this) && withdrawnAmount > 0) {
            stakingToken.safeTransfer(destination_address, withdrawnAmount);
        }
    }

    function _lockedStakes() internal view override returns (IFraxGauge.LockedStake[] memory) {
        return underlyingGauge.lockedStakesOf(address(convexVault));
    }

    function getRewards(address[] calldata rewardTokens) external override returns (uint256[] memory) {
        // The convex vault fees (co-owner & veFXS boost provider) get sent directly to LiquidityOps
        // (or some other STAX fee collector contract). 
        // The remaining rewards get sent to this contract.
        convexVault.getReward(true, rewardTokens);

        // Now forward the rewards to the tranche owner (liquidity ops)
        address _owner = owner();
        uint256[] memory rewardAmounts = new uint256[](rewardTokens.length);
        for (uint256 i=0; i<rewardTokens.length;) {
            uint256 bal = IERC20(rewardTokens[i]).balanceOf(address(this));
            if (bal > 0) {
                IERC20(rewardTokens[i]).safeTransfer(_owner, bal);
            }
            rewardAmounts[i] = bal;
            unchecked { i++; }
        }

        emit RewardClaimed(address(this), rewardAmounts);
        return rewardAmounts;
    }

    /**
      * @notice Switch the convex vault's veFXS boost to a new proxy. This proxy must be either
      * the stax whitelisted veFXS proxy or the convex whitelisted veFXS proxy.
      * 
      * Calling convexVault.setVeFXSProxy() will:
      *   1. Turn off the convex vault on the old veFXS proxy (eg convex's veFXS proxy)
      *   2. Turn on the convex vault on the new veFXS proxy (eg stax's veFXS proxy)
      *   3. Set the new veFXS proxy on the underlying convex vault
      *
      * @dev Get the current convex booster from their whitelisted veFXS proxy, as it can change
      */
    function setVeFXSProxy(address _proxy) external override onlyOwner {
        IConvexBooster(convexVeFxsProxy.operator()).setVeFXSProxy(address(convexVault), _proxy);
        emit VeFXSProxySet(_proxy);
    }

    function toggleMigrator(address /*migrator_address*/) external pure override {
        // The Convex vault doesn't allow this to be set, and are not willing to add.
        // In this case that this happens, STAX will be paying owner fees until unlock, 
        // but can avoid paying booster fees by switching the vefxs proxy to STAX's veFXSProxy.
        // If very malicious, then FRAX may be willing to global unlock the gauge.
        revert NotSupported();
    }

    function getAllRewardTokens() external view returns (address[] memory) {
        address[] memory gaugeRewardTokens = underlyingGauge.getAllRewardTokens();

        IConvexRewards convexRewards = IConvexRewards(convexVault.rewards());
        if (convexRewards.active()) {
            // Need to construct a fixed size array and copy the underlying gauge + convex reward addresses.
            // Not particularly efficient, however this should only be called off-chain
            uint256 convexRewardsLength = convexRewards.rewardTokenLength();
            uint256 size = gaugeRewardTokens.length + convexRewardsLength;
            address[] memory allRewardTokens = new address[](size);

            uint256 index;
            for (; index < gaugeRewardTokens.length; index++) {
                allRewardTokens[index] = gaugeRewardTokens[index];
            }

            for (uint256 j=0; j < convexRewardsLength; j++) {
                allRewardTokens[index] = convexRewards.rewardTokens(j);
                index++;
            }
            return allRewardTokens;
        } else {
            // Just the underlying gauge reward addresses.
            return gaugeRewardTokens;
        }
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

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
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
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

pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later
// STAX (interfaces/external/convex/IConvexStakingProxyERC20Joint.sol)

// ref: https://github.com/convex-eth/frax-cvx-platform/blob/feature/joint_vault/contracts/contracts/StakingProxyERC20Joint.sol
interface IConvexStakingProxyERC20Joint {
    function stakeLocked(uint256 _liquidity, uint256 _secs) external;
    function lockAdditional(bytes32 _kek_id, uint256 _addl_liq) external;
    function withdrawLocked(bytes32 _kek_id) external;
    function getReward(bool _claim, address[] calldata _rewardTokenList) external;

    function stakingAddress() external view returns (address);
    function stakingToken() external view returns (address);
    function rewards() external view returns (address);
}

pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later
// STAX (interfaces/external/convex/IConvexRewards.sol)

// ref: https://github.com/convex-eth/frax-cvx-platform/blob/feature/joint_vault/contracts/contracts/MultiRewards.sol
interface IConvexRewards {
    function rewardTokens(uint256 _rid) external view returns (address);
    function rewardTokenLength() external view returns(uint256);
    function active() external view returns(bool);
}

pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later
// STAX (interfaces/external/convex/IConvexVeFxsProxy.sol)

// https://github.com/convex-eth/frax-cvx-platform/blob/feature/joint_vault/contracts/contracts/VoterProxy.sol

interface IConvexVeFxsProxy {
    function operator() external view returns (address);
}

pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later
// STAX (interfaces/external/convex/IConvexBooster.sol)

// ref: https://github.com/convex-eth/frax-cvx-platform/blob/feature/joint_vault/contracts/contracts/Booster.sol
interface IConvexBooster {
    function createVault(uint256 _pid) external returns (address);
    function setVeFXSProxy(address _vault, address _newproxy) external;
}

pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later
// STAX (investments/frax-gauge/tranche/BaseTranche.sol)

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "../../../interfaces/investments/frax-gauge/tranche/ITranche.sol";
import "../../../interfaces/investments/frax-gauge/tranche/ITrancheRegistry.sol";
import "../../../interfaces/external/frax/IFraxGauge.sol";

import "../../../common/CommonEventsAndErrors.sol";
import "../../../common/Executable.sol";

/**
  * @notice The abstract base contract for all tranche implementations
  * 
  * Owner of each tranche: LiquidityOps
  */
abstract contract BaseTranche is ITranche, Ownable {
    using SafeERC20 for IERC20;

    /// @notice Whether this tranche has been initialized yet or not.
    /// @dev A tranche can only be initialized once
    /// factory template deployments are pushed manually, and should then be disabled
    /// (such that they can't be initialized)
    bool public initialized;
    
    /// @notice The registry used to create/initialize this instance.
    /// @dev Tranche implementations have access to call some methods of the registry
    ///      which created it.
    ITrancheRegistry public registry;

    /// @notice If this tranche is disabled, it cannot be used for new tranche instances
    ///         and new desposits can not be taken.
    ///         Withdrawals of expired locks can still take place.
    bool public override disabled;

    /// @notice The underlying frax gauge that this tranche is staking into.
    IFraxGauge public underlyingGauge;

    /// @notice The token which is being staked.
    IERC20 public stakingToken;

    /// @notice The total amount of stakingToken locked in this tranche.
    ///         This includes not yet withdrawn tokens in expired locks
    ///         Withdrawn tokens decrement this total.
    uint256 public totalLocked;

    /// @notice The implementation used to clone this instance
    uint256 public fromImplId;

    error OnlyOwnerOrRegistry(address caller);

    /// @notice Initialize the newly cloned instance.
    /// @dev When deploying new template implementations, setDisabled() should be called on
    ///      them such that they can't be initialized by others.
    function initialize(address _registry, uint256 _fromImplId, address _newOwner) external override returns (address, address) {
        if (initialized) revert AlreadyInitialized();
        if (disabled) revert InactiveTranche(address(this));

        registry = ITrancheRegistry(_registry);                
        fromImplId = _fromImplId;
        _transferOwnership(_newOwner);

        initialized = true;

        _initialize();

        return (address(underlyingGauge), address(stakingToken));
    }

    /// @notice Derived classes to implement any custom initialization
    function _initialize() internal virtual;

    /// @dev The old registry or the owner can re-point to a new registry, in case of registry upgrade.
    function setRegistry(address _registry) external override onlyOwnerOrRegistry {
        registry = ITrancheRegistry(_registry);
        emit RegistrySet(_registry);
    }

    /// @notice The registry or the owner can disable this tranche instance
    function setDisabled(bool isDisabled) external override onlyOwnerOrRegistry {
        disabled = isDisabled;
        emit SetDisabled(isDisabled);
    }

    function lockedStakes() external view override returns (IFraxGauge.LockedStake[] memory) {
        return _lockedStakes();
    }

    function _lockedStakes() internal virtual view returns (IFraxGauge.LockedStake[] memory);

    /// @notice Stake LP in the underlying gauge/vault, for a given duration
    /// @dev If there is already an active gauge lock for this tranche, and that lock
    ///      has not yet expired, then the LP will be added to the existing lock
    ///      So only one active lock will exist.
    function stake(uint256 liquidity, uint256 secs) external override onlyOwner isOpenForStaking(liquidity) returns (bytes32 kekId) {
        totalLocked += liquidity;

        // If first time lock or the latest lock has expired - then create a new lock.
        // otherwise add to the existing active lock
        IFraxGauge.LockedStake[] memory existingLockedStakes = _lockedStakes();
        uint256 lockedStakesLength = existingLockedStakes.length;
        
        if (lockedStakesLength == 0 || block.timestamp >= existingLockedStakes[lockedStakesLength - 1].ending_timestamp) {
            kekId = _stakeLocked(liquidity, secs);
        } else {
            kekId = existingLockedStakes[lockedStakesLength - 1].kek_id;
            _lockAdditional(kekId, liquidity);
        }
    }

    function _stakeLocked(uint256 liquidity, uint256 secs) internal virtual returns (bytes32);

    function _lockAdditional(bytes32 kek_id, uint256 addl_liq) internal virtual;

    /// @notice Withdraw LP from expired locks
    function withdraw(bytes32 kek_id, address destination_address) external override onlyOwner returns (uint256 withdrawnAmount) {      
        withdrawnAmount = _withdrawLocked(kek_id, destination_address);
        totalLocked -= withdrawnAmount;
    }

    function _withdrawLocked(bytes32 kek_id, address destination_address) internal virtual returns (uint256 withdrawnAmount);

    /// @notice Owner can recoer tokens
    function recoverToken(address _token, address _to, uint256 _amount) external onlyOwner {
        IERC20(_token).safeTransfer(_to, _amount);
        emit CommonEventsAndErrors.TokenRecovered(_to, _token, _amount);
    }

    /// @notice Execute is provided for the owner (LiquidityOps), in case there are future operations on the underlying gauge/vault
    /// which need to be called.
    function execute(
        address _to,
        uint256 _value,
        bytes calldata _data
    ) external onlyOwner returns (bytes memory) {
        return Executable.execute(_to, _value, _data);
    }

    /// @notice Is this tranche active and the total locked is less than maxTrancheSize
    function willAcceptLock(uint256 maxTrancheSize) external view override returns (bool) {
        return (
            !disabled &&
            totalLocked < maxTrancheSize
        );
    }

    /// @notice Does this tranche have sufficient LP in it, and it's active/open for staking
    modifier isOpenForStaking(uint256 _liquidity) {
        if (disabled || !initialized) revert InactiveTranche(address(this));

        // Check this tranche has enough liquidity
        uint256 balance = stakingToken.balanceOf(address(this));
        if (balance < _liquidity) revert CommonEventsAndErrors.InsufficientBalance(address(stakingToken), _liquidity, balance);

        // Also check that this tranche implementation is still open for staking
        // Worth the gas to have the kill switch on the implementation id.
        // Any automation (eg keeper) will simulate first, so gas shouldn't be wasted on revert.
        if (registry.implDetails(fromImplId).closedForStaking) revert ITrancheRegistry.InvalidTrancheImpl(fromImplId);

        _;
    }

    modifier onlyOwnerOrRegistry() {
        if (msg.sender != owner() && msg.sender != address(registry)) revert OnlyOwnerOrRegistry(msg.sender);
        _;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
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

pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later
// STAX (interfaces/investments/frax-gauge/tranche/ITranche.sol)

import "../../../external/frax/IFraxGauge.sol";

interface ITranche {
    enum TrancheType {
        DIRECT,
        CONVEX_VAULT
    }

    event RegistrySet(address indexed registry);
    event SetDisabled(bool isDisabled);
    event RewardClaimed(address indexed trancheAddress, uint256[] rewardData);
    event AdditionalLocked(address indexed staker, bytes32 kekId, uint256 liquidity);
    event VeFXSProxySet(address indexed proxy);
    event MigratorToggled(address indexed migrator);

    error InactiveTranche(address tranche);
    error AlreadyInitialized();
    
    function disabled() external view returns (bool);
    function willAcceptLock(uint256 liquidity) external view returns (bool);
    function lockedStakes() external view returns (IFraxGauge.LockedStake[] memory);

    function initialize(address _registry, uint256 _fromImplId, address _newOwner) external returns (address, address);
    function setRegistry(address _registry) external;
    function setDisabled(bool isDisabled) external;
    function setVeFXSProxy(address _proxy) external;
    function toggleMigrator(address migrator_address) external;

    function stake(uint256 liquidity, uint256 secs) external returns (bytes32 kek_id);
    function withdraw(bytes32 kek_id, address destination_address) external returns (uint256 withdrawnAmount);
    function getRewards(address[] calldata rewardTokens) external returns (uint256[] memory rewardAmounts);
}

pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later
// STAX (interfaces/investments/frax-gauge/tranche/ITrancheRegistry.sol)

interface ITrancheRegistry {
    struct ImplementationDetails {
        // The reference tranche implementation which is to be cloned
        address implementation;

        // If true, new/additional locks cannot be added into this tranche type
        bool closedForStaking;

        // If true, no staking allowed and these tranches have no rewards
        // to claim or tokens to withdraw. So fully deprecated.
        bool disabled;
    }

    event TrancheCreated(uint256 indexed implId, address indexed tranche, address stakingAddress, address stakingToken);
    event TrancheImplCreated(uint256 indexed implId, address indexed implementation);
    event ImplementationDisabled(uint256 indexed implId, bool value);
    event ImplementationClosedForStaking(uint256 indexed implId, bool value);
    event AddedExistingTranche(uint256 indexed implId, address indexed tranche);

    error OnlyOwnerOperatorTranche(address caller);
    error InvalidTrancheImpl(uint256 implId);
    error TrancheAlreadyExists(address tranche);
    error UnknownTranche(address tranche);

    function createTranche(uint256 _implId) external returns (address tranche, address underlyingGaugeAddress, address stakingToken);
    function implDetails(uint256 _implId) external view returns (ImplementationDetails memory details);
    function execute(address _to, uint256 _value, bytes calldata _data) external returns (bytes memory);
}

pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later
// STAX (interfaces/external/curve/IFraxGauge.sol)

// ref: https://github.com/FraxFinance/frax-solidity/blob/master/src/hardhat/contracts/Staking/FraxUnifiedFarm_ERC20.sol

interface IFraxGauge {
    struct LockedStake {
        bytes32 kek_id;
        uint256 start_timestamp;
        uint256 liquidity;
        uint256 ending_timestamp;
        uint256 lock_multiplier; // 6 decimals of precision. 1x = 1000000
    }

    function stakeLocked(uint256 liquidity, uint256 secs) external;
    function lockAdditional(bytes32 kek_id, uint256 addl_liq) external;
    function withdrawLocked(bytes32 kek_id, address destination_address) external;

    function lockedStakesOf(address account) external view returns (LockedStake[] memory);
    function getAllRewardTokens() external view returns (address[] memory);
    function getReward(address destination_address) external returns (uint256[] memory);

    function stakerSetVeFXSProxy(address proxy_address) external;
    function stakerToggleMigrator(address migrator_address) external;

    function lock_time_min() external view returns (uint256);
    function lock_time_for_max_multiplier() external view returns (uint256);
}

pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later
// STAX (common/CommonEventsAndErrors.sol)

/// @notice A collection of common errors thrown within the STAX contracts
library CommonEventsAndErrors {
    error InsufficientBalance(address token, uint256 required, uint256 balance);
    error InvalidToken(address token);
    error InvalidParam();
    error InvalidAddress(address addr);
    error OnlyOwner(address caller);
    error OnlyOwnerOrOperators(address caller);

    event TokenRecovered(address indexed to, address indexed token, uint256 amount);
}

pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later
// STAX (common/Executable.sol)

/// @notice An inlined library function to add a generic execute() function to contracts.
/// @dev As this is a powerful funciton, care and consideration needs to be taken when 
///      adding into contracts, and on who can call.
library Executable {
    error UnknownFailure();

    /// @notice Call a function on another contract, where the msg.sender will be this contract
    /// @param _to The address of the contract to call
    /// @param _value Any eth to send
    /// @param _data The encoded function selector and args.
    /// @dev If the underlying function reverts, this willl revert where the underlying revert message will bubble up.
    function execute(
        address _to,
        uint256 _value,
        bytes calldata _data
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = _to.call{value: _value}(_data);
        
        if (success) {
            return returndata;
        } else if (returndata.length > 0) {
            // Look for revert reason and bubble it up if present
            // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol#L232
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert UnknownFailure();
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}