// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

interface ERC20Balance {
    function balanceOf(address holder) external view returns (uint256);
}

interface CiderLiquidity {
    function gearCommitted(address holder) external view returns (uint256);
}

address constant tokenDistributor = 0xf7512B2B20Cf427ADD8b01D8CDEef97a4B0E2C27;
address constant ciderLiquidity = 0xcB91F4521Fc43d4B51586E69F7145606b926b8D4;

contract DrunkVoting is ERC20Balance {
    function balanceOf(address holder) external view returns (uint256) {
        if (holder == ciderLiquidity) return 0;

        return ERC20Balance(tokenDistributor).balanceOf(holder) + CiderLiquidity(ciderLiquidity).gearCommitted(holder);
    }
}