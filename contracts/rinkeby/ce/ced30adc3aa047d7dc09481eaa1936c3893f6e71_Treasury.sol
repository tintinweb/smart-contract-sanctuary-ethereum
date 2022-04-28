pragma solidity ^0.8.12;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./ISwap.sol";
import "./IPair.sol";
import "./IERC20.sol";
import "./Math.sol";


contract Treasury is Initializable, UUPSUpgradeable, OwnableUpgradeable {
    address public lsc;

    modifier onlyLsc() {
        require(_msgSender() == lsc);
        _;
    }

    modifier onlyOwnerOrLsc() {
        require(_msgSender() == owner() || _msgSender() == lsc);
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

    struct FindPoolArgs {
        uint amountLiquidity;
        uint expectedToken;
        uint expectedBlxm;
        uint liquidityInPools;
        uint[] currentAmounts0;
        uint[] currentAmounts1;
    }

    uint public constant MINIMUM_LIQUIDITY = 1000;
    uint private constant PERCENT_PRECISION = 10000000000000000;

    mapping(uint => Pool) public pools;
    uint public numberOfPools;

    uint public maximumBuffer;
    uint public minimumCash;
    uint public balancingThresholdPercent;
    uint private threshold;

    address public token1Address;
    address public token0Address;
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

    mapping(address => uint) public balances;

    address[] public tokenReceivers;

    uint sentReserve0;
    uint sentReserve1;
    mapping(uint => uint) sentLPTokens;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function _authorizeUpgrade(address) internal override onlyOwner {}

    function initialize(address _lsc, address _token0, address _token1, uint _minimumCash, uint _maximumBuffer, uint _balancingThresholdPercent) initializer public {
        __Ownable_init();
        lsc = _lsc;
        maximumBuffer = _maximumBuffer;
        minimumCash = _minimumCash;
        token1Address = _token1;
        token0Address = _token0;
        balancingThresholdPercent = _balancingThresholdPercent;
        threshold = _balancingThresholdPercent * PERCENT_PRECISION;
    }

    function add_liquidity(uint amountBlxm, uint amountToken, address to) external onlyLsc {
        (uint liquidity) = calculate_liquidity_amount(
            amountToken,
            amountBlxm
        );
        updateBalance(liquidity, to);
        reserve1 += amountToken;
        reserve0 += amountBlxm;
        cash += liquidity;
        if (cash > minimumCash) {
            buffer += cash - minimumCash;
            cash = minimumCash;
        }
        if (buffer >= maximumBuffer) {
            send_tokens_investment_buffer();
        }
    }

    function send_tokens_investment(uint amount0, uint amount1, uint poolIndex) public onlyOwner {
        require(reserve0 >= amount0 || reserve1 >= amount1, "Not enough tokens");
        (uint depositedToken, uint depositedBlxm) = send_tokens_to_pool(pools[poolIndex], amount1, amount0);
        (uint depositedLiquidity) = calculate_liquidity_amount(
            depositedToken,
            depositedBlxm
        );
        reserve0 -= amount0;
        reserve1 -= amount1;
        uint reservesLiquidity = calculate_liquidity_amount(reserve0, reserve1);
        if (reservesLiquidity > minimumCash) {
            cash = minimumCash;
            buffer = reservesLiquidity - minimumCash;
        } else {
            cash = reservesLiquidity;
            buffer = 0;
        }
        pools[poolIndex].amountLiquidity += depositedLiquidity;
    }

    function retrieve_tokens(uint amountLpTokens, uint poolIndex) public onlyOwner {
        Pool storage pool = pools[poolIndex];
        require(pool.amountOfLPTokens >= amountLpTokens, "Not enough liquidity in pool");
        (uint amountBlxm, uint amountToken) = retrieve_tokens_from_pool(amountLpTokens, pool.pair, pool.router);
        pool.amountOfLPTokens -= amountLpTokens;
        reserve1 += amountToken;
        reserve0 += amountBlxm;
        uint reservesLiquidity = calculate_liquidity_amount(reserve0, reserve1);
        if (reservesLiquidity > minimumCash) {
            cash = minimumCash;
            buffer = reservesLiquidity - minimumCash;
        } else {
            cash = reservesLiquidity;
            buffer = 0;
        }
        (,,,,uint[] memory currentAmounts0, uint[] memory currentAmounts1) = get_total_amounts();
        pool.amountLiquidity = calculate_liquidity_amount(currentAmounts0[poolIndex], currentAmounts1[poolIndex]);
    }

    function update_pools_liquidity(uint[] memory currentAmounts0, uint[] memory currentAmounts1) private {
        for (uint i = 0; i < numberOfPools; i++) {
            pools[i].amountLiquidity = calculate_liquidity_amount(currentAmounts0[i], currentAmounts1[i]);
        }
    }

    function get_tokens(uint reward, uint requestedAmount0, uint requestedAmount1, address payable to) external onlyLsc returns (uint sentToken, uint sentBlxm) {
        // reward? requestedAmount0 = 40(18), requestedAmount1 = 10(18)
        require(IERC20(token0Address).balanceOf(address(this)) - (reserve0) >= reward, "Not enough reward");
        if (requestedAmount0 > reserve0 || requestedAmount1 > reserve1) {
            // amount0 - reserve0 = 96608402601935735482
            // amount1 - reserve1 = 65200804562559449392    
            // diff:9948384562559448394
            (uint amount0, uint amount1,,,uint[] memory currentAmounts0, uint[] memory currentAmounts1) = get_total_amounts();
            update_pools_liquidity(currentAmounts0, currentAmounts1);
            require(requestedAmount0 <= amount0 && requestedAmount1 <= amount1, "No enough tokens to retreive");
            uint liquidityInPools = calculate_liquidity_amount(amount0 - reserve0, amount1 - reserve1);
            // liquidityInPools = 79365896814374067048
            uint expectedTokenToRetrieve;
            uint expectedBlxmToRetrieve;
            if (requestedAmount1 > reserve1 && requestedAmount0 > reserve0) {
                expectedTokenToRetrieve = minimumCash * (amount1 - reserve1) / liquidityInPools + requestedAmount1 - reserve1;// amount1 - reserve1);
                expectedBlxmToRetrieve = expectedTokenToRetrieve * (amount0 - reserve0) / (amount1 - reserve1);
                if (expectedBlxmToRetrieve < minimumCash * (amount0 - reserve0) / liquidityInPools + requestedAmount0 - reserve0) {
                    expectedBlxmToRetrieve = Math.max(expectedBlxmToRetrieve, minimumCash * (amount0 - reserve0) / liquidityInPools + requestedAmount0 - reserve0);
                    expectedTokenToRetrieve = expectedBlxmToRetrieve * (amount1 - reserve1) / (amount0 - reserve0);
                }
            } else if (requestedAmount1 > reserve1) {
                expectedTokenToRetrieve = minimumCash * (amount1 - reserve1) / liquidityInPools + requestedAmount1 - reserve1;
                expectedBlxmToRetrieve = expectedTokenToRetrieve * (amount0 - reserve0) / (amount1 - reserve1);
            } else {
                expectedBlxmToRetrieve = minimumCash * (amount0 - reserve0) / liquidityInPools + requestedAmount0 - reserve0;
                expectedTokenToRetrieve = expectedBlxmToRetrieve * (amount1 - reserve1) / (amount0 - reserve0);
            }

            if (expectedBlxmToRetrieve > amount0 - reserve0 || expectedTokenToRetrieve > amount1 - reserve1) {
                expectedBlxmToRetrieve = amount0 - reserve0;
                expectedTokenToRetrieve = amount1 - reserve1;
            }           
            
            uint liquidityToRetrieve = calculate_liquidity_amount(expectedTokenToRetrieve, expectedBlxmToRetrieve);
            // fill over from pools
            FindPoolArgs memory args;
            args.amountLiquidity = liquidityToRetrieve;
            args.expectedToken = expectedTokenToRetrieve;
            args.expectedBlxm = expectedBlxmToRetrieve;
            args.liquidityInPools = liquidityInPools;
            args.currentAmounts0 = currentAmounts0;
            args.currentAmounts1 = currentAmounts1;
            (uint[] memory poolsIndexes, uint[] memory amountsToRemove) = find_pool_to_fill_reserves(args);
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
        }
        if (reserve1 > requestedAmount1) {
            reserve1 -= requestedAmount1;
            sentToken = requestedAmount1;
            IERC20(token1Address).transfer(to, requestedAmount1);
        } else {
            IERC20(token1Address).transfer(to, reserve1);
            sentToken = reserve1;
            reserve1 = 0;
        }
        if (reserve0 > requestedAmount0) {
            reserve0 -= requestedAmount0;
            sentBlxm = requestedAmount0 + reward;
            IERC20(token0Address).transfer(to, requestedAmount0 + reward);
        } else {
            IERC20(token0Address).transfer(to, reserve0 + reward);
            sentBlxm = reserve0 + reward;
            reserve0 = 0;
        }

        uint reservesLiquidity = calculate_liquidity_amount(reserve0, reserve1);
        if (reservesLiquidity > minimumCash) {
            cash = minimumCash;
            buffer = reservesLiquidity - minimumCash;
        } else {
            cash = reservesLiquidity;
            buffer = 0;
        }
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

    function get_nominal_amounts() public view returns (
        uint amount0,
        uint amount1
    ) {
        amount0 = reserve0 + sentReserve0;
        amount1 = reserve1 + sentReserve1;
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
            amount0 += reserve0Pool * (pool.amountOfLPTokens + sentLPTokens[i]) / totalSupply;
            amount1 += reserve1Pool * (pool.amountOfLPTokens + sentLPTokens[i]) / totalSupply;
        }
        return (amount0, amount1);
    }

    function set_maximum_buffer(uint _buffer) public onlyOwner {
        maximumBuffer = _buffer;
    }

    function set_minimum_cash(uint _cash) public onlyOwner {
        minimumCash = _cash;
    }

    function set_balancing_threshold_percent(uint new_percent) public onlyOwner {
        balancingThresholdPercent = new_percent;
        threshold = new_percent * PERCENT_PRECISION;
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
        require(pools[index].amountOfLPTokens == 0, "Pool is not empty");
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

    function change_pools_percentages(uint[] memory newPercentages) public onlyOwner {
        require(newPercentages.length == numberOfPools, "New percentages should be provided for all products");
        uint totalPercent;
        for (uint i; i < newPercentages.length; i++) {
            totalPercent += newPercentages[i];
            pools[i].percentage = newPercentages[i];
        }
        require(totalPercent == 100, "Total percent of all products must be 100");
    }

    function send_lp_tokens(uint receiverIndex, uint poolIndex, uint amount) public onlyOwner {
        require(receiverIndex < tokenReceivers.length && poolIndex < numberOfPools, "Index is out range");
        Pool storage pool = pools[poolIndex];
        require(amount <= pools[poolIndex].amountOfLPTokens, "Not enough tokens");
        IERC20(pool.pair).transfer(tokenReceivers[receiverIndex], amount);
        pool.amountOfLPTokens -= amount;
        sentLPTokens[poolIndex] += amount;
    }

    function send_reserve_tokens(uint receiverIndex, uint amount0, uint amount1) public onlyOwner {
        require(receiverIndex < tokenReceivers.length, "Index is out range");
        require(amount0 <= reserve0 && amount1 <= reserve1, "Not enough tokens");
        IERC20(token0Address).transfer(tokenReceivers[receiverIndex], amount0);
        IERC20(token1Address).transfer(tokenReceivers[receiverIndex], amount1);
        reserve0 -= amount0;
        reserve1 -= amount1;
        sentReserve0 += amount0;
        sentReserve1 += amount1;
        uint liquidity = calculate_liquidity_amount(reserve0, reserve1);
        cash = Math.min(liquidity, minimumCash);
        buffer = liquidity - cash;
    }

    function add_token_receiver(address receiver) public onlyOwner {
        tokenReceivers.push(receiver);
    }

    function remove_token_receiver(uint index) public onlyOwner {
        require(index < tokenReceivers.length, "Index is out of array range");
        for (uint i = index; i < tokenReceivers.length - 1; i++) {
            tokenReceivers[i] = tokenReceivers[i + 1];
        }
        tokenReceivers.pop();
    }

    function set_lp_amount(uint index, uint amountOfLP) public onlyOwner {
        require(index < numberOfPools, "Index is out of array range");
        require(amountOfLP > pools[index].amountOfLPTokens, "Set amount is lower than current");
        sentLPTokens[index] -= Math.min(amountOfLP - pools[index].amountOfLPTokens, sentLPTokens[index]);
        pools[index].amountOfLPTokens = amountOfLP;
    }

    function set_reserves_amount(uint amount0, uint amount1) public onlyOwner {
        require(amount0 >= reserve0 && amount1 >= reserve1, "Set amount is lower than current");
        sentReserve0 -= Math.min(amount0 - reserve0, sentReserve0);
        sentReserve1 -= Math.min(amount1 - reserve1, sentReserve1);
        reserve0 = amount0;
        reserve1 = amount1;
        uint liquidity = calculate_liquidity_amount(amount0, amount1);
        cash = Math.min(liquidity, minimumCash);
        buffer = liquidity - cash;
    }

    function find_pool_to_add(uint amountLiquidity, uint amountAll0, uint amountAll1) private view returns (uint[] memory, uint[] memory){
        uint liquidityInPools = calculate_liquidity_amount(amountAll0 - reserve0, amountAll1 - reserve1);
        Pool memory poolToAdd = pools[0];
        uint poolIndex;
        uint poolMismatch;
        // find most imbalanced pool
        if (numberOfPools > 1) {
            for (uint i = 0; i < numberOfPools; i++) {
                uint currentPoolPercentage = pools[i].amountLiquidity * PERCENT_PRECISION * 100 / Math.max(liquidityInPools, 1);
                if (pools[i].percentage * PERCENT_PRECISION > currentPoolPercentage &&
                    (pools[i].percentage * PERCENT_PRECISION - currentPoolPercentage > poolMismatch ||
                    (pools[i].percentage * PERCENT_PRECISION - currentPoolPercentage == poolMismatch && pools[i].percentage > poolToAdd.percentage))
                ) {
                    poolToAdd = pools[i];
                    poolMismatch = pools[i].percentage * PERCENT_PRECISION - currentPoolPercentage;
                    poolIndex = i;
                }
            }
        }
        uint finalLiquidity = liquidityInPools + amountLiquidity;
        uint[] memory poolIndexes;
        uint[] memory amountsToAdd;
        // check if adding liquidity to one pool leads to disbalance
        if ((poolToAdd.amountLiquidity + amountLiquidity) * PERCENT_PRECISION * 100 / finalLiquidity > poolToAdd.percentage * PERCENT_PRECISION &&
            (poolToAdd.amountLiquidity + amountLiquidity) * PERCENT_PRECISION * 100 / finalLiquidity - poolToAdd.percentage * PERCENT_PRECISION > threshold) {
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

    function send_tokens_investment_buffer() private {
        (uint amount0,
        uint amount1,
        uint[] memory totalAmounts0,
        uint[] memory totalAmounts1,
        uint[] memory currentAmounts0,
        uint[] memory currentAmounts1
        ) = get_total_amounts();
        update_pools_liquidity(currentAmounts0, currentAmounts1);
        uint depositedTokenAll;
        uint depositedBlxmAll;
        uint depositedLiquidityAll;
        (uint[] memory poolIndexes, uint[] memory amountsToAdd) = find_pool_to_add(buffer, amount0, amount1);
        for (uint i = 0; i < poolIndexes.length; i++) {
            uint amountToken = reserve1 * amountsToAdd[i] / (buffer + cash);
            uint amountBlxm = amountToken * totalAmounts0[i] / totalAmounts1[i];
            if (amountBlxm > reserve0) {
                amountBlxm = reserve0 * amountsToAdd[i] / (buffer + cash);
                amountToken = amountBlxm * totalAmounts1[i] / totalAmounts0[i];
            }
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
        reserve1 -= depositedTokenAll;
        reserve0 -= depositedBlxmAll;
        cash = calculate_liquidity_amount(reserve0, reserve1);
        if (cash > minimumCash) {
            buffer = cash - minimumCash;
            cash = minimumCash;
        } else {
            buffer = 0;
        }
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

    function is_possible_to_balance_on_get(uint finalLiquidity, uint expectedToken, uint expectedBlxm, uint[] memory currentAmounts0, uint[] memory currentAmounts1) private view returns (bool) {
        uint sumToken;
        uint sumBlxm;
        for (uint i = 0; i < numberOfPools; i++) {
            if (finalLiquidity * pools[i].percentage / 100 > pools[i].amountLiquidity) {
                return false;
            }
            uint amountToRemove = pools[i].amountLiquidity - finalLiquidity * pools[i].percentage / 100;
            uint poolToRemoveLiquidity = Math.max(amountToRemove * currentAmounts1[i] * expectedBlxm / (currentAmounts0[i] * expectedToken), amountToRemove * currentAmounts0[i] * expectedToken / (currentAmounts1[i] * expectedBlxm));
            poolToRemoveLiquidity = Math.min(poolToRemoveLiquidity, pools[i].amountLiquidity);
            sumToken += poolToRemoveLiquidity * currentAmounts1[i] / pools[i].amountLiquidity;
            sumBlxm += poolToRemoveLiquidity * currentAmounts0[i] / pools[i].amountLiquidity;
        }
        if (sumToken < expectedToken || sumBlxm < expectedBlxm) return false;
        return true;
    }

    function find_pool_to_fill_reserves(FindPoolArgs memory args) private view returns (uint[] memory, uint[] memory) {
        uint[] memory poolsIndexes;
        uint[] memory amountsToRemove;
        if (args.liquidityInPools - args.amountLiquidity == 0) {
            poolsIndexes = new uint[](numberOfPools);
            amountsToRemove = new uint[](numberOfPools);
            for (uint i = 0; i < numberOfPools; i++) {
                poolsIndexes[i] = i;
                amountsToRemove[i] = pools[i].amountLiquidity;
            }
        } else {
            Pool memory poolToRemove = pools[0];
            uint poolMismatch;
            uint poolIndex;
            if (numberOfPools > 1) {
                for (uint i = 0; i < numberOfPools; i++) {
                    uint poolPercentage = pools[i].amountLiquidity * PERCENT_PRECISION * 100 / args.liquidityInPools;
                    if (poolPercentage > pools[i].percentage * PERCENT_PRECISION &&
                        (poolPercentage - pools[i].percentage * PERCENT_PRECISION > poolMismatch ||
                        (poolPercentage - pools[i].percentage * PERCENT_PRECISION == poolMismatch && pools[i].percentage > poolToRemove.percentage))
                    ) {
                        poolToRemove = pools[i];
                        poolMismatch = poolPercentage - pools[i].percentage * PERCENT_PRECISION;
                        poolIndex = i;
                    }
                }
            }
            uint liq = Math.max(
                args.amountLiquidity * args.currentAmounts1[poolIndex] * args.expectedBlxm / args.currentAmounts0[poolIndex] * args.expectedToken,
                args.amountLiquidity * args.currentAmounts0[poolIndex] * args.expectedToken / args.currentAmounts1[poolIndex] * args.expectedBlxm
            );
            // recalculate poolToRemove.amountLiquidity
            if (poolToRemove.amountLiquidity < liq ||
                (poolToRemove.percentage * PERCENT_PRECISION > (poolToRemove.amountLiquidity - liq) * PERCENT_PRECISION * 100 / (args.liquidityInPools - args.amountLiquidity) &&
                poolToRemove.percentage * PERCENT_PRECISION - (poolToRemove.amountLiquidity - liq) * PERCENT_PRECISION * 100 / (args.liquidityInPools - args.amountLiquidity) > threshold)
            ) {
                poolsIndexes = new uint[](numberOfPools);
                amountsToRemove = new uint[](numberOfPools);
                bool isPossibleToBalance = is_possible_to_balance_on_get(args.liquidityInPools - args.amountLiquidity, args.expectedToken, args.expectedBlxm, args.currentAmounts0, args.currentAmounts1);
                for (uint i = 0; i < numberOfPools; i++) {
                    poolsIndexes[i] = i;
                    if (isPossibleToBalance) {
                        amountsToRemove[i] = pools[i].amountLiquidity - (args.liquidityInPools - args.amountLiquidity) * pools[i].percentage / 100;
                        amountsToRemove[i] = Math.max(amountsToRemove[i] * args.currentAmounts1[i] * args.expectedBlxm / (args.currentAmounts0[i] * args.expectedToken), amountsToRemove[i] * args.currentAmounts0[i] * args.expectedToken / (args.currentAmounts1[i] * args.expectedBlxm));
                        amountsToRemove[i] = Math.min(amountsToRemove[i], pools[i].amountLiquidity);
                    } else {
                        amountsToRemove[i] = args.amountLiquidity * pools[i].amountLiquidity / args.liquidityInPools;
                    }
                }
            } else {
                poolsIndexes = new uint[](1);
                amountsToRemove = new uint[](1);
                poolsIndexes[0] = poolIndex;
                amountsToRemove[0] = liq;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate that the this implementation remains valid after an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

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

pragma solidity ^0.8.12;

interface IPair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function totalSupply() external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);
}

pragma solidity ^0.8.12;

interface IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address tokenOwner) external view returns (uint balance);

    function transfer(address _to, uint256 _value) external returns (bool success);

    function allowance(address owner, address spender) external returns (uint256);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

pragma solidity ^0.8.12;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}