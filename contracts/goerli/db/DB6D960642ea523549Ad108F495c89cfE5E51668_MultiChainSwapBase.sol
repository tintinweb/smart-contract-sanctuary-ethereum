// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@zetachain/protocol-contracts/contracts/ZetaInteractor.sol";
import "@zetachain/protocol-contracts/contracts/ZetaInterfaces.sol";
import "@zetachain/protocol-contracts/contracts/ZetaReceiver.sol";

import "./MultiChainSwapErrors.sol";

contract MultiChainSwapBase is ZetaInteractor, ZetaReceiver, MultiChainSwapErrors {
    uint16 internal constant MAX_DEADLINE = 365;
    bytes32 public constant CROSS_CHAIN_SWAP_MESSAGE = keccak256("CROSS_CHAIN_SWAP");

    address public uniswapV2RouterAddress;
    address internal immutable wETH;
    address public zetaToken;

    IUniswapV2Router02 internal uniswapV2Router;

    event SentTokenSwap(
        address originSender,
        address originInputToken,
        uint256 inputTokenAmount,
        address destinationOutToken,
        uint256 outTokenMinAmount,
        address receiverAddress
    );

    event SentEthSwap(
        address originSender,
        uint256 inputEthAmount,
        address destinationOutToken,
        uint256 outTokenMinAmount,
        address receiverAddress
    );

    event Swapped(
        address originSender,
        address originInputToken,
        uint256 inputTokenAmount,
        address destinationOutToken,
        uint256 outTokenFinalAmount,
        address receiverAddress
    );

    event RevertedSwap(
        address originSender,
        address originInputToken,
        uint256 inputTokenAmount,
        uint256 inputTokenReturnedAmount
    );

    constructor(
        address _zetaConnector,
        address _zetaTokenInput,
        address _uniswapV2Router
    ) ZetaInteractor(_zetaConnector) {
        zetaToken = _zetaTokenInput;
        uniswapV2RouterAddress = _uniswapV2Router;
        uniswapV2Router = IUniswapV2Router02(_uniswapV2Router);
        wETH = uniswapV2Router.WETH();
    }

    function swapETHForTokensCrossChain(
        bytes calldata receiverAddress,
        address destinationOutToken,
        bool isDestinationOutETH,
        /**
         * @dev The minimum amount of tokens that receiverAddress should get,
         * if it's not reached, the transaction will revert on the destination chain
         */
        uint256 outTokenMinAmount,
        uint256 destinationChainId,
        uint256 crossChainGasLimit
    ) external payable {
        if (!isValidChainId(destinationChainId)) revert InvalidDestinationChainId();

        if (msg.value == 0) revert ValueShouldBeGreaterThanZero();
        if (
            (destinationOutToken != address(0) && isDestinationOutETH) ||
            (destinationOutToken == address(0) && !isDestinationOutETH)
        ) revert OutTokenInvariant();

        uint256 zetaAmount;
        {
            address[] memory path = new address[](2);
            path[0] = wETH;
            path[1] = zetaToken;

            uint256[] memory amounts = uniswapV2Router.swapExactETHForTokens{value: msg.value}(
                0, /// @dev Output can't be validated here, it's validated after the next swap
                path,
                address(this),
                block.timestamp + MAX_DEADLINE
            );

            zetaAmount = amounts[path.length - 1];
        }
        if (zetaAmount == 0) revert ErrorSwappingTokens();

        {
            bool success = IERC20(zetaToken).approve(address(connector), zetaAmount);
            if (!success) revert ErrorApprovingTokens(zetaToken);
        }

        connector.send(
            ZetaInterfaces.SendInput({
                destinationChainId: destinationChainId,
                destinationAddress: interactorsByChainId[destinationChainId],
                gasLimit: crossChainGasLimit,
                message: abi.encode(
                    CROSS_CHAIN_SWAP_MESSAGE,
                    msg.sender,
                    wETH,
                    msg.value,
                    receiverAddress,
                    destinationOutToken,
                    isDestinationOutETH,
                    outTokenMinAmount,
                    true // inputTokenIsETH
                ),
                zetaAmount: zetaAmount,
                zetaParams: abi.encode("")
            })
        );
    }

    function swapTokensForTokensCrossChain(
        address originInputToken,
        uint256 inputTokenAmount,
        bytes calldata receiverAddress,
        address destinationOutToken,
        bool isDestinationOutETH,
        /**
         * @dev The minimum amount of tokens that receiverAddress should get,
         * if it's not reached, the transaction will revert on the destination chain
         */
        uint256 outTokenMinAmount,
        uint256 destinationChainId,
        uint256 crossChainGasLimit
    ) external {
        if (keccak256(interactorsByChainId[destinationChainId]) == keccak256(new bytes(0)))
            revert InvalidDestinationChainId();

        if (originInputToken == address(0)) revert MissingOriginInputTokenAddress();
        if (
            (destinationOutToken != address(0) && isDestinationOutETH) ||
            (destinationOutToken == address(0) && !isDestinationOutETH)
        ) revert OutTokenInvariant();

        uint256 zetaAmount;

        if (originInputToken == zetaToken) {
            bool success1 = IERC20(zetaToken).transferFrom(msg.sender, address(this), inputTokenAmount);
            bool success2 = IERC20(zetaToken).approve(address(connector), inputTokenAmount);
            if (!success1 || !success2) revert ErrorTransferringTokens(zetaToken);

            zetaAmount = inputTokenAmount;
        } else {
            /**
             * @dev If the input token is not Zeta, trade it using Uniswap
             */
            {
                bool success1 = IERC20(originInputToken).transferFrom(msg.sender, address(this), inputTokenAmount);
                bool success2 = IERC20(originInputToken).approve(uniswapV2RouterAddress, inputTokenAmount);
                if (!success1 || !success2) revert ErrorTransferringTokens(originInputToken);
            }

            address[] memory path;
            if (originInputToken == wETH) {
                path = new address[](2);
                path[0] = wETH;
                path[1] = zetaToken;
            } else {
                path = new address[](3);
                path[0] = originInputToken;
                path[1] = wETH;
                path[2] = zetaToken;
            }

            uint256[] memory amounts = uniswapV2Router.swapExactTokensForTokens(
                inputTokenAmount,
                0, /// @dev Output can't be validated here, it's validated after the next swap
                path,
                address(this),
                block.timestamp + MAX_DEADLINE
            );

            zetaAmount = amounts[path.length - 1];
            if (zetaAmount == 0) revert ErrorSwappingTokens();
        }

        {
            bool success = IERC20(zetaToken).approve(address(connector), zetaAmount);
            if (!success) revert ErrorApprovingTokens(zetaToken);
        }

        connector.send(
            ZetaInterfaces.SendInput({
                destinationChainId: destinationChainId,
                destinationAddress: interactorsByChainId[destinationChainId],
                gasLimit: crossChainGasLimit,
                message: abi.encode(
                    CROSS_CHAIN_SWAP_MESSAGE,
                    msg.sender,
                    originInputToken,
                    inputTokenAmount,
                    receiverAddress,
                    destinationOutToken,
                    isDestinationOutETH,
                    outTokenMinAmount,
                    false // inputTokenIsETH
                ),
                zetaAmount: zetaAmount,
                zetaParams: abi.encode("")
            })
        );
    }

    function onZetaMessage(ZetaInterfaces.ZetaMessage calldata zetaMessage) external isValidMessageCall(zetaMessage) {
        (
            bytes32 messageType,
            address originSender,
            address originInputToken,
            uint256 inputTokenAmount,
            bytes memory receiverAddressEncoded,
            address destinationOutToken,
            bool isDestinationOutETH,
            uint256 outTokenMinAmount,

        ) = abi.decode(zetaMessage.message, (bytes32, address, address, uint256, bytes, address, bool, uint256, bool));

        address receiverAddress = address(uint160(bytes20(receiverAddressEncoded)));

        if (messageType != CROSS_CHAIN_SWAP_MESSAGE) revert InvalidMessageType();

        uint256 outTokenFinalAmount;
        if (destinationOutToken == zetaToken) {
            if (zetaMessage.zetaAmount < outTokenMinAmount) revert InsufficientOutToken();

            bool success = IERC20(zetaToken).transfer(receiverAddress, zetaMessage.zetaAmount);
            if (!success) revert ErrorTransferringTokens(zetaToken);

            outTokenFinalAmount = zetaMessage.zetaAmount;
        } else {
            /**
             * @dev If the out token is not Zeta, get it using Uniswap
             */
            {
                bool success = IERC20(zetaToken).approve(uniswapV2RouterAddress, zetaMessage.zetaAmount);
                if (!success) revert ErrorApprovingTokens(zetaToken);
            }

            address[] memory path;
            if (destinationOutToken == wETH || isDestinationOutETH) {
                path = new address[](2);
                path[0] = zetaToken;
                path[1] = wETH;
            } else {
                path = new address[](3);
                path[0] = zetaToken;
                path[1] = wETH;
                path[2] = destinationOutToken;
            }

            uint256[] memory amounts;
            if (isDestinationOutETH) {
                amounts = uniswapV2Router.swapExactTokensForETH(
                    zetaMessage.zetaAmount,
                    outTokenMinAmount,
                    path,
                    receiverAddress,
                    block.timestamp + MAX_DEADLINE
                );
            } else {
                amounts = uniswapV2Router.swapExactTokensForTokens(
                    zetaMessage.zetaAmount,
                    outTokenMinAmount,
                    path,
                    receiverAddress,
                    block.timestamp + MAX_DEADLINE
                );
            }

            outTokenFinalAmount = amounts[amounts.length - 1];
            if (outTokenFinalAmount == 0) revert ErrorSwappingTokens();
            if (outTokenFinalAmount < outTokenMinAmount) revert InsufficientOutToken();
        }

        emit Swapped(
            originSender,
            originInputToken,
            inputTokenAmount,
            destinationOutToken,
            outTokenFinalAmount,
            receiverAddress
        );
    }

    function onZetaRevert(ZetaInterfaces.ZetaRevert calldata zetaRevert) external isValidRevertCall(zetaRevert) {
        /**
         * @dev: If something goes wrong we must swap to the original token
         */
        (, address originSender, address originInputToken, uint256 inputTokenAmount, , , , , bool inputTokenIsETH) = abi
            .decode(zetaRevert.message, (bytes32, address, address, uint256, bytes, address, bool, uint256, bool));

        uint256 inputTokenReturnedAmount;
        if (originInputToken == zetaToken) {
            bool success1 = IERC20(zetaToken).approve(address(this), zetaRevert.zetaAmount);
            bool success2 = IERC20(zetaToken).transferFrom(address(this), originSender, zetaRevert.zetaAmount);
            if (!success1 || !success2) revert ErrorTransferringTokens(zetaToken);
            inputTokenReturnedAmount = zetaRevert.zetaAmount;
        } else {
            /**
             * @dev If the original input token is not Zeta, trade it using Uniswap
             */
            {
                bool success = IERC20(zetaToken).approve(uniswapV2RouterAddress, zetaRevert.zetaAmount);
                if (!success) revert ErrorTransferringTokens(zetaToken);
            }

            address[] memory path;
            if (originInputToken == wETH) {
                path = new address[](2);
                path[0] = zetaToken;
                path[1] = wETH;
            } else {
                path = new address[](3);
                path[0] = zetaToken;
                path[1] = wETH;
                path[2] = originInputToken;
            }
            {
                uint256[] memory amounts;

                if (inputTokenIsETH) {
                    amounts = uniswapV2Router.swapExactTokensForETH(
                        zetaRevert.zetaAmount,
                        0, /// @dev Any output is fine, otherwise the value will be stuck in the contract
                        path,
                        originSender,
                        block.timestamp + MAX_DEADLINE
                    );
                } else {
                    amounts = uniswapV2Router.swapExactTokensForTokens(
                        zetaRevert.zetaAmount,
                        0, /// @dev Any output is fine, otherwise the value will be stuck in the contract
                        path,
                        originSender,
                        block.timestamp + MAX_DEADLINE
                    );
                }
                inputTokenReturnedAmount = amounts[amounts.length - 1];
            }
        }

        emit RevertedSwap(originSender, originInputToken, inputTokenAmount, inputTokenReturnedAmount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./ZetaInterfaces.sol";
import "./ZetaInteractorErrors.sol";

abstract contract ZetaInteractor is Ownable, ZetaInteractorErrors {
    uint256 internal immutable currentChainId;
    ZetaConnector public connector;

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
        if (keccak256(zetaMessage.originSenderAddress) != keccak256(interactorsByChainId[zetaMessage.originChainId]))
            revert InvalidZetaMessageCall();
        _;
    }

    modifier isValidRevertCall(ZetaInterfaces.ZetaRevert calldata zetaRevert) {
        _isValidCaller();
        if (zetaRevert.originSenderAddress != address(this)) revert InvalidZetaRevertCall();
        if (zetaRevert.originChainId != currentChainId) revert InvalidZetaRevertCall();
        _;
    }

    constructor(address zetaConnectorAddress) {
        currentChainId = block.chainid;
        connector = ZetaConnector(zetaConnectorAddress);
    }

    function _isValidCaller() private view {
        if (msg.sender != address(connector)) revert InvalidCaller(msg.sender);
    }

    function isValidChainId(uint256 chainId) internal view returns (bool) {
        return (keccak256(interactorsByChainId[chainId]) != keccak256(new bytes(0)));
    }

    function setInteractorByChainId(uint256 destinationChainId, bytes calldata contractAddress) external onlyOwner {
        interactorsByChainId[destinationChainId] = contractAddress;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface ZetaInterfaces {
    /**
     * @dev Use SendInput to interact with our Connector: connector.send(SendInput)
     */
    struct SendInput {
        /// @dev Chain id of the destination chain. More about chain ids https://docs.zetachain.com/learn/glossary#chain-id
        uint256 destinationChainId;
        /// @dev Address to send to on the destination chain (expressed in bytes since it can be non-EVM)
        bytes destinationAddress;
        /// @dev Gas amount limit for the destination chain's transaction
        uint256 gasLimit;
        /// @dev An encoded, arbitrary message to be parsed by the destination contract
        bytes message;
        /// @dev The amount of ZETA that you want to send cross-chain + the gas fees to be paid for the transaction
        uint256 zetaAmount;
        /// @dev Optional parameters for the ZetaChain protocol
        bytes zetaParams;
    }

    /**
     * @dev Our Connector will call your contract's onZetaMessage using this interface
     */
    struct ZetaMessage {
        bytes originSenderAddress;
        uint256 originChainId;
        address destinationAddress;
        uint256 zetaAmount;
        bytes message;
    }

    /**
     * @dev Our Connector will call your contract's onZetaRevert using this interface
     */
    struct ZetaRevert {
        address originSenderAddress;
        uint256 originChainId;
        bytes destinationAddress;
        uint256 destinationChainId;
        uint256 zetaAmount;
        bytes message;
    }
}

interface ZetaConnector {
    /**
     * @dev Sending value and data cross-chain is as easy as calling connector.send(SendInput)
     */
    function send(ZetaInterfaces.SendInput calldata input) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./ZetaInterfaces.sol";

interface ZetaReceiver {
    /**
     * @dev onZetaMessage will be called when a cross-chain message is delivered to your contract
     */
    function onZetaMessage(ZetaInterfaces.ZetaMessage calldata zetaMessage) external;

    /**
     * @dev onZetaRevert will be called when a cross-chain message reverts
     * It's useful to rollback your contract's state
     */
    function onZetaRevert(ZetaInterfaces.ZetaRevert calldata zetaRevert) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface MultiChainSwapErrors {
    error ErrorTransferringTokens(address token);

    error ErrorApprovingTokens(address token);

    error ErrorSwappingTokens();

    error ValueShouldBeGreaterThanZero();

    error OutTokenInvariant();

    error InsufficientOutToken();

    error MissingOriginInputTokenAddress();

    error InvalidMessageType();
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

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
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
pragma solidity ^0.8.12;

interface ZetaInteractorErrors {
    error InvalidDestinationChainId();

    error InvalidCaller(address caller);

    error InvalidZetaMessageCall();

    error InvalidZetaRevertCall();
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