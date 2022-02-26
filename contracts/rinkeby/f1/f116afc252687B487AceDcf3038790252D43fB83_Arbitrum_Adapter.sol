// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

/**
 * @title A contract that provides modifiers to prevent reentrancy to state-changing and view-only methods. This contract
 * is inspired by https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/ReentrancyGuard.sol
 * and https://github.com/balancer-labs/balancer-core/blob/master/contracts/BPool.sol.
 */
contract Lockable {
    bool private _notEntered;

    constructor() {
        // Storing an initial non-zero value makes deployment a bit more expensive, but in exchange the refund on every
        // call to nonReentrant will be lower in amount. Since refunds are capped to a percentage of the total
        // transaction's gas, it is best to keep them low in cases like this one, to increase the likelihood of the full
        // refund coming into effect.
        _notEntered = true;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant` function is not supported. It is possible to
     * prevent this from happening by making the `nonReentrant` function external, and making it call a `private`
     * function that does the actual state modification.
     */
    modifier nonReentrant() {
        _preEntranceCheck();
        _preEntranceSet();
        _;
        _postEntranceReset();
    }

    /**
     * @dev Designed to prevent a view-only method from being re-entered during a call to a `nonReentrant()` state-changing method.
     */
    modifier nonReentrantView() {
        _preEntranceCheck();
        _;
    }

    // Internal methods are used to avoid copying the require statement's bytecode to every `nonReentrant()` method.
    // On entry into a function, `_preEntranceCheck()` should always be called to check if the function is being
    // re-entered. Then, if the function modifies state, it should call `_postEntranceSet()`, perform its logic, and
    // then call `_postEntranceReset()`.
    // View-only methods can simply call `_preEntranceCheck()` to make sure that it is not being re-entered.
    function _preEntranceCheck() internal view {
        // On the first call to nonReentrant, _notEntered will be true
        require(_notEntered, "ReentrancyGuard: reentrant call");
    }

    function _preEntranceSet() internal {
        // Any calls to nonReentrant after this point will fail
        _notEntered = false;
    }

    function _postEntranceReset() internal {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _notEntered = true;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import "./Base_Adapter.sol";
import "../interfaces/AdapterInterface.sol";
import "../interfaces/WETH9.sol";

import "@uma/core/contracts/common/implementation/Lockable.sol";

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

contract Arbitrum_Adapter is Base_Adapter, Lockable {
    // Gas limit for immediate L2 execution attempt (can be estimated via NodeInterface.estimateRetryableTicket).
    // NodeInterface precompile interface exists at L2 address 0x00000000000000000000000000000000000000C8
    uint32 public l2GasLimit = 5_000_000;

    // Amount of ETH allocated to pay for the base submission fee. The base submission fee is a parameter unique to
    // retryable transactions; the user is charged the base submission fee to cover the storage costs of keeping their
    // ticket’s calldata in the retry buffer. (current base submission fee is queryable via
    // ArbRetryableTx.getSubmissionPrice). ArbRetryableTicket precompile interface exists at L2 address
    // 0x000000000000000000000000000000000000006E.
    uint256 public l2MaxSubmissionCost = 0.1e18;

    // L2 Gas price bid for immediate L2 execution attempt (queryable via standard eth*gasPrice RPC)
    uint256 public l2GasPrice = 10e9; // 10 gWei

    // This address on L2 receives extra ETH that is left over after relaying a message via the inbox.
    address public l2RefundL2Address;

    ArbitrumL1InboxLike public l1Inbox;

    ArbitrumL1ERC20GatewayLike public l1ERC20Gateway;

    event L2GasLimitSet(uint32 newL2GasLimit);

    event L2MaxSubmissionCostSet(uint256 newL2MaxSubmissionCost);

    event L2GasPriceSet(uint256 newL2GasPrice);

    event L2RefundL2AddressSet(address newL2RefundL2Address);

    constructor(
        address _hubPool,
        ArbitrumL1InboxLike _l1ArbitrumInbox,
        ArbitrumL1ERC20GatewayLike _l1ERC20Gateway
    ) Base_Adapter(_hubPool) {
        l1Inbox = _l1ArbitrumInbox;
        l1ERC20Gateway = _l1ERC20Gateway;

        l2RefundL2Address = owner();
    }

    function setL2GasLimit(uint32 _l2GasLimit) public onlyOwner {
        l2GasLimit = _l2GasLimit;
        emit L2GasLimitSet(l2GasLimit);
    }

    function setL2MaxSubmissionCost(uint256 _l2MaxSubmissionCost) public onlyOwner {
        l2MaxSubmissionCost = _l2MaxSubmissionCost;
        emit L2MaxSubmissionCostSet(l2MaxSubmissionCost);
    }

    function setL2GasPrice(uint256 _l2GasPrice) public onlyOwner {
        l2GasPrice = _l2GasPrice;
        emit L2GasPriceSet(l2GasPrice);
    }

    function setL2RefundL2Address(address _l2RefundL2Address) public onlyOwner {
        l2RefundL2Address = _l2RefundL2Address;
        emit L2RefundL2AddressSet(l2RefundL2Address);
    }

    function relayMessage(address target, bytes memory message) external payable override nonReentrant onlyHubPool {
        uint256 requiredL1CallValue = getL1CallValue();
        require(address(this).balance >= requiredL1CallValue, "Insufficient ETH balance");

        l1Inbox.createRetryableTicket{ value: requiredL1CallValue }(
            target, // destAddr destination L2 contract address
            0, // l2CallValue call value for retryable L2 message
            l2MaxSubmissionCost, // maxSubmissionCost Max gas deducted from user's L2 balance to cover base submission fee
            l2RefundL2Address, // excessFeeRefundAddress maxgas x gasprice - execution cost gets credited here on L2 balance
            l2RefundL2Address, // callValueRefundAddress l2Callvalue gets credited here on L2 if retryable txn times out or gets cancelled
            l2GasLimit, // maxGas Max gas deducted from user's L2 balance to cover L2 execution
            l2GasPrice, // gasPriceBid price bid for L2 execution
            message // data ABI encoded data of L2 message
        );

        emit MessageRelayed(target, message);
    }

    function relayTokens(
        address l1Token,
        address l2Token, // l2Token is unused for Arbitrum.
        uint256 amount,
        address to
    ) external payable override nonReentrant onlyHubPool {
        l1ERC20Gateway.outboundTransfer(l1Token, to, amount, l2GasLimit, l2GasPrice, "");
        emit TokensRelayed(l1Token, l2Token, amount, to);
    }

    function getL1CallValue() public view returns (uint256) {
        return l2MaxSubmissionCost + l2GasPrice * l2GasLimit;
    }

    receive() external payable {}
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;
import "../interfaces/AdapterInterface.sol";

import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract Base_Adapter is Ownable, AdapterInterface {
    address public hubPool;

    modifier onlyHubPool() {
        require(msg.sender == hubPool, "Can only be called by hubPool");
        _;
    }

    constructor(address _hubPool) {
        hubPool = _hubPool;
    }

    function setHubPool(address _hubPool) public onlyOwner {
        hubPool = _hubPool;
        emit HubPoolChanged(_hubPool);
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