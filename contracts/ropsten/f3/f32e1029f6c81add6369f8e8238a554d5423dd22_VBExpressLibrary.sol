/**
 *Submitted for verification at Etherscan.io on 2022-05-17
*/

//SPDX-License-Identifier: MIT
pragma solidity =0.8.13;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
interface IVBExpressFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function getPair(address tokenA, address tokenB, uint24 kA, uint24 kB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB, uint24 kA, uint24 kB) external returns (address pair);
}

interface IVBExpressPair{
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Mint(address indexed sender, uint256 liquidity);
    event Burn(address indexed sender, uint256 amount0, address indexed to);
    event Withdraw(address indexed sender, uint256 amount1, address indexed to);
    event Express(
        address indexed sender,
        uint256 amount1In,
        uint256 amount0Out,
        address indexed to,
        address indexed assigned
    );
    event Sync(uint256 reserve0, uint256 reserve1);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    function MINIMUM_LIQUIDITY() external view returns (uint256);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function prioritizedToken1Of(address account) external view returns (uint256);

    function getReserve0() external view returns (uint256 _reserve0, uint32 _blockTimestampLast);

    function getReserve1() external view returns (uint256 _reserve1, uint32 _blockTimestampLast);

    // called once by the factory at time of deployment
    function initialize(address _token0, address _token1, uint24 _k0, uint24 _k1) external;

    // this low-level function should be called from a contract which performs important safety checks
    function mint(address to) external returns (uint256 amount0);

    // this low-level function should be called from a contract which performs important safety checks
    function burn(address to) external returns (uint256 burnedAmount);

    // this low-level function should be called from a contract which performs important safety checks
    function withdraw(address to) external returns (uint256 burnedAmount, uint256 withdrawedAmount);

    // this low-level function should be called from a contract which performs important safety checks
    function express(uint256 amount0Out, uint256 amount1In, address to, bytes calldata data) external;

    function expressWithAssign(uint256 amount0Out, uint256 amount1In, address to, address assigned, bytes calldata data) external;
}
library VBExpressLibrary {
    //using SafeMath for uint;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB, uint24 kA, uint24 kB) internal pure returns (address token0, address token1, uint24 k0, uint24 k1) {
        require(tokenA != tokenB, "VBExpressLibrary: IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        (k0, k1) = tokenA < tokenB ? (kA, kB) : (kB, kA);
        require(token0 != address(0), "VBExpressLibrary: ZERO_ADDRESS");
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB, uint24 kA, uint24 kB) public pure returns (address pair) {
        (address token0, address token1, uint24 k0, uint24 k1) = sortTokens(tokenA, tokenB, kA, kB);
        pair = address(uint160(uint256(keccak256(abi.encodePacked(
                hex"ff",
                factory,
                keccak256(abi.encodePacked(token0, token1, k0, k1)),
                hex"38d3ae982c158b1927bcaf882724e011b3810d6a495b20213f7ec7e0c6e5d25a" // init code hash
            )))));
    }

    // fetches and sorts the reserves for a pair
    // Lấy lượng tokenA dự trữ còn khả năng giao dịch trong pair
    function getReserve0(address factory, address tokenA, address tokenB, uint24 kA, uint24 kB) internal view returns (uint256 reserveA) {
        (reserveA,) = IVBExpressPair(pairFor(factory, tokenA, tokenB, kA, kB)).getReserve0();
    }

    function getReserve1(address factory, address tokenA, address tokenB, uint24 kA, uint24 kB) internal view returns (uint256 reserveB) {
        (reserveB,) = IVBExpressPair(pairFor(factory, tokenA, tokenB, kA, kB)).getReserve1();
    }

    function prioritizedToken1Of(address factory, address tokenA, address tokenB, uint24 kA, uint24 kB, address account) external view returns (uint256) {
        return IVBExpressPair(pairFor(factory, tokenA, tokenB, kA, kB)).prioritizedToken1Of(account);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    // Tính toán số lượng token A cần Nạp vào pair để nhận được lượng token B mong muốn
    function getAmountIn(uint256 amountB, uint24 kA, uint24 kB) internal pure returns (uint amountA) {
        require(amountB > 0, "VBExpressLibrary: INSUFFICIENT_AMOUNT");
        require(kA > 0 && kB > 0, "VBExpressLibrary: INSUFFICIENT_RATIO");
        amountA = amountB*kA/kB;
    }
    
    // Tính toán số lượng token B nhận được với số lượng token A nạp vào
    function getAmountOut(uint256 amountA, uint24 kA, uint24 kB) internal pure returns (uint amountB) {
        require(amountA > 0, "VBExpressLibrary: INSUFFICIENT_AMOUNT");
        require(kA > 0 && kB > 0, "VBExpressLibrary: INSUFFICIENT_RATIO");
        amountB = amountA*kB/kA;
    }
}