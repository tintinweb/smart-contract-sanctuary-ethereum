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

pragma solidity >=0.5.0;

interface IDXswapFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function INIT_CODE_PAIR_HASH() external pure returns (bytes32);
    function feeTo() external view returns (address);
    function protocolFeeDenominator() external view returns (uint8);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
    function setProtocolFee(uint8 _protocolFee) external;
    function setSwapFee(address pair, uint32 swapFee) external;
}

pragma solidity >=0.5.0;

interface IDXswapPair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);
    function swapFee() external view returns (uint32);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
    function setSwapFee(uint32) external;
}

pragma solidity >=0.5.0;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
    function balanceOf(address owner) external view returns (uint);
}

pragma solidity >=0.6.2;


interface IDXswapRouter {
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
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut, uint swapFee) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut, uint swapFee) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);

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

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

//SPDX-License-Identifier: MIT
pragma solidity =0.8.15;

import {IDXswapFactory} from '@swapr/core/contracts/interfaces/IDXswapFactory.sol';
import {IDXswapPair} from '@swapr/core/contracts/interfaces/IDXswapPair.sol';
import {IERC20} from '@swapr/core/contracts/interfaces/IERC20.sol';
import {IWETH} from '@swapr/core/contracts/interfaces/IWETH.sol';
import {IDXswapRouter} from '@swapr/periphery/contracts/interfaces/IDXswapRouter.sol';
import {TransferHelper} from '@swapr/periphery/contracts/libraries/TransferHelper.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import './peripherals/Ownable.sol';

error ForbiddenFeeValue();
error InsufficientSwapMinAmount();
error InsufficientTokenInputAmount();
error InvalidPair();
error InvalidStartPath();
error InvalidTargetPath();
error OnlyFeeSetter();
error ZeroAddressInput();

/// @title Zap
/// @notice Allows to zapIn from an ERC20 or native currency to ERC20 pair
/// and zapOut from an ERC20 pair to an ERC20 or native currency
/// @dev Dusts from zap can be withdrawn by owner
contract TesterZap is Ownable, ReentrancyGuard {
    uint16 public protocolFee = 50; // default 0.5% of zap amount protocol fee
    address public immutable nativeCurrencyWrapper;
    address public feeTo;
    address public feeToSetter;
    IDXswapFactory public immutable factory;
    IDXswapRouter public immutable router;

    event ZapInFromToken(
        address indexed sender,
        address indexed tokenFrom,
        uint256 amountFrom,
        address indexed pairTo,
        uint256 amountTo
    );

    event ZapInFromNativeCurrency(
        address indexed sender,
        uint256 amountNativeCurrencyWrapper,
        address indexed pairTo,
        uint256 amountTo
    );

    event ZapOutToToken(
        address indexed sender,
        address indexed pairFrom,
        uint256 amountFrom,
        address tokenTo,
        uint256 amountTo
    );

    event ZapOutToNativeCurrency(
        address indexed sender,
        address indexed pairFrom,
        uint256 amountFrom,
        uint256 amountNativeCurrencyWrapper
    );

    /// @notice Constructor
    /// @param _factory The address of factory
    /// @param _router The address of router
    /// @param _nativeCurrencyWrapper The address of wrapped native currency
    constructor(
        address _owner,
        address _factory,
        address _router,
        address _nativeCurrencyWrapper,
        address _feeToSetter
    ) Ownable(_owner) {
        if (_router == address(0)) revert ZeroAddressInput();

        factory = IDXswapFactory(_factory);
        router = IDXswapRouter(_router);
        nativeCurrencyWrapper = _nativeCurrencyWrapper;
        feeToSetter = _feeToSetter;
    }

    /// @notice TokenFrom is the first value of `pathToPairToken(0/1)` array.
    /// Swaps half of it to token0 and the other half token1 and add liquidity
    /// with the swapped amounts
    /// @dev Any excess from adding liquidity is kept by Zap
    /// @param amountFrom The amountFrom of tokenFrom to zap
    /// @param amount0Min The min amount to receive of token0
    /// @param amount1Min The min amount to receive of token1
    /// @param pathToPairToken0 The path to the pair's token0
    /// @param pathToPairToken1 The path to the pair's token1
    function zapInFromToken(
        uint256 amountFrom,
        uint256 amount0Min,
        uint256 amount1Min,
        address[] calldata pathToPairToken0,
        address[] calldata pathToPairToken1
    ) external nonReentrant returns (uint256 amountTo) {
        if (amountFrom == 0) revert InsufficientTokenInputAmount();
        if (pathToPairToken0[0] != pathToPairToken1[0]) revert InvalidStartPath();
        // Call to factory to check if pair is valid
        address pair = _getFactoryPair(
            pathToPairToken0[pathToPairToken0.length - 1],
            pathToPairToken1[pathToPairToken1.length - 1]
        );

        address token = pathToPairToken0[0];

        // Transfer tax tokens safeguard
        uint256 previousBalance = IERC20(token).balanceOf(address(this));
        TransferHelper.safeTransferFrom(token, msg.sender, address(this), amountFrom);
        uint256 amountReceived = (IERC20(token).balanceOf(address(this))) - (previousBalance);

        // Send protocol fee if fee receiver address is set
        if (feeTo != address(0) && protocolFee > 0) {
            uint256 amountFeeTo;
            unchecked {
                amountFeeTo = (amountReceived * protocolFee) / 10000;
                amountReceived = amountReceived - amountFeeTo;
            }
            TransferHelper.safeTransfer(token, feeTo, amountFeeTo);
        }

        amountTo = _zapInFromToken(amountReceived, amount0Min, amount1Min, pathToPairToken0, pathToPairToken1);

        emit ZapInFromToken(msg.sender, token, amountFrom, pair, amountTo);
    }

    /// @notice Swaps half of NativeCurrencyWrapper to token0 and the other half token1 and
    /// add liquidity with the swapped amounts
    /// @dev Any excess from adding liquidity is kept by Zap
    /// @param amount0Min The min amount of token0 to add liquidity
    /// @param amount1Min The min amount to token1 to add liquidity
    /// @param pathToPairToken0 The path to the pair's token0
    /// @param pathToPairToken1 The path to the pair's token1
    function zapInFromNativeCurrency(
        uint256 amount0Min,
        uint256 amount1Min,
        address[] calldata pathToPairToken0,
        address[] calldata pathToPairToken1
    ) external payable nonReentrant returns (uint256 amountTo) {
        uint256 amountFrom = msg.value;
        if (amountFrom == 0) revert InsufficientTokenInputAmount();
        if (pathToPairToken0[0] != nativeCurrencyWrapper || pathToPairToken1[0] != nativeCurrencyWrapper)
            revert InvalidStartPath();
        // Call to factory to check if pair is valid
        address pair = _getFactoryPair(
            pathToPairToken0[pathToPairToken0.length - 1],
            pathToPairToken1[pathToPairToken1.length - 1]
        );

        // Send protocol fee if fee receiver address is set
        if (feeTo != address(0) && protocolFee > 0) {
            uint256 amountFeeTo;
            unchecked {
                amountFeeTo = (amountFrom * protocolFee) / 10000;
                amountFrom = amountFrom - amountFeeTo;
            }
            TransferHelper.safeTransferETH(feeTo, amountFeeTo);
        }

        IWETH(nativeCurrencyWrapper).deposit{value: amountFrom}();

        amountTo = _zapInFromToken(amountFrom, amount0Min, amount1Min, pathToPairToken0, pathToPairToken1);

        emit ZapInFromNativeCurrency(msg.sender, msg.value, pair, amountTo);
    }

    /// @notice Unwrap Pair and swap the 2 tokens to path(0/1)[-1]
    /// @dev path0 and path1 do not need to be ordered
    /// @param amountFrom The amount of liquidity to zap
    /// @param amountToMin The min amount to receive of tokenTo
    /// @param path0 The path to one of the pair's token
    /// @param path1 The path to one of the pair's token
    function zapOutToToken(
        uint256 amountFrom,
        uint256 amountToMin,
        address[] calldata path0,
        address[] calldata path1
    ) external nonReentrant returns (uint256 amountTo) {
        if (path0[path0.length - 1] != path1[path1.length - 1]) revert InvalidTargetPath();

        IDXswapPair pairFrom = IDXswapPair(_getFactoryPair(path0[0], path1[0]));
        amountTo = _zapOutToToken(pairFrom, amountFrom, amountToMin, path0, path1, msg.sender);

        emit ZapOutToToken(msg.sender, address(pairFrom), amountFrom, path0[path0.length - 1], amountTo);
    }

    /// @notice Unwrap Pair and swap the 2 tokens to path(0/1)[-1]
    /// @dev path0 and path1 do not need to be ordered
    /// @param amountFrom The amount of liquidity to zap
    /// @param amountToMin The min amount to receive of token1
    /// @param path0 The path to one of the pair's token
    /// @param path1 The path to one of the pair's token
    function zapOutToNativeCurrency(
        uint256 amountFrom,
        uint256 amountToMin,
        address[] calldata path0,
        address[] calldata path1
    ) external nonReentrant returns (uint256 amountTo) {
        if (path0[path0.length - 1] != nativeCurrencyWrapper || path1[path1.length - 1] != nativeCurrencyWrapper)
            revert InvalidTargetPath();

        IDXswapPair pairFrom = IDXswapPair(_getFactoryPair(path0[0], path1[0]));
        amountTo = _zapOutToToken(pairFrom, amountFrom, amountToMin, path0, path1, address(this));

        IWETH(nativeCurrencyWrapper).withdraw(amountTo);
        TransferHelper.safeTransferETH(msg.sender, amountTo);

        emit ZapOutToNativeCurrency(msg.sender, address(pairFrom), amountFrom, amountTo);
    }

    /// @notice Allows the contract to receive native currency
    /// @dev It is necessary to be able to receive native currency when using nativeCurrencyWrapper.withdraw()
    receive() external payable {}

    /// @notice Withdraw token to owner of the Zap contract
    /// @dev if token's address is null address, sends NativeCurrencyWrapper
    /// @param token The token to withdraw
    function withdraw(address token) external onlyOwner {
        if (token == address(0)) {
            TransferHelper.safeTransferETH(msg.sender, address(this).balance);
        } else {
            uint256 amount = IERC20(token).balanceOf(address(this));
            IERC20(token).transfer(msg.sender, amount);
        }
    }

    /// @notice Swaps half of tokenFrom to token0 and the other half token1 and add liquidity
    /// with the swapped amounts
    /// @dev Any excess from adding liquidity is kept by Zap
    /// @param amountFrom The amountFrom of tokenFrom to zap
    /// @param amount0Min The min amount to receive of token0
    /// @param amount1Min The min amount to receive of token1
    /// @param pathToPairToken0 The path to the pair's token0
    /// @param pathToPairToken1 The path to the pair's token
    /// @return liquidity The amount of liquidity received
    function _zapInFromToken(
        uint256 amountFrom,
        uint256 amount0Min,
        uint256 amount1Min,
        address[] calldata pathToPairToken0,
        address[] calldata pathToPairToken1
    ) internal returns (uint256 liquidity) {
        uint256 amountFromToken0;
        uint256 amountFromToken1;
        unchecked {
            amountFromToken0 = amountFrom / 2;
            amountFromToken1 = amountFrom - amountFromToken0;
        }
        uint256 amount0 = _swapExactTokensForTokens(amountFromToken0, 0, pathToPairToken0, address(this));
        uint256 amount1 = _swapExactTokensForTokens(amountFromToken1, 0, pathToPairToken1, address(this));

        if (amount0 < amount0Min || amount1 < amount1Min) revert InsufficientSwapMinAmount();

        liquidity = _addLiquidity(amount0, amount1, amount0Min, amount1Min, pathToPairToken0, pathToPairToken1);
    }

    /// @notice Unwrap Pair and swap the 2 tokens to path(0/1)[-1]
    /// @dev path0 and path1 do not need to be ordered
    /// @param pair The pair to unwrap
    /// @param amountFrom The amount of liquidity to zap
    /// @param amountToMin The min amount to receive of token1
    /// @param path0 The path to one of the pair's token
    /// @param path1 The path to one of the pair's token
    /// @param to The address to send the token
    /// @return amountTo The amount of tokenTo received
    function _zapOutToToken(
        IDXswapPair pair,
        uint256 amountFrom,
        uint256 amountToMin,
        address[] calldata path0,
        address[] calldata path1,
        address to
    ) internal returns (uint256 amountTo) {
        if (amountFrom == 0) revert InsufficientTokenInputAmount();
        pair.transferFrom(msg.sender, address(this), amountFrom);

        (uint256 balance0, uint256 balance1) = _removeLiquidity(pair, amountFrom);

        if (path0[0] > path1[0]) {
            (path0, path1) = (path1, path0);
        }

        amountTo = _swapExactTokensForTokens(balance0, 0, path0, to);
        amountTo = amountTo + (_swapExactTokensForTokens(balance1, 0, path1, to));

        if (amountTo < amountToMin) revert InsufficientSwapMinAmount();
    }

    /// @notice Approves the token if needed
    /// @param token The address of the token
    /// @param amount The amount of token to send
    function _approveTokenIfNeeded(address token, uint256 amount) internal {
        if (IERC20(token).allowance(address(this), address(router)) < amount) {
            TransferHelper.safeApprove(token, address(router), amount);
        }
    }

    /// @notice Swaps exact tokenFrom following path
    /// @param amountFrom The amount of tokenFrom to swap
    /// @param amountToMin The min amount of tokenTo to receive
    /// @param path The path to follow to swap tokenFrom to TokenTo
    /// @param to The address that will receive tokenTo
    /// @return amountTo The amount of token received
    function _swapExactTokensForTokens(
        uint256 amountFrom,
        uint256 amountToMin,
        address[] calldata path,
        address to
    ) internal returns (uint256 amountTo) {
        uint256 len = path.length;
        address token = path[len - 1];
        uint256 balanceBefore = IERC20(token).balanceOf(to);

        // swap tokens following the path
        if (len > 1) {
            _approveTokenIfNeeded(path[0], amountFrom);
            router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                amountFrom,
                amountToMin,
                path,
                to,
                block.timestamp
            );
            amountTo = IERC20(token).balanceOf(to) - balanceBefore;
        } else {
            // no swap needed because path is only 1-element
            if (to != address(this)) {
                // transfer token to receiver address
                TransferHelper.safeTransfer(token, to, amountFrom);
                amountTo = IERC20(token).balanceOf(to) - balanceBefore;
            } else {
                // ZapIn case: token already on Zap contract balance
                amountTo = amountFrom;
            }
        }
        if (amountTo < amountToMin) revert InsufficientSwapMinAmount();
    }

    /// @notice Adds liquidity to the pair of the last 2 tokens of paths
    /// @param amount0 The amount of token0 to add to liquidity
    /// @param amount1 The amount of token1 to add to liquidity
    /// @param amount0Min The min amount of token0 to add to liquidity
    /// @param amount1Min The min amount of token0 to add to liquidity
    /// @param pathToPairToken0 The path from tokenFrom to one of the pair's tokens
    /// @param pathToPairToken1 The path from tokenFrom to one of the pair's tokens
    /// @return liquidity The amount of liquidity added
    function _addLiquidity(
        uint256 amount0,
        uint256 amount1,
        uint256 amount0Min,
        uint256 amount1Min,
        address[] calldata pathToPairToken0,
        address[] calldata pathToPairToken1
    ) internal returns (uint256 liquidity) {
        (address token0, address token1) = (
            pathToPairToken0[pathToPairToken0.length - 1],
            pathToPairToken1[pathToPairToken1.length - 1]
        );

        _approveTokenIfNeeded(token0, amount0);
        _approveTokenIfNeeded(token1, amount1);

        (, , liquidity) = router.addLiquidity(
            token0,
            token1,
            amount0,
            amount1,
            amount0Min,
            amount1Min,
            msg.sender,
            block.timestamp
        );
    }

    /// @notice Removes amount of liquidity from pair
    /// @param amount The amount of liquidity of the pair to unwrap
    /// @param pair The address of the pair
    /// @return token0Balance The actual amount of token0 received
    /// @return token1Balance The actual amount of token received
    function _removeLiquidity(IDXswapPair pair, uint256 amount) internal returns (uint256, uint256) {
        _approveTokenIfNeeded(address(pair), amount);

        address token0 = pair.token0();
        address token1 = pair.token1();

        uint256 balance0Before = IERC20(token0).balanceOf(address(this));
        uint256 balance1Before = IERC20(token1).balanceOf(address(this));
        router.removeLiquidity(token0, token1, amount, 0, 0, address(this), block.timestamp);

        return (
            IERC20(token0).balanceOf(address(this)) - balance0Before,
            IERC20(token1).balanceOf(address(this)) - balance1Before
        );
    }

    /// @notice Gets and validates pair's address
    /// @param token0 The addres of the first token of the pair
    /// @param token1 The addres of the second token of the pair
    /// @return pair The address of the pair
    function _getFactoryPair(address token0, address token1) internal view returns (address pair) {
        pair = factory.getPair(token0, token1);
        if (pair == address(0)) revert InvalidPair();
    }

    /// @notice Sets the fee receiver address
    /// @param _feeTo The address to send received zap fee
    function setFeeTo(address _feeTo) external {
        if (msg.sender != feeToSetter) revert OnlyFeeSetter();
        feeTo = _feeTo;
    }

    /// @notice Sets the setter address
    /// @param _feeToSetter The address of the fee setter
    function setFeeToSetter(address _feeToSetter) external {
        if (msg.sender != feeToSetter) revert OnlyFeeSetter();
        feeToSetter = _feeToSetter;
    }

    /// @notice Sets the protocol fee percent
    /// @param _protocolFee The new protocl fee percent
    function setProtocolFee(uint16 _protocolFee) external {
        if (msg.sender != feeToSetter) revert OnlyFeeSetter();
        if (_protocolFee > 10000) revert ForbiddenFeeValue();
        protocolFee = _protocolFee;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

/// @title Ownable contract
/// @notice Manages the owner role
interface IOwnable {
    // Events

    /// @notice Emitted when pendingOwner accepts to be owner
    /// @param _owner Address of the new owner
    event OwnerSet(address _owner);

    /// @notice Emitted when a new owner is proposed
    /// @param _pendingOwner Address that is proposed to be the new owner
    event OwnerProposal(address _pendingOwner);

    // Errors

    /// @notice Throws if the caller of the function is not owner
    error OnlyOwner();

    /// @notice Throws if the caller of the function is not pendingOwner
    error OnlyPendingOwner();

    /// @notice Throws if trying to set owner to zero address
    error NoOwnerZeroAddress();

    // Variables

    /// @notice Stores the owner address
    /// @return _owner The owner addresss
    function owner() external view returns (address _owner);

    /// @notice Stores the pendingOwner address
    /// @return _pendingOwner The pendingOwner addresss
    function pendingOwner() external view returns (address _pendingOwner);

    // Methods

    /// @notice Proposes a new address to be owner
    /// @param _owner The address being proposed as the new owner
    function setOwner(address _owner) external;

    /// @notice Changes the owner from the current owner to the previously proposed address
    function acceptOwner() external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import '../interfaces/IOwnable.sol';

abstract contract Ownable is IOwnable {
    /// @inheritdoc IOwnable
    address public override owner;

    /// @inheritdoc IOwnable
    address public override pendingOwner;

    constructor(address _owner) {
        if (_owner == address(0)) revert NoOwnerZeroAddress();
        owner = _owner;
    }

    /// @inheritdoc IOwnable
    function setOwner(address _owner) external override onlyOwner {
        pendingOwner = _owner;
        emit OwnerProposal(_owner);
    }

    /// @inheritdoc IOwnable
    function acceptOwner() external override onlyPendingOwner {
        owner = pendingOwner;
        delete pendingOwner;
        emit OwnerSet(owner);
    }

    /// @notice Functions with this modifier can only be called by owner
    modifier onlyOwner() {
        if (msg.sender != owner) revert OnlyOwner();
        _;
    }

    /// @notice Functions with this modifier can only be called by pendingOwner
    modifier onlyPendingOwner() {
        if (msg.sender != pendingOwner) revert OnlyPendingOwner();
        _;
    }
}