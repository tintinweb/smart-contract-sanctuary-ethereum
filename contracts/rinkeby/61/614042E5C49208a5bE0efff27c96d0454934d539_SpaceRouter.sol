// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.10;

import "./ICO/ISpaceCoin.sol";
import "./IPool.sol";

contract SpaceRouter {
    address public immutable spaceCoinLP;
    address public immutable spaceCoinToken;

    event LiquidityAdd(
        address indexed to,
        uint256 amountOfSpc,
        uint256 amountOfEth,
        uint256 lpTokensMinted
    );
    event LiquidityRemove(
        address indexed to,
        uint256 amountOfSpc,
        uint256 amountOfEth,
        uint256 lpTokensBurned
    );
    event Swap(address indexed to, uint256 spcAmount, uint256 ethAmount);

    constructor(address _spaceCoinToken, address _spaceCoinLp) {
        spaceCoinToken = _spaceCoinToken;
        spaceCoinLP = _spaceCoinLp;
    }

    function addLiquidity(
        address to,
        uint256 spcDesired,
        uint256 spcMin,
        uint256 ethMin
    ) external payable returns (uint256 amountSpc, uint256 amountEth) {
        uint256 ethDesired = msg.value;

        require(spcDesired > 0, "SPC_CANT_BE_ZERO");
        require(ethDesired > 0, "ETH_CANT_BE_ZERO");
        // First liquidity add to the pool sets the ratio

        (uint256 spcReserve, uint256 ethReserve) = IPool(spaceCoinLP)
            .getReserves();

        if (spcReserve == 0 && ethReserve == 0) {
            amountSpc = spcDesired;
            amountEth = ethDesired;
        } else {
            // Try to calculate spc with msg.value first to avoid refunding eth
            uint256 spcOptimal = quoteAmount(
                ethDesired,
                ethReserve,
                spcReserve
            );
            if (spcOptimal <= spcDesired) {
                require(spcOptimal >= spcMin, "NOT_ENOUGH_ETH");
                amountSpc = spcOptimal;
                amountEth = ethDesired;
            } else {
                // If the eth sent is greater that the spc desired calculate eth cost of spc desired
                uint256 ethOptimal = quoteAmount(
                    spcDesired,
                    spcReserve,
                    ethReserve
                );
                require(ethOptimal >= ethMin, "NOT_ENOUGH_SPC");
                amountSpc = spcDesired;
                amountEth = ethOptimal;
            }
        }
        // Transfer correct ratio amount to Lp contract
        _safeTransferFromSpc(msg.sender, spaceCoinLP, amountSpc);
        // Call minLpTokens function to get token
        uint256 lpTokens = IPool(spaceCoinLP).mintLpTokens{value: amountEth}(
            to
        );
        // Emiting event before if caller reenter the order of events is correct
        emit LiquidityAdd(to, amountSpc, amountEth, lpTokens);
        // Refund remainding ETH
        if (msg.value > amountEth) {
            _safeTransferEth(msg.sender, msg.value - amountEth);
        }
    }

    function removeLiquidity(
        address to,
        uint256 liquidityTokens,
        uint256 spcAmountMin,
        uint256 ethAmountMin
    ) external {
        // Approve pool to spend LP tokens of caller in front end
        bool success = IPool(spaceCoinLP).transferFrom(
            msg.sender,
            spaceCoinLP,
            liquidityTokens
        );

        require(success, "LP_TOKENS_TRANSFER_FAILED");

        (uint256 spcAmount, uint256 ethAmount) = IPool(spaceCoinLP)
            .burnLpTokens(to);
        require(spcAmount >= spcAmountMin, "SPC_MIN_NOT_FULFILLED");
        require(ethAmount >= ethAmountMin, "ETH_MIN_NOT_FULFILLED");
        emit LiquidityRemove(to, spcAmount, ethAmount, liquidityTokens);
    }

    function swap(
        address to,
        uint256 amountSpcIn,
        uint256 amountEthOutMin,
        uint256 amountSpcOutMin
    ) external payable {
        uint256 amountEthIn = msg.value;
        // Since the router should guide the user, it's ilogical to think someone would sends two assets
        require(amountEthIn == 0 || amountSpcIn == 0, "ONLY_ONE_WAY_SWAP");
        if (amountSpcIn > 0) {
            _safeTransferFromSpc(msg.sender, spaceCoinLP, amountSpcIn);
        }
        // If token has tax on the actualSpcIn will differ from the amountSpcIn
        uint256 actualSpcIn = _getSpcIn();
        (uint256 amountSpcOut, uint256 amountEthOut) = getAmountOut(
            actualSpcIn,
            amountEthIn
        );
        require(amountEthOut >= amountEthOutMin, "MIN_ETH_NOT_REACHED");
        uint256 spcBefore = ISpaceCoin(spaceCoinToken).balanceOf(to);
        IPool(spaceCoinLP).swap{value: amountEthIn}(
            to,
            amountSpcOut,
            amountEthOut
        );
        // Check if the SPC sent is more or equal than the amountSpcOutMin
        require(
            ISpaceCoin(spaceCoinToken).balanceOf(to) - spcBefore >=
                amountSpcOutMin,
            "MIN_SPC_NOT_REACHED"
        );

        emit Swap(to, amountSpcOut, amountEthOut);
    }

    function quoteAmount(
        uint256 amountI,
        uint256 reserveI,
        uint256 reserveO
    ) public pure returns (uint256 amountO) {
        require(amountI > 0, "INSUFFICIENT_AMOUNT");
        require(reserveI > 0 && reserveO > 0, "NO_LIQUIDITY");
        amountO = (amountI * reserveO) / reserveI;
    }

    function getAmountOut(uint256 spcIn, uint256 ethIn)
        public
        view
        returns (uint256 spcOut, uint256 ethOut)
    {
        (uint256 spcReserve, uint256 ethReserve) = IPool(spaceCoinLP)
            .getReserves();
        if (spcReserve == 0 || ethReserve == 0) {
            ethOut = 0;
            spcOut = 0;
        } else {
            if (spcIn > 0) {
                uint256 numerator = spcIn * 99 * ethReserve;
                uint256 denominator = (spcReserve * 100) + (spcIn * 99);
                ethOut = numerator / denominator;
            }
            if (ethIn > 0) {
                uint256 numerator = ethIn * 99 * spcReserve;
                uint256 denominator = (ethReserve * 100) + (ethIn * 99);
                spcOut = numerator / denominator;
            }
        }
    }

    function _getSpcIn() internal view returns (uint256 realSpcIn) {
        (uint256 spcReserve, ) = IPool(spaceCoinLP).getReserves();
        (uint256 spcBalance, ) = IPool(spaceCoinLP).getBalances();
        realSpcIn = spcBalance - spcReserve;
    }

    function _safeTransferFromSpc(
        address from,
        address to,
        uint256 spcAmountOut
    ) internal {
        bool success = ISpaceCoin(spaceCoinToken).transferFrom(
            from,
            to,
            spcAmountOut
        );
        require(success, "SPC_TRANSFER_FAILED");
    }

    function _safeTransferEth(address to, uint256 ethAmount) internal {
        (bool success, bytes memory data) = to.call{value: ethAmount}("");
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "ETH_TRANSFER_FAILED"
        );
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;

interface ISpaceCoin {
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    event TaxActive();

    event TaxInactive();

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function activateTax() external;

    function deactivateTax() external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;

interface IPool {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function getReserves() external view returns (uint256 _spc, uint256 _eth);

    function getBalances() external view returns (uint256 _spc, uint256 _eth);

    function mintLpTokens(address to)
        external
        payable
        returns (uint256 liquidity);

    function burnLpTokens(address to)
        external
        returns (uint256 spcAmount, uint256 ethAmount);

    function swap(
        address to,
        uint256 spcAmountOut,
        uint256 ethAmountOut
    ) external payable;

    event Minted(address indexed to, uint256 lpAmount);
    event Burned(address indexed from, uint256 lpAmount);
    event Swap(
        address indexed sender,
        uint256 amountSpcIn,
        uint256 amountEthIn,
        uint256 amountSpcOut,
        uint256 amountEthOut,
        address indexed to
    );
    event Synced(uint256 spcReserve, uint256 ethReserve);
}