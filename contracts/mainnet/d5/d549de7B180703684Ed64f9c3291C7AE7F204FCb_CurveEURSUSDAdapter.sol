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

contract CurveEURSUSDAdapter is IExchangeAdapter {
    function indexByCoin(address coin) public pure returns (uint256) {
        if (coin == 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48) return 1; // USDC
        if (coin == 0xdB25f211AB05b1c97D595516F45794528a807ad8) return 2; // EURS
        return 0;
    }

    function executeSwap(
        address pool,
        address fromToken,
        address toToken,
        uint256 amount
    ) external payable returns (uint256) {
        ICurveEURSUSD curve = ICurveEURSUSD(pool);

        uint256 i = indexByCoin(fromToken);
        uint256 j = indexByCoin(toToken);
        require(i != 0 && j != 0, "EursUsdAdptr: can't swap");

        return curve.exchange(i - 1, j - 1, amount, 0);
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