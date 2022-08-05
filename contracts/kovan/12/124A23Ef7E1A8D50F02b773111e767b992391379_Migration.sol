// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity >=0.8.6;

import "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";
import "../interfaces/IVaultMetadata.sol";
import "../libs/TransferUtils.sol";

contract Migration {
    using TransferUtils for IERC20;

    IVaultMetadata immutable from;
    IVaultMetadata immutable to;

    constructor(IVaultMetadata _from, IVaultMetadata _to) {
        require(_from.asset() == _to.asset(), "Vault assets must be the same");
        from = _from;
        to = _to;
    }

    function migrate() external {
        uint256 shares = from.balanceOf(msg.sender);
        from.redeem(shares, address(this), msg.sender);

        IERC20 asset = IERC20(from.asset());
        uint256 balance = asset.balanceOf(address(this));
        asset.safeApprove(address(to), balance);
        to.deposit(balance, msg.sender);
    }

    function migrateWithPermit(
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        uint256 shares = from.balanceOf(msg.sender);
        IERC20Permit(address(from)).permit(msg.sender, address(this), shares, deadline, v, r, s);
        from.redeem(shares, address(this), msg.sender);

        IERC20 asset = IERC20(from.asset());
        uint256 balance = asset.balanceOf(address(this));
        asset.safeApprove(address(to), balance);
        to.deposit(balance, msg.sender);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity >=0.8.6;

import "./IVault.sol";

interface IVaultMetadata is IVault {
    function asset() external view returns (address);
}

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity >=0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library TransferUtils {
    error TransferUtils__TransferDidNotSucceed();
    error TransferUtils__ApproveDidNotSucceed();

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

    function safeApprove(
        IERC20 token,
        address spender,
        uint256 amount
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, amount));
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory result) = address(token).call(data);
        if (!success || result.length > 0) {
            // Return data is optional
            bool transferSucceeded = abi.decode(result, (bool));
            if (!transferSucceeded) revert TransferUtils__TransferDidNotSucceed();
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity >=0.8.6;

import "./IERC4626.sol";

interface IVault is IERC4626 {
    error IVault__CallerIsNotTheController();
    error IVault__NotProcessingDeposits();
    error IVault__AlreadyProcessingDeposits();
    error IVault__ForbiddenWhileProcessingDeposits();
    error IVault__ZeroAssets();
    error IVault__ZeroShares();

    event FeeCollected(uint256 fee);
    event StartRound(uint256 indexed roundId, uint256 amountAddedToStrategy);
    event EndRound(uint256 indexed roundId);
    event DepositProcessed(address indexed owner, uint256 indexed roundId, uint256 assets, uint256 shares);

    /**
     * @notice Returns the fee charged on withdraws.
     */
    function withdrawFeeRatio() external view returns (uint256);

    /**
     * @notice Returns the vault controller
     */
    function controller() external view returns (address);

    /**
     * @notice Outputs the amount of asset tokens of an `owner` is idle, waiting for the next round.
     */
    function idleAssetsOf(address owner) external view returns (uint256);

    /**
     * @notice Outputs the amount of asset tokens of an `owner` are either waiting for the next round,
     * deposited or committed.
     */
    function assetsOf(address owner) external view returns (uint256);

    /**
     * @notice Outputs the amount of asset tokens is idle, waiting for the next round.
     */
    function totalIdleAssets() external view returns (uint256);

    /**
     * @notice Outputs current size of the deposit queue.
     */
    function depositQueueSize() external view returns (uint256);

    /**
     * @notice Starts the next round, sending the idle funds to the
     * strategy where it should start accruing yield.
     */
    function startRound() external;

    /**
     * @notice Closes the round, allowing deposits to the next round be processed.
     * and opens the window for withdraws.
     */
    function endRound() external;

    /**
     * @notice Mint shares for deposits accumulated, effectively including their owners in the next round.
     * `processQueuedDeposits` extracts up to but not including endIndex. For example, processQueuedDeposits(1,4)
     * extracts the second element through the fourth element (elements indexed 1, 2, and 3).
     *
     * @param startIndex Zero-based index at which to start processing deposits
     * @param endIndex The index of the first element to exclude from queue
     */
    function processQueuedDeposits(uint256 startIndex, uint256 endIndex) external;
}

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity >=0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC4626 is IERC20 {
    event Deposit(address indexed caller, address indexed owner, uint256 assets, uint256 shares);

    event Withdraw(
        address indexed caller,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    /**
     * @notice Total amount of the underlying asset that is “managed” by Vault.
     */
    function totalAssets() external view returns (uint256);

    /**
     * @notice Mints `shares` Vault shares to `receiver` by depositing exactly `amount` of underlying tokens.
     * @return shares Shares minted.
     */
    function deposit(uint256 assets, address receiver) external returns (uint256 shares);

    /**
     * @notice Mints exactly `shares` Vault shares to `receiver` by depositing amount of underlying tokens.
     * @return assets Assets deposited.
     */
    function mint(uint256 shares, address receiver) external returns (uint256 assets);

    /**
     * @notice Burns exactly `shares` from `owner` and sends `assets` of underlying tokens to `receiver`.
     * @return assets Assets withdrawn.
     */
    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) external returns (uint256 assets);

    /**
     * @notice Burns `shares` from `owner` and sends exactly `assets` of underlying tokens to `receiver`.
     * @return shares Shares burned.
     */
    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) external returns (uint256 shares);

    /**
     * @notice Outputs the amount of shares that would be generated by depositing `assets`.
     */
    function previewDeposit(uint256 assets) external view returns (uint256 shares);

    /**
     * @notice Outputs the amount of asset tokens would be necessary to generate the amount of `shares`.
     */
    function previewMint(uint256 shares) external view returns (uint256 amount);

    /**
     * @notice Outputs the amount of shares would be burned to withdraw the `assets` amount.
     */
    function previewWithdraw(uint256 assets) external view returns (uint256 shares);

    /**
     * @notice Outputs the amount of asset tokens would be withdrawn burning a given amount of shares.
     */
    function previewRedeem(uint256 shares) external view returns (uint256 amount);

    /**
     * @notice The amount of shares that the Vault would exchange for
     * the amount of assets provided, in an ideal scenario where all the conditions are met.
     */
    function convertToShares(uint256 assets) external view returns (uint256);

    /**
     * @notice The amount of assets that the Vault would exchange for
     * the amount of shares provided, in an ideal scenario where all the conditions are met.
     */
    function convertToAssets(uint256 shares) external view returns (uint256);

    /**
     * @notice Maximum amount of the underlying asset that can be deposited into
     * the Vault for the `receiver`, through a `deposit` call.
     */
    function maxDeposit(address owner) external view returns (uint256);

    /**
     * @notice Maximum amount of shares that can be minted from the Vault for
     * the `receiver`, through a `mint` call.
     */
    function maxMint(address receiver) external view returns (uint256 maxShares);

    /**
     * @notice Maximum amount of the underlying asset that can be withdrawn from
     * the `owner` balance in the Vault, through a `withdraw` call.
     */
    function maxWithdraw(address owner) external view returns (uint256 maxAssets);

    /**
     * @notice Maximum amount of Vault shares that can be redeemed from
     * the `owner` balance in the Vault, through a `redeem` call.
     */
    function maxRedeem(address owner) external view returns (uint256 maxShares);
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