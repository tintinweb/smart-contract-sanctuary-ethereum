// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {DefiiWithParams} from "../DefiiWithParams.sol";

contract CompoundV2LeverageDaiUsdc is DefiiWithParams {
    IERC20 constant DAI = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    IERC20 constant USDC = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    ICErc20 constant cDAI = ICErc20(0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643);
    ICErc20 constant cUSDC =
        ICErc20(0x39AA39c021dfbaE8faC545936693aC917d5E7563);
    IERC20 constant COMP = IERC20(0xc00e94Cb662C3520282E6f5717214004A7f26888);
    IERC20 constant WETH = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    IComptroller constant comptroller =
        IComptroller(0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B);
    ISwapRouter constant router =
        ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
    IPool constant daiUsdcPool =
        IPool(0x5777d92f208679DB4b9778590Fa3CAB3aC9e2168);

    function encodeParams(uint8 loopCount, uint8 ltv)
        external
        pure
        returns (bytes memory encodedParams)
    {
        require(ltv < 100, "LTV must be in range [0, 100]");
        encodedParams = abi.encode(loopCount, ltv);
    }

    function _enterWithParams(bytes memory params) internal override {
        IPriceOracle oracle = comptroller.oracle();

        (uint8 loopCount, uint8 ltv) = abi.decode(params, (uint8, uint8));

        USDC.approve(address(router), type(uint256).max);
        DAI.approve(address(cDAI), type(uint256).max);

        address[] memory cTokens = new address[](1);
        cTokens[0] = address(cDAI);
        uint256[] memory errors = comptroller.enterMarkets(cTokens);
        require(errors[0] == 0, "Comptroller.enterMarkets failed.");

        uint256 daiPrice = oracle.getUnderlyingPrice(address(cDAI));
        uint256 usdcPrice = oracle.getUnderlyingPrice(address(cUSDC));

        uint256 daiBalance;
        uint256 usdcBalance;
        for (uint8 i = 0; i < loopCount; i++) {
            daiBalance = DAI.balanceOf(address(this));
            cDAI.mint(daiBalance);
            cUSDC.borrow((((daiBalance * daiPrice) / usdcPrice) * ltv) / 100);
            usdcBalance = USDC.balanceOf(address(this));

            router.exactInputSingle(
                ISwapRouter.ExactInputSingleParams({
                    tokenIn: address(USDC),
                    tokenOut: address(DAI),
                    fee: 100,
                    recipient: address(this),
                    deadline: block.timestamp,
                    amountIn: usdcBalance,
                    amountOutMinimum: (usdcBalance * 999) / 1000, // slippage 0.1 %
                    sqrtPriceLimitX96: 0
                })
            );
        }
        cDAI.mint(DAI.balanceOf(address(this)));

        USDC.approve(address(router), 0);
        DAI.approve(address(cDAI), 0);
    }

    function _exit() internal override call {
        uint256 borrowedUsdc = cUSDC.borrowBalanceCurrent(address(this));
        daiUsdcPool.swap(
            address(this),
            true,
            -int256(borrowedUsdc),
            4295128739 + 1, // MIN_SQRT_RATIO + 1
            bytes("")
        );
        cDAI.redeem(cDAI.balanceOf(address(this)));

        _claimCompAndConvertToUsdc();
    }

    function uniswapV3SwapCallback(
        int256 amount0,
        int256 amount1,
        bytes calldata data
    ) external callback {
        require(msg.sender == address(daiUsdcPool));

        // Should obtain DAI, should return USDC
        require(amount0 > 0, "Wrong amount of DAI");
        require(amount1 < 0, "Wrong admount of USDC");

        uint256 repaymentAmount = uint256(-amount1);
        USDC.approve(address(cUSDC), repaymentAmount);
        cUSDC.repayBorrow(repaymentAmount);

        cDAI.redeemUnderlying(uint256(amount0));
        DAI.transfer(address(daiUsdcPool), uint256(amount0));
    }

    function _harvest() internal override {
        _claimCompAndConvertToUsdc();
        _withdrawFunds();
    }

    function _claimCompAndConvertToUsdc() internal {
        comptroller.claimComp(address(this));
        uint256 compBalance = COMP.balanceOf(address(this));
        if (compBalance == 0) {
            return;
        }

        COMP.approve(address(router), compBalance);
        router.exactInput(
            ISwapRouter.ExactInputParams({
                path: abi.encodePacked(
                    COMP,
                    uint24(10000),
                    WETH,
                    uint24(500),
                    USDC
                ),
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: compBalance,
                amountOutMinimum: 0
            })
        );
    }

    function _withdrawFunds() internal override {
        withdrawERC20(DAI);
        withdrawERC20(USDC);
    }

    bool readyForCallback = false;

    modifier call() {
        readyForCallback = true;
        _;
        readyForCallback = false;
    }
    modifier callback() {
        require(readyForCallback, "Call first");
        _;
    }
}

interface ICErc20 is IERC20 {
    function borrow(uint256 borrowAmount) external returns (uint256);

    function borrowBalanceCurrent(address account) external returns (uint256);

    function mint(uint256 mintAmount) external returns (uint256);

    function redeem(uint256 redeemTokens) external returns (uint256);

    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);

    function repayBorrow(uint256 repayAmount) external returns (uint256);
}

interface IComptroller {
    function oracle() external view returns (IPriceOracle);

    function enterMarkets(address[] calldata)
        external
        returns (uint256[] memory);

    function claimComp(address holder) external;
}

interface IPriceOracle {
    function getUnderlyingPrice(address cToken) external view returns (uint256);
}

interface ISwapRouter {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    function exactInputSingle(ExactInputSingleParams calldata params)
        external
        payable
        returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    function exactInput(ExactInputParams memory params)
        external
        returns (uint256 amountOut);
}

interface IPool {
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./Defii.sol";


abstract contract DefiiWithParams is Defii {
    function enterWithParams(bytes memory params) external onlyOwner {
        _enterWithParams(params);
    }

    function _enterWithParams(bytes memory params) internal virtual;

    function _enter() internal override {
        revert("Run enterWithParams");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "./interfaces/IDefiiFactory.sol";
import "./interfaces/IDefii.sol";


abstract contract Defii is IDefii {
    address public owner;
    address public factory;

    function init(address owner_, address factory_) external {
        require(owner == address(0), "Already initialized");
        owner = owner_;
        factory = factory_;
    }

    // owner functions
    function enter() external onlyOwner {
        _enter();
    }

    function runTx(address target, uint256 value, bytes memory data) external onlyOwner {
        (bool success,) = target.call{value: value}(data);
        require(success, "runTx failed");
    }

    // owner and executor functions
    function exit() external onlyOnwerOrExecutor {
        _exit();
    }
    function exitAndWithdraw() public onlyOnwerOrExecutor {
        _exit();
        _withdrawFunds();
    }

    function harvest() external onlyOnwerOrExecutor {
        _harvest();
    }

    function withdrawFunds() external onlyOnwerOrExecutor {
        _withdrawFunds();
    }

    function withdrawERC20(IERC20 token) public onlyOnwerOrExecutor {
        _withdrawERC20(token);
    }

    function withdrawETH() public onlyOnwerOrExecutor {
        _withdrawETH();
    }
    receive() external payable {}

    // internal functions - common logic
    function _withdrawERC20(IERC20 token) internal {
        uint256 tokenAmount = token.balanceOf(address(this));
        if (tokenAmount > 0) {
            token.transfer(owner, tokenAmount);
        }
    }

    function _withdrawETH() internal {
        uint256 balance = address(this).balance;
        if (balance > 0) {
            (bool success,) = owner.call{value: balance}("");
            require(success, "Transfer failed");
        }
    }

    // internal functions - defii specific logic
    function _enter() internal virtual;
    function _exit() internal virtual;
    function _harvest() internal virtual;
    function _withdrawFunds() internal virtual;

    // modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    modifier onlyOnwerOrExecutor() {
        require(msg.sender == owner || msg.sender == IDefiiFactory(factory).executor(), "Only owner or executor");
        _;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;


interface IDefiiFactory {
    function executor() view external returns (address executor);

    function createDefiiFor(address wallet) external;
    function createDefii() external;
    function getDefiiFor(address wallet) external view returns (address defii);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";

interface IDefii {
    function init(address owner_, address factory_) external;

    function enter() external;
    function runTx(address target, uint256 value, bytes memory data) external;

    function exit() external;
    function exitAndWithdraw() external;
    function harvest() external;
    function withdrawERC20(IERC20 token) external;
    function withdrawETH() external;
    function withdrawFunds() external;
}