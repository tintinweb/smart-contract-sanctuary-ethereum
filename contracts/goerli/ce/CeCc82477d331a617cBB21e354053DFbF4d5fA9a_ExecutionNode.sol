// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.15;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

import "./lib/Types.sol";
import "./lib/MessageReceiver.sol";
import "./lib/Pauser.sol";
import "./lib/NativeWrap.sol";
import "./lib/Bytes.sol";

import "./interfaces/IBridgeAdapter.sol";
import "./interfaces/ICodec.sol";
import "./interfaces/IExecutionNodeEvents.sol";
import "./interfaces/IWETH.sol";
import "./interfaces/IMessageBus.sol";

import "./BridgeRegistry.sol";
import "./FeeOperator.sol";
import "./SigVerifier.sol";
import "./Pocket.sol";
import "./DexRegistry.sol";

/**
 * @author Chainhop Dex Team
 * @author Padoriku
 * @title a route execution contract
 * @notice
 * a few key concepts about how the chain of execution works:
 * - a "swap-bridge execution combo" (Types.ExecutionInfo) is a node in the execution chain
 * - a node be swap-only, bridge-only, or swap-bridge
 * - a message is an edge in the execution chain, it carries the remaining swap-bridge combos to the next node
 * - execute() executes a swap-bridge combo and determines if the current node is the final one by looking at Types.DestinationInfo
 * - executeMessage() is called on the intermediate nodes by chainhop's executor. it simply calls execute() to advance the execution chain
 * - a "pocket" is a counterfactual contract of which the address is determined at quote-time by chainhop's pathfinder server with using the id as salt
 * the actual pocket contract deployment is done at execution time by the the ExecutionNode on that chain
 * these concepts are there to make bridge-agnostic multi-hop execution possible and to help keep the code sane
 */
contract ExecutionNode is
    IExecutionNodeEvents,
    MessageReceiver,
    DexRegistry,
    BridgeRegistry,
    SigVerifier,
    FeeOperator,
    NativeWrap,
    ReentrancyGuard,
    Pauser
{
    using SafeERC20 for IERC20;
    using ECDSA for bytes32;
    using Bytes for bytes;

    constructor(
        bool _testMode,
        address _messageBus,
        address _nativeWrap
    ) MessageReceiver(_testMode, _messageBus) NativeWrap(_nativeWrap) {}

    // init() can only be called once during the first deployment of the proxy contract.
    // any subsequent changes to the proxy contract's state must be done through their respective set methods via owner key.
    function init(
        bool _testMode,
        address _messageBus,
        address _nativeWrap,
        address _signer,
        address _feeCollector,
        address[] memory _dexList,
        string[] memory _funcs,
        address[] memory _codecs,
        string[] memory _bridgeProviders,
        address[] memory _bridgeAdapters
    ) external initializer {
        initMessageReceiver(_testMode, _messageBus);
        initDexRegistry(_dexList, _funcs, _codecs);
        initBridgeRegistry(_bridgeProviders, _bridgeAdapters);
        initSigVerifier(_signer);
        initFeeOperator(_feeCollector);
        initNativeWrap(_nativeWrap);
    }

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     * Core
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

    /**
     * @notice executes a swap-bridge combo and relays the next swap-bridge combo to the next chain (if any)
     * @notice nop nodes are allowed. execute() simply sends the output token (wrap/unwrap native if needed) to the receiver
     * @param _id an id that is unique enough per user-swap. persistent for the entire operation. also used as salt for the pocket contract
     * id = keccak256(abi.encodePacked(_dstReceiver, _nonce));
     * @param _execs contains info that tells this contract how to collect a part of the bridge token
     * received as fee and how to swap can be omitted on the source chain if there is no swaps to execute
     * @param _src only required on the source chain and should not be populated on subsequent hops
     * @param _dst the receiving info of the entire operation
     */
    function execute(
        bytes32 _id,
        Types.ExecutionInfo[] memory _execs,
        Types.SourceInfo memory _src,
        Types.DestinationInfo memory _dst
    ) public payable nonReentrant whenNotPaused returns (uint256 remainingValue) {
        require(_execs.length > 0, "nop");

        Types.ExecutionInfo memory exec;
        (exec, _execs) = _popFirst(_execs);

        remainingValue = msg.value;

        // pull funds
        uint256 amountIn;
        address tokenIn;
        if (_src.chainId == _chainId()) {
            // if there are more executions on other chains, verify sig so that we are sure the fees
            // to be collected will not be tempered with when we run executions on other chains
            // note that quote sig verification is only done on the src chain. the security of each
            // subsequent execution's fee collection is dependant on the security of cbridge's IM
            if (_execs.length > 0) {
                _verify(_execs, _src, _dst);
            }
            (amountIn, tokenIn) = _pullFundFromSender(_src);
            if (_src.nativeIn) {
                remainingValue -= amountIn;
            }
        } else {
            (amountIn, tokenIn) = _pullFundFromPocket(_id, exec);
            // if amountIn is 0 after deducting fee, this contract keeps all amountIn as fee and
            // ends the execution
            if (amountIn == 0) {
                emit StepExecuted(_id, 0, tokenIn);
                return remainingValue;
            }
            // refund immediately if receives bridge out fallback token
            if (tokenIn == exec.bridgeOutFallbackToken) {
                _sendToken(tokenIn, amountIn, _dst.receiver, false);
                emit StepExecuted(_id, amountIn, tokenIn);
                return remainingValue;
            }
        }

        // process swap if any
        uint256 nextAmount = amountIn;
        address nextToken = tokenIn;
        if (exec.swap.dex != address(0)) {
            bool success = true;
            (success, nextAmount, nextToken) = _executeSwap(exec.swap, amountIn, tokenIn);
            if (_src.chainId == _chainId()) require(success, "swap fail");
            // refund immediately if swap fails
            if (!success) {
                _sendToken(tokenIn, amountIn, _dst.receiver, false);
                emit StepExecuted(_id, amountIn, tokenIn);
                return remainingValue;
            }
        }

        // pay receiver if this is the last execution step or if the swap fails on a middle chain
        if (_dst.chainId == _chainId()) {
            _sendToken(nextToken, nextAmount, _dst.receiver, _dst.nativeOut);
            emit StepExecuted(_id, nextAmount, nextToken);
            return remainingValue;
        }

        // funds are bridged directly to receiver if there is no swaps needed on the destination chain. otherwise,
        // it's sent to a "pocket" contract addr to temporarily hold the fund before it is used for swapping.
        address bridgeOutReceiver = (_execs.length > 0) ? _getPocketAddr(_id, exec.remoteExecutionNode) : _dst.receiver;
        uint256 refundMsgFee = _bridgeSend(
            exec.bridge.toChainId,
            keccak256(bytes(exec.bridge.bridgeProvider)),
            exec.bridge.bridgeParams,
            bridgeOutReceiver,
            nextToken,
            nextAmount
        );
        remainingValue -= refundMsgFee;

        // initiate the next hop
        if (_execs.length > 0) {
            bytes memory message = abi.encode(Types.Message({id: _id, execs: _execs, dst: _dst}));
            uint256 msgFee = IMessageBus(messageBus).calcFee(message);
            remainingValue -= msgFee;
            IMessageBus(messageBus).sendMessage{value: msgFee}(
                exec.remoteExecutionNode,
                exec.bridge.toChainId,
                message
            );
        }

        emit StepExecuted(_id, nextAmount, nextToken);
    }

    /**
     * @notice call by cBridge MessageBus and then simply calls execute() to carry on the executions
     * @param _message the message that contains the remaining swap-bridge combos to be executed
     * @return executionStatus always success if no reverts to let the MessageBus know that the message is processed
     */
    function executeMessage(
        address, // _sender
        uint64, // _srcChainId
        bytes memory _message,
        address // _executor
    ) external payable override onlyMessageBus returns (ExecutionStatus) {
        Types.Message memory message = abi.decode((_message), (Types.Message));
        uint256 remainingValue = execute(message.id, message.execs, Types.emptySourceInfo(), message.dst);
        // chainhop executor would always send a set amount of native token with calling messagebus's executeMessage().
        // this is to allow chaining another message in case that another bridging is needed. refunding the unspent native
        // tokens back to the executor
        if (remainingValue > 0) {
            (bool ok, ) = tx.origin.call{value: remainingValue}("");
            require(ok, "failed to refund remaining native token");
        }
        return ExecutionStatus.Success;
    }

    // the receiver of a swap is entitled to all the funds in the pocket. as long as someone can prove
    // that they are the receiver of a swap, they can always recreate the pocket contract and claim the
    // funds inside.
    function claimPocketFund(
        address _sender,
        address _receiver,
        uint64 _nonce,
        address _token
    ) external {
        // id ensures that only the designated receiver of a swap can claim funds from the designated pocket of a swap
        bytes32 id = _computeId(_sender, _receiver, _nonce);

        Pocket pocket = new Pocket{salt: id}();
        uint256 erc20Amount = IERC20(_token).balanceOf(address(pocket));
        uint256 nativeAmount = address(pocket).balance;
        require(erc20Amount > 0 || nativeAmount > 0, "pocket is empty");

        // this claims both _token and native
        pocket.claim(_token, erc20Amount);

        if (erc20Amount > 0) {
            IERC20(_token).safeTransfer(_receiver, erc20Amount);
        }
        if (nativeAmount > 0) {
            (bool ok, ) = _receiver.call{value: nativeAmount, gas: 50000}("");
            require(ok, "failed to send native");
        }
        emit PocketFundClaimed(_receiver, erc20Amount, _token, nativeAmount);
    }

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     * Misc
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    function _computeId(
        address _sender,
        address _dstReceiver,
        uint64 _nonce
    ) private pure returns (bytes32) {
        // the main purpose of this id is to uniquely identify a receiver on a per-swap basis.
        return keccak256(abi.encodePacked(_sender, _dstReceiver, _nonce));
    }

    function _pullFundFromSender(Types.SourceInfo memory _src) private returns (uint256 amount, address token) {
        if (_src.nativeIn) {
            require(_src.tokenIn == nativeWrap, "tokenIn not nativeWrap");
            require(msg.value >= _src.amountIn, "insufficient native amount");
            IWETH(nativeWrap).deposit{value: _src.amountIn}();
        } else {
            IERC20(_src.tokenIn).safeTransferFrom(msg.sender, address(this), _src.amountIn);
        }
        return (_src.amountIn, _src.tokenIn);
    }

    function _pullFundFromPocket(bytes32 _id, Types.ExecutionInfo memory _exec)
        private
        returns (uint256 amount, address token)
    {
        Pocket pocket = new Pocket{salt: _id}();

        uint256 fallbackAmount;
        if (_exec.bridgeOutFallbackToken != address(0)) {
            fallbackAmount = IERC20(_exec.bridgeOutFallbackToken).balanceOf(address(pocket)); // e.g. hToken/anyToken
        }
        uint256 erc20Amount = IERC20(_exec.bridgeOutToken).balanceOf(address(pocket));
        uint256 nativeAmount = address(pocket).balance;

        // if the pocket does not have bridgeOutMin, we consider the transfer not arrived yet. in
        // this case we tell the msgbus to revert the outter tx using the MSGBUS::REVERT opcode so
        // that our executor will retry sending this tx later.
        // this is a counter-measure to a DoS attack vector. an attacker can deposit a small amount
        // of fund into the pocket and confuse this contract that the bridged fund has arrived,
        // denying the dst swap for the victim. bridgeOutMin is determined by the server before
        // sending out the transfer. bridgeOutMin = R * bridgeAmountIn where R is an arbitrary ratio
        // that we feel effective in raising the attacker's attack cost.
        // note that in case the bridging actually has a huge slippage, the user can always call
        // claimPocketFund to collect the bridge out tokens as a refund.
        require(
            erc20Amount > _exec.bridgeOutMin ||
                nativeAmount > _exec.bridgeOutMin ||
                fallbackAmount > _exec.bridgeOutFallbackMin,
            "MSGBUS::REVERT"
        );
        if (fallbackAmount > 0) {
            pocket.claim(_exec.bridgeOutFallbackToken, fallbackAmount);
            amount = _deductFee(_exec.feeInBridgeOutFallbackToken, fallbackAmount);
            token = _exec.bridgeOutFallbackToken;
        } else {
            pocket.claim(_exec.bridgeOutToken, erc20Amount);
            if (erc20Amount > 0) {
                amount = _deductFee(_exec.feeInBridgeOutToken, erc20Amount);
            } else if (nativeAmount > 0) {
                require(_exec.bridgeOutToken == nativeWrap, "bridgeOutToken not nativeWrap");
                amount = _deductFee(_exec.feeInBridgeOutToken, nativeAmount);
                IWETH(_exec.bridgeOutToken).deposit{value: amount}();
            }
            token = _exec.bridgeOutToken;
        }
    }

    function _getPocketAddr(bytes32 _salt, address _deployer) private pure returns (address) {
        bytes32 hash = keccak256(
            abi.encodePacked(bytes1(0xff), _deployer, _salt, keccak256(type(Pocket).creationCode))
        );
        return address(uint160(uint256(hash)));
    }

    function _deductFee(uint256 _fee, uint256 _amount) private pure returns (uint256 amount) {
        // handle the case where amount received is not enough to pay fee
        if (_amount >= _fee) {
            amount = _amount - _fee;
        }
    }

    function _bridgeSend(
        uint64 _toChainId,
        bytes32 _bridgeProvider,
        bytes memory _bridgeParams,
        address _receiver,
        address _token,
        uint256 _amount
    ) private returns (uint256 refundMsgFee) {
        IBridgeAdapter bridge = bridges[_bridgeProvider];
        if (_bridgeProvider == CBRIDGE_PROVIDER_HASH) {
            // special handling for dealing with cbridge's refund mechnism: cbridge adapter always
            // sends a message that contains only the receiver addr along with the transfer. this way
            // when refund happens we can execute the executeMessageWithTransferRefund function in
            // cbridge adapter to refund to the receiver
            refundMsgFee = IMessageBus(messageBus).calcFee(abi.encode(_receiver));
        }
        IERC20(_token).safeIncreaseAllowance(address(bridge), _amount);
        bridge.bridge{value: refundMsgFee}(_toChainId, _receiver, _amount, _token, _bridgeParams);
    }

    function _executeSwap(
        ICodec.SwapDescription memory _swap,
        uint256 _amountIn,
        address _tokenIn
    )
        private
        returns (
            bool ok,
            uint256 amountOut,
            address tokenOut
        )
    {
        if (_swap.dex == address(0)) {
            // nop swap
            return (true, _amountIn, _tokenIn);
        }
        bytes4 selector = bytes4(_swap.data);
        ICodec codec = getCodec(_swap.dex, selector);
        address tokenIn;
        (, tokenIn, tokenOut) = codec.decodeCalldata(_swap);
        require(tokenIn == _tokenIn, "swap info mismatch");

        bytes memory data = codec.encodeCalldataWithOverride(_swap.data, _amountIn, address(this));
        IERC20(tokenIn).safeIncreaseAllowance(_swap.dex, _amountIn);
        uint256 balBefore = IERC20(tokenOut).balanceOf(address(this));
        (bool success, ) = _swap.dex.call(data);
        if (!success) {
            return (false, 0, tokenOut);
        }
        uint256 balAfter = IERC20(tokenOut).balanceOf(address(this));
        return (true, balAfter - balBefore, tokenOut);
    }

    function _sendToken(
        address _token,
        uint256 _amount,
        address _receiver,
        bool _nativeOut
    ) private {
        if (_nativeOut) {
            require(_token == nativeWrap, "token is not nativeWrap");
            IWETH(nativeWrap).withdraw(_amount);
            (bool sent, ) = _receiver.call{value: _amount, gas: 50000}("");
            require(sent, "send fail");
        } else {
            IERC20(_token).safeTransfer(_receiver, _amount);
        }
    }

    function _popFirst(Types.ExecutionInfo[] memory _execs)
        private
        pure
        returns (Types.ExecutionInfo memory first, Types.ExecutionInfo[] memory rest)
    {
        require(_execs.length > 0, "empty execs");
        first = _execs[0];
        rest = new Types.ExecutionInfo[](_execs.length - 1);
        for (uint256 i = 1; i < _execs.length; i++) {
            rest[i - 1] = _execs[i];
        }
    }

    function _verify(
        Types.ExecutionInfo[] memory _execs, // all execs except the one on the src chain
        Types.SourceInfo memory _src,
        Types.DestinationInfo memory _dst
    ) private view {
        require(_src.deadline > block.timestamp, "deadline exceeded");
        bytes memory data = abi.encode(
            "chainhop quote",
            uint64(block.chainid),
            _dst.chainId,
            _src.amountIn,
            _src.tokenIn,
            _src.deadline
        );
        for (uint256 i = 0; i < _execs.length; i++) {
            Types.ExecutionInfo memory e = _execs[i];
            bytes memory execData = abi.encode(
                e.chainId,
                e.feeInBridgeOutToken,
                e.bridgeOutToken,
                e.feeInBridgeOutFallbackToken,
                e.bridgeOutFallbackToken
            );
            data = data.concat(execData);
        }
        bytes32 signHash = keccak256(data).toEthSignedMessageHash();
        verifySig(signHash, _src.quoteSig);
    }

    function _chainId() private view returns (uint64) {
        return uint64(block.chainid);
    }

    function executeMessageWithTransferRefund(
        address _token,
        uint256 _amount,
        bytes calldata _message
    ) external payable override returns (bool) {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
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

    function safePermit(
        IERC20Permit token,
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
// OpenZeppelin Contracts (last updated v4.7.3) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
abstract contract ReentrancyGuard {
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

    constructor() {
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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/Address.sol";

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
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!Address.isContract(address(this)) && _initialized == 1),
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
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
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
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.15;

import "./MsgDataTypes.sol";
import "../interfaces/ICodec.sol";

library Types {
    struct SourceInfo {
        uint64 chainId;
        // A number unique enough to be used in request ID generation.
        uint64 nonce;
        // the unix timestamp before which the fee is valid
        uint256 deadline;
        // sig of sha3("executor fee", srcChainId, amountIn, tokenIn, deadline, toChainId, feeInBridgeOutToken, bridgeOutToken, feeInBridgeOutFallbackToken, bridgeOutFallbackToken[, toChainId, feeInBridgeOutToken, bridgeOutToken, feeInBridgeOutFallbackToken, bridgeOutFallbackToken]...)
        // see _verifyQuote()
        bytes quoteSig;
        uint256 amountIn;
        address tokenIn;
        bool nativeIn;
    }

    function emptySourceInfo() internal pure returns (SourceInfo memory) {
        return SourceInfo(0, 0, 0, "", 0, address(0), false);
    }

    struct DestinationInfo {
        uint64 chainId;
        // The receiving party (the user) of the final output token
        // note that if an organization user's private key is breached, and if their original receiver is a contract
        // address, the hacker could deploy a malicious contract with the same address on the different chain and hence
        // get access to the user's pocket funds on that chain.
        // WARNING users should make sure their own deployer key's safety or that receiver is either
        // 1. not a reproducable address on any of the chains that chainhop supports
        // 2. a contract that they already deployed on all the chains that chainhop supports
        // 3. an EOA
        address receiver;
        bool nativeOut;
    }

    struct ExecutionInfo {
        uint64 chainId;
        ICodec.SwapDescription swap;
        BridgeInfo bridge;
        address remoteExecutionNode;
        address bridgeOutToken;
        // some bridges utilize a intermediary token (e.g. hToken for Hop and anyToken for Multichain)
        // in cases where there isn't enough underlying token liquidity on the dst chain, the user/pocket
        // could receive this token as a fallback. remote ExecutionNode needs to know what this token is
        // in order to check whether a fallback has happened and refund the user.
        address bridgeOutFallbackToken;
        // the minimum that remote ExecutionNode needs to receive in order to allow the swap message
        // to execute. note that this differs from a normal slippages controlling variable and is
        // purely used to deter DoS attacks (detailed in ExecutionNode).
        uint256 bridgeOutMin;
        uint256 bridgeOutFallbackMin;
        // executor fee
        uint256 feeInBridgeOutToken;
        // in case the bridging result in in fallback tokens, this is the amount of the fee that
        // chainhop charges
        uint256 feeInBridgeOutFallbackToken;
    }

    struct BridgeInfo {
        uint64 toChainId;
        // bridge provider identifier
        string bridgeProvider;
        // Bridge transfers quoted and abi encoded by chainhop backend server.
        // Bridge adapter implementations need to decode this themselves.
        bytes bridgeParams;
    }

    struct Message {
        bytes32 id;
        Types.ExecutionInfo[] execs;
        Types.DestinationInfo dst;
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

import "../interfaces/IMessageReceiver.sol";

abstract contract MessageReceiver is IMessageReceiver, Ownable, Initializable {
    event MessageBusUpdated(address messageBus);

    // testMode is used for the ease of testing functions with the "onlyMessageBus" modifier.
    // WARNING: when testMode is true, ANYONE can call executeMessage functions
    // this variable can only be set during contract construction and is always not set on mainnets
    bool public testMode;

    address public messageBus;

    constructor(bool _testMode, address _messageBus) {
        testMode = _testMode;
        messageBus = _messageBus;
    }

    function initMessageReceiver(bool _testMode, address _msgbus) internal onlyInitializing {
        require(!_testMode || block.chainid == 31337); // only allow testMode on hardhat local network
        testMode = _testMode;
        messageBus = _msgbus;
        emit MessageBusUpdated(messageBus);
    }

    function setMessageBus(address _msgbus) public onlyOwner {
        messageBus = _msgbus;
        emit MessageBusUpdated(messageBus);
    }

    modifier onlyMessageBus() {
        if (!testMode) {
            require(msg.sender == messageBus, "caller is not message bus");
        }
        _;
    }

    /**
     * @notice Called by MessageBus (MessageBusReceiver)
     * @param _sender The address of the source app contract
     * @param _srcChainId The source chain ID where the transfer is originated from
     * @param _message Arbitrary message bytes originated from and encoded by the source app contract
     * @param _executor Address who called the MessageBus execution function
     */
    function executeMessage(
        address _sender,
        uint64 _srcChainId,
        bytes calldata _message,
        address _executor
    ) external payable virtual returns (ExecutionStatus);

    /**
     * @notice Called by MessageBus (MessageBusReceiver) to process refund of the original transfer from this contract
     * @param _token The token address of the original transfer
     * @param _amount The amount of the original transfer
     * @param _message The same message associated with the original transfer
     */
    function executeMessageWithTransferRefund(
        address _token,
        uint256 _amount,
        bytes calldata _message
    ) external payable virtual returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.15;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract Pauser is Ownable, Pausable {
    mapping(address => bool) public pausers;

    event PauserAdded(address account);
    event PauserRemoved(address account);

    constructor() {
        _addPauser(msg.sender);
    }

    modifier onlyPauser() {
        require(isPauser(msg.sender), "Caller is not pauser");
        _;
    }

    function pause() public onlyPauser {
        _pause();
    }

    function unpause() public onlyPauser {
        _unpause();
    }

    function isPauser(address account) public view returns (bool) {
        return pausers[account];
    }

    function addPauser(address account) public onlyOwner {
        _addPauser(account);
    }

    function removePauser(address account) public onlyOwner {
        _removePauser(account);
    }

    function renouncePauser() public {
        _removePauser(msg.sender);
    }

    function _addPauser(address account) private {
        require(!isPauser(account), "Account is already pauser");
        pausers[account] = true;
        emit PauserAdded(account);
    }

    function _removePauser(address account) private {
        require(isPauser(account), "Account is not pauser");
        pausers[account] = false;
        emit PauserRemoved(account);
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

abstract contract NativeWrap is Ownable, Initializable {
    address public nativeWrap;

    event NativeWrapUpdated(address nativeWrap);

    constructor(address _nativeWrap) {
        nativeWrap = _nativeWrap;
    }

    function initNativeWrap(address _nativeWrap) internal onlyInitializing {
        _setNativeWrap(_nativeWrap);
    }

    function setNativeWrap(address _nativeWrap) external onlyOwner {
        _setNativeWrap(_nativeWrap);
    }

    function _setNativeWrap(address _nativeWrap) private {
        nativeWrap = _nativeWrap;
        emit NativeWrapUpdated(_nativeWrap);
    }

    receive() external payable {}
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.15;

library Bytes {
    uint256 internal constant WORD_SIZE = 32;

    function concat(bytes memory self, bytes memory other) internal pure returns (bytes memory) {
        bytes memory ret = new bytes(self.length + other.length);
        (uint256 src, uint256 srcLen) = fromBytes(self);
        (uint256 src2, uint256 src2Len) = fromBytes(other);
        (uint256 dest, ) = fromBytes(ret);
        uint256 dest2 = dest + srcLen;
        copy(src, dest, srcLen);
        copy(src2, dest2, src2Len);
        return ret;
    }

    function fromBytes(bytes memory bts) internal pure returns (uint256 addr, uint256 len) {
        len = bts.length;
        assembly {
            addr := add(bts, 32)
        }
    }

    function copy(
        uint256 src,
        uint256 dest,
        uint256 len
    ) internal pure {
        // Copy word-length chunks while possible
        for (; len >= WORD_SIZE; len -= WORD_SIZE) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += WORD_SIZE;
            src += WORD_SIZE;
        }

        if (len == 0) return;

        // Copy remaining bytes
        uint256 mask = 256**(WORD_SIZE - len) - 1;
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.15;

interface IBridgeAdapter {
    function bridge(
        uint64 _dstChainId,
        // the address that the fund is transfered to on the destination chain
        address _receiver,
        uint256 _amount,
        address _token,
        // Bridge transfers quoted and abi encoded by chainhop backend server.
        // Bridge adapter implementations need to decode this themselves.
        bytes memory _bridgeParams
    ) external payable returns (bytes memory bridgeResp);
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.0;

interface ICodec {
    struct SwapDescription {
        address dex; // the DEX to use for the swap, zero address implies no swap needed
        bytes data; // the data to call the dex with
    }

    function decodeCalldata(SwapDescription calldata swap)
        external
        view
        returns (
            uint256 amountIn,
            address tokenIn,
            address tokenOut
        );

    function encodeCalldataWithOverride(
        bytes calldata data,
        uint256 amountInOverride,
        address receiverOverride
    ) external pure returns (bytes memory swapCalldata);
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.15;

import "../lib/Types.sol";

interface IExecutionNodeEvents {
    /**
     * @notice Emitted when operations on dst chain is done.
     * @param id see _computeId()
     * @param amountOut the amount of tokenOut from this step
     * @param tokenOut the token that is outputted from this step
     */
    event StepExecuted(bytes32 id, uint256 amountOut, address tokenOut);

    event PocketFundClaimed(address receiver, uint256 erc20Amount, address token, uint256 nativeAmount);
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint256) external;
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.0;

import "../lib/MsgDataTypes.sol";

interface IMessageBus {
    function liquidityBridge() external view returns (address);

    function pegBridge() external view returns (address);

    function pegBridgeV2() external view returns (address);

    function pegVault() external view returns (address);

    function pegVaultV2() external view returns (address);

    function feeBase() external view returns (uint256);

    function feePerByte() external view returns (uint256);

    /**
     * @notice Calculates the required fee for the message.
     * @param _message Arbitrary message bytes to be decoded by the destination app contract.
     @ @return The required fee.
     */
    function calcFee(bytes calldata _message) external view returns (uint256);

    /**
     * @notice Sends a message to an app on another chain via MessageBus without an associated transfer.
     * A fee is charged in the native gas token.
     * @param _receiver The address of the destination app contract.
     * @param _dstChainId The destination chain ID.
     * @param _message Arbitrary message bytes to be decoded by the destination app contract.
     */
    function sendMessage(
        address _receiver,
        uint256 _dstChainId,
        bytes calldata _message
    ) external payable;

    /**
     * @notice Sends a message associated with a transfer to an app on another chain via MessageBus without an associated transfer.
     * A fee is charged in the native token.
     * @param _receiver The address of the destination app contract.
     * @param _dstChainId The destination chain ID.
     * @param _srcBridge The bridge contract to send the transfer with.
     * @param _srcTransferId The transfer ID.
     * @param _dstChainId The destination chain ID.
     * @param _message Arbitrary message bytes to be decoded by the destination app contract.
     */
    function sendMessageWithTransfer(
        address _receiver,
        uint256 _dstChainId,
        address _srcBridge,
        bytes32 _srcTransferId,
        bytes calldata _message
    ) external payable;

    /**
     * @notice Withdraws message fee in the form of native gas token.
     * @param _account The address receiving the fee.
     * @param _cumulativeFee The cumulative fee credited to the account. Tracked by SGN.
     * @param _sigs The list of signatures sorted by signing addresses in ascending order. A withdrawal must be
     * signed-off by +2/3 of the sigsVerifier's current signing power to be delivered.
     * @param _signers The sorted list of signers.
     * @param _powers The signing powers of the signers.
     */
    function withdrawFee(
        address _account,
        uint256 _cumulativeFee,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers
    ) external;

    /**
     * @notice Execute a message with a successful transfer.
     * @param _message Arbitrary message bytes originated from and encoded by the source app contract
     * @param _transfer The transfer info.
     * @param _sigs The list of signatures sorted by signing addresses in ascending order. A relay must be signed-off by
     * +2/3 of the sigsVerifier's current signing power to be delivered.
     * @param _signers The sorted list of signers.
     * @param _powers The signing powers of the signers.
     */
    function executeMessageWithTransfer(
        bytes calldata _message,
        MsgDataTypes.TransferInfo calldata _transfer,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers
    ) external payable;

    /**
     * @notice Execute a message with a refunded transfer.
     * @param _message Arbitrary message bytes originated from and encoded by the source app contract
     * @param _transfer The transfer info.
     * @param _sigs The list of signatures sorted by signing addresses in ascending order. A relay must be signed-off by
     * +2/3 of the sigsVerifier's current signing power to be delivered.
     * @param _signers The sorted list of signers.
     * @param _powers The signing powers of the signers.
     */
    function executeMessageWithTransferRefund(
        bytes calldata _message, // the same message associated with the original transfer
        MsgDataTypes.TransferInfo calldata _transfer,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers
    ) external payable;

    /**
     * @notice Execute a message not associated with a transfer.
     * @param _message Arbitrary message bytes originated from and encoded by the source app contract
     * @param _sigs The list of signatures sorted by signing addresses in ascending order. A relay must be signed-off by
     * +2/3 of the sigsVerifier's current signing power to be delivered.
     * @param _signers The sorted list of signers.
     * @param _powers The signing powers of the signers.
     */
    function executeMessage(
        bytes calldata _message,
        MsgDataTypes.RouteInfo calldata _route,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers
    ) external payable;
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

import "./interfaces/IBridgeAdapter.sol";

/**
 * @title Manages a list of supported bridges
 * @author lionelhoho
 * @author Padoriku
 */
abstract contract BridgeRegistry is Ownable, Initializable {
    event SupportedBridgesUpdated(string[] providers, address[] adapters);

    bytes32 public constant CBRIDGE_PROVIDER_HASH = keccak256(bytes("cbridge"));

    mapping(bytes32 => IBridgeAdapter) public bridges;

    function initBridgeRegistry(string[] memory _providers, address[] memory _adapters) internal onlyInitializing {
        _setSupportedbridges(_providers, _adapters);
    }

    // to disable a bridge, set the bridge addr of the corresponding provider to address(0)
    function setSupportedBridges(string[] memory _providers, address[] memory _adapters) external onlyOwner {
        _setSupportedbridges(_providers, _adapters);
    }

    function _setSupportedbridges(string[] memory _providers, address[] memory _adapters) private {
        require(_providers.length == _adapters.length, "params size mismatch");
        for (uint256 i = 0; i < _providers.length; i++) {
            bridges[keccak256(bytes(_providers[i]))] = IBridgeAdapter(_adapters[i]);
        }
        emit SupportedBridgesUpdated(_providers, _adapters);
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

/**
 * @title Allows the owner to set fee collector and allows fee collectors to collect fees
 * @author Padoriku
 */
abstract contract FeeOperator is Ownable, Initializable {
    using SafeERC20 for IERC20;

    address public feeCollector;

    event FeeCollectorUpdated(address from, address to);

    modifier onlyFeeCollector() {
        require(msg.sender == feeCollector, "not fee collector");
        _;
    }

    function initFeeOperator(address _feeCollector) internal onlyInitializing {
        _setFeeCollector(_feeCollector);
    }

    function collectFee(address[] calldata _tokens, address _to) external onlyFeeCollector {
        for (uint256 i = 0; i < _tokens.length; i++) {
            // use zero address to denote native token
            if (_tokens[i] == address(0)) {
                uint256 bal = address(this).balance;
                (bool sent, ) = _to.call{value: bal, gas: 50000}("");
                require(sent, "send native failed");
            } else {
                uint256 balance = IERC20(_tokens[i]).balanceOf(address(this));
                IERC20(_tokens[i]).safeTransfer(_to, balance);
            }
        }
    }

    function setFeeCollector(address _feeCollector) external onlyOwner {
        _setFeeCollector(_feeCollector);
    }

    function _setFeeCollector(address _feeCollector) private {
        address oldFeeCollector = feeCollector;
        feeCollector = _feeCollector;
        emit FeeCollectorUpdated(oldFeeCollector, _feeCollector);
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.15;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

/**
 * @title Allows owner to set signer, and verifies signatures
 * @author Padoriku
 */
contract SigVerifier is Ownable, Initializable {
    using ECDSA for bytes32;

    address public signer;

    event SignerUpdated(address from, address to);

    function initSigVerifier(address _signer) internal onlyInitializing {
        _setSigner(_signer);
    }

    function setSigner(address _signer) public onlyOwner {
        _setSigner(_signer);
    }

    function _setSigner(address _signer) private {
        address oldSigner = signer;
        signer = _signer;
        emit SignerUpdated(oldSigner, _signer);
    }

    function verifySig(bytes32 _hash, bytes memory _feeSig) internal view {
        address _signer = _hash.recover(_feeSig);
        require(_signer == signer, "invalid signer");
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.15;

// the pocket is a contract that is to be created conterfactually on the dst chain in the scenario where
// there is a dst swap. the main problem the pocket tries to solve is to gain the ability to know when and
// by how much the bridged send out funds.
// when chainhop backend builds a cross-chain swap, it calculates a swap id (the same as _computeSwapId
// in ExecutionNode) and the id is used as the salt in generating a pocket address on the dst chain.
// the pocket address would temporarily hold the fund that the bridge transfers to it until the swap
// message is executed on the dst chain and ExecutionNode deploys this pocket contract that claims
// the fund.
contract Pocket {
    function claim(address _token, uint256 _amt) external {
        address sender = msg.sender;
        _token.call(abi.encodeWithSelector(0xa9059cbb, sender, _amt));
        assembly {
            // selfdestruct sends all native balance to sender
            selfdestruct(sender)
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

import "./interfaces/ICodec.sol";

/**
 * @title Manages a list supported dex
 * @author Padoriku
 */
abstract contract DexRegistry is Ownable, Initializable {
    event DexCodecUpdated(address dex, bytes4 selector, address codec);

    // supported swap functions
    // 0x3df02124 exchange(int128,int128,uint256,uint256)
    // 0xa6417ed6 exchange_underlying(int128,int128,uint256,uint256)
    // 0x44ee1986 exchange_underlying(int128,int128,uint256,uint256,address)
    // 0x38ed1739 swapExactTokensForTokens(uint256,uint256,address[],address,uint256)
    // 0xc04b8d59 exactInput((bytes,address,uint256,uint256,uint256))
    // 0xb0431182 clipperSwap(address,address,uint256,uint256)
    // 0xe449022e uniswapV3Swap(uint256,uint256,uint256[])
    // 0x2e95b6c8 unoswap(address,uint256,uint256,bytes32[])
    // 0x7c025200 swap(address,(address,address,address,address,uint256,uint256,uint256,bytes),bytes)
    // 0xd0a3b665 fillOrderRFQ((uint256,address,address,address,address,uint256,uint256),bytes,uint256,uint256)
    mapping(address => mapping(bytes4 => address)) public dexFunc2Codec;

    function initDexRegistry(
        address[] memory _dexList,
        string[] memory _funcs,
        address[] memory _codecs
    ) internal onlyInitializing {
        _setDexCodecs(_dexList, _funcs, _codecs);
    }

    function setDexCodecs(
        address[] memory _dexList,
        string[] memory _funcs,
        address[] memory _codecs
    ) external onlyOwner {
        _setDexCodecs(_dexList, _funcs, _codecs);
    }

    function _setDexCodecs(
        address[] memory _dexList,
        string[] memory _funcs,
        address[] memory _codecs
    ) private {
        for (uint256 i = 0; i < _dexList.length; i++) {
            bytes4 selector = bytes4(keccak256(bytes(_funcs[i])));
            _setDexCodec(_dexList[i], selector, _codecs[i]);
        }
    }

    function _setDexCodec(
        address _dex,
        bytes4 _selector,
        address _codec
    ) private {
        address codec = dexFunc2Codec[_dex][_selector];
        require(codec != _codec, "nop");
        dexFunc2Codec[_dex][_selector] = _codec;
        emit DexCodecUpdated(_dex, _selector, _codec);
    }

    function getCodec(address _dex, bytes4 _selector) internal view returns (ICodec) {
        require(dexFunc2Codec[_dex][_selector] != address(0), "unsupported dex");
        return ICodec(dexFunc2Codec[_dex][_selector]);
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
interface IERC20Permit {
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.15;

library MsgDataTypes {
    // bridge operation type at the sender side (src chain)
    enum BridgeSendType {
        Null,
        Liquidity,
        PegDeposit,
        PegBurn,
        PegV2Deposit,
        PegV2Burn,
        PegV2BurnFrom
    }

    // bridge operation type at the receiver side (dst chain)
    enum TransferType {
        Null,
        LqRelay, // relay through liquidity bridge
        LqWithdraw, // withdraw from liquidity bridge
        PegMint, // mint through pegged token bridge
        PegWithdraw, // withdraw from original token vault
        PegV2Mint, // mint through pegged token bridge v2
        PegV2Withdraw // withdraw from original token vault v2
    }

    enum MsgType {
        MessageWithTransfer,
        MessageOnly
    }

    enum TxStatus {
        Null,
        Success,
        Fail,
        Fallback,
        Pending // transient state within a transaction
    }

    struct TransferInfo {
        TransferType t;
        address sender;
        address receiver;
        address token;
        uint256 amount;
        uint64 wdseq; // only needed for LqWithdraw (refund)
        uint64 srcChainId;
        bytes32 refId;
        bytes32 srcTxHash; // src chain msg tx hash
    }

    struct RouteInfo {
        address sender;
        address receiver;
        uint64 srcChainId;
        bytes32 srcTxHash; // src chain msg tx hash
    }

    struct MsgWithTransferExecutionParams {
        bytes message;
        TransferInfo transfer;
        bytes[] sigs;
        address[] signers;
        uint256[] powers;
    }

    struct BridgeTransferParams {
        bytes request;
        bytes[] sigs;
        address[] signers;
        uint256[] powers;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.0;

interface IMessageReceiver {
    enum ExecutionStatus {
        Fail, // execution failed, finalized
        Success, // execution succeeded, finalized
        Retry // execution rejected, can retry later
    }

    /**
     * @notice Called by MessageBus (MessageBusReceiver)
     * @param _sender The address of the source app contract
     * @param _srcChainId The source chain ID where the transfer is originated from
     * @param _message Arbitrary message bytes originated from and encoded by the source app contract
     * @param _executor Address who called the MessageBus execution function
     */
    function executeMessage(
        address _sender,
        uint64 _srcChainId,
        bytes calldata _message,
        address _executor
    ) external payable returns (ExecutionStatus);

    /**
     * @notice Called by MessageBus (MessageBusReceiver) to process refund of the original transfer from this contract
     * @param _token The token address of the original transfer
     * @param _amount The amount of the original transfer
     * @param _message The same message associated with the original transfer
     */
    function executeMessageWithTransferRefund(
        address _token,
        uint256 _amount,
        bytes calldata _message
    ) external payable returns (bool);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}