/*
 * SPDX-License-Identifier: MIT
 */
pragma solidity ^0.8.17;

contract Utils {
    function _bytes32ToString(bytes32 x) internal pure returns (string memory) {
        bytes memory bytesString = new bytes(32);
        uint256 charCount = 0;
        for (uint256 j = 0; j < 32; j++) {
            bytes1 char = x[j];
            if (char != 0) {
                bytesString[charCount] = char;
                charCount++;
            }
        }
        bytes memory bytesStringTrimmed = new bytes(charCount);
        for (uint256 j = 0; j < charCount; j++) {
            bytesStringTrimmed[j] = bytesString[j];
        }
        return string(bytesStringTrimmed);
    }

    function _callAndParseInt24Return(address token, bytes4 selector)
        internal
        view
        returns (int24)
    {
        (bool success, bytes memory data) = token.staticcall(
            abi.encodeWithSelector(selector)
        );

        // if not implemented, or returns empty data, return empty string
        if (!success || data.length == 0) {
            return 0;
        }

        // if implemented, or returns data, return decoded int24 else return 0
        if (data.length == 32) {
            return abi.decode(data, (int24));
        }

        return 0;
    }

    function _callAndParseStringReturn(address token, bytes4 selector)
        internal
        view
        returns (string memory)
    {
        (bool success, bytes memory data) = token.staticcall(
            abi.encodeWithSelector(selector)
        );

        // if not implemented, or returns empty data, return empty string
        if (!success || data.length == 0) {
            return "";
        }

        // bytes32 data always has length 32
        if (data.length == 32) {
            bytes32 decoded = abi.decode(data, (bytes32));
            return _bytes32ToString(decoded);
        } else if (data.length > 64) {
            return abi.decode(data, (string));
        }
        return "";
    }

    function _compare(string memory str1, string memory str2)
        internal
        pure
        returns (bool)
    {
        if (bytes(str1).length != bytes(str2).length) {
            return false;
        }
        return
            keccak256(abi.encodePacked(str1)) ==
            keccak256(abi.encodePacked(str2));
    }
}

/*
 * SPDX-License-Identifier: MIT
 */

pragma solidity ^0.8.17;

import "./lib/Utils.sol";
import "./uniswap/v2-core/interfaces/IUniswapV2Factory.sol";
import "./uniswap/v2-core/interfaces/IUniswapV2Pair.sol";
import "./uniswap/v2-periphery/interfaces/IUniswapV2Router02.sol";
import "./uniswap/v3-core/interfaces/IUniswapV3Factory.sol";
import "./uniswap/v3-core/interfaces/IUniswapV3Pool.sol";

contract TestContract is Utils {
    address private constant _DEXV2_ROUTER_ADDR =
        0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; // UniswapV2Router02
    address private constant _DEXV3_FACTORY_ADDR =
        0x1F98431c8aD98523631AE4a59f267346ea31F984; // UniswapV3Factory
    address private constant _DEXV3_ROUTER_ADDR =
        0xE592427A0AEce92De3Edee1F18E0157C05861564; // SwapRouter
    address private constant _NFPOSMAN_ADDR =
        0xC36442b4a4522E871399CD717aBDD847Ab11FE88; // NonfungiblePositionManager

    IUniswapV2Factory internal immutable _dexFactoryV2;
    IUniswapV2Router02 internal immutable _dexRouterV2;
    IUniswapV3Factory internal immutable _dexFactoryV3;

    constructor() {
        _dexRouterV2 = IUniswapV2Router02(_DEXV2_ROUTER_ADDR);
        _dexFactoryV2 = IUniswapV2Factory(_dexRouterV2.factory());
        _dexFactoryV3 = IUniswapV3Factory(_DEXV3_FACTORY_ADDR);
    }

    // common function between v2pair and v3pool contracts
    // factory() - read
    // token0() - read
    // token1() - read
    // burn() - write
    // mint() - write
    // swap() - write

    // hex"0dfe1681" // token0() returns address
    // hex"c45a0155" // factory() returns address
    // hex"d21220a7" // token1() returns address
    function hasFactoryFunction(address target) internal view returns (string memory) {
        string memory targetSymbol = _callAndParseStringReturn(
            target,
            hex"c45a0155" // factory()
        );

        if (bytes(targetSymbol).length == 0) {
            return "No factory function";
        }

        return "Has factory function";
    }

    function hasToken0Function(address target) internal view returns (string memory) {
        string memory targetSymbol = _callAndParseStringReturn(
            target,
            hex"0dfe1681" // token0()
        );

        if (bytes(targetSymbol).length == 0) {
            return "No token0 function";
        }

        return "Has token0 function";
    }

    function hasToken1Function(address target) internal view returns (string memory) {
        string memory targetSymbol = _callAndParseStringReturn(
            target,
            hex"d21220a7" // token1()
        );

        if (bytes(targetSymbol).length == 0) {
            return "No token1 function";
        }

        return "Has token1 function";
    }

     function _callAndParseAddressReturn(address token, bytes4 selector)
        internal
        view
        returns (address)
    {
        (bool success, bytes memory data) = token.staticcall(
            abi.encodeWithSelector(selector)
        );

        // if not implemented, or returns empty data, return empty string
        if (!success || data.length == 0) {
            return address(0);
        }

        // if implemented, or returns data, return decoded int24 else return 0
        if (data.length == 32) {
            return abi.decode(data, (address));
        }

        return address(0);
    }

}

/*
 * SPDX-License-Identifier: MIT
 */
 
pragma solidity ^0.8.17;

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function allPairsLength() external view returns (uint);
    function allPairs(uint) external view returns (address pair);
}

/*
 * SPDX-License-Identifier: MIT
 */
 
pragma solidity ^0.8.17;

interface IUniswapV2Pair {
    function token0() external view returns (address);
    function token1() external view returns (address);
}

/*
 * SPDX-License-Identifier: MIT
 */
 
pragma solidity ^0.8.17;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

/*
 * SPDX-License-Identifier: MIT
 */
 
pragma solidity ^0.8.17;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.17;

/// @title The interface for the Uniswap V3 Factory
/// @notice The Uniswap V3 Factory facilitates creation of Uniswap V3 pools and control over the protocol fees
interface IUniswapV3Factory {
    /// @notice Returns the pool address for a given pair of tokens and a fee, or address 0 if it does not exist
    /// @dev tokenA and tokenB may be passed in either token0/token1 or token1/token0 order
    /// @param tokenA The contract address of either token0 or token1
    /// @param tokenB The contract address of the other token
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @return pool The pool address
    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view returns (address pool);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.17;

import './pool/IUniswapV3PoolImmutables.sol';

/// @title The interface for a Uniswap V3 Pool
/// @notice A Uniswap pool facilitates swapping and automated market making between any two assets that strictly conform
/// to the ERC20 specification
/// @dev The pool interface is broken up into many smaller pieces
interface IUniswapV3Pool is
    IUniswapV3PoolImmutables
{

}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.17;

/// @title Pool state that never changes
/// @notice These parameters are fixed for a pool forever, i.e., the methods will always return the same values
interface IUniswapV3PoolImmutables {
    /// @notice The first of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token0() external view returns (address);

    /// @notice The second of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token1() external view returns (address);

    /// @notice The pool's fee in hundredths of a bip, i.e. 1e-6
    /// @return The fee
    function fee() external view returns (uint24);
}