/**
 *Submitted for verification at Etherscan.io on 2023-01-31
*/

//SPDX-License-Identifier: MIT

pragma abicoder v2;
pragma solidity ^0.8.7;

pragma solidity >=0.6.2;

interface IPancakeRouter01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

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

    function getAmountsOut(
        uint256 amountIn,
        address[] calldata path
    ) external view returns (uint256[] memory amounts);

    function getAmountsIn(
        uint256 amountOut,
        address[] calldata path
    ) external view returns (uint256[] memory amounts);
}

// File: contracts\interfaces\IPancakeRouter02.sol

pragma solidity >=0.6.2;

interface IPancakeRouter02 is IPancakeRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

pragma solidity >=0.5.0;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

// File: contracts\interfaces\IWETH.sol

pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;
    // function transfer(address to, uint256 value) external returns (bool);
    // function withdraw(uint256) external;
    // function transferFrom(address from ,address to, uint256 value) external returns (bool);
}

pragma solidity ^0.8.7;

contract honeyCheckerV5 {
    IPancakeRouter02 public router;
    uint256 approveInfinity =
        115792089237316195423570985008687907853269984665640564039457584007913129639935;

    struct HoneyResponse {
        uint256 buyResult;
        uint256 expectedbuyAmount;
        uint256 sellResult;
        uint256 expectedsellAmount;
        uint256 tokenBalance2;
        uint256 buyGasCost;
        uint256 sellGasCost;
    }
    HoneyResponse public responsestruct;

    // address public BUSDaddress = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;//goerli测试链真实的busd地址
    address public BUSDaddress = 0x810cf6f8AcF0A5133467cF06a525Ab9952164065; //自己部署的yBUSD
    address public WETHaddress = 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6;

    IERC20 wETH = IERC20(WETHaddress); // wETH
    IERC20 BUSD = IERC20(BUSDaddress); // BUSD

    constructor() {}

    //随意更改价值币的地址，主要用于测试用
    function setwcoinaddress(address wcoin) public {
        BUSDaddress = wcoin;
    }

    function honeyCheckstruct(
        address targetTokenAddress,
        address idexRouterAddres
    ) external payable returns (HoneyResponse memory) {
        router = IPancakeRouter02(idexRouterAddres);

        // IERC20 wETH = IERC20(router.WETH()); // wETH
        IERC20 targetToken = IERC20(targetTokenAddress); //Test Token

        address[] memory buyPath = new address[](2);
        buyPath[0] = WETHaddress;
        buyPath[1] = targetTokenAddress;

        address[] memory sellPath = new address[](2);
        sellPath[0] = targetTokenAddress;
        sellPath[1] = WETHaddress;

        uint256[] memory buyamounts = router.getAmountsOut(msg.value, buyPath);

        uint256 expectedbuyAmount = buyamounts[1];

        IWETH(router.WETH()).deposit{value: msg.value}();

        wETH.approve(idexRouterAddres, approveInfinity);

        uint256 wETHBalance = wETH.balanceOf(address(this));

        uint256 startBuyGas = gasleft();

        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            wETHBalance,
            1,
            buyPath,
            address(this),
            block.timestamp + 10
        );

        uint256 buyResult = targetToken.balanceOf(address(this));

        uint256[] memory sellamounts = router.getAmountsOut(buyResult, sellPath);
        uint256 expectedsellAmount = sellamounts[1];

        uint256 finishBuyGas = gasleft();

        targetToken.approve(idexRouterAddres, approveInfinity);

        uint256 startSellGas = gasleft();

        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            buyResult,
            1,
            sellPath,
            address(this),
            block.timestamp + 10
        );

        uint256 finishSellGas = gasleft();

        uint256 tokenBalance2 = targetToken.balanceOf(address(this));

        uint256 sellResult = wETH.balanceOf(address(this));

        // uint256 buyGasCost = startBuyGas - finishBuyGas;
        // uint256 sellGasCost = startSellGas - finishSellGas;

        responsestruct = HoneyResponse(
            expectedbuyAmount,
            buyResult,
            expectedsellAmount,
            sellResult,
            tokenBalance2,
            startBuyGas - finishBuyGas,
            startSellGas - finishSellGas
        );

        wETH.transferFrom(address(this), msg.sender, sellResult);
        return (responsestruct);
    }

    function honeyCheckbusdstruct(
        address targetTokenAddress,
        address idexRouterAddres,
        uint256 amount
    ) external returns (HoneyResponse memory) {
        router = IPancakeRouter02(idexRouterAddres);

      
        IERC20 targetToken = IERC20(targetTokenAddress); //Test Token

        BUSD.transferFrom(msg.sender, address(this), amount);

      

        address[] memory buyPath = new address[](2);
        buyPath[0] = BUSDaddress;
        buyPath[1] = targetTokenAddress;

        address[] memory sellPath = new address[](2);
        sellPath[0] = targetTokenAddress;
        sellPath[1] = BUSDaddress;

        uint256[] memory buyamounts = router.getAmountsOut(amount, buyPath);
        uint256 expectedbuyAmount = buyamounts[1];

        BUSD.approve(idexRouterAddres, approveInfinity);

        uint256 BUSDBalance = BUSD.balanceOf(address(this));

        uint256 startBuyGas = gasleft();

        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            BUSDBalance,
            1,
            buyPath,
            address(this),
            block.timestamp + 10
        );

        uint256 buyResult = targetToken.balanceOf(address(this));

        uint256[] memory sellamounts = router.getAmountsOut(buyResult, sellPath);
        uint256 expectedsellAmount = sellamounts[1];

        uint256 finishBuyGas = gasleft();

        targetToken.approve(idexRouterAddres, approveInfinity);

        uint256 startSellGas = gasleft();

        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            buyResult,
            1,
            sellPath,
            address(this),
            block.timestamp + 10
        );

        uint256 finishSellGas = gasleft();

        uint256 tokenBalance2 = targetToken.balanceOf(address(this));

        uint256 sellResult = BUSD.balanceOf(address(this));

        // uint256 buyGasCost = startBuyGas - finishBuyGas;
        // uint256 sellGasCost = startSellGas - finishSellGas;

        responsestruct = HoneyResponse(
            expectedbuyAmount,
            buyResult,
            expectedsellAmount,
            sellResult,
            tokenBalance2,
            startBuyGas - finishBuyGas,
            startSellGas - finishSellGas
        );

        BUSD.transfer( msg.sender, sellResult);
        return (responsestruct);
    }

    function getwethback() public {
        
        wETH.transfer( msg.sender, wETH.balanceOf(address(this)));
    }

    function getanywethback(address add) public {
        
        IERC20 anywcoin = IERC20(add); // wETH
        anywcoin.transfer( msg.sender, anywcoin.balanceOf(address(this)));
    }

    fallback() external payable {}

    receive() external payable {}

    event Response(bool success, bytes data);

    address cakeV2 = 0xEfF92A263d31888d860bD50809A8D171709b7b1c;
    address WETH = 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6;
    address cakegetpair = 0x1097053Fd2ea711dad45caCcc45EfF7548fCB362;
    //address tokenDog;
    uint256 amountMax = type(uint256).max;
    uint256 amountIn;
    uint256 amountOutMin;
    address[] path;
    address to;
    uint256 deadline;
    uint32 blockTimestampLast;
    address token0;
    address token1;
    address pairaddress;
    uint112 reserve0;
    uint112 reserve1;

    function gettokendoginformation(address tokenDog) public returns (uint8) {
        (bool success, bytes memory data) = tokenDog.call(abi.encodeWithSignature("decimals()"));
        emit Response(success, data);
        return abi.decode(data, (uint8));
    }

    function get() public view returns (uint256, uint256, address[] memory, address, uint256) {
        return (amountIn, amountOutMin, path, to, deadline);
    }

    //approve+用土狗币去买价值币
    function frontbuy11(
        address dogtokenaddress,
        uint256 myfrontrunspendtokenamount,
        uint256 myfrontrungettokenamount,
        address[] memory path1,
        address to1,
        uint256 deadline1
    ) public {
        //第1步授权土狗币给cakev2
        (bool success1, bytes memory data1) = dogtokenaddress.call(
            abi.encodeWithSignature("approve(address,uint256)", cakeV2, amountMax)
        );
        emit Response(success1, data1);
        //抢买
        (bool success2, bytes memory data2) = cakeV2.call(
            abi.encodeWithSignature(
                "swapExactTokensForTokens(uint256,uint256,address[],address,uint256)",
                myfrontrunspendtokenamount,
                myfrontrungettokenamount,
                path1,
                to1,
                deadline1
            )
        );
        emit Response(success2, data2);
    }

    //没有授权，普通在cake里面swap
    function frontbuy00(
        uint256 myfrontrunspendtokenamount,
        uint256 myfrontrungettokenamount,
        address[] memory path1,
        address to1,
        uint256 deadline1
    ) public {
        //抢买
        (bool success2, bytes memory data2) = cakeV2.call(
            abi.encodeWithSignature(
                "swapExactTokensForTokens(uint256,uint256,address[],address,uint256)",
                myfrontrunspendtokenamount,
                myfrontrungettokenamount,
                path1,
                to1,
                deadline1
            )
        );
        emit Response(success2, data2);
    }

    function sellafterbuy(
        address dogtokenaddress,
        uint256 myfrontrunspendtokenamount,
        uint256 myfrontrungettokenamount,
        address[] memory path1,
        address to1,
        uint256 deadline1
    ) public {
        //第1步授权土狗币给cakev2
        (bool success1, bytes memory data1) = dogtokenaddress.call(
            abi.encodeWithSignature("approve(address,uint256)", cakeV2, amountMax)
        );
        emit Response(success1, data1);
        //抢买
        (bool success2, bytes memory data2) = cakeV2.call(
            abi.encodeWithSignature(
                "swapExactTokensForTokens(uint256,uint256,address[],address,uint256)",
                myfrontrunspendtokenamount,
                myfrontrungettokenamount,
                path1,
                to1,
                deadline1
            )
        );
        emit Response(success2, data2);
    }

    function getinformation11(
        address dogtokenaddress,
        address account
    ) public returns (string memory, string memory, uint256, uint8, uint256) {
        (, bytes memory data1) = dogtokenaddress.call(abi.encodeWithSignature("name()"));
        (, bytes memory data2) = dogtokenaddress.call(abi.encodeWithSignature("symbol()"));
        (, bytes memory data3) = dogtokenaddress.call(abi.encodeWithSignature("totalSupply()"));
        (, bytes memory data4) = dogtokenaddress.call(abi.encodeWithSignature("decimals()"));
        (, bytes memory data5) = dogtokenaddress.call(
            abi.encodeWithSignature("balanceOf(address)", account)
        );

        //emit Response(success1, data1);
        string memory name = abi.decode(data1, (string));
        string memory symbol = abi.decode(data2, (string));
        uint256 totalSupply = abi.decode(data3, (uint256));
        uint8 decimals = abi.decode(data4, (uint8));
        uint256 balanceOf = abi.decode(data5, (uint256));

        return (name, symbol, totalSupply, decimals, balanceOf);
    }

    function getinformation22(
        address dogtokenaddress,
        address valuetokenaddress
    ) public returns (address, address, address, uint112, uint112, uint32) {
        (, bytes memory data1) = cakegetpair.call(
            abi.encodeWithSignature("getPair(address,address)", valuetokenaddress, dogtokenaddress)
        );
        pairaddress = abi.decode(data1, (address));

        (, bytes memory data2) = pairaddress.call(abi.encodeWithSignature("token0()"));
        token0 = abi.decode(data2, (address));

        (, bytes memory data3) = pairaddress.call(abi.encodeWithSignature("token1()"));
        token1 = abi.decode(data3, (address));

        (, bytes memory data4) = pairaddress.call(abi.encodeWithSignature("getReserves()"));

        (reserve0, reserve1, blockTimestampLast) = abi.decode(data4, (uint112, uint112, uint32));
        return (pairaddress, token0, token1, reserve0, reserve1, blockTimestampLast);
    }

    //可有可无
    function getname(address dogtokenaddress) public returns (string memory) {
        (bool success, bytes memory data) = dogtokenaddress.call(abi.encodeWithSignature("name()"));
        emit Response(success, data);
        return abi.decode(data, (string));
    }

    //可有可无
    function getdecimals(address dogtokenaddress) public returns (uint8) {
        (bool success, bytes memory data) = dogtokenaddress.call(
            abi.encodeWithSignature("decimals()")
        );
        emit Response(success, data);
        return abi.decode(data, (uint8));
    }

    //发送所有eth给调用者
    function transferETH(address payable _to) external payable {
        _to.transfer(address(this).balance);
    }
}