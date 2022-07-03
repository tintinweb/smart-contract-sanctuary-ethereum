// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.10;

import "../../interfaces/IERC20.sol";
import "../../libraries/SafeERC20.sol";
import "../../interfaces/IStrategy.sol";
import "../../interfaces/IUniswapV2Pair.sol";
import "../../interfaces/IUniswapV2Router.sol";
import "../../interfaces/IUniswapV2Factory.sol";

error UniswapStrategy_NotIncurDebtAddress();
error UniswapStrategy_AmountDoesNotMatch();
error UniswapStrategy_LPTokenDoesNotMatch();
error UniswapStrategy_OhmAddressNotFound();

/**
    @title UniswapStrategy
    @notice This contract provides liquidity to uniswap on behalf of IncurDebt contract.
 */
contract UniSwapStrategy is IStrategy {
    using SafeERC20 for IERC20;

    IUniswapV2Router router;
    IUniswapV2Factory factory;

    address incurDebtAddress;
    address ohmAddress;

    constructor(
        address _router,
        address _factory,
        address _incurDebtAddress,
        address _ohmAddress
    ) {
        router = IUniswapV2Router(_router);
        factory = IUniswapV2Factory(_factory);

        incurDebtAddress = _incurDebtAddress;
        ohmAddress = _ohmAddress;

        IERC20(ohmAddress).approve(_router, type(uint256).max);
    }

    function addLiquidity(
        bytes memory _data,
        uint256 _ohmAmount,
        address _user
    )
        external
        returns (
            uint256 liquidity,
            uint256 ohmUnused,
            address lpTokenAddress
        )
    {
        if (msg.sender != incurDebtAddress) revert UniswapStrategy_NotIncurDebtAddress();
        (
            address tokenA,
            address tokenB,
            uint256 amountADesired,
            uint256 amountBDesired,
            uint256 amountAMin,
            uint256 amountBMin
        ) = abi.decode(_data, (address, address, uint256, uint256, uint256, uint256));

        if (tokenA == ohmAddress) {
            if (_ohmAmount != amountADesired) revert UniswapStrategy_AmountDoesNotMatch();

            IERC20(tokenA).safeTransferFrom(incurDebtAddress, address(this), _ohmAmount);
            IERC20(tokenB).safeTransferFrom(_user, address(this), amountBDesired);
            IERC20(tokenB).approve(address(router), amountBDesired);
        } else if (tokenB == ohmAddress) {
            if (_ohmAmount != amountBDesired) revert UniswapStrategy_AmountDoesNotMatch();

            IERC20(tokenB).safeTransferFrom(incurDebtAddress, address(this), _ohmAmount);
            IERC20(tokenA).safeTransferFrom(_user, address(this), amountADesired);
            IERC20(tokenA).approve(address(router), amountADesired);
        } else {
            revert UniswapStrategy_OhmAddressNotFound();
        }

        uint256 amountA;
        uint256 amountB;

        (amountA, amountB, liquidity) = router.addLiquidity(
            tokenA,
            tokenB,
            amountADesired,
            amountBDesired,
            amountAMin,
            amountBMin,
            incurDebtAddress,
            block.timestamp
        );

        uint256 amountALeftover = amountADesired - amountA;
        uint256 amountBLeftover = amountBDesired - amountB;

        if (tokenA == ohmAddress) {
            // Return leftover ohm to incurdebt and pair token to user
            ohmUnused = amountALeftover;
            if (amountALeftover > 0) {
                IERC20(ohmAddress).safeTransfer(incurDebtAddress, amountALeftover);
            }

            if (amountBLeftover > 0) {
                IERC20(tokenB).safeTransfer(_user, amountBLeftover);
            }
        } else {
            ohmUnused = amountBLeftover;
            if (amountBLeftover > 0) {
                IERC20(ohmAddress).safeTransfer(incurDebtAddress, amountBLeftover);
            }

            if (amountALeftover > 0) {
                IERC20(tokenA).safeTransfer(_user, amountALeftover);
            }
        }

        lpTokenAddress = IUniswapV2Factory(factory).getPair(tokenA, tokenB);
    }

    function removeLiquidity(
        bytes memory _data,
        uint256 _liquidity,
        address _lpTokenAddress,
        address _user
    ) external returns (uint256 ohmRecieved) {
        if (msg.sender != incurDebtAddress) revert UniswapStrategy_NotIncurDebtAddress();
        (address tokenA, address tokenB, uint256 liquidity, uint256 amountAMin, uint256 amountBMin) = abi.decode(
            _data,
            (address, address, uint256, uint256, uint256)
        );

        address lpTokenAddress = IUniswapV2Factory(factory).getPair(tokenA, tokenB);

        if (liquidity != _liquidity) revert UniswapStrategy_AmountDoesNotMatch();
        if (tokenA != ohmAddress && tokenB != ohmAddress) revert UniswapStrategy_OhmAddressNotFound();
        if (_lpTokenAddress != lpTokenAddress) revert UniswapStrategy_LPTokenDoesNotMatch();

        IUniswapV2Pair(lpTokenAddress).approve(address(router), liquidity);

        (uint256 amountA, uint256 amountB) = router.removeLiquidity(
            tokenA,
            tokenB,
            liquidity,
            amountAMin,
            amountBMin,
            address(this),
            block.timestamp
        );

        if (tokenA == ohmAddress) {
            ohmRecieved = amountA;
            IERC20(tokenA).safeTransfer(incurDebtAddress, amountA);
            IERC20(tokenB).safeTransfer(_user, amountB);
        } else {
            ohmRecieved = amountB;
            IERC20(tokenB).safeTransfer(incurDebtAddress, amountB);
            IERC20(tokenA).safeTransfer(_user, amountA);
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.7.5;

import {IERC20} from "../interfaces/IERC20.sol";

/// @notice Safe IERC20 and ETH transfer library that safely handles missing return values.
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v3-periphery/blob/main/contracts/libraries/TransferHelper.sol)
/// Taken from Solmate
library SafeERC20 {
    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, amount)
        );

        require(success && (data.length == 0 || abi.decode(data, (bool))), "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(IERC20.transfer.selector, to, amount)
        );

        require(success && (data.length == 0 || abi.decode(data, (bool))), "TRANSFER_FAILED");
    }

    function safeApprove(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(IERC20.approve.selector, to, amount)
        );

        require(success && (data.length == 0 || abi.decode(data, (bool))), "APPROVE_FAILED");
    }

    function safeTransferETH(address to, uint256 amount) internal {
        (bool success, ) = to.call{value: amount}(new bytes(0));

        require(success, "ETH_TRANSFER_FAILED");
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.10;

/**
    @title IStrategy
    @notice This interface is implemented by strategy contracts to provide liquidity on behalf of incurdebt contract.
 */
interface IStrategy {
    /**
        @notice Add liquidity to the dex using this strategy.
        @dev Some strategies like uniswap will have tokens left over which is either sent back to 
        incur debt contract (OHM) or back to LPer's wallet address (pair token). Other strategies like
        curve will have no leftover tokens.
        This function is also only for LPing for pools with two tokens. Do not use this for pools with more than 2 tokens.
        @param _data Data needed to input into external call to add liquidity. Different for different strategies.
        @param _ohmAmount amount of OHM to LP 
        @param _user address of user that called incur debt function to do this operation.
        @return liquidity : total amount of lp tokens gained.
        ohmUnused : total amount of ohm unused in LP process and sent back to incur debt address.
        lpTokenAddress : address of LP token gained.
    */
    function addLiquidity(
        bytes memory _data,
        uint256 _ohmAmount,
        address _user
    )
        external
        returns (
            uint256 liquidity,
            uint256 ohmUnused,
            address lpTokenAddress
        );

    /**
        @notice Remove liquidity to the dex using this strategy.
        @param _data Data needed to input into external call to remove liquidity. Different for different strategies.
        @param _liquidity amount of LP tokens to remove liquidity from.
        @param _lpTokenAddress address of LP token to remove.
        @param _user address of user that called incur debt function to do this operation.
        @return ohmRecieved : total amount of ohm recieved from removing the LP. Send back to incurdebt contract.
    */
    function removeLiquidity(
        bytes memory _data,
        uint256 _liquidity,
        address _lpTokenAddress,
        address _user
    ) external returns (uint256 ohmRecieved);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

import "./IUniswapV2ERC20.sol";

interface IUniswapV2Pair is IUniswapV2ERC20 {
    function token0() external pure returns (address);

    function token1() external pure returns (address);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function mint(address to) external returns (uint256 liquidity);

    function sync() external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

interface IUniswapV2Router {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);
}

pragma solidity ^0.8.10;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

interface IUniswapV2ERC20 {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}