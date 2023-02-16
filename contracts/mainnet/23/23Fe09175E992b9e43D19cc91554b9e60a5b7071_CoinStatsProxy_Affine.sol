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
// OpenZeppelin Contracts (last updated v4.8.0) (interfaces/IERC4626.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";
import "../token/ERC20/extensions/IERC20Metadata.sol";

/**
 * @dev Interface of the ERC4626 "Tokenized Vault Standard", as defined in
 * https://eips.ethereum.org/EIPS/eip-4626[ERC-4626].
 *
 * _Available since v4.7._
 */
interface IERC4626 is IERC20, IERC20Metadata {
    event Deposit(address indexed sender, address indexed owner, uint256 assets, uint256 shares);

    event Withdraw(
        address indexed sender,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    /**
     * @dev Returns the address of the underlying token used for the Vault for accounting, depositing, and withdrawing.
     *
     * - MUST be an ERC-20 token contract.
     * - MUST NOT revert.
     */
    function asset() external view returns (address assetTokenAddress);

    /**
     * @dev Returns the total amount of the underlying asset that is “managed” by Vault.
     *
     * - SHOULD include any compounding that occurs from yield.
     * - MUST be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT revert.
     */
    function totalAssets() external view returns (uint256 totalManagedAssets);

    /**
     * @dev Returns the amount of shares that the Vault would exchange for the amount of assets provided, in an ideal
     * scenario where all the conditions are met.
     *
     * - MUST NOT be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT show any variations depending on the caller.
     * - MUST NOT reflect slippage or other on-chain conditions, when performing the actual exchange.
     * - MUST NOT revert.
     *
     * NOTE: This calculation MAY NOT reflect the “per-user” price-per-share, and instead should reflect the
     * “average-user’s” price-per-share, meaning what the average user should expect to see when exchanging to and
     * from.
     */
    function convertToShares(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Returns the amount of assets that the Vault would exchange for the amount of shares provided, in an ideal
     * scenario where all the conditions are met.
     *
     * - MUST NOT be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT show any variations depending on the caller.
     * - MUST NOT reflect slippage or other on-chain conditions, when performing the actual exchange.
     * - MUST NOT revert.
     *
     * NOTE: This calculation MAY NOT reflect the “per-user” price-per-share, and instead should reflect the
     * “average-user’s” price-per-share, meaning what the average user should expect to see when exchanging to and
     * from.
     */
    function convertToAssets(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev Returns the maximum amount of the underlying asset that can be deposited into the Vault for the receiver,
     * through a deposit call.
     *
     * - MUST return a limited value if receiver is subject to some deposit limit.
     * - MUST return 2 ** 256 - 1 if there is no limit on the maximum amount of assets that may be deposited.
     * - MUST NOT revert.
     */
    function maxDeposit(address receiver) external view returns (uint256 maxAssets);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their deposit at the current block, given
     * current on-chain conditions.
     *
     * - MUST return as close to and no more than the exact amount of Vault shares that would be minted in a deposit
     *   call in the same transaction. I.e. deposit should return the same or more shares as previewDeposit if called
     *   in the same transaction.
     * - MUST NOT account for deposit limits like those returned from maxDeposit and should always act as though the
     *   deposit would be accepted, regardless if the user has enough tokens approved, etc.
     * - MUST be inclusive of deposit fees. Integrators should be aware of the existence of deposit fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToShares and previewDeposit SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by depositing.
     */
    function previewDeposit(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Mints shares Vault shares to receiver by depositing exactly amount of underlying tokens.
     *
     * - MUST emit the Deposit event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   deposit execution, and are accounted for during deposit.
     * - MUST revert if all of assets cannot be deposited (due to deposit limit being reached, slippage, the user not
     *   approving enough underlying tokens to the Vault contract, etc).
     *
     * NOTE: most implementations will require pre-approval of the Vault with the Vault’s underlying asset token.
     */
    function deposit(uint256 assets, address receiver) external returns (uint256 shares);

    /**
     * @dev Returns the maximum amount of the Vault shares that can be minted for the receiver, through a mint call.
     * - MUST return a limited value if receiver is subject to some mint limit.
     * - MUST return 2 ** 256 - 1 if there is no limit on the maximum amount of shares that may be minted.
     * - MUST NOT revert.
     */
    function maxMint(address receiver) external view returns (uint256 maxShares);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their mint at the current block, given
     * current on-chain conditions.
     *
     * - MUST return as close to and no fewer than the exact amount of assets that would be deposited in a mint call
     *   in the same transaction. I.e. mint should return the same or fewer assets as previewMint if called in the
     *   same transaction.
     * - MUST NOT account for mint limits like those returned from maxMint and should always act as though the mint
     *   would be accepted, regardless if the user has enough tokens approved, etc.
     * - MUST be inclusive of deposit fees. Integrators should be aware of the existence of deposit fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToAssets and previewMint SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by minting.
     */
    function previewMint(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev Mints exactly shares Vault shares to receiver by depositing amount of underlying tokens.
     *
     * - MUST emit the Deposit event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the mint
     *   execution, and are accounted for during mint.
     * - MUST revert if all of shares cannot be minted (due to deposit limit being reached, slippage, the user not
     *   approving enough underlying tokens to the Vault contract, etc).
     *
     * NOTE: most implementations will require pre-approval of the Vault with the Vault’s underlying asset token.
     */
    function mint(uint256 shares, address receiver) external returns (uint256 assets);

    /**
     * @dev Returns the maximum amount of the underlying asset that can be withdrawn from the owner balance in the
     * Vault, through a withdraw call.
     *
     * - MUST return a limited value if owner is subject to some withdrawal limit or timelock.
     * - MUST NOT revert.
     */
    function maxWithdraw(address owner) external view returns (uint256 maxAssets);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their withdrawal at the current block,
     * given current on-chain conditions.
     *
     * - MUST return as close to and no fewer than the exact amount of Vault shares that would be burned in a withdraw
     *   call in the same transaction. I.e. withdraw should return the same or fewer shares as previewWithdraw if
     *   called
     *   in the same transaction.
     * - MUST NOT account for withdrawal limits like those returned from maxWithdraw and should always act as though
     *   the withdrawal would be accepted, regardless if the user has enough shares, etc.
     * - MUST be inclusive of withdrawal fees. Integrators should be aware of the existence of withdrawal fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToShares and previewWithdraw SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by depositing.
     */
    function previewWithdraw(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Burns shares from owner and sends exactly assets of underlying tokens to receiver.
     *
     * - MUST emit the Withdraw event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   withdraw execution, and are accounted for during withdraw.
     * - MUST revert if all of assets cannot be withdrawn (due to withdrawal limit being reached, slippage, the owner
     *   not having enough shares, etc).
     *
     * Note that some implementations will require pre-requesting to the Vault before a withdrawal may be performed.
     * Those methods should be performed separately.
     */
    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) external returns (uint256 shares);

    /**
     * @dev Returns the maximum amount of Vault shares that can be redeemed from the owner balance in the Vault,
     * through a redeem call.
     *
     * - MUST return a limited value if owner is subject to some withdrawal limit or timelock.
     * - MUST return balanceOf(owner) if owner is not subject to any withdrawal limit or timelock.
     * - MUST NOT revert.
     */
    function maxRedeem(address owner) external view returns (uint256 maxShares);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their redeemption at the current block,
     * given current on-chain conditions.
     *
     * - MUST return as close to and no more than the exact amount of assets that would be withdrawn in a redeem call
     *   in the same transaction. I.e. redeem should return the same or more assets as previewRedeem if called in the
     *   same transaction.
     * - MUST NOT account for redemption limits like those returned from maxRedeem and should always act as though the
     *   redemption would be accepted, regardless if the user has enough shares, etc.
     * - MUST be inclusive of withdrawal fees. Integrators should be aware of the existence of withdrawal fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToAssets and previewRedeem SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by redeeming.
     */
    function previewRedeem(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev Burns exactly shares from owner and sends assets of underlying tokens to receiver.
     *
     * - MUST emit the Withdraw event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   redeem execution, and are accounted for during redeem.
     * - MUST revert if all of shares cannot be redeemed (due to withdrawal limit being reached, slippage, the owner
     *   not having enough shares, etc).
     *
     * NOTE: some implementations will require pre-requesting to the Vault before a withdrawal may be performed.
     * Those methods should be performed separately.
     */
    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) external returns (uint256 assets);
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
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

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
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

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "./FeesV2.sol";

interface IVault {
    function addAffiliateBalance(address affiliate, address token, uint256 affiliatePortion) external;
}

abstract contract CoinStatsBaseV1 is FeesV2 {
    using SafeERC20 for IERC20;

    address public immutable VAULT;

    constructor(uint256 _goodwill, uint256 _affiliateSplit, address _vaultAddress) FeesV2(_goodwill, _affiliateSplit) {
        VAULT = _vaultAddress;
    }

    /// @notice Sends provided token amount to the contract
    /// @param token represents token address to be transfered
    /// @param amount represents token amount to be transfered
    function _pullTokens(address token, uint256 amount) internal returns (uint256 balance) {
        if (token == ETH_ADDRESS) {
            require(msg.value > 0, "ETH was not sent");
        } else {
            // solhint-disable reason-string
            require(msg.value == 0, "Along with token, the ETH was also sent");
            uint256 balanceBefore = _getBalance(token);

            // Transfers all tokens to current contract
            IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

            return _getBalance(token) - balanceBefore;
        }
        return amount;
    }

    /// @notice Subtracts goodwill portion from given amount
    /// @dev If 0x00... address was given, then it will be replaced with 0xEeeEE... address
    /// @param token represents token address
    /// @param amount represents token amount
    /// @param affiliate goodwill affiliate
    /// @param enableGoodwill boolean representation whether to charge fee or not
    /// @return totalGoodwillPortion the amount of goodwill
    function _subtractGoodwill(
        address token,
        uint256 amount,
        address affiliate,
        bool enableGoodwill
    ) internal returns (uint256 totalGoodwillPortion) {
        bool whitelisted = feeWhitelist[msg.sender];

        if (enableGoodwill && !whitelisted && (goodwill > 0)) {
            totalGoodwillPortion = (amount * goodwill) / 10000;

            if (token == ETH_ADDRESS) {
                Address.sendValue(payable(VAULT), totalGoodwillPortion);
            } else {
                uint256 balanceBefore = IERC20(token).balanceOf(VAULT);
                IERC20(token).safeTransfer(VAULT, totalGoodwillPortion);
                totalGoodwillPortion = IERC20(token).balanceOf(VAULT) - balanceBefore;
            }

            if (affiliates[affiliate]) {
                uint256 affiliatePortion = (totalGoodwillPortion * affiliateSplit) / 100;

                IVault(VAULT).addAffiliateBalance(affiliate, token, affiliatePortion);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

abstract contract FeesV2 is Ownable {
    using SafeERC20 for IERC20;
    bool public paused = false;

    // If true, goodwill is not deducted
    mapping(address => bool) public feeWhitelist;

    uint256 public goodwill;
    uint256 public affiliateSplit;

    // Mapping from {affiliate} to {status}
    mapping(address => bool) public affiliates;
    // Mapping from {swapTarget} to {status}
    mapping(address => bool) public approvedTargets;
    // Mapping from {token} to {status}
    mapping(address => bool) public shouldResetAllowance;

    address internal constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    event ContractPauseStatusChanged(bool status);
    event FeeWhitelistUpdate(address _address, bool status);
    event GoodwillChange(uint256 newGoodwill);
    event AffiliateSplitChange(uint256 newAffiliateSplit);

    constructor(uint256 _goodwill, uint256 _affiliateSplit) {
        goodwill = _goodwill;
        affiliateSplit = _affiliateSplit;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is temporary paused");
        _;
    }

    /// @notice Returns address token balance
    /// @param token address
    /// @return balance
    function _getBalance(address token) internal view returns (uint256 balance) {
        if (token == address(ETH_ADDRESS)) {
            balance = address(this).balance;
        } else {
            balance = IERC20(token).balanceOf(address(this));
        }
    }

    /// @dev Gives MAX allowance to token spender
    /// @param token address to apporve
    /// @param spender address
    function _approveToken(address token, address spender, uint256 amount) internal {
        IERC20 _token = IERC20(token);

        if (shouldResetAllowance[token]) {
            _token.safeApprove(spender, 0);
            _token.safeApprove(spender, type(uint256).max);
        } else if (_token.allowance(address(this), spender) > amount) return;
        else {
            _token.safeApprove(spender, 0);
            _token.safeApprove(spender, type(uint256).max);
        }
    }

    /// @notice To pause/unpause contract
    function toggleContractActive() public onlyOwner {
        paused = !paused;

        emit ContractPauseStatusChanged(paused);
    }

    /// @notice Whitelists addresses from paying goodwill
    function setFeeWhitelist(address _address, bool status) external onlyOwner {
        feeWhitelist[_address] = status;

        emit FeeWhitelistUpdate(_address, status);
    }

    /// @notice Changes goodwill %
    function setNewGoodwill(uint256 _newGoodwill) public onlyOwner {
        require(_newGoodwill <= 100, "Invalid goodwill value");
        goodwill = _newGoodwill;

        emit GoodwillChange(_newGoodwill);
    }

    /// @notice Changes affiliate split %
    function setNewAffiliateSplit(uint256 _newAffiliateSplit) external onlyOwner {
        require(_newAffiliateSplit <= 100, "Invalid affilatesplit percent");
        affiliateSplit = _newAffiliateSplit;

        emit AffiliateSplitChange(_newAffiliateSplit);
    }

    /// @notice Sets affiliate status
    function setAffiliates(address[] calldata _affiliates, bool[] calldata _status) external onlyOwner {
        require(_affiliates.length == _status.length, "Affiliate: Invalid input length");

        for (uint256 i = 0; i < _affiliates.length; i++) {
            affiliates[_affiliates[i]] = _status[i];
        }
    }

    ///@notice Sets approved targets
    function setApprovedTargets(address[] calldata targets, bool[] calldata isApproved) external onlyOwner {
        require(targets.length == isApproved.length, "SetApprovedTargets: Invalid input length");

        for (uint256 i = 0; i < targets.length; i++) {
            approvedTargets[targets[i]] = isApproved[i];
        }
    }

    ///@notice Sets address allowance that should be reset first
    function setShouldResetAllowance(address[] calldata tokens, bool[] calldata statuses) external onlyOwner {
        require(tokens.length == statuses.length, "SetShouldResetAllowance: Invalid input length");

        for (uint256 i = 0; i < tokens.length; i++) {
            shouldResetAllowance[tokens[i]] = statuses[i];
        }
    }

    receive() external payable {
        // solhint-disable-next-line
        require(msg.sender != tx.origin, "Do not send ETH directly");
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

/// @title Protocol Integration Interface
abstract contract IntegrationInterface {
    /**
  @dev The function must deposit assets to the protocol.
  @param entryTokenAddress Token to be transfered to integration contract from caller
  @param entryTokenAmount Token amount to be transferes to integration contract from caller
  @param \ Pool/Vault address to deposit funds
  @param depositTokenAddress Token to be transfered to poolAddress
  @param minExitTokenAmount Min acceptable amount of liquidity/stake tokens to reeive
  @param underlyingTarget Underlying target which will execute swap
  @param targetDepositTokenAddress Token which will be used to deposit fund in target contract
  @param swapTarget Underlying target's swap target
  @param swapData Data for swap
  @param affiliate Affiliate address 
  */

    function deposit(
        address entryTokenAddress,
        uint256 entryTokenAmount,
        address,
        address depositTokenAddress,
        uint256 minExitTokenAmount,
        address underlyingTarget,
        address targetDepositTokenAddress,
        address swapTarget,
        bytes calldata swapData,
        address affiliate
    ) external payable virtual;

    /**
  @dev The function must withdraw assets from the protocol.
  @param \ Pool/Vault address
  @param \ Token amount to be transferes to integration contract
  @param exitTokenAddress Specifies the token which will be send to caller
  @param minExitTokenAmount Min acceptable amount of tokens to reeive
  @param underlyingTarget Underlying target which will execute swap
  @param targetWithdrawTokenAddress Token which will be used to withdraw funds from target contract
  @param swapTarget Underlying target's swap target
  @param swapData Data for swap
  @param affiliate Affiliate address 
  */
    function withdraw(
        address,
        uint256,
        address exitTokenAddress,
        uint256 minExitTokenAmount,
        address underlyingTarget,
        address targetWithdrawTokenAddress,
        address swapTarget,
        bytes calldata swapData,
        address affiliate
    ) external payable virtual;

    /**
    @dev Returns account balance
    @param \ Pool/Vault address
    @param account User account address
    @return balance Returns user current balance
   */
    function getBalance(address, address account) public view virtual returns (uint256 balance);

    /**
    @notice Utility function to determine the quantity and address of a token being removed
    @param \ Pool/Vault address from which liquidity should be removed
    @param [Optional] Token address token to be removed
    @param amount Quantity of LP tokens to remove.
    @return The amount of token removed
  */
    function removeAssetReturn(address, address, uint256 amount) external virtual returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { CoinStatsBaseV1, Ownable, SafeERC20, IERC20 } from "./base/CoinStatsBaseV1.sol";
import { IERC4626 } from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import { IntegrationInterface } from "./base/IntegrationInterface.sol";

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;
}

contract CoinStatsProxy_Affine is CoinStatsBaseV1, IntegrationInterface {
    using SafeERC20 for IERC20;

    address immutable WETH;

    mapping(address => bool) public targetWhitelist;

    error TargetIsNotWhitelited(address target);

    event Deposit(address indexed from, address indexed pool, address token, uint256 amount, address affiliate);
    event Withdraw(address indexed from, address indexed pool, address token, uint256 amount, address affiliate);
    event FillQuoteSwap(
        address swapTarget,
        address inputTokenAddress,
        uint256 inputTokenAmount,
        address outputTokenAddress,
        uint256 outputTokenAmount
    );

    constructor(
        address _target,
        address _weth,
        uint256 _goodwill,
        uint256 _affiliateSplit,
        address _vaultAddress
    ) CoinStatsBaseV1(_goodwill, _affiliateSplit, _vaultAddress) {
        WETH = _weth;
        targetWhitelist[_target] = true;

        approvedTargets[0x1111111254fb6c44bAC0beD2854e76F90643097d] = true;
    }

    function removeAssetReturn(
        address withdrawTarget,
        address,
        uint256 shares
    ) external view override returns (uint256) {
        return IERC4626(withdrawTarget).previewRedeem(shares);
    }

    function getBalance(address target, address account) public view override returns (uint256) {
        return IERC20(target).balanceOf(account);
    }

    function setTarget(address[] memory targets, bool[] memory statuses) external onlyOwner {
        for (uint8 i = 0; i < targets.length; i++) {
            targetWhitelist[targets[i]] = statuses[i];
        }
    }

    function _fillQuote(
        address inputTokenAddress,
        uint256 inputTokenAmount,
        address outputTokenAddress,
        address swapTarget,
        bytes memory swapData
    ) private returns (uint256 outputTokenAmount) {
        if (swapTarget == WETH) {
            if (outputTokenAddress == ETH_ADDRESS) {
                IWETH(WETH).withdraw(inputTokenAmount);

                return inputTokenAmount;
            } else {
                IWETH(WETH).deposit{ value: inputTokenAmount }();

                return inputTokenAmount;
            }
        }

        uint256 value;
        if (inputTokenAddress == ETH_ADDRESS) {
            value = inputTokenAmount;
        } else {
            _approveToken(inputTokenAddress, swapTarget, inputTokenAmount);
        }

        uint256 initialOutputTokenBalance = _getBalance(outputTokenAddress);

        // solhint-disable-next-line reason-string
        require(approvedTargets[swapTarget], "FillQuote: Target is not whitelisted");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = swapTarget.call{ value: value }(swapData);
        require(success, "FillQuote: Failed to swap tokens");

        outputTokenAmount = _getBalance(outputTokenAddress) - initialOutputTokenBalance;

        // solhint-disable-next-line reason-string
        require(outputTokenAmount > 0, "FillQuote: Swapped to invalid token");

        emit FillQuoteSwap(swapTarget, inputTokenAddress, inputTokenAmount, outputTokenAddress, outputTokenAmount);
    }

    function deposit(
        address entryTokenAddress,
        uint256 entryTokenAmount,
        address depositTarget,
        address,
        uint256 minShares,
        address,
        address,
        address swapTarget,
        bytes calldata swapData,
        address affiliate
    ) external payable override whenNotPaused {
        if (!targetWhitelist[depositTarget]) {
            revert TargetIsNotWhitelited(depositTarget);
        }

        if (entryTokenAddress == address(0)) {
            entryTokenAddress = ETH_ADDRESS;
        }

        entryTokenAmount = _pullTokens(entryTokenAddress, entryTokenAmount);

        entryTokenAmount -= _subtractGoodwill(entryTokenAddress, entryTokenAmount, affiliate, true);

        address asset = IERC4626(depositTarget).asset();

        if (entryTokenAddress != asset) {
            entryTokenAmount = _fillQuote(entryTokenAddress, entryTokenAmount, asset, swapTarget, swapData);
        }

        IERC20(asset).safeApprove(depositTarget, entryTokenAmount);

        // Do not call this from contracts, shares will be locked there
        uint256 shares = IERC4626(depositTarget).deposit(entryTokenAmount, msg.sender);
        require(shares >= minShares, "Got less shares than expected");

        emit Deposit(msg.sender, depositTarget, entryTokenAddress, entryTokenAmount, affiliate);
    }

    function withdraw(
        address withdrawTarget,
        uint256 withdrawAmount,
        address exitTokenAddress,
        uint256 minExitTokenAmount,
        address,
        address,
        address swapTarget,
        bytes calldata swapData,
        address affiliate
    ) external payable override whenNotPaused {
        if (!targetWhitelist[withdrawTarget]) {
            revert TargetIsNotWhitelited(withdrawTarget);
        }

        withdrawAmount = _pullTokens(withdrawTarget, withdrawAmount);

        _approveToken(withdrawTarget, withdrawTarget, withdrawAmount);

        address asset = IERC4626(withdrawTarget).asset();
        uint256 exitTokenAmount;

        uint256 assets = IERC4626(withdrawTarget).redeem(withdrawAmount, address(this), address(this));

        if (exitTokenAddress != asset) {
            exitTokenAmount = _fillQuote(asset, assets, exitTokenAddress, swapTarget, swapData);
        }

        exitTokenAmount -= _subtractGoodwill(exitTokenAddress, exitTokenAmount, affiliate, true);

        IERC20(exitTokenAddress).safeTransfer(msg.sender, exitTokenAmount);

        require(exitTokenAmount >= minExitTokenAmount, "Got less exit tokens than expected");

        emit Withdraw(msg.sender, withdrawTarget, exitTokenAddress, exitTokenAmount, affiliate);
    }
}