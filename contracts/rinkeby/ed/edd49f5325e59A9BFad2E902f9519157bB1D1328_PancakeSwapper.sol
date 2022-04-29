//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

//import "hardhat/console.sol";

import { Swapper } from "./interfaces/Swapper.sol";
import { WardedLiving} from "./interfaces/WardedLiving.sol";
import { UniFactoryV2, UniRouterV2 } from "./interfaces/UniV2.sol";

interface IERC20 {
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
}

contract PancakeSwapper is Swapper, WardedLiving {

    address public bridgeAsset; //Stargate USDT
    UniFactoryV2 public factory;
    UniRouterV2 public router;

    constructor(address sgUSDT_, address router_) {
        bridgeAsset = sgUSDT_;
        router = UniRouterV2(router_);
        factory = UniFactoryV2(router.factory());

        relyOnSender();
        run();

        IERC20(bridgeAsset).approve(router_,
            115792089237316195423570985008687907853269984665640564039457584007913129639935);
    }

    function setBridgeAsset(address token) external auth {
        bridgeAsset = token;
    }

    function isTokenSupported(address token) public view returns(bool) {
        return factory.getPair(bridgeAsset, token) != address(0x0);
    }

    function toBridgeAsset(address token, uint256 amount) external live payable returns (uint256) {
        if (token == address(0x0)) {
//            console.log("[PS] msg.value: " , msg.value);

            require(isTokenSupported(router.WETH()), "PancakeSwapper/cannot-swap-here");
            address[] memory path = new address[](2);
            path[0] = router.WETH();
            path[1] = bridgeAsset;
            return router.swapExactETHForTokens{value:msg.value}(
                0, //amountOutMin  FixMe <-- Dangerous. Need to get quotes before
                path,
                msg.sender,
                block.timestamp + 300 //5 minute
            )[1];
        } else {
            require(isTokenSupported(token), "PancakeSwapper/cannot-swap-here");
            address[] memory path = new address[](2);
            path[0] = token;
            path[1] = bridgeAsset;
            return router.swapExactTokensForTokens(
                amount, //amountIn
                0, //amountOutMin  FixMe <-- Dangerous. Need to get quotes before
                path,
                msg.sender,
                block.timestamp + 300 //5 minute
            )[1];
        }
    }

    function fromBridgeAsset(address bridgeToken, address token, uint256 amount, address receiver) external live returns (uint256) {
        if (token == address(0x0)) {
            require(isTokenSupported(router.WETH()), "PancakeSwapper/cannot-swap-here");
            address[] memory path = new address[](2);
            path[0] = bridgeToken;
            path[1] = router.WETH();
            return router.swapExactTokensForETH(
                amount, //amountIn
                0, //amountOutMin  FixMe <-- Dangerous. Need to get quotes before
                path,
                receiver,
                block.timestamp + 300 // 5 minutes
            )[1];
        } else {
            require(isTokenSupported(token), "PancakeSwapper/cannot-swap-here");
            address[] memory path = new address[](2);
            path[0] = bridgeToken;
            path[1] = token;
            return router.swapExactTokensForTokens(
                amount, //amountIn
                0, //amountOutMin  FixMe <-- Dangerous. Need to get quotes before
                path,
                receiver,
                block.timestamp + 300 // 5 minutes
            )[1];
        }
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface Swapper {
    function bridgeAsset() external view returns (address);
    function setBridgeAsset(address token) external;

    function toBridgeAsset(address token, uint256 amount) external payable returns (uint256);
    function fromBridgeAsset(address bridgeToken, address token, uint256 amount, address receiver) external returns (uint256);
    function isTokenSupported(address token) external view returns(bool);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./Warded.sol";

abstract contract WardedLiving is Warded {
    uint256 alive;

    modifier live {
        require(alive != 0, "WardedLiving/not-live");
        _;
    }

    function stop() external auth {
        alive = 0;
    }

    function run() public auth {
        alive = 1;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface UniFactoryV2 {
    //Address for tokenA and address for tokenB return address of pair contract (where one exists).
    //tokenA and tokenB order is interchangeable.
    //Returns 0x0000000000000000000000000000000000000000 as address where no pair exists.
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface UniRouterV2 {
    //Receive as many output tokens as possible for an exact amount of input tokens.
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    //Receive as many output tokens as possible for an exact amount of BNB.
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);

    //Receive an exact amount of output tokens for as little BNB as possible.
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);

    //Returns the canonical address for Binance: WBNB token
    //(WETH being a vestige from Ethereum network origins).
    function WETH() external pure returns (address);

    //Returns the canonical address for PancakeFactory.
    function factory() external pure returns (address);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

abstract contract Warded {

    mapping (address => uint256) public wards;
    function rely(address usr) external auth { wards[usr] = 1; }
    function deny(address usr) external auth { wards[usr] = 0; }
    modifier auth {
        require(wards[msg.sender] == 1, "Warded/not-authorized");
        _;
    }

    // Use this in ctor
    function relyOnSender() internal { wards[msg.sender] = 1; }
}