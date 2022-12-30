// SPDX-License-Identifier: CAL
pragma solidity =0.8.17;

import "./IOrderBookV1.sol";
import "../interpreter/run/LibStackTop.sol";
import {IERC20Upgradeable as IERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {SafeERC20Upgradeable as SafeERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {MathUpgradeable as Math} from "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "../math/FixedPointMath.sol";
import "../interpreter/ops/AllStandardOps.sol";
import "./OrderBookFlashLender.sol";
import {ReentrancyGuardUpgradeable as ReentrancyGuard} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "../interpreter/run/LibEncodedDispatch.sol";
import {MulticallUpgradeable as Multicall} from "@openzeppelin/contracts-upgradeable/utils/MulticallUpgradeable.sol";

SourceIndex constant ORDER_ENTRYPOINT = SourceIndex.wrap(0);
SourceIndex constant HANDLE_IO_ENTRYPOINT = SourceIndex.wrap(1);

uint constant ORDER_MIN_OUTPUTS = 2;
uint constant ORDER_MAX_OUTPUTS = 2;

uint constant HANDLE_IO_MIN_OUTPUTS = 0;
uint constant HANDLE_IO_MAX_OUTPUTS = type(uint16).max;

uint constant CONTEXT_COLUMNS = 4;
uint constant CONTEXT_BASE_COLUMN = 0;
uint constant CONTEXT_CALCULATIONS_COLUMN = 1;
uint constant CONTEXT_VAULT_INPUTS_COLUMN = 2;
uint constant CONTEXT_VAULT_OUTPUTS_COLUMN = 3;

uint constant CONTEXT_VAULT_IO_TOKEN = 0;
uint constant CONTEXT_VAULT_IO_TOKEN_DECIMALS = 1;
uint constant CONTEXT_VAULT_IO_VAULT_ID = 2;
uint constant CONTEXT_VAULT_IO_BALANCE_BEFORE = 3;
uint constant CONTEXT_VAULT_IO_BALANCE_DIFF = 4;
uint constant CONTEXT_VAULT_IO_ROWS = 5;

struct ClearStateChange {
    uint256 aOutput;
    uint256 bOutput;
    uint256 aInput;
    uint256 bInput;
}

library LibOrder {
    function hash(Order memory order_) internal pure returns (uint) {
        return uint256(keccak256(abi.encode(order_)));
    }
}

contract OrderBook is
    IOrderBookV1,
    ReentrancyGuard,
    Multicall,
    OrderBookFlashLender
{
    using LibInterpreterState for bytes;
    using LibStackTop for StackTop;
    using LibStackTop for uint256[];
    using LibUint256Array for uint256[];
    using SafeERC20 for IERC20;
    using Math for uint256;
    using FixedPointMath for uint256;
    using LibOrder for Order;
    using LibInterpreterState for InterpreterState;
    using LibUint256Array for uint;

    event Deposit(address sender, DepositConfig config);
    /// @param sender `msg.sender` withdrawing tokens.
    /// @param config All config sent to the `withdraw` call.
    /// @param amount The amount of tokens withdrawn, can be less than the
    /// config amount if the vault does not have the funds available to cover
    /// the config amount.
    event Withdraw(address sender, WithdrawConfig config, uint256 amount);
    event AddOrder(address sender, Order order, uint orderHash);
    event RemoveOrder(address sender, Order order, uint orderHash);
    event TakeOrder(
        address sender,
        TakeOrderConfig takeOrder,
        uint256 input,
        uint256 output
    );
    event OrderNotFound(address sender, address owner, uint orderHash);
    event OrderZeroAmount(address sender, address owner, uint orderHash);
    event OrderExceedsMaxRatio(address sender, address owner, uint orderHash);
    event Clear(address sender, Order a, Order b, ClearConfig clearConfig);
    event AfterClear(ClearStateChange stateChange);

    // order hash => order is live
    mapping(uint => uint) private orders;
    /// @inheritdoc IOrderBookV1
    mapping(address => mapping(address => mapping(uint256 => uint256)))
        public vaultBalance;

    constructor() initializer {
        __ReentrancyGuard_init();
        __Multicall_init();
    }

    function deposit(DepositConfig calldata config_) external nonReentrant {
        vaultBalance[msg.sender][config_.token][config_.vaultId] += config_
            .amount;
        emit Deposit(msg.sender, config_);
        IERC20(config_.token).safeTransferFrom(
            msg.sender,
            address(this),
            config_.amount
        );
    }

    /// Allows the sender to withdraw any tokens from their own vaults.
    /// @param config_ All config required to withdraw. Notably if the amount
    /// is less than the current vault balance then the vault will be cleared
    /// to 0 rather than the withdraw transaction reverting.
    function withdraw(WithdrawConfig calldata config_) external nonReentrant {
        uint256 vaultBalance_ = vaultBalance[msg.sender][config_.token][
            config_.vaultId
        ];
        uint256 withdrawAmount_ = config_.amount.min(vaultBalance_);
        vaultBalance[msg.sender][config_.token][config_.vaultId] =
            vaultBalance_ -
            withdrawAmount_;
        emit Withdraw(msg.sender, config_, withdrawAmount_);
        _decreaseFlashDebtThenSendToken(
            config_.token,
            msg.sender,
            withdrawAmount_
        );
    }

    function addOrder(OrderConfig calldata config_) external nonReentrant {
        address expression_ = IExpressionDeployerV1(config_.expressionDeployer)
            .deployExpression(
                config_.interpreterStateConfig,
                LibUint256Array.arrayFrom(
                    ORDER_MIN_OUTPUTS,
                    HANDLE_IO_MIN_OUTPUTS
                )
            );
        Order memory order_ = Order(
            msg.sender,
            config_.interpreter,
            LibEncodedDispatch.encode(
                expression_,
                ORDER_ENTRYPOINT,
                ORDER_MAX_OUTPUTS
            ),
            config_
                .interpreterStateConfig
                .sources[SourceIndex.unwrap(HANDLE_IO_ENTRYPOINT)]
                .length > 0
                ? LibEncodedDispatch.encode(
                    expression_,
                    HANDLE_IO_ENTRYPOINT,
                    HANDLE_IO_MAX_OUTPUTS
                )
                : EncodedDispatch.wrap(0),
            config_.validInputs,
            config_.validOutputs,
            config_.data
        );
        uint orderHash_ = order_.hash();
        orders[orderHash_] = 1;
        emit AddOrder(msg.sender, order_, orderHash_);
    }

    function removeOrder(Order calldata order_) external nonReentrant {
        require(msg.sender == order_.owner, "OWNER");
        uint orderHash_ = order_.hash();
        delete (orders[orderHash_]);
        emit RemoveOrder(msg.sender, order_, orderHash_);
    }

    function _calculateOrderIO(
        Order memory order_,
        uint inputIOIndex_,
        uint256 outputIOIndex_,
        address counterparty_
    )
        internal
        view
        returns (
            uint256 orderOutputMax_,
            uint256 orderIORatio_,
            uint[][] memory,
            uint[] memory
        )
    {
        uint orderHash_ = order_.hash();
        uint[][] memory context_ = new uint[][](CONTEXT_COLUMNS);

        {
            context_[CONTEXT_BASE_COLUMN] = LibUint256Array.arrayFrom(
                orderHash_,
                uint(uint160(order_.owner)),
                uint(uint160(counterparty_))
            );

            context_[CONTEXT_VAULT_INPUTS_COLUMN] = new uint[](
                CONTEXT_VAULT_IO_ROWS
            );
            context_[CONTEXT_VAULT_OUTPUTS_COLUMN] = new uint[](
                CONTEXT_VAULT_IO_ROWS
            );

            context_[CONTEXT_VAULT_INPUTS_COLUMN][
                CONTEXT_VAULT_IO_TOKEN
            ] = uint(uint160(order_.validInputs[inputIOIndex_].token));
            context_[CONTEXT_VAULT_OUTPUTS_COLUMN][
                CONTEXT_VAULT_IO_TOKEN
            ] = uint(uint160(order_.validOutputs[outputIOIndex_].token));

            context_[CONTEXT_VAULT_INPUTS_COLUMN][
                CONTEXT_VAULT_IO_TOKEN_DECIMALS
            ] = order_.validInputs[inputIOIndex_].decimals;
            context_[CONTEXT_VAULT_OUTPUTS_COLUMN][
                CONTEXT_VAULT_IO_TOKEN_DECIMALS
            ] = order_.validOutputs[outputIOIndex_].decimals;

            context_[CONTEXT_VAULT_INPUTS_COLUMN][
                CONTEXT_VAULT_IO_VAULT_ID
            ] = order_.validInputs[inputIOIndex_].vaultId;
            context_[CONTEXT_VAULT_OUTPUTS_COLUMN][
                CONTEXT_VAULT_IO_VAULT_ID
            ] = order_.validOutputs[outputIOIndex_].vaultId;

            context_[CONTEXT_VAULT_INPUTS_COLUMN][
                CONTEXT_VAULT_IO_BALANCE_BEFORE
            ] = vaultBalance[order_.owner][
                order_.validInputs[inputIOIndex_].token
            ][order_.validInputs[inputIOIndex_].vaultId];
            context_[CONTEXT_VAULT_OUTPUTS_COLUMN][
                CONTEXT_VAULT_IO_BALANCE_BEFORE
            ] = vaultBalance[order_.owner][
                order_.validOutputs[outputIOIndex_].token
            ][order_.validOutputs[outputIOIndex_].vaultId];
        }

        // The state changes produced here are handled in _recordVaultIO so that
        // local storage writes happen before writes on the interpreter.
        (uint[] memory stack_, uint[] memory stateChanges_) = IInterpreterV1(
            order_.interpreter
        ).evalWithNamespace(
                StateNamespace.wrap(uint(uint160(order_.owner))),
                order_.dispatch,
                context_
            );
        (orderOutputMax_, orderIORatio_) = stack_.asStackTopAfter().peek2();

        // Rescale order output max from 18 FP to whatever decimals the output
        // token is using.
        orderOutputMax_ = orderOutputMax_.scaleN(
            order_.validOutputs[outputIOIndex_].decimals
        );
        // Rescale the ratio from 18 FP according to the difference in decimals
        // between input and output.
        orderIORatio_ = orderIORatio_.scaleRatio(
            order_.validOutputs[outputIOIndex_].decimals,
            order_.validInputs[inputIOIndex_].decimals
        );

        uint[] memory calculationsContext_ = new uint[](2);
        calculationsContext_[0] = orderOutputMax_;
        calculationsContext_[1] = orderIORatio_;
        context_[CONTEXT_CALCULATIONS_COLUMN] = calculationsContext_;

        // The order owner can't send more than the smaller of their vault
        // balance or their per-order limit.
        orderOutputMax_ = orderOutputMax_.min(
            vaultBalance[order_.owner][
                order_.validOutputs[outputIOIndex_].token
            ][order_.validOutputs[outputIOIndex_].vaultId]
        );

        return (orderOutputMax_, orderIORatio_, context_, stateChanges_);
    }

    function _recordVaultIO(
        Order memory order_,
        uint256 input_,
        uint256 output_,
        uint[][] memory context_,
        uint[] memory stateChangesCalculate_
    ) internal {
        context_[CONTEXT_VAULT_INPUTS_COLUMN][
            CONTEXT_VAULT_IO_BALANCE_DIFF
        ] = input_;
        context_[CONTEXT_VAULT_OUTPUTS_COLUMN][
            CONTEXT_VAULT_IO_BALANCE_DIFF
        ] = output_;

        if (input_ > 0) {
            // IMPORTANT! THIS MATH MUST BE CHECKED TO AVOID OVERFLOW.
            vaultBalance[order_.owner][
                address(
                    uint160(
                        context_[CONTEXT_VAULT_INPUTS_COLUMN][
                            CONTEXT_VAULT_IO_TOKEN
                        ]
                    )
                )
            ][
                context_[CONTEXT_VAULT_INPUTS_COLUMN][CONTEXT_VAULT_IO_VAULT_ID]
            ] += input_;
        }
        if (output_ > 0) {
            // IMPORTANT! THIS MATH MUST BE CHECKED TO AVOID UNDERFLOW.
            vaultBalance[order_.owner][
                address(
                    uint160(
                        context_[CONTEXT_VAULT_OUTPUTS_COLUMN][
                            CONTEXT_VAULT_IO_TOKEN
                        ]
                    )
                )
            ][
                context_[CONTEXT_VAULT_OUTPUTS_COLUMN][
                    CONTEXT_VAULT_IO_VAULT_ID
                ]
            ] -= output_;
        }

        if (stateChangesCalculate_.length > 0) {
            IInterpreterV1(order_.interpreter).stateChangesWithNamespace(
                StateNamespace.wrap(uint(uint160(order_.owner))),
                stateChangesCalculate_
            );
        }
        if (EncodedDispatch.unwrap(order_.handleIODispatch) > 0) {
            (, uint[] memory stateChangesHandleIO_) = IInterpreterV1(
                order_.interpreter
            ).evalWithNamespace(
                    StateNamespace.wrap(uint(uint160(order_.owner))),
                    order_.handleIODispatch,
                    context_
                );
            if (stateChangesHandleIO_.length > 0) {
                IInterpreterV1(order_.interpreter).stateChangesWithNamespace(
                    StateNamespace.wrap(uint(uint160(order_.owner))),
                    stateChangesHandleIO_
                );
            }
        }
    }

    function takeOrders(
        TakeOrdersConfig calldata takeOrders_
    )
        external
        nonReentrant
        returns (uint256 totalInput_, uint256 totalOutput_)
    {
        uint256 i_ = 0;
        TakeOrderConfig memory takeOrder_;
        Order memory order_;
        uint256 remainingInput_ = takeOrders_.maximumInput;
        while (i_ < takeOrders_.orders.length && remainingInput_ > 0) {
            takeOrder_ = takeOrders_.orders[i_];
            order_ = takeOrder_.order;
            uint orderHash_ = order_.hash();
            if (orders[orderHash_] == 0) {
                emit OrderNotFound(msg.sender, order_.owner, orderHash_);
            } else {
                require(
                    order_.validInputs[takeOrder_.inputIOIndex].token ==
                        takeOrders_.output,
                    "TOKEN_MISMATCH"
                );
                require(
                    order_.validOutputs[takeOrder_.outputIOIndex].token ==
                        takeOrders_.input,
                    "TOKEN_MISMATCH"
                );

                (
                    uint256 orderOutputMax_,
                    uint256 orderIORatio_,
                    uint[][] memory context_,
                    uint[] memory stateChangesCalculate_
                ) = _calculateOrderIO(
                        order_,
                        takeOrder_.inputIOIndex,
                        takeOrder_.outputIOIndex,
                        msg.sender
                    );

                // Skip orders that are too expensive rather than revert as we have
                // no way of knowing if a specific order becomes too expensive
                // between submitting to mempool and execution, but other orders may
                // be valid so we want to take advantage of those if possible.
                if (orderIORatio_ > takeOrders_.maximumIORatio) {
                    emit OrderExceedsMaxRatio(
                        msg.sender,
                        order_.owner,
                        orderHash_
                    );
                } else if (orderOutputMax_ == 0) {
                    emit OrderZeroAmount(msg.sender, order_.owner, orderHash_);
                } else {
                    uint256 input_ = remainingInput_.min(orderOutputMax_);
                    uint256 output_ = input_.fixedPointMul(orderIORatio_);

                    remainingInput_ -= input_;
                    totalOutput_ += output_;

                    _recordVaultIO(
                        order_,
                        output_,
                        input_,
                        context_,
                        stateChangesCalculate_
                    );
                    emit TakeOrder(msg.sender, takeOrder_, input_, output_);
                }
            }

            unchecked {
                i_++;
            }
        }
        totalInput_ = takeOrders_.maximumInput - remainingInput_;

        require(totalInput_ >= takeOrders_.minimumInput, "MIN_INPUT");

        IERC20(takeOrders_.output).safeTransferFrom(
            msg.sender,
            address(this),
            totalOutput_
        );
        _decreaseFlashDebtThenSendToken(
            takeOrders_.input,
            msg.sender,
            totalInput_
        );
    }

    function clear(
        Order memory a_,
        Order memory b_,
        ClearConfig calldata clearConfig_
    ) external nonReentrant {
        {
            require(a_.owner != b_.owner, "SAME_OWNER");
            require(
                a_.validOutputs[clearConfig_.aOutputIOIndex].token ==
                    b_.validInputs[clearConfig_.bInputIOIndex].token,
                "TOKEN_MISMATCH"
            );
            require(
                b_.validOutputs[clearConfig_.bOutputIOIndex].token ==
                    a_.validInputs[clearConfig_.aInputIOIndex].token,
                "TOKEN_MISMATCH"
            );
            require(orders[a_.hash()] > 0, "A_NOT_LIVE");
            require(orders[b_.hash()] > 0, "B_NOT_LIVE");
        }

        ClearStateChange memory stateChange_;
        uint[][] memory aContext_;
        uint[] memory aStateChangesCalculate_;
        uint[][] memory bContext_;
        uint[] memory bStateChangesCalculate_;

        {
            // `IORatio` is input per output for both `a_` and `b_`.
            uint256 aIORatio_;
            uint256 bIORatio_;
            // `a_` and `b_` can both set a maximum output from the Interpreter.
            uint256 aOutputMax_;
            uint256 bOutputMax_;

            // emit the Clear event before `a_` and `b_` are mutated due to the
            // Interpreter execution in eval.
            emit Clear(msg.sender, a_, b_, clearConfig_);

            (
                aOutputMax_,
                aIORatio_,
                aContext_,
                aStateChangesCalculate_
            ) = _calculateOrderIO(
                a_,
                clearConfig_.aInputIOIndex,
                clearConfig_.aOutputIOIndex,
                b_.owner
            );
            (
                bOutputMax_,
                bIORatio_,
                bContext_,
                bStateChangesCalculate_
            ) = _calculateOrderIO(
                b_,
                clearConfig_.bInputIOIndex,
                clearConfig_.bOutputIOIndex,
                a_.owner
            );

            stateChange_.aOutput = aOutputMax_.min(
                bOutputMax_.fixedPointMul(bIORatio_)
            );
            stateChange_.bOutput = bOutputMax_.min(
                aOutputMax_.fixedPointMul(aIORatio_)
            );

            require(
                stateChange_.aOutput > 0 || stateChange_.bOutput > 0,
                "0_CLEAR"
            );

            stateChange_.aInput = stateChange_.aOutput.fixedPointMul(aIORatio_);
            stateChange_.bInput = stateChange_.bOutput.fixedPointMul(bIORatio_);
        }

        _recordVaultIO(
            a_,
            stateChange_.aInput,
            stateChange_.aOutput,
            aContext_,
            aStateChangesCalculate_
        );
        _recordVaultIO(
            b_,
            stateChange_.bInput,
            stateChange_.bOutput,
            bContext_,
            bStateChangesCalculate_
        );

        {
            // At least one of these will overflow due to negative bounties if
            // there is a spread between the orders.
            uint256 aBounty_ = stateChange_.aOutput - stateChange_.bInput;
            uint256 bBounty_ = stateChange_.bOutput - stateChange_.aInput;
            if (aBounty_ > 0) {
                vaultBalance[msg.sender][
                    a_.validOutputs[clearConfig_.aOutputIOIndex].token
                ][clearConfig_.aBountyVaultId] += aBounty_;
            }
            if (bBounty_ > 0) {
                vaultBalance[msg.sender][
                    b_.validOutputs[clearConfig_.bOutputIOIndex].token
                ][clearConfig_.bBountyVaultId] += bBounty_;
            }
        }

        emit AfterClear(stateChange_);
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

import "../interpreter/deploy/IExpressionDeployerV1.sol";
import "../interpreter/run/IInterpreterV1.sol";

struct DepositConfig {
    address token;
    uint256 vaultId;
    uint256 amount;
}

struct WithdrawConfig {
    address token;
    uint256 vaultId;
    uint256 amount;
}

struct IO {
    address token;
    uint8 decimals;
    uint256 vaultId;
}

struct OrderConfig {
    address expressionDeployer;
    address interpreter;
    StateConfig interpreterStateConfig;
    IO[] validInputs;
    IO[] validOutputs;
    bytes data;
}

struct Order {
    address owner;
    address interpreter;
    EncodedDispatch dispatch;
    EncodedDispatch handleIODispatch;
    IO[] validInputs;
    IO[] validOutputs;
    bytes data;
}

struct TakeOrdersConfig {
    /// Output token from the perspective of the order taker.
    address output;
    /// Input token from the perspective of the order taker.
    address input;
    /// Minimum input from the perspective of the order taker.
    uint256 minimumInput;
    /// Maximum input from the perspective of the order taker.
    uint256 maximumInput;
    /// Maximum IO ratio as calculated by the order being taken. The input is
    /// from the perspective of the order so higher ratio means worse deal for
    /// the order taker.
    uint256 maximumIORatio;
    /// Ordered list of orders that will be taken until the limit is hit. Takers
    /// are expected to prioritise orders that appear to be offering better
    /// deals i.e. lower IO ratios. This prioritisation and sorting MUST happen
    /// offchain, e.g. via. some simulator.
    TakeOrderConfig[] orders;
}

struct TakeOrderConfig {
    Order order;
    uint256 inputIOIndex;
    uint256 outputIOIndex;
}

struct ClearConfig {
    uint256 aInputIOIndex;
    uint256 aOutputIOIndex;
    uint256 bInputIOIndex;
    uint256 bOutputIOIndex;
    uint256 aBountyVaultId;
    uint256 bBountyVaultId;
}

interface IOrderBookV1 {
    /// depositor => token => vault id => token amount.
    function vaultBalance(
        address owner,
        address token,
        uint id
    ) external view returns (uint balance);

    function deposit(DepositConfig calldata config) external;

    function withdraw(WithdrawConfig calldata config) external;

    function addOrder(OrderConfig calldata config) external;

    function removeOrder(Order calldata order) external;

    function takeOrders(
        TakeOrdersConfig calldata takeOrders
    ) external returns (uint256 totalInput, uint256 totalOutput);

    function clear(
        Order memory a,
        Order memory b,
        ClearConfig calldata clearConfig
    ) external;
}

// SPDX-License-Identifier: CAL
pragma solidity =0.8.17;

/// Config required to build a new `State`.
/// @param sources Sources verbatim. These sources MUST be provided in their
/// sequential/index opcode form as the deployment process will need to index
/// into BOTH the integrity check and the final runtime function pointers.
/// This will be emitted in an event for offchain processing to use the indexed
/// opcode sources.
/// @param constants Constants verbatim. Constants are provided alongside sources
/// rather than inline as it allows us to avoid variable length opcodes and can
/// be more memory efficient if the same constant is referenced several times
/// from the sources.
struct StateConfig {
    bytes[] sources;
    uint256[] constants;
}

/// @title IExpressionDeployerV1
/// @notice Expressions are expected to be deployed onchain as immutable contract
/// code with a first class address like any other contract or account.
/// Technically this is optional in the sense that all the tools required to
/// eval some expression and define all its opcodes are available as libraries.
///
/// In practise there are enough advantages to deploying the sources directly
/// onchain as contract data and loading them from the interpreter at eval time:
///
/// - Loading and storing binary data is gas efficient as immutable contract data
/// - Expressions need to be immutable between their deploy time integrity check
///   and runtime evaluation
/// - Passing the address of an expression through calldata to an interpreter is
///   cheaper than passing an entire expression through calldata
/// - Conceptually a very simple approach, even if implementations like SSTORE2
///   are subtle under the hood
///
/// The expression deployer MUST perform an integrity check of the source code
/// before it puts the expression onchain at a known address. The integrity check
/// MUST at a minimum (it is free to do additional static analysis) calculate the
/// memory required to be allocated for the stack in total, and that no out of
/// bounds memory reads/writes occur within this stack. A simple example of an
/// invalid source would be one that pushes one value to the stack then attempts
/// to pops two values, clearly we cannot remove more values than we added.
///
/// Once the integrity check is complete the deployer MUST do any additional
/// processing required by its paired interpreter. For example, the expression
/// deployer MAY NEED to replace the indexed opcodes in the `StateConfig` sources
/// with real function pointers from the corresponding interpreter.
///
/// Interpreters MUST assume that expression deployers are malicious and fail
/// gracefully if the integrity check is corrupt/bypassed and/or function
/// pointers are incorrect, etc. i.e. the interpreter MUST always return a stack
/// from `eval` in a read only way or error. I.e. it is the expression deployer's
/// responsibility to do everything it can to prevent undefined behaviour in the
/// interpreter, and the interpreter's responsibility to handle the expression
/// deployer completely failing to do so.
interface IExpressionDeployerV1 {
    function deployExpression(
        StateConfig memory config,
        uint[] memory minOutputs
    ) external returns (address expressionAddress);
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.0;

type SourceIndex is uint256;
type EncodedDispatch is uint256;
type StateNamespace is uint256;
type Operand is uint256;

interface IInterpreterV1 {
    function functionPointers() external view returns (bytes memory);

    function eval(
        EncodedDispatch dispatch,
        uint256[][] calldata context
    )
        external
        view
        returns (uint256[] memory stack, uint256[] memory stateChanges);

    function stateChanges(uint[] calldata stateChanges) external;

    function evalWithNamespace(
        StateNamespace namespace,
        EncodedDispatch dispatch,
        uint256[][] calldata context
    )
        external
        view
        returns (uint256[] memory stack, uint256[] memory stateChanges);

    function stateChangesWithNamespace(
        StateNamespace namespace,
        uint256[] calldata stateChanges
    ) external;
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

import "./IInterpreterV1.sol";
import "../../array/LibUint256Array.sol";
import "../../bytes/LibBytes.sol";

/// Custom type to point to memory ostensibly in a stack.
type StackTop is uint256;

/// @title LibStackTop
/// @notice A `StackTop` is just a pointer to some memory. Ostensibly it is the
/// top of some stack used by the `RainInterpreter` so that means it can move "up" and
/// "down" (increment and decrement) by `uint256` (32 bytes) increments. In
/// general we're abusing that concept a bit to extend to things like the bottom
/// of a stack or a hypothetical maximum stack or even treating an arbitrary
/// `uint256[]` array as "a stack". In the future it's likely this lib and
/// concept will be renamed to reflect that it is used much more generally than
/// simply the top of some stack.
/// All the functions in `LibStackTop` operate on memory to read/write what is
/// referenced but the pointers and values themselves are typically input/output
/// of the functions. I.e. the stack top itself is not being mutated in-place,
/// typically the caller would have both the input stack top and the output
/// stack top in scope after calling library functions.
/// Most of the functions in this library are equivalent to each other via
/// composition, i.e. everything could be achieved with just `up`, `down`,
/// `pop`, `push`, `peek`. The reason there is so much duplication of logic is
/// that the Solidity compiler seems to fail at inlining equivalent logic quite
/// a lot sadly. There appears to be effort upstream towards improving the
/// function inlining by the optimizer so we should expect a lot of this library
/// to become redundant or even counterproductive in the future.
library LibStackTop {
    using LibStackTop for StackTop;
    using LibStackTop for uint256[];
    using LibStackTop for bytes;
    using LibUint256Array for uint256[];
    using LibBytes for uint256;

    /// Reads the value above the stack top. If the stack top is the current
    /// true stack top this is an out of bounds read. This is only useful if
    /// the stack was first moved down and the value it moved past needs to be
    /// read as part of the current operation.
    /// @param stackTop_ Position to read past/above.
    function peekUp(StackTop stackTop_) internal pure returns (uint256 a_) {
        assembly ("memory-safe") {
            a_ := mload(stackTop_)
        }
    }

    /// Read the value immediately below the given stack top. Equivalent to
    /// calling `pop` and discarding the `stackTopAfter_` value, so may be
    /// less gas than setting and discarding a value.
    /// @param stackTop_ The stack top to read below.
    /// @return a_ The value that was read.
    function peek(StackTop stackTop_) internal pure returns (uint256 a_) {
        assembly ("memory-safe") {
            a_ := mload(sub(stackTop_, 0x20))
        }
    }

    /// Reads 2 values below the given stack top.
    /// The following statements are equivalent but A may use gas if the
    /// compiler fails to inline some function calls.
    /// A:
    /// ```
    /// (uint a_, uint b_) = stackTop_.peek2();
    /// ```
    /// B:
    /// ```
    /// uint b_;
    /// (stackTop_, b_) = stackTop_.pop();
    /// uint a_ = stackTop_.peek();
    /// ```
    /// @param stackTop_ The stack top to peek below.
    function peek2(
        StackTop stackTop_
    ) internal pure returns (uint256 a_, uint256 b_) {
        assembly ("memory-safe") {
            a_ := mload(sub(stackTop_, 0x40))
            b_ := mload(sub(stackTop_, 0x20))
        }
    }

    /// Read the value immediately below the given stack top and return the
    /// stack top that points to the value that was read alongside the value.
    /// The following are equivalent but A may be cheaper if the compiler
    /// fails to inline some function calls:
    /// A:
    /// ```
    /// uint a_;
    /// (stackTop_, a_) = stackTop_.pop();
    /// ```
    /// B:
    /// ```
    /// stackTop_ = stackTop_.down();
    /// uint a_ = stackTop_.peekUp();
    /// ```
    /// @param stackTop_ The stack top to read below.
    /// @return stackTopAfter_ The stack top that points to the value that was
    /// read.
    /// @return a_ The value that was read.
    function pop(
        StackTop stackTop_
    ) internal pure returns (StackTop stackTopAfter_, uint256 a_) {
        assembly ("memory-safe") {
            stackTopAfter_ := sub(stackTop_, 0x20)
            a_ := mload(stackTopAfter_)
        }
    }

    function consumeSentinel(
        StackTop stackTop_,
        StackTop stackBottom_,
        uint256 sentinel_,
        uint256 stepSize_
    ) internal pure returns (StackTop, uint256[] memory) {
        uint256[] memory array_;
        assembly ("memory-safe") {
            // Underflow is not allowed and pointing at position 0 in memory is
            // corrupt behaviour anyway.
            if iszero(stackBottom_) {
                revert(0, 0)
            }
            let sentinelLocation_ := 0
            let length_ := 0
            let step_ := mul(stepSize_, 0x20)
            for {
                stackTop_ := sub(stackTop_, 0x20)
                let end_ := sub(stackBottom_, 0x20)
            } gt(stackTop_, end_) {
                stackTop_ := sub(stackTop_, step_)
                length_ := add(length_, stepSize_)
            } {
                if eq(sentinel_, mload(stackTop_)) {
                    sentinelLocation_ := stackTop_
                    break
                }
            }
            // Sentinel MUST exist in the stack if consumer expects it to there.
            if iszero(sentinelLocation_) {
                revert(0, 0)
            }
            mstore(sentinelLocation_, length_)
            array_ := sentinelLocation_
        }
        return (stackTop_, array_);
    }

    function consumeStructs(
        StackTop stackTop_,
        StackTop stackBottom_,
        uint256 sentinel_,
        uint256 structSize_
    ) internal pure returns (StackTop, uint256[] memory) {
        uint256[] memory tempArray_;
        (stackTop_, tempArray_) = stackTop_.consumeSentinel(
            stackBottom_,
            sentinel_,
            structSize_
        );
        uint256 structsLength_ = tempArray_.length / structSize_;
        uint256[] memory refs_ = new uint256[](structsLength_);
        assembly ("memory-safe") {
            for {
                let refCursor_ := add(refs_, 0x20)
                let refEnd_ := add(refCursor_, mul(structsLength_, 0x20))
                let tempCursor_ := add(tempArray_, 0x20)
                let tempStepSize_ := mul(structSize_, 0x20)
            } lt(refCursor_, refEnd_) {
                refCursor_ := add(refCursor_, 0x20)
                tempCursor_ := add(tempCursor_, tempStepSize_)
            } {
                mstore(refCursor_, tempCursor_)
            }
        }
        return (stackTop_, refs_);
    }

    /// Write a value at the stack top location. Typically not useful if the
    /// given stack top is not subsequently moved past the written value , or
    /// if the given stack top is actually located somewhere below the "true"
    /// stack top.
    /// @param stackTop_ The stack top to write the value at.
    /// @param a_ The value to write.
    function set(StackTop stackTop_, uint256 a_) internal pure {
        assembly ("memory-safe") {
            mstore(stackTop_, a_)
        }
    }

    /// Store a `uint256` at the stack top position and return the stack top
    /// above the written value. The following statements are equivalent in
    /// functionality but A may be less gas if the compiler fails to inline
    /// some function calls.
    /// A:
    /// ```
    /// stackTop_ = stackTop_.push(a_);
    /// ```
    /// B:
    /// ```
    /// stackTop_.set(a_);
    /// stackTop_ = stackTop_.up();
    /// ```
    /// @param stackTop_ The stack top to write at.
    /// @param a_ The value to write.
    /// @return The stack top above where `a_` was written to.
    function push(
        StackTop stackTop_,
        uint256 a_
    ) internal pure returns (StackTop) {
        assembly ("memory-safe") {
            mstore(stackTop_, a_)
            stackTop_ := add(stackTop_, 0x20)
        }
        return stackTop_;
    }

    /// Store a `uint256[]` at the stack top position and return the stack top
    /// above the written values. The length of the array is NOT written to the
    /// stack, ONLY the array values are copied to the stack. The following
    /// statements are equivalent in functionality but A may be less gas if the
    /// compiler fails to inline some function calls.
    /// A:
    /// ```
    /// stackTop_ = stackTop_.push(array_);
    /// ```
    /// B:
    /// ```
    /// unchecked {
    ///   for (uint i_ = 0; i_ < array_.length; i_++) {
    ///     stackTop_ = stackTop_.push(array_[i_]);
    ///   }
    /// }
    /// ```
    /// @param stackTop_ The stack top to write at.
    /// @param array_ The array of values to write.
    /// @return The stack top above the array.
    function push(
        StackTop stackTop_,
        uint256[] memory array_
    ) internal pure returns (StackTop) {
        array_.unsafeCopyValuesTo(StackTop.unwrap(stackTop_));
        return stackTop_.up(array_.length);
    }

    /// Store a `uint256[]` at the stack top position and return the stack top
    /// above the written values. The length of the array IS written to the
    /// stack.
    /// @param stackTop_ The stack top to write at.
    /// @param array_ The array of values and length to write.
    /// @return The stack top above the array.
    function pushWithLength(
        StackTop stackTop_,
        uint256[] memory array_
    ) internal pure returns (StackTop) {
        return stackTop_.push(array_.length).push(array_);
    }

    /// Store `bytes` at the stack top position and return the stack top above
    /// the written bytes. The length of the bytes is NOT written to the stack,
    /// ONLY the bytes are written. As `bytes` may be of arbitrary length, i.e.
    /// it MAY NOT be a multiple of 32, the push is unaligned. The caller MUST
    /// ensure that this is safe in context of subsequent reads and writes.
    /// @param stackTop_ The stack top to write at.
    /// @param bytes_ The bytes to write at the stack top.
    /// @return The stack top above the written bytes.
    function unalignedPush(
        StackTop stackTop_,
        bytes memory bytes_
    ) internal pure returns (StackTop) {
        StackTop.unwrap(bytes_.asStackTop().up()).unsafeCopyBytesTo(
            StackTop.unwrap(stackTop_),
            bytes_.length
        );
        return stackTop_.upBytes(bytes_.length);
    }

    /// Store `bytes` at the stack top position and return the stack top above
    /// the written bytes. The length of the bytes IS written to the stack in
    /// addition to the bytes. As `bytes` may be of arbitrary length, i.e. it
    /// MAY NOT be a multiple of 32, the push is unaligned. The caller MUST
    /// ensure that this is safe in context of subsequent reads and writes.
    /// @param stackTop_ The stack top to write at.
    /// @param bytes_ The bytes to write with their length at the stack top.
    /// @return The stack top above the written bytes.
    function unalignedPushWithLength(
        StackTop stackTop_,
        bytes memory bytes_
    ) internal pure returns (StackTop) {
        return stackTop_.push(bytes_.length).unalignedPush(bytes_);
    }

    /// Store 8x `uint256` at the stack top position and return the stack top
    /// above the written value. The following statements are equivalent in
    /// functionality but A may be cheaper if the compiler fails to
    /// inline some function calls.
    /// A:
    /// ```
    /// stackTop_ = stackTop_.push(a_, b_, c_, d_, e_, f_, g_, h_);
    /// ```
    /// B:
    /// ```
    /// stackTop_ = stackTop_
    ///   .push(a_)
    ///   .push(b_)
    ///   .push(c_)
    ///   .push(d_)
    ///   .push(e_)
    ///   .push(f_)
    ///   .push(g_)
    ///   .push(h_);
    /// @param stackTop_ The stack top to write at.
    /// @param a_ The first value to write.
    /// @param b_ The second value to write.
    /// @param c_ The third value to write.
    /// @param d_ The fourth value to write.
    /// @param e_ The fifth value to write.
    /// @param f_ The sixth value to write.
    /// @param g_ The seventh value to write.
    /// @param h_ The eighth value to write.
    /// @return The stack top above where `h_` was written.
    function push(
        StackTop stackTop_,
        uint256 a_,
        uint256 b_,
        uint256 c_,
        uint256 d_,
        uint256 e_,
        uint256 f_,
        uint256 g_,
        uint256 h_
    ) internal pure returns (StackTop) {
        assembly ("memory-safe") {
            mstore(stackTop_, a_)
            mstore(add(stackTop_, 0x20), b_)
            mstore(add(stackTop_, 0x40), c_)
            mstore(add(stackTop_, 0x60), d_)
            mstore(add(stackTop_, 0x80), e_)
            mstore(add(stackTop_, 0xA0), f_)
            mstore(add(stackTop_, 0xC0), g_)
            mstore(add(stackTop_, 0xE0), h_)
            stackTop_ := add(stackTop_, 0x100)
        }
        return stackTop_;
    }

    /// Execute a function, reading and writing inputs and outputs on the stack.
    /// The caller MUST ensure this does not result in unsafe reads and writes.
    /// @param stackTop_ The stack top to read and write to.
    /// @param fn_ The function to run on the stack.
    /// @return The new stack top above the outputs of fn_.
    function applyFn(
        StackTop stackTop_,
        function(uint256) internal view returns (uint256) fn_
    ) internal view returns (StackTop) {
        uint256 a_;
        uint256 location_;
        assembly ("memory-safe") {
            location_ := sub(stackTop_, 0x20)
            a_ := mload(location_)
        }
        a_ = fn_(a_);
        assembly ("memory-safe") {
            mstore(location_, a_)
        }
        return stackTop_;
    }

    /// Execute a function, reading and writing inputs and outputs on the stack.
    /// The caller MUST ensure this does not result in unsafe reads and writes.
    /// @param stackTop_ The stack top to read and write to.
    /// @param fn_ The function to run on the stack.
    /// @return The new stack top above the outputs of fn_.
    function applyFn(
        StackTop stackTop_,
        function(Operand, uint256) internal view returns (uint256) fn_,
        Operand operand_
    ) internal view returns (StackTop) {
        uint256 a_;
        uint256 location_;
        assembly ("memory-safe") {
            location_ := sub(stackTop_, 0x20)
            a_ := mload(location_)
        }
        a_ = fn_(operand_, a_);
        assembly ("memory-safe") {
            mstore(location_, a_)
        }
        return stackTop_;
    }

    /// Execute a function, reading and writing inputs and outputs on the stack.
    /// The caller MUST ensure this does not result in unsafe reads and writes.
    /// @param stackTop_ The stack top to read and write to.
    /// @param fn_ The function to run on the stack.
    /// @return The new stack top above the outputs of fn_.
    function applyFn(
        StackTop stackTop_,
        function(uint256, uint256) internal view returns (uint256) fn_
    ) internal view returns (StackTop) {
        uint256 a_;
        uint256 b_;
        uint256 location_;
        assembly ("memory-safe") {
            stackTop_ := sub(stackTop_, 0x20)
            location_ := sub(stackTop_, 0x20)
            a_ := mload(location_)
            b_ := mload(stackTop_)
        }
        a_ = fn_(a_, b_);
        assembly ("memory-safe") {
            mstore(location_, a_)
        }
        return stackTop_;
    }

    /// Reduce a function N times, reading and writing inputs and the accumulated
    /// result on the stack.
    /// The caller MUST ensure this does not result in unsafe reads and writes.
    /// @param stackTop_ The stack top to read and write to.
    /// @param fn_ The function to run on the stack.
    /// @param n_ The number of times to apply fn_ to accumulate a final result.
    /// @return stackTopAfter_ The new stack top above the outputs of fn_.
    function applyFnN(
        StackTop stackTop_,
        function(uint256, uint256) internal view returns (uint256) fn_,
        uint256 n_
    ) internal view returns (StackTop stackTopAfter_) {
        unchecked {
            uint256 bottom_;
            uint256 cursor_;
            uint256 a_;
            uint256 b_;
            assembly ("memory-safe") {
                bottom_ := sub(stackTop_, mul(n_, 0x20))
                a_ := mload(bottom_)
                stackTopAfter_ := add(bottom_, 0x20)
                cursor_ := stackTopAfter_
            }
            while (cursor_ < StackTop.unwrap(stackTop_)) {
                assembly ("memory-safe") {
                    b_ := mload(cursor_)
                }
                a_ = fn_(a_, b_);
                cursor_ += 0x20;
            }
            assembly ("memory-safe") {
                mstore(bottom_, a_)
            }
        }
    }

    function applyFnN(
        StackTop stackTop_,
        function(uint256) internal view fn_,
        uint256 n_
    ) internal view returns (StackTop stackTopAfter_) {
        uint256 cursor_;
        uint256 a_;
        assembly ("memory-safe") {
            stackTopAfter_ := sub(stackTop_, mul(n_, 0x20))
            cursor_ := stackTopAfter_
        }
        while (cursor_ < StackTop.unwrap(stackTop_)) {
            assembly ("memory-safe") {
                a_ := mload(cursor_)
                cursor_ := add(cursor_, 0x20)
            }
            fn_(a_);
        }
    }

    /// Execute a function, reading and writing inputs and outputs on the stack.
    /// The caller MUST ensure this does not result in unsafe reads and writes.
    /// @param stackTop_ The stack top to read and write to.
    /// @param fn_ The function to run on the stack.
    /// @return The new stack top above the outputs of fn_.
    function applyFn(
        StackTop stackTop_,
        function(uint256, uint256, uint256) internal view returns (uint256) fn_
    ) internal view returns (StackTop) {
        uint256 a_;
        uint256 b_;
        uint256 c_;
        uint256 location_;
        assembly ("memory-safe") {
            stackTop_ := sub(stackTop_, 0x40)
            location_ := sub(stackTop_, 0x20)
            a_ := mload(location_)
            b_ := mload(stackTop_)
            c_ := mload(add(stackTop_, 0x20))
        }
        a_ = fn_(a_, b_, c_);
        assembly ("memory-safe") {
            mstore(location_, a_)
        }
        return stackTop_;
    }

    /// Execute a function, reading and writing inputs and outputs on the stack.
    /// The caller MUST ensure this does not result in unsafe reads and writes.
    /// @param stackTop_ The stack top to read and write to.
    /// @param fn_ The function to run on the stack.
    /// @return The new stack top above the outputs of fn_.
    function applyFn(
        StackTop stackTop_,
        function(uint256, uint256, uint256, uint)
            internal
            view
            returns (uint256) fn_
    ) internal view returns (StackTop) {
        uint256 a_;
        uint256 b_;
        uint256 c_;
        uint d_;
        uint256 location_;
        assembly ("memory-safe") {
            stackTop_ := sub(stackTop_, 0x60)
            location_ := sub(stackTop_, 0x20)
            a_ := mload(location_)
            b_ := mload(stackTop_)
            c_ := mload(add(stackTop_, 0x20))
            d_ := mload(add(stackTop_, 0x40))
        }
        a_ = fn_(a_, b_, c_, d_);
        assembly ("memory-safe") {
            mstore(location_, a_)
        }
        return stackTop_;
    }

    /// Execute a function, reading and writing inputs and outputs on the stack.
    /// The caller MUST ensure this does not result in unsafe reads and writes.
    /// @param stackTop_ The stack top to read and write to.
    /// @param fn_ The function to run on the stack.
    /// @param operand_ Operand is passed from the source instead of the stack.
    /// @return The new stack top above the outputs of fn_.
    function applyFn(
        StackTop stackTop_,
        function(Operand, uint256, uint256) internal view returns (uint256) fn_,
        Operand operand_
    ) internal view returns (StackTop) {
        uint256 a_;
        uint256 b_;
        uint256 location_;
        assembly ("memory-safe") {
            stackTop_ := sub(stackTop_, 0x20)
            location_ := sub(stackTop_, 0x20)
            a_ := mload(location_)
            b_ := mload(stackTop_)
        }
        a_ = fn_(operand_, a_, b_);
        assembly ("memory-safe") {
            mstore(location_, a_)
        }
        return stackTop_;
    }

    function applyFn(
        StackTop stackTop_,
        function(uint256[] memory) internal view returns (uint256) fn_,
        uint256 length_
    ) internal view returns (StackTop stackTopAfter_) {
        (uint256 a_, uint256[] memory tail_) = stackTop_.list(length_);
        uint256 b_ = fn_(tail_);
        return tail_.asStackTop().push(a_).push(b_);
    }

    /// Execute a function, reading and writing inputs and outputs on the stack.
    /// The caller MUST ensure this does not result in unsafe reads and writes.
    /// @param stackTop_ The stack top to read and write to.
    /// @param fn_ The function to run on the stack.
    /// @param length_ The length of the array to pass to fn_ from the stack.
    /// @return stackTopAfter_ The new stack top above the outputs of fn_.
    function applyFn(
        StackTop stackTop_,
        function(uint256, uint256, uint256[] memory)
            internal
            view
            returns (uint256) fn_,
        uint256 length_
    ) internal view returns (StackTop stackTopAfter_) {
        (uint256 b_, uint256[] memory tail_) = stackTop_.list(length_);
        stackTopAfter_ = tail_.asStackTop();
        (StackTop location_, uint256 a_) = stackTopAfter_.pop();
        location_.set(fn_(a_, b_, tail_));
    }

    /// Execute a function, reading and writing inputs and outputs on the stack.
    /// The caller MUST ensure this does not result in unsafe reads and writes.
    /// @param stackTop_ The stack top to read and write to.
    /// @param fn_ The function to run on the stack.
    /// @param length_ The length of the array to pass to fn_ from the stack.
    /// @return The new stack top above the outputs of fn_.
    function applyFn(
        StackTop stackTop_,
        function(uint256, uint256, uint256, uint256[] memory)
            internal
            view
            returns (uint256) fn_,
        uint256 length_
    ) internal view returns (StackTop) {
        (uint256 c_, uint256[] memory tail_) = stackTop_.list(length_);
        (StackTop stackTopAfter_, uint256 b_) = tail_.asStackTop().pop();
        uint256 a_ = stackTopAfter_.peek();
        stackTopAfter_.down().set(fn_(a_, b_, c_, tail_));
        return stackTopAfter_;
    }

    /// Execute a function, reading and writing inputs and outputs on the stack.
    /// The caller MUST ensure this does not result in unsafe reads and writes.
    /// @param stackTop_ The stack top to read and write to.
    /// @param fn_ The function to run on the stack.
    /// @param length_ The length of the arrays to pass to fn_ from the stack.
    /// @return The new stack top above the outputs of fn_.
    function applyFn(
        StackTop stackTop_,
        function(uint256, uint256[] memory, uint256[] memory)
            internal
            view
            returns (uint256[] memory) fn_,
        uint256 length_
    ) internal view returns (StackTop) {
        StackTop csStart_ = stackTop_.down(length_);
        uint256[] memory cs_ = LibUint256Array.copyToNewUint256Array(
            StackTop.unwrap(csStart_),
            length_
        );
        (uint256 a_, uint256[] memory bs_) = csStart_.list(length_);

        uint256[] memory results_ = fn_(a_, bs_, cs_);
        require(results_.length == length_, "BAD_RESULT_LENGTH");
        StackTop bottom_ = bs_.asStackTop();
        LibUint256Array.unsafeCopyValuesTo(results_, StackTop.unwrap(bottom_));
        return bottom_.up(length_);
    }

    /// Returns `length_` values from the stack as an array without allocating
    /// new memory. As arrays always start with their length, this requires
    /// writing the length value to the stack below the array values. The value
    /// that is overwritten in the process is also returned so that data is not
    /// lost. For example, imagine a stack `[ A B C D ]` and we list 2 values.
    /// This will write the stack to look like `[ A 2 C D ]` and return both `B`
    /// and a pointer to `2` represented as a `uint256[]`.
    /// The returned array is ONLY valid for as long as the stack DOES NOT move
    /// back into its memory. As soon as the stack moves up again and writes into
    /// the array it will be corrupt. The caller MUST ensure that it does not
    /// read from the returned array after it has been corrupted by subsequent
    /// stack writes.
    /// @param stackTop_ The stack top to read the values below into an array.
    /// @param length_ The number of values to include in the returned array.
    /// @return head_ The value that was overwritten with the length.
    /// @return tail_ The array constructed from the stack memory.
    function list(
        StackTop stackTop_,
        uint256 length_
    ) internal pure returns (uint256 head_, uint256[] memory tail_) {
        assembly ("memory-safe") {
            tail_ := sub(stackTop_, add(0x20, mul(length_, 0x20)))
            head_ := mload(tail_)
            mstore(tail_, length_)
        }
    }

    /// Cast a `uint256[]` array to a stack top. The stack top will point to the
    /// length of the array, NOT its first value.
    /// @param array_ The array to cast to a stack top.
    /// @return stackTop_ The stack top that points to the length of the array.
    function asStackTop(
        uint256[] memory array_
    ) internal pure returns (StackTop stackTop_) {
        assembly ("memory-safe") {
            stackTop_ := array_
        }
    }

    /// Cast a stack top to an array. The value immediately above the stack top
    /// will be treated as the length of the array, so the proceeding length
    /// values will be the items of the array. The caller MUST ensure the values
    /// above the stack top constitute a valid array. The retured array will be
    /// corrupt if/when the stack subsequently moves into it and writes to those
    /// memory locations. The caller MUST ensure that it does NOT read from the
    /// returned array after the stack writes over it.
    /// @param stackTop_ The stack top that will be cast to an array.
    /// @return array_ The array above the stack top.
    function asUint256Array(
        StackTop stackTop_
    ) internal pure returns (uint256[] memory array_) {
        assembly ("memory-safe") {
            array_ := stackTop_
        }
    }

    /// Cast a stack top to bytes. The value immediately above the stack top will
    /// be treated as the length of the `bytes`, so the proceeding length bytes
    /// will be the data of the `bytes`. The caller MUST ensure the length and
    /// bytes above the stack top constitute valid `bytes` data. The returned
    /// `bytes` will be corrupt if/when the stack subsequently moves into it and
    /// writes to those memory locations. The caller MUST ensure that it does
    /// NOT read from the returned bytes after the stack writes over it.
    /// @param stackTop_ The stack top that will be cast to bytes.
    /// @return bytes_ The bytes above the stack top.
    function asBytes(
        StackTop stackTop_
    ) internal pure returns (bytes memory bytes_) {
        assembly ("memory-safe") {
            bytes_ := stackTop_
        }
    }

    /// Cast a `uint256[]` array to a stack top after its length. The stack top
    /// will point to the first item of the array, NOT its length.
    /// @param array_ The array to cast to a stack top.
    /// @return stackTop_ The stack top that points to the first item of the array.
    function asStackTopUp(
        uint256[] memory array_
    ) internal pure returns (StackTop stackTop_) {
        assembly ("memory-safe") {
            stackTop_ := add(array_, 0x20)
        }
    }

    function asStackTopAfter(
        uint256[] memory array_
    ) internal pure returns (StackTop stackTop_) {
        assembly ("memory-safe") {
            stackTop_ := add(array_, add(0x20, mul(mload(array_), 0x20)))
        }
    }

    /// Cast `bytes` to a stack top. The stack top will point to the length of
    /// the `bytes`, NOT the first byte.
    /// @param bytes_ The `bytes` to cast to a stack top.
    /// @return stackTop_ The stack top that points to the length of the bytes.
    function asStackTop(
        bytes memory bytes_
    ) internal pure returns (StackTop stackTop_) {
        assembly ("memory-safe") {
            stackTop_ := bytes_
        }
    }

    /// Returns the stack top 32 bytes above/past the passed stack top.
    /// @param stackTop_ The stack top at the starting position.
    /// @return The stack top 32 bytes above the passed stack top.
    function up(StackTop stackTop_) internal pure returns (StackTop) {
        unchecked {
            return StackTop.wrap(StackTop.unwrap(stackTop_) + 0x20);
        }
    }

    /// Returns the stack top `n_ * 32` bytes above/past the passed stack top.
    /// @param stackTop_ The stack top at the starting position.
    /// @param n_ The multiplier on the stack movement. MAY be zero.
    /// @return The stack top `n_ * 32` bytes above/past the passed stack top.
    function up(
        StackTop stackTop_,
        uint256 n_
    ) internal pure returns (StackTop) {
        unchecked {
            return StackTop.wrap(StackTop.unwrap(stackTop_) + 0x20 * n_);
        }
    }

    /// Returns the stack top `n_` bytes above/past the passed stack top.
    /// The returned stack top MAY NOT be aligned with the passed stack top for
    /// subsequent 32 byte reads and writes. The caller MUST ensure that it is
    /// safe to read and write data relative to the returned stack top.
    /// @param stackTop_ The stack top at the starting position.
    /// @param n_ The number of bytes to move.
    /// @return The stack top `n_` bytes above/past the passed stack top.
    function upBytes(
        StackTop stackTop_,
        uint256 n_
    ) internal pure returns (StackTop) {
        unchecked {
            return StackTop.wrap(StackTop.unwrap(stackTop_) + n_);
        }
    }

    /// Returns the stack top 32 bytes below/before the passed stack top.
    /// @param stackTop_ The stack top at the starting position.
    /// @return The stack top 32 bytes below/before the passed stack top.
    function down(StackTop stackTop_) internal pure returns (StackTop) {
        unchecked {
            return StackTop.wrap(StackTop.unwrap(stackTop_) - 0x20);
        }
    }

    /// Returns the stack top `n_ * 32` bytes below/before the passed stack top.
    /// @param stackTop_ The stack top at the starting position.
    /// @param n_ The multiplier on the movement.
    /// @return The stack top `n_ * 32` bytes below/before the passed stack top.
    function down(
        StackTop stackTop_,
        uint256 n_
    ) internal pure returns (StackTop) {
        unchecked {
            return StackTop.wrap(StackTop.unwrap(stackTop_) - 0x20 * n_);
        }
    }

    /// Convert two stack top values to a single stack index. A stack index is
    /// the distance in 32 byte increments between two stack positions. The
    /// calculations assumes the two stack positions are aligned. The caller MUST
    /// ensure the alignment of both values. The calculation is unchecked and MAY
    /// underflow. The caller MUST ensure that the stack top is always above the
    /// stack bottom.
    /// @param stackBottom_ The lower of the two values.
    /// @param stackTop_ The higher of the two values.
    /// @return The stack index as 32 byte distance between the two stack
    /// positions.
    function toIndex(
        StackTop stackBottom_,
        StackTop stackTop_
    ) internal pure returns (uint256) {
        unchecked {
            return
                (StackTop.unwrap(stackTop_) - StackTop.unwrap(stackBottom_)) /
                0x20;
        }
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

/// @title Uint256Array
/// @notice Things we want to do carefully and efficiently with uint256 arrays
/// that Solidity doesn't give us native tools for.
library LibUint256Array {
    using LibUint256Array for uint256[];

    /// Building arrays from literal components is a common task that introduces
    /// boilerplate that is either inefficient or error prone.
    /// @param a_ a single integer to build an array around.
    /// @return the newly allocated array including a_ as a single item.
    function arrayFrom(uint256 a_) internal pure returns (uint256[] memory) {
        uint256[] memory array_ = new uint256[](1);
        assembly ("memory-safe") {
            mstore(add(array_, 0x20), a_)
        }
        return array_;
    }

    /// Building arrays from literal components is a common task that introduces
    /// boilerplate that is either inefficient or error prone.
    /// @param a_ the first integer to build an array around.
    /// @param b_ the second integer to build an array around.
    /// @return the newly allocated array including a_ and b_ as the only items.
    function arrayFrom(
        uint256 a_,
        uint256 b_
    ) internal pure returns (uint256[] memory) {
        uint256[] memory array_ = new uint256[](2);
        assembly ("memory-safe") {
            mstore(add(array_, 0x20), a_)
            mstore(add(array_, 0x40), b_)
        }
        return array_;
    }

    function arrayFrom(
        uint256 a_,
        uint256 b_,
        uint256 c_
    ) internal pure returns (uint256[] memory) {
        uint256[] memory array_ = new uint256[](3);
        assembly ("memory-safe") {
            mstore(add(array_, 0x20), a_)
            mstore(add(array_, 0x40), b_)
            mstore(add(array_, 0x60), c_)
        }
        return array_;
    }

    function arrayFrom(
        uint256 a_,
        uint256 b_,
        uint256 c_,
        uint256 d_
    ) internal pure returns (uint256[] memory) {
        uint256[] memory array_ = new uint256[](4);
        assembly ("memory-safe") {
            mstore(add(array_, 0x20), a_)
            mstore(add(array_, 0x40), b_)
            mstore(add(array_, 0x60), c_)
            mstore(add(array_, 0x80), d_)
        }
        return array_;
    }

    function arrayFrom(
        uint256 a_,
        uint256 b_,
        uint256 c_,
        uint256 d_,
        uint256 e_
    ) internal pure returns (uint256[] memory) {
        uint256[] memory array_ = new uint256[](5);
        assembly ("memory-safe") {
            mstore(add(array_, 0x20), a_)
            mstore(add(array_, 0x40), b_)
            mstore(add(array_, 0x60), c_)
            mstore(add(array_, 0x80), d_)
            mstore(add(array_, 0xA0), e_)
        }
        return array_;
    }

    function arrayFrom(
        uint256 a_,
        uint256 b_,
        uint256 c_,
        uint256 d_,
        uint256 e_,
        uint f_
    ) internal pure returns (uint256[] memory) {
        uint256[] memory array_ = new uint256[](6);
        assembly ("memory-safe") {
            mstore(add(array_, 0x20), a_)
            mstore(add(array_, 0x40), b_)
            mstore(add(array_, 0x60), c_)
            mstore(add(array_, 0x80), d_)
            mstore(add(array_, 0xA0), e_)
            mstore(add(array_, 0xC0), f_)
        }
        return array_;
    }

    /// Building arrays from literal components is a common task that introduces
    /// boilerplate that is either inefficient or error prone.
    /// @param a_ The head of the new array.
    /// @param tail_ The tail of the new array.
    /// @return The new array.
    function arrayFrom(
        uint256 a_,
        uint256[] memory tail_
    ) internal pure returns (uint256[] memory) {
        uint256[] memory array_ = new uint256[](1);
        assembly ("memory-safe") {
            mstore(add(array_, 0x20), a_)
        }
        array_.extend(tail_);
        return array_;
    }

    /// Building arrays from literal components is a common task that introduces
    /// boilerplate that is either inefficient or error prone.
    /// @param a_ The first item of the new array.
    /// @param b_ The second item of the new array.
    /// @param tail_ The tail of the new array.
    /// @return The new array.
    function arrayFrom(
        uint256 a_,
        uint256 b_,
        uint256[] memory tail_
    ) internal pure returns (uint256[] memory) {
        uint256[] memory array_ = new uint256[](2);
        assembly ("memory-safe") {
            mstore(add(array_, 0x20), a_)
            mstore(add(array_, 0x40), b_)
        }
        array_.extend(tail_);
        return array_;
    }

    function matrixFrom(
        uint256[] memory a_
    ) internal pure returns (uint256[][] memory) {
        uint256[][] memory matrix_ = new uint256[][](1);
        assembly ("memory-safe") {
            mstore(add(matrix_, 0x20), a_)
        }
        return matrix_;
    }

    /// Solidity provides no way to change the length of in-memory arrays but
    /// it also does not deallocate memory ever. It is always safe to shrink an
    /// array that has already been allocated, with the caveat that the
    /// truncated items will effectively become inaccessible regions of memory.
    /// That is to say, we deliberately "leak" the truncated items, but that is
    /// no worse than Solidity's native behaviour of leaking everything always.
    /// The array is MUTATED in place so there is no return value and there is
    /// no new allocation or copying of data either.
    /// @param array_ The array to truncate.
    /// @param newLength_ The new length of the array after truncation.
    function truncate(
        uint256[] memory array_,
        uint256 newLength_
    ) internal pure {
        require(newLength_ <= array_.length, "OOB_TRUNCATE");
        assembly ("memory-safe") {
            mstore(array_, newLength_)
        }
    }

    /// Extends `base_` with `extend_` by allocating additional `extend_.length`
    /// uints onto `base_`. Reverts if some other memory has been allocated
    /// after `base_` already, in which case it is NOT safe to copy inline.
    /// If `base_` is large this MAY be significantly more efficient than
    /// allocating `base_.length + extend_.length` for an entirely new array and
    /// copying both `base_` and `extend_` into the new array one item at a
    /// time in Solidity.
    /// The Solidity compiler MAY rearrange sibling statements in a code block
    /// EVEN IF THE OPTIMIZER IS DISABLED such that it becomes unsafe to use
    /// `extend` for memory allocated in different code blocks. It is ONLY safe
    /// to `extend` arrays that were allocated in the same lexical scope and you
    /// WILL see subtle errors that revert transactions otherwise.
    /// i.e. the `new` keyword MUST appear in the same code block as `extend`.
    /// @param base_ The base integer array that will be extended by `extend_`.
    /// @param extend_ The integer array that extends `base_`.
    function extend(
        uint256[] memory base_,
        uint256[] memory extend_
    ) internal pure {
        uint256 freeMemoryPointer_;
        assembly ("memory-safe") {
            // Solidity stores free memory pointer at 0x40
            freeMemoryPointer_ := mload(0x40)
            let baseLength_ := mload(base_)
            let extendLength_ := mload(extend_)

            // The freeMemoryPointer_ does NOT point to the end of `base_` so
            // it is NOT safe to copy `extend_` over the top of already
            // allocated memory. This happens whenever some memory is allocated
            // after `base_` is allocated but before `extend` is called.
            if gt(
                freeMemoryPointer_,
                add(base_, add(0x20, mul(0x20, baseLength_)))
            ) {
                revert(0, 0)
            }

            // Move the free memory pointer by the length of extend_, excluding
            // the length slot of extend as that will NOT be copied to `base_`.
            mstore(0x40, add(freeMemoryPointer_, mul(0x20, extendLength_)))

            // Update the length of base to be the length of base+extend.
            mstore(base_, add(baseLength_, extendLength_))
        }

        unsafeCopyValuesTo(extend_, freeMemoryPointer_);
    }

    /// Copies `inputs_` to `outputCursor_` with NO attempt to check that this
    /// is safe to do so. The caller MUST ensure that there exists allocated
    /// memory at `outputCursor_` in which it is safe and appropriate to copy
    /// ALL `inputs_` to. Anything that was already written to memory at
    /// `[outputCursor_:outputCursor_+(inputs_.length * 32 bytes)]` will be
    /// overwritten. The length of `inputs_` is NOT copied to the output
    /// location, ONLY the `uint256` values of the `inputs_` array are copied.
    /// There is no return value as memory is modified directly.
    /// @param inputs_ The input array that will be copied from EXCLUDING the
    /// length at the start of the array in memory.
    /// @param outputCursor_ Location in memory that the values will be copied
    /// to linearly.
    function unsafeCopyValuesTo(
        uint256[] memory inputs_,
        uint256 outputCursor_
    ) internal pure {
        uint256 inputCursor_;
        assembly ("memory-safe") {
            inputCursor_ := add(inputs_, 0x20)
        }
        unsafeCopyValuesTo(inputCursor_, outputCursor_, inputs_.length);
    }

    /// Copies `length_` 32 byte words from `inputCursor_` to a newly allocated
    /// uint256[] array with NO attempt to check that the inputs are sane.
    /// This function is safe in that the outputs are guaranteed to be copied
    /// to newly allocated memory so no existing data will be overwritten.
    /// This function is subtle in that the `inputCursor_` is NOT validated in
    /// any way so the caller MUST ensure it points to a sensible memory
    /// location to read (e.g. to exclude the length from input arrays etc.).
    /// @param inputCursor_ The start of the memory that will be copied to the
    /// newly allocated array.
    /// @param length_ Number of 32 byte words to copy starting at
    /// `inputCursor_` to the items of the newly allocated array.
    /// @return The newly allocated `uint256[]` array.
    function copyToNewUint256Array(
        uint256 inputCursor_,
        uint256 length_
    ) internal pure returns (uint256[] memory) {
        uint256[] memory outputs_ = new uint256[](length_);
        uint256 outputCursor_;
        assembly ("memory-safe") {
            outputCursor_ := add(outputs_, 0x20)
        }
        unsafeCopyValuesTo(inputCursor_, outputCursor_, length_);
        return outputs_;
    }

    /// Copies `length_` uint256 values starting from `inputsCursor_` to
    /// `outputCursor_` with NO attempt to check that this is safe to do so.
    /// The caller MUST ensure that there exists allocated memory at
    /// `outputCursor_` in which it is safe and appropriate to copy
    /// `length_ * 32` bytes to. Anything that was already written to memory at
    /// `[outputCursor_:outputCursor_+(length_ * 32 bytes)]` will be
    /// overwritten.
    /// There is no return value as memory is modified directly.
    /// @param inputCursor_ The starting position in memory that data will be
    /// copied from.
    /// @param outputCursor_ The starting position in memory that data will be
    /// copied to.
    /// @param length_ The number of 32 byte (i.e. `uint256`) values that will
    /// be copied.
    function unsafeCopyValuesTo(
        uint256 inputCursor_,
        uint256 outputCursor_,
        uint256 length_
    ) internal pure {
        assembly ("memory-safe") {
            for {
                let end_ := add(inputCursor_, mul(0x20, length_))
            } lt(inputCursor_, end_) {
                inputCursor_ := add(inputCursor_, 0x20)
                outputCursor_ := add(outputCursor_, 0x20)
            } {
                mstore(outputCursor_, mload(inputCursor_))
            }
        }
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

/// @title LibBytes
/// @notice Things we want to do carefully and efficiently with `bytes` in memory
/// that Solidity doesn't give us native tools for.
library LibBytes {
    /// Copy an arbitrary number of bytes from one location in memory to another.
    /// As we can only read/write bytes in 32 byte chunks we first have to loop
    /// over 32 byte values to copy then handle any unaligned remaining data. The
    /// remaining data will be appropriately masked with the existing data in the
    /// final chunk so as to not write past the desired length. Note that the
    /// final unaligned write will be more gas intensive than the prior aligned
    /// writes. The writes are completely unsafe, the caller MUST ensure that
    /// sufficient memory is allocated and reading/writing the requested number
    /// of bytes from/to the requested locations WILL NOT corrupt memory in the
    /// opinion of solidity or other subsequent read/write operations.
    /// @param inputCursor_ The starting location in memory to read from.
    /// @param outputCursor_ The starting location in memory to write to.
    /// @param remaining_ The number of bytes to read/write.
    function unsafeCopyBytesTo(
        uint256 inputCursor_,
        uint256 outputCursor_,
        uint256 remaining_
    ) internal pure {
        assembly ("memory-safe") {
            for {

            } iszero(lt(remaining_, 0x20)) {
                remaining_ := sub(remaining_, 0x20)
                inputCursor_ := add(inputCursor_, 0x20)
                outputCursor_ := add(outputCursor_, 0x20)
            } {
                mstore(outputCursor_, mload(inputCursor_))
            }

            if gt(remaining_, 0) {
                let mask_ := shr(
                    mul(remaining_, 8),
                    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
                )
                // preserve existing bytes
                mstore(
                    outputCursor_,
                    or(
                        // input
                        and(mload(inputCursor_), not(mask_)),
                        and(mload(outputCursor_), mask_)
                    )
                )
            }
        }
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.0;

import {MathUpgradeable as Math} from "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import {SafeCastUpgradeable as SafeCast} from "@openzeppelin/contracts-upgradeable/utils/math/SafeCastUpgradeable.sol";
import "../math/SaturatingMath.sol";

/// @dev The scale of all fixed point math. This is adopting the conventions of
/// both ETH (wei) and most ERC20 tokens, so is hopefully uncontroversial.
uint256 constant FP_DECIMALS = 18;
/// @dev The number `1` in the standard fixed point math scaling. Most of the
/// differences between fixed point math and regular math is multiplying or
/// dividing by `ONE` after the appropriate scaling has been applied.
uint256 constant FP_ONE = 1e18;

/// @title FixedPointMath
/// @notice Sometimes we want to do math with decimal values but all we have
/// are integers, typically uint256 integers. Floats are very complex so we
/// don't attempt to simulate them. Instead we provide a standard definition of
/// "one" as 10 ** 18 and scale everything up/down to this as fixed point math.
///
/// Overflows SATURATE rather than error, e.g. scaling max uint256 up will result
/// in max uint256. The max uint256 as decimal is roughly 1e77 so scaling values
/// comparable to 1e18 is unlikely to ever saturate in practise. For a typical
/// use case involving tokens, the entire supply of a token rescaled up a full
/// 18 decimals would still put it "only" in the region of ~1e40 which has a full
/// 30 orders of magnitude buffer before running into saturation issues. However,
/// there's no theoretical reason that a token or any other use case couldn't use
/// large numbers or extremely precise decimals that would push this library to
/// saturation point, so it MUST be treated with caution around the edge cases.
///
/// One case where values could come near the saturation/overflow point is phantom
/// overflow. This is where an overflow happens during the internal logic of some
/// operation like "fixed point multiplication" even though the final result fits
/// within uint256. The fixed point multiplication and division functions are
/// thin wrappers around Open Zeppelin's `mulDiv` function, that handles phantom
/// overflow, reducing the problems of rescaling overflow/saturation to the input
/// and output range rather than to the internal implementation details. For this
/// library that gives an additional full 18 orders of magnitude for safe fixed
/// point multiplication operations.
///
/// Note that scaling down ANY fixed point decimal also reduces the precision
/// which lead to dust or in the worst case trapped funds if subsequent
/// subtraction overflows a rounded-down number. Consider using saturating
/// subtraction for safety against previously downscaled values, and whether
/// trapped dust is a significant issue. If you need to retain full/arbitrary
/// precision in the case of downscaling DO NOT use this library.
library FixedPointMath {
    using Math for uint256;
    using SafeCast for int;
    using SaturatingMath for uint256;

    /// Scale a fixed point decimal of some scale factor to match `DECIMALS`.
    /// @param a_ Some fixed point decimal value.
    /// @param aDecimals_ The number of fixed decimals of `a_`.
    /// @return `a_` scaled to match `DECIMALS`.
    function scale18(
        uint256 a_,
        uint256 aDecimals_
    ) internal pure returns (uint256) {
        uint256 decimals_;
        if (FP_DECIMALS == aDecimals_) {
            return a_;
        } else if (FP_DECIMALS > aDecimals_) {
            unchecked {
                decimals_ = FP_DECIMALS - aDecimals_;
            }
            return a_.saturatingMul(10 ** decimals_);
        } else {
            unchecked {
                decimals_ = aDecimals_ - FP_DECIMALS;
            }
            return a_ / 10 ** decimals_;
        }
    }

    /// Scale a fixed point decimals of `DECIMALS` to some other scale.
    /// @param a_ A `DECIMALS` fixed point decimals.
    /// @param targetDecimals_ The new scale of `a_`.
    /// @return `a_` rescaled from `DECIMALS` to `targetDecimals_`.
    function scaleN(
        uint256 a_,
        uint256 targetDecimals_
    ) internal pure returns (uint256) {
        uint256 decimals_;
        if (targetDecimals_ == FP_DECIMALS) {
            return a_;
        } else if (FP_DECIMALS > targetDecimals_) {
            unchecked {
                decimals_ = FP_DECIMALS - targetDecimals_;
            }
            return a_ / 10 ** decimals_;
        } else {
            unchecked {
                decimals_ = targetDecimals_ - FP_DECIMALS;
            }
            return a_.saturatingMul(10 ** decimals_);
        }
    }

    /// Scale a fixed point decimals of `DECIMALS` that represents a ratio of
    /// a_:b_ according to the decimals of a and b that MAY NOT be `DECIMALS`.
    /// i.e. a subsequent call to `a_.fixedPointMul(ratio_)` would yield the value
    /// that it would have as though `a_` and `b_` were both `DECIMALS` and we
    /// hadn't rescaled the ratio.
    function scaleRatio(
        uint ratio_,
        uint8 aDecimals_,
        uint8 bDecimals_
    ) internal pure returns (uint) {
        return
            scaleBy(
                ratio_,
                (int(uint(bDecimals_)) - int(uint(aDecimals_))).toInt8()
            );
    }

    /// Scale a fixed point up or down by `scaleBy_` orders of magnitude.
    /// The caller MUST ensure the end result matches `DECIMALS` if other
    /// functions in this library are to work correctly.
    /// Notably `scaleBy` is a SIGNED integer so scaling down by negative OOMS
    /// is supported.
    /// @param a_ Some integer of any scale.
    /// @param scaleBy_ OOMs to scale `a_` up or down by.
    /// @return `a_` rescaled according to `scaleBy_`.
    function scaleBy(
        uint256 a_,
        int8 scaleBy_
    ) internal pure returns (uint256) {
        if (scaleBy_ == 0) {
            return a_;
        } else if (scaleBy_ > 0) {
            return a_.saturatingMul(10 ** uint8(scaleBy_));
        } else {
            uint256 posScaleDownBy_;
            unchecked {
                posScaleDownBy_ = uint8(-1 * scaleBy_);
            }
            return a_ / 10 ** posScaleDownBy_;
        }
    }

    /// Fixed point multiplication in native scale decimals.
    /// Both `a_` and `b_` MUST be `DECIMALS` fixed point decimals.
    /// @param a_ First term.
    /// @param b_ Second term.
    /// @return `a_` multiplied by `b_` to `DECIMALS` fixed point decimals.
    function fixedPointMul(
        uint256 a_,
        uint256 b_
    ) internal pure returns (uint256) {
        return a_.mulDiv(b_, FP_ONE);
    }

    /// Fixed point division in native scale decimals.
    /// Both `a_` and `b_` MUST be `DECIMALS` fixed point decimals.
    /// @param a_ First term.
    /// @param b_ Second term.
    /// @return `a_` divided by `b_` to `DECIMALS` fixed point decimals.
    function fixedPointDiv(
        uint256 a_,
        uint256 b_
    ) internal pure returns (uint256) {
        return a_.mulDiv(FP_ONE, b_);
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.0;

/// @title SaturatingMath
/// @notice Sometimes we neither want math operations to error nor wrap around
/// on an overflow or underflow. In the case of transferring assets an error
/// may cause assets to be locked in an irretrievable state within the erroring
/// contract, e.g. due to a tiny rounding/calculation error. We also can't have
/// assets underflowing and attempting to approve/transfer "infinity" when we
/// wanted "almost or exactly zero" but some calculation bug underflowed zero.
/// Ideally there are no calculation mistakes, but in guarding against bugs it
/// may be safer pragmatically to saturate arithmatic at the numeric bounds.
/// Note that saturating div is not supported because 0/0 is undefined.
library SaturatingMath {
    /// Saturating addition.
    /// @param a_ First term.
    /// @param b_ Second term.
    /// @return Minimum of a_ + b_ and max uint256.
    function saturatingAdd(
        uint256 a_,
        uint256 b_
    ) internal pure returns (uint256) {
        unchecked {
            uint256 c_ = a_ + b_;
            return c_ < a_ ? type(uint256).max : c_;
        }
    }

    /// Saturating subtraction.
    /// @param a_ Minuend.
    /// @param b_ Subtrahend.
    /// @return Maximum of a_ - b_ and 0.
    function saturatingSub(
        uint256 a_,
        uint256 b_
    ) internal pure returns (uint256) {
        unchecked {
            return a_ > b_ ? a_ - b_ : 0;
        }
    }

    /// Saturating multiplication.
    /// @param a_ First term.
    /// @param b_ Second term.
    /// @return Minimum of a_ * b_ and max uint256.
    function saturatingMul(
        uint256 a_,
        uint256 b_
    ) internal pure returns (uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being
            // zero, but the benefit is lost if 'b' is also tested.
            // https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a_ == 0) return 0;
            uint256 c_ = a_ * b_;
            return c_ / a_ != b_ ? type(uint256).max : c_;
        }
    }
}

// SPDX-License-Identifier: CAL
pragma solidity =0.8.17;

import "../../type/LibCast.sol";
import "../../type/LibConvert.sol";
import "../../array/LibUint256Array.sol";
import "./chainlink/OpChainlinkOraclePrice.sol";
import "./core/OpCall.sol";
import "./core/OpSet.sol";
import "./core/OpContext.sol";
import "./core/OpContextRow.sol";
import "./core/OpDebug.sol";
import "./core/OpDoWhile.sol";
import "./core/OpFoldContext.sol";
import "./core/OpLoopN.sol";
import "./core/OpReadMemory.sol";
import "./crypto/OpHash.sol";
import "./erc20/OpERC20BalanceOf.sol";
import "./erc20/OpERC20TotalSupply.sol";
import "./erc20/snapshot/OpERC20SnapshotBalanceOfAt.sol";
import "./erc20/snapshot/OpERC20SnapshotTotalSupplyAt.sol";
import "./erc721/OpERC721BalanceOf.sol";
import "./erc721/OpERC721OwnerOf.sol";
import "./erc1155/OpERC1155BalanceOf.sol";
import "./erc1155/OpERC1155BalanceOfBatch.sol";
import "./error/OpEnsure.sol";
import "./evm/OpBlockNumber.sol";
import "./evm/OpTimestamp.sol";
import "./list/OpExplode32.sol";
import "./math/fixedPoint/OpFixedPointScale18.sol";
import "./math/fixedPoint/OpFixedPointScale18Div.sol";
import "./math/fixedPoint/OpFixedPointScale18Mul.sol";
import "./math/fixedPoint/OpFixedPointScaleBy.sol";
import "./math/fixedPoint/OpFixedPointScaleN.sol";
import "./math/logic/OpAny.sol";
import "./math/logic/OpEagerIf.sol";
import "./math/logic/OpEqualTo.sol";
import "./math/logic/OpEvery.sol";
import "./math/logic/OpGreaterThan.sol";
import "./math/logic/OpIsZero.sol";
import "./math/logic/OpLessThan.sol";
import "./math/saturating/OpSaturatingAdd.sol";
import "./math/saturating/OpSaturatingMul.sol";
import "./math/saturating/OpSaturatingSub.sol";
import "./math/OpAdd.sol";
import "./math/OpDiv.sol";
import "./math/OpExp.sol";
import "./math/OpMax.sol";
import "./math/OpMin.sol";
import "./math/OpMod.sol";
import "./math/OpMul.sol";
import "./math/OpSub.sol";
import "./rain/IOrderBookV1/OpIOrderBookV1VaultBalance.sol";
import "./rain/ISaleV2/OpISaleV2RemainingTokenInventory.sol";
import "./rain/ISaleV2/OpISaleV2Reserve.sol";
import "./rain/ISaleV2/OpISaleV2SaleStatus.sol";
import "./rain/ISaleV2/OpISaleV2Token.sol";
import "./rain/ISaleV2/OpISaleV2TotalReserveReceived.sol";
import "./rain/IVerifyV1/OpIVerifyV1AccountStatusAtTime.sol";
import "./tier/OpITierV2Report.sol";
import "./tier/OpITierV2ReportTimeForTier.sol";
import "./tier/OpSaturatingDiff.sol";
import "./tier/OpSelectLte.sol";
import "./tier/OpUpdateTimesForTierRange.sol";

uint256 constant ALL_STANDARD_OPS_LENGTH = 58;

/// @title AllStandardOps
/// @notice RainInterpreter opcode pack to expose all other packs.
library AllStandardOps {
    using LibCast for uint256;
    using LibCast for function(uint256) pure returns (uint256);
    using LibCast for function(InterpreterState memory, uint256, StackTop)
        view
        returns (StackTop);
    using LibCast for function(InterpreterState memory, uint256, StackTop)
        pure
        returns (StackTop);
    using LibCast for function(InterpreterState memory, uint256, StackTop)
        view
        returns (StackTop)[];

    using AllStandardOps for function(IntegrityState memory, Operand, StackTop)
        view
        returns (StackTop)[ALL_STANDARD_OPS_LENGTH + 1];
    using AllStandardOps for function(
        InterpreterState memory,
        Operand,
        StackTop
    ) view returns (StackTop)[ALL_STANDARD_OPS_LENGTH + 1];

    using AllStandardOps for uint256[ALL_STANDARD_OPS_LENGTH + 1];

    using LibUint256Array for uint256[];
    using LibConvert for uint256[];
    using LibCast for uint256[];
    using LibCast for function(IntegrityState memory, Operand, StackTop)
        view
        returns (StackTop);
    using LibCast for function(IntegrityState memory, Operand, StackTop)
        pure
        returns (StackTop);
    using LibCast for function(IntegrityState memory, Operand, StackTop)
        view
        returns (StackTop)[];
    using LibCast for function(InterpreterState memory, Operand, StackTop)
        view
        returns (StackTop)[];

    /// An oddly specific conversion between a fixed and dynamic uint256 array.
    /// This is useful for the purpose of building metadata for bounds checks
    /// and dispatch of all the standard ops provided by RainInterpreter.
    /// The cast will fail if the length of the dynamic array doesn't match the
    /// first item of the fixed array; it relies on differences in memory
    /// layout in Solidity that MAY change in the future. The rollback guards
    /// against changes in Solidity memory layout silently breaking this cast.
    /// @param fixed_ The fixed size uint array to cast to a dynamic uint array.
    /// Specifically the size is fixed to match the number of standard ops.
    /// @param dynamic_ The dynamic uint array with length of the standard ops.
    function asUint256Array(
        function(IntegrityState memory, Operand, StackTop)
            view
            returns (StackTop)[ALL_STANDARD_OPS_LENGTH + 1]
            memory fixed_
    ) internal pure returns (uint256[] memory dynamic_) {
        assembly ("memory-safe") {
            dynamic_ := fixed_
        }
        require(
            dynamic_.length == ALL_STANDARD_OPS_LENGTH,
            "BAD_DYNAMIC_LENGTH"
        );
    }

    function asUint256Array(
        function(InterpreterState memory, Operand, StackTop)
            view
            returns (StackTop)[ALL_STANDARD_OPS_LENGTH + 1]
            memory fixed_
    ) internal pure returns (uint256[] memory dynamic_) {
        assembly ("memory-safe") {
            dynamic_ := fixed_
        }
        require(
            dynamic_.length == ALL_STANDARD_OPS_LENGTH,
            "BAD_DYNAMIC_LENGTH"
        );
    }

    function integrityFunctionPointers(
        function(IntegrityState memory, Operand, StackTop)
            view
            returns (StackTop)[]
            memory locals_
    )
        internal
        pure
        returns (
            function(IntegrityState memory, Operand, StackTop)
                view
                returns (StackTop)[]
                memory
        )
    {
        unchecked {
            function(IntegrityState memory, Operand, StackTop)
                view
                returns (StackTop)[ALL_STANDARD_OPS_LENGTH + 1]
                memory pointersFixed_ = [
                    ALL_STANDARD_OPS_LENGTH.asIntegrityFunctionPointer(),
                    OpChainlinkOraclePrice.integrity,
                    OpCall.integrity,
                    OpContext.integrity,
                    OpContextRow.integrity,
                    OpDebug.integrity,
                    OpDoWhile.integrity,
                    OpFoldContext.integrity,
                    OpLoopN.integrity,
                    OpReadMemory.integrity,
                    OpSet.integrity,
                    OpHash.integrity,
                    OpERC20BalanceOf.integrity,
                    OpERC20TotalSupply.integrity,
                    OpERC20SnapshotBalanceOfAt.integrity,
                    OpERC20SnapshotTotalSupplyAt.integrity,
                    OpERC721BalanceOf.integrity,
                    OpERC721OwnerOf.integrity,
                    OpERC1155BalanceOf.integrity,
                    OpERC1155BalanceOfBatch.integrity,
                    OpEnsure.integrity,
                    OpBlockNumber.integrity,
                    OpTimestamp.integrity,
                    OpExplode32.integrity,
                    OpFixedPointScale18.integrity,
                    OpFixedPointScale18Div.integrity,
                    OpFixedPointScale18Mul.integrity,
                    OpFixedPointScaleBy.integrity,
                    OpFixedPointScaleN.integrity,
                    OpAny.integrity,
                    OpEagerIf.integrity,
                    OpEqualTo.integrity,
                    OpEvery.integrity,
                    OpGreaterThan.integrity,
                    OpIsZero.integrity,
                    OpLessThan.integrity,
                    OpSaturatingAdd.integrity,
                    OpSaturatingMul.integrity,
                    OpSaturatingSub.integrity,
                    OpAdd.integrity,
                    OpDiv.integrity,
                    OpExp.integrity,
                    OpMax.integrity,
                    OpMin.integrity,
                    OpMod.integrity,
                    OpMul.integrity,
                    OpSub.integrity,
                    OpIOrderBookV1VaultBalance.integrity,
                    OpISaleV2RemainingTokenInventory.integrity,
                    OpISaleV2Reserve.integrity,
                    OpISaleV2SaleStatus.integrity,
                    OpISaleV2Token.integrity,
                    OpISaleV2TotalReserveReceived.integrity,
                    OpIVerifyV1AccountStatusAtTime.integrity,
                    OpITierV2Report.integrity,
                    OpITierV2ReportTimeForTier.integrity,
                    OpSaturatingDiff.integrity,
                    OpSelectLte.integrity,
                    OpUpdateTimesForTierRange.integrity
                ];
            uint256[] memory pointers_ = pointersFixed_.asUint256Array();
            pointers_.extend(locals_.asUint256Array());
            return pointers_.asIntegrityPointers();
        }
    }

    function opcodeFunctionPointers(
        function(InterpreterState memory, Operand, StackTop)
            view
            returns (StackTop)[]
            memory locals_
    )
        internal
        pure
        returns (
            function(InterpreterState memory, Operand, StackTop)
                view
                returns (StackTop)[]
                memory opcodeFunctionPointers_
        )
    {
        unchecked {
            function(InterpreterState memory, Operand, StackTop)
                view
                returns (StackTop)[ALL_STANDARD_OPS_LENGTH + 1]
                memory pointersFixed_ = [
                    ALL_STANDARD_OPS_LENGTH.asOpFunctionPointer(),
                    OpChainlinkOraclePrice.price,
                    OpCall.run,
                    OpContext.run,
                    OpContextRow.run,
                    OpDebug.debug,
                    OpDoWhile.run,
                    OpFoldContext.run,
                    OpLoopN.run,
                    OpReadMemory.run,
                    OpSet.run,
                    OpHash.hash,
                    OpERC20BalanceOf.balanceOf,
                    OpERC20TotalSupply.totalSupply,
                    OpERC20SnapshotBalanceOfAt.balanceOfAt,
                    OpERC20SnapshotTotalSupplyAt.totalSupplyAt,
                    OpERC721BalanceOf.balanceOf,
                    OpERC721OwnerOf.ownerOf,
                    OpERC1155BalanceOf.balanceOf,
                    OpERC1155BalanceOfBatch.balanceOfBatch,
                    OpEnsure.ensure,
                    OpBlockNumber.blockNumber,
                    OpTimestamp.timestamp,
                    OpExplode32.explode32,
                    OpFixedPointScale18.scale18,
                    OpFixedPointScale18Div.scale18Div,
                    OpFixedPointScale18Mul.scale18Mul,
                    OpFixedPointScaleBy.scaleBy,
                    OpFixedPointScaleN.scaleN,
                    OpAny.any,
                    OpEagerIf.eagerIf,
                    OpEqualTo.equalTo,
                    OpEvery.every,
                    OpGreaterThan.greaterThan,
                    OpIsZero.isZero,
                    OpLessThan.lessThan,
                    OpSaturatingAdd.saturatingAdd,
                    OpSaturatingMul.saturatingMul,
                    OpSaturatingSub.saturatingSub,
                    OpAdd.add,
                    OpDiv.div,
                    OpExp.exp,
                    OpMax.max,
                    OpMin.min,
                    OpMod.mod,
                    OpMul.mul,
                    OpSub.sub,
                    OpIOrderBookV1VaultBalance.run,
                    OpISaleV2RemainingTokenInventory.run,
                    OpISaleV2Reserve.run,
                    OpISaleV2SaleStatus.run,
                    OpISaleV2Token.run,
                    OpISaleV2TotalReserveReceived.run,
                    OpIVerifyV1AccountStatusAtTime.run,
                    OpITierV2Report.report,
                    OpITierV2ReportTimeForTier.reportTimeForTier,
                    OpSaturatingDiff.saturatingDiff,
                    OpSelectLte.selectLte,
                    OpUpdateTimesForTierRange.updateTimesForTierRange
                ];
            uint256[] memory pointers_ = pointersFixed_.asUint256Array();
            pointers_.extend(locals_.asUint256Array());
            opcodeFunctionPointers_ = pointers_.asOpcodeFunctionPointers();
        }
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

import "../interpreter/run/LibStackTop.sol";
import "../interpreter/run/LibInterpreterState.sol";
import "../interpreter/deploy/LibIntegrityState.sol";

/// @title LibCast
/// @notice Additional type casting logic that the Solidity compiler doesn't
/// give us by default. A type cast (vs. conversion) is considered one where the
/// structure is unchanged by the cast. The cast does NOT (can't) check that the
/// input is a valid output, for example any integer MAY be cast to a function
/// pointer but almost all integers are NOT valid function pointers. It is the
/// calling context that MUST ensure the validity of the data, the cast will
/// merely retype the data in place, generally without additional checks.
/// As most structures in solidity have the same memory structure as a `uint256`
/// or fixed/dynamic array of `uint256` there are many conversions that can be
/// done with near zero or minimal overhead.
library LibCast {
    /// Retype an integer to an opcode function pointer.
    /// @param u_ The integer to cast to an opcode function pointer.
    /// @return fn_ The opcode function pointer.
    function asOpFunctionPointer(
        uint256 u_
    )
        internal
        pure
        returns (
            function(InterpreterState memory, Operand, StackTop)
                view
                returns (StackTop) fn_
        )
    {
        assembly ("memory-safe") {
            fn_ := u_
        }
    }

    /// Retype an array of integers to an array of opcode function pointers.
    /// @param us_ The array of integers to cast to an array of opcode fuction
    /// pointers.
    /// @return fns_ The array of opcode function pointers.
    function asOpcodeFunctionPointers(
        uint256[] memory us_
    )
        internal
        pure
        returns (
            function(InterpreterState memory, Operand, StackTop)
                view
                returns (StackTop)[]
                memory fns_
        )
    {
        assembly ("memory-safe") {
            fns_ := us_
        }
    }

    /// Retype an integer to an integrity function pointer.
    /// @param u_ The integer to cast to an integrity function pointer.
    /// @return fn_ The integrity function pointer.
    function asIntegrityFunctionPointer(
        uint256 u_
    )
        internal
        pure
        returns (
            function(IntegrityState memory, Operand, StackTop)
                internal
                view
                returns (StackTop) fn_
        )
    {
        assembly ("memory-safe") {
            fn_ := u_
        }
    }

    /// Retype an integer to a pointer to the interpreter eval function.
    /// @param u_ The integer to cast to the eval function.
    /// @return fn_ The eval function.
    function asEvalFunctionPointer(
        uint256 u_
    )
        internal
        pure
        returns (
            function(InterpreterState memory, SourceIndex, StackTop)
                view
                returns (StackTop) fn_
        )
    {
        assembly ("memory-safe") {
            fn_ := u_
        }
    }

    /// Retype a stack move function pointer to an integer.
    /// Provided the origin of the function pointer is solidity and NOT yul, the
    /// returned integer will be valid to run if retyped back via yul. If the
    /// origin of the function pointer is yul then we cannot guarantee anything
    /// about the validity beyond the correctness of the yul code in question.
    ///
    /// Function pointers as integers are NOT portable across contracts as the
    /// code in different contracts is different so function pointers will point
    /// to a different, incompatible part of the code.
    ///
    /// Function pointers as integers lose the information about their signature
    /// so MUST ONLY be called in an appropriate context once restored.
    /// @param fn_ The stack move function pointer to integerify.
    /// @return u_ The integer of the function pointer.
    function asUint256(
        function(uint256) view returns (uint256) fn_
    ) internal pure returns (uint256 u_) {
        assembly ("memory-safe") {
            u_ := fn_
        }
    }

    function asUint256(
        function(IntegrityState memory, Operand, StackTop)
            internal
            view
            returns (StackTop) fn_
    ) internal pure returns (uint256 u_) {
        assembly ("memory-safe") {
            u_ := fn_
        }
    }

    function asUint256Array(
        function(IntegrityState memory, Operand, StackTop)
            internal
            view
            returns (StackTop)[]
            memory fns_
    ) internal pure returns (uint256[] memory us_) {
        assembly ("memory-safe") {
            us_ := fns_
        }
    }

    function asUint256(bool bool_) internal pure returns (uint256 u_) {
        assembly ("memory-safe") {
            u_ := bool_
        }
    }

    function asUint256(
        function(InterpreterState memory, SourceIndex, StackTop)
            view
            returns (StackTop) fn_
    ) internal pure returns (uint256 u_) {
        assembly ("memory-safe") {
            u_ := fn_
        }
    }

    function asUint256Array(
        function(InterpreterState memory, Operand, StackTop)
            view
            returns (StackTop)[]
            memory fns_
    ) internal pure returns (uint256[] memory us_) {
        assembly ("memory-safe") {
            us_ := fns_
        }
    }

    function asUint256Array(
        function(uint256) pure returns (uint256)[] memory fns_
    ) internal pure returns (uint256[] memory us_) {
        assembly ("memory-safe") {
            us_ := fns_
        }
    }

    function asAddresses(
        uint256[] memory us_
    ) internal pure returns (address[] memory addresses_) {
        assembly ("memory-safe") {
            addresses_ := us_
        }
    }

    function asIntegrityPointers(
        uint256[] memory us_
    )
        internal
        pure
        returns (
            function(IntegrityState memory, Operand, StackTop)
                view
                returns (StackTop)[]
                memory fns_
        )
    {
        assembly ("memory-safe") {
            fns_ := us_
        }
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

import "../run/IInterpreterV1.sol";
import "../deploy/IExpressionDeployerV1.sol";
import "./LibStackTop.sol";
import "../../type/LibCast.sol";
import "../../type/LibConvert.sol";
import "../../array/LibUint256Array.sol";
import "../../memory/LibMemorySize.sol";
import {SafeCastUpgradeable as SafeCast} from "@openzeppelin/contracts-upgradeable/utils/math/SafeCastUpgradeable.sol";
import "../../kv/LibMemoryKV.sol";
import "hardhat/console.sol";

enum DebugStyle {
    Stack,
    Constant,
    Context,
    Source
}

type FullyQualifiedNamespace is uint256;

/// Everything required to evaluate and track the state of a Rain expression.
/// As this is a struct it will be in memory when passed to `RainInterpreter` and so
/// will be modified by reference internally. This is important for gas
/// efficiency; the stack, arguments and stackIndex will likely be mutated by
/// the running expression.
/// @param stackIndex Opcodes write to the stack at the stack index and can
/// consume from the stack by decrementing the index and reading between the
/// old and new stack index.
/// IMPORANT: The stack is never zeroed out so the index must be used to
/// find the "top" of the stack as the result of an `eval`.
/// @param stack Stack is the general purpose runtime state that opcodes can
/// read from and write to according to their functionality.
/// @param sources Sources available to be executed by `eval`.
/// Notably `ZIPMAP` can also select a source to execute by index.
/// @param constants Constants that can be copied to the stack by index by
/// `VAL`.
/// @param arguments `ZIPMAP` populates arguments which can be copied to the
/// stack by `VAL`.
struct InterpreterState {
    StackTop stackBottom;
    StackTop constantsBottom;
    MemoryKV stateKV;
    FullyQualifiedNamespace namespace;
    uint256[][] context;
    bytes[] compiledSources;
}

string constant DEBUG_DELIMETER = "~~~";

library LibInterpreterState {
    using SafeCast for uint256;
    using LibMemorySize for uint256;
    using LibMemorySize for uint256[];
    using LibMemorySize for bytes;
    using LibUint256Array for uint256[];
    using LibUint256Array for uint256;
    using LibInterpreterState for InterpreterState;
    using LibStackTop for uint256[];
    using LibStackTop for StackTop;
    using LibStackTop for bytes;
    using LibCast for uint256;
    using LibCast for function(InterpreterState memory, SourceIndex, StackTop)
        view
        returns (StackTop);
    using LibCast for function(InterpreterState memory, Operand, StackTop)
        view
        returns (StackTop)[];
    using LibConvert for uint256[];

    function debugArray(uint256[] memory array_) internal view {
        console.log(DEBUG_DELIMETER);
        for (uint256 i_ = 0; i_ < array_.length; i_++) {
            console.log(i_, array_[i_]);
        }
        console.log(DEBUG_DELIMETER);
    }

    function debugStack(
        StackTop stackBottom_,
        StackTop stackTop_
    ) internal view returns (StackTop) {
        uint256 length_ = stackBottom_.toIndex(stackTop_);
        debugArray(
            StackTop.unwrap(stackTop_.down(length_)).copyToNewUint256Array(
                length_
            )
        );
        return stackTop_;
    }

    function debugStack(
        InterpreterState memory state_,
        StackTop stackTop_
    ) internal view returns (StackTop) {
        return debugStack(state_.stackBottom, stackTop_);
    }

    /// Console log various aspects of the Interpreter state.
    /// Gas intensive and relies on hardhat console so not intended for
    /// production but great for debugging Rain expressions.
    function debug(
        InterpreterState memory state_,
        StackTop stackTop_,
        DebugStyle debugStyle_
    ) internal view returns (StackTop) {
        if (debugStyle_ == DebugStyle.Source) {
            for (uint256 i_ = 0; i_ < state_.compiledSources.length; i_++) {
                console.logBytes(state_.compiledSources[i_]);
            }
        } else {
            if (debugStyle_ == DebugStyle.Stack) {
                state_.debugStack(stackTop_);
            } else if (debugStyle_ == DebugStyle.Constant) {
                debugArray(state_.constantsBottom.down().asUint256Array());
            } else {
                for (uint256 i_ = 0; i_ < state_.context.length; i_++) {
                    debugArray(state_.context[i_]);
                }
            }
        }
        return stackTop_;
    }

    function serialize(
        StateConfig memory config_,
        uint256 stackLength_,
        bytes memory opcodeFunctionPointers_
    ) internal pure returns (bytes memory) {
        unchecked {
            uint256 size_ = 0;
            size_ += stackLength_.size();
            size_ += config_.constants.size();
            for (uint256 i_ = 0; i_ < config_.sources.length; i_++) {
                size_ += config_.sources[i_].size();
            }
            bytes memory serialized_ = new bytes(size_);
            StackTop cursor_ = serialized_.asStackTop().up();

            // Copy stack length.
            cursor_ = cursor_.push(stackLength_);

            // Then the constants.
            cursor_ = cursor_.pushWithLength(config_.constants);

            // Last the sources.
            bytes memory source_;
            for (uint256 i_ = 0; i_ < config_.sources.length; i_++) {
                source_ = config_.sources[i_];
                compile(source_, opcodeFunctionPointers_);
                cursor_ = cursor_.unalignedPushWithLength(source_);
            }
            return serialized_;
        }
    }

    function deserialize(
        bytes memory serialized_
    ) internal pure returns (InterpreterState memory) {
        unchecked {
            InterpreterState memory state_;

            // Context will probably be overridden by the caller according to the
            // context scratch that we deserialize so best to just set it empty
            // here.
            state_.context = new uint256[][](0);

            StackTop cursor_ = serialized_.asStackTop().up();
            // The end of processing is the end of the state bytes.
            StackTop end_ = cursor_.upBytes(cursor_.peek());

            // Read the stack length and build a stack.
            cursor_ = cursor_.up();
            uint256 stackLength_ = cursor_.peek();

            // The stack is never stored in stack bytes so we allocate a new
            // array for it with length as per the indexes and point the state
            // at it.
            uint256[] memory stack_ = new uint256[](stackLength_);
            state_.stackBottom = stack_.asStackTopUp();

            // Reference the constants array and move cursor past it.
            cursor_ = cursor_.up();
            state_.constantsBottom = cursor_;
            cursor_ = cursor_.up(cursor_.peek());

            // Rebuild the sources array.
            uint256 i_ = 0;
            StackTop lengthCursor_ = cursor_;
            uint256 sourcesLength_ = 0;
            while (StackTop.unwrap(lengthCursor_) < StackTop.unwrap(end_)) {
                lengthCursor_ = lengthCursor_
                    .upBytes(lengthCursor_.peekUp())
                    .up();
                sourcesLength_++;
            }
            state_.compiledSources = new bytes[](sourcesLength_);
            while (StackTop.unwrap(cursor_) < StackTop.unwrap(end_)) {
                state_.compiledSources[i_] = cursor_.asBytes();
                cursor_ = cursor_.upBytes(cursor_.peekUp()).up();
                i_++;
            }
            return state_;
        }
    }

    /// Given a source in opcodes compile to an equivalent source with real
    /// function pointers for a given Interpreter contract. The "compilation"
    /// involves simply replacing the opcode with the pointer at the index of
    /// the opcode. i.e. opcode 4 will be replaced with `pointers_[4]`.
    /// Relies heavily on the integrity checks ensuring opcodes used are not OOB
    /// and that the pointers provided are valid and in the correct order.
    /// Hopefully it goes without saying that the list of pointers MUST NOT be
    /// user defined, otherwise any source can be compiled with a completely
    /// different mapping between opcodes and dispatched functions.
    function compile(
        bytes memory source_,
        bytes memory pointers_
    ) internal pure {
        assembly ("memory-safe") {
            for {
                let replaceMask_ := 0xFFFF
                let preserveMask_ := not(replaceMask_)
                let sourceLength_ := mload(source_)
                let pointersBottom_ := add(pointers_, 2)
                let cursor_ := add(source_, 2)
                let end_ := add(source_, sourceLength_)
            } lt(cursor_, end_) {
                cursor_ := add(cursor_, 4)
            } {
                let data_ := mload(cursor_)
                let pointer_ := and(
                    replaceMask_,
                    mload(
                        add(pointersBottom_, mul(2, and(data_, replaceMask_)))
                    )
                )
                mstore(cursor_, or(and(data_, preserveMask_), pointer_))
            }
        }
    }

    /// Evaluates a Rain expression.
    /// The main workhorse of the rain Interpreter, `eval` runs any core opcodes
    /// and dispatches anything it is unaware of to the implementing contract.
    /// For an expression to be useful the implementing contract must override
    /// `applyOp` and dispatch non-core opcodes to domain specific logic. This
    /// could be mathematical operations for a calculator, tier reports for
    /// a membership combinator, entitlements for a minting curve, etc.
    ///
    /// Everything required to coordinate the execution of a Rain expression to
    /// completion is contained in the `State`. The context and source index
    /// are provided so the caller can provide additional data and kickoff the
    /// opcode dispatch from the correct source in `sources`.
    function eval(
        InterpreterState memory state_,
        SourceIndex sourceIndex_,
        StackTop stackTop_
    ) internal view returns (StackTop) {
        unchecked {
            uint256 cursor_;
            uint256 end_;
            assembly ("memory-safe") {
                cursor_ := mload(
                    add(
                        mload(add(state_, 0xA0)),
                        add(0x20, mul(0x20, sourceIndex_))
                    )
                )
                end_ := add(cursor_, mload(cursor_))
            }

            // Loop until complete.
            while (cursor_ < end_) {
                function(InterpreterState memory, Operand, StackTop)
                    internal
                    view
                    returns (StackTop) fn_;
                Operand operand_;
                cursor_ += 4;
                {
                    uint256 op_;
                    assembly ("memory-safe") {
                        op_ := mload(cursor_)
                        operand_ := and(op_, 0xFFFF)
                        fn_ := and(shr(16, op_), 0xFFFF)
                    }
                }
                stackTop_ = fn_(state_, operand_, stackTop_);
            }
            return stackTop_;
        }
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

/// @title LibConvert
/// @notice Type conversions that require additional structural changes to
/// complete safely. These are NOT mere type casts and involve additional
/// reads and writes to complete, such as recalculating the length of an array.
/// The convention "toX" is adopted from Rust to imply the additional costs and
/// consumption of the source to produce the target.
library LibConvert {
    /// Convert an array of integers to `bytes` data. This requires modifying
    /// the length in situ as the integer array length is measured in 32 byte
    /// increments while the length of `bytes` is the literal number of bytes.
    /// @return bytes_ The integer array converted to `bytes` data.
    function toBytes(
        uint256[] memory is_
    ) internal pure returns (bytes memory bytes_) {
        assembly ("memory-safe") {
            bytes_ := is_
            // Length in bytes is 32x the length in uint256
            mstore(bytes_, mul(0x20, mload(bytes_)))
        }
    }

    function unsafeTo16BitBytes(
        uint256[] memory is_
    ) internal pure returns (bytes memory) {
        unchecked {
            // We will keep 2 bytes (16 bits) from each integer.
            bytes memory bytes_ = new bytes(is_.length * 2);
            assembly ("memory-safe") {
                let replaceMask_ := 0xFFFF
                let preserveMask_ := not(replaceMask_)
                for {
                    let cursor_ := add(is_, 0x20)
                    let end_ := add(cursor_, mul(mload(is_), 0x20))
                    let bytesCursor_ := add(bytes_, 0x02)
                } lt(cursor_, end_) {
                    cursor_ := add(cursor_, 0x20)
                    bytesCursor_ := add(bytesCursor_, 0x02)
                } {
                    let data_ := mload(bytesCursor_)
                    mstore(
                        bytesCursor_,
                        or(and(preserveMask_, data_), mload(cursor_))
                    )
                }
            }
            return bytes_;
        }
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.10;

/// @title LibMemorySize
/// @notice Reports the size in bytes of type data that represents contigious
/// regions of memory. Pointers to regions of memory that may not be congigious
/// are not supported, e.g. fields on structs may point to dynamic data that is
/// separate to the struct. Length slots for dynamic data are included in the
/// size and the size is always measured in bytes.
library LibMemorySize {
    /// Reports the size of a `uint256` in bytes. Is always 32.
    /// @return 32.
    function size(uint256) internal pure returns (uint256) {
        return 0x20;
    }

    /// Reports the size of a `uint256[]` in bytes. Is the size of the length
    /// slot (32 bytes) plus the length of the array multiplied by 32 bytes per
    /// item.
    /// @return The size of the array data including its length slot size.
    function size(uint256[] memory array_) internal pure returns (uint256) {
        unchecked {
            return 0x20 + (array_.length * 0x20);
        }
    }

    /// Reports the size of `bytes` data. Is the size of the length slot
    /// (32 bytes) plus the number of bytes as per its length.
    /// @return The size of the `bytes` data including its length slot size.
    function size(bytes memory bytes_) internal pure returns (uint256) {
        unchecked {
            return 0x20 + bytes_.length;
        }
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

import "../math/Binary.sol";

type MemoryKV is uint;
type MemoryKVKey is uint;
type MemoryKVPtr is uint;
type MemoryKVVal is uint;

library LibMemoryKV {
    function readPtrVal(MemoryKVPtr ptr_) internal pure returns (MemoryKVVal) {
        // This is ALWAYS a bug. It means the caller did not check if the ptr is
        // nonzero before trying to read from it.
        require(MemoryKVPtr.unwrap(ptr_) > 0, "INVALID_PTR");
        MemoryKVVal v_;
        assembly ("memory-safe") {
            v_ := mload(add(ptr_, 0x20))
        }
        return v_;
    }

    function getPtr(
        MemoryKV kv_,
        MemoryKVKey k_
    ) internal pure returns (MemoryKVPtr) {
        uint mask_ = MASK_16BIT;
        MemoryKVPtr ptr_;
        assembly ("memory-safe") {
            // loop until k found or give up if ptr is zero
            for {
                ptr_ := and(kv_, mask_)
            } iszero(iszero(ptr_)) {
                ptr_ := mload(add(ptr_, 0x40))
            } {
                if eq(k_, mload(ptr_)) {
                    break
                }
            }
        }
        return ptr_;
    }

    function setVal(
        MemoryKV kv_,
        MemoryKVKey k_,
        MemoryKVVal v_
    ) internal pure returns (MemoryKV) {
        MemoryKVPtr ptr_ = getPtr(kv_, k_);
        uint mask_ = MASK_16BIT;
        // update
        if (MemoryKVPtr.unwrap(ptr_) > 0) {
            assembly ("memory-safe") {
                mstore(add(ptr_, 0x20), v_)
            }
        }
        // insert
        else {
            assembly ("memory-safe") {
                // allocate new memory
                ptr_ := mload(0x40)
                mstore(0x40, add(ptr_, 0x60))
                // set k/v/ptr
                mstore(ptr_, k_)
                mstore(add(ptr_, 0x20), v_)
                mstore(add(ptr_, 0x40), and(kv_, mask_))
                // kv must point to new insertion and update array len
                kv_ := or(
                    // inc len by 2
                    shl(16, add(shr(16, kv_), 2)),
                    // set ptr
                    ptr_
                )
            }
        }
        return kv_;
    }

    function toUint256Array(
        MemoryKV kv_
    ) internal pure returns (uint[] memory) {
        unchecked {
            uint ptr_ = MemoryKV.unwrap(kv_) & MASK_16BIT;
            uint length_ = MemoryKV.unwrap(kv_) >> 16;
            uint[] memory arr_ = new uint[](length_);
            assembly ("memory-safe") {
                for {
                    let cursor_ := add(arr_, 0x20)
                    let end_ := add(cursor_, mul(mload(arr_), 0x20))
                } lt(cursor_, end_) {
                    cursor_ := add(cursor_, 0x20)
                    ptr_ := mload(add(ptr_, 0x40))
                } {
                    // key
                    mstore(cursor_, mload(ptr_))
                    cursor_ := add(cursor_, 0x20)
                    // value
                    mstore(cursor_, mload(add(ptr_, 0x20)))
                }
            }
            return arr_;
        }
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

/// @dev Binary 1.
uint constant B_1 = 2 ** 1 - 1;
/// @dev Binary 11.
uint constant B_11 = 2 ** 2 - 1;
/// @dev Binary 111.
uint constant B_111 = 2 ** 3 - 1;
/// @dev Binary 1111.
uint constant B_1111 = 2 ** 4 - 1;
/// @dev Binary 11111.
uint constant B_11111 = 2 ** 5 - 1;
/// @dev Binary 111111.
uint constant B_111111 = 2 ** 6 - 1;
/// @dev Binary 1111111.
uint constant B_1111111 = 2 ** 7 - 1;
/// @dev Binary 11111111.
uint constant B_11111111 = 2 ** 8 - 1;
/// @dev Binary 111111111.
uint constant B_111111111 = 2 ** 9 - 1;
/// @dev Binary 1111111111.
uint constant B_1111111111 = 2 ** 10 - 1;
/// @dev Binary 11111111111.
uint constant B_11111111111 = 2 ** 11 - 1;
/// @dev Binary 111111111111.
uint constant B_111111111111 = 2 ** 12 - 1;
/// @dev Binary 1111111111111.
uint constant B_1111111111111 = 2 ** 13 - 1;
/// @dev Binary 11111111111111.
uint constant B_11111111111111 = 2 ** 14 - 1;
/// @dev Binary 111111111111111.
uint constant B_111111111111111 = 2 ** 15 - 1;
/// @dev Binary 1111111111111111.
uint constant B_1111111111111111 = 2 ** 16 - 1;

/// @dev Bitmask for 1 bit.
uint constant MASK_1BIT = B_1;
/// @dev Bitmask for 2 bits.
uint constant MASK_2BIT = B_11;
/// @dev Bitmask for 3 bits.
uint constant MASK_3BIT = B_111;
/// @dev Bitmask for 4 bits.
uint constant MASK_4BIT = B_1111;
/// @dev Bitmask for 5 bits.
uint constant MASK_5BIT = B_11111;
/// @dev Bitmask for 6 bits.
uint constant MASK_6BIT = B_111111;
/// @dev Bitmask for 7 bits.
uint constant MASK_7BIT = B_1111111;
/// @dev Bitmask for 8 bits.
uint constant MASK_8BIT = B_11111111;
/// @dev Bitmask for 9 bits.
uint constant MASK_9BIT = B_111111111;
/// @dev Bitmask for 10 bits.
uint constant MASK_10BIT = B_1111111111;
/// @dev Bitmask for 11 bits.
uint constant MASK_11BIT = B_11111111111;
/// @dev Bitmask for 12 bits.
uint constant MASK_12BIT = B_111111111111;
/// @dev Bitmask for 13 bits.
uint constant MASK_13BIT = B_1111111111111;
/// @dev Bitmask for 14 bits.
uint constant MASK_14BIT = B_11111111111111;
/// @dev Bitmask for 15 bits.
uint constant MASK_15BIT = B_111111111111111;
/// @dev Bitmask for 16 bits.
uint constant MASK_16BIT = B_1111111111111111;

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

import "../run/LibStackTop.sol";
import {MathUpgradeable as Math} from "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";

import "../run/IInterpreterV1.sol";

struct IntegrityState {
    // Sources first as we read it in assembly.
    bytes[] sources;
    uint256 constantsLength;
    StackTop stackBottom;
    StackTop stackMaxTop;
    function(IntegrityState memory, Operand, StackTop)
        view
        returns (StackTop)[] integrityFunctionPointers;
}

library LibIntegrityState {
    using LibIntegrityState for IntegrityState;
    using LibStackTop for StackTop;
    using Math for uint256;

    function syncStackMaxTop(
        IntegrityState memory integrityState_,
        StackTop stackTop_
    ) internal pure {
        if (
            StackTop.unwrap(stackTop_) >
            StackTop.unwrap(integrityState_.stackMaxTop)
        ) {
            integrityState_.stackMaxTop = stackTop_;
        }
    }

    function ensureIntegrity(
        IntegrityState memory integrityState_,
        SourceIndex sourceIndex_,
        StackTop stackTop_,
        uint minStackOutputs_
    ) internal view returns (StackTop) {
        unchecked {
            uint256 cursor_;
            uint256 end_;
            assembly ("memory-safe") {
                cursor_ := mload(
                    add(
                        mload(integrityState_),
                        add(0x20, mul(0x20, sourceIndex_))
                    )
                )
                end_ := add(cursor_, mload(cursor_))
            }

            // Loop until complete.
            while (cursor_ < end_) {
                uint256 opcode_;
                Operand operand_;
                cursor_ += 4;
                assembly ("memory-safe") {
                    let op_ := mload(cursor_)
                    operand_ := and(op_, 0xFFFF)
                    opcode_ := and(shr(16, op_), 0xFFFF)
                }
                // We index into the function pointers here to ensure that any
                // opcodes that we don't have a pointer for will error.
                stackTop_ = integrityState_.integrityFunctionPointers[opcode_](
                    integrityState_,
                    operand_,
                    stackTop_
                );
            }
            require(
                minStackOutputs_ <=
                    integrityState_.stackBottom.toIndex(stackTop_),
                "MIN_FINAL_STACK"
            );
            return stackTop_;
        }
    }

    function push(
        IntegrityState memory integrityState_,
        StackTop stackTop_
    ) internal pure returns (StackTop stackTopAfter_) {
        stackTopAfter_ = stackTop_.up();
        integrityState_.syncStackMaxTop(stackTopAfter_);
    }

    function push(
        IntegrityState memory integrityState_,
        StackTop stackTop_,
        uint256 n_
    ) internal pure returns (StackTop stackTopAfter_) {
        stackTopAfter_ = stackTop_.up(n_);
        integrityState_.syncStackMaxTop(stackTopAfter_);
    }

    function popUnderflowCheck(
        IntegrityState memory integrityState_,
        StackTop stackTop_
    ) internal pure {
        require(
            // Stack bottom may be non-zero so check we are above it.
            (StackTop.unwrap(stackTop_) >=
                StackTop.unwrap(integrityState_.stackBottom)) &&
                // If we underflowed zero then we will be above the stack max
                // top. Assumes that at least 1 item was popped so we can do a
                // strict inequality check here.
                (StackTop.unwrap(stackTop_) <
                    StackTop.unwrap(integrityState_.stackMaxTop)),
            "STACK_UNDERFLOW"
        );
    }

    function pop(
        IntegrityState memory integrityState_,
        StackTop stackTop_
    ) internal pure returns (StackTop stackTopAfter_) {
        stackTopAfter_ = stackTop_.down();
        integrityState_.popUnderflowCheck(stackTopAfter_);
    }

    function pop(
        IntegrityState memory integrityState_,
        StackTop stackTop_,
        uint256 n_
    ) internal pure returns (StackTop) {
        if (n_ > 0) {
            stackTop_ = stackTop_.down(n_);
            integrityState_.popUnderflowCheck(stackTop_);
        }
        return stackTop_;
    }

    function applyFnN(
        IntegrityState memory integrityState_,
        StackTop stackTop_,
        function(uint256, uint256) internal view returns (uint256),
        uint256 n_
    ) internal pure returns (StackTop) {
        return integrityState_.push(integrityState_.pop(stackTop_, n_));
    }

    function applyFnN(
        IntegrityState memory integrityState_,
        StackTop stackTop_,
        function(uint256) internal view,
        uint256 n_
    ) internal pure returns (StackTop) {
        return integrityState_.pop(stackTop_, n_);
    }

    function applyFn(
        IntegrityState memory integrityState_,
        StackTop stackTop_,
        function(uint256) internal view returns (uint256)
    ) internal pure returns (StackTop) {
        return integrityState_.push(integrityState_.pop(stackTop_));
    }

    function applyFn(
        IntegrityState memory integrityState_,
        StackTop stackTop_,
        function(Operand, uint256) internal view returns (uint256)
    ) internal pure returns (StackTop) {
        return integrityState_.push(integrityState_.pop(stackTop_));
    }

    function applyFn(
        IntegrityState memory integrityState_,
        StackTop stackTop_,
        function(uint256, uint256) internal view
    ) internal pure returns (StackTop) {
        return integrityState_.pop(stackTop_, 2);
    }

    function applyFn(
        IntegrityState memory integrityState_,
        StackTop stackTop_,
        function(uint256, uint256) internal view returns (uint256)
    ) internal pure returns (StackTop) {
        return integrityState_.push(integrityState_.pop(stackTop_, 2));
    }

    function applyFn(
        IntegrityState memory integrityState_,
        StackTop stackTop_,
        function(Operand, uint256, uint256) internal view returns (uint256)
    ) internal pure returns (StackTop) {
        return integrityState_.push(integrityState_.pop(stackTop_, 2));
    }

    function applyFn(
        IntegrityState memory integrityState_,
        StackTop stackTop_,
        function(uint256, uint256, uint256) internal view returns (uint256)
    ) internal pure returns (StackTop) {
        return integrityState_.push(integrityState_.pop(stackTop_, 3));
    }

    function applyFn(
        IntegrityState memory integrityState_,
        StackTop stackTop_,
        function(uint256, uint256, uint256, uint)
            internal
            view
            returns (uint256)
    ) internal pure returns (StackTop) {
        return integrityState_.push(integrityState_.pop(stackTop_, 4));
    }

    function applyFn(
        IntegrityState memory integrityState_,
        StackTop stackTop_,
        function(uint256[] memory) internal view returns (uint256),
        uint256 length_
    ) internal pure returns (StackTop) {
        return integrityState_.push(integrityState_.pop(stackTop_, length_));
    }

    function applyFn(
        IntegrityState memory integrityState_,
        StackTop stackTop_,
        function(uint256, uint256, uint256[] memory)
            internal
            view
            returns (uint256),
        uint256 length_
    ) internal pure returns (StackTop) {
        unchecked {
            return
                integrityState_.push(
                    integrityState_.pop(stackTop_, length_ + 2)
                );
        }
    }

    function applyFn(
        IntegrityState memory integrityState_,
        StackTop stackTop_,
        function(uint256, uint256, uint256, uint256[] memory)
            internal
            view
            returns (uint256),
        uint256 length_
    ) internal pure returns (StackTop) {
        unchecked {
            return
                integrityState_.push(
                    integrityState_.pop(stackTop_, length_ + 3)
                );
        }
    }

    function applyFn(
        IntegrityState memory integrityState_,
        StackTop stackTop_,
        function(uint256, uint256[] memory, uint256[] memory)
            internal
            view
            returns (uint256[] memory),
        uint256 length_
    ) internal pure returns (StackTop) {
        unchecked {
            return
                integrityState_.push(
                    integrityState_.pop(stackTop_, length_ * 2 + 1),
                    length_
                );
        }
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

import {LibChainlink} from "../../../chainlink/LibChainlink.sol";
import "../../run/LibStackTop.sol";
import "../../run/LibInterpreterState.sol";
import "../../deploy/LibIntegrityState.sol";

/// @title OpChainlinkOraclePrice
/// @notice Opcode for chainlink oracle prices.
library OpChainlinkOraclePrice {
    using LibStackTop for StackTop;
    using LibIntegrityState for IntegrityState;

    function _price(
        uint256 feed_,
        uint256 staleAfter_
    ) internal view returns (uint256) {
        return LibChainlink.price(address(uint160(feed_)), staleAfter_);
    }

    function integrity(
        IntegrityState memory integrityState_,
        Operand,
        StackTop stackTop_
    ) internal pure returns (StackTop) {
        return integrityState_.applyFn(stackTop_, _price);
    }

    function price(
        InterpreterState memory,
        Operand,
        StackTop stackTop_
    ) internal view returns (StackTop) {
        return stackTop_.applyFn(_price);
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "../math/FixedPointMath.sol";

library LibChainlink {
    using SafeCast for int256;
    using FixedPointMath for uint256;

    function price(
        address feed_,
        uint256 staleAfter_
    ) internal view returns (uint256) {
        (, int256 answer_, , uint256 updatedAt_, ) = AggregatorV3Interface(
            feed_
        ).latestRoundData();
        require(answer_ > 0, "MIN_BASE_PRICE");
        // Checked time comparison ensures no updates from the future as that
        // would overflow, and no stale prices.
        // solhint-disable-next-line not-rely-on-time
        require(block.timestamp - updatedAt_ < staleAfter_, "STALE_PRICE");

        // Safely cast the answer to uint and scale it to 18 decimal FP.
        return
            answer_.toUint256().scale18(
                AggregatorV3Interface(feed_).decimals()
            );
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

import {IERC20Upgradeable as IERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "../../run/LibStackTop.sol";
import "../../run/LibInterpreterState.sol";
import "../../../array/LibUint256Array.sol";
import "../../deploy/LibIntegrityState.sol";
import "../../../math/Binary.sol";

/// @title OpCall
/// @notice Opcode for calling eval with a new scope. The construction of this
/// scope is split across integrity and runtime responsibilities. When the
/// integrity checks are done the expression being called has all its integrity
/// logic run, recursively if needed. The integrity checks are run against the
/// integrity state as it is but with the stack bottom set below the inputs to
/// the called source. This ensures that the sub-integrity checks do not
/// underflow what they perceive as a fresh stack, and it ensures that we set the
/// stack length long enough to cover all sub-executions as a single array in
/// memory. At runtime we trust the integrity checks have allocated enough runway
/// in the stack for all our recursive sub-calls so we simply move the stack
/// bottom in the state below the inputs during the call and move it back to
/// where it was after the call. Notably this means that reading from the stack
/// in the called source will 0 index from the first input, NOT the bottom of
/// the calling stack.
library OpCall {
    using LibIntegrityState for IntegrityState;
    using LibStackTop for StackTop;
    using LibInterpreterState for InterpreterState;
    using LibUint256Array for uint;

    /// Interpreter integrity logic.
    /// The basic movements on the outer stack are to pop the inputs and push the
    /// outputs, but the called source doesn't have access to a separately
    /// allocated region of memory. There's only a single shared memory
    /// allocation for all executions and sub-executions, so we recursively run
    /// integrity checks on the called source relative to the current stack
    /// position.
    /// @param integrityState_ The state of the current integrity check.
    /// @param operand_ The operand associated with this call.
    /// @param stackTop_ The current stack top within the integrity check.
    /// @return stackTopAfter_ The stack top after the call movements are applied.
    function integrity(
        IntegrityState memory integrityState_,
        Operand operand_,
        StackTop stackTop_
    ) internal view returns (StackTop stackTopAfter_) {
        // Unpack the operand to get IO and the source to be called.
        uint256 inputs_ = Operand.unwrap(operand_) & MASK_4BIT;
        uint256 outputs_ = (Operand.unwrap(operand_) >> 4) & MASK_4BIT;
        SourceIndex callSourceIndex_ = SourceIndex.wrap(
            Operand.unwrap(operand_) >> 8
        );

        // Remember the outer stack bottom.
        StackTop stackBottom_ = integrityState_.stackBottom;

        // Set the inner stack bottom to below the inputs.
        integrityState_.stackBottom = integrityState_.pop(stackTop_, inputs_);

        // Ensure the integrity of the inner source on the current state using
        // the stack top above the inputs as the starting stack top.
        // Contraints namespace is irrelevant here.
        integrityState_.ensureIntegrity(callSourceIndex_, stackTop_, outputs_);

        // The outer stack top will move above the outputs relative to the inner
        // stack bottom. At runtime any values that are not outputs will be
        // removed so they do not need to be accounted for here.
        stackTopAfter_ = integrityState_.push(
            integrityState_.stackBottom,
            outputs_
        );

        // Reinstate the outer stack bottom.
        integrityState_.stackBottom = stackBottom_;
    }

    /// Call eval with a new scope.
    /// @param state_ The state of the current evaluation.
    /// @param operand_ The operand associated with this call.
    /// @param stackTop_ The current stack top within the evaluation.
    /// @return stackTopAfter_ The stack top after the call is evaluated.
    function run(
        InterpreterState memory state_,
        Operand operand_,
        StackTop stackTop_
    ) internal view returns (StackTop stackTopAfter_) {
        // Unpack the operand to get IO and the source to be called.
        uint256 inputs_ = Operand.unwrap(operand_) & MASK_4BIT;
        uint256 outputs_ = (Operand.unwrap(operand_) >> 4) & MASK_4BIT;
        SourceIndex callSourceIndex_ = SourceIndex.wrap(
            Operand.unwrap(operand_) >> 8
        );

        // Remember the outer stack bottom.
        StackTop stackBottom_ = state_.stackBottom;

        // Set the inner stack bottom to below the inputs.
        state_.stackBottom = stackTop_.down(inputs_);

        // Eval the source from the operand on the current state using the stack
        // top above the inputs as the starting stack top. The final stack top
        // is where we will read outputs from below.
        StackTop stackTopEval_ = state_.eval(callSourceIndex_, stackTop_);
        // Normalize the inner final stack so that it contains only the outputs
        // starting from the inner stack bottom.
        LibUint256Array.unsafeCopyValuesTo(
            StackTop.unwrap(stackTopEval_.down(outputs_)),
            StackTop.unwrap(state_.stackBottom),
            outputs_
        );

        // The outer stack top should now point above the outputs.
        stackTopAfter_ = state_.stackBottom.up(outputs_);

        // The outer stack bottom needs to be reinstated as it was before eval.
        state_.stackBottom = stackBottom_;
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

import {IERC20Upgradeable as IERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "../../run/LibStackTop.sol";
import "../../run/LibInterpreterState.sol";
import "../../deploy/LibIntegrityState.sol";
import "../../../kv/LibMemoryKV.sol";

/// @title OpSet
/// @notice Opcode for recording k/v state changes to be set in storage.
library OpSet {
    using LibStackTop for StackTop;
    using LibInterpreterState for InterpreterState;
    using LibIntegrityState for IntegrityState;
    using LibMemoryKV for MemoryKV;

    function integrity(
        IntegrityState memory integrityState_,
        Operand,
        StackTop stackTop_
    ) internal pure returns (StackTop) {
        unchecked {
            function(uint, uint) internal pure fn_;
            return integrityState_.applyFn(stackTop_, fn_);
        }
    }

    function run(
        InterpreterState memory state_,
        Operand,
        StackTop stackTop_
    ) internal pure returns (StackTop) {
        unchecked {
            uint k_;
            uint v_;
            (stackTop_, v_) = stackTop_.pop();
            (stackTop_, k_) = stackTop_.pop();
            state_.stateKV = state_.stateKV.setVal(
                MemoryKVKey.wrap(k_),
                MemoryKVVal.wrap(v_)
            );
            return stackTop_;
        }
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

import {IERC20Upgradeable as IERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "../../run/LibStackTop.sol";
import "../../run/LibInterpreterState.sol";
import "../../deploy/LibIntegrityState.sol";
import "../../../math/Binary.sol";

/// @title OpContext
/// @notice Opcode for stacking from the context. Context requires slightly
/// different handling to other memory reads as it is working with data that
/// is provided at runtime.
library OpContext {
    using LibStackTop for StackTop;
    using LibInterpreterState for InterpreterState;
    using LibIntegrityState for IntegrityState;

    /// Interpreter integrity logic.
    /// Context pushes a single value to the stack from memory.
    function integrity(
        IntegrityState memory integrityState_,
        Operand,
        StackTop stackTop_
    ) internal pure returns (StackTop) {
        // Note that a expression with context can error at runtime due to OOB
        // reads that we don't know about here.
        return integrityState_.push(stackTop_);
    }

    /// Stack a value from the context WITH OOB checks from solidity.
    /// The bounds checks are done at runtime because context MAY be provided
    /// by the end user with arbitrary length.
    function run(
        InterpreterState memory state_,
        Operand operand_,
        StackTop stackTop_
    ) internal pure returns (StackTop) {
        // The indexing syntax here enforces OOB checks at runtime.
        return
            stackTop_.push(
                state_.context[Operand.unwrap(operand_) >> 8][
                    Operand.unwrap(operand_) & MASK_8BIT
                ]
            );
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

import {IERC20Upgradeable as IERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "../../run/LibStackTop.sol";
import "../../run/LibInterpreterState.sol";
import "../../deploy/LibIntegrityState.sol";
import "../../../math/Binary.sol";

/// @title OpContextRow
/// @notice Opcode for stacking a dynamic row from the context. Context requires
/// slightly different handling to other memory reads as it is working with data
/// that is provided at runtime. `OpContextRow` works exactly like `OpContext`
/// but the row is provided from the stack instead of the operand. We rely on
/// Solidity OOB checks at runtime to enforce that the index from the stack is
/// within bounds at runtime. As we do NOT know statically which row will be read
/// the context reads is set to the entire column.
library OpContextRow {
    using LibStackTop for StackTop;
    using LibInterpreterState for InterpreterState;
    using LibIntegrityState for IntegrityState;

    /// Interpreter integrity logic.
    /// Context pushes a single value to the stack from memory.
    function integrity(
        IntegrityState memory integrityState_,
        Operand,
        StackTop stackTop_
    ) internal pure returns (StackTop) {
        // Note that a expression with context can error at runtime due to OOB
        // reads that we don't know about here.
        function(uint) internal pure returns (uint) fn_;
        return integrityState_.applyFn(stackTop_, fn_);
    }

    /// Stack a value from the context WITH OOB checks from solidity.
    /// The bounds checks are done at runtime because context MAY be provided
    /// by the end user with arbitrary length.
    function run(
        InterpreterState memory state_,
        Operand operand_,
        StackTop stackTop_
    ) internal pure returns (StackTop) {
        // The indexing syntax here enforces OOB checks at runtime.
        (StackTop location_, uint row_) = stackTop_.pop();
        location_.set(state_.context[Operand.unwrap(operand_)][row_]);
        return stackTop_;
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

import {IERC20Upgradeable as IERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "../../run/LibStackTop.sol";
import "../../run/LibInterpreterState.sol";
import "../../deploy/LibIntegrityState.sol";

/// @title OpDebug
/// @notice Opcode for debugging state. Uses the standard debugging logic from
/// InterpreterState.debug.
library OpDebug {
    using LibStackTop for StackTop;
    using LibInterpreterState for InterpreterState;

    /// Interpreter integrity for debug.
    /// Debug doesn't modify the stack.
    function integrity(
        IntegrityState memory,
        Operand operand_,
        StackTop stackTop_
    ) internal pure returns (StackTop) {
        // Try to build a debug style from the operand to ensure we can enumerate
        // it.
        DebugStyle(Operand.unwrap(operand_));
        return stackTop_;
    }

    /// Debug the current state.
    function debug(
        InterpreterState memory state_,
        Operand operand_,
        StackTop stackTop_
    ) internal view returns (StackTop) {
        DebugStyle debugStyle_ = DebugStyle(Operand.unwrap(operand_));

        state_.debug(stackTop_, debugStyle_);

        return stackTop_;
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

import {IERC20Upgradeable as IERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "../../run/LibStackTop.sol";
import "../../run/LibInterpreterState.sol";
import "../../deploy/LibIntegrityState.sol";
import "./OpCall.sol";

/// @title OpWhile
/// @notice Opcode for looping while the stack top is nonzero. As we pre-allocate
/// all the memory for execution during integrity checks we have an apparent
/// contradiction here. If we do not know how many times the loop will run then
/// we cannot calculate the final stack height or intermediate pops and pushes.
/// To solve this we simply wrap `OpCall` which already has fixed inputs and
/// outputs and enforce that the outputs of each iteration is 1 more than the
/// inputs. We then consume the extra output as the condition for the decision
/// to loop again, thus the outputs = inputs for every iteration. If the stack
/// height does not change between iterations we do not care how many times we
/// loop (although the user paying gas might).
library OpDoWhile {
    using LibIntegrityState for IntegrityState;
    using LibStackTop for StackTop;
    using LibInterpreterState for InterpreterState;

    /// Interpreter integrity for do while.
    /// The loop itself pops a single value from the stack to determine whether
    /// it should run another iteration of the loop. The source called by the
    /// loop must then put a value back on the stack in the same position to
    /// either continue or break the loop.
    function integrity(
        IntegrityState memory integrityState_,
        Operand operand_,
        StackTop stackTop_
    ) internal view returns (StackTop) {
        unchecked {
            uint inputs_ = Operand.unwrap(operand_) & MASK_8BIT;
            /// We need outputs to be larger than inputs so inputs can't be the
            /// max value possible in 4 bits or outputs will overflow.
            require(inputs_ < MASK_4BIT, "OP_DO_WHILE_INPUTS");
            uint outputs_ = inputs_ + 1;
            Operand callOperand_ = Operand.wrap(
                Operand.unwrap(operand_) | (outputs_ << 4)
            );
            // Stack height changes are deterministic so if we call once we've
            // called a thousand times. Also we pop one output off the result of
            // the call to check the while condition.
            return
                integrityState_.pop(
                    OpCall.integrity(integrityState_, callOperand_, stackTop_)
                );
        }
    }

    /// Loop the stack while the stack top is true.
    function run(
        InterpreterState memory state_,
        Operand operand_,
        StackTop stackTop_
    ) internal view returns (StackTop) {
        unchecked {
            uint inputs_ = Operand.unwrap(operand_) & MASK_8BIT;
            uint outputs_ = inputs_ + 1;
            Operand callOperand_ = Operand.wrap(
                Operand.unwrap(operand_) | (outputs_ << 4)
            );
            uint256 do_;
            (stackTop_, do_) = stackTop_.pop();
            while (do_ > 0) {
                stackTop_ = OpCall.run(state_, callOperand_, stackTop_);
                (stackTop_, do_) = stackTop_.pop();
            }
            return stackTop_;
        }
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

import "../../run/LibStackTop.sol";
import "../../run/LibInterpreterState.sol";
import "../../deploy/LibIntegrityState.sol";
import "./OpCall.sol";

/// @title OpFoldContext
/// Folds over columns of context from their start to end. Expressions do not
/// have a good way of handling dynamic lengths of things, and that is
/// intentional to avoid end users having to write out looping constructs of the
/// form `i = 0; i < length; i++` is is so tedious and error prone in software
/// development generally. It is very easy to implement "off by one" errors in
/// this form, and requires sourcing a length from somewhere. This opcode exposes
/// a pretty typical fold as found elsewhere in functional programming. A start
/// column and width of columns can be specified, the rows will be iterated and
/// pushed to the stack on top of any additional inputs specified by the
/// expression. The additional inputs are the accumulators and so the number of
/// outputs in the called source needs to match the number of accumulator inputs.
library OpFoldContext {
    using LibIntegrityState for IntegrityState;
    using LibStackTop for StackTop;

    function integrity(
        IntegrityState memory integrityState_,
        Operand operand_,
        StackTop stackTop_
    ) internal view returns (StackTop) {
        unchecked {
            uint sourceIndex_ = Operand.unwrap(operand_) & MASK_4BIT;
            // We don't use the column for anything in the integrity check.
            // uint column_ = (Operand.unwrap(operand_) >> 4) & MASK_4BIT;
            uint width_ = (Operand.unwrap(operand_) >> 8) & MASK_4BIT;
            uint inputs_ = Operand.unwrap(operand_) >> 12;
            uint callInputs_ = width_ + inputs_;

            // Outputs for call is the same as the inputs.
            Operand callOperand_ = Operand.wrap(
                (sourceIndex_ << 8) | (inputs_ << 4) | callInputs_
            );

            // First the width of the context columns being folded is pushed to
            // the stack.
            stackTop_ = integrityState_.push(stackTop_, width_);
            // Then we loop over call taking the width and extra inputs, then
            // returning the same number of outputs as non-width inputs.
            return OpCall.integrity(integrityState_, callOperand_, stackTop_);
        }
    }

    function run(
        InterpreterState memory state_,
        Operand operand_,
        StackTop stackTop_
    ) internal view returns (StackTop) {
        unchecked {
            uint sourceIndex_ = Operand.unwrap(operand_) & MASK_4BIT;
            uint column_ = (Operand.unwrap(operand_) >> 4) & MASK_4BIT;
            uint width_ = (Operand.unwrap(operand_) >> 8) & MASK_4BIT;
            uint inputs_ = Operand.unwrap(operand_) >> 12;
            // Call will take the width of the context rows being copied and the
            // base inputs that will be the accumulators of the fold.
            uint callInputs_ = width_ + inputs_;

            // Fold over the entire context. This will error with an OOB index
            // if the context columns are not of the same length.
            for (uint i_ = 0; i_ < state_.context[column_].length; i_++) {
                // Push the width of the context columns onto the stack as rows.
                for (uint j_ = 0; j_ < width_; j_++) {
                    stackTop_ = stackTop_.push(
                        state_.context[column_ + j_][i_]
                    );
                }
                // The outputs of call are the same as the base inputs, this is
                // similar to `OpDoWhile` so that we don't have to care how many
                // iterations there are in order to calculate the stack.
                Operand callOperand_ = Operand.wrap(
                    (sourceIndex_ << 8) | (inputs_ << 4) | callInputs_
                );
                stackTop_ = OpCall.run(state_, callOperand_, stackTop_);
            }

            return stackTop_;
        }
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

import {IERC20Upgradeable as IERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "../../run/LibStackTop.sol";
import "../../run/LibInterpreterState.sol";
import "../../deploy/LibIntegrityState.sol";
import "./OpCall.sol";

/// @title OpLoopN
/// @notice Opcode for looping a static number of times. A thin wrapper around
/// `OpCall` with the 4 high bits as a number of times to loop. Each iteration
/// will use the outputs of the previous iteration as its inputs so the inputs
/// to call must be greater or equal to the outputs. If the outputs exceed the
/// inputs then each subsequent call will take as many inputs as it needs from
/// the top of the intermediate stack. The net outputs to the stack will include
/// all the intermediate excess outputs as:
/// `outputs + (inputs - outputs) * n`
library OpLoopN {
    using LibStackTop for StackTop;
    using LibInterpreterState for InterpreterState;
    using LibIntegrityState for IntegrityState;

    function integrity(
        IntegrityState memory integrityState_,
        Operand operand_,
        StackTop stackTop_
    ) internal view returns (StackTop) {
        unchecked {
            uint n_ = Operand.unwrap(operand_) >> 12;
            uint inputs_ = Operand.unwrap(operand_) & MASK_4BIT;
            uint outputs_ = (Operand.unwrap(operand_) >> 4) & MASK_4BIT;
            require(inputs_ >= outputs_, "LOOP_N_INPUTS");
            Operand callOperand_ = Operand.wrap(
                Operand.unwrap(operand_) & MASK_12BIT
            );
            for (uint i_ = 0; i_ < n_; i_++) {
                stackTop_ = OpCall.integrity(
                    integrityState_,
                    callOperand_,
                    stackTop_
                );
            }
            return stackTop_;
        }
    }

    function run(
        InterpreterState memory state_,
        Operand operand_,
        StackTop stackTop_
    ) internal view returns (StackTop) {
        uint256 n_ = Operand.unwrap(operand_) >> 12;
        Operand callOperand_ = Operand.wrap(
            Operand.unwrap(operand_) & MASK_12BIT
        );
        for (uint256 i_ = 0; i_ < n_; i_++) {
            stackTop_ = OpCall.run(state_, callOperand_, stackTop_);
        }
        return stackTop_;
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

import {IERC20Upgradeable as IERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "../../run/LibStackTop.sol";
import "../../run/LibInterpreterState.sol";
import "../../deploy/LibIntegrityState.sol";
import "../../../math/Binary.sol";

uint256 constant OPCODE_MEMORY_TYPE_STACK = 0;
uint256 constant OPCODE_MEMORY_TYPE_CONSTANT = 1;

/// @title OpReadMemory
/// @notice Opcode for stacking from the state.
library OpReadMemory {
    using LibStackTop for StackTop;
    using LibInterpreterState for InterpreterState;
    using LibIntegrityState for IntegrityState;

    function integrity(
        IntegrityState memory integrityState_,
        Operand operand_,
        StackTop stackTop_
    ) internal pure returns (StackTop) {
        uint256 type_ = Operand.unwrap(operand_) & MASK_1BIT;
        uint256 offset_ = Operand.unwrap(operand_) >> 1;
        if (type_ == OPCODE_MEMORY_TYPE_STACK) {
            require(
                offset_ < integrityState_.stackBottom.toIndex(stackTop_),
                "OOB_STACK_READ"
            );
        } else {
            require(
                offset_ < integrityState_.constantsLength,
                "OOB_CONSTANT_READ"
            );
        }
        return integrityState_.push(stackTop_);
    }

    function run(
        InterpreterState memory state_,
        Operand operand_,
        StackTop stackTop_
    ) internal pure returns (StackTop) {
        unchecked {
            uint256 type_ = Operand.unwrap(operand_) & MASK_1BIT;
            uint256 offset_ = Operand.unwrap(operand_) >> 1;
            assembly ("memory-safe") {
                mstore(
                    stackTop_,
                    mload(
                        add(
                            mload(add(state_, mul(0x20, type_))),
                            mul(0x20, offset_)
                        )
                    )
                )
            }
            return StackTop.wrap(StackTop.unwrap(stackTop_) + 0x20);
        }
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

import "../../run/LibStackTop.sol";
import "../../../array/LibUint256Array.sol";
import "../../../type/LibCast.sol";
import "../../run/LibInterpreterState.sol";
import "../../deploy/LibIntegrityState.sol";

/// @title OpHash
/// @notice Opcode for hashing a list of values.
library OpHash {
    using LibStackTop for StackTop;
    using LibCast for uint256[];
    using LibIntegrityState for IntegrityState;

    function _hash(uint256[] memory values_) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(values_)));
    }

    function integrity(
        IntegrityState memory integrityState_,
        Operand operand_,
        StackTop stackTop_
    ) internal pure returns (StackTop) {
        return
            integrityState_.applyFn(stackTop_, _hash, Operand.unwrap(operand_));
    }

    // Stack the return of `balanceOfBatch`.
    // Operand will be the length
    function hash(
        InterpreterState memory,
        Operand operand_,
        StackTop stackTop_
    ) internal view returns (StackTop) {
        return stackTop_.applyFn(_hash, Operand.unwrap(operand_));
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

import {IERC20Upgradeable as IERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "../../run/LibStackTop.sol";
import "../../run/LibInterpreterState.sol";
import "../../deploy/LibIntegrityState.sol";

/// @title OpERC20BalanceOf
/// @notice Opcode for ERC20 `balanceOf`.
library OpERC20BalanceOf {
    using LibStackTop for StackTop;
    using LibIntegrityState for IntegrityState;

    function _balanceOf(
        uint256 token_,
        uint256 account_
    ) internal view returns (uint256) {
        return
            IERC20(address(uint160(token_))).balanceOf(
                address(uint160(account_))
            );
    }

    function integrity(
        IntegrityState memory integrityState_,
        Operand,
        StackTop stackTop_
    ) internal pure returns (StackTop) {
        return integrityState_.applyFn(stackTop_, _balanceOf);
    }

    /// Stack `balanceOf`.
    function balanceOf(
        InterpreterState memory,
        Operand,
        StackTop stackTop_
    ) internal view returns (StackTop) {
        return stackTop_.applyFn(_balanceOf);
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

import {IERC20Upgradeable as IERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "../../run/LibStackTop.sol";
import "../../run/LibInterpreterState.sol";
import "../../deploy/LibIntegrityState.sol";

/// @title OpERC20TotalSupply
/// @notice Opcode for ERC20 `totalSupply`.
library OpERC20TotalSupply {
    using LibStackTop for StackTop;
    using LibIntegrityState for IntegrityState;

    function _totalSupply(uint256 token_) internal view returns (uint256) {
        return IERC20(address(uint160(token_))).totalSupply();
    }

    function integrity(
        IntegrityState memory integrityState_,
        Operand,
        StackTop stackTop_
    ) internal pure returns (StackTop) {
        return integrityState_.applyFn(stackTop_, _totalSupply);
    }

    // Stack the return of `totalSupply`.
    function totalSupply(
        InterpreterState memory,
        Operand,
        StackTop stackTop_
    ) internal view returns (StackTop) {
        return stackTop_.applyFn(_totalSupply);
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

import {ERC20SnapshotUpgradeable as ERC20Snapshot} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20SnapshotUpgradeable.sol";
import "../../../run/LibStackTop.sol";
import "../../../run/LibInterpreterState.sol";
import "../../../deploy/LibIntegrityState.sol";

/// @title OpERC20SnapshotBalanceOfAt
/// @notice Opcode for Open Zeppelin `ERC20Snapshot.balanceOfAt`.
/// https://docs.openzeppelin.com/contracts/4.x/api/token/erc20#ERC20Snapshot
library OpERC20SnapshotBalanceOfAt {
    using LibStackTop for StackTop;
    using LibIntegrityState for IntegrityState;

    function _balanceOfAt(
        uint256 token_,
        uint256 account_,
        uint256 snapshotId_
    ) internal view returns (uint256) {
        return
            ERC20Snapshot(address(uint160(token_))).balanceOfAt(
                address(uint160(account_)),
                snapshotId_
            );
    }

    function integrity(
        IntegrityState memory integrityState_,
        Operand,
        StackTop stackTop_
    ) internal pure returns (StackTop) {
        return integrityState_.applyFn(stackTop_, _balanceOfAt);
    }

    /// Stack `balanceOfAt`.
    function balanceOfAt(
        InterpreterState memory,
        Operand,
        StackTop stackTop_
    ) internal view returns (StackTop) {
        return stackTop_.applyFn(_balanceOfAt);
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

import {ERC20SnapshotUpgradeable as ERC20Snapshot} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20SnapshotUpgradeable.sol";
import "../../../run/LibStackTop.sol";
import "../../../run/LibInterpreterState.sol";
import "../../../deploy/LibIntegrityState.sol";

/// @title OpERC20SnapshotTotalSupplyAt
/// @notice Opcode for Open Zeppelin `ERC20Snapshot.totalSupplyAt`.
/// https://docs.openzeppelin.com/contracts/4.x/api/token/erc20#ERC20Snapshot
library OpERC20SnapshotTotalSupplyAt {
    using LibStackTop for StackTop;
    using LibIntegrityState for IntegrityState;

    function _totalSupplyAt(
        uint256 token_,
        uint256 snapshotId_
    ) internal view returns (uint256) {
        return
            ERC20Snapshot(address(uint160(token_))).totalSupplyAt(snapshotId_);
    }

    function integrity(
        IntegrityState memory integrityState_,
        Operand,
        StackTop stackTop_
    ) internal pure returns (StackTop) {
        return integrityState_.applyFn(stackTop_, _totalSupplyAt);
    }

    /// Stack `totalSupplyAt`.
    function totalSupplyAt(
        InterpreterState memory,
        Operand,
        StackTop stackTop_
    ) internal view returns (StackTop) {
        return stackTop_.applyFn(_totalSupplyAt);
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

import {IERC721Upgradeable as IERC721} from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "../../run/LibStackTop.sol";
import "../../run/LibInterpreterState.sol";
import "../../deploy/LibIntegrityState.sol";

/// @title OpERC721BalanceOf
/// @notice Opcode for getting the current erc721 balance of an account.
library OpERC721BalanceOf {
    using LibStackTop for StackTop;
    using LibIntegrityState for IntegrityState;

    function _balanceOf(
        uint256 token_,
        uint256 account_
    ) internal view returns (uint256) {
        return
            IERC721(address(uint160(token_))).balanceOf(
                address(uint160(account_))
            );
    }

    function integrity(
        IntegrityState memory integrityState_,
        Operand,
        StackTop stackTop_
    ) internal pure returns (StackTop) {
        return integrityState_.applyFn(stackTop_, _balanceOf);
    }

    // Stack the return of `balanceOf`.
    function balanceOf(
        InterpreterState memory,
        Operand,
        StackTop stackTop_
    ) internal view returns (StackTop) {
        return stackTop_.applyFn(_balanceOf);
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

import {IERC721Upgradeable as IERC721} from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "../../run/LibStackTop.sol";
import "../../run/LibInterpreterState.sol";
import "../../deploy/LibIntegrityState.sol";

/// @title OpERC721OwnerOf
/// @notice Opcode for getting the current erc721 owner of an account.
library OpERC721OwnerOf {
    using LibStackTop for StackTop;
    using LibIntegrityState for IntegrityState;

    function _ownerOf(
        uint256 token_,
        uint256 id_
    ) internal view returns (uint256) {
        return uint256(uint160(IERC721(address(uint160(token_))).ownerOf(id_)));
    }

    function integrity(
        IntegrityState memory integrityState_,
        Operand,
        StackTop stackTop_
    ) internal pure returns (StackTop) {
        return integrityState_.applyFn(stackTop_, _ownerOf);
    }

    // Stack the return of `ownerOf`.
    function ownerOf(
        InterpreterState memory,
        Operand,
        StackTop stackTop_
    ) internal view returns (StackTop) {
        return stackTop_.applyFn(_ownerOf);
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

import {IERC1155Upgradeable as IERC1155} from "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import "../../run/LibStackTop.sol";
import "../../run/LibInterpreterState.sol";
import "../../deploy/LibIntegrityState.sol";

/// @title OpERC1155BalanceOf
/// @notice Opcode for getting the current erc1155 balance of an account.
library OpERC1155BalanceOf {
    using LibStackTop for StackTop;
    using LibIntegrityState for IntegrityState;

    function _balanceOf(
        uint256 token_,
        uint256 account_,
        uint256 id_
    ) internal view returns (uint256) {
        return
            IERC1155(address(uint160(token_))).balanceOf(
                address(uint160(account_)),
                id_
            );
    }

    function integrity(
        IntegrityState memory integrityState_,
        Operand,
        StackTop stackTop_
    ) internal pure returns (StackTop) {
        return integrityState_.applyFn(stackTop_, _balanceOf);
    }

    // Stack the return of `balanceOf`.
    function balanceOf(
        InterpreterState memory,
        Operand,
        StackTop stackTop_
    ) internal view returns (StackTop) {
        return stackTop_.applyFn(_balanceOf);
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

import {IERC1155Upgradeable as IERC1155} from "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import "../../run/LibStackTop.sol";
import "../../../array/LibUint256Array.sol";
import "../../../type/LibCast.sol";
import "../../run/LibInterpreterState.sol";
import "../../deploy/LibIntegrityState.sol";

/// @title OpERC1155BalanceOfBatch
/// @notice Opcode for getting the current erc1155 balance of an accounts batch.
library OpERC1155BalanceOfBatch {
    using LibStackTop for StackTop;
    using LibCast for uint256[];
    using LibIntegrityState for IntegrityState;

    function _balanceOfBatch(
        uint256 token_,
        uint256[] memory accounts_,
        uint256[] memory ids_
    ) internal view returns (uint256[] memory) {
        return
            IERC1155(address(uint160(token_))).balanceOfBatch(
                accounts_.asAddresses(),
                ids_
            );
    }

    function integrity(
        IntegrityState memory integrityState_,
        Operand operand_,
        StackTop stackTop_
    ) internal pure returns (StackTop) {
        return
            integrityState_.applyFn(
                stackTop_,
                _balanceOfBatch,
                Operand.unwrap(operand_)
            );
    }

    // Stack the return of `balanceOfBatch`.
    // Operand will be the length
    function balanceOfBatch(
        InterpreterState memory,
        Operand operand_,
        StackTop stackTop_
    ) internal view returns (StackTop) {
        return stackTop_.applyFn(_balanceOfBatch, Operand.unwrap(operand_));
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

import "../../run/LibStackTop.sol";
import "../../../array/LibUint256Array.sol";
import "../../run/LibInterpreterState.sol";
import "../../deploy/LibIntegrityState.sol";

/// @title OpEnsure
/// @notice Opcode for requiring some truthy values.
library OpEnsure {
    using LibStackTop for StackTop;
    using LibIntegrityState for IntegrityState;

    function _ensure(uint256 a_) internal pure {
        assembly ("memory-safe") {
            if iszero(a_) {
                revert(0, 0)
            }
        }
    }

    function integrity(
        IntegrityState memory integrityState_,
        Operand operand_,
        StackTop stackTop_
    ) internal pure returns (StackTop) {
        return
            integrityState_.applyFnN(
                stackTop_,
                _ensure,
                Operand.unwrap(operand_)
            );
    }

    function ensure(
        InterpreterState memory,
        Operand operand_,
        StackTop stackTop_
    ) internal view returns (StackTop) {
        return stackTop_.applyFnN(_ensure, Operand.unwrap(operand_));
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

import "../../run/LibStackTop.sol";
import "../../run/LibInterpreterState.sol";
import "../../deploy/LibIntegrityState.sol";

/// @title OpBlockNumber
/// @notice Opcode for getting the current block number.
library OpBlockNumber {
    using LibStackTop for StackTop;
    using LibIntegrityState for IntegrityState;

    function integrity(
        IntegrityState memory integrityState_,
        Operand,
        StackTop stackTop_
    ) internal pure returns (StackTop) {
        return integrityState_.push(stackTop_);
    }

    function blockNumber(
        InterpreterState memory,
        Operand,
        StackTop stackTop_
    ) internal view returns (StackTop) {
        return stackTop_.push(block.number);
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

import "../../run/LibStackTop.sol";
import "../../run/LibInterpreterState.sol";
import "../../deploy/LibIntegrityState.sol";

/// @title OpTimestamp
/// @notice Opcode for getting the current timestamp.
library OpTimestamp {
    using LibStackTop for StackTop;
    using LibIntegrityState for IntegrityState;

    function integrity(
        IntegrityState memory integrityState_,
        Operand,
        StackTop stackTop_
    ) internal pure returns (StackTop) {
        return integrityState_.push(stackTop_);
    }

    function timestamp(
        InterpreterState memory,
        Operand,
        StackTop stackTop_
    ) internal view returns (StackTop) {
        return stackTop_.push(block.timestamp);
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

import "../../run/LibStackTop.sol";
import "../../../array/LibUint256Array.sol";
import "../../run/LibInterpreterState.sol";
import "../../deploy/LibIntegrityState.sol";

/// @title OpExplode
/// @notice Opcode for exploding a single value into 8x 32 bit integers.
library OpExplode32 {
    using LibStackTop for StackTop;
    using LibIntegrityState for IntegrityState;

    function integrity(
        IntegrityState memory integrityState_,
        Operand,
        StackTop stackTop_
    ) internal pure returns (StackTop) {
        return integrityState_.push(integrityState_.pop(stackTop_), 8);
    }

    function explode32(
        InterpreterState memory,
        Operand,
        StackTop stackTop_
    ) internal pure returns (StackTop) {
        (StackTop location_, uint256 i_) = stackTop_.pop();
        uint256 mask_ = uint256(type(uint32).max);
        return
            location_.push(
                i_ & mask_,
                (i_ >> 0x20) & mask_,
                (i_ >> 0x40) & mask_,
                (i_ >> 0x60) & mask_,
                (i_ >> 0x80) & mask_,
                (i_ >> 0xA0) & mask_,
                (i_ >> 0xC0) & mask_,
                (i_ >> 0xE0) & mask_
            );
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

import "../../../../math/FixedPointMath.sol";
import "../../../run/LibStackTop.sol";
import "../../../run/LibInterpreterState.sol";
import "../../../deploy/LibIntegrityState.sol";

/// @title OpFixedPointScale18
/// @notice Opcode for scaling a number to 18 fixed point.
library OpFixedPointScale18 {
    using FixedPointMath for uint256;
    using LibStackTop for StackTop;
    using LibIntegrityState for IntegrityState;

    function _scale18(
        Operand operand_,
        uint256 a_
    ) internal pure returns (uint256) {
        return a_.scale18(Operand.unwrap(operand_));
    }

    function integrity(
        IntegrityState memory integrityState_,
        Operand,
        StackTop stackTop_
    ) internal pure returns (StackTop) {
        return integrityState_.applyFn(stackTop_, _scale18);
    }

    function scale18(
        InterpreterState memory,
        Operand operand_,
        StackTop stackTop_
    ) internal view returns (StackTop) {
        return stackTop_.applyFn(_scale18, operand_);
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

import "../../../../math/FixedPointMath.sol";
import "../../../run/LibStackTop.sol";
import "../../../run/LibInterpreterState.sol";
import "../../../deploy/LibIntegrityState.sol";

/// @title OpFixedPointScale18Div
/// @notice Opcode for performing scale 18 fixed point division.
library OpFixedPointScale18Div {
    using FixedPointMath for uint256;
    using LibStackTop for StackTop;
    using LibIntegrityState for IntegrityState;

    function _scale18Div(
        Operand operand_,
        uint256 a_,
        uint256 b_
    ) internal pure returns (uint256) {
        return a_.scale18(Operand.unwrap(operand_)).fixedPointDiv(b_);
    }

    function integrity(
        IntegrityState memory integrityState_,
        Operand,
        StackTop stackTop_
    ) internal pure returns (StackTop) {
        return integrityState_.applyFn(stackTop_, _scale18Div);
    }

    function scale18Div(
        InterpreterState memory,
        Operand operand_,
        StackTop stackTop_
    ) internal view returns (StackTop) {
        return stackTop_.applyFn(_scale18Div, operand_);
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

import "../../../../math/FixedPointMath.sol";
import "../../../run/LibStackTop.sol";
import "../../../run/LibInterpreterState.sol";
import "../../../deploy/LibIntegrityState.sol";

/// @title OpFixedPointScale18Mul
/// @notice Opcode for performing scale 18 fixed point multiplication.
library OpFixedPointScale18Mul {
    using FixedPointMath for uint256;
    using LibStackTop for StackTop;
    using LibIntegrityState for IntegrityState;

    function _scale18Mul(
        Operand operand_,
        uint256 a_,
        uint256 b_
    ) internal pure returns (uint256) {
        return a_.scale18(Operand.unwrap(operand_)).fixedPointMul(b_);
    }

    function integrity(
        IntegrityState memory integrityState_,
        Operand,
        StackTop stackTop_
    ) internal pure returns (StackTop) {
        return integrityState_.applyFn(stackTop_, _scale18Mul);
    }

    function scale18Mul(
        InterpreterState memory,
        Operand operand_,
        StackTop stackTop_
    ) internal view returns (StackTop) {
        return stackTop_.applyFn(_scale18Mul, operand_);
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

import "../../../../math/FixedPointMath.sol";
import "../../../run/LibStackTop.sol";
import "../../../run/LibInterpreterState.sol";
import "../../../deploy/LibIntegrityState.sol";

/// @title OpFixedPointScaleBy
/// @notice Opcode for scaling a number by some OOMs.
library OpFixedPointScaleBy {
    using FixedPointMath for uint256;
    using LibStackTop for StackTop;
    using LibIntegrityState for IntegrityState;

    function _scaleBy(
        Operand operand_,
        uint256 a_
    ) internal pure returns (uint256) {
        return a_.scaleBy(int8(uint8(Operand.unwrap(operand_))));
    }

    function integrity(
        IntegrityState memory integrityState_,
        Operand,
        StackTop stackTop_
    ) internal pure returns (StackTop) {
        return integrityState_.applyFn(stackTop_, _scaleBy);
    }

    function scaleBy(
        InterpreterState memory,
        Operand operand_,
        StackTop stackTop_
    ) internal view returns (StackTop) {
        return stackTop_.applyFn(_scaleBy, operand_);
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

import "../../../../math/FixedPointMath.sol";
import "../../../run/LibStackTop.sol";
import "../../../run/LibInterpreterState.sol";
import "../../../deploy/LibIntegrityState.sol";

/// @title OpFixedPointScaleN
/// @notice Opcode for scaling a number to N fixed point.
library OpFixedPointScaleN {
    using FixedPointMath for uint256;
    using LibStackTop for StackTop;
    using LibIntegrityState for IntegrityState;

    function _scaleN(
        Operand operand_,
        uint256 a_
    ) internal pure returns (uint256) {
        return a_.scaleN(Operand.unwrap(operand_));
    }

    function integrity(
        IntegrityState memory integrityState_,
        Operand,
        StackTop stackTop_
    ) internal pure returns (StackTop) {
        return integrityState_.applyFn(stackTop_, _scaleN);
    }

    function scaleN(
        InterpreterState memory,
        Operand operand_,
        StackTop stackTop_
    ) internal view returns (StackTop) {
        return stackTop_.applyFn(_scaleN, operand_);
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;
import "../../../run/LibStackTop.sol";
import "../../../run/LibInterpreterState.sol";
import "../../../deploy/LibIntegrityState.sol";

/// @title OpAny
/// @notice Opcode to compare the top N stack values.
library OpAny {
    using LibStackTop for StackTop;
    using LibIntegrityState for IntegrityState;

    function integrity(
        IntegrityState memory integrityState_,
        Operand operand_,
        StackTop stackTop_
    ) internal pure returns (StackTop) {
        function(uint256[] memory) internal view returns (uint256) fn_;
        return
            integrityState_.applyFn(stackTop_, fn_, Operand.unwrap(operand_));
    }

    // ANY
    // ANY is the first nonzero item, else 0.
    // operand_ id the length of items to check.
    function any(
        InterpreterState memory,
        Operand operand_,
        StackTop stackTop_
    ) internal pure returns (StackTop) {
        StackTop bottom_ = stackTop_.down(Operand.unwrap(operand_));
        for (
            StackTop i_ = bottom_;
            StackTop.unwrap(i_) < StackTop.unwrap(stackTop_);
            i_ = i_.up()
        ) {
            uint256 item_ = i_.peekUp();
            if (item_ > 0) {
                return bottom_.push(item_);
            }
        }
        return bottom_.up();
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;
import "../../../run/LibStackTop.sol";
import "../../../run/LibInterpreterState.sol";
import "../../../deploy/LibIntegrityState.sol";

/// @title OpEagerIf
/// @notice Opcode for selecting a value based on a condition.
library OpEagerIf {
    using LibIntegrityState for IntegrityState;
    using LibStackTop for StackTop;

    function _eagerIf(
        uint256 a_,
        uint256[] memory bs_,
        uint256[] memory cs_
    ) internal pure returns (uint256[] memory) {
        return a_ > 0 ? bs_ : cs_;
    }

    function integrity(
        IntegrityState memory integrityState_,
        Operand operand_,
        StackTop stackTop_
    ) internal pure returns (StackTop) {
        return
            integrityState_.applyFn(
                stackTop_,
                _eagerIf,
                Operand.unwrap(operand_) + 1
            );
    }

    /// Eager because BOTH x_ and y_ must be eagerly evaluated
    /// before EAGER_IF will select one of them. If both x_ and y_
    /// are cheap (e.g. constant values) then this may also be the
    /// simplest and cheapest way to select one of them.
    function eagerIf(
        InterpreterState memory,
        Operand operand_,
        StackTop stackTop_
    ) internal view returns (StackTop) {
        unchecked {
            return stackTop_.applyFn(_eagerIf, Operand.unwrap(operand_) + 1);
        }
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;
import "../../../run/LibStackTop.sol";
import "../../../../type/LibCast.sol";
import "../../../run/LibInterpreterState.sol";
import "../../../deploy/LibIntegrityState.sol";

/// @title OpEqualTo
/// @notice Opcode to compare the top two stack values.
library OpEqualTo {
    using LibCast for bool;
    using LibStackTop for StackTop;
    using LibIntegrityState for IntegrityState;

    function _equalTo(uint256 a_, uint256 b_) internal pure returns (uint256) {
        return (a_ == b_).asUint256();
    }

    function integrity(
        IntegrityState memory integrityState_,
        Operand,
        StackTop stackTop_
    ) internal pure returns (StackTop) {
        return integrityState_.applyFn(stackTop_, _equalTo);
    }

    function equalTo(
        InterpreterState memory,
        Operand,
        StackTop stackTop_
    ) internal view returns (StackTop) {
        return stackTop_.applyFn(_equalTo);
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;
import "../../../run/LibStackTop.sol";
import "../../../run/LibInterpreterState.sol";
import "../../../deploy/LibIntegrityState.sol";

/// @title OpEvery
/// @notice Opcode to compare the top N stack values.
library OpEvery {
    using LibStackTop for StackTop;
    using LibIntegrityState for IntegrityState;

    function integrity(
        IntegrityState memory integrityState_,
        Operand operand_,
        StackTop stackTop_
    ) internal pure returns (StackTop) {
        function(uint256[] memory) internal view returns (uint256) fn_;
        return
            integrityState_.applyFn(stackTop_, fn_, Operand.unwrap(operand_));
    }

    // EVERY
    // EVERY is either the first item if every item is nonzero, else 0.
    // operand_ is the length of items to check.
    function every(
        InterpreterState memory,
        Operand operand_,
        StackTop stackTop_
    ) internal pure returns (StackTop) {
        StackTop bottom_ = stackTop_.down(Operand.unwrap(operand_));
        for (
            StackTop i_ = bottom_;
            StackTop.unwrap(i_) < StackTop.unwrap(stackTop_);
            i_ = i_.up()
        ) {
            if (i_.peekUp() == 0) {
                return bottom_.push(0);
            }
        }
        return bottom_.up();
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;
import "../../../run/LibStackTop.sol";
import "../../../../type/LibCast.sol";
import "../../../run/LibInterpreterState.sol";
import "../../../deploy/LibIntegrityState.sol";

/// @title OpGreaterThan
/// @notice Opcode to compare the top two stack values.
library OpGreaterThan {
    using LibCast for bool;
    using LibStackTop for StackTop;
    using LibIntegrityState for IntegrityState;

    function _greaterThan(
        uint256 a_,
        uint256 b_
    ) internal pure returns (uint256) {
        return (a_ > b_).asUint256();
    }

    function integrity(
        IntegrityState memory integrityState_,
        Operand,
        StackTop stackTop_
    ) internal pure returns (StackTop) {
        return integrityState_.applyFn(stackTop_, _greaterThan);
    }

    function greaterThan(
        InterpreterState memory,
        Operand,
        StackTop stackTop_
    ) internal view returns (StackTop) {
        return stackTop_.applyFn(_greaterThan);
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;
import "../../../run/LibStackTop.sol";
import "../../../../type/LibCast.sol";
import "../../../run/LibInterpreterState.sol";
import "../../../deploy/LibIntegrityState.sol";

/// @title OpIsZero
/// @notice Opcode for checking if the stack top is zero.
library OpIsZero {
    using LibCast for bool;
    using LibStackTop for StackTop;
    using LibIntegrityState for IntegrityState;

    function _isZero(uint256 a_) internal pure returns (uint256) {
        return (a_ == 0).asUint256();
    }

    function integrity(
        IntegrityState memory integrityState_,
        Operand,
        StackTop stackTop_
    ) internal pure returns (StackTop) {
        return integrityState_.applyFn(stackTop_, _isZero);
    }

    function isZero(
        InterpreterState memory,
        Operand,
        StackTop stackTop_
    ) internal view returns (StackTop) {
        return stackTop_.applyFn(_isZero);
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;
import "../../../run/LibStackTop.sol";
import "../../../../type/LibCast.sol";
import "../../../run/LibInterpreterState.sol";
import "../../../deploy/LibIntegrityState.sol";

/// @title OpLessThan
/// @notice Opcode to compare the top two stack values.
library OpLessThan {
    using LibStackTop for StackTop;
    using LibCast for bool;
    using LibIntegrityState for IntegrityState;

    function _lessThan(uint256 a_, uint256 b_) internal pure returns (uint256) {
        return (a_ < b_).asUint256();
    }

    function integrity(
        IntegrityState memory integrityState_,
        Operand,
        StackTop stackTop_
    ) internal pure returns (StackTop) {
        return integrityState_.applyFn(stackTop_, _lessThan);
    }

    function lessThan(
        InterpreterState memory,
        Operand,
        StackTop stackTop_
    ) internal view returns (StackTop) {
        return stackTop_.applyFn(_lessThan);
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

import "../../../../math/SaturatingMath.sol";
import "../../../run/LibStackTop.sol";
import "../../../run/LibInterpreterState.sol";
import "../../../deploy/LibIntegrityState.sol";

/// @title OpSaturatingAdd
/// @notice Opcode for adding N numbers with saturating addition.
library OpSaturatingAdd {
    using SaturatingMath for uint256;
    using LibStackTop for StackTop;
    using LibIntegrityState for IntegrityState;

    function integrity(
        IntegrityState memory integrityState_,
        Operand operand_,
        StackTop stackTop_
    ) internal pure returns (StackTop) {
        return
            integrityState_.applyFnN(
                stackTop_,
                SaturatingMath.saturatingAdd,
                Operand.unwrap(operand_)
            );
    }

    function saturatingAdd(
        InterpreterState memory,
        Operand operand_,
        StackTop stackTop_
    ) internal view returns (StackTop stackTopAfter_) {
        return
            stackTop_.applyFnN(
                SaturatingMath.saturatingAdd,
                Operand.unwrap(operand_)
            );
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

import "../../../../math/SaturatingMath.sol";
import "../../../run/LibStackTop.sol";
import "../../../run/LibInterpreterState.sol";
import "../../../deploy/LibIntegrityState.sol";

/// @title OpSaturatingMul
/// @notice Opcode for multiplying N numbers with saturating multiplication.
library OpSaturatingMul {
    using SaturatingMath for uint256;
    using LibStackTop for StackTop;
    using LibIntegrityState for IntegrityState;

    function integrity(
        IntegrityState memory integrityState_,
        Operand operand_,
        StackTop stackTop_
    ) internal pure returns (StackTop) {
        return
            integrityState_.applyFnN(
                stackTop_,
                SaturatingMath.saturatingMul,
                Operand.unwrap(operand_)
            );
    }

    function saturatingMul(
        InterpreterState memory,
        Operand operand_,
        StackTop stackTop_
    ) internal view returns (StackTop stackTopAfter_) {
        return
            stackTop_.applyFnN(
                SaturatingMath.saturatingMul,
                Operand.unwrap(operand_)
            );
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

import "../../../../math/SaturatingMath.sol";
import "../../../run/LibStackTop.sol";
import "../../../run/LibInterpreterState.sol";
import "../../../deploy/LibIntegrityState.sol";

/// @title OpSaturatingSub
/// @notice Opcode for subtracting N numbers with saturating subtraction.
library OpSaturatingSub {
    using SaturatingMath for uint256;
    using LibStackTop for StackTop;
    using LibIntegrityState for IntegrityState;

    function integrity(
        IntegrityState memory integrityState_,
        Operand operand_,
        StackTop stackTop_
    ) internal pure returns (StackTop) {
        return
            integrityState_.applyFnN(
                stackTop_,
                SaturatingMath.saturatingSub,
                Operand.unwrap(operand_)
            );
    }

    function saturatingSub(
        InterpreterState memory,
        Operand operand_,
        StackTop stackTop_
    ) internal view returns (StackTop stackTopAfter_) {
        return
            stackTop_.applyFnN(
                SaturatingMath.saturatingSub,
                Operand.unwrap(operand_)
            );
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

import "../../run/LibStackTop.sol";
import "../../../array/LibUint256Array.sol";
import "../../run/LibInterpreterState.sol";
import "../../deploy/LibIntegrityState.sol";

/// @title OpAdd
/// @notice Opcode for adding N numbers.
library OpAdd {
    using LibStackTop for StackTop;
    using LibIntegrityState for IntegrityState;

    function _add(uint256 a_, uint256 b_) internal pure returns (uint256) {
        return a_ + b_;
    }

    function integrity(
        IntegrityState memory integrityState_,
        Operand operand_,
        StackTop stackTop_
    ) internal pure returns (StackTop) {
        return
            integrityState_.applyFnN(stackTop_, _add, Operand.unwrap(operand_));
    }

    function add(
        InterpreterState memory,
        Operand operand_,
        StackTop stackTop_
    ) internal view returns (StackTop) {
        return stackTop_.applyFnN(_add, Operand.unwrap(operand_));
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

import "../../run/LibStackTop.sol";
import "../../run/LibInterpreterState.sol";
import "../../deploy/LibIntegrityState.sol";

/// @title OpDiv
/// @notice Opcode for dividing N numbers.
library OpDiv {
    using LibStackTop for StackTop;
    using LibIntegrityState for IntegrityState;

    function _div(uint256 a_, uint256 b_) internal pure returns (uint256) {
        return a_ / b_;
    }

    function integrity(
        IntegrityState memory integrityState_,
        Operand operand_,
        StackTop stackTop_
    ) internal pure returns (StackTop) {
        return
            integrityState_.applyFnN(stackTop_, _div, Operand.unwrap(operand_));
    }

    function div(
        InterpreterState memory,
        Operand operand_,
        StackTop stackTop_
    ) internal view returns (StackTop stackTopAfter_) {
        return stackTop_.applyFnN(_div, Operand.unwrap(operand_));
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

import "../../run/LibStackTop.sol";
import "../../run/LibInterpreterState.sol";
import "../../deploy/LibIntegrityState.sol";

/// @title OpExp
/// @notice Opcode to exponentiate N numbers.
library OpExp {
    using LibStackTop for StackTop;
    using LibIntegrityState for IntegrityState;

    function _exp(uint256 a_, uint256 b_) internal pure returns (uint256) {
        return a_ ** b_;
    }

    function integrity(
        IntegrityState memory integrityState_,
        Operand operand_,
        StackTop stackTop_
    ) internal pure returns (StackTop) {
        return
            integrityState_.applyFnN(stackTop_, _exp, Operand.unwrap(operand_));
    }

    function exp(
        InterpreterState memory,
        Operand operand_,
        StackTop stackTop_
    ) internal view returns (StackTop stackTopAfter_) {
        return stackTop_.applyFnN(_exp, Operand.unwrap(operand_));
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

import "../../run/LibStackTop.sol";
import "../../run/LibInterpreterState.sol";
import "../../deploy/LibIntegrityState.sol";

/// @title OpMax
/// @notice Opcode to stack the maximum of N numbers.
library OpMax {
    using LibStackTop for StackTop;
    using LibIntegrityState for IntegrityState;

    function _max(uint256 a_, uint256 b_) internal pure returns (uint256) {
        return a_ > b_ ? a_ : b_;
    }

    function integrity(
        IntegrityState memory integrityState_,
        Operand operand_,
        StackTop stackTop_
    ) internal pure returns (StackTop) {
        return
            integrityState_.applyFnN(stackTop_, _max, Operand.unwrap(operand_));
    }

    function max(
        InterpreterState memory,
        Operand operand_,
        StackTop stackTop_
    ) internal view returns (StackTop stackTopAfter_) {
        return stackTop_.applyFnN(_max, Operand.unwrap(operand_));
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

import "../../run/LibStackTop.sol";
import "../../run/LibInterpreterState.sol";
import "../../deploy/LibIntegrityState.sol";

/// @title OpMin
/// @notice Opcode to stack the minimum of N numbers.
library OpMin {
    using LibStackTop for StackTop;
    using LibIntegrityState for IntegrityState;

    function _min(uint256 a_, uint256 b_) internal pure returns (uint256) {
        return a_ < b_ ? a_ : b_;
    }

    function integrity(
        IntegrityState memory integrityState_,
        Operand operand_,
        StackTop stackTop_
    ) internal pure returns (StackTop) {
        return
            integrityState_.applyFnN(stackTop_, _min, Operand.unwrap(operand_));
    }

    function min(
        InterpreterState memory,
        Operand operand_,
        StackTop stackTop_
    ) internal view returns (StackTop stackTopAfter_) {
        return stackTop_.applyFnN(_min, Operand.unwrap(operand_));
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

import "../../run/LibStackTop.sol";
import "../../run/LibInterpreterState.sol";
import "../../deploy/LibIntegrityState.sol";

/// @title OpMod
/// @notice Opcode to mod N numbers.
library OpMod {
    using LibStackTop for StackTop;
    using LibIntegrityState for IntegrityState;

    function _mod(uint256 a_, uint256 b_) internal pure returns (uint256) {
        return a_ % b_;
    }

    function integrity(
        IntegrityState memory integrityState_,
        Operand operand_,
        StackTop stackTop_
    ) internal pure returns (StackTop) {
        return
            integrityState_.applyFnN(stackTop_, _mod, Operand.unwrap(operand_));
    }

    function mod(
        InterpreterState memory,
        Operand operand_,
        StackTop stackTop_
    ) internal view returns (StackTop stackTopAfter_) {
        return stackTop_.applyFnN(_mod, Operand.unwrap(operand_));
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

import "../../run/LibStackTop.sol";
import "../../run/LibInterpreterState.sol";
import "../../deploy/LibIntegrityState.sol";

/// @title OpMul
/// @notice Opcode for multiplying N numbers.
library OpMul {
    using LibStackTop for StackTop;
    using LibIntegrityState for IntegrityState;

    function _mul(uint256 a_, uint256 b_) internal pure returns (uint256) {
        return a_ * b_;
    }

    function integrity(
        IntegrityState memory integrityState_,
        Operand operand_,
        StackTop stackTop_
    ) internal pure returns (StackTop) {
        return
            integrityState_.applyFnN(stackTop_, _mul, Operand.unwrap(operand_));
    }

    function mul(
        InterpreterState memory,
        Operand operand_,
        StackTop stackTop_
    ) internal view returns (StackTop stackTopAfter_) {
        return stackTop_.applyFnN(_mul, Operand.unwrap(operand_));
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

import "../../run/LibStackTop.sol";
import "../../run/LibInterpreterState.sol";
import "../../deploy/LibIntegrityState.sol";

/// @title OpSub
/// @notice Opcode for subtracting N numbers.
library OpSub {
    using LibStackTop for StackTop;
    using LibIntegrityState for IntegrityState;

    function _sub(uint256 a_, uint256 b_) internal pure returns (uint256) {
        return a_ - b_;
    }

    function integrity(
        IntegrityState memory integrityState_,
        Operand operand_,
        StackTop stackTop_
    ) internal pure returns (StackTop) {
        return
            integrityState_.applyFnN(stackTop_, _sub, Operand.unwrap(operand_));
    }

    function sub(
        InterpreterState memory,
        Operand operand_,
        StackTop stackTop_
    ) internal view returns (StackTop stackTopAfter_) {
        return stackTop_.applyFnN(_sub, Operand.unwrap(operand_));
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

import "../../../../orderbook/IOrderBookV1.sol";
import "../../../run/LibStackTop.sol";
import "../../../run/LibInterpreterState.sol";
import "../../../deploy/LibIntegrityState.sol";

/// @title OpIOrderBookV1VaultBalance
/// @notice Opcode for IOrderBookV1 `vaultBalance`.
library OpIOrderBookV1VaultBalance {
    using LibStackTop for StackTop;
    using LibIntegrityState for IntegrityState;

    function f(
        uint256 orderbook_,
        uint owner_,
        uint token_,
        uint id_
    ) internal view returns (uint256) {
        return
            uint256(
                uint160(
                    IOrderBookV1(address(uint160(orderbook_))).vaultBalance(
                        address(uint160(owner_)),
                        address(uint160(token_)),
                        id_
                    )
                )
            );
    }

    function integrity(
        IntegrityState memory integrityState_,
        Operand,
        StackTop stackTop_
    ) internal pure returns (StackTop) {
        return integrityState_.applyFn(stackTop_, f);
    }

    function run(
        InterpreterState memory,
        Operand,
        StackTop stackTop_
    ) internal view returns (StackTop) {
        return stackTop_.applyFn(f);
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

import "../../../../sale/ISaleV2.sol";
import "../../../run/LibStackTop.sol";
import "../../../run/LibInterpreterState.sol";
import "../../../deploy/LibIntegrityState.sol";

/// @title OpISaleV2RemainingTokenInventory
/// @notice Opcode for ISaleV2 `remainingTokenInventory`.
library OpISaleV2RemainingTokenInventory {
    using LibStackTop for StackTop;
    using LibIntegrityState for IntegrityState;

    function f(uint256 sale_) internal view returns (uint256) {
        return ISaleV2(address(uint160(sale_))).remainingTokenInventory();
    }

    function integrity(
        IntegrityState memory integrityState_,
        Operand,
        StackTop stackTop_
    ) internal pure returns (StackTop) {
        return integrityState_.applyFn(stackTop_, f);
    }

    /// Stack `remainingTokenInventory`.
    function run(
        InterpreterState memory,
        Operand,
        StackTop stackTop_
    ) internal view returns (StackTop) {
        return stackTop_.applyFn(f);
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.0;

/// An `ISale` can be in one of 4 possible states and a linear progression is
/// expected from an "in flight" status to an immutable definitive outcome.
/// - Pending: The sale is deployed onchain but cannot be interacted with yet.
/// - Active: The sale can now be bought into and otherwise interacted with.
/// - Success: The sale has ended AND reached its minimum raise target.
/// - Fail: The sale has ended BUT NOT reached its minimum raise target.
/// Once an `ISale` reaches `Active` it MUST NOT return `Pending` ever again.
/// Once an `ISale` reaches `Success` or `Fail` it MUST NOT return any other
/// status ever again.
enum SaleStatus {
    Pending,
    Active,
    Success,
    Fail
}

interface ISaleV2 {
    /// Returns the address of the token being sold in the sale.
    /// MUST NOT change during the lifecycle of the sale contract.
    function token() external view returns (address);

    function remainingTokenInventory() external view returns (uint256);

    /// Returns the address of the token that sale prices are denominated in.
    /// MUST NOT change during the lifecycle of the sale contract.
    function reserve() external view returns (address);

    /// total reserve taken in to the sale contract via. buys. Does NOT
    /// include any reserve sent directly to the sale contract outside the
    /// standard buy/refund loop, e.g. due to a dusting attack.
    function totalReserveReceived() external view returns (uint256);

    /// Returns the current `SaleStatus` of the sale.
    /// Represents a linear progression of the sale through its major lifecycle
    /// events.
    function saleStatus() external view returns (SaleStatus);
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

import "../../../../sale/ISaleV2.sol";
import "../../../run/LibStackTop.sol";
import "../../../run/LibInterpreterState.sol";
import "../../../deploy/LibIntegrityState.sol";

/// @title OpISaleV2Reserve
/// @notice Opcode for ISaleV2 `reserve`.
library OpISaleV2Reserve {
    using LibStackTop for StackTop;
    using LibIntegrityState for IntegrityState;

    function f(uint256 sale_) internal view returns (uint256) {
        return uint256(uint160(ISaleV2(address(uint160(sale_))).reserve()));
    }

    function integrity(
        IntegrityState memory integrityState_,
        Operand,
        StackTop stackTop_
    ) internal pure returns (StackTop) {
        return integrityState_.applyFn(stackTop_, f);
    }

    /// Stack `reserve`.
    function run(
        InterpreterState memory,
        Operand,
        StackTop stackTop_
    ) internal view returns (StackTop) {
        return stackTop_.applyFn(f);
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

import "../../../../sale/ISaleV2.sol";
import "../../../run/LibStackTop.sol";
import "../../../run/LibInterpreterState.sol";
import "../../../deploy/LibIntegrityState.sol";

/// @title OpISaleV2SaleStatus
/// @notice Opcode for ISaleV2 `saleStatus`.
library OpISaleV2SaleStatus {
    using LibStackTop for StackTop;
    using LibIntegrityState for IntegrityState;

    function f(uint256 sale_) internal view returns (uint256) {
        return uint(ISaleV2(address(uint160(sale_))).saleStatus());
    }

    function integrity(
        IntegrityState memory integrityState_,
        Operand,
        StackTop stackTop_
    ) internal pure returns (StackTop) {
        return integrityState_.applyFn(stackTop_, f);
    }

    /// Stack `saleStatus`.
    function run(
        InterpreterState memory,
        Operand,
        StackTop stackTop_
    ) internal view returns (StackTop) {
        return stackTop_.applyFn(f);
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

import "../../../../sale/ISaleV2.sol";
import "../../../run/LibStackTop.sol";
import "../../../run/LibInterpreterState.sol";
import "../../../deploy/LibIntegrityState.sol";

/// @title OpISaleV2Token
/// @notice Opcode for ISaleV2 `token`.
library OpISaleV2Token {
    using LibStackTop for StackTop;
    using LibIntegrityState for IntegrityState;

    function f(uint256 sale_) internal view returns (uint256) {
        return uint256(uint160(ISaleV2(address(uint160(sale_))).token()));
    }

    function integrity(
        IntegrityState memory integrityState_,
        Operand,
        StackTop stackTop_
    ) internal pure returns (StackTop) {
        return integrityState_.applyFn(stackTop_, f);
    }

    /// Stack `token`.
    function run(
        InterpreterState memory,
        Operand,
        StackTop stackTop_
    ) internal view returns (StackTop) {
        return stackTop_.applyFn(f);
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

import "../../../../sale/ISaleV2.sol";
import "../../../run/LibStackTop.sol";
import "../../../run/LibInterpreterState.sol";
import "../../../deploy/LibIntegrityState.sol";

/// @title OpISaleV2TotalReserveReceived
/// @notice Opcode for ISaleV2 `totalReserveReceived`.
library OpISaleV2TotalReserveReceived {
    using LibStackTop for StackTop;
    using LibIntegrityState for IntegrityState;

    function f(uint256 sale_) internal view returns (uint256) {
        return ISaleV2(address(uint160(sale_))).totalReserveReceived();
    }

    function integrity(
        IntegrityState memory integrityState_,
        Operand,
        StackTop stackTop_
    ) internal pure returns (StackTop) {
        return integrityState_.applyFn(stackTop_, f);
    }

    /// Stack `totalReserveReceived`.
    function run(
        InterpreterState memory,
        Operand,
        StackTop stackTop_
    ) internal view returns (StackTop) {
        return stackTop_.applyFn(f);
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

import "../../../../verify/IVerifyV1.sol";
import "../../../run/LibStackTop.sol";
import "../../../run/LibInterpreterState.sol";
import "../../../deploy/LibIntegrityState.sol";

/// @title OpIVerifyV1AccountStatusAtTime
/// @notice Opcode for IVerifyV1 `accountStatusAtTime`.
library OpIVerifyV1AccountStatusAtTime {
    using LibStackTop for StackTop;
    using LibIntegrityState for IntegrityState;

    function f(
        uint contract_,
        uint256 account_,
        uint timestamp_
    ) internal view returns (uint256) {
        return
            VerifyStatus.unwrap(
                IVerifyV1(address(uint160(contract_))).accountStatusAtTime(
                    address(uint160(account_)),
                    timestamp_
                )
            );
    }

    function integrity(
        IntegrityState memory integrityState_,
        Operand,
        StackTop stackTop_
    ) internal pure returns (StackTop) {
        return integrityState_.applyFn(stackTop_, f);
    }

    /// Stack `token`.
    function run(
        InterpreterState memory,
        Operand,
        StackTop stackTop_
    ) internal view returns (StackTop) {
        return stackTop_.applyFn(f);
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.0;

type VerifyStatus is uint;

interface IVerifyV1 {
    function accountStatusAtTime(
        address account,
        uint timestamp
    ) external view returns (VerifyStatus);
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

import "../../../tier/ITierV2.sol";
import "../../run/LibStackTop.sol";
import "../../run/LibInterpreterState.sol";
import "../../deploy/LibIntegrityState.sol";

/// @title OpITierV2Report
/// @notice Exposes `ITierV2.report` as an opcode.
library OpITierV2Report {
    using LibStackTop for StackTop;
    using LibStackTop for uint256[];
    using LibIntegrityState for IntegrityState;

    function _report(
        uint256 tierContract_,
        uint256 account_,
        uint256[] memory context_
    ) internal view returns (uint256) {
        return
            ITierV2(address(uint160(tierContract_))).report(
                address(uint160(account_)),
                context_
            );
    }

    function integrity(
        IntegrityState memory integrityState_,
        Operand operand_,
        StackTop stackTop_
    ) internal pure returns (StackTop) {
        return
            integrityState_.applyFn(
                stackTop_,
                _report,
                Operand.unwrap(operand_)
            );
    }

    // Stack the `report` returned by an `ITierV2` contract.
    function report(
        InterpreterState memory,
        Operand operand_,
        StackTop stackTop_
    ) internal view returns (StackTop stackTopAfter_) {
        return stackTop_.applyFn(_report, Operand.unwrap(operand_));
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.0;

/// @title ITierV2
/// @notice `ITierV2` is a simple interface that contracts can implement to
/// provide membership lists for other contracts.
///
/// There are many use-cases for a time-preserving conditional membership list.
///
/// Some examples include:
///
/// - Self-serve whitelist to participate in fundraising
/// - Lists of users who can claim airdrops and perks
/// - Pooling resources with implied governance/reward tiers
/// - POAP style attendance proofs allowing access to future exclusive events
///
/// @dev Standard interface to a tiered membership.
///
/// A "membership" can represent many things:
/// - Exclusive access.
/// - Participation in some event or process.
/// - KYC completion.
/// - Combination of sub-memberships.
/// - Etc.
///
/// The high level requirements for a contract implementing `ITierV2`:
/// - MUST represent held tiers as a `uint`.
/// - MUST implement `report`.
///   - The report is a `uint256` that SHOULD represent the time each tier has
///     been continuously held since encoded as `uint32`.
///   - The encoded tiers start at `1`; Tier `0` is implied if no tier has ever
///     been held.
///   - Tier `0` is NOT encoded in the report, it is simply the fallback value.
///   - If a tier is lost the time data is erased for that tier and will be
///     set if/when the tier is regained to the new time.
///   - If a tier is held but the historical time information is not available
///     the report MAY return `0x00000000` for all held tiers.
///   - Tiers that are lost or have never been held MUST return `0xFFFFFFFF`.
///   - Context can be a list of numbers that MAY pairwise define tiers such as
///     minimum thresholds, or MAY simply provide global context such as a
///     relevant NFT ID for example.
/// - MUST implement `reportTimeForTier`
///   - Functions exactly as `report` but only returns a single time for a
///     single tier
///   - MUST return the same time value `report` would for any given tier and
///     context combination.
///
/// So the four possible states and report values are:
/// - Tier is held and time is known: Timestamp is in the report
/// - Tier is held but time is NOT known: `0` is in the report
/// - Tier is NOT held: `0xFF..` is in the report
/// - Tier is unknown: `0xFF..` is in the report
///
/// The reason `context` is specified as a list of values rather than arbitrary
/// bytes is to allow clear and efficient compatibility with interpreter stacks.
/// Some N values can be taken from an interpreter stack and used directly as a
/// context, which would be difficult or impossible to ensure is safe for
/// arbitrary bytes.
interface ITierV2 {
    /// Same as report but only returns the time for a single tier.
    /// Often the implementing contract can calculate a single tier more
    /// efficiently than all 8 tiers. If the consumer only needs one or a few
    /// tiers it MAY be much cheaper to request only those tiers individually.
    /// This DOES NOT apply to all contracts, an obvious example is token
    /// balance based tiers which always return `ALWAYS` or `NEVER` for all
    /// tiers so no efficiency is gained.
    /// The return value is a `uint256` for gas efficiency but the values will
    /// be bounded by `type(uint32).max` as no single tier can report a value
    /// higher than this.
    function reportTimeForTier(
        address account,
        uint256 tier,
        uint256[] calldata context
    ) external view returns (uint256 time);

    /// Returns an 8 tier encoded report of 32 bit timestamps for the given
    /// account.
    ///
    /// Same as `ITier` (legacy interface) but with a list of values for
    /// `context` which allows a single underlying state to present many
    /// different reports dynamically.
    ///
    /// For example:
    /// - Staking ledgers can calculate different tier thresholds
    /// - NFTs can give different tiers based on different IDs
    /// - Snapshot ERC20s can give different reports based on snapshot ID
    ///
    /// `context` supercedes `setTier` function and `TierChange` event from
    /// `ITier` at the interface level.
    function report(
        address account,
        uint256[] calldata context
    ) external view returns (uint256 report);
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

import "../../../tier/ITierV2.sol";
import "../../run/LibStackTop.sol";
import "../../run/LibInterpreterState.sol";
import "../../deploy/LibIntegrityState.sol";

/// @title OpITierV2Report
/// @notice Exposes `ITierV2.reportTimeForTier` as an opcode.
library OpITierV2ReportTimeForTier {
    using LibStackTop for StackTop;
    using LibStackTop for uint256[];
    using LibIntegrityState for IntegrityState;

    function _reportTimeForTier(
        uint256 tierContract_,
        uint256 account_,
        uint256 tier_,
        uint256[] memory context_
    ) internal view returns (uint256) {
        return
            ITierV2(address(uint160(tierContract_))).reportTimeForTier(
                address(uint160(account_)),
                tier_,
                context_
            );
    }

    function integrity(
        IntegrityState memory integrityState_,
        Operand operand_,
        StackTop stackTop_
    ) internal pure returns (StackTop) {
        return
            integrityState_.applyFn(
                stackTop_,
                _reportTimeForTier,
                Operand.unwrap(operand_)
            );
    }

    // Stack the `reportTimeForTier` returned by an `ITierV2` contract.
    function reportTimeForTier(
        InterpreterState memory,
        Operand operand_,
        StackTop stackTop_
    ) internal view returns (StackTop) {
        return stackTop_.applyFn(_reportTimeForTier, Operand.unwrap(operand_));
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

import "../../../tier/libraries/TierwiseCombine.sol";
import "../../run/LibStackTop.sol";
import "../../run/LibInterpreterState.sol";
import "../../deploy/LibIntegrityState.sol";

library OpSaturatingDiff {
    using LibStackTop for StackTop;
    using LibIntegrityState for IntegrityState;

    function integrity(
        IntegrityState memory integrityState_,
        Operand,
        StackTop stackTop_
    ) internal pure returns (StackTop) {
        return
            integrityState_.applyFn(stackTop_, TierwiseCombine.saturatingSub);
    }

    // Stack the tierwise saturating subtraction of two reports.
    // If the older report is newer than newer report the result will
    // be `0`, else a tierwise diff in blocks will be obtained.
    // The older and newer report are taken from the stack.
    function saturatingDiff(
        InterpreterState memory,
        Operand,
        StackTop stackTop_
    ) internal view returns (StackTop) {
        return stackTop_.applyFn(TierwiseCombine.saturatingSub);
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.0;

import {MathUpgradeable as Math} from "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "./TierReport.sol";
import "../../math/SaturatingMath.sol";

library TierwiseCombine {
    using Math for uint256;
    using SaturatingMath for uint256;

    /// Every lte check in `selectLte` must pass.
    uint256 internal constant LOGIC_EVERY = 0;
    /// Only one lte check in `selectLte` must pass.
    uint256 internal constant LOGIC_ANY = 1;

    /// Select the minimum block number from passing blocks in `selectLte`.
    uint256 internal constant MODE_MIN = 0;
    /// Select the maximum block number from passing blocks in `selectLte`.
    uint256 internal constant MODE_MAX = 1;
    /// Select the first block number that passes in `selectLte`.
    uint256 internal constant MODE_FIRST = 2;

    /// Performs a tierwise saturating subtraction of two reports.
    /// Intepret as "# of blocks older report was held before newer report".
    /// If older report is in fact newer then `0` will be returned.
    /// i.e. the diff cannot be negative, older report as simply spent 0 blocks
    /// existing before newer report, if it is in truth the newer report.
    /// @param newerReport_ Block to subtract from.
    /// @param olderReport_ Block to subtract.
    function saturatingSub(
        uint256 newerReport_,
        uint256 olderReport_
    ) internal pure returns (uint256) {
        unchecked {
            uint256 ret_;
            for (uint256 tier_ = 1; tier_ <= 8; tier_++) {
                uint256 newerBlock_ = TierReport.reportTimeForTier(
                    newerReport_,
                    tier_
                );
                uint256 olderBlock_ = TierReport.reportTimeForTier(
                    olderReport_,
                    tier_
                );
                uint256 diff_ = newerBlock_.saturatingSub(olderBlock_);
                ret_ = TierReport.updateTimeAtTier(ret_, tier_ - 1, diff_);
            }
            return ret_;
        }
    }

    /// Given a list of reports, selects the best tier in a tierwise fashion.
    /// The "best" criteria can be configured by `logic_` and `mode_`.
    /// Logic can be "every" or "any", which means that the reports for a given
    /// tier must either all or any be less than or equal to the reference
    /// `blockNumber_`.
    /// Mode can be "min", "max", "first" which selects between all the block
    /// numbers for a given tier that meet the lte criteria.
    /// IMPORTANT: If the output of `selectLte` is used to write to storage
    /// care must be taken to ensure that "upcoming" tiers relative to the
    /// `blockNumber_` are not overwritten inappropriately. Typically this
    /// function should be used as a filter over reads only from an upstream
    /// source of truth.
    /// @param reports_ The list of reports to select over.
    /// @param blockNumber_ The block number that tier blocks must be lte.
    /// @param logic_ `LOGIC_EVERY` or `LOGIC_ANY`.
    /// @param mode_ `MODE_MIN`, `MODE_MAX` or `MODE_FIRST`.
    function selectLte(
        uint256 logic_,
        uint256 mode_,
        uint256 blockNumber_,
        uint256[] memory reports_
    ) internal pure returns (uint256) {
        unchecked {
            uint256 ret_;
            uint256 block_;
            bool anyLte_;
            uint256 length_ = reports_.length;
            for (uint256 tier_ = 1; tier_ <= 8; tier_++) {
                uint256 accumulator_;
                // Nothing lte the reference block for this tier yet.
                anyLte_ = false;

                // Initialize the accumulator for this tier.
                if (mode_ == MODE_MIN) {
                    accumulator_ = TierConstants.NEVER_REPORT;
                } else {
                    accumulator_ = 0;
                }

                // Filter all the blocks at the current tier from all the
                // reports against the reference tier and each other.
                for (uint256 i_ = 0; i_ < length_; i_++) {
                    block_ = TierReport.reportTimeForTier(reports_[i_], tier_);

                    if (block_ <= blockNumber_) {
                        // Min and max need to compare current value against
                        // the accumulator.
                        if (mode_ == MODE_MIN) {
                            accumulator_ = block_.min(accumulator_);
                        } else if (mode_ == MODE_MAX) {
                            accumulator_ = block_.max(accumulator_);
                        } else if (mode_ == MODE_FIRST && !anyLte_) {
                            accumulator_ = block_;
                        }
                        anyLte_ = true;
                    } else if (logic_ == LOGIC_EVERY) {
                        // Can short circuit for an "every" check.
                        accumulator_ = TierConstants.NEVER_REPORT;
                        break;
                    }
                }
                if (!anyLte_) {
                    accumulator_ = TierConstants.NEVER_REPORT;
                }
                ret_ = TierReport.updateTimeAtTier(
                    ret_,
                    tier_ - 1,
                    accumulator_
                );
            }
            return ret_;
        }
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.0;

import {ITierV2} from "../ITierV2.sol";
import "./TierConstants.sol";

/// @title TierReport
/// @notice `TierReport` implements several pure functions that can be
/// used to interface with reports.
/// - `tierAtTimeFromReport`: Returns the highest status achieved relative to
/// a block timestamp and report. Statuses gained after that block are ignored.
/// - `tierTime`: Returns the timestamp that a given tier has been held
/// since according to a report.
/// - `truncateTiersAbove`: Resets all the tiers above the reference tier.
/// - `updateTimesForTierRange`: Updates a report with a timestamp for every
///    tier in a range.
/// - `updateReportWithTierAtTime`: Updates a report to a new tier.
/// @dev Utilities to consistently read, write and manipulate tiers in reports.
/// The low-level bit shifting can be difficult to get right so this
/// factors that out.
library TierReport {
    /// Enforce upper limit on tiers so we can do unchecked math.
    /// @param tier_ The tier to enforce bounds on.
    modifier maxTier(uint256 tier_) {
        require(tier_ <= TierConstants.MAX_TIER, "MAX_TIER");
        _;
    }

    /// Returns the highest tier achieved relative to a block timestamp
    /// and report.
    ///
    /// Note that typically the report will be from the _current_ contract
    /// state, i.e. `block.timestamp` but not always. Tiers gained after the
    /// reference time are ignored.
    ///
    /// When the `report` comes from a later block than the `timestamp_` this
    /// means the user must have held the tier continuously from `timestamp_`
    /// _through_ to the report time.
    /// I.e. NOT a snapshot.
    ///
    /// @param report_ A report as per `ITierV2`.
    /// @param timestamp_ The timestamp to check the tiers against.
    /// @return tier_ The highest tier held since `timestamp_` as per `report`.
    function tierAtTimeFromReport(
        uint256 report_,
        uint256 timestamp_
    ) internal pure returns (uint256 tier_) {
        unchecked {
            for (tier_ = 0; tier_ < 8; tier_++) {
                if (uint32(uint256(report_ >> (tier_ * 32))) > timestamp_) {
                    break;
                }
            }
        }
    }

    /// Returns the timestamp that a given tier has been held since from a
    /// report.
    ///
    /// The report MUST encode "never" as 0xFFFFFFFF. This ensures
    /// compatibility with `tierAtTimeFromReport`.
    ///
    /// @param report_ The report to read a timestamp from.
    /// @param tier_ The Tier to read the timestamp for.
    /// @return The timestamp the tier has been held since.
    function reportTimeForTier(
        uint256 report_,
        uint256 tier_
    ) internal pure maxTier(tier_) returns (uint256) {
        unchecked {
            // ZERO is a special case. Everyone has always been at least ZERO,
            // since block 0.
            if (tier_ == 0) {
                return 0;
            }

            uint256 offset_ = (tier_ - 1) * 32;
            return uint256(uint32(uint256(report_ >> offset_)));
        }
    }

    /// Resets all the tiers above the reference tier to 0xFFFFFFFF.
    ///
    /// @param report_ Report to truncate with high bit 1s.
    /// @param tier_ Tier to truncate above (exclusive).
    /// @return Truncated report.
    function truncateTiersAbove(
        uint256 report_,
        uint256 tier_
    ) internal pure maxTier(tier_) returns (uint256) {
        unchecked {
            uint256 offset_ = tier_ * 32;
            uint256 mask_ = (TierConstants.NEVER_REPORT >> offset_) << offset_;
            return report_ | mask_;
        }
    }

    /// Updates a report with a timestamp for a given tier.
    /// More gas efficient than `updateTimesForTierRange` if only a single
    /// tier is being modified.
    /// The tier at/above the given tier is updated. E.g. tier `0` will update
    /// the time for tier `1`.
    /// @param report_ Report to use as the baseline for the updated report.
    /// @param tier_ The tier level to update.
    /// @param timestamp_ The new block number for `tier_`.
    /// @return The newly updated `report_`.
    function updateTimeAtTier(
        uint256 report_,
        uint256 tier_,
        uint256 timestamp_
    ) internal pure maxTier(tier_) returns (uint256) {
        unchecked {
            uint256 offset_ = tier_ * 32;
            return
                (report_ &
                    ~uint256(uint256(TierConstants.NEVER_TIME) << offset_)) |
                uint256(timestamp_ << offset_);
        }
    }

    /// Updates a report with a block number for every tier in a range.
    ///
    /// Does nothing if the end status is equal or less than the start tier.
    /// @param report_ The report to update.
    /// @param startTier_ The tier at the start of the range (exclusive).
    /// @param endTier_ The tier at the end of the range (inclusive).
    /// @param timestamp_ The timestamp to set for every tier in the range.
    /// @return The updated report.
    function updateTimesForTierRange(
        uint256 report_,
        uint256 startTier_,
        uint256 endTier_,
        uint256 timestamp_
    ) internal pure maxTier(endTier_) returns (uint256) {
        unchecked {
            uint256 offset_;
            for (uint256 i_ = startTier_; i_ < endTier_; i_++) {
                offset_ = i_ * 32;
                report_ =
                    (report_ &
                        ~uint256(
                            uint256(TierConstants.NEVER_TIME) << offset_
                        )) |
                    uint256(timestamp_ << offset_);
            }
            return report_;
        }
    }

    /// Updates a report to a new status.
    ///
    /// Internally dispatches to `truncateTiersAbove` and
    /// `updateBlocksForTierRange`.
    /// The dispatch is based on whether the new tier is above or below the
    /// current tier.
    /// The `startTier_` MUST match the result of `tierAtBlockFromReport`.
    /// It is expected the caller will know the current tier when
    /// calling this function and need to do other things in the calling scope
    /// with it.
    ///
    /// @param report_ The report to update.
    /// @param startTier_ The tier to start updating relative to. Data above
    /// this tier WILL BE LOST so probably should be the current tier.
    /// @param endTier_ The new highest tier held, at the given timestamp_.
    /// @param timestamp_ The timestamp_ to update the highest tier to, and
    /// intermediate tiers from `startTier_`.
    /// @return The updated report.
    function updateReportWithTierAtTime(
        uint256 report_,
        uint256 startTier_,
        uint256 endTier_,
        uint256 timestamp_
    ) internal pure returns (uint256) {
        return
            endTier_ < startTier_
                ? truncateTiersAbove(report_, endTier_)
                : updateTimesForTierRange(
                    report_,
                    startTier_,
                    endTier_,
                    timestamp_
                );
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.0;

/// @title TierConstants
/// @notice Constants for use with tier logic.
library TierConstants {
    /// NEVER is 0xFF.. as it is infinitely in the future.
    /// NEVER for an entire report.
    uint256 internal constant NEVER_REPORT = type(uint256).max;
    /// NEVER for a single tier time.
    uint32 internal constant NEVER_TIME = type(uint32).max;

    /// Always is 0 as negative timestamps are not possible/supported onchain.
    /// Tiers can't predate the chain but they can predate an `ITierV2`
    /// contract.
    uint256 internal constant ALWAYS = 0;

    /// Account has never held a tier.
    uint256 internal constant TIER_ZERO = 0;

    /// Magic number for tier one.
    uint256 internal constant TIER_ONE = 1;
    /// Magic number for tier two.
    uint256 internal constant TIER_TWO = 2;
    /// Magic number for tier three.
    uint256 internal constant TIER_THREE = 3;
    /// Magic number for tier four.
    uint256 internal constant TIER_FOUR = 4;
    /// Magic number for tier five.
    uint256 internal constant TIER_FIVE = 5;
    /// Magic number for tier six.
    uint256 internal constant TIER_SIX = 6;
    /// Magic number for tier seven.
    uint256 internal constant TIER_SEVEN = 7;
    /// Magic number for tier eight.
    uint256 internal constant TIER_EIGHT = 8;
    /// Maximum tier is `TIER_EIGHT`.
    uint256 internal constant MAX_TIER = TIER_EIGHT;
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

import "../../../tier/libraries/TierwiseCombine.sol";
import "../../run/LibStackTop.sol";
import "../../run/LibInterpreterState.sol";
import "../../deploy/LibIntegrityState.sol";
import "../../../math/Binary.sol";

/// @title OpSelectLte
/// @notice Exposes `TierwiseCombine.selectLte` as an opcode.
library OpSelectLte {
    using LibStackTop for StackTop;
    using LibStackTop for uint256[];
    using LibIntegrityState for IntegrityState;

    function integrity(
        IntegrityState memory integrityState_,
        Operand operand_,
        StackTop stackTop_
    ) internal pure returns (StackTop) {
        unchecked {
            uint256 inputs_ = Operand.unwrap(operand_) & MASK_8BIT;
            require(inputs_ > 0, "SELECT_LTE_ZERO_INPUTS");
            return
                integrityState_.push(integrityState_.pop(stackTop_, inputs_));
        }
    }

    // Stacks the result of a `selectLte` combinator.
    // All `selectLte` share the same stack and argument handling.
    // Takes the `logic_` and `mode_` from the `operand_` high bits.
    // `logic_` is the highest bit.
    // `mode_` is the 2 highest bits after `logic_`.
    // The other bits specify how many values to take from the stack
    // as reports to compare against each other and the block number.
    function selectLte(
        InterpreterState memory,
        Operand operand_,
        StackTop stackTop_
    ) internal pure returns (StackTop) {
        unchecked {
            uint inputs_ = Operand.unwrap(operand_) & MASK_8BIT;
            uint mode_ = (Operand.unwrap(operand_) >> 8) & MASK_2BIT;
            uint logic_ = Operand.unwrap(operand_) >> 10;
            (uint256 time_, uint256[] memory reports_) = stackTop_.list(
                inputs_
            );
            return
                reports_.asStackTop().push(
                    TierwiseCombine.selectLte(logic_, mode_, time_, reports_)
                );
        }
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

import "../../../tier/libraries/TierReport.sol";
import "../../run/LibStackTop.sol";
import "../../run/LibInterpreterState.sol";
import "../../deploy/LibIntegrityState.sol";

library OpUpdateTimesForTierRange {
    using LibStackTop for StackTop;
    using LibIntegrityState for IntegrityState;

    function _updateTimesForTierRange(
        Operand operand_,
        uint256 report_,
        uint256 timestamp_
    ) internal pure returns (uint256) {
        return
            TierReport.updateTimesForTierRange(
                report_,
                // start tier.
                // 4 low bits.
                Operand.unwrap(operand_) & 0x0f,
                // end tier.
                // 4 high bits.
                (Operand.unwrap(operand_) >> 4) & 0x0f,
                timestamp_
            );
    }

    function integrity(
        IntegrityState memory integrityState_,
        Operand,
        StackTop stackTop_
    ) internal pure returns (StackTop) {
        return integrityState_.applyFn(stackTop_, _updateTimesForTierRange);
    }

    // Stacks a report with updated times over tier range.
    // The start and end tier are taken from the low and high bits of
    // the `operand_` respectively.
    // The report to update and timestamp to update to are both
    // taken from the stack.
    function updateTimesForTierRange(
        InterpreterState memory,
        Operand operand_,
        StackTop stackTop_
    ) internal view returns (StackTop) {
        return stackTop_.applyFn(_updateTimesForTierRange, operand_);
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.0;

import {IERC20Upgradeable as IERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {SafeERC20Upgradeable as SafeERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "../ierc3156/IERC3156FlashBorrower.sol";
import "../ierc3156/IERC3156FlashLender.sol";

/**
 * @author Alberto Cuesta Cañada
 * @dev Extension of {ERC20} that allows flash lending.
 */
contract OrderBookFlashLender is IERC3156FlashLender {
    bytes32 public constant CALLBACK_SUCCESS =
        keccak256("ERC3156FlashBorrower.onFlashLoan");
    using SafeERC20 for IERC20;

    // token => receiver => active debt
    mapping(address => mapping(address => uint)) internal activeFlashDebts;

    function _increaseFlashDebtThenSendToken(
        address token_,
        address receiver_,
        uint amount_
    ) internal {
        activeFlashDebts[token_][receiver_] += amount_;
        IERC20(token_).safeTransfer(receiver_, amount_);
    }

    function _decreaseFlashDebtThenSendToken(
        address token_,
        address receiver_,
        uint amount_
    ) internal {
        uint activeFlashDebt_ = activeFlashDebts[token_][receiver_];
        if (amount_ > activeFlashDebt_) {
            if (activeFlashDebt_ > 0) {
                delete activeFlashDebts[token_][receiver_];
            }

            IERC20(token_).safeTransfer(receiver_, amount_ - activeFlashDebt_);
        } else {
            activeFlashDebts[token_][receiver_] -= amount_;
        }
    }

    function _finalizeDebt(address token_, address receiver_) internal {
        uint activeFlashDebt_ = activeFlashDebts[token_][receiver_];
        if (activeFlashDebt_ > 0) {
            IERC20(token_).safeTransferFrom(
                receiver_,
                address(this),
                activeFlashDebt_
            );
            // Once we have the tokens safely in hand decrease the debt.
            activeFlashDebts[token_][receiver_] -= activeFlashDebt_;
        }
        require(activeFlashDebts[token_][receiver_] == 0, "BAD_DEBT");
    }

    /// @inheritdoc IERC3156FlashLender
    function flashLoan(
        IERC3156FlashBorrower receiver_,
        address token_,
        uint256 amount_,
        bytes calldata data_
    ) external override returns (bool) {
        _increaseFlashDebtThenSendToken(token_, address(receiver_), amount_);
        require(
            receiver_.onFlashLoan(msg.sender, token_, amount_, 0, data_) ==
                CALLBACK_SUCCESS,
            "FlashLender: Callback failed"
        );
        _finalizeDebt(token_, address(receiver_));
        return true;
    }

    /// @inheritdoc IERC3156FlashLender
    function flashFee(
        address,
        uint256
    ) external pure override returns (uint256) {
        return 0;
    }

    /// @inheritdoc IERC3156FlashLender
    function maxFlashLoan(
        address token_
    ) external view override returns (uint256) {
        return IERC20(token_).balanceOf(address(this));
    }
}

// SPDX-License-Identifier: CC0
// Alberto Cuesta Cañada, Fiona Kobayashi, fubuloubu, Austin Williams, "EIP-3156: Flash Loans," Ethereum Improvement Proposals, no. 3156, November 2020. [Online serial]. Available: https://eips.ethereum.org/EIPS/eip-3156.
pragma solidity ^0.8.0;

interface IERC3156FlashBorrower {
    /**
     * @dev Receive a flash loan.
     * @param initiator The initiator of the loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param fee The additional amount of tokens to repay.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     * @return The keccak256 hash of "ERC3156FlashBorrower.onFlashLoan"
     */
    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bytes32);
}

// SPDX-License-Identifier: CC0
// Alberto Cuesta Cañada, Fiona Kobayashi, fubuloubu, Austin Williams, "EIP-3156: Flash Loans," Ethereum Improvement Proposals, no. 3156, November 2020. [Online serial]. Available: https://eips.ethereum.org/EIPS/eip-3156.
pragma solidity ^0.8.0;
import "./IERC3156FlashBorrower.sol";

interface IERC3156FlashLender {
    /**
     * @dev The amount of currency available to be lent.
     * @param token The loan currency.
     * @return The amount of `token` that can be borrowed.
     */
    function maxFlashLoan(address token) external view returns (uint256);

    /**
     * @dev The fee to be charged for a given loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @return The amount of `token` to be charged for the loan, on top of the returned principal.
     */
    function flashFee(
        address token,
        uint256 amount
    ) external view returns (uint256);

    /**
     * @dev Initiate a flash loan.
     * @param receiver The receiver of the tokens in the loan, and the receiver of the callback.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     */
    function flashLoan(
        IERC3156FlashBorrower receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) external returns (bool);
}

// SPDX-License-Identifier: CAL
pragma solidity =0.8.17;

import "./IInterpreterV1.sol";

library LibEncodedDispatch {
    function encode(
        address expressionPointer_,
        SourceIndex sourceIndex_,
        uint maxOutputs_
    ) internal pure returns (EncodedDispatch) {
        return
            EncodedDispatch.wrap(
                (uint(uint160(expressionPointer_)) << 32) |
                    (SourceIndex.unwrap(sourceIndex_) << 16) |
                    maxOutputs_
            );
    }

    function decode(
        EncodedDispatch dispatch_
    ) internal pure returns (address, SourceIndex, uint) {
        return (
            address(uint160(EncodedDispatch.unwrap(dispatch_) >> 32)),
            SourceIndex.wrap((EncodedDispatch.unwrap(dispatch_) >> 16) & 0xFF),
            EncodedDispatch.unwrap(dispatch_) & 0xFF
        );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

import "../IERC20Upgradeable.sol";
import "../extensions/draft-IERC20PermitUpgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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
        IERC20PermitUpgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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
interface IERC20PermitUpgradeable {
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Multicall.sol)

pragma solidity ^0.8.0;

import "./AddressUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides a function to batch together multiple calls in a single external call.
 *
 * _Available since v4.1._
 */
abstract contract MulticallUpgradeable is Initializable {
    function __Multicall_init() internal onlyInitializing {
    }

    function __Multicall_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev Receives and executes a batch of function calls on this contract.
     */
    function multicall(bytes[] calldata data) external virtual returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            results[i] = _functionDelegateCall(address(this), data[i]);
        }
        return results;
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SafeCast.sol)
// This file was procedurally generated from scripts/generate/templates/SafeCast.js.

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCastUpgradeable {
    /**
     * @dev Returns the downcasted uint248 from uint256, reverting on
     * overflow (when the input is greater than largest uint248).
     *
     * Counterpart to Solidity's `uint248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toUint248(uint256 value) internal pure returns (uint248) {
        require(value <= type(uint248).max, "SafeCast: value doesn't fit in 248 bits");
        return uint248(value);
    }

    /**
     * @dev Returns the downcasted uint240 from uint256, reverting on
     * overflow (when the input is greater than largest uint240).
     *
     * Counterpart to Solidity's `uint240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toUint240(uint256 value) internal pure returns (uint240) {
        require(value <= type(uint240).max, "SafeCast: value doesn't fit in 240 bits");
        return uint240(value);
    }

    /**
     * @dev Returns the downcasted uint232 from uint256, reverting on
     * overflow (when the input is greater than largest uint232).
     *
     * Counterpart to Solidity's `uint232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toUint232(uint256 value) internal pure returns (uint232) {
        require(value <= type(uint232).max, "SafeCast: value doesn't fit in 232 bits");
        return uint232(value);
    }

    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.2._
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint216 from uint256, reverting on
     * overflow (when the input is greater than largest uint216).
     *
     * Counterpart to Solidity's `uint216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toUint216(uint256 value) internal pure returns (uint216) {
        require(value <= type(uint216).max, "SafeCast: value doesn't fit in 216 bits");
        return uint216(value);
    }

    /**
     * @dev Returns the downcasted uint208 from uint256, reverting on
     * overflow (when the input is greater than largest uint208).
     *
     * Counterpart to Solidity's `uint208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toUint208(uint256 value) internal pure returns (uint208) {
        require(value <= type(uint208).max, "SafeCast: value doesn't fit in 208 bits");
        return uint208(value);
    }

    /**
     * @dev Returns the downcasted uint200 from uint256, reverting on
     * overflow (when the input is greater than largest uint200).
     *
     * Counterpart to Solidity's `uint200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toUint200(uint256 value) internal pure returns (uint200) {
        require(value <= type(uint200).max, "SafeCast: value doesn't fit in 200 bits");
        return uint200(value);
    }

    /**
     * @dev Returns the downcasted uint192 from uint256, reverting on
     * overflow (when the input is greater than largest uint192).
     *
     * Counterpart to Solidity's `uint192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toUint192(uint256 value) internal pure returns (uint192) {
        require(value <= type(uint192).max, "SafeCast: value doesn't fit in 192 bits");
        return uint192(value);
    }

    /**
     * @dev Returns the downcasted uint184 from uint256, reverting on
     * overflow (when the input is greater than largest uint184).
     *
     * Counterpart to Solidity's `uint184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toUint184(uint256 value) internal pure returns (uint184) {
        require(value <= type(uint184).max, "SafeCast: value doesn't fit in 184 bits");
        return uint184(value);
    }

    /**
     * @dev Returns the downcasted uint176 from uint256, reverting on
     * overflow (when the input is greater than largest uint176).
     *
     * Counterpart to Solidity's `uint176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toUint176(uint256 value) internal pure returns (uint176) {
        require(value <= type(uint176).max, "SafeCast: value doesn't fit in 176 bits");
        return uint176(value);
    }

    /**
     * @dev Returns the downcasted uint168 from uint256, reverting on
     * overflow (when the input is greater than largest uint168).
     *
     * Counterpart to Solidity's `uint168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toUint168(uint256 value) internal pure returns (uint168) {
        require(value <= type(uint168).max, "SafeCast: value doesn't fit in 168 bits");
        return uint168(value);
    }

    /**
     * @dev Returns the downcasted uint160 from uint256, reverting on
     * overflow (when the input is greater than largest uint160).
     *
     * Counterpart to Solidity's `uint160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toUint160(uint256 value) internal pure returns (uint160) {
        require(value <= type(uint160).max, "SafeCast: value doesn't fit in 160 bits");
        return uint160(value);
    }

    /**
     * @dev Returns the downcasted uint152 from uint256, reverting on
     * overflow (when the input is greater than largest uint152).
     *
     * Counterpart to Solidity's `uint152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toUint152(uint256 value) internal pure returns (uint152) {
        require(value <= type(uint152).max, "SafeCast: value doesn't fit in 152 bits");
        return uint152(value);
    }

    /**
     * @dev Returns the downcasted uint144 from uint256, reverting on
     * overflow (when the input is greater than largest uint144).
     *
     * Counterpart to Solidity's `uint144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toUint144(uint256 value) internal pure returns (uint144) {
        require(value <= type(uint144).max, "SafeCast: value doesn't fit in 144 bits");
        return uint144(value);
    }

    /**
     * @dev Returns the downcasted uint136 from uint256, reverting on
     * overflow (when the input is greater than largest uint136).
     *
     * Counterpart to Solidity's `uint136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toUint136(uint256 value) internal pure returns (uint136) {
        require(value <= type(uint136).max, "SafeCast: value doesn't fit in 136 bits");
        return uint136(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v2.5._
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint120 from uint256, reverting on
     * overflow (when the input is greater than largest uint120).
     *
     * Counterpart to Solidity's `uint120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toUint120(uint256 value) internal pure returns (uint120) {
        require(value <= type(uint120).max, "SafeCast: value doesn't fit in 120 bits");
        return uint120(value);
    }

    /**
     * @dev Returns the downcasted uint112 from uint256, reverting on
     * overflow (when the input is greater than largest uint112).
     *
     * Counterpart to Solidity's `uint112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toUint112(uint256 value) internal pure returns (uint112) {
        require(value <= type(uint112).max, "SafeCast: value doesn't fit in 112 bits");
        return uint112(value);
    }

    /**
     * @dev Returns the downcasted uint104 from uint256, reverting on
     * overflow (when the input is greater than largest uint104).
     *
     * Counterpart to Solidity's `uint104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toUint104(uint256 value) internal pure returns (uint104) {
        require(value <= type(uint104).max, "SafeCast: value doesn't fit in 104 bits");
        return uint104(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.2._
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint88 from uint256, reverting on
     * overflow (when the input is greater than largest uint88).
     *
     * Counterpart to Solidity's `uint88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toUint88(uint256 value) internal pure returns (uint88) {
        require(value <= type(uint88).max, "SafeCast: value doesn't fit in 88 bits");
        return uint88(value);
    }

    /**
     * @dev Returns the downcasted uint80 from uint256, reverting on
     * overflow (when the input is greater than largest uint80).
     *
     * Counterpart to Solidity's `uint80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toUint80(uint256 value) internal pure returns (uint80) {
        require(value <= type(uint80).max, "SafeCast: value doesn't fit in 80 bits");
        return uint80(value);
    }

    /**
     * @dev Returns the downcasted uint72 from uint256, reverting on
     * overflow (when the input is greater than largest uint72).
     *
     * Counterpart to Solidity's `uint72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toUint72(uint256 value) internal pure returns (uint72) {
        require(value <= type(uint72).max, "SafeCast: value doesn't fit in 72 bits");
        return uint72(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v2.5._
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint56 from uint256, reverting on
     * overflow (when the input is greater than largest uint56).
     *
     * Counterpart to Solidity's `uint56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toUint56(uint256 value) internal pure returns (uint56) {
        require(value <= type(uint56).max, "SafeCast: value doesn't fit in 56 bits");
        return uint56(value);
    }

    /**
     * @dev Returns the downcasted uint48 from uint256, reverting on
     * overflow (when the input is greater than largest uint48).
     *
     * Counterpart to Solidity's `uint48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toUint48(uint256 value) internal pure returns (uint48) {
        require(value <= type(uint48).max, "SafeCast: value doesn't fit in 48 bits");
        return uint48(value);
    }

    /**
     * @dev Returns the downcasted uint40 from uint256, reverting on
     * overflow (when the input is greater than largest uint40).
     *
     * Counterpart to Solidity's `uint40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toUint40(uint256 value) internal pure returns (uint40) {
        require(value <= type(uint40).max, "SafeCast: value doesn't fit in 40 bits");
        return uint40(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v2.5._
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint24 from uint256, reverting on
     * overflow (when the input is greater than largest uint24).
     *
     * Counterpart to Solidity's `uint24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toUint24(uint256 value) internal pure returns (uint24) {
        require(value <= type(uint24).max, "SafeCast: value doesn't fit in 24 bits");
        return uint24(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v2.5._
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v2.5._
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     *
     * _Available since v3.0._
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int248 from int256, reverting on
     * overflow (when the input is less than smallest int248 or
     * greater than largest int248).
     *
     * Counterpart to Solidity's `int248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toInt248(int256 value) internal pure returns (int248 downcasted) {
        downcasted = int248(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 248 bits");
    }

    /**
     * @dev Returns the downcasted int240 from int256, reverting on
     * overflow (when the input is less than smallest int240 or
     * greater than largest int240).
     *
     * Counterpart to Solidity's `int240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toInt240(int256 value) internal pure returns (int240 downcasted) {
        downcasted = int240(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 240 bits");
    }

    /**
     * @dev Returns the downcasted int232 from int256, reverting on
     * overflow (when the input is less than smallest int232 or
     * greater than largest int232).
     *
     * Counterpart to Solidity's `int232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toInt232(int256 value) internal pure returns (int232 downcasted) {
        downcasted = int232(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 232 bits");
    }

    /**
     * @dev Returns the downcasted int224 from int256, reverting on
     * overflow (when the input is less than smallest int224 or
     * greater than largest int224).
     *
     * Counterpart to Solidity's `int224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.7._
     */
    function toInt224(int256 value) internal pure returns (int224 downcasted) {
        downcasted = int224(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 224 bits");
    }

    /**
     * @dev Returns the downcasted int216 from int256, reverting on
     * overflow (when the input is less than smallest int216 or
     * greater than largest int216).
     *
     * Counterpart to Solidity's `int216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toInt216(int256 value) internal pure returns (int216 downcasted) {
        downcasted = int216(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 216 bits");
    }

    /**
     * @dev Returns the downcasted int208 from int256, reverting on
     * overflow (when the input is less than smallest int208 or
     * greater than largest int208).
     *
     * Counterpart to Solidity's `int208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toInt208(int256 value) internal pure returns (int208 downcasted) {
        downcasted = int208(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 208 bits");
    }

    /**
     * @dev Returns the downcasted int200 from int256, reverting on
     * overflow (when the input is less than smallest int200 or
     * greater than largest int200).
     *
     * Counterpart to Solidity's `int200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toInt200(int256 value) internal pure returns (int200 downcasted) {
        downcasted = int200(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 200 bits");
    }

    /**
     * @dev Returns the downcasted int192 from int256, reverting on
     * overflow (when the input is less than smallest int192 or
     * greater than largest int192).
     *
     * Counterpart to Solidity's `int192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toInt192(int256 value) internal pure returns (int192 downcasted) {
        downcasted = int192(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 192 bits");
    }

    /**
     * @dev Returns the downcasted int184 from int256, reverting on
     * overflow (when the input is less than smallest int184 or
     * greater than largest int184).
     *
     * Counterpart to Solidity's `int184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toInt184(int256 value) internal pure returns (int184 downcasted) {
        downcasted = int184(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 184 bits");
    }

    /**
     * @dev Returns the downcasted int176 from int256, reverting on
     * overflow (when the input is less than smallest int176 or
     * greater than largest int176).
     *
     * Counterpart to Solidity's `int176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toInt176(int256 value) internal pure returns (int176 downcasted) {
        downcasted = int176(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 176 bits");
    }

    /**
     * @dev Returns the downcasted int168 from int256, reverting on
     * overflow (when the input is less than smallest int168 or
     * greater than largest int168).
     *
     * Counterpart to Solidity's `int168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toInt168(int256 value) internal pure returns (int168 downcasted) {
        downcasted = int168(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 168 bits");
    }

    /**
     * @dev Returns the downcasted int160 from int256, reverting on
     * overflow (when the input is less than smallest int160 or
     * greater than largest int160).
     *
     * Counterpart to Solidity's `int160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toInt160(int256 value) internal pure returns (int160 downcasted) {
        downcasted = int160(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 160 bits");
    }

    /**
     * @dev Returns the downcasted int152 from int256, reverting on
     * overflow (when the input is less than smallest int152 or
     * greater than largest int152).
     *
     * Counterpart to Solidity's `int152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toInt152(int256 value) internal pure returns (int152 downcasted) {
        downcasted = int152(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 152 bits");
    }

    /**
     * @dev Returns the downcasted int144 from int256, reverting on
     * overflow (when the input is less than smallest int144 or
     * greater than largest int144).
     *
     * Counterpart to Solidity's `int144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toInt144(int256 value) internal pure returns (int144 downcasted) {
        downcasted = int144(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 144 bits");
    }

    /**
     * @dev Returns the downcasted int136 from int256, reverting on
     * overflow (when the input is less than smallest int136 or
     * greater than largest int136).
     *
     * Counterpart to Solidity's `int136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toInt136(int256 value) internal pure returns (int136 downcasted) {
        downcasted = int136(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 136 bits");
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128 downcasted) {
        downcasted = int128(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 128 bits");
    }

    /**
     * @dev Returns the downcasted int120 from int256, reverting on
     * overflow (when the input is less than smallest int120 or
     * greater than largest int120).
     *
     * Counterpart to Solidity's `int120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toInt120(int256 value) internal pure returns (int120 downcasted) {
        downcasted = int120(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 120 bits");
    }

    /**
     * @dev Returns the downcasted int112 from int256, reverting on
     * overflow (when the input is less than smallest int112 or
     * greater than largest int112).
     *
     * Counterpart to Solidity's `int112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toInt112(int256 value) internal pure returns (int112 downcasted) {
        downcasted = int112(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 112 bits");
    }

    /**
     * @dev Returns the downcasted int104 from int256, reverting on
     * overflow (when the input is less than smallest int104 or
     * greater than largest int104).
     *
     * Counterpart to Solidity's `int104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toInt104(int256 value) internal pure returns (int104 downcasted) {
        downcasted = int104(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 104 bits");
    }

    /**
     * @dev Returns the downcasted int96 from int256, reverting on
     * overflow (when the input is less than smallest int96 or
     * greater than largest int96).
     *
     * Counterpart to Solidity's `int96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.7._
     */
    function toInt96(int256 value) internal pure returns (int96 downcasted) {
        downcasted = int96(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 96 bits");
    }

    /**
     * @dev Returns the downcasted int88 from int256, reverting on
     * overflow (when the input is less than smallest int88 or
     * greater than largest int88).
     *
     * Counterpart to Solidity's `int88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toInt88(int256 value) internal pure returns (int88 downcasted) {
        downcasted = int88(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 88 bits");
    }

    /**
     * @dev Returns the downcasted int80 from int256, reverting on
     * overflow (when the input is less than smallest int80 or
     * greater than largest int80).
     *
     * Counterpart to Solidity's `int80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toInt80(int256 value) internal pure returns (int80 downcasted) {
        downcasted = int80(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 80 bits");
    }

    /**
     * @dev Returns the downcasted int72 from int256, reverting on
     * overflow (when the input is less than smallest int72 or
     * greater than largest int72).
     *
     * Counterpart to Solidity's `int72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toInt72(int256 value) internal pure returns (int72 downcasted) {
        downcasted = int72(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 72 bits");
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64 downcasted) {
        downcasted = int64(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 64 bits");
    }

    /**
     * @dev Returns the downcasted int56 from int256, reverting on
     * overflow (when the input is less than smallest int56 or
     * greater than largest int56).
     *
     * Counterpart to Solidity's `int56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toInt56(int256 value) internal pure returns (int56 downcasted) {
        downcasted = int56(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 56 bits");
    }

    /**
     * @dev Returns the downcasted int48 from int256, reverting on
     * overflow (when the input is less than smallest int48 or
     * greater than largest int48).
     *
     * Counterpart to Solidity's `int48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toInt48(int256 value) internal pure returns (int48 downcasted) {
        downcasted = int48(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 48 bits");
    }

    /**
     * @dev Returns the downcasted int40 from int256, reverting on
     * overflow (when the input is less than smallest int40 or
     * greater than largest int40).
     *
     * Counterpart to Solidity's `int40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toInt40(int256 value) internal pure returns (int40 downcasted) {
        downcasted = int40(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 40 bits");
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32 downcasted) {
        downcasted = int32(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 32 bits");
    }

    /**
     * @dev Returns the downcasted int24 from int256, reverting on
     * overflow (when the input is less than smallest int24 or
     * greater than largest int24).
     *
     * Counterpart to Solidity's `int24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toInt24(int256 value) internal pure returns (int24 downcasted) {
        downcasted = int24(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 24 bits");
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16 downcasted) {
        downcasted = int16(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 16 bits");
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8 downcasted) {
        downcasted = int8(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 8 bits");
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     *
     * _Available since v3.0._
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int256)", p0));
	}

	function logUint(uint256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint256 p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256)", p0, p1));
	}

	function log(uint256 p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string)", p0, p1));
	}

	function log(uint256 p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool)", p0, p1));
	}

	function log(uint256 p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address)", p0, p1));
	}

	function log(string memory p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint256 p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/extensions/ERC20Snapshot.sol)

pragma solidity ^0.8.0;

import "../ERC20Upgradeable.sol";
import "../../../utils/ArraysUpgradeable.sol";
import "../../../utils/CountersUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev This contract extends an ERC20 token with a snapshot mechanism. When a snapshot is created, the balances and
 * total supply at the time are recorded for later access.
 *
 * This can be used to safely create mechanisms based on token balances such as trustless dividends or weighted voting.
 * In naive implementations it's possible to perform a "double spend" attack by reusing the same balance from different
 * accounts. By using snapshots to calculate dividends or voting power, those attacks no longer apply. It can also be
 * used to create an efficient ERC20 forking mechanism.
 *
 * Snapshots are created by the internal {_snapshot} function, which will emit the {Snapshot} event and return a
 * snapshot id. To get the total supply at the time of a snapshot, call the function {totalSupplyAt} with the snapshot
 * id. To get the balance of an account at the time of a snapshot, call the {balanceOfAt} function with the snapshot id
 * and the account address.
 *
 * NOTE: Snapshot policy can be customized by overriding the {_getCurrentSnapshotId} method. For example, having it
 * return `block.number` will trigger the creation of snapshot at the beginning of each new block. When overriding this
 * function, be careful about the monotonicity of its result. Non-monotonic snapshot ids will break the contract.
 *
 * Implementing snapshots for every block using this method will incur significant gas costs. For a gas-efficient
 * alternative consider {ERC20Votes}.
 *
 * ==== Gas Costs
 *
 * Snapshots are efficient. Snapshot creation is _O(1)_. Retrieval of balances or total supply from a snapshot is _O(log
 * n)_ in the number of snapshots that have been created, although _n_ for a specific account will generally be much
 * smaller since identical balances in subsequent snapshots are stored as a single entry.
 *
 * There is a constant overhead for normal ERC20 transfers due to the additional snapshot bookkeeping. This overhead is
 * only significant for the first transfer that immediately follows a snapshot for a particular account. Subsequent
 * transfers will have normal cost until the next snapshot, and so on.
 */

abstract contract ERC20SnapshotUpgradeable is Initializable, ERC20Upgradeable {
    function __ERC20Snapshot_init() internal onlyInitializing {
    }

    function __ERC20Snapshot_init_unchained() internal onlyInitializing {
    }
    // Inspired by Jordi Baylina's MiniMeToken to record historical balances:
    // https://github.com/Giveth/minime/blob/ea04d950eea153a04c51fa510b068b9dded390cb/contracts/MiniMeToken.sol

    using ArraysUpgradeable for uint256[];
    using CountersUpgradeable for CountersUpgradeable.Counter;

    // Snapshotted values have arrays of ids and the value corresponding to that id. These could be an array of a
    // Snapshot struct, but that would impede usage of functions that work on an array.
    struct Snapshots {
        uint256[] ids;
        uint256[] values;
    }

    mapping(address => Snapshots) private _accountBalanceSnapshots;
    Snapshots private _totalSupplySnapshots;

    // Snapshot ids increase monotonically, with the first value being 1. An id of 0 is invalid.
    CountersUpgradeable.Counter private _currentSnapshotId;

    /**
     * @dev Emitted by {_snapshot} when a snapshot identified by `id` is created.
     */
    event Snapshot(uint256 id);

    /**
     * @dev Creates a new snapshot and returns its snapshot id.
     *
     * Emits a {Snapshot} event that contains the same id.
     *
     * {_snapshot} is `internal` and you have to decide how to expose it externally. Its usage may be restricted to a
     * set of accounts, for example using {AccessControl}, or it may be open to the public.
     *
     * [WARNING]
     * ====
     * While an open way of calling {_snapshot} is required for certain trust minimization mechanisms such as forking,
     * you must consider that it can potentially be used by attackers in two ways.
     *
     * First, it can be used to increase the cost of retrieval of values from snapshots, although it will grow
     * logarithmically thus rendering this attack ineffective in the long term. Second, it can be used to target
     * specific accounts and increase the cost of ERC20 transfers for them, in the ways specified in the Gas Costs
     * section above.
     *
     * We haven't measured the actual numbers; if this is something you're interested in please reach out to us.
     * ====
     */
    function _snapshot() internal virtual returns (uint256) {
        _currentSnapshotId.increment();

        uint256 currentId = _getCurrentSnapshotId();
        emit Snapshot(currentId);
        return currentId;
    }

    /**
     * @dev Get the current snapshotId
     */
    function _getCurrentSnapshotId() internal view virtual returns (uint256) {
        return _currentSnapshotId.current();
    }

    /**
     * @dev Retrieves the balance of `account` at the time `snapshotId` was created.
     */
    function balanceOfAt(address account, uint256 snapshotId) public view virtual returns (uint256) {
        (bool snapshotted, uint256 value) = _valueAt(snapshotId, _accountBalanceSnapshots[account]);

        return snapshotted ? value : balanceOf(account);
    }

    /**
     * @dev Retrieves the total supply at the time `snapshotId` was created.
     */
    function totalSupplyAt(uint256 snapshotId) public view virtual returns (uint256) {
        (bool snapshotted, uint256 value) = _valueAt(snapshotId, _totalSupplySnapshots);

        return snapshotted ? value : totalSupply();
    }

    // Update balance and/or total supply snapshots before the values are modified. This is implemented
    // in the _beforeTokenTransfer hook, which is executed for _mint, _burn, and _transfer operations.
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        if (from == address(0)) {
            // mint
            _updateAccountSnapshot(to);
            _updateTotalSupplySnapshot();
        } else if (to == address(0)) {
            // burn
            _updateAccountSnapshot(from);
            _updateTotalSupplySnapshot();
        } else {
            // transfer
            _updateAccountSnapshot(from);
            _updateAccountSnapshot(to);
        }
    }

    function _valueAt(uint256 snapshotId, Snapshots storage snapshots) private view returns (bool, uint256) {
        require(snapshotId > 0, "ERC20Snapshot: id is 0");
        require(snapshotId <= _getCurrentSnapshotId(), "ERC20Snapshot: nonexistent id");

        // When a valid snapshot is queried, there are three possibilities:
        //  a) The queried value was not modified after the snapshot was taken. Therefore, a snapshot entry was never
        //  created for this id, and all stored snapshot ids are smaller than the requested one. The value that corresponds
        //  to this id is the current one.
        //  b) The queried value was modified after the snapshot was taken. Therefore, there will be an entry with the
        //  requested id, and its value is the one to return.
        //  c) More snapshots were created after the requested one, and the queried value was later modified. There will be
        //  no entry for the requested id: the value that corresponds to it is that of the smallest snapshot id that is
        //  larger than the requested one.
        //
        // In summary, we need to find an element in an array, returning the index of the smallest value that is larger if
        // it is not found, unless said value doesn't exist (e.g. when all values are smaller). Arrays.findUpperBound does
        // exactly this.

        uint256 index = snapshots.ids.findUpperBound(snapshotId);

        if (index == snapshots.ids.length) {
            return (false, 0);
        } else {
            return (true, snapshots.values[index]);
        }
    }

    function _updateAccountSnapshot(address account) private {
        _updateSnapshot(_accountBalanceSnapshots[account], balanceOf(account));
    }

    function _updateTotalSupplySnapshot() private {
        _updateSnapshot(_totalSupplySnapshots, totalSupply());
    }

    function _updateSnapshot(Snapshots storage snapshots, uint256 currentValue) private {
        uint256 currentId = _getCurrentSnapshotId();
        if (_lastSnapshotId(snapshots.ids) < currentId) {
            snapshots.ids.push(currentId);
            snapshots.values.push(currentValue);
        }
    }

    function _lastSnapshotId(uint256[] storage ids) private view returns (uint256) {
        if (ids.length == 0) {
            return 0;
        } else {
            return ids[ids.length - 1];
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[46] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Arrays.sol)

pragma solidity ^0.8.0;

import "./StorageSlotUpgradeable.sol";
import "./math/MathUpgradeable.sol";

/**
 * @dev Collection of functions related to array types.
 */
library ArraysUpgradeable {
    using StorageSlotUpgradeable for bytes32;

    /**
     * @dev Searches a sorted `array` and returns the first index that contains
     * a value greater or equal to `element`. If no such index exists (i.e. all
     * values in the array are strictly less than `element`), the array length is
     * returned. Time complexity O(log n).
     *
     * `array` is expected to be sorted in ascending order, and to contain no
     * repeated elements.
     */
    function findUpperBound(uint256[] storage array, uint256 element) internal view returns (uint256) {
        if (array.length == 0) {
            return 0;
        }

        uint256 low = 0;
        uint256 high = array.length;

        while (low < high) {
            uint256 mid = MathUpgradeable.average(low, high);

            // Note that mid will always be strictly less than high (i.e. it will be a valid array index)
            // because Math.average rounds down (it does integer division with truncation).
            if (unsafeAccess(array, mid).value > element) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        // At this point `low` is the exclusive upper bound. We will return the inclusive upper bound.
        if (low > 0 && unsafeAccess(array, low - 1).value == element) {
            return low - 1;
        } else {
            return low;
        }
    }

    /**
     * @dev Access an array in an "unsafe" way. Skips solidity "index-out-of-range" check.
     *
     * WARNING: Only use if you are certain `pos` is lower than the array length.
     */
    function unsafeAccess(address[] storage arr, uint256 pos) internal pure returns (StorageSlotUpgradeable.AddressSlot storage) {
        bytes32 slot;
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0, arr.slot)
            slot := add(keccak256(0, 0x20), pos)
        }
        return slot.getAddressSlot();
    }

    /**
     * @dev Access an array in an "unsafe" way. Skips solidity "index-out-of-range" check.
     *
     * WARNING: Only use if you are certain `pos` is lower than the array length.
     */
    function unsafeAccess(bytes32[] storage arr, uint256 pos) internal pure returns (StorageSlotUpgradeable.Bytes32Slot storage) {
        bytes32 slot;
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0, arr.slot)
            slot := add(keccak256(0, 0x20), pos)
        }
        return slot.getBytes32Slot();
    }

    /**
     * @dev Access an array in an "unsafe" way. Skips solidity "index-out-of-range" check.
     *
     * WARNING: Only use if you are certain `pos` is lower than the array length.
     */
    function unsafeAccess(uint256[] storage arr, uint256 pos) internal pure returns (StorageSlotUpgradeable.Uint256Slot storage) {
        bytes32 slot;
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0, arr.slot)
            slot := add(keccak256(0, 0x20), pos)
        }
        return slot.getUint256Slot();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library CountersUpgradeable {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}