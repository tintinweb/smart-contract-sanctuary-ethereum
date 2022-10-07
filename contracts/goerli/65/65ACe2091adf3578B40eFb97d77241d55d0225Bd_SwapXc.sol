// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@zetachain/contracts/packages/protocol-contracts/contracts/ZetaInteractor.sol";
import "@zetachain/contracts/packages/protocol-contracts/contracts/interfaces/ZetaInterfaces.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";

import "./interfaces/ISwapXc.sol";
import "./interfaces/IWETH.sol";

///@title Swap Cross-Chain
///@notice Swap assets cross-chain using 0x for first leg (from chain) and Uniswap V3 for second leg (to chain)
contract SwapXc is ISwapXc, ZetaInteractor, ZetaReceiver, Pausable {
    address private constant NATIVE = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE; // Arbitrary address to denote a chains native asset (ETHEREUM = ETH | POLYGON = MATIC)
    uint256 private constant MAX_INT = 2**256 - 1; // Max Uint256 value

    uint16 private sMaxDeadline = 180; // Max time a swap can take in seconds
    uint24 public sProtocolFee = 9000; // 0.9% in basis points (parts per 1,000,000)

    address public immutable iWETH9; // Wrapped native token address
    address public immutable iZetaToken; // ZETA Token address
    address public sZeroEx; // ZeroEx address

    ISwapRouter public immutable iSwapRouterUniV3; // UniswapV3 Swap Router

    // From Chain Input Arguments
    struct XcSwapArgs {
        bytes recipientAddress;
        bytes firstLegCalldata;
        bytes secondLegCalldata;
        bytes revertPath;
        address fromToken;
        address toToken;
        address revertToken;
        uint256 fromTokenAmount;
        uint256 toTokenMinAmount;
        uint256 toChainId;
        uint256 toGasLimit;
        uint16 zetaWethPoolFee;
    }

    // Cross-Chain Message
    struct XcMessage {
        bytes recipientAddress;
        bytes secondLegCalldata;
        bytes revertPath;
        address sourceTxOrigin;
        address fromToken;
        address toToken;
        address revertToken;
        uint256 toTokenMinAmount;
        uint16 zetaWethPoolFee;
    }

    ///@param _zetaConnector ZetaConnector address
    ///@param _zetaToken ZETA Token address
    ///@param _swapRouter UniswapV3 SwapRouter address
    ///@param _WETH9 WETH9 address (Wrapped native asset)
    ///@param _zeroEx ZeroEx address (Used for first leg swap)
    constructor(
        address _zetaConnector,
        address _zetaToken,
        address _swapRouter,
        address _WETH9,
        address _zeroEx
    ) ZetaInteractor(_zetaConnector) {
        // Check for 0 addresses
        require(_zetaConnector != address(0));
        require(_zetaToken != address(0));
        require(_swapRouter != address(0));
        require(_WETH9 != address(0));
        require(_zeroEx != address(0));

        iZetaToken = _zetaToken;
        iSwapRouterUniV3 = ISwapRouter(_swapRouter);
        iWETH9 = _WETH9;
        sZeroEx = _zeroEx;

        // Approve ZetaConnector to spend ZETA
        TransferHelper.safeApprove(_zetaToken, _zetaConnector, MAX_INT);

        // Approve ZeroEx to spend ZETA
        TransferHelper.safeApprove(_zetaToken, _zeroEx, MAX_INT);

        // Approve the SwapRouter to spend ZETA (For revert leg)
        TransferHelper.safeApprove(_zetaToken, _swapRouter, MAX_INT);

        // Approve ZeroEx to spend WETH
        TransferHelper.safeApprove(_WETH9, _zeroEx, MAX_INT);
    }

    /// @dev Allows this contract to receive ether.
    receive() external payable {}

    ///@notice Execute the first leg of cross-chain swap and call ZetaConnector to send cross-chain message with zetaValueAndGas
    ///@notice If swapping from non-native token, token approval is required
    ///@dev Uses ZeroEx to swap from fromToken to ZETA
    ///@param _args Struct of required data for cross-chain swap
    function swapXc(XcSwapArgs calldata _args) external payable whenNotPaused {
        // Validate destination chain id (only chains where this contract is deployed is supported)
        if (!_isValidChainId(_args.toChainId)) revert InvalidDestinationChainId();

        // If swap from native asset, validate value is equal to fromAmount
        if (_args.fromToken == NATIVE) {
            if (msg.value != _args.fromTokenAmount) revert ValueNotEqualFromAmount();
        } else {
            /**
             *  Transfer fromToken to this contract
             *  token spend needs to be approved for this contract beforehand
             */
            TransferHelper.safeTransferFrom(
                _args.fromToken,
                msg.sender,
                address(this),
                _args.fromTokenAmount
            );

            // Give ZeroEx allowance to spend this contract's fromToken.
            TransferHelper.safeApprove(_args.fromToken, address(sZeroEx), _args.fromTokenAmount);
        }

        // If fromToken ZETA, no need to swap
        uint256 zetaValueAndGas;
        if (_args.fromToken == iZetaToken) {
            zetaValueAndGas = _args.fromTokenAmount;
        } else {
            // Get balance of ZETA before ZeroEx swap
            uint256 zetaBalBefore = IERC20(iZetaToken).balanceOf(address(this));
            // Call ZeroEx with swap data
            (bool success, ) = sZeroEx.call{value: msg.value}(_args.firstLegCalldata);
            if (!success) revert BuyZetaFailed();
            // Get ZETA balance after swap and subtract balance before swap to get output ZETA amount
            zetaValueAndGas = IERC20(iZetaToken).balanceOf(address(this)) - zetaBalBefore;
        }

        // Take protocol fee
        uint256 protocolFee = (zetaValueAndGas * sProtocolFee) / 1000000;
        zetaValueAndGas -= protocolFee;

        // Send message to ZetaConnector
        connector.send(
            ZetaInterfaces.SendInput({
                destinationChainId: _args.toChainId,
                destinationAddress: interactorsByChainId[_args.toChainId],
                destinationGasLimit: _args.toGasLimit,
                message: abi.encode(
                    XcMessage({
                        secondLegCalldata: _args.secondLegCalldata,
                        sourceTxOrigin: msg.sender,
                        recipientAddress: _args.recipientAddress,
                        fromToken: _args.fromToken,
                        toToken: _args.toToken,
                        revertToken: _args.revertToken,
                        revertPath: _args.revertPath,
                        zetaWethPoolFee: _args.zetaWethPoolFee,
                        toTokenMinAmount: _args.toTokenMinAmount
                    })
                ),
                zetaValueAndGas: zetaValueAndGas,
                zetaParams: abi.encode("")
            })
        );

        emit FirstLegSuccess(
            msg.sender,
            iZetaToken,
            _args.fromTokenAmount,
            _args.toToken,
            zetaValueAndGas,
            address(uint160(bytes20(_args.recipientAddress))),
            protocolFee
        );
    }

    ///@dev Required function for ZetaConnector - Called on toChain
    ///@param _zetaMessage ZetaMessage struct args
    function onZetaMessage(ZetaInterfaces.ZetaMessage calldata _zetaMessage)
        external
        override
        isValidMessageCall(_zetaMessage)
    {
        XcMessage memory xcMessage = abi.decode(_zetaMessage.message, (XcMessage));

        // decode recipient address
        address recipientAddress = address(uint160(bytes20(xcMessage.recipientAddress)));

        uint256 toTokenFinalAmount;
        if (xcMessage.toToken == iZetaToken) {
            toTokenFinalAmount = _zetaMessage.zetaValue;

            // Transfer user the ZETA
            TransferHelper.safeTransfer(iZetaToken, recipientAddress, _zetaMessage.zetaValue);
        } else {
            if (xcMessage.toToken == NATIVE) {
                ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
                    .ExactInputSingleParams({
                        tokenIn: iZetaToken,
                        tokenOut: iWETH9,
                        fee: xcMessage.zetaWethPoolFee,
                        recipient: address(this),
                        deadline: block.timestamp + sMaxDeadline,
                        amountIn: _zetaMessage.zetaValue,
                        amountOutMinimum: xcMessage.toTokenMinAmount,
                        sqrtPriceLimitX96: 0
                    });

                // executes the swap
                toTokenFinalAmount = iSwapRouterUniV3.exactInputSingle(params);

                // unwrap wNATIVE and transfer to recipient
                IWETH(iWETH9).withdraw(toTokenFinalAmount);
                TransferHelper.safeTransferETH(recipientAddress, toTokenFinalAmount);
            } else {
                ISwapRouter.ExactInputParams memory params = ISwapRouter.ExactInputParams({
                    path: xcMessage.secondLegCalldata,
                    recipient: recipientAddress,
                    deadline: block.timestamp + sMaxDeadline,
                    amountIn: _zetaMessage.zetaValue,
                    amountOutMinimum: xcMessage.toTokenMinAmount
                });

                // executes the swap
                toTokenFinalAmount = iSwapRouterUniV3.exactInput(params);
            }

            if (toTokenFinalAmount < xcMessage.toTokenMinAmount) revert InsufficientToToken();
        }

        emit SecondLegSuccess(
            xcMessage.sourceTxOrigin,
            iZetaToken,
            _zetaMessage.zetaValue,
            xcMessage.toToken,
            toTokenFinalAmount,
            recipientAddress
        );
    }

    ///@dev Required function for ZetaConnector - Called on fromChain when toChain tx fails
    ///@param _zetaRevert ZetaRevert struct args
    function onZetaRevert(ZetaInterfaces.ZetaRevert calldata _zetaRevert)
        external
        override
        isValidRevertCall(_zetaRevert)
    {
        XcMessage memory xcMessage = abi.decode(_zetaRevert.message, (XcMessage));

        uint256 revertTokenFinalAmount;
        /**
         * if revertToken ZETA -> Send token straight to recipientAddress
         * else -> Swap remainingZetaValue to revertToken
         */
        if (xcMessage.revertToken == iZetaToken) {
            revertTokenFinalAmount = _zetaRevert.remainingZetaValue;

            // Transfer ZETA to user
            TransferHelper.safeTransfer(
                iZetaToken,
                xcMessage.sourceTxOrigin,
                _zetaRevert.remainingZetaValue
            );
        } else {
            /**
             * Get swap params
             * Recipient is this contract when revertToken is NATIVE
             * amountOutMinimum set to 0 to accept any output amount
             */
            ISwapRouter.ExactInputParams memory params = ISwapRouter.ExactInputParams({
                path: xcMessage.revertPath,
                recipient: xcMessage.revertToken == NATIVE
                    ? address(this)
                    : xcMessage.sourceTxOrigin,
                deadline: block.timestamp + sMaxDeadline,
                amountIn: _zetaRevert.remainingZetaValue,
                amountOutMinimum: 0
            });
            // Executes the swap
            revertTokenFinalAmount = iSwapRouterUniV3.exactInput(params);

            // Fallback to sending ZETA to sourceTxOrigin on failure to swap to revertToken
            if (!(revertTokenFinalAmount > 0)) {
                TransferHelper.safeTransfer(
                    iZetaToken,
                    xcMessage.sourceTxOrigin,
                    _zetaRevert.remainingZetaValue
                );
            }
        }

        // Unwrap wNATIVE token and send to sourceTxOrigin
        if (xcMessage.revertToken == NATIVE) {
            IWETH(iWETH9).withdraw(revertTokenFinalAmount);
            TransferHelper.safeTransferETH(xcMessage.sourceTxOrigin, revertTokenFinalAmount);
        }

        emit RevertedSwap(
            xcMessage.sourceTxOrigin,
            xcMessage.fromToken,
            xcMessage.revertToken,
            revertTokenFinalAmount
        );
    }

    ///@notice Set protocol fee
    ///@param _protocolFee protocol fee (parts per 1,000,000) e.g. 10000 == 1%
    function setProtocolFee(uint16 _protocolFee) external onlyOwner {
        sProtocolFee = _protocolFee;
        emit ProtocolFeeSet(_protocolFee);
    }

    ///@notice Set ZeroEx address
    ///@param _zeroEx ZeroEx address
    function setZeroEx(address _zeroEx) external onlyOwner {
        sZeroEx = _zeroEx;
        emit ZeroExSet(_zeroEx);
    }

    ///@notice Set sMaxDeadline
    ///@param _maxDeadline Max time a swap can take
    function setMaxDeadline(uint16 _maxDeadline) external onlyOwner {
        sMaxDeadline = _maxDeadline;
        emit MaxDeadlineSet(_maxDeadline);
    }

    ///@notice Withdraw all NATIVE token in contract to specified address
    ///@param _recipient Address to receive native token
    function withdrawNativeToken(address _recipient) external onlyOwner {
        uint256 amount = address(this).balance;
        require(payable(_recipient).send(amount));
        emit FeesWithdrawn(NATIVE, amount);
    }

    ///@notice Withdraw all ZETA in contract to specified address
    ///@param _recipient Address to receive ZETA
    function withdrawZeta(address _recipient) external onlyOwner {
        uint256 amount = IERC20(iZetaToken).balanceOf(address(this));
        TransferHelper.safeTransfer(iZetaToken, _recipient, amount);
        emit FeesWithdrawn(iZetaToken, amount);
    }
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.7;

import "./swapXc/ISwapXcEvents.sol";
import "./swapXc/ISwapXcErrors.sol";

interface ISwapXc is ISwapXcEvents, ISwapXcErrors {}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

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
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/ZetaInterfaces.sol";
import "./interfaces/ZetaInteractorErrors.sol";

abstract contract ZetaInteractor is Ownable, ZetaInteractorErrors {
    bytes32 constant ZERO_BYTES = keccak256(new bytes(0));
    uint256 internal immutable currentChainId;
    ZetaConnector public immutable connector;

    /**
     * @dev Maps a chain id to its corresponding address of the MultiChainSwap contract
     * The address is expressed in bytes to allow non-EVM chains
     * This mapping is useful, mainly, for two reasons:
     *  - Given a chain id, the contract is able to route a transaction to its corresponding address
     *  - To check that the messages (onZetaMessage, onZetaRevert) come from a trusted source
     */
    mapping(uint256 => bytes) public interactorsByChainId;

    modifier isValidMessageCall(ZetaInterfaces.ZetaMessage calldata zetaMessage) {
        _isValidCaller();
        if (keccak256(zetaMessage.zetaTxSenderAddress) != keccak256(interactorsByChainId[zetaMessage.sourceChainId]))
            revert InvalidZetaMessageCall();
        _;
    }

    modifier isValidRevertCall(ZetaInterfaces.ZetaRevert calldata zetaRevert) {
        _isValidCaller();
        if (zetaRevert.zetaTxSenderAddress != address(this)) revert InvalidZetaRevertCall();
        if (zetaRevert.sourceChainId != currentChainId) revert InvalidZetaRevertCall();
        _;
    }

    constructor(address zetaConnectorAddress) {
        currentChainId = block.chainid;
        connector = ZetaConnector(zetaConnectorAddress);
    }

    function _isValidCaller() private view {
        if (msg.sender != address(connector)) revert InvalidCaller(msg.sender);
    }

    /**
     * @dev Useful for contracts that inherit from this one
     */
    function _isValidChainId(uint256 chainId) internal view returns (bool) {
        return (keccak256(interactorsByChainId[chainId]) != ZERO_BYTES);
    }

    function setInteractorByChainId(uint256 destinationChainId, bytes calldata contractAddress) external onlyOwner {
        interactorsByChainId[destinationChainId] = contractAddress;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import '@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol';

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface ZetaInterfaces {
    /**
     * @dev Use SendInput to interact with the Connector: connector.send(SendInput)
     */
    struct SendInput {
        /// @dev Chain id of the destination chain. More about chain ids https://docs.zetachain.com/learn/glossary#chain-id
        uint256 destinationChainId;
        /// @dev Address receiving the message on the destination chain (expressed in bytes since it can be non-EVM)
        bytes destinationAddress;
        /// @dev Gas limit for the destination chain's transaction
        uint256 destinationGasLimit;
        /// @dev An encoded, arbitrary message to be parsed by the destination contract
        bytes message;
        /// @dev ZETA to be sent cross-chain + ZetaChain gas fees + destination chain gas fees (expressed in ZETA)
        uint256 zetaValueAndGas;
        /// @dev Optional parameters for the ZetaChain protocol
        bytes zetaParams;
    }

    /**
     * @dev Our Connector calls onZetaMessage with this struct as argument
     */
    struct ZetaMessage {
        bytes zetaTxSenderAddress;
        uint256 sourceChainId;
        address destinationAddress;
        /// @dev Remaining ZETA from zetaValueAndGas after subtracting ZetaChain gas fees and destination gas fees
        uint256 zetaValue;
        bytes message;
    }

    /**
     * @dev Our Connector calls onZetaRevert with this struct as argument
     */
    struct ZetaRevert {
        address zetaTxSenderAddress;
        uint256 sourceChainId;
        bytes destinationAddress;
        uint256 destinationChainId;
        /// @dev Equals to: zetaValueAndGas - ZetaChain gas fees - destination chain gas fees - source chain revert tx gas fees
        uint256 remainingZetaValue;
        bytes message;
    }
}

interface ZetaConnector {
    /**
     * @dev Sending value and data cross-chain is as easy as calling connector.send(SendInput)
     */
    function send(ZetaInterfaces.SendInput calldata input) external;
}

interface ZetaReceiver {
    /**
     * @dev onZetaMessage is called when a cross-chain message reaches a contract
     */
    function onZetaMessage(ZetaInterfaces.ZetaMessage calldata zetaMessage) external;

    /**
     * @dev onZetaRevert is called when a cross-chain message reverts.
     * It's useful to rollback to the original state
     */
    function onZetaRevert(ZetaInterfaces.ZetaRevert calldata zetaRevert) external;
}

/**
 * @dev ZetaTokenConsumer makes it easier to handle the following situations:
 *   - Getting Zeta using native coin (to pay for destination gas while using `connector.send`)
 *   - Getting Zeta using a token (to pay for destination gas while using `connector.send`)
 *   - Getting native coin using Zeta (to return unused destination gas when `onZetaRevert` is executed)
 *   - Getting a token using Zeta (to return unused destination gas when `onZetaRevert` is executed)
 * @dev The interface can be implemented using different strategies, like UniswapV2, UniswapV3, etc
 */
interface ZetaTokenConsumer {
    event EthExchangedForZeta(uint256 amountIn, uint256 amountOut);
    event TokenExchangedForZeta(address token, uint256 amountIn, uint256 amountOut);
    event ZetaExchangedForEth(uint256 amountIn, uint256 amountOut);
    event ZetaExchangedForToken(address token, uint256 amountIn, uint256 amountOut);

    function getZetaFromEth(address destinationAddress, uint256 minAmountOut) external payable returns (uint256);

    function getZetaFromToken(
        address destinationAddress,
        uint256 minAmountOut,
        address inputToken,
        uint256 inputTokenAmount
    ) external returns (uint256);

    function getEthFromZeta(
        address destinationAddress,
        uint256 minAmountOut,
        uint256 zetaTokenAmount
    ) external returns (uint256);

    function getTokenFromZeta(
        address destinationAddress,
        uint256 minAmountOut,
        address outputToken,
        uint256 zetaTokenAmount
    ) external returns (uint256);
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.7;

interface ISwapXcEvents {
    event FirstLegSuccess(
        address sourceTxOrigin,
        address fromToken,
        uint256 fromTokenAmount,
        address toToken,
        uint256 toTokenFinalAmount,
        address receiverAddress,
        uint256 protocolFee
    );
    event SecondLegSuccess(
        address sourceTxOrigin,
        address fromToken,
        uint256 fromTokenAmount,
        address toToken,
        uint256 toTokenFinalAmount,
        address receiverAddress
    );
    event RevertedSwap(
        address sourceTxOrigin,
        address fromToken,
        address revertToken,
        uint256 revertTokenReturnedAmount
    );
    event ProtocolFeeSet(uint256 fee);
    event ZeroExSet(address zeroEx);
    event MaxDeadlineSet(uint16 maxDeadline);
    event FeesWithdrawn(address token, uint256 amount);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface ISwapXcErrors {
    error InvalidMessageType();

    error BuyZetaFailed();

    error ValueNotEqualFromAmount();

    error InsufficientToToken();
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface ZetaInteractorErrors {
    error InvalidDestinationChainId();

    error InvalidCaller(address caller);

    error InvalidZetaMessageCall();

    error InvalidZetaRevertCall();
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}