// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import { IFeeCollector } from "./interfaces/IFeeCollector.sol";
import { LibAddress } from "./lib/LibAddress.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract FeeCollector is IFeeCollector {
    using LibAddress for address payable;

    address payable public guildFeeCollector;
    uint96 public guildSharex100;

    address payable public poapFeeCollector;
    uint96 public poapSharex100;

    Vault[] internal vaults;

    constructor(
        address payable guildFeeCollector_,
        uint96 guildSharex100_,
        address payable poapFeeCollector_,
        uint96 poapSharex100_
    ) {
        guildFeeCollector = guildFeeCollector_;
        guildSharex100 = guildSharex100_;
        poapFeeCollector = poapFeeCollector_;
        poapSharex100 = poapSharex100_;
    }

    function registerVault(
        uint256 eventId,
        address owner,
        address token,
        uint128 fee
    ) external {
        Vault storage vault = vaults.push();
        vault.eventId = eventId;
        vault.owner = owner;
        vault.token = token;
        vault.fee = fee;
        emit VaultRegistered(vaults.length - 1, eventId, owner, token, fee);
    }

    function payFee(uint256 vaultId) external payable {
        if (vaultId >= vaults.length || vaults[vaultId].owner == address(0)) revert VaultDoesNotExist(vaultId);

        uint256 requiredAmount = vaults[vaultId].fee;
        vaults[vaultId].collected += uint128(requiredAmount);
        vaults[vaultId].paid[msg.sender] = true;

        // If the tokenAddress is zero, the payment should be in Ether, otherwise in ERC20.
        address tokenAddress = vaults[vaultId].token;
        if (tokenAddress == address(0)) {
            if (msg.value != requiredAmount) revert IncorrectFee(vaultId, msg.value, requiredAmount);
        } else {
            if (msg.value != 0) revert IncorrectFee(vaultId, msg.value, 0);
            if (!IERC20(vaults[vaultId].token).transferFrom(msg.sender, address(this), requiredAmount))
                revert TransferFailed(msg.sender, address(this));
        }

        emit FeeReceived(vaultId, msg.sender, requiredAmount);
    }

    function withdraw(uint256 vaultId) external {
        address eventOwner = vaults[vaultId].owner;
        if (vaultId >= vaults.length || eventOwner == address(0)) revert VaultDoesNotExist(vaultId);

        uint256 collected = vaults[vaultId].collected;
        vaults[vaultId].collected = 0;

        uint256 guildAmount = (collected * poapSharex100) / 10000;
        uint256 poapAmount = (collected * poapSharex100) / 10000;
        uint256 ownerAmount = collected - poapAmount - guildAmount;

        // If the tokenAddress is zero, the collected fees are in Ether, otherwise in ERC20.
        address tokenAddress = vaults[vaultId].token;
        if (tokenAddress == address(0)) _withdrawEther(guildAmount, poapAmount, ownerAmount, eventOwner);
        else _withdrawToken(guildAmount, poapAmount, ownerAmount, eventOwner, tokenAddress);

        emit Withdrawn(vaultId, guildAmount, poapAmount, ownerAmount);
    }

    function setGuildFeeCollector(address payable newFeeCollector) external {
        if (msg.sender != guildFeeCollector) revert OnlyOwner(msg.sender, guildFeeCollector);
        guildFeeCollector = newFeeCollector;
        emit GuildFeeCollectorChanged(newFeeCollector);
    }

    function setGuildSharex100(uint96 newShare) external {
        if (msg.sender != guildFeeCollector) revert OnlyOwner(msg.sender, guildFeeCollector);
        guildSharex100 = newShare;
        emit GuildSharex100Changed(newShare);
    }

    function setPoapFeeCollector(address payable newFeeCollector) external {
        if (msg.sender != poapFeeCollector) revert OnlyOwner(msg.sender, poapFeeCollector);
        poapFeeCollector = newFeeCollector;
        emit PoapFeeCollectorChanged(newFeeCollector);
    }

    function setPoapSharex100(uint96 newShare) external {
        if (msg.sender != poapFeeCollector) revert OnlyOwner(msg.sender, poapFeeCollector);
        poapSharex100 = newShare;
        emit PoapSharex100Changed(newShare);
    }

    function getVault(uint256 vaultId)
        external
        view
        returns (
            uint256 eventId,
            address owner,
            address token,
            uint128 fee,
            uint128 collected
        )
    {
        Vault storage vault = vaults[vaultId];
        return (vault.eventId, vault.owner, vault.token, vault.fee, vault.collected);
    }

    function hasPaid(uint256 vaultId, address account) external view returns (bool paid) {
        return vaults[vaultId].paid[account];
    }

    function _withdrawEther(
        uint256 guildAmount,
        uint256 poapAmount,
        uint256 ownerAmount,
        address eventOwner
    ) internal {
        guildFeeCollector.sendEther(guildAmount);
        poapFeeCollector.sendEther(poapAmount);
        payable(eventOwner).sendEther(ownerAmount);
    }

    function _withdrawToken(
        uint256 guildAmount,
        uint256 poapAmount,
        uint256 ownerAmount,
        address eventOwner,
        address tokenAddress
    ) internal {
        IERC20 token = IERC20(tokenAddress);
        if (!token.transfer(guildFeeCollector, guildAmount)) revert TransferFailed(address(this), guildFeeCollector);
        if (!token.transfer(poapFeeCollector, poapAmount)) revert TransferFailed(address(this), poapFeeCollector);
        if (!token.transfer(eventOwner, ownerAmount)) revert TransferFailed(address(this), eventOwner);
    }
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
    /// @param amount The amount of ether to send in wei.
    function sendEther(address payable recipient, uint256 amount) internal {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = recipient.call{ value: amount }("");
        if (!success) revert FailedToSendEther(recipient);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IFeeCollector {
    struct Vault {
        uint256 eventId;
        address owner;
        address token;
        uint128 fee;
        uint128 collected;
        mapping(address => bool) paid;
    }

    /// @notice Registers a POAP drop and it's fee.
    /// @param eventId The id of the POAP drop.
    /// @param owner The address that receives the fees from the drop.
    /// @param token Ether if 0, otherwise an ERC20 token.
    /// @param fee The amount of fee to pay in wei.
    function registerVault(
        uint256 eventId,
        address owner,
        address token,
        uint128 fee
    ) external;

    /// @notice Registers the paid fee, both in Ether or ERC20.
    /// @param vaultId The id of the vault to pay to.
    function payFee(uint256 vaultId) external payable;

    /// @notice Sets the address that receives Guild's share from the funds.
    /// @param newFeeCollector The new address of guildFeeCollector.
    function setGuildFeeCollector(address payable newFeeCollector) external;

    /// @notice Sets Guild's share from the funds.
    /// @param newShare The percentual value multiplied by 100.
    function setGuildSharex100(uint96 newShare) external;

    /// @notice Sets the address that receives POAP's share from the funds.
    /// @param newFeeCollector The new address of poapFeeCollector.
    function setPoapFeeCollector(address payable newFeeCollector) external;

    /// @notice Sets POAP's share from the funds.
    /// @param newShare The percentual value multiplied by 100.
    function setPoapSharex100(uint96 newShare) external;

    /// @notice Distributes the funds from a vault to the fee collectors and the owner.
    /// @param vaultId The id of the vault who's funds should be distributed.
    function withdraw(uint256 vaultId) external;

    /// @notice Returns a vault's details.
    /// @param vaultId The id of the queried vault.
    /// @return eventId The id of the POAP drop.
    /// @return owner The owner of the vault who recieves the funds.
    /// @return token The address of the token to receive funds in (0 in case of Ether).
    /// @return fee The amount of funds to accepted in wei.
    /// @return collected The amount of already collected funds.
    function getVault(uint256 vaultId)
        external
        view
        returns (
            uint256 eventId,
            address owner,
            address token,
            uint128 fee,
            uint128 collected
        );

    /// @notice Returns if an account has paid the fee to a vault.
    /// @param vaultId The id of the queried vault.
    /// @param account The address of the queried account.
    function hasPaid(uint256 vaultId, address account) external view returns (bool paid);

    /// @notice Returns the address that receives Guild's share from the funds.
    function guildFeeCollector() external view returns (address payable);

    /// @notice Returns the percentage of Guild's share multiplied by 100.
    function guildSharex100() external view returns (uint96);

    /// @notice Returns the address that receives POAP's share from the funds.
    function poapFeeCollector() external view returns (address payable);

    /// @notice Returns the percentage of POAP's share multiplied by 100.
    function poapSharex100() external view returns (uint96);

    /// @notice Event emitted when a call to {payFee} succeeds.
    /// @param vaultId The id of the vault that received the payment.
    /// @param account The address of the account that paid.
    /// @param amount The amount of fee received in wei.
    event FeeReceived(uint256 indexed vaultId, address indexed account, uint256 amount);

    /// @notice Event emitted when the Guild fee collector address is changed.
    /// @param newFeeCollector The address to change guildFeeCollector to.
    event GuildFeeCollectorChanged(address newFeeCollector);

    /// @notice Event emitted when the share of the Guild fee collector changes.
    /// @param newShare The new value of guildSharex100.
    event GuildSharex100Changed(uint96 newShare);

    /// @notice Event emitted when the POAP fee collector address is changed.
    /// @param newFeeCollector The address to change poapFeeCollector to.
    event PoapFeeCollectorChanged(address newFeeCollector);

    /// @notice Event emitted when the share of the POAP fee collector changes.
    /// @param newShare The new value of poapSharex100.
    event PoapSharex100Changed(uint96 newShare);

    /// @notice Event emitted when a new vault is registered.
    /// @param eventId The id of the POAP drop.
    /// @param owner The address that receives the fees from the drop.
    /// @param token Ether if 0, otherwise an ERC20 token.
    /// @param fee The amount of fee to pay in wei.
    event VaultRegistered(
        uint256 vaultId,
        uint256 indexed eventId,
        address indexed owner,
        address indexed token,
        uint256 fee
    );

    /// @notice Event emitted when funds are withdrawn by a vault owner.
    /// @param vaultId The id of the vault.
    /// @param guildAmount The amount received by the Guild fee collector in wei.
    /// @param poapAmount The amount received by the POAP fee collector in wei.
    /// @param ownerAmount The amount received by the vault's owner in wei.
    event Withdrawn(uint256 indexed vaultId, uint256 guildAmount, uint256 poapAmount, uint256 ownerAmount);

    /// @notice Error thrown when an incorrect amount of fee is attempted to be paid.
    /// @dev requiredAmount might be 0 in cases when an ERC20 payment was expected but Ether was received, too.
    /// @param vaultId The id of the vault.
    /// @param paid The amount of funds received.
    /// @param requiredAmount The amount of fees required by the vault.
    error IncorrectFee(uint256 vaultId, uint256 paid, uint256 requiredAmount);

    /// @notice Error thrown when a function is attempted to be called by the wrong address.
    /// @param sender The address that sent the transaction.
    /// @param owner The address that is allowed to call the function.
    error OnlyOwner(address sender, address owner);

    /// @notice Error thrown when an ERC20 transfer failed.
    /// @param from The sender of the token.
    /// @param to The recipient of the token.
    error TransferFailed(address from, address to);

    /// @notice Error thrown when a vault does not exist.
    /// @param vaultId The id of the requested vault.
    error VaultDoesNotExist(uint256 vaultId);
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