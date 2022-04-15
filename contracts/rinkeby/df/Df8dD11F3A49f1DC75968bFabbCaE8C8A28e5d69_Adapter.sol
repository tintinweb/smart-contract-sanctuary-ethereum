// SPDX-License-Identifier: MIT

pragma solidity >= 0.8.12 <0.9.0;

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Adapter is Ownable {
    address public immutable ROUTER;
    address public immutable FACTORY;
    mapping(address => mapping(address => address)) public pairs;
    mapping(address => mapping(address => uint256)) public prices;

    constructor(address _router, address _factory) {
        ROUTER = _router;
        FACTORY = _factory;
    }

    /// @notice creates pair by calling Uniswap contract
    /// @dev adds two entries to mapping
    /// @param addr0 - token one
    /// @param addr1 - token two
    function createPair(address addr0, address addr1) external {
        address pairAddress = IUniswapV2Factory(FACTORY).createPair(addr0, addr1);

        if(pairAddress != address(0)) {
            pairs[addr0][addr1] = pairAddress;
            pairs[addr1][addr0] = pairAddress;
        } else {
            revert("Adapter: Failed to create pair");
        }
    }

    /// @notice adds liquidity by calling Uniswap contract https://docs.uniswap.org/protocol/V2/reference/smart-contracts/router-02#addliquidity
    /// @dev contract always sends to msg.sender with hardcoded deadline
    /// @param token0 - a pool token
    /// @param token1 - a pool token
    /// @param amount0D amount of tokenA to add as liquidity if the B/A price is <= amountBDesired/amountADesired (A depreciates)
    /// @param amount1D amount of tokenB to add as liquidity if the A/B price is <= amountADesired/amountBDesired (B depreciates)
    /// @param amount0M bounds the extent to which the B/A price can go up before the transaction reverts. Must be <= amountADesired
    /// @param amount1M bounds the extent to which the A/B price can go up before the transaction reverts. Must be <= amountBDesired
    function addLiquidity(address token0, address token1, uint amount0D, uint amount1D, uint amount0M, uint amount1M) external {
        (bool success,) = ROUTER.delegatecall(abi.encodeWithSignature(
            "addLiquidity(address,address,uint256,uint256,uint256,uint256,address,uint256)", 
            token0, token1, amount0D, amount1D, amount0M, amount1M, msg.sender, block.timestamp + 60)
        );

        require(success, "Adapter: Failed to add liquidity");
    }

    /// @notice adds liquidity by calling Uniswap contract https://docs.uniswap.org/protocol/V2/reference/smart-contracts/router-02#addliquidityeth
    /// @dev contract always sends to msg.sender with hardcoded deadline
    /// @param token - a pool token
    /// @param amountD amount of token to add as liquidity if the WETH/token price is <= msg.value/amountTokenDesired (token depreciates)
    /// @param amountM bounds the extent to which the WETH/token price can go up before the transaction reverts. Must be <= amountTokenDesired
    /// @param amountEM bounds the extent to which the token/WETH price can go up before the transaction reverts. Must be <= msg.value
    function addLiquidityETH(address token, uint amountD, uint amountM, uint amountEM) external payable {
        require(msg.value > 0, "Adapter: zero ETH value");
        
        (bool success,) = ROUTER.delegatecall(abi.encodeWithSignature(
            "addLiquidityETH(address,uint256,uint256,uint256,address,uint256)", 
            token, amountD, amountM, amountEM, msg.sender, block.timestamp + 60)
        );
        
        require(success, "Adapter: Failed to add liquidity eth");
    }


    /// @notice removes liquidity by calling Uniswap contract https://docs.uniswap.org/protocol/V2/reference/smart-contracts/router-02#removeliquidity
    /// @dev contract always sends to msg.sender with hardcoded deadline
    /// @param token0 - a pool token
    /// @param token1 - a pool token
    /// @param liquidity amount of liquidity tokens to remove
    /// @param amount0M minimum amount of tokenA that must be received for the transaction not to revert
    /// @param amount1M minimum amount of tokenB that must be received for the transaction not to revert
    function removeLiquidity(address token0, address token1, uint liquidity, uint amount0M, uint amount1M) external {
        (bool success, bytes memory data) = ROUTER.delegatecall(abi.encodeWithSignature(
            "removeLiquidity(address,address,uint256,uint256,uint256,address,uint256)", 
            token0, token1, liquidity, amount0M, amount1M, msg.sender, block.timestamp + 60)
        );
        
        require(success, "Adapter: Failed to remove liquidity");
    }

    /// @notice removes liquidity by calling Uniswap contract https://docs.uniswap.org/protocol/V2/reference/smart-contracts/router-02#removeliquidityeth
    /// @dev contract always sends to msg.sender with hardcoded deadline
    /// @param token - a pool token
    /// @param liquidity - amount of liquidity tokens to remove.
    /// @param amountM - minimum amount of token that must be received for the transaction not to revert
    /// @param amountEM - minimum amount of ETH that must be received for the transaction not to revert
    function removeLiquidityETH(address token, uint liquidity, uint amountM, uint amountEM) external {
        address weth = IUniswapV2Router02(ROUTER).WETH();
        address pair = pairs[token][weth];

        pair.call(abi.encodeWithSignature("transferFrom(address,address,uint256)", msg.sender, address(this), liquidity));
        pair.call(abi.encodeWithSignature("approve(address,uint256)", ROUTER, liquidity));

        (uint amountA, uint amountB) = IUniswapV2Router02(ROUTER).removeLiquidityETH(token, liquidity, amountM, amountEM, msg.sender, block.timestamp + 60);
    }

    /// @notice polls Uniswap for how much tokenB is one tokenA worth
    /// @dev only records current price, to get it use pairs mapping
    /// @param tokenA - first token
    /// @param tokenB - second token
    function updatePairPrice(address tokenA, address tokenB) external {
        require(tokenA != address(0) && tokenB != address(0), "Adapter: Incorrect address");

        address[] memory addresses = new address[](2);
        addresses[0] = tokenA;
        addresses[1] = tokenB;
        (uint256[] memory amounts) = IUniswapV2Router02(ROUTER).getAmountsOut(10**18, addresses);
        prices[tokenA][tokenB] = amounts[1];
    }

    /// @notice swaps one token for another by calling Uniswap contract https://docs.uniswap.org/protocol/V2/reference/smart-contracts/router-02#swapexacttokensfortokens
    /// @dev contract always sends to msg.sender with hardcoded deadline
    /// @param token0 - a pool token
    /// @param token1 - a pool token
    /// @param amountIn - amount of input tokens to send
    /// @param amountOutMin - minimum amount of output tokens that must be received for the transaction not to revert
    function makeDirectSwap(address token0, address token1, uint amountIn, uint amountOutMin) external {
        address pair = pairs[token0][token1];
        require(pair != address(0), "Adapter: Unknown pair");

        token0.call(abi.encodeWithSignature("transferFrom(address,address,uint256)", msg.sender, address(this), amountIn));
        token0.call(abi.encodeWithSignature("approve(address,uint256)", ROUTER, amountIn));

        address[] memory addresses = new address[](2);
        addresses[0] = token0;
        addresses[1] = token1;

        IUniswapV2Router02(ROUTER).swapExactTokensForTokens(amountIn, amountOutMin, addresses, msg.sender, block.timestamp + 60);
    }

    /// @notice swaps one token for another by calling Uniswap contract https://docs.uniswap.org/protocol/V2/reference/smart-contracts/router-02#swapexacttokensfortokens
    /// @dev contract always sends to msg.sender with hardcoded deadline
    /// @param tokens - multiple tokens that make up path
    /// @param amountIn - amount of input tokens to send
    /// @param amountOutMin - minimum amount of output tokens that must be received for the transaction not to revert
    function makePathSwap(address[] memory tokens, uint amountIn, uint amountOutMin) external {
        tokens[0].call(abi.encodeWithSignature("transferFrom(address,address,uint256)", msg.sender, address(this), amountIn));
        tokens[0].call(abi.encodeWithSignature("approve(address,uint256)", ROUTER, amountIn));

        address[] memory addresses = new address[](tokens.length);

        for (uint256 i = 0; i < tokens.length; i++) {
            addresses[i] = tokens[i];
        }

        IUniswapV2Router02(ROUTER).swapExactTokensForTokens(amountIn, amountOutMin, addresses, msg.sender, block.timestamp + 60);
    }
}

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