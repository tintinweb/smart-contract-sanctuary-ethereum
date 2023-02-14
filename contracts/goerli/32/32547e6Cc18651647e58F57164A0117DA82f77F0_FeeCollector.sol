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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Multicall.sol)

pragma solidity ^0.8.0;

import "./Address.sol";

/**
 * @dev Provides a function to batch together multiple calls in a single external call.
 *
 * _Available since v4.1._
 */
abstract contract Multicall {
    /**
     * @dev Receives and executes a batch of function calls on this contract.
     */
    function multicall(bytes[] calldata data) external virtual returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            results[i] = Address.functionDelegateCall(address(this), data[i]);
        }
        return results;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import { IFeeCollector } from "./interfaces/IFeeCollector.sol";
import { LibAddress } from "./lib/LibAddress.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";

/// @title A smart contract for registering vaults for payments.
contract FeeCollector is IFeeCollector, Multicall {
    using LibAddress for address payable;

    address payable public guildFeeCollector;
    uint96 public guildShareBps;

    Vault[] internal vaults;

    /// @param guildFeeCollector_ The address that will receive Guild's share from the funds.
    /// @param guildShareBps_ The percentage of Guild's share expressed in basis points (e.g 500 for a 5% cut).
    constructor(address payable guildFeeCollector_, uint96 guildShareBps_) {
        guildFeeCollector = guildFeeCollector_;
        guildShareBps = guildShareBps_;
    }

    function registerVault(address owner, address token, bool multiplePayments, uint120 fee) external {
        Vault storage vault = vaults.push();
        vault.owner = owner;
        vault.token = token;
        vault.multiplePayments = multiplePayments;
        vault.fee = fee;

        emit VaultRegistered(vaults.length - 1, owner, token, fee);
    }

    function payFee(uint256 vaultId) external payable {
        if (vaultId >= vaults.length) revert VaultDoesNotExist(vaultId);

        Vault storage vault = vaults[vaultId];

        if (!vault.multiplePayments && vault.paid[msg.sender]) revert AlreadyPaid(vaultId, msg.sender);

        uint256 requiredAmount = vault.fee;
        vault.collected += uint128(requiredAmount);
        vault.paid[msg.sender] = true;

        // If the tokenAddress is zero, the payment should be in Ether, otherwise in ERC20.
        address tokenAddress = vault.token;
        if (tokenAddress == address(0)) {
            if (msg.value != requiredAmount) revert IncorrectFee(vaultId, msg.value, requiredAmount);
        } else {
            if (msg.value != 0) revert IncorrectFee(vaultId, msg.value, 0);
            if (!IERC20(tokenAddress).transferFrom(msg.sender, address(this), requiredAmount))
                revert TransferFailed(msg.sender, address(this));
        }

        emit FeeReceived(vaultId, msg.sender, requiredAmount);
    }

    function withdraw(uint256 vaultId) external {
        if (vaultId >= vaults.length) revert VaultDoesNotExist(vaultId);

        Vault storage vault = vaults[vaultId];
        uint256 collected = vault.collected;
        vault.collected = 0;

        // Calculate fees to receive. Guild's part is truncated - the remainder goes to the owner.
        uint256 guildAmount = (collected * guildShareBps) / 10000;
        uint256 ownerAmount = collected - guildAmount;

        // If the tokenAddress is zero, the collected fees are in Ether, otherwise in ERC20.
        address tokenAddress = vault.token;
        if (tokenAddress == address(0)) _withdrawEther(guildAmount, ownerAmount, vault.owner);
        else _withdrawToken(guildAmount, ownerAmount, vault.owner, tokenAddress);

        emit Withdrawn(vaultId, guildAmount, ownerAmount);
    }

    function setGuildFeeCollector(address payable newFeeCollector) external {
        if (msg.sender != guildFeeCollector) revert AccessDenied(msg.sender, guildFeeCollector);
        guildFeeCollector = newFeeCollector;
        emit GuildFeeCollectorChanged(newFeeCollector);
    }

    function setGuildShareBps(uint96 newShare) external {
        if (msg.sender != guildFeeCollector) revert AccessDenied(msg.sender, guildFeeCollector);
        guildShareBps = newShare;
        emit GuildShareBpsChanged(newShare);
    }

    function setVaultDetails(uint256 vaultId, address newOwner, bool newMultiplePayments, uint120 newFee) external {
        if (vaultId >= vaults.length) revert VaultDoesNotExist(vaultId);
        Vault storage vault = vaults[vaultId];

        if (msg.sender != vault.owner) revert AccessDenied(msg.sender, vault.owner);

        vault.owner = newOwner;
        vault.multiplePayments = newMultiplePayments;
        vault.fee = newFee;

        emit VaultDetailsChanged(vaultId);
    }

    function getVault(
        uint256 vaultId
    ) external view returns (address owner, address token, bool multiplePayments, uint120 fee, uint128 collected) {
        if (vaultId >= vaults.length) revert VaultDoesNotExist(vaultId);
        Vault storage vault = vaults[vaultId];
        return (vault.owner, vault.token, vault.multiplePayments, vault.fee, vault.collected);
    }

    function hasPaid(uint256 vaultId, address account) external view returns (bool paid) {
        if (vaultId >= vaults.length) revert VaultDoesNotExist(vaultId);
        return vaults[vaultId].paid[account];
    }

    function _withdrawEther(uint256 guildAmount, uint256 ownerAmount, address eventOwner) internal {
        guildFeeCollector.sendEther(guildAmount);
        payable(eventOwner).sendEther(ownerAmount);
    }

    function _withdrawToken(
        uint256 guildAmount,
        uint256 ownerAmount,
        address eventOwner,
        address tokenAddress
    ) internal {
        IERC20 token = IERC20(tokenAddress);
        if (!token.transfer(guildFeeCollector, guildAmount)) revert TransferFailed(address(this), guildFeeCollector);
        if (!token.transfer(eventOwner, ownerAmount)) revert TransferFailed(address(this), eventOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title A smart contract for registering vaults for payments.
interface IFeeCollector {
    struct Vault {
        address owner;
        address token;
        bool multiplePayments;
        uint120 fee;
        uint128 collected;
        mapping(address => bool) paid;
    }

    /// @notice Registers a vault and it's fee.
    /// @param owner The address that receives the fees from the payment.
    /// @param token The zero address for Ether, otherwise an ERC20 token.
    /// @param multiplePayments Whether the fee can be paid multiple times.
    /// @param fee The amount of fee to pay in base units.
    function registerVault(address owner, address token, bool multiplePayments, uint120 fee) external;

    /// @notice Registers the paid fee, both in Ether or ERC20.
    /// @param vaultId The id of the vault to pay to.
    function payFee(uint256 vaultId) external payable;

    /// @notice Sets the address that receives Guild's share from the funds.
    /// @dev Callable only by the current Guild fee collector.
    /// @param newFeeCollector The new address of guildFeeCollector.
    function setGuildFeeCollector(address payable newFeeCollector) external;

    /// @notice Sets Guild's share from the funds.
    /// @dev Callable only by the Guild fee collector.
    /// @param newShare The percentual value expressed in basis points.
    function setGuildShareBps(uint96 newShare) external;

    /// @notice Changes the details of a vault.
    /// @dev Callable only by the owner of the vault to be changed.
    /// @param vaultId The id of the vault whose details should be changed.
    /// @param newOwner The address that will receive the fees from now on.
    /// @param newMultiplePayments Whether the fee can be paid multiple times from now on.
    /// @param newFee The amount of fee to pay in base units from now on.
    function setVaultDetails(uint256 vaultId, address newOwner, bool newMultiplePayments, uint120 newFee) external;

    /// @notice Distributes the funds from a vault to the fee collectors and the owner.
    /// @param vaultId The id of the vault whose funds should be distributed.
    function withdraw(uint256 vaultId) external;

    /// @notice Returns a vault's details.
    /// @param vaultId The id of the queried vault.
    /// @return owner The owner of the vault who recieves the funds.
    /// @return token The address of the token to receive funds in (the zero address in case of Ether).
    /// @return multiplePayments Whether the fee can be paid multiple times.
    /// @return fee The amount of required funds in base units.
    /// @return collected The amount of already collected funds.
    function getVault(
        uint256 vaultId
    ) external view returns (address owner, address token, bool multiplePayments, uint120 fee, uint128 collected);

    /// @notice Returns if an account has paid the fee to a vault.
    /// @param vaultId The id of the queried vault.
    /// @param account The address of the queried account.
    function hasPaid(uint256 vaultId, address account) external view returns (bool paid);

    /// @notice Returns the address that receives Guild's share from the funds.
    function guildFeeCollector() external view returns (address payable);

    /// @notice Returns the percentage of Guild's share expressed in basis points.
    function guildShareBps() external view returns (uint96);

    /// @notice Event emitted when a call to {payFee} succeeds.
    /// @param vaultId The id of the vault that received the payment.
    /// @param account The address of the account that paid.
    /// @param amount The amount of fee received in base units.
    event FeeReceived(uint256 indexed vaultId, address indexed account, uint256 amount);

    /// @notice Event emitted when the Guild fee collector address is changed.
    /// @param newFeeCollector The address to change guildFeeCollector to.
    event GuildFeeCollectorChanged(address newFeeCollector);

    /// @notice Event emitted when the share of the Guild fee collector changes.
    /// @param newShare The new value of guildShareBps.
    event GuildShareBpsChanged(uint96 newShare);

    /// @notice Event emitted when a vault's details are changed.
    /// @param vaultId The id of the altered vault.
    event VaultDetailsChanged(uint256 vaultId);

    /// @notice Event emitted when a new vault is registered.
    /// @param owner The address that receives the fees from the payment.
    /// @param token The zero address for Ether, otherwise an ERC20 token.
    /// @param fee The amount of fee to pay in base units.
    event VaultRegistered(uint256 vaultId, address indexed owner, address indexed token, uint256 fee);

    /// @notice Event emitted when funds are withdrawn by a vault owner.
    /// @param vaultId The id of the vault.
    /// @param guildAmount The amount received by the Guild fee collector in base units.
    /// @param ownerAmount The amount received by the vault's owner in base units.
    event Withdrawn(uint256 indexed vaultId, uint256 guildAmount, uint256 ownerAmount);

    /// @notice Error thrown when multiple payments aren't enabled, but the sender attempts to pay repeatedly.
    /// @param vaultId The id of the vault.
    /// @param sender The sender of the transaction.
    error AlreadyPaid(uint256 vaultId, address sender);

    /// @notice Error thrown when an incorrect amount of fee is attempted to be paid.
    /// @dev requiredAmount might be 0 in cases when an ERC20 payment was expected but Ether was received, too.
    /// @param vaultId The id of the vault.
    /// @param paid The amount of funds received.
    /// @param requiredAmount The amount of fees required by the vault.
    error IncorrectFee(uint256 vaultId, uint256 paid, uint256 requiredAmount);

    /// @notice Error thrown when a function is attempted to be called by the wrong address.
    /// @param sender The address that sent the transaction.
    /// @param owner The address that is allowed to call the function.
    error AccessDenied(address sender, address owner);

    /// @notice Error thrown when an ERC20 transfer failed.
    /// @param from The sender of the token.
    /// @param to The recipient of the token.
    error TransferFailed(address from, address to);

    /// @notice Error thrown when a vault does not exist.
    /// @param vaultId The id of the requested vault.
    error VaultDoesNotExist(uint256 vaultId);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Library for functions related to addresses.
library LibAddress {
    /// @notice Error thrown when sending ether fails.
    /// @param recipient The address that could not receive the ether.
    error FailedToSendEther(address recipient);

    /// @notice Send ether to an address, forwarding all available gas and reverting on errors.
    /// @param recipient The recipient of the ether.
    /// @param amount The amount of ether to send in base units.
    function sendEther(address payable recipient, uint256 amount) internal {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = recipient.call{ value: amount }("");
        if (!success) revert FailedToSendEther(recipient);
    }
}