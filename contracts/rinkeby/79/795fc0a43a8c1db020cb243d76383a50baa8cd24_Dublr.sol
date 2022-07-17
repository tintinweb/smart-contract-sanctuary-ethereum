/**
 *Submitted for verification at Etherscan.io on 2022-07-17
*/

// Sources flattened with hardhat v2.9.9 https://hardhat.org

// File contracts/main/OmniToken/interfaces/IERC165.sol

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

/**
 * @dev Determine whether or not this contract supports a given interface, as defined by ERC165.
 */
interface IERC165 {
    /**
     * @notice Determine whether or not this contract supports a given interface.
     *
     * @dev [ERC165] Implements the ERC165 API.
     * 
     * @param interfaceId The result of xor-ing together the function selectors of all functions in the interface
     * of interest.
     * @return implementsInterface `true` if this contract implements the requested interface.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}


// File contracts/main/OmniToken/interfaces/IERC1820Registry.sol


pragma solidity 0.8.15;

/** @dev Interface for ERC1820 registry. */
interface IERC1820Registry {
    /// @notice Indicates a contract is the 'implementer' of 'interfaceHash' for 'addr'.
    event InterfaceImplementerSet(address indexed addr, bytes32 indexed interfaceHash, address indexed implementer);
    /// @notice Indicates 'newManager' is the address of the new manager for 'addr'.
    event ManagerChanged(address indexed addr, address indexed newManager);

    /// @notice Query if an address implements an interface and through which contract.
    /// @param _addr Address being queried for the implementer of an interface.
    /// (If '_addr' is the zero address then 'msg.sender' is assumed.)
    /// @param _interfaceHash Keccak256 hash of the name of the interface as a string.
    /// E.g., 'web3.utils.keccak256("ERC777TokensRecipient")' for the 'ERC777TokensRecipient' interface.
    /// @return The address of the contract which implements the interface '_interfaceHash' for '_addr'
    /// or '0' if '_addr' did not register an implementer for this interface.
    function getInterfaceImplementer(address _addr, bytes32 _interfaceHash) external view returns (address);

    /// @notice Sets the contract which implements a specific interface for an address.
    /// Only the manager defined for that address can set it.
    /// (Each address is the manager for itself until it sets a new manager.)
    /// @param _addr Address for which to set the interface.
    /// (If '_addr' is the zero address then 'msg.sender' is assumed.)
    /// @param _interfaceHash Keccak256 hash of the name of the interface as a string.
    /// E.g., 'web3.utils.keccak256("ERC777TokensRecipient")' for the 'ERC777TokensRecipient' interface.
    /// @param _implementer Contract address implementing '_interfaceHash' for '_addr'.
    function setInterfaceImplementer(address _addr, bytes32 _interfaceHash, address _implementer) external;

    /// @notice Sets '_newManager' as manager for '_addr'.
    /// The new manager will be able to call 'setInterfaceImplementer' for '_addr'.
    /// @param _addr Address for which to set the new manager.
    /// @param _newManager Address of the new manager for 'addr'. (Pass '0x0' to reset the manager to '_addr'.)
    function setManager(address _addr, address _newManager) external;

    /// @notice Get the manager of an address.
    /// @param _addr Address for which to return the manager.
    /// @return Address of the manager for a given address.
    function getManager(address _addr) external view returns(address);

    /// @notice Compute the keccak256 hash of an interface given its name.
    /// @param _interfaceName Name of the interface.
    /// @return The keccak256 hash of an interface name.
    function interfaceHash(string calldata _interfaceName) external pure returns(bytes32);

    /* --- ERC165 Related Functions --- */
    /* --- Developed in collaboration with William Entriken. --- */

    /// @notice Updates the cache with whether the contract implements an ERC165 interface or not.
    /// @param _contract Address of the contract for which to update the cache.
    /// @param _interfaceId ERC165 interface for which to update the cache.
    function updateERC165Cache(address _contract, bytes4 _interfaceId) external;

    /// @notice Checks whether a contract implements an ERC165 interface or not.
    //  If the result is not cached a direct lookup on the contract address is performed.
    //  If the result is not cached or the cached value is out-of-date, the cache MUST be updated manually by calling
    //  'updateERC165Cache' with the contract address.
    /// @param _contract Address of the contract to check.
    /// @param _interfaceId ERC165 interface to check.
    /// @return True if '_contract' implements '_interfaceId', false otherwise.
    function implementsERC165Interface(address _contract, bytes4 _interfaceId) external view returns (bool);

    /// @notice Checks whether a contract implements an ERC165 interface or not without using nor updating the cache.
    /// @param _contract Address of the contract to check.
    /// @param _interfaceId ERC165 interface to check.
    /// @return True if '_contract' implements '_interfaceId', false otherwise.
    function implementsERC165InterfaceNoCache(address _contract, bytes4 _interfaceId) external view returns (bool);
}


// File contracts/main/OmniToken/interfaces/IERC20.sol

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)
// From: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol

pragma solidity 0.8.15;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @notice Tokens transferred.
     * 
     * @dev [ERC20] Emitted when `amount` tokens are moved from `sender` to `recipient`.
     *
     * @param sender The account tokens were transferred from.
     * @param recipient The account tokens were transferred to.
     * @param amount The number of tokens transferred.
     */
    event Transfer(address indexed sender, address indexed recipient, uint256 amount);

    /**
     * @notice Allowance approved.
     *
     * @dev [ERC20] Emitted when `holder` authorizes `spender` to spend `amount` tokens on their behalf.
     *
     * @param holder The token holder granting authorization.
     * @param spender The account granted authorization to spned on behalf of `holder`.
     * @param amount The allowance (the number of tokens `spender` may spend on behalf of `holder`).
     */
    event Approval(address indexed holder, address indexed spender, uint256 amount);

    /**
     * @notice The total supply of tokens.
     *
     * @return supply The total supply of tokens.
     */
    function totalSupply() external view returns (uint256 supply);

    /**
     * @notice The number of tokens owned by a given address.
     *
     * @param holder The address to query.
     * @return amount The number of tokens owned by `holder`.
     */
    function balanceOf(address holder) external view returns (uint256 amount);

    /**
     * @notice Get the number of tokens that `spender` can spend on behalf of `holder`.
     *
     * @dev [ERC20] Returns the remaining number of tokens that `spender` will be allowed to spend on
     * behalf of `holder`, via a call to `transferFrom`. Zero by default. Also returns zero if
     * allowance has expired.
     *
     * @notice By calling this function, you confirm that this token is not considered an unregistered or
     * illegal security, and that this smart contract is not considered an unregistered or illegal exchange,
     * by the laws of any legal jurisdiction in which you hold or use tokens, or any legal jurisdiction
     * of the holder or spender.
     * 
     * @notice In some jurisdictions, such as the United States, any use, transfer, or sale of a token is a taxable
     * event. It is your responsibility to record the purchase price and sale price in ETH or your local currency
     * for each use, transfer, or sale of tokens you own, and to pay the taxes due.
     *
     * @param holder The token holder.
     * @param spender The token spender.
     * @return amount The allowance of `spender` to spend the funds of `holder`.
     */
    function allowance(address holder, address spender) external view returns (uint256 amount);

    /**
     * @notice Approve another account (or contract) to spend tokens on your behalf.
     *
     * @dev [ERC20] Approves a `spender` to be allowed to spend `allowedAmount` tokens on behalf of the
     * caller, via a call to `transferFrom`.
     *
     * @notice By calling this function, you confirm that this token is not considered an unregistered or
     * illegal security, and that this smart contract is not considered an unregistered or illegal exchange,
     * by the laws of any legal jurisdiction in which you hold or use tokens, or any legal jurisdiction
     * of the holder or spender.
     * 
     * @notice In some jurisdictions, such as the United States, any use, transfer, or sale of a token is a taxable
     * event. It is your responsibility to record the purchase price and sale price in ETH or your local currency
     * for each use, transfer, or sale of tokens you own, and to pay the taxes due.
     *
     * @param spender The spender.
     * @param amount The allowance amount. Use a value of `0` to disallow `spender` spending tokens on behalf
     *          of the caller. Use a value of `2**256-1` to set unlimited allowance, if unlimited allowances are
     *          enabled. The allowed amount may be greater than the account balance.
     * @return success `true` if the approval succeeded (otherwise reverts).
     */
    function approve(address spender, uint256 amount) external returns (bool success);

    /**
     * @notice Transfer tokens to another account.
     *
     * @dev [ERC20] Moves `amount` tokens from the caller's account to `recipient`.
     *
     * @notice By calling this function, you confirm that this token is not considered an unregistered or
     * illegal security, and that this smart contract is not considered an unregistered or illegal exchange,
     * by the laws of any legal jurisdiction in which you hold or use tokens, or any legal jurisdiction
     * of the recipient.
     * 
     * @notice In some jurisdictions, such as the United States, any use, transfer, or sale of a token is a taxable
     * event. It is your responsibility to record the purchase price and sale price in ETH or your local currency
     * for each use, transfer, or sale of tokens you own, and to pay the taxes due.
     *
     * @param recipient The token recipient.
     * @param amount The number of tokens to transfer from the caller to `recipient`.
     * @return success `true` if the operation succeeded (otherwise reverts).
     */
    function transfer(address recipient, uint256 amount) external returns (bool success);

    /**
     * @notice Transfer tokens from a holder account to a recipient account account, on behalf of the holder.
     *
     * @dev [ERC20] Moves `amount` tokens from `sender` to `recipient`. The caller must have previously been
     * approved by `sender` to send at least `amount` tokens on their behalf, by `sender` calling `approve`.
     * `amount` is deducted from the caller’s allowance (unless the allowance is set to unlimited).
     *
     * @notice By calling this function, you confirm that this token is not considered an unregistered or
     * illegal security, and that this smart contract is not considered an unregistered or illegal exchange,
     * by the laws of any legal jurisdiction in which you hold or use tokens, or any legal jurisdiction
     * of the holder or recipient.
     * 
     * @notice In some jurisdictions, such as the United States, any use, transfer, or sale of a token is a taxable
     * event. It is your responsibility to record the purchase price and sale price in ETH or your local currency
     * for each use, transfer, or sale of tokens you own, and to pay the taxes due.
     * 
     * @param holder The token holder.
     * @param recipient The token recipient.
     * @param amount The number of tokens to transfer from the caller to `recipient`.
     * @return success `true` if the operation succeeded (otherwise reverts).
     */
    function transferFrom(address holder, address recipient, uint256 amount) external returns (bool success);
}


// File contracts/main/OmniToken/interfaces/IERC20Optional.sol

// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)
//
// From:
// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/extensions/IERC20Metadata.sol

pragma solidity 0.8.15;

/** @dev Interface for the optional token information functions from the ERC20 standard. */
interface IERC20Optional is IERC20 {
    /** @dev The name of the token. */
    function name() external view returns (string memory tokenName);

    /** @dev The token symbol. */
    function symbol() external view returns (string memory tokenSymbol);

    /**
     * @notice The number of decimal places used to display token balances.
     * (Hardcoded to the ETH-standard value of 18, as required by ERC777.)
     */
    function decimals() external view returns (uint8 numDecimals);
}


// File contracts/main/OmniToken/interfaces/IERC20Burn.sol


pragma solidity 0.8.15;

/**
 * @dev The ERC20 `burn` extension function.
 */
interface IERC20Burn {
    /**
     * @notice Burn tokens.
     *
     * @dev [ERC20 extension] Burn tokens. Destroys `amount` tokens from caller's account forever,
     * reducing the total supply. Use with caution, as this cannot be reverted, and you should ensure
     * that some other smart contract guarantees you some benefit for burning tokens before you burn
     * them.
     *
     * By convention, burning is logged as a transfer to the zero address.
     *
     * @param amount The amount to burn.
     */
    function burn(uint256 amount) external;
}


// File contracts/main/OmniToken/interfaces/IERC20SafeApproval.sol


pragma solidity 0.8.15;

/**
 * @dev An ERC20 safe approval protocol suggested in:
 * "ERC20 API: An Attack Vector on Approve/TransferFrom Methods"
 * https://docs.google.com/document/d/1YLPtQxZu1UAvO9cZ1O2RPXBbT0mooh4DYKjA_jp-RLM/edit
 */
interface IERC20SafeApproval {
    /**
     * @notice Transfer event for safe "compare and set" approval alternative.
     *
     * @dev This is designed to mitigate the ERC-20 allowance attack described in:
     *
     * "ERC20 API: An Attack Vector on Approve/TransferFrom Methods"
     * https://docs.google.com/document/d/1YLPtQxZu1UAvO9cZ1O2RPXBbT0mooh4DYKjA_jp-RLM/edit
     *
     * Note that this event is named `Transfer` in the original proposal, but it has been renamed to
     * `TransferInfo` here because ERC20 already defines an event with the name `Transfer` (and
     * Ethers doesn't like contracts that have two events with the same name).
     *
     * @param spender The spender.
     * @param from The sender.
     * @param to The recipient.
     * @param value The amount transferred (may be zero).
     */
    event TransferInfo(address indexed spender, address indexed from, address indexed to, uint256 value);

    /**
     * @notice Approval event for safe "compare and set" approval alternative.
     *
     * @dev This is designed to mitigate the ERC-20 allowance attack described in:
     *
     * "ERC20 API: An Attack Vector on Approve/TransferFrom Methods"
     * https://docs.google.com/document/d/1YLPtQxZu1UAvO9cZ1O2RPXBbT0mooh4DYKjA_jp-RLM/edit
     *
     * Note that this event is named `Approval` in the original proposal, but it has been renamed to
     * `ApprovalInfo` here because ERC20 already defines an event with the name `Approval` (and
     * Ethers doesn't like contracts that have two events with the same name).
     *
     * @param holder The token holder.
     * @param spender The spender granted an allowance.
     * @param oldValue The previous value of the allowance.
     * @param value The new allowance to set.
     */
    event ApprovalInfo(address indexed holder, address indexed spender, uint256 oldValue, uint256 value);

    /**
     * @notice Safely "compare and set" the allowance for a spender to spend your tokens.
     * 
     * @dev [ERC20 extension] Atomically compare-and-set the allowance for a spender.
     * This is designed to mitigate the ERC-20 allowance attack described in:
     *
     * "ERC20 API: An Attack Vector on Approve/TransferFrom Methods"
     * https://docs.google.com/document/d/1YLPtQxZu1UAvO9cZ1O2RPXBbT0mooh4DYKjA_jp-RLM/edit
     *
     * @notice By calling this function, you confirm that this token is not considered an unregistered or
     * illegal security, and that this smart contract is not considered an unregistered or illegal exchange,
     * by the laws of any legal jurisdiction in which you hold or use tokens, or any legal jurisdiction
     * of the holder or spender.
     * 
     * @notice In some jurisdictions, such as the United States, any use, transfer, or sale of a token is a taxable
     * event. It is your responsibility to record the purchase price and sale price in ETH or your local currency
     * for each use, transfer, or sale of tokens you own, and to pay the taxes due.
     *
     * @param spender The spender.
     * @param expectedCurrentAmount The expected amount of `spender`'s current allowance.
     *        If the current allowance does not match this value, then the transaction will revert.
     * @param amount The new allowance amount.
     * @return success `true` if the operation succeeded (otherwise reverts).
     */
    function approve(address spender, uint256 expectedCurrentAmount, uint256 amount) external returns (bool success);
}


// File contracts/main/OmniToken/interfaces/IERC20IncreaseDecreaseAllowance.sol


pragma solidity 0.8.15;

/**
 * @dev Non-standard API for safe approvals that can be used as a mitigation for the double-spend race condition
 * attack described here:
 * https://docs.openzeppelin.com/contracts/2.x/api/token/erc20#ERC20-increaseAllowance-address-uint256-
 */
interface IERC20IncreaseDecreaseAllowance {
    /**
     * @notice Safely increase the allowance for a spender to spend your tokens.
     *
     * @dev [ERC20 extension] Increases the ERC20 token allowance granted to `spender` by the caller.
     * This is an alternative to `approve` that can mitigate for the double-spend race condition attack
     * that is described here:
     *
     * https://docs.google.com/document/d/1YLPtQxZu1UAvO9cZ1O2RPXBbT0mooh4DYKjA_jp-RLM/edit
     *
     * N.B. the transaction will revert if the allowance is currently set to the unlimited allowance
     * amount of `2**256-1`, since the correct new allowance amount cannot be determined by addition.
     *
     * @notice By calling this function, you confirm that this token is not considered an unregistered or
     * illegal security, and that this smart contract is not considered an unregistered or illegal exchange,
     * by the laws of any legal jurisdiction in which you hold or use tokens, or any legal jurisdiction
     * of the holder or spender.
     * 
     * @notice In some jurisdictions, such as the United States, any use, transfer, or sale of a token is a taxable
     * event. It is your responsibility to record the purchase price and sale price in ETH or your local currency
     * for each use, transfer, or sale of tokens you own, and to pay the taxes due.
     *
     * @param spender The token spender.
     * @param amountToAdd The number of tokens by which to increase the allowance of `spender`.
     * @return success `true` if the operation succeeded (otherwise reverts).
     */
    function increaseAllowance(address spender, uint256 amountToAdd) external returns (bool success);

    /**
     * @notice Safely decrease the allowance for a spender to spend your tokens.
     *
     * @dev [ERC20 extension] Decreases the ERC20 token allowance granted to `spender` by the caller.
     * This is an alternative to `approve` that can mitigate for the double-spend race condition attack
     * that is described here:
     *
     * https://docs.google.com/document/d/1YLPtQxZu1UAvO9cZ1O2RPXBbT0mooh4DYKjA_jp-RLM/edit
     *
     * N.B. the transaction will revert if the allowance is currently set to the unlimited allowance
     * amount of `2**256-1`, since the correct new allowance amount cannot be determined by subtraction.
     *
     * @notice By calling this function, you confirm that this token is not considered an unregistered or
     * illegal security, and that this smart contract is not considered an unregistered or illegal exchange,
     * by the laws of any legal jurisdiction in which you hold or use tokens, or any legal jurisdiction
     * of the holder or spender.
     * 
     * @notice In some jurisdictions, such as the United States, any use, transfer, or sale of a token is a taxable
     * event. It is your responsibility to record the purchase price and sale price in ETH or your local currency
     * for each use, transfer, or sale of tokens you own, and to pay the taxes due.
     *
     * @param spender The token spender.
     * @param amountToSubtract The number of tokens by which to decrease the allowance of `spender`.
     * @return success `true` if the operation succeeded (otherwise reverts).
     *         Note that this operation will revert if amountToSubtract is greater than the current allowance.
     */
    function decreaseAllowance(address spender, uint256 amountToSubtract) external returns (bool success);
}


// File contracts/main/OmniToken/interfaces/IERC20TimeLimitedTokenAllowances.sol


pragma solidity 0.8.15;

/**
 * @dev Time-limited token allowances, as proposed in the following draft:
 *
 * https://github.com/vrypan/EIPs/blob/master/EIPS/eip-draft_time_limited_token_allowances.md
 */
interface IERC20TimeLimitedTokenAllowances {
    /**
     * @notice Emitted when the allowance of a `spender` for a `holder` is set by a call to `approve`.
     *
     * @dev This event is not part of the proposal for this ERC20 extension, and we log expiration
     * time rather than expiration block number.
     *
     * @param holder The token holder.
     * @param spender The spender.
     * @param value The new allowance.
     * @param expirationTimestamp the block timestamp after which the approval will expire. (Note that this is
     *          the actual expiration timestamp, not the number of seconds the approval should last for, which
     *          is passed into `approveWithExpiration`.)
     */
    event ApprovalWithExpiration(address indexed holder, address indexed spender, uint256 value,
            uint256 expirationTimestamp);

    /**
     * @notice Approve a spender to spend your tokens with a specified expiration time.
     *
     * @dev ERC20 extension function for approving with time-limited allowances.
     *
     * See: https://github.com/vrypan/EIPs/blob/master/EIPS/eip-draft_time_limited_token_allowances.md
     *
     * @notice By calling this function, you confirm that this token is not considered an unregistered or
     * illegal security, and that this smart contract is not considered an unregistered or illegal exchange,
     * by the laws of any legal jurisdiction in which you hold or use tokens, or any legal jurisdiction
     * of the holder or spender.
     * 
     * @notice In some jurisdictions, such as the United States, any use, transfer, or sale of a token is a taxable
     * event. It is your responsibility to record the purchase price and sale price in ETH or your local currency
     * for each use, transfer, or sale of tokens you own, and to pay the taxes due.
     *
     * @param spender The token spender.
     * @param amount The amount to allow.
     * @param expirationSec The number of seconds after which the allowance expires, or `2**256-1` if the
     *          allowance should not expire (consider this unsafe), or `0` if spending must happen in the
     *          same block as approval (e.g. for a flash loan).
     *          Note: The proposal for this ERC20 extension API requires a user to specify the number of
     *          blocks an approval should be valid for before expiration. OmniToken uses seconds instead
     *          of number of blocks, because mining does not happen at a reliable interval.
     * @return success `true` if approval was successful.
     */
    function approveWithExpiration(address spender, uint256 amount, uint256 expirationSec) external
            returns (bool success);
    
    /**
     * @notice Get the expiration timestamp for the allowance of a spender to spend tokens on behalf of a holder.
     * 
     * @dev ERC20 extension function for returning the allowance amount and block timestamp after which allowance
     * expires. Expiration time will be `2**256-1` for allowances that do not expire, or smaller than that value
     * for time-limited allowances.
     *
     * See: https://github.com/vrypan/EIPs/blob/master/EIPS/eip-draft_time_limited_token_allowance.md
     *
     * @param holder The token holder.
     * @param spender The token spender.
     * @return remainingAmount The amount of the allowance remaining, or 0 if the allowance has expired.
     * @return expirationTimestamp The block timestamp after which the allowance expires.
     */
    function allowanceWithExpiration(address holder, address spender) external view
            returns (uint256 remainingAmount, uint256 expirationTimestamp);
}


// File contracts/main/OmniToken/interfaces/IERC777.sol

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC777/IERC777.sol)
//
// Modified from:
// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC777/IERC777.sol

pragma solidity 0.8.15;

/**
 * @dev Interface of the ERC777Token standard as defined in the ERC777.
 *
 * This contract uses the ERC1820 registry standard to let token holders (senders) and recipients register to be
 * notified of token movements, by implementing the appropriate interface.
 */
interface IERC777 {
    /**
     * @notice Tokens sent.
     *
     * @dev [ERC777] Emitted when tokens are sent from `holder` to `recipient`, possibly by another account
     *          (`operator`) on behalf of `holder`.
     *
     * @param operator The operator.
     * @param holder The account tokens were sent from.
     * @param recipient The account tokens were sent to.
     * @param amount The number of tokens sent.
     * @param data Extra data sent to `recipient`.
     * @param operatorData Extra data supplied by the operator to `recipient`.
     */
    event Sent(address indexed operator, address indexed holder, address indexed recipient, uint256 amount, bytes data,
        bytes operatorData);

    /**
     * @notice Tokens minted.
     *
     * @dev [ERC777] Emitted when `amount` tokens are created by `operator` and assigned to `account`.
     *
     * @param operator The operator.
     * @param account The account tokens were minted for.
     * @param amount The number of tokens minted.
     * @param data Extra data sent to `account`.
     * @param operatorData Extra data supplied by the operator to `account`.
     */
    event Minted(address indexed operator, address indexed account, uint256 amount, bytes data, bytes operatorData);

    /**
     * @notice Tokens burned.
     *
     * @dev [ERC777] Emitted when `operator` destroys `amount` tokens from `account`.
     *
     * @param operator The operator.
     * @param account The account tokens were burned for.
     * @param amount The number of tokens burned.
     * @param data Extra data sent to `account`.
     * @param operatorData Extra data supplied by the operator to `account`.
     */
    event Burned(address indexed operator, address indexed account, uint256 amount, bytes data, bytes operatorData);

    /**
     * @notice Operator status authorized.
     *
     * @dev [ERC777] Emitted when `operator` is made an operator for `account`.
     *
     * @param operator The operator.
     * @param account The account `operator` is authorized to act on behalf of.
     */
    event AuthorizedOperator(address indexed operator, address indexed account);

    /**
     * @notice Operator status revoked.
     *
     * @dev [ERC777] Emitted when `operator` has its operator status revoked for `account`.
     *
     * @param operator The operator.
     * @param account The account `operator` is no longer authorized to act on behalf of.
     */
    event RevokedOperator(address indexed operator, address indexed account);

    /** @notice The name of the token. */
    function name() external view returns (string memory);

    /** @notice The symbol of the token. */
    function symbol() external view returns (string memory);

    /**
     * @notice The granularity of the token.
     *
     * @dev [ERC777] For OmniToken, this value is 1 for compatibility with ERC20.
     */
    function granularity() external view returns (uint256 tokenGranularity);

    /** @notice The number of tokens in existence. */
    function totalSupply() external view returns (uint256 tokenSupply);

    /**
     * @notice The number of tokens owned by a given address.
     *
     * @param account The account to query.
     * @return balance The account balance.
     */
    function balanceOf(address account) external view returns (uint256 balance);

    /**
     * @notice Send tokens to a recipient.
     *
     * @dev [ERC777] Send `amount` tokens to `recipient`, passing `data` to the recipient. `recipient` must
     * implement the ERC777 recipient interface, unless it is a non-contract account (EOA wallet).
     *
     * @notice By calling this function, you confirm that this token is not considered an unregistered or
     * illegal security, and that this smart contract is not considered an unregistered or illegal exchange,
     * by the laws of any legal jurisdiction in which you hold or use tokens.
     * 
     * @notice In some jurisdictions, such as the United States, any use, transfer, or sale of a token is a taxable
     * event. It is your responsibility to record the purchase price and sale price in ETH or your local currency
     * for each use, transfer, or sale of tokens you own, and to pay the taxes due.
     *
     * @param recipient The address of the recipient.
     * @param amount The number of tokens to be sent.
     */
    function send(address recipient, uint256 amount, bytes calldata data) external;

    /**
     * @notice Burn tokens.
     *
     * @dev [ERC777] Burn tokens. Destroys `amount` tokens from caller's account forever,
     * reducing the total supply.
     *
     * Use with caution, as this cannot be reverted, and you should ensure that some other contract
     * guarantees you some benefit for burning tokens before you burn them.
     *
     * @param amount The number of tokens to burn.
     * @param data Extra data to log.
     */
    function burn(uint256 amount, bytes calldata data) external;

    /**
     * @notice Check whether an operator is authorized to manage the tokens held by a given address.
     *
     * @dev [ERC777] Checking whether `operator` is authorized to manage the tokens held by
     * `account` address. Returns `true` if `operator` is a non-revoked default operator, or has
     * been previously authorized (and not later revoked) by `account` calling `authorizeOperator(operator)`.
     *
     * @param operator address to check if it has the right to manage the tokens.
     * @param account address which holds the tokens to be managed.
     * @return isOperator `true` if `operator` is authorized for `account`.
     */
    function isOperatorFor(address operator, address account) external view returns (bool isOperator);

    /**
     * @notice Authorize another address, `operator`, to be able to send your tokens.
     *
     * @dev [ERC777] Authorize `operator` to be able to send the caller's tokens. The operator can then call
     * `operatorSend` to transfer the caller's tokens to a recipient.
     *
     * @param operator The operator to authorize.
     */
    function authorizeOperator(address operator) external;

    /**
     * @notice Revoke `operator` from being able to send your tokens.
     *
     * @dev [ERC777] Revoke `operator` from being able to send the caller's tokens.
     *
     * @param operator The operator to revoke.
     */
    function revokeOperator(address operator) external;

    /**
     * @notice The default operator list.
     *
     * @dev [ERC777] The list of default operators. These accounts are operators for all token holders,
     * even if `authorizeOperator` was never called on them.
     *
     * This list is immutable, but individual holders may revoke these via `revokeOperator`, in which case
     * `isOperatorFor` will return false.
     */
    function defaultOperators() external view returns (address[] memory);

    /**
     * @notice Send tokens on behalf of a token holder (or sender) that you have previously been authorized
     * to be an operator for.
     *
     * @dev [ERC777] Send `amount` tokens on behalf of the address `holder` to the address `recipient`.
     * The caller must have previously been authorized for as an operator for `holder`, by `holder`
     * calling `authorizeOperator`.
     *
     * The `holder` account may optionally implement the ERC777 sender interface to be notified when
     * tokens are sent.
     * 
     * `recipient` must implement the ERC777 recipient interface, unless it is a non-contract
     * account (EOA wallet).
     *
     * @notice By calling this function, you confirm that this token is not considered an unregistered or
     * illegal security, and that this smart contract is not considered an unregistered or illegal exchange,
     * by the laws of any legal jurisdiction in which you hold or use tokens, or any legal jursidiction
     * of the holder or recipient account.
     * 
     * @notice In some jurisdictions, such as the United States, any use, transfer, or sale of a token is a taxable
     * event. It is your responsibility to record the purchase price and sale price in ETH or your local currency
     * for each use, transfer, or sale of tokens you own, and to pay the taxes due.
     *
     * @param holder The address holding the tokens being sent.
     * @param recipient The address of the recipient.
     * @param amount The number of tokens to be sent.
     * @param data Data generated by the user to be sent to the recipient.
     * @param operatorData Data generated by the operator to be sent to the recipient.
     */
    function operatorSend(address holder, address recipient, uint256 amount, bytes calldata data,
        bytes calldata operatorData) external;

    /**
     * @notice Burn tokens.
     *
     * @dev [ERC777] Burn tokens. Destroys `amount` tokens from `account` account forever, reducing the total supply.
     * Caller must have previously been approved as an operator for `account`.
     *
     * Use with caution, as this cannot be reverted, and you should ensure that some other contract guarantees
     * you some benefit for burning tokens before you burn them.
     *
     * @param account The account to destroy tokens from.
     * @param amount The number of tokens to burn.
     * @param data Extra data to log.
     * @param operatorData Extra data to log.
     */
    function operatorBurn(address account, uint256 amount, bytes calldata data, bytes calldata operatorData) external;
}


// File contracts/main/OmniToken/interfaces/IERC1820InterfaceImplementer.sol


pragma solidity 0.8.15;

/**
 * @title IERC1820InterfaceImplementer
 */
interface IERC1820InterfaceImplementer {
    function canImplementInterfaceForAddress(bytes32 interfaceHash, address addr) external view returns(bytes32);
}


// File contracts/main/OmniToken/interfaces/IERC777Sender.sol


pragma solidity 0.8.15;

/**
 * @title IERC777Sender
 */
interface IERC777Sender is IERC1820InterfaceImplementer {
    function canImplementInterfaceForAddress(bytes32 interfaceHash, address addr)
            override(IERC1820InterfaceImplementer) external view returns(bytes32);
    function tokensToSend(address, address, address, uint256, bytes calldata, bytes calldata) external;
}


// File contracts/main/OmniToken/interfaces/IERC777Recipient.sol


pragma solidity 0.8.15;

/**
 * @title IERC777Recipient
 */
interface IERC777Recipient is IERC1820InterfaceImplementer {
    function canImplementInterfaceForAddress(bytes32 interfaceHash, address addr)
            override(IERC1820InterfaceImplementer) external view returns(bytes32);
    function tokensReceived(address, address sender, address, uint256, bytes calldata, bytes calldata) external;
}


// File contracts/main/OmniToken/interfaces/IERC1363.sol


pragma solidity 0.8.15;


/**
 * @dev Determine whether or not this contract supports a given interface, as defined by ERC165.
 *
 * Note: the ERC-165 identifier for this interface is 0xb0202a11.
 * 0xb0202a11 ===
 *   bytes4(keccak256('transferAndCall(address,uint256)')) ^
 *   bytes4(keccak256('transferAndCall(address,uint256,bytes)')) ^
 *   bytes4(keccak256('transferFromAndCall(address,address,uint256)')) ^
 *   bytes4(keccak256('transferFromAndCall(address,address,uint256,bytes)')) ^
 *   bytes4(keccak256('approveAndCall(address,uint256)')) ^
 *   bytes4(keccak256('approveAndCall(address,uint256,bytes)'))
 */
interface IERC1363 is IERC20, IERC165 {
    /**
     * @notice Transfer tokens to a recipient, and then call the ERC1363 recipient notification interface
     * on the recipient.
     *
     * @dev [ERC1363] Transfer tokens from the caller to `recipient`, and then call the ERC1363 receiver
     * interface's `onTransferReceived` on the recipient. The transaction will fail if the recipient does
     * not implement this interface (including if the recipient address is an EOA address).
     *
     * @notice By calling this function, you confirm that this token is not considered an unregistered or
     * illegal security, and that this smart contract is not considered an unregistered or illegal exchange,
     * by the laws of any legal jurisdiction in which you hold or use tokens, or any legal jurisdiction
     * of the recipient.
     * 
     * @notice In some jurisdictions, such as the United States, any use, transfer, or sale of a token is a taxable
     * event. It is your responsibility to record the purchase price and sale price in ETH or your local currency
     * for each use, transfer, or sale of tokens you own, and to pay the taxes due.
     *
     * @param recipient The address which you want to transfer tokens to.
     * @param amount The number of tokens to be transferred.
     * @return success `true` unless the transaction is reverted.
     */
    function transferAndCall(address recipient, uint256 amount) external returns (bool success);

    /**
     * @notice Transfer tokens to a recipient, and then call the ERC1363 recipient notification interface
     * on the recipient.
     *
     * @dev [ERC1363] Transfer tokens from the caller to `recipient`, and then call the ERC1363 receiver
     * interface's `onTransferReceived` on the recipient. The transaction will fail if the recipient does
     * not implement this interface (including if the recipient address is an EOA address).
     *
     * @notice By calling this function, you confirm that this token is not considered an unregistered or
     * illegal security, and that this smart contract is not considered an unregistered or illegal exchange,
     * by the laws of any legal jurisdiction in which you hold or use tokens, or any legal jurisdiction
     * of the recipient.
     * 
     * @notice In some jurisdictions, such as the United States, any use, transfer, or sale of a token is a taxable
     * event. It is your responsibility to record the purchase price and sale price in ETH or your local currency
     * for each use, transfer, or sale of tokens you own, and to pay the taxes due.
     *
     * @param recipient The address which you want to transfer tokens to.
     * @param amount The number of tokens to be transferred.
     * @param data Additional data with no specified format, sent in call to `recipient`.
     * @return success `true` unless the transaction is reverted.
     */
    function transferAndCall(address recipient, uint256 amount, bytes memory data) external returns (bool success);

    /**
     * @notice Transfer tokens to a recipient on behalf of another account, and then call the ERC1363
     * recipient notification interface on the recipient.
     *
     * @dev [ERC1363] Transfer tokens from `holder` to `recipient`, and then call the ERC1363 spender
     * interface's `onApprovalReceived` on the recipient. The transaction will fail if the recipient does
     * not implement this interface (including if the recipient address is an EOA address).
     *
     * @notice By calling this function, you confirm that this token is not considered an unregistered or
     * illegal security, and that this smart contract is not considered an unregistered or illegal exchange,
     * by the laws of any legal jurisdiction in which you hold or use tokens, or any legal jurisdiction
     * of the holder or recipient.
     * 
     * @notice In some jurisdictions, such as the United States, any use, transfer, or sale of a token is a taxable
     * event. It is your responsibility to record the purchase price and sale price in ETH or your local currency
     * for each use, transfer, or sale of tokens you own, and to pay the taxes due.
     *
     * @param holder The address which you want to send tokens on behalf of.
     * @param recipient The address which you want to transfer tokens to.
     * @param amount The number of tokens to be transferred.
     * @return success `true` unless the transaction is reverted.
     */
    function transferFromAndCall(address holder, address recipient, uint256 amount) external returns (bool success);

    /**
     * @notice Transfer tokens to a recipient on behalf of another account, and then call the ERC1363
     * recipient notification interface on the recipient.
     *
     * @dev [ERC1363] Transfer tokens from `holder` to `recipient`, and then call the ERC1363 spender
     * interface's `onApprovalReceived` on the recipient. The transaction will fail if the recipient does
     * not implement this interface (including if the recipient address is an EOA address).
     *
     * @notice By calling this function, you confirm that this token is not considered an unregistered or
     * illegal security, and that this smart contract is not considered an unregistered or illegal exchange,
     * by the laws of any legal jurisdiction in which you hold or use tokens, or any legal jurisdiction
     * of the holder or recipient.
     * 
     * @notice In some jurisdictions, such as the United States, any use, transfer, or sale of a token is a taxable
     * event. It is your responsibility to record the purchase price and sale price in ETH or your local currency
     * for each use, transfer, or sale of tokens you own, and to pay the taxes due.
     *
     * @param holder The address which you want to send tokens from.
     * @param recipient The address which you want to transfer tokens to.
     * @param amount The number of tokens to be transferred.
     * @param data Additional data with no specified format, sent in call to `recipient`.
     * @return success `true` unless the transaction is reverted.
     */
    function transferFromAndCall(address holder, address recipient, uint256 amount, bytes memory data)
        external returns (bool success);

    /**
     * @notice Approve another account to spend your tokens, and then call the ERC1363 spender notification
     * interface on the spender.
     *
     * @dev [ERC1363] Approve `spender` to spend the specified number of tokens on behalf of
     * caller (the token holder), and then call `onApprovalReceived` on spender.
     *
     * @notice By calling this function, you confirm that this token is not considered an unregistered or
     * illegal security, and that this smart contract is not considered an unregistered or illegal exchange,
     * by the laws of any legal jurisdiction in which you hold or use tokens, or any legal jurisdiction
     * of the spender or recipient.
     * 
     * @notice In some jurisdictions, such as the United States, any use, transfer, or sale of a token is a taxable
     * event. It is your responsibility to record the purchase price and sale price in ETH or your local currency
     * for each use, transfer, or sale of tokens you own, and to pay the taxes due.
     *
     * @param spender The address which will spend the funds.
     * @param amount The number of tokens to allow the spender to spend.
     * @return success `true` unless the transaction is reverted.
     */
    function approveAndCall(address spender, uint256 amount) external returns (bool success);

    /**
     * @notice Approve another account to spend your tokens, and then call the ERC1363 spender notification
     * interface on the spender.
     *
     * @dev [ERC1363] Approve `spender` to spend the specified number of tokens on behalf of
     * caller (the token holder), and then call `onApprovalReceived` on spender.
     *
     * @notice By calling this function, you confirm that this token is not considered an unregistered or
     * illegal security, and that this smart contract is not considered an unregistered or illegal exchange,
     * by the laws of any legal jurisdiction in which you hold or use tokens, or any legal jurisdiction
     * of the spender or recipient.
     * 
     * @notice In some jurisdictions, such as the United States, any use, transfer, or sale of a token is a taxable
     * event. It is your responsibility to record the purchase price and sale price in ETH or your local currency
     * for each use, transfer, or sale of tokens you own, and to pay the taxes due.
     *
     * @param spender The address which will spend the funds.
     * @param amount The number of tokens to be allow the spender to spend.
     * @param data Additional data with no specified format, sent in call to `spender`.
     * @return success `true` unless the transaction is reverted.
     */
    function approveAndCall(address spender, uint256 amount, bytes memory data) external returns (bool success);
}


// File contracts/main/OmniToken/interfaces/IERC1363Spender.sol


/**
 * @title ERC1363Spender interface
 * @dev Interface for any contract that wants to support `approveAndCall`
 *  from ERC1363 token contracts.
 */

pragma solidity 0.8.15;

/*
 * @dev The ERC-165 identifier for this interface is 0x7b04a2d0.
 * 0x7b04a2d0 === bytes4(keccak256("onApprovalReceived(address,uint256,bytes)"))
 */
interface IERC1363Spender is IERC165 {
    /**
     * @notice Handle the approval of ERC1363 tokens
     * @dev Any ERC1363 smart contract calls this function on the recipient
     * after an `approve`. This function MAY throw to revert and reject the
     * approval. Return of other than the magic value MUST result in the
     * transaction being reverted.
     * Note: the token contract address is always the message sender.
     * @param holder address The address which called `approveAndCall` function
     * @param amount uint256 The number of tokens to be spent
     * @param data bytes Additional data with no specified format
     * @return `bytes4(keccak256("onApprovalReceived(address,uint256,bytes)"))` (0x7b04a2d0) unless reverting
     */
    function onApprovalReceived(address holder, uint256 amount, bytes memory data) external returns (bytes4);
}


// File contracts/main/OmniToken/interfaces/IERC1363Receiver.sol


/**
 * @title ERC1363Receiver interface
 * @dev Interface for any contract that wants to support `transferAndCall` or `transferFromAndCall`
 *  from ERC1363 token contracts.
 */

pragma solidity 0.8.15;

interface IERC1363Receiver is IERC165 {
    /*
     * Note: the ERC-165 identifier for this interface is 0x88a7ca5c.
     * 0x88a7ca5c === bytes4(keccak256("onTransferReceived(address,address,uint256,bytes)"))
     */

    /**
     * @notice Handle the receipt of ERC1363 tokens
     * @dev Any ERC1363 smart contract calls this function on the recipient after a `transfer` or a `transferFrom`.
     *        This function MAY throw to revert and reject the transfer. Return of other than the magic value MUST
     *        result in the transaction being reverted. Note: the token contract address is always the message sender.
     * @param operator address The address which called `transferAndCall` or `transferFromAndCall` function.
     * @param sender address The address which are token transferred from.
     * @param value uint256 The amount of tokens transferred.
     * @param data bytes Additional data with no specified format.
     * @return `bytes4(keccak256("onTransferReceived(address,address,uint256,bytes)"))` (0x88a7ca5c) unless reverting.
     */
    function onTransferReceived(address operator, address sender, uint256 value, bytes memory data)
            external returns (bytes4);
}


// File contracts/main/OmniToken/interfaces/IERC4524.sol

// From: https://eips.ethereum.org/EIPS/eip-4524

pragma solidity 0.8.15;


/**
 * @dev A safer ERC20 trasfer protocol, similar to ERC777's recipient notification protocol.
 *
 * The EIP-165 interfaceId for this interface is 0x534f5876.
 */
interface IERC4524 is IERC20, IERC165 {
    /**
     * @notice Transfer funds and then notify the recipient via the ERC4524 receiver interface.
     *
     * @dev [ERC4524] Move `amount` tokens from the caller's account to `recipient`. Only succeeds if `recipient`
     * correctly implements the ERC4524 receiver interface, or if the receiver is an EOA (non-contract wallet).
     *
     * @notice By calling this function, you confirm that this token is not considered an unregistered or
     * illegal security, and that this smart contract is not considered an unregistered or illegal exchange,
     * by the laws of any legal jurisdiction in which you hold or use tokens, or any legal jurisdiction
     * of the recipient.
     * 
     * @notice In some jurisdictions, such as the United States, any use, transfer, or sale of a token is a taxable
     * event. It is your responsibility to record the purchase price and sale price in ETH or your local currency
     * for each use, transfer, or sale of tokens you own, and to pay the taxes due.
     *
     * @param recipient The token recipient.
     * @param amount The number of tokens to transfer from the caller to `recipient`.
     * @return success `true` if the operation succeeded (otherwise reverts).
     */
    function safeTransfer(address recipient, uint256 amount) external returns(bool success);

    /**
     * @notice Transfer funds and then notify the recipient via the ERC4524 receiver interface.
     *
     * @dev [ERC4524] Move `amount` tokens from the caller's account to `recipient`. Only succeeds if `recipient`
     * correctly implements the ERC4524 receiver interface, or if the receiver is an EOA (non-contract wallet).
     *
     * @notice By calling this function, you confirm that this token is not considered an unregistered or
     * illegal security, and that this smart contract is not considered an unregistered or illegal exchange,
     * by the laws of any legal jurisdiction in which you hold or use tokens, or any legal jurisdiction
     * of the recipient.
     * 
     * @notice In some jurisdictions, such as the United States, any use, transfer, or sale of a token is a taxable
     * event. It is your responsibility to record the purchase price and sale price in ETH or your local currency
     * for each use, transfer, or sale of tokens you own, and to pay the taxes due.
     *
     * @param recipient The token recipient.
     * @param amount The number of tokens to transfer from the caller to `recipient`.
     * @param data Extra data to add to the emmitted transfer event.
     * @return success `true` if the operation succeeded (otherwise reverts).
     */
    function safeTransfer(address recipient, uint256 amount, bytes memory data) external returns(bool success);

    /**
     * @notice Transfer funds and then notify the recipient via the ERC4524 receiver interface.
     *
     * @dev [ERC4524] Move `amount` tokens from `holder` to `recipient`. (The caller must have
     * previously been approved by `holder` to send at least `amount` tokens on behalf of `holder`, by
     * `holder` calling `approve`.) `amount` is then deducted from the caller’s allowance.
     * Only succeeds if `recipient` correctly implements the ERC4524 receiver interface,
     * or if `recipient` is an EOA (non-contract wallet).
     *
     * @notice By calling this function, you confirm that this token is not considered an unregistered or
     * illegal security, and that this smart contract is not considered an unregistered or illegal exchange,
     * by the laws of any legal jurisdiction in which you hold or use tokens, or any legal jurisdiction
     * of the holder or recipient.
     * 
     * @notice In some jurisdictions, such as the United States, any use, transfer, or sale of a token is a taxable
     * event. It is your responsibility to record the purchase price and sale price in ETH or your local currency
     * for each use, transfer, or sale of tokens you own, and to pay the taxes due.
     * 
     * @param holder The token holder.
     * @param recipient The token recipient.
     * @param amount The number of tokens to transfer from the caller to `recipient`.
     * @return success `true` if the operation succeeded (otherwise reverts).
     */
    function safeTransferFrom(address holder, address recipient, uint256 amount) external returns(bool success);

    /**
     * @notice Transfer funds and then notify the recipient via the ERC4524 receiver interface.
     *
     * @dev [ERC4524] Move `amount` tokens from `holder` to `recipient`. (The caller must have
     * previously been approved by `holder` to send at least `amount` tokens on behalf of `holder`, by
     * `holder` calling `approve`.) `amount` is then deducted from the caller’s allowance.
     * Only succeeds if `recipient` correctly implements the ERC4524 receiver interface,
     * or if `recipient` is an EOA (non-contract wallet).
     *
     * @notice By calling this function, you confirm that this token is not considered an unregistered or
     * illegal security, and that this smart contract is not considered an unregistered or illegal exchange,
     * by the laws of any legal jurisdiction in which you hold or use tokens, or any legal jurisdiction
     * of the holder or recipient.
     * 
     * @notice In some jurisdictions, such as the United States, any use, transfer, or sale of a token is a taxable
     * event. It is your responsibility to record the purchase price and sale price in ETH or your local currency
     * for each use, transfer, or sale of tokens you own, and to pay the taxes due.
     * 
     * @param holder The token holder.
     * @param recipient The token recipient.
     * @param amount The number of tokens to transfer from the caller to `recipient`.
     * @param data Extra data to add to the emmitted transfer event.
     * @return success `true` if the operation succeeded (otherwise reverts).
     */
    function safeTransferFrom(address holder, address recipient, uint256 amount, bytes memory data)
            external returns(bool success);
}


// File contracts/main/OmniToken/interfaces/IERC4524Recipient.sol


pragma solidity 0.8.15;

/**
 * @title IERC4523Recipient
 */
interface IERC4524Recipient is IERC165 {
    function onERC20Received(address operator, address sender, uint256 amount, bytes memory data)
            external returns(bytes4);
}


// File contracts/main/OmniToken/interfaces/IEIP2612.sol


pragma solidity 0.8.15;

/**
 * @dev Interface of the EIP2612 permitting standard.
 */
interface IEIP2612 {
    /**
     * @notice Convert a signed certificate into a permit or allowance for a spender account to spend tokens
     * on behalf of a holder account.
     *
     * @dev [EIP2612] Implements the EIP2612 permit standard. Sets the spendable allowance for `spender` to
     * spend `holder`'s tokens, which can then be transferred using the ERC20 `transferFrom` function.
     *
     * https://eips.ethereum.org/EIPS/eip-2612
     * https://github.com/Uniswap/v2-core/blob/master/contracts/UniswapV2ERC20.sol
     *
     * @notice By calling this function, you confirm that this token is not considered an unregistered or
     * illegal security, and that this smart contract is not considered an unregistered or illegal exchange,
     * by the laws of any legal jurisdiction in which you hold or use tokens, or any legal jurisdiction
     * of the holder or spender.
     * 
     * @notice In some jurisdictions, such as the United States, any use, transfer, or sale of a token is a taxable
     * event. It is your responsibility to record the purchase price and sale price in ETH or your local currency
     * for each use, transfer, or sale of tokens you own, and to pay the taxes due.
     *
     * @param holder The token holder.
     * @param spender The spender who will be authorized to spend tokens on behalf of `holder`.
     * @param amount The number of tokens `spender` will be authorized to spend on behalf of `holder`.
     * @param deadline The block timestamp after which the certificate expires.
     *          Note that if the permit is granted, then the allowance that is approved has its own deadline,
     *          separate from the certificate deadline. By default, allowances expire 1 hour after they are
     *          granted, but this may be modified by the contract owner -- call `defaultAllowanceExpirationSec()`
     *          to get the current value.
     * @param v The ECDSA `v` value.
     * @param r The ECDSA `r` value.
     * @param s The ECDSA `s` value.
     */
    function permit(address holder, address spender, uint amount, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    /** @notice EIP2612 permit nonces. */
    function nonces(address holder) external view returns (uint);

    /** @notice EIP712 domain separator for EIP2612 permits. */
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}


// File contracts/main/OmniToken/OmniTokenInternal.sol


// The OmniToken Ethereum token contract library, supporting multiple token standards.
// By Hiroshi Yamamoto.
// 虎穴に入らずんば虎子を得ず。
//
// Officially hosted at: https://github.com/dublr/dublr

pragma solidity 0.8.15;

















/**
 * @title OmniTokenInternal
 * @dev Utility functions for the OmniToken Ethereum token contract library.
 * @author Hiroshi Yamamoto
 */
abstract contract OmniTokenInternal is 
                      IERC20, IERC20Optional, IERC20Burn,
                      IERC20SafeApproval, IERC20IncreaseDecreaseAllowance, IERC20TimeLimitedTokenAllowances,
                      IERC777, IERC1363, IERC4524, IEIP2612 {

    /** @dev Creator/owner of the contract. */
    address immutable internal _owner;

    /** @dev EIP712/EIP2612 constant domain separator fields. */
    bytes32[] private domainSepFields;

    /**
     * @dev Constructor.
     *
     * @param tokenName the name of the token.
     * @param tokenSymbol the ticker symbol for the token.
     * @param tokenVersion the version number string for the token.
     */
    constructor(string memory tokenName, string memory tokenSymbol, string memory tokenVersion) {
        // Remember creator of contract as owner
        _owner = msg.sender;

        name = tokenName;
        symbol = tokenSymbol;
        version = tokenVersion;

        // Cache constant domain separator fields so that they don't have to be recomputed for each permit approval
        domainSepFields.push(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"));
        domainSepFields.push(keccak256(bytes(tokenName)));
        domainSepFields.push(keccak256(bytes(tokenVersion)));

        // There must be an ERC1820 registry deployed on the network for ERC777
        require(isContract(ERC1820_REGISTRY_ADDRESS), "No ERC1820 registry");
        
        // Register thet ERC165 interface with itself
        registerInterfaceViaERC165(type(IERC165).interfaceId, true);

        // Enable and register interfaces
        _owner_enableERC20(true);
        _owner_enableERC777(true);
        _owner_enableERC1363(true);
        _owner_enableERC4524(true);
        _owner_enableEIP2612(true);
        
    }

    // -----------------------------------------------------------------------------------------------------------------
    // Functions common to multiple interfaces

    /** @notice The number of tokens owned by a given address. */
    mapping(address => uint256) public override(IERC20, IERC777) balanceOf;

    /** @notice The total supply of tokens. */
    uint256 public override(IERC20, IERC777) totalSupply;

    /** @notice The name of the token. */
    string public override(IERC20Optional, IERC777) name;

    /** @notice The token symbol. */
    string public override(IERC20Optional, IERC777) symbol;

    /** @notice The token version. (Optional but supported in some token implementations.) */
    string public version;

    /**
     * @notice The number of decimal places used to display token balances.
     * (Hardcoded to the ETH-standard value of 18, as required by ERC777.)
     */
    uint8 public constant override(IERC20Optional) decimals = 18;

    /** @notice The ERC777 granularity. (Hardcoded to 1, for maximum compatibility with ERC20.) */
    uint256 public constant override(IERC777) granularity = 1;

    // -----------------------------------------------------------------------------------------------------------------

    /**
     * @notice EIP712 domain separator for EIP2612 permits.
     *
     * @dev [EIP2612] Part of the EIP2612 permit API.
     *
     * @return The domain separator for EIP2612 permits.
     */
    function DOMAIN_SEPARATOR() public view override(IEIP2612) returns (bytes32) {
        return keccak256(
            abi.encode(
                domainSepFields[0],
                domainSepFields[1],
                domainSepFields[2],
                // Domain separator must be dynamically generated to prevent sidechain replay attacks:
                // https://github.com/dublr/dublr/issues/10
                block.chainid,
                address(this)));
    }

    // -----------------------------------------------------------------------------------------------------------------
    // Function modifiers

    /** @dev The number of functions on the stack that modify contract state. */
    uint256 private _stateUpdaterDepth;

    /**
     * @dev Reentrancy protection for functions that modify account state. Disallows a state-modifying
     * function (stateUpdater) from being called deeper in the callstack than a function that calls an
     * external contract (modified by `extCaller`), or vice versa.
     */
    modifier stateUpdater() {
        // Prevent reentrance
        require(_extCallerDepth == 0, "Reentrance denied");
        // slither-disable-next-line reentrancy-eth
        unchecked { ++_stateUpdaterDepth; }
        _;
        // slither-disable-next-line reentrancy-eth
        unchecked { --_stateUpdaterDepth; }
    }

    /** @dev The number of functions on the stack that call external contracts. */
    uint256 private _extCallerDepth;

    /**
     * @dev Reentrancy protection for functions that modify account state. Disallows a function that
     * calls an external contract (modified by `extCaller`) from being called deeper in the callstack
     * than a state-modifying function (stateUpdater), or vice versa.
     */
    modifier extCaller() {
        require(_stateUpdaterDepth == 0, "Reentrance denied");
        // slither-disable-next-line reentrancy-eth
        unchecked { ++_extCallerDepth; }
        _;
        // slither-disable-next-line reentrancy-eth
        unchecked { --_extCallerDepth; }
    }

    // --------------

    /**
     * @notice Emitted when the owner/deployer of the contract calls an `_owner_...` function.
     *
     * @param msgData The ABI-encoded data for the function call, from `msg.data`.
     */
    event OwnerCall(bytes msgData);

    /** @dev Limit access to a function to the owner of the contract. */
    modifier ownerOnly() {
        require(msg.sender == _owner, "Not owner");
        _;
        emit OwnerCall(msg.data);
    }

    // -----------------------------------------------------------------------------------------------------------------
    // API enablement (needed in case a security issue is discovered with one of the APIs after the contract is created)

    /** @dev true if the ERC20 API is enabled. */
    bool internal _ERC20Enabled;

    /**
     * @notice Only callable by the owner/deployer of the contract.
     * @dev Enable or disable ERC20 support in the API.
     * If disabled, also disables other token APIs that are a superset of ERC20, since these depend
     * upon the ERC20 API. However disabling ERC20 does not disable the ERC777 API.
     */
    function _owner_enableERC20(bool enable) public ownerOnly {
        _ERC20Enabled = enable;

        // ERC20
        registerInterfaceViaERC165(type(IERC20).interfaceId, enable);

        // ERC20 increase/decrease allowance extension
        registerInterfaceViaERC165(type(IERC20IncreaseDecreaseAllowance).interfaceId, enable);
                
        // ERC20 safe approval extension
        registerInterfaceViaERC165(type(IERC20SafeApproval).interfaceId, enable);

        // Don't register time-limited token allowance extension, because the OmniToken version uses seconds rather
        // than blocks for expiration, but the method type signature is the same

        registerInterfaceViaERC1820("ERC20Token", enable);
    }

    /** @dev Require ERC20 to be enabled. */
    modifier erc20() {
        require(_ERC20Enabled, "Disabled");
        _;
    }

    // --------------

    /** @dev true if the ERC777 API is enabled. */
    bool internal _ERC777Enabled;

    /**
     * @notice Only callable by the owner/deployer of the contract.
     * @dev Enable or disable ERC777 support in the API.
     */
    function _owner_enableERC777(bool enable) public ownerOnly {
        _ERC777Enabled = enable;
        
        registerInterfaceViaERC165(type(IERC777).interfaceId, enable);
        
        registerInterfaceViaERC1820("ERC777Token", enable);
    }

    /** The number of function calls in the stack for functions marked with the erc777 modifier. */
    uint256 internal _erc777CallDepth;

    /** @dev Require ERC777 to be enabled, and mark the ERC777 API as active. */
    modifier erc777() {
        require(_ERC777Enabled, "Disabled");
        unchecked { ++_erc777CallDepth; }
        _;
        unchecked { --_erc777CallDepth; }
    }

    /**
     * @dev Require ERC777 to be enabled, without marking the ERC777 API as active (needed for `view` functions,
     * of which there is one in the ERC777 API -- can't just remove `view` modifier since that function may be
     * called statically by a caller).
     */
    modifier erc777View() {
        require(_ERC777Enabled, "Disabled");
        _;
    }

    // --------------

    /** @dev true if the ERC1363 API is enabled. */
    bool internal _ERC1363Enabled;

    /**
     * @notice Only callable by the owner/deployer of the contract.
     * @dev Enable or disable ERC1363 support in the API.
     */
    function _owner_enableERC1363(bool enable) public ownerOnly {
        _ERC1363Enabled = enable;

        registerInterfaceViaERC165(type(IERC1363).interfaceId, enable);

        registerInterfaceViaERC1820("ERC1363Token", enable);
    }

    /** The number of function calls in the stack for functions marked with the erc1363 modifier. */
    uint256 internal _erc1363CallDepth;

    /** @dev Require ERC1363 to be enabled, and mark the ERC1363 API as active. */
    modifier erc1363() {
        require(_ERC1363Enabled, "Disabled");
        unchecked { ++_erc1363CallDepth; }
        _;
        unchecked { --_erc1363CallDepth; }
    }

    // --------------

    /** @dev true if the ERC4524 API is enabled. */
    bool internal _ERC4524Enabled;

    /**
     * @notice Only callable by the owner/deployer of the contract.
     * @dev Enable or disable ERC4524 support in the API (may only be called by the contract creator).
     */
    function _owner_enableERC4524(bool enable) public ownerOnly {
        _ERC4524Enabled = enable;
        
        registerInterfaceViaERC165(type(IERC4524).interfaceId, enable);
        
        registerInterfaceViaERC1820("ERC4524Token", enable);
    }

    /** The number of function calls in the stack for functions marked with the erc4524 modifier. */
    uint256 internal _erc4524CallDepth;

    /** @dev Require ERC4524 to be enabled, and mark the ERC4524 API as active. */
    modifier erc4524() {
        require(_ERC4524Enabled, "Disabled");
        unchecked { ++_erc4524CallDepth; }
        _;
        unchecked { --_erc4524CallDepth; }
    }

    // --------------

    /** @dev true if the EIP2612 permit API is enabled. */
    bool internal _EIP2612Enabled;

    /**
     * @notice Only callable by the owner/deployer of the contract.
     * @dev Enable or disable EIP2612 permit support in the API.
     */
    function _owner_enableEIP2612(bool enable) public ownerOnly {
        _EIP2612Enabled = enable;

        registerInterfaceViaERC165(type(IEIP2612).interfaceId, enable);

        registerInterfaceViaERC1820("ERC2612Permit", enable);
    }

    /** @dev Require EIP2612 permit support to be enabled. */
    modifier eip2612() {
        require(_EIP2612Enabled, "Disabled");
        _;
    }

    // --------------

    /**
     * @dev true if unlimited allowance is enabled.
     */
    bool internal _unlimitedAllowancesEnabled = true;

    /**
     * @notice Only callable by the owner/deployer of the contract.
     *
     * @dev Enable/disable unlimited allowances.
     *
     * Note that having unlimited allowances enabled can be dangerous, $120M was stolen in the BADGER frontend
     * injection attack due to unlimited allowances.
     *
     * Disabling this causes an allowance amount of `type(uint256).max` to be rejected, which is not strictly
     * ERC20 compatible.
     * 
     * See: https://kalis.me/unlimited-erc20-allowances/
     *      https://rekt.news/badger-rekt/
     *
     * @param enable Whether to enable unlimited allowances.
     */
    function _owner_enableUnlimitedAllowances(bool enable) external ownerOnly {
        _unlimitedAllowancesEnabled = enable;
    }

    // --------------

    /** @dev true if ERC20 transfer to smart contracts is enabled. */
    bool internal _transferToContractsEnabled = true;

    /**
     * @notice Only callable by the owner/deployer of the contract.
     *
     * @dev Enable/disable ERC20 transfer to smart contracts. Note that enabling this can be dangerous:
     * millions have been lost in the Ethereum ecosystem due to users accidentally transferring tokens
     * to a smart contract rather than an EOA wallet, since smart contracts generally aren't
     * set up to function as wallets, and contract code generally can't be changed to recover
     * lost tokens.
     *
     * Disabling this is not ERC20 compatible, but it's much safer.
     * 
     * See: https://101blockchains.com/erc20-vs-erc223-vs-erc777/
     *
     * @param enable Whether to enable transfer of tokens to non-EOA addresses (contracts).
     */
    function _owner_enableTransferToContracts(bool enable) external ownerOnly {
        _transferToContractsEnabled = enable;
    }

    // --------------

    /**
     * @dev true if ERC20 allows setting allowances from a non-zero value to another non-zero value.
     */
    bool internal _changingAllowanceWithoutZeroingEnabled = true;

    /**
     * @notice Only callable by the owner/deployer of the contract.
     *
     * @dev Enable/disable the ability of the ERC20 `approve` function to approve a non-zero allowance when the
     * allowance is already non-zero.
     *
     * Disabling this prevents the well-known allowance race condition vulnerability in ERC20, which is not
     * ERC20-compatible behavior, but it's much safer.
     *
     * See: https://github.com/guylando/KnowledgeLists/blob/master/EthereumSmartContracts.md
     *
     * @param enable Whether to enable changing allowances without first setting them to zero.
     */
    function _owner_enableChangingAllowanceWithoutZeroing(bool enable) external ownerOnly {
        _changingAllowanceWithoutZeroingEnabled = enable;
    }

    // -----------------------------------------------------------------------------------------------------------------
    // Contract utility functions

    /**
     * @dev Test whether `account` is a contract.
     *
     * May return false negatives: during the execution of a contract's constructor, its address will be reported as not
     * containing a contract. Therefore, it is not safe to assume that an address for which this function returns `false`
     * is an externally-owned account (EOA) and not a contract.
     *
     * @param account The account.
     * @return Whether `account` is a contract (`true`) or is an externally-owned account (EOA) (`false`). Note that
     *         a return value of `true` is reliable, but a return value of `false` is not reliable.
     */
    function isContract(address account) internal view returns (bool) {
        // This relies on extcodesize, which returns 0 for contracts in construction, since the code is
        // only stored at the end of the constructor execution.
        return account != address(0) && account.code.length > 0;
    }

    // -----------------------------------------------------------------------------------------------------------------
    // ERC165 support for testing whether a given interface is supported

    /** @dev Supported interfaces (for ERC165 support). */
    mapping(bytes4 => bool) internal _supportedInterfaces;
    
    /**
     * @notice Determine whether or not this contract supports a given interface.
     *
     * @dev [ERC165] Implements the ERC165 API.
     * 
     * @param interfaceId The result of xor-ing together the function selectors of all functions in the interface
     * of interest.
     * @return implementsInterface `true` if this contract implements the requested interface.
     */
    function supportsInterface(bytes4 interfaceId) external view override(IERC165) returns (bool implementsInterface) {
        return _supportedInterfaces[interfaceId];
    }

    /** @dev Register a supported interface via ERC165. */
    function registerInterfaceViaERC165(bytes4 interfaceId, bool supported) internal {
        if (interfaceId != 0xffffffff) {  // ERC165 does not allow registering this interfaceId
            _supportedInterfaces[interfaceId] = supported;
        }
    }

    /**
     * @dev Check that a contract supports a given interface (declared via ERC165), reverting if not.
     *
     * @param contractAddr The contract address.
     * @param interfaceId The interface id.
     * @param errMsgOnFail The error message to revert with, if the contract does not support the interface.
     */
    function requireContractSupportsInterface(address contractAddr, bytes4 interfaceId, string memory errMsgOnFail)
            // Use extCaller modifier for reentrancy protection
            internal extCaller {
        require(isContract(contractAddr), errMsgOnFail);
        bool supported;
        try IERC165(contractAddr).supportsInterface(interfaceId) returns (bool result) {
            supported = result;
        } catch {
            supported = false;
        }
        require(supported, errMsgOnFail);
    }

    // -----------------------------------------------------------------------------------------------------------------
    // ERC1820 support for registering and finding the implementer of an interface

    /** @dev The ERC1820 registry address. */
    address internal constant ERC1820_REGISTRY_ADDRESS = address(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);

    /**
     * @dev Register or unregister an interface in the ERC1820 registry, with this address as the account
     * and implementer.
     */
    function registerInterfaceViaERC1820(string memory interfaceName, bool enable) internal {
        // extCaller modifier not required, since the ERC1820 registry is known and trusted
        IERC1820Registry(ERC1820_REGISTRY_ADDRESS)
                .setInterfaceImplementer(
                        // address(0) is equivalent to address(this) for first arg of `setInterfaceImplementer`
                        /* account = */ address(0),
                        /* interfaceHash = */ keccak256(bytes(interfaceName)),
                        /* implementer = */ enable ? address(this) : address(0));
    }

    /**
     * @dev Look up an interface in the ERC1820 registry.
     *
     * @param addrToQuery Address being queried for the implementer of an interface.
     * @param interfaceName the name of the interface as a string.
     * @return interfaceAddr The address of the contract which implements the interface `hash` for `addr`, 
     *         or `address(0)` if `addr` did not register an implementer for this interface (or if the
     *         registry could not be called).
     */
    function lookUpInterfaceViaERC1820(address addrToQuery, string memory interfaceName)
                internal view returns(address interfaceAddr) {
        // extCaller modifier not required, since the ERC1820 registry is known and trusted
        return IERC1820Registry(ERC1820_REGISTRY_ADDRESS)
                .getInterfaceImplementer(addrToQuery, keccak256(bytes(interfaceName)));
    }

    // -----------------------------------------------------------------------------------------------------------------
    // Functions for interacting with other contracts (modified with `extCaller` for reentrancy protection)

    /**
     * @dev Call the ERC777 sender's `tokensToSend` function. Should be called before any account state changes,
     * according to the ERC777 spec, but we call this after account state is finalized (in violation of the spec),
     * because calling an external contract before finalizing account state violates Checks-Effects-Interactions.
     *
     * @param sender The address holding the tokens being sent
     * @param recipient The address of the recipient
     * @param amount The amount of tokens to be sent
     * @param data Data generated by the user to be passed to the recipient
     * @param operatorData Data generated by the operator to be passed to the recipient
     */
    function call_ERC777TokensSender_tokensToSend(
            address operator, address sender, address recipient, uint256 amount,
            bytes memory data, bytes memory operatorData)
            // Use extCaller modifier for reentrancy protection
            internal extCaller {
        address senderImplementation = lookUpInterfaceViaERC1820(sender, "ERC777TokensSender");
        if (isContract(senderImplementation)) {
            try IERC777Sender(senderImplementation)
                    .tokensToSend(operator, sender, recipient, amount, data, operatorData) {
                // Success
            } catch {
                // Don't revert if sender couldn't be called, just return false (currently ignored by caller)
                // (it is optional for sender to implement ERC777 sender interface)
            }
        }
    }

    /**
     * @dev Call the ERC777 recipient's `tokensReceived` function. Must be called after contract state is finalized.
     *
     * @param operator The address performing the send or mint.
     * @param sender The address holding the tokens being sent.
     * @param recipient The address of the recipient.
     * @param amount The number of tokens to be sent.
     * @param data Data generated by the user to be passed to the recipient.
     * @param operatorData Data generated by the operator to be passed to the recipient.
     */
    function call_ERC777TokensRecipient_tokensReceived(
            address operator, address sender, address recipient, uint256 amount,
            bytes memory data, bytes memory operatorData)
            // Use extCaller modifier for reentrancy protection
            internal extCaller {
        address recipientImpl = lookUpInterfaceViaERC1820(recipient, "ERC777TokensRecipient");
        if (recipientImpl != address(0)) {
            IERC777Recipient(recipientImpl)
                    .tokensReceived(operator, sender, recipient, amount, data, operatorData);
        } else {
            // The ERC777 spec specifies that sending to a non-ERC777 contract must revert, while sending to a
            // non-contract address (an EOA) must silently continue.
            // https://eips.ethereum.org/EIPS/eip-777#backward-compatibility
            // Note that `isContract` will return a false negative if the contract's constructor has not completed,
            // and in this case the transaction will silently succeed when sending to a contract that does not
            // implement the ERC777 receiver function. However, the reference implementation of ERC777 has this
            // same problem, and there's no solution for this currently for Ethereum contracts.
            require(!isContract(recipient), "Not ERC777 recipient");
        }
    }

    /**
     * @dev Call the ERC1363 spender's `onApprovalReceived` function. Must be called after contract state is finalized.
     *
     * @param holder The address holding the tokens being spent.
     * @param spender The address spending the tokens.
     * @param amount The number of tokens to be spent.
     * @param data Data generated by the user to be passed to the recipient.
     */
    function call_ERC1363Spender_onApprovalReceived(
            address holder, address spender, uint256 amount, bytes memory data)
            // Use extCaller modifier for reentrancy protection
            internal extCaller {
        // `spender` must declare it implements ERC1363 spender interface via ERC165
        string memory errMsg = "Not ERC1363 spender";
        requireContractSupportsInterface(spender, type(IERC1363Spender).interfaceId, errMsg);
        require(IERC1363Spender(spender).onApprovalReceived(holder, amount, data)
                == type(IERC1363Spender).interfaceId, errMsg);
    }

    /**
     * @dev Call the ERC1363 receiver's `onTransferReceived` function. Must be called after contract state is finalized.
     *
     * @param operator address The address which called `transferAndCall` or `transferFromAndCall` function.
     * @param sender address The address which are token transferred from.
     * @param recipient address The address which are token transferred to.
     * @param amount uint256 The amount of tokens transferred.
     * @param data bytes Additional data with no specified format.
     */
    function call_ERC1363Receiver_onTransferReceived(
            address operator, address sender, address recipient, uint256 amount, bytes memory data)
            // Use extCaller modifier for reentrancy protection
            internal extCaller {
        // `recipient` must declare it implements ERC1363 recipient interface via ERC165
        string memory errMsg = "Not ERC1363 recipient";
        requireContractSupportsInterface(recipient, type(IERC1363Receiver).interfaceId, errMsg);
        require(IERC1363Receiver(recipient).onTransferReceived(operator, sender, amount, data)
                == type(IERC1363Receiver).interfaceId, errMsg);
    }

    /**
     * @dev Call the ERC4524 recipient's `onERC20Received` function. Must be called after contract state is finalized.
     *
     * @param operator The address performing the send or mint.
     * @param sender The address holding the tokens being sent.
     * @param recipient The address of the recipient.
     * @param amount The number of tokens to be sent.
     * @param data Data generated by the user to be passed to the recipient.
     */
    function call_ERC4524TokensRecipient_onERC20Received(
            address operator, address sender, address recipient, uint256 amount, bytes memory data)
            // Use extCaller modifier for reentrancy protection
            internal extCaller {
        // Sending to an EOA always succeeds, by falling through to the return statement
        if (isContract(recipient)) {
            // `recipient` must declare it implements ERC4524 recipient interface via ERC165
            string memory errMsg = "Not ERC4524 recipient";
            requireContractSupportsInterface(recipient, type(IERC4524Recipient).interfaceId, errMsg);
            require(IERC4524Recipient(recipient).onERC20Received(operator, sender, amount, data)
                    == type(IERC4524Recipient).interfaceId, errMsg);
        }
        // Either recipient is an EOA, or receiver's onERC20Received function was successfully called
        // and the function returned the correct value.
    }

    // -----------------------------------------------------------------------------------------------------------------
    // Send ETH to address

    /**
     * @dev Send an amount of ETH to a given address. Must be called after contract state is finalized.
     *
     * @param recipient The address to send ETH to.
     * @param amountETH The amount of ETH (in wei) to send to the recipient.
     * @param errorMessageOnFail The error message to revert with if the ETH payment couldn't be sent,
     *              or empty if the transaction should not revert if the attempt to send ETH fails.
     *              If `errorMessageOnFail` is empty and the attempt to send ETH fails, then `sendETH` will
     *              return the `(false, returnData)` from the call.
     * @return success `true` if the send succeeded, or `false` if `errorMessageOnFail` is empty and the send failed.
     * @return returnData Any data returned from a failed call, if `success == false`.
     */
    function sendETH(address recipient, uint256 amountETH, string memory errorMessageOnFail)
            // Use extCaller modifier for reentrancy protection
            internal extCaller returns (bool success, bytes memory returnData) {
        require(recipient != address(0), "Bad recipient");
        if (amountETH > 0) {
            // Calls the `receive` or `fallback` function with the specified amount of ETH (if a contract).
            // For contracts, the argument of "" delivers a zero-length payload to the call. Function calls
            // must be at least 4 bytes long, for the function selector. Solidity 0.6.0 and above will
            // call the `receive()` function if `msg.data.length == 0`, otherwise they will call the
            // `fallback()` function if `msg.data.length > 0` or there is no `receive()` function defined.
            // If there is no `receive()` or `fallback()` function defined, and the recipient is a contract,
            // then send will revert. For contracts compiled on older versions of solidity, zero-length
            // payloads will simply trigger the `fallback()` function -- there is no `receive()` function.
            // `call` automatically succeeds if the recipient is an EOA.
            (success, returnData) = recipient.call{value: amountETH}("");
            if (!success && bytes(errorMessageOnFail).length > 0) {
                // Only revert with message if the message is not empty
                revert(errorMessageOnFail);
            }
        } else {
            return (true, "");
        }
    }

    // -----------------------------------------------------------------------------------------------------------------
    // Permitting
    
    /** @dev The EIP2612 permit function typehash. */
    bytes32 internal constant EIP2612_PERMIT_TYPEHASH =
            keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    /**
     * @dev Check permit certificate. Reverts if certificate is not valid.
     *
     * @param deadline The block timestamp after which the certificate is invalid.
     * @param keccak256ABIEncoding The result of calling `keccak256(abi.encode(...))` with the `Permit` call typehash.
     * @param v The ECDSA `v` value.
     * @param r The ECDSA `r` value.
     * @param s The ECDSA `s` value.
     * @param requiredSigner The required value of the address recovered from the signature.
     */
    function checkPermit(uint256 deadline, bytes32 keccak256ABIEncoding,
            uint8 v, bytes32 r, bytes32 s, address requiredSigner) internal view {
        // solhint-disable-next-line not-rely-on-time
        require(block.timestamp <= deadline, "Expired");

        // From:
        // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/cryptography/ECDSA.sol
        //
        // See https://eips.ethereum.org/EIPS/eip-1271 :
        //
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0
                && (v == 27 || v == 28), "Bad sig");

        // Recover address of signer from digest, and check it matches the required signer (the token holder)
        // The \x19 prefix is part of the Recursive Length Prefix (RLP) encoding:
        // https://blog.ricmoo.com/verifying-messages-in-solidity-50a94f82b2ca
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR(), keccak256ABIEncoding));
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == requiredSigner, "Bad sig");
    }
}


// File contracts/main/OmniToken/OmniToken.sol


// The OmniToken Ethereum token contract library, supporting multiple token standards.
// By Hiroshi Yamamoto.
// 虎穴に入らずんば虎子を得ず。
//
// Officially hosted at: https://github.com/dublr/dublr

pragma solidity 0.8.15;











/**
 * @title OmniToken
 * @dev The OmniToken Ethereum token contract library, supporting multiple token standards.
 * @author Hiroshi Yamamoto
 */
contract OmniToken is OmniTokenInternal {

    // -----------------------------------------------------------------------------------------------------------------
    // ERC20 fields

    /** @dev ERC20 allowances. */
    mapping(address => mapping(address => uint256)) internal _allowance;

    /** @dev The allowance amount that is treated as unlimited by some ERC20 exchanges. */
    uint256 internal constant UNLIMITED_ALLOWANCE = type(uint256).max;

    // --------------

    /** @dev The block timestamp after which the ERC20 allowance expires for a given address. */
    mapping(address => mapping(address => uint256)) internal _allowanceExpirationTimestamp;

    /** @dev The expiration time that is treated as unlimited, if unlimited expiration is enabled. */
    uint256 internal constant UNLIMITED_EXPIRATION = type(uint256).max;

    /**
     * @notice The default number of seconds that an allowance is valid for, after the allowance or permit
     * is granted, before the allowance expires.
     *
     * @dev Note that the block timestamp can be altered by miners up to about +/-15 seconds (as long as block
     * timestamps increase monotonically), so do not use an allowance expiration time of less than 15 seconds.
     *
     * @dev Call `_owner_setDefaultAllowanceExpirationSec(type(uint256).max)` as the contract owner
     * if you want allowances never to expire, for backwards compatibility with ERC20, or pass a smaller
     * number to expire all allowances after that number of seconds by default.
     */
    uint256 public defaultAllowanceExpirationSec = UNLIMITED_EXPIRATION;

    /**
     * @notice Only callable by the owner/deployer of the contract.
     *
     * @dev Set the default number of seconds that an allowance is valid for. Set this to
     * `type(uint256).max == 2**256-1` if you want allowances never to expire, for backwards compatibility
     * with ERC20.
     *
     * @dev Note that the block timestamp can be altered by miners up to about +/-15 seconds (as long as block
     * timestamps increase monotonically), so do not use an allowance expiration time of less than 15 seconds.
     *
     * You can utilize a different expiration time on a case-by-case basis by calling `approveWithExpiration`.
     *
     * @param allowanceExpirationSec The number of seconds that allowances should be valid for.
     */
    function _owner_setDefaultAllowanceExpirationSec(uint256 allowanceExpirationSec) external ownerOnly {
        defaultAllowanceExpirationSec = allowanceExpirationSec;
    }

    /**
     * @dev Calculate default allowance expiration time.
     *
     * This is ERC20 compatible if `defaultAllowanceExpirationSec == type(uint256).max`.
     *
     * @return expirationTimestamp The default allowance expiration block timestamp, defaultAllowanceExpirationSec
     * seconds in the future.
     */
    function defaultAllowanceExpirationTime() private view returns (uint256 expirationTimestamp) {
        return defaultAllowanceExpirationSec == UNLIMITED_EXPIRATION
                    ? defaultAllowanceExpirationSec
                    // solhint-disable-next-line not-rely-on-time
                    : block.timestamp + defaultAllowanceExpirationSec;
    }

    // -----------------------------------------------------------------------------------------------------------------
    // ERC777 fields

    /** @dev ERC777 default operators, if any. */
    address[] internal _defaultOperators;

    /** @notice ERC777 default operators, if any. */
    function defaultOperators() external view returns (address[] memory operators) { return _defaultOperators; }

    /** @dev True if an address is a default operator. */
    mapping(address => bool) internal isDefaultOperator;

    /** @dev True if an address is a revoked default operator. */
    mapping(address => mapping(address => bool)) internal isRevokedDefaultOperatorFor;

    /** @dev True if an address is an authorized operator. */
    mapping(address => mapping(address => bool)) internal isAuthorizedOperatorFor;

    // -----------------------------------------------------------------------------------------------------------------
    // EIP2612 permit API public field

    /** @notice EIP2612 permit nonces. */
    mapping(address => uint) public override(IEIP2612) nonces;

    // -----------------------------------------------------------------------------------------------------------------
    // Constructor

    /**
     * @notice OmniToken constructor.
     *
     * @param tokenName the name of the token.
     * @param tokenSymbol the ticker symbol for the token.
     * @param tokenVersion the version number string for the token.
     * @param erc777DefaultOperators any default ERC777 operators.
     * @param initialMintAmount how many coins to mint for owner/deployer of contract.
     */
    constructor(string memory tokenName, string memory tokenSymbol, string memory tokenVersion,
            address[] memory erc777DefaultOperators, uint256 initialMintAmount)
            OmniTokenInternal(tokenName, tokenSymbol, tokenVersion) {

        // Set up ERC777 default operators, if any
        _defaultOperators = erc777DefaultOperators;
        for (uint256 i = 0; i < _defaultOperators.length; i++) {
            isDefaultOperator[_defaultOperators[i]] = true;
        }

        if (initialMintAmount > 0) {
            // Perform initial mint for contract owner/deployer
            _mint(msg.sender, msg.sender, initialMintAmount, "", "");
        }

        // Register via ERC1820
        registerInterfaceViaERC1820("OmniToken", true);
        
        // (Don't need to register OmniToken API via ERC165 -- each of the individual supported APIs is already
        // registered by OmniTokenInternal's constructor)
    }

    // -----------------------------------------------------------------------------------------------------------------
    // Core internal state update functions (modified with `stateUpdater` to prevent these functions being
    // called reentrantly, deeper in the stack than a function modified by `extCaller`, and to ensure that these
    // functions are not accidentally modified to call an `extCaller` function).

    /**
     * @dev Mint `amount` tokens into `account`.
     *
     * @param operator The address performing the mint.
     * @param account The address to mint tokens into.
     * @param amount The number of tokens to mint.
     * @param data Data generated by the user to be passed to the recipient.
     * @param operatorData Data generated by the operator to be passed to the recipient.
     */
    function _mint_stateUpdater(address operator, address account, uint256 amount, 
            bytes memory data, bytes memory operatorData)
            // Modified with `stateUpdater`, so `extCaller` functions cannot be called. This ensures that
            // future code changes do not break the Checks-Effects-Interactions pattern.
            internal stateUpdater {

        // PRECONDITIONS [CHECKS]:
        
        require(operator != address(0) && account != address(0) && amount != 0, "Bad arg");

        // MINT [EFFECTS]:

        // Mint tokens
        balanceOf[account] += amount;
        totalSupply += amount;

        // EMIT EVENTS:

        if (_erc777CallDepth > 0) {
            // Emit ERC777 Minted event
            emit Minted(operator, account, amount, data, operatorData);
        }
        // Emit ERC20 mint event (indicating a transfer from address(0))
        emit Transfer(/* sender = */ address(0), /* recipient = */ account, amount);
        // Emit ERC20 "safe approval" mint event
        emit TransferInfo(operator, /* sender = */ address(0), /* recipient = */ account, amount);
        
        // NO INTERACTIONS
    }
    
    /**
     * @dev Set the value of the allowance of `spender` to spend `holder`s tokens. Called only from `_approve`
     * and `_spendAllowance`, and only after all checks have been performed.
     *
     * This function performs no checks on the validity of the allowance, the holder, or the spender.
     */
    function _setAllowance_stateUpdater(
            address holder, address spender, uint256 amount, uint256 expirationTimestamp)
            // Modified with `stateUpdater`, so `extCaller` functions cannot be called. This ensures that
            // future code changes do not break the Checks-Effects-Interactions pattern.
            private stateUpdater {

        // APPROVE [EFFECTS]:

        // Update allowance.
        uint256 prevAmount = _allowance[holder][spender];
        _allowance[holder][spender] = amount;
        
        // Update expiration.
        _allowanceExpirationTimestamp[holder][spender] = expirationTimestamp;

        // EMIT EVENTS:

        // Emit ERC20 Approval event
        emit Approval(holder, spender, amount);
        // Emit ERC20 "safe approval" event
        emit ApprovalInfo(holder, spender, prevAmount, amount);
        if (expirationTimestamp < UNLIMITED_EXPIRATION) {
            // Emit ERC20 "approval with expiration" event if approval is not unlimited
            emit ApprovalWithExpiration(holder, spender, amount, expirationTimestamp);
        }
        
        // NO INTERACTIONS
    }

    /**
     * @dev Spend `amount` of `operator`'s allowance to spend `holder`'s tokens.
     * Called only by `_transfer`, and assumes some validity checks have already been performed.
     */ 
    function _spendAllowance_stateUpdater(address operator, address holder, uint256 amount)
            // Modified with `stateUpdater`, so `extCaller` functions cannot be called. This ensures that
            // future code changes do not break the Checks-Effects-Interactions pattern.
            private stateUpdater {
            
        // Can't use allowance from the ERC777 API (sanity check)
        assert(_erc777CallDepth == 0);

        uint256 allowedAmount = _allowance[holder][/* spender = */ operator];
        
        // If unlimited allowance was previously enabled, and spender was granted an unlimited allowance,
        // and then later unlimited allowance was disabled, and the spender's allowance is still unlimited,
        // then the transfer should fail (the user's allowance needs to be set to a limited allowance
        // before transfers will succeed again).
        require(_unlimitedAllowancesEnabled || allowedAmount != UNLIMITED_ALLOWANCE,
                "Unlimited allowance disabled");
        
        // Fail transaction if allowance is insufficient
        require(amount <= allowedAmount, "Insufficient allowance");

        // Fail if allowance has expired
        uint256 expirationTimestamp = _allowanceExpirationTimestamp[holder][operator];
        // solhint-disable-next-line not-rely-on-time
        require(block.timestamp <= expirationTimestamp, "Allowance expired");
                
        // If allowance is not unlimited, reduce allowance by amount
        if (allowedAmount != UNLIMITED_ALLOWANCE) {
            // Decrease allowance by amount
            uint256 newAllowedAmount;
            unchecked { newAllowedAmount = allowedAmount - amount; }  // Save gas, checked above
            // Approve decreased allowance amount (this will update _allowance[holder][/* spender = */ operator]).
            // Will generate new allowance events.
            _setAllowance_stateUpdater(holder, /* spender = */ operator, newAllowedAmount, expirationTimestamp);
        }
        
        // NO INTERACTIONS
    }


    /**
     * @dev Destroys `amount` tokens from `account`, reducing the total supply.
     *
     * @param operator The address performing the burn.
     * @param account The address to burn tokens from.
     * @param amount The number of tokens to burn.
     * @param data Data generated by the user to be passed to the recipient.
     * @param operatorData Data generated by the operator to be passed to the recipient.
     */
    function _burn_stateUpdater(address operator, address account, uint256 amount,
            bytes memory data, bytes memory operatorData) private stateUpdater {

        // PRECONDITIONS [CHECKS]:

        require(operator != address(0) && account != address(0) && amount != 0, "Bad arg");

        // BURN [EFFECTS]:

        // Burn tokens and decrease total supply
        require(amount <= balanceOf[account], "Insufficient balance");
        unchecked { balanceOf[account] -= amount; }  // Save gas by using unchecked
        totalSupply -= amount;

        // EMIT EVENTS:

        if (_erc777CallDepth > 0) {
            // Emit ERC777 Burned event
            emit Burned(operator, account, amount, data, operatorData);
        }
        // Emit ERC20 burn event (indicating a transfer to address(0))
        emit Transfer(/* sender = */ account, /* recipient = */ address(0), amount);
        // Emit ERC20 "safe approval" transfer event
        emit TransferInfo(operator, /* sender = */ account, /* recipient = */ address(0), amount);
        
        // NO INTERACTIONS
    }

    /**
     * @dev Transfer `amount` tokens from `holder` to `recipient`.
     *
     * @param operator The address performing the transfer.
     * @param holder The address holding the tokens being transferred.
     * @param recipient The address of the recipient.
     * @param amount The number of tokens to be transferred.
     * @param useAllowance If true, use the allowance system to determine whether the user can make
     *                     the transfer, and reduce the allowance by the amount of the transfer.
     * @param data Data generated by the user to be passed to the recipient.
     * @param operatorData Data generated by the operator to be passed to the recipient.
     */
    function _transfer_stateUpdater(address operator, address holder, address recipient, uint256 amount,
            bool useAllowance, bytes memory data, bytes memory operatorData) internal stateUpdater {

        // PRECONDITIONS [CHECKS]:

        require(operator != address(0) && holder != address(0) && recipient != address(0), "Bad arg");
        // Zero amount is valid for ERC20 transfers, for some reason (even though it's wasteful)

        // PERFORM TRANSFER [EFFECTS]:

        // If requested, check the operator has sufficient allowance to send the holder's tokens, and if so,
        // reduce the allowance by the requested amount.
        if (useAllowance && amount > 0) {
            // Spend (reduce) allowance. Will generate new allowance events, unless the allowance is unlimited.
            // Done before making the transfer, to ensure the allowance covers the transfer, but also, allowance
            // must be reduced before calling sender/recipient notification functions in external contracts.
            _spendAllowance_stateUpdater(operator, holder, amount);
        }

        // Transfer amount from holder to recipient
        require(amount <= balanceOf[holder], "Insufficient balance");
        unchecked { balanceOf[holder] -= amount; }  // Save gas by using unchecked
        balanceOf[recipient] += amount;

        // EMIT EVENTS:

        if (_erc777CallDepth > 0) {
            // Emit ERC777 Sent event
            emit Sent(operator, holder, recipient, amount, data, operatorData);
        }
        // Emit ERC20 transfer event
        emit Transfer(holder, recipient, amount);
        // Emit ERC20 "safe approval" transfer event
        emit TransferInfo(operator, holder, recipient, amount);
        
        // NO INTERACTIONS
    }

    /**
     * @dev Sets `allowedAmount` as the number of `holder`'s tokens that `spender` is allowed to transfer.
     *
     * @param holder The holder of the tokens.
     * @param spender The spender of the tokens.
     * @param allowedAmount The number of tokens to grant as an allowance.
     * @param expirationTimestamp The last valid block timestamp for the allowance.
     */
    function _approve_stateUpdater(address holder, address spender, uint256 allowedAmount,
            uint256 expirationTimestamp) internal {
    
        // PRECONDITIONS [CHECKS]:
        
        require(holder != address(0) && spender != address(0), "Bad arg");
        require(_unlimitedAllowancesEnabled || allowedAmount != UNLIMITED_ALLOWANCE, "Unlimited allowance disabled");
        // ERC777 doesn't use the approval API (sanity check)
        assert(_erc777CallDepth == 0);
        // solhint-disable-next-line not-rely-on-time
        require(block.timestamp <= expirationTimestamp, "Allowance expired");

        // APPROVE [EFFECTS], AND EMIT EVENTS:

        // Set allowed amount. Will generate new allowance events.
        _setAllowance_stateUpdater(holder, spender, allowedAmount, expirationTimestamp);
        
        // NO INTERACTIONS
    }

    // -----------------------------------------------------------------------------------------------------------------
    // Core account management functions, called by the public API.

    /**
     * @dev Mint `amount` tokens into `account`.
     *
     * @param operator The address performing the mint.
     * @param account The address to mint tokens into.
     * @param amount The number of tokens to mint.
     * @param data Data generated by the user to be passed to the recipient.
     * @param operatorData Data generated by the operator to be passed to the recipient.
     */
    function _mint(address operator, address account, uint256 amount, 
            bytes memory data, bytes memory operatorData) internal {

        // CHECKS, EFFECTS, EVENTS -- `stateUpdater` function:
        
        _mint_stateUpdater(operator, account, amount, data, operatorData);

        // NOTIFY RECIPIENT [INTERACTIONS] -- `extCaller` functions:

        // Notify ER777 token recipient of mint from address(0), if called from ERC777 API.
        if (_erc777CallDepth > 0) {
            call_ERC777TokensRecipient_tokensReceived(
                    operator, /* sender = */ address(0), /* recipient = */ account, amount,
                    data, operatorData);
        }
        // Notify ERC4524 token recipient of mint from address(0), if called from ERC4524 API
        if (_erc4524CallDepth > 0) {
            call_ERC4524TokensRecipient_onERC20Received(
                    operator, /* sender = */ address(0), /* recipient = */ account, amount, data);
        }
        // Call ERC1363 recipient if called from ERC1363 API
        if (_erc1363CallDepth > 0) {
            call_ERC1363Receiver_onTransferReceived(
                    operator, /* sender = */ address(0), /* recipient = */ account, amount, data);
        }
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the total supply.
     *
     * @param operator The address performing the burn.
     * @param account The address to burn tokens from.
     * @param amount The number of tokens to burn.
     * @param data Data generated by the user to be passed to the recipient.
     * @param operatorData Data generated by the operator to be passed to the recipient.
     */
    function _burn(address operator, address account, uint256 amount,
            bytes memory data, bytes memory operatorData) internal {

        // CHECKS, EFFECTS, EVENTS -- `stateUpdater` function:

        _burn_stateUpdater(operator, account, amount, data, operatorData);

        // NOTIFY TOKEN BURNER [INTERACTIONS] -- `extCaller` function:
        
        // Notify token burner (`account`) of tokens sent to address(0), if account is an ERC777 contract.
        // The ERC777 spec says this must happen before the balance transfer. However, this violates the
        // Checks-Effects-Interactions pattern, and is unsafe. Therefore we break from the standard and
        // call the sender only after the state has been updated. Other ERC777 implementations have made
        // this same choice: https://github.com/OpenZeppelin/openzeppelin-contracts/issues/1749
        if (_erc777CallDepth > 0) {
            call_ERC777TokensSender_tokensToSend(
                    operator, /* sender = */ account, /* recipient = */ address(0), amount, data, operatorData);
        }
    }

    /**
     * @dev Transfer `amount` tokens from `holder` to `recipient`.
     *
     * @param operator The address performing the transfer.
     * @param holder The address holding the tokens being transferred.
     * @param recipient The address of the recipient.
     * @param amount The number of tokens to be transferred.
     * @param useAllowance If true, use the allowance system to determine whether the user can make
     *                     the transfer, and reduce the allowance by the amount of the transfer.
     * @param data Data generated by the user to be passed to the recipient.
     * @param operatorData Data generated by the operator to be passed to the recipient.
     */
    function _transfer(address operator, address holder, address recipient, uint256 amount, bool useAllowance,
            bytes memory data, bytes memory operatorData) internal {

        // CHECKS, EFFECTS, EVENTS -- `stateUpdater` function:

        _transfer_stateUpdater(operator, holder, recipient, amount, useAllowance, data, operatorData);

        // NOTIFY SENDER/RECIPIENT [INTERACTIONS] -- `extCaller` functions:

        // Call ERC777 sender, if necessary.
        // The ERC777 spec says this must happen before the balance transfer. However, this violates the
        // Checks-Effects-Interactions pattern, and is unsafe. Therefore we break from the standard and
        // call the sender only after the state has been updated.
        // OpenZeppelin also considered breaking with the spec in the same way:
        // https://github.com/OpenZeppelin/openzeppelin-contracts/issues/1749
        // however ultimately a decision was made to instead deprecate ERC777 in OpenZeppelin
        // (it is considered an overengineered standard anyway):
        // https://github.com/OpenZeppelin/openzeppelin-contracts/issues/2620
        if (_erc777CallDepth > 0) {
            call_ERC777TokensSender_tokensToSend(operator, holder, recipient, amount, data, operatorData);
        }
        // Call ERC777 recipient if called from ERC777 API
        if (_erc777CallDepth > 0) {
            call_ERC777TokensRecipient_tokensReceived(operator, holder, recipient, amount, data, operatorData);
        }
        // Call ERC1363 recipient if called from ERC1363 API
        if (_erc1363CallDepth > 0) {
            call_ERC1363Receiver_onTransferReceived(operator, holder, recipient, amount, data);
        }
        // Call ERC4524 recipient if called from ERC4524 API
        if (_erc4524CallDepth > 0) {
            call_ERC4524TokensRecipient_onERC20Received(operator, holder, recipient, amount, data);
        }
    }

    /**
     * @dev Sets `allowedAmount` as the number of `holder`'s tokens that `spender` is allowed to transfer.
     *
     * @param holder The holder of the tokens.
     * @param spender The spender of the tokens.
     * @param allowedAmount The number of tokens to grant as an allowance.
     * @param expirationTimestamp The last valid block timestamp for the allowance.
     * @param data Data to be passed to the spender, if the approval is via ERC1363's `approveAndCall` function.
     */
    function _approve(address holder, address spender, uint256 allowedAmount, uint256 expirationTimestamp,
            bytes memory data) internal {

        // CHECKS, EFFECTS, EVENTS -- `stateUpdater` function:

        _approve_stateUpdater(holder, spender, allowedAmount, expirationTimestamp);

        // NOTIFY SPENDER [INTERACTIONS] -- `extCaller` function:
        
        // Notify ERC1363 spender, if called from ERC1363 API
        if (_erc1363CallDepth > 0) {
            call_ERC1363Spender_onApprovalReceived(/* holder = */ holder, spender, allowedAmount, data);
        }
    }

    // -----------------------------------------------------------------------------------------------------------------
    // ERC20 allowance/approve/transfer/transferFrom API functions

    /**
     * @notice Get the number of tokens that `spender` can spend on behalf of `holder`.
     *
     * @dev [ERC20] Returns the remaining number of tokens that `spender` will be allowed to spend on
     * behalf of `holder`, via a call to `transferFrom`. Zero by default. Also returns zero if
     * allowance has expired.
     *
     * @notice By calling this function, you confirm that this token is not considered an unregistered or
     * illegal security, and that this smart contract is not considered an unregistered or illegal exchange,
     * by the laws of any legal jurisdiction in which you hold or use tokens, or any legal jurisdiction
     * of the holder or spender.
     * 
     * @notice In some jurisdictions, such as the United States, any use, transfer, or sale of a token is
     * a taxable event. It is your responsibility to record the purchase price and sale price in ETH or
     * your local currency for each use, transfer, or sale of tokens you own, and to pay the taxes due.
     *
     * @param holder The token holder.
     * @param spender The token spender.
     * @return amount The allowance of `spender` to spend the funds of `holder`.
     */
    function allowance(address holder, address spender) public view erc20 override(IERC20)
            returns (uint256 amount) {
        // solhint-disable-next-line not-rely-on-time
        return block.timestamp <= _allowanceExpirationTimestamp[holder][spender]
                ? _allowance[holder][spender]
                : 0;  // Allowance has expired
    }

    /**
     * @notice Approve another account (or contract) to spend tokens on your behalf.
     *
     * @dev [ERC20] Approves a `spender` to be allowed to spend `amount` tokens on behalf of the
     * caller, via a call to `transferFrom`.
     *
     * Note that by default (unless the behavior was changed by the contract owner/deployer), the allowance
     * has to be set to zero before it can be set to a non-zero amount, to prevent the well-known ERC20 allowance
     * race condition that can allow double-spending of allowances. This is not fully ERC20-compatible, but it
     * is much safer.
     *
     * @notice By calling this function, you confirm that this token is not considered an unregistered or
     * illegal security, and that this smart contract is not considered an unregistered or illegal exchange,
     * by the laws of any legal jurisdiction in which you hold or use tokens, or any legal jurisdiction
     * of the holder or spender.
     * 
     * @notice In some jurisdictions, such as the United States, any use, transfer, or sale of a token is
     * a taxable event. It is your responsibility to record the purchase price and sale price in ETH or
     * your local currency for each use, transfer, or sale of tokens you own, and to pay the taxes due.
     *
     * @param spender The spender.
     * @param amount The allowance amount. Use a value of `0` to disallow `spender` spending tokens on behalf
     *          of the caller. Use a value of `2**256-1` to set unlimited allowance, if unlimited allowances are
     *          enabled. The allowed amount may be greater than the account balance.
     * @return success `true` if the approval succeeded (otherwise reverts).
     */
    function approve(address spender, uint256 amount) external erc20 override(IERC20)
            returns (bool success) {
        if (!_changingAllowanceWithoutZeroingEnabled && amount != 0) {
            // ERC20 safety: have to set allowance to zero (or let it expire) before it can be set to non-zero
            require(allowance(/* holder = */ msg.sender, spender) == 0, "Curr allowance nonzero");
        }
        _approve(/* holder = */ msg.sender, spender, amount, defaultAllowanceExpirationTime(), "");
        return true;
    }

    /**
     * @notice Transfer tokens to another account.
     *
     * @dev [ERC20] Moves `amount` tokens from the caller's account to `recipient`.
     *
     * @notice By calling this function, you confirm that this token is not considered an unregistered or
     * illegal security, and that this smart contract is not considered an unregistered or illegal exchange,
     * by the laws of any legal jurisdiction in which you hold or use tokens, or any legal jurisdiction
     * of the recipient.
     * 
     * @notice In some jurisdictions, such as the United States, any use, transfer, or sale of a token is
     * a taxable event. It is your responsibility to record the purchase price and sale price in ETH or
     * your local currency for each use, transfer, or sale of tokens you own, and to pay the taxes due.
     *
     * @param recipient The token recipient.
     * @param amount The number of tokens to transfer from the caller to `recipient`.
     * @return success `true` if the operation succeeded (otherwise reverts).
     */
    function transfer(address recipient, uint256 amount) external erc20 override(IERC20)
            returns (bool success) {
        // ERC20 tokens should almost never need to be sent to a smart contract -- tokens sent to a smart
        // contract are generally considered burned. Therefore, disallow transfer to smart contracts.
        // This is non-standard, but provides important protection to users against the most common mistake
        // in sending ERC20 tokens, which has caused millions of dollars in loss.
        // Instead, the user should use `approve` and `transferFrom`, or ERC777/ERC1363/ERC4524.
        require(_transferToContractsEnabled || !isContract(recipient), "Can't transfer to a contract");
        // Perform the transfer
        _transfer(/* operator = */ msg.sender, /* sender = */ msg.sender, recipient, amount,
                /* useAllowance = */ false, "", "");
        return true;
    }

    /**
     * @notice Transfer tokens from a holder account to a recipient account account, on behalf of the holder.
     *
     * @dev [ERC20] Moves `amount` tokens from `sender` to `recipient`. The caller must have previously been
     * approved by `sender` to send at least `amount` tokens on their behalf, by `sender` calling `approve`.
     * `amount` is deducted from the caller’s allowance (unless the allowance is set to unlimited).
     *
     * @notice By calling this function, you confirm that this token is not considered an unregistered or
     * illegal security, and that this smart contract is not considered an unregistered or illegal exchange,
     * by the laws of any legal jurisdiction in which you hold or use tokens, or any legal jurisdiction
     * of the holder or recipient.
     * 
     * @notice In some jurisdictions, such as the United States, any use, transfer, or sale of a token is
     * a taxable event. It is your responsibility to record the purchase price and sale price in ETH or
     * your local currency for each use, transfer, or sale of tokens you own, and to pay the taxes due.
     * 
     * @param holder The token holder.
     * @param recipient The token recipient.
     * @param amount The number of tokens to transfer from the caller to `recipient`.
     * @return success `true` if the operation succeeded (otherwise reverts).
     */
    function transferFrom(address holder, address recipient, uint256 amount) external erc20 override(IERC20)
            returns (bool success) {
        // Don't allow transfer to contracts, as with `transfer` function
        require(_transferToContractsEnabled || !isContract(recipient), "Can't transfer to a contract");
        // Perform the transfer
        _transfer(/* operator = */ msg.sender, holder, recipient, amount, /* useAllowance = */ true, "", "");
        return true;
    }

    // -----------------------------------------------------------------------------------------------------------------
    // ERC20 extensions

    /**
     * @notice Safely increase the allowance for a spender to spend your tokens.
     *
     * @dev [ERC20 extension] Increases the ERC20 token allowance granted to `spender` by the caller.
     * This is an alternative to `approve` that can mitigate for the double-spend race condition attack
     * that is described here:
     *
     * https://docs.google.com/document/d/1YLPtQxZu1UAvO9cZ1O2RPXBbT0mooh4DYKjA_jp-RLM/edit
     *
     * N.B. the transaction will revert if the allowance is currently set to the unlimited allowance
     * amount of `2**256-1`, since the correct new allowance amount cannot be determined by addition.
     *
     * @notice By calling this function, you confirm that this token is not considered an unregistered or
     * illegal security, and that this smart contract is not considered an unregistered or illegal exchange,
     * by the laws of any legal jurisdiction in which you hold or use tokens, or any legal jurisdiction
     * of the holder or spender.
     * 
     * @notice In some jurisdictions, such as the United States, any use, transfer, or sale of a token is
     * a taxable event. It is your responsibility to record the purchase price and sale price in ETH or
     * your local currency for each use, transfer, or sale of tokens you own, and to pay the taxes due.
     *
     * @param spender The token spender.
     * @param amountToAdd The number of tokens by which to increase the allowance of `spender`.
     * @return success `true` if the operation succeeded (otherwise reverts).
     */
    function increaseAllowance(address spender, uint256 amountToAdd)
            external erc20 override(IERC20IncreaseDecreaseAllowance) returns (bool success) {
        if (amountToAdd > 0) {
            uint256 allowedAmount = _allowance[/* holder = */ msg.sender][spender];
            // Don't increase an unlimited allowance
            require(allowedAmount != UNLIMITED_ALLOWANCE, "Unlimited allowance");
            // Don't increase an expired allowance
            // solhint-disable-next-line not-rely-on-time
            require(block.timestamp <= _allowanceExpirationTimestamp[/* holder = */ msg.sender][spender],
                    "Allowance expired");
            // Increase allowance
            _approve(/* holder = */ msg.sender, spender, allowedAmount + amountToAdd,
                    // Reset allowance expiration time every time allowance is increased
                    defaultAllowanceExpirationTime(), "");
        }
        return true;
    }

    /**
     * @notice Safely decrease the allowance for a spender to spend your tokens.
     *
     * @dev [ERC20 extension] Decreases the ERC20 token allowance granted to `spender` by the caller.
     * This is an alternative to `approve` that can mitigate for the double-spend race condition attack
     * that is described here:
     *
     * https://docs.google.com/document/d/1YLPtQxZu1UAvO9cZ1O2RPXBbT0mooh4DYKjA_jp-RLM/edit
     *
     * N.B. the transaction will revert if the allowance is currently set to the unlimited allowance
     * amount of `2**256-1`, since the correct new allowance amount cannot be determined by subtraction.
     *
     * @notice By calling this function, you confirm that this token is not considered an unregistered or
     * illegal security, and that this smart contract is not considered an unregistered or illegal exchange,
     * by the laws of any legal jurisdiction in which you hold or use tokens, or any legal jurisdiction
     * of the holder or spender.
     * 
     * @notice In some jurisdictions, such as the United States, any use, transfer, or sale of a token is
     * a taxable event. It is your responsibility to record the purchase price and sale price in ETH or
     * your local currency for each use, transfer, or sale of tokens you own, and to pay the taxes due.
     *
     * @param spender The token spender.
     * @param amountToSubtract The number of tokens by which to decrease the allowance of `spender`.
     * @return success `true` if the operation succeeded (otherwise reverts).
     *         Note that this operation will revert if amountToSubtract is greater than the current allowance.
     */
    function decreaseAllowance(address spender, uint256 amountToSubtract)
            external erc20 override(IERC20IncreaseDecreaseAllowance) returns (bool success) {
        if (amountToSubtract > 0) {
            uint256 allowedAmount = _allowance[/* holder = */ msg.sender][spender];
            // Don't decrease an unlimited allowance
            require(allowedAmount != UNLIMITED_ALLOWANCE, "Unlimited allowance");
            // Can't decrease by more than the current allowance
            require(amountToSubtract <= allowedAmount, "Insufficient allowance");
            // Don't decrease an expired allowance
            // solhint-disable-next-line not-rely-on-time
            require(block.timestamp <= _allowanceExpirationTimestamp[/* holder = */ msg.sender][spender],
                    "Allowance expired");
            // Decrease allowance
            uint256 newAllowedAmount;
            unchecked { newAllowedAmount = allowedAmount - amountToSubtract; }  // Save gas with unchecked
            _approve(/* holder = */ msg.sender, spender, newAllowedAmount,
                    // Reset allowance expiration time every time allowance is decreased
                    defaultAllowanceExpirationTime(), "");
        }
        return true;
    }

    /**
     * @notice Safely change the allowance for a spender to spend your tokens.
     * 
     * @dev [ERC20 extension] Atomically compare-and-set the allowance for a spender.
     * This is designed to mitigate the ERC-20 allowance attack described in:
     *
     * "ERC20 API: An Attack Vector on Approve/TransferFrom Methods"
     * https://docs.google.com/document/d/1YLPtQxZu1UAvO9cZ1O2RPXBbT0mooh4DYKjA_jp-RLM/edit
     *
     * @notice By calling this function, you confirm that this token is not considered an unregistered or
     * illegal security, and that this smart contract is not considered an unregistered or illegal exchange,
     * by the laws of any legal jurisdiction in which you hold or use tokens, or any legal jurisdiction
     * of the holder or spender.
     * 
     * @notice In some jurisdictions, such as the United States, any use, transfer, or sale of a token is
     * a taxable event. It is your responsibility to record the purchase price and sale price in ETH or
     * your local currency for each use, transfer, or sale of tokens you own, and to pay the taxes due.
     *
     * @param spender The spender.
     * @param expectedCurrentAmount The expected amount of `spender`'s current allowance.
     *        If the current allowance does not match this value, then the transaction will revert.
     * @param amount The new allowance amount.
     * @return success `true` if the operation succeeded (otherwise reverts).
     */
    function approve(address spender, uint256 expectedCurrentAmount, uint256 amount)
            external erc20 override(IERC20SafeApproval) returns (bool success) {
        require(_allowance[/* holder = */ msg.sender][spender] == expectedCurrentAmount, "Allowance mismatch");
        // Approve new allowance, with default expiration time.
        _approve(/* holder = */ msg.sender, spender, amount, defaultAllowanceExpirationTime(), "");
        return true;
    }

    /**
     * @notice Approve a spender to spend your tokens with a specified expiration time.
     *
     * @dev ERC20 extension function for approving with time-limited allowances.
     *
     * See: https://github.com/vrypan/EIPs/blob/master/EIPS/eip-draft_time_limited_token_allowances.md
     *
     * @dev Note that the block timestamp can be altered by miners up to about +/-15 seconds (as long as block
     * timestamps increase monotonically), so do not use an allowance expiration time of less than 15 seconds.
     *
     * Note that by default (unless the behavior was changed by the contract owner/deployer), the allowance
     * has to be set to zero before it can be set to a non-zero amount, to prevent the well-known ERC20 allowance
     * race condition that can allow double-spending of allowances. This is not fully ERC20-compatible (and
     * it is not the defined behavior of this ERC20 extension), but it is much safer than the ERC20 default.
     *
     * @notice By calling this function, you confirm that this token is not considered an unregistered or
     * illegal security, and that this smart contract is not considered an unregistered or illegal exchange,
     * by the laws of any legal jurisdiction in which you hold or use tokens, or any legal jurisdiction
     * of the holder or spender.
     * 
     * @notice In some jurisdictions, such as the United States, any use, transfer, or sale of a token is
     * a taxable event. It is your responsibility to record the purchase price and sale price in ETH or
     * your local currency for each use, transfer, or sale of tokens you own, and to pay the taxes due.
     *
     * @param spender The token spender.
     * @param amount The number of tokens to allow spender to spend on the caller's behalf.
     * @param expirationSec The number of seconds after which the allowance expires, or `2**256-1` if the
     *          allowance should not expire (consider this unsafe), or `0` if spending must happen in the
     *          same block as approval (e.g. for a flash loan).
     *          Note: The proposal for this ERC20 extension API requires a user to specify the number of
     *          blocks an approval should be valid for before expiration. OmniToken uses seconds instead
     *          of number of blocks, because mining does not happen at a reliable interval.
     * @return success `true` if approval was successful.
     */
    function approveWithExpiration(address spender, uint256 amount, uint256 expirationSec)
            external erc20 override(IERC20TimeLimitedTokenAllowances) returns (bool success) {
        if (!_changingAllowanceWithoutZeroingEnabled && amount != 0) {
            // Have to set allowance to zero (or let it expire) before it can be set to non-zero
            require(allowance(/* holder = */ msg.sender, spender) == 0, "Curr allowance nonzero");
        }
        // Timestamps can be fudged up to 15 seconds by miners, so expirationSec needs to be greater than 15
        require(expirationSec > 15, "expirationSec must be >15");
        _approve(/* holder = */ msg.sender, spender, amount,
                expirationSec == UNLIMITED_EXPIRATION ? expirationSec
                        // solhint-disable-next-line not-rely-on-time
                        : block.timestamp + expirationSec, "");
        return true;
    }
    
    /**
     * @notice Get the expiration timestamp for the allowance of a spender to spend tokens on behalf of a holder.
     * 
     * @dev ERC20 extension function for returning the allowance amount and block timestamp after which allowance
     * expires. Expiration time will be `2**256-1` for allowances that do not expire, or smaller than that value
     * for time-limited allowances.
     *
     * See: https://github.com/vrypan/EIPs/blob/master/EIPS/eip-draft_time_limited_token_allowance.md
     *
     * @param holder The token holder.
     * @param spender The token spender.
     * @return remainingAmount The amount of the allowance remaining, or 0 if the allowance has expired.
     * @return expirationTimestamp The block timestamp after which the allowance expires.
     */
    function allowanceWithExpiration(address holder, address spender)
            external view erc20 override(IERC20TimeLimitedTokenAllowances)
            returns (uint256 remainingAmount, uint256 expirationTimestamp) {
        remainingAmount = allowance(holder, spender);
        expirationTimestamp = _allowanceExpirationTimestamp[holder][spender];
    }

    /**
     * @notice Burn tokens.
     *
     * @dev [ERC20 extension] Burn tokens. Destroys `amount` tokens from caller's account forever,
     * reducing the total supply. Use with caution, as this cannot be reverted, and you should ensure
     * that some other smart contract guarantees you some benefit for burning tokens before you burn
     * them.
     *
     * By convention, burning is logged as a transfer to the zero address.
     *
     * @param amount The amount to burn.
     */
    function burn(uint256 amount) external erc20 override(IERC20Burn) {
        _burn(/* operator = */ msg.sender, /* account = */ msg.sender, amount, "", "");
    }

    // -----------------------------------------------------------------------------------------------------------------
    // ERC777 functions

    /**
     * @notice Authorize another address, `operator`, to be able to send your tokens.
     *
     * @dev [ERC777] Authorize `operator` to be able to send the caller's tokens. The operator can then call
     * `operatorSend` to transfer the caller's tokens to a recipient.
     *
     * @param operator The operator to authorize.
     */
    function authorizeOperator(address operator) external erc777 override(IERC777) {
        require(operator != msg.sender, "Can't auth self");
        if (isDefaultOperator[operator]) {
            isRevokedDefaultOperatorFor[operator][msg.sender] = false;
        } else {
            isAuthorizedOperatorFor[operator][msg.sender] = true;
        }
        emit AuthorizedOperator(operator, msg.sender);
    }

    /**
     * @notice Revoke `operator` from being able to send your tokens.
     *
     * @dev [ERC777] Revoke `operator` from being able to send the caller's tokens.
     *
     * @param operator The operator to revoke.
     */
    function revokeOperator(address operator) external erc777 override(IERC777) {
        require(operator != msg.sender, "Can't revoke self");
        if (isDefaultOperator[operator]) {
            isRevokedDefaultOperatorFor[operator][msg.sender] = true;
        } else {
            isAuthorizedOperatorFor[operator][msg.sender] = false;
        }
        emit RevokedOperator(operator, msg.sender);
    }

    /**
     * @notice Check whether an operator is authorized to manage the tokens held by a given address.
     *
     * @dev [ERC777] Checking whether `operator` is authorized to manage the tokens held by
     * `holder` address. Returns `true` if `operator` is a non-revoked default operator, or has
     * been previously authorized (and not later revoked) by `holder` calling `authorizeOperator(operator)`.
     *
     * @param operator address to check if it has the right to manage the tokens.
     * @param holder address which holds the tokens to be managed.
     * @return isOperatorForHolder `true` if `operator` is authorized for `holder`.
     */
    function isOperatorFor(address operator, address holder) public view erc777View override(IERC777)
            returns (bool isOperatorForHolder) {
        return operator == holder || isAuthorizedOperatorFor[operator][holder]
            || (isDefaultOperator[operator] && !isRevokedDefaultOperatorFor[operator][holder]);
    }

    /**
     * @notice Send tokens to a recipient.
     *
     * @dev [ERC777] Send `amount` tokens to `recipient`, passing `data` to the recipient. `recipient` must
     * implement the ERC777 recipient interface, unless it is a non-contract account (EOA wallet).
     *
     * @notice By calling this function, you confirm that this token is not considered an unregistered or
     * illegal security, and that this smart contract is not considered an unregistered or illegal exchange,
     * by the laws of any legal jurisdiction in which you hold or use tokens.
     * 
     * @notice In some jurisdictions, such as the United States, any use, transfer, or sale of a token is
     * a taxable event. It is your responsibility to record the purchase price and sale price in ETH or
     * your local currency for each use, transfer, or sale of tokens you own, and to pay the taxes due.
     *
     * @param recipient The address of the recipient.
     * @param amount The number of tokens to be sent.
     */
    function send(address recipient, uint256 amount, bytes calldata data) external erc777 override(IERC777) {
        // Safety is guaranteed by the erc777 function modifier, which sets _erc777CallDepth,
        // which requires _transfer to successfully notify the ERC777 recipient
        _transfer(/* operator = */ msg.sender, /* holder = */ msg.sender, recipient, amount,
                  /* useAllowance = */ false, data, "");
    }

    /**
     * @notice Send tokens on behalf of a token holder that you have previously been authorized to be
     * an operator for.
     *
     * @dev [ERC777] Send `amount` tokens on behalf of the address `holder` to the address `recipient`.
     * The caller must have previously been authorized for as an operator for `sender`, by `sender`
     * calling `authorizeOperator`.
     *
     * The `holder` account may optionally implement the ERC777 sender interface to be notified when
     * tokens are sent.
     * 
     * `recipient` must implement the ERC777 recipient interface, unless it is a non-contract
     * account (EOA wallet).
     *
     * @notice By calling this function, you confirm that this token is not considered an unregistered or
     * illegal security, and that this smart contract is not considered an unregistered or illegal exchange,
     * by the laws of any legal jurisdiction in which you hold or use tokens, or any legal jursidiction
     * of the holder or recipient account.
     * 
     * @notice In some jurisdictions, such as the United States, any use, transfer, or sale of a token is
     * a taxable event. It is your responsibility to record the purchase price and sale price in ETH or
     * your local currency for each use, transfer, or sale of tokens you own, and to pay the taxes due.
     *
     * @param holder The address holding the tokens being sent.
     * @param recipient The address of the recipient.
     * @param amount The number of tokens to be sent.
     * @param data Data generated by the user to be sent to the recipient.
     * @param operatorData Data generated by the operator to be sent to the recipient.
     */
    function operatorSend(address holder, address recipient, uint256 amount, bytes calldata data,
            bytes calldata operatorData) external erc777 override(IERC777) {
        // Ensure `msg.sender` is operator for `holder`
        require(isOperatorFor(msg.sender, holder), "Not operator");
        // Safety is guaranteed by the erc777 function modifier, which sets _erc777CallDepth,
        // which requires _transfer to successfully notify the ERC777 recipient
        _transfer(/* operator = */  msg.sender, holder, recipient, amount,
                  /* useAllowance = */ false, data, operatorData);
    }

    /**
     * @notice Burn tokens.
     *
     * @dev [ERC777] Burn tokens. Destroys `amount` tokens from caller's account forever,
     * reducing the total supply.
     *
     * Use with caution, as this cannot be reverted, and you should ensure that some other contract
     * guarantees you some benefit for burning tokens before you burn them.
     *
     * @param amount The number of tokens to burn.
     * @param data Extra data to log.
     */
    function burn(uint256 amount, bytes calldata data) external erc777 override(IERC777) {
        // Burn tokens
        _burn(/* operator = */ msg.sender, /* account = */ msg.sender, amount, data, "");
    }

    /**
     * @notice Burn tokens.
     *
     * @dev [ERC777] Burn tokens. Destroys `amount` tokens from `holder` account forever, reducing the total supply.
     * Caller must have previously been approved as an operator for `holder`.
     *
     * Use with caution, as this cannot be reverted, and you should ensure that some other contract guarantees
     * you some benefit for burning tokens before you burn them.
     *
     * @param holder The account to destroy tokens from.
     * @param amount The number of tokens to burn.
     * @param data Extra data to log.
     * @param operatorData Extra data to log.
     */
    function operatorBurn(address holder, uint256 amount, bytes calldata data, bytes calldata operatorData)
            external erc777 override(IERC777) {
        // Ensure `sender` is operator for `holder`
        require(isOperatorFor(msg.sender, holder), "Not operator");
        // Burn tokens
        _burn(/* operator = */ msg.sender, /* account = */ holder, amount, data, operatorData);
    }
    
    // -----------------------------------------------------------------------------------------------------------------
    // ERC1363 functions
    
    /**
     * @notice Transfer tokens to a recipient, and then call the ERC1363 recipient notification interface
     * on the recipient.
     *
     * @dev [ERC1363] Transfer tokens from the caller to `recipient`, and then call the ERC1363 receiver
     * interface's `onTransferReceived` on the recipient. The transaction will fail if the recipient does
     * not implement this interface (including if the recipient address is an EOA address).
     *
     * @notice By calling this function, you confirm that this token is not considered an unregistered or
     * illegal security, and that this smart contract is not considered an unregistered or illegal exchange,
     * by the laws of any legal jurisdiction in which you hold or use tokens, or any legal jurisdiction
     * of the recipient.
     * 
     * @notice In some jurisdictions, such as the United States, any use, transfer, or sale of a token is
     * a taxable event. It is your responsibility to record the purchase price and sale price in ETH or
     * your local currency for each use, transfer, or sale of tokens you own, and to pay the taxes due.
     *
     * @param recipient The address which you want to transfer tokens to.
     * @param amount The number of tokens to be transferred.
     * @return success `true` unless the transaction is reverted.
     */
    function transferAndCall(address recipient, uint256 amount)
            external erc1363 override(IERC1363) returns (bool success) {
        // Safety is guaranteed by the erc1363 function modifier, which sets _erc1363CallDepth,
        // which requires _transfer to successfully notify the ERC1363 recipient
        _transfer(/* operator = */ msg.sender, /* holder = */ msg.sender, recipient, amount,
                  /* useAllowance = */ false, "", "");
        return true;
    }

    /**
     * @notice Transfer tokens to a recipient, and then call the ERC1363 recipient notification interface
     * on the recipient.
     *
     * @dev [ERC1363] Transfer tokens from the caller to `recipient`, and then call the ERC1363 receiver
     * interface's `onTransferReceived` on the recipient. The transaction will fail if the recipient does
     * not implement this interface (including if the recipient address is an EOA address).
     *
     * @notice By calling this function, you confirm that this token is not considered an unregistered or
     * illegal security, and that this smart contract is not considered an unregistered or illegal exchange,
     * by the laws of any legal jurisdiction in which you hold or use tokens, or any legal jurisdiction
     * of the recipient.
     * 
     * @notice In some jurisdictions, such as the United States, any use, transfer, or sale of a token is
     * a taxable event. It is your responsibility to record the purchase price and sale price in ETH or
     * your local currency for each use, transfer, or sale of tokens you own, and to pay the taxes due.
     *
     * @param recipient The address which you want to transfer tokens to.
     * @param amount The number of tokens to be transferred.
     * @param data Additional data with no specified format, sent in call to `recipient`.
     * @return success `true` unless the transaction is reverted.
     */
    function transferAndCall(address recipient, uint256 amount, bytes memory data)
            external erc1363 override(IERC1363) returns (bool success) {
        // Safety is guaranteed by the erc1363 function modifier, which sets _erc1363CallDepth,
        // which requires _transfer to successfully notify the ERC1363 recipient
        _transfer(/* operator = */ msg.sender, /* holder = */ msg.sender, recipient, amount,
                  /* useAllowance = */ false, data, "");
        return true;
    }

    /**
     * @notice Transfer tokens to a recipient on behalf of another account, and then call the ERC1363
     * recipient notification interface on the recipient.
     *
     * @dev [ERC1363] Transfer tokens from `holder` to `recipient`, and then call the ERC1363 spender
     * interface's `onApprovalReceived` on the recipient. The transaction will fail if the recipient does
     * not implement this interface (including if the recipient address is an EOA address).
     *
     * @notice By calling this function, you confirm that this token is not considered an unregistered or
     * illegal security, and that this smart contract is not considered an unregistered or illegal exchange,
     * by the laws of any legal jurisdiction in which you hold or use tokens, or any legal jurisdiction
     * of the holder or recipient.
     * 
     * @notice In some jurisdictions, such as the United States, any use, transfer, or sale of a token is
     * a taxable event. It is your responsibility to record the purchase price and sale price in ETH or
     * your local currency for each use, transfer, or sale of tokens you own, and to pay the taxes due.
     *
     * @param holder The address which you want to send tokens on behalf of.
     * @param recipient The address which you want to transfer tokens to.
     * @param amount The number of tokens to be transferred.
     * @return success `true` unless the transaction is reverted.
     */
    function transferFromAndCall(address holder, address recipient, uint256 amount)
            external erc1363 override(IERC1363) returns (bool success) {
        // Safety is guaranteed by the erc1363 function modifier, which sets _erc1363CallDepth,
        // which requires _transfer to successfully notify the ERC1363 recipient
        _transfer(/* operator = */ msg.sender, holder, recipient, amount, /* useAllowance = */ true, "", "");
        return true;
    }


    /**
     * @notice Transfer tokens to a recipient on behalf of another account, and then call the ERC1363
     * recipient notification interface on the recipient.
     *
     * @dev [ERC1363] Transfer tokens from `holder` to `recipient`, and then call the ERC1363 spender
     * interface's `onApprovalReceived` on the recipient. The transaction will fail if the recipient does
     * not implement this interface (including if the recipient address is an EOA address).
     *
     * @notice By calling this function, you confirm that this token is not considered an unregistered or
     * illegal security, and that this smart contract is not considered an unregistered or illegal exchange,
     * by the laws of any legal jurisdiction in which you hold or use tokens, or any legal jurisdiction
     * of the holder or recipient.
     * 
     * @notice In some jurisdictions, such as the United States, any use, transfer, or sale of a token is
     * a taxable event. It is your responsibility to record the purchase price and sale price in ETH or
     * your local currency for each use, transfer, or sale of tokens you own, and to pay the taxes due.
     *
     * @param holder The address which you want to send tokens from.
     * @param recipient The address which you want to transfer tokens to.
     * @param amount The number of tokens to be transferred.
     * @param data Additional data with no specified format, sent in call to `recipient`.
     * @return success `true` unless the transaction is reverted.
     */
    function transferFromAndCall(address holder, address recipient, uint256 amount, bytes memory data)
            external erc1363 override(IERC1363) returns (bool success) {
        // Safety is guaranteed by the erc1363 function modifier, which sets _erc1363CallDepth,
        // which requires _transfer to successfully notify the ERC1363 recipient
        _transfer(/* operator = */ msg.sender, holder, recipient, amount, /* useAllowance = */ true, data, "");
        return true;
    }

    /**
     * @notice Approve another account to spend your tokens, and then call the ERC1363 spender notification
     * interface on the spender.
     *
     * @dev [ERC1363] Approve `spender` to spend the specified number of tokens on behalf of
     * caller (the token holder), and then call `onApprovalReceived` on spender.
     *
     * @notice By calling this function, you confirm that this token is not considered an unregistered or
     * illegal security, and that this smart contract is not considered an unregistered or illegal exchange,
     * by the laws of any legal jurisdiction in which you hold or use tokens, or any legal jurisdiction
     * of the spender or recipient.
     * 
     * @notice In some jurisdictions, such as the United States, any use, transfer, or sale of a token is
     * a taxable event. It is your responsibility to record the purchase price and sale price in ETH or
     * your local currency for each use, transfer, or sale of tokens you own, and to pay the taxes due.
     *
     * @param spender The address which will spend the funds.
     * @param amount The number of tokens to allow the spender to spend.
     * @return success `true` unless the transaction is reverted.
     */
    function approveAndCall(address spender, uint256 amount)
            external erc1363 override(IERC1363) returns (bool success) {
        // Safety is guaranteed by the erc1363 function modifier, which sets _erc1363CallDepth,
        // which requires _approve to successfully notify the ERC1363 spender
        _approve(/* holder = */ msg.sender, spender, amount, defaultAllowanceExpirationTime(), "");
        return true;
    }

    /**
     * @notice Approve another account to spend your tokens, and then call the ERC1363 spender notification
     * interface on the spender.
     *
     * @dev [ERC1363] Approve `spender` to spend the specified number of tokens on behalf of
     * caller (the token holder), and then call `onApprovalReceived` on spender.
     *
     * @notice By calling this function, you confirm that this token is not considered an unregistered or
     * illegal security, and that this smart contract is not considered an unregistered or illegal exchange,
     * by the laws of any legal jurisdiction in which you hold or use tokens, or any legal jurisdiction
     * of the spender or recipient.
     * 
     * @notice In some jurisdictions, such as the United States, any use, transfer, or sale of a token is
     * a taxable event. It is your responsibility to record the purchase price and sale price in ETH or
     * your local currency for each use, transfer, or sale of tokens you own, and to pay the taxes due.
     *
     * @param spender The address which will spend the funds.
     * @param amount The number of tokens to be allow the spender to spend.
     * @param data Additional data with no specified format, sent in call to `spender`.
     * @return success `true` unless the transaction is reverted.
     */
    function approveAndCall(address spender, uint256 amount, bytes memory data)
            external erc1363 override(IERC1363) returns (bool success) {
        // Safety is guaranteed by the erc1363 function modifier, which sets _erc1363CallDepth,
        // which requires _approve to successfully notify the ERC1363 spender
        _approve(/* holder = */ msg.sender, spender, amount, defaultAllowanceExpirationTime(), data);
        return true;
    }
       
    // -----------------------------------------------------------------------------------------------------------------
    // ERC4524 functions

    /**
     * @notice Transfer funds and then notify the recipient via the ERC4524 receiver interface.
     *
     * @dev [ERC4524] Move `amount` tokens from the caller's account to `recipient`. Only succeeds if `recipient`
     * correctly implements the ERC4524 receiver interface, or if the receiver is an EOA (non-contract wallet).
     *
     * @notice By calling this function, you confirm that this token is not considered an unregistered or
     * illegal security, and that this smart contract is not considered an unregistered or illegal exchange,
     * by the laws of any legal jurisdiction in which you hold or use tokens, or any legal jurisdiction
     * of the recipient.
     * 
     * @notice In some jurisdictions, such as the United States, any use, transfer, or sale of a token is
     * a taxable event. It is your responsibility to record the purchase price and sale price in ETH or
     * your local currency for each use, transfer, or sale of tokens you own, and to pay the taxes due.
     *
     * @param recipient The token recipient.
     * @param amount The number of tokens to transfer from the caller to `recipient`.
     * @return success `true` if the operation succeeded (otherwise reverts).
     */
    function safeTransfer(address recipient, uint256 amount)
            external erc4524 override(IERC4524) returns(bool success) {
        // Safety is guaranteed by the erc4524 function modifier, which sets _erc4524CallDepth,
        // which requires _transfer to successfully notify the ERC4524 recipient
        _transfer(/* operator = */ msg.sender, /* holder = */ msg.sender, recipient, amount,
                  /* useAllowance = */ false, "", "");
        return true;
    }
    
    /**
     * @notice Transfer funds and then notify the recipient via the ERC4524 receiver interface.
     *
     * @dev [ERC4524] Move `amount` tokens from the caller's account to `recipient`. Only succeeds if `recipient`
     * correctly implements the ERC4524 receiver interface, or if the receiver is an EOA (non-contract wallet).
     *
     * @notice By calling this function, you confirm that this token is not considered an unregistered or
     * illegal security, and that this smart contract is not considered an unregistered or illegal exchange,
     * by the laws of any legal jurisdiction in which you hold or use tokens, or any legal jurisdiction
     * of the recipient.
     * 
     * @notice In some jurisdictions, such as the United States, any use, transfer, or sale of a token is
     * a taxable event. It is your responsibility to record the purchase price and sale price in ETH or
     * your local currency for each use, transfer, or sale of tokens you own, and to pay the taxes due.
     *
     * @param recipient The token recipient.
     * @param amount The number of tokens to transfer from the caller to `recipient`.
     * @param data Extra data to add to the emmitted transfer event.
     * @return success `true` if the operation succeeded (otherwise reverts).
     */
    function safeTransfer(address recipient, uint256 amount, bytes memory data)
            external erc4524 override(IERC4524) returns(bool success) {
        // Safety is guaranteed by the erc4524 function modifier, which sets _erc4524CallDepth,
        // which requires _transfer to successfully notify the ERC4524 recipient
        _transfer(/* operator = */ msg.sender, /* holder = */ msg.sender, recipient, amount,
                  /* useAllowance = */ false, data, "");
        return true;
    }
    
    /**
     * @notice Transfer funds and then notify the recipient via the ERC4524 receiver interface.
     *
     * @dev [ERC4524] Move `amount` tokens from `holder` to `recipient`. (The caller must have
     * previously been approved by `holder` to send at least `amount` tokens on behalf of `holder`, by
     * `holder` calling `approve`.) `amount` is then deducted from the caller’s allowance.
     * Only succeeds if `recipient` correctly implements the ERC4524 receiver interface,
     * or if `recipient` is an EOA (non-contract wallet).
     *
     * @notice By calling this function, you confirm that this token is not considered an unregistered or
     * illegal security, and that this smart contract is not considered an unregistered or illegal exchange,
     * by the laws of any legal jurisdiction in which you hold or use tokens, or any legal jurisdiction
     * of the holder or recipient.
     * 
     * @notice In some jurisdictions, such as the United States, any use, transfer, or sale of a token is
     * a taxable event. It is your responsibility to record the purchase price and sale price in ETH or
     * your local currency for each use, transfer, or sale of tokens you own, and to pay the taxes due.
     * 
     * @param holder The token holder.
     * @param recipient The token recipient.
     * @param amount The number of tokens to transfer from the caller to `recipient`.
     * @return success `true` if the operation succeeded (otherwise reverts).
     */
    function safeTransferFrom(address holder, address recipient, uint256 amount)
            external erc4524 override(IERC4524) returns(bool success) {
        // Safety is guaranteed by the erc4524 function modifier, which sets _erc4524CallDepth,
        // which requires _transfer to successfully notify the ERC4524 recipient
        _transfer(/* operator = */ msg.sender, holder, recipient, amount, /* useAllowance = */ true, "", "");
        return true;
    }
    
    /**
     * @notice Transfer funds and then notify the recipient via the ERC4524 receiver interface.
     *
     * @dev [ERC4524] Move `amount` tokens from `holder` to `recipient`. (The caller must have
     * previously been approved by `holder` to send at least `amount` tokens on behalf of `holder`, by
     * `holder` calling `approve`.) `amount` is then deducted from the caller’s allowance.
     * Only succeeds if `recipient` correctly implements the ERC4524 receiver interface,
     * or if `recipient` is an EOA (non-contract wallet).
     *
     * @notice By calling this function, you confirm that this token is not considered an unregistered or
     * illegal security, and that this smart contract is not considered an unregistered or illegal exchange,
     * by the laws of any legal jurisdiction in which you hold or use tokens, or any legal jurisdiction
     * of the holder or recipient.
     * 
     * @notice In some jurisdictions, such as the United States, any use, transfer, or sale of a token is
     * a taxable event. It is your responsibility to record the purchase price and sale price in ETH or
     * your local currency for each use, transfer, or sale of tokens you own, and to pay the taxes due.
     * 
     * @param holder The token holder.
     * @param recipient The token recipient.
     * @param amount The number of tokens to transfer from the caller to `recipient`.
     * @param data Extra data to add to the emmitted transfer event.
     * @return success `true` if the operation succeeded (otherwise reverts).
     */
    function safeTransferFrom(address holder, address recipient, uint256 amount, bytes memory data)
            external erc4524 override(IERC4524) returns(bool success) {
        // Safety is guaranteed by the erc4524 function modifier, which sets _erc4524CallDepth,
        // which requires _transfer to successfully notify the ERC4524 recipient
        _transfer(/* operator = */ msg.sender, holder, recipient, amount, /* useAllowance = */ true, data, "");
        return true;
    }

    // -----------------------------------------------------------------------------------------------------------------
    // Permitting

    /**
     * @notice Convert a signed certificate into a permit or allowance for a spender account to spend tokens
     * on behalf of a holder account.
     *
     * @dev [EIP2612] Implements the EIP2612 permit standard. Sets the spendable allowance for `spender` to
     * spend `holder`'s tokens, which can then be transferred using the ERC20 `transferFrom` function.
     *
     * https://eips.ethereum.org/EIPS/eip-2612
     * https://github.com/Uniswap/v2-core/blob/master/contracts/UniswapV2ERC20.sol
     *
     * @notice By calling this function, you confirm that this token is not considered an unregistered or
     * illegal security, and that this smart contract is not considered an unregistered or illegal exchange,
     * by the laws of any legal jurisdiction in which you hold or use tokens, or any legal jurisdiction
     * of the holder or spender.
     * 
     * @notice In some jurisdictions, such as the United States, any use, transfer, or sale of a token is
     * a taxable event. It is your responsibility to record the purchase price and sale price in ETH or
     * your local currency for each use, transfer, or sale of tokens you own, and to pay the taxes due.
     *
     * @param holder The token holder that signed the certificate.
     * @param spender The spender who will be authorized to spend tokens on behalf of `holder`.
     * @param amount The number of tokens `spender` will be authorized to spend on behalf of `holder`.
     * @param deadline The block timestamp after which the certificate expires.
     *          Note that if the permit is granted, then the allowance that is approved has its own deadline,
     *          separate from the certificate deadline. By default, allowances expire 1 hour after they are
     *          granted, but this may be modified by the contract owner -- call `defaultAllowanceExpirationSec()`
     *          to get the current value.
     * @param v The ECDSA certificate `v` value.
     * @param r The ECDSA certificate `r` value.
     * @param s The ECDSA certificate `s` value.
     */
    function permit(address holder, address spender, uint256 amount, uint256 deadline,
            uint8 v, bytes32 r, bytes32 s) external eip2612 override(IEIP2612) {
            
        // Get and update nonce
        uint256 nonce = nonces[holder]++;
        
        // Check whether permit is valid (reverts if not)
        checkPermit(deadline,
                keccak256(abi.encode(EIP2612_PERMIT_TYPEHASH, holder, spender, amount, nonce, deadline)),
                v, r, s, /* requiredSigner = */ holder);
                
        // Approve amount allowed in the permit
        _approve(holder, spender, amount,
                // Use the default allowance expiration time
                defaultAllowanceExpirationTime(), "");
    }
}


// File contracts/main/Dublr/DublrInternal.sol


// The Dublr token (symbol: DUBLR), with a built-in distributed exchange for buying/selling tokens.
// By Hiroshi Yamamoto.
// 虎穴に入らずんば虎子を得ず。
//
// Officially hosted at: https://github.com/dublr/dublr

pragma solidity 0.8.15;

/**
 * @title DublrInternal
 * @dev Utility functions for the Dublr token and distributed exchange.
 * @author Hiroshi Yamamoto
 */
abstract contract DublrInternal is OmniToken {

    // -----------------------------------------------------------------------------------------------------------------
    // API enablement (needed in case a security issue is discovered with one of the APIs after the contract is created)

    /** @dev true if minting is enabled. */
    bool internal mintingEnabled = true;

    /** @dev true if buying is enabled on the built-in distributed exchange. */
    bool internal buyingEnabled = true;

    /** @dev true if selling is enabled on the built-in distributed exchange. */
    bool internal sellingEnabled = true;

    /** @dev The ETH value (in wei, == 10^-18 ETH) of the minimum sell order that may be listed for sale via `sell()`. */
    uint256 public minSellOrderValueETHWEI = 10000000000000000;   // == 0.01 ETH == US$10 equiv, if 1 ETH == US$1000

    /**
     * @notice Only callable by the owner/deployer of the contract.
     *
     * @dev Enable or disable minting.
     */
    function _owner_enableMinting(bool enable) external ownerOnly { mintingEnabled = enable; }

    /**
     * @notice Only callable by the owner/deployer of the contract.
     *
     * @dev Enable or disable selling on the built-in distributed exchange.
     */
    function _owner_enableSelling(bool enable) external ownerOnly { sellingEnabled = enable; }

    /**
     * @notice Only callable by the owner/deployer of the contract.
     *
     * @dev Enable or disable buying on the built-in distributed exchange.
     * `_owner_enableBuying(false)` disables buying but not minting, so `buy()` will still work
     * unless minting is also disabled.
     */
    function _owner_enableBuying(bool enable) external ownerOnly { buyingEnabled = enable; }

    /**
     * @notice Only callable by the owner/deployer of the contract.
     *
     * @dev Set the ETH value (in wei, == 10^-18 ETH) of the minimum sell order that may be listed for sale via
     * a call to `sell()`.
     */
    function _owner_setMinSellOrderValueETHWEI(uint256 value) external ownerOnly { minSellOrderValueETHWEI = value; }

    // -----------------------------------------------------------------------------------------------------------------
    // Constants

    /** @dev Mint price doubling period: 90 days. */
    uint256 internal constant DOUBLING_PERIOD_DAYS = 90;

    /** @dev Doublings per year = 4.05 ~= 4 => mint price increase factor per year = ~2^4 = ~16. */
    uint256 internal constant DOUBLING_PERIOD_SEC = DOUBLING_PERIOD_DAYS * 24 * 60 * 60;

    /**
     * @dev Num doubling periods: 30 (7.5 years * 4 doublings per year) => max mint price increase factor is
     * 2^30 = ~1B, although minting should end organically before then due to increased supply of sell orders
     * below the mint price. (See forward-looking statement disclaimer in README.md .)
     */
    uint256 internal constant NUM_DOUBLING_PERIODS = 30;

    /** @dev The number of seconds during which the mint price continues to double. */
    uint256 internal constant MAX_DOUBLING_TIME_SEC = DOUBLING_PERIOD_SEC * NUM_DOUBLING_PERIODS;

    /** @dev The value of 1 for fixed point calculation of number of doublings over time. */
    uint256 internal constant FIXED_POINT = 1 << 30;

    /** @dev The value of ln(2)*FIXED_POINT == ln(2)*(1<<30). */
    uint256 internal constant LN2_FIXED_POINT = 0x2c5c85fe;

    /**
     * @dev One minus the trading fee of 0.15%, = floor((1 - 0.0015) * (1 << 30)). ETH amount of an order is multiplied
     * by this to determine how much to send to sellers.
     */
    uint256 internal constant SELLER_PAYMENT_FRACTION_FIXED_POINT = 0x3FE76C8B;

    /**
     * @dev The maximum number of sell orders that can be bought at once, to prevent uncontrolled resource consumption
     * DoS attacks. See: https://swcregistry.io/docs/SWC-128
     */
    uint256 internal constant MAX_SELL_ORDERS_PER_BUY = 20;

    // -----------------------------------------------------------------------------------------------------------------
    // Minting values set by the constructor

    /** @dev The price of 1 DUBLR in ETH, times 1e9, when the constructor was called. */
    uint256 internal initialMintPriceETHPerDUBLR_x1e9;

    /** @dev The timestamp when the constructor was called. */
    uint256 internal initialMintTimestamp;

    // -----------------------------------------------------------------------------------------------------------------
    // The distributed exchange orderbook

    /** @dev An orderbook entry (for a sell order). */
    struct Order {
        address seller;
        uint256 timestamp;
        uint256 priceETHPerDUBLR_x1e9;
        uint256 amountDUBLRWEI;
    }

    /** @dev The heap (to enforce increasing order of price for orderbook entry removal). */
    Order[] internal orderBook;

    /**
     * @dev The order book: mapping from address to (heap index + 1) if there is a current active sell order
     * for this address in the heap. (Need to add one because heap storage starts at index 0, but zero values
     * cannot be disambiguated from non-existence in a mapping.)
     *
     * The use of this mapping guarantees O(log N) removal time for removing an order by address.
     *
     * This data structure only allows us to have zero orders or one order per address at any given time.
     * It would be significantly more complex to create an orderbook where each user can have multiple active
     * orders at any given time, and still keep all order book access to O(log N) time.
     */
    mapping(address => uint256) internal sellerToHeapIdxPlusOne;

    // -----------------------------------------------------------------------------------------------------------------
    // Orderbook heap management functions

    /**
     * @dev Compare two orderbook entries, first by price, then (as a tiebreaker) by timestamp.
     * This is used to ensure that the cheapest orders are sold first, and when there is a tie,
     * the oldest order is sold first. (Does not compare amount, only compares price and timestamp.)
     *
     * @return diff -1 if order0 < order1, 0 if order0 == order1, 1 if order0 > order1, according to
     *         the above criteria.
     */
    function compare(Order memory order0, Order memory order1) private pure returns (int diff) {
        return order0.priceETHPerDUBLR_x1e9 < order1.priceETHPerDUBLR_x1e9 ? int(-1)
               : order0.priceETHPerDUBLR_x1e9 > order1.priceETHPerDUBLR_x1e9 ? int(1)
               : order0.timestamp < order1.timestamp ? int(-1)
               : int(1);
    }

    /**
     * @dev Set an entry in the orderbook min-heap, also updating the seller-to-heap-index mapping
     * sellerToHeapIdxPlusOne[order.seller].
     *
     * @param heapIdx The position to set the order.
     * @param order The order to set at the position.
     */
    function setOrder(uint256 heapIdx, Order memory order) private {
        assert(heapIdx <= orderBook.length);  // Sanity check
        if (heapIdx == orderBook.length) {
            orderBook.push(order);
        } else {
            orderBook[heapIdx] = order;
        }
        sellerToHeapIdxPlusOne[order.seller] = heapIdx + 1;
    }

    /**
     * @dev Standard up-heap algorithm for moving an order up a heap into its correct position.
     * (Heap is a min-heap, ordered by priceETHPerDUBLR_x1e9, then by timestamp.)
     *
     * @param orderToMove The order to bubble up the heap
     * @param startHeapIdx The heap index to start bubbling up the heap from. (The order at this index
     * is ignored -- it is treated as a "hole".)
     */
    function upHeap(Order memory orderToMove, uint256 startHeapIdx) private {
        uint256 i = startHeapIdx;
        while (i > 0) {
            uint256 parentI;
            unchecked { parentI = (i - 1) / 2; }  // Save gas by using unchecked
            Order memory parentOrder = orderBook[parentI];
            if (compare(parentOrder, orderToMove) <= 0) {
                // Stop moving up heap once the parent order has a smaller value than the order to be inserted
                break;
            }
            // Move parent order down into position `i`, leaving a "hole" where the parent was
            setOrder(i, parentOrder);
            // Move up the heap
            i = parentI;
        }
        // Overwrite the "hole" at the final position with orderToMove
        setOrder(i, orderToMove);
    }

    /**
     * @dev Standard down-heap algorithm for moving an order down a heap into its correct position.
     * (Heap is a min-heap, ordered by priceETHPerDUBLR_x1e9, then by timestamp.)
     *
     * @param orderToMove The order to percolate down the heap
     * @param startHeapIdx The heap index to start percolating down the heap from. (The order at this index
     * is ignored -- it is treated as a "hole".)
     */
    function downHeap(Order memory orderToMove, uint256 startHeapIdx) private {
        uint256 i = startHeapIdx;
        while (true) {
            // Get the index of the left and right child
            uint256 leftI;
            unchecked { leftI = 2 * i + 1; }  // Save gas (it would be impossibly expensive to ever cause overflow)
            if (leftI >= orderBook.length) {
                // Stop when node has no children
                break;
            }
            uint256 rightI;
            unchecked { rightI = leftI + 1; }  // Save gas
            // Choose child with lower priceETHPerDUBLR_x1e9 (or older child, if children have same price)
            // -- this preserves the min-heap property relative to the other child, if the child with
            // a lower price or older order timestamp is moved up to the parent position
            uint256 smallerChildI = rightI < orderBook.length && compare(orderBook[rightI], orderBook[leftI]) < 0
                    ? rightI : leftI;
            Order memory smallerChildOrder = orderBook[smallerChildI];
            if (compare(orderToMove, smallerChildOrder) < 0) {
                // Stop when the correct insertion point for orderToMove is found
                break;
            }
            // Insertion point for orderToMove has not yet been found -- move child up into empty
            // parent position (this leaves child entry empty), as parent for next iteration)
            setOrder(i, smallerChildOrder);
            // Move to child entry
            i = smallerChildI;
        }
        // Overwrite the "hole" in the heap at the final position with orderToMove
        setOrder(i, orderToMove);
    }

    /**
     * @dev Insert a new sell order into the orderbook min-heap.
     *
     * @param order The sell order to insert into the heap.
     */
    function heapInsert(Order memory order) internal {
        // Insert order at the end of the heap, then bubble up into correct position
        upHeap(order, orderBook.length);
    }

    /**
     * @dev Remove an entry from the orderbook min-heap by index.
     *
     * (Min-heap is ordered by priceETHPerDUBLR_x1e9, then by timestamp.)
     *
     * @param heapIdx The index of the heap entry to remove and return.
     * @return removedOrder The order at the given heap index.
     */
    function heapRemove(uint256 heapIdx) internal returns (Order memory removedOrder) {
        assert(orderBook.length > 0 && heapIdx < orderBook.length);  // Sanity check
        // Set element to be removed as return value
        removedOrder = orderBook[heapIdx];
        // After removing this order, there are no other orders for the seller (sellers can have only one
        // sell order at a given time)
        delete sellerToHeapIdxPlusOne[removedOrder.seller];
        // Last element in heap must be inserted into the space vacated by deletion of removedOrder,
        // then moved into position via down-heap (percolate down) operation
        uint256 lastOrderIdx;
        unchecked { lastOrderIdx = orderBook.length - 1; }  // Checked by assert above
        Order memory lastOrder = orderBook[lastOrderIdx];
        // Remove lastOrder from the end of the array
        orderBook.pop();
        // if (heapIdx == lastOrderIdx), then removed order is at end of array (i.e. removedOrder == lastOrder)
        // -- just return the removed order
        if (heapIdx != lastOrderIdx) {
            // Otherwise determine whether lastOrder needs to be bubbled up the heap or percolated down the heap
            // from the hole vacated by removedOrder
            if (heapIdx > 0 && compare(lastOrder, orderBook[(heapIdx - 1) / 2]) < 0) {
                // removedOrder had a parent (wasn't the root node of the heap), and lastOrder has a value
                // less than removedOrder's parent's value, so run up-heap algorithm
                upHeap(lastOrder, heapIdx);
            } else {
                // Otherwise (if removedOrder was at the root of the heap or lastOrder has a value greater than
                // or equal to removedOrder's parent's value), then run down-heap algorithm
                downHeap(lastOrder, heapIdx);
            }
        }
    }

    // -----------------------------------------------------------------------------------------------------------------
    // Math functions
    
    /** @dev Return the minimum of two values. */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
    
    /** The fixed point multiplier for priceETHPerDUBLR_x1e9 prices (i.e. 1e9). */
    uint256 internal constant _1e9 = 1e9;
    
    /**
     * @dev Convert DUBLR to ETH, rounding up, then clamping the result to a given max value.
     *
     * @param priceETHPerDUBLR_x1e9 The price in ETH per DUBLR, multiplied by 1e9.
     * @param dublrAmt The amount of DUBLR to convert to ETH.
     * @param maxEthAmt The max amount of ETH to clamp the return value to.
     * @return equivEthAmt the ETH-equivalent value of dublrAmt at the given price.
     */
    function dublrToEthRoundUpClamped(uint256 priceETHPerDUBLR_x1e9, uint256 dublrAmt, uint256 maxEthAmt)
            internal pure returns (uint256 equivEthAmt) {
        uint256 ethAmt = (dublrAmt * priceETHPerDUBLR_x1e9 + _1e9 - 1) / _1e9;
        return ethAmt < maxEthAmt ? ethAmt : maxEthAmt;
    }
    
    /**
     * @dev Convert DUBLR to ETH, rounding down.
     *
     * @param priceETHPerDUBLR_x1e9 The price in ETH per DUBLR, multiplied by 1e9.
     * @param dublrAmt The amount of DUBLR to convert to ETH.
     * @return equivEthAmt the ETH-equivalent value of dublrAmt at the given price.
     */
    function dublrToEthRoundDown(uint256 priceETHPerDUBLR_x1e9, uint256 dublrAmt)
            internal pure returns (uint256 equivEthAmt) {
        return dublrAmt * priceETHPerDUBLR_x1e9 / _1e9;
    }
    
    /**
     * @dev Convert DUBLR to ETH, subtracting market maker fee, and rounding to nearest 1 ETH.
     *
     * @param priceETHPerDUBLR_x1e9 The price in ETH per DUBLR, multiplied by 1e9.
     * @param dublrAmt The amount of DUBLR to convert to ETH.
     * @return equivEthAmt the ETH-equivalent value of dublrAmt at the given price, less market maker fee.
     */
    function dublrToEthLessMarketMakerFee(uint256 priceETHPerDUBLR_x1e9, uint256 dublrAmt)
            internal pure returns (uint256 equivEthAmt) {
        // Round to nearest 1 ETH
        uint256 denom = _1e9 * FIXED_POINT;
        return (dublrAmt * priceETHPerDUBLR_x1e9 * SELLER_PAYMENT_FRACTION_FIXED_POINT + denom / 2) / denom;
    }
    
    /**
     * @dev Convert ETH to DUBLR, rounding down.
     *
     * @param priceETHPerDUBLR_x1e9 The price in ETH per DUBLR, multiplied by 1e9.
     * @param ethAmt The amount of ETH to convert to DUBLR.
     * @return equivDublrAmt the DUBLR-equivalent value of ethAmt at the given price.
     */
    function ethToDublrRoundDown(uint256 priceETHPerDUBLR_x1e9, uint256 ethAmt)
            internal pure returns (uint256 equivDublrAmt) {
        return ethAmt * _1e9 / priceETHPerDUBLR_x1e9;
    }
}


// File contracts/main/Dublr/interfaces/IDublrDEX.sol


// The Dublr token (symbol: DUBLR), with a built-in distributed exchange for buying/selling tokens.
// By Hiroshi Yamamoto.
// 虎穴に入らずんば虎子を得ず。
//
// Officially hosted at: https://github.com/dublr/dublr

pragma solidity 0.8.15;

/**
 * @title IDublrDex
 * @dev Dublr distributed exchange interface.
 * @author Hiroshi Yamamoto
 */
interface IDublrDEX {

    // -----------------------------------------------------------------------------------------------------------------
    // Events

    /**
     * @notice Emitted when a seller's tokens are listed for sale.
     *
     * @param seller The account of the seller of the listed tokens.
     * @param priceETHPerDUBLR_x1e9 The list price of the tokens, in ETH per DUBLR (multiplied by `10^9`).
     * @param amountDUBLRWEI The number of tokens listed for sale.
     */
    event ListSell(address indexed seller, uint256 priceETHPerDUBLR_x1e9, uint256 amountDUBLRWEI);

    /**
     * @notice Emitted when a sell order is canceled.
     *
     * @param seller The account of the token seller in the canceled listing.
     * @param priceETHPerDUBLR_x1e9 The price tokens were listed for, in ETH per DUBLR (multiplied by `10^9`).
     * @param amountDUBLRWEI The number of tokens that were listed for sale.
     */
    event CancelSell(address indexed seller, uint256 priceETHPerDUBLR_x1e9, uint256 amountDUBLRWEI);

    /**
     * @notice Emitted when the a sell order is partially or fully purchased by a buyer.
     *
     * @dev When amountRemainingInOrderDUBLR reaches 0, the sell order is removed from the orderbook.
     *
     * @param buyer The buyer account.
     * @param seller The seller account.
     * @param priceETHPerDUBLR_x1e9 The price tokens were listed for, in ETH per DUBLR (multiplied by `10^9`).
     * @param amountBoughtDUBLRWEI The number of DUBLR tokens (in DUBLR wei, where 1 DUBLR == `10^18` DUBLR wei)
     *          that were transferred from the seller to the buyer.
     * @param amountRemainingInOrderDUBLRWEI The number of DUBLR tokens (in DUBLR wei) remaining in the order.
     * @param amountSentToSellerETHWEI The amount of ETH (in wei) transferred from the buyer to the seller.
     * @param amountChargedToBuyerETHWEI The amount of ETH (in wei) charged to the buyer, including fees.
     */
    event Buy(address indexed buyer, address indexed seller,
            uint256 priceETHPerDUBLR_x1e9, uint256 amountBoughtDUBLRWEI, uint256 amountRemainingInOrderDUBLRWEI,
            uint256 amountSentToSellerETHWEI, uint256 amountChargedToBuyerETHWEI);

    /**
     * @notice Emitted when a buyer calls `buy()`, and there are no sell orders listed below the mint price,
     * leading to new tokens being minted for the buyer.
     *
     * @param buyer The account to mint tokens for.
     * @param priceETHPerDUBLR_x1e9 The current mint price, in ETH per DUBLR (multiplied by `10^9`).
     * @param amountSpentETHWEI The amount of ETH that was spent by the buyer to mint tokens.
     * @param amountMintedDUBLRWEI The number of tokens that were minted for the buyer.
     */
    event Mint(address indexed buyer, uint256 priceETHPerDUBLR_x1e9, uint256 amountSpentETHWEI,
            uint256 amountMintedDUBLRWEI);

    /**
     * @notice Emitted when 90% of the supplied buyer's ETH balance has been expended on buying sell orders
     */
    event OutOfGasForBuyingSellOrders(address indexed buyer, uint256 buyOrderRemainingETHWEI, uint256 totBoughtDUBLRWEI);

    /**
     * @notice Emitted to return any change to the buyer from a `buy()` call, where the provided ETH amount was
     * not a whole multiple of the token price.
     *
     * @param buyer The buyer account.
     * @param refundedETHWEI The amount of ETH (in wei) that was refunded to the buyer.
     */
    event RefundChange(address indexed buyer, uint256 refundedETHWEI);

    /**
     * @notice Emitted when an ETH payment could not be sent to a seller for any reason. These payments
     * are considered forfeited as per the documentation on the `sell(...)` function.
     *
     * @param seller The seller account to which an attempt was made to send an ETH payment.
     * @param amountETHWEI The amount of ETH (in wei) that the Dublr contract attempted to send.
     * @param data Any data returned by the failed payable call (may contain revert reason information).
     */
    event Unpayable(address indexed seller, uint256 amountETHWEI, bytes data);

    // -----------------------------------------------------------------------------------------------------------------
    // Public functions for interacting with order book

    /**
     * @notice The number of sell orders in the order book.
     *
     * @return numEntries The number of entries in the order book.
     */
    function orderBookSize() external view returns (uint256 numEntries);

    /**
     * @notice The price of the cheapest sell order in the order book for any user.
     *
     * @dev If there are no current sell orders, reverts.
     *
     * @return priceETHPerDUBLR_x1e9 The price of DUBLR tokens in the cheapest sell order, in ETH per DUBLR
     *          (multiplied by `10^9`).
     * @return amountDUBLRWEI the number of DUBLR tokens for sale, in DUBLR wei (1 DUBLR = 10^18 DUBLR wei).
     */
    function cheapestSellOrder() external view returns (uint256 priceETHPerDUBLR_x1e9, uint256 amountDUBLRWEI);

    /**
     * @notice The current sell order in the order book for the caller.
     *
     * @dev If the caller has no current sell order, reverts.
     *
     * @return priceETHPerDUBLR_x1e9 The price of DUBLR tokens in the caller's current sell order, in ETH per DUBLR
     *          (multiplied by `10^9`).
     * @return amountDUBLRWEI the number of DUBLR tokens for sale, in DUBLR wei (1 DUBLR = `10^18` DUBLR wei).
     */
    function mySellOrder() external view returns (uint256 priceETHPerDUBLR_x1e9, uint256 amountDUBLRWEI);

    /**
     * @notice Cancel the caller's current sell order in the orderbook.
     *
     * @dev Restores the amount of the caller's sell order back to the seller's token balance.
     *
     * If the caller has no current sell order, reverts.
     */
    function cancelMySellOrder() external;
    
    /**
     * @dev The price and amount of a sell order in the orderbook.
     *
     * @param priceETHPerDUBLR_x1e9 The price of DUBLR tokens in the caller's current sell order, in ETH per DUBLR
     *          (multiplied by `10^9`).
     * @param amountDUBLRWEI the number of DUBLR tokens for sale, in DUBLR wei (1 DUBLR = `10^18` DUBLR wei).
     */
    struct PriceAndAmount {
        // Tuples are not a first-class type in Solidity, so need to use a struct to return an array of tuples
        uint256 priceETHPerDUBLR_x1e9;
        uint256 amountDUBLRWEI;
    }

    /**
     * @notice Get all sell orders in the orderbook.
     * 
     * @dev Note that the orders are returned in min-heap order by price, and not in increasing order by price.
     *
     * @return priceAndAmountOfSellOrders A list of all sell orders in the orderbook, in min-heap order by price.
     * Each list item is a tuple consisting of the price of each token in ETH per DUBLR (multiplied by `10^9`),
     * and the number of tokens for sale.
     */
    function allSellOrders() external view
            // Returning an array requires ABI encoder v2, which is the default in Solidity >=0.8.0.
            returns (PriceAndAmount[] memory priceAndAmountOfSellOrders);

    // -----------------------------------------------------------------------------------------------------------------
    // Selling

    /** 
     * @notice List DUBLR tokens for sale in the orderbook.
     *
     * @dev List some amount of the caller's DUBLR token balance for sale. This may be canceled any time before the
     * tokens are purchased by a buyer. If tokens from the order are bought by a buyer, the ETH value of the purchased
     * tokens are sent to the seller, minus a market maker fee of 0.15%.
     *
     * During the time that tokens are listed for sale, the amount of the sell order is deducted from the token
     * balance of the seller, to prevent double-spending. The amount is returned to the seller's token balance if
     * the sell order is later canceled.
     *
     * If there is already a sell order in the order book for this sender, then that old order is automatically
     * canceled before the new order is placed (there may only be one order per seller in the order book at one
     * time).
     *
     * Note that the equivalent ETH amount of the order must be at least `minSellOrderValueETHWEI`, to ensure
     * that the order size is not unreasonably small (small orders cost buyers a lot of gas relative to the number
     * of tokens they buy). The equivalent ETH amount of the order can be calculated as:
     * `uint256 amountETHWEI = amountDUBLRWEI * priceETHPerDUBLR_x1e9 / 1e9` . If `amountETHWEI` is not at least
     * `minSellOrderValueETHWEI`, then the transaction will revert with "Order value too small".
     *
     * @notice Because payment for the sale of tokens is sent to the seller when the tokens are sold, the seller
     * account must be able to receive ETH payments. In other words, the seller account must either be a non-contract
     * wallet (an Externally-Owned Account or EOA), or a contract that implements one of the payable `receive()`
     * or `fallback()` functions, in order to receive payment. If sending ETH to the seller fails because the
     * seller account is a non-payable contract, then the ETH from the sale of tokens is forfeited.
     *
     * @notice By calling this function, you confirm that the Dublr token is not considered an unregistered or illegal
     * security, and that the Dublr smart contract is not considered an unregistered or illegal exchange, by
     * the laws of any legal jurisdiction in which you hold or use the Dublr token.
     * 
     * @notice In some jurisdictions, such as the United States, any use, transfer, or sale of a token is a taxable
     * event. It is your responsibility to record the purchase price and sale price in ETH or your local currency
     * equivalent for each use, transfer, or sale of DUBLR tokens you own, and to pay the taxes due.
     *
     * @notice The creator of Dublr makes no claims, guarantees, or promises, express or implied, about the
     * profitability, utility, fitness for any purpose, or redeemability for fiat value of any purchased DUBLR tokens.
     * By purchasing DUBLR tokens, you assume all liability and risk, and you agree to all conditions in the Legal
     * Agreement and Disclaimers for Dublr and OmniToken: https://github.com/dublr/dublr/blob/main/LEGAL.md
     *
     * @param priceETHPerDUBLR_x1e9 the price to list the tokens for sale at, in ETH per DUBLR token, multiplied
     *          by `10^9`.
     * @param amountDUBLRWEI the number of DUBLR tokens to sell, in units of DUBLR wei (1 DUBLR == `10^18` DUBLR wei).
     *          Must be less than or equal to the caller's balance. Additionally,
     *          `amountETHWEI = amountDUBLRWEI * priceETHPerDUBLR_x1e9 / 1e9` must be greater than the
     *          ETH value of gas supplied to run the function, to ensure the order size is not tiny.
     */
    function sell(uint256 priceETHPerDUBLR_x1e9, uint256 amountDUBLRWEI) external;
    
    // -----------------------------------------------------------------------------------------------------------------
    // Buying

    /**
     * @notice Buy the cheapest DUBLR tokens available, for the equivalent value of the ETH `payableAmount`/`value`
     * sent with the transaction.
     *
     * @dev A payable function that exchanges the ETH value attached to the transaction for DUBLR tokens.
     *
     * Buys tokens listed for sale, if any sell orders are listed below the mint price and `allowBuying == true`.
     * Sell orders are purchased in increasing order of price, until the supplied ETH amount runs out or the mint price
     * is reached. Then this function will mint new tokens at the current mint price with the remaining ETH balance, if
     * `allowMinting == true`, increasing total supply.
     *
     * At least `minimumTokensToBuyOrMintDUBLRWEI` DUBLR tokens must be either purchased from sell orders or minted,
     * otherwise the transaction will revert with "Too much slippage". You can determine how many coins you expect
     * to receive for a given ETH payable amount, by examining the order book (call `allSellOrders()` to get all
     * orderbook entries, and then sort them in increasing order of price).
     *
     * A maximum of 90% of the supplied gas may be used to buy sell orders from the built-in DEX (to prevent
     * gas exhaustion DoS attacks). If this gas limit is reached, buying will stop with the order partially filled,
     * an `OutOfGasForBuyingSellOrders` event will be emitted to signify that the order was only partially filled,
     * the unspent ETH balance will be returned to the buyer, and a `RefundChange` event will be emitted to inform
     * the buyer of the refund. (Note that `minimumTokensToBuyOrMintDUBLRWEI` tokens must still be bought in this
     * partially-filled order, otherwise the transaction will instead revert with "Out of gas".)
     *
     * Change is also refunded to the buyer if the buyer sends an ETH amount that is not a whole multiple of the token
     * price, and a `RefundChange` event is emitted. The buyer must be able to receive refunded ETH payments for the
     * `buy()` function to succed: the buyer account must either be a non-contract wallet (an EOA), or a contract
     * that implements one of the payable `receive()` or `fallback()` functions to receive payment.
     *
     * @notice By calling this function, you confirm that the Dublr token is not considered an unregistered or illegal
     * security, and that the Dublr smart contract is not considered an unregistered or illegal exchange, by
     * the laws of any legal jurisdiction in which you hold or use the Dublr token.
     * 
     * @notice In some jurisdictions, such as the United States, any use, transfer, or sale of a token is a taxable
     * event. It is your responsibility to record the purchase price and sale price in ETH or your local currency
     * equivalent for each use, transfer, or sale of DUBLR tokens you own, and to pay the taxes due.
     *
     * @notice The creator of Dublr makes no claims, guarantees, or promises, express or implied, about the
     * profitability, utility, fitness for any purpose, or redeemability for fiat value of any purchased DUBLR tokens.
     * By purchasing DUBLR tokens, you assume all liability and risk, and you agree to all conditions in the Legal
     * Agreement and Disclaimers for Dublr and OmniToken: https://github.com/dublr/dublr/blob/main/LEGAL.md
     *
     * @param minimumTokensToBuyOrMintDUBLRWEI The minimum number of tokens (in DUBLR wei, i.e. 10^-18 DUBLR) that the
     *      provided (payable) ETH value should buy, in order to prevent slippage. If at least this total number is not
     *      bought or minted by the time all ETH funds of the transaction have been expended, then the transaction is
     *      reverted and the full provided ETH amount is refunded (minus gas spent, since this is not refundable).
     *      This mechanism attempts to protect the user from any drastic and unfavorable price changes while their
     *      transaction is pending.
     * @param allowBuying If `true`, allow the buying of any tokens listed for sale below the mint price.
     * @param allowMinting If `true`, allow the minting of new tokens at the current mint price.
     */
    function buy(uint256 minimumTokensToBuyOrMintDUBLRWEI, bool allowBuying, bool allowMinting) external payable;
}


// File contracts/main/Dublr/Dublr.sol


// The Dublr token (symbol: DUBLR), with a built-in distributed exchange for buying/selling tokens.
// By Hiroshi Yamamoto.
// 虎穴に入らずんば虎子を得ず。
//
// Officially hosted at: https://github.com/dublr/dublr

pragma solidity 0.8.15;


/**
 * @title Dublr
 * @dev The Dublr token and distributed exchange
 * @author Hiroshi Yamamoto
 */
contract Dublr is DublrInternal, IDublrDEX {

    // -----------------------------------------------------------------------------------------------------------------
    // Constructor

    /**
     * @dev Constructor.
     * @param initialMintPrice_ETHPerDUBLR_x1e9 the numerator of the initial price of DUBLR in
     *          ETH per DUBLR token, multiplied by 1e9 (as a fixed point representation).
     * @param initialMintAmountDUBLR the one-time number of DUBLR tokens to mint for the owner on creation
     *          of the contract.
     */
    constructor(uint256 initialMintPrice_ETHPerDUBLR_x1e9, uint256 initialMintAmountDUBLR)
            OmniToken("Dublr", "DUBLR", "1", new address[](0), initialMintAmountDUBLR) {
        require(initialMintPrice_ETHPerDUBLR_x1e9 > 0, "Zero price");
        
        // Record timestamp and initial mint price at contract creation time
        initialMintPriceETHPerDUBLR_x1e9 = initialMintPrice_ETHPerDUBLR_x1e9;
        // solhint-disable-next-line not-rely-on-time
        initialMintTimestamp = block.timestamp;

        // Register DUBLR token via ERC1820
        registerInterfaceViaERC1820("DUBLRToken", true);
        
        // Register IDublrDEX interface via ERC165
        registerInterfaceViaERC165(type(IDublrDEX).interfaceId, true);
    }

    // -----------------------------------------------------------------------------------------------------------------
    // Determine the current mint price, based on block timestamp

    /**
     * @notice The current mint price, in ETH per DUBLR (multiplied by `10^9`).
     *
     * @dev Returns the current mint price for this token. Calls to `buy()` will buy tokens for sale
     * rather than minting new tokens, if there are tokens listed below the current mint price.
     *
     * The mint price grows exponentially, doubling every 90 days for 30 doubling periods, and then minting
     * is disabled. In practice, minting may no longer be triggered long before that time, if the supply
     * of coins for sale below the mint price exceeds demand.
     *
     * @return mintPriceETHPerDUBLR_x1e9 The current mint price, in ETH per DUBLR, multiplied by `10^9`,
     *              or zero if the minting time period has ended (after 30 doubling periods).
     */
    function mintPrice() public view returns (uint256 mintPriceETHPerDUBLR_x1e9) {
        // This is only a polynomial approximation of 2^t, so the doubling is not quite precise.
        // Factor increase in mint price during 1st doubling period: 1.999528
        // Factor increase in mint price during 30th doubling period: 1.973042
        // Factor increase in mint price between initial mint price and price after 30th
        //     doubling period: 871819739 (0.87 billion, i.e. 19% less than 1<<30)

        // N.B. daily compound interest rate == exp(ln(2) / DOUBLING_PERIOD_DAYS)
        // == 1.00773 if DOUBLING_PERIOD_DAYS == 90 (compound interest rate is 0.77% per day)

        // Use the block timestamp as an estimate of the current time. It is possible for miners to spoof
        // this timestamp, but it must be greater than the parent block timestamp (according to the Ethereum
        // yellowpaper), and most clients reject timestamps more than 15 seconds in the future.
        // The mint price grows by only 0.77% per day, so adding 15 seconds won't change the value of the
        // mint price by much (up to 0.003%). Also, setting the timestamp ahead of the real time results
        // in a higher price, which is only disadvantageous for a would-be attacker. Therefore, using the
        // block timestamp is not problematic here.
        // solhint-disable-next-line not-rely-on-time
        uint256 t = block.timestamp - initialMintTimestamp;
        if (t > MAX_DOUBLING_TIME_SEC) {
            return 0;
        }

        // Given an exponential function that doubles as x increments by 1
        //
        //     p = 2**x
        //
        // then to rewrite this in base e, we have
        //
        //     p = e**(ln(2) x)
        //
        // since
        //
        //     e**y = 2  =>  y == ln(2)
        //
        // Therefore the factor increase in mint price since the contract was deployed is given by
        //
        //     p = e**(ln(2) t / DOUBLING_PERIOD_SEC)
        //
        // where t is time since the constructor was called, in seconds.
        //
        // Exponentiation may be approximated by a polynomial:
        //
        //     exp(x) = lim{n->inf} (1 + x/n)**n
        //
        // (we use n = 1024 for a reasonable approximation that is not too costly).
        //
        // The factor increase in price can therefore be approximated by
        //
        //     p = (1 + ln(2) t / DOUBLING_PERIOD_SEC)**1024
        //
        // This approximation is accurate to within 3% per doubling period, with the biggest error
        // at the latest (30th) doubling period.
        
        // Convert the value (ln(2) * t / DOUBLING_PERIOD_SEC) to fixed point
        uint256 x = LN2_FIXED_POINT * t / DOUBLING_PERIOD_SEC;
        // x = 1 + x/1024
        x = FIXED_POINT + x / 1024;
        // x = x**1024
        // Obtained via 10 iterations, since x**(2**10) == x**1024
        for (uint256 i = 0; i < 10; ) {
            // slither-disable-next-line divide-before-multiply
            x = x * x / FIXED_POINT;
            unchecked { ++i; }  // Save gas
        }
        // x is now an estimate of p, the factor increase in price, in fixed point.
        // Multiply x by the initial mint price to get the current mint price in fixed point,
        // then convert back from fixed point
        return x * initialMintPriceETHPerDUBLR_x1e9 / FIXED_POINT;
    }
    
    // -----------------------------------------------------------------------------------------------------------------
    // Public functions for interacting with order book

    /**
     * @notice The number of sell orders in the order book.
     *
     * @return numEntries The number of entries in the order book.
     */
    function orderBookSize() external view override(IDublrDEX) returns (uint256 numEntries) {
        return orderBook.length;
    }

    /**
     * @notice The price of the cheapest sell order in the order book for any user.
     *
     * @dev If there are no current sell orders, reverts.
     *
     * @return priceETHPerDUBLR_x1e9 The price of DUBLR tokens in the cheapest sell order, in ETH per DUBLR
     *          (multiplied by `10^9`).
     * @return amountDUBLRWEI the number of DUBLR tokens for sale, in DUBLR wei (1 DUBLR = 10^18 DUBLR wei).
     */
    function cheapestSellOrder() external view override(IDublrDEX)
            returns (uint256 priceETHPerDUBLR_x1e9, uint256 amountDUBLRWEI) {
        require(orderBook.length > 0, "No sell order");
        Order storage order = orderBook[0];
        return (order.priceETHPerDUBLR_x1e9, order.amountDUBLRWEI);
    }

    /**
     * @notice The current sell order in the order book for the caller.
     *
     * @dev If the caller has no current sell order, reverts.
     *
     * @return priceETHPerDUBLR_x1e9 The price of DUBLR tokens in the caller's current sell order, in ETH per DUBLR
     *          (multiplied by `10^9`).
     * @return amountDUBLRWEI the number of DUBLR tokens for sale, in DUBLR wei (1 DUBLR = `10^18` DUBLR wei).
     */
    function mySellOrder() external view override(IDublrDEX)
            returns (uint256 priceETHPerDUBLR_x1e9, uint256 amountDUBLRWEI) {
        uint256 heapIdxPlusOne = sellerToHeapIdxPlusOne[msg.sender];
        require(heapIdxPlusOne > 0, "No sell order");
        uint256 heapIdx;
        unchecked { heapIdx = heapIdxPlusOne - 1; }  // Save gas
        
        // Peek at the order in the heap without removing it
        Order storage order = orderBook[heapIdx];
        assert(order.seller == msg.sender);  // Sanity check
        
        return (order.priceETHPerDUBLR_x1e9, order.amountDUBLRWEI);
    }

    /**
     * @notice Cancel the caller's current sell order in the orderbook.
     *
     * @dev Restores the remaining (unfulfilled) amount of the caller's sell order back to the seller's
     * token balance. If the caller has no current sell order, reverts.
     */
    function cancelMySellOrder() public override(IDublrDEX)
            // Modified with stateUpdater for reentrancy protection
            stateUpdater {
        // Determine the heap index of the sender's current sell order, if any
        uint256 heapIdxPlusOne = sellerToHeapIdxPlusOne[msg.sender];
        require(heapIdxPlusOne > 0, "No sell order");
        uint256 heapIdx;
        unchecked { heapIdx = heapIdxPlusOne - 1; }  // Save gas

        // Remove the order from the heap
        Order memory order = heapRemove(heapIdx);
        assert(order.seller == msg.sender);  // Sanity check

        // Add the order amount of the canceled sell order back into the seller's balance
        balanceOf[order.seller] += order.amountDUBLRWEI;

        emit CancelSell(order.seller, order.priceETHPerDUBLR_x1e9, order.amountDUBLRWEI);
    }

    /**
     * @notice Get all sell orders in the orderbook.
     * 
     * @dev Note that the orders are returned in min-heap order by price, and not in increasing order by price.
     *
     * @return priceAndAmountOfSellOrders A list of all sell orders in the orderbook, in min-heap order by price.
     * Each list item is a tuple consisting of the price of each token in ETH per DUBLR (multiplied by `10^9`),
     * and the number of tokens for sale.
     */
    function allSellOrders() external view override(IDublrDEX)
            // Returning an array requires ABI encoder v2, which is the default in Solidity >=0.8.0.
            returns (PriceAndAmount[] memory priceAndAmountOfSellOrders) {
        require(orderBook.length > 0, "No sell order");
        priceAndAmountOfSellOrders = new PriceAndAmount[](orderBook.length);
        uint256 len = orderBook.length;
        for (uint256 i = 0; i < len; ) {
            Order storage order = orderBook[i];
            priceAndAmountOfSellOrders[i] = PriceAndAmount({
                    priceETHPerDUBLR_x1e9: order.priceETHPerDUBLR_x1e9,
                    amountDUBLRWEI: order.amountDUBLRWEI});
            unchecked { ++i; }  // Save gas
        }
    }

    /**
     * @notice Only callable by the owner/deployer of the contract.
     *
     * @dev Cancel all sell orders (in case of emergency).
     * Restores the remaining (unfulfilled) amount of each sell order back to the respective seller's token balance.
     */
    function _owner_cancelAllSellOrders() external
            // Modified with stateUpdater for reentrancy protection
            stateUpdater ownerOnly {
        while (orderBook.length > 0) {
            uint256 heapIdx;
            unchecked { heapIdx = orderBook.length - 1; }  // Save gas
            Order storage order = orderBook[heapIdx];
            balanceOf[order.seller] += order.amountDUBLRWEI;
            delete sellerToHeapIdxPlusOne[order.seller];
            orderBook.pop();
            emit CancelSell(order.seller, order.priceETHPerDUBLR_x1e9, order.amountDUBLRWEI);
        }
    }

    // -----------------------------------------------------------------------------------------------------------------
    // Selling

    /** 
     * @notice List DUBLR tokens for sale in the orderbook.
     *
     * @dev List some amount of the caller's DUBLR token balance for sale. This may be canceled any time before the
     * tokens are purchased by a buyer. If tokens from the order are bought by a buyer, the ETH value of the purchased
     * tokens are sent to the seller, minus a market maker fee of 0.15%.
     *
     * During the time that tokens are listed for sale, the amount of the sell order is deducted from the token
     * balance of the seller, to prevent double-spending. The amount is returned to the seller's token balance if
     * the sell order is later canceled.
     *
     * If there is already a sell order in the order book for this sender, then that old order is automatically
     * canceled before the new order is placed (there may only be one order per seller in the order book at one
     * time).
     *
     * Note that the equivalent ETH amount of the order must be at least `minSellOrderValueETHWEI`, to ensure
     * that the order size is not unreasonably small (small orders cost buyers a lot of gas relative to the number
     * of tokens they buy). The equivalent ETH amount of the order can be calculated as:
     * `uint256 amountETHWEI = amountDUBLRWEI * priceETHPerDUBLR_x1e9 / 1e9` . If `amountETHWEI` is not at least
     * `minSellOrderValueETHWEI`, then the transaction will revert with "Order value too small".
     *
     * @notice Because payment for the sale of tokens is sent to the seller when the tokens are sold, the seller
     * account must be able to receive ETH payments. In other words, the seller account must either be a non-contract
     * wallet (an Externally-Owned Account or EOA), or a contract that implements one of the payable `receive()`
     * or `fallback()` functions, in order to receive payment. If sending ETH to the seller fails because the
     * seller account is a non-payable contract, then the ETH from the sale of tokens is forfeited.
     *
     * @notice By calling this function, you confirm that the Dublr token is not considered an unregistered or illegal
     * security, and that the Dublr smart contract is not considered an unregistered or illegal exchange, by
     * the laws of any legal jurisdiction in which you hold or use the Dublr token.
     * 
     * @notice In some jurisdictions, such as the United States, any use, transfer, or sale of a token is a taxable
     * event. It is your responsibility to record the purchase price and sale price in ETH or your local currency
     * equivalent for each use, transfer, or sale of DUBLR tokens you own, and to pay the taxes due.
     *
     * @notice The creator of Dublr makes no claims, guarantees, or promises, express or implied, about the
     * profitability, utility, fitness for any purpose, or redeemability for fiat value of any purchased DUBLR tokens.
     * By purchasing DUBLR tokens, you assume all liability and risk, and you agree to all conditions in the Legal
     * Agreement and Disclaimers for Dublr and OmniToken: https://github.com/dublr/dublr/blob/main/LEGAL.md
     *
     * @param priceETHPerDUBLR_x1e9 the price to list the tokens for sale at, in ETH per DUBLR token, multiplied
     *          by `10^9`.
     * @param amountDUBLRWEI the number of DUBLR tokens to sell, in units of DUBLR wei (1 DUBLR == `10^18` DUBLR wei).
     *          Must be less than or equal to the caller's balance. Additionally,
     *          `amountETHWEI = amountDUBLRWEI * priceETHPerDUBLR_x1e9 / 1e9` must be greater than the
     *          ETH value of gas supplied to run the function, to ensure the order size is not tiny.
     */
    function sell(uint256 priceETHPerDUBLR_x1e9, uint256 amountDUBLRWEI) external override(IDublrDEX)
            // Modified with stateUpdater for reentrancy protection
            stateUpdater {
        require(sellingEnabled, "Selling disabled");
        require(priceETHPerDUBLR_x1e9 > 0 && amountDUBLRWEI > 0, "Bad arg");

        // To mitigate DoS attacks, we have to prevent sellers from listing lots of very small sell orders from different
        // addresses, by making it costly to do this. We require that the total amount of the sell order in ETH be greater
        // than a specified minimum amount.
        require(dublrToEthRoundDown(priceETHPerDUBLR_x1e9, amountDUBLRWEI) >= minSellOrderValueETHWEI,
                "Order value too small");

        // Cancel existing order, if there is one, before placing new sell order
        address seller = msg.sender;
        uint256 heapIdxPlusOne = sellerToHeapIdxPlusOne[seller];
        if (heapIdxPlusOne > 0) {
            cancelMySellOrder();
        }

        // Remove sell amount from sender's balance, to prevent spending of amount while order is in orderbook
        // (this amount will be restored to account balance if order is canceled)
        require(amountDUBLRWEI <= balanceOf[seller], "Insufficient balance");
        unchecked { balanceOf[seller] -= amountDUBLRWEI; }  // Save gas by using unchecked

        // Add sell order to heap
        heapInsert(Order({
                seller: msg.sender,
                // solhint-disable-next-line not-rely-on-time
                timestamp: block.timestamp,
                priceETHPerDUBLR_x1e9: priceETHPerDUBLR_x1e9,
                amountDUBLRWEI: amountDUBLRWEI}));

        emit ListSell(seller, priceETHPerDUBLR_x1e9, amountDUBLRWEI);
    }

    // -----------------------------------------------------------------------------------------------------------------
    // Buying

    /** @dev The amount of change to give to a seller. */
    struct SellerPayment {
        address seller;
        uint256 amountETHWEI;
    } 

    /**
     * @dev Amount in ETH to send to sellers. This will be cleared at the end of each buy() call, it is only
     * held in storage rather than memory because Solidity does not support dynamic arrays in memory.
     */
    SellerPayment[] private amountToSendToSellers;

    /**
     * @dev Buy sell orders and then mint new tokens. Updates state of the contract, but does not call external
     * contracts (i.e. does not call `sendETH`).
     *
     * @param minimumTokensToBuyOrMintDUBLRWEI The minimum number of tokens (in DUBLR wei, i.e. 10^-18 DUBLR) that the
     *      provided (payable) ETH value should buy, in order to prevent slippage. If at least this total number is not
     *      bought or minted by the time all ETH funds of the transaction have been expended, then the transaction is
     *      reverted and the full provided ETH amount is refunded (minus gas spent, since this is not refundable).
     *      This mechanism attempts to protect the user from any drastic and unfavorable price changes while their
     *      transaction is pending.
     * @param allowBuying If `true`, allow the buying of any tokens listed for sale below the mint price.
     * @param allowMinting If `true`, allow the minting of new tokens at the current mint price.
     * @return amountToRefundToBuyerETHWEI The amount of ETH to refund to the buyer.
     * @return amountToSendToSellersCopy The amount(s) of ETH to send to the sellers.
     */
    function _buy_stateUpdater(uint256 minimumTokensToBuyOrMintDUBLRWEI, bool allowBuying, bool allowMinting)
            // Modified with stateUpdater for reentrancy protection
            private stateUpdater
            returns (uint256 amountToRefundToBuyerETHWEI, SellerPayment[] memory amountToSendToSellersCopy) {
        uint256 initialGas = gasleft();

        // Up to 70% of the gas can be used for buying sell orders, leaving a minimum of 30% of the gas for
        // the rest of this function, including minting. (Buying sell orders is an expensive operation, since
        // it can involve manipulating the heap, potentially removing the root node of the heap for many
        // separate sell orders.)
        // Buying sell orders will terminate when the amount of gas remaining falls below buySellOrderMinGasLimit,
        // to prevent a DoS (gas exhaustion) attack on the exchange. Instead, if the remaining gas falls below
        // this limit, buying of sell orders will stop, and an OutOfGasForBuyingSellOrders event will be emitted.
        // The transaction may still revert if the provided gas is simply too low to run this function.
        uint256 buySellOrdersMinGasLimit = initialGas * 3 / 10;

        // The buyer is the caller
        address buyer = msg.sender;

        // Get the ETH value sent to this function in units of ETH wei
        uint256 buyOrderRemainingETHWEI = msg.value;

        // Keep track of total tokens bought or minted
        uint256 totBoughtOrMintedDUBLRWEI = 0;

        // Calculate the mint price -- the price is 0 if minting has finished
        // (MAX_DOUBLING_TIME_SEC seconds or more after contract deployment, mintPrice() will return 0)
        uint256 mintPriceETHPerDUBLR_x1e9 = mintPrice();

        // Amount of ETH to refund to (buyer, and amounts to send to sellers at end of transaction
        amountToRefundToBuyerETHWEI = 0;  // Return param
        assert(amountToSendToSellers.length == 0);  // Sanity check

        // Buying sell orders: -----------------------------------------------------------------------------------------

        bool ranOutOfGasForBuyingSellOrders = false;
        bool skipMinting = false;
        while (
                // If buyingEnabled is false (set by owner) or allowBuying is false (set by caller), skip over the
                // buying stage. This allows exchange function to be shut down or disabled if necessary without
                // affecting minting.
                buyingEnabled && allowBuying
                // Iterate through orders in increasing order of priceETHPerDUBLR_x1e9, until we run out of ETH,
                // or until we run out of orders.
                && buyOrderRemainingETHWEI > 0 && orderBook.length > 0) {

            // Find the lowest-priced order (this is a memory copy, because heapRemove(0) may be called below)
            Order memory sellOrder = orderBook[0];

            // Stop iterating through sell orders once the order price is above the current mint price.
            if (mintPriceETHPerDUBLR_x1e9 > 0
                    && sellOrder.priceETHPerDUBLR_x1e9 > mintPriceETHPerDUBLR_x1e9) {
                break;
            }
            
            // Calculate number of tokens to buy, and the price including fees: ----------------------------------------

            uint256 amountToBuyDUBLRWEI;
            {
                // Determine how many whole DUBLR can be purchased with the buyer's remaining ETH balance,
                // at the current price of this order. (Whole DUBLR => round down.)
                uint256 amountBuyerCanAffordAtSellOrderPrice_asDUBLRWEI =
                        ethToDublrRoundDown(sellOrder.priceETHPerDUBLR_x1e9, buyOrderRemainingETHWEI);

                if (amountBuyerCanAffordAtSellOrderPrice_asDUBLRWEI == 0) {
                    // The amount of DUBLR that the buyer can afford at the sell order price is less than 1 token,
                    // so the buyer can't continue buying orders (order prices in the rest of the order book, and
                    // the mint price, have to be at least as high as the current price). Stop going through order
                    // book, and refunded remaining ETH balance to the buyer as change.
                    // The minting price must be higher than the current order, so minting will not be
                    // triggered either.
                    skipMinting = true;
                    break;
                }

                // The number of DUBLR tokens to buy from the sell order is the minimum of the order's
                // amountDUBLRWEI (it's only possible to buy a maximum of amountDUBLRWEI tokens from this
                // order) and amountBuyerCanAffordAtSellOrderPrice_asDUBLRWEI (the buyer can't buy more
                // tokensthan they can afford)
                amountToBuyDUBLRWEI = min(sellOrder.amountDUBLRWEI, amountBuyerCanAffordAtSellOrderPrice_asDUBLRWEI);
            }

            // Given the whole number of DUBLR tokens to be purchased, calculate the ETH amount to charge buyer,
            // and deduct the market maker fee from the amount to send the seller.
            // Round up amount to charge buyer and round down amount to send seller to nearest 1 ETH wei.
            uint256 amountToChargeBuyerETHWEI = dublrToEthRoundUpClamped(
                    sellOrder.priceETHPerDUBLR_x1e9, amountToBuyDUBLRWEI,
                    // Clamping shouldn't be needed, but to guarantee safe rounding up,
                    // clamp amount to available balance
                    buyOrderRemainingETHWEI);
            // Invariant: amountToChargeBuyerETHWEI <= buyOrderRemainingETHWEI

            // Convert the number of DUBLR tokens bought into an ETH balance to send to seller, after subtracting
            // the trading fee.
            uint256 amountToSendToSellerETHWEI =
                    dublrToEthLessMarketMakerFee(sellOrder.priceETHPerDUBLR_x1e9, amountToBuyDUBLRWEI);

            // Transfer DUBLR from sell order to buyer: ----------------------------------------------------------------

            // Subtract the DUBLR amount from the seller's order balance
            // (modify `orderBook[0]` in storage, not the `sellOrder` copy in memory)
            uint256 sellOrderRemainingDUBLRWEI =
                    // Note that the following expression has a side effect: `-=`. The orderbook entry's
                    // remaining amount is modified in-place. The corresponding field of the in-memory copy,
                    // `sellOrder.amountDUBLRWEI`, is not used below the following line, so it doesn't matter
                    // that the storage version and the in-memory copy differ after this point.
                    (orderBook[0].amountDUBLRWEI -= amountToBuyDUBLRWEI);
                    
            // Remove `orderBook[0]` from the orderbook when its remaining balance reaches zero
            if (sellOrderRemainingDUBLRWEI == 0) {
                heapRemove(0);
            }
            
            // Deposit the DUBLR amount into the buyer's account
            balanceOf[buyer] += amountToBuyDUBLRWEI;

            // Keep track of total tokens bought or minted
            totBoughtOrMintedDUBLRWEI += amountToBuyDUBLRWEI;

            // Transfer ETH from buyer to seller: ----------------------------------------------------------------------

            // Record the amount of ETH to be sent to the seller (there may be several sellers involved in one buy)
            if (amountToSendToSellerETHWEI > 0) {
                amountToSendToSellers.push(
                        SellerPayment({seller: sellOrder.seller, amountETHWEI: amountToSendToSellerETHWEI}));
            }

            // Deduct from the remaining ETH balance of buyer's buy order
            unchecked { buyOrderRemainingETHWEI -= amountToChargeBuyerETHWEI; }  // Save gas (see invariant above)
            
            // Fees to send to owner: ----------------------------------------------------------------------------------
            
            // Fees to send to owner are (amountToChargeBuyerETHWEI - amountToSendToSellerETHWEI).
            // We don't need to actually calculate this or store it anywhere, because we can calculate how much ETH is
            // left over from `msg.value` after sellers have been paid and buyer has received change.

            // Emit Dublr Buy event
            emit Buy(buyer, sellOrder.seller,
                    sellOrder.priceETHPerDUBLR_x1e9, amountToBuyDUBLRWEI,
                    sellOrderRemainingDUBLRWEI, amountToSendToSellerETHWEI, amountToChargeBuyerETHWEI);

            if (gasleft() < buySellOrdersMinGasLimit) {
                // Ran out of gas for buying sell orders --  prevent uncontrolled resource consumption DoS attacks.
                // See: https://swcregistry.io/docs/SWC-128

                // Record that we ran out of gas so we can revert with an appropriate message if necessary                
                ranOutOfGasForBuyingSellOrders = true;

                // Emit event
                emit OutOfGasForBuyingSellOrders(buyer, buyOrderRemainingETHWEI, totBoughtOrMintedDUBLRWEI);
                
                // Stop processing sell orders, and also do not fall through to minting (since there may be a big
                // jump in price between the current order's sell price and the mint price). The remaining ETH
                // balance must be refunded as-is.
                skipMinting = true;
                break;
            }
        }

        // Minting: ----------------------------------------------------------------------------------------------------

        // If the buyer's ETH balance is still greater than zero after there are no more sell orders below the
        // mint price, switch to minting
        if (
            // Only mint if minting is enabled by owner and is allowed by the caller
            mintingEnabled && allowMinting && !skipMinting
            // If mint price is 0, then the minting period has finished
            && mintPriceETHPerDUBLR_x1e9 > 0
            // Only mint if there is a remaining ETH balance
            && buyOrderRemainingETHWEI > 0) {

            // Mint DUBLR tokens into buyer's account: -----------------------------------------------------------------

            // Convert the amount remaining of the buy order from ETH to DUBLR.
            // Round down to the nearest whole DUBLR wei.
            uint256 amountToMintDUBLRWEI = ethToDublrRoundDown(
                    mintPriceETHPerDUBLR_x1e9, buyOrderRemainingETHWEI);
                    
            // Convert the whole number of DUBLR wei to mint back into ETH wei to spend on minting.
            // Round up to the nearest 1 ETH wei.
            uint256 amountToMintETHWEI = dublrToEthRoundUpClamped(
                    mintPriceETHPerDUBLR_x1e9, amountToMintDUBLRWEI,
                    // Clamping shouldn't be needed, but to guarantee safe rounding up,
                    // clamp amount to available balance
                    buyOrderRemainingETHWEI);
            // Invariant: amountToMintETHWEI <= buyOrderRemainingETHWEI

            // Only mint if the number of DUBLR tokens to mint is at least 1
            if (amountToMintDUBLRWEI > 0) {
                // Mint this number of DUBLR tokens for buyer (msg.sender).
                // Call the `_mint_stateUpdater` version rather than the `_mint` version to ensure that the minting function
                // cannot call out to external contracts, so that Checks-Effects-Interactions is followed (since
                // we're still updating state).
                _mint_stateUpdater(buyer, buyer, amountToMintDUBLRWEI, "", "");

                // Keep track of total tokens bought or minted
                totBoughtOrMintedDUBLRWEI += amountToMintDUBLRWEI;

                // Emit Dublr Mint event (provides more useful info than other mint events)
                emit Mint(buyer, mintPriceETHPerDUBLR_x1e9, amountToMintETHWEI, amountToMintDUBLRWEI);
            }

            // Refund change to buyer for any fractional remainder (ETH worth less than 1 DUBLR): ----------------------

            // Calculate how much change to give for the last fractional ETH value that is worth less than 1 DUBLR
            // (amountToMintETHWEI is clamped above to a max of buyOrderRemainingETHWEI)
            unchecked { buyOrderRemainingETHWEI -= amountToMintETHWEI; }  // Save gas (see invariant above)
        }
        
        // Refund unspent balance: -------------------------------------------------------------------------------------
        
        // If the remaining ETH balance is greater than zero, it could not all be spent -- refund to buyer
        if (buyOrderRemainingETHWEI > 0) {
            amountToRefundToBuyerETHWEI += buyOrderRemainingETHWEI;
            // Emit RefundChange event
            emit RefundChange(buyer, buyOrderRemainingETHWEI);
            // All remaining ETH is used up.
            buyOrderRemainingETHWEI = 0;
        }
        
        // Protect against slippage: -----------------------------------------------------------------------------------
        
        // Require that the number of tokens bought or minted met or exceeded the minimum purchase amount
        require(totBoughtOrMintedDUBLRWEI >= minimumTokensToBuyOrMintDUBLRWEI,
                // If buyer ran out of gas for buying sell orders, then this should be reported rather than that
                // there was too much slippage.
                ranOutOfGasForBuyingSellOrders ? "Out of gas" : "Too much slippage");

        // Finalize state: ---------------------------------------------------------------------------------------------

        // In order to prevent the opportunity for reentrancy attacks, a copy of the amountToSendToSellers array
        // is made in order to ensure amountToSendToSellers is emptied before any sendETH call to external contracts
        // (otherwise looping through the amountToSendToSellers array to send payments to sellers would mix state
        // updates with calling external contracts, breaking the Checks-Effects-Interactions pattern).
        uint256 numSellers = amountToSendToSellers.length;
        amountToSendToSellersCopy = new SellerPayment[](numSellers);  // Return param
        for (uint256 i = 0; i < numSellers; ) {
            amountToSendToSellersCopy[i] = amountToSendToSellers[i];
            unchecked { ++i; }  // Save gas
        }
        delete amountToSendToSellers;  // Clear storage array, so that it is always clear at the end of buy()
    }

    /**
     * @notice Buy the cheapest DUBLR tokens available, for the equivalent value of the ETH `payableAmount`/`value`
     * sent with the transaction.
     *
     * @dev A payable function that exchanges the ETH value attached to the transaction for DUBLR tokens.
     *
     * Buys tokens listed for sale, if any sell orders are listed below the mint price and `allowBuying == true`.
     * Sell orders are purchased in increasing order of price, until the supplied ETH amount runs out or the mint price
     * is reached. Then this function will mint new tokens at the current mint price with the remaining ETH balance, if
     * `allowMinting == true`, increasing total supply.
     *
     * At least `minimumTokensToBuyOrMintDUBLRWEI` DUBLR tokens must be either purchased from sell orders or minted,
     * otherwise the transaction will revert with "Too much slippage". You can determine how many coins you expect
     * to receive for a given ETH payable amount, by examining the order book (call `allSellOrders()` to get all
     * orderbook entries, and then sort them in increasing order of price).
     *
     * A maximum of 70% of the supplied gas may be used to buy sell orders from the built-in DEX (to prevent
     * gas exhaustion DoS attacks). If this gas limit is reached, buying will stop with the order partially filled,
     * an `OutOfGasForBuyingSellOrders` event will be emitted to signify that the order was only partially filled,
     * the unspent ETH balance will be returned to the buyer, and a `RefundChange` event will be emitted to inform
     * the buyer of the refund. (Note that `minimumTokensToBuyOrMintDUBLRWEI` tokens must still be bought in this
     * partially-filled order, otherwise the transaction will instead revert with "Out of gas".)
     * The transaction may also revert with gas exhaustion if the provided gas is simply too low to run this function.
     *
     * Change is also refunded to the buyer if the buyer sends an ETH amount that is not a whole multiple of the token
     * price, and a `RefundChange` event is emitted. The buyer must be able to receive refunded ETH payments for the
     * `buy()` function to succed: the buyer account must either be a non-contract wallet (an EOA), or a contract
     * that implements one of the payable `receive()` or `fallback()` functions to receive payment.
     *
     * @notice By calling this function, you confirm that the Dublr token is not considered an unregistered or illegal
     * security, and that the Dublr smart contract is not considered an unregistered or illegal exchange, by
     * the laws of any legal jurisdiction in which you hold or use the Dublr token.
     * 
     * @notice In some jurisdictions, such as the United States, any use, transfer, or sale of a token is a taxable
     * event. It is your responsibility to record the purchase price and sale price in ETH or your local currency
     * equivalent for each use, transfer, or sale of DUBLR tokens you own, and to pay the taxes due.
     *
     * @notice The creator of Dublr makes no claims, guarantees, or promises, express or implied, about the
     * profitability, utility, fitness for any purpose, or redeemability for fiat value of any purchased DUBLR tokens.
     * By purchasing DUBLR tokens, you assume all liability and risk, and you agree to all conditions in the Legal
     * Agreement and Disclaimers for Dublr and OmniToken: https://github.com/dublr/dublr/blob/main/LEGAL.md
     *
     * @param minimumTokensToBuyOrMintDUBLRWEI The minimum number of tokens (in DUBLR wei, i.e. 10^-18 DUBLR) that the
     *      provided (payable) ETH value should buy, in order to prevent slippage. If at least this total number is not
     *      bought or minted by the time all ETH funds of the transaction have been expended, then the transaction is
     *      reverted and the full provided ETH amount is refunded (minus gas spent, since this is not refundable).
     *      This mechanism attempts to protect the user from any drastic and unfavorable price changes while their
     *      transaction is pending.
     * @param allowBuying If `true`, allow the buying of any tokens listed for sale below the mint price.
     * @param allowMinting If `true`, allow the minting of new tokens at the current mint price.
     */
    function buy(uint256 minimumTokensToBuyOrMintDUBLRWEI, bool allowBuying, bool allowMinting)
            public payable override(IDublrDEX) {

        require(msg.value > 0, "Zero payment");

        // CHECKS / EFFECTS / EVENTS:
        
        (uint256 amountToRefundToBuyerETHWEI, SellerPayment[] memory amountToSendToSellersCopy) =
                _buy_stateUpdater(minimumTokensToBuyOrMintDUBLRWEI, allowBuying, allowMinting);

        // INTERACTIONS:

        // Transfer ETH from buyer to seller, and ETH fees to owner (`sendETH` is an `extCaller` function)
        
        // Send any pending ETH payments to sellers
        uint256 totalSentToSellersAndBuyerETHWEI = 0;
        uint256 numSellers = amountToSendToSellersCopy.length;
        for (uint256 i = 0; i < numSellers; ) {
            SellerPayment memory sellerPayment = amountToSendToSellersCopy[i];
            // By attempting to send with `errorMessageOnFail == ""`, if sending fails, then instead of reverting,
            // sendETH will return false. We need to catch this case, because otherwise, a seller could execute
            // a DoS on the DEX by refusing to accept ETH payments, since every buy attempt would fail. Due to
            // Checks-Effects-Interactions, we can't go back at this point and just cancel the seller's order
            // -- all state has to have already been finalized. We also can't cancel the buy order, because
            // this is not the buyer's fault. Therefore, it is the seller's responsibility to ensure that they
            // can receive ETH payments, and as noted in the documentation for the `sell` function, if they
            // can't or won't accept ETH payment, they forfeit the payment.
            (bool success, bytes memory returnData) =
                    sendETH(sellerPayment.seller, sellerPayment.amountETHWEI, /* errorMessageOnFail = */ "");
            if (success) {
                // sellerPayment.amountETHWEI was sent to seller
                totalSentToSellersAndBuyerETHWEI += sellerPayment.amountETHWEI;
            } else {
                // if (!success), then payment is forfeited and sent to owner, because seller does not accept
                // ETH, and we must prevent seller from being able to attack the exchange by causing all `buy()`
                // calls to revert. Log this case.
                // (Disable Slither static analyzer warning, there is no way to emit this event before all
                // external function calls are made)
                // slither-disable-next-line reentrancy-events
                emit Unpayable(sellerPayment.seller, sellerPayment.amountETHWEI, returnData);
            }
            unchecked { ++i; }  // Save gas
        }
        
        // Refund any unspent ETH back to buyer. Reverts if the buyer does not accept payment. (This is different than
        // the behavior when a seller does not accept payment, because a buyer not accepting payment cannot
        // shut down the whole exchange.)
        sendETH(/* buyer = */ msg.sender, amountToRefundToBuyerETHWEI, "Can't refund change");
        totalSentToSellersAndBuyerETHWEI += amountToRefundToBuyerETHWEI;
        
        // Send any remaining ETH (trading fees + minting fees) to owner
        sendETH(_owner, address(this).balance, "Can't pay owner");
    }
}