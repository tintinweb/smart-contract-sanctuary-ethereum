/**
 *Submitted for verification at Etherscan.io on 2022-04-18
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

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

// Ropsten test (latest contract: 0x3bf986e4dE3edc78F6f417C80395565212ad2051)
contract UniswapTest {
    address private JHT       = 0x8366233f4B4d9b337C3CF4837Bae0917613CAdf5;
    address private DAI       = 0xaD6D458402F60fD3Bd25163575031ACDce07538D;
    address private WETH      = 0xc778417E063141139Fce010982780140Aa0cD5Ab; // mainnet: 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
    // address private USDC      = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48; // mainnet
    address private factoryV2 = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address private factoryV3 = 0x1F98431c8aD98523631AE4a59f267346ea31F984;
    address private uniRouter2  = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address private swapRouter2 = 0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45;
    // JHT/ETH pool : 0x7A3F37e60C0a499708C7485C897c11edA2f1E950
    function getPair(address token0, address token1) public view returns (address) {
        return IUniswapV2Factory(factoryV2).getPair(token0, token1);
    }
    function getReserves(address token0, address token1) external view returns (uint112, uint112, uint32) {
        address pair = getPair(token0, token1);
        (uint112 reserve0, uint112 reserve1, uint32 btl) = IUniswapV2Pair(pair).getReserves();
        return (reserve0, reserve1, btl);
    }
    function allPairs(uint idx) external view returns (address) {
        return IUniswapV2Factory(factoryV2).allPairs(idx);
    }
    function allPairsLength() external view returns (uint) {
        return IUniswapV2Factory(factoryV2).allPairsLength();
    }
    function createPair(address token0, address token1) external returns (address pair) {
        return IUniswapV2Factory(factoryV2).createPair(token0, token1);
    }
}

contract TestType {
    uint public constant test = 1;
    uint public immutable test2 = 2;
}

contract Test {
    // address private JHT       = 0x8366233f4B4d9b337C3CF4837Bae0917613CAdf5;
    // address private WETH      = 0xc778417E063141139Fce010982780140Aa0cD5Ab;
    // address public creartedPair;
    // function getByteCode() public pure returns (bytes memory) {
    //     // 0x6080604052348015600f57600080fd5b50603f80601d6000396000f3fe6080604052600080fdfea2646970667358221220ffe3f53613107de2c656460e3a9f495347ea5a33d3f7a0288fa917567f19779e64736f6c634300080d0033
    //     return type(TestType).creationCode;
    // }
    // function getSalt(address token0, address token1) public pure returns (bytes32) {
    //     // 0xdfcd40af0c188014cdffec0739f801c8c1cd88cd047542db69745f38839d9fee
    //     return keccak256(abi.encodePacked(token0, token1));
    // }
    // function getEncodePacked(address token0, address token1) external pure returns (bytes memory) {
    //     // 0x8366233f4b4d9b337c3cf4837bae0917613cadf5c778417e063141139fce010982780140aa0cd5ab
    //     return abi.encodePacked(token0, token1);
    // }
    // function getPair(address token0, address token1) external returns (address pair) {
    //     bytes memory bytecode = getByteCode();
    //     bytes32 salt = getSalt(token0, token1);
    //     assembly {
    //         pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
    //     }
    //     creartedPair = pair;
    // }
    uint public inn;
    uint public out;
    uint public dead;
    address public toAddr;
    address[] public pathArr;
    function aaa1(address[] calldata path, uint amountIn, uint amountOutMin, address to, uint deadline) external {
        inn = amountIn;
        out = amountOutMin;
        pathArr = path;
        toAddr = to;
        dead = deadline;
    }
    function aaa2(uint amountIn, address[] calldata path, uint amountOutMin, address to, uint deadline) external {
        inn = amountIn;
        out = amountOutMin;
        pathArr = path;
        toAddr = to;
        dead = deadline;
    }
    function aaa3(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external {
        inn = amountIn;
        out = amountOutMin;
        pathArr = path;
        toAddr = to;
        dead = deadline;
    }
    function aaa4(uint amountIn, uint amountOutMin, address to, address[] calldata path, uint deadline) external {
        inn = amountIn;
        out = amountOutMin;
        pathArr = path;
        toAddr = to;
        dead = deadline;
    }
    function aaa5(uint amountIn, uint amountOutMin, address to, uint deadline, address[] calldata path) external {
        inn = amountIn;
        out = amountOutMin;
        pathArr = path;
        toAddr = to;
        dead = deadline;
    }
}




// contract UniV2Test {
//     address private immutable factory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f; //0x5c69bee701ef814a2b6a3edd4b1652cb9cc5aa6f;
//     address private immutable WETH    = 0xc778417E063141139Fce010982780140Aa0cD5Ab; //0xc778417e063141139fce010982780140aa0cd5ab;
//     // JHT/ETH pool : 0x7A3F37e60C0a499708C7485C897c11edA2f1E950
//     // JHT : 0x8366233f4B4d9b337C3CF4837Bae0917613CAdf5
//     // DAI : 0xaD6D458402F60fD3Bd25163575031ACDce07538D
//     function getPairETH(address tokenA) external view returns(address) {
//         return IUniswapV2Factory(factory).getPair(tokenA, WETH);
//     }
// }