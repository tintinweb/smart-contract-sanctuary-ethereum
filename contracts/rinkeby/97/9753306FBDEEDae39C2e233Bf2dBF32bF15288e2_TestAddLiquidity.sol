/**
 *Submitted for verification at Etherscan.io on 2022-02-03
*/

pragma solidity ^0.7.2;

interface ISwap {
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);

    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
}

interface IPair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

interface IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address tokenOwner) external view returns (uint balance);

    function transfer(address _to, uint256 _value) external returns (bool success);

    function totalSupply() external view returns (uint256);
}

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

library Math {
    function min(uint x, uint y) internal pure returns (uint z) {
        z = x < y ? x : y;
    }

    function max(uint x, uint y) internal pure returns (uint z) {
        z = x > y ? x : y;
    }

    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

contract TestAddLiquidity {
    using SafeMath for uint;

    struct Pool {
        string name;
        address router;
        address pair;
        uint percentage;
        uint amountOfLPTokens;
    }

    mapping(uint => Pool) public pools;
    uint public numberOfPools;
    // test token address
    address internal constant TOKEN_ADRESS = 0xfb5caC4c3130Fb7EbbeD98c3B9ad0AD59d0Ce340;
    uint public UNISWAP_PERSENTAGE = 70;
    uint public SUSHISWAP_PERSENTAGE = 30;
    // need to find best variants for this numbers
    uint public MAXIMUM_BUFER = 707106780186547500;
    uint public MINIMUM_CASH = 707106781186547500;
    uint public MINIMUM_LIQUIDITY = 1000;
    // eth and blxm contract balances
    uint public reserve0;
    uint public reserve1;
    // minimum amount of liquidity that has to stay in contract
    uint public cash;
    // amount of liquidity that is not stored in cash and will be transferred to pools if buffer >= MAXIMUM_BUFER,
    uint public buffer;
    // total amount of our internal liquidity(on our balance and in pools)
    uint public totalLiquidity;

    mapping(address => uint) public balances;

    constructor() public {
        pools[0] = Pool(
            "Uniswap",
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D,
        // test pair address
            0x0D52297D95F66f7069C1B5fA48897a33Bf72dB36,
            70,
            0
        );
        pools[1] = Pool(
            "Sushiswap",
            0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506,
        // test pair address
            0x81aaAc709ACA097970409d9579824c1F8541e5Bf,
            30,
            0
        );
        numberOfPools = 2;
    }

    function updateBalance(uint newBalance, address sender) private {
        balances[sender] = balances[sender] + newBalance;
    }

    function add_liquidity(uint amountToken, uint amountETH, address to) external payable {
        require(msg.value == amountETH, "Not enough eth sent");
        // TODO transfer blxm from LSC
        (uint amount0,
        uint amount1,
        uint[] memory totalAmounts0,
        uint[] memory totalAmounts1,,) = get_total_amounts();
        (uint liquidity) = calculate_liquidity_amount(
            amountETH,
            amountToken,
            amount0,
            amount1
        );
        updateBalance(liquidity, to);
        totalLiquidity += liquidity;
        reserve0 += amountETH;
        reserve1 += amountToken;
        if (cash < MINIMUM_CASH) {
            uint cashAddition = MINIMUM_CASH - cash;
            if (cashAddition < liquidity) {
                cash += cashAddition;
                liquidity -= cashAddition;
            } else {
                cash += liquidity;
                liquidity = 0;
            }
        }
        buffer += liquidity;
        if (buffer >= MAXIMUM_BUFER) {
            amount0 += amountETH;
            amount1 += amountToken;
            send_tokens_investment(
                amount0,
                amount1,
                totalAmounts0,
                totalAmounts1
            );
        }
    }
    // TODO change the signature according to documentation(for now it looks like this for testing purposes)
    function send_tokens_investment(uint amount0, uint amount1, uint[] memory totalAmounts0, uint[] memory totalAmounts1) private {
        uint depositedEthAll;
        uint depositedTokenAll;
        uint depositedLiquidityAll;
        for (uint i = 0; i < numberOfPools; i++) {
            Pool storage pool = pools[i];
            (uint depositedETH, uint depositedToken) = send_tokens_to_pool(pool, totalAmounts0[i], totalAmounts1[i]);
            (uint depositedLiquidity) = calculate_liquidity_amount(
                depositedETH,
                depositedToken,
                amount0,
                amount1
            );
            depositedEthAll += depositedETH;
            depositedTokenAll += depositedToken;
            depositedLiquidityAll += depositedLiquidity;
        }
        if (depositedLiquidityAll > buffer) {
            buffer = 0;
            cash -= depositedLiquidityAll - buffer;
        } else {
            buffer -= depositedLiquidityAll;
        }
        reserve0 -= depositedEthAll;
        reserve1 -= depositedTokenAll;
    }

    function send_tokens_to_pool(Pool storage pool, uint totalAmount0, uint totalAmount1) private returns (uint depositedETH, uint depositedToken) {
        uint valueETH = (reserve0.mul(buffer) / totalLiquidity).mul(pool.percentage) / 100;
        uint valueTok = valueETH.mul(totalAmount1) / totalAmount0;
        IERC20(TOKEN_ADRESS).approve(pool.router, valueTok);
        (uint amountToken, uint amountETH, uint lpTokens) = ISwap(pool.router).addLiquidityETH{value : valueETH}(
            TOKEN_ADRESS,
            valueTok.add(valueTok * 5 / 100),
            valueTok.sub(valueTok * 5 / 100),
            valueETH,
            address(this),
            block.timestamp + 300
        );
        pool.amountOfLPTokens += lpTokens;
        return (amountETH, amountToken);
    }

    // TODO change the signature according to documentation(for now it looks like this for testing purposes)
    function retrieve_tokens(uint lp, address pair, address router) internal returns (uint amountToken, uint amountETH) {
        IERC20(pair).approve(router, lp);
        return ISwap(router).removeLiquidityETH(TOKEN_ADRESS, lp, 0, 0, address(this), block.timestamp + 300);
    }

    // TODO refactor this function(add send_tokens_investors() function)
    function get_tokens(uint reward, uint percent, address payable to) external {
        // require(balances[to] >= percent.mul(totalLiquidity) / 100, "No enough balance to retreive tokens");
        require(IERC20(TOKEN_ADRESS).balanceOf(address(this)).sub(reserve1) >= reward, "Not enough reward");
        (uint amountAll0,
        uint amountAll1,,,
        uint[] memory currentAmounts0,
        uint[] memory currentAmounts1) = get_total_amounts();
        uint liquidityToRetrieve = totalLiquidity.mul(percent) / 100;
        if (cash < liquidityToRetrieve) {
            if (liquidityToRetrieve >= totalLiquidity - cash) {
                liquidityToRetrieve = totalLiquidity - cash;
            } else if (cash < MINIMUM_CASH) {
                if (totalLiquidity - cash > MINIMUM_CASH - cash + liquidityToRetrieve) {
                    liquidityToRetrieve += MINIMUM_CASH - cash;
                } else {
                    liquidityToRetrieve = totalLiquidity - cash;
                }   
            }
            uint retreiveETH = amountAll0.mul(liquidityToRetrieve) / totalLiquidity;
            uint retreiveTok = amountAll1.mul(liquidityToRetrieve) / totalLiquidity;
            for (uint i = 0; i < numberOfPools; i++) {
                Pool storage pool = pools[i];
                uint tokensToRetreive = Math.max(
                    (pool.amountOfLPTokens.mul(retreiveETH).mul(pool.percentage)) / (currentAmounts0[i].mul(100)),
                    (pool.amountOfLPTokens.mul(retreiveTok).mul(pool.percentage)) / (currentAmounts1[i].mul(100))
                );
                if (tokensToRetreive > pool.amountOfLPTokens) {
                    tokensToRetreive = pool.amountOfLPTokens;
                }
                (uint amountToken, uint amountETH) = retrieve_tokens(tokensToRetreive, pool.pair, pool.router);
                pool.amountOfLPTokens -= tokensToRetreive;
                reserve0 += amountETH;
                reserve1 += amountToken;
            }
            cash += liquidityToRetrieve;
        }
        if(reserve0 > amountAll0.mul(percent) / 100) {
            reserve0 -= amountAll0.mul(percent) / 100;
            to.transfer(amountAll0.mul(percent) / 100);
        } else {
            to.transfer(reserve0);
            reserve0 = 0;
        }
        if(reserve1 > amountAll1.mul(percent) / 100) {
            reserve1 -= amountAll1.mul(percent) / 100;
            IERC20(TOKEN_ADRESS).transfer(to, amountAll1.mul(percent) / 100 + reward);
        } else {
            IERC20(TOKEN_ADRESS).transfer(to, reserve1 + reward);
            reserve1 = 0;
        }
        cash -= percent.mul(totalLiquidity) / 100;
        // balances[to] -= percent.mul(totalLiquidity) / 100;
        totalLiquidity -= percent.mul(totalLiquidity) / 100;
    }

    function get_total_amounts() public view returns (
        uint amount0,
        uint amount1,
        uint[] memory,
        uint[] memory,
        uint[] memory,
        uint[] memory
    ) {
        uint[] memory totalAmounts0 = new uint[](numberOfPools);
        uint[] memory totalAmounts1 = new uint[](numberOfPools);
        uint[] memory currentAmounts0 = new uint[](numberOfPools);
        uint[] memory currentAmounts1 = new uint[](numberOfPools);
        amount0 = reserve0;
        amount1 = reserve1;
        for (uint i = 0; i < numberOfPools; i++) {
            Pool storage pool = pools[i];
            uint totalSupply = IERC20(pool.pair).totalSupply();
            (uint112 reserve0Pool, uint112 reserve1Pool,) = IPair(pool.pair).getReserves();
            totalAmounts0[i] = reserve0Pool;
            totalAmounts1[i] = reserve1Pool;
            currentAmounts0[i] = reserve0Pool * pool.amountOfLPTokens / totalSupply;
            currentAmounts1[i] = reserve1Pool * pool.amountOfLPTokens / totalSupply;
            amount0 += reserve0Pool * pool.amountOfLPTokens / totalSupply;
            amount1 += reserve1Pool * pool.amountOfLPTokens / totalSupply;
        }
        return (amount0, amount1, totalAmounts0, totalAmounts1, currentAmounts0, currentAmounts1);
    }

    function set_maximum_buffer(uint new_buffer) public {
        MAXIMUM_BUFER = new_buffer;
    }

    function set_minimum_cash(uint new_cash) public {
        MINIMUM_CASH = new_cash;
    }


    function calculate_liquidity_amount(uint amount0, uint amount1, uint amountAll0, uint amountAll1) public view returns (uint liquidity) {
        if (totalLiquidity == 0) {
            liquidity = Math.sqrt(amount0.mul(amount1)).sub(MINIMUM_LIQUIDITY);
        } else {
            liquidity = Math.min(amount0.mul(totalLiquidity) / amountAll0, amount1.mul(totalLiquidity) / amountAll1);
        }
    }

    function add_new_investment_product(string memory name, address router, address pair, uint[] memory newPercentages) public {
        require(newPercentages.length == numberOfPools + 1, "New percentages should be provided for all products");
        uint totalPercent;
        for(uint i; i < newPercentages.length; i++){
            totalPercent += newPercentages[i];
        }
        require(totalPercent == 100, "Total percent of all products must be 100");
        pools[numberOfPools] = Pool(name, router, pair, newPercentages[numberOfPools], 0);
        numberOfPools += 1;
    }

    receive() payable external {}

}