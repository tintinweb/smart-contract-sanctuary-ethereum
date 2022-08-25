// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import './SupportingSwap.sol';

contract PYESwapRouter is SupportingSwap {

    constructor(address _factory, address _WETH, address _USDC, uint8 _adminFee, address _adminFeeAddress, address _adminFeeSetter) {
        require(_factory != address(0) && _WETH != address(0) && _USDC != address(0), "PYESwap: INVALID_ADDRESS");
        factory = _factory;
        WETH = _WETH;
        USDC = _USDC;
        initialize(_factory, _adminFee, _adminFeeAddress, _adminFeeSetter);
    }

    receive() external payable {
        assert(msg.sender == WETH); // only accept ETH via fallback from the WETH contract
    }

    // **** ADD LIQUIDITY ****
    function _addLiquidity(
        address tokenA,
        address tokenB,
        address feeTaker,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin
    ) internal virtual returns (uint amountA, uint amountB, address pair) {
        // create the pair if it doesn't exist yet
        pair = getPair(tokenA, tokenB);
        if (pair == address(0)) {
            if(tokenA == WETH || tokenA == USDC) {
                pair = IPYESwapFactory(factory).createPair(tokenB, tokenA, feeTaker != address(0), feeTaker);
                pairFeeAddress[pair] = tokenA;
            } else {
                pair = IPYESwapFactory(factory).createPair(tokenA, tokenB, feeTaker != address(0), feeTaker);
                pairFeeAddress[pair] = tokenB;
            }
        }
        (uint reserveA, uint reserveB) = PYESwapLibrary.getReserves(tokenA, tokenB);
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
            if (tokenA == WETH || tokenA == USDC) {
                pairFeeAddress[pair] = tokenA;
            } else {
                pairFeeAddress[pair] = tokenB;
            }
        } else {
            uint amountBOptimal = PYESwapLibrary.quote(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                require(amountBOptimal >= amountBMin, 'PYESwapRouter: INSUFFICIENT_B_AMOUNT');
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint amountAOptimal = PYESwapLibrary.quote(amountBDesired, reserveB, reserveA);
                assert(amountAOptimal <= amountADesired);
                require(amountAOptimal >= amountAMin, 'PYESwapRouter: INSUFFICIENT_A_AMOUNT');
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }

    function getPair(address tokenA,address tokenB) public view returns (address){
        return IPYESwapFactory(factory).getPair(tokenA, tokenB);
    }

    function addLiquidity(
        address tokenA,
        address tokenB,
        address feeTaker,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) returns (uint amountA, uint amountB, uint liquidity) {
        address pair;
        (amountA, amountB, pair) = _addLiquidity(tokenA, tokenB, feeTaker, amountADesired, amountBDesired, amountAMin, amountBMin);
        TransferHelper.safeTransferFrom(tokenA, msg.sender, address(this), amountA);
        TransferHelper.safeTransfer(tokenA, pair, amountA);
        TransferHelper.safeTransferFrom(tokenB, msg.sender, address(this), amountB);
        TransferHelper.safeTransfer(tokenB, pair, amountB);
        liquidity = IPYESwapPair(pair).mint(to);
    }
    function addLiquidityETH(
        address token,
        address feeTaker,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external virtual override payable ensure(deadline) returns (uint amountETH, uint amountToken, uint liquidity) {
        address pair;
        (amountETH, amountToken, pair) = _addLiquidity(
            WETH,
            token,
            feeTaker,
            msg.value,
            amountTokenDesired,
            amountETHMin,
            amountTokenMin
        );

        TransferHelper.safeTransferFrom(token, msg.sender, address(this), amountToken);
        TransferHelper.safeTransfer(token, pair, amountToken);
        IWETH(WETH).deposit{value: amountETH}();
        assert(IWETH(WETH).transfer(pair, amountETH));
        liquidity = IPYESwapPair(pair).mint(to);
        // refund dust eth, if any
        if (msg.value > amountETH) TransferHelper.safeTransferETH(msg.sender, msg.value - amountETH);
    }

    // **** REMOVE LIQUIDITY ****
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) public virtual override ensure(deadline) returns (uint amountA, uint amountB) {
        address pair = PYESwapLibrary.pairFor(tokenA, tokenB);
        TransferHelper.safeTransferFrom(pair, msg.sender, pair, liquidity); // send liquidity to pair
        (uint amount0, uint amount1) = IPYESwapPair(pair).burn(to);
        (address token0,) = PYESwapLibrary.sortTokens(tokenA, tokenB);
        (amountA, amountB) = tokenA == token0 ? (amount0, amount1) : (amount1, amount0);
        require(amountA >= amountAMin, 'PYESwapRouter: INSUFFICIENT_A_AMOUNT');
        require(amountB >= amountBMin, 'PYESwapRouter: INSUFFICIENT_B_AMOUNT');
    }
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) public virtual override ensure(deadline) returns (uint amountToken, uint amountETH) {
        (amountToken, amountETH) = removeLiquidity(
            token,
            WETH,
            liquidity,
            amountTokenMin,
            amountETHMin,
            address(this),
            deadline
        );
        TransferHelper.safeTransfer(token, to, amountToken);
        IWETH(WETH).withdraw(amountETH);
        TransferHelper.safeTransferETH(to, amountETH);
    }
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external virtual override returns (uint amountA, uint amountB) {
        address pair = PYESwapLibrary.pairFor(tokenA, tokenB);
        uint value = approveMax ? type(uint).max - 1 : liquidity;
        IPYESwapPair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        (amountA, amountB) = removeLiquidity(tokenA, tokenB, liquidity, amountAMin, amountBMin, to, deadline);
    }
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external virtual override returns (uint amountToken, uint amountETH) {
        address pair = PYESwapLibrary.pairFor(token, WETH);
        uint value = approveMax ? type(uint).max - 1 : liquidity;
        IPYESwapPair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        (amountToken, amountETH) = removeLiquidityETH(token, liquidity, amountTokenMin, amountETHMin, to, deadline);
    }

    // **** REMOVE LIQUIDITY (supporting fee-on-transfer tokens) ****
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) public virtual override ensure(deadline) returns (uint amountETH) {
        (, amountETH) = removeLiquidity(
            token,
            WETH,
            liquidity,
            amountTokenMin,
            amountETHMin,
            address(this),
            deadline
        );
        TransferHelper.safeTransfer(token, to, IERC20(token).balanceOf(address(this)));
        IWETH(WETH).withdraw(amountETH);
        TransferHelper.safeTransferETH(to, amountETH);
    }
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external virtual override returns (uint amountETH) {
        address pair = PYESwapLibrary.pairFor(token, WETH);
        uint value = approveMax ? type(uint).max - 1 : liquidity;
        IPYESwapPair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        amountETH = removeLiquidityETHSupportingFeeOnTransferTokens(
            token, liquidity, amountTokenMin, amountETHMin, to, deadline
        );
    }

    function getAmountsOut(uint amountIn, address[] memory path, uint totalFee)
        public
        view
        virtual
        override
        returns (uint[] memory amounts)
    {
        return PYESwapLibrary.getAmountsOut(amountIn, path, totalFee);
    }

    function getAmountsIn(uint amountOut, address[] memory path, uint totalFee)
        public
        view
        virtual
        override
        returns (uint[] memory amounts)
    {
        return PYESwapLibrary.getAmountsIn(amountOut, path, totalFee);
    }

    
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import './interfaces/IPYESwapRouter.sol';
import './libraries/TransferHelper.sol';
import './libraries/PYESwapLibrary.sol';
import './interfaces/IERC20.sol';
import './interfaces/IWETH.sol';
import './interfaces/IToken.sol';
import './FeeStore.sol';

abstract contract SupportingSwap is FeeStore, IPYESwapRouter {


    address public override factory;
    address public override WETH;
    address public override USDC;
    uint8 private maxHops = 4;

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'PYESwapRouter: EXPIRED');
        _;
    }

    function _swap(address _feeCheck, uint[] memory amounts, address[] memory path, address _to) internal virtual {
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = PYESwapLibrary.sortTokens(input, output);

            IPYESwapPair pair = IPYESwapPair(PYESwapLibrary.pairFor(input, output));

            uint amountOut = amounts[i + 1];
            {
                uint amountsI = amounts[i];
                address[] memory _path = path;
                address finalPath = i < _path.length - 2 ? _path[i + 2] : address(0);
                (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOut) : (amountOut, uint(0));
                (uint amount0Fee, uint amount1Fee, uint _amount0Out, uint _amount1Out) = PYESwapLibrary._calculateFees(_feeCheck, input, output, amountsI, amount0Out, amount1Out);
                address to = i < _path.length - 2 ? PYESwapLibrary.pairFor(output, finalPath) : _to;

                pair.swap(
                    _amount0Out, _amount1Out, amount0Fee, amount1Fee, to, new bytes(0)
                );

            }
        }
    }


    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) returns (uint[] memory amounts) {
        require(path.length <= maxHops, "PYESwapRouter: TOO_MANY_HOPS");
        if(amountIn == 0) { return amounts; }
        address pair = PYESwapLibrary.pairFor(path[0], path[1]);

        address feeTaker = IPYESwapPair(pair).feeTaker();
        uint totalFee = feeTaker != address(0) ? IToken(feeTaker).getTotalFee(to) : 0;

        uint adminFeeDeduct;
        if(path[0] == pairFeeAddress[pair]){
            (amountIn,adminFeeDeduct) = PYESwapLibrary.adminFeeCalculation(amountIn, adminFee);
            TransferHelper.safeTransferFrom(
                path[0], msg.sender, adminFeeAddress, adminFeeDeduct
            );
        }

        TransferHelper.safeTransferFrom(
            path[0], msg.sender, pair, amounts[0]
        );
        amounts = PYESwapLibrary.amountsOut(amountIn, path, totalFee);
        require(amounts[amounts.length - 1] >= amountOutMin, 'PYESwapRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        _swap(to, amounts, path, to);
    }
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) returns (uint[] memory amounts) {
        require(path.length <= maxHops, "PYESwapRouter: TOO_MANY_HOPS");
        address pair = PYESwapLibrary.pairFor(path[0], path[1]);

        uint adminFeeDeduct;
        address feeTaker = IPYESwapPair(pair).feeTaker();
        uint totalFee;
        if(path[0] == pairFeeAddress[pair]) {
            
            totalFee = feeTaker != address(0) ? IToken(feeTaker).getTotalFee(to) : 0;
            amounts = PYESwapLibrary.amountsIn(amountOut, path, totalFee);
            require(amounts[0] <= amountInMax, 'PYESwapRouter: EXCESSIVE_INPUT_AMOUNT');
            (, adminFeeDeduct) = PYESwapLibrary.adminFeeCalculation(amounts[0], adminFee);
            TransferHelper.safeTransferFrom(
                path[0], msg.sender, adminFeeAddress, adminFeeDeduct
            );

            TransferHelper.safeTransferFrom(
                path[0], msg.sender, pair, amounts[0]
            );

        } else {
            TransferHelper.safeTransferFrom(
                path[0], msg.sender, pair, 1
            );
            totalFee = feeTaker != address(0) ? IToken(feeTaker).getTotalFee(to) : 0;
            amounts = PYESwapLibrary.amountsIn(amountOut, path, totalFee);
            require(amounts[0] <= amountInMax, "PYESwapRouter: EXCESSIVE_INPUT_AMOUNT");
            if(feeTaker != address(0)) { IToken(feeTaker).handleFee(0, path[1]); }
            TransferHelper.safeTransferFrom(
                path[0], msg.sender, pair, amounts[0] - 1
            );
        }

        _swap(to, amounts, path, to);
    }

    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    virtual
    override
    payable
    ensure(deadline)
    returns (uint[] memory amounts)
    {
        require(path.length <= maxHops, "PYESwapRouter: TOO_MANY_HOPS");
        require(path[0] == WETH, "PYESwapRouter: INVALID_PATH");

        uint amountIn = msg.value;
        if(amountIn == 0) { return amounts; }
        address pair = PYESwapLibrary.pairFor(path[0], path[1]);

        address feeTaker = IPYESwapPair(pair).feeTaker();
        uint totalFee = feeTaker != address(0) ? IToken(feeTaker).getTotalFee(to) : 0;

        uint adminFeeDeduct;
        if(path[0] == pairFeeAddress[pair]){
            (amountIn, adminFeeDeduct) = PYESwapLibrary.adminFeeCalculation(amountIn, adminFee);
            if(address(this) != adminFeeAddress){
                payable(adminFeeAddress).transfer(adminFeeDeduct);
            }
        }

        amounts = PYESwapLibrary.amountsOut(amountIn, path, totalFee);

        require(amounts[amounts.length - 1] >= amountOutMin, "PYESwapRouter: INSUFFICIENT_OUTPUT_AMOUNT");
        IWETH(WETH).deposit{value: amounts[0]}();
        assert(IWETH(WETH).transfer(pair, amounts[0]));
        _swap(to, amounts, path, to);
    }

    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
    external
    virtual
    override
    ensure(deadline)
    returns (uint[] memory amounts)
    {
        require(path.length <= maxHops, "PYESwapRouter: TOO_MANY_HOPS");
        require(path[path.length - 1] == WETH, 'PYESwapRouter: INVALID_PATH');

        uint adminFeeDeduct;
        address pair = PYESwapLibrary.pairFor(path[0], path[1]);
        address feeTaker = IPYESwapPair(pair).feeTaker();
        
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, pair, 1
        );
        uint totalFee = feeTaker != address(0) ? IToken(feeTaker).getTotalFee(to) : 0;
        amounts = PYESwapLibrary.amountsIn(amountOut, path, totalFee);
        require(amounts[0] <= amountInMax, 'PYESwapRouter: EXCESSIVE_INPUT_AMOUNT');

        if(feeTaker != address(0)) { IToken(feeTaker).handleFee(0, WETH); }
        
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, pair, amounts[0] - 1
        );
        
        _swap(to, amounts, path, address(this));

        uint amountETHOut = amounts[amounts.length - 1];
        if(path[1] == pairFeeAddress[pair]){
            (amountETHOut,adminFeeDeduct) = PYESwapLibrary.adminFeeCalculation(amountETHOut,adminFee);
        }
        if(totalFee > 0) {
            amountETHOut = (amountETHOut * (10000 - totalFee)) / 10000;
        }
        IWETH(WETH).withdraw(amountETHOut);
        TransferHelper.safeTransferETH(to, amountETHOut);
    }
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    virtual
    override
    ensure(deadline)
    returns (uint[] memory amounts)
    {
        require(path.length <= maxHops, "PYESwapRouter: TOO_MANY_HOPS");
        require(path[path.length - 1] == WETH, 'PYESwapRouter: INVALID_PATH');
        if(amountIn == 0) { return amounts; }
        uint adminFeeDeduct;
        address pair = PYESwapLibrary.pairFor(path[0], path[1]);

        address feeTaker = IPYESwapPair(pair).feeTaker();

        if(path[0] == pairFeeAddress[pair]){
            (amountIn,adminFeeDeduct) = PYESwapLibrary.adminFeeCalculation(amountIn, adminFee);
            TransferHelper.safeTransferFrom(
                path[0], msg.sender, adminFeeAddress, adminFeeDeduct
            );
        }

        TransferHelper.safeTransferFrom(
            path[0], msg.sender, pair, amounts[0]
        );
        uint totalFee = feeTaker != address(0) ? IToken(feeTaker).getTotalFee(to) : 0;
        amounts = PYESwapLibrary.amountsOut(amountIn, path, totalFee);
        require(amounts[amounts.length - 1] >= amountOutMin, 'PYESwapRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        _swap(to, amounts, path, address(this));

        uint amountETHOut = amounts[amounts.length - 1];
        if(path[1] == pairFeeAddress[pair]){
            (amountETHOut,adminFeeDeduct) = PYESwapLibrary.adminFeeCalculation(amountETHOut,adminFee);
        }
        IWETH(WETH).withdraw(amountETHOut);
        TransferHelper.safeTransferETH(to, amountETHOut);
    }
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
    external
    virtual
    override
    payable
    ensure(deadline)
    returns (uint[] memory amounts)
    {
        require(path.length <= maxHops, "PYESwapRouter: TOO_MANY_HOPS");
        require(path[0] == WETH, 'PYESwapRouter: INVALID_PATH');

        address pair = PYESwapLibrary.pairFor(path[0], path[1]);

        address feeTaker = IPYESwapPair(pair).feeTaker();
        uint totalFee = feeTaker != address(0) ? IToken(feeTaker).getTotalFee(to) : 0;

        uint adminFeeDeduct;
        if(path[0] == pairFeeAddress[pair]){
            amounts = PYESwapLibrary.amountsIn(amountOut, path, totalFee);
            require(amounts[0] <= msg.value, 'PYESwapRouter: EXCESSIVE_INPUT_AMOUNT');

            ( ,adminFeeDeduct) = PYESwapLibrary.adminFeeCalculation(amounts[0], adminFee);
            if(address(this) != adminFeeAddress){
                payable(adminFeeAddress).transfer(adminFeeDeduct);
            }

            IWETH(WETH).deposit{value: amounts[0]}();
            assert(IWETH(WETH).transfer(pair, amounts[0]));

        } else {
            amounts = PYESwapLibrary.amountsIn(amountOut, path, totalFee);
            require(amounts[0] <= msg.value, 'PYESwapRouter: EXCESSIVE_INPUT_AMOUNT');
            IWETH(WETH).deposit{value: amounts[0]}();
            assert(IWETH(WETH).transfer(PYESwapLibrary.pairFor(path[0], path[1]), amounts[0]));
        }

        _swap(to, amounts, path, to);
        // refund dust eth, if any
        uint bal = amounts[0] + adminFeeDeduct;
        if (msg.value > bal) TransferHelper.safeTransferETH(msg.sender, msg.value - bal);
    }


    // **** SWAP (supporting fee-on-transfer tokens) ****
    // requires the initial amount to have already been sent to the first pair
    function _swapSupportingFeeOnTransferTokens(address _feeCheck, address[] memory path, address _to) internal virtual {
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = PYESwapLibrary.sortTokens(input, output);

            IPYESwapPair pair = IPYESwapPair(PYESwapLibrary.pairFor(input, output));

            (uint amountInput, uint amountOutput) = PYESwapLibrary._calculateAmounts(_feeCheck, input, output, token0);
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOutput) : (amountOutput, uint(0));

            (uint amount0Fee, uint amount1Fee, uint _amount0Out, uint _amount1Out) = PYESwapLibrary._calculateFees(_feeCheck, input, output, amountInput, amount0Out, amount1Out);

            {
                address[] memory _path = path;
                address finalPath = i < _path.length - 2 ? _path[i + 2] : address(0);
                address to = i < _path.length - 2 ? PYESwapLibrary.pairFor(output, finalPath) : _to;
                pair.swap(_amount0Out, _amount1Out, amount0Fee, amount1Fee, to, new bytes(0));
            }
        }
    }
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) {
        require(path.length <= maxHops, "PYESwapRouter: TOO_MANY_HOPS");
        if(amountIn == 0) { return; }
        address pair = PYESwapLibrary.pairFor(path[0], path[1]);
        uint adminFeeDeduct;
        if(path[0] == pairFeeAddress[pair]){
            (amountIn,adminFeeDeduct) = PYESwapLibrary.adminFeeCalculation(amountIn,adminFee);
            TransferHelper.safeTransferFrom(
                path[0], msg.sender, adminFeeAddress, adminFeeDeduct
            );
        }

        TransferHelper.safeTransferFrom(
            path[0], msg.sender, pair, amountIn
        );
        uint balanceBefore = IERC20(path[path.length - 1]).balanceOf(to);
        _swapSupportingFeeOnTransferTokens(to, path, to);
        if(path[1] == pairFeeAddress[pair]){
            (amountOutMin,adminFeeDeduct) = PYESwapLibrary.adminFeeCalculation(amountOutMin,adminFee);
        }
        require(
            IERC20(path[path.length - 1]).balanceOf(to) - balanceBefore >= amountOutMin,
            'PYESwapRouter: INSUFFICIENT_OUTPUT_AMOUNT'
        );
    }
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    )
    external
    virtual
    override
    payable
    ensure(deadline)
    {
        require(path.length <= maxHops, "PYESwapRouter: TOO_MANY_HOPS");
        require(path[0] == WETH, 'PYESwapRouter: INVALID_PATH');
        uint amountIn = msg.value;
        if(amountIn == 0) { return; }
        address pair = PYESwapLibrary.pairFor(path[0], path[1]);
        uint adminFeeDeduct;
        if(path[0] == pairFeeAddress[pair]){
            (amountIn,adminFeeDeduct) = PYESwapLibrary.adminFeeCalculation(amountIn,adminFee);
            if(address(this) != adminFeeAddress){
                payable(adminFeeAddress).transfer(adminFeeDeduct);
            }
        }

        IWETH(WETH).deposit{value: amountIn}();
        assert(IWETH(WETH).transfer(pair, amountIn));
        uint balanceBefore = IERC20(path[path.length - 1]).balanceOf(to);
        _swapSupportingFeeOnTransferTokens(to, path, to);
        if(path[1] == pairFeeAddress[pair]){
            (amountOutMin,adminFeeDeduct) = PYESwapLibrary.adminFeeCalculation(amountOutMin,adminFee);
        }
        require(
            IERC20(path[path.length - 1]).balanceOf(to) - balanceBefore >= amountOutMin,
            'PYESwapRouter: INSUFFICIENT_OUTPUT_AMOUNT'
        );
    }
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    )
    external
    virtual
    override
    ensure(deadline)
    {
        require(path.length <= maxHops, "PYESwapRouter: TOO_MANY_HOPS");
        require(path[path.length - 1] == WETH, 'PYESwapRouter: INVALID_PATH');
        if(amountIn == 0) { return; }
        address pair = PYESwapLibrary.pairFor(path[0], path[1]);

        TransferHelper.safeTransferFrom(
            path[0], msg.sender, pair, amountIn
        );
        _swapSupportingFeeOnTransferTokens(to, path, address(this));
        uint amountOut = IERC20(WETH).balanceOf(address(this));
        amountOutMin;
        
        IWETH(WETH).withdraw(amountOut);
        TransferHelper.safeTransferETH(to, amountOut);
    }
    function setMaxHops(uint8 _maxHops) external {
        require(msg.sender == adminFeeSetter);
        require(_maxHops >= 2);
        maxHops = _maxHops;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import './interfaces/IPYESwapFactory.sol';
import './interfaces/IPYESwapPair.sol';

abstract contract FeeStore {
    uint public adminFee;
    address public adminFeeAddress;
    address public adminFeeSetter;
    address public factoryAddress;
    mapping (address => address) public pairFeeAddress;

    event AdminFeeSet(uint adminFee, address adminFeeAddress);

    function initialize(address _factory, uint256 _adminFee, address _adminFeeAddress, address _adminFeeSetter) internal {
        factoryAddress = _factory;
        adminFee = _adminFee;
        adminFeeAddress = _adminFeeAddress;
        adminFeeSetter = _adminFeeSetter;
    }

    function setAdminFee (address _adminFeeAddress, uint _adminFee) external {
        require(msg.sender == adminFeeSetter);
        require(_adminFee <= 100);
        adminFeeAddress = _adminFeeAddress;
        adminFee = _adminFee;
        emit AdminFeeSet(adminFee, adminFeeAddress);
    }

    function setAdminFeeSetter(address _adminFeeSetter) external {
        require(msg.sender == adminFeeSetter);
        adminFeeSetter = _adminFeeSetter;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface IToken {
    function addPair(address pair, address token) external;
    function depositLPFee(uint amount, address token) external;
    // function isExcludedFromFee(address account) external view returns (bool);
    function getTotalFee(address _feeCheck) external view returns (uint);
    function handleFee(uint amount, address token) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import '../interfaces/IPYESwapPair.sol';
import '../interfaces/IPYESwapFactory.sol';
import '../interfaces/IToken.sol';
import '../interfaces/IERC20.sol';

import "./SafeMath.sol";

library PYESwapLibrary {

    address constant factory = 0x0fC5F7Ec0fa80933677F63c7b896A26CFC6b76a5;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'PYESwapLibrary: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'PYESwapLibrary: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint160(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'42b17b9ed6f45899a012923d0f2518a13ffd33f7548e091d1718d57dd3a5c9ce' // init code hash
            )))));
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,,) = IPYESwapPair(pairFor(tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'PYESwapLibrary: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'PYESwapLibrary: INSUFFICIENT_LIQUIDITY');
        amountB = (amountA * reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut, bool tokenFee, bool baseIn, uint totalFee) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'PYESwapLibrary: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'PYESwapLibrary: INSUFFICIENT_LIQUIDITY');
        uint amountInMultiplier = baseIn && tokenFee ? 10000 - totalFee : 10000;
        uint amountInWithFee = amountIn * amountInMultiplier;
        uint numerator = amountInWithFee * reserveOut;
        uint denominator = (reserveIn * 10000) + amountInWithFee;
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut, bool tokenFee, bool baseOut, uint totalFee) internal pure returns (uint, uint) {
        require(amountOut > 0, 'PYESwapLibrary: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'PYESwapLibrary: INSUFFICIENT_LIQUIDITY');
        uint amountOutMultiplier = tokenFee ? 10000 - totalFee : 10000;
        uint amountOutWithFee = (amountOut * 10000 ) / amountOutMultiplier;
        uint numerator = reserveIn * amountOutWithFee;
        uint denominator = reserveOut - amountOutWithFee;
        uint amountIn = (numerator / denominator) + 1;
        return (amountIn, baseOut ? amountOutWithFee : amountOut);
    }

    function amountsOut(uint amountIn, address[] memory path, uint totalFee) internal view returns (uint[] memory) {
        return getAmountsOut(amountIn, path, totalFee);
    }

    function amountsIn(uint amountOut, address[] memory path, uint totalFee) internal view returns (uint[] memory) {
        return getAmountsIn(amountOut, path, totalFee);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(uint amountIn, address[] memory path, uint totalFee) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'PYESwapLibrary: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            IPYESwapPair pair = IPYESwapPair(pairFor(path[i], path[i + 1]));
            address baseToken = pair.baseToken();
            bool baseIn = baseToken == path[i] && baseToken != address(0);
            (uint reserveIn, uint reserveOut) = getReserves(path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut, baseToken != address(0), baseIn, totalFee);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(uint amountOut, address[] memory path, uint totalFee) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'PYESwapLibrary: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            IPYESwapPair pair = IPYESwapPair(pairFor(path[i - 1], path[i]));
            address baseToken = pair.baseToken();
            bool baseOut = baseToken == path[i] && baseToken != address(0);
            (uint reserveIn, uint reserveOut) = getReserves(path[i - 1], path[i]);
            (amounts[i - 1], amounts[i]) = getAmountIn(amounts[i], reserveIn, reserveOut, baseToken != address(0), baseOut, totalFee);
        }
    }

    function adminFeeCalculation(uint256 _amounts,uint256 _adminFee) internal pure returns (uint256,uint256) {
        uint adminFeeDeduct = (_amounts * _adminFee) / (10000);
        _amounts = _amounts - adminFeeDeduct;

        return (_amounts,adminFeeDeduct);
    }

    function _calculateFees(address _feeCheck, address input, address output, uint amountIn, uint amount0Out, uint amount1Out) internal view returns (uint amount0Fee, uint amount1Fee, uint _amount0Out, uint _amount1Out) {
        IPYESwapPair pair = IPYESwapPair(pairFor(input, output));
        (address token0,) = sortTokens(input, output);
        address baseToken = pair.baseToken();
        address feeTaker = pair.feeTaker();
        uint totalFee = feeTaker != address(0) ? IToken(feeTaker).getTotalFee(_feeCheck) : 0;
        
        amount0Fee = baseToken != token0 ? uint(0) : input == token0 ? (amountIn * totalFee) / (10**4) : (amount0Out * totalFee) / (10**4);
        amount1Fee = baseToken == token0 ? uint(0) : input != token0 ? (amountIn * totalFee) / (10**4) : (amount1Out * totalFee) / (10**4);
        _amount0Out = amount0Out > 0 ? amount0Out - amount0Fee : amount0Out;
        _amount1Out = amount1Out > 0 ? amount1Out - amount1Fee : amount1Out;
    }

    function _calculateAmounts(address _feeCheck, address input, address output, address token0) internal view returns (uint amountInput, uint amountOutput) {
        IPYESwapPair pair = IPYESwapPair(pairFor(input, output));

        (uint reserve0, uint reserve1,, address baseToken) = pair.getReserves();
        address feeTaker = pair.feeTaker();
        uint totalFee = feeTaker != address(0) ? IToken(feeTaker).getTotalFee(_feeCheck) : 0;
        bool baseIn = baseToken == input && baseToken != address(0);
        (uint reserveInput, uint reserveOutput) = input == token0 ? (reserve0, reserve1) : (reserve1, reserve0);

        amountInput = IERC20(input).balanceOf(address(pair)) - reserveInput;
        amountOutput = getAmountOut(amountInput, reserveInput, reserveOutput, baseToken != address(0), baseIn, totalFee);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
  function safeApprove(
    address token,
    address to,
    uint256 value
) internal {
    // bytes4(keccak256(bytes('approve(address,uint256)')));
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
    require(
      success && (data.length == 0 || abi.decode(data, (bool))),
      'TransferHelper::safeApprove: approve failed'
    );
  }

  function safeTransfer(
    address token,
    address to,
    uint256 value
) internal {
    // bytes4(keccak256(bytes('transfer(address,uint256)')));
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
    require(
      success && (data.length == 0 || abi.decode(data, (bool))),
      'TransferHelper::safeTransfer: transfer failed'
    );
  }

  function safeTransferFrom(
    address token,
    address from,
    address to,
    uint256 value
) internal {
    // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
    require(
      success && (data.length == 0 || abi.decode(data, (bool))),
      'TransferHelper::transferFrom: transferFrom failed'
    );
  }

  function safeTransferETH(address to, uint256 value) internal {
    (bool success, ) = to.call{value: value}(new bytes(0));
    require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import './IPYESwapRouter01.sol';

interface IPYESwapRouter is IPYESwapRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }

    function div(uint x, uint y) internal pure returns (uint z) {
        require(y > 0, "ds-math-div-underflow");
        z = x / y;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface IPYESwapFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);
    function pairExist(address pair) external view returns (bool);

    function createPair(address tokenA, address tokenB, bool supportsTokenFee, address feeTaker) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
    function routerInitialize(address) external;
    function routerAddress() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface IPYESwapPair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function baseToken() external view returns (address);
    function feeTaker() external view returns (address);
    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    function updateTotalFee(uint totalFee) external returns (bool);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast, address _baseToken);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, uint amount0Fee, uint amount1Fee, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
    function setBaseToken(address _baseToken) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface IPYESwapRouter01 {
    function factory() external view returns (address);
    function WETH() external view returns (address);
    function USDC() external view returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        // bool supportsTokenFee,
        address feeTaker,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        // bool supportsTokenFee,
        address feeTaker,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function getAmountsOut(uint256 amountIn, address[] calldata path, uint totalFee) external view returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path, uint totalFee) external view returns (uint256[] memory amounts);
}