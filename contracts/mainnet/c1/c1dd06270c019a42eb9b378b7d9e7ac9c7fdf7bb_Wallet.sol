/**
 *Submitted for verification at Etherscan.io on 2022-05-10
*/

//SPDX-License-Identifier: MIT

// File interfaces/IDelegator.sol

pragma solidity >=0.7.5;

interface IDelegator {
    /// Tells how much the delegator is charging for the delegated call in wei.
    function fee(uint256 gasUsed) external view returns (uint256);

    /// Returns the minimum gas needed for an execution.
    function minimumBalance() external view returns (uint256);
}

// File @openzeppelin/contracts/token/ERC20/[email protected]

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

// File interfaces/IWallet.sol

interface IWallet {
    /// Emitted when the owner delegates ownership to another address.
    event Delegation(address from, address to, uint256 value);

    /// Emitted when a delegateee has executed a function for a given user.
    event Execution(address owner, address caller, address target, uint256 fee);

    /// Emitted when the balance changes for a given address.
    event Balance(address owner, uint256 value);

    // MARK: - Methods

    struct ExecuteParams {
        /// Address of the target contract.
        address target;
        /// Execution parameters passed to the target contract.
        bytes data;
        /// List of tokens that should be available in the execution environment.
        ExecutionToken[] tokens;
        /// Ethereum sent to the executed contract.
        uint256 value;
    }

    struct ExecutionToken {
        /// Address of the token contract.
        IERC20 token;
        /// Amount of tokens to transfer.
        uint256 amount;
    }

    /// Lets a delegated executor execute a transaction.
    function execute(address from, ExecuteParams calldata params) external returns (bytes memory result);

    /// Tells how much ether the delegator may use.
    function allowance(address owner, address delegatee) external view returns (uint256);
}

// File @uniswap/v3-periphery/contracts/libraries/[email protected]

library TransferHelper {
    /// @notice Transfers tokens from the targeted address to the given destination
    /// @notice Errors with 'STF' if transfer fails
    /// @param token The contract address of the token to be transferred
    /// @param from The originating address from which the tokens will be transferred
    /// @param to The destination address of the transfer
    /// @param value The amount to be transferred
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value)
        );
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'STF');
    }

    /// @notice Transfers tokens from msg.sender to a recipient
    /// @dev Errors with ST if transfer fails
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'ST');
    }

    /// @notice Approves the stipulated contract to spend the given allowance in the given token
    /// @dev Errors with 'SA' if transfer fails
    /// @param token The contract address of the token to be approved
    /// @param to The target of the approval
    /// @param value The amount of the given token the target will be allowed to spend
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.approve.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'SA');
    }

    /// @notice Transfers ETH to the recipient address
    /// @dev Fails with `STE`
    /// @param to The destination of the transfer
    /// @param value The value to be transferred
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'STE');
    }
}

// File contracts/Wallet.sol

/**
Wallet is a smart contract that acts as a proxy wallet.
Only the owner of the funds can delegate the processing of those funds
to another smart contract and withdraw the funds.

Only ETH actually needs to be deposited, for trading ERC20 tokens, they 
need to be approved to the Wallet. The ETH must be paid in any case, 
at least enough to pay for gas and fees. Only ETH must be delegated furher, 
to another smart contract.
 */
contract Wallet is IWallet {
    /// Balances of ETH for each holder.
    mapping(address => uint256) private balances;

    // Dictionary of delegated addresses where the first index represents
    // the wallet giving the permission and the second one the wallet
    // receiving the permission and the value tells how much funds
    // the delegator may use.
    mapping(address => mapping(address => uint256)) private allowances;

    // MARK: - Constructor

    constructor() IWallet() {}

    // MARK: - Admin Functions

    /// Lets a physical wallet take back the funds from the smart contract.
    function withdraw(uint256 amount) external {
        require(msg.sender == tx.origin, 'Only physical wallet can withdraw.');

        // Check if the transaction sender has enough tokens.
        // If `require`'s first argument evaluates to `false` then the
        // transaction will revert.
        require(balances[tx.origin] >= amount, 'Not enough ETH.');

        // Transfer the amount.
        balances[tx.origin] -= amount;
        payable(tx.origin).transfer(amount);
    }

    /// Lets physical wallet top-up the funds on its wallet proxy.
    receive() external payable {
        require(msg.sender == tx.origin, 'Only physical wallet can deposit.');

        balances[tx.origin] += msg.value;
        emit Balance(tx.origin, balances[tx.origin]);
    }

    /// Delegates the usage of funds to another address.
    function delegate(address spender, uint256 amount) external {
        require(msg.sender == tx.origin, 'Only physical wallet can delegate.');

        allowances[tx.origin][spender] = amount;
        emit Delegation(tx.origin, spender, amount);
    }

    // MARK: - User Functions

    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }

    /// Tells the amount owner has to delegated to the given address.
    function allowance(address owner, address delegatee) external view override returns (uint256) {
        return allowances[owner][delegatee];
    }

    // MARK: - Delegation

    /// Lets a delegated executor execute a transaction.
    /// - NOTE: The sender of the executed transaction is the wallet, not the
    ///         contract executing the `execute` function.
    /// - NOTE: The function should use all tokens or return them to the owner.
    function execute(address from, ExecuteParams calldata params) external override returns (bytes memory result) {
        IDelegator delegator = IDelegator(msg.sender);

        // If the person wants to use 1ETH, he should also have ETH for paying gas,
        // that's why we add the amount to the minimumBalance.
        uint256 minimumBalance = delegator.minimumBalance() + params.value;
        require(allowances[from][msg.sender] >= minimumBalance, 'Not delegated!');
        require(balances[from] >= minimumBalance, 'Balance too low!');

        uint256 initialGas = gasleft();

        {
            // Transfer tokens and funds to the proxy contract so that the called function
            // may access them in the call environment.
            for (uint256 index = 0; index < params.tokens.length; index++) {
                ExecutionToken memory ext = params.tokens[index];

                TransferHelper.safeTransferFrom(address(ext.token), from, address(this), ext.amount);

                // We approve the tokens to the target contract so that they
                // can use them while executing the function (e.g. when calling
                // Uniswap, we approve tokens to the Uniswap contract).
                TransferHelper.safeApprove(address(ext.token), params.target, ext.amount);
            }
        }

        // Execute call to given contract.
        (bool success, bytes memory res) = params.target.call{value: params.value}(params.data);
        require(success, 'Contract call failed.');

        {
            // Return remaining ERC20 tokens back to the owner.
            for (uint256 index = 0; index < params.tokens.length; index++) {
                ExecutionToken memory ext = params.tokens[index];

                TransferHelper.safeTransferFrom(
                    address(ext.token),
                    address(this),
                    from,
                    ext.token.balanceOf(address(this))
                );
            }
        }

        {
            // Take fee for the execution and send it to the caller.
            uint256 gasUsed = initialGas - gasleft();
            uint256 fee = delegator.fee(gasUsed) + gasUsed * tx.gasprice;

            // Because Solidity 0.8.0 has built-in overflow protection, we don't need to check for overflow.
            allowances[from][msg.sender] -= fee;

            balances[from] -= fee;
            emit Balance(from, balances[from]);

            // It's important that we send the funds as the last action to prevent reentrancy attacks.
            payable(tx.origin).transfer(fee);

            emit Execution(from, msg.sender, params.target, fee);
        }

        return res;
    }
}