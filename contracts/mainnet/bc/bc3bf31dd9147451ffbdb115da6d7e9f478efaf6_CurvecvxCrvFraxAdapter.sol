// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./../interfaces/IExchangeAdapter.sol";

// solhint-disable func-name-mixedcase
// solhint-disable var-name-mixedcase
interface ICurvecvxCrvFRax {
    function add_liquidity(
        address _pool,
        uint256[3] memory _amounts,
        uint256 _min_mint_amount
    ) external returns (uint256);

    function remove_liquidity_one_coin(
        address _pool,
        uint256 _burn_amount,
        uint256 i,
        uint256 _min_received
    ) external returns (uint256);
}

contract CurvecvxCrvFraxAdapter is IExchangeAdapter {
    address public constant CVXCRV_FRAXBP_POOL =
        0x31c325A01861c7dBd331a9270296a31296D797A0;
    address public constant CVXCRV_FRAXBP_LPTOKEN =
        0x527331F3F550f6f85ACFEcAB9Cc0889180C6f1d5;

    function indexByCoin(address coin) public pure returns (uint256) {
        if (coin == 0x62B9c7356A2Dc64a1969e19C23e4f579F9810Aa7) return 1; // cvxCrv
        if (coin == 0x853d955aCEf822Db058eb8505911ED77F175b99e) return 2; // frax
        if (coin == 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48) return 3; // usdc
        return 0;
    }

    // 0x6012856e  =>  executeSwap(address,address,address,uint256)
    function executeSwap(
        address pool,
        address fromToken,
        address toToken,
        uint256 amount
    ) external payable returns (uint256) {
        ICurvecvxCrvFRax curve = ICurvecvxCrvFRax(pool);
        if (toToken == CVXCRV_FRAXBP_LPTOKEN) {
            uint256 i = uint128(indexByCoin(fromToken));
            require(i != 0, "CurvecvxCrvFraxAdapter: Can't Swap");
            uint256[3] memory entryVector;
            entryVector[i - 1] = amount;
            return curve.add_liquidity(CVXCRV_FRAXBP_POOL, entryVector, 0);
        } else if (fromToken == CVXCRV_FRAXBP_LPTOKEN) {
            uint256 i = indexByCoin(toToken);
            require(i != 0, "CurvecvxCrvFraxAdapter: !Swap");
            return
                curve.remove_liquidity_one_coin(
                    CVXCRV_FRAXBP_POOL,
                    amount,
                    i - 1,
                    0
                );
        } else {
            revert("CurvecvxCrvFraxAdapter: !Swap");
        }
    }

    // 0xe83bbb76  =>  enterPool(address,address,address,uint256)
    function enterPool(
        address,
        address,
        uint256
    ) external payable returns (uint256) {
        revert("CurvecvxCrvFraxAdapter: !Swap");
    }

    // 0x9d756192  =>  exitPool(address,address,address,uint256)
    function exitPool(
        address,
        address,
        uint256
    ) external payable returns (uint256) {
        revert("CurvecvxCrvFraxAdapter: !Swap");
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