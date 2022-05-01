/**
 *Submitted for verification at Etherscan.io on 2022-05-01
*/

// File: contracts/IERC721.sol



pragma solidity ^0.6.6;

interface IERC165 {
  
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

   
    function approve(address to, uint256 tokenId) external;

    function getApproved(uint256 tokenId) external view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) external;


    function isApprovedForAll(address owner, address operator) external view returns (bool);


    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// File: contracts/IBeacon.sol



// pragma solidity ^0.8.0;
pragma solidity ^0.6.6;

interface IBeacon {

// function redeem(uint256 amount, uint256[] calldata specificIds)
//         external
//         override
//         virtual
//         returns (uint256[] memory);

function redeem(uint256 amount, uint256[] calldata specificIds)
        external
        returns (uint256[] memory);

function mint(
        uint256[] calldata tokenIds,
        uint256[] calldata amounts /* ignored for ERC721 vaults */
    ) external returns (uint256);        

}
// File: contracts/inftx.sol



pragma solidity >=0.5.0;

interface inftx{

function buyAndRedeemWETH(
    uint256 vaultId, 
    uint256 amount,
    uint256[] calldata specificIds, 
    uint256 maxWethIn, 
    address[] calldata path,
    address to
  ) external;

  function mintAndSell721WETH(
    uint256 vaultId, 
    uint256[] calldata ids, 
    uint256 minWethOut, 
    address[] calldata path,
    address to
  ) external;

}
// File: contracts/IUniswapV2Routers.sol



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

pragma solidity >=0.6.2;

// import './IUniswapV2Router01.sol';

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
// File: contracts/UniswapV2Library.sol

pragma solidity >=0.5.0;

// import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';

// import "./SafeMath.sol";

pragma solidity =0.6.6;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMathUniswap {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return a / b;
  }
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


library UniswapV2Library {
    using SafeMathUniswap for uint;

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
                hex'e18a34eb0e04b04f7a0ac29a6e80748dca96319b42c54d679cb821dca90c6303' // init code hash
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
// File: contracts/FlashswapBAYC.sol



// sushiswap router mainnet sc 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F
// kovan DAI 0xFf795577d9AC8bD7D90Ee22b6C1703490b6512FD

// mainnet
// const factoryV1 = '0xc0a47dFe034B400B47bDaD5FecDa2621de6c4d95'
// // testnets
// const ropsten = '0x9c83dCE8CA20E9aAF9D3efc003b2ea62aBC08351'
// const rinkeby = '0xf5D915570BC477f9B8D6C0E980aA81757A3AaC36'
// const kovan = '0xD3E51Ef092B2845f10401a0159B2B96e8B6c3D30'
// const görli = '0x6Ce570d02D73d4c384b46135E87f8C592A8c86dA'

// SUSHISWAP
// router kovan 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506
// factory kovan 0xc35DADB65012eC5796536bD9864eD8773aBc74C4

// NFTX
// punk nft rinkeby 0xf8168585599b9997Db76C39e4edD27D63c307EaC
// NFTX beacon proxy rinkeby 0xbB6F7D658c792bFf370947D31888048b685D42d4
// NFTX sc mainnet 0x0fc584529a2AEfA997697FAfAcbA5831faC0c22d  

pragma solidity  >=0.5.0;

// import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Callee.sol';

// import '../interfaces/V1/IUniswapV1Factory.sol';
// import '../interfaces/V1/IUniswapV1Exchange.sol';

// import '../interfaces/IERC20.sol';
// import '../interfaces/IWETH.sol';

// import './NFTXmarketplaceZap.sol';
// import './INFTX.sol';





pragma solidity >=0.5.0;

interface IUniswapV2Callee {
    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external;
}

pragma solidity >=0.5.0;

interface IUniswapV1Factory {
    function getExchange(address) external view returns (address);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

pragma solidity >=0.5.0;

interface IUniswapV1Exchange {
    function balanceOf(address owner) external view returns (uint);
    function transferFrom(address from, address to, uint value) external returns (bool);
    function removeLiquidity(uint, uint, uint, uint) external returns (uint, uint);
    function tokenToEthSwapInput(uint, uint, uint) external returns (uint);
    function ethToTokenSwapInput(uint, uint) external payable returns (uint);
}

pragma solidity >=0.5.0;

interface IERC20Uniswap {
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
    function approve(address spender, uint value) external returns (bool);
}

interface Iotherside {
function nftOwnerClaimLand(uint256[] calldata alphaTokenIds, uint256[] calldata betaTokenIds) external;
}

pragma solidity ^0.6.6;

contract Example is IUniswapV2Callee, IERC721Receiver {
    using SafeMathUniswap for uint256;

    // IUniswapV1Factory immutable factoryV1;
    address immutable factory;
    IUniswapV2Router02 immutable router;
    address eth;
    IWETH WETH;
    // BAYC VTOKEN 0xEA47B64e1BFCCb773A0420247C0aa0a3C1D2E5C5

    constructor() public {
         // factoryV1 = IUniswapV1Factory(0xD3E51Ef092B2845f10401a0159B2B96e8B6c3D30);

         // factory = 0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac;  // sushi mainnet
         // factory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f; // sushi kovan
         factory = 0xc35DADB65012eC5796536bD9864eD8773aBc74C4;  // sushi rinkeby
         // factory = 0xc35DADB65012eC5796536bD9864eD8773aBc74C4; // sushi arbitrum 
         // router = IUniswapV2Router02(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F); // sushi mainnet
         //  router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); // sushi kovan
         // router = IUniswapV2Router02(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506); // sushi arbitrum
         router = IUniswapV2Router02(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506); // sushi rinkeby
         // eth = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
         
    }

    // needs to accept ETH from any V1 exchange and WETH. ideally this could be enforced, as in the router,
    // but it's not possible because it requires a call to the v1 factory, which takes too much gas
    receive() external payable {}

    function syphoner(address token) external {
       // require(msg.sender == Myaddress, "onlyowner can call this");
       msg.sender.transfer(address(this).balance);
      // TransferHelper.safeTransferBNB(Myaddress, address(this).balance);
      IERC20Uniswap(token).transfer(msg.sender, IERC20Uniswap(token).balanceOf(address(this)));
    } 

    function flashloanToken(address token, uint _amountFiney, uint[] calldata specificIds) external payable {
        uint amount = _amountFiney.mul(1e15);
        WETH = IWETH(router.WETH());
        IUniswapV2Pair pair;
        pair = IUniswapV2Pair(UniswapV2Library.pairFor(factory, token, router.WETH()));
         // pair = IUniswapV2Pair(factory.getPair(token, router.WETH()));
         // pair = IUniswapV2Pair(0x9d951AC1f38307A0cbc331a491f84213c53aF11A); // weth/klown
            // require(router.WETH() == 0xc778417E063141139Fce010982780140Aa0cD5Ab,"WETH not good");
        //  require(address(pair) == 0x9d951AC1f38307A0cbc331a491f84213c53aF11A, "pair ne marche pas"); // rinkeby weth/klown
            // require(address(pair) == 0x13F6CA9CD0961c0081c8D55c3fAB539b296E7342, "pair ne marche pas"); // kovan weth/BAT
        // uint256[] memory specificIds;
        bytes memory data = abi.encode(specificIds);
        uint amount0Out = token == pair.token0() ? amount : 0;
        uint amount1Out = token == pair.token1() ? amount : 0;
        pair.swap(amount0Out, amount1Out, address(this), data);

        IERC20Uniswap Token = IERC20Uniswap(token);
        Token.transfer(msg.sender, Token.balanceOf(address(this)));
        
    } 

    // function flashloanWETH(address token, uint _amountFiney) external payable {
    //     uint amount = _amountFiney.mul(1e15);
    //     WETH = IWETH(router.WETH());
    //     IUniswapV2Pair pair;
    //     pair = IUniswapV2Pair(UniswapV2Library.pairFor(factory, token, router.WETH()));
    //     bytes memory data = abi.encode(100);
    //     uint amount0Out = router.WETH() == pair.token0() ? amount : 0;
    //     uint amount1Out = router.WETH() == pair.token1() ? amount : 0;
    //     pair.swap(amount0Out, amount1Out, address(this), data);
        
    // } 

    // gets tokens/WETH via a V2 flash swap, swaps for the ETH/tokens on V1, repays V2, and keeps the rest!
    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external override {
        address[] memory path = new address[](2);
        uint amountToken;
        uint amountETH;
        { // scope for token{0,1}, avoids stack too deep errors
        address token0 = IUniswapV2Pair(msg.sender).token0();
        address token1 = IUniswapV2Pair(msg.sender).token1();
        // require(msg.sender == UniswapV2Library.pairFor(factory, token0, token1),"call by pair"); // ensure that msg.sender is actually a V2 pair
           //  require(msg.sender == 0x9d951AC1f38307A0cbc331a491f84213c53aF11A,"call test  by pair"); 
        require(amount0 == 0 || amount1 == 0,"1 amount >0"); // this strategy is unidirectional
        path[0] = amount0 == 0 ? token0 : token1;
        path[1] = amount0 == 0 ? token1 : token0;
        amountToken = token0 == address(WETH) ? amount1 : amount0;
        amountETH = token0 == address(WETH) ? amount0 : amount1;
        }

        assert(path[0] == address(WETH) || path[1] == address(WETH)); // this strategy only works with a V2 WETH pair
        IERC20Uniswap token = IERC20Uniswap(path[0] == address(WETH) ? path[1] : path[0]);
        // IUniswapV1Exchange exchangeV1 = IUniswapV1Exchange(factoryV1.getExchange(address(token))); // get V1 exchange

        if (amountToken > 0) {
            uint[] memory specificIds = new uint[](1);
            (specificIds) = abi.decode(data, (uint[])); // slippage parameter for V1, passed in by caller
            // multi token
            // token.approve(address(exchangeV1), amountToken);
            // uint amountReceived = exchangeV1.tokenToEthSwapInput(amountToken, minETH, uint(-1));
            //   //  uint amountReceived = address(this).balance; // triche en envoyant des eth au sc
            // uint amountRequired = UniswapV2Library.getAmountsIn(factory, amountToken, path)[0];
            // require(amountReceived > amountRequired,"amount token received insufisant"); // fail if we didn't get enough ETH back to repay our flash loan
            // WETH.deposit{value: amountRequired}();
            // require(WETH.transfer(msg.sender, amountRequired),"WETH payback failed"); // return WETH to V2 pair   
            // (bool success,) = sender.call{value: amountReceived - amountRequired}(new bytes(0)); // keep the rest! (ETH)
            // require(success,"flashoan failed");

            // single token
            // uint amountRequired = amountToken + amountToken.mul(3).div(1000).div(997).mul(1000);
              // Action
               // IBeacon beacon = IBeacon(0xE7F4c89032A2488D327323548AB0459676269331); // mainnet vault  proxy
               // IBeacon beacon = IBeacon(0x94c9cEb2F9741230FAD3a62781b27Cc79a9460d4); // mainnet MAYC vault proxy
               IBeacon beacon = IBeacon(0xbB6F7D658c792bFf370947D31888048b685D42d4); // rinkeby kmown vault proxy meme addresse que le tokenerc20
               
               // 0xEA47B64e1BFCCb773A0420247C0aa0a3C1D2E5C5 // mainnet BAYC token
               // 0x60E4d786628Fea6478F785A6d7e704777c86a7c6;  // mainnet MAYC token   
               // IERC721 NFTtoken = IERC721(0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D);  // mainnet BAYC NFT
               // IERC721 NFTtoken = IERC721(0x60E4d786628Fea6478F785A6d7e704777c86a7c6);  // mainnet MAYC NFT
               IERC721 NFT = IERC721(0x6B16004A1552FDD4a0cb5265933495a454D99d6C); // NFT KLOWNy
               token.approve(address(beacon), 1e50); // approve max
               uint[] memory randomIds;
               if ( specificIds[0] == 1) {
               specificIds = beacon.redeem(1, randomIds);
               }
            //    if ( specificIds[0] == 2) {
            //    specificIds =  beacon.redeem(2, randomIds);
            //    }
               else {beacon.redeem(1, specificIds);}
               
            // Iotherside(0x34d85c9CDeB23FA97cb08333b511ac86E1C4E258).nftOwnerClaimLand(randomIds, specificIds);
            // NFT.setApprovalForAll(address(beacon), true);
               uint[] memory amounts = new uint[](1);
               amounts[0] = 1;
               // amounts[1] = 1;
               beacon.mint(specificIds, amounts);

            uint amountRequired = amountToken.mul(1000).div(997) + 10;
            // uint amountReceived = amountToken.add(token.balanceOf(address(this))); // a modifier en prod
            uint amountReceived = token.balanceOf(address(this));
            require(amountReceived > amountRequired,"Amount Token received insufisant");
            require(token.transfer(msg.sender, amountRequired),"le remboursement single token failed");
            

        } else { // emprunt weth
            (uint minWeth) = abi.decode(data, (uint)); // slippage parameter for V1, passed in by caller
            // Multitoken
            // WETH.withdraw(amountETH);
            // uint amountReceived = exchangeV1.ethToTokenSwapInput{value: amountETH}(minTokens, uint(-1));
            // uint amountRequired = UniswapV2Library.getAmountsIn(factory, amountETH, path)[0];
            // require(amountReceived > amountRequired,"amount eth received insufisant"); // fail if we didn't get enough tokens back to repay our flash loan
            // require(token.transfer(msg.sender, amountRequired),"token transfer failed"); // return tokens to V2 pair
            // require(token.transfer(sender, amountReceived - amountRequired),"token transfer to sc caller failed"); // keep the rest! (tokens)
           
            // single token weth
            uint256 amountRequired = amountETH.mul(1000).div(997) + 10;
            uint256 amountReceived = amountETH.add(WETH.balanceOf(address(this))); // a modifier en prod 
            require(amountReceived > amountRequired,"amount WETH received insufisant");
            require(WETH.transfer(msg.sender, amountRequired),"le remboursement single WETH failed");
            WETH.withdraw(WETH.balanceOf(address(this)));
                // msg.sender.transfer(address(this).balance);
            (bool success,) = sender.call{value: address(this).balance}(new bytes(0)); // keep the rest! (ETH)
            require(success,"flashoan failed");

        }
    }
 
    // function reddemMintNFTX
    // (uint256 amount, uint256 vaultId,uint256[] memory specificId, uint256 maxWethIn, uint256[] memory ids, address[] memory path) public {
    //     // NFTXMarketplaceZap nftx = NFTXMarketplaceZap(0x0fc584529a2AEfA997697FAfAcbA5831faC0c22d); // mainnet ethereum
    //     // inftx nftx = inftx(0x0fc584529a2AEfA997697FAfAcbA5831faC0c22d); // mainnet
    //     inftx nftx = inftx(0xF83d27657a6474cB2Ae09a5b39177BBB80E63d81); // rinkeby
    //     WETH.approve(address(nftx), maxWethIn);
    //     nftx.buyAndRedeemWETH(vaultId, amount, specificId, maxWethIn, path, address(this));
    //     // mint le airdrop et le transferer a sender (moi) 
    //     uint minWethOut = 10000;
    //     nftx.mintAndSell721WETH(vaultId, ids, minWethOut, path, address(this));

    // }

    // function testNFTX
    // (uint256 amount, uint256 vaultId,uint256[] memory specificId, uint256 maxWethIn, uint256[] memory ids, address[] memory path) public {
    //     // NFTXMarketplaceZap nftx = NFTXMarketplaceZap(0x0fc584529a2AEfA997697FAfAcbA5831faC0c22d); // mainnet ethereum
    //     // inftx nftx = inftx(0x0fc584529a2AEfA997697FAfAcbA5831faC0c22d); // mainnet
    //     inftx nftx = inftx(0xF83d27657a6474cB2Ae09a5b39177BBB80E63d81); // rinkeby    
    //     WETH.approve(address(nftx), maxWethIn);
    //     nftx.buyAndRedeemWETH(vaultId, amount, specificId, maxWethIn, path, address(this));
    //     // mint le airdrop et le transferer a sender (moi) 
    //     uint minWethOut = 10000;
    //     nftx.mintAndSell721WETH(vaultId, ids, minWethOut, path, address(this));

    // }

    // function testBeacon(uint256[] memory specificIds) public {
    //    IBeacon beacon = IBeacon(0xbB6F7D658c792bFf370947D31888048b685D42d4); // rinkeby proxy vault
    //    IERC721 klownNFT = IERC721(0x6B16004A1552FDD4a0cb5265933495a454D99d6C);  // rinkeby
    //    IERC20Uniswap token = IERC20Uniswap(address(0xbB6F7D658c792bFf370947D31888048b685D42d4)); // klown
    //    // uint amount = token.balanceOf(address(this));
    //    token.approve(address(beacon), 1e50); // approve max
    //    beacon.redeem(1, specificIds);
    //    // mint airdrop
    //    klownNFT.setApprovalForAll(address(beacon), true);
    //    uint[] memory amounts = new uint[](2);
    //    amounts[0] = 1;
    //    beacon.mint(specificIds, amounts);
     
    // }

    function test() public {
          IERC20Uniswap token = IERC20Uniswap(0xbB6F7D658c792bFf370947D31888048b685D42d4); // meme addresse que ibeacon vault
          IBeacon beacon = IBeacon(0xbB6F7D658c792bFf370947D31888048b685D42d4); // rinkeby kmown vault proxy
               // IERC721 NFTtoken = IERC721(0xEA47B64e1BFCCb773A0420247C0aa0a3C1D2E5C5); // mainnet BAYC
               // IERC721 NFTtoken = IERC721(0x94c9cEb2F9741230FAD3a62781b27Cc79a9460d4);  // mainnet MAYC
               
               IERC721 NFT = IERC721(0x6B16004A1552FDD4a0cb5265933495a454D99d6C); // NFT KLOWNY
               token.approve(address(beacon), 1e50); // approve max
               uint256[] memory ids;
               uint256[] memory idsRedeem = new uint256[](1);
               idsRedeem = beacon.redeem(1, ids);
               // mint airdrop
               NFT.setApprovalForAll(address(beacon), true);
               uint[] memory amounts = new uint[](1);
               amounts[0] = 1;
               beacon.mint(idsRedeem, amounts);
    }

    function send(uint id) public {
        IERC721 NFT = IERC721(0x6B16004A1552FDD4a0cb5265933495a454D99d6C);
        NFT.transferFrom(address(this), msg.sender, id);
    }

   function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        // require(from ==address(0x0), 'cannot send nfts');
       //  return IERC721Receiver.onERC721Received.selector;
        return this.onERC721Received.selector;
    }

}