// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.2;

import {VaultAPI, BaseWrapperImplementation, RegistryAPI} from "BaseWrapperImplementation.sol";
import {ApeVaultFactory} from "ApeVaultFactory.sol";
import {ApeVaultWrapperImplementation} from "ApeVault.sol";
import {IERC20} from "IERC20.sol";
import {SafeERC20} from "SafeERC20.sol";
import "TimeLock.sol";

contract ApeRouter is TimeLock {
	using SafeERC20 for IERC20;


	uint256 constant MAX_UINT = type(uint256).max;

	address public yearnRegistry;
	address public apeVaultFactory;

	constructor(address _reg, address _factory, uint256 _minDelay) TimeLock(_minDelay)  {
		yearnRegistry = _reg;
		apeVaultFactory = _factory;
	}

	event DepositInVault(address indexed vault, address token, uint256 amount);
	event WithdrawFromVault(address indexed vault, address token, uint256 amount);
	event YearnRegistryUpdated(address registry);

	function delegateDepositYvTokens(address _apeVault, address _yvToken, address _token, uint256 _amount) external returns(uint256 deposited) {
		VaultAPI vault = VaultAPI(RegistryAPI(yearnRegistry).latestVault(_token));
		require(address(vault) != address(0), "ApeRouter: No vault for token");
		require(address(vault) == _yvToken, "ApeRouter: yvTokens don't match");
		require(ApeVaultFactory(apeVaultFactory).vaultRegistry(_apeVault), "ApeRouter: Vault does not exist");
		require(address(vault) == address(ApeVaultWrapperImplementation(_apeVault).vault()), "ApeRouter: yearn Vault not identical");

		IERC20(_yvToken).safeTransferFrom(msg.sender, _apeVault, _amount);
		deposited = vault.pricePerShare() * _amount / (10**uint256(vault.decimals()));
		ApeVaultWrapperImplementation(_apeVault).addFunds(deposited);
		emit DepositInVault(_apeVault, _token, _amount);
	}

	function delegateDeposit(address _apeVault, address _token, uint256 _amount) external returns(uint256 deposited) {
		VaultAPI vault = VaultAPI(RegistryAPI(yearnRegistry).latestVault(_token));
		require(address(vault) != address(0), "ApeRouter: No vault for token");
		require(ApeVaultFactory(apeVaultFactory).vaultRegistry(_apeVault), "ApeRouter: Vault does not exist");
		require(address(vault) == address(ApeVaultWrapperImplementation(_apeVault).vault()), "ApeRouter: yearn Vault not identical");

		IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);

		if (IERC20(_token).allowance(address(this), address(vault)) < _amount) {
			IERC20(_token).safeApprove(address(vault), 0); // Avoid issues with some IERC20(_token)s requiring 0
			IERC20(_token).safeApprove(address(vault), _amount); // Vaults are trusted
		}

		uint256 beforeBal = IERC20(_token).balanceOf(address(this));
        
		uint256 sharesMinted = vault.deposit(_amount, _apeVault);

		uint256 afterBal = IERC20(_token).balanceOf(address(this));
		deposited = beforeBal - afterBal;

		ApeVaultWrapperImplementation(_apeVault).addFunds(deposited);
		emit DepositInVault(_apeVault, _token, sharesMinted);
	}

	function delegateWithdrawal(address _recipient, address _apeVault, address _token, uint256 _shareAmount, bool _underlying) external{
		VaultAPI vault = VaultAPI(RegistryAPI(yearnRegistry).latestVault(_token));
		require(address(vault) != address(0), "ApeRouter: No vault for token");
		require(ApeVaultFactory(apeVaultFactory).vaultRegistry(msg.sender), "ApeRouter: Vault does not exist");
		require(address(vault) == address(ApeVaultWrapperImplementation(_apeVault).vault()), "ApeRouter: yearn Vault not identical");

		if (_underlying)
			vault.withdraw(_shareAmount, _recipient);
		else
			vault.transfer(_recipient, _shareAmount);
		emit WithdrawFromVault(address(vault), vault.token(), _shareAmount);
	}

	function removeTokens(address _token) external onlyOwner {
		IERC20(_token).safeTransfer(msg.sender, IERC20(_token).balanceOf(address(this)));
	}

	/**
		* @notice
		*  Used to update the yearn registry.
		* @param _registry The new _registry address.
		*/
	function setRegistry(address _registry) external itself {
		yearnRegistry = _registry;
		emit YearnRegistryUpdated(_registry);
	}
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.2;

import {IERC20} from "IERC20.sol";
import {SafeERC20} from "SafeERC20.sol";
import {Math} from "Math.sol";
import {SafeMath} from "SafeMath.sol";

struct StrategyParams {
    uint256 performanceFee;
    uint256 activation;
    uint256 debtRatio;
    uint256 minDebtPerHarvest;
    uint256 maxDebtPerHarvest;
    uint256 lastReport;
    uint256 totalDebt;
    uint256 totalGain;
    uint256 totalLoss;
}

interface VaultAPI is IERC20 {
    function name() external view returns (string calldata);

    function symbol() external view returns (string calldata);

    function decimals() external view returns (uint256);

    function apiVersion() external pure returns (string memory);

    function permit(
        address owner,
        address spender,
        uint256 amount,
        uint256 expiry,
        bytes calldata signature
    ) external returns (bool);

    // NOTE: Vyper produces multiple signatures for a given function with "default" args
    function deposit() external returns (uint256);

    function deposit(uint256 amount) external returns (uint256);

    function deposit(uint256 amount, address recipient) external returns (uint256);

    // NOTE: Vyper produces multiple signatures for a given function with "default" args
    function withdraw() external returns (uint256);

    function withdraw(uint256 maxShares) external returns (uint256);

    function withdraw(uint256 maxShares, address recipient) external returns (uint256);

    function token() external view returns (address);

    function strategies(address _strategy) external view returns (StrategyParams memory);

    function pricePerShare() external view returns (uint256);

    function totalAssets() external view returns (uint256);

    function depositLimit() external view returns (uint256);

    function maxAvailableShares() external view returns (uint256);

    /**
     * View how much the Vault would increase this Strategy's borrow limit,
     * based on its present performance (since its last report). Can be used to
     * determine expectedReturn in your Strategy.
     */
    function creditAvailable() external view returns (uint256);

    /**
     * View how much the Vault would like to pull back from the Strategy,
     * based on its present performance (since its last report). Can be used to
     * determine expectedReturn in your Strategy.
     */
    function debtOutstanding() external view returns (uint256);

    /**
     * View how much the Vault expect this Strategy to return at the current
     * block, based on its present performance (since its last report). Can be
     * used to determine expectedReturn in your Strategy.
     */
    function expectedReturn() external view returns (uint256);

    /**
     * This is the main contact point where the Strategy interacts with the
     * Vault. It is critical that this call is handled as intended by the
     * Strategy. Therefore, this function will be called by BaseStrategy to
     * make sure the integration is correct.
     */
    function report(
        uint256 _gain,
        uint256 _loss,
        uint256 _debtPayment
    ) external returns (uint256);

    /**
     * This function should only be used in the scenario where the Strategy is
     * being retired but no migration of the positions are possible, or in the
     * extreme scenario that the Strategy needs to be put into "Emergency Exit"
     * mode in order for it to exit as quickly as possible. The latter scenario
     * could be for any reason that is considered "critical" that the Strategy
     * exits its position as fast as possible, such as a sudden change in
     * market conditions leading to losses, or an imminent failure in an
     * external dependency.
     */
    function revokeStrategy() external;

    /**
     * View the governance address of the Vault to assert privileged functions
     * can only be called by governance. The Strategy serves the Vault, so it
     * is subject to governance defined by the Vault.
     */
    function governance() external view returns (address);

    /**
     * View the management address of the Vault to assert privileged functions
     * can only be called by management. The Strategy serves the Vault, so it
     * is subject to management defined by the Vault.
     */
    function management() external view returns (address);

    /**
     * View the guardian address of the Vault to assert privileged functions
     * can only be called by guardian. The Strategy serves the Vault, so it
     * is subject to guardian defined by the Vault.
     */
    function guardian() external view returns (address);
}


interface RegistryAPI {
    function governance() external view returns (address);

    function latestVault(address token) external view returns (address);

    function numVaults(address token) external view returns (uint256);

    function vaults(address token, uint256 deploymentId) external view returns (address);
}

/**
 * @title Yearn Base Wrapper
 * @author yearn.finance
 * @notice
 *  BaseWrapper implements all of the required functionality to interoperate
 *  closely with the Vault contract. This contract should be inherited and the
 *  abstract methods implemented to adapt the Wrapper.
 *  A good starting point to build a wrapper is https://github.com/yearn/brownie-wrapper-mix
 *
 */
abstract contract BaseWrapperImplementation {
    using Math for uint256;
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using SafeERC20 for VaultAPI;

    IERC20 public token;

    // Reduce number of external calls (SLOADs stay the same)
    VaultAPI[] private _cachedVaults;

    RegistryAPI public registry;

    // ERC20 Unlimited Approvals (short-circuits VaultAPI.transferFrom)
    uint256 constant UNLIMITED_APPROVAL = type(uint256).max;
    // Sentinal values used to save gas on deposit/withdraw/migrate
    // NOTE: DEPOSIT_EVERYTHING == WITHDRAW_EVERYTHING == MIGRATE_EVERYTHING
    uint256 constant DEPOSIT_EVERYTHING = type(uint256).max;
    uint256 constant WITHDRAW_EVERYTHING = type(uint256).max;
    uint256 constant MIGRATE_EVERYTHING = type(uint256).max;
    // VaultsAPI.depositLimit is unlimited
    uint256 constant UNCAPPED_DEPOSITS = type(uint256).max;

    /**
     * @notice
     *  Used to update the yearn registry.
     * @param _registry The new _registry address.
     */
    function setRegistry(address _registry) external {
        require(msg.sender == registry.governance());
        // In case you want to override the registry instead of re-deploying
        registry = RegistryAPI(_registry);
        // Make sure there's no change in governance
        // NOTE: Also avoid bricking the wrapper from setting a bad registry
        require(msg.sender == registry.governance());
    }

    /**
     * @notice
     *  Used to get the most revent vault for the token using the registry.
     * @return An instance of a VaultAPI
     */
    function bestVault() public view virtual returns (VaultAPI) {
        return VaultAPI(registry.latestVault(address(token)));
    }

    /**
     * @notice
     *  Used to get all vaults from the registery for the token
     * @return An array containing instances of VaultAPI
     */
    function allVaults() public view virtual returns (VaultAPI[] memory) {
        uint256 cache_length = _cachedVaults.length;
        uint256 num_vaults = registry.numVaults(address(token));

        // Use cached
        if (cache_length == num_vaults) {
            return _cachedVaults;
        }

        VaultAPI[] memory vaults = new VaultAPI[](num_vaults);

        for (uint256 vault_id = 0; vault_id < cache_length; vault_id++) {
            vaults[vault_id] = _cachedVaults[vault_id];
        }

        for (uint256 vault_id = cache_length; vault_id < num_vaults; vault_id++) {
            vaults[vault_id] = VaultAPI(registry.vaults(address(token), vault_id));
        }

        return vaults;
    }

    function _updateVaultCache(VaultAPI[] memory vaults) internal {
        // NOTE: even though `registry` is update-able by Yearn, the intended behavior
        //       is that any future upgrades to the registry will replay the version
        //       history so that this cached value does not get out of date.
        if (vaults.length > _cachedVaults.length) {
            _cachedVaults = vaults;
        }
    }

    /**
     * @notice
     *  Used to get the balance of an account accross all the vaults for a token.
     *  @dev will be used to get the wrapper balance using totalVaultBalance(address(this)).
     *  @param account The address of the account.
     *  @return balance of token for the account accross all the vaults.
     */
    function totalVaultBalance(address account) public view returns (uint256 balance) {
        VaultAPI[] memory vaults = allVaults();

        for (uint256 id = 0; id < vaults.length; id++) {
            balance = balance.add(vaults[id].balanceOf(account).mul(vaults[id].pricePerShare()).div(10**uint256(vaults[id].decimals())));
        }
    }

    /**
     * @notice
     *  Used to get the TVL on the underlying vaults.
     *  @return assets the sum of all the assets managed by the underlying vaults.
     */
    function totalAssets() public view returns (uint256 assets) {
        VaultAPI[] memory vaults = allVaults();

        for (uint256 id = 0; id < vaults.length; id++) {
            assets = assets.add(vaults[id].totalAssets());
        }
    }

    function _deposit(
        address depositor,
        address receiver,
        uint256 amount, // if `MAX_UINT256`, just deposit everything
        bool pullFunds // If true, funds need to be pulled from `depositor` via `transferFrom`
    ) internal returns (uint256 deposited) {
        VaultAPI _bestVault = bestVault();

        if (pullFunds) {
            if (amount != DEPOSIT_EVERYTHING) {
                token.safeTransferFrom(depositor, address(this), amount);
            } else {
                token.safeTransferFrom(depositor, address(this), token.balanceOf(depositor));
            }
        }

        if (token.allowance(address(this), address(_bestVault)) < amount) {
            token.safeApprove(address(_bestVault), 0); // Avoid issues with some tokens requiring 0
            token.safeApprove(address(_bestVault), UNLIMITED_APPROVAL); // Vaults are trusted
        }

        // Depositing returns number of shares deposited
        // NOTE: Shortcut here is assuming the number of tokens deposited is equal to the
        //       number of shares credited, which helps avoid an occasional multiplication
        //       overflow if trying to adjust the number of shares by the share price.
        uint256 beforeBal = token.balanceOf(address(this));
        if (receiver != address(this)) {
            _bestVault.deposit(amount, receiver);
        } else if (amount != DEPOSIT_EVERYTHING) {
            _bestVault.deposit(amount);
        } else {
            _bestVault.deposit();
        }

        uint256 afterBal = token.balanceOf(address(this));
        deposited = beforeBal.sub(afterBal);
        // `receiver` now has shares of `_bestVault` as balance, converted to `token` here
        // Issue a refund if not everything was deposited
        if (depositor != address(this) && afterBal > 0) token.safeTransfer(depositor, afterBal);
    }

    function _withdraw(
        address sender,
        address receiver,
        uint256 amount, // if `MAX_UINT256`, just withdraw everything
        bool withdrawFromBest // If true, also withdraw from `_bestVault`
    ) internal returns (uint256 withdrawn) {
        VaultAPI _bestVault = bestVault();

        VaultAPI[] memory vaults = allVaults();
        _updateVaultCache(vaults);

        // NOTE: This loop will attempt to withdraw from each Vault in `allVaults` that `sender`
        //       is deposited in, up to `amount` tokens. The withdraw action can be expensive,
        //       so it if there is a denial of service issue in withdrawing, the downstream usage
        //       of this wrapper contract must give an alternative method of withdrawing using
        //       this function so that `amount` is less than the full amount requested to withdraw
        //       (e.g. "piece-wise withdrawals"), leading to less loop iterations such that the
        //       DoS issue is mitigated (at a tradeoff of requiring more txns from the end user).
        for (uint256 id = 0; id < vaults.length; id++) {
            if (!withdrawFromBest && vaults[id] == _bestVault) {
                continue; // Don't withdraw from the best
            }

            // Start with the total shares that `sender` has
            uint256 availableShares = vaults[id].balanceOf(sender);

            // Restrict by the allowance that `sender` has to this contract
            // NOTE: No need for allowance check if `sender` is this contract
            if (sender != address(this)) {
                availableShares = Math.min(availableShares, vaults[id].allowance(sender, address(this)));
            }

            // Limit by maximum withdrawal size from each vault
            availableShares = Math.min(availableShares, vaults[id].maxAvailableShares());

            if (availableShares > 0) {
                // Intermediate step to move shares to this contract before withdrawing
                // NOTE: No need for share transfer if this contract is `sender`
                // if (sender != address(this)) vaults[id].transferFrom(sender, address(this), availableShares);

                if (amount != WITHDRAW_EVERYTHING) {
                    // Compute amount to withdraw fully to satisfy the request
                    uint256 estimatedShares =
                        amount
                            .sub(withdrawn) // NOTE: Changes every iteration
                            .mul(10**uint256(vaults[id].decimals()))
                            .div(vaults[id].pricePerShare()); // NOTE: Every Vault is different

                    // Limit amount to withdraw to the maximum made available to this contract
                    // NOTE: Avoid corner case where `estimatedShares` isn't precise enough
                    // NOTE: If `0 < estimatedShares < 1` but `availableShares > 1`, this will withdraw more than necessary
                    if (estimatedShares > 0 && estimatedShares < availableShares) {
                        if (sender != address(this)) vaults[id].safeTransferFrom(sender, address(this), estimatedShares);
                        withdrawn = withdrawn.add(vaults[id].withdraw(estimatedShares));
                    } else {
                        if (sender != address(this)) vaults[id].safeTransferFrom(sender, address(this), availableShares);
                        withdrawn = withdrawn.add(vaults[id].withdraw(availableShares));
                    }
                } else {
                    if (sender != address(this)) vaults[id].safeTransferFrom(sender, address(this), availableShares);
                    withdrawn = withdrawn.add(vaults[id].withdraw());
                }

                // Check if we have fully satisfied the request
                // NOTE: use `amount = WITHDRAW_EVERYTHING` for withdrawing everything
                if (amount <= withdrawn) break; // withdrawn as much as we needed
            }
        }

        // If we have extra, deposit back into `_bestVault` for `sender`
        // NOTE: Invariant is `withdrawn <= amount`
        if (withdrawn > amount && withdrawn.sub(amount) > _bestVault.pricePerShare().div(10**_bestVault.decimals())) {
            // Don't forget to approve the deposit
            if (token.allowance(address(this), address(_bestVault)) < withdrawn.sub(amount)) {
                token.safeApprove(address(_bestVault), UNLIMITED_APPROVAL); // Vaults are trusted
            }

            _bestVault.deposit(withdrawn.sub(amount), sender);
            withdrawn = amount;
        }

        // `receiver` now has `withdrawn` tokens as balance
        if (receiver != address(this)) token.safeTransfer(receiver, withdrawn);
    }

    function _migrate(address account) internal returns (uint256) {
        return _migrate(account, MIGRATE_EVERYTHING);
    }

    function _migrate(address account, uint256 amount) internal returns (uint256) {
        // NOTE: In practice, it was discovered that <50 was the maximum we've see for this variance
        return _migrate(account, amount, 0);
    }

    function _migrate(
        address account,
        uint256 amount,
        uint256 maxMigrationLoss
    ) internal returns (uint256 migrated) {
        VaultAPI _bestVault = bestVault();

        // NOTE: Only override if we aren't migrating everything
        uint256 _depositLimit = _bestVault.depositLimit();
        uint256 _totalAssets = _bestVault.totalAssets();
        if (_depositLimit <= _totalAssets) return 0; // Nothing to migrate (not a failure)

        uint256 _amount = amount;
        if (_depositLimit < UNCAPPED_DEPOSITS && _amount < WITHDRAW_EVERYTHING) {
            // Can only deposit up to this amount
            uint256 _depositLeft = _depositLimit.sub(_totalAssets);
            if (_amount > _depositLeft) _amount = _depositLeft;
        }

        if (_amount > 0) {
            // NOTE: `false` = don't withdraw from `_bestVault`
            uint256 withdrawn = _withdraw(account, address(this), _amount, false);
            if (withdrawn == 0) return 0; // Nothing to migrate (not a failure)

            // NOTE: `false` = don't do `transferFrom` because it's already local
            migrated = _deposit(address(this), account, withdrawn, false);
            // NOTE: Due to the precision loss of certain calculations, there is a small inefficency
            //       on how migrations are calculated, and this could lead to a DoS issue. Hence, this
            //       value is made to be configurable to allow the user to specify how much is acceptable
            require(withdrawn.sub(migrated) <= maxMigrationLoss);
        } // else: nothing to migrate! (not a failure)
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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

import "IERC20.sol";
import "Address.sol";

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

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.2;

import "ApeVault.sol";
import "VaultProxy.sol";

contract ApeVaultFactory {
	mapping(address => bool) public vaultRegistry;

	address public yearnRegistry;
	address public apeRegistry;
	address public beacon;

	event VaultCreated(address vault);

	constructor(address _reg, address _apeReg, address _beacon) {
		apeRegistry = _apeReg;
		yearnRegistry = _reg;
		beacon = _beacon;
	}

	function createCoVault(address _token, address _simpleToken) external {
		bytes memory data = abi.encodeWithSignature("init(address,address,address,address,address)", apeRegistry, _token, yearnRegistry, _simpleToken, msg.sender);
		VaultProxy proxy = new VaultProxy(beacon, msg.sender, data);
		vaultRegistry[address(proxy)] = true;
		emit VaultCreated(address(proxy));
	}
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.2;

import "IApeVault.sol";
import "ApeDistributor.sol";
import "ApeAllowanceModule.sol";
import "ApeRegistry.sol";
import "FeeRegistry.sol";
import "ApeRouter.sol";

import "BaseWrapperImplementation.sol";

abstract contract OwnableImplementation {
    address internal _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

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
        require(owner() == msg.sender, "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract ApeVaultWrapperImplementation is BaseWrapperImplementation, OwnableImplementation {
	using SafeERC20 for VaultAPI;
	using SafeERC20 for IERC20;

	uint256 constant TOTAL_SHARES = 10000;
	
	IERC20 public simpleToken;

	bool internal setup;
	uint256 public underlyingValue;
	address public apeRegistry;
	VaultAPI public vault;

	function init(
		address _apeRegistry,
		address _token,
		address _registry,
		address _simpleToken,
		address _newOwner) external {
		require(!setup);
		require(_token != address(0) || _simpleToken != address(0));
		setup = true;
		apeRegistry = _apeRegistry;
		if (_token != address(0))
			vault = VaultAPI(RegistryAPI(_registry).latestVault(_token));
		simpleToken = IERC20(_simpleToken);

		// Recommended to use a token with a `Registry.latestVault(_token) != address(0)`
		token = IERC20(_token);
		// Recommended to use `v2.registry.ychad.eth`
		registry = RegistryAPI(_registry);
		_owner = _newOwner;
		emit OwnershipTransferred(address(0), _newOwner);
	}

	event ApeVaultFundWithdrawal(address indexed apeVault, address vault, uint256 _amount, bool underlying);

	modifier onlyDistributor() {
		require(msg.sender == ApeRegistry(apeRegistry).distributor());
		_;
	}

	modifier onlyRouter() {
		require(msg.sender == ApeRegistry(apeRegistry).router());
		_;
	}

	function shareValue(uint256 numShares) public view returns (uint256) {
		return vault.pricePerShare() * numShares / (10**uint256(vault.decimals()));
	}

	function sharesForValue(uint256 amount) public view returns (uint256) {
		return amount * (10**uint256(vault.decimals())) / vault.pricePerShare();
	}

	/**  
	 * @notice
	 * Used to measure profits made compared to funds send to the vault
	 * Returns 0 if negative
	 */
	function profit() public view returns(uint256) {
		uint256 totalValue = shareValue(vault.balanceOf(address(this)));
		if (totalValue <= underlyingValue)
			return 0;
		else
			return totalValue - underlyingValue;
	}

	/**  
	 * @notice
	 * Used to withdraw non yield bearing tokens
	 * @param _amount Amount of simpleToken to withdraw
	 */
	function apeWithdrawSimpleToken(uint256 _amount) public onlyOwner {
		simpleToken.safeTransfer(msg.sender, _amount);
	}

	/**  
	 * @notice
	 * Used to withdraw yield bearing token
	 * @param _shareAmount Amount of yield bearing token to withdraw
	 * @param _underlying boolean to know if we redeem shares or not
	 */
	function apeWithdraw(uint256 _shareAmount, bool _underlying) external onlyOwner {
		uint256 underlyingAmount = shareValue(_shareAmount);
		require(underlyingAmount <= underlyingValue, "underlying amount higher than vault value");

		address router = ApeRegistry(apeRegistry).router();
		underlyingValue -= underlyingAmount;
		vault.safeTransfer(router, _shareAmount);
		ApeRouter(router).delegateWithdrawal(owner(), address(this), vault.token(), _shareAmount, _underlying);
	}

	/**  
	 * @notice
	 * Used to withdraw all yield bearing token
	 * @param _underlying boolean to know if we redeem shares or not
	 */
	function exitVaultToken(bool _underlying) external onlyOwner {
		underlyingValue = 0;
		uint256 totalShares = vault.balanceOf(address(this));
		address router = ApeRegistry(apeRegistry).router();
		vault.safeTransfer(router, totalShares);
		ApeRouter(router).delegateWithdrawal(owner(), address(this), vault.token(), totalShares, _underlying);
	}

	/**  
	 * @notice
	 * Used to migrate yearn vault. _migrate(address) takes the address of the receiver of the funds, in our case, the contract itself.
	 * It is expected that the receiver is the vault
	 */
	function apeMigrate() external onlyOwner returns(uint256 migrated){
		migrated = _migrate(address(this));
		vault = VaultAPI(registry.latestVault(address(token)));
	}

	/**  
	 * @notice
	 * Used to take funds from vault into the distributor (can only be called by distributor)
	 * @param _value Amount of funds to take
	 * @param _type The type of tap performed on the vault
	 */
	function tap(uint256 _value, uint8 _type) external onlyDistributor returns(uint256) {
		if (_type == uint8(0)) {
			_tapOnlyProfit(_value, msg.sender);
			return _value;
		}
		else if (_type == uint8(1)) {
			_tapBase(_value, msg.sender);
			return _value;
		}
		else if (_type == uint8(2))
			_tapSimpleToken(_value, msg.sender);
		return (0);
	}


	/**  
	 * @notice
	 * Used to take funds from vault purely from profit made from yearn yield
	 * @param _tapValue Amount of funds to take
	 * @param _recipient recipient of funds (always distributor)
	 */
	function _tapOnlyProfit(uint256 _tapValue, address _recipient) internal {
		uint256 fee = FeeRegistry(ApeRegistry(apeRegistry).feeRegistry()).getVariableFee(_tapValue, _tapValue);
		uint256 finalTapValue = _tapValue + _tapValue * fee / TOTAL_SHARES;
		require(shareValue(finalTapValue) <= profit(), "Not enough profit to cover epoch");
		vault.safeTransfer(_recipient, _tapValue);
		vault.safeTransfer(ApeRegistry(apeRegistry).treasury(), _tapValue * fee / TOTAL_SHARES);
	}

	/**  
	 * @notice
	 * Used to take funds from vault by deducting a part from profits
	 * @param _tapValue Amount of funds to take
	 * @param _recipient recipient of funds (always distributor)
	 */
	function _tapBase(uint256 _tapValue, address _recipient) internal {
		uint256 underlyingTapValue = shareValue(_tapValue);
		uint256 profit_ = profit();
		uint256 fee = FeeRegistry(ApeRegistry(apeRegistry).feeRegistry()).getVariableFee(profit_, underlyingTapValue);
		uint256 finalTapValue = underlyingTapValue + underlyingTapValue * fee / TOTAL_SHARES;
		if (finalTapValue > profit_)
			underlyingValue -= finalTapValue - profit_;
		vault.safeTransfer(_recipient, _tapValue);
		vault.safeTransfer(ApeRegistry(apeRegistry).treasury(), _tapValue * fee / TOTAL_SHARES);
	}

	/**  
	 * @notice
	 * Used to take funds simple token
	 * @param _tapValue Amount of funds to take
	 * @param _recipient recipient of funds (always distributor)
	 */
	function _tapSimpleToken(uint256 _tapValue, address _recipient) internal {
		uint256 feeAmount = _tapValue * FeeRegistry(ApeRegistry(apeRegistry).feeRegistry()).staticFee() / TOTAL_SHARES;
		simpleToken.safeTransfer(_recipient, _tapValue);
		simpleToken.safeTransfer(ApeRegistry(apeRegistry).treasury(), feeAmount);
	}

	/**  
	 * @notice
	 * Used to correct change the amount of underlying funds held by the ape Vault
	 */
	function syncUnderlying() external onlyOwner {
		underlyingValue = shareValue(vault.balanceOf(address(this)));
	}

	/**  
	 * @notice
	 * Used to add the correct amount of funds from the router, only callable by router
	 * @param _amount amount of undelrying funds to add
	 */
	function addFunds(uint256 _amount) external onlyRouter {
		underlyingValue += _amount;
	}

	/**  
	 * @notice
	 * Used to approve an admin to fund/finalise epochs from this vault to a specific circle
	 * @param _circle Circle who will benefit from this vault
	 * @param _admin address that can finalise epochs
	 */
	function updateCircleAdmin(bytes32 _circle, address _admin) external onlyOwner {
		ApeDistributor(ApeRegistry(apeRegistry).distributor()).updateCircleAdmin(_circle, _admin);
	}

	/**  
	 * @notice
	 * Used to update the allowance of a circle that the vault funds
	 * @param _circle Circle who will benefit from this vault
	 * @param _amount Max amount of funds available per epoch
	 * @param _interval Seconds in between each epochs
	 * @param _epochAmount Amount of epochs to fund (0 means you're at least funding one epoch)
	 * If you want to stop funding a circle, set _amount to 0
	 * @param _intervalStart Unix timestamp fromw hich epoch starts (block.timestamp if 0)
	 */
	function updateAllowance(
		bytes32 _circle,
		address _token,
		uint256 _amount,
		uint256 _interval,
		uint256 _epochAmount,
		uint256 _intervalStart
		) external onlyOwner {
		ApeDistributor(
			ApeRegistry(apeRegistry).distributor()
		).setAllowance(_circle, _token, _amount, _interval, _epochAmount, _intervalStart);
	}
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.2;

interface IApeVault {
	function tap(uint256 _tapValue, uint256 _slippage, uint8 _type) external;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.2;

import "Ownable.sol";
import "MerkleProof.sol";
import "IERC20.sol";
import "SafeERC20.sol";
import "ApeRegistry.sol";
import "ApeVault.sol";
import "ApeAllowanceModule.sol";
import {VaultAPI} from "BaseWrapperImplementation.sol";

contract ApeDistributor is ApeAllowanceModule {
	using MerkleProof for bytes32[];
	using SafeERC20 for IERC20;

	struct ClaimData {
		address vault;
		bytes32 circle;
		address token;
		uint256 epoch;
		uint256 index;
		address account;
		uint256 checkpoint;
		bool redeemShare;
		bytes32[] proof;
	}

	address public registry;

	// address to approve admins for a circle
	// vault => circle => admin address
	mapping(address => mapping(bytes32 => address)) public vaultApprovals;


	// roots following this mapping:
	// vault address => circle ID => token address => epoch ID => root
	mapping(address => mapping(bytes32 => mapping(address => mapping(uint256 => bytes32)))) public epochRoots;
	mapping(bytes32 => mapping(address => uint256)) public epochTracking;
	mapping(address => mapping(bytes32 => mapping(address => mapping(uint256 => mapping(uint256 => uint256))))) public epochClaimBitMap;

	mapping(address => mapping(bytes32 => mapping(address => uint256))) public circleAlloc;

	// checkpoints following this mapping:
	// circle => token => address => checkpoint
	mapping(address => mapping(bytes32 => mapping(address => mapping(address => uint256)))) public checkpoints;

	event AdminApproved(address indexed vault, bytes32 indexed circle, address indexed admin);

	event Claimed(address vault, bytes32 circle, address token, uint256 epoch, uint256 index, address account, uint256 amount);
	
	event EpochFunded(address indexed vault, bytes32 indexed circle, address indexed token, uint256 epochId, uint8 _tapType, uint256 amount);

	event yearnApeVaultFundsTapped(address indexed apeVault, address yearnVault, uint256 amount);

	constructor(address _registry) {
		registry = _registry;
	}

	function _tap(
		address _vault,
		bytes32 _circle,
		address _token,
		uint256 _amount,
		uint8 _tapType,
		bytes32 _root
	) internal {
		require(ApeVaultFactory(ApeRegistry(registry).factory()).vaultRegistry(_vault), "ApeDistributor: Vault does not exist");
		bool isOwner = ApeVaultWrapperImplementation(_vault).owner() == msg.sender;
		require(vaultApprovals[_vault][_circle] == msg.sender || isOwner, "ApeDistributor: Sender not approved");
		
		if (_tapType == uint8(2))
			require(address(ApeVaultWrapperImplementation(_vault).simpleToken()) == _token, "ApeDistributor: Vault cannot supply token");
		else
			require(address(ApeVaultWrapperImplementation(_vault).vault()) == _token, "ApeDistributor: Vault cannot supply token");
			
		if (!isOwner)
			_isTapAllowed(_vault, _circle, _token, _amount);
		
		uint256 beforeBal = IERC20(_token).balanceOf(address(this));
		uint256 sharesRemoved = ApeVaultWrapperImplementation(_vault).tap(_amount, _tapType);
		uint256 afterBal = IERC20(_token).balanceOf(address(this));
		require(afterBal - beforeBal == _amount, "ApeDistributor: Did not receive correct amount of tokens");

		if (sharesRemoved > 0)
			emit yearnApeVaultFundsTapped(_vault, address(ApeVaultWrapperImplementation(_vault).vault()), sharesRemoved);
		
		uint256 epoch = epochTracking[_circle][_token];
		epochRoots[_vault][_circle][_token][epoch] = _root;
		epochTracking[_circle][_token]++;

		emit EpochFunded(_vault, _circle, _token, epoch, _tapType, _amount);
	}

	/**  
	 * @notice
	 * Used to allow a circle to supply an epoch with funds from a given ape vault
	 * @param _vault Address of ape vault from which to take funds from
	 * @param _circle Circle ID querying the funds
	 * @param _token Address of the token to withdraw from the vault
	 * @param _root Merkle root of the current circle's epoch
	 * @param _amount Amount of tokens to withdraw
	 * @param _tapType Ape vault's type tap (pure profit, mixed, simple token)
	 */
	function uploadEpochRoot(
		address _vault,
		bytes32 _circle,
		address _token,
		bytes32 _root,
		uint256 _amount,
		uint8 _tapType)
		external {
		_tap(_vault, _circle, _token, _amount, _tapType, _root);

		circleAlloc[_vault][_circle][_token] += _amount;
	}

	function sum(uint256[] calldata _vals) internal pure returns(uint256 res) {
		for (uint256 i = 0; i < _vals.length; i++)
			res += _vals[i];
	}

	/**  
	* @notice
	* Used to distribute funds from an epoch directly to users
	* @param _vault Address of ape vault from which to take funds from
	* @param _circle Circle ID querying the funds
	* @param _token Address of the token to withdraw from the vault
	* @param _users Users to receive tokens
	* @param _amounts Tokens to give per user
	* @param _amount Amount of tokens to withdraw
	* @param _tapType Ape vault's type tap (pure profit, mixed, simple token)
	*/
	function tapEpochAndDistribute(
		address _vault,
		bytes32 _circle,
		address _token,
		address[] calldata _users,
		uint256[] calldata _amounts,
		uint256 _amount,
		uint8 _tapType)
		external {
		require(_users.length == _amounts.length, "ApeDistributor: Array lengths do not match");
		require(sum(_amounts) == _amount, "ApeDistributor: Amount does not match sum of values");

		_tap(_vault, _circle, _token, _amount, _tapType, bytes32(type(uint256).max));

		for (uint256 i = 0; i < _users.length; i++)
			IERC20(_token).safeTransfer(_users[i], _amounts[i]);
	}

	/**  
	 * @notice
	 * Used to allow an ape vault owner to set an admin for a circle
	 * @param _circle Circle ID of future admin
	 * @param _admin Address of allowed admin to call `uploadEpochRoot`
	 */
	function updateCircleAdmin(bytes32 _circle, address _admin) external {
		vaultApprovals[msg.sender][_circle] = _admin;
		emit AdminApproved(msg.sender, _circle, _admin);
	}

	function isClaimed(address _vault, bytes32 _circle, address _token, uint256 _epoch, uint256 _index) public view returns(bool) {
		uint256 wordIndex = _index / 256;
		uint256 bitIndex = _index % 256;
		uint256 word = epochClaimBitMap[_vault][_circle][_token][_epoch][wordIndex];
		uint256 bitMask = 1 << bitIndex;
		return word & bitMask == bitMask;
	}

	function _setClaimed(address _vault, bytes32 _circle, address _token, uint256 _epoch, uint256 _index) internal {
		uint256 wordIndex = _index / 256;
		uint256 bitIndex = _index % 256;
		epochClaimBitMap[_vault][_circle][_token][_epoch][wordIndex] |= 1 << bitIndex;
	}

	/**  
	 * @notice
	 * Used to allow circle users to claim their allocation of a given epoch
	 * @param _circle Circle ID of the user
	 * @param _token Address of token claimed
	 * @param _epoch Epoch ID associated to the claim
	 * @param _index Position of user's address in the merkle tree
	 * @param _account Address of user
	 * @param _checkpoint Total amount of tokens claimed by user (enables to claim multiple epochs at once)
	 * @param _redeemShares Boolean to allow user to redeem underlying tokens of a yearn vault (prerequisite: _token must be a yvToken)
	 * @param _proof Merkle proof to verify user is entitled to claim
	 */
	function claim(address _vault, bytes32 _circle, address _token, uint256 _epoch, uint256 _index, address _account, uint256 _checkpoint, bool _redeemShares, bytes32[] memory _proof) public {
		require(!isClaimed(_vault, _circle, _token, _epoch, _index), "Claimed already");
		bytes32 node = keccak256(abi.encodePacked(_index, _account, _checkpoint));
		require(_proof.verify(epochRoots[_vault][_circle][_token][_epoch], node), "Wrong proof");
		uint256 currentCheckpoint = checkpoints[_vault][_circle][_token][_account];
		require(_checkpoint > currentCheckpoint, "Given checkpoint not higher than current checkpoint");

		uint256 claimable = _checkpoint - currentCheckpoint;
		require(claimable <= circleAlloc[_vault][_circle][_token], "Can't claim more than circle has to give");
		circleAlloc[_vault][_circle][_token] -= claimable;
		checkpoints[_vault][_circle][_token][_account] = _checkpoint;
		_setClaimed(_vault, _circle, _token, _epoch, _index);
		if (_redeemShares && msg.sender == _account)
			VaultAPI(_token).withdraw(claimable, _account);
		else
			IERC20(_token).safeTransfer(_account, claimable);
		emit Claimed(_vault, _circle, _token, _epoch, _index, _account, claimable);
	}

	/**
	 * @notice
	 * Used to allow circle users to claim many tokens at once if applicable
	 * Operated similarly to the `claim` function but due to "Stack too deep errors",
	 * input data was concatenated into similar typed arrays
	 * @param _claims Array of ClaimData objects to claim tokens of users
	 */
	function claimMany(ClaimData[] memory _claims) external {
		for(uint256 i = 0; i < _claims.length; i++) {
			claim(
				_claims[i].vault,
				_claims[i].circle,
				_claims[i].token,
				_claims[i].epoch,
				_claims[i].index,
				_claims[i].account,
				_claims[i].checkpoint,
				_claims[i].redeemShare,
				_claims[i].proof
				);
		}
	}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "Context.sol";
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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle trees (hash trees),
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(bytes32[] memory proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.2;

import "TimeLock.sol";

contract ApeRegistry is TimeLock {
	address public feeRegistry;
	address public router;
	address public distributor;
	address public factory;
	address public treasury;

	event FeeRegistryChanged(address feeRegistry);
	event RouterChanged(address router);
	event DistributorChanged(address distributor);
	event FactoryChanged(address factory);
	event TreasuryChanged(address treasury);

	constructor(address _treasury, uint256 _minDelay) TimeLock(_minDelay) {
		treasury = _treasury;
		emit TreasuryChanged(_treasury);
	}

	function setFeeRegistry(address _registry) external itself {
		feeRegistry = _registry;
		emit FeeRegistryChanged(_registry);
	}

	function setRouter(address _router) external itself {
		router = _router;
		emit RouterChanged(_router);
	}

	function setDistributor(address _distributor) external itself {
		distributor = _distributor;
		emit DistributorChanged(_distributor);
	}

	function setFactory(address _factory) external itself {
		factory = _factory;
		emit FactoryChanged(_factory);
	}

	function setTreasury(address _treasury) external itself {
		treasury = _treasury;
		emit TreasuryChanged(_treasury);
	}
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.2;

import "Ownable.sol";

contract TimeLock is Ownable {
	uint256 internal constant _DONE_TIMESTAMP = uint256(1);

	mapping(bytes32 => uint256) public timestamps;
	uint256 public minDelay;

	event CallScheduled(
        bytes32 indexed id,
        address target,
        bytes data,
        bytes32 predecessor,
        uint256 delay
    );

	event CallCancelled(bytes32 id);

	event CallExecuted(bytes32 indexed id, address target, bytes data);

	constructor(uint256 _minDelay) {
		minDelay = _minDelay;
	}


	modifier itself() {
		require(msg.sender == address(this), "TimeLock: Caller is not contract itself");
		_;
	}

	function changeMinDelay(uint256 _min) external itself {
		minDelay = _min;
	}

	function hashOperation(address _target, bytes calldata _data, bytes32 _predecessor, bytes32 _salt) internal pure returns(bytes32) {
		return keccak256(abi.encode(_target, _data, _predecessor, _salt));
	}

	function isPendingCall(bytes32 _id) public view returns(bool) {
		return timestamps[_id] > _DONE_TIMESTAMP;
	}

	function isDoneCall(bytes32 _id) public view returns(bool) {
		return timestamps[_id] == _DONE_TIMESTAMP;
	}

	function isReadyCall(bytes32 _id) public view returns(bool) {
		return timestamps[_id] <= block.timestamp && timestamps[_id] > _DONE_TIMESTAMP;
	}

	function schedule(address _target, bytes calldata _data, bytes32 _predecessor, bytes32 _salt, uint256 _delay) external onlyOwner {
		bytes32 id = hashOperation(_target, _data, _predecessor, _salt);
		require(timestamps[id] == 0, "TimeLock: Call already scheduled");
		require(_delay >= minDelay, "TimeLock: Insufficient delay");
		timestamps[id] = block.timestamp + _delay;
		emit CallScheduled(id, _target, _data, _predecessor, _delay);
	}

	function cancel(bytes32 _id) external onlyOwner {
		require(isPendingCall(_id), "TimeLock: Call is not pending");
		timestamps[_id] = 0;
		emit CallCancelled(_id);
	}

	function execute(address _target, bytes calldata _data, bytes32 _predecessor, bytes32 _salt, uint256 _delay) external onlyOwner {
		bytes32 id = hashOperation(_target, _data, _predecessor, _salt);
		require(isReadyCall(id), "TimeLock: Not ready for execution or executed");
		require(_predecessor == bytes32(0) || isDoneCall(_predecessor), "TimeLock: Predecessor call not executed");
		timestamps[id] = _DONE_TIMESTAMP;
		_call(id, _target, _data);
	}

	function _call(
        bytes32 id,
        address target,
        bytes calldata data
    ) internal {
        (bool success, ) = target.call(data);
        require(success, "Timelock: underlying transaction reverted");

        emit CallExecuted(id, target, data);
    }

}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.2;

abstract contract ApeAllowanceModule {

	struct Allowance {
		uint256 maxAmount;
		uint256 cooldownInterval;
	}

	struct CurrentAllowance {
		uint256 debt;
		uint256 intervalStart;
		uint256 epochs;
	}

	// vault => circle => token => allowance
	mapping(address => mapping(bytes32 => mapping(address => Allowance))) public allowances;
	mapping(address => mapping(bytes32 => mapping(address => CurrentAllowance))) public currentAllowances;

	event AllowanceUpdated(address vault, bytes32 circle, address token, uint256 amount, uint256 interval);


	/**  
	 * @notice
	 * Used to set an allowance of a circle from an ape vault.
	 * Setting _epochs at 0 with a non-zero _amount entitles the circle to one epoch of funds
	 * @param _circle Circle ID receiving the allowance
	 * @param _token Address of token to allocate
	 * @param _amount Amount to take out at most
	 * @param _cooldownInterval Duration of an epoch in seconds
	 * @param _epochs Amount of epochs to fund. Expected_funded_epochs = _epochs + 1
	 * @param _intervalStart Unix timestamp fromw hich epoch starts (block.timestamp if 0)
	 */
	function setAllowance(
		bytes32 _circle,
		address _token,
		uint256 _amount,
		uint256 _cooldownInterval,
		uint256 _epochs,
		uint256 _intervalStart
		) external {
		uint256 _now = block.timestamp;
		if (_intervalStart == 0)
			_intervalStart = _now;
		require(_intervalStart >= _now, "Interval start in the past");
		allowances[msg.sender][_circle][_token] = Allowance({
			maxAmount: _amount,
			cooldownInterval: _cooldownInterval
		});
		currentAllowances[msg.sender][_circle][_token] = CurrentAllowance({
			debt: 0,
			intervalStart: _intervalStart,
			epochs: _epochs
		});
		emit AllowanceUpdated(msg.sender, _circle, _token, _amount, _cooldownInterval);
	}

	/**  
	 * @notice
	 * Used to check and update if a circle can take funds out of an ape vault
	 * @param _vault Address of vault to take funds from
	 * @param _circle Circle ID querying the funds
	 * @param _token Address of token to take out
	 * @param _amount Amount to take out
	 */
	function _isTapAllowed(
		address _vault,
		bytes32 _circle,
		address _token,
		uint256 _amount
		) internal {
		Allowance memory allowance = allowances[_vault][_circle][_token];
		CurrentAllowance storage currentAllowance = currentAllowances[_vault][_circle][_token];
		require(_amount <= allowance.maxAmount, "Amount tapped exceed max allowance");
		require(block.timestamp >= currentAllowance.intervalStart, "Epoch has not started");

		if (currentAllowance.debt + _amount > allowance.maxAmount)
			_updateInterval(currentAllowance, allowance);
		currentAllowance.debt += _amount;
	}

	function _updateInterval(CurrentAllowance storage _currentAllowance, Allowance memory _allowance) internal {
		uint256 elapsedTime = block.timestamp - _currentAllowance.intervalStart;
		require(elapsedTime > _allowance.cooldownInterval, "Cooldown interval not finished");
		require(_currentAllowance.epochs > 0, "Circle cannot tap anymore");
		_currentAllowance.debt = 0;
		_currentAllowance.intervalStart = block.timestamp;
		_currentAllowance.epochs--;
	}
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.2;

import "TimeLock.sol";

contract FeeRegistry is TimeLock(0){
	uint256 private constant _staticFee = 100; // 100 | MAX = 10000
	bool public on;

	function activateFee() external itself {
		on = true;
	}

	function shutdownFee() external itself {
		on = false;
	}

	function staticFee() external view returns(uint256) {
		if (!on)
			return 0;
		return _staticFee;
	}

	function getVariableFee(uint256 _yield, uint256 _tapTotal) external view returns(uint256 variableFee) {
		if (!on)
			return 0;
		uint256 yieldRatio = _yield * 1000 / _tapTotal;
		uint256 baseFee = 100;
		if (yieldRatio >= 900)
			variableFee = baseFee;        // 1%     @ 90% yield ratio
		else if (yieldRatio >= 800)
			variableFee = baseFee + 25;   // 1.25%  @ 80% yield ratio
		else if (yieldRatio >= 700)
			variableFee = baseFee + 50;   // 1.50%  @ 70% yield ratio
		else if (yieldRatio >= 600)
			variableFee = baseFee + 75;   // 1.75%  @ 60% yield ratio
		else if (yieldRatio >= 500)
			variableFee = baseFee + 100;  // 2.00%  @ 80% yield ratio
		else if (yieldRatio >= 400)
			variableFee = baseFee + 125;  // 2.25%  @ 80% yield ratio
		else if (yieldRatio >= 300)
			variableFee = baseFee + 150;  // 2.50%  @ 80% yield ratio
		else if (yieldRatio >= 200)
			variableFee = baseFee + 175;  // 2.75%  @ 80% yield ratio
		else if (yieldRatio >= 100)
			variableFee = baseFee + 200;  // 3.00%  @ 80% yield ratio
		else
			variableFee = baseFee + 250;  // 3.50%  @  0% yield ratio
	}
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.2;

import "BeaconProxy.sol";
import "VaultBeacon.sol";

contract VaultProxy is BeaconProxy {
	bytes32 private constant _OWNER_SLOT = 0xa7b53796fd2d99cb1f5ae019b54f9e024446c3d12b483f733ccc62ed04eb126a;

	event ProxyOwnershipTransferred(address newOwner);

	constructor(address _apeBeacon, address _owner, bytes memory data) BeaconProxy(_apeBeacon, data) {
		assert(_OWNER_SLOT == bytes32(uint256(keccak256("eip1967.proxy.owner")) - 1));
		assembly {
            sstore(_OWNER_SLOT, _owner)
        }
	}

	function proxyOwner() public view returns(address owner) {
		assembly {
            owner := sload(_OWNER_SLOT)
        }
	}

	function transferProxyOwnership(address _newOwner) external {
		require(msg.sender == proxyOwner());
		assembly {
            sstore(_OWNER_SLOT, _newOwner)
        }
		emit ProxyOwnershipTransferred(_newOwner);
	}

	function setBeaconDeploymentPrefs(uint256 _value) external {
		require(msg.sender == proxyOwner());
		VaultBeacon(_beacon()).setDeploymentPrefs(_value);
	}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "IBeacon.sol";
import "Proxy.sol";
import "Address.sol";

/**
 * @dev This contract implements a proxy that gets the implementation address for each call from a {UpgradeableBeacon}.
 *
 * The beacon address is stored in storage slot `uint256(keccak256('eip1967.proxy.beacon')) - 1`, so that it doesn't
 * conflict with the storage layout of the implementation behind the proxy.
 *
 * _Available since v3.4._
 */
contract BeaconProxy is Proxy {
    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 private constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Initializes the proxy with `beacon`.
     *
     * If `data` is nonempty, it's used as data in a delegate call to the implementation returned by the beacon. This
     * will typically be an encoded function call, and allows initializating the storage of the proxy like a Solidity
     * constructor.
     *
     * Requirements:
     *
     * - `beacon` must be a contract with the interface {IBeacon}.
     */
    constructor(address beacon, bytes memory data) payable {
        assert(_BEACON_SLOT == bytes32(uint256(keccak256("eip1967.proxy.beacon")) - 1));
        _setBeacon(beacon, data);
    }

    /**
     * @dev Returns the current beacon address.
     */
    function _beacon() internal view virtual returns (address beacon) {
        bytes32 slot = _BEACON_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            beacon := sload(slot)
        }
    }

    /**
     * @dev Returns the current implementation address of the associated beacon.
     */
    function _implementation() internal view virtual override returns (address) {
        return IBeacon(_beacon()).implementation();
    }

    /**
     * @dev Changes the proxy to use a new beacon.
     *
     * If `data` is nonempty, it's used as data in a delegate call to the implementation returned by the beacon.
     *
     * Requirements:
     *
     * - `beacon` must be a contract.
     * - The implementation returned by `beacon` must be a contract.
     */
    function _setBeacon(address beacon, bytes memory data) internal virtual {
        require(
            Address.isContract(beacon),
            "BeaconProxy: beacon is not a contract"
        );
        require(
            Address.isContract(IBeacon(beacon).implementation()),
            "BeaconProxy: beacon implementation is not a contract"
        );
        bytes32 slot = _BEACON_SLOT;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, beacon)
        }

        if (data.length > 0) {
            Address.functionDelegateCall(_implementation(), data, "BeaconProxy: function call failed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    /**
     * @dev This is a virtual function that should be overriden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback () external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive () external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overriden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.2;

import "UpgradeableBeacon.sol";
import "IBeacon.sol";
import "TimeLock.sol";

contract VaultBeacon is TimeLock {

	mapping(uint256 => address) public deployments;
	uint256 public deploymentCount;

	mapping(address => uint256) public deploymentPref;

	event NewImplementationPushed(address newImplementation);

	constructor(address _apeVault, uint256 _minDelay) TimeLock(_minDelay) {
		require(Address.isContract(_apeVault), "VaultBeacon: implementation is not a contract");
		deployments[++deploymentCount] = _apeVault;
	}

	function implementation(address _user) public view returns(address) {
		uint256 pref = deploymentPref[_user];
		if(pref == 0)
			return deployments[deploymentCount];
		else
			return deployments[pref];
	}

	function implementation() public view returns(address) {
		return implementation(msg.sender);
	}

	function setDeploymentPrefs(uint256 _value) external {
		require(_value <= deploymentCount);
		deploymentPref[msg.sender] = _value;
	}

	function pushNewImplementation(address _newImplementation) public itself {
		require(Address.isContract(_newImplementation), "VaultBeacon: implementaion is not a contract");
		deployments[++deploymentCount] = _newImplementation;
		emit NewImplementationPushed(_newImplementation);
	}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "IBeacon.sol";
import "Ownable.sol";
import "Address.sol";

/**
 * @dev This contract is used in conjunction with one or more instances of {BeaconProxy} to determine their
 * implementation contract, which is where they will delegate all function calls.
 *
 * An owner is able to change the implementation the beacon points to, thus upgrading the proxies that use this beacon.
 */
contract UpgradeableBeacon is IBeacon, Ownable {
    address private _implementation;

    /**
     * @dev Emitted when the implementation returned by the beacon is changed.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Sets the address of the initial implementation, and the deployer account as the owner who can upgrade the
     * beacon.
     */
    constructor(address implementation_) {
        _setImplementation(implementation_);
    }

    /**
     * @dev Returns the current implementation address.
     */
    function implementation() public view virtual override returns (address) {
        return _implementation;
    }

    /**
     * @dev Upgrades the beacon to a new implementation.
     *
     * Emits an {Upgraded} event.
     *
     * Requirements:
     *
     * - msg.sender must be the owner of the contract.
     * - `newImplementation` must be a contract.
     */
    function upgradeTo(address newImplementation) public virtual onlyOwner {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Sets the implementation contract address for this beacon
     *
     * Requirements:
     *
     * - `newImplementation` must be a contract.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "UpgradeableBeacon: implementation is not a contract");
        _implementation = newImplementation;
    }
}