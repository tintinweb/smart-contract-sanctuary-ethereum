/**
 *Submitted for verification at Etherscan.io on 2022-12-13
*/

// Sources flattened with hardhat v2.9.9 https://hardhat.org

// File lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol

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


// File src/base/ErrorMessages.sol

pragma solidity >=0.8.4;

/// @notice An error used to indicate that an argument passed to a function is illegal or
///         inappropriate.
///
/// @param message The error message.
error IllegalArgument(string message);

/// @notice An error used to indicate that a function has encountered an unrecoverable state.
///
/// @param message The error message.
error IllegalState(string message);

/// @notice An error used to indicate that an operation is unsupported.
///
/// @param message The error message.
error UnsupportedOperation(string message);

/// @notice An error used to indicate that a message sender tried to execute a privileged function.
///
/// @param message The error message.
error Unauthorized(string message);


// File src/base/MutexLock.sol

pragma solidity 0.8.13;

/// @title  Mutex
/// @author Alchemix Finance
///
/// @notice Provides a mutual exclusion lock for implementing contracts.
abstract contract MutexLock {
    enum State {
        RESERVED,
        UNLOCKED,
        LOCKED
    }

    /// @notice The lock state.
    State private _lockState = State.UNLOCKED;

    /// @dev A modifier which acquires the mutex.
    modifier lock() {
        _claimLock();

        _;

        _freeLock();
    }

    /// @dev Gets if the mutex is locked.
    ///
    /// @return if the mutex is locked.
    function _isLocked() internal view returns (bool) {
        return _lockState == State.LOCKED;
    }

    /// @dev Claims the lock. If the lock is already claimed, then this will revert.
    function _claimLock() internal {
        // Check that the lock has not been claimed yet.
        if (_lockState != State.UNLOCKED) {
            revert IllegalState("Lock already claimed");
        }

        // Claim the lock.
        _lockState = State.LOCKED;
    }

    /// @dev Frees the lock.
    function _freeLock() internal {
        _lockState = State.UNLOCKED;
    }
}


// File src/interfaces/IERC20Metadata.sol

pragma solidity >=0.5.0;

/// @title  IERC20Metadata
/// @author Alchemix Finance
interface IERC20Metadata {
    /// @notice Gets the name of the token.
    ///
    /// @return The name.
    function name() external view returns (string memory);

    /// @notice Gets the symbol of the token.
    ///
    /// @return The symbol.
    function symbol() external view returns (string memory);

    /// @notice Gets the number of decimals that the token has.
    ///
    /// @return The number of decimals.
    function decimals() external view returns (uint8);
}


// File src/libraries/SafeERC20.sol

pragma solidity >=0.8.4;

/// @title  SafeERC20
/// @author Alchemix Finance
library SafeERC20 {
    /// @notice An error used to indicate that a call to an ERC20 contract failed.
    ///
    /// @param target  The target address.
    /// @param success If the call to the token was a success.
    /// @param data    The resulting data from the call. This is error data when the call was not a
    ///                success. Otherwise, this is malformed data when the call was a success.
    error ERC20CallFailed(address target, bool success, bytes data);

    /// @dev A safe function to get the decimals of an ERC20 token.
    ///
    /// @dev Reverts with a {CallFailed} error if execution of the query fails or returns an
    ///      unexpected value.
    ///
    /// @param token The target token.
    ///
    /// @return The amount of decimals of the token.
    function expectDecimals(address token) internal view returns (uint8) {
        (bool success, bytes memory data) = token.staticcall(
            abi.encodeWithSelector(IERC20Metadata.decimals.selector)
        );

        if (!success || data.length < 32) {
            revert ERC20CallFailed(token, success, data);
        }

        return abi.decode(data, (uint8));
    }

    /// @dev Transfers tokens to another address.
    ///
    /// @dev Reverts with a {CallFailed} error if execution of the transfer failed or returns an
    ///      unexpected value.
    ///
    /// @param token     The token to transfer.
    /// @param recipient The address of the recipient.
    /// @param amount    The amount of tokens to transfer.
    function safeTransfer(address token, address recipient, uint256 amount) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(IERC20.transfer.selector, recipient, amount)
        );

        if (!success || (data.length != 0 && !abi.decode(data, (bool)))) {
            revert ERC20CallFailed(token, success, data);
        }
    }

    /// @dev Approves tokens for the smart contract.
    ///
    /// @dev Reverts with a {CallFailed} error if execution of the approval fails or returns an
    ///      unexpected value.
    ///
    /// @param token   The token to approve.
    /// @param spender The contract to spend the tokens.
    /// @param value   The amount of tokens to approve.
    function safeApprove(address token, address spender, uint256 value) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(IERC20.approve.selector, spender, value)
        );

        if (!success || (data.length != 0 && !abi.decode(data, (bool)))) {
            revert ERC20CallFailed(token, success, data);
        }
    }

    /// @dev Transfer tokens from one address to another address.
    ///
    /// @dev Reverts with a {CallFailed} error if execution of the transfer fails or returns an
    ///      unexpected value.
    ///
    /// @param token     The token to transfer.
    /// @param owner     The address of the owner.
    /// @param recipient The address of the recipient.
    /// @param amount    The amount of tokens to transfer.
    function safeTransferFrom(address token, address owner, address recipient, uint256 amount) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(IERC20.transferFrom.selector, owner, recipient, amount)
        );

        if (!success || (data.length != 0 && !abi.decode(data, (bool)))) {
            revert ERC20CallFailed(token, success, data);
        }
    }
}


// File src/interfaces/external/chainlink/IChainlinkOracle.sol

pragma solidity >= 0.6.6;

interface IChainlinkOracle {
  function latestAnswer() external view returns (int256);
  function latestTimestamp() external view returns (uint256);
  function latestRound() external view returns (uint256);
  function getAnswer(uint256 roundId) external view returns (int256);
  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);
  event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
}


// File src/interfaces/ITokenAdapter.sol

pragma solidity >=0.5.0;

/// @title  ITokenAdapter
/// @author Alchemix Finance
interface ITokenAdapter {
    /// @notice Gets the current version.
    ///
    /// @return The version.
    function version() external view returns (string memory);

    /// @notice Gets the address of the yield token that this adapter supports.
    ///
    /// @return The address of the yield token.
    function token() external view returns (address);

    /// @notice Gets the address of the underlying token that the yield token wraps.
    ///
    /// @return The address of the underlying token.
    function underlyingToken() external view returns (address);

    /// @notice Gets the number of underlying tokens that a single whole yield token is redeemable
    ///         for.
    ///
    /// @return The price.
    function price() external view returns (uint256);

    /// @notice Wraps `amount` underlying tokens into the yield token.
    ///
    /// @param amount    The amount of the underlying token to wrap.
    /// @param recipient The address which will receive the yield tokens.
    ///
    /// @return amountYieldTokens The amount of yield tokens minted to `recipient`.
    function wrap(uint256 amount, address recipient)
        external
        returns (uint256 amountYieldTokens);

    /// @notice Unwraps `amount` yield tokens into the underlying token.
    ///
    /// @param amount    The amount of yield-tokens to redeem.
    /// @param recipient The recipient of the resulting underlying-tokens.
    ///
    /// @return amountUnderlyingTokens The amount of underlying tokens unwrapped to `recipient`.
    function unwrap(uint256 amount, address recipient)
        external
        returns (uint256 amountUnderlyingTokens);
}


// File src/interfaces/external/IWETH9.sol

pragma solidity >=0.5.0;

/// @title IWETH9
interface IWETH9 is IERC20, IERC20Metadata {
  /// @notice Deposits `msg.value` ethereum into the contract and mints `msg.value` tokens.
  function deposit() external payable;

  /// @notice Burns `amount` tokens to retrieve `amount` ethereum from the contract.
  ///
  /// @dev This version of WETH utilizes the `transfer` function which hard codes the amount of gas
  ///      that is allowed to be utilized to be exactly 2300 when receiving ethereum.
  ///
  /// @param amount The amount of tokens to burn.
  function withdraw(uint256 amount) external;
}


// File src/interfaces/external/curve/IStableSwap2Pool.sol

pragma solidity >=0.5.0;

uint256 constant N_COINS = 2;

interface IStableSwap2Pool {
    function coins(uint256 index) external view returns (address);

    function A() external view returns (uint256);

    function get_virtual_price() external view returns (uint256);

    function calc_token_amount(
        uint256[N_COINS] calldata amounts,
        bool deposit
    ) external view returns (uint256 amount);

    function add_liquidity(uint256[N_COINS] calldata amounts, uint256 minimumMintAmount) external;

    function get_dy(int128 i, int128 j, uint256 dx) external view returns (uint256 dy);

    function get_dy_underlying(int128 i, int128 j, uint256 dx) external view returns (uint256 dy);

    function exchange(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 minimumDy
    ) external payable returns (uint256);

    function remove_liquidity(uint256 amount, uint256[N_COINS] calldata minimumAmounts) external;

    function remove_liquidity_imbalance(
        uint256[N_COINS] calldata amounts,
        uint256 maximumBurnAmount
    ) external;

    function calc_withdraw_one_coin(uint256 tokenAmount, int128 i) external view returns (uint256);

    function remove_liquidity_one_coin(
        uint256 tokenAmount,
        int128 i,
        uint256 minimumAmount
    ) external;
}


// File src/interfaces/external/lido/IStETH.sol

pragma solidity >=0.5.0;

interface IStETH is IERC20 {
    function sharesOf(address account) external view returns (uint256);
    function getPooledEthByShares(uint256 sharesAmount) external view returns (uint256);
    function submit(address referral) external payable returns (uint256);
}


// File src/interfaces/external/lido/IWstETH.sol

pragma solidity >=0.5.0;

interface IWstETH is IERC20 {
    function getWstETHByStETH(uint256 amount) external view returns (uint256);
    function getStETHByWstETH(uint256 amount) external view returns (uint256);
    function wrap(uint256 amount) external returns (uint256);
    function unwrap(uint256 amount) external returns (uint256);
}


// File src/adapters/lido/WstETHAdapterV1.sol

pragma solidity 0.8.13;







struct InitializationParams {
    address alchemist;
    address token;
    address parentToken;
    address underlyingToken;
    address curvePool;
    address oracleStethUsd;
    address oracleEthUsd;
    uint256 ethPoolIndex;
    uint256 stEthPoolIndex;
    address referral;
}

contract WstETHAdapterV1 is ITokenAdapter, MutexLock {
    string public override version = "1.1.0";

    address public immutable alchemist;
    address public immutable override token;
    address public immutable parentToken;
    address public immutable override underlyingToken;
    address public immutable curvePool;
    address public immutable oracleStethUsd;
    address public immutable oracleEthUsd;
    uint256 public immutable ethPoolIndex;
    uint256 public immutable stEthPoolIndex;
    address public immutable referral;

    constructor(InitializationParams memory params) {
        alchemist       = params.alchemist;
        token           = params.token;
        parentToken     = params.parentToken;
        underlyingToken = params.underlyingToken;
        curvePool       = params.curvePool;
        oracleStethUsd  = params.oracleStethUsd;
        oracleEthUsd    = params.oracleEthUsd;
        ethPoolIndex    = params.ethPoolIndex;
        stEthPoolIndex  = params.stEthPoolIndex;
        referral        = params.referral;

        // Verify and make sure that the provided ETH matches the curve pool ETH.
        if (
            IStableSwap2Pool(params.curvePool).coins(params.ethPoolIndex) !=
            0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE
        ) {
            revert IllegalArgument("Curve pool ETH token mismatch");
        }

        // Verify and make sure that the provided stETH matches the curve pool stETH.
        if (
            IStableSwap2Pool(params.curvePool).coins(params.stEthPoolIndex) !=
            params.parentToken
        ) {
            revert IllegalArgument("Curve pool stETH token mismatch");
        }
    }

    /// @dev Checks that the message sender is the alchemist that the adapter is bound to.
    modifier onlyAlchemist() {
        if (msg.sender != alchemist) {
            revert Unauthorized("Not alchemist");
        }
        _;
    }

    receive() external payable {
        if (msg.sender != underlyingToken && msg.sender != curvePool) {
            revert Unauthorized("Payments only permitted from WETH or curve pool");
        }
    }

    /// @inheritdoc ITokenAdapter
    function price() external view returns (uint256) {
        uint256 stethToEth = uint256(IChainlinkOracle(oracleStethUsd).latestAnswer()) * 1e18 / uint256(IChainlinkOracle(oracleEthUsd).latestAnswer());

        // stETH is capped at 1 ETH
        if (stethToEth > 1e18) stethToEth = 1e18;

        return IWstETH(token).getStETHByWstETH(10**SafeERC20.expectDecimals(token)) * stethToEth / 1e18;
    }

    /// @inheritdoc ITokenAdapter
    function wrap(
        uint256 amount,
        address recipient
    ) external lock onlyAlchemist returns (uint256) {
        // Transfer the tokens from the message sender.
        SafeERC20.safeTransferFrom(underlyingToken, msg.sender, address(this), amount);

        // Unwrap the WETH into ETH.
        IWETH9(underlyingToken).withdraw(amount);

        // Wrap the ETH into stETH.
        uint256 startingStEthBalance = IERC20(parentToken).balanceOf(address(this));

        IStETH(parentToken).submit{value: amount}(referral);

        uint256 mintedStEth = IERC20(parentToken).balanceOf(address(this)) - startingStEthBalance;

        // Wrap the stETH into wstETH.
        SafeERC20.safeApprove(parentToken, address(token), mintedStEth);
        uint256 mintedWstEth = IWstETH(token).wrap(mintedStEth);

        // Transfer the minted wstETH to the recipient.
        SafeERC20.safeTransfer(token, recipient, mintedWstEth);

        return mintedWstEth;
    }

    // @inheritdoc ITokenAdapter
    function unwrap(
        uint256 amount,
        address recipient
    ) external lock onlyAlchemist returns (uint256) {
        // Transfer the tokens from the message sender.
        SafeERC20.safeTransferFrom(token, msg.sender, address(this), amount);

        // Unwrap the wstETH into stETH.
        uint256 startingStEthBalance = IStETH(parentToken).balanceOf(address(this));
        IWstETH(token).unwrap(amount);
        uint256 endingStEthBalance = IStETH(parentToken).balanceOf(address(this));

        // Approve the curve pool to transfer the tokens.
        uint256 unwrappedStEth = endingStEthBalance - startingStEthBalance;
        SafeERC20.safeApprove(parentToken, curvePool, unwrappedStEth);

        // Exchange the stETH for ETH. We do not check the curve pool because it is an immutable
        // contract and we expect that its output is reliable.
        uint256 received = IStableSwap2Pool(curvePool).exchange(
            int128(uint128(stEthPoolIndex)), // Why are we here, just to suffer?
            int128(uint128(ethPoolIndex)),   //                       (╥﹏╥)
            unwrappedStEth,
            0                                // <- Slippage is handled upstream
        );

        // Wrap the ETH that we received from the exchange.
        IWETH9(underlyingToken).deposit{value: received}();

        // Transfer the tokens to the recipient.
        SafeERC20.safeTransfer(underlyingToken, recipient, received);

        return received;
    }
}