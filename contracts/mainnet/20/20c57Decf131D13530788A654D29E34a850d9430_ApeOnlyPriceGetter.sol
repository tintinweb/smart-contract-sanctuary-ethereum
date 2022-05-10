// SPDX-License-Identifier: MIT
pragma solidity =0.6.6;

import '../interfaces/IApePair.sol';
import '../interfaces/IApeFactory.sol';
import '../interfaces/IERC20.sol';

// This library provides simple price calculations for ApeSwap tokens, accounting
// for commonly used pairings. Will break if USDC goes far off peg.
// Should NOT be used as the sole oracle for sensitive calculations such as 
// liquidation, as it is vulnerable to manipulation by flash loans, etc. BETA
// SOFTWARE, PROVIDED AS IS WITH NO WARRANTIES WHATSOEVER.

// ApeSwap only version
library ApeOnlyPriceGetter {
    address public constant FACTORY = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f; //Uniswap Factory

    //All returned prices calculated with this precision (18 decimals)
    uint private constant PRECISION = 10**DECIMALS; //1e18 == $1
    uint public constant DECIMALS = 18;

    //Token addresses
    address constant NATIVE = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    //Token value constants
    uint private constant USDC_RAW_PRICE = 1e6;

    //Ape LP addresses
    address constant USDC_NATIVE_PAIR = 0xB4e16d0168e52d35CaCD2c6185b44281Ec28C9Dc; // usdc is token0

    //Normalized to specified number of decimals based on token's decimals and
    //specified number of decimals
    function getPrice(address token, uint _decimals) external view returns (uint) {
        return normalize(getRawPrice(token), token, _decimals);
    }

    function getLPPrice(address token, uint _decimals) external view returns (uint) {
        return normalize(getRawLPPrice(token), token, _decimals);
    }

    function getPrices(address[] calldata tokens, uint _decimals) external view returns (uint[] memory prices) {
        prices = getRawPrices(tokens);

        for (uint i; i < prices.length; i++) {
            prices[i] = normalize(prices[i], tokens[i], _decimals);
        }
    }

    function getLPPrices(address[] calldata tokens, uint _decimals) external view returns (uint[] memory prices) {
        prices = getRawLPPrices(tokens);

        for (uint i; i < prices.length; i++) {
            prices[i] = normalize(prices[i], tokens[i], _decimals);
        }
    }

    //returns the price of any token in USD based on common pairings; zero on failure
    function getRawPrice(address token) public view returns (uint) {
        uint pegPrice = pegTokenPrice(token);
        if (pegPrice != 0) return pegPrice;

        return getRawPrice(token, getNativePrice());
    }

    //returns the prices of multiple tokens, zero on failure
    function getRawPrices(address[] memory tokens) public view returns (uint[] memory prices) {
        prices = new uint[](tokens.length);
        uint nativePrice = getNativePrice();

        for (uint i; i < prices.length; i++) {
            address token = tokens[i];

            uint pegPrice = pegTokenPrice(token, nativePrice);
            if (pegPrice != 0) prices[i] = pegPrice;
            else prices[i] = getRawPrice(token, nativePrice);
        }
    }

    //returns the value of a LP token if it is one, or the regular price if it isn't LP
    function getRawLPPrice(address token) internal view returns (uint) {
        uint pegPrice = pegTokenPrice(token);
        if (pegPrice != 0) return pegPrice;

        return getRawLPPrice(token, getNativePrice());
    }

    //returns the prices of multiple tokens which may or may not be LPs
    function getRawLPPrices(address[] memory tokens) internal view returns (uint[] memory prices) {
        prices = new uint[](tokens.length);
        uint nativePrice = getNativePrice();

        for (uint i; i < prices.length; i++) {
            address token = tokens[i];

            uint pegPrice = pegTokenPrice(token, nativePrice);
            if (pegPrice != 0) prices[i] = pegPrice;
            else prices[i] = getRawLPPrice(token, nativePrice);
        }
    }

    //returns the current USD price of ETH based on primary stablecoin pairs
    function getNativePrice() public view returns (uint) {
        (uint usdcReserve, uint nativeReserve1,) = IApePair(USDC_NATIVE_PAIR).getReserves();
        uint nativeTotal = nativeReserve1;
        uint usdTotal = usdcReserve;
    
        return usdTotal * PRECISION / USDC_RAW_PRICE / nativeTotal;
    }

    //Calculate LP token value in USD. Generally compatible with any UniswapV2 pair but will always price underlying
    //tokens using ape prices. If the provided token is not a LP, it will attempt to price the token as a
    //standard token. This is useful for MasterChef farms which stake both single tokens and pairs
    function getRawLPPrice(address lp, uint nativePrice) internal view returns (uint) {
        //if not a LP, handle as a standard token
        try IApePair(lp).getReserves() returns (uint112 reserve0, uint112 reserve1, uint32) {
            address token0 = IApePair(lp).token0();
            address token1 = IApePair(lp).token1();
            uint totalSupply = IApePair(lp).totalSupply();

            //price0*reserve0+price1*reserve1
            uint totalValue = getRawPrice(token0, nativePrice) * reserve0 + getRawPrice(token1, nativePrice) * reserve1;

            return totalValue / totalSupply;

        } catch {
            return getRawPrice(lp, nativePrice);
        }
    }

    // checks for primary tokens and returns the correct predetermined price if possible, otherwise calculates price
    function getRawPrice(address token, uint nativePrice) internal view returns (uint rawPrice) {
        uint pegPrice = pegTokenPrice(token, nativePrice);
        if (pegPrice != 0) return pegPrice;

        uint numTokens;
        uint pairedValue;
        uint lpTokens;
        uint lpValue;

        (lpTokens, lpValue) = pairTokensAndValue(token, NATIVE);
        numTokens += lpTokens;
        pairedValue += lpValue;

        (lpTokens, lpValue) = pairTokensAndValue(token, USDC);
        numTokens += lpTokens;
        pairedValue += lpValue;

        if (numTokens > 0) return pairedValue / numTokens;
    }

    //if one of the peg tokens, returns that price, otherwise zero
    function pegTokenPrice(address token, uint nativePrice) private pure returns (uint) {
        if (token == USDC) return USDC_RAW_PRICE;
        if (token == NATIVE) return nativePrice;
        return 0;
    }

    function pegTokenPrice(address token) private view returns (uint) {
        if (token == USDC) return USDC_RAW_PRICE;
        if (token == NATIVE) return getNativePrice();
        return 0;
    }

    //returns the number of tokens and the USD value within a single LP. peg is one of the listed primary, pegPrice is the predetermined USD value of this token
    function pairTokensAndValue(address token, address peg) private view returns (uint tokenNum, uint pegValue) {
        address tokenPegPair = pairFor(token, peg);

        // if the address has no contract deployed, the pair doesn't exist
        uint256 size;
        assembly { size := extcodesize(tokenPegPair) }
        if (size == 0) return (0,0);

        try IApePair(tokenPegPair).getReserves() returns (uint112 reserve0, uint112 reserve1, uint32) {
            uint reservePeg;
            (tokenNum, reservePeg) = token < peg ? (reserve0, reserve1) : (reserve1, reserve0);
            pegValue = reservePeg * pegTokenPrice(peg);
        } catch {
            return (0,0);
        }
    }

    //normalize a token price to a specified number of decimals
    function normalize(uint price, address token, uint _decimals) private view returns (uint) {
        uint tokenDecimals;

        try IERC20(token).decimals() returns (uint8 dec) {
            tokenDecimals = dec;
        } catch {
            tokenDecimals = 18;
        }

        if (tokenDecimals + _decimals <= 2*DECIMALS) return price / 10**(2*DECIMALS - tokenDecimals - _decimals);
        else return price * 10**(_decimals + tokenDecimals - 2*DECIMALS);
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address tokenA, address tokenB) private view returns (address pair) {
        IApeFactory factory = IApeFactory(FACTORY);
        return factory.getPair(tokenA, tokenB);
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

pragma solidity >=0.6.6;

interface IApePair {
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

pragma solidity >=0.6.6;

interface IApeFactory {
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