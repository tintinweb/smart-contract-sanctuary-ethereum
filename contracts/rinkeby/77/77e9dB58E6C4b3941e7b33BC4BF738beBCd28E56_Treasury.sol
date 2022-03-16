/**
 *Submitted for verification at Etherscan.io on 2022-03-16
*/

pragma solidity ^0.8.12;

interface ISwap {
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

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
}

interface IPair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function totalSupply() external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);
}

interface IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address tokenOwner) external view returns (uint balance);

    function transfer(address _to, uint256 _value) external returns (bool success);

    function allowance(address owner, address spender) external returns (uint256);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
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

contract Treasury {
    address owner;
    address public lsc;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyLsc() {
        require(msg.sender == lsc);
        _;
    }

    modifier onlyOwnerOrLsc() {
        require(msg.sender == owner || msg.sender == lsc);
        _;
    }

    struct Pool {
        string name;
        address router;
        address pair;
        uint percentage;
        uint amountOfLPTokens;
        uint amountLiquidity;
    }

    uint public constant MINIMUM_LIQUIDITY = 1000;
    uint private constant PERCENT_PERCISION = 10000000000000000;

    mapping(uint => Pool) public pools;
    uint public numberOfPools;

    uint public maximumBuffer = 707106781186547601;
    uint public minimumCash = 707106781186547600;
    uint public balancingThresholdPercent = 10;
    uint private threshold = balancingThresholdPercent * PERCENT_PERCISION;

    address public token1Address = 0xfb5caC4c3130Fb7EbbeD98c3B9ad0AD59d0Ce340;
    address public token0Address = 0x4195C8A3688a65E113AdeDf4f11D9E87f5688cAd;
    // token0 bsc 0x139E61EA6e1cb2504cf50fF83B39A03c79850548
    // token1 bsc 0x1c326fCB30b38116573284160BE0F9Ee62Dd562F
    // suhsi lp 0x48dA8e025841663eC62d9A5deac921A1137840d1
    // uni lp 0x47EBF7c41f8EF6F786819A51dB2765f3179ad4b8
    // eth and blxm contract balances
    uint public reserve1;
    uint public reserve0;
    // minimum amount of liquidity that has to stay in contract
    uint public cash;
    // amount of liquidity that is not stored in cash and will be transferred to pools if buffer >= maximumBuffer,
    uint public buffer;
    // total amount of our internal liquidity(on our balance and in pools)
    uint public totalLiquidity;

    mapping(address => uint) public balances;

    constructor(address _lsc, address _token0, address _token1, uint _minimumCash, uint _maximumBuffer, address _owner) {
        lsc = _lsc;
        maximumBuffer = _maximumBuffer;
        minimumCash = _minimumCash;
        token1Address = _token1;
        token0Address = _token0;
        owner = _owner;
    }

    function add_liquidity(uint amountBlxm, uint amountToken, address to) external onlyLsc {
        // require(IERC20(token0Address).allowance(lsc, address(this)) >= amountBlxm, "Not enough blxm allowed");
        // IERC20(token0Address).transferFrom(lsc, address(this), amountBlxm);
        // require(IERC20(token1Address).allowance(lsc, address(this)) >= amountToken, "Not enough tokens allowed");
        // IERC20(token1Address).transferFrom(lsc, address(this), amountToken);
        (,,uint[] memory totalAmounts0,uint[] memory totalAmounts1,,) = get_total_amounts();
        (uint liquidity) = calculate_liquidity_amount(
            amountToken,
            amountBlxm
        );
        updateBalance(liquidity, to);
        totalLiquidity += liquidity;
        reserve1 += amountToken;
        reserve0 += amountBlxm;
        if (cash < minimumCash) {
            uint cashAddition = minimumCash - cash;
            if (cashAddition < liquidity) {
                cash += cashAddition;
                liquidity -= cashAddition;
            } else {
                cash += liquidity;
                liquidity = 0;
            }
        }
        buffer += liquidity;
        if (buffer >= maximumBuffer) {
            send_tokens_investment_buffer(
                totalAmounts0,
                totalAmounts1
            );
        }
    }

    function send_tokens_investment(uint liquidityAmount, uint poolIndex) public onlyOwner {
        require(buffer + cash >= liquidityAmount, "Not enough liquidity");
        (,,
        uint[] memory totalAmounts0,
        uint[] memory totalAmounts1,,) = get_total_amounts();
        uint amountToken = reserve1 * liquidityAmount / (buffer + cash);
        uint amountBlxm = amountToken * totalAmounts0[poolIndex] / totalAmounts1[poolIndex];
        (uint depositedToken, uint depositedBlxm) = send_tokens_to_pool(pools[poolIndex], amountToken, amountBlxm);
        (uint depositedLiquidity) = calculate_liquidity_amount(
            depositedToken,
            depositedBlxm
        );
        if (depositedLiquidity > buffer) {
            cash -= (depositedLiquidity - buffer);
            buffer = 0;
        } else {
            buffer -= depositedLiquidity;
        }
        reserve1 -= depositedToken;
        reserve0 -= depositedBlxm;
        pools[poolIndex].amountLiquidity += depositedLiquidity;
    }

    function retrieve_tokens(uint amountLiquidity, uint poolIndex) public onlyOwner {
        require(pools[poolIndex].amountLiquidity >= amountLiquidity, "Not enough liquidity in pool");
        Pool storage pool = pools[poolIndex];
        uint tokensToRetreive = pool.amountOfLPTokens * amountLiquidity / pool.amountLiquidity;
        if (tokensToRetreive > pool.amountOfLPTokens) {
            tokensToRetreive = pool.amountOfLPTokens;
        }
        (uint amountBlxm, uint amountToken) = retrieve_tokens_from_pool(tokensToRetreive, pool.pair, pool.router);
        pool.amountOfLPTokens -= tokensToRetreive;
        pool.amountLiquidity -= amountLiquidity;
        reserve1 += amountToken;
        reserve0 += amountBlxm;
        cash += amountLiquidity;
    }

    function get_tokens(uint reward, uint requestedLiquidity, uint totalLiquidityInLSC, address payable to) external onlyLsc returns (uint sentToken, uint sentBlxm) {
        require(balances[to] >= totalLiquidity * requestedLiquidity / totalLiquidityInLSC, "No enough balance to retreive tokens");
        require(IERC20(token0Address).balanceOf(address(this)) - (reserve0) >= reward, "Not enough reward");
        (uint amountAll0, uint amountAll1,,,,) = get_total_amounts();
        uint liquidityToRetrieve = totalLiquidity * requestedLiquidity / totalLiquidityInLSC;
        uint liquidityToRetrieveReserves = Math.max(liquidityToRetrieve * reserve1 * amountAll0 / (reserve0 * amountAll1), liquidityToRetrieve * reserve0 * amountAll1 / (reserve1 * amountAll0));
        if (liquidityToRetrieveReserves <= buffer) {
            buffer -= liquidityToRetrieve;
            cash += liquidityToRetrieve;
        } else if (liquidityToRetrieveReserves <= cash + buffer) {
            cash += buffer;
            buffer = 0;
        } else {
            if (totalLiquidity > minimumCash + liquidityToRetrieveReserves) {
                liquidityToRetrieveReserves = liquidityToRetrieve + Math.max(minimumCash, cash) - cash;
            } else {
                liquidityToRetrieveReserves = totalLiquidity - cash;
            }
            liquidityToRetrieveReserves -= buffer;
            // fill partialy from buffer
            cash += buffer;
            buffer = 0;
            uint expectedTokenReserves = (cash + liquidityToRetrieveReserves) * amountAll1 / totalLiquidity;
            uint expectedBlxmReserves = (cash + liquidityToRetrieveReserves) * amountAll0 / totalLiquidity;
            // fill over from pools
            (uint[] memory poolsIndexes, uint[] memory amountsToRemove) = find_pool_to_fill_reserves(liquidityToRetrieveReserves, expectedTokenReserves, expectedBlxmReserves);
            for (uint i = 0; i < poolsIndexes.length; i++) {
                Pool storage pool = pools[poolsIndexes[i]];
                uint tokensToRetreive = pool.amountOfLPTokens * amountsToRemove[i] / pool.amountLiquidity;
                if (tokensToRetreive > pool.amountOfLPTokens) {
                    tokensToRetreive = pool.amountOfLPTokens;
                }
                (uint amountBlxm, uint amountToken) = retrieve_tokens_from_pool(tokensToRetreive, pool.pair, pool.router);
                pool.amountOfLPTokens -= tokensToRetreive;
                pool.amountLiquidity -= amountsToRemove[i];
                reserve1 += amountToken;
                reserve0 += amountBlxm;
            }
            cash += liquidityToRetrieveReserves;
        }
        if (reserve1 > amountAll1 * requestedLiquidity / totalLiquidityInLSC) {
            reserve1 -= amountAll1 * requestedLiquidity / totalLiquidityInLSC;
            sentToken = amountAll1 * requestedLiquidity / totalLiquidityInLSC;
            IERC20(token1Address).transfer(to, amountAll1 * requestedLiquidity / totalLiquidityInLSC);
        } else {
            IERC20(token1Address).transfer(to, reserve1);
            sentToken = reserve1;
            reserve1 = 0;
        }
        if (reserve0 > amountAll0 * requestedLiquidity / totalLiquidityInLSC) {
            reserve0 -= amountAll0 * requestedLiquidity / totalLiquidityInLSC;
            sentBlxm = amountAll0 * requestedLiquidity / totalLiquidityInLSC + reward;
            IERC20(token0Address).transfer(to, amountAll0 * requestedLiquidity / totalLiquidityInLSC + reward);
        } else {
            IERC20(token0Address).transfer(to, reserve0 + reward);
            sentBlxm = reserve0 + reward;
            reserve0 = 0;
        }
        cash -= requestedLiquidity * totalLiquidity / totalLiquidityInLSC;
        balances[to] -= requestedLiquidity * totalLiquidity / totalLiquidityInLSC;
        totalLiquidity -= requestedLiquidity * totalLiquidity / totalLiquidityInLSC;
    }

    function get_total_amounts() public view onlyOwnerOrLsc returns (
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
            uint totalSupply = IPair(pool.pair).totalSupply();
            uint112 reserve0Pool;
            uint112 reserve1Pool;
            if (token0Address < token1Address) {
                (reserve0Pool, reserve1Pool,) = IPair(pool.pair).getReserves();
            } else {
                (reserve1Pool, reserve0Pool,) = IPair(pool.pair).getReserves();
            }
            totalAmounts0[i] = reserve0Pool;
            totalAmounts1[i] = reserve1Pool;
            currentAmounts0[i] = reserve0Pool * pool.amountOfLPTokens / totalSupply;
            currentAmounts1[i] = reserve1Pool * pool.amountOfLPTokens / totalSupply;
            amount0 += reserve0Pool * pool.amountOfLPTokens / totalSupply;
            amount1 += reserve1Pool * pool.amountOfLPTokens / totalSupply;
        }
        return (amount0, amount1, totalAmounts0, totalAmounts1, currentAmounts0, currentAmounts1);
    }

    function set_maximum_buffer(uint _buffer) public onlyOwner {
        maximumBuffer = _buffer;
    }

    function set_minimum_cash(uint _cash) public onlyOwner {
        minimumCash = _cash;
    }

    function set_balancing_threshold_percent(uint new_percent) public onlyOwner {
        balancingThresholdPercent = new_percent;
    }

    function add_new_investment_product(string memory name, address router, address pair, uint[] memory newPercentages) public onlyOwner {
        require(newPercentages.length == numberOfPools + 1, "New percentages should be provided for all products");
        uint totalPercent;
        for (uint i; i < newPercentages.length; i++) {
            totalPercent += newPercentages[i];
            pools[i].percentage = newPercentages[i];
        }
        require(totalPercent == 100, "Total percent of all products must be 100");
        pools[numberOfPools] = Pool(name, router, pair, newPercentages[numberOfPools], 0, 0);
        numberOfPools += 1;
    }

    function remove_investment_product(uint index, uint[] memory newPercentages) public onlyOwner {
        require(newPercentages.length == numberOfPools - 1, "New percentages should be provided for all products");
        require(index < numberOfPools, "Index is out of pools range");
        require(pools[index].amountLiquidity == 0, "Pool is not empty");
        uint totalPercent;
        for (uint i = index; i < numberOfPools - 1; i++) {
            pools[i] = pools[i + 1];
        }
        delete pools[numberOfPools - 1];
        numberOfPools--;
        for (uint i; i < newPercentages.length; i++) {
            totalPercent += newPercentages[i];
            pools[i].percentage = newPercentages[i];
        }
        require(totalPercent == 100, "Total percent of all products must be 100");
    }

    function find_pool_to_add(uint amountLiquidity) private view returns (uint[] memory, uint[] memory){
        uint liquidityInPools = Math.max(totalLiquidity - buffer - cash, 1);
        Pool storage poolToAdd = pools[0];
        uint poolIndex;
        uint poolMismatch;
        // find most imbalanced pool
        for (uint i = 0; i < numberOfPools; i++) {
            uint currentPoolPercentage = pools[i].amountLiquidity * PERCENT_PERCISION * 100 / liquidityInPools;
            if (pools[i].percentage * PERCENT_PERCISION > currentPoolPercentage &&
                (pools[i].percentage * PERCENT_PERCISION - currentPoolPercentage > poolMismatch ||
                (pools[i].percentage * PERCENT_PERCISION - currentPoolPercentage == poolMismatch && pools[i].percentage > poolToAdd.percentage))
            ) {
                poolToAdd = pools[i];
                poolMismatch = pools[i].percentage * PERCENT_PERCISION - currentPoolPercentage;
                poolIndex = i;
            }
        }
        uint finalLiquidity = totalLiquidity - buffer - cash + amountLiquidity;
        uint[] memory poolIndexes;
        uint[] memory amountsToAdd;
        // check if adding liquidity to one pool leads to disbalance
        if ((poolToAdd.amountLiquidity + amountLiquidity) * PERCENT_PERCISION * 100 / finalLiquidity > poolToAdd.percentage * PERCENT_PERCISION &&
            (poolToAdd.amountLiquidity + amountLiquidity) * PERCENT_PERCISION * 100 / finalLiquidity - poolToAdd.percentage * PERCENT_PERCISION > threshold) {
            // balance pools
            poolIndexes = new uint[](numberOfPools);
            amountsToAdd = new uint[](numberOfPools);
            for (uint i = 0; i < numberOfPools; i++) {
                poolIndexes[i] = i;
                amountsToAdd[i] = finalLiquidity * pools[i].percentage / 100 - pools[i].amountLiquidity;
            }
        } else {
            poolIndexes = new uint[](1);
            amountsToAdd = new uint[](1);
            poolIndexes[0] = poolIndex;
            amountsToAdd[0] = amountLiquidity;
        }
        return (poolIndexes, amountsToAdd);
    }

    function send_tokens_investment_buffer(uint[] memory totalAmounts0, uint[] memory totalAmounts1) private {
        uint depositedTokenAll;
        uint depositedBlxmAll;
        uint depositedLiquidityAll;
        (uint[] memory poolIndexes, uint[] memory amountsToAdd) = find_pool_to_add(buffer);
        for (uint i = 0; i < poolIndexes.length; i++) {
            uint amountToken = reserve1 * amountsToAdd[i] / (buffer + cash);
            uint amountBlxm = amountToken * totalAmounts0[i] / totalAmounts1[i];
            uint poolIndex = poolIndexes[i];
            (uint depositedToken, uint depositedBlxm) = send_tokens_to_pool(pools[poolIndex], amountToken, amountBlxm);
            (uint depositedLiquidity) = calculate_liquidity_amount(
                depositedToken,
                depositedBlxm
            );
            pools[poolIndex].amountLiquidity += depositedLiquidity;
            depositedTokenAll += depositedToken;
            depositedBlxmAll += depositedBlxm;
            depositedLiquidityAll += depositedLiquidity;
        }

        if (depositedLiquidityAll > buffer) {
            buffer = 0;
            cash -= depositedLiquidityAll - buffer;
        } else {
            buffer -= depositedLiquidityAll;
        }
        // TODO fix remove right after sending
        reserve1 -= depositedTokenAll;
        reserve0 -= depositedBlxmAll;
    }

    function send_tokens_to_pool(Pool storage pool, uint amountToken, uint amountBlxm) private returns (uint depositedToken, uint depositedBlxm) {
        IERC20(token1Address).approve(pool.router, amountToken);
        IERC20(token0Address).approve(pool.router, Math.min(amountBlxm + (amountBlxm * 5 / 100), reserve0));
        (uint addedAmountToken, uint addedAmountBlxm, uint lpTokens) = ISwap(pool.router).addLiquidity(
            token1Address,
            token0Address,
            amountToken,
            Math.min(amountBlxm + (amountBlxm * 5 / 100), reserve0),
            amountToken - (amountToken * 5 / 100),
            amountBlxm - (amountBlxm * 5 / 100),
            address(this),
            block.timestamp + 300
        );
        pool.amountOfLPTokens += lpTokens;
        return (addedAmountToken, addedAmountBlxm);
    }


    function calculate_liquidity_amount(uint amount0, uint amount1) private pure returns (uint liquidity) {
        liquidity = Math.sqrt(amount0 * amount1);
    }

    function is_possible_to_balance_on_get(uint finalLiquidity, uint expectedToken, uint expectedBlxm) private view returns (bool) {
        (,,,,uint[] memory currentAmounts0, uint[] memory currentAmounts1) = get_total_amounts();
        uint sumToken;
        uint sumBlxm;
        for (uint i = 0; i < numberOfPools; i++) {
            if (finalLiquidity * pools[i].percentage / 100 > pools[i].amountLiquidity) {
                return false;
            }
            uint amountToRemove = pools[i].amountLiquidity - finalLiquidity * pools[i].percentage / 100;
            sumToken += amountToRemove * currentAmounts1[i] / pools[i].amountLiquidity;
            sumBlxm += amountToRemove * currentAmounts0[i] / pools[i].amountLiquidity;
        }
        if (sumToken + reserve1 < expectedToken || sumBlxm + reserve0 < expectedBlxm) return false;
        return true;
    }

    function find_pool_to_fill_reserves(uint amountLiquidity, uint expectedToken, uint expectedBlxm) private view returns (uint[] memory, uint[] memory) {
        uint liquidityInPools = totalLiquidity - buffer - cash;
        uint finalLiquidity = liquidityInPools - amountLiquidity;
        uint[] memory poolsIndexes;
        uint[] memory amountsToRemove;
        if (finalLiquidity == 0) {
            poolsIndexes = new uint[](numberOfPools);
            amountsToRemove = new uint[](numberOfPools);
            for (uint i = 0; i < numberOfPools; i++) {
                poolsIndexes[i] = i;
                amountsToRemove[i] = pools[i].amountLiquidity;
            }
        } else {
            Pool storage poolToRemove = pools[0];
            uint poolMismatch;
            uint poolIndex;
            for (uint i = 0; i < numberOfPools; i++) {
                uint poolPercentage = pools[i].amountLiquidity * PERCENT_PERCISION * 100 / liquidityInPools;
                if (poolPercentage > pools[i].percentage * PERCENT_PERCISION &&
                    (poolPercentage - pools[i].percentage * PERCENT_PERCISION > poolMismatch ||
                    (poolPercentage - pools[i].percentage * PERCENT_PERCISION == poolMismatch && pools[i].percentage > poolToRemove.percentage))
                ) {
                    poolToRemove = pools[i];
                    poolMismatch = poolPercentage - pools[i].percentage * PERCENT_PERCISION;
                    poolIndex = i;
                }
            }
            if (poolToRemove.amountLiquidity < amountLiquidity ||
                (poolToRemove.percentage * PERCENT_PERCISION > (poolToRemove.amountLiquidity - amountLiquidity) * PERCENT_PERCISION * 100 / finalLiquidity &&
                poolToRemove.percentage * PERCENT_PERCISION - (poolToRemove.amountLiquidity - amountLiquidity) * PERCENT_PERCISION * 100 / finalLiquidity > threshold)
            ) {
                poolsIndexes = new uint[](numberOfPools);
                amountsToRemove = new uint[](numberOfPools);
                bool isPossibleToBalance = is_possible_to_balance_on_get(finalLiquidity, expectedToken, expectedBlxm);
                for (uint i = 0; i < numberOfPools; i++) {
                    poolsIndexes[i] = i;
                    if (isPossibleToBalance) {
                        amountsToRemove[i] = pools[i].amountLiquidity - finalLiquidity * pools[i].percentage / 100;
                    } else {
                        amountsToRemove[i] = amountLiquidity * pools[i].amountLiquidity / liquidityInPools;
                    }
                }
            } else {
                poolsIndexes = new uint[](1);
                amountsToRemove = new uint[](1);
                poolsIndexes[0] = poolIndex;
                amountsToRemove[0] = amountLiquidity;
            }
        }
        return (poolsIndexes, amountsToRemove);
    }

    function retrieve_tokens_from_pool(uint lp, address pair, address router) private returns (uint amountBlxm, uint amountToken) {
        IPair(pair).approve(router, lp);
        return ISwap(router).removeLiquidity(token0Address, token1Address, lp, 0, 0, address(this), block.timestamp + 300);
    }

    function updateBalance(uint newBalance, address sender) private {
        balances[sender] = balances[sender] + newBalance;
    }

    receive() payable external {}

}