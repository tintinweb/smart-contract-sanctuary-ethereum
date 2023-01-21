/**
 *Submitted for verification at Etherscan.io on 2023-01-21
*/

// Sources flattened with hardhat v2.9.1 https://hardhat.org

// File contracts/uniswapv2/interfaces/IMegafiswapV2Pair.sol

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

interface IMegafiswapV2Pair {
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


// File contracts/uniswapv2/libraries/SafeMath.sol


pragma solidity =0.6.12;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMathMegafiswap {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
}


// File contracts/uniswapv2/libraries/MegafiswapV2Library.sol


pragma solidity >=0.5.0;

library MegafiswapV2Library {
    using SafeMathMegafiswap for uint;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'MegafiswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'MegafiswapV2Library: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'f1291f720800a71184837892667771f3dbb8f98c5e3bc079f0da9e0ae5ce02c6' // init code hash
            ))));
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IMegafiswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'MegafiswapV2Library: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'MegafiswapV2Library: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'MegafiswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'MegafiswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'MegafiswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'MegafiswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(1000);
        uint denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'MegafiswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'MegafiswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}


// File contracts/uniswapv2/libraries/TransferHelper.sol


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


// File contracts/uniswapv2/interfaces/IMegafiswapV2Router01.sol


pragma solidity >=0.6.2;

interface IMegafiswapV2Router01 {
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


// File contracts/uniswapv2/interfaces/IMegafiswapV2Router02.sol


pragma solidity >=0.6.2;

interface IMegafiswapV2Router02 is IMegafiswapV2Router01 {
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


// File contracts/uniswapv2/interfaces/IMegafiswapV2Factory.sol


pragma solidity >=0.5.0;

interface IMegafiswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function migrator() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
    function setMigrator(address) external;
}


// File contracts/uniswapv2/interfaces/IERC20.sol


pragma solidity >=0.5.0;

interface IERC20Megafiswap {
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


// File contracts/uniswapv2/interfaces/IWETH.sol


pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}


// File @openzeppelin/contracts/utils/[email protected]


pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


// File @openzeppelin/contracts/access/[email protected]


pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


// File contracts/uniswapv2/MegafiAggregator.sol


pragma solidity =0.6.12;








contract MegafiAggregator is Ownable{

    IMegafiswapV2Router02 public immutable router;
    IMegafiswapV2Factory public immutable factory;

    IMegafiswapV2Router02 public immutable megaRouter;
    IMegafiswapV2Factory public immutable megaFactory;

    address public immutable weth;

    bool public paused;

    event Pause();
    event UnPaused();

    modifier ifNotPaused(){
        require(paused == false, "Paused");
        _;
    }

    constructor( address _router, address _megaFiRouter) public {
        router = IMegafiswapV2Router02(_router);
        megaRouter = IMegafiswapV2Router02(_megaFiRouter);

        factory = IMegafiswapV2Factory(IMegafiswapV2Router02(_router).factory());
        megaFactory = IMegafiswapV2Factory(IMegafiswapV2Router02(_megaFiRouter).factory());

        weth = IMegafiswapV2Router02(_megaFiRouter).WETH() ;
    }

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external ifNotPaused {
        require((amountADesired > 0) && (amountBDesired>0) ,"Zero amount");
        require((tokenA != address(0x00)) && (tokenB != address(0x00)), "Invalid tokens address");

        TransferHelper.safeTransferFrom(tokenA, msg.sender, address(this), amountADesired);
        TransferHelper.safeTransferFrom(tokenB, msg.sender, address(this), amountBDesired);

        if (IMegafiswapV2Factory(megaFactory).getPair(tokenA, tokenB) != address(0)) {
            _approve(tokenA, address(megaRouter), amountADesired);
            _approve(tokenB, address(megaRouter), amountBDesired);
            megaRouter.addLiquidity(tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin, to, deadline);
        } else if (IMegafiswapV2Factory(factory).getPair(tokenA, tokenB) != address(0)) {
            _approve(tokenA, address(router), amountADesired);
            _approve(tokenB, address(router), amountBDesired);
            router.addLiquidity(tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin, to, deadline);
        } else {
            _approve(tokenA, address(megaRouter), amountADesired);
            _approve(tokenB, address(megaRouter), amountBDesired);
            megaRouter.addLiquidity(tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin, to, deadline);
        }
        
        _transferToken(tokenA, IERC20Megafiswap(tokenA).balanceOf(address(this)));
        _transferToken(tokenB, IERC20Megafiswap(tokenB).balanceOf(address(this)));
    }

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable ifNotPaused {
        require((amountTokenDesired > 0) && (msg.value > 0) ,"Zero amount");
        require((token != address(0x00)), "Invalid token address");
        
        TransferHelper.safeTransferFrom(token, msg.sender, address(this), amountTokenDesired);

        if (IMegafiswapV2Factory(megaFactory).getPair(token, weth) != address(0)) {
            _approve(token, address(megaRouter), amountTokenDesired);
            megaRouter.addLiquidityETH{value: msg.value}(token, amountTokenDesired, amountTokenMin, amountETHMin, to, deadline);
        } else if (IMegafiswapV2Factory(factory).getPair(token, weth) != address(0)) {
            _approve(token, address(router), amountTokenDesired);
            router.addLiquidityETH{value: msg.value}(token, amountTokenDesired, amountTokenMin, amountETHMin, to, deadline);
        } else {
            _approve(token, address(megaRouter), amountTokenDesired);
            megaRouter.addLiquidityETH{value: msg.value}(token, amountTokenDesired, amountTokenMin, amountETHMin, to, deadline);
        }
        _transferToken(token, IERC20Megafiswap(token).balanceOf(address(this)));
        _transfer(address(this).balance);
    }

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external ifNotPaused {
        require((liquidity > 0) ,"Zero liquidity amount");
        require((tokenA != address(0x00)) && (tokenB != address(0x00)), "Invalid tokens address");
        address pair; 

        if (IMegafiswapV2Factory(megaFactory).getPair(tokenA, tokenB) != address(0)) {
            pair = IMegafiswapV2Factory(megaFactory).getPair(tokenA, tokenB);
            TransferHelper.safeTransferFrom(pair, msg.sender, address(this), liquidity);

            _approve(pair, address(megaRouter), liquidity);        
            megaRouter.removeLiquidity(tokenA, tokenB, liquidity, amountAMin, amountBMin, to, deadline);
        } else if (IMegafiswapV2Factory(factory).getPair(tokenA, tokenB) != address(0)) {
            pair = IMegafiswapV2Factory(factory).getPair(tokenA, tokenB);
            TransferHelper.safeTransferFrom(pair, msg.sender, address(this), liquidity);

            _approve(pair, address(router), liquidity);
            router.removeLiquidity(tokenA, tokenB, liquidity, amountAMin, amountBMin, to, deadline);
        } 
    }

    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external ifNotPaused {
        require((liquidity > 0), "Zero liquidity amount");
        require((token != address(0x00)), "Invalid tokens address");
        address pair; 

        if (IMegafiswapV2Factory(megaFactory).getPair(token, weth) != address(0)) {
            pair = IMegafiswapV2Factory(megaFactory).getPair(token, weth);
            TransferHelper.safeTransferFrom(pair, msg.sender, address(this), liquidity);

            _approve(pair, address(megaRouter), liquidity);        
            megaRouter.removeLiquidityETH(token, liquidity, amountTokenMin, amountETHMin, to, deadline);
        } else if (IMegafiswapV2Factory(factory).getPair(token, weth) != address(0)) {
            pair = IMegafiswapV2Factory(factory).getPair(token, weth);
            TransferHelper.safeTransferFrom(pair, msg.sender, address(this), liquidity);
            _approve(pair, address(router), liquidity);
            router.removeLiquidityETH(token, liquidity, amountTokenMin, amountETHMin, to, deadline);
        } 
    }

    // swap 

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external ifNotPaused {
        
        TransferHelper.safeTransferFrom(path[0], msg.sender, address(this), amountIn);

        if (IMegafiswapV2Factory(megaFactory).getPair(path[0], path[1]) != address(0)) {
            _approve(path[0], address(megaRouter), amountIn);        
            megaRouter.swapExactTokensForTokens(amountIn, amountOutMin, path, to, deadline);
        } else if (IMegafiswapV2Factory(factory).getPair(path[0], path[1]) != address(0)) {
            _approve(path[0], address(router), amountIn);        
            router.swapExactTokensForTokens(amountIn, amountOutMin, path, to, deadline);
        }
        _transferToken(path[0], IERC20Megafiswap(path[0]).balanceOf(address(this)));

    }

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external ifNotPaused {
        TransferHelper.safeTransferFrom(path[0], msg.sender, address(this), amountInMax);
    
        if (IMegafiswapV2Factory(megaFactory).getPair(path[0], path[1]) != address(0)) {
            _approve(path[0], address(megaRouter), amountInMax);        
            megaRouter.swapTokensForExactTokens(amountOut, amountInMax, path, to, deadline);
        } else if (IMegafiswapV2Factory(factory).getPair(path[0], path[1]) != address(0)) {
            _approve(path[0], address(router), amountInMax);        
            router.swapTokensForExactTokens(amountOut, amountInMax, path, to, deadline);
        }
        _transferToken(path[0], IERC20Megafiswap(path[0]).balanceOf(address(this)));

    }

    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        ifNotPaused
    {
        if (IMegafiswapV2Factory(megaFactory).getPair(path[0], path[1]) != address(0)) {
            megaRouter.swapExactETHForTokens{value: msg.value}(amountOutMin, path, to, deadline);
        } else if (IMegafiswapV2Factory(factory).getPair(path[0], path[1]) != address(0)) {
            router.swapExactETHForTokens{value: msg.value}(amountOutMin, path, to, deadline);
        }
    }

    function swapTokensForExactETH(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external ifNotPaused {
       TransferHelper.safeTransferFrom(path[0], msg.sender, address(this), amountInMax);
    
        if (IMegafiswapV2Factory(megaFactory).getPair(path[0], path[1]) != address(0)) {
            _approve(path[0], address(megaRouter), amountInMax);        
            megaRouter.swapTokensForExactETH(amountOut, amountInMax, path, to, deadline);
        } else if (IMegafiswapV2Factory(factory).getPair(path[0], path[1]) != address(0)) {
            _approve(path[0], address(router), amountInMax);        
            router.swapTokensForExactETH(amountOut, amountInMax, path, to, deadline);
        }
        _transferToken(path[0], IERC20Megafiswap(path[0]).balanceOf(address(this)));
    }

    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) 
        external 
        ifNotPaused
    {
        TransferHelper.safeTransferFrom(path[0], msg.sender, address(this), amountIn);
    
        if (IMegafiswapV2Factory(megaFactory).getPair(path[0], path[1]) != address(0)) {
            _approve(path[0], address(megaRouter), amountIn);        
            megaRouter.swapExactTokensForETH(amountIn, amountOutMin, path, to, deadline);
        } else if (IMegafiswapV2Factory(factory).getPair(path[0], path[1]) != address(0)) {
            _approve(path[0], address(router), amountIn);        
            router.swapExactTokensForETH(amountIn, amountOutMin, path, to, deadline);
        }
        _transferToken(path[0], IERC20Megafiswap(path[0]).balanceOf(address(this)));
    }

    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        ifNotPaused
    {
        if (IMegafiswapV2Factory(megaFactory).getPair(path[0], path[1]) != address(0)) {
            megaRouter.swapExactETHForTokens{value: msg.value}(amountOut, path, to, deadline);
        } else if (IMegafiswapV2Factory(factory).getPair(path[0], path[1]) != address(0)) {
            router.swapExactETHForTokens{value: msg.value}(amountOut, path, to, deadline);
        }
    }

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external ifNotPaused {
        TransferHelper.safeTransferFrom(path[0], msg.sender, address(this), amountIn);

        if (IMegafiswapV2Factory(megaFactory).getPair(path[0], path[1]) != address(0)) {
            _approve(path[0], address(megaRouter), amountIn);        
            megaRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(amountIn, amountOutMin, path, to, deadline);
        } else if (IMegafiswapV2Factory(factory).getPair(path[0], path[1]) != address(0)) {
            _approve(path[0], address(router), amountIn);        
            router.swapExactTokensForTokensSupportingFeeOnTransferTokens(amountIn, amountOutMin, path, to, deadline);
        }
        _transferToken(path[0], IERC20Megafiswap(path[0]).balanceOf(address(this)));
    }

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    )
        external
        payable
        ifNotPaused
    {
       if (IMegafiswapV2Factory(megaFactory).getPair(path[0], path[1]) != address(0)) {
            megaRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(amountOutMin, path, to, deadline);
        } else if (IMegafiswapV2Factory(factory).getPair(path[0], path[1]) != address(0)) {
            router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(amountOutMin, path, to, deadline);
        }
    }

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    )
        external
        ifNotPaused
    {
        TransferHelper.safeTransferFrom(path[0], msg.sender, address(this), amountIn);

        if (IMegafiswapV2Factory(megaFactory).getPair(path[0], path[1]) != address(0)) {
            _approve(path[0], address(megaRouter), amountIn);        
            megaRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(amountIn, amountOutMin, path, to, deadline);
        } else if (IMegafiswapV2Factory(factory).getPair(path[0], path[1]) != address(0)) {
            _approve(path[0], address(router), amountIn);        
            router.swapExactTokensForETHSupportingFeeOnTransferTokens(amountIn, amountOutMin, path, to, deadline);
        }
        _transferToken(path[0], IERC20Megafiswap(path[0]).balanceOf(address(this)));
    }

    // internal/ private functions
    function _approve(address _token, address _receiver, uint amount) private {
        if(amount <= IERC20Megafiswap(_token).allowance(address(this), _receiver)) {
            TransferHelper.safeApprove(_token, _receiver, type(uint160).max);
        }
    }

    function _transferToken(address _token, uint _amount) private {
        if(_amount > 0){
            TransferHelper.safeTransfer(_token, msg.sender, _amount);
        }
    }

    function _transfer(uint256 _value) private {
        if(_value > 0){
            (msg.sender).transfer(_value);
        }
    }

    // view functions

    function getAmountsOut(uint amountIn, address[] memory path)
        public
        view
        returns (uint[] memory amounts)
    {

        if (IMegafiswapV2Factory(megaFactory).getPair(path[0], path[1]) != address(0)) {
           amounts = megaRouter.getAmountsOut(amountIn, path);
        } else if (IMegafiswapV2Factory(factory).getPair(path[0], path[1]) != address(0)) {
           amounts = router.getAmountsOut(amountIn, path);
        }        
        return amounts;
    }

    function getAmountsIn(uint amountOut, address[] memory path)
        public
        view
        returns (uint[] memory amounts)
    {

        if (IMegafiswapV2Factory(megaFactory).getPair(path[0], path[1]) != address(0)) {
           amounts = megaRouter.getAmountsIn(amountOut, path);
        } else if (IMegafiswapV2Factory(factory).getPair(path[0], path[1]) != address(0)) {
           amounts = router.getAmountsIn(amountOut, path);
        }
        return amounts;
    }

    function pause() external onlyOwner{
        paused = true;
        emit Pause();
    }

    function unPause() external onlyOwner{
        paused = false;
        emit UnPaused();
    }

    function getPair(address token0, address token1) external view returns(address pair){
        if(IMegafiswapV2Factory(megaFactory).getPair(token0, token1) != address(0x000)){
            pair = IMegafiswapV2Factory(megaFactory).getPair(token0, token1);
        }else {
            pair = IMegafiswapV2Factory(factory).getPair(token0, token1);
        }
    }

}