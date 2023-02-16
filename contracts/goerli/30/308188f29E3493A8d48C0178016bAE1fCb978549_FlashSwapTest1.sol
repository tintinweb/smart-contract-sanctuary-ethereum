// SPDX-License-Identifier: MIT
pragma solidity =0.6.6;

import "@uniswap/v2-periphery/contracts/libraries/UniswapV2Library.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Callee.sol"; // uniswap will call uniswapV2Call function when we execute the flash swap 
import "@uniswap/v2-core/contracts/interfaces/IERC20.sol";
import "@uniswap/lib/contracts/libraries/TransferHelper.sol";

// flash swap contract
contract FlashSwapTest1 is IUniswapV2Callee {

    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    using SafeMath for uint256;

    address private constant ALE_TOKEN = 0x4908deb870fCc7f4E3071e44e7C9692794a223F4;
    address private constant MAT_TOKEN = 0x73435274BaAaAE2ceB3580CB0d194BEC249b8453;

    address private constant UniswapV2Factory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address private constant UNISWAP_V2_ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    IUniswapV2Router02 private uni_router = IUniswapV2Router02(UNISWAP_V2_ROUTER);

    address public constant SushiswapV2Factory = 0xc35DADB65012eC5796536bD9864eD8773aBc74C4;
    address public constant SUSHISWAP_V2_ROUTER = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506;
    IUniswapV2Router02 private sushi_router = IUniswapV2Router02(SUSHISWAP_V2_ROUTER);

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'UniswapV2Router: EXPIRED');
        _;
    }

    // calculates the CREATE2 address for a Sushiswap pair without making any external calls
    function pairForSushiswap(address factory, address tokenA, address tokenB) public pure returns (address pair) {
        (address token0, address token1) = UniswapV2Library.sortTokens(tokenA, tokenB);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'e18a34eb0e04b04f7a0ac29a6e80748dca96319b42c54d679cb821dca90c6303' // init code hash
            ))));
    }

    // **** SWAP ****
    // requires the initial amount to have already been sent to the first pair
    //_swap original function from UniswapV2Router02.sol
    function _sushi_swap(uint[] memory amounts, address[] memory path, address _to) public {
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = UniswapV2Library.sortTokens(input, output);
            uint amountOut = amounts[i + 1];
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOut) : (amountOut, uint(0));
            address to = i < path.length - 2 ? pairForSushiswap(SushiswapV2Factory, output, path[i + 2]) : _to;
            IUniswapV2Pair(pairForSushiswap(SushiswapV2Factory, input, output)).swap(
                amount0Out, amount1Out, to, new bytes(0)
            );
        }
    }

    // fetches and sorts the reserves for a pair
    function _getReserves(address factory, address tokenA, address tokenB) public view returns (uint reserveA, uint reserveB) {
        (address token0,) = UniswapV2Library.sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(pairForSushiswap(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function _getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) public pure returns (uint amountOut) {
        require(amountIn > 0, "My_UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "My_UniswapV2Library: INSUFFICIENT_LIQUIDITY");
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // performs chained getAmountOut calculations on any number of pairs
    function _getAmountsOut(address factory, uint amountIn, address[] memory path) public view returns (uint[] memory amounts) {
        require(path.length >= 2, "My_UniswapV2Library: INVALID_PATH");
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = _getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = _getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    //Swaps an exact amount of input tokens for as many output tokens as possible on SUSHISWAP
    function _swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] memory path,
        address to, //Recipient of the output tokens.
        uint deadline
    ) public ensure(deadline) returns (uint[] memory amounts) {
        amounts = _getAmountsOut(SushiswapV2Factory, amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, "My_UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT");
        TransferHelper.safeTransferFrom(
            path[0], // token
            msg.sender, // from (msg.sender era l'originale)
            pairForSushiswap(SushiswapV2Factory, path[0], path[1]), // to
            amounts[0] // value
        );
        _sushi_swap(amounts, path, to);
    }

    function approveToken(address _token, address _toApprove, uint _quantity) public {
         // create a pointer to the token we are going to sell on sushiswap 
        IERC20 token = IERC20(_token);
        // approve the sushiSwapRouter to spend our tokens so the trade can occur             
        token.approve(address(_toApprove), _quantity);
        // return the approved quantity
        uint amountApproved = token.allowance(address(this), _toApprove);
    }

    // trader needs to monitor for arbitrage opportunities with a bot or script
    // this is the function that trader will call when an arbitrage opportunity exists
    // tokens are the addresses that you want to trade
    // this first function will create the flash loan on uniswap
    // one of the amounts will be 0 and the other amount will be the amount you want to borrow
    function executeTrade(address token0, address token1, uint amount0, uint amount1) public {

        // get liquidity pair address for tokens on uniswap
        address pairAddress = IUniswapV2Factory(UniswapV2Factory).getPair(token0, token1); 

        // make sure the pair exists in uniswap 
        require(pairAddress != address(0), "Could not find pool on uniswap"); 

        bytes memory data = abi.encode(pairAddress);

        // create flashloan 
        // create pointer to the liquidity pair address 
        // to create a flashloan call the swap function on the pair contract 
        // one amount will be 0 and the non 0 amount is for the token you want to borrow 
        // address is where you want to receive token that you are borrowing
        // bytes can not be empty.  Need to inculde some text to initiate the flash loan 
        // if bytes is empty it will initiate a traditional swap 
        IUniswapV2Pair(pairAddress).swap(amount0, amount1, address(this), data);
    }

    // After the flashloan is created the below function will be called back by Uniswap
    // Uniswap is expecting the function to be named uniswapV2Call
    // the parameters below will be sent
    // sender is the smart contract address
    // amount will be the amount borrowed from the flashloan and other amount will be 0
    // bytes is the calldata passed in above
    function uniswapV2Call(address _sender, uint _amount0, uint _amount1, bytes calldata _data) override external {

        // the path is the array of addresses to capture pricing information 
        address[] memory pathA = new address[](2);
        address[] memory pathB = new address[](2);
        
        // get the amount of tokens that were borrowed in the flash loan amount 0 or amount 1 
        // call it amountTokenBorrowed and will use later in the function 
        uint amountTokenBorrowed = _amount0 == 0 ? _amount1 : _amount0; 

        // get the addresses of the two tokens from the uniswap liquidity pool 
        address token0 = IUniswapV2Pair(msg.sender).token0(); 
        address token1 = IUniswapV2Pair(msg.sender).token1(); 

        // make sure the call to this function originated from
        // one of the pair contracts in uniswap to prevent unauthorized behavior
        require(msg.sender == UniswapV2Library.pairFor(UniswapV2Factory, token0, token1), "Invalid Request");
        // check sender holds the address who initiated the flash loans
        require(_sender == address(this), "!sender");

        // make sure one of the amounts = 0 
        require(_amount0 == 0 || _amount1 == 0);

        // create and populate path array for sushiswap.  
        // this defines what token we are buying or selling 
        // if amount0 == 0 then we are going to sell token 1 and buy token 0 on sushiswap 
        // if amount0 is not 0 then we are going to sell token 0 and buy token 1 on sushiswap 
        pathA[0] = _amount0 == 0 ? token1 : token0; //ALE
        pathA[1] = _amount0 == 0 ? token0 : token1; //MAT
        // create and populate path array for uniswap getAmountsIn function.
        // unlike swapExactTokensForTokens that us getAmountsOut inside the sort of the token inside "path" must be inverted.
        pathB[0] = _amount0 == 0 ? token0 : token1; //MAT
        pathB[1] = _amount0 == 0 ? token1 : token0; //ALE

        //get Sushiswap pair address
        //address sushi_pair = pairForSushiswap(SushiswapV2Factory, token0, token1);

        // create a pointer to the token we are going to sell on sushiswap 
        IERC20 token = IERC20(_amount0 == 0 ? token1 : token0);
        IERC20 tokenUNI = IERC20(msg.sender);
        
        // approve the sushiSwapRouter to spend our tokens so the trade can occur 
        //Lets msg.sender set their allowance for a spender.            
        token.approve(address(sushi_router), amountTokenBorrowed);
        tokenUNI.approve(address(sushi_router), amountTokenBorrowed);
        //Returns the amount of liquidity tokens owned by an address that a spender is allowed to transfer via transferFrom.
        //uint allowed = token.allowance(msg.sender, address(sushi_router));
        //uint allowedUNI = token.allowance(msg.sender, address(sushi_router));
        //approveToken(address(token), address(sushi_router), amountTokenBorrowed);
        //approveToken(address(tokenUNI), address(sushi_router), amountTokenBorrowed);
        IUniswapV2Pair(msg.sender).transfer(address(this), amountTokenBorrowed);

        // calculate the amount of tokens we need to reimburse uniswap for the flashloan 
        uint amountRequired = UniswapV2Library.getAmountsIn(UniswapV2Factory, amountTokenBorrowed, pathB)[0]; 
        
        // finally sell the token we borrowed from uniswap on sushiswap 
        // amountTokenBorrowed is the amount to sell 
        // amountRequired is the minimum amount of token to receive in exchange required to payback the flash loan 
        // path what we are selling or buying 
        // msg.sender address to receive the tokens 
        // deadline is the order time limit 
        // if the amount received does not cover the flash loan the entire transaction is reverted
        uint amountReceived = _swapExactTokensForTokens(amountTokenBorrowed, amountRequired, pathA, address(this), block.timestamp + 60)[1]; 

        // fail if we didn't get enough tokens
        require(amountReceived > amountRequired, "amountReceived <= amountRequired!");

        // pointer to output token from sushiswap 
        IERC20 outputToken = IERC20(_amount0 == 0 ? token0 : token1);
        
        // amount to payback flashloan 
        // amountRequired is the amount we need to payback 
        // uniswap can accept any token as payment
        outputToken.transfer(msg.sender, amountRequired);   

        // send profit (remaining tokens) back to the address that initiated the transaction 
        outputToken.transfer(owner, amountReceived - amountRequired);  
    }

    receive() external payable {}
    fallback() external payable {}
    
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeApprove: approve failed'
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
    }
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

interface IUniswapV2Callee {
    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external;
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

pragma solidity >=0.5.0;

import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';

import "./SafeMath.sol";

library UniswapV2Library {
    using SafeMath for uint;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f' // init code hash
            ))));
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'UniswapV2Library: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(1000);
        uint denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}

pragma solidity =0.6.6;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMath {
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