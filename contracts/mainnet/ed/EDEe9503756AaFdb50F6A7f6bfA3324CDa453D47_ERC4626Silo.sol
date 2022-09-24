// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "contracts/interfaces/ISilo.sol";

interface IERC4626 {
    /// @notice Mints `shares` amount of vault tokens to `to` by depositing exactly `value` underlying tokens.

    function deposit(uint256 assets, address receiver) external returns (uint256 shares);

    /// @notice Burns `shares` vault tokens from `from`, withdrawing exactly `value` underlying tokens to `to`.
    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) external returns (uint256 shares);

    /// @notice Returns the address of the token the vault uses for accounting, depositing, and withdrawing.
    function asset() external view returns (address);

    /// The amount of assets that the Vault would exchange for the amount of shares provided, in an ideal scenario where all the conditions are met.
    function convertToAssets(uint256 shares) external view returns (uint256 assets);
}

contract ERC4626Silo is ISilo {
    /// @inheritdoc ISilo
    string public name;

    IERC4626 public immutable vault;

    address public immutable underlying;

    constructor(IERC4626 _vault) {
        vault = _vault;
        underlying = _vault.asset();

        // ex: ERC4626 (fDAI) DAI Silo
        name = string(
            abi.encodePacked(
                "ERC4626 (",
                IERC20Metadata(address(vault)).symbol(),
                ") ",
                IERC20Metadata(underlying).symbol(),
                " Silo"
            )
        );
    }

    /// @inheritdoc ISilo
    function poke() external override {}

    /// @inheritdoc ISilo
    function deposit(uint256 amount) external override {
        if (amount == 0) return;
        _approve(underlying, address(vault), amount);
        vault.deposit(amount, address(this));
    }

    /// @inheritdoc ISilo
    function withdraw(uint256 amount) external override {
        if (amount == 0) return;
        vault.withdraw(amount, address(this), address(this));
    }

    /// @inheritdoc ISilo
    function balanceOf(address account) external view override returns (uint256 balance) {
        balance = vault.convertToAssets(IERC20(address(vault)).balanceOf(account));
    }

    /// @inheritdoc ISilo
    function shouldAllowRemovalOf(address token) external view override returns (bool shouldAllow) {
        shouldAllow = token != address(vault);
    }

    function _approve(
        address token,
        address spender,
        uint256 amount
    ) private {
        // 200 gas to read uint256
        if (IERC20(token).allowance(address(this), spender) < amount) {
            // 20000 gas to write uint256 if changing from zero to non-zero
            // 5000  gas to write uint256 if changing from non-zero to non-zero
            IERC20(token).approve(spender, type(uint256).max);
        }
    }
}

// SPDX-License-Identifier: MIT

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
pragma solidity ^0.8.10;

interface ISilo {
    /// @notice A descriptive name for the silo (ex: Compound USDC Silo)
    function name() external view returns (string memory);

    /// @notice A place to update the silo's internal state
    /// @dev After this has been called, balances reported by `balanceOf` MUST be correct
    function poke() external;

    /// @notice Deposits `amount` of the underlying token
    function deposit(uint256 amount) external;

    /// @notice Withdraws EXACTLY `amount` of the underlying token
    function withdraw(uint256 amount) external;

    /// @notice Reports how much of the underlying token `account` has stored
    /// @dev Must never overestimate `balance`. Should give the exact, correct value after `poke` is called
    function balanceOf(address account) external view returns (uint256 balance);

    /**
     * @notice Whether the given token is irrelevant to the silo's strategy (`shouldAllow = true`) or
     * is required for proper management (`shouldAllow = false`). ex: Compound silos shouldn't allow
     * removal of cTokens, but the may allow removal of COMP rewards.
     * @dev Removed tokens are used to help incentivize rebalances for the Blend vault that uses the silo. So
     * if you want something like COMP rewards to go to Blend *users* instead, you'd have to implement a
     * trading function as part of `poke()` to convert COMP to the underlying token.
     */
    function shouldAllowRemovalOf(address token) external view returns (bool shouldAllow);
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