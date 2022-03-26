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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import "../interfaces/AdapterInterface.sol";
import "../interfaces/AdapterInterface.sol";
import "../interfaces/WETH9.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ArbitrumL1InboxLike {
    function createRetryableTicket(
        address destAddr,
        uint256 arbTxCallValue,
        uint256 maxSubmissionCost,
        address submissionRefundAddress,
        address valueRefundAddress,
        uint256 maxGas,
        uint256 gasPriceBid,
        bytes calldata data
    ) external payable returns (uint256);
}

interface ArbitrumL1ERC20GatewayLike {
    function outboundTransfer(
        address _token,
        address _to,
        uint256 _amount,
        uint256 _maxGas,
        uint256 _gasPriceBid,
        bytes calldata _data
    ) external payable returns (bytes memory);
}

/**
 * @notice Contract containing logic to send messages from L1 to Arbitrum.
 * @dev Public functions calling external contracts do not guard against reentrancy because they are expected to be
 * called via delegatecall, which will execute this contract's logic within the context of the originating contract.
 * For example, the HubPool will delegatecall these functions, therefore its only neccessary that the HubPool's methods
 * that call this contract's logic guard against reentrancy.
 */
contract Arbitrum_Adapter is AdapterInterface {
    // Gas limit for immediate L2 execution attempt (can be estimated via NodeInterface.estimateRetryableTicket).
    // NodeInterface precompile interface exists at L2 address 0x00000000000000000000000000000000000000C8
    uint32 public immutable l2GasLimit = 5_000_000;

    // Amount of ETH allocated to pay for the base submission fee. The base submission fee is a parameter unique to
    // retryable transactions; the user is charged the base submission fee to cover the storage costs of keeping their
    // ticket’s calldata in the retry buffer. (current base submission fee is queryable via
    // ArbRetryableTx.getSubmissionPrice). ArbRetryableTicket precompile interface exists at L2 address
    // 0x000000000000000000000000000000000000006E.
    uint256 public immutable l2MaxSubmissionCost = 0.1e18;

    // L2 Gas price bid for immediate L2 execution attempt (queryable via standard eth*gasPrice RPC)
    uint256 public immutable l2GasPrice = 10e9; // 10 gWei

    // This address on L2 receives extra ETH that is left over after relaying a message via the inbox.
    address public immutable l2RefundL2Address;

    ArbitrumL1InboxLike public immutable l1Inbox;

    ArbitrumL1ERC20GatewayLike public immutable l1ERC20Gateway;

    event L2GasLimitSet(uint32 newL2GasLimit);

    event L2MaxSubmissionCostSet(uint256 newL2MaxSubmissionCost);

    event L2GasPriceSet(uint256 newL2GasPrice);

    event L2RefundL2AddressSet(address newL2RefundL2Address);

    /**
     * @notice Constructs new Adapter.
     * @param _l1ArbitrumInbox Inbox helper contract to send messages to Arbitrum.
     * @param _l1ERC20Gateway ERC20 gateway contract to send tokens to Arbitrum.
     */
    constructor(ArbitrumL1InboxLike _l1ArbitrumInbox, ArbitrumL1ERC20GatewayLike _l1ERC20Gateway) {
        l1Inbox = _l1ArbitrumInbox;
        l1ERC20Gateway = _l1ERC20Gateway;

        l2RefundL2Address = msg.sender;
    }

    /**
     * @notice Send cross-chain message to target on Arbitrum.
     * @notice This contract must hold at least getL1CallValue() amount of ETH to send a message via the Inbox
     * successfully, or the message will get stuck.
     * @param target Contract on Arbitrum that will receive message.
     * @param message Data to send to target.
     */
    function relayMessage(address target, bytes memory message) external payable override {
        uint256 requiredL1CallValue = getL1CallValue();
        require(address(this).balance >= requiredL1CallValue, "Insufficient ETH balance");

        l1Inbox.createRetryableTicket{ value: requiredL1CallValue }(
            target, // destAddr destination L2 contract address
            0, // l2CallValue call value for retryable L2 message
            l2MaxSubmissionCost, // maxSubmissionCost Max gas deducted from user's L2 balance to cover base fee
            l2RefundL2Address, // excessFeeRefundAddress maxgas * gasprice - execution cost gets credited here on L2
            l2RefundL2Address, // callValueRefundAddress l2Callvalue gets credited here on L2 if retryable txn times out or gets cancelled
            l2GasLimit, // maxGas Max gas deducted from user's L2 balance to cover L2 execution
            l2GasPrice, // gasPriceBid price bid for L2 execution
            message // data ABI encoded data of L2 message
        );

        emit MessageRelayed(target, message);
    }

    /**
     * @notice Bridge tokens to Arbitrum.
     * @param l1Token L1 token to deposit.
     * @param l2Token L2 token to receive.
     * @param amount Amount of L1 tokens to deposit and L2 tokens to receive.
     * @param to Bridge recipient.
     */
    function relayTokens(
        address l1Token,
        address l2Token, // l2Token is unused for Arbitrum.
        uint256 amount,
        address to
    ) external payable override {
        l1ERC20Gateway.outboundTransfer(l1Token, to, amount, l2GasLimit, l2GasPrice, "");
        emit TokensRelayed(l1Token, l2Token, amount, to);
    }

    /**
     * @notice Returns required amount of ETH to send a message via the Inbox.
     * @return amount of ETH that this contract needs to hold in order for relayMessage to succeed.
     */
    function getL1CallValue() public pure returns (uint256) {
        return l2MaxSubmissionCost + l2GasPrice * l2GasLimit;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

/**
 * @notice Sends cross chain messages and tokens to contracts on a specific L2 network.
 */

interface AdapterInterface {
    event HubPoolChanged(address newHubPool);

    event MessageRelayed(address target, bytes message);

    event TokensRelayed(address l1Token, address l2Token, uint256 amount, address to);

    function relayMessage(address target, bytes memory message) external payable;

    function relayTokens(
        address l1Token,
        address l2Token,
        uint256 amount,
        address to
    ) external payable;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

interface WETH9 {
    function withdraw(uint256 wad) external;

    function deposit() external payable;

    function balanceOf(address guy) external view returns (uint256 wad);

    function transfer(address guy, uint256 wad) external;
}