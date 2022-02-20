/**
 *Submitted for verification at Etherscan.io on 2022-02-20
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
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

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
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

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Property{
    IUniswapV2Router02 public sushiRouter = IUniswapV2Router02(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);
    event rateLog(address tokenAddr, uint256 rate);
    event mortAmount(address recipient, address tokenAddr, uint256 rate);
    address tokenUSD;//当前抵押出的币种
    uint interRate;//年利率
    bool stateFrozen;
    bool notFrozenState;
    //冻结
    modifier notFrozen()
    {
        require(notFrozenState, "STATE_IS_FROZEN");
        _;
    }


    //预估需要的token，想兑换出数量amountOut, 那需要数量amountIn
    function sushiGetSwapTokenAmountIn(
        address tokenA,
        address tokenB,
        uint amountOut
    ) public view virtual returns (uint) {
        address[] memory path = new address[](2);
        path[0] = tokenA;
        path[1] = tokenB;
        uint amountIn = sushiRouter.getAmountsIn(
            amountOut,
            path
        )[0];
        return amountIn;
    }

    //价格：预估兑换出的token，用A兑换B，可以兑换出B的数量amountOut
    function sushiGetSwapTokenAmountOut(
        address tokenIn,
        address tokenOut,
        uint amountIn
    ) public view virtual returns (uint) {
        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;
        uint amountOut = sushiRouter.getAmountsOut(
            amountIn,
            path
        )[0];
        return amountOut;
    }

    //开始兑换，把In兑换成Out，Out是稳定币，已在添加抵押物时approve
    function sushiSwapper(address tokenIn, address tokenOut,uint amountIn) public {
        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;
        uint amountOut = sushiGetSwapTokenAmountOut(tokenIn,tokenOut,amountIn);
        sushiRouter.swapExactTokensForTokens(
            amountIn,
            amountOut,
            path,
            address(this),
            block.timestamp + 300
        );
        // emit contraCollaLog();
    }

/////////////////////////////////////////////////////////////////////////////////////////////////////////

//设置新的抵押物
    struct collaListPa{
        uint mortRate;//抵押率
        uint liquRate;//清算率
        uint state;//启用状态
    }
    mapping(address=>collaListPa) private collaList;//抵押物列表
    function setCollateralList(
        address tokenAddr,//抵押物地址
        uint mortRate,
        uint liquRate,
        uint state
    )public {
        if (collaList[tokenAddr].mortRate == 0){
            //polygon sushiswap address
            address sushiswapAddr = address(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);
            //需要approve，this.address approve tokenA to sushiswap，清算时需要，否则无法清算卖出该币种
            // IERC20(tokenAddr).approve(sushiswapAddr,amount);
        }
        collaList[tokenAddr].mortRate = mortRate;
        collaList[tokenAddr].liquRate = liquRate;
        collaList[tokenAddr].state = state;
    }

//抵押出的币种
    address tokenUSDAddr;
    function settokenUSDAddr(address newtokenUSDAddr) public{
        // emit tokenUSDchangeLog(newtokenUSDAddr,tokenUSDAddr);
        //核对现有的抵押物是否都有交易对，没有时抵押物应该禁用
        tokenUSDAddr = newtokenUSDAddr;
    }

//年利率更改
    uint inteRate;
    function setInteRate(uint setInteRate) public {
        //更新所有合同，不足8小时的不计，更新利息计时开始时间

        //更改利率
        interRate = setInteRate;
        // emit inteRateChangeLog(setInteRate,interRate);
    }

    //内部交易
    function transferToExchange(address tokenAddr,uint256 amount)public returns (bool){
        IERC20 token = IERC20(tokenAddr);
        uint256 exchangeBalanceBefore = token.balanceOf(address(this));
        bytes memory callData = abi.encodeWithSelector(
            token.transferFrom.selector,
            msg.sender,
            address(this),
            amount
        );
        tokenAddr.call(callData);
        uint256 exchangeBalanceAfter = token.balanceOf(address(this));
        require(exchangeBalanceAfter >= exchangeBalanceBefore, "OVERFLOW");
        require(
            exchangeBalanceAfter == exchangeBalanceBefore + amount,
            "INCORRECT_AMOUNT_TRANSFERRED"
        );
        return true;
    }

//抵押物进来直接兑换，需要用户先approve到this.address
    //用户表
    struct contPar{
        address tokenUSD;//抵押出的币种
        uint createTime;
        uint state;
    }
    struct user{
        mapping(address => uint) asset;//资金帐户
        mapping(string=>contPar) contList;//用户所有合同
        uint contNum;//合同总数
        uint createTime;//创建时间
    }
    mapping(address=>user) private users;

    function depositToken(
        address tokenAddr,
        uint amount,
        uint tranType
    )public notFrozen(){
        //判断抵押物是否存在，状态是否启用
        require(collaList[tokenAddr].state != 0,"MORTGAGE_INVALID");
        //transfer，转币到交易所合约地址
        transferToExchange(tokenAddr,amount);

        //查询抵押率，抵押出的币种，
        uint mortRate = collaList[tokenAddr].mortRate;
        //可卖出币的数量
        uint tokenOutAmount = sushiGetSwapTokenAmountOut(tokenAddr,tokenUSDAddr,amount);
        //抵押出的数量
        uint tokenCollateraAmount = tokenOutAmount / mortRate/100;

        //开始存储数据
        uint isUser = users[msg.sender].createTime;
        if (isUser!=0) {//用户不存在
            //资金帐户
            users[msg.sender].asset[tokenUSDAddr] = tokenCollateraAmount;
            users[msg.sender].contNum = 1;
            users[msg.sender].createTime = block.timestamp;
            //用户合同数
            uint idNum = 1;
            //合同编号
            string memory contId = string(string(abi.encodePacked(addressToSting(msg.sender),uint2str(idNum))));
            users[msg.sender].contList[contId].tokenUSD = tokenUSDAddr;
            users[msg.sender].contList[contId].createTime = block.timestamp;
            users[msg.sender].contList[contId].state = tranType;
        }else{
            //判断有没有合同，遍历所有合同
            


        }

        //1、判断是否存在已有合同，用户地址和抵押出的币种
        //已有合同，追加。结算利息，重置借出的币数量

        //没有合同，新开合同


        //写入日志，抵押出的量，交易所查询上帐用
        // emit depositCollateraAmount(msg.sender,tokenAddr,amount,tranType,collateraRate,tokenOutAmount,tokenCollateraAmount);
    }

    //链的主币充值，如eth,matic


    //归还
    function repayment() public {
        //资金帐户还款
        //资金
    }

    //返回清算合同
    //问题：1、两笔同时追加(同一区块)时结果是否正确
    function contractList(
        address recipient,
        address tokenAddr
    )public{
        //所有合同列表
        uint nowTiem = block.timestamp;//当前时间
        // for contractList{
            // createTime = 123455//合同成立时间
            //A 当前抵押出的USD
            //B 计时起始时间，每一次更新都会重置
            //C 已确认的利息，每一次更新时累加
            //D 实时利息 = (A+C)*(nowTime-createTime算了几个八小时) * 利率
            //总利息 = C+D

            //F 总欠款 = A+C+D
            //G 清算节点 = 可抵押出的USD/清算率
            //F>=G时清算
        // }
    }

    //清算合同,每个合同单独清算，不合并，一次不要过多
    // function Liquidation(
    //     bytes32[] contractList
    // )public {
    //     for contractList{
    //         //更新合同为清算

    //         //全部卖出
    //         address tokenUSD = "";//要兑换成的稳定币
    //         address tokenColla = "";//要清算的币种
    //         uint amount = 100;//清算的数量
    //         sushiSwapper(tokenColla,tokenUSD,amount);
    //     }
    // }

    //address to string
    function addressToSting(address addr) internal pure returns(string memory){
        bytes memory addressBytes = abi.encodePacked(addr);
        bytes memory stringBytes = new bytes(42);

        stringBytes[0] = '';
        stringBytes[0] = '';

        for (uint i=0;i<20;i++) {
            uint8 leftValue = uint8(addressBytes[i]) / 16;
            uint8 rightValue = uint8(addressBytes[i]) - 16 *leftValue;
            bytes1 leftChar = leftValue < 10 ? bytes1(leftValue+48) : bytes1(leftValue+87);
            bytes1 rightChar = rightValue < 10 ? bytes1(rightValue+48) : bytes1(rightValue+87);
            stringBytes[2*i+3] = rightChar;
            stringBytes[2*i+2] = leftChar;
        }
        return string(stringBytes);
    }

    //uint to string
    function uint2str(uint _i) internal pure returns (string memory) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }


    //清算公式
    //抵押出的U = (抵押物数量 * 抵押时的价格) / 基础抵押率
    //触发条件：抵押出的U - 已偿还的U <= (抵押物数量 * 实时价) / 清算抵押率 + 利息
    //追加抵押物：先结算上一笔抵押利息，再重置开始时间
    //归还部分债务：下次计息时扣除归还部分，
    //            1、归还完刚好清算的数额，如果有多的则充值到交易帐户或资金帐户
    //
    //利息：单位小时，根据币种，每8小时计息一次，每小时利率。几小时A，小时利息rateA
    //     1、抵押：抵押物、数量、价格，抵押出的币种，抵押出币的数量，交易时间。= (抵押物*数量*价格)
    //     2、追加：抵押物、数量、价格，抵押出的币种，抵押出币的数量，交易时间。
    //     3、归还：

    event testLog(uint oldNum, uint newNum,uint blocktime);
    uint public testNum;
    function test() public {
        uint oldNum = testNum; 
        testNum +=1;
        uint newNum = testNum;
        emit testLog(oldNum,newNum,block.timestamp); 
    }

    struct af{
        string aa;
        uint bb;
        uint cc;
        uint dd;
    }

    mapping(uint=>af) testF;
    function test2(uint am) external{
        for (uint i=0; i<=am; i++){
            testF[i].aa = "aaaa";
            testF[i].bb = block.timestamp;
            testF[i].cc = block.timestamp;
            testF[i].dd = i;
        }
    }

    function testaa(uint amm) external view returns(string memory){
        return testF[amm].aa;
    }

    function testbb(uint amm) external view returns(uint){
        return testF[amm].bb;
    }

    function testcc(uint amm) external view returns(uint){
        return testF[amm].cc;
    }

    function testdd(uint amm) external view returns(uint){
        return testF[amm].dd;
    }
}