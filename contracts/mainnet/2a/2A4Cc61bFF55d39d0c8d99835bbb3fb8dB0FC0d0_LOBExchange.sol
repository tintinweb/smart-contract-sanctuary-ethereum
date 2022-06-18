//SPDX-License-Identifier: MIT
//Create by Openflow.network core team.
pragma solidity ^0.8.0;

import "./LOB.sol";
// import "./LOBExchange.sol";
import "./LOBFlowProxy.sol";
import "./interfaces/ILOBExchange.sol";
import "./interfaces/IStrategy.sol";
import "../../../interfaces/IEvaFlow.sol";

contract LOBExchange is IEvaFlow, LOBFlowProxy, LOB {
    IStrategy public strategy;

    event StrategyChanged(address newStrategy);

    constructor(IStrategy strategy_, Config memory cfg) LOB(cfg) {
        strategy = strategy_;
    }

    function check(bytes memory orderIdData)
        external
        view
        override
        returns (bool needExecute, bytes memory executeData)
    {
        bytes32 key = abi.decode(orderIdData, (bytes32));

        if (!isActiveOrder(key)) {
            return (false, bytes(""));
        }

        (Order memory order, OrderStatus memory status) = getOrderInfo(key);

        //find taker
        (uint256 input, uint256 output, bytes memory execData) = strategy.getRouter(
            address(order.inputToken),
            address(order.outputToken),
            status.balance,
            order.minRate
        );

        if (output == 0 || input < order.minInputPer) {
            return (false, bytes(""));
        }

        return (true, abi.encode(key, strategy, input, execData));
    }

    function needClose(bytes memory orderIdData) external view override returns (bool yes) {
        bytes32 orderId = abi.decode(orderIdData, (bytes32));
        yes = orderExpired(orderId);
    }

    function close(bytes memory orderIdData) external override {
        bytes32 orderId = abi.decode(orderIdData, (bytes32));
        closeOrder(orderId);
    }

    function execute(bytes memory executeData) external override returns (bool canDestoryFlow) {
        (bytes32 orderId, IStrategy s, uint256 input, bytes memory data) = abi.decode(
            executeData,
            (bytes32, IStrategy, uint256, bytes)
        );
        (, uint256 balance) = executeOrder(orderId, s, input, data);

        // can destory flow when order is completed.
        canDestoryFlow = balance == 0;
    }

    function setStrategy(address s) external onlyOwner {
        require(s != address(0), "strategy is empty");
        strategy = IStrategy(s);

        emit StrategyChanged(s);
    }
}

//SPDX-License-Identifier: MIT
//Create by Openflow.network core team.
pragma solidity ^0.8.0;

import "./interfaces/IStrategy.sol";
import "../../../lib/TransferHelper.sol";
import {Order} from "./interfaces/ILOBExchange.sol";

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @notice Core contract used to create, cancel and execute orders.
contract LOB is Ownable {
    using SafeMath for uint256;
    using Address for address;
    using SafeERC20 for IERC20;
    // using Fabric for bytes32;

    uint256 private constant _FEE_UNIT = 10000;
    uint256 private constant _ORDER_MIN_AGE = 9 minutes;
    uint256 private constant _ORDER_MAX_AGE = 90 days;
    mapping(bytes32 => Order) private _orders;
    mapping(bytes32 => OrderStatus) private _orderStatus;

    Config public config;
    struct Config {
        bool paused;
        uint64 basisPointsRate;
        address feeTo;
    }

    struct OrderStatus {
        uint96 balance;
        bool paused;
    }

    event OrderCreated(bytes32 indexed orderId, address indexed owner, uint256 fee);
    event OrderExecuted(bytes32 indexed orderId, uint256 input, uint256 output);
    event OrderCancelled(bytes32 indexed orderId, uint256 returnAmount);
    event ConfigChanged(Config newConfig);

    constructor(Config memory cfg) {
        setConfig(cfg);
    }

    /**
      @notice create order
      @dev sender can create order for anyone.
      rule:
      1. can't repeat create same order.
      2. creation fee charged, but capped.
      3. will transfer sell token to here.
     */
    function createOrder(Order memory order) public payable onlyRunning returns (bytes32 orderId) {
        orderId = keyOf(order);

        require(order.owner == msg.sender, "WRONG_INPUT_OWNER");
        require(
            order.deadline >= block.timestamp + _ORDER_MIN_AGE && //solhint-disable  not-rely-on-time
                order.deadline <= block.timestamp + _ORDER_MAX_AGE, //solhint-disable  not-rely-on-time
            "WRONG_EXPIRATION"
        );
        require(order.minInputPer <= order.inputAmount, "WRONG_INPUT_AMOUNT");
        require(_orders[orderId].owner == address(0), "ORDER_EXIST");

        (address feeTo, uint256 fee) = getFee(order.inputAmount);

        // save order info
        _orders[orderId] = order;
        _orderStatus[orderId].balance = order.inputAmount - uint96(fee);

        // transfer order amount to here include fee.
        if (order.inputToken == TransferHelper.ETH_ADDRESS) {
            require(msg.value == order.inputAmount, "WRONG_INPUT_AMOUNT");
        } else {
            TransferHelper.safeTransferFrom(order.inputToken, msg.sender, address(this), order.inputAmount);
        }

        if (fee > 0) {
            // feeTo never empty
            TransferHelper.safeTransferTokenOrETH(order.inputToken, feeTo, fee);
        }
        emit OrderCreated(orderId, order.owner, fee);
    }

    /**
     * @notice Cancel order
     * @dev
     *   1. order can be closed by order owner on any time.
     *   2. any one can close order when order has expired.
     */
    function closeOrder(bytes32 orderId) public {
        Order memory order = _orders[orderId];
        address orderOwner = order.owner;
        if (orderOwner != msg.sender) {
            require(orderExpired(orderId), "order is active");
        }
        uint256 balance = _orderStatus[orderId].balance; //  balance may be zero.
        delete _orderStatus[orderId];

        TransferHelper.safeTransferTokenOrETH(
            order.inputToken,
            order.receiptor == address(0) ? orderOwner : order.receiptor,
            balance
        );
        emit OrderCancelled(orderId, balance);
    }

    /**
     * @notice Executes an order
     * @dev it can be called by anyone
     */
    function executeOrder(
        bytes32 orderId,
        IStrategy strategy,
        uint256 input,
        bytes memory data
    ) public onlyRunning returns (uint256 output, uint256 orderBalance) {
        Order memory order = _orders[orderId];
        require(isActiveOrder(orderId), "ORDER_NOT_ACTIVE");

        // check input
        uint256 balance = _orderStatus[orderId].balance;
        uint256 minInput = balance <= order.minInputPer ? balance : order.minInputPer;
        require(input >= minInput, "ORDER_INPUT_LESS");

        // Pull amount to strategy
        _transferOutBalance(orderId, address(strategy), input);

        uint256 before = TransferHelper.balanceOf(order.outputToken, address(this));
        strategy.execute(order.inputToken, order.outputToken, data);
        output = TransferHelper.balanceOf(order.outputToken, address(this)).sub(before);

        // check bought
        uint256 expect = input.mul(order.minRate).div(1e18);

        require(output >= expect, "ORDER_OUTPUT_LESS");

        // pull bought to receiptor
        TransferHelper.safeTransferTokenOrETH(
            order.outputToken,
            order.receiptor != address(0) ? order.receiptor : order.owner,
            output
        );
        orderBalance = _orderStatus[orderId].balance;
        emit OrderExecuted(orderId, input, output);
    }

    function getOrderInfo(bytes32 orderId) public view returns (Order memory order, OrderStatus memory status) {
        order = _orders[orderId];
        status = _orderStatus[orderId];
    }

    function isActiveOrder(bytes32 orderId) public view returns (bool) {
        OrderStatus memory status = _orderStatus[orderId];
        //solhint-disable  not-rely-on-time
        return !status.paused && status.balance > 0 && _orders[orderId].deadline >= block.timestamp;
    }

    function orderExpired(bytes32 orderId) public view returns (bool) {
        return _orders[orderId].deadline < block.timestamp && _orderStatus[orderId].balance > 0;
    }

    /**
     * @notice Get the order's orderId
     */
    function keyOf(Order memory o) public pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    o.owner,
                    o.receiptor,
                    o.inputToken,
                    o.outputToken,
                    o.inputAmount,
                    o.minRate,
                    o.deadline,
                    o.minInputPer
                )
            );
    }

    function getFee(uint96 amountIn) public view returns (address feeTo, uint256 fee) {
        Config memory cfg = config;
        feeTo = cfg.feeTo;

        if (feeTo != address(0)) {
            // fee will always be less then amountIn
            fee = uint256(cfg.basisPointsRate).mul(amountIn).div(_FEE_UNIT);
        }
    }

    function setConfig(Config memory cfg) public onlyOwner {
        config = cfg;
        // safe check
        require(cfg.basisPointsRate < _FEE_UNIT, "INVALID_RATE");
        emit ConfigChanged(cfg);
    }

    function _transferOutBalance(
        bytes32 orderId,
        address to,
        uint256 amount
    ) private {
        uint96 balance = _orderStatus[orderId].balance;
        require(amount <= uint256(balance), "INSUFFICIENT_BALANCE");
        _orderStatus[orderId].balance = balance - uint96(amount);

        TransferHelper.safeTransferTokenOrETH(_orders[orderId].inputToken, to, amount);
    }

    modifier onlyRunning() {
        require(!config.paused, "LOB_PAUSED");
        _;
    }

    modifier onlySeller(bytes32 orderId) {
        require(msg.sender == _orders[orderId].owner, "INVALID_OWNER");
        _;
    }
}

//SPDX-License-Identifier: MIT
//Create by Openflow.network core team.
pragma solidity ^0.8.0;
import "../../../interfaces/IEvaFlowController.sol";
import "../../../interfaces/IEvaFlowProxy.sol";
import {KeepNetWork} from "../../../lib/EvabaseHelper.sol";

import "../../../lib/TransferHelper.sol";

import "./interfaces/ILOBExchange.sol";

contract LOBFlowProxy is IEvaFlowProxy {
    /**
      @notice use delegate to create LimitOrder by WalletSafes.
      @dev step:
         1. approve exchange to use asset.
         2. create order on exchange.
         3. register listen order task to Evabase
     */
    function create(
        IEvaFlowController ser,
        ILOBExchange exchange,
        KeepNetWork network,
        uint256 gasFee,
        string memory name,
        Order memory order
    ) external payable {
        require(bytes(name).length > 0, "invalid name");
        // disable call self
        require(address(this) != address(exchange), "FORBIDDEN");

        uint256 value = 0;
        if (order.inputToken == TransferHelper.ETH_ADDRESS) {
            value = msg.value - gasFee; // will be revert when overflow
            require(order.inputAmount + gasFee == msg.value, "invalid input amount");
        } else {
            require(msg.value == gasFee, "invalid value");
            //  pull token to acct's walletsafes from acct (msg.sender)
            TransferHelper.safeTransferFrom(order.inputToken, msg.sender, address(this), order.inputAmount);
            // approve Exchange can transfer amount
            TransferHelper.safeApprove(order.inputToken, address(exchange), order.inputAmount);
        }

        // create order and get order key.

        bytes32 orderId = exchange.createOrder{value: value}(order);

        // orderId+safes
        // 3. register listen order task on Evabase
        ser.registerFlow{value: gasFee}(
            name,
            network,
            address(exchange),
            abi.encode(orderId) //checkdata
        );
    }

    function closeFlow(IEvaFlowController ser, uint256 flowId) external override {
        ser.closeFlow(flowId);
        (ILOBExchange exchange, bytes32 orderKey) = _getInfo(ser, flowId);
        exchange.closeOrder(orderKey);
    }

    function _getInfo(IEvaFlowController ser, uint256 flowId)
        private
        view
        returns (ILOBExchange exchange, bytes32 key)
    {
        (address flow, bytes memory checkdata) = ser.getFlowCheckInfo(flowId);
        require(flow != address(0), "empty");

        exchange = ILOBExchange(flow);
        key = abi.decode(checkdata, (bytes32));
    }
}

//SPDX-License-Identifier: MIT
//Create by Openflow.network core team.
pragma solidity ^0.8.0;

struct Order {
    address owner;
    uint96 inputAmount;
    address inputToken;
    address outputToken;
    uint64 deadline;
    address receiptor;
    uint96 minInputPer;
    uint160 minRate;
}

interface ILOBExchange {
    function createOrder(Order calldata order) external payable returns (bytes32 key);

    function closeOrder(bytes32 key) external;
}

//SPDX-License-Identifier: MIT
//Create by Openflow.network core team.
pragma solidity ^0.8.0;

interface IERC20Exchange {
    function afterCreate(bytes32 key) external;

    function afterExcute(
        bytes32 key,
        uint256 input,
        uint256 output
    ) external;
}

interface IStrategy {
    function execute(
        address inputToken,
        address outputToken,
        bytes calldata execData
    ) external;

    function getRouter(
        address intputToken,
        address outputToken,
        uint256 maxInput,
        uint256 minRate
    )
        external
        view
        returns (
            uint256 input,
            uint256 output,
            bytes memory execData
        );
}

//SPDX-License-Identifier: MIT
//Create by evabase.network core team.
pragma solidity ^0.8.0;

interface IEvaFlow {
    function check(bytes memory checkData) external view returns (bool needExecute, bytes memory executeData);

    function execute(bytes memory executeData) external returns (bool canDestoryFlow);

    function needClose(bytes memory checkData) external returns (bool yes);

    function close(bytes memory checkData) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
// Copy from https://github.com/Uniswap/v3-periphery/blob/main/contracts/libraries/TransferHelper.sol
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library TransferHelper {
    /* solhint-disable */
    address internal constant ETH_ADDRESS = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

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
        require(success && (data.length == 0 || abi.decode(data, (bool))), "STF");
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
        require(success && (data.length == 0 || abi.decode(data, (bool))), "ST");
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
        require(success && (data.length == 0 || abi.decode(data, (bool))), "SA");
    }

    /// @notice Transfers ETH to the recipient address
    /// @dev Fails with `STE`
    /// @param to The destination of the transfer
    /// @param value The value to be transferred
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "STE");
    }

    /**
     * @notice Get the account's balance of token or ETH
     * @param token - Address of the token
     * @param addr - Address of the account
     * @return uint256 - Account's balance of token or ETH
     */
    function balanceOf(address token, address addr) internal view returns (uint256) {
        if (ETH_ADDRESS == address(token)) {
            return addr.balance;
        }
        return IERC20(token).balanceOf(addr);
    }

    /// @notice Transfers tokens from msg.sender to a recipient
    /// @dev Errors with ST if transfer fails
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function safeTransferTokenOrETH(
        address token,
        address to,
        uint256 value
    ) internal {
        if (ETH_ADDRESS == token) {
            safeTransferETH(to, value);
            return;
        }
        safeTransfer(token, to, value);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
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

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
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

//SPDX-License-Identifier: MIT
//Create by evabase.network core team.
pragma solidity ^0.8.0;
import {FlowStatus, KeepNetWork} from "../lib/EvabaseHelper.sol";

//struct
struct EvaFlowMeta {
    FlowStatus flowStatus;
    KeepNetWork keepNetWork;
    address admin;
    address lastKeeper;
    address lastVersionflow;
    uint256 lastExecNumber;
    uint256 maxVaildBlockNumber;
    string flowName;
    bytes checkData;
}

struct EvaUserMeta {
    uint120 ethBal;
    uint120 gasTokenBal; //keep
    uint8 vaildFlowsNum;
}

struct MinConfig {
    address feeRecived;
    address feeToken;
    uint64 minGasFundForUser;
    uint64 minGasFundOneFlow;
    uint16 ppb;
    uint16 blockCountPerTurn;
}

interface IEvaFlowController {
    event FlowOperatorChanged(address op, bool removed);
    event FlowCreated(address indexed user, uint256 indexed flowId, address flowAdd, bytes checkData, uint256 fee);
    event FlowUpdated(address indexed user, uint256 flowId, address flowAdd);
    event FlowClosed(address indexed user, uint256 flowId);
    event FlowExecuteSuccess(
        address indexed user,
        uint256 indexed flowId,
        uint120 payAmountByETH,
        uint120 payAmountByFeeToken,
        uint256 gasUsed
    );
    event FlowExecuteFailed(
        address indexed user,
        uint256 indexed flowId,
        uint120 payAmountByETH,
        uint120 payAmountByFeeToken,
        uint256 gasUsed,
        string reason
    );

    event SetMinConfig(
        address indexed user,
        address feeRecived,
        address feeToken,
        uint64 minGasFundForUser,
        uint64 minGasFundOneFlow,
        uint16 ppb,
        uint16 blockCountPerTurn
    );

    function registerFlow(
        string memory name,
        KeepNetWork keepNetWork,
        address flow,
        bytes memory checkdata
    ) external payable returns (uint256 flowId);

    function closeFlow(uint256 flowId) external;

    function closeFlowWithGas(uint256 flowId, uint256 before) external;

    function execFlow(
        address keeper,
        uint256 flowId,
        bytes memory inputData
    ) external;

    function depositFund(address flowAdmin) external payable;

    function withdrawFund(address recipient, uint256 amount) external;

    function withdrawPayment(uint256 amount) external;

    function getIndexVaildFlow(uint256 index, KeepNetWork keepNetWork) external view returns (uint256 value);

    function getAllVaildFlowSize(KeepNetWork keepNetWork) external view returns (uint256 size);

    function getFlowMetas(uint256 index) external view returns (EvaFlowMeta memory);

    function getFlowMetaSize() external view returns (uint256);

    function batchExecFlow(address keeper, bytes memory data) external;

    function getFlowCheckInfo(uint256 flowId) external view returns (address flow, bytes memory checkData);
}

//SPDX-License-Identifier: MIT
//Create by evabase.network core team.
pragma solidity ^0.8.0;

import "./IEvaFlowController.sol";

interface IEvaFlowProxy {
    function closeFlow(IEvaFlowController ctr, uint256 flowId) external;
}

//SPDX-License-Identifier: MIT
//Create by evabase.network core team.
pragma solidity ^0.8.0;

enum CompareOperator {
    Eq,
    Ne,
    Ge,
    Gt,
    Le,
    Lt
}

enum FlowStatus {
    Active, //可执行
    Closed,
    Expired,
    Completed,
    Unknown
}

enum KeepNetWork {
    ChainLink,
    Evabase,
    Gelato,
    Others
}