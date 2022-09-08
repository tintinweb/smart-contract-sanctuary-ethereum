import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";
import "./IPancakeswapV2Pair.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;  

contract Oracle is Ownable{
    IUniswapV2Router02 public uniswapV2Router;

    IPancakeswapV2Pair public USDPair;
    IPancakeswapV2Pair public TOKENPair;

    address public USD = 0x045144F7532E498694d7Aae2d88E176c42c0ff97; // usd token
    address public TOKEN = 0x045144F7532E498694d7Aae2d88E176c42c0ff97;  // plushie token // mintable 0x73A59d7b4D7d7316F0D933FA9739d9aAaAdEf98B
    event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);

    constructor() {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        address _uniswapV2USDPair = IUniswapV2Factory(_uniswapV2Router.factory()).getPair(address(USD), _uniswapV2Router.WETH());
        USDPair = IPancakeswapV2Pair(_uniswapV2USDPair);

        address _uniswapV2TOKENPair = IUniswapV2Factory(_uniswapV2Router.factory()).getPair(address(TOKEN), _uniswapV2Router.WETH());
        TOKENPair = IPancakeswapV2Pair(_uniswapV2TOKENPair);
        uniswapV2Router = _uniswapV2Router;
    }

    function setRouter(address _router) external onlyOwner{
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(_router);
        uniswapV2Router = _uniswapV2Router;
    }
    
    function setTOKENPair(address _token) external onlyOwner{
        require(TOKEN != _token);
        TOKEN = _token;
        address _uniswapV2TOKENPair = IUniswapV2Factory(uniswapV2Router.factory())
            .getPair(address(_token), uniswapV2Router.WETH());
        TOKENPair = IPancakeswapV2Pair(_uniswapV2TOKENPair);
    }

    function setUSDPair(address _usd) external onlyOwner{
        require(USD != _usd);
        USD = _usd;
        address _uniswapV2USDPair = IUniswapV2Factory(uniswapV2Router.factory())
            .getPair(address(_usd), uniswapV2Router.WETH());
        USDPair = IPancakeswapV2Pair(_uniswapV2USDPair);
    }


    function getPrice(uint256 _amount,uint16 _decimals, uint256 _denominator) external view returns(uint256){ 
        uint256 bnbInUsdPair;
        uint256 usdInUsdPair;
        uint256 BNB;
        uint256 Token;
        
        if(address(USDPair.token0()) == address(USD))
            (usdInUsdPair, bnbInUsdPair,  ) = USDPair.getReserves();
        else
            (bnbInUsdPair, usdInUsdPair, ) = USDPair.getReserves();
            
        uint256 bnbPriceInUsd = usdInUsdPair / bnbInUsdPair;
        
        if(address(TOKENPair.token0()) == TOKEN)
            (Token, BNB,) = TOKENPair.getReserves();
        else
            (BNB, Token,) = TOKENPair.getReserves();
        uint256 TokenBNBPrice = (Token * 10 ** (18-_decimals)) / BNB;

        uint256 TokenUsdPrice = (_amount*bnbPriceInUsd/TokenBNBPrice) / 10**_denominator;
        
        return (TokenUsdPrice); 
    }
//!     So you know how you will use plushie tycoon coin to buy a nft and there is 1/10/20/50/100 for example you can buy at a time,

// ! Can you make it so that for each nft the user also pays for a 1 dollar transaction fee in bnb that will be sent to a designated wallet?

//!  So for example if they want to buy the package of 1 nft they pay 1plushi token and 1 dollar worth of bnb foe the transaction, if it’s 10 nfts that’s 10 coins and 10 dollars worth of bnb
 
    function getNFTPrice(uint256 token_, bool _type) external view returns(uint256){  
        uint256 bnbInUsdPair;
        uint256 usdInUsdPair;
        uint256 BNB;
        uint256 Token;
        uint256 tokenPrice;
        uint256 bnbPrice;
        
        if(address(USDPair.token0()) == address(USD))
            (usdInUsdPair, bnbInUsdPair,  ) = USDPair.getReserves();
        else
            (bnbInUsdPair, usdInUsdPair, ) = USDPair.getReserves();
            
        uint256 bnbPriceInUsd = (usdInUsdPair * 1e18) / bnbInUsdPair;
        
        if(address(TOKENPair.token0()) == TOKEN)
            (Token, BNB,) = TOKENPair.getReserves();
        else
            (BNB, Token,) = TOKENPair.getReserves();

        uint256 TokenBNBPrice = (Token * 1e18) / BNB;

        uint256 TokenUsdPrice = (1e18 * bnbPriceInUsd) / TokenBNBPrice;

        if(_type == true){
        tokenPrice = (token_ * 1e18) / TokenUsdPrice;
        return tokenPrice; // plushi token ise türkçeleri sileriz sonra Ahmet abiye bi son kez anlatıp
        }               // ok
        bnbPrice = (token_ * TokenUsdPrice) / bnbPriceInUsd;
        return bnbPrice; // bnb ise type
    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16; 
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

import "./IUniswapV2Router01.sol";
// SPDX-License-Identifier: MIT
pragma solidity 0.8.16; 
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
pragma solidity 0.8.16; 
interface IPancakeswapV2Pair {
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

    function permit(
        address owner, 
        address spender, 
        uint value, 
        uint deadline, 
        uint8 v, 
        bytes32 r, 
        bytes32 s
    ) external;

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
    function getReserves() external view returns (
        uint112 reserve0, 
        uint112 reserve1, 
        uint32 blockTimestampLast
    );
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
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
pragma solidity 0.8.16; 
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