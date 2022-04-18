/**
 *Submitted for verification at Etherscan.io on 2022-04-18
*/

/**
 *Submitted for verification at Etherscan.io on 2022-03-11
*/

// File: https://github.com/Uniswap/uniswap-v2-periphery/blob/master/contracts/interfaces/IUniswapV2Router01.sol

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

// File: https://github.com/Uniswap/uniswap-v2-periphery/blob/master/contracts/interfaces/IUniswapV2Router02.sol

pragma solidity >=0.6.2;


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

// File: musashi-js/contracts/Farm/price-convertor/TransferHelper.sol

pragma solidity 0.6.12;

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

// File: musashi-js/contracts/Farm/price-convertor/SafeMath.sol

pragma solidity 0.6.12;

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a, 'SafeMath:INVALID_ADD');
    }

    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a, 'SafeMath:OVERFLOW_SUB');
        c = a - b;
    }

    function mul(uint a, uint b, uint decimal) internal pure returns (uint) {
        uint dc = 10**decimal;
        uint c0 = a * b;
        require(a == 0 || c0 / a == b, "SafeMath: multiple overflow");
        uint c1 = c0 + (dc / 2);
        require(c1 >= c0, "SafeMath: multiple overflow");
        uint c2 = c1 / dc;
        return c2;
    }

    function div(uint256 a, uint256 b, uint decimal) internal pure returns (uint256) {
        require(b != 0, "SafeMath: division by zero");
        uint dc = 10**decimal;
        uint c0 = a * dc;
        require(a == 0 || c0 / a == dc, "SafeMath: division internal");
        uint c1 = c0 + (b / 2);
        require(c1 >= c0, "SafeMath: division internal");
        uint c2 = c1 / b;
        return c2;
    }
}

// File: musashi-js/contracts/Farm/price-convertor/PriceConvertor.sol

pragma solidity 0.6.12;




contract PriceConvertor {
    using SafeMath for uint;
    
    uint constant ETHER_DECIMAL = 18;
    
    address public owner;
    address public token_usdt;
    address public uniswap_factory;
    address public uniswap_router;
    
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    constructor() public {
        owner = msg.sender;
        token_usdt  = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
        uniswap_factory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
        uniswap_router  = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    }
    
    // (default asset) convert token to usd. assume token have pair with BNB
    function getTokenToUsd(address token, uint token0Amount) public view returns (uint) {
        address[] memory path = new address[](2);
        path[0] = token;
        path[1] = IUniswapV2Router02(uniswap_router).WETH();
        uint bnb = _getPrice(token0Amount, path);    
        
        address[] memory path2 = new address[](2);
        path2[0] = IUniswapV2Router02(uniswap_router).WETH();
        path2[1] = token_usdt;
        return _getPrice(bnb, path2);
    }
    
    // get WETH from the router
    function getWeth() public view returns (address) {
        return IUniswapV2Router02(uniswap_router).WETH();
    }
    
    // convert any pairing
    function getPrice(uint token0Amount, address[] memory pair) public view returns (uint) {
        return _getPrice(token0Amount, pair);
    }
    
    // update factory address
    function updateUniswapFactory(address _address) public onlyOwner {
        uniswap_factory = _address;        
    }
    
    // update router address
    function updateUniswapRouter(address _address) public onlyOwner {
        uniswap_router = _address;        
    }
    
    // update token_usdt address
    function updateUsdt(address _address) public onlyOwner {
        token_usdt = _address;        
    }
    
    // transfer ownership
    function transferOwner(address _address) public onlyOwner {
        owner = _address;
    }
    
    // emergency transfer ether to owner. only owner executable
    function emergencyTransferEther(uint amount) public onlyOwner {
        TransferHelper.safeTransferETH(owner, amount);
    }

    // emergency transfer any token to owner. only owner executable
    function emergencyTransferToken(address token, uint amount) public onlyOwner {
        TransferHelper.safeTransfer(token, owner, amount);
    }
    
    // get pair price rate as close as the raw price
    function _getPrice(uint token0Amount, address[] memory pair) internal view returns (uint) {
        // retrieve reserve of pairing
        (uint reserve0, uint reserve1,) = IUniswapPair(IUniswapFactory(uniswap_factory).getPair(pair[0], pair[1])).getReserves();

        address token0 = IUniswapPair(IUniswapFactory(uniswap_factory).getPair(pair[0], pair[1])).token0();
        address token1 = IUniswapPair(IUniswapFactory(uniswap_factory).getPair(pair[0], pair[1])).token1();

        // convert to WEI unit for calculation
        reserve0     = reserve0     * 10**(ETHER_DECIMAL.sub(IERC20(token0).decimals()));
        reserve1     = reserve1     * 10**(ETHER_DECIMAL.sub(IERC20(token1).decimals()));
        token0Amount = token0Amount * 10**(ETHER_DECIMAL.sub(IERC20(pair[0]).decimals()));

        // calculate price rate
        uint price   = token0Amount.mul((token0 == pair[0] ? reserve1 : reserve0), ETHER_DECIMAL);
        price        = price.div((token0 == pair[0] ? reserve0 : reserve1), ETHER_DECIMAL);

        // convert WEI unit to the output currency decimal
        price = price / 10**(ETHER_DECIMAL.sub(IERC20(pair[1]).decimals()));

        return price;
    }
}

interface IERC20 {
    function decimals() external view returns (uint);
}

interface IUniswapFactory {
    function getPair(address tokenA, address tokenB) external view returns (address);
}

interface IUniswapPair {
    function getReserves() external view returns (uint112, uint112, uint32);
    function token0() external view returns (address);
    function token1() external view returns (address);
}