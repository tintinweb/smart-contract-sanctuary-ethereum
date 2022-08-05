// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./../interfaces/IExchangeAdapter.sol";

// solhint-disable func-name-mixedcase
// solhint-disable var-name-mixedcase

interface ICurveEURSUSD {
    function exchange(
        uint256 i,
        uint256 j,
        uint256 dx,
        uint256 min_dy
    ) external returns (uint256);

    function add_liquidity(uint256[2] memory amounts, uint256 min_mint_amount)
        external
        returns (uint256);

    function remove_liquidity_one_coin(
        uint256 token_amount,
        uint256 i,
        uint256 min_amount
    ) external returns (uint256);
}

interface ICurveEUR {
    function exchange(
        int128 i,
        int128 j,
        uint256 _dx,
        uint256 _min_dy
    ) external returns (uint256);

    function add_liquidity(uint256[3] memory _amounts, uint256 _min_mint_amount)
        external
        returns (uint256);

    function remove_liquidity_one_coin(
        uint256 _burn_amount,
        int128 i,
        uint256 _min_received
    ) external returns (uint256);
}

contract CurveEURAdapter is IExchangeAdapter {
    function indexByCoin(address coin) public pure returns (uint256) {
        if (coin == 0x1a7e4e63778B4f12a199C062f3eFdD288afCBce8) return 1; // agEUR
        if (coin == 0xC581b735A1688071A1746c968e0798D642EDE491) return 2; // EURT
        if (coin == 0xdB25f211AB05b1c97D595516F45794528a807ad8) return 3; // EURS
        return 0;
    }

    function executeSwap(
        address pool,
        address fromToken,
        address toToken,
        uint256 amount
    ) external payable returns (uint256) {
        address usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
        ICurveEURSUSD usdPool = ICurveEURSUSD(
            0x98a7F18d4E56Cfe84E3D081B40001B3d5bD3eB8B
        );
        ICurveEUR eurPool = ICurveEUR(pool);
        if (fromToken == usdc) {
            int128 j = int128(int256(indexByCoin(toToken)));
            require(j != 0, "EurAdptr: 1can't swap");

            // step 1: usdc -> eurs
            uint256 eursReceived = usdPool.exchange(0, 1, amount, 0);

            // step 2: eurs -> toToken
            return eurPool.exchange(2, j - 1, eursReceived, 0);
        } else if (toToken == usdc) {
            int128 i = int128(int256(indexByCoin(fromToken)));
            require(i != 0, "EurAdptr: 2can't swap");

            // step 1: fromToken -> eurs
            uint256 eursReceived = eurPool.exchange(i - 1, 2, amount, 0);

            // step 2: eurs -> usdc
            return usdPool.exchange(1, 0, eursReceived, 0);
        } else revert("EurAdptr: 3can't swap");
    }

    function enterPool(
        address,
        address,
        uint256
    ) external payable returns (uint256) {
        revert("CurveEURSUSDAdapter: 1!supported");
    }

    function exitPool(
        address,
        address,
        uint256
    ) external payable returns (uint256) {
        revert("CurveEURSUSDAdapter: 2!supported");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IExchangeAdapter {
    // 0x6012856e  =>  executeSwap(address,address,address,uint256)
    function executeSwap(
        address pool,
        address fromToken,
        address toToken,
        uint256 amount
    ) external payable returns (uint256);

    // 0x73ec962e  =>  enterPool(address,address,uint256)
    function enterPool(
        address pool,
        address fromToken,
        uint256 amount
    ) external payable returns (uint256);

    // 0x660cb8d4  =>  exitPool(address,address,uint256)
    function exitPool(
        address pool,
        address toToken,
        uint256 amount
    ) external payable returns (uint256);
}