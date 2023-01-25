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

    function _callAndParseUint24Return(address token, bytes4 selector)
        internal
        view
        returns (uint24)
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
            return abi.decode(data, (uint24));
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
    // Test data (Goerli)
    // UniswapV2Pair: 0x2220806590A1101f8a74eFa1252aA440DA0D84ce, 0xD1FfB61B8896da8a4470ad25F2856da7e27eB5B5
    // LBSKR: 0x47814167dDd2A37c93dFF8aE3CB0f32b2b119d50
    // BSKR: 0xeb0835aB57b8cd712d0c2e1f0f40D61Bca390Be4
    // UniswapV2Router02: 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
    // UniswapV2Factory: 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f
    // WETH: 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6
    // UniswapV3Pool: 0x1fF8277B2cC1cAB7927E756D2A2F6d0fD11df83f, 0x40bf7A55A0De1Bbb9A88E18558F124728F6FFb71, 0xFfB71B832e1757c2FA02C16184B8B26221AA3678
    // SwapRouter: 0xE592427A0AEce92De3Edee1F18E0157C05861564
    // UniswapV3Factory: 0x1F98431c8aD98523631AE4a59f267346ea31F984
    // SwapRouter02: 0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45
    // NonfungiblePositionManager: 0xC36442b4a4522E871399CD717aBDD847Ab11FE88

    constructor() {}

    function isPairPool(address target)
        external
        view
        returns (bool isPair, bool isV3Pool)
    {
        address token0 = _getToken0(target);
        if (token0 == address(0)) {
            return (false, false);
        }

        address token1 = _getToken1(target);
        if (token1 == address(0)) {
            return (false, false);
        }

        uint24 fee = _getFee(target);

        if (fee == 0) {
            return (true, false);
        } else {
            return (true, true);
        }
    }

    function _getFee(address target) internal view returns (uint24 targetFee) {
        targetFee = _callAndParseUint24Return(
            target,
            hex"ddca3f43" // fee()
        );

        return targetFee;
    }

    function _getToken0(address target)
        internal
        view
        returns (address targetToken0)
    {
        targetToken0 = _callAndParseAddressReturn(
            target,
            hex"0dfe1681" // token0()
        );

        return targetToken0;
    }

    function _getToken1(address target)
        internal
        view
        returns (address targetToken1)
    {
        targetToken1 = _callAndParseAddressReturn(
            target,
            hex"d21220a7" // token1()
        );

        return targetToken1;
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