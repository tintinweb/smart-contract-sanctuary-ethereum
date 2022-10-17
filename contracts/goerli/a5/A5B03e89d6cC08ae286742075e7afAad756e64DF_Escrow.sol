// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

error Escrow__EtherSentMustEqualAmount(uint256 etherSent, uint256 amount);
error Escrow__AmountMustBeAboveZero();
error Escrow__DurationMustBeAboveZero();
error Escrow__ToAddressMustNotBeZero();

error Escrow__DepositIsStillLocked(uint256 releaseTime);
error Escrow__DepositDoesNotExist();
error Escrow__MsgSenderIsNotDepositReceiver();

/**
 * @title Escrow
 * @author github.com/dindonero
 * @notice A contract that holds funds until a release time.
 */
contract Escrow {
    struct EscrowDeposit {
        address to;
        address token;
        uint256 amount;
        uint256 releaseTime;
    }

    // Events
    event Deposit(
        uint256 indexed depositId,
        address indexed depositor,
        address indexed to,
        address token,
        uint256 amount,
        uint256 releaseTime
    );
    event Withdrawal(address indexed receiver, uint256 indexed amount);

    // Local Variables
    // tokenAddress -> userAddress -> EscrowDeposit
    mapping(uint256 => EscrowDeposit) private s_deposits;

    uint256 private s_depositCounter = 0;

    /**
     * @notice Creates a new deposit that it not released until the release time.
     * @dev To create a ETH deposit, set token to address(0).
     * @dev The token must have been approved to this contract prior to its execution by each user.
     * @param to The address that will receive the funds.
     * @param token The address of the token to deposit.
     * @param amount The amount of tokens to deposit.
     * @param duration The duration in seconds until the funds can be withdrawn.
     */
    function deposit(
        address to,
        address token,
        uint256 amount,
        uint256 duration
    ) public payable {
        if (amount == 0) revert Escrow__AmountMustBeAboveZero();
        if (duration == 0) revert Escrow__DurationMustBeAboveZero();
        if (to == address(0)) revert Escrow__ToAddressMustNotBeZero();

        if (token == address(0)) {
            if (msg.value != amount) revert Escrow__EtherSentMustEqualAmount(msg.value, amount);
        } else {
            IERC20 erc20 = IERC20(token);
            erc20.transferFrom(msg.sender, address(this), amount);
        }

        uint256 depositId = s_depositCounter;

        uint256 releaseTime = block.timestamp + duration;

        EscrowDeposit memory m_deposit = EscrowDeposit({
            to: to,
            token: token,
            amount: amount,
            releaseTime: releaseTime
        });

        s_deposits[depositId] = m_deposit;

        s_depositCounter++;

        emit Deposit(depositId, msg.sender, to, token, amount, releaseTime);
    }

    /**
     * @notice Withdraws the funds of a deposit.
     * @dev The funds can only be withdrawn after the release time.
     * @dev This function is safe from Reentrancy, because it resets the deposit before transferring the funds.
     * @param depositId The id of the deposit.
     */
    function withdraw(uint256 depositId) public {
        EscrowDeposit memory m_deposit = getDeposit(depositId);

        if (m_deposit.amount == 0) revert Escrow__DepositDoesNotExist();
        if (m_deposit.to != msg.sender) revert Escrow__MsgSenderIsNotDepositReceiver();
        if (m_deposit.releaseTime > block.timestamp)
            revert Escrow__DepositIsStillLocked(m_deposit.releaseTime);

        address to = m_deposit.to;
        address token = m_deposit.token;
        uint256 amount = m_deposit.amount;

        m_deposit.to = address(0);
        m_deposit.token = address(0);
        m_deposit.amount = 0;
        m_deposit.releaseTime = 0;

        // First we reset the deposit to avoid reentrancy
        s_deposits[depositId] = m_deposit;

        if (token == address(0)) {
            payable(to).transfer(amount);
        } else {
            IERC20 erc20 = IERC20(token);
            erc20.transfer(to, amount);
        }

        emit Withdrawal(to, amount);
    }

    // Getters
    function getDeposit(uint256 depositId) public view returns (EscrowDeposit memory) {
        return s_deposits[depositId];
    }

    function getDepositCounter() public view returns (uint256) {
        return s_depositCounter;
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