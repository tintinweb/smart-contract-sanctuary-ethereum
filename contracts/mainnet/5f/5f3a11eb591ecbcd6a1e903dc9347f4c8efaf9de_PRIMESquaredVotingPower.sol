pragma solidity ^0.8.0;

interface IERC20 {
    function balanceOf(address account) external view returns (uint);
}

interface IPrimeRewards {
    struct CacheInfo {
        uint256 amount;
        int256 rewardDebt;
    }
    function cacheInfo(uint pid, address account) external view returns (CacheInfo memory);
}

contract PRIMESquaredVotingPower is IERC20 {
    IERC20 constant PRIME_CONTRACT =                IERC20(0xb23d80f5FefcDDaa212212F028021B41DEd428CF);
    uint constant PRIME_DECIMALS =                  18;
    uint constant UNIT =                            10 ** 18;

    uint constant PK_POOL_ID =                      0;
    IPrimeRewards constant PK_CACHING_CONTRACT =    IPrimeRewards(0x3399eff96D4b6Bae8a56F4852EB55736c9C2b041);

    uint constant PK_START_WEIGHT =                 4000;
    uint constant PK_START_TIME =                   1658141695;
    uint constant PK_END_TIME =                     1689677695;

    function cachedPrimeKeys(address account) public view returns (uint) {
        return PK_CACHING_CONTRACT.cacheInfo(PK_POOL_ID, account).amount;
    }

    function primeBalance(address account) public view returns (uint) {
        return PRIME_CONTRACT.balanceOf(account);
    }

    function currentDecayWeight() public view returns (uint) {
        uint decayWeight;
        if (block.timestamp <= PK_START_TIME) {
            decayWeight = UNIT;
        } else if (block.timestamp >= PK_END_TIME) {
            decayWeight = 0;
        } else {
            decayWeight = UNIT - (((block.timestamp - PK_START_TIME) * UNIT) / (PK_END_TIME - PK_START_TIME));
        }
        decayWeight = decayWeight * PK_START_WEIGHT;
        return decayWeight;
    }

    function balanceOf(address account) external override view returns (uint) {
        uint pkBalance = cachedPrimeKeys(account);
        uint primeTokenBalance = primeBalance(account);

        uint squaredVotingPower = pkBalance * currentDecayWeight() + primeTokenBalance;

        return squaredVotingPower;
    }
}