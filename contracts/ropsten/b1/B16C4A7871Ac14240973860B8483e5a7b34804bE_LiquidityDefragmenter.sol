/**
 *Submitted for verification at Etherscan.io on 2022-03-31
*/

// File @uniswap/v2-core/contracts/interfaces/[email protected]

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
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

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}


// File @uniswap/v2-core/contracts/interfaces/[email protected]

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}


// File @uniswap/v2-periphery/contracts/interfaces/[email protected]

pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}


// File @uniswap/lib/contracts/libraries/[email protected]

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


// File @openzeppelin/contracts/token/ERC20/extensions/[email protected]

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


// File contracts/amm/LiquidityDefragmenter.sol
pragma solidity >=0.8.0;

//  ██████╗ ███████╗███╗   ███╗███████╗██╗    ██╗ █████╗ ██████╗
// ██╔════╝ ██╔════╝████╗ ████║██╔════╝██║    ██║██╔══██╗██╔══██╗
// ██║  ███╗█████╗  ██╔████╔██║███████╗██║ █╗ ██║███████║██████╔╝
// ██║   ██║██╔══╝  ██║╚██╔╝██║╚════██║██║███╗██║██╔══██║██╔═══╝
// ╚██████╔╝███████╗██║ ╚═╝ ██║███████║╚███╔███╔╝██║  ██║██║
//  ╚═════╝ ╚══════╝╚═╝     ╚═╝╚══════╝ ╚══╝╚══╝ ╚═╝  ╚═╝╚═╝
interface IERC20PermitAllowed {
    function permit(
        address holder,
        address spender,
        uint256 nonce,
        uint256 expiry,
        bool allowed,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

contract LiquidityDefragmenter {

    address public immutable WETH;
    constructor(address _WETH) { WETH = _WETH; }

    /* -------------------------------------------------------------------------- */
    /*                                 SWAP LOGIC                                 */
    /* -------------------------------------------------------------------------- */

    // requires the initial amount to have already been sent to the first pair
    function _swap(
        uint256[] memory amounts,
        address[] memory path,
        address[] memory factories,
        address _to
    ) internal virtual returns (uint256 amountOut) {
        // Math will not reasonably overflow & was orginally unchecked
        unchecked {
            // Cache path.length before use in for loop to save gas
            uint256 length = path.length;
            // Execute swaps
            for (uint256 i; i < length - 1; ++i) {
                // Cache input and output token for this paticular swap
                (address input, address output) = (path[i], path[i + 1]);
                // Sort tokens, and calculate amount out for token0 and token1
                (address token0,) = sortTokens(input, output);
                (uint256 amount0Out, uint256 amount1Out) = input == token0 ? (uint256(0), amounts[i + 1]) : (amounts[i + 1], uint256(0));
                // Determine whether we need to send funds to next pair (for next trade), or back to trader (_to)
                address to = i < length - 2 ? IUniswapV2Factory(factories[i + 1]).getPair(output, path[i + 2]) : _to;
                // Swap input for output tokens, and sent funds to address determined above
                IUniswapV2Pair(IUniswapV2Factory(factories[i]).getPair(input, output)).swap(amount0Out, amount1Out, to, new bytes(0));
            }
            // Return final output amount
            return amounts[amounts.length - 1];
        }
    }

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address[] calldata factories,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts) {
        // Ensure that deadline has not elapsed
        require(deadline >= block.timestamp, "EXPIRED");
        // Ensure that first/input token is WETH
        require(path[0] == WETH, "INVALID_PATH");
        // Calculate amounts out for trade
        amounts = getAmountsOut(msg.value, factories, path);
        // Wrap raw ETH into WETH before swaping
        IWETH(WETH).deposit{value: amounts[0]}();
        // Transfer WETH amount to the first pair
        assert(IWETH(WETH).transfer(IUniswapV2Factory(factories[0]).getPair(path[0], path[1]), amounts[0]));
        // Ensure that output amount is greater than or equal to "minAmountOut"
        require(_swap(amounts, path, factories, to) >= amountOutMin, "!OUTPUT");
    }

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address[] calldata factories,
        address to,
        uint256 deadline
    ) public returns (uint256[] memory amounts) {
        // Ensure that deadline has not elapsed
        require(deadline >= block.timestamp, "EXPIRED");
        // Optimistically calculate swap amounts
        amounts = getAmountsOut(amountIn, factories, path);
        // Transfer input token amount from caller to the first pair
        TransferHelper.safeTransferFrom(
            path[0],
            msg.sender,
            IUniswapV2Factory(factories[0]).getPair(path[0], path[1]),
            amounts[0]
        );
        // Ensure that output amount is greater than or equal to "minAmountOut"
        require(_swap(amounts, path, factories, to) >= amountOutMin, "!OUTPUT");
    }

    function swapExactTokensForTokensUsingPermit(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address[] calldata factories,
        address to,
        uint256 deadline, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint256[] memory amounts) {
        // Approve tokens for spender - https://eips.ethereum.org/EIPS/eip-2612
        IERC20Permit(path[0]).permit(msg.sender, address(this), amountIn, deadline, v, r, s);

        amounts = swapExactTokensForTokens(amountIn, amountOutMin, path, factories, to, deadline);
    }

    function swapExactTokensForTokensUsingPermitAllowed(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address[] calldata factories,
        address to,
        uint256 deadline, uint256 nonce, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint256[] memory amounts) {
        // Approve tokens for spender - https://eips.ethereum.org/EIPS/eip-2612
        IERC20PermitAllowed(path[0]).permit(msg.sender, address(this), nonce, deadline, true, v, r, s);

        amounts = swapExactTokensForTokens(amountIn, amountOutMin, path, factories, to, deadline);
    }

    /* -------------------------------------------------------------------------- */
    /*                            INTERNAL HELPER LOGIC                           */
    /* -------------------------------------------------------------------------- */

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(
        address tokenA,
        address tokenB
    ) internal pure returns (address token0, address token1) {
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), "ZERO_ADDRESS");
    }

    // performs chained getAmountOut calculations on any number of pairs + factories
    function getAmountsOut(
        uint256 amountIn,
        address[] calldata factories,
        address[] calldata path
    ) internal view returns (uint256[] memory amounts) {

        amounts = new uint256[](path.length);
        amounts[0] = amountIn;

        uint256 reserve0;
        uint256 reserve1;
        uint256 reserveIn;
        uint256 reserveOut;
        uint256 length = path.length - 1;

        for (uint256 i; i < length;) {

            // Unchecked because "i" cannot reasonably overflow
            unchecked {
                (address token0,) = sortTokens(path[i], path[i + 1]);
                (reserve0, reserve1,) = IUniswapV2Pair(IUniswapV2Factory(factories[i]).getPair(path[i], path[i + 1])).getReserves();
                (reserveIn, reserveOut) = path[i] == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
            }

            uint256 amountInWithFee = amountIn * 997;
            uint256 numerator = amountInWithFee * reserveOut;
            uint256 denominator = reserveIn * 1000 + amountInWithFee;

            // Unchecked because "i" cannot reasonably overflow & division was originally unchecked
            unchecked {
                amounts[i + 1] = numerator / denominator;
                ++i;
            }
        }
    }
}